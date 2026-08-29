/**
 * Name: LeadConversionQueue
 * Description:
 *  Crea registros FSC/Custom derivados del Lead al convertirse (BULK SAFE):
 *   - ContactPointAddress (Dirección)
 *   - ContactPointPhone / ContactPointEmail (Vías de contacto)
 *   - Informacion_Financiera__c
 *   - FinServ__Employment__c (Historial Laboral)
 *   - FinServ__ContactContactRelation__c (Referencias) + Contact de referencia
 *
 * Last modified: 2026-05-14
 * Autor: Jhonny Peroza
 */
public without sharing class LeadConversionQueue implements Queueable {
  private Set<Id> leadIds;

  private static final String ACTION_PLAN_NAME = 'Seguimiento documentación cliente';
  private static final String ACTION_PLAN_TEMPLATE_NAME = 'Seguimiento de Entrega de Documentos';
  private static final String ACTION_PLAN_TYPE = 'Industries';
  private static final String ACTION_PLAN_STATE = 'No se ha iniciado';
  private static final String ACTION_PLAN_SCHEDULE_FREQUENCY = 'Ninguno';

  public LeadConversionQueue(Set<Id> leadIds) {
    this.leadIds = (leadIds == null) ? new Set<Id>() : new Set<Id>(leadIds);
  }

  public void execute(QueueableContext qc) {
    processLeads(leadIds);
  }

  public static void processLeads(Set<Id> leadIds) {
    System.debug('on LeadConversionQueue.processLeads() leadIds size: ' + (leadIds == null ? 0 : leadIds.size()));

    if (leadIds == null || leadIds.isEmpty())
      return;

    try {
      Id defaultContactRoleId = null;

      List<FinServ__ReciprocalRole__c> contactRoles = [
        SELECT Id
        FROM FinServ__ReciprocalRole__c
        WHERE RecordType.DeveloperName = 'ContactRole'
        LIMIT 1
      ];

      if (!contactRoles.isEmpty()) {
        defaultContactRoleId = contactRoles[0].Id;
      }

      Id ccrParticipanteRtId = null;

      List<RecordType> ccrRts = [
        SELECT Id
        FROM RecordType
        WHERE SObjectType = 'FinServ__ContactContactRelation__c'
        AND DeveloperName = 'Participante'
        LIMIT 1
      ];

      if (!ccrRts.isEmpty()) {
        ccrParticipanteRtId = ccrRts[0].Id;
      }

      List<Lead> leads = [
        SELECT
          Id,
          FirstName,
          MiddleName,
          LastName,
          Suffix,
          IsConverted,
          ConvertedAccountId,
          ConvertedContactId,
          RecordType.Name,
          Name,
          LEA_TipoIdentificacion__c,
          LEA_Nombre_Ejecutivo__c,
          LEA_NumIdentificacion__c,
          LEA_Nombre_Puesto__c,
          LEA_Nacionalidad__c,
          LEA_NumOficina__c,
          LEA_Zona__c,
          LEA_Tipo_Persona_PF__c,
          LEA_Resultado_Validacion__c,
          LEA_Tipo_Cliente_PF__c,
          LEA_Tipo_Sector__c,
          LEA_Tipo_Vinculacion__c,
          LEA_Actividad_Economica__c,
          LEA_Tipo_Actividad__c,
          Lugar_de_nacimiento_Padron_Electoral__c,
          LEA_EsEmpleado_Vimenca__c,
          LEA_EsEmpleado_GrupoVimenca__c,
          LEA_EmpresaGrupo__c,
          LEA_EsProveedor__c,
          LEA_Branch__c,
          LEA_Segmento__c,
          LEA_Cliente_Conocido__c,
          LEA_Calificacion_de_cliente__c,
          LEA_PersonBirthdate__c,
          LEA_Estado_Civil__c,
          LEA_Tipo_de_vivienda__c,
          Tiempo_en_Vivienda__c,
          LEA_Genero_Identificaci_n__c,
          LEA_Relacion_de_dignatarios__c,
          LEA_Pais_Nacimiento__c,
          LEA_Pais_Residencia_Legal__c,
          LEA_Genero__c,
          LEA_N_Identificacion_Anterior__c,
          LEA_Tipo_Identificacion_Anterior__c,
          LEA_Actividad_Economica_Name__c,
          LEA_Actividad_Economica_Direccion__c,
          LEA_Otra_Nacionalidad__c,
          LEA_Provincia_Nacimiento__c,
          LEA_Ciudad_de_nacimiento__c,
          LEA_Ciudad_Nacimiento_Codigo__c,
          LEA_Posee_Resid_Otro_Pais__c,
          LEA_Tipo_Depositante__c,
          LEA_Relacion_Exterior__c,
          LEA_Es_Mayor_de_Edad__c,
          LEA_Owner_Alias__c,
          LEA_CIF__c,
          LEA_Residencia_Rep_Dom__c,
          LEA_Fecha_Informacion__c,
          LEA_Total_Activos__c,
          LEA_Moneda__c,
          LEA_Ventas_Ingresos_Anuales__c,
          LEA_Patrimonio_Num__c,
          LEA_Fuente_Informacion__c,
          LEA_Patrimonio_Desc__c,
          LEA_Gastos_anuales__c,
          LEA_Volumen_Ventas_Anual__c,
          LEA_Nombre_Corto_Comercial__c,
          LEA_RNC__c,
          LEA_Fecha_Cierre_Fiscal__c,
          LEA_Tipo_Cliente_PJ__c,
          LEA_Clasificacion_Empresa__c,
          LEA_Fecha_Fundacion__c,
          ACC_Tipo_Persona_PJ__c,
          LEA_Tipo_Organizacion__c,
          LEA_NumEmpleado__c,
          LEA_Nombre_FATCA__c,
          LEA_Apellido_FATCA__c,
          LEA_Nacionalidad_FATCA__c,
          LEA_N_Pasaporte_FATCA__c,
          LEA_Estado_FATCA__c,
          LEA_Fecha_Expiracion_FATCA__c,
          LEA_SSN_FATCA__c,
          LEA_TIN_FATCA__c,
          LEA_Direccion_FATCA__c,
          LEA_Ciudad_FATCA__c,
          LEA_Telefono_FATCA__c,
          LEA_Codigo_Postal_FATCA__c,
          LEA_Aplica_FATCA__c,
          LEA_Tipo_Identif_PEP__c,
          LEA_N_Identificacion_PEP__c,
          LEA_N_Decreto_PEP__c,
          LEA_Fecha_Decreto_PEP__c,
          LEA_Tipo_Relacion_PEP__c,
          LEA_Nacionalidad_PEP__c,
          LEA_Primer_Nombre_PEP__c,
          LEA_Segundo_Nombre_PEP__c,
          LEA_Primer_Apellido_PEP__c,
          LEA_Segundo_Apellido_PEP__c,
          LEA_Ocupacion_PEP__c,
          LEA_Puesto_Cargo_PEP__c,
          LEA_Direccion_Trabajo_PEP__c,
          LEA_Institucion_Trabajo_PEP__c,
          LEA_Persona_PEP__c,
          LEA_Calle__c,
          LEA_Numero__c,
          LEA_Edificio__c,
          LEA_N_Apartamento__c,
          LEA_Pais__c,
          LEA_Provincia__c,
          LEA_Municipio__c,
          LEA_Distrito__c,
          LEA_Address_Sector__c,
          LEA_Apartado_postal__c,
          LEA_Estado_Ciudad__c,
          LEA_Referencia_Ubicacion__c,
          LEA_Direccion_SIEBEL__c,
          LEA_Via_de_Contacto1__c,
          LEA_Numero_Correo1__c,
          LEA_Telefonica1__c,
          LEA_Envio_SMS1__c,
          LEA_Principal1__c,
          LEA_Via_de_Contacto2__c,
          LEA_Numero_Correo2__c,
          LEA_Telefonica2__c,
          LEA_Envio_SMS2__c,
          LEA_Principal2__c,
          LEA_Via_de_Contacto3__c,
          LEA_Numero_Correo3__c,
          LEA_Telefonica3__c,
          LEA_Envio_SMS3__c,
          LEA_Principal3__c,
          LEA_Fuente_de_ingresos__c,
          LEA_Periodo__c,
          LEA_Ingresos__c,
          LEA_Otros_Ingresos__c,
          LEA_Descripci_n_otros_ingresos__c,
          LEA_Empresa__c,
          LEA_Puesto_de_trabajo__c,
          LEA_Ocupacion__c,
          LEA_Empleo_Actual_Anterior__c,
          LEA_Principal__c,
          LEA_Tipo_de_empleado__c,
          LEA_Tiempo_de_empresa__c,
          LEA_Fecha_de_ingreso__c,
          LEA_Fecha_de_fin__c,
          LEA_Salario__c,
          LEA_Direcci_n_de_la_empresa__c,
          LEA_Telefono_de_empresa__c,
          LEA_Correo_laboral__c,
          LEA_Tipo_Referencia1__c,
          LEA_Nombre_Referencia1__c,
          LEA_Telefono_Referencia1__c,
          LEA_RNC_Referencia1__c,
          LEA_Direccion_Referencia1__c,
          LEA_Pais_Referencia1__c,
          LEA_REF_Banco_1__c,
          LEA_REF_Tipo_de_Cuenta_1__c,
          LEA_REF_N_de_cuenta_1__c,
          LEA_REF_Moneda_1__c,
          LEA_Tipo_Referencia2__c,
          LEA_Nombre_Referencia2__c,
          LEA_Telefono_Referencia2__c,
          LEA_RNC_Referencia2__c,
          LEA_Direccion_Referencia2__c,
          LEA_Pais_Referencia2__c,
          LEA_REF_Banco_2__c,
          LEA_REF_Tipo_de_Cuenta_2__c,
          LEA_REF_N_de_cuenta_2__c,
          LEA_REF_Moneda_2__c,
          LEA_DeclaracionSiManejaOpInternacionales__c,
          LEA_Canales_a_utilizar__c,
          LEA_ProductosASolicitar__c,
          LEA_NoIndicaTipoMonedaProdTrans__c,
          LEA_IndicarVolMensualEstimadoTransaccion__c,
          LEA_DeclaracionSiProyectaManejarEfectivo__c,
          LEA_Tipo_beneficio_final__c,
          LEA_Servicios_a_solicitar__c
        FROM Lead
        WHERE Id IN :leadIds
      ];

      System.debug('LeadConversionQueue.execute() leads queried: ' + leads.size());

      Map<Id, List<Documentacion_Legal__c>> docsByLead = new Map<Id, List<Documentacion_Legal__c>>();

      List<Documentacion_Legal__c> docs = [
        SELECT
          Id,
          DOC_Candidato__c,
          DOC_Id_Externo__c,
          DOC_Codigo_Documento__c,
          DOC_Descripcion__c,
          DOC_Estado__c,
          DOC_Sub_Estado__c,
          DOC_Recibido__c,
          DOC_Fecha_Recepcion__c,
          DOC_Fecha_Recepcion_Legal__c,
          DOC_Fecha_Aprobacion_Legal__c,
          DOC_Fecha_Vencimiento__c,
          DOC_Aprobado_Por__c,
          DOC_Documento_PF__c,
          DOC_Documento_PJ__c,
          DOC_Documento_PF__r.ADR_Nombre_de_documento__c,
          DOC_Documento_PF__r.ADR_Requerido__c,
          DOC_Documento_PJ__r.ADR_Nombre_de_documento__c,
          DOC_Documento_PJ__r.ADR_Requerido__c
        FROM Documentacion_Legal__c
        WHERE DOC_Candidato__c IN :leadIds
      ];

      for (Documentacion_Legal__c d : docs) {
        if (d == null || d.DOC_Candidato__c == null)
          continue;

        if (!docsByLead.containsKey(d.DOC_Candidato__c))
          docsByLead.put(d.DOC_Candidato__c, new List<Documentacion_Legal__c>());

        docsByLead.get(d.DOC_Candidato__c).add(d);
      }

      Schema.DescribeSObjectResult dACC = safeDescribe('Account');
      Schema.DescribeSObjectResult dCPA = safeDescribe('ContactPointAddress');
      Schema.DescribeSObjectResult dCPP = safeDescribe('ContactPointPhone');
      Schema.DescribeSObjectResult dCPE = safeDescribe('ContactPointEmail');
      Schema.DescribeSObjectResult dINF = safeDescribe('Informacion_Financiera__c');
      Schema.DescribeSObjectResult dEMP = safeDescribe('FinServ__Employment__c');
      Schema.DescribeSObjectResult dCCR = safeDescribe('FinServ__ContactContactRelation__c');
      Schema.DescribeSObjectResult dAAR = safeDescribe('FinServ__AccountAccountRelation__c');
      Schema.DescribeSObjectResult dDCI = safeDescribe('DocumentChecklistItem');
      Schema.DescribeSObjectResult dAP = safeDescribe('ActionPlan');

      Boolean hasSourceExt = false;

      if (dDCI != null && dDCI.fields != null && dDCI.fields.getMap() != null) {
        hasSourceExt = dDCI.fields.getMap().containsKey('Source_External_Id__c');
      }

      List<Account> accountUpdates = new List<Account>();
      List<SObject> cpAddresses = new List<SObject>();
      List<SObject> cpPhones = new List<SObject>();
      List<SObject> cpEmails = new List<SObject>();
      List<SObject> finInfos = new List<SObject>();
      List<SObject> employments = new List<SObject>();
      List<SObject> finCCR = new List<SObject>();
      List<SObject> docChecklistItems = new List<SObject>();
      List<Id> documentacionLegalIdsByChecklistIndex = new List<Id>();
      List<SObject> actionPlans = new List<SObject>();
      Set<Id> accountsWithPendingDocs = new Set<Id>();
      Map<Id, List<String>> pendingDocNamesByAccount = new Map<Id, List<String>>();
      List<RefBundle> refBundles = new List<RefBundle>();

      for (Lead l : leads) {
        if (l == null || l.IsConverted != true)
          continue;

        Id accountId = l.ConvertedAccountId;
        Id contactId = l.ConvertedContactId;

        if (accountId == null && contactId == null)
          continue;

        if (dACC != null && accountId != null) {
          Account acc = new Account(Id = accountId);
          mapLeadDetailsToAccount(acc, dACC, l);
          System.debug('acc updated fields: ' + acc);
          accountUpdates.add(acc);
        }

        if (dCPA != null && accountId != null) {
          SObject cpa = Schema.getGlobalDescribe().get('ContactPointAddress').newSObject();

          String addressName = isPF(l) ? 'Dirección de residencia' : 'Dirección Empresarial';

          setIfFieldExists(cpa, dCPA, 'Name', addressName);
          setIfFieldExists(cpa, dCPA, 'FinServ__RelatedAccount__c', accountId);
          setIfFieldExists(cpa, dCPA, 'RelatedAccountId', accountId);
          setIfFieldExists(cpa, dCPA, 'AccountId', accountId);
          setIfFieldExists(cpa, dCPA, 'ParentId', accountId);

          String street1 = joinNotBlank(
            new List<String>{
              safeStr(l.get('LEA_Calle__c')),
              safeStr(l.get('LEA_Numero__c'))
            },
            ' '
          );

          String street2 = joinNotBlank(
            new List<String>{
              safeStr(l.get('LEA_Edificio__c')) != null ? ('Edif: ' + safeStr(l.get('LEA_Edificio__c'))) : null,
              safeStr(l.get('LEA_N_Apartamento__c')) != null ? ('Apto: ' + safeStr(l.get('LEA_N_Apartamento__c'))) : null
            },
            ' | '
          );

          setIfFieldExists(cpa, dCPA, 'AddressType', isPF(l) ? 'RESIDENCIA' : 'EMPRESARIAL');
          setIfFieldExists(cpa, dCPA, 'Street', joinNotBlank(new List<String>{ street1, street2 }, '\n'));
          setIfFieldExists(cpa, dCPA, 'CPA_Municipio__c', safeStr(l.get('LEA_Municipio__c')));
          setIfFieldExists(cpa, dCPA, 'State', safeStr(l.get('LEA_Provincia__c')));
          setIfFieldExists(cpa, dCPA, 'PostalCode', safeStr(l.get('LEA_Apartado_postal__c')));
          setIfFieldExists(cpa, dCPA, 'Country', safeStr(l.get('LEA_Pais__c')));
          setIfFieldExists(cpa, dCPA, 'CPA_Distrito__c', safeStr(l.get('LEA_Distrito__c')));
          setIfFieldExists(cpa, dCPA, 'CPA_Sector__c', safeStr(l.get('LEA_Address_Sector__c')));
          setIfFieldExists(cpa, dCPA, 'CPA_Referencia_Ubicacion__c', safeStr(l.get('LEA_Referencia_Ubicacion__c')));
          setIfFieldExists(cpa, dCPA, 'Direccion_SIEBEL__c', safeStr(l.get('LEA_Direccion_SIEBEL__c')));
          setIfFieldExists(cpa, dCPA, 'IsPrimary', true);

          cpAddresses.add(cpa);
        }

        buildContactPointsFromSlot(dCPP, dCPE, cpPhones, cpEmails, accountId, contactId, safeStr(l.get('LEA_Via_de_Contacto1__c')), safeStr(l.get('LEA_Numero_Correo1__c')), toBool(l.get('LEA_Telefonica1__c')), (Boolean) l.get('LEA_Envio_SMS1__c'), (Boolean) l.get('LEA_Principal1__c'), safeStr(l.get('LEA_Telefonica1__c')));
        buildContactPointsFromSlot(dCPP, dCPE, cpPhones, cpEmails, accountId, contactId, safeStr(l.get('LEA_Via_de_Contacto2__c')), safeStr(l.get('LEA_Numero_Correo2__c')), toBool(l.get('LEA_Telefonica2__c')), (Boolean) l.get('LEA_Envio_SMS2__c'), (Boolean) l.get('LEA_Principal2__c'), safeStr(l.get('LEA_Telefonica2__c')));
        buildContactPointsFromSlot(dCPP, dCPE, cpPhones, cpEmails, accountId, contactId, safeStr(l.get('LEA_Via_de_Contacto3__c')), safeStr(l.get('LEA_Numero_Correo3__c')), toBool(l.get('LEA_Telefonica3__c')), (Boolean) l.get('LEA_Envio_SMS3__c'), (Boolean) l.get('LEA_Principal3__c'), safeStr(l.get('LEA_Telefonica3__c')));

        if (dINF != null && accountId != null) {
          SObject inf = Schema.getGlobalDescribe().get('Informacion_Financiera__c').newSObject();

          setIfFieldExists(inf, dINF, 'INF_Cuenta__c', accountId);
          setIfFieldExists(inf, dINF, 'Account__c', accountId);
          setIfFieldExists(inf, dINF, 'Cliente__c', accountId);
          setIfFieldExists(inf, dINF, 'FinServ__RelatedAccount__c', accountId);
          setIfFieldExists(inf, dINF, 'INF_Fuente_de_ingresos__c', safeStr(l.get('LEA_Fuente_de_ingresos__c')));
          setIfFieldExists(inf, dINF, 'INF_Periodo__c', safeStr(l.get('LEA_Periodo__c')));
          setIfFieldExists(inf, dINF, 'INF_Ingresos__c', l.get('LEA_Ingresos__c'));
          setIfFieldExists(inf, dINF, 'Otros_Ingresos__c', l.get('LEA_Otros_Ingresos__c'));
          setIfFieldExists(inf, dINF, 'Descripci_n_otros_ingresos__c', safeStr(l.get('LEA_Descripci_n_otros_ingresos__c')));

          finInfos.add(inf);
        }

        if (dEMP != null && (accountId != null || contactId != null)) {
          SObject emp = Schema.getGlobalDescribe().get('FinServ__Employment__c').newSObject();

          if (contactId != null) {
            setIfFieldExists(emp, dEMP, 'FinServ__Contact__c', contactId);
            setIfFieldExists(emp, dEMP, 'Contact__c', contactId);
          }

          if (accountId != null) {
            setIfFieldExists(emp, dEMP, 'FinServ__RelatedAccount__c', accountId);
            setIfFieldExists(emp, dEMP, 'Cliente__c', accountId);
          }

          setIfFieldExists(emp, dEMP, 'Name', safeStr(l.get('LEA_Empresa__c')));
          setIfFieldExists(emp, dEMP, 'EMP_Empresa__c', safeStr(l.get('LEA_Empresa__c')));
          setIfFieldExists(emp, dEMP, 'FinServ__Position__c', safeStr(l.get('LEA_Puesto_de_trabajo__c')));
          setIfFieldExists(emp, dEMP, 'FinServ__Occupation__c', safeStr(l.get('LEA_Ocupacion__c')));
          setIfFieldExists(emp, dEMP, 'EMP_Empleo__c', safeStr(l.get('LEA_Empleo_Actual_Anterior__c')));
          setIfFieldExists(emp, dEMP, 'EMP_Principal__c', (Boolean) l.get('LEA_Principal__c'));
          setIfFieldExists(emp, dEMP, 'EMP_Tipo_de_empleado__c', safeStr(l.get('LEA_Tipo_de_empleado__c')));
          setIfFieldExists(emp, dEMP, 'FinServ__StartDate__c', l.get('LEA_Fecha_de_ingreso__c'));
          setIfFieldExists(emp, dEMP, 'FinServ__EndDate__c', l.get('LEA_Fecha_de_fin__c'));
          setIfFieldExists(emp, dEMP, 'FinServ__AnnualIncome__c', l.get('LEA_Salario__c'));
          setIfFieldExists(emp, dEMP, 'FinServ__EmployerAddress__c', safeStr(l.get('LEA_Direcci_n_de_la_empresa__c')));
          setIfFieldExists(emp, dEMP, 'FinServ__EmployerPhoneNumber__c', safeStr(l.get('LEA_Telefono_de_empresa__c')));

          employments.add(emp);
        }

        if (dCCR != null && contactId != null) {
          addReferenceBundle(
            refBundles,
            dCCR,
            contactId,
            defaultContactRoleId,
            safeStr(l.get('LEA_Tipo_Referencia1__c')),
            safeStr(l.get('LEA_Nombre_Referencia1__c')),
            safeStr(l.get('LEA_Telefono_Referencia1__c')),
            safeStr(l.get('LEA_RNC_Referencia1__c')),
            safeStr(l.get('LEA_Direccion_Referencia1__c')),
            safeStr(l.get('LEA_Pais_Referencia1__c')),
            safeStr(l.get('LEA_REF_Banco_1__c')),
            safeStr(l.get('LEA_REF_Tipo_de_Cuenta_1__c')),
            safeStr(l.get('LEA_REF_N_de_cuenta_1__c')),
            safeStr(l.get('LEA_REF_Moneda_1__c'))
          );

          addReferenceBundle(
            refBundles,
            dCCR,
            contactId,
            defaultContactRoleId,
            safeStr(l.get('LEA_Tipo_Referencia2__c')),
            safeStr(l.get('LEA_Nombre_Referencia2__c')),
            safeStr(l.get('LEA_Telefono_Referencia2__c')),
            safeStr(l.get('LEA_RNC_Referencia2__c')),
            safeStr(l.get('LEA_Direccion_Referencia2__c')),
            safeStr(l.get('LEA_Pais_Referencia2__c')),
            safeStr(l.get('LEA_REF_Banco_2__c')),
            safeStr(l.get('LEA_REF_Tipo_de_Cuenta_2__c')),
            safeStr(l.get('LEA_REF_N_de_cuenta_2__c')),
            safeStr(l.get('LEA_REF_Moneda_2__c'))
          );
        }

        if (dAAR != null && accountId != null) {
          List<Participante__c> participants = [
            SELECT
              PAR_Cargo__c,
              PAR_Tipo__c,
              PAR_Porcentaje__c,
              VFS_FirmanteConozcaCliente__c,
              VFS_FirmanteDeContratoAutorizado__c,
              VFS_FirmanteAutorizado__c,
              VFS_RepresentanteLegal__c,
              Participante__c,
              Participante__r.RecordType.DeveloperName
            FROM Participante__c
            WHERE PAR_Candidato__c = :l.Id
          ];

          for (Participante__c p : participants) {
            SObject ccr = Schema.getGlobalDescribe().get('FinServ__ContactContactRelation__c').newSObject();

            if (p.Participante__c != null) {
              Contact contact = [
                SELECT Id, Name, LastName, RecordType.DeveloperName
                FROM Contact
                WHERE AccountId = :p.Participante__c
                LIMIT 1
              ];

              setIfFieldExists(ccr, dCCR, 'FinServ__Role__c', defaultContactRoleId);
              setIfFieldExists(ccr, dCCR, 'FinServ__Contact__c', contactId);
              setIfFieldExists(ccr, dCCR, 'Contact__c', contactId);
              setIfFieldExists(ccr, dCCR, 'FinServ__RelatedContact__c', contact.Id);
              setIfFieldExists(ccr, dCCR, 'CCR_Cargo__c', p.PAR_Cargo__c);
              setIfFieldExists(ccr, dCCR, 'CCR_Tipo_Accionista__c', p.PAR_Tipo__c);
              setIfFieldExists(ccr, dCCR, 'CCR_Porcentaje__c', p.PAR_Porcentaje__c);
              setIfFieldExists(ccr, dCCR, 'CCR_FirmanteConozcaCliente__c', p.VFS_FirmanteConozcaCliente__c);
              setIfFieldExists(ccr, dCCR, 'CCR_FirmanteDeContratoAutorizado__c', p.VFS_FirmanteDeContratoAutorizado__c);
              setIfFieldExists(ccr, dCCR, 'CCR_FirmanteAutorizado__c', p.VFS_FirmanteAutorizado__c);
              setIfFieldExists(ccr, dCCR, 'CCR_RepresentanteLegal__c', p.VFS_RepresentanteLegal__c);

              if (ccrParticipanteRtId != null) {
                ccr.put('RecordTypeId', ccrParticipanteRtId);
              }

              finCCR.add(ccr);
            }
          }
        }

        if (dDCI != null && accountId != null) {
          List<Documentacion_Legal__c> myDocs = docsByLead.get(l.Id);

          if (myDocs != null && !myDocs.isEmpty()) {
            Boolean pf = isPF(l);

            for (Documentacion_Legal__c doc : myDocs) {
              if (doc == null)
                continue;

              SObject adr = null;

              if (pf && doc.DOC_Documento_PF__c != null) {
                adr = doc.getSObject('DOC_Documento_PF__r');
              } else if (!pf && doc.DOC_Documento_PJ__c != null) {
                adr = doc.getSObject('DOC_Documento_PJ__r');
              }

              String docName = null;
              Boolean required = true;

              if (adr != null) {
                docName = safeStr(adr.get('ADR_Nombre_de_documento__c'));
                Object reqVal = adr.get('ADR_Requerido__c');

                if (reqVal != null)
                  required = (Boolean) reqVal;
              }

              if (String.isBlank(docName)) {
                docName = String.isBlank(doc.DOC_Codigo_Documento__c) ? 'Documento Legal' : ('Documento ' + doc.DOC_Codigo_Documento__c);
              }

              SObject dci = Schema.getGlobalDescribe().get('DocumentChecklistItem').newSObject();

              setIfFieldExists(dci, dDCI, 'AccountId', accountId);
              setIfFieldExists(dci, dDCI, 'Name', (docName.length() > 255) ? docName.substring(0, 255) : docName);
              setIfFieldExists(dci, dDCI, 'IsRequired', required);

              String docStatus = safeStr(doc.DOC_Estado__c);

              if (!String.isBlank(docStatus)) {
                setIfFieldExists(dci, dDCI, 'Status', docStatus);
              }

              if (!String.isBlank(docStatus) && docStatus.equalsIgnoreCase('PENDIENTE')) {
                accountsWithPendingDocs.add(accountId);

                if (!pendingDocNamesByAccount.containsKey(accountId)) {
                  pendingDocNamesByAccount.put(accountId, new List<String>());
                }

                pendingDocNamesByAccount.get(accountId).add(docName);

                System.debug('LeadConversionQueue pending document detected. accountId=' + accountId + ', leadId=' + l.Id + ', documentName=' + docName + ', status=' + docStatus);
              }

              setIfFieldExists(dci, dDCI, 'ParentRecordId', accountId);
              System.debug('LeadConversionQueue DocumentChecklistItem ParentRecordId set. accountId=' + accountId + ', leadId=' + l.Id + ', documentName=' + docName);

              setIfFieldExists(dci, dDCI, 'Instruction', doc.DOC_Descripcion__c);
              setIfFieldExists(dci, dDCI, 'DCI_Aprobado_Por__c', doc.DOC_Aprobado_Por__c);
              setIfFieldExists(dci, dDCI, 'DCI_Fecha_Aprobacion_Legal__c', doc.DOC_Fecha_Aprobacion_Legal__c);
              setIfFieldExists(dci, dDCI, 'DCI_Fecha_Vencimiento__c', doc.DOC_Fecha_Vencimiento__c);

              if (contactId != null) {
                setIfFieldExists(dci, dDCI, 'WhoId', contactId);
              }

              if (hasSourceExt) {
                String sourceKey = String.isBlank(doc.DOC_Id_Externo__c) ? String.valueOf(doc.Id) : doc.DOC_Id_Externo__c.trim();
                setIfFieldExists(dci, dDCI, 'Source_External_Id__c', sourceKey);
              }

              docChecklistItems.add(dci);
              documentacionLegalIdsByChecklistIndex.add(doc.Id);
            }
          }
        }
      }

      if (!accountUpdates.isEmpty()) {
        update accountUpdates;
      }

      insertInChunks(cpAddresses, 200, 'ContactPointAddress');
      insertInChunks(cpPhones, 200, 'ContactPointPhone');
      insertInChunks(cpEmails, 200, 'ContactPointEmail');
      insertInChunks(finInfos, 200, 'Informacion_Financiera__c');
      insertInChunks(employments, 200, 'FinServ__Employment__c');
      insertInChunks(finCCR, 200, 'FinServ__ContactContactRelation__c');

      if (hasSourceExt && dDCI != null && docChecklistItems != null && !docChecklistItems.isEmpty()) {
        Set<Id> accIds = new Set<Id>();
        Set<String> sourceKeys = new Set<String>();

        for (SObject s : docChecklistItems) {
          Id a = (Id) s.get('AccountId');
          String k = (String) s.get('Source_External_Id__c');

          if (a != null)
            accIds.add(a);

          if (!String.isBlank(k))
            sourceKeys.add(k.trim());
        }

        Map<String, Boolean> existing = new Map<String, Boolean>();

        if (!accIds.isEmpty() && !sourceKeys.isEmpty()) {
          List<SObject> existingItems = Database.query(
            'SELECT Id, AccountId, Source_External_Id__c ' +
            'FROM DocumentChecklistItem ' +
            'WHERE AccountId IN :accIds ' +
            'AND Source_External_Id__c IN :sourceKeys'
          );

          for (SObject ei : existingItems) {
            Id a = (Id) ei.get('AccountId');
            String k = (String) ei.get('Source_External_Id__c');

            if (a != null && !String.isBlank(k)) {
              existing.put(String.valueOf(a) + '|' + k.trim(), true);
            }
          }
        }

        List<SObject> filtered = new List<SObject>();
        List<Id> filteredDocIds = new List<Id>();

        for (Integer i = 0; i < docChecklistItems.size(); i++) {
          SObject s2 = docChecklistItems[i];
          Id a2 = (Id) s2.get('AccountId');
          String k2 = (String) s2.get('Source_External_Id__c');

          if (a2 == null || String.isBlank(k2))
            continue;

          String key = String.valueOf(a2) + '|' + k2.trim();

          if (!existing.containsKey(key)) {
            filtered.add(s2);

            if (i < documentacionLegalIdsByChecklistIndex.size()) {
              filteredDocIds.add(documentacionLegalIdsByChecklistIndex[i]);
            }
          }
        }

        docChecklistItems = filtered;
        documentacionLegalIdsByChecklistIndex = filteredDocIds;
      }

      insertInChunks(docChecklistItems, 200, 'DocumentChecklistItem');
      linkContentDocumentsToChecklistItems(documentacionLegalIdsByChecklistIndex, docChecklistItems);

      buildActionPlansForPendingDocs(dAP, accountsWithPendingDocs, actionPlans);
      insertInChunks(actionPlans, 200, 'ActionPlan');

      List<Task> actionPlanTasks = buildTasksForPendingDocuments(pendingDocNamesByAccount);
      insertTaskInChunks(actionPlanTasks, 200);

      if (!refBundles.isEmpty()) {
        List<Contact> refContacts = new List<Contact>();

        for (RefBundle b : refBundles) {
          refContacts.add(b.refContact);
        }

        insertInChunksContacts(refContacts, 200);

        for (Integer i = 0; i < refBundles.size(); i++) {
          RefBundle b = refBundles[i];

          if (b == null)
            continue;

          Id refContactId = refContacts[i].Id;

          if (refContactId == null)
            continue;

          if (b.relDescribe != null) {
            setIfFieldExists(b.relation, b.relDescribe, 'FinServ__RelatedContact__c', refContactId);
            setIfFieldExists(b.relation, b.relDescribe, 'RelatedContact__c', refContactId);
          }
        }

        List<SObject> relations = new List<SObject>();

        for (RefBundle b2 : refBundles) {
          relations.add(b2.relation);
        }

        insertInChunks(relations, 200, 'FinServ__ContactContactRelation__c');
      }
    } catch (Exception e) {
      System.debug('ERROR LeadConversionQueue.execute: ' + e.getMessage());
      System.debug(e.getStackTraceString());
      throw e;
    }
  }

  private class LeadConversionDebugException extends Exception {
  }

  private class RefBundle {
    public Contact refContact;
    public SObject relation;
    public Schema.DescribeSObjectResult relDescribe;

    public RefBundle(Contact c, SObject r, Schema.DescribeSObjectResult d) {
      this.refContact = c;
      this.relation = r;
      this.relDescribe = d;
    }
  }

  private static String normalizePicklistValue(Schema.DescribeSObjectResult describeResult, String fieldApiName, String inputValue) {
    System.debug('LeadConversionQueue.normalizePicklistValue() fieldApiName=' + fieldApiName + ', inputValue=' + inputValue);

    if (describeResult == null || String.isBlank(fieldApiName) || String.isBlank(inputValue)) {
      return inputValue;
    }

    try {
      Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();

      if (fieldsMap == null || !fieldsMap.containsKey(fieldApiName)) {
        return inputValue;
      }

      Schema.DescribeFieldResult fieldDescribe = fieldsMap.get(fieldApiName).getDescribe();
      String inputNormalized = normalizeForCompare(inputValue);

      for (Schema.PicklistEntry pe : fieldDescribe.getPicklistValues()) {
        if (pe == null || !pe.isActive()) {
          continue;
        }

        String valueNormalized = normalizeForCompare(pe.getValue());
        String labelNormalized = normalizeForCompare(pe.getLabel());

        if (inputNormalized == valueNormalized || inputNormalized == labelNormalized) {
          System.debug(
            'LeadConversionQueue.normalizePicklistValue() match encontrado. field=' + fieldApiName +
            ', input=' + inputValue +
            ', value=' + pe.getValue() +
            ', label=' + pe.getLabel()
          );

          return pe.getValue();
        }
      }

      System.debug(
        LoggingLevel.WARN,
        'LeadConversionQueue.normalizePicklistValue() no encontró match activo. field=' + fieldApiName +
        ', inputValue=' + inputValue
      );

      return inputValue;

    } catch (Exception e) {
      System.debug(
        LoggingLevel.WARN,
        'LeadConversionQueue.normalizePicklistValue() ERROR field=' + fieldApiName +
        ', inputValue=' + inputValue +
        ', msg=' + e.getMessage()
      );

      return inputValue;
    }
  }

  private static String normalizeForCompare(String value) {
    if (String.isBlank(value)) {
      return null;
    }

    String normalized = value.trim().toUpperCase();

    normalized = normalized.replace('Á', 'A');
    normalized = normalized.replace('É', 'E');
    normalized = normalized.replace('Í', 'I');
    normalized = normalized.replace('Ó', 'O');
    normalized = normalized.replace('Ú', 'U');
    normalized = normalized.replace('Ü', 'U');
    normalized = normalized.replace('Ñ', 'N');

    while (normalized.contains('  ')) {
      normalized = normalized.replace('  ', ' ');
    }

    return normalized;
  }

  private static void mapLeadDetailsToAccount(Account acc, Schema.DescribeSObjectResult dACC, Lead l) {
    if (acc == null || dACC == null || l == null)
      return;

    setIfFieldExists(acc, dACC, 'FinServ__Status__c', safeStr('CREADO'));
    setIfFieldExists(acc, dACC, 'ACC_Condicion__c', safeStr('CLIENTE'));
    setIfFieldExists(acc, dACC, 'ACC_CIF__c', safeStr(l.get('LEA_CIF__c')));
    setIfFieldExists(acc, dACC, 'ACC_TipoIdentificacion__c', safeStr(l.get('LEA_TipoIdentificacion__c')));
    setIfFieldExists(acc, dACC, 'ACC_Nombre_Ejecutivo__c', safeStr(l.get('LEA_Nombre_Ejecutivo__c')));
    setIfFieldExists(acc, dACC, 'ACC_NumIdentificacion__c', safeStr(l.get('LEA_NumIdentificacion__c')));
    setIfFieldExists(acc, dACC, 'ACC_Nombre_Puesto__c', safeStr(l.get('LEA_Nombre_Puesto__c')));
    setIfFieldExists(acc, dACC, 'ACC_Nacionalidad__c', safeStr(l.get('LEA_Nacionalidad__c')));
    setIfFieldExists(acc, dACC, 'ACC_NumOficina__c', safeStr(l.get('LEA_NumOficina__c')));
    setIfFieldExists(acc, dACC, 'ACC_Zona__c', safeStr(l.get('LEA_Zona__c')));
    setIfFieldExists(acc, dACC, 'ACC_Genero_Identificaci_n__c', safeStr(l.get('LEA_Genero_Identificaci_n__c')));
    setIfFieldExists(acc, dACC, 'ACC_Genero__c', safeStr(l.get('LEA_Genero__c')));
    setIfFieldExists(acc, dACC, 'ACC_Tipo_Persona_PF__c', safeStr(l.get('LEA_Tipo_Persona_PF__c')));
    setIfFieldExists(acc, dACC, 'ACC_Resultado_Validacion__c', safeStr(l.get('LEA_Resultado_Validacion__c')));
    setIfFieldExists(acc, dACC, 'ACC_Tipo_Cliente_PF__c', safeStr(l.get('LEA_Tipo_Cliente_PF__c')));
    setIfFieldExists(acc, dACC, 'ACC_Tipo_Sector__c', safeStr(l.get('LEA_Tipo_Sector__c')));
    setIfFieldExists(acc, dACC, 'ACC_Tipo_Vinculacion__c', safeStr(l.get('LEA_Tipo_Vinculacion__c')));
    setIfFieldExists(acc, dACC, 'ACC_Actividad_Economica__c', safeStr(l.get('LEA_Actividad_Economica__c')));
    setIfFieldExists(acc, dACC, 'ACC_Tipo_Actividad__c', safeStr(l.get('LEA_Tipo_Actividad__c')));
    setIfFieldExists(acc, dACC, 'Lugar_de_nacimiento_Padron_Electoral__c', safeStr(l.get('Lugar_de_nacimiento_Padron_Electoral__c')));
    setIfFieldExists(acc, dACC, 'ACC_EsEmpleado_Vimenca__c', l.get('LEA_EsEmpleado_Vimenca__c'));
    setIfFieldExists(acc, dACC, 'ACC_Es_empleado_grupo_Vimenca__c', l.get('LEA_EsEmpleado_GrupoVimenca__c'));
    setIfFieldExists(acc, dACC, 'ACC_Empresa_Grupo__c', l.get('LEA_EmpresaGrupo__c'));
    setIfFieldExists(acc, dACC, 'ACC_Es_Proveedor__c', l.get('LEA_EsProveedor__c'));
    setIfFieldExists(acc, dACC, 'ACC_Branch__c', l.get('LEA_Branch__c'));
    setIfFieldExists(acc, dACC, 'ACC_Segmento__c', safeStr(l.get('LEA_Segmento__c')));
    setIfFieldExists(acc, dACC, 'ACC_Cliente_Conocido__c', l.get('LEA_Cliente_Conocido__c'));
    setIfFieldExists(acc, dACC, 'ACC_Calificacion_de_cliente__c', safeStr(l.get('LEA_Calificacion_de_cliente__c')));
    setIfFieldExists(acc, dACC, 'PersonBirthdate', l.get('LEA_PersonBirthdate__c'));
    setIfFieldExists(acc, dACC, 'ACC_Estado_Civil__c', safeStr(l.get('LEA_Estado_Civil__c')));
    setIfFieldExists(acc, dACC, 'Tipo_de_vivienda__c', safeStr(l.get('LEA_Tipo_de_vivienda__c')));
    setIfFieldExists(acc, dACC, 'Tiempo_en_Vivienda__c', safeStr(l.get('Tiempo_en_Vivienda__c')));
    setIfFieldExists(acc, dACC, 'ACC_Relacion_de_dignatarios__c', safeStr(l.get('LEA_Relacion_de_dignatarios__c')));
    setIfFieldExists(acc, dACC, 'ACC_N_Identificacion_Anterior__c', safeStr(l.get('LEA_N_Identificacion_Anterior__c')));
    setIfFieldExists(acc, dACC, 'ACC_Tipo_Identificacion_Anterior__c', safeStr(l.get('LEA_Tipo_Identificacion_Anterior__c')));
    Boolean poseeResidenciaOtroPais = (Boolean) l.get('LEA_Posee_Resid_Otro_Pais__c');

    setIfFieldExists(acc, dACC, 'ACC_Posee_Resid_Otro_Pais__c', poseeResidenciaOtroPais);
    setIfFieldExists(acc, dACC, 'ACC_Tipo_Depositante__c', safeStr(l.get('LEA_Tipo_Depositante__c')));
    setIfFieldExists(acc, dACC, 'ACC_Relacion_Exterior__c', safeStr(l.get('LEA_Relacion_Exterior__c')));
    setIfFieldExists(acc, dACC, 'ACC_Residencia_Rep_Dom__c', safeStr(l.get('LEA_Residencia_Rep_Dom__c')));
    setIfFieldExists(acc, dACC, 'ACC_Ciudad_Nacimiento_Codigo__c', safeStr(l.get('LEA_Ciudad_Nacimiento_Codigo__c')));
    setIfFieldExists(acc, dACC, 'ACC_Provincia_Nacimiento__c', safeStr(l.get('LEA_Provincia_Nacimiento__c')));
    setIfFieldExists(acc, dACC, 'ACC_Ciudad_de_nacimiento__c', safeStr(l.get('LEA_Ciudad_de_nacimiento__c')));
    setIfFieldExists(acc, dACC, 'ACC_Pais_Nacimiento__c', safeStr(l.get('LEA_Pais_Nacimiento__c')));

    String paisResidenciaLegal = safeStr(l.get('LEA_Pais_Residencia_Legal__c'));

    if (poseeResidenciaOtroPais == false) {
      paisResidenciaLegal = 'REPUBLICA DOMINICANA';
    }

    paisResidenciaLegal = normalizePicklistValue(dACC, 'ACC_Pais_Residencia_Legal__c', paisResidenciaLegal);

    System.debug('LeadConversionQueue.mapLeadDetailsToAccount() LEA_Posee_Resid_Otro_Pais__c=' + poseeResidenciaOtroPais);
    System.debug('LeadConversionQueue.mapLeadDetailsToAccount() ACC_Pais_Residencia_Legal__c normalizado=' + paisResidenciaLegal);

    setIfFieldExists(acc, dACC, 'ACC_Pais_Residencia_Legal__c', paisResidenciaLegal);
    setIfFieldExists(acc, dACC, 'ACC_Otra_Nacionalidad__c', safeStr(l.get('LEA_Otra_Nacionalidad__c')));
    setIfFieldExists(acc, dACC, 'ACC_Fecha_Informacion__c', l.get('LEA_Fecha_Informacion__c'));
    setIfFieldExists(acc, dACC, 'ACC_Total_Activos__c', l.get('LEA_Total_Activos__c'));
    setIfFieldExists(acc, dACC, 'ACC_Moneda__c', safeStr(l.get('LEA_Moneda__c')));
    setIfFieldExists(acc, dACC, 'ACC_Ventas_Ingresos_Anuales__c', l.get('LEA_Ventas_Ingresos_Anuales__c'));
    setIfFieldExists(acc, dACC, 'ACC_Patrimonio_Num__c', l.get('LEA_Patrimonio_Num__c'));
    setIfFieldExists(acc, dACC, 'ACC_NumEmpleados__c', l.get('LEA_NumEmpleado__c'));
    setIfFieldExists(acc, dACC, 'ACC_Fuente_Informacion__c', l.get('LEA_Fuente_Informacion__c'));
    setIfFieldExists(acc, dACC, 'ACC_Patrimonio_Desc__c', l.get('LEA_Patrimonio_Desc__c'));
    setIfFieldExists(acc, dACC, 'ACC_Nombre_Corto_Comercial__c', safeStr(l.get('LEA_Nombre_Corto_Comercial__c')));
    setIfFieldExists(acc, dACC, 'ACC_RNC__c', safeStr(l.get('LEA_RNC__c')));
    setIfFieldExists(acc, dACC, 'ACC_Fecha_Cierre_Fiscal__c', l.get('LEA_Fecha_Cierre_Fiscal__c'));
    setIfFieldExists(acc, dACC, 'ACC_Tipo_Cliente_PJ__c', safeStr(l.get('LEA_Tipo_Cliente_PJ__c')));
    setIfFieldExists(acc, dACC, 'ACC_Clasificacion_Empresa__c', safeStr(l.get('LEA_Clasificacion_Empresa__c')));
    setIfFieldExists(acc, dACC, 'ACC_Fecha_Fundacion__c', l.get('LEA_Fecha_Fundacion__c'));
    setIfFieldExists(acc, dACC, 'ACC_Tipo_Persona_PJ__c', safeStr(l.get('ACC_Tipo_Persona_PJ__c')));
    setIfFieldExists(acc, dACC, 'ACC_Tipo_Organizacion__c', safeStr(l.get('LEA_Tipo_Organizacion__c')));
    setIfFieldExists(acc, dACC, 'Gastos_anuales__c', l.get('LEA_Gastos_anuales__c'));
    setIfFieldExists(acc, dACC, 'ACC_Volumen_Ventas_Anual__c', l.get('LEA_Volumen_Ventas_Anual__c'));
    setIfFieldExists(acc, dACC, 'ACC_Nombre_FATCA__c', safeStr(l.get('LEA_Nombre_FATCA__c')));
    setIfFieldExists(acc, dACC, 'ACC_Apellido_FATCA__c', safeStr(l.get('LEA_Apellido_FATCA__c')));
    setIfFieldExists(acc, dACC, 'ACC_Nacionalidad_FATCA__c', safeStr(l.get('LEA_Nacionalidad_FATCA__c')));
    setIfFieldExists(acc, dACC, 'ACC_N_Pasaporte_FATCA__c', safeStr(l.get('LEA_N_Pasaporte_FATCA__c')));
    setIfFieldExists(acc, dACC, 'ACC_Estado_FATCA__c', safeStr(l.get('LEA_Estado_FATCA__c')));
    setIfFieldExists(acc, dACC, 'ACC_Fecha_Expiracion_FATCA__c', l.get('LEA_Fecha_Expiracion_FATCA__c'));
    setIfFieldExists(acc, dACC, 'ACC_SSN_FATCA__c', safeStr(l.get('LEA_SSN_FATCA__c')));
    setIfFieldExists(acc, dACC, 'ACC_TIN_FATCA__c', safeStr(l.get('LEA_TIN_FATCA__c')));
    setIfFieldExists(acc, dACC, 'ACC_Direccion_FATCA__c', safeStr(l.get('LEA_Direccion_FATCA__c')));
    setIfFieldExists(acc, dACC, 'ACC_Ciudad_FATCA__c', safeStr(l.get('LEA_Ciudad_FATCA__c')));
    setIfFieldExists(acc, dACC, 'ACC_Telefono_FATCA__c', safeStr(l.get('LEA_Telefono_FATCA__c')));
    setIfFieldExists(acc, dACC, 'ACC_Codigo_Postal_FATCA__c', safeStr(l.get('LEA_Codigo_Postal_FATCA__c')));
    setIfFieldExists(acc, dACC, 'ACC_Aplica_FATCA__c', l.get('LEA_Aplica_FATCA__c'));
    setIfFieldExists(acc, dACC, 'ACC_Persona_PEP__c', safeStr(l.get('LEA_Persona_PEP__c')));
    setIfFieldExists(acc, dACC, 'ACC_Tipo_Identif_PEP__c', safeStr(l.get('LEA_Tipo_Identif_PEP__c')));
    setIfFieldExists(acc, dACC, 'ACC_N_Identificacion_PEP__c', safeStr(l.get('LEA_N_Identificacion_PEP__c')));
    setIfFieldExists(acc, dACC, 'ACC_N_Decreto_PEP__c', safeStr(l.get('LEA_N_Decreto_PEP__c')));
    setIfFieldExists(acc, dACC, 'ACC_Fecha_Decreto_PEP__c', l.get('LEA_Fecha_Decreto_PEP__c'));
    setIfFieldExists(acc, dACC, 'ACC_Tipo_Relacion_PEP__c', safeStr(l.get('LEA_Tipo_Relacion_PEP__c')));
    setIfFieldExists(acc, dACC, 'ACC_Nacionalidad_PEP__c', safeStr(l.get('LEA_Nacionalidad_PEP__c')));
    setIfFieldExists(acc, dACC, 'ACC_Primer_Nombre_PEP__c', safeStr(l.get('LEA_Primer_Nombre_PEP__c')));
    setIfFieldExists(acc, dACC, 'ACC_Segundo_Nombre_PEP__c', safeStr(l.get('LEA_Segundo_Nombre_PEP__c')));
    setIfFieldExists(acc, dACC, 'ACC_Primer_Apellido_PEP__c', safeStr(l.get('LEA_Primer_Apellido_PEP__c')));
    setIfFieldExists(acc, dACC, 'ACC_Segundo_Apellido_PEP__c', safeStr(l.get('LEA_Segundo_Apellido_PEP__c')));
    setIfFieldExists(acc, dACC, 'ACC_Ocupacion_PEP__c', safeStr(l.get('LEA_Ocupacion_PEP__c')));
    setIfFieldExists(acc, dACC, 'ACC_Puesto_Cargo_PEP__c', safeStr(l.get('LEA_Puesto_Cargo_PEP__c')));
    setIfFieldExists(acc, dACC, 'ACC_Direccion_Trabajo_PEP__c', safeStr(l.get('LEA_Direccion_Trabajo_PEP__c')));
    setIfFieldExists(acc, dACC, 'ACC_Institucion_Trabajo_PEP__c', safeStr(l.get('LEA_Institucion_Trabajo_PEP__c')));
    setIfFieldExists(acc, dACC, 'ACC_DeclaracionSiManejaOpInternacionales__c', l.get('LEA_DeclaracionSiManejaOpInternacionales__c'));
    setIfFieldExists(acc, dACC, 'ACC_Canales_a_utilizar__c', safeStr(l.get('LEA_Canales_a_utilizar__c')));
    setIfFieldExists(acc, dACC, 'ACC_ProductosASolicitar__c', safeStr(l.get('LEA_ProductosASolicitar__c')));
    setIfFieldExists(acc, dACC, 'ACC_NoIndicaTipoMonedaProdTrans__c', safeStr(l.get('LEA_NoIndicaTipoMonedaProdTrans__c')));
    setIfFieldExists(acc, dACC, 'ACC_IndicarVolMensualEstimadoTransaccion__c', l.get('LEA_IndicarVolMensualEstimadoTransaccion__c'));
    setIfFieldExists(acc, dACC, 'ACC_DeclaracionSiProyectaManejarEfectivo__c', l.get('LEA_DeclaracionSiProyectaManejarEfectivo__c'));
    setIfFieldExists(acc, dACC, 'ACC_Tipo_beneficio_final__c', safeStr(l.get('LEA_Tipo_beneficio_final__c')));
    setIfFieldExists(acc, dACC, 'ACC_Servicios_a_solicitar__c', safeStr(l.get('LEA_Servicios_a_solicitar__c')));

    mapPrimaryContactPointFieldsToAccount(acc, dACC, l);
  }

  private static void mapPrimaryContactPointFieldsToAccount(Account acc, Schema.DescribeSObjectResult dACC, Lead l) {
    System.debug('LeadConversionQueue.mapPrimaryContactPointFieldsToAccount() leadId=' + (l == null ? null : l.Id));

    if (acc == null || dACC == null || l == null)
      return;

    String primaryPhone = getPrimaryPhoneFromLead(l);
    String primaryEmail = getPrimaryEmailFromLead(l);
    String billingStreet = getPrimaryBillingStreetFromLead(l);

    if (!String.isBlank(primaryPhone)) {
      setIfAccountFieldExistsAndUpdateable(acc, dACC, 'Phone', primaryPhone);
    }

    if (!String.isBlank(primaryEmail)) {
      setIfAccountFieldExistsAndUpdateable(acc, dACC, 'Correo_Electronico_Cliente__c', primaryEmail);
      setIfAccountFieldExistsAndUpdateable(acc, dACC, 'ACC_Correo_Electronico_Cliente__c', primaryEmail);
      setIfAccountFieldExistsAndUpdateable(acc, dACC, 'PersonEmail', primaryEmail);
    }

    if (!String.isBlank(billingStreet)) {
      setIfAccountFieldExistsAndUpdateable(acc, dACC, 'BillingStreet', billingStreet);
      setIfAccountFieldExistsAndUpdateable(acc, dACC, 'BillingCity', safeStr(l.get('LEA_Municipio__c')));
      setIfAccountFieldExistsAndUpdateable(acc, dACC, 'BillingState', safeStr(l.get('LEA_Provincia__c')));
      setIfAccountFieldExistsAndUpdateable(acc, dACC, 'BillingPostalCode', safeStr(l.get('LEA_Apartado_postal__c')));
      setIfAccountFieldExistsAndUpdateable(acc, dACC, 'BillingCountry', safeStr(l.get('LEA_Pais__c')));
    }

    System.debug('LeadConversionQueue.mapPrimaryContactPointFieldsToAccount() primaryPhone=' + primaryPhone + ', primaryEmail=' + primaryEmail + ', billingStreet=' + billingStreet);
  }

  private static String getPrimaryPhoneFromLead(Lead l) {
    if (l == null)
      return null;

    String value1 = safeStr(l.get('LEA_Numero_Correo1__c'));
    String value2 = safeStr(l.get('LEA_Numero_Correo2__c'));
    String value3 = safeStr(l.get('LEA_Numero_Correo3__c'));

    if (((Boolean) l.get('LEA_Principal1__c')) == true && looksLikePhone(value1))
      return value1;

    if (((Boolean) l.get('LEA_Principal2__c')) == true && looksLikePhone(value2))
      return value2;

    if (((Boolean) l.get('LEA_Principal3__c')) == true && looksLikePhone(value3))
      return value3;

    return null;
  }

  private static String getPrimaryEmailFromLead(Lead l) {
    if (l == null)
      return null;

    String value1 = safeStr(l.get('LEA_Numero_Correo1__c'));
    String value2 = safeStr(l.get('LEA_Numero_Correo2__c'));
    String value3 = safeStr(l.get('LEA_Numero_Correo3__c'));

    if (((Boolean) l.get('LEA_Principal1__c')) == true && !String.isBlank(value1) && !looksLikePhone(value1))
      return value1;

    if (((Boolean) l.get('LEA_Principal2__c')) == true && !String.isBlank(value2) && !looksLikePhone(value2))
      return value2;

    if (((Boolean) l.get('LEA_Principal3__c')) == true && !String.isBlank(value3) && !looksLikePhone(value3))
      return value3;

    return null;
  }

  private static String getPrimaryBillingStreetFromLead(Lead l) {
    if (l == null)
      return null;

    String street1 = joinNotBlank(
      new List<String>{
        safeStr(l.get('LEA_Calle__c')),
        safeStr(l.get('LEA_Numero__c'))
      },
      ' '
    );

    String street2 = joinNotBlank(
      new List<String>{
        safeStr(l.get('LEA_Edificio__c')) != null ? ('Edif: ' + safeStr(l.get('LEA_Edificio__c'))) : null,
        safeStr(l.get('LEA_N_Apartamento__c')) != null ? ('Apto: ' + safeStr(l.get('LEA_N_Apartamento__c'))) : null
      },
      ' | '
    );

    return joinNotBlank(new List<String>{ street1, street2 }, '\n');
  }

  private static void addReferenceBundle(
    List<RefBundle> bundles,
    Schema.DescribeSObjectResult dCCR,
    Id mainContactId,
    Id roleId,
    String tipo,
    String nombre,
    String telefono,
    String rnc,
    String direccion,
    String pais,
    String banco,
    String tipoCuenta,
    String numeroCuenta,
    String moneda
  ) {
    System.debug('LeadConversionQueue.addReferenceBundle() mainContactId=' + mainContactId + ', tipo=' + tipo + ', nombre=' + nombre);

    if (bundles == null)
      return;

    if (String.isBlank(nombre) || mainContactId == null)
      return;

    Contact c = new Contact();
    c.LastName = (nombre.length() > 80) ? nombre.substring(0, 80) : nombre;

    if (!String.isBlank(telefono)) {
      c.Phone = telefono;
    }

    setIfContactFieldExists(c, 'VFS_RNC__c', rnc);
    setIfContactFieldExists(c, 'MailingAddress', direccion);
    setIfContactFieldExists(c, 'Pais__c', pais);

    SObject link = Schema.getGlobalDescribe().get('FinServ__ContactContactRelation__c').newSObject();

    setIfFieldExists(link, dCCR, 'FinServ__Contact__c', mainContactId);
    setIfFieldExists(link, dCCR, 'Contact__c', mainContactId);
    setIfFieldExists(link, dCCR, 'FinServ__Role__c', roleId);
    setIfFieldExists(link, dCCR, 'FinServ__IndividualType__c', tipo);
    setIfFieldExists(link, dCCR, 'CCR_Tipo__c', tipo);

    Boolean isReferenciaBancaria = !String.isBlank(tipo) && tipo.equalsIgnoreCase('BANCARIA');

    System.debug('LeadConversionQueue.addReferenceBundle() isReferenciaBancaria=' + isReferenciaBancaria);
    System.debug('LeadConversionQueue.addReferenceBundle() banco=' + banco + ', tipoCuenta=' + tipoCuenta + ', numeroCuenta=' + numeroCuenta + ', moneda=' + moneda);

    if (isReferenciaBancaria) {
      setIfFieldExists(link, dCCR, 'CCR_Banco__c', String.isBlank(banco) ? null : banco);
      setIfFieldExists(link, dCCR, 'CCR_Tipo_de_cuenta__c', String.isBlank(tipoCuenta) ? null : tipoCuenta);
      setIfFieldExists(link, dCCR, 'CCR_N_de_cuenta__c', String.isBlank(numeroCuenta) ? null : numeroCuenta);
      setIfFieldExists(link, dCCR, 'CCR_moneda__c', String.isBlank(moneda) ? null : moneda);
    }

    bundles.add(new RefBundle(c, link, dCCR));
  }

  private static void buildContactPointsFromSlot(
    Schema.DescribeSObjectResult dCPP,
    Schema.DescribeSObjectResult dCPE,
    List<SObject> cpPhones,
    List<SObject> cpEmails,
    Id accountId,
    Id contactId,
    String via,
    String value,
    Boolean isPhone,
    Boolean sendSms,
    Boolean isPrimary,
    String telefonica
  ) {
    if (String.isBlank(value)) {
      return;
    }

    Boolean treatAsPhone = looksLikePhone(value);

    if (treatAsPhone) {
      if (dCPP == null)
        return;

      SObject cpp = Schema.getGlobalDescribe().get('ContactPointPhone').newSObject();

      if (accountId != null) {
        setIfFieldExists(cpp, dCPP, 'ParentId', accountId);
        setIfFieldExists(cpp, dCPP, 'FinServ__RelatedAccount__c', accountId);
        setIfFieldExists(cpp, dCPP, 'Account__c', accountId);
      } else if (contactId != null) {
        setIfFieldExists(cpp, dCPP, 'ParentId', contactId);
        setIfFieldExists(cpp, dCPP, 'FinServ__RelatedContact__c', contactId);
        setIfFieldExists(cpp, dCPP, 'Contact__c', contactId);
      }

      setIfFieldExists(cpp, dCPP, 'TelephoneNumber', value);
      setIfFieldExists(cpp, dCPP, 'PhoneNumber', value);
      setIfFieldExists(cpp, dCPP, 'Phone', value);
      setIfFieldExists(cpp, dCPP, 'IsPrimary', (isPrimary == true));
      setIfFieldExists(cpp, dCPP, 'CanReceiveSms__c', (sendSms == true));
      setIfFieldExists(cpp, dCPP, 'CPP_Tipo__c', via);
      setIfFieldExists(cpp, dCPP, 'CPP_Telefonica__c', telefonica);

      cpPhones.add(cpp);
    } else {
      if (dCPE == null)
        return;

      SObject cpe = Schema.getGlobalDescribe().get('ContactPointEmail').newSObject();

      if (accountId != null) {
        setIfFieldExists(cpe, dCPE, 'ParentId', accountId);
        setIfFieldExists(cpe, dCPE, 'FinServ__RelatedAccount__c', accountId);
        setIfFieldExists(cpe, dCPE, 'Account__c', accountId);
      } else if (contactId != null) {
        setIfFieldExists(cpe, dCPE, 'ParentId', contactId);
        setIfFieldExists(cpe, dCPE, 'FinServ__RelatedContact__c', contactId);
        setIfFieldExists(cpe, dCPE, 'Contact__c', contactId);
      }

      setIfFieldExists(cpe, dCPE, 'EmailAddress', value);
      setIfFieldExists(cpe, dCPE, 'Email', value);
      setIfFieldExists(cpe, dCPE, 'CPP_Tipo__c', via);
      setIfFieldExists(cpe, dCPE, 'IsPrimary', (isPrimary == true));

      cpEmails.add(cpe);
    }
  }

  private static void buildActionPlansForPendingDocs(Schema.DescribeSObjectResult dAP, Set<Id> accountsWithPendingDocs, List<SObject> actionPlans) {
    System.debug('LeadConversionQueue.buildActionPlansForPendingDocs() accountsWithPendingDocs size: ' + (accountsWithPendingDocs == null ? 0 : accountsWithPendingDocs.size()));

    if (dAP == null) {
      System.debug('LeadConversionQueue.buildActionPlansForPendingDocs() ActionPlan describe is null.');
      return;
    }

    if (accountsWithPendingDocs == null || accountsWithPendingDocs.isEmpty()) {
      System.debug('LeadConversionQueue.buildActionPlansForPendingDocs() no pending documents found.');
      return;
    }

    if (actionPlans == null) {
      System.debug('LeadConversionQueue.buildActionPlansForPendingDocs() actionPlans list is null.');
      return;
    }

    Id templateVersionId = getActionPlanTemplateVersionIdByTemplateName(ACTION_PLAN_TEMPLATE_NAME);

    if (templateVersionId == null) {
      System.debug('LeadConversionQueue.buildActionPlansForPendingDocs() template version not found for templateName=' + ACTION_PLAN_TEMPLATE_NAME);
      return;
    }

    Set<Id> accountsAlreadyWithActionPlan = new Set<Id>();
    String actionPlanName = ACTION_PLAN_NAME;

    List<SObject> existingActionPlans = Database.query(
      'SELECT Id, TargetId, Name ' +
      'FROM ActionPlan ' +
      'WHERE TargetId IN :accountsWithPendingDocs ' +
      'AND Name = :actionPlanName'
    );

    System.debug('LeadConversionQueue.buildActionPlansForPendingDocs() existingActionPlans size: ' + existingActionPlans.size());

    for (SObject existingAp : existingActionPlans) {
      Id targetId = (Id) existingAp.get('TargetId');

      if (targetId != null) {
        accountsAlreadyWithActionPlan.add(targetId);
      }
    }

    for (Id accountId : accountsWithPendingDocs) {
      if (accountId == null) {
        continue;
      }

      if (accountsAlreadyWithActionPlan.contains(accountId)) {
        System.debug('LeadConversionQueue.buildActionPlansForPendingDocs() existing ActionPlan found for accountId=' + accountId);
        continue;
      }

      SObject ap = Schema.getGlobalDescribe().get('ActionPlan').newSObject();

      setIfFieldExists(ap, dAP, 'Name', ACTION_PLAN_NAME);
      setIfFieldExists(ap, dAP, 'TargetId', accountId);
      setIfFieldExists(ap, dAP, 'ActionPlanTemplateVersionId', templateVersionId);
      setIfFieldExists(ap, dAP, 'ActionPlanType', ACTION_PLAN_TYPE);
      setIfFieldExists(ap, dAP, 'ActionPlanState', ACTION_PLAN_STATE);
      setIfFieldExists(ap, dAP, 'ScheduleFrequency', ACTION_PLAN_SCHEDULE_FREQUENCY);
      setIfFieldExists(ap, dAP, 'StartDate', Date.today());
      setIfFieldExists(ap, dAP, 'IsUsingHolidayHours', true);
      setIfFieldExists(ap, dAP, 'ShouldAllowOverride', false);

      actionPlans.add(ap);

      System.debug('LeadConversionQueue.buildActionPlansForPendingDocs() ActionPlan prepared for accountId=' + accountId + ', templateVersionId=' + templateVersionId);
    }

    System.debug('LeadConversionQueue.buildActionPlansForPendingDocs() actionPlans prepared size: ' + actionPlans.size());
  }

  private static Id getActionPlanTemplateVersionIdByTemplateName(String templateName) {
    System.debug('LeadConversionQueue.getActionPlanTemplateVersionIdByTemplateName() templateName=' + templateName);

    if (String.isBlank(templateName)) {
      System.debug('LeadConversionQueue.getActionPlanTemplateVersionIdByTemplateName() templateName is blank.');
      return null;
    }

    List<SObject> templates = Database.query(
      'SELECT Id, Name ' +
      'FROM ActionPlanTemplate ' +
      'WHERE Name = :templateName ' +
      'ORDER BY CreatedDate DESC ' +
      'LIMIT 1'
    );

    System.debug('LeadConversionQueue.getActionPlanTemplateVersionIdByTemplateName() templates size: ' + templates.size());

    if (templates.isEmpty()) {
      return null;
    }

    Id templateId = (Id) templates[0].get('Id');

    List<SObject> templateVersions = Database.query(
      'SELECT Id ' +
      'FROM ActionPlanTemplateVersion ' +
      'WHERE ActionPlanTemplateId = :templateId ' +
      'ORDER BY CreatedDate DESC ' +
      'LIMIT 1'
    );

    System.debug('LeadConversionQueue.getActionPlanTemplateVersionIdByTemplateName() templateVersions size: ' + templateVersions.size());

    if (templateVersions.isEmpty()) {
      return null;
    }

    Id templateVersionId = (Id) templateVersions[0].get('Id');

    System.debug('LeadConversionQueue.getActionPlanTemplateVersionIdByTemplateName() templateVersionId=' + templateVersionId);

    return templateVersionId;
  }

  private static List<Task> buildTasksForPendingDocuments(Map<Id, List<String>> pendingDocNamesByAccount) {
    System.debug('LeadConversionQueue.buildTasksForPendingDocuments() accounts size: ' + (pendingDocNamesByAccount == null ? 0 : pendingDocNamesByAccount.size()));

    List<Task> tasks = new List<Task>();

    if (pendingDocNamesByAccount == null || pendingDocNamesByAccount.isEmpty()) {
      System.debug('LeadConversionQueue.buildTasksForPendingDocuments() no pending documents to create tasks.');
      return tasks;
    }

    Set<Id> accountIds = new Set<Id>();
    Set<String> expectedSubjects = new Set<String>();

    for (Id accountId : pendingDocNamesByAccount.keySet()) {
      if (accountId == null) {
        continue;
      }

      accountIds.add(accountId);

      List<String> docNames = pendingDocNamesByAccount.get(accountId);

      if (docNames == null || docNames.isEmpty()) {
        continue;
      }

      for (String docName : docNames) {
        if (!String.isBlank(docName)) {
          expectedSubjects.add('Revisar ' + docName);
        }
      }
    }

    Map<String, Boolean> existingTaskByAccountAndSubject = new Map<String, Boolean>();

    if (!accountIds.isEmpty() && !expectedSubjects.isEmpty()) {
      List<Task> existingTasks = [
        SELECT Id, WhatId, Subject
        FROM Task
        WHERE WhatId IN :accountIds
        AND Subject IN :expectedSubjects
      ];

      System.debug('LeadConversionQueue.buildTasksForPendingDocuments() existingTasks size: ' + existingTasks.size());

      for (Task existingTask : existingTasks) {
        if (existingTask.WhatId != null && !String.isBlank(existingTask.Subject)) {
          existingTaskByAccountAndSubject.put(String.valueOf(existingTask.WhatId) + '|' + existingTask.Subject, true);
        }
      }
    }

    for (Id accountId : pendingDocNamesByAccount.keySet()) {
      if (accountId == null) {
        continue;
      }

      List<String> docNames = pendingDocNamesByAccount.get(accountId);

      if (docNames == null || docNames.isEmpty()) {
        continue;
      }

      for (String docName : docNames) {
        if (String.isBlank(docName)) {
          continue;
        }

        String subject = 'Revisar ' + docName;
        String taskKey = String.valueOf(accountId) + '|' + subject;

        if (existingTaskByAccountAndSubject.containsKey(taskKey)) {
          System.debug('LeadConversionQueue.buildTasksForPendingDocuments() existing Task found. accountId=' + accountId + ', subject=' + subject);
          continue;
        }

        Task t = new Task();
        t.Subject = subject;
        t.Status = 'Open';
        t.Priority = 'High';
        t.ActivityDate = Date.today().addDays(7);
        t.OwnerId = UserInfo.getUserId();
        t.WhatId = accountId;

        tasks.add(t);

        System.debug('LeadConversionQueue.buildTasksForPendingDocuments() Task prepared. accountId=' + accountId + ', subject=' + t.Subject);
      }
    }

    System.debug('LeadConversionQueue.buildTasksForPendingDocuments() tasks prepared size: ' + tasks.size());

    return tasks;
  }

  private static void linkContentDocumentsToChecklistItems(List<Id> documentacionLegalIdsByChecklistIndex, List<SObject> docChecklistItems) {
    System.debug('LeadConversionQueue.linkContentDocumentsToChecklistItems() inicio');
    System.debug('LeadConversionQueue.linkContentDocumentsToChecklistItems() documentacionLegalIdsByChecklistIndex size=' + (documentacionLegalIdsByChecklistIndex == null ? 0 : documentacionLegalIdsByChecklistIndex.size()));
    System.debug('LeadConversionQueue.linkContentDocumentsToChecklistItems() docChecklistItems size=' + (docChecklistItems == null ? 0 : docChecklistItems.size()));

    if (documentacionLegalIdsByChecklistIndex == null || documentacionLegalIdsByChecklistIndex.isEmpty()) {
      return;
    }

    if (docChecklistItems == null || docChecklistItems.isEmpty()) {
      return;
    }

    Set<Id> documentacionLegalIds = new Set<Id>();

    for (Id docLegalId : documentacionLegalIdsByChecklistIndex) {
      if (docLegalId != null) {
        documentacionLegalIds.add(docLegalId);
      }
    }

    if (documentacionLegalIds.isEmpty()) {
      return;
    }

    Map<Id, List<Id>> contentDocumentIdsByDocLegalId = new Map<Id, List<Id>>();

    for (ContentDocumentLink cdl : [
      SELECT Id, LinkedEntityId, ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId IN :documentacionLegalIds
    ]) {
      if (cdl.LinkedEntityId == null || cdl.ContentDocumentId == null) {
        continue;
      }

      if (!contentDocumentIdsByDocLegalId.containsKey(cdl.LinkedEntityId)) {
        contentDocumentIdsByDocLegalId.put(cdl.LinkedEntityId, new List<Id>());
      }

      contentDocumentIdsByDocLegalId.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
    }

    Set<Id> checklistIds = new Set<Id>();

    for (SObject dci : docChecklistItems) {
      if (dci != null && dci.Id != null) {
        checklistIds.add(dci.Id);
      }
    }

    Set<String> existingLinks = new Set<String>();

    if (!checklistIds.isEmpty()) {
      for (ContentDocumentLink existingLink : [
        SELECT Id, LinkedEntityId, ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId IN :checklistIds
      ]) {
        existingLinks.add(String.valueOf(existingLink.LinkedEntityId) + '|' + String.valueOf(existingLink.ContentDocumentId));
      }
    }

    List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();

    Integer maxSize = Math.min(documentacionLegalIdsByChecklistIndex.size(), docChecklistItems.size());

    for (Integer i = 0; i < maxSize; i++) {
      Id docLegalId = documentacionLegalIdsByChecklistIndex[i];
      SObject dci = docChecklistItems[i];

      if (docLegalId == null || dci == null || dci.Id == null) {
        continue;
      }

      List<Id> contentDocumentIds = contentDocumentIdsByDocLegalId.get(docLegalId);

      if (contentDocumentIds == null || contentDocumentIds.isEmpty()) {
        System.debug('LeadConversionQueue.linkContentDocumentsToChecklistItems() sin archivos para Documentacion_Legal__c=' + docLegalId);
        continue;
      }

      for (Id contentDocumentId : contentDocumentIds) {
        String key = String.valueOf(dci.Id) + '|' + String.valueOf(contentDocumentId);

        if (existingLinks.contains(key)) {
          continue;
        }

        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.LinkedEntityId = dci.Id;
        newLink.ContentDocumentId = contentDocumentId;
        newLink.ShareType = 'V';
        newLink.Visibility = 'AllUsers';

        linksToInsert.add(newLink);
      }
    }

    System.debug('LeadConversionQueue.linkContentDocumentsToChecklistItems() linksToInsert size=' + linksToInsert.size());

    if (!linksToInsert.isEmpty()) {
      insert linksToInsert;
    }
  }

  private static void insertTaskInChunks(List<Task> rows, Integer chunkSize) {
    if (rows == null || rows.isEmpty()) {
      System.debug('LeadConversionQueue.insertTaskInChunks() no tasks to insert.');
      return;
    }

    Integer size = rows.size();
    System.debug('LeadConversionQueue.insertTaskInChunks() total=' + size);

    for (Integer i = 0; i < size; i += chunkSize) {
      Integer endIdx = Math.min(i + chunkSize, size);
      List<Task> chunk = new List<Task>();

      for (Integer j = i; j < endIdx; j++) {
        chunk.add(rows[j]);
      }

      System.debug('LeadConversionQueue.insertTaskInChunks() chunk ' + i + ' to ' + endIdx + ' size=' + chunk.size());
      insert chunk;
    }
  }

  private static void insertInChunks(List<SObject> rows, Integer chunkSize, String label) {
    if (rows == null || rows.isEmpty())
      return;

    Integer size = rows.size();
    System.debug('insertInChunks ' + label + ' total=' + size);

    for (Integer i = 0; i < size; i += chunkSize) {
      Integer endIdx = Math.min(i + chunkSize, size);
      List<SObject> chunk = new List<SObject>();

      for (Integer j = i; j < endIdx; j++) {
        chunk.add(rows[j]);
      }

      System.debug('insertInChunks ' + label + ' chunk ' + i + '->' + endIdx + ' size=' + chunk.size());
      insert chunk;
    }
  }

  private static void insertInChunksContacts(List<Contact> rows, Integer chunkSize) {
    if (rows == null || rows.isEmpty())
      return;

    Integer size = rows.size();
    System.debug('insertInChunks Contact total=' + size);

    for (Integer i = 0; i < size; i += chunkSize) {
      Integer endIdx = Math.min(i + chunkSize, size);
      List<Contact> chunk = new List<Contact>();

      for (Integer j = i; j < endIdx; j++) {
        chunk.add(rows[j]);
      }

      System.debug('insertInChunks Contact chunk ' + i + '->' + endIdx + ' size=' + chunk.size());
      insert chunk;
    }
  }

  private static Schema.DescribeSObjectResult safeDescribe(String apiName) {
    try {
      Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

      if (gd == null || !gd.containsKey(apiName)) {
        System.debug('safeDescribe: object not found -> ' + apiName);
        return null;
      }

      return gd.get(apiName).getDescribe();
    } catch (Exception e) {
      System.debug('safeDescribe ERROR ' + apiName + ': ' + e.getMessage());
      return null;
    }
  }

  private static void setIfFieldExists(SObject sob, Schema.DescribeSObjectResult d, String fieldApi, Object value) {
    try {
      if (sob == null || d == null || String.isBlank(fieldApi))
        return;

      Map<String, Schema.SObjectField> f = d.fields.getMap();

      if (f != null && f.containsKey(fieldApi)) {
        sob.put(fieldApi, value);
      }
    } catch (Exception e) {
      System.debug('setIfFieldExists ERROR field=' + fieldApi + ' value=' + value + ' msg=' + e.getMessage());
    }
  }

  private static void setIfAccountFieldExistsAndUpdateable(SObject sob, Schema.DescribeSObjectResult d, String fieldApi, Object value) {
    try {
      if (sob == null || d == null || String.isBlank(fieldApi))
        return;

      Map<String, Schema.SObjectField> f = d.fields.getMap();

      if (f != null && f.containsKey(fieldApi) && f.get(fieldApi).getDescribe().isUpdateable()) {
        sob.put(fieldApi, value);
      }
    } catch (Exception e) {
      System.debug('setIfAccountFieldExistsAndUpdateable ERROR field=' + fieldApi + ' value=' + value + ' msg=' + e.getMessage());
    }
  }

  private static void setIfContactFieldExists(Contact c, String fieldApi, Object value) {
    try {
      if (c == null || String.isBlank(fieldApi))
        return;

      Map<String, Schema.SObjectField> f = Contact.SObjectType.getDescribe().fields.getMap();

      if (f != null && f.containsKey(fieldApi)) {
        c.put(fieldApi, value);
      }
    } catch (Exception e) {
      System.debug('setIfContactFieldExists ERROR field=' + fieldApi + ' msg=' + e.getMessage());
    }
  }

  private static String safeStr(Object o) {
    return (o == null) ? null : String.valueOf(o).trim();
  }

  private static String joinNotBlank(List<String> parts, String sep) {
    if (parts == null || parts.isEmpty())
      return null;

    List<String> out = new List<String>();

    for (String p : parts) {
      if (!String.isBlank(p))
        out.add(p);
    }

    return out.isEmpty() ? null : String.join(out, sep);
  }

  private static Boolean looksLikePhone(String v) {
    if (String.isBlank(v))
      return false;

    String s = v.replace(' ', '').replace('-', '').replace('(', '').replace(')', '').replace('+', '');

    if (s.length() < 7)
      return false;

    return Pattern.matches('^[0-9]+$', s);
  }

  private static Boolean toBool(Object value) {
    if (value == null)
      return null;

    return String.isNotBlank(String.valueOf(value).trim());
  }

  private static Boolean isPF(Lead l) {
    if (l == null || l.RecordType == null)
      return false;

    String recordtypeName = l.RecordType.Name;

    return String.isNotBlank(recordtypeName) && recordtypeName.equalsIgnoreCase('Candidato Persona Física');
  }
}