public without sharing class FSC_DescargarEnvelopeFirmadoQueueable implements Queueable, Database.AllowsCallouts {
    private Map<String, String> finishedAtByEnvelopeId;

    public FSC_DescargarEnvelopeFirmadoQueueable(String envelopeId, String finishedAtStr) {
        this(new Map<String, String>{ envelopeId => finishedAtStr });
    }

    public FSC_DescargarEnvelopeFirmadoQueueable(Map<String, String> finishedAtByEnvelopeId) {
        this.finishedAtByEnvelopeId = new Map<String, String>();

        if (finishedAtByEnvelopeId == null) {
            return;
        }

        for (String envelopeId : finishedAtByEnvelopeId.keySet()) {
            if (!String.isBlank(envelopeId)) {
                this.finishedAtByEnvelopeId.put(envelopeId, finishedAtByEnvelopeId.get(envelopeId));
            }
        }
    }

    public void execute(QueueableContext context) {
        if (finishedAtByEnvelopeId == null || finishedAtByEnvelopeId.isEmpty()) {
            return;
        }

        String currentEnvelopeId = getNextEnvelopeId(finishedAtByEnvelopeId.keySet());
        String currentFinishedAtStr = finishedAtByEnvelopeId.get(currentEnvelopeId);

        Map<String, String> remainingEnvelopeIds = new Map<String, String>(finishedAtByEnvelopeId);
        remainingEnvelopeIds.remove(currentEnvelopeId);

        try {
            procesarEnvelope(currentEnvelopeId, currentFinishedAtStr);
        } catch (Exception e) {
            System.debug('Line: ' + e.getLineNumber());
            System.debug('Message: ' + e.getMessage());
            System.debug('Trace: ' + e.getStackTraceString());
        }

        if (!remainingEnvelopeIds.isEmpty() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new FSC_DescargarEnvelopeFirmadoQueueable(remainingEnvelopeIds));
        }
    }

    @TestVisible
    static void procesarEnvelope(String envelopeId, String finishedAtStr) {
        if (String.isBlank(envelopeId)) {
            return;
        }

        List<ContentVersion> originals = [
            SELECT Id, Title, ContentDocumentId, FSC_EnvelopeId__c
            FROM ContentVersion
            WHERE FSC_EnvelopeId__c = :envelopeId
            AND FSC_EnviarDocumento__c = true
            AND FSC_FechaEnvioFirma__c != null
            AND FSC_Firmado__c = false
            ORDER BY Title
        ];

        if (originals.isEmpty()) {
            return;
        }

        Map<Id, Id> rlaIdByContentVersionId = getRlaIdByContentVersionId(originals);
        Map<Id, String> signedTitleByContentVersionId = new Map<Id, String>();
        Set<Id> rlaIds = new Set<Id>();
        Set<String> signedTitles = new Set<String>();

        for (ContentVersion original : originals) {
            Id rlaId = rlaIdByContentVersionId.get(original.Id);
            if (rlaId == null) {
                continue;
            }

            String signedTitle = buildSignedTitle(original.Title);
            signedTitleByContentVersionId.put(original.Id, signedTitle);
            rlaIds.add(rlaId);
            signedTitles.add(signedTitle);
        }

        Set<String> existingSignedKeys = getExistingSignedFileKeys(rlaIds, signedTitles);
        List<FSC_FirmarDocumentoUtility.SignedEnvelopeFile> downloadedFiles =
            FSC_FirmarDocumentoUtility.obtenerArchivosFirmadosEnvelope(envelopeId);

        List<ContentVersion> signedFilesToInsert = new List<ContentVersion>();
        List<Id> originalIdsByInsertIndex = new List<Id>();
        Set<Id> originalIdsReadyToMark = new Set<Id>();
        Datetime finishedAt = FSC_ConsultarEstadoEnvelopeBatch.parseIsoDatetime(finishedAtStr);

        for (ContentVersion original : originals) {
            Id rlaId = rlaIdByContentVersionId.get(original.Id);
            String signedTitle = signedTitleByContentVersionId.get(original.Id);

            if (rlaId == null || String.isBlank(signedTitle)) {
                continue;
            }

            String existingKey = buildExistingSignedFileKey(rlaId, signedTitle);
            if (existingSignedKeys.contains(existingKey)) {
                originalIdsReadyToMark.add(original.Id);
                continue;
            }

            Blob signedBody = resolveSignedBody(original, downloadedFiles, originals);
            if (signedBody == null || signedBody.size() == 0) {
                continue;
            }

            signedFilesToInsert.add(new ContentVersion(
                Title = signedTitle,
                PathOnClient = signedTitle + '.pdf',
                VersionData = signedBody,
                FirstPublishLocationId = rlaId,
                FSC_Firmado__c = true,
                FSC_FechaDeFirmaCliente__c = finishedAt
            ));
            originalIdsByInsertIndex.add(original.Id);
        }

        if (!signedFilesToInsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(signedFilesToInsert, false);
            for (Integer i = 0; i < insertResults.size(); i++) {
                if (insertResults[i].isSuccess()) {
                    originalIdsReadyToMark.add(originalIdsByInsertIndex[i]);
                } else {
                    for (Database.Error error : insertResults[i].getErrors()) {
                        System.debug('No se pudo guardar archivo firmado: ' + error.getMessage());
                    }
                }
            }
        }

        Map<Id, Id> contentDocumentIdByOriginalId = new Map<Id, Id>();
        for (ContentVersion original : originals) {
            if (!originalIdsReadyToMark.contains(original.Id)) {
                continue;
            }

            contentDocumentIdByOriginalId.put(original.Id, original.ContentDocumentId);
        }

        List<ContentVersion> cvToUpdate = new List<ContentVersion>();
        List<Id> originalIdsByUpdateIndex = new List<Id>();
        for (Id originalId : originalIdsReadyToMark) {
            cvToUpdate.add(new ContentVersion(
                Id = originalId,
                FSC_FechaDeFirmaCliente__c = finishedAt,
                FSC_Firmado__c = true
            ));
            originalIdsByUpdateIndex.add(originalId);
        }

        Set<Id> contentDocumentIdsToDelete = new Set<Id>();
        for (Id originalId : originalIdsReadyToMark) {
            Id contentDocumentId = contentDocumentIdByOriginalId.get(originalId);
            if (contentDocumentId != null) {
                contentDocumentIdsToDelete.add(contentDocumentId);
            }
        }

        if (!cvToUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(cvToUpdate, false);

            for (Integer i = 0; i < updateResults.size(); i++) {
                if (updateResults[i].isSuccess()) {
                    continue;
                } else {
                    for (Database.Error error : updateResults[i].getErrors()) {
                        System.debug('No se pudo marcar archivo original como firmado: ' + error.getMessage());
                    }
                }
            }
        }

        deleteOriginalContentDocuments(contentDocumentIdsToDelete);
        completarRlasConFirmasListas(rlaIds);
    }

    private static String getNextEnvelopeId(Set<String> envelopeIds) {
        for (String envelopeId : envelopeIds) {
            return envelopeId;
        }

        return null;
    }

    private static void deleteOriginalContentDocuments(Set<Id> contentDocumentIds) {
        if (contentDocumentIds == null || contentDocumentIds.isEmpty()) {
            return;
        }

        List<ContentDocument> documentsToDelete = new List<ContentDocument>();
        for (Id contentDocumentId : contentDocumentIds) {
            documentsToDelete.add(new ContentDocument(Id = contentDocumentId));
        }

        Database.DeleteResult[] deleteResults = Database.delete(documentsToDelete, false);
        for (Integer i = 0; i < deleteResults.size(); i++) {
            if (deleteResults[i].isSuccess()) {
                continue;
            }

            for (Database.Error error : deleteResults[i].getErrors()) {
                System.debug('No se pudo eliminar archivo original sin firma: ' + error.getMessage());
            }
        }
    }

    private static void completarRlasConFirmasListas(Set<Id> rlaIds) {
        if (rlaIds == null || rlaIds.isEmpty()) {
            return;
        }

        Map<Id, Set<String>> pendingSignedTitlesByRla = new Map<Id, Set<String>>();
        Map<Id, Set<String>> signedTitlesByRla = new Map<Id, Set<String>>();
        Set<Id> linkedContentDocumentIds = new Set<Id>();
        Map<Id, Id> rlaIdByContentDocumentId = new Map<Id, Id>();

        for (ContentDocumentLink link : [
            SELECT LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :rlaIds
        ]) {
            linkedContentDocumentIds.add(link.ContentDocumentId);
            rlaIdByContentDocumentId.put(link.ContentDocumentId, link.LinkedEntityId);
        }

        if (linkedContentDocumentIds.isEmpty()) {
            return;
        }

        for (ContentVersion version : [
            SELECT Title, ContentDocumentId, FSC_EnviarDocumento__c, FSC_Firmado__c
            FROM ContentVersion
            WHERE ContentDocumentId IN :linkedContentDocumentIds
            AND IsLatest = true
        ]) {
            Id rlaId = rlaIdByContentDocumentId.get(version.ContentDocumentId);
            if (rlaId == null) {
                continue;
            }

            if (!pendingSignedTitlesByRla.containsKey(rlaId)) {
                pendingSignedTitlesByRla.put(rlaId, new Set<String>());
                signedTitlesByRla.put(rlaId, new Set<String>());
            }

            if (version.FSC_EnviarDocumento__c == true) {
                pendingSignedTitlesByRla.get(rlaId).add(buildSignedTitle(version.Title));
            }

            if (version.FSC_Firmado__c == true) {
                signedTitlesByRla.get(rlaId).add(version.Title);
            }
        }

        List<ResidentialLoanApplication> rlasToUpdate = new List<ResidentialLoanApplication>();
        for (Id rlaId : rlaIds) {
            Set<String> pendingSignedTitles = pendingSignedTitlesByRla.get(rlaId);
            Set<String> signedTitles = signedTitlesByRla.get(rlaId);

            if (signedTitles == null || signedTitles.isEmpty()) {
                continue;
            }

            Boolean allPendingHaveSignedFile = true;
            if (pendingSignedTitles != null) {
                for (String pendingSignedTitle : pendingSignedTitles) {
                    if (!signedTitles.contains(pendingSignedTitle)) {
                        allPendingHaveSignedFile = false;
                        break;
                    }
                }
            }

            if (allPendingHaveSignedFile) {
                rlasToUpdate.add(new ResidentialLoanApplication(
                    Id = rlaId,
                    FSC_Firma_completada__c = true,
                    FSC_Subestado__c = 'Documentación para desembolso y firmas'
                ));
            }
        }

        if (!rlasToUpdate.isEmpty()) {
            update rlasToUpdate;
        }
    }

    private static Map<Id, Id> getRlaIdByContentVersionId(List<ContentVersion> originals) {
        Map<Id, Id> rlaIdByContentVersionId = new Map<Id, Id>();
        Set<Id> contentDocumentIds = new Set<Id>();
        Map<Id, Id> contentVersionIdByContentDocumentId = new Map<Id, Id>();

        for (ContentVersion original : originals) {
            contentDocumentIds.add(original.ContentDocumentId);
            contentVersionIdByContentDocumentId.put(original.ContentDocumentId, original.Id);
        }

        for (ContentDocumentLink link : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :contentDocumentIds
        ]) {
            if (link.LinkedEntityId != null &&
                link.LinkedEntityId.getSObjectType() == ResidentialLoanApplication.SObjectType) {
                rlaIdByContentVersionId.put(
                    contentVersionIdByContentDocumentId.get(link.ContentDocumentId),
                    link.LinkedEntityId
                );
            }
        }

        return rlaIdByContentVersionId;
    }

    private static Set<String> getExistingSignedFileKeys(Set<Id> rlaIds, Set<String> signedTitles) {
        Set<String> existingKeys = new Set<String>();

        if (rlaIds.isEmpty() || signedTitles.isEmpty()) {
            return existingKeys;
        }

        Map<Id, Id> rlaIdByContentDocumentId = new Map<Id, Id>();
        for (ContentDocumentLink link : [
            SELECT LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :rlaIds
        ]) {
            rlaIdByContentDocumentId.put(link.ContentDocumentId, link.LinkedEntityId);
        }

        if (rlaIdByContentDocumentId.isEmpty()) {
            return existingKeys;
        }

        Set<Id> existingContentDocumentIds = rlaIdByContentDocumentId.keySet();
        for (ContentVersion version : [
            SELECT Title, ContentDocumentId
            FROM ContentVersion
            WHERE ContentDocumentId IN :existingContentDocumentIds
            AND IsLatest = true
            AND Title IN :signedTitles
        ]) {
            existingKeys.add(buildExistingSignedFileKey(
                rlaIdByContentDocumentId.get(version.ContentDocumentId),
                version.Title
            ));
        }

        return existingKeys;
    }

    private static Blob resolveSignedBody(
        ContentVersion original,
        List<FSC_FirmarDocumentoUtility.SignedEnvelopeFile> downloadedFiles,
        List<ContentVersion> originals
    ) {
        if (downloadedFiles == null || downloadedFiles.isEmpty()) {
            return null;
        }

        if (downloadedFiles.size() == 1) {
            return downloadedFiles[0].body;
        }

        String originalTitleNorm = normalizeFileName(original.Title);
        for (FSC_FirmarDocumentoUtility.SignedEnvelopeFile downloadedFile : downloadedFiles) {
            String downloadedNameNorm = normalizeFileName(downloadedFile.fileName);
            if (downloadedNameNorm.contains(originalTitleNorm) || originalTitleNorm.contains(downloadedNameNorm)) {
                return downloadedFile.body;
            }
        }

        Integer indexInEnvelope = 0;
        for (ContentVersion candidate : originals) {
            if (candidate.FSC_EnvelopeId__c == original.FSC_EnvelopeId__c) {
                if (candidate.Id == original.Id) {
                    break;
                }
                indexInEnvelope++;
            }
        }

        if (indexInEnvelope < downloadedFiles.size()) {
            return downloadedFiles[indexInEnvelope].body;
        }

        return null;
    }

    private static String buildSignedTitle(String title) {
        return title != null && title.endsWith('_firmado') ? title : title + '_firmado';
    }

    private static String buildExistingSignedFileKey(Id rlaId, String title) {
        return String.valueOf(rlaId) + '|' + title;
    }

    private static String normalizeFileName(String value) {
        if (String.isBlank(value)) {
            return '';
        }

        String normalized = value.toLowerCase();
        for (String suffix : new List<String>{ '.pdf', '.zip', '_firmado' }) {
            if (normalized.endsWith(suffix)) {
                normalized = normalized.substring(0, normalized.length() - suffix.length());
            }
        }
        return normalized.replaceAll('[^a-z0-9]', '');
    }
}