public class wsConsultaProdFinPFPJ {
    public static HttpRequest requestInfo;
    /* Funcion que realiza el envio de la consulta al CORE por POST */
    public static HttpResponse ConsultaProdFinPost(String body, String Action) {
        
        /* Clase encargada del envio y recepcion*/ 
        Http http = new Http();
        
        /* Nueva petición HTTP -> Se rellenan las cabezeras necesárias y el cuerpo pasado por parametro */ 
        HttpRequest request = new HttpRequest();
        request.setEndpoint(Label.EndpointWs);
        request.setMethod('POST');
        request.setTimeout(120000);
        request.setHeader('SoapAction','http://crmintegration.local/' + Action);
        request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        request.setBody(body);
        requestInfo=request;
        /* Se envía y recoje la petición */
        HttpResponse response = http.send(request);
        
        /* Se devuelve la respuesta */
        return response;
    }
    
    /* Funcion que genera el XML de envio */
    public static DOM.Document parserToWsXML(List <String> Parameters){
        
        /* Fecha cuando se realiza la integración */
        Datetime actualTime = Datetime.now();
        
        /* Datos del usuario que lanza la integración */
        User user = [Select Id, Username, USE_Codigo__c, USE_Direccion_Oficina__c from User where ID =:UserInfo.getUserId()];
        
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
        dom.XmlNode Envelope = doc.createRootElement('SOAP-ENV:Envelope', null, null);
        Envelope.setNamespace('SOAP-ENV', 'http://schemas.xmlsoap.org/soap/envelope/');
        Envelope.setNamespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance');
        Envelope.setNamespace('xsd', 'http://www.w3.org/2001/XMLSchema');
        
        /* HEADER */
        dom.XmlNode Header = Envelope.addChildElement('SOAP-ENV:Header', null, null);
        dom.XmlNode Security = Header.addChildElement('wsse:Security', null, null);
        Security.setNamespace('wsse','http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd');
        Security.setNamespace('wsu','http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd');  
        dom.XmlNode UsernameToken = Security.addChildElement('wsse:UsernameToken', null, null);
        UsernameToken.setAttribute('wsu:Id','UsernameToken-XXDARIO');
        dom.XmlNode Username = UsernameToken.addChildElement('wsse:Username', null, null).addTextNode(Label.Int_Username);
        dom.XmlNode Password = UsernameToken.addChildElement('wsse:Password', null, null);
        Password.setAttribute('Type','http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText');
        Password.addTextNode(Label.Int_Password);
        
        /* BODY */
        dom.XmlNode Body = Envelope.addChildElement('SOAP-ENV:Body', null, null);
        dom.XmlNode HTTPSleepTime = Body.addChildElement('HTTPSleepTime', null, null);
        HTTPSleepTime.setNamespace('', 'http://crmintegration.local/');
        dom.XmlNode ListOfBREAIFuncionGeneral = Body.addChildElement('ListOfBREAIFuncionGeneral', null, null);
        ListOfBREAIFuncionGeneral.setNamespace('', 'http://www.siebel.com/xml/BR%20EAI%20Funcion%20General%20IO');
        dom.XmlNode Function = ListOfBREAIFuncionGeneral.addChildElement('Function', null, null);
        /* Se rellena el nodo con los datos de la cuenta */
        Function.addChildElement('FunctionName', null, null).addTextNode(Parameters[0]);
        Function.addChildElement('UserName', null, null).addTextNode(user.Username);
        Function.addChildElement('RequestDate', null, null).addTextNode(((actualTime.day() < 10)? '0' : '') + actualTime.day() + '/' + ((actualTime.month() < 10)? '0' : '') + actualTime.month() + '/' + actualTime.year());
        Function.addChildElement('RequestTime', null, null).addTextNode(((actualTime.hour() < 10)? '0' : '') + actualTime.hour() + ':' + ((actualTime.minute() < 10)? '0' : '') + actualTime.minute() + ':' + ((actualTime.second() < 10)? '0' : '') + actualTime.second());
        Function.addChildElement('Terminal', null, null).addTextNode('0.0.0.0');
        Function.addChildElement('Channel', null, null).addTextNode('SALESFORCE');
        Function.addChildElement('Version', null, null).addTextNode('1');
        Function.addChildElement('Parameter01', null, null).addTextNode(Parameters[1] == NULL ? '' : Parameters[1]);
        Function.addChildElement('Parameter02', null, null).addTextNode(Parameters[2] == NULL ? '' : Parameters[2]);
        Function.addChildElement('Parameter03', null, null).addTextNode(Parameters[3] == NULL ? '' : Parameters[3]);
        Function.addChildElement('Parameter04', null, null).addTextNode(user.USE_Codigo__c == NULL ? '' : user.USE_Codigo__c);
        Function.addChildElement('Parameter05', null, null).addTextNode(user.USE_Direccion_Oficina__c == NULL ? '' : user.USE_Direccion_Oficina__c);
        
        /* Debug log esta limitado, se divide en porciones de 300 caracteres */
        /*String ALL_XML= doc.toXmlString().remove('<?xml version="1.0" encoding="UTF-8"?>');
for (Integer i = 0; i < ALL_XML.length(); i=i+300) {
Integer iEffectiveEnd = (i+300 > (ALL_XML.length()) ? ALL_XML.length() : i+300);
System.debug(ALL_XML.substring(i,iEffectiveEnd));
}*/
        
        /* Se devuelve la variable DOM con los datos a enviar */
        return doc;
    }
    
