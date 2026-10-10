@IsTest
private class AuxiliaryControllersTest {
    @IsTest
    static void exercisesFinancialLookupEmptyStates() {
        List<String> noAccounts = new List<String>();

        System.assertEquals(0, fsc_lookup_controller.search('none', noAccounts).size());
        System.assertEquals(0, fsc_lookup_controller.searchAumento('none', noAccounts).size());
        System.assertEquals(0, fsc_lookup_controller.searchMatriz('LINEA INEXISTENTE').size());
        System.assertEquals(0, fsc_lookup_controller.getRecentlyViewed(null).size());
        System.assertEquals(0, fsc_lookup_controller.getRecentlyViewedAumento(null).size());
        System.assertEquals(0, fsc_lookup_controller.getRecentlyViewedFinn(null, null).size());
        System.assertEquals(0, fsc_lookup_controller.searchTarjetaCredito('none', noAccounts, true).size());
        System.assertEquals(0, fsc_lookup_controller.searchTarjetaCredito('none', noAccounts, false).size());
        System.assertEquals(0, fsc_lookup_controller.getRecentlyViewedTarjetaCredito(null, true).size());
        System.assertEquals(0, fsc_lookup_controller.getRecentlyViewedTarjetaCredito(null, false).size());
        System.assertEquals(0, fsc_lookup_controller.searchTrasladoBalance('none', noAccounts, null).size());
        System.assertEquals(0, fsc_lookup_controller.getRecentlyViewedTrasladoBalance(null, null).size());
        System.assertNotEquals(null, fsc_lookup_controller.searchEjecutivo('none', noAccounts));
        System.assertNotEquals(null, fsc_lookup_controller.getEjecutivosCambioOptions());
    }

    @IsTest
    static void exercisesLegalDocumentGridEmptyStatesAndNames() {
        System.assertEquals(0, LegalDocumentsAssignedGridController.getUserQueueIds(null).size());
        System.assertEquals(0, LegalDocumentsAssignedGridController.getRoleAndAncestorIds(null).size());
        System.assertEquals(
            'Documento Legal',
            LegalDocumentsAssignedGridController.getDocumentName(null)
        );
        System.assertEquals(
            'Documento ABC',
            LegalDocumentsAssignedGridController.getDocumentName(
                new Documentacion_Legal__c(DOC_Codigo_Documento__c = 'ABC')
            )
        );
        System.assertNotEquals(
            null,
            LegalDocumentsAssignedGridController.getPendingLegalDocuments()
        );
    }

    @IsTest
    static void validatesNewCaseCandidateRequests() {
        Integer rejected = 0;
        rejected += candidateRequestIsRejected(null, null, null, null, null, null, null);
        rejected += candidateRequestIsRejected('Persona Natural', null, null, null, null, null, null);
        rejected += candidateRequestIsRejected('INVALIDO', 'RNC', null, null, null, null, null);
        rejected += candidateRequestIsRejected('Persona Jurídica', 'RNC', null, null, null, null, null);
        rejected += candidateRequestIsRejected('Persona Jurídica', 'RNC', null, '131000001', null, null, null);
        rejected += candidateRequestIsRejected('Persona Natural', 'Cédula', null, null, null, 'Apellido', null);
        rejected += candidateRequestIsRejected('Persona Natural', 'Cédula', '00100000001', null, null, null, null);

        System.assertEquals(7, rejected);
        System.assertNotEquals(null, FSC_NewCaseComponent_Controller.getOficinaLabel());
    }

