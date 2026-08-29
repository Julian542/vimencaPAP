@IsTest
private class FSC_ConsultarEstadoEnvelopeBatch_Test {

    private class EnvelopeCompletedMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            if (req.getEndpoint() != null && req.getEndpoint().endsWith('/files')) {
                res.setHeader('Content-Type', 'application/pdf');
                res.setBodyAsBlob(Blob.valueOf('PDF FIRMADO'));
                return res;
            }

            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"SenderUserInformation":{"Surname":"VIMENCA","GivenName":"BV_NOTIFICACIONES","Email":"bv_notificaciones@bv.com.do"},"Activities":[{"Action":{"Sign":{"SigningGroup":1,"ContactInformation":{"LanguageCode":"EN","Surname":"Valenti","GivenName":"Joel","Email":"testaccountfsc@yopmail.com"}}},"OpenedDate":"2026-03-18T00:03:28+00:00","FinishedDate":"2026-03-18T00:03:40+00:00","Status":"Completed","Id":"db91c363-0a01-42da-a556-235e9df31869"}],"SentDate":"2026-03-17T23:49:51+00:00","Name":"Pagare","EnvelopeStatus":"Completed","Id":"2eb4525a-cc8d-4a48-bda5-ab99ad983c12"}');
            return res;
        }
    }

    private class EnvelopeSentMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"SenderUserInformation":{"Surname":"VIMENCA","GivenName":"BV_NOTIFICACIONES","Email":"bv_notificaciones@bv.com.do"},"Activities":[{"Action":{"Sign":{"SigningGroup":1,"ContactInformation":{"LanguageCode":"EN","Surname":"Valenti","GivenName":"Joel","Email":"testaccountfsc@yopmail.com"}}},"OpenedDate":"2026-03-18T00:03:28+00:00","FinishedDate":null,"Status":"InProgress","Id":"db91c363-0a01-42da-a556-235e9df31869"}],"SentDate":"2026-03-17T23:49:51+00:00","Name":"Pagare","EnvelopeStatus":"InProgress","Id":"2eb4525a-cc8d-4a48-bda5-ab99ad983c12"}');
            return res;
        }
    }

    private class EnvelopeCompletedFilesErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();

            if (req.getEndpoint() != null && req.getEndpoint().endsWith('/files')) {
                res.setStatusCode(500);
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"Message":"No disponible"}');
                return res;
            }

            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Activities":[{"FinishedDate":"2026-03-18T00:03:40+00:00","Status":"Completed"}],"EnvelopeStatus":"Completed"}');
            return res;
        }
    }

    private static ContentVersion createContentVersion(String envelopeId) {
        ResidentialLoanApplication rla = createRla();

        ContentVersion cv = new ContentVersion(
            Title = 'Documento Test',
            PathOnClient = 'DocumentoTest.pdf',
            VersionData = Blob.valueOf('PDF TEST'),
            IsMajorVersion = true,
            FirstPublishLocationId = rla.Id,
            FSC_EnviarDocumento__c = true,
            FSC_FechaEnvioFirma__c = System.now(),
            FSC_EnvelopeId__c = envelopeId,
            FSC_Firmado__c = false
        );
        insert cv;

        return [
            SELECT Id, Title, ContentDocumentId, FSC_Firmado__c, FSC_FechaDeFirmaCliente__c, FSC_EnvelopeId__c
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];
    }

    private static ResidentialLoanApplication createRla() {
        Account a = new Account();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Candidato_Persona_Juridica')
            .getRecordTypeId();
        a.Name = 'Cliente Batch';
        a.ACC_NumIdentificacion__c = '00298765432';
        a.ACC_RNC__c = 'BATCH' + String.valueOf(System.now().getTime()).right(6);
        a.ACC_TipoIdentificacion__c = 'RNC';
        a.ACC_Condicion__c = 'PROSPECTO';
        a.ACC_Estado__c = 'INICIADO';
        a.ACC_Nacionalidad__c = 'AFGANISTÁN';
        a.ACC_Estado_Civil__c = 'SOLTERO/A';
        a.BillingStreet = 'Av. Siempre Viva';
        a.BillingCity = 'Santo Domingo';
        a.BillingState = 'DN';
        a.BillingCountry = 'Republica Dominicana';
        insert a;

        ResidentialLoanApplication rla = new ResidentialLoanApplication();
        rla.AccountId = a.Id;
        rla.Name = 'RLA Batch Test';
        rla.FSC_MontoAprobado__c = 100000;
        rla.FSC_FechaYHoraAprobacionComite__c = System.now();
        rla.FSC_PlazoMesesAprobado__c = 10;
        rla.FSC_Plazo_meses__c = '11';
        rla.FSC_Aplica_Garantia__c = false;
        rla.FSC_TasaInteresAprobada__c = 15;
        rla.FSC_Moneda__c = '1';
        rla.FSC_TasaInteres__c = 1.00;
        rla.FSC_Aprobado_con_Condiciones__c = false;
        rla.Status = 'En proceso';
        rla.FSC_Subestado__c = 'Gestionar firmas';
        insert rla;

        return rla;
    }

    @IsTest
    static void testBatch_ActualizaContentVersion_CuandoEnvelopeCompleted() {
        ContentVersion cv = createContentVersion('ENV-001');

        Test.setMock(HttpCalloutMock.class, new EnvelopeCompletedMock());

        Test.startTest();
        Database.executeBatch(new FSC_ConsultarEstadoEnvelopeBatch(), 1);
        Test.stopTest();

        ContentVersion result = [
            SELECT Id, FSC_Firmado__c, FSC_FechaDeFirmaCliente__c, FSC_EnvelopeId__c
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];

        System.assertEquals(false, result.FSC_Firmado__c, 'El batch solo debe encolar la descarga; el queueable marca el original');
        System.assertEquals(null, result.FSC_FechaDeFirmaCliente__c, 'El queueable guarda la fecha de firma');
    }

    @IsTest
    static void testBatch_NoActualiza_CuandoEnvelopeNoEstaCompleted() {
        ContentVersion cv = createContentVersion('ENV-002');

        Test.setMock(HttpCalloutMock.class, new EnvelopeSentMock());

        Test.startTest();
        Database.executeBatch(new FSC_ConsultarEstadoEnvelopeBatch(), 1);
        Test.stopTest();

        ContentVersion result = [
            SELECT Id, FSC_Firmado__c, FSC_FechaDeFirmaCliente__c, FSC_EnvelopeId__c
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];

        System.assertEquals(false, result.FSC_Firmado__c, 'No debe marcarse como firmado');
        System.assertEquals(null, result.FSC_FechaDeFirmaCliente__c, 'No debe guardar fecha de firma');
    }

    @IsTest
    static void testBatch_NoMarcaOriginal_CuandoDescargaFirmadoFalla() {
        ContentVersion cv = createContentVersion('ENV-004');

        Test.setMock(HttpCalloutMock.class, new EnvelopeCompletedFilesErrorMock());

        Test.startTest();
        Database.executeBatch(new FSC_ConsultarEstadoEnvelopeBatch(), 1);
        Test.stopTest();

        ContentVersion result = [
            SELECT Id, FSC_Firmado__c, FSC_FechaDeFirmaCliente__c
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];

        System.assertEquals(false, result.FSC_Firmado__c, 'No debe marcarse como firmado si no se guarda el PDF firmado');
        System.assertEquals(null, result.FSC_FechaDeFirmaCliente__c, 'No debe guardar fecha si falla la descarga');
    }

    @IsTest
    static void testSchedulable_EjecutaBatch() {
        ContentVersion cv = createContentVersion('ENV-003');

        Test.setMock(HttpCalloutMock.class, new EnvelopeCompletedMock());

        Test.startTest();
        new FSC_ConsultarEstadoEnvelopeBatch().execute(null);
        Test.stopTest();

        ContentVersion result = [
            SELECT Id, FSC_Firmado__c, FSC_FechaDeFirmaCliente__c, FSC_EnvelopeId__c
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];

        System.assertEquals(false, result.FSC_Firmado__c, 'El schedulable dispara el batch, y el batch encola la descarga');
        System.assertEquals(null, result.FSC_FechaDeFirmaCliente__c, 'El queueable guarda la fecha de firma');
    }

    @IsTest
    static void testSchedule_JobQuedaProgramado() {
        String cronExp = '0 0 8 * * ?';

        Test.startTest();
        String jobId = System.schedule(
            'TEST_FSC_ConsultarEstadoEnvelopeBatch_' + Datetime.now().getTime(),
            cronExp,
            new FSC_ConsultarEstadoEnvelopeBatch()
        );
        Test.stopTest();

        CronTrigger ct = [
            SELECT Id, CronExpression
            FROM CronTrigger
            WHERE Id = :jobId
            LIMIT 1
        ];

        System.assertEquals(cronExp, ct.CronExpression);
    }

    @IsTest
    static void testParseIsoDatetime() {
        Datetime dt1 = FSC_ConsultarEstadoEnvelopeBatch.parseIsoDatetime('2026-03-17T12:30:00Z');
        Datetime dt2 = FSC_ConsultarEstadoEnvelopeBatch.parseIsoDatetime('2026-03-17T12:30:00+00:00');
        Datetime dt3 = FSC_ConsultarEstadoEnvelopeBatch.parseIsoDatetime(null);

        System.assertNotEquals(null, dt1, 'Debe parsear formato con Z');
        System.assertNotEquals(null, dt2, 'Debe parsear formato con timezone');
        System.assertEquals(null, dt3, 'Debe retornar null cuando el valor venga vacío');
    }
}
