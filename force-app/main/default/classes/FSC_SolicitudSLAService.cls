public with sharing class FSC_SolicitudSLAService {

    private static final String CODIGO_FIELD_API = 'CAS_Codigo_Reclamacion__c';
    private static final String CANAL_FIELD_API = 'CAS_Canal_distribucion__c';
    private static final String PRODUCTO_FIELD_API = 'CAS_MatrizProducto__c';

    public static void assignEntitlementFromRule(
        Case caseRecord,
        Solicitud_Routing_Config__mdt rule
    ) {

        System.debug('SLA ent '+ rule.Entitlement_Name__c);


        if (caseRecord == null || rule == null) {
            System.debug(LoggingLevel.WARN, 'SLA | Case o rule null.');
            return;
        }

        if (String.isBlank(rule.Entitlement_Name__c)) {
            System.debug(LoggingLevel.WARN,
                'SLA | La regla no tiene Entitlement_Name__c. Rule=' + rule.DeveloperName
            );
            return;
        }

        List<Entitlement> entitlements = [
            SELECT Id, Name
            FROM Entitlement
            WHERE Name = :rule.Entitlement_Name__c
            LIMIT 1
        ];

        System.debug('SLA '+entitlements);

        if (entitlements.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'SLA | No se encontró Entitlement con Name=' + rule.Entitlement_Name__c
            );
            return;
        }

        caseRecord.EntitlementId = entitlements[0].Id;

        System.debug(LoggingLevel.DEBUG,
            'SLA | Entitlement asignado. Rule=' + rule.DeveloperName +
            ', Entitlement=' + entitlements[0].Name +
            ', EntitlementId=' + entitlements[0].Id
        );
    }

    public static void assignReclamacionEntitlementFromRule(
        Case caseRecord,
        Reclamacion_Routing_Config__mdt rule
    ) {

        System.debug('SLA ent '+ rule.Entitlement_Name__c);

        if (caseRecord == null || rule == null) {
            System.debug(LoggingLevel.WARN, 'SLA R | Case o rule null.');
            return;
        }

        if (String.isBlank(rule.Entitlement_Name__c)) {
            System.debug(LoggingLevel.WARN,
                'SLA R | La regla no tiene Entitlement_Name__c. Rule=' + rule.DeveloperName
            );
            return;
        }

        List<Entitlement> entitlements = [
            SELECT Id, Name
            FROM Entitlement
            WHERE Name = :rule.Entitlement_Name__c
            LIMIT 1
        ];
        System.debug('SLA ');
        System.debug('SLA '+entitlements);

        if (entitlements.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'SLA R | No se encontró Entitlement con Name=' + rule.Entitlement_Name__c
            );
            return;
        }

        caseRecord.EntitlementId = entitlements[0].Id;

        System.debug(LoggingLevel.DEBUG,
            'SLA | Entitlement asignado. Rule=' + rule.DeveloperName +
            ', Entitlement=' + entitlements[0].Name +
            ', EntitlementId=' + entitlements[0].Id
        );
    }

    public static void completeMilestonesOnCaseClose(
        List<Case> newCases,
        Map<Id, Case> oldCaseMap
    ){
        Set<Id> closedCaseIds = new Set<Id>();
        Map<Id, Datetime> caseClosedDateById = new Map<Id, Datetime>();

        for (Case c : newCases) {
            Case oldCase = oldCaseMap.get(c.Id);

            Boolean wasClosed = oldCase != null && oldCase.IsClosed;
            Boolean isNowClosed = c.IsClosed;

            if (
                !wasClosed &&
                isNowClosed &&
                c.EntitlementId != null
            ) {
                closedCaseIds.add(c.Id);
                caseClosedDateById.put(
                    c.Id,
                    c.ClosedDate != null ? c.ClosedDate : System.now()
                );
            }
        }

        if (closedCaseIds.isEmpty()) {
            return;
        }

        List<CaseMilestone> milestonesToComplete = [
            SELECT Id, CaseId, CompletionDate
            FROM CaseMilestone
            WHERE CaseId IN :closedCaseIds
            AND CompletionDate = null
        ];

        for (CaseMilestone cm : milestonesToComplete) {
            cm.CompletionDate = caseClosedDateById.containsKey(cm.CaseId)
                ? caseClosedDateById.get(cm.CaseId)
                : System.now();
        }

        if (!milestonesToComplete.isEmpty()) {
            Database.update(milestonesToComplete, false);
        }
    }
}