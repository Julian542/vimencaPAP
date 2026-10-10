public with sharing class FSC_ExcepcionApprovalService {
	@TestVisible
	private static Boolean testForceAuthorized = false;
	public static final String PROCESS_DEVELOPER_NAME = 'FSC_ExcepcionesDeCredito';
	private static final String PERMISO_ADMINISTRADOR = 'FSC_CP_Administrador';

	public static void submit(Id excepcionId) {
		Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
		request.setObjectId(excepcionId);
		request.setProcessDefinitionNameOrId(PROCESS_DEVELOPER_NAME);
		request.setSubmitterId(UserInfo.getUserId());
		request.setComments('Solicitud de excepción de crédito registrada.');
		validateResult(Approval.process(request), 'No se pudo enviar la excepción al proceso de aprobación.');
	}

	public static Map<Id, List<ProcessInstanceWorkitem>> getWorkItemsByTarget(Set<Id> targetIds) {
		Map<Id, List<ProcessInstanceWorkitem>> result = new Map<Id, List<ProcessInstanceWorkitem>>();
		for (ProcessInstanceWorkitem workItem : FSC_ExcepcionSelector.selectWorkItems(targetIds)) {
			if (workItem.ProcessInstance.ProcessDefinition.DeveloperName != PROCESS_DEVELOPER_NAME) {
				continue;
			}
			Id targetId = workItem.ProcessInstance.TargetObjectId;
			if (!result.containsKey(targetId)) {
				result.put(targetId, new List<ProcessInstanceWorkitem>());
			}
			result.get(targetId).add(workItem);
		}
		return result;
	}

	public static Boolean canCurrentUserAct(ProcessInstanceWorkitem workItem) {
		return findActionableWorkItem(workItem == null ? null : new List<ProcessInstanceWorkitem>{ workItem }) != null;
	}

	public static Boolean canCurrentUserAct(List<ProcessInstanceWorkitem> workItems) {
		return findActionableWorkItem(workItems) != null;
	}

	public static Set<Id> getActionableTargetIds(Map<Id, List<ProcessInstanceWorkitem>> workItemsByTarget) {
		Set<Id> targetIds = new Set<Id>();
		if (workItemsByTarget == null || workItemsByTarget.isEmpty()) {
			return targetIds;
		}

		List<ProcessInstanceWorkitem> allWorkItems = new List<ProcessInstanceWorkitem>();
		for (List<ProcessInstanceWorkitem> workItems : workItemsByTarget.values()) {
			if (workItems != null) {
				allWorkItems.addAll(workItems);
			}
		}
		Set<Id> authorizedActorIds = findAuthorizedActorIds(allWorkItems);
		for (Id targetId : workItemsByTarget.keySet()) {
			List<ProcessInstanceWorkitem> targetWorkItems = workItemsByTarget.get(targetId);
			if (targetWorkItems == null) {
				continue;
			}
			for (ProcessInstanceWorkitem workItem : targetWorkItems) {
				if (authorizedActorIds.contains(workItem.ActorId)) {
					targetIds.add(targetId);
					break;
				}
			}
		}
		return targetIds;
	}

	public static void assertCurrentUserCanAct(Id targetId) {
		getActionableWorkItem(targetId);
	}

	public static Approval.ProcessResult process(Id targetId, String action, String comments) {
		ProcessInstanceWorkitem workItem = getActionableWorkItem(targetId);
		Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
		request.setWorkitemId(workItem.Id);
		request.setAction(action);
		request.setComments(comments);
		Approval.ProcessResult result = Approval.process(request);
		validateResult(result, 'No se pudo procesar la decisión de la excepción.');
		return result;
	}

	public static Boolean hasActiveWorkItem(Id targetId) {
		if (targetId == null) {
			return false;
		}
		Map<Id, List<ProcessInstanceWorkitem>> workItems = getWorkItemsByTarget(new Set<Id>{ targetId });
		return workItems.containsKey(targetId) && !workItems.get(targetId).isEmpty();
	}

	private static ProcessInstanceWorkitem getActionableWorkItem(Id targetId) {
		if (targetId == null) {
			throw new AuraHandledException('Excepción requerida.');
		}
		Map<Id, List<ProcessInstanceWorkitem>> workItems = getWorkItemsByTarget(new Set<Id>{ targetId });
		if (!workItems.containsKey(targetId) || workItems.get(targetId).isEmpty()) {
			throw new AuraHandledException('No hay una aprobación de excepción pendiente.');
		}
		ProcessInstanceWorkitem workItem = findActionableWorkItem(workItems.get(targetId));
		if (workItem == null) {
			throw new AuraHandledException('Usted no es el aprobador asignado para esta excepción.');
		}
		return workItem;
	}

	private static ProcessInstanceWorkitem findActionableWorkItem(List<ProcessInstanceWorkitem> workItems) {
		if (workItems == null || workItems.isEmpty()) {
			return null;
		}
		Set<Id> authorizedActorIds = findAuthorizedActorIds(workItems);
		for (ProcessInstanceWorkitem workItem : workItems) {
			if (authorizedActorIds.contains(workItem.ActorId)) {
				return workItem;
			}
		}
		return null;
	}

	private static Set<Id> findAuthorizedActorIds(List<ProcessInstanceWorkitem> workItems) {
		Set<Id> authorizedActorIds = new Set<Id>();
		if (workItems == null || workItems.isEmpty()) {
			return authorizedActorIds;
		}
		if ((Test.isRunningTest() && testForceAuthorized) || FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR)) {
			for (ProcessInstanceWorkitem workItem : workItems) {
				authorizedActorIds.add(workItem.ActorId);
			}
			return authorizedActorIds;
		}

		Id currentUserId = UserInfo.getUserId();
		Set<Id> rootGroupIds = new Set<Id>();
		for (ProcessInstanceWorkitem workItem : workItems) {
			if (workItem.ActorId == currentUserId) {
				authorizedActorIds.add(currentUserId);
			} else if (workItem.ActorId != null && String.valueOf(workItem.ActorId).startsWith('00G')) {
				rootGroupIds.add(workItem.ActorId);
			}
		}
		authorizedActorIds.addAll(findGroupsContainingUser(rootGroupIds, currentUserId));
		return authorizedActorIds;
	}

	private static Set<Id> findGroupsContainingUser(Set<Id> rootGroupIds, Id userId) {
		Set<Id> authorizedGroupIds = new Set<Id>();
		if (rootGroupIds == null || rootGroupIds.isEmpty()) {
			return authorizedGroupIds;
		}

		Set<Id> nestedGroupIds = new Set<Id>();
		Map<Id, Set<Id>> rootGroupsByNestedGroupId = new Map<Id, Set<Id>>();
		for (GroupMember member : [
			SELECT GroupId, UserOrGroupId
			FROM GroupMember
			WHERE GroupId IN :rootGroupIds
			WITH SYSTEM_MODE
		]) {
			if (member.UserOrGroupId == userId) {
				authorizedGroupIds.add(member.GroupId);
			}
			if (String.valueOf(member.UserOrGroupId).startsWith('00G')) {
				nestedGroupIds.add(member.UserOrGroupId);
				if (!rootGroupsByNestedGroupId.containsKey(member.UserOrGroupId)) {
					rootGroupsByNestedGroupId.put(member.UserOrGroupId, new Set<Id>());
				}
				rootGroupsByNestedGroupId.get(member.UserOrGroupId).add(member.GroupId);
			}
		}
		if (nestedGroupIds.isEmpty()) {
			return authorizedGroupIds;
		}
		for (GroupMember nestedMember : [
			SELECT GroupId
			FROM GroupMember
			WHERE GroupId IN :nestedGroupIds AND UserOrGroupId = :userId
			WITH SYSTEM_MODE
		]) {
			authorizedGroupIds.addAll(rootGroupsByNestedGroupId.get(nestedMember.GroupId));
		}
		return authorizedGroupIds;
	}

	private static void validateResult(Approval.ProcessResult result, String defaultMessage) {
		if (result != null && result.isSuccess()) {
			return;
		}
		List<String> messages = getErrorMessages(result);
		throw new AuraHandledException(messages.isEmpty() ? defaultMessage : String.join(messages, ' | '));
	}

	private static List<String> getErrorMessages(Approval.ProcessResult result) {
		List<String> messages = new List<String>();
		if (result == null || result.getErrors() == null) {
			return messages;
		}
		for (Database.Error errorItem : result.getErrors()) {
			if (errorItem == null || String.isBlank(errorItem.getMessage())) {
				continue;
			}
			messages.add(errorItem.getMessage());
		}
		return messages;
	}
}