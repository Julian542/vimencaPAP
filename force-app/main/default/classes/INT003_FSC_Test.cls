/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 06-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
private with sharing class INT003_FSC_Test {

    @isTest
    static void INT003validatePFTest(){
        List<Account> accList =TestDataFactory_FSC.createPersonAccounts(2);

        Test.setMock(HttpCalloutMock.class, new INT002TestMock('PF'));
        Test.startTest();
        INT003_FSC.validatePF(accList[0].Id);
        Test.stopTest();
    }

    @isTest
    static void INT003_ValidarContraLista_Controller_validatePF(){
        List<Account> accList =TestDataFactory_FSC.createPersonAccounts(2);

        Test.setMock(HttpCalloutMock.class, new INT004TestMock('PF'));
        accList[0].FinServ__IndividualId__c = '00100058007';
        accList[0].ACC_TipoIdentificacion__c = 'Cédula';
        /*accList[0].ACC_Condicion__c = 'PROSPECTO';
        accList[0].ACC_Estado__c = 'INICIADO';*/

        update accList;
        Test.startTest();
        //  System.debug('RNC Number: '+ accList[0].ACC_RNC__c);
            INT003_ValidarContraLista_Controller_FSC.validatePF(accList[0].id);
        Test.stopTest();
    }

    @isTest
    static void INT003_ValidarContraLista_Controller_validatePFFAIL(){
        Test.setMock(HttpCalloutMock.class, new INT002TestMock('PF'));
        Test.startTest();
        //  System.debug('RNC Number: '+ accList[0].ACC_RNC__c);
            INT003_ValidarContraLista_Controller_FSC.validatePF('a0B1k000001GjTnEAK');
        Test.stopTest();
    }
}