@IsTest
private class ReclamacionRoutingServiceTest {
    private static User routingUser() {
        String uniqueSuffix = String.valueOf(System.now().getTime());
        return new User(
            Alias = 'routr',
            Email = 'routing.' + uniqueSuffix + '@example.test',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Routing Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/Santo_Domingo',
            Username = 'routing.' + uniqueSuffix + '@example.test',
            Canal_Atencion__c = 'OFICIALES NEGOCIOS'
        );
    }

    private static Case routingCase(String status) {
        String keyPrefix = Case.SObjectType.getDescribe().getKeyPrefix();
        Case request = new Case(
            Id = Id.valueOf(keyPrefix + '000000000002'),
            Type = 'R1',
            Status = status,
            OwnerId = UserInfo.getUserId()
        );
        request.put('CAS_Canal_distribucion__c', 'PE');
        return request;
    }

    @IsTest
    static void selectsExistingReclamacionRoutingMetadata() {
        ReclamacionRoutingConfigService.RoutingRuleResult nullCaseResult =
            ReclamacionRoutingConfigService.getMatchingRuleFromCase(
                null,
                'Type',
                'CAS_Canal_distribucion__c',
                'CAS_Producto_a_Reclamar__c'
            );
        ReclamacionRoutingConfigService.RoutingRuleResult missingCodeResult =
            ReclamacionRoutingConfigService.getMatchingRule(null, null, null);
        ReclamacionRoutingConfigService.RoutingRuleResult missingRuleResult =
            ReclamacionRoutingConfigService.getMatchingRule('RECLAMACION INEXISTENTE', null, null);
        ReclamacionRoutingConfigService.RoutingRuleResult matchingResult =
            ReclamacionRoutingConfigService.getMatchingRule('R1', 'OFICIALES NEGOCIOS', null);

        System.assertEquals(false, nullCaseResult.foundRule);
        System.assertEquals(false, missingCodeResult.foundRule);
        System.assertEquals(false, missingRuleResult.foundRule);
        System.assertEquals(true, matchingResult.foundRule, matchingResult.message);
        System.assertNotEquals(null, matchingResult.rule);

        ReclamacionRoutingConfigService.RoutingRuleResult noApplicableRuleResult =
            ReclamacionRoutingConfigService.getMatchingRule('R1', 'CANAL INEXISTENTE', 'PRODUCTO INEXISTENTE');
        System.assertEquals(false, noApplicableRuleResult.foundRule);
    }

    @IsTest
    static void readsRoutingValuesFromTheCaseRecord() {
        Case source = routingCase(null);
        source.put('CAS_Canal_distribucion__c', ' oficiales negocios ');

        ReclamacionRoutingConfigService.RoutingRuleResult matchingResult =
            ReclamacionRoutingConfigService.getMatchingRuleFromCase(
                source,
                'Type',
                'CAS_Canal_distribucion__c',
                'Subject'
            );
        ReclamacionRoutingConfigService.RoutingRuleResult invalidFieldResult =
            ReclamacionRoutingConfigService.getMatchingRuleFromCase(
                source,
                'Campo_Inexistente__c',
                'CAS_Canal_distribucion__c',
                'Subject'
            );

        System.assertEquals(true, matchingResult.foundRule, matchingResult.message);
        System.assertEquals(false, invalidFieldResult.foundRule);
    }

    @IsTest
    static void appliesInitialAndUpdateRoutingInMemory() {
        User testUser = routingUser();
        insert testUser;

        System.runAs(testUser) {
            Case initialCase = routingCase(null);

            Test.startTest();
            ReclamacionRoutingService.clearCache();
            ReclamacionRoutingService.applyInitialRouting(new List<Case>{ initialCase });

            Case oldCase = routingCase('Crear Solicitud');
            Case updatedCase = routingCase('Validación');
            ReclamacionRoutingService.applyUpdateRouting(
                new List<Case>{ updatedCase },
                new Map<Id, Case>{ oldCase.Id => oldCase }
            );
            ReclamacionRoutingService.applyInitialRouting(null);
            ReclamacionRoutingService.applyUpdateRouting(null, null);
            Test.stopTest();

            System.assertEquals('Crear Solicitud', initialCase.Status);
            System.assertNotEquals(null, initialCase.RecordTypeId);
            System.assertEquals('Validación', updatedCase.Status);
        }
    }

