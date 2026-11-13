public without sharing class FSC_AutoApproveGestionPlanillasQueueable implements Queueable {
    private static final String PROCESS_DEVELOPER_NAME = 'FSC_GestionPlanillasDeDesembolso';
    private static final String APPROVAL_COMMENT = 'Aprobado automaticamente al completar la planilla de desembolso.';

    private final Set<Id> residentialLoanApplicationIds;

    @TestVisible
    private class WorkItemCandidate {
        @TestVisible private Id workItemId;
        @TestVisible private Id actorId;
        @TestVisible private String processStatus;
        @TestVisible private String processDeveloperName;

        @TestVisible
        private WorkItemCandidate(
            Id workItemId,
            Id actorId,
            String processStatus,
            String processDeveloperName
        ) {
            this.workItemId = workItemId;
            this.actorId = actorId;
            this.processStatus = processStatus;
            this.processDeveloperName = processDeveloperName;
        }
    }

    public FSC_AutoApproveGestionPlanillasQueueable(Set<Id> residentialLoanApplicationIds) {
        this.residentialLoanApplicationIds = residentialLoanApplicationIds == null
            ? new Set<Id>()
            : new Set<Id>(residentialLoanApplicationIds);
    }

    public void execute(QueueableContext context) {
        if (residentialLoanApplicationIds.isEmpty()) {
            return;
        }

        approveCandidates(buildCandidates(residentialLoanApplicationIds), true);
    }

    @TestVisible
    private static List<WorkItemCandidate> buildCandidates(Set<Id> residentialLoanApplicationIds) {
        List<WorkItemCandidate> candidates = new List<WorkItemCandidate>();
        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id,
                   ActorId,
                   ProcessInstance.Status,
                   ProcessInstance.ProcessDefinition.DeveloperName
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId IN :residentialLoanApplicationIds
            ORDER BY CreatedDate DESC
        ];

        if (workItems.isEmpty()) {
            return candidates;
        }

        for (ProcessInstanceWorkitem workItem : workItems) {
            candidates.add(new WorkItemCandidate(
                workItem.Id,
                workItem.ActorId,
                workItem.ProcessInstance.Status,
                workItem.ProcessInstance.ProcessDefinition.DeveloperName
            ));
        }

        return candidates;
    }

    @TestVisible
    private static Integer approveCandidates(List<WorkItemCandidate> candidates, Boolean submitApproval) {
        Integer approvedCount = 0;
        if (candidates == null || candidates.isEmpty()) {
            return approvedCount;
        }

        for (WorkItemCandidate candidate : candidates) {
            if (!shouldApprove(candidate)) {
                continue;
            }

            approvedCount++;
            if (!submitApproval) {
                continue;
            }

            try {
                Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
                request.setWorkitemId(candidate.workItemId);
                request.setAction('Approve');
                request.setComments(APPROVAL_COMMENT);
                Approval.process(request);
            } catch (Exception e) {
                System.debug(
                    LoggingLevel.ERROR,
                    'No se pudo autoaprobar la gestion de planillas de desembolso para el workitem ' +
                    candidate.workItemId + ': ' + e.getMessage()
                );
            }
        }

        return approvedCount;
    }

    @TestVisible
    private static Boolean shouldApprove(WorkItemCandidate candidate) {
        return candidate != null &&
            candidate.processStatus == 'Pending' &&
            candidate.processDeveloperName == PROCESS_DEVELOPER_NAME &&
            candidate.actorId == UserInfo.getUserId();
    }
}