public with sharing class FSC_APIPrestamoDesembolso {
	private static final String INTEGRATION_PROCEDURE_NAME = 'FSC_APIDesembolso';
	private static final String SUBESTADO_ARCHIVO_Y_CUSTODIA = 'Archivo y custodia';
	private static final String TIPO_SOLICITANTE_DEUDOR = 'Deudor';
	private static final Integer HTTP_OK = 200;

	@TestVisible
	private static Object mockIpResponse;

	@TestVisible
	private static Map<String, Object> lastIpInput;

	public class Input {
		@InvocableVariable(required=true)
		public Id residentialLoanApplicationId;

		@InvocableVariable(label='codigoUsuario')
		public String codigoUsuario;
	}

	public class Output {
		@InvocableVariable
		public Boolean success;

		@InvocableVariable
		public String message;

		@InvocableVariable
		public Integer statusCode;

		@InvocableVariable
		public String responseJson;

		@InvocableVariable
		public String ipInput;
	}

	@InvocableMethod(label='FSC - Desembolsar prestamo' description='Invoca IP FSC_APIDesembolso y actualiza el subestado cuando StatusCode es 200.')
	public static List<Output> run(List<Input> inputs) {
		List<Output> outputs = new List<Output>();
		if (inputs == null || inputs.isEmpty()) {
			return outputs;
		}

		Set<Id> rlaIds = new Set<Id>();
		for (Input inputItem : inputs) {
			if (inputItem != null && inputItem.residentialLoanApplicationId != null) {
				rlaIds.add(inputItem.residentialLoanApplicationId);
			}
		}

		Map<Id, ResidentialLoanApplication> rlaById = loadResidentialLoanApplications(rlaIds);
		Map<Id, LoanApplicant> debtorByRlaId = loadDebtors(rlaIds);
		String currentUserCodigoAbanks = needsCurrentUserCodigo(inputs) ? getCurrentUserCodigoAbanks() : null;
		List<PendingUpdate> pendingUpdates = new List<PendingUpdate>();

		for (Input inputItem : inputs) {
			Output outputItem = new Output();
			outputItem.success = false;
			ResidentialLoanApplication rla = null;

			try {
				if (inputItem == null || inputItem.residentialLoanApplicationId == null) {
					outputItem.message = 'residentialLoanApplicationId requerido.';
					outputs.add(outputItem);
					continue;
				}

				rla = rlaById.get(inputItem.residentialLoanApplicationId);
				if (rla == null) {
					outputItem.message = 'No se encontro ResidentialLoanApplication para el Id provisto.';
					outputs.add(outputItem);
					continue;
				}

				LoanApplicant debtor = debtorByRlaId.get(rla.Id);
				Map<String, Object> ipInput = buildIpInput(
					rla,
					debtor,
					firstNonBlank(new List<String>{ inputItem.codigoUsuario, currentUserCodigoAbanks, 'LOBAL001' })
				);
				outputItem.ipInput = JSON.serialize(ipInput);

				Object rawResponse = callDesembolsoIp(ipInput);
				DesembolsoResponse response = parseDesembolsoResponse(rawResponse);
				outputItem.statusCode = response.statusCode;
				outputItem.responseJson = response.responseJson;

				if (response.statusCode == HTTP_OK) {
					pendingUpdates.add(
						new PendingUpdate(
							new ResidentialLoanApplication(
								Id = rla.Id,
								FSC_Subestado__c = SUBESTADO_ARCHIVO_Y_CUSTODIA,
								FSC_FlagErrorAPIDesembolso__c = false
							),
							outputItem
						)
					);
					outputItem.success = true;
					outputItem.message = 'Desembolso creado en ABANKS.';
				} else {
					pendingUpdates.add(
						new PendingUpdate(new ResidentialLoanApplication(Id = rla.Id, FSC_FlagErrorAPIDesembolso__c = true), outputItem)
					);
					outputItem.message = 'IP devolvio StatusCode=' + String.valueOf(response.statusCode) + '.';
				}

				outputs.add(outputItem);
			} catch (Exception e) {
				outputItem.success = false;
				outputItem.message = 'Error: ' + e.getMessage();
				outputs.add(outputItem);

				if (rla != null) {
					pendingUpdates.add(
						new PendingUpdate(new ResidentialLoanApplication(Id = rla.Id, FSC_FlagErrorAPIDesembolso__c = true), outputItem)
					);
				}
			}
		}

		applyUpdates(pendingUpdates);
		return outputs;
	}

	public static Object callDesembolsoIp(Map<String, Object> inputMap) {
		lastIpInput = inputMap;

		if (Test.isRunningTest() && mockIpResponse != null) {
			return mockIpResponse;
		}

		return omnistudio.IntegrationProcedureService.runIntegrationService(INTEGRATION_PROCEDURE_NAME, inputMap, new Map<String, Object>());
	}

	@TestVisible
	private static Map<String, Object> buildIpInput(ResidentialLoanApplication rla, LoanApplicant debtor, String codigoUsuario) {
		List<String> missingFields = new List<String>();
		addMissingIfBlank(missingFields, codigoUsuario, 'User.FSC_CodigoAbanks__c');
		addMissingIfBlank(missingFields, rla.FSC_NumeroPrestamoAbanks__c, 'FSC_NumeroPrestamoAbanks__c');
		addMissingIfNull(missingFields, debtor, 'LoanApplicant Deudor');
		addMissingIfBlank(missingFields, debtor == null ? null : debtor.FSC_TipoIdentificacion__c, 'LoanApplicant.FSC_TipoIdentificacion__c');
		addMissingIfBlank(missingFields, debtor == null ? null : debtor.FSC_NumIdentificacion__c, 'LoanApplicant.FSC_NumIdentificacion__c');
		addMissingIfBlank(missingFields, rla.FSC_CodigoAprobacion__c, 'FSC_CodigoAprobacion__c');
		addMissingIfBlank(missingFields, rla.FSC_Grupo_de_Empresa__c, 'FSC_Grupo_de_Empresa__c');
		addMissingIfBlank(missingFields, rla.FSC_subAplicacion__c, 'FSC_subAplicacion__c');
		addMissingIfBlank(missingFields, rla.FSC_NumeroCuentaDesembolso__c, 'FSC_NumeroCuentaDesembolso__c');

		if (!missingFields.isEmpty()) {
			throw new IllegalArgumentException('Faltan datos requeridos para FSC_APIDesembolso: ' + String.join(missingFields, ', ') + '.');
		}

		String codigoTipoIdentificacion = mapCodigoTipoIdentificacion(debtor.FSC_TipoIdentificacion__c);
		Map<String, Object> desembolso = new Map<String, Object>{
			'numeroPrestamo' => parseWholeNumber(rla.FSC_NumeroPrestamoAbanks__c, 'FSC_NumeroPrestamoAbanks__c'),
			'codigoTipoIdentificacion' => parseWholeNumber(codigoTipoIdentificacion, 'LoanApplicant.FSC_TipoIdentificacion__c'),
			'numeroIdentificacion' => debtor.FSC_NumIdentificacion__c,
			'codigoAplicacion' => rla.FSC_CodigoAprobacion__c,
			'codigoAgencia' => parseWholeNumber(rla.FSC_Grupo_de_Empresa__c, 'FSC_Grupo_de_Empresa__c'),
			'codigoSubAplicacion' => parseWholeNumber(rla.FSC_subAplicacion__c, 'FSC_subAplicacion__c'),
			'numeroCuenta' => parseWholeNumber(rla.FSC_NumeroCuentaDesembolso__c, 'FSC_NumeroCuentaDesembolso__c')
		};

		return new Map<String, Object>{
			'bodyRequest' => new Map<String, Object>{ 'codigoUsuario' => codigoUsuario.trim(), 'desembolso' => desembolso }
		};
	}

	private static Map<Id, ResidentialLoanApplication> loadResidentialLoanApplications(Set<Id> rlaIds) {
		if (rlaIds == null || rlaIds.isEmpty()) {
			return new Map<Id, ResidentialLoanApplication>();
		}

		return new Map<Id, ResidentialLoanApplication>(
			[
				SELECT
					Id,
					FSC_Subestado__c,
					FSC_NumeroPrestamoAbanks__c,
					FSC_CodigoAprobacion__c,
					FSC_Grupo_de_Empresa__c,
					FSC_subAplicacion__c,
					FSC_NumeroCuentaDesembolso__c
				FROM ResidentialLoanApplication
				WHERE Id IN :rlaIds
			]
		);
	}

	private static Map<Id, LoanApplicant> loadDebtors(Set<Id> rlaIds) {
		Map<Id, LoanApplicant> debtorByRlaId = new Map<Id, LoanApplicant>();
		if (rlaIds == null || rlaIds.isEmpty()) {
			return debtorByRlaId;
		}

		for (LoanApplicant applicant : [
			SELECT Id, LoanApplicationId, FSC_TipoIdentificacion__c, FSC_NumIdentificacion__c
			FROM LoanApplicant
			WHERE LoanApplicationId IN :rlaIds AND FSC_TipoSolicitante__c = :TIPO_SOLICITANTE_DEUDOR
			ORDER BY CreatedDate ASC
		]) {
			if (!debtorByRlaId.containsKey(applicant.LoanApplicationId)) {
				debtorByRlaId.put(applicant.LoanApplicationId, applicant);
			}
		}

		return debtorByRlaId;
	}

	private static Boolean needsCurrentUserCodigo(List<Input> inputs) {
		for (Input inputItem : inputs) {
			if (inputItem != null && String.isBlank(inputItem.codigoUsuario)) {
				return true;
			}
		}
		return false;
	}

	private static String getCurrentUserCodigoAbanks() {
		User currentUser = [
			SELECT FSC_CodigoAbanks__c
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];
		return currentUser.FSC_CodigoAbanks__c;
	}

	private static void applyUpdates(List<PendingUpdate> pendingUpdates) {
		if (pendingUpdates == null || pendingUpdates.isEmpty()) {
			return;
		}

		List<ResidentialLoanApplication> recordsToUpdate = new List<ResidentialLoanApplication>();
		for (PendingUpdate pendingUpdate : pendingUpdates) {
			recordsToUpdate.add(pendingUpdate.record);
		}

		Database.SaveResult[] saveResults = Database.update(recordsToUpdate, false);
		for (Integer i = 0; i < saveResults.size(); i++) {
			if (saveResults[i].isSuccess()) {
				continue;
			}

			PendingUpdate failedUpdate = pendingUpdates[i];
			failedUpdate.output.success = false;
			failedUpdate.output.message = 'Error actualizando solicitud: ' + saveResults[i].getErrors()[0].getMessage();
		}
	}

	private static DesembolsoResponse parseDesembolsoResponse(Object rawResponse) {
		DesembolsoResponse response = new DesembolsoResponse();
		response.statusCode = extractStatusCode(rawResponse);
		response.responseJson = serializeResponse(rawResponse);
		return response;
	}

	private static Integer extractStatusCode(Object rawResponse) {
		Object normalizedResponse = normalizeResponse(rawResponse);
		Object statusCodeValue = findValueByNormalizedKey(normalizedResponse, 'statuscode');
		return valueToInteger(statusCodeValue);
	}

	private static Object findValueByNormalizedKey(Object value, String normalizedKey) {
		if (value == null) {
			return null;
		}

		if (value instanceof Map<String, Object>) {
			Map<String, Object> valueMap = (Map<String, Object>) value;
			for (String key : valueMap.keySet()) {
				if (key != null && key.toLowerCase() == normalizedKey) {
					return valueMap.get(key);
				}
			}

			for (Object childValue : valueMap.values()) {
				Object result = findValueByNormalizedKey(childValue, normalizedKey);
				if (result != null) {
					return result;
				}
			}
		} else if (value instanceof List<Object>) {
			for (Object childValue : (List<Object>) value) {
				Object result = findValueByNormalizedKey(childValue, normalizedKey);
				if (result != null) {
					return result;
				}
			}
		}

		return null;
	}

	private static Object normalizeResponse(Object response) {
		if (response == null) {
			return null;
		}

		if (response instanceof String) {
			String responseText = (String) response;
			if (String.isBlank(responseText)) {
				return null;
			}

			try {
				return JSON.deserializeUntyped(responseText);
			} catch (Exception e) {
				return responseText;
			}
		}

		if (response instanceof Map<String, Object> || response instanceof List<Object>) {
			return response;
		}

		try {
			return JSON.deserializeUntyped(JSON.serialize(response));
		} catch (Exception e) {
			return null;
		}
	}

	private static Decimal parseWholeNumber(String value, String fieldName) {
		if (String.isBlank(value)) {
			throw new IllegalArgumentException(fieldName + ' requerido.');
		}

		String normalizedValue = value.trim();
		if (normalizedValue.endsWith('.0')) {
			normalizedValue = normalizedValue.substring(0, normalizedValue.length() - 2);
		}

		if (normalizedValue.replaceAll('[0-9]', '') != '') {
			throw new IllegalArgumentException(fieldName + ' debe ser numerico.');
		}

		return Decimal.valueOf(normalizedValue);
	}

	private static String mapCodigoTipoIdentificacion(String tipoIdentificacion) {
		if (String.isBlank(tipoIdentificacion)) {
			return null;
		}

		String normalizedValue = tipoIdentificacion.trim().toLowerCase();
		if (normalizedValue == '1' || normalizedValue.startsWith('c')) {
			return '1';
		}
		if (normalizedValue == '2' || normalizedValue == 'r' || normalizedValue.contains('rnc')) {
			return '2';
		}
		if (normalizedValue == '3' || normalizedValue.startsWith('p')) {
			return '3';
		}

		return tipoIdentificacion;
	}

	private static Integer valueToInteger(Object value) {
		if (value == null) {
			return null;
		}

		String textValue = String.valueOf(value).trim();
		if (String.isBlank(textValue)) {
			return null;
		}

		try {
			return Decimal.valueOf(textValue).intValue();
		} catch (Exception e) {
			return null;
		}
	}

	private static String firstNonBlank(List<String> values) {
		for (String value : values) {
			if (!String.isBlank(value)) {
				return value.trim();
			}
		}
		return null;
	}

	private static void addMissingIfBlank(List<String> missingFields, String value, String fieldName) {
		if (String.isBlank(value)) {
			missingFields.add(fieldName);
		}
	}

	private static void addMissingIfNull(List<String> missingFields, Object value, String fieldName) {
		if (value == null) {
			missingFields.add(fieldName);
		}
	}

	private static String serializeResponse(Object response) {
		if (response == null) {
			return null;
		}
		return response instanceof String ? (String) response : JSON.serialize(response);
	}

	private class PendingUpdate {
		public ResidentialLoanApplication record;
		public Output output;

		public PendingUpdate(ResidentialLoanApplication record, Output output) {
			this.record = record;
			this.output = output;
		}
	}

	private class DesembolsoResponse {
		public Integer statusCode;
		public String responseJson;
	}
}