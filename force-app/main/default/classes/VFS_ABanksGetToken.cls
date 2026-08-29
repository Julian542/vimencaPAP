/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_ABanksGetToken
 * Versión                :   1.0
 * Fecha de creación      :   11/06/2025
 * Función                :   Clase para obtener token de autenticación de ABanks
 * Clase Test             :   VFS_ABanksGetTokenTest
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        11/06/2025      Versión original
 *********************************************************************************************/
@SuppressWarnings('PMD.LocalVariableNamingConventions')
public with sharing class VFS_ABanksGetToken {
    // Método principal para obtener el token de autenticación de ABanks
    public static INTLogger.INTLoggerCalloutData getToken() {
        final String CREDENTIAL_DEV_NAME = 'tdpago';
        final String ENDPOINT_DEV_NAME = 'GetToken';

        SObject cred = getCredential(CREDENTIAL_DEV_NAME);
        if (cred == null){ return null; }

        String bodyJson = buildBodyJson(cred);
        if (String.isBlank(bodyJson)){ return null; }
        System.debug('Body JSON para Abanks: ' + bodyJson);

        String endpoint = getEndpoint(ENDPOINT_DEV_NAME);
        if (String.isBlank(endpoint)){ return null; }
        System.debug('Endpoint obtenido de custom metadata: ' + endpoint);

        HttpRequest req = buildHttpRequest(endpoint, bodyJson);
        System.debug('Request preparado: ' + req);

        HttpResponse res = sendRequest(req);

        return INTLogger.logCalloutNoInsert('VFS_Abanks', 'getToken', req, res);
    }

    private static String buildBodyJson(SObject cred) {
        if (cred == null){ return null; }
        Map<String, Object> bodyMap = new Map<String, Object>{
            'username'      => cred.get('username__c'),
            'password'      => cred.get('password__c'),
            'userDatabase'  => cred.get('userDatabase__c')
        };
        return JSON.serialize(bodyMap);
    }

    private static HttpRequest buildHttpRequest(String endpoint, String bodyJson) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(bodyJson);
        return req;
    }

    private static HttpResponse sendRequest(HttpRequest req) {
        HttpResponse res;
        try {
            Http http = new Http();
            res = http.send(req);
            System.debug('Respuesta HTTP recibida: ' + res);
            System.debug('Respuesta HTTP recibida body: ' + res.getBody() + ' status: ' + res.getStatus());
        } catch (Exception e) {
            System.debug('Excepción en callout Abanks: ' + e.getMessage());
            res = null;
        }
        return res;
    }

    private static SObject getCredential(String devName) {
        try {
            SObject cred = Database.query('SELECT username__c, password__c, userDatabase__c FROM VFS_Abanks_Credential__mdt WHERE DeveloperName = :devName LIMIT 1');
            if (cred.get('username__c') == null || cred.get('password__c') == null || cred.get('userDatabase__c') == null) {
                System.debug('Credenciales incompletas.');
                return null;
            }
            return cred;
        } catch (Exception e) {
            System.debug('No se encontró credencial en VFS_Abanks_Credential__mdt: ' + e.getMessage());
            return null;
        }
    }

    private static String getEndpoint(String devName) {
        try {
            SObject endpointRec = Database.query('SELECT Url__c FROM VFS_Abanks_Endpoint__mdt WHERE DeveloperName = :devName LIMIT 1');
            return (endpointRec != null) ? (String)endpointRec.get('Url__c') : null;
        } catch (Exception e) {
            System.debug('No se encontró endpoint en VFS_Abanks_Endpoint__mdt: ' + e.getMessage());
            return null;
        }
    }

    public class Response {
        public String accessToken;
        public String refreshToken;
        public Integer accessTokenTime;
        public Integer refreshTokenTime;
        public Integer status;
        public Boolean changed;
    }
}