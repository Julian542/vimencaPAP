/**
 * Adaptación de la clase INT001_VAER_Controller_FSC de Account a Lead (Prospecto/Candidato).
 *
 * Equivalencia de campos (Account → Lead):
 * - FinServ__IndividualId__c → LEA_NumIdentificacion__c
 * - ACC_TipoIdentificacion__c → LEA_TipoIdentificacion__c
 * - ACC_Estado__c → Status (Lead Status)
 * - PersonBirthdate → LEA_PersonBirthdate__c
 * - FinServ__Gender__pc → LEA_Genero__c
 * - FinServ__CountryOfBirth__pc / FinServ__Citizenship__pc → LEA_Pais_Nacimiento__c / LEA_Nacionalidad__c
 * - Campos PEP (ACC_*_PEP__c) → LEA_*_PEP__c
 *
 * @author: Jhonny Peroza
 * @date: 14-03-2026
 */

@SuppressWarnings('PMD')
public with sharing class INT001_LEAD_VAER_Controller_FSC {
  public class Response {
    @AuraEnabled
    public Integer httpRequestStatusCode;
    @AuraEnabled
    public String errorCode;
    @AuraEnabled
    public String errorText;
    @AuraEnabled
    public Boolean updateSuccess;
    @AuraEnabled
    public String updateErrorMessage;
    @AuraEnabled
    public Boolean skipPep;
  }

  /**
   * Ahora recibe Id de Lead (Prospecto/Candidato) en vez de Account.
   * Mantengo el nombre del método para no romper llamadas desde UI.
   */
  @AuraEnabled
  public static INT001_LEAD_VAER_Controller_FSC.Response updateAccount(Id recordId) {
    System.debug('on INT001_LEAD_VAER_Controller_FSC.updateAccount(recordId=' + recordId + ')');

    INT001_LEAD_VAER_Controller_FSC.Response response = new INT001_LEAD_VAER_Controller_FSC.Response();

    Lead lea = [
      SELECT
        Id,
        RecordType.Name,
        Status,
        FirstName,
        MiddleName,
        LastName,
        Suffix,
        LEA_NumIdentificacion__c,
        LEA_TipoIdentificacion__c,
        LEA_PersonBirthdate__c,
        Lugar_de_nacimiento_Padron_Electoral__c,
        LEA_Pais_Nacimiento__c,
        LEA_Nacionalidad__c,
        LEA_Genero__c
      FROM Lead
      WHERE Id = :recordId
    ];

    // Equivalencias:
    // - Estado: Account.ACC_Estado__c => Lead.Status
    // - Tipo identificación: Account.ACC_TipoIdentificacion__c => Lead.LEA_TipoIdentificacion__c
    // - Nº identificación: Account.FinServ__IndividualId__c => Lead.LEA_NumIdentificacion__c
    if ((lea.Status == 'Pendiente' || lea.Status == 'Iniciado') && lea.LEA_TipoIdentificacion__c == 'Cédula' && String.isNotBlank(lea.LEA_NumIdentificacion__c)) {
      System.debug('# Prospecto: ' + lea.LEA_TipoIdentificacion__c + ' - ' + lea.LEA_NumIdentificacion__c);

      // Check Identification Number against Electoral Register.
      INT001_FSC.Response recordData = INT001_FSC.validateAgainstElectoralRegister(lea.LEA_NumIdentificacion__c, lea.LEA_TipoIdentificacion__c);

      System.debug('# VAER response: ' + recordData);
      System.debug('# VAER httpRequestStatusCode: ' + recordData.requestStatusCode);
      System.debug('# VAER ErrorCode: ' + recordData.ErrorCode);
      System.debug('# VAER ErrorText: ' + recordData.ErrorText);

      // Store results in response.
      response.httpRequestStatusCode = recordData.requestStatusCode;
      response.errorCode = recordData.ErrorCode;
      response.errorText = recordData.ErrorText;

      System.debug('# VAER NumDocumento=' + recordData.NumDocumento);

      if (response.errorCode == '000' && String.isNotBlank(recordData.NumDocumento)) {
        try {
          // Nombre y apellidos
          lea.FirstName = recordData.PrimerNombre;
          lea.MiddleName = recordData.SegundoNombre;
          lea.LastName = recordData.PrimerApellido;
          lea.Suffix = recordData.SegundoApellido;

          // Fecha Nacimiento (equivalente Lead)
          // Account.PersonBirthdate => Lead.LEA_PersonBirthdate__c
          if (String.isNotBlank(recordData.FechaNacimiento)) {
            try {
              lea.LEA_PersonBirthdate__c = Date.valueOf(recordData.FechaNacimiento);
            } catch (Exception ignoreDate) {
              System.debug('FechaNacimiento inválida: ' + recordData.FechaNacimiento);
            }
          }

          // Lugar nacimiento
          lea.Lugar_de_nacimiento_Padron_Electoral__c = recordData.LugarNacimiento;

          // País nacimiento / Nacionalidad (equivalentes Lead)
          // Account.FinServ__CountryOfBirth__pc => Lead.LEA_Pais_Nacimiento__c
          // Account.FinServ__Citizenship__pc   => Lead.LEA_Nacionalidad__c
          if (String.isNotBlank(recordData.LugarNacimiento)) {
            if (recordData.LugarNacimiento.containsAny('R.D')) {
              lea.LEA_Pais_Nacimiento__c = 'REPUBLICA DOMINICANA';
              lea.LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA';
            } else if (recordData.LugarNacimiento.split(',').size() > 1) {
              String country = recordData.LugarNacimiento.split(',')[1].trim();
              lea.LEA_Pais_Nacimiento__c = country;
              lea.LEA_Nacionalidad__c = country;
            } else {
              lea.LEA_Pais_Nacimiento__c = recordData.LugarNacimiento;
              lea.LEA_Nacionalidad__c = recordData.LugarNacimiento;
            }
          }

          // Género
          // Account.FinServ__Gender__pc => Lead.LEA_Genero__c
          lea.LEA_Genero__c = recordData.Genero;

          // Cambio de estado del prospecto (Account.ACC_Estado__c => Lead.Status)
          lea.Status = 'Calificado';

          try {
            update lea;
          } catch (Exception ex) {
            // Si te falla por valores no válidos en picklists de país/nacionalidad, los nullo y reintento.
            if (ex.getMessage().containsIgnoreCase('LEA_Nacionalidad__c') || ex.getMessage().containsIgnoreCase('LEA_Pais_Nacimiento__c')) {
              lea.LEA_Pais_Nacimiento__c = null;
              lea.LEA_Nacionalidad__c = null;
              update lea;
              System.debug('ERROR lugar nacimiento: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            } else {
              throw ex;
            }
          }

          response.updateSuccess = true;
        } catch (Exception e) {
          String msg = e.getMessage();
          if (msg != null && msg.containsIgnoreCase('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
            response.updateErrorMessage = msg.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': [');
          } else if (msg == 'Invalid date: ') {
          } else {
            response.updateErrorMessage = msg;
          }
          response.updateSuccess = false;
        }
      } else {
        response.errorCode = '000';
        response.httpRequestStatusCode = 200;
        response.updateSuccess = false;
        response.updateErrorMessage = 'El numero de documento no esta registrado';
      }
    } else if ((lea.Status == 'Pendiente' || lea.Status == 'Iniciado') &&
        lea.LEA_TipoIdentificacion__c == 'Pasaporte' &&
        String.isNotBlank(lea.LEA_NumIdentificacion__c)) {
      return submitPassportForApproval(lea);
    } else if (lea.LEA_TipoIdentificacion__c != 'Cédula') {
      response.errorCode = '000';
      response.httpRequestStatusCode = 200;
      response.updateSuccess = false;
      response.updateErrorMessage = 'El prospecto solo puede calificarse si su tipo de identificación es CÉDULA';
    } else {
      response.errorCode = '000';
      response.httpRequestStatusCode = 200;
      response.updateSuccess = false;
      response.updateErrorMessage = 'El prospecto solo puede calificarse si está en estado INICIADO y el Nº de Identificación esta informado';
    }

    return response;
  }

  public static Response submitPassportForApproval(Lead candidate) {
    Response response = new Response();
    Savepoint savepoint = Database.setSavepoint();

    try {
      List<ProcessInstance> pendingApprovals = [
        SELECT Id
        FROM ProcessInstance
        WHERE TargetObjectId = :candidate.Id AND Status = 'Pending'
        LIMIT 1
      ];

      if (pendingApprovals.isEmpty()) {
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setObjectId(candidate.Id);
        request.setProcessDefinitionNameOrId('PA_Flujo_Aprobacion_LEAD');
        request.setSkipEntryCriteria(true);
        request.setComments('Candidato con pasaporte enviado automáticamente a revisión legal.');

        Approval.ProcessResult result = Approval.process(request);
        if (!result.isSuccess()) {
          throw new PassportApprovalException('No fue posible enviar el candidato al proceso de aprobación.');
        }
      }

      response.httpRequestStatusCode = 200;
      response.errorCode = '000';
      response.updateSuccess = true;
      response.skipPep = true;
    } catch (Exception error) {
      Database.rollback(savepoint);
      String message = error.getMessage();
      response.httpRequestStatusCode = 200;
      response.errorCode = '000';
      response.updateSuccess = false;
      response.skipPep = true;
      response.updateErrorMessage = message != null && message.containsIgnoreCase('FIELD_CUSTOM_VALIDATION_EXCEPTION')
        ? message.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': [')
        : message;
    }

    return response;
  }

  private class PassportApprovalException extends Exception {}

  //INT004 Integration controller
  @AuraEnabled
  public static INT001_LEAD_VAER_Controller_FSC.Response updateAccountPEP(Id recordId) {
    System.debug('on INT001_LEAD_VAER_Controller_FSC.updateAccountPEP(recordId=' + recordId + ')');
    INT001_LEAD_VAER_Controller_FSC.Response response = tunelCaseFlowLightning(recordId);
    return response;
  }

  @InvocableMethod
  public static void updateAccountPEPFlow(List<Id> recordId) {
    System.debug('on INT001_LEAD_VAER_Controller_FSC.updateAccountPEPFlow(recordId=' + recordId + ')');
    INT001_LEAD_VAER_Controller_FSC.Response response = tunelCaseFlowLightning(recordId[0]);
  }

  /**
   * Ahora opera sobre Lead (Prospecto).
   * Mantengo el nombre del método para minimizar impactos.
   */
  public static INT001_LEAD_VAER_Controller_FSC.Response tunelCaseFlowLightning(Id recordId) {
    System.debug('on INT001_LEAD_VAER_Controller_FSC.tunelCaseFlowLightning(recordId=' + recordId + ')');

    INT001_LEAD_VAER_Controller_FSC.Response response = new INT001_LEAD_VAER_Controller_FSC.Response();

    Lead lea = [
      SELECT
        Id,
        RecordType.DeveloperName,
        FirstName,
        LastName,
        LEA_NumIdentificacion__c,
        LEA_TipoIdentificacion__c,
        // Campos PEP en Lead
        LEA_N_Identificacion_PEP__c,
        LEA_Tipo_Identif_PEP__c,
        LEA_Primer_Nombre_PEP__c,
        LEA_Segundo_Nombre_PEP__c,
        LEA_Primer_Apellido_PEP__c,
        LEA_Segundo_Apellido_PEP__c,
        LEA_Persona_PEP__c,
        LEA_Tipo_Relacion_PEP__c,
        LEA_Ocupacion_PEP__c,
        LEA_Nacionalidad_PEP__c,
        LEA_Puesto_Cargo_PEP__c,
        LEA_Institucion_Trabajo_PEP__c
      FROM Lead
      WHERE Id = :recordId
    ];

    System.debug('Lead.RecordType=' + lea.RecordType.DeveloperName);

    if (lea.RecordType.DeveloperName == 'Candidato_Persona_Natural' && (lea.LEA_NumIdentificacion__c != null && lea.LEA_TipoIdentificacion__c != null)) {
      System.debug('# Llamamos al INT004_FSC.updateUserPEP');
      System.debug('# lea.LEA_NumIdentificacion__c=' + lea.LEA_NumIdentificacion__c);
      System.debug('# lea.LEA_TipoIdentificacion__c=' + lea.LEA_TipoIdentificacion__c);
      System.debug('# lea.FirstName=' + lea.FirstName);
      System.debug('# lea.LastName=' + lea.LastName);

      INT004_FSC.Response recordData = INT004_FSC.updateUserPEP(lea.LEA_NumIdentificacion__c, lea.LEA_TipoIdentificacion__c, lea.FirstName, lea.LastName);

      System.debug('# recordData=' + recordData);

      System.debug('recordData raw: ' + JSON.serialize(recordData));

      response.httpRequestStatusCode = recordData.requestStatusCode;
      response.errorCode = recordData.ErrorCode;
      response.errorText = recordData.ErrorText;

      System.debug('# response.errorCode  = ' + response.errorCode);
      System.debug('# response.errorText = ' + response.errorText);

      System.debug('recordData.values: ' + recordData.values);

      if (response.errorCode == '000') {
        String personaPepVal = (recordData.values != null && recordData.values.containsKey('PersonaPEP')) ? String.valueOf(recordData.values.get('PersonaPEP')) : null;

        System.debug('# personaPepVal = ' + personaPepVal);

        // si es SI o viene vacío, lleno todo.
        if (personaPepVal == 'SI' || String.isBlank(personaPepVal)) {
          lea.LEA_N_Identificacion_PEP__c = safeStr(recordData, 'Documento');
          lea.LEA_Tipo_Identif_PEP__c = safeStr(recordData, 'TipoDocumento');

          String primerNombreFull = safeStr(recordData, 'PrimerNombre');
          String[] firstNameParts = (String.isNotBlank(primerNombreFull)) ? primerNombreFull.split(' ', 2) : new List<String>{ null, null };

          lea.LEA_Primer_Nombre_PEP__c = (firstNameParts.size() > 0) ? firstNameParts[0] : null;
          lea.LEA_Segundo_Nombre_PEP__c = (firstNameParts.size() > 1) ? firstNameParts[1] : null;

          lea.LEA_Primer_Apellido_PEP__c = safeStr(recordData, 'PrimerApellido');
          lea.LEA_Segundo_Apellido_PEP__c = safeStr(recordData, 'SegundoApellido');

          lea.LEA_Persona_PEP__c = personaPepVal;
          lea.LEA_Tipo_Relacion_PEP__c = safeStr(recordData, 'TipoParentesco');
          lea.LEA_Ocupacion_PEP__c = safeStr(recordData, 'Ocupacion');
          lea.LEA_Nacionalidad_PEP__c = safeStr(recordData, 'Nacionalidad');
          lea.LEA_Puesto_Cargo_PEP__c = safeStr(recordData, 'CargoPolitico');

          // En Lead NO existe Employment__c.
          // Guardamos institución en el campo Lead ya existente:
          lea.LEA_Institucion_Trabajo_PEP__c = safeStr(recordData, 'InstitucionTrabajo');
          System.debug('#Lea=' + JSON.serialize(lea));
          try {
            update lea;
            response.updateSuccess = true;
          } catch (Exception e) {
            response.updateSuccess = false;
            response.updateErrorMessage = 'ERROR DESCONOCIDO ::' + e.getMessage();
          }
        } else {
          // Solo marca Persona PEP y actualiza
          lea.LEA_Persona_PEP__c = personaPepVal;

          try {
            update lea;
            response.errorCode = '000';
            response.httpRequestStatusCode = 200;
            response.updateSuccess = true;
          } catch (Exception e) {
            response.updateSuccess = false;
            response.updateErrorMessage = 'ERROR DESCONOCIDO ::' + e.getMessage();
          }
        }
      }
    } else if (lea.RecordType.DeveloperName == 'Candidato_Persona_Natural' && (lea.LEA_NumIdentificacion__c == null || lea.LEA_TipoIdentificacion__c == null)) {
      response.errorCode = '000';
      response.httpRequestStatusCode = 200;
      response.updateSuccess = false;
      response.updateErrorMessage = 'Los campos Tipo de identificación y Nº de Identificación no pueden estar vacios.';
    } else {
      response.updateSuccess = true;
    }

    return response;
  }

  private static String safeStr(INT004_FSC.Response recordData, String key) {
    try {
      if (recordData != null && recordData.values != null && recordData.values.containsKey(key) && recordData.values.get(key) != null) {
        return String.valueOf(recordData.values.get(key));
      }
    } catch (Exception e) {
      System.debug('safeStr error key=' + key + ' msg=' + e.getMessage());
    }
    return null;
  }
}