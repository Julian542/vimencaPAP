@isTest
public class beforInserFinanAccountTest {      
    
    @isTest
    static void checkFinancialProductDetailputInfoTest()
    {
       List<Profile> profiles =TestDataFactory.createProfile();
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = profiles[0].Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest@testorg.com');
        insert u;
        
        List<Account> aList=TestDataFactory.createPersonAccounts(1);
        aList[0].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(); 
        aList[0].ACC_Condicion__c='CLIENTE';
        aList[0].ACC_Estado__c='CREADO';
        update aList;
        List<Direccion__c> dirsList=TestDataFactory.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList = TestDataFactory.createMatrizDeProducto(10);
        
        List<Asset> financeAsset = TestDataFactory.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);
        
        financeAsset[0].Name ='123456';
        financeAsset[0].ASE_N_de_cuenta__c='123456';
        
         Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
        Test.startTest();
        update financeAsset;
        Test.stopTest();
        
   
    }
    
    
    
}