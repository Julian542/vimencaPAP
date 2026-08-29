@isTest
private class AccountValidationController_Test {
  @testSetup
  static void setup() {
    // Bypass AccountTrigger para evitar callouts
    Bypass_Trigger__c bt = new Bypass_Trigger__c();
    bt.Usernames_Allowed__c = UserInfo.getUserName();
    insert bt;

    // Crear Account de prueba
    Account acc = new Account(Name = 'Test Account', ACC_Resultado_Validacion__c = 'Aprobado', ACC_Persona_PEP__c = 'NO', FinServ__Status__c = 'INICIADO');
    insert acc;

    // Crear Contact relacionado
    Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
    insert con;

    // Crear ContactPointPhone
    ContactPointPhone cpp = new ContactPointPhone(ParentId = acc.Id, TelephoneNumber = '8091234567', IsPrimary = true);
    insert cpp;

    // Crear ContactPointAddress
    ContactPointAddress cpa = new ContactPointAddress(ParentId = acc.Id, Name = 'Test Address', Street = 'Calle Test 123', City = 'Santo Domingo', Country = 'Dominican Republic', IsPrimary = true);
    insert cpa;

    // Crear Informacion Financiera
    Informacion_Financiera__c inf = new Informacion_Financiera__c(INF_Cuenta__c = acc.Id, INF_Fuente_de_ingresos__c = 'Herencia');
    insert inf;

    // Obtener RecordType para ContactRole
    Id contactRoleRecordTypeId = Schema.SObjectType.FinServ__ReciprocalRole__c.getRecordTypeInfosByDeveloperName().get('ContactRole').getRecordTypeId();

    // Crear ReciprocalRole para ContactContactRelation
    FinServ__ReciprocalRole__c role = new FinServ__ReciprocalRole__c(Name = 'Test Role', FinServ__InverseRole__c = 'Test Role', RecordTypeId = contactRoleRecordTypeId);
    insert role;

    // Crear ContactContactRelation
    FinServ__ContactContactRelation__c ccr = new FinServ__ContactContactRelation__c(FinServ__Contact__c = con.Id, FinServ__Role__c = role.Id);
    insert ccr;
  }

  @isTest
  static void testGetAccountValidation_AllDataPresent() {
    // Arrange
    Account acc = [SELECT Id FROM Account LIMIT 1];

    // Act
    Test.startTest();
    AccountValidationController.ValidationResult result = AccountValidationController.getAccountValidation(acc.Id);
    Test.stopTest();

    // Assert
    System.assertEquals(true, result.hasContactPoints, 'Should have contact points');
    System.assertEquals(true, result.hasAddresses, 'Should have addresses');
    System.assertEquals(true, result.hasFinancialInfo, 'Should have financial info');
    System.assertEquals(true, result.hasReferences, 'Should have references');
    System.assertEquals('Aprobado', result.resultadoValidacion, 'Should be Aprobado');
    System.assertEquals('NO', result.validacionPEP, 'PEP should be NO');
    System.assertEquals('INICIADO', result.clientStatus, 'Status should be INICIADO');
  }

  @isTest
  static void testGetAccountValidation_NoRelatedData() {
    Account acc = new Account(Name = 'Empty Account', ACC_Resultado_Validacion__c = 'Pendiente', ACC_Persona_PEP__c = 'SI');
    insert acc;

    Test.startTest();
    AccountValidationController.ValidationResult result = AccountValidationController.getAccountValidation(acc.Id);
    Test.stopTest();

    System.assertEquals(false, result.hasContactPoints, 'Should not have contact points');
    System.assertEquals(false, result.hasAddresses, 'Should not have addresses');
    System.assertEquals(false, result.hasFinancialInfo, 'Should not have financial info');
    System.assertEquals(false, result.hasReferences, 'Should not have references');
    System.assertEquals('Pendiente', result.resultadoValidacion, 'Should be Pendiente');
    System.assertEquals('SI', result.validacionPEP, 'PEP should be SI');
  }

  @isTest
  static void testGetAccountValidation_NullAccountId() {
    Test.startTest();
    AccountValidationController.ValidationResult result = AccountValidationController.getAccountValidation(null);
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(false, result.hasContactPoints, 'Should not have contact points');
    System.assertEquals(false, result.hasAddresses, 'Should not have addresses');
    System.assertEquals(false, result.hasFinancialInfo, 'Should not have financial info');
    System.assertEquals(false, result.hasReferences, 'Should not have references');
  }

  @isTest
  static void testGetAccountValidation_PartialData() {
    Account acc = new Account(Name = 'Partial Account', ACC_Resultado_Validacion__c = 'Rechazado');
    insert acc;

    ContactPointPhone cpp = new ContactPointPhone(ParentId = acc.Id, TelephoneNumber = '8099876543', IsPrimary = true);
    insert cpp;

    ContactPointAddress cpa = new ContactPointAddress(ParentId = acc.Id, Name = 'Partial Address', Street = 'Calle Parcial 456', City = 'Santiago');
    insert cpa;

    Test.startTest();
    AccountValidationController.ValidationResult result = AccountValidationController.getAccountValidation(acc.Id);
    Test.stopTest();

    System.assertEquals(true, result.hasContactPoints, 'Should have contact points');
    System.assertEquals(true, result.hasAddresses, 'Should have addresses');
    System.assertEquals(false, result.hasFinancialInfo, 'Should not have financial info');
    System.assertEquals(false, result.hasReferences, 'Should not have references');
    System.assertEquals('Rechazado', result.resultadoValidacion, 'Should be Rechazado');
  }

  @isTest
  static void testGetAccountValidation_MultipleContacts() {
    Account acc = [SELECT Id FROM Account LIMIT 1];

    List<ContactPointPhone> phones = new List<ContactPointPhone>();
    for (Integer i = 0; i < 3; i++) {
      phones.add(new ContactPointPhone(ParentId = acc.Id, TelephoneNumber = '80912345' + i, IsPrimary = (i == 0)));
    }
    insert phones;

    List<ContactPointAddress> addresses = new List<ContactPointAddress>();
    for (Integer i = 0; i < 2; i++) {
      addresses.add(new ContactPointAddress(ParentId = acc.Id, Name = 'Address ' + i, Street = 'Street ' + i, City = 'City ' + i));
    }
    insert addresses;

    Test.startTest();
    AccountValidationController.ValidationResult result = AccountValidationController.getAccountValidation(acc.Id);
    Test.stopTest();

    System.assertEquals(true, result.hasContactPoints, 'Should have contact points');
    System.assertEquals(true, result.hasAddresses, 'Should have addresses');
  }

  @isTest
  static void testValidationResult_Constructor() {
    AccountValidationController.ValidationResult result = new AccountValidationController.ValidationResult();

    System.assertEquals(false, result.hasContactPoints, 'Default should be false');
    System.assertEquals(false, result.hasAddresses, 'Default should be false');
    System.assertEquals(false, result.hasFinancialInfo, 'Default should be false');
    System.assertEquals(false, result.hasReferences, 'Default should be false');
    System.assertEquals(null, result.resultadoValidacion, 'Default should be null');
    System.assertEquals(null, result.validacionFATCA, 'Default should be null');
    System.assertEquals(null, result.validacionPEP, 'Default should be null');
    System.assertEquals(null, result.datosFinancieros, 'Default should be null');
    System.assertEquals(null, result.clientStatus, 'Default should be null');
  }
}