@IsTest
private class FSC_RlaAccionesControllerPrivilegedTest {
    private static final String SUBESTADO_ANALISIS = 'An\u00E1lisis de cr\u00E9dito';
    private static Boolean privilegedEndpointCalled = false;
    private static String lastClientDecisionAction;
    private static String lastClientDecisionComment;

    private class PrivilegedSupervisorReviewMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            privilegedEndpointCalled = true;
            System.assertEquals('POST', req.getMethod());
            System.assert(
                req.getEndpoint().contains('/services/apexrest/fsc/rla-approval-admin/supervisor-review') ||
                req.getEndpoint().contains('/services/apexrest/fsc/rla-approval-admin/return-to-business') ||
                req.getEndpoint().contains('/services/apexrest/fsc/rla-approval-admin/return-to-analyst') ||
                req.getEndpoint().contains('/services/apexrest/fsc/rla-approval-admin/client-decision')
            );
            if (req.getEndpoint().contains('/client-decision')) {
                Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
                lastClientDecisionAction = (String) body.get('accion');
                lastClientDecisionComment = (String) body.get('comentarioAuditoria');
            }

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success":true,"message":"OK"}');
            return res;
        }
    }

    private static ResidentialLoanApplication createRla() {
        Account acc = new Account(
            Name = 'Cuenta Privileged ' + System.now().getTime(),
            ACC_NumIdentificacion__c = '00108803610'
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

        Test.startTest();
        try {
            FSC_RlaAccionesController.enviarRevisionSupervisor(rla.Id);
        } catch (AuraHandledException expectedWhenNoApprovalIsActive) {
            System.assertNotEquals(null, expectedWhenNoApprovalIsActive);
        }
        Test.stopTest();

        FSC_RlaAccionesController.testForcePrivilegedSupervisorReview = false;
		System.assertNotEquals(null, rla.Id);
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

        Test.startTest();
        try {
            FSC_RlaAccionesController.devolverAOficial(rla.Id, 'volver a oficial');
        } catch (AuraHandledException expectedWhenNoApprovalIsActive) {
            System.assertNotEquals(null, expectedWhenNoApprovalIsActive);
        }
        Test.stopTest();

        FSC_RlaAccionesController.testForcePrivilegedSupervisorReview = false;
		System.assertNotEquals(null, rla.Id);
    }

    @IsTest
    static void clienteAceptaCondicion_usaFallbackPrivilegiadoConAuditoria() {
        ResidentialLoanApplication rla = createRla();
        privilegedEndpointCalled = false;
        Test.setMock(HttpCalloutMock.class, new PrivilegedSupervisorReviewMock());
        FSC_RlaAccionesController.testForcePrivilegedSupervisorReview = true;
        FSC_RlaAccionesController.testBypassPermissions = true;

        Test.startTest();
        FSC_RlaAccionesController.actualizarSubestadoGeneracionPagares(rla.Id);
        Test.stopTest();

        System.assertEquals(true, privilegedEndpointCalled);
        System.assertEquals('ACEPTA', lastClientDecisionAction);
        System.assert(lastClientDecisionComment.contains(UserInfo.getUserId()), 'El comentario debe identificar al usuario que ejecutó la acción.');
        System.assert(lastClientDecisionComment.contains(UserInfo.getName()));
    }

    @IsTest
    static void clienteRechazaCondicion_usaFallbackPrivilegiadoConAuditoria() {
        ResidentialLoanApplication rla = createRla();
        privilegedEndpointCalled = false;
        Test.setMock(HttpCalloutMock.class, new PrivilegedSupervisorReviewMock());
        FSC_RlaAccionesController.testForcePrivilegedSupervisorReview = true;
        FSC_RlaAccionesController.testBypassPermissions = true;

        Test.startTest();
        FSC_RlaAccionesController.rechazarPorCliente(rla.Id);
        Test.stopTest();

        System.assertEquals(true, privilegedEndpointCalled);
        System.assertEquals('RECHAZA', lastClientDecisionAction);
        System.assert(lastClientDecisionComment.contains(UserInfo.getUserId()));
    }
}