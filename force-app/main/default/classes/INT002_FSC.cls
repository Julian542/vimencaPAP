/**
 * @description       : an adapted version of INT002 to FinServ Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 27-12-2025
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
public with sharing class INT002_FSC {
    public class Response extends INTResponse {
        public final List<String> fieldList = new List<String>{'RNC', 'NombreCorto','RazonSocial'};
    }

    public static INT002_FSC.Response parse(String response) {
        INT002_FSC.Response r = new INT002_FSC.Response();

        // Retrieve Result Status.
        r.errorCode = response.substringAfter('<ErrorCode>').substringBefore('</ErrorCode>');
        r.errorText = response.substringAfter('<ErrorText>').substringBefore('</ErrorText>');
        System.debug(r.errorCode);
        // If status is successful, retrieve fields.
        if(r.errorCode == '000') {
            //   System.debug( response.substringAfter('<Result>').substringBefore('</Result>'));
            for(String field: r.fieldList) {
                String textValue    = response.substringAfter('<'+field+'>').substringBefore('</'+field+'>');
                textValue           = textValue.replace('Yamp;', '&');
                r.values.put(field, textValue);
			//	System.debug(textValue);
            }
        }
        return r;
    }

    public static INT002_FSC.Response validateRNC(String documentRCN) {
        List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT002_request_frame'];
        List<AuthSession> authList = [
            SELECT id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate
            FROM AuthSession
            WHERE UsersId =: UserInfo.getUserId()
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
        INT002_FSC.Response responseServer = new INT002_FSC.Response();
        String frame;

        // If parameters are not specified, throw exception.

        // If static resource with the frame to be sent exists, replaces fields and sends it.
        if(!srList.isEmpty()) {
            // Setup request
            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            request.setHeader('SoapAction'  ,'http://crmintegration.local/ValidacionRNC');
            frame = srList[0].body.toString();

            // Set WebService credentials.
            frame = frame.replace('[ws_user]'       , Label.Int_Username);
            frame = frame.replace('[ws_password]'   , Label.Int_Password);

            // Set Callout parameters.
            frame = frame.replace('[function_username]'     , UserInfo.getUserName());
            frame = frame.replace('[function_requestdate]'  , System.now().format('dd/MM/yyyy'));
            frame = frame.replace('[function_requesttime]'  , System.now().format('hh:mm:ss'));
            frame = frame.replace('[function_terminal]'     , authList[0].SourceIp);
            frame = frame.replace('[function_RCN]'          , documentRCN);

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
                INTLogger.INTLoggerResult result = INTLogger.logCallout('002','ValidacionRNC', request, res);
            }
            responseServer.requestStatusCode = res.getStatusCode();
            responseServer.requestStatus = res.getStatus();
        } else {
            throw new XmlException('Static resource with the request template named "INT002_request_frame" could not be found.');
        }
        return responseServer;
    }
}