trigger FSC_ExcepcionTrigger on FSC_Excepcion__c(before insert, before delete, after update) {
	if (Trigger.isBefore && Trigger.isInsert) {
		FSC_ExcepcionTriggerHandler.beforeInsert(Trigger.new);
	}
	if (Trigger.isBefore && Trigger.isDelete) {
		FSC_ExcepcionTriggerHandler.beforeDelete(Trigger.old);
	}
	if (Trigger.isAfter && Trigger.isUpdate) {
		FSC_ExcepcionTriggerHandler.afterUpdate(Trigger.newMap, Trigger.oldMap);
	}
}