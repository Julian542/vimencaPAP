@IsTest
private class AccountLookupControllerTest {
    @IsTest
    static void smokeTest() {
        Test.startTest();
        try {
            System.assertEquals(0, AccountLookupController.searchParticipantsSource(null).size());
        } catch (Exception expected) {
            System.assertNotEquals(null, expected.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void searchesAccountsAndBuildsPublicDtos() {
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'Lookup Coverage Company',
            ACC_RNC__c = '131LOOKUP1',
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert account;

        Datos_Maestros__c activity = new Datos_Maestros__c(
            Name = 'Lookup Candidate Activity',
            DM_Direccion__c = 'LCA001'
        );
        insert activity;
        Lead matchingCandidate = buildLead(
            'Lookup Candidate',
            '00108803888',
            activity.Id
        );
        insert matchingCandidate;

        Test.startTest();
        List<AccountLookupController.SearchResultDTO> sources =
            AccountLookupController.searchParticipantsSource('Lookup Coverage');
        List<AccountLookupController.AccountDTO> accounts =
            AccountLookupController.searchAccounts('Lookup Coverage');
        List<AccountLookupController.CandidateDTO> candidates =
            AccountLookupController.searchCandidates('Lookup Candidate');
        List<AccountLookupController.FieldInfoDTO> fields =
            AccountLookupController.getParticipantModalFields();
        Test.stopTest();

        System.assertEquals(1, accounts.size());
        System.assertEquals(account.Id, accounts[0].id);
        System.assert(!sources.isEmpty());
        System.assertEquals(1, candidates.size());
        System.assertEquals(matchingCandidate.Id, candidates[0].id);
        System.assertNotEquals(null, fields);

        AccountLookupController.CandidateDTO candidateDto =
            new AccountLookupController.CandidateDTO(
                new Lead(FirstName = 'Test', LastName = 'Candidate', Company = 'Test')
            );
        AccountLookupController.AccountDTO accountDto =
            new AccountLookupController.AccountDTO(account);
        AccountLookupController.ParticipantDTO participantDto =
            new AccountLookupController.ParticipantDTO(
                new Participante__c(PAR_Tipo__c = 'ACCIONISTA', PAR_Cargo__c = 'GERENTE'),
                new Map<Id, Lead>()
            );

        System.assertEquals(null, candidateDto.id);
        System.assertEquals(account.Id, accountDto.id);
        System.assertEquals('ACCIONISTA', participantDto.tipo);
    }

    @IsTest
    static void rejectsIncompletePublicRequests() {
        assertCreateCandidateRejected(null, null, null, null, null, null);
        assertCreateCandidateRejected('EMPRESA', 'RNC', null, null, null, '131000001');
        assertCreateCandidateRejected('PERSONA', 'CEDULA', null, 'Apellido', null, '00100000001');
        assertCreateCandidateRejected('PERSONA', 'CEDULA', 'Nombre', null, null, '00100000001');
        assertCreateCandidateRejected('PERSONA', 'CEDULA', 'Nombre', 'Apellido', null, null);

        Boolean invalidParticipantTypeRejected = false;
        try {
            AccountLookupController.addParticipant(UserInfo.getUserId(), UserInfo.getUserId(), 'INVALID', null);
        } catch (AuraHandledException expected) {
            invalidParticipantTypeRejected = true;
        }

        System.assert(invalidParticipantTypeRejected);
        System.assertEquals(0, AccountLookupController.getParticipants(null).size());
        assertNullParticipantOperationsRejected();
    }

    @IsTest
    static void createsMinimalParticipantCandidates() {
        Lead personCandidate;
        Boolean invalidCompanyRejected = false;

        Test.startTest();
        personCandidate = AccountLookupController.createParticipantCandidate(
            'PERSONA',
            'Cédula',
            'Nuevo',
            'Participante',
            null,
            '00108803001'
        );
        try {
            AccountLookupController.createParticipantCandidate(
                'EMPRESA',
                'RNC',
                null,
                null,
                null,
                '131000002'
            );
        } catch (AuraHandledException expected) {
            invalidCompanyRejected = true;
        }
        Test.stopTest();

        Lead persistedCandidate = [
            SELECT FirstName, LastName, Company, LEA_TipoIdentificacion__c,
                   LEA_NumIdentificacion__c, LEA_Tipo_Vinculacion__c, LEA_Tipo_Sector__c
            FROM Lead
            WHERE Id = :personCandidate.Id
        ];
        System.assertNotEquals(null, personCandidate.Id);
        System.assertEquals('Nuevo', persistedCandidate.FirstName);
        System.assertEquals('Participante', persistedCandidate.LastName);
        System.assertEquals('00108803001', persistedCandidate.LEA_NumIdentificacion__c);
        System.assertEquals('SIN DEFINIR', persistedCandidate.LEA_Tipo_Vinculacion__c);
        System.assertEquals('NO DISPONIBLE', persistedCandidate.LEA_Tipo_Sector__c);
        System.assert(invalidCompanyRejected);
        System.assertEquals(0, [SELECT COUNT() FROM Lead WHERE LEA_RNC__c = '131000002']);
    }

    @IsTest
    static void managesAccountParticipantLifecycle() {
        Account participantAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'Participant Lifecycle Company',
            ACC_RNC__c = '131LIFE001',
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert participantAccount;

        Datos_Maestros__c economicActivity = new Datos_Maestros__c(
            Name = 'Participant Lifecycle Activity',
            DM_Direccion__c = 'PLC001'
        );
        insert economicActivity;
        Lead principal = new Lead(
            FirstName = 'Lifecycle',
            LastName = 'Principal',
            Company = 'Lifecycle Principal',
            Status = 'Iniciado',
            LEA_NumIdentificacion__c = '00108803777',
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
            LEA_PersonBirthdate__c = Date.today().addYears(-30),
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Actividad_Economica__c = economicActivity.Id,
            LEA_Tipo_Sector__c = 'PRIVADO'
        );
        insert principal;

        Test.startTest();
        Id participantId = AccountLookupController.addParticipant(
            principal.Id,
            participantAccount.Id,
            'ACCOUNT',
            JSON.serialize(new Map<String, Object>{
                'PAR_Tipo__c' => 'Organización',
                'PAR_Porcentaje__c' => 25
            })
        );
        List<AccountLookupController.ParticipantDTO> participants =
            AccountLookupController.getParticipants(principal.Id);
        AccountLookupController.ParticipantEditDTO editData =
            AccountLookupController.getParticipantForEdit(participantId);
        Id updatedId = AccountLookupController.updateParticipant(
            participantId,
            JSON.serialize(new Map<String, Object>{ 'PAR_Porcentaje__c' => 30 })
        );
        AccountLookupController.deleteParticipant(participantId);
        Test.stopTest();

        System.assertNotEquals(null, principal.Id);
        System.assertEquals(1, participants.size());
        System.assertEquals(participantAccount.Id, editData.relatedRecordId);
        System.assertEquals('ACCOUNT', editData.relatedRecordType);
        System.assertEquals(participantId, updatedId);
        System.assertEquals(0, [SELECT COUNT() FROM Participante__c WHERE Id = :participantId]);
    }

    @IsTest
    static void managesLeadParticipantAndReusesNoCustomerAccount() {
        Datos_Maestros__c economicActivity = new Datos_Maestros__c(
            Name = 'Lead Participant Activity',
            DM_Direccion__c = 'LPC001'
        );
        insert economicActivity;
        Lead principal = buildLead(
            'Lead Principal',
            '00108803444',
            economicActivity.Id
        );
        Lead participantLead = buildLead(
            'Lead Participant',
            '00108803333',
            economicActivity.Id
        );
        insert principal;
        insert participantLead;
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));

        Test.startTest();
        Id participantId = AccountLookupController.addParticipant(
            principal.Id,
            participantLead.Id,
            'LEAD',
            JSON.serialize(new Map<String, Object>{ 'PAR_Tipo__c' => 'Contacto' })
        );
        Id duplicateId = AccountLookupController.addParticipant(
            principal.Id,
            participantLead.Id,
            'LEAD',
            JSON.serialize(new Map<String, Object>{ 'PAR_Tipo__c' => 'Contacto' })
        );
        List<AccountLookupController.ParticipantDTO> participants =
            AccountLookupController.getParticipants(principal.Id);
        AccountLookupController.deleteParticipant(participantId);
        Test.stopTest();

        System.assertEquals(participantId, duplicateId);
        System.assertEquals(1, participants.size());
        System.assertEquals('Candidato', participants[0].tipoRegistro);
        System.assertEquals(participantLead.Id, participants[0].accountId);
    }

    private static Lead buildLead(String lastName, String identificationNumber, Id activityId) {
        return new Lead(
            FirstName = 'Coverage',
            LastName = lastName,
            Company = 'Coverage ' + lastName,
            Status = 'Iniciado',
            LEA_NumIdentificacion__c = identificationNumber,
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
            LEA_PersonBirthdate__c = Date.today().addYears(-30),
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Actividad_Economica__c = activityId,
            LEA_Tipo_Sector__c = 'PRIVADO'
        );
    }

    private static void assertCreateCandidateRejected(
        String participantType,
        String identificationType,
        String firstName,
        String lastName,
        String companyName,
        String identificationNumber
    ) {
        Boolean rejected = false;
        try {
            AccountLookupController.createParticipantCandidate(
                participantType,
                identificationType,
                firstName,
                lastName,
                companyName,
                identificationNumber
            );
        } catch (AuraHandledException expected) {
            rejected = true;
        }
        System.assert(rejected);
    }

    private static void assertNullParticipantOperationsRejected() {
        Integer rejectedOperations = 0;
        try {
            AccountLookupController.getParticipantForEdit(null);
        } catch (AuraHandledException expected) {
            rejectedOperations++;
        }
        try {
            AccountLookupController.updateParticipant(null, null);
        } catch (AuraHandledException expected) {
            rejectedOperations++;
        }
        try {
            AccountLookupController.deleteParticipant(null);
        } catch (AuraHandledException expected) {
            rejectedOperations++;
        }
        System.assertEquals(3, rejectedOperations);
    }
}
