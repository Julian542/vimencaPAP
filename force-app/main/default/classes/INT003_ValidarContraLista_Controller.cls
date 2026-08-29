public class INT003_ValidarContraLista_Controller {
    public class Response {
        @InvocableVariable @AuraEnabled public Integer httpRequestStatusCode;
        @InvocableVariable @AuraEnabled public string errorCode;
        @InvocableVariable @AuraEnabled public string errorText;
        @InvocableVariable @AuraEnabled public boolean updateSuccess;
        @InvocableVariable @AuraEnabled public String updateErrorMessage;
    }
    
    @AuraEnabled
    public static INT003_ValidarContraLista_Controller.Response validatePF(Id recordId) {
        INT003_ValidarContraLista_Controller.Response response =  tunelCaseFlowLightning(recordId);   
        return response;
    }
    @InvocableMethod
    //public static void validatePFFlow(List<Id> recordId) {
    public static List<INT003_ValidarContraLista_Controller.Response> validatePFFlow(List<Id> recordId) {
        System.debug('ID Flow: '+recordId[0]);
        INT003_ValidarContraLista_Controller.Response response =  tunelCaseFlowLightning(recordId[0]);
        return new List<INT003_ValidarContraLista_Controller.Response> {response};
            }
    
    public static INT003_ValidarContraLista_Controller.Response tunelCaseFlowLightning(Id recordId) {
        INT003_ValidarContraLista_Controller.Response response = new INT003_ValidarContraLista_Controller.Response();
        try {               
            List<Account> client = [SELECT id FROM Account WHERE id=:recordID];
            if(client.size()>0){
                INT003.validatePF(recordId);
                response.httpRequestStatusCode = 200;
                response.errorCode = '000';
                response.errorText = 'TRANSACCION COMPLETADA';
                response.updateSuccess = true;    
            }else{
                throw new XmlException('No hay Cliente con el id :: ' + recordID);
            }                           
        } catch(Exception e) {
            String msg = e.getMessage();
            System.debug(msg);
            if(msg.containsIgnoreCase('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                response.updateErrorMessage = e.getMessage().substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ' , ': [');
            } else {
                response.updateErrorMessage = e.getMessage();
            }
            response.errorText = 'ERROR NO CONTROLADO :: '+ e.getMessage();
            response.updateSuccess = false;        
        }      
        return response;
    }
}