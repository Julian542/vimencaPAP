@IsTest
private class FSC_GenerarPDFTest {
	private static final String TITLE_PREFIX = 'Crédito ';
	private static final String RT_CREDITO_CONSUMO = 'FSC_Solicitud_Credito_Consumo';
	private static final String RT_CREDITO_PYME = 'FSC_Solicitud_Credito_PYME';
	private static final String RT_CREDITO_VEHICULO = 'FSC_Solicitud_Credito_Vehiculo';
	private static final String RT_CREDITO_HIPOTECARIO = 'FSC_Solicitud_Credito_Hipotecario';
	private static final String DOC_TIPO_PYME = 'PyMe';
	private static final String DOC_TIPO_CONSUMO = 'Consumo';
	private static final String DOC_TIPO_VEHICULO = 'Vehiculo';
	private static final String DOC_TIPO_HIPOTECARIO = 'Hipotecario';
	private static final String METHOD_GENERAR_PDF_PLANILLA_DESEMBOLSO = 'generarPDFPlanillaDesembolso';
	private static final String METHOD_GENERAR_PDF_SOLICITUD_PYME = 'generarPDFSolicitudPYME';
	private static final String METHOD_GENERAR_PDF_SOLICITUD_CONSUMO = 'generarPDFSolicitudConsumo';
	private static final String METHOD_REGENERAR_PDF_SOLICITUD_CREDITO = 'regenerarPDFSolicitudCredito';

	@TestSetup
	static void setupSolicitudFixture() {
		createLoanApplication('Ana', 'Perez', '00123456789', 'RLA Unicidad', RT_CREDITO_CONSUMO);
	}

	@IsTest
	static void shouldReplaceAllDuplicates_WhenGeneratingPyme() {
		verifyUniqueSolicitud(RT_CREDITO_PYME, DOC_TIPO_PYME, METHOD_GENERAR_PDF_SOLICITUD_PYME);
	}

	@IsTest
	static void shouldReplaceAllDuplicates_WhenGeneratingConsumo() {
		verifyUniqueSolicitud(RT_CREDITO_CONSUMO, DOC_TIPO_CONSUMO, METHOD_GENERAR_PDF_SOLICITUD_CONSUMO);
	}

	@IsTest
	static void shouldReplaceAllDuplicates_WhenGeneratingVehiculo() {
		verifyUniqueSolicitud(RT_CREDITO_VEHICULO, DOC_TIPO_VEHICULO, METHOD_GENERAR_PDF_SOLICITUD_CONSUMO);
	}

	@IsTest
	static void shouldReplaceAllDuplicates_WhenGeneratingHipotecario() {
		verifyUniqueSolicitud(RT_CREDITO_HIPOTECARIO, DOC_TIPO_HIPOTECARIO, METHOD_GENERAR_PDF_SOLICITUD_CONSUMO);
	}

	private static void verifyUniqueSolicitud(String recordTypeName, String creditLabel, String methodName) {
		ResidentialLoanApplication application = [SELECT Id, AccountId FROM ResidentialLoanApplication WHERE Name = 'RLA Unicidad'];
		application.RecordTypeId = getResidentialLoanApplicationRecordTypeId(recordTypeName);
		update application;
		String expectedTitle = TITLE_PREFIX + creditLabel + ' - Ana Perez - 00123456789';
		Id wrongDocument = createLinkedDocument(application.Id, TITLE_PREFIX + creditLabel + ' - Ana Perez - 99999999999', 'wrong.pdf');
		Id correctDocument = createLinkedDocument(application.Id, expectedTitle, 'correct.pdf');
		Id legacyDocument = createLinkedDocument(application.Id, '(' + TITLE_PREFIX + 'PyMe - Ana Perez - 88888888888)', 'legacy.pdf');
		Id unrelatedDocument = createLinkedDocument(application.Id, 'Documento sin borrar', 'other.pdf');
		Map<String, Object> output = new Map<String, Object>();
		FSC_GenerarPDF generator = new FSC_GenerarPDF();
		Test.startTest();
		Assert.isTrue(
			generator.invokeMethod(
				methodName,
				new Map<String, Object>{ 'Id' => application.Id, 'Title' => 'Identificacion incorrecta' },
				output,
				null
			),
			'La generacion debe funcionar'
		);
		Assert.areEqual(3, output.get('deletedDocumentCount'), 'Debe eliminar correctos, incorrectos y legacy simultaneamente');
		Assert.isTrue(
			generator.invokeMethod(METHOD_REGENERAR_PDF_SOLICITUD_CREDITO, new Map<String, Object>{ 'Id' => application.Id }, output, null),
			'El reintento debe funcionar'
		);
		FSC_GenerarPDF.validarSolicitudParaFirma(application.Id);
		Test.stopTest();
		Set<Id> removedIds = new Set<Id>{ wrongDocument, correctDocument, legacyDocument };
		Assert.areEqual(0, [SELECT COUNT() FROM ContentDocument WHERE Id IN :removedIds], 'No deben sobrevivir archivos anteriores');
		Assert.areEqual(
			2,
			[SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :application.Id],
			'Solo deben quedar la planilla y el otro documento'
		);
		Assert.areEqual(1, [SELECT COUNT() FROM ContentDocument WHERE Id = :unrelatedDocument], 'Debe conservar documentos ajenos a la planilla');
		Id versionId = (Id) output.get('ContentVersionId');
		ContentVersion version = [SELECT Title, FSC_ClaveTecnicaPrecarga__c FROM ContentVersion WHERE Id = :versionId];
		Assert.areEqual(expectedTitle, version.Title, 'El titulo debe usar exactamente la identificacion de la Account');
		Assert.areEqual(
			FSC_ChecklistDocsPrecargaService.SOLICITUD_CREDITO,
			version.FSC_ClaveTecnicaPrecarga__c,
			'La planilla debe conservar su clasificacion tecnica'
		);
	}

