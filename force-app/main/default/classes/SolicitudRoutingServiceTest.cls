@IsTest
private class SolicitudRoutingServiceTest {
    private static Case routingCase(String status) {
        return routingCase('001', 'OFICIALES NEGOCIOS', status);
    }

    private static Case routingCase(String codigoSolicitud, String canal, String status) {
        String keyPrefix = Case.SObjectType.getDescribe().getKeyPrefix();
        return (Case) JSON.deserialize(
            JSON.serialize(
                new Map<String, Object>{
                    'Id' => Id.valueOf(keyPrefix + '000000000001'),
                    'Type' => codigoSolicitud,
                    'Status' => status,
                    'OwnerId' => UserInfo.getUserId(),
                    'CAS_Canal_distribucion__c' => canal,
                    'CAS_Codigo_de_producto__c' => 'TARJETA DE CREDITO'
                }
            ),
            Case.class
        );
    }

    @IsTest
    static void selectsExistingSolicitudRoutingMetadata() {
        SolicitudRoutingConfigService.RoutingRuleResult nullCaseResult =
            SolicitudRoutingConfigService.getMatchingRuleFromCase(
                null,
                'Type',
                'CAS_Canal_distribucion__c',
                'CAS_Codigo_de_producto__c'
            );
        SolicitudRoutingConfigService.RoutingRuleResult missingCodeResult =
            SolicitudRoutingConfigService.getMatchingRule(null, null, null);
        SolicitudRoutingConfigService.RoutingRuleResult missingRuleResult =
            SolicitudRoutingConfigService.getMatchingRule('SOLICITUD INEXISTENTE', null, null);
        SolicitudRoutingConfigService.RoutingRuleResult matchingResult =
            SolicitudRoutingConfigService.getMatchingRule(
                '001',
                'OFICIALES NEGOCIOS',
                'TARJETA DE CREDITO'
            );

        System.assertEquals(false, nullCaseResult.foundRule);
        System.assertEquals(false, missingCodeResult.foundRule);
        System.assertEquals(false, missingRuleResult.foundRule);
        System.assertEquals(true, matchingResult.foundRule, matchingResult.message);
        System.assertNotEquals(null, matchingResult.rule);

        SolicitudRoutingConfigService.RoutingRuleResult noApplicableRuleResult =
            SolicitudRoutingConfigService.getMatchingRule('001', 'CANAL INEXISTENTE', 'PRODUCTO INEXISTENTE');
        System.assertEquals(false, noApplicableRuleResult.foundRule);
    }

    @IsTest
    static void appliesInitialAndUpdateRoutingInMemory() {
        Case initialCase = routingCase(null);

        Test.startTest();
        SolicitudRoutingService.clearCache();
        SolicitudRoutingService.applyInitialRouting(new List<Case>{ initialCase });

        Case oldCase = routingCase('Crear Solicitud');
        Case updatedCase = routingCase('Validación');
        SolicitudRoutingService.applyUpdateRouting(
            new List<Case>{ updatedCase },
            new Map<Id, Case>{ oldCase.Id => oldCase }
        );
        SolicitudRoutingService.applyInitialRouting(null);
        SolicitudRoutingService.applyUpdateRouting(null, null);
        Test.stopTest();

        System.assertEquals('Crear Solicitud', initialCase.Status);
        System.assertNotEquals(null, initialCase.RecordTypeId);
        System.assertEquals('Validación', updatedCase.Status);
    }

    @IsTest
    static void ignoresCasesThatDoNotQualifyForRouting() {
        Case ignoredCase = routingCase(null);
        ignoredCase.Type = 'TIPO INEXISTENTE';

        Test.startTest();
        SolicitudRoutingService.applyInitialRouting(new List<Case>{ ignoredCase });
        SolicitudRoutingService.applyUpdateRouting(
            new List<Case>{ ignoredCase },
            new Map<Id, Case>()
        );
        Test.stopTest();

        System.assertEquals(null, ignoredCase.RecordTypeId);
    }

