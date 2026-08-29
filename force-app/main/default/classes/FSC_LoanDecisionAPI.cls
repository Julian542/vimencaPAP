public with sharing class FSC_LoanDecisionAPI {
	private static final String CONFIG_URL = 'URL';
	private static final String CONFIG_URL_HIPOTECARIO = 'URLHipotecario';
	private static final String CONFIG_URL_VEHICULAR = 'URLVehicular';
	private static final String CONFIG_CREDENTIALS = 'Credentials';
	private static final String RT_CREDITO_CONSUMO = 'FSC_Solicitud_Credito_Consumo';
	private static final String RT_CREDITO_HIPOTECARIO = 'FSC_Solicitud_Credito_Hipotecario';
	private static final String RT_CREDITO_VEHICULO = 'FSC_Solicitud_Credito_Vehiculo';
	private static final String RESPONSE_NODE_CONSUMO = 'Filtro_BcoVimencaPre';
	private static final String RESPONSE_NODE_HIPOTECARIO = 'FiltroVimencaPreHipotecario';
	private static final String RESPONSE_NODE_VEHICULAR = 'Filtro_BcoVimencaVhi';
	private static final Map<String, String> CONFIG_BY_RECORD_TYPE = new Map<String, String>{
		RT_CREDITO_CONSUMO => CONFIG_URL,
		RT_CREDITO_HIPOTECARIO => CONFIG_URL_HIPOTECARIO,
		RT_CREDITO_VEHICULO => CONFIG_URL_VEHICULAR
	};
	private static final Map<String, String> RESPONSE_NODE_BY_RECORD_TYPE = new Map<String, String>{
		RT_CREDITO_CONSUMO => RESPONSE_NODE_CONSUMO,
		RT_CREDITO_HIPOTECARIO => RESPONSE_NODE_HIPOTECARIO,
		RT_CREDITO_VEHICULO => RESPONSE_NODE_VEHICULAR
	};
	private static final Map<String, String> PATH_BY_RECORD_TYPE = new Map<String, String>{
		RT_CREDITO_HIPOTECARIO => 'prehip',
		RT_CREDITO_VEHICULO => 'prevhi'
	};

	private static final String SUBESTADO_APROBADO = 'Generación de pagarés y plantillas';
	private static final String SUBESTADO_REFERIDO = 'Recepción de documentos – Análisis';
	private static final String SUBESTADO_RECHAZADO = 'Rechazado por Buró';
	private static final String MOTIVO_RECHAZADO = '9';
	private static final String STATUS_CERRADA_PERDIDA = 'Cerrada Perdida';
	private static final String ERROR_LOG_SEPARATOR = '\n--------------------\n';
	private static final String ERROR_LOG_TIMESTAMP_FORMAT = 'yyyy-MM-dd HH:mm:ss';
	private static final Integer ERROR_LOG_BODY_MAX_LENGTH = 255;
	@TestVisible
	private static Map<String, String> testConfigValues;

	public static void callAPI(List<Id> rlaIds) {
		if (rlaIds == null || rlaIds.isEmpty()) {
			return;
		}

		Map<String, String> endpointsByRecordType = getEndpointsByRecordType();
		String authorizationHeader = getAuthorizationHeader();

		List<ResidentialLoanApplication> rlas = [
			SELECT
				Id,
				AccountId,
				OpportunityId,
				RecordType.DeveloperName,
				FSC_Ingresos_Mensuales__c,
				FSC_A_os_de_operacion__c,
				FSC_Clasificacion_de_Riesgo__c,
				FSC_MontoAprobado__c,
				FSC_PlazoMesesAprobado__c,
				FSC_TasaInteresAprobada__c,
				FSC_Monto__c,
				FSC_Plazo_meses__c,
				FSC_TasaInteres__c,
				FSC_Origen_de_los_Ingresos__c,
				FSC_Valor_de_la_Garantia__c,
				FSC_productoBanco__c,
				FSC_Resultado_Buro__c,
				FSC_XCore_Buro__c,
				FSC_Mensajes_Buro__c,
				FSC_LogErrores__c,
				FSC_Subestado__c,
				Status
			FROM ResidentialLoanApplication
			WHERE Id IN :rlaIds
		];

		if (rlas.isEmpty()) {
			return;
		}

		if (allValuesBlank(endpointsByRecordType)) {
			throw new CalloutException('Configuración faltante: no se encontró ConfigLoanDecisionAPI__mdt.URL o Value__c está vacío.');
		}

		Set<Id> accountIds = new Set<Id>();
		Set<Id> opportunityIds = new Set<Id>();
		for (ResidentialLoanApplication rla : rlas) {
			if (rla.AccountId != null) {
				accountIds.add(rla.AccountId);
			}
			if (rla.OpportunityId != null) {
				opportunityIds.add(rla.OpportunityId);
			}
		}

		Map<Id, Account> accountsById = new Map<Id, Account>();
		if (!accountIds.isEmpty()) {
			accountsById = new Map<Id, Account>(
				[
					SELECT Id, ACC_NumIdentificacion__c, ACC_TipoIdentificacion__c
					FROM Account
					WHERE Id IN :accountIds
				]
			);
		}

		Map<Id, Opportunity> opportunitiesById = new Map<Id, Opportunity>();
		if (!opportunityIds.isEmpty()) {
			opportunitiesById = new Map<Id, Opportunity>(
				[
					SELECT Id, OPP_VehValue__c, OPP_VehPrice__c, OPP_VehType__c, OPP_VehTime__c
					FROM Opportunity
					WHERE Id IN :opportunityIds
				]
			);
		}

		Map<Id, FinServ__Employment__c> historialByAccountId = new Map<Id, FinServ__Employment__c>();
		if (!accountIds.isEmpty()) {
			for (FinServ__Employment__c historial : [
				SELECT Cliente__c, EMP_Tipo_de_empleado__c
				FROM FinServ__Employment__c
				WHERE Cliente__c IN :accountIds
				ORDER BY CreatedDate DESC
			]) {
				if (!historialByAccountId.containsKey(historial.Cliente__c)) {
					historialByAccountId.put(historial.Cliente__c, historial);
				}
			}
		}

		Set<Id> rlaIdSet = new Set<Id>();
		for (ResidentialLoanApplication rla : rlas) {
			rlaIdSet.add(rla.Id);
		}

		Map<Id, LoanApplicant> debtorApplicantByRlaId = new Map<Id, LoanApplicant>();
		Map<Id, LoanApplicant> coDebtorApplicantByRlaId = new Map<Id, LoanApplicant>();
		for (LoanApplicant applicant : [
			SELECT
				LoanApplicationId,
				FSC_ClasificacionSIB__c,
				FSC_FuenteIngreso__c,
				FSC_NumIdentificacion__c,
				FSC_TiempoLaborando__c,
				FSC_TipoIdentificacion__c,
				FSC_TipoSolicitante__c,
				FSC_TotalIngresos__c
			FROM LoanApplicant
			WHERE LoanApplicationId IN :rlaIdSet AND FSC_TipoSolicitante__c IN ('Deudor', 'Co-Deudor')
			ORDER BY CreatedDate DESC, Id DESC
		]) {
			if (applicant.FSC_TipoSolicitante__c == 'Co-Deudor') {
				if (!coDebtorApplicantByRlaId.containsKey(applicant.LoanApplicationId)) {
					coDebtorApplicantByRlaId.put(applicant.LoanApplicationId, applicant);
				}
			} else {
				debtorApplicantByRlaId.put(applicant.LoanApplicationId, applicant);
			}
		}

		Map<Id, FSC_Garantia__c> guaranteeByRlaId = new Map<Id, FSC_Garantia__c>();
		for (FSC_Garantia__c guarantee : [
			SELECT
				FSC_Residential_Loan_Application__c,
				FSC_Precio_de_Venta__c,
				FSC_Tipo_de_Garantia__c,
				FSC_Valor_Inmueble__c,
				FSC_Valor_Tasado__c
			FROM FSC_Garantia__c
			WHERE FSC_Residential_Loan_Application__c IN :rlaIdSet
			ORDER BY CreatedDate
		]) {
			Id rlaId = guarantee.FSC_Residential_Loan_Application__c;
			if (!guaranteeByRlaId.containsKey(rlaId)) {
				guaranteeByRlaId.put(rlaId, guarantee);
			}
		}

		Http http = new Http();
		List<ResidentialLoanApplication> updates = new List<ResidentialLoanApplication>();

		for (ResidentialLoanApplication rla : rlas) {
			Account acc = accountsById.get(rla.AccountId);
			FinServ__Employment__c historial = historialByAccountId.get(rla.AccountId);
			Opportunity opportunity = opportunitiesById.get(rla.OpportunityId);
			LoanApplicant debtorApplicant = debtorApplicantByRlaId.get(rla.Id);
			LoanApplicant coDebtorApplicant = coDebtorApplicantByRlaId.get(rla.Id);
			FSC_Garantia__c guarantee = guaranteeByRlaId.get(rla.Id);

			ResidentialLoanApplication upd = new ResidentialLoanApplication(Id = rla.Id);

			try {
				if (acc == null) {
					upd.FSC_LogErrores__c = appendErrorLog(
						rla.FSC_LogErrores__c,
						buildErrorLogEntry('No se pudo consultar Buro: el ResidentialLoanApplication no tiene una Account relacionada valida.', null)
					);
					updates.add(upd);
					continue;
				}

				String recordTypeDeveloperName = getSupportedRecordTypeDeveloperName(rla);
				String endpoint = getEndpointForRecordType(recordTypeDeveloperName, endpointsByRecordType);
				if (String.isBlank(endpoint)) {
					throw new CalloutException(
						'Configuracion faltante: no se encontro URL para el tipo de solicitud ' + recordTypeDeveloperName + '.'
					);
				}

				String requestBody = buildRequestBody(
					recordTypeDeveloperName,
					new RequestContext(rla, acc, historial, opportunity, debtorApplicant, coDebtorApplicant, guarantee)
				);

				HttpRequest req = new HttpRequest();
				req.setEndpoint(endpoint);
				req.setMethod('POST');
				req.setHeader('Content-Type', 'application/json');
				if (!String.isBlank(authorizationHeader)) {
					req.setHeader('Authorization', authorizationHeader);
				}
				req.setTimeout(120000);
				req.setBody(requestBody);
				System.debug('requestBody: ' + requestBody);

				HttpResponse res = http.send(req);

				if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
					LoanDecisionResult result = parseResponse(res.getBody(), recordTypeDeveloperName);
					System.debug('result: ' + result);
					applyResultToRla(upd, result);
				} else {
					upd.FSC_LogErrores__c = appendErrorLog(
						rla.FSC_LogErrores__c,
						buildErrorLogEntry(
							'Error HTTP al consultar Buro: statusCode=' + res.getStatusCode() + ', statusLine=' + res.getStatus(),
							res.getBody()
						)
					);
				}
			} catch (Exception e) {
				upd.FSC_LogErrores__c = appendErrorLog(
					rla.FSC_LogErrores__c,
					buildErrorLogEntry('Excepcion al consultar Buro: ' + trimForLog(e.getMessage(), ERROR_LOG_BODY_MAX_LENGTH), null)
				);
			}

			updates.add(upd);
		}

		if (!updates.isEmpty()) {
			update updates;
		}
	}

	private static String buildRequestBody(String recordTypeDeveloperName, RequestContext ctx) {
		if (recordTypeDeveloperName == RT_CREDITO_VEHICULO) {
			return serializePersonalInformation(buildVehicularPersonalInfo(ctx), buildSecondaryPersonalInfo(ctx));
		}
		if (recordTypeDeveloperName == RT_CREDITO_HIPOTECARIO) {
			return serializePersonalInformation(buildHipotecarioPersonalInfo(ctx), buildSecondaryPersonalInfo(ctx));
		}
		return serializePersonalInformation(buildConsumoPersonalInfo(ctx), buildSecondaryPersonalInfo(ctx));
	}

	private static Map<String, Object> buildConsumoPersonalInfo(RequestContext ctx) {
		Map<String, Object> info = basePersonalInfo(ctx);
		info.put('asalariado', ctx.historial == null ? null : ctx.historial.EMP_Tipo_de_empleado__c);
		info.put('ingresos', getIngresos(ctx));
		putLoanInfo(info, ctx, 'tiempoLaborando', 'clasificacionSIB', 'MontoPrestamo', 'PlazoPrestamo', 'TasaPrestamo');
		return info;
	}

	private static Map<String, Object> buildVehicularPersonalInfo(RequestContext ctx) {
		Map<String, Object> info = basePersonalInfo(ctx);
		info.put('fuenteIngreso', safeString(ctx.rla.FSC_Origen_de_los_Ingresos__c));
		info.put('ingresoTotal', getIngresos(ctx));
		putLoanInfo(info, ctx, 'tiempoLaborando', 'clasificacionDeudor', 'montoPrestamo', 'plazoPrestamo', 'tasaPrestamo');
		info.put('valorVehiculo', getValorVehiculo(ctx));
		info.put('precioVenta', getPrecioVenta(ctx));
		info.put('tipoVehiculo', getTipoVehiculo(ctx));
		info.put('tiempoVehiculo', ctx.opportunity == null ? null : decimalToString(ctx.opportunity.OPP_VehTime__c));
		return info;
	}

	private static Map<String, Object> buildHipotecarioPersonalInfo(RequestContext ctx) {
		Map<String, Object> info = basePersonalInfo(ctx);
		info.put('asalariado', ctx.historial == null ? null : ctx.historial.EMP_Tipo_de_empleado__c);
		info.put('ingresos', getIngresos(ctx));
		putLoanInfo(info, ctx, 'tiempolaborando', 'clasificacionSIB', 'montoprestamo', 'plazoprestamo', 'tasaprestamo');
		info.put('valordelinmueble', getValorInmueble(ctx));
		info.put('preciodeventa', ctx.guarantee == null ? null : decimalToString(ctx.guarantee.FSC_Precio_de_Venta__c));
		return info;
	}

	private static Map<String, Object> basePersonalInfo(RequestContext ctx) {
		return new Map<String, Object>{
			'id' => safeString(ctx.acc.ACC_NumIdentificacion__c),
			'type' => mapTipoIdentificacion(ctx.acc.ACC_TipoIdentificacion__c)
		};
	}

	private static void putLoanInfo(
		Map<String, Object> info,
		RequestContext ctx,
		String laborKey,
		String classificationKey,
		String amountKey,
		String termKey,
		String rateKey
	) {
		info.put(laborKey, getTiempoLaborandoMeses(ctx));
		info.put(classificationKey, safeString(getClasificacionSib(ctx)));
		info.put(amountKey, getMontoPrestamo(ctx));
		info.put(termKey, getPlazoPrestamo(ctx));
		info.put(rateKey, getTasaPrestamo(ctx));
	}

	private static Map<String, Object> buildSecondaryPersonalInfo(RequestContext ctx) {
		Map<String, Object> info = emptySecondaryPersonalInfo();
		if (ctx.coDebtorApplicant == null) {
			return info;
		}

		LoanApplicant coDebtor = ctx.coDebtorApplicant;
		info.put('id', safeString(coDebtor.FSC_NumIdentificacion__c));
		info.put('type', safeString(mapTipoIdentificacion(coDebtor.FSC_TipoIdentificacion__c)));
		info.put('ingresos', safeString(decimalToString(coDebtor.FSC_TotalIngresos__c)));
		info.put('producto', safeString(ctx.rla.FSC_productoBanco__c));
		info.put('tipoGarantia', safeString(ctx.guarantee == null ? null : ctx.guarantee.FSC_Tipo_de_Garantia__c));
		info.put('valorInmueble', safeString(getValorInmueble(ctx)));
		info.put('precioVenta', safeString(getPrecioVenta(ctx)));
		info.put('clasificacionSIB', safeString(coDebtor.FSC_ClasificacionSIB__c));
		info.put('asalariado', safeString(mapFuenteIngresoToEmployeeType(coDebtor.FSC_FuenteIngreso__c)));
		info.put('montoPrestamo', safeString(getMontoPrestamo(ctx)));
		info.put('plazoPrestamo', safeString(getPlazoPrestamo(ctx)));
		info.put('tasaprestamo', safeString(getTasaPrestamo(ctx)));
		info.put('tiempolaborando', safeString(getTiempoLaborandoMeses(coDebtor)));
		return info;
	}

	private static Map<String, Object> emptySecondaryPersonalInfo() {
		Map<String, Object> info = new Map<String, Object>();
		for (String fieldName : new List<String>{
			'id', 'type', 'ingresos', 'producto', 'tipoGarantia', 'valorInmueble', 'precioVenta',
			'clasificacionSIB', 'asalariado', 'montoPrestamo', 'plazoPrestamo', 'tasaprestamo', 'tiempolaborando'
		}) {
			info.put(fieldName, '');
		}
		return info;
	}

	private static String serializePersonalInformation(
		Map<String, Object> personalInformation,
		Map<String, Object> secondaryPersonalInformation
	) {
		return JSON.serialize(
			new Map<String, Object>{
				'applicants' => new Map<String, Object>{
					'primaryConsumer' => new Map<String, Object>{ 'personalInformation' => personalInformation },
					'secondaryConsumer' => new Map<String, Object>{ 'personalInformation' => secondaryPersonalInformation }
				}
			}
		);
	}

	private static Map<String, String> getEndpointsByRecordType() {
		Map<String, String> endpointsByRecordType = new Map<String, String>();
		for (String recordTypeDeveloperName : CONFIG_BY_RECORD_TYPE.keySet()) {
			endpointsByRecordType.put(recordTypeDeveloperName, getConfigValue(CONFIG_BY_RECORD_TYPE.get(recordTypeDeveloperName)));
		}
		return endpointsByRecordType;
	}

	private static Boolean allValuesBlank(Map<String, String> valuesByKey) {
		for (String value : valuesByKey.values()) {
			if (!String.isBlank(value)) {
				return false;
			}
		}
		return true;
	}

	private static String getEndpointForRecordType(String recordTypeDeveloperName, Map<String, String> endpointsByRecordType) {
		String endpoint = endpointsByRecordType.get(recordTypeDeveloperName);
		if (!String.isBlank(endpoint)) {
			return endpoint;
		}

		String fallbackPath = PATH_BY_RECORD_TYPE.get(recordTypeDeveloperName);
		return String.isBlank(fallbackPath) ? endpoint : replaceLastEndpointPath(endpointsByRecordType.get(RT_CREDITO_CONSUMO), fallbackPath);
	}

	private static String replaceLastEndpointPath(String endpoint, String newPath) {
		if (String.isBlank(endpoint) || String.isBlank(newPath)) {
			return endpoint;
		}

		Integer interconnectIndex = endpoint.lastIndexOf('/interconnect/');
		if (interconnectIndex >= 0) {
			return endpoint.substring(0, interconnectIndex) + '/interconnect/' + newPath;
		}

		Integer lastSlashIndex = endpoint.lastIndexOf('/');
		return lastSlashIndex < 0 ? endpoint + '/' + newPath : endpoint.substring(0, lastSlashIndex + 1) + newPath;
	}

	private static String getSupportedRecordTypeDeveloperName(ResidentialLoanApplication rla) {
		String recordTypeDeveloperName = rla != null && rla.RecordType != null ? rla.RecordType.DeveloperName : null;
		return !String.isBlank(recordTypeDeveloperName) && CONFIG_BY_RECORD_TYPE.containsKey(recordTypeDeveloperName)
			? recordTypeDeveloperName
			: RT_CREDITO_CONSUMO;
	}

	private static String getTiempoLaborandoMeses(RequestContext ctx) {
		if (ctx.rla.FSC_A_os_de_operacion__c != null) {
			return decimalToString(ctx.rla.FSC_A_os_de_operacion__c * 12);
		}

		Date tiempoLaborando = ctx.debtorApplicant == null ? null : ctx.debtorApplicant.FSC_TiempoLaborando__c;
		return tiempoLaborando == null ? null : decimalToString(tiempoLaborando.monthsBetween(Date.today()));
	}

	private static String getTiempoLaborandoMeses(LoanApplicant applicant) {
		return applicant == null || applicant.FSC_TiempoLaborando__c == null
			? null
			: decimalToString(applicant.FSC_TiempoLaborando__c.monthsBetween(Date.today()));
	}

	private static String mapFuenteIngresoToEmployeeType(String fuenteIngreso) {
		Map<String, String> employeeTypeByIncomeSource = new Map<String, String>{
			'independiente' => '0',
			'empleado privado' => '1',
			'empleado publico' => '2',
			'empleado público' => '2'
		};
		String normalizedValue = normalize(fuenteIngreso);
		return employeeTypeByIncomeSource.containsKey(normalizedValue)
			? employeeTypeByIncomeSource.get(normalizedValue)
			: fuenteIngreso;
	}

	private static String getMontoPrestamo(RequestContext ctx) {
		return decimalToString(firstNonNull(new List<Object>{ ctx.rla.FSC_MontoAprobado__c, ctx.rla.FSC_Monto__c }));
	}

	private static String getPlazoPrestamo(RequestContext ctx) {
		return decimalToString(firstNonNull(new List<Object>{ ctx.rla.FSC_PlazoMesesAprobado__c, ctx.rla.FSC_Plazo_meses__c }));
	}

	private static String getTasaPrestamo(RequestContext ctx) {
		return decimalToString(firstNonNull(new List<Object>{ ctx.rla.FSC_TasaInteresAprobada__c, ctx.rla.FSC_TasaInteres__c }));
	}

	private static String getClasificacionSib(RequestContext ctx) {
		return firstNonBlank(
			new List<String>{
				ctx.rla.FSC_Clasificacion_de_Riesgo__c,
				ctx.debtorApplicant == null ? null : ctx.debtorApplicant.FSC_ClasificacionSIB__c
			}
		);
	}

	private static String getIngresos(RequestContext ctx) {
		return decimalToString(
			firstNonNull(
				new List<Object>{ ctx.rla.FSC_Ingresos_Mensuales__c, ctx.debtorApplicant == null ? null : ctx.debtorApplicant.FSC_TotalIngresos__c }
			)
		);
	}

	private static String getValorVehiculo(RequestContext ctx) {
		return decimalToString(
			firstNonNull(
				new List<Object>{
					ctx.opportunity == null ? null : ctx.opportunity.OPP_VehValue__c,
					ctx.guarantee == null ? null : ctx.guarantee.FSC_Valor_Inmueble__c,
					ctx.guarantee == null ? null : ctx.guarantee.FSC_Valor_Tasado__c,
					ctx.rla.FSC_Valor_de_la_Garantia__c
				}
			)
		);
	}

	private static String getValorInmueble(RequestContext ctx) {
		return decimalToString(
			firstNonNull(
				new List<Object>{
					ctx.guarantee == null ? null : ctx.guarantee.FSC_Valor_Inmueble__c,
					ctx.guarantee == null ? null : ctx.guarantee.FSC_Valor_Tasado__c,
					ctx.rla.FSC_Valor_de_la_Garantia__c
				}
			)
		);
	}

	private static String getPrecioVenta(RequestContext ctx) {
		return decimalToString(
			firstNonNull(
				new List<Object>{
					ctx.opportunity == null ? null : ctx.opportunity.OPP_VehPrice__c,
					ctx.guarantee == null ? null : ctx.guarantee.FSC_Precio_de_Venta__c
				}
			)
		);
	}

	private static String getTipoVehiculo(RequestContext ctx) {
		return firstNonBlank(new List<String>{ ctx.opportunity == null ? null : ctx.opportunity.OPP_VehType__c });
	}

	private static String mapEstadoDelVehiculo(String estadoDelVehiculo) {
		String normalizedValue = normalize(estadoDelVehiculo);
		if (String.isBlank(normalizedValue)) {
			return null;
		}
		if (normalizedValue == '1' || normalizedValue.contains('nuevo')) {
			return '1';
		}
		return normalizedValue == '2' || normalizedValue.contains('usado') ? '2' : estadoDelVehiculo;
	}

	private static Object firstNonNull(List<Object> values) {
		for (Object value : values) {
			if (value != null) {
				return value;
			}
		}
		return null;
	}

	private static String firstNonBlank(List<String> values) {
		for (String value : values) {
			if (!String.isBlank(value)) {
				return value;
			}
		}
		return null;
	}

	private static LoanDecisionResult parseResponse(String responseBody, String recordTypeDeveloperName) {
		LoanDecisionResult result = new LoanDecisionResult();

		if (String.isBlank(responseBody)) {
			return result;
		}

		Map<String, Object> root = parseResponseBodyToMap(responseBody);
		if (root == null) {
			return result;
		}

		Map<String, Object> applicants = objectToMap(root.get('applicants'));
		Map<String, Object> primaryConsumer = applicants == null ? null : objectToMap(applicants.get('primaryConsumer'));
		Map<String, Object> interconnectResponse = primaryConsumer == null ? null : objectToMap(primaryConsumer.get('interconnectResponse'));
		Map<String, Object> filtro = getDecisionFilterNode(root, interconnectResponse, recordTypeDeveloperName);
		Map<String, Object> generales = filtro == null ? null : objectToMap(filtro.get('Generales'));

		if (generales != null) {
			result.dictamen = objectToString(generales.get('Dictamen'));
			result.xcore = objectToDecimal(generales.get('Xcore'));

			result.mensajes = formatMensajesFromNode(generales);
		}

		if (String.isBlank(result.mensajes) && filtro != null) {
			result.mensajes = formatMensajesFromNode(filtro);
		}

		if (result.xcore == null && filtro != null) {
			result.xcore = objectToDecimal(findFirstValueByKey(filtro, 'Xcore'));
		}

		if (result.xcore == null && interconnectResponse != null) {
			Map<String, Object> xcoreNode = objectToMap(interconnectResponse.get('Xcore_PD12M_ALL_PC_NC_Global'));
			if (xcoreNode != null) {
				result.xcore = objectToDecimal(xcoreNode.get('Xcore'));
			}
		}

		return result;
	}

	private static Map<String, Object> getDecisionFilterNode(
		Map<String, Object> root,
		Map<String, Object> interconnectResponse,
		String recordTypeDeveloperName
	) {
		String expectedNodeName = RESPONSE_NODE_BY_RECORD_TYPE.get(recordTypeDeveloperName);
		if (String.isBlank(expectedNodeName)) {
			expectedNodeName = RESPONSE_NODE_CONSUMO;
		}

		if (recordTypeDeveloperName == RT_CREDITO_HIPOTECARIO) {
			Map<String, Object> rootNode = objectToMap(root.get(expectedNodeName));
			if (rootNode != null) {
				return rootNode;
			}
		}

		Map<String, Object> interconnectNode = interconnectResponse == null ? null : objectToMap(interconnectResponse.get(expectedNodeName));
		if (interconnectNode != null) {
			return interconnectNode;
		}

		for (String nodeName : new List<String>{ RESPONSE_NODE_CONSUMO, RESPONSE_NODE_VEHICULAR }) {
			Map<String, Object> fallbackNode = interconnectResponse == null ? null : objectToMap(interconnectResponse.get(nodeName));
			if (fallbackNode != null) {
				return fallbackNode;
			}
		}

		return objectToMap(root.get(RESPONSE_NODE_HIPOTECARIO));
	}

	private static String formatMensajesFromNode(Map<String, Object> node) {
		Map<String, Object> mensajes = node == null ? null : objectToMap(node.get('Mensajes'));
		if (mensajes == null) {
			return null;
		}

		List<Object> evaluacion = objectToList(mensajes.get('Evaluacion'));
		return formatMensajes(evaluacion);
	}

	private static Object findFirstValueByKey(Object value, String key) {
		Map<String, Object> valueAsMap = objectToMap(value);
		if (valueAsMap != null) {
			if (valueAsMap.containsKey(key) && valueAsMap.get(key) != null) {
				return valueAsMap.get(key);
			}

			for (Object childValue : valueAsMap.values()) {
				Object foundValue = findFirstValueByKey(childValue, key);
				if (foundValue != null) {
					return foundValue;
				}
			}
			return null;
		}

		List<Object> valueAsList = objectToList(value);
		if (valueAsList != null) {
			for (Object childValue : valueAsList) {
				Object foundValue = findFirstValueByKey(childValue, key);
				if (foundValue != null) {
					return foundValue;
				}
			}
		}

		return null;
	}

	private static void applyResultToRla(ResidentialLoanApplication upd, LoanDecisionResult result) {
		upd.FSC_Resultado_Buro__c = result.dictamen;
		upd.FSC_XCore_Buro__c = result.xcore;
		upd.FSC_Mensajes_Buro__c = result.mensajes;

		String dictamenNormalized = normalize(result.dictamen);

		if (dictamenNormalized == 'aprobado') {
			upd.FSC_Subestado__c = SUBESTADO_APROBADO;
		} else if (dictamenNormalized == 'referido') {
			upd.FSC_Subestado__c = SUBESTADO_REFERIDO;
		} else if (dictamenNormalized == 'rechazado') {
			upd.FSC_Subestado__c = SUBESTADO_RECHAZADO;
			upd.FSC_MotivosDeRechazo__c = MOTIVO_RECHAZADO;
			upd.Status = STATUS_CERRADA_PERDIDA;
		}
	}

	private static String formatMensajes(List<Object> evaluacion) {
		if (evaluacion == null || evaluacion.isEmpty()) {
			return null;
		}

		List<String> bloques = new List<String>();

		for (Object item : evaluacion) {
			if (!(item instanceof Map<String, Object>)) {
				continue;
			}

			Map<String, Object> mensaje = (Map<String, Object>) item;
			String code = objectToString(mensaje.get('code'));
			String description = objectToString(mensaje.get('description'));

			List<String> bloque = new List<String>();
			bloque.add('code: ' + safeString(code));
			bloque.add('description: ' + safeString(description));

			bloques.add(String.join(bloque, '\n'));
		}

		return bloques.isEmpty() ? null : String.join(bloques, '\n\n');
	}

	private static String buildErrorLogEntry(String mainMessage, String responseBody) {
		List<String> parts = new List<String>{ Datetime.now().format(ERROR_LOG_TIMESTAMP_FORMAT), mainMessage };

		String responseSummary = buildResponseSummary(responseBody);
		if (!String.isBlank(responseSummary)) {
			parts.add(responseSummary);
		}

		return String.join(parts, ' | ');
	}

	private static String appendErrorLog(String currentLog, String newEntry) {
		if (String.isBlank(newEntry)) {
			return currentLog;
		}
		if (String.isBlank(currentLog)) {
			return newEntry;
		}

		return currentLog + ERROR_LOG_SEPARATOR + newEntry;
	}

	private static String buildResponseSummary(String responseBody) {
		if (String.isBlank(responseBody)) {
			return null;
		}

		Map<String, Object> root = parseResponseBodyToMap(responseBody);
		if (root == null) {
			return trimForLog(cleanResponseBody(responseBody), ERROR_LOG_BODY_MAX_LENGTH);
		}

		List<String> parts = new List<String>();
		addResponseSummaryPart(parts, 'transactionId', root.get('transactionId'));
		addResponseSummaryPart(parts, 'status', root.get('status'));
		addResponseSummaryPart(parts, 'error', root.get('error'));
		addResponseSummaryPart(parts, 'message', root.get('message'));
		addResponseSummaryPart(parts, 'efxErrorCode', root.get('efxErrorCode'));
		addResponseSummaryPart(parts, 'description', root.get('description'));

		Map<String, Object> additionalErrorDetails = objectToMap(root.get('additionalErrorDetails'));
		if (additionalErrorDetails != null) {
			addResponseSummaryPart(parts, 'detailError', additionalErrorDetails.get('error'));
			addResponseSummaryPart(parts, 'detailTimestamp', additionalErrorDetails.get('timestamp'));
			addResponseSummaryPart(parts, 'apiStatus', additionalErrorDetails.get('status'));
		}

		return parts.isEmpty() ? trimForLog(cleanResponseBody(responseBody), ERROR_LOG_BODY_MAX_LENGTH) : String.join(parts, ' | ');
	}

	private static Map<String, Object> parseResponseBodyToMap(String responseBody) {
		String jsonCandidate = extractJsonCandidate(responseBody);
		if (String.isBlank(jsonCandidate)) {
			return null;
		}

		try {
			Object parsed = JSON.deserializeUntyped(jsonCandidate);
			return objectToMap(parsed);
		} catch (Exception e) {
			return null;
		}
	}

	private static String extractJsonCandidate(String responseBody) {
		String cleanedResponseBody = cleanResponseBody(responseBody);
		Integer firstBrace = cleanedResponseBody.indexOf('{');
		Integer lastBrace = cleanedResponseBody.lastIndexOf('}');

		if (firstBrace < 0 || lastBrace <= firstBrace) {
			return null;
		}

		String jsonCandidate = cleanedResponseBody.substring(firstBrace, lastBrace + 1);
		jsonCandidate = jsonCandidate.replace('\\\"', '"');
		jsonCandidate = jsonCandidate.replace('\\r', '\r');
		jsonCandidate = jsonCandidate.replace('\\n', '\n');
		jsonCandidate = jsonCandidate.replace('\\t', '\t');

		return jsonCandidate;
	}

	private static String cleanResponseBody(String responseBody) {
		if (String.isBlank(responseBody)) {
			return responseBody;
		}

		String cleanedResponseBody = responseBody.trim();
		cleanedResponseBody = cleanedResponseBody.replace('<EOL>', '\n');
		cleanedResponseBody = cleanedResponseBody.replace('\r\n', '\n');
		cleanedResponseBody = cleanedResponseBody.replace('\r', '\n');

		while (cleanedResponseBody.contains('  ')) {
			cleanedResponseBody = cleanedResponseBody.replace('  ', ' ');
		}

		return cleanedResponseBody;
	}

	private static Map<String, Object> objectToMap(Object value) {
		if (value == null || !(value instanceof Map<String, Object>)) {
			return null;
		}

		return (Map<String, Object>) value;
	}

	private static List<Object> objectToList(Object value) {
		if (value == null || !(value instanceof List<Object>)) {
			return null;
		}

		return (List<Object>) value;
	}

	private static void addResponseSummaryPart(List<String> parts, String label, Object value) {
		String textValue = objectToString(value);
		if (!String.isBlank(textValue)) {
			parts.add(label + '=' + trimForLog(textValue, ERROR_LOG_BODY_MAX_LENGTH));
		}
	}

	private static String trimForLog(String value, Integer maxLength) {
		if (String.isBlank(value) || maxLength == null || value.length() <= maxLength) {
			return value;
		}

		return value.substring(0, maxLength) + '...';
	}

	private static String getConfigValue(String developerName) {
		if (Test.isRunningTest() && testConfigValues != null && testConfigValues.containsKey(developerName)) {
			return testConfigValues.get(developerName);
		}

		ConfigLoanDecisionAPI__mdt configRecord = ConfigLoanDecisionAPI__mdt.getInstance(developerName);
		return configRecord == null ? null : configRecord.Value__c;
	}

	private static String getAuthorizationHeader() {
		String credentialsValue = getConfigValue(CONFIG_CREDENTIALS);
		if (String.isBlank(credentialsValue)) {
			return null;
		}

		String trimmedValue = credentialsValue.trim();
		return trimmedValue.toLowerCase().startsWith('bearer ') ? trimmedValue : 'Bearer ' + trimmedValue;
	}

	private static String decimalToString(Object value) {
		return value == null ? null : String.valueOf(value);
	}

	private static Decimal objectToDecimal(Object value) {
		if (value == null) {
			return null;
		}

		try {
			return Decimal.valueOf(String.valueOf(value));
		} catch (Exception e) {
			return null;
		}
	}

	private static String objectToString(Object value) {
		return value == null ? null : String.valueOf(value);
	}

	private static String safeString(String value) {
		return value == null ? '' : value;
	}

	private static String normalize(String value) {
		return value == null ? null : value.trim().toLowerCase();
	}

	private static String mapTipoIdentificacion(String tipoIdentificacion) {
		String value = normalize(tipoIdentificacion);

		if (String.isBlank(value)) {
			return null;
		}

		if (value == 'c' || value == 'cedula' || value == 'cédula') {
			return 'C';
		}
		if (value == 'r' || value == 'rnc') {
			return 'R';
		}
		if (value == 'pasaporte') {
			return 'P';
		}

		return tipoIdentificacion;
	}

	private class RequestContext {
		public ResidentialLoanApplication rla;
		public Account acc;
		public FinServ__Employment__c historial;
		public Opportunity opportunity;
		public LoanApplicant debtorApplicant;
		public LoanApplicant coDebtorApplicant;
		public FSC_Garantia__c guarantee;

		public RequestContext(
			ResidentialLoanApplication rla,
			Account acc,
			FinServ__Employment__c historial,
			Opportunity opportunity,
			LoanApplicant debtorApplicant,
			LoanApplicant coDebtorApplicant,
			FSC_Garantia__c guarantee
		) {
			this.rla = rla;
			this.acc = acc;
			this.historial = historial;
			this.opportunity = opportunity;
			this.debtorApplicant = debtorApplicant;
			this.coDebtorApplicant = coDebtorApplicant;
			this.guarantee = guarantee;
		}
	}

	private class LoanDecisionResult {
		public String dictamen;
		public Decimal xcore;
		public String mensajes;
	}
}
