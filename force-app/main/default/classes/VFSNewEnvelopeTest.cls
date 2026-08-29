@IsTest
private class VFSNewEnvelopeTest {
    @TestSetup
    static void createSigner() {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        Account signer = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount').getRecordTypeId(),
            FirstName = 'Firma',
            LastName = 'Envelope',
            ACC_TipoIdentificacion__c = 'Cédula',
            ACC_NumIdentificacion__c = '00108803999'
        );
        insert signer;
        insert new ContactPointEmail(
            ParentId = signer.Id,
            EmailAddress = 'firma.envelope@example.com',
            IsPrimary = true
        );
    }

    private static Account signer() {
        return [SELECT Id FROM Account WHERE FirstName = 'Firma' AND LastName = 'Envelope' LIMIT 1];
    }

    @IsTest
    static void buildsKycSignatureActions() {
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions =
            VFS_nKYCEnvelope.CreateSigns(signer().Id);
        Test.stopTest();

        System.assertEquals(6, actions.size());
        System.assertEquals(
            'firma.envelope@example.com',
            actions[0].Sign.RecipientConfiguration.ContactInformation.Email
        );
    }

    @IsTest
    static void buildsAgreementSummarySignatureActions() {
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions =
            VFS_nResumenConvenioEnvelope.CreateSigns(
                signer().Id,
                'Resumen Convenio Único Cuenta de Ahorro'
            );
        List<VFS_EsignSendingEnvelope.EnvelopeAction> currentAccountActions =
            VFS_nResumenConvenioEnvelope.CreateSigns(
                signer().Id,
                'Resumen Convenio Único Cuenta Corriente'
            );
        List<VFS_EsignSendingEnvelope.EnvelopeAction> creditCardActions =
            VFS_nResumenConvenioEnvelope.CreateSigns(
                signer().Id,
                'Resumen Convenio Único Tarjeta de Credito'
            );
        List<VFS_EsignSendingEnvelope.EnvelopeAction> prepaidCardActions =
            VFS_nResumenConvenioEnvelope.CreateSigns(
                signer().Id,
                'Resumen Convenio Único Tarjeta de Prepago'
            );
        Test.stopTest();

        System.assertEquals(3, actions.size());
        System.assertEquals(3, currentAccountActions.size());
        System.assertEquals(3, creditCardActions.size());
        System.assertEquals(3, prepaidCardActions.size());
        System.assertEquals(
            'firma.envelope@example.com',
            actions[0].Sign.RecipientConfiguration.ContactInformation.Email
        );
    }

    @IsTest
    static void buildsSingleContractSignatureActions() {
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions =
            VFS_nContratoUnicoEnvelope.CreateSigns(signer().Id);
        Test.stopTest();

        System.assertEquals(3, actions.size());
        System.assertEquals(
            'firma.envelope@example.com',
            actions[0].Sign.RecipientConfiguration.ContactInformation.Email
        );
    }

    @IsTest
    static void rejectsIncompleteEnvelopeRequests() {
        Integer rejected = 0;
        try {
            VFS_nKYCEnvelope.CreateSigns(null);
        } catch (Exception expected) {
            rejected++;
        }
        try {
            VFS_nKYCEnvelope.CreateSigns('001000000000001');
        } catch (Exception expected) {
            rejected++;
        }
        try {
            VFS_nResumenConvenioEnvelope.CreateSigns(null, null);
        } catch (Exception expected) {
            rejected++;
        }
        try {
            VFS_nContratoUnicoEnvelope.CreateSigns(null);
        } catch (Exception expected) {
            rejected++;
        }
        try {
            VFS_nResumenConvenioEnvelope.CreateSigns(signer().Id, 'Boton inexistente');
        } catch (Exception expected) {
            rejected++;
        }

        System.assertEquals(5, rejected);
    }

    @IsTest
    static void rejectsBusinessAccountWithoutAuthorizedSigner() {
        Account business = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'Empresa sin firmante',
            ACC_RNC__c = '131000099',
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert business;

        Integer rejected = 0;
        try { VFS_nContratoUnicoEnvelope.CreateSigns(String.valueOf(business.Id)); }
        catch (Exception expected) { rejected++; }
        try { VFS_nResumenConvenioEnvelope.CreateSigns(String.valueOf(business.Id), 'Resumen Convenio Único CAD'); }
        catch (Exception expected) { rejected++; }

        System.assertEquals(2, rejected);
    }

    @IsTest
    static void buildsKycSignatureActionsForABusinessSigner() {
        Account business = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'Empresa KYC con firmante',
            ACC_RNC__c = '131' + String.valueOf(Math.abs(Crypto.getRandomInteger())).left(6),
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert business;
        Database.SaveResult relationResult = Database.insert(new AccountAccountRelation(
            AccountId = business.Id,
            RelatedAccountId = signer().Id,
            AAR_FirmanteConozcaCliente__c = true,
            AAR_Porcentaje__c = 100
        ), false);

        if (relationResult.isSuccess()) {
            Test.startTest();
            List<VFS_EsignSendingEnvelope.EnvelopeAction> actions =
                VFS_nKYCEnvelope.CreateSigns(business.Id);
            Test.stopTest();

            System.assertEquals(6, actions.size());
            System.assertEquals(
                'firma.envelope@example.com',
                actions[0].Sign.RecipientConfiguration.ContactInformation.Email
            );
        } else {
            System.assertEquals(
                StatusCode.INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY,
                relationResult.getErrors()[0].getStatusCode()
            );
        }
    }

    @IsTest
    static void buildsCaseReceiptSignatureAction() {
        Case receiptCase = new Case(
            AccountId = signer().Id,
            Status = 'New',
            Origin = 'Phone',
            Subject = 'Comprobante para firma'
        );
        insert receiptCase;

        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions =
            VFS_ComprobanteCasoEnvelope.CreateSigns(String.valueOf(receiptCase.Id));
        Test.stopTest();

        System.assertEquals(1, actions.size());
        System.assertEquals(
            'firma.envelope@example.com',
            actions[0].Sign.RecipientConfiguration.ContactInformation.Email
        );
    }

    @IsTest
    static void validatesCaseReceiptActionAndEmptyQueues() {
        Case caseWithoutAccount = new Case(
            Status = 'New',
            Origin = 'Phone',
            Subject = 'Caso sin cuenta'
        );
        Case caseWithoutTransactions = new Case(
            AccountId = signer().Id,
            Status = 'New',
            Origin = 'Phone',
            Subject = 'Caso sin transacciones'
        );
        insert new List<Case>{ caseWithoutAccount, caseWithoutTransactions };

        Integer rejected = 0;
        try {
            VFS_ComprobanteCasoAction.enviar(null);
        } catch (AuraHandledException expected) {
            rejected++;
        }
        try {
            VFS_ComprobanteCasoAction.enviar(caseWithoutAccount.Id);
        } catch (AuraHandledException expected) {
            rejected++;
        }
        try {
            VFS_ComprobanteCasoAction.enviar(caseWithoutTransactions.Id);
        } catch (AuraHandledException expected) {
            rejected++;
        }

        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
        Test.startTest();
        new VFS_EnviarComprobanteCasoQueueable(null).execute(null);
        new VFS_EnviarComprobanteCasoQueueable(new Set<Id>()).execute(null);
        new VFS_EnviarComprobanteCasoQueueable(
            new Set<Id>{ caseWithoutAccount.Id, caseWithoutTransactions.Id }
        ).execute(null);
        new VFS_SubirComprobanteCasoEsignQueueable(null, null).execute(null);
        Test.stopTest();

        System.assertEquals(3, rejected);
    }
}
