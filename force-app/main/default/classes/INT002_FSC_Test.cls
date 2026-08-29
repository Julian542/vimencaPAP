/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 28-12-2025
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
private with sharing class INT002_FSC_Test {
    @isTest
    static void INT002validateRNCTest(){
        List<Account> accList = TestDataFactory_FSC.createPersonAccounts(2);

        Test.setMock(HttpCalloutMock.class, new INT002TestMock('PJ'));
        Test.startTest();
        System.debug('RNC Number: '+ accList[0].ACC_RNC__c);
        INT002_FSC.validateRNC(accList[0].ACC_RNC__c);
        Test.stopTest();
    }

    @isTest
    static void INT002VARNTest(){
        /* List<Account> accList =TestDataFactory_FSC.createPersonAccounts(2);
		Account acc = [SELECT id FROM Account WHERE ACC_Estado__c ='INICIADO' LIMIT 1];

		Test.setMock(HttpCalloutMock.class, new INT002TestMock('PJ'));
		Test.startTest();
		System.debug('RNC Number: '+ accList[0].ACC_RNC__c);*/
       	List<Account> accList = TestDataFactory_FSC.createJuridicAccounts(2);
        //  List<Account> accList =TestDataFactory_FSC.createPersonAccounts(2);
        Test.setMock(HttpCalloutMock.class, new INT002TestMock('PJ'));
      	/*  // accList[0].ACC_TipoIdentificacion__c = 'Cédula';
        //	accList[0].RecordtypeId = '0123i0000001VXhAAM';*/
        accList[0].ACC_RNC__c 		= '00100058007';
        accList[0].ACC_Condicion__c = 'PROSPECTO';
        accList[0].ACC_Estado__c 	= 'INICIADO';
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