public class INT061 {        
    public class Response extends INTResponse {
        public final List<String> fieldList = new List<String>{'CodBanco', 'NombreBanco'};
            List<Map<String, Object>> responseList = new List<Map<String, Object>>();
    }
    
    public static INT061.Response parse(String response) {
        INT061.Response r = new INT061.Response();
        Map<String, Object> result;
        
        // Retrieve Result Status.
        r.errorCode = response.substringAfter('<ErrorCode>').substringBefore('</ErrorCode>');
        r.errorText = response.substringAfter('<ErrorText>').substringBefore('</ErrorText>');
        // If status is successful, retrieve fields.
        if(r.errorCode == '000') {
            Integer cont= 0;
            // Loop while there are responses...
            while(response.contains('</Response>')) {
                result = new Map<String, Object>();
                
                for(String field: r.fieldList) {
                    result.put(field, response.substringAfter('<'+field+'>').substringBefore('</'+field+'>'));                 
                }                
                r.responseList.add(result);
                
                // Remove the first <Response> element in the response.
                response = response.substringAfter('</Response>');
                cont++;
            }
            System.debug('Readed Rows ::' + cont);            
        }
        return r;
    }
    
    public static void seveDataInObject(INT061.Response responseServer) {
        List<Datos_Temporales__c> newListElements =new List<Datos_Temporales__c>();
        for(Map<String, Object> responseElement : responseServer.responseList){
            //System.debug(responseElement.get('CodBanco'));            
            Datos_Temporales__c newElement =new Datos_Temporales__c(DAT_Codigo_Banco__c = responseElement.get('CodBanco').toString(),Name=responseElement.get('NombreBanco').toString(), DAT_Tipo__c='Banco');
            newListElements.add(newElement);
        }
        try {
            upsert newListElements DAT_Codigo_Banco__c;
        } catch (DmlException e) {
            System.debug('Exception :: ' + e); 
        }
        //  Insert newListElements;
    }
    
    @future(callout=true)
    public static void UpdateListOfBanks() {
        List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT061_request_frame'];
        List<AuthSession> authList = [Select id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate From AuthSession WHERE UsersId =: UserInfo.getUserId() Order By CreatedDate DESC LIMIT 1];
        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
        INT061.Response responseServer = new INT061.Response();
        String frame;
        
        // If parameters are not specified, throw exception.
        
        // If static resource with the frame to be sent exists, replaces fields and sends it.
        if(!srList.isEmpty()) {
            // Setup request
            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            request.setHeader('SoapAction','http://crmintegration.local/ConsultaListaBancos');
            frame = srList[0].body.toString();
            
            // Set WebService credentials.
            frame = frame.replace('[ws_user]', Label.Int_Username);
            frame = frame.replace('[ws_password]', Label.Int_Password);
            
            // Set Callout parameters.
            frame = frame.replace('[function_username]', UserInfo.getUserName());
            frame = frame.replace('[function_requestdate]', System.now().format('dd/MM/yyyy'));
            frame = frame.replace('[function_requesttime]', System.now().format('hh:mm:ss'));
            frame = frame.replace('[function_terminal]', authList[0].SourceIp);
            
            request.setBody(frame);
            
            res = http.send(request);
            
            try{
                switch on (res.getStatusCode()) {
                    when 200 {
                        responseServer = parse(res.getBody());
                        System.debug('Recived rows :: ' + responseServer.responseList.size());
                        seveDataInObject(responseServer);
                    }
                    when else {
                        // On Error
                        //  system.debug(res);
                    }
                }
            }catch(Exception e){
                System.debug('Error :: ' + e);
            }finally{
                //Record result and request
                INTLogger.INTLoggerResult result = INTLogger.logCallout('061', 'ConsultaListaBancos', request, res);
            }
            responseServer.requestStatusCode = res.getStatusCode();
            responseServer.requestStatus = res.getStatus();
            
        } else {
            throw new XmlException('Static resource with the request template named "INT061_request_frame" could not be found.');
        }        
    }
}