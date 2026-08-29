@SuppressWarnings('PMD')
@isTest
private with sharing class AccountTrigger_Test {
  @isTest
  static void afterInsert_PersonAccount_Test() {
    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));

    Test.startTest();
    Account acc = new Account();
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    acc.FirstName = 'Trigger';
    acc.LastName = 'PF Test';
    acc.ACC_TipoIdentificacion__c = 'Cédula';
    acc.FinServ__IndividualId__c = '11100011100';
    acc.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
    acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
    acc.ACC_Genero__c = 'FEMENINO';
    acc.ACC_Estado_Civil__c = 'SOLTERO/A';
    insert acc;
    Test.stopTest();

    System.assertNotEquals(null, acc.Id);
  }

  @isTest
  static void afterInsert_IndustriesBusiness_Test() {
    Test.setMock(HttpCalloutMock.class, new INT008TestMock('PJ'));

    Test.startTest();
    Account acc = new Account();
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesBusiness').getRecordTypeId();
    acc.Name = 'Trigger IB Test';
    acc.ACC_RNC__c = '11111';
    acc.ACC_Condicion__c = 'PROSPECTO';
    acc.ACC_Estado__c = 'INICIADO';
    acc.ACC_TipoIdentificacion__c = 'RNC';
    insert acc;

    // Contact needed by INT008_FSC.fillReferences
    Contact con = new Contact(LastName = 'Contacto Trigger IB', AccountId = acc.Id);
    insert con;
    Test.stopTest();

    System.assertNotEquals(null, acc.Id);
  }

  @isTest
  static void afterInsert_otherRecordType_Test() {
    Test.startTest();
    Account acc = new Account();
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
    acc.Name = 'Trigger Other RT';
    acc.ACC_RNC__c = '111111';
    acc.ACC_Condicion__c = 'PROSPECTO';
    acc.ACC_Estado__c = 'INICIADO';
    acc.ACC_TipoIdentificacion__c = 'RNC';
    insert acc;
    Test.stopTest();

    System.assertNotEquals(null, acc.Id);
  }

  @isTest
  static void beforeUpdate_PersonAccount_Test() {
    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
    Account acc = new Account();
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    acc.FirstName = 'Update';
    acc.LastName = 'Trigger Test';
    acc.ACC_TipoIdentificacion__c = 'Cédula';
    acc.FinServ__IndividualId__c = '22200022200';
    acc.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
    acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
    acc.ACC_Genero__c = 'FEMENINO';
    acc.ACC_Estado_Civil__c = 'SOLTERO/A';
    insert acc;

    Test.startTest();
    acc.FirstName = 'Updated';
    update acc;
    Test.stopTest();

    Account updated = [SELECT FirstName FROM Account WHERE Id = :acc.Id];
    System.assertEquals('Updated', updated.FirstName);
  }

  @isTest
  static void beforeUpdate_otherRecordType_Test() {
    Account acc = new Account();
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
    acc.Name = 'Update Other RT';
    acc.ACC_RNC__c = '111111';
    acc.ACC_Condicion__c = 'PROSPECTO';
    acc.ACC_Estado__c = 'INICIADO';
    acc.ACC_TipoIdentificacion__c = 'RNC';
    insert acc;

    Test.startTest();
    acc.Name = 'Updated Other RT';
    update acc;
    Test.stopTest();

    Account updated = [SELECT Name FROM Account WHERE Id = :acc.Id];
    System.assertEquals('Updated Other RT', updated.Name);
  }
}