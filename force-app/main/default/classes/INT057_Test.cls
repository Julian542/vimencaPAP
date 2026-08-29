@isTest
public class INT057_Test {
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
        
        Test.setMock(HttpCalloutMock.class, new INT057TestMock('PF'));
        Test.startTest();
        INT057.consultVin('Cédula' , vinList[0].VIN_Cuenta_financiera__c, aList[0].id , financeAsset[0].ASE_Linea_de_producto__c , financeAsset[0].id, aList[0].ACC_CIF__c);
        Test.stopTest();
    }
    
}