public with sharing class GenerateCSVBatchScheduler {
    @AuraEnabled
    public static void startBatch(String objectType, Integer months) {
        if (objectType == 'Request') {
            Database.executeBatch(new GenerateCSVBatch('INT_Request__c', months));
        } else if (objectType == 'Response') {
            Database.executeBatch(new GenerateCSVBatch('INT_Response__c', months));
        } else {
            throw new IllegalArgumentException('Tipo de objeto no válido.');
        }
    }
}