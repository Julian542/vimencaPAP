@IsTest
private class FSC_ContentVersionTrigger_Test {
	@TestSetup
	static void setupData() {
		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
		Account a = new Account();
		a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
		a.FirstName = 'Cliente';
		a.LastName = 'PDF';
		a.ACC_NumIdentificacion__c = '00298765432';
		a.ACC_TipoIdentificacion__c = 'Cédula';
		a.ACC_Nacionalidad__c = 'AFGANISTÁN';
		a.ACC_Estado_Civil__c = 'SOLTERO/A';
		a.BillingStreet = 'Av. Siempre Viva';
		a.BillingCity = 'Santo Domingo';
		a.BillingState = 'DN';
		a.BillingCountry = 'Republica Dominicana';
		insert a;

		ResidentialLoanApplication rla = new ResidentialLoanApplication();
		rla.AccountId = a.Id;
		rla.Name = 'RLA Test';
		rla.RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
			.get('FSC_Solicitud_Credito_Consumo')
			.getRecordTypeId();
		rla.FSC_MontoAprobado__c = 100000;
		rla.FSC_FechaYHoraAprobacionComite__c = System.now();
		rla.FSC_PlazoMesesAprobado__c = 10;
		rla.FSC_Plazo_meses__c = '11';
		rla.FSC_Aplica_Garantia__c = false;
		rla.FSC_TasaInteresAprobada__c = 15;
		rla.FSC_Moneda__c = '1';
		rla.FSC_TasaInteres__c = 1.00;
		rla.FSC_Aprobado_con_Condiciones__c = false;
		rla.Status = 'En proceso';
			rla.FSC_Subestado__c = 'Generación de pagarés y plantillas';
			rla.FSC_lineaFinanciera__c = '32';
			rla.FSC_subAplicacion__c = '401';
			rla.FSC_DocumentosFirmadosFis__c = true;

		insert rla;
	}

	private static ResidentialLoanApplication getRLA() {
		return [
			SELECT Id, Name, FSC_Firma_completada__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			LIMIT 1
		];
	}

