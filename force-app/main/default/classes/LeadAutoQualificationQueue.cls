/**
 * Califica automaticamente los candidatos Persona Natural y valida el RNC
 * de los candidatos Persona Juridica al crearlos.
 *
 * Las etapas Padron y PEP se ejecutan en Queueables separados porque la
 * primera integracion actualiza el Lead y Salesforce no permite otro callout
 * despues de DML pendiente en la misma transaccion.
 */
public without sharing class LeadAutoQualificationQueue implements Queueable, Database.AllowsCallouts {
    private static final String PERSON_LEAD_RECORD_TYPE = 'Candidato_Persona_Natural';
    private static final String COMPANY_LEAD_RECORD_TYPE = 'Candidato_Persona_Juridica';
    private static final String APPROVAL_PROCESS = 'PA_Flujo_Aprobacion_LEAD';
    private static final String REVIEW_STATUS = 'Validado';
    private static final String REVIEW_SUBSTATUS = 'EN REVISIÓN';

    private enum QualificationStage { ELECTORAL_REGISTER, PEP, RNC, PASSPORT_APPROVAL }

    private List<Id> leadIds;
    private QualificationStage currentStage;

    private LeadAutoQualificationQueue(List<Id> leadIds, QualificationStage qualificationStage) {
        this.leadIds = leadIds == null ? new List<Id>() : new List<Id>(leadIds);
        this.currentStage = qualificationStage;
    }

    public static void enqueueEligibleLeads(List<Lead> insertedLeads) {
        if (insertedLeads == null || insertedLeads.isEmpty()) {
            return;
        }

        Id personRecordTypeId = Schema.SObjectType.Lead
            .getRecordTypeInfosByDeveloperName()
            .get(PERSON_LEAD_RECORD_TYPE)
            .getRecordTypeId();
        Id companyRecordTypeId = Schema.SObjectType.Lead
            .getRecordTypeInfosByDeveloperName()
            .get(COMPANY_LEAD_RECORD_TYPE)
            .getRecordTypeId();

        List<Id> eligiblePersonIds = new List<Id>();
        List<Id> eligiblePassportIds = new List<Id>();
        List<Id> eligibleCompanyIds = new List<Id>();
        for (Lead leadRecord : insertedLeads) {
            if (leadRecord != null &&
                leadRecord.Id != null &&
                leadRecord.RecordTypeId == personRecordTypeId &&
                leadRecord.LEA_TipoIdentificacion__c == 'Cédula' &&
                String.isNotBlank(leadRecord.LEA_NumIdentificacion__c)) {
                eligiblePersonIds.add(leadRecord.Id);
            } else if (leadRecord != null &&
                leadRecord.Id != null &&
                leadRecord.RecordTypeId == personRecordTypeId &&
                leadRecord.LEA_TipoIdentificacion__c == 'Pasaporte' &&
                String.isNotBlank(leadRecord.LEA_NumIdentificacion__c)) {
                eligiblePassportIds.add(leadRecord.Id);
            } else if (leadRecord != null &&
                leadRecord.Id != null &&
                leadRecord.RecordTypeId == companyRecordTypeId &&
                String.isNotBlank(leadRecord.LEA_RNC__c)) {
                eligibleCompanyIds.add(leadRecord.Id);
            }
        }

        if (!eligiblePersonIds.isEmpty()) {
            System.enqueueJob(new LeadAutoQualificationQueue(eligiblePersonIds, QualificationStage.ELECTORAL_REGISTER));
        }
        if (!eligiblePassportIds.isEmpty()) {
            System.enqueueJob(new LeadAutoQualificationQueue(eligiblePassportIds, QualificationStage.PASSPORT_APPROVAL));
        }
        if (!eligibleCompanyIds.isEmpty()) {
            System.enqueueJob(new LeadAutoQualificationQueue(eligibleCompanyIds, QualificationStage.RNC));
        }
    }

    public void execute(QueueableContext context) {
        if (leadIds.isEmpty()) {
            return;
        }

        Id currentLeadId = leadIds.remove(0);

        try {
            if (currentStage == QualificationStage.ELECTORAL_REGISTER) {
                runElectoralRegister(currentLeadId);
            } else if (currentStage == QualificationStage.PEP) {
                runPep(currentLeadId);
            } else if (currentStage == QualificationStage.RNC) {
                runRnc(currentLeadId);
            } else {
                runPassportApproval(currentLeadId);
            }
        } catch (Exception error) {
            System.debug(LoggingLevel.ERROR,
                'LeadAutoQualificationQueue error. leadId=' + currentLeadId +
                ', stage=' + currentStage + ', message=' + error.getMessage() +
                ', stack=' + error.getStackTraceString());

            if (currentStage == QualificationStage.RNC) {
                sendRncFailureToApproval(currentLeadId, error.getMessage());
            }
            // Un fallo de una integracion no debe impedir procesar los demas Leads.
            enqueueNextLeadIfAny();
        }
    }

    private void runElectoralRegister(Id leadId) {
        INT001_LEAD_VAER_Controller_FSC.Response response =
            INT001_LEAD_VAER_Controller_FSC.updateAccount(leadId);

        if (response != null && response.updateSuccess == true) {
            System.enqueueJob(new LeadAutoQualificationQueue(
                prepend(leadId, leadIds),
                QualificationStage.PEP
            ));
        } else {
            System.debug(LoggingLevel.WARN,
                'Calificacion automatica: Padron no completado. leadId=' + leadId +
                ', error=' + (response == null ? 'Respuesta nula' : response.updateErrorMessage));
            enqueueNextLeadIfAny();
        }
    }

    private void runPep(Id leadId) {
        INT001_LEAD_VAER_Controller_FSC.Response response =
            INT001_LEAD_VAER_Controller_FSC.updateAccountPEP(leadId);

        if (response != null && response.updateSuccess == true) {
            Lead qualifiedLead = [
                SELECT Id, OwnerId, LEA_Persona_PEP__c
                FROM Lead
                WHERE Id = :leadId
                LIMIT 1
            ];

            if (qualifiedLead.LEA_Persona_PEP__c == 'SI') {
                sendToApproval(qualifiedLead);
            }
        } else {
            System.debug(LoggingLevel.WARN,
                'Calificacion automatica: PEP no completado. leadId=' + leadId +
                ', error=' + (response == null ? 'Respuesta nula' : response.updateErrorMessage));
        }

        enqueueNextLeadIfAny();
    }

    private void runRnc(Id leadId) {
        INT002_VARNC_Controller_FSC.Response response =
            INT002_LEAD_VARNC_Controller_FSC.updateLeadRNC(leadId);

        if (response == null || response.updateSuccess != true) {
            String errorMessage = response == null
                ? 'Respuesta nula'
                : (String.isNotBlank(response.errorText) ? response.errorText : response.updateErrorMessage);
            sendRncFailureToApproval(leadId, errorMessage);
        }

        enqueueNextLeadIfAny();
    }

    private void runPassportApproval(Id leadId) {
        Lead candidate = [SELECT Id, Status FROM Lead WHERE Id = :leadId LIMIT 1];
        INT001_LEAD_VAER_Controller_FSC.Response response =
            INT001_LEAD_VAER_Controller_FSC.submitPassportForApproval(candidate);

        if (response == null || response.updateSuccess != true) {
            System.debug(LoggingLevel.WARN,
                'Aprobación automática de pasaporte no completada. leadId=' + leadId +
                ', error=' + (response == null ? 'Respuesta nula' : response.updateErrorMessage));
        }

        enqueueNextLeadIfAny();
    }

    private static void sendRncFailureToApproval(Id leadId, String errorMessage) {
        Lead candidate = [SELECT Id, Status FROM Lead WHERE Id = :leadId LIMIT 1];
        if (candidate.Status != 'Iniciado') {
            candidate.Status = 'Iniciado';
            update candidate;
        }

        List<ProcessInstance> pendingApprovals = [
            SELECT Id
            FROM ProcessInstance
            WHERE TargetObjectId = :leadId AND Status = 'Pending'
            LIMIT 1
        ];
        if (!pendingApprovals.isEmpty()) {
            return;
        }

        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setObjectId(leadId);
        request.setProcessDefinitionNameOrId(APPROVAL_PROCESS);
        request.setSkipEntryCriteria(true);
        request.setComments(
            'Enviado automáticamente a revisión porque no fue posible validar el RNC. Detalle: ' +
            errorMessage
        );

        Approval.ProcessResult result = Approval.process(request);
        if (!result.isSuccess()) {
            throw new LeadAutoQualificationException(
                'No fue posible enviar el candidato jurídico a aprobación.'
            );
        }
    }

    private static void sendToApproval(Lead qualifiedLead) {
        qualifiedLead.Status = REVIEW_STATUS;
        qualifiedLead.LEA_SubEstado__c = REVIEW_SUBSTATUS;
        update qualifiedLead;

        List<ProcessInstance> pendingApprovals = [
            SELECT Id
            FROM ProcessInstance
            WHERE TargetObjectId = :qualifiedLead.Id
            AND Status = 'Pending'
            LIMIT 1
        ];
        if (!pendingApprovals.isEmpty()) {
            return;
        }

        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setObjectId(qualifiedLead.Id);
        request.setProcessDefinitionNameOrId(APPROVAL_PROCESS);
        request.setComments('Enviado automáticamente a revisión por resultado PEP.');

        Approval.ProcessResult result = Approval.process(request);
        if (!result.isSuccess()) {
            throw new LeadAutoQualificationException('No fue posible enviar el candidato a aprobación.');
        }
    }

    private void enqueueNextLeadIfAny() {
        if (!leadIds.isEmpty()) {
            QualificationStage nextStage = currentStage == QualificationStage.PEP
                ? QualificationStage.ELECTORAL_REGISTER
                : currentStage;
            System.enqueueJob(new LeadAutoQualificationQueue(leadIds, nextStage));
        }
    }

    private static List<Id> prepend(Id firstId, List<Id> remainingIds) {
        List<Id> result = new List<Id>{ firstId };
        result.addAll(remainingIds);
        return result;
    }

    private class LeadAutoQualificationException extends Exception {}
}