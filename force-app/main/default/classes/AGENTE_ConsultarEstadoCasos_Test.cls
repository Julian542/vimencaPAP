@isTest
private class AGENTE_ConsultarEstadoCasos_Test {
    private static Account buildNeutralAccount(String nameSuffix) {
        return new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica')
                .getRecordTypeId(),
            Name = 'Cuenta Test ' + nameSuffix,
            ACC_RNC__c = 'AGENTERNC' + nameSuffix,
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC'
        );
    }

    @testSetup
    static void setupData() {

        Account acc = buildNeutralAccount('Setup');
        insert acc;

        List<Case> casos = new List<Case>();

        for(Integer i = 1; i <= 6; i++) {
            casos.add(new Case(
                AccountId = acc.Id,
                Subject = 'Caso ' + i,
                Status = 'New'
            ));
        }

        insert casos;
    }

    @isTest
    static void testBuscarPorNumero_OK() {

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Case c = [SELECT CaseNumber, Status FROM Case LIMIT 1];

        AGENTE_ConsultarEstadoCasos.InvocableInput input =
            new AGENTE_ConsultarEstadoCasos.InvocableInput();

        input.accountId = acc.Id;
        input.mode = 'BY_NUMBER';
        input.caseNumber = c.CaseNumber;

        Test.startTest();

        List<AGENTE_ConsultarEstadoCasos.InvocableOutput> result =
            AGENTE_ConsultarEstadoCasos.ejecutar(
                new List<AGENTE_ConsultarEstadoCasos.InvocableInput>{ input }
            );

        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('OK', result[0].status);
        System.assertEquals(true, result[0].found);
        System.assertEquals(c.CaseNumber, result[0].outCaseNumber);
    }

    @isTest
    static void testBuscarPorNumero_NotFound() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        AGENTE_ConsultarEstadoCasos.InvocableInput input =
            new AGENTE_ConsultarEstadoCasos.InvocableInput();

        input.accountId = acc.Id;
        input.mode = 'BY_NUMBER';
        input.caseNumber = '999999999';

        Test.startTest();

        List<AGENTE_ConsultarEstadoCasos.InvocableOutput> result =
            AGENTE_ConsultarEstadoCasos.ejecutar(
                new List<AGENTE_ConsultarEstadoCasos.InvocableInput>{ input }
            );

        Test.stopTest();

        System.assertEquals('NOT_FOUND', result[0].status);
        System.assertEquals(false, result[0].found);
    }

    @isTest
    static void testListarRecientes_OK() {

        Account acc = [SELECT Id FROM Account LIMIT 1];

        AGENTE_ConsultarEstadoCasos.InvocableInput input =
            new AGENTE_ConsultarEstadoCasos.InvocableInput();

        input.accountId = acc.Id;
        input.mode = 'RECENT';
        input.displayOffset = 0;

        Test.startTest();

        List<AGENTE_ConsultarEstadoCasos.InvocableOutput> result =
            AGENTE_ConsultarEstadoCasos.ejecutar(
                new List<AGENTE_ConsultarEstadoCasos.InvocableInput>{ input }
            );

        Test.stopTest();

        System.assertEquals('OK', result[0].status);
        System.assertEquals(true, result[0].found);
        System.assert(result[0].displayedCount > 0);
    }

    @isTest
    static void testInputInvalido() {

        AGENTE_ConsultarEstadoCasos.InvocableInput input =
            new AGENTE_ConsultarEstadoCasos.InvocableInput();

        input.mode = 'RECENT';

        Test.startTest();

        List<AGENTE_ConsultarEstadoCasos.InvocableOutput> result =
            AGENTE_ConsultarEstadoCasos.ejecutar(
                new List<AGENTE_ConsultarEstadoCasos.InvocableInput>{ input }
            );

        Test.stopTest();

        System.assertEquals('INVALID_INPUT', result[0].status);
    }

    @isTest
    static void testNoCases() {

        Account acc = buildNeutralAccount('SinCasos');
        insert acc;

        AGENTE_ConsultarEstadoCasos.InvocableInput input =
            new AGENTE_ConsultarEstadoCasos.InvocableInput();

        input.accountId = acc.Id;
        input.mode = 'RECENT';

        Test.startTest();

        List<AGENTE_ConsultarEstadoCasos.InvocableOutput> result =
            AGENTE_ConsultarEstadoCasos.ejecutar(
                new List<AGENTE_ConsultarEstadoCasos.InvocableInput>{ input }
            );

        Test.stopTest();

        System.assertEquals('NO_CASES', result[0].status);
    }
}
