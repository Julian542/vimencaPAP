@SuppressWarnings('PMD')
public with sharing class INT003_LEAD_FSC {
  public static Response response;
  public class Response extends INTResponse {
    public final List<String> fieldList = new List<String>{ 'NumDocumento', 'TipoDocumento', 'CoincidenciaLI', 'CoincidenciaLE', 'Listas' };
    public Map<String, String> valuesClient = new Map<String, String>{
      '[function_document]' => 'LEA_NumIdentificacion__c',
      '[function_documentType]' => 'LEA_TipoIdentificacion__c',
      '[function_firstName]' => 'firstName',
      '[function_middleName]' => 'middleName',
      '[function_lastName]' => 'lastName',
      '[function_suffix]' => 'suffix',
      '[function_birthDate]' => 'LEA_PersonBirthdate__c',
      '[function_nacionality]' => 'LEA_Nacionalidad__c'
    };
  }

  public static INT003_LEAD_FSC.Response parse(String response) {
    INT003_LEAD_FSC.Response r = new INT003_LEAD_FSC.Response();

    // Retrieve Result Status.
    r.errorCode = response.substringAfter('<ErrorCode>').substringBefore('</ErrorCode>');
    r.errorText = response.substringAfter('<ErrorText>').substringBefore('</ErrorText>');
    // If status is successful, retrieve fields.
    if (r.errorCode == '000') {
      for (String field : r.fieldList) {
        String textValue = response.substringAfter('<' + field + '>').substringBefore('</' + field + '>');
        textValue = textValue.replace('Yamp;', '&');
        r.values.put(field, textValue);
      }
    }
    return r;
  }
  public static void updateAccount(INT003_LEAD_FSC.Response recordData, id recordId) {
    Lead lea = [SELECT id, LEA_Resultado_Validacion__c, Status, LEA_SubEstado__c FROM Lead WHERE id = :recordId];
    List<Matriz_lista_control__c> matrizCase = [
      SELECT id, MAT_Resultado_validacion__c, MAT_Estado__c, MAT_Sub_estado__c
      FROM Matriz_lista_control__c
      WHERE MAT_Coincidencia_en_listas_externas__c = :recordData.values.get('CoincidenciaLE').toString() AND MAT_Coincidencia_en_listas__c = :recordData.values.get('CoincidenciaLI').toString()
    ];

    lea.LEA_Resultado_Validacion__c = matrizCase[0].MAT_Resultado_validacion__c;
    lea.Status = matrizCase[0].MAT_Estado__c;
    lea.LEA_SubEstado__c = matrizCase[0].MAT_Sub_estado__c.toUpperCase();
    lea.LEA_Coincidencia_Listas_Externas__c = (recordData.values.get('CoincidenciaLE').toString() == 'Y') ? true : false;
    lea.LEA_Coincidencia_Listas_Internas__c = (recordData.values.get('CoincidenciaLI').toString() == 'Y') ? true : false;
    lea.LEA_Listas__c = recordData.values.get('Listas').toString();
    lea.LEA_Ultima_Actualizacion_Listas_Internas__c = System.now();
    lea.LEA_Ultima_Actualizacion_Listas_Externas__c = System.now();

    try {
      update lea;
    } catch (Exception e) {
      System.debug('ERROR NO CONTROLADO EN UPDATE:: ' + e.getMessage());
    }
  }

  public static String fillXML(INT003_LEAD_FSC.Response responseServer, Lead client, String frame) {
    String detailClient = frame.substringBetween('<Function>', '</Function>');
    frame = frame.replace(detailClient, fillDetailClient(responseServer.valuesClient, client, detailClient));
    return frame;
  }

  public static String fillDetailClient(Map<String, String> valuesClient, SObject client, String frame) {
    frame = INTUtilities.fillCorrectType(valuesClient, client, frame);
    return frame;
  }

  public INT003_LEAD_FSC(String idClient) {
    validatePF(idClient);
  }

  public INT003_LEAD_FSC.Response returnResponse() {
    return response;
  }

  public static void validatePF(String idClient) {
    Lead leadToValidate = [SELECT Status FROM Lead WHERE Id = :idClient LIMIT 1];
    if (leadToValidate.Status != 'Calificado') {
      throw new IllegalArgumentException('El candidato debe estar en estado Calificado antes de validar contra listas');
    }

    List<StaticResource> srList = [SELECT id, name, body FROM StaticResource WHERE name = 'INT003_request_frame'];
    List<AuthSession> authList = [
      SELECT id, SourceIP, Users.Name, LoginType, NumSecondsValid, CreatedDate
      FROM AuthSession
      WHERE UsersId = :UserInfo.getUserId()
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];

    List<String> fields = new List<String>(Lead.SObjectType.getDescribe().fields.getMap().keySet());
    String soql = '' + ' SELECT ' + String.join(fields, ',') + ' FROM Lead' + ' WHERE id=\'' + String.escapeSingleQuotes(idClient) + '\'';
    Lead client = Database.query(soql);

    HttpRequest request = new HttpRequest();
    HttpResponse res;
    Http http = new Http();
    INT003_LEAD_FSC.Response responseServer = new INT003_LEAD_FSC.Response();
    String frame;

    // If parameters are not specified, throw exception.

    // If static resource with the frame to be sent exists, replaces fields and sends it.
    if (!srList.isEmpty()) {
      // Setup request
      request.setEndpoint(Label.EndpointWs);
      request.setMethod('POST');
      request.setTimeout(120000);
      request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
      request.setHeader('SoapAction', 'http://crmintegration.local/ValidaListasControl');
      frame = srList[0].body.toString();

      // Set WebService credentials.
      frame = frame.replace('[ws_user]', Label.Int_Username);
      frame = frame.replace('[ws_password]', Label.Int_Password);

      // Set Callout parameters.
      frame = frame.replace('[function_username]', UserInfo.getUserName());
      frame = frame.replace('[function_requestdate]', System.now().format('dd/MM/yyyy'));
      frame = frame.replace('[function_requesttime]', System.now().format('hh:mm:ss'));
      frame = frame.replace('[function_terminal]', authList[0].SourceIp);

      frame = fillXML(responseServer, client, frame);

      request.setBody(frame);

      res = http.send(request);

      try {
        switch on (res.getStatusCode()) {
          when 200 {
            responseServer = parse(res.getBody());
            updateAccount(responseServer, idClient);
          }
          when else {
            // On Error
            System.debug('Error response :: ' + res);
          }
        }
      } catch (Exception e) {
        System.debug('Error :: ' + e);
      } finally {
        INTLogger.INTLoggerResult result = INTLogger.logCallout('003', 'ValidaListasControl', request, res);
      }
      responseServer.requestStatusCode = res.getStatusCode();
      responseServer.requestStatus = res.getStatus();
    } else {
      throw new XmlException('Static resource with the request template named "INT003_request_frame" could not be found.');
    }
    response = responseServer;
  }
}