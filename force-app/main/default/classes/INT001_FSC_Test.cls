/**
 * @description       :
 * @author            : lplatino@keystoneadvisors.cl
 * @group             :
 * @last modified on  : 09-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
 **/
@SuppressWarnings('PMD')
@isTest
private with sharing class INT001_FSC_Test {
  @isTest
  static void INT001validateRNCTest() {
    List<Account> accList = TestDataFactory_FSC.createPersonAccounts(2);

    Test.setMock(HttpCalloutMock.class, new INT001TestMock('PF'));
    accList[0].ACC_NumIdentificacion__c = '00100058007';
    accList[0].ACC_TipoIdentificacion__c = 'Cédula';
    //accList[0].RecordtypeId = '0123J0000008URXQA2';
    update accList;

    Test.startTest();
    //  System.debug('RNC Number: '+ accList[0].ACC_RNC__c);
    INT001_FSC.validateAgainstElectoralRegister(accList[0].ACC_NumIdentificacion__c, accList[0].ACC_TipoIdentificacion__c);
    Test.stopTest();
  }

  @isTest
  static void INT001_VAER_ControllerTest_updateAccountSucces() {
    List<Account> accList = TestDataFactory_FSC.createPersonAccounts(2);
    accList[0].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    update accList;

    accList[0].ACC_NumIdentificacion__c = '00100058007';
    accList[0].ACC_TipoIdentificacion__c = 'Cédula';
    // accList[0].RecordtypeId = '0123J0000008URXQA2';
    accList[0].ACC_Condicion__c = 'CLIENTE';
    accList[0].ACC_Estado__c = 'CREADO';

    update accList;

    Test.setMock(HttpCalloutMock.class, new INT001TestMock('PF'));
    Test.startTest();
    //  System.debug('RNC Number: '+ accList[0].ACC_RNC__c);
    INT001_VAER_Controller.updateAccount(accList[0].id);
    Test.stopTest();
  }

  @isTest
  static void INT001_VAER_ControllerTestupdateAccountFail() {
    List<Account> accList = TestDataFactory_FSC.createPersonAccounts(2);

    // accList[0].RecordtypeId = '0123J0000008URXQA2';
    accList[0].ACC_NumIdentificacion__c = '00100058007';
    accList[0].ACC_TipoIdentificacion__c = 'Cédula';
    accList[0].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

    update accList;

    Test.setMock(HttpCalloutMock.class, new INT001TestMock('FAIL'));
    Test.startTest();
    // System.debug('RNC Number: '+ accList[0].ACC_RNC__c);
    INT001_VAER_Controller.updateAccount(accList[0].id);
    Test.stopTest();
  }

  @isTest
  static void INT001_VAER_ControllerTest() {
    List<Account> accList = TestDataFactory_FSC.createPersonAccounts(2);

    accList[0].ACC_NumIdentificacion__c = '00100058007';
    // accList[0].RecordtypeId = '0123J0000008URXQA2';
    accList[0].ACC_TipoIdentificacion__c = 'Cédula';

    update accList;

    Test.setMock(HttpCalloutMock.class, new INT001TestMock('PF'));
    Test.startTest();
    //  System.debug('RNC Number: '+ accList[0].ACC_RNC__c);
    INT001_VAER_Controller.updateAccount(accList[0].id);
    Test.stopTest();
  }

  @isTest
  static void INT001_VAER_Controller_updateAccountNoCedula() {
    List<Account> accList = TestDataFactory_FSC.createPersonAccounts(2);

    accList[0].ACC_NumIdentificacion__c = '00100058007';
    //accList[0].RecordtypeId = '0123J0000008URXQA2';
    accList[0].ACC_TipoIdentificacion__c = 'Pasaporte';

    update accList;

    Test.setMock(HttpCalloutMock.class, new INT004TestMock('PF'));
    Test.startTest();
    //  System.debug('RNC Number: '+ accList[0].ACC_RNC__c);
    INT001_VAER_Controller.updateAccount(accList[0].id);
    Test.stopTest();
  }
}