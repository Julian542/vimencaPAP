/**
 * @description       : an adapted version of INT029 to FinServ Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 27-12-2025
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
public with sharing class INT029_FSC {
    public class Response extends INTResponse {
        public final List<String> fieldList = new List<String>{'ScoreCredito', 'UltimaActualizacionScore'};
        public Map<String, String> valuesClient = new Map<String, String>{
            '[function_document]'           => 'FinServ__IndividualId__c',
            //'[function_documentType]' => 'ACC_TipoIdentificacion__c',
            '[function_CIF]'                => 'ACC_CIF__c',
            '[function_codEmployee]'        => '',
            '[function_codAttentionCenter]' => ''
        };
    }

    public static INT029_FSC.Response parse(String response) {
        INT029_FSC.Response r = new INT029_FSC.Response();

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

    public static String fillXML(INT029_FSC.Response responseServer, Account client, String frame){
        String detailClient =  frame.substringBetween('<Function>', '</Function>');
        frame = frame.replace(detailClient, fillDetailClient(responseServer.valuesClient,client,detailClient));
        return frame;
    }

    public static String fillDetailClient(Map<String, String> valuesClient, SObject client, String frame){
        frame = INTUtilities.fillCorrectType(valuesClient,client,frame);
        return frame;
    }

    public static INT029_FSC.Response updateSC(String idClient) {
        List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT029_request_frame'];
        List<AuthSession> authList = [
            SELECT id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate
            FROM AuthSession
            WHERE UsersId =: UserInfo.getUserId()
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        List<String> fields = new List<String>(Account.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM Account'
            + ' WHERE id=\''+String.escapeSingleQuotes(idClient)+'\'';
        Account client = Database.query(soql);

        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
        INT029_FSC.Response responseServer = new INT029_FSC.Response();
        String frame;

        // If parameters are not specified, throw exception.

        // If static resource with the frame to be sent exists, replaces fields and sends it.
        if(!srList.isEmpty()) {
            // Setup request
            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            request.setHeader('SoapAction','http://crmintegration.local/ConsultaScore');
            frame = srList[0].body.toString();

            // Set WebService credentials.
            frame = frame.replace('[ws_user]', Label.Int_Username);
            frame = frame.replace('[ws_password]', Label.Int_Password);

            // Set Callout parameters.
            frame = frame.replace('[function_username]'     , UserInfo.getUserName());
            frame = frame.replace('[function_requestdate]'  , System.now().format('dd/MM/yyyy'));
            frame = frame.replace('[function_requesttime]'  , System.now().format('hh:mm:ss'));
            frame = frame.replace('[function_terminal]'     , authList[0].SourceIp);
			String documentType = client.ACC_TipoIdentificacion__c=='Cédula' ? 'Cedula': client.ACC_TipoIdentificacion__c;
            frame = frame.replace('[function_documentType]' ,documentType);
            frame = fillXML(responseServer,client,frame);

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
                INTLogger.INTLoggerResult result = INTLogger.logCallout('029','ConsultaScore', request, res);
            }
            responseServer.requestStatusCode = res.getStatusCode();
            responseServer.requestStatus = res.getStatus();
        } else {
            throw new XmlException('Static resource with the request template named "INT029_request_frame" could not be found.');
        }
        return responseServer;
    }
}