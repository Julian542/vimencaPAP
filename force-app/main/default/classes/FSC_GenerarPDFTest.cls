@IsTest
private class FSC_GenerarPDFTest {
	private static final String TITLE_PREFIX = 'Crédito ';
	private static final String RT_CREDITO_CONSUMO = 'FSC_Solicitud_Credito_Consumo';
	private static final String RT_CREDITO_PYME = 'FSC_Solicitud_Credito_PYME';

	private static Id getNeutralAccountRecordTypeId() {
		Schema.RecordTypeInfo rtInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
			.get('Candidato_Persona_Juridica');

		return rtInfo == null ? null : rtInfo.getRecordTypeId();
	}

	private static Account buildNeutralAccount(String name, String documentNumber) {
		Account account = new Account(
			Name = name,
			ACC_NumIdentificacion__c = documentNumber,
			ACC_RNC__c = 'PDF' + String.valueOf(System.now().getTime()).right(6),
			ACC_Condicion__c = 'PROSPECTO',
			ACC_Estado__c = 'INICIADO',
			ACC_TipoIdentificacion__c = 'RNC'
		);
		Id recordTypeId = getNeutralAccountRecordTypeId();
		if (recordTypeId != null) {
			account.RecordTypeId = recordTypeId;
		}
		return account;
	}

