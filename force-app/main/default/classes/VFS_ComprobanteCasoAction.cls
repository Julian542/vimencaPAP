public with sharing class VFS_ComprobanteCasoAction {

    private static final Set<String> TYPES_REQUIRING_TRANSACTIONS = new Set<String>{
        'R1', 'R2', 'R3', 'R4', 'R5', 'R6', 'R7', 'R9', 'R10',
        '12', '13', '15', 'RE18', 'R20', '21', '22', 'R24', '26',
        'R27', 'R28', 'R29', '30', '32', '33', '34', '35', '36',
        '43', '46', 'R47', 'R49', 'R53', 'RE54', 'RE55',
        '003', '006', '012', '013', '016', '020', '022', '026', '028'
    };

    @AuraEnabled
    public static void enviar(Id caseId) {
        validar(caseId);

        System.enqueueJob(
            new VFS_EnviarComprobanteCasoQueueable(
                new Set<Id>{ caseId }
            )
        );
    }

    @AuraEnabled
    public static void validar(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('Debe enviarse el Id del caso.');
        }

        Case caso = [
            SELECT Id, AccountId, Type, CAS_Numero_transacciones__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        if (caso.AccountId == null) {
            throw new AuraHandledException('El caso no tiene cliente asociado.');
        }

        if (
            TYPES_REQUIRING_TRANSACTIONS.contains(caso.Type) &&
            (caso.CAS_Numero_transacciones__c == null || caso.CAS_Numero_transacciones__c <= 0)
        ) {
            throw new AuraHandledException('El caso no tiene transacciones relacionadas.');
        }
    }

    @AuraEnabled
    public static void registrarEnvioFirma(Id contentDocumentId, String envelopeId) {
        if (contentDocumentId == null || String.isBlank(envelopeId)) {
            throw new AuraHandledException('No fue posible registrar el envío del comprobante.');
        }

        ContentVersion version = [
            SELECT Id
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocumentId
            AND IsLatest = true
            LIMIT 1
        ];
        version.FSC_EnvelopeId__c = envelopeId;
        version.FSC_EnviarDocumento__c = true;
        version.FSC_FechaEnvioFirma__c = System.now();
        version.FSC_Firmado__c = false;
        update version;
    }
}