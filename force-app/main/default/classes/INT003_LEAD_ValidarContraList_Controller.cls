/**
 * @description       : Controller invocable/Aura para ejecutar INT003_FSC.validatePF usando Lead (Candidato) en lugar de Account.
 * @author            : Jhonny Peroza
 * @group             : Keystone Advisors
 * @last modified on  : 14-01-2026
 * @last modified by  : jperoza@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
public with sharing class INT003_LEAD_ValidarContraList_Controller {

    public class Response {
        @InvocableVariable @AuraEnabled public Integer httpRequestStatusCode;
        @InvocableVariable @AuraEnabled public String  errorCode;
        @InvocableVariable @AuraEnabled public String  errorText;
        @InvocableVariable @AuraEnabled public Boolean updateSuccess;
        @InvocableVariable @AuraEnabled public String  updateErrorMessage;
    }

    @AuraEnabled
    public static INT003_ValidarContraLista_Controller_FSC.Response validatePF(Id recordId) {
        INT003_ValidarContraLista_Controller_FSC.Response response = tunelCaseFlowLightning(recordId);
        return response;
    }

    @InvocableMethod
    public static List<INT003_ValidarContraLista_Controller_FSC.Response> validatePFFlow(List<Id> recordId) {
        System.debug('INT003_LEAD_ValidarContraList_Controller.validatePFFlow - ID Flow: ' + recordId);
        INT003_ValidarContraLista_Controller_FSC.Response response = tunelCaseFlowLightning(recordId[0]);
        return new List<INT003_ValidarContraLista_Controller_FSC.Response>{ response };
    }

    public static INT003_ValidarContraLista_Controller_FSC.Response tunelCaseFlowLightning(Id recordId) {
        INT003_ValidarContraLista_Controller_FSC.Response response = new INT003_ValidarContraLista_Controller_FSC.Response();

        try {
            List<Lead> leadFound = [SELECT Id, Status FROM Lead WHERE Id = :recordId LIMIT 1];

            if (!leadFound.isEmpty()) {
                if (leadFound[0].Status != 'Calificado') {
                    response.httpRequestStatusCode = 200;
                    response.errorCode = '000';
                    response.errorText = 'VALIDACION NO EJECUTADA';
                    response.updateSuccess = false;
                    response.updateErrorMessage = 'El candidato debe estar en estado Calificado antes de validar contra listas';
                    return response;
                }

                // INT003_LEAD_FSC conserva la respuesta real del servicio en su
                // propiedad estática response. No se debe fabricar un resultado
                // exitoso aquí, porque el callout puede haber respondido con error.
                INT003_LEAD_FSC.validatePF(recordId);

                INT003_LEAD_FSC.Response serviceResponse = INT003_LEAD_FSC.response;
                if (serviceResponse == null) {
                    response.httpRequestStatusCode = 500;
                    response.errorCode = 'INT003-NULL';
                    response.errorText = 'El servicio de validación contra listas no devolvió respuesta.';
                    response.updateSuccess = false;
                } else {
                    response.httpRequestStatusCode = serviceResponse.requestStatusCode;
                    response.errorCode = serviceResponse.errorCode;
                    response.errorText = serviceResponse.errorText;
                    response.updateSuccess = serviceResponse.requestStatusCode == 200 &&
                                             serviceResponse.errorCode == '000';

                    if (serviceResponse.requestStatusCode != 200 && String.isBlank(response.errorCode)) {
                        response.errorCode = 'HTTP-' + String.valueOf(serviceResponse.requestStatusCode);
                    }
                    if (serviceResponse.requestStatusCode != 200 && String.isBlank(response.errorText)) {
                        response.errorText = 'El servicio de validación contra listas respondió HTTP ' +
                                             String.valueOf(serviceResponse.requestStatusCode) + ' - ' +
                                             serviceResponse.requestStatus;
                    }
                }

            } else {
                throw new XmlException('No hay Lead (Candidato) con el id :: ' + recordId);
            }

        } catch (Exception e) {
            String msg = e.getMessage();
            System.debug('INT003_ValidarContraLista_Controller_FSC.tunelCaseFlowLightning - ERROR: ' + msg);

            if (msg != null && msg.containsIgnoreCase('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                response.updateErrorMessage = e.getMessage().substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': [');
            } else {
                response.updateErrorMessage = e.getMessage();
            }

            response.errorText = 'ERROR NO CONTROLADO :: ' + e.getMessage();
            response.updateSuccess = false;
        }

        return response;
    }
}