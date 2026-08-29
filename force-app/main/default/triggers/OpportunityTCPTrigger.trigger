/**
 * Name: OpportunityTCPTrigger
 * Description: Encola precalificación cuando la oportunidad entra a Validado + Pendiente Precalificacion.
 * Last modified: 2026-01-03
 */
trigger OpportunityTCPTrigger on OpportunityTCP__c (after update) {
    System.debug('>>> on OpportunityTCPTrigger (after update). Size: ' + Trigger.new.size());

    if (Trigger.isAfter && Trigger.isUpdate) {
        OpportunityTCPTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}