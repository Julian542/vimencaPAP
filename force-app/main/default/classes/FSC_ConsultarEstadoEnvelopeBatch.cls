global class FSC_ConsultarEstadoEnvelopeBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {    

    public static Integer batchSize = 1;
    private Map<String, String> completedEnvelopeFinishedAtByEnvelopeId = new Map<String, String>();

    global void execute(SchedulableContext sc){
        Database.executeBatch(new FSC_ConsultarEstadoEnvelopeBatch(), batchSize);
    } 

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, FSC_Firmado__c, FSC_FechaDeFirmaCliente__c, FSC_EnvelopeId__c, FSC_EnviarDocumento__c, FSC_FechaEnvioFirma__c ' +
            'FROM ContentVersion ' +
            'WHERE FSC_EnvelopeId__c != null ' +
            'AND FSC_EnvelopeId__c != \'\' ' +
            'AND FSC_EnviarDocumento__c = true ' +
            'AND FSC_FechaEnvioFirma__c != null ' +
            'AND FSC_Firmado__c = false'
        );
    }

    global void execute(Database.BatchableContext bc, List<ContentVersion> scope){
        try {
            Set<String> envelopeIdsInScope = new Set<String>();
            for(ContentVersion cv : scope){
                if (!String.isBlank(cv.FSC_EnvelopeId__c)) {
                    envelopeIdsInScope.add(cv.FSC_EnvelopeId__c);
                }
            }

            for (String envelopeId : envelopeIdsInScope) {
                if (completedEnvelopeFinishedAtByEnvelopeId.containsKey(envelopeId)) {
                    continue;
                }

                FSC_FirmarDocumentoUtility.EnvelopeStatus response =
                    FSC_FirmarDocumentoUtility.obtenerEstadoEnvelope(envelopeId);

                if (response != null && response.envelopeStatus == 'Completed') {
                    completedEnvelopeFinishedAtByEnvelopeId.put(envelopeId, response.envelopeFinishedDate);
                }
            }
        } catch (Exception e) {
            System.debug('Line: '+e.getLineNumber());
            System.debug('Message: '+e.getMessage());
            System.debug('Trace: '+e.getStackTraceString());
        }
    }

    global void finish(Database.BatchableContext bc){
        try {
            if (completedEnvelopeFinishedAtByEnvelopeId.isEmpty()) {
                return;
            }

            if (Test.isRunningTest()) {
                return;
            }

            if (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
                System.debug('No se encolo la descarga firmada por limite de queueables.');
                return;
            }

            System.enqueueJob(new FSC_DescargarEnvelopeFirmadoQueueable(
                completedEnvelopeFinishedAtByEnvelopeId
            ));
        } catch (Exception e) {
            System.debug('Line: '+e.getLineNumber());
            System.debug('Message: '+e.getMessage());
            System.debug('Trace: '+e.getStackTraceString());
        }
    }

    public static Datetime parseIsoDatetime(String value) {
        if (String.isBlank(value)) {
            return null;
        }

        String normalized = value.trim();

        normalized = normalized.replace('T', ' ');

        if (normalized.endsWith('Z')) {
            normalized = normalized.substring(0, normalized.length() - 1);
        }

        Integer plusIndex = normalized.indexOf('+');
        if (plusIndex > 0) {
            normalized = normalized.substring(0, plusIndex);
        }

        Integer minusIndex = normalized.lastIndexOf('-');
        if (minusIndex > 10) {
            normalized = normalized.substring(0, minusIndex);
        }

        return Datetime.valueOfGmt(normalized);
    }

}