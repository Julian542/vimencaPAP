/**
 * @description       : Trigger para iniciar la creación automática de productos financieros en CORE
 *                      cuando se crea una cuenta financiera en FSC.
 * @author            : Jhonny Peroza / Keystone Advisors
 * @last modified on  : 06-07-2026
**/
trigger FinancialAccountTrigger on FinServ__FinancialAccount__c (
    before insert,
    after insert,
    after update
) {

    System.debug('FinancialAccountTrigger | Inicio');

    if (Trigger.isBefore && Trigger.isInsert) {
        FinancialAccountTriggerHandler.beforeInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        FinancialAccountTriggerHandler.afterInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        FinancialAccountTriggerHandler.afterUpdate(Trigger.new);
    }
}