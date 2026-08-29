@isTest(SeeAllData=true)
private class ValidatePreQualifyFlowController_FSCTest {
  private static Boolean bypassCreated = false;

  private static void ensureBypass() {
    if (!bypassCreated) {
      try {
        insert new Bypass_Trigger__c(Name = 'Bypass ' + System.now().getTime(), Usernames_Allowed__c = UserInfo.getUserName());
      } catch (DmlException ex) {
        System.assertEquals(true, ex.getMessage().contains('DUPLICATE_VALUE'), ex.getMessage());
      }
      bypassCreated = true;
    }
  }

  private static Lead createLead(Id recordTypeId) {
    String developerName = [SELECT DeveloperName FROM RecordType WHERE Id = :recordTypeId LIMIT 1].DeveloperName;
    Boolean isJuridica = developerName == 'Candidato_Persona_Juridica';
    Datos_Maestros__c actividad = new Datos_Maestros__c(Name = 'Test Actividad PreQ ' + System.now().getTime(), DM_Direccion__c = 'PQ001');
    insert actividad;

    Lead l = new Lead(
      FirstName = isJuridica ? null : 'Test',
      LastName = 'Tester',
      Company = 'ACME',
      Status = 'Nuevo',
      RecordTypeId = recordTypeId,
      LEA_TipoIdentificacion__c = isJuridica ? 'RNC' : 'Cédula',
      LEA_NumIdentificacion__c = isJuridica ? null : '00100058007',
      LEA_RNC__c = isJuridica ? String.valueOf(Math.abs(Crypto.getRandomInteger())).leftPad(9, '0').substring(0, 9) : null,
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actividad.Id,
      LEA_Tipo_Sector__c = 'PRIVADO'
    );
    insert l;
    l.LEA_TipoIdentificacion__c = null;
    l.LEA_NumIdentificacion__c = null;
    l.LEA_RNC__c = null;
    l.LEA_Nombre_Corto_Comercial__c = null;
    return l;
  }

  @isTest
  static void validatePersonaNatural_missingFields() {
    Id rtId = getLeadRecordTypeId('Candidato_Persona_Natural');
    System.assertNotEquals(null, rtId, 'Se requiere un RecordType Candidato_Persona_Natural configurado en la org de pruebas');

    Lead leadNatural = createLead(rtId);

    ValidatePreQualifyFlowController_FSC.FlowInputs input = new ValidatePreQualifyFlowController_FSC.FlowInputs();
    input.lead = leadNatural;
    input.accionista = new Participante__c();
    input.representante = new Participante__c();

    Test.startTest();
    List<ValidatePreQualifyFlowController_FSC.FlowValidateOutputs> result = ValidatePreQualifyFlowController_FSC.validatePrequalify(new List<ValidatePreQualifyFlowController_FSC.FlowInputs>{input});
    Test.stopTest();

    System.assertEquals(1, result.size(), 'Debe devolver una sola respuesta');
    System.assertEquals(false, result[0].ok, 'Debe marcarse como inválido por campos faltantes');
    System.assert(result[0].invalidField.contains('Tipo de Ident'), 'Debe listar campos faltantes de identificación');
  }

  @isTest
  static void validatePersonaJuridica_missingFields() {
    Id rtId = getLeadRecordTypeId('Candidato_Persona_Juridica');
    System.assertNotEquals(null, rtId, 'Se requiere un RecordType Candidato_Persona_Juridica configurado en la org de pruebas');

    Lead leadJuridica = createLead(rtId);

    ValidatePreQualifyFlowController_FSC.FlowInputs input = new ValidatePreQualifyFlowController_FSC.FlowInputs();
    input.lead = leadJuridica;
    input.accionista = new Participante__c();
    input.representante = new Participante__c();

    Test.startTest();
    List<ValidatePreQualifyFlowController_FSC.FlowValidateOutputs> result = ValidatePreQualifyFlowController_FSC.validatePrequalify(new List<ValidatePreQualifyFlowController_FSC.FlowInputs>{input});
    Test.stopTest();

    System.assertEquals(1, result.size(), 'Debe devolver una sola respuesta');
    System.assertEquals(false, result[0].ok, 'Debe marcarse como inválido por campos faltantes');
    System.assert(result[0].invalidField.contains('Nombre Persona'), 'Debe listar campos faltantes de persona jurídica');
  }

  private static Id getLeadRecordTypeId(String developerName) {
    for (RecordType rt : [SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName = :developerName LIMIT 1]) {
      return rt.Id;
    }
    return null;
  }
}
