public without sharing class FSC_ApprovalHistoryController {
	public class ApprovalHistoryItem {
		@AuraEnabled
		public String id;
		@AuraEnabled
		public String stepName;
		@AuraEnabled
		public String status;
		@AuraEnabled
		public String assignedTo;
		@AuraEnabled
		public String actualApprover;
		@AuraEnabled
		public String comments;
		@AuraEnabled
		public Datetime createdDate;
		@AuraEnabled
		public String createdDateFormatted;
	}

	@AuraEnabled(cacheable=true)
	public static List<ApprovalHistoryItem> getApprovalHistory(Id recordId) {
		if (recordId == null) {
			throw new AuraHandledException('recordId requerido.');
		}

		List<ApprovalHistoryItem> result = new List<ApprovalHistoryItem>();
		String sObjName = recordId.getSObjectType().getDescribe().getName();

		// 1. Obtener historial nativo de ProcessInstance (para RLA, Lead y cuentas con Approval Process)
		List<ProcessInstance> processInstances = [
			SELECT Id, Status, CreatedDate, SubmittedBy.Name, ProcessDefinition.DeveloperName
			FROM ProcessInstance
			WHERE TargetObjectId = :recordId
			ORDER BY CreatedDate DESC
		];

		if (!processInstances.isEmpty()) {
			Set<Id> processInstanceIds = new Set<Id>();
			Set<Id> instanciasCredito = new Set<Id>();
			for (ProcessInstance pi : processInstances) {
				processInstanceIds.add(pi.Id);
				if (pi.ProcessDefinition.DeveloperName == FSC_InstanciasCreditoService.PROCESO)
					instanciasCredito.add(pi.Id);
			}

			List<ProcessInstanceStep> steps = [
				SELECT
					Id,
					ProcessInstanceId,
					StepNodeId,
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
				SELECT Id, ProcessInstanceId, Actor.Name, Actor.Type, OriginalActor.Name, OriginalActor.Type, CreatedDate
				FROM ProcessInstanceWorkitem
				WHERE ProcessInstanceId IN :processInstanceIds
				ORDER BY CreatedDate DESC
			];

			Set<Id> nodeIds = new Set<Id>();
			for (ProcessInstanceStep step : steps)
				if (step.StepNodeId != null)
					nodeIds.add(step.StepNodeId);
			Map<Id, ProcessNode> nodes = new Map<Id, ProcessNode>([SELECT Id, Name, DeveloperName FROM ProcessNode WHERE Id IN :nodeIds]);
			for (ProcessInstanceStep s : steps) {
				String resolvedStepName = nodes.containsKey(s.StepNodeId) ? nodes.get(s.StepNodeId).Name : resolveStepNameFromStatus(s.StepStatus);
				if (
					instanciasCredito.contains(s.ProcessInstanceId) &&
					nodes.containsKey(s.StepNodeId) &&
					nodes.get(s.StepNodeId).DeveloperName == 'Analista'
				) {
					resolvedStepName = 'Decisión de análisis de crédito';
				}
				String mappedStatus = mapStatus(s.StepStatus);

				if (shouldExcludeItem(resolvedStepName, mappedStatus)) {
					continue;
				}

				ApprovalHistoryItem item = new ApprovalHistoryItem();
				item.id = (String) s.Id;
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
				item.id = (String) w.Id;
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
		}

		// 2. Si el registro es una Cuenta (Account), consolidar además el historial custom de PLA y Legal
		if (sObjName == 'Account') {
			appendAccountCustomHistory(recordId, result);
		}

		result.sort(new ApprovalHistoryItemSorter());

		return result;
	}

	/**
	 * Construye y anexa el historial custom de tareas y estado activo de debida diligencia PLA/Legal para Cuentas.
	 */
	private static void appendAccountCustomHistory(Id accountId, List<ApprovalHistoryItem> result) {
		List<Account> accounts = [
			SELECT
				Id,
				Name,
				ACC_Estado__c,
				ACC_SubEstado__c,
				ACC_Resultado_Validacion__c,
				ACC_Abogado_Asignado__c,
				ACC_Abogado_Asignado__r.Name,
				LastModifiedDate,
				LastModifiedBy.Name
			FROM Account
			WHERE Id = :accountId
			LIMIT 1
		];

		if (accounts.isEmpty()) {
			return;
		}

		Account acc = accounts[0];

		// 2.a. Si la cuenta está en revisión activa (PLA o Legal), agregar tarjeta de estado pendiente actual
		Boolean isPendingReview = (acc.ACC_SubEstado__c == 'EN REVISIÓN' ||
		(String.isNotBlank(acc.ACC_Resultado_Validacion__c) &&
		(acc.ACC_Resultado_Validacion__c.equalsIgnoreCase('En revisión') || acc.ACC_Resultado_Validacion__c.equalsIgnoreCase('En Revisión Legal'))));

		if (isPendingReview) {
			String pendingStep = 'Validación PLA / Legal en curso';
			String assignedLawyer = (acc.ACC_Abogado_Asignado__r != null) ? acc.ACC_Abogado_Asignado__r.Name : 'Cola Legal';
			if (String.isNotBlank(acc.ACC_Resultado_Validacion__c) && acc.ACC_Resultado_Validacion__c.equalsIgnoreCase('En Revisión Legal')) {
				pendingStep = 'Revisión Legal de Cliente';
			} else {
				pendingStep = 'Debida Diligencia PLA de Cliente';
				assignedLawyer = 'Cola PLA';
			}

			ApprovalHistoryItem pendingItem = new ApprovalHistoryItem();
			pendingItem.id = 'PENDING_' + acc.Id;
			pendingItem.stepName = pendingStep;
			pendingItem.status = 'Pending';
			pendingItem.assignedTo = assignedLawyer;
			pendingItem.actualApprover = assignedLawyer;
			pendingItem.comments = 'Cliente en proceso formal de validación y control.';
			pendingItem.createdDate = acc.LastModifiedDate;
			pendingItem.createdDateFormatted = formatDateTime(acc.LastModifiedDate);
			result.add(pendingItem);
		}

		// 2.b. Obtener tareas de auditoría registradas en los envíos, devoluciones, rechazos y requerimientos de PLA/Legal
		List<Task> auditTasks = [
			SELECT Id, Subject, Description, Status, CreatedDate, CreatedBy.Name, Owner.Name
			FROM Task
			WHERE
				WhatId = :accountId
				AND (Subject LIKE 'PLA / Legal:%'
				OR Subject LIKE 'PLA:%'
				OR Subject LIKE 'Legal:%'
				OR Subject LIKE '%Devuelto%'
				OR Subject LIKE '%Rechazado%'
				OR Subject LIKE '%Aprobado%')
			ORDER BY CreatedDate DESC
			LIMIT 100
		];

		Boolean hasApprovedStep = false;
		for (Task t : auditTasks) {
			ApprovalHistoryItem item = new ApprovalHistoryItem();
			item.id = (String) t.Id;
			item.stepName = resolveTaskStepName(t.Subject);
			item.status = resolveTaskStatus(t.Subject);
			if (item.status == 'Aprobado') {
				hasApprovedStep = true;
			}
			item.assignedTo = t.Owner != null ? t.Owner.Name : '';
			item.actualApprover = t.CreatedBy != null ? t.CreatedBy.Name : '';
			item.comments = extractTaskComments(t.Description);
			item.createdDate = t.CreatedDate;
			item.createdDateFormatted = formatDateTime(t.CreatedDate);
			result.add(item);
		}

		// 2.c. Fallback de resiliencia: Si la cuenta está APROBADA (ACC_Resultado_Validacion__c == 'Aprobado' o ACC_SubEstado__c == 'ACEPTADO')
		// y aún no existe un ítem formal con status 'Aprobado' en el resultado (por ejemplo cuentas aprobadas previas a la inserción de tareas),
		// sintetizar el hito de aprobación para que se visualice correctamente en el componente.
		Boolean isAccountApproved = (acc.ACC_Resultado_Validacion__c == 'Aprobado' || acc.ACC_SubEstado__c == 'ACEPTADO');
		if (isAccountApproved && !hasApprovedStep) {
			String approver = (acc.ACC_Abogado_Asignado__r != null)
				? acc.ACC_Abogado_Asignado__r.Name
				: (acc.LastModifiedBy != null ? acc.LastModifiedBy.Name : 'Equipo Legal');
			ApprovalHistoryItem approvedItem = new ApprovalHistoryItem();
			approvedItem.id = 'APPROVED_' + acc.Id;
			approvedItem.stepName = 'Dictamen Legal: Cliente Aprobado';
			approvedItem.status = 'Aprobado';
			approvedItem.assignedTo = approver;
			approvedItem.actualApprover = approver;
			approvedItem.comments = 'El cliente y sus recaudos legales han sido validados y aprobados satisfactoriamente.';
			approvedItem.createdDate = acc.LastModifiedDate;
			approvedItem.createdDateFormatted = formatDateTime(acc.LastModifiedDate);
			result.add(approvedItem);
		}
	}

	private static String resolveTaskStepName(String subject) {
		if (String.isBlank(subject))
			return 'Validación de Cliente';
		if (subject.startsWithIgnoreCase('PLA / Legal: Solicitud'))
			return 'Solicitud de Revisión PLA / Legal';
		if (subject.startsWithIgnoreCase('Legal: Cliente Devuelto'))
			return 'Dictamen Legal: Cliente Devuelto';
		if (subject.startsWithIgnoreCase('Legal: Cliente Rechazado'))
			return 'Dictamen Legal: Cliente Rechazado';
		if (subject.startsWithIgnoreCase('Legal: Cliente Aprobado'))
			return 'Dictamen Legal: Cliente Aprobado';
		if (subject.startsWithIgnoreCase('Legal: Requerimiento'))
			return 'Requerimiento de Información Legal';
		if (subject.startsWithIgnoreCase('PLA: Requerimiento'))
			return 'Requerimiento de Evidencias PLA';
		return subject;
	}

	private static String resolveTaskStatus(String subject) {
		if (String.isBlank(subject))
			return 'Enviado';
		String lower = subject.toLowerCase();
		if (lower.contains('devuelto'))
			return 'Devuelto';
		if (lower.contains('rechazado'))
			return 'Rechazado';
		if (lower.contains('aprobado'))
			return 'Aprobado';
		if (lower.contains('requerimiento') || lower.contains('información') || lower.contains('evidencias')) {
			return 'Pendiente Subsanación';
		}
		if (lower.contains('solicitud'))
			return 'Enviado';
		return 'Enviado';
	}

	private static String extractTaskComments(String description) {
		if (String.isBlank(description))
			return '';
		if (description.contains('Motivo / Comentarios:')) {
			return description.substringAfter('Motivo / Comentarios:').trim();
		}
		if (description.contains('Comentarios / Justificación:')) {
			return description.substringAfter('Comentarios / Justificación:').trim();
		}
		if (description.contains('Comentarios adicionales:')) {
			return description.substringAfter('Comentarios adicionales:').trim();
		}
		return description.trim();
	}

	public class ApprovalHistoryItemSorter implements System.Comparator<ApprovalHistoryItem> {
		public Integer compare(ApprovalHistoryItem a, ApprovalHistoryItem b) {
			if (a.createdDate == b.createdDate)
				return 0;
			if (a.createdDate == null)
				return 1;
			if (b.createdDate == null)
				return -1;
			return a.createdDate > b.createdDate ? -1 : 1;
		}
	}

	private static Boolean shouldExcludeItem(String stepName, String status) {
		String normalizedStepName = normalize(stepName);
		String normalizedStatus = normalize(status);

		return normalizedStepName == 'locked' || normalizedStepName == 'unlocked' || normalizedStatus == 'locked' || normalizedStatus == 'unlocked';
	}

	private static String normalize(String value) {
		return String.isBlank(value) ? '' : value.trim().toLowerCase();
	}

	private static String mapStatus(String stepStatus) {
		if (String.isBlank(stepStatus))
			return '';

		String normalized = stepStatus.trim().toLowerCase();

		if (normalized == 'approved')
			return 'Approved';
		if (normalized == 'rejected')
			return 'Rejected';
		if (normalized == 'removed')
			return 'Removed';
		if (normalized == 'recalled')
			return 'Recalled';
		if (normalized == 'started')
			return 'Submitted';
		if (normalized == 'pending')
			return 'Pending';

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
	private static String resolveAssignedTo(String actorName, String actorType, String originalActorName, String originalActorType) {
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
		if (dt == null)
			return '';
		return dt.format('M/d/yyyy, h:mm a');
	}
}