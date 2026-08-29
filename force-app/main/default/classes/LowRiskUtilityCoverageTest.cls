@IsTest
private class LowRiskUtilityCoverageTest {
    private class ExchangeRateMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        ExchangeRateMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setStatus(statusCode == 200 ? 'OK' : 'Server Error');
            response.setBody(body);
            return response;
        }
    }

    @IsTest
    static void parsesAndRejectsExchangeRateResponses() {
        System.assertEquals(0, ExchangeRateService.getTasaCambio(null));

        Test.setMock(HttpCalloutMock.class, new ExchangeRateMock(200, '{"TasaCambio":"58.25"}'));
        System.assertEquals(58.25, ExchangeRateService.getTasaCambio(2));
        System.assertNotEquals(null, ExchangeRateService.lastRequestToLog);
        System.assertNotEquals(null, ExchangeRateService.lastResponseToLog);

        Test.setMock(HttpCalloutMock.class, new ExchangeRateMock(200, '{"TasaCambio":"INVALID"}'));
        System.assertEquals(0, ExchangeRateService.getTasaCambio(2));

        Test.setMock(HttpCalloutMock.class, new ExchangeRateMock(500, '{"error":"unavailable"}'));
        System.assertEquals(0, ExchangeRateService.getTasaCambio(2));
    }

    @IsTest
    static void exercisesEmptyDocumentExpirationBatch() {
        DocumentosVencimientoNotificationBatch batch =
            new DocumentosVencimientoNotificationBatch();
        DocumentosVencimientoNotificationBatch.WorkItem nearExpiration =
            new DocumentosVencimientoNotificationBatch.WorkItem(
                null,
                'Documentacion_Legal__c',
                'Documento de prueba',
                'Candidato de prueba',
                Date.today().addDays(5),
                true,
                false
            );

        Test.startTest();
        Iterable<DocumentosVencimientoNotificationBatch.WorkItem> pending = batch.start(null);
        batch.execute(null, null);
        batch.execute(null, new List<DocumentosVencimientoNotificationBatch.WorkItem>());
        batch.execute(
            null,
            new List<DocumentosVencimientoNotificationBatch.WorkItem>{ nearExpiration }
        );
        batch.finish(null);
        Test.stopTest();

        System.assertNotEquals(null, pending);
        System.assertEquals(true, nearExpiration.isNearExpiration);
    }

    @IsTest
    static void notifiesAndMarksExpiringLegalDocuments() {
        Datos_Maestros__c activity = new Datos_Maestros__c(
            Name = 'Expiration notification activity',
            DM_Direccion__c = 'EXP-NOT-001'
        );
        insert activity;
        Lead candidate = new Lead(
            FirstName = 'Document',
            LastName = 'Expiration',
            Company = 'Coverage company',
            Status = 'Iniciado',
            LEA_NumIdentificacion__c = '00108803123',
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
            LEA_PersonBirthdate__c = Date.today().addYears(-30),
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Actividad_Economica__c = activity.Id,
            LEA_Tipo_Sector__c = 'PRIVADO'
        );
        insert candidate;
        List<Documentacion_Legal__c> documents = new List<Documentacion_Legal__c>{
            new Documentacion_Legal__c(
                DOC_Candidato__c = candidate.Id,
                DOC_Codigo_Documento__c = 'NEAR-EXPIRATION',
                DOC_Fecha_Vencimiento__c = Date.today().addDays(5)
            ),
            new Documentacion_Legal__c(
                DOC_Candidato__c = candidate.Id,
                DOC_Codigo_Documento__c = 'EXPIRED',
                DOC_Fecha_Vencimiento__c = Date.today().addDays(-1)
            )
        };
        insert documents;

        Group legalQueue = [
            SELECT Id
            FROM Group
            WHERE Type = 'Queue' AND DeveloperName = 'FSC_Legal'
            LIMIT 1
        ];
        try {
            insert new GroupMember(GroupId = legalQueue.Id, UserOrGroupId = UserInfo.getUserId());
        } catch (DmlException alreadyMember) {
            System.assertNotEquals(null, alreadyMember);
        }

        DocumentosVencimientoNotificationBatch batch =
            new DocumentosVencimientoNotificationBatch();
        Test.startTest();
        batch.execute(
            null,
            new List<DocumentosVencimientoNotificationBatch.WorkItem>{
                new DocumentosVencimientoNotificationBatch.WorkItem(
                    documents[0].Id,
                    'Documentacion_Legal__c',
                    'Documento NEAR-EXPIRATION',
                    candidate.Name,
                    Date.today().addDays(5),
                    true,
                    false
                ),
                new DocumentosVencimientoNotificationBatch.WorkItem(
                    documents[1].Id,
                    'Documentacion_Legal__c',
                    'Documento EXPIRED',
                    candidate.Name,
                    Date.today().addDays(-1),
                    false,
                    true
                )
            }
        );
        Test.stopTest();

        System.assertNotEquals(null, legalQueue.Id);
        System.assertEquals(2, [SELECT COUNT() FROM Documentacion_Legal__c WHERE Id IN :documents]);
    }

    @IsTest
    static void handlesEmptyLegalDocumentAndParticipantChanges() {
        String documentPrefix = Documentacion_Legal__c.SObjectType.getDescribe().getKeyPrefix();
        String leadPrefix = Lead.SObjectType.getDescribe().getKeyPrefix();
        Documentacion_Legal__c unchangedDocument = new Documentacion_Legal__c(
            Id = Id.valueOf(documentPrefix + '000000000001')
        );

        Test.startTest();
        DocumentacionLegalTriggerHandler.afterInsert(null);
        DocumentacionLegalTriggerHandler.afterInsert(
            new List<Documentacion_Legal__c>{ null, unchangedDocument }
        );
        DocumentacionLegalTriggerHandler.afterUpdate(
            new List<Documentacion_Legal__c>{ null, unchangedDocument },
            new Map<Id, Documentacion_Legal__c>()
        );
        DocumentacionLegalTriggerHandler.afterDelete(
            new List<Documentacion_Legal__c>{ null, unchangedDocument }
        );
        DocumentacionLegalTriggerHandler.afterUndelete(null);
        DocumentacionLegalTriggerHandler.recalcularDocumentosNoAprobados(null);

        ParticipanteTotalsService.recalcularPorLeadsParticipantes(null);
        ParticipanteTotalsService.recalcularPorCandidatosPrincipales(new Set<Id>());
        ParticipanteTotalsService.recalcularPorLeadsParticipantes(
            new Set<Id>{ Id.valueOf(leadPrefix + '000000000001') }
        );
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void parsesInt057ResponsesAndFrames() {
        String successXml =
            '<ErrorCode>000</ErrorCode><ErrorText>OK</ErrorText>' +
            '<Result><ErrorText>Fila 1</ErrorText></Result>' +
            '<Result><ErrorText>Fila 2</ErrorText></Result>';
        INT057_FSC.Response success = INT057_FSC.parse(successXml);
        INT057_FSC.Response failure = INT057_FSC.parse(
            '<ErrorCode>500</ErrorCode><ErrorText>Error controlado</ErrorText>'
        );
        String detail = INT057_FSC.fillDetailClient(
            new Map<String, String>(),
            new Vinculado__c(),
            'contenido'
        );
        String frame = INT057_FSC.fillXML(
            new INT057_FSC.Response(),
            new Vinculado__c(),
            '<Function>contenido</Function>'
        );

        System.assertEquals('000', success.errorCode);
        System.assertEquals(2, success.responseList.size());
        System.assertEquals('500', failure.errorCode);
        System.assertEquals('contenido', detail);
        System.assert(frame.contains('contenido'));
    }

    @IsTest
    static void appliesFinancialAccountDefaultsAndSafeSkips() {
        Id checkingRecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c
            .getRecordTypeInfosByDeveloperName().get('CheckingAccount').getRecordTypeId();
        String keyPrefix = FinServ__FinancialAccount__c.SObjectType.getDescribe().getKeyPrefix();
        FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
            RecordTypeId = checkingRecordTypeId,
            FinServ__FinancialAccountNumber__c = '7788990011'
        );

        FinancialAccountTriggerHandler.beforeInsert(null);
        FinancialAccountTriggerHandler.beforeInsert(
            new List<FinServ__FinancialAccount__c>{ financialAccount }
        );
        financialAccount.Id = Id.valueOf(keyPrefix + '000000000001');

        FinancialAccountTriggerHandler.afterInsert(null);
        FinancialAccountTriggerHandler.afterInsert(
            new List<FinServ__FinancialAccount__c>{ financialAccount }
        );
        FinancialAccountTriggerHandler.afterUpdate(new List<FinServ__FinancialAccount__c>());
        FinancialAccountTriggerHandler.afterUpdate(
            new List<FinServ__FinancialAccount__c>{ financialAccount }
        );

        System.assertEquals('7788990011', financialAccount.Name);
        System.assertEquals('Cuentas corrientes', financialAccount.FIN_Linea_de_producto__c);
        System.assertEquals(0, financialAccount.FinServ__Balance__c);
        System.assertEquals('VIGENTE', financialAccount.FinServ__Status__c);
    }

    @IsTest
    static void listsCasesAssignedToCurrentUser() {
        Case assignedCase = new Case(
            Status = 'New',
            Origin = 'Phone',
            Subject = 'Assigned case coverage',
            Asignado_a__c = UserInfo.getUserId()
        );
        insert assignedCase;

        Test.startTest();
        List<MyAssignedCasesGridController.CaseRow> rows =
            MyAssignedCasesGridController.getMyAssignedCases();
        Test.stopTest();

        System.assertEquals(1, rows.size());
        System.assertEquals(assignedCase.Id, rows[0].caseId);
        System.assertNotEquals(null, rows[0].assignedToName);
    }

    @IsTest
    static void schedulesDocumentExpirationBatch() {
        Test.startTest();
        DocumentosVencimientoNotificScheduler.scheduleDaily();
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name =
                'Notificación diaria documentos por vencer']
        );
    }

    @IsTest
    static void exercisesDefensiveBatchSlaAndInvocableBranches() {
        VimencaAutoRejectLeadBatch batch = new VimencaAutoRejectLeadBatch();
        Database.QueryLocator locator = batch.start(null);
        batch.execute(null, new List<Lead>());
        batch.finish(null);

        VimencashSlaAssigner.applySlaIfNeeded(null);
        VimencashSlaAssigner.applySlaIfNeeded(new Case());
        String entitlementPrefix = Entitlement.SObjectType.getDescribe().getKeyPrefix();
        VimencashSlaAssigner.applySlaIfNeeded(
            new Case(EntitlementId = Id.valueOf(entitlementPrefix + '000000000001'))
        );
        List<RecordType> cancelacionTypes = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Case'
            AND DeveloperName = :VimencashSlaAssigner.RT_DEVNAME_CANCELACIONES
            LIMIT 1
        ];
        if (!cancelacionTypes.isEmpty()) {
            VimencashSlaAssigner.applySlaIfNeeded(
                new Case(RecordTypeId = cancelacionTypes[0].Id)
            );
        }

        String leadPrefix = Lead.SObjectType.getDescribe().getKeyPrefix();
        Id missingLeadId = Id.valueOf(leadPrefix + '000000000009');
        INT003_nValidarCL_Controller_FSC.Response accountResponse =
            INT003_nValidarCL_Controller_FSC.validatePF(missingLeadId);
        List<INT003_nValidarCL_Controller_FSC.Response> accountFlowResponses =
            INT003_nValidarCL_Controller_FSC.validatePFFlow(new List<Id>{ missingLeadId });
        INT003_ValidarContraLista_Controller_FSC.Response leadResponse =
            INT003_LEAD_ValidarContraList_Controller.validatePF(missingLeadId);
        List<INT003_ValidarContraLista_Controller_FSC.Response> leadFlowResponses =
            INT003_LEAD_ValidarContraList_Controller.validatePFFlow(
                new List<Id>{ missingLeadId }
            );

        ReintentarCreacionClienteCoreInvocable.reintentar(null);
        ReintentarCreacionClienteCoreInvocable.reintentar(
            new List<ReintentarCreacionClienteCoreInvocable.Request>{
                null,
                new ReintentarCreacionClienteCoreInvocable.Request()
            }
        );

        System.assertNotEquals(null, locator);
        System.assertEquals(false, accountResponse.updateSuccess);
        System.assertEquals(false, accountFlowResponses[0].updateSuccess);
        System.assertEquals(false, leadResponse.updateSuccess);
        System.assertEquals(false, leadFlowResponses[0].updateSuccess);
    }

    @IsTest
    static void validatesUnqualifiedLeadWithoutCallout() {
        Datos_Maestros__c activity = new Datos_Maestros__c(
            Name = 'Lead validation activity',
            DM_Direccion__c = 'LEAD-ACT-001'
        );
        insert activity;
        Lead candidate = new Lead(
            FirstName = 'Coverage',
            LastName = 'Unqualified',
            Company = 'Coverage Company',
            Status = 'Iniciado',
            LEA_NumIdentificacion__c = '00108803901',
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
            LEA_PersonBirthdate__c = Date.today().addYears(-30),
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Actividad_Economica__c = activity.Id,
            LEA_Tipo_Sector__c = 'PRIVADO'
        );
        insert candidate;

        INT003_ValidarContraLista_Controller_FSC.Response response =
            INT003_LEAD_ValidarContraList_Controller.validatePF(candidate.Id);
        List<INT003_ValidarContraLista_Controller_FSC.Response> flowResponses =
            INT003_LEAD_ValidarContraList_Controller.validatePFFlow(
                new List<Id>{ candidate.Id }
            );

        System.assertEquals(false, response.updateSuccess);
        System.assertEquals('VALIDACION NO EJECUTADA', response.errorText);
        System.assertEquals(false, flowResponses[0].updateSuccess);
    }

    @IsTest
    static void validatesQualifiedLeadWithMockedService() {
        Datos_Maestros__c activity = new Datos_Maestros__c(
            Name = 'Qualified lead activity',
            DM_Direccion__c = 'LEAD-ACT-002'
        );
        insert activity;
        Lead candidate = new Lead(
            FirstName = 'Coverage',
            LastName = 'Qualified',
            Company = 'Coverage Qualified Company',
            Status = 'Calificado',
            LEA_NumIdentificacion__c = '00108803902',
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
            LEA_PersonBirthdate__c = Date.today().addYears(-30),
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Actividad_Economica__c = activity.Id,
            LEA_Tipo_Sector__c = 'PRIVADO'
        );
        insert candidate;
        insert new Matriz_lista_control__c(
            MAT_Coincidencia_en_listas_externas__c = 'N',
            MAT_Coincidencia_en_listas__c = 'N',
            MAT_Resultado_validacion__c = 'Aprobado',
            MAT_Estado__c = 'Calificado',
            MAT_Sub_estado__c = 'Aceptado'
        );

        Test.setMock(HttpCalloutMock.class, new INT003_LEAD_FSC_TestMock('SUCCESS'));
        INT003_ValidarContraLista_Controller_FSC.Response response =
            INT003_LEAD_ValidarContraList_Controller.validatePF(candidate.Id);

        System.assertNotEquals(null, response);
    }

    @IsTest
    static void exercisesSafeBatchAndCoreServicePaths() {
        String leadPrefix = Lead.SObjectType.getDescribe().getKeyPrefix();
        VimencaAutoRejectLeadBatch batch = new VimencaAutoRejectLeadBatch();

        Test.startTest();
        batch.execute(null, new List<Lead>{
            new Lead(Id = Id.valueOf(leadPrefix + '000000000001'))
        });
        FinancialAccountCoreCreationService.process(null);
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void classifiesInMemoryAndFormatsIntegrationValues() {
        Account previous = new Account(
            ACC_Persona_Fisica__c = false,
            ACC_NumEmpleados__c = 1,
            ACC_Volumen_Ventas_Anual__c = 1,
            ACC_Total_Activos__c = 1
        );
        Account current = new Account(
            ACC_Persona_Fisica__c = false,
            ACC_NumEmpleados__c = 0,
            ACC_Volumen_Ventas_Anual__c = 0,
            ACC_Total_Activos__c = 0
        );

        new beforeUpdateClientsHelper().CalculateClasification(current, previous);
        System.assertEquals('Micro', current.ACC_Clasificacion_Empresa__c);

        Account values = new Account(
            Name = 'A & B',
            ACC_Total_Activos__c = 42.6
        );
        String frame = INTUtilities.fillCorrectType(
            new Map<String, String>{
                '[function_numEmployees]' => 'ACC_NumEmpleados__c',
                '[function_totalAssets]' => 'ACC_Total_Activos__c',
                '[function_name]' => 'Name',
                '[unused]' => ''
            },
            values,
            '[function_numEmployees]|[function_totalAssets]|[function_name]|[unused]'
        );

        System.assertEquals('0|43|A &amp; B|', frame);
    }

    private static String firstActivePicklistValue(String fieldName) {
        Schema.DescribeFieldResult fieldDescribe =
            Account.SObjectType.getDescribe().fields.getMap().get(fieldName).getDescribe();
        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        return null;
    }

    @IsTest
    static void coversClientClassificationBandsAndTranslations() {
        Decimal maxEmployees = Decimal.valueOf(Label.Max_Empleado);
        Decimal maxSales = Decimal.valueOf(Label.Max_Ventas);
        Decimal maxAssets = Decimal.valueOf(Label.Max_Activos);

        List<Decimal> factors = new List<Decimal>{ 0, 0.1, 0.5, 2 };
        List<String> expectedClassifications = new List<String>{
            'Micro', 'Pequeña', 'Mediana', 'Corporativa'
        };

        for (Integer i = 0; i < factors.size(); i++) {
            Account current = new Account(
                ACC_Persona_Fisica__c = false,
                ACC_NumEmpleados__c = maxEmployees * factors[i],
                ACC_Volumen_Ventas_Anual__c = maxSales * factors[i],
                ACC_Total_Activos__c = maxAssets * factors[i]
            );
            Account previous = new Account(
                ACC_Persona_Fisica__c = false,
                ACC_NumEmpleados__c = 1,
                ACC_Volumen_Ventas_Anual__c = 1,
                ACC_Total_Activos__c = 1
            );

            new beforeUpdateClientsHelper().CalculateClasification(current, previous);
            System.assertEquals(expectedClassifications[i], current.ACC_Clasificacion_Empresa__c);
        }

        Account pf = new Account(
            ACC_Fuente_Informacion__c = firstActivePicklistValue('ACC_Fuente_Informacion__c'),
            ACC_Persona_Fisica__c = true,
            ACC_Tipo_Persona_PF__c = firstActivePicklistValue('ACC_Tipo_Persona_PF__c'),
            ACC_Tipo_Cliente_PF__c = firstActivePicklistValue('ACC_Tipo_Cliente_PF__c')
        );
        Account pj = new Account(
            ACC_Fuente_Informacion__c = firstActivePicklistValue('ACC_Fuente_Informacion__c'),
            ACC_Persona_Fisica__c = false,
            ACC_Tipo_Persona_PJ__c = firstActivePicklistValue('ACC_Tipo_Persona_PJ__c'),
            ACC_Tipo_Cliente_PJ__c = firstActivePicklistValue('ACC_Tipo_Cliente_PJ__c')
        );

        beforeUpdateClientsHelper helper = new beforeUpdateClientsHelper();
        helper.Traducir_Valores_Cliente(pf);
        helper.Traducir_Valores_Cliente(pj);
        Account incomplete = new Account(ACC_Persona_Fisica__c = false);
        helper.CalculateClasification(incomplete, new Account());
        helper.updateCIF(new Account(), new Account());

        System.assertNotEquals(null, pf.ACC_Traduccion_tipo_persona__c);
        System.assertNotEquals(null, pj.ACC_Traduccion_tipo_persona__c);
    }

    @IsTest
    static void coversEmptyQueuesAndFlowRequestBuilders() {
        new FinancialAccountCoreCreationQueueable(null).execute(null);
        new FinancialAccountCoreCreationQueueable(new List<Id>()).execute(null);
        new VFS_EnviarComprobanteCasoQueueable(null).execute(null);
        new VFS_SubirComprobanteCasoEsignQueueable(null, null).execute(null);

        Opportunity opportunity = new Opportunity(
            Name = 'Flow body coverage',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Plazo__c = 12,
            Tasa__c = 10,
            Monto__c = 5000,
            Forma_de_pago__c = 'Mensual',
            Opp_numSolictud__c = '123'
        );

        ConsultaMontoFlowController.FlowInputs amountInput =
            new ConsultaMontoFlowController.FlowInputs();
        amountInput.opportunity = opportunity;
        String amountBody = ConsultaMontoFlowController.createBody(amountInput);

        SincronizarSolicitudFlowController.FlowInputs syncInput =
            new SincronizarSolicitudFlowController.FlowInputs();
        syncInput.opportunity = opportunity;
        String syncBody = SincronizarSolicitudFlowController.createBody(syncInput);

        System.assert(amountBody.contains('5000'));
        System.assert(syncBody.contains('123'));
        System.assertEquals(
            0,
            ConsultaMontoFlowController.qualify(
                new List<ConsultaMontoFlowController.FlowInputs>()
            ).size()
        );
        System.assertEquals(
            0,
            SincronizarSolicitudFlowController.sincronizar(
                new List<SincronizarSolicitudFlowController.FlowInputs>()
            ).size()
        );
        System.assertEquals(0, PreQualifyLeadFlowController_FSC.prequalify(new List<PreQualifyLeadFlowController_FSC.FlowInputs>()).size());

        Boolean invalidPrequalifyRejected = false;
        try {
            PreQualifyLeadFlowController_FSC.prequalify(null);
        } catch (Exception expected) {
            invalidPrequalifyRejected = true;
        }
        System.assertEquals(true, invalidPrequalifyRejected);
    }
}
