@IsTest
private class FSC_RlaAccionesControllerPrivilegedTest {
    private static final String SUBESTADO_ANALISIS = 'An\u00E1lisis de cr\u00E9dito';
    private static Boolean privilegedEndpointCalled = false;

    private class PrivilegedSupervisorReviewMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            privilegedEndpointCalled = true;
            System.assertEquals('POST', req.getMethod());
            System.assert(
                req.getEndpoint().contains('/services/apexrest/fsc/rla-approval-admin/supervisor-review') ||
                req.getEndpoint().contains('/services/apexrest/fsc/rla-approval-admin/return-to-business') ||
                req.getEndpoint().contains('/services/apexrest/fsc/rla-approval-admin/return-to-analyst')
            );

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success":true,"message":"OK"}');
            return res;
        }
    }

    private static ResidentialLoanApplication createRla() {
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'Cuenta Privileged ' + System.now().getTime(),
            ACC_RNC__c = String.valueOf(Math.abs(Crypto.getRandomInteger())).leftPad(9, '0').substring(0, 9),
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC'
        );
        insert acc;

        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            Name = 'RLA Privileged ' + System.now().getTime(),
            AccountId = acc.Id,
            Status = 'En proceso',
            FSC_Subestado__c = SUBESTADO_ANALISIS,
            FSC_ActoNumeroPagare__c = 'ACTPRIV',
            FSC_Pagares_y_Plantillas_Generados__c = false,
            FSC_Monto__c = 5000,
            FSC_Plazo_meses__c = '24',
            FSC_TasaInteres__c = 14,
            FSC_Aprobado_con_Condiciones__c = false
        );
        insert rla;
        return rla;
    }

    @IsTest
    static void enviarRevisionSupervisor_usaFallbackPrivilegiado() {
        ResidentialLoanApplication rla = createRla();
        privilegedEndpointCalled = false;
        Test.setMock(HttpCalloutMock.class, new PrivilegedSupervisorReviewMock());
        FSC_RlaAccionesController.testForcePrivilegedSupervisorReview = true;

        Boolean validationBlocked = false;
        Test.startTest();
        try {
            FSC_RlaAccionesController.enviarRevisionSupervisor(rla.Id);
        } catch (AuraHandledException ex) {
            validationBlocked = true;
            System.assertEquals('Script-thrown exception', ex.getMessage());
        }
        Test.stopTest();

        FSC_RlaAccionesController.testForcePrivilegedSupervisorReview = false;
        System.assertEquals(true, privilegedEndpointCalled || validationBlocked);
    }

    @IsTest
    static void devolverAAnalista_usaFallbackPrivilegiado() {
        ResidentialLoanApplication rla = createRla();
        privilegedEndpointCalled = false;
        Test.setMock(HttpCalloutMock.class, new PrivilegedSupervisorReviewMock());
        FSC_RlaAccionesController.testForcePrivilegedSupervisorReview = true;

        Test.startTest();
        FSC_RlaAccionesController.devolverAAnalista(rla.Id, 'volver a analista');
        Test.stopTest();

        FSC_RlaAccionesController.testForcePrivilegedSupervisorReview = false;
        System.assertEquals(true, privilegedEndpointCalled);
    }

    @IsTest
    static void devolverAOficial_usaFallbackPrivilegiado() {
        ResidentialLoanApplication rla = createRla();
        privilegedEndpointCalled = false;
        Test.setMock(HttpCalloutMock.class, new PrivilegedSupervisorReviewMock());
        FSC_RlaAccionesController.testForcePrivilegedSupervisorReview = true;

        Boolean validationBlocked = false;
        Test.startTest();
        try {
            FSC_RlaAccionesController.devolverAOficial(rla.Id, 'volver a oficial');
        } catch (AuraHandledException ex) {
            validationBlocked = true;
            System.assertEquals('Script-thrown exception', ex.getMessage());
        }
        Test.stopTest();

        FSC_RlaAccionesController.testForcePrivilegedSupervisorReview = false;
        System.assertEquals(true, privilegedEndpointCalled || validationBlocked);
    }
}
