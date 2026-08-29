@IsTest
private class AGENTE_ConsultarTarjetasMockTest {
    
    @IsTest
    static void testRespondPersonaFisica() {
        // 1. Preparamos el simulador y una petición falsa de Persona Física (PF)
        AGENTE_ConsultarTarjetasMock mock = new AGENTE_ConsultarTarjetasMock();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('http://dummy-endpoint.com');
        req.setMethod('POST');
        req.setBody('<FunctionName>ConsultaProdFinPF</FunctionName>'); // No contiene PJ
        
        // 2. Ejecutamos el método respond del Mock directamente
        Test.startTest();
        HttpResponse res = mock.respond(req);
        Test.stopTest();
        
        // 3. Verificamos que devuelva el código 200 y el Namespace de PF
        System.assertEquals(200, res.getStatusCode(), 'El código de estado debe ser 200');
        System.assertEquals('text/xml;charset=UTF-8', res.getHeader('Content-Type'), 'El Content-Type no es el esperado');
        System.assert(res.getBody().contains('http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20VBC%20Response%20IO'), 'Debería usar el Namespace de Persona Física (PF)');
    }

    @IsTest
    static void testRespondPersonaJuridica() {
        // 1. Preparamos el simulador y una petición falsa de Persona Jurídica (PJ)
        AGENTE_ConsultarTarjetasMock mock = new AGENTE_ConsultarTarjetasMock();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('http://dummy-endpoint.com');
        req.setMethod('POST');
        req.setBody('<FunctionName>ConsultaProdFinPJ</FunctionName>'); // Contiene PJ
        
        // 2. Ejecutamos el método respond del Mock directamente
        Test.startTest();
        HttpResponse res = mock.respond(req);
        Test.stopTest();
        
        // 3. Verificamos que devuelva el código 200 y el Namespace de PJ
        System.assertEquals(200, res.getStatusCode(), 'El código de estado debe ser 200');
        System.assert(res.getBody().contains('http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PJ%20Response%20IO'), 'Debería usar el Namespace de Persona Jurídica (PJ)');
    }
}