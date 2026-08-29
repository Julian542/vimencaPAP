public with sharing class AGENTE_ConsultarProductosCliente {

    private class AgentHandledException extends Exception {}

    private static HttpRequest requestInfo;
    private static final Integer AGENT_LOG_TEXT_LIMIT = 32000;

    public class ProductOption {
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

    public class ProductPortfolioResponse {
        public String status; // OK / ERROR / NO_PRODUCTS
        public String message;
        public Integer totalProducts;
        public List<ProductOption> products;

        public ProductPortfolioResponse() {
            products = new List<ProductOption>();
            totalProducts = 0;
        }
    }

    public class InternalRequest {
        public String customerType;
        public String identificationNumber;
        public String identificationType;
        public String cif;
    }

    public class InvocableInput {
        @InvocableVariable(required=true)
        public String customerType;

        @InvocableVariable(required=true)
        public String identificationNumber;

        @InvocableVariable(required=false)
        public String identificationType;

        @InvocableVariable(required=true)
        public String cif;

        @InvocableVariable(required=false)
        public String messagingSessionId;
    }

    public class InvocableOutput {
        @InvocableVariable
        public String status;

        @InvocableVariable
        public String message;

        @InvocableVariable
        public Integer totalProducts;

        @InvocableVariable
        public String productsJson;

        @InvocableVariable
        public String displayText;
    }

    @InvocableMethod(label='Consultar productos del cliente' description='Consulta productos financieros elegibles del cliente autenticado para el agente')
    public static List<InvocableOutput> consultarProductosFlow(List<InvocableInput> inputs) {
        List<InvocableOutput> outputs = new List<InvocableOutput>();

        if (inputs == null || inputs.isEmpty()) {
            InvocableOutput out = new InvocableOutput();
            out.status = 'ERROR';
            out.message = 'No se recibió información de entrada.';
            out.totalProducts = 0;
            out.productsJson = '[]';
            out.displayText = 'No fue posible procesar la solicitud.';
            outputs.add(out);
            return outputs;
        }

        for (InvocableInput input : inputs) {
            InvocableOutput out = new InvocableOutput();

            try {
                InternalRequest request = new InternalRequest();
                request.customerType = input.customerType;
                request.identificationNumber = input.identificationNumber;
                request.identificationType = input.identificationType;
                request.cif = input.cif;

                ProductPortfolioResponse serviceResponse = consultarProductos(
                    request,
                    input == null ? null : input.messagingSessionId
                );

                out.status = serviceResponse.status;
                out.message = serviceResponse.message;
                out.totalProducts = serviceResponse.totalProducts;
                out.productsJson = JSON.serialize(serviceResponse.products);
                out.displayText = buildDisplayText(serviceResponse);

            } catch (Exception e) {
                out.status = 'ERROR';
                out.message = 'Ocurrió un error al consultar los productos del cliente: ' + e.getMessage();
                out.totalProducts = 0;
                out.productsJson = '[]';
                out.displayText = 'No fue posible consultar los productos en este momento.';
            }

            outputs.add(out);
        }

        return outputs;
    }

    public static ProductPortfolioResponse consultarProductos(InternalRequest input) {
        return consultarProductos(input, null);
    }

    public static ProductPortfolioResponse consultarProductos(InternalRequest input, String messagingSessionId) {
        ProductPortfolioResponse output = new ProductPortfolioResponse();
        HttpResponse response = null;
        String functionName = 'ConsultaProdFinPF_PJ_Agent';

        requestInfo = null;

        try {
            validateInput(input);

            functionName = getFunctionName(input.customerType);
            String requestXML = buildSoapRequest(input, functionName);

            response = sendSoapRequest(requestXML, functionName);

            if (response == null) {
                output.status = 'ERROR';
                output.message = 'No fue posible obtener respuesta del servicio de productos.';

                logAgentFailure(
                    'Core Bancario',
                    functionName,
                    requestInfo,
                    response,
                    'NO_RESPONSE',
                    output.message,
                    messagingSessionId
                );

                return output;
            }

            if (response.getStatusCode() != 200) {
                output.status = 'ERROR';
                output.message = 'El servicio de productos respondió con error técnico. Código HTTP: ' + response.getStatusCode();

                logAgentFailure(
                    'Core Bancario',
                    functionName,
                    requestInfo,
                    response,
                    'HTTP_' + String.valueOf(response.getStatusCode()),
                    output.message,
                    messagingSessionId
                );

                return output;
            }

            parseSoapResponse(response, input.customerType, output);

            if (output.products.isEmpty()) {
                output.status = 'NO_PRODUCTS';
                output.message = 'No se encontraron productos elegibles para consultar movimientos.';
                output.totalProducts = 0;
            } else {
                output.status = 'OK';
                output.message = 'Productos obtenidos correctamente.';
                output.totalProducts = output.products.size();
            }

            return output;

        } catch (Exception e) {
            output.status = 'ERROR';
            output.message = 'Ocurrió un error al consultar los productos del cliente: ' + e.getMessage();

            if (requestInfo != null || response != null) {
                logAgentFailure(
                    'Core Bancario',
                    functionName,
                    requestInfo,
                    response,
                    deriveExternalErrorCode(response),
                    output.message,
                    messagingSessionId
                );
            }

            return output;

        } finally {
            try {
                INTLogger.INTLoggerResult result = INTLogger.logCallout(
                    '011',
                    'ConsultaProdFinPF_PJ_Agent',
                    requestInfo,
                    response
                );
            } catch (Exception logEx) {
                System.debug('Error registrando log de integración: ' + logEx.getMessage());
            }
        }
    }

    private static void validateInput(InternalRequest input) {
        if (input == null) {
            throw new AgentHandledException('La solicitud está vacía.');
        }

        if (String.isBlank(input.customerType)) {
            throw new AgentHandledException('Debe indicar el tipo de cliente.');
        }

        if (String.isBlank(input.identificationNumber)) {
            throw new AgentHandledException('Debe indicar el número de identificación o RNC.');
        }

        if (String.isBlank(input.cif)) {
            throw new AgentHandledException('Debe indicar el CIF del cliente.');
        }

        String normalizedCustomerType = input.customerType.trim().toUpperCase();
        if (normalizedCustomerType != 'PF' && normalizedCustomerType != 'PJ') {
            throw new AgentHandledException('El tipo de cliente debe ser PF o PJ.');
        }

        if (normalizedCustomerType == 'PF' && String.isBlank(input.identificationType)) {
            throw new AgentHandledException('Para Persona Física debe indicar el tipo de identificación.');
        }
    }

    private static String getFunctionName(String customerType) {
        String normalizedCustomerType = customerType.trim().toUpperCase();
        return normalizedCustomerType == 'PJ' ? 'ConsultaProdFinPJ' : 'ConsultaProdFinPF';
    }

    private static String buildSoapRequest(InternalRequest input, String functionName) {
        Datetime actualTime = Datetime.now();

        User userData = [
            SELECT Id, Username, USE_Codigo__c, USE_Direccion_Oficina__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        DOM.Document doc = new DOM.Document();

        DOM.XmlNode envelope = doc.createRootElement('SOAP-ENV:Envelope', null, null);
        envelope.setNamespace('SOAP-ENV', 'http://schemas.xmlsoap.org/soap/envelope/');
        envelope.setNamespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance');
        envelope.setNamespace('xsd', 'http://www.w3.org/2001/XMLSchema');

        DOM.XmlNode header = envelope.addChildElement('SOAP-ENV:Header', null, null);
        DOM.XmlNode security = header.addChildElement('wsse:Security', null, null);
        security.setNamespace('wsse', 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd');
        security.setNamespace('wsu', 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd');

        DOM.XmlNode usernameToken = security.addChildElement('wsse:UsernameToken', null, null);
        usernameToken.setAttribute('wsu:Id', 'UsernameToken-Agentforce');

        usernameToken.addChildElement('wsse:Username', null, null).addTextNode(Label.Int_Username);

        DOM.XmlNode password = usernameToken.addChildElement('wsse:Password', null, null);
        password.setAttribute('Type', 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText');
        password.addTextNode(Label.Int_Password);

        DOM.XmlNode body = envelope.addChildElement('SOAP-ENV:Body', null, null);

        DOM.XmlNode httpSleepTime = body.addChildElement('HTTPSleepTime', null, null);
        httpSleepTime.setNamespace('', 'http://crmintegration.local/');
        httpSleepTime.addTextNode('30000');

        DOM.XmlNode listOfFuncionGeneral = body.addChildElement('ListOfBREAIFuncionGeneral', null, null);
        listOfFuncionGeneral.setNamespace('', 'http://www.siebel.com/xml/BR%20EAI%20Funcion%20General%20IO');

        DOM.XmlNode function = listOfFuncionGeneral.addChildElement('Function', null, null);
        function.addChildElement('FunctionName', null, null).addTextNode(functionName);
        function.addChildElement('UserName', null, null).addTextNode(userData.Username);
        function.addChildElement('RequestDate', null, null).addTextNode(formatDateDDMMYYYY(actualTime));
        function.addChildElement('RequestTime', null, null).addTextNode(formatTimeHHMMSS(actualTime));
        function.addChildElement('Terminal', null, null).addTextNode('0.0.0.0');
        function.addChildElement('Channel', null, null).addTextNode('SALESFORCE');
        function.addChildElement('Version', null, null).addTextNode('1');

        if (input.customerType.trim().toUpperCase() == 'PJ') {
            function.addChildElement('Parameter01', null, null).addTextNode(nullSafe(input.identificationNumber));
            function.addChildElement('Parameter02', null, null).addTextNode('RNC');
        } else {
            function.addChildElement('Parameter01', null, null).addTextNode(nullSafe(input.identificationNumber));
            function.addChildElement('Parameter02', null, null).addTextNode(normalizeIdentificationType(input.identificationType));
        }

        function.addChildElement('Parameter03', null, null).addTextNode(nullSafe(input.cif));
        function.addChildElement('Parameter04', null, null).addTextNode(nullSafe(userData.USE_Codigo__c));
        function.addChildElement('Parameter05', null, null).addTextNode(nullSafe(userData.USE_Direccion_Oficina__c));

        return doc.toXmlString().remove('<?xml version="1.0" encoding="UTF-8"?>');
    }

    private static HttpResponse sendSoapRequest(String body, String action) {
        Http http = new Http();

        HttpRequest request = new HttpRequest();
        request.setEndpoint(Label.EndpointWs);
        request.setMethod('POST');
        request.setTimeout(120000);
        request.setHeader('SoapAction', 'http://crmintegration.local/' + action);
        request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        request.setBody(body);

        requestInfo = request;

        return http.send(request);
    }

    private static void parseSoapResponse(HttpResponse response, String customerType, ProductPortfolioResponse output) {
        String namespace = getResponseNamespace(customerType);

        DOM.Document responseXML = response.getBodyDocument();
        DOM.XMLNode rootNode = responseXML.getRootElement();

        DOM.XMLNode bodyNode = rootNode.getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/');
        if (bodyNode == null) {
            throw new AgentHandledException('La respuesta SOAP no contiene Body.');
        }

        DOM.XMLNode listNode = bodyNode.getChildElement('ListOfBREAIFuncionGeneral', namespace);
        if (listNode == null) {
            throw new AgentHandledException('La respuesta SOAP no contiene la lista de resultados esperada.');
        }

        DOM.XMLNode resultNode = listNode.getChildElement('Result', namespace);
        if (resultNode == null) {
            throw new AgentHandledException('La respuesta SOAP no contiene el nodo Result.');
        }

        String errorCode = getChildText(resultNode, 'ErrorCode', namespace);
        String errorText = getChildText(resultNode, 'ErrorText', namespace);

        if (errorCode != '000' || errorText != 'TRANSACCION PROCESADA') {
            throw new AgentHandledException('Error en la integración. Código: ' + errorCode + '. Mensaje: ' + errorText);
        }

        List<DOM.XMLNode> children = resultNode.getChildren();

        for (DOM.XMLNode childNode : children) {
            if (childNode == null || childNode.getName() != 'Producto') {
                continue;
            }

            ProductOption product = mapProduct(childNode, namespace);

            if (product.eligibleForTransactions) {
                output.products.add(product);
            }
        }
    }

    private static ProductOption mapProduct(DOM.XMLNode productNode, String namespace) {
        ProductOption product = new ProductOption();

        String accountNumber = getChildText(productNode, 'NumCuenta', namespace);
        String productCode = getChildText(productNode, 'CodigoProducto', namespace);
        String lineDescription = getChildText(productNode, 'LineaProducto', namespace);
        String ownershipType = getChildText(productNode, 'TipoVinculacion', namespace);
        String status = getChildText(productNode, 'Estado', namespace);
        String holderName = getChildText(productNode, 'Titulares', namespace);
System.debug('===================');
System.debug('LINEA -> ' + lineDescription);
System.debug('ACCOUNT -> ' + accountNumber);
System.debug('PRODUCT CODE -> ' + productCode);
System.debug('STATUS -> ' + status);
        if(
    lineDescription != null &&
    lineDescription.toLowerCase().contains('prest')
){

    System.debug(
        '======= DETALLE PRESTAMO ======='
    );

    for(DOM.XMLNode child : productNode.getChildren()){

        System.debug(
            child.getName() +
            ' -> ' +
            child.getText()
        );
    }

    System.debug(
        '================================'
    );
}
System.debug('===== CAMPOS PRODUCTO PRESTAMO =====');

for(DOM.XMLNode child : productNode.getChildren()){

    System.debug(
        child.getName() +
        ' -> ' +
        child.getText()
    );
}

System.debug('===================================');
System.debug('===================');
        String saldoRD = getChildText(productNode, 'SaldoRD', namespace);
        String saldoUS = getChildText(productNode, 'SaldoUS', namespace);

        product.accountNumberRaw = accountNumber;
        product.accountNumberMasked = maskAccountNumber(accountNumber);
        product.productCode = productCode;
        product.lineDescription = String.isBlank(lineDescription) ? '' : lineDescription.trim();
        product.ownershipType = ownershipType;
        product.status = String.isBlank(status) ? '' : status.trim();
        product.holderName = holderName;
        product.productType = normalizeProductType(product.lineDescription, productCode);
        product.eligibleForTransactions = isEligibleForTransactions(product.lineDescription, product.status);

        product.integrationProductNumber = accountNumber;
        product.integrationProductType = product.lineDescription;
        product.currencyCode = inferCurrencyCode(saldoRD, saldoUS, product.lineDescription);

        product.productKey = buildProductKey(product.integrationProductNumber, product.productCode, product.integrationProductType);
        product.displayLabel = buildDisplayLabel(product.productType, product.accountNumberMasked, product.status);

        return product;
   
    }

    private static String getResponseNamespace(String customerType) {
        String normalizedCustomerType = customerType.trim().toUpperCase();

        if (normalizedCustomerType == 'PJ') {
            return 'http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PJ%20Response%20IO';
        }

        return 'http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20VBC%20Response%20IO';
    }

    private static String normalizeIdentificationType(String identificationType) {
        if (String.isBlank(identificationType)) {
            return '';
        }

        String value = identificationType.trim();

        if (value.equalsIgnoreCase('Cédula')) {
            return 'Cedula';
        }

        return value;
    }

    private static String normalizeProductType(
    String lineDescription,
    String productCode
) {
    String line =
        String.isBlank(lineDescription)
        ? ''
        : lineDescription
            .trim()
            .toLowerCase();

    // Normalizar acentos
    line = line.replace('á','a');
    line = line.replace('é','e');
    line = line.replace('í','i');
    line = line.replace('ó','o');
    line = line.replace('ú','u');

    if (line.contains('prepago')) {
        return 'Prepago';
    }

    if (line.contains('tarjeta')) {
        return 'Tarjeta';
    }

    if (
        line.contains('prestamo') ||
        line.contains('credito')
    ) {
        return 'Préstamo';
    }

    if (
        line.contains('cuenta') ||
        line.contains('ahorro') ||
        line.contains('corriente')
    ) {
        return 'Cuenta';
    }

    return 'Producto';
}

    private static Boolean isEligibleForTransactions(
    String lineDescription,
    String status
) {
    if (String.isBlank(status)) {
        return false;
    }

    String normalizedStatus =
        status.trim().toUpperCase();

    if (
        normalizedStatus != 'ACTIVA' &&
        normalizedStatus != 'VIGENTE'
    ) {
        return false;
    }

    String line =
        String.isBlank(lineDescription)
        ? ''
        : lineDescription
            .trim()
            .toLowerCase();

    // Normalizar acentos
    line = line.replace('á','a');
    line = line.replace('é','e');
    line = line.replace('í','i');
    line = line.replace('ó','o');
    line = line.replace('ú','u');

    // CUENTAS
    if (line.contains('cuenta')) {
        return true;
    }

    if (line.contains('ahorro')) {
        return true;
    }

    if (line.contains('corriente')) {
        return true;
    }

    // TARJETAS
    if (line.contains('prepago')) {
        return true;
    }

    if (line.contains('tarjeta')) {
        return true;
    }

    // PRESTAMOS
    if (line.contains('prestamo')) {
        return true;
    }

    if (line.contains('credito')) {
        return true;
    }

    return false;
}

    private static String inferCurrencyCode(String saldoRD, String saldoUS, String lineDescription) {
        if (!String.isBlank(saldoUS) && isNonZeroDecimal(saldoUS)) {
            return 'USD';
        }
        if (!String.isBlank(saldoRD) && isNonZeroDecimal(saldoRD)) {
            return 'DOP';
        }

        String line = String.isBlank(lineDescription) ? '' : lineDescription.trim().toLowerCase();
        if (line.contains('tarjeta')) {
            return 'DOP';
        }

        return '';
    }

    private static Boolean isNonZeroDecimal(String value) {
        try {
            return Decimal.valueOf(value) != 0;
        } catch (Exception e) {
            return false;
        }
    }

    private static String buildProductKey(String accountNumber, String productCode, String productType) {
        return EncodingUtil.base64Encode(
            Blob.valueOf(
                nullSafe(accountNumber) + '|' +
                nullSafe(productCode) + '|' +
                nullSafe(productType)
            )
        );
    }

    private static String buildDisplayLabel(String productType, String maskedNumber, String status) {
        String label = productType + ' ' + maskedNumber;
        if (!String.isBlank(status)) {
            label += ' - ' + status;
        }
        return label;
    }

    private static String buildDisplayText(ProductPortfolioResponse response) {
        if (response == null) {
            return 'No fue posible consultar los productos en este momento.';
        }

        if (response.status == 'NO_PRODUCTS') {
            return 'No encontré productos elegibles para consultar movimientos.';
        }

        if (response.status == 'ERROR') {
            return 'No fue posible consultar los productos en este momento.';
        }

        if (response.products == null || response.products.isEmpty()) {
            return 'No encontré productos elegibles para consultar movimientos.';
        }

        String text = 'Encontré estos productos asociados a tu perfil:\n';
        Integer index = 1;

        for (ProductOption product : response.products) {
            text += String.valueOf(index) + '. ' + product.displayLabel + '\n';
            index++;
        }

        text += 'Por favor, indícame cuál deseas consultar.';
        return text;
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
            logRecord.SourceClass__c = 'AGENTE_ConsultarProductosCliente';
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

    private static String deriveExternalErrorCode(HttpResponse response) {
        if (response == null) {
            return 'CALLOUT_EXCEPTION';
        }

        if (response.getStatusCode() != 200) {
            return 'HTTP_' + String.valueOf(response.getStatusCode());
        }

        String body = response.getBody();
        String coreErrorCode = extractXmlTagValue(body, 'ErrorCode');

        if (!String.isBlank(coreErrorCode)) {
            return coreErrorCode;
        }

        return 'INVALID_RESPONSE';
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

        sanitized = maskXmlTagByLocalName(sanitized, 'Username');
        sanitized = maskXmlTagByLocalName(sanitized, 'Password');
        sanitized = maskXmlTagByLocalName(sanitized, 'Token');
        sanitized = maskXmlTagByLocalName(sanitized, 'Authorization');

        sanitized = maskXmlTagByLocalName(sanitized, 'Parameter01');
        sanitized = maskXmlTagByLocalName(sanitized, 'Parameter03');
        sanitized = maskXmlTagByLocalName(sanitized, 'NumCuenta');
        sanitized = maskXmlTagByLocalName(sanitized, 'NumTarjeta');
        sanitized = maskXmlTagByLocalName(sanitized, 'Documento');
        sanitized = maskXmlTagByLocalName(sanitized, 'NumDocumento');

        return sanitized;
    }

    private static String maskXmlTagByLocalName(String source, String localName) {
        if (String.isBlank(source) || String.isBlank(localName)) {
            return source;
        }

        String result = source;
        String openSearch = localName;
        String masked = '***MASKED***';
        Integer searchFrom = 0;

        while (searchFrom < result.length()) {
            Integer nameIndex = result.indexOf(openSearch, searchFrom);
            if (nameIndex < 0) {
                break;
            }

            Integer tagStart = result.lastIndexOf('<', nameIndex);
            Integer tagEnd = result.indexOf('>', nameIndex);

            if (tagStart < 0 || tagEnd < 0 || tagStart > nameIndex) {
                searchFrom = nameIndex + openSearch.length();
                continue;
            }

            String openTagContent = result.substring(tagStart + 1, tagEnd);
            if (openTagContent.startsWith('/')) {
                searchFrom = tagEnd + 1;
                continue;
            }

            String elementName = openTagContent;
            if (elementName.contains(' ')) {
                elementName = elementName.substringBefore(' ');
            }

            Boolean isMatch = elementName == localName || elementName.endsWith(':' + localName);
            if (!isMatch) {
                searchFrom = tagEnd + 1;
                continue;
            }

            String closeTag = '</' + elementName + '>';
            Integer closeStart = result.indexOf(closeTag, tagEnd + 1);

            if (closeStart < 0) {
                searchFrom = tagEnd + 1;
                continue;
            }

            Integer valueStart = tagEnd + 1;
            result = result.substring(0, valueStart) + masked + result.substring(closeStart);
            searchFrom = valueStart + masked.length() + closeTag.length();
        }

        return result;
    }

    private static String extractXmlTagValue(String source, String tagName) {
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

    private static String maskAccountNumber(String accountNumber) {
        if (String.isBlank(accountNumber)) {
            return '****';
        }

        String cleaned = accountNumber.trim();

        if (cleaned.length() <= 4) {
            return '****' + cleaned;
        }

        return '****' + cleaned.right(4);
    }

    private static String getChildText(DOM.XMLNode parentNode, String childName, String namespace) {
        DOM.XMLNode child = parentNode.getChildElement(childName, namespace);
        return child == null ? '' : child.getText();
    }

    private static String formatDateDDMMYYYY(Datetime dt) {
        return pad2(dt.day()) + '/' + pad2(dt.month()) + '/' + String.valueOf(dt.year());
    }

    private static String formatTimeHHMMSS(Datetime dt) {
        return pad2(dt.hour()) + ':' + pad2(dt.minute()) + ':' + pad2(dt.second());
    }

    private static String pad2(Integer value) {
        return value < 10 ? '0' + String.valueOf(value) : String.valueOf(value);
    }

    private static String nullSafe(String value) {
        return value == null ? '' : value;
    }
}