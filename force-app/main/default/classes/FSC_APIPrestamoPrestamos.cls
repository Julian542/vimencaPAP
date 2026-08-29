public with sharing class FSC_APIPrestamoPrestamos {
	private static final String INTEGRATION_PROCEDURE_NAME = 'FSC_APIPrestamos';
	private static final String SUCCESS_DESCRIPTION = 'Exitoso';
	private static final String SUBESTADO_DESEMBOLSO = 'Desembolso';

	@TestVisible
	private static Object mockIpResponse;

	@TestVisible
	private static Map<String, Object> lastIpInput;

	public class Input {
		@InvocableVariable(required=true)
		public Id residentialLoanApplicationId;

		@InvocableVariable(label='productoJson')
		public String productoJson;

		@InvocableVariable(label='codigoUsuario')
		public String codigoUsuario;

		@InvocableVariable(label='codigoAgencia')
		public String codigoAgencia;

		@InvocableVariable(label='codigoEjecutivo')
		public String codigoEjecutivo;
	}

	public class Output {
		@InvocableVariable
		public Boolean success;

		@InvocableVariable
		public String message;

		@InvocableVariable
		public String descripcionRespuesta;

		@InvocableVariable
		public String descripcionTecnica;

		@InvocableVariable
		public String codigoRespuesta;

		@InvocableVariable
		public String numeroPrestamo;

		@InvocableVariable
		public String responseJson;

		@InvocableVariable
		public String ipInput;
	}

	@InvocableMethod(
		label='FSC - Crear prestamo'
		description='Invoca IP FSC_APIPrestamos y actualiza numero de prestamo y subestado cuando la respuesta es exitosa.'
	)
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

		Map<Id, ResidentialLoanApplication> rlaById = new Map<Id, ResidentialLoanApplication>();
		if (!rlaIds.isEmpty()) {
			rlaById = new Map<Id, ResidentialLoanApplication>(
				[
					SELECT
						Id,
						Name,
						AccountId,
						Account.ACC_NumIdentificacion__c,
						Account.ACC_TipoIdentificacion__c,
						CreatedDate,
						Status,
						FSC_Subestado__c,
						FSC_Grupo_de_Empresa__c,
						FSC_MontoAprobado__c,
						FSC_MontoCuotaRegular__c,
						FSC_PlazoMesesAprobado__c,
						FSC_TasaInteresAprobada__c,
						FSC_FechaYHoraAprobacionComite__c,
						FSC_FechaVencimiento__c,
						FSC_subAplicacion__c,
						FSC_CodigoAprobacion__c,
						FSC_TipoTasa__c,
						FSC_TipoFrecuenciaRevision__c,
						FSC_PeriodoTasa__c,
						FSC_DiaRevisionTasa__c,
						FSC_FechaRevisionInteres__c,
						FSC_FechaPrimerPagoInteres__c,
						FSC_FechaPrimerPagoCapital__c
					FROM ResidentialLoanApplication
					WHERE Id IN :rlaIds
					WITH USER_MODE
				]
			);
		}

		List<PendingUpdate> pendingUpdates = new List<PendingUpdate>();

		for (Input inputItem : inputs) {
			Output outputItem = new Output();
			outputItem.success = false;

			try {
				if (inputItem == null || inputItem.residentialLoanApplicationId == null) {
					outputItem.message = 'residentialLoanApplicationId requerido.';
					outputs.add(outputItem);
					continue;
				}

				ResidentialLoanApplication rla = rlaById.get(inputItem.residentialLoanApplicationId);
				if (rla == null) {
					outputItem.message = 'No se encontro ResidentialLoanApplication para el Id provisto.';
					outputs.add(outputItem);
					continue;
				}

				Map<String, Object> ipInput = buildIpInput(rla, inputItem);
				outputItem.ipInput = JSON.serialize(ipInput);
				Object rawResponse = callPrestamosIp(ipInput);
				PrestamosResponse response = parsePrestamosResponse(rawResponse);

				outputItem.descripcionRespuesta = response.descripcionRespuesta;
				outputItem.descripcionTecnica = response.descripcionTecnica;
				outputItem.codigoRespuesta = response.codigoRespuesta;
				outputItem.numeroPrestamo = response.numeroPrestamo;
				outputItem.responseJson = response.responseJson;

				if (response.descripcionRespuesta != SUCCESS_DESCRIPTION) {
					outputItem.message = 'IP devolvio descripcionRespuesta=' + String.valueOf(response.descripcionRespuesta) + '.';
					outputs.add(outputItem);
					pendingUpdates.add(
						new PendingUpdate(
							new ResidentialLoanApplication(
								Id = rla.Id,
								FSC_FlagErrorAPIPrestamos__c = true
							),
							outputItem
						)
					);
					continue;
				}

				if (String.isBlank(response.numeroPrestamo)) {
					outputItem.message = 'IP devolvio Exitoso pero no incluyo numeroPrestamo.';
					outputs.add(outputItem);
					continue;
				}

				pendingUpdates.add(
					new PendingUpdate(
						new ResidentialLoanApplication(
							Id = rla.Id,
							FSC_NumeroPrestamoAbanks__c = response.numeroPrestamo,
							FSC_Subestado__c = SUBESTADO_DESEMBOLSO,
							FSC_FlagErrorAPIPrestamos__c = false
						),
						outputItem
					)
				);

				outputItem.success = true;
				outputItem.message = 'Prestamo creado en ABANKS.';
				outputs.add(outputItem);
			} catch (Exception e) {
				outputItem.success = false;
				outputItem.message = 'Error: ' + e.getMessage();
				outputs.add(outputItem);
			}
		}

		applyUpdates(pendingUpdates);
		return outputs;
	}

	public static Object callPrestamosIp(Map<String, Object> inputMap) {
		lastIpInput = inputMap;

		if (Test.isRunningTest() && mockIpResponse != null) {
			return mockIpResponse;
		}

		return omnistudio.IntegrationProcedureService.runIntegrationService(INTEGRATION_PROCEDURE_NAME, inputMap, new Map<String, Object>());
	}

	@TestVisible
	private static Map<String, Object> buildIpInput(ResidentialLoanApplication rla, Input inputItem) {
		Map<String, Object> producto = parseProduct(inputItem == null ? null : inputItem.productoJson);
		String numeroIdentificacion = rla.Account == null ? null : rla.Account.ACC_NumIdentificacion__c;
		String plazo = getPlazo(rla);
		Decimal montoInicial = rla.FSC_MontoAprobado__c;
		Decimal valorCuota = rla.FSC_MontoCuotaRegular__c;
		Decimal tasaAprobada = rla.FSC_TasaInteresAprobada__c;
		String claveProducto = valueToString(producto == null ? null : producto.get('CLAVE_PRODUCTO'));
		String codigoAgencia = inputItem == null ? null : inputItem.codigoAgencia;
		String codigoTipoAmortizacion = valueToString(producto == null ? null : producto.get('CODIGO_TIPO_AMORTIZACION'));
		String codigoEstadoCartera = valueToString(producto == null ? null : producto.get('CODIGO_ESTADO_CARTERA'));
		String diasGraciaMora = valueToString(producto == null ? null : producto.get('DIAS_GRACIA_MORA'));
		Object rawCodigoValorTasaCartera = producto == null ? null : producto.get('CODIGO_VALOR_TASA_CARTERA');
		String codigoValorTasaCartera = valueToString(rawCodigoValorTasaCartera);
		Decimal tasaBaseIntCorriente = valueToDecimal(rawCodigoValorTasaCartera, 'productoJson.CODIGO_VALOR_TASA_CARTERA');

		List<String> missingFields = new List<String>();
		addMissingIfBlank(missingFields, numeroIdentificacion, 'Account.ACC_NumIdentificacion__c');
		addMissingIfBlank(
			missingFields,
			mapCodigoTipoIdentificacion(rla.Account == null ? null : rla.Account.ACC_TipoIdentificacion__c),
			'Account.ACC_TipoIdentificacion__c'
		);
		addMissingIfBlank(missingFields, rla.FSC_Grupo_de_Empresa__c, 'FSC_Grupo_de_Empresa__c');
		addMissingIfBlank(missingFields, codigoAgencia, 'codigoAgencia');
		addMissingIfNull(missingFields, montoInicial, 'FSC_MontoAprobado__c');
		addMissingIfNull(missingFields, valorCuota, 'FSC_MontoCuotaRegular__c');
		addMissingIfNull(missingFields, tasaAprobada, 'FSC_TasaInteresAprobada__c');
		addMissingIfBlank(missingFields, plazo, 'FSC_PlazoMesesAprobado__c');
		addMissingIfBlank(missingFields, rla.FSC_subAplicacion__c, 'FSC_subAplicacion__c');
		addMissingIfNull(missingFields, rla.FSC_FechaVencimiento__c, 'FSC_FechaVencimiento__c');
		addMissingIfBlank(missingFields, claveProducto, 'productoJson.CLAVE_PRODUCTO');
		addMissingIfBlank(missingFields, codigoTipoAmortizacion, 'productoJson.CODIGO_TIPO_AMORTIZACION');
		addMissingIfBlank(missingFields, codigoValorTasaCartera, 'productoJson.CODIGO_VALOR_TASA_CARTERA');
		addMissingIfBlank(missingFields, codigoEstadoCartera, 'productoJson.CODIGO_ESTADO_CARTERA');
		addMissingIfBlank(missingFields, rla.FSC_TipoTasa__c, 'FSC_TipoTasa__c');
		addMissingIfBlank(missingFields, rla.FSC_TipoFrecuenciaRevision__c, 'FSC_TipoFrecuenciaRevision__c');
		addMissingIfNull(missingFields, rla.FSC_PeriodoTasa__c, 'FSC_PeriodoTasa__c');
		addMissingIfNull(missingFields, rla.FSC_DiaRevisionTasa__c, 'FSC_DiaRevisionTasa__c');
		addMissingIfNull(missingFields, rla.FSC_FechaRevisionInteres__c, 'FSC_FechaRevisionInteres__c');
		addMissingIfBlank(missingFields, diasGraciaMora, 'productoJson.DIAS_GRACIA_MORA');
		addMissingIfNull(missingFields, rla.FSC_FechaPrimerPagoInteres__c, 'FSC_FechaPrimerPagoInteres__c');
		addMissingIfNull(missingFields, rla.FSC_FechaPrimerPagoCapital__c, 'FSC_FechaPrimerPagoCapital__c');

		if (!missingFields.isEmpty()) {
			throw new IllegalArgumentException('Faltan datos requeridos para FSC_APIPrestamos: ' + String.join(missingFields, ', ') + '.');
		}

		Map<String, Object> prestamoItem = new Map<String, Object>{
			'numeroSolicitud' => '',
			'codigoTipoIdentificacion' => mapCodigoTipoIdentificacion(rla.Account.ACC_TipoIdentificacion__c),
			'numeroIdentificacion' => numeroIdentificacion,
			'codigoEmpresa' => rla.FSC_Grupo_de_Empresa__c,
			'codigoAgencia' => codigoAgencia,
			'codigoSubAplicacion' => rla.FSC_subAplicacion__c,
			'claveProducto' => claveProducto,
			'codigoTipoAmortizacion' => codigoTipoAmortizacion,
			'codigoEstadoCartera' => codigoEstadoCartera,
			'montoInicial' => montoInicial,
			'valorCuota' => valorCuota,
			'codigoValorTasaCartera' => codigoValorTasaCartera,
			'tasaBaseIntCorriente' => tasaBaseIntCorriente,
			'relacionMatematica1' => '',
			'spreadCorriente1' => '',
			'tasaTotal' => tasaAprobada,
			'tipoTasa' => rla.FSC_TipoTasa__c,
			'tipoFrecuenciaRevision' => rla.FSC_TipoFrecuenciaRevision__c,
			'periodoTasa' => decimalToIntegerString(rla.FSC_PeriodoTasa__c),
			'diaRevisionTasa' => decimalToIntegerString(rla.FSC_DiaRevisionTasa__c),
			'fechaRevisionInt' => formatAbanksDate(rla.FSC_FechaRevisionInteres__c),
			'calcularMora' => '',
			'diasGraciaMora' => diasGraciaMora,
			'tasaBaseIntMora' => '',
			'spreadMora' => '',
			'relacionMatematicaMora' => '',
			'codigoValorTasaMora' => '',
			'diaPagoCapital' => '',
			'diaPagoInteres' => '',
			'numeroCuotas' => plazo,
			'numeroCuotasCapital' => plazo,
			'fechaAprobacion' => formatAbanksDate(datetimeToDate(rla.FSC_FechaYHoraAprobacionComite__c)),
			'fechaApertura' => formatAbanksDate(datetimeToDate(rla.CreatedDate)),
			'codigoAprobacion' => firstNonBlank(new List<String>{ rla.FSC_CodigoAprobacion__c, '' }),
			'fechaPrimerPagoInteres' => formatAbanksDate(rla.FSC_FechaPrimerPagoInteres__c),
			'fechaPrimerPagoCapital' => formatAbanksDate(rla.FSC_FechaPrimerPagoCapital__c),
			'valorRescate' => '',
			'fechaVencimiento' => formatAbanksDate(rla.FSC_FechaVencimiento__c),
			'fechaVencimientoCalculado' => '',
			'codigoEjecutivo' => firstNonBlank(
				new List<String>{ inputItem == null ? null : inputItem.codigoEjecutivo, inputItem == null ? null : inputItem.codigoUsuario, 'ABANKS' }
			)
		};

		return new Map<String, Object>{
			'codigoUsuario' => firstNonBlank(new List<String>{ inputItem == null ? null : inputItem.codigoUsuario, 'LOBAL001' }),
			'prestamo' => new Map<String, Object>{ 'prPrestamosItem' => new List<Object>{ prestamoItem } },
			'deducciones' => new Map<String, Object>{ 'prDeduccionesItem' => new List<Object>(), 'prdeduccionesItem' => new List<Object>() }
		};
	}

	@SuppressWarnings('PMD.ApexCRUDViolation')
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

	private static PrestamosResponse parsePrestamosResponse(Object rawResponse) {
		Map<String, Object> responseMap = normalizeResponseToMap(rawResponse);

		PrestamosResponse response = new PrestamosResponse();
		response.descripcionRespuesta = valueToString(responseMap.get('descripcionRespuesta'));
		response.descripcionTecnica = valueToString(responseMap.get('descripcionTecnica'));
		response.codigoRespuesta = valueToString(responseMap.get('codigoRespuesta'));
		response.numeroPrestamo = valueToString(responseMap.get('numeroPrestamo'));
		response.responseJson = serializeResponse(rawResponse);
		return response;
	}

	private static Map<String, Object> normalizeResponseToMap(Object response) {
		Map<String, Object> responseMap = toMap(response);
		if (responseMap == null) {
			return new Map<String, Object>();
		}

		Map<String, Object> httpPrestamos = toMap(responseMap.get('HTTPPrestamos'));
		return httpPrestamos == null ? responseMap : httpPrestamos;
	}

	private static Map<String, Object> parseProduct(String productoJson) {
		if (String.isBlank(productoJson)) {
			return null;
		}

		return toMap(productoJson);
	}

	private static Map<String, Object> toMap(Object value) {
		if (value == null) {
			return null;
		}

		if (value instanceof Map<String, Object>) {
			return (Map<String, Object>) value;
		}

		try {
			Object normalizedValue = value instanceof String
				? JSON.deserializeUntyped((String) value)
				: JSON.deserializeUntyped(JSON.serialize(value));
			return normalizedValue instanceof Map<String, Object> ? (Map<String, Object>) normalizedValue : null;
		} catch (Exception e) {
			return null;
		}
	}

	private static String getPlazo(ResidentialLoanApplication rla) {
		return decimalToIntegerString(rla.FSC_PlazoMesesAprobado__c);
	}

	private static String formatAbanksDate(Date value) {
		if (value == null) {
			return '';
		}

		List<String> months = new List<String>{ 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic' };
		String dayText = value.day() < 10 ? '0' + String.valueOf(value.day()) : String.valueOf(value.day());
		return dayText + '-' + months[value.month() - 1] + '-' + String.valueOf(value.year());
	}

	private static Date datetimeToDate(Datetime value) {
		return value == null ? null : value.date();
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

	private static String firstNonBlank(List<String> values) {
		for (String value : values) {
			if (!String.isBlank(value)) {
				return value.trim();
			}
		}
		return null;
	}

	private static String decimalToIntegerString(Decimal value) {
		return value == null ? null : String.valueOf(value.setScale(0));
	}

	private static Decimal valueToDecimal(Object value, String fieldName) {
		String textValue = valueToString(value);
		if (String.isBlank(textValue)) {
			return null;
		}

		try {
			return Decimal.valueOf(textValue);
		} catch (Exception e) {
			throw new IllegalArgumentException('Valor numerico invalido en ' + fieldName + ': ' + textValue + '.');
		}
	}

	private static String valueToString(Object value) {
		if (value == null) {
			return null;
		}

		String textValue = String.valueOf(value).trim();
		return textValue.endsWith('.0') ? textValue.substring(0, textValue.length() - 2) : textValue;
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

	private class PrestamosResponse {
		public String descripcionRespuesta;
		public String descripcionTecnica;
		public String codigoRespuesta;
		public String numeroPrestamo;
		public String responseJson;
	}
}