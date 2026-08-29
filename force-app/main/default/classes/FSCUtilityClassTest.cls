/*************************
* @Class Name:- FSCUtilityClassTest
* @Description:- Test class for FSCUtilityClass
**************************/
@IsTest
public with sharing class FSCUtilityClassTest {

    private static void setupRetailMock() {
        Map<String, String> headers = new Map<String, String>{ 'Content-Type' => 'application/json' };
        Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(200, 'Success', '{}', headers));
    }
    
    //This test method is to get base path of community site 
    @IsTest 
    static void testgetBasePath() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        args.put('input', input);
        args.put('output', output);
        Callable callableMethod = (Callable)Type.forName('FSCUtilityClass').newInstance();
        Object countryPicklistValueObj = callableMethod.call('getBasePath', args);
        System.assertEquals('{result={BasePath=}}', String.valueOf(countryPicklistValueObj));
        System.assertEquals(null, callableMethod.call('unsupportedAction', args));
    }
    
    //This test method is to get the account source system Id 
    @IsTest 
    static void testGetAccountSourceSystemId() {
        setupRetailMock();
        Integer intNumber = 1;
        List<Account> listAccount = FSCRetailTestDataFactory.createAccounts(intNumber);
        List<FinServ__Card__c> listCardsCreated = FSCRetailTestDataFactory.createCards(listAccount);
        //insert list of Service Catalog Requests from test data factory
        List<SvcCatalogRequest> listServiceCatalogReq = FSCRetailTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
        insert listServiceCatalogReq;
        SvcCatalogRequest svcCatalogRequestRec = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        Test.startTest();
        String recordId;
        try {
            recordId = FSCUtilityClass.getAccountSourceSystemId(svcCatalogRequestRec.Id);
        } catch (QueryException ex) {
            System.assert(ex.getMessage().contains('secure query included inaccessible field'), ex.getMessage());
            Test.stopTest();
            return;
        }
        Test.stopTest();
        System.assertEquals(recordId, '2340'); 
    }
    
    //This test method is to get the card source system id
    @IsTest 
    static void testGetCardsSourceSystemId() {
        setupRetailMock();
        //insert list of accounts from test data factory
        Integer intNumber = 1;
        List<Account> listAccount = FSCRetailTestDataFactory.createAccounts(intNumber);
        List<FinServ__Card__c> listCardsCreated = FSCRetailTestDataFactory.createCards(listAccount);
        Test.startTest();
        Map<String, Map<String, String>> finalCardDetails = FSCUtilityClass.getCardsSourceSystemId(listAccount[0].FinServ__SourceSystemId__c);
        Test.stopTest();
        Map<String, String> cardAttr = new Map<String, String>();
        cardAttr = finalCardDetails.get('SourceSystemId');
        String sourceSysId = cardAttr.get('XXXX-6382');
        System.assertEquals(sourceSysId, '12345');
    }
    
    //This test method is to get the card source system id
    @IsTest 
    static void testGetFinancialAccSourceSystemId() {
        setupRetailMock();
        //insert list of accounts from test data factory
        Integer intNumber = 1;
        List<Account> listAccount = FSCRetailTestDataFactory.createAccounts(intNumber);
        List<FinServ__FinancialAccount__c> financialAcc = FSCRetailTestDataFactory.createFinancialAccounts(1, listAccount);
        Test.startTest();
        String finAccSourceSysId = FSCUtilityClass.getFinancialAccSourceSystemId(listAccount[0].FinServ__SourceSystemId__c, 'XXXX-6210');
        Test.stopTest();
        System.assertEquals(finAccSourceSysId, '234454330');
    }
    
    //This test method is to get the financial account id
    @IsTest 
    static void testGetFinancialAccountId() {
        setupRetailMock();
        //insert list of accounts from test data factory
        Integer intNumber = 1;
        List<Account> listAccount = FSCRetailTestDataFactory.createAccounts(intNumber);
        List<FinServ__FinancialAccount__c> financialAcc = FSCRetailTestDataFactory.createFinancialAccounts(1, listAccount);
        Test.startTest();
        String financialAccountId = FSCUtilityClass.getFinancialAccountId(listAccount[0].FinServ__SourceSystemId__c, 'XXXX-6210');
        Test.stopTest();
        System.assert(financialAccountId != null);
    }
}
