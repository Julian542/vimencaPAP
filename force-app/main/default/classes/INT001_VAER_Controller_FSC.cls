/**
 * @description       : an adapted version of INT001_VAER_Controller to FinServ Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             :
 * @last modified on  : 13-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
 **/
@SuppressWarnings('PMD')
//TODO reveer toda la clase y pasar a Lead
public with sharing class INT001_VAER_Controller_FSC {
  public class Response {
    @AuraEnabled
    public Integer httpRequestStatusCode;
    @AuraEnabled
    public string errorCode;
    @AuraEnabled
    public string errorText;
    @AuraEnabled
    public boolean updateSuccess;
    @AuraEnabled
    public String updateErrorMessage;
  }

  @AuraEnabled
  public static INT001_VAER_Controller_FSC.Response updateAccount(Id recordId) {
    INT001_VAER_Controller_FSC.Response response = new INT001_VAER_Controller_FSC.Response();

    Account acc = [
      SELECT id, ACC_NumIdentificacion__c, ACC_TipoIdentificacion__c, ACC_Estado__c
      FROM Account
      WHERE id = :recordId
    ];

    if (acc.ACC_Estado__c == 'CREADO' && acc.ACC_TipoIdentificacion__c == 'Cédula' && String.isNotBlank(acc.ACC_NumIdentificacion__c)) {
      // Check Identification Number against Electoral Register.
      INT001_FSC.Response recordData = INT001_FSC.validateAgainstElectoralRegister(acc.ACC_NumIdentificacion__c, acc.ACC_TipoIdentificacion__c);

      // Store results in response.
      response.httpRequestStatusCode = recordData.requestStatusCode;
      response.errorCode = recordData.ErrorCode;
      response.errorText = recordData.ErrorText;
      System.debug(recordData.NumDocumento);

      if (response.errorCode == '000' && String.isNotBlank(recordData.NumDocumento)) {
        try {
          acc.FirstName = recordData.PrimerNombre;
          acc.MiddleName = recordData.SegundoNombre;
          acc.LastName = recordData.PrimerApellido;
          acc.Suffix = recordData.SegundoApellido;

          acc.PersonBirthdate = Date.valueOf(recordData.FechaNacimiento);
          acc.Lugar_de_nacimiento_Padron_Electoral__c = recordData.LugarNacimiento;

          if (recordData.LugarNacimiento.containsAny('R.D')) {
            acc.ACC_Ciudad_de_Nacimiento__c = recordData.LugarNacimiento.split(',')[0];
            acc.FinServ__CountryOfBirth__pc = 'REPUBLICA DOMINICANA';
            acc.FinServ__Citizenship__pc = 'REPUBLICA DOMINICANA';
          } else if (recordData.LugarNacimiento.split(',').size() > 1) {
            acc.FinServ__CountryOfBirth__pc = recordData.LugarNacimiento.split(',')[1];
            acc.FinServ__Citizenship__pc = recordData.LugarNacimiento.split(',')[1];
          } else {
            acc.FinServ__CountryOfBirth__pc = recordData.LugarNacimiento;
            acc.FinServ__Citizenship__pc = recordData.LugarNacimiento;
          }

          acc.ACC_Condicion__c = 'CLIENTE';
          acc.ACC_Estado__c = 'CALIFICADO';
          acc.FinServ__Gender__pc = recordData.Genero;

          try {
            update acc;
          } catch (Exception ex) {
            if (
              ex.getMessage().containsIgnoreCase('FinServ__Citizenship__pc') ||
              ex.getMessage().containsIgnoreCase('FinServ__CountryOfBirth__pc') ||
              ex.getMessage().containsIgnoreCase('ACC_Ciudad_de_Nacimiento__c')
            ) {
              acc.FinServ__CountryOfBirth__pc = null;
              acc.FinServ__Citizenship__pc = null;
              acc.ACC_Ciudad_de_Nacimiento__c = null;
              update acc;
              system.debug('HA SUCEDIDO UN ERROR CON EL LUGAR DE NACIMIENTO ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            }
          }

          response.updateSuccess = true;
        } catch (Exception e) {
          String msg = e.getMessage();
          if (msg.containsIgnoreCase('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
            response.updateErrorMessage = e.getMessage().substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': [');
          } else if (msg == 'Invalid date: ') {
          } else {
            response.updateErrorMessage = e.getMessage();
          }
          response.updateSuccess = false;
        }
      } else {
        response.errorCode = '000';
        response.httpRequestStatusCode = 200;
        response.updateSuccess = false;
        response.updateErrorMessage = 'El numero de documento no esta registrado';
      }
    } else if (acc.ACC_TipoIdentificacion__c != 'Cédula') {
      response.errorCode = '000';
      response.httpRequestStatusCode = 200;
      response.updateSuccess = false;
      response.updateErrorMessage = 'El cliente solo puede calificarse si su tipo de identificación es CÉDULA';
    } else {
      response.errorCode = '000';
      response.httpRequestStatusCode = 200;
      response.updateSuccess = false;
      response.updateErrorMessage = 'El cliente solo puede calificarse si está en estado CREADO y el Nº de Identificación esta informado';
    }
    return response;
  }

  //INT004 Integration controler
  @AuraEnabled
  public static INT001_VAER_Controller_FSC.Response updateAccountPEP(Id recordId) {
    INT001_VAER_Controller_FSC.Response response = tunelCaseFlowLightning(recordId);
    return response;
  }

  @InvocableMethod
  public static void updateAccountPEPFlow(List<Id> recordId) {
    INT001_VAER_Controller_FSC.Response response = tunelCaseFlowLightning(recordId[0]);
    //return new List<INT001_VAER_Controller_FSC.Response> {response};
  }

  public static INT001_VAER_Controller_FSC.Response tunelCaseFlowLightning(Id recordId) {
    INT001_VAER_Controller_FSC.Response response = new INT001_VAER_Controller_FSC.Response();

    Account acc = [
      SELECT id, ACC_NumIdentificacion__c, ACC_TipoIdentificacion__c, firstName, LastName, RecordType.name
      FROM Account
      WHERE id = :recordId
    ];
    // Check Identification Number against Electoral Register.
    system.debug(acc.RecordType.name);
    //TODO revisar porque candidato ahora es Lead.
    if (acc.RecordType.name == 'Candidato Persona Física' && (acc.ACC_NumIdentificacion__c != null && acc.ACC_TipoIdentificacion__c != null)) {
      INT004_FSC.Response recordData = INT004_FSC.updateUserPEP(acc.ACC_NumIdentificacion__c, acc.ACC_TipoIdentificacion__c, acc.firstName, acc.LastName);

      List<FinServ__Employment__c> empleoList = [
        SELECT Id, Name
        FROM FinServ__Employment__c
        WHERE Name = :recordData.values.get('InstitucionTrabajo').toString()
      ];

      FinServ__Employment__c empleoToCreate;
      if (empleoList.isEmpty()) {
        empleoToCreate.Name = recordData.values.get('InstitucionTrabajo').toString();
        insert empleoToCreate;
        empleoList.add(empleoToCreate);
      }
      // Store results in response.
      response.httpRequestStatusCode = recordData.requestStatusCode;
      response.errorCode = recordData.ErrorCode;
      response.errorText = recordData.ErrorText;

      if (response.errorCode == '000') {
        if (recordData.values.get('PersonaPEP').toString() == 'SI' || String.isEmpty(recordData.values.get('PersonaPEP').toString())) {
          acc.ACC_N_Identificacion_PEP__c = recordData.values.get('Documento').toString();
          acc.ACC_Tipo_Identif_PEP__c = recordData.values.get('TipoDocumento').toString();
          String[] firstName = recordData.values.get('PrimerNombre').toString().split(' ', 2);
          System.debug(recordData.values.get('SegundoApellido').toString());

          acc.ACC_Primer_Nombre_PEP__c = firstName[0];
          acc.ACC_Segundo_Nombre_PEP__c = firstName[1];
          acc.ACC_Primer_Apellido_PEP__c = recordData.values.get('PrimerApellido').toString();
          acc.ACC_Segundo_Apellido_PEP__c = recordData.values.get('SegundoApellido').toString();
          acc.ACC_Persona_PEP__c = recordData.values.get('PersonaPEP').toString();
          acc.ACC_Tipo_Relacion_PEP__c = recordData.values.get('TipoParentesco').toString();
          acc.ACC_Ocupacion_PEP__c = recordData.values.get('Ocupacion').toString();
          //acc.Employment__c = empleoList[0].Id;
          acc.ACC_Nacionalidad_PEP__c = recordData.values.get('Nacionalidad').toString();
          acc.ACC_Puesto_Cargo_PEP__c = recordData.values.get('CargoPolitico').toString();
          try {
            update acc;
            response.updateSuccess = true;
          } catch (Exception e) {
            response.updateSuccess = false;
            response.updateErrorMessage = 'ERROR DESCONOCIDO ::' + e.getMessage();
          }
        } else {
          acc.ACC_Persona_PEP__c = recordData.values.get('PersonaPEP').toString();
          try {
            update acc;
            // response.updateSuccess = true;
            response.errorCode = '000';
            response.httpRequestStatusCode = 200;
            response.updateSuccess = true;
            //response.updateErrorMessage = 'Solo se puede recuperar la información PEP si el prospecto está marcado como persona PEP.';
          } catch (Exception e) {
            response.updateSuccess = false;
            response.updateErrorMessage = 'ERROR DESCONOCIDO ::' + e.getMessage();
          }
        }
      }
    } else if (acc.RecordType.name == 'Person Account' && (acc.ACC_NumIdentificacion__c == null || acc.ACC_TipoIdentificacion__c == null)) {
      response.errorCode = '000';
      response.httpRequestStatusCode = 200;
      response.updateSuccess = false;
      response.updateErrorMessage = 'Los campos Tipo de identificación y Nº de Identificación no pueden estar vacios.';
    } else {
      response.updateSuccess = true;
    }
    return response;
  }
}