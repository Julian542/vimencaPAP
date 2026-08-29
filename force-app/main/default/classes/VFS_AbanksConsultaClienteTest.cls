/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_AbanksConsultaClienteTest
 * Versión                :   1.0
 * Fecha de creación      :   07/07/2025
 * Función                :   Clase de pruebas unitarias e integración para VFS_AbanksConsultaCliente
 * Clase que cubre        :   VFS_AbanksConsultaCliente
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        07/07/2025      Versión original
 *********************************************************************************************/

@isTest
private class VFS_AbanksConsultaClienteTest {
    // Mock para callout exitoso
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"OK","data":{"identificationNumber":"123456789","firmaUnica":"FIRMA123","date":"2025-07-07"}}');
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
    static void testConsultaClienteParametroRequerido() {
        VFS_AbanksConsultaCliente.ConsultaClienteRequest req = new VFS_AbanksConsultaCliente.ConsultaClienteRequest();
        req.identificacion = '';

        Test.startTest();
            VFS_AbanksConsultaCliente.ConsultaClienteResponse resp = VFS_AbanksConsultaCliente.flowConsultaCliente(
                new List<VFS_AbanksConsultaCliente.ConsultaClienteRequest>{ req }
            )[0];
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Debe retornar un objeto ConsultaClienteResponse');
        System.assertEquals(false, resp.success, 'Debe fallar si identificacion es vacía');
        System.assert(resp.message.contains('obligatorio'), 'Debe indicar que el campo es obligatorio');
    }

    @isTest
    static void testConsultaClienteHttpError() {
        VFS_AbanksConsultaCliente.ConsultaClienteRequest req = new VFS_AbanksConsultaCliente.ConsultaClienteRequest();
        req.identificacion = '123456789';

        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        Test.startTest();
            VFS_AbanksConsultaCliente.ConsultaClienteResponse resp = VFS_AbanksConsultaCliente.flowConsultaCliente(
                new List<VFS_AbanksConsultaCliente.ConsultaClienteRequest>{ req }
            )[0];
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Debe retornar un objeto ConsultaClienteResponse');
        System.assertEquals(false, resp.success, 'Debe fallar si el callout da error');
        System.assert(resp.message != null && resp.message.contains('Error en callout'), 'Debe indicar error en callout');
    }

    @isTest static void testConsultaClienteExitoso() {
        VFS_AbanksConsultaCliente.ConsultaClienteRequest req = new VFS_AbanksConsultaCliente.ConsultaClienteRequest();
        req.identificacion = '123456789';

        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
            VFS_AbanksConsultaCliente.ConsultaClienteResponse resp = VFS_AbanksConsultaCliente.flowConsultaCliente(
                new List<VFS_AbanksConsultaCliente.ConsultaClienteRequest>{ req }
            )[0];
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Debe retornar un objeto ConsultaClienteResponse');
        System.assertEquals(true, resp.success, 'Debe ser exitoso si el callout responde OK');
        System.assertEquals('OK', resp.status, 'El status debe ser OK');
        System.assertNotEquals(null, resp.firmaUnica, 'Debe retornar firmaUnica');
        System.assertEquals('FIRMA123', resp.firmaUnica, 'Debe mapear firmaUnica');
        System.assertEquals('2025-07-07', resp.fecha, 'Debe mapear fecha desde date');
        System.assert(resp.debugInfo.contains('StatusCode: 200'), 'Debe contener el status code en debugInfo');
    }
}