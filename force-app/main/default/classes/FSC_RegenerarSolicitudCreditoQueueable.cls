public with sharing class FSC_RegenerarSolicitudCreditoQueueable implements Queueable, Database.AllowsCallouts {
	@TestVisible
	private static final Integer CHUNK_SIZE = 1;

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
		List<Id> remainingLoanApplicationIds = new List<Id>();
		for (Integer index = CHUNK_SIZE; index < residentialLoanApplicationIds.size(); index++) {
			remainingLoanApplicationIds.add(residentialLoanApplicationIds[index]);
		}

		Map<String, Object> output = new Map<String, Object>();
		FSC_GenerarPDF pdfGenerator = new FSC_GenerarPDF();
		Boolean success = pdfGenerator.invokeMethod(
			METHOD_REGENERAR_PDF_SOLICITUD_CREDITO,
			new Map<String, Object>{ 'Id' => residentialLoanApplicationIds[0] },
			output,
			new Map<String, Object>()
		);
		Boolean outputSuccess = output.get('success') == null ? false : (Boolean) output.get('success');
		if (!success || !outputSuccess) {
			System.debug(
				LoggingLevel.ERROR,
				'No fue posible regenerar el PDF de solicitud de credito para la RLA ' +
					residentialLoanApplicationIds[0] +
					'. Tipo: ' +
					output.get('exceptionType')
			);
		}

		if (!remainingLoanApplicationIds.isEmpty()) {
			System.enqueueJob(new FSC_RegenerarSolicitudCreditoQueueable(remainingLoanApplicationIds));
		}
	}
}