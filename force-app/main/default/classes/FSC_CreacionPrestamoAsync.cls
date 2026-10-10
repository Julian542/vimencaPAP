public without sharing class FSC_CreacionPrestamoAsync implements Queueable, Database.AllowsCallouts {
	private static final String ERROR_LOG_SEPARATOR = '\n--------------------\n';
	private static final Integer ERROR_LOG_MAX_LENGTH = 10000;
	private List<Input> pendingInputs;

	public class Input {
		@InvocableVariable(required=true)
		public Id residentialLoanApplicationId;

		@InvocableVariable
		public String codigoUsuario;

		@InvocableVariable
		public String codigoAgencia;

		@InvocableVariable
		public String codigoEjecutivo;
	}

	public FSC_CreacionPrestamoAsync(List<Input> inputs) {
		pendingInputs = inputs;
	}

	// Encola los callouts para ejecutarlos despues del commit.
	@InvocableMethod(
		label='FSC - Encolar creacion de prestamo'
		description='Ejecuta las APIs de productos y prestamos despues de confirmar la transaccion.'
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
			System.enqueueJob(new FSC_CreacionPrestamoAsync(validInputs));
		}
	}

	public void execute(QueueableContext context) {
		Set<Id> rlaIds = new Set<Id>();
		Map<Id, Input> inputByRlaId = new Map<Id, Input>();
		for (Input inputItem : pendingInputs) {
			rlaIds.add(inputItem.residentialLoanApplicationId);
			inputByRlaId.put(inputItem.residentialLoanApplicationId, inputItem);
		}

		try {
			Map<Id, ResidentialLoanApplication> rlaById = new Map<Id, ResidentialLoanApplication>([
				SELECT Id, FSC_lineaFinanciera__c, FSC_subAplicacion__c, FSC_ClaveProducto__c
				FROM ResidentialLoanApplication
				WHERE Id IN :rlaIds
			]);

			List<Id> orderedRlaIds = new List<Id>();
			List<FSC_APIPrestamoProductos.Input> productInputs = new List<FSC_APIPrestamoProductos.Input>();
			for (Id rlaId : rlaIds) {
				ResidentialLoanApplication rla = rlaById.get(rlaId);
				if (rla == null) {
					continue;
				}

				FSC_APIPrestamoProductos.Input productInput = new FSC_APIPrestamoProductos.Input();
				productInput.lineaFinanciera = rla.FSC_lineaFinanciera__c;
				productInput.subAplicacion = rla.FSC_subAplicacion__c;
				productInput.claveProducto = rla.FSC_ClaveProducto__c;
				orderedRlaIds.add(rlaId);
				productInputs.add(productInput);
			}

			List<FSC_APIPrestamoProductos.Output> productOutputs = FSC_APIPrestamoProductos.run(productInputs);
			List<FSC_APIPrestamoPrestamos.Input> loanInputs = new List<FSC_APIPrestamoPrestamos.Input>();
			Map<Id, String> productErrorsByRlaId = new Map<Id, String>();

			for (Integer i = 0; i < orderedRlaIds.size(); i++) {
				Id rlaId = orderedRlaIds[i];
				FSC_APIPrestamoProductos.Output productOutput = productOutputs != null && i < productOutputs.size()
					? productOutputs[i]
					: null;

				if (
					productOutput == null ||
					productOutput.success != true ||
					productOutput.found != true ||
					String.isBlank(productOutput.productoJson)
				) {
					String errorMessage = productOutput == null || String.isBlank(productOutput.message)
						? 'No se obtuvo una respuesta valida al consultar productos.'
						: productOutput.message;
					productErrorsByRlaId.put(rlaId, errorMessage);
					continue;
				}

				Input sourceInput = inputByRlaId.get(rlaId);
				FSC_APIPrestamoPrestamos.Input loanInput = new FSC_APIPrestamoPrestamos.Input();
				loanInput.residentialLoanApplicationId = rlaId;
				loanInput.productoJson = productOutput.productoJson;
				loanInput.codigoUsuario = sourceInput.codigoUsuario;
				loanInput.codigoAgencia = sourceInput.codigoAgencia;
				loanInput.codigoEjecutivo = sourceInput.codigoEjecutivo;
				loanInputs.add(loanInput);
			}

			// Se crea el prestamo solo cuando se encontro el producto correspondiente.
			if (!loanInputs.isEmpty()) {
				FSC_APIPrestamoPrestamos.run(loanInputs);
			}

			markErrors(productErrorsByRlaId, 'API Productos');
		} catch (Exception e) {
			System.debug('Error creando prestamos de forma asincrona: ' + e.getMessage());
			Map<Id, String> asyncErrorsByRlaId = new Map<Id, String>();
			for (Id rlaId : rlaIds) {
				asyncErrorsByRlaId.put(rlaId, 'Error en la creacion asincrona del prestamo: ' + e.getMessage());
			}
			markErrors(asyncErrorsByRlaId, 'Creacion de prestamo');
		}
	}

	private static void markErrors(Map<Id, String> errorsByRlaId, String source) {
		if (errorsByRlaId == null || errorsByRlaId.isEmpty()) {
			return;
		}

		Set<Id> errorRlaIds = errorsByRlaId.keySet();
		Map<Id, ResidentialLoanApplication> rlaById = new Map<Id, ResidentialLoanApplication>([
			SELECT Id, FSC_LogErrores__c
			FROM ResidentialLoanApplication
			WHERE Id IN :errorRlaIds
		]);
		List<ResidentialLoanApplication> updates = new List<ResidentialLoanApplication>();
		for (Id rlaId : errorsByRlaId.keySet()) {
			ResidentialLoanApplication rla = rlaById.get(rlaId);
			if (rla == null) {
				continue;
			}

			String entry = Datetime.now().format('yyyy-MM-dd HH:mm:ss') + ' | ' + source + ' | ' + errorsByRlaId.get(rlaId);
			updates.add(
				new ResidentialLoanApplication(
					Id = rlaId,
					FSC_FlagErrorAPIPrestamos__c = true,
					FSC_LogErrores__c = appendErrorLog(rla.FSC_LogErrores__c, entry)
				)
			);
		}
		if (!updates.isEmpty()) {
			Database.update(updates, false);
		}
	}

	private static String appendErrorLog(String currentLog, String newEntry) {
		String combinedLog = String.isBlank(currentLog) ? newEntry : currentLog + ERROR_LOG_SEPARATOR + newEntry;
		return combinedLog.length() <= ERROR_LOG_MAX_LENGTH
			? combinedLog
			: combinedLog.substring(combinedLog.length() - ERROR_LOG_MAX_LENGTH);
	}
}