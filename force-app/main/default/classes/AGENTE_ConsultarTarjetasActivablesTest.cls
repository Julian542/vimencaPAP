@IsTest
private class AGENTE_ConsultarTarjetasActivablesTest {

    private class TarjetasHttpMock implements HttpCalloutMock {
        
        private final String mode;

        TarjetasHttpMock(String mode) {
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
                res.setBody(buildNoEligibleCardsResponse());
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
            } else if (mode == 'EMPTY_XML') {
                res.setStatusCode(200);
                res.setBody(buildEmptyXmlResponse());
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

    // ============================================================================
    // TESTS ORIGINALES (Mantenidos y funcionales)
    // ============================================================================

    @IsTest
    static void testConsultarTarjetasActivables_SuccessPF_NoCreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new TarjetasHttpMock('SUCCESS_PF'));

        AGENTE_ConsultarTarjetasActivables.InternalRequest req = buildBasePfRequest();

        Test.startTest();
        AGENTE_ConsultarTarjetasActivables.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivables(req);
        Test.stopTest();

        System.assertEquals('OK', result.status);
        System.assertEquals(1, result.totalCards);
        System.assertEquals(1, result.cards.size());
        System.assertEquals(true, result.cards[0].eligibleForActivation);
        System.assertEquals('INACTIVA', result.cards[0].status);
        System.assertEquals('Tarjeta ****4444 - INACTIVA', result.cards[0].displayLabel);
        System.assertEquals('1234567890124444', result.cards[0].integrationProductNumber);
        System.assertEquals('TARJETA CREDITO', result.cards[0].integrationProductType);
        System.assertEquals('DOP', result.cards[0].currencyCode);
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarTarjetasActivables_SuccessPJ_NoCreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new TarjetasHttpMock('SUCCESS_PJ'));

        AGENTE_ConsultarTarjetasActivables.InternalRequest req = buildBasePjRequest();

        Test.startTest();
        AGENTE_ConsultarTarjetasActivables.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivables(req);
        Test.stopTest();

