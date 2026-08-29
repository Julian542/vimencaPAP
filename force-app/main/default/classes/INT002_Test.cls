@isTest
public class INT002_Test 
{    
    @isTest
    static void INT002validateRNCTest()
    {
        Test.setMock(HttpCalloutMock.class, new INT002TestMock('PJ'));
        Test.startTest();
        INT002.validateRNC('131000012');
        Test.stopTest();
    }
    
    @isTest
    static void INT002VARNTest()
    {
        /* List<Account> accList =TestDataFactory.createPersonAccounts(2);        
Account acc = [SELECT id FROM Account WHERE ACC_Estado__c ='INICIADO' LIMIT 1];

Test.setMock(HttpCalloutMock.class, new INT002TestMock('PJ'));
Test.startTest();
System.debug('RNC Number: '+ accList[0].ACC_RNC__c);*/
       List<Account> accList =TestDataFactory.createJuridicAccounts(2);
        //  List<Account> accList =TestDataFactory.createPersonAccounts(2);
        Test.setMock(HttpCalloutMock.class, new INT002TestMock('PJ'));        
      /*  // accList[0].ACC_TipoIdentificacion__c = 'Cédula';
        //	accList[0].RecordtypeId = '0123i0000001VXhAAM';*/
        accList[0].ACC_RNC__c = '00100058007';        
        accList[0].ACC_Condicion__c = 'PROSPECTO';
        accList[0].ACC_Estado__c = 'INICIADO';
        // accList[0].ACC_NumIdentificacion__c = '00100058007';
      //  accList[0].RecordtypeId = '0123i0000001VXhAAM';
       // accList[0].ACC_TipoIdentificacion__c = 'Cédula';
       // accList[0].ACC_Condicion__c = 'PROSPECTO';
      //  accList[0].ACC_Estado__c = 'INICIADO';
        
        update accList;
        Test.startTest();
        INT002_VARNC_Controller.updateAccountRNC(accList[0].Id);
        Test.stopTest();
    }
}
