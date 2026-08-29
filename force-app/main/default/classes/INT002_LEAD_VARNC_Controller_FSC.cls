/**
 * @description       :
 * @author            : lplatino@keystoneadvisors.cl
 * @group             :
 * @last modified on  : 02-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
 **/
@SuppressWarnings('PMD')
public with sharing class INT002_LEAD_VARNC_Controller_FSC {
  public class TestUpdateException extends Exception {
  }
  @TestVisible
  static Boolean forceUpdateException = false;

  @TestVisible
  static String forceUpdateExceptionMessage = 'FIELD_CUSTOM_VALIDATION_EXCEPTION, simulated validation: [Lead.Status]';

  public class Response {
    @AuraEnabled
    public Integer httpRequestStatusCode;
    @AuraEnabled
    public string errorCode;
    @AuraEnabled
    public string errorText;
    @AuraEnabled
    public boolean updateSuccess;
    @AuraEnabled
    public String updateErrorMessage;
  }

  public class QualificationState {
    @AuraEnabled public String status;
    @AuraEnabled public Boolean pendingApproval;
    @AuraEnabled public Boolean finished;
  }

  @AuraEnabled
  public static QualificationState getQualificationState(Id recordId) {
    Lead candidate = [SELECT Status FROM Lead WHERE Id = :recordId LIMIT 1];
    Boolean hasPendingApproval = [
      SELECT COUNT()
      FROM ProcessInstance
      WHERE TargetObjectId = :recordId AND Status = 'Pending'
    ] > 0;

    QualificationState state = new QualificationState();
    state.status = candidate.Status;
    state.pendingApproval = hasPendingApproval;
    state.finished = candidate.Status == 'Validado' || hasPendingApproval;
    return state;
  }

  @AuraEnabled
  public static INT002_VARNC_Controller_FSC.Response updateLeadRNC(Id recordId) {
    INT002_VARNC_Controller_FSC.Response response = new INT002_VARNC_Controller_FSC.Response();

    Lead lea = [
      SELECT Id, Name, LEA_RNC__c, LEA_Nombre_Corto_Comercial__c, Status
      FROM Lead
      WHERE Id = :recordId
    ];
    // Check Identification Number against Electoral Register.
    INT002_FSC.Response recordData = INT002_FSC.validateRNC(lea.LEA_RNC__c);

    // Store results in response.
    response.httpRequestStatusCode = recordData.requestStatusCode;
    response.errorCode = recordData.ErrorCode;
    response.errorText = recordData.ErrorText;

    if (response.errorCode == '000') {
        lea.LEA_Nombre_Corto_Comercial__c = recordData.values.get('NombreCorto').toString();
        lea.LEA_RNC__c = recordData.values.get('RNC').toString();
        lea.Status = 'Validado';
        try {
          if (Test.isRunningTest() && forceUpdateException) {
            throw new TestUpdateException(forceUpdateExceptionMessage);
          }
          update lea;
          response.updateSuccess = true;
        } catch (Exception e) {
          String msg = e.getMessage();

          if (msg.containsIgnoreCase('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
            response.updateErrorMessage = e.getMessage().substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': [');
          } else {
            response.updateErrorMessage = e.getMessage();
          }
          response.updateSuccess = false;
        }
    }
    return response;
  }
}