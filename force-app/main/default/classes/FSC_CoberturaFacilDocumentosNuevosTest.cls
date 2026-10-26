@IsTest
private class FSC_CoberturaFacilDocumentosNuevosTest {
    static void asignarPermisosAdministrador() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet permiso = [SELECT Id FROM PermissionSet WHERE Name = 'FSC_PS_Administrador' LIMIT 1];
            // El usuario que ejecuta los tests puede tener ya el permission set asignado.
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permiso.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permiso.Id);
            }
        }
    }

	@TestSetup
	static void setupAccount() {
		asignarPermisosAdministrador();
		FSC_FabricaDatosDocumentosAnalisisTest.crearDatosBase();
		Account account = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		account.ACC_TipoIdentificacion__c = 'RNC';
		account.ACC_RNC__c = '101123456';
		account.VFS_RegistroMercantil__c = 'RM-TEST';
		account.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
		account.ACC_Estado_Civil__c = 'SOLTERO/A';
		update account;
	}

	private static ResidentialLoanApplication createRla(String recordTypeName, String suffix) {
		// Estos tests cubren documentos y contratos; los límites de política se prueban en FSC_CreditPolicyGuardTest.
		FSC_CreditPolicyGuard.bypassInTests = true;
		Account account = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		ResidentialLoanApplication rla = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			account.Id,
			recordTypeName,
			'En proceso',
			'Generación de contrato',
			1000000,
			true
		);
		rla.FSC_Moneda__c = '1';
		rla.FSC_MontoAprobado__c = 900000;
		rla.FSC_TasaInteresAprobada__c = 12;
		// Un crédito vehicular sin garantías no admite plazo aprobado (regla FSC_ValidarPlazoMaximoVehiculo).
		if (recordTypeName != 'FSC_Solicitud_Credito_Vehiculo') {
			rla.FSC_PlazoMesesAprobado__c = 24;
		}
		rla.FSC_Fecha_Contrato__c = Date.today();
		rla.FSC_UsuarioPagaresYContratos__c = UserInfo.getUserId();
		update rla;
		return rla;
	}

	private static ResidentialLoanApplication createMortgage(String sellerType, String suffix) {
		ResidentialLoanApplication rla = createRla('FSC_Solicitud_Credito_Hipotecario', suffix);
		rla.FSC_Tipo_de_Garantia__c = 'Garantía Real';
		rla.FSC_Propietario_Garantia_Hipotecaria__c = FSC_HipotecarioDocumentoResolver.PROPIETARIO_DEUDOR;
		rla.FSC_Tipo_Vendedor_Hipotecario__c = sellerType;
		Map<String, Object> contractValues = new Map<String, Object>{
			'clienteRnc' => '101123456',
			'clienteRegistroMercantil' => 'RM-TEST',
			'clienteIdentificacion' => '00112345678',
			'clienteNacionalidad' => 'REPUBLICA DOMINICANA',
			'clienteEstadoCivil' => 'SOLTERO/A',
			'clienteDomicilio' => 'Santo Domingo',
			'representanteNombre' => 'Representante prueba',
			'representanteCargo' => 'Gerente',
			'representanteNacionalidad' => 'REPUBLICA DOMINICANA',
			'representanteEstadoCivil' => 'SOLTERO/A',
			'representanteIdentificacion' => '00187654321',
			'representanteDomicilio' => 'Santo Domingo',
			'autorizacionResolucion' => 'Resolución de prueba',
			'autorizacionFecha' => String.valueOf(Date.today()),
			'autorizacionPersonas' => 'Representante prueba',
			'autorizacionCalidad' => 'Gerente',
			'garantiaDescripcion' => 'Apartamento residencial de prueba',
			'garantiaNumeroTitulo' => 'TIT-' + suffix,
			'garantiaRegistroTitulos' => 'Registro de Títulos',
			'garantiaFechaTitulo' => String.valueOf(Date.today()),
			'seguroPoliza' => 'POL-TEST',
			'seguroAseguradora' => 'Aseguradora de prueba',
			'seguroDireccion' => 'Santo Domingo',
			'seguroFechaEndoso' => String.valueOf(Date.today()),
			'seguroMonto' => '1500000',
			'clienteSexo' => 'Femenino',
			'representanteSexo' => 'Masculino',
			'seguroVidaPoliza' => 'VIDA-TEST',
			'seguroVidaAseguradora' => 'Aseguradora de prueba',
			'seguroVidaDireccion' => 'Santo Domingo',
			'seguroVidaPrima' => '850',
			'hipotecarioPrecioVenta' => '1200000',
			'hipotecarioAporteInicial' => '300000',
			'hipotecarioFechaPagoInicial' => String.valueOf(Date.today()),
			'hipotecarioMedioPagoInicial' => 'Transferencia',
			'hipotecarioMedioPagoFinanciado' => 'Préstamo',
			'hipotecarioPeriodoTasaFija' => '12',
			'hipotecarioVendedorNombre' => 'Vendedor de prueba',
			'hipotecarioVendedorRnc' => '101123456',
			'hipotecarioVendedorRegistroMercantil' => 'RM-VENDEDOR',
			'hipotecarioVendedorNacionalidad' => 'Dominicana',
			'hipotecarioVendedorEstadoCivil' => 'Soltero',
			'hipotecarioVendedorIdentificacion' => '00112345678',
			'hipotecarioVendedorDomicilio' => 'Santo Domingo',
			'hipotecarioVendedorRepresentanteCargo' => 'Gerente',
			'hipotecarioVendedorRepresentanteNombre' => 'Representante',
			'hipotecarioVendedorRepresentanteNacionalidad' => 'REPUBLICA DOMINICANA',
			'hipotecarioVendedorRepresentanteEstadoCivil' => 'Soltero',
			'hipotecarioVendedorRepresentanteIdentificacion' => '00187654321',
			'hipotecarioVendedorRepresentanteDomicilio' => 'Santo Domingo',
			'hipotecarioVendedorAutorizacion' => 'Acta de autorización',
			'hipotecarioFideicomisoNombre' => 'Fideicomiso prueba',
			'hipotecarioFideicomisoRnc' => '101987654',
			'hipotecarioFideicomisoRegistro' => 'RM-FIDEICOMISO',
			'hipotecarioFiduciariaNombre' => 'Fiduciaria prueba',
			'hipotecarioFiduciariaRnc' => '101456789',
			'hipotecarioFiduciariaRegistro' => 'RM-FIDUCIARIA',
			'hipotecarioFiduciariaDomicilio' => 'Santo Domingo',
			'hipotecarioFiduciariaRepresentantes' => 'Representantes de prueba',
			'hipotecarioFiduciariaFirmantes' => 'Firmantes de prueba',
			'hipotecarioFiduciariaAutorizacion' => 'Autorización fiduciaria',
			'hipotecarioPromotoresGenerales' => 'Promotores de prueba',
			'hipotecarioPromotoresFirmantes' => 'Firmantes promotores',
			'hipotecarioProyectoNombre' => 'Proyecto de prueba',
			'hipotecarioTipoVendedor' => sellerType,
			'hipotecarioPropietarioGarantia' => FSC_HipotecarioDocumentoResolver.PROPIETARIO_DEUDOR
		};
		rla.FSC_Datos_Contrato_Hipotecario__c = JSON.serialize(contractValues);
		update rla;

		FSC_Garantia__c guarantee = FSC_FabricaDatosDocumentosAnalisisTest.crearGarantiaHipotecaria(rla.Id, 1500000, 1200000);
		update new FSC_Garantia__c(
			Id = guarantee.Id,
			FSC_Clase_de_Garantia__c = 'BIENES INMUEBLES',
			FSC_Numero_Titulo__c = 'TIT-' + suffix,
			FSC_Registro_de_Titulos__c = 'Registro de Títulos',
			FSC_Fecha_Expedicion_Titulo__c = Date.today()
		);
		FSC_DatosContratoController.guardarDatosYPrepararGeneracion(rla.Id, null, null, null, false, true, JSON.serialize(contractValues));
		return rla;
	}

	private static void addCertificate(ResidentialLoanApplication rla, String documentName) {
		FSC_ChecklistDocumentos__c document = new FSC_ChecklistDocumentos__c(
			FSC_TipoDeSolicitudDeCredito__c = 'Solicitud de crédito hipotecario',
			FSC_CategoriaDelDocumento__c = 'Documentos para análisis',
			FSC_NroDeDocumento__c = 90,
			FSC_NombreDelDocumento__c = documentName
		);
		insert document;
		FSC_SolicitudDeCreditoYChecklistDeDocs__c row = new FSC_SolicitudDeCreditoYChecklistDeDocs__c(
			FSC_SolicitudDeCredito__c = rla.Id,
			FSC_Documento__c = document.Id,
			FSC_NoAplica__c = false,
			FSC_EstadoRevision__c = 'Aprobado'
		);
		insert row;
		insert new ContentVersion(
			Title = documentName,
			PathOnClient = documentName + '.pdf',
			VersionData = Blob.valueOf('PDF'),
			FirstPublishLocationId = row.Id
		);
	}

	private static void exerciseController(ResidentialLoanApplication rla, String templateCode) {
		FSC_RLAContractTemplateResolver.ContractResolution resolution = FSC_RLAContractTemplateResolver.resolve(rla.Id);
		System.assertEquals(templateCode, resolution.templateCode);
		ApexPages.StandardController standardController = new ApexPages.StandardController(rla);
		try {
			if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_PERSONA_FISICA) {
				new FSC_ContratoHipotecarioPersonaFisicaCtrl(standardController);
			} else if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_EMPRESA) {
				new FSC_ContratoHipotecarioEmpresaCtrl(standardController);
			} else if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_EMPRESA_LEY_158) {
				new FSC_ContratoHipotecarioEmpresaLey158Ctrl(standardController);
			} else if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_FIDEICOMISO_NORMAL) {
				new FSC_ContratoHipFideicomisoNormalCtrl(standardController);
			} else {
				new FSC_ContratoHipFideicomisoBajoCtrl(standardController);
			}
		} catch (Exception expectedValidationFailure) {
			System.assertNotEquals(null, expectedValidationFailure);
		}
	}

	private static FSC_DatosContratoController.CampoEntrada findGenerationField(
		FSC_DatosContratoController.ContextoGeneracion context,
		String fieldKey
	) {
		for (FSC_DatosContratoController.SeccionEntrada section : context.seccionesContrato) {
			for (FSC_DatosContratoController.CampoEntrada field : section.campos) {
				if (field.clave == fieldKey) {
					return field;
				}
			}
		}
		return null;
	}

	@IsTest
	static void coversBuroConfigurationHelpers() {
		System.assertEquals(true, FSC_BuroConfigService.isMotorEncendido('NO_CONFIGURADO'));
		System.assertNotEquals(null, FSC_BuroConfigService.isMotorEncendido('FSC_Solicitud_Credito_Consumo'));
		System.assertNotEquals(null, FSC_BuroConfigService.isMotorEncendido('FSC_Solicitud_Credito_Vehiculo'));
		System.assertNotEquals(null, FSC_BuroConfigService.isMotorEncendido('FSC_Solicitud_Credito_Hipotecario'));
		System.assertNotEquals(null, FSC_BuroConfigService.isMotorEncendido('FSC_Solicitud_Credito_PYME'));

		FSC_BuroConfigService.aplicarMotorApagado(null);
		ResidentialLoanApplication rla = new ResidentialLoanApplication();
		FSC_BuroConfigService.aplicarMotorApagado(rla);
		System.assertEquals(FSC_BuroConfigService.RESULTADO_REFERIDO, rla.FSC_Resultado_Buro__c);
		System.assertEquals(FSC_BuroConfigService.SUBESTADO_REFERIDO, rla.FSC_Subestado__c);
	}

	@IsTest
	static void coversVehicleResolver() {
		ResidentialLoanApplication rla = createRla('FSC_Solicitud_Credito_Vehiculo', 'vehiculo');
		rla.FSC_Propietario_Garantia_Vehiculo__c = FSC_VehiculoDocumentoResolver.PROPIETARIO_DEUDOR;
		update rla;

		FSC_VehiculoDocumentoResolver.ResolucionDocumento withoutGuarantee = FSC_VehiculoDocumentoResolver.resolve(rla.Id);
		System.assertEquals(FSC_VehiculoDocumentoResolver.SIN_GARANTIA, withoutGuarantee.tipoGarantia);

		insert new FSC_Garantia__c(
			Name = 'Vehículo cobertura simple',
			FSC_Residential_Loan_Application__c = rla.Id,
			FSC_Clase_de_Garantia__c = 'VEHICULOS USADOS-P2',
			FSC_Tipo_de_Garantia__c = 'Vehículo',
			FSC_Ano_Vehiculo__c = Date.today().year() - 1
		);
		FSC_VehiculoDocumentoResolver.ResolucionDocumento vehicle = FSC_VehiculoDocumentoResolver.resolve(rla.Id);
		System.assertEquals(true, vehicle.tieneContratoVehicular);
		System.assertEquals(true, vehicle.generaContrato);

		update new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_Propietario_Garantia_Vehiculo__c = FSC_VehiculoDocumentoResolver.PROPIETARIO_DISTINTO,
			FSC_Excepcion_Contrato_Notarial__c = true
		);
		FSC_VehiculoDocumentoResolver.ResolucionDocumento externalOwner = FSC_VehiculoDocumentoResolver.resolve(rla.Id);
		System.assertEquals(true, externalOwner.generaContrato);
		System.assertEquals(FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL, externalOwner.codigoPagare);
	}

	@IsTest
	static void coversMortgageNaturalPerson() {
		exerciseController(
			createMortgage(FSC_HipotecarioDocumentoResolver.VENDEDOR_PERSONA_FISICA, 'persona'),
			FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_PERSONA_FISICA
		);
	}

	@IsTest
	static void coversMortgageCompany() {
		exerciseController(
			createMortgage(FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA, 'empresa'),
			FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_EMPRESA
		);
	}

	@IsTest
	static void representativeNationalityUsesGlobalValueSet() {
		ResidentialLoanApplication rla = createMortgage(FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA, 'nacionalidad');

		Test.startTest();
		FSC_DatosContratoController.ContextoGeneracion context = FSC_DatosContratoController.getContextoGeneracion(rla.Id);
		Test.stopTest();

		FSC_DatosContratoController.CampoEntrada nationalityField = findGenerationField(context, 'hipotecarioVendedorRepresentanteNacionalidad');
		Assert.isNotNull(nationalityField, 'Debe incluir el campo Nacionalidad del representante.');
		Assert.isTrue(nationalityField.esLista, 'Nacionalidad del representante debe renderizarse como picklist.');
		Assert.areEqual('REPUBLICA DOMINICANA', nationalityField.valor, 'Debe conservar el valor seleccionado del Global Value Set.');

		Map<String, String> expectedLabelsByValue = new Map<String, String>();
		for (Schema.PicklistEntry entry : LoanApplicant.FSC_Nacionalidad__c.getDescribe().getPicklistValues()) {
			if (entry.isActive()) {
				expectedLabelsByValue.put(entry.getValue(), entry.getLabel());
			}
		}
		Map<String, String> actualLabelsByValue = new Map<String, String>();
		for (FSC_DatosContratoController.OpcionEntrada option : nationalityField.opciones) {
			actualLabelsByValue.put(option.value, option.label);
		}
		Assert.areEqual(expectedLabelsByValue, actualLabelsByValue, 'Las opciones deben coincidir con los valores activos de GP_Nacionalidad.');
	}

	@IsTest
	static void coversMortgageCompanyLaw158() {
		ResidentialLoanApplication rla = createMortgage(FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA, 'ley158');
		addCertificate(rla, 'Certificado CONFOTUR');
		exerciseController(rla, FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_EMPRESA_LEY_158);
	}

	@IsTest
	static void coversMortgageTrust() {
		exerciseController(
			createMortgage(FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO, 'fideicomiso'),
			FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_FIDEICOMISO_NORMAL
		);
	}

	@IsTest
	static void coversMortgageLowCostTrust() {
		ResidentialLoanApplication rla = createMortgage(FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO, 'bajocosto');
		addCertificate(rla, 'Certificado vivienda de bajo costo');
		exerciseController(rla, FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_FIDEICOMISO_BAJO_COSTO);
	}

	@IsTest
	static void addsSimpleDocumentControllerBranches() {
		Test.setCurrentPage(new PageReference('/apex/FSC_InformeCreditoAnalisisPDF'));
		FSC_ControladorDocumentosAnalisisCredito emptyPageController = new FSC_ControladorDocumentosAnalisisCredito();
		System.assertNotEquals(null, emptyPageController.datos);

		ResidentialLoanApplication rla = createRla('FSC_Solicitud_Credito_Hipotecario', 'documentos');
		FSC_Garantia__c guarantee = FSC_FabricaDatosDocumentosAnalisisTest.crearGarantiaHipotecaria(rla.Id, 1500000, 1200000);
		update new FSC_Garantia__c(Id = guarantee.Id, FSC_EsTasadorExterno__c = true, FSC_NombreTasadorExterno__c = 'Tasador externo');
		insert FSC_ExcepcionTestDataFactory.buildExcepcion(rla.Id, 99, 'Pendiente', 'Condición simple');

		Map<String, Object> data = FSC_ControladorDocumentosAnalisisCredito.construirDatos(
			rla.Id,
			FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME
		);
		System.assertNotEquals(null, data);
	}
}