@IsTest
private class FSC_SolicitudSLAServiceTest {
    private static Solicitud_Routing_Config__mdt routingRule(String entitlementName) {
        return new Solicitud_Routing_Config__mdt(
            DeveloperName = 'CoverageRule',
            MasterLabel = 'Coverage Rule',
            Entitlement_Name__c = entitlementName
        );
    }

    private static Reclamacion_Routing_Config__mdt reclamacionRule(String entitlementName) {
        return new Reclamacion_Routing_Config__mdt(
            DeveloperName = 'CoverageReclamacionRule',
            MasterLabel = 'Coverage Reclamacion Rule',
            Entitlement_Name__c = entitlementName
        );
    }

    @IsTest
    static void coversEntitlementAssignmentGuards() {
        Case caseRecord = new Case();

        FSC_SolicitudSLAService.assignEntitlementFromRule(null, routingRule('Missing entitlement'));
        FSC_SolicitudSLAService.assignEntitlementFromRule(caseRecord, routingRule(null));
        FSC_SolicitudSLAService.assignEntitlementFromRule(caseRecord, routingRule('Missing entitlement'));

        FSC_SolicitudSLAService.assignReclamacionEntitlementFromRule(null, reclamacionRule('Missing entitlement'));
        FSC_SolicitudSLAService.assignReclamacionEntitlementFromRule(caseRecord, reclamacionRule(''));
        FSC_SolicitudSLAService.assignReclamacionEntitlementFromRule(caseRecord, reclamacionRule('Missing entitlement'));

        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'SLA assignment account',
            ACC_RNC__c = 'RNC-SLA-ASSIGNMENT',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC'
        );
        insert account;
        Entitlement entitlement = new Entitlement(
            Name = 'SLA assignment entitlement',
            AccountId = account.Id
        );
        insert entitlement;

        FSC_SolicitudSLAService.assignEntitlementFromRule(
            caseRecord,
            routingRule(entitlement.Name)
        );
        System.assertEquals(entitlement.Id, caseRecord.EntitlementId);

        FSC_SolicitudSLAService.assignReclamacionEntitlementFromRule(
            caseRecord,
            reclamacionRule(entitlement.Name)
        );
        System.assertEquals(entitlement.Id, caseRecord.EntitlementId);
    }

    @IsTest
    static void coversMilestoneCompletionGuards() {
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'SLA coverage account',
            ACC_RNC__c = 'RNC-SLA-COVERAGE',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC'
        );
        insert account;
        Entitlement entitlement = new Entitlement(
            Name = 'SLA coverage entitlement',
            AccountId = account.Id
        );
        insert entitlement;
        CaseStatus closedStatus = [
            SELECT MasterLabel
            FROM CaseStatus
            WHERE IsClosed = TRUE
            LIMIT 1
        ];
        Case openCase = new Case(
            Status = closedStatus.MasterLabel,
            Subject = 'SLA coverage closed',
            EntitlementId = entitlement.Id,
            FSC_CAS_Resultado__c = 'Resultado de prueba',
            FSC_CAS_Motivo_de_cierre__c = 'Motivo de prueba',
            FSC_CAS_Resumen_de_solucion__c = 'Resumen de prueba'
        );
        insert openCase;

        Case oldOpenCase = new Case(Id = openCase.Id, Status = 'New');
        Case closedCase = [
            SELECT Id, Status, IsClosed, EntitlementId, ClosedDate
            FROM Case
            WHERE Id = :openCase.Id
        ];
        Case oldClosedCase = new Case(Id = closedCase.Id, Status = 'New');

        Test.startTest();
        FSC_SolicitudSLAService.completeMilestonesOnCaseClose(
            new List<Case>{ openCase },
            new Map<Id, Case>{ openCase.Id => oldOpenCase }
        );
        FSC_SolicitudSLAService.completeMilestonesOnCaseClose(
            new List<Case>{ closedCase },
            new Map<Id, Case>{ closedCase.Id => oldClosedCase }
        );
        Test.stopTest();

        System.assertEquals(0, [
            SELECT COUNT()
            FROM CaseMilestone
            WHERE CaseId = :openCase.Id
        ]);
    }
}
