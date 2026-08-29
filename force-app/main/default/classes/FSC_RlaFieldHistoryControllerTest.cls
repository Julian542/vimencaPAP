@IsTest
private class FSC_RlaFieldHistoryControllerTest {
	private static Id getRecordTypeId(String developerName) {
		Map<String, Schema.RecordTypeInfo> rtMap = ResidentialLoanApplication.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
		return rtMap != null && rtMap.containsKey(developerName) ? rtMap.get(developerName).getRecordTypeId() : null;
	}

	private static Account buildNeutralAccount() {
		return new Account(
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
				.get('Candidato_Persona_Juridica')
				.getRecordTypeId(),
			Name = 'Cuenta History ' + System.now().getTime(),
			ACC_NumIdentificacion__c = '00108803610',
			ACC_RNC__c = 'HIST' + String.valueOf(System.now().getTime()).right(6),
			ACC_Condicion__c = 'PROSPECTO',
			ACC_Estado__c = 'INICIADO',
			ACC_TipoIdentificacion__c = 'RNC'
		);
	}

	private static ResidentialLoanApplication createRla() {
		Account acc = buildNeutralAccount();
		insert acc;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA History',
			AccountId = acc.Id,
			RecordTypeId = getRecordTypeId('FSC_Solicitud_Credito_Consumo'),
			Status = 'En proceso',
			FSC_Subestado__c = 'Documentación para desembolso y firmas',
			FSC_TipoSolicitud__c = 'BPR',
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401'
		);
		insert rla;
		return rla;
	}

	@IsTest
	static void testGetHistory_RecordIdNull() {
		Boolean thrown = false;

		try {
			FSC_RlaFieldHistoryController.getHistory(null, 10);
		} catch (AuraHandledException e) {
			thrown = true;
		}

		System.assertEquals(true, thrown);
	}

	@IsTest
	static void testGetHistory_SinRegistro() {
		ResidentialLoanApplication rla = createRla();
		Id deletedId = rla.Id;
		delete rla;

		List<FSC_RlaFieldHistoryController.HistoryRow> rows = FSC_RlaFieldHistoryController.getHistory(deletedId, 10);

		System.assertEquals(0, rows.size());
	}

	@IsTest
	static void testGetHistory_SinHistorial() {
		ResidentialLoanApplication rla = createRla();

		List<FSC_RlaFieldHistoryController.HistoryRow> rows = FSC_RlaFieldHistoryController.getHistory(rla.Id, 999);

		System.assertEquals(0, rows.size());
	}

	@IsTest
	static void testGetHistory_ConCambios() {
		ResidentialLoanApplication rla = createRla();
		Profile currentProfile = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
		User newOwner = new User(
			FirstName = 'Owner',
			LastName = 'History',
			Alias = 'ownhist',
			Email = 'owner.history@test.com',
			Username = 'owner.history.' + System.now().getTime() + '@test.com',
			CommunityNickname = 'ownerhist' + String.valueOf(System.now().getTime()),
			TimeZoneSidKey = 'America/Argentina/Buenos_Aires',
			LocaleSidKey = 'es_AR',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'es',
			ProfileId = currentProfile.Id
		);
		insert newOwner;

		update new ResidentialLoanApplication(Id = rla.Id, OwnerId = newOwner.Id);

		Test.startTest();
		List<FSC_RlaFieldHistoryController.HistoryRow> rows = FSC_RlaFieldHistoryController.getHistory(rla.Id, 20);
		Test.stopTest();

		System.assertNotEquals(null, rows);
	}

	@IsTest(SeeAllData=true)
	static void testGetHistory_ConDatosRealesSandbox() {
		List<ResidentialLoanApplicationHistory> histories = [
			SELECT ResidentialLoanApplicationId
			FROM ResidentialLoanApplicationHistory
			LIMIT 1
		];

		if (histories.isEmpty()) {
			return;
		}

		List<FSC_RlaFieldHistoryController.HistoryRow> rows = FSC_RlaFieldHistoryController.getHistory(histories[0].ResidentialLoanApplicationId, 20);

		System.assert(rows.size() > 0, 'Debe retornar historial real de la sandbox.');
		System.assertNotEquals(null, rows[0].fieldApiName);
	}
}
