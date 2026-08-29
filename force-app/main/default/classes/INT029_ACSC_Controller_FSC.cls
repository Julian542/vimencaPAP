/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 02-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
public with sharing class INT029_ACSC_Controller_FSC {
public class Response {
        @AuraEnabled public Integer httpRequestStatusCode;
        @AuraEnabled public string errorCode;
        @AuraEnabled public string errorText;
        @AuraEnabled public boolean updateSuccess;
        @AuraEnabled public String updateErrorMessage;
    }
    @AuraEnabled
    public static INT029_ACSC_Controller_FSC.Response updateAccountSC(Id recordId) {
        INT029_ACSC_Controller_FSC.Response response = new INT029_ACSC_Controller_FSC.Response();

        Account acc = [SELECT id, ACC_Score_Crediticio__c,ACC_Ultima_Actualizacion_Score__c FROM Account WHERE id = :recordId];

            // Check Identification Number against Electoral Register.
            INT029_FSC.Response recordData = INT029_FSC.updateSC(acc.id);

            // Store results in response.
            response.httpRequestStatusCode = recordData.requestStatusCode;
            response.errorCode = recordData.ErrorCode;
            response.errorText = recordData.ErrorText;

            if(response.errorCode == '000') {
                acc.ACC_Score_Crediticio__c = recordData.values.get('ScoreCredito').toString();
                System.debug(recordData.values.get('UltimaActualizacionScore').toString());
                String[] dateBuffer = recordData.values.get('UltimaActualizacionScore').toString().split('/');
                //String lo= '01/28/2020';
                //String[] dateBuffer =lo.split('/');
                DAte newData = Date.newInstance(integer.valueof(dateBuffer[2]),integer.valueof(dateBuffer[0]),integer.valueof(dateBuffer[1]));
                System.debug(newData);
                acc.ACC_Ultima_Actualizacion_Score__c = newData.addDays(1);

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
            }else if(response.errorCode == '9903'){
                response.errorCode = '000';
                response.httpRequestStatusCode = 200;
                response.updateSuccess = false;
                response.updateErrorMessage = 'El numero de documento no esta registrado';
            }

        return response;
    }
}//TODO campos de account no estan en el file