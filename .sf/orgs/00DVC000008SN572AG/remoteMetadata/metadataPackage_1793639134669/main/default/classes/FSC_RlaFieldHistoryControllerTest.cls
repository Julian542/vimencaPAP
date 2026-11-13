@IsTest
private class FSC_RlaFieldHistoryControllerTest {
	private static Id getRecordTypeId(String developerName) {
		Map<String, Schema.RecordTypeInfo> rtMap = ResidentialLoanApplication.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
		return rtMap != null && rtMap.containsKey(developerName) ? rtMap.get(developerName).getRecordTypeId() : null;
	}

	private static ResidentialLoanApplication createRla() {
		Account acc = new Account(Name = 'Cuenta History ' + System.now().getTime(), ACC_NumIdentificacion__c = '00108803610');
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
		completarCamposObligatoriosUsuario(newOwner);
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

	@IsTest
	static void testBuildHistoryRow_ConvierteValores() {
		Map<String, Schema.SObjectField> fields = ResidentialLoanApplication.SObjectType.getDescribe().fields.getMap();
		Datetime changedAt = Datetime.newInstance(2026, 1, 2, 10, 30, 0);

		FSC_RlaFieldHistoryController.HistoryRow knownField = FSC_RlaFieldHistoryController.buildHistoryRow(
			null,
			'Status',
			Date.newInstance(2026, 1, 1),
			changedAt,
			changedAt,
			'Usuario Test',
			fields
		);
		FSC_RlaFieldHistoryController.HistoryRow unknownField = FSC_RlaFieldHistoryController.buildHistoryRow(
			null,
			'CampoInexistente__c',
			Time.newInstance(10, 30, 0, 0),
			null,
			changedAt,
			null,
			fields
		);

		System.assertNotEquals(null, knownField.fieldLabel);
		System.assertEquals(true, knownField.hasChanged);
		System.assertEquals('CampoInexistente__c', unknownField.fieldLabel);
	}

	@IsTest
	static void testBuildHistoryRows_FiltraCamposTecnicos() {
		Datetime changedAt = Datetime.newInstance(2026, 1, 2, 10, 30, 0);
		FSC_RlaFieldHistoryController.HistorySource statusHistory = new FSC_RlaFieldHistoryController.HistorySource(
			null,
			'Status',
			'Anterior',
			'Nuevo',
			changedAt,
			'Usuario Test'
		);
		FSC_RlaFieldHistoryController.HistorySource lockedHistory = new FSC_RlaFieldHistoryController.HistorySource(
			null,
			'Locked',
			null,
			null,
			changedAt,
			null
		);
		List<FSC_RlaFieldHistoryController.HistoryRow> rows = FSC_RlaFieldHistoryController.buildHistoryRows(
			new List<FSC_RlaFieldHistoryController.HistorySource>{ statusHistory, lockedHistory },
			ResidentialLoanApplication.SObjectType.getDescribe().fields.getMap()
		);

		System.assertEquals(1, rows.size());
		System.assertEquals('Status', rows[0].fieldApiName);
		System.assertEquals(true, rows[0].hasChanged);
	}

	// La org exige Oficina, Codigo y Canal de Atencion en todo usuario (regla Validar_Campos_Obligatorios_Usuario).
	private static void completarCamposObligatoriosUsuario(User usuario) {
		Map<String, Schema.SObjectField> campos = Schema.SObjectType.User.fields.getMap();
		for (String campo : new List<String>{ 'USE_Oficina__c', 'Canal_Atencion__c' }) {
			if (!campos.containsKey(campo)) {
				continue;
			}
			for (Schema.PicklistEntry valor : campos.get(campo).getDescribe().getPicklistValues()) {
				if (valor.isActive()) {
					usuario.put(campo, valor.getValue());
					break;
				}
			}
		}
		if (campos.containsKey('USE_Codigo__c')) {
			usuario.put('USE_Codigo__c', 'TEST');
		}
		if (campos.containsKey('USE_Oficina__c')) {
			asegurarOficinaEnDatosMaestros((String) usuario.get('USE_Oficina__c'));
		}
	}

	// El flow "Información usuario" busca la oficina del usuario en Datos_Maestros__c y falla si no existe.
	private static void asegurarOficinaEnDatosMaestros(String oficina) {
		if (String.isBlank(oficina) || [SELECT COUNT() FROM Datos_Maestros__c WHERE DM_Codigo_Oficina__c = :oficina AND DM_Tipo__c = 'Oficina'] > 0) {
			return;
		}
		System.runAs(new User(Id = UserInfo.getUserId())) {
			insert new Datos_Maestros__c(Name = 'Oficina test ' + oficina, DM_Codigo_Oficina__c = oficina, DM_Tipo__c = 'Oficina');
		}
	}
}