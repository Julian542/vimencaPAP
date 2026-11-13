@IsTest
private class FSC_FirmarDocumentoUtility_Test {
	private static final String PROCESS_CREDIT = 'CREDITO_PYME';
	private static final String ENVELOPE_ID = 'mock-envelope-id-001';
	private static final String SIGNED_CONTENT = 'PDF FIRMADO';
	private static final String TITLE_PREFIX_CREDITO = 'Crédito ';
	private class EnvelopeStatusErrorMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(400);
			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"ErrorId":"ERR-1","Message":"Error envelope","TraceId":"TRACE-1"}');
			return res;
		}
	}

	private class EnvelopeStatusExceptionMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			throw new CalloutException('Mock exception');
		}
	}

	private class EnvelopeFilesJsonMock implements HttpCalloutMock {
		private String responseBody;
		private Integer responseStatus;
		EnvelopeFilesJsonMock() {
			this.responseBody =
				'{"Files":[{"FileName":"Documento Test.pdf","Content":"' +
				EncodingUtil.base64Encode(Blob.valueOf('PDF FIRMADO JSON')) +
				'"}]}';
			this.responseStatus = 200;
		}
		EnvelopeFilesJsonMock(String responseBody, Integer responseStatus) {
			this.responseBody = responseBody;
			this.responseStatus = responseStatus;
		}
		public HttpResponse respond(HttpRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(responseStatus);
			res.setHeader('Content-Type', 'application/json');
			res.setBody(responseBody);
			return res;
		}
	}

	private class EnvelopeFilesFileIdMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);

			if (req.getEndpoint() != null && req.getEndpoint().contains('/file/')) {
				res.setHeader('Content-Type', 'application/pdf');
				res.setBodyAsBlob(Blob.valueOf('PDF FIRMADO FILEID'));
				return res;
			}

			res.setHeader('Content-Type', 'application/json');
			res.setBody('{"Documents":[{"FileId":"file-id-001","FileName":"Documento FileId.pdf"}]}');
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

	@TestSetup
	static void setupData() {
		Account acc = createAccount('Joel Valenti', '42010242');

		Date actaDate = Date.today();
		DateTime approvedDt = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 14, 30, 0);
		ResidentialLoanApplication rla = new ResidentialLoanApplication();
		rla.AccountId = acc.Id;
		rla.RecordTypeId = getRecordTypeId('FSC_Solicitud_Credito_PYME');
		rla.FSC_SolicitudAprobadaPorComite__c = true;
		rla.FSC_FechaYHoraAprobacionComite__c = approvedDt;
		rla.Name = 'Test RLA ' + String.valueOf(approvedDt);
		rla.FSC_Monto__c = 1000;
		rla.FSC_MontoAprobado__c = 900;
		rla.FSC_PlazoMeses__c = 10;
		rla.FSC_PlazoMesesAprobado__c = 9;
		rla.FSC_TasaInteres__c = 12;
		rla.FSC_TasaInteresAprobada__c = 10;
		rla.FSC_Aplica_Garantia__c = false;
		rla.FSC_DecisionComite__c = 'Aprobada con condición';

		insert rla;

		insert new ContentVersion(
			Title = 'Crédito PyMe - Joel Valenti - 42010242',
			PathOnClient = 'credito.pdf',
			VersionData = Blob.valueOf('PDF CREDITO'),
			FirstPublishLocationId = rla.Id,
			FSC_EnviarDocumento__c = true
		);

		insert new ContentVersion(
			Title = 'Pagare Joel Valenti 2026-03-10-16-43-34',
			PathOnClient = 'pagare.pdf',
			VersionData = Blob.valueOf('PDF PAGARE'),
			FirstPublishLocationId = rla.Id,
			FSC_EnviarDocumento__c = true
		);
	}

	private static ResidentialLoanApplication getRla() {
		return [SELECT Id FROM ResidentialLoanApplication LIMIT 1];
	}

	private static Id getRecordTypeId(String developerName) {
		Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName();
		System.assert(recordTypes.containsKey(developerName), 'No existe el RecordType: ' + developerName);
		return recordTypes.get(developerName).getRecordTypeId();
	}

	@IsTest
	static void testEnviarDocumentosFirmar_ProcesoValido() {
		Account acc = new Account(
			Name = 'Cuenta Proceso Valido',
			ACC_NumIdentificacion__c = '00123456789',
			ACC_Correo_Electronico_Cliente__c = 'procesovalido@test.com'
		);
		insert acc;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			AccountId = acc.Id,
			RecordTypeId = getRecordTypeId('FSC_Solicitud_Credito_PYME'),
			Name = 'RLA Proceso Valido'
		);
		insert rla;

		insert new ContentVersion(
			Title = 'Crédito PyMe - Cuenta Proceso Valido - 00123456789',
			PathOnClient = 'credito-proceso-valido.pdf',
			VersionData = Blob.valueOf('PDF CREDITO PROCESO VALIDO'),
			FirstPublishLocationId = rla.Id,
			FSC_EnviarDocumento__c = true
		);

		insert new ContentVersion(
			Title = 'Pagare Proceso Valido',
			PathOnClient = 'pagare-proceso-valido.pdf',
			VersionData = Blob.valueOf('PDF PAGARE PROCESO VALIDO'),
			FirstPublishLocationId = rla.Id,
			FSC_EnviarDocumento__c = true
		);

		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

		Test.startTest();
		FSC_FirmarDocumentoUtility.SendDocumentsResult result = FSC_FirmarDocumentoUtility.enviarDocumentosFirmar('Gestionar firmas', rla.Id);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertNotEquals(null, result.message);
	}

	@IsTest
	static void testEnviarDocumentosFirmar_ButtonInvalido() {
		ResidentialLoanApplication rla = getRla();

		try {
			FSC_FirmarDocumentoUtility.enviarDocumentosFirmar('Boton Invalido', rla.Id);
			System.assert(false);
		} catch (Exception e) {
			System.assert(e.getMessage().contains('Tipo de proceso no reconocido'));
		}
	}

	@IsTest
	static void testEnviarDocumentosFirmar_ButtonVacio() {
		ResidentialLoanApplication rla = getRla();

		try {
			FSC_FirmarDocumentoUtility.enviarDocumentosFirmar('', rla.Id);
			System.assert(false);
		} catch (Exception e) {
			System.assert(e.getMessage().contains('no puede estar vacio'));
		}
	}

	@IsTest
	static void testEnviarDocumentosFirmar_RecordIdVacio() {
		try {
			FSC_FirmarDocumentoUtility.enviarDocumentosFirmar('Gestionar firmas', '');
			System.assert(false);
		} catch (Exception e) {
			System.assert(e.getMessage().contains('ID del registro'));
		}
	}

	@IsTest
	static void testEnviarPorProcesoCredito_NoExplota() {
		ResidentialLoanApplication rla = getRla();

		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

		Test.startTest();
		VFS_EsignSendingEnvelope.EnvelopeResult result = FSC_FirmarDocumentoUtility.enviarPorProceso('CREDITO_PYME', rla.Id);
		Test.stopTest();

		System.assertNotEquals(null, result);
	}

	@IsTest
	static void testEnviarPorProcesoPagare_NoExplota() {
		ResidentialLoanApplication rla = getRla();

		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

		Test.startTest();
		VFS_EsignSendingEnvelope.EnvelopeResult result = FSC_FirmarDocumentoUtility.enviarPorProceso('PAGARE', rla.Id);
		Test.stopTest();

		System.assertNotEquals(null, result);
	}

	@IsTest
	static void testEnviarPorProcesoSinArchivos() {
		Account acc = new Account(Name = 'Cuenta Sin Archivos', ACC_Correo_Electronico_Cliente__c = 'sinarchivos@test.com');
		insert acc;

		Date actaDate = Date.today();
		DateTime approvedDt = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 14, 30, 0);
		ResidentialLoanApplication rla = new ResidentialLoanApplication();
		rla.AccountId = acc.Id;
		rla.RecordTypeId = getRecordTypeId('FSC_Solicitud_Credito_PYME');
		rla.FSC_SolicitudAprobadaPorComite__c = true;
		rla.FSC_FechaYHoraAprobacionComite__c = approvedDt;
		rla.Name = 'Test RLA ' + String.valueOf(approvedDt);
		rla.FSC_Monto__c = 1000;
		rla.FSC_MontoAprobado__c = 900;
		rla.FSC_PlazoMeses__c = 10;
		rla.FSC_PlazoMesesAprobado__c = 9;
		rla.FSC_TasaInteres__c = 12;
		rla.FSC_TasaInteresAprobada__c = 10;
		rla.FSC_Aplica_Garantia__c = false;
		rla.FSC_DecisionComite__c = 'Aprobada con condición';

		insert rla;

		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

		Test.startTest();
		VFS_EsignSendingEnvelope.EnvelopeResult result = FSC_FirmarDocumentoUtility.enviarPorProceso('CREDITO_PYME', rla.Id);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(false, result.success);
		System.assert(result.message.contains('No se encontraron archivos pendientes'));
	}

	@IsTest
	static void testEnviarDocumentosFirmar_SinDocumentosPendientes_NoMarcaSolicitud() {
		Account acc = new Account(
			Name = 'Cuenta Sin Pendientes',
			ACC_NumIdentificacion__c = '00123456789',
			ACC_Correo_Electronico_Cliente__c = 'sinpendientes@test.com'
		);
		insert acc;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			AccountId = acc.Id,
			RecordTypeId = getRecordTypeId('FSC_Solicitud_Credito_PYME'),
			Name = 'RLA Sin Pendientes'
		);
		insert rla;

		insert new ContentVersion(
			Title = 'Crédito PyMe - Cuenta Sin Pendientes - 00123456789',
			PathOnClient = 'credito-enviado.pdf',
			VersionData = Blob.valueOf('PDF CREDITO ENVIADO'),
			FirstPublishLocationId = rla.Id,
			FSC_EnviarDocumento__c = true,
			FSC_FechaEnvioFirma__c = System.now()
		);

		insert new ContentVersion(
			Title = 'Pagare Ya enviado',
			PathOnClient = 'pagare-enviado.pdf',
			VersionData = Blob.valueOf('PDF PAGARE ENVIADO'),
			FirstPublishLocationId = rla.Id,
			FSC_EnviarDocumento__c = true,
			FSC_FechaEnvioFirma__c = System.now()
		);

		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

		Test.startTest();
		FSC_FirmarDocumentoUtility.SendDocumentsResult result = FSC_FirmarDocumentoUtility.enviarDocumentosFirmar('Gestionar firmas', rla.Id);
		Test.stopTest();

		System.assertEquals(false, result.success);
		System.assertEquals(false, result.documentsSent);
		System.assert(result.message.contains('Sin documentos pendientes'));

		ResidentialLoanApplication updatedRla = [
			SELECT FSC_EnviadoAFirmar__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
			LIMIT 1
		];
		System.assertEquals(false, updatedRla.FSC_EnviadoAFirmar__c);
	}

	@IsTest
	static void testEnviarDocumentosFirmar_SoloPagarePendiente() {
		Account acc = new Account(
			Name = 'Cuenta Solo Pagare',
			ACC_NumIdentificacion__c = '00123456789',
			ACC_Correo_Electronico_Cliente__c = 'solopagare@test.com'
		);
		insert acc;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			AccountId = acc.Id,
			RecordTypeId = getRecordTypeId('FSC_Solicitud_Credito_PYME'),
			Name = 'RLA Solo Pagare'
		);
		insert rla;

		insert new ContentVersion(
			Title = 'Crédito PyMe - Cuenta Solo Pagare - 00123456789',
			PathOnClient = 'credito-ya-enviado.pdf',
			VersionData = Blob.valueOf('PDF CREDITO YA ENVIADO'),
			FirstPublishLocationId = rla.Id,
			FSC_EnviarDocumento__c = true,
			FSC_FechaEnvioFirma__c = System.now()
		);

		insert new ContentVersion(
			Title = 'Pagare Solo Pendiente',
			PathOnClient = 'pagare-pendiente.pdf',
			VersionData = Blob.valueOf('PDF PAGARE PENDIENTE'),
			FirstPublishLocationId = rla.Id,
			FSC_EnviarDocumento__c = true
		);

		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

		Test.startTest();
		FSC_FirmarDocumentoUtility.SendDocumentsResult result = FSC_FirmarDocumentoUtility.enviarDocumentosFirmar('Gestionar firmas', rla.Id);
		Test.stopTest();

		Assert.isFalse(result.creditoSent, 'La planilla ya enviada no debe volver a enviarse');
		Assert.areEqual(
			FSC_ConfiguracionFirmaDocumentosService.isFirmaDigital(
				'FSC_Solicitud_Credito_PYME',
				FSC_ConfiguracionFirmaDocumentosService.DOCUMENTO_PAGARE
			),
			result.pagareSent,
			'Solo debe encolar el pagare si su firma es digital'
		);
	}

	@IsTest
	static void testTieneArchivosPendientes_PorProceso() {
		ResidentialLoanApplication rla = getRla();

		System.assertEquals(true, FSC_FirmarDocumentoUtility.tieneArchivosPendientes('PAGARE', rla.Id));
		System.assertEquals(true, FSC_FirmarDocumentoUtility.tieneArchivosPendientes('CREDITO_PYME', rla.Id));
	}

	@IsTest
	static void testTieneArchivosPendientes_CreditoPorRecordType() {
		Map<String, String> labels = new Map<String, String>{
			'FSC_Solicitud_Credito_PYME' => 'PyMe',
			'FSC_Solicitud_Credito_Consumo' => 'Consumo',
			'FSC_Solicitud_Credito_Vehiculo' => 'Vehiculo',
			'FSC_Solicitud_Credito_Hipotecario' => 'Hipotecario'
		};
		Account account = createAccount('Cliente Tipos Credito', '00123456789');
		List<ResidentialLoanApplication> applications = new List<ResidentialLoanApplication>();
		for (String recordType : labels.keySet()) {
			applications.add(new ResidentialLoanApplication(Name = recordType, AccountId = account.Id, RecordTypeId = getRecordTypeId(recordType)));
		}
		insert applications;
		List<ContentVersion> files = new List<ContentVersion>();
		for (ResidentialLoanApplication application : applications) {
			files.add(
				new ContentVersion(
					Title = TITLE_PREFIX_CREDITO + labels.get(application.Name) + ' - ' + account.Name + ' - ' + account.ACC_NumIdentificacion__c,
					PathOnClient = 'credito.pdf',
					VersionData = Blob.valueOf('PDF'),
					FirstPublishLocationId = application.Id,
					FSC_EnviarDocumento__c = true
				)
			);
		}
		insert files;
		Test.startTest();
		for (ResidentialLoanApplication application : applications) {
			Assert.isTrue(
				FSC_FirmarDocumentoUtility.tieneArchivosPendientes('CREDITO_PYME', application.Id),
				'Debe encontrar la planilla de ' + application.Name
			);
		}
		Test.stopTest();
	}

	@IsTest
	static void testEmailTextCreditoPorRecordType() {
		Map<String, String> emailLabelByRecordType = new Map<String, String>{
			'FSC_Solicitud_Credito_PYME' => 'PYME',
			'FSC_Solicitud_Credito_Consumo' => 'Consumo',
			'FSC_Solicitud_Credito_Vehiculo' => 'Vehiculo',
			'FSC_Solicitud_Credito_Hipotecario' => 'Hipotecario'
		};

		for (String recordTypeDeveloperName : emailLabelByRecordType.keySet()) {
			ResidentialLoanApplication rla = createRlaSinDocumentos(recordTypeDeveloperName);
			String expectedLabel = emailLabelByRecordType.get(recordTypeDeveloperName);

			String subject = FSC_FirmarDocumentoUtility.buildEmailSubject('CREDITO_PYME', rla.Id);
			String body = FSC_FirmarDocumentoUtility.buildEmailBody('CREDITO_PYME', rla.Id);

			System.assert(subject.contains(expectedLabel), 'El asunto debe incluir el tipo de credito ' + expectedLabel);
			System.assert(body.contains(expectedLabel), 'El cuerpo debe incluir el tipo de credito ' + expectedLabel);
		}
	}

	@IsTest
	static void testTieneArchivosPendientes_ProcesoInvalido() {
		ResidentialLoanApplication rla = getRla();

		try {
			FSC_FirmarDocumentoUtility.tieneArchivosPendientes('INVALIDO', rla.Id);
			System.assert(false);
		} catch (Exception e) {
			System.assert(e.getMessage().contains('No existe configuracion'));
		}
	}

	@IsTest
	static void testMarcarSolicitudComoEnviada() {
		ResidentialLoanApplication rla = createRlaSinDocumentos();

		FSC_FirmarDocumentoUtility.marcarSolicitudComoEnviada(rla.Id);

		ResidentialLoanApplication updatedRla = [
			SELECT FSC_EnviadoAFirmar__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
			LIMIT 1
		];
		System.assertEquals(true, updatedRla.FSC_EnviadoAFirmar__c);
	}

	private static ResidentialLoanApplication createRlaSinDocumentos() {
		return createRlaSinDocumentos('FSC_Solicitud_Credito_PYME');
	}

	private static ResidentialLoanApplication createRlaSinDocumentos(String recordTypeDeveloperName) {
		Account acc = new Account(
			Name = 'Cuenta Sin Documentos ' + System.now().getTime(),
			ACC_NumIdentificacion__c = '00123456789',
			ACC_Correo_Electronico_Cliente__c = 'sindocumentos@test.com'
		);
		insert acc;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			AccountId = acc.Id,
			RecordTypeId = getRecordTypeId(recordTypeDeveloperName),
			Name = 'RLA Sin Documentos ' + System.now().getTime()
		);
		insert rla;
		return rla;
	}

	@IsTest
	static void testObtenerEstadoEnvelope_Success() {
		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

		Test.startTest();
		FSC_FirmarDocumentoUtility.EnvelopeStatus result = FSC_FirmarDocumentoUtility.obtenerEstadoEnvelope('env-001');
		Test.stopTest();

		System.assertEquals(true, result.success);
		System.assertEquals('InProgress', result.envelopeStatus);
	}

	@IsTest
	static void testObtenerEstadoEnvelope_Error() {
		Test.setMock(HttpCalloutMock.class, new EnvelopeStatusErrorMock());

		Test.startTest();
		FSC_FirmarDocumentoUtility.EnvelopeStatus result = FSC_FirmarDocumentoUtility.obtenerEstadoEnvelope('env-002');
		Test.stopTest();

		System.assertEquals(false, result.success);
		System.assertEquals('ERR-1', result.errorId);
		System.assertEquals('Error envelope', result.message);
		System.assertEquals('TRACE-1', result.traceId);
	}

	@IsTest
	static void testObtenerEstadoEnvelope_Exception() {
		Test.setMock(HttpCalloutMock.class, new EnvelopeStatusExceptionMock());

		Test.startTest();
		FSC_FirmarDocumentoUtility.EnvelopeStatus result = FSC_FirmarDocumentoUtility.obtenerEstadoEnvelope('env-003');
		Test.stopTest();

		System.assertEquals(false, result.success);
		System.assert(result.message.contains('Mock exception'));
	}

	@IsTest
	static void testObtenerArchivosFirmadosEnvelope_Binario() {
		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

		Test.startTest();
		List<FSC_FirmarDocumentoUtility.SignedEnvelopeFile> result = FSC_FirmarDocumentoUtility.obtenerArchivosFirmadosEnvelope('env-files-001');
		Test.stopTest();

		System.assertEquals(1, result.size());
		System.assertEquals('Documento firmado.pdf', result[0].fileName);
		System.assertEquals('PDF FIRMADO MOCK', result[0].body.toString());
	}

	@IsTest
	static void testObtenerArchivosFirmadosEnvelope_JsonBase64() {
		Test.setMock(HttpCalloutMock.class, new EnvelopeFilesJsonMock());

		Test.startTest();
		List<FSC_FirmarDocumentoUtility.SignedEnvelopeFile> result = FSC_FirmarDocumentoUtility.obtenerArchivosFirmadosEnvelope('env-files-002');
		Test.stopTest();

		System.assertEquals(1, result.size());
		System.assertEquals('Documento Test.pdf', result[0].fileName);
		System.assertEquals('PDF FIRMADO JSON', result[0].body.toString());
	}

	@IsTest
	static void testObtenerArchivosFirmadosEnvelope_JsonFileId() {
		Test.setMock(HttpCalloutMock.class, new EnvelopeFilesFileIdMock());

		Test.startTest();
		List<FSC_FirmarDocumentoUtility.SignedEnvelopeFile> result = FSC_FirmarDocumentoUtility.obtenerArchivosFirmadosEnvelope('env-files-004');
		Test.stopTest();

		System.assertEquals(1, result.size());
		System.assertEquals('Documento FileId.pdf', result[0].fileName);
		System.assertEquals('PDF FIRMADO FILEID', result[0].body.toString());
	}

	@IsTest
	static void testObtenerArchivosFirmadosEnvelope_Error() {
		Test.setMock(HttpCalloutMock.class, new EnvelopeFilesErrorMock());

		Boolean thrown = false;
		try {
			FSC_FirmarDocumentoUtility.obtenerArchivosFirmadosEnvelope('env-files-003');
		} catch (Exception e) {
			thrown = true;
		}

		System.assertEquals(true, thrown, 'Debe lanzar excepcion cuando la descarga retorna error');
	}

	private static Account createAccount(String accountName, String identification) {
		Account account = new Account(
			Name = accountName,
			ACC_NumIdentificacion__c = identification,
			ACC_Correo_Electronico_Cliente__c = 'credito@test.com'
		);
		insert account;
		return account;
	}

	private static ResidentialLoanApplication createSigningFixture() {
		Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
		Account account = new Account(
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
			FirstName = 'Cliente',
			LastName = 'Cobertura Firma',
			ACC_NumIdentificacion__c = '00123456789',
			ACC_Correo_Electronico_Cliente__c = 'credito@test.com'
		);
		insert account;
		ResidentialLoanApplication application = new ResidentialLoanApplication(
			Name = 'RLA Cobertura Firma',
			AccountId = account.Id,
			RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
				.get('FSC_Solicitud_Credito_PYME')
				.getRecordTypeId()
		);
		insert application;
		insert new ContentVersion(
			Title = 'Crédito PyMe - Cliente Cobertura Firma - 00123456789',
			PathOnClient = 'credito.pdf',
			VersionData = Blob.valueOf('PDF CREDITO'),
			FirstPublishLocationId = application.Id,
			FSC_EnviarDocumento__c = true
		);
		return application;
	}

	@IsTest
	static void shouldMarkLatestDocumentAfterSuccessfulEnvelope() {
		ResidentialLoanApplication application = createSigningFixture();
		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
		Test.startTest();
		VFS_EsignSendingEnvelope.EnvelopeResult result = FSC_FirmarDocumentoUtility.enviarPorProceso(PROCESS_CREDIT, application.Id);
		Test.stopTest();
		Assert.isTrue(result.success, 'Debe enviar el envelope del documento correcto: ' + result.message);
		ContentDocumentLink file = [
			SELECT ContentDocument.LatestPublishedVersion.FSC_EnvelopeId__c, ContentDocument.LatestPublishedVersion.FSC_FechaEnvioFirma__c
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :application.Id
			LIMIT 1
		];
		Assert.areEqual(ENVELOPE_ID, file.ContentDocument.LatestPublishedVersion.FSC_EnvelopeId__c, 'Debe guardar el envelope enviado');
		Assert.isNotNull(file.ContentDocument.LatestPublishedVersion.FSC_FechaEnvioFirma__c, 'Debe marcar la fecha de envio');
	}

	@IsTest
	static void shouldReturnAlreadySentWithoutEnqueuingAgain() {
		ResidentialLoanApplication application = createSigningFixture();
		application.FSC_EnviadoAFirmar__c = true;
		update application;
		Test.startTest();
		FSC_FirmarDocumentoUtility.SendDocumentsResult result = FSC_FirmarDocumentoUtility.enviarDocumentosFirmar('Gestionar firmas', application.Id);
		Assert.areEqual(0, Limits.getQueueableJobs(), 'No debe volver a encolar documentos');
		Test.stopTest();
		Assert.isFalse(result.documentsSent, 'No debe reenviar la solicitud');
		Assert.areEqual('La solicitud ya fue enviada a firmar.', result.message, 'Debe informar que ya fue enviada');
	}

	@IsTest
	static void shouldReadEnvelopeCompletionDate() {
		String finishedDate = '2026-10-08T15:00:00Z';
		Test.setMock(
			HttpCalloutMock.class,
			new EnvelopeFilesJsonMock(
				'{"EnvelopeStatus":"Completed","Activities":[{"Status":"InProgress"},{"Status":"Completed","FinishedDate":"' + finishedDate + '"}]}',
				200
			)
		);
		Test.startTest();
		FSC_FirmarDocumentoUtility.EnvelopeStatus result = FSC_FirmarDocumentoUtility.obtenerEstadoEnvelope(ENVELOPE_ID);
		Test.stopTest();
		Assert.isTrue(result.success, 'Debe procesar el estado del envelope');
		Assert.areEqual(finishedDate, result.envelopeFinishedDate, 'Debe usar la fecha de la actividad completada');
	}

	@IsTest
	static void shouldReadSignedFilesFromRootArray() {
		String encoded = EncodingUtil.base64Encode(Blob.valueOf(SIGNED_CONTENT));
		Test.setMock(HttpCalloutMock.class, new EnvelopeFilesJsonMock('[{"FileName":"firmado.pdf","Content":"' + encoded + '"}]', 200));
		Test.startTest();
		List<FSC_FirmarDocumentoUtility.SignedEnvelopeFile> files = FSC_FirmarDocumentoUtility.obtenerArchivosFirmadosEnvelope(ENVELOPE_ID);
		Test.stopTest();
		Assert.areEqual(1, files.size(), 'Debe descargar el archivo del array');
		Assert.areEqual(SIGNED_CONTENT, files[0].body.toString(), 'Debe decodificar el contenido');
	}

	@IsTest
	static void shouldReadSignedFilesFromRootBase64() {
		String encoded = EncodingUtil.base64Encode(Blob.valueOf(SIGNED_CONTENT));
		Test.setMock(HttpCalloutMock.class, new EnvelopeFilesJsonMock('{"Base64Content":"' + encoded + '"}', 200));
		Test.startTest();
		List<FSC_FirmarDocumentoUtility.SignedEnvelopeFile> files = FSC_FirmarDocumentoUtility.obtenerArchivosFirmadosEnvelope(ENVELOPE_ID);
		Test.stopTest();
		Assert.areEqual(1, files.size(), 'Debe reconocer el contenido Base64 en la raiz');
		Assert.areEqual(SIGNED_CONTENT, files[0].body.toString(), 'Debe decodificar el Base64 de la raiz');
	}

	@IsTest
	static void shouldRejectMissingEnvelopeId() {
		Test.startTest();
		try {
			FSC_FirmarDocumentoUtility.obtenerArchivosFirmadosEnvelope(null);
			Assert.fail('Debe rechazar el envelope ausente');
		} catch (FSC_FirmarDocumentoUtility.FSC_FirmarDocumentoUtilityException expected) {
			Assert.isTrue(expected.getMessage().contains('EnvelopeId requerido'), 'Debe identificar la entrada invalida');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldRejectSuccessfulResponseWithoutFiles() {
		Test.setMock(HttpCalloutMock.class, new EnvelopeFilesJsonMock('{"Documents":[]}', 200));
		Test.startTest();
		try {
			FSC_FirmarDocumentoUtility.obtenerArchivosFirmadosEnvelope(ENVELOPE_ID);
			Assert.fail('Debe rechazar una descarga sin archivos');
		} catch (FSC_FirmarDocumentoUtility.FSC_FirmarDocumentoUtilityException expected) {
			Assert.isTrue(expected.getMessage().contains('no devolvio archivos'), 'Debe informar la descarga vacia');
		}
		Test.stopTest();
	}
}