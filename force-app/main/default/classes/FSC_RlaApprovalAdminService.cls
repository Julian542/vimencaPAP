public without sharing class FSC_RlaApprovalAdminService {
    private static final String RECALL_COMMENT = 'Proceso cancelado desde sistema.';
    @TestVisible
    private static Boolean testForceRemoveFailure = false;

    public static void sendToSupervisor(Id residentialLoanApplicationId) {
        if (residentialLoanApplicationId == null) {
            throw new AuraHandledException('Solicitud requerida.');
        }

        recallApproval(residentialLoanApplicationId);
        markSupervisorReview(residentialLoanApplicationId);
    }

    public static void returnToAnalyst(Id residentialLoanApplicationId, String motivo) {
        if (residentialLoanApplicationId == null) {
            throw new AuraHandledException('Solicitud requerida.');
        }
        if (String.isBlank(motivo)) {
            throw new AuraHandledException('Motivo requerido.');
        }
        if (motivo.length() > 255) {
            throw new AuraHandledException('Motivo excede 255 caracteres.');
        }

        recallApproval(residentialLoanApplicationId);
        markReturnToAnalyst(residentialLoanApplicationId, motivo);
    }

    public static void returnToBusiness(
        Id residentialLoanApplicationId,
        String motivo,
        String profileName
    ) {
        if (residentialLoanApplicationId == null) {
            throw new AuraHandledException('Solicitud requerida.');
        }
        if (String.isBlank(motivo)) {
            throw new AuraHandledException('Motivo requerido.');
        }
        if (motivo.length() > 255) {
            throw new AuraHandledException('Motivo excede 255 caracteres.');
        }

        recallApproval(residentialLoanApplicationId);
        markReturnToBusiness(residentialLoanApplicationId, motivo, profileName);
    }

    @TestVisible
    public static Boolean isRecallPermissionIssue(String message) {
        String normalizedMessage = message == null ? '' : message.toLowerCase();

        return normalizedMessage.contains('insufficient access') ||
            normalizedMessage.contains('insufficient_access') ||
            normalizedMessage.contains('you do not have permission') ||
            normalizedMessage.contains('you don\'t have permission') ||
            normalizedMessage.contains('not allowed to recall') ||
            normalizedMessage.contains('cannot recall') ||
            normalizedMessage.contains('cant recall') ||
            normalizedMessage.contains('cannot remove') ||
            normalizedMessage.contains('cant remove') ||
            normalizedMessage.contains('recall');
    }

    @TestVisible
    private static void recallApproval(Id residentialLoanApplicationId) {
        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :residentialLoanApplicationId
            ORDER BY CreatedDate DESC
        ];

        for (ProcessInstanceWorkitem wi : workItems) {
            removeWorkItem(wi.Id);
        }
    }

    @TestVisible
    private static void removeWorkItem(Id workItemId) {
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setWorkitemId(workItemId);
        req.setAction('Removed');
        req.setComments(RECALL_COMMENT);

        if (Test.isRunningTest() && testForceRemoveFailure) {
            throw buildRecallFailure(null);
        }

        Approval.ProcessResult result = Approval.process(req);
        if (!result.isSuccess()) {
            throw buildRecallFailure(result);
        }
    }

    @TestVisible
    private static void markSupervisorReview(Id residentialLoanApplicationId) {
        update new ResidentialLoanApplication(
            Id = residentialLoanApplicationId,
            FSC_DebeRevisarSupervisor__c = true
        );
    }

    @TestVisible
    private static void markReturnToAnalyst(Id residentialLoanApplicationId, String motivo) {
        update new ResidentialLoanApplication(
            Id = residentialLoanApplicationId,
            FSC_DebeRevisarSupervisor__c = false,
            FSC_ObservacionSupervisor__c = motivo
        );
    }

    @TestVisible
    private static void markReturnToBusiness(
        Id residentialLoanApplicationId,
        String motivo,
        String profileName
    ) {
        ResidentialLoanApplication rlaUpd = new ResidentialLoanApplication(
            Id = residentialLoanApplicationId,
            FSC_DebeRevisarComite__c = false,
            FSC_DebeRevisarSupervisor__c = false,
            FSC_Doc_Completa_Analisis__c = false,
            FSC_DocumentacionValidadaAnalista__c = false,
            FSC_Subestado__c = 'Recepción de documentos – Análisis'
        );

        String norm = normalize(profileName);
        if (norm == normalize('Analista de crédito')) {
            rlaUpd.FSC_ObservacionAnalistaDeCredito__c = motivo;
        } else if (norm == normalize('Supervisor')) {
            rlaUpd.FSC_ObservacionSupervisor__c = motivo;
        } else if (
            norm == normalize('Comité de crédito') ||
            norm == normalize('Comite de credito')
        ) {
            rlaUpd.FSC_ObservacionesComite__c = motivo;
        } else {
            rlaUpd.FSC_ObservacionAnalistaDeCredito__c = motivo;
        }

        update rlaUpd;
    }

    @TestVisible
    private static String normalize(String s) {
        if (s == null) return '';
        String out = s.trim().toLowerCase();
        out = out.replace('á','a').replace('é','e').replace('í','i').replace('ó','o').replace('ú','u');
        out = out.replace('ü','u').replace('ñ','n');
        out = out.replace('–', ' ').replace('-', ' ');
        out = out.replaceAll('\\s+', ' ').trim();
        return out;
    }

    @TestVisible
    private static AuraHandledException buildRecallFailure(Approval.ProcessResult result) {
        List<String> errors = new List<String>();
        if (result != null && result.getErrors() != null) {
            for (Database.Error errorItem : result.getErrors()) {
                if (errorItem != null && String.isNotBlank(errorItem.getMessage())) {
                    errors.add(errorItem.getMessage());
                }
            }
        }

        return new AuraHandledException(
            errors.isEmpty() ? 'No se pudo cancelar el proceso.' : String.join(errors, ' | ')
        );
    }
}