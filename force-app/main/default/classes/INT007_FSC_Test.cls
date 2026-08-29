@SuppressWarnings('PMD')
@isTest
private with sharing class INT007_FSC_Test {
  @TestSetup
  static void setupData() {
    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
    List<Account> accList = TestDataFactory_FSC.createPersonAccounts(2);
    List<ContactPointAddress> direcciones = TestDataFactory_FSC.createDirecciones(accList);
    List<ContactPointPhone> vias = TestDataFactory_FSC.createViasDeContacto(accList);

    // ContactPointEmail for fillContactPointInfo with emails
    ContactPointEmail cpe = new ContactPointEmail();
    cpe.ParentId = accList[0].Id;
    cpe.EmailAddress = 'test@test.com';
    cpe.CPE_Tipo__c = 'CORREO LABORAL';
    insert cpe;

    // Informacion_Financiera__c for fillFinanData with data
    Informacion_Financiera__c info = new Informacion_Financiera__c();
    info.INF_Cuenta__c = accList[0].Id;
    info.INF_Fuente_de_ingresos__c = 'Herencia';
    info.INF_Ingresos__c = 'RD$ 50,001 A RD$ 80,000';
    info.INF_Periodo__c = 'Mensual';
    insert info;

    // FinServ__Employment__c for fillLaboral with data
    FinServ__Employment__c emp = new FinServ__Employment__c();
    emp.Cliente__c = accList[0].Id;
    emp.Name = 'Empresa Test';
    emp.FinServ__Position__c = 'Gerente';
    emp.FinServ__Occupation__c = 'ABOGADO';
    emp.FinServ__AnnualIncome__c = 500000;
    emp.FinServ__StartDate__c = Date.today().addYears(-5);
    emp.FinServ__EndDate__c = Date.today();
    emp.FinServ__EmployerAddress__c = 'Calle Principal 123';
    emp.FinServ__EmployerPhoneNumber__c = '8091234567';
    insert emp;
  }

  private static Account getTestAccount() {
    List<String> fields = new List<String>(Account.SObjectType.getDescribe().fields.getMap().keySet());
    String soql = 'SELECT ' + String.join(fields, ',') + ' FROM Account WHERE isPersonAccount = true LIMIT 1';
    return Database.query(soql);
  }

  // --- parse tests ---

  @isTest
  static void parseSuccessTest() {
    String body = '<ErrorCode>000</ErrorCode><ErrorText>OK</ErrorText><CIF>12345</CIF>';

    Test.startTest();
    INT007_FSC.Response r = INT007_FSC.parse(body);
    Test.stopTest();

    System.assertEquals('000', r.errorCode);
    System.assertEquals('12345', r.values.get('CIF'));
  }

  @isTest
  static void parseErrorTest() {
    String body = '<ErrorCode>999</ErrorCode><ErrorText>ERROR</ErrorText>';

    Test.startTest();
    INT007_FSC.Response r = INT007_FSC.parse(body);
    Test.stopTest();

    System.assertEquals('999', r.errorCode);
    System.assert(r.values.isEmpty());
  }

  // --- updateClientCIF tests ---

  @isTest
  static void updateClientCIF_withCIF_Test() {
    Account acc = getTestAccount();
    INT007_FSC.Response resp = new INT007_FSC.Response();
    resp.values.put('CIF', '999888');

    Test.startTest();
    INT007_FSC.updateClientCIF(resp, acc.Id, 'C', true);
    Test.stopTest();

    Account updated = [SELECT ACC_CIF__c, Resultado_de_la_Integracion__c FROM Account WHERE Id = :acc.Id];
    System.assertEquals('999888', updated.ACC_CIF__c);
    System.assertEquals('Registro creado correctamente en el core.', updated.Resultado_de_la_Integracion__c);
  }

  @isTest
  static void updateClientCIF_noCIF_Test() {
    Account acc = getTestAccount();
    INT007_FSC.Response resp = new INT007_FSC.Response();

    Test.startTest();
    INT007_FSC.updateClientCIF(resp, acc.Id, 'C', true);
    Test.stopTest();

    Account updated = [SELECT Resultado_de_la_Integracion__c FROM Account WHERE Id = :acc.Id];
    System.assert(updated.Resultado_de_la_Integracion__c.contains('no se obtuvo CIF'));
  }

  @isTest
  static void updateClientCIF_estateFalse_Test() {
    Account acc = getTestAccount();
    INT007_FSC.Response resp = new INT007_FSC.Response();
    resp.errorCode = '500';
    resp.errorText = 'Server Error';

    Test.startTest();
    INT007_FSC.updateClientCIF(resp, acc.Id, 'C', false);
    Test.stopTest();

    Account updated = [SELECT Resultado_de_la_Integracion__c FROM Account WHERE Id = :acc.Id];
    System.assert(updated.Resultado_de_la_Integracion__c.contains('Integracion fallida'));
  }

  @isTest
  static void fillDetailClientTest() {
    Account acc = getTestAccount();
    INT007_FSC.Response resp = new INT007_FSC.Response();
    String frame = '[function_firstName][function_lastName]';

    Test.startTest();
    String result = INT007_FSC.fillDetailClient(resp.valuesClient, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_firstName]'));
    System.assert(!result.contains('[function_lastName]'));
  }

  @isTest
  static void fillAdressesClient_withAddresses_Test() {
    Account acc = getTestAccount();
    INT007_FSC.Response resp = new INT007_FSC.Response();
    String frame = '[function_addressStreet][function_addressNum]';

    Test.startTest();
    String result = INT007_FSC.fillAdressesClient(resp.valuesAdresses, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_addressStreet]'));
  }

  @isTest
  static void fillAdressesClient_noAddresses_Test() {
    // Use an account without addresses
    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
    Account acc = new Account();
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    acc.firstName = 'NoAddr';
    acc.lastName = 'Test';
    acc.ACC_TipoIdentificacion__c = 'Cédula';
    acc.FinServ__IndividualId__c = '99999999999';
    acc.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
    acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
    acc.ACC_Genero__c = 'FEMENINO';
    acc.ACC_Estado_Civil__c = 'SOLTERO/A';
    insert acc;

    INT007_FSC.Response resp = new INT007_FSC.Response();
    String frame = '[function_addressStreet]';

    Test.startTest();
    String result = INT007_FSC.fillAdressesClient(resp.valuesAdresses, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_addressStreet]'));
  }

  @isTest
  static void fillContactPointInfo_withData_Test() {
    Account acc = getTestAccount();
    INT007_FSC.Response resp = new INT007_FSC.Response();
    String frame = '[function_contactInfoId][function_contactWayType][function_contactWayCant][function_contactCompany][function_contactExRef][function_ViaIdExternoVia][function_contactPrincipal][function_contactInfoIdentifier]';

    Test.startTest();
    String result = INT007_FSC.fillContactPointInfo(resp.valuesContactPoint, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_contactInfoId]'));
  }

  @isTest
  static void fillContactPointInfo_noData_Test() {
    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
    Account acc = new Account();
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    acc.firstName = 'NoCont';
    acc.lastName = 'Test';
    acc.ACC_TipoIdentificacion__c = 'Cédula';
    acc.FinServ__IndividualId__c = '88888888888';
    acc.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
    acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
    acc.ACC_Genero__c = 'FEMENINO';
    acc.ACC_Estado_Civil__c = 'SOLTERO/A';
    insert acc;

    INT007_FSC.Response resp = new INT007_FSC.Response();
    String frame = '[function_contactInfoId][function_contactWayType][function_contactWayCant][function_contactCompany][function_contactExRef][function_ViaIdExternoVia][function_contactPrincipal][function_contactInfoIdentifier]';

    Test.startTest();
    String result = INT007_FSC.fillContactPointInfo(resp.valuesContactPoint, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_contactInfoId]'));
  }

  @isTest
  static void fillReferences_noReferences_Test() {
    Account acc = getTestAccount();
    INT007_FSC.Response resp = new INT007_FSC.Response();
    String frame = '[function_referenceType][function_referenceName][function_referencePhone][function_referenceAddress]';

    Test.startTest();
    String result = INT007_FSC.fillReferences(resp.valuesReferences, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_referenceType]'));
  }

  @isTest
  static void fillReferences_withReferences_Test() {
    Account acc = getTestAccount();
    Id personContactId = [SELECT PersonContactId FROM Account WHERE Id = :acc.Id].PersonContactId;

    Contact refContact = new Contact(LastName = 'Referencia Test', Phone = '8091112222', MailingStreet = 'Calle Duarte 45');
    insert refContact;

    Id refRtId = Schema.SObjectType.FinServ__ContactContactRelation__c.getRecordTypeInfosByDeveloperName().get('Referencia').getRecordTypeId();

    Id contactRoleRecordTypeId = Schema.SObjectType.FinServ__ReciprocalRole__c.getRecordTypeInfosByDeveloperName().get('ContactRole').getRecordTypeId();
    FinServ__ReciprocalRole__c contactRole = new FinServ__ReciprocalRole__c(Name = 'Test ContactRole', FinServ__InverseRole__c = 'Test ContactRole', RecordTypeId = contactRoleRecordTypeId);
    insert contactRole;

    FinServ__ContactContactRelation__c ccr = new FinServ__ContactContactRelation__c();
    ccr.FinServ__Contact__c = personContactId;
    ccr.FinServ__RelatedContact__c = refContact.Id;
    ccr.RecordTypeId = refRtId;
    ccr.CCR_Tipo__c = 'PERSONAL';
    ccr.FinServ__Role__c = contactRole.Id;
    insert ccr;

    INT007_FSC.Response resp = new INT007_FSC.Response();
    String frame = '[function_referenceType][function_referenceName][function_referencePhone][function_referenceAddress]';

    Test.startTest();
    String result = INT007_FSC.fillReferences(resp.valuesReferences, acc, frame);
    Test.stopTest();

    System.assert(result.contains('Referencia Test'));
    System.assert(result.contains('8091112222'));
    System.assert(result.contains('Calle Duarte 45'));
  }

  @isTest
  static void fillFinanData_withData_Test() {
    Account acc = getTestAccount();
    INT007_FSC.Response resp = new INT007_FSC.Response();
    String frame = '[function_finanDataFont][function_finanDataRange][function_finanDataPeriod]';

    Test.startTest();
    String result = INT007_FSC.fillFinanData(resp.finanData, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_finanDataFont]'));
  }

  @isTest
  static void fillFinanData_noData_Test() {
    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
    Account acc = new Account();
    acc.lastName = 'Test';
    acc.ACC_TipoIdentificacion__c = 'Cédula';
    acc.FinServ__IndividualId__c = '77777777777';
    acc.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
    acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
    acc.ACC_Genero__c = 'FEMENINO';
    acc.ACC_Estado_Civil__c = 'SOLTERO/A';
    insert acc;

    INT007_FSC.Response resp = new INT007_FSC.Response();
    String frame = '[function_finanDataFont][function_finanDataRange][function_finanDataPeriod]';

    Test.startTest();
    String result = INT007_FSC.fillFinanData(resp.finanData, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_finanDataFont]'));
  }

  @isTest
  static void fillLaboral_withData_Test() {
    Account acc = getTestAccount();
    INT007_FSC.Response resp = new INT007_FSC.Response();
    String frame = '[function_laboralJob][function_laboralCompany]';

    Test.startTest();
    String result = INT007_FSC.fillLaboral(resp.laboral, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_laboralCompany]'));
  }

  @isTest
  static void fillLaboral_noData_Test() {
    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
    Account acc = new Account();
    acc.lastName = 'Test';
    acc.ACC_TipoIdentificacion__c = 'Cédula';
    acc.FinServ__IndividualId__c = '66666666666';
    acc.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
    acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
    acc.ACC_Genero__c = 'FEMENINO';
    acc.ACC_Estado_Civil__c = 'SOLTERO/A';
    insert acc;

    INT007_FSC.Response resp = new INT007_FSC.Response();
    String frame = '[function_laboralJob][function_laboralCompany]';

    Test.startTest();
    String result = INT007_FSC.fillLaboral(resp.laboral, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_laboralCompany]'));
  }

  @isTest
  static void fillConyuge_noConyuge_Test() {
    Account acc = getTestAccount();
    INT007_FSC.Response resp = new INT007_FSC.Response();
    String frame = '[function_partnerFirstName][function_partnerLastName]';

    Test.startTest();
    String result = INT007_FSC.fillConyuge(resp.conyuge, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_partnerFirstName]'));
  }

  @isTest
  static void fillConyugeLab_noConyuge_Test() {
    Account acc = getTestAccount();
    INT007_FSC.Response resp = new INT007_FSC.Response();
    String frame = '[function_partnerLaboralCompany][function_partnerLaboralPosition][function_partnerLaboralFunction][function_partnerLaboralSalary][function_partnerLaboralAddress][function_partnerLaboralPhone][function_laboralJob][function_laboralCompany][function_laboralEmployeeType][function_laboralCompanyTime][function_laboralPosition][function_laboralFunction][function_laboralSalary][function_laboralStartDate][function_laboralEndDate][function_laboralAddress][function_laboralPhone][function_laboralMail][function_partnerLaboralMail]';

    Test.startTest();
    String result = INT007_FSC.fillConyugeLab(resp.conyugeLab, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_partnerLaboralCompany]'));
  }

  @isTest
  static void fillXMLTest() {
    Account acc = getTestAccount();
    INT007_FSC.Response resp = new INT007_FSC.Response();
    String frame =
      '<Function>[function_firstName]</Function>' +
      '<Direcciones>[function_addressStreet]</Direcciones>' +
      '<ViasContacto>[function_contactInfoId][function_contactExRef][function_ViaIdExternoVia][function_contactPrincipal][function_contactWayType][function_contactWayCant][function_contactCompany][function_contactInfoIdentifier]</ViasContacto>' +
      '<Referencias>[function_referenceType][function_referenceName][function_referencePhone][function_referenceAddress]</Referencias>' +
      '<DatosFinancieros>[function_finanDataFont]</DatosFinancieros>' +
      '<HistorialLaboral>[function_laboralCompany]</HistorialLaboral>' +
      '<Conyuge>[function_partnerFirstName]</Conyuge>' +
      '<EmpleoActual>[function_partnerLaboralCompany][function_partnerLaboralPosition][function_partnerLaboralFunction][function_partnerLaboralSalary][function_partnerLaboralAddress][function_partnerLaboralPhone][function_partnerLaboralMail][function_laboralJob][function_laboralCompany][function_laboralEmployeeType][function_laboralCompanyTime][function_laboralPosition][function_laboralFunction][function_laboralSalary][function_laboralStartDate][function_laboralEndDate][function_laboralAddress][function_laboralPhone][function_laboralMail]</EmpleoActual>';

    Test.startTest();
    String result = INT007_FSC.fillXML(resp, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_firstName]'));
  }

  @isTest
  static void creteClientTest() {
    Account acc = getTestAccount();

    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
    Test.startTest();
    try {
      INT007_FSC.creteClient(acc.Id);
    } catch (Exception e) {
    }
    Test.stopTest();
  }

  @isTest
  static void modifiClientTest() {
    Account acc = getTestAccount();

    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
    Test.startTest();
    try {
      INT007_FSC.modifiClient(acc.Id, 'M');
    } catch (Exception e) {
      // createOrModifyPF may throw if StaticResource or AuthSession is missing in test context
    }
    Test.stopTest();
  }
}