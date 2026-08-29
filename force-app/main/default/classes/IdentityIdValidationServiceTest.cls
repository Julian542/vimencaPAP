@IsTest
private class IdentityIdValidationServiceTest {

    private static final String RT_PERSON_DEVNAME   = 'PersonAccount';
    private static final String RT_BUSINESS_DEVNAME = 'IndustriesHousehold';

    private class AccountCreateMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml');
            res.setStatusCode(200);
            res.setBody(
                '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
                    '<soap:Body>' +
                        '<ListOfBREAIFuncionGeneral>' +
                            '<Result>' +
                                '<ErrorCode>000</ErrorCode>' +
                                '<ErrorText>TRANSACCION PROCESADA</ErrorText>' +
                                '<Response><CIF>258968542</CIF></Response>' +
                            '</Result>' +
                        '</ListOfBREAIFuncionGeneral>' +
                    '</soap:Body>' +
                '</soap:Envelope>'
            );
            return res;
        }
    }

    private static Id getRtId(String devName) {
        return [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
              AND DeveloperName = :devName
            LIMIT 1
        ].Id;
    }

    private static Account basePersonAcc() {
        Test.setMock(HttpCalloutMock.class, new AccountCreateMock());
        Account a = new Account();
        a.RecordTypeId = getRtId(RT_PERSON_DEVNAME);
        a.FirstName = 'Test';
        a.LastName  = 'Person ' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        a.ACC_Condicion__c = 'CLIENTE';
        a.ACC_TipoIdentificacion__c = 'Cédula';
        return a;
    }

    private static Account baseBusinessAcc() {
        Test.setMock(HttpCalloutMock.class, new AccountCreateMock());
        Account a = new Account();
        a.RecordTypeId = getRtId(RT_BUSINESS_DEVNAME);
        a.Name = 'Test Biz ' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        a.ACC_Condicion__c = 'CLIENTE';
        return a;
    }

    private static String idNorm(String raw) {
        String s = raw == null ? null : raw.trim();
        if (s == null) return null;
        s = s.replace(' ', '').replace('-', '').replace('.', '').replace('/', '');
        s = s.replaceAll('[^a-zA-Z0-9]', '');
        return s.toUpperCase();
    }

    @IsTest
    static void test_invalid_input_blank_or_short() {
        IdentityIdValidationService.Request r1 = new IdentityIdValidationService.Request();
        r1.identificationNumber = '  ';
        r1.messagingSessionId = null;

        IdentityIdValidationService.Response res1 = IdentityIdValidationService.validate(r1);
        System.assertEquals(false, res1.isValid);
        System.assertEquals('INVALID_INPUT', res1.status);
        System.assertEquals(false, res1.sessionLinked);

        IdentityIdValidationService.Request r2 = new IdentityIdValidationService.Request();
        r2.identificationNumber = '1234';
        r2.messagingSessionId = null;

        IdentityIdValidationService.Response res2 = IdentityIdValidationService.validate(r2);
        System.assertEquals(false, res2.isValid);
        System.assertEquals('INVALID_INPUT', res2.status);
        System.assertEquals(false, res2.sessionLinked);
    }

    @IsTest
    static void test_not_found() {
        IdentityIdValidationService.Request r = new IdentityIdValidationService.Request();
        r.identificationNumber = idNorm('000999888');
        r.messagingSessionId = null;

        IdentityIdValidationService.Response res = IdentityIdValidationService.validate(r);

        System.assertEquals(false, res.isValid);
        System.assertEquals('NOT_FOUND', res.status);
        System.assertEquals(0, res.matches);
        System.assertEquals(false, res.sessionLinked);
    }

    @IsTest
    static void test_person_ok_without_session_link() {
        String doc = idNorm('030-3456');

        Account a = basePersonAcc();
        a.ACC_Estado__c = 'ACTIVO';
        a.ACC_NumIdentificacion__c = doc;
        a.ACC_Correo_Electronico_Cliente__c = 'florencia.harmath@gmail.com';
        insert a;

        IdentityIdValidationService.Request r = new IdentityIdValidationService.Request();
        r.identificationNumber = '030-3456';
        r.messagingSessionId = null;

        IdentityIdValidationService.Response res = IdentityIdValidationService.validate(r);

        System.assertEquals(true, res.isValid);
        System.assertEquals('OK', res.status);
        System.assertEquals('PERSON', res.accountType);
        System.assertEquals(a.Id, res.accountId);
        System.assertEquals(1, res.matches);
        System.assertEquals('ACTIVO', res.accountStatus);
        System.assertEquals('florencia.harmath@gmail.com', res.email);
        System.assertNotEquals(null, res.maskedEmail);
        System.assertEquals(false, res.sessionLinked);
        System.assertEquals('No se recibió messagingSessionId o accountId.', res.sessionLinkMessage);
    }

    @IsTest
    static void test_multiple_active_person() {
        String doc = idNorm('123450001');

        Account a1 = basePersonAcc();
        a1.ACC_Estado__c = 'ACTIVO';
        a1.ACC_NumIdentificacion__c = doc;
        a1.ACC_Correo_Electronico_Cliente__c = 'a1@test.com';

        Account a2 = basePersonAcc();
        a2.ACC_Estado__c = 'ACTIVO';
        a2.ACC_NumIdentificacion__c = doc;
        a2.ACC_Correo_Electronico_Cliente__c = 'a2@test.com';

        insert new List<Account>{ a1, a2 };

        IdentityIdValidationService.Request r = new IdentityIdValidationService.Request();
        r.identificationNumber = '123450001';
        r.messagingSessionId = null;

        IdentityIdValidationService.Response res = IdentityIdValidationService.validate(r);

        System.assertEquals(false, res.isValid);
        System.assertEquals('MULTIPLE_ACTIVE', res.status);
        System.assertEquals(2, res.matches);
        System.assertEquals(false, res.sessionLinked);
    }

    @IsTest
    static void test_not_active_person_fallback() {
        String doc = idNorm('7777777');

        Account a = basePersonAcc();
        a.ACC_Estado__c = 'INACTIVO';
        a.ACC_NumIdentificacion__c = doc;
        a.ACC_Correo_Electronico_Cliente__c = 'na@test.com';
        insert a;

        IdentityIdValidationService.Request r = new IdentityIdValidationService.Request();
        r.identificationNumber = '7777777';
        r.messagingSessionId = null;

        IdentityIdValidationService.Response res = IdentityIdValidationService.validate(r);

        System.assertEquals(false, res.isValid);
        System.assertEquals('NOT_ACTIVE', res.status);
        System.assertEquals('PERSON', res.accountType);
        System.assertEquals(a.Id, res.accountId);
        System.assertEquals('INACTIVO', res.accountStatus);
        System.assertEquals(false, res.sessionLinked);
    }

    @IsTest
    static void test_business_ok_without_session_link() {
        String rnc = idNorm('1-01-99999-9');

        Account a = baseBusinessAcc();
        a.ACC_Estado__c = 'ACTIVO';
        a.ACC_RNC__c = rnc;
        a.ACC_Correo_Electronico_Cliente__c = 'empresa@test.com';
        insert a;

        IdentityIdValidationService.Request r = new IdentityIdValidationService.Request();
        r.identificationNumber = '1-01-99999-9';
        r.messagingSessionId = null;

        IdentityIdValidationService.Response res = IdentityIdValidationService.validate(r);

        System.assertEquals(true, res.isValid);
        System.assertEquals('OK', res.status);
        System.assertEquals('BUSINESS', res.accountType);
        System.assertEquals(a.Id, res.accountId);
        System.assertEquals(1, res.matches);
        System.assertEquals('ACTIVO', res.accountStatus);
        System.assertEquals('empresa@test.com', res.email);
        System.assertNotEquals(null, res.maskedEmail);
        System.assertEquals(false, res.sessionLinked);
        System.assertEquals('No se recibió messagingSessionId o accountId.', res.sessionLinkMessage);
    }

    @IsTest
    static void test_not_active_business_fallback() {
        String rnc = idNorm('8888888');

        Account a = baseBusinessAcc();
        a.ACC_Estado__c = 'INACTIVO';
        a.ACC_RNC__c = rnc;
        a.ACC_Correo_Electronico_Cliente__c = 'na2@test.com';
        insert a;

        IdentityIdValidationService.Request r = new IdentityIdValidationService.Request();
        r.identificationNumber = '8888888';
        r.messagingSessionId = null;

        IdentityIdValidationService.Response res = IdentityIdValidationService.validate(r);

        System.assertEquals(false, res.isValid);
        System.assertEquals('NOT_ACTIVE', res.status);
        System.assertEquals('BUSINESS', res.accountType);
        System.assertEquals(a.Id, res.accountId);
        System.assertEquals('INACTIVO', res.accountStatus);
        System.assertEquals(false, res.sessionLinked);
    }

    @IsTest
    static void test_no_email() {
        String doc = idNorm('55555');

        Account a = basePersonAcc();
        a.ACC_Estado__c = 'ACTIVO';
        a.ACC_NumIdentificacion__c = doc;
        a.ACC_Correo_Electronico_Cliente__c = null;
        insert a;

        IdentityIdValidationService.Request r = new IdentityIdValidationService.Request();
        r.identificationNumber = '55555';
        r.messagingSessionId = null;

        IdentityIdValidationService.Response res = IdentityIdValidationService.validate(r);

        System.assertEquals(false, res.isValid);
        System.assertEquals('NO_EMAIL', res.status);
        System.assertEquals(a.Id, res.accountId);
        System.assertEquals('PERSON', res.accountType);
        System.assertEquals(false, res.sessionLinked);
    }

    @IsTest
    static void test_invocable_wrapper_person_without_session_link() {
        String doc = idNorm('33333');

        Account a = basePersonAcc();
        a.ACC_Estado__c = 'ACTIVO';
        a.ACC_NumIdentificacion__c = doc;
        a.ACC_Correo_Electronico_Cliente__c = 'invocable@test.com';
        insert a;

        IdentityIdValidationService.InvocableInput in1 = new IdentityIdValidationService.InvocableInput();
        in1.identificationNumber = '33333';
        in1.messagingSessionId = null;

        Test.startTest();
        List<IdentityIdValidationService.InvocableOutput> outs =
            IdentityIdValidationService.validateInvocable(
                new List<IdentityIdValidationService.InvocableInput>{ in1 }
            );
        Test.stopTest();

        System.assertEquals(1, outs.size());
        System.assertEquals(true, outs[0].isValid);
        System.assertEquals('OK', outs[0].status);
        System.assertEquals('PERSON', outs[0].accountType);
        System.assertEquals('invocable@test.com', outs[0].email);
        System.assertNotEquals(null, outs[0].maskedEmail);
        System.assertEquals(1, outs[0].matches);
        System.assertNotEquals(null, outs[0].accountId);
        System.assertEquals(false, outs[0].sessionLinked);
        System.assertEquals('No se recibió messagingSessionId o accountId.', outs[0].sessionLinkMessage);
    }

    @IsTest
    static void test_invocable_wrapper_invalid_input() {
        IdentityIdValidationService.InvocableInput in1 = new IdentityIdValidationService.InvocableInput();
        in1.identificationNumber = '12';
        in1.messagingSessionId = null;

        Test.startTest();
        List<IdentityIdValidationService.InvocableOutput> outs =
            IdentityIdValidationService.validateInvocable(
                new List<IdentityIdValidationService.InvocableInput>{ in1 }
            );
        Test.stopTest();

        System.assertEquals(1, outs.size());
        System.assertEquals(false, outs[0].isValid);
        System.assertEquals('INVALID_INPUT', outs[0].status);
        System.assertEquals(false, outs[0].sessionLinked);
    }

    @IsTest
static void test_person_ok_stored_vimenca_format_input_different_hyphen_format() {
    Account a = basePersonAcc();
    a.ACC_Estado__c = 'ACTIVO';
    a.ACC_NumIdentificacion__c = '00-1088036-10';
    a.ACC_Correo_Electronico_Cliente__c = 'cliente@test.com';
    insert a;

    IdentityIdValidationService.Request r = new IdentityIdValidationService.Request();
    r.identificationNumber = '0010880361-0';
    r.messagingSessionId = null;

    IdentityIdValidationService.Response res = IdentityIdValidationService.validate(r);

    System.assertEquals(true, res.isValid);
    System.assertEquals('OK', res.status);
    System.assertEquals('PERSON', res.accountType);
    System.assertEquals(a.Id, res.accountId);
    System.assertEquals(1, res.matches);
}
}
