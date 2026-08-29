public with sharing class FSC_RlaApprovalAdminClient {
    @TestVisible
    private static final String NAMED_CREDENTIAL = 'FSC_RlaApprovalAdmin';
    private static final String SUPERVISOR_ENDPOINT =
        'callout:' + NAMED_CREDENTIAL + '/services/apexrest/fsc/rla-approval-admin/supervisor-review';
    private static final String RETURN_TO_BUSINESS_ENDPOINT =
        'callout:' + NAMED_CREDENTIAL + '/services/apexrest/fsc/rla-approval-admin/return-to-business';
    private static final String RETURN_TO_ANALYST_ENDPOINT =
        'callout:' + NAMED_CREDENTIAL + '/services/apexrest/fsc/rla-approval-admin/return-to-analyst';
    private static final String UPDATE_FORMA_DESEMBOLSO_ENDPOINT =
        'callout:' + NAMED_CREDENTIAL + '/services/apexrest/fsc/rla-approval-admin/update-forma-desembolso';

    public static void sendToSupervisor(Id residentialLoanApplicationId) {
        if (residentialLoanApplicationId == null) {
            throw new AuraHandledException('Solicitud requerida.');
        }

        sendRequest(
            SUPERVISOR_ENDPOINT,
            new RequestPayload(residentialLoanApplicationId, null, null),
            'No se pudo ejecutar el fallback tecnico para enviar a Supervisor.'
        );
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

        sendRequest(
            RETURN_TO_ANALYST_ENDPOINT,
            new RequestPayload(residentialLoanApplicationId, motivo, null),
            'No se pudo ejecutar el fallback tecnico para devolver a Analista.'
        );
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

        sendRequest(
            RETURN_TO_BUSINESS_ENDPOINT,
            new RequestPayload(residentialLoanApplicationId, motivo, profileName),
            'No se pudo ejecutar el fallback tecnico para devolver a Oficial.'
        );
    }

    public static void updateFormaDeDesembolso(Id residentialLoanApplicationId, String formaDeDesembolso) {
        if (residentialLoanApplicationId == null) {
            throw new AuraHandledException('Solicitud requerida.');
        }
        if (String.isBlank(formaDeDesembolso)) {
            throw new AuraHandledException('Forma de desembolso requerida.');
        }

        sendRequest(
            UPDATE_FORMA_DESEMBOLSO_ENDPOINT,
            new RequestPayload(residentialLoanApplicationId, null, null, formaDeDesembolso),
            'No se pudo ejecutar el fallback tecnico para guardar la forma de desembolso.'
        );
    }

    private static void sendRequest(String endpoint, RequestPayload payload, String baseErrorMessage) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        req.setBody(JSON.serialize(payload));

        HttpResponse res;
        try {
            res = new Http().send(req);
        } catch (Exception ex) {
            throw new AuraHandledException(
                baseErrorMessage + ' ' +
                'Verifica la configuracion del Named Credential legado ' + NAMED_CREDENTIAL + '. ' +
                ex.getMessage()
            );
        }

        if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
            throw new AuraHandledException(buildResponseError(res, baseErrorMessage));
        }
    }

    private static String buildResponseError(HttpResponse res, String baseErrorMessage) {
        String responseBody = res == null ? null : res.getBody();
        String message = String.isBlank(responseBody)
            ? baseErrorMessage
            : responseBody;

        return baseErrorMessage + ' ' + message;
    }

    private class RequestPayload {
        public Id residentialLoanApplicationId;
        public String motivo;
        public String profileName;
        public String formaDeDesembolso;

        RequestPayload(Id residentialLoanApplicationId, String motivo, String profileName) {
            this(residentialLoanApplicationId, motivo, profileName, null);
        }

        RequestPayload(Id residentialLoanApplicationId, String motivo, String profileName, String formaDeDesembolso) {
            this.residentialLoanApplicationId = residentialLoanApplicationId;
            this.motivo = motivo;
            this.profileName = profileName;
            this.formaDeDesembolso = formaDeDesembolso;
        }
    }
}