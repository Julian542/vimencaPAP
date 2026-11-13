/**
 * @description       : an adapted version of wsConsultaProdFinPFPJ to Fin Serv Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             :
 * @last modified on  : 29-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
public with sharing class wsConsultaProdFinPFPJ_FSC {
    public static HttpRequest requestInfo;

    /* Funcion que realiza el envio de la consulta al CORE por POST */
    public static HttpResponse consultaProdFinPost(String body, String action) {

        System.debug(' on wsConsultaProdFinPFPJ_FSC.consultaProdFinPost() ');
        System.debug(' body: ' + body);
        System.debug(' action: ' + action);

        /* Clase encargada del envio y recepcion*/
        Http http = new Http();

        /* Nueva petición HTTP -> Se rellenan las cabezeras necesárias y el cuerpo pasado por parametro */
        HttpRequest request = new HttpRequest();
        request.setEndpoint(Label.EndpointWs);
        request.setMethod('POST');
        request.setTimeout(120000);
        request.setHeader('SoapAction', 'http://crmintegration.local/' + action);
        request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        request.setBody(body);
        requestInfo = request;

        /* Se envía y recoje la petición */
        HttpResponse response = http.send(request);

        /* Se devuelve la respuesta */
        return response;
    }

    /* Funcion que genera el XML de envio */
    public static DOM.Document parserToWsXML(List<String> parameters) {

        /* Fecha cuando se realiza la integración */
        Datetime actualTime = Datetime.now();

        /* Datos del usuario que lanza la integración */
        User user = [SELECT Id, Username, USE_Codigo__c, USE_Direccion_Oficina__c FROM User WHERE ID = :UserInfo.getUserId()];

        /* Se el objeto DOM del XML a enviar */
        DOM.Document doc = new DOM.Document();

        /*
            <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
            <SOAP-ENV:Header>
            <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
            <wsse:UsernameToken wsu:Id="UsernameToken-XXDARIO">
            <wsse:Username></wsse:Username>
            <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText"></wsse:Password>
            </wsse:UsernameToken>
            </wsse:Security>
            </SOAP-ENV:Header>
            <SOAP-ENV:Body>
            <HTTPSleepTime xmlns="http://crmintegration.local/">30000</HTTPSleepTime>
            <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Funcion%20General%20IO">
            <Function>
            <FunctionName></FunctionName>
            <UserName></UserName>
            <RequestDate></RequestDate>
            <RequestTime></RequestTime>
            <Terminal></Terminal>
            <Channel></Channel>
            <Version></Version>
            <Parameter01></Parameter01>
            <Parameter02></Parameter02>
            <Parameter03></Parameter03>
            <Parameter04></Parameter04>
            <Parameter05></Parameter05>
            </Function>
            </ListOfBREAIFuncionGeneral>
            </SOAP-ENV:Body>
            </SOAP-ENV:Envelope>
        */

        /* BASE */
        Dom.XmlNode envelope = doc.createRootElement('SOAP-ENV:Envelope', null, null);
        envelope.setNamespace('SOAP-ENV', 'http://schemas.xmlsoap.org/soap/envelope/');
        envelope.setNamespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance');
        envelope.setNamespace('xsd', 'http://www.w3.org/2001/XMLSchema');

        /* HEADER */
        Dom.XmlNode header = envelope.addChildElement('SOAP-ENV:Header', null, null);
        Dom.XmlNode security = header.addChildElement('wsse:Security', null, null);
        security.setNamespace('wsse', 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd');
        security.setNamespace('wsu', 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd');
        Dom.XmlNode usernameToken = security.addChildElement('wsse:UsernameToken', null, null);
        usernameToken.setAttribute('wsu:Id', 'UsernameToken-XXDARIO');
        Dom.XmlNode username = usernameToken.addChildElement('wsse:Username', null, null).addTextNode(Label.Int_Username);
        Dom.XmlNode password = usernameToken.addChildElement('wsse:Password', null, null);
        password.setAttribute('Type', 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText');
        password.addTextNode(Label.Int_Password);

        /* BODY */
        Dom.XmlNode body = envelope.addChildElement('SOAP-ENV:Body', null, null);
        Dom.XmlNode hTTPSleepTime = body.addChildElement('HTTPSleepTime', null, null);
        hTTPSleepTime.setNamespace('', 'http://crmintegration.local/');
        Dom.XmlNode listOfBREAIFuncionGeneral = body.addChildElement('ListOfBREAIFuncionGeneral', null, null);
        listOfBREAIFuncionGeneral.setNamespace('', 'http://www.siebel.com/xml/BR%20EAI%20Funcion%20General%20IO');
        Dom.XmlNode function = listOfBREAIFuncionGeneral.addChildElement('Function', null, null);

        /* Se rellena el nodo con los datos de la cuenta */
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
        function.addChildElement('Parameter04', null, null).addTextNode(user.USE_Codigo__c == NULL ? '' : user.USE_Codigo__c);
        function.addChildElement('Parameter05', null, null).addTextNode(user.USE_Direccion_Oficina__c == NULL ? '' : user.USE_Direccion_Oficina__c);

        /* Debug log esta limitado, se divide en porciones de 300 caracteres */
        /*
            String ALL_XML= doc.toXmlString().remove('<?xml version="1.0" encoding="UTF-8"?>');
            for (Integer i = 0; i < ALL_XML.length(); i=i+300) {
                Integer iEffectiveEnd = (i+300 > (ALL_XML.length()) ? ALL_XML.length() : i+300);
                System.debug(ALL_XML.substring(i,iEffectiveEnd));
            }
        */

        /* Se devuelve la variable DOM con los datos a enviar */
        return doc;
    }

    /* Metodo encargado de hacer el Callout y recoger la información necesaria*/
    @AuraEnabled
    public static String consultaProdFinPFPJ(Id idpfpj) {

        System.debug(' on wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ() ');
        System.debug(' idpfpj: ' + idpfpj);

        /* Cuenta Personal o fisica, de la que se van a enviar los datos */
        Account pfpj;

        /* Lista de parametros del XML */
        List<String> parameters = new List<String>();

        /* Variable que almacena la peticion en un XML */
        String requestXML;

        /* Se obtienen los IDs de los recordTypes de 'Persona Física' y 'Persona Jurídica'*/
        Id rtpj = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Personas_Juridicas').getRecordTypeId();
        Id rtpf = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

        /* Variables para almacenar la respuesta recibida por el WS */
        HttpResponse respuesta;
        DOM.Document respuestaXML;
        Dom.XMLNode returnValue;

        /* Se consulta que exista una cuenta con el Id recibido */
        try {
            pfpj = [
                SELECT Id, ACC_CIF__c, ACC_TipoIdentificacion__c, ACC_NumIdentificacion__c, ACC_RNC__c, RecordTypeId
                FROM Account
                WHERE Id = :idpfpj
            ];
        } catch (Exception e) {
            System.debug('La persona física o jurídica no existe en Salesforce: \n' + e.getMessage());
            return 'La persona física o jurídica no existe en Salesforce: \n' + e.getMessage();
        }

        /* Si es persona fisica se envia el "ACC_NumIdentificacion__c" y el tipo del campo 'ACC_TipoIdentificacion__c */
        if (pfpj.RecordTypeId == rtpf) {
            parameters.add('ConsultaProdFinPF');
            parameters.add(pfpj.ACC_NumIdentificacion__c);
            parameters.add(pfpj.ACC_TipoIdentificacion__c == NULL ? '' : pfpj.ACC_TipoIdentificacion__c.Equals('Cédula') ? 'Cedula' : pfpj.ACC_TipoIdentificacion__c);
        }

        /* Si es persona juridica se envia el "ACC_RNC__c" y como tipo RNC fijo */
        if (pfpj.RecordTypeId == rtpj) {
            parameters.add('ConsultaProdFinPJ');
            parameters.add(pfpj.ACC_RNC__c);
            parameters.add('RNC');
        }

        /* En los dos casos se envia el CIF */
        parameters.add(pfpj.ACC_CIF__c);

        /* Se obtiene el XML de envio */
        requestXML = parserToWsXML(parameters).toXmlString().remove('<?xml version="1.0" encoding="UTF-8"?>');

        /* Se realiza el envio de la petición */
        try {
            /* Se realiza la llamada al WS de consulta de productos*/
            respuesta = ConsultaProdFinPost(requestXML, parameters[0]);

            /*
                String ALL_XML= respuesta.getBodyDocument().toXmlString().remove('<?xml version="1.0" encoding="UTF-8"?>');
                for (Integer i = 0; i < ALL_XML.length(); i=i+300) {
                    Integer iEffectiveEnd = (i+300 > (ALL_XML.length()) ? ALL_XML.length() : i+300);
                    System.debug(ALL_XML.substring(i,iEffectiveEnd));
                }
            */

            /*<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
                <soap:Header>
                <Data></Data>
                </soap:Header>
                <soap:Body>
                <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20Response%20IO">
                <Result>
                <ErrorCode>000</ErrorCode>
                <ErrorText>TRANSACCION PROCESADA</ErrorText>
                <Producto>
                <NumCuenta>2401322114</NumCuenta>
                <Producto>219</Producto>
                <CodigoProducto>219</CodigoProducto>
                <Estado>ACTIVA</Estado>
                <FechaApertura>06/16/2008</FechaApertura>
                <FechaCancelacion>10/15/2021</FechaCancelacion>
                <FechaReapertura>03/27/2018</FechaReapertura>
                <LineaProducto>Cuentas de ahorro</LineaProducto>
                <SaldoRD>3.54</SaldoRD>
                <SaldoUS>2.27</SaldoUS>
                <TipoVinculacion>Principal</TipoVinculacion>
                <DetalleTitular>
                <NumDocumento></NumDocumento>
                <Principal>Y/N</Principal>
                </DetalleTitular>
                <Titulares>Principal BELQUI ALBANIA PIMENTEL</Titulares>
                </Producto>
                </Result>
                </ListOfBREAIFuncionGeneral>
                </soap:Body>
                </soap:Envelope>
            */

            /* Si el 'Status' es 200, no ha sucedido ningún error*/
            if (respuesta.getStatusCode() == 200) {
                /* Namespace comun que se utiliza en todo el xml */
                String namespace;
                if (pfpj.RecordTypeId == rtpj) {
                    namespace = 'http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PJ%20Response%20IO';
                }
                if (pfpj.RecordTypeId == rtpf) {
                    namespace = 'http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20VBC%20Response%20IO';
                }

                /* Solo se procesa el cuerpo de la petición, la cabezera se ignora */
                respuestaXML = respuesta.getBodyDocument();

                returnValue = respuestaXML.getRootElement();
                returnValue = returnValue.getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/');
                returnValue = returnValue.getChildElement('ListOfBREAIFuncionGeneral', namespace);

                /* Se accede hasta el apartado de result */
                returnValue = returnValue.getChildElement('Result', namespace);

                /* Se almacena el ErroCorde, ErrorText y los datos de las cuentas financieras a crear */
                String errorCode = returnValue.getChildElement('ErrorCode', namespace).getText();
                String errorText = returnValue.getChildElement('ErrorText', namespace).getText();
                List<Dom.XMLNode> productsXML = returnValue.getChildren();

                List<FinServ__FinancialAccount__c> newAssets = new List<FinServ__FinancialAccount__c>();

                /* Si se ha devuelto un codigo de error o mensaje no controlado, no se continua procesando */
                if (!errorCode.Equals('000') || !errorText.Equals('TRANSACCION PROCESADA')) {
                    System.debug('Ha sucedido un error en la integración: ' + 'Code: ' + errorCode + ' | Text: ' + errorText);
                    return 'Ha sucedido un error en la integración:' + '\nCode: ' + errorCode + '\nText: ' + errorText;
                }

                /* Si no hay error, se procesan los productos */
                else {
                    Set<String> setNumerosCuenta = new Set<String>();
                    Map<String, String> assetProductMap = new Map<String, String>();

                    for (Dom.XMLNode productXML : productsXML) {
                        if (productXML.getName().Equals('Producto') && errorCode.Equals('000') && errorText.Equals('TRANSACCION PROCESADA')) {
                            setNumerosCuenta.add(productXML.getChildElement('NumCuenta', namespace).getText());
                            assetProductMap.put(productXML.getChildElement('NumCuenta', namespace).getText(), productXML.getChildElement('CodigoProducto', namespace).getText());
                        }
                    }

                    Map<String, FinServ__FinancialAccount__c> assetMap = new Map<String, FinServ__FinancialAccount__c>();

                    for (FinServ__FinancialAccount__c actualAsset : [
                        SELECT FinServ__FinancialAccountNumber__c, FinServ__PrimaryOwner__c
                        FROM FinServ__FinancialAccount__c
                        WHERE FinServ__FinancialAccountNumber__c IN :setNumerosCuenta
                    ]) {
                        assetMap.put(actualAsset.FinServ__FinancialAccountNumber__c, actualAsset);
                    }

                    Map<String, Matriz_de_producto__c> productMap = new Map<String, Matriz_de_producto__c>();

                    for (Matriz_de_producto__c prod : [
                        SELECT Id, PRO_Codigo_de_producto__c, PRO_Nombre_de_linea_de_producto__c
                        FROM Matriz_de_producto__c
                        WHERE PRO_Codigo_de_producto__c IN :assetProductMap.values()
                        AND PROD_Producto_principal__c = NULL
                    ]) {
                        productMap.put(prod.PRO_Codigo_de_producto__c, prod);
                    }

                    String numCuenta = '';
                    String numProducto = '';

                    for (Dom.XMLNode productXML : productsXML) {
                        if (productXML.getName() == 'Producto') {
                            FinServ__FinancialAccount__c auxAsset = null;
                            Matriz_de_producto__c auxProduct = null;

                            numCuenta = productXML.getChildElement('NumCuenta', namespace).getText();
                            numProducto = productXML.getChildElement('CodigoProducto', namespace).getText();

                            // Comprobamos si ya existe el FinServ__FinancialAccount__c
                            if (assetMap.containsKey(numCuenta)) {
                                auxAsset = assetMap.get(numCuenta);
                            } else {
                                auxAsset = new FinServ__FinancialAccount__c();
                            }

                            // Se rellena/actualiza el asset
                            auxAsset.Name = numCuenta;
                            auxAsset.FinServ__FinancialAccountNumber__c = numCuenta;

                            // Si el producto indicado no existe, no se añade
                            if (productMap.containsKey(numProducto)) {
                                auxAsset.FIN_Producto__c = productMap.get(numProducto).Id;
                            }

                            auxAsset.FinServ__Status__c = productXML.getChildElement('Estado', namespace).getText();
                            auxAsset.FinServ__OpenDate__c = productXML.getChildElement('FechaApertura', namespace).getText() == '' ? NULL : generalUtils.parseStringtoDate(productXML.getChildElement('FechaApertura', namespace).getText());
                            auxAsset.FinServ__CloseDate__c = productXML.getChildElement('FechaCancelacion', namespace).getText() == '' ? NULL : generalUtils.parseStringtoDate(productXML.getChildElement('FechaCancelacion', namespace).getText());
                            auxAsset.FIN_Fecha_de_reapertura__c = productXML.getChildElement('FechaReapertura', namespace).getText() == '' ? NULL : generalUtils.parseStringtoDate(productXML.getChildElement('FechaReapertura', namespace).getText());
                            auxAsset.FIN_Linea_de_producto__c = productXML.getChildElement('LineaProducto', namespace).getText();
                            auxAsset.FinServ__Balance__c = Decimal.valueOf(productXML.getChildElement('SaldoRD', namespace).getText());
                            auxAsset.FIN_Titular_de_la_cuenta__c = productXML.getChildElement('Titulares', namespace).getText();
                            auxAsset.FinServ__PrimaryOwner__c = idpfpj;
                            auxAsset.RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByName().get(auxAsset.FIN_Linea_de_producto__c).getRecordTypeId();

                            /* Se añade a la lista de nuevos assets */
                            newAssets.add(auxAsset);
                        }
                    }

                    //VERSIÓN ANTIGUA - Puede fallar por límites de SOQL
                    /* Se recorren todos los nodos por debajo de Result
                       for (Dom.XMLNode productXML : productsXML){

                           /* Se recojen los productos y si no ha habido error en 'ErrorCode' y 'ErrorText'
                           if (productXML.getName().Equals('Producto') && errorCode.Equals('000') && ErrorText.Equals('TRANSACCION PROCESADA')){

                                Solo nos se procesan los productos en los que el cliente sea PRINCIPAL
                                if(productXML.getChildElement('TipoVinculacion', namespace).getText().Equals('PRINCIPAL')){

                                Se comprueba si ya existe el asset (No puede haber 2 cuentas financieras con el mismo NºCuenta y Código de producto) -- DESACTIVADO HASTA CARGA CATALOGO
                                 List<Asset> new_asset = [SELECT Id FROM Asset WHERE ASE_N_de_cuenta__c =:productXML.getChildElement('NumCuenta', namespace).getText() and ASE_Producto__r.PRO_Codigo_de_producto__c = :productXML.getChildElement('CodigoProducto',namespace).getText()];
                                List<Asset> new_asset = [SELECT Id FROM Asset WHERE ASE_N_de_cuenta__c =:productXML.getChildElement('NumCuenta', namespace).getText()];
                                List<Matriz_de_producto__c> producto = [SELECT Id,PRO_Nombre_de_linea_de_producto__c FROM Matriz_de_producto__c WHERE PRO_Codigo_de_producto__c = :productXML.getChildElement('CodigoProducto',namespace).getText() AND PROD_Producto_principal__c=null];

                                Si no existe, se genera un asset nuevo
                                if(new_asset == NULL || new_asset.size() == 0) new_asset = new List<Asset>{new Asset()};

                                Se rellena/actualiza el asset
                                new_asset[0].Name = productXML.getChildElement('NumCuenta', namespace).getText();
                                new_asset[0].ASE_N_de_cuenta__c = productXML.getChildElement('NumCuenta', namespace).getText();

                                Si el PRODUCTO indicado no existe, no se añade
                                System.debug('Cosa '+producto[0].PRO_Nombre_de_linea_de_producto__c);
                                System.debug('Cosa2 '+productXML.getChildElement('LineaProducto', namespace).getText());
                                if(producto != null && producto.size() !=0){
                                    new_asset[0].ASE_Producto__c = producto[0].Id;
                                        if(producto[0].PRO_Nombre_de_linea_de_producto__c==null){
                                            producto[0].PRO_Nombre_de_linea_de_producto__c = productXML.getChildElement('LineaProducto', namespace).getText();
                                            producto[0].PRO_Nombre_de_linea_de_producto__c = 'Certificados financieros';
                                        update producto;
                                    }
                                }

                               new_asset[0].ASE_Estado__c = productXML.getChildElement('Estado', namespace).getText();
                               new_asset[0].ASE_Fecha_de_apertura__c = productXML.getChildElement('FechaApertura', namespace).getText() == '' ? NULL : generalUtils.parseStringtoDate(productXML.getChildElement('FechaApertura', namespace).getText());
                               new_asset[0].ASE_Fecha_de_cierre_cancelacion__c = productXML.getChildElement('FechaCancelacion', namespace).getText() == '' ? NULL : generalUtils.parseStringtoDate(productXML.getChildElement('FechaCancelacion', namespace).getText());
                               new_asset[0].ASE_Fecha_de_reapertura__c = productXML.getChildElement('FechaReapertura', namespace).getText() == '' ? NULL : generalUtils.parseStringtoDate(productXML.getChildElement('FechaReapertura', namespace).getText());
                               new_asset[0].ASE_Linea_de_producto__c = productXML.getChildElement('LineaProducto', namespace).getText();
                               new_asset[0].ASE_Saldo_disponible__c = Decimal.valueOf(productXML.getChildElement('SaldoRD', namespace).getText());
                               new_asset[0].ASE_Titular_de_la_cuenta__c = productXML.getChildElement('Titulares', namespace).getText();
                               new_asset[0].AccountId = idpfpj;

                               Se define el RecordType del registro
                               new_asset[0].RecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByName().get(new_asset[0].ASE_Linea_de_producto__c).getRecordTypeId();

                               Se añade a la lista de nuevos assets
                               newAssets.add(new_asset[0]);
                               }
                           }
                       }*/
                }

                /* Se Insertan/Actualizan los registros de Cuentas financieras respecto a lo recibido en la integración */
                upsert newAssets;

                // Agregado por Jhonny Peroza para encolar el llamado a las transacciones relacionadas
                List<Id> accountIds = new List<Id>();

                for (FinServ__FinancialAccount__c acc : newAssets) {
                    if (acc.Id != null) {
                        accountIds.add(acc.Id);
                    }
                }

                if (!accountIds.isEmpty()) {
                    System.enqueueJob(
                        new INT014FinancialTransactionsQueue(accountIds)
                    );
                }

                return '';
            }

            /* Si ha sucedido algun error especifico en el CORE */
            else {
                System.debug('Ha sucedido un error durante la consulta en la integración de Consulta de productos financieros: ' + 'Code: ' + respuesta.getStatusCode() + ' |Message: ' + respuesta.getBody());
                return 'Ha sucedido un error durante la consulta en la integración de Consulta de productos financieros: ' + '\nCode: ' + respuesta.getStatusCode() + '\nMessage: ' + respuesta.getBody();
            }
        }
        /* Si sucede alguna excepcion durante el proceso */
        catch (Exception e) {
            System.debug('Ha sucedido un error no controlado durante la integración de Consulta de productos financieros: ' + e.getMessage() + ' ' + e.getStackTraceString());
            return 'Ha sucedido un error no controlado durante la integración de Consulta de productos financieros:\n' + e.getMessage();
        } finally {
            INTLogger.INTLoggerResult result = INTLogger.logCallout('011', 'ConsultaProdFinPJ', requestInfo, respuesta);
        }
    }

    /* Metodos para llamar la integración de PF/PJ Actualizar pasivas de forma ASINCRONA */
    @future(callout=true)
    public static void futureConsultaProdFin_PF_PJ(Id idpf) {
        consultaProdFinPFPJ(idpf);
    }
}