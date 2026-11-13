public without sharing class FSC_EnviarEnvelopeQueueable implements Queueable, Database.AllowsCallouts {

    private String proceso;
    private String recordId;
    private Boolean encadenarPagare;

    public FSC_EnviarEnvelopeQueueable(String proceso, String recordId, Boolean encadenarPagare) {
        this.proceso = proceso;
        this.recordId = recordId;
        this.encadenarPagare = encadenarPagare;
    }

    public void execute(QueueableContext context) {
        try {
            VFS_EsignSendingEnvelope.EnvelopeResult result =
                FSC_FirmarDocumentoUtility.enviarPorProceso(proceso, recordId);

            if (result != null && result.success) {
                FSC_FirmarDocumentoUtility.marcarSolicitudComoEnviada(recordId);
            } else {
                marcarSolicitudConError(
                    result == null
                        ? 'El envio a firma no devolvio respuesta.'
                        : 'No se pudo enviar a firma. Detalle: ' + String.valueOf(result.message)
                );
            }

            if (encadenarPagare && !Test.isRunningTest()) {
                System.enqueueJob(new FSC_EnviarEnvelopeQueueable('PAGARE', recordId, false));
            }
        } catch (Exception e) {
            marcarSolicitudConError('Error al enviar a firma: ' + e.getMessage());
        }
    }

    private void marcarSolicitudConError(String errorMessage) {
        if (String.isBlank(recordId)) {
            return;
        }

        String message = '[' + Datetime.now().formatGmt('yyyy-MM-dd HH:mm:ss') + ' GMT] ' +
            'Proceso firma ' + String.valueOf(proceso) + ': ' +
            (String.isBlank(errorMessage) ? 'Error desconocido.' : errorMessage);

        List<ResidentialLoanApplication> rlas = [
            SELECT Id, FSC_LogErrores__c
            FROM ResidentialLoanApplication
            WHERE Id = :recordId
            LIMIT 1
        ];

        if (rlas.isEmpty()) {
            return;
        }

        ResidentialLoanApplication rla = rlas[0];
        String previousLog = String.isBlank(rla.FSC_LogErrores__c) ? '' : rla.FSC_LogErrores__c + '\n';
        String newLog = previousLog + message;
        if (newLog.length() > 10000) {
            newLog = newLog.substring(newLog.length() - 10000);
        }

        update new ResidentialLoanApplication(
            Id = rla.Id,
            FSC_EnviadoAFirmar__c = false,
            FSC_LogErrores__c = newLog
        );
    }
}