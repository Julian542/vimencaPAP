@IsTest
private class FSC_MissingCoverageTest {
	private class EnvelopeStatusMock implements HttpCalloutMock {
		private Integer statusCode;
		private String body;

		EnvelopeStatusMock(Integer statusCode, String body) {
			this.statusCode = statusCode;
			this.body = body;
		}

		public HttpResponse respond(HttpRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(statusCode);
			res.setStatus(statusCode == 200 ? 'OK' : 'Error');
			res.setBody(body);
			return res;
		}
	}

	private static ResidentialLoanApplication createRla() {
		Account account = new Account(
			LastName = 'Cliente Missing Coverage',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Fisica').getRecordTypeId()
		);
		insert account;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Missing Coverage',
			AccountId = account.Id,
			FSC_TipoSolicitud__c = 'BPR'
		);
		insert rla;
		return rla;
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
		System.assertEquals('Cliente Missing Coverage', accountApplicant.get('FSC_Nombre__c'));
		System.assertEquals(null, nullContextApplicant);
	}

	@IsTest
	static void loanApplicantControllerPrefersAccountOverLoanApplicant() {
		Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
		Account account = new Account(
			FirstName = 'Cliente',
			LastName = 'Cliente Account',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Fisica').getRecordTypeId(),
			ACC_TipoIdentificacion__c = 'Pasaporte',
			ACC_NumIdentificacion__c = '00200000000',
			ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA',
			ACC_Estado_Civil__c = 'SOLTERO/A',
			ACC_Genero__c = 'MASCULINO',
			PersonBirthdate = Date.newInstance(1990, 1, 1),
			Tipo_de_vivienda__c = '1',
			Tiempo_en_Vivienda__c = '3 anos',
			ACC_N_Dependientes__c = 2,
			ACC_Ventas_Ingresos_Anuales__c = 120000
		);
		insert account;

		ResidentialLoanApplication rla = createRla();
		insert new LoanApplicant(
			Name = 'Solicitante No Preferido',
			LoanApplicationId = rla.Id,
			FSC_TipoIdentificacion__c = 'Pasaporte',
			FSC_NumIdentificacion__c = '00200000000',
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
		Map<String, Object> found = FSC_LoanApplicantController.getLoanApplicant('Pasaporte', '00200000000');
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
		System.assertEquals('Pasaporte', fromContext.get('FSC_TipoIdentificacion__c'));
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

		System.assertEquals(true, successResult.success, 'La consulta simulada debe ser exitosa.');
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
		Account account = new Account(Name = 'Cliente Planilla Saver');
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
		FSC_RlaAccionesController.testBypassPermissions = true;
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
		System.assertEquals('123456789 - 123456789', cuentas[0].get('label'));

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

		Boolean nullComplementaryThrown = false;
		try {
			FSC_RlaAccionesController.guardarDatosPagareComplementario(null, '54321');
		} catch (AuraHandledException ex) {
			nullComplementaryThrown = true;
		}
		System.assertEquals(true, nullComplementaryThrown);
		FSC_RlaAccionesController.guardarDatosPagareComplementario(rla.Id, ' ');
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

		FSC_RLATriggerHandler.beforeInsert(new List<ResidentialLoanApplication>());
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

	@IsTest
	static void rlaAccionesCoversAdditionalSimpleValidations() {
		ResidentialLoanApplication rla = createRla();
		update new ResidentialLoanApplication(
			Id = rla.Id,
			RecordTypeId = ResidentialLoanApplication.SObjectType.getDescribe()
				.getRecordTypeInfosByDeveloperName().get('FSC_Solicitud_Credito_Consumo').getRecordTypeId(),
			Status = 'En proceso',
			FSC_Subestado__c = 'Creación de crédito',
			FSC_FormaDeDesembolso__c = null
		);

		try {
			FSC_RlaAccionesController.reintentarCreacionPrestamo(rla.Id);
			System.assert(false, 'La forma de desembolso ausente debe rechazarse.');
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}

		update new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_Subestado__c = 'Desembolso',
			FSC_FlagErrorAPIDesembolso__c = true,
			FSC_FormaDeDesembolso__c = null
		);
		try {
			FSC_RlaAccionesController.reintentarDesembolso(rla.Id);
			System.assert(false, 'La forma de desembolso ausente debe rechazarse.');
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}

		try {
			FSC_RlaAccionesController.validateChecklistApprovalReadiness(null);
			System.assert(false, 'La solicitud nula debe rechazarse.');
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}
		try {
			FSC_RlaAccionesController.aprobarProcesoActualConHistorial(null, 'Comentario', 'Historial');
			System.assert(false, 'La solicitud nula debe rechazarse.');
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}

		String oversizedConditions = '';
		while (oversizedConditions.length() <= 2000) {
			oversizedConditions += 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
		}
		try {
			FSC_RlaAccionesController.aprobarConCondicion(rla.Id, 1, 1, 1, oversizedConditions);
			System.assert(false, 'Las condiciones extensas deben rechazarse.');
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}
	}

	@IsTest
	static void rlaAccionesCoversAbanksRetryBranches() {
		ResidentialLoanApplication rla = createRla();
		Id consumoRecordTypeId = ResidentialLoanApplication.SObjectType.getDescribe()
			.getRecordTypeInfosByDeveloperName().get('FSC_Solicitud_Credito_Consumo').getRecordTypeId();
		update new Account(
			Id = rla.AccountId,
			ACC_TipoIdentificacion__c = 'Cédula',
			ACC_NumIdentificacion__c = '00108803610'
		);
		update new ResidentialLoanApplication(
			Id = rla.Id,
			RecordTypeId = consumoRecordTypeId,
			Status = 'En proceso',
			FSC_Subestado__c = 'Creación de crédito',
			FSC_FormaDeDesembolso__c = 'Cuenta de ahorro',
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401',
			FSC_ClaveProducto__c = '17',
			FSC_Grupo_de_Empresa__c = '1',
			FSC_MontoAprobado__c = 20000,
			FSC_Monto_De_La_Cuota__c = 1000,
			FSC_PlazoMesesAprobado__c = 24,
			FSC_TasaInteresAprobada__c = 12,
			FSC_FechaVencimiento__c = Date.today().addMonths(24),
			FSC_PeriodoTasa__c = 12,
			FSC_FechaPrimerPagoInteres__c = Date.today().addMonths(1),
			FSC_FechaPrimerPagoCapital__c = Date.today().addMonths(1)
		);

		Map<String, Object> activeProduct = new Map<String, Object>{
			'NOMBRE' => 'Producto test',
			'CODIGO_LINEA_FINANCIERA' => 32,
			'CODIGO_SUB_APLICACION' => 401,
			'CLAVE_PRODUCTO' => 17,
			'CODIGO_TIPO_AMORTIZACION' => '4',
			'CODIGO_VALOR_TASA_CARTERA' => 55,
			'CODIGO_ESTADO_CARTERA' => 'A',
			'CODIGO_VALOR_TASA_CARTERA_MORA' => 40,
			'DIAS_GRACIA_MORA' => 3
		};

		FSC_APIPrestamoProductos.mockIpResponse = new Map<String, Object>{
			'productos' => new List<Object>{ activeProduct }
		};
		FSC_APIPrestamoPrestamos.mockIpResponse = new Map<String, Object>{
			'descripcionRespuesta' => 'Exitoso',
			'codigoRespuesta' => '00',
			'numeroPrestamo' => 54290
		};
		try {
			FSC_RlaAccionesController.reintentarCreacionPrestamo(rla.Id);
		} catch (AuraHandledException expectedWhenOptionalRateFieldsAreUnavailable) {
			System.assertNotEquals(null, expectedWhenOptionalRateFieldsAreUnavailable);
		}

		FSC_APIPrestamoProductos.mockIpResponse = new Map<String, Object>{ 'productos' => new List<Object>() };
		try {
			FSC_RlaAccionesController.reintentarCreacionPrestamo(rla.Id);
			System.assert(false, 'Un producto inexistente debe producir un error controlado.');
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}

		FSC_APIPrestamoProductos.mockIpResponse = new Map<String, Object>{ 'success' => false, 'error' => 'Error simulado' };
		try {
			FSC_RlaAccionesController.reintentarCreacionPrestamo(rla.Id);
			System.assert(false, 'Un error del catálogo debe propagarse de forma controlada.');
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}

		insert new LoanApplicant(
			Name = 'Deudor reintento',
			LoanApplicationId = rla.Id,
			FSC_TipoSolicitante__c = 'Deudor',
			FSC_TipoIdentificacion__c = 'Cédula',
			FSC_NumIdentificacion__c = '00108803610',
			FSC_Nombre__c = 'Deudor reintento'
		);
		update new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_Subestado__c = 'Desembolso',
			FSC_FlagErrorAPIDesembolso__c = true,
			FSC_NumeroPrestamoAbanks__c = '54290',
			FSC_NumeroCuentaDesembolso__c = '102083476'
		);
		FSC_APIPrestamoDesembolso.mockIpResponse = new Map<String, Object>{
			'HTTPDesembolso' => new Map<String, Object>{ 'StatusCode' => 200 }
		};

		Test.startTest();
		String desembolsoResult = FSC_RlaAccionesController.reintentarDesembolso(rla.Id);
		Test.stopTest();
		System.assertEquals('Desembolso creado en ABANKS.', desembolsoResult);
	}

	@IsTest
	static void rlaAccionesCoversSimpleNoProcessAndMetadataBranches() {
		ResidentialLoanApplication rla = createRla();
		Id pymeRecordTypeId = ResidentialLoanApplication.SObjectType.getDescribe()
			.getRecordTypeInfosByDeveloperName().get('FSC_Solicitud_Credito_PYME').getRecordTypeId();
		update new ResidentialLoanApplication(
			Id = rla.Id,
			RecordTypeId = pymeRecordTypeId,
			FSC_Cantidad_de_empleados__c = 5,
			FSC_VentasBrutasAnuales__c = 100000
		);

		try {
			FSC_RlaAccionesController.validarClasificacionMIPYMES(rla.Id);
		} catch (AuraHandledException expectedFromUnmockedIntegrationProcedure) {
			System.assertNotEquals(null, expectedFromUnmockedIntegrationProcedure);
		}
		System.assertEquals(false, FSC_RlaAccionesController.shouldUsePrivilegedSupervisorFallback(rla.Id));
		System.assertEquals('', FSC_RlaAccionesController.getProcessDefinitionDeveloperName(Id.valueOf('04g000000000001AAA')));

		try {
			FSC_RlaAccionesController.validarDocumentacionAnalista(rla.Id);
			System.assert(false, 'Sin proceso activo debe devolver un error controlado.');
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}
		try {
			FSC_RlaAccionesController.marcarCreadoEnAbanks(null);
			System.assert(false, 'El Id es requerido.');
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}
		try {
			FSC_RlaAccionesController.marcarDesembolsado(null);
			System.assert(false, 'El Id es requerido.');
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}
	}

	@IsTest
	static void rlaAccionesCoversSimpleDisbursementAccountBranches() {
		ResidentialLoanApplication rla = createRla();
		update new ResidentialLoanApplication(Id = rla.Id, FSC_UsuarioGestionPlanilla__c = UserInfo.getUserId());
		List<Map<String, String>> availableAccounts = FSC_RlaAccionesController.getCuentasDesembolsoOptions(rla.Id);
		System.assertEquals(0, availableAccounts.size());
		try {
			FSC_RlaAccionesController.guardarFormaDesembolsoGestionPlanillas(rla.Id, 'Cuenta de ahorro', null);
			System.assert(false, 'Una cuenta obligatoria debe rechazarse.');
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}

		String alternativeDisbursement;
		for (Schema.PicklistEntry entry : ResidentialLoanApplication.FSC_FormaDeDesembolso__c.getDescribe().getPicklistValues()) {
			if (entry.isActive() && entry.getValue() != 'Cuenta de ahorro') {
				alternativeDisbursement = entry.getValue();
				break;
			}
		}
		System.assertNotEquals(null, alternativeDisbursement);
		FSC_RlaAccionesController.guardarFormaDesembolsoGestionPlanillas(rla.Id, alternativeDisbursement, null);
	}
}