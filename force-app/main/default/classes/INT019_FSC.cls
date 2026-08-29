/**
 * @description       : an adapted version of INT019 to FinServ Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 27-12-2025
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
public with sharing class INT019_FSC {

    public class Response extends INTResponse {
        public final List<String> fieldList = new List<String>{
            'CompaniaExterna',
            'ConfirmacionEndoso',
            'CuotasPendientes',
            'DestinoSeguro',
            'DetalleAsegurado', 
            'FechaDesembolso',
            'FechaPrimerPago',
            'FechaUltimoPago',
            'FechaVencimiento',
            'MontoSeguro',
            'Nombre',
            'NombreEmpresa',
            'NumeroPoliza',
            'PlazoMeses',
            'ValorCuota',
            'ValorDesembolso',
            'ValorPendientePago',
            'ValorTotalAdeudado',
            'ValorTotalPrima'
        };
        public Map<String, String> valuesProduct = new Map<String, String>{
            '[function_numeroProducto]' => 'Name',
            '[function_lineaProducto]'  => 'FIN_Linea_de_producto__c'
        };
        @AuraEnabled public List<Map<String, Object>> responseList = new List<Map<String, Object>>();
    }

    public static INT019_FSC.Response parse(String response) {
        INT019_FSC.Response r = new INT019_FSC.Response();
        Map<String, Object> result;
        // Retrieve Result StatusThe.
        r.errorCode = response.substringAfter('<ErrorCode>').substringBefore('</ErrorCode>');
        r.errorText = response.substringAfter('<ErrorText>').substringBefore('</ErrorText>');
        // If status is successful, retrieve fields.
        if(r.errorCode == '000') {
            Integer cont= 0;
            while(response.contains('</Seguros>')) {
                result = new Map<String, Object>();

                for(String field: r.fieldList) {
                    result.put(field, response.substringAfter('<'+field+'>').substringBefore('</'+field+'>'));
                }
                r.responseList.add(result);

                // Remove the first <Response> element in the response.
                response = response.substringAfter('</Seguros>');
                cont++;
            }
            System.debug('Readed Rows ::' + cont);
        }
        return r;
    }

    public static String fillXML(INT019_FSC.Response responseServer, FinServ__FinancialAccount__c productF, String frame){
        String detailClient =  frame.substringBetween('<Function>', '</Function>');
        frame = frame.replace(detailClient, fillDetailClient(responseServer.valuesProduct,productF,detailClient));
        return frame;
    }

    public static String fillDetailClient(Map<String, String> valuesProduct, FinServ__FinancialAccount__c productF, String frame){
        frame =  INTUtilities.fillCorrectType(valuesProduct,productF,frame);
        return frame;
    }

    @AuraEnabled
    public static INT019_FSC.Response consultVin(String idProduct) {
        List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT019_request_frame'];
        List<AuthSession> authList = [
            SELECT id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate
            FROM AuthSession
            WHERE UsersId =: UserInfo.getUserId()
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        List<String> fields = new List<String>(FinServ__FinancialAccount__c.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = ''
            + ' SELECT ' + String.join(fields, ',')
            + ' FROM FinServ__FinancialAccount__c'
            + ' WHERE id=\''+String.escapeSingleQuotes(idProduct)+'\'';
        FinServ__FinancialAccount__c producF = Database.query(soql);

        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
        INT019_FSC.Response responseServer = new INT019_FSC.Response();
        String frame;

        // If parameters are not specified, throw exception.

        // If static resource with the frame to be sent exists, replaces fields and sends it.
        if(!srList.isEmpty()) {
            // Setup request
            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Content-Type'                , 'text/xml;charset=UTF-8');
            request.setHeader('SoapAction'                  ,'http://crmintegration.local/ConsultaSeguros');
            frame = srList[0].body.toString();

            // Set WebService credentials.
            frame = frame.replace('[ws_user]'               , Label.Int_Username);
            frame = frame.replace('[ws_password]'           , Label.Int_Password);

            // Set Callout parameters.
            frame = frame.replace('[function_username]'     , UserInfo.getUserName());
            frame = frame.replace('[function_requestdate]'  , System.now().format('dd/MM/yyyy'));
            frame = frame.replace('[function_requesttime]'  , System.now().format('hh:mm:ss'));
            frame = frame.replace('[function_terminal]'     , authList[0].SourceIp);

            frame = fillXML(responseServer,producF,frame);

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
                INTLogger.INTLoggerResult result = INTLogger.logCallout('019','ConsultaSeguros', request, res);
            }
            responseServer.requestStatusCode = res.getStatusCode();
            responseServer.requestStatus = res.getStatus();
        } else {
            throw new XmlException('Static resource with the request template named "INT019_request_frame" could not be found.');
        }
        System.debug('Response: ' + responseServer );
        return responseServer;
    }
}