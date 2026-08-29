@IsTest
private class AGENTE_ConsultarTarjetasParaBloqueoTest {

    private class TarjetasBloqueoHttpMock implements HttpCalloutMock {
        private final String mode;

        TarjetasBloqueoHttpMock(String mode) {
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
            } else if (mode == 'NO_CARDS') {
                res.setStatusCode(200);
                res.setBody(buildNoCardsResponse());
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
            } else if (mode == 'VARIANT_CARDS') {
                res.setStatusCode(200);
                res.setBody(buildVariantCardsResponse());
            } else {
                res.setStatusCode(200);
                res.setBody(buildSuccessPfResponse());
            }

            return res;
        }
    }

    @IsTest
    static void testConsultarTarjetasParaBloqueo_SuccessPF_NoCreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new TarjetasBloqueoHttpMock('SUCCESS_PF'));

        AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest req = buildBasePfRequest();

        Test.startTest();
        AGENTE_ConsultarTarjetasParaBloqueo.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueo(req);
        Test.stopTest();

        System.assertEquals('OK', result.status);
        System.assertEquals(3, result.totalCards);
        System.assertEquals(3, result.cards.size());

        System.assertEquals('Tarjeta ****3456 - VIGENTE', result.cards[0].displayLabel);
        System.assertEquals('Tarjeta ****4444 - INACTIVA', result.cards[1].displayLabel);
        System.assertEquals('Tarjeta ****7654 - ACTIVA', result.cards[2].displayLabel);

        System.assertEquals(true, result.cards[0].eligibleForBlock);
        System.assertEquals(true, result.cards[1].eligibleForBlock);
        System.assertEquals(true, result.cards[2].eligibleForBlock);

        System.assertEquals('DOP', result.cards[0].currencyCode);
        System.assertEquals('1234567890123456', result.cards[0].integrationProductNumber);
        System.assertEquals('TARJETA CREDITO', result.cards[0].integrationProductType);

        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarTarjetasParaBloqueo_SuccessPJ_NoCreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new TarjetasBloqueoHttpMock('SUCCESS_PJ'));

        AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest req = buildBasePjRequest();

        Test.startTest();
        AGENTE_ConsultarTarjetasParaBloqueo.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueo(req);
        Test.stopTest();

        System.assertEquals('OK', result.status);
        System.assertEquals(1, result.totalCards);
        System.assertEquals('Tarjeta ****2114 - VIGENTE', result.cards[0].displayLabel);
        System.assertEquals('USD', result.cards[0].currencyCode);

        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarTarjetasParaBloqueo_NoCards_NoCreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new TarjetasBloqueoHttpMock('NO_CARDS'));

        AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest req = buildBasePfRequest();

        Test.startTest();
        AGENTE_ConsultarTarjetasParaBloqueo.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueo(req);
        Test.stopTest();

        System.assertEquals('NO_CARDS', result.status);
        System.assertEquals(0, result.totalCards);
        System.assertEquals(0, result.cards.size());
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarTarjetasParaBloqueo_CoreError_CreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new TarjetasBloqueoHttpMock('CORE_ERROR'));

        AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest req = buildBasePfRequest();

        Test.startTest();
        AGENTE_ConsultarTarjetasParaBloqueo.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueo(req);
        Test.stopTest();

        System.assertEquals('ERROR', result.status);

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
            WHERE SourceClass__c = 'AGENTE_ConsultarTarjetasParaBloqueo'
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
    static void testConsultarTarjetasParaBloqueo_HttpError_CreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new TarjetasBloqueoHttpMock('HTTP_ERROR'));

        AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest req = buildBasePfRequest();

        Test.startTest();
        AGENTE_ConsultarTarjetasParaBloqueo.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueo(req);
        Test.stopTest();

        System.assertEquals('ERROR', result.status);
        System.assert(result.message.contains('Código HTTP: 500'));

        List<AgentLog__c> logs = [
            SELECT Id,
                   Status__c,
                   SourceClass__c,
                   IntegrationName__c,
                   Operation__c,
                   HttpStatusCode__c,
                   HttpMethod__c,
                   ExternalErrorCode__c,
                   ErrorMessage__c
            FROM AgentLog__c
            WHERE SourceClass__c = 'AGENTE_ConsultarTarjetasParaBloqueo'
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
    static void testConsultarTarjetasParaBloqueo_InvalidBody_CreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new TarjetasBloqueoHttpMock('INVALID_BODY'));

        AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest req = buildBasePfRequest();

        Test.startTest();
        AGENTE_ConsultarTarjetasParaBloqueo.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueo(req);
        Test.stopTest();

        System.assertEquals('ERROR', result.status);

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
            WHERE SourceClass__c = 'AGENTE_ConsultarTarjetasParaBloqueo'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(1, logs.size());
        System.assertEquals('Error', logs[0].Status__c);
        System.assertEquals('ConsultaProdFinPF', logs[0].Operation__c);
        System.assertEquals(200, logs[0].HttpStatusCode__c);
        System.assertEquals('INVALID_RESPONSE', logs[0].ExternalErrorCode__c);
        System.assert(logs[0].ErrorMessage__c.contains('No se encontró el nodo Body'));
    }

    @IsTest
    static void testConsultarTarjetasParaBloqueo_CalloutException_CreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new TarjetasBloqueoHttpMock('CALLOUT_EXCEPTION'));

        AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest req = buildBasePfRequest();

        Test.startTest();
        AGENTE_ConsultarTarjetasParaBloqueo.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueo(req);
        Test.stopTest();

        System.assertEquals('ERROR', result.status);

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
            WHERE SourceClass__c = 'AGENTE_ConsultarTarjetasParaBloqueo'
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
    static void testConsultarTarjetasParaBloqueo_ValidationErrors_NoCreaAgentLog() {
        AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest req1 =
            new AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest();

        AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest req2 =
            new AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest();
        req2.customerType = 'XX';
        req2.identificationNumber = '123';
        req2.identificationType = 'Cedula';
        req2.cif = '999';

        AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest req3 =
            new AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest();
        req3.customerType = 'PF';
        req3.identificationNumber = '123';
        req3.identificationType = '';
        req3.cif = '999';

        AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest req4 =
            new AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest();
        req4.customerType = 'PF';
        req4.identificationNumber = '';
        req4.identificationType = 'Cedula';
        req4.cif = '999';

        AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest req5 =
            new AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest();
        req5.customerType = 'PF';
        req5.identificationNumber = '123';
        req5.identificationType = 'Cedula';
        req5.cif = '';

        Test.startTest();

        AGENTE_ConsultarTarjetasParaBloqueo.CardPortfolioResponse res1 =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueo(req1);

        AGENTE_ConsultarTarjetasParaBloqueo.CardPortfolioResponse res2 =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueo(req2);

        AGENTE_ConsultarTarjetasParaBloqueo.CardPortfolioResponse res3 =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueo(req3);

        AGENTE_ConsultarTarjetasParaBloqueo.CardPortfolioResponse res4 =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueo(req4);

        AGENTE_ConsultarTarjetasParaBloqueo.CardPortfolioResponse res5 =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueo(req5);

        Test.stopTest();

        System.assertEquals('ERROR', res1.status);
        System.assertEquals('ERROR', res2.status);
        System.assertEquals('ERROR', res3.status);
        System.assertEquals('ERROR', res4.status);
        System.assertEquals('ERROR', res5.status);

        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarTarjetasParaBloqueoFlow_NullInputs() {
        Test.startTest();
        List<AGENTE_ConsultarTarjetasParaBloqueo.InvocableOutput> result =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueoFlow(null);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('ERROR', result[0].status);
        System.assertEquals(0, result[0].totalCards);
        System.assertEquals('[]', result[0].cardsJson);
    }

    @IsTest
    static void testConsultarTarjetasParaBloqueoFlow_EmptyInputs() {
        Test.startTest();
        List<AGENTE_ConsultarTarjetasParaBloqueo.InvocableOutput> result =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueoFlow(
                new List<AGENTE_ConsultarTarjetasParaBloqueo.InvocableInput>()
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('ERROR', result[0].status);
        System.assertEquals(0, result[0].totalCards);
        System.assertEquals('[]', result[0].cardsJson);
    }
@IsTest
    static void testConsultarTarjetasParaBloqueoFlow_Success() {
        // CUBRE: El camino feliz del método Invocable llamado por Agentforce/Flow
        Test.setMock(HttpCalloutMock.class, new TarjetasBloqueoHttpMock('SUCCESS_PF'));

        Account acc = createFlowAccount('10');
        AGENTE_ConsultarTarjetasParaBloqueo.InvocableInput input = new AGENTE_ConsultarTarjetasParaBloqueo.InvocableInput();
        input.accountId = '001000000000000AAA'; // Ajusta si usas un ID distinto en este agente
        input.accountId = acc.Id;
        input.identificationNumber = '00108803610';

        Test.startTest();
        List<AGENTE_ConsultarTarjetasParaBloqueo.InvocableOutput> outputs = 
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueoFlow(
                new List<AGENTE_ConsultarTarjetasParaBloqueo.InvocableInput>{input}
            );
        Test.stopTest();

        System.assertNotEquals(null, outputs, 'La lista de salida no debe ser nula');
        System.assertEquals(1, outputs.size(), 'Debe devolver un output por cada input');
        System.assertEquals('OK', outputs[0].status, 'El estado del output debe ser OK');
    }

    @IsTest
    static void testConsultarTarjetasParaBloqueoFlow_Bulk() {
        // CUBRE: La ejecución masiva del Invocable Method
        Test.setMock(HttpCalloutMock.class, new TarjetasBloqueoHttpMock('SUCCESS_PF'));

        List<AGENTE_ConsultarTarjetasParaBloqueo.InvocableInput> inputs = new List<AGENTE_ConsultarTarjetasParaBloqueo.InvocableInput>();
        
        // Simulamos el envío de 3 registros simultáneos desde el flow
        for(Integer i = 0; i < 3; i++) {
            Account acc = createFlowAccount(String.valueOf(i));
            AGENTE_ConsultarTarjetasParaBloqueo.InvocableInput input = new AGENTE_ConsultarTarjetasParaBloqueo.InvocableInput();
            input.accountId = acc.Id;
            input.identificationNumber = '0010880361' + i;
            inputs.add(input);
        }

        Test.startTest();
        List<AGENTE_ConsultarTarjetasParaBloqueo.InvocableOutput> outputs = 
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueoFlow(inputs);
        Test.stopTest();

        System.assertNotEquals(null, outputs);
        System.assertEquals(3, outputs.size(), 'Debe procesar y devolver 3 outputs correctamente');
        System.assertEquals('OK', outputs[0].status);
    }

    @IsTest
    static void testConsultarTarjetasParaBloqueo_MapsAdditionalCardVariants() {
        Test.setMock(HttpCalloutMock.class, new TarjetasBloqueoHttpMock('VARIANT_CARDS'));

        Test.startTest();
        AGENTE_ConsultarTarjetasParaBloqueo.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueo(buildBasePfRequest());
        Test.stopTest();

        System.assertEquals('OK', result.status);
        System.assertEquals(3, result.totalCards);
        System.assertEquals('Tarjeta', result.cards[0].productType);
        System.assertEquals('Tarjeta', result.cards[1].productType);
        System.assertEquals('Tarjeta', result.cards[2].productType);
    }

    @IsTest
    static void testConsultarTarjetasParaBloqueoFlow_InputFailures() {
        AGENTE_ConsultarTarjetasParaBloqueo.InvocableInput missingAccount =
            new AGENTE_ConsultarTarjetasParaBloqueo.InvocableInput();
        AGENTE_ConsultarTarjetasParaBloqueo.InvocableInput missingDocument =
            new AGENTE_ConsultarTarjetasParaBloqueo.InvocableInput();
        missingDocument.accountId = '001000000000000AAA';
        AGENTE_ConsultarTarjetasParaBloqueo.InvocableInput unknownAccount =
            new AGENTE_ConsultarTarjetasParaBloqueo.InvocableInput();
        unknownAccount.accountId = '001000000000000AAA';
        unknownAccount.identificationNumber = '00108803610';

        Test.startTest();
        List<AGENTE_ConsultarTarjetasParaBloqueo.InvocableOutput> results =
            AGENTE_ConsultarTarjetasParaBloqueo.consultarTarjetasParaBloqueoFlow(
                new List<AGENTE_ConsultarTarjetasParaBloqueo.InvocableInput>{
                    null,
                    missingAccount,
                    missingDocument,
                    unknownAccount
                }
            );
        Test.stopTest();

        System.assertEquals(4, results.size());
        for (AGENTE_ConsultarTarjetasParaBloqueo.InvocableOutput result : results) {
            System.assertEquals('ERROR', result.status);
        }
    }

    private static Account createFlowAccount(String suffix) {
        Account acc = new Account(
            RecordTypeId = getPersonAccountRtId(),
            FirstName = 'Cliente',
            LastName = 'Bloqueo ' + suffix,
            ACC_CIF__c = '1022328' + suffix,
            ACC_Condicion__c = 'CLIENTE'
        );
        insert acc;
        return acc;
    }

    private static Id getPersonAccountRtId() {
        return [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName = 'PersonAccount'
            LIMIT 1
        ].Id;
    }
    private static AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest buildBasePfRequest() {
        AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest req =
            new AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest();

        req.customerType = 'PF';
        req.identificationNumber = '00108803610';
        req.identificationType = 'Cédula';
        req.cif = '1022328';

        return req;
    }

    private static AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest buildBasePjRequest() {
        AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest req =
            new AGENTE_ConsultarTarjetasParaBloqueo.InternalRequest();

        req.customerType = 'PJ';
        req.identificationNumber = '101010101';
        req.identificationType = '';
        req.cif = '5555';

        return req;
    }

    private static String buildSuccessPfResponse() {
        return ''
            + '<?xml version="1.0" encoding="UTF-8"?>'
            + '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'
            + '  <SOAP-ENV:Body>'
            + '    <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20VBC%20Response%20IO">'
            + '      <Result>'
            + '        <ErrorCode>000</ErrorCode>'
            + '        <ErrorText>TRANSACCION PROCESADA</ErrorText>'
            + '        <Producto>'
            + '          <NumCuenta>1234567890123456</NumCuenta>'
            + '          <CodigoProducto>TCR</CodigoProducto>'
            + '          <LineaProducto>TARJETA CREDITO</LineaProducto>'
            + '          <Estado>VIGENTE</Estado>'
            + '          <SaldoRD>100.00</SaldoRD>'
            + '          <SaldoUS>0.00</SaldoUS>'
            + '          <TipoVinculacion>Principal</TipoVinculacion>'
            + '          <Titulares>Cliente Test</Titulares>'
            + '        </Producto>'
            + '        <Producto>'
            + '          <NumCuenta>1111222233334444</NumCuenta>'
            + '          <CodigoProducto>TCR</CodigoProducto>'
            + '          <LineaProducto>TARJETA CREDITO</LineaProducto>'
            + '          <Estado>INACTIVA</Estado>'
            + '          <SaldoRD>50.00</SaldoRD>'
            + '          <SaldoUS>0.00</SaldoUS>'
            + '          <TipoVinculacion>Principal</TipoVinculacion>'
            + '          <Titulares>Cliente Test</Titulares>'
            + '        </Producto>'
            + '        <Producto>'
            + '          <NumCuenta>9876543210987654</NumCuenta>'
            + '          <CodigoProducto>TCR</CodigoProducto>'
            + '          <LineaProducto>TARJETA CREDITO</LineaProducto>'
            + '          <Estado>ACTIVA</Estado>'
            + '          <SaldoRD>25.00</SaldoRD>'
            + '          <SaldoUS>0.00</SaldoUS>'
            + '          <TipoVinculacion>Principal</TipoVinculacion>'
            + '          <Titulares>Cliente Test</Titulares>'
            + '        </Producto>'
            + '        <Producto>'
            + '          <NumCuenta>5555666677778888</NumCuenta>'
            + '          <CodigoProducto>TCR</CodigoProducto>'
            + '          <LineaProducto>TARJETA CREDITO</LineaProducto>'
            + '          <Estado>BLOQUEADA</Estado>'
            + '          <SaldoRD>10.00</SaldoRD>'
            + '          <SaldoUS>0.00</SaldoUS>'
            + '          <TipoVinculacion>Principal</TipoVinculacion>'
            + '          <Titulares>Cliente Test</Titulares>'
            + '        </Producto>'
            + '      </Result>'
            + '    </ListOfBREAIFuncionGeneral>'
            + '  </SOAP-ENV:Body>'
            + '</SOAP-ENV:Envelope>';
    }

    private static String buildSuccessPjResponse() {
        return ''
            + '<?xml version="1.0" encoding="UTF-8"?>'
            + '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'
            + '  <SOAP-ENV:Body>'
            + '    <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PJ%20Response%20IO">'
            + '      <Result>'
            + '        <ErrorCode>000</ErrorCode>'
            + '        <ErrorText>TRANSACCION PROCESADA</ErrorText>'
            + '        <Producto>'
            + '          <NumCuenta>2401322114</NumCuenta>'
            + '          <CodigoProducto>TCR</CodigoProducto>'
            + '          <LineaProducto>TARJETA CREDITO</LineaProducto>'
            + '          <Estado>VIGENTE</Estado>'
            + '          <SaldoRD>0.00</SaldoRD>'
            + '          <SaldoUS>25.00</SaldoUS>'
            + '          <TipoVinculacion>Principal</TipoVinculacion>'
            + '          <Titulares>Empresa Test</Titulares>'
            + '        </Producto>'
            + '      </Result>'
            + '    </ListOfBREAIFuncionGeneral>'
            + '  </SOAP-ENV:Body>'
            + '</SOAP-ENV:Envelope>';
    }

    private static String buildNoCardsResponse() {
        return ''
            + '<?xml version="1.0" encoding="UTF-8"?>'
            + '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'
            + '  <SOAP-ENV:Body>'
            + '    <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20VBC%20Response%20IO">'
            + '      <Result>'
            + '        <ErrorCode>000</ErrorCode>'
            + '        <ErrorText>TRANSACCION PROCESADA</ErrorText>'
            + '        <Producto>'
            + '          <NumCuenta>1111222233334444</NumCuenta>'
            + '          <CodigoProducto>TCR</CodigoProducto>'
            + '          <LineaProducto>TARJETA CREDITO</LineaProducto>'
            + '          <Estado>BLOQUEADA</Estado>'
            + '          <SaldoRD>50.00</SaldoRD>'
            + '          <SaldoUS>0.00</SaldoUS>'
            + '          <TipoVinculacion>Principal</TipoVinculacion>'
            + '          <Titulares>Cliente Test</Titulares>'
            + '        </Producto>'
            + '      </Result>'
            + '    </ListOfBREAIFuncionGeneral>'
            + '  </SOAP-ENV:Body>'
            + '</SOAP-ENV:Envelope>';
    }

    private static String buildCoreErrorResponse() {
        return ''
            + '<?xml version="1.0" encoding="UTF-8"?>'
            + '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'
            + '  <SOAP-ENV:Body>'
            + '    <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20VBC%20Response%20IO">'
            + '      <Result>'
            + '        <ErrorCode>999</ErrorCode>'
            + '        <ErrorText>ERROR CONTROLADO</ErrorText>'
            + '      </Result>'
            + '    </ListOfBREAIFuncionGeneral>'
            + '  </SOAP-ENV:Body>'
            + '</SOAP-ENV:Envelope>';
    }

    private static String buildVariantCardsResponse() {
        return ''
            + '<?xml version="1.0" encoding="UTF-8"?>'
            + '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'
            + '  <SOAP-ENV:Body>'
            + '    <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20VBC%20Response%20IO">'
            + '      <Result>'
            + '        <ErrorCode>000</ErrorCode>'
            + '        <ErrorText>TRANSACCION PROCESADA</ErrorText>'
            + '        <Producto><NumCuenta>12</NumCuenta><CodigoProducto>PRE</CodigoProducto><LineaProducto>PREPAGO</LineaProducto><Estado>ACTIVA</Estado><SaldoRD>0.00</SaldoRD><SaldoUS>0.00</SaldoUS></Producto>'
            + '        <Producto><NumCuenta>2345</NumCuenta><CodigoProducto>TDB</CodigoProducto><LineaProducto>DEBITO</LineaProducto><Estado>INACTIVA</Estado><SaldoRD>invalido</SaldoRD><SaldoUS>0.00</SaldoUS></Producto>'
            + '        <Producto><NumCuenta>3456</NumCuenta><CodigoProducto>TAR</CodigoProducto><LineaProducto>CUENTA</LineaProducto><Estado>VIGENTE</Estado><SaldoRD>0.00</SaldoRD><SaldoUS>0.00</SaldoUS></Producto>'
            + '        <Producto><NumCuenta>4567</NumCuenta><CodigoProducto>TCR</CodigoProducto><LineaProducto>TARJETA</LineaProducto><Estado>ACTIVA</Estado><SaldoRD>0.00</SaldoRD><SaldoUS>0.00</SaldoUS></Producto>'
            + '        <Producto><NumCuenta>5678</NumCuenta><CodigoProducto>CTA</CodigoProducto><LineaProducto>CUENTA</LineaProducto><Estado></Estado><SaldoRD>0.00</SaldoRD><SaldoUS>0.00</SaldoUS></Producto>'
            + '      </Result>'
            + '    </ListOfBREAIFuncionGeneral>'
            + '  </SOAP-ENV:Body>'
            + '</SOAP-ENV:Envelope>';
    }
}
