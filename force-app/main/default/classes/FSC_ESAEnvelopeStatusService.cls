public without sharing class FSC_ESAEnvelopeStatusService {

    // Recomendado:
    // 1) Crear un Named Credential apuntando a tu tenant, por ejemplo:
    //    https://tu-tenant.esignanywhere.net
    // 2) Guardar el ApiToken en un Custom Metadata / Custom Setting / Named Credential header policy
    //
    // Este ejemplo usa:
    // - Named Credential: callout:eSignAnywhere
    // - Token en un método getApiToken()

    public class EnvelopeStatusResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String envelopeId;
        @AuraEnabled public String status;
        @AuraEnabled public String rawBody;
        @AuraEnabled public String errorMessage;
    }

    @AuraEnabled(cacheable=false)
    public static EnvelopeStatusResult obtenerEstadoEnvelope(String envelopeId) {
        EnvelopeStatusResult result = new EnvelopeStatusResult();
        result.envelopeId = envelopeId;

        if (String.isBlank(envelopeId)) {
            result.success = false;
            result.errorMessage = 'envelopeId es requerido.';
            return result;
        }

        try {
            HttpRequest req = new HttpRequest();

            // Ajustá el path exacto según el Swagger de TU tenant.
            // Base documentada: /api/v6
            // Ejemplo habitual:
            req.setEndpoint('callout:Esignanywhere/api/v6/envelope/' + EncodingUtil.urlEncode(envelopeId, 'UTF-8'));
            req.setMethod('GET');
            req.setHeader('Accept', 'application/json');
            req.setHeader('ApiToken', getApiToken());
            req.setTimeout(120000);

            Http http = new Http();
            HttpResponse res = http.send(req);

            result.statusCode = res.getStatusCode();
            result.rawBody = res.getBody();

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                result.success = true;

                Map<String, Object> body =
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                // El nombre exacto del campo puede variar según endpoint/tenant.
                // Probamos varias opciones comunes.
                result.status = extraerStatus(body);

            } else {
                result.success = false;
                result.errorMessage = 'Error consultando Esignanywhere: HTTP ' +
                    res.getStatusCode() + ' - ' + res.getStatus();
            }

            return result;

        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Excepción: ' + e.getMessage();
            return result;
        }
    }

    private static String extraerStatus(Map<String, Object> body) {
        if (body == null) return null;

        List<String> posiblesCampos = new List<String>{
            'Status',
            'status',
            'EnvelopeStatus',
            'DocumentStatus',
            'State',
            'state'
        };

        for (String key : posiblesCampos) {
            if (body.containsKey(key) && body.get(key) != null) {
                return String.valueOf(body.get(key));
            }
        }

        // Si viene anidado, lo podés adaptar acá.
        return null;
    }

    private static String getApiToken() {
        // Cambiá esta implementación por algo seguro.
        // Ejemplo ideal: Custom Metadata / External Credential / Protected Custom Setting
        return 'TU_API_TOKEN';
    }
}