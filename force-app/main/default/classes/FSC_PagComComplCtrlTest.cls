@IsTest
private class FSC_PagComComplCtrlTest {
	private static Account createNeutralAccount(String name, String identification, String street) {
		Account acc = new Account(
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
			Name = name,
			ACC_RNC__c = identification.substring(0, 9),
			ACC_NumIdentificacion__c = identification,
			ACC_Condicion__c = 'PROSPECTO',
			ACC_Estado__c = 'INICIADO',
			ACC_TipoIdentificacion__c = 'RNC',
			BillingStreet = street,
			BillingCity = 'Santo Domingo',
			BillingCountry = 'DO'
		);
		insert acc;
		return acc;
	}

	@IsTest
	static void controller_loadsActoNumeroPagare() {
		Account acc = createNeutralAccount('Cuenta Ctrl Pagare', '00108803610', 'Calle 1');

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Ctrl Pagare',
			AccountId = acc.Id,
			Status = 'En proceso',
			FSC_Subestado__c = 'Generación de pagarés y plantillas',
			FSC_ActoNumeroPagare__c = 'ACT999',
			FSC_NumeroFolioPagare__c = 62,
			FSC_Monto__c = 1200,
			FSC_MontoAprobado__c = 1200,
			FSC_Plazo_meses__c = '12',
			FSC_PlazoMesesAprobado__c = 12,
			FSC_TasaInteres__c = 12,
			FSC_TasaInteresAprobada__c = 12,
			FSC_Aprobado_con_Condiciones__c = true
		);
		insert rla;

		Test.setCurrentPage(Page.FSC_PagarePDF);
		ApexPages.currentPage().getParameters().put('id', rla.Id);

		Test.startTest();
		FSC_PagareComercialComplementarioCtrl ctrl = new FSC_PagareComercialComplementarioCtrl(new ApexPages.StandardController(rla));
		Test.stopTest();

		System.assertEquals('ACT999', ctrl.actoNumeroPagare);
		System.assertEquals('62', ctrl.numeroFolioPagare);
		System.assertEquals(acc.Name, ctrl.nombreCliente);
		System.assertEquals('001-0880361-0', ctrl.cedula);
		System.assertEquals('1.200,00', ctrl.valorMonto);
		System.assertEquals(acc.Name, ctrl.nombreDeudorFirma);
		System.assert(ctrl.direccion.contains('Calle 1'));
	}

	@IsTest
	static void controller_usesRequestedValuesWhenNotApprovedWithConditions() {
		Account acc = createNeutralAccount('Cuenta Ctrl Sin Condiciones', '00108803611', 'Calle 2');

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Ctrl Sin Condiciones',
			AccountId = acc.Id,
			FSC_Monto__c = 1500,
			FSC_MontoAprobado__c = 1,
			FSC_Plazo_meses__c = '18',
			FSC_PlazoMesesAprobado__c = 1,
			FSC_TasaInteres__c = 15,
			FSC_TasaInteresAprobada__c = 1,
			FSC_Aprobado_con_Condiciones__c = false
		);
		insert rla;

		Test.setCurrentPage(Page.FSC_PagarePDF);
		ApexPages.currentPage().getParameters().put('id', rla.Id);

		Test.startTest();
		FSC_PagareComercialComplementarioCtrl ctrl = new FSC_PagareComercialComplementarioCtrl(new ApexPages.StandardController(rla));
		Test.stopTest();

		System.assertEquals('1.500,00', ctrl.valorMonto);
		System.assertEquals('18', ctrl.plazoMeses);
		System.assertEquals(15, ctrl.tasaInteres);
		System.assert(ctrl.plazoAniosTexto.contains('Y SEIS MESES'));
	}

	@IsTest
	static void helperMethods_coverAdditionalBranches() {
		System.assertEquals('CERO', FSC_PagareComercialComplementarioCtrl.toWordsEs(0));
		System.assertEquals('UNO', FSC_PagareComercialComplementarioCtrl.toWordsEs(1));
		System.assert(FSC_PagareComercialComplementarioCtrl.toWordsEs(21).contains('VEINTI'));
		System.assert(FSC_PagareComercialComplementarioCtrl.toWordsEs(35).contains('Y'));
		System.assertEquals('CIEN', FSC_PagareComercialComplementarioCtrl.toWordsEs(100));
		System.assert(FSC_PagareComercialComplementarioCtrl.toWordsEs(101).contains('CIENTO'));
		System.assert(FSC_PagareComercialComplementarioCtrl.toWordsEs(1500).contains('MIL'));
		System.assert(FSC_PagareComercialComplementarioCtrl.toWordsEs(2500000).contains('MILLONES'));

		System.assertEquals('CERO', FSC_PagareComercialComplementarioCtrl.toWordsEsPlazo(0));
		System.assertEquals('UN', FSC_PagareComercialComplementarioCtrl.toWordsEsPlazo(1));
		System.assert(FSC_PagareComercialComplementarioCtrl.toWordsEsPlazo(21).contains('VEINTI'));
		System.assert(FSC_PagareComercialComplementarioCtrl.toWordsEsPlazo(1500).contains('MIL'));

		System.assertEquals('enero', FSC_PagareComercialComplementarioCtrl.mesEnLetras(1));
		System.assertEquals('veinte', FSC_PagareComercialComplementarioCtrl.numeroALetras_0_99(20));
		System.assert(FSC_PagareComercialComplementarioCtrl.numeroALetras_0_99(31).contains('y'));
		System.assertEquals('UNO CON 50/100', FSC_PagareComercialComplementarioCtrl.numberToWordsEs(1.5));
		System.assertEquals('15.000,00', FSC_PagareComercialComplementarioCtrl.formatAmountEs(15000));
		System.assertEquals('031-0024559-0', FSC_PagareComercialComplementarioCtrl.formatCedula('03100245590'));
		System.assertEquals(
			'a los uno (1) días del mes de enero del año dos mil veintiséis (2026)',
			FSC_PagareComercialComplementarioCtrl.fechaNotarial(Date.newInstance(2026, 1, 1))
		);
	}

	@IsTest
	static void helperMethods_throwForUnsupportedValues() {
		Boolean invalidYearThrown = false;
		Boolean invalidDayThrown = false;

		try {
			FSC_PagareComercialComplementarioCtrl.fechaNotarial(Date.newInstance(1999, 1, 1));
		} catch (Exception e) {
			invalidYearThrown = true;
		}

		try {
			FSC_PagareComercialComplementarioCtrl.numeroALetras_0_99(120);
		} catch (Exception e) {
			invalidDayThrown = true;
		}

		System.assertEquals(true, invalidYearThrown);
		System.assertEquals(true, invalidDayThrown);
		System.assertEquals(0, FSC_PagareComercialComplementarioCtrl.modLong(5, 0));
	}
}
