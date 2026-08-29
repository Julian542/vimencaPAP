public with sharing class ReintentarCreacionClienteCoreInvocable {

    public class Request {

        @InvocableVariable(
            required=true
            label='Id del Cliente'
        )
        public Id accountId;
    }

    @InvocableMethod(
        label='Reintentar creación de cliente en Core'
        description='Relanza la creación del cliente en el Core mediante INT007 o INT008 según el tipo de cliente'
    )
    public static void reintentar(List<Request> requests) {

        if (requests == null || requests.isEmpty()) {
            return;
        }

        Set<Id> accountIds = new Set<Id>();

        for (Request req : requests) {
            if (req != null && req.accountId != null) {
                accountIds.add(req.accountId);
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        Map<String, Schema.RecordTypeInfo> recordTypes =
            Schema.SObjectType.Account
                .getRecordTypeInfosByDeveloperName();

        Id personAccountRtId =
            recordTypes.get('PersonAccount').getRecordTypeId();

        Id industriesBusinessRtId =
            recordTypes.get('IndustriesBusiness').getRecordTypeId();

        List<Account> accounts = [
            SELECT Id, RecordTypeId
            FROM Account
            WHERE Id IN :accountIds
        ];

        for (Account account : accounts) {

            if (account.RecordTypeId == personAccountRtId) {

                System.debug(
                    'Reintentando creación de cliente PERSONA. AccountId='
                    + account.Id
                );

                INT007_FSC.creteClient(account.Id);

            } else if (
                account.RecordTypeId == industriesBusinessRtId
            ) {

                System.debug(
                    'Reintentando creación de cliente JURÍDICO. AccountId='
                    + account.Id
                );

                INT008_FSC.creteClientJ(account.Id);

            } else {

                System.debug(
                    LoggingLevel.WARN,
                    'El cliente no tiene un Record Type soportado. AccountId='
                    + account.Id
                );
            }
        }
    }
}