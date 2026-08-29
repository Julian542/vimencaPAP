trigger FSC_FacilidadesDeCreditoTrigger on FSC_Facilidades_De_Credito__c(after insert, after update, after delete) {
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