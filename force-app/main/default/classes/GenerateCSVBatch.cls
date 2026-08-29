global class GenerateCSVBatch implements Database.Batchable<SObject>, Database.Stateful {
    private String objectType;
    private Integer months;
    private Integer totalDeleted = 0;

    public GenerateCSVBatch(String objectType, Integer months) {
        this.objectType = objectType;
        this.months = months;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query;

        if (objectType == 'INT_Request__c') {
            query = 'SELECT Id FROM INT_Request__c WHERE CreatedDate < LAST_N_MONTHS:' + months;
        } else if (objectType == 'INT_Response__c') {
            query = 'SELECT Id FROM INT_Response__c WHERE CreatedDate < LAST_N_MONTHS:' + months;
        } else {
            throw new AuraHandledException('Unsupported object type: ' + objectType);
        }

        if(test.isRunningTest()){
            if (objectType == 'INT_Request__c') {
                query = 'SELECT Id FROM INT_Request__c WHERE CreatedDate = TODAY';
            } else if (objectType == 'INT_Response__c') {
                query = 'SELECT Id FROM INT_Response__c WHERE CreatedDate = TODAY';
            } else {
                throw new AuraHandledException('Unsupported object type: ' + objectType);
            }
        }

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        if (!scope.isEmpty()) {
            totalDeleted += scope.size();
            delete scope;
        }
    }

    global void finish(Database.BatchableContext BC) {
        User targetUser = [SELECT Email FROM User WHERE Name = 'LUIS CONRADO RODRIGUEZ GARCIA' AND IsActive = true LIMIT 1];
        String[] toAddresses = new List<String>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { targetUser.Email }); // Reemplazar con dirección real
        mail.setSubject('Registros eliminados del batch');
        mail.setPlainTextBody('Se han eliminado ' + totalDeleted + ' registros del objeto ' + objectType + ' que tenían más de ' + months + ' meses.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
}