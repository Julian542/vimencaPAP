public class INT056 {
 public class Response extends INTResponse {
        @InvocableVariable @AuraEnabled public boolean ivSuccess;
        @InvocableVariable @AuraEnabled public String ivMessage;
        public final List<String> fieldList = new List<String>{'ErrorText'};
            public Map<String, String> valuesVincl = new Map<String, String>{
                '[function_TipoIdentificacion]' => 'VIN_Tipo_identificacion_vinculado__c',
                    '[function_NumeroIdentificacion]' => 'VIN_N_identificacion_vinculado__c',
                    //'[function_Vinculo]' => 'VIN_Tipo_de_vinculo__c',
                    '[function_Vinculo]' => 'VIN_Clase_de_Cliente__c',
                    '[function_LineaProducto]' => 'VIN_Linea_de_producto__c',
                    // '[function_NumeroProducto]' => 'VIN_Cuenta_financiera__c.ASE_N_de_cuenta__c',
                    '[function_TipoPoder]' => 'VIN_Relacion__c',
                    '[function_DarGarantia]' => 'VIN_Firmante__c',
                    //'[function_GirarDepositar]' => 'VIN_Codigo__c',
                    //'[function_GirarDepositar]' => '',
                    '[function_CIF]' => 'VIN_CIF_Vinculado__c'
                    }; 
                     @AuraEnabled public List<Map<String, Object>> responseList = new List<Map<String, Object>>();                        
    }
    
    public static INT056.Response parse(String response) {
        INT056.Response r = new INT056.Response();
        Map<String, Object> result;
        // Retrieve Result StatusThe.
        r.errorCode = response.substringAfter('<ErrorCode>').substringBefore('</ErrorCode>');
        r.errorText = response.substringAfter('<ErrorText>').substringBefore('</ErrorText>');
        // If status is successful, retrieve fields.
        if(r.errorCode == '000') {
            Integer cont= 0;
            while(response.contains('</Result>')) {
                result = new Map<String, Object>();
                
                for(String field: r.fieldList) {
                    result.put(field, response.substringAfter('<'+field+'>').substringBefore('</'+field+'>'));                 
                }                
                r.responseList.add(result);
                
                // Remove the first <Response> element in the response.
                response = response.substringAfter('</Result>');
                cont++;
            }
            System.debug('Readed Rows ::' + cont); 
        }
        return r;
    }
    public static String fillXML(INT056.Response responseServer, Vinculado__c vinclF, String frame){
        String detailClient =  frame.substringBetween('<Function>', '</Function>');
        frame = frame.replace(detailClient, fillDetailClient(responseServer.valuesVincl,vinclF,detailClient));
        return frame;        
    }
    
    public static String fillDetailClient(Map<String, String> valuesVincl, Vinculado__c vinclF, String frame){
        frame =  INTUtilities.fillCorrectType(valuesVincl,vinclF,frame);
        return frame;
    }
    
    
    @future(callout=true)
    public static void consultVin(String idVincul) {  
        List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT056_request_frame'];
        List<AuthSession> authList = [Select id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate From AuthSession WHERE UsersId =: UserInfo.getUserId() Order By CreatedDate DESC LIMIT 1];
        
        List<String> fields = new List<String>(Vinculado__c.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM Vinculado__c'
            + ' WHERE id=\''+String.escapeSingleQuotes(idVincul)+'\'';
        Vinculado__c viculdF = Database.query(soql);
        
        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
        INT056.Response responseServer = new INT056.Response();
        String frame;
        
        // If parameters are not specified, throw exception.
        
        // If static resource with the frame to be sent exists, replaces fields and sends it.
        if(!srList.isEmpty()) {
            // Setup request
            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            request.setHeader('SoapAction','http://crmintegration.local/AsocVinculado');
            frame = srList[0].body.toString();
            
            // Set WebService credentials.
            frame = frame.replace('[ws_user]', Label.Int_Username);
            frame = frame.replace('[ws_password]', Label.Int_Password);
            
            // Set Callout parameters.
            frame = frame.replace('[function_username]', UserInfo.getUserName());
            frame = frame.replace('[function_requestdate]', System.now().format('dd/MM/yyyy'));
            frame = frame.replace('[function_requesttime]', System.now().format('hh:mm:ss'));
            frame = frame.replace('[function_terminal]', authList[0].SourceIp);
            Asset cuenta = [SELECT id, ASE_N_de_cuenta__c FROM Asset WHERE id=:viculdF.VIN_Cuenta_financiera__c];
            frame = frame.replace('[function_NumeroProducto]', cuenta.ASE_N_de_cuenta__c);
            frame = frame.replace('[function_GirarDepositar]', (viculdF.VIN_Codigo__c=='N/A')?'':viculdF.VIN_Codigo__c);
            
            frame = fillXML(responseServer,viculdF,frame);     
            
            request.setBody(frame);
            
            res = http.send(request);
            
            try{
                switch on (res.getStatusCode()) {
                    when 200 {
                        responseServer = parse(res.getBody());
                        delete viculdF;
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
                INTLogger.INTLoggerResult result = INTLogger.logCallout('056','AsocVinculado', request, res);
            }
            responseServer.requestStatusCode = res.getStatusCode();
            responseServer.requestStatus = res.getStatus();            
        } else {
            throw new XmlException('Static resource with the request template named "INT056_request_frame" could not be found.');
        }        
        System.debug('Response: ' + responseServer );
        // return responseServer;
    }
    
    @InvocableMethod
    public static List<INT056.Response> createLikedFinanAccounts(List<Id> viculadoId) {
        INT056.Response res = new INT056.Response();
        
        try {
            consultVin(viculadoId[0]);
            
            res.ivSuccess = true;
            
        } catch(Exception e) {
            res.ivSuccess = false;
            res.ivMessage = e.getMessage();
            System.debug('ERROR NO CONTROLADO :: '+e.getMessage());
        }
        /* else {
res.ivSuccess = false;
res.ivMessage = '[INT055-IM] There is no record with specified accountId in Account object table.';
}*/
        return new List<INT056.Response> {res};
            }

}