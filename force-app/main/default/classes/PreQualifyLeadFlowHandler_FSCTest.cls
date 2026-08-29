@isTest
private class PreQualifyLeadFlowHandler_FSCTest {
  private class PrequalifyMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      res.setHeader('Content-Type', 'application/json');
      res.setBody('{"status":"OK","data":{"id":"1","message":"BAJO"}}');
      return res;
    }
  }

  private class PrequalifyMockMedio implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      res.setHeader('Content-Type', 'application/json');
      res.setBody('{"status":"OK","data":{"id":"1","message":"MEDIO"}}');
      return res;
    }
  }

  private class PrequalifyMock500 implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(500);
      res.setHeader('Content-Type', 'application/json');
      res.setBody('{"status":"ERROR"}');
      return res;
    }
  }

  @isTest
  static void prequalify_pf_returnsRating() {
    Precalificar_Setting__mdt meta = new Precalificar_Setting__mdt();
    meta.Named_Credential__c = 'NamedCred_Precalificar';
    meta.Metodo__c = '/prequalify';
    meta.Sign__c = 'sig';
    meta.rtind__c = 'rt';
    meta.Event__c = 'evt';
    meta.User__c = 'usr';
    PreQualifyLeadFlowHandler_FSC.TEST_METADATA = meta;
    PreQualifyLeadFlowHandler_FSC.TEST_RATING = 'BAJO';

    Lead lead = new Lead(
      LastName = 'Tester',
      Company = 'ACME',
      LEA_NumIdentificacion__c = '1234567890',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_PersonBirthdate__c = Date.today().addYears(-20),
      LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
      LEA_Tipo_Persona_PF__c = 'P3'
    );
    insert lead;

    lead.RecordType = new RecordType(Name = 'Candidato Persona Natural');

    Test.setMock(HttpCalloutMock.class, new PrequalifyMock());

    PreQualifyFlowModel body = PreQualifyLeadFlowHandler_FSC.createBody(lead, null, null);

    Test.startTest();
    String rating = PreQualifyLeadFlowHandler_FSC.prequalifyClient(body);
    Test.stopTest();

    System.assertEquals('BAJO', rating, 'Debe devolver el rating en mayusculas');
    System.assertNotEquals(null, body, 'El body no debe ser nulo');
    System.assertNotEquals(null, body.Header, 'El body debe tener header');
  }

  @isTest
  static void prequalify_pf_callout_path_returnsNullOnNon200() {
    Precalificar_Setting__mdt meta = new Precalificar_Setting__mdt();
    meta.Named_Credential__c = 'NamedCred_Precalificar';
    meta.Metodo__c = '/prequalify';
    meta.Sign__c = 'sig';
    meta.rtind__c = 'rt';
    meta.Event__c = 'evt';
    meta.User__c = 'usr';
    PreQualifyLeadFlowHandler_FSC.TEST_METADATA = meta;
    PreQualifyLeadFlowHandler_FSC.TEST_RATING = null; // forzar ruta real de callout

    Lead lead = new Lead(LastName = 'Tester', Company = 'ACME', LEA_NumIdentificacion__c = '0000000000', LEA_TipoIdentificacion__c = 'Cédula', LEA_PersonBirthdate__c = Date.today().addYears(-30));
    insert lead;

    lead.RecordType = new RecordType(Name = 'Candidato Persona Natural');

    Test.setMock(HttpCalloutMock.class, new PrequalifyMock500());

    PreQualifyFlowModel body = PreQualifyLeadFlowHandler_FSC.createBody(lead, null, null);

    HttpResponse resp = new HttpResponse();
    resp.setStatusCode(500);
    resp.setHeader('Content-Type', 'application/json');
    resp.setBody('{"status":"ERROR"}');
    PreQualifyLeadFlowHandler_FSC.TEST_RESPONSE = resp;

    Test.startTest();
    String rating = PreQualifyLeadFlowHandler_FSC.prequalifyClient(body);
    Test.stopTest();

    System.assertEquals(null, rating, 'Debe retornar null cuando el status no es 200');
  }

  @isTest
  static void prequalify_pj_setsProductsServicesChannels() {
    Precalificar_Setting__mdt meta = new Precalificar_Setting__mdt();
    meta.Named_Credential__c = 'NamedCred_Precalificar';
    meta.Metodo__c = '/prequalify';
    meta.Sign__c = 'sig';
    meta.rtind__c = 'rt';
    meta.Event__c = 'evt';
    meta.User__c = 'usr';
    PreQualifyLeadFlowHandler_FSC.TEST_METADATA = meta;
    PreQualifyLeadFlowHandler_FSC.TEST_RATING = 'ALTO';

    Lead lead = new Lead(
      LastName = 'Empresa',
      Company = 'ACME Corp',
      LEA_RNC__c = '123456789',
      LEA_NumIdentificacion__c = '123456789',
      LEA_TipoIdentificacion__c = 'RNC',
      LEA_ProductosASolicitar__c = '4',
      LEA_Fecha_Fundacion__c = Date.today().addYears(-10),
      LEA_Servicios_a_solicitar__c = 'd;i',
      LEA_INT_Canales_a_utilizar__c = 'Internet Banking / APP'
    );
    insert lead;

    lead.RecordType = new RecordType(Name = 'Candidato Persona Juridica');

    Participante__c accionista = new Participante__c(PAR_Tipo__c = 'Contacto', PAR_Cargo__c = 'Accionista', PAR_Porcentaje__c = 50, PAR_Candidato__c = lead.Id);

    Participante__c representante = new Participante__c(PAR_Tipo__c = 'Contacto', PAR_Cargo__c = 'Representante legal', PAR_Candidato__c = lead.Id);

    Test.setMock(HttpCalloutMock.class, new PrequalifyMock());

    PreQualifyFlowModel body = PreQualifyLeadFlowHandler_FSC.createBody(lead, accionista, representante);

    Test.startTest();
    String rating = PreQualifyLeadFlowHandler_FSC.prequalifyClient(body);
    Test.stopTest();

    System.assertEquals('ALTO', rating, 'Debe devolver el rating mockeado');
    System.assertEquals('4', body.Fields.productCode01, 'Debe mapear el producto');
    System.assertEquals('d', body.Fields.serviceCode01, 'Debe mapear el primer servicio');
    System.assertEquals('Internet Banking / APP', body.Fields.channel01, 'Debe mapear el primer canal');
    System.assertEquals('1', body.Fields.productChosenCount, 'Debe contar productos');
  }
}
