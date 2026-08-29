@isTest
public class INT026_Test {
    @isTest
    static void consultVinTest()
    {
       List<Profile> profiles =TestDataFactory.createProfile(); 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = profiles[0].Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardpruebasusertest@testorg.com');
        insert u;
        
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        List<Direccion__c> dirsList=TestDataFactory.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList = TestDataFactory.createMatrizDeProducto(10);
        
        List<Asset> financeAsset = TestDataFactory.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);
        
        Test.setMock(HttpCalloutMock.class, new INT026TestMock('PF'));
        Test.startTest();
        INT026.consultVin(financeAsset[0].Id);
        Test.stopTest();
    }

    @isTest
    static void consultVin2Test()
    {
       List<Profile> profiles =TestDataFactory.createProfile(); 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = profiles[0].Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardpruebasusertest@testorg.com');
        insert u;
        
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        List<Direccion__c> dirsList=TestDataFactory.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList = TestDataFactory.createMatrizDeProducto(10);
        
        List<Asset> financeAsset = TestDataFactory.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);
        
        Test.setMock(HttpCalloutMock.class, new INT026TestMock('PF'));
        Test.startTest();
        INT026.consultVin2(financeAsset[0].Id);
        Test.stopTest();
    }
    
    @isTest
    static void getAccountInfoTest()
    {
        List<Profile> profiles =TestDataFactory.createProfile();
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = profiles[0].Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standapruebasrdusertest@testorg.com');
        insert u;
        
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        List<Direccion__c> dirsList=TestDataFactory.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList = TestDataFactory.createMatrizDeProducto(10);
        
        List<Asset> financeAsset = TestDataFactory.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);
        
        Test.setMock(HttpCalloutMock.class, new INT026TestMock('PF'));
        Test.startTest();
        INT026.getAccountInfo(financeAsset[0].id);
        Test.stopTest();
    }
}