	@IsTest
	static void shouldRejectSignature_WhenDuplicatesExist() {
		ResidentialLoanApplication application = [SELECT Id FROM ResidentialLoanApplication WHERE Name = 'RLA Unicidad'];
		createLinkedDocument(application.Id, TITLE_PREFIX + 'Consumo - Ana Perez - 00123456789', 'first.pdf');
		createLinkedDocument(application.Id, TITLE_PREFIX + 'Consumo - Ana Perez - 99999999999', 'second.pdf');
		Test.startTest();
		try {
			FSC_GenerarPDF.validarSolicitudParaFirma(application.Id);
			Assert.fail('La firma debe bloquearse cuando hay dos planillas');
		} catch (AuraHandledException expected) {
			Assert.isNotNull(expected, 'Debe pedir regenerar la solicitud');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldRejectSignature_WhenIdentificationIsWrong() {
		ResidentialLoanApplication application = [SELECT Id FROM ResidentialLoanApplication WHERE Name = 'RLA Unicidad'];
		createLinkedDocument(application.Id, TITLE_PREFIX + 'Consumo - Ana Perez - 99999999999', 'wrong.pdf');
		Test.startTest();
		try {
			FSC_GenerarPDF.validarSolicitudParaFirma(application.Id);
			Assert.fail('La firma debe bloquearse cuando la identificacion no coincide');
		} catch (AuraHandledException expected) {
			Assert.isNotNull(expected, 'Debe pedir regenerar la solicitud');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldPreserveFiles_WhenAccountIdentificationIsMissing() {
		ResidentialLoanApplication application = [SELECT Id, AccountId FROM ResidentialLoanApplication WHERE Name = 'RLA Unicidad'];
		update new Account(Id = application.AccountId, ACC_NumIdentificacion__c = null);
		Id documentId = createLinkedDocument(application.Id, TITLE_PREFIX + 'Consumo - Ana Perez - 00123456789', 'old.pdf');
		Map<String, Object> output = new Map<String, Object>();
		Test.startTest();
		Boolean success = new FSC_GenerarPDF()
			.invokeMethod(METHOD_REGENERAR_PDF_SOLICITUD_CREDITO, new Map<String, Object>{ 'Id' => application.Id }, output, null);
		Test.stopTest();
		Assert.isFalse(success, 'No debe generar una planilla sin identificacion');
		Assert.areEqual(1, [SELECT COUNT() FROM ContentDocument WHERE Id = :documentId], 'La validacion debe ocurrir antes de eliminar');
	}

	@IsTest
	static void shouldClassifyHistoricalFiles_WhenProcessing251Titles() {
		Test.startTest();
		for (Integer index = 0; index < 251; index++) {
			Assert.isTrue(
				FSC_GenerarPDF.isSolicitudCreditoFile('(Credito PyMe - Cliente - ' + index + ')', null),
				'Debe reconocer cada archivo legacy'
			);
			Assert.isTrue(
				FSC_GenerarPDF.isSolicitudCreditoFile('Titulo anterior ' + index, FSC_ChecklistDocsPrecargaService.SOLICITUD_CREDITO),
				'La clave tecnica debe prevalecer sobre el titulo'
			);
			Assert.isFalse(FSC_GenerarPDF.isSolicitudCreditoFile('Pagare - ' + index, null), 'No debe confundir otros documentos con planillas');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldSendOnlyLatestVersion_WhenDocumentHasTwoVersions() {
		ResidentialLoanApplication application = [SELECT Id FROM ResidentialLoanApplication WHERE Name = 'RLA Unicidad'];
		String title = TITLE_PREFIX + 'Consumo - Ana Perez - 00123456789';
		Id documentId = createLinkedDocument(application.Id, title, 'first.pdf');
		ContentVersion latest = new ContentVersion(
			ContentDocumentId = documentId,
			Title = title,
			PathOnClient = 'latest.pdf',
			VersionData = Blob.valueOf('NEW_PDF'),
			FSC_EnviarDocumento__c = true
		);
		insert latest;
		Test.startTest();
		List<ContentVersion> pending = FSC_FirmarDocumentoUtility.obtenerArchivosPendientes(
			String.valueOf(application.Id),
			TITLE_PREFIX + 'Consumo - %'
		);
		Test.stopTest();
		Assert.areEqual(1, pending.size(), 'No debe enviar versiones historicas');
		Assert.areEqual(latest.Id, pending[0].Id, 'Debe seleccionar exactamente la ultima version');
	}

	@IsTest
	static void shouldRollbackDeletion_WhenSavingReplacementFails() {
		Account account = new Account(Name = 'A'.repeat(255), ACC_NumIdentificacion__c = '00123456789');
		insert account;
		ResidentialLoanApplication application = new ResidentialLoanApplication(
			Name = 'RLA Rollback',
			AccountId = account.Id,
			RecordTypeId = getResidentialLoanApplicationRecordTypeId(RT_CREDITO_CONSUMO),
			Status = 'En proceso',
			FSC_Subestado__c = 'Documentación para desembolso y firmas',
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401',
			FSC_UsuarioGestionPlanilla__c = UserInfo.getUserId()
		);
		insert application;
		Id oldDocument = createLinkedDocument(application.Id, TITLE_PREFIX + 'Consumo - Anterior - 99999999999', 'old.pdf');
		Map<String, Object> output = new Map<String, Object>();
		Test.startTest();
		Boolean success = new FSC_GenerarPDF()
			.invokeMethod(METHOD_REGENERAR_PDF_SOLICITUD_CREDITO, new Map<String, Object>{ 'Id' => application.Id }, output, null);
		Test.stopTest();
		Assert.isFalse(success, 'El titulo que supera el limite debe provocar un error de guardado');
		Assert.areEqual('System.DmlException', output.get('exceptionType'), 'Debe alcanzar el DML de reemplazo');
		Assert.areEqual(1, [SELECT COUNT() FROM ContentDocument WHERE Id = :oldDocument], 'El rollback debe restaurar el documento eliminado');
		Assert.areEqual(1, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :application.Id], 'El rollback debe restaurar el vinculo');
	}

	@IsTest
	static void shouldGenerateBothApplications_WhenQueueContinues() {
		ResidentialLoanApplication first = [SELECT Id FROM ResidentialLoanApplication WHERE Name = 'RLA Unicidad'];
		ResidentialLoanApplication second = createLoanApplication('Juan', 'Lopez', '00198765432', 'RLA Coleccion', RT_CREDITO_PYME);
		Set<Id> applicationIds = new Set<Id>{ first.Id, second.Id };
		Test.startTest();
		new FSC_RegenerarSolicitudCreditoQueueable(new List<Id>{ first.Id, second.Id }).execute(null);
		Test.stopTest();
		Assert.areEqual(
			2,
			[SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId IN :applicationIds],
			'Debe guardar una planilla por solicitud'
		);
		ContentDocumentLink secondFile = [SELECT ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId = :second.Id LIMIT 1];
		Assert.areEqual(
			TITLE_PREFIX + 'PyMe - Juan Lopez - 00198765432',
			secondFile.ContentDocument.Title,
			'No debe mezclar identidades entre solicitudes'
		);
	}

	private static Id createParentId() {
		Account a = new Account(Name = 'PDF Parent');
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

	private static Id getPersonAccountRecordTypeId() {
		Schema.RecordTypeInfo rtInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount');

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
		Id personAccountRecordTypeId = getPersonAccountRecordTypeId();
		if (personAccountRecordTypeId != null) {
			account.RecordTypeId = personAccountRecordTypeId;
		}
		account.FirstName = firstName;
		account.LastName = lastName;
		account.ACC_NumIdentificacion__c = documentNumber;
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
		Boolean ok = new FSC_GenerarPDF().invokeMethod(METHOD_GENERAR_PDF_PLANILLA_DESEMBOLSO, input, output, options);
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
		Boolean ok = new FSC_GenerarPDF().invokeMethod(METHOD_GENERAR_PDF_PLANILLA_DESEMBOLSO, input, output, new Map<String, Object>());
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
				METHOD_GENERAR_PDF_PLANILLA_DESEMBOLSO,
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
		Object ret = new FSC_GenerarPDF().call(METHOD_GENERAR_PDF_PLANILLA_DESEMBOLSO, args);
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
			.invokeMethod(METHOD_REGENERAR_PDF_SOLICITUD_CREDITO, new Map<String, Object>{ 'Id' => rla.Id }, output, new Map<String, Object>());
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
			.invokeMethod(METHOD_REGENERAR_PDF_SOLICITUD_CREDITO, new Map<String, Object>{ 'Id' => rla.Id }, output, new Map<String, Object>());
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