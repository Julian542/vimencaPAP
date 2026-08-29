@IsTest
private class FSC_NuevoDocumentoEnvelope_Test {
	private class PrepareFileMock implements HttpCalloutMock {
		private Integer statusCode;
		private String body;

		PrepareFileMock() {
			this(
				200,
					'{"Activities":[{"Action":{"Sign":{"Elements":{"Signatures":[' +
						'{"ElementId":"FIRMASOLICITANTE","DocumentNumber":2,"FieldDefinition":{"Position":{"PageNumber":5,"X":111,"Y":222},"Size":{"Width":333,"Height":44}}},' +
						'{"ElementId":"FIRMALOANAPPLICANT1","DocumentNumber":2,"FieldDefinition":{"Position":{"PageNumber":6,"X":211,"Y":322},"Size":{"Width":433,"Height":54}}},' +
						'{"ElementId":"FIRMAOFICIALNEGOCIO","DocumentNumber":2,"FieldDefinition":{"Position":{"PageNumber":7,"X":244,"Y":422},"Size":{"Width":160,"Height":60}}}' +
					']}}}}]}'
			);
		}

		PrepareFileMock(Integer statusCode, String body) {
			this.statusCode = statusCode;
			this.body = body;
		}

		public HttpResponse respond(HttpRequest req) {
			System.assertEquals('POST', req.getMethod());
			System.assert(req.getEndpoint().contains('/Api/v6/file/prepare'));

			HttpResponse res = new HttpResponse();
			res.setStatusCode(statusCode);
			res.setBody(body);
			return res;
		}
	}

	private static Integer accountSequence = 0;

