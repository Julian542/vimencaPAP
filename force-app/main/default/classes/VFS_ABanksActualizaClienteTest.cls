/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_ABanksActualizaClienteTest
 * Versión                :   1.0
 * Fecha de creación      :   21/07/2025
 * Función                :   Clase de pruebas unitarias e integración para VFS_ABanksActualizaCliente
 * Clase que cubre        :   VFS_ABanksActualizaCliente
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        21/07/2025      Estandarización y ampliación de pruebas
 *********************************************************************************************/

@isTest
private class VFS_ABanksActualizaClienteTest {
    // Mock para callout exitoso
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":{"identificationNumber":"123456","firmaUnica":"FIRMA123","date":"2025-07-07"},"status":"OK","error":null}');
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

    @isTest
    static void testActualizaClienteParametroRequerido() {
        // identificacion vacío
        Test.startTest();
            VFS_ABanksActualizaCliente.Response resp1 = VFS_ABanksActualizaCliente.actualizaCliente('', 'FIRMA123');
            // firmaUnica vacío
            VFS_ABanksActualizaCliente.Response resp2 = VFS_ABanksActualizaCliente.actualizaCliente('123456', '');
        Test.stopTest();

        System.assertNotEquals(null, resp1, 'Debe retornar un objeto Response');
        System.assertEquals('El campo identificacion es obligatorio.', resp1.message, 'Debe indicar que el campo identificacion es obligatorio');
        System.assertEquals('ERROR', resp1.status, 'El status debe ser ERROR');
        System.assertNotEquals(null, resp2, 'Debe retornar un objeto Response');
        System.assertEquals('El campo firmaUnica es obligatorio.', resp2.message, 'Debe indicar que el campo firmaUnica es obligatorio');
        System.assertEquals('ERROR', resp2.status, 'El status debe ser ERROR');
    }

    @isTest
    static void testActualizaClienteHttpError() {

        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        Test.startTest();
            VFS_ABanksActualizaCliente.Response resp = VFS_ABanksActualizaCliente.actualizaCliente('123456', 'FIRMA123');
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Debe retornar un objeto Response');
        System.assertEquals('ERROR', resp.status, 'El status debe ser ERROR si el callout falla');
        System.assert(resp.message != null && resp.message.contains('No se pudo obtener token') || resp.message.contains('No se encontró endpoint') || resp.message.contains('Error en callout'), 'Debe indicar error en callout o token/endpoint');
    }

    @isTest
    static void testActualizaClienteExitoso() {

        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        // Mock de token y endpoint
        Test.startTest();
            VFS_ABanksActualizaCliente.testToken = 'token123';
            VFS_ABanksActualizaCliente.testEndpoint = 'https://dummy.endpoint';
            VFS_ABanksActualizaCliente.Response resp = VFS_ABanksActualizaCliente.actualizaCliente('123456', 'FIRMA123');
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Debe retornar un objeto Response');
        System.assertEquals('OK', resp.status, 'El status debe ser OK');
        System.assertNotEquals(null, resp.data, 'Debe retornar data');
        System.assertEquals('123456', resp.data.identificationNumber, 'Debe mapear identificationNumber');
        System.assertEquals('FIRMA123', resp.data.firmaUnica, 'Debe mapear firmaUnica');
        System.assertEquals('2025-07-07', resp.data.fecha, 'Debe mapear fecha desde date');
        System.assert(resp.debugInfo != null && resp.debugInfo.contains('StatusCode'), 'Debe contener debugInfo con StatusCode');
    }

    @isTest
    static void testActualizaClienteFlow() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        // Mock de token y endpoint
        VFS_ABanksActualizaCliente.testToken = 'token123';
        VFS_ABanksActualizaCliente.testEndpoint = 'https://dummy.endpoint';
        VFS_ABanksActualizaCliente.ActualizaClienteRequest req = new VFS_ABanksActualizaCliente.ActualizaClienteRequest();
        req.identificacion = '123456';
        req.firmaUnica = 'FIRMA123';

        Test.startTest();
            List<VFS_ABanksActualizaCliente.ActualizaClienteResponse> responses = VFS_ABanksActualizaCliente.flowActualizaCliente(new List<VFS_ABanksActualizaCliente.ActualizaClienteRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Debe retornar una respuesta');
        VFS_ABanksActualizaCliente.ActualizaClienteResponse resp = responses[0];
        System.assertEquals('OK', resp.status, 'El status debe ser OK');
        System.assertEquals('123456', resp.identificacion, 'Debe mapear identificacion');
        System.assertEquals('FIRMA123', resp.firmaUnica, 'Debe mapear firmaUnica');
        System.assertEquals('2025-07-07', resp.fecha, 'Debe mapear fecha');
    }
}