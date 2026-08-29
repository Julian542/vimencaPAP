@isTest
public class INT008_Test {
    @isTest
    static void createOrModifyPFTest()
    {
        List<Account> aList = TestDataFactory.createPersonAccounts(10);
        List<Direccion__c> direcciones = TestDataFactory.createDirecciones(aList);
        List<Vias_de_Contacto__c> viasList = TestDataFactory.createViasDeContacto(aList);
        
        Test.setMock(HttpCalloutMock.class, new INT008TestMock('PF'));
        Test.startTest();
        INT008.createOrModifyPF(aList[0].Id, 'action');
        Test.stopTest();
    } 
}