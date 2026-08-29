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

            VFS_FirmarDocumentoUtility.sendEnvelope(
                uploadResult.fileId,
                'VFS_FirmarComprobanteCaso',
                String.valueOf(caseId)
            );

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error subiendo/enviando comprobante a firma. CaseId=' + caseId +
                ' | Error=' + e.getMessage() +
                ' | Stack=' + e.getStackTraceString()
            );
        }
    }
}