/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_ABanksGetTokenTest
 * Versión                :   1.0
 * Fecha de modificación  :   21/07/2025
 * Función                :   Clase de pruebas unitarias e integración para VFS_ABanksGetToken
 * Clase que cubre        :   VFS_ABanksGetToken
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        07/07/2025      Versión original
 *********************************************************************************************/
@isTest
private class VFS_ABanksGetTokenTest {
    // Mock para callout exitoso
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"accessToken":"abc123","refreshToken":"def456","accessTokenTime":3600,"refreshTokenTime":7200,"status":1,"changed":true}');
            return res;
        }
    }

    // Mock para callout con error
    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('');
            return res;
        }
    }

    @isTest static void testGetTokenSuccess() {

        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
            INTLogger.INTLoggerCalloutData result = VFS_ABanksGetToken.getToken();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Debe retornar un objeto INTLoggerCalloutData');
        // Validar que el body de la respuesta mockeada esté presente
        Map<String, Object> res = (Map<String, Object>)result.res;
        System.assertEquals(200, res.get('Http_Status_Code__c'), 'Debe ser status 200');
        System.assert(res.get('Trama_de_respuesta__c') != null && ((String)res.get('Trama_de_respuesta__c')).contains('abc123'), 'El body debe contener el token de prueba');
    }

    @isTest static void testGetTokenHttpError() {

        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        Test.startTest();
            INTLogger.INTLoggerCalloutData result = VFS_ABanksGetToken.getToken();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Debe retornar un objeto INTLoggerCalloutData');
        Map<String, Object> res = (Map<String, Object>)result.res;
        System.assertEquals(500, res.get('Http_Status_Code__c'), 'Debe ser status 500');
        System.assertEquals('', res.get('Trama_de_respuesta__c'), 'El body debe estar vacío');
    }
}