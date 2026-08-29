@IsTest
private class FSC_ActaComitePDFControllerTest {

    private static Account createAccount(String name) {
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = name,
            ACC_RNC__c = '131000002',
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert account;
        return account;
    }

    private static ResidentialLoanApplication createRLA(
        Id accountId,
        DateTime fechaAprobacion,
        Boolean aprobadaPorComite,
        Decimal montoSolicitado,
        Decimal montoAprobado,
        Decimal plazoSolicitado,
        Decimal plazoAprobado,
        Boolean aplicaGarantia
    ) {
        ResidentialLoanApplication rla = new ResidentialLoanApplication();
        rla.AccountId = accountId;
        rla.FSC_SolicitudAprobadaPorComite__c = aprobadaPorComite;
        rla.FSC_FechaYHoraAprobacionComite__c = fechaAprobacion;
        rla.Name = 'Test RLA ' + String.valueOf(fechaAprobacion);
        rla.FSC_Monto__c = montoSolicitado;
        rla.FSC_MontoAprobado__c = montoAprobado;
        rla.FSC_PlazoMeses__c = plazoSolicitado;
        rla.FSC_PlazoMesesAprobado__c = plazoAprobado;
        rla.FSC_TasaInteres__c = 12.34;
        rla.FSC_TasaInteresAprobada__c = 10.11;
        rla.FSC_Aplica_Garantia__c = aplicaGarantia;
        rla.FSC_DecisionComite__c = 'Aprobada con condición';
        rla.FSC_CondicionComite__c = 'COND';
        rla.FSC_ObservacionesComite__c = 'OBS';
        rla.FSC_Cuotas__c = 1;
        rla.FSC_TipoCredito__c = '01 - CONSUMO';
        rla.FSC_Tipo_de_Garantia__c = 'Garantía Real';

        insert rla;
        return rla;
    }

    private static void createGuarantee(Id rlaId, String assetType, Decimal value, String descripcion) {
        LoanApplicationAsset laa = new LoanApplicationAsset();
        laa.LoanApplicationId = rlaId;
        laa.AssetType = assetType;
        laa.CashOrMarketValue = value;
        laa.Name = 'Name ' + assetType;
        laa.FSC_Descripcion_de_la_Garantia__c = descripcion;
        insert laa;
    }

    @IsTest
    static void testController_withRecordsAndAssets() {
        Account acc = createAccount('Cliente Test');

        Date actaDate = Date.today();
        DateTime dtInRange = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 12, 0, 0);

        ResidentialLoanApplication rla1 = createRLA(
            acc.Id,
            dtInRange,
            true,
            1000,
            900,
            10,
            9,
            true
        );

        createGuarantee(rla1.Id, 'HIPOTECA', 5000, 'Casa');
        createGuarantee(rla1.Id, 'PRENDA', 2000, 'Auto');

        DateTime dtOutRange = dtInRange.addDays(-1);
        createRLA(acc.Id, dtOutRange, true, 2000, 1500, 12, 10, false);

        Test.startTest();
        PageReference pr = Page.FSC_ActaComitePDF;
        Test.setCurrentPage(pr);

        ApexPages.currentPage().getParameters().put('actaDate', String.valueOf(actaDate));
        ApexPages.currentPage().getParameters().put('actaNumero', 'NUM-TEST');
        ApexPages.currentPage().getParameters().put('horaInicio', '08:00');
        ApexPages.currentPage().getParameters().put('horaFin', '09:00');

        FSC_ActaComitePDFController ctrl = new FSC_ActaComitePDFController();
        Test.stopTest();

        System.assertEquals('NUM-TEST', ctrl.actaNumero, 'Debe tomar actaNumero de params');
        System.assertNotEquals(null, ctrl.actaFecha, 'Debe calcular actaFecha');
        System.assertEquals('08:00', ctrl.horaInicio);
        System.assertEquals('09:00', ctrl.horaFin);

        System.assertNotEquals(null, ctrl.textoQuorum);
        System.assertNotEquals(null, ctrl.textoObjetivo);

        System.assertEquals(1, ctrl.actas.size(), 'Solo debe incluir el RLA del día (1 registro)');

        FSC_ActaComitePDFController.ActaRow row = ctrl.actas[0];
        System.assertEquals(1, row.numero);
        System.assertEquals('Oficina Principal', row.sucursal);
        System.assertEquals('Cliente Test', row.nombreCliente);
        System.assert(row.montoSolicitado != null && row.montoSolicitado.startsWith('$ '), 'Formato dinero solicitado');
        System.assert(row.montoAprobado != null && row.montoAprobado.startsWith('$ '), 'Formato dinero aprobado');

        System.assertEquals('HIPOTECA', row.garantiaPrincipal);
        System.assert(row.valorGarantiaPrincipal.startsWith('$ '));
        System.assertEquals('Casa', row.descGarantiaPrincipal);

        System.assertEquals('PRENDA', row.garantiaSecundaria);
        System.assert(row.valorGarantiaSecundaria.startsWith('$ '));
        System.assertEquals('Auto', row.descGarantiaSecundaria);
    }

    @IsTest
    static void testController_noAssets_noCrash() {
        Account acc = createAccount('Cliente Sin Garantias');

        Date actaDate = Date.today();
        DateTime dtInRange = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 10, 0, 0);

        createRLA(acc.Id, dtInRange, true, 3000, 2500, 6, 6, false);

        Test.startTest();
        Test.setCurrentPage(Page.FSC_ActaComitePDF);
        ApexPages.currentPage().getParameters().put('actaDate', String.valueOf(actaDate));

        FSC_ActaComitePDFController ctrl = new FSC_ActaComitePDFController();
        Test.stopTest();

        System.assertEquals(1, ctrl.actas.size());
        FSC_ActaComitePDFController.ActaRow row = ctrl.actas[0];

        System.assertEquals('', row.garantiaPrincipal);
        System.assertEquals('', row.valorGarantiaPrincipal);
        System.assertEquals('', row.descGarantiaPrincipal);
        System.assertEquals('', row.garantiaSecundaria);
        System.assertEquals('', row.valorGarantiaSecundaria);
        System.assertEquals('', row.descGarantiaSecundaria);
    }
}
