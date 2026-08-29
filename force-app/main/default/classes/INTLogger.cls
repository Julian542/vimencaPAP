public class INTLogger {
    public class INTLoggerResult {
        public boolean success;
        public string message;
    }
    public static INTLoggerResult logCallout(String integration, String function, HttpRequest request, HttpResponse response) {
        INTLoggerResult result = new INTLoggerResult();
        INT_Request__c req;
        INT_Response__c res;
        try {
            req = new INT_Request__c();
            res = new INT_Response__c();
            
            req.Trama_de_env_o__c = request.getBody();
            req.Integraci_n__c = integration;
        	req.Funci_n__c = function;
            insert req;
            
            res.Trama_de_respuesta__c = response.getBody();
            res.INT_Request__c = req.id;
            res.Http_Status_Code__c = response.getStatusCode();
            res.Status__c = response.getStatus();
            insert res;
            
            result.success = true;
        } catch(Exception e) {
            result.success = false;
            result.message = e.getMessage();
        }
        return result;
    }
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