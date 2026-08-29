@isTest
public class INT029_Test {
    @isTest
    static void updateSCTest()
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
        
        
        Test.setMock(HttpCalloutMock.class, new INT029TestMock('PF'));
        Test.startTest();
        INT029.updateSC(aList[0].id);
        Test.stopTest();
    }
    
    
    @isTest
    static void updateAccountSCCorrectTest()
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
        
        
        Test.setMock(HttpCalloutMock.class, new INT029TestMock('PM'));
        Test.startTest();
        INT029_ACSC_Controller.updateAccountSC(aList[0].id);
        Test.stopTest();
    }
    
       @isTest
    static void updateAccountSCExceptionTest()
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
        
        
        Test.setMock(HttpCalloutMock.class, new INT029TestMock('PJ'));
        Test.startTest();
        INT029_ACSC_Controller.updateAccountSC(aList[0].id);
        Test.stopTest();
    }
}