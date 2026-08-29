/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 06-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
private with sharing class INT057_FSC_Test {
    @isTest
    static void checkCommonLinkedAccountsTest() {
        List<Profile> profiles =TestDataFactory_FSC.createProfile();
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = profiles[0].Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest@testorg.com');
        insert u;

        List<Account> aList=TestDataFactory_FSC.createPersonAccounts(5);
        List<ContactPointAddress> dirsList=TestDataFactory_FSC.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList = TestDataFactory_FSC.createMatrizDeProducto(10);

        List<FinServ__FinancialAccount__c> financeAsset = TestDataFactory_FSC.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);
        List<FinServ__FinancialAccountRole__c> vinList=TestDataFactory_FSC.createVinculados(aList, financeAsset );

        Test.setMock(HttpCalloutMock.class, new INT057TestMock('PF'));
        Test.startTest();
            INT057.consultVin('Cédula' , vinList[0].FinServ__FinancialAccount__c, aList[0].id , financeAsset[0].FIN_Linea_de_producto__c , financeAsset[0].id, aList[0].ACC_CIF__c);
        Test.stopTest();
    }

    @isTest
    static void parsesResponsesAndBuildsXmlFrame() {
        INT057_FSC.Response success = INT057_FSC.parse(
            '<ErrorCode>000</ErrorCode><ErrorText></ErrorText>' +
            '<Result><ErrorText>Procesado</ErrorText></Result>'
        );
        INT057_FSC.Response error = INT057_FSC.parse(
            '<ErrorCode>999</ErrorCode><ErrorText>Rechazado</ErrorText>'
        );

        System.assertEquals('000', success.errorCode);
        System.assertEquals(1, success.responseList.size());
        System.assertEquals('999', error.errorCode);
        System.assertEquals(0, error.responseList.size());

        Vinculado__c linked = new Vinculado__c();
        String frame = '<Envelope><Function><Value>sin cambios</Value></Function></Envelope>';
        String output = INT057_FSC.fillXML(success, linked, frame);
        System.assertEquals(frame, output);
    }
}
