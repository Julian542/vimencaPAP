public class INTLogger {
    public class INTLoggerResult {
        public boolean success;
        public string message;
        public Id requestId;
        public Id responseId;
    }

    public static INTLoggerResult logCallout(String integration, String function, HttpRequest request, HttpResponse response) {
        return saveCallout(
            integration,
            function,
            request,
            response == null ? null : response.getBody(),
            response == null ? null : response.getStatusCode(),
            response == null ? 'SIN RESPUESTA' : response.getStatus()
        );
    }

    public static INTLoggerResult logCalloutError(String integration, String function, HttpRequest request, String errorMessage) {
        // Conserva el intento aunque no exista una respuesta HTTP.
        return saveCallout(integration, function, request, errorMessage, null, 'SIN RESPUESTA');
    }

    private static INTLoggerResult saveCallout(
        String integration,
        String function,
        HttpRequest request,
        String responseBody,
        Integer statusCode,
        String status
    ) {
        INTLoggerResult result = new INTLoggerResult();
        INT_Request__c req;
        INT_Response__c res;
        try {
            if (request == null) {
                throw new INTLoggerException('No existe una solicitud HTTP para registrar.');
            }

            req = new INT_Request__c();
            res = new INT_Response__c();
            
            req.Trama_de_env_o__c = request.getBody();
            req.Integraci_n__c = integration;
        	req.Funci_n__c = function;
            insert req;
            result.requestId = req.Id;
            
            res.Trama_de_respuesta__c = responseBody;
            res.INT_Request__c = req.id;
            res.Http_Status_Code__c = statusCode;
            res.Status__c = status;
            insert res;
            result.responseId = res.Id;
            
            result.success = true;
        } catch(Exception e) {
            result.success = false;
            result.message = e.getMessage();
        }
        return result;
    }

    private class INTLoggerException extends Exception {}
    public class INTLoggerCalloutData {
        public Object req;
        public Object res;
        public INTLoggerCalloutData(Object req, Object res) {
            this.req = req;
            this.res = res;
        }
    }

    public static INTLoggerCalloutData logCalloutNoInsert(String integration, String function, HttpRequest request, HttpResponse response) {
        // Usamos mapas para simular los datos de req y res
        Map<String, Object> req = new Map<String, Object>{
            'Trama_de_env_o__c' => request.getBody(),
            'Integraci_n__c' => integration,
            'Funci_n__c' => function
        };
        Map<String, Object> res = new Map<String, Object>{
            'Trama_de_respuesta__c' => response.getBody(),
            'INT_Request__c' => null, // No hay id porque no se insertó
            'Http_Status_Code__c' => response.getStatusCode(),
            'Status__c' => response.getStatus()
        };
        return new INTLoggerCalloutData(req, res);
    }
}