public with sharing class FSC_APIPrestamoDesembolso {
	private static final String DESEMBOLSO_ENDPOINT = 'callout:FSC_APIPrestamo/api/prestamo/desembolso';
	private static final String API_KEY_HEADER = 'X-API-KEY';
	private static final String API_KEY_CONFIG = 'Default';
	private static final Integer HTTP_TIMEOUT = 120000;
	private static final String SUBESTADO_ARCHIVO_Y_CUSTODIA = 'Archivo y custodia';
	private static final String TIPO_SOLICITANTE_DEUDOR = 'Deudor';
	private static final String RECORD_TYPE_PYME = 'FSC_Solicitud_Credito_PYME';
	private static final String CODIGO_APLICACION_CUENTA_AHORRO = 'BCA';
	private static final String CODIGO_SUBAPLICACION_CUENTA_AHORRO = '204';
	private static final Integer HTTP_SUCCESS_MIN = 200;
	private static final Integer HTTP_SUCCESS_MAX = 300;
	private static final String ERROR_LOG_SEPARATOR = '\n--------------------\n';
	private static final Integer ERROR_LOG_MAX_LENGTH = 10000;
	private static final Integer ERROR_DETAIL_MAX_LENGTH = 3000;
	private static final Integer INTEGRATION_LOG_BODY_MAX_LENGTH = 131072;
	private static final Integer INTEGRATION_LOG_TEXT_MAX_LENGTH = 255;
	private static final String LOG_INTEGRATION_NAME = 'FSC_APIPrestamoDesembolso';
	private static final String LOG_FUNCTION_NAME = 'callDesembolsoIp';

	// Los logs se acumulan para no hacer DML entre callouts.
	private static List<IntegrationLog> pendingIntegrationLogs = new List<IntegrationLog>();

	@TestVisible
	private static Object mockIpResponse;

	@TestVisible
	private static Map<String, Object> lastIpInput;

	public class Input {
		@InvocableVariable(required=true)
		public Id residentialLoanApplicationId;

		@InvocableVariable(label='codigoUsuario')
		public String codigoUsuario;

		@InvocableVariable(label='codigoAgencia')
		public String codigoAgencia;
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

	@InvocableMethod(label='FSC - Desembolsar prestamo' description='Invoca API Desembolso y actualiza el subestado cuando la respuesta HTTP es exitosa.')
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
		User currentUser = needsCurrentUserData(inputs) ? getCurrentUserData() : null;
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
					firstNonBlank(
						new List<String>{ inputItem.codigoUsuario, currentUser == null ? null : currentUser.FSC_CodigoAbanks__c, 'LOBAL001' }
					),
					firstNonBlank(
						new List<String>{
							inputItem.codigoAgencia,
							currentUser == null ? null : currentUser.USE_Oficina__c,
							extractCode(rla.FSC_Grupo_de_Empresa__c)
						}
					)
				);
				outputItem.ipInput = JSON.serialize(ipInput);

				Object rawResponse = callDesembolsoIp(ipInput);
				DesembolsoResponse response = parseDesembolsoResponse(rawResponse);
				outputItem.statusCode = response.statusCode;
				outputItem.responseJson = response.responseJson;

				if (isSuccessStatus(response.statusCode)) {
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
					outputItem.message = 'API devolvio StatusCode=' + String.valueOf(response.statusCode) + '.';
					pendingUpdates.add(
						new PendingUpdate(buildErrorUpdate(rla, outputItem), outputItem)
					);
				}

				outputs.add(outputItem);
			} catch (Exception e) {
				outputItem.success = false;
				outputItem.message = 'Error: ' + e.getMessage();
				outputs.add(outputItem);

				if (rla != null) {
					pendingUpdates.add(
						new PendingUpdate(buildErrorUpdate(rla, outputItem), outputItem)
					);
				}
			}
		}

		persistIntegrationLogs();
		applyUpdates(pendingUpdates);
		return outputs;
	}

	public static Object callDesembolsoIp(Map<String, Object> inputMap) {
		lastIpInput = inputMap;

		if (Test.isRunningTest() && mockIpResponse != null) {
			return mockIpResponse;
		}

		// El API espera solamente el contenido de bodyRequest.
		Object requestBody = inputMap == null ? null : inputMap.get('bodyRequest');
		HttpRequest request = new HttpRequest();
		request.setEndpoint(DESEMBOLSO_ENDPOINT);
		request.setMethod('POST');
		request.setTimeout(HTTP_TIMEOUT);
		request.setHeader('Content-Type', 'application/json');
		request.setHeader(API_KEY_HEADER, getApiKey());
		request.setBody(JSON.serialize(requestBody == null ? inputMap : requestBody));

		HttpResponse response;
		try {
			response = new Http().send(request);
		} catch (Exception e) {
			pendingIntegrationLogs.add(new IntegrationLog(request.getBody(), 'Error: ' + e.getMessage(), 0, 'SIN RESPUESTA'));
			throw e;
		}
		pendingIntegrationLogs.add(
			new IntegrationLog(request.getBody(), response.getBody(), response.getStatusCode(), response.getStatus())
		);

		return new Map<String, Object>{
			'StatusCode' => response.getStatusCode(),
			'body' => response.getBody()
		};
	}

	@TestVisible
	private static Map<String, Object> buildIpInput(
		ResidentialLoanApplication rla,
		LoanApplicant debtor,
		String codigoUsuario,
		String codigoAgencia
	) {
		Boolean usarCuentaPyme = debtor == null && isPyme(rla);
		String tipoIdentificacion = usarCuentaPyme
			? (rla.Account == null ? null : rla.Account.ACC_TipoIdentificacion__c)
			: (debtor == null ? null : debtor.FSC_TipoIdentificacion__c);
		String numeroIdentificacion = usarCuentaPyme
			? (rla.Account == null ? null : rla.Account.ACC_NumIdentificacion__c)
			: (debtor == null ? null : debtor.FSC_NumIdentificacion__c);
		String origenIdentificacion = usarCuentaPyme ? 'Account' : 'LoanApplicant';

		List<String> missingFields = new List<String>();
		addMissingIfBlank(missingFields, codigoUsuario, 'User.FSC_CodigoAbanks__c');
		addMissingIfBlank(missingFields, rla.FSC_NumeroPrestamoAbanks__c, 'FSC_NumeroPrestamoAbanks__c');
		if (!usarCuentaPyme) {
			addMissingIfNull(missingFields, debtor, 'LoanApplicant Deudor');
		}
		addMissingIfBlank(missingFields, tipoIdentificacion, origenIdentificacion + '.TipoIdentificacion');
		addMissingIfBlank(missingFields, numeroIdentificacion, origenIdentificacion + '.NumeroIdentificacion');
		addMissingIfBlank(missingFields, codigoAgencia, 'codigoAgencia');
		addMissingIfBlank(missingFields, rla.FSC_NumeroCuentaDesembolso__c, 'FSC_NumeroCuentaDesembolso__c');

		if (!missingFields.isEmpty()) {
			throw new IllegalArgumentException('Faltan datos requeridos para FSC_APIDesembolso: ' + String.join(missingFields, ', ') + '.');
		}

		String codigoTipoIdentificacion = mapCodigoTipoIdentificacion(tipoIdentificacion);
		numeroIdentificacion = formatNumeroIdentificacion(numeroIdentificacion, codigoTipoIdentificacion);
		Map<String, Object> desembolso = new Map<String, Object>{
			'numeroPrestamo' => parseWholeNumber(rla.FSC_NumeroPrestamoAbanks__c, 'FSC_NumeroPrestamoAbanks__c'),
			'codigoTipoIdentificacion' => parseWholeNumber(codigoTipoIdentificacion, origenIdentificacion + '.TipoIdentificacion'),
			'numeroIdentificacion' => numeroIdentificacion,
			// La cuenta destino es de ahorros; el API de desembolso espera BCA.
			'codigoAplicacion' => CODIGO_APLICACION_CUENTA_AHORRO,
			'codigoAgencia' => parseWholeNumber(extractCode(codigoAgencia), 'codigoAgencia'),
			'codigoSubAplicacion' => parseWholeNumber(CODIGO_SUBAPLICACION_CUENTA_AHORRO, 'codigoSubAplicacion'),
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
					RecordType.DeveloperName,
					AccountId,
					Account.ACC_TipoIdentificacion__c,
					Account.ACC_NumIdentificacion__c,
					FSC_Subestado__c,
					FSC_NumeroPrestamoAbanks__c,
					FSC_Grupo_de_Empresa__c,
					FSC_NumeroCuentaDesembolso__c,
					FSC_LogErrores__c
				FROM ResidentialLoanApplication
				WHERE Id IN :rlaIds
			]
		);
	}

	private static Boolean isPyme(ResidentialLoanApplication rla) {
		return rla != null && rla.RecordType != null && rla.RecordType.DeveloperName == RECORD_TYPE_PYME;
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

	private static Boolean needsCurrentUserData(List<Input> inputs) {
		for (Input inputItem : inputs) {
			if (inputItem != null && (String.isBlank(inputItem.codigoUsuario) || String.isBlank(inputItem.codigoAgencia))) {
				return true;
			}
		}
		return false;
	}

	private static User getCurrentUserData() {
		User currentUser = [
			SELECT FSC_CodigoAbanks__c, USE_Oficina__c
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];
		return currentUser;
	}

	@SuppressWarnings('PMD.ApexCRUDViolation')
	private static void persistIntegrationLogs() {
		if (pendingIntegrationLogs.isEmpty()) {
			return;
		}

		List<IntegrationLog> logs = pendingIntegrationLogs;
		pendingIntegrationLogs = new List<IntegrationLog>();

		List<INT_Request__c> requests = new List<INT_Request__c>();
		for (IntegrationLog log : logs) {
			requests.add(
				new INT_Request__c(
					Trama_de_env_o__c = truncateForIntegrationLog(log.requestBody, INTEGRATION_LOG_BODY_MAX_LENGTH),
					Integraci_n__c = LOG_INTEGRATION_NAME,
					Funci_n__c = LOG_FUNCTION_NAME
				)
			);
		}

		// Un fallo del log no debe impedir actualizar la solicitud.
		Savepoint loggingSavepoint = Database.setSavepoint();
		try {
			insert requests;

			List<INT_Response__c> responses = new List<INT_Response__c>();
			for (Integer i = 0; i < logs.size(); i++) {
				responses.add(
					new INT_Response__c(
						INT_Request__c = requests[i].Id,
						Trama_de_respuesta__c = truncateForIntegrationLog(logs[i].responseBody, INTEGRATION_LOG_BODY_MAX_LENGTH),
						Http_Status_Code__c = logs[i].statusCode,
						Status__c = truncateForIntegrationLog(logs[i].status, INTEGRATION_LOG_TEXT_MAX_LENGTH)
					)
				);
			}
			insert responses;
		} catch (Exception e) {
			Database.rollback(loggingSavepoint);
			System.debug(LoggingLevel.ERROR, 'No se pudo registrar el log de integracion: ' + e.getMessage());
		}
	}

	private static String getApiKey() {
		FSC_APIPrestamoConfig__mdt config = FSC_APIPrestamoConfig__mdt.getInstance(API_KEY_CONFIG);
		if (config == null || String.isBlank(config.FSC_ApiKey__c)) {
			throw new CalloutException('Falta configurar FSC_APIPrestamoConfig__mdt.' + API_KEY_CONFIG + '.FSC_ApiKey__c.');
		}
		return config.FSC_ApiKey__c;
	}

	private static String truncateForIntegrationLog(String value, Integer maxLength) {
		return value == null || value.length() <= maxLength ? value : value.substring(0, maxLength);
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

	private static String formatNumeroIdentificacion(String numeroIdentificacion, String codigoTipoIdentificacion) {
		if (String.isBlank(numeroIdentificacion) || codigoTipoIdentificacion != '1') {
			return numeroIdentificacion;
		}

		String digitos = numeroIdentificacion.replaceAll('[^0-9]', '');
		if (digitos.length() < 5) {
			throw new IllegalArgumentException('El numero de cedula debe contener al menos cinco digitos.');
		}

		// Conserva todos los dígitos intermedios, sin asumir una longitud fija.
		return digitos.substring(0, 3) + '-' + digitos.substring(3, digitos.length() - 1) + '-' + digitos.right(1);
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

	private static Boolean isSuccessStatus(Integer statusCode) {
		return statusCode != null && statusCode >= HTTP_SUCCESS_MIN && statusCode < HTTP_SUCCESS_MAX;
	}

	private static String extractCode(String value) {
		if (String.isBlank(value)) {
			return null;
		}

		String normalizedValue = value.trim();
		Integer descriptionSeparator = normalizedValue.indexOf(' - ');
		return descriptionSeparator > 0 ? normalizedValue.substring(0, descriptionSeparator).trim() : normalizedValue;
	}

	private static String firstNonBlank(List<String> values) {
		for (String value : values) {
			if (!String.isBlank(value)) {
				return value.trim();
			}
		}
		return null;
	}

	private static ResidentialLoanApplication buildErrorUpdate(ResidentialLoanApplication rla, Output outputItem) {
		List<String> details = new List<String>{ outputItem.message };
		if (outputItem.statusCode != null) {
			details.add('statusCode=' + String.valueOf(outputItem.statusCode));
		}
		if (!String.isBlank(outputItem.responseJson)) {
			details.add('response=' + trimForLog(outputItem.responseJson, ERROR_DETAIL_MAX_LENGTH));
		}

		String entry = Datetime.now().format('yyyy-MM-dd HH:mm:ss') + ' | API Desembolso | ' + String.join(details, ' | ');
		return new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_FlagErrorAPIDesembolso__c = true,
			FSC_LogErrores__c = appendErrorLog(rla.FSC_LogErrores__c, entry)
		);
	}

	private static String appendErrorLog(String currentLog, String newEntry) {
		String combinedLog = String.isBlank(currentLog) ? newEntry : currentLog + ERROR_LOG_SEPARATOR + newEntry;
		return combinedLog.length() <= ERROR_LOG_MAX_LENGTH
			? combinedLog
			: combinedLog.substring(combinedLog.length() - ERROR_LOG_MAX_LENGTH);
	}

	private static String trimForLog(String value, Integer maxLength) {
		return String.isBlank(value) || value.length() <= maxLength ? value : value.substring(0, maxLength) + '...';
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

	private class IntegrationLog {
		public String requestBody;
		public String responseBody;
		public Integer statusCode;
		public String status;

		public IntegrationLog(String requestBody, String responseBody, Integer statusCode, String status) {
			this.requestBody = requestBody;
			this.responseBody = responseBody;
			this.statusCode = statusCode;
			this.status = status;
		}
	}

	private class DesembolsoResponse {
		public Integer statusCode;
		public String responseJson;
	}
}