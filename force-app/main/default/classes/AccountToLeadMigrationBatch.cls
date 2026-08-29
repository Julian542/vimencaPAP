public with sharing class AccountToLeadMigrationBatch implements Database.Batchable<SObject>, Database.Stateful {
    public class FieldMapping {
        public String sourceField;
        public List<String> targetFields;

        public FieldMapping(String sourceField, String targetField) {
            this.sourceField = sourceField;
            this.targetFields = new List<String>{ targetField };
        }

        public FieldMapping(String sourceField, List<String> targetFields) {
            this.sourceField = sourceField;
            this.targetFields = targetFields;
        }
    }

    private Integer processedCount = 0;
    private Integer successCount = 0;
    private Integer errorCount = 0;

    private Id rtPersonaNaturalId;
    private Id rtPersonaJuridicaId;

    private List<Migration_Error__c> failedRecords = new List<Migration_Error__c>();

    private static final List<FieldMapping> ACCOUNT_MAPPINGS = new List<FieldMapping>{
        new FieldMapping('ACC_INT_TipoPersona__c', 'LEA_INT_TipoPersona__c'),
        new FieldMapping('ACC_Tipo_Cliente_PF__c', 'LEA_Tipo_Cliente_PF__c'),
        new FieldMapping('ACC_Tipo_Cliente_PJ__c', 'LEA_Tipo_Cliente_PJ__c'),
        new FieldMapping('ACC_Tipo_Vinculacion__c', 'LEA_Tipo_Vinculacion__c'),
        new FieldMapping('ACC_Actividad_Economica__c', 'LEA_Actividad_Economica__c'),
        new FieldMapping('ACC_Tipo_Sector__c', 'LEA_Tipo_Sector__c'),
        new FieldMapping('ACC_Estado__c', 'Status'),
        new FieldMapping('ACC_Nombre_Corto_Comercial__c', 'LEA_Nombre_Corto_Comercial__c'),
        new FieldMapping('ACC_RNC__c', 'LEA_RNC__c'),
        new FieldMapping('ACC_Tipo_Organizacion__c', 'LEA_Tipo_Organizacion__c'),
        new FieldMapping('ACC_Fecha_Fundacion__c', 'LEA_Fecha_Fundacion__c'),
        new FieldMapping('ACC_Fecha_Cierre_Fiscal__c', 'LEA_Fecha_Cierre_Fiscal__c'),
        new FieldMapping('ACC_Nacionalidad__c', 'LEA_Nacionalidad__c'),
        new FieldMapping('ACC_Tipo_Actividad__c', 'LEA_Tipo_Actividad__c'),
        new FieldMapping('ACC_Clasificacion_Empresa__c', 'LEA_Clasificacion_Empresa__c'),
        new FieldMapping('PersonBirthdate', 'LEA_PersonBirthdate__c'),
        new FieldMapping('Tipo_de_vivienda__c', 'LEA_Tipo_de_vivienda__c'),
        new FieldMapping('ACC_Resultado_Validacion__c', 'LEA_Resultado_Validacion__c'),
        new FieldMapping('ACC_TipoIdentificacion__c', 'LEA_TipoIdentificacion__c'),
        new FieldMapping('ACC_NumIdentificacion__c', 'LEA_NumIdentificacion__c'),
        new FieldMapping('ACC_Genero__c', 'GenderIdentity'),
        new FieldMapping('ACC_Estado_Civil__c', 'LEA_Estado_Civil__c'),
        new FieldMapping('ACC_Persona_Fisica__c', 'LEA_Persona_Fisica__c'),
        new FieldMapping('ACC_Pais_Nacimiento__c', 'LEA_Pais_Nacimiento__c'),
        new FieldMapping('ACC_N_Documentos__c', 'LEA_N_Documentos__c'),
        new FieldMapping('ACC_Posee_Otra_Nacionalidad__c', 'LEA_Posee_Otra_Nacionalidad__c'),
        new FieldMapping('ACC_N_Participantes__c', 'LEA_N_Participantes__c'),
        new FieldMapping('ACC_Calificacion_de_cliente__c', 'LEA_Calificacion_de_cliente__c'),
        new FieldMapping('ACC_Posee_Resid_Otro_Pais__c', 'LEA_Posee_Resid_Otro_Pais__c'),
        new FieldMapping('ACC_Pais_Residencia_Legal__c', 'LEA_Pais_Residencia_Legal__c'),
        new FieldMapping('ACC_N_Identificacion_Anterior__c', 'LEA_N_Identificacion_Anterior__c'),
        new FieldMapping('ACC_Tipo_Identificacion_Anterior__c', 'LEA_Tipo_Identificacion_Anterior__c'),
        new FieldMapping('ACC_Tipo_Persona_PF__c', 'LEA_Tipo_Persona_PF__c'),
        new FieldMapping('Actividad_Economica_Name__c', 'LEA_Actividad_Economica_Name__c'),
        new FieldMapping('Actividad_Economica_Direccion__c', 'LEA_Actividad_Economica_Direccion__c'),
        new FieldMapping('ACC_Provincia_Nacimiento__c', 'LEA_Provincia_Nacimiento__c'),
        new FieldMapping('ACC_Ciudad_de_nacimiento__c', 'LEA_Ciudad_de_nacimiento__c'),
        new FieldMapping('Ciudad_Nacimiento_Codigo__c', 'LEA_Ciudad_Nacimiento_Codigo__c'),
        new FieldMapping('ACC_Nombre_Puesto__c', 'LEA_Nombre_Puesto__c'),
        new FieldMapping('ACC_Nombre_Ejecutivo__c', 'LEA_Nombre_Ejecutivo__c'),
        new FieldMapping('ACC_NumOficina__c', 'LEA_NumOficina__c'),
        new FieldMapping('ACC_Zona__c', 'LEA_Zona__c'),
        new FieldMapping('ACC_Residencia_Rep_Dom__c', 'LEA_Residencia_Rep_Dom__c'),
        new FieldMapping('ACC_Tipo_Depositante__c', 'LEA_Tipo_Depositante__c'),
        new FieldMapping('ACC_Patrimonio_Desc__c', 'LEA_Patrimonio_Desc__c'),
        new FieldMapping('ACC_Aplica_FATCA__c', 'LEA_Aplica_FATCA__c'),
        new FieldMapping('ACC_Es_Mayor_de_Edad__c', 'LEA_Es_Mayor_de_Edad__c'),
        new FieldMapping('Owner_Alias__c', 'LEA_Owner_Alias__c'),
        new FieldMapping('ACC_Cliente_Conocido__c', 'LEA_Cliente_Conocido__c'),
        new FieldMapping('ACC_Es_Empleado_Vimenca__c', 'LEA_Es_Empleado_Vimenca__c'),
        new FieldMapping('ACC_CIF__c', 'LEA_CIF__c'),
        new FieldMapping('ACC_Relacion_Exterior__c', 'LEA_Relacion_Exterior__c'),
        new FieldMapping('ACC_Segmento__c', 'LEA_Segmento__c'),
        new FieldMapping('Resultado_de_la_Integracion__c', 'LEA_Resultado_de_la_Integracion__c'),
        new FieldMapping('ACC_Otra_Nacionalidad__c', 'LEA_Otra_Nacionalidad__c'),
        new FieldMapping('ACC_Fecha_Informacion__c', 'LEA_Fecha_Informacion__c'),
        new FieldMapping('ACC_Total_Activos__c', 'LEA_Total_Activos__c'),
        new FieldMapping('ACC_Moneda__c', 'LEA_Moneda__c'),
        new FieldMapping('ACC_Ventas_Ingresos_Anuales__c', 'LEA_Ventas_Ingresos_Anuales__c'),
        new FieldMapping('ACC_Patrimonio_Num__c', 'LEA_Patrimonio_Num__c'),
        new FieldMapping('ACC_Fuente_Informacion__c', 'LEA_Fuente_Informacion__c'),
        new FieldMapping('ACC_Volumen_Ventas_Anual__c', 'LEA_Volumen_Ventas_Anual__c'),
        new FieldMapping('Gastos_anuales__c', 'LEA_Gastos_anuales__c'),
        new FieldMapping('ACC_Direccion_Trabajo_PEP__c', 'LEA_Direccion_Trabajo_PEP__c'),
        new FieldMapping('ACC_Fecha_Decreto_PEP__c', 'LEA_Fecha_Decreto_PEP__c'),
        new FieldMapping('ACC_Institucion_Trabajo_PEP__c', 'LEA_Institucion_Trabajo_PEP__c'),
        new FieldMapping('ACC_Nacionalidad_PEP__c', 'LEA_Nacionalidad_PEP__c'),
        new FieldMapping('ACC_N_Decreto_PEP__c', 'LEA_N_Decreto_PEP__c'),
        new FieldMapping('ACC_N_Identificacion_PEP__c', 'LEA_N_Identificacion_PEP__c'),
        new FieldMapping('ACC_Ocupacion_PEP__c', 'LEA_Ocupacion_PEP__c'),
        new FieldMapping('ACC_Persona_PEP__c', 'LEA_Persona_PEP__c'),
        new FieldMapping('ACC_Primer_Apellido_PEP__c', 'LEA_Primer_Apellido_PEP__c'),
        new FieldMapping('ACC_Primer_Nombre_PEP__c', 'LEA_Primer_Nombre_PEP__c'),
        new FieldMapping('ACC_Puesto_Cargo_PEP__c', 'LEA_Puesto_Cargo_PEP__c'),
        new FieldMapping('ACC_Segundo_Apellido_PEP__c', 'LEA_Segundo_Apellido_PEP__c'),
        new FieldMapping('ACC_Segundo_Nombre_PEP__c', 'LEA_Segundo_Nombre_PEP__c'),
        new FieldMapping('ACC_Tipo_Identif_PEP__c', 'LEA_Tipo_Identif_PEP__c'),
        new FieldMapping('ACC_Tipo_Relacion_PEP__c', 'LEA_Tipo_Relacion_PEP__c'),
        new FieldMapping('ACC_Apellido_FATCA__c', 'LEA_Apellido_FATCA__c'),
        new FieldMapping('ACC_Ciudad_FATCA__c', 'LEA_Ciudad_FATCA__c'),
        new FieldMapping('ACC_Codigo_Postal_FATCA__c', 'LEA_Codigo_Postal_FATCA__c'),
        new FieldMapping('ACC_Direccion_FATCA__c', 'LEA_Direccion_FATCA__c'),
        new FieldMapping('ACC_Estado_FATCA__c', 'LEA_Estado_FATCA__c'),
        new FieldMapping('ACC_Fecha_Expiracion_FATCA__c', 'LEA_Fecha_Expiracion_FATCA__c'),
        new FieldMapping('ACC_Nombre_FATCA__c', 'LEA_Nombre_FATCA__c'),
        new FieldMapping('ACC_N_Pasaporte_FATCA__c', 'LEA_N_Pasaporte_FATCA__c'),
        new FieldMapping('ACC_SSN_FATCA__c', 'LEA_SSN_FATCA__c'),
        new FieldMapping('ACC_TIN_FATCA__c', 'LEA_TIN_FATCA__c'),
        new FieldMapping('ACC_Telefono_FATCA__c', 'LEA_Telefono_FATCA__c'),
        new FieldMapping('ACC_Nacionalidad_FATCA__c', 'LEA_Nacionalidad_FATCA__c'),
        new FieldMapping('ACC_INT_Tipo_de_identificacion__c', 'LEA_INT_Tipo_de_identificacion__c'),
        new FieldMapping('ACC_INT_Nacionalidad__c', 'LEA_INT_Nacionalidad__c'),
        new FieldMapping('ACC_INT_Pais_Nacimiento__c', 'LEA_INT_Pais_Nacimiento__c'),
        new FieldMapping('ACC_INT_Pais_Residencia_Legal__c', 'LEA_INT_Pais_Residencia_Legal__c'),
        new FieldMapping('ACC_INT_Canales_a_utilizar__c', 'LEA_INT_Canales_a_utilizar__c'),
        new FieldMapping('ACC_INT_Tipo_Estructura_Juridica__c', 'LEA_INT_Tipo_Estructura_Juridica__c'),
        new FieldMapping('ACC_INT_NumOficina__c', 'LEA_INT_NumOficina__c'),
        new FieldMapping('ACC_ProductosASolicitar__c', 'LEA_ProductosASolicitar__c'),
        new FieldMapping('ACC_Servicios_a_solicitar__c', 'LEA_Servicios_a_solicitar__c'),
        new FieldMapping('ACC_Canales_a_utilizar__c', 'LEA_Canales_a_utilizar__c'),
        new FieldMapping('ACC_Tipo_beneficio_final__c', 'LEA_Tipo_beneficio_final__c'),
        new FieldMapping('ACC_Relacion_de_dignatarios__c', 'LEA_Relacion_de_dignatarios__c'),
        new FieldMapping('ACC_INT_Otra_Nacionalidad__c', 'LEA_INT_Otra_Nacionalidad__c'),
        new FieldMapping('ACC_INT_Tipo_Relacion_PEP__c', 'LEA_INT_Tipo_Relacion_PEP__c'),
        new FieldMapping('ACC_NoIndicaTipoMonedaProdTrans__c', 'LEA_NoIndicaTipoMonedaProdTrans__c'),
        new FieldMapping('ACC_DeclaracionSiProyectaManejarEfectivo__c', 'LEA_DeclaracionSiProyectaManejarEfectivo__c'),
        new FieldMapping('ACC_DeclaracionSiManejaOpInternacionales__c', 'LEA_DeclaracionSiManejaOpInternacionales__c'),
        new FieldMapping('ACC_IndicarVolMensualEstimadoTransaccion__c', 'LEA_IndicarVolMensualEstimadoTransaccion__c'),
        new FieldMapping('ACC_Rango_de_Transacciones_estimadas__c', 'LEA_Rango_de_Transacciones_estimadas__c'),
        new FieldMapping('ACC_Relacion_ent_alto_riesgo__c', 'LEA_Relacion_ent_alto_riesgo__c'),
        new FieldMapping('ACC_Familiar_PEP__c', 'LEA_Familiar_PEP__c'),
        new FieldMapping('ACC_Colaborador_de_PEP__c', 'LEA_Colaborador_de_PEP__c')
    };

    private static final List<FieldMapping> DIRECCION_MAPPINGS = new List<FieldMapping>{
        new FieldMapping('DIR_Calle__c', 'LEA_Calle__c'),
        new FieldMapping('DIR_Numero__c', 'LEA_Numero__c'),
        new FieldMapping('DIR_Edificio__c', 'LEA_Edificio__c'),
        new FieldMapping('DIR_N_Apartamento__c', 'LEA_N_Apartamento__c'),
        new FieldMapping('DIR_Pais__c', 'LEA_Pais__c'),
        new FieldMapping('DIR_Provincia__c', 'LEA_Provincia__c'),
        new FieldMapping('DIR_Municipio__c', 'LEA_Municipio__c'),
        new FieldMapping('DIR_Distrito__c', 'LEA_Distrito__c'),
        new FieldMapping('DIR_Sector__c', 'LEA_Sector__c'),
        new FieldMapping('DIR_Apartado_postal__c', 'LEA_Apartado_postal__c'),
        new FieldMapping('DIR_Estado_Ciudad__c', 'LEA_Estado_Ciudad__c'),
        new FieldMapping('DIR_Referencia_Ubicacion__c', 'LEA_Referencia_Ubicacion__c'),
        new FieldMapping('DIR_Direccion_SIEBEL__c', 'LEA_Direccion_SIEBEL__c')
    };

    private static final List<FieldMapping> HISTORIAL_MAPPINGS = new List<FieldMapping>{
        new FieldMapping('HIS_Empresa__c', 'LEA_Empresa__c'),
        new FieldMapping('HIS_Puesto_de_trabajo__c', 'LEA_Puesto_de_trabajo__c'),
        new FieldMapping('HIS_Ocupacion__c', 'LEA_Ocupacion__c'),
        new FieldMapping('HIS_Empleo__c', 'LEA_Empleo_Actual_Anterior__c'),
        new FieldMapping('HIS_Principal__c', 'LEA_Principal__c'),
        new FieldMapping('Tipo_de_empleado__c', 'LEA_Tipo_de_empleado__c'),
        new FieldMapping('Tiempo_de_empresa__c', 'LEA_Tiempo_de_empresa__c'),
        new FieldMapping('HIS_Fecha_de_ingreso__c', 'LEA_Fecha_de_ingreso__c'),
        new FieldMapping('HIS_Fecha_de_fin__c', 'LEA_Fecha_de_fin__c'),
        new FieldMapping('Salario__c', 'LEA_Salario__c'),
        new FieldMapping('Direcci_n_de_la_empresa__c', 'LEA_Direcci_n_de_la_empresa__c'),
        new FieldMapping('Telefono_de_empresa__c', 'LEA_Telefono_de_empresa__c'),
        new FieldMapping('Correo_laboral__c', 'LEA_Correo_laboral__c'),
        new FieldMapping('LEA_INT_Prefesion_u_Oficio__c', 'LEA_INT_Prefesion_u_Oficio__c')
    };

    private static final List<FieldMapping> FINANCIERA_MAPPINGS = new List<FieldMapping>{
        new FieldMapping('INF_Fuente_de_ingresos__c', 'LEA_Fuente_de_ingresos__c'),
        new FieldMapping('INF_Periodo__c', 'LEA_Periodo__c'),
        new FieldMapping('INF_Ingresos__c', 'LEA_Ingresos__c'),
        new FieldMapping('Otros_Ingresos__c', 'LEA_Otros_Ingresos__c'),
        new FieldMapping('Descripci_n_otros_ingresos__c', 'LEA_Descripci_n_otros_ingresos__c'),
        new FieldMapping('INF_INT_Origen_de_los_recursos__c', 'LEA_INT_Origen_de_los_recursos__c')
    };

    private static final List<FieldMapping> REFERENCIA_MAPPINGS = new List<FieldMapping>{
        new FieldMapping('REF_Tipo__c', new List<String>{ 'LEA_Tipo_Referencia1__c', 'LEA_Tipo_Referencia2__c' }),
        new FieldMapping('REF_Nombre__c', new List<String>{ 'LEA_Nombre_Referencia1__c', 'LEA_Nombre_Referencia2__c', 'LEA_Nombre_Referencia3__c' }),
        new FieldMapping('REF_Telefono__c', new List<String>{ 'LEA_Telefono_Referencia1__c', 'LEA_Telefono_Referencia2__c', 'LEA_Telefono_Referencia3__c' }),
        new FieldMapping('VFS_RNC__c', new List<String>{ 'LEA_RNC_Referencia1__c', 'LEA_RNC_Referencia2__c', 'LEA_RNC_Referencia3__c' }),
        new FieldMapping('REF_Direccion__c', new List<String>{ 'LEA_Direccion_Referencia1__c', 'LEA_Direccion_Referencia2__c', 'LEA_Direccion_Referencia3__c' }),
        new FieldMapping('Pais__c', new List<String>{ 'LEA_Pais_Referencia1__c', 'LEA_Pais_Referencia2__c', 'LEA_Pais_Referencia3__c' })
    };

    private static final List<FieldMapping> CONTACTO_MAPPINGS = new List<FieldMapping>{
        new FieldMapping('VIA_de_Contacto__c', new List<String>{ 'LEA_Via_de_Contacto1__c', 'LEA_Via_de_Contacto2__c', 'LEA_Via_de_Contacto3__c' }),
        new FieldMapping('VIA_Numero_Correo__c', new List<String>{ 'LEA_Numero_Correo1__c', 'LEA_Numero_Correo2__c', 'LEA_Numero_Correo3__c' }),
        new FieldMapping('VIA_Telefonica__c', new List<String>{ 'LEA_Telefonica1__c', 'LEA_Telefonica2__c', 'LEA_Telefonica3__c' }),
        new FieldMapping('VIA_Envio_SMS__c', new List<String>{ 'LEA_Envio_SMS1__c', 'LEA_Envio_SMS2__c', 'LEA_Envio_SMS3__c' }),
        new FieldMapping('VIA_Principal__c', new List<String>{ 'LEA_Principal1__c', 'LEA_Principal2__c', 'LEA_Principal3__c' })
    };

    public static Id runBatch(Integer scopeSize) {
        Integer finalScope = (scopeSize == null || scopeSize <= 0) ? 100 : scopeSize;
        return Database.executeBatch(new AccountToLeadMigrationBatch(), finalScope);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Map<String, Schema.RecordTypeInfo> leadRTs = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName();
        if (leadRTs.containsKey('Candidato_Persona_Natural')) {
            rtPersonaNaturalId = leadRTs.get('Candidato_Persona_Natural').getRecordTypeId();
        }
        if (leadRTs.containsKey('Candidato_Persona_Juridica')) {
            rtPersonaJuridicaId = leadRTs.get('Candidato_Persona_Juridica').getRecordTypeId();
        }

        Set<String> fieldsToQuery = new Set<String>{ 'Id', 'Name', 'FirstName', 'LastName' };
        Map<String, Schema.SObjectField> accountDescribe = Schema.SObjectType.Account.fields.getMap();

        for (FieldMapping mapping : ACCOUNT_MAPPINGS) {
            if (accountDescribe.containsKey(mapping.sourceField)) {
                fieldsToQuery.add(mapping.sourceField);
            }
        }

        String soql = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ') +
            ' FROM Account WHERE ACC_Condicion__c = \'PROSPECTO\'';
        return Database.getQueryLocator(soql);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Account> accounts = (List<Account>)scope;
        if (accounts.isEmpty()) {
            return;
        }

        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }

        Map<Id, List<SObject>> dirByAccount = queryChildByAccount('Direccion__c', accountIds, DIRECCION_MAPPINGS);
        Map<Id, List<SObject>> histByAccount = queryChildByAccount('Historial_laboral__c', accountIds, HISTORIAL_MAPPINGS);
        Map<Id, List<SObject>> finByAccount = queryChildByAccount('Informacion_Financiera__c', accountIds, FINANCIERA_MAPPINGS);
        Map<Id, List<SObject>> refByAccount = queryChildByAccount('Referencia__c', accountIds, REFERENCIA_MAPPINGS);
        Map<Id, List<SObject>> conByAccount = queryChildByAccount('Vias_de_Contacto__c', accountIds, CONTACTO_MAPPINGS);

        Map<String, Schema.SObjectField> leadFields = Schema.SObjectType.Lead.fields.getMap();
        List<Lead> leadsToInsert = new List<Lead>();
        List<Id> accountIdsForLeads = new List<Id>();

        for (Account acc : accounts) {
            Lead newLead = new Lead();
            newLead.LastName = String.isBlank(acc.LastName) ? (String.isBlank(acc.Name) ? 'Sin Apellido' : acc.Name) : acc.LastName;
            newLead.Company = String.isBlank(acc.Name) ? 'Sin Compania' : acc.Name;
            if (!String.isBlank(acc.FirstName)) {
                newLead.FirstName = acc.FirstName;
            }

            String tipoPersona = (String) acc.get('ACC_INT_TipoPersona__c');
            if (tipoPersona == 'J' && rtPersonaJuridicaId != null) {
                newLead.RecordTypeId = rtPersonaJuridicaId;
            } else if (rtPersonaNaturalId != null) {
                newLead.RecordTypeId = rtPersonaNaturalId;
            }

            applyMappings(acc, newLead, ACCOUNT_MAPPINGS, leadFields, null);

            if (dirByAccount.containsKey(acc.Id) && !dirByAccount.get(acc.Id).isEmpty()) {
                applyMappings(dirByAccount.get(acc.Id)[0], newLead, DIRECCION_MAPPINGS, leadFields, 0);
            }
            if (histByAccount.containsKey(acc.Id) && !histByAccount.get(acc.Id).isEmpty()) {
                applyMappings(histByAccount.get(acc.Id)[0], newLead, HISTORIAL_MAPPINGS, leadFields, 0);
            }
            if (finByAccount.containsKey(acc.Id) && !finByAccount.get(acc.Id).isEmpty()) {
                applyMappings(finByAccount.get(acc.Id)[0], newLead, FINANCIERA_MAPPINGS, leadFields, 0);
            }
            if (refByAccount.containsKey(acc.Id)) {
                List<SObject> refs = refByAccount.get(acc.Id);
                for (Integer i = 0; i < Math.min(3, refs.size()); i++) {
                    applyMappings(refs[i], newLead, REFERENCIA_MAPPINGS, leadFields, i);
                }
            }
            if (conByAccount.containsKey(acc.Id)) {
                List<SObject> contactos = conByAccount.get(acc.Id);
                for (Integer i = 0; i < Math.min(3, contactos.size()); i++) {
                    applyMappings(contactos[i], newLead, CONTACTO_MAPPINGS, leadFields, i);
                }
            }

            accountIdsForLeads.add(acc.Id);
            leadsToInsert.add(newLead);
        }

        if (!leadsToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(leadsToInsert, false);
            for (Integer i = 0; i < results.size(); i++) {
                processedCount++;
                Database.SaveResult sr = results[i];
                if (sr.isSuccess()) {
                    successCount++;
                } else {
                    errorCount++;
                    List<String> msgs = new List<String>();
                    for (Database.Error e : sr.getErrors()) {
                        msgs.add(e.getStatusCode() + ': ' + e.getMessage());
                        System.debug(LoggingLevel.ERROR, 'Error insertando Lead: ' + e.getMessage());
                    }
                    failedRecords.add(new Migration_Error__c(
                        MEE_Record_Id__c = accountIdsForLeads[i],
                        MEE_Batch_Job_Id__c = bc.getJobId(),
                        MEE_Mensaje_Error__c = String.join(msgs, '\n')
                    ));
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'Migración Account->Lead terminada. Procesados=' + processedCount +
            ', Exitosos=' + successCount +
            ', Errores=' + errorCount
        );
        if (!failedRecords.isEmpty()) {
            Database.insert(failedRecords, false);
        }
    }

    private static void applyMappings(
        SObject source,
        Lead target,
        List<FieldMapping> mappings,
        Map<String, Schema.SObjectField> leadFields,
        Integer rowIndex
    ) {
        if (source == null) {
            return;
        }

        for (FieldMapping mapping : mappings) {
            if (String.isBlank(mapping.sourceField) || !source.getSObjectType().getDescribe().fields.getMap().containsKey(mapping.sourceField)) {
                continue;
            }

            Object sourceValue = source.get(mapping.sourceField);
            if (sourceValue == null) {
                continue;
            }

            String targetField = resolveTargetField(mapping, rowIndex);
            if (String.isBlank(targetField) || !leadFields.containsKey(targetField)) {
                continue;
            }

            try {
                target.put(targetField, sourceValue);
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN,
                    'No se pudo mapear ' + mapping.sourceField + ' -> ' + targetField + ': ' + ex.getMessage()
                );
            }
        }
    }

    private static String resolveTargetField(FieldMapping mapping, Integer rowIndex) {
        if (mapping.targetFields == null || mapping.targetFields.isEmpty()) {
            return null;
        }

        if (rowIndex == null) {
            return mapping.targetFields[0];
        }

        Integer safeIndex = Math.max(0, rowIndex);
        if (safeIndex >= mapping.targetFields.size()) {
            return null;
        }
        return mapping.targetFields[safeIndex];
    }

    private static Map<Id, List<SObject>> queryChildByAccount(
        String childObjectApiName,
        Set<Id> accountIds,
        List<FieldMapping> mappings
    ) {
        Map<Id, List<SObject>> result = new Map<Id, List<SObject>>();
        if (String.isBlank(childObjectApiName) || accountIds == null || accountIds.isEmpty()) {
            return result;
        }

        Schema.SObjectType childType = Schema.getGlobalDescribe().get(childObjectApiName);
        if (childType == null) {
            return result;
        }

        Map<String, Schema.SObjectField> childFields = childType.getDescribe().fields.getMap();
        String accountLookupField = findAccountLookupField(childType);
        if (String.isBlank(accountLookupField)) {
            return result;
        }

        Set<String> selectFields = new Set<String>{ 'Id', accountLookupField };
        for (FieldMapping mapping : mappings) {
            if (childFields.containsKey(mapping.sourceField)) {
                selectFields.add(mapping.sourceField);
            }
        }

        String soql = 'SELECT ' + String.join(new List<String>(selectFields), ', ') +
            ' FROM ' + childObjectApiName +
            ' WHERE ' + accountLookupField + ' IN :accountIds';

        for (SObject row : Database.query(soql)) {
            Id accId = (Id)row.get(accountLookupField);
            if (accId == null) {
                continue;
            }
            if (!result.containsKey(accId)) {
                result.put(accId, new List<SObject>());
            }
            result.get(accId).add(row);
        }

        return result;
    }

    private static String findAccountLookupField(Schema.SObjectType childType) {
        Map<String, Schema.SObjectField> fields = childType.getDescribe().fields.getMap();

        List<String> preferred = new List<String>{ 'Account__c', 'ACC_Account__c', 'AccountId' };
        for (String candidate : preferred) {
            if (fields.containsKey(candidate) && isLookupToAccount(fields.get(candidate))) {
                return candidate;
            }
        }

        for (String fieldName : fields.keySet()) {
            if (isLookupToAccount(fields.get(fieldName))) {
                return fieldName;
            }
        }

        return null;
    }

    private static Boolean isLookupToAccount(Schema.SObjectField f) {
        if (f == null) {
            return false;
        }
        Schema.DescribeFieldResult d = f.getDescribe();
        if (d.getType() != Schema.DisplayType.Reference) {
            return false;
        }

        for (Schema.SObjectType refType : d.getReferenceTo()) {
            if (refType.getDescribe().getName() == 'Account') {
                return true;
            }
        }
        return false;
    }
}