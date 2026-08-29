public class INT001 {
    public class Response {
        @AuraEnabled public Integer requestStatusCode;
        @AuraEnabled public String requestStatus;
        @AuraEnabled public String NumDocumento = '';
        @AuraEnabled public String TipoDocumento = '';
        @AuraEnabled public String PrimerNombre = '';
        @AuraEnabled public String SegundoNombre = '';
        @AuraEnabled public String PrimerApellido = '';
        @AuraEnabled public String SegundoApellido = '';
        @AuraEnabled public String FechaNacimiento = '';
        @AuraEnabled public String LugarNacimiento = '';
        @AuraEnabled public String Genero = '';    
        @AuraEnabled public String ErrorCode = '';
        @AuraEnabled public String ErrorText = '';
    }
    
    
    private static INT001.Response parse(String response) {
        INT001.Response r = new INT001.Response();
        
        // Retrieve Result Status.
        r.errorCode = response.substringAfter('<ErrorCode>').substringBefore('</ErrorCode>');
        r.errorText = response.substringAfter('<ErrorText>').substringBefore('</ErrorText>');
        
        // If status is successful, retrieve fields.
        if(r.errorCode == '000') {
            r.NumDocumento = response.contains('<NumDocumento>') ? response.substringAfter('<NumDocumento>').substringBefore('</NumDocumento>') : '';
            r.TipoDocumento = response.contains('<TipoDocumento>') ? response.substringAfter('<TipoDocumento>').substringBefore('</TipoDocumento>') : '';
            r.PrimerNombre = response.substringAfter('<PrimerNombre>').substringBefore('</PrimerNombre>');
            r.SegundoNombre = response.contains('<SegundoNombre>') ? response.substringAfter('<SegundoNombre>').substringBefore('</SegundoNombre>') : '';
            r.PrimerApellido = response.contains('<PrimerApellido>') ? response.substringAfter('<PrimerApellido>').substringBefore('</PrimerApellido>') : '';
            r.SegundoApellido = response.contains('<SegundoApellido>') ? response.substringAfter('<SegundoApellido>').substringBefore('</SegundoApellido>') : '';
            
            if(response.contains('<FechaNacimiento>')) {
                r.FechaNacimiento = response.substringAfter('<FechaNacimiento>').substringBefore('</FechaNacimiento>');
                String[] dateBuffer = r.FechaNacimiento.split('/');
                r.FechaNacimiento = dateBuffer[2]+'-'+dateBuffer[0]+'-'+ dateBuffer[1];
            } else {
                r.FechaNacimiento = '';
            }
            
            r.LugarNacimiento = response.contains('<LugarNacimiento>') ? response.substringAfter('<LugarNacimiento>').substringBefore('</LugarNacimiento>') : '';
            r.Genero = response.contains('<Genero>') ? response.substringAfter('<Genero>').substringBefore('</Genero>') : '';
        }
        
        return r;
    }
    public static INT001.Response validateAgainstElectoralRegister(String documentNumber, String documentType) {
        List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT001_request_frame'];
        List<AuthSession> authList = [Select id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate From AuthSession WHERE UsersId =: UserInfo.getUserId() Order By CreatedDate DESC LIMIT 1];
        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
        String frame;
        INT001.Response r = new INT001.Response();
        
        // If parameters are not specified, throw exception.
        if(String.isEmpty(documentNumber)) throw new IllegalArgumentException('DocumentNumber argument cannot be blank or null.');
        if(String.isEmpty(documentType)) throw new IllegalArgumentException('DocumentType argument cannot be blank or null.');
        
        // If static resource with the frame to be sent exists, replaces fields and sends it.
        if(!srList.isEmpty()) {
            // Setup request
            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            request.setHeader('SoapAction','http://crmintegration.local/ConsultaPadron');
            frame = srList[0].body.toString();
            
            // Set WebService credentials.
            frame = frame.replace('[ws_user]', Label.Int_Username);
            frame = frame.replace('[ws_password]', Label.Int_Password);
            
            // Set Callout parameters.
            frame = frame.replace('[function_username]', UserInfo.getUserName());
            frame = frame.replace('[function_requestdate]', System.now().format('dd/MM/yyyy'));
            frame = frame.replace('[function_requesttime]', System.now().format('hh:mm:ss'));
            frame = frame.replace('[function_terminal]', authList[0].SourceIp);
            frame = frame.replace('[function_documentnumber]', documentNumber);
            frame = frame.replace('[function_documenttype]', documentType);
            
            request.setBody(frame);
            
            res = http.send(request);
            
            try{
                switch on (res.getStatusCode()) {
                    when 200 {
                        r = parse(res.getBody());                
                    }
                    when else {
                      system.debug(res);
                    }
                }
            }catch(Exception e){
                System.debug('Error :: ' + e);
            }finally{                
                //Record result and request
                INTLogger.INTLoggerResult result = INTLogger.logCallout('001', 'ConsultaPadron', request, res);
            }
            
            
            
            // Store request results.
            r.requestStatusCode = res.getStatusCode();
            r.requestStatus = res.getStatus();
        } else {
            throw new XmlException('Static resource with the request template named "INT001_request_frame" could not be found.');
        }
        
        return r;
    }
}