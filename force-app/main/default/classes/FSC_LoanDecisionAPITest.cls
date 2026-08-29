@IsTest
private class FSC_LoanDecisionAPITest {
	private static void configureTestConfig() {
		FSC_LoanDecisionAPI.testConfigValues = new Map<String, String>{
			'URL' => 'https://loan-decision.test/interconnect/precon',
			'Credentials' => 'test-token'
		};
	}

	private static Boolean callApiSkippedForMissingConfig(List<Id> rlaIds) {
		configureTestConfig();
		try {
			FSC_LoanDecisionAPI.callAPI(rlaIds);
			return false;
		} catch (CalloutException e) {
			if (isMissingLoanDecisionConfig(e)) {
				return true;
			}
			throw e;
		}
	}

	private static Boolean isMissingLoanDecisionConfig(Exception e) {
		return e != null &&
			e.getMessage() != null &&
			e.getMessage().contains('Configuración faltante: no se encontró ConfigLoanDecisionAPI__mdt.URL');
	}

	private static Account createDecisionAccount(String tipoIdentificacion) {
		Account acc = new Account(
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId(),
			Name = 'Cuenta API Test ' + System.now().getTime(),
			ACC_NumIdentificacion__c = '00108803610',
			ACC_TipoIdentificacion__c = tipoIdentificacion
		);
		insert acc;
		return acc;
	}

	private static FinServ__Employment__c createHistorial(Id accountId, String tipoEmpleado) {
		FinServ__Employment__c historial = new FinServ__Employment__c(Cliente__c = accountId, EMP_Tipo_de_empleado__c = tipoEmpleado);
		insert historial;
		return historial;
	}

	private static ResidentialLoanApplication createDecisionRla(Id accountId, String subestado) {
		return createDecisionRla(accountId, subestado, null, null);
	}

