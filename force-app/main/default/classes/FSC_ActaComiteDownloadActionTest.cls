@IsTest
private class FSC_ActaComiteDownloadActionTest {

    private static Account createAccount(String name) {
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = name,
            ACC_RNC__c = '131000001',
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert account;
        return account;
    }

    private static ResidentialLoanApplication createRLAApproved(Id accountId, DateTime approvedDt) {
        ResidentialLoanApplication rla = new ResidentialLoanApplication();
        rla.AccountId = accountId;
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
        return rla;
    }

    @IsTest
    static void testGenerateUrl_actaDateRequired() {
        Test.startTest();
        List<FSC_ActaComiteDownloadAction.Request> reqs = new List<FSC_ActaComiteDownloadAction.Request>();
        reqs.add(new FSC_ActaComiteDownloadAction.Request());

        List<FSC_ActaComiteDownloadAction.Response> resList =
            FSC_ActaComiteDownloadAction.generateUrl(reqs);
        Test.stopTest();

        System.assertEquals(1, resList.size());
        System.assertEquals(false, resList[0].success);
        System.assert(resList[0].message != null && resList[0].message.contains('actaDate'), 'Debe avisar que actaDate es requerido');
        System.assertEquals(null, resList[0].pdfUrl);
    }

    @IsTest
    static void testGenerateUrl_noApplications() {
        Date actaDate = Date.today();

        FSC_ActaComiteDownloadAction.Request req = new FSC_ActaComiteDownloadAction.Request();
        req.actaDate = actaDate;

        Test.startTest();
        List<FSC_ActaComiteDownloadAction.Response> resList =
            FSC_ActaComiteDownloadAction.generateUrl(new List<FSC_ActaComiteDownloadAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, resList.size());
        FSC_ActaComiteDownloadAction.Response res = resList[0];

        System.assertEquals(true, res.success);
        System.assertEquals(0, res.totalApplications);
        System.assertEquals(null, res.pdfUrl);
        System.assert(res.message != null && res.message.contains('No hay solicitudes'), 'Mensaje cuando no hay RLAs');
    }

    @IsTest
    static void testGenerateUrl_withApplicationsReturnsUrl() {
        Account acc = createAccount('Cliente Action');

        Date actaDate = Date.today();
        DateTime approvedDt = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 14, 30, 0);
        createRLAApproved(acc.Id, approvedDt);

        FSC_ActaComiteDownloadAction.Request req = new FSC_ActaComiteDownloadAction.Request();
        req.actaDate = actaDate;

        Test.startTest();
        List<FSC_ActaComiteDownloadAction.Response> resList =
            FSC_ActaComiteDownloadAction.generateUrl(new List<FSC_ActaComiteDownloadAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, resList.size());
        FSC_ActaComiteDownloadAction.Response res = resList[0];

        System.assertEquals(true, res.success);
        System.assertEquals(1, res.totalApplications);
        System.assertNotEquals(null, res.pdfUrl, 'Debe generar URL cuando hay RLAs');
        System.assert(res.message != null && res.message.contains('URL generada'), 'Mensaje de OK');
    }

    @IsTest
    static void testGenerateUrl_multipleRequests() {
        Account acc = createAccount('Cliente Multi');

        Date d1 = Date.today();
        Date d2 = Date.today().addDays(-1);

        createRLAApproved(acc.Id, DateTime.newInstance(d1.year(), d1.month(), d1.day(), 11, 0, 0));

        FSC_ActaComiteDownloadAction.Request r1 = new FSC_ActaComiteDownloadAction.Request();
        r1.actaDate = d1;

        FSC_ActaComiteDownloadAction.Request r2 = new FSC_ActaComiteDownloadAction.Request();
        r2.actaDate = d2;

        Test.startTest();
        List<FSC_ActaComiteDownloadAction.Response> resList =
            FSC_ActaComiteDownloadAction.generateUrl(new List<FSC_ActaComiteDownloadAction.Request>{ r1, r2 });
        Test.stopTest();

        System.assertEquals(2, resList.size());
        System.assertEquals(true, resList[0].success);
        System.assertEquals(1, resList[0].totalApplications);
        System.assertNotEquals(null, resList[0].pdfUrl);

        System.assertEquals(true, resList[1].success);
        System.assertEquals(0, resList[1].totalApplications);
        System.assertEquals(null, resList[1].pdfUrl);
    }
}
