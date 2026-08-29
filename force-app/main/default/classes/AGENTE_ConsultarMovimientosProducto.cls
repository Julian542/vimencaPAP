public with sharing class AGENTE_ConsultarMovimientosProducto {

    private static HttpRequest requestInfo;
    private static final Integer MAX_BUFFERED_TRANSACTIONS = 10;
    private static final Integer PAGE_SIZE = 5;
    private static final Integer AGENT_LOG_TEXT_LIMIT = 32000;

    @TestVisible
    private static String testRequestFrameOverride;

    public class ProductOptionLite {
        public String productKey;
        public String productCode;
        public String productType;
        public String lineDescription;
        public String accountNumberMasked;
        public String accountNumberRaw;
        public String ownershipType;
        public String status;
        public String holderName;
        public Boolean eligibleForTransactions;
        public String displayLabel;

        public String integrationProductNumber;
        public String integrationProductType;
        public String currencyCode;
    }

    public class TransactionItem {
        public String transactionDate;
        public String description;
        public String amount;
        public String rawAmount;
        public String creditDebit;
        public String reference;
    }

    public class ServiceResponse {
        public String status;
        public String message;
        public String displayText;
        public String selectedProductLabel;
        public Boolean hasMore;
        public String nextPaginationId;
        public Integer displayedCount;
        public List<TransactionItem> transactions;

        public Integer nextDisplayOffset;
        public Boolean hasBufferedMore;
        public Integer remainingCount;

        public ServiceResponse() {
            transactions = new List<TransactionItem>();
            hasMore = false;
            displayedCount = 0;
            nextDisplayOffset = 0;
            hasBufferedMore = false;
            remainingCount = 0;
        }
    }

    public class InvocableInput {
        @InvocableVariable(required=true)
        public String productsJson;

        @InvocableVariable(required=true)
        public String selectedOption;

        @InvocableVariable(required=false)
        public String paginationId;

        @InvocableVariable(required=false)
        public String pageDirection;

        @InvocableVariable(required=false)
        public String fromDate;

        @InvocableVariable(required=false)
        public String untilDate;

        @InvocableVariable(required=false)
        public String transactionsJson;

        @InvocableVariable(required=false)
        public Integer displayOffset;

        @InvocableVariable(required=false)
        public String messagingSessionId;
    }

    public class InvocableOutput {
        @InvocableVariable public String status;
        @InvocableVariable public String message;
        @InvocableVariable public String displayText;
        @InvocableVariable public String transactionsJson;
        @InvocableVariable public String selectedProductLabel;
        @InvocableVariable public Boolean hasMore;
        @InvocableVariable public String nextPaginationId;
        @InvocableVariable public Integer displayedCount;
        @InvocableVariable public Integer nextDisplayOffset;
        @InvocableVariable public Boolean hasBufferedMore;
        @InvocableVariable public Integer remainingCount;
    }

    public class CoreResponse {
        public String errorCode;
        public String errorText;
        public Boolean successTimeout = true;
        public List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        public String idPagProx;
        public String idPagAnt;
        public String ultimaPagina;
        public List<String> fields;

        public Map<String, String> functionsXml = new Map<String, String>{
            'cuentas de ahorro' => 'ConsultaTransCtas',
            'cuentas corrientes' => 'ConsultaTransCtas',
            'tarjetas de crédito' => 'ConsultaTransTC',
            'tarjetas de credito' => 'ConsultaTransTC',
            'certificados financieros' => 'ConsultaTransCF',
            'préstamos' => 'ConsultaTransPrest',
            'prestamos' => 'ConsultaTransPrest',
            'tarjetas prepago' => 'ConsultaTransCtas'
        };

        public void parse(String functionName, String responseBody) {
            String normalizedFunctionName = String.isBlank(functionName) ? '' : functionName.trim().toLowerCase();

            switch on normalizedFunctionName {
                when 'cuentas de ahorro', 'cuentas corrientes' {
                    fields = new List<String>{
                        'CO','CodCausal','CodTransaccion','CreditoDebito','DescTransaccion','Documento','Estado',
                        'FechaFinal','FechaInicial','FechaProceso','FechaTransaccion','Hora','IdPagAnt','IdPagProx',
                        'MontoMaximo','MontoMinimo','NumDocumento','Oficina','Referencia','Terminal','TipoDeposito','Valor'
                    };
                    parseCase(responseBody);
                }
                when 'préstamos', 'prestamos' {
                    fields = new List<String>{
                        'CodigoTransaccion','Valor','Usuario','TotalPagado','TotalFacturado','TipoMovimiento','Terminal',
                        'TasaMora','TasaInteres','TasaComision','Saldo','SUP','Oficina','NumFactura','NumDocumento',
                        'Documento','Mora','MontoTotal','MontoInteres','MontoCapital','VencimientoFactura',
                        'FechaTransaccion','FechaFinal','FechaInicial','MontoMaximo','MontoMinimo','FechaPagoFactura',
                        'Evento','Estado','DiasAtrasos','DetalleFactura','Descripcion','CreditoDebito','Comision',
                        'CodigoCausal','IdPagAnt','IdPagProx','UltimaPagina'
                    };
                    parseCase(responseBody);
                }
                when 'tarjetas de crédito', 'tarjetas de credito' {
                    fields = new List<String>{
                        'CanalPago','Pais','OficinaOrigen','NumTransaccion','NumTarjeta','NumDocumento','Documento',
                        'MontoOriginal','MontoLocal','MontoMaximo','MontoMinimo','FechaTransaccion','FechaCompra',
                        'FechaFinal','FechaInicial','EstadoConsumo','Estado','Descripcion','Moneda','CreditoDebito',
                        'CodTransaccion','Ciudad','TipoRespuesta','TipoTransaccion','IdPagAnt','IdPagProx','UltimaPagina'
                    };
                    parseCase(responseBody);
                }
                when 'tarjetas prepago' {
                    fields = new List<String>{
                        'CodCausa', 'CodTransaccion', 'CreditoDebito', 'DescTransaccion', 'Estado', 'FechaProceso',
                        'FechaTransaccion', 'NumDocumento', 'Oficina', 'Referencia', 'Terminal', 'TipoDeposito',
                        'Valor', 'IdPagAnt', 'IdPagProx', 'UltimaPagina'
                    };
                    parseCase(responseBody);
                }
                when else {
                    throw new AuraHandledException('El tipo de producto no tiene una integración de movimientos configurada.');
                }
            }
        }

        private void parseCase(String responseBody) {
            Map<String, Object> row;
            errorCode = extractTagValue(responseBody, 'ErrorCode');
            errorText = extractTagValue(responseBody, 'ErrorText');

            if (errorCode != '000' && errorCode != '9750') {
                return;
            }

            String remaining = responseBody;

            while (remaining.contains('</Response>')) {
                String block = remaining.substringBefore('</Response>');
                row = new Map<String, Object>();

                for (String fieldName : fields) {
                    row.put(fieldName, extractTagValue(block, fieldName));
                }

                if (String.isBlank(idPagProx)) {
                    idPagProx = String.valueOf(row.get('IdPagProx'));
                }
                if (String.isBlank(idPagAnt)) {
                    idPagAnt = String.valueOf(row.get('IdPagAnt'));
                }
                if (String.isBlank(ultimaPagina)) {
                    ultimaPagina = String.valueOf(row.get('UltimaPagina'));
                }

                responseList.add(row);
                remaining = remaining.substringAfter('</Response>');
            }
        }

        private String extractTagValue(String source, String tagName) {
            if (String.isBlank(source) || String.isBlank(tagName)) {
                return '';
            }

            String openTag = '<' + tagName + '>';
            String closeTag = '</' + tagName + '>';

            if (!source.contains(openTag) || !source.contains(closeTag)) {
                return '';
            }

            return source.substringAfter(openTag).substringBefore(closeTag);
        }
    }

    @InvocableMethod(label='Consultar movimientos del producto' description='Consulta los ultimos movimientos del producto seleccionado por el cliente')
    public static List<InvocableOutput> consultarMovimientosFlow(List<InvocableInput> inputs) {
        List<InvocableOutput> outputs = new List<InvocableOutput>();

        if (inputs == null || inputs.isEmpty()) {
            InvocableOutput out = new InvocableOutput();
            out.status = 'ERROR';
            out.message = 'No se recibió información de entrada.';
            out.displayText = 'No fue posible consultar los movimientos en este momento.';
            out.transactionsJson = '[]';
            out.hasMore = false;
            out.nextPaginationId = '';
            out.displayedCount = 0;
            out.nextDisplayOffset = 0;
            out.hasBufferedMore = false;
            out.remainingCount = 0;
            outputs.add(out);
            return outputs;
        }

        for (InvocableInput input : inputs) {
            ServiceResponse service = consultarMovimientos(input);

            InvocableOutput out = new InvocableOutput();
            out.status = service.status;
            out.message = service.message;
            out.displayText = service.displayText;
            out.transactionsJson = JSON.serialize(service.transactions);
            out.selectedProductLabel = service.selectedProductLabel;
            out.hasMore = service.hasMore;
            out.nextPaginationId = service.nextPaginationId;
            out.displayedCount = service.displayedCount;
            out.nextDisplayOffset = service.nextDisplayOffset;
            out.hasBufferedMore = service.hasBufferedMore;
            out.remainingCount = service.remainingCount;

            outputs.add(out);
        }

        return outputs;
    }

    public static ServiceResponse consultarMovimientos(InvocableInput input) {
        ServiceResponse output = new ServiceResponse();

        try {
            validateInput(input);

            List<ProductOptionLite> products = parseProducts(input.productsJson);
            ProductOptionLite selectedProduct = resolveSelectedProduct(products, input.selectedOption);
            output.selectedProductLabel = selectedProduct.displayLabel;

            Integer offset = input.displayOffset == null ? 0 : input.displayOffset;

            if (!String.isBlank(input.transactionsJson) && input.transactionsJson != '[]') {
                List<TransactionItem> bufferedTransactions = parseBufferedTransactions(input.transactionsJson);
                sortTransactionsByDateDesc(bufferedTransactions);

                if (bufferedTransactions.isEmpty()) {
                    output.status = 'NO_MOVEMENTS';
                    output.message = 'No se encontraron movimientos recientes para el producto seleccionado.';
                    output.displayText = buildNoMovementsText(selectedProduct);
                    return output;
                }

                applyLocalPagination(output, selectedProduct, bufferedTransactions, offset);
                return output;
            }

            CoreResponse core = executeCoreRequestWithExpandedRange(selectedProduct, input);

            if (!core.successTimeout) {
                output.status = 'ERROR';
                output.message = 'No fue posible obtener respuesta válida del servicio de movimientos.';
                output.displayText = buildGenericUnavailableText(selectedProduct);
                return output;
            }

            if (core.errorCode == '9750') {
                output.status = 'NO_MOVEMENTS';
                output.message = 'No se encontraron movimientos para el rango consultado.';
                output.displayText = buildNoMovementsText(selectedProduct);
                return output;
            }

            if (String.isBlank(core.errorCode) || core.errorCode != '000') {
                output.status = 'ERROR';
                output.message = 'La integración de movimientos devolvió error. Código: '
                    + core.errorCode + '. Mensaje: ' + core.errorText;
                output.displayText = buildGenericUnavailableText(selectedProduct);
                return output;
            }

            List<TransactionItem> normalized = normalizeTransactions(core.responseList, selectedProduct);
            sortTransactionsByDateDesc(normalized);

            if (normalized == null || normalized.isEmpty()) {
                output.status = 'NO_MOVEMENTS';
                output.message = 'La consulta fue exitosa, pero no devolvió movimientos utilizables.';
                output.displayText = buildNoMovementsText(selectedProduct);
                return output;
            }

            List<TransactionItem> buffered = new List<TransactionItem>();
            Integer maxToBuffer = Math.min(MAX_BUFFERED_TRANSACTIONS, normalized.size());

            for (Integer i = 0; i < maxToBuffer; i++) {
                buffered.add(normalized[i]);
            }

            applyLocalPagination(output, selectedProduct, buffered, 0);
            output.nextPaginationId = '';
            output.hasMore = false;

            return output;

        } catch (AuraHandledException ahe) {
            output.status = 'INVALID_SELECTION';
            output.message = ahe.getMessage();
            output.displayText = 'No pude identificar el producto seleccionado. Por favor, selecciona una opción válida de la lista.';
            return output;

        } catch (Exception e) {
            output.status = 'ERROR';
            output.message = 'Ocurrió un error al consultar los movimientos: ' + e.getMessage();
            output.displayText = 'No fue posible consultar los movimientos del producto seleccionado por este canal en este momento.';
            return output;
        }
    }

    private static void applyLocalPagination(ServiceResponse output, ProductOptionLite selectedProduct, List<TransactionItem> bufferedTransactions, Integer offset) {
        Integer safeOffset = offset == null ? 0 : offset;

        if (safeOffset < 0) {
            safeOffset = 0;
        }

        if (safeOffset > bufferedTransactions.size()) {
            safeOffset = bufferedTransactions.size();
        }

        Integer endExclusive = Math.min(safeOffset + PAGE_SIZE, bufferedTransactions.size());
        List<TransactionItem> page = new List<TransactionItem>();

        for (Integer i = safeOffset; i < endExclusive; i++) {
            page.add(bufferedTransactions[i]);
        }

        output.transactions = bufferedTransactions;
        output.displayedCount = page.size();
        output.nextDisplayOffset = endExclusive;
        output.remainingCount = Math.max(0, bufferedTransactions.size() - endExclusive);
        output.hasBufferedMore = output.remainingCount > 0;
        output.status = 'OK';
        output.message = 'Movimientos obtenidos correctamente.';
        output.displayText = buildDisplayText(selectedProduct, page, output.remainingCount);
    }

    private static List<TransactionItem> parseBufferedTransactions(String transactionsJson) {
        List<TransactionItem> items = (List<TransactionItem>) JSON.deserialize(transactionsJson, List<TransactionItem>.class);
        return items == null ? new List<TransactionItem>() : items;
    }

    private static void validateInput(InvocableInput input) {
        if (input == null) {
            throw new AuraHandledException('La solicitud está vacía.');
        }

        if (String.isBlank(input.productsJson)) {
            throw new AuraHandledException('No se recibió el listado de productos.');
        }

        if (String.isBlank(input.selectedOption)) {
            throw new AuraHandledException('No se recibió la selección del producto.');
        }
    }

    private static List<ProductOptionLite> parseProducts(String productsJson) {
        List<ProductOptionLite> products = (List<ProductOptionLite>) JSON.deserialize(productsJson, List<ProductOptionLite>.class);

        if (products == null || products.isEmpty()) {
            throw new AuraHandledException('No hay productos disponibles para seleccionar.');
        }

        return products;
    }

    private static ProductOptionLite resolveSelectedProduct(List<ProductOptionLite> products, String selectedOption) {
        String option = String.isBlank(selectedOption) ? '' : selectedOption.trim();

        if (String.isBlank(option)) {
            throw new AuraHandledException('No se recibió una opción seleccionada.');
        }

        for (ProductOptionLite product : products) {
            if (product != null && !String.isBlank(product.displayLabel) && product.displayLabel == option) {
                return product;
            }
        }

        String normalizedOption = normalizeSelection(option);

        for (ProductOptionLite product : products) {
            if (product != null && normalizeSelection(product.displayLabel) == normalizedOption) {
                return product;
            }
        }

        for (ProductOptionLite product : products) {
            if (product != null && !String.isBlank(product.productKey) && product.productKey == option) {
                return product;
            }
        }

        Integer selectedIndex = extractSelectedIndex(option);

        if (selectedIndex != null && selectedIndex > 0 && selectedIndex <= products.size()) {
            return products[selectedIndex - 1];
        }

        throw new AuraHandledException('No pude identificar el producto seleccionado.');
    }

    private static Integer extractSelectedIndex(String selectedOption) {
        if (String.isBlank(selectedOption)) {
            return null;
        }

        String trimmed = selectedOption.trim();

        if (isNumeric(trimmed)) {
            return Integer.valueOf(trimmed);
        }

        String digits = '';

        for (Integer i = 0; i < trimmed.length(); i++) {
            String c = trimmed.substring(i, i + 1);

            if (c >= '0' && c <= '9') {
                digits += c;
            } else if (!String.isBlank(digits)) {
                break;
            }
        }

        if (String.isBlank(digits)) {
            return null;
        }

        try {
            Integer index = Integer.valueOf(digits);

            if (index <= 0) {
                return null;
            }

            if (index <= 20) {
                return index;
            }

            return null;
        } catch (Exception e) {
            return null;
        }
    }

    private static Boolean isNumeric(String value) {
        if (String.isBlank(value)) {
            return false;
        }

        for (Integer i = 0; i < value.length(); i++) {
            String c = value.substring(i, i + 1);

            if (c < '0' || c > '9') {
                return false;
            }
        }

        return true;
    }

    private static String normalizeSelection(String value) {
        if (String.isBlank(value)) {
            return '';
        }

        String normalized = value.trim().toLowerCase();
        normalized = normalized.replace('á', 'a');
        normalized = normalized.replace('é', 'e');
        normalized = normalized.replace('í', 'i');
        normalized = normalized.replace('ó', 'o');
        normalized = normalized.replace('ú', 'u');
        normalized = normalized.replaceAll('\\s+', ' ');
        return normalized;
    }

    private static CoreResponse executeCoreRequestWithExpandedRange(ProductOptionLite selectedProduct, InvocableInput input) {
        List<Integer> dayRanges = new List<Integer>{ 30, 90, 180, 365, 730, 1095, 1825, 3650 };
        CoreResponse bestResponse;

        String untilDate = coreDateToday();

        for (Integer daysBack : dayRanges) {
            InvocableInput rangedInput = cloneInputForDateRange(
                input,
                coreDateDaysAgo(daysBack),
                untilDate
            );

            CoreResponse current = executeCoreRequestCollectingPages(selectedProduct, rangedInput, false);

            if (!current.successTimeout) {
                return current;
            }

            if (String.isBlank(current.errorCode) || (current.errorCode != '000' && current.errorCode != '9750')) {
                return current;
            }

            if (current.errorCode == '000' && current.responseList != null && !current.responseList.isEmpty()) {
                bestResponse = current;

                if (current.responseList.size() >= MAX_BUFFERED_TRANSACTIONS) {
                    return current;
                }
            } else if (bestResponse == null) {
                bestResponse = current;
            }
        }

        return bestResponse == null ? executeCoreRequestCollectingPages(selectedProduct, input, false) : bestResponse;
    }

    private static CoreResponse executeCoreRequestCollectingPages(
        ProductOptionLite selectedProduct,
        InvocableInput input,
        Boolean writeIntegrationLog
    ) {
        CoreResponse aggregate = executeCoreRequest(selectedProduct, input, writeIntegrationLog);

        if (!aggregate.successTimeout) {
            return aggregate;
        }

        if (String.isBlank(aggregate.errorCode) || aggregate.errorCode != '000') {
            return aggregate;
        }

        Integer safetyCounter = 0;
        String nextPaginationId = aggregate.idPagProx;

        while (hasNextCorePage(nextPaginationId) && safetyCounter < 20) {
            safetyCounter++;

            InvocableInput nextInput = cloneInputForDateRange(
                input,
                input.fromDate,
                input.untilDate
            );

            nextInput.paginationId = nextPaginationId;
            nextInput.pageDirection = 'Proximo';

            CoreResponse nextPage = executeCoreRequest(selectedProduct, nextInput, false);

            if (!nextPage.successTimeout) {
                return nextPage;
            }

            if (String.isBlank(nextPage.errorCode) || (nextPage.errorCode != '000' && nextPage.errorCode != '9750')) {
                return nextPage;
            }

            if (nextPage.errorCode == '9750') {
                break;
            }

            if (nextPage.responseList != null && !nextPage.responseList.isEmpty()) {
                aggregate.responseList.addAll(nextPage.responseList);
            }

            if (String.isBlank(nextPage.idPagProx) || nextPage.idPagProx == nextPaginationId) {
                break;
            }

            nextPaginationId = nextPage.idPagProx;
        }

        return aggregate;
    }

    private static Boolean hasNextCorePage(String paginationId) {
        if (String.isBlank(paginationId)) {
            return false;
        }

        String value = paginationId.trim();

        return value != '0'
            && value != '-1'
            && value.toLowerCase() != 'null';
    }

    private static InvocableInput cloneInputForDateRange(InvocableInput source, String fromDate, String untilDate) {
        InvocableInput clone = new InvocableInput();

        clone.productsJson = source.productsJson;
        clone.selectedOption = source.selectedOption;
        clone.paginationId = source.paginationId;
        clone.pageDirection = source.pageDirection;
        clone.fromDate = fromDate;
        clone.untilDate = untilDate;
        clone.transactionsJson = source.transactionsJson;
        clone.displayOffset = source.displayOffset;
        clone.messagingSessionId = source.messagingSessionId;

        return clone;
    }

    private static String coreDateToday() {
        return Datetime.now().format('MM/dd/yyyy');
    }

    private static String coreDateDaysAgo(Integer daysAgo) {
        return Datetime.now().addDays(-daysAgo).format('MM/dd/yyyy');
    }

    private static CoreResponse executeCoreRequest(ProductOptionLite selectedProduct, InvocableInput input) {
        return executeCoreRequest(selectedProduct, input, true);
    }

    private static CoreResponse executeCoreRequest(ProductOptionLite selectedProduct, InvocableInput input, Boolean writeIntegrationLog) {
        String sourceIp = '0.0.0.0';

        List<AuthSession> authList = [
            SELECT Id, SourceIP, CreatedDate
            FROM AuthSession
            WHERE UsersId = :UserInfo.getUserId()
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (!authList.isEmpty() && !String.isBlank(authList[0].SourceIP)) {
            sourceIp = authList[0].SourceIP;
        }

        CoreResponse responseServer = new CoreResponse();
        String normalizedLine = normalizeLineForFunction(selectedProduct.integrationProductType);
        String function = responseServer.functionsXml.get(normalizedLine);

        if (String.isBlank(function)) {
            throw new AuraHandledException('El producto seleccionado no tiene una función de movimientos configurada.');
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(Label.EndpointWs);
        request.setMethod('POST');
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        request.setHeader('SoapAction', 'http://crmintegration.local/' + function);

        String frame = loadRequestFrame();
        frame = frame.replace('[ws_user]', Label.Int_Username);
        frame = frame.replace('[ws_password]', Label.Int_Password);
        frame = frame.replace('[function_processIntegration]', function);
        frame = frame.replace('[function_username]', UserInfo.getUserName());
        frame = frame.replace('[function_requestdate]', System.now().format('dd/MM/yyyy'));
        frame = frame.replace('[function_requesttime]', System.now().format('hh:mm:ss'));
        frame = frame.replace('[function_terminal]', sourceIp);

        frame = frame.replace('[function_fromDate]', defaultFromDate(input.fromDate));
        frame = frame.replace('[function_untilDate]', defaultUntilDate(input.untilDate));
        frame = frame.replace('[function_state]', 'null');
        frame = frame.replace('[function_minimunAmount]', 'null');
        frame = frame.replace('[function_maxAmount]', 'null');
        frame = frame.replace('[function_credirDebit]', 'null');
        frame = frame.replace('[function_documentNumber]', 'null');
        frame = frame.replace('[function_idPagination]', String.isBlank(input.paginationId) ? '0' : input.paginationId);
        frame = frame.replace('[function_pagination]', String.isBlank(input.pageDirection) ? 'Proximo' : input.pageDirection);

        frame = frame.replace('[function_numProduct]', nullSafe(selectedProduct.integrationProductNumber));
        frame = frame.replace('[function_productType]', nullSafe(selectedProduct.integrationProductType));
        frame = frame.replace('[function_currency]', normalizeCoreCurrency(selectedProduct.currencyCode));

        request.setBody(frame);
        requestInfo = request;

        HttpResponse res = null;

        try {
            res = http.send(request);

            if (res.getStatusCode() == 200) {
                if (res.getBody() != null && res.getBody().contains('<ErrorCode>')) {
                    responseServer.parse(selectedProduct.integrationProductType, res.getBody());

                    if (!String.isBlank(responseServer.errorCode)
                        && responseServer.errorCode != '000'
                        && responseServer.errorCode != '9750') {

                        logAgentFailure(
                            'Core Bancario',
                            function,
                            request,
                            res,
                            responseServer.errorCode,
                            'La integración de movimientos devolvió error. Código: '
                                + responseServer.errorCode + '. Mensaje: ' + responseServer.errorText,
                            input == null ? null : input.messagingSessionId
                        );
                    }
                } else {
                    responseServer.successTimeout = false;

                    logAgentFailure(
                        'Core Bancario',
                        function,
                        request,
                        res,
                        'INVALID_RESPONSE',
                        'La respuesta del servicio de movimientos no contiene ErrorCode o no tiene el formato esperado.',
                        input == null ? null : input.messagingSessionId
                    );
                }
            } else {
                responseServer.successTimeout = false;

                logAgentFailure(
                    'Core Bancario',
                    function,
                    request,
                    res,
                    'HTTP_' + String.valueOf(res.getStatusCode()),
                    'La integración de movimientos devolvió un código HTTP no exitoso: '
                        + String.valueOf(res.getStatusCode()) + ' - ' + res.getStatus(),
                    input == null ? null : input.messagingSessionId
                );
            }
        } catch (Exception e) {
            responseServer.successTimeout = false;
            System.debug('Error en consulta de movimientos: ' + e.getMessage());

            logAgentFailure(
                'Core Bancario',
                function,
                request,
                res,
                'CALLOUT_EXCEPTION',
                'Excepción en consulta de movimientos: ' + e.getMessage(),
                input == null ? null : input.messagingSessionId
            );
        } finally {
            if (writeIntegrationLog == true) {
                try {
                    INTLogger.INTLoggerResult result = INTLogger.logCallout('014', function, request, res);
                } catch (Exception logEx) {
                    System.debug('Error registrando log INT014: ' + logEx.getMessage());
                }
            }
        }

        return responseServer;
    }

    private static String loadRequestFrame() {
        if (Test.isRunningTest() && !String.isBlank(testRequestFrameOverride)) {
            return testRequestFrameOverride;
        }

        List<StaticResource> srList = [
            SELECT Id, Name, Body
            FROM StaticResource
            WHERE Name = 'INT014_request_frame'
            LIMIT 1
        ];

        if (srList.isEmpty()) {
            throw new XmlException('No se encontró el Static Resource "INT014_request_frame".');
        }

        return srList[0].Body.toString();
    }

    private static void logAgentFailure(
        String integrationName,
        String operation,
        HttpRequest req,
        HttpResponse res,
        String externalErrorCode,
        String errorMessage,
        String messagingSessionId
    ) {
        try {
            AgentLog__c logRecord = new AgentLog__c();

            logRecord.LogDateTime__c = System.now();
            logRecord.Status__c = 'Error';
            logRecord.SourceClass__c = 'AGENTE_ConsultarMovimientosProducto';
            logRecord.IntegrationName__c = safeTruncate(integrationName, 255);
            logRecord.Operation__c = safeTruncate(operation, 255);
            logRecord.ExternalErrorCode__c = safeTruncate(externalErrorCode, 255);
            logRecord.ErrorMessage__c = safeTruncate(errorMessage, AGENT_LOG_TEXT_LIMIT);

            if (req != null) {
                logRecord.Endpoint__c = safeTruncate(req.getEndpoint(), 255);
                logRecord.HttpMethod__c = safeTruncate(req.getMethod(), 255);
                logRecord.RequestPayload__c = safeTruncate(sanitizePayload(req.getBody()), AGENT_LOG_TEXT_LIMIT);
            }

            if (res != null) {
                logRecord.HttpStatusCode__c = res.getStatusCode();
                logRecord.ResponsePayload__c = safeTruncate(sanitizePayload(res.getBody()), AGENT_LOG_TEXT_LIMIT);
            }

            Id sessionId = safeSalesforceId(messagingSessionId);

            if (sessionId != null) {
                logRecord.MessagingSession__c = sessionId;
            }

            insertAgentLogSafely(logRecord);

        } catch (Exception logEx) {
            System.debug('Error creando AgentLog__c: ' + logEx.getMessage());
        }
    }

    private static void insertAgentLogSafely(AgentLog__c logRecord) {
        try {
            insert logRecord;
        } catch (DmlException dmlEx) {
            if (logRecord.MessagingSession__c != null) {
                logRecord.MessagingSession__c = null;
                insert logRecord;
            } else {
                throw dmlEx;
            }
        }
    }

    private static String sanitizePayload(String payload) {
        if (String.isBlank(payload)) {
            return '';
        }

        String sanitized = payload;

        if (!String.isBlank(Label.Int_Username)) {
            sanitized = sanitized.replace(Label.Int_Username, '***MASKED_USERNAME***');
        }

        if (!String.isBlank(Label.Int_Password)) {
            sanitized = sanitized.replace(Label.Int_Password, '***MASKED_PASSWORD***');
        }

        sanitized = maskXmlTag(sanitized, 'Password');
        sanitized = maskXmlTag(sanitized, 'password');
        sanitized = maskXmlTag(sanitized, 'PassWord');
        sanitized = maskXmlTag(sanitized, 'UserPassword');
        sanitized = maskXmlTag(sanitized, 'Token');
        sanitized = maskXmlTag(sanitized, 'token');
        sanitized = maskXmlTag(sanitized, 'Authorization');
        sanitized = maskXmlTag(sanitized, 'NumTarjeta');
        sanitized = maskXmlTag(sanitized, 'NumeroTarjeta');
        sanitized = maskXmlTag(sanitized, 'CardNumber');
        sanitized = maskXmlTag(sanitized, 'NumProduct');
        sanitized = maskXmlTag(sanitized, 'numProduct');
        sanitized = maskXmlTag(sanitized, 'NumDocumento');
        sanitized = maskXmlTag(sanitized, 'Documento');

        return sanitized;
    }

    private static String maskXmlTag(String source, String tagName) {
        if (String.isBlank(source) || String.isBlank(tagName)) {
            return source;
        }

        String result = source;
        String openPrefix = '<' + tagName;
        String closeTag = '</' + tagName + '>';
        String masked = '***MASKED***';
        Integer searchFrom = 0;

        while (searchFrom < result.length()) {
            Integer openStart = result.indexOf(openPrefix, searchFrom);

            if (openStart < 0) {
                break;
            }

            Integer openEnd = result.indexOf('>', openStart);

            if (openEnd < 0) {
                break;
            }

            Integer closeStart = result.indexOf(closeTag, openEnd + 1);

            if (closeStart < 0) {
                searchFrom = openEnd + 1;
                continue;
            }

            Integer valueStart = openEnd + 1;
            result = result.substring(0, valueStart) + masked + result.substring(closeStart);
            searchFrom = valueStart + masked.length() + closeTag.length();
        }

        return result;
    }

    private static String safeTruncate(String value, Integer maxLength) {
        if (String.isBlank(value)) {
            return '';
        }

        if (maxLength == null || maxLength <= 0) {
            return value;
        }

        return value.length() > maxLength ? value.substring(0, maxLength) : value;
    }

    private static Id safeSalesforceId(String value) {
        if (String.isBlank(value)) {
            return null;
        }

        try {
            Id parsedId = value.trim();
            return parsedId;
        } catch (Exception e) {
            return null;
        }
    }

    private static List<TransactionItem> normalizeTransactions(List<Map<String, Object>> rows, ProductOptionLite selectedProduct) {
        List<TransactionItem> items = new List<TransactionItem>();
        String normalizedLine = normalizeLineForFunction(selectedProduct.integrationProductType);

        for (Map<String, Object> row : rows) {
            TransactionItem item = new TransactionItem();

            if (normalizedLine == 'tarjetas de crédito' || normalizedLine == 'tarjetas de credito') {
                String dateValue = firstNonBlank(
                    String.valueOf(row.get('FechaCompra')),
                    String.valueOf(row.get('FechaTransaccion'))
                );

                String descriptionValue = firstNonBlank(
                    String.valueOf(row.get('Descripcion')),
                    String.valueOf(row.get('TipoTransaccion')),
                    'Movimiento'
                );

                String amountRaw = firstNonBlank(
                    String.valueOf(row.get('MontoLocal')),
                    String.valueOf(row.get('MontoOriginal'))
                );

                String creditDebit = String.valueOf(row.get('CreditoDebito'));

                item.transactionDate = normalizeDate(dateValue);
                item.description = truncateText(descriptionValue, 40);
                item.rawAmount = amountRaw;
                item.amount = formatSignedAmount(amountRaw, creditDebit, String.valueOf(row.get('Moneda')));
                item.creditDebit = creditDebit;
                item.reference = String.valueOf(row.get('NumTransaccion'));
            } else {
                String dateValue = firstNonBlank(
                    String.valueOf(row.get('FechaTransaccion')),
                    String.valueOf(row.get('FechaProceso'))
                );

                String descriptionValue = firstNonBlank(
                    String.valueOf(row.get('DescTransaccion')),
                    String.valueOf(row.get('Descripcion')),
                    'Movimiento'
                );

                String amountRaw = firstNonBlank(
                    String.valueOf(row.get('Valor')),
                    String.valueOf(row.get('MontoTotal'))
                );

                String creditDebit = String.valueOf(row.get('CreditoDebito'));

                item.transactionDate = normalizeDate(dateValue);
                item.description = truncateText(descriptionValue, 40);
                item.rawAmount = amountRaw;
                item.amount = formatSignedAmount(amountRaw, creditDebit, selectedProduct.currencyCode);
                item.creditDebit = creditDebit;
                item.reference = firstNonBlank(
                    String.valueOf(row.get('Referencia')),
                    String.valueOf(row.get('Documento')),
                    String.valueOf(row.get('NumDocumento'))
                );
            }

            items.add(item);
        }

        return items;
    }

    private static void sortTransactionsByDateDesc(List<TransactionItem> items) {
        if (items == null || items.size() <= 1) {
            return;
        }

        for (Integer i = 0; i < items.size() - 1; i++) {
            for (Integer j = i + 1; j < items.size(); j++) {
                if (isTransactionAfter(items[j], items[i])) {
                    TransactionItem temp = items[i];
                    items[i] = items[j];
                    items[j] = temp;
                }
            }
        }
    }

    private static Boolean isTransactionAfter(TransactionItem left, TransactionItem right) {
        if (left == null) {
            return false;
        }

        if (right == null) {
            return true;
        }

        Integer leftKey = transactionDateSortKey(left.transactionDate);
        Integer rightKey = transactionDateSortKey(right.transactionDate);

        if (leftKey == null && rightKey == null) {
            return false;
        }

        if (leftKey != null && rightKey == null) {
            return true;
        }

        if (leftKey == null && rightKey != null) {
            return false;
        }

        return leftKey > rightKey;
    }

    private static Integer transactionDateSortKey(String value) {
        if (String.isBlank(value)) {
            return null;
        }

        try {
            String trimmed = value.trim();

            if (trimmed.contains('/')) {
                List<String> parts = trimmed.split('/');

                if (parts.size() == 3) {
                    Integer day = Integer.valueOf(leadingDigits(parts[0], 2));
                    Integer month = Integer.valueOf(leadingDigits(parts[1], 2));
                    Integer year = Integer.valueOf(leadingDigits(parts[2], 4));

                    return (year * 10000) + (month * 100) + day;
                }
            }

            if (trimmed.contains('-')) {
                List<String> parts = trimmed.split('-');

                if (parts.size() >= 3) {
                    Integer year = Integer.valueOf(leadingDigits(parts[0], 4));
                    Integer month = Integer.valueOf(leadingDigits(parts[1], 2));
                    Integer day = Integer.valueOf(leadingDigits(parts[2], 2));

                    return (year * 10000) + (month * 100) + day;
                }
            }

            return null;

        } catch (Exception e) {
            return null;
        }
    }

    private static String buildDisplayText(ProductOptionLite selectedProduct, List<TransactionItem> txs, Integer remainingCount) {
        String text = 'Estos son los últimos movimientos de ' + nullSafe(selectedProduct.displayLabel) + ':\n';
        Integer idx = 1;

        for (TransactionItem tx : txs) {
            text += String.valueOf(idx) + '. '
                + tx.transactionDate + ' - '
                + tx.description + ' - '
                + tx.amount + '\n';
            idx++;
        }

        String normalizedLine = normalizeLineForFunction(selectedProduct.integrationProductType);

        if (normalizedLine == 'tarjetas de crédito' || normalizedLine == 'tarjetas de credito') {
            text += '\nLos movimientos de TC pueden demorar hasta 48hs en verse reflejados.';
        }

        if (remainingCount != null && remainingCount > 0) {
            Integer nextBatch = remainingCount >= PAGE_SIZE ? PAGE_SIZE : remainingCount;
            text += '\n\nSi deseas, puedo mostrarte ' + String.valueOf(nextBatch) + ' movimiento';

            if (nextBatch != 1) {
                text += 's';
            }

            text += ' más.';
        }

        return text;
    }

    private static String buildNoMovementsText(ProductOptionLite selectedProduct) {
        return 'No tengo movimientos disponibles para ' + nullSafe(selectedProduct.displayLabel)
            + ' en este momento o para el rango consultado.';
    }

    private static String buildGenericUnavailableText(ProductOptionLite selectedProduct) {
        return 'No fue posible consultar los movimientos de ' + nullSafe(selectedProduct.displayLabel)
            + ' por este canal en este momento.';
    }

    private static String normalizeLineForFunction(String lineDescription) {
        return String.isBlank(lineDescription) ? '' : lineDescription.trim().toLowerCase();
    }

    private static String defaultFromDate(String fromDate) {
        if (!String.isBlank(fromDate)) {
            return normalizeToCoreDate(fromDate);
        }

        return Datetime.now().addDays(-30).format('MM/dd/yyyy');
    }

    private static String defaultUntilDate(String untilDate) {
        if (!String.isBlank(untilDate)) {
            return normalizeToCoreDate(untilDate);
        }

        return Datetime.now().format('MM/dd/yyyy');
    }

    private static String normalizeToCoreDate(String inputDate) {
        if (String.isBlank(inputDate)) {
            return '';
        }

        String value = inputDate.trim();

        if (value.contains('/')) {
            List<String> parts = value.split('/');

            if (parts.size() == 3) {
                Integer first = Integer.valueOf(leadingDigits(parts[0], 2));
                Integer second = Integer.valueOf(leadingDigits(parts[1], 2));
                String year = leadingDigits(parts[2], 4);

                if (first > 12) {
                    return pad2(second) + '/' + pad2(first) + '/' + year;
                }

                return pad2(first) + '/' + pad2(second) + '/' + year;
            }
        }

        if (value.contains('-')) {
            List<String> parts = value.split('-');

            if (parts.size() == 3) {
                return pad2(Integer.valueOf(leadingDigits(parts[1], 2)))
                    + '/'
                    + pad2(Integer.valueOf(leadingDigits(parts[2], 2)))
                    + '/'
                    + leadingDigits(parts[0], 4);
            }
        }

        return value;
    }

    private static String normalizeDate(String value) {
        if (String.isBlank(value)) {
            return '';
        }

        String trimmed = value.trim();

        if (trimmed.contains('/')) {
            List<String> parts = trimmed.split('/');

            if (parts.size() == 3) {
                if (parts[0].length() == 4) {
                    Integer isoDay = Integer.valueOf(leadingDigits(parts[2], 2));
                    Integer isoMonth = Integer.valueOf(leadingDigits(parts[1], 2));
                    String isoYear = leadingDigits(parts[0], 4);
                    return pad2(isoDay) + '/' + pad2(isoMonth) + '/' + isoYear;
                }

                Integer first = Integer.valueOf(leadingDigits(parts[0], 2));
                Integer second = Integer.valueOf(leadingDigits(parts[1], 2));
                String year = leadingDigits(parts[2], 4);

                if (first > 12) {
                    return pad2(first) + '/' + pad2(second) + '/' + year;
                }

                if (second > 12) {
                    return pad2(second) + '/' + pad2(first) + '/' + year;
                }

                return pad2(second) + '/' + pad2(first) + '/' + year;
            }
        }

        if (trimmed.contains('-')) {
            List<String> parts = trimmed.split('-');

            if (parts.size() >= 3) {
                return pad2(Integer.valueOf(leadingDigits(parts[2], 2)))
                    + '/'
                    + pad2(Integer.valueOf(leadingDigits(parts[1], 2)))
                    + '/'
                    + leadingDigits(parts[0], 4);
            }
        }

        return trimmed;
    }

    private static String truncateText(String value, Integer maxLen) {
        if (String.isBlank(value)) {
            return '';
        }

        String cleaned = value.trim();

        if (cleaned.length() <= maxLen) {
            return cleaned;
        }

        return cleaned.substring(0, maxLen - 3) + '...';
    }

    private static String formatSignedAmount(String amountRaw, String creditDebit, String currencyRaw) {
        if (String.isBlank(amountRaw)) {
            return '';
        }

        Decimal amount;

        try {
            amount = Decimal.valueOf(amountRaw.replace(',', ''));
        } catch (Exception e) {
            return amountRaw;
        }

        String sign = inferSign(creditDebit);
        String currencySymbol = normalizeCurrency(currencyRaw);

        return currencySymbol + sign + formatDecimal(amount);
    }

    private static String inferSign(String creditDebit) {
        String val = String.isBlank(creditDebit) ? '' : creditDebit.trim().toUpperCase();

        if (val == 'C' || val == 'CR' || val == 'CREDITO' || val == 'CRÉDITO' || val == 'CREDIT') {
            return '+';
        }

        if (val == 'D' || val == 'DB' || val == 'DEBITO' || val == 'DÉBITO' || val == 'DEBIT') {
            return '-';
        }

        return '';
    }

    private static String normalizeCurrency(String currencyRaw) {
        String c = String.isBlank(currencyRaw) ? '' : currencyRaw.trim().toUpperCase();

        if (c == 'DOP' || c == 'RD' || c == 'RD$' || c == 'RDP') {
            return 'RD$ ';
        }

        if (c == 'USD' || c == 'US' || c == 'US$') {
            return 'US$ ';
        }

        return '';
    }

    private static String normalizeCoreCurrency(String currencyRaw) {
        String c = String.isBlank(currencyRaw) ? '' : currencyRaw.trim().toUpperCase();

        if (c == 'RD' || c == 'RD$' || c == 'RDP') {
            return 'DOP';
        }

        if (c == 'US' || c == 'US$') {
            return 'USD';
        }

        return c;
    }

    private static String formatDecimal(Decimal value) {
        Decimal scaled = value.setScale(2);
        String raw = String.valueOf(scaled);
        List<String> parts = raw.split('\\.');
        String intPart = parts[0];
        String decPart = parts.size() > 1 ? parts[1] : '00';

        String formattedInt = '';
        Integer count = 0;

        for (Integer i = intPart.length() - 1; i >= 0; i--) {
            formattedInt = intPart.substring(i, i + 1) + formattedInt;
            count++;

            if (count == 3 && i > 0) {
                formattedInt = ',' + formattedInt;
                count = 0;
            }
        }

        if (decPart.length() == 1) {
            decPart += '0';
        }

        return formattedInt + '.' + decPart;
    }

    private static String firstNonBlank(String a, String b) {
        return firstNonBlank(new List<String>{ a, b });
    }

    private static String firstNonBlank(String a, String b, String c) {
        return firstNonBlank(new List<String>{ a, b, c });
    }

    private static String firstNonBlank(List<String> values) {
        for (String v : values) {
            if (!String.isBlank(v) && v != 'null') {
                return v;
            }
        }

        return '';
    }

    private static String nullSafe(String value) {
        return value == null ? '' : value;
    }

    private static String pad2(Integer value) {
        return value < 10 ? '0' + String.valueOf(value) : String.valueOf(value);
    }

    private static String leadingDigits(String value, Integer maxLen) {
        if (String.isBlank(value)) {
            return '';
        }

        String digits = '';

        for (Integer i = 0; i < value.length(); i++) {
            String c = value.substring(i, i + 1);

            if (c >= '0' && c <= '9') {
                digits += c;

                if (maxLen != null && maxLen > 0 && digits.length() >= maxLen) {
                    break;
                }
            } else if (!String.isBlank(digits)) {
                break;
            }
        }

        return digits;
    }
}