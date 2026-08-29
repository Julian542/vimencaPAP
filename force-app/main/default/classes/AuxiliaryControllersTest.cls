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
