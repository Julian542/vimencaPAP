@IsTest
private class CaseFinancialTransactionControllerTest {
    private static final String ACCOUNT_NUMBER = '4455667788';
    private static final String TRANSACTION_ID = 'DOC-COVERAGE-01';

    @TestSetup
    static void createData() {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount').getRecordTypeId(),
            FirstName = 'Financial',
            LastName = 'Transaction',
            ACC_TipoIdentificacion__c = 'Cédula',
            ACC_NumIdentificacion__c = '00108803999'
        );
        insert account;

        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
        FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
            RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c
                .getRecordTypeInfosByDeveloperName().get('CheckingAccount').getRecordTypeId(),
            Name = 'Cuenta transacciones coverage',
            FinServ__FinancialAccountNumber__c = ACCOUNT_NUMBER,
            FinServ__SourceSystemId__c = 'SRC' + ACCOUNT_NUMBER,
            FinServ__PrimaryOwner__c = account.Id
        );
        insert financialAccount;

        insert new Case(
            AccountId = account.Id,
            FinServ__FinancialAccount__c = financialAccount.Id,
            Status = 'New',
            Origin = 'Phone',
            Subject = 'Caso transacciones coverage'
        );

        insert new FinServ__FinancialAccountTransaction__c(
            FinServ__FinancialAccount__c = financialAccount.Id,
            FinServ__TransactionDate__c = Datetime.newInstance(Date.today(), Time.newInstance(10, 30, 0, 0)),
            FinServ__Amount__c = 125.50,
            FinServ__Description__c = 'Compra de prueba',
            FinServ__TransactionType__c = 'Debit',
            FinServ__TransactionStatus__c = 'Posted',
            FinServ__TransactionId__c = TRANSACTION_ID,
            FinServ__SourceTransactionType__c = 'PURCHASE',
            FinServ__SourceSystemId__c = 'TX-COVERAGE-01'
        );
    }

    @IsTest
    static void returnsTransactionsWithAndWithoutFilters() {
        Case caseRecord = [
            SELECT Id
            FROM Case
            WHERE Subject = 'Caso transacciones coverage'
            LIMIT 1
        ];
        CaseFinancialTransactionController.TransactionFilter filters =
            new CaseFinancialTransactionController.TransactionFilter();
        filters.fechaDesde = Date.today().addDays(-1);
        filters.fechaHasta = Date.today();
        filters.estado = ' Posted ';
        filters.creditoDebito = ' Debit ';
        filters.montoMinimo = 100;
        filters.montoMaximo = 150;
        filters.numeroDocumento = 'COVERAGE';

        Test.startTest();
        List<CaseFinancialTransactionController.TransactionRow> unfiltered =
            CaseFinancialTransactionController.getTransactionsByCase(caseRecord.Id, null);
        List<CaseFinancialTransactionController.TransactionRow> filtered =
            CaseFinancialTransactionController.getTransactionsByCase(caseRecord.Id, filters);
        Test.stopTest();

        System.assertEquals(1, unfiltered.size());
        System.assertEquals(1, filtered.size());
        System.assertEquals(TRANSACTION_ID, filtered[0].numeroDocumento);
        System.assertEquals(125.50, filtered[0].monto);
        System.assertEquals('Debit', filtered[0].creditoDebito);
    }

    @IsTest
    static void linksTransactionAndValidatesRequiredInputs() {
        Case caseRecord = [
            SELECT Id
            FROM Case
            WHERE Subject = 'Caso transacciones coverage'
            LIMIT 1
        ];
        FinServ__FinancialAccountTransaction__c transactionRecord = [
            SELECT Id
            FROM FinServ__FinancialAccountTransaction__c
            WHERE FinServ__TransactionId__c = :TRANSACTION_ID
            LIMIT 1
        ];
        update new FinServ__FinancialAccountTransaction__c(
            Id = transactionRecord.Id,
            FinServ__TransactionType__c = null
        );

        Test.startTest();
        assertAuraExceptionForNullCase();
        assertAuraExceptionForEmptySelection(caseRecord.Id);
        CaseFinancialTransactionController.linkTransactionsToCase(
            caseRecord.Id,
            new List<Id>{ transactionRecord.Id }
        );
        Test.stopTest();

        TRA_Transaccion__c linked = [
            SELECT TRA_Reclamacion__c, TRA_Fecha__c, TRA_Monto__c, TRA_Credito_Debito__c
            FROM TRA_Transaccion__c
            WHERE TRA_Reclamacion__c = :caseRecord.Id
            LIMIT 1
        ];
        System.assertEquals(caseRecord.Id, linked.TRA_Reclamacion__c);
        System.assertEquals(Date.today(), linked.TRA_Fecha__c);
        System.assertEquals(125.50, linked.TRA_Monto__c);
        System.assertEquals(null, linked.TRA_Credito_Debito__c);
    }

    private static void assertAuraExceptionForNullCase() {
        try {
            CaseFinancialTransactionController.getTransactionsByCase(null, null);
            System.assert(false, 'Se esperaba validar el Id del caso');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected.getMessage());
        }
    }

    private static void assertAuraExceptionForEmptySelection(Id caseId) {
        try {
            CaseFinancialTransactionController.linkTransactionsToCase(caseId, new List<Id>());
            System.assert(false, 'Se esperaba validar la selección');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected.getMessage());
        }
    }
}
