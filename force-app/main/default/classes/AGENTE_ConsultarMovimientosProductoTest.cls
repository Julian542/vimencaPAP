@IsTest
private class AGENTE_ConsultarMovimientosProductoTest {

    private class MovimientosHttpMock implements HttpCalloutMock {
        private final String mode;
        public Integer callCount = 0;

        MovimientosHttpMock(String mode) {
            this.mode = mode;
        }

        public HttpResponse respond(HttpRequest req) {
            callCount++;

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml;charset=UTF-8');

            if (mode == 'SUCCESS_TC') {
                res.setStatusCode(200);
                res.setBody(buildTarjetaSuccessResponse(7));
            } else if (mode == 'SUCCESS_TC_2') {
                res.setStatusCode(200);
                res.setBody(buildTarjetaSuccessResponse(2));
            } else if (mode == 'EXPAND_THEN_SUCCESS') {
                res.setStatusCode(200);

                if (callCount == 1) {
                    res.setBody(buildNoMovementsResponse());
                } else {
                    res.setBody(buildTarjetaSuccessResponse(12));
                }
            } else if (mode == 'CORE_PAGED_SUCCESS') {
                res.setStatusCode(200);

                if (req.getBody() != null && req.getBody().contains('<IdPagination>P2</IdPagination>')) {
                    res.setBody(buildTarjetaPagedResponse(6, 12, '0'));
                } else {
                    res.setBody(buildTarjetaPagedResponse(1, 5, 'P2'));
                }
            } else if (mode == 'NO_MOVEMENTS') {
                res.setStatusCode(200);
                res.setBody(buildNoMovementsResponse());
            } else if (mode == 'HTTP_BODY_INVALID') {
                res.setStatusCode(200);
                res.setBody('<html>Error</html>');
            } else if (mode == 'CORE_ERROR') {
                res.setStatusCode(200);
                res.setBody(buildCoreErrorResponse('8888', 'ERROR SIMULADO DEL CORE'));
            } else if (mode == 'HTTP_500') {
                res.setStatusCode(500);
                res.setStatus('Internal Server Error');
                res.setBody('<html>Internal Server Error</html>');
            } else {
                res.setStatusCode(200);
                res.setBody(buildTarjetaSuccessResponse(2));
            }

            return res;
        }
    }

