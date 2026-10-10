@IsTest
private class FSC_ContratoPrestamoVariantesTest {
	private static String firstPicklistValue(Schema.SObjectField field) {
		for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
			if (entry.isActive()) return entry.getValue();
		}
		return null;
	}

	private static LoanApplicant applicant(Id rlaId, String type, String suffix) {
		return new LoanApplicant(
			Name = type + ' ' + suffix,
			LoanApplicationId = rlaId,
			FSC_TipoSolicitante__c = type,
			FSC_TipoIdentificacion__c = firstPicklistValue(LoanApplicant.FSC_TipoIdentificacion__c),
			FSC_Nombre__c = type,
			FSC_PrimerApellido__c = suffix,
			FSC_NumIdentificacion__c = '00100000' + suffix,
			FSC_Nacionalidad__c = firstPicklistValue(LoanApplicant.FSC_Nacionalidad__c),
			FSC_EstadoCivil__c = firstPicklistValue(LoanApplicant.FSC_EstadoCivil__c)
		);
	}
    @IsTest
    static void shouldInitializeSimpleContractControllers() {
        ApexPages.StandardController standardController =
            FSC_ContratoPrestamoCtrlTestHelper.buildUnsavedStandardController();

        FSC_ContratoConsumoHipotecarioCtrl hipotecario =
            new FSC_ContratoConsumoHipotecarioCtrl(standardController);
        FSC_ContratoPrestamoComercialSFCtrl solaFirma =
            new FSC_ContratoPrestamoComercialSFCtrl(standardController);

        System.assertEquals(null, hipotecario.loanApplication);
        System.assertEquals(null, solaFirma.loanApplication);
        System.assertEquals(true, hipotecario.getHasAnnexImage());
        System.assertEquals(true, solaFirma.getHasAnnexImage());
    }

	@IsTest
	static void shouldInitializeVehicleContractInterveners() {
		FSC_FabricaDatosDocumentosAnalisisTest.crearDatosBase();
		Account account = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		account.ACC_RNC__c = '101123456';
		account.VFS_RegistroMercantil__c = 'RM-VEHICULO';
		account.BillingState = 'Distrito Nacional';
		update account;

		ResidentialLoanApplication rla = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			account.Id,
			'FSC_Solicitud_Credito_Vehiculo',
			'En proceso',
			'Generación de contrato',
			900000,
			true
		);
		Map<String, Object> interveners = new Map<String, Object>{
			'codeudor_0_domicilio' => 'Santo Domingo',
			'garanteContrato_0_domicilio' => 'Santo Domingo',
			'garanteContrato_1_domicilio' => 'Santiago'
		};
		update new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_Moneda__c = '1',
			FSC_MontoAprobado__c = 850000,
			FSC_TasaInteresAprobada__c = 12,
			FSC_Fecha_Contrato__c = Date.today(),
			FSC_Propietario_Garantia_Vehiculo__c = FSC_VehiculoDocumentoResolver.PROPIETARIO_DISTINTO,
			FSC_RNC_Cliente_Contrato__c = '101123456',
			FSC_Registro_Mercantil_Contrato__c = 'RM-VEHICULO',
			FSC_Domicilio_Cliente_Contrato__c = 'Santo Domingo',
			FSC_Nombre_Representante_Cliente__c = 'Representante Cliente',
			FSC_Cargo_Representante_Cliente__c = 'Gerente',
			FSC_Nacionalidad_Representante__c = 'REPUBLICA DOMINICANA',
			FSC_Estado_Civil_Representante__c = 'SOLTERO/A',
			FSC_Identificacion_Representante__c = '00112345678',
			FSC_Domicilio_Representante__c = 'Santo Domingo',
			FSC_Resolucion_Autorizacion__c = 'Acta de autorización',
			FSC_Fecha_Acta_Autorizacion__c = Date.today(),
			FSC_Personas_Autorizadas__c = 'Representante Cliente',
			FSC_Calidad_Autorizados__c = 'Gerente',
			FSC_Datos_Intervinientes_Contrato__c = JSON.serialize(interveners)
		);

		insert new List<LoanApplicant>{
			applicant(rla.Id, FSC_ContratoIntervinienteService.TIPO_CODEUDOR, '101'),
			applicant(rla.Id, FSC_ContratoIntervinienteService.TIPO_GARANTE, '102'),
			applicant(rla.Id, FSC_ContratoIntervinienteService.TIPO_GARANTE, '103')
		};
		insert new FSC_Garantia__c(
			Name = 'Vehículo contrato',
			FSC_Residential_Loan_Application__c = rla.Id,
			FSC_Clase_de_Garantia__c = 'VEHICULOS USADOS-P2',
			FSC_Tipo_de_Garantia__c = 'Vehículo',
			FSC_Tipo_Vehiculo__c = 'Automóvil',
			FSC_Marca_Vehiculo__c = 'Aval',
			FSC_Modelo_Vehiculo__c = 'Jolion',
			FSC_Ano_Vehiculo__c = Date.today().year() - 1,
			FSC_Color_Vehiculo__c = 'Blanco',
			FSC_Numero_Chasis_Vehiculo__c = 'CHASIS-TEST',
			FSC_Serial_Motor_Vehiculo__c = 'MOTOR-TEST',
			FSC_Numero_Placa_Vehiculo__c = 'A000001',
			FSC_Numero_Matricula__c = 'MAT-TEST',
			FSC_Valor_Vehiculo__c = 950000,
			FSC_Ubicacion__c = 'Santo Domingo'
		);
		// El plazo aprobado de un crédito vehicular se valida contra el año del vehículo, así que va después de la garantía.
		update new ResidentialLoanApplication(Id = rla.Id, FSC_PlazoMesesAprobado__c = 36);
		insert new FSC_Seguro__c(
			FSC_Residential_Loan_Application__c = rla.Id,
			FSC_Numero_Poliza_Contrato__c = 'POL-TEST',
			FSC_Aseguradora_Contrato__c = 'Aseguradora Test',
			FSC_Direccion_Aseguradora_Contrato__c = 'Santo Domingo',
			FSC_Fecha_Endoso_Contrato__c = Date.today(),
			FSC_Monto_Asegurado_Contrato__c = 950000,
			FSC_Monto_de_la_Prima__c = 2500
		);

		Test.startTest();
		FSC_ContratoPrestamoConsumoVehiculoCtrl controller =
			new FSC_ContratoPrestamoConsumoVehiculoCtrl(new ApexPages.StandardController(rla));
		Test.stopTest();

		System.assertEquals(true, controller.vehiculo.tieneGaranteMobiliario);
		System.assertEquals(2, controller.vehiculo.garantes.size());
		System.assert(!String.isBlank(controller.vehiculo.nombresFirmantesNotario));
	}
}