@isTest
public class INT055_Test {
    @isTest
    static void checkCommonLinkedAccountsTest()
    {
        List<Profile> profiles =TestDataFactory.createProfile();
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = profiles[0].Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest@testorg.com');
        insert u;
        
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        List<Direccion__c> dirsList=TestDataFactory.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList = TestDataFactory.createMatrizDeProducto(10);
        
        List<Asset> financeAsset = TestDataFactory.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);
        List<Vinculado__c> vinList=TestDataFactory.createVinculados(aList, financeAsset );
        
        Test.setMock(HttpCalloutMock.class, new INT055TestMock('PF'));
        Test.startTest();
        INT055.checkCommonLinkedAccounts(financeAsset[0], vinList );
        Test.stopTest();
    }
    
      @isTest
    static void checkCommonLinkedAccountsInvocableTest()
    {
        List<Profile> profiles =TestDataFactory.createProfile();
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = profiles[0].Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest@testorg.com');
        insert u;
        
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        List<Direccion__c> dirsList=TestDataFactory.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList = TestDataFactory.createMatrizDeProducto(10);
        
        List<Asset> financeAsset = TestDataFactory.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);
        List<Vinculado__c> vinList=TestDataFactory.createVinculados(aList, financeAsset );
        
        List<Id> assetIdsList = new List<Id>();              
        assetIdsList.add(financeAsset[0].id);
        
        Test.setMock(HttpCalloutMock.class, new INT055TestMock('PF'));
        Test.startTest();
        INT055.checkCommonLinkedAccounts(assetIdsList);
        Test.stopTest();
    }
}