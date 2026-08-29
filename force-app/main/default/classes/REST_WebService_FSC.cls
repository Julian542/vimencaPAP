/**
 * @description       : an adapted version of REST_WebService to FinServ Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 28-12-2025
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
public with sharing class REST_WebService_FSC {

    public static string metodoSincronizarSolicitud = '';
    public static string metodoPrestamoVehiculo = '';
    public static string metodoPrestamoConsumo = '';
    public static string metodoConsultaMonto = '';
    public static string metodoCrearSolicitud = '';
    public static string namedCredential = '';
    public static string accessToken = '';
    public static string username = '';
    public static string password = '';

    public REST_WebService_FSC(){
        Boolean isSandbox = [SELECT IsSandbox FROM Organization].IsSandbox;
        Prestamo_Setting__mdt config = [
            SELECT  Endpoint2_Prestamo_Consumo__c,
                    Endpoint2_Prestamo_Vehiculo__c,
                    Endpoint2_Consula_Monto__c,
                    Endpoint2_Crear_Solicitud__c,
                    Endpoint2_Sincronizar_Solicitud__c,
                    Named_Credential__c,
                    Username__c,
                    Password__c,
                    Access_Token__c
            FROM Prestamo_Setting__mdt
            WHERE Is_Sandbox__c = :isSandbox
            LIMIT 1
        ];

        metodoPrestamoVehiculo = config.Endpoint2_Prestamo_Vehiculo__c;
        metodoPrestamoConsumo = config.Endpoint2_Prestamo_Consumo__c;
        metodoConsultaMonto = config.Endpoint2_Consula_Monto__c;
        metodoCrearSolicitud = config.Endpoint2_Crear_Solicitud__c;
        metodoSincronizarSolicitud = config.Endpoint2_Sincronizar_Solicitud__c;
        namedCredential = config.Named_Credential__c;
        username = config.Username__c;
        password = config.Password__c;
        accessToken = config.Access_Token__c;
    }

    public static ConsultaDatacreditoFlowController.FlowOutputs consultaPrestamoConsumo(string body){

        REST_WebService ws = new REST_WebService();
        try {
            HttpResponse httpRes = getResponse(metodoPrestamoConsumo, body);
            if (httpRes.getStatusCode() == 200) {
                REST_Wrappers.responseDatacredito_WS wrapperResponseDatacredito_WS = (REST_Wrappers.responseDatacredito_WS)
                    JSON.deserialize(httpRes.getBody(), REST_Wrappers.responseDatacredito_WS.class);

                ConsultaDatacreditoFlowController.FlowOutputs response = new ConsultaDatacreditoFlowController.FlowOutputs();

                if (wrapperResponseDatacredito_WS.DCR.ErrorHandling.Id == 0) {
                    response.dictamen = wrapperResponseDatacredito_WS.DCR.Filtro_BcoVimencaPre.Generales.Dictamen;
                    response.xcore = wrapperResponseDatacredito_WS.DCR.Filtro_BcoVimencaPre.Generales.Xcore;
                    response.mensaje = wrapperResponseDatacredito_WS.DCR.Filtro_BcoVimencaPre.Generales.Mensajes.Evaluacion.toString();
                }else {
                    response.error = wrapperResponseDatacredito_WS.DCR.ErrorHandling.Description;
                }

                return response;
            }
        } catch (Exception e) {throw e;} return null;
    }

    public static CrearSolicitudHelper.Output crearSolicitud(string body){
        REST_WebService ws = new REST_WebService();
        try {
            HttpResponse httpRes = getResponse(metodoCrearSolicitud, body);

            CrearSolicitudHelper.Output response = new CrearSolicitudHelper.Output();
            if (httpRes.getStatusCode() == 200) {
                REST_Wrappers.responseCrearSolicitud_WS wpResponseCrearSolicitud_WS = (REST_Wrappers.responseCrearSolicitud_WS)JSON.deserialize(httpRes.getBody(), REST_Wrappers.responseCrearSolicitud_WS.class);        
                //response.errorCode = wpResponseCrearSolicitud_WS.processError.errorCode;
                response.errorMessage = wpResponseCrearSolicitud_WS.processError.errorMessage;
                response.processRadNumber = response.errorMessage == '' ? wpResponseCrearSolicitud_WS.processRadNumber : null;
            }else {
                response.errorMessage = httpRes.getStatus();
            }
            return response;
        } catch (Exception e) { throw e; }
    }

    public static ConsultaDatacreditoFlowController.FlowOutputs consultaPrestamoVehiculo(string body){
        REST_WebService ws = new REST_WebService();
        try {
            HttpResponse httpRes = getResponse(metodoPrestamoVehiculo, body);
            if (httpRes.getStatusCode() == 200) {
                REST_Wrappers.responseDatacredito_WS wrapperResponseDatacredito_WS = (REST_Wrappers.responseDatacredito_WS)
                    JSON.deserialize(httpRes.getBody(), REST_Wrappers.responseDatacredito_WS.class);

                ConsultaDatacreditoFlowController.FlowOutputs response = new ConsultaDatacreditoFlowController.FlowOutputs();

                if (wrapperResponseDatacredito_WS.DCR.ErrorHandling.Id == 0) {
                    // response.dictamen = wrapperResponseDatacredito_WS.DCR.Filtro_BcoVimencaPre.Generales.Dictamen;
                    // response.xcore = wrapperResponseDatacredito_WS.DCR.Filtro_BcoVimencaPre.Generales.Xcore;
                    // response.mensaje = wrapperResponseDatacredito_WS.DCR.Filtro_BcoVimencaPre.Generales.Mensajes.Evaluacion.toString();
                }else {
                    response.error = wrapperResponseDatacredito_WS.DCR.ErrorHandling.Description;
                }

                return response;
            }
        } catch (Exception e) { throw e; } return null;

    }

    public static ConsultaMontoFlowController.FlowOutputs consultaMonto(string body) {
        REST_WebService ws = new REST_WebService();
        try {
            HttpResponse httpRes = getResponse(metodoConsultaMonto, body);
            if (httpRes.getStatusCode() == 200) {
                REST_Wrappers.responseMonto_WS wrapperResponseMonto_WS = (REST_Wrappers.responseMonto_WS)
                    JSON.deserialize(httpRes.getBody(), REST_Wrappers.responseMonto_WS.class);

                ConsultaMontoFlowController.FlowOutputs response = new ConsultaMontoFlowController.FlowOutputs();
                response.montoCuotas = wrapperResponseMonto_WS.montoCuotas;
                response.message = wrapperResponseMonto_WS.message;
                response.responseCode = wrapperResponseMonto_WS.responseCode;
                return response;
            }
        } catch (Exception e) { throw e;} return null;
    }

    public static SincronizarSolicitudFlowController.FlowOutputs sincronizarSolicitud(string body) {
        REST_WebService ws = new REST_WebService();
        try {
            HttpResponse httpRes = getResponse(metodoSincronizarSolicitud, body);
            if (httpRes.getStatusCode() == 200) {
                REST_Wrappers.responseSyncSolicitud_WS wpResponseSyncSolicitud_WS = (REST_Wrappers.responseSyncSolicitud_WS)
                    JSON.deserialize(httpRes.getBody(), REST_Wrappers.responseSyncSolicitud_WS.class);

                SincronizarSolicitudFlowController.FlowOutputs response = new SincronizarSolicitudFlowController.FlowOutputs();
                response.codeSubEstado = wpResponseSyncSolicitud_WS.ConsultarEstadoSolBizagiResult.CodigoEstado;
                response.descSubEstado = wpResponseSyncSolicitud_WS.ConsultarEstadoSolBizagiResult.DescripcionEstado;
                return response;
            }
        } catch (Exception e) { throw e; } return null;
    }

    private static HttpResponse getResponse(String metodo, String body){

        Http http = new Http();
        HttpResponse response = new HttpResponse();
        HttpRequest request = new HttpRequest();

        try{

            //Declarar variables
            String endpoint = 'callout:' + namedCredential + '/'+ metodo;
            System.debug('endpoint: ' + endpoint);

            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Connection', 'keep-alive');
            request.setHeader('username', username);
            request.setHeader('password', password);
            request.setHeader('Access-Token', accessToken);
            request.setTimeout(30000);

            if(body!= '' && body != null){
                request.setBody(body);
            }

            response = http.send(request);

            // Parse the JSON response
            if (response.getStatusCode() != 200) {
                System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus());
                return response;
            } else {
                System.debug('The status and code ' + response.getStatusCode() + ' ' + response.getStatus());
                System.debug('the body: ' + response.getBody());
                return response;
            }
        }
        catch(Exception e){ throw e; }
        finally {
            INTLogger.INTLoggerResult result = INTLogger.logCallout(metodo, 'REST_WebService_FSC.getResponse', request, response);
        }
    }
}