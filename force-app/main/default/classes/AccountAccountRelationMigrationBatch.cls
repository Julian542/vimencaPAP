/**
 * AccountAccountRelationMigrationBatch
 *
 * Migra registros desde Empresa_Filial__c hacia FinServ__AccountAccountRelation__c.
 *
 * Uso desde Execute Anonymous:
 *   AccountAccountRelationMigrationBatch.runBatch(200);
 *
 * Decisiones de diseño:
 *   - FinServ__Account__c    = lookup al Account dueño del registro (Cliente__c)
 *   - Todos los campos se validan contra el schema en runtime para evitar errores
 *     si algún campo aún no existe en la sandbox.
 */
public with sharing class AccountAccountRelationMigrationBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    // ─── Objeto fuente ────────────────────────────────────────────────────────
    private static final String SOURCE_OBJECT = 'Empresa_Filial__c';

    // ─── Estadísticas stateful ───────────────────────────────────────────────
    private Integer processedCount = 0;
    private Integer successCount   = 0;
    private Integer errorCount     = 0;
    private List<Migration_Error__c> failedRecords = new List<Migration_Error__c>();
    private Map<String, Id> recordTypeIdByDevName  = new Map<String, Id>();

    // ─── Constantes de campo ─────────────────────────────────────────────────
    private static final String AAR_OBJECT = 'FinServ__AccountAccountRelation__c';
    private static final String F_ACCOUNT = 'FinServ__Account__c';

    // Campos comunes a todos los objetos fuente (origen → destino)
    // El lookup de cuenta padre se resuelve aparte según el objeto.
    private static final List<String[]> MAPPINGS_COMMON = new List<String[]>{
        new String[]{ 'Tipo__c', 'AAR_Tipo__c' }
    };

    // Campos exclusivos de Empresa_Filial__c
    private static final List<String[]> MAPPINGS_EMPRESA_FILIAL = new List<String[]>{
        new String[]{ 'Grupo_economico__c',   'AAR_Grupo_economico__c'  },
        new String[]{ 'Grupo_financiero__c',  'AAR_Grupo_financiero__c' },
        new String[]{ 'Pais_donde_opera__c',  'AAR_Pais_donde_opera__c' }
    };

    // ─── Configuración de campo lookup de cuenta padre ─────────────────────
    private static final String ACCOUNT_LOOKUP_FIELD = 'Cliente__c';

    // ─── RecordType para Empresa_Filial__c ────────────────────────────────────
    private static final String RECORD_TYPE_DEV_NAME = 'Empresa_Filial';

    // ─────────────────────────────────────────────────────────────────────────

    public AccountAccountRelationMigrationBatch() {}

    public static Id runBatch(Integer scopeSize) {
        Integer finalScope = (scopeSize == null || scopeSize <= 0) ? 200 : scopeSize;
        return Database.executeBatch(
            new AccountAccountRelationMigrationBatch(),
            finalScope
        );
    }

    // ─── start ───────────────────────────────────────────────────────────────
    public Database.QueryLocator start(Database.BatchableContext bc) {
        for (RecordType rt : [
            SELECT Id, DeveloperName FROM RecordType
            WHERE SObjectType = 'FinServ__AccountAccountRelation__c'
        ]) {
            recordTypeIdByDevName.put(rt.DeveloperName, rt.Id);
        }

        Schema.SObjectType srcType = Schema.getGlobalDescribe().get(SOURCE_OBJECT);
        if (srcType == null) {
            throw new IllegalArgumentException(
                'Objeto fuente no encontrado en la org: ' + SOURCE_OBJECT
            );
        }

        Map<String, Schema.SObjectField> srcFields = srcType.getDescribe().fields.getMap();

        Set<String> fieldsToQuery = new Set<String>{ 'Id' };

        // Campo lookup de cuenta padre
        if (srcFields.containsKey(ACCOUNT_LOOKUP_FIELD)) {
            fieldsToQuery.add(ACCOUNT_LOOKUP_FIELD);
        }

        // Campos comunes
        for (String[] pair : MAPPINGS_COMMON) {
            if (srcFields.containsKey(pair[0])) {
                fieldsToQuery.add(pair[0]);
            }
        }

        // Campos específicos de Empresa_Filial__c
        for (String[] pair : MAPPINGS_EMPRESA_FILIAL) {
            if (srcFields.containsKey(pair[0])) {
                fieldsToQuery.add(pair[0]);
            }
        }

        String soql = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ')
            + ' FROM ' + SOURCE_OBJECT;
        return Database.getQueryLocator(soql);
    }

    // ─── execute ─────────────────────────────────────────────────────────────
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        Schema.SObjectType srcType = Schema.getGlobalDescribe().get(SOURCE_OBJECT);
        if (srcType == null) {
            return;
        }

        Schema.SObjectType aarType = Schema.getGlobalDescribe().get(AAR_OBJECT);
        if (aarType == null) {
            System.debug(LoggingLevel.ERROR,
                AAR_OBJECT + ' no encontrado. Verifica que FSC esté instalado.'
            );
            return;
        }

        Map<String, Schema.SObjectField> srcFieldMap = srcType.getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> aarFieldMap = aarType.getDescribe().fields.getMap();

        List<SObject> recordsToInsert = new List<SObject>();
        List<Id> sourceIds = new List<Id>();

        for (SObject src : scope) {
            SObject aar = aarType.newSObject();

            // ── RecordType ───────────────────────────────────────────────────
            if (recordTypeIdByDevName.containsKey(RECORD_TYPE_DEV_NAME)) {
                aar.put('RecordTypeId', recordTypeIdByDevName.get(RECORD_TYPE_DEV_NAME));
            }

            // ── FinServ__Account__c: lookup al Account dueño del registro ────
            if (srcFieldMap.containsKey(ACCOUNT_LOOKUP_FIELD)
                    && aarFieldMap.containsKey(F_ACCOUNT)) {
                Object accountId = src.get(ACCOUNT_LOOKUP_FIELD);
                if (accountId != null) {
                    try {
                        aar.put(F_ACCOUNT, accountId);
                    } catch (Exception ex) {
                        System.debug(LoggingLevel.WARN,
                            'No se pudo asignar ' + F_ACCOUNT + ': ' + ex.getMessage()
                        );
                    }
                }
            }

            // ── Campos comunes ───────────────────────────────────────────────
            applyMappings(src, aar, MAPPINGS_COMMON, srcFieldMap, aarFieldMap);

            // ── Campos específicos de Empresa_Filial__c ──────────────────────
            applyMappings(src, aar, MAPPINGS_EMPRESA_FILIAL, srcFieldMap, aarFieldMap);

            sourceIds.add((Id) src.get('Id'));
            recordsToInsert.add(aar);
        }

        if (!recordsToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(recordsToInsert, false);
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
                        System.debug(LoggingLevel.ERROR,
                            '[' + SOURCE_OBJECT + '] Error insertando AAR: ' + e.getMessage()
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
    }

    // ─── finish ──────────────────────────────────────────────────────────────
    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'Migración ' + SOURCE_OBJECT + ' -> ' + AAR_OBJECT + ' terminada. ' +
            'Procesados=' + processedCount +
            ', Exitosos=' + successCount +
            ', Errores=' + errorCount
        );
        if (!failedRecords.isEmpty()) {
            Database.insert(failedRecords, false);
        }
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

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

            if (!srcFieldMap.containsKey(srcField) || !tgtFieldMap.containsKey(tgtField)) {
                continue;
            }

            if (tgtFieldMap.get(tgtField).getDescribe().isCalculated()) {
                continue;
            }

            Object val = src.get(srcField);
            if (val == null) {
                continue;
            }

            try {
                target.put(tgtField, val);
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN,
                    'No se pudo mapear ' + srcField + ' -> ' + tgtField + ': ' + ex.getMessage()
                );
            }
        }
    }
}