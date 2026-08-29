@IsTest
private class BasicModelCoverageTest {
    @IsTest
    static void coversSimpleModelsAndEmptyQueue() {
        VimencashModel.ApiMessage message = new VimencashModel.ApiMessage('OK', 'Procesado');
        System.assertEquals('OK', message.codigo);

        FlowMapClass mapEntry = new FlowMapClass();
        mapEntry.key = 'origen';
        mapEntry.value = 'test';
        System.assertEquals('test', mapEntry.value);

        REST_Referencia.ReferenciaDTO reference = new REST_Referencia.ReferenciaDTO();
        reference.ACC_CIF_c = 'CIF-TEST';
        System.assertEquals('CIF-TEST', reference.ACC_CIF_c);
        System.assertNotEquals(null, new REST_Referencia.ResponseWrapper());

        new OpportunityTCPPrequalificationQueue(null).execute(null);
    }

    @IsTest
    static void coversLookupAndRestResponses() {
        FSC_LookupSearchResult first = new FSC_LookupSearchResult('1', 'Account', 'standard:account', 'A', 'Uno');
        FSC_LookupSearchResult second = new FSC_LookupSearchResult('2', 'Account', 'standard:account', 'B', 'Dos');
        FSC_LookupSearchResult untitled = new FSC_LookupSearchResult('3', null, null, null, null);
        System.assertEquals('1', first.getId());
        System.assertEquals('Account', first.getSObjectType());
        System.assertEquals('standard:account', first.getIcon());
        System.assertEquals('Uno', first.getSubtitle());
        System.assert(first.compareTo(second) < 0);
        System.assertEquals(1, untitled.compareTo(first));
        System.assertEquals(0, untitled.compareTo(untitled));

        RestContext.response = new RestResponse();
        VimencashModel.respondError(400, 'Solicitud invalida', 'campo requerido');
        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Solicitud invalida'));

        RestContext.response = new RestResponse();
        VimencashModel.respondError(500, 'Error interno', 'detalle');
        System.assertEquals(500, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('traceId'));
        System.assert(VimencashModel.isBlank(' '));
    }

    @IsTest
    static void rejectsRncValidationOutsideInitialState() {
        Account account = TestDataFactory_FSC.createJuridicAccounts(1)[0];
        account.ACC_Estado__c = 'CALIFICADO';
        update account;

        INT002_VARNC_Controller_FSC.Response response =
            INT002_VARNC_Controller_FSC.updateAccountRNC(account.Id);

        System.assertEquals(200, response.httpRequestStatusCode);
        System.assertEquals('000', response.errorCode);
        System.assertEquals(false, response.updateSuccess);
    }

    @IsTest
    static void validatesRncAndUpdatesInitialAccount() {
        Account account = TestDataFactory_FSC.createJuridicAccounts(1)[0];
        account.ACC_Estado__c = 'INICIADO';
        account.ACC_RNC__c = '00100058007';
        update account;

        Test.setMock(HttpCalloutMock.class, new INT002TestMock('PJ'));
        Test.startTest();
        INT002_VARNC_Controller_FSC.Response response =
            INT002_VARNC_Controller_FSC.updateAccountRNC(account.Id);
        Test.stopTest();

        System.assertEquals(200, response.httpRequestStatusCode);
        System.assertEquals('000', response.errorCode);
        System.assertEquals(true, response.updateSuccess);
        Account updated = [SELECT ACC_Estado__c, ACC_RNC__c FROM Account WHERE Id = :account.Id];
        System.assertEquals('CALIFICADO', updated.ACC_Estado__c);
        System.assertEquals('502598856', updated.ACC_RNC__c);
    }
}
