public class INT002_VARNC_Controller {
public class Response {
        @AuraEnabled public Integer httpRequestStatusCode;
        @AuraEnabled public string errorCode;
        @AuraEnabled public string errorText;
        @AuraEnabled public boolean updateSuccess;
        @AuraEnabled public String updateErrorMessage;
    }
    @AuraEnabled
    public static INT002_VARNC_Controller.Response updateAccountRNC(Id recordId) {
        INT002_VARNC_Controller.Response response = new INT002_VARNC_Controller.Response();
        
        Account acc = [SELECT id, Name, ACC_RNC__c, ACC_Nombre_Corto_Comercial__c,ACC_Estado__c FROM Account WHERE id = :recordId];
        if(acc.ACC_Estado__c == 'INICIADO') {
            // Check Identification Number against Electoral Register.
            INT002.Response recordData = INT002.validateRNC(acc.ACC_RNC__c);
            
            // Store results in response.
            response.httpRequestStatusCode = recordData.requestStatusCode;
            response.errorCode = recordData.ErrorCode;
            response.errorText = recordData.ErrorText;
            if(response.errorCode == '000') {                
                acc.ACC_Nombre_Corto_Comercial__c = recordData.values.get('NombreCorto').toString();
                acc.ACC_RNC__c = recordData.values.get('RNC').toString();
                acc.ACC_Condicion__c = 'PROSPECTO';
                acc.ACC_Estado__c = 'CALIFICADO';        
                try {
                    update acc;
                    response.updateSuccess = true;               
                } catch(Exception e) {
                    String msg = e.getMessage();
                    
                    if(msg.containsIgnoreCase('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                        response.updateErrorMessage = e.getMessage().substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ' , ': [');
                    } else {
                        response.updateErrorMessage = e.getMessage();
                    }
                    response.updateSuccess = false;        
                }
            }
        } else {
            response.errorCode = '000';
            response.httpRequestStatusCode = 200;
            response.updateSuccess = false;
            response.updateErrorMessage = 'El R.N.C solo puede validarse si está en estado INICIADO';
        }
        return response;
    }
    
}