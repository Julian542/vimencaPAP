@isTest
public class INT014_Test {          
    @isTest
    static void checkFinancialProductDetailputInfoTest()
    {
        List<Profile> profiles =TestDataFactory.createProfile();
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = profiles[0].Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest2@testorg.com');
        insert u;
        
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        List<Direccion__c> dirsList=TestDataFactory.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList = TestDataFactory.createMatrizDeProducto(10);
        
        List<Asset> financeAsset = TestDataFactory.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);
        
        
        Map<String, String> mapForm = new Map<String, String>();
        mapForm.put('fromDate', 'value');
        mapForm.put('untilDate', 'value');
        mapForm.put('state', 'value');
        mapForm.put('minimunAmount', 'value');
        mapForm.put('maxAmount', 'value');
        mapForm.put('credirDebit', 'value');
        mapForm.put('documentNumber', 'value');
        
        
        
        Test.setMock(HttpCalloutMock.class, new INT014TestMock('PF'));
        Test.startTest();
        INT014.checkProductTransactions(financeAsset[0].id, mapForm);
        Test.stopTest(); 
    }
    
    
}