    @IsTest
    static void validatesRoundRobinRequestsAndQueueLookup() {
        System.assertEquals(
            0,
            TCP_RoundRobinOpportunityAssign.assignFromFlow(null).size()
        );

        TCP_RoundRobinOpportunityAssign.Request invalidRequest =
            new TCP_RoundRobinOpportunityAssign.Request();
        List<TCP_RoundRobinOpportunityAssign.Response> invalidResults =
            TCP_RoundRobinOpportunityAssign.assignFromFlow(
                new List<TCP_RoundRobinOpportunityAssign.Request>{ invalidRequest }
            );
        System.assertEquals(false, invalidResults[0].success);

        String keyPrefix = OpportunityTCP__c.SObjectType.getDescribe().getKeyPrefix();
        TCP_RoundRobinOpportunityAssign.Request missingOpportunity =
            new TCP_RoundRobinOpportunityAssign.Request();
        missingOpportunity.opportunityId = Id.valueOf(keyPrefix + '000000000001');
        missingOpportunity.queueId = UserInfo.getUserId();
        missingOpportunity.scenery = 'ANALISIS_CREDITO';

        List<TCP_RoundRobinOpportunityAssign.Response> missingResults =
            TCP_RoundRobinOpportunityAssign.assignFromFlow(
                new List<TCP_RoundRobinOpportunityAssign.Request>{ missingOpportunity }
            );
        System.assertEquals(false, missingResults[0].success);
        System.assertEquals(
            0,
            TCP_RoundRobinOpportunityAssign.getActiveUsersFromQueue(UserInfo.getUserId()).size()
        );
        TCP_RoundRobinOpportunityAssign.generateNotification(null, null, null, null);
    }

    @IsTest
    static void coversSimpleNewCaseControllerPaths() {
        System.assertEquals(null, FSC_NewCaseComponent_Controller.getPrimaryEmail(null));
        System.assertEquals(
            0,
            FSC_NewCaseComponent_Controller.getFamiliaresAdicionales(null).size()
        );
        System.assertNotEquals(null, FSC_NewCaseComponent_Controller.getSupportQueueId());

        FSC_NewCaseComponent_Controller.FamiliarAdicionalOption option =
            new FSC_NewCaseComponent_Controller.FamiliarAdicionalOption(
                UserInfo.getUserId(), 'Familiar de prueba', 'Hermano'
            );
        System.assertEquals(UserInfo.getUserId(), option.contactId);
        System.assertEquals('Familiar de prueba', option.nombre);
        System.assertEquals('Hermano', option.parentesco);
    }

