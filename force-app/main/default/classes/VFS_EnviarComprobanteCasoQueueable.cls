public with sharing class VFS_EnviarComprobanteCasoQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> caseIds;

    public VFS_EnviarComprobanteCasoQueueable(Set<Id> caseIds) {
        this.caseIds = caseIds;
    }

    public void execute(QueueableContext context) {

        if (caseIds == null || caseIds.isEmpty()) {
            return;
        }

        for (Case caso : [
            SELECT Id, CaseNumber, AccountId
            FROM Case
            WHERE Id IN :caseIds
        ]) {
            try {
                if (caso.AccountId == null) {
                    continue;
                }

                Id contentDocumentId =
                    VFS_GenerarDocumentosUtility.generarPDFDesdeDefinicion(
                        'Comprobante de caso',
                        caso.Id
                    );

                System.enqueueJob(
                    new VFS_SubirComprobanteCasoEsignQueueable(
                        caso.Id,
                        contentDocumentId
                    )
                );

            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,
                    'Error generando comprobante de caso. CaseId=' + caso.Id +
                    ' | Error=' + e.getMessage() +
                    ' | Stack=' + e.getStackTraceString()
                );
            }
        }
    }
}