	@TestSetup
	static void setupData() {
		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
		Account acc = new Account(
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
			FirstName = 'Cuenta',
			LastName = 'Test',
			ACC_TipoIdentificacion__c = 'Cédula',
			ACC_NumIdentificacion__c = nextTestIdentification(),
			ACC_Correo_Electronico_Cliente__c = 'cliente@test.com'
		);
		insert acc;
		insert new ContactPointEmail(ParentId = acc.Id, EmailAddress = 'cliente@test.com', IsPrimary = true);

		Date actaDate = Date.today();
		DateTime approvedDt = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 14, 30, 0);
		ResidentialLoanApplication rla = new ResidentialLoanApplication();
		rla.AccountId = acc.Id;
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
	}

	private static String nextTestIdentification() {
		accountSequence++;
		return '00108803' + String.valueOf(accountSequence).leftPad(3, '0');
	}

	private static ResidentialLoanApplication getRla() {
		return [
			SELECT Id, AccountId, Account.FirstName, Account.LastName, Account.ACC_Correo_Electronico_Cliente__c
			FROM ResidentialLoanApplication
			LIMIT 1
		];
	}

	private static VFS_EsignSendingEnvelope.EnvelopeSignature getOnlySignature(List<VFS_EsignSendingEnvelope.EnvelopeAction> actions) {
		System.assertEquals(1, actions.size());
		System.assertNotEquals(null, actions[0].Sign);
		System.assertEquals('firmante', actions[0].Sign.SigningGroup);
		System.assertEquals(1, actions[0].Sign.Elements.Signatures.size());
		return actions[0].Sign.Elements.Signatures[0];
	}

	private static LoanApplicant createFirmante(ResidentialLoanApplication rla) {
		LoanApplicant applicant = new LoanApplicant(
			Name = 'Co Deudor Test',
			LoanApplicationId = rla.Id,
			FSC_TipoSolicitante__c = 'Co-Deudor',
			FSC_TipoIdentificacion__c = 'Cédula',
			FSC_NumIdentificacion__c = '00112345678',
			FSC_Nombre__c = 'Codeudor',
			FSC_PrimerApellido__c = 'Test'
		);
		insert applicant;

		insert new ContactPointEmail(
			EmailAddress = 'codeudor@test.com',
			FSC_Solicitante__c = applicant.Id
		);

		return applicant;
	}

	private static void assertSignature(
		VFS_EsignSendingEnvelope.EnvelopeSignature signature,
		Integer documentNumber,
		Integer pageNumber,
		Integer x,
		Integer y,
		Integer width,
		Integer height
	) {
		System.assertEquals('sig_nuevo_documento', signature.ElementId);
		System.assertEquals(documentNumber, signature.DocumentNumber);
		System.assertEquals(pageNumber, signature.FieldDefinition.Position.PageNumber);
		System.assertEquals(x, signature.FieldDefinition.Position.X);
		System.assertEquals(y, signature.FieldDefinition.Position.Y);
		System.assertEquals(width, signature.FieldDefinition.Size.Width);
		System.assertEquals(height, signature.FieldDefinition.Size.Height);
	}

	@IsTest
	static void testCrearFirmasCreditoPyme() {
		ResidentialLoanApplication rla = getRla();

		List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = FSC_NuevoDocumentoEnvelope.crearFirmas(rla.Id, 'CREDITO_PYME');

		System.assertEquals(2, actions.size());
		assertSignature(getOnlySignature(new List<VFS_EsignSendingEnvelope.EnvelopeAction>{ actions[0] }), 1, 3, 238, 160, 120, 40);
		System.assertEquals('oficial_negocio', actions[1].Sign.SigningGroup);
	}

	@IsTest
	static void testCrearFirmasPagare() {
		ResidentialLoanApplication rla = getRla();

		List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = FSC_NuevoDocumentoEnvelope.crearFirmas(rla.Id, 'PAGARE');

		assertSignature(getOnlySignature(actions), 1, 3, 235, 370, 160, 60);
	}

	@IsTest
	static void testCrearFirmasUsaMarcadoresPreparados() {
		ResidentialLoanApplication rla = getRla();
		createFirmante(rla);
		VFS_EsignSendingEnvelope.EnvelopeDocument document = new VFS_EsignSendingEnvelope.EnvelopeDocument();
		document.FileId = 'file-1';
		document.DocumentNumber = 1;
		Test.setMock(HttpCalloutMock.class, new PrepareFileMock());

		Test.startTest();
		FSC_NuevoDocumentoEnvelope.permitirMarcadoresEnTest = true;
		List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = FSC_NuevoDocumentoEnvelope.crearFirmas(
			rla.Id,
			'CREDITO_PYME',
			new List<VFS_EsignSendingEnvelope.EnvelopeDocument>{ document }
		);
		FSC_NuevoDocumentoEnvelope.permitirMarcadoresEnTest = false;
		Test.stopTest();

		System.assertEquals(3, actions.size());
		assertSignature(getOnlySignature(new List<VFS_EsignSendingEnvelope.EnvelopeAction>{ actions[0] }), 2, 5, 111, 222, 333, 44);
		System.assertEquals('firmante_1', actions[1].Sign.SigningGroup);
		System.assertEquals('sig_firmaloanapplicant1', actions[1].Sign.Elements.Signatures[0].ElementId);
			System.assertEquals(2, actions[1].Sign.Elements.Signatures[0].DocumentNumber);
			System.assertEquals(6, actions[1].Sign.Elements.Signatures[0].FieldDefinition.Position.PageNumber);
			System.assertEquals('oficial_negocio', actions[2].Sign.SigningGroup);
			System.assertEquals(7, actions[2].Sign.Elements.Signatures[0].FieldDefinition.Position.PageNumber);
			System.assertEquals(244, actions[2].Sign.Elements.Signatures[0].FieldDefinition.Position.X);
			System.assertEquals(422, actions[2].Sign.Elements.Signatures[0].FieldDefinition.Position.Y);
		}

	@IsTest
	static void testCrearFirmasDocumentoSinFileId() {
		ResidentialLoanApplication rla = getRla();
		VFS_EsignSendingEnvelope.EnvelopeDocument document = new VFS_EsignSendingEnvelope.EnvelopeDocument();
		document.DocumentNumber = 1;

		try {
			FSC_NuevoDocumentoEnvelope.permitirMarcadoresEnTest = true;
			FSC_NuevoDocumentoEnvelope.crearFirmas(rla.Id, 'CREDITO_PYME', new List<VFS_EsignSendingEnvelope.EnvelopeDocument>{ document });
			System.assert(false);
		} catch (Exception e) {
			System.assert(e.getMessage().contains('FileId'));
		} finally {
			FSC_NuevoDocumentoEnvelope.permitirMarcadoresEnTest = false;
		}
	}

	@IsTest
	static void testCrearFirmasDocumentoPreparadoErrorHttp() {
		ResidentialLoanApplication rla = getRla();
		VFS_EsignSendingEnvelope.EnvelopeDocument document = new VFS_EsignSendingEnvelope.EnvelopeDocument();
		document.FileId = 'file-error';
		document.DocumentNumber = 1;
		Test.setMock(HttpCalloutMock.class, new PrepareFileMock(500, 'error'));

		try {
			Test.startTest();
			FSC_NuevoDocumentoEnvelope.permitirMarcadoresEnTest = true;
			FSC_NuevoDocumentoEnvelope.crearFirmas(rla.Id, 'CREDITO_PYME', new List<VFS_EsignSendingEnvelope.EnvelopeDocument>{ document });
			System.assert(false);
		} catch (Exception e) {
			System.assert(e.getMessage().contains('HTTP 500'));
		} finally {
			FSC_NuevoDocumentoEnvelope.permitirMarcadoresEnTest = false;
			Test.stopTest();
		}
	}

	@IsTest
	static void testCrearFirmasDocumentoPreparadoSinMarcador() {
		ResidentialLoanApplication rla = getRla();
		VFS_EsignSendingEnvelope.EnvelopeDocument document = new VFS_EsignSendingEnvelope.EnvelopeDocument();
		document.FileId = 'file-empty';
		document.DocumentNumber = 1;
		Test.setMock(HttpCalloutMock.class, new PrepareFileMock(200, '{"Activities":[]}'));

		try {
			Test.startTest();
			FSC_NuevoDocumentoEnvelope.permitirMarcadoresEnTest = true;
			FSC_NuevoDocumentoEnvelope.crearFirmas(rla.Id, 'CREDITO_PYME', new List<VFS_EsignSendingEnvelope.EnvelopeDocument>{ document });
			System.assert(false);
		} catch (Exception e) {
			System.assert(e.getMessage().contains('FIRMASOLICITANTE'));
		} finally {
			FSC_NuevoDocumentoEnvelope.permitirMarcadoresEnTest = false;
			Test.stopTest();
		}
	}

	@IsTest
	static void testCrearFirmasProcesoInvalido() {
		ResidentialLoanApplication rla = getRla();

		try {
			FSC_NuevoDocumentoEnvelope.crearFirmas(rla.Id, 'INVALIDO');
			System.assert(false);
		} catch (Exception e) {
			System.assert(e.getMessage().contains('No existe'));
		}
	}
}
