@IsTest
private class RestWebServiceCoverageTest {
    private class ErrorResponseMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(500);
            response.setStatus('Internal Server Error');
            response.setBody('{"error":"coverage"}');
            return response;
        }
    }

    private static void configureBaseService() {
        REST_WebService.metodoPrestamoConsumo = 'consumo';
        REST_WebService.metodoPrestamoVehiculo = 'vehiculo';
        REST_WebService.metodoConsultaMonto = 'monto';
        REST_WebService.metodoCrearSolicitud = 'crear';
        REST_WebService.metodoSincronizarSolicitud = 'sincronizar';
        REST_WebService.namedCredential = 'REST_Coverage';
        REST_WebService.username = 'coverage';
        REST_WebService.password = 'coverage';
        REST_WebService.accessToken = 'coverage';
    }

    private static void configureFscService() {
        REST_WebService_FSC.metodoPrestamoConsumo = 'consumo';
        REST_WebService_FSC.metodoPrestamoVehiculo = 'vehiculo';
        REST_WebService_FSC.metodoConsultaMonto = 'monto';
        REST_WebService_FSC.metodoCrearSolicitud = 'crear';
        REST_WebService_FSC.metodoSincronizarSolicitud = 'sincronizar';
        REST_WebService_FSC.namedCredential = 'REST_Coverage';
        REST_WebService_FSC.username = 'coverage';
        REST_WebService_FSC.password = 'coverage';
        REST_WebService_FSC.accessToken = 'coverage';
    }

    @IsTest
    static void reportsMissingSandboxConfigurationBeforeCallingTheService() {
        Test.setMock(HttpCalloutMock.class, new ErrorResponseMock());

        Boolean baseConfigurationMissing = false;
        Boolean fscConfigurationMissing = false;
        Test.startTest();
        try {
            new REST_WebService();
        } catch (QueryException expectedException) {
            baseConfigurationMissing = expectedException.getMessage().contains('List has no rows');
        }
        try {
            new REST_WebService_FSC();
        } catch (QueryException expectedException) {
            fscConfigurationMissing = expectedException.getMessage().contains('List has no rows');
        }
        Test.stopTest();

        System.assert(baseConfigurationMissing);
        System.assert(fscConfigurationMissing);
    }
}
