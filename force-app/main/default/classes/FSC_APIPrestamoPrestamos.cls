public with sharing class FSC_APIPrestamoPrestamos {
	private static final String PRESTAMOS_ENDPOINT = 'callout:FSC_APIPrestamo/api/prestamo/prestamos';
	private static final String TIPOS_GARANTIA_ENDPOINT = 'callout:FSC_APIPrestamo/api/prestamo/garantias/tipos';
	private static final String TIPOS_BIEN_ENDPOINT = 'callout:FSC_APIPrestamo/api/prestamo/garantias/tipos-bien';
	private static final String MODELOS_AUTO_ENDPOINT = 'callout:FSC_APIPrestamo/api/prestamo/garantias/modelos-auto';
	private static final String MARCAS_AUTO_ENDPOINT = 'callout:FSC_APIPrestamo/api/prestamo/garantias/marcas-auto';
	private static final String CLASES_GARANTIA_ENDPOINT = 'callout:FSC_APIPrestamo/api/prestamo/garantias/clases';
	private static final String CLASES_POR_TIPO_ENDPOINT = 'callout:FSC_APIPrestamo/api/prestamo/garantias/clases-por-tipo';
	private static final String ASEGURADORAS_ENDPOINT = 'callout:FSC_APIPrestamo/api/prestamo/garantias/aseguradoras';
	private static final String TIPOS_SALDO_ENDPOINT = 'callout:FSC_APIPrestamo/api/prestamo/tipos/saldo';
	private static final String TIPO_DEDUCCION_ABANKS = 'D';
	private static final String CAPITALIZAR_COMISION = 'S';
	// Gastos de la planilla de desembolso: el label de cada campo es la DESCRIPCION del tipo de saldo en ABANKS.
	private static final List<Schema.SObjectField> DEDUCTION_FIELDS = new List<Schema.SObjectField>{
		ResidentialLoanApplication.FSC_ComisionAdminSeguroMonto__c,
		ResidentialLoanApplication.FSC_TransferenciaInmobiliaria__c,
		ResidentialLoanApplication.FSC_TasasServicios__c,
		ResidentialLoanApplication.FSC_AyuntamientoRegistroCivil__c,
		ResidentialLoanApplication.FSC_OtrosGastosLegales__c,
		ResidentialLoanApplication.FSC_InscripcionHipoteca__c,
		ResidentialLoanApplication.FSC_ComisionEndosoPoliza__c,
		ResidentialLoanApplication.FSC_HonorariosLegalizacion__c,
		ResidentialLoanApplication.FSC_ConfeccionCheque__c
	};
	// Gastos cuyo label no coincide con la DESCRIPCION del tipo de saldo en ABANKS.
	private static final Map<Schema.SObjectField, String> TIPO_SALDO_DESCRIPTION_BY_FIELD = new Map<Schema.SObjectField, String>{
		ResidentialLoanApplication.FSC_ComisionAdminSeguroMonto__c => 'SERV. ADM DE SEGUROS',
		ResidentialLoanApplication.FSC_AyuntamientoRegistroCivil__c => 'PAGO POR REGISTRO DE PAGARE',
		ResidentialLoanApplication.FSC_ConfeccionCheque__c => 'IMP CK/TRANSF, ADMINISTRACION'
	};
	private static final String API_KEY_HEADER = 'X-API-KEY';
	private static final String API_KEY_CONFIG = 'Default';
	private static final Integer HTTP_TIMEOUT = 120000;
	private static final String SUCCESS_DESCRIPTION = 'Exitoso';
	private static final String SUBESTADO_DESEMBOLSO = 'Desembolso';
	private static final String FORMA_DESEMBOLSO_CUENTA_AHORRO = 'Cuenta de ahorro';
	// Valores fijos de ABANKS que no entrega el API de productos ni los catalogos de garantias.
	private static final String CODIGO_EMPRESA_ABANKS = '1';
	private static final String CODIGO_ESTADO_CARTERA_DEFAULT = 'A';
	private static final String ESTADO_GARANTIA_ABANKS = '2';
	private static final Integer PORCENTAJE_ASIGNACION_GARANTIA = 100;
	private static final String ERROR_LOG_SEPARATOR = '\n--------------------\n';
	private static final Integer ERROR_LOG_MAX_LENGTH = 10000;
	private static final Integer ERROR_DETAIL_MAX_LENGTH = 3000;
	private static final Integer INTEGRATION_LOG_BODY_MAX_LENGTH = 131072;
	private static final Integer INTEGRATION_LOG_TEXT_MAX_LENGTH = 255;
	private static final String LOG_INTEGRATION_NAME = 'FSC_APIPrestamoPrestamos';
	private static final String LOG_FUNCTION_NAME = 'callPrestamosIp';

	// Los logs se acumulan para no hacer DML entre callouts.
	private static List<IntegrationLog> pendingIntegrationLogs = new List<IntegrationLog>();

	@TestVisible
	private static Object mockIpResponse;

	@TestVisible
	private static Map<String, Object> lastIpInput;

	@TestVisible
	private static Map<String, Object> mockCatalogResponses;

	@TestVisible
	private static Boolean callCatalogHttpInTests = false;

	private static Map<Id, List<FSC_Garantia__c>> guaranteesByRlaId = new Map<Id, List<FSC_Garantia__c>>();
	private static Map<Id, List<LoanApplicationAsset>> assetsByRlaId = new Map<Id, List<LoanApplicationAsset>>();
	private static Map<Id, List<FSC_Seguro__c>> insurancesByRlaId = new Map<Id, List<FSC_Seguro__c>>();
	private static Map<Id, FSC_Garantia__c> catalogCodesByGuaranteeId = new Map<Id, FSC_Garantia__c>();
	private static Map<String, List<Map<String, Object>>> catalogCache = new Map<String, List<Map<String, Object>>>();
	private static GuaranteeCatalog guaranteeCatalog;
	private static Map<String, Integer> tipoSaldoCodesByDescription;

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
		description='Invoca API Prestamos y actualiza el numero de prestamo cuando la respuesta es exitosa.'
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
						RecordType.DeveloperName,
						AccountId,
						Account.ACC_NumIdentificacion__c,
						Account.ACC_TipoIdentificacion__c,
						CreatedDate,
						Status,
						FSC_Subestado__c,
						FSC_MontoAprobado__c,
						FSC_MontoCuotaRegular__c,
						FSC_Monto_De_La_Cuota__c,
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
						FSC_FechaPrimerPagoCapital__c,
						FSC_FormaDeDesembolso__c,
						FSC_Tipo_de_Garantia__c,
						FSC_Descripcion_de_la_Garantia__c,
						FSC_Valor_de_la_Garantia__c,
						FSC_Porcentaje_de_Admisibilidad__c,
						FSC_Moneda__c,
						FSC_ComisionAdminSeguroMonto__c,
						FSC_TransferenciaInmobiliaria__c,
						FSC_TasasServicios__c,
						FSC_AyuntamientoRegistroCivil__c,
						FSC_OtrosGastosLegales__c,
						FSC_InscripcionHipoteca__c,
						FSC_ComisionEndosoPoliza__c,
						FSC_HonorariosLegalizacion__c,
						FSC_ConfeccionCheque__c,
						FSC_LogErrores__c
					FROM ResidentialLoanApplication
					WHERE Id IN :rlaIds
					WITH USER_MODE
				]
			);
			loadGuaranteeData(rlaIds);
		}

		Map<Id, String> existingLoanNumberByRlaId = loadExistingLoanNumbers(rlaIds);
		String currentUserCode = needsCurrentUserCode(inputs) ? getCurrentUserCode() : null;
		List<PendingUpdate> pendingUpdates = new List<PendingUpdate>();
		Set<Id> processedRlaIds = new Set<Id>();
		Set<Id> habilitadas = FSC_ProcesamientoAbanks.habilitadas(rlaIds);

		for (Input inputItem : inputs) {
			Output outputItem = new Output();
			outputItem.success = false;
			ResidentialLoanApplication rla;

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

				if (!habilitadas.contains(rla.Id)) {
					outputItem.message = 'La automatización de Abanks está deshabilitada para esta solicitud. Continúe por Captura y Operaciones.';
					outputs.add(outputItem);
					continue;
				}

				// Evita crear el prestamo dos veces en ABANKS.
				if (!processedRlaIds.add(rla.Id)) {
					outputItem.message = 'La solicitud viene repetida en la misma ejecucion; se omite.';
					outputs.add(outputItem);
					continue;
				}
				if (existingLoanNumberByRlaId.containsKey(rla.Id)) {
					outputItem.numeroPrestamo = existingLoanNumberByRlaId.get(rla.Id);
					outputItem.message =
						'La solicitud ya tiene el prestamo ' + outputItem.numeroPrestamo + ' creado en ABANKS; no se vuelve a crear.';
					outputs.add(outputItem);
					continue;
				}

				if (String.isBlank(inputItem.codigoUsuario)) {
					inputItem.codigoUsuario = currentUserCode;
				}
				if (String.isBlank(inputItem.codigoEjecutivo)) {
					inputItem.codigoEjecutivo = currentUserCode;
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
					pendingUpdates.add(new PendingUpdate(buildErrorUpdate(rla, outputItem, inputItem), outputItem));
					continue;
				}

				if (String.isBlank(response.numeroPrestamo)) {
					outputItem.message = 'IP devolvio Exitoso pero no incluyo numeroPrestamo.';
					outputs.add(outputItem);
					pendingUpdates.add(new PendingUpdate(buildErrorUpdate(rla, outputItem, inputItem), outputItem));
					continue;
				}

				ResidentialLoanApplication successUpdate = new ResidentialLoanApplication(
					Id = rla.Id,
					FSC_NumeroPrestamoAbanks__c = response.numeroPrestamo,
					FSC_FlagErrorAPIPrestamos__c = false,
					FSC_ClaveProducto__c = getProductKey(inputItem)
				);

				// La cuenta de ahorro requiere validacion en Abanks antes del desembolso.
				if (rla.FSC_FormaDeDesembolso__c != FORMA_DESEMBOLSO_CUENTA_AHORRO) {
					successUpdate.FSC_Subestado__c = SUBESTADO_DESEMBOLSO;
				}

				pendingUpdates.add(new PendingUpdate(successUpdate, outputItem));

				outputItem.success = true;
				outputItem.message = 'Prestamo creado en ABANKS.';
				outputs.add(outputItem);
			} catch (Exception e) {
				outputItem.success = false;
				outputItem.message = 'Error: ' + e.getMessage();
				outputs.add(outputItem);
				if (rla != null) {
					pendingUpdates.add(new PendingUpdate(buildErrorUpdate(rla, outputItem, inputItem), outputItem));
				}
			}
		}

		persistIntegrationLogs();
		applyUpdates(pendingUpdates);
		return outputs;
	}

	public static Object callPrestamosIp(Map<String, Object> inputMap) {
		lastIpInput = inputMap;

		if (Test.isRunningTest() && mockIpResponse != null) {
			return mockIpResponse;
		}

		// El callout directo evita que OmniStudio descarte el body del POST.
		HttpRequest request = new HttpRequest();
		request.setEndpoint(PRESTAMOS_ENDPOINT);
		request.setMethod('POST');
		request.setTimeout(HTTP_TIMEOUT);
		request.setHeader('Content-Type', 'application/json');
		request.setHeader(API_KEY_HEADER, getApiKey());
		request.setBody(JSON.serialize(inputMap));

		HttpResponse response;
		try {
			response = new Http().send(request);
		} catch (Exception e) {
			pendingIntegrationLogs.add(new IntegrationLog(LOG_FUNCTION_NAME, request.getBody(), 'Error: ' + e.getMessage(), 0, 'SIN RESPUESTA'));
			throw e;
		}
		queueCompletedCallout(LOG_FUNCTION_NAME, request, response);

		if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
			throw new CalloutException(
				'API Prestamos respondio HTTP ' + response.getStatusCode() + ': ' + trimForLog(response.getBody(), ERROR_DETAIL_MAX_LENGTH)
			);
		}
		return response.getBody();
	}

	@TestVisible
	private static Map<String, Object> buildIpInput(ResidentialLoanApplication rla, Input inputItem) {
		Map<String, Object> producto = parseProduct(inputItem == null ? null : inputItem.productoJson);
		String tipoIdentificacion = rla.Account == null ? null : rla.Account.ACC_TipoIdentificacion__c;
		String codigoTipoIdentificacion = mapCodigoTipoIdentificacion(tipoIdentificacion);
		String numeroIdentificacion = formatNumeroIdentificacion(
			rla.Account == null ? null : rla.Account.ACC_NumIdentificacion__c,
			codigoTipoIdentificacion
		);
		String plazo = getPlazo(rla);
		Decimal montoInicial = rla.FSC_MontoAprobado__c;
		Decimal valorCuota = rla.FSC_Monto_De_La_Cuota__c == null ? rla.FSC_MontoCuotaRegular__c : rla.FSC_Monto_De_La_Cuota__c;
		Decimal tasaAprobada = rla.FSC_TasaInteresAprobada__c;
		// FSC_Grupo_de_Empresa__c es el grupo economico del cliente, no la empresa de ABANKS.
		String codigoEmpresa = CODIGO_EMPRESA_ABANKS;
		String codigoUsuario = firstNonBlank(new List<String>{ inputItem == null ? null : inputItem.codigoUsuario });
		String codigoAgencia = extractCode(inputItem == null ? null : inputItem.codigoAgencia);
		String codigoSubAplicacion = extractCode(rla.FSC_subAplicacion__c);
		String claveProducto = valueToString(producto == null ? null : producto.get('CLAVE_PRODUCTO'));
		String codigoTipoAmortizacion = valueToString(producto == null ? null : producto.get('CODIGO_TIPO_AMORTIZACION'));
		String codigoEstadoCartera = firstNonBlank(
			new List<String>{ valueToString(producto == null ? null : producto.get('CODIGO_ESTADO_CARTERA')), CODIGO_ESTADO_CARTERA_DEFAULT }
		);
		String diasGraciaMora = valueToString(producto == null ? null : producto.get('DIAS_GRACIA_MORA'));
		Object rawCodigoValorTasaCartera = producto == null ? null : producto.get('CODIGO_VALOR_TASA_CARTERA');
		String codigoValorTasaCartera = valueToString(rawCodigoValorTasaCartera);
		Object rawTasaBaseInteres = producto == null ? null : producto.get('TASA_BASE_INTERES');
		Decimal tasaBaseIntCorriente = valueToDecimal(
			rawTasaBaseInteres == null ? rawCodigoValorTasaCartera : rawTasaBaseInteres,
			'productoJson.TASA_BASE_INTERES'
		);
		String relacionMatematica1 = valueToString(producto == null ? null : producto.get('RELACION_MATEMATICA_1'));
		Object rawSpreadCorriente1 = producto == null ? null : producto.get('SPREAD_CORRIENTE_1');
		Decimal spreadCorriente1 = rawSpreadCorriente1 == null ? 0 : valueToDecimal(rawSpreadCorriente1, 'productoJson.SPREAD_CORRIENTE_1');
		String calcularMora = valueToString(producto == null ? null : producto.get('CALCULAR_MORA'));
		String relacionMatematicaMora = valueToString(producto == null ? null : producto.get('RELACION_MATEMATICA_MORA'));
		Object rawSpreadMora = producto == null ? null : producto.get('SPREAD_MORA');
		Decimal spreadMora = rawSpreadMora == null ? 0 : valueToDecimal(rawSpreadMora, 'productoJson.SPREAD_MORA');
		String codigoValorTasaMora = valueToString(producto == null ? null : producto.get('CODIGO_VALOR_TASA_CARTERA_MORA'));

		List<String> missingFields = new List<String>();
		addMissingIfBlank(missingFields, codigoUsuario, 'codigoUsuario (User.FSC_CodigoAbanks__c o User.Alias)');
		addMissingIfBlank(missingFields, numeroIdentificacion, 'Account.ACC_NumIdentificacion__c');
		addMissingIfBlank(missingFields, codigoTipoIdentificacion, 'Account.ACC_TipoIdentificacion__c');
		addMissingIfBlank(missingFields, codigoAgencia, 'codigoAgencia');
		addMissingIfNull(missingFields, montoInicial, 'FSC_MontoAprobado__c');
		addMissingIfNull(missingFields, valorCuota, 'FSC_MontoCuotaRegular__c');
		addMissingIfNull(missingFields, tasaAprobada, 'FSC_TasaInteresAprobada__c');
		addMissingIfBlank(missingFields, plazo, 'FSC_PlazoMesesAprobado__c');
		addMissingIfBlank(missingFields, codigoSubAplicacion, 'FSC_subAplicacion__c');
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
			'codigoTipoIdentificacion' => codigoTipoIdentificacion,
			'numeroIdentificacion' => numeroIdentificacion,
			'codigoEmpresa' => codigoEmpresa,
			'codigoAgencia' => codigoAgencia,
			'codigoSubAplicacion' => codigoSubAplicacion,
			'claveProducto' => claveProducto,
			'codigoTipoAmortizacion' => codigoTipoAmortizacion,
			'codigoEstadoCartera' => codigoEstadoCartera,
			'montoInicial' => montoInicial,
			'valorCuota' => valorCuota,
			'codigoValorTasaCartera' => codigoValorTasaCartera,
			'tasaBaseIntCorriente' => tasaBaseIntCorriente,
			'relacionMatematica1' => relacionMatematica1,
			'spreadCorriente1' => spreadCorriente1,
			'tasaTotal' => tasaAprobada,
			'tipoTasa' => rla.FSC_TipoTasa__c,
			'tipoFrecuenciaRevision' => rla.FSC_TipoFrecuenciaRevision__c,
			'periodoTasa' => decimalToIntegerString(rla.FSC_PeriodoTasa__c),
			'diaRevisionTasa' => decimalToIntegerString(rla.FSC_DiaRevisionTasa__c),
			'fechaRevisionInt' => formatAbanksDate(rla.FSC_FechaRevisionInteres__c),
			'calcularMora' => calcularMora,
			'diasGraciaMora' => diasGraciaMora,
			'tasaBaseIntMora' => 0,
			'spreadMora' => spreadMora,
			'relacionMatematicaMora' => relacionMatematicaMora,
			'codigoValorTasaMora' => codigoValorTasaMora,
			'diaPagoCapital' => dateDayToString(rla.FSC_FechaPrimerPagoCapital__c),
			'diaPagoInteres' => dateDayToString(rla.FSC_FechaPrimerPagoInteres__c),
			'numeroCuotas' => plazo,
			'numeroCuotasCapital' => plazo,
			'fechaAprobacion' => formatAbanksDate(datetimeToDate(rla.FSC_FechaYHoraAprobacionComite__c)),
			'fechaApertura' => formatAbanksDate(datetimeToDate(rla.CreatedDate)),
			'codigoAprobacion' => firstNonBlank(new List<String>{ rla.FSC_CodigoAprobacion__c, '' }),
			'fechaPrimerPagoInteres' => formatAbanksDate(rla.FSC_FechaPrimerPagoInteres__c),
			'fechaPrimerPagoCapital' => formatAbanksDate(rla.FSC_FechaPrimerPagoCapital__c),
			'valorRescate' => 0,
			'fechaVencimiento' => formatAbanksDate(rla.FSC_FechaVencimiento__c),
			'fechaVencimientoCalculado' => '',
			'codigoEjecutivo' => firstNonBlank(
				new List<String>{ inputItem == null ? null : inputItem.codigoEjecutivo, codigoUsuario }
			)
		};
		GuaranteePayload guaranteePayload = buildGuaranteePayload(
			rla,
			numeroIdentificacion,
			codigoEmpresa,
			codigoAgencia,
			codigoSubAplicacion,
			plazo
		);
		List<Object> deductionItems = buildDeductionItems(rla, numeroIdentificacion);

		Map<String, Object> ipInput = new Map<String, Object>{
			'codigoUsuario' => codigoUsuario,
			'prestamo' => new Map<String, Object>{ 'prPrestamosItem' => new List<Object>{ prestamoItem } }
		};
		if (!guaranteePayload.guaranteeItems.isEmpty()) {
			ipInput.put('garantia', new Map<String, Object>{ 'gaGarantiasItem' => guaranteePayload.guaranteeItems });
		}
		if (!guaranteePayload.vehicleItems.isEmpty()) {
			ipInput.put('garantiaAutos', new Map<String, Object>{ 'gaAutosItem' => guaranteePayload.vehicleItems });
		}
		if (!deductionItems.isEmpty()) {
			ipInput.put('deducciones', new Map<String, Object>{ 'prDeduccionesItem' => deductionItems });
		}
		return ipInput;
	}

	// Un item por cada gasto de la planilla con monto; sin codigo de tipo de saldo no se crea el prestamo incompleto.
	private static List<Object> buildDeductionItems(ResidentialLoanApplication rla, String numeroIdentificacion) {
		List<Object> deductionItems = new List<Object>();
		List<String> labelsWithoutCode = new List<String>();
		for (Schema.SObjectField field : DEDUCTION_FIELDS) {
			Decimal valor = (Decimal) rla.get(field);
			if (valor == null || valor <= 0) {
				continue;
			}
			String label = field.getDescribe().getLabel();
			String description = TIPO_SALDO_DESCRIPTION_BY_FIELD.containsKey(field) ? TIPO_SALDO_DESCRIPTION_BY_FIELD.get(field) : label;
			Integer codigoTipoSaldo = getTipoSaldoCode(description);
			if (codigoTipoSaldo == null) {
				labelsWithoutCode.add(label);
				continue;
			}
			deductionItems.add(
				new Map<String, Object>{
					'numeroSolicitud' => '',
					'numeroIdentificacion' => numeroIdentificacion,
					'codigoTipoSaldo' => codigoTipoSaldo,
					'tipoDeduccion' => TIPO_DEDUCCION_ABANKS,
					'valor' => valor,
					'capitalizar' => normalizeText(label).contains('COMISION') ? CAPITALIZAR_COMISION : ''
				}
			);
		}
		if (!labelsWithoutCode.isEmpty()) {
			throw new IllegalArgumentException(
				'No existe tipo de saldo en ABANKS con la descripcion: ' + String.join(labelsWithoutCode, ', ') + '.'
			);
		}
		return deductionItems;
	}

	private static Integer getTipoSaldoCode(String description) {
		// El catalogo se consulta solo si hay gastos y una vez por transaccion.
		if (tipoSaldoCodesByDescription == null) {
			tipoSaldoCodesByDescription = new Map<String, Integer>();
			for (Map<String, Object> row : fetchCatalog(TIPOS_SALDO_ENDPOINT)) {
				String key = compactText(valueToString(row.get('DESCRIPCION')));
				if (!String.isBlank(key) && !tipoSaldoCodesByDescription.containsKey(key)) {
					tipoSaldoCodesByDescription.put(key, toInteger(row.get('CODIGO_TIPO_SALDO'), 'CODIGO_TIPO_SALDO'));
				}
			}
		}
		return tipoSaldoCodesByDescription.get(compactText(description));
	}

	// Se lee en modo sistema: el control de duplicados no puede depender del FLS del usuario.
	private static Map<Id, String> loadExistingLoanNumbers(Set<Id> rlaIds) {
		Map<Id, String> loanNumberByRlaId = new Map<Id, String>();
		if (rlaIds.isEmpty()) {
			return loanNumberByRlaId;
		}
		for (ResidentialLoanApplication rla : [
			SELECT Id, FSC_NumeroPrestamoAbanks__c
			FROM ResidentialLoanApplication
			WHERE Id IN :rlaIds AND FSC_NumeroPrestamoAbanks__c != NULL
			WITH SYSTEM_MODE
		]) {
			loanNumberByRlaId.put(rla.Id, rla.FSC_NumeroPrestamoAbanks__c);
		}
		return loanNumberByRlaId;
	}

	private static Boolean needsCurrentUserCode(List<Input> inputs) {
		for (Input inputItem : inputs) {
			if (inputItem != null && (String.isBlank(inputItem.codigoUsuario) || String.isBlank(inputItem.codigoEjecutivo))) {
				return true;
			}
		}
		return false;
	}

	// Usuario y ejecutivo ABANKS: el codigo ABANKS del usuario o, si no lo tiene, su alias.
	private static String getCurrentUserCode() {
		List<User> users = [SELECT FSC_CodigoAbanks__c, Alias FROM User WHERE Id = :UserInfo.getUserId() WITH SYSTEM_MODE LIMIT 1];
		if (users.isEmpty()) {
			return null;
		}
		return String.isBlank(users[0].FSC_CodigoAbanks__c) ? users[0].Alias : users[0].FSC_CodigoAbanks__c;
	}

	// Carga las relaciones antes de iniciar los callouts.
	private static void loadGuaranteeData(Set<Id> rlaIds) {
		guaranteesByRlaId = new Map<Id, List<FSC_Garantia__c>>();
		assetsByRlaId = new Map<Id, List<LoanApplicationAsset>>();
		insurancesByRlaId = new Map<Id, List<FSC_Seguro__c>>();

		for (FSC_Garantia__c guarantee : [
			SELECT
				Id,
				CreatedDate,
				FSC_Residential_Loan_Application__c,
				FSC_Clase_de_Garantia__c,
				FSC_Tipo_de_Garantia__c,
				FSC_Descripcion_de_la_Garantia__c,
				FSC_Tipo_de_Inmueble__c,
				FSC_Valor_Inmueble__c,
				FSC_Valor_Tasado__c,
				FSC_Precio_de_Venta__c,
				FSC_Fecha_Tasacion__c,
				FSC_Tipo_Vehiculo__c,
				FSC_Marca_Vehiculo__c,
				FSC_Modelo_Vehiculo__c,
				FSC_Ano_Vehiculo__c,
				FSC_Color_Vehiculo__c,
				FSC_Numero_Chasis_Vehiculo__c,
				FSC_Serial_Motor_Vehiculo__c,
				FSC_Numero_Placa_Vehiculo__c,
				FSC_Numero_Matricula__c,
				FSC_Valor_Vehiculo__c,
				FSC_Monto_Certificado_Deposito__c
			FROM FSC_Garantia__c
			WHERE FSC_Residential_Loan_Application__c IN :rlaIds
			WITH USER_MODE
			ORDER BY CreatedDate ASC, Id ASC
		]) {
			Id rlaId = guarantee.FSC_Residential_Loan_Application__c;
			if (!guaranteesByRlaId.containsKey(rlaId)) {
				guaranteesByRlaId.put(rlaId, new List<FSC_Garantia__c>());
			}
			guaranteesByRlaId.get(rlaId).add(guarantee);
		}

		// Los codigos del catalogo los completa el sistema; se leen aparte para no exigir permiso de campo al usuario.
		catalogCodesByGuaranteeId = new Map<Id, FSC_Garantia__c>(
			[
				SELECT Id, FSC_Codigo_Clase_Garantia__c, FSC_Codigo_Tipo_Garantia__c, FSC_Codigo_Marca_Vehiculo__c, FSC_Codigo_Modelo_Vehiculo__c
				FROM FSC_Garantia__c
				WHERE FSC_Residential_Loan_Application__c IN :rlaIds
				WITH SYSTEM_MODE
			]
		);

		for (LoanApplicationAsset asset : [
			SELECT
				Id,
				CreatedDate,
				LoanApplicationId,
				Name,
				AssetClass,
				AssetType,
				AccountType,
				CashOrMarketValue,
				FSC_Porcentaje_Admisibilidad__c,
				FSC_Descripcion_de_la_Garantia__c,
				FSC_Descripcion_Contrato__c,
				FSC_Tipo_Vehiculo_Contrato__c,
				FSC_Marca_Vehiculo_Contrato__c,
				FSC_Modelo_Vehiculo_Contrato__c,
				FSC_Ano_Vehiculo_Contrato__c,
				FSC_Color_Vehiculo_Contrato__c,
				FSC_Chasis_Vehiculo_Contrato__c,
				FSC_Motor_Vehiculo_Contrato__c,
				FSC_Placa_Vehiculo_Contrato__c,
				FSC_Matricula_Vehiculo_Contrato__c
			FROM LoanApplicationAsset
			WHERE LoanApplicationId IN :rlaIds
			WITH USER_MODE
			ORDER BY CreatedDate ASC, Id ASC
		]) {
			if (!assetsByRlaId.containsKey(asset.LoanApplicationId)) {
				assetsByRlaId.put(asset.LoanApplicationId, new List<LoanApplicationAsset>());
			}
			assetsByRlaId.get(asset.LoanApplicationId).add(asset);
		}

		for (FSC_Seguro__c insurance : [
			SELECT Id, CreatedDate, FSC_Residential_Loan_Application__c, FSC_Tipo_de_Seguro__c, FSC_Aseguradora_Contrato__c
			FROM FSC_Seguro__c
			WHERE FSC_Residential_Loan_Application__c IN :rlaIds
			WITH USER_MODE
			ORDER BY CreatedDate ASC, Id ASC
		]) {
			Id rlaId = insurance.FSC_Residential_Loan_Application__c;
			if (!insurancesByRlaId.containsKey(rlaId)) {
				insurancesByRlaId.put(rlaId, new List<FSC_Seguro__c>());
			}
			insurancesByRlaId.get(rlaId).add(insurance);
		}
	}

	private static GuaranteePayload buildGuaranteePayload(
		ResidentialLoanApplication rla,
		String numeroIdentificacion,
		String codigoEmpresa,
		String codigoAgencia,
		String codigoSubAplicacion,
		String plazo
	) {
		GuaranteePayload payload = new GuaranteePayload();
		List<GuaranteeSource> sources = getGuaranteeSources(rla);
		if (sources.isEmpty()) {
			return payload;
		}

		GuaranteeCatalog catalogs = getGuaranteeCatalog();
		FSC_Seguro__c insurance = getPropertyInsurance(rla.Id);
		Integer insuranceCode = catalogs.resolveInsuranceCode(
			insurance == null ? new List<String>() : new List<String>{ insurance.FSC_Aseguradora_Contrato__c, insurance.FSC_Tipo_de_Seguro__c }
		);
		Integer companyCode = toInteger(codigoEmpresa, 'codigoEmpresa');
		Integer agencyCode = toInteger(codigoAgencia, 'codigoAgencia');
		Integer subApplicationCode = toInteger(codigoSubAplicacion, 'FSC_subAplicacion__c');
		Integer contractLife = toInteger(plazo, 'FSC_PlazoMesesAprobado__c');

		for (Integer index = 0; index < sources.size(); index++) {
			GuaranteeSource source = sources[index];
			Integer sequence = index + 1;
			Integer guaranteeTypeCode;
			Integer guaranteeClassCode;
			if (source.usesStoredCodes) {
				// Las garantias capturadas guardan los codigos del catalogo; no se deducen por texto.
				guaranteeClassCode = catalogs.requireStoredClassCode(source, sequence);
				guaranteeTypeCode = catalogs.requireStoredTypeCode(source, guaranteeClassCode, sequence);
			} else {
				guaranteeTypeCode = catalogs.resolveGuaranteeTypeCode(source, rla.FSC_Moneda__c);
				if (guaranteeTypeCode == null) {
					throw new IllegalArgumentException(
						'No se encontro codigo de tipo para la garantia ' + sequence + ': ' + source.typeDescription + '.'
					);
				}

				guaranteeClassCode = catalogs.resolveGuaranteeClassCode(
					source.classCode,
					source.classReference,
					guaranteeTypeCode,
					source.vehicle,
					source.typeDescription
				);
				if (guaranteeClassCode == null) {
					throw new IllegalArgumentException(
						'No se encontro codigo de clase para la garantia ' + sequence + ': ' + source.classReference + '.'
					);
				}
			}

			Integer goodCode = catalogs.resolveGoodCode(
				new List<String>{ source.goodReference, source.typeDescription, source.classReference, source.description }
			);
			if (goodCode == null) {
				throw new IllegalArgumentException('No se encontro codigo de bien para la garantia ' + sequence + ': ' + source.goodReference + '.');
			}

			Decimal realValue = source.value == null ? 0 : source.value;
			Decimal coveragePercentage = source.percentage;
			if (coveragePercentage == null) {
				coveragePercentage = catalogs.getCoveragePercentage(guaranteeTypeCode);
			}
			if (coveragePercentage == null) {
				throw new IllegalArgumentException(
					'No hay porcentaje de cobertura para la garantia ' +
						sequence +
						': falta FSC_Porcentaje_de_Admisibilidad__c y el tipo ' +
						guaranteeTypeCode +
						' no trae PORCENTAJE_SIB.'
				);
			}
			Boolean solidary = normalizeText(firstNonBlank(new List<String>{ source.typeDescription, source.classReference, source.description }))
				.contains('SOLIDAR');
			Decimal guaranteeValue = solidary ? 0 : (realValue * coveragePercentage / 100);
			String description = firstNonBlank(
				new List<String>{ source.description, source.typeDescription, source.classReference, 'Garantia ' + sequence }
			);
			Date presentationDate = source.presentationDate == null ? Date.today() : source.presentationDate;

			payload.guaranteeItems.add(
				new Map<String, Object>{
					'numeroSolicitud' => '',
					'numeroIdentificacion' => numeroIdentificacion,
					'numeroGarantia' => sequence,
					'valorGarantia' => guaranteeValue,
					'codigoTipoGarantia' => guaranteeTypeCode,
					'descripcionGarantia' => description,
					'fechaPresentacion' => formatGuaranteeDate(presentationDate),
					'subType' => catalogs.getGoodSubtype(goodCode),
					'estado' => ESTADO_GARANTIA_ABANKS,
					'valorAvaluo' => realValue,
					'valorContable' => realValue,
					'valorDisponible' => guaranteeValue,
					'valorInicial' => realValue,
					'codigoEmpresa' => companyCode,
					'codigoAgencia' => agencyCode,
					'porcentajeAsignacion' => PORCENTAJE_ASIGNACION_GARANTIA,
					'porcentajeCobertura' => coveragePercentage,
					'valorRealGarantia' => realValue,
					'codigoSubAplicacion' => subApplicationCode,
					'observaciones' => description,
					'fechaDisponibilidad' => formatGuaranteeDate(presentationDate),
					'codigoBien' => goodCode,
					'codigoClaseGarantias' => guaranteeClassCode,
					'manejaSeguro' => catalogs.getManagesInsurance(guaranteeTypeCode, guaranteeClassCode, insurance != null),
					'codigoAseguradora' => insuranceCode,
					'codigoGrupo' => catalogs.getGoodGroup(goodCode),
					'codigoSubGrupo' => catalogs.getGoodSubgroup(goodCode)
				}
			);

			if (source.vehicle) {
				payload.vehicleItems.add(buildVehicleGuaranteeItem(source, catalogs, sequence, numeroIdentificacion, companyCode, contractLife));
			}
		}
		return payload;
	}

	private static Map<String, Object> buildVehicleGuaranteeItem(
		GuaranteeSource source,
		GuaranteeCatalog catalogs,
		Integer sequence,
		String numeroIdentificacion,
		Integer companyCode,
		Integer contractLife
	) {
		VehicleCodes vehicleCodes = catalogs.resolveVehicleCodes(source);
		List<String> missingFields = new List<String>();
		if (vehicleCodes.brandCode == null) {
			missingFields.add('marca ' + source.brand);
		}
		if (vehicleCodes.modelCode == null) {
			missingFields.add('modelo ' + source.model);
		}
		addMissingIfBlank(missingFields, source.motorNumber, 'numero de motor');
		addMissingIfBlank(missingFields, source.chassisNumber, 'numero de chasis');
		if (!missingFields.isEmpty()) {
			throw new IllegalArgumentException(
				'Faltan datos requeridos de la garantia vehicular ' + sequence + ': ' + String.join(missingFields, ', ') + '.'
			);
		}

		return new Map<String, Object>{
			'numeroSolicitud' => '',
			'numeroIdentificacion' => numeroIdentificacion,
			'codigoEmpresa' => companyCode,
			'secuenciaGarantia' => sequence,
			'numeroMotor' => source.motorNumber,
			'numeroChasis' => source.chassisNumber,
			'codigoMarca' => vehicleCodes.brandCode,
			'codigoModelo' => vehicleCodes.modelCode,
			'descripcionModelo' => firstNonBlank(new List<String>{ source.model, vehicleCodes.modelDescription, '' }),
			'capacidad' => vehicleCodes.capacity == null ? 0 : vehicleCodes.capacity,
			'traccion' => '',
			'combustible' => '',
			'cilindrada' => '',
			'costoCompra' => source.value == null ? 0 : source.value,
			'carroNumeroUsado' => firstNonBlank(new List<String>{ source.registrationNumber, '' }),
			'tipoDeCambio' => 0,
			'colorAuto' => firstNonBlank(new List<String>{ source.color, '' }),
			'capacidadToneladas' => 0,
			'anoAuto' => source.year == null ? 0 : source.year.intValue(),
			'noPlaca' => firstNonBlank(new List<String>{ source.plateNumber, '' }),
			'usoAuto' => firstNonBlank(new List<String>{ source.goodReference, 'OTROS' }),
			'clase' => vehicleCodes.vehicleClass == null ? 0 : vehicleCodes.vehicleClass,
			'tipoPlazo' => 0,
			'vidaUtilBien' => 0,
			'vidaUtilContrato' => contractLife,
			'proveedorGps' => ''
		};
	}

	private static List<GuaranteeSource> getGuaranteeSources(ResidentialLoanApplication rla) {
		List<GuaranteeSource> sources = new List<GuaranteeSource>();
		String recordTypeName = rla.RecordType == null ? null : rla.RecordType.DeveloperName;
		if (recordTypeName == 'FSC_Solicitud_Credito_PYME') {
			for (LoanApplicationAsset asset : safeAssets(rla.Id)) {
				sources.add(fromLoanApplicationAsset(asset, rla));
			}
		} else {
			for (FSC_Garantia__c guarantee : safeGuarantees(rla.Id)) {
				sources.add(fromGuarantee(guarantee, rla));
			}
		}

		if (
			sources.isEmpty() &&
			normalizeText(rla.FSC_Tipo_de_Garantia__c) != 'SIN GARANTIA' &&
			(!String.isBlank(rla.FSC_Tipo_de_Garantia__c) ||
			!String.isBlank(rla.FSC_Descripcion_de_la_Garantia__c) ||
			rla.FSC_Valor_de_la_Garantia__c != null)
		) {
			sources.add(fromResidentialLoanApplication(rla));
		}
		return sources;
	}

	private static GuaranteeSource fromGuarantee(FSC_Garantia__c guarantee, ResidentialLoanApplication rla) {
		GuaranteeSource source = new GuaranteeSource();
		source.typeReference = guarantee.FSC_Tipo_de_Garantia__c;
		source.typeDescription = guarantee.FSC_Tipo_de_Garantia__c;
		source.classReference = guarantee.FSC_Clase_de_Garantia__c;
		source.description = guarantee.FSC_Descripcion_de_la_Garantia__c;
		source.goodReference = firstNonBlank(new List<String>{ guarantee.FSC_Tipo_Vehiculo__c, guarantee.FSC_Tipo_de_Inmueble__c });
		source.value = firstNonNullDecimal(
			new List<Decimal>{
				guarantee.FSC_Valor_Tasado__c,
				guarantee.FSC_Valor_Vehiculo__c,
				guarantee.FSC_Monto_Certificado_Deposito__c,
				guarantee.FSC_Valor_Inmueble__c,
				guarantee.FSC_Precio_de_Venta__c,
				rla.FSC_Valor_de_la_Garantia__c
			}
		);
		source.percentage = rla.FSC_Porcentaje_de_Admisibilidad__c;
		source.presentationDate = datetimeToDate(guarantee.CreatedDate);
		source.brand = getPicklistLabel(FSC_Garantia__c.FSC_Marca_Vehiculo__c, guarantee.FSC_Marca_Vehiculo__c);
		source.model = getPicklistLabel(FSC_Garantia__c.FSC_Modelo_Vehiculo__c, guarantee.FSC_Modelo_Vehiculo__c);
		source.year = guarantee.FSC_Ano_Vehiculo__c;
		source.color = guarantee.FSC_Color_Vehiculo__c;
		source.chassisNumber = guarantee.FSC_Numero_Chasis_Vehiculo__c;
		source.motorNumber = guarantee.FSC_Serial_Motor_Vehiculo__c;
		source.plateNumber = guarantee.FSC_Numero_Placa_Vehiculo__c;
		source.registrationNumber = guarantee.FSC_Numero_Matricula__c;
		source.usesStoredCodes = true;
		FSC_Garantia__c codes = catalogCodesByGuaranteeId.get(guarantee.Id);
		if (codes != null) {
			source.classCode = decimalToInteger(codes.FSC_Codigo_Clase_Garantia__c);
			source.typeCode = decimalToInteger(codes.FSC_Codigo_Tipo_Garantia__c);
			source.brandCode = decimalToInteger(codes.FSC_Codigo_Marca_Vehiculo__c);
			source.modelCode = decimalToInteger(codes.FSC_Codigo_Modelo_Vehiculo__c);
		}
		source.vehicle = isVehicleSource(source);
		return source;
	}

	private static Integer decimalToInteger(Decimal value) {
		return value == null ? null : value.intValue();
	}

	private static GuaranteeSource fromLoanApplicationAsset(LoanApplicationAsset asset, ResidentialLoanApplication rla) {
		GuaranteeSource source = new GuaranteeSource();
		source.typeReference = asset.FSC_Descripcion_de_la_Garantia__c;
		source.typeDescription = getPicklistLabel(LoanApplicationAsset.FSC_Descripcion_de_la_Garantia__c, asset.FSC_Descripcion_de_la_Garantia__c);
		source.description = firstNonBlank(new List<String>{ asset.FSC_Descripcion_Contrato__c, asset.Name, source.typeDescription });
		source.goodReference = firstNonBlank(
			new List<String>{ asset.FSC_Tipo_Vehiculo_Contrato__c, asset.AssetType, asset.AssetClass, asset.AccountType }
		);
		source.value = firstNonNullDecimal(new List<Decimal>{ asset.CashOrMarketValue, rla.FSC_Valor_de_la_Garantia__c });
		source.percentage = asset.FSC_Porcentaje_Admisibilidad__c == null
			? rla.FSC_Porcentaje_de_Admisibilidad__c
			: asset.FSC_Porcentaje_Admisibilidad__c;
		source.presentationDate = datetimeToDate(asset.CreatedDate);
		source.brand = asset.FSC_Marca_Vehiculo_Contrato__c;
		source.model = asset.FSC_Modelo_Vehiculo_Contrato__c;
		source.year = asset.FSC_Ano_Vehiculo_Contrato__c;
		source.color = asset.FSC_Color_Vehiculo_Contrato__c;
		source.chassisNumber = asset.FSC_Chasis_Vehiculo_Contrato__c;
		source.motorNumber = asset.FSC_Motor_Vehiculo_Contrato__c;
		source.plateNumber = asset.FSC_Placa_Vehiculo_Contrato__c;
		source.registrationNumber = asset.FSC_Matricula_Vehiculo_Contrato__c;
		source.vehicle = isVehicleSource(source);
		return source;
	}

	private static GuaranteeSource fromResidentialLoanApplication(ResidentialLoanApplication rla) {
		GuaranteeSource source = new GuaranteeSource();
		source.typeReference = rla.FSC_Descripcion_de_la_Garantia__c;
		source.typeDescription = firstNonBlank(
			new List<String>{
				getPicklistLabel(ResidentialLoanApplication.FSC_Descripcion_de_la_Garantia__c, rla.FSC_Descripcion_de_la_Garantia__c),
				rla.FSC_Tipo_de_Garantia__c
			}
		);
		source.classReference = rla.FSC_Tipo_de_Garantia__c;
		source.description = source.typeDescription;
		source.value = rla.FSC_Valor_de_la_Garantia__c;
		source.percentage = rla.FSC_Porcentaje_de_Admisibilidad__c;
		source.presentationDate = Date.today();
		source.vehicle = normalizeText(
				firstNonBlank(new List<String>{ source.typeDescription, rla.RecordType == null ? null : rla.RecordType.DeveloperName })
			)
			.contains('VEHICUL');
		return source;
	}

	private static Boolean isVehicleSource(GuaranteeSource source) {
		String text = normalizeText(
			firstNonBlank(new List<String>{ source.classReference, source.typeDescription, source.goodReference, source.description })
		);
		return text.contains('VEHICUL') ||
			!String.isBlank(source.brand) ||
			!String.isBlank(source.model) ||
			!String.isBlank(source.chassisNumber) ||
			!String.isBlank(source.motorNumber);
	}

	private static List<FSC_Garantia__c> safeGuarantees(Id rlaId) {
		return guaranteesByRlaId.containsKey(rlaId) ? guaranteesByRlaId.get(rlaId) : new List<FSC_Garantia__c>();
	}

	private static List<LoanApplicationAsset> safeAssets(Id rlaId) {
		return assetsByRlaId.containsKey(rlaId) ? assetsByRlaId.get(rlaId) : new List<LoanApplicationAsset>();
	}

	private static FSC_Seguro__c getPropertyInsurance(Id rlaId) {
		if (!insurancesByRlaId.containsKey(rlaId)) {
			return null;
		}
		FSC_Seguro__c fallback;
		for (FSC_Seguro__c insurance : insurancesByRlaId.get(rlaId)) {
			String insuranceType = normalizeText(insurance.FSC_Tipo_de_Seguro__c);
			if (insuranceType.contains('VIDA') || insuranceType.contains('DESEMPLEO')) {
				continue;
			}
			fallback = fallback == null ? insurance : fallback;
			if (!String.isBlank(insurance.FSC_Aseguradora_Contrato__c)) {
				return insurance;
			}
		}
		return fallback;
	}

	private static GuaranteeCatalog getGuaranteeCatalog() {
		// Los catalogos se consultan una sola vez por transaccion.
		if (guaranteeCatalog == null) {
			guaranteeCatalog = new GuaranteeCatalog();
		}
		return guaranteeCatalog;
	}

	private static List<Map<String, Object>> fetchCatalog(String endpoint) {
		if (catalogCache.containsKey(endpoint)) {
			return catalogCache.get(endpoint);
		}

		Object rawCatalog;
		if (Test.isRunningTest() && mockCatalogResponses != null && mockCatalogResponses.containsKey(endpoint)) {
			rawCatalog = mockCatalogResponses.get(endpoint);
		} else if (Test.isRunningTest() && !callCatalogHttpInTests) {
			rawCatalog = new List<Object>();
		} else {
			HttpRequest request = new HttpRequest();
			request.setEndpoint(endpoint);
			request.setMethod('GET');
			request.setTimeout(HTTP_TIMEOUT);
			request.setHeader('Accept', 'application/json');
			request.setHeader(API_KEY_HEADER, getApiKey());
			HttpResponse response;
			try {
				response = new Http().send(request);
			} catch (Exception e) {
				pendingIntegrationLogs.add(new IntegrationLog(endpoint, describeRequest(request), 'Error: ' + e.getMessage(), 0, 'SIN RESPUESTA'));
				throw e;
			}
			queueCompletedCallout(endpoint, request, response);
			if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
				throw new CalloutException(
					'Catalogo ' + endpoint.substringAfter('/api/prestamo/') + ' respondio HTTP ' +
						response.getStatusCode() +
						': ' +
						trimForLog(response.getBody(), ERROR_DETAIL_MAX_LENGTH)
				);
			}
			rawCatalog = JSON.deserializeUntyped(response.getBody());
		}

		List<Map<String, Object>> rows = new List<Map<String, Object>>();
		if (rawCatalog != null) {
			List<Object> rawRows = (List<Object>) JSON.deserializeUntyped(JSON.serialize(rawCatalog));
			for (Object row : rawRows) {
				rows.add((Map<String, Object>) row);
			}
		}
		catalogCache.put(endpoint, rows);
		return rows;
	}

	private static String getPicklistLabel(Schema.SObjectField field, String value) {
		if (String.isBlank(value)) {
			return value;
		}
		for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
			if (entry.getValue() == value) {
				return entry.getLabel();
			}
		}
		return value;
	}

	private static String getPicklistValueByLabel(Schema.SObjectField field, String label) {
		String normalizedLabel = normalizeText(label);
		if (String.isBlank(normalizedLabel)) {
			return null;
		}
		for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
			if (normalizeText(entry.getLabel()) == normalizedLabel || normalizeText(entry.getValue()) == normalizedLabel) {
				return entry.getValue();
			}
		}
		return null;
	}

	private static Decimal firstNonNullDecimal(List<Decimal> values) {
		for (Decimal value : values) {
			if (value != null) {
				return value;
			}
		}
		return null;
	}

	private static Integer toInteger(Object value, String fieldName) {
		String textValue = valueToString(value);
		if (String.isBlank(textValue)) {
			return null;
		}
		try {
			return Decimal.valueOf(textValue).intValue();
		} catch (Exception e) {
			throw new IllegalArgumentException('Valor entero invalido en ' + fieldName + ': ' + textValue + '.');
		}
	}

	private static String formatGuaranteeDate(Date value) {
		if (value == null) {
			return '';
		}
		return String.valueOf(value.day()).leftPad(2, '0') + '-' + String.valueOf(value.month()).leftPad(2, '0') + '-' + String.valueOf(value.year());
	}

	private static String normalizeText(String value) {
		if (String.isBlank(value)) {
			return '';
		}
		return value
			.trim()
			.toUpperCase()
			.replace('Á', 'A')
			.replace('É', 'E')
			.replace('Í', 'I')
			.replace('Ó', 'O')
			.replace('Ú', 'U')
			.replace('Ü', 'U')
			.replace('Ñ', 'N')
			.replaceAll('[^A-Z0-9]+', ' ')
			.trim()
			.replaceAll('\\s+', ' ');
	}

	// Compara descripciones ignorando acentos, espacios y signos (ej. "I2" frente a "-I2").
	private static String compactText(String value) {
		return normalizeText(value).replace(' ', '');
	}

	private static String joinNonBlank(List<String> values) {
		List<String> populatedValues = new List<String>();
		for (String value : values) {
			if (!String.isBlank(value)) {
				populatedValues.add(value);
			}
		}
		return String.join(populatedValues, ' ');
	}

	private class GuaranteeCatalog {
		private Map<Integer, Map<String, Object>> guaranteeTypesByCode = new Map<Integer, Map<String, Object>>();
		private Map<String, Integer> guaranteeTypeCodesByDescription = new Map<String, Integer>();
		private Map<Integer, Map<String, Object>> goodsByCode = new Map<Integer, Map<String, Object>>();
		private Map<String, Integer> goodCodesByDescription = new Map<String, Integer>();
		private Map<Integer, Map<String, Object>> classesByCode = new Map<Integer, Map<String, Object>>();
		private Map<String, Integer> classCodesByDescription = new Map<String, Integer>();
		private Map<Integer, Set<Integer>> classCodesByGuaranteeType = new Map<Integer, Set<Integer>>();
		private Map<String, List<Integer>> brandCodesByDescription = new Map<String, List<Integer>>();
		private Map<String, List<Map<String, Object>>> modelsByDescription = new Map<String, List<Map<String, Object>>>();
		private Map<String, Map<String, Object>> modelsByBrandAndCode = new Map<String, Map<String, Object>>();
		private Map<String, Integer> insuranceCodesByName = new Map<String, Integer>();

		private GuaranteeCatalog() {
			for (Map<String, Object> row : fetchCatalog(TIPOS_GARANTIA_ENDPOINT)) {
				Integer code = toInteger(row.get('CODIGO_TIPO_GARANTIA'), 'CODIGO_TIPO_GARANTIA');
				guaranteeTypesByCode.put(code, row);
				guaranteeTypeCodesByDescription.put(normalizeText(valueToString(row.get('DESCRIPCION'))), code);
			}
			for (Map<String, Object> row : fetchCatalog(TIPOS_BIEN_ENDPOINT)) {
				Integer code = toInteger(row.get('CODIGO_BIEN'), 'CODIGO_BIEN');
				goodsByCode.put(code, row);
				goodCodesByDescription.put(normalizeText(valueToString(row.get('DESCRIPCION'))), code);
			}
			for (Map<String, Object> row : fetchCatalog(CLASES_GARANTIA_ENDPOINT)) {
				Integer code = toInteger(row.get('CODIGO_CLASE_GARANTIA'), 'CODIGO_CLASE_GARANTIA');
				classesByCode.put(code, row);
				classCodesByDescription.put(normalizeText(valueToString(row.get('DESCRIPCION'))), code);
			}
			for (Map<String, Object> row : fetchCatalog(CLASES_POR_TIPO_ENDPOINT)) {
				Integer typeCode = toInteger(row.get('CODIGO_TIPO_GARANTIA'), 'CODIGO_TIPO_GARANTIA');
				Integer classCode = toInteger(row.get('CODIGO_CLASE_GARANTIA'), 'CODIGO_CLASE_GARANTIA');
				if (!classCodesByGuaranteeType.containsKey(typeCode)) {
					classCodesByGuaranteeType.put(typeCode, new Set<Integer>());
				}
				classCodesByGuaranteeType.get(typeCode).add(classCode);
			}
			for (Map<String, Object> row : fetchCatalog(MARCAS_AUTO_ENDPOINT)) {
				String description = normalizeText(valueToString(row.get('DESCRIPCION')));
				if (!brandCodesByDescription.containsKey(description)) {
					brandCodesByDescription.put(description, new List<Integer>());
				}
				brandCodesByDescription.get(description).add(toInteger(row.get('CODIGO_MARCA'), 'CODIGO_MARCA'));
			}
			for (Map<String, Object> row : fetchCatalog(MODELOS_AUTO_ENDPOINT)) {
				String description = normalizeText(valueToString(row.get('DESCRIPCION')));
				if (!modelsByDescription.containsKey(description)) {
					modelsByDescription.put(description, new List<Map<String, Object>>());
				}
				modelsByDescription.get(description).add(row);
				modelsByBrandAndCode.put(
					toInteger(row.get('CODIGO_MARCA'), 'CODIGO_MARCA') + '|' + toInteger(row.get('CODIGO_MODELO'), 'CODIGO_MODELO'),
					row
				);
			}
			for (Map<String, Object> row : fetchCatalog(ASEGURADORAS_ENDPOINT)) {
				insuranceCodesByName.put(
					normalizeText(valueToString(row.get('NOMBRE'))),
					toInteger(row.get('CODIGO_ASEGURADORA'), 'CODIGO_ASEGURADORA')
				);
			}
		}

		private Integer requireStoredClassCode(GuaranteeSource source, Integer sequence) {
			String guaranteeLabel = 'la garantia ' + sequence + ' (' + source.classReference + ')';
			if (source.classCode == null) {
				throw new IllegalArgumentException(
					'Falta el codigo de clase ABANKS (FSC_Codigo_Clase_Garantia__c) en ' +
						guaranteeLabel +
						'. Edite la garantia y seleccione la clase del catalogo.'
				);
			}
			if (!classesByCode.containsKey(source.classCode)) {
				throw new IllegalArgumentException(
					'El codigo de clase ' + source.classCode + ' de ' + guaranteeLabel + ' no existe en el catalogo de ABANKS.'
				);
			}
			return source.classCode;
		}

		private Integer requireStoredTypeCode(GuaranteeSource source, Integer classCode, Integer sequence) {
			String guaranteeLabel = 'la garantia ' + sequence + ' (' + source.typeDescription + ')';
			if (source.typeCode == null) {
				throw new IllegalArgumentException(
					'Falta el codigo de tipo ABANKS (FSC_Codigo_Tipo_Garantia__c) en ' +
						guaranteeLabel +
						'. Edite la garantia y seleccione el tipo del catalogo.'
				);
			}
			if (!guaranteeTypesByCode.containsKey(source.typeCode)) {
				throw new IllegalArgumentException(
					'El codigo de tipo ' + source.typeCode + ' de ' + guaranteeLabel + ' no existe en el catalogo de ABANKS.'
				);
			}
			if (!typeMatchesClass(source.typeCode, classCode)) {
				throw new IllegalArgumentException(
					'El tipo ' + source.typeCode + ' de ' + guaranteeLabel + ' no corresponde a la clase ' + classCode + ' en ABANKS.'
				);
			}
			return source.typeCode;
		}

		private Integer resolveGuaranteeTypeCode(GuaranteeSource source, String currencyCode) {
			List<String> references = new List<String>{
				source.typeDescription,
				source.typeReference,
				source.classReference,
				source.goodReference,
				source.description
			};
			Integer expectedClassCode = inferGuaranteeClassCode(source);
			Integer currencyValue = parseInteger(currencyCode);

			// El codigo guardado solo desempata: debe coincidir con el texto y pasar las mismas validaciones.
			if (
				codeMatchesDescription(guaranteeTypesByCode, source.typeCode, source.typeDescription) &&
				typeMatchesClass(source.typeCode, expectedClassCode) &&
				typeMatchesCurrency(source.typeCode, currencyValue)
			) {
				return source.typeCode;
			}

			for (String reference : references) {
				Integer descriptionCode = findBestCode(guaranteeTypeCodesByDescription, reference);
				if (
					descriptionCode != null &&
					typeMatchesClass(descriptionCode, expectedClassCode) &&
					typeMatchesCurrency(descriptionCode, currencyValue)
				) {
					return descriptionCode;
				}
			}

			Integer numericCode = parseCatalogCode(source.typeReference, guaranteeTypesByCode.keySet());
			if (
				numericCode != null &&
				typeMatchesClass(numericCode, expectedClassCode) &&
				typeMatchesCurrency(numericCode, currencyValue) &&
				typeDescriptionsAreCompatible(numericCode, source.typeDescription)
			) {
				return numericCode;
			}

			return resolveTypeByContext(source, currencyCode, expectedClassCode);
		}

		private Integer inferGuaranteeClassCode(GuaranteeSource source) {
			if (codeMatchesDescription(classesByCode, source.classCode, source.classReference)) {
				return source.classCode;
			}
			Integer classCode = findBestCode(classCodesByDescription, source.classReference);
			if (classCode != null) {
				return classCode;
			}

			String combined = normalizeText(
				joinNonBlank(new List<String>{ source.typeDescription, source.typeReference, source.goodReference, source.description })
			);
			if (source.vehicle || combined.contains('VEHICUL')) {
				return findBestCode(classCodesByDescription, 'VEHICULOS, MAQUINARIAS');
			}
			if (combined.contains('HIPOTEC') || combined.contains('INMUEBLE') || combined.contains('GARANTIA REAL')) {
				return findBestCode(classCodesByDescription, 'BIENES INMUEBLES');
			}
			if (combined.contains('SOLIDAR')) {
				return findBestCode(classCodesByDescription, 'FIRMA SOLIDARIA');
			}
			if (combined.contains('CERTIFIC') || combined.contains('DEPOSITO')) {
				String className = combined.contains('VIMENCA') || combined.contains('PROPIA EIF')
					? 'CERTIFICADOS DEPOSITOS BANCO VIMENCA'
					: 'CERTIFICADOS DEPOSITOS O INVERSIONES OTRAS ENTIDADES';
				return findBestCode(classCodesByDescription, className);
			}
			return null;
		}

		private Integer resolveTypeByContext(GuaranteeSource source, String currencyCode, Integer expectedClassCode) {
			String combined = normalizeText(
				joinNonBlank(
					new List<String>{ source.typeDescription, source.typeReference, source.classReference, source.goodReference, source.description }
				)
			);
			Integer currencyValue = parseInteger(currencyCode);
			if (combined.contains('SOLIDAR')) {
				return findTypeCodeByText('SOLIDARIO', currencyValue, expectedClassCode, null);
			}
			if (source.vehicle || combined.contains('VEHICUL')) {
				return resolveVehicleGuaranteeType(source, currencyValue, expectedClassCode);
			}
			if (
				combined.contains('HIPOTEC') ||
				combined.contains('INMUEBLE') ||
				combined.contains('GARANTIA REAL') ||
				expectedClassCode == findBestCode(classCodesByDescription, 'BIENES INMUEBLES')
			) {
				return resolveRealEstateGuaranteeType(combined, currencyValue, expectedClassCode);
			}
			if (combined.contains('CERTIFIC') || combined.contains('DEPOSITO')) {
				String searchText = combined.contains('VIMENCA') || combined.contains('PROPIA EIF') ? 'DUENO DEL DP' : 'OTRAS EIF';
				Integer code = findTypeCodeByText(searchText, currencyValue, expectedClassCode, null);
				return code == null ? findTypeCodeByText('PERSONA DISTINTA DEL DP', currencyValue, expectedClassCode, null) : code;
			}
			// Sin una coincidencia clara no se elige un tipo cualquiera del catalogo.
			return null;
		}

		private Integer resolveVehicleGuaranteeType(GuaranteeSource source, Integer currencyValue, Integer expectedClassCode) {
			String combined = normalizeText(joinNonBlank(new List<String>{ source.typeDescription, source.classReference, source.goodReference }));
			if (combined.contains('PESAD')) {
				return findTypeCodeByText('VEHICULOS PESADOS', currencyValue, expectedClassCode, 'VEHICUL');
			}

			Integer age = source.year == null ? null : Date.today().year() - source.year.intValue();
			Boolean newVehicle = combined.contains('NUEV');
			Boolean usedVehicle = combined.contains('USAD');
			if (newVehicle) {
				String ageText = age != null && age <= 0 ? 'MENOR DE 1 ANO' : '1 A 2 ANOS';
				Integer code = findTypeCodeByText(ageText, currencyValue, expectedClassCode, 'VEHICUL');
				if (code != null) {
					return code;
				}
			}
			if (usedVehicle && age != null && age >= 6 && age <= 7) {
				Integer code = findTypeCodeByText('6 7 ANOS', currencyValue, expectedClassCode, 'VEHICUL');
				if (code != null) {
					return code;
				}
			}
			if (usedVehicle && age != null && age > 5) {
				Integer code = findTypeCodeByText('MAYOR DE 5 ANOS', currencyValue, expectedClassCode, 'VEHICUL');
				if (code != null) {
					return code;
				}
			}
			if (usedVehicle || (age != null && age >= 3)) {
				Integer code = findTypeCodeByText('3 5 ANOS', currencyValue, expectedClassCode, 'VEHICUL');
				if (code != null) {
					return code;
				}
			}
			return findTypeCodeByText('VEHICUL', currencyValue, expectedClassCode, null);
		}

		private Integer resolveRealEstateGuaranteeType(String combined, Integer currencyValue, Integer expectedClassCode) {
			List<String> searchTexts = new List<String>();
			if (combined.contains('AGROPECUAR')) {
				searchTexts.add('SOLARES O TERRENOS PARA FINES AGROPECUARIOS');
			} else if (combined.contains('SOLAR') || combined.contains('TERRENO')) {
				searchTexts.add('SOLARES O TERRENOS');
			} else if (combined.contains('HOTEL')) {
				searchTexts.add('HOTELES');
			} else if (combined.contains('NAVE INDUSTRIAL')) {
				searchTexts.add('NAVES INDUSTRIALES');
			} else if (combined.contains('ZONA FRANCA')) {
				searchTexts.add('ZONAS FRANCAS INMUEBLES');
			} else if (combined.contains('LOCAL') || combined.contains('COMERCIAL')) {
				searchTexts.add('EDIFICIOS Y LOCALES COMERCIALES');
			} else {
				searchTexts.add('EDIFICIOS RESIDENCIALES VIVIENDAS O APTOS');
			}

			for (String searchText : searchTexts) {
				Integer code = findTypeCodeByText(searchText, currencyValue, expectedClassCode, null);
				if (code != null) {
					return code;
				}
			}
			return null;
		}

		private Integer findTypeCodeByText(String searchText, Integer currencyValue, Integer expectedClassCode, String requiredText) {
			String normalizedSearch = normalizeText(searchText);
			String normalizedRequired = normalizeText(requiredText);
			for (Integer code : sortedTypeCodes()) {
				Map<String, Object> row = guaranteeTypesByCode.get(code);
				String description = normalizeText(valueToString(row.get('DESCRIPCION')));
				Integer rowCurrency = toInteger(row.get('CODIGO_MONEDA'), 'CODIGO_MONEDA');
				if (
					(currencyValue == null ||
					currencyValue == rowCurrency) &&
					typeMatchesClass(code, expectedClassCode) &&
					description.contains(normalizedSearch) &&
					(String.isBlank(normalizedRequired) || description.contains(normalizedRequired))
				) {
					return code;
				}
			}
			return null;
		}

		private List<Integer> sortedTypeCodes() {
			List<Integer> codes = new List<Integer>(guaranteeTypesByCode.keySet());
			codes.sort();
			return codes;
		}

		private Boolean typeMatchesClass(Integer typeCode, Integer expectedClassCode) {
			return expectedClassCode == null ||
				(classCodesByGuaranteeType.containsKey(typeCode) && classCodesByGuaranteeType.get(typeCode).contains(expectedClassCode));
		}

		private Boolean typeMatchesCurrency(Integer typeCode, Integer currencyValue) {
			return currencyValue == null || currencyValue == toInteger(guaranteeTypesByCode.get(typeCode).get('CODIGO_MONEDA'), 'CODIGO_MONEDA');
		}

		private Boolean typeDescriptionsAreCompatible(Integer typeCode, String localDescription) {
			if (String.isBlank(localDescription)) {
				return false;
			}
			String localText = normalizeText(localDescription);
			String apiText = normalizeText(valueToString(guaranteeTypesByCode.get(typeCode).get('DESCRIPCION')));
			return localText == apiText ||
				(localText.contains('VEHICUL') && apiText.contains('VEHICUL')) ||
				(localText.contains('SOLIDAR') && apiText.contains('SOLIDAR')) ||
				(localText.contains('CERTIFIC') && apiText.contains('CERTIFIC')) ||
				(localText.contains('PAGARE') && apiText.contains('PAGARE'));
		}

		private Boolean codeMatchesDescription(Map<Integer, Map<String, Object>> rowsByCode, Integer code, String localDescription) {
			Map<String, Object> row = code == null ? null : rowsByCode.get(code);
			return row != null && !String.isBlank(localDescription) && compactText(valueToString(row.get('DESCRIPCION'))) == compactText(localDescription);
		}

		private Integer parseInteger(String value) {
			return String.isBlank(value) || !Pattern.matches('^\\d+$', value.trim()) ? null : Integer.valueOf(value.trim());
		}

		private Integer resolveGuaranteeClassCode(
			Integer storedClassCode,
			String classReference,
			Integer guaranteeTypeCode,
			Boolean vehicle,
			String typeDescription
		) {
			if (codeMatchesDescription(classesByCode, storedClassCode, classReference)) {
				return storedClassCode;
			}
			Integer code = findBestCode(classCodesByDescription, classReference);
			if (code != null) {
				return code;
			}
			Set<Integer> relatedCodes = classCodesByGuaranteeType.get(guaranteeTypeCode);
			if (relatedCodes == null || relatedCodes.isEmpty()) {
				return null;
			}
			List<Integer> orderedCodes = new List<Integer>(relatedCodes);
			orderedCodes.sort();
			if (orderedCodes.size() == 1) {
				return orderedCodes[0];
			}

			String normalizedType = normalizeText(typeDescription);
			Integer newVehicleClass = findBestCode(classCodesByDescription, 'VEHICULOS NUEVOS -P2');
			Integer usedVehicleClass = findBestCode(classCodesByDescription, 'VEHICULOS USADOS-P2');
			Integer genericVehicleClass = findBestCode(classCodesByDescription, 'VEHICULOS, MAQUINARIAS');
			if (vehicle && normalizedType.contains('NUEV') && relatedCodes.contains(newVehicleClass)) {
				return newVehicleClass;
			}
			if (vehicle && normalizedType.contains('USAD') && relatedCodes.contains(usedVehicleClass)) {
				return usedVehicleClass;
			}
			if (vehicle && relatedCodes.contains(genericVehicleClass)) {
				return genericVehicleClass;
			}
			// Con varias clases posibles no se elige la primera a ciegas.
			return null;
		}

		private Integer resolveGoodCode(List<String> references) {
			for (String reference : references) {
				Integer code = findBestCode(goodCodesByDescription, reference);
				if (code != null) {
					return code;
				}
			}

			String combined = normalizeText(joinNonBlank(references));
			if (combined.contains('SOLIDAR') || combined.contains('FIANZA') || combined.contains('AVAL')) {
				return findBestCode(goodCodesByDescription, 'AVALES O FIANZAS');
			}
			if (combined.contains('VEHICUL')) {
				return findBestCode(goodCodesByDescription, 'VEHICULO');
			}
			if (combined.contains('CERTIFIC') || combined.contains('DEPOSITO')) {
				return findBestCode(goodCodesByDescription, 'CERTIFICADO DEPOSITO INVERSION');
			}
			if (combined.contains('HIPOTEC') || combined.contains('INMUEBLE') || combined.contains('GARANTIA REAL')) {
				return findBestCode(goodCodesByDescription, 'CASA');
			}
			if (combined.contains('INVENTARIO')) {
				return findBestCode(goodCodesByDescription, 'INVENTARIO');
			}
			if (combined.contains('MAQUINARIA')) {
				return findBestCode(goodCodesByDescription, 'MAQUINARIA');
			}
			// Sin coincidencia no se envia "OTROS"; el llamador informa el bien que falta.
			return null;
		}

		private VehicleCodes resolveVehicleCodes(GuaranteeSource source) {
			VehicleCodes result = new VehicleCodes();
			Map<String, Object> selectedModel;
			List<Integer> brandCodes;
			if (source.usesStoredCodes) {
				// Marca y modelo se eligieron del catalogo al capturar la garantia.
				brandCodes = source.brandCode == null ? null : new List<Integer>{ source.brandCode };
				selectedModel = source.brandCode == null || source.modelCode == null
					? null
					: modelsByBrandAndCode.get(source.brandCode + '|' + source.modelCode);
			} else {
				brandCodes = brandCodesByDescription.get(normalizeText(source.brand));
				List<Map<String, Object>> modelRows = modelsByDescription.get(normalizeText(source.model));
				if (modelRows == null) {
					modelRows = findBestRows(modelsByDescription, source.model);
				}
				// El modelo debe pertenecer a la marca indicada; nunca se toma el de otra marca.
				if (modelRows != null && brandCodes != null) {
					for (Map<String, Object> row : modelRows) {
						if (brandCodes.contains(toInteger(row.get('CODIGO_MARCA'), 'CODIGO_MARCA'))) {
							selectedModel = row;
							break;
						}
					}
				}
			}

			if (selectedModel != null) {
				result.modelCode = toInteger(selectedModel.get('CODIGO_MODELO'), 'CODIGO_MODELO');
				result.brandCode = toInteger(selectedModel.get('CODIGO_MARCA'), 'CODIGO_MARCA');
				result.modelDescription = valueToString(selectedModel.get('DESCRIPCION'));
				result.capacity = toInteger(selectedModel.get('CAPACIDAD'), 'CAPACIDAD');
				result.cylinders = toInteger(selectedModel.get('CILINDROS'), 'CILINDROS');
				result.vehicleClass = toInteger(selectedModel.get('CODIGO_TIPO'), 'CODIGO_TIPO');
			} else if (brandCodes != null && !brandCodes.isEmpty()) {
				result.brandCode = brandCodes[0];
			}
			return result;
		}

		private Integer resolveInsuranceCode(List<String> references) {
			if (references.isEmpty() || String.isBlank(joinNonBlank(references))) {
				return 0;
			}
			for (String reference : references) {
				Integer code = findBestCode(insuranceCodesByName, reference);
				if (code != null) {
					return code;
				}
			}
			for (String reference : references) {
				String normalizedReference = normalizeText(reference);
				for (String insurerName : insuranceCodesByName.keySet()) {
					for (String token : insurerName.split(' ')) {
						if (
							token.length() >= 4 &&
							!new Set<String>{ 'SEGURO', 'SEGUROS', 'COMPANIA', 'DOMINICANA' }.contains(token) &&
							normalizedReference.contains(token)
						) {
							return insuranceCodesByName.get(insurerName);
						}
					}
				}
			}
			throw new IllegalArgumentException('No se encontro codigo para la aseguradora: ' + joinNonBlank(references) + '.');
		}

		private Decimal getCoveragePercentage(Integer guaranteeTypeCode) {
			Map<String, Object> row = guaranteeTypesByCode.get(guaranteeTypeCode);
			return row == null ? null : valueToDecimal(row.get('PORCENTAJE_SIB'), 'PORCENTAJE_SIB');
		}

		private String getManagesInsurance(Integer guaranteeTypeCode, Integer classCode, Boolean hasInsurance) {
			Map<String, Object> typeRow = guaranteeTypesByCode.get(guaranteeTypeCode);
			String value = typeRow == null ? null : valueToString(typeRow.get('MANEJA_SEGUROS'));
			if (String.isBlank(value)) {
				Map<String, Object> classRow = classesByCode.get(classCode);
				value = classRow == null ? null : valueToString(classRow.get('MANEJA_SEGUROS'));
			}
			return firstNonBlank(new List<String>{ value, hasInsurance ? 'S' : 'N' });
		}

		private Integer getGoodSubtype(Integer goodCode) {
			Map<String, Object> row = goodsByCode.get(goodCode);
			String status = row == null ? null : valueToString(row.get('STATUS'));
			// STATUS agrupa inmueble, mueble, titulo, otros, inventario y equipo.
			Map<String, Integer> subtypesByStatus = new Map<String, Integer>{ 'I' => 1, 'M' => 2, 'T' => 3, 'O' => 4, 'N' => 5, 'E' => 6 };
			return subtypesByStatus.containsKey(status) ? subtypesByStatus.get(status) : 0;
		}

		private String getGoodGroup(Integer goodCode) {
			Map<String, Object> row = goodsByCode.get(goodCode);
			return firstNonBlank(new List<String>{ row == null ? null : valueToString(row.get('SIGLA')), '' });
		}

		private String getGoodSubgroup(Integer goodCode) {
			Map<String, Object> row = goodsByCode.get(goodCode);
			return firstNonBlank(new List<String>{ row == null ? null : valueToString(row.get('CODIGO_GRUPO_TARIFA')), '' });
		}

		private Integer parseCatalogCode(String value, Set<Integer> validCodes) {
			if (String.isBlank(value) || !Pattern.matches('^\\d+$', value.trim())) {
				return null;
			}
			Integer code = Integer.valueOf(value.trim());
			return validCodes.contains(code) ? code : null;
		}

		private Integer findBestCode(Map<String, Integer> codesByDescription, String reference) {
			String normalizedReference = normalizeText(reference);
			if (String.isBlank(normalizedReference)) {
				return null;
			}
			if (codesByDescription.containsKey(normalizedReference)) {
				return codesByDescription.get(normalizedReference);
			}

			String bestKey;
			for (String key : codesByDescription.keySet()) {
				if (
					key.length() >= 4 &&
					(normalizedReference.contains(key) || key.contains(normalizedReference)) &&
					(bestKey == null ||
					key.length() > bestKey.length())
				) {
					bestKey = key;
				}
			}
			return bestKey == null ? null : codesByDescription.get(bestKey);
		}

		private Integer findCodeContaining(Map<String, Integer> codesByDescription, String token) {
			String normalizedToken = normalizeText(token);
			for (String key : codesByDescription.keySet()) {
				if (key.contains(normalizedToken)) {
					return codesByDescription.get(key);
				}
			}
			return null;
		}

		private List<Map<String, Object>> findBestRows(Map<String, List<Map<String, Object>>> rowsByDescription, String reference) {
			String normalizedReference = normalizeText(reference);
			String bestKey;
			for (String key : rowsByDescription.keySet()) {
				if (
					!String.isBlank(normalizedReference) &&
					(normalizedReference.contains(key) || key.contains(normalizedReference)) &&
					(bestKey == null ||
					key.length() > bestKey.length())
				) {
					bestKey = key;
				}
			}
			return bestKey == null ? null : rowsByDescription.get(bestKey);
		}
	}

	private class GuaranteePayload {
		private List<Object> guaranteeItems = new List<Object>();
		private List<Object> vehicleItems = new List<Object>();
	}

	private class GuaranteeSource {
		private String typeReference;
		private String typeDescription;
		private String classReference;
		private String description;
		private String goodReference;
		private Decimal value;
		private Decimal percentage;
		private Date presentationDate;
		private Boolean vehicle = false;
		// Solo FSC_Garantia__c guarda los codigos ABANKS elegidos al capturar la garantia.
		private Boolean usesStoredCodes = false;
		private String brand;
		private String model;
		private Integer classCode;
		private Integer typeCode;
		private Integer brandCode;
		private Integer modelCode;
		private Decimal year;
		private String color;
		private String chassisNumber;
		private String motorNumber;
		private String plateNumber;
		private String registrationNumber;
	}

	private class VehicleCodes {
		private Integer brandCode;
		private Integer modelCode;
		private String modelDescription;
		private Integer capacity;
		private Integer cylinders;
		private Integer vehicleClass;
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
					Funci_n__c = truncateForIntegrationLog(log.functionName, INTEGRATION_LOG_TEXT_MAX_LENGTH)
				)
			);
		}

		// Un fallo del log no debe impedir actualizar la solicitud.
		Savepoint loggingSavepoint = Database.setSavepoint();
		try {
			insert as system requests;

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
			insert as system responses;
		} catch (Exception e) {
			Database.rollback(loggingSavepoint);
			System.debug(LoggingLevel.ERROR, 'No se pudo registrar el log de integracion: ' + e.getMessage());
		}
	}

	private static void queueCompletedCallout(String functionName, HttpRequest request, HttpResponse response) {
		INTLogger.INTLoggerCalloutData calloutData = INTLogger.logCalloutNoInsert(LOG_INTEGRATION_NAME, functionName, request, response);
		Map<String, Object> requestData = (Map<String, Object>) calloutData.req;
		Map<String, Object> responseData = (Map<String, Object>) calloutData.res;
		String requestBody = (String) requestData.get('Trama_de_env_o__c');
		pendingIntegrationLogs.add(
			new IntegrationLog(
				(String) requestData.get('Funci_n__c'),
				String.isBlank(requestBody) ? describeRequest(request) : requestBody,
				(String) responseData.get('Trama_de_respuesta__c'),
				(Integer) responseData.get('Http_Status_Code__c'),
				(String) responseData.get('Status__c')
			)
		);
	}

	private static String getApiKey() {
		FSC_APIPrestamoConfig__mdt config = FSC_APIPrestamoConfig__mdt.getInstance(API_KEY_CONFIG);
		if (config == null || String.isBlank(config.FSC_ApiKey__c)) {
			throw new CalloutException('Falta configurar FSC_APIPrestamoConfig__mdt.' + API_KEY_CONFIG + '.FSC_ApiKey__c.');
		}
		return config.FSC_ApiKey__c;
	}

	private static String describeRequest(HttpRequest request) {
		return JSON.serialize(new Map<String, String>{ 'method' => request.getMethod(), 'endpoint' => request.getEndpoint() });
	}

	private static String truncateForIntegrationLog(String value, Integer maxLength) {
		return value == null || value.length() <= maxLength ? value : value.substring(0, maxLength);
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

		// Campos tecnicos de la integracion: el usuario de desembolso no tiene FLS de edicion.
		Database.SaveResult[] saveResults = Database.update(recordsToUpdate, false, AccessLevel.SYSTEM_MODE);
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

		// ABANKS procesa los meses con la configuracion de Oracle en ingles.
		List<String> months = new List<String>{ 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec' };
		String dayText = value.day() < 10 ? '0' + String.valueOf(value.day()) : String.valueOf(value.day());
		return dayText + '-' + months[value.month() - 1] + '-' + String.valueOf(value.year());
	}

	private static Date datetimeToDate(Datetime value) {
		return value == null ? null : value.date();
	}

	private static String dateDayToString(Date value) {
		return value == null ? '' : String.valueOf(value.day());
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
		if (digitos.length() != 11) {
			throw new IllegalArgumentException('Account.ACC_NumIdentificacion__c debe contener 11 digitos para una cedula.');
		}

		// El API de prestamos requiere la cedula con guiones.
		return digitos.substring(0, 3) + '-' + digitos.substring(3, 10) + '-' + digitos.substring(10);
	}

	private static String firstNonBlank(List<String> values) {
		for (String value : values) {
			if (!String.isBlank(value)) {
				return value.trim();
			}
		}
		return null;
	}

	private static String extractCode(String value) {
		if (String.isBlank(value)) {
			return null;
		}

		String normalizedValue = value.trim();
		Integer descriptionSeparator = normalizedValue.indexOf(' - ');
		return descriptionSeparator > 0 ? normalizedValue.substring(0, descriptionSeparator).trim() : normalizedValue;
	}

	private static ResidentialLoanApplication buildErrorUpdate(ResidentialLoanApplication rla, Output outputItem, Input inputItem) {
		List<String> details = new List<String>{ outputItem.message };
		if (!String.isBlank(outputItem.codigoRespuesta)) {
			details.add('codigoRespuesta=' + outputItem.codigoRespuesta);
		}
		if (!String.isBlank(outputItem.descripcionRespuesta)) {
			details.add('descripcionRespuesta=' + outputItem.descripcionRespuesta);
		}
		if (!String.isBlank(outputItem.descripcionTecnica)) {
			details.add('descripcionTecnica=' + outputItem.descripcionTecnica);
		}
		if (!String.isBlank(outputItem.responseJson)) {
			details.add('response=' + trimForLog(outputItem.responseJson, ERROR_DETAIL_MAX_LENGTH));
		}

		String entry = Datetime.now().format('yyyy-MM-dd HH:mm:ss') + ' | API Prestamos | ' + String.join(details, ' | ');
		return new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_FlagErrorAPIPrestamos__c = true,
			FSC_LogErrores__c = appendErrorLog(rla.FSC_LogErrores__c, entry),
			FSC_ClaveProducto__c = getProductKey(inputItem)
		);
	}

	private static String getProductKey(Input inputItem) {
		Map<String, Object> producto = parseProduct(inputItem == null ? null : inputItem.productoJson);
		return valueToString(producto == null ? null : producto.get('CLAVE_PRODUCTO'));
	}

	private static String appendErrorLog(String currentLog, String newEntry) {
		String combinedLog = String.isBlank(currentLog) ? newEntry : currentLog + ERROR_LOG_SEPARATOR + newEntry;
		return combinedLog.length() <= ERROR_LOG_MAX_LENGTH ? combinedLog : combinedLog.substring(combinedLog.length() - ERROR_LOG_MAX_LENGTH);
	}

	private static String trimForLog(String value, Integer maxLength) {
		return String.isBlank(value) || value.length() <= maxLength ? value : value.substring(0, maxLength) + '...';
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

	private class IntegrationLog {
		public String functionName;
		public String requestBody;
		public String responseBody;
		public Integer statusCode;
		public String status;

		public IntegrationLog(String functionName, String requestBody, String responseBody, Integer statusCode, String status) {
			this.functionName = functionName;
			this.requestBody = requestBody;
			this.responseBody = responseBody;
			this.statusCode = statusCode;
			this.status = status;
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