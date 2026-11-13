/**
 * @description       : an adapted version of INT014 to FinServ Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             :
 * @last modified on  : 06-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
public with sharing class INT014_FSC {

    public class Response extends INTResponse{
        @AuraEnabled public List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        @AuraEnabled public Boolean succesTimeout = true;
        @AuraEnabled public List<String> fields;
        public Map<String, String> fuctionsXML = new Map<String, String>{
            'cuentas de ahorro'         => 'ConsultaTransCtas',
            'cuentas corrientes'        => 'ConsultaTransCtas',
            'tarjetas de crédito'       => 'ConsultaTransTC',
            'certificados financieros'  => 'ConsultaTransCF',
            'préstamos'                 => 'ConsultaTransPrest',
            'tarjetas prepago'          => 'ConsultaTransCtas'
        };
		public Map<String, String> valuesProduct = new Map<String, String>{
            '[function_numProduct]' => 'Name',
            '[function_productType]' => 'FIN_Linea_de_producto__c',
            '[function_currency]' => 'FIN_Moneda__c'
        };

        public void parse(String functionName, String response) {
            System.debug(functionName.toLowerCase());
            switch on(functionName.toLowerCase()) {
                when 'cuentas de ahorro','cuentas corrientes' {
                    fields=new List<String> {
                        'CO',
                        'CodCausal',
                        'CodTransaccion',
                        'CreditoDebito',
                        'DescTransaccion',
                        'Documento',
                        'Estado',
                        'FechaFinal',
                        'FechaInicial',
                        'FechaProceso',
                        'FechaTransaccion',
                        'Hora',
                        'IdPagAnt',
                        'IdPagProx',
                        'MontoMaximo',
                        'MontoMinimo',
                        'NumDocumento',
                        'Oficina',
                        'Referencia',
                        'Terminal',
                        'TipoDeposito',
                        'Valor'
                    };
                    parsecase(response);
                }
               /* when ('certificados financieros') {
                    cfResponse = new INT014CFDTO();
                    cfResponse.parse(response);
                }   */
                when ('préstamos') {
                    fields=new List<String> {
                        'CodigoTransaccion',
                        'Valor',
                        'Usuario',
                        'TotalPagado',
                        'TotalFacturado',
                        'TipoMovimiento',
                        'Terminal',
                        'TasaMora',
                        'TasaInteres',
                        'TasaComision',
                        'Saldo',
                        'SUP',
                        'Oficina',
                        'NumFactura',
                        'NumDocumento',
                        'Documento',
                        'Mora',
                        'MontoTotal',
                        'MontoInteres',
                        'MontoCapital',
                        'VencimientoFactura',
                        'FechaTransaccion',
                        'FechaFinal',
                        'FechaInicial',
                        'MontoMaximo',
                        'MontoMinimo',
                        'FechaPagoFactura',
                        'Evento',
                        'Estado',
                        'DiasAtrasos',
                        'DetalleFactura',
                        'Descripcion',
                        'CreditoDebito',
                        'Comision',
                        'CodigoCausal',
                        'IdPagAnt',
                        'IdPagProx',
                        'UltimaPagina'
                    };
                    parsecase(response);
                } 
                when ('tarjetas de crédito') {
                    fields=new List<String> {
                        'CanalPago',
                        'Pais',
                        'OficinaOrigen',
                        'NumTransaccion',
                        'NumTarjeta',
                        'NumDocumento',
                        'Documento',
                        'MontoOriginal',
                        'MontoLocal',
                        'MontoMaximo',
                        'MontoMinimo',
                        'FechaTransaccion',
                        'FechaCompra',
                        'FechaFinal',
                        'FechaInicial',
                        'EstadoConsumo',
                        'Estado',
                        'Descripcion',
                        'Moneda',
                        'CreditoDebito',
                        'CodTransaccion',
                        'Ciudad',
                        'TipoRespuesta',
                        'TipoTransaccion',
                        'IdPagAnt',
                        'IdPagProx',
                        'UltimaPagina'
                    };
                    parsecase(response);
                }
                when('tarjetas prepago'){
                    fields=new List<String>{
                        'CodCausa',
                        'CodTransaccion',
                        'CreditoDebito',
                        'DescTransaccion',
                        'Estado',
                        'FechaProceso',
                        'FechaTransaccion',
                        'NumDocumento',
                        'Oficina',
                        'Referencia',
                        'Terminal',
                        'TipoDeposito',
                        'Valor',
                        'IdPagAnt',
                        'IdPagProx',
                        'UltimaPagina'
                    };
                    parsecase(response);
                }
            }
        }
        public void parsecase(String response) {
            Map<String, Object> result;
            // Retrieve Result Status.
            errorCode = response.substringAfter('<ErrorCode>').substringBefore('</ErrorCode>');
            errorText = response.substringAfter('<ErrorText>').substringBefore('</ErrorText>');
            // If status is successful, retrieve fields.
            if(errorCode == '000') {
                Integer cont= 0;
                while(response.contains('</Response>')) {
                    result = new Map<String, Object>();

                    for(String field: fields) {
                        result.put(field, response.substringAfter('<'+field+'>').substringBefore('</'+field+'>'));
                    }
                    responseList.add(result);

                    // Remove the first <Response> element in the response.
                    response = response.substringAfter('</Response>');
                    cont++;
                }
                System.debug('Readed Rows ::' + cont);
            }
        }
    }

    public static String fillXML(INT014_FSC.Response responseServer, FinServ__FinancialAccount__c productF, String frame){
        String detailClient =  frame.substringBetween('<Function>', '</Function>');
        frame = frame.replace(detailClient, fillDetailClient(responseServer.valuesProduct,productF,detailClient));
        return frame;
    }

    public static String fillDetailClient(Map<String, String> valuesProduct, FinServ__FinancialAccount__c productF, String frame){
        frame =  INTUtilities.fillCorrectType(valuesProduct,productF,frame);
        
        System.debug('*** frame '+frame);
        return frame;
    }

    @AuraEnabled
    public static INT014_FSC.Response checkProductTransactions(id idFinanAccount,Map<String,string> queryTransaction) {
        List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT014_request_frame'];
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
            + ' WHERE id=\''+String.escapeSingleQuotes(idFinanAccount)+'\'';
        FinServ__FinancialAccount__c producF = Database.query(soql);

        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();
        INT014_FSC.Response responseServer = new INT014_FSC.Response();
        String frame; 
        String function = responseServer.fuctionsXML.get(producF.FIN_Linea_de_producto__c.toLowerCase());
        System.debug(function);

        // If static resource with the frame to be sent exists, replaces fields and sends it.
        if(!srList.isEmpty()) {
            // Setup request
            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Content-Type'                        , 'text/xml;charset=UTF-8');
            request.setHeader('SoapAction'                          , 'http://crmintegration.local/'+function);

            frame = srList[0].body.toString();
            // Set WebService credentials.
            frame = frame.replace('[ws_user]'                       , Label.Int_Username);
            frame = frame.replace('[ws_password]'                   , Label.Int_Password);
            // Set Callout parameters.
            frame = frame.replace('[function_processIntegration]'   ,  function);
            //frame = frame.replace('[function_processIntegration]','ConsultaLineaCred');
            frame = frame.replace('[function_username]'             , UserInfo.getUserName());
            frame = frame.replace('[function_requestdate]'          , System.now().format('dd/MM/yyyy'));
            frame = frame.replace('[function_requesttime]'          , System.now().format('hh:mm:ss'));
            frame = frame.replace('[function_terminal]'             , authList[0].SourceIp);

            //Custom filed of the request
            frame = frame.replace('[function_fromDate]'             , queryTransaction.get('fromDate'));
            frame = frame.replace('[function_untilDate]'            , queryTransaction.get('untilDate'));
            frame = frame.replace('[function_state]'                , queryTransaction.get('state'));
            frame = frame.replace('[function_minimunAmount]'        , queryTransaction.get('minimunAmount'));
            frame = frame.replace('[function_maxAmount]'            , queryTransaction.get('maxAmount'));
            frame = frame.replace('[function_credirDebit]'          , queryTransaction.get('credirDebit'));
            frame = frame.replace('[function_documentNumber]'       , queryTransaction.get('documentNumber'));
            frame = frame.replace('[function_idPagination]'         , '0');
            frame = frame.replace('[function_pagination]'           , 'Proximo');

            frame = fillXML(responseServer,producF,frame);

            request.setBody(frame);

            try {
                res = http.send(request);
                System.debug(res.getStatusCode());
                switch on (res.getStatusCode()) {
                    when 200 {
                        if(res.getBody().contains('<ErrorCode>')){
                            responseServer.parse(producF.FIN_Linea_de_producto__c, res.getBody());
                        }else{
                            responseServer.succesTimeout = false;
                        }
                    }
                    when else {
                        // On Error
                    }
                }
            }catch(Exception e){
                responseServer.succesTimeout = false;
                System.debug('Error Type :: '+ e );
            }finally{
                INTLogger.INTLoggerResult result = INTLogger.logCallout('014',function, request, res);
            }
        } else {
            throw new XmlException('Static resource with the request template named "INT014_request_frame" could not be found.');
        }
        return responseServer;
    }
}