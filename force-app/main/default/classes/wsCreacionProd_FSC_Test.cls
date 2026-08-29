/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@SuppressWarnings('PMD')
@isTest
private with sharing class wsCreacionProd_FSC_Test {

    private static Id getFinancialAccountRecordTypeId() {
        Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName();
        if (recordTypes.containsKey('CheckingAccount')) {
            return recordTypes.get('CheckingAccount').getRecordTypeId();
        }
        if (recordTypes.containsKey('Cuenta_Corriente')) {
            return recordTypes.get('Cuenta_Corriente').getRecordTypeId();
        }
        if (recordTypes.containsKey('Cuentas_corrientes')) {
            return recordTypes.get('Cuentas_corrientes').getRecordTypeId();
        }
        return null;
    }

    @TestSetup
    static void makeData(){
        Profile p = [SELECT Id FROM Profile WHERE id='00e3i000001RR1rAAG']; //Id de usuario estandar
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest@testorg.com');
        insert u;

        Account acc = new Account();
        acc.RecordTypeId              = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        acc.firstName                 = 'FirstName ';
        acc.lastname                  = 'Test Person Account ';
        acc.ACC_CIF__c                = 'TESTCIF';
        acc.ACC_TipoIdentificacion__c = 'Cédula';
        acc.FinServ__IndividualId__c  = '12345678';
        acc.ACC_Nacionalidad__c       = 'REPUBLICA DOMINICANA';
        acc.PersonBirthdate           = Date.newInstance(2000, 1, 1);
        acc.ACC_Genero__c             = 'FEMENINO';
        acc.ACC_Estado_Civil__c       = 'SOLTERO/A';
        acc.ACC_RNC__c                = 'ABC13';
        acc.Phone                       = '158654';
        acc.ACC_Volumen_Ventas_Anual__c = 13123;
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        insert acc;

        Datos_Maestros__c dm = new Datos_Maestros__c(
        	Name = 'Datos TEST',
            DM_Codigo_Oficina__c = '1',
            DM_Tipo__c = 'Oficina',
            DM_Direccion__c = 't',
            DM_Distrito__c = '290403'
        );
        insert dm;

        ContactPointAddress dir = new ContactPointAddress();
        dir.Name                 = 'Test '+acc.Name ;
        dir.ParentId             = acc.id;
        dir.CPA_N_Apartamento__c = '8';
        dir.Street               = 'AVENIDA ' + acc.name;
        dir.Country              = 'AZ';
        dir.State                = 'SA';
        dir.CPA_Distrito__c      = '290403';
        dir.City                 = 'A';
        dir.PostalCode           = '146';
        dir.CPA_Sector__c        = dm.Id;
        dir.CPA_ExternalId__c    = 'H-154';
        dir.isPrimary            = true;
        insert dir;

        ContactPointPhone via = new ContactPointPhone();
        via.ParentId = acc.id;
        via.ExtensionNumber = '011';
        via.TelephoneNumber = '1156541';
        via.isPrimary = true;
        insert via;

        Matriz_de_producto__c matriz = new Matriz_de_producto__c();
        matriz.name = 'Matriz de producto TEST';
        matriz.PRO_Codigo_de_producto__c =  'TEST';
        insert matriz;

        FinServ__FinancialAccount__c ast        = new FinServ__FinancialAccount__c();
        ast.RecordTypeId                        = getFinancialAccountRecordTypeId();//Certificados_financieros en Asset
        ast.name                                = 'Cuenta Corriente ';
        ast.FinServ__PrimaryOwner__c            = acc.id;
        ast.FIN_Moneda__c                       = 'DOP';
        ast.FinServ__FinancialAccountNumber__c  = 'CC';
        ast.FinServ__Nickname__c                = 'ALIAS'+acc.name;
        ast.FinServ__FinancialAccountType__c    = 'TEST';
        ast.FIN_Producto__c                     = matriz.id;
        ast.FIN_N_de_libreta__c                 = 'asda2321';
        ast.FIN_Tipo_de_vinculacion__c          = 'Principal';
        ast.FIN_Linea_de_producto__c            = 'Préstamos';
        insert ast;
    }

    @isTest
    static void futurecreacionProdCACCCFTest() {

        FinServ__FinancialAccount__c ast = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new wsCreacionProdMock('SUCCESS'));
        Test.startTest();
        wsCreacionProd_FSC.Future_creacionProdCA_CC_CF(ast.Id);
        Test.stopTest();
    }

    @isTest
    static void futurecreacionProdCACCCFTestFail() {
        FinServ__FinancialAccount__c financeAsset = [SELECT Id, RecordTypeId FROM FinServ__FinancialAccount__c LIMIT 1];
        financeAsset.RecordTypeId = getFinancialAccountRecordTypeId();
        update financeAsset;

        Test.setMock(HttpCalloutMock.class, new wsCreacionProdMock('FAIL'));
        Test.startTest();
        wsCreacionProd_FSC.Invocable_creacionProdCA_CC_CF(new List<id>{financeAsset.id});
        Test.stopTest();
    }
}
