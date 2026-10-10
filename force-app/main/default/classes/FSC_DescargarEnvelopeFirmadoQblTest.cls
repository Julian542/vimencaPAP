@IsTest
private class FSC_DescargarEnvelopeFirmadoQblTest {
	private class EnvelopeFilesBinaryMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);
			res.setHeader('Content-Type', 'application/pdf');
			res.setBodyAsBlob(Blob.valueOf('PDF FIRMADO QUEUEABLE'));
			return res;
		}
	}

	private class EnvelopeFilesErrorMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(500);
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"Message":"Error descarga"}');
			return res;
		}
	}

	@IsTest
	static void testQueueable_GuardaFirmadoYMarcaOriginal() {
		ContentVersion original = createContentVersion('ENV-Q-001', 'Documento Queueable');
		Id rlaId = getRlaId(original.ContentDocumentId);

		Test.setMock(HttpCalloutMock.class, new EnvelopeFilesBinaryMock());

		Test.startTest();
		System.enqueueJob(new FSC_DescargarEnvelopeFirmadoQueueable('ENV-Q-001', '2026-03-18T00:03:40+00:00'));
		Test.stopTest();

		List<ContentVersion> activeOriginals = [
			SELECT Id
			FROM ContentVersion
			WHERE Id = :original.Id
		];
		System.assertEquals(0, activeOriginals.size(), 'Debe eliminar el archivo original sin firma despues de guardar el firmado');

		List<ContentDocumentLink> signedLinks = [
			SELECT Id
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :rlaId AND ContentDocument.LatestPublishedVersion.Title = 'Documento Queueable_firmado'
		];
		System.assertEquals(1, signedLinks.size(), 'Debe crear un archivo separado con sufijo _firmado');
	}

	@IsTest
	static void testQueueable_NoDuplicaFirmadoExistente() {
		ContentVersion original = createContentVersion('ENV-Q-002', 'Documento Duplicado');
		Id rlaId = getRlaId(original.ContentDocumentId);

		insert new ContentVersion(
			Title = 'Documento Duplicado_firmado',
			PathOnClient = 'Documento Duplicado_firmado.pdf',
			VersionData = Blob.valueOf('PDF YA EXISTE'),
			FirstPublishLocationId = rlaId,
			FSC_Firmado__c = true
		);

		Test.setMock(HttpCalloutMock.class, new EnvelopeFilesBinaryMock());

		Test.startTest();
		System.enqueueJob(new FSC_DescargarEnvelopeFirmadoQueueable('ENV-Q-002', '2026-03-18T00:03:40+00:00'));
		Test.stopTest();

		List<ContentDocumentLink> signedLinks = [
			SELECT Id
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :rlaId AND ContentDocument.LatestPublishedVersion.Title = 'Documento Duplicado_firmado'
		];
		System.assertEquals(1, signedLinks.size(), 'No debe duplicar el archivo firmado');

		List<ContentVersion> activeOriginals = [
			SELECT Id
			FROM ContentVersion
			WHERE Id = :original.Id
		];
		System.assertEquals(0, activeOriginals.size(), 'Debe eliminar el original si el firmado ya existia');
	}

	@IsTest
	static void testQueueable_NoMarcaOriginal_CuandoDescargaFalla() {
		ContentVersion original = createContentVersion('ENV-Q-003', 'Documento Error');

		Test.setMock(HttpCalloutMock.class, new EnvelopeFilesErrorMock());

		try {
			Test.startTest();
			System.enqueueJob(new FSC_DescargarEnvelopeFirmadoQueueable('ENV-Q-003', '2026-03-18T00:03:40+00:00'));
			Test.stopTest();
		} catch (Exception e) {
			// El fallo del callout debe dejar el original sin marcar.
		}

		ContentVersion updatedOriginal = [
			SELECT FSC_Firmado__c, FSC_FechaDeFirmaCliente__c
			FROM ContentVersion
			WHERE Id = :original.Id
			LIMIT 1
		];
		System.assertEquals(false, updatedOriginal.FSC_Firmado__c);
		System.assertEquals(null, updatedOriginal.FSC_FechaDeFirmaCliente__c);
	}

	private static ContentVersion createContentVersion(String envelopeId, String title) {
		return createContentVersion(envelopeId, title, createRla().Id);
	}

	private static ContentVersion createContentVersion(String envelopeId, String title, Id residentialLoanApplicationId) {
		insert new ContentVersion(
			Title = title,
			PathOnClient = title + '.pdf',
			VersionData = Blob.valueOf('PDF ORIGINAL'),
			FirstPublishLocationId = residentialLoanApplicationId,
			FSC_EnviarDocumento__c = true,
			FSC_FechaEnvioFirma__c = System.now(),
			FSC_EnvelopeId__c = envelopeId,
			FSC_Firmado__c = false
		);

		return [
			SELECT Id, Title, ContentDocumentId, FSC_Firmado__c
			FROM ContentVersion
			WHERE Title = :title
			LIMIT 1
		];
	}

	@IsTest
	static void shouldDownloadOnlySelectedRla_WhenEnvelopeIdIsShared() {
		ResidentialLoanApplication selectedRla = createRla();
		ResidentialLoanApplication otherRla = selectedRla.clone(false, true, false, false);
		otherRla.Name = 'Otra solicitud';
		insert otherRla;
		ContentVersion selectedDocument = createContentVersion('ENV-SHARED', 'Documento seleccionado', selectedRla.Id);
		ContentVersion otherDocument = createContentVersion('ENV-SHARED', 'Documento otra solicitud', otherRla.Id);
		Test.setMock(HttpCalloutMock.class, new EnvelopeFilesBinaryMock());

		Test.startTest();
		System.enqueueJob(
			new FSC_DescargarEnvelopeFirmadoQueueable(new Map<String, String>{ 'ENV-SHARED' => '2026-03-18T00:03:40+00:00' }, selectedRla.Id)
		);
		Test.stopTest();

		Assert.areEqual(0, [SELECT COUNT() FROM ContentVersion WHERE Id = :selectedDocument.Id], 'Debe reemplazar el original del RLA seleccionado');
		ContentVersion untouchedDocument = [SELECT FSC_Firmado__c, FSC_FechaDeFirmaCliente__c FROM ContentVersion WHERE Id = :otherDocument.Id];
		Assert.isFalse(untouchedDocument.FSC_Firmado__c, 'No debe modificar el documento de otro RLA');
		Assert.isNull(untouchedDocument.FSC_FechaDeFirmaCliente__c, 'No debe registrar firma en otro RLA');
		ResidentialLoanApplication untouchedRla = [
			SELECT FSC_Firma_completada__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :otherRla.Id
		];
		Assert.isFalse(untouchedRla.FSC_Firma_completada__c, 'No debe completar firmas de otro RLA');
		Assert.areEqual('Gestionar firmas', untouchedRla.FSC_Subestado__c, 'No debe avanzar el subestado de otro RLA');
		Assert.areEqual(
			1,
			[
				SELECT COUNT()
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :selectedRla.Id AND ContentDocument.LatestPublishedVersion.Title = 'Documento seleccionado_firmado'
			],
			'Debe guardar el PDF firmado solo en el RLA seleccionado'
		);
	}

	@IsTest
	static void shouldPreserveOriginal_WhenDocumentIsLinkedToAnotherRla() {
		ResidentialLoanApplication selectedRla = createRla();
		ResidentialLoanApplication otherRla = selectedRla.clone(false, true, false, false);
		otherRla.Name = 'Otra solicitud';
		insert otherRla;
		ContentVersion sharedDocument = createContentVersion('ENV-LINKED', 'Documento compartido', selectedRla.Id);
		insert new ContentDocumentLink(ContentDocumentId = sharedDocument.ContentDocumentId, LinkedEntityId = otherRla.Id, ShareType = 'V');
		Test.setMock(HttpCalloutMock.class, new EnvelopeFilesBinaryMock());

		Test.startTest();
		System.enqueueJob(
			new FSC_DescargarEnvelopeFirmadoQueueable(new Map<String, String>{ 'ENV-LINKED' => '2026-03-18T00:03:40+00:00' }, selectedRla.Id)
		);
		Test.stopTest();

		ContentVersion untouchedDocument = [SELECT FSC_Firmado__c FROM ContentVersion WHERE Id = :sharedDocument.Id];
		Assert.isFalse(untouchedDocument.FSC_Firmado__c, 'El original compartido debe conservar su estado para el otro RLA');
		Assert.areEqual(
			1,
			[SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :otherRla.Id AND ContentDocumentId = :sharedDocument.ContentDocumentId],
			'Debe conservar el archivo vinculado al otro RLA'
		);
		Assert.areEqual(
			0,
			[
				SELECT COUNT()
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :selectedRla.Id AND ContentDocumentId = :sharedDocument.ContentDocumentId
			],
			'Solo debe desvincular el original del RLA seleccionado'
		);
		Assert.areEqual(
			1,
			[
				SELECT COUNT()
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :selectedRla.Id AND ContentDocument.LatestPublishedVersion.Title = 'Documento compartido_firmado'
			],
			'Debe guardar el firmado en el RLA seleccionado'
		);
		ResidentialLoanApplication untouchedRla = [
			SELECT FSC_Firma_completada__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :otherRla.Id
		];
		Assert.isFalse(untouchedRla.FSC_Firma_completada__c, 'No debe completar firmas del otro RLA');
		Assert.areEqual('Gestionar firmas', untouchedRla.FSC_Subestado__c, 'No debe avanzar el otro RLA');
	}

	private static Id getRlaId(Id contentDocumentId) {
		for (ContentDocumentLink link : [
			SELECT LinkedEntityId
			FROM ContentDocumentLink
			WHERE ContentDocumentId = :contentDocumentId
		]) {
			if (link.LinkedEntityId != null && link.LinkedEntityId.getSObjectType() == ResidentialLoanApplication.SObjectType) {
				return link.LinkedEntityId;
			}
		}

		return null;
	}

	private static ResidentialLoanApplication createRla() {
		Account a = new Account();
		a.LastName = 'Cliente Queueable';
		a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Fisica').getRecordTypeId();
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
		rla.Name = 'RLA Queueable Test';
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
		rla.FSC_Subestado__c = 'Gestionar firmas';
		insert rla;

		return rla;
	}
}