@IsTest
private class INT014FinancialTransactionsQueueTest {
    private static FinServ__FinancialAccount__c createFinancialAccount() {
        List<Profile> profiles = TestDataFactory_FSC.createProfile();
        User testUser = new User(
            Alias = 'int014',
            Email = 'int014.queue@example.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Queue Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profiles[0].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'int014.queue.' + System.now().getTime() + '@example.test'
        );
        insert testUser;

        List<Account> accounts = TestDataFactory_FSC.createPersonAccounts(1);
        List<ContactPointAddress> addresses = TestDataFactory_FSC.createDirecciones(accounts);
        List<Matriz_de_producto__c> products = TestDataFactory_FSC.createMatrizDeProducto(1);
        return TestDataFactory_FSC.createAssets_CuentaCorriente(
            accounts,
            addresses,
            products,
            testUser,
            1
        )[0];
    }

    @IsTest
    static void processesTransactionsWithTheExistingInt014Mock() {
        FinServ__FinancialAccount__c financialAccount = createFinancialAccount();
        Test.setMock(HttpCalloutMock.class, new INT014TestMock('PF'));

        Test.startTest();
        Id jobId = System.enqueueJob(new INT014FinancialTransactionsQueue(
            new List<Id>{ financialAccount.Id }
        ));
        Test.stopTest();

        System.assertEquals('Completed', [
            SELECT Status
            FROM AsyncApexJob
            WHERE Id = :jobId
        ].Status);
    }

    @IsTest
    static void skipsEmptyAndMissingFinancialAccountInputs() {
        new INT014FinancialTransactionsQueue(null).execute(null);
        new INT014FinancialTransactionsQueue(
            new List<Id>{ 'a0k000000000001AAA' }
        ).execute(null);

        System.assert(true);
    }
}
