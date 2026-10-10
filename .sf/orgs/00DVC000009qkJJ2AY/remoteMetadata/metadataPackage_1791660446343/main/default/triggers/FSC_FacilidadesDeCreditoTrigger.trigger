trigger FSC_FacilidadesDeCreditoTrigger on FSC_Facilidades_De_Credito__c(before insert, before update, before delete, after insert, after update, after delete) {
	if (Trigger.isBefore) {
		if (Trigger.isDelete) {
			FSC_CreditoAprobadoLockService.validarFacilidades(Trigger.old);
		} else {
			FSC_CreditoAprobadoLockService.validarFacilidades(Trigger.new);
		}
	}

	if (Trigger.isAfter) {
		if (Trigger.isInsert) {
			FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(Trigger.new);
		} else if (Trigger.isUpdate) {
			FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(Trigger.new, Trigger.oldMap);
		} else if (Trigger.isDelete) {
			FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(Trigger.old);
		}
	}
}