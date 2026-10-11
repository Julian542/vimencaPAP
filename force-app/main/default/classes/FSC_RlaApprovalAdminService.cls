public without sharing class FSC_RlaApprovalAdminService {
	private static final String RECALL_COMMENT = 'Proceso cancelado desde sistema.';
	private static final String PERMISO_ADMINISTRADOR = 'FSC_CP_Administrador';
	private static final String PERMISO_ANALISTA_CREDITO = 'FSC_CP_Analista_Credito';
	private static final String PERMISO_COMITE_CREDITO = 'FSC_CP_Comite_Credito';
	private static final String PERMISO_SUPERVISOR = 'FSC_CP_Supervisor';
	private static final String SUBESTADO_GENERACION_PAGARES = 'Generación de pagarés y plantillas';
	private static final String SUBESTADO_RECHAZADA_POR_CLIENTE = 'Rechazada por cliente';
	private static final String STATUS_CERRADA_PERDIDA = 'Cerrada Perdida';
	private static final Integer MAX_LONGITUD_COMENTARIO = 4000;
	public static final String ACCION_CLIENTE_ACEPTA = 'ACEPTA';
	public static final String ACCION_CLIENTE_RECHAZA = 'RECHAZA';
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

	public static void returnToBusiness(Id residentialLoanApplicationId, String motivo, String permisoOrigen) {
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
		markReturnToBusiness(residentialLoanApplicationId, motivo, permisoOrigen);
	}

	public static void ejecutarDecisionCliente(Id residentialLoanApplicationId, String accion, String comentarioAuditoria) {
		if (accion == ACCION_CLIENTE_ACEPTA) {
			clienteAceptaCondicion(residentialLoanApplicationId, comentarioAuditoria);
		} else if (accion == ACCION_CLIENTE_RECHAZA) {
			clienteRechazaCondicion(residentialLoanApplicationId, comentarioAuditoria);
		} else {
			throw new AuraHandledException('Acción de cliente no válida.');
		}
	}

	public static void clienteAceptaCondicion(Id residentialLoanApplicationId, String comentarioAuditoria) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		recallApproval(residentialLoanApplicationId, comentarioAuditoria);
		update new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_Subestado__c = SUBESTADO_GENERACION_PAGARES,
			FSC_SolicitudAprobadaPorComite__c = true,
			FSC_FechaYHoraAprobacionComite__c = System.now()
		);
	}

	public static void clienteRechazaCondicion(Id residentialLoanApplicationId, String comentarioAuditoria) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		recallApproval(residentialLoanApplicationId, comentarioAuditoria);
		update new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			Status = STATUS_CERRADA_PERDIDA,
			FSC_Subestado__c = SUBESTADO_RECHAZADA_POR_CLIENTE
		);
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
		recallApproval(residentialLoanApplicationId, null);
	}

	private static void recallApproval(Id residentialLoanApplicationId, String comentarioAuditoria) {
		List<ProcessInstanceWorkitem> workItems = [
			SELECT Id
			FROM ProcessInstanceWorkitem
			WHERE ProcessInstance.TargetObjectId = :residentialLoanApplicationId
			ORDER BY CreatedDate DESC
		];

		for (ProcessInstanceWorkitem wi : workItems) {
			removeWorkItem(wi.Id, comentarioAuditoria);
		}
	}

	@TestVisible
	private static String buildRecallComment(String comentarioAuditoria) {
		if (String.isBlank(comentarioAuditoria)) {
			return RECALL_COMMENT;
		}
		return (RECALL_COMMENT + ' ' + comentarioAuditoria.trim()).abbreviate(MAX_LONGITUD_COMENTARIO);
	}

	@TestVisible
	private static void removeWorkItem(Id workItemId) {
		removeWorkItem(workItemId, null);
	}

	private static void removeWorkItem(Id workItemId, String comentarioAuditoria) {
		Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
		req.setWorkitemId(workItemId);
		req.setAction('Removed');
		req.setComments(buildRecallComment(comentarioAuditoria));

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
		update new ResidentialLoanApplication(Id = residentialLoanApplicationId, FSC_DebeRevisarSupervisor__c = true);
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
	private static void markReturnToBusiness(Id residentialLoanApplicationId, String motivo, String permisoOrigen) {
		ResidentialLoanApplication rlaUpd = new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_DebeRevisarComite__c = false,
			FSC_DebeRevisarSupervisor__c = false,
			FSC_Doc_Completa_Analisis__c = false,
			FSC_DocumentacionValidadaAnalista__c = false,
			FSC_Subestado__c = 'Recepción de documentos – Análisis'
		);

		if (permisoOrigen == PERMISO_ANALISTA_CREDITO) {
			rlaUpd.FSC_ObservacionAnalistaDeCredito__c = motivo;
		} else if (permisoOrigen == PERMISO_SUPERVISOR) {
			rlaUpd.FSC_ObservacionSupervisor__c = motivo;
		} else if (permisoOrigen == PERMISO_COMITE_CREDITO) {
			rlaUpd.FSC_ObservacionesComite__c = motivo;
		} else if (permisoOrigen == PERMISO_ADMINISTRADOR) {
			rlaUpd.FSC_ObservacionAdministrador__c = motivo;
		} else {
			throw new AuraHandledException('Permiso personalizado de origen no válido.');
		}

		update rlaUpd;
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

		return new AuraHandledException(errors.isEmpty() ? 'No se pudo cancelar el proceso.' : String.join(errors, ' | '));
	}
}