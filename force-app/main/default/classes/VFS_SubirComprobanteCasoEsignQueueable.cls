public with sharing class VFS_SubirComprobanteCasoEsignQueueable implements Queueable, Database.AllowsCallouts {

    private Id caseId;
    private Id contentDocumentId;

    public VFS_SubirComprobanteCasoEsignQueueable(Id caseId, Id contentDocumentId) {
        this.caseId = caseId;
        this.contentDocumentId = contentDocumentId;
    }

    public void execute(QueueableContext context) {

        try {
            VFS_EsignUploadDocument.UploadResult uploadResult =
                VFS_EsignUploadDocument.uploadDocument(String.valueOf(contentDocumentId));

            if (uploadResult == null || !uploadResult.success) {
                System.debug(LoggingLevel.ERROR,
                    'Error subiendo comprobante a eSignAnyWhere. CaseId=' + caseId +
                    ' | Mensaje=' + (uploadResult == null ? 'Sin respuesta' : uploadResult.message)
                );
                return;
            }

            VFS_EsignSendingEnvelope.EnvelopeResult envelopeResult =
                VFS_FirmarDocumentoUtility.sendEnvelope(
                uploadResult.fileId,
                'VFS_FirmarComprobanteCaso',
                String.valueOf(caseId)
            );

            if (envelopeResult == null || !envelopeResult.success || String.isBlank(envelopeResult.envelopeId)) {
                System.debug(LoggingLevel.ERROR,
                    'No se obtuvo EnvelopeId para el comprobante. CaseId=' + caseId
                );
                return;
            }

            List<ContentVersion> versions = [
                SELECT Id
                FROM ContentVersion
                WHERE ContentDocumentId = :contentDocumentId
                AND IsLatest = true
                LIMIT 1
            ];

            if (!versions.isEmpty()) {
                versions[0].FSC_EnvelopeId__c = envelopeResult.envelopeId;
                versions[0].FSC_EnviarDocumento__c = true;
                versions[0].FSC_FechaEnvioFirma__c = System.now();
                versions[0].FSC_Firmado__c = false;
                update versions[0];
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error subiendo/enviando comprobante a firma. CaseId=' + caseId +
                ' | Error=' + e.getMessage() +
                ' | Stack=' + e.getStackTraceString()
            );
        }
    }
}