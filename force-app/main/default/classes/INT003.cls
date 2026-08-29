public class INT003 {
    public static Response response;
    public class Response extends INTResponse {
        public final List<String> fieldList = new List<String>{'NumDocumento', 'TipoDocumento','CoincidenciaLI','CoincidenciaLE','Listas'};
            public Map<String, String> valuesClient = new Map<String, String>{
                '[function_document]' => 'ACC_NumIdentificacion__c',
                    '[function_documentType]' => 'ACC_TipoIdentificacion__c',
                    '[function_firstName]' => 'firstName',
                    '[function_middleName]' => 'middleName',
                    '[function_lastName]' => 'lastName',
                    '[function_suffix]' => 'suffix',
                    '[function_birthDate]' => 'PersonBirthdate',
                    '[function_nacionality]' => 'ACC_Nacionalidad__c'};  
                        }
    
    public static INT003.Response parse(String response) {
        INT003.Response r = new INT003.Response();
        
        // Retrieve Result Status.
        r.errorCode = response.substringAfter('<ErrorCode>').substringBefore('</ErrorCode>');
        r.errorText = response.substringAfter('<ErrorText>').substringBefore('</ErrorText>');
        // If status is successful, retrieve fields.
        if(r.errorCode == '000') {            
            //   System.debug( response.substringAfter('<Result>').substringBefore('</Result>'));
            for(String field: r.fieldList) {
                String textValue=  response.substringAfter('<'+field+'>').substringBefore('</'+field+'>');
                textValue = textValue.replace('Yamp;', '&');
                r.values.put(field, textValue);
                //     System.debug(response.substringAfter('<'+field+'>').substringBefore('</'+field+'>'));
            }
        }
        return r;
    }
    public static void updateAccount(INT003.Response recordData, id recordId) {
        Account acc = [SELECT id, ACC_Resultado_Validacion__c, ACC_Estado__c, ACC_SubEstado__c,ACC_Condicion__c FROM Account WHERE id = :recordId];
        List<Matriz_lista_control__c> matrizCase=[SELECT 
                                                  id,MAT_Resultado_validacion__c,MAT_Estado__c,MAT_Sub_estado__c 
                                                  FROM Matriz_lista_control__c 
                                                  WHERE MAT_Coincidencia_en_listas_externas__c =:recordData.values.get('CoincidenciaLE').toString()
                                                  AND MAT_Coincidencia_en_listas__c =:recordData.values.get('CoincidenciaLI').toString()];
        if(acc.ACC_Condicion__c=='CLIENTE'){
            acc.ACC_Resultado_Validacion__c = matrizCase[0].MAT_Resultado_validacion__c;
        }else{
            acc.ACC_Resultado_Validacion__c = matrizCase[0].MAT_Resultado_validacion__c;                
            acc.ACC_Estado__c = matrizCase[0].MAT_Estado__c;
            acc.ACC_SubEstado__c = matrizCase[0].MAT_Sub_estado__c.toUpperCase();      
        }               
        acc.ACC_Coincidencia_Listas_Externas__c = (recordData.values.get('CoincidenciaLE').toString()=='Y')? true: false;
        acc.ACC_Coincidencia_Listas_Internas__c = (recordData.values.get('CoincidenciaLI').toString()=='Y')? true: false;
        acc.ACC_Listas__c = recordData.values.get('Listas').toString();
        acc.ACC_Ultima_Actualizacion_Listas_Internas__c = System.now();
        acc.ACC_Ultima_Actualizacion_Listas_Externas__c = System.now();
        try {            
            update acc;
           
        } catch(Exception e) {
            System.debug('ERROR NO CONTROLADO EN UPDATE:: '+ e.getMessage());
        }            
    }

    public static void updateLoan(INT003.Response recordData, Id idSolicitudDeCredito) {
        try {
            ResidentialLoanApplication rla = [SELECT Id, FSC_Resultado_PEP_Listas__c, FSC_ErrorValidacionListas__c, FSC_Subestado__c FROM ResidentialLoanApplication WHERE Id =: idSolicitudDeCredito LIMIT 1];
            if (recordData.values.get('CoincidenciaLI').toString() =='Y' || recordData.values.get('CoincidenciaLE').toString()=='Y') {
                rla.FSC_Resultado_PEP_Listas__c = 'Coincidencia';
            } else {
                rla.FSC_Resultado_PEP_Listas__c = 'Sin coincidencias';
                rla.FSC_Subestado__c = 'En Motor Buró';
            }
            rla.FSC_ErrorValidacionListas__c = null;
            update rla;
        } catch (Exception e) {
            System.debug('Error al intentar actualizar loan.');
            System.debug('Error stack: ' + e.getStackTraceString());
            System.debug('Error message: ' + e.getMessage());
        }
    }

    public static void updateLoanError(Id idSolicitudDeCredito, String message) {
        try {
            ResidentialLoanApplication rla = [SELECT Id, FSC_ErrorValidacionListas__c FROM ResidentialLoanApplication WHERE Id =: idSolicitudDeCredito LIMIT 1];
            rla.FSC_ErrorValidacionListas__c = message;
            update rla;
        } catch (Exception e) {
            System.debug('Error al intentar actualizar loan.');
            System.debug('Error stack: ' + e.getStackTraceString());
            System.debug('Error message: ' + e.getMessage());
        }
    }

    public static String fillXML(INT003.Response responseServer, Account client, String frame){
        String detailClient =  frame.substringBetween('<Function>', '</Function>');
        frame = frame.replace(detailClient, fillDetailClient(responseServer.valuesClient,client,detailClient));
        return frame;        
    }
    
    public static String fillDetailClient(Map<String, String> valuesClient, SObject client, String frame){
        //frame = fillCorrectType(valuesClient,client,frame);
        frame = INTUtilities.fillCorrectType(valuesClient,client,frame);
        return frame;
    } 
    public INT003(String idClient, String idSolicitudDeCredito){
        validatePF(idClient, idSolicitudDeCredito);
    }
    public  INT003.Response returnResponse() {
        return response;
    }

    public static void validatePF(Id idClient) {
        validatePF(String.valueOf(idClient), null);
    }

    public static void validatePF(String idClient) {
        validatePF(idClient, null);
    }
    
    @future(callout=true)
    // public static INT003.Response validatePF(String idClient) {  
    public static void validatePF(String idClient, String idSolicitudDeCredito) {  
        List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT003_request_frame'];
        List<AuthSession> authList = [Select id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate From AuthSession WHERE UsersId =: UserInfo.getUserId() Order By CreatedDate DESC LIMIT 1];
        
        List<String> fields = new List<String>(Account.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM Account'
            + ' WHERE id=\''+String.escapeSingleQuotes(idClient)+'\'';
        Account client = Database.query(soql);
        
        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
        INT003.Response responseServer = new INT003.Response();
        String frame;
        
        // If parameters are not specified, throw exception.
        
        // If static resource with the frame to be sent exists, replaces fields and sends it.
        if(!srList.isEmpty()) {
            // Setup request
            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            request.setHeader('SoapAction','http://crmintegration.local/ValidaListasControl');
            frame = srList[0].body.toString();
            
            // Set WebService credentials.
            frame = frame.replace('[ws_user]', Label.Int_Username);
            frame = frame.replace('[ws_password]', Label.Int_Password);
            
            // Set Callout parameters.
            frame = frame.replace('[function_username]', UserInfo.getUserName());
            frame = frame.replace('[function_requestdate]', System.now().format('dd/MM/yyyy'));
            frame = frame.replace('[function_requesttime]', System.now().format('hh:mm:ss'));
            frame = frame.replace('[function_terminal]', authList[0].SourceIp);
            
            frame = fillXML(responseServer,client,frame);     
            
            request.setBody(frame);
            
            res = http.send(request);
            
            try{
                System.debug('Res status code: ' + res.getStatusCode());
                switch on (res.getStatusCode()) {
                    when 200 {
                        responseServer = parse(res.getBody());
                        system.debug('Respuesta serializada: ' + JSON.serializePretty(responseServer));
                        updateAccount(responseServer, idClient);
                        if (idSolicitudDeCredito != null) {
                            updateLoan(responseServer, idSolicitudDeCredito);
                        }
                    }
                    when else {
                        if (idSolicitudDeCredito != null) {
                            String message = 'Error ' + res.getStatusCode() + ': ' + res.getBody();
                            updateLoanError(idSolicitudDeCredito, message);
                        }
                    }
                }
            }catch(Exception e){
                System.debug('Error :: ' + e);
                if (idSolicitudDeCredito != null) {
                    String message = 'Error ' + e.getMessage() + ': ' + e.getStackTraceString();
                    updateLoanError(idSolicitudDeCredito, message);
                }
            }finally{
                //Record result and request
                INTLogger.INTLoggerResult result = INTLogger.logCallout('003','ValidaListasControl', request, res);
            }
            responseServer.requestStatusCode = res.getStatusCode();
            responseServer.requestStatus = res.getStatus();            
        } else {
            throw new XmlException('Static resource with the request template named "INT003_request_frame" could not be found.');
        } 
        response = responseServer;
        //return responseServer;
    }
}
