/**
 * @description       : an adapted version of INT056 to FinServ Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 14-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
public with sharing class INT056_FSC {
    public class Response extends INTResponse {
        @InvocableVariable @AuraEnabled public boolean ivSuccess;
        @InvocableVariable @AuraEnabled public String ivMessage;
        public final List<String> fieldList = new List<String>{'ErrorText'};
        public Map<String, String> valuesVincl = new Map<String, String>{
            '[function_TipoIdentificacion]' => 'FinServ__RelatedAccount__r.ACC_NumIdentificacion__c',
            '[function_NumeroIdentificacion]' => 'FinServ__RelatedAccount__r.ACC_TipoIdentificacion__c', //TODO ajustar estos valores
            //'[function_Vinculo]' => 'VIN_Tipo_de_vinculo__c',
            '[function_Vinculo]' => 'FinServ__FinancialAccount__r.ClientClass__c ',
            '[function_LineaProducto]' => 'FinServ__FinancialAccount__r.Linea_de_producto__c ',
            // '[function_NumeroProducto]' => 'VIN_Cuenta_financiera__c.ASE_N_de_cuenta__c',
            '[function_TipoPoder]' => 'FAR_Relacion__c',
            '[function_DarGarantia]' => 'FAR_Firmante__c',
            //'[function_GirarDepositar]' => 'VIN_Codigo__c',
            //'[function_GirarDepositar]' => '',
            '[function_CIF]' => 'FinServ__RelatedAccount__r.ACC_CIF__c'
        };
        @AuraEnabled public List<Map<String, Object>> responseList = new List<Map<String, Object>>();
    }

    public static INT056_FSC.Response parse(String response) {
        INT056_FSC.Response r = new INT056_FSC.Response();
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

    public static String fillXML(INT056_FSC.Response responseServer, FinServ__FinancialAccountRole__c vinclF, String frame){
        String detailClient =  frame.substringBetween('<Function>', '</Function>');
        frame = frame.replace(detailClient, fillDetailClient(responseServer.valuesVincl,vinclF,detailClient));
        return frame;
    }

    public static String fillDetailClient(Map<String, String> valuesVincl, FinServ__FinancialAccountRole__c vinclF, String frame){
        frame =  /*INTUtilities.*/fillCorrectType(valuesVincl,vinclF,frame); //TODO clase roñosa INTUtilities
        System.debug('*** frame '+frame);
        return frame;
    }

    @future(callout=true)
    public static void consultVin(String idVincul) {
        List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT056_request_frame'];
        List<AuthSession> authList = [
            SELECT  id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate
            FROM    AuthSession
            WHERE   UsersId =: UserInfo.getUserId()
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.debug('***** idVincul ' + idVincul );
        List<String> fields = new List<String>(FinServ__FinancialAccountRole__c.SObjectType.getDescribe().fields.getMap().keySet());
        /*String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM FinServ__FinancialAccountRole__c'
            + ' WHERE id=\''+String.escapeSingleQuotes(idVincul)+'\'';
        System.debug('***** soql ' + soql );
        FinServ__FinancialAccountRole__c viculdF = Database.query(soql);*/

        FinServ__FinancialAccountRole__c viculdF = [
            SELECT Id, 
                FinServ__RelatedAccount__r.ACC_TipoIdentificacion__c , 
                FinServ__RelatedAccount__r.ACC_NumIdentificacion__c,
                FinServ__RelatedAccount__r.ACC_CIF__c,
                FAR_Relacion__c, 
                FAR_Firmante__c
            FROM FinServ__FinancialAccountRole__c 
            WHERE Id = :idVincul
        ];

        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
        INT056_FSC.Response responseServer = new INT056_FSC.Response();
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
            frame = frame.replace('[function_username]'         , UserInfo.getUserName());
            frame = frame.replace('[function_requestdate]'      , System.now().format('dd/MM/yyyy'));
            frame = frame.replace('[function_requesttime]'      , System.now().format('hh:mm:ss'));
            frame = frame.replace('[function_terminal]'         , authList[0].SourceIp);

            FinServ__FinancialAccountRole__c rol = [
                SELECT FAR_LegacyLinkedCode__c, FinServ__FinancialAccount__r.FinServ__FinancialAccountNumber__c
                FROM FinServ__FinancialAccountRole__c
                WHERE id = :viculdF.Id
            ];

            frame = frame.replace('[function_NumeroProducto]'   , rol.FinServ__FinancialAccount__r.FinServ__FinancialAccountNumber__c);
            frame = frame.replace('[function_GirarDepositar]'   , (rol.FAR_LegacyLinkedCode__c=='N/A')?'':rol.FAR_LegacyLinkedCode__c);

            frame = fillXML(responseServer,viculdF,frame);

            request.setBody(frame);

            res = http.send(request);

            try{
                switch on (res.getStatusCode()) {
                    when 200 {
                        responseServer = parse(res.getBody());
                        //delete viculdF;//se decide no borrar el dato
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
    public static List<INT056_FSC.Response> createLikedFinanAccounts(List<Id> viculadoId) {
        INT056_FSC.Response res = new INT056_FSC.Response();

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
        return new List<INT056_FSC.Response> {res};
    }

    public static String fillCorrectType(Map<String, String> valuesVincl, FinServ__FinancialAccountRole__c vinclF, String frame) {
        /*FinServ__FinancialAccountRole__c roleRecord = [
            SELECT Id, 
                FinServ__RelatedAccount__r.ACC_TipoIdentificacion__c , 
                FinServ__RelatedAccount__r.ACC_NumIdentificacion__c,
                FinServ__RelatedAccount__r.ACC_CIF__c,
                Relacion__c, 
                FAR_Firmante__c
            FROM FinServ__FinancialAccountRole__c 
            WHERE Id = :vinclF.Id
        ];*/
        
        for (String placeholder : valuesVincl.keySet()) {
            String apiPath = valuesVincl.get(placeholder).trim();
            
            if (String.isNotBlank(apiPath)) {
                // Traverse relationships dynamically (e.g., Account.Name)
                Object value = resolveFieldValue(vinclF, apiPath);
                
                if (value != null) {
                    // Apply the same formatting/escaping logic from your original class
                    if (value instanceof String) {
                        frame = frame.replace(placeholder, String.valueOf(value).escapeXml());
                    } else if (value instanceof Boolean) {
                        frame = frame.replace(placeholder, (Boolean)value ? 'Y' : 'N');
                    } else if (value instanceof Date) {
                        frame = frame.replace(placeholder, ((Date)value).format());
                    } else {
                        frame = frame.replace(placeholder, String.valueOf(value));
                    }
                } else {
                    // Special null handling for numeric placeholders if needed
                    frame = frame.replace(placeholder, '');
                }
            }
        }
        return frame;
    }

    private static Object resolveFieldValue(FinServ__FinancialAccountRole__c obj, String fieldPath) {
        if (obj == null || String.isBlank(fieldPath)) return null;

        // If it's a simple field, return directly
        if (!fieldPath.contains('.')) {
            return obj.get(fieldPath);
        }

        // Split the path into parts: ['FinServ__FinancialAccount__r', 'CIF__c']
        List<String> pathParts = fieldPath.split('\\.');
        SObject currentObj = obj;

        // Traverse all but the last part (the actual field)
        for (Integer i = 0; i < pathParts.size() - 1; i++) {
            currentObj = currentObj.getSObject(pathParts[i]);
            if (currentObj == null) return null; // Parent record not populated or null
        }

        // Return the final field value from the last parent object
        return currentObj.get(pathParts[pathParts.size() - 1]);
    }
}