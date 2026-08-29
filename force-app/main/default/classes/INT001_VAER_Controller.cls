public class INT001_VAER_Controller {
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
  public static INT001_VAER_Controller.Response updateAccount(Id recordId) {
    INT001_VAER_Controller.Response response = new INT001_VAER_Controller.Response();

    Account acc = [SELECT id, ACC_NumIdentificacion__c, ACC_TipoIdentificacion__c, ACC_Estado__c FROM Account WHERE id = :recordId];
    if (acc.ACC_TipoIdentificacion__c == 'Cédula' && String.isNotBlank(acc.ACC_NumIdentificacion__c)) {
      // Check Identification Number against Electoral Register.
      INT001.Response recordData = INT001.validateAgainstElectoralRegister(acc.ACC_NumIdentificacion__c, acc.ACC_TipoIdentificacion__c);

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
            acc.ACC_Pais_Nacimiento__c = 'REPUBLICA DOMINICANA';
            acc.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
          } else if (recordData.LugarNacimiento.split(',').size() > 1) {
            acc.ACC_Pais_Nacimiento__c = recordData.LugarNacimiento.split(',')[1];
            acc.ACC_Nacionalidad__c = recordData.LugarNacimiento.split(',')[1];
          } else {
            acc.ACC_Pais_Nacimiento__c = recordData.LugarNacimiento;
            acc.ACC_Nacionalidad__c = recordData.LugarNacimiento;
          }

          acc.ACC_Condicion__c = 'PROSPECTO';
          acc.ACC_Estado__c = 'CALIFICADO';
          acc.ACC_Genero__c = recordData.Genero;

          try {
            update acc;
          } catch (Exception ex) {
            if (
              ex.getMessage().containsIgnoreCase('ACC_Nacionalidad__c') ||
              ex.getMessage().containsIgnoreCase('ACC_Pais_Nacimiento__c') ||
              ex.getMessage().containsIgnoreCase('ACC_Ciudad_de_Nacimiento__c')
            ) {
              acc.ACC_Pais_Nacimiento__c = null;
              acc.ACC_Nacionalidad__c = null;
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
    }
    return response;
  }

  //INT004 Integration controler
  @AuraEnabled
  public static INT001_VAER_Controller.Response updateAccountPEP(Id recordId) {
    INT001_VAER_Controller.Response response = tunelCaseFlowLightning(recordId);
    return response;
  }
  @InvocableMethod
  public static void updateAccountPEPFlow(List<Id> recordId) {
    INT001_VAER_Controller.Response response = tunelCaseFlowLightning(recordId[0]);
    //return new List<INT001_VAER_Controller.Response> {response};
  }
  public static INT001_VAER_Controller.Response tunelCaseFlowLightning(Id recordId) {
    INT001_VAER_Controller.Response response = new INT001_VAER_Controller.Response();

    Account acc = [SELECT id, ACC_NumIdentificacion__c, ACC_TipoIdentificacion__c, firstName, LastName, RecordType.name FROM Account WHERE id = :recordId];
    // Check Identification Number against Electoral Register.
    system.debug(acc.RecordType.name);
    if (acc.RecordType.name == 'Candidato Persona Física' && (acc.ACC_NumIdentificacion__c != null && acc.ACC_TipoIdentificacion__c != null)) {
      INT004.Response recordData = INT004.updateUserPEP(acc.ACC_NumIdentificacion__c, acc.ACC_TipoIdentificacion__c, acc.firstName, acc.LastName);

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
          acc.ACC_Institucion_Trabajo_PEP__c = recordData.values.get('InstitucionTrabajo').toString();
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