	private static Id createParentId() {
		Account a = buildNeutralAccount('PDF Parent', '00108803610');
		insert a;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA PDF Parent',
			AccountId = a.Id,
			RecordTypeId = getResidentialLoanApplicationRecordTypeId(RT_CREDITO_CONSUMO),
			Status = 'En proceso',
			FSC_Subestado__c = 'Documentación para desembolso y firmas',
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401',
			FSC_UsuarioGestionPlanilla__c = UserInfo.getUserId()
		);
		insert rla;
		return rla.Id;
	}

	private static Id getResidentialLoanApplicationRecordTypeId(String developerName) {
		Schema.RecordTypeInfo rtInfo = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName().get(developerName);

		return rtInfo == null ? null : rtInfo.getRecordTypeId();
	}

	private static ResidentialLoanApplication createLoanApplication(
		String firstName,
		String lastName,
		String documentNumber,
		String rlaName,
		String recordTypeDeveloperName
	) {
		Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
		Account account = new Account();
		Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
			.get('PersonAccount')
			.getRecordTypeId();
		account.RecordTypeId = personAccountRecordTypeId;
		account.FirstName = firstName;
		account.LastName = lastName;
		account.ACC_NumIdentificacion__c = documentNumber;
		account.ACC_TipoIdentificacion__c = 'Cédula';
		account.FinServ__IndividualId__c = documentNumber;
		account.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
		account.PersonBirthdate = Date.newInstance(2000, 1, 1);
		account.ACC_Genero__c = 'FEMENINO';
		account.ACC_Estado_Civil__c = 'SOLTERO/A';
		insert account;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = rlaName,
			AccountId = account.Id,
			RecordTypeId = getResidentialLoanApplicationRecordTypeId(recordTypeDeveloperName),
			Status = 'En proceso',
			FSC_Subestado__c = 'Documentación para desembolso y firmas',
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401',
			FSC_UsuarioGestionPlanilla__c = UserInfo.getUserId()
		);
		insert rla;
		return rla;
	}

	private static Id createLinkedDocument(Id linkedEntityId, String title, String pathOnClient) {
		ContentVersion cv = new ContentVersion(
			Title = title,
			PathOnClient = pathOnClient,
			VersionData = Blob.valueOf('OLD_PDF'),
			FirstPublishLocationId = linkedEntityId,
			FSC_EnviarDocumento__c = true
		);
		insert cv;

		return [
			SELECT ContentDocumentId
			FROM ContentVersion
			WHERE Id = :cv.Id
			LIMIT 1
		]
		.ContentDocumentId;
	}

	@IsTest
	static void testInvokeMethod_GenerarPDFPlanillaDesembolso_Success() {
		Id parentId = createParentId();
		String formulaCedula = '001-0000000-0';

		Map<String, Object> input = new Map<String, Object>{
			'Id' => parentId,
			'FormulaFecha' => '2027-01-31T03:00:00.000Z',
			'FormulaCedula' => formulaCedula
		};

		Map<String, Object> output = new Map<String, Object>();
		Map<String, Object> options = new Map<String, Object>();

		Test.startTest();
		Boolean ok = new FSC_GenerarPDF().invokeMethod('generarPDFPlanillaDesembolso', input, output, options);
		Test.stopTest();

		System.assertEquals(true, ok);
		System.assertEquals(true, (Boolean) output.get('success'));

		Id contentVersionId = (Id) output.get('contentVersionId');
		Id contentDocumentId = (Id) output.get('contentDocumentId');
		Id linkId = (Id) output.get('contentDocumentLinkId');

		System.assertNotEquals(null, contentVersionId);
		System.assertNotEquals(null, contentDocumentId);
		System.assertNotEquals(null, linkId);

		ContentVersion cv = [
			SELECT Id, Title, ContentDocumentId
			FROM ContentVersion
			WHERE Id = :contentVersionId
			LIMIT 1
		];
		System.assertEquals('Hoja de desembolso - ' + formulaCedula + ' - ' + DateTime.now().format('dd-MM-yyyy HH:mm'), cv.Title);
		System.assertEquals(contentDocumentId, cv.ContentDocumentId);

		ContentDocumentLink cdl = [
			SELECT Id, ContentDocumentId, LinkedEntityId, ShareType, Visibility
			FROM ContentDocumentLink
			WHERE Id = :linkId
			LIMIT 1
		];
		System.assertEquals(parentId, cdl.LinkedEntityId);
		System.assertEquals(contentDocumentId, cdl.ContentDocumentId);
		System.assertEquals('V', cdl.ShareType);
		System.assertEquals('InternalUsers', cdl.Visibility);
	}

	@IsTest
	static void testInvokeMethod_GenerarPDFPlanillaDesembolso_HydratesTasaFijaPorFromRla() {
		ResidentialLoanApplication rla = createLoanApplication('Ana', 'Perez', '00199999999', 'RLA Desembolso', RT_CREDITO_CONSUMO);
		rla.FSC_TasaFijaPorMeses__c = 13;
		rla.FSC_TasaInteres__c = 12.5;
		update rla;

		Map<String, Object> input = new Map<String, Object>{
			'Id' => rla.Id,
			'FormulaFecha' => '2027-01-31T03:00:00.000Z',
			'FormulaCedula' => '001-9999999-9'
		};

		Map<String, Object> output = new Map<String, Object>();

		Test.startTest();
		Boolean ok = new FSC_GenerarPDF().invokeMethod('generarPDFPlanillaDesembolso', input, output, new Map<String, Object>());
		Test.stopTest();

		System.assertEquals(true, ok);
		System.assertEquals(true, (Boolean) output.get('success'));
	}

	@IsTest
	static void testInvokeMethod_UnknownMethod() {
		Map<String, Object> output = new Map<String, Object>();

		Boolean ok = new FSC_GenerarPDF().invokeMethod('metodoInexistente', new Map<String, Object>(), output, new Map<String, Object>());

		System.assertEquals(false, ok);
		System.assertEquals(false, (Boolean) output.get('success'));
		System.assert(((String) output.get('message')).contains('Unknown methodName'));
	}

	@IsTest
	static void testInvokeMethod_MissingMethodName() {
		Map<String, Object> output = new Map<String, Object>();

		Boolean ok = new FSC_GenerarPDF().invokeMethod(null, new Map<String, Object>(), output, new Map<String, Object>());

		System.assertEquals(false, ok);
		System.assertEquals(false, (Boolean) output.get('success'));
	}

	@IsTest
	static void testInvokeMethod_MissingId() {
		Map<String, Object> output = new Map<String, Object>();

		Boolean ok = new FSC_GenerarPDF()
			.invokeMethod(
				'generarPDFPlanillaDesembolso',
				new Map<String, Object>{ 'FormulaFecha' => '2027-01-31T03:00:00.000Z' },
				output,
				new Map<String, Object>()
			);

		System.assertEquals(false, ok);
		System.assertEquals(false, (Boolean) output.get('success'));
	}

	@IsTest
	static void testCallableInterface_RoutesToInvokeMethod() {
		Id parentId = createParentId();

		Map<String, Object> input = new Map<String, Object>{ 'Id' => parentId, 'FormulaFecha' => '2027-01-31T03:00:00.000Z' };

		Map<String, Object> output = new Map<String, Object>();
		Map<String, Object> args = new Map<String, Object>{ 'input' => input, 'output' => output, 'options' => new Map<String, Object>() };

		Test.startTest();
		Object ret = new FSC_GenerarPDF().call('generarPDFPlanillaDesembolso', args);
		Test.stopTest();

		Map<String, Object> out = (Map<String, Object>) ret;
		System.assertEquals(true, (Boolean) out.get('success'));
		System.assertNotEquals(null, (Id) out.get('contentDocumentId'));
	}

	@IsTest
	static void testInvokeMethod_RegenerarPDFSolicitudCredito_Consumo() {
		ResidentialLoanApplication rla = createLoanApplication('Joel', 'Valenti', '42010242', 'RLA Consumo', RT_CREDITO_CONSUMO);
		String expectedTitle = TITLE_PREFIX + 'Consumo - Joel Valenti - 42010242';
		Id previousDocumentId = createLinkedDocument(rla.Id, expectedTitle, 'credito-consumo-old.pdf');
		createLinkedDocument(rla.Id, 'Documento sin borrar', 'otro-documento.pdf');

		Map<String, Object> output = new Map<String, Object>();

		Test.startTest();
		Boolean ok = new FSC_GenerarPDF()
			.invokeMethod('regenerarPDFSolicitudCredito', new Map<String, Object>{ 'Id' => rla.Id }, output, new Map<String, Object>());
		Test.stopTest();

		System.assertEquals(true, ok);
		System.assertEquals(true, (Boolean) output.get('success'));
		System.assertEquals(expectedTitle, (String) output.get('title'));
		System.assertEquals(1, (Integer) output.get('deletedDocumentCount'));
		System.assertEquals(0, [SELECT COUNT() FROM ContentDocument WHERE Id = :previousDocumentId]);

		Id newDocumentId = (Id) output.get('ContentDocumentId');
		System.assertNotEquals(null, newDocumentId);
		System.assertNotEquals(previousDocumentId, newDocumentId);
		System.assertEquals(
			1,
			[
				SELECT COUNT()
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :rla.Id AND ContentDocument.Title = :expectedTitle
			]
		);
		System.assertEquals(
			1,
			[
				SELECT COUNT()
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :rla.Id AND ContentDocument.Title = 'Documento sin borrar'
			]
		);
	}

	@IsTest
	static void testInvokeMethod_RegenerarPDFSolicitudCredito_Pyme() {
		ResidentialLoanApplication rla = createLoanApplication('Maria', 'Gomez', '00112345678', 'RLA PyMe', RT_CREDITO_PYME);
		String expectedTitle = TITLE_PREFIX + 'PyMe - Maria Gomez - 00112345678';
		Id previousDocumentId = createLinkedDocument(rla.Id, expectedTitle, 'credito-pyme-old.pdf');

		Map<String, Object> output = new Map<String, Object>();

		Test.startTest();
		Boolean ok = new FSC_GenerarPDF()
			.invokeMethod('regenerarPDFSolicitudCredito', new Map<String, Object>{ 'Id' => rla.Id }, output, new Map<String, Object>());
		Test.stopTest();

		System.assertEquals(true, ok);
		System.assertEquals(true, (Boolean) output.get('success'));
		System.assertEquals(expectedTitle, (String) output.get('title'));
		System.assertEquals(1, (Integer) output.get('deletedDocumentCount'));
		System.assertEquals(0, [SELECT COUNT() FROM ContentDocument WHERE Id = :previousDocumentId]);

		Id newDocumentId = (Id) output.get('ContentDocumentId');
		System.assertNotEquals(null, newDocumentId);
		System.assertNotEquals(previousDocumentId, newDocumentId);
		System.assertEquals(
			1,
			[
				SELECT COUNT()
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :rla.Id AND ContentDocument.Title = :expectedTitle
			]
		);
	}
}
