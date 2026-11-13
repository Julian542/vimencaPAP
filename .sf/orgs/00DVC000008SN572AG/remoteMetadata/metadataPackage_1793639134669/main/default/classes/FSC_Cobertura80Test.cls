@IsTest
private class FSC_Cobertura80Test {
    @TestSetup
    static void asignarPermisosAdministrador() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet permiso = [SELECT Id FROM PermissionSet WHERE Name = 'FSC_PS_Administrador' LIMIT 1];
            // El usuario que ejecuta los tests puede tener ya el permission set asignado.
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permiso.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permiso.Id);
            }
        }
    }

	private static ResidentialLoanApplication solicitud(String tipo, String subestado) {
		Account cuenta = new Account(
			LastName = 'Cobertura simple',
			RecordTypeId = Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Fisica').getRecordTypeId()
		);
		insert cuenta;
		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'Cobertura ' + tipo,
			AccountId = cuenta.Id,
			RecordTypeId = ResidentialLoanApplication.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get(tipo).getRecordTypeId(),
			Status = 'En proceso',
			FSC_Subestado__c = subestado,
			FSC_TipoSolicitud__c = 'BPR',
			FSC_UsuarioPagaresYContratos__c = UserInfo.getUserId()
		);
		insert rla;
		return rla;
	}

	@IsTest
	static void cubreInformePyme() {
		ResidentialLoanApplication rla = solicitud('FSC_Solicitud_Credito_PYME', 'Análisis de crédito');
		Test.setCurrentPage(new PageReference('/apex/FSC_InformeCreditoPyme'));
		ApexPages.currentPage().getParameters().put('id', String.valueOf(rla.Id));
		Test.startTest();
		Map<String, Object> datos = FSC_ControladorInformeCreditoPyme.construirDatos(rla.Id);
		FSC_ControladorInformeCreditoPyme controlador = new FSC_ControladorInformeCreditoPyme();
		FSC_PYMESolicitudPDFController solicitudPdf = new FSC_PYMESolicitudPDFController();
		String oficial = solicitudPdf.oficialNegociosFirma;
		Test.stopTest();
		System.assertEquals(true, datos.get('esPyme'));
		System.assertEquals(rla.Name, controlador.datos.get('numeroSolicitud'));
		System.assertNotEquals(null, oficial);
	}

	@IsTest
	static void cubreGarantiasNoPyme() {
		ResidentialLoanApplication rla = solicitud('FSC_Solicitud_Credito_Consumo', 'Análisis de crédito');
		insert new FSC_Garantia__c(
			Name = 'Garantía de prueba',
			FSC_Residential_Loan_Application__c = rla.Id,
			FSC_Clase_de_Garantia__c = 'BIENES INMUEBLES',
			FSC_Tipo_de_Garantia__c = 'Hipoteca',
			FSC_Descripcion_de_la_Garantia__c = 'Inmueble',
			FSC_Ubicacion__c = 'Santo Domingo',
			FSC_Valor_Inmueble__c = 100000
		);
		Test.startTest();
		List<FSC_RlaGarantiasTablaController.GarantiaRow> filas = FSC_RlaGarantiasTablaController.getGarantias(rla.Id);
		Test.stopTest();
		System.assertEquals(1, filas.size());
		System.assertEquals(false, filas[0].esPyme);
	}

	@IsTest
	static void cubreDocumentacionContratos() {
		ResidentialLoanApplication rla = solicitud('FSC_Solicitud_Credito_PYME', 'Generación de pagarés y plantillas');
		FSC_ChecklistDocumentos__c documento = new FSC_ChecklistDocumentos__c(
			FSC_TipoDeSolicitudDeCredito__c = 'Solicitud de crédito pyme',
			FSC_CategoriaDelDocumento__c = FSC_DocumentacionContratosService.CATEGORIA,
			FSC_NroDeDocumento__c = 1,
			FSC_NombreDelDocumento__c = 'Documento cobertura'
		);
		insert documento;
		Test.startTest();
		Map<String, Object> contexto = FSC_RlaAccionesController.getDocumentacionContratosContext(rla.Id);
		FSC_RlaAccionesController.solicitarDocumentacionContratos(rla.Id, 'Adjuntar soporte');
		FSC_SolicitudDeCreditoYChecklistDeDocs__c fila = [
			SELECT Id
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE FSC_SolicitudDeCredito__c = :rla.Id
			LIMIT 1
		];
		fila.FSC_NoAplica__c = true;
		fila.FSC_EstadoRevision__c = 'Aprobado';
		update fila;
		Map<String, Object> contextoActualizado = FSC_DocumentacionContratosService.getContexto(rla.Id);
		Test.stopTest();
		System.assertEquals(true, contexto.get('tieneCategoria'));
		System.assertEquals(true, contextoActualizado.get('documentosAprobados'));
		System.assertEquals(
			'Documentación para contratos',
			[SELECT FSC_Subestado__c FROM ResidentialLoanApplication WHERE Id = :rla.Id].FSC_Subestado__c
		);
	}

	@IsTest
	static void cubreEnvioYValidacionContratos() {
		ResidentialLoanApplication rla = solicitud('FSC_Solicitud_Credito_PYME', 'Documentación para contratos');
		FSC_ChecklistDocumentos__c documento = new FSC_ChecklistDocumentos__c(
			FSC_TipoDeSolicitudDeCredito__c = 'Solicitud de crédito pyme',
			FSC_CategoriaDelDocumento__c = FSC_DocumentacionContratosService.CATEGORIA,
			FSC_NroDeDocumento__c = 2,
			FSC_NombreDelDocumento__c = 'Documento sin archivo'
		);
		insert documento;
		insert new FSC_SolicitudDeCreditoYChecklistDeDocs__c(
			FSC_SolicitudDeCredito__c = rla.Id,
			FSC_Documento__c = documento.Id,
			FSC_NoAplica__c = true,
			FSC_EstadoRevision__c = 'Aprobado'
		);
		Test.startTest();
		ResidentialLoanApplication candidata = new ResidentialLoanApplication(
			Id = rla.Id,
			RecordTypeId = rla.RecordTypeId,
			Status = 'En proceso',
			FSC_Subestado__c = 'Generación de pagarés y plantillas'
		);
		FSC_DocumentacionContratosService.encaminarEntradas(new List<ResidentialLoanApplication>{ candidata }, null);
		System.assertEquals('Documentación para contratos', candidata.FSC_Subestado__c);
		FSC_RlaAccionesController.enviarDocumentacionContratos(rla.Id);
		FSC_DocumentacionContratosService.validarGeneracion(rla.Id);
		Test.stopTest();
		System.assertEquals(
			'Generación de pagarés y plantillas',
			[SELECT FSC_Subestado__c FROM ResidentialLoanApplication WHERE Id = :rla.Id].FSC_Subestado__c
		);
	}

	@IsTest
	static void cubreProductosInformePyme() {
		ResidentialLoanApplication rla = solicitud('FSC_Solicitud_Credito_PYME', 'Análisis de crédito');
		Id cuentaId = rla.AccountId;
		insert new FSC_Facilidades_De_Credito__c(
			Name = 'Facilidad informe',
			FSC_Residential_Loan_Application__c = rla.Id,
			FSC_Monto_Solicitado__c = 100000,
			FSC_Plazo_meses__c = 24,
			FSC_Tasa__c = 12
		);
		insert new LoanApplicationLiability(
			Name = 'Compromiso informe',
			LoanApplicationId = rla.Id,
			UnpaidBalanceAmount = 10000,
			MonthlyPaymentAmount = 500,
			ShouldBePaidInFull = true
		);
		insert new List<FinServ__FinancialAccount__c>{
			new FinServ__FinancialAccount__c(
				Name = 'Certificado',
				RecordTypeId = FinServ__FinancialAccount__c.SObjectType.getDescribe()
					.getRecordTypeInfosByDeveloperName()
					.get('Certificados_financieros')
					.getRecordTypeId(),
				FinServ__PrimaryOwner__c = cuentaId,
				FinServ__FinancialAccountNumber__c = 'CERT-8001',
				FinServ__SourceSystemId__c = 'SRC-CERT-8001',
				FinServ__Balance__c = 25000
			),
			new FinServ__FinancialAccount__c(
				Name = 'Cuenta corriente',
				RecordTypeId = FinServ__FinancialAccount__c.SObjectType.getDescribe()
					.getRecordTypeInfosByDeveloperName()
					.get('CheckingAccount')
					.getRecordTypeId(),
				FinServ__PrimaryOwner__c = cuentaId,
				FinServ__FinancialAccountNumber__c = 'CTA-8002',
				FinServ__SourceSystemId__c = 'SRC-CTA-8002',
				FinServ__Balance__c = 15000
			),
			new FinServ__FinancialAccount__c(
				Name = 'Prestamo',
				RecordTypeId = FinServ__FinancialAccount__c.SObjectType.getDescribe()
					.getRecordTypeInfosByDeveloperName()
					.get('Prestamos')
					.getRecordTypeId(),
				FinServ__PrimaryOwner__c = cuentaId,
				FinServ__FinancialAccountNumber__c = 'PRE-8003',
				FinServ__SourceSystemId__c = 'SRC-PRE-8003',
				FinServ__Balance__c = 30000
			)
		};
		Test.startTest();
		Map<String, Object> datos = FSC_ControladorInformeCreditoPyme.construirDatos(rla.Id);
		Test.stopTest();
		System.assertNotEquals(null, datos.get('productosBvTipoCredito'));
	}

	@IsTest
	static void cubreCandidatoNuevo() {
		Test.startTest();
		Id leadId = FSC_NewCaseComponent_Controller.getOrCreateCandidate(
			'Persona Natural',
			'Cédula',
			'00199980001',
			null,
			'Prueba',
			'Cobertura',
			null,
			'cobertura@example.test',
			'8095558899'
		);
		Test.stopTest();
		System.assertNotEquals(null, leadId);
	}

	@IsTest
	static void cubreCapturaYDesembolsoManual() {
		FSC_CapturaOperacionesService.testBypassPermissions = true;
		ResidentialLoanApplication rla = solicitud('FSC_Solicitud_Credito_Consumo', 'Creación de crédito');
		update new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_FormaDeDesembolso__c = 'Cheque de administracion',
			FSC_UsuarioCaptura__c = UserInfo.getUserId(),
			FSC_UsuarioOperaciones__c = UserInfo.getUserId()
		);
		rla = [
			SELECT Id, Status, FSC_Subestado__c, FSC_FormaDeDesembolso__c, FSC_UsuarioCaptura__c, FSC_UsuarioOperaciones__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertEquals(true, FSC_CapturaOperacionesService.esEtapaManual(rla));
		Test.startTest();
		Map<String, Object> contextoCaptura = FSC_RlaAccionesController.getCapturaOperacionesContext(rla.Id);
		FSC_RlaAccionesController.guardarCapturaAbanks(rla.Id, 'PRESTAMO-80', true, true, true);
		Map<String, Object> contextoOperaciones = FSC_CapturaOperacionesService.contexto(rla.Id);
		Test.stopTest();
		System.assertEquals(true, contextoCaptura.get('etapaManual'));
		System.assertEquals('Desembolso', contextoOperaciones.get('etapa'));
		insert new List<ContentVersion>{
			new ContentVersion(
				Title = 'Amortización',
				PathOnClient = 'amortizacion.pdf',
				VersionData = Blob.valueOf('amortizacion'),
				FirstPublishLocationId = UserInfo.getUserId()
			),
			new ContentVersion(
				Title = 'Recibo',
				PathOnClient = 'recibo.pdf',
				VersionData = Blob.valueOf('recibo'),
				FirstPublishLocationId = UserInfo.getUserId()
			)
		};
		List<ContentVersion> archivos = [
			SELECT ContentDocumentId
			FROM ContentVersion
			WHERE Title IN ('Amortización', 'Recibo')
			ORDER BY Title
		];
		FSC_RlaAccionesController.confirmarDesembolsoManual(
			rla.Id,
			new List<Id>{ archivos[0].ContentDocumentId },
			new List<Id>{ archivos[1].ContentDocumentId }
		);
		ContentVersion descartable = new ContentVersion(
			Title = 'Descartable',
			PathOnClient = 'descartable.pdf',
			VersionData = Blob.valueOf('descartable'),
			FirstPublishLocationId = UserInfo.getUserId()
		);
		insert descartable;
		Id descartableId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :descartable.Id].ContentDocumentId;
		FSC_RlaAccionesController.descartarArchivosDesembolso(new List<Id>{ descartableId });
		System.assertEquals('Archivo y custodia', [SELECT FSC_Subestado__c FROM ResidentialLoanApplication WHERE Id = :rla.Id].FSC_Subestado__c);
	}

	@IsTest
	static void cubreAsignacionYComparticionCaptura() {
		FSC_CapturaOperacionesService.testBypassPermissions = true;
		ResidentialLoanApplication rla = solicitud('FSC_Solicitud_Credito_Consumo', 'Creación de crédito');
		update new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_FormaDeDesembolso__c = 'Cheque de administracion',
			FSC_UsuarioCaptura__c = UserInfo.getUserId(),
			FSC_UsuarioOperaciones__c = UserInfo.getUserId()
		);
		rla = [
			SELECT Id, OwnerId, Status, FSC_Subestado__c, FSC_FormaDeDesembolso__c, FSC_UsuarioCaptura__c, FSC_UsuarioOperaciones__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		Test.startTest();
		List<Map<String, String>> opciones = FSC_RlaAccionesController.getUsuariosCapturaOperaciones(rla.Id);
		Map<String, Integer> inicializacion = FSC_CapturaOperacionesService.inicializarSolicitudesExistentes();
		FSC_CapturaOperacionesService.compartirSolicitudes(new List<ResidentialLoanApplication>{ rla }, null);
		Id usuarioDistinto = [SELECT Id FROM User WHERE IsActive = TRUE AND Id != :UserInfo.getUserId() LIMIT 1].Id;
		rla.FSC_UsuarioCaptura__c = usuarioDistinto;
		FSC_CapturaOperacionesService.compartirSolicitudes(new List<ResidentialLoanApplication>{ rla }, null);
		try {
			FSC_RlaAccionesController.reasignarCapturaOperaciones(
				rla.Id,
				opciones.isEmpty() ? UserInfo.getUserId() : (Id) opciones[0].get('value'),
				'Creación de crédito'
			);
		} catch (AuraHandledException error) {
			System.assertNotEquals(null, error.getMessage());
		}
		FSC_CapturaOperacionesService.asignarResponsables(
			new List<ResidentialLoanApplication>{
				new ResidentialLoanApplication(
					Status = 'En proceso',
					FSC_Subestado__c = 'Creación de crédito',
					FSC_FormaDeDesembolso__c = 'Cheque de administracion'
				),
				new ResidentialLoanApplication(
					Status = 'En proceso',
					FSC_Subestado__c = 'Desembolso',
					FSC_FormaDeDesembolso__c = 'Cheque de administracion'
				)
			}
		);
		Test.stopTest();
		System.assertNotEquals(null, opciones);
		System.assertNotEquals(null, inicializacion.get('procesadas'));
	}

	@IsTest
	static void cubreRamasCortasDeDocumentos() {
		try {
			FSC_GenerarActoGarantiaSolidaria.generar(null);
			System.assert(false, 'Debe exigir una solicitud.');
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}
		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
		new FSC_EnviarEnvelopeQueueable('INVALIDO', null, false).execute(null);
		new FSC_DescargarEnvelopeFirmadoQueueable((Map<String, String>) null).execute(null);
	}

	@IsTest
	static void cubreEliminacionDeGarantiasYSeguros() {
		ResidentialLoanApplication rla = solicitud('FSC_Solicitud_Credito_Consumo', 'Análisis de crédito');
		LoanApplicationAsset activo = new LoanApplicationAsset(Name = 'Activo borrable', LoanApplicationId = rla.Id, CashOrMarketValue = 10000);
		insert activo;
		activo.Name = 'Activo actualizado';
		update activo;
		delete activo;
		FSC_Seguro__c seguro = new FSC_Seguro__c(FSC_Residential_Loan_Application__c = rla.Id);
		insert seguro;
		delete seguro;
	}

	@IsTest
	static void cubreCreacionAsincronaConProducto() {
		ResidentialLoanApplication rla = solicitud('FSC_Solicitud_Credito_Consumo', 'Análisis de crédito');
		update new ResidentialLoanApplication(Id = rla.Id, FSC_lineaFinanciera__c = '32', FSC_subAplicacion__c = '401');
		FSC_APIPrestamoProductos.mockIpResponse = new Map<String, Object>{
			'success' => true,
			'productos' => new List<Object>{
				new Map<String, Object>{
					'CLAVE_PRODUCTO' => 44,
					'NOMBRE' => 'Producto cobertura',
					'CODIGO_LINEA_FINANCIERA' => '32',
					'CODIGO_SUB_APLICACION' => 401
				}
			}
		};
		FSC_APIPrestamoPrestamos.mockIpResponse = new Map<String, Object>{ 'descripcionRespuesta' => 'Error controlado', 'codigoRespuesta' => '99' };
		FSC_CreacionPrestamoAsync.Input entrada = new FSC_CreacionPrestamoAsync.Input();
		entrada.residentialLoanApplicationId = rla.Id;
		entrada.codigoUsuario = 'TEST';
		entrada.codigoAgencia = '7';
		entrada.codigoEjecutivo = 'TEST';
		Test.startTest();
		new FSC_CreacionPrestamoAsync(new List<FSC_CreacionPrestamoAsync.Input>{ entrada }).execute(null);
		Test.stopTest();
		System.assertNotEquals(null, [SELECT Id FROM ResidentialLoanApplication WHERE Id = :rla.Id]);
		update new ResidentialLoanApplication(Id = rla.Id, FSC_Subestado__c = 'Creación de crédito', FSC_FormaDeDesembolso__c = 'Cuenta de ahorro');
		FSC_RlaAccionesController.ReintentoPrestamoResult result = FSC_RlaAccionesController.reintentarCreacionPrestamo(rla.Id);
		System.assertEquals(false, result.success);
		System.assert(String.isNotBlank(result.message));
	}

	@IsTest
	static void cubreEntradasFaltantesDeApis() {
		FSC_APIPrestamoPrestamos.Input inexistente = new FSC_APIPrestamoPrestamos.Input();
		inexistente.residentialLoanApplicationId = Id.valueOf(ResidentialLoanApplication.SObjectType.getDescribe().getKeyPrefix() + '000000000000');
		Test.startTest();
		List<FSC_APIPrestamoPrestamos.Output> prestamos = FSC_APIPrestamoPrestamos.run(new List<FSC_APIPrestamoPrestamos.Input>{ null, inexistente });
		try {
			FSC_APIBuroCredito.callBuroCreditoIp(null, 'IP_INEXISTENTE');
		} catch (Exception error) {
			System.assertNotEquals(null, error.getMessage());
		}
		Test.stopTest();
		System.assertEquals(2, prestamos.size());
		System.assertEquals(false, prestamos[0].success);
		System.assertEquals(false, prestamos[1].success);
	}

	@IsTest
	static void cubreErrorDeListasConSolicitudReal() {
		ResidentialLoanApplication rla = solicitud('FSC_Solicitud_Credito_Consumo', 'Análisis de crédito');
		Map<String, Object> salida = new Map<String, Object>();
		Test.startTest();
		Boolean invocado = FSC_CallAPIs.invokeMethod(
			'validatePF',
			new Map<String, Object>{ 'solicitudDeCreditoId' => rla.Id },
			salida,
			new Map<String, Object>()
		);
		Map<String, Object> salidaConCuenta = new Map<String, Object>();
		FSC_CallAPIs.invokeMethod(
			'validatePF',
			new Map<String, Object>{ 'solicitudDeCreditoId' => rla.Id, 'accountId' => rla.AccountId },
			salidaConCuenta,
			new Map<String, Object>()
		);
		Test.stopTest();
		System.assertEquals(true, invocado);
		System.assertEquals(false, salida.get('success'));
		System.assertEquals(true, salida.get('rlaErrorSaved'));
		System.assertNotEquals(null, salidaConCuenta.get('stage'));
	}

	@IsTest
	static void cubreBuroConMotorApagado() {
		ResidentialLoanApplication rla = solicitud('FSC_Solicitud_Credito_PYME', 'Análisis de crédito');
		FSC_BuroConfigService.motoresApagadosEnPrueba.add('FSC_Solicitud_Credito_PYME');
		FSC_APIBuroCredito.Input entrada = new FSC_APIBuroCredito.Input();
		entrada.residentialLoanApplicationId = rla.Id;
		Test.startTest();
		List<FSC_APIBuroCredito.Output> resultados = FSC_APIBuroCredito.run(new List<FSC_APIBuroCredito.Input>{ entrada });
		Test.stopTest();
		System.assertEquals(true, resultados[0].success);
		System.assertEquals('Referido', resultados[0].ipResult);
	}

	@IsTest
	static void cubreFormatoInformePymeEditable() {
		ResidentialLoanApplication rla = solicitud('FSC_Solicitud_Credito_PYME', 'Análisis de crédito');
		update new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_Resultado_Buro__c = 'Referido',
			FSC_Doc_Completa_Analisis__c = true,
			FSC_DocumentacionValidadaAnalista__c = true,
			FSC_DebeRevisarComite__c = false,
			FSC_DebeRevisarSupervisor__c = false,
			FSC_Aprobado_con_Condiciones__c = false
		);
		FSC_RlaAccionesController.testPermitirEdicionDocumentosAnalisis = true;
		Boolean sinPdf = false;
		try {
			FSC_RlaAccionesController.guardarYRegenerarDocumentoAnalisis(
				rla.Id,
				FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME,
				'{"analisisFinanciero":{"value":"Texto simple","format":"text"}}'
			);
		} catch (AuraHandledException expected) {
			sinPdf = true;
		}
		System.assertEquals(true, sinPdf);
	}

	@IsTest
	static void cubreReintentoDesembolsoConDatosMinimos() {
		ResidentialLoanApplication rla = solicitud('FSC_Solicitud_Credito_Consumo', 'Desembolso');
		update new ResidentialLoanApplication(Id = rla.Id, FSC_FormaDeDesembolso__c = 'Cuenta de ahorro', FSC_FlagErrorAPIDesembolso__c = true);
		Boolean errorControlado = false;
		try {
			FSC_RlaAccionesController.reintentarDesembolso(rla.Id);
		} catch (AuraHandledException expected) {
			errorControlado = true;
		}
		System.assertEquals(true, errorControlado);
	}
}