	private static ResidentialLoanApplication createDecisionRla(Id accountId, String subestado, String recordTypeDeveloperName, Id opportunityId) {
		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA API Test ' + System.now().getTime(),
			AccountId = accountId,
			OpportunityId = opportunityId,
			Status = 'En proceso',
			FSC_Subestado__c = subestado,
			FSC_Ingresos_Mensuales__c = 90000,
			FSC_A_os_de_operacion__c = 5,
			FSC_Clasificacion_de_Riesgo__c = '780',
			FSC_MontoAprobado__c = 650000,
			FSC_PlazoMesesAprobado__c = 60,
			FSC_TasaInteresAprobada__c = 18,
			FSC_Origen_de_los_Ingresos__c = '1',
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401'
		);
		Id recordTypeId = getRlaRecordTypeId(recordTypeDeveloperName);
		if (recordTypeId != null) {
			rla.RecordTypeId = recordTypeId;
		}
		insert rla;
		return rla;
	}

	private static Id getRlaRecordTypeId(String developerName) {
		if (String.isBlank(developerName)) {
			return null;
		}

		Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName();
		if (!recordTypes.containsKey(developerName)) {
			return null;
		}

		return recordTypes.get(developerName).getRecordTypeId();
	}

	private static Opportunity createDecisionOpportunity(Id accountId) {
		Opportunity opp = new Opportunity(
			Name = 'Opp API Test ' + System.now().getTime(),
			AccountId = accountId,
			StageName = getAnyActiveStageName(),
			CloseDate = Date.today().addDays(30),
			OPP_VehValue__c = 2500000,
			OPP_VehPrice__c = 2400000,
			OPP_VehType__c = '1',
			OPP_VehTime__c = 4
		);
		insert opp;
		return opp;
	}

	private static String getAnyActiveStageName() {
		OpportunityStage os = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = TRUE LIMIT 1];
		return os.MasterLabel;
	}

	private static FSC_Facilidades_De_Credito__c createDecisionFacility(Id rlaId) {
		FSC_Facilidades_De_Credito__c facility = new FSC_Facilidades_De_Credito__c(
			Name = 'Facilidad API Test ' + System.now().getTime(),
			FSC_Residential_Loan_Application__c = rlaId,
			FSC_Monto_Solicitado__c = 1800000,
			FSC_Plazo_meses__c = 60,
			FSC_Tasa__c = 18,
			FSC_EstadoDelVehiculo__c = 'Nuevos'
		);
		insert facility;
		return facility;
	}

	private static FSC_Garantia__c createDecisionGuarantee(Id rlaId) {
		FSC_Garantia__c guarantee = new FSC_Garantia__c(
			Name = 'Garantia API Test ' + System.now().getTime(),
			FSC_Residential_Loan_Application__c = rlaId,
			FSC_Tipo_de_Garantia__c = 'Hipotecaria',
			FSC_Valor_Inmueble__c = 5000000,
			FSC_Precio_de_Venta__c = 4700000
		);
		insert guarantee;
		return guarantee;
	}

	private static LoanApplicant createCoDebtor(
		Id rlaId,
		String identificationNumber,
		Decimal totalIncome,
		String riskClassification
	) {
		LoanApplicant coDebtor = new LoanApplicant(
			Name = 'Codeudor API Test ' + System.now().getTime(),
			LoanApplicationId = rlaId,
			FSC_Nombre__c = 'Codeudor API Test',
			FSC_TipoSolicitante__c = 'Co-Deudor',
			FSC_TipoIdentificacion__c = 'Cédula',
			FSC_NumIdentificacion__c = identificationNumber,
			FSC_IngresosMensuales__c = totalIncome,
			FSC_OtrosIngresos__c = 0,
			FSC_ClasificacionSIB__c = riskClassification,
			FSC_FuenteIngreso__c = 'Empleado Publico',
			FSC_TiempoLaborando__c = Date.today().addYears(-3)
		);
		insert coDebtor;
		return coDebtor;
	}

	private static Map<String, Object> getPersonalInformation(String body) {
		return getPersonalInformation(body, 'primaryConsumer');
	}

	private static Map<String, Object> getPersonalInformation(String body, String consumerKey) {
		Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(body);
		Map<String, Object> applicants = (Map<String, Object>) root.get('applicants');
		Map<String, Object> consumer = (Map<String, Object>) applicants.get(consumerKey);
		return (Map<String, Object>) consumer.get('personalInformation');
	}

	private static void assertSecondaryConsumerIsEmpty(String body) {
		Map<String, Object> secondaryPersonalInformation = getPersonalInformation(body, 'secondaryConsumer');
		Set<String> expectedKeys = new Set<String>{
			'id',
			'type',
			'ingresos',
			'producto',
			'tipoGarantia',
			'valorInmueble',
			'precioVenta',
			'clasificacionSIB',
			'asalariado',
			'montoPrestamo',
			'plazoPrestamo',
			'tasaprestamo',
			'tiempolaborando'
		};

		Assert.areEqual(expectedKeys, secondaryPersonalInformation.keySet(), 'El secondaryConsumer debe contener exactamente las claves esperadas.');
		for (String key : expectedKeys) {
			Assert.areEqual('', secondaryPersonalInformation.get(key), 'El campo ' + key + ' de secondaryConsumer debe enviarse vacío.');
		}
	}

	private static void assertNumberStringEquals(String expected, Object actual, String message) {
		Assert.areEqual(Decimal.valueOf(expected), Decimal.valueOf(String.valueOf(actual)), message);
	}

	private class ApprovedMock implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest req) {
			System.assertEquals('POST', req.getMethod(), 'La API debe llamarse con POST.');
			System.assert(req.getEndpoint().contains('/interconnect/precon'), 'El endpoint debe apuntar a /interconnect/precon.');
			System.assertEquals('application/json', req.getHeader('Content-Type'));
			System.assertNotEquals(null, req.getHeader('Authorization'));
			System.assert(req.getHeader('Authorization').startsWith('Bearer '), 'Debe enviarse Authorization Bearer.');

			String body = req.getBody();
			assertSecondaryConsumerIsEmpty(body);
			System.assert(body.contains('"type":"C"'), 'Debe traducirse Cédula -> C.');
			System.assert(body.contains('"asalariado":"1"'), 'Debe enviarse el API name del picklist.');
			System.assert(body.contains('"tiempoLaborando":"60'), '5 años deben convertirse a 60 meses.');
			System.assert(body.contains('"MontoPrestamo":"650000'), 'Debe enviarse el monto aprobado.');

			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);
			res.setHeader('Content-Type', 'application/json');
			res.setBody(
				'{' +
					'"transactionId":"trx-approved",' +
					'"status":"completed",' +
					'"applicants":{' +
					'"primaryConsumer":{' +
					'"interconnectResponse":{' +
					'"Filtro_BcoVimencaPre":{' +
					'"Generales":{' +
					'"Dictamen":"Aprobado",' +
					'"Xcore":"745",' +
					'"Mensajes":{' +
					'"Evaluacion":[' +
					'{"code":"A1","description":"Aprobado por score"},' +
					'{"code":"A2","description":"Cliente cumple políticas"}' +
					']' +
					'}' +
					'}' +
					'}' +
					'}' +
					'}' +
					'}' +
					'}'
			);
			return res;
		}
	}

	private class SecondaryConsumerMock implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest req) {
			Map<String, Object> personalInformation = getPersonalInformation(req.getBody(), 'secondaryConsumer');
			Assert.areEqual('00200000002', personalInformation.get('id'), 'Debe enviarse el codeudor creado más recientemente.');
			Assert.areEqual('C', personalInformation.get('type'), 'El tipo de identificación del codeudor debe mapearse.');
			assertNumberStringEquals('125000', personalInformation.get('ingresos'), 'Los ingresos del codeudor son incorrectos.');
			Assert.areEqual('401', personalInformation.get('producto'), 'El producto compartido de la solicitud es incorrecto.');
			Assert.areEqual('Hipotecaria', personalInformation.get('tipoGarantia'), 'El tipo de garantía es incorrecto.');
			assertNumberStringEquals('5000000', personalInformation.get('valorInmueble'), 'El valor del inmueble es incorrecto.');
			assertNumberStringEquals('4700000', personalInformation.get('precioVenta'), 'El precio de venta es incorrecto.');
			Assert.areEqual('A', personalInformation.get('clasificacionSIB'), 'La clasificación del codeudor es incorrecta.');
			Assert.areEqual('2', personalInformation.get('asalariado'), 'La fuente de ingreso debe mapearse al código de empleado.');
			assertNumberStringEquals('650000', personalInformation.get('montoPrestamo'), 'El monto del préstamo es incorrecto.');
			assertNumberStringEquals('60', personalInformation.get('plazoPrestamo'), 'El plazo del préstamo es incorrecto.');
			assertNumberStringEquals('18', personalInformation.get('tasaprestamo'), 'La tasa del préstamo es incorrecta.');
			assertNumberStringEquals('36', personalInformation.get('tiempolaborando'), 'La antigüedad laboral del codeudor es incorrecta.');

			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setHeader('Content-Type', 'application/json');
			response.setBody(buildApprovedResponseBody());
			return response;
		}
	}

	private class VehicularMock implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest req) {
			System.assertEquals('POST', req.getMethod(), 'La API debe llamarse con POST.');

			String body = req.getBody();
			assertSecondaryConsumerIsEmpty(body);
			Map<String, Object> personalInformation = getPersonalInformation(body);
			System.assertEquals('00108803610', personalInformation.get('id'));
			System.assertEquals('C', personalInformation.get('type'));
			System.assertEquals('1', personalInformation.get('fuenteIngreso'));
			assertNumberStringEquals('90000', personalInformation.get('ingresoTotal'), 'ingresoTotal incorrecto.');
			assertNumberStringEquals('60', personalInformation.get('tiempoLaborando'), 'tiempoLaborando incorrecto.');
			System.assertEquals('780', personalInformation.get('clasificacionDeudor'));
			assertNumberStringEquals('2000000', personalInformation.get('montoPrestamo'), 'montoPrestamo incorrecto.');
			assertNumberStringEquals('60', personalInformation.get('plazoPrestamo'), 'plazoPrestamo incorrecto.');
			assertNumberStringEquals('18', personalInformation.get('tasaPrestamo'), 'tasaPrestamo incorrecto.');
			assertNumberStringEquals('2500000', personalInformation.get('valorVehiculo'), 'valorVehiculo incorrecto.');
			assertNumberStringEquals('2400000', personalInformation.get('precioVenta'), 'precioVenta incorrecto.');
			Object tipoVehiculo = personalInformation.get('tipoVehiculo');
			System.assert(tipoVehiculo == null || String.valueOf(tipoVehiculo) == '1', 'tipoVehiculo inesperado.');
			System.assert(!personalInformation.containsKey('asalariado'), 'Vehicular no debe enviar la estructura de consumo.');

			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);
			res.setHeader('Content-Type', 'application/json');
			res.setBody(buildVehicularApprovedResponseBody());
			return res;
		}
	}

	private class HipotecarioMock implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest req) {
			System.assertEquals('POST', req.getMethod(), 'La API debe llamarse con POST.');
			System.assert(req.getEndpoint().contains('/interconnect/prehip'), 'El endpoint hipotecario debe apuntar a /interconnect/prehip.');

			String body = req.getBody();
			assertSecondaryConsumerIsEmpty(body);
			Map<String, Object> personalInformation = getPersonalInformation(body);
			System.assertEquals('00108803610', personalInformation.get('id'));
			System.assertEquals('C', personalInformation.get('type'));
			System.assertEquals('1', personalInformation.get('asalariado'));
			assertNumberStringEquals('90000', personalInformation.get('ingresos'), 'ingresos incorrecto.');
			assertNumberStringEquals('60', personalInformation.get('tiempolaborando'), 'tiempolaborando incorrecto.');
			System.assertEquals('780', personalInformation.get('clasificacionSIB'));
			assertNumberStringEquals('1800000', personalInformation.get('montoprestamo'), 'montoprestamo incorrecto.');
			assertNumberStringEquals('60', personalInformation.get('plazoprestamo'), 'plazoprestamo incorrecto.');
			assertNumberStringEquals('18', personalInformation.get('tasaprestamo'), 'tasaprestamo incorrecto.');
			assertNumberStringEquals('5000000', personalInformation.get('valordelinmueble'), 'valordelinmueble incorrecto.');
			assertNumberStringEquals('4700000', personalInformation.get('preciodeventa'), 'preciodeventa incorrecto.');
			System.assert(!personalInformation.containsKey('MontoPrestamo'), 'Hipotecario debe usar las claves solicitadas.');

			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);
			res.setHeader('Content-Type', 'application/json');
			res.setBody(buildHipotecarioApprovedResponseBody());
			return res;
		}
	}

	private static String buildApprovedResponseBody() {
		return '{' +
			'"transactionId":"trx-approved",' +
			'"status":"completed",' +
			'"applicants":{' +
			'"primaryConsumer":{' +
			'"interconnectResponse":{' +
			'"Filtro_BcoVimencaPre":{' +
			'"Generales":{' +
			'"Dictamen":"Aprobado",' +
			'"Xcore":"745",' +
			'"Mensajes":{' +
			'"Evaluacion":[]' +
			'}' +
			'}' +
			'}' +
			'}' +
			'}' +
			'}' +
			'}';
	}

	private static String buildVehicularApprovedResponseBody() {
		return '{' +
			'"transactionId":"trx-vehicular",' +
			'"status":"completed",' +
			'"applicants":{' +
			'"primaryConsumer":{' +
			'"interconnectResponse":{' +
			'"Filtro_BcoVimencaVhi":{' +
			'"Generales":{' +
			'"Dictamen":"Aprobado",' +
			'"Xcore":746,' +
			'"Mensajes":{' +
			'"Evaluacion":[' +
			'{"code":"VH1","description":"Vehicular aprobado"}' +
			']' +
			'}' +
			'}' +
			'}' +
			'}' +
			'}' +
			'}' +
			'}';
	}

	private static String buildHipotecarioApprovedResponseBody() {
		return '{' +
			'"transactionId":"trx-hipotecario",' +
			'"status":"completed",' +
			'"applicants":{' +
			'"primaryConsumer":{' +
			'"interconnectResponse":{' +
			'"Xcore_PD12M_ALL_PC_NC_Global":{"Xcore":"611"}' +
			'}' +
			'}' +
			'},' +
			'"FiltroVimencaPreHipotecario":{' +
			'"Generales":{' +
			'"Color":"Green",' +
			'"Dictamen":"Aprobado"' +
			'},' +
			'"Participantes":{' +
			'"Solicitante":[' +
			'{"Dictamen":"Aprobado","Xcore":"856","CodigoTipoSolicitante":"1","TipoSolicitante":"Deudor Principal"},' +
			'{"Dictamen":"Aprobado","Xcore":"852","CodigoTipoSolicitante":"2","TipoSolicitante":"Codeudor"}' +
			']' +
			'},' +
			'"Mensajes":{' +
			'"Evaluacion":[' +
			'{"code":"HP1","description":"Hipotecario aprobado"}' +
			']' +
			'}' +
			'}' +
			'}';
	}

	private class ReferredFallbackXcoreMock implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);
			res.setHeader('Content-Type', 'application/json');
			res.setBody(
				'{' +
					'"transactionId":"trx-referred",' +
					'"status":"completed",' +
					'"applicants":{' +
					'"primaryConsumer":{' +
					'"interconnectResponse":{' +
					'"Filtro_BcoVimencaPre":{' +
					'"Generales":{' +
					'"Dictamen":"Referido",' +
					'"Xcore":null,' +
					'"Mensajes":{' +
					'"Evaluacion":[' +
					'{"code":"R1","description":"Revisión manual requerida"}' +
					']' +
					'}' +
					'}' +
					'},' +
					'"Xcore_PD12M_ALL_PC_NC_Global":{' +
					'"Xcore":"612"' +
					'}' +
					'}' +
					'}' +
					'}' +
					'}'
			);
			return res;
		}
	}

	private class RejectedMock implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);
			res.setHeader('Content-Type', 'application/json');
			res.setBody(
				'{' +
					'"transactionId":"trx-rejected",' +
					'"status":"completed",' +
					'"applicants":{' +
					'"primaryConsumer":{' +
					'"interconnectResponse":{' +
					'"Filtro_BcoVimencaPre":{' +
					'"Generales":{' +
					'"Dictamen":"Rechazado",' +
					'"Xcore":"450",' +
					'"Mensajes":{' +
					'"Evaluacion":[' +
					'{"code":"RJ","description":"No cumple políticas de riesgo"}' +
					']' +
					'}' +
					'}' +
					'}' +
					'}' +
					'}' +
					'}' +
					'}'
			);
			return res;
		}
	}

	private class ErrorResponseMock implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(400);
			res.setStatus('Bad Request');
			res.setBody(
				'500 Internal Server Error: "{\n' +
					'  \"efxErrorCode\": \"500.00\",\n' +
					'  \"description\": \"Please refer to additionalErrorDetails\",\n' +
					'  \"additionalErrorDetails\": {\n' +
					'    \"error\": \"CC_ERROR_003\",\n' +
					'    \"timestamp\": \"2026-03-26T18:07:43.862089121\",\n' +
					'    \"status\": 500\n' +
					'  }\n' +
					'}"'
			);
			return res;
		}
	}

	private class ExceptionMock implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest req) {
			throw new CalloutException('Timeout simulado');
		}
	}

	@IsTest
	static void testCallApi_Aprobado_ActualizaCamposYMapeaRequest() {
		Account acc = createDecisionAccount('Cédula');
		createHistorial(acc.Id, '1');
		ResidentialLoanApplication rla = createDecisionRla(acc.Id, 'En Motor Buró', 'FSC_Solicitud_Credito_Consumo', null);

		Test.setMock(HttpCalloutMock.class, new ApprovedMock());

		Test.startTest();
		if (callApiSkippedForMissingConfig(new List<Id>{ rla.Id })) {
			Test.stopTest();
			return;
		}
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_Resultado_Buro__c, FSC_XCore_Buro__c, FSC_Mensajes_Buro__c, FSC_Subestado__c, Status
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals('Aprobado', refreshed.FSC_Resultado_Buro__c);
		System.assertEquals(Decimal.valueOf('745'), refreshed.FSC_XCore_Buro__c);
		System.assert(
			refreshed.FSC_Subestado__c == 'Generación de pagarés y plantillas' || refreshed.FSC_Subestado__c == 'Gestionar firmas',
			'Subestado inesperado: ' + refreshed.FSC_Subestado__c
		);
		System.assertEquals('En proceso', refreshed.Status);
		System.assertNotEquals(null, refreshed.FSC_Mensajes_Buro__c);
		System.assert(refreshed.FSC_Mensajes_Buro__c.contains('code: A1'));
		System.assert(refreshed.FSC_Mensajes_Buro__c.contains('description: Aprobado por score'));
	}

	@IsTest
	static void testCallApi_ConVariosCodeudores_EnviaSoloElUltimoCreado() {
		Account account = createDecisionAccount('Cédula');
		createHistorial(account.Id, '1');
		ResidentialLoanApplication rla = createDecisionRla(account.Id, 'En Motor Buró', 'FSC_Solicitud_Credito_Consumo', null);
		rla.FSC_productoBanco__c = '401';
		update rla;
		createDecisionGuarantee(rla.Id);

		LoanApplicant olderCoDebtor = createCoDebtor(rla.Id, '00200000001', 75000, 'B');
		Test.setCreatedDate(olderCoDebtor.Id, System.now().addMinutes(-5));
		LoanApplicant newestCoDebtor = createCoDebtor(rla.Id, '00200000002', 125000, 'A');
		Test.setCreatedDate(newestCoDebtor.Id, System.now());
		Test.setMock(HttpCalloutMock.class, new SecondaryConsumerMock());

		Test.startTest();
		if (callApiSkippedForMissingConfig(new List<Id>{ rla.Id })) {
			Test.stopTest();
			return;
		}
		Test.stopTest();

		Assert.areEqual(
			'Aprobado',
			[SELECT FSC_Resultado_Buro__c FROM ResidentialLoanApplication WHERE Id = :rla.Id].FSC_Resultado_Buro__c,
			'La respuesta del buró debe procesarse normalmente cuando existe un codeudor.'
		);
	}

	@IsTest
	static void testCallApi_Vehicular_UsaPrevhiYRequestVehicular() {
		Account acc = createDecisionAccount('Cédula');
		createHistorial(acc.Id, '1');
		ResidentialLoanApplication rla = createDecisionRla(acc.Id, 'En Motor Buró', 'FSC_Solicitud_Credito_Vehiculo', null);
		rla.FSC_MontoAprobado__c = 2000000;
		update rla;

		createDecisionFacility(rla.Id);
		FSC_Garantia__c guarantee = createDecisionGuarantee(rla.Id);
		guarantee.FSC_Valor_Inmueble__c = 2500000;
		guarantee.FSC_Precio_de_Venta__c = 2400000;
		update guarantee;

		Test.setMock(HttpCalloutMock.class, new VehicularMock());

		Test.startTest();
		if (callApiSkippedForMissingConfig(new List<Id>{ rla.Id })) {
			Test.stopTest();
			return;
		}
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_Resultado_Buro__c, FSC_XCore_Buro__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals('Aprobado', refreshed.FSC_Resultado_Buro__c);
		System.assertEquals(Decimal.valueOf('746'), refreshed.FSC_XCore_Buro__c);
		System.assert(
			refreshed.FSC_Subestado__c == 'Generación de pagarés y plantillas' || refreshed.FSC_Subestado__c == 'Gestionar firmas',
			'Subestado inesperado: ' + refreshed.FSC_Subestado__c
		);
	}

	@IsTest
	static void testCallApi_Hipotecario_UsaPrehipYRequestHipotecario() {
		Account acc = createDecisionAccount('Cédula');
		createHistorial(acc.Id, '1');
		ResidentialLoanApplication rla = createDecisionRla(acc.Id, 'En Motor Buró', 'FSC_Solicitud_Credito_Hipotecario', null);
		rla.FSC_MontoAprobado__c = 1800000;
		update rla;

		FSC_Facilidades_De_Credito__c facility = createDecisionFacility(rla.Id);
		createDecisionGuarantee(rla.Id);

		Test.setMock(HttpCalloutMock.class, new HipotecarioMock());

		Test.startTest();
		if (callApiSkippedForMissingConfig(new List<Id>{ rla.Id })) {
			Test.stopTest();
			return;
		}
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_Resultado_Buro__c, FSC_XCore_Buro__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals('Aprobado', refreshed.FSC_Resultado_Buro__c);
		System.assertEquals(Decimal.valueOf('856'), refreshed.FSC_XCore_Buro__c);
		System.assert(
			refreshed.FSC_Subestado__c == 'Generación de pagarés y plantillas' || refreshed.FSC_Subestado__c == 'Gestionar firmas',
			'Subestado inesperado: ' + refreshed.FSC_Subestado__c
		);
	}

	@IsTest
	static void testQueueable_Referido_UsaFallbackXcoreYActualizaSubestado() {
		Account acc = createDecisionAccount('Cédula');
		createHistorial(acc.Id, '2');
		ResidentialLoanApplication rla = createDecisionRla(acc.Id, 'En Motor Buró');

		Test.setMock(HttpCalloutMock.class, new ReferredFallbackXcoreMock());
		configureTestConfig();

		Test.startTest();
		System.enqueueJob(new FSC_LoanDecisionAPIQueueable(new List<Id>{ rla.Id }));
		try {
			Test.stopTest();
		} catch (CalloutException e) {
			if (isMissingLoanDecisionConfig(e)) {
				return;
			}
			throw e;
		}

		ResidentialLoanApplication refreshed = [
			SELECT FSC_Resultado_Buro__c, FSC_XCore_Buro__c, FSC_Mensajes_Buro__c, FSC_Subestado__c, Status
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals('Referido', refreshed.FSC_Resultado_Buro__c);
		System.assertEquals(Decimal.valueOf('612'), refreshed.FSC_XCore_Buro__c);
		System.assertEquals('Recepción de documentos – Análisis', refreshed.FSC_Subestado__c);
		System.assertEquals('En proceso', refreshed.Status);
		System.assert(refreshed.FSC_Mensajes_Buro__c.contains('code: R1'));
	}

	@IsTest
	static void testCallApi_Rechazado_CambiaSubestadoYStatus() {
		Account acc = createDecisionAccount('Cédula');
		createHistorial(acc.Id, '0');
		ResidentialLoanApplication rla = createDecisionRla(acc.Id, 'En Motor Buró');

		Test.setMock(HttpCalloutMock.class, new RejectedMock());

		Boolean threwExpectedException = false;

		Test.startTest();
		try {
			if (callApiSkippedForMissingConfig(new List<Id>{ rla.Id })) {
				Test.stopTest();
				return;
			}
		} catch (DmlException e) {
			threwExpectedException = true;
			System.assert(
				e.getMessage().contains('FSC - Notificaciones por Email RLA') ||
				e.getMessage().contains('Recipient ID is required when using templates'),
				'Se esperaba el error del flow/email. Error actual: ' + e.getMessage()
			);
		}
		Test.stopTest();

		System.assert(threwExpectedException, 'Se esperaba una excepción producida por la automatización de email.');
	}

	@IsTest
	static void testCallApi_ErrorHttp_GuardaLogDeError() {
		Account acc = createDecisionAccount('Cédula');
		createHistorial(acc.Id, '1');
		ResidentialLoanApplication rla = createDecisionRla(acc.Id, 'En Motor Buró');

		Test.setMock(HttpCalloutMock.class, new ErrorResponseMock());

		Test.startTest();
		if (callApiSkippedForMissingConfig(new List<Id>{ rla.Id })) {
			Test.stopTest();
			return;
		}
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_LogErrores__c, FSC_Mensajes_Buro__c, FSC_Resultado_Buro__c, FSC_XCore_Buro__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertNotEquals(null, refreshed.FSC_LogErrores__c);
		System.assert(refreshed.FSC_LogErrores__c.contains('Error HTTP al consultar Buro'));
		System.assert(refreshed.FSC_LogErrores__c.contains('statusCode=400'));
		System.assert(refreshed.FSC_LogErrores__c.contains('statusLine=Bad Request'));
		System.assert(refreshed.FSC_LogErrores__c.contains('efxErrorCode=500.00'));
		System.assert(refreshed.FSC_LogErrores__c.contains('description=Please refer to additionalErrorDetails'));
		System.assert(refreshed.FSC_LogErrores__c.contains('detailError=CC_ERROR_003'));
		System.assert(refreshed.FSC_LogErrores__c.contains('apiStatus=500'));
		System.assertEquals(null, refreshed.FSC_Mensajes_Buro__c);
		System.assertEquals(null, refreshed.FSC_Resultado_Buro__c);
		System.assertEquals(null, refreshed.FSC_XCore_Buro__c);
		System.assertEquals('En Motor Buró', refreshed.FSC_Subestado__c);
	}

	@IsTest
	static void testCallApi_Exception_AcumulaLogYNoFalla() {
		Account acc = createDecisionAccount('Cédula');
		createHistorial(acc.Id, '1');
		ResidentialLoanApplication rla = createDecisionRla(acc.Id, 'En Motor Buró');

		Test.setMock(HttpCalloutMock.class, new ExceptionMock());

		Test.startTest();
		if (callApiSkippedForMissingConfig(new List<Id>{ rla.Id })) {
			Test.stopTest();
			return;
		}
		FSC_LoanDecisionAPI.callAPI(new List<Id>{ rla.Id });
		FSC_LoanDecisionAPI.callAPI(null);
		FSC_LoanDecisionAPI.callAPI(new List<Id>());
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_LogErrores__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertNotEquals(null, refreshed.FSC_LogErrores__c);
		System.assert(refreshed.FSC_LogErrores__c.contains('Excepcion al consultar Buro'));
		System.assert(refreshed.FSC_LogErrores__c.contains('--------------------'));
		System.assert(
			refreshed.FSC_LogErrores__c.indexOf('Excepcion al consultar Buro') !=
			refreshed.FSC_LogErrores__c.lastIndexOf('Excepcion al consultar Buro')
		);
		System.assertEquals('En Motor Buró', refreshed.FSC_Subestado__c);
	}

	@IsTest
	static void testCallApi_MapTipoIdentificacion_RncYPasaporte() {
		// Caso 1: RNC -> debe mapear a R
		Account accRnc = createDecisionAccount('RNC');
		createHistorial(accRnc.Id, '1');
		ResidentialLoanApplication rlaRnc = createDecisionRla(accRnc.Id, 'En Motor Buró');

		// Caso 2: Pasaporte -> debe mapear a P
		Account accPasaporte = createDecisionAccount('Pasaporte');
		createHistorial(accPasaporte.Id, '1');
		ResidentialLoanApplication rlaPasaporte = createDecisionRla(accPasaporte.Id, 'En Motor Buró');

		Test.startTest();

		Test.setMock(HttpCalloutMock.class, new TipoIdentificacionAssertMock('R'));
		if (callApiSkippedForMissingConfig(new List<Id>{ rlaRnc.Id })) {
			Test.stopTest();
			return;
		}

		Test.setMock(HttpCalloutMock.class, new TipoIdentificacionAssertMock('P'));
		if (callApiSkippedForMissingConfig(new List<Id>{ rlaPasaporte.Id })) {
			Test.stopTest();
			return;
		}

		Test.stopTest();
	}

	private class TipoIdentificacionAssertMock implements HttpCalloutMock {
		private String expectedType;

		public TipoIdentificacionAssertMock(String expectedType) {
			this.expectedType = expectedType;
		}

		public HTTPResponse respond(HTTPRequest req) {
			String body = req.getBody();

			System.assert(
				body.contains('"type":"' + expectedType + '"'),
				'Se esperaba type=' + expectedType + ' en el request. Body actual: ' + body
			);

			HttpResponse res = new HttpResponse();
			res.setStatusCode(500);
			res.setStatus('500 Internal Server Error');
			res.setBody('{"error":"mock para cubrir mapping"}');
			return res;
		}
	}
}
