trigger FSC_ResidentialLoanApplicationTrigger on ResidentialLoanApplication (
    before insert,
    before update,
    after insert,
    after update
) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            FSC_TipoGarantiaService.setDefaultOnInsert(Trigger.new);
            FSC_RLATriggerHandler.beforeInsert(Trigger.new);
        }

        if (Trigger.isUpdate) {
            FSC_RLATriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        FSC_RLATriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        FSC_CapturaOperacionesService.compartirSolicitudes(Trigger.new, null);
    }
}