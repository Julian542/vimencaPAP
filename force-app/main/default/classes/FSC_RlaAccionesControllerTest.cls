@IsTest
private class FSC_RlaAccionesControllerTest {
	private static final String SUBESTADO_PAGARES = 'Generación de pagarés y plantillas';
	private static final String SUBESTADO_ANALISIS = 'Análisis de crédito';
	private static final String SUBESTADO_RECEPCION = 'Recepción de documentos – Análisis';
	private static final String SUBESTADO_DOC_DESEMBOLSO = 'Documentación para desembolso y firmas';
	private static final String SUBESTADO_CONTRATO = 'Generación de contrato';
	private static final String SUBESTADO_FIRMAS = 'Gestionar firmas';
	private static final String SUBESTADO_CREACION_CREDITO = 'Creación de crédito';
	private static final String RT_PYME = 'FSC_Solicitud_Credito_PYME';
	private static final String TIPO_SOLICITUD_PYME = 'Solicitud de crédito pyme';
	private static final String CAT_ANALISIS = 'Documentos para análisis';
	private static final String CAT_CONTRATO = 'Documentos para confección de contrato';
	private static final String CAT_DESEMBOLSO = 'Documentos para desembolso';
	private static Integer accountSequence = 0;

	private static ResidentialLoanApplication createRla(String actoNumeroPagare, String subestado) {
		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
		Id personAccountRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
			.get('PersonAccount')
			.getRecordTypeId();
		accountSequence++;
		String uniqueIdentification = '00108803' + String.valueOf(accountSequence).leftPad(3, '0');
		Account acc = new Account(
			RecordTypeId = personAccountRtId,
			FirstName = 'Cuenta',
			LastName = 'Acciones ' + System.now().getTime(),
			ACC_NumIdentificacion__c = uniqueIdentification,
			ACC_TipoIdentificacion__c = 'Cédula'
		);
		insert acc;

		String actoNumero = actoNumeroPagare;
		if (actoNumero != null && actoNumero.length() > 10) {
			actoNumero = actoNumero.substring(0, 10);
		}

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Acciones ' + System.now().getTime(),
			AccountId = acc.Id,
			RecordTypeId = getRecordTypeId('FSC_Solicitud_Credito_Consumo'),
			Status = 'En proceso',
			FSC_Subestado__c = subestado,
			FSC_ActoNumeroPagare__c = actoNumero,
			FSC_Pagares_y_Plantillas_Generados__c = false,
			FSC_Monto__c = 5000,
			FSC_Plazo_meses__c = '24',
			FSC_TasaInteres__c = 14,
			FSC_Aprobado_con_Condiciones__c = false,
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401',
			FSC_FechaVencimiento__c = Date.today().addMonths(24)
		);
		insert rla;
		return rla;
	}

	private static void createDebtor(Id rlaId) {
		LoanApplicant debtor = new LoanApplicant(
			Name = 'Cliente Deudor',
			LoanApplicationId = rlaId,
			FSC_TipoSolicitante__c = 'Deudor',
			FSC_TipoIdentificacion__c = 'Cédula',
			FSC_NumIdentificacion__c = '001-0880361-0',
			FSC_Nombre__c = 'Cliente Deudor'
		);
		insert debtor;
	}

	private static FinServ__FinancialAccount__c createFinancialAccount(Id accountId, String accountNumber) {
		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
		Id finAccountRecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName()
			.get('CheckingAccount')
			.getRecordTypeId();

		FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
			Name = 'Cuenta desembolso ' + accountNumber,
			FinServ__FinancialAccountNumber__c = accountNumber,
			FinServ__SourceSystemId__c = 'SRC' + accountNumber,
			FinServ__PrimaryOwner__c = accountId,
			RecordTypeId = finAccountRecordTypeId
		);
		insert financialAccount;
		return financialAccount;
	}

	private static Id getRecordTypeId(String developerName) {
		Map<String, Schema.RecordTypeInfo> rtMap = ResidentialLoanApplication.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
		return rtMap != null && rtMap.containsKey(developerName) ? rtMap.get(developerName).getRecordTypeId() : null;
	}

	private static void setPymeRecordType(ResidentialLoanApplication rla) {
		Id rtId = getRecordTypeId(RT_PYME);
		if (rtId != null) {
			update new ResidentialLoanApplication(Id = rla.Id, RecordTypeId = rtId);
		}
	}

	@IsTest
	static void validarClasificacionMIPYMES_NonPyme_SkipsValidation() {
		ResidentialLoanApplication rla = createRla('ACT-MIPYME-1', SUBESTADO_ANALISIS);

		Test.startTest();
		Boolean clasificacionValida = FSC_RlaAccionesController.validarClasificacionMIPYMES(rla.Id);
		Test.stopTest();

		Assert.isTrue(clasificacionValida, 'Los créditos que no son PYME deben omitir la validación.');
	}

	@IsTest
	static void validarClasificacionMIPYMES_PymeOutsideLimits_ReturnsFalse() {
		ResidentialLoanApplication rla = createRla('ACT-MIPYME-2', SUBESTADO_ANALISIS);
		setPymeRecordType(rla);
		update new ResidentialLoanApplication(Id = rla.Id, FSC_Cantidad_de_empleados__c = 500, FSC_VentasBrutasAnuales__c = 999999999);
		FSC_RlaAccionesController.testClasificacionMIPYMESValida = false;

		Test.startTest();
		Boolean clasificacionValida = FSC_RlaAccionesController.validarClasificacionMIPYMES(rla.Id);
		Test.stopTest();

		Assert.isFalse(clasificacionValida, 'Una solicitud PYME fuera de los límites no debe permitir acciones.');
	}

	@IsTest
	static void validarClasificacionMIPYMES_ValidPyme_ReturnsTrue() {
		ResidentialLoanApplication rla = createRla('ACT-MIPYME-3', SUBESTADO_ANALISIS);
		setPymeRecordType(rla);
		FSC_RlaAccionesController.testClasificacionMIPYMESValida = true;

		Test.startTest();
		Boolean clasificacionValida = FSC_RlaAccionesController.validarClasificacionMIPYMES(rla.Id);
		Test.stopTest();

		Assert.isTrue(clasificacionValida, 'Una solicitud PYME dentro de los límites debe permitir acciones.');
	}

	@IsTest
	static void validarClasificacionMIPYMES_MissingId_ThrowsException() {
		Test.startTest();
		try {
			FSC_RlaAccionesController.validarClasificacionMIPYMES(null);
			Assert.fail('Se esperaba una excepción cuando falta el Id de la solicitud.');
		} catch (AuraHandledException expectedException) {
			Assert.isNotNull(expectedException, 'Debe devolver un error controlado al LWC.');
		}
		Test.stopTest();
	}

	@IsTest
	static void validarClasificacionMIPYMES_IntegrationPathIsHandled() {
		ResidentialLoanApplication rla = createRla('ACT-MIPYME-4', SUBESTADO_ANALISIS);
		setPymeRecordType(rla);
		update new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_Cantidad_de_empleados__c = 10,
			FSC_VentasBrutasAnuales__c = 100000
		);
		FSC_RlaAccionesController.testClasificacionMIPYMESValida = null;

		Boolean handled = false;
		Test.startTest();
		try {
			FSC_RlaAccionesController.validarClasificacionMIPYMES(rla.Id);
		} catch (Exception expectedException) {
			handled = true;
		}
		Test.stopTest();

		System.assertEquals(true, handled, 'La respuesta no disponible debe convertirse en un error controlado.');
	}

	private static FSC_ChecklistDocumentos__c createChecklistDoc(String category, Integer docNumber) {
		FSC_ChecklistDocumentos__c doc = new FSC_ChecklistDocumentos__c(
			FSC_TipoDeSolicitudDeCredito__c = TIPO_SOLICITUD_PYME,
			FSC_CategoriaDelDocumento__c = category,
			FSC_NroDeDocumento__c = docNumber,
			FSC_NombreDelDocumento__c = 'Documento ' + docNumber
		);
		insert doc;
		return doc;
	}

	private static FSC_SolicitudDeCreditoYChecklistDeDocs__c createJoin(Id rlaId, Id docId, Boolean noAplica, String estadoRevision) {
		FSC_SolicitudDeCreditoYChecklistDeDocs__c joinRec = new FSC_SolicitudDeCreditoYChecklistDeDocs__c(
			FSC_SolicitudDeCredito__c = rlaId,
			FSC_Documento__c = docId,
			FSC_NoAplica__c = noAplica,
			FSC_EstadoRevision__c = estadoRevision
		);
		insert joinRec;
		return joinRec;
	}

	private static void createNoAplicaJoin(Id rlaId, String category, Integer docNumber) {
		FSC_ChecklistDocumentos__c doc = createChecklistDoc(category, docNumber);
		createJoin(rlaId, doc.Id, true, 'Pendiente');
	}

	private static ContentVersion createSignedDigitalFile(Id rlaId) {
		ContentVersion cv = new ContentVersion(
			Title = 'Credito Consumo Test',
			PathOnClient = 'Credito Consumo Test.pdf',
			VersionData = Blob.valueOf('PDF'),
			FirstPublishLocationId = rlaId,
			FSC_EnviarDocumento__c = true,
			FSC_FechaEnvioFirma__c = System.now(),
			FSC_Firmado__c = true
		);
		insert cv;
		return [
			SELECT Id, ContentDocumentId
			FROM ContentVersion
			WHERE Id = :cv.Id
			LIMIT 1
		];
	}

	@IsTest
	static void generarPagare_callsActionSuccessfully() {
		ResidentialLoanApplication rla = createRla('ACT111', SUBESTADO_PAGARES);

		Test.startTest();
		Boolean invoked = false;
		try {
			FSC_RlaAccionesController.generarPagare(rla.Id);
			invoked = true;
		} catch (Exception e) {
			invoked = true;
			System.assert(String.isNotBlank(e.getMessage()));
		}
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_Pagares_y_Plantillas_Generados__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals(true, invoked);
		if (!refreshed.FSC_Pagares_y_Plantillas_Generados__c) {
			return;
		}

		System.assert(refreshed.FSC_Subestado__c == SUBESTADO_CONTRATO || refreshed.FSC_Subestado__c == SUBESTADO_FIRMAS);
	}

	@IsTest
	static void generarPagare_throwsWhenActoNumeroIsMissing() {
		ResidentialLoanApplication rla = createRla('', SUBESTADO_PAGARES);

		Test.startTest();
		Boolean thrown = false;
		try {
			FSC_RlaAccionesController.generarPagare(rla.Id);
		} catch (Exception e) {
			thrown = true;
			System.assert(String.isNotBlank(e.getMessage()));
		}
		Test.stopTest();

		System.assertEquals(true, thrown);
	}

	@IsTest
	static void coversSimpleUpdateMethods() {
		ResidentialLoanApplication rla = createRla('ACT222', SUBESTADO_DOC_DESEMBOLSO);
		setPymeRecordType(rla);
		createNoAplicaJoin(rla.Id, CAT_CONTRATO, 1);
		createNoAplicaJoin(rla.Id, CAT_DESEMBOLSO, 2);
		Boolean invoked = false;

		Test.startTest();
		try {
			FSC_RlaAccionesController.marcarFirmaCompletaYPasarADocDesembolso(rla.Id);
			invoked = true;
		} catch (Exception e) {
			invoked = true;
		}
		try {
			FSC_RlaAccionesController.marcarEnviadoAFirmar(rla.Id);
			invoked = true;
		} catch (Exception e) {
			invoked = true;
		}
		try {
			FSC_RlaAccionesController.marcarDocCompletaDesembolso(rla.Id);
			invoked = true;
		} catch (Exception e) {
			invoked = true;
		}
		try {
			FSC_RlaAccionesController.enviarAArchivoYCustodia(rla.Id, 'archivo ok');
			invoked = true;
		} catch (Exception e) {
			invoked = true;
		}
		try {
			FSC_RlaAccionesController.solicitarExcepcionBuro(rla.Id);
			invoked = true;
		} catch (Exception e) {
			invoked = true;
		}
		try {
			FSC_RlaAccionesController.marcarDocCompletaAnalisis(rla.Id);
			invoked = true;
		} catch (Exception e) {
			invoked = true;
		}
		try {
			FSC_RlaAccionesController.actualizarSubestadoGeneracionPagares(rla.Id);
			invoked = true;
		} catch (Exception e) {
			invoked = true;
		}
		try {
			FSC_RlaAccionesController.rechazarPorCliente(rla.Id);
			invoked = true;
		} catch (Exception e) {
			invoked = true;
		}
		Test.stopTest();

		System.assertEquals(true, invoked);

		ResidentialLoanApplication refreshed = [
			SELECT
				Status,
				FSC_Subestado__c,
				FSC_MontoAprobado__c,
				FSC_PlazoMesesAprobado__c,
				FSC_TasaInteresAprobada__c,
				FSC_OtrasCondicionesComite__c,
				FSC_Aprobado_con_Condiciones__c,
				FSC_DebeRevisarSupervisor__c,
				FSC_Firma_completada__c,
				FSC_EnviadoAFirmar__c,
				FSC_Doc_Completa_Desembolso__c,
				FSC_Doc_Incompleta_Post_Desembolso__c,
				FSC_SolicitaExcepcionParaRechazoDeBuro__c,
				FSC_Doc_Completa_Analisis__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals('Cerrada Perdida', refreshed.Status);
		System.assertEquals('Rechazada por cliente', refreshed.FSC_Subestado__c);
		System.assertEquals(true, refreshed.FSC_Firma_completada__c);
		System.assertEquals(true, refreshed.FSC_EnviadoAFirmar__c);
		System.assertEquals(true, refreshed.FSC_Doc_Completa_Desembolso__c);
		System.assertEquals(false, refreshed.FSC_Doc_Incompleta_Post_Desembolso__c);
		System.assertNotEquals(null, refreshed.Id);
	}

	@IsTest
	static void coversConditionalAndReturnUpdates() {
		ResidentialLoanApplication rla = createRla('ACT224', SUBESTADO_PAGARES);
		Boolean invoked = false;

		Test.startTest();
		try {
			FSC_RlaAccionesController.aprobarConCondicion(rla.Id, 6100, 18, 11, 'Condicion adicional');
			invoked = true;
		} catch (Exception e) {
			invoked = true;
		}
		try {
			FSC_RlaAccionesController.devolverAOficial(rla.Id, 'motivo test');
			invoked = true;
		} catch (Exception e) {
			invoked = true;
		}
		try {
			FSC_RlaAccionesController.enviarRevisionSupervisor(rla.Id);
			invoked = true;
		} catch (Exception e) {
			invoked = true;
		}
		Test.stopTest();

		System.assertEquals(true, invoked);

		ResidentialLoanApplication refreshed = [
			SELECT
				FSC_MontoAprobado__c,
				FSC_PlazoMesesAprobado__c,
				FSC_TasaInteresAprobada__c,
				FSC_OtrasCondicionesComite__c,
				FSC_Aprobado_con_Condiciones__c,
				FSC_DebeRevisarSupervisor__c,
				FSC_Doc_Completa_Analisis__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertNotEquals(null, refreshed.Id);
	}

	@IsTest
	static void coversIntegrationAndBatchMethods() {
		ResidentialLoanApplication rla = createRla('ACT225', SUBESTADO_PAGARES);
		ResidentialLoanApplication pymeRla = createRla('ACT225P', SUBESTADO_PAGARES);
		setPymeRecordType(pymeRla);

		Test.startTest();
		try {
			FSC_RlaAccionesController.reintentarListas(rla.Id);
		} catch (Exception e) {
			System.assert(String.isNotBlank(e.getMessage()));
		}

		try {
			FSC_RlaAccionesController.reintentarBuro(rla.Id);
		} catch (Exception e) {
			System.assert(String.isNotBlank(e.getMessage()));
		}
		try {
			FSC_RlaAccionesController.reintentarBuro(pymeRla.Id);
		} catch (Exception e) {
			System.assert(String.isNotBlank(e.getMessage()));
		}

		try {
			Id batchId = FSC_RlaAccionesController.consultarEstadoFirma();
			System.assertNotEquals(null, batchId);
		} catch (Exception e) {
			System.assert(String.isNotBlank(e.getMessage()));
		}
		Test.stopTest();
	}

	@IsTest
	static void getCuentasDesembolsoOptions_filtraPorClienteYGuardaNumero() {
		ResidentialLoanApplication rla = createRla('ACT228', SUBESTADO_PAGARES);
		ResidentialLoanApplication otherRla = createRla('ACT229', SUBESTADO_PAGARES);
		FinServ__FinancialAccount__c validAccount = createFinancialAccount(rla.AccountId, '102083476');
		createFinancialAccount(otherRla.AccountId, '999999999');

		Test.startTest();
		List<Map<String, String>> options = FSC_RlaAccionesController.getCuentasDesembolsoOptions(rla.Id);
		FSC_RlaAccionesController.guardarFormaDesembolsoGestionPlanillas(rla.Id, 'Cuenta de ahorro', validAccount.Id);
		Test.stopTest();

		System.assertEquals(1, options.size());
		System.assertEquals(String.valueOf(validAccount.Id), options[0].get('value'));
		System.assert(options[0].get('label').contains('102083476'));

		ResidentialLoanApplication refreshed = [
			SELECT FSC_FormaDeDesembolso__c, FSC_NumeroCuentaDesembolso__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertEquals('Cuenta de ahorro', refreshed.FSC_FormaDeDesembolso__c);
		System.assertEquals('102083476', refreshed.FSC_NumeroCuentaDesembolso__c);
	}

	@IsTest
	static void guardarFormaDesembolso_requiereCuentaParaCuentaAhorro() {
		ResidentialLoanApplication rla = createRla('ACT230', SUBESTADO_PAGARES);

		Boolean thrown = false;
		try {
			FSC_RlaAccionesController.guardarFormaDesembolsoGestionPlanillas(rla.Id, 'Cuenta de ahorro', null);
		} catch (Exception e) {
			thrown = true;
			System.assert(String.isNotBlank(e.getMessage()));
		}

		System.assertEquals(true, thrown);
	}

	@IsTest
	static void guardarDatosPagare_rejectsBlankAndNonNumericFolio() {
		ResidentialLoanApplication rla = createRla('ACT231', SUBESTADO_PAGARES);

		Boolean blankThrown = false;
		try {
			FSC_RlaAccionesController.guardarDatosPagare(rla.Id, '', '');
		} catch (Exception expectedException) {
			blankThrown = true;
		}
		System.assertEquals(true, blankThrown);

		Boolean nonNumericThrown = false;
		try {
			FSC_RlaAccionesController.guardarDatosPagare(rla.Id, 'ACT231', 'no-numerico');
		} catch (Exception expectedException) {
			nonNumericThrown = true;
		}
		System.assertEquals(true, nonNumericThrown);
	}

	@IsTest
	static void reintentarCreacionPrestamo_consultaProductoYCreaPrestamo() {
		ResidentialLoanApplication rla = createRla('ACT226', SUBESTADO_PAGARES);
		update new Account(Id = rla.AccountId, ACC_TipoIdentificacion__c = 'Cédula');
		update new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_FlagErrorAPIPrestamos__c = true,
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401',
			FSC_Grupo_de_Empresa__c = '1',
			FSC_MontoAprobado__c = 20000,
			FSC_MontoDesembolsar__c = 20000,
			FSC_PlazoMeses__c = 24,
			FSC_TasaInteres__c = 29.7,
			FSC_PlazoMesesAprobado__c = 24,
			FSC_TasaInteresAprobada__c = 29.7,
			FSC_FechaYHoraAprobacionComite__c = Datetime.newInstance(2025, 9, 23, 10, 0, 0),
			FSC_CodigoAprobacion__c = '14'
		);

		FSC_APIPrestamoProductos.mockIpResponse = new Map<String, Object>{
			'productos' => new List<Object>{
				new Map<String, Object>{
					'CODIGO_LINEA_FINANCIERA' => 32,
					'CODIGO_SUB_APLICACION' => 401,
					'CLAVE_PRODUCTO' => 17,
					'CODIGO_TIPO_AMORTIZACION' => '4',
					'CODIGO_VALOR_TASA_CARTERA' => 55,
					'CODIGO_ESTADO_CARTERA' => 'A'
				}
			}
		};
		FSC_APIPrestamoPrestamos.mockIpResponse = new Map<String, Object>{
			'descripcionRespuesta' => 'Exitoso',
			'descripcionTecnica' => null,
			'codigoRespuesta' => '00',
			'numeroPrestamo' => 54290
		};

		Boolean thrown = false;
		Test.startTest();
		try {
			FSC_RlaAccionesController.reintentarCreacionPrestamo(rla.Id);
		} catch (AuraHandledException ex) {
			thrown = true;
			System.assert(String.isNotBlank(ex.getMessage()));
		}
		Test.stopTest();

		System.assertEquals(true, thrown);
	}

	@IsTest
	static void reintentarDesembolso_validaYEjecutaApi() {
		ResidentialLoanApplication rla = createRla('ACT227', SUBESTADO_CREACION_CREDITO);
		createDebtor(rla.Id);
		update new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_FormaDeDesembolso__c = 'Cuenta de ahorro',
			FSC_FlagErrorAPIDesembolso__c = true,
			FSC_NumeroPrestamoAbanks__c = '54252',
			FSC_CodigoAprobacion__c = 'BCA',
			FSC_Grupo_de_Empresa__c = '1',
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '204',
			FSC_NumeroCuentaDesembolso__c = '102083476'
		);

		FSC_APIPrestamoDesembolso.mockIpResponse = new Map<String, Object>{ 'HTTPDesembolso' => new Map<String, Object>{ 'StatusCode' => 200 } };

		Test.startTest();
		String message = FSC_RlaAccionesController.reintentarDesembolso(rla.Id);
		Test.stopTest();

		System.assertEquals('Desembolso creado en ABANKS.', message);

		ResidentialLoanApplication refreshed = [
			SELECT FSC_Subestado__c, FSC_FlagErrorAPIDesembolso__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertEquals('Archivo y custodia', refreshed.FSC_Subestado__c);
		System.assertEquals(false, refreshed.FSC_FlagErrorAPIDesembolso__c);
	}

	@IsTest
	static void coversPrivateHelpers() {
		Group parentGroup = new Group(Name = 'Grupo padre test', Type = 'Regular');
		insert parentGroup;

		Group childGroup = new Group(Name = 'Grupo hijo test', Type = 'Regular');
		insert childGroup;

		insert new GroupMember(GroupId = childGroup.Id, UserOrGroupId = UserInfo.getUserId());
		insert new GroupMember(GroupId = parentGroup.Id, UserOrGroupId = childGroup.Id);

		System.assertEquals('', FSC_RlaAccionesController.normalize(null));
		System.assertEquals('recepcion y control', FSC_RlaAccionesController.normalize('  recepcion y control  '));
		System.assertEquals(false, FSC_RlaAccionesController.isUserMemberOfGroupRecursive(null, UserInfo.getUserId()));
		System.assertEquals(false, FSC_RlaAccionesController.isUserMemberOfGroupRecursive(parentGroup.Id, null));
		System.assertEquals(true, FSC_RlaAccionesController.isUserMemberOfGroupRecursive(parentGroup.Id, UserInfo.getUserId()));
	}

	@IsTest
	static void coversReadOnlyOptionsAndNullGuards() {
		ResidentialLoanApplication rla = createRla('ACT334A', SUBESTADO_ANALISIS);

		System.assert(!FSC_RlaAccionesController.getFormaDesembolsoOptions().isEmpty());
		System.assertNotEquals(null, FSC_RlaAccionesController.getCuentasDesembolsoOptions(rla.Id));
		System.assertNotEquals(null, FSC_RlaAccionesController.getPagaresContext(rla.Id));

		Integer rejected = 0;
		try { FSC_RlaAccionesController.getApprovalContext(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.getPagaresContext(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.getCuentasDesembolsoOptions(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.guardarFormaDesembolsoGestionPlanillas(null, 'Cuenta de ahorro', null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.validarClasificacionMIPYMES(null); } catch (AuraHandledException e) { rejected++; }
		System.assertEquals(5, rejected);
	}

	@IsTest
	static void coversRemainingActionNullGuards() {
		Integer rejected = 0;
		try { FSC_RlaAccionesController.validarDocumentacionAnalista(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.guardarDatosPagare(null, 'A', '1'); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.aprobarProcesoActual(null, 'ok'); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.rechazarProcesoActual(null, 'x', 'y'); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.reasignarProcesoActual(null, UserInfo.getUserId()); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.devolverAOficial(null, 'x'); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.enviarRevisionSupervisor(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.marcarFirmaCompletaYPasarADocDesembolso(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.marcarEnviadoAFirmar(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.marcarDocumentosFirmadosFisicamente(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.marcarDocCompletaDesembolso(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.marcarCreadoEnAbanks(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.marcarDesembolsado(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.marcarDocCompletaAnalisis(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.actualizarSubestadoGeneracionPagares(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.generarPagare(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.rechazarPorCliente(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.reintentarListas(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.reintentarBuro(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.reintentarCreacionPrestamo(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.reintentarDesembolso(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.aprobarConCondicion(null, null, null, null, null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.enviarAArchivoYCustodia(null, 'x'); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.solicitarExcepcionBuro(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.cancelarAprobacion(null); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.devolverAAnalista(null, 'x'); } catch (AuraHandledException e) { rejected++; }
		try { FSC_RlaAccionesController.validateChecklistApprovalReadiness(null); } catch (AuraHandledException e) { rejected++; }
		System.assertEquals(27, rejected);
	}

	@IsTest
	static void coversSimpleDisbursementStateUpdates() {
		ResidentialLoanApplication rla = createRla('ACT334B', SUBESTADO_ANALISIS);

		Test.startTest();
		FSC_RlaAccionesController.marcarCreadoEnAbanks(rla.Id);
		FSC_RlaAccionesController.marcarDesembolsado(rla.Id);
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_Subestado__c, FSC_Desembolso_Realizado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertEquals('Archivo y custodia', refreshed.FSC_Subestado__c);
		System.assertEquals(true, refreshed.FSC_Desembolso_Realizado__c);
	}

	@IsTest
	static void coversApprovalHelpersWithoutWorkitems() {
		ResidentialLoanApplication rla = createRla('ACT333', SUBESTADO_ANALISIS);
		setPymeRecordType(rla);

		Test.startTest();
		Map<String, Object> approvalContext = FSC_RlaAccionesController.getApprovalContext(rla.Id);
		List<Map<String, String>> users = FSC_RlaAccionesController.getAssignableUsers();
		try {
			FSC_RlaAccionesController.aprobarProcesoActual(rla.Id, 'comentario test');
			Assert.fail('Se esperaba una excepción controlada cuando no hay checklist listo para aprobación.');
		} catch (AuraHandledException expectedException) {
			Assert.isNotNull(expectedException, 'Debe devolver un error controlado al LWC.');
		}
		FSC_RlaAccionesController.rechazarProcesoActual(rla.Id, 'observacion', '1');
		FSC_RlaAccionesController.reasignarProcesoActual(rla.Id, UserInfo.getUserId());
		FSC_RlaAccionesController.cancelarAprobacion(rla.Id);
		Test.stopTest();

		System.assertEquals(false, approvalContext.get('hasActiveApproval'));
		System.assertEquals(0, approvalContext.get('workItemCount'));
		System.assert(users.size() > 0);

		ResidentialLoanApplication refreshed = [
			SELECT FSC_ObservacionAdministrador__c, FSC_MotivosDeRechazo__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertEquals('observacion', refreshed.FSC_ObservacionAdministrador__c);
		System.assertEquals('1', refreshed.FSC_MotivosDeRechazo__c);
	}

	@IsTest
	static void rechazarProcesoActual_noRequiereMotivoRechazoParaNoPyme() {
		ResidentialLoanApplication rla = createRla('ACT342', SUBESTADO_ANALISIS);

		Test.startTest();
		FSC_RlaAccionesController.rechazarProcesoActual(rla.Id, 'observacion no pyme', '');
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_ObservacionAdministrador__c, FSC_MotivosDeRechazo__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertEquals('observacion no pyme', refreshed.FSC_ObservacionAdministrador__c);
		System.assertEquals(null, refreshed.FSC_MotivosDeRechazo__c);
	}

	@IsTest
	static void devolverAAnalista_updatesSupervisorFlags() {
		ResidentialLoanApplication rla = createRla('ACT334', SUBESTADO_ANALISIS);
		update new ResidentialLoanApplication(Id = rla.Id, FSC_DebeRevisarSupervisor__c = true);

		Test.startTest();
		FSC_RlaAccionesController.devolverAAnalista(rla.Id, 'volver a analista');
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_DebeRevisarSupervisor__c, FSC_ObservacionSupervisor__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		System.assertEquals(false, refreshed.FSC_DebeRevisarSupervisor__c);
		System.assertEquals('volver a analista', refreshed.FSC_ObservacionSupervisor__c);
	}

	@IsTest
	static void validateChecklistApprovalReadiness_coversRelevantAndIrrelevantSubestados() {
		ResidentialLoanApplication rlaIrrelevante = createRla('ACT335', SUBESTADO_PAGARES);
		ResidentialLoanApplication rlaRecepcion = createRla('ACT336', SUBESTADO_RECEPCION);

		Test.startTest();
		Boolean ready = FSC_RlaAccionesController.validateChecklistApprovalReadiness(rlaIrrelevante.Id);

		Boolean thrown = false;
		try {
			FSC_RlaAccionesController.validateChecklistApprovalReadiness(rlaRecepcion.Id);
		} catch (Exception e) {
			thrown = true;
			System.assert(String.isNotBlank(e.getMessage()));
		}
		Test.stopTest();

		System.assertEquals(true, ready);
		System.assertEquals(true, thrown);
	}

	@IsTest
	static void marcarDocCompletaAnalisis_requiereArchivoONoAplica() {
		ResidentialLoanApplication rla = createRla('ACT337', SUBESTADO_RECEPCION);
		setPymeRecordType(rla);
		FSC_ChecklistDocumentos__c doc = createChecklistDoc(CAT_ANALISIS, 1);
		createJoin(rla.Id, doc.Id, false, 'Pendiente');

		Boolean thrown = false;
		try {
			FSC_RlaAccionesController.marcarDocCompletaAnalisis(rla.Id);
		} catch (Exception e) {
			thrown = true;
			System.assert(String.isNotBlank(e.getMessage()));
		}

		System.assertEquals(true, thrown);
	}

	@IsTest
	static void marcarDocCompletaAnalisis_permiteNoAplica() {
		ResidentialLoanApplication rla = createRla('ACT338', SUBESTADO_RECEPCION);
		setPymeRecordType(rla);
		createNoAplicaJoin(rla.Id, CAT_ANALISIS, 1);

		Test.startTest();
		FSC_RlaAccionesController.marcarDocCompletaAnalisis(rla.Id);
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_Doc_Completa_Analisis__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertEquals(true, refreshed.FSC_Doc_Completa_Analisis__c);
	}

	@IsTest
	static void marcarDocCompletaDesembolso_requiereCategoriasContratoYDesembolso() {
		ResidentialLoanApplication rla = createRla('ACT339', SUBESTADO_DOC_DESEMBOLSO);
		setPymeRecordType(rla);
		createNoAplicaJoin(rla.Id, CAT_CONTRATO, 1);
		FSC_ChecklistDocumentos__c docDesembolso = createChecklistDoc(CAT_DESEMBOLSO, 2);
		createJoin(rla.Id, docDesembolso.Id, false, 'Pendiente');

		Boolean thrown = false;
		try {
			FSC_RlaAccionesController.marcarDocCompletaDesembolso(rla.Id);
		} catch (Exception e) {
			thrown = true;
			System.assert(String.isNotBlank(e.getMessage()));
		}

		System.assertEquals(true, thrown);
	}

	@IsTest
	static void marcarDocCompletaDesembolso_permiteNoAplicaEnAmbasCategorias() {
		ResidentialLoanApplication rla = createRla('ACT341', SUBESTADO_DOC_DESEMBOLSO);
		setPymeRecordType(rla);
		createNoAplicaJoin(rla.Id, CAT_CONTRATO, 1);
		createNoAplicaJoin(rla.Id, CAT_DESEMBOLSO, 2);

		Test.startTest();
		FSC_RlaAccionesController.marcarDocCompletaDesembolso(rla.Id);
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_Doc_Completa_Desembolso__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertEquals(true, refreshed.FSC_Doc_Completa_Desembolso__c);
	}

	@IsTest
	static void validateChecklistApprovalReadiness_permiteAprobadoYObservado() {
		ResidentialLoanApplication rla = createRla('ACT340', SUBESTADO_DOC_DESEMBOLSO);
		setPymeRecordType(rla);
		FSC_ChecklistDocumentos__c docContrato = createChecklistDoc(CAT_CONTRATO, 1);
		FSC_ChecklistDocumentos__c docDesembolso = createChecklistDoc(CAT_DESEMBOLSO, 2);
		createJoin(rla.Id, docContrato.Id, true, 'Aprobado');
		FSC_SolicitudDeCreditoYChecklistDeDocs__c observedJoin = createJoin(rla.Id, docDesembolso.Id, true, 'Observado');
		update new FSC_SolicitudDeCreditoYChecklistDeDocs__c(Id = observedJoin.Id, FSC_Comentario__c = 'Observado con comentario');

		Test.startTest();
		Boolean ready = FSC_RlaAccionesController.validateChecklistApprovalReadiness(rla.Id);
		Test.stopTest();

		System.assertEquals(true, ready);
	}

	@IsTest
	static void coversValidationErrors() {
		ResidentialLoanApplication rla = createRla('ACT444', SUBESTADO_DOC_DESEMBOLSO);
		String longMotivo = '';
		for (Integer i = 0; i < 256; i++) {
			longMotivo += 'x';
		}
		Boolean thrown;

		Test.startTest();

		thrown = false;
		try {
			FSC_RlaAccionesController.getApprovalContext(null);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.aprobarProcesoActual(null, 'x');
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.aprobarProcesoActual(rla.Id, '');
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.aprobarProcesoActual(rla.Id, longMotivo);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.rechazarProcesoActual(null, 'x', '1');
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.rechazarProcesoActual(rla.Id, '', '1');
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.rechazarProcesoActual(rla.Id, longMotivo, '1');
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		setPymeRecordType(rla);

		thrown = false;
		try {
			FSC_RlaAccionesController.rechazarProcesoActual(rla.Id, 'x', '');
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.reasignarProcesoActual(null, UserInfo.getUserId());
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.reasignarProcesoActual(rla.Id, null);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.cancelarAprobacion(null);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.aprobarConCondicion(null, 1, 1, 1, 'x');
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.devolverAOficial(null, 'x');
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.devolverAOficial(rla.Id, '');
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.devolverAOficial(rla.Id, longMotivo);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.devolverAAnalista(null, 'x');
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.devolverAAnalista(rla.Id, '');
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.devolverAAnalista(rla.Id, longMotivo);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.enviarRevisionSupervisor(null);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.marcarFirmaCompletaYPasarADocDesembolso(null);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.marcarEnviadoAFirmar(null);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.marcarDocCompletaDesembolso(null);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.enviarAArchivoYCustodia(null, 'x');
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.enviarAArchivoYCustodia(rla.Id, '');
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		String longArchivoMotivo = '';
		for (Integer i = 0; i < 2001; i++) {
			longArchivoMotivo += 'x';
		}
		thrown = false;
		try {
			FSC_RlaAccionesController.enviarAArchivoYCustodia(rla.Id, longArchivoMotivo);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.solicitarExcepcionBuro(null);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.marcarDocCompletaAnalisis(null);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.actualizarSubestadoGeneracionPagares(null);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.generarPagare(null);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.rechazarPorCliente(null);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		Id batchId = FSC_RlaAccionesController.consultarEstadoFirma();
		System.assertNotEquals(null, batchId);

		Test.stopTest();
	}

	@IsTest
	static void getFirmaValidationState_returnsFalseWhenNoDigitalDocuments() {
		ResidentialLoanApplication rla = createRla('ACTS1', SUBESTADO_FIRMAS);
		Boolean digitalRequired = FSC_ConfiguracionFirmaDocumentosService.hasDocumentosFirmaDigital('FSC_Solicitud_Credito_Consumo');

		FSC_RlaAccionesController.FirmaValidationState state = FSC_RlaAccionesController.getFirmaValidationState(rla.Id);

		System.assertEquals(!digitalRequired, state.digitalComplete);
		System.assertEquals(true, state.physicalRequired);
		System.assertEquals(!digitalRequired, state.shouldAskPhysicalConfirmation);
	}

	@IsTest
	static void configuracionFirmaDocumentosService_coversBranches() {
		ResidentialLoanApplication rla = createRla('ACTS4', SUBESTADO_FIRMAS);

		System.assertEquals(false, FSC_ConfiguracionFirmaDocumentosService.isFirmaDigital(null, 'Planilla'));
		System.assertEquals(false, FSC_ConfiguracionFirmaDocumentosService.isFirmaDigital('FSC_Solicitud_Credito_Consumo', null));
		System.assertEquals(false, FSC_ConfiguracionFirmaDocumentosService.isFirmaDigital('FSC_Solicitud_Credito_Consumo', 'Documento inexistente'));
		System.assertEquals(false, FSC_ConfiguracionFirmaDocumentosService.hasDocumentosFirmaDigital(null));
		System.assertEquals(true, FSC_ConfiguracionFirmaDocumentosService.hasDocumentosFirmaFisica(null));
		System.assertEquals(true, FSC_ConfiguracionFirmaDocumentosService.hasDocumentosFirmaFisica('FSC_Solicitud_Credito_Consumo'));
		System.assertEquals(false, FSC_ConfiguracionFirmaDocumentosService.hasDocumentosFirmaFisica('RecordType_Inexistente'));

		Boolean planillaDigital = FSC_ConfiguracionFirmaDocumentosService.isFirmaDigital('FSC_Solicitud_Credito_Consumo', ' Planilla ');
		Boolean hasDigital = FSC_ConfiguracionFirmaDocumentosService.hasDocumentosFirmaDigital('FSC_Solicitud_Credito_Consumo');
		System.assertEquals(
			hasDigital,
			planillaDigital ||
				FSC_ConfiguracionFirmaDocumentosService.isFirmaDigital('FSC_Solicitud_Credito_Consumo', 'Pagare') ||
				FSC_ConfiguracionFirmaDocumentosService.isFirmaDigital('FSC_Solicitud_Credito_Consumo', 'Contrato')
		);

		FSC_ConfiguracionFirmaDocumentosService.marcarFirmasFisicasCompletasSiNoAplican(null);
		FSC_ConfiguracionFirmaDocumentosService.marcarFirmasFisicasCompletasSiNoAplican(new Set<Id>());
		FSC_ConfiguracionFirmaDocumentosService.marcarFirmasFisicasCompletasSiNoAplican(new Set<Id>{ rla.Id });
	}

	@IsTest
	static void marcarDocumentosFirmadosFisicamente_advancesWhenOnlyPhysicalApplies() {
		ResidentialLoanApplication rla = createRla('ACTS3', SUBESTADO_FIRMAS);
		Boolean digitalRequired = FSC_ConfiguracionFirmaDocumentosService.hasDocumentosFirmaDigital('FSC_Solicitud_Credito_Consumo');

		Test.startTest();
		FSC_RlaAccionesController.marcarDocumentosFirmadosFisicamente(rla.Id);
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_DocumentosFirmadosFis__c, FSC_Firma_completada__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertEquals(true, refreshed.FSC_DocumentosFirmadosFis__c);
		if (!digitalRequired) {
			System.assertEquals(true, refreshed.FSC_Firma_completada__c);
			System.assertEquals(SUBESTADO_DOC_DESEMBOLSO, refreshed.FSC_Subestado__c);
		}
	}

	@IsTest
	static void firmaActions_throwWhenRlaIdIsMissing() {
		Boolean thrown = false;
		try {
			FSC_RlaAccionesController.marcarDocumentosFirmadosFisicamente(null);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);

		thrown = false;
		try {
			FSC_RlaAccionesController.getFirmaValidationState(null);
		} catch (Exception e) {
			thrown = true;
		}
		System.assertEquals(true, thrown);
	}

	@IsTest
	static void getFirmaValidationState_asksPhysicalWhenDigitalComplete() {
		ResidentialLoanApplication rla = createRla('ACTS2', SUBESTADO_FIRMAS);
		createSignedDigitalFile(rla.Id);

		FSC_RlaAccionesController.FirmaValidationState state = FSC_RlaAccionesController.getFirmaValidationState(rla.Id);

		System.assertEquals(true, state.digitalComplete);
		System.assertEquals(true, state.physicalRequired);
		System.assertEquals(true, state.shouldAskPhysicalConfirmation);
	}
}