    @IsTest
    static void ignoresCasesThatDoNotQualifyForRouting() {
        Case ignoredCase = routingCase(null);
        ignoredCase.Type = 'TIPO INEXISTENTE';

        Test.startTest();
        ReclamacionRoutingService.applyInitialRouting(new List<Case>{ ignoredCase });
        ReclamacionRoutingService.applyUpdateRouting(
            new List<Case>{ ignoredCase },
            new Map<Id, Case>()
        );
        Test.stopTest();

        System.assertEquals(null, ignoredCase.RecordTypeId);
    }

    @IsTest
    static void routesConfiguredLevelsAndDevolucion() {
        User testUser = routingUser();
        insert testUser;

        System.runAs(testUser) {
            Case oldCase = routingCase('Crear Solicitud');
            Case initialStatus = routingCase('Crear Solicitud');
            Case oldBeforeInitial = routingCase('Verificación del Caso');
            List<Case> transitions = new List<Case>();
            for (String status : new List<String>{
                'Verificación del Caso',
                'Análisis del Caso',
                'Actualización de Data Crédito'
            }) {
                Case transition = routingCase(status);
                transition.put('CAS_Producto_a_Reclamar__c', 'ALL');
                transitions.add(transition);
            }

            Case explicitN3 = routingCase('Verificación del Caso');
            explicitN3.Type = '38';
            explicitN3.put('CAS_Producto_a_Reclamar__c', 'ALL');
            explicitN3.put('CAS_Escalar_A_N3__c', true);

            Case devolucion = routingCase('Verificación del Caso');
            devolucion.put('CAS_Devolver_Al_Origen__c', true);
            devolucion.put('CAS_Motivo_Devolucion__c', 'Cobertura mínima');

            Case devolucionSinMotivo = routingCase('Verificación del Caso');
            devolucionSinMotivo.put('CAS_Devolver_Al_Origen__c', true);

            Case unmatched = routingCase('Verificación del Caso');
            unmatched.Type = 'CODIGO INEXISTENTE';
            Case withoutCode = routingCase('Verificación del Caso');
            withoutCode.Type = null;
            Case unchanged = routingCase('Verificación del Caso');
            Id unrelatedCaseId = Id.valueOf(Case.SObjectType.getDescribe().getKeyPrefix() + '000000000998');

            Test.startTest();
            ReclamacionRoutingService.clearCache();
            ReclamacionRoutingService.applyInitialRouting(new List<Case>{ withoutCode });
            ReclamacionRoutingService.applyUpdateRouting(
                new List<Case>{ initialStatus },
                new Map<Id, Case>{ oldBeforeInitial.Id => oldBeforeInitial }
            );
            for (Case transition : transitions) {
                ReclamacionRoutingService.applyUpdateRouting(
                    new List<Case>{ transition },
                    new Map<Id, Case>{ oldCase.Id => oldCase }
                );
            }
            ReclamacionRoutingService.applyUpdateRouting(
                new List<Case>{ explicitN3 },
                new Map<Id, Case>{ oldCase.Id => oldCase }
            );
            ReclamacionRoutingService.applyUpdateRouting(
                new List<Case>{ devolucion },
                new Map<Id, Case>{ oldCase.Id => oldCase }
            );
            ReclamacionRoutingService.applyUpdateRouting(
                new List<Case>{ devolucionSinMotivo },
                new Map<Id, Case>{ oldCase.Id => oldCase }
            );
            ReclamacionRoutingService.applyUpdateRouting(
                new List<Case>{ unmatched },
                new Map<Id, Case>{ oldCase.Id => oldCase }
            );
            ReclamacionRoutingService.applyUpdateRouting(
                new List<Case>{ withoutCode },
                new Map<Id, Case>{ oldCase.Id => oldCase }
            );
            ReclamacionRoutingService.applyUpdateRouting(
                new List<Case>{ unchanged },
                new Map<Id, Case>{ unrelatedCaseId => oldCase }
            );
            ReclamacionRoutingService.applyUpdateRouting(
                new List<Case>{ unchanged },
                new Map<Id, Case>{ unchanged.Id => unchanged.clone(false, true, false, false) }
            );
            Test.stopTest();

            System.assertEquals(3, transitions.size());
            System.assertEquals('Crear Solicitud', initialStatus.Status);
            System.assertEquals('Crear Solicitud', devolucion.Status);
            System.assertEquals(false, devolucion.get('CAS_Devolver_Al_Origen__c'));
            System.assertEquals(true, devolucionSinMotivo.hasErrors());
        }
    }
}
