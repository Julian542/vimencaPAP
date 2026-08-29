public class INT004 {
    public class Response extends INTResponse {
        public final List<String> fieldList = new List<String>{'Documento', 'TipoDocumento','PersonaPEP','TipoParentesco','Ocupacion','InstitucionTrabajo','PrimerNombre','SegundoNombre','PrimerApellido','SegundoApellido','Genero','Nacionalidad','CargoPolitico'};
            }
    
    public static INT004.Response parse(String response) {
        INT004.Response r = new INT004.Response();
        
        // Retrieve Result Status.
        r.errorCode = response.substringAfter('<ErrorCode>').substringBefore('</ErrorCode>');
        r.errorText = response.substringAfter('<ErrorText>').substringBefore('</ErrorText>');
        // If status is successful, retrieve fields.
        if(r.errorCode == '000') {            
            //   System.debug( response.substringAfter('<Result>').substringBefore('</Result>'));
            for(String field: r.fieldList) {
                r.values.put(field, response.substringAfter('<'+field+'>').substringBefore('</'+field+'>'));
                //     System.debug(response.substringAfter('<'+field+'>').substringBefore('</'+field+'>'));
            }
            System.debug(r.values.get('SegundoApellido'));
        }
        return r;
    }       
    
    public static INT004.Response updateUserPEP(String document, String documentType, String firstName, String lastName) {  
        List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT004_request_frame'];
        List<AuthSession> authList = [Select id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate From AuthSession WHERE UsersId =: UserInfo.getUserId() Order By CreatedDate DESC LIMIT 1];
        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
        INT004.Response responseServer = new INT004.Response();
        String frame;
        
        // If parameters are not specified, throw exception.
        
        // If static resource with the frame to be sent exists, replaces fields and sends it.
        if(!srList.isEmpty()) {
            // Setup request
            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            request.setHeader('SoapAction','http://crmintegration.local/ConsultaPEP');
            frame = srList[0].body.toString();
            
            // Set WebService credentials.
            frame = frame.replace('[ws_user]', Label.Int_Username);
            frame = frame.replace('[ws_password]', Label.Int_Password);
            
            // Set Callout parameters.
            frame = frame.replace('[function_username]', UserInfo.getUserName());
            frame = frame.replace('[function_requestdate]', System.now().format('dd/MM/yyyy'));
            frame = frame.replace('[function_requesttime]', System.now().format('hh:mm:ss'));
            frame = frame.replace('[function_terminal]', authList[0].SourceIp);
            frame = frame.replace('[function_document]', document);
            documentType = documentType=='Cédula' ? 'Cedula': documentType;
            frame = frame.replace('[function_documentType]',documentType);
            //  frame = frame.replace('[function_firstName]', firstName);
            //  frame = frame.replace('[function_lastName]', lastName);
            request.setBody(frame);
            
            res = http.send(request);
            
            try{
                switch on (res.getStatusCode()) {
                    when 200 {
                        responseServer = parse(res.getBody());                 
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
                INTLogger.INTLoggerResult result = INTLogger.logCallout('004','ConsultaPEP', request, res);
            }
            responseServer.requestStatusCode = res.getStatusCode();
            responseServer.requestStatus = res.getStatus();            
        } else {
            throw new XmlException('Static resource with the request template named "INT004_request_frame" could not be found.');
        }        
        return responseServer;
    }
}