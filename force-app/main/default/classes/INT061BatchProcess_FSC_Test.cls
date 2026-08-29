/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 10-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
private with sharing class INT061BatchProcess_FSC_Test {

    public static final String CRON_EXP = '0 0 0 15 3 ? 2029';

    @isTest
    static void testBatch(){
        Test.setMock(HttpCalloutMock.class, new INT061TestMock('PJ'));
        Test.startTest();
            INT061BatchProcess_FSC testsche = new INT061BatchProcess_FSC();
            System.schedule('Test status Check'+Date.today(), CRON_EXP, testsche);
        Test.stopTest();
    }
}