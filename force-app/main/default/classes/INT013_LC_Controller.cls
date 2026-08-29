public class INT013_LC_Controller {
    public class Response {
        @AuraEnabled public Integer httpRequestStatusCode;
        @AuraEnabled public string errorCode;
        @AuraEnabled public string errorText;
        @AuraEnabled public boolean updateSuccess;
        @AuraEnabled public String updateErrorMessage;
    }
    @AuraEnabled
    public static INT013_LC_Controller.Response updateFinanAccount(Id recordId) {
          INT013_LC_Controller.Response response = new INT013_LC_Controller.Response();
      
            // Check Identification Number against Electoral Register.
            INT013.Response recordData = INT013.checkFinancialProductDetailputInfo(recordId);
            
            // Store results in response.
            response.errorCode = recordData.errorcode;
            response.errorText = recordData.ErrorText;
        if(response.errorCode == '000') { 
            response.updateSuccess = true;            
        }else{
            response.errorCode = '000';
            response.httpRequestStatusCode = 404;
            response.updateSuccess = false;
            response.updateErrorMessage = 'Error Datos no encontrados';
        }
        
        return response;
    }
    
}