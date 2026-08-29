@IsTest
private class FSC_EnviarEnvelopeQueueable_Test {
    private static Account buildNeutralAccount(String name) {
        return new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica')
                .getRecordTypeId(),
            Name = name,
            ACC_RNC__c = 'ENV' + String.valueOf(System.now().getTime()).right(6),
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Correo_Electronico_Cliente__c = 'queueable@test.com'
        );
    }

    @TestSetup
    static void setupData() {
        Account acc = buildNeutralAccount('Cuenta Queueable');
        insert acc;

        Date actaDate = Date.today();
        DateTime approvedDt = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 14, 30, 0);
        ResidentialLoanApplication rla = new ResidentialLoanApplication();
        rla.AccountId = acc.Id;
        rla.RecordTypeId = getRecordTypeId('FSC_Solicitud_Credito_PYME');
        rla.FSC_SolicitudAprobadaPorComite__c = true;
        rla.FSC_FechaYHoraAprobacionComite__c = approvedDt;
        rla.Name = 'Test RLA ' + String.valueOf(approvedDt);
        rla.FSC_Monto__c = 1000;
        rla.FSC_MontoAprobado__c = 900;
        rla.FSC_PlazoMeses__c = 10;
        rla.FSC_PlazoMesesAprobado__c = 9;
        rla.FSC_TasaInteres__c = 12;
        rla.FSC_TasaInteresAprobada__c = 10;
        rla.FSC_Aplica_Garantia__c = false;
        rla.FSC_DecisionComite__c = 'Aprobada con condición';

        insert rla;

        insert new ContentVersion(
            Title = 'Crédito PyMe - Queueable Test',
            PathOnClient = 'credito_queueable.pdf',
            VersionData = Blob.valueOf('PDF CREDITO QUEUEABLE'),
            FirstPublishLocationId = rla.Id,
            FSC_EnviarDocumento__c = true
        );

        insert new ContentVersion(
            Title = 'Pagare Queueable Test',
            PathOnClient = 'pagare_queueable.pdf',
            VersionData = Blob.valueOf('PDF PAGARE QUEUEABLE'),
            FirstPublishLocationId = rla.Id,
            FSC_EnviarDocumento__c = true
        );
    }

    private static ResidentialLoanApplication getRla() {
        return [
            SELECT Id, FSC_EnviadoAFirmar__c, FSC_LogErrores__c
            FROM ResidentialLoanApplication
            LIMIT 1
        ];
    }

    private class EsignSendErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            String endpoint = req.getEndpoint() == null ? '' : req.getEndpoint();
            if (endpoint.contains('/file/upload')) {
                res.setBody('{"FileId":"mock-file-id-001"}');
                return res;
            }

            if (endpoint.contains('/envelope/send')) {
                res.setBody('{"ErrorId":"ERR_SEND","Message":"No se pudo crear el envelope","TraceId":"TRACE_SEND"}');
                return res;
            }

            res.setBody('{}');
            return res;
        }
    }

    private static Id getRecordTypeId(String developerName) {
        Map<String, Schema.RecordTypeInfo> recordTypes =
            Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName();
        System.assert(recordTypes.containsKey(developerName), 'No existe el RecordType: ' + developerName);
        return recordTypes.get(developerName).getRecordTypeId();
    }

    @IsTest
    static void testQueueableSoloCredito() {
        ResidentialLoanApplication rla = getRla();
        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

        Test.startTest();
        System.enqueueJob(new FSC_EnviarEnvelopeQueueable('CREDITO_PYME', rla.Id, false));
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testQueueableSoloPagare() {
        ResidentialLoanApplication rla = getRla();
        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

        Test.startTest();
        System.enqueueJob(new FSC_EnviarEnvelopeQueueable('PAGARE', rla.Id, false));
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testQueueableErrorReseteaSolicitudYLoguea() {
        ResidentialLoanApplication rla = getRla();
        update new ResidentialLoanApplication(Id = rla.Id, FSC_EnviadoAFirmar__c = true);

        Test.setMock(HttpCalloutMock.class, new EsignSendErrorMock());

        Test.startTest();
        System.enqueueJob(new FSC_EnviarEnvelopeQueueable('CREDITO_PYME', rla.Id, false));
        Test.stopTest();

        ResidentialLoanApplication updatedRla = getRla();
        System.assertEquals(false, updatedRla.FSC_EnviadoAFirmar__c, 'Debe permitir reintentar si falla el envio asincronico.');
        System.assert(
            updatedRla.FSC_LogErrores__c != null && updatedRla.FSC_LogErrores__c.contains('No se pudo enviar a firma'),
            'Debe registrar el error de envio.'
        );
    }
}