    @IsTest
    static void coversFileAndEmailHelpers() {
        insert new Bypass_Trigger__c(
            Name = 'Auxiliary file test bypass',
            Usernames_Allowed__c = UserInfo.getUserName()
        );
        Account parent = new Account(Name = 'Auxiliary file test account');
        insert parent;

        Test.startTest();
        FSC_NewCaseComponent_Controller.uploadFile(
            parent.Id, 'archivo-prueba.txt',
            EncodingUtil.base64Encode(Blob.valueOf('contenido'))
        );

        FSC_NewCaseComponent_Controller.Input input =
            new FSC_NewCaseComponent_Controller.Input();
        input.emailTo = 'test@example.com';
        input.emailSubject = 'Asunto de prueba';
        input.emaiemailBodylTo = 'Cuerpo de prueba';
        FSC_NewCaseComponent_Controller.procesar(
            new List<FSC_NewCaseComponent_Controller.Input>{ input }
        );
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM ContentVersion WHERE Title = 'archivo-prueba.txt']
        );
    }

    @IsTest
    static void createsCandidatesAndReadsBasicAccountData() {
        String suffix = String.valueOf(Math.abs(Crypto.getRandomInteger())).left(6);
        insert new Bypass_Trigger__c(
            Name = 'Auxiliary candidate test bypass ' + suffix,
            Usernames_Allowed__c = UserInfo.getUserName()
        );
        Datos_Maestros__c activity = new Datos_Maestros__c(
            Name = 'Actividad candidato existente ' + suffix,
            DM_Direccion__c = 'AUX' + suffix
        );
        insert activity;
        Lead naturalCandidate = new Lead(
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Natural').getRecordTypeId(),
            FirstName = 'Candidato',
            LastName = 'Natural',
            Company = 'Prospecto No Cliente',
            Status = 'Iniciado',
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_NumIdentificacion__c = '00108803558',
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Actividad_Economica__c = activity.Id,
            LEA_Tipo_Sector__c = 'PRIVADO'
        );
        Lead businessCandidate = new Lead(
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            LastName = 'Empresa Cobertura ' + suffix,
            Company = 'Empresa Cobertura ' + suffix,
            Status = 'Iniciado',
            LEA_TipoIdentificacion__c = 'RNC',
            LEA_RNC__c = '131000088',
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Actividad_Economica__c = activity.Id,
            LEA_Tipo_Sector__c = 'PRIVADO'
        );
        insert new List<Lead>{ naturalCandidate, businessCandidate };

        Id naturalId = FSC_NewCaseComponent_Controller.getOrCreateCandidate(
            'Persona Natural', 'Cédula', '00108803558', null,
            'Candidato', 'Natural', null,
            'natural@example.test', '8095550101'
        );
        Id existingNaturalId = FSC_NewCaseComponent_Controller.getOrCreateCandidate(
            'Persona Natural', 'Cédula', '00108803558', null,
            'Candidato', 'Natural', null,
            'natural@example.test', '8095550101'
        );
        Id businessId = FSC_NewCaseComponent_Controller.getOrCreateCandidate(
            'Persona Jurídica', 'RNC', null, '131000088',
            null, null, 'Empresa Cobertura ' + suffix,
            'empresa@example.test', '8095550102'
        );

        Account account = new Account(Name = 'Cuenta auxiliar ' + suffix);
        insert account;
        insert new ContactPointEmail(
            ParentId = account.Id,
            EmailAddress = 'principal@example.test',
            IsPrimary = true
        );
        FinServ__FinancialAccount__c financialAccount =
            new FinServ__FinancialAccount__c(
                FinServ__PrimaryOwner__c = account.Id,
                FinServ__FinancialAccountNumber__c = 'FA-' + suffix
            );
        insert financialAccount;

        System.assertEquals(naturalId, existingNaturalId);
        System.assertNotEquals(null, businessId);
        System.assertEquals(
            'principal@example.test',
            FSC_NewCaseComponent_Controller.getPrimaryEmail(account.Id)
        );
        System.assertEquals(false,
            FSC_NewCaseComponent_Controller.hasFinancialAccountTransactions(null));
        System.assertEquals(false,
            FSC_NewCaseComponent_Controller.hasFinancialAccountTransactions(financialAccount.Id));
        System.assertEquals(account.Id,
            FSC_NewCaseComponent_Controller.getAccountInfo(account.Id).Id);
        System.assertEquals(
            0,
            FSC_NewCaseComponent_Controller.getFamiliaresAdicionales(account.Id).size()
        );
        System.assertEquals(financialAccount.Id,
            FSC_NewCaseComponent_Controller.getAccountNumber(account.Id).Id);
        System.assertEquals(financialAccount.Id,
            FSC_NewCaseComponent_Controller.getOneFinnAccountNumber(financialAccount.Id).Id);
        System.assertEquals(financialAccount.Id,
            FSC_NewCaseComponent_Controller.getFinnAccountNumber(
                financialAccount.Id, UserInfo.getUserId()
            ).Id);
        System.assertNotEquals(null,
            FSC_NewCaseComponent_Controller.getDefaultLeadStatus());
        System.assertNotEquals('',
            FSC_NewCaseComponent_Controller.formatOficinaLabel('1'));
        System.assertEquals('',
            FSC_NewCaseComponent_Controller.formatOficinaLabel('99'));

        Integer rejectedMetadata = 0;
        try {
            FSC_NewCaseComponent_Controller.validateLeadField('Campo_Inexistente__c');
        } catch (AuraHandledException expected) {
            rejectedMetadata++;
        }
        try {
            FSC_NewCaseComponent_Controller.getLeadRecordTypeId('RecordType_Inexistente');
        } catch (AuraHandledException expected) {
            rejectedMetadata++;
        }
        System.assertEquals(2, rejectedMetadata);
    }

    private static Integer candidateRequestIsRejected(
        String candidateType,
        String identificationType,
        String identificationNumber,
        String rnc,
        String firstName,
        String lastName,
        String company
    ) {
        try {
            FSC_NewCaseComponent_Controller.getOrCreateCandidate(
                candidateType,
                identificationType,
                identificationNumber,
                rnc,
                firstName,
                lastName,
                company,
                null,
                null
            );
        } catch (AuraHandledException expected) {
            return 1;
        }
        return 0;
    }
}
