global without sharing class FSC_CallAPIs implements omnistudio.VlocityOpenInterface, Callable{
    public static Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        try {
            if (methodName.equals('validatePF')) {
                validatePF(inputMap, outMap, options);
                return true;
            } else {
                System.debug('El nombre del método no es correcto');
                return false;
            }
        } catch (Exception e) {
            System.debug(
                'Error Invoke Method:: ' +
                    e.getMessage() +
                    ' en la linea:: ' +
                    e.getLineNumber()
            );
            return false;
        }
    }
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');
        return invokeMethod(action, input, output, options);
    }

    private static void validatePF(
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        try {
            String accountId = (String) inputMap.get('accountId');
            String solicitudDeCreditoId = (String) inputMap.get('solicitudDeCreditoId');
            Id solicitudDeCreditoRecordId = String.isBlank(solicitudDeCreditoId) ? null : Id.valueOf(solicitudDeCreditoId);

            List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT003_request_frame'];
            List<AuthSession> authList = [Select id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate From AuthSession WHERE UsersId =: UserInfo.getUserId() Order By CreatedDate DESC LIMIT 1];
            
            List<String> fields = new List<String>(Account.SObjectType.getDescribe().fields.getMap().keySet());
            String soql = ''
                + ' SELECT ' + String.join(fields, ',')
                + ' FROM Account'
                + ' WHERE id=\''+String.escapeSingleQuotes(accountId)+'\'';
            Account client = Database.query(soql);
            
            HttpRequest request = new HttpRequest();
            HttpResponse res;
            Http http = new Http();
            INT003.Response responseServer = new INT003.Response();
            String frame;

            if(!srList.isEmpty()) {
                request.setEndpoint(Label.EndpointWs);
                request.setMethod('POST');
                request.setTimeout(120000);
                request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
                request.setHeader('SoapAction','http://crmintegration.local/ValidaListasControl');
                frame = srList[0].body.toString();

                frame = frame.replace('[ws_user]', Label.Int_Username);
                frame = frame.replace('[ws_password]', Label.Int_Password);

                frame = frame.replace('[function_username]', UserInfo.getUserName());
                frame = frame.replace('[function_requestdate]', System.now().format('dd/MM/yyyy'));
                frame = frame.replace('[function_requesttime]', System.now().format('hh:mm:ss'));
                frame = frame.replace('[function_terminal]', authList[0].SourceIp);
                
                frame = INT003.fillXML(responseServer,client,frame);     
                
                request.setBody(frame);
                
                res = http.send(request);
                
                try{
                    System.debug('Res status code: ' + res.getStatusCode());
                    switch on (res.getStatusCode()) {
                        when 200 {
                            responseServer = INT003.parse(res.getBody());
                            system.debug('Respuesta serializada: ' + JSON.serializePretty(responseServer));
                            INT003.updateAccount(responseServer, accountId);
                            if (solicitudDeCreditoRecordId != null) {
                                INT003.updateLoan(responseServer, solicitudDeCreditoRecordId);
                            }
                        }
                        when else {
                            if (solicitudDeCreditoRecordId != null) {
                                String message = 'Error ' + res.getStatusCode() + ': ' + res.getBody();
                                INT003.updateLoanError(solicitudDeCreditoRecordId, message);
                            }
                        }
                    }
                }catch(Exception e){
                    System.debug('Error :: ' + e);
                    if (solicitudDeCreditoRecordId != null) {
                        String message = 'Error ' + e.getMessage() + ': ' + e.getStackTraceString();
                        INT003.updateLoanError(solicitudDeCreditoRecordId, message);
                    }
                }finally{
                    INTLogger.INTLoggerResult result = INTLogger.logCallout('003','ValidaListasControl', request, res);
                }
                responseServer.requestStatusCode = res.getStatusCode();
                responseServer.requestStatus = res.getStatus();            
            } else {
                throw new XmlException('Static resource with the request template named "INT003_request_frame" could not be found.');
            }
            outMap.put('coincidenciaLE', responseServer?.values.get('CoincidenciaLE').toString() == 'Y');
            outMap.put('coincidenciaLI', responseServer?.values.get('CoincidenciaLI').toString() == 'Y');
            outMap.put('coincidenciaLista', responseServer?.values.get('Listas').toString() != '');
        } catch (Exception e) {
            outMap.put('errorMessage', e.getMessage());
            outMap.put('errorLine', e.getLineNumber());
        }
    }
}