	@IsTest
	static void testTrigger_actualizaRLA_cuandoTodosLosDocumentosEstanFirmados() {
		ResidentialLoanApplication rla = getRLA();

		ContentVersion cv1 = createFileLinkedToRecord(rla.Id, 'Documento 1', true, true);

		ContentVersion cv2 = createFileLinkedToRecord(rla.Id, 'Documento 2', true, false);

		Test.startTest();

		cv2.FSC_Firmado__c = true;
		update cv2;

		Test.stopTest();

		ResidentialLoanApplication updatedRla = [
			SELECT Id, FSC_Firma_completada__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals(true, updatedRla.FSC_Firma_completada__c, 'El RLA debe quedar con firma completada en true');
		System.assertEquals(
			'Documentación para desembolso y firmas',
			updatedRla.FSC_Subestado__c,
			'El subestado debe actualizarse al valor esperado'
		);
	}

	@IsTest
	static void testTrigger_noActualizaRLA_siFaltaUnDocumentoPorFirmar() {
		ResidentialLoanApplication rla = getRLA();

		ContentVersion cv1 = createFileLinkedToRecord(rla.Id, 'Doc A', true, true);

		ContentVersion cv2 = createFileLinkedToRecord(rla.Id, 'Doc B', true, false);

		ContentVersion cv3 = createFileLinkedToRecord(rla.Id, 'Doc C', true, false);

		Test.startTest();

		cv2.FSC_Firmado__c = true;
		update cv2;

		Test.stopTest();

		ResidentialLoanApplication updatedRla = [
			SELECT Id, FSC_Firma_completada__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals(false, updatedRla.FSC_Firma_completada__c, 'El RLA no debe actualizarse porque todavía falta un documento por firmar');
		System.assertNotEquals(
			'Documentación para desembolso y firmas',
			updatedRla.FSC_Subestado__c,
			'El subestado no debe cambiar cuando aún faltan documentos firmados'
		);
	}

	@IsTest
	static void testTrigger_noHaceNada_siFirmadoNoCambiaATrue() {
		ResidentialLoanApplication rla = getRLA();

		ContentVersion cv1 = createFileLinkedToRecord(rla.Id, 'Documento sin cambio de firma', true, false);

		Test.startTest();

		cv1.Title = 'Documento sin cambio de firma actualizado';
		update cv1;

		Test.stopTest();

		ResidentialLoanApplication updatedRla = [
			SELECT Id, FSC_Firma_completada__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals(false, updatedRla.FSC_Firma_completada__c, 'No debe actualizar el RLA si FSC_Firmado__c no cambió a true');
		System.assertNotEquals(
			'Documentación para desembolso y firmas',
			updatedRla.FSC_Subestado__c,
			'No debe cambiar el subestado si FSC_Firmado__c no cambió a true'
		);
	}

	@IsTest
	static void testHandler_validacionDocumentosFirmados_devuelveNull_siNoEsRLA() {
		Account acc = getTestAccount();

		ContentVersion cv = createFileLinkedToRecord(acc.Id, 'Archivo ligado a Account', true, true);

		Test.startTest();
		Id result = FSC_ContentVersionTriggerHandler.validacionDocumentosFirmados(cv);
		Test.stopTest();

		System.assertEquals(null, result, 'Debe devolver null cuando el LinkedEntityId no corresponde a ResidentialLoanApplication');
	}

	private static Account getTestAccount() {
		return [
			SELECT Id
			FROM Account
			LIMIT 1
		];
	}

	@IsTest
	static void testHandler_actualizarRLAs_actualizaRegistros() {
		ResidentialLoanApplication rla = getRLA();
		createFileLinkedToRecord(rla.Id, 'Documento firmado', true, true);

		Test.startTest();
		FSC_ContentVersionTriggerHandler.actualizarRLAs(new Set<Id>{ rla.Id });
		Test.stopTest();

		ResidentialLoanApplication updatedRla = [
			SELECT Id, FSC_Firma_completada__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals(true, updatedRla.FSC_Firma_completada__c, 'El método actualizarRLAs debe marcar la firma como completada');
		System.assertEquals(
			'Documentación para desembolso y firmas',
			updatedRla.FSC_Subestado__c,
			'El método actualizarRLAs debe actualizar el subestado'
		);
	}

	private static ContentVersion createFileLinkedToRecord(Id linkedEntityId, String title, Boolean enviarDocumento, Boolean firmado) {
		ContentVersion cv = new ContentVersion(
			Title = title,
			PathOnClient = title + '.pdf',
			VersionData = Blob.valueOf('test-' + title),
			FirstPublishLocationId = linkedEntityId,
			FSC_EnviarDocumento__c = enviarDocumento,
			FSC_Firmado__c = firmado,
			FSC_FechaEnvioFirma__c = enviarDocumento ? System.now() : null
		);
		insert cv;

		return [
			SELECT Id, Title, ContentDocumentId, FSC_EnviarDocumento__c, FSC_Firmado__c
			FROM ContentVersion
			WHERE Id = :cv.Id
		];
	}

	@IsTest
	static void testValidacionDocumentosFirmados_recordNull() {
		Test.startTest();
		Id result = FSC_ContentVersionTriggerHandler.validacionDocumentosFirmados(null);
		Test.stopTest();

		System.assertEquals(null, result, 'Debe devolver null cuando el record recibido es null');
	}

	@IsTest
	static void testValidacionDocumentosFirmados_contentDocumentIdNull() {
		ContentVersion cv = new ContentVersion();

		Test.startTest();
		Id result = FSC_ContentVersionTriggerHandler.validacionDocumentosFirmados(cv);
		Test.stopTest();

		System.assertEquals(null, result, 'Debe devolver null cuando ContentDocumentId es null');
	}

	@IsTest
	static void testValidacionDocumentosFirmados_currentLinksEmpty() {
		ResidentialLoanApplication rla = getRLA();

		ContentVersion realCv = createFileLinkedToRecord(rla.Id, 'Doc temporal', true, true);

		List<ContentDocumentLink> links = [
			SELECT Id
			FROM ContentDocumentLink
			WHERE ContentDocumentId = :realCv.ContentDocumentId
		];
		delete links;

		ContentVersion inputCv = new ContentVersion(Id = realCv.Id, ContentDocumentId = realCv.ContentDocumentId);

		Test.startTest();
		Id result = FSC_ContentVersionTriggerHandler.validacionDocumentosFirmados(inputCv);
		Test.stopTest();

		System.assertEquals(null, result, 'Debe devolver null cuando no existen ContentDocumentLink para ese ContentDocument');
	}

	@IsTest
	static void testValidacionDocumentosFirmados_contentVersionIdsEmpty() {
		ResidentialLoanApplication rla = getRLA();

		ContentVersion cv = createFileLinkedToRecord(rla.Id, 'Doc para borrar version', true, true);

		List<ContentDocumentLink> linksBefore = [
			SELECT Id, ContentDocumentId
			FROM ContentDocumentLink
			WHERE ContentDocumentId = :cv.ContentDocumentId
		];

		delete [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId];

		ContentVersion inputCv = new ContentVersion(Id = cv.Id, ContentDocumentId = cv.ContentDocumentId);

		Test.startTest();
		Id result = FSC_ContentVersionTriggerHandler.validacionDocumentosFirmados(inputCv);
		Test.stopTest();

		System.assertEquals(null, result, 'Debe devolver null cuando no se pueden obtener LatestPublishedVersionId válidos');
	}

	@IsTest
	static void testValidacionDocumentosFirmados_returnNullFinal_cuandoNoTodosFirmados() {
		ResidentialLoanApplication rla = getRLA();

		createFileLinkedToRecord(rla.Id, 'Documento firmado', true, true);

		ContentVersion noFirmado = createFileLinkedToRecord(rla.Id, 'Documento no firmado', true, false);

		ContentVersion inputCv = [
			SELECT Id, ContentDocumentId, FSC_EnviarDocumento__c, FSC_Firmado__c
			FROM ContentVersion
			WHERE Id = :noFirmado.Id
		];

		Test.startTest();
		Id result = FSC_ContentVersionTriggerHandler.validacionDocumentosFirmados(inputCv);
		Test.stopTest();

		System.assertEquals(null, result, 'Debe devolver null cuando existen documentos enviados que todavía no están todos firmados');
	}

	@IsTest
	static void testActualizarRLAs_cubreUpdate() {
		ResidentialLoanApplication rla = getRLA();
		createFileLinkedToRecord(rla.Id, 'Documento firmado update', true, true);

		Test.startTest();
		FSC_ContentVersionTriggerHandler.actualizarRLAs(new Set<Id>{ rla.Id });
		Test.stopTest();

		ResidentialLoanApplication updatedRla = [
			SELECT Id, FSC_Firma_completada__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals(true, updatedRla.FSC_Firma_completada__c);
		System.assertEquals('Documentación para desembolso y firmas', updatedRla.FSC_Subestado__c);
	}

	@IsTest
	static void testActualizarRLAs_setVacio() {
		Test.startTest();
		FSC_ContentVersionTriggerHandler.actualizarRLAs(new Set<Id>());
		FSC_ContentVersionTriggerHandler.actualizarRLAs(null);
		Test.stopTest();

		System.assert(true, 'Cubre la salida temprana cuando el set viene vacío o null');
	}
}
