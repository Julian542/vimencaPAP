/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_AbanksConsultaCliente
 * Versión                :   1.0
 * Fecha de creación      :   07/07/2025
 * Función                :   Clase para consultar cliente en Abanks por firma única
 * Clase Test             :   VFS_AbanksConsultaClienteTest
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        07/07/2025      Versión original
 *********************************************************************************************/
@SuppressWarnings('PMD.ExcessiveParameterList,PMD.AvoidDeeplyNestedIfStmts,PMD.CognitiveComplexity')
public with sharing class VFS_AbanksConsultaCliente {
    private static final String ENDPOINT_DEV_NAME = 'ConsultaCliente';

    // --- Clases internas para Flow ---
    public class ConsultaClienteRequest {
        @InvocableVariable(required=true)
        public String identificacion;
    }
    public class ConsultaClienteResponse {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String status;
        @InvocableVariable public String message;
        @InvocableVariable public String debugInfo;
        @InvocableVariable public String identificactionNumber;
        @InvocableVariable public String firmaUnica;
        @InvocableVariable public String fecha;
    }

    @InvocableMethod(label='Consultar Cliente ABanks' description='Consulta un cliente en ABanks por firma única')
    public static List<ConsultaClienteResponse> flowConsultaCliente(List<ConsultaClienteRequest> requests) {
        List<ConsultaClienteResponse> responses = new List<ConsultaClienteResponse>();
        for (ConsultaClienteRequest req : requests) {
            // Validar antes de obtener el token
            if (String.isBlank(req.identificacion)) {
                ConsultaClienteResponse res = new ConsultaClienteResponse();
                res.success     = false;
                res.message     = 'El campo identificacion es obligatorio.';
                res.debugInfo   = 'Validación fallida: El campo identificacion es obligatorio.';
                responses.add(res);
            } else {
                String token = obtenerTokenSeguro();
                responses.add(consultarClienteFlow(req.identificacion, token));
            }
        }
        return responses;
    }

    private static ConsultaClienteResponse consultarClienteFlow(String identificacion, String token) {
        ConsultaClienteResponse res = new ConsultaClienteResponse();
        if (String.isBlank(identificacion)) {
            res.success     = false;
            res.message     = 'El campo identificacion es obligatorio.';
            res.debugInfo   = 'Validación fallida: El campo identificacion es obligatorio.';
            return res;
        }

        String endpoint = getEndpointUrl(ENDPOINT_DEV_NAME);

        if (String.isBlank(endpoint)) {
            res.success     = false;
            res.message     = 'No se encontró endpoint configurado.';
            res.debugInfo   = 'Endpoint vacío o nulo.';
            return res;
        }

        if (!endpoint.endsWith('/')){ endpoint += '/'; }

        endpoint += identificacion;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);

        HttpResponse httpRes = null;

        try {
            httpRes = new Http().send(req);
            if (httpRes != null && httpRes.getBody() != null) {
                Map<String, Object> rawResponse = (Map<String, Object>) JSON.deserializeUntyped(httpRes.getBody());
                if (rawResponse.containsKey('data')) {
                    Map<String, Object> dataMap = (Map<String, Object>)rawResponse.get('data');
                    if (dataMap.containsKey('date')) {
                        dataMap.put('fecha', dataMap.get('date'));
                        dataMap.remove('date');
                    }
                    res.identificactionNumber = (String)dataMap.get('identificactionNumber');
                    res.firmaUnica = (String)dataMap.get('firmaUnica');
                    res.fecha = (String)dataMap.get('fecha');
                }
                res.success     = true;
                res.status      = (String)rawResponse.get('status');
                res.message     = (String)rawResponse.get('error');
                res.debugInfo   = 'StatusCode: ' + httpRes.getStatusCode() + '\nBody: ' + httpRes.getBody();
            } else {
                res.success     = false;
                res.message     = 'Respuesta vacía del servicio Abanks.';
                res.debugInfo   = 'Respuesta HTTP vacía.';
            }
        } catch (Exception e) {
            res.success     = false;
            res.message     = 'Error en callout Abanks: ' + e.getMessage();
            res.debugInfo   = 'Excepción: ' + e.getMessage();
        }
        logCallout('Abanks', 'consultaCliente', req, httpRes);
        return res;
    }

    private static String obtenerTokenSeguro() {
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
    private static void logCallout(String sistema, String operacion, HttpRequest req, HttpResponse res) {
        try {
            INTLogger.INTLoggerResult logResult = INTLogger.logCallout(sistema, operacion, req, res);
            if (!logResult.success) {
                System.debug('Error guardando log: ' + logResult.message);
            }
        } catch (Exception e) {
            System.debug('No se pudo registrar log: ' + e.getMessage());
        }
    }
    @TestVisible
    private static String getEndpointUrl(String devName) {
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
}