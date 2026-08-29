@IsTest
private class FSC_GenerarPagarePDF_ActionTest {
    private static Account buildNeutralAccount() {
        return new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica')
                .getRecordTypeId(),
            Name = 'Cuenta Pagare ' + System.now().getTime(),
            ACC_NumIdentificacion__c = '00108803610',
            ACC_RNC__c = 'PAG' + String.valueOf(System.now().getTime()).right(6),
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC'
        );
    }

    private static ResidentialLoanApplication createRla(String actoNumeroPagare) {
        return createRla(actoNumeroPagare, false);
    }

    private static ResidentialLoanApplication createRla(String actoNumeroPagare, Boolean aprobadoConCondiciones) {
        Account acc = buildNeutralAccount();
        insert acc;

        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            Name = 'RLA Pagare ' + System.now().getTime(),
            AccountId = acc.Id,
            RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
                .get('FSC_Solicitud_Credito_Consumo')
                .getRecordTypeId(),
            Status = 'En proceso',
            FSC_Subestado__c = 'Generación de pagarés y plantillas',
            FSC_ActoNumeroPagare__c = actoNumeroPagare,
            FSC_NumeroFolioPagare__c = actoNumeroPagare == null ? null : 123,
            FSC_Pagares_y_Plantillas_Generados__c = false,
            FSC_Monto__c = 1000,
            FSC_Plazo_meses__c = '12',
            FSC_TasaInteres__c = 10,
            FSC_Aprobado_con_Condiciones__c = aprobadoConCondiciones,
            FSC_MontoAprobado__c = aprobadoConCondiciones ? 2000 : null,
            FSC_PlazoMesesAprobado__c = aprobadoConCondiciones ? 18 : null,
            FSC_TasaInteresAprobada__c = aprobadoConCondiciones ? 12 : null,
            FSC_lineaFinanciera__c = '32',
            FSC_subAplicacion__c = '401'
        );
        insert rla;
        return rla;
    }

    @IsTest
    static void run_generatesPdfWhenActoNumeroExists() {
        ResidentialLoanApplication rla = createRla('ACT123');

        FSC_GenerarPagarePDF_Action.Input inputItem = new FSC_GenerarPagarePDF_Action.Input();
        inputItem.residentialLoanApplicationId = rla.Id;

        Test.startTest();
        List<FSC_GenerarPagarePDF_Action.Output> outputs =
            FSC_GenerarPagarePDF_Action.run(new List<FSC_GenerarPagarePDF_Action.Input>{ inputItem });
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        System.assertEquals('OK', outputs[0].status);
        System.assertNotEquals(null, outputs[0].contentVersionId);
        System.assertNotEquals(null, outputs[0].contentDocumentId);

        ResidentialLoanApplication refreshed = [
            SELECT FSC_Pagares_y_Plantillas_Generados__c,
                   FSC_Subestado__c,
                   FSC_MontoAprobado__c,
                   FSC_PlazoMesesAprobado__c,
                   FSC_TasaInteresAprobada__c
            FROM ResidentialLoanApplication
            WHERE Id = :rla.Id
        ];

        System.assertEquals(true, refreshed.FSC_Pagares_y_Plantillas_Generados__c);
        System.assert(
            refreshed.FSC_Subestado__c == 'Generación de contrato' ||
            refreshed.FSC_Subestado__c == 'Gestionar firmas',
            'Subestado inesperado: ' + refreshed.FSC_Subestado__c
        );
        System.assertEquals(1000, refreshed.FSC_MontoAprobado__c);
        System.assertEquals(12, refreshed.FSC_PlazoMesesAprobado__c);
        System.assertEquals(10, refreshed.FSC_TasaInteresAprobada__c);
        System.assert(
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :rla.Id] > 0,
            'Debe generarse al menos un archivo relacionado a la solicitud.'
        );
    }

    @IsTest
    static void run_returnsErrorWhenActoNumeroIsMissing() {
        ResidentialLoanApplication rla = createRla(null);

        FSC_GenerarPagarePDF_Action.Input inputItem = new FSC_GenerarPagarePDF_Action.Input();
        inputItem.residentialLoanApplicationId = rla.Id;

        Test.startTest();
        List<FSC_GenerarPagarePDF_Action.Output> outputs =
            FSC_GenerarPagarePDF_Action.run(new List<FSC_GenerarPagarePDF_Action.Input>{ inputItem });
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        System.assertEquals('ERROR', outputs[0].status);
        System.assert(outputs[0].message.contains('Acto número pagaré'));

        ResidentialLoanApplication refreshed = [
            SELECT FSC_Pagares_y_Plantillas_Generados__c,
                   FSC_Subestado__c
            FROM ResidentialLoanApplication
            WHERE Id = :rla.Id
        ];

        System.assertEquals(false, refreshed.FSC_Pagares_y_Plantillas_Generados__c);
        System.assertEquals('Generación de pagarés y plantillas', refreshed.FSC_Subestado__c);
        System.assertEquals(
            0,
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :rla.Id]
        );
    }

    @IsTest
    static void run_returnsErrorWhenAlreadyGenerated() {
        ResidentialLoanApplication rla = createRla('ACT123');
        update new ResidentialLoanApplication(
            Id = rla.Id,
            FSC_Pagares_y_Plantillas_Generados__c = true
        );

        FSC_GenerarPagarePDF_Action.Input inputItem = new FSC_GenerarPagarePDF_Action.Input();
        inputItem.residentialLoanApplicationId = rla.Id;

        Test.startTest();
        List<FSC_GenerarPagarePDF_Action.Output> outputs =
            FSC_GenerarPagarePDF_Action.run(new List<FSC_GenerarPagarePDF_Action.Input>{ inputItem });
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        System.assertEquals('ERROR', outputs[0].status);
        System.assert(outputs[0].message.contains('ya fue generado'));
    }

    @IsTest
    static void run_preservesApprovedValuesWhenApprovedWithConditions() {
        ResidentialLoanApplication rla = createRla('ACT456', true);

        FSC_GenerarPagarePDF_Action.Input inputItem = new FSC_GenerarPagarePDF_Action.Input();
        inputItem.residentialLoanApplicationId = rla.Id;

        Test.startTest();
        List<FSC_GenerarPagarePDF_Action.Output> outputs =
            FSC_GenerarPagarePDF_Action.run(new List<FSC_GenerarPagarePDF_Action.Input>{ inputItem });
        Test.stopTest();

        System.assertEquals('OK', outputs[0].status);
        ResidentialLoanApplication refreshed = [
            SELECT FSC_MontoAprobado__c, FSC_PlazoMesesAprobado__c, FSC_TasaInteresAprobada__c
            FROM ResidentialLoanApplication
            WHERE Id = :rla.Id
        ];
        System.assertEquals(2000, refreshed.FSC_MontoAprobado__c);
        System.assertEquals(18, refreshed.FSC_PlazoMesesAprobado__c);
        System.assertEquals(12, refreshed.FSC_TasaInteresAprobada__c);
    }
}