    @IsTest
    static void evaluatesEachConfiguredResolutionLevelInMemory() {
        Case oldCase = routingCase('Crear Solicitud');

        List<Case> transitions = new List<Case>();
        for (String status : new List<String>{
            'Validación',
            'Análisis',
            'Procesamiento',
            'Resolución y Cierre'
        }) {
            Case transition = routingCase(status);
            transitions.add(transition);
        }

        Case explicitN3 = routingCase('Validación');
        explicitN3.put('CAS_Escalar_A_N3__c', true);

        Case devolucion = routingCase('Validación');
        devolucion.put('CAS_Devolver_Al_Origen__c', true);
        devolucion.put('CAS_Motivo_Devolucion__c', 'Cobertura de ruteo');

        Test.startTest();
        for (Case transition : transitions) {
            SolicitudRoutingService.applyUpdateRouting(
                new List<Case>{ transition },
                new Map<Id, Case>{ oldCase.Id => oldCase }
            );
        }
        SolicitudRoutingService.applyUpdateRouting(
            new List<Case>{ explicitN3 },
            new Map<Id, Case>{ oldCase.Id => oldCase }
        );
        SolicitudRoutingService.applyUpdateRouting(
            new List<Case>{ devolucion },
            new Map<Id, Case>{ oldCase.Id => oldCase }
        );
        Test.stopTest();

        System.assertEquals(4, transitions.size());
        System.assertNotEquals(null, explicitN3.Status);
        System.assertNotEquals(null, devolucion.Status);
    }

    @IsTest
    static void routesConfiguredDevolucionAndEarlyExitPaths() {
        Case oldValidation = routingCase('002', 'OFICIALES NEGOCIOS', 'Validación');
        Case initialStatus = routingCase('002', 'OFICIALES NEGOCIOS', 'Crear Solicitud');
        Case devolucion = routingCase('002', 'OFICIALES NEGOCIOS', 'Validación');
        devolucion.put('CAS_Devolver_Al_Origen__c', true);
        devolucion.put('CAS_Motivo_Devolucion__c', 'Cobertura mínima');

        Case devolucionSinMotivo = routingCase('002', 'OFICIALES NEGOCIOS', 'Validación');
        devolucionSinMotivo.put('CAS_Devolver_Al_Origen__c', true);

        Case unmatched = routingCase('CODIGO INEXISTENTE', 'OFICIALES NEGOCIOS', 'Validación');
        Case unmatchedChannel = routingCase('002', 'CANAL INEXISTENTE', 'Validación');
        Case unchanged = routingCase('002', 'OFICIALES NEGOCIOS', 'Validación');
        Case blankChannel = routingCase('002', null, null);
        Id unrelatedCaseId = Id.valueOf(Case.SObjectType.getDescribe().getKeyPrefix() + '000000000999');

        Test.startTest();
        SolicitudRoutingService.clearCache();
        SolicitudRoutingService.applyInitialRouting(new List<Case>{ blankChannel });
        SolicitudRoutingService.applyInitialRouting(new List<Case>{ null });
        SolicitudRoutingService.applyUpdateRouting(
            new List<Case>{ initialStatus },
            new Map<Id, Case>{ oldValidation.Id => oldValidation }
        );
        SolicitudRoutingService.applyUpdateRouting(
            new List<Case>{ devolucion },
            new Map<Id, Case>{ oldValidation.Id => oldValidation }
        );
        SolicitudRoutingService.applyUpdateRouting(
            new List<Case>{ devolucionSinMotivo },
            new Map<Id, Case>{ oldValidation.Id => oldValidation }
        );
        SolicitudRoutingService.applyUpdateRouting(
            new List<Case>{ unmatched },
            new Map<Id, Case>{ oldValidation.Id => oldValidation }
        );
        SolicitudRoutingService.applyUpdateRouting(
            new List<Case>{ unmatchedChannel },
            new Map<Id, Case>{ oldValidation.Id => oldValidation }
        );
        SolicitudRoutingService.applyUpdateRouting(
            new List<Case>{ null },
            new Map<Id, Case>{ oldValidation.Id => oldValidation }
        );
        SolicitudRoutingService.applyUpdateRouting(
            new List<Case>{ unchanged },
            new Map<Id, Case>{ unrelatedCaseId => oldValidation }
        );
        SolicitudRoutingService.applyUpdateRouting(
            new List<Case>{ unchanged },
            new Map<Id, Case>{ unchanged.Id => unchanged.clone(false, true, false, false) }
        );
        Test.stopTest();

        System.assertEquals('Crear Solicitud', initialStatus.Status);
        System.assertEquals('Crear Solicitud', devolucion.Status);
        System.assertEquals(false, devolucion.get('CAS_Devolver_Al_Origen__c'));
        System.assertEquals(true, devolucionSinMotivo.hasErrors());
    }
}
