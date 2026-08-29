@IsTest
private class FSC_CaseWrapUpController_Test {

    private static Contact createContactWithAccount(String email) {
        Account a = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'Test Account WrapUp',
            ACC_RNC__c = '131000020',
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert a;

        Contact c = new Contact(
            LastName = 'WrapUp Contact',
            AccountId = a.Id,
            Email = email
        );
        insert c;

        return c;
    }

    private static Case createCase(Id contactId, String suppliedEmail) {
        Case cs = new Case(
            Subject = 'WrapUp Case',
            Status = 'New',
            Origin = 'Phone',
            SuppliedEmail = suppliedEmail,
            ContactId = contactId
        );
        insert cs;
        return cs;
    }

    @IsTest
    static void testGetWrapUpData_UsesSuppliedEmail_WhenNoContact() {
        Case cs = createCase(null, 'supplied@test.com');

        cs = [SELECT Id, CaseNumber FROM Case WHERE Id = :cs.Id];
        
        Test.startTest();
        FSC_CaseWrapUpController.WrapUpResult res =
            FSC_CaseWrapUpController.getWrapUpData(cs.Id);
        Test.stopTest();

        System.assertNotEquals(null, res);
        System.assertEquals(0, res.fileCount, 'No hay files linkeados en el test');
        System.assertEquals('supplied@test.com', res.emailTo, 'Debe usar SuppliedEmail si no hay Contact');
        System.assert(res.emailSubject.contains(cs.CaseNumber), 'El subject debería incluir CaseNumber');
        System.assert(res.emailBody.contains(cs.CaseNumber), 'El body debería incluir CaseNumber');
    }

    @IsTest
    static void testGetWrapUpData_UsesContactEmail_WhenContactPresent() {
        Contact c = createContactWithAccount('contact@test.com');
        Case cs = createCase(c.Id, 'supplied@test.com');

        Test.startTest();
        FSC_CaseWrapUpController.WrapUpResult res =
            FSC_CaseWrapUpController.getWrapUpData(cs.Id);
        Test.stopTest();

        System.assertNotEquals(null, res);
        System.assertEquals('contact@test.com', res.emailTo, 'Debe priorizar Contact.Email sobre SuppliedEmail');
    }

    @IsTest
    static void testGetWrapUpData_NullCaseId_Throws() {
        try {
            Test.startTest();
            FSC_CaseWrapUpController.getWrapUpData(null);
            Test.stopTest();
            System.assert(false, 'Debió lanzar excepción por caseId null');
        } catch (AuraHandledException e) {
            
        }
    }

    @IsTest
    static void testCloseCase_MissingRequiredFields_Throws() {
        Case cs = createCase(null, 'supplied@test.com');

        try {
            Test.startTest();
            FSC_CaseWrapUpController.closeCase(
                cs.Id,
                null,                 
                'Motivo',
                'Resumen',
                false,
                null, null, null,
                null
            );
            Test.stopTest();
            System.assert(false, 'Debió lanzar excepción por campos obligatorios incompletos');
        } catch (AuraHandledException e) {
            
        }
    }

    @IsTest
    static void testCloseCase_MissingEvidence_Throws_WhenMinFilesRequired() {
        Case cs = createCase(null, 'supplied@test.com');

        try {
            Test.startTest();
            FSC_CaseWrapUpController.closeCase(
                cs.Id,
                'Resultado',
                'Motivo',
                'Resumen',
                false,
                null, null, null,
                3 
            );
            Test.stopTest();
            System.assert(false, 'Debió lanzar excepción por falta de evidencias');
        } catch (AuraHandledException e) {
           
        }
    }

    @IsTest
    static void testCloseCase_OK_WhenNoMinFilesRequired_UpdatesFields() {
        Case cs = createCase(null, 'supplied@test.com');

        Test.startTest();
        FSC_CaseWrapUpController.closeCase(
            cs.Id,
            'Resultado OK',
            'Motivo OK',
            'Resumen OK',
            false,
            null, null, null,
            null 
        );
        Test.stopTest();

        Case updated = [
            SELECT Id, Status,
                   CAS_Motivo_de_Rechazo__c,
                   FSC_CAS_Resultado__c,
                   FSC_CAS_Motivo_de_cierre__c,
                   FSC_CAS_Resumen_de_solucion__c
            FROM Case
            WHERE Id = :cs.Id
            LIMIT 1
        ];

        System.assertEquals('Resolucion del caso', updated.Status, 'Debe quedar en el estado final configurado');
        System.assertEquals('Resultado OK', updated.CAS_Motivo_de_Rechazo__c);
        System.assertEquals('Motivo OK', updated.FSC_CAS_Motivo_de_cierre__c);
        System.assertEquals('Resumen OK', updated.FSC_CAS_Resumen_de_solucion__c);
    }

    @IsTest
    static void testSendReminderEmail_ReturnsForEmptyClosedAndMissingEmail() {
        Test.startTest();
        FSC_CaseWrapUpController.sendReminderEmail(new List<FSC_CaseWrapUpController.Request>());
        Test.stopTest();

        Case missingEmailCase = createCase(null, null);
        FSC_CaseWrapUpController.Request missingEmailRequest = new FSC_CaseWrapUpController.Request();
        missingEmailRequest.caseId = missingEmailCase.Id;
        FSC_CaseWrapUpController.sendReminderEmail(new List<FSC_CaseWrapUpController.Request>{ missingEmailRequest });
    }

    @IsTest
    static void testSendAditionalInformationEmail_RequiresEmail() {
        Case cs = createCase(null, null);

        try {
            FSC_CaseWrapUpController.sendAditionalInformationEmail('Información adicional', cs.Id);
            System.assert(false, 'Debe exigir correo del cliente');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected.getMessage());
        }
    }

    @IsTest
    static void testSendAditionalInformationEmail_WithEmailStartsFlow() {
        Case cs = createCase(null, 'client@test.com');
        cs.CAS_Correo_Electronico_Cliente__c = 'client@test.com';
        update cs;

        try {
            FSC_CaseWrapUpController.sendAditionalInformationEmail('Información adicional', cs.Id);
        } catch (Exception expected) {
            System.assertNotEquals(null, expected.getMessage());
        }

        Case refreshed = [
            SELECT CAS_Informacion_Adicional__c
            FROM Case
            WHERE Id = :cs.Id
        ];
        System.assertEquals('Información adicional', refreshed.CAS_Informacion_Adicional__c);
    }
}
