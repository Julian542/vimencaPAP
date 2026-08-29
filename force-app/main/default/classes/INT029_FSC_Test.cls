/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 06-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
private with sharing class INT029_FSC_Test {

    @isTest
    static void updateSCTest(){
        List<Profile> profiles =TestDataFactory_FSC.createProfile();
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = profiles[0].Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest@testorg.com');
        insert u;

        List<Account> aList                     = TestDataFactory_FSC.createPersonAccounts(5);
        List<ContactPointAddress> dirsList             = TestDataFactory_FSC.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList  = TestDataFactory_FSC.createMatrizDeProducto(10);

        List<FinServ__FinancialAccount__c> financeAsset = TestDataFactory_FSC.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);

        Test.setMock(HttpCalloutMock.class, new INT029TestMock('PF'));
        Test.startTest();
            INT029_FSC.updateSC(aList[0].id);
        Test.stopTest();
    }

    @isTest
    static void updateAccountSCCorrectTest(){
        List<Profile> profiles =TestDataFactory_FSC.createProfile();
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = profiles[0].Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest@testorg.com');
        insert u;

        List<Account> aList                     = TestDataFactory_FSC.createPersonAccounts(5);
        List<ContactPointAddress> dirsList             = TestDataFactory_FSC.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList  = TestDataFactory_FSC.createMatrizDeProducto(10);

        List<FinServ__FinancialAccount__c> financeAsset = TestDataFactory_FSC.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);

        Test.setMock(HttpCalloutMock.class, new INT029TestMock('PM'));
        Test.startTest();
            INT029_ACSC_Controller.updateAccountSC(aList[0].id);
        Test.stopTest();
    }

    @isTest
    static void updateAccountSCExceptionTest(){
        List<Profile> profiles =TestDataFactory_FSC.createProfile();
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = profiles[0].Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest@testorg.com');
        insert u;

        List<Account> aList                     = TestDataFactory_FSC.createPersonAccounts(5);
        List<ContactPointAddress> dirsList             = TestDataFactory_FSC.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList  = TestDataFactory_FSC.createMatrizDeProducto(10);

        List<FinServ__FinancialAccount__c> financeAsset = TestDataFactory_FSC.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);

        Test.setMock(HttpCalloutMock.class, new INT029TestMock('PJ'));
        Test.startTest();
            INT029_ACSC_Controller.updateAccountSC(aList[0].id);
        Test.stopTest();
    }
}