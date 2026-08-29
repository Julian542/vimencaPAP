/**
 * ViasDeContactoMigrationBatch
 *
 * Migra registros desde Vias_de_Contacto__c hacia:
 *   - ContactPointPhone
 *   - ContactPointEmail
 *
 * Reglas de clasificacion por VIA_de_Contacto__c:
 *   - Phone: TELEFONO FIJO, TELEFONO MOVIL, TELEFONO FAX,
 *            TELEFONO EN EL EXTERIOR, MOVIL EN EL EXTERIOR, TELEFONO TRABAJO
 *   - Email: CORREO LABORAL, CORREO ELECTRONICO
 *   - Omitir: SITIO/PAGINA WEB y cualquier otro valor
 *
 * Uso desde Execute Anonymous:
 *   ViasDeContactoMigrationBatch.runBatch(200);
 */
public with sharing class ViasDeContactoMigrationBatch
        implements Database.Batchable<SObject>, Database.Stateful {

    private static final String SOURCE_OBJECT = 'Vias_de_Contacto__c';
    private static final String PHONE_OBJECT  = 'ContactPointPhone';
    private static final String EMAIL_OBJECT  = 'ContactPointEmail';

    // Campos de fuente
    private static final String F_SOURCE_ID      = 'Id';
    private static final String F_SRC_ACCOUNT    = 'VIA_Account__c';
    private static final String F_SRC_VALUE      = 'VIA_Numero_Correo__c';
    private static final String F_SRC_PRIMARY    = 'VIA_Principal__c';
    private static final String F_SRC_TELEFONICA = 'VIA_Telefonica__c';
    private static final String F_SRC_VIA_TIPO   = 'VIA_de_Contacto__c';

    // Campos en Phone
    private static final String F_PHONE_PARENT      = 'ParentId';
    private static final String F_PHONE_NUMBER      = 'TelephoneNumber';
    private static final String F_PHONE_IS_PRIMARY  = 'IsPrimary';
    private static final String F_PHONE_TIPO        = 'CPP_Tipo__c';
    private static final String F_PHONE_TELEFONICA  = 'CPP_Telefonica__c';

    // Campos en Email
    private static final String F_EMAIL_PARENT      = 'ParentId';
    private static final String F_EMAIL_ADDRESS     = 'EmailAddress';
    private static final String F_EMAIL_IS_PRIMARY  = 'IsPrimary';
    private static final String F_EMAIL_TIPO        = 'CPE_Tipo__c';

    // Candidatos para idempotencia por SourceSystemId / ExternalId
    @TestVisible
    private static final List<String> PHONE_IDEMPOTENCY_FIELDS = new List<String>{
        'FinServ__SourceSystemId__c',
        'SourceSystemId',
        'SourceSystemIdentifier',
        'CPP_ExternalId__c'
    };

    @TestVisible
    private static final List<String> EMAIL_IDEMPOTENCY_FIELDS = new List<String>{
        'FinServ__SourceSystemId__c',
        'SourceSystemId',
        'SourceSystemIdentifier',
        'CPE_ExternalId__c'
    };

    // Estadisticas stateful
    private Integer processedCount = 0;
    private Integer successCount   = 0;
    private Integer errorCount     = 0;
    private Integer skippedCount   = 0;

    private List<Migration_Error__c> failedRecords = new List<Migration_Error__c>();

    public static Id runBatch(Integer scopeSize) {
        Integer finalScope = (scopeSize == null || scopeSize <= 0) ? 200 : scopeSize;
        return Database.executeBatch(new ViasDeContactoMigrationBatch(), finalScope);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Schema.SObjectType srcType = Schema.getGlobalDescribe().get(SOURCE_OBJECT);
        if (srcType == null) {
            throw new IllegalArgumentException(SOURCE_OBJECT + ' no encontrado en la org.');
        }

        Map<String, Schema.SObjectField> srcFields = srcType.getDescribe().fields.getMap();
        Set<String> fieldsToQuery = new Set<String>{ F_SOURCE_ID };

        for (String f : new List<String>{
            F_SRC_ACCOUNT,
            F_SRC_VALUE,
            F_SRC_PRIMARY,
            F_SRC_TELEFONICA,
            F_SRC_VIA_TIPO
        }) {
            if (srcFields.containsKey(f)) {
                fieldsToQuery.add(f);
            }
        }

        return Database.getQueryLocator(
            'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ')
            + ' FROM ' + SOURCE_OBJECT
        );
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            executeInternal(bc, scope);
        } catch (Exception ex) {
            // Captura de seguridad del bloque para que el batch continúe.
            errorCount++;
            failedRecords.add(new Migration_Error__c(
                MEE_Record_Id__c     = null,
                MEE_Batch_Job_Id__c  = bc.getJobId(),
                MEE_Mensaje_Error__c = 'Error inesperado en execute: ' + ex.getMessage()
            ));
            System.debug(LoggingLevel.ERROR,
                'Error inesperado en execute de ' + SOURCE_OBJECT + ': ' + ex.getMessage()
            );
        }
    }

    private void executeInternal(Database.BatchableContext bc, List<SObject> scope) {
        Schema.SObjectType srcType   = Schema.getGlobalDescribe().get(SOURCE_OBJECT);
        Schema.SObjectType phoneType = Schema.getGlobalDescribe().get(PHONE_OBJECT);
        Schema.SObjectType emailType = Schema.getGlobalDescribe().get(EMAIL_OBJECT);

        if (srcType == null || phoneType == null || emailType == null) {
            errorCount++;
            failedRecords.add(new Migration_Error__c(
                MEE_Record_Id__c     = null,
                MEE_Batch_Job_Id__c  = bc.getJobId(),
                MEE_Mensaje_Error__c = 'Objeto(s) no encontrado(s): '
                    + SOURCE_OBJECT + ', ' + PHONE_OBJECT + ', ' + EMAIL_OBJECT
            ));
            return;
        }

        Map<String, Schema.SObjectField> srcFieldMap   = srcType.getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> phoneFieldMap = phoneType.getDescribe().fields.getMap();
        Map<String, Schema.SObjectField> emailFieldMap = emailType.getDescribe().fields.getMap();

        String phoneIdempotencyField = getFirstExistingField(phoneFieldMap, PHONE_IDEMPOTENCY_FIELDS);
        String emailIdempotencyField = getFirstExistingField(emailFieldMap, EMAIL_IDEMPOTENCY_FIELDS);

        List<SObject> phonesToInsert = new List<SObject>();
        List<SObject> emailsToInsert = new List<SObject>();

        List<Id> phoneSourceIds = new List<Id>();
        List<Id> emailSourceIds = new List<Id>();

        Set<String> phoneSourceKeys = new Set<String>();
        Set<String> emailSourceKeys = new Set<String>();

        Set<Id> candidatePhoneParents = new Set<Id>();
        Set<Id> candidateEmailParents = new Set<Id>();

        for (SObject src : scope) {
            Id sourceId = (Id) src.get(F_SOURCE_ID);
            processedCount++;

            try {
                if (!srcFieldMap.containsKey(F_SRC_ACCOUNT) || !srcFieldMap.containsKey(F_SRC_VIA_TIPO)) {
                    skippedCount++;
                    continue;
                }

                Id parentId = (Id) src.get(F_SRC_ACCOUNT);
                if (parentId == null) {
                    skippedCount++;
                    continue;
                }

                String viaTipoOriginal = srcFieldMap.containsKey(F_SRC_VIA_TIPO)
                    ? (String) src.get(F_SRC_VIA_TIPO)
                    : null;
                String viaTipoNorm = normalizeViaType(viaTipoOriginal);

                String channel = classifyChannel(viaTipoNorm);
                if (channel == 'SKIP') {
                    skippedCount++;
                    continue;
                }

                String rawValue = srcFieldMap.containsKey(F_SRC_VALUE)
                    ? (String) src.get(F_SRC_VALUE)
                    : null;

                if (channel == 'PHONE') {
                    String cleanPhone = sanitizePhone(rawValue);
                    if (String.isBlank(cleanPhone)) {
                        skippedCount++;
                        continue;
                    }

                    SObject phone = phoneType.newSObject();
                    putSafe(phone, phoneFieldMap, F_PHONE_PARENT, parentId);
                    putSafe(phone, phoneFieldMap, F_PHONE_NUMBER, cleanPhone);
                    putSafe(phone, phoneFieldMap, F_PHONE_TIPO, viaTipoOriginal);

                    if (srcFieldMap.containsKey(F_SRC_PRIMARY)) {
                        putSafe(phone, phoneFieldMap, F_PHONE_IS_PRIMARY, src.get(F_SRC_PRIMARY));
                    }
                    if (srcFieldMap.containsKey(F_SRC_TELEFONICA)) {
                        putSafe(phone, phoneFieldMap, F_PHONE_TELEFONICA, src.get(F_SRC_TELEFONICA));
                    }

                    if (String.isNotBlank(phoneIdempotencyField)) {
                        String sourceKey = String.valueOf(sourceId);
                        putSafe(phone, phoneFieldMap, phoneIdempotencyField, sourceKey);
                        phoneSourceKeys.add(sourceKey);
                    } else {
                        candidatePhoneParents.add(parentId);
                    }

                    phonesToInsert.add(phone);
                    phoneSourceIds.add(sourceId);
                } else if (channel == 'EMAIL') {
                    String emailAddress = (rawValue == null) ? null : rawValue.trim();
                    if (String.isBlank(emailAddress)) {
                        skippedCount++;
                        continue;
                    }

                    SObject email = emailType.newSObject();
                    putSafe(email, emailFieldMap, F_EMAIL_PARENT, parentId);
                    putSafe(email, emailFieldMap, F_EMAIL_ADDRESS, emailAddress);
                    putSafe(email, emailFieldMap, F_EMAIL_TIPO, viaTipoOriginal);

                    if (srcFieldMap.containsKey(F_SRC_PRIMARY)) {
                        putSafe(email, emailFieldMap, F_EMAIL_IS_PRIMARY, src.get(F_SRC_PRIMARY));
                    }

                    if (String.isNotBlank(emailIdempotencyField)) {
                        String sourceKey = String.valueOf(sourceId);
                        putSafe(email, emailFieldMap, emailIdempotencyField, sourceKey);
                        emailSourceKeys.add(sourceKey);
                    } else {
                        candidateEmailParents.add(parentId);
                    }

                    emailsToInsert.add(email);
                    emailSourceIds.add(sourceId);
                }
            } catch (Exception exRecord) {
                errorCount++;
                failedRecords.add(new Migration_Error__c(
                    MEE_Record_Id__c     = sourceId,
                    MEE_Batch_Job_Id__c  = bc.getJobId(),
                    MEE_Mensaje_Error__c = 'Error transformando registro: ' + exRecord.getMessage()
                ));
            }
        }

        // Evitar duplicados por re-ejecucion.
        Set<String> existingPhoneKeysBySource = new Set<String>();
        Set<String> existingEmailKeysBySource = new Set<String>();
        Set<String> existingPhoneSignatures   = new Set<String>();
        Set<String> existingEmailSignatures   = new Set<String>();

        if (!phonesToInsert.isEmpty()) {
            if (String.isNotBlank(phoneIdempotencyField) && !phoneSourceKeys.isEmpty()) {
                for (SObject row : queryBySourceKeys(PHONE_OBJECT, phoneIdempotencyField, phoneSourceKeys)) {
                    Object key = row.get(phoneIdempotencyField);
                    if (key != null) {
                        existingPhoneKeysBySource.add(String.valueOf(key));
                    }
                }
            } else if (!candidatePhoneParents.isEmpty()) {
                existingPhoneSignatures = getExistingPhoneSignatures(candidatePhoneParents, phoneFieldMap);
            }
        }

        if (!emailsToInsert.isEmpty()) {
            if (String.isNotBlank(emailIdempotencyField) && !emailSourceKeys.isEmpty()) {
                for (SObject row : queryBySourceKeys(EMAIL_OBJECT, emailIdempotencyField, emailSourceKeys)) {
                    Object key = row.get(emailIdempotencyField);
                    if (key != null) {
                        existingEmailKeysBySource.add(String.valueOf(key));
                    }
                }
            } else if (!candidateEmailParents.isEmpty()) {
                existingEmailSignatures = getExistingEmailSignatures(candidateEmailParents, emailFieldMap);
            }
        }

        List<SObject> dedupedPhones = new List<SObject>();
        List<Id> dedupedPhoneSourceIds = new List<Id>();
        for (Integer i = 0; i < phonesToInsert.size(); i++) {
            SObject row = phonesToInsert[i];
            if (String.isNotBlank(phoneIdempotencyField)) {
                String key = String.valueOf(row.get(phoneIdempotencyField));
                if (existingPhoneKeysBySource.contains(key)) {
                    skippedCount++;
                    continue;
                }
            } else {
                String sig = buildPhoneSignature(row);
                if (existingPhoneSignatures.contains(sig)) {
                    skippedCount++;
                    continue;
                }
                existingPhoneSignatures.add(sig);
            }
            dedupedPhones.add(row);
            dedupedPhoneSourceIds.add(phoneSourceIds[i]);
        }

        List<SObject> dedupedEmails = new List<SObject>();
        List<Id> dedupedEmailSourceIds = new List<Id>();
        for (Integer i = 0; i < emailsToInsert.size(); i++) {
            SObject row = emailsToInsert[i];
            if (String.isNotBlank(emailIdempotencyField)) {
                String key = String.valueOf(row.get(emailIdempotencyField));
                if (existingEmailKeysBySource.contains(key)) {
                    skippedCount++;
                    continue;
                }
            } else {
                String sig = buildEmailSignature(row);
                if (existingEmailSignatures.contains(sig)) {
                    skippedCount++;
                    continue;
                }
                existingEmailSignatures.add(sig);
            }
            dedupedEmails.add(row);
            dedupedEmailSourceIds.add(emailSourceIds[i]);
        }

        insertWithLogging(dedupedPhones, dedupedPhoneSourceIds, bc, 'PHONE');
        insertWithLogging(dedupedEmails, dedupedEmailSourceIds, bc, 'EMAIL');
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'Migracion ' + SOURCE_OBJECT + ' -> ContactPointPhone/ContactPointEmail terminada. '
            + 'Procesados=' + processedCount
            + ', Exitosos=' + successCount
            + ', Errores=' + errorCount
            + ', Omitidos=' + skippedCount
        );

        if (!failedRecords.isEmpty()) {
            Database.insert(failedRecords, false);
        }
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    @TestVisible
    private static String classifyChannel(String viaTipoNorm) {
        if (String.isBlank(viaTipoNorm)) {
            return 'SKIP';
        }

        if (PHONE_TYPES.contains(viaTipoNorm)) {
            return 'PHONE';
        }
        if (EMAIL_TYPES.contains(viaTipoNorm)) {
            return 'EMAIL';
        }
        return 'SKIP';
    }

    @TestVisible
    private static final Set<String> PHONE_TYPES = new Set<String>{
        'TELEFONO FIJO',
        'TELEFONO MOVIL',
        'TELEFONO FAX',
        'TELEFONO EN EL EXTERIOR',
        'MOVIL EN EL EXTERIOR',
        'TELEFONO TRABAJO'
    };

    @TestVisible
    private static final Set<String> EMAIL_TYPES = new Set<String>{
        'CORREO LABORAL',
        'CORREO ELECTRONICO'
    };

    @TestVisible
    private static String normalizeViaType(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        String val = raw.trim().toUpperCase();
        // Normalizacion basica para soportar acentos comunes.
        val = val.replace('Á', 'A');
        val = val.replace('É', 'E');
        val = val.replace('Í', 'I');
        val = val.replace('Ó', 'O');
        val = val.replace('Ú', 'U');
        val = val.replace('Ü', 'U');
        return val;
    }

    @TestVisible
    private static String sanitizePhone(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        String clean = raw.replaceAll('[^0-9]', '');
        return String.isBlank(clean) ? null : clean;
    }

    private static String getFirstExistingField(
        Map<String, Schema.SObjectField> fieldMap,
        List<String> candidates
    ) {
        for (String f : candidates) {
            if (fieldMap.containsKey(f)) {
                return f;
            }
        }
        return null;
    }

    private static void putSafe(
        SObject target,
        Map<String, Schema.SObjectField> targetFieldMap,
        String fieldName,
        Object value
    ) {
        if (value == null || !targetFieldMap.containsKey(fieldName)) {
            return;
        }

        try {
            if (!targetFieldMap.get(fieldName).getDescribe().isCalculated()) {
                target.put(fieldName, value);
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN,
                'No se pudo asignar campo ' + fieldName + ': ' + ex.getMessage()
            );
        }
    }

    private static List<SObject> queryBySourceKeys(
        String objectName,
        String sourceField,
        Set<String> keys
    ) {
        if (String.isBlank(objectName) || String.isBlank(sourceField) || keys.isEmpty()) {
            return new List<SObject>();
        }

        return Database.query(
            'SELECT Id, ' + sourceField
            + ' FROM ' + objectName
            + ' WHERE ' + sourceField + ' IN :keys'
        );
    }

    private static Set<String> getExistingPhoneSignatures(
        Set<Id> parentIds,
        Map<String, Schema.SObjectField> phoneFieldMap
    ) {
        Set<String> signatures = new Set<String>();
        if (parentIds.isEmpty()) {
            return signatures;
        }

        List<String> fields = new List<String>{ F_PHONE_PARENT, F_PHONE_NUMBER };
        if (phoneFieldMap.containsKey(F_PHONE_TIPO)) {
            fields.add(F_PHONE_TIPO);
        }

        List<SObject> rows = Database.query(
            'SELECT ' + String.join(fields, ', ')
            + ' FROM ' + PHONE_OBJECT
            + ' WHERE ParentId IN :parentIds'
        );

        for (SObject row : rows) {
            signatures.add(buildPhoneSignature(row));
        }
        return signatures;
    }

    private static Set<String> getExistingEmailSignatures(
        Set<Id> parentIds,
        Map<String, Schema.SObjectField> emailFieldMap
    ) {
        Set<String> signatures = new Set<String>();
        if (parentIds.isEmpty()) {
            return signatures;
        }

        List<String> fields = new List<String>{ F_EMAIL_PARENT, F_EMAIL_ADDRESS };
        if (emailFieldMap.containsKey(F_EMAIL_TIPO)) {
            fields.add(F_EMAIL_TIPO);
        }

        List<SObject> rows = Database.query(
            'SELECT ' + String.join(fields, ', ')
            + ' FROM ' + EMAIL_OBJECT
            + ' WHERE ParentId IN :parentIds'
        );

        for (SObject row : rows) {
            signatures.add(buildEmailSignature(row));
        }
        return signatures;
    }

    private static String buildPhoneSignature(SObject row) {
        String parent = String.valueOf(row.get(F_PHONE_PARENT));
        String phoneNumber = sanitizePhone((String) row.get(F_PHONE_NUMBER));
        String tipo = normalizeViaType((String) row.get(F_PHONE_TIPO));
        return parent + '|' + phoneNumber + '|' + tipo;
    }

    private static String buildEmailSignature(SObject row) {
        String parent = String.valueOf(row.get(F_EMAIL_PARENT));
        String email = (String) row.get(F_EMAIL_ADDRESS);
        String tipo = normalizeViaType((String) row.get(F_EMAIL_TIPO));
        return parent + '|' + ((email == null) ? null : email.trim().toLowerCase()) + '|' + tipo;
    }

    private void insertWithLogging(
        List<SObject> records,
        List<Id> sourceIds,
        Database.BatchableContext bc,
        String channel
    ) {
        if (records.isEmpty()) {
            return;
        }

        Database.SaveResult[] results = Database.insert(records, false);
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                successCount++;
            } else {
                errorCount++;
                List<String> msgs = new List<String>();
                for (Database.Error e : results[i].getErrors()) {
                    msgs.add(e.getStatusCode() + ': ' + e.getMessage());
                }
                failedRecords.add(new Migration_Error__c(
                    MEE_Record_Id__c     = sourceIds[i],
                    MEE_Batch_Job_Id__c  = bc.getJobId(),
                    MEE_Mensaje_Error__c = channel + ': ' + String.join(msgs, '\n')
                ));
            }
        }
    }
}