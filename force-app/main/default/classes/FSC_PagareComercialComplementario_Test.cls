@IsTest
private class FSC_PagareComercialComplementario_Test {
	private static Account buildAccount() {
		Account a = new Account();
		a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
		a.Name = 'Cliente Prueba';
		a.ACC_NumIdentificacion__c = '00112345678';
		a.ACC_RNC__c = '131000004';
		a.ACC_TipoIdentificacion__c = 'RNC';
		a.ACC_Condicion__c = 'PROSPECTO';
		a.ACC_Estado__c = 'INICIADO';
		a.ACC_Nacionalidad__c = 'AFGANISTÁN';
		a.ACC_Estado_Civil__c = 'SOLTERO/A';
		a.BillingStreet = 'Calle 1';
		a.BillingCity = 'Santo Domingo';
		a.BillingState = 'DN';
		a.BillingCountry = 'Republica Dominicana';
		insert a;
		return a;
	}

	private static ResidentialLoanApplication buildRLA(Id accountId) {
		ResidentialLoanApplication rla = new ResidentialLoanApplication();
		rla.AccountId = accountId;
		rla.Name = 'Cliente Prueba';
		rla.FSC_MontoAprobado__c = 120000.50;
		rla.FSC_Monto__c = 120000.50;
		rla.FSC_FechaYHoraAprobacionComite__c = System.now();
		rla.FSC_PlazoMesesAprobado__c = 12;
		rla.FSC_Plazo_meses__c = '12';
		rla.FSC_Aplica_Garantia__c = true;
		rla.FSC_TasaInteresAprobada__c = 12;
		rla.FSC_TasaInteres__c = 12;
		rla.FSC_Moneda__c = '1';
		rla.FSC_Aprobado_con_Condiciones__c = true;

		insert rla;
		return rla;
	}

	private static void insertLoanApplicant(Id rlaId, String tipoSolicitante, String nombre, String primerApellido, String documento) {
		insert new LoanApplicant(
			Name = nombre + ' ' + primerApellido,
			LoanApplicationId = rlaId,
			FSC_TipoIdentificacion__c = 'Cédula',
			FSC_NumIdentificacion__c = documento,
			FSC_Nombre__c = nombre,
			FSC_PrimerApellido__c = primerApellido,
			FSC_TipoSolicitante__c = tipoSolicitante
		);
	}

	@IsTest
	static void testController_FillsFields() {
		Account a = buildAccount();
		ResidentialLoanApplication rla = buildRLA(a.Id);
		insertLoanApplicant(rla.Id, 'Deudor', 'Cliente', 'Prueba', '00100000001');
		insertLoanApplicant(rla.Id, 'Co-Deudor', 'Codeudor', 'Prueba', '00100000002');

		Test.setCurrentPage(Page.FSC_PagarePDF);
		ApexPages.currentPage().getParameters().put('id', rla.Id);

		ApexPages.StandardController sc = new ApexPages.StandardController(rla);

		Test.startTest();
		FSC_PagareComercialComplementarioCtrl ctrl = new FSC_PagareComercialComplementarioCtrl(sc);
		Test.stopTest();

		System.assertNotEquals(null, ctrl, 'Controller debe instanciar');
		System.assertEquals('001-1234567-8', ctrl.cedula, 'Debe mapear cedula desde Account');
		System.assertEquals('Cliente Prueba', ctrl.nombreCliente, 'Debe mapear nombre del cliente');
		System.assertEquals('12', ctrl.plazoMeses, 'Debe mapear plazo meses');
		System.assertEquals(12, ctrl.tasaInteres, 'Tasa interes entero');
		System.assertEquals('DOCE', ctrl.tasaInteresTexto, 'Tasa interes en letras sin centavos');
		System.assert(ctrl.valorMontoTexto.contains('CON'), 'Monto en letras debe incluir formato CON xx/100');
		System.assertNotEquals('', ctrl.cuotaMensual, 'Cuota mensual no debe venir vacia');
		System.assertNotEquals('', ctrl.direccion, 'Direccion no debe venir vacia');
		System.assertEquals(1, ctrl.getLoanApplicantFirmantesSize(), 'Debe exponer los codeudores/garantes firmantes');
		System.assertEquals('FIRMALOANAPPLICANT1', ctrl.loanApplicantFirmantes[0].firmaElementId, 'Debe usar el marcador esperado');
		System.assertEquals('Co-Deudor', ctrl.loanApplicantFirmantes[0].tipoSolicitante, 'Debe conservar el tipo de firmante');
	}

	@IsTest
	static void testController_NoComiteDate() {
		Account a = buildAccount();
		ResidentialLoanApplication rla = buildRLA(a.Id);

		rla.FSC_FechaYHoraAprobacionComite__c = null;
		update rla;

		Test.setCurrentPage(Page.FSC_PagarePDF);
		ApexPages.currentPage().getParameters().put('id', rla.Id);

		ApexPages.StandardController sc = new ApexPages.StandardController(rla);

		Test.startTest();
		FSC_PagareComercialComplementarioCtrl ctrl = new FSC_PagareComercialComplementarioCtrl(sc);
		Test.stopTest();
	}
}
