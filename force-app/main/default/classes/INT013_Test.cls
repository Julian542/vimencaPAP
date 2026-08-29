@isTest
public class INT013_Test {      
    
    @TestSetup
    static void setupTestData(){
        Profile p = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        User testUser = new User(
            Alias = 'standt', 
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8', 
            LastName = 'Testing', 
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'standardusertesttwo@testorg.com');        
        insert testUser;
              
    }

    @isTest
    static void checkFinancialProductDetailputInfoTest(){
       User testUser = [SELECT Id FROM User WHERE Alias = 'standt' LIMIT 1];

        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        List<Direccion__c> dirsList=TestDataFactory.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList = TestDataFactory.createMatrizDeProducto(10);        
        List<Asset> financeAsset = TestDataFactory.createAssets_CuentaCorriente(aList, dirsList, matrizList, testUser , 1);
               
        Test.setMock(HttpCalloutMock.class, new INT013TestMock('PF'));
        Test.startTest();
        INT013.checkFinancialProductDetail('123', 'Préstamos', financeAsset[0].ASE_Moneda__c, financeAsset[0].Id);
        Test.stopTest();
    }
    
    @isTest
    static void checkFinancialProdPrestamos(){
        String accountNumber='123';
        String productLine='Préstamos';
        String requestedCurrency='EUR';
        id idFinanAccount;
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        idFinanAccount=aList[0].id;
        Test.setMock(HttpCalloutMock.class, new INT013TestMock('PF'));
        Test.startTest();
        INT013.checkFinancialProductDetail(accountNumber, 'Préstamos', requestedCurrency, idFinanAccount);
        Test.stopTest();
    }
    
    @isTest
    static void checkFinancialProdCertificadoFinanc(){
        String accountNumber='123';
        String productLine='Préstamos';
        String requestedCurrency='EUR';
        id idFinanAccount;
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        idFinanAccount=aList[0].id;
        Test.setMock(HttpCalloutMock.class, new INT013TestMock('PF'));
        
        Test.startTest();
        INT013.checkFinancialProductDetail(accountNumber, 'certificados financieros', requestedCurrency, idFinanAccount);
        Test.stopTest();
    }
    
    @isTest
    static void checkFinancialProdLineaCredt(){
        String accountNumber='123';
        String productLine='Préstamos';
        String requestedCurrency='EUR';
        id idFinanAccount;
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        idFinanAccount=aList[0].id;
        Test.setMock(HttpCalloutMock.class, new INT013TestMock('PF'));
        
        Test.startTest();
        INT013.checkFinancialProductDetail(accountNumber, 'líneas de crédito', requestedCurrency, idFinanAccount);
        Test.stopTest();
    }
    
    @isTest
    static void checkFinancialProdCuentAhorr(){
        String accountNumber='123';
        String productLine='Préstamos';
        String requestedCurrency='EUR';
        id idFinanAccount;
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        idFinanAccount=aList[0].id;
        Test.setMock(HttpCalloutMock.class, new INT013TestMock('PF'));
        
        Test.startTest();
        INT013.checkFinancialProductDetail(accountNumber, 'cuentas de ahorro', requestedCurrency, idFinanAccount);
        Test.stopTest();
    }
    
    @isTest
    static void checkFinancialProdTarjtCred(){
        String accountNumber='123';
        String productLine='Préstamos';
        String requestedCurrency='EUR';
        id idFinanAccount;
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        idFinanAccount=aList[0].id;
        Test.setMock(HttpCalloutMock.class, new INT013TestMock('PF'));
        
        Test.startTest();
        INT013.checkFinancialProductDetail(accountNumber, 'tarjetas de crédito', requestedCurrency, idFinanAccount);
        Test.stopTest();
    }
    
    @isTest
    static void checkFinancialProdCuentCorr(){
        String accountNumber='123';
        String productLine='Préstamos';
        String requestedCurrency='EUR';
        id idFinanAccount;
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        idFinanAccount=aList[0].id;
        Test.setMock(HttpCalloutMock.class, new INT013TestMock('PF'));
        
        Test.startTest();
        INT013.checkFinancialProductDetail(accountNumber, 'cuentas corrientes', requestedCurrency, idFinanAccount);
        Test.stopTest();
    }

    @isTest
    static void checkFinancialProdTarjtPre(){
        String accountNumber='123';
        String productLine='Préstamos';
        String requestedCurrency='EUR';
        id idFinanAccount;
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        idFinanAccount=aList[0].id;
        Test.setMock(HttpCalloutMock.class, new INT013TestMock('PF'));
        Test.startTest();
        INT013.checkFinancialProductDetail(accountNumber, 'tarjetas prepago', requestedCurrency, idFinanAccount);
        Test.stopTest();
    }


    @isTest
    static void controllerLightingINT013(){
        User testUser = [SELECT Id FROM User WHERE Alias = 'standt' LIMIT 1];
        
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        List<Direccion__c> dirsList=TestDataFactory.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList = TestDataFactory.createMatrizDeProducto(10);
        
        List<Asset> financeAsset = TestDataFactory.createAssets_CuentaCorriente(aList, dirsList, matrizList, testUser, 1);
        
        //   id idFinanAccount=financeAsset[0].accountID;
      //  financeAsset[0].ASE_Linea_de_producto__c='Cuentas corrientes';
        //update financeAsset;
        Test.setMock(HttpCalloutMock.class, new INT013TestMock('FAIL'));
        
        Test.startTest();
        INT013_LC_Controller.updateFinanAccount(financeAsset[0].Id);            
        Test.stopTest();
    }
}
