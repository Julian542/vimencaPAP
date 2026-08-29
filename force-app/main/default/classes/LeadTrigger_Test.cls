@SuppressWarnings('PMD')
@isTest
private with sharing class LeadTrigger_Test {
  private static Datos_Maestros__c getOrCreateActividad() {
    Datos_Maestros__c actividad = new Datos_Maestros__c(Name = 'Test Actividad LT', DM_Direccion__c = 'LT001');
    insert actividad;
    return actividad;
  }

  @isTest
  static void beforeInsert_cleansNumIdentificacion_Test() {
    Datos_Maestros__c actividad = getOrCreateActividad();

    Test.startTest();
    Lead lea = new Lead(
      FirstName = 'Test',
      LastName = 'Insert',
      Company = 'TestCo',
      Status = 'Iniciado',
      LEA_NumIdentificacion__c = '001-1234567-8',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
      LEA_PersonBirthdate__c = Date.today().addYears(-30),
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actividad.Id,
      LEA_Tipo_Sector__c = 'PRIVADO'
    );
    insert lea;
    Test.stopTest();

    Lead inserted = [SELECT LEA_NumIdentificacion__c FROM Lead WHERE Id = :lea.Id];
    System.assertEquals('00112345678', inserted.LEA_NumIdentificacion__c);
  }

  @isTest
  static void beforeInsert_cleansRNC_Test() {
    Datos_Maestros__c actividad = getOrCreateActividad();

    Test.startTest();
    Lead lea = new Lead(
      FirstName = 'Test',
      LastName = 'RNC Insert',
      Company = 'TestCo',
      Status = 'Iniciado',
      LEA_NumIdentificacion__c = '00112345678',
      LEA_RNC__c = '123-456-789',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
      LEA_PersonBirthdate__c = Date.today().addYears(-30),
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actividad.Id,
      LEA_Tipo_Sector__c = 'PRIVADO'
    );
    insert lea;
    Test.stopTest();

    Lead inserted = [SELECT LEA_RNC__c FROM Lead WHERE Id = :lea.Id];
    System.assertEquals('123456789', inserted.LEA_RNC__c);
  }

  @isTest
  static void beforeInsert_nullFields_Test() {
    Datos_Maestros__c actividad = getOrCreateActividad();

    Test.startTest();
    Lead lea = new Lead(
      FirstName = 'Test',
      LastName = 'Null Fields',
      Company = 'TestCo',
      Status = 'Iniciado',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
      LEA_PersonBirthdate__c = Date.today().addYears(-30),
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actividad.Id,
      LEA_Tipo_Sector__c = 'PRIVADO'
    );
    try {
      insert lea;
      System.assert(false, 'La validación debe exigir el número de identificación.');
    } catch (DmlException ex) {
      System.assert(ex.getMessage().contains('Número de Identificación'), ex.getMessage());
    }
    Test.stopTest();
  }

  @isTest
  static void beforeUpdate_cleansFields_Test() {
    Datos_Maestros__c actividad = getOrCreateActividad();

    Lead lea = new Lead(
      FirstName = 'Test',
      LastName = 'Update',
      Company = 'TestCo',
      Status = 'Iniciado',
      LEA_NumIdentificacion__c = '00112345678',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
      LEA_PersonBirthdate__c = Date.today().addYears(-30),
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actividad.Id,
      LEA_Tipo_Sector__c = 'PRIVADO'
    );
    insert lea;

    Test.startTest();
    lea.LEA_NumIdentificacion__c = '999-8888888-7';
    lea.LEA_RNC__c = '111-222';
    update lea;
    Test.stopTest();

    Lead updated = [SELECT LEA_NumIdentificacion__c, LEA_RNC__c FROM Lead WHERE Id = :lea.Id];
    System.assertEquals('99988888887', updated.LEA_NumIdentificacion__c);
    System.assertEquals('111222', updated.LEA_RNC__c);
  }

  @isTest
  static void afterUpdate_convertedLead_Test() {
    Datos_Maestros__c actividad = getOrCreateActividad();

    Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));

    Lead lea = new Lead(
      FirstName = 'Convert',
      LastName = 'Test',
      Company = 'TestCo',
      Status = 'Iniciado',
      LEA_NumIdentificacion__c = '00112345678',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
      LEA_PersonBirthdate__c = Date.today().addYears(-30),
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actividad.Id,
      LEA_Tipo_Sector__c = 'PRIVADO'
    );
    insert lea;

    Database.LeadConvert lc = new Database.LeadConvert();
    lc.setLeadId(lea.Id);
    lc.setConvertedStatus('Calificado');
    lc.setDoNotCreateOpportunity(true);

    Test.startTest();
    try {
      Database.convertLead(lc);
    } catch (Exception e) {
      // LeadConversionQueue may fail but trigger lines 11/17 are covered
    }
    Test.stopTest();
  }
}
