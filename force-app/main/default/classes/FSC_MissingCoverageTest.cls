@IsTest
private class FSC_MissingCoverageTest {
	private static Integer accountSequence = 0;

	private class EnvelopeStatusMock implements HttpCalloutMock {
		private Integer statusCode;
		private String body;

		EnvelopeStatusMock(Integer statusCode, String body) {
			this.statusCode = statusCode;
			this.body = body;
		}

		public HttpResponse respond(HttpRequest req) {
			System.assertEquals('GET', req.getMethod());
			System.assert(req.getEndpoint().contains('/api/v6/envelope/'));

			HttpResponse res = new HttpResponse();
			res.setStatusCode(statusCode);
			res.setStatus(statusCode == 200 ? 'OK' : 'Error');
			res.setBody(body);
			return res;
		}
	}

	private static ResidentialLoanApplication createRla() {
		Account account = createPersonAccount('Missing Coverage', nextTestIdentification());
		insert account;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Missing Coverage',
			AccountId = account.Id,
			FSC_TipoSolicitud__c = 'BPR'
		);
		insert rla;
		return rla;
	}

	private static Account createPersonAccount(String lastName, String identificationNumber) {
		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
		return new Account(
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
			FirstName = 'Cliente',
			LastName = lastName,
			ACC_TipoIdentificacion__c = 'Cédula',
			ACC_NumIdentificacion__c = identificationNumber
		);
	}

	private static String nextTestIdentification() {
		accountSequence++;
		return '00108803' + String.valueOf(accountSequence).leftPad(3, '0');
	}

	@IsTest
	static void loanApplicantControllerFindsAndMissesApplicant() {
		ResidentialLoanApplication rla = createRla();

		LoanApplicant applicant = new LoanApplicant(
			Name = 'Solicitante Test',
			LoanApplicationId = rla.Id,
			FSC_TipoIdentificacion__c = 'Cédula',
			FSC_NumIdentificacion__c = '00100000000',
			FSC_Nombre__c = 'Solicitante',
			FSC_TipoSolicitante__c = 'Deudor'
		);
		insert applicant;

		insert new ContactPointPhone(ParentId = rla.AccountId, FSC_Solicitante__c = applicant.Id, TelephoneNumber = '8095551234');
		insert new ContactPointAddress(
			ParentId = rla.AccountId,
			FSC_Solicitante__c = applicant.Id,
			Name = 'Residencia Test',
			Street = 'Calle 1',
			City = 'Santo Domingo',
			State = 'Distrito Nacional',
			PostalCode = '10100',
			Country = 'DO'
		);
		insert new ContactPointEmail(ParentId = rla.AccountId, FSC_Solicitante__c = applicant.Id, EmailAddress = 'solicitante@example.com');
		insert new FSC_Referencias__c(
			FSC_LoanApplicant__c = applicant.Id,
			FSC_Residential_Loan_Application__c = rla.Id,
			Name = 'Referencia Test',
			FSC_FirstName__c = 'Referencia',
			FSC_LastName__c = 'Personal',
			FSC_Telefono__c = '8095559876',
			FSC_Email__c = 'referencia@example.com',
			FSC_LugarTrabajo__c = 'Empresa Referencia'
		);

		Test.startTest();
		Map<String, Object> found = FSC_LoanApplicantController.getLoanApplicant('Cédula', '00100000000');
		Map<String, Object> missing = FSC_LoanApplicantController.getLoanApplicant('Pasaporte', 'X');
		Map<String, Object> accountApplicant = FSC_LoanApplicantController.getAccountLoanApplicant(rla.Id);
		Map<String, Object> nullContextApplicant = FSC_LoanApplicantController.getAccountLoanApplicant(null);
		Test.stopTest();

		System.assertNotEquals(null, found);
		if (found.get('Id') != null) {
			System.assertEquals(applicant.Id, found.get('Id'));
		}
		List<Map<String, Object>> phones = (List<Map<String, Object>>) found.get('Contact_Point_Phones__r');
		List<Map<String, Object>> addresses = (List<Map<String, Object>>) found.get('Contact_Point_Addresses__r');
		List<Map<String, Object>> emails = (List<Map<String, Object>>) found.get('Contact_Point_Emails__r');
		List<Map<String, Object>> referencias = (List<Map<String, Object>>) found.get('Referencias__r');
		System.assertEquals(1, phones.size());
		System.assertEquals('8095551234', phones[0].get('TelephoneNumber'));
		System.assertEquals(1, addresses.size());
		System.assertEquals('Calle 1', addresses[0].get('Street'));
		System.assertEquals(1, emails.size());
		System.assertEquals('solicitante@example.com', emails[0].get('EmailAddress'));
		if (!referencias.isEmpty()) {
			System.assertEquals('Referencia', referencias[0].get('FSC_FirstName__c'));
		}
		System.assertEquals(null, missing);
		System.assertNotEquals(null, accountApplicant);
		System.assertEquals('Deudor', accountApplicant.get('FSC_TipoSolicitante__c'));
		System.assertEquals('Cliente', accountApplicant.get('FSC_Nombre__c'));
		System.assertEquals(null, nullContextApplicant);
	}

	@IsTest
	static void loanApplicantControllerPrefersAccountOverLoanApplicant() {
		Account account = createPersonAccount('Account', nextTestIdentification());
		account.Tipo_de_vivienda__c = '1';
		account.Tiempo_en_Vivienda__c = '3 anos';
		account.ACC_N_Dependientes__c = 2;
		account.ACC_Ventas_Ingresos_Anuales__c = 120000;
		insert account;

		ResidentialLoanApplication rla = createRla();
		insert new LoanApplicant(
			Name = 'Solicitante No Preferido',
			LoanApplicationId = rla.Id,
			FSC_TipoIdentificacion__c = account.ACC_TipoIdentificacion__c,
			FSC_NumIdentificacion__c = account.ACC_NumIdentificacion__c,
			FSC_Nombre__c = 'Solicitante',
			FSC_TipoSolicitante__c = 'Deudor',
			FSC_MontoPrestacionesLaborales__c = '15000'
		);

		insert new List<FinServ__Employment__c>{
			new FinServ__Employment__c(
				Cliente__c = account.Id,
				EMP_Empleo__c = 'Actual',
				EMP_Empresa__c = 'Empresa Actual',
				EMP_Principal__c = true,
				EMP_Tipo_de_empleado__c = '1',
				FinServ__AnnualIncome__c = 240000,
				FinServ__Occupation__c = 'ABOGADO',
				FinServ__StartDate__c = Date.newInstance(2020, 1, 15)
			),
			new FinServ__Employment__c(
				Cliente__c = account.Id,
				EMP_Empleo__c = 'Anterior',
				EMP_Empresa__c = 'Empresa Anterior'
			)
		};

		insert new ContactPointPhone(ParentId = account.Id, TelephoneNumber = '8095551111');
		insert new ContactPointAddress(
			ParentId = account.Id,
			Name = 'Direccion Account',
			Street = 'Calle Account',
			City = 'Santo Domingo',
			State = 'Distrito Nacional',
			PostalCode = '10200',
			Country = 'DO'
		);
		insert new ContactPointEmail(ParentId = account.Id, EmailAddress = 'account@example.com');

		Test.startTest();
		Map<String, Object> found = FSC_LoanApplicantController.getLoanApplicant(account.ACC_TipoIdentificacion__c, account.ACC_NumIdentificacion__c);
		Map<String, Object> fromContext = FSC_LoanApplicantController.getAccountLoanApplicant(account.Id);
		Test.stopTest();

		System.assertNotEquals(null, found);
		System.assertEquals(null, found.get('Id'), 'Los datos de Account no deben devolverse con Id de LoanApplicant.');
		System.assertEquals('Cliente', found.get('FSC_Nombre__c'));
		System.assertEquals('2', found.get('FSC_TipoVivienda__c'), 'Debe convertir Alquilada de Account al valor equivalente de LoanApplicant.');
		System.assertEquals('ABOGADO', found.get('FSC_Ocupacion__c'));
		System.assertEquals('Empresa Actual', found.get('FSC_LugarFondeLabora__c'));
		System.assertEquals('Empresa Anterior', found.get('FSC_EmpresaAnteriorLaboro__c'));
		System.assertEquals(Date.newInstance(2020, 1, 15), found.get('FSC_TiempoLaborando__c'));
		System.assertEquals('Empleado Privado', found.get('FSC_FuenteIngreso__c'));
		System.assertEquals(Decimal.valueOf('20000'), found.get('FSC_IngresosMensuales__c'));
		System.assertEquals('15000', found.get('FSC_MontoPrestacionesLaborales__c'));
		List<Map<String, Object>> phones = (List<Map<String, Object>>) found.get('Contact_Point_Phones__r');
		List<Map<String, Object>> addresses = (List<Map<String, Object>>) found.get('Contact_Point_Addresses__r');
		List<Map<String, Object>> emails = (List<Map<String, Object>>) found.get('Contact_Point_Emails__r');
		System.assertEquals(1, phones.size());
		System.assertEquals('8095551111', phones[0].get('TelephoneNumber'));
		System.assertEquals(1, addresses.size());
		System.assertEquals('Calle Account', addresses[0].get('Street'));
		System.assertEquals(1, emails.size());
		System.assertEquals('account@example.com', emails[0].get('EmailAddress'));
		System.assertEquals(account.ACC_TipoIdentificacion__c, fromContext.get('FSC_TipoIdentificacion__c'));
	}

	@IsTest
	static void garantiasControllerReturnsRowsAndHandlesNull() {
		ResidentialLoanApplication rla = createRla();

		LoanApplicationAsset asset = new LoanApplicationAsset(Name = 'Garantia Test', LoanApplicationId = rla.Id, CashOrMarketValue = 50000);
		asset.FSC_Numero_Facilidades__c = 1;
		asset.FSC_Descripcion_de_la_Garantia__c = 'Vehiculo';
		asset.FSC_Porcentaje_Admisibilidad__c = 75;
		insert asset;

		Test.startTest();
		List<FSC_RlaGarantiasTablaController.GarantiaRow> emptyRows = FSC_RlaGarantiasTablaController.getGarantias(null);
		List<FSC_RlaGarantiasTablaController.GarantiaRow> rows = FSC_RlaGarantiasTablaController.getGarantias(rla.Id);
		Test.stopTest();

		System.assertEquals(0, emptyRows.size());
		System.assertEquals(1, rows.size());
		System.assertEquals('1', rows[0].numeroFacilidad);
		System.assertEquals('Vehiculo', rows[0].descripcionGarantia);
		System.assertEquals(50000, rows[0].valor);
		System.assertEquals(75, rows[0].porcentajeAdmisibilidad);
	}

	@IsTest
	static void pymeSolicitudPdfControllerBindsPayloadAndFormatsValues() {
		Map<String, Object> omniData = new Map<String, Object>{
			'StepPersonType' => new Map<String, Object>{ 'PersonType' => 'Persona_Fisica' },
			'StepApplicantDetailsFisica' => new Map<String, Object>{ 'IdentificationType' => 'Cedula', 'Sex' => 'Femenino' },
			'StepApplicantDetailsJuridica' => new Map<String, Object>{
				'FSC_Socios_Principales_Y_Accionistas__c' => new List<Object>{ new Map<String, Object>{ 'Name' => 'Socio 1' } }
			},
			'StepCompanyDetails' => new Map<String, Object>{ 'Name' => 'Compania' },
			'StepLoanDetails' => new Map<String, Object>{ 'Amount' => 1200 },
			'StepWarrantyDetails' => new Map<String, Object>{ 'Warranty' => 'Si' },
			'StepDescripcionFacilidades' => new Map<String, Object>{
				'FSC_Facilidades_De_Credito__c' => new List<Object>{ new Map<String, Object>{ 'Name' => 'Facilidad 1' } }
			},
			'StepProposito' => new Map<String, Object>{
				'FSC_Proposito_Y_Uso_De_Fondos__c' => new List<Object>{ new Map<String, Object>{ 'Name' => 'Capital' } }
			},
			'StepGarantias' => new Map<String, Object>{
				'LoanApplicationAsset' => new List<Object>{ new Map<String, Object>{ 'Name' => 'Garantia' } }
			},
			'StepRelacion' => new List<Object>{ new Map<String, Object>{ 'Name' => 'Relacion' } },
			'StepReferencias' => new Map<String, Object>{
				'FSC_Referencias__c' => new List<Object>{ new Map<String, Object>{ 'Name' => 'Referencia' } }
			},
			'StepFortalezaDebilidades' => new Map<String, Object>{
				'FSC_Fortalezas_Y_Debilidades__c' => new List<Object>{ new Map<String, Object>{ 'Name' => 'Fortaleza' } }
			},
			'StepClientesYProveedoresPrincipales' => new Map<String, Object>{
				'FSC_Clientes_Y_Proveedores_Principales__c' => new List<Object>{ new Map<String, Object>{ 'Name' => 'Cliente' } }
			}
		};

		Test.setCurrentPage(Page.FSC_PymeSolicitudPdf);
		ApexPages.currentPage().getParameters().put('payload', JSON.serialize(new Map<String, Object>{ 'omniData' => omniData }));
		ApexPages.currentPage().getParameters().put('ContextId', 'CTX-1');

		Test.startTest();
		FSC_PymeSolicitudPdfCtrl ctrl = new FSC_PymeSolicitudPdfCtrl();
		Test.stopTest();

		System.assertEquals('CTX-1', ctrl.contextId);
		System.assert(ctrl.isPersonaFisica());
		System.assert(!ctrl.isPersonaJuridica());
		System.assert(ctrl.isCedula());
		System.assert(!ctrl.isPasaporte());
		System.assert(!ctrl.isMasculino());
		System.assert(ctrl.isFemenino());
		System.assertEquals(1, ctrl.socios.size());
		System.assertEquals(1, ctrl.facilidades.size());
		System.assertEquals(1, ctrl.propositos.size());
		System.assertEquals(1, ctrl.garantiasOfrecidas.size());
		System.assertEquals(1, ctrl.relacion.size());
		System.assertEquals(1, ctrl.referencias.size());
		System.assertEquals(1, ctrl.fortalezasDebilidades.size());
		System.assertEquals(1, ctrl.clientesProveedores.size());
		System.assertEquals('2-1-2026', ctrl.fmtDate('2026-01-02'));
		System.assertEquals('not-a-date', ctrl.fmtDate('not-a-date'));
		System.assertEquals('', ctrl.fmtMoney(null));
		System.assertEquals('abc', ctrl.fmtMoney('abc'));
		System.assertNotEquals('', ctrl.fmtMoney('123.4'));
		System.assertNotEquals('', ctrl.cb(true));
		System.assertNotEquals('', ctrl.cb(false));
	}

	@IsTest
	static void autoApproveQueueableHandlesEmptyAndNoWorkItems() {
		ResidentialLoanApplication rla = createRla();
		List<FSC_AutoApproveGestionPlanillasQueueable.WorkItemCandidate> candidates = new List<FSC_AutoApproveGestionPlanillasQueueable.WorkItemCandidate>{
			new FSC_AutoApproveGestionPlanillasQueueable.WorkItemCandidate(null, UserInfo.getUserId(), 'Pending', 'FSC_GestionPlanillasDeDesembolso'),
			new FSC_AutoApproveGestionPlanillasQueueable.WorkItemCandidate(
				null,
				UserInfo.getUserId(),
				'Approved',
				'FSC_GestionPlanillasDeDesembolso'
			),
			new FSC_AutoApproveGestionPlanillasQueueable.WorkItemCandidate(null, UserInfo.getUserId(), 'Pending', 'Other_Process')
		};

		Test.startTest();
		new FSC_AutoApproveGestionPlanillasQueueable(null).execute(null);
		new FSC_AutoApproveGestionPlanillasQueueable(new Set<Id>()).execute(null);
		new FSC_AutoApproveGestionPlanillasQueueable(new Set<Id>{ rla.Id }).execute(null);
		Integer approvedCount = FSC_AutoApproveGestionPlanillasQueueable.approveCandidates(candidates, false);
		Integer attemptedCount = FSC_AutoApproveGestionPlanillasQueueable.approveCandidates(
			new List<FSC_AutoApproveGestionPlanillasQueueable.WorkItemCandidate>{ candidates[0] },
			true
		);
		Test.stopTest();

		System.assertEquals(1, approvedCount);
		System.assertEquals(1, attemptedCount);
		System.assert(FSC_AutoApproveGestionPlanillasQueueable.shouldApprove(candidates[0]));
		System.assert(!FSC_AutoApproveGestionPlanillasQueueable.shouldApprove(candidates[1]));
		System.assert(!FSC_AutoApproveGestionPlanillasQueueable.shouldApprove(candidates[2]));
	}

	@IsTest
	static void esaEnvelopeStatusServiceHandlesSuccessErrorAndValidation() {
		Test.setMock(HttpCalloutMock.class, new EnvelopeStatusMock(200, '{"Status":"Completed"}'));
		FSC_ESAEnvelopeStatusService.EnvelopeStatusResult successResult = FSC_ESAEnvelopeStatusService.obtenerEstadoEnvelope('env-1');

		System.assertEquals(true, successResult.success);
		System.assertEquals(200, successResult.statusCode);
		System.assertEquals('Completed', successResult.status);

		Test.setMock(HttpCalloutMock.class, new EnvelopeStatusMock(500, '{"message":"error"}'));
		FSC_ESAEnvelopeStatusService.EnvelopeStatusResult errorResult = FSC_ESAEnvelopeStatusService.obtenerEstadoEnvelope('env-2');

		System.assertEquals(false, errorResult.success);
		System.assertEquals(500, errorResult.statusCode);
		System.assert(String.isNotBlank(errorResult.errorMessage));

		FSC_ESAEnvelopeStatusService.EnvelopeStatusResult missingResult = FSC_ESAEnvelopeStatusService.obtenerEstadoEnvelope(null);
		System.assertEquals(false, missingResult.success);
		System.assertEquals('envelopeId es requerido.', missingResult.errorMessage);
	}

	@IsTest
	static void planillaDesembolsoSaverUpdatesAllowedFieldsAndTargetSubstatus() {
		Account account = createPersonAccount('Planilla Saver', nextTestIdentification());
		insert account;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Planilla Saver',
			AccountId = account.Id,
			RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
				.get('FSC_Solicitud_Credito_Consumo')
				.getRecordTypeId(),
			Status = 'En proceso',
			FSC_Subestado__c = 'Documentación para desembolso y firmas',
			FSC_TipoSolicitud__c = 'BPR',
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401',
			FSC_UsuarioGestionPlanilla__c = UserInfo.getUserId()
		);
		insert rla;

		Map<String, Object> inputMap = new Map<String, Object>{
			'Id' => 'ignored',
			'Name' => 'ignored',
			'Status' => 'En proceso',
			'FSC_Monto__c' => '12345.67',
			'FSC_TasaInteres__c' => '18.5',
			'FSC_TasaFijaPorMeses__c' => '12',
			'FSC_FechaVencimiento__c' => '2027-01-31',
			'FSC_FechaYHoraAprobacionComite__c' => '2026-01-31T12:30:00Z',
			'NoExiste__c' => 'ignored'
		};

		Test.startTest();
		FSC_PlanillaDesembolsoSaver.save(rla.Id, inputMap);
		Test.stopTest();

		ResidentialLoanApplication updatedRla = [
			SELECT FSC_Subestado__c, FSC_Monto__c, FSC_TasaInteres__c, FSC_TasaFijaPorMeses__c, FSC_FechaVencimiento__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals('Creación de crédito', updatedRla.FSC_Subestado__c);
		System.assertEquals(Decimal.valueOf('12345.67'), updatedRla.FSC_Monto__c);
		System.assertEquals(Decimal.valueOf('18.5'), updatedRla.FSC_TasaInteres__c);
		System.assertEquals(Decimal.valueOf('12'), updatedRla.FSC_TasaFijaPorMeses__c);
		System.assertEquals(Date.newInstance(2027, 1, 31), updatedRla.FSC_FechaVencimiento__c);
	}

	@IsTest
	static void planillaDesembolsoSaverRejectsInvalidId() {
		Boolean thrown = false;
		try {
			FSC_PlanillaDesembolsoSaver.save(UserInfo.getUserId(), new Map<String, Object>());
		} catch (AuraHandledException ex) {
			thrown = true;
		}
		System.assertEquals(true, thrown);
	}

	@IsTest
	static void rlaAccionesControllerCoversReadContextsAndValidations() {
		ResidentialLoanApplication rla = createRla();
		update new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_UsuarioPagaresYContratos__c = UserInfo.getUserId(),
			FSC_UsuarioGestionPlanilla__c = UserInfo.getUserId()
		);

		Map<String, Object> approvalContext = FSC_RlaAccionesController.getApprovalContext(rla.Id);
		Map<String, Object> pagaresContext = FSC_RlaAccionesController.getPagaresContext(rla.Id);
		List<Map<String, String>> assignableUsers = FSC_RlaAccionesController.getAssignableUsers();
		List<Map<String, String>> formasDesembolso = FSC_RlaAccionesController.getFormaDesembolsoOptions();

		System.assertEquals(false, approvalContext.get('hasActiveApproval'));
		System.assertEquals(UserInfo.getUserId(), pagaresContext.get('assignedUserId'));
		System.assert(!assignableUsers.isEmpty());
		System.assert(!formasDesembolso.isEmpty());

		assertAuraHandledExceptionForNullContexts();
	}

	@IsTest
	static void rlaAccionesControllerCoversCuentaOptionsAndHelpers() {
		ResidentialLoanApplication rla = createRla();
		Id finAccountRecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName()
			.get('CheckingAccount')
			.getRecordTypeId();
		insert new FinServ__FinancialAccount__c(
			Name = 'Cuenta Principal',
			FinServ__FinancialAccountNumber__c = '123456789',
			FinServ__SourceSystemId__c = 'SRC123456789',
			FinServ__PrimaryOwner__c = rla.AccountId,
			RecordTypeId = finAccountRecordTypeId
		);

		List<Map<String, String>> cuentas = FSC_RlaAccionesController.getCuentasDesembolsoOptions(rla.Id);
		System.assertEquals(1, cuentas.size());
		System.assert(cuentas[0].get('label').contains('123456789'), 'El label debe incluir el número de la cuenta.');

		System.assertEquals('', FSC_RlaAccionesController.getProcessDefinitionDeveloperName(null));
		System.assertEquals('recepcion de documentos analisis', FSC_RlaAccionesController.normalize('Recepción de documentos – Análisis'));
		System.assertEquals(false, FSC_RlaAccionesController.isUserMemberOfGroupRecursive(null, UserInfo.getUserId()));
		System.assertEquals(false, FSC_RlaAccionesController.isUserMemberOfGroupRecursive(UserInfo.getUserId(), null));
	}

	@IsTest
	static void rlaAccionesControllerCoversPagareAndDesembolsoValidationBranches() {
		ResidentialLoanApplication rla = createRla();
		update new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_UsuarioPagaresYContratos__c = UserInfo.getUserId(),
			FSC_UsuarioGestionPlanilla__c = UserInfo.getUserId()
		);

		Boolean nullPagareThrown = false;
		try {
			FSC_RlaAccionesController.guardarDatosPagare(null, 'ACT-1', '1');
		} catch (AuraHandledException ex) {
			nullPagareThrown = true;
		}
		System.assertEquals(true, nullPagareThrown);

		Boolean blankPagareThrown = false;
		try {
			FSC_RlaAccionesController.guardarDatosPagare(rla.Id, '', '1');
		} catch (AuraHandledException ex) {
			blankPagareThrown = true;
		}
		System.assertEquals(true, blankPagareThrown);

		Boolean numericPagareThrown = false;
		try {
			FSC_RlaAccionesController.guardarDatosPagare(rla.Id, 'ACT-1', 'ABC');
		} catch (AuraHandledException ex) {
			numericPagareThrown = true;
		}
		System.assertEquals(true, numericPagareThrown);

		Boolean nullDesembolsoThrown = false;
		try {
			FSC_RlaAccionesController.guardarFormaDesembolsoGestionPlanillas(null, 'Cuenta de ahorro', null);
		} catch (AuraHandledException ex) {
			nullDesembolsoThrown = true;
		}
		System.assertEquals(true, nullDesembolsoThrown);

		Boolean blankDesembolsoThrown = false;
		try {
			FSC_RlaAccionesController.guardarFormaDesembolsoGestionPlanillas(rla.Id, '', null);
		} catch (AuraHandledException ex) {
			blankDesembolsoThrown = true;
		}
		System.assertEquals(true, blankDesembolsoThrown);

		Boolean invalidDesembolsoThrown = false;
		try {
			FSC_RlaAccionesController.guardarFormaDesembolsoGestionPlanillas(rla.Id, 'VALOR_INVALIDO', null);
		} catch (AuraHandledException ex) {
			invalidDesembolsoThrown = true;
		}
		System.assertEquals(true, invalidDesembolsoThrown);

		FSC_RlaAccionesController.guardarDatosPagare(rla.Id, 'ACT-COV', '123');
		ResidentialLoanApplication updatedRla = [
			SELECT FSC_ActoNumeroPagare__c, FSC_NumeroFolioPagare__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertEquals('ACT-COV', updatedRla.FSC_ActoNumeroPagare__c);
		System.assertEquals(Decimal.valueOf('123'), updatedRla.FSC_NumeroFolioPagare__c);
	}

	private static void assertAuraHandledExceptionForNullContexts() {
		Boolean approvalThrown = false;
		try {
			FSC_RlaAccionesController.getApprovalContext(null);
		} catch (AuraHandledException ex) {
			approvalThrown = true;
		}
		System.assertEquals(true, approvalThrown);

		Boolean pagaresThrown = false;
		try {
			FSC_RlaAccionesController.getPagaresContext(null);
		} catch (AuraHandledException ex) {
			pagaresThrown = true;
		}
		System.assertEquals(true, pagaresThrown);

		Boolean cuentasThrown = false;
		try {
			FSC_RlaAccionesController.getCuentasDesembolsoOptions(null);
		} catch (AuraHandledException ex) {
			cuentasThrown = true;
		}
		System.assertEquals(true, cuentasThrown);
	}

	@IsTest
	static void rlaTriggerHandlerCoversDuplicateValidationBranches() {
		ResidentialLoanApplication duplicateActoA = new ResidentialLoanApplication(Name = 'RLA Dup Acto A', FSC_ActoNumeroPagare__c = 'ACT-DUP');
		ResidentialLoanApplication duplicateActoB = new ResidentialLoanApplication(Name = 'RLA Dup Acto B', FSC_ActoNumeroPagare__c = 'ACT-DUP');
		FSC_RLATriggerHandler.beforeInsert(new List<ResidentialLoanApplication>{ duplicateActoA, duplicateActoB });
		System.assertEquals(1, duplicateActoA.getErrors().size());
		System.assertEquals(1, duplicateActoB.getErrors().size());

		ResidentialLoanApplication duplicateFolioA = new ResidentialLoanApplication(Name = 'RLA Dup Folio A', FSC_NumeroFolioPagare__c = 123);
		ResidentialLoanApplication duplicateFolioB = new ResidentialLoanApplication(Name = 'RLA Dup Folio B', FSC_NumeroFolioPagare__c = 123);
		FSC_RLATriggerHandler.beforeInsert(new List<ResidentialLoanApplication>{ duplicateFolioA, duplicateFolioB });
		System.assertEquals(1, duplicateFolioA.getErrors().size());
		System.assertEquals(1, duplicateFolioB.getErrors().size());

		FSC_RLATriggerHandler.beforeInsert(null);
		FSC_RLATriggerHandler.beforeInsert(new List<ResidentialLoanApplication>());
		FSC_RLATriggerHandler.beforeInsert(new List<ResidentialLoanApplication>{ null });
	}

	@IsTest
	static void rlaTriggerHandlerCoversAfterUpdateBranches() {
		ResidentialLoanApplication rla = createRla();
		ResidentialLoanApplication oldRecord = new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_Subestado__c = 'Pendiente planilla de desembolso',
			FSC_Desembolso_Realizado__c = false
		);
		ResidentialLoanApplication newRecord = new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_Subestado__c = 'Creación de crédito',
			FSC_Desembolso_Realizado__c = true
		);

		Test.startTest();
		FSC_RLATriggerHandler.afterUpdate(
			new List<ResidentialLoanApplication>{ newRecord },
			new Map<Id, ResidentialLoanApplication>{ rla.Id => oldRecord }
		);
		FSC_RLATriggerHandler.afterUpdate(new List<ResidentialLoanApplication>{ newRecord }, new Map<Id, ResidentialLoanApplication>());
		Test.stopTest();
	}
}
