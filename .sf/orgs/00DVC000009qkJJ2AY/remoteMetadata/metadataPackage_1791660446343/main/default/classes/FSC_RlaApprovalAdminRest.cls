@RestResource(urlMapping='/fsc/rla-approval-admin/supervisor-review')
global without sharing class FSC_RlaApprovalAdminRest {
    global class RequestPayload {
        public Id residentialLoanApplicationId;
    }

    global class ResponsePayload {
        public Boolean success;
        public String message;
    }

    @HttpPost
    global static void sendToSupervisor() {
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
            } else {
                FSC_RlaApprovalAdminService.sendToSupervisor(req.residentialLoanApplicationId);
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