@IsTest
private class FSC_RlaApprovalAdminDecisionRestTest {
	private static final String SUBESTADO_ANALISIS = 'Análisis de crédito';
	private static final String ENDPOINT = '/services/apexrest/fsc/rla-approval-admin/client-decision';

	private static ResidentialLoanApplication createRla() {
		Account acc = new Account(Name = 'Cuenta Decision ' + System.now().getTime(), ACC_NumIdentificacion__c = '00108803610');
		insert acc;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Decision ' + System.now().getTime(),
			AccountId = acc.Id,
			RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
				.get('FSC_Solicitud_Credito_Consumo')
				.getRecordTypeId(),
			Status = 'En proceso',
			FSC_Subestado__c = SUBESTADO_ANALISIS,
			FSC_ActoNumeroPagare__c = 'ACTDEC',
			FSC_Pagares_y_Plantillas_Generados__c = false,
			FSC_Monto__c = 5000,
			FSC_Plazo_meses__c = '24',
			FSC_TasaInteres__c = 14,
			FSC_Aprobado_con_Condiciones__c = true,
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401'
		);
		insert rla;
		return rla;
	}

	private static void prepararRequest(String body) {
		RestContext.request = new RestRequest();
		RestContext.request.requestUri = ENDPOINT;
		RestContext.request.httpMethod = 'POST';
		RestContext.request.requestBody = Blob.valueOf(body);
		RestContext.response = new RestResponse();
	}

	@IsTest
	static void registrarDecisionCliente_rechazoCierraSolicitud() {
		ResidentialLoanApplication rla = createRla();
		prepararRequest('{"residentialLoanApplicationId":"' + rla.Id + '","accion":"RECHAZA","comentarioAuditoria":"Ejecutado por: Oficial"}');

		Test.startTest();
		FSC_RlaApprovalAdminDecisionRest.registrarDecisionCliente();
		Test.stopTest();

		ResidentialLoanApplication refreshed = [SELECT Status, FSC_Subestado__c FROM ResidentialLoanApplication WHERE Id = :rla.Id];
		System.assertEquals(200, RestContext.response.statusCode);
		System.assertEquals('Cerrada Perdida', refreshed.Status);
		System.assertEquals('Rechazada por cliente', refreshed.FSC_Subestado__c);
	}

	@IsTest
	static void registrarDecisionCliente_aceptaPasaAGeneracionDePagares() {
		ResidentialLoanApplication rla = createRla();
		prepararRequest('{"residentialLoanApplicationId":"' + rla.Id + '","accion":"ACEPTA","comentarioAuditoria":"Ejecutado por: Oficial"}');

		Test.startTest();
		FSC_RlaApprovalAdminDecisionRest.registrarDecisionCliente();
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_Subestado__c, FSC_SolicitudAprobadaPorComite__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertEquals(200, RestContext.response.statusCode, RestContext.response.responseBody.toString());
		System.assertEquals('Generación de pagarés y plantillas', refreshed.FSC_Subestado__c);
		System.assertEquals(true, refreshed.FSC_SolicitudAprobadaPorComite__c);
	}

	@IsTest
	static void registrarDecisionCliente_badRequestSinSolicitud() {
		prepararRequest('{"accion":"ACEPTA"}');

		Test.startTest();
		FSC_RlaApprovalAdminDecisionRest.registrarDecisionCliente();
		Test.stopTest();

		System.assertEquals(400, RestContext.response.statusCode);
		System.assert(RestContext.response.responseBody.toString().contains('Solicitud requerida'));
	}

	@IsTest
	static void registrarDecisionCliente_badRequestAccionInvalida() {
		ResidentialLoanApplication rla = createRla();
		prepararRequest('{"residentialLoanApplicationId":"' + rla.Id + '","accion":"OTRA"}');

		Test.startTest();
		FSC_RlaApprovalAdminDecisionRest.registrarDecisionCliente();
		Test.stopTest();

		System.assertEquals(400, RestContext.response.statusCode);
		System.assert(RestContext.response.responseBody.toString().contains('"success":false'));
	}

	@IsTest
	static void registrarDecisionCliente_errorServidorConJsonInvalido() {
		prepararRequest('{');

		Test.startTest();
		FSC_RlaApprovalAdminDecisionRest.registrarDecisionCliente();
		Test.stopTest();

		System.assertEquals(500, RestContext.response.statusCode);
		System.assert(RestContext.response.responseBody.toString().contains('"success":false'));
	}
}