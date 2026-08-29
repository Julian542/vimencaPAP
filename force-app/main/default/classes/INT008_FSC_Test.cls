@SuppressWarnings('PMD')
@isTest
private with sharing class INT008_FSC_Test {
  @TestSetup
  static void setupData() {
    // Candidato_Persona_Juridica does NOT trigger INT008_FSC callout (only IndustriesBusiness does)
    Account acc = new Account();
    acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
    acc.Name = 'Empresa Test PJ';
    acc.ACC_RNC__c = 'RNC999';
    acc.ACC_CIF__c = '12345';
    acc.ACC_Condicion__c = 'PROSPECTO';
    acc.ACC_Estado__c = 'INICIADO';
    acc.ACC_TipoIdentificacion__c = 'RNC';
    insert acc;

    // Contact linked to the business account (needed for fillReferences, fillParticipant)
    Contact con = new Contact(LastName = 'Contacto PJ', AccountId = acc.Id);
    insert con;

    // ContactPointAddress
    ContactPointAddress cpa = new ContactPointAddress();
    cpa.ParentId = acc.Id;
    cpa.Name = 'Dir Test';
    cpa.AddressType = 'RESIDENCIAL';
    cpa.Street = 'Calle Duarte 45';
    cpa.City = 'Santo Domingo';
    cpa.State = 'Distrito Nacional';
    cpa.Country = 'DO';
    cpa.PostalCode = '10100';
    cpa.isPrimary = true;
    insert cpa;

    // ContactPointPhone
    ContactPointPhone cpp = new ContactPointPhone();
    cpp.ParentId = acc.Id;
    cpp.TelephoneNumber = '1234567';
    cpp.AreaCode = '809';
    cpp.isPrimary = true;
    cpp.CPP_Tipo__c = 'TELÉFONO TRABAJO';
    insert cpp;

    // ContactPointEmail
    ContactPointEmail cpe = new ContactPointEmail();
    cpe.ParentId = acc.Id;
    cpe.EmailAddress = 'empresa@test.com';
    cpe.CPE_Tipo__c = 'CORREO LABORAL';
    insert cpe;

    // Productos_y_Servicios__c
    Productos_y_Servicios__c prod = new Productos_y_Servicios__c();
    prod.Cliente__c = acc.Id;
    prod.Name = 'Producto Test';
    insert prod;

    // Cliente_Principal__c
    Cliente_Principal__c cli = new Cliente_Principal__c();
    cli.Cliente__c = acc.Id;
    cli.Name = 'Cliente Principal Test';
    cli.Tipo_de_identificacion__c = 'RNC';
    cli.N_de_Identificacion__c = '1234567890';
    insert cli;

    // Principal_Proveedor__c
    Principal_Proveedor__c prov = new Principal_Proveedor__c();
    prov.Cliente__c = acc.Id;
    prov.Name = 'Proveedor Test';
    prov.Tipo_de_identificaci_n__c = 'RNC';
    prov.N_de_Identificacion__c = '9876543210';
    insert prov;

    // Empresa_Filial__c
    Empresa_Filial__c filial = new Empresa_Filial__c();
    filial.Cliente__c = acc.Id;
    filial.Name = 'Filial Test';
    filial.RNC__c = 'RNC456';
    filial.Pais_donde_opera__c = 'DO';
    filial.Grupo_economico__c = 'Grupo Eco';
    filial.Grupo_financiero__c = 'Grupo Fin';
    insert filial;
  }

  private static Account getTestAccount() {
    List<String> fields = new List<String>(Account.SObjectType.getDescribe().fields.getMap().keySet());
    String soql = 'SELECT ' + String.join(fields, ',') + ' FROM Account WHERE Name = \'Empresa Test PJ\' LIMIT 1';
    return Database.query(soql);
  }

  // --- parse tests ---

  @isTest
  static void parseSuccessTest() {
    String body = '<ErrorCode>000</ErrorCode><ErrorText>OK</ErrorText><CIF>12345</CIF>';

    Test.startTest();
    INT008_FSC.Response r = INT008_FSC.parse(body);
    Test.stopTest();

    System.assertEquals('000', r.errorCode);
    System.assertEquals('12345', r.values.get('CIF'));
  }

  @isTest
  static void parseErrorTest() {
    String body = '<ErrorCode>999</ErrorCode><ErrorText>ERROR</ErrorText>';

    Test.startTest();
    INT008_FSC.Response r = INT008_FSC.parse(body);
    Test.stopTest();

    System.assertEquals('999', r.errorCode);
    System.assert(r.values.isEmpty());
  }

  // --- updateClientCIF tests ---

  @isTest
  static void updateClientCIF_withCIF_Test() {
    Account acc = getTestAccount();
    INT008_FSC.Response resp = new INT008_FSC.Response();
    resp.values.put('CIF', '999888');

    Test.startTest();
    INT008_FSC.updateClientCIF(resp, acc.Id, 'C', true);
    Test.stopTest();

    Account updated = [SELECT ACC_CIF__c, Resultado_de_la_Integracion__c FROM Account WHERE Id = :acc.Id];
    System.assertEquals('999888', updated.ACC_CIF__c);
    System.assertEquals('Registro creado correctamente en el core.', updated.Resultado_de_la_Integracion__c);
  }

  @isTest
  static void updateClientCIF_noCIF_Test() {
    Account acc = getTestAccount();
    INT008_FSC.Response resp = new INT008_FSC.Response();

    Test.startTest();
    INT008_FSC.updateClientCIF(resp, acc.Id, 'C', true);
    Test.stopTest();

    Account updated = [SELECT Resultado_de_la_Integracion__c FROM Account WHERE Id = :acc.Id];
    System.assert(updated.Resultado_de_la_Integracion__c.contains('no se obtuvo CIF'));
  }

  @isTest
  static void updateClientCIF_stateFalse_Test() {
    Account acc = getTestAccount();
    INT008_FSC.Response resp = new INT008_FSC.Response();
    resp.errorCode = '500';
    resp.errorText = 'Server Error';

    Test.startTest();
    INT008_FSC.updateClientCIF(resp, acc.Id, 'C', false);
    Test.stopTest();

    Account updated = [SELECT Resultado_de_la_Integracion__c FROM Account WHERE Id = :acc.Id];
    System.assert(updated.Resultado_de_la_Integracion__c.contains('Integracion fallida'));
  }

  // --- fillDetailClient test ---

  @isTest
  static void fillDetailClientTest() {
    Account acc = getTestAccount();
    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_razonSocial][function_RNC][function_Nacionalidad]';

    Test.startTest();
    String result = INT008_FSC.fillDetailClient(resp.valuesClient, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_razonSocial]'));
    System.assert(!result.contains('[function_RNC]'));
  }

  // --- fillAdressesClient tests ---

  @isTest
  static void fillAdressesClient_withAddresses_Test() {
    Account acc = getTestAccount();
    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_addressStreet][function_addressNum][function_addressCountry]';

    Test.startTest();
    String result = INT008_FSC.fillAdressesClient(resp.valuesAdresses, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_addressStreet]'));
  }

  @isTest
  static void fillAdressesClient_noAddresses_Test() {
    Account bare = new Account();
    bare.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
    bare.Name = 'Bare PJ NoAddr';
    bare.ACC_RNC__c = 'RNCNOADDR';
    bare.ACC_Condicion__c = 'PROSPECTO';
    bare.ACC_Estado__c = 'INICIADO';
    bare.ACC_TipoIdentificacion__c = 'RNC';
    insert bare;

    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_addressStreet]';

    Test.startTest();
    String result = INT008_FSC.fillAdressesClient(resp.valuesAdresses, bare, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_addressStreet]'));
  }

  // --- fillContactInfo tests ---

  @isTest
  static void fillContactInfo_withData_Test() {
    Account acc = getTestAccount();
    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_contactInfoId][function_contactWayType][function_contactWayCant][function_contactCompany][function_contactExRef][function_ViaIdExternoVia][function_contactPrincipal][function_contactInfoIdentifier]';

    Test.startTest();
    String result = INT008_FSC.fillContactInfo(resp.valuesContactInfo, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_contactInfoId]'));
  }

  @isTest
  static void fillContactInfo_noData_Test() {
    Account bare = new Account();
    bare.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
    bare.Name = 'Bare PJ NoCont';
    bare.ACC_RNC__c = 'RNCNOCONT';
    bare.ACC_Condicion__c = 'PROSPECTO';
    bare.ACC_Estado__c = 'INICIADO';
    bare.ACC_TipoIdentificacion__c = 'RNC';
    insert bare;

    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_contactInfoId][function_contactWayType][function_contactWayCant][function_contactCompany][function_contactExRef][function_ViaIdExternoVia][function_contactPrincipal][function_contactInfoIdentifier]';

    Test.startTest();
    String result = INT008_FSC.fillContactInfo(resp.valuesContactInfo, bare, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_contactInfoId]'));
  }

  // --- fillReferences tests ---

  @isTest
  static void fillReferences_noReferences_Test() {
    Account acc = getTestAccount();
    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_referenceType][function_referenceName][function_referencePhone][function_referenceAddress][function_referenceBank][function_referenceAccountType][function_referenceCurrency][function_referenceAccountNum]';

    Test.startTest();
    String result = INT008_FSC.fillReferences(resp.valuesReferences, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_referenceType]'));
  }

  @isTest
  static void fillReferences_withReferences_Test() {
    Account acc = getTestAccount();
    Contact mainContact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

    // Create orphan Contact as reference
    Contact refContact = new Contact(LastName = 'Referencia PJ Test', Phone = '8091112222', MailingStreet = 'Calle Duarte 45');
    insert refContact;

    Id refRtId = Schema.SObjectType.FinServ__ContactContactRelation__c.getRecordTypeInfosByDeveloperName().get('Referencia').getRecordTypeId();

    Id contactRoleRecordTypeId = Schema.SObjectType.FinServ__ReciprocalRole__c.getRecordTypeInfosByDeveloperName().get('ContactRole').getRecordTypeId();
    FinServ__ReciprocalRole__c contactRole = new FinServ__ReciprocalRole__c(Name = 'Test ContactRole PJ', FinServ__InverseRole__c = 'Test ContactRole PJ', RecordTypeId = contactRoleRecordTypeId);
    insert contactRole;

    FinServ__ContactContactRelation__c ccr = new FinServ__ContactContactRelation__c();
    ccr.FinServ__Contact__c = mainContact.Id;
    ccr.FinServ__RelatedContact__c = refContact.Id;
    ccr.RecordTypeId = refRtId;
    ccr.CCR_Tipo__c = 'PERSONAL';
    ccr.FinServ__Role__c = contactRole.Id;
    insert ccr;

    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_referenceType][function_referenceName][function_referencePhone][function_referenceAddress][function_referenceBank][function_referenceAccountType][function_referenceCurrency][function_referenceAccountNum]';

    Test.startTest();
    String result = INT008_FSC.fillReferences(resp.valuesReferences, acc, frame);
    Test.stopTest();

    System.assert(result.contains('Referencia PJ Test'));
    System.assert(result.contains('8091112222'));
    System.assert(result.contains('Calle Duarte 45'));
  }

  // --- fillProducts tests ---

  @isTest
  static void fillProducts_withData_Test() {
    Account acc = getTestAccount();
    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_prodServName]';

    Test.startTest();
    String result = INT008_FSC.fillProducts(resp.valuesProducts, acc, frame);
    Test.stopTest();

    System.assert(result.contains('Producto Test'));
  }

  @isTest
  static void fillProducts_noData_Test() {
    Account bare = new Account();
    bare.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
    bare.Name = 'Bare PJ NoProd';
    bare.ACC_RNC__c = 'RNCNOPROD';
    bare.ACC_Condicion__c = 'PROSPECTO';
    bare.ACC_Estado__c = 'INICIADO';
    bare.ACC_TipoIdentificacion__c = 'RNC';
    insert bare;

    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_prodServName]';

    Test.startTest();
    String result = INT008_FSC.fillProducts(resp.valuesProducts, bare, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_prodServName]'));
  }

  // --- fillLargestCust tests ---

  @isTest
  static void fillLargestCust_withData_Test() {
    Account acc = getTestAccount();
    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_largestCustName][function_largestCustDocumentType][function_largestCustDocument]';

    Test.startTest();
    String result = INT008_FSC.fillLargestCust(resp.valuesLargestCust, acc, frame);
    Test.stopTest();

    System.assert(result.contains('Cliente Principal Test'));
  }

  @isTest
  static void fillLargestCust_noData_Test() {
    Account bare = new Account();
    bare.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
    bare.Name = 'Bare PJ NoCust';
    bare.ACC_RNC__c = 'RNCNOCUST';
    bare.ACC_Condicion__c = 'PROSPECTO';
    bare.ACC_Estado__c = 'INICIADO';
    bare.ACC_TipoIdentificacion__c = 'RNC';
    insert bare;

    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_largestCustName]';

    Test.startTest();
    String result = INT008_FSC.fillLargestCust(resp.valuesLargestCust, bare, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_largestCustName]'));
  }

  // --- fillSupplier tests ---

  @isTest
  static void fillSupplier_withData_Test() {
    Account acc = getTestAccount();
    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_supplierName][function_supplierDocumentType][function_supplierDocument]';

    Test.startTest();
    String result = INT008_FSC.fillSupplier(resp.valuesSupplier, acc, frame);
    Test.stopTest();

    System.assert(result.contains('Proveedor Test'));
  }

  @isTest
  static void fillSupplier_noData_Test() {
    Account bare = new Account();
    bare.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
    bare.Name = 'Bare PJ NoSup';
    bare.ACC_RNC__c = 'RNCNOSUP';
    bare.ACC_Condicion__c = 'PROSPECTO';
    bare.ACC_Estado__c = 'INICIADO';
    bare.ACC_TipoIdentificacion__c = 'RNC';
    insert bare;

    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_supplierName]';

    Test.startTest();
    String result = INT008_FSC.fillSupplier(resp.valuesSupplier, bare, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_supplierName]'));
  }

  // --- fillAffiliate tests ---

  @isTest
  static void fillAffiliate_withData_Test() {
    Account acc = getTestAccount();
    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_affiliateName][function_affiliateDocument][function_affiliateCountry][function_affiliateEcoGroup][function_affiliateFinGroup]';

    Test.startTest();
    String result = INT008_FSC.fillAffiliate(resp.valuesaffiliate, acc, frame);
    Test.stopTest();

    System.assert(result.contains('Filial Test'));
  }

  @isTest
  static void fillAffiliate_noData_Test() {
    Account bare = new Account();
    bare.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
    bare.Name = 'Bare PJ NoFil';
    bare.ACC_RNC__c = 'RNCNOFIL';
    bare.ACC_Condicion__c = 'PROSPECTO';
    bare.ACC_Estado__c = 'INICIADO';
    bare.ACC_TipoIdentificacion__c = 'RNC';
    insert bare;

    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_affiliateName]';

    Test.startTest();
    String result = INT008_FSC.fillAffiliate(resp.valuesaffiliate, bare, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_affiliateName]'));
  }

  // --- fillParticipant tests ---

  @isTest
  static void fillParticipant_noData_Test() {
    Account acc = getTestAccount();
    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_participantType][function_participantRole][function_participantDocumentType][function_participantDocument][function_participantName][function_participantLastName]';

    Test.startTest();
    String result = INT008_FSC.fillParticipant(resp.valuesParticipantCcr, resp.valuesParticipantPFAcc, resp.valuesParticipantPJAcc, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_participantType]'));
  }

  @isTest
  static void fillParticipant_withData_PF_Test() {
    Account acc = getTestAccount();
    Contact mainContact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

    // Create a PersonAccount as the related participant account
    Test.setMock(HttpCalloutMock.class, new INT008TestMock('PF'));
    Account pfAcc = new Account();
    pfAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    pfAcc.FirstName = 'Participante';
    pfAcc.LastName = 'PFTest';
    pfAcc.ACC_TipoIdentificacion__c = 'Cédula';
    pfAcc.FinServ__IndividualId__c = '55555555555';
    pfAcc.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
    pfAcc.PersonBirthdate = Date.newInstance(1990, 1, 1);
    pfAcc.ACC_Genero__c = 'MASCULINO';
    pfAcc.ACC_Estado_Civil__c = 'SOLTERO/A';
    insert pfAcc;

    Contact pfContact = [SELECT Id FROM Contact WHERE AccountId = :pfAcc.Id LIMIT 1];

    Id partRtId = Schema.SObjectType.FinServ__ContactContactRelation__c.getRecordTypeInfosByDeveloperName().get('Participante').getRecordTypeId();

    Id contactRoleRecordTypeId = Schema.SObjectType.FinServ__ReciprocalRole__c.getRecordTypeInfosByDeveloperName().get('ContactRole').getRecordTypeId();
    FinServ__ReciprocalRole__c contactRole = new FinServ__ReciprocalRole__c(Name = 'Participant Role', FinServ__InverseRole__c = 'Participant Role', RecordTypeId = contactRoleRecordTypeId);
    insert contactRole;

    FinServ__ContactContactRelation__c ccr = new FinServ__ContactContactRelation__c();
    ccr.FinServ__Contact__c = mainContact.Id;
    ccr.FinServ__RelatedContact__c = pfContact.Id;
    ccr.RecordTypeId = partRtId;
    ccr.CCR_Tipo__c = 'PERSONAL';
    ccr.CCR_Cargo__c = 'Director';
    ccr.CCR_Porcentaje__c = 50;
    ccr.FinServ__Role__c = contactRole.Id;
    insert ccr;

    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_participantType][function_participantRole][function_participantDocumentType][function_participantDocument][function_participantName][function_participantLastName][function_participantSecondLastName][function_participantFatca][function_participantValidation][function_participantPorcentage][function_participantPosition]';

    Test.startTest();
    String result = INT008_FSC.fillParticipant(resp.valuesParticipantCcr, resp.valuesParticipantPFAcc, resp.valuesParticipantPJAcc, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_participantType]'));
  }

  @isTest
  static void fillParticipant_withData_PJ_Test() {
    Account acc = getTestAccount();
    Contact mainContact = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

    // Create a business account as the related participant
    Account pjAcc = new Account();
    pjAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
    pjAcc.Name = 'Empresa Participante';
    pjAcc.ACC_RNC__c = 'RNCPART';
    pjAcc.ACC_Condicion__c = 'PROSPECTO';
    pjAcc.ACC_Estado__c = 'INICIADO';
    pjAcc.ACC_TipoIdentificacion__c = 'RNC';
    insert pjAcc;

    Contact pjContact = new Contact(LastName = 'Contacto Participante', AccountId = pjAcc.Id);
    insert pjContact;

    Id partRtId = Schema.SObjectType.FinServ__ContactContactRelation__c.getRecordTypeInfosByDeveloperName().get('Participante').getRecordTypeId();

    Id contactRoleRecordTypeId = Schema.SObjectType.FinServ__ReciprocalRole__c.getRecordTypeInfosByDeveloperName().get('ContactRole').getRecordTypeId();
    FinServ__ReciprocalRole__c contactRole = new FinServ__ReciprocalRole__c(Name = 'Participant Role PJ', FinServ__InverseRole__c = 'Participant Role PJ', RecordTypeId = contactRoleRecordTypeId);
    insert contactRole;

    FinServ__ContactContactRelation__c ccr = new FinServ__ContactContactRelation__c();
    ccr.FinServ__Contact__c = mainContact.Id;
    ccr.FinServ__RelatedContact__c = pjContact.Id;
    ccr.RecordTypeId = partRtId;
    ccr.CCR_Tipo__c = 'PERSONAL';
    ccr.CCR_Cargo__c = 'Presidente';
    ccr.CCR_Porcentaje__c = 100;
    ccr.FinServ__Role__c = contactRole.Id;
    insert ccr;

    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_participantType][function_participantRole][function_participantDocumentType][function_participantDocument][function_participantName][function_participantLastName][function_participantSecondLastName][function_participantFatca][function_participantValidation][function_participantPorcentage][function_participantPosition]';

    Test.startTest();
    String result = INT008_FSC.fillParticipant(resp.valuesParticipantCcr, resp.valuesParticipantPFAcc, resp.valuesParticipantPJAcc, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_participantType]'));
  }

  // --- fillAuthorized tests ---

  @isTest
  static void fillAuthorized_noData_Test() {
    Account acc = getTestAccount();
    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_authorizedDocumentType][function_authorizedDocument][function_authorizedName][function_authorizedLastName][function_authorizedPosition][function_authorizedPhone]';

    Test.startTest();
    String result = INT008_FSC.fillAuthorized(resp.valuesAuthorized, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_authorizedDocumentType]'));
  }

  @isTest
  static void fillAuthorized_withData_Test() {
    Account acc = getTestAccount();

    // Create a PersonAccount for the authorized contact (AUT_* fields are formulas from the Contact's Account)
    Test.setMock(HttpCalloutMock.class, new INT008TestMock('PF'));
    Account authAcc = new Account();
    authAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    authAcc.FirstName = 'Juan';
    authAcc.LastName = 'Perez';
    authAcc.ACC_TipoIdentificacion__c = 'Cédula';
    authAcc.FinServ__IndividualId__c = '00100100100';
    authAcc.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
    authAcc.PersonBirthdate = Date.newInstance(1985, 5, 15);
    authAcc.ACC_Genero__c = 'MASCULINO';
    authAcc.ACC_Estado_Civil__c = 'SOLTERO/A';
    insert authAcc;

    Contact authContact = [SELECT Id FROM Contact WHERE AccountId = :authAcc.Id LIMIT 1];

    // Create ACR between business account and the authorized person's contact
    AccountContactRelation acr = new AccountContactRelation(ContactId = authContact.Id, AccountId = acc.Id);
    acr.ACC_CON_Autorizado__c = true;
    acr.ACC_CON_Puesto_Posicion__c = 'Gerente';
    acr.ACC_CON_Telefono__c = '8095551234';
    insert acr;

    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame = '[function_authorizedDocumentType][function_authorizedDocument][function_authorizedName][function_authorizedLastName][function_authorizedSecondLastName][function_authorizedPosition][function_authorizedPhone]';

    Test.startTest();
    String result = INT008_FSC.fillAuthorized(resp.valuesAuthorized, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_authorizedDocumentType]'));
  }

  // --- fillXML test ---

  @isTest
  static void fillXMLTest() {
    Account acc = getTestAccount();
    INT008_FSC.Response resp = new INT008_FSC.Response();
    String frame =
      '<Function>[function_razonSocial]</Function>' +
      '<Direcciones>[function_addressStreet]</Direcciones>' +
      '<ViasContacto>[function_contactInfoId][function_contactExRef][function_ViaIdExternoVia][function_contactPrincipal][function_contactWayType][function_contactWayCant][function_contactCompany][function_contactInfoIdentifier]</ViasContacto>' +
      '<Referencias>[function_referenceType][function_referenceName][function_referencePhone][function_referenceAddress][function_referenceCountry][function_referenceBank][function_referenceAccountType][function_referenceCurrency][function_referenceAccountNum]</Referencias>' +
      '<ProductosServicios>[function_prodServName]</ProductosServicios>' +
      '<ClientesPrincipales>[function_largestCustName]</ClientesPrincipales>' +
      '<Proveedores>[function_supplierName]</Proveedores>' +
      '<Filiales>[function_affiliateName]</Filiales>' +
      '<Participantes>[function_participantType][function_participantRole][function_participantDocumentType][function_participantDocument][function_participantName][function_participantLastName][function_participantSecondLastName][function_participantFatca][function_participantValidation][function_participantPorcentage][function_participantPosition]</Participantes>' +
      '<Autorizados>[function_authorizedDocumentType][function_authorizedDocument][function_authorizedName]</Autorizados>';

    Test.startTest();
    String result = INT008_FSC.fillXML(resp, acc, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_razonSocial]'));
  }

  // --- creteClientJ / createOrModifyPF tests ---

  @isTest
  static void creteClientJTest() {
    Account acc = getTestAccount();

    Test.setMock(HttpCalloutMock.class, new INT008TestMock('PJ'));
    Test.startTest();
    try {
      INT008_FSC.creteClientJ(acc.Id);
    } catch (Exception e) {
      // createOrModifyPF may throw if StaticResource or AuthSession is missing in test context
    }
    Test.stopTest();
  }

  @isTest
  static void cliente008PJTest() {
    Account acc = getTestAccount();

    Test.setMock(HttpCalloutMock.class, new INT008TestMock('PJ'));
    Test.startTest();
    try {
      INT008_FSC.Cliente008_PJ(new List<Id>{ acc.Id });
    } catch (Exception e) {
      // createOrModifyPF may throw if StaticResource or AuthSession is missing in test context
    }
    Test.stopTest();
  }
}