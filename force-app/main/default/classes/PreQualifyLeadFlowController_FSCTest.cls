@isTest(SeeAllData=true)
private class PreQualifyLeadFlowController_FSCTest {
  // Mock de callout para PreQualify
  private class PrequalifyMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      res.setBody('{"status":"OK","data":{"id":"1","message":"BAJO"}}');
      res.setHeader('Content-Type', 'application/json');
      return res;
    }
  }

  private static Id getLeadRecordTypeId(String developerName) {
    for (RecordType rt : [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = :developerName LIMIT 1]) {
      return rt.Id;
    }
    return null;
  }

  @isTest
  static void prequalify_personaNatural_returnsRating() {
    Id rtId = getLeadRecordTypeId('Candidato_Persona_Natural');
    System.assertNotEquals(null, rtId, 'Debe existir el RT Candidato_Persona_Natural en la org de pruebas');

    Lead lead = new Lead(LastName = 'Tester', Company = 'ACME', RecordTypeId = rtId, LEA_NumIdentificacion__c = '1234567890', LEA_TipoIdentificacion__c = 'Cédula');
    insert lead;

    PreQualifyLeadFlowController_FSC.FlowInputs input = new PreQualifyLeadFlowController_FSC.FlowInputs();
    input.lead = lead;
    input.accionista = null;
    input.representante = null;

    Test.setMock(HttpCalloutMock.class, new PrequalifyMock());

    Test.startTest();
    List<PreQualifyLeadFlowController_FSC.FlowOutputs> results = PreQualifyLeadFlowController_FSC.prequalify(new List<PreQualifyLeadFlowController_FSC.FlowInputs>{ input });
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Debe devolver una respuesta');
    System.assertEquals(lead.Id, results[0].leadId, 'Debe devolver el Id del lead procesado');
    System.assertEquals('BAJO', results[0].clientRating, 'Debe mapear el rating retornado por el servicio');
  }
}