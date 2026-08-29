@isTest
public class INT056_Test {
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
        
        Test.setMock(HttpCalloutMock.class, new INT056TestMock('PF'));
        Test.startTest();
        INT056.consultVin(vinList[0].id);
        Test.stopTest();
    }
    
}