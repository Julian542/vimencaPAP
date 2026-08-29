public class ValidatePreQualifyFlowController_FSC {
  @TestVisible
  private static Boolean isCandidatoPersonaNatural(
    Id recordTypeId,
    Map<Id, String> recordTypeDeveloperById
  ) {
    if (recordTypeId == null) {
      return false;
    }
    String devName = recordTypeDeveloperById.get(recordTypeId);
    return devName == 'Candidato_Persona_Natural';
  }
  public class FlowInputs {
    @InvocableVariable
    public Lead lead;
    @InvocableVariable
    public Participante__c accionista;
    @InvocableVariable
    public Participante__c representante;
  }

  public class FlowValidateOutputs {
    @InvocableVariable
    public String invalidField;
    @InvocableVariable
    public Boolean ok;

    public FlowValidateOutputs() {
      invalidField = '';
      ok = false;
    }
  }

  @InvocableMethod(
    label='ValidatePrequalifyFSC'
    description='allows us to validate data to prequalify'
  )
  public static List<FlowValidateOutputs> validatePrequalify(
    FlowInputs[] data
  ) {
    try {
      FlowValidateOutputs[] responses = new List<FlowValidateOutputs>();
      FlowValidateOutputs response = new FlowValidateOutputs();

      // Cache RecordType developer names to avoid querying inside the main loop.
      Set<Id> leadRecordTypeIds = new Set<Id>();
      for (FlowInputs record : data) {
        if (
          record != null &&
          record.lead != null &&
          record.lead.RecordTypeId != null
        ) {
          leadRecordTypeIds.add(record.lead.RecordTypeId);
        }
      }
      Map<Id, String> leadRecordTypeDeveloperById = new Map<Id, String>();
      if (!leadRecordTypeIds.isEmpty()) {
        for (RecordType rt : [
          SELECT Id, DeveloperName
          FROM RecordType
          WHERE Id IN :leadRecordTypeIds
        ]) {
          leadRecordTypeDeveloperById.put(rt.Id, rt.DeveloperName);
        }
      }

      for (FlowInputs record : data) {
        Lead candidato = record.lead;
        Participante__c accionista = record.accionista;
        Participante__c representante = record.representante;
        Boolean esPersonaNatural = isCandidatoPersonaNatural(
          candidato.RecordTypeId,
          leadRecordTypeDeveloperById
        );

        Lead candidatoTrama = [
          SELECT
            tolabel(LEA_INT_Tipo_de_identificacion__c),
            tolabel(LEA_INT_Nacionalidad__c),
            tolabel(LEA_INT_Pais_Nacimiento__c),
            tolabel(LEA_INT_Pais_Residencia_Legal__c),
            tolabel(LEA_INT_Canales_a_utilizar__c),
            tolabel(LEA_INT_Tipo_Estructura_Juridica__c),
            tolabel(LEA_INT_Origen_de_los_recursos__c),
            tolabel(LEA_INT_Prefesion_u_Oficio__c)
          FROM Lead
          WHERE Id = :candidato.Id
        ];

        //*********************************//
        //* Campos requeridos cliente N/J *//
        //*********************************//

        // ACRM - Código de Empresa (0001 por default)

        // ACRM - Tipo ID+Número de Identificación
        if (
          candidato.LEA_TipoIdentificacion__c == null ||
          candidatoTrama.LEA_INT_Tipo_de_identificacion__c == null
        ) {
          response.invalidField += 'Tipo de Identificación, \n';
        } else {
          if (candidatoTrama.LEA_INT_Tipo_de_identificacion__c == '1') {
            if (candidato.LEA_NumIdentificacion__c == null) {
              response.invalidField += 'Cédula, \n';
            }
          } else if (candidatoTrama.LEA_INT_Tipo_de_identificacion__c == '2') {
            if (candidato.LEA_NumIdentificacion__c == null) {
              response.invalidField += 'Pasaporte, \n';
            }
          } else if (candidatoTrama.LEA_INT_Tipo_de_identificacion__c == '3') {
            if (candidato.LEA_RNC__c == null) {
              response.invalidField += 'R.N.C., \n';
            }
          }
        }

        // ACRM - Maneja Depósito EFECTIVO
        // (unchecked por default)

        // ACRM - Maneja Op. Internacionales
        // (unchecked por default)

        // ACRM - Código de cliente
        // if (cliente.ACC_CIF__c == null) {
        //     response.invalidField += 'Código de Cliente (C.I.F), \n';
        // }

        // ACRM - Control de Pre vinculación
        // ('S' por default)

        // ACRM - Fecha Proceso
        // (Current time por default)

        // ACRM - Prev Numero Referencia
        // (Salesforce ID por default)

        // ACRM - Fecha de Nacimiento/Constitución
        if (
          (esPersonaNatural && candidato.LEA_PersonBirthdate__c == null) ||
          (!esPersonaNatural && candidato.LEA_Fecha_Fundacion__c == null)
        ) {
          response.invalidField += 'Fecha de Nacimiento/Constitución, \n';
        }

        // ACRM - Nacionalidad/Constitución
        if (
          candidato.LEA_Nacionalidad__c == null ||
          candidatoTrama.LEA_INT_Nacionalidad__c == null
        ) {
          response.invalidField += 'Nacionalidad/Constitución, \n';
        }

        // ACRM - Sucursal apertura
        if (candidato.LEA_INT_NumOficina__c == null) {
          response.invalidField += 'Sucursal Apertura, \n';
        }

        // ACRM - Código de Ejecutivo - Oficial
        if (candidato.LEA_Owner_Alias__c == null) {
          response.invalidField += 'Código de Ejecutivo - Oficial, \n';
        }

        // ACRM - Promedio ingreso mensual
        if (candidato.LEA_Total_Activos__c == null) {
          response.invalidField += 'Promedio Ingreso Mensual, \n';
        }

        // ACRM - Rango promedio ingreso mensual
        if (candidato.LEA_Ingresos__c == null) {
          response.invalidField += 'Rango Promedio Ingreso Mensual, \n';
        }

        // ACRM - Promedio ventas mensual
        if (candidato.LEA_Ventas_Ingresos_Anuales__c == null) {
          response.invalidField += 'Promedio Ventas Mensual, \n';
        }

        // ACRM - Rango promedio ventas mensual
        // (Desconocido en Salesforce)

        // ACRM - Tipo de Persona   N-J
        if (candidato.LEA_INT_TipoPersona__c == null) {
          response.invalidField += 'Tipo de Persona, \n';
        }

        // ACRM - Codigo Producto a Solicitar - 01
        if (candidato.LEA_ProductosASolicitar__c == null) {
          response.invalidField += 'Codigo Producto a Solicitar 01, \n';
        }

        // ACRM - Código de Actividad Económica
        if (candidato.LEA_Actividad_Economica__c == null) {
          response.invalidField += 'Código de Actividad Económica, \n';
        }

        // ACRM - Origen de los recursos
        if (
          candidato.LEA_INT_Origen_de_los_recursos__c == null ||
          candidato.LEA_Fuente_de_ingresos__c == null
        ) {
          response.invalidField += 'Origen de los Recursos, \n';
        }

        // ACRM - Codigo Servicio a Solicitar - 01
        if (candidato.LEA_Servicios_a_solicitar__c == null) {
          response.invalidField += 'Codigo Servicio a Solicitar 01, \n';
        }

        // ACRM - Codigo Canal a Utilizar - 01
        if (
          candidato.LEA_Canales_a_utilizar__c == null ||
          candidato.LEA_INT_Canales_a_utilizar__c == null
        ) {
          response.invalidField += ' Codigo Canal a Utilizar 01, \n';
        }

        // ACRM - Tipo de Beneficiario Final (CJ)
        if (candidato.LEA_Tipo_beneficio_final__c == null) {
          response.invalidField += 'Tipo de Beneficiario Final (CJ), \n';
        }

        // ACRM - Relación de dignatarios
        if (candidato.LEA_Relacion_de_dignatarios__c == null) {
          response.invalidField += 'Relación de Dignatarios, \n';
        }

        // ACRM - GUID
        // ( Vacio por default )

        //*********************************//
        //* Campos requeridos cliente F   *//
        //*********************************//

        if (esPersonaNatural) {
          // ACRM - Primer nombre
          if (candidato.FirstName == null) {
            response.invalidField += 'Primer nombre, \n';
          }

          // ACRM - Segundo nombre
          // if (cliente.middleName == null) {
          //     response.invalidField += 'Segundo nombre, \n';
          // }

          // ACRM - Primer apellido
          if (candidato.LastName == null) {
            response.invalidField += 'Primer apellido, \n';
          }

          // ACRM - Segundo apellido
          // if (cliente.Suffix == null) {
          //     response.invalidField += 'Segundo apellido, \n';
          // }

          // ACRM - Pais de nacimiento
          if (
            candidato.LEA_Pais_Nacimiento__c == null ||
            candidatoTrama.LEA_INT_Pais_Nacimiento__c == null
          ) {
            response.invalidField += 'País de Nacimiento, \n';
          }

          // ACRM - País Residencia
          if (
            candidato.LEA_Pais_Residencia_Legal__c == null ||
            candidatoTrama.LEA_INT_Pais_Residencia_Legal__c == null
          ) {
            response.invalidField += 'País Residencia, \n';
          }

          // ACRM - Profesión u Oficio
          if (
            candidato.LEA_Ocupacion__c == null ||
            candidatoTrama.LEA_INT_Prefesion_u_Oficio__c == null
          ) {
            response.invalidField += 'Profesión u Oficio, \n';
          }

          // ACRM - Servidor Público PEP
          if (candidato.LEA_Persona_PEP__c == null) {
            response.invalidField += 'Servidor Público PEP, \n';
          }

          // ACRM - Familiar de PEP
          // ( false por default)

          // ACRM - Colaborador de PEP
          // ( false por default)

          // ACRM - Relación con la Institucion
          // ( Vacio por default)
        } else {
          //*********************************//
          //* Campos requeridos cliente J   *//
          //*********************************//

          // ACRM - Nombre Persona/Razón Social
          if (candidato.LEA_Nombre_Corto_Comercial__c == null) {
            response.invalidField += 'Nombre Persona/Razón Social, \n';
          }

          // ACRM - Accionista 01
          if (accionista.PAR_Nombres__c == null) {
            response.invalidField += 'Accionista 01, \n';
          }

          // ACRM - Representante 01
          if (representante.PAR_Nombres__c == null) {
            response.invalidField += 'Representante Legal 01, \n';
          }

          // ACRM - Tipo Estructura Juridica
          if (
            candidato.LEA_Tipo_Organizacion__c == null ||
            candidato.LEA_INT_Tipo_Estructura_Juridica__c == null
          ) {
            response.invalidField += 'Tipo Estructura Juridica, \n';
          }
        }
      }

      response.ok = (response.invalidField.length() == 0);
      responses.add(response);
      return responses;
    } catch (System.FlowException e) {
      throw new HandledException(e.getMessage());
    }
  }
}