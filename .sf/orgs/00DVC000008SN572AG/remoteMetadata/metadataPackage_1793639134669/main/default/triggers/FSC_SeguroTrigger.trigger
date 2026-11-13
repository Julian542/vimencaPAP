trigger FSC_SeguroTrigger on FSC_Seguro__c(before insert, before update, before delete) {
	if (Trigger.isDelete) {
		FSC_CreditoAprobadoLockService.validarSeguros(Trigger.old);
	} else {
		FSC_CreditoAprobadoLockService.validarSeguros(Trigger.new, Trigger.oldMap, Trigger.isInsert);
	}
}