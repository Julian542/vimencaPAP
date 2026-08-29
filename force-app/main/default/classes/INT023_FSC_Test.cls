/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 06-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
private with sharing class INT023_FSC_Test {
    @isTest
    static void consultVinBloqueoTest(){
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

        Test.setMock(HttpCalloutMock.class, new INT023TestMock('PF'));
        Test.startTest();
            INT023_Bloqueo_FSC.consultVin(financeAsset[0].id);
        Test.stopTest();
    }

    @isTest
    static void consultVinRestriccionesTest(){
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

        Test.setMock(HttpCalloutMock.class, new INT023TestMock('PJ'));
        Test.startTest();
            INT023_Restricciones_FSC.consultVin(financeAsset[0].id);
        Test.stopTest();
    }
}