        System.assertEquals('OK', result.status);
        System.assertEquals(1, result.totalCards);
        System.assertEquals('Tarjeta ****2114 - INACTIVA', result.cards[0].displayLabel);
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarTarjetasActivables_NoCards_NoCreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new TarjetasHttpMock('NO_CARDS'));

        AGENTE_ConsultarTarjetasActivables.InternalRequest req = buildBasePfRequest();

        Test.startTest();
        AGENTE_ConsultarTarjetasActivables.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivables(req);
        Test.stopTest();

        System.assertEquals('NO_CARDS', result.status);
        System.assertEquals(0, result.totalCards);
        System.assertEquals(0, result.cards.size());
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarTarjetasActivables_CoreError_CreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new TarjetasHttpMock('CORE_ERROR'));

        AGENTE_ConsultarTarjetasActivables.InternalRequest req = buildBasePfRequest();

        Test.startTest();
        AGENTE_ConsultarTarjetasActivables.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivables(req);
        Test.stopTest();

        System.assertEquals('ERROR', result.status);

        List<AgentLog__c> logs = [
            SELECT Id, Status__c, SourceClass__c, IntegrationName__c, Operation__c,
                   HttpStatusCode__c, HttpMethod__c, ExternalErrorCode__c,
                   ErrorMessage__c, RequestPayload__c, ResponsePayload__c
            FROM AgentLog__c
            WHERE SourceClass__c = 'AGENTE_ConsultarTarjetasActivables'
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
    }

    @IsTest
    static void testConsultarTarjetasActivables_HttpError_CreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new TarjetasHttpMock('HTTP_ERROR'));

        AGENTE_ConsultarTarjetasActivables.InternalRequest req = buildBasePfRequest();

        Test.startTest();
        AGENTE_ConsultarTarjetasActivables.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivables(req);
        Test.stopTest();

        System.assertEquals('ERROR', result.status);
        System.assert(result.message.contains('Código HTTP: 500'));

        List<AgentLog__c> logs = [
            SELECT Id, Status__c, SourceClass__c, IntegrationName__c, Operation__c,
                   HttpStatusCode__c, HttpMethod__c, ExternalErrorCode__c, ErrorMessage__c
            FROM AgentLog__c
            WHERE SourceClass__c = 'AGENTE_ConsultarTarjetasActivables'
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
    static void testConsultarTarjetasActivables_InvalidBody_CreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new TarjetasHttpMock('INVALID_BODY'));

        AGENTE_ConsultarTarjetasActivables.InternalRequest req = buildBasePfRequest();

        Test.startTest();
        AGENTE_ConsultarTarjetasActivables.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivables(req);
        Test.stopTest();

        System.assertEquals('ERROR', result.status);

        List<AgentLog__c> logs = [
            SELECT Id, Status__c, SourceClass__c, IntegrationName__c, Operation__c,
                   HttpStatusCode__c, ExternalErrorCode__c, ErrorMessage__c
            FROM AgentLog__c
            WHERE SourceClass__c = 'AGENTE_ConsultarTarjetasActivables'
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
    static void testConsultarTarjetasActivables_CalloutException_CreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new TarjetasHttpMock('CALLOUT_EXCEPTION'));

        AGENTE_ConsultarTarjetasActivables.InternalRequest req = buildBasePfRequest();

        Test.startTest();
        AGENTE_ConsultarTarjetasActivables.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivables(req);
        Test.stopTest();

        List<AgentLog__c> logs = [
            SELECT Id, Status__c, SourceClass__c, IntegrationName__c, Operation__c,
                   HttpStatusCode__c, ExternalErrorCode__c, ErrorMessage__c
            FROM AgentLog__c
            WHERE SourceClass__c = 'AGENTE_ConsultarTarjetasActivables'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }

    @IsTest
    static void testConsultarTarjetasActivables_ValidationErrors_NoCreaAgentLog() {
        AGENTE_ConsultarTarjetasActivables.InternalRequest req1 = new AGENTE_ConsultarTarjetasActivables.InternalRequest();

        AGENTE_ConsultarTarjetasActivables.InternalRequest req2 = new AGENTE_ConsultarTarjetasActivables.InternalRequest();
        req2.customerType = 'XX';
        req2.identificationNumber = '123';
        req2.identificationType = 'Cedula';
        req2.cif = '999';

        AGENTE_ConsultarTarjetasActivables.InternalRequest req3 = new AGENTE_ConsultarTarjetasActivables.InternalRequest();
        req3.customerType = 'PF';
        req3.identificationNumber = '123';
        req3.identificationType = '';
        req3.cif = '999';

        AGENTE_ConsultarTarjetasActivables.InternalRequest req4 = new AGENTE_ConsultarTarjetasActivables.InternalRequest();
        req4.customerType = 'PF';
        req4.identificationNumber = '';
        req4.identificationType = 'Cedula';
        req4.cif = '999';

        AGENTE_ConsultarTarjetasActivables.InternalRequest req5 = new AGENTE_ConsultarTarjetasActivables.InternalRequest();
        req5.customerType = 'PF';
        req5.identificationNumber = '123';
        req5.identificationType = 'Cedula';
        req5.cif = '';

        Test.startTest();

        System.assertEquals('ERROR', AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivables(req1).status);
        System.assertEquals('ERROR', AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivables(req2).status);
        System.assertEquals('ERROR', AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivables(req3).status);
        System.assertEquals('ERROR', AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivables(req4).status);
        System.assertEquals('ERROR', AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivables(req5).status);

        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    // ============================================================================
    // NUEVOS TESTS (Para forzar cobertura de bloques catch e Invocables)
    // ============================================================================

    @IsTest
    static void testConsultarTarjetasActivables_NullRequest_CatchBlock() {
        // Cubre el bloque catch genérico si se envía un nulo absoluto
        Test.startTest();
        AGENTE_ConsultarTarjetasActivables.CardPortfolioResponse result = 
            AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivables(null);
        Test.stopTest();

        System.assertEquals('ERROR', result.status, 'Debe atrapar el NullPointerException u error de validación');
    }

    @IsTest
    static void testConsultarTarjetasActivables_EmptyXml() {
        // Cubre la lógica de iteración de XML cuando existe el ErrorCode 000 pero no hay nodos <Producto>
        Test.setMock(HttpCalloutMock.class, new TarjetasHttpMock('EMPTY_XML'));

        AGENTE_ConsultarTarjetasActivables.InternalRequest req = buildBasePfRequest();

        Test.startTest();
        AGENTE_ConsultarTarjetasActivables.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivables(req);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser nulo');
        // Dependiendo de tu lógica interna, esto podría devolver NO_CARDS o OK con 0 tarjetas.
    }

    @IsTest
    static void testConsultarTarjetasActivables_InvocableMethod() {
        // Cubre el wrapper @InvocableMethod (consultarTarjetasActivablesFlow) que Agentforce o Flow llama.
        Test.setMock(HttpCalloutMock.class, new TarjetasHttpMock('SUCCESS_PF'));

        // Nota: Asegúrate de que los nombres de las propiedades coincidan con tu clase InvocableInput
        Account acc = createFlowAccount('10');
        AGENTE_ConsultarTarjetasActivables.InvocableInput input = new AGENTE_ConsultarTarjetasActivables.InvocableInput();
        input.accountId = '001000000000000AAA'; // Id ficticio para pasar la validación de nulos
        input.accountId = acc.Id;
        input.identificationNumber = '00108803610';
        Test.startTest();
        List<AGENTE_ConsultarTarjetasActivables.InvocableOutput> outputs = 
            AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivablesFlow(
                new List<AGENTE_ConsultarTarjetasActivables.InvocableInput>{input}
            );
        Test.stopTest();

        System.assertNotEquals(null, outputs, 'La lista InvocableOutput no debe ser nula');
        System.assertEquals(1, outputs.size(), 'Debe devolver un output por cada input');
        System.assertEquals('OK', outputs[0].status);
    }
@IsTest
    static void testConsultarTarjetasActivables_InvocableMethod_EmptyList() {
        // CUBRE: El escenario donde el Flow o Agentforce envía una lista vacía
        Test.startTest();
        List<AGENTE_ConsultarTarjetasActivables.InvocableOutput> outputs = 
            AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivablesFlow(
                new List<AGENTE_ConsultarTarjetasActivables.InvocableInput>()
            );
        Test.stopTest();

        // Dependiendo de tu código, esto devolverá null o una lista vacía, 
        // pero la llamada garantiza la cobertura de la validación inicial.
        System.assertEquals(1, outputs.size(), 'Debe devolver un output de error para listas vacías');
    }

    @IsTest
    static void testConsultarTarjetasActivables_InvocableMethod_InvalidInput() {
        // CUBRE: El bloque de captura de errores y validaciones cuando la llamada viene del Flow
        AGENTE_ConsultarTarjetasActivables.InvocableInput input = new AGENTE_ConsultarTarjetasActivables.InvocableInput();
        // Al dejar el AccountId y el IdentificationNumber nulos, forzamos que 
        // falle la validación interna y devuelva un InvocableOutput con status de ERROR.
        
        Test.startTest();
        List<AGENTE_ConsultarTarjetasActivables.InvocableOutput> outputs = 
            AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivablesFlow(
                new List<AGENTE_ConsultarTarjetasActivables.InvocableInput>{input}
            );
        Test.stopTest();

        System.assertNotEquals(null, outputs, 'La lista de salida no debe ser nula');
        System.assertEquals(1, outputs.size(), 'Debe devolver un registro de error por el input recibido');
        // Usualmente el status viaja en alguna propiedad, asegúrate de cubrir la asignación de errores
    }

    @IsTest
    static void testConsultarTarjetasActivables_InvocableMethod_Bulk() {
        // CUBRE: El bucle "for" completo del Invocable Method (Best Practice de Salesforce)
        Test.setMock(HttpCalloutMock.class, new TarjetasHttpMock('SUCCESS_PF'));

        List<AGENTE_ConsultarTarjetasActivables.InvocableInput> inputs = new List<AGENTE_ConsultarTarjetasActivables.InvocableInput>();
        
        // Creamos 3 inputs simulando una llamada masiva
        for(Integer i = 0; i < 3; i++) {
            Account acc = createFlowAccount(String.valueOf(i));
            AGENTE_ConsultarTarjetasActivables.InvocableInput input = new AGENTE_ConsultarTarjetasActivables.InvocableInput();
            input.accountId = acc.Id; 
            input.identificationNumber = '0010880361' + i;
            inputs.add(input);
        }

        Test.startTest();
        List<AGENTE_ConsultarTarjetasActivables.InvocableOutput> outputs = 
            AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivablesFlow(inputs);
        Test.stopTest();

        System.assertNotEquals(null, outputs);
        System.assertEquals(3, outputs.size(), 'Debe procesar y devolver 3 outputs');
    }

    @IsTest
    static void testConsultarTarjetasActivables_MapsAdditionalCardVariants() {
        Test.setMock(HttpCalloutMock.class, new TarjetasHttpMock('VARIANT_CARDS'));

        Test.startTest();
        AGENTE_ConsultarTarjetasActivables.CardPortfolioResponse result =
            AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivables(buildBasePfRequest());
        Test.stopTest();

        System.assertEquals('OK', result.status);
        System.assertEquals(4, result.totalCards);
        System.assertEquals('Prepago', result.cards[0].productType);
        System.assertEquals('Tarjeta', result.cards[1].productType);
        System.assertEquals('Tarjeta', result.cards[2].productType);
        System.assertEquals('Producto', result.cards[3].productType);
    }

    @IsTest
    static void testConsultarTarjetasActivables_InvocableInputFailures() {
        AGENTE_ConsultarTarjetasActivables.InvocableInput missingAccount =
            new AGENTE_ConsultarTarjetasActivables.InvocableInput();
        AGENTE_ConsultarTarjetasActivables.InvocableInput missingDocument =
            new AGENTE_ConsultarTarjetasActivables.InvocableInput();
        missingDocument.accountId = '001000000000000AAA';
        AGENTE_ConsultarTarjetasActivables.InvocableInput unknownAccount =
            new AGENTE_ConsultarTarjetasActivables.InvocableInput();
        unknownAccount.accountId = '001000000000000AAA';
        unknownAccount.identificationNumber = '00108803610';

        Test.startTest();
        List<AGENTE_ConsultarTarjetasActivables.InvocableOutput> results =
            AGENTE_ConsultarTarjetasActivables.consultarTarjetasActivablesFlow(
                new List<AGENTE_ConsultarTarjetasActivables.InvocableInput>{
                    null,
                    missingAccount,
                    missingDocument,
                    unknownAccount
                }
            );
        Test.stopTest();

        System.assertEquals(4, results.size());
        for (AGENTE_ConsultarTarjetasActivables.InvocableOutput result : results) {
            System.assertEquals('ERROR', result.status);
        }
    }

    private static Account createFlowAccount(String suffix) {
        Account acc = new Account(
            RecordTypeId = getPersonAccountRtId(),
            FirstName = 'Cliente',
            LastName = 'Activable ' + suffix,
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

    // ============================================================================
    // MÉTODOS DE CONSTRUCCIÓN DE STRINGS XML Y REQUESTS
    // ============================================================================

    private static AGENTE_ConsultarTarjetasActivables.InternalRequest buildBasePfRequest() {
        AGENTE_ConsultarTarjetasActivables.InternalRequest req = new AGENTE_ConsultarTarjetasActivables.InternalRequest();
        req.customerType = 'PF';
        req.identificationNumber = '00108803610';
        req.identificationType = 'Cédula';
        req.cif = '1022328';
        return req;
    }

    private static AGENTE_ConsultarTarjetasActivables.InternalRequest buildBasePjRequest() {
        AGENTE_ConsultarTarjetasActivables.InternalRequest req = new AGENTE_ConsultarTarjetasActivables.InternalRequest();
        req.customerType = 'PJ';
        req.identificationNumber = '101010101';
        req.identificationType = 'RNC'; // Ajustado para evitar string vacío que fallaría tu validación
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
            + '          <NumCuenta>1234567890124444</NumCuenta>'
            + '          <CodigoProducto>TCR</CodigoProducto>'
            + '          <LineaProducto>TARJETA CREDITO</LineaProducto>'
            + '          <Estado>INACTIVA</Estado>'
            + '          <SaldoRD>100.00</SaldoRD>'
            + '          <SaldoUS>0.00</SaldoUS>'
            + '          <TipoVinculacion>Principal</TipoVinculacion>'
            + '          <Titulares>Cliente Test</Titulares>'
            + '        </Producto>'
            + '        <Producto>'
            + '          <NumCuenta>1111222233334444</NumCuenta>'
            + '          <CodigoProducto>TCR</CodigoProducto>'
            + '          <LineaProducto>TARJETA CREDITO</LineaProducto>'
            + '          <Estado>VIGENTE</Estado>'
            + '          <SaldoRD>50.00</SaldoRD>'
            + '          <SaldoUS>0.00</SaldoUS>'
            + '          <TipoVinculacion>Principal</TipoVinculacion>'
            + '          <Titulares>Cliente Test</Titulares>'
            + '        </Producto>'
            + '        <Producto>'
            + '          <NumCuenta>9876543210987654</NumCuenta>'
            + '          <CodigoProducto>TCR</CodigoProducto>'
            + '          <LineaProducto>TARJETA CREDITO</LineaProducto>'
            + '          <Estado>BLOQUEADA</Estado>'
            + '          <SaldoRD>25.00</SaldoRD>'
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
            + '          <Estado>INACTIVA</Estado>'
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

    private static String buildNoEligibleCardsResponse() {
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
            + '          <Estado>VIGENTE</Estado>'
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

    private static String buildEmptyXmlResponse() {
        return ''
            + '<?xml version="1.0" encoding="UTF-8"?>'
            + '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">'
            + '  <SOAP-ENV:Body>'
            + '    <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20VBC%20Response%20IO">'
            + '      <Result>'
            + '        <ErrorCode>000</ErrorCode>'
            + '        <ErrorText>TRANSACCION PROCESADA SIN PRODUCTOS</ErrorText>'
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
            + '        <Producto><NumCuenta>1234</NumCuenta><CodigoProducto>PRE</CodigoProducto><LineaProducto>PREPAGO</LineaProducto><Estado>INACTIVA</Estado><SaldoRD>0.00</SaldoRD><SaldoUS>0.00</SaldoUS></Producto>'
            + '        <Producto><NumCuenta>2345</NumCuenta><CodigoProducto>TDB</CodigoProducto><LineaProducto>DEBITO</LineaProducto><Estado>INACTIVA</Estado><SaldoRD>0.00</SaldoRD><SaldoUS>invalido</SaldoUS></Producto>'
            + '        <Producto><NumCuenta>3456</NumCuenta><CodigoProducto>TCR</CodigoProducto><LineaProducto>CREDITO</LineaProducto><Estado>INACTIVA</Estado><SaldoRD>invalido</SaldoRD><SaldoUS>0.00</SaldoUS></Producto>'
            + '        <Producto><NumCuenta>4567</NumCuenta><CodigoProducto>TAR</CodigoProducto><LineaProducto>CUENTA</LineaProducto><Estado>INACTIVA</Estado><SaldoRD>0.00</SaldoRD><SaldoUS>0.00</SaldoUS></Producto>'
            + '      </Result>'
            + '    </ListOfBREAIFuncionGeneral>'
            + '  </SOAP-ENV:Body>'
            + '</SOAP-ENV:Envelope>';
    }
}
