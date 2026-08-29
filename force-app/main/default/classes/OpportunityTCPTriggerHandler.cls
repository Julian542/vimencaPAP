/**
 * Name: OpportunityTCPTriggerHandler
 * Description: Handler del trigger para detectar transición y encolar Queueable.
 * Last modified: 2026-01-03
 */
public with sharing class OpportunityTCPTriggerHandler {

    // Evita doble ejecución en la misma transacción
    private static Boolean alreadyEnqueued = false;

    public static void afterUpdate(List<OpportunityTCP__c> newList, Map<Id, OpportunityTCP__c> oldMap) {
        System.debug('>>> on OpportunityTCPTriggerHandler.afterUpdate. Records: ' + newList.size());

        if (alreadyEnqueued) {
            System.debug('>>> Skipping: alreadyEnqueued = true');
            return;
        }

        Set<Id> idsToPrequalify = new Set<Id>();

        for (OpportunityTCP__c n : newList) {
            OpportunityTCP__c o = oldMap.get(n.Id);

            Boolean nowMatches =
                n.OTCP_State__c == 'Validado' &&
                n.OTCP_SubState__c == 'Pendiente Precalificacion';

            Boolean previouslyMatches =
                o != null &&
                o.OTCP_State__c == 'Validado' &&
                o.OTCP_SubState__c == 'Pendiente Precalificacion';

            // Solo si "entra" a la condición (antes no estaba, ahora sí)
            if (nowMatches && !previouslyMatches) {
                idsToPrequalify.add(n.Id);
            }
        }

        System.debug('>>> idsToPrequalify size: ' + idsToPrequalify.size());

        if (!idsToPrequalify.isEmpty()) {
            alreadyEnqueued = true;
            System.debug('>>> Enqueuing OpportunityTCPPrequalificationQueue with ids: ' + idsToPrequalify);
            System.enqueueJob(new OpportunityTCPPrequalificationQueue(new List<Id>(idsToPrequalify)));
        }
    }
}