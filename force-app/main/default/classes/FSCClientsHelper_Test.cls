@SuppressWarnings('PMD')
@isTest
private with sharing class FSCClientsHelper_Test {
  @isTest
  static void createCIF_PersonAccount_Test() {
    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
    Account acc = new Account();
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    acc.FirstName = 'Test';
    acc.LastName = 'PF Helper';
    acc.ACC_TipoIdentificacion__c = 'Cédula';
    acc.FinServ__IndividualId__c = '11122233344';
    acc.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
    acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
    acc.ACC_Genero__c = 'FEMENINO';
    acc.ACC_Estado_Civil__c = 'SOLTERO/A';
    insert acc;

    FSCClientsHelper helper = new FSCClientsHelper();

    Test.startTest();
    helper.createCIF(acc);
    Test.stopTest();
  }

  @isTest
  static void createCIF_IndustriesBusiness_Test() {
    Test.setMock(HttpCalloutMock.class, new INT008TestMock('PJ'));
    Account acc = new Account();
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesBusiness').getRecordTypeId();
    acc.Name = 'Empresa Helper Test';
    acc.ACC_RNC__c = 'RNCHELPER';
    acc.ACC_Condicion__c = 'PROSPECTO';
    acc.ACC_Estado__c = 'INICIADO';
    acc.ACC_TipoIdentificacion__c = 'RNC';
    insert acc;

    Contact con = new Contact(LastName = 'Contacto IB', AccountId = acc.Id);
    insert con;

    FSCClientsHelper helper = new FSCClientsHelper();

    Test.startTest();
    helper.createCIF(acc);
    Test.stopTest();
  }

  @isTest
  static void createCIF_otherRecordType_Test() {
    Account acc = new Account();
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
    acc.Name = 'Empresa No Match';
    acc.ACC_RNC__c = '111111';
    acc.ACC_Condicion__c = 'PROSPECTO';
    acc.ACC_Estado__c = 'INICIADO';
    acc.ACC_TipoIdentificacion__c = 'RNC';
    insert acc;

    FSCClientsHelper helper = new FSCClientsHelper();

    Test.startTest();
    helper.createCIF(acc);
    Test.stopTest();
  }

  @isTest
  static void updateCIF_PersonAccount_Test() {
    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
    Account acc = new Account();
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    acc.FirstName = 'Update';
    acc.LastName = 'CIF Test';
    acc.ACC_TipoIdentificacion__c = 'Cédula';
    acc.FinServ__IndividualId__c = '44455566677';
    acc.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
    acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
    acc.ACC_Genero__c = 'FEMENINO';
    acc.ACC_Estado_Civil__c = 'SOLTERO/A';
    insert acc;

    FSCClientsHelper helper = new FSCClientsHelper();

    Test.startTest();
    helper.updateCIF(acc);
    Test.stopTest();
  }

  @isTest
  static void updateCIF_otherRecordType_Test() {
    Account acc = new Account();
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
    acc.Name = 'No Update Match';
    acc.ACC_RNC__c = '1111111';
    acc.ACC_Condicion__c = 'PROSPECTO';
    acc.ACC_Estado__c = 'INICIADO';
    acc.ACC_TipoIdentificacion__c = 'RNC';
    insert acc;

    FSCClientsHelper helper = new FSCClientsHelper();

    Test.startTest();
    helper.updateCIF(acc);
    Test.stopTest();
  }
}