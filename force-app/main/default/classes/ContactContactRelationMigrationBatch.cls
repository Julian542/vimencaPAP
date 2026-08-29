/**
 * ContactContactRelationMigrationBatch
 *
 * Migra registros desde Referencia__c y Participante__c
 * hacia FinServ__ContactContactRelation__c (FSC).
 *
 * Uso desde Execute Anonymous (ejecutar uno por uno):
 *   ContactContactRelationMigrationBatch.runBatch('Referencia__c',   200);
 *   ContactContactRelationMigrationBatch.runBatch('Participante__c', 200);
 *
 * Decisiones de diseño:
 *
 *   Referencia__c:
 *     FinServ__Contact__c        ← Account__c
 *       (el CSV indica que Account__c actúa como persona principal;
 *        en orgs FSC con PersonAccounts el mismo Id sirve como ContactId.
 *        Si tu org usa Contact separado, ajusta contactLookupField en
 *        CONTACT_LOOKUP_BY_OBJECT a tu campo de lookup a Contact.)
 *     FinServ__RelatedContact__c ← sin fuente explícita en el CSV para
 *        este objeto. Agregar aquí si se identifica el campo en la org.
 *
 *   Participante__c:
 *     FinServ__Contact__c        ← PAR_Cliente__c  (cuenta/contacto principal)
 *     FinServ__RelatedContact__c ← Participante__c (campo lookup al contacto relacionado)
 *
 *   Campos sin __c en el CSV normalizados:
 *     "Codigo Participante" → Codigo_Participante__c
 *     "Country"             → campo estándar protegido por validación de schema
 *
 *   Todos los campos se validan contra el schema en runtime.
 */
public with sharing class ContactContactRelationMigrationBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    // ─── Configuración de la instancia ──────────────────────────────────────
    private String sourceObjectName;

    // ─── Estadísticas stateful ───────────────────────────────────────────────
    private Integer processedCount = 0;
    private Integer successCount   = 0;
    private Integer errorCount     = 0;
    private List<Migration_Error__c> failedRecords = new List<Migration_Error__c>();
    private Map<String, Id> recordTypeIdByDevName  = new Map<String, Id>();

    // ─── Constantes ──────────────────────────────────────────────────────────
    private static final String CCR_OBJECT        = 'FinServ__ContactContactRelation__c';
    private static final String F_CONTACT         = 'FinServ__Contact__c';
    private static final String F_RELATED_CONTACT = 'FinServ__RelatedContact__c';

    // ─── RecordType por objeto fuente ────────────────────────────────────────
    private static final Map<String, String> RECORD_TYPE_MAP = new Map<String, String>{
        'Referencia__c'   => 'Referencia',
        'Participante__c' => 'Participante'
    };

    // ─── Lookup de contacto principal por objeto ─────────────────────────────
    // Referencia__c → Account__c actúa como persona principal (ver nota de diseño)
    // Participante__c → PAR_Cliente__c
    private static final Map<String, String> CONTACT_LOOKUP_BY_OBJECT = new Map<String, String>{
        'Referencia__c'   => 'Account__c',
        'Participante__c' => 'PAR_Cliente__c'
    };

    // ─── Lookup de contacto relacionado por objeto ───────────────────────────
    // Referencia__c → sin campo explícito en el CSV; dejar null para saltarlo
    // Participante__c → campo Participante__c (lookup al contacto relacionado)
    private static final Map<String, String> RELATED_CONTACT_LOOKUP_BY_OBJECT = new Map<String, String>{
        'Referencia__c'   => null,
        'Participante__c' => 'Participante__c'
    };

    // ─── Mapeos exclusivos de Referencia__c ─────────────────────────────────
    private static final List<String[]> MAPPINGS_REFERENCIA = new List<String[]>{
        new String[]{ 'Name',               'Name'                      },
        new String[]{ 'Banco__c',           'CCR_Banco__c'              },
        new String[]{ 'Tipo_de_cuenta__c',  'CCR_Tipo_de_cuenta__c'     },
        new String[]{ 'REF_Tipo__c',        'CCR_Tipo__c'               },
        new String[]{ 'Moneda__c',          'CCR_Moneda__c'             },
        new String[]{ 'N_de_cuenta__c',     'CCR_N_de_cuenta__c'        },
        new String[]{ 'REF_Id_Externo__c',  'FinServ__ExternalId__c'    },
        new String[]{ 'REF_Id_Externo_bk__c','FinServ__SourceSystemId__c'},
        new String[]{ 'VFS_RNC__c',         'VFS_RNC__c'                },
        new String[]{ 'Pais__c',            'Country'                   }
    };

    // ─── Mapeos exclusivos de Participante__c ────────────────────────────────
    private static final List<String[]> MAPPINGS_PARTICIPANTE = new List<String[]>{
        new String[]{ 'Porcentaje__c',                   'CCR_Porcentaje__c'               },
        new String[]{ 'Tipo__c',                         'CCR_Tipo__c'                     },
        new String[]{ 'PAR_Cargo__c',                    'CCR_Cargo__c'                    },
        new String[]{ 'PAR_Ejecutivo__c',                'CCR_Ejecutivo__c'                },
        new String[]{ 'PAR_Id_Externo__c',               'FinServ__ExternalId__c'          },
        new String[]{ 'VFS_FirmanteConozcaCliente__c',   'CCR_FirmanteConozcaCliente__c'   },
        new String[]{ 'VFS_FirmanteAutorizado__c',       'CCR_Firmante_autorizado__c'      },
        new String[]{ 'VFS_LImiteFirmantesKYC__c',       'CCR_LimiteFirmantesKYC__c'       },
        new String[]{ 'FirmanteDeContratoAutorizado__c', 'CCR_FirmanteDeContratoAutorizado__c'},
        new String[]{ 'VFS_LimiteFirmantesContratos__c', 'CCR_LimiteFirmantesContratos__c' },
        new String[]{ 'VFS_RepresentanteLegal__c',       'CCR_RepresentanteLegal__c'       },
        new String[]{ 'Codigo_Participante__c',          'CCR_Codigo_Participante__c'      }
    };

    // ─────────────────────────────────────────────────────────────────────────

    public ContactContactRelationMigrationBatch(String sourceObjectName) {
        this.sourceObjectName = sourceObjectName;
    }

    public static Id runBatch(String sourceObjectName, Integer scopeSize) {
        Integer finalScope = (scopeSize == null || scopeSize <= 0) ? 200 : scopeSize;
        return Database.executeBatch(
            new ContactContactRelationMigrationBatch(sourceObjectName),
            finalScope
        );
    }

    // ─── start ───────────────────────────────────────────────────────────────
    public Database.QueryLocator start(Database.BatchableContext bc) {
        for (RecordType rt : [
            SELECT Id, DeveloperName FROM RecordType
            WHERE SObjectType = 'FinServ__ContactContactRelation__c'
        ]) {
            recordTypeIdByDevName.put(rt.DeveloperName, rt.Id);
        }

        Schema.SObjectType srcType = Schema.getGlobalDescribe().get(sourceObjectName);
        if (srcType == null) {
            throw new IllegalArgumentException(
                'Objeto fuente no encontrado en la org: ' + sourceObjectName
            );
        }

        Map<String, Schema.SObjectField> srcFields = srcType.getDescribe().fields.getMap();

        Set<String> fieldsToQuery = new Set<String>{ 'Id' };

        // Lookup de contacto principal
        String contactLookup = CONTACT_LOOKUP_BY_OBJECT.get(sourceObjectName);
        if (String.isNotBlank(contactLookup) && srcFields.containsKey(contactLookup)) {
            fieldsToQuery.add(contactLookup);
        }

        // Lookup de contacto relacionado
        String relatedLookup = RELATED_CONTACT_LOOKUP_BY_OBJECT.get(sourceObjectName);
        if (String.isNotBlank(relatedLookup) && srcFields.containsKey(relatedLookup)) {
            fieldsToQuery.add(relatedLookup);
        }

        // Campos específicos del objeto
        for (String[] pair : getMappingsForSource()) {
            if (srcFields.containsKey(pair[0])) {
                fieldsToQuery.add(pair[0]);
            }
        }

        String soql = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ')
            + ' FROM ' + sourceObjectName;
        return Database.getQueryLocator(soql);
    }

    // ─── execute ─────────────────────────────────────────────────────────────
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        Schema.SObjectType srcType = Schema.getGlobalDescribe().get(sourceObjectName);
        if (srcType == null) {
            return;
        }

        Schema.SObjectType ccrType = Schema.getGlobalDescribe().get(CCR_OBJECT);
        if (ccrType == null) {
            System.debug(LoggingLevel.ERROR,
                CCR_OBJECT + ' no encontrado. Verifica que FSC esté instalado.'
            );
            return;
        }

        Map<String, Schema.SObjectField> srcFieldMap = srcType.getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> ccrFieldMap = ccrType.getDescribe().fields.getMap();

        String contactLookup        = CONTACT_LOOKUP_BY_OBJECT.get(sourceObjectName);
        String relatedContactLookup = RELATED_CONTACT_LOOKUP_BY_OBJECT.get(sourceObjectName);
        List<String[]> specificMappings = getMappingsForSource();

        List<SObject> recordsToInsert = new List<SObject>();
        List<Id> sourceIds = new List<Id>();

        for (SObject src : scope) {
            SObject ccr = ccrType.newSObject();

            // ── RecordType según objeto fuente ───────────────────────────────
            String rtDevName = RECORD_TYPE_MAP.get(sourceObjectName);
            if (String.isNotBlank(rtDevName) && recordTypeIdByDevName.containsKey(rtDevName)) {
                ccr.put('RecordTypeId', recordTypeIdByDevName.get(rtDevName));
            }

            // ── FinServ__Contact__c: contacto principal ──────────────────────
            if (String.isNotBlank(contactLookup)
                    && srcFieldMap.containsKey(contactLookup)
                    && ccrFieldMap.containsKey(F_CONTACT)) {
                Object contactId = src.get(contactLookup);
                if (contactId != null) {
                    try {
                        ccr.put(F_CONTACT, contactId);
                    } catch (Exception ex) {
                        System.debug(LoggingLevel.WARN,
                            'No se pudo asignar ' + F_CONTACT + ': ' + ex.getMessage()
                        );
                    }
                }
            }

            // ── FinServ__RelatedContact__c: contacto relacionado ─────────────
            if (String.isNotBlank(relatedContactLookup)
                    && srcFieldMap.containsKey(relatedContactLookup)
                    && ccrFieldMap.containsKey(F_RELATED_CONTACT)) {
                Object relatedId = src.get(relatedContactLookup);
                if (relatedId != null) {
                    try {
                        ccr.put(F_RELATED_CONTACT, relatedId);
                    } catch (Exception ex) {
                        System.debug(LoggingLevel.WARN,
                            'No se pudo asignar ' + F_RELATED_CONTACT + ': ' + ex.getMessage()
                        );
                    }
                }
            }

            // ── Campos específicos del objeto fuente ─────────────────────────
            applyMappings(src, ccr, specificMappings, srcFieldMap, ccrFieldMap);

            sourceIds.add((Id) src.get('Id'));
            recordsToInsert.add(ccr);
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
                            '[' + sourceObjectName + '] Error insertando CCR: ' + e.getMessage()
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
            'Migración ' + sourceObjectName + ' -> ' + CCR_OBJECT + ' terminada. ' +
            'Procesados=' + processedCount +
            ', Exitosos=' + successCount +
            ', Errores=' + errorCount
        );
        if (!failedRecords.isEmpty()) {
            Database.insert(failedRecords, false);
        }
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private List<String[]> getMappingsForSource() {
        if (sourceObjectName == 'Referencia__c') {
            return MAPPINGS_REFERENCIA;
        }
        if (sourceObjectName == 'Participante__c') {
            return MAPPINGS_PARTICIPANTE;
        }
        return new List<String[]>();
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