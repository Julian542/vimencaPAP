public with sharing class AGENTE_RegistrarCargoNoReconocido {

    private static final String CASE_SUBJECT = 'Reclamaciones por cargos o consumos no reconocidos';

    public class InvocableInput {
        @InvocableVariable(required=false)
        public Id accountId;
        
        @InvocableVariable(required=false)
        public String financialAccountNumber;

        @InvocableVariable(required=false)
        public Id messagingSessionId;

        @InvocableVariable(required=false)
        public String customerType; // PF o PJ

        @InvocableVariable(required=false)
        public String identificationNumber;

        @InvocableVariable(required=false)
        public String identificationType;

        @InvocableVariable(required=false)
        public String cif;

        @InvocableVariable(required=false)
        public String accountName;

        @InvocableVariable(required=false)
        public String selectedProductLabel;

        @InvocableVariable(required=false)
        public String selectedProductKey;

        @InvocableVariable(required=true)
        public String selectedTransactionJson;

        @InvocableVariable(required=false)
        public String customerStatement;

        @InvocableVariable(required=false)
        public String channel; // Web, WhatsApp, Chat, etc.

        @InvocableVariable(required=false)
        public String targetQueueName; // Cola Reclamaciones / Teleasistencia

        @InvocableVariable(required=false)
        public Boolean createCase;

        @InvocableVariable(required=false)
        public Boolean requiresTransfer;
    }

    public class InvocableOutput {
        @InvocableVariable
        public String status; // OK / ERROR / INVALID_INPUT / ACCOUNT_NOT_FOUND / ACCOUNT_INACTIVE

        @InvocableVariable
        public String message;

        @InvocableVariable
        public Id caseId;

        @InvocableVariable
        public String caseNumber;

        @InvocableVariable
        public Boolean shouldTransfer;

        @InvocableVariable
        public String targetQueueName;

        @InvocableVariable
        public String summary;

        @InvocableVariable
        public String displayText;

        @InvocableVariable
        public Boolean messagingSessionLinked;
    }

    private class TransactionData {
        public String transactionId;
        public String transactionDate;
        public String postingDate;
        public String description;
        public String amount;
        public String currencyCode;
        public String debitCredit;
        public String merchant;
        public String reference;
        public String maskedProductNumber;
        public String rawJson;
    }

    @InvocableMethod(
        label='Reclamaciones por cargos o consumos no reconocidos'
        description='Registra un caso de cargo no reconocido a partir de una transacción seleccionada por el cliente autenticado'
    )
    public static List<InvocableOutput> registrarCargoNoReconocido(List<InvocableInput> inputs) {
        List<InvocableOutput> outputs = new List<InvocableOutput>();

        if (inputs == null || inputs.isEmpty()) {
            InvocableOutput out = new InvocableOutput();
            out.status = 'INVALID_INPUT';
            out.message = 'No se recibió información de entrada.';
            out.displayText = 'No fue posible procesar la solicitud.';
            out.shouldTransfer = false;
            out.messagingSessionLinked = false;
            outputs.add(out);
            return outputs;
        }

        for (InvocableInput input : inputs) {
            outputs.add(processSingle(input));
        }

        return outputs;
    }

    private static InvocableOutput processSingle(InvocableInput input) {
        InvocableOutput out = new InvocableOutput();
        out.shouldTransfer = false;
        out.messagingSessionLinked = false;
        out.targetQueueName = (input == null || String.isBlank(input.targetQueueName))
            ? 'Casos Agentforce Vimencash'
            : input.targetQueueName;

        try {
            validateInput(input);

            Account acct = resolveAccount(input);
            if (acct == null) {
                out.status = 'ACCOUNT_NOT_FOUND';
                out.message = 'No fue posible identificar la cuenta asociada al reclamo.';
                out.displayText = 'No pude identificar de forma segura la cuenta asociada a la transacción.';
                return out;
            }

            if (!isActiveAccount(acct)) {
                out.status = 'ACCOUNT_INACTIVE';
                out.message = 'La cuenta asociada no se encuentra activa.';
                out.displayText = 'No es posible continuar por este canal porque la cuenta no se encuentra activa.';
                return out;
            }

            FinServ__FinancialAccount__c financialAccount =
            resolveFinancialAccount(input.financialAccountNumber);
            
            TransactionData tx = parseTransaction(input.selectedTransactionJson);

            String summary = buildSummary(acct, input, tx);
            out.summary = summary;

            Boolean mustCreateCase = (input.createCase == null) ? true : input.createCase;
            Boolean mustTransfer = (input.requiresTransfer == null) ? true : input.requiresTransfer;

            if (mustCreateCase) {
                Case newCase = buildCase(acct, financialAccount, input, tx, summary);
                insert newCase;

                Case insertedCase = [
                    SELECT Id, CaseNumber, Subject
                    FROM Case
                    WHERE Id = :newCase.Id
                    LIMIT 1
                ];

                out.caseId = insertedCase.Id;
                out.caseNumber = insertedCase.CaseNumber;
                   // Crear la transacción relacionada al caso
                createTransaction(
                insertedCase.Id,
                input,
                 tx
                 );
                if (input.messagingSessionId != null) {
                    out.messagingSessionLinked = linkCaseToMessagingSession(input.messagingSessionId, insertedCase.Id);
                }
            }

            out.status = 'OK';
            out.message = 'Reclamacion por cargos o consumos no reconocidos registrado correctamente.';
            out.shouldTransfer = mustTransfer;
            out.targetQueueName = mustTransfer ? out.targetQueueName : null;
            out.displayText = mustCreateCase
                ? 'He registrado tu solicitud de Reclamacion por cargos o consumos no reconocidos con el número de caso ' + out.caseNumber + '.'
                : 'He registrado la solicitud de Reclamacion por cargos o consumos no reconocidos.';

            return out;

        } catch (AuraHandledException e) {
            out.status = 'INVALID_INPUT';
            out.message = e.getMessage();
            out.displayText = 'No fue posible procesar la solicitud: ' + e.getMessage();
            return out;

        } catch (Exception e) {
            out.status = 'ERROR';
            out.message = 'Ocurrió un error al registrar la Reclamacion por cargos o consumos no reconocidos: ' + e.getMessage();
            out.displayText = 'Ocurrió un error al registrar la solicitud en este momento.';
            return out;
        }
    }

    private static void validateInput(InvocableInput input) {
        if (input == null) {
            throw new AuraHandledException('La solicitud está vacía.');
        }

        if (String.isBlank(input.selectedTransactionJson)) {
            throw new AuraHandledException('Debe indicar la transacción seleccionada.');
        }

        if (input.accountId == null && String.isBlank(input.identificationNumber) && String.isBlank(input.cif)) {
            throw new AuraHandledException('Debe indicar accountId o datos de identificación para resolver la cuenta.');
        }

        if (!String.isBlank(input.customerType)) {
            String ct = input.customerType.trim().toUpperCase();
            if (ct != 'PF' && ct != 'PJ') {
                throw new AuraHandledException('El tipo de cliente debe ser PF o PJ.');
            }
        }
    }

    private static Account resolveAccount(InvocableInput input) {
        if (input.accountId != null) {
            List<Account> byId = [
              SELECT Id,
                Name,
                ACC_Estado__c,
                ACC_NumIdentificacion__c,
                ACC_RNC__c,
                ACC_Correo_Electronico_Cliente__c
                FROM Account
                WHERE Id = :input.accountId
                LIMIT 1
            ];
            return byId.isEmpty() ? null : byId[0];
        }

        String customerType = String.isBlank(input.customerType) ? '' : input.customerType.trim().toUpperCase();

        if (customerType == 'PJ' || !String.isBlank(input.cif)) {
            String normalizedRnc = normalizeDoc(input.cif);
            if (String.isBlank(normalizedRnc)) {
                return null;
            }

            List<Account> byRnc = [
                SELECT Id, Name, ACC_Estado__c, ACC_NumIdentificacion__c, ACC_RNC__c
                FROM Account
                WHERE ACC_RNC__c = :normalizedRnc
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            return byRnc.isEmpty() ? null : byRnc[0];
        }

        String normalizedId = normalizeDoc(input.identificationNumber);
        if (String.isBlank(normalizedId)) {
            return null;
        }

        List<Account> byIdentification = [
            SELECT Id, Name, ACC_Estado__c, ACC_NumIdentificacion__c, ACC_RNC__c
            FROM Account
            WHERE ACC_NumIdentificacion__c = :normalizedId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return byIdentification.isEmpty() ? null : byIdentification[0];
    }
    private static FinServ__FinancialAccount__c resolveFinancialAccount(String accountNumber) {

    if (String.isBlank(accountNumber)) {
        return null;
    }

    List<FinServ__FinancialAccount__c> financialAccounts = [
        SELECT Id, FinServ__FinancialAccountNumber__c
        FROM FinServ__FinancialAccount__c
        WHERE FinServ__FinancialAccountNumber__c = :accountNumber
        LIMIT 1
    ];

    return financialAccounts.isEmpty() ? null : financialAccounts[0];
}

    private static Boolean isActiveAccount(Account acct) {
        String status = (String) acct.get('ACC_Estado__c');
        return !String.isBlank(status) && status.trim().toUpperCase() == 'ACTIVO';
    }

    private static String normalizeDoc(String value) {
        if (String.isBlank(value)) {
            return null;
        }

        String out = value.trim();
        out = out.replace('.', '');
        out = out.replace('-', '');
        out = out.replace(' ', '');
        out = out.replace('/', '');
        return out;
    }
    private static void createTransaction(
    Id caseId,
    InvocableInput input,
    TransactionData tx
) {
    if (caseId == null || tx == null) {
        return;
    }
    TRA_Transaccion__c trxRecord = new TRA_Transaccion__c();

trxRecord.Name = !String.isBlank(tx.description)
    ? truncate(tx.description, 80)
    : 'Transacción reclamada';

trxRecord.TRA_Reclamacion__c = caseId;

if (!String.isBlank(tx.transactionDate)) {
    try {

        if (tx.transactionDate.contains('/')) {

            List<String> parts = tx.transactionDate.split('/');

            trxRecord.TRA_Fecha__c = Date.newInstance(
                Integer.valueOf(parts[2]),
                Integer.valueOf(parts[1]),
                Integer.valueOf(parts[0])
            );

        } else {

            trxRecord.TRA_Fecha__c = Date.valueOf(tx.transactionDate);

        }

    } catch (Exception e) {
        System.debug(
            'Error convirtiendo fecha: ' +
            tx.transactionDate +
            ' -> ' +
            e.getMessage()
        );
    }
}

if (!String.isBlank(tx.amount)) {
    try {
        trxRecord.TRA_Monto__c = Decimal.valueOf(tx.amount);
    } catch (Exception e) {
    }
}

trxRecord.TRA_Moneda__c = tx.currencyCode;
trxRecord.TRA_Credito_Debito__c = tx.debitCredit;
//trxRecord.TRA_Canal__c = mapOrigin(input.channel);
trxRecord.TRA_Canal__c = null;
try {
    System.debug(JSON.serializePretty(trxRecord));
    Database.SaveResult sr = Database.insert(trxRecord, false);

if (!sr.isSuccess()) {
    for (Database.Error err : sr.getErrors()) {
        System.debug(err.getStatusCode());
        System.debug(err.getMessage());
    }
}
} catch (Exception e) {
    throw new AuraHandledException(
        'Error creando Transacción: ' + e.getMessage()
    );
}
}

    private static TransactionData parseTransaction(String jsonText) {
        TransactionData tx = new TransactionData();
        tx.rawJson = jsonText;

        Object raw = JSON.deserializeUntyped(jsonText);
        if (!(raw instanceof Map<String, Object>)) {
            throw new AuraHandledException('La transacción seleccionada no tiene un formato válido.');
        }

        Map<String, Object> mapTx = (Map<String, Object>) raw;

        tx.transactionId = stringValue(mapTx, new List<String>{ 'transactionId', 'id', 'txnId', 'referenceId' });
        tx.transactionDate = stringValue(mapTx, new List<String>{ 'transactionDate', 'date', 'fecha', 'trxDate' });
        tx.postingDate = stringValue(mapTx, new List<String>{ 'postingDate', 'bookingDate', 'fechaAplicacion' });
        tx.description = stringValue(mapTx, new List<String>{ 'description', 'descripcion', 'detail', 'glosa' });
        tx.amount = stringValue(mapTx, new List<String>{ 'rawAmount','amount', 'monto', 'transactionAmount', 'importe' });
        tx.currencyCode = stringValue(mapTx, new List<String>{ 'currency', 'currencyCode', 'moneda' });
        tx.debitCredit = stringValue(mapTx,  new List<String>{ 'debitCredit','creditDebit','movementType','tipoMovimiento'});
        tx.merchant = stringValue(mapTx, new List<String>{ 'merchant', 'commerce', 'comercio', 'merchantName' });
        tx.reference = stringValue(mapTx, new List<String>{ 'reference', 'referencia', 'authorizationNumber', 'authCode' });
        tx.maskedProductNumber = stringValue(mapTx, new List<String>{ 'maskedProductNumber', 'maskedAccountNumber', 'productMasked', 'cuentaEnmascarada' });
           // Si la moneda no viene en el JSON, intentar inferirla del campo amount
    String displayAmount = stringValue(mapTx, new List<String>{ 'amount' });

    if (String.isBlank(tx.currencyCode) && !String.isBlank(displayAmount)) {
        if (displayAmount.startsWith('RD$')) {
            tx.currencyCode = 'DOP';
        } else if (displayAmount.startsWith('US$')) {
            tx.currencyCode = 'USD';
        }
    }
        return tx;
    }

    private static String stringValue(Map<String, Object> source, List<String> candidateKeys) {
        for (String key : candidateKeys) {
            if (source.containsKey(key) && source.get(key) != null) {
                return String.valueOf(source.get(key));
            }
        }
        return null;
    }

    private static String buildSummary(Account acct, InvocableInput input, TransactionData tx) {
        List<String> parts = new List<String>();
        parts.add('Reclamaciones por cargos o consumos no reconocidos');

        if (!String.isBlank(acct.Name)) {
            parts.add('Cliente: ' + acct.Name);
        }
        if (String.isBlank(tx.currencyCode) && !String.isBlank(tx.amount)) {

    if (tx.amount.startsWith('RD$')) {
        tx.currencyCode = 'DOP';
    } else if (tx.amount.startsWith('US$')) {
        tx.currencyCode = 'USD';
    } else if (tx.amount.startsWith('€')) {
        tx.currencyCode = 'EUR';
    }
}
        if (!String.isBlank(input.selectedProductLabel)) {
            parts.add('Producto: ' + input.selectedProductLabel);
        }
        if (!String.isBlank(tx.description)) {
            parts.add('Transacción: ' + tx.description);
        }
        if (!String.isBlank(tx.amount)) {
            parts.add('Monto: ' + tx.amount + (String.isBlank(tx.currencyCode) ? '' : ' ' + tx.currencyCode));
        }
        if (!String.isBlank(tx.transactionDate)) {
            parts.add('Fecha: ' + tx.transactionDate);
        }

        return String.join(parts, ' | ');
    }

    private static Case buildCase(Account acct, FinServ__FinancialAccount__c financialAccount,  InvocableInput input, TransactionData tx, String summary) {
        Case c = new Case();
        c.AccountId = acct.Id;

        c.Subject = CASE_SUBJECT;

        c.Description = buildCaseDescription(acct, input, tx);
        c.Origin = 'Agentforce';
        c.Status = 'New';
        c.Priority = 'High';

        putIfFieldExists(c, 'Messaging_Session__c', input.messagingSessionId);
        putIfFieldExists(c, 'SuppliedName', acct.Name);
        putIfFieldExists(c, 'Type', 'Reclamación por cargo o consumo no reconocido');
        putIfFieldExists(c, 'Reason', 'Reclamaciones por cargos o consumos no reconocidos');
        putIfFieldExists(c, 'Tipo_de_Solicitante__c', 'CLIENTE');
        putIfFieldExists(c, 'Producto_Seleccionado__c', input.selectedProductLabel);
        putIfFieldExists(c, 'Producto_Key__c', input.selectedProductKey);
        putIfFieldExists(c, 'Resumen_Reclamo__c', truncate(summary, 255));
        putIfFieldExists(c, 'Transaccion_JSON__c', truncateLong(buildSafeTransactionSnapshot(tx), 131000));
        putIfFieldExists(c, 'Motivo_Reclamo__c', 'Reclamaciones por cargos o consumos no reconocidos');
        putIfFieldExists(c, 'Requiere_Derivacion__c', input.requiresTransfer);
        putIfFieldExists(c,'FinServ__FinancialAccount__c',financialAccount == null ? null : financialAccount.Id);
        putIfFieldExists(c,'CAS_Correo_Electronico_Cliente__c',acct.ACC_Correo_Electronico_Cliente__c);
        return c;
    }

    private static Boolean linkCaseToMessagingSession(Id messagingSessionId, Id caseId) {
        if (messagingSessionId == null || caseId == null) {
            return false;
        }

        try {
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

            if (!globalDescribe.containsKey('MessagingSession')) {
                return false;
            }

            Schema.SObjectType messagingSessionType = globalDescribe.get('MessagingSession');
            Map<String, Schema.SObjectField> fieldMap = messagingSessionType.getDescribe().fields.getMap();

            String caseLookupField = null;

            if (fieldMap.containsKey('CaseId')) {
                caseLookupField = 'CaseId';
            } else if (fieldMap.containsKey('Case__c')) {
                caseLookupField = 'Case__c';
            } else if (fieldMap.containsKey('Caso__c')) {
                caseLookupField = 'Caso__c';
            }

            if (String.isBlank(caseLookupField)) {
                return false;
            }

            SObject messagingSessionToUpdate = messagingSessionType.newSObject(messagingSessionId);
            messagingSessionToUpdate.put(caseLookupField, caseId);

            update messagingSessionToUpdate;

            return true;

        } catch (Exception e) {
            return false;
        }
    }

    private static String buildCaseDescription(Account acct, InvocableInput input, TransactionData tx) {
        List<String> lines = new List<String>();
      
        lines.add('Reclamacion por cargo o consumo no reconocido');
        return String.join(lines, '\n');
    }

    private static String buildSafeTransactionSnapshot(TransactionData tx) {
        Map<String, Object> snapshot = new Map<String, Object>();
        snapshot.put('transactionId', tx.transactionId);
        snapshot.put('transactionDate', tx.transactionDate);
        snapshot.put('postingDate', tx.postingDate);
        snapshot.put('description', tx.description);
        snapshot.put('amount', tx.amount);
        snapshot.put('currencyCode', tx.currencyCode);
        snapshot.put('debitCredit', tx.debitCredit);
        snapshot.put('merchant', tx.merchant);
        snapshot.put('reference', tx.reference);
        snapshot.put('maskedProductNumber', tx.maskedProductNumber);
        return JSON.serialize(snapshot);
    }

    private static void putIfFieldExists(SObject record, String fieldApiName, Object value) {
        if (value == null) {
            return;
        }

        Map<String, Schema.SObjectField> fieldMap = record.getSObjectType().getDescribe().fields.getMap();
        if (fieldMap.containsKey(fieldApiName)) {
            record.put(fieldApiName, value);
        }
    }

    private static String mapOrigin(String channel) {
        if (String.isBlank(channel)) {
            return 'Agentforce';
        }

        String normalized = channel.trim().toLowerCase();

        if (normalized.contains('whatsapp')) {
            return 'WhatsApp';
        }

        if (normalized.contains('chat')) {
            return 'Chat';
        }

        if (normalized.contains('web')) {
            return 'Web';
        }

        if (normalized.contains('agentforce')) {
            return 'Agentforce';
        }

        return channel;
    }

    private static String truncate(String value, Integer maxLen) {
        if (value == null) {
            return null;
        }

        return value.length() <= maxLen ? value : value.substring(0, maxLen);
    }

    private static String truncateLong(String value, Integer maxLen) {
        return truncate(value, maxLen);
    }

    private static String nullSafe(String value) {
        return value == null ? '' : value;
    }
}