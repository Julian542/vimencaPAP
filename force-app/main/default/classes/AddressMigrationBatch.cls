/**
 * AddressMigrationBatch
 *
 * Migra registros desde Direccion__c hacia dos objetos FSC:
 *   - ContactPointAddress : dirección física del Account
 *   - ContactPointPhone   : teléfono adicional (solo si existe número)
 *
 * Uso desde Execute Anonymous:
 *   AddressMigrationBatch.runBatch(200);
 *
 * Tabla de mapeo (contact-point-address.csv):
 *
 *   ContactPointAddress:
 *     ParentId             ← DIR_Account__c
 *     Street               ← DIR_Calle__c + DIR_Numero__c + DIR_Edificio__c (concatenados)
 *     City                 ← DIR_Municipio_texto__c  (fallback: DIR_Estado_Ciudad__c)
 *     State                ← DIR_Provincia_texto__c  (fallback: DIR_Estado_Ciudad__c)
 *     Country              ← DIR_Pais_Texto__c       (fallback: DIR_Pais__c)
 *     PostalCode           ← DIR_Sector__r.Name
 *     CPA_N_Apartamento__c ← DIR_N_Apartamento__c
 *     CPA_Distrito__c      ← DIR_Distrito_texto__c
 *     CPA_Sector__c        ← DIR_Sector__c           (Id del lookup al sector)
 *     CPA_ExternalId__c    ← DIR_Id_Externo_Direccion__c
 *
 *   ContactPointPhone (solo si al menos uno de los campos de teléfono tiene valor):
 *     ParentId             ← DIR_Account__c
 *     TelephoneNumber      ← DIR_Telef_Adicional__c  (fallback: DIR_Telefono_adicional__c)
 *     ExtensionNumber      ← DIR_Extension__c
 *
 * Decisiones de diseño:
 *   - Street es la concatenación (separada con espacio) de los tres campos de calle,
 *     omitiendo los que sean nulos o blancos.
 *   - City y State se toman de los campos específicos de municipio/provincia; si están
 *     vacíos se utiliza DIR_Estado_Ciudad__c como fallback (campo combinado legado).
 *   - DIR_Telef_Adicional__c y DIR_Telefono_adicional__c son dos campos distintos;
 *     se usa el primero que no esté vacío.
 *   - PostalCode se obtiene cruzando la relación DR_Sector__r; si el sector no tiene
 *     valor se omite el campo.
 *   - Todos los campos custom se validan contra el schema en runtime para evitar
 *     errores en sandboxes donde algún campo aún no exista.
 *   - Los errores de inserción de ContactPointAddress se registran en Migration_Error__c.
 */
