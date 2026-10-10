public without sharing class FSC_ApprovalHistoryController {

    public class ApprovalHistoryItem {
        @AuraEnabled public String id;
        @AuraEnabled public String stepName;
        @AuraEnabled public String status;
        @AuraEnabled public String assignedTo;
        @AuraEnabled public String actualApprover;
        @AuraEnabled public String comments;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String createdDateFormatted;
    }

    @AuraEnabled(cacheable=true)
    public static List<ApprovalHistoryItem> getApprovalHistory(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('recordId requerido.');
        }

        List<ApprovalHistoryItem> result = new List<ApprovalHistoryItem>();

        List<ProcessInstance> processInstances = [
            SELECT Id, Status, CreatedDate, SubmittedBy.Name
            FROM ProcessInstance
            WHERE TargetObjectId = :recordId
            ORDER BY CreatedDate DESC
        ];

        if (processInstances.isEmpty()) {
            return result;
        }

        Set<Id> processInstanceIds = new Set<Id>();
        for (ProcessInstance pi : processInstances) {
            processInstanceIds.add(pi.Id);
        }

        List<ProcessInstanceStep> steps = [
            SELECT Id,
                   ProcessInstanceId,
                   StepStatus,
                   Comments,
                   OriginalActor.Name,
                   OriginalActor.Type,
                   Actor.Name,
                   Actor.Type,
                   CreatedDate
            FROM ProcessInstanceStep
            WHERE ProcessInstanceId IN :processInstanceIds
            ORDER BY CreatedDate DESC
        ];

        List<ProcessInstanceWorkitem> workitems = [
            SELECT Id,
                   ProcessInstanceId,
                   Actor.Name,
                   Actor.Type,
                   OriginalActor.Name,
                   OriginalActor.Type,
                   CreatedDate
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstanceId IN :processInstanceIds
            ORDER BY CreatedDate DESC
        ];

        for (ProcessInstanceStep s : steps) {
            String resolvedStepName = resolveStepNameFromStatus(s.StepStatus);
            String mappedStatus = mapStatus(s.StepStatus);

            if (shouldExcludeItem(resolvedStepName, mappedStatus)) {
                continue;
            }

            ApprovalHistoryItem item = new ApprovalHistoryItem();
            item.id = (String)s.Id;
            item.stepName = resolvedStepName;
            item.status = mappedStatus;
            item.assignedTo = resolveAssignedTo(
                s.Actor != null ? s.Actor.Name : '',
                s.Actor != null ? String.valueOf(s.Actor.Type) : '',
                s.OriginalActor != null ? s.OriginalActor.Name : '',
                s.OriginalActor != null ? String.valueOf(s.OriginalActor.Type) : ''
            );
            item.actualApprover = s.Actor != null ? s.Actor.Name : '';
            item.comments = String.isBlank(s.Comments) ? '' : s.Comments;
            item.createdDate = s.CreatedDate;
            item.createdDateFormatted = formatDateTime(s.CreatedDate);
            result.add(item);
        }

        for (ProcessInstanceWorkitem w : workitems) {
            ApprovalHistoryItem item = new ApprovalHistoryItem();
            item.id = (String)w.Id;
            item.stepName = 'Pending Approval';
            item.status = 'Pending';

            if (shouldExcludeItem(item.stepName, item.status)) {
                continue;
            }

            item.assignedTo = resolveAssignedTo(
                w.Actor != null ? w.Actor.Name : '',
                w.Actor != null ? String.valueOf(w.Actor.Type) : '',
                w.OriginalActor != null ? w.OriginalActor.Name : '',
                w.OriginalActor != null ? String.valueOf(w.OriginalActor.Type) : ''
            );
            item.actualApprover = w.OriginalActor != null ? w.OriginalActor.Name : '';
            item.comments = '';
            item.createdDate = w.CreatedDate;
            item.createdDateFormatted = formatDateTime(w.CreatedDate);
            result.add(item);
        }

        result.sort(new ApprovalHistoryItemSorter());

        return result;
    }

    public class ApprovalHistoryItemSorter implements System.Comparator<ApprovalHistoryItem> {
        public Integer compare(ApprovalHistoryItem a, ApprovalHistoryItem b) {
            if (a.createdDate == b.createdDate) return 0;
            if (a.createdDate == null) return 1;
            if (b.createdDate == null) return -1;
            return a.createdDate > b.createdDate ? -1 : 1;
        }
    }

    private static Boolean shouldExcludeItem(String stepName, String status) {
        String normalizedStepName = normalize(stepName);
        String normalizedStatus = normalize(status);

        return normalizedStepName == 'locked'
            || normalizedStepName == 'unlocked'
            || normalizedStatus == 'locked'
            || normalizedStatus == 'unlocked';
    }

    private static String normalize(String value) {
        return String.isBlank(value) ? '' : value.trim().toLowerCase();
    }

    private static String mapStatus(String stepStatus) {
        if (String.isBlank(stepStatus)) return '';

        String normalized = stepStatus.trim().toLowerCase();

        if (normalized == 'approved') return 'Approved';
        if (normalized == 'rejected') return 'Rejected';
        if (normalized == 'removed') return 'Removed';
        if (normalized == 'recalled') return 'Recalled';
        if (normalized == 'started') return 'Submitted';
        if (normalized == 'pending') return 'Pending';

        return stepStatus;
    }

    private static String resolveStepNameFromStatus(String stepStatus) {
        if (String.isBlank(stepStatus)) {
            return 'Approval Step';
        }

        String normalized = stepStatus.trim().toLowerCase();

        if (normalized == 'started') {
            return 'Approval Request Submitted';
        }

        return 'Approval Step';
    }

    @TestVisible
    private static String resolveAssignedTo(
        String actorName,
        String actorType,
        String originalActorName,
        String originalActorType
    ) {
        String normalizedActorType = normalize(actorType);
        String normalizedOriginalActorType = normalize(originalActorType);

        if (normalizedActorType == 'user' && !String.isBlank(actorName)) {
            return actorName;
        }

        if (normalizedOriginalActorType == 'user' && !String.isBlank(originalActorName)) {
            return originalActorName;
        }

        if (!String.isBlank(actorName)) {
            return actorName;
        }

        return String.isBlank(originalActorName) ? '' : originalActorName;
    }

    private static String formatDateTime(Datetime dt) {
        if (dt == null) return '';
        return dt.format('M/d/yyyy, h:mm a');
    }
}