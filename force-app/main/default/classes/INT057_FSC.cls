/**
 * @description       : an adapted version of INT057 to FinServ Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 27-12-2025
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
public with sharing class INT057_FSC {
    public class Response extends INTResponse {
        public final List<String> fieldList = new List<String>{'ErrorText'};
        public Map<String, String> valuesVincl = new Map<String, String>{
               /* '[function_TipoIdentificacion]' => 'VIN_Tipo_identificacion_vinculado__c',
                    '[function_NumeroIdentificacion]' => 'VIN_N_identificacion_vinculado__c',
                    '[function_ClienteVinc]' => 'VIN_Cliente_vinculado__c',
                    '[function_LineaProducto]' => 'VIN_Linea_de_producto__c',
                    '[function_NumeroProducto]' => 'VIN_Cuenta_financiera__c',
                    '[function_CIF]' => 'VIN_CIF_Vinculado__c'*/};

        @AuraEnabled public List<Map<String, Object>> responseList = new List<Map<String, Object>>();
    }

    public static INT057_FSC.Response parse(String response) {
        INT057_FSC.Response r = new INT057_FSC.Response();
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

    public static String fillXML(INT057_FSC.Response responseServer, Vinculado__c vinclF, String frame){
        String detailClient =  frame.substringBetween('<Function>', '</Function>');
        frame = frame.replace(detailClient, fillDetailClient(responseServer.valuesVincl,vinclF,detailClient));
        return frame;
    }

    public static String fillDetailClient(Map<String, String> valuesVincl, Vinculado__c vinclF, String frame){
        frame =  INTUtilities.fillCorrectType(valuesVincl,vinclF,frame);
        return frame;
    }

    @AuraEnabled
    //public static INT057_FSC.Response consultVin(String idVincul, String tipoIdentVin, String NumIdneVinc, String clienVinc, String linProd, String cuentFinanc, String cifVinc) {
    public static INT057_FSC.Response consultVin( String tipoIdentVin, String NumIdneVinc, String clienVinc, String linProd, String cuentFinanc, String cifVinc) {
        List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT057_request_frame'];
        List<AuthSession> authList = [
            SELECT  id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate
            FROM    AuthSession
            WHERE   UsersId =: UserInfo.getUserId()
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        List<String> fields = new List<String>(Account.SObjectType.getDescribe().fields.getMap().keySet());
        System.debug('Object Fields: '+  fields);
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM Account'
            + ' WHERE FinServ__IndividualId__c=\''+String.escapeSingleQuotes(NumIdneVinc)+'\' OR ACC_RNC__c=\''+String.escapeSingleQuotes(NumIdneVinc)+'\'';
        List<Account> accountParent = Database.query(soql);

        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
        INT057_FSC.Response responseServer = new INT057_FSC.Response();
        String frame;

        // If parameters are not specified, throw exception.

        // If static resource with the frame to be sent exists, replaces fields and sends it.
        if(!srList.isEmpty()) {
            // Setup request
            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            request.setHeader('SoapAction','http://crmintegration.local/EliminarVinc');
            frame = srList[0].body.toString();

            // Set WebService credentials.
            frame = frame.replace('[ws_user]'                       , Label.Int_Username);
            frame = frame.replace('[ws_password]'                   , Label.Int_Password);

            // Set Callout parameters.
            frame = frame.replace('[function_username]'             , UserInfo.getUserName());
            frame = frame.replace('[function_requestdate]'          , System.now().format('dd/MM/yyyy'));
            frame = frame.replace('[function_requesttime]'          , System.now().format('hh:mm:ss'));
            frame = frame.replace('[function_terminal]'             , authList[0].SourceIp);
            frame = frame.replace('[function_TipoIdentificacion]'   , tipoIdentVin);
            frame = frame.replace('[function_NumeroIdentificacion]' , NumIdneVinc);
            frame = frame.replace('[function_ClienteVinc]'          , clienVinc);
            frame = frame.replace('[function_LineaProducto]'        , linProd);
            frame = frame.replace('[function_NumeroProducto]'       , cuentFinanc);
 			//frame = frame.replace('[function_CIF]', accountParent[0].ACC_CIF__c);
            frame = (accountParent.size()>0)?frame.replace('[function_CIF]', accountParent[0].ACC_CIF__c):frame.replace('[function_CIF]', '');

            /*'' => 'VIN_Tipo_identificacion_vinculado__c',  String tipoIdentVin, String NumIdneVinc, String clienVinc, String linProd, String cuentFinanc, String cifVinc
                    '' => 'VIN_N_identificacion_vinculado__c',
                    '' => 'VIN_Cliente_vinculado__c',
                    '' => 'VIN_Linea_de_producto__c',
                    '' => 'VIN_Cuenta_financiera__c',
                    '' => 'VIN_CIF_Vinculado__c'*/
            //frame = fillXML(responseServer,viculdF,frame);

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
                INTLogger.INTLoggerResult result = INTLogger.logCallout('057','EliminarVinc', request, res);
            }
            responseServer.requestStatusCode = res.getStatusCode();
            responseServer.requestStatus = res.getStatus();
        } else {
            throw new XmlException('Static resource with the request template named "INT057_request_frame" could not be found.');
        }
        System.debug('Response: ' + responseServer );
        return responseServer;
    }
}