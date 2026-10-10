@RestResource(urlMapping='/fsc/rla-approval-admin/return-to-analyst')
global without sharing class FSC_RlaApprovalAdminReturnToAnalystRest {
    global class RequestPayload {
        public Id residentialLoanApplicationId;
        public String motivo;
    }

    global class ResponsePayload {
        public Boolean success;
        public String message;
    }

    @HttpPost
    global static void returnToAnalyst() {
        RestResponse res = RestContext.response;
        ResponsePayload payload = new ResponsePayload();

        try {
            RequestPayload req = (RequestPayload) JSON.deserialize(
                RestContext.request.requestBody.toString(),
                RequestPayload.class
            );

            if (req == null || req.residentialLoanApplicationId == null) {
                res.statusCode = 400;
                payload.success = false;
                payload.message = 'Solicitud requerida.';
            } else if (String.isBlank(req.motivo)) {
                res.statusCode = 400;
                payload.success = false;
                payload.message = 'Motivo requerido.';
            } else {
                FSC_RlaApprovalAdminService.returnToAnalyst(
                    req.residentialLoanApplicationId,
                    req.motivo
                );
                res.statusCode = 200;
                payload.success = true;
                payload.message = 'OK';
            }
        } catch (Exception ex) {
            res.statusCode = 500;
            payload.success = false;
            payload.message = ex.getMessage();
        }

        res.responseBody = Blob.valueOf(JSON.serialize(payload));
    }
}