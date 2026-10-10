public without sharing class FSC_RegenerarPagareComplementarioQbl implements Queueable, Database.AllowsCallouts {
    @TestVisible
    private static final Integer CHUNK_SIZE = 10;

    private List<Id> residentialLoanApplicationIds;

    public FSC_RegenerarPagareComplementarioQbl(List<Id> residentialLoanApplicationIds) {
        this.residentialLoanApplicationIds = residentialLoanApplicationIds == null
            ? new List<Id>()
            : new List<Id>(new Set<Id>(residentialLoanApplicationIds));
    }

    public static void enqueueIfExists(Set<Id> residentialLoanApplicationIds) {
        if (residentialLoanApplicationIds == null || residentialLoanApplicationIds.isEmpty()) {
            return;
        }

        Map<Id, Set<Id>> documentIdsByRlaId = getComplementaryDocumentIds(
            new List<Id>(residentialLoanApplicationIds)
        );
        if (!documentIdsByRlaId.isEmpty()) {
            System.enqueueJob(
                new FSC_RegenerarPagareComplementarioQbl(
                    new List<Id>(documentIdsByRlaId.keySet())
                )
            );
        }
    }

    public void execute(QueueableContext context) {
        if (residentialLoanApplicationIds.isEmpty()) {
            return;
        }

        List<Id> idsToProcess = new List<Id>();
        List<Id> remainingIds = new List<Id>();
        for (Integer index = 0; index < residentialLoanApplicationIds.size(); index++) {
            if (index < CHUNK_SIZE) {
                idsToProcess.add(residentialLoanApplicationIds[index]);
            } else {
                remainingIds.add(residentialLoanApplicationIds[index]);
            }
        }

        Map<Id, Set<Id>> complementaryDocumentIdsByRlaId = getComplementaryDocumentIds(idsToProcess);
        List<PendingReplacement> pendingReplacements = new List<PendingReplacement>();

        for (ResidentialLoanApplication rla : [
            SELECT Id, RecordType.DeveloperName, FSC_RequiereContratoPagareNotarial__c,
                FSC_NumeroPrestamoAbanks__c, Account.Name
            FROM ResidentialLoanApplication
            WHERE Id IN :idsToProcess AND FSC_NumeroPrestamoAbanks__c != null
        ]) {
            Set<Id> existingDocumentIds = complementaryDocumentIdsByRlaId.get(rla.Id);
            if (existingDocumentIds == null || existingDocumentIds.isEmpty()) {
                continue;
            }

            try {
                if (!usesComplementaryPagare(rla)) {
                    continue;
                }

                PageReference pageReference = Page.FSC_PagareComercialComplementarioPDF;
                pageReference.getParameters().put('id', String.valueOf(rla.Id));
                Blob pdfBlob = Test.isRunningTest()
                    ? Blob.valueOf('TEST PDF CONTENT')
                    : pageReference.getContentAsPDF();

                if (pdfBlob == null || pdfBlob.size() == 0) {
                    throw new PagareRegenerationException('El PDF se genero vacio.');
                }

                String accountName = rla.Account == null || String.isBlank(rla.Account.Name)
                    ? 'Sin Nombre'
                    : rla.Account.Name;
                String title = 'Pagare Complementario ' + accountName + ' ' +
                    System.now().format('yyyy-MM-dd-HH-mm-ss');
                pendingReplacements.add(
                    new PendingReplacement(rla.Id, title, pdfBlob, existingDocumentIds)
                );
            } catch (Exception error) {
                System.debug(
                    LoggingLevel.ERROR,
                    'No fue posible regenerar el pagare complementario para la RLA ' +
                    rla.Id + ': ' + error.getMessage()
                );
            }
        }

        for (PendingReplacement replacement : pendingReplacements) {
            Savepoint replacementSavepoint = Database.setSavepoint();
            try {
                // El anterior se elimina solamente despues de crear el archivo nuevo.
                insert new ContentVersion(
                    Title = replacement.title,
                    PathOnClient = replacement.title + '.pdf',
                    VersionData = replacement.pdfBlob,
                    FirstPublishLocationId = replacement.rlaId,
                    FSC_EnviarDocumento__c = true
                );

                List<ContentDocument> documentsToDelete = new List<ContentDocument>();
                for (Id contentDocumentId : replacement.previousContentDocumentIds) {
                    documentsToDelete.add(new ContentDocument(Id = contentDocumentId));
                }

                Database.DeleteResult[] deleteResults = Database.delete(documentsToDelete, false);
                for (Database.DeleteResult deleteResult : deleteResults) {
                    if (!deleteResult.isSuccess()) {
                        throw new PagareRegenerationException(
                            'No se pudo eliminar el pagare anterior: ' +
                            deleteResult.getErrors()[0].getMessage()
                        );
                    }
                }
            } catch (Exception error) {
                Database.rollback(replacementSavepoint);
                System.debug(
                    LoggingLevel.ERROR,
                    'No fue posible reemplazar el pagare complementario para la RLA ' +
                    replacement.rlaId + ': ' + error.getMessage()
                );
            }
        }

        if (!remainingIds.isEmpty()) {
            System.enqueueJob(new FSC_RegenerarPagareComplementarioQbl(remainingIds));
        }
    }

    private static Map<Id, Set<Id>> getComplementaryDocumentIds(List<Id> rlaIds) {
        Map<Id, Set<Id>> documentIdsByRlaId = new Map<Id, Set<Id>>();
        for (ContentDocumentLink link : [
            SELECT LinkedEntityId, ContentDocumentId, ContentDocument.Title
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :rlaIds
        ]) {
            if (!isComplementaryPagareTitle(link.ContentDocument.Title)) {
                continue;
            }
            if (!documentIdsByRlaId.containsKey(link.LinkedEntityId)) {
                documentIdsByRlaId.put(link.LinkedEntityId, new Set<Id>());
            }
            documentIdsByRlaId.get(link.LinkedEntityId).add(link.ContentDocumentId);
        }
        return documentIdsByRlaId;
    }

    private static Boolean isComplementaryPagareTitle(String title) {
        if (String.isBlank(title)) {
            return false;
        }

        String normalizedTitle = title.trim().toLowerCase().replace('é', 'e');
        return normalizedTitle.startsWith('pagare complementario');
    }

    private static Boolean usesComplementaryPagare(ResidentialLoanApplication rla) {
        String recordTypeName = rla.RecordType.DeveloperName;
        if (recordTypeName == 'FSC_Solicitud_Credito_Consumo') {
            return FSC_ConsumoDocumentoResolver.resolve(rla.Id).codigoPagare ==
                FSC_ConsumoDocumentoResolver.PAGARE_COMPLEMENTARIO;
        }
        if (recordTypeName == 'FSC_Solicitud_Credito_Vehiculo') {
            return FSC_VehiculoDocumentoResolver.resolve(rla.Id).codigoPagare ==
                FSC_ConsumoDocumentoResolver.PAGARE_COMPLEMENTARIO;
        }
        if (recordTypeName == 'FSC_Solicitud_Credito_Hipotecario') {
            return FSC_HipotecarioDocumentoResolver.resolve(rla.Id).codigoPagare ==
                FSC_ConsumoDocumentoResolver.PAGARE_COMPLEMENTARIO;
        }
        return recordTypeName == 'FSC_Solicitud_Credito_PYME' &&
            rla.FSC_RequiereContratoPagareNotarial__c != true;
    }

    private class PendingReplacement {
        private Id rlaId;
        private String title;
        private Blob pdfBlob;
        private Set<Id> previousContentDocumentIds;

        private PendingReplacement(
            Id rlaId,
            String title,
            Blob pdfBlob,
            Set<Id> previousContentDocumentIds
        ) {
            this.rlaId = rlaId;
            this.title = title;
            this.pdfBlob = pdfBlob;
            this.previousContentDocumentIds = new Set<Id>(previousContentDocumentIds);
        }
    }

    public class PagareRegenerationException extends Exception {}
}