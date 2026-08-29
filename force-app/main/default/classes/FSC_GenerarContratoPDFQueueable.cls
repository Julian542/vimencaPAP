public without sharing class FSC_GenerarContratoPDFQueueable implements Queueable, Database.AllowsCallouts {

    @TestVisible
    private static Set<Id> forcedGenerationErrorLoanApplicationIds = new Set<Id>();

    private static final String SUBESTADO_GENERACION_CONTRATO = 'Generación de contrato';
    private static final String SUBESTADO_GESTIONAR_FIRMAS = 'Gestionar firmas';
    private static final String ERROR_LOG_SEPARATOR = '\n--------------------\n';
    private static final String ERROR_LOG_TIMESTAMP_FORMAT = 'yyyy-MM-dd HH:mm:ss';
    private static final Integer ERROR_LOG_MESSAGE_MAX_LENGTH = 255;

    private List<Id> residentialLoanApplicationIds;

    public FSC_GenerarContratoPDFQueueable(List<Id> residentialLoanApplicationIds) {
        this.residentialLoanApplicationIds = new List<Id>();

        if (residentialLoanApplicationIds != null) {
            this.residentialLoanApplicationIds.addAll(residentialLoanApplicationIds);
        }
    }

    public void execute(QueueableContext context) {
        if (residentialLoanApplicationIds.isEmpty()) {
            return;
        }

        List<ResidentialLoanApplication> loanApplications = [
            SELECT Id, FSC_Subestado__c, FSC_Contrato_Generado__c, FSC_LogErrores__c
            FROM ResidentialLoanApplication
            WHERE Id IN :residentialLoanApplicationIds
        ];

        Map<Id, String> currentErrorLogsByLoanApplicationId = new Map<Id, String>();
        for (ResidentialLoanApplication loanApplication : loanApplications) {
            currentErrorLogsByLoanApplicationId.put(loanApplication.Id, loanApplication.FSC_LogErrores__c);
        }

        Map<Id, String> pendingErrorLogsByLoanApplicationId = new Map<Id, String>();
        List<ContentVersion> filesToInsert = new List<ContentVersion>();
        List<Id> fileLoanApplicationIds = new List<Id>();

        for (ResidentialLoanApplication loanApplication : loanApplications) {
            if (loanApplication.FSC_Subestado__c != SUBESTADO_GENERACION_CONTRATO) {
                continue;
            }

            try {
                if (Test.isRunningTest() && forcedGenerationErrorLoanApplicationIds.contains(loanApplication.Id)) {
                    throw new FSC_GenerarContratoPDFQueueableException('Error de generación forzado para prueba.');
                }

                PageReference contractPage = FSC_RLAContractTemplateResolver.resolvePageReference(loanApplication.Id);

                Blob pdfBlob = Test.isRunningTest()
                    ? Blob.valueOf('TEST PDF CONTENT')
                    : contractPage.getContentAsPDF();

                if (pdfBlob == null || pdfBlob.size() == 0) {
                    throw new FSC_GenerarContratoPDFQueueableException('El PDF se generó vacío.');
                }

                String fileTitle = buildFileTitle(loanApplication.Id);

                filesToInsert.add(new ContentVersion(
                    Title = fileTitle,
                    PathOnClient = fileTitle + '.pdf',
                    VersionData = pdfBlob,
                    FirstPublishLocationId = loanApplication.Id,
                    FSC_EnviarDocumento__c = true
                ));
                fileLoanApplicationIds.add(loanApplication.Id);
            } catch (Exception e) {
                registerError(
                    currentErrorLogsByLoanApplicationId,
                    pendingErrorLogsByLoanApplicationId,
                    loanApplication.Id,
                    'Error generando contrato PDF: ' + trimForLog(e.getMessage(), ERROR_LOG_MESSAGE_MAX_LENGTH)
                );

                System.debug(
                    LoggingLevel.ERROR,
                    'Error generando contrato PDF para RLA ' + loanApplication.Id + ': ' + e.getMessage()
                );
            }
        }

        Set<Id> successfulLoanApplicationIds = new Set<Id>();

        if (!filesToInsert.isEmpty()) {
            Database.SaveResult[] saveResults = Database.insert(filesToInsert, false);

            for (Integer i = 0; i < saveResults.size(); i++) {
                if (saveResults[i].isSuccess()) {
                    successfulLoanApplicationIds.add(fileLoanApplicationIds[i]);
                } else {
                    String insertErrorMessage = buildDatabaseErrorMessage(saveResults[i].getErrors());
                    registerError(
                        currentErrorLogsByLoanApplicationId,
                        pendingErrorLogsByLoanApplicationId,
                        fileLoanApplicationIds[i],
                        'Error guardando contrato PDF: ' + insertErrorMessage
                    );

                    System.debug(
                        LoggingLevel.ERROR,
                        'Error guardando PDF para RLA ' + fileLoanApplicationIds[i] + ': ' + insertErrorMessage
                    );
                }
            }
        }

        if (!successfulLoanApplicationIds.isEmpty()) {
            List<ResidentialLoanApplication> loanApplicationsToUpdate = new List<ResidentialLoanApplication>();
            List<Id> updateLoanApplicationIds = new List<Id>();

            for (Id loanApplicationId : successfulLoanApplicationIds) {
                loanApplicationsToUpdate.add(new ResidentialLoanApplication(
                    Id = loanApplicationId,
                    FSC_Subestado__c = SUBESTADO_GESTIONAR_FIRMAS,
                    FSC_Contrato_Generado__c = true
                ));
                updateLoanApplicationIds.add(loanApplicationId);
            }

            Database.SaveResult[] updateResults = Database.update(loanApplicationsToUpdate, false);

            for (Integer i = 0; i < updateResults.size(); i++) {
                if (!updateResults[i].isSuccess()) {
                    String updateErrorMessage = buildDatabaseErrorMessage(updateResults[i].getErrors());
                    registerError(
                        currentErrorLogsByLoanApplicationId,
                        pendingErrorLogsByLoanApplicationId,
                        updateLoanApplicationIds[i],
                        'Error actualizando ResidentialLoanApplication luego de generar contrato PDF: ' + updateErrorMessage
                    );

                    System.debug(
                        LoggingLevel.ERROR,
                        'Error actualizando RLA ' + updateLoanApplicationIds[i] + ' luego de generar PDF: ' + updateErrorMessage
                    );
                }
            }
        }

        if (!pendingErrorLogsByLoanApplicationId.isEmpty()) {
            List<ResidentialLoanApplication> logUpdates = new List<ResidentialLoanApplication>();

            for (Id loanApplicationId : pendingErrorLogsByLoanApplicationId.keySet()) {
                logUpdates.add(new ResidentialLoanApplication(
                    Id = loanApplicationId,
                    FSC_LogErrores__c = pendingErrorLogsByLoanApplicationId.get(loanApplicationId)
                ));
            }

            Database.update(logUpdates, false);
        }
    }

    private static void registerError(
        Map<Id, String> currentErrorLogsByLoanApplicationId,
        Map<Id, String> pendingErrorLogsByLoanApplicationId,
        Id loanApplicationId,
        String message
    ) {
        String baseLog = pendingErrorLogsByLoanApplicationId.containsKey(loanApplicationId)
            ? pendingErrorLogsByLoanApplicationId.get(loanApplicationId)
            : currentErrorLogsByLoanApplicationId.get(loanApplicationId);

        pendingErrorLogsByLoanApplicationId.put(
            loanApplicationId,
            appendErrorLog(baseLog, buildErrorLogEntry(message))
        );
    }

    private static String buildDatabaseErrorMessage(Database.Error[] errors) {
        if (errors == null || errors.isEmpty()) {
            return 'Error desconocido.';
        }

        List<String> messages = new List<String>();
        for (Database.Error errorItem : errors) {
            messages.add(trimForLog(errorItem.getMessage(), ERROR_LOG_MESSAGE_MAX_LENGTH));
        }

        return String.join(messages, ' | ');
    }

    private static String buildErrorLogEntry(String message) {
        return Datetime.now().format(ERROR_LOG_TIMESTAMP_FORMAT) + ' | ' + message;
    }

    private static String appendErrorLog(String currentLog, String newEntry) {
        if (String.isBlank(newEntry)) {
            return currentLog;
        }
        if (String.isBlank(currentLog)) {
            return newEntry;
        }

        return currentLog + ERROR_LOG_SEPARATOR + newEntry;
    }

    private static String trimForLog(String value, Integer maxLength) {
        if (String.isBlank(value) || maxLength == null || value.length() <= maxLength) {
            return value;
        }

        return value.substring(0, maxLength) + '...';
    }

    private static String buildFileTitle(Id loanApplicationId) {
        return 'Contrato_RLA_' + String.valueOf(loanApplicationId);
    }

    public class FSC_GenerarContratoPDFQueueableException extends Exception {}
}