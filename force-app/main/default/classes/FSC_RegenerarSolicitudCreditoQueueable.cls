public without sharing class FSC_RegenerarSolicitudCreditoQueueable implements Queueable, Database.AllowsCallouts {
    @TestVisible
    private static final Integer CHUNK_SIZE = 10;

    private static final String METHOD_REGENERAR_PDF_SOLICITUD_CREDITO = 'regenerarPDFSolicitudCredito';

    private List<Id> residentialLoanApplicationIds;

    public FSC_RegenerarSolicitudCreditoQueueable(List<Id> residentialLoanApplicationIds) {
        this.residentialLoanApplicationIds = new List<Id>();

        if (residentialLoanApplicationIds != null) {
            this.residentialLoanApplicationIds.addAll(residentialLoanApplicationIds);
        }
    }

    public void execute(QueueableContext context) {
        if (residentialLoanApplicationIds.isEmpty()) {
            return;
        }

        List<Id> loanApplicationIdsToProcess = new List<Id>();
        List<Id> remainingLoanApplicationIds = new List<Id>();

        for (Integer index = 0; index < residentialLoanApplicationIds.size(); index++) {
            if (index < CHUNK_SIZE) {
                loanApplicationIdsToProcess.add(residentialLoanApplicationIds[index]);
            } else {
                remainingLoanApplicationIds.add(residentialLoanApplicationIds[index]);
            }
        }

        if (!remainingLoanApplicationIds.isEmpty()) {
            System.enqueueJob(
                new FSC_RegenerarSolicitudCreditoQueueable(remainingLoanApplicationIds)
            );
        }

        FSC_GenerarPDF pdfGenerator = new FSC_GenerarPDF();

        for (Id loanApplicationId : loanApplicationIdsToProcess) {
            Map<String, Object> output = new Map<String, Object>();
            Boolean success = pdfGenerator.invokeMethod(
                METHOD_REGENERAR_PDF_SOLICITUD_CREDITO,
                new Map<String, Object>{ 'Id' => loanApplicationId },
                output,
                new Map<String, Object>()
            );
            Boolean outputSuccess = output.get('success') == null
                ? false
                : (Boolean) output.get('success');

            if (!success || !outputSuccess) {
                System.debug(
                    LoggingLevel.ERROR,
                    'No fue posible regenerar el PDF de solicitud de crédito para la RLA '
                    + loanApplicationId
                    + '. Respuesta: '
                    + JSON.serialize(output)
                );
            }
        }
    }
}