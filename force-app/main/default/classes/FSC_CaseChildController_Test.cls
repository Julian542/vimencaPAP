@IsTest
private class FSC_CaseChildController_Test {

    private static Account buildNeutralAccount() {
        Account acc = new Account();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
        acc.Name = 'Test Account';
        acc.ACC_RNC__c = 'RNCCASE001';
        acc.ACC_Condicion__c = 'PROSPECTO';
        acc.ACC_Estado__c = 'INICIADO';
        acc.ACC_TipoIdentificacion__c = 'RNC';
        return acc;
    }

    private static String getClosedStatus() {
        return [SELECT MasterLabel FROM CaseStatus WHERE IsClosed = true LIMIT 1].MasterLabel;
    }

    private static String getOpenStatus() {
        return [SELECT MasterLabel FROM CaseStatus WHERE IsClosed = false LIMIT 1].MasterLabel;
    }

    private static Map<String, Id> createAccountAndContact() {
        Account a = buildNeutralAccount();
        insert a;

        Contact c = new Contact(
            LastName = 'Test Contact',
            AccountId = a.Id,
            Email = 'test@example.com'
        );
        insert c;

        return new Map<String, Id>{
            'accountId' => a.Id,
            'contactId' => c.Id
        };
    }

    private static Case createCase(Id accountId, Id contactId, String status) {
        Case cs = new Case(
            Subject = 'Parent Case',
            Status = status,
            Origin = 'Phone',
            FSC_CAS_Resumen_de_solucion__c = 'test',
            FSC_CAS_Resultado__c = 'test',
            FSC_CAS_Motivo_de_cierre__c = 'test',
            AccountId = accountId,
            ContactId = contactId,
            Type = 'TestType',
            CAS_Correo_Electronico_Cliente__c = 'cliente@test.com'
        );
        insert cs;
        return cs;
    }

    @IsTest
    static void testGetParentCase_OK() {
        Map<String, Id> ids = createAccountAndContact();
        Case parentC = createCase(ids.get('accountId'), ids.get('contactId'), getOpenStatus());

        Test.startTest();
        FSC_CaseChildController.ParentInfo info =
            FSC_CaseChildController.getParentCase(parentC.Id);
        Test.stopTest();

        System.assertNotEquals(null, info, 'ParentInfo no debería ser null');
        System.assertEquals(parentC.Id, info.id);
        System.assertEquals(parentC.Subject, info.subject);
        System.assertEquals(parentC.IsClosed, info.isClosed);
        System.assertEquals(parentC.AccountId, info.accountId);
        System.assertEquals(parentC.ContactId, info.contactId);
        System.assertEquals(parentC.Origin, info.origin);

    }

    @IsTest
    static void testGetParentCase_Null_Throws() {
        try {
            Test.startTest();
            FSC_CaseChildController.getParentCase(null);
            Test.stopTest();
            System.assert(false, 'Debió lanzar excepción por parentCaseId null');
        } catch (AuraHandledException e) {
            
        }
    }

    @IsTest
    static void testCreateChildCase_OK_FromClosedParent() {
        Map<String, Id> ids = createAccountAndContact();

        Case parentC = createCase(ids.get('accountId'), ids.get('contactId'), getClosedStatus());

        Test.startTest();
        FSC_CaseChildController.CreateChildResponse res =
            FSC_CaseChildController.createChildCase(parentC.Id, 'Child Subject', 'Child Desc');
        Test.stopTest();

        System.assertNotEquals(null, res, 'Response no debería ser null');
        System.assertNotEquals(null, res.childCaseId, 'Debería retornar Id del caso hijo');

        Case childC = [
            SELECT Id, ParentId, AccountId, ContactId, RecordTypeId, Origin, Subject, Description, Type, CAS_Correo_Electronico_Cliente__c
            FROM Case
            WHERE Id = :res.childCaseId
            LIMIT 1
        ];

        System.assertEquals(parentC.Id, childC.ParentId, 'ParentId debe apuntar al caso padre');
        System.assertEquals(parentC.AccountId, childC.AccountId);
        System.assertEquals(parentC.ContactId, childC.ContactId);
        System.assertEquals(parentC.Origin, childC.Origin);
        System.assertEquals('Child Subject', childC.Subject);
        System.assertEquals('Child Desc', childC.Description);
        System.assertEquals(parentC.Type, childC.Type);
        System.assertEquals(parentC.CAS_Correo_Electronico_Cliente__c, childC.CAS_Correo_Electronico_Cliente__c);
    }

    @IsTest
    static void testCreateChildCase_NullParentId_Throws() {
        try {
            Test.startTest();
            FSC_CaseChildController.createChildCase(null, 'Child Subject', 'Child Desc');
            Test.stopTest();
            System.assert(false, 'Debió lanzar excepción por parentCaseId null');
        } catch (AuraHandledException e) {

        }
    }

    @IsTest
    static void testCreateChildCase_BlankSubject_Throws() {
        Map<String, Id> ids = createAccountAndContact();
        Case parentC = createCase(ids.get('accountId'), ids.get('contactId'), getClosedStatus());

        try {
            Test.startTest();
            FSC_CaseChildController.createChildCase(parentC.Id, '   ', 'Child Desc');
            Test.stopTest();
            System.assert(false, 'Debió lanzar excepción por Subject en blanco');
        } catch (AuraHandledException e) {
            
        }
    }

    @IsTest
    static void testCreateChildCase_ParentNotClosed_Throws() {
        Map<String, Id> ids = createAccountAndContact();
        Case parentC = createCase(ids.get('accountId'), ids.get('contactId'), getOpenStatus());

        try {
            Test.startTest();
            FSC_CaseChildController.createChildCase(parentC.Id, 'Child Subject', 'Child Desc');
            Test.stopTest();
            System.assert(false, 'Debió lanzar excepción por padre no cerrado');
        } catch (AuraHandledException e) {
            
        }
    }
}
