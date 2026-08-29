trigger FSC_ResidentialLoanApplicationTrigger on ResidentialLoanApplication (
    before insert,
    before update,
    after update
) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            FSC_RLATriggerHandler.beforeInsert(Trigger.new);
        }

        if (Trigger.isUpdate) {
            FSC_RLATriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        FSC_RLATriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}