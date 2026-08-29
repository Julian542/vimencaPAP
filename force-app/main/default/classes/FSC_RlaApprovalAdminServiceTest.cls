@IsTest
private class FSC_RlaApprovalAdminServiceTest {
	private static final String SUBESTADO_ANALISIS = 'An\u00E1lisis de cr\u00E9dito';

	private static Account buildNeutralAccount() {
		Account acc = new Account();
		acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
		acc.Name = 'Cuenta Service ' + System.now().getTime();
		acc.ACC_RNC__c = 'RNCSERVICE001';
		acc.ACC_NumIdentificacion__c = '00108803610';
		acc.ACC_Condicion__c = 'PROSPECTO';
		acc.ACC_Estado__c = 'INICIADO';
		acc.ACC_TipoIdentificacion__c = 'RNC';
		return acc;
	}

	private static ResidentialLoanApplication createRla() {
		Account acc = buildNeutralAccount();
		insert acc;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Service ' + System.now().getTime(),
			AccountId = acc.Id,
			RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
				.get('FSC_Solicitud_Credito_Consumo')
				.getRecordTypeId(),
			Status = 'En proceso',
			FSC_Subestado__c = SUBESTADO_ANALISIS,
			FSC_ActoNumeroPagare__c = 'ACTSERV',
			FSC_Pagares_y_Plantillas_Generados__c = false,
			FSC_Monto__c = 5000,
			FSC_Plazo_meses__c = '24',
			FSC_TasaInteres__c = 14,
			FSC_Aprobado_con_Condiciones__c = false,
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401'
		);
		insert rla;
		return rla;
	}

	@IsTest
	static void sendToSupervisor_marksFlagWhenNoWorkitems() {
		ResidentialLoanApplication rla = createRla();

		Test.startTest();
		FSC_RlaApprovalAdminService.sendToSupervisor(rla.Id);
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_DebeRevisarSupervisor__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals(true, refreshed.FSC_DebeRevisarSupervisor__c);
	}

	@IsTest
	static void returnToAnalyst_updatesFieldsWhenNoWorkitems() {
		ResidentialLoanApplication rla = createRla();
		update new ResidentialLoanApplication(Id = rla.Id, FSC_DebeRevisarSupervisor__c = true);

		Test.startTest();
		FSC_RlaApprovalAdminService.returnToAnalyst(rla.Id, 'devolver a analista');
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_DebeRevisarSupervisor__c, FSC_ObservacionSupervisor__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals(false, refreshed.FSC_DebeRevisarSupervisor__c);
		System.assertEquals('devolver a analista', refreshed.FSC_ObservacionSupervisor__c);
	}

	@IsTest
	static void returnToBusiness_updatesFieldsWhenNoWorkitems() {
		ResidentialLoanApplication rla = createRla();
		update new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_DebeRevisarSupervisor__c = true,
			FSC_DebeRevisarComite__c = true,
			FSC_Doc_Completa_Analisis__c = true
		);

		Test.startTest();
		FSC_RlaApprovalAdminService.returnToBusiness(rla.Id, 'devolver a oficial', 'Supervisor');
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT
				FSC_DebeRevisarSupervisor__c,
				FSC_DebeRevisarComite__c,
				FSC_Doc_Completa_Analisis__c,
				FSC_Subestado__c,
				FSC_ObservacionSupervisor__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals(false, refreshed.FSC_DebeRevisarSupervisor__c);
		System.assertEquals(false, refreshed.FSC_DebeRevisarComite__c);
		System.assertEquals(false, refreshed.FSC_Doc_Completa_Analisis__c);
		System.assertEquals('Recepción de documentos – Análisis', refreshed.FSC_Subestado__c);
		System.assertEquals('devolver a oficial', refreshed.FSC_ObservacionSupervisor__c);
	}

	@IsTest
	static void isRecallPermissionIssue_detectsPermissionMessages() {
		System.assertEquals(
			true,
			FSC_RlaApprovalAdminService.isRecallPermissionIssue('INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY: cannot recall approval request')
		);
		System.assertEquals(false, FSC_RlaApprovalAdminService.isRecallPermissionIssue('No se encontro workitem activo'));
	}

	@IsTest
	static void sendToSupervisor_throwsWhenIdIsNull() {
		Boolean thrown = false;

		Test.startTest();
		try {
			FSC_RlaApprovalAdminService.sendToSupervisor(null);
		} catch (AuraHandledException ex) {
			thrown = true;
		}
		Test.stopTest();

		System.assertEquals(true, thrown);
	}

	@IsTest
	static void returnToAnalyst_validatesInputs() {
		Boolean thrown = false;
		String longMotivo = '';
		for (Integer i = 0; i < 256; i++) {
			longMotivo += 'x';
		}

		try {
			FSC_RlaApprovalAdminService.returnToAnalyst(null, 'x');
		} catch (AuraHandledException ex) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaApprovalAdminService.returnToAnalyst(UserInfo.getUserId(), '');
		} catch (AuraHandledException ex) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		Test.startTest();
		try {
			FSC_RlaApprovalAdminService.returnToAnalyst(UserInfo.getUserId(), longMotivo);
		} catch (AuraHandledException ex) {
			thrown = true;
		}
		Test.stopTest();
		System.assertEquals(true, thrown);
	}

	@IsTest
	static void returnToBusiness_validatesInputs() {
		Boolean thrown = false;
		String longMotivo = '';
		for (Integer i = 0; i < 256; i++) {
			longMotivo += 'x';
		}

		try {
			FSC_RlaApprovalAdminService.returnToBusiness(null, 'x', 'Supervisor');
		} catch (AuraHandledException ex) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaApprovalAdminService.returnToBusiness(UserInfo.getUserId(), '', 'Supervisor');
		} catch (AuraHandledException ex) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		Test.startTest();
		try {
			FSC_RlaApprovalAdminService.returnToBusiness(UserInfo.getUserId(), longMotivo, 'Supervisor');
		} catch (AuraHandledException ex) {
			thrown = true;
		}
		Test.stopTest();
		System.assertEquals(true, thrown);
	}

	@IsTest
	static void buildRecallFailure_returnsDefaultException() {
		AuraHandledException ex = FSC_RlaApprovalAdminService.buildRecallFailure(null);
		System.assertNotEquals(null, ex);
	}

	@IsTest
	static void removeWorkItem_throwsDefaultErrorWhenForced() {
		Boolean thrown = false;
		FSC_RlaApprovalAdminService.testForceRemoveFailure = true;

		Test.startTest();
		try {
			FSC_RlaApprovalAdminService.removeWorkItem(UserInfo.getUserId());
		} catch (AuraHandledException ex) {
			thrown = true;
			System.assertNotEquals(null, ex);
		}
		Test.stopTest();

		FSC_RlaApprovalAdminService.testForceRemoveFailure = false;
		System.assertEquals(true, thrown);
	}
}