public with sharing class AddressMigrationBatch
        implements Database.Batchable<SObject>, Database.Stateful {

    private class AddressWorkItem {
        Id sourceId;
        SObject cpa;
        Boolean requiresPhoneLink;
        Integer phoneInsertIndex;
    }

    // ─── Estadísticas stateful ───────────────────────────────────────────────
    private Integer processedCount = 0;
    private Integer successCount   = 0;
    private Integer errorCount     = 0;
    private List<Migration_Error__c> failedRecords = new List<Migration_Error__c>();

    // ─── Campos source directo → ContactPointAddress (campos custom) ─────────
    @TestVisible
    private static final List<String[]> MAPPINGS_CPA_CUSTOM = new List<String[]>{
        new String[]{ 'DIR_N_Apartamento__c',        'CPA_N_Apartamento__c' },
        new String[]{ 'DIR_Distrito_texto__c',       'CPA_Distrito__c'      },
        new String[]{ 'DIR_Id_Externo_Direccion__c', 'CPA_ExternalId__c'    }
    };

    // ─────────────────────────────────────────────────────────────────────────

    public static Id runBatch(Integer scopeSize) {
        Integer finalScope = (scopeSize == null || scopeSize <= 0) ? 200 : scopeSize;
        return Database.executeBatch(new AddressMigrationBatch(), finalScope);
    }

    // ─── start ───────────────────────────────────────────────────────────────
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Schema.SObjectType srcType = Schema.getGlobalDescribe().get('Direccion__c');
        if (srcType == null) {
            throw new IllegalArgumentException('Direccion__c no encontrado en la org.');
        }

        Map<String, Schema.SObjectField> srcFields = srcType.getDescribe().fields.getMap();
        Set<String> fieldsToQuery = new Set<String>{ 'Id' };

        for (String f : new List<String>{
            'DIR_Account__c',
            'DIR_Estado_Ciudad__c',
            'DIR_N_Apartamento__c',
            'DIR_Distrito_texto__c',
            'DIR_Municipio_texto__c',
            'DIR_Provincia_texto__c',
            'DIR_Pais_Texto__c',
            'DIR_Pais__c',
            'DIR_Calle__c',
            'DIR_Numero__c',
            'DIR_Edificio__c',
            'DIR_Telef_Adicional__c',
            'DIR_Telefono_adicional__c',
            'DIR_Extension__c',
            'DIR_Sector__c',
            'DIR_Id_Externo_Direccion__c'
        }) {
            if (srcFields.containsKey(f)) {
                fieldsToQuery.add(f);
            }
        }

        // Relación para PostalCode (DIR_Sector__r.Name)
        if (srcFields.containsKey('DIR_Sector__c')) {
            fieldsToQuery.add('DIR_Sector__r.Name');
        }

        return Database.getQueryLocator(
            'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ')
            + ' FROM Direccion__c'
        );
    }

    // ─── execute ─────────────────────────────────────────────────────────────
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        Schema.SObjectType srcType = Schema.getGlobalDescribe().get('Direccion__c');
        if (srcType == null) { return; }

        Schema.SObjectType cpaType = Schema.getGlobalDescribe().get('ContactPointAddress');
        Schema.SObjectType cppType = Schema.getGlobalDescribe().get('ContactPointPhone');

        if (cpaType == null) {
            System.debug(LoggingLevel.ERROR,
                'ContactPointAddress no encontrado. Verifica que FSC esté instalado.'
            );
            return;
        }

        if (cppType == null) {
            System.debug(LoggingLevel.ERROR,
                'ContactPointPhone no encontrado. Verifica que FSC esté instalado.'
            );
            return;
        }

        Map<String, Schema.SObjectField> srcFieldMap = srcType.getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> cpaFieldMap = cpaType.getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> cppFieldMap = (cppType != null)
            ? cppType.getDescribe().fields.getMap()
            : new Map<String, Schema.SObjectField>();

        List<SObject> cppToInsert = new List<SObject>();
        List<Id> cppSourceIds = new List<Id>();
        List<AddressWorkItem> items = new List<AddressWorkItem>();

        Boolean hasPhoneLinkField = cpaFieldMap.containsKey('ContactPointPhoneId');
        Boolean hasCpaExternalId = cpaFieldMap.containsKey('CPA_ExternalId__c');

        for (SObject src : scope) {
            Id sourceId  = (Id) src.get('Id');
            Id accountId = srcFieldMap.containsKey('DIR_Account__c')
                ? (Id) src.get('DIR_Account__c') : null;

            try {
                if (accountId == null) {
                    errorCount++;
                    failedRecords.add(new Migration_Error__c(
                        MEE_Record_Id__c     = sourceId,
                        MEE_Batch_Job_Id__c  = bc.getJobId(),
                        MEE_Mensaje_Error__c = 'DIR_Account__c es obligatorio para crear CPAddress/CPPhone.'
                    ));
                    continue;
                }

                AddressWorkItem item = new AddressWorkItem();
                item.sourceId = sourceId;
                item.requiresPhoneLink = false;
                item.phoneInsertIndex = null;

                // ── ContactPointAddress ──────────────────────────────────────
                SObject cpa = cpaType.newSObject();
                cpa.put('ParentId', accountId);

                // Street: concatenar Calle + Numero + Edificio (partes no vacías)
                List<String> streetParts = new List<String>();
                for (String f : new List<String>{ 'DIR_Calle__c', 'DIR_Numero__c', 'DIR_Edificio__c' }) {
                    if (srcFieldMap.containsKey(f)) {
                        String val = (String) src.get(f);
                        if (String.isNotBlank(val)) {
                            streetParts.add(val.trim());
                        }
                    }
                }
                if (!streetParts.isEmpty()) {
                    cpa.put('Street', String.join(streetParts, ' '));
                }

                // City: DIR_Municipio_texto__c (fallback DIR_Estado_Ciudad__c)
                String city = getFirstNonBlank(src, srcFieldMap,
                    new List<String>{ 'DIR_Municipio_texto__c', 'DIR_Estado_Ciudad__c' });
                if (city != null) { cpa.put('City', city); }

                // State: DIR_Provincia_texto__c (fallback DIR_Estado_Ciudad__c)
                String state = getFirstNonBlank(src, srcFieldMap,
                    new List<String>{ 'DIR_Provincia_texto__c', 'DIR_Estado_Ciudad__c' });
                if (state != null) { cpa.put('State', state); }

                // Country: DIR_Pais__c (fallback DIR_Pais_Texto__c)
                String country = getFirstNonBlank(src, srcFieldMap,
                    new List<String>{ 'DIR_Pais__c', 'DIR_Pais_Texto__c' });
                if (country != null) { cpa.put('Country', country); }

                // PostalCode: DIR_Sector__r.Name (relación)
                if (srcFieldMap.containsKey('DIR_Sector__c')) {
                    SObject sectorRef = src.getSObject('DIR_Sector__r');
                    if (sectorRef != null) {
                        Object postalCode = sectorRef.get('Name');
                        if (postalCode != null) {
                            cpa.put('PostalCode', postalCode);
                        }
                    }
                }

                // CPA_Sector__c ← DIR_Sector__c (Id del lookup al sector)
                if (srcFieldMap.containsKey('DIR_Sector__c') && cpaFieldMap.containsKey('CPA_Sector__c')) {
                    Object val = src.get('DIR_Sector__c');
                    if (val != null) {
                        try {
                            cpa.put('CPA_Sector__c', val);
                        } catch (Exception ex) {
                            System.debug(LoggingLevel.WARN,
                                'No se pudo asignar DIR_Sector__c -> CPA_Sector__c: ' + ex.getMessage()
                            );
                        }
                    }
                }

                // Campos custom directos (Apartamento, Distrito, ExternalId)
                applyMappings(src, cpa, MAPPINGS_CPA_CUSTOM, srcFieldMap, cpaFieldMap);

                // ── ContactPointPhone primero si hay telefono ───────────────
                String phone = getFirstNonBlank(src, srcFieldMap,
                    new List<String>{ 'DIR_Telef_Adicional__c', 'DIR_Telefono_adicional__c' });

                if (phone != null) {
                    if (!hasPhoneLinkField) {
                        errorCount++;
                        failedRecords.add(new Migration_Error__c(
                            MEE_Record_Id__c     = sourceId,
                            MEE_Batch_Job_Id__c  = bc.getJobId(),
                            MEE_Mensaje_Error__c = 'ContactPointPhoneId no existe en ContactPointAddress.'
                        ));
                        continue;
                    }

                    SObject cpp = cppType.newSObject();
                    cpp.put('ParentId', accountId);
                    cpp.put('TelephoneNumber', phone);

                    if (srcFieldMap.containsKey('DIR_Extension__c')
                            && cppFieldMap.containsKey('ExtensionNumber')) {
                        Object ext = src.get('DIR_Extension__c');
                        if (ext != null) {
                            try {
                                cpp.put('ExtensionNumber', ext);
                            } catch (Exception ex) {
                                System.debug(LoggingLevel.WARN,
                                    'No se pudo asignar DIR_Extension__c -> ExtensionNumber: '
                                    + ex.getMessage()
                                );
                            }
                        }
                    }

                    item.requiresPhoneLink = true;
                    item.phoneInsertIndex = cppToInsert.size();
                    cppToInsert.add(cpp);
                    cppSourceIds.add(sourceId);
                }

                item.cpa = cpa;
                items.add(item);
            } catch (Exception exTransform) {
                errorCount++;
                failedRecords.add(new Migration_Error__c(
                    MEE_Record_Id__c     = sourceId,
                    MEE_Batch_Job_Id__c  = bc.getJobId(),
                    MEE_Mensaje_Error__c = 'Error transformando Direccion__c: ' + exTransform.getMessage()
                ));
            }
        }

        // ── Insertar ContactPointPhone primero para obtener IDs ───────────────
        Map<Integer, Id> phoneIdByInsertIndex = new Map<Integer, Id>();
        Set<Id> phoneFailedSourceIds = new Set<Id>();
        if (!cppToInsert.isEmpty()) {
            try {
                Database.SaveResult[] phoneResults = Database.insert(cppToInsert, false);
                for (Integer i = 0; i < phoneResults.size(); i++) {
                    if (phoneResults[i].isSuccess()) {
                        phoneIdByInsertIndex.put(i, phoneResults[i].getId());
                    } else {
                        errorCount++;
                        Id srcId = cppSourceIds[i];
                        phoneFailedSourceIds.add(srcId);
                        List<String> msgs = new List<String>();
                        for (Database.Error e : phoneResults[i].getErrors()) {
                            msgs.add(e.getStatusCode() + ': ' + e.getMessage());
                            System.debug(LoggingLevel.ERROR,
                                'Error insertando ContactPointPhone (fuente=' + srcId + '): '
                                + e.getMessage()
                            );
                        }
                        failedRecords.add(new Migration_Error__c(
                            MEE_Record_Id__c     = srcId,
                            MEE_Batch_Job_Id__c  = bc.getJobId(),
                            MEE_Mensaje_Error__c = 'CPP: ' + String.join(msgs, '\n')
                        ));
                    }
                }
            } catch (Exception exPhoneDml) {
                errorCount += cppToInsert.size();
                failedRecords.add(new Migration_Error__c(
                    MEE_Record_Id__c     = null,
                    MEE_Batch_Job_Id__c  = bc.getJobId(),
                    MEE_Mensaje_Error__c = 'Excepcion DML insertando ContactPointPhone: '
                        + exPhoneDml.getMessage()
                ));
                for (Id sid : cppSourceIds) {
                    phoneFailedSourceIds.add(sid);
                }
            }
        }

        // ── Construir addresses finales con vínculo ContactPointPhoneId ──────
        List<SObject> cpaToUpsert = new List<SObject>();
        List<Id> cpaSourceIds = new List<Id>();
        for (AddressWorkItem item : items) {
            if (item.requiresPhoneLink) {
                if (phoneFailedSourceIds.contains(item.sourceId)
                        || item.phoneInsertIndex == null
                        || !phoneIdByInsertIndex.containsKey(item.phoneInsertIndex)) {
                    continue;
                }
                item.cpa.put('ContactPointPhoneId', phoneIdByInsertIndex.get(item.phoneInsertIndex));
            }

            cpaToUpsert.add(item.cpa);
            cpaSourceIds.add(item.sourceId);
        }

        // ── Upsert ContactPointAddress por CPA_ExternalId__c ────────────────
        if (!cpaToUpsert.isEmpty()) {
            try {
                if (hasCpaExternalId) {
                    Database.UpsertResult[] results = Database.upsert(
                        cpaToUpsert,
                        cpaFieldMap.get('CPA_ExternalId__c'),
                        false
                    );
                    for (Integer i = 0; i < results.size(); i++) {
                        processedCount++;
                        if (results[i].isSuccess()) {
                            successCount++;
                        } else {
                            errorCount++;
                            List<String> msgs = new List<String>();
                            for (Database.Error e : results[i].getErrors()) {
                                msgs.add(e.getStatusCode() + ': ' + e.getMessage());
                                System.debug(LoggingLevel.ERROR,
                                    'Error en ContactPointAddress (fuente=' + cpaSourceIds[i] + '): '
                                    + e.getMessage()
                                );
                            }
                            failedRecords.add(new Migration_Error__c(
                                MEE_Record_Id__c     = cpaSourceIds[i],
                                MEE_Batch_Job_Id__c  = bc.getJobId(),
                                MEE_Mensaje_Error__c = 'CPA: ' + String.join(msgs, '\n')
                            ));
                        }
                    }
                } else {
                    Database.SaveResult[] results = Database.insert(cpaToUpsert, false);
                    for (Integer i = 0; i < results.size(); i++) {
                        processedCount++;
                        if (results[i].isSuccess()) {
                            successCount++;
                        } else {
                            errorCount++;
                            List<String> msgs = new List<String>();
                            for (Database.Error e : results[i].getErrors()) {
                                msgs.add(e.getStatusCode() + ': ' + e.getMessage());
                                System.debug(LoggingLevel.ERROR,
                                    'Error en ContactPointAddress (fuente=' + cpaSourceIds[i] + '): '
                                    + e.getMessage()
                                );
                            }
                            failedRecords.add(new Migration_Error__c(
                                MEE_Record_Id__c     = cpaSourceIds[i],
                                MEE_Batch_Job_Id__c  = bc.getJobId(),
                                MEE_Mensaje_Error__c = 'CPA: ' + String.join(msgs, '\n')
                            ));
                        }
                    }
                }
            } catch (Exception exAddressDml) {
                errorCount += cpaToUpsert.size();
                failedRecords.add(new Migration_Error__c(
                    MEE_Record_Id__c     = null,
                    MEE_Batch_Job_Id__c  = bc.getJobId(),
                    MEE_Mensaje_Error__c = 'Excepcion DML en ContactPointAddress: '
                        + exAddressDml.getMessage()
                ));
            }
        }
    }

    // ─── finish ──────────────────────────────────────────────────────────────
    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'Migración Direccion__c -> ContactPointAddress terminada. '
            + 'Procesados=' + processedCount
            + ', Exitosos=' + successCount
            + ', Errores=' + errorCount
        );
        if (!failedRecords.isEmpty()) {
            Database.insert(failedRecords, false);
        }
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    // Devuelve el primer valor no nulo/blanco de la lista de campos dada.
    private static String getFirstNonBlank(
        SObject src,
        Map<String, Schema.SObjectField> fieldMap,
        List<String> fields
    ) {
        for (String f : fields) {
            if (fieldMap.containsKey(f)) {
                String val = (String) src.get(f);
                if (String.isNotBlank(val)) {
                    return val.trim();
                }
            }
        }
        return null;
    }

    private static void applyMappings(
        SObject src,
        SObject target,
        List<String[]> mappings,
        Map<String, Schema.SObjectField> srcFieldMap,
        Map<String, Schema.SObjectField> tgtFieldMap
    ) {
        for (String[] pair : mappings) {
            String srcField = pair[0];
            String tgtField = pair[1];
            if (!srcFieldMap.containsKey(srcField) || !tgtFieldMap.containsKey(tgtField)) { continue; }
            if (tgtFieldMap.get(tgtField).getDescribe().isCalculated()) { continue; }
            Object val = src.get(srcField);
            if (val == null) { continue; }
            try {
                target.put(tgtField, val);
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN,
                    'applyMappings ' + srcField + ' -> ' + tgtField + ': ' + ex.getMessage()
                );
            }
        }
    }
}