    @IsTest
    static void testConsultarMovimientosFlow_EmptyInputs() {
        Test.startTest();
        List<AGENTE_ConsultarMovimientosProducto.InvocableOutput> result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientosFlow(
                new List<AGENTE_ConsultarMovimientosProducto.InvocableInput>()
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('ERROR', result[0].status);
        System.assertEquals(0, result[0].displayedCount);
        System.assertEquals(false, result[0].hasBufferedMore);
        System.assertEquals(0, result[0].remainingCount);
        System.assertEquals('[]', result[0].transactionsJson);
    }

    @IsTest
    static void testConsultarMovimientosFlow_NullInputs() {
        Test.startTest();
        List<AGENTE_ConsultarMovimientosProducto.InvocableOutput> result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientosFlow(null);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('ERROR', result[0].status);
        System.assertEquals('[]', result[0].transactionsJson);
    }

    @IsTest
    static void testConsultarMovimientosFlow_FirstCall_Success_BufferedPagination() {
        Test.setMock(HttpCalloutMock.class, new MovimientosHttpMock('SUCCESS_TC'));

        AGENTE_ConsultarMovimientosProducto.InvocableInput input = buildBaseInput();

        Test.startTest();
        List<AGENTE_ConsultarMovimientosProducto.InvocableOutput> result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientosFlow(
                new List<AGENTE_ConsultarMovimientosProducto.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());

        AGENTE_ConsultarMovimientosProducto.InvocableOutput out = result[0];

        System.assertEquals('OK', out.status);
        System.assertEquals('Tarjeta ****1462 - VIGENTE', out.selectedProductLabel);
        System.assertEquals(5, out.displayedCount);
        System.assertEquals(true, out.hasBufferedMore);
        System.assertEquals(2, out.remainingCount);
        System.assertEquals(5, out.nextDisplayOffset);
        System.assertNotEquals(null, out.transactionsJson);
        System.assert(out.displayText.contains('Estos son los últimos movimientos'));
        System.assert(out.displayText.contains('puedo mostrarte 2 movimientos más'));
        System.assert(out.displayText.contains('Movimiento 7'));

        List<AGENTE_ConsultarMovimientosProducto.TransactionItem> txs =
            (List<AGENTE_ConsultarMovimientosProducto.TransactionItem>)
                JSON.deserialize(out.transactionsJson, List<AGENTE_ConsultarMovimientosProducto.TransactionItem>.class);

        System.assertEquals(7, txs.size());
        System.assertEquals('TX7', txs[0].reference);
        System.assertEquals('TX1', txs[6].reference);
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarMovimientosFlow_ExpandRangeUntilTenAndSortDesc() {
        MovimientosHttpMock mock = new MovimientosHttpMock('EXPAND_THEN_SUCCESS');
        Test.setMock(HttpCalloutMock.class, mock);

        AGENTE_ConsultarMovimientosProducto.InvocableInput input = buildBaseInput();

        Test.startTest();
        List<AGENTE_ConsultarMovimientosProducto.InvocableOutput> result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientosFlow(
                new List<AGENTE_ConsultarMovimientosProducto.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());

        AGENTE_ConsultarMovimientosProducto.InvocableOutput out = result[0];

        System.assertEquals('OK', out.status);
        System.assertEquals(5, out.displayedCount);
        System.assertEquals(true, out.hasBufferedMore);
        System.assertEquals(5, out.remainingCount);
        System.assertEquals(5, out.nextDisplayOffset);
        System.assert(mock.callCount >= 2);

        List<AGENTE_ConsultarMovimientosProducto.TransactionItem> txs =
            (List<AGENTE_ConsultarMovimientosProducto.TransactionItem>)
                JSON.deserialize(out.transactionsJson, List<AGENTE_ConsultarMovimientosProducto.TransactionItem>.class);

        System.assertEquals(10, txs.size());
        System.assertEquals('TX12', txs[0].reference);
        System.assertEquals('Movimiento 12', txs[0].description);
        System.assertEquals('TX3', txs[9].reference);
        System.assert(out.displayText.contains('Movimiento 12'));
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarMovimientosFlow_CorePagination_CollectsPagesAndReturnsLatestTen() {
        MovimientosHttpMock mock = new MovimientosHttpMock('CORE_PAGED_SUCCESS');
        Test.setMock(HttpCalloutMock.class, mock);

        AGENTE_ConsultarMovimientosProducto.InvocableInput input = buildBaseInput();

        Test.startTest();
        List<AGENTE_ConsultarMovimientosProducto.InvocableOutput> result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientosFlow(
                new List<AGENTE_ConsultarMovimientosProducto.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());

        AGENTE_ConsultarMovimientosProducto.InvocableOutput out = result[0];

        System.assertEquals('OK', out.status);
        System.assertEquals(5, out.displayedCount);
        System.assertEquals(true, out.hasBufferedMore);
        System.assertEquals(5, out.remainingCount);
        System.assertEquals(5, out.nextDisplayOffset);
        System.assertEquals(2, mock.callCount);

        List<AGENTE_ConsultarMovimientosProducto.TransactionItem> txs =
            (List<AGENTE_ConsultarMovimientosProducto.TransactionItem>)
                JSON.deserialize(out.transactionsJson, List<AGENTE_ConsultarMovimientosProducto.TransactionItem>.class);

        System.assertEquals(10, txs.size());
        System.assertEquals('TX12', txs[0].reference);
        System.assertEquals('TX3', txs[9].reference);
        System.assert(out.displayText.contains('Movimiento 12'));
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarMovimientosFlow_SecondCall_LocalPagination() {
        Test.setMock(HttpCalloutMock.class, new MovimientosHttpMock('SUCCESS_TC'));

        AGENTE_ConsultarMovimientosProducto.InvocableInput firstInput = buildBaseInput();

        Test.startTest();

        List<AGENTE_ConsultarMovimientosProducto.InvocableOutput> firstResult =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientosFlow(
                new List<AGENTE_ConsultarMovimientosProducto.InvocableInput>{ firstInput }
            );

        AGENTE_ConsultarMovimientosProducto.InvocableOutput firstOut = firstResult[0];

        System.assertEquals('OK', firstOut.status);
        System.assertEquals(2, firstOut.remainingCount);

        AGENTE_ConsultarMovimientosProducto.InvocableInput secondInput =
            new AGENTE_ConsultarMovimientosProducto.InvocableInput();

        secondInput.productsJson = buildProductsJson();
        secondInput.selectedOption = 'Tarjeta ****1462 - VIGENTE';
        secondInput.transactionsJson = firstOut.transactionsJson;
        secondInput.displayOffset = firstOut.nextDisplayOffset;
        secondInput.paginationId = '';
        secondInput.pageDirection = 'Proximo';
        secondInput.fromDate = '';
        secondInput.untilDate = '';

        List<AGENTE_ConsultarMovimientosProducto.InvocableOutput> secondResult =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientosFlow(
                new List<AGENTE_ConsultarMovimientosProducto.InvocableInput>{ secondInput }
            );

        Test.stopTest();

        AGENTE_ConsultarMovimientosProducto.InvocableOutput secondOut = secondResult[0];

        System.assertEquals('OK', secondOut.status);
        System.assertEquals(2, secondOut.displayedCount);
        System.assertEquals(false, secondOut.hasBufferedMore);
        System.assertEquals(0, secondOut.remainingCount);
        System.assert(!secondOut.displayText.contains('puedo mostrarte'));
    }

    @IsTest
    static void testConsultarMovimientosFlow_BufferedJson_OrdersDatesFromNewestToOldest() {
        List<AGENTE_ConsultarMovimientosProducto.TransactionItem> txs =
            new List<AGENTE_ConsultarMovimientosProducto.TransactionItem>();

        txs.add(buildTx('12/04/2026', 'Abril 12', 'REF_ABR_12'));
        txs.add(buildTx('12/02/2026', 'Febrero 12', 'REF_FEB_12'));
        txs.add(buildTx('11/04/2026', 'Abril 11', 'REF_ABR_11'));
        txs.add(buildTx('27/03/2026', 'Marzo 27', 'REF_MAR_27'));
        txs.add(buildTx('25/03/2026', 'Marzo 25', 'REF_MAR_25'));

        AGENTE_ConsultarMovimientosProducto.InvocableInput input =
            new AGENTE_ConsultarMovimientosProducto.InvocableInput();

        input.productsJson = buildProductsJson();
        input.selectedOption = 'Tarjeta ****1462 - VIGENTE';
        input.transactionsJson = JSON.serialize(txs);
        input.displayOffset = 0;
        input.paginationId = '';
        input.pageDirection = 'Proximo';
        input.fromDate = '';
        input.untilDate = '';

        Test.startTest();
        AGENTE_ConsultarMovimientosProducto.ServiceResponse result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientos(input);
        Test.stopTest();

        System.assertEquals('OK', result.status);
        System.assertEquals(5, result.displayedCount);
        System.assertEquals(0, result.remainingCount);
        System.assertEquals(false, result.hasBufferedMore);

        System.assertEquals('REF_ABR_12', result.transactions[0].reference);
        System.assertEquals('REF_ABR_11', result.transactions[1].reference);
        System.assertEquals('REF_MAR_27', result.transactions[2].reference);
        System.assertEquals('REF_MAR_25', result.transactions[3].reference);
        System.assertEquals('REF_FEB_12', result.transactions[4].reference);

        Integer posAbr12 = result.displayText.indexOf('12/04/2026');
        Integer posAbr11 = result.displayText.indexOf('11/04/2026');
        Integer posFeb12 = result.displayText.indexOf('12/02/2026');

        System.assert(posAbr12 >= 0);
        System.assert(posAbr11 > posAbr12);
        System.assert(posFeb12 > posAbr11);
    }

    @IsTest
    static void testConsultarMovimientosFlow_NoMovements9750_NoCreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new MovimientosHttpMock('NO_MOVEMENTS'));

        AGENTE_ConsultarMovimientosProducto.InvocableInput input = buildBaseInput();

        Test.startTest();
        List<AGENTE_ConsultarMovimientosProducto.InvocableOutput> result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientosFlow(
                new List<AGENTE_ConsultarMovimientosProducto.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('NO_MOVEMENTS', result[0].status);
        System.assert(result[0].displayText.contains('No tengo movimientos disponibles'));
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarMovimientosFlow_InvalidSelection() {
        AGENTE_ConsultarMovimientosProducto.InvocableInput input =
            new AGENTE_ConsultarMovimientosProducto.InvocableInput();

        input.productsJson = buildProductsJson();
        input.selectedOption = 'Producto inexistente';
        input.paginationId = '';
        input.pageDirection = 'Proximo';
        input.fromDate = '';
        input.untilDate = '';
        input.transactionsJson = '';
        input.displayOffset = 0;

        Test.startTest();
        List<AGENTE_ConsultarMovimientosProducto.InvocableOutput> result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientosFlow(
                new List<AGENTE_ConsultarMovimientosProducto.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('INVALID_SELECTION', result[0].status);
        System.assert(result[0].displayText.contains('No pude identificar el producto seleccionado'));
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarMovimientosFlow_SelectByNumericOption() {
        Test.setMock(HttpCalloutMock.class, new MovimientosHttpMock('SUCCESS_TC'));

        AGENTE_ConsultarMovimientosProducto.InvocableInput input = buildBaseInput();
        input.selectedOption = '1';

        Test.startTest();
        List<AGENTE_ConsultarMovimientosProducto.InvocableOutput> result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientosFlow(
                new List<AGENTE_ConsultarMovimientosProducto.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals('OK', result[0].status);
        System.assertEquals('Tarjeta ****1462 - VIGENTE', result[0].selectedProductLabel);
    }

    @IsTest
    static void testConsultarMovimientosFlow_SelectByProductKey() {
        Test.setMock(HttpCalloutMock.class, new MovimientosHttpMock('SUCCESS_TC'));

        String productsJson = buildProductsJson();

        List<AGENTE_ConsultarMovimientosProducto.ProductOptionLite> products =
            (List<AGENTE_ConsultarMovimientosProducto.ProductOptionLite>)
                JSON.deserialize(productsJson, List<AGENTE_ConsultarMovimientosProducto.ProductOptionLite>.class);

        AGENTE_ConsultarMovimientosProducto.InvocableInput input = buildBaseInput();
        input.productsJson = productsJson;
        input.selectedOption = products[0].productKey;

        Test.startTest();
        List<AGENTE_ConsultarMovimientosProducto.InvocableOutput> result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientosFlow(
                new List<AGENTE_ConsultarMovimientosProducto.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals('OK', result[0].status);
    }

    @IsTest
    static void testConsultarMovimientosFlow_Http200WithoutErrorCode_CreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new MovimientosHttpMock('HTTP_BODY_INVALID'));

        AGENTE_ConsultarMovimientosProducto.InvocableInput input = buildBaseInput();

        Test.startTest();
        List<AGENTE_ConsultarMovimientosProducto.InvocableOutput> result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientosFlow(
                new List<AGENTE_ConsultarMovimientosProducto.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals('ERROR', result[0].status);

        List<AgentLog__c> logs = [
            SELECT Id,
                   Status__c,
                   SourceClass__c,
                   IntegrationName__c,
                   Operation__c,
                   Endpoint__c,
                   HttpMethod__c,
                   HttpStatusCode__c,
                   ExternalErrorCode__c,
                   ErrorMessage__c,
                   RequestPayload__c,
                   ResponsePayload__c
            FROM AgentLog__c
            WHERE SourceClass__c = 'AGENTE_ConsultarMovimientosProducto'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(1, logs.size());
        System.assertEquals('Error', logs[0].Status__c);
        System.assertEquals('Core Bancario', logs[0].IntegrationName__c);
        System.assertEquals('ConsultaTransTC', logs[0].Operation__c);
        System.assertEquals('POST', logs[0].HttpMethod__c);
        System.assertEquals(200, logs[0].HttpStatusCode__c);
        System.assertEquals('INVALID_RESPONSE', logs[0].ExternalErrorCode__c);
        System.assert(logs[0].ErrorMessage__c.contains('no contiene ErrorCode'));
        System.assert(logs[0].RequestPayload__c.contains('<Password>***MASKED***</Password>'));
        System.assert(logs[0].RequestPayload__c.contains('<NumProduct>***MASKED***</NumProduct>'));
    }

    @IsTest
    static void testConsultarMovimientosFlow_CoreError_CreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new MovimientosHttpMock('CORE_ERROR'));

        AGENTE_ConsultarMovimientosProducto.InvocableInput input = buildBaseInput();

        Test.startTest();
        List<AGENTE_ConsultarMovimientosProducto.InvocableOutput> result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientosFlow(
                new List<AGENTE_ConsultarMovimientosProducto.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals('ERROR', result[0].status);
        System.assert(result[0].message.contains('8888'));

        List<AgentLog__c> logs = [
            SELECT Id,
                   Status__c,
                   SourceClass__c,
                   IntegrationName__c,
                   Operation__c,
                   HttpStatusCode__c,
                   ExternalErrorCode__c,
                   ErrorMessage__c,
                   ResponsePayload__c
            FROM AgentLog__c
            WHERE SourceClass__c = 'AGENTE_ConsultarMovimientosProducto'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(1, logs.size());
        System.assertEquals('Error', logs[0].Status__c);
        System.assertEquals('Core Bancario', logs[0].IntegrationName__c);
        System.assertEquals('ConsultaTransTC', logs[0].Operation__c);
        System.assertEquals(200, logs[0].HttpStatusCode__c);
        System.assertEquals('8888', logs[0].ExternalErrorCode__c);
        System.assert(logs[0].ErrorMessage__c.contains('ERROR SIMULADO DEL CORE'));
    }

    @IsTest
    static void testConsultarMovimientosFlow_Http500_CreaAgentLog() {
        Test.setMock(HttpCalloutMock.class, new MovimientosHttpMock('HTTP_500'));

        AGENTE_ConsultarMovimientosProducto.InvocableInput input = buildBaseInput();

        Test.startTest();
        List<AGENTE_ConsultarMovimientosProducto.InvocableOutput> result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientosFlow(
                new List<AGENTE_ConsultarMovimientosProducto.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals('ERROR', result[0].status);

        List<AgentLog__c> logs = [
            SELECT Id,
                   Status__c,
                   SourceClass__c,
                   IntegrationName__c,
                   Operation__c,
                   HttpStatusCode__c,
                   ExternalErrorCode__c,
                   ErrorMessage__c,
                   ResponsePayload__c
            FROM AgentLog__c
            WHERE SourceClass__c = 'AGENTE_ConsultarMovimientosProducto'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(1, logs.size());
        System.assertEquals('Error', logs[0].Status__c);
        System.assertEquals('Core Bancario', logs[0].IntegrationName__c);
        System.assertEquals('ConsultaTransTC', logs[0].Operation__c);
        System.assertEquals(500, logs[0].HttpStatusCode__c);
        System.assertEquals('HTTP_500', logs[0].ExternalErrorCode__c);
        System.assert(logs[0].ErrorMessage__c.contains('HTTP no exitoso'));
    }

    @IsTest
    static void testConsultarMovimientos_BufferOffsetGreaterThanSize() {
        List<AGENTE_ConsultarMovimientosProducto.TransactionItem> txs =
            new List<AGENTE_ConsultarMovimientosProducto.TransactionItem>();

        for (Integer i = 1; i <= 3; i++) {
            AGENTE_ConsultarMovimientosProducto.TransactionItem tx =
                new AGENTE_ConsultarMovimientosProducto.TransactionItem();

            tx.transactionDate = '0' + i + '/03/2026';
            tx.description = 'Movimiento ' + i;
            tx.amount = 'RD$ +' + i;
            tx.reference = 'REF' + i;
            txs.add(tx);
        }

        AGENTE_ConsultarMovimientosProducto.InvocableInput input =
            new AGENTE_ConsultarMovimientosProducto.InvocableInput();

        input.productsJson = buildProductsJson();
        input.selectedOption = 'Tarjeta ****1462 - VIGENTE';
        input.transactionsJson = JSON.serialize(txs);
        input.displayOffset = 99;
        input.paginationId = '';
        input.pageDirection = 'Proximo';
        input.fromDate = '';
        input.untilDate = '';

        Test.startTest();
        AGENTE_ConsultarMovimientosProducto.ServiceResponse result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientos(input);
        Test.stopTest();

        System.assertEquals('OK', result.status);
        System.assertEquals(0, result.displayedCount);
        System.assertEquals(0, result.remainingCount);
        System.assertEquals(false, result.hasBufferedMore);
    }

    @IsTest
    static void testConsultarMovimientosFlow_WithExplicitDates_IgnoresThemAndSearchesFromTodayBackwards() {
        Test.setMock(HttpCalloutMock.class, new MovimientosHttpMock('SUCCESS_TC'));

        AGENTE_ConsultarMovimientosProducto.InvocableInput input = buildBaseInput();
        input.fromDate = '18/12/2025';
        input.untilDate = '18/03/2026';

        Test.startTest();
        List<AGENTE_ConsultarMovimientosProducto.InvocableOutput> result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientosFlow(
                new List<AGENTE_ConsultarMovimientosProducto.InvocableInput>{ input }
            );
        Test.stopTest();

        System.assertEquals('OK', result[0].status);
        System.assertEquals(5, result[0].displayedCount);
    }

    @IsTest
    static void testConsultarMovimientosFlow_UnsupportedProductType() {
        AGENTE_ConsultarMovimientosProducto.ProductOptionLite p =
            new AGENTE_ConsultarMovimientosProducto.ProductOptionLite();

        p.productKey = 'abc';
        p.displayLabel = 'Producto raro';
        p.integrationProductNumber = '123';
        p.integrationProductType = 'Producto no soportado';
        p.currencyCode = 'DOP';

        AGENTE_ConsultarMovimientosProducto.InvocableInput input =
            new AGENTE_ConsultarMovimientosProducto.InvocableInput();

        input.productsJson = JSON.serialize(
            new List<AGENTE_ConsultarMovimientosProducto.ProductOptionLite>{ p }
        );

        input.selectedOption = 'Producto raro';
        input.paginationId = '';
        input.pageDirection = 'Proximo';
        input.fromDate = '';
        input.untilDate = '';
        input.transactionsJson = '';
        input.displayOffset = 0;

        Test.startTest();
        AGENTE_ConsultarMovimientosProducto.ServiceResponse result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientos(input);
        Test.stopTest();

        System.assertEquals('INVALID_SELECTION', result.status);
        System.assertEquals(0, [SELECT COUNT() FROM AgentLog__c]);
    }

    @IsTest
    static void testConsultarMovimientosFlow_BufferedJsonSingleItem() {
        List<AGENTE_ConsultarMovimientosProducto.TransactionItem> txs =
            new List<AGENTE_ConsultarMovimientosProducto.TransactionItem>();

        AGENTE_ConsultarMovimientosProducto.TransactionItem tx =
            new AGENTE_ConsultarMovimientosProducto.TransactionItem();

        tx.transactionDate = '18/03/2026';
        tx.description = 'Movimiento único';
        tx.amount = 'RD$ +1,000.00';
        tx.reference = 'REF1';
        txs.add(tx);

        AGENTE_ConsultarMovimientosProducto.InvocableInput input =
            new AGENTE_ConsultarMovimientosProducto.InvocableInput();

        input.productsJson = buildProductsJson();
        input.selectedOption = 'Tarjeta ****1462 - VIGENTE';
        input.transactionsJson = JSON.serialize(txs);
        input.displayOffset = 0;
        input.paginationId = '';
        input.pageDirection = 'Proximo';
        input.fromDate = '';
        input.untilDate = '';

        Test.startTest();
        AGENTE_ConsultarMovimientosProducto.ServiceResponse result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientos(input);
        Test.stopTest();

        System.assertEquals('OK', result.status);
        System.assertEquals(1, result.displayedCount);
        System.assertEquals(0, result.remainingCount);
        System.assertEquals(false, result.hasBufferedMore);
    }

    @IsTest
    static void testConsultarMovimientosFlow_NullInputObject() {
        Test.startTest();
        AGENTE_ConsultarMovimientosProducto.ServiceResponse result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientos(null);
        Test.stopTest();

        System.assertEquals('INVALID_SELECTION', result.status);
        System.assert(result.displayText.contains('No pude identificar el producto seleccionado'));
    }

    @IsTest
    static void testConsultarMovimientosFlow_BlankProductsJson() {
        AGENTE_ConsultarMovimientosProducto.InvocableInput input =
            new AGENTE_ConsultarMovimientosProducto.InvocableInput();

        input.productsJson = '';
        input.selectedOption = 'Tarjeta ****1462 - VIGENTE';

        Test.startTest();
        AGENTE_ConsultarMovimientosProducto.ServiceResponse result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientos(input);
        Test.stopTest();

        System.assertEquals('INVALID_SELECTION', result.status);
        System.assert(result.displayText.contains('No pude identificar el producto seleccionado'));
    }

    @IsTest
    static void testConsultarMovimientosFlow_BlankSelectedOption() {
        AGENTE_ConsultarMovimientosProducto.InvocableInput input =
            new AGENTE_ConsultarMovimientosProducto.InvocableInput();

        input.productsJson = buildProductsJson();
        input.selectedOption = '';

        Test.startTest();
        AGENTE_ConsultarMovimientosProducto.ServiceResponse result =
            AGENTE_ConsultarMovimientosProducto.consultarMovimientos(input);
        Test.stopTest();

        System.assertEquals('INVALID_SELECTION', result.status);
        System.assert(result.displayText.contains('No pude identificar el producto seleccionado'));
    }

    @IsTest
    static void testCoreResponseParsesSavingsLoansAndPrepaidProducts() {
        String successfulResponse =
            '<ErrorCode>000</ErrorCode><ErrorText></ErrorText><Response>' +
            '<FechaTransaccion>18/03/2026</FechaTransaccion>' +
            '<IdPagAnt>PREV</IdPagAnt><IdPagProx>NEXT</IdPagProx>' +
            '<UltimaPagina>0</UltimaPagina><Valor>100.00</Valor></Response>';

        AGENTE_ConsultarMovimientosProducto.CoreResponse savings =
            new AGENTE_ConsultarMovimientosProducto.CoreResponse();
        savings.parse('cuentas de ahorro', successfulResponse);

        AGENTE_ConsultarMovimientosProducto.CoreResponse loan =
            new AGENTE_ConsultarMovimientosProducto.CoreResponse();
        loan.parse('prestamos', successfulResponse);

        AGENTE_ConsultarMovimientosProducto.CoreResponse prepaid =
            new AGENTE_ConsultarMovimientosProducto.CoreResponse();
        prepaid.parse('tarjetas prepago', successfulResponse);

        System.assertEquals(1, savings.responseList.size());
        System.assertEquals(1, loan.responseList.size());
        System.assertEquals(1, prepaid.responseList.size());
        System.assertEquals('NEXT', savings.idPagProx);
        System.assertEquals('NEXT', loan.idPagProx);
        System.assertEquals('NEXT', prepaid.idPagProx);

        Boolean unsupportedRejected = false;
        try {
            new AGENTE_ConsultarMovimientosProducto.CoreResponse().parse('Producto no configurado', '');
        } catch (AuraHandledException expected) {
            unsupportedRejected = true;
        }
        System.assert(unsupportedRejected);
    }

    private static AGENTE_ConsultarMovimientosProducto.InvocableInput buildBaseInput() {
        AGENTE_ConsultarMovimientosProducto.testRequestFrameOverride = buildRequestFrame();

        AGENTE_ConsultarMovimientosProducto.InvocableInput input =
            new AGENTE_ConsultarMovimientosProducto.InvocableInput();

        input.productsJson = buildProductsJson();
        input.selectedOption = 'Tarjeta ****1462 - VIGENTE';
        input.paginationId = '';
        input.pageDirection = 'Proximo';
        input.fromDate = '';
        input.untilDate = '';
        input.transactionsJson = '';
        input.displayOffset = 0;

        return input;
    }

    private static String buildProductsJson() {
        List<AGENTE_ConsultarMovimientosProducto.ProductOptionLite> products =
            new List<AGENTE_ConsultarMovimientosProducto.ProductOptionLite>();

        AGENTE_ConsultarMovimientosProducto.ProductOptionLite p =
            new AGENTE_ConsultarMovimientosProducto.ProductOptionLite();

        p.productKey = EncodingUtil.base64Encode(
            Blob.valueOf('4593820000051462|TC|Tarjetas de crédito')
        );

        p.productCode = 'TC';
        p.productType = 'Tarjeta';
        p.lineDescription = 'Tarjetas de crédito';
        p.accountNumberMasked = '****1462';
        p.accountNumberRaw = '4593820000051462';
        p.ownershipType = 'Principal';
        p.status = 'VIGENTE';
        p.holderName = 'Cliente Test';
        p.eligibleForTransactions = true;
        p.displayLabel = 'Tarjeta ****1462 - VIGENTE';
        p.integrationProductNumber = '4593820000051462';
        p.integrationProductType = 'Tarjetas de crédito';
        p.currencyCode = 'DOP';

        products.add(p);

        return JSON.serialize(products);
    }

    private static AGENTE_ConsultarMovimientosProducto.TransactionItem buildTx(String dateValue, String description, String reference) {
        AGENTE_ConsultarMovimientosProducto.TransactionItem tx =
            new AGENTE_ConsultarMovimientosProducto.TransactionItem();

        tx.transactionDate = dateValue;
        tx.description = description;
        tx.amount = 'RD$ +1,000.00';
        tx.rawAmount = '1000.00';
        tx.creditDebit = 'Crédito';
        tx.reference = reference;

        return tx;
    }

    private static String buildRequestFrame() {
        return ''
            + '<Envelope>'
            + '  <Header>'
            + '    <Username>[ws_user]</Username>'
            + '    <Password>[ws_password]</Password>'
            + '  </Header>'
            + '  <Body>'
            + '    <Function>[function_processIntegration]</Function>'
            + '    <FunctionUsername>[function_username]</FunctionUsername>'
            + '    <RequestDate>[function_requestdate]</RequestDate>'
            + '    <RequestTime>[function_requesttime]</RequestTime>'
            + '    <Terminal>[function_terminal]</Terminal>'
            + '    <FromDate>[function_fromDate]</FromDate>'
            + '    <UntilDate>[function_untilDate]</UntilDate>'
            + '    <State>[function_state]</State>'
            + '    <MinimumAmount>[function_minimunAmount]</MinimumAmount>'
            + '    <MaximumAmount>[function_maxAmount]</MaximumAmount>'
            + '    <CreditDebit>[function_credirDebit]</CreditDebit>'
            + '    <DocumentNumber>[function_documentNumber]</DocumentNumber>'
            + '    <IdPagination>[function_idPagination]</IdPagination>'
            + '    <Pagination>[function_pagination]</Pagination>'
            + '    <NumProduct>[function_numProduct]</NumProduct>'
            + '    <ProductType>[function_productType]</ProductType>'
            + '    <Currency>[function_currency]</Currency>'
            + '  </Body>'
            + '</Envelope>';
    }

    private static String buildNoMovementsResponse() {
        return ''
            + '<?xml version="1.0" encoding="utf-8"?>'
            + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
            + '  <soap:Body>'
            + '    <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Transacciones%20TC%20Response%20IO">'
            + '      <Result>'
            + '        <ErrorCode>9750</ErrorCode>'
            + '        <ErrorText>NO EXISTE DATOS PARA ESTA CONSULTA</ErrorText>'
            + '      </Result>'
            + '    </ListOfBREAIFuncionGeneral>'
            + '  </soap:Body>'
            + '</soap:Envelope>';
    }

    private static String buildCoreErrorResponse(String errorCode, String errorText) {
        return ''
            + '<?xml version="1.0" encoding="utf-8"?>'
            + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
            + '  <soap:Body>'
            + '    <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Transacciones%20TC%20Response%20IO">'
            + '      <Result>'
            + '        <ErrorCode>' + errorCode + '</ErrorCode>'
            + '        <ErrorText>' + errorText + '</ErrorText>'
            + '      </Result>'
            + '    </ListOfBREAIFuncionGeneral>'
            + '  </soap:Body>'
            + '</soap:Envelope>';
    }

    private static String buildTarjetaSuccessResponse(Integer countRows) {
        return buildTarjetaPagedResponse(1, countRows, '0');
    }

    private static String buildTarjetaPagedResponse(Integer startIndex, Integer endIndex, String idPagProx) {
        String body = ''
            + '<?xml version="1.0" encoding="utf-8"?>'
            + '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
            + '  <soap:Body>'
            + '    <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Transacciones%20TC%20Response%20IO">'
            + '      <Result>'
            + '        <ErrorCode>000</ErrorCode>'
            + '        <ErrorText>TRANSACCION PROCESADA</ErrorText>';

        for (Integer i = startIndex; i <= endIndex; i++) {
            String amount = String.valueOf(1000 * i) + '.00';
            String creditDebit = Math.mod(i, 2) == 0 ? 'Débito' : 'Crédito';

            body += ''
                + '        <Response>'
                + '          <OficinaOrigen></OficinaOrigen>'
                + '          <NumTarjeta>4593820000051462</NumTarjeta>'
                + '          <NumTransaccion>TX' + i + '</NumTransaccion>'
                + '          <FechaTransaccion>03/' + pad2(i) + '/2026</FechaTransaccion>'
                + '          <FechaCompra></FechaCompra>'
                + '          <MontoOriginal>' + amount + '</MontoOriginal>'
                + '          <MontoLocal>' + amount + '</MontoLocal>'
                + '          <CodTransaccion>0</CodTransaccion>'
                + '          <CanalPago></CanalPago>'
                + '          <Ciudad>Santo Domingo</Ciudad>'
                + '          <Pais>Dominican Rep.</Pais>'
                + '          <TipoRespuesta></TipoRespuesta>'
                + '          <EstadoConsumo></EstadoConsumo>'
                + '          <CreditoDebito>' + creditDebit + '</CreditoDebito>'
                + '          <Descripcion>Movimiento ' + i + '</Descripcion>'
                + '          <Estado>Procesadas</Estado>'
                + '          <Moneda>DOP</Moneda>'
                + '          <NumDocumento>DOC' + i + '</NumDocumento>'
                + '          <IdPagAnt>0</IdPagAnt>'
                + '          <IdPagProx>' + idPagProx + '</IdPagProx>'
                + '          <UltimaPagina>' + (idPagProx == '0' ? 'Y' : 'N') + '</UltimaPagina>'
                + '        </Response>';
        }

        body += ''
            + '      </Result>'
            + '    </ListOfBREAIFuncionGeneral>'
            + '  </soap:Body>'
            + '</soap:Envelope>';

        return body;
    }

    private static String pad2(Integer value) {
        return value < 10 ? '0' + String.valueOf(value) : String.valueOf(value);
    }
}
