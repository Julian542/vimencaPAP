public with sharing class FSC_CreacionDesembolsoAsync implements Queueable, Database.AllowsCallouts {
	private List<Input> pendingInputs;

	public class Input {
		@InvocableVariable(required=true)
		public Id residentialLoanApplicationId;

		@InvocableVariable(label='codigoUsuario')
		public String codigoUsuario;

		@InvocableVariable(label='codigoAgencia')
		public String codigoAgencia;
	}

	public FSC_CreacionDesembolsoAsync(List<Input> inputs) {
		pendingInputs = inputs;
	}

	// Ejecuta el desembolso despues de confirmar la creacion del prestamo.
	@InvocableMethod(
		label='FSC - Encolar creacion de desembolso'
		description='Ejecuta la API de desembolso despues de confirmar la transaccion.'
	)
	public static void enqueue(List<Input> inputs) {
		List<Input> validInputs = new List<Input>();
		if (inputs != null) {
			for (Input inputItem : inputs) {
				if (inputItem != null && inputItem.residentialLoanApplicationId != null) {
					validInputs.add(inputItem);
				}
			}
		}

		if (!validInputs.isEmpty()) {
			System.enqueueJob(new FSC_CreacionDesembolsoAsync(validInputs));
		}
	}

	public void execute(QueueableContext context) {
		List<FSC_APIPrestamoDesembolso.Input> desembolsoInputs = new List<FSC_APIPrestamoDesembolso.Input>();
		for (Input inputItem : pendingInputs) {
			FSC_APIPrestamoDesembolso.Input desembolsoInput = new FSC_APIPrestamoDesembolso.Input();
			desembolsoInput.residentialLoanApplicationId = inputItem.residentialLoanApplicationId;
			desembolsoInput.codigoUsuario = inputItem.codigoUsuario;
			desembolsoInput.codigoAgencia = inputItem.codigoAgencia;
			desembolsoInputs.add(desembolsoInput);
		}

		FSC_APIPrestamoDesembolso.run(desembolsoInputs);
	}
}