/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 06-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
private with sharing class INT014_FSC_Test {

    @isTest
    static void checkFinancialProductDetailputInfoTest(){
        List<Profile> profiles =TestDataFactory_FSC.createProfile();
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = profiles[0].Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest2@testorg.com');
        insert u;

        List<Account> aList=TestDataFactory_FSC.createPersonAccounts(5);
        List<ContactPointAddress> dirsList=TestDataFactory_FSC.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList = TestDataFactory_FSC.createMatrizDeProducto(10);

        List<FinServ__FinancialAccount__c> financeAsset = TestDataFactory_FSC.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);

        Map<String, String> mapForm = new Map<String, String>();
        mapForm.put('fromDate'      , 'value');
        mapForm.put('untilDate'     , 'value');
        mapForm.put('state'         , 'value');
        mapForm.put('minimunAmount' , 'value');
        mapForm.put('maxAmount'     , 'value');
        mapForm.put('credirDebit'   , 'value');
        mapForm.put('documentNumber', 'value');

        Test.setMock(HttpCalloutMock.class, new INT014TestMock('PF'));
        Test.startTest();
            INT014_FSC.checkProductTransactions(financeAsset[0].id, mapForm);
        Test.stopTest();
    }

}