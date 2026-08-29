/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 06-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
private with sharing class INT056_FSC_Test {
    @isTest
    static void checkCommonLinkedAccountsTest() {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        List<Profile> profiles =TestDataFactory_FSC.createProfile();
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = profiles[0].Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest@testorg.com');
        insert u;

        List<Account> aList                     = TestDataFactory_FSC.createPersonAccounts(5);
        List<ContactPointAddress> dirsList      = TestDataFactory_FSC.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList  = TestDataFactory_FSC.createMatrizDeProducto(10);

        List<FinServ__FinancialAccount__c> financeAsset = TestDataFactory_FSC.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);
        List<FinServ__FinancialAccountRole__c> vinList  = TestDataFactory_FSC.createVinculados(aList, financeAsset );
        System.debug('***** ' + vinList );
        FinServ__FinancialAccountRole__c role = [
            SELECT Id,
                FinServ__RelatedAccount__r.ACC_TipoIdentificacion__c,
                FinServ__RelatedAccount__r.ACC_NumIdentificacion__c,
                FinServ__RelatedAccount__r.ACC_CIF__c,
                FAR_Relacion__c,
                FAR_Firmante__c
            FROM FinServ__FinancialAccountRole__c
            WHERE Id = :vinList[0].Id
        ];
        String frame = [SELECT Body FROM StaticResource WHERE Name = 'INT056_request_frame' LIMIT 1].Body.toString();
        INT056_FSC.Response response = new INT056_FSC.Response();
        response.valuesVincl.remove('[function_Vinculo]');
        response.valuesVincl.remove('[function_LineaProducto]');

        Test.startTest();
        String xml = INT056_FSC.fillXML(response, role, frame);
        Test.stopTest();

        System.assertNotEquals(null, xml);
    }

    @IsTest
    static void parsesSuccessfulAndErrorResponses() {
        INT056_FSC.Response success = INT056_FSC.parse(
            '<ErrorCode>000</ErrorCode><ErrorText></ErrorText>' +
            '<Result><ErrorText>Primero</ErrorText></Result>' +
            '<Result><ErrorText>Segundo</ErrorText></Result>'
        );
        INT056_FSC.Response error = INT056_FSC.parse(
            '<ErrorCode>999</ErrorCode><ErrorText>Error controlado</ErrorText>'
        );

        System.assertEquals('000', success.errorCode);
        System.assertEquals(2, success.responseList.size());
        System.assertEquals('999', error.errorCode);
        System.assertEquals(0, error.responseList.size());
    }

    @IsTest
    static void fillsSimpleAndNullRoleValues() {
        FinServ__FinancialAccountRole__c role = new FinServ__FinancialAccountRole__c(
            FAR_Firmante__c = 'SI',
            FAR_Relacion__c = 'Titular & Principal'
        );
        Map<String, String> values = new Map<String, String>{
            '[firmante]' => 'FAR_Firmante__c',
            '[relacion]' => 'FAR_Relacion__c',
            '[vacio]' => 'FAR_LegacyLinkedCode__c'
        };

        String output = INT056_FSC.fillCorrectType(
            values,
            role,
            '<F>[firmante]|[relacion]|[vacio]</F>'
        );

        System.assert(output.contains('SI'));
        System.assert(output.contains('Titular &amp; Principal'));
        System.assert(output.contains('|</F>'));
    }
}
