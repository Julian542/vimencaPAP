@IsTest
private class FSC_GenerarPagarePDF_Action_Test {

    private static Account buildAccount() {
        Account a = new Account();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
        a.Name = 'Cliente PDF';
        a.ACC_RNC__c = String.valueOf(Math.abs(Crypto.getRandomInteger())).leftPad(9, '0').substring(0, 9);
        a.ACC_NumIdentificacion__c = '00298765432';
        a.ACC_TipoIdentificacion__c = 'RNC';
        a.ACC_Condicion__c = 'PROSPECTO';
        a.ACC_Estado__c = 'INICIADO';
        a.ACC_Nacionalidad__c = 'AFGANISTÁN';
        a.ACC_Estado_Civil__c = 'SOLTERO/A';
        a.BillingStreet = 'Av. Siempre Viva';
        a.BillingCity = 'Santo Domingo';
        a.BillingState = 'DN';
        a.BillingCountry = 'Republica Dominicana';
        insert a;
        return a;
    }

    private static ResidentialLoanApplication buildRLA(Id accountId) {
        ResidentialLoanApplication rla = new ResidentialLoanApplication();
        rla.AccountId = accountId;
        rla.Name = 'Cliente Prueba';
        rla.RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
            .get('FSC_Solicitud_Credito_Consumo')
            .getRecordTypeId();
        rla.FSC_MontoAprobado__c = 100000;
        rla.FSC_FechaYHoraAprobacionComite__c = System.now();
        rla.FSC_PlazoMesesAprobado__c = 10;
        rla.FSC_Plazo_meses__c = '11';
        rla.FSC_Aplica_Garantia__c = false;
        rla.FSC_TasaInteresAprobada__c = 15;
        rla.FSC_Moneda__c = '1';
        rla.FSC_TasaInteres__c = 1.00;
        rla.FSC_ActoNumeroPagare__c = 'ACT-PDF';
        rla.FSC_NumeroFolioPagare__c = 123;
        rla.FSC_Aprobado_con_Condiciones__c = false;
        rla.Status = 'En proceso';
        rla.FSC_Subestado__c = 'Generación de pagarés y plantillas';
        rla.FSC_lineaFinanciera__c = '32';
        rla.FSC_subAplicacion__c = '401';

        insert rla;
        return rla;
    }

    @IsTest
    static void testInvocable_GeneratesFileAndLink() {
        Account a = buildAccount();
        ResidentialLoanApplication rla = buildRLA(a.Id);

        FSC_GenerarPagarePDF_Action.Input inp = new FSC_GenerarPagarePDF_Action.Input();
        inp.residentialLoanApplicationId = rla.Id;

        List<FSC_GenerarPagarePDF_Action.Input> inputs = new List<FSC_GenerarPagarePDF_Action.Input>{ inp };

        Test.startTest();
        List<FSC_GenerarPagarePDF_Action.Output> outList = FSC_GenerarPagarePDF_Action.run(inputs);
        Test.stopTest();

        System.assertEquals(1, outList.size(), 'Debe retornar 1 resultado');
        System.assertEquals('OK', outList[0].status, 'Status debe ser OK');
        System.assertNotEquals(null, outList[0].contentVersionId, 'Debe crear ContentVersion');
        System.assertNotEquals(null, outList[0].contentDocumentId, 'Debe tener ContentDocumentId');

        ContentVersion cv = [
            SELECT Id, Title, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :outList[0].contentVersionId
            LIMIT 1
        ];
        System.assertNotEquals(null, cv.ContentDocumentId, 'ContentDocumentId no debe ser null');

        ContentDocumentLink cdl = [
            SELECT Id, LinkedEntityId, ContentDocumentId, ShareType, Visibility
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :rla.Id
            LIMIT 1
        ];
        System.assertEquals(rla.Id, cdl.LinkedEntityId, 'Debe linkear al RLA');
        System.assertEquals(cv.ContentDocumentId, cdl.ContentDocumentId, 'Debe linkear el mismo ContentDocumentId');
        System.assertEquals('V', cdl.ShareType, 'ShareType debe ser Viewer');
    }

    @IsTest
    static void testInvocable_NullInput() {
        FSC_GenerarPagarePDF_Action.Input inp = new FSC_GenerarPagarePDF_Action.Input();
        inp.residentialLoanApplicationId = null;

        Test.startTest();
        List<FSC_GenerarPagarePDF_Action.Output> outList =
            FSC_GenerarPagarePDF_Action.run(new List<FSC_GenerarPagarePDF_Action.Input>{ inp });
        Test.stopTest();

        System.assertEquals(1, outList.size());
        System.assertEquals('ERROR', outList[0].status);
        System.assert(outList[0].message.contains('requerido'));
    }
}