    /* Metodo encargado de hacer el Callout y recoger la información necesaria*/ 
    @AuraEnabled
    public static String consultaProdFinPFPJ(Id id_pf_pj){
        
        /* Cuenta Personal o fisica, de la que se van a enviar los datos */
        Account pf_pj;
        
        /* Lista de parametros del XML */
        List <String> Parameters = new List<String>();
        
        /* Variable que almacena la peticion en un XML */
        string requestXML;
        
        /* Se obtienen los IDs de los recordTypes de 'Persona Física' y 'Persona Jurídica'*/
        ID rt_pj  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Personas_Juridicas').getRecordTypeId();
        ID rt_pf  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        /* Variables para almacenar la respuesta recibida por el WS */
        HttpResponse respuesta;
        DOM.Document respuestaXML;
        Dom.XMLNode return_value;
        
        /* Se consulta que exista una cuenta con el Id recibido */
        try{
            pf_pj = [Select Id, ACC_CIF__c, ACC_TipoIdentificacion__c, ACC_NumIdentificacion__c, ACC_RNC__c, RecordTypeId from Account where Id =:id_pf_pj];
        }
        catch (exception e){
            System.debug('La persona física o jurídica no existe en Salesforce: \n' + e.getMessage()); 
            return 'La persona física o jurídica no existe en Salesforce: \n'+ e.getMessage();
        }
        
        /* Si es persona fisica se envia el "ACC_NumIdentificacion__c" y el tipo del campo 'ACC_TipoIdentificacion__c */
        if(pf_pj.RecordTypeId == rt_pf){
            Parameters.add('ConsultaProdFinPF');
            Parameters.add(pf_pj.ACC_NumIdentificacion__c);
            Parameters.add(pf_pj.ACC_TipoIdentificacion__c == NULL ? '' : pf_pj.ACC_TipoIdentificacion__c.Equals('Cédula')? 'Cedula' : pf_pj.ACC_TipoIdentificacion__c);
        }
        
        /* Si es persona juridica se envia el "ACC_RNC__c" y como tipo RNC fijo */
        if(pf_pj.RecordTypeId == rt_pj){
            Parameters.add('ConsultaProdFinPJ');
            Parameters.add(pf_pj.ACC_RNC__c);
            Parameters.add('RNC');
        }
        
        /* En los dos casos se envia el CIF */
        Parameters.add(pf_pj.ACC_CIF__c);
        
        /* Se obtiene el XML de envio */
        requestXML = parserToWsXML(Parameters).toXmlString().remove('<?xml version="1.0" encoding="UTF-8"?>');
        
        /* Se realiza el envio de la petición */
        try{
            /* Se realiza la llamada al WS de consulta de productos*/
            respuesta = ConsultaProdFinPost(requestXML, Parameters[0]);
            
            /*String ALL_XML= respuesta.getBodyDocument().toXmlString().remove('<?xml version="1.0" encoding="UTF-8"?>');
for (Integer i = 0; i < ALL_XML.length(); i=i+300) {
Integer iEffectiveEnd = (i+300 > (ALL_XML.length()) ? ALL_XML.length() : i+300);
System.debug(ALL_XML.substring(i,iEffectiveEnd));
}*/
            
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
</soap:Envelope>*/
            
            /* Si el 'Status' es 200, no ha sucedido ningún error*/
            if(respuesta.getStatusCode() == 200){
                /* Namespace comun que se utiliza en todo el xml */
                String namespace;
                if(pf_pj.RecordTypeId == rt_pj)
                    namespace = 'http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PJ%20Response%20IO';
                if(pf_pj.RecordTypeId == rt_pf)
                    namespace = 'http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20VBC%20Response%20IO';
                
                /* Solo se procesa el cuerpo de la petición, la cabezera se ignora */
                respuestaXML = respuesta.getBodyDocument();
                
                return_value = respuestaXML.getRootElement();
                return_value = return_value.getChildElement('Body','http://schemas.xmlsoap.org/soap/envelope/');
                return_value = return_value.getChildElement('ListOfBREAIFuncionGeneral',namespace);
                
                /* Se accede hasta el apartado de result */
                return_value = return_value.getChildElement('Result', namespace);
                
                
                /* Se almacena el ErroCorde, ErrorText y los datos de las cuentas financieras a crear */
                String ErrorCode = return_value.getChildElement('ErrorCode', namespace).getText();
                String ErrorText = return_value.getChildElement('ErrorText', namespace).getText();
                List<Dom.XMLNode> productsXML = return_value.getChildren();
                
                List<Asset> new_assets = new List<Asset>();
                
                /* Si se ha devuelto un codigo de error o mensaje no controlado, no se continua procesando */
                if(!ErrorCode.Equals('000') || !ErrorText.Equals('TRANSACCION PROCESADA')){
                    System.debug('Ha sucedido un error en la integración: ' + 'Code: ' + ErrorCode + ' | Text: ' + ErrorText);
                    return 'Ha sucedido un error en la integración:' + '\nCode: ' + ErrorCode + '\nText: ' + ErrorText;
                }
                
                /* Si no hay error, se procesan los productos */
                else{
                    Set<String> setNumerosCuenta = new Set<String>();
                    Map<String, String> assetProductMap = new Map<String, String>();

                    for (Dom.XMLNode productXML : productsXML){
                        if (productXML.getName().Equals('Producto') && ErrorCode.Equals('000') && ErrorText.Equals('TRANSACCION PROCESADA')){
                            setNumerosCuenta.add(productXML.getChildElement('NumCuenta', namespace).getText());
                            assetProductMap.put(productXML.getChildElement('NumCuenta', namespace).getText(), productXML.getChildElement('CodigoProducto',namespace).getText());
                        }
                    }

                    Map<String, Asset> assetMap = new Map<String, Asset>();
                    
                    for (Asset actualAsset : [SELECT ASE_N_de_cuenta__c FROM Asset WHERE ASE_N_de_cuenta__c IN :setNumerosCuenta]){
                    	assetMap.put(actualAsset.ASE_N_de_cuenta__c, actualAsset);    
                    }
                    
                    Map<String, Matriz_de_producto__c> productMap = new Map<String, Matriz_de_producto__c>();
                        
                    for (Matriz_de_producto__c prod : [SELECT Id, PRO_Codigo_de_producto__c, PRO_Nombre_de_linea_de_producto__c FROM Matriz_de_producto__c WHERE PRO_Codigo_de_producto__c IN: assetProductMap.values() AND PROD_Producto_principal__c = NULL]){
                        productMap.put(prod.PRO_Codigo_de_producto__c, prod);
                    }

                    String numCuenta = '';
                    String numProducto = '';
                    
                    for (Dom.XMLNode productXML : productsXML) {
                        if (productXML.getName() == 'Producto') {
                            Asset auxAsset = null;
                            Matriz_de_producto__c auxProduct = null;
                            
                            numCuenta = productXML.getChildElement('NumCuenta', namespace).getText();
                            numProducto = productXML.getChildElement('CodigoProducto', namespace).getText();
                            
                            // Comprobamos si ya existe el Asset
                            if (assetMap.containsKey(numCuenta)){
                                auxAsset = assetMap.get(numCuenta);
                            } else {
                                auxAsset = new Asset();
                            }
    
                            // Se rellena/actualiza el asset
                            auxAsset.Name = numCuenta;
                            auxAsset.ASE_N_de_cuenta__c = numCuenta;
    
                            // Si el producto indicado no existe, no se añade
                            if (productMap.containsKey(numProducto)){
                                auxAsset.ASE_Producto__c = productMap.get(numProducto).Id;
                            }
    
                            auxAsset.ASE_Estado__c = productXML.getChildElement('Estado', namespace).getText();   
                            auxAsset.ASE_Fecha_de_apertura__c = productXML.getChildElement('FechaApertura', namespace).getText() == '' ? NULL : generalUtils.parseStringtoDate(productXML.getChildElement('FechaApertura', namespace).getText());
                            auxAsset.ASE_Fecha_de_cierre_cancelacion__c = productXML.getChildElement('FechaCancelacion', namespace).getText() == '' ? NULL : generalUtils.parseStringtoDate(productXML.getChildElement('FechaCancelacion', namespace).getText());
                            auxAsset.ASE_Fecha_de_reapertura__c = productXML.getChildElement('FechaReapertura', namespace).getText() == '' ? NULL : generalUtils.parseStringtoDate(productXML.getChildElement('FechaReapertura', namespace).getText());
                            auxAsset.ASE_Linea_de_producto__c = productXML.getChildElement('LineaProducto', namespace).getText();
                            auxAsset.ASE_Saldo_disponible__c = Decimal.valueOf(productXML.getChildElement('SaldoRD', namespace).getText());
                            auxAsset.ASE_Titular_de_la_cuenta__c = productXML.getChildElement('Titulares', namespace).getText();
                            auxAsset.AccountId = id_pf_pj;
                            auxAsset.RecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByName().get(auxAsset.ASE_Linea_de_producto__c).getRecordTypeId();
                                
                            /* Se añade a la lista de nuevos assets */
                            new_assets.add(auxAsset);
                        }
                    }

                    //VERSIÓN ANTIGUA - Puede fallar por límites de SOQL
                    /* Se recorren todos los nodos por debajo de Result */
                    // for (Dom.XMLNode productXML : productsXML){
                        
                    //     /* Se recojen los productos y si no ha habido error en 'ErrorCode' y 'ErrorText' */
                    //     if (productXML.getName().Equals('Producto') && ErrorCode.Equals('000') && ErrorText.Equals('TRANSACCION PROCESADA')){
                            
                    //         /* Solo nos se procesan los productos en los que el cliente sea PRINCIPAL */
                    //         /*if(productXML.getChildElement('TipoVinculacion', namespace).getText().Equals('PRINCIPAL')){*/
                            
                    //         /* Se comprueba si ya existe el asset (No puede haber 2 cuentas financieras con el mismo NºCuenta y Código de producto) -- DESACTIVADO HASTA CARGA CATALOGO */
                    //         //List<Asset> new_asset = [Select Id from Asset where ASE_N_de_cuenta__c =:productXML.getChildElement('NumCuenta', namespace).getText() and ASE_Producto__r.PRO_Codigo_de_producto__c = :productXML.getChildElement('CodigoProducto',namespace).getText()];
                    //         List<Asset> new_asset = [Select Id from Asset where ASE_N_de_cuenta__c =:productXML.getChildElement('NumCuenta', namespace).getText()];
                    //         List<Matriz_de_producto__c> producto = [Select Id,PRO_Nombre_de_linea_de_producto__c from Matriz_de_producto__c where PRO_Codigo_de_producto__c = :productXML.getChildElement('CodigoProducto',namespace).getText() AND PROD_Producto_principal__c=null];
                            
                    //         /* Si no existe, se genera un asset nuevo */
                    //         if(new_asset == NULL || new_asset.size() == 0) new_asset = new List<Asset>{new Asset()};
                                
                    //         /* Se rellena/actualiza el asset */
                    //         new_asset[0].Name = productXML.getChildElement('NumCuenta', namespace).getText();
                    //         new_asset[0].ASE_N_de_cuenta__c = productXML.getChildElement('NumCuenta', namespace).getText();
                            
                    //         /* Si el PRODUCTO indicado no existe, no se añade */
                    //         System.debug('Cosa '+producto[0].PRO_Nombre_de_linea_de_producto__c);
                    //          System.debug('Cosa2 '+productXML.getChildElement('LineaProducto', namespace).getText());
                    //         if(producto != null && producto.size() !=0){
                    //             new_asset[0].ASE_Producto__c = producto[0].Id;
                    //            /* if(producto[0].PRO_Nombre_de_linea_de_producto__c==null){
                    //                // producto[0].PRO_Nombre_de_linea_de_producto__c = productXML.getChildElement('LineaProducto', namespace).getText();
                    //                  producto[0].PRO_Nombre_de_linea_de_producto__c = 'Certificados financieros';
                    //                 update producto;                               
                    //             }*/
                    //         } 
                            
                    //         new_asset[0].ASE_Estado__c = productXML.getChildElement('Estado', namespace).getText();   
                    //         new_asset[0].ASE_Fecha_de_apertura__c = productXML.getChildElement('FechaApertura', namespace).getText() == '' ? NULL : generalUtils.parseStringtoDate(productXML.getChildElement('FechaApertura', namespace).getText());
                    //         new_asset[0].ASE_Fecha_de_cierre_cancelacion__c = productXML.getChildElement('FechaCancelacion', namespace).getText() == '' ? NULL : generalUtils.parseStringtoDate(productXML.getChildElement('FechaCancelacion', namespace).getText());
                    //         new_asset[0].ASE_Fecha_de_reapertura__c = productXML.getChildElement('FechaReapertura', namespace).getText() == '' ? NULL : generalUtils.parseStringtoDate(productXML.getChildElement('FechaReapertura', namespace).getText());
                    //         new_asset[0].ASE_Linea_de_producto__c = productXML.getChildElement('LineaProducto', namespace).getText();
                    //         new_asset[0].ASE_Saldo_disponible__c = Decimal.valueOf(productXML.getChildElement('SaldoRD', namespace).getText());
                    //         new_asset[0].ASE_Titular_de_la_cuenta__c = productXML.getChildElement('Titulares', namespace).getText();
                    //         new_asset[0].AccountId = id_pf_pj;
                            
                    //         /* Se define el RecordType del registro */
                    //         new_asset[0].RecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByName().get(new_asset[0].ASE_Linea_de_producto__c).getRecordTypeId();
                            
                    //         /* Se añade a la lista de nuevos assets */
                    //         new_assets.add(new_asset[0]);
                    //         /*}*/ 
                    //     }
                    // }
                }
                
                /* Se Insertan/Actualizan los registros de Cuentas financieras respecto a lo recibido en la integración */
                upsert new_assets;
                return '';
            }
            
            /* Si ha sucedido algun error especifico en el CORE */
            else{
                System.debug('Ha sucedido un error durante la consulta en la integración de Consulta de productos financieros: '+ 'Code: ' + respuesta.getStatusCode() + ' |Message: ' + respuesta.getBody());
                return 'Ha sucedido un error durante la consulta en la integración de Consulta de productos financieros: '+ '\nCode: ' + respuesta.getStatusCode() +  '\nMessage: ' + respuesta.getBody();
            }  
        }
        /* Si sucede alguna excepcion durante el proceso */
        catch(exception e){
            System.debug('Ha sucedido un error no controlado durante la integración de Consulta de productos financieros: ' + e.getMessage() + ' ' + e.getStackTraceString());
            return 'Ha sucedido un error no controlado durante la integración de Consulta de productos financieros:\n' + e.getMessage();
        }finally{
            INTLogger.INTLoggerResult result = INTLogger.logCallout('011','ConsultaProdFinPJ', requestInfo, respuesta);
        }
        
    }
    
    /* Metodos para llamar la integración de PF/PJ Actualizar pasivas de forma ASINCRONA */
    @future(callout=true)
    public static void futureConsultaProdFin_PF_PJ(Id id_pf){
        consultaProdFinPFPJ(id_pf);
    }
    
}