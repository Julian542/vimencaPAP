@RestResource(urlMapping='/fsc/rla-approval-admin/client-decision')
global without sharing class FSC_RlaApprovalAdminDecisionRest {
	global class RequestPayload {
		public Id residentialLoanApplicationId;
		public String accion;
		public String comentarioAuditoria;
	}

	global class ResponsePayload {
		public Boolean success;
		public String message;
	}

	@HttpPost
	global static void registrarDecisionCliente() {
		RestResponse res = RestContext.response;
		ResponsePayload payload = new ResponsePayload();

		try {
			RequestPayload req = (RequestPayload) JSON.deserialize(RestContext.request.requestBody.toString(), RequestPayload.class);

			if (req == null || req.residentialLoanApplicationId == null) {
				res.statusCode = 400;
				payload.success = false;
				payload.message = 'Solicitud requerida.';
			} else if (
				req.accion != FSC_RlaApprovalAdminService.ACCION_CLIENTE_ACEPTA &&
				req.accion != FSC_RlaApprovalAdminService.ACCION_CLIENTE_RECHAZA
			) {
				res.statusCode = 400;
				payload.success = false;
				payload.message = 'Acción de cliente no válida.';
			} else {
				FSC_RlaApprovalAdminService.ejecutarDecisionCliente(req.residentialLoanApplicationId, req.accion, req.comentarioAuditoria);
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