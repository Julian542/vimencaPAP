/**
 * FinancialAccountRoleMigrationBatch
 *
 * Migra registros hacia FinServ__FinancialAccountRole__c (FSC)
 * a partir del objeto legado Vinculado__c.
 *
 * Uso desde Execute Anonymous:
 *   FinancialAccountRoleMigrationBatch.runBatch('Vinculado__c', 200);
 *
 * Tabla de mapeo (financial-account-role.csv):
 *
 *   Vinculado__c:
 *     FinServ__RelatedAccount__c  ← VIN_Cliente_vinculado__c
 *     FinServ__FinancialAccount__c← VIN_Cuenta_financiera__c
 *     FinServ__Role__c            ← VIN_Tipo_de_vinculo__c; VIN_Clase_de_Cliente__c
 *                                   (VIN_Clase_de_Cliente__c sobrescribe si no es nulo)
 *     FAR_Relacion__c             ← VIN_Relacion__c
 *     FAR_Firmante__c             ← VIN_Firmante__c
 *     FAR_LegacyLinkedCode__c     ← VIN_Codigo__c
 *     FinServ__SourceSystemId__c  ← Id
 *
 *     Además actualiza el Account/Contact apuntado por VIN_Cliente_vinculado__c:
 *       CIF__c              ← VIN_CIF_Vinculado__c
 *       DocumentNumber__c   ← VIN_N_identificacion_vinculado__c
 *       FAR_DocumentType__c ← VIN_Tipo_identificacion_vinculado__c
 *
 *     Además actualiza la FinancialAccount apuntada por VIN_Cuenta_financiera__c:
 *       FIN_Linea_de_producto__c ← VIN_Linea_de_producto__c
 *
 * Decisiones de diseño:
 *   - FinServ__RelatedAccount__c se usa tanto para Account como para Contact
 *     (PersonAccount). Si la org distingue Contact separado, ajustar la lógica
 *     en buildFarFromVinculado.
 *   - Todos los campos se validan contra el schema en runtime para evitar errores
 *     si algún campo no existe todavía en la sandbox.
 *   - Los errores de inserción se registran en Migration_Error__c y se persisten
 *     en finish().
 */
public with sharing class FinancialAccountRoleMigrationBatch
        implements Database.Batchable<SObject>, Database.Stateful {

    // ─── Configuración de la instancia ──────────────────────────────────────
    private String sourceObjectName;

    // ─── Estadísticas stateful ───────────────────────────────────────────────
    private Integer processedCount = 0;
    private Integer successCount   = 0;
    private Integer errorCount     = 0;
    private List<Migration_Error__c> failedRecords = new List<Migration_Error__c>();

    // ─── Objeto destino ──────────────────────────────────────────────────────
    private static final String FAR_OBJECT = 'FinServ__FinancialAccountRole__c';

    // ─── Claves de campo FAR ─────────────────────────────────────────────────
    private static final String F_RELATED_ACCOUNT   = 'FinServ__RelatedAccount__c';
    private static final String F_FINANCIAL_ACCOUNT = 'FinServ__FinancialAccount__c';
    private static final String F_SOURCE_SYSTEM_ID  = 'FinServ__SourceSystemId__c';

    // ─── Campos de Vinculado__c → FinancialAccountRole ───────────────────────
    // VIN_Tipo_de_vinculo__c y VIN_Clase_de_Cliente__c comparten destino;
    // el segundo sobrescribe al primero si no es nulo (orden garantizado por la lista).
    @TestVisible
    private static final List<String[]> MAPPINGS_VINCULADO_FAR = new List<String[]>{
        new String[]{ 'VIN_Tipo_de_vinculo__c',   'FinServ__Role__c'         },
        new String[]{ 'VIN_Clase_de_Cliente__c',  'FinServ__Role__c'         },
        new String[]{ 'VIN_Relacion__c',          'FAR_Relacion__c'          },
        new String[]{ 'VIN_Firmante__c',          'FAR_Firmante__c'          },
        new String[]{ 'VIN_Codigo__c',            'FAR_LegacyLinkedCode__c'  }
    };

    // ─── Campos de Vinculado__c que actualizan Account / Contact ─────────────
    @TestVisible
    private static final List<String[]> MAPPINGS_VINCULADO_PARTY = new List<String[]>{
        new String[]{ 'VIN_CIF_Vinculado__c',               'CIF__c'              },
        new String[]{ 'VIN_N_identificacion_vinculado__c',  'DocumentNumber__c'   },
        new String[]{ 'VIN_Tipo_identificacion_vinculado__c','FAR_DocumentType__c' }
    };

    // ─────────────────────────────────────────────────────────────────────────

    public FinancialAccountRoleMigrationBatch(String sourceObjectName) {
        this.sourceObjectName = sourceObjectName;
    }

    public static Id runBatch(String sourceObjectName, Integer scopeSize) {
        Integer finalScope = (scopeSize == null || scopeSize <= 0) ? 200 : scopeSize;
        return Database.executeBatch(
            new FinancialAccountRoleMigrationBatch(sourceObjectName),
            finalScope
        );
    }

    // ─── start ───────────────────────────────────────────────────────────────
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Schema.SObjectType srcType = Schema.getGlobalDescribe().get(sourceObjectName);
        if (srcType == null) {
            throw new IllegalArgumentException(
                'Objeto fuente no encontrado en la org: ' + sourceObjectName
            );
        }

        Map<String, Schema.SObjectField> srcFields = srcType.getDescribe().fields.getMap();
        Set<String> fieldsToQuery = new Set<String>{ 'Id' };

        addIfExists(fieldsToQuery, srcFields, 'VIN_Cliente_vinculado__c');
        addIfExists(fieldsToQuery, srcFields, 'VIN_Cuenta_financiera__c');
        addIfExists(fieldsToQuery, srcFields, 'VIN_Linea_de_producto__c');
        for (String[] pair : MAPPINGS_VINCULADO_FAR) {
            addIfExists(fieldsToQuery, srcFields, pair[0]);
        }
        for (String[] pair : MAPPINGS_VINCULADO_PARTY) {
            addIfExists(fieldsToQuery, srcFields, pair[0]);
        }

        return Database.getQueryLocator(
            'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ')
            + ' FROM ' + sourceObjectName
        );
    }

    // ─── execute ─────────────────────────────────────────────────────────────
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        Schema.SObjectType srcType = Schema.getGlobalDescribe().get(sourceObjectName);
        if (srcType == null) { return; }

        Schema.SObjectType farType = Schema.getGlobalDescribe().get(FAR_OBJECT);
        if (farType == null) {
            System.debug(LoggingLevel.ERROR,
                FAR_OBJECT + ' no encontrado. Verifica que FSC esté instalado.'
            );
            return;
        }

        Map<String, Schema.SObjectField> srcFieldMap = srcType.getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> farFieldMap = farType.getDescribe().fields.getMap();

        List<SObject>    farsToInsert   = new List<SObject>();
        List<Id>         sourceIds      = new List<Id>();
        Map<Id, SObject> partiesToUpdate = new Map<Id, SObject>();  // Account / Contact
        Map<Id, SObject> finAccsToUpdate = new Map<Id, SObject>();  // FinancialAccount

        for (SObject src : scope) {
            SObject far = farType.newSObject();

            // FinServ__SourceSystemId__c ← Id (texto con 18 caracteres)
            putSafe(far, farFieldMap, F_SOURCE_SYSTEM_ID, String.valueOf(src.get('Id')));

            buildFarFromVinculado(src, far, srcFieldMap, farFieldMap,
                partiesToUpdate, finAccsToUpdate);

            sourceIds.add((Id) src.get('Id'));
            farsToInsert.add(far);
        }

        // ── Insertar FinancialAccountRole records ─────────────────────────────
        if (!farsToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(farsToInsert, false);
            for (Integer i = 0; i < results.size(); i++) {
                processedCount++;
                if (results[i].isSuccess()) {
                    successCount++;
                } else {
                    errorCount++;
                    List<String> msgs = new List<String>();
                    msgs.add('Objeto fuente: ' + sourceObjectName + ' | Id: ' + sourceIds[i]);
                    for (Database.Error e : results[i].getErrors()) {
                        String detail = e.getStatusCode() + ': ' + e.getMessage();
                        List<String> fields = e.getFields();
                        if (fields != null && !fields.isEmpty()) {
                            detail += ' | Campos: ' + String.join(fields, ', ');
                        }
                        msgs.add(detail);
                        System.debug(LoggingLevel.ERROR,
                            '[' + sourceObjectName + '] Error insertando FAR'
                            + ' (Id=' + sourceIds[i] + '): ' + detail
                        );
                    }
                    failedRecords.add(new Migration_Error__c(
                        MEE_Record_Id__c     = sourceIds[i],
                        MEE_Batch_Job_Id__c  = bc.getJobId(),
                        MEE_Mensaje_Error__c = String.join(msgs, '\n')
                    ));
                }
            }
        }

        // ── Actualizar Account / Contact vinculados ───────────────────────────
        if (!partiesToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(partiesToUpdate.values(), false);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error e : sr.getErrors()) {
                        System.debug(LoggingLevel.WARN,
                            'Error actualizando Account/Contact: ' + e.getMessage()
                        );
                    }
                }
            }
        }

        // ── Actualizar FinancialAccount vinculadas ────────────────────────────
        if (!finAccsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(finAccsToUpdate.values(), false);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error e : sr.getErrors()) {
                        System.debug(LoggingLevel.WARN,
                            'Error actualizando FinancialAccount: ' + e.getMessage()
                        );
                    }
                }
            }
        }
    }

    // ─── finish ──────────────────────────────────────────────────────────────
    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'Migración ' + sourceObjectName + ' -> ' + FAR_OBJECT + ' terminada. '
            + 'Procesados=' + processedCount
            + ', Exitosos=' + successCount
            + ', Errores=' + errorCount
        );
        if (!failedRecords.isEmpty()) {
            Database.insert(failedRecords, false);
        }
    }

    // ─── Construcción de FAR desde Vinculado__c ──────────────────────────────
    private void buildFarFromVinculado(
        SObject src,
        SObject far,
        Map<String, Schema.SObjectField> srcFieldMap,
        Map<String, Schema.SObjectField> farFieldMap,
        Map<Id, SObject> partiesToUpdate,
        Map<Id, SObject> finAccsToUpdate
    ) {
        // FinServ__RelatedAccount__c ← VIN_Cliente_vinculado__c
        copyLookup(src, far, srcFieldMap, farFieldMap,
            'VIN_Cliente_vinculado__c', F_RELATED_ACCOUNT);

        // FinServ__FinancialAccount__c ← VIN_Cuenta_financiera__c
        copyLookup(src, far, srcFieldMap, farFieldMap,
            'VIN_Cuenta_financiera__c', F_FINANCIAL_ACCOUNT);

        // Campos directos sobre FAR (Role, Relacion, Firmante, Codigo)
        applyMappings(src, far, MAPPINGS_VINCULADO_FAR, srcFieldMap, farFieldMap);

        // ── Actualizar Account / Contact con datos de identificación ──────────
        if (srcFieldMap.containsKey('VIN_Cliente_vinculado__c')) {
            Id partyId = (Id) src.get('VIN_Cliente_vinculado__c');
            if (partyId != null) {
                if (!partiesToUpdate.containsKey(partyId)) {
                    partiesToUpdate.put(partyId, partyId.getSObjectType().newSObject(partyId));
                }
                SObject party = partiesToUpdate.get(partyId);
                Map<String, Schema.SObjectField> partyFieldMap =
                    partyId.getSObjectType().getDescribe().fields.getMap();
                for (String[] pair : MAPPINGS_VINCULADO_PARTY) {
                    if (srcFieldMap.containsKey(pair[0]) && partyFieldMap.containsKey(pair[1])) {
                        Object val = src.get(pair[0]);
                        if (val == null) { continue; }
                        try {
                            party.put(pair[1], val);
                        } catch (Exception ex) {
                            System.debug(LoggingLevel.WARN,
                                'No se pudo asignar ' + pair[0] + ' -> ' + pair[1]
                                + ': ' + ex.getMessage()
                            );
                        }
                    }
                }
            }
        }

        // ── Actualizar FIN_Linea_de_producto__c en la FinancialAccount ────────
        if (srcFieldMap.containsKey('VIN_Linea_de_producto__c')
                && srcFieldMap.containsKey('VIN_Cuenta_financiera__c')) {
            Object linea    = src.get('VIN_Linea_de_producto__c');
            Id     finAccId = (Id) src.get('VIN_Cuenta_financiera__c');
            if (linea != null && finAccId != null) {
                if (!finAccsToUpdate.containsKey(finAccId)) {
                    Schema.SObjectType finAccType =
                        Schema.getGlobalDescribe().get('FinServ__FinancialAccount__c');
                    if (finAccType != null) {
                        finAccsToUpdate.put(finAccId, finAccType.newSObject(finAccId));
                    }
                }
                if (finAccsToUpdate.containsKey(finAccId)) {
                    Map<String, Schema.SObjectField> finAccFieldMap =
                        Schema.getGlobalDescribe().get('FinServ__FinancialAccount__c')
                            .getDescribe().fields.getMap();
                    if (finAccFieldMap.containsKey('FIN_Linea_de_producto__c')) {
                        try {
                            finAccsToUpdate.get(finAccId).put('FIN_Linea_de_producto__c', linea);
                        } catch (Exception ex) {
                            System.debug(LoggingLevel.WARN,
                                'No se pudo asignar VIN_Linea_de_producto__c'
                                + ' -> FIN_Linea_de_producto__c: ' + ex.getMessage()
                            );
                        }
                    }
                }
            }
        }
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private static void addIfExists(
        Set<String> fields,
        Map<String, Schema.SObjectField> fieldMap,
        String fieldName
    ) {
        if (String.isNotBlank(fieldName) && fieldMap.containsKey(fieldName)) {
            fields.add(fieldName);
        }
    }

    private static void putSafe(
        SObject target,
        Map<String, Schema.SObjectField> tgtFieldMap,
        String field,
        Object val
    ) {
        if (!tgtFieldMap.containsKey(field) || val == null) { return; }
        try {
            target.put(field, val);
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'putSafe ' + field + ': ' + ex.getMessage());
        }
    }

    private static void copyLookup(
        SObject src,
        SObject target,
        Map<String, Schema.SObjectField> srcFieldMap,
        Map<String, Schema.SObjectField> tgtFieldMap,
        String srcField,
        String tgtField
    ) {
        if (!srcFieldMap.containsKey(srcField) || !tgtFieldMap.containsKey(tgtField)) { return; }
        Object val = src.get(srcField);
        if (val == null) { return; }
        try {
            target.put(tgtField, val);
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN,
                'copyLookup ' + srcField + ' -> ' + tgtField + ': ' + ex.getMessage()
            );
        }
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