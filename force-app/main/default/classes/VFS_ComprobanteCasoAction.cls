public with sharing class VFS_ComprobanteCasoAction {

    @AuraEnabled
    public static void enviar(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('Debe enviarse el Id del caso.');
        }

        Case caso = [
            SELECT Id, AccountId, CAS_Numero_transacciones__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        if (caso.AccountId == null) {
            throw new AuraHandledException('El caso no tiene cliente asociado.');
        }

        if (caso.CAS_Numero_transacciones__c == null || caso.CAS_Numero_transacciones__c <= 0) {
            throw new AuraHandledException('El caso no tiene transacciones relacionadas.');
        }

        System.enqueueJob(
            new VFS_EnviarComprobanteCasoQueueable(
                new Set<Id>{ caseId }
            )
        );
    }
}