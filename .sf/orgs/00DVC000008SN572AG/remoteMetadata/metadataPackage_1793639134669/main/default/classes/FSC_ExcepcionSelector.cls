public inherited sharing class FSC_ExcepcionSelector {
	public static ResidentialLoanApplication selectSolicitud(Id solicitudId) {
		if (solicitudId == null) {
			return null;
		}
		List<ResidentialLoanApplication> solicitudes = [
			SELECT Id, Status, FSC_Subestado__c, FSC_Monto__c, FSC_Aplica_Garantia__c, FSC_Cantidad_Excepciones__c
			FROM ResidentialLoanApplication
			WHERE Id = :solicitudId
			WITH USER_MODE
			LIMIT 1
		];
		return solicitudes.isEmpty() ? null : solicitudes[0];
	}

	public static List<FSC_Excepcion__c> selectBySolicitud(Id solicitudId) {
		if (solicitudId == null) {
			return new List<FSC_Excepcion__c>();
		}
		return [
			SELECT Id, Name, FSC_Solicitud_Prestamo__c, FSC_Tipo__c, FSC_Detalle__c, FSC_Motivo__c, FSC_Estado__c, FSC_Condicion__c, CreatedDate
			FROM FSC_Excepcion__c
			WHERE FSC_Solicitud_Prestamo__c = :solicitudId
			WITH USER_MODE
			ORDER BY CreatedDate DESC, Id DESC
		];
	}

	public static FSC_Excepcion__c selectById(Id excepcionId) {
		if (excepcionId == null) {
			return null;
		}
		List<FSC_Excepcion__c> excepciones = [
			SELECT Id, FSC_Solicitud_Prestamo__c, FSC_Tipo__c, FSC_Detalle__c, FSC_Motivo__c, FSC_Estado__c, FSC_Condicion__c
			FROM FSC_Excepcion__c
			WHERE Id = :excepcionId
			WITH USER_MODE
			LIMIT 1
		];
		return excepciones.isEmpty() ? null : excepciones[0];
	}

	public static List<ProcessInstanceWorkitem> selectWorkItems(Set<Id> targetIds) {
		if (targetIds == null || targetIds.isEmpty()) {
			return new List<ProcessInstanceWorkitem>();
		}
		return [
			SELECT Id, ActorId, ProcessInstance.TargetObjectId, ProcessInstance.ProcessDefinition.DeveloperName, CreatedDate
			FROM ProcessInstanceWorkitem
			WHERE ProcessInstance.TargetObjectId IN :targetIds
			WITH SYSTEM_MODE
			ORDER BY CreatedDate DESC
		];
	}
}