/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 06-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
private with sharing class INT055_FSC_Test {
    @isTest
    static void checkCommonLinkedAccountsTest() {
        List<Profile> profiles =TestDataFactory_FSC.createProfile();
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = profiles[0].Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest@testorg.com');
        insert u;

        List<Account> aList=TestDataFactory_FSC.createPersonAccounts(5);
        List<ContactPointAddress> dirsList=TestDataFactory_FSC.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList = TestDataFactory_FSC.createMatrizDeProducto(10);

        List<FinServ__FinancialAccount__c> financeAsset = TestDataFactory_FSC.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);
        List<FinServ__FinancialAccountRole__c> vinList=TestDataFactory_FSC.createVinculados(aList, financeAsset );

        Test.setMock(HttpCalloutMock.class, new INT055TestMock('PF'));
        Test.startTest();
            INT055_FSC.checkCommonLinkedAccounts(financeAsset[0], vinList );
        Test.stopTest();
    }

      @isTest
    static void checkCommonLinkedAccountsInvocableTest(){
        List<Profile> profiles =TestDataFactory_FSC.createProfile();
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = profiles[0].Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest@testorg.com');
        insert u;

        List<Account> aList=TestDataFactory_FSC.createPersonAccounts(5);
        List<ContactPointAddress> dirsList=TestDataFactory_FSC.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList = TestDataFactory_FSC.createMatrizDeProducto(10);

        List<FinServ__FinancialAccount__c> financeAsset = TestDataFactory_FSC.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);
        List<FinServ__FinancialAccountRole__c> vinList=TestDataFactory_FSC.createVinculados(aList, financeAsset );

        List<Id> assetIdsList = new List<Id>();
        assetIdsList.add(financeAsset[0].id);

        Test.setMock(HttpCalloutMock.class, new INT055TestMock('PF'));
        Test.startTest();
            INT055_FSC.checkCommonLinkedAccounts(assetIdsList);
        Test.stopTest();
    }
}