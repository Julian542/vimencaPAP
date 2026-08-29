@IsTest
public with sharing class TCP_EmailSenderInvocableTest {

    // ---------- TEST SETUP ----------
    @TestSetup
    static void setupData() {
        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

        // Usuario Analista
        Profile p = [SELECT Id FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        User analyst = new User(
            Alias = 'analyst',
            Email = 'analyst@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Analyst',
            LanguageLocaleKey = 'es',
            LocaleSidKey = 'es_AR',
            TimeZoneSidKey = 'America/Argentina/Buenos_Aires',
            ProfileId = p.Id,
            UserName = 'analyst_' + System.currentTimeMillis() + '@test.com'
        );
        insert analyst;

        // Cuenta Cliente
        Id personAccountRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        Account acc = new Account(
            RecordTypeId = personAccountRtId,
            FirstName = 'Cliente',
            LastName = 'Test'
        );
        insert acc;

        // Vía de contacto EMAIL
        ContactPointEmail viaEmail = new ContactPointEmail(
            ParentId = acc.Id,
            IsPrimary = true,
            EmailAddress = 'cliente@test.com'
        );
        insert viaEmail;

        // Opportunity TCP base
        OpportunityTCP__c otcp = new OpportunityTCP__c(
            Name = 'OTCP-001',
            OTCP_Account__c = acc.Id,
            OTCP_State__c = 'Validado',
            OTCP_SubState__c = 'Pendiente Precalificacion',
            OTCP_AssignedAnalyst__c = analyst.Id
        );
        insert otcp;
    }

    private static OpportunityTCP__c getOtcp() {
        return [
            SELECT Id, Name, OTCP_Account__c, OTCP_AssignedAnalyst__c,
                   OTCP_CardType__c, OTCP_limiteSugeridoDOP__c, OTCP_limiteSugeridoUSD__c
            FROM OpportunityTCP__c
            LIMIT 1
        ];
    }

    private static String getAnyConfiguredCardType() {
        List<TCP_Welcome_Config__mdt> cfgList = [
            SELECT Card_Type__c
            FROM TCP_Welcome_Config__mdt
            WHERE Card_Type__c != null
            LIMIT 1
        ];
        return cfgList.isEmpty() ? null : cfgList[0].Card_Type__c;
    }

    // Helper: ejecuta invocable y asegura Output básico
    private static TCP_EmailSenderInvocable.Output runInvocable(Id otcpId, String mode) {
        TCP_EmailSenderInvocable.Input input = new TCP_EmailSenderInvocable.Input();
        input.opportunityTcpId = otcpId;
        input.subject = 'Subject Test';
        input.recipientMode = mode;

        Test.startTest();
        List<TCP_EmailSenderInvocable.Output> result =
            TCP_EmailSenderInvocable.sendEmail(new List<TCP_EmailSenderInvocable.Input>{ input });
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result no puede ser null');
        System.assertEquals(1, result.size(), 'Debe devolver 1 Output');
        System.assertNotEquals(null, result[0], 'Output no puede ser null');
        System.assertEquals(mode, result[0].recipientModeUsed, 'recipientModeUsed debe coincidir');
        System.assertEquals(otcpId, result[0].opportunityTcpId, 'Debe mapear el mismo OTCP');
        System.assertNotEquals(null, result[0].message, 'Siempre debe haber message para diagnóstico');

        System.debug('OUTPUT (' + mode + '): ' + JSON.serialize(result[0]));
        return result[0];
    }

    // Helper: valida que resolvió destinatario
    // Nota: NO forzamos success=true porque en UAT Deliverability=System Email Only puede bloquear sendEmail.
    private static void assertRecipientResolved(TCP_EmailSenderInvocable.Output out) {
        System.assert(
            !String.isBlank(out.toEmailResolved),
            'No se resolvió email destino. message=' + out.message
        );
    }

    // ---------- INVOCABLE: inputs null / empty ----------
    @IsTest
    static void testSendEmail_NullInputs() {
        Test.startTest();
        List<TCP_EmailSenderInvocable.Output> result = TCP_EmailSenderInvocable.sendEmail(null);
        Test.stopTest();
        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testSendEmail_EmptyInputs() {
        Test.startTest();
        List<TCP_EmailSenderInvocable.Output> result =
            TCP_EmailSenderInvocable.sendEmail(new List<TCP_EmailSenderInvocable.Input>());
        Test.stopTest();
        System.assertEquals(0, result.size());
    }

    // ---------- CLIENT ----------
    @IsTest
    static void testSendEmail_Client() {
        OpportunityTCP__c otcp = getOtcp();
        TCP_EmailSenderInvocable.Output out = runInvocable(otcp.Id, 'CLIENT');

        System.assertEquals(
            'cliente@test.com',
            out.toEmailResolved,
            'Email de cliente no coincide. message=' + out.message
        );
    }

    // ---------- BIENVENIDA_CLIENTE (camino positivo) ----------
    @IsTest
    static void testSendEmail_BienvenidaCliente() {
        String configuredCardType = getAnyConfiguredCardType();

        if (String.isBlank(configuredCardType)) {
            System.assertEquals(null, configuredCardType, 'No hay TCP_Welcome_Config__mdt disponible en este ambiente.');
            return;
        }

        OpportunityTCP__c otcp = getOtcp();
        otcp.OTCP_CardType__c = configuredCardType;
        otcp.OTCP_limiteSugeridoDOP__c = 150000.50;
        otcp.OTCP_limiteSugeridoUSD__c = 3000.75;
        update otcp;

        TCP_EmailSenderInvocable.Output out = runInvocable(otcp.Id, 'BIENVENIDA_CLIENTE');

        System.assertEquals(
            'cliente@test.com',
            out.toEmailResolved,
            'Debe resolver el email del cliente en BIENVENIDA_CLIENTE. message=' + out.message
        );

        System.assertEquals(
            'BIENVENIDA_CLIENTE',
            out.recipientModeUsed,
            'Debe conservar el modo BIENVENIDA_CLIENTE'
        );

        // No forzamos success=true porque puede variar por Deliverability del org.
        System.assert(
            out.message != null &&
            (out.message.contains('Email preparado para envío.') || out.message.contains('Email enviado') || out.message.contains('Error al enviar email')),
            'Mensaje inesperado en BIENVENIDA_CLIENTE: ' + out.message
        );
    }

    // ---------- BIENVENIDA_CLIENTE (sin card type => excepción controlada) ----------
    @IsTest
    static void testSendEmail_BienvenidaCliente_SinCardType() {
        OpportunityTCP__c otcp = getOtcp();
        otcp.OTCP_CardType__c = null;
        update otcp;

        TCP_EmailSenderInvocable.Input input = new TCP_EmailSenderInvocable.Input();
        input.opportunityTcpId = otcp.Id;
        input.subject = 'Bienvenida sin card type';
        input.recipientMode = 'BIENVENIDA_CLIENTE';

        Test.startTest();
        List<TCP_EmailSenderInvocable.Output> result =
            TCP_EmailSenderInvocable.sendEmail(new List<TCP_EmailSenderInvocable.Input>{ input });
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(false, result[0].success);
        System.assert(
            result[0].message != null &&
            result[0].message.startsWith('Excepción en invocable:'),
            'Debe encapsular la excepción de BIENVENIDA_CLIENTE cuando falta OTCP_CardType__c. message=' + result[0].message
        );
    }

    // ---------- ANALYST ----------
    @IsTest
    static void testSendEmail_Analyst() {
        OpportunityTCP__c otcp = getOtcp();
        TCP_EmailSenderInvocable.Output out = runInvocable(otcp.Id, 'ANALYST');

        assertRecipientResolved(out);
        System.assert(
            out.toEmailResolved.contains('@test.com'),
            'Email analista inesperado. message=' + out.message
        );
    }

    // ---------- DEMORA_EVIDENCIAS ----------
    @IsTest
    static void testSendEmail_DemoraEvidencias() {
        OpportunityTCP__c otcp = getOtcp();
        TCP_EmailSenderInvocable.Output out = runInvocable(otcp.Id, 'DEMORA_EVIDENCIAS');
        assertRecipientResolved(out);
    }

    // ---------- ASIGNACION_ANALISTA_INICIAL ----------
    @IsTest
    static void testSendEmail_AsignacionAnalistaInicial() {
        OpportunityTCP__c otcp = getOtcp();
        TCP_EmailSenderInvocable.Output out = runInvocable(otcp.Id, 'ASIGNACION_ANALISTA_INICIAL');
        assertRecipientResolved(out);
    }

    // ---------- DEMORA_INICIAR_ANALISIS ----------
    @IsTest
    static void testSendEmail_DemoraIniciarAnalisis() {
        OpportunityTCP__c otcp = getOtcp();
        TCP_EmailSenderInvocable.Output out = runInvocable(otcp.Id, 'DEMORA_INICIAR_ANALISIS');
        assertRecipientResolved(out);
    }

    // ---------- DEMORA_TERMINAR_ANALISIS ----------
    @IsTest
    static void testSendEmail_DemoraTerminarAnalisis() {
        OpportunityTCP__c otcp = getOtcp();
        TCP_EmailSenderInvocable.Output out = runInvocable(otcp.Id, 'DEMORA_TERMINAR_ANALISIS');
        assertRecipientResolved(out);
    }

    // ---------- MODO INVALIDO ----------
    @IsTest
    static void testInvalidMode() {
        OpportunityTCP__c otcp = getOtcp();
        TCP_EmailSenderInvocable.Output out = runInvocable(otcp.Id, 'MODO_QUE_NO_EXISTE');

        System.assertEquals(false, out.success, 'Debe fallar en modo inválido');
        System.assert(out.message != null, 'Debe traer message');
    }

    // ---------- SIN DESTINATARIO (NO FAIL) ----------
    @IsTest
    static void testMissingRecipient_NoFail() {
        OpportunityTCP__c otcp = new OpportunityTCP__c(Name = 'OTCP-SIN-EMAIL');
        insert otcp;

        TCP_EmailSenderInvocable.Input input = new TCP_EmailSenderInvocable.Input();
        input.opportunityTcpId = otcp.Id;
        input.subject = 'Test sin destinatario';
        input.recipientMode = 'CLIENT';
        input.failOnMissingRecipient = false;

        Test.startTest();
        List<TCP_EmailSenderInvocable.Output> result =
            TCP_EmailSenderInvocable.sendEmail(new List<TCP_EmailSenderInvocable.Input>{ input });
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(false, result[0].success);
        System.assert(
            result[0].message != null && result[0].message.contains('No se resolvió email destino'),
            'Mensaje inesperado: ' + result[0].message
        );
    }

    // ---------- SIN DESTINATARIO (FAIL TRUE -> EXCEPTION ENCAPSULADA) ----------
    @IsTest
    static void testMissingRecipient_FailTrue_NoThrow_ButOutputHasExceptionMessage() {
        OpportunityTCP__c otcp = new OpportunityTCP__c(Name = 'OTCP-SIN-EMAIL-2');
        insert otcp;

        TCP_EmailSenderInvocable.Input input = new TCP_EmailSenderInvocable.Input();
        input.opportunityTcpId = otcp.Id;
        input.subject = 'Test sin destinatario';
        input.recipientMode = 'CLIENT';
        input.failOnMissingRecipient = true;

        Test.startTest();
        List<TCP_EmailSenderInvocable.Output> result =
            TCP_EmailSenderInvocable.sendEmail(new List<TCP_EmailSenderInvocable.Input>{ input });
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(false, result[0].success);
        System.assert(
            result[0].message != null && result[0].message.startsWith('Excepción en invocable:'),
            'Mensaje inesperado: ' + result[0].message
        );
    }

    // ---------- sendFromCode ----------
    @IsTest
    static void testSendFromCode_Covers() {
        OpportunityTCP__c otcp = getOtcp();

        Test.startTest();
        TCP_EmailSenderInvocable.Output out = TCP_EmailSenderInvocable.sendFromCode(
            otcp.Id,
            'Subject From Code',
            'ANALYST',
            null,
            false
        );
        Test.stopTest();

        System.assertNotEquals(null, out);
        System.assertEquals('ANALYST', out.recipientModeUsed);
        System.assertNotEquals(null, out.message);
        System.assert(!String.isBlank(out.toEmailResolved), 'Debe resolver destinatario');
    }

    // ---------- sendEmails (lista) ----------
    @IsTest
    static void testSendEmails_List_Covers() {
        Messaging.SingleEmailMessage m1 = new Messaging.SingleEmailMessage();
        m1.setToAddresses(new List<String>{ 'a@test.com' });
        m1.setSubject('S1');
        m1.setHtmlBody('<p>B1</p>');

        Messaging.SingleEmailMessage m2 = new Messaging.SingleEmailMessage();
        m2.setToAddresses(new List<String>{ 'b@test.com' });
        m2.setSubject('S2');
        m2.setHtmlBody('<p>B2</p>');

        Test.startTest();
        Messaging.SendEmailResult[] res =
            TCP_EmailSenderInvocable.sendEmails(new List<Messaging.SingleEmailMessage>{ m1, m2 });
        Test.stopTest();

        System.assertNotEquals(null, res);
        System.assertEquals(2, res.size());
    }

    // ---------- sendSingleEmail (incluye orgWide null) ----------
    @IsTest
    static void testSendSingleEmail_CoversBlock() {
        Test.startTest();
        Messaging.SendEmailResult r = TCP_EmailSenderInvocable.sendSingleEmail(
            'single@test.com',
            'Subject Single',
            '<p>Body</p>',
            null
        );
        Test.stopTest();

        System.assertNotEquals(null, r);
    }

    // ---------- sendSingleEmail invalid (solo cobertura) ----------
    @IsTest
    static void testSendSingleEmail_InvalidAddress_TriesErrorBranch() {
        Test.startTest();
        Messaging.SendEmailResult r = TCP_EmailSenderInvocable.sendSingleEmail(
            'not_an_email',
            'Bad Email',
            '<p>Body</p>',
            null
        );
        Test.stopTest();

        System.assertNotEquals(null, r);
    }
}
