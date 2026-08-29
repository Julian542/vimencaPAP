public class PreQualifyFlowHandler {
    
    private static final string DEVELOPERNAME_METADATA = 'Precalificar';
    
    public static string prequalifyClient(PreQualifyFlowModel body){
        
        HttpRequest request = new HttpRequest();
        HttpResponse response;
        String precalificacion;
        Map<String,String> precalificacionMap = new Map<String,String>();
        precalificacionMap.put('BAJO', 'BAJO');
        precalificacionMap.put('MEDIO', 'MEDIO');
        precalificacionMap.put('ALTO', 'ALTO');
        
        try {
            
            Http http = new Http();
            request = postHttpRequest(DEVELOPERNAME_METADATA);
            request.setBody(JSON.serialize(body));
            response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                ResponseOK res = (ResponseOK) JSON.deserialize(response.getBody(), ResponseOK.class);
                precalificacion = res.data.message;
            }
            
        } catch (Exception e) {
            System.debug('Error :: ' + e);
        } finally {
            INTLogger.INTLoggerResult result = INTLogger.logCallout('Prequalify', 'PreQualifyFlowHandler.prequalifyClient', request, response);
        }
        return precalificacion != null && precalificacionMap.containsKey(precalificacion.toUpperCase()) ? precalificacion.toUpperCase() : null;
    }

    public static PreQualifyFlowModel createBody(Account account, Informacion_Financiera__c infoFinanciera, Participante__c accionista, Participante__c repLegal, Historial_laboral__c history) {

        
        PreQualifyFlowModel body = new PreQualifyFlowModel();
        
        Precalificar_Setting__mdt config = getMetadata(DEVELOPERNAME_METADATA);
        String rtind = config.rtind__c;
        String event = config.Event__c;
        String user = config.User__c;
        
        // Generate headers
        Map<String,String> headerMap = new Map<String,String>();
        headerMap.put('RTInd', rtind);
        headerMap.put('date', convertToDateFormat2(Date.today()));
        headerMap.put('time', convertToTimeFormat(Datetime.now()));
        headerMap.put('EVENT', event);
        headerMap.put('USER', user);
        body.Header = headerMap;

        // Datos del cliente nunca deben ser nulos
        Account accountTrama = [Select
                tolabel(ACC_INT_Canales_a_utilizar__c),
                tolabel(ACC_INT_Nacionalidad__c),
                tolabel(ACC_INT_Otra_Nacionalidad__c),
                tolabel(ACC_INT_Pais_Nacimiento__c),
                tolabel(ACC_INT_Pais_Residencia_Legal__c),
                tolabel(ACC_INT_Tipo_de_identificacion__c),
                tolabel(ACC_INT_Tipo_Estructura_Juridica__c),
                tolabel(ACC_INT_Tipo_Relacion_PEP__c),
                tolabel(ACC_INT_NoIndicaTipoMonedaProdTrans__c)
            from Account where id =: account.Id];

            // Información financiera nunca debe ser nula
        Informacion_Financiera__c infoFinancieraTrama = [Select 
                tolabel(INF_INT_Origen_de_los_recursos__c)
            from Informacion_Financiera__c where Id =: infoFinanciera.Id
        ];

        // Generate Fields
        PreQualifyFlowModel.FieldsModel fieldsObj = new PreQualifyFlowModel.FieldsModel();
        
        // Inicio ---- Campos para personas jurídicas y personas físicas
        String activityCode = [Select DM_Direccion__c from Datos_Maestros__c where id = :account.ACC_Actividad_Economica__c]?.DM_Direccion__c;

        fieldsObj.typeIdIdentificationNumber = account.isPersonAccount ? accountTrama.ACC_INT_Tipo_de_identificacion__c + '' + account.ACC_NumIdentificacion__c : accountTrama.ACC_INT_Tipo_de_identificacion__c + '' + account.ACC_RNC__c;
        fieldsObj.handleCash = validarVacio(convertBooleanToString(account.ACC_DeclaracionSiProyectaManejarEfectivo__c));
        fieldsObj.internationalOperations = validarVacio(convertBooleanToString(account.ACC_DeclaracionSiManejaOpInternacionales__c));
        fieldsObj.customerCode = validarVacio(account.ACC_CIF__c);
        fieldsObj.processDate = validarVacio(convertToDateFormat(Date.today()));
        fieldsObj.accountId = account.Id;
        if(account.ACC_INT_TipoPersona__c == 'N' && account.PersonBirthdate != null) {
            fieldsObj.dateOfBirthIncorporation = validarEntero(convertToDateFormat(account.PersonBirthdate));  
        }else if (account.ACC_INT_TipoPersona__c == 'J' && account.ACC_Fecha_Fundacion__c != null){
            fieldsObj.dateOfBirthIncorporation = validarEntero(convertToDateFormat(account.ACC_Fecha_Fundacion__c));              
        }
        fieldsObj.nationalityConstitution = validarVacio(accountTrama.ACC_INT_Nacionalidad__c);
        fieldsObj.branchOpening = validarVacio(account.ACC_INT_NumOficina__c); 
        fieldsObj.executiveCodeOfficial = validarVacio(account.Owner_Alias__c);
        fieldsObj.averageMonthlyIncome = validarVacio(account.ACC_Total_Activos__c);
        // fieldsObj.averageMonthlyIncomeRange = validarVacio(infoFinanciera.INF_Ingresos__c);
        fieldsObj.averageMonthlySales = validarVacio(account.ACC_Ventas_Ingresos_Anuales__c);
        fieldsObj.personTypeNJ = validarVacio(account.ACC_INT_TipoPersona__c);
        List<String> productos = procesarMultipicklist(account.ACC_ProductosASolicitar__c);
        if (productos.size()>0) {
            fieldsObj.productCode01 = productos.size() > 0 ? productos[0]: '';
            fieldsObj.productCode02 = productos.size() > 1 ? productos[1]: '';
            fieldsObj.productCode03 = productos.size() > 2 ? productos[2]: '';
            fieldsObj.productCode04 = productos.size() > 3 ? productos[3]: '';
            fieldsObj.productCode05 = productos.size() > 4 ? productos[4]: '';
            fieldsObj.productChosenCount = String.valueOf(productos.size());
        }
        fieldsObj.economicActivityCode = validarVacio(activityCode);
        fieldsObj.originOfResources = validarVacio(infoFinancieraTrama.INF_INT_Origen_de_los_recursos__c); 
        Double monthlyVolume = account.ACC_IndicarVolMensualEstimadoTransaccion__c != null ? account.ACC_IndicarVolMensualEstimadoTransaccion__c : 0.0;
        fieldsObj.monthlyVolume = validarDecimal(String.valueOf(monthlyVolume.format()));
        fieldsObj.monthlyTrx = validarVacio(account.ACC_Rango_de_Transacciones_estimadas__c);
        List<String> servicios = procesarMultipicklist(account.ACC_Servicios_a_solicitar__c);
        if (servicios.size()>0) {
            fieldsObj.serviceCode01 = servicios.size() > 0 ? servicios[0]: '';
            fieldsObj.serviceCode02 = servicios.size() > 1 ? servicios[1]: '';
            fieldsObj.serviceCode03 = servicios.size() > 2 ? servicios[2]: '';
            fieldsObj.serviceCode04 = servicios.size() > 3 ? servicios[3]: '';
            fieldsObj.serviceCode05 = servicios.size() > 4 ? servicios[4]: '';
        }
        List<String> canales = procesarMultipicklist(accountTrama.ACC_INT_Canales_a_utilizar__c);
        if (canales != null && canales.size()>0) {
            fieldsObj.channel01 = canales.size() > 0 ? canales[0]: '';
            fieldsObj.channel02 = canales.size() > 1 ? canales[1]: '';
            fieldsObj.channel03 = canales.size() > 2 ? canales[2]: '';
            fieldsObj.channel04 = canales.size() > 3 ? canales[3]: '';
            fieldsObj.channel05 = canales.size() > 4 ? canales[4]: '';
        }
        fieldsObj.beneficiaryType = validarVacio(account.ACC_Tipo_beneficio_final__c);
        fieldsObj.dignitaryRelationship = validarVacio(account.ACC_Relacion_de_dignatarios__c);
        fieldsObj.relationshipWithHighRisk = validarVacio(String.valueOf(account.ACC_Relacion_ent_alto_riesgo__c));
        fieldsObj.currentType = validarVacio(accountTrama.ACC_INT_NoIndicaTipoMonedaProdTrans__c);
        // Fin ---- Campos para personas jurídicas y personas físicas


        // Inicio ---- Campos para personas físicas
        if (account.ACC_Persona_Fisica__c) {

            Historial_laboral__c historialTrama = [Select tolabel(HIS_INT_Prefesion_u_Oficio__c) from Historial_laboral__c where Id = :history.Id];

            fieldsObj.firstName = validarVacio(account.firstName);
            fieldsObj.middleName = validarVacio(account.middleName);
            fieldsObj.firstSurname = validarVacio(account.LastName);
            fieldsObj.secondSurname = validarVacio(account.Suffix);
            fieldsObj.hasNationalityConstitution2 = validarVacio(String.valueOf(account.ACC_Posee_Otra_Nacionalidad__c));
            fieldsObj.nationalityConstitution2 = validarVacio(accountTrama.ACC_INT_Otra_Nacionalidad__c);
            fieldsObj.countryOfBirth = validarVacio(accountTrama.ACC_INT_Pais_Nacimiento__c);
            fieldsObj.occupation = validarVacio(historialTrama.HIS_INT_Prefesion_u_Oficio__c);
            fieldsObj.countryOfResidence = validarVacio(accountTrama.ACC_INT_Pais_Residencia_Legal__c);
            fieldsObj.pepPublicServer = validarVacio(account.ACC_Persona_PEP__c);
            fieldsObj.pepFamily = validarVacio(convertBooleanToString(account.ACC_Familiar_PEP__c));
            fieldsObj.pepCollaborator = validarVacio(convertBooleanToString(account.ACC_Colaborador_de_PEP__c));
            fieldsObj.pepRelationType = validarVacio(accountTrama.ACC_INT_Tipo_Relacion_PEP__c);
            // Fin ---- Campos para personas físicas
        }else {

            // Inicio ---- Campos para personas jurídicas
            Participante__c accionistaTrama = [Select tolabel(Participante__r.ACC_INT_Tipo_de_identificacion__c), tolabel(Participante__r.ACC_INT_Nacionalidad__c) from Participante__c where Id = :accionista.Id];
            Participante__c repLegalTrama = [Select tolabel(Participante__r.ACC_INT_Tipo_de_identificacion__c), tolabel(Participante__r.ACC_INT_Nacionalidad__c) from Participante__c where Id = :repLegal.Id];

            fieldsObj.personNameBusinessName = validarVacio(account.ACC_Nombre_Corto_Comercial__c);
            fieldsObj.shareholder01 = validarVacio(accionista.PAR_Nombres__c);
            fieldsObj.typeIdIdentificationShareholder1 = validarVacio(accionistaTrama.Participante__r.ACC_INT_Tipo_de_identificacion__c) + validarVacio(accionista.PAR_Numero_Identificacion__c);
            fieldsObj.nationalityShareholder1 = validarVacio(accionistaTrama.Participante__r.ACC_INT_Nacionalidad__c);
            fieldsObj.dateOfBirthShareholder1 = validarEntero(String.valueOf(accionista.PAR_FechaNacimiento__c));
            fieldsObj.participationPercentageShareholder1 = validarVacio(String.valueOf((Integer)accionista.PAR_Porcentaje__c));
            fieldsObj.firstNameShareholder1 = validarVacio(accionista.PAR_PrimerNombre__c);
            fieldsObj.middleNameShareholder1 = validarVacio(accionista.PAR_SegundoNombre__c);
            fieldsObj.firstSurnameShareholder1 = validarVacio(accionista.PAR_PrimerApellido__c);
            fieldsObj.secondSurnameShareholder1 = validarVacio(accionista.PAR_SegundoApellido__c);
            fieldsObj.representative01 = validarVacio(repLegal.PAR_Nombres__c);
            fieldsObj.typeIdIdentificationRepresentative1 = validarVacio(repLegalTrama.Participante__r.ACC_INT_Tipo_de_identificacion__c) + validarVacio(repLegal.PAR_Numero_Identificacion__c);
            fieldsObj.nationalityRepresentative1 = validarVacio(repLegalTrama.Participante__r.ACC_INT_Nacionalidad__c);
            fieldsObj.dateOfBirthRepresentative1 = validarEntero(String.valueOf(repLegal.PAR_FechaNacimiento__c));
            fieldsObj.firstNameRepresentative1 = validarVacio(repLegal.PAR_PrimerNombre__c);
            fieldsObj.middleNameRepresentative1 = validarVacio(repLegal.PAR_SegundoNombre__c);
            fieldsObj.firstSurnameRepresentative1 = validarVacio(repLegal.PAR_PrimerApellido__c);
            fieldsObj.secondSurnameRepresentative1 = validarVacio(repLegal.PAR_SegundoApellido__c); 
            fieldsObj.legalStructureType = validarVacio(accountTrama.ACC_INT_Tipo_Estructura_Juridica__c);
            // Fin ---- Campos para personas jurídicas
        }

        body.Fields = fieldsObj;
        return body;
    }
    
    private static Precalificar_Setting__mdt getMetadata(String nombreServicio) {
        Boolean isSandbox = [SELECT IsSandbox FROM Organization].IsSandbox;
        Precalificar_Setting__mdt config = [
            SELECT Named_Credential__c, Metodo__c, Sign__c, rtind__c, Id__c, Event__c, User__c
            FROM Precalificar_Setting__mdt
            WHERE DeveloperName = :nombreServicio AND Is_sandbox__c = :isSandbox
            LIMIT 1
        ];
        
        return config;
    }
    
    public static HttpRequest postHttpRequest(String nombreServicio) {
        
        Precalificar_Setting__mdt config = getMetadata(nombreServicio);
        String namedCredential = config.Named_Credential__c;
        String metodo = config.Metodo__c;
        String Id = config.Id__c;
        String Sign = config.Sign__c;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + namedCredential + metodo);
        req.setMethod('POST');
        req.setTimeout(120000);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Sign', Sign);
        req.setHeader('Id', Id);
        return req;
    }

    private static String convertBooleanToString(Boolean value){
        return (value) ? 'true' : 'false';
    }

    /**
     *  Devuelve fecha en formato AAAAMMDD
     */
    private static String convertToDateFormat(Date d){
        if(d!= null){
            String month = String.valueOf(d.month()).leftPad(2,'0');
            String day =  String.valueOf(d.day()).leftPad(2,'0');
            return d.year() + month + day;
        }
        return null;
    }

    /**
     *  Devuelve fecha en formato DDMMAAAA
     */
    private static String convertToDateFormat2(Date d){
        if(d!= null){
            String month = String.valueOf(d.month()).leftPad(2,'0');
            String day =  String.valueOf(d.day()).leftPad(2,'0');
            return day + month + d.year();
        }
        return null;
    }

    public static String convertToTimeFormat(Datetime dt){ //HHSS
        if(dt!= null){
            String hours = String.valueOf(dt.hour()).leftPad(2, '0');
            String minutes =  String.valueOf(dt.minute()).leftPad(2, '0');
            return hours + minutes;
        }
        return null;
    }

    private static List<String> procesarMultipicklist(String cadena){
        List<String> values = new List<String>();
        if (cadena != null){values.addAll(cadena.split(';'));}
        return values;
    }

    private static string validarVacio(string value){
        return value != null ? value : '';
    }
   
    private static string validarVacio(decimal value){
        return String.valueOf(value) != null ? value.toPlainString() : '';
    }
   
    private static string validarDecimal(string value){
        return value != null ? value : '0.0';
    }
   
    private static string validarEntero(string value){
        return value != null ? value : '0';
    }
   
    public class ResponseData {
        public string id;
        public string message;
    }

    public class ResponseOK {
        public string status;
        public ResponseData data;
    }   
}