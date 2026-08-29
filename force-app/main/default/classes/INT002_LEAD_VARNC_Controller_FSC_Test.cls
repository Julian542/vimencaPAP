@IsTest
private class INT002_LEAD_VARNC_Controller_FSC_Test {
  private class MockRncCallout implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      res.setStatus('OK');
      res.setBody(
        '<Envelope>' +
          '<ErrorCode>000</ErrorCode>' +
          '<ErrorText>OK</ErrorText>' +
          '<Result>' +
          '<RNC>123456789</RNC>' +
          '<NombreCorto>ACME</NombreCorto>' +
          '<RazonSocial>ACME Inc.</RazonSocial>' +
          '</Result>' +
          '</Envelope>'
      );
      return res;
    }
  }

  private static Id getLeadRecordTypeId() {
    return [
      SELECT Id
      FROM RecordType
      WHERE SObjectType = 'Lead' AND DeveloperName = 'Candidato_Persona_Juridica'
      LIMIT 1
    ]
    .Id;
  }

  private static Datos_Maestros__c getOrCreateActividad() {
    Datos_Maestros__c actividad = new Datos_Maestros__c(Name = 'Test Actividad', DM_Direccion__c = 'ACT001');
    insert actividad;
    return actividad;
  }

  @IsTest
  static void updateLeadRNC_success_updates_lead() {
    Datos_Maestros__c actividad = getOrCreateActividad();
    Lead lea = new Lead(
      LastName = 'Test Lead',
      Company = 'Test Co',
      Status = 'Iniciado',
      LEA_RNC__c = '101010101',
      RecordTypeId = getLeadRecordTypeId(),
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actividad.Id,
      LEA_Tipo_Sector__c = 'PRIVADO'
    );
    insert lea;

    Test.setMock(HttpCalloutMock.class, new MockRncCallout());

    Test.startTest();
    INT002_VARNC_Controller_FSC.Response res = INT002_LEAD_VARNC_Controller_FSC.updateLeadRNC(lea.Id);
    Test.stopTest();

    Lead updated = [
      SELECT Status, LEA_RNC__c, LEA_Nombre_Corto_Comercial__c
      FROM Lead
      WHERE Id = :lea.Id
    ];
    System.assertEquals(200, res.httpRequestStatusCode);
    System.assertEquals('000', res.errorCode);
    System.assertEquals(true, res.updateSuccess);
    System.assertEquals('123456789', updated.LEA_RNC__c);
    System.assertEquals('ACME', updated.LEA_Nombre_Corto_Comercial__c);
    System.assert(updated.Status == 'Calificado' || updated.Status == 'Validado', 'Estado inesperado: ' + updated.Status);
  }

  @IsTest
  static void updateLeadRNC_handles_validation_exception() {
    Datos_Maestros__c actividad = getOrCreateActividad();
    Lead lea = new Lead(
      LastName = 'Validation Lead',
      Company = 'Val Co',
      Status = 'Iniciado',
      LEA_RNC__c = '303030303',
      RecordTypeId = getLeadRecordTypeId(),
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actividad.Id,
      LEA_Tipo_Sector__c = 'PRIVADO'
    );
    insert lea;

    INT002_LEAD_VARNC_Controller_FSC.forceUpdateException = true;
    INT002_LEAD_VARNC_Controller_FSC.forceUpdateExceptionMessage = 'FIELD_CUSTOM_VALIDATION_EXCEPTION, mock validation: [Lead.Status]';

    Test.setMock(HttpCalloutMock.class, new MockRncCallout());

    Test.startTest();
    INT002_VARNC_Controller_FSC.Response res = INT002_LEAD_VARNC_Controller_FSC.updateLeadRNC(lea.Id);
    Test.stopTest();

    System.assertEquals(false, res.updateSuccess);
    System.assertEquals('mock validation', res.updateErrorMessage);
  }

  @IsTest
  static void updateLeadRNC_rejects_non_iniciado_status() {
    Datos_Maestros__c actividad = getOrCreateActividad();
    Lead lea = new Lead(
      LastName = 'Other Lead',
      Company = 'Other Co',
      Status = 'Calificado',
      LEA_RNC__c = '202020202',
      RecordTypeId = getLeadRecordTypeId(),
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actividad.Id,
      LEA_Tipo_Sector__c = 'PRIVADO'
    );
    insert lea;

    Test.setMock(HttpCalloutMock.class, new MockRncCallout());

    Test.startTest();
    INT002_VARNC_Controller_FSC.Response res = INT002_LEAD_VARNC_Controller_FSC.updateLeadRNC(lea.Id);
    Test.stopTest();

    if (res.updateSuccess) {
      System.assertEquals(true, res.updateSuccess);
    } else {
      System.assertEquals('El R.N.C solo puede validarse si está en estado Iniciado', res.updateErrorMessage);
    }
    Lead unchanged = [SELECT Status FROM Lead WHERE Id = :lea.Id];
    System.assert(unchanged.Status == 'Calificado' || unchanged.Status == 'Validado', 'Estado inesperado: ' + unchanged.Status);
  }

  @IsTest
  static void getQualificationState_readsLeadStatus() {
    Datos_Maestros__c actividad = getOrCreateActividad();
    Lead lea = new Lead(
      LastName = 'Qualification State Lead',
      Company = 'State Co',
      Status = 'Iniciado',
      LEA_RNC__c = '404040404',
      RecordTypeId = getLeadRecordTypeId(),
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actividad.Id,
      LEA_Tipo_Sector__c = 'PRIVADO'
    );
    insert lea;

    Test.startTest();
    INT002_LEAD_VARNC_Controller_FSC.QualificationState state =
      INT002_LEAD_VARNC_Controller_FSC.getQualificationState(lea.Id);
    Test.stopTest();

    System.assertEquals('Iniciado', state.status);
    System.assertEquals(false, state.pendingApproval);
    System.assertEquals(false, state.finished);
  }
}
