@IsTest
private class AGENTE_ConsultarProductosClienteTest {

    private class ProductosHttpMock implements HttpCalloutMock {
        private final String mode;

        ProductosHttpMock(String mode) {
            this.mode = mode;
        }

        public HttpResponse respond(HttpRequest req) {
            if (mode == 'CALLOUT_EXCEPTION') {
                throw new CalloutException('Read timed out');
            }

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml;charset=UTF-8');

            if (mode == 'SUCCESS_PF') {
                res.setStatusCode(200);
                res.setBody(buildSuccessPfResponse());
            } else if (mode == 'SUCCESS_PJ') {
                res.setStatusCode(200);
                res.setBody(buildSuccessPjResponse());
            } else if (mode == 'NO_PRODUCTS') {
                res.setStatusCode(200);
                res.setBody(buildNoEligibleProductsResponse());
            } else if (mode == 'CORE_ERROR') {
                res.setStatusCode(200);
                res.setBody(buildCoreErrorResponse());
            } else if (mode == 'HTTP_ERROR') {
                res.setStatusCode(500);
                res.setStatus('Internal Server Error');
                res.setBody('Error interno');
            } else if (mode == 'INVALID_BODY') {
                res.setStatusCode(200);
                res.setBody('<html>respuesta invalida</html>');
            } else {
                res.setStatusCode(200);
                res.setBody(buildSuccessPfResponse());
            }

            return res;
        }
    }

    @IsTest
    static void testConsultarProductosFlow_NullInputs() {
        Test.startTest();
        List<AGENTE_ConsultarProductosCliente.InvocableOutput> result =
            AGENTE_ConsultarProductosCliente.consultarProductosFlow(null);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('ERROR', result[0].status);
        System.assertEquals(0, result[0].totalProducts);
        System.assertEquals('[]', result[0].productsJson);
        System.assertEquals('No fue posible procesar la solicitud.', result[0].displayText);
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarProductosFlow_EmptyInputs() {
        Test.startTest();
        List<AGENTE_ConsultarProductosCliente.InvocableOutput> result =
            AGENTE_ConsultarProductosCliente.consultarProductosFlow(
                new List<AGENTE_ConsultarProductosCliente.InvocableInput>()
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('ERROR', result[0].status);
        System.assertEquals(0, result[0].totalProducts);
        System.assertEquals('[]', result[0].productsJson);
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarProductosFlow_SuccessPF() {
        Test.setMock(HttpCalloutMock.class, new ProductosHttpMock('SUCCESS_PF'));

        AGENTE_ConsultarProductosCliente.InvocableInput input = buildBasePfInput();

        Test.startTest();
        List<AGENTE_ConsultarProductosCliente.InvocableOutput> result =
            AGENTE_ConsultarProductosCliente.consultarProductosFlow(
                new List<AGENTE_ConsultarProductosCliente.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        AGENTE_ConsultarProductosCliente.InvocableOutput out = result[0];

        System.assertEquals('OK', out.status);
        System.assertEquals(4, out.totalProducts);
        System.assert(out.displayText.contains('Encontré estos productos asociados a tu perfil'));
        System.assert(out.displayText.contains('1. Tarjeta ****1462 - VIGENTE'));
        System.assert(out.displayText.contains('2. Prepago ****0010 - VIGENTE'));
        System.assert(out.displayText.contains('3. Cuenta ****3476 - ACTIVA'));

        List<AGENTE_ConsultarProductosCliente.ProductOption> products =
            (List<AGENTE_ConsultarProductosCliente.ProductOption>)
                JSON.deserialize(out.productsJson, List<AGENTE_ConsultarProductosCliente.ProductOption>.class);

        System.assertEquals(4, products.size());

        System.assertEquals('4593820000051462', products[0].integrationProductNumber);
        System.assertEquals('Tarjetas de crédito', products[0].integrationProductType);
        System.assertEquals('DOP', products[0].currencyCode);
        System.assertEquals('Tarjeta', products[0].productType);
        System.assertEquals(true, products[0].eligibleForTransactions);
        System.assertNotEquals(null, products[0].productKey);

        System.assertEquals('Tarjetas prepago', products[1].integrationProductType);
        System.assertEquals('Prepago', products[1].productType);
        System.assertEquals('DOP', products[1].currencyCode);

        System.assertEquals('Cuentas de ahorro', products[2].integrationProductType);
        System.assertEquals('Cuenta', products[2].productType);
        System.assertEquals('DOP', products[2].currencyCode);

        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarProductosFlow_SuccessPJ() {
        Test.setMock(HttpCalloutMock.class, new ProductosHttpMock('SUCCESS_PJ'));

        AGENTE_ConsultarProductosCliente.InvocableInput input = buildBasePjInput();

        Test.startTest();
        List<AGENTE_ConsultarProductosCliente.InvocableOutput> result =
            AGENTE_ConsultarProductosCliente.consultarProductosFlow(
                new List<AGENTE_ConsultarProductosCliente.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('OK', result[0].status);
        System.assertEquals(1, result[0].totalProducts);

        List<AGENTE_ConsultarProductosCliente.ProductOption> products =
            (List<AGENTE_ConsultarProductosCliente.ProductOption>)
                JSON.deserialize(result[0].productsJson, List<AGENTE_ConsultarProductosCliente.ProductOption>.class);

        System.assertEquals(1, products.size());
        System.assertEquals('Cuenta', products[0].productType);
        System.assertEquals('USD', products[0].currencyCode);
        System.assertEquals('2401322114', products[0].integrationProductNumber);

        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarProductosFlow_NoProducts_NoCreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new ProductosHttpMock('NO_PRODUCTS'));

        AGENTE_ConsultarProductosCliente.InvocableInput input = buildBasePfInput();

        Test.startTest();
        List<AGENTE_ConsultarProductosCliente.InvocableOutput> result =
            AGENTE_ConsultarProductosCliente.consultarProductosFlow(
                new List<AGENTE_ConsultarProductosCliente.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('OK', result[0].status);
        System.assertEquals(1, result[0].totalProducts);
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarProductosFlow_CoreError_CreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new ProductosHttpMock('CORE_ERROR'));

        AGENTE_ConsultarProductosCliente.InvocableInput input = buildBasePfInput();

        Test.startTest();
        List<AGENTE_ConsultarProductosCliente.InvocableOutput> result =
            AGENTE_ConsultarProductosCliente.consultarProductosFlow(
                new List<AGENTE_ConsultarProductosCliente.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('ERROR', result[0].status);
        System.assertEquals(0, result[0].totalProducts);

        List<AgentLog__c> logs = [
            SELECT Id,
                   Status__c,
                   SourceClass__c,
                   IntegrationName__c,
                   Operation__c,
                   HttpStatusCode__c,
                   HttpMethod__c,
                   ExternalErrorCode__c,
                   ErrorMessage__c,
                   RequestPayload__c,
                   ResponsePayload__c
            FROM AgentLog__c
            WHERE SourceClass__c = 'AGENTE_ConsultarProductosCliente'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(1, logs.size());
        System.assertEquals('Error', logs[0].Status__c);
        System.assertEquals('Core Bancario', logs[0].IntegrationName__c);
        System.assertEquals('ConsultaProdFinPF', logs[0].Operation__c);
        System.assertEquals(200, logs[0].HttpStatusCode__c);
        System.assertEquals('POST', logs[0].HttpMethod__c);
        System.assertEquals('999', logs[0].ExternalErrorCode__c);
        System.assert(logs[0].ErrorMessage__c.contains('ERROR CONTROLADO'));
        System.assert(logs[0].RequestPayload__c.contains('***MASKED***'));
    }

    @IsTest
    static void testConsultarProductosFlow_HttpError_CreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new ProductosHttpMock('HTTP_ERROR'));

        AGENTE_ConsultarProductosCliente.InvocableInput input = buildBasePfInput();

        Test.startTest();
        List<AGENTE_ConsultarProductosCliente.InvocableOutput> result =
            AGENTE_ConsultarProductosCliente.consultarProductosFlow(
                new List<AGENTE_ConsultarProductosCliente.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('ERROR', result[0].status);
        System.assertEquals(0, result[0].totalProducts);
        System.assert(result[0].message.contains('Código HTTP: 500'));

        List<AgentLog__c> logs = [
            SELECT Id,
                   Status__c,
                   SourceClass__c,
                   IntegrationName__c,
                   Operation__c,
                   HttpStatusCode__c,
                   HttpMethod__c,
                   ExternalErrorCode__c,
                   ErrorMessage__c,
                   ResponsePayload__c
            FROM AgentLog__c
            WHERE SourceClass__c = 'AGENTE_ConsultarProductosCliente'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(1, logs.size());
        System.assertEquals('Error', logs[0].Status__c);
        System.assertEquals('Core Bancario', logs[0].IntegrationName__c);
        System.assertEquals('ConsultaProdFinPF', logs[0].Operation__c);
        System.assertEquals(500, logs[0].HttpStatusCode__c);
        System.assertEquals('POST', logs[0].HttpMethod__c);
        System.assertEquals('HTTP_500', logs[0].ExternalErrorCode__c);
        System.assert(logs[0].ErrorMessage__c.contains('Código HTTP: 500'));
    }

    @IsTest
    static void testConsultarProductosFlow_InvalidBody_CreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new ProductosHttpMock('INVALID_BODY'));

        AGENTE_ConsultarProductosCliente.InvocableInput input = buildBasePfInput();

        Test.startTest();
        List<AGENTE_ConsultarProductosCliente.InvocableOutput> result =
            AGENTE_ConsultarProductosCliente.consultarProductosFlow(
                new List<AGENTE_ConsultarProductosCliente.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('ERROR', result[0].status);

        List<AgentLog__c> logs = [
            SELECT Id,
                   Status__c,
                   SourceClass__c,
                   IntegrationName__c,
                   Operation__c,
                   HttpStatusCode__c,
                   ExternalErrorCode__c,
                   ErrorMessage__c
            FROM AgentLog__c
            WHERE SourceClass__c = 'AGENTE_ConsultarProductosCliente'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(1, logs.size());
        System.assertEquals('Error', logs[0].Status__c);
        System.assertEquals('ConsultaProdFinPF', logs[0].Operation__c);
        System.assertEquals(200, logs[0].HttpStatusCode__c);
        System.assertEquals('INVALID_RESPONSE', logs[0].ExternalErrorCode__c);
        System.assert(logs[0].ErrorMessage__c.contains('La respuesta SOAP no contiene Body'));
    }

    @IsTest
    static void testConsultarProductosFlow_CalloutException_CreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new ProductosHttpMock('CALLOUT_EXCEPTION'));

        AGENTE_ConsultarProductosCliente.InvocableInput input = buildBasePfInput();

        Test.startTest();
        List<AGENTE_ConsultarProductosCliente.InvocableOutput> result =
            AGENTE_ConsultarProductosCliente.consultarProductosFlow(
                new List<AGENTE_ConsultarProductosCliente.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('ERROR', result[0].status);

        List<AgentLog__c> logs = [
            SELECT Id,
                   Status__c,
                   SourceClass__c,
                   IntegrationName__c,
                   Operation__c,
                   HttpStatusCode__c,
                   ExternalErrorCode__c,
                   ErrorMessage__c
            FROM AgentLog__c
            WHERE SourceClass__c = 'AGENTE_ConsultarProductosCliente'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(1, logs.size());
        System.assertEquals('Error', logs[0].Status__c);
        System.assertEquals('ConsultaProdFinPF', logs[0].Operation__c);
        System.assertEquals(null, logs[0].HttpStatusCode__c);
        System.assertEquals('CALLOUT_EXCEPTION', logs[0].ExternalErrorCode__c);
        System.assert(logs[0].ErrorMessage__c.contains('Read timed out'));
    }

    @IsTest
    static void testConsultarProductos_ValidationErrors_NoCreaAgentLog() {
        AGENTE_ConsultarProductosCliente.InternalRequest req1 =
            new AGENTE_ConsultarProductosCliente.InternalRequest();

        AGENTE_ConsultarProductosCliente.InternalRequest req2 =
            new AGENTE_ConsultarProductosCliente.InternalRequest();
        req2.customerType = 'XX';
        req2.identificationNumber = '123';
        req2.identificationType = 'Cedula';
        req2.cif = '999';

        AGENTE_ConsultarProductosCliente.InternalRequest req3 =
            new AGENTE_ConsultarProductosCliente.InternalRequest();
        req3.customerType = 'PF';
        req3.identificationNumber = '123';
        req3.identificationType = '';
        req3.cif = '999';

        AGENTE_ConsultarProductosCliente.InternalRequest req4 =
            new AGENTE_ConsultarProductosCliente.InternalRequest();
        req4.customerType = 'PF';
        req4.identificationNumber = '';
        req4.identificationType = 'Cedula';
        req4.cif = '999';

        AGENTE_ConsultarProductosCliente.InternalRequest req5 =
            new AGENTE_ConsultarProductosCliente.InternalRequest();
        req5.customerType = 'PF';
        req5.identificationNumber = '123';
        req5.identificationType = 'Cedula';
        req5.cif = '';

        Test.startTest();

        AGENTE_ConsultarProductosCliente.ProductPortfolioResponse res1 =
            AGENTE_ConsultarProductosCliente.consultarProductos(req1);

        AGENTE_ConsultarProductosCliente.ProductPortfolioResponse res2 =
            AGENTE_ConsultarProductosCliente.consultarProductos(req2);

        AGENTE_ConsultarProductosCliente.ProductPortfolioResponse res3 =
            AGENTE_ConsultarProductosCliente.consultarProductos(req3);

        AGENTE_ConsultarProductosCliente.ProductPortfolioResponse res4 =
            AGENTE_ConsultarProductosCliente.consultarProductos(req4);

        AGENTE_ConsultarProductosCliente.ProductPortfolioResponse res5 =
            AGENTE_ConsultarProductosCliente.consultarProductos(req5);

        Test.stopTest();

        System.assertEquals('ERROR', res1.status);
        System.assertEquals('ERROR', res2.status);
        System.assertEquals('ERROR', res3.status);
        System.assertEquals('ERROR', res4.status);
        System.assertEquals('ERROR', res5.status);
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarProductos_PJDoesNotRequireIdentificationType() {
        Test.setMock(HttpCalloutMock.class, new ProductosHttpMock('SUCCESS_PJ'));

        AGENTE_ConsultarProductosCliente.InternalRequest req =
            new AGENTE_ConsultarProductosCliente.InternalRequest();
        req.customerType = 'PJ';
        req.identificationNumber = '101010101';
        req.identificationType = '';
        req.cif = '5555';

        Test.startTest();
        AGENTE_ConsultarProductosCliente.ProductPortfolioResponse res =
            AGENTE_ConsultarProductosCliente.consultarProductos(req);
        Test.stopTest();

        System.assertEquals('OK', res.status);
        System.assertEquals(1, res.totalProducts);
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarProductos_PFNormalizesCedula() {
        Test.setMock(HttpCalloutMock.class, new ProductosHttpMock('SUCCESS_PF'));

        AGENTE_ConsultarProductosCliente.InternalRequest req =
            new AGENTE_ConsultarProductosCliente.InternalRequest();
        req.customerType = 'PF';
        req.identificationNumber = '00108803610';
        req.identificationType = 'Cédula';
        req.cif = '1022328';

        Test.startTest();
        AGENTE_ConsultarProductosCliente.ProductPortfolioResponse res =
            AGENTE_ConsultarProductosCliente.consultarProductos(req);
        Test.stopTest();

        System.assertEquals('OK', res.status);
        System.assertEquals(4, res.totalProducts);
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    private static AGENTE_ConsultarProductosCliente.InvocableInput buildBasePfInput() {
        AGENTE_ConsultarProductosCliente.InvocableInput input =
            new AGENTE_ConsultarProductosCliente.InvocableInput();
        input.customerType = 'PF';
        input.identificationNumber = '00108803610';
        input.identificationType = 'Cédula';
        input.cif = '1022328';
        return input;
    }

    private static AGENTE_ConsultarProductosCliente.InvocableInput buildBasePjInput() {
        AGENTE_ConsultarProductosCliente.InvocableInput input =
            new AGENTE_ConsultarProductosCliente.InvocableInput();
        input.customerType = 'PJ';
        input.identificationNumber = '101010101';
        input.identificationType = '';
        input.cif = '5555';
        return input;
    }

    private static String buildSuccessPfResponse() {
        return ''
            + '<?xml version="1.0" encoding="utf-8"?>'
            + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
            + '  <soap:Body>'
            + '    <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20VBC%20Response%20IO">'
            + '      <Result>'
            + '        <ErrorCode>000</ErrorCode>'
            + '        <ErrorText>TRANSACCION PROCESADA</ErrorText>'
            + '        <Producto>'
            + '          <NumCuenta>4593820000051462</NumCuenta>'
            + '          <Producto>TC</Producto>'
            + '          <CodigoProducto>TC</CodigoProducto>'
            + '          <Estado>VIGENTE</Estado>'
            + '          <LineaProducto>Tarjetas de crédito</LineaProducto>'
            + '          <SaldoRD>100.00</SaldoRD>'
            + '          <SaldoUS>0.00</SaldoUS>'
            + '          <TipoVinculacion>Principal</TipoVinculacion>'
            + '          <Titulares>Cliente Test</Titulares>'
            + '        </Producto>'
            + '        <Producto>'
            + '          <NumCuenta>15503700000000000010</NumCuenta>'
            + '          <Producto>PP</Producto>'
            + '          <CodigoProducto>PP</CodigoProducto>'
            + '          <Estado>VIGENTE</Estado>'
            + '          <LineaProducto>Tarjetas prepago</LineaProducto>'
            + '          <SaldoRD>50.00</SaldoRD>'
            + '          <SaldoUS>0.00</SaldoUS>'
            + '          <TipoVinculacion>Principal</TipoVinculacion>'
            + '          <Titulares>Cliente Test</Titulares>'
            + '        </Producto>'
            + '        <Producto>'
            + '          <NumCuenta>102083476</NumCuenta>'
            + '          <Producto>CA</Producto>'
            + '          <CodigoProducto>CA</CodigoProducto>'
            + '          <Estado>ACTIVA</Estado>'
            + '          <LineaProducto>Cuentas de ahorro</LineaProducto>'
            + '          <SaldoRD>10.00</SaldoRD>'
            + '          <SaldoUS>0.00</SaldoUS>'
            + '          <TipoVinculacion>Principal</TipoVinculacion>'
            + '          <Titulares>Cliente Test</Titulares>'
            + '        </Producto>'
            + '        <Producto>'
            + '          <NumCuenta>PREST123</NumCuenta>'
            + '          <Producto>PR</Producto>'
            + '          <CodigoProducto>PR</CodigoProducto>'
            + '          <Estado>ACTIVA</Estado>'
            + '          <LineaProducto>Préstamos</LineaProducto>'
            + '          <SaldoRD>999.00</SaldoRD>'
            + '          <SaldoUS>0.00</SaldoUS>'
            + '          <TipoVinculacion>Principal</TipoVinculacion>'
            + '          <Titulares>Cliente Test</Titulares>'
            + '        </Producto>'
            + '        <Producto>'
            + '          <NumCuenta>00001234</NumCuenta>'
            + '          <Producto>CC</Producto>'
            + '          <CodigoProducto>CC</CodigoProducto>'
            + '          <Estado>CANCELADA</Estado>'
            + '          <LineaProducto>Cuentas corrientes</LineaProducto>'
            + '          <SaldoRD>0.00</SaldoRD>'
            + '          <SaldoUS>0.00</SaldoUS>'
            + '          <TipoVinculacion>Principal</TipoVinculacion>'
            + '          <Titulares>Cliente Test</Titulares>'
            + '        </Producto>'
            + '      </Result>'
            + '    </ListOfBREAIFuncionGeneral>'
            + '  </soap:Body>'
            + '</soap:Envelope>';
    }

    private static String buildSuccessPjResponse() {
        return ''
            + '<?xml version="1.0" encoding="utf-8"?>'
            + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
            + '  <soap:Body>'
            + '    <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PJ%20Response%20IO">'
            + '      <Result>'
            + '        <ErrorCode>000</ErrorCode>'
            + '        <ErrorText>TRANSACCION PROCESADA</ErrorText>'
            + '        <Producto>'
            + '          <NumCuenta>2401322114</NumCuenta>'
            + '          <Producto>219</Producto>'
            + '          <CodigoProducto>219</CodigoProducto>'
            + '          <Estado>ACTIVA</Estado>'
            + '          <LineaProducto>Cuentas corrientes</LineaProducto>'
            + '          <SaldoRD>0.00</SaldoRD>'
            + '          <SaldoUS>25.00</SaldoUS>'
            + '          <TipoVinculacion>Principal</TipoVinculacion>'
            + '          <Titulares>Empresa Test</Titulares>'
            + '        </Producto>'
            + '      </Result>'
            + '    </ListOfBREAIFuncionGeneral>'
            + '  </soap:Body>'
            + '</soap:Envelope>';
    }

    private static String buildNoEligibleProductsResponse() {
        return ''
            + '<?xml version="1.0" encoding="utf-8"?>'
            + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
            + '  <soap:Body>'
            + '    <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20VBC%20Response%20IO">'
            + '      <Result>'
            + '        <ErrorCode>000</ErrorCode>'
            + '        <ErrorText>TRANSACCION PROCESADA</ErrorText>'
            + '        <Producto>'
            + '          <NumCuenta>PREST123</NumCuenta>'
            + '          <Producto>PR</Producto>'
            + '          <CodigoProducto>PR</CodigoProducto>'
            + '          <Estado>ACTIVA</Estado>'
            + '          <LineaProducto>Préstamos</LineaProducto>'
            + '          <SaldoRD>999.00</SaldoRD>'
            + '          <SaldoUS>0.00</SaldoUS>'
            + '          <TipoVinculacion>Principal</TipoVinculacion>'
            + '          <Titulares>Cliente Test</Titulares>'
            + '        </Producto>'
            + '      </Result>'
            + '    </ListOfBREAIFuncionGeneral>'
            + '  </soap:Body>'
            + '</soap:Envelope>';
    }

    private static String buildCoreErrorResponse() {
        return ''
            + '<?xml version="1.0" encoding="utf-8"?>'
            + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
            + '  <soap:Body>'
            + '    <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20VBC%20Response%20IO">'
            + '      <Result>'
            + '        <ErrorCode>999</ErrorCode>'
            + '        <ErrorText>ERROR CONTROLADO</ErrorText>'
            + '      </Result>'
            + '    </ListOfBREAIFuncionGeneral>'
            + '  </soap:Body>'
            + '</soap:Envelope>';
    }
}