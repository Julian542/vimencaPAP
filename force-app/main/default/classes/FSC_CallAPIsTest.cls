@IsTest
private class FSC_CallAPIsTest {

    private static Account createAccount() {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
            FirstName = 'Cuenta',
            LastName = 'Test',
            ACC_TipoIdentificacion__c = 'Cédula',
            ACC_NumIdentificacion__c = '00108803610'
        );
        insert acc;
        return acc;
    }

    private class ValidatePFMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true}');
            return res;
        }
    }

    @IsTest
    static void testInvokeMethod_validatePF() {
        Account acc = createAccount();

        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            Name = 'RLA Test Desembolso',
            AccountId = acc.Id
        );

        Map<String, Object> inputMap = new Map<String, Object>{
            'accountId' => acc.Id,
            'solicitudDeCreditoId' => rla.Id
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.setMock(HttpCalloutMock.class, new ValidatePFMock());

        Test.startTest();
        Boolean result = FSC_CallAPIs.invokeMethod(
            'validatePF',
            inputMap,
            outMap,
            options
        );
        Test.stopTest();

        System.assertEquals(true, result, 'Debe devolver true cuando el metodo es valido');
        System.assert(outMap.containsKey('coincidenciaLE') || outMap.containsKey('errorMessage'));
    }

    @IsTest
    static void testInvokeMethod_invalidMethod() {
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Test.startTest();
        Boolean result = FSC_CallAPIs.invokeMethod(
            'metodoInvalido',
            inputMap,
            outMap,
            options
        );
        Test.stopTest();

        System.assertEquals(false, result, 'Debe devolver false cuando el metodo no existe');
    }

    @IsTest
    static void testCall_validatePF() {
        Account acc = createAccount();

        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            Name = 'RLA Test Desembolso',
            AccountId = acc.Id
        );

        Map<String, Object> inputMap = new Map<String, Object>{
            'accountId' => acc.Id,
            'solicitudDeCreditoId' => rla.Id
        };
        
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => inputMap,
            'output' => outMap,
            'options' => options
        };

        FSC_CallAPIs service = new FSC_CallAPIs();

        Test.setMock(HttpCalloutMock.class, new ValidatePFMock());

        Test.startTest();
        Object resultObj = service.call('validatePF', args);
        Test.stopTest();

        System.assertEquals(true, (Boolean) resultObj, 'call debe retornar true');
        System.assert(outMap.containsKey('coincidenciaLE') || outMap.containsKey('errorMessage'));
    }

    @IsTest
    static void testCall_withInvalidArgs_entersCatch() {
        FSC_CallAPIs service = new FSC_CallAPIs();
        Map<String, Object> args = new Map<String, Object>();

        Test.startTest();
        Object resultObj = service.call('validatePF', args);
        Test.stopTest();

        System.assertEquals(false, (Boolean) resultObj, 'Debe devolver false si ocurre excepción');
    }
}
