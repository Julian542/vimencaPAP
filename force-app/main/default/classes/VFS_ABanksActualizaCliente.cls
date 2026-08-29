/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_ABanksActualizaCliente
 * Versión                :   1.0
 * Fecha de modificación  :   07/07/2025
 * Función                :   Clase para actualizar cliente en ABanks por firma única
 * Clase Test             :   VFS_ABanksActualizaClienteTest
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        07/07/2025      Versión inicial
 *********************************************************************************************/
public with sharing class VFS_ABanksActualizaCliente {
    private static final String ENDPOINT_DEV_NAME = 'ConsultaCliente';

    @TestVisible
    public static String testToken = null;
    @TestVisible
    public static String testEndpoint = null;

    public static Response actualizaCliente(String identificacion, String firmaUnica) {
        String validationError = validateRequest(identificacion, firmaUnica);
        if (validationError != null) {
            return buildErrorResponse(validationError, 'Validación fallida: ' + validationError);
        }

        // Obtener token seguro
        String token = getAccessToken();
        if (String.isBlank(token)) {
            return buildErrorResponse('No se pudo obtener token de autenticación.', 'Token vacío o nulo.');
        }

        String endpoint = getEndpointUrl(ENDPOINT_DEV_NAME);
        if (String.isBlank(endpoint)) {
            return buildErrorResponse('No se encontró endpoint configurado.', 'Endpoint vacío o nulo.');
        }
        if (endpoint.endsWith('/')) endpoint = endpoint.substring(0, endpoint.length() - 1);

        String bodyJson = buildBodyJson(identificacion, firmaUnica);
        HttpRequest req = buildRequest(endpoint, token, bodyJson);
        HttpResponse res = sendRequest(req);
        Response result = handleResponse(res);

        // Registrar logs
        insertLogs(req, res);
        return result;
    }

    private static String getAccessToken() {
        if (testToken != null) {
            return testToken;
        }
        INTLogger.INTLoggerCalloutData tokenLogData = VFS_ABanksGetToken.getToken();
        if (tokenLogData != null && tokenLogData.res != null) {
            Map<String, Object> resMap = (Map<String, Object>)tokenLogData.res;
            if (resMap.containsKey('Trama_de_respuesta__c')) {
                String body = (String)resMap.get('Trama_de_respuesta__c');
                if (!String.isBlank(body)) {
                    try {
                        Map<String, Object> bodyMap = (Map<String, Object>)JSON.deserializeUntyped(body);
                        if (bodyMap.containsKey('accessToken')) {
                            return (String)bodyMap.get('accessToken');
                        }
                    } catch (Exception e) {
                        System.debug('No se pudo extraer accessToken del body de GetToken: ' + e.getMessage());
                    }
                }
            }
        }
        return null;
    }

    private static String buildBodyJson(String identificacion, String firmaUnica) {
        return JSON.serialize(new Map<String, Object>{
            'identificactionNumber' => identificacion,
            'firmaUnica' => firmaUnica
        });
    }

    private static HttpRequest buildRequest(String endpoint, String token, String bodyJson) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setBody(bodyJson);
        System.debug('Body JSON para ABanks: ' + req.getBody());
        return req;
    }

    private static HttpResponse sendRequest(HttpRequest req) {
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('Respuesta HTTP recibida: ' + res);
            System.debug('Respuesta HTTP recibida body: ' + res.getBody() + ' status: ' + res.getStatus());
            return res;
        } catch (Exception e) {
            System.debug('Error en callout ABanks: ' + e.getMessage());
            return null;
        }
    }

    private static Response handleResponse(HttpResponse res) {
        Response result = new Response();
        if (res != null && res.getBody() != null) {
            Map<String, Object> rawResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (rawResponse.containsKey('data')) {
                Map<String, Object> dataMap = (Map<String, Object>)rawResponse.get('data');
                if (dataMap.containsKey('date')) {
                    dataMap.put('fecha', dataMap.get('date'));
                    dataMap.remove('date');
                }
                Data data = new Data();
                data.identificationNumber = (String)dataMap.get('identificationNumber');
                data.firmaUnica = (String)dataMap.get('firmaUnica');
                data.fecha = (String)dataMap.get('fecha');
                result.data = data;
            }
            result.status = (String)rawResponse.get('status');
            result.message = (String)rawResponse.get('error');
            result.debugInfo = 'StatusCode: ' + res.getStatusCode() + '\nBody: ' + res.getBody();
        }
        return result;
    }

    private static void insertLogs(HttpRequest req, HttpResponse res) {
        List<SObject> logsToInsert = new List<SObject>();
        try {
            INTLogger.INTLoggerResult logResult = INTLogger.logCallout('ABanks', 'actualizaCliente', req, res);
            INTLogger.INTLoggerCalloutData tokenLogData = VFS_ABanksGetToken.getToken();
            if (tokenLogData != null) {
                if (tokenLogData.req != null) logsToInsert.add((SObject)tokenLogData.req);
                if (tokenLogData.res != null) logsToInsert.add((SObject)tokenLogData.res);
            }
        } catch (Exception e) {
            System.debug('No se pudo registrar log de actualizaCliente: ' + e.getMessage());
        }
        if (!logsToInsert.isEmpty()) {
            try {
                insert logsToInsert;
            } catch (Exception e) {
                System.debug('No se pudo insertar logs: ' + e.getMessage());
            }
        }
    }

    private static String validateRequest(String identificacion, String firmaUnica) {
        if (String.isBlank(identificacion)) return 'El campo identificacion es obligatorio.';
        if (String.isBlank(firmaUnica)) return 'El campo firmaUnica es obligatorio.';
        return null;
    }

    @TestVisible
    private static String getEndpointUrl(String devName) {
        if (testEndpoint != null) {
            return testEndpoint;
        }
        try {
            List<SObject> endpoints = Database.query('SELECT Url__c FROM VFS_Abanks_Endpoint__mdt WHERE DeveloperName = :devName LIMIT 1');
            if (!endpoints.isEmpty()) {
                return (String)endpoints[0].get('Url__c');
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'No se encontró endpoint en VFS_Abanks_Endpoint__mdt: ' + e.getMessage());
        }
        return null;
    }

    private static Response buildErrorResponse(String message, String debugInfo) {
        Response result = new Response();
        result.message = message;
        result.debugInfo = debugInfo;
        result.status = 'ERROR';
        return result;
    }

    public class Response {
        public String status;
        public Data data;
        public String message;
        public String debugInfo;
    }
    public class Data {
        public String identificationNumber;
        public String firmaUnica;
        public String fecha;
    }

    public class ActualizaClienteRequest {
        @InvocableVariable(required=true)
        public String identificacion;
        @InvocableVariable(required=true)
        public String firmaUnica;
    }

    public class ActualizaClienteResponse {
        @InvocableVariable
        public String status;
        @InvocableVariable
        public String message;
        @InvocableVariable
        public String debugInfo;
        @InvocableVariable
        public String identificacion;
        @InvocableVariable
        public String firmaUnica;
        @InvocableVariable
        public String fecha;
    }

    @InvocableMethod(label='Actualizar Cliente ABanks' description='Actualiza un cliente en ABanks por firma única')
    public static List<ActualizaClienteResponse> flowActualizaCliente(List<ActualizaClienteRequest> requests) {
        List<ActualizaClienteResponse> responses = new List<ActualizaClienteResponse>();
        for (ActualizaClienteRequest req : requests) {
            system.debug('identificacion: ' + req.identificacion);
            system.debug('firmaUnica: ' + req.firmaUnica);
            Response res = actualizaCliente(req.identificacion, req.firmaUnica);
            ActualizaClienteResponse flowRes = new ActualizaClienteResponse();
            if (res != null) {
                flowRes.status = res.status;
                flowRes.message = res.message;
                flowRes.debugInfo = res.debugInfo;
                if (res.data != null) {
                    flowRes.identificacion = res.data.identificationNumber;
                    flowRes.firmaUnica = res.data.firmaUnica;
                    flowRes.fecha = res.data.fecha;
                }
            } else {
                flowRes.status = 'ERROR';
                flowRes.message = 'Sin respuesta';
            }
            responses.add(flowRes);
        }
        return responses;
    }
}