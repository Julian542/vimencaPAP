/**
 * @description       : an adapted version of 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 02-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
public with sharing class INT013_LC_Controller_FSC {
    public class Response {
        @AuraEnabled public Integer httpRequestStatusCode;
        @AuraEnabled public string errorCode;
        @AuraEnabled public string errorText;
        @AuraEnabled public boolean updateSuccess;
        @AuraEnabled public String updateErrorMessage;
    }
    @AuraEnabled
    public static INT013_LC_Controller_FSC.Response updateFinanAccount(Id recordId) {
          INT013_LC_Controller_FSC.Response response = new INT013_LC_Controller_FSC.Response();

            // Check Identification Number against Electoral Register.
            INT013_FSC.Response recordData = INT013_FSC.checkFinancialProductDetailputInfo(recordId);

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