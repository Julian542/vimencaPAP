@SuppressWarnings('PMD')
@isTest
private with sharing class INT003_LEAD_FSC_Test {
  @TestSetup
  static void setupData() {
    Datos_Maestros__c actividad = new Datos_Maestros__c(Name = 'Test Actividad', DM_Direccion__c = 'ACT001');
    insert actividad;

    Lead lea = new Lead(
	      FirstName = 'Test',
	      LastName = 'Lead',
	      Company = 'TestCo',
	      Status = 'Calificado',
      LEA_NumIdentificacion__c = '00112345678',
      LEA_TipoIdentificacion__c = 'Cédula',
      LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
      LEA_PersonBirthdate__c = Date.today().addYears(-30),
      LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
      LEA_Actividad_Economica__c = actividad.Id,
      LEA_Tipo_Sector__c = 'PRIVADO'
    );
    insert lea;

    Matriz_lista_control__c matriz = new Matriz_lista_control__c(
      MAT_Coincidencia_en_listas_externas__c = 'N',
      MAT_Coincidencia_en_listas__c = 'N',
      MAT_Resultado_validacion__c = 'Aprobado',
      MAT_Estado__c = 'Calificado',
      MAT_Sub_estado__c = 'Aceptado'
    );
    insert matriz;
  }

  private static Lead getTestLead() {
    List<String> fields = new List<String>(Lead.SObjectType.getDescribe().fields.getMap().keySet());
    String soql = 'SELECT ' + String.join(fields, ',') + ' FROM Lead WHERE LastName = \'Lead\' LIMIT 1';
    return Database.query(soql);
  }

  @isTest
  static void parseSuccessTest() {
    String responseBody =
      '<ErrorCode>000</ErrorCode>' +
      '<ErrorText>TRANSACCION PROCESADA</ErrorText>' +
      '<NumDocumento>00112345678</NumDocumento>' +
      '<TipoDocumento>Cedula</TipoDocumento>' +
      '<CoincidenciaLI>N</CoincidenciaLI>' +
      '<CoincidenciaLE>N</CoincidenciaLE>' +
      '<Listas>Lista1</Listas>';

    Test.startTest();
    INT003_LEAD_FSC.Response result = INT003_LEAD_FSC.parse(responseBody);
    Test.stopTest();

    System.assertEquals('000', result.errorCode);
    System.assertEquals('TRANSACCION PROCESADA', result.errorText);
    System.assertEquals('N', result.values.get('CoincidenciaLI'));
    System.assertEquals('N', result.values.get('CoincidenciaLE'));
    System.assertEquals('Lista1', result.values.get('Listas'));
  }

  @isTest
  static void parseErrorResponseTest() {
    String responseBody = '<ErrorCode>999</ErrorCode>' + '<ErrorText>ERROR</ErrorText>';

    Test.startTest();
    INT003_LEAD_FSC.Response result = INT003_LEAD_FSC.parse(responseBody);
    Test.stopTest();

    System.assertEquals('999', result.errorCode);
    System.assert(result.values.isEmpty());
  }

  @isTest
  static void updateAccountTest() {
    Lead lea = getTestLead();

    INT003_LEAD_FSC.Response responseData = new INT003_LEAD_FSC.Response();
    responseData.values.put('CoincidenciaLI', 'N');
    responseData.values.put('CoincidenciaLE', 'N');
    responseData.values.put('Listas', '');

    Test.startTest();
    INT003_LEAD_FSC.updateAccount(responseData, lea.Id);
    Test.stopTest();

    Lead updated = [SELECT Id, LEA_Resultado_Validacion__c, Status, LEA_SubEstado__c, LEA_Coincidencia_Listas_Externas__c, LEA_Coincidencia_Listas_Internas__c FROM Lead WHERE Id = :lea.Id];
    System.assertEquals('Aprobado', updated.LEA_Resultado_Validacion__c);
    System.assertEquals(false, updated.LEA_Coincidencia_Listas_Externas__c);
    System.assertEquals(false, updated.LEA_Coincidencia_Listas_Internas__c);
  }

  @isTest
  static void fillXMLTest() {
    Lead lea = getTestLead();

    INT003_LEAD_FSC.Response responseServer = new INT003_LEAD_FSC.Response();
    String frame = '<Function>[function_document][function_lastName]</Function>';

    Test.startTest();
    String result = INT003_LEAD_FSC.fillXML(responseServer, lea, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_document]'));
    System.assert(!result.contains('[function_lastName]'));
  }

  @isTest
  static void fillDetailClientTest() {
    Lead lea = getTestLead();

    INT003_LEAD_FSC.Response responseServer = new INT003_LEAD_FSC.Response();
    String frame = '[function_document][function_lastName]';

    Test.startTest();
    String result = INT003_LEAD_FSC.fillDetailClient(responseServer.valuesClient, lea, frame);
    Test.stopTest();

    System.assert(!result.contains('[function_lastName]'));
  }

  @isTest
  static void validatePFSuccessTest() {
    Lead lea = getTestLead();

    Test.setMock(HttpCalloutMock.class, new INT003_LEAD_FSC_TestMock('SUCCESS'));
    Test.startTest();
    INT003_LEAD_FSC.validatePF(lea.Id);
    Test.stopTest();

    System.assertNotEquals(null, INT003_LEAD_FSC.response);
    System.assertEquals(200, INT003_LEAD_FSC.response.requestStatusCode);
  }

  @isTest
  static void validatePFHttpErrorTest() {
    Lead lea = getTestLead();

    Test.setMock(HttpCalloutMock.class, new INT003_LEAD_FSC_TestMock('HTTP_ERROR'));
    Test.startTest();
    INT003_LEAD_FSC.validatePF(lea.Id);
    Test.stopTest();

    System.assertEquals(500, INT003_LEAD_FSC.response.requestStatusCode);
  }

  @isTest
  static void validatePFErrorCodeTest() {
    Lead lea = getTestLead();

    Test.setMock(HttpCalloutMock.class, new INT003_LEAD_FSC_TestMock('ERROR'));
    Test.startTest();
    INT003_LEAD_FSC.validatePF(lea.Id);
    Test.stopTest();

    System.assertEquals(200, INT003_LEAD_FSC.response.requestStatusCode);
  }

  @isTest
  static void constructorAndReturnResponseTest() {
    Lead lea = getTestLead();

    Test.setMock(HttpCalloutMock.class, new INT003_LEAD_FSC_TestMock('SUCCESS'));
    Test.startTest();
    INT003_LEAD_FSC instance = new INT003_LEAD_FSC(lea.Id);
    INT003_LEAD_FSC.Response resp = instance.returnResponse();
    Test.stopTest();

    System.assertNotEquals(null, resp);
  }
}
