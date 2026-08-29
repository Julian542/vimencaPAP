/**
 * @description       : an adapted version of wsConsultaProdFinPFPJ to Fin Serv Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             :
 * @last modified on  : 17-04-2026
 * @last modified by  : Jhonny Peroza
**/
@SuppressWarnings('PMD')
public with sharing class wsConsultaProdFinPFPJ_FSC {
    public static HttpRequest requestInfo;

    /* Funcion que realiza el envio de la consulta al CORE por POST */
    public static HttpResponse consultaProdFinPost(String body, String action) {

        System.debug(' on wsConsultaProdFinPFPJ_FSC.consultaProdFinPost() ');
        System.debug(' body: ' + body);
        System.debug(' action: ' + action);

        Http http = new Http();

        HttpRequest request = new HttpRequest();
        request.setEndpoint(Label.EndpointWs);
        request.setMethod('POST');
        request.setTimeout(120000);
        request.setHeader('SoapAction', 'http://crmintegration.local/' + action);
        request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        request.setBody(body);
        requestInfo = request;

        HttpResponse response = http.send(request);
        return response;
    }

    /* Funcion que genera el XML de envio */
    public static DOM.Document parserToWsXML(List<String> parameters) {

        Datetime actualTime = Datetime.now();

        User user = [
            SELECT Id, Username, USE_Codigo__c, USE_Direccion_Oficina__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        DOM.Document doc = new DOM.Document();

        Dom.XmlNode envelope = doc.createRootElement('SOAP-ENV:Envelope', null, null);
        envelope.setNamespace('SOAP-ENV', 'http://schemas.xmlsoap.org/soap/envelope/');
        envelope.setNamespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance');
        envelope.setNamespace('xsd', 'http://www.w3.org/2001/XMLSchema');

        Dom.XmlNode header = envelope.addChildElement('SOAP-ENV:Header', null, null);
        Dom.XmlNode security = header.addChildElement('wsse:Security', null, null);
        security.setNamespace('wsse', 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd');
        security.setNamespace('wsu', 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd');

        Dom.XmlNode usernameToken = security.addChildElement('wsse:UsernameToken', null, null);
        usernameToken.setAttribute('wsu:Id', 'UsernameToken-XXDARIO');
        usernameToken.addChildElement('wsse:Username', null, null).addTextNode(Label.Int_Username);

        Dom.XmlNode password = usernameToken.addChildElement('wsse:Password', null, null);
        password.setAttribute('Type', 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText');
        password.addTextNode(Label.Int_Password);

        Dom.XmlNode body = envelope.addChildElement('SOAP-ENV:Body', null, null);
        Dom.XmlNode hTTPSleepTime = body.addChildElement('HTTPSleepTime', null, null);
        hTTPSleepTime.setNamespace('', 'http://crmintegration.local/');

        Dom.XmlNode listOfBREAIFuncionGeneral = body.addChildElement('ListOfBREAIFuncionGeneral', null, null);
        listOfBREAIFuncionGeneral.setNamespace('', 'http://www.siebel.com/xml/BR%20EAI%20Funcion%20General%20IO');

        Dom.XmlNode function = listOfBREAIFuncionGeneral.addChildElement('Function', null, null);

        String functionName = (parameters != null && parameters.size() > 0 && parameters[0] != null) ? parameters[0] : '';
        String parameter01  = (parameters != null && parameters.size() > 1 && parameters[1] != null) ? parameters[1] : '';
        String parameter02  = (parameters != null && parameters.size() > 2 && parameters[2] != null) ? parameters[2] : '';
        String parameter03  = (parameters != null && parameters.size() > 3 && parameters[3] != null) ? parameters[3] : '';

        function.addChildElement('FunctionName', null, null).addTextNode(functionName);
        function.addChildElement('UserName', null, null).addTextNode(user.Username);
        function.addChildElement('RequestDate', null, null).addTextNode(((actualTime.day() < 10) ? '0' : '') + actualTime.day() + '/' + ((actualTime.month() < 10) ? '0' : '') + actualTime.month() + '/' + actualTime.year());
        function.addChildElement('RequestTime', null, null).addTextNode(((actualTime.hour() < 10) ? '0' : '') + actualTime.hour() + ':' + ((actualTime.minute() < 10) ? '0' : '') + actualTime.minute() + ':' + ((actualTime.second() < 10) ? '0' : '') + actualTime.second());
        function.addChildElement('Terminal', null, null).addTextNode('0.0.0.0');
        function.addChildElement('Channel', null, null).addTextNode('SALESFORCE');
        function.addChildElement('Version', null, null).addTextNode('1');
        function.addChildElement('Parameter01', null, null).addTextNode(parameter01);
        function.addChildElement('Parameter02', null, null).addTextNode(parameter02);
        function.addChildElement('Parameter03', null, null).addTextNode(parameter03);
        function.addChildElement('Parameter04', null, null).addTextNode(user.USE_Codigo__c == null ? '' : user.USE_Codigo__c);
        function.addChildElement('Parameter05', null, null).addTextNode(user.USE_Direccion_Oficina__c == null ? '' : user.USE_Direccion_Oficina__c);

        return doc;
    }

    /* Metodo para homologar la linea de producto del CORE al DeveloperName del Record Type FSC */
    private static String getFscFinancialAccountRecordTypeDeveloperName(String coreProductLine) {
        System.debug(' on wsConsultaProdFinPFPJ_FSC.getFscFinancialAccountRecordTypeDeveloperName() ');
        System.debug(' coreProductLine: ' + coreProductLine);

        String normalizedLine = coreProductLine == null ? '' : coreProductLine.trim().toUpperCase();

        if (normalizedLine == 'CUENTAS CORRIENTES') {
            return 'CheckingAccount';
        }
        if (normalizedLine == 'CUENTAS AHORRO' || normalizedLine == 'CUENTAS DE AHORRO') {
            return 'SavingsAccount';
        }
        if (normalizedLine == 'TARJETAS DE CREDITO' || normalizedLine == 'TARJETAS DE CRÉDITO') {
            return 'CreditCard';
        }
        if (normalizedLine == 'PRESTAMOS' || normalizedLine == 'PRÉSTAMOS') {
            return 'LoanAccount';
        }
        if (normalizedLine == 'CERTIFICADOS FINANCIEROS') {
            return 'InvestmentAccount';
        }
        if (normalizedLine == 'LINEAS DE CREDITO' || normalizedLine == 'LÍNEAS DE CRÉDITO') {
            return 'HELOC';
        }
        if (normalizedLine == 'CREDITOS HIPOTECARIOS' || normalizedLine == 'CRÉDITOS HIPOTECARIOS') {
            return 'Mortgage';
        }
        if (normalizedLine == 'CREDITOS AUTOMOTRIZ' || normalizedLine == 'CRÉDITOS AUTOMOTRIZ') {
            return 'AutoLoan';
        }

        return null;
    }

    /* Metodo encargado de hacer el Callout y recoger la información necesaria*/
    @AuraEnabled
    public static String consultaProdFinPFPJ(Id idpfpj) {

        System.debug(' on wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ() ');
        System.debug(' idpfpj: ' + idpfpj);

        Account pfpj;
        List<String> parameters = new List<String>();
        String requestXML;
        String action = '';
        String namespace = '';

        Map<String, Schema.RecordTypeInfo> accountRtByDeveloperName =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();

        Id rtpj = accountRtByDeveloperName.containsKey('Personas_Juridicas')
            ? accountRtByDeveloperName.get('Personas_Juridicas').getRecordTypeId()
            : null;

        Id rtpf = accountRtByDeveloperName.containsKey('PersonAccount')
            ? accountRtByDeveloperName.get('PersonAccount').getRecordTypeId()
            : null;

        HttpResponse respuesta;
        DOM.Document respuestaXML;
        Dom.XMLNode returnValue;

        try {
            pfpj = [
                SELECT Id,
                       ACC_CIF__c,
                       ACC_TipoIdentificacion__c,
                       ACC_NumIdentificacion__c,
                       ACC_RNC__c,
                       RecordTypeId,
                       RecordType.DeveloperName,
                       RecordType.Name,
                       IsPersonAccount
                FROM Account
                WHERE Id = :idpfpj
            ];
        } catch (Exception e) {
            System.debug('La persona física o jurídica no existe en Salesforce: \n' + e.getMessage());
            return 'La persona física o jurídica no existe en Salesforce: \n' + e.getMessage();
        }

        String rtDeveloperName = pfpj.RecordType == null ? '' : pfpj.RecordType.DeveloperName;
        String rtName = pfpj.RecordType == null ? '' : pfpj.RecordType.Name;
        String rtText = (rtDeveloperName + ' ' + rtName).toUpperCase();

        Boolean isPersonaFisica = pfpj.IsPersonAccount || pfpj.RecordTypeId == rtpf || rtDeveloperName == 'PersonAccount';
        Boolean isPersonaJuridica = pfpj.RecordTypeId == rtpj || !String.isBlank(pfpj.ACC_RNC__c) || rtText.contains('JUR');

        if (isPersonaFisica) {
            action = 'ConsultaProdFinPF';
            namespace = 'http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20VBC%20Response%20IO';

            parameters.add(action);
            parameters.add(pfpj.ACC_NumIdentificacion__c);
            parameters.add(
                pfpj.ACC_TipoIdentificacion__c == null
                    ? ''
                    : pfpj.ACC_TipoIdentificacion__c.equals('Cédula')
                        ? 'Cedula'
                        : pfpj.ACC_TipoIdentificacion__c
            );
            parameters.add(pfpj.ACC_CIF__c);
        } else if (isPersonaJuridica) {
            action = 'ConsultaProdFinPJ';
            namespace = 'http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PJ%20Response%20IO';

            parameters.add(action);
            parameters.add(pfpj.ACC_RNC__c);
            parameters.add('RNC');
            parameters.add(pfpj.ACC_CIF__c);
        } else {
            System.debug('RecordType no soportado. AccountId: ' + idpfpj + ' RecordTypeId: ' + pfpj.RecordTypeId + ' DeveloperName: ' + rtDeveloperName + ' Name: ' + rtName);
            return 'RecordType no soportado para consulta de productos financieros.';
        }

        requestXML = parserToWsXML(parameters).toXmlString().remove('<?xml version="1.0" encoding="UTF-8"?>');

        try {
            respuesta = consultaProdFinPost(requestXML, action);

            if (respuesta.getStatusCode() == 200) {
                respuestaXML = respuesta.getBodyDocument();

                returnValue = respuestaXML.getRootElement();
                returnValue = returnValue.getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/');

                if (returnValue == null) {
                    return 'Ha sucedido un error durante la consulta en la integración de Consulta de productos financieros: no se encontró el Body en la respuesta del servicio.';
                }

                returnValue = returnValue.getChildElement('ListOfBREAIFuncionGeneral', namespace);

                if (returnValue == null) {
                    return 'Ha sucedido un error durante la consulta en la integración de Consulta de productos financieros: no se encontró ListOfBREAIFuncionGeneral en la respuesta del servicio.';
                }

                returnValue = returnValue.getChildElement('Result', namespace);

                if (returnValue == null) {
                    return 'Ha sucedido un error durante la consulta en la integración de Consulta de productos financieros: no se encontró Result en la respuesta del servicio.';
                }

                String errorCode = returnValue.getChildElement('ErrorCode', namespace) == null ? '' : returnValue.getChildElement('ErrorCode', namespace).getText();
                String errorText = returnValue.getChildElement('ErrorText', namespace) == null ? '' : returnValue.getChildElement('ErrorText', namespace).getText();
                List<Dom.XMLNode> productsXML = returnValue.getChildren();

                List<FinServ__FinancialAccount__c> newAssets = new List<FinServ__FinancialAccount__c>();
                List<Id> financialAccountIdsForQueue = new List<Id>();

                if (errorCode == '9709' || errorText.toUpperCase().contains('DO NOT HAVE ANY PRODUCT')) {
                    System.debug('No se encontraron productos financieros en el CORE. Code: ' + errorCode + ' | Text: ' + errorText);
                    return 'NO_PRODUCTS_FOUND';
                }

                if (!errorCode.equals('000') || !errorText.equals('TRANSACCION PROCESADA')) {
                    System.debug('Ha sucedido un error en la integración: ' + 'Code: ' + errorCode + ' | Text: ' + errorText);
                    return 'Ha sucedido un error en la integración:' + '\nCode: ' + errorCode + '\nText: ' + errorText;
                } else {
                    Set<String> setNumerosCuenta = new Set<String>();
                    Map<String, String> assetProductMap = new Map<String, String>();

                    for (Dom.XMLNode productXML : productsXML) {
                        if (productXML.getName().equals('Producto') && errorCode.equals('000') && errorText.equals('TRANSACCION PROCESADA')) {
                            String numeroCuentaCore = getChildText(productXML, 'NumCuenta', namespace);
                            String codigoProductoCore = getChildText(productXML, 'CodigoProducto', namespace);

                            numeroCuentaCore = String.isBlank(numeroCuentaCore) ? '' : numeroCuentaCore.trim();
                            codigoProductoCore = String.isBlank(codigoProductoCore) ? '' : codigoProductoCore.trim();

                            if (String.isNotBlank(numeroCuentaCore)) {
                                setNumerosCuenta.add(numeroCuentaCore);
                                assetProductMap.put(numeroCuentaCore, codigoProductoCore);
                            }
                        }
                    }

                    if (setNumerosCuenta.isEmpty()) {
                        System.debug('No se encontraron productos financieros en el CORE para la cuenta: ' + idpfpj);
                        return 'NO_PRODUCTS_FOUND';
                    }

                    Map<String, FinServ__FinancialAccount__c> assetMap = new Map<String, FinServ__FinancialAccount__c>();

                    for (FinServ__FinancialAccount__c actualAsset : [
                        SELECT Id,
                               Name,
                               OwnerId,
                               FIN_Ejecutivo__c,
                               FinServ__FinancialAccountNumber__c,
                               FinServ__PrimaryOwner__c,
                               FIN_Producto__c,
                               FinServ__Status__c,
                               FinServ__OpenDate__c,
                               FinServ__CloseDate__c,
                               FIN_Fecha_de_reapertura__c,
                               FIN_Linea_de_producto__c,
                               FinServ__Balance__c,
                               FIN_Titular_de_la_cuenta__c,
                               RecordTypeId
                        FROM FinServ__FinancialAccount__c
                        WHERE FinServ__FinancialAccountNumber__c IN :setNumerosCuenta
                        AND FinServ__PrimaryOwner__c = :idpfpj
                        ORDER BY CreatedDate ASC
                    ]) {
                        String normalizedAccountNumber = actualAsset.FinServ__FinancialAccountNumber__c == null
                            ? ''
                            : actualAsset.FinServ__FinancialAccountNumber__c.trim();

                        String mapKey = buildFinancialAccountKey(actualAsset.FinServ__PrimaryOwner__c, normalizedAccountNumber);

                        if (!assetMap.containsKey(mapKey)) {
                            System.debug('wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ | Producto existente encontrado | mapKey: ' + mapKey + ' | Id: ' + actualAsset.Id);
                            assetMap.put(mapKey, actualAsset);
                        }
                    }

                    Map<String, Matriz_de_producto__c> productMap = new Map<String, Matriz_de_producto__c>();

                    for (Matriz_de_producto__c prod : [
                        SELECT Id,
                               PRO_Codigo_de_producto__c,
                               PRO_Nombre_de_linea_de_producto__c
                        FROM Matriz_de_producto__c
                        WHERE PRO_Codigo_de_producto__c IN :assetProductMap.values()
                        AND PROD_Producto_principal__c = NULL
                    ]) {
                        productMap.put(prod.PRO_Codigo_de_producto__c, prod);
                    }

                    Map<String, Schema.RecordTypeInfo> financialAccountRtByDeveloperName =
                        Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName();

                    Map<String, FinServ__FinancialAccount__c> assetsToUpsertByKey = new Map<String, FinServ__FinancialAccount__c>();

                    for (Dom.XMLNode productXML : productsXML) {
                        if (productXML.getName() == 'Producto') {
                            FinServ__FinancialAccount__c existingAsset = null;
                            FinServ__FinancialAccount__c auxAsset = new FinServ__FinancialAccount__c();

                            String numCuenta = getChildText(productXML, 'NumCuenta', namespace);
                            String numProducto = getChildText(productXML, 'CodigoProducto', namespace);

                            numCuenta = String.isBlank(numCuenta) ? '' : numCuenta.trim();
                            numProducto = String.isBlank(numProducto) ? '' : numProducto.trim();

                            if (String.isBlank(numCuenta)) {
                                System.debug('wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ | Producto omitido porque NumCuenta viene vacío.');
                                continue;
                            }

                            String assetKey = buildFinancialAccountKey(idpfpj, numCuenta);

                            System.debug('wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ | Procesando producto CORE | assetKey: ' + assetKey);

                            if (assetMap.containsKey(assetKey)) {
                                existingAsset = assetMap.get(assetKey);
                                auxAsset.Id = existingAsset.Id;
                                System.debug('wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ | Se evaluará actualización de producto existente | Id: ' + auxAsset.Id);
                            } else if (assetsToUpsertByKey.containsKey(assetKey)) {
                                System.debug('wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ | Producto repetido en respuesta CORE. Se omite repetido | key: ' + assetKey);
                                continue;
                            } else {
                                System.debug('wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ | Se creará nuevo producto financiero para cuenta: ' + numCuenta);
                            }

                            auxAsset.Name = numCuenta;
                            auxAsset.FinServ__FinancialAccountNumber__c = numCuenta;

                            if (productMap.containsKey(numProducto)) {
                                auxAsset.FIN_Producto__c = productMap.get(numProducto).Id;
                            }

                            auxAsset.FinServ__Status__c = getChildText(productXML, 'Estado', namespace);
                            auxAsset.FinServ__OpenDate__c = parseCoreDate(getChildText(productXML, 'FechaApertura', namespace));
                            auxAsset.FinServ__CloseDate__c = parseCoreDate(getChildText(productXML, 'FechaCancelacion', namespace));
                            auxAsset.FIN_Fecha_de_reapertura__c = parseCoreDate(getChildText(productXML, 'FechaReapertura', namespace));
                            auxAsset.FIN_Linea_de_producto__c = getChildText(productXML, 'LineaProducto', namespace);
                            auxAsset.FinServ__Balance__c = parseCoreDecimal(getChildText(productXML, 'SaldoRD', namespace));
                            auxAsset.FIN_Titular_de_la_cuenta__c = getChildText(productXML, 'Titulares', namespace);
                            auxAsset.FinServ__PrimaryOwner__c = idpfpj;

                            String fscRecordTypeDeveloperName = getFscFinancialAccountRecordTypeDeveloperName(
                                getChildText(productXML, 'LineaProducto', namespace)
                            );

                            System.debug(' numCuenta: ' + numCuenta);
                            System.debug(' numProducto: ' + numProducto);
                            System.debug(' lineaProductoCORE: ' + getChildText(productXML, 'LineaProducto', namespace));
                            System.debug(' fscRecordTypeDeveloperName: ' + fscRecordTypeDeveloperName);

                            if (
                                !String.isBlank(fscRecordTypeDeveloperName) &&
                                financialAccountRtByDeveloperName.containsKey(fscRecordTypeDeveloperName)
                            ) {
                                System.debug('RecordType: ' + financialAccountRtByDeveloperName.get(fscRecordTypeDeveloperName).getRecordTypeId());
                                auxAsset.RecordTypeId = financialAccountRtByDeveloperName.get(fscRecordTypeDeveloperName).getRecordTypeId();
                                System.debug('auxAsset.RecordTypeId: ' + auxAsset.RecordTypeId);
                            } else {
                                System.debug('No se encontró RecordType para fscRecordTypeDeveloperName: ' + fscRecordTypeDeveloperName);
                            }

                            if (existingAsset != null && existingAsset.FIN_Ejecutivo__c != null) {
                                auxAsset.FIN_Ejecutivo__c = existingAsset.FIN_Ejecutivo__c;
                            } else {
                                auxAsset.FIN_Ejecutivo__c = UserInfo.getUserId();
                            }

                            if (existingAsset != null && existingAsset.OwnerId != null) {
                                auxAsset.OwnerId = existingAsset.OwnerId;
                            } else {
                                auxAsset.OwnerId = UserInfo.getUserId();
                            }

                            System.debug('wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ | auxAsset.FIN_Ejecutivo__c: ' + auxAsset.FIN_Ejecutivo__c);
                            System.debug('wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ | auxAsset.OwnerId: ' + auxAsset.OwnerId);

                            if (existingAsset == null || hasFinancialAccountChanges(existingAsset, auxAsset)) {
                                assetsToUpsertByKey.put(assetKey, auxAsset);
                            } else {
                                System.debug('wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ | Producto sin cambios. No se hará upsert | Id: ' + existingAsset.Id);

                                if (existingAsset.Id != null) {
                                    financialAccountIdsForQueue.add(existingAsset.Id);
                                }
                            }
                        }
                    }

                    newAssets.addAll(assetsToUpsertByKey.values());
                }

                if (!newAssets.isEmpty()) {
                    System.debug('wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ | Total productos a upsert: ' + newAssets.size());
                    upsert newAssets;
                } else {
                    System.debug('wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ | No hay productos financieros nuevos o modificados para upsert.');
                }

                for (FinServ__FinancialAccount__c acc : newAssets) {
                    if (acc.Id != null) {
                        financialAccountIdsForQueue.add(acc.Id);
                    }
                }

                if (!financialAccountIdsForQueue.isEmpty()) {
                    System.enqueueJob(new INT014FinancialTransactionsQueue(financialAccountIdsForQueue));
                }

                return '';
            } else {
                System.debug('Ha sucedido un error durante la consulta en la integración de Consulta de productos financieros: ' + 'Code: ' + respuesta.getStatusCode() + ' |Message: ' + respuesta.getBody());
                return 'Ha sucedido un error durante la consulta en la integración de Consulta de productos financieros: ' + '\nCode: ' + respuesta.getStatusCode() + '\nMessage: ' + respuesta.getBody();
            }
        } catch (Exception e) {
            System.debug('Ha sucedido un error no controlado durante la integración de Consulta de productos financieros: ' + e.getMessage() + ' ' + e.getStackTraceString());
            return 'Ha sucedido un error no controlado durante la integración de Consulta de productos financieros:\n' + e.getMessage();
        } finally {
            INTLogger.INTLoggerResult result = INTLogger.logCallout('011', 'ConsultaProdFinPJ', requestInfo, respuesta);
        }
    }

    private static String buildFinancialAccountKey(Id ownerId, String accountNumber) {
        String normalizedAccountNumber = String.isBlank(accountNumber) ? '' : accountNumber.trim();
        return String.valueOf(ownerId) + '-' + normalizedAccountNumber;
    }

    private static String getChildText(Dom.XMLNode parentNode, String childName, String namespace) {
        if (parentNode == null || String.isBlank(childName)) {
            return null;
        }

        Dom.XMLNode childNode = parentNode.getChildElement(childName, namespace);

        if (childNode == null) {
            return null;
        }

        return childNode.getText();
    }

    private static Date parseCoreDate(String value) {
        if (String.isBlank(value)) {
            return null;
        }

        return generalUtils.parseStringtoDate(value);
    }

    private static Decimal parseCoreDecimal(String value) {
        if (String.isBlank(value)) {
            return null;
        }

        return Decimal.valueOf(value);
    }

    private static Boolean hasFinancialAccountChanges(
        FinServ__FinancialAccount__c existingAsset,
        FinServ__FinancialAccount__c incomingAsset
    ) {
        if (existingAsset == null || incomingAsset == null) {
            return true;
        }

        if (valuesAreDifferent(existingAsset.Name, incomingAsset.Name)) return true;
        if (valuesAreDifferent(existingAsset.FinServ__FinancialAccountNumber__c, incomingAsset.FinServ__FinancialAccountNumber__c)) return true;
        if (valuesAreDifferent(existingAsset.FinServ__PrimaryOwner__c, incomingAsset.FinServ__PrimaryOwner__c)) return true;
        if (valuesAreDifferent(existingAsset.FIN_Producto__c, incomingAsset.FIN_Producto__c)) return true;
        if (valuesAreDifferent(existingAsset.FinServ__Status__c, incomingAsset.FinServ__Status__c)) return true;
        if (valuesAreDifferent(existingAsset.FinServ__OpenDate__c, incomingAsset.FinServ__OpenDate__c)) return true;
        if (valuesAreDifferent(existingAsset.FinServ__CloseDate__c, incomingAsset.FinServ__CloseDate__c)) return true;
        if (valuesAreDifferent(existingAsset.FIN_Fecha_de_reapertura__c, incomingAsset.FIN_Fecha_de_reapertura__c)) return true;
        if (valuesAreDifferent(existingAsset.FIN_Linea_de_producto__c, incomingAsset.FIN_Linea_de_producto__c)) return true;
        if (valuesAreDifferent(existingAsset.FinServ__Balance__c, incomingAsset.FinServ__Balance__c)) return true;
        if (valuesAreDifferent(existingAsset.FIN_Titular_de_la_cuenta__c, incomingAsset.FIN_Titular_de_la_cuenta__c)) return true;
        if (valuesAreDifferent(existingAsset.RecordTypeId, incomingAsset.RecordTypeId)) return true;
        if (valuesAreDifferent(existingAsset.FIN_Ejecutivo__c, incomingAsset.FIN_Ejecutivo__c)) return true;
        if (valuesAreDifferent(existingAsset.OwnerId, incomingAsset.OwnerId)) return true;

        return false;
    }

    private static Boolean valuesAreDifferent(Object oldValue, Object newValue) {
        if (oldValue == null && newValue == null) {
            return false;
        }

        if (oldValue == null || newValue == null) {
            return true;
        }

        return String.valueOf(oldValue) != String.valueOf(newValue);
    }

    /* Metodos para llamar la integración de PF/PJ Actualizar pasivas de forma ASINCRONA */
    @future(callout=true)
    public static void futureConsultaProdFin_PF_PJ(Id idpf) {
        consultaProdFinPFPJ(idpf);
    }
}