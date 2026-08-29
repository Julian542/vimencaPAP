@IsTest
private class FSC_RlaApprovalAdminClientTest {
    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('POST', req.getMethod());
            System.assert(req.getEndpoint().contains('callout:' + FSC_RlaApprovalAdminClient.NAMED_CREDENTIAL));

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success":true,"message":"OK"}');
            return res;
        }
    }

    private class FailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"success":false,"message":"fallo tecnico"}');
            return res;
        }
    }

    @IsTest
    static void sendToSupervisor_callsNamedCredential() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        FSC_RlaApprovalAdminClient.sendToSupervisor(UserInfo.getUserId());
        Test.stopTest();
    }

    @IsTest
    static void sendToSupervisor_throwsOnHttpFailure() {
        Test.setMock(HttpCalloutMock.class, new FailureMock());

        Boolean thrown = false;
        Test.startTest();
        try {
            FSC_RlaApprovalAdminClient.sendToSupervisor(UserInfo.getUserId());
        } catch (AuraHandledException ex) {
            thrown = true;
            System.assert(String.isNotBlank(ex.getMessage()));
        }
        Test.stopTest();

        System.assertEquals(true, thrown);
    }

    @IsTest
    static void returnToAnalyst_callsNamedCredential() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        FSC_RlaApprovalAdminClient.returnToAnalyst(UserInfo.getUserId(), 'motivo test');
        Test.stopTest();
    }

    @IsTest
    static void returnToAnalyst_throwsOnHttpFailure() {
        Test.setMock(HttpCalloutMock.class, new FailureMock());

        Boolean thrown = false;
        Test.startTest();
        try {
            FSC_RlaApprovalAdminClient.returnToAnalyst(UserInfo.getUserId(), 'motivo test');
        } catch (AuraHandledException ex) {
            thrown = true;
            System.assert(String.isNotBlank(ex.getMessage()));
        }
        Test.stopTest();

        System.assertEquals(true, thrown);
    }

    @IsTest
    static void returnToBusiness_callsNamedCredential() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        FSC_RlaApprovalAdminClient.returnToBusiness(UserInfo.getUserId(), 'motivo test', 'Supervisor');
        Test.stopTest();
    }

    @IsTest
    static void returnToBusiness_throwsOnHttpFailure() {
        Test.setMock(HttpCalloutMock.class, new FailureMock());

        Boolean thrown = false;
        Test.startTest();
        try {
            FSC_RlaApprovalAdminClient.returnToBusiness(UserInfo.getUserId(), 'motivo test', 'Supervisor');
        } catch (AuraHandledException ex) {
            thrown = true;
            System.assert(String.isNotBlank(ex.getMessage()));
        }
        Test.stopTest();

        System.assertEquals(true, thrown);
    }

    @IsTest
    static void updateFormaDeDesembolso_callsNamedCredential() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        FSC_RlaApprovalAdminClient.updateFormaDeDesembolso(
            UserInfo.getUserId(), 'Cuenta de ahorro'
        );
        Test.stopTest();
    }
}
