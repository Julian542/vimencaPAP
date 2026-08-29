@IsTest
private class RetryClienteCoreTest {
    @IsTest
    static void ignoresEmptyAndUnsupportedAccountRequests() {
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'Retry unsupported account',
            ACC_RNC__c = '131' + String.valueOf(Math.abs(Crypto.getRandomInteger())).left(6),
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert account;

        ReintentarCreacionClienteCoreInvocable.Request emptyRequest =
            new ReintentarCreacionClienteCoreInvocable.Request();
        ReintentarCreacionClienteCoreInvocable.Request unsupportedRequest =
            new ReintentarCreacionClienteCoreInvocable.Request();
        unsupportedRequest.accountId = account.Id;

        Test.startTest();
        ReintentarCreacionClienteCoreInvocable.reintentar(null);
        ReintentarCreacionClienteCoreInvocable.reintentar(
            new List<ReintentarCreacionClienteCoreInvocable.Request>{ emptyRequest, unsupportedRequest }
        );
        Test.stopTest();

        System.assertNotEquals(null, account.Id);
    }
}
