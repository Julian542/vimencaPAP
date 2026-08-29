@isTest
public class INT004_Test {
    @isTest
    static void updateUserPEPTest()
    {
        String document ='';
        String documentType='';
        String firstName='';
        String lastName='';
        
        Test.setMock(HttpCalloutMock.class, new INT004TestMock('PJ'));
        Test.startTest();
        INT004.updateUserPEP(document, documentType, firstName, lastName);
        Test.stopTest();
    }
    
    @isTest
    static void INT001_VAER_Controller_updateAccountPEP()
    {
        
        List<Account> accList =TestDataFactory.createPersonAccounts(2);
        
        Test.setMock(HttpCalloutMock.class, new INT004TestMock('PJ'));
        accList[0].ACC_NumIdentificacion__c = '00100058007';
        accList[0].ACC_TipoIdentificacion__c = 'Cédula';
        accList[0].ACC_Condicion__c = 'PROSPECTO';
        accList[0].ACC_Estado__c = 'INICIADO';
        
        update accList;
        Test.startTest();
        //  System.debug('RNC Number: '+ accList[0].ACC_RNC__c);
        INT001_VAER_Controller.updateAccountPEP(accList[0].id);
        Test.stopTest();
    }
    @isTest
    static void INT001_VAER_Controller_updateAccountPEPNO()
    {
        
        List<Account> accList =TestDataFactory.createPersonAccounts(2);
        
        Test.setMock(HttpCalloutMock.class, new INT004TestMock('PEP_NO'));
        accList[0].ACC_NumIdentificacion__c = '00100058007';
        accList[0].ACC_TipoIdentificacion__c = 'Cédula';
        accList[0].ACC_Condicion__c = 'PROSPECTO';
        accList[0].ACC_Estado__c = 'INICIADO';
        
        update accList;
        Test.startTest();
        //  System.debug('RNC Number: '+ accList[0].ACC_RNC__c);
        INT001_VAER_Controller.updateAccountPEP(accList[0].id);
        Test.stopTest();
    }
    @isTest
    static void INT001_VAER_Controller_updateAccountNoCedula()
    {
        
        List<Account> accList =TestDataFactory.createPersonAccounts(2);
        
        Test.setMock(HttpCalloutMock.class, new INT004TestMock('PF'));
        //   accList[0].ACC_NumIdentificacion__c = '00100058007';
        //  accList[0].ACC_TipoIdentificacion__c = 'Pasaporte';
        accList[0].ACC_Condicion__c = 'PROSPECTO';
        accList[0].ACC_Estado__c = 'INICIADO';
        
        update accList;
        Test.startTest();
        //  System.debug('RNC Number: '+ accList[0].ACC_RNC__c);
        INT001_VAER_Controller.updateAccountPEP(accList[0].id);
        Test.stopTest();
    }
    
    @isTest
    static void INT001_VAER_Controller_updateAccountPEPFlow()
    {
        
        List<Account> accList =TestDataFactory.createPersonAccounts(2);
        List<Id> ids = new List<Id>();
        for(Account acc : accList){
            ids.add(acc.Id);
        }
        
        Test.setMock(HttpCalloutMock.class, new INT004TestMock('PF'));
        //   accList[0].ACC_NumIdentificacion__c = '00100058007';
        //  accList[0].ACC_TipoIdentificacion__c = 'Pasaporte';
        accList[0].ACC_Condicion__c = 'PROSPECTO';
        accList[0].ACC_Estado__c = 'INICIADO';
        
        update accList;
        Test.startTest();
        //  System.debug('RNC Number: '+ accList[0].ACC_RNC__c);
        INT001_VAER_Controller.updateAccountPEPFlow(ids);
        Test.stopTest();
    }
}