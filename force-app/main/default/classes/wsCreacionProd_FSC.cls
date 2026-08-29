/**
 * @description       : an adapted version of wsCreacionProd to Fin Serv Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 30-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
public with sharing class wsCreacionProd_FSC {
    public static HttpRequest requestLoguer;

    /* Funcion que realiza el envío de las nuevas cuentas financieras al CORE por POST */
    public static HttpResponse creacionProdCA_CC_CF_Post(String body, String action) {

        /* Clase encargada del envio y recepcion*/
        Http http = new Http();

        /* Nueva petición HTTP -> Se rellenan las cabezeras necesárias y el cuerpo pasado por parametro */
        HttpRequest request = new HttpRequest();
        request.setEndpoint(Label.EndpointWs);
        request.setMethod('POST');
        request.setHeader('SoapAction'  ,'http://crmintegration.local/' + action);
        request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        request.setBody(body);
        requestLoguer = request;

        /* Se envía y recoje la petición */
        HttpResponse response = http.send(request);

        /* Se devuelve la respuesta cual sea */
        return response;
    }

    /* Funcion que genera el XML de envio */
    public static DOM.Document parserToWsXML(FinServ__FinancialAccount__c cf, List <String> parameters){

        /* Fecha cuando se realiza la integración */
        Datetime actualTime = Datetime.now();

        /* Datos del usuario que lanza la integración */
        User user = [SELECT Id, Username, USE_Codigo__c, USE_Oficina__c FROM User WHERE ID =:UserInfo.getUserId()];

        /* Se obtienen los vinculados de la cuenta */
        List<FinServ__FinancialAccountRole__c> vinculados = [
            SELECT Id,
                   FinServ__RelatedAccount__c,
                   FinServ__RelatedAccount__r.ACC_NumIdentificacion__c,
                   FinServ__RelatedAccount__r.ACC_TipoIdentificacion__c,
                   FinServ__RelatedAccount__r.ACC_RNC__c,
                   FinServ__Role__c,
                   FAR_DocumentType__c,
                   FinServ__RelatedAccount__r.ACC_CIF__c
            FROM FinServ__FinancialAccountRole__c
            WHERE FinServ__FinancialAccount__c = :cf.Id
        ];

        Set<String> numerosIdentificacionVinculados = new Set<String>();

        for (FinServ__FinancialAccountRole__c auxVin : vinculados) {
            if (
                auxVin.FinServ__RelatedAccount__r != null &&
                String.isNotBlank(auxVin.FinServ__RelatedAccount__r.ACC_NumIdentificacion__c)
            ) {
                numerosIdentificacionVinculados.add(auxVin.FinServ__RelatedAccount__r.ACC_NumIdentificacion__c);
            }
        }

        Map<String, String> tipoDocumentoPorNumeroIdentificacion = new Map<String, String>();

        if (!numerosIdentificacionVinculados.isEmpty()) {
            for (Account acc : [
                SELECT Id,
                       ACC_NumIdentificacion__c,
                       ACC_TipoIdentificacion__c
                FROM Account
                WHERE ACC_NumIdentificacion__c IN :numerosIdentificacionVinculados
            ]) {
                if (
                    String.isNotBlank(acc.ACC_NumIdentificacion__c) &&
                    String.isNotBlank(acc.ACC_TipoIdentificacion__c)
                ) {
                    String tipoDocumento = acc.ACC_TipoIdentificacion__c;

                    tipoDocumentoPorNumeroIdentificacion.put(
                        acc.ACC_NumIdentificacion__c,
                        tipoDocumento == 'Cédula' ? 'Cedula' : tipoDocumento
                    );
                }
            }
        }

        List<ContactPointAddress> direccionLista = [
            SELECT  Id, AddressType, Street, Address, CPA_N_Apartamento__c, Country, State, CPA_Distrito__c, CPA_Sector__c, CPA_Sector__r.DM_Direccion__c, CPA_ExternalId__c, 
                    PostalCode
            FROM ContactPointAddress
            WHERE ParentId = :cf.FinServ__PrimaryOwner__c AND isPrimary = true
        ];

        List<ContactPointEmail> correoLista = [
            SELECT  Id, EmailAddress, CPE_Tipo__c
            FROM ContactPointEmail
            WHERE ParentId = :cf.FinServ__PrimaryOwner__c AND isPrimary = true
        ];

        List<ContactPointPhone> telefonoLista = [
            SELECT  Id, AreaCode, TelephoneNumber, CPP_Tipo__c, CPP_Telefonica__c
            FROM ContactPointPhone
            WHERE ParentId = :cf.FinServ__PrimaryOwner__c AND isPrimary = true
        ];

        /* Se el objeto DOM del XML a enviar */
        DOM.Document doc = new DOM.Document();

        /* BASE */
        dom.XmlNode envelope = doc.createRootElement('SOAP-ENV:Envelope', null, null);
        envelope.setNamespace('SOAP-ENV',   'http://schemas.xmlsoap.org/soap/envelope/');
        envelope.setNamespace('xsi',        'http://www.w3.org/2001/XMLSchema-instance');
        envelope.setNamespace('xsd',        'http://www.w3.org/2001/XMLSchema');

        /* HEADER */
        dom.XmlNode header = envelope.addChildElement('SOAP-ENV:Header', null, null);
        dom.XmlNode security = header.addChildElement('wsse:Security',   null, null);
        security.setNamespace('wsse',           'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd');
        security.setNamespace('wsu',            'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd');
        dom.XmlNode usernameToken = security.addChildElement('wsse:UsernameToken', null, null);
        usernameToken.setAttribute('wsu:Id',    'UsernameToken-XXDARIO');
        dom.XmlNode username = usernameToken.addChildElement('wsse:Username', null, null).addTextNode(Label.Int_Username);
        dom.XmlNode password = usernameToken.addChildElement('wsse:Password', null, null);
        password.setAttribute('Type',           'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText');
        password.addTextNode(Label.Int_Password);

        /* BODY */
        dom.XmlNode body = envelope.addChildElement('SOAP-ENV:Body', null, null);
        dom.XmlNode hTTPSleepTime = body.addChildElement('HTTPSleepTime', null, null);
        hTTPSleepTime.setNamespace('', 'http://crmintegration.local/');
        dom.XmlNode listOfBREAIFuncionGeneral = body.addChildElement('ListOfBREAIFuncionGeneral', null, null);
        System.debug('*** parameters *** '+parameters);

        /* Cuenta de ahorro */
        if (cf.RecordTypeId == parameters[0]){
            listOfBREAIFuncionGeneral.setNamespace('', 'http://www.siebel.com/xml/BR%20Crear%20Cta%20Ahorro%20XML%20IO');
        }
        /* Cuenta corriente */
        else if(cf.RecordTypeId == parameters[1]){
            listOfBREAIFuncionGeneral.setNamespace('', 'http://www.siebel.com/xml/BR%20Crear%20Cta%20Corriente%20XML%20IO');
        }

        dom.XmlNode function = listOfBREAIFuncionGeneral.addChildElement('Function', null, null);

        /* Se rellena el nodo con los datos de la cuenta */
        function.addChildElement('FunctionName', null, null).addTextNode(parameters[4]);
        function.addChildElement('UserName', null, null).addTextNode(user.Username);
        function.addChildElement('RequestDate', null, null).addTextNode(((actualTime.day() < 10)? '0' : '') + actualTime.day() + '/' + ((actualTime.month() < 10)? '0' : '') + actualTime.month() + '/' + actualTime.year());
        function.addChildElement('RequestTime', null, null).addTextNode(((actualTime.hour() < 10)? '0' : '') + actualTime.hour() + ':' + ((actualTime.minute() < 10)? '0' : '') + actualTime.minute() + ':' + ((actualTime.second() < 10)? '0' : '') + actualTime.second());
        function.addChildElement('Terminal', null, null).addTextNode('0.0.0.0');
        function.addChildElement('Channel', null, null).addTextNode('SALESFORCE');
        function.addChildElement('Version', null, null).addTextNode('1');

        function.addChildElement('NumeroCuenta', null, null).addTextNode(cf.FinServ__FinancialAccountNumber__c == NULL ? '' : cf.FinServ__FinancialAccountNumber__c);

        /* ApellidosTitular, NombreTitular, TipoIdentificacion, Identificacion solo si es PF */
        /* PJ */
        if(cf.FinServ__PrimaryOwner__r.RecordTypeId == parameters[2]){
            function.addChildElement('ApellidosTitular'  , null, null).addTextNode('');
            function.addChildElement('NombreTitular'     , null, null).addTextNode(cf.FinServ__PrimaryOwner__r.Name == NULL ? '' : cf.FinServ__PrimaryOwner__r.Name);
            function.addChildElement('TipoIdentificacion', null, null).addTextNode('RNC');
            function.addChildElement('Identificacion'    , null, null).addTextNode(cf.FinServ__PrimaryOwner__r.ACC_RNC__c == NULL ? '' : cf.FinServ__PrimaryOwner__r.ACC_RNC__c);
        }
        /* PF */
        else if (cf.FinServ__PrimaryOwner__r.RecordTypeId == parameters[3]){
            function.addChildElement('ApellidosTitular'  , null, null).addTextNode(cf.FinServ__PrimaryOwner__r.LastName == NULL ? (cf.FinServ__PrimaryOwner__r.Suffix == NULL ? '' : cf.FinServ__PrimaryOwner__r.Suffix) : (cf.FinServ__PrimaryOwner__r.Suffix == NULL ? cf.FinServ__PrimaryOwner__r.LastName : cf.FinServ__PrimaryOwner__r.LastName + ' ' + cf.FinServ__PrimaryOwner__r.Suffix));
            function.addChildElement('NombreTitular'     , null, null).addTextNode(cf.FinServ__PrimaryOwner__r.FirstName == NULL ? (cf.FinServ__PrimaryOwner__r.MiddleName == NULL ? '' : cf.FinServ__PrimaryOwner__r.MiddleName) : (cf.FinServ__PrimaryOwner__r.MiddleName == NULL ? cf.FinServ__PrimaryOwner__r.FirstName : cf.FinServ__PrimaryOwner__r.FirstName + ' ' + cf.FinServ__PrimaryOwner__r.MiddleName));
            function.addChildElement('TipoIdentificacion', null, null).addTextNode(cf.FinServ__PrimaryOwner__r.ACC_TipoIdentificacion__c == NULL ? '' : cf.FinServ__PrimaryOwner__r.ACC_TipoIdentificacion__c.Equals('Cédula')? 'Cedula' : cf.FinServ__PrimaryOwner__r.ACC_TipoIdentificacion__c);
            function.addChildElement('Identificacion'    , null, null).addTextNode(cf.FinServ__PrimaryOwner__r.ACC_NumIdentificacion__c == NULL ? '' : cf.FinServ__PrimaryOwner__r.ACC_NumIdentificacion__c);
        }

        System.debug('*** direccionLista *** '+direccionLista.size());

        function.addChildElement('Subtitulo'             , null, null).addTextNode(cf.FinServ__Nickname__c == NULL ? '' : cf.FinServ__Nickname__c);
        function.addChildElement('IdDireccion'           , null, null).addTextNode(direccionLista[0].CPA_ExternalId__c == NULL ? '' : direccionLista[0].CPA_ExternalId__c);
        function.addChildElement('IdViaContacto2'        , null, null).addTextNode('');
        function.addChildElement('IdViaContacto3'        , null, null).addTextNode('');
        function.addChildElement('TipoCuenta'            , null, null).addTextNode(cf.FinServ__FinancialAccountType__c == NULL ? 'PERSONAL' : cf.FinServ__FinancialAccountType__c);
        function.addChildElement('CodigoProducto'        , null, null).addTextNode(cf.FIN_Producto__r.PRO_Codigo_de_producto__c == NULL ? '' :  cf.FIN_Producto__r.PRO_Codigo_de_producto__c);

        /* Si es cuenta de ahorro siempre va el valor 3 - (TRIMESTRAL) */
        if(cf.RecordTypeId == parameters[0]){
            function.addChildElement('CodPeriodicidadEstado', null, null).addTextNode('3');
        }
        /* Si es cuenta corriente, puede ir 'Día 15' (Per Física) o 'Día 30' (Per Juridica) */
        else if (cf.RecordTypeId == parameters[1]){
            /* PJ */
            if(cf.FinServ__PrimaryOwner__r.RecordTypeId == parameters[2]){
                function.addChildElement('CodPeriodicidadEstado', null, null).addTextNode('2');
            }
            /* PF */
            else if (cf.FinServ__PrimaryOwner__r.RecordTypeId == parameters[3]) {
                function.addChildElement('CodPeriodicidadEstado', null, null).addTextNode('1');
            }
        }

        System.debug('Alias :: '+ cf.FIN_Ejecutivo__r.alias);
        System.debug('Owner :: '+ cf.Owner.alias);

        function.addChildElement('CodigoEjecutivo', null, null).addTextNode(cf.FIN_Ejecutivo__r.alias == NULL ? '' : cf.FIN_Ejecutivo__r.alias);
        function.addChildElement('CodigoCreador', null, null).addTextNode(cf.Owner.alias == NULL ? '' : cf.Owner.alias);
        function.addChildElement('CentroAtencionCreador', null, null).addTextNode(user.USE_Oficina__c == NULL ? '' : user.USE_Oficina__c);
        function.addChildElement('CodigoCuentaCatalogo', null, null).addTextNode(cf.FIN_Producto__r.PRO_Codigo_de_producto__c == NULL ? '' :  cf.FIN_Producto__r.PRO_Codigo_de_producto__c);
        function.addChildElement('Mancomunada', null, null).addTextNode(vinculados.size() > 0 ? 'Y':'N');
        function.addChildElement('CentroAtencion', null, null).addTextNode('1');
        function.addChildElement('CodigoEmpleado', null, null).addTextNode(user.USE_Codigo__c == NULL ? '' : user.USE_Codigo__c);
        function.addChildElement('CIF', null, null).addTextNode(cf.FinServ__PrimaryOwner__r.ACC_CIF__c == NULL ? '' : cf.FinServ__PrimaryOwner__r.ACC_CIF__c);

        /* Campos especificos de la cuenta de ahorro */
        if(cf.RecordTypeId == parameters[0]){
            function.addChildElement('SenalLibreta', null, null).addTextNode(cf.FIN_Producto__r.PRO_Requiere_libreta_PF_PJ__c ? 'Y' : 'N');
            function.addChildElement('NumeroLibreta', null, null).addTextNode(cf.FIN_N_de_libreta__c == NULL ? '' : cf.FIN_N_de_libreta__c);
            function.addChildElement('Producto', null, null).addTextNode(cf.FIN_Producto__r.Name == NULL ? '' : cf.FIN_Producto__r.Name);
        }
        /* Campos especificos de la cuenta corriente */
        else if(cf.RecordTypeId == parameters[1]){
            function.addChildElement('AgenciaApertura', null, null).addTextNode('1');
            function.addChildElement('TipoDeposito', null, null).addTextNode(cf.FIN_Tipo_de_deposito__c == NULL ? '' : cf.FIN_Tipo_de_deposito__c);
            function.addChildElement('OficinaRetencionEstado', null, null).addTextNode(cf.FIN_Oficina_retencion_de_estado__c == NULL ? '' : cf.FIN_Oficina_retencion_de_estado__c);
            function.addChildElement('MetodoEntregaEstado', null, null).addTextNode(cf.FIN_Metodo_de_entrega_de_estado__c == NULL ? '' : cf.FIN_Metodo_de_entrega_de_estado__c);
            function.addChildElement('ClaseCuenta', null, null).addTextNode('');
        }

        /* Se rellenan los vinculados */
        for(FinServ__FinancialAccountRole__c auxVin : vinculados){
            dom.XmlNode vinculado =  function.addChildElement('Vinculados', null, null);

            String tipoIdentificacionVinculado = '';
            String identificacionVinculado = '';

            if (auxVin.FinServ__RelatedAccount__r != null) {
                if (String.isNotBlank(auxVin.FinServ__RelatedAccount__r.ACC_RNC__c)) {
                    tipoIdentificacionVinculado = 'RNC';
                    identificacionVinculado = auxVin.FinServ__RelatedAccount__r.ACC_RNC__c;
                } else {
                    tipoIdentificacionVinculado = auxVin.FinServ__RelatedAccount__r.ACC_TipoIdentificacion__c == NULL
                        ? ''
                        : auxVin.FinServ__RelatedAccount__r.ACC_TipoIdentificacion__c == 'Cédula'
                            ? 'Cedula'
                            : auxVin.FinServ__RelatedAccount__r.ACC_TipoIdentificacion__c;

                    identificacionVinculado = auxVin.FinServ__RelatedAccount__r.ACC_NumIdentificacion__c == NULL
                        ? ''
                        : auxVin.FinServ__RelatedAccount__r.ACC_NumIdentificacion__c;
                }
            }

            vinculado.addChildElement('TipoIdentificacionVinculado', null, null).addTextNode(tipoIdentificacionVinculado);
            vinculado.addChildElement('IdentificacionVinculado', null, null).addTextNode(identificacionVinculado);
            vinculado.addChildElement('Vinculo', null, null).addTextNode(auxVin.FinServ__Role__c == NULL ? '' : auxVin.FinServ__Role__c);
            vinculado.addChildElement('CIF', null, null).addTextNode(
                auxVin.FinServ__RelatedAccount__r == NULL || auxVin.FinServ__RelatedAccount__r.ACC_CIF__c == NULL
                    ? ''
                    : auxVin.FinServ__RelatedAccount__r.ACC_CIF__c
            );
        }

        /* Se añaden las direcciones de la cuenta */
        dom.XmlNode direcciones = function.addChildElement('Direcciones', null, null);
        direcciones.addChildElement('Principal', null, null).addTextNode('Y');
        direcciones.addChildElement('TipoDir', null, null).addTextNode(direccionLista[0].AddressType == NULL ? '' : direccionLista[0].AddressType);
        direcciones.addChildElement('Calle', null, null).addTextNode(direccionLista[0].Street == NULL ? '' : direccionLista[0].Street);
        direcciones.addChildElement('Numero', null, null).addTextNode(direccionLista[0].Street == NULL ? '' : direccionLista[0].Street);
        direcciones.addChildElement('Apartamento', null, null).addTextNode(direccionLista[0].CPA_N_Apartamento__c == NULL ? '' : direccionLista[0].CPA_N_Apartamento__c);
        direcciones.addChildElement('Edificio', null, null).addTextNode(direccionLista[0].Street == NULL ? '' : direccionLista[0].Street);
        direcciones.addChildElement('Pais', null, null).addTextNode(direccionLista[0].Country == NULL ? '' : generalUtils.pickListGetLabel(Direccion__c.DIR_Pais__c.getDescribe(),direccionLista[0].Country));
        direcciones.addChildElement('Provincia', null, null).addTextNode(direccionLista[0].State == NULL ? '' : generalUtils.pickListGetLabel(Direccion__c.DIR_Provincia__c.getDescribe(),direccionLista[0].State));
        direcciones.addChildElement('Municipio', null, null).addTextNode(direccionLista[0].Street == NULL ? '' : generalUtils.pickListGetLabel(Direccion__c.DIR_Municipio__c.getDescribe(),direccionLista[0].Street));
        direcciones.addChildElement('Sector', null, null).addTextNode(direccionLista[0].CPA_Sector__r.DM_Direccion__c == NULL ? '' : direccionLista[0].CPA_Sector__r.DM_Direccion__c);
        direcciones.addChildElement('CP', null, null).addTextNode(direccionLista[0].PostalCode == NULL ? '' : direccionLista[0].PostalCode);

        /* Se añaden las vias de la cuenta */
        dom.XmlNode vias = function.addChildElement('Vias', null, null);
        vias.addChildElement('AsociadoEDC', null, null).addTextNode('Y');

        if(telefonoLista.size() > 0){
            String phoneNum = String.valueOf(telefonoLista[0].AreaCode) + String.valueOf(telefonoLista[0].TelephoneNumber);
            vias.addChildElement('ViaContacto', null, null).addTextNode(telefonoLista[0].CPP_Tipo__c == NULL ? '' : telefonoLista[0].CPP_Tipo__c);
            vias.addChildElement('Telefonica', null, null).addTextNode(telefonoLista[0].CPP_Telefonica__c == NULL ? '' : telefonoLista[0].CPP_Telefonica__c);
            vias.addChildElement('NumeroCorreo', null, null).addTextNode(phoneNum == NULL ? '' : phoneNum);
        } else if(correoLista.size() > 0){
            vias.addChildElement('ViaContacto', null, null).addTextNode(correoLista[0].CPE_Tipo__c == NULL ? '' : correoLista[0].CPE_Tipo__c);
            vias.addChildElement('Telefonica', null, null).addTextNode('');
            vias.addChildElement('NumeroCorreo', null, null).addTextNode(correoLista[0].EmailAddress == NULL ? '' : correoLista[0].EmailAddress);
        }

        /* Debug log esta limitado, se divide en porciones de 300 caracteres */
        String aLLXML= doc.toXmlString().remove('<?xml version="1.0" encoding="UTF-8"?>');
        for (Integer i = 0; i < aLLXML.length(); i=i+300) {
            Integer iEffectiveEnd = (i+300 > (aLLXML.length()) ? aLLXML.length() : i+300);
            System.debug(aLLXML.substring(i,iEffectiveEnd));
        }

        /* Se devuelve la variable DOM con los datos a enviar */
        return doc;
    }

    /* Metodo encargado de hacer el Callout y recoger la información necesaria*/
    public static String creacionProdCA_CC_CF(Id idCF){
        /* Cuenta Personal o juridica, de la que se van a enviar los datos */
        FinServ__FinancialAccount__c cf;

        /* Se almacena en un String la integración que se va a lanzar, para los mensajes de error */
        String integracion;

        /* Se consulta que exista una cuenta con el Id recibido */
        try{
            cf = [
                SELECT  Id, FinServ__FinancialAccountNumber__c, FinServ__FinancialAccountType__c, FinServ__Nickname__c, RecordTypeId, FIN_Res_Creacion__c, FIN_Respuesta_Integracion_Core__c, FIN_CodigoCreador__c,
                        FinServ__PrimaryOwner__c, FIN_N_de_libreta__c, FIN_Tipo_de_deposito__c, FIN_Oficina_retencion_de_estado__c, FIN_Metodo_de_entrega_de_estado__c,
                        FIN_Fecha_de_vencimiento__c, FinServ__InterestRate__c,
                        FIN_Moneda__c, FinServ__PrimaryOwner__r.Name, FinServ__PrimaryOwner__r.FirstName,
                        FinServ__PrimaryOwner__r.LastName, FinServ__PrimaryOwner__r.MiddleName,
                        FinServ__PrimaryOwner__r.Suffix, FinServ__PrimaryOwner__r.ACC_TipoIdentificacion__c, FinServ__PrimaryOwner__r.ACC_NumIdentificacion__c,
                        FinServ__PrimaryOwner__r.ACC_RNC__c, FinServ__PrimaryOwner__r.ACC_CIF__c, FinServ__PrimaryOwner__r.RecordTypeId,
                        FIN_Producto__r.PRO_Codigo_de_producto__c, FIN_Producto__r.Name, FIN_Producto__r.PRO_Requiere_libreta_PF_PJ__c,
                        FIN_Ejecutivo__r.USE_Codigo__c, FIN_Ejecutivo__r.USE_Oficina__c, FIN_Ejecutivo__r.alias, Owner.alias
                FROM FinServ__FinancialAccount__c
                WHERE Id = :idCF
            ];
        }
        catch (exception e){
            System.debug('La persona cuenta financiera no existe en la aplicación: \n' + e.getMessage());
            return 'La persona cuenta financiera no existe en la aplicación: \n'+ e.getMessage();
        }

        /* Lista de parametros del XML */
        List <String> parameters = new List<String>();

        /* Variable que almacena la peticion en un XML */
        string requestXML;

        /* Se obtienen los IDs de los recordTypes de 'Cuentas de Ahorro', 'Cuentas corrientes' y 'Certificados financieros' */
        parameters.add(Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get('SavingsAccount').getRecordTypeId());
        parameters.add(Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get('CheckingAccount').getRecordTypeId());
        parameters.add(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesBusiness').getRecordTypeId());
        parameters.add(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId());

        /* Variables para almacenar la respuesta recibida por el WS */
        HttpResponse respuesta;
        DOM.Document respuestaXML;
        Dom.XMLNode  returnValue;

        /* Si es una cuenta de ahorro */
        if(cf.RecordTypeId == parameters[0]){
           parameters.add('CrearCtaAhorro');
           integracion = 'Cuentas de Ahorro';
        }

        /* Si es una cuenta corriente */
        else if(cf.RecordTypeId == parameters[1]){
            parameters.add('CrearCtaCorriente');
            integracion = 'Cuentas corrientes';
        }

        /* Se obtiene el XML de envío */
        requestXML = parserToWsXML(cf, parameters).toXmlString().remove('<?xml version="1.0" encoding="UTF-8"?>');

        /* Se realiza el envío de la petición */
        try{
            /* Se realiza la llamada al WS de consulta de productos*/
            respuesta = creacionProdCA_CC_CF_Post(requestXML, parameters[4]);

            String aLLXML= respuesta.getBodyDocument().toXmlString();
            for (Integer i = 0; i < aLLXML.length(); i=i+300) {
                Integer iEffectiveEnd = (i+300 > (aLLXML.length()) ? aLLXML.length() : i+300);
                System.debug(aLLXML.substring(i,iEffectiveEnd));
            }

            /* Si el 'Status' es 200, no ha sucedido ningún error*/
            if(respuesta.getStatusCode() == 200){
                String namespace = 'http://www.siebel.com/xml/BR%20EAI%20Crear%20Cuenta%20Response%20IO';

                respuestaXML = respuesta.getBodyDocument();
                returnValue = respuestaXML.getRootElement();
                returnValue = returnValue.getChildElement('Body',                         'http://schemas.xmlsoap.org/soap/envelope/');
                returnValue = returnValue.getChildElement('ListOfBREAIFuncionGeneral',    namespace);
                returnValue = returnValue.getChildElement('Result', namespace);

                String errorCode = returnValue.getChildElement('ErrorCode', namespace).getText();
                String errorText = returnValue.getChildElement('ErrorText', namespace).getText();

                if(!errorCode.Equals('000') || !errorText.Equals('TRANSACCION PROCESADA')){
                    System.debug('Ha sucedido un error en la integración de creación de ' + integracion + ' : ' + 'Code: ' + errorCode + ' | Text: ' + errorText);
                    cf.FIN_Res_Creacion__c = 'Ha sucedido un error en lla integración de creación de ' + integracion + ' : ' + '\nCode: ' + errorCode + '\nText: ' + errorText;
                    cf.FIN_Respuesta_Integracion_Core__c = cf.FIN_Res_Creacion__c;
                    upsert cf;
                    INTLogger.INTLoggerResult result = INTLogger.logCallout('052',parameters[4], requestLoguer, respuesta);
                    return 'Ha sucedido un error en lla integración de creación de ' + integracion + ' : ' + '\nCode: ' + errorCode + '\nText: ' + errorText;
                }
                else{
                    returnValue = returnValue.getChildElement('Producto', namespace);
                    cf.FinServ__FinancialAccountNumber__c = returnValue.getChildElement('NumCuenta', namespace).getText();

                    if(cf.FinServ__FinancialAccountNumber__c == NULL){
                        System.debug('La integración de creación de ' + integracion + ' : No se ha devuelto un número de cuenta válido');
                        cf.FIN_Res_Creacion__c = 'La integración de creación de ' + integracion + ' : No se ha devuelto un número de cuenta válido';
                        cf.FIN_Respuesta_Integracion_Core__c = cf.FIN_Res_Creacion__c;
                        upsert cf;
                        return 'La integración de creación de ' + integracion + ' : No se ha devuelto un número de cuenta válido';
                    }
                    else{
                        cf.Name = cf.FinServ__FinancialAccountNumber__c;
                        cf.FIN_Res_Creacion__c = 'Cuenta de tipo \'' + integracion + '\' creada de forma correcta';
                        cf.FIN_Respuesta_Integracion_Core__c = cf.FIN_Res_Creacion__c;
                        upsert cf;
                        system.debug('Cuenta de tipo \'' + integracion + '\' creada de forma correcta');
                        return 'Cuenta de tipo \'' + integracion + '\' creada de forma correcta' ;
                    }
                }
            }
            else{
                System.debug('Ha sucedido un error durante la integración de creación de ' + integracion + ' : ' + 'Code: ' + respuesta.getStatusCode() + ' |Mensagge: ' + respuesta.getBody());
                cf.FIN_Res_Creacion__c = 'Ha sucedido un error durante la integración de creación de ' + integracion + ' : ' + '\nCode: ' + respuesta.getStatusCode() +  '\nMensagge: ' + respuesta.getBody();
                cf.FIN_Respuesta_Integracion_Core__c = cf.FIN_Res_Creacion__c;
                upsert cf;
                return 'Ha sucedido un error durante la integración de creación de ' + integracion + ' : ' + '\nCode: ' + respuesta.getStatusCode() +  '\nMensagge: ' + respuesta.getBody();
            }
        }
        catch(exception e){
            System.debug('Ha sucedido un error no controlado durante la integración de creación de ' + integracion + ' : ' + e.getMessage() + ' ' + e.getStackTraceString());
            cf.FIN_Res_Creacion__c = 'Ha sucedido un error no controlado durante la integración de creación de ' + integracion + ' : ' + e.getMessage();
            cf.FIN_Respuesta_Integracion_Core__c = cf.FIN_Res_Creacion__c;
            upsert cf;
            return 'Ha sucedido un error no controlado durante la integración de creación de ' + integracion + ' : ' + e.getMessage();
        } finally {
            INTLogger.INTLoggerResult result = INTLogger.logCallout('052',parameters[4], requestLoguer, respuesta);
        }
    }

    /* Metodos para llamar a la integración de creación de: 'Cuentas de Ahorro', 'Cuentas Corrientes' y 'Cuentas Financieras' de forma ASINCRONA */
    @future(callout=true)
    public static void Future_creacionProdCA_CC_CF(Id idCF){
        creacionProdCA_CC_CF(idCF);
    }

    @InvocableMethod
    public static void Invocable_creacionProdCA_CC_CF(List<Id> idCF){
        if(idCF.size() > 0){
            Future_creacionProdCA_CC_CF(idCF[0]);
        }
    }
}