@IsTest
private class FSC_CaseWrapUpController_Test {

    private static Case createCase(Id contactId, String suppliedEmail) {
        Case caseRecord = new Case(
            Subject = 'WrapUp Case',
            Status = 'New',
            Origin = 'Phone',
            SuppliedEmail = suppliedEmail,
            ContactId = contactId
        );
        insert caseRecord;
        return caseRecord;
    }

    private static Case createLegacyCase(String recordTypeDeveloperName) {
        List<RecordType> recordTypes = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Case'
                AND DeveloperName = :recordTypeDeveloperName
            LIMIT 1
        ];
        System.assert(
            !recordTypes.isEmpty(),
            'No existe el Record Type de Case: ' + recordTypeDeveloperName
        );

        Case caseRecord = new Case(
            RecordTypeId = recordTypes[0].Id,
            Subject = 'Legacy WrapUp ' + recordTypeDeveloperName,
            Status = 'New',
            Origin = 'Phone'
        );
        insert caseRecord;
        return caseRecord;
    }

    private static Contact createContactWithAccount(String email) {
        Id accountRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Candidato_Persona_Juridica')
            .getRecordTypeId();

        Account accountRecord = new Account(
            RecordTypeId = accountRecordTypeId,
            Name = 'Test Account WrapUp',
            ACC_RNC__c = '131000020',
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert accountRecord;

        Contact contactRecord = new Contact(
            LastName = 'WrapUp Contact',
            AccountId = accountRecord.Id,
            Email = email
        );
        insert contactRecord;
        return contactRecord;
    }

    @IsTest
    static void testGetWrapUpData_UsesSuppliedEmail_WhenNoContact() {
        Case caseRecord = createCase(null, 'supplied@test.com');
        caseRecord = [SELECT Id, CaseNumber FROM Case WHERE Id = :caseRecord.Id];

        Test.startTest();
        FSC_CaseWrapUpController.WrapUpResult result =
            FSC_CaseWrapUpController.getWrapUpData(caseRecord.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(0, result.fileCount);
        System.assertEquals('supplied@test.com', result.emailTo);
        System.assert(result.emailSubject.contains(caseRecord.CaseNumber));
        System.assert(result.emailBody.contains(caseRecord.CaseNumber));
    }

    @IsTest
    static void testGetWrapUpData_UsesContactEmail_WhenContactPresent() {
        Contact contactRecord = createContactWithAccount('contact@test.com');
        Case caseRecord = createCase(contactRecord.Id, 'supplied@test.com');

        Test.startTest();
        FSC_CaseWrapUpController.WrapUpResult result =
            FSC_CaseWrapUpController.getWrapUpData(caseRecord.Id);
        Test.stopTest();

        System.assertEquals('contact@test.com', result.emailTo);
    }

    @IsTest
    static void testGetWrapUpData_CountsLinkedFile() {
        Case caseRecord = createCase(null, 'supplied@test.com');
        insert new ContentVersion(
            Title = 'WrapUp Test File',
            PathOnClient = 'WrapUpTestFile.txt',
            VersionData = Blob.valueOf('archivo de prueba'),
            FirstPublishLocationId = caseRecord.Id
        );

        Test.startTest();
        FSC_CaseWrapUpController.WrapUpResult result =
            FSC_CaseWrapUpController.getWrapUpData(caseRecord.Id);
        Test.stopTest();

        System.assertEquals(1, result.fileCount);
    }

    @IsTest
    static void testGetWrapUpData_NullCaseId_Throws() {
        Boolean exceptionThrown = false;
        try {
            FSC_CaseWrapUpController.getWrapUpData(null);
        } catch (AuraHandledException expected) {
            exceptionThrown = true;
        }
        System.assertEquals(true, exceptionThrown, 'Debió exigir el Id del caso.');
    }

    @IsTest
    static void testCloseCase_NullCaseId_Throws() {
        Boolean exceptionThrown = false;
        try {
            FSC_CaseWrapUpController.closeCase(
                null, 'Resultado', 'Resumen', false, null, null, null, null
            );
        } catch (AuraHandledException expected) {
            exceptionThrown = true;
        }
        System.assertEquals(true, exceptionThrown, 'Debió exigir el Id del caso.');
    }

    @IsTest
    static void testCloseCase_MissingRequiredFields_Throws() {
        Case caseRecord = createCase(null, 'supplied@test.com');
        Boolean exceptionThrown = false;
        try {
            FSC_CaseWrapUpController.closeCase(
                caseRecord.Id, null, 'Resumen', false, null, null, null, null
            );
        } catch (AuraHandledException expected) {
            exceptionThrown = true;
        }
        System.assertEquals(true, exceptionThrown, 'Debió exigir resultado y resumen.');
    }

    @IsTest
    static void testCloseCase_MissingEvidence_Throws() {
        Case caseRecord = createLegacyCase('RT_Solicitud_1_2');
        Boolean exceptionThrown = false;
        try {
            FSC_CaseWrapUpController.closeCase(
                caseRecord.Id, 'Resultado', 'Resumen', false,
                null, null, null, 3
            );
        } catch (AuraHandledException expected) {
            exceptionThrown = true;
        }
        System.assertEquals(
            true,
            exceptionThrown,
            'Debió exigir evidencias para un resultado distinto de Desestimado.'
        );
    }

    @IsTest
    static void testCloseCase_Desestimado_SinEvidencias_CierraSolicitudAntigua() {
        Case caseRecord = createLegacyCase('RT_Solicitud_1_2');

        Test.startTest();
        FSC_CaseWrapUpController.closeCase(
            caseRecord.Id,
            'Desestimado',
            'Caso desestimado',
            false,
            null,
            null,
            null,
            3
        );
        Test.stopTest();

        Case updatedCase = [
            SELECT Status, CAS_Motivo_de_Rechazo__c,
                FSC_CAS_Resumen_de_solucion__c, IsClosed
            FROM Case
            WHERE Id = :caseRecord.Id
        ];
        System.assertEquals('Resolución y Cierre', updatedCase.Status);
        System.assertEquals('Desestimado', updatedCase.CAS_Motivo_de_Rechazo__c);
        System.assertEquals('Caso desestimado', updatedCase.FSC_CAS_Resumen_de_solucion__c);
        System.assertEquals(true, updatedCase.IsClosed);
    }

    @IsTest
    static void testCloseCase_Desestimado_SinEvidencias_CierraReclamacionAntigua() {
        Case caseRecord = createLegacyCase('RT_Soporte_3');

        Test.startTest();
        FSC_CaseWrapUpController.closeCase(
            caseRecord.Id,
            'Desestimado',
            'Caso desestimado',
            false,
            null,
            null,
            null,
            2
        );
        Test.stopTest();

        Case updatedCase = [
            SELECT Status, IsClosed
            FROM Case
            WHERE Id = :caseRecord.Id
        ];
        System.assertEquals('Resolucion del caso', updatedCase.Status);
        System.assertEquals(true, updatedCase.IsClosed);
    }

    @IsTest
    static void testSendReminderEmail_EmptyRequestsDoesNotThrow() {
        Test.startTest();
        FSC_CaseWrapUpController.sendReminderEmail(
            new List<FSC_CaseWrapUpController.Request>()
        );
        Test.stopTest();
    }

    @IsTest
    static void testSendReminderEmail_NullRequestDoesNotThrow() {
        FSC_CaseWrapUpController.Request request =
            new FSC_CaseWrapUpController.Request();
        Test.startTest();
        FSC_CaseWrapUpController.sendReminderEmail(
            new List<FSC_CaseWrapUpController.Request>{ request }
        );
        Test.stopTest();
    }

    @IsTest
    static void testSendReminderEmail_MissingEmailReturns() {
        Case caseRecord = createCase(null, null);
        FSC_CaseWrapUpController.Request request =
            new FSC_CaseWrapUpController.Request();
        request.caseId = caseRecord.Id;

        Test.startTest();
        FSC_CaseWrapUpController.sendReminderEmail(
            new List<FSC_CaseWrapUpController.Request>{ request }
        );
        Test.stopTest();
    }

    @IsTest
    static void testSendReminderEmail_WithEmailDoesNotThrow() {
        Contact contactRecord = createContactWithAccount('client@test.com');
        Case caseRecord = createCase(contactRecord.Id, 'client@test.com');
        caseRecord.CAS_Correo_Electronico_Cliente__c = 'client@test.com';
        update caseRecord;

        FSC_CaseWrapUpController.Request request =
            new FSC_CaseWrapUpController.Request();
        request.caseId = caseRecord.Id;

        Test.startTest();
        FSC_CaseWrapUpController.sendReminderEmail(
            new List<FSC_CaseWrapUpController.Request>{ request }
        );
        Test.stopTest();
    }

    @IsTest
    static void testSendAditionalInformationEmail_NullId_Throws() {
        Boolean exceptionThrown = false;
        try {
            FSC_CaseWrapUpController.sendAditionalInformationEmail(
                'Información adicional', null
            );
        } catch (AuraHandledException expected) {
            exceptionThrown = true;
        }
        System.assertEquals(true, exceptionThrown, 'Debió exigir el Id del caso.');
    }

    @IsTest
    static void testSendAditionalInformationEmail_RequiresEmail() {
        Case caseRecord = createCase(null, null);
        Boolean exceptionThrown = false;
        try {
            FSC_CaseWrapUpController.sendAditionalInformationEmail(
                'Información adicional', caseRecord.Id
            );
        } catch (AuraHandledException expected) {
            exceptionThrown = true;
        }
        System.assertEquals(true, exceptionThrown, 'Debe exigir correo del cliente.');
    }

    @IsTest
    static void testSendAditionalInformationEmail_WithEmailUpdatesCase() {
        Case caseRecord = createCase(null, 'client@test.com');
        caseRecord.CAS_Correo_Electronico_Cliente__c = 'client@test.com';
        update caseRecord;

        try {
            FSC_CaseWrapUpController.sendAditionalInformationEmail(
                'Información adicional',
                caseRecord.Id
            );
        } catch (Exception flowException) {
            // El Flow puede requerir configuración adicional del entorno de prueba;
            // la actualización del caso ocurre antes de iniciarlo.
        }

        Case refreshedCase = [
            SELECT CAS_Informacion_Adicional__c
            FROM Case
            WHERE Id = :caseRecord.Id
        ];
        System.assertEquals(
            'Información adicional',
            refreshedCase.CAS_Informacion_Adicional__c
        );
    }

}