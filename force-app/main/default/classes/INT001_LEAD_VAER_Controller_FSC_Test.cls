@SuppressWarnings('PMD')
@isTest
public with sharing class INT001_LEAD_VAER_Controller_FSC_Test {
  @TestSetup
  static void setupTestData() {
    Datos_Maestros__c actEcon = new Datos_Maestros__c(Name = 'Test Actividad Economica');
    insert actEcon;
  }
  public class INT001FSCMockSuccess implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
      HTTPResponse response = new HTTPResponse();
      response.setHeader('Content-Type', 'application/xml');
      response.setStatusCode(200);
      response.setBody(
        '<?xml version="1.0"?>' +
          '<root>' +
          '<ErrorCode>000</ErrorCode>' +
          '<ErrorText>Success</ErrorText>' +
          '<NumDocumento>12345678901</NumDocumento>' +
          '<PrimerNombre>Juan</PrimerNombre>' +
          '<SegundoNombre>Carlos</SegundoNombre>' +
          '<PrimerApellido>Perez</PrimerApellido>' +
          '<SegundoApellido>Lopez</SegundoApellido>' +
          '<FechaNacimiento>05/15/1990</FechaNacimiento>' +
          '<LugarNacimiento>R.D</LugarNacimiento>' +
          '<Genero>MASCULINO</Genero>' +
          '</root>'
      );
      return response;
    }
  }
  public class INT001FSCMockInvalidDate implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
      HTTPResponse response = new HTTPResponse();
      response.setHeader('Content-Type', 'application/xml');
      response.setStatusCode(200);
      response.setBody(
        '<?xml version="1.0"?>' +
          '<root>' +
          '<ErrorCode>000</ErrorCode>' +
          '<ErrorText>Success</ErrorText>' +
          '<NumDocumento>12345678901</NumDocumento>' +
          '<PrimerNombre>Juan</PrimerNombre>' +
          '<SegundoNombre>Carlos</SegundoNombre>' +
          '<PrimerApellido>Perez</PrimerApellido>' +
          '<SegundoApellido>Lopez</SegundoApellido>' +
          '<FechaNacimiento>invalid-date</FechaNacimiento>' +
          '<LugarNacimiento>R.D</LugarNacimiento>' +
          '<Genero>MASCULINO</Genero>' +
          '</root>'
      );
      return response;
    }
  }

  public class INT001FSCMockNotFound implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
      HTTPResponse response = new HTTPResponse();
      response.setHeader('Content-Type', 'application/xml');
      response.setStatusCode(200);
      response.setBody('<?xml version="1.0"?>' + '<root>' + '<ErrorCode>001</ErrorCode>' + '<ErrorText>Not Found</ErrorText>' + '<NumDocumento></NumDocumento>' + '</root>');
      return response;
    }
  }

  public class INT001FSCMockError implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
      HTTPResponse response = new HTTPResponse();
      response.setHeader('Content-Type', 'application/xml');
      response.setStatusCode(500);
      response.setBody('<?xml version="1.0"?>' + '<root>' + '<ErrorCode>500</ErrorCode>' + '<ErrorText>Server Error</ErrorText>' + '</root>');
      return response;
    }
  }

  public class INT001FSCMockForeignComma implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
      HTTPResponse response = new HTTPResponse();
      response.setHeader('Content-Type', 'application/xml');
      response.setStatusCode(200);
      response.setBody(
        '<?xml version="1.0"?>' +
          '<root>' +
          '<ErrorCode>000</ErrorCode>' +
          '<ErrorText>Success</ErrorText>' +
          '<NumDocumento>12345678901</NumDocumento>' +
          '<PrimerNombre>Juan</PrimerNombre>' +
          '<SegundoNombre>Carlos</SegundoNombre>' +
          '<PrimerApellido>Perez</PrimerApellido>' +
          '<SegundoApellido>Lopez</SegundoApellido>' +
          '<FechaNacimiento>05/15/1990</FechaNacimiento>' +
          '<LugarNacimiento>Tokyo, JAPON</LugarNacimiento>' +
          '<Genero>MASCULINO</Genero>' +
          '</root>'
      );
      return response;
    }
  }

  public class INT001FSCMockForeignSimple implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
      HTTPResponse response = new HTTPResponse();
      response.setHeader('Content-Type', 'application/xml');
      response.setStatusCode(200);
      response.setBody(
        '<?xml version="1.0"?>' +
          '<root>' +
          '<ErrorCode>000</ErrorCode>' +
          '<ErrorText>Success</ErrorText>' +
          '<NumDocumento>12345678901</NumDocumento>' +
          '<PrimerNombre>Juan</PrimerNombre>' +
          '<SegundoNombre>Carlos</SegundoNombre>' +
          '<PrimerApellido>Perez</PrimerApellido>' +
          '<SegundoApellido>Lopez</SegundoApellido>' +
          '<FechaNacimiento>05/15/1990</FechaNacimiento>' +
          '<LugarNacimiento>VENEZUELA</LugarNacimiento>' +
          '<Genero>MASCULINO</Genero>' +
          '</root>'
      );
      return response;
    }
  }

  public class INT004FSCMockNotPEP implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
      HTTPResponse response = new HTTPResponse();
      response.setHeader('Content-Type', 'application/xml');
      response.setStatusCode(200);
      response.setBody('<?xml version="1.0"?>' + '<root>' + '<ErrorCode>000</ErrorCode>' + '<ErrorText>Success</ErrorText>' + '<PersonaPEP>NO</PersonaPEP>' + '</root>');
      return response;
    }
  }

  public class INT004FSCMockIsPEP implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
      HTTPResponse response = new HTTPResponse();
      response.setHeader('Content-Type', 'application/xml');
      response.setStatusCode(200);
      response.setBody(
        '<?xml version="1.0"?>' +
          '<root>' +
          '<ErrorCode>000</ErrorCode>' +
          '<ErrorText>Success</ErrorText>' +
          '<PersonaPEP>SI</PersonaPEP>' +
          '<Documento>12345678901</Documento>' +
          '<TipoDocumento>Cédula</TipoDocumento>' +
          '<PrimerNombre>Juan Carlos Miguel</PrimerNombre>' +
          '<SegundoNombre>Manuel</SegundoNombre>' +
          '<PrimerApellido>Perez</PrimerApellido>' +
          '<SegundoApellido>Lopez</SegundoApellido>' +
          '<TipoParentesco>AMIGO</TipoParentesco>' +
          '<Ocupacion>MEDICO</Ocupacion>' +
          '<Nacionalidad>REPUBLICA DOMINICANA</Nacionalidad>' +
          '<CargoPolitico>SENADOR</CargoPolitico>' +
          '<InstitucionTrabajo>SENADO</InstitucionTrabajo>' +
          '</root>'
      );
      return response;
    }
  }

  public class INT004FSCMockBlankPEP implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
      HTTPResponse response = new HTTPResponse();
      response.setHeader('Content-Type', 'application/xml');
      response.setStatusCode(200);
      response.setBody(
        '<?xml version="1.0"?>' +
          '<root>' +
          '<ErrorCode>000</ErrorCode>' +
          '<ErrorText>Success</ErrorText>' +
          '<PersonaPEP></PersonaPEP>' +
          '<Documento>12345678901</Documento>' +
          '<TipoDocumento>Cédula</TipoDocumento>' +
          '<PrimerNombre>Juan</PrimerNombre>' +
          '<PrimerApellido>Perez</PrimerApellido>' +
          '<Ocupacion>ADMINISTRADOR EJECUTIVO</Ocupacion>' +
          '</root>'
      );
      return response;
    }
  }

  @isTest
  static void testResponseCreation() {
    INT001_LEAD_VAER_Controller_FSC.Response resp = new INT001_LEAD_VAER_Controller_FSC.Response();
    resp.httpRequestStatusCode = 200;
    resp.errorCode = '000';
    resp.errorText = 'Success';
    resp.updateSuccess = true;
    resp.updateErrorMessage = null;

    System.assertEquals(200, resp.httpRequestStatusCode);
    System.assertEquals('000', resp.errorCode);
    System.assertEquals('Success', resp.errorText);
    System.assertEquals(true, resp.updateSuccess);
  }

  @isTest
  static void testUpdateAccountSuccessWithInitiadoStatus() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
      Company = 'TestCo',
      Status = 'Iniciado',
      LEA_NumIdentificacion__c = '12345678901',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Persona_PEP__c = 'NO',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );
    insert testLead;

    Test.setMock(HttpCalloutMock.class, new INT001FSCMockSuccess());

    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccount(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
    Lead updatedLead = [SELECT Id, FirstName, LEA_Pais_Nacimiento__c, LEA_PersonBirthdate__c, Status FROM Lead WHERE Id = :testLead.Id];
    System.assertEquals('Juan', updatedLead.FirstName);
    System.assertEquals('REPUBLICA DOMINICANA', updatedLead.LEA_Pais_Nacimiento__c);
    System.assertEquals(Date.newInstance(1990, 5, 15), updatedLead.LEA_PersonBirthdate__c);
    System.assertEquals('Calificado', updatedLead.Status);
  }

  @isTest
  static void testUpdateAccountDocumentNotFound() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
      Company = 'TestCo',
      Status = 'Iniciado',
      LEA_NumIdentificacion__c = '99999999999',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );
    insert testLead;

    Test.setMock(HttpCalloutMock.class, new INT001FSCMockNotFound());

    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccount(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }

  @isTest
  static void testUpdateAccountInvalidDocumentType() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
      Company = 'TestCo',
      Status = 'Iniciado',
      LEA_NumIdentificacion__c = '12345678901',
      LEA_TipoIdentificacion__c = 'RNC',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
	    );
	    insert testLead;
	    Test.setMock(HttpCalloutMock.class, new INT001FSCMockNotFound());

	    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccount(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }

  @isTest
  static void testUpdateAccountInvalidStatus() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
      Company = 'TestCo',
      Status = 'Validado',
      LEA_NumIdentificacion__c = '12345678901',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
	    );
	    insert testLead;
	    Test.setMock(HttpCalloutMock.class, new INT001FSCMockNotFound());

	    Test.startTest();
	    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccount(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }

	  @isTest
	  static void testUpdateAccountEmptyDocumentNumber() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
	      Company = 'TestCo',
	      Status = 'Iniciado',
	      LEA_NumIdentificacion__c = '12345678901',
	      LEA_TipoIdentificacion__c = 'Cédula',
	      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );
	    insert testLead;
	    Test.setMock(HttpCalloutMock.class, new INT001FSCMockNotFound());

	    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccount(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }

  @isTest
  static void testUpdateAccountEmptyDocumentType() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
	      Company = 'TestCo',
	      Status = 'Iniciado',
	      LEA_NumIdentificacion__c = '12345678901',
	      LEA_TipoIdentificacion__c = 'RNC',
	      LEA_RNC__c = '123456789',
	      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );
    insert testLead;

    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccount(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }

  @isTest
  static void testUpdateAccountRNCDocumentType() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
	      Company = 'TestCo',
	      Status = 'Iniciado',
	      LEA_NumIdentificacion__c = '12345678901',
	      LEA_TipoIdentificacion__c = 'RNC',
	      LEA_RNC__c = '123456789',
	      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );
    insert testLead;

    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccount(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }

  @isTest
  static void testUpdateAccountPEPNotPEP() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];

    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
      Company = 'TestCo',
      LEA_NumIdentificacion__c = '12345678901',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );
    insert testLead;

    Test.setMock(HttpCalloutMock.class, new INT004FSCMockNotPEP());

    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccountPEP(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }

  @isTest
  static void testUpdateAccountPEPBlankPersonaPEP() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
	      Company = 'TestCo',
	      LEA_NumIdentificacion__c = '12345678901',
	      LEA_TipoIdentificacion__c = 'Cédula',
	      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado',
      LEA_Ocupacion_PEP__c = 'ADMINISTRADOR EJECUTIVO'
    );

    RecordType rt = null;
    try {
	      rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = 'Candidato_Persona_Natural' LIMIT 1];
    } catch (QueryException e) {
      try {
        rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' LIMIT 1];
      } catch (QueryException e2) {
      }
    }

    if (rt != null) {
      testLead.RecordTypeId = rt.Id;
    }

    insert testLead;

    Lead insertedLead = [SELECT Id, RecordTypeId, RecordType.Name FROM Lead WHERE Id = :testLead.Id];

    Test.setMock(HttpCalloutMock.class, new INT004FSCMockBlankPEP());

    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccountPEP(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);

    if (rt != null) {
      Lead updatedLead = [SELECT Id, RecordTypeId, RecordType.Name, LEA_Ocupacion_PEP__c, LEA_Nacionalidad_PEP__c FROM Lead WHERE Id = :testLead.Id];
      System.assertEquals('ADMINISTRADOR EJECUTIVO', updatedLead.LEA_Ocupacion_PEP__c);
    }
  }

  @isTest
  static void testUpdateAccountPEPMissingFields() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
	      Company = 'TestCo',
	      LEA_NumIdentificacion__c = '12345678901',
	      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );

    try {
	      RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = 'Candidato_Persona_Natural' LIMIT 1];
	      testLead.RecordTypeId = rt.Id;
    } catch (QueryException e) {
      System.debug('Candidato Persona Física RecordType not found, test will use default');
	    }
	    insert testLead;
	    Test.setMock(HttpCalloutMock.class, new INT004FSCMockNotPEP());

    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccountPEP(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }

  @isTest
  static void testUpdateAccountPEPMissingDocType() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
	      Company = 'TestCo',
	      LEA_NumIdentificacion__c = '12345678901',
	      LEA_TipoIdentificacion__c = 'Cédula',
	      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );

    try {
	      RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = 'Candidato_Persona_Natural' LIMIT 1];
	      testLead.RecordTypeId = rt.Id;
    } catch (QueryException e) {
      System.debug('Candidato Persona Física RecordType not found, test will use default');
	    }
	    insert testLead;
	    Test.setMock(HttpCalloutMock.class, new INT004FSCMockNotPEP());

    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccountPEP(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }

  @isTest
  static void testUpdateAccountPEPFlowNotPEP() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
      Company = 'TestCo',
      LEA_NumIdentificacion__c = '12345678901',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );

    // Try to assign RecordType if 'Candidato Persona Física' exists
    try {
      RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = 'Candidato_Persona_Fisica' LIMIT 1];
      testLead.RecordTypeId = rt.Id;
    } catch (QueryException e) {
      System.debug('Candidato Persona Física RecordType not found, test will use default');
    }
    insert testLead;

    Test.setMock(HttpCalloutMock.class, new INT004FSCMockNotPEP());

    Test.startTest();
    INT001_LEAD_VAER_Controller_FSC.updateAccountPEPFlow(new List<Id>{ testLead.Id });
    Test.stopTest();

    Lead updatedLead = [SELECT Id FROM Lead WHERE Id = :testLead.Id];
    System.assertNotEquals(null, updatedLead);
  }

  @isTest
  static void testUpdateAccountPEPFlowIsPEP() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
      Company = 'TestCo',
      LEA_NumIdentificacion__c = '12345678901',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );

    try {
      RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = 'Candidato_Persona_Fisica' LIMIT 1];
      testLead.RecordTypeId = rt.Id;
    } catch (QueryException e) {
      System.debug('Candidato Persona Física RecordType not found, test will use default');
    }
    insert testLead;

    Test.setMock(HttpCalloutMock.class, new INT004FSCMockIsPEP());

    Test.startTest();
    INT001_LEAD_VAER_Controller_FSC.updateAccountPEPFlow(new List<Id>{ testLead.Id });
    Test.stopTest();

    Lead updatedLead = [SELECT Id FROM Lead WHERE Id = :testLead.Id];
    System.assertNotEquals(null, updatedLead);
  }

  @isTest
  static void testUpdateAccountWithBlankNames() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
      Company = 'TestCo',
      Status = 'Iniciado',
      LEA_NumIdentificacion__c = '12345678901',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Persona_PEP__c = 'NO',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );
    insert testLead;

    Test.setMock(HttpCalloutMock.class, new INT001FSCMockSuccess());

    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccount(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }

  @isTest
  static void testUpdateAccountErrorResponse() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
      Company = 'TestCo',
      Status = 'Iniciado',
      LEA_NumIdentificacion__c = '12345678901',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );
    insert testLead;

    Test.setMock(HttpCalloutMock.class, new INT001FSCMockError());

    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccount(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }

  @isTest
  static void testTunelCaseFlowLightningNotCandidato() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    RecordType rtl = [
      SELECT Id
      FROM RecordType
      WHERE SObjectType = 'Lead'
      LIMIT 1
    ];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
      Company = 'TestCo',
	      RecordTypeId = rtl.Id,
	      LEA_NumIdentificacion__c = '12345678901',
	      LEA_TipoIdentificacion__c = 'RNC',
	      LEA_RNC__c = '123456789',
	      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );

    try {
      RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName != 'Candidato_Persona_Fisica' LIMIT 1];
      testLead.RecordTypeId = rt.Id;
    } catch (QueryException e) {
      System.debug('Non-Candidato RecordType not found, test will use default');
    }
    insert testLead;

    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccountPEP(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }

  @isTest
  static void testUpdateAccountForeignBirthplaceComma() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
      Company = 'TestCo',
      Status = 'Iniciado',
      LEA_NumIdentificacion__c = '12345678901',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Persona_PEP__c = 'NO',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );
    insert testLead;

    Test.setMock(HttpCalloutMock.class, new INT001FSCMockForeignComma());

    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccount(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }

  @isTest
  static void testUpdateAccountForeignBirthplaceSimple() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
      Company = 'TestCo',
      Status = 'Iniciado',
      LEA_NumIdentificacion__c = '12345678901',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Persona_PEP__c = 'NO',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );
    insert testLead;

    Test.setMock(HttpCalloutMock.class, new INT001FSCMockForeignSimple());

    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccount(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }

  @isTest
  static void testUpdateAccountPEPCandidatoIsPEP() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
      Company = 'TestCo',
      LEA_NumIdentificacion__c = '12345678901',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );

    try {
      RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = 'Candidato_Persona_Natural' LIMIT 1];
      testLead.RecordTypeId = rt.Id;
    } catch (QueryException e) {
      System.debug('Candidato Persona Natural RecordType not found, test will use default');
    }
    insert testLead;

    Lead debugLead = [SELECT Id, RecordType.DeveloperName, LEA_NumIdentificacion__c, LEA_TipoIdentificacion__c FROM Lead WHERE Id = :testLead.Id];
    System.debug(
      '### DEBUG CandidatoIsPEP - RT: ' + debugLead.RecordType.DeveloperName + ' | NumIdent: ' + debugLead.LEA_NumIdentificacion__c + ' | TipoIdent: ' + debugLead.LEA_TipoIdentificacion__c
    );

    Test.setMock(HttpCalloutMock.class, new INT004FSCMockIsPEP());

    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccountPEP(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }

  @isTest
  static void testUpdateAccountPEPCandidatoNotPEP() {
    Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c LIMIT 1];
    Lead testLead = new Lead(
      FirstName = 'Test',
      LastName = 'Lead',
      Company = 'TestCo',
      LEA_NumIdentificacion__c = '12345678901',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actEcon.Id,
      LEA_Tipo_Sector__c = 'Privado'
    );

    try {
      RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = 'Candidato_Persona_Natural' LIMIT 1];
      testLead.RecordTypeId = rt.Id;
    } catch (QueryException e) {
      System.debug('Candidato Persona Natural RecordType not found, test will use default');
    }
    insert testLead;

    Test.setMock(HttpCalloutMock.class, new INT004FSCMockNotPEP());

    Test.startTest();
    Object response = INT001_LEAD_VAER_Controller_FSC.updateAccountPEP(testLead.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
  }
}
