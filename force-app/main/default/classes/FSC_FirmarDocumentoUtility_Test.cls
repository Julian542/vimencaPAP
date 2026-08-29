@IsTest
private class FSC_FirmarDocumentoUtility_Test {
    private class EnvelopeStatusErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"ErrorId":"ERR-1","Message":"Error envelope","TraceId":"TRACE-1"}'
            );
            return res;
        }
    }

    private class EnvelopeStatusExceptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Mock exception');
        }
    }

    private class EnvelopeFilesJsonMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{"Files":[{"FileName":"Documento Test.pdf","Content":"' +
                EncodingUtil.base64Encode(Blob.valueOf('PDF FIRMADO JSON')) +
                '"}]}'
            );
            return res;
        }
    }

    private class EnvelopeFilesFileIdMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            if (req.getEndpoint() != null && req.getEndpoint().contains('/file/')) {
                res.setHeader('Content-Type', 'application/pdf');
                res.setBodyAsBlob(Blob.valueOf('PDF FIRMADO FILEID'));
                return res;
            }

            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Documents":[{"FileId":"file-id-001","FileName":"Documento FileId.pdf"}]}');
            return res;
        }
    }

    private class EnvelopeFilesErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Message":"Error descarga"}');
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        Account acc = createTestAccount('Utility', 'cliente.utility@test.com');

        Date actaDate = Date.today();
        DateTime approvedDt = DateTime.newInstance(
            actaDate.year(),
            actaDate.month(),
            actaDate.day(),
            14,
            30,
            0
        );
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
            Title = 'Crédito PyMe - Joel Valenti - 42010242',
            PathOnClient = 'credito.pdf',
            VersionData = Blob.valueOf('PDF CREDITO'),
            FirstPublishLocationId = rla.Id,
            FSC_EnviarDocumento__c = true
        );

        insert new ContentVersion(
            Title = 'Pagare Joel Valenti 2026-03-10-16-43-34',
            PathOnClient = 'pagare.pdf',
            VersionData = Blob.valueOf('PDF PAGARE'),
            FirstPublishLocationId = rla.Id,
            FSC_EnviarDocumento__c = true
        );
    }

    private static ResidentialLoanApplication getRla() {
        return [SELECT Id FROM ResidentialLoanApplication LIMIT 1];
    }

    private static Id getRecordTypeId(String developerName) {
        Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName();
        System.assert(
            recordTypes.containsKey(developerName),
            'No existe el RecordType: ' + developerName
        );
        return recordTypes.get(developerName).getRecordTypeId();
    }

    private static Account createTestAccount(String suffix, String email) {
        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
        Id personAccountRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        Account acc = new Account(
            RecordTypeId = personAccountRtId,
            FirstName = 'Cuenta',
            LastName = 'Test ' + suffix,
            ACC_Correo_Electronico_Cliente__c = email
        );
        insert acc;
        return acc;
    }

    @IsTest
    static void testEnviarDocumentosFirmar_ProcesoValido() {
        Account acc = createTestAccount('Proceso Valido', 'procesovalido@test.com');

        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            AccountId = acc.Id,
            RecordTypeId = getRecordTypeId('FSC_Solicitud_Credito_PYME'),
            Name = 'RLA Proceso Valido'
        );
        insert rla;

        insert new ContentVersion(
            Title = 'Crédito PyMe - Proceso Valido',
            PathOnClient = 'credito-proceso-valido.pdf',
            VersionData = Blob.valueOf('PDF CREDITO PROCESO VALIDO'),
            FirstPublishLocationId = rla.Id,
            FSC_EnviarDocumento__c = true
        );

        insert new ContentVersion(
            Title = 'Pagare Proceso Valido',
            PathOnClient = 'pagare-proceso-valido.pdf',
            VersionData = Blob.valueOf('PDF PAGARE PROCESO VALIDO'),
            FirstPublishLocationId = rla.Id,
            FSC_EnviarDocumento__c = true
        );

        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

        Test.startTest();
        FSC_FirmarDocumentoUtility.SendDocumentsResult result = FSC_FirmarDocumentoUtility.enviarDocumentosFirmar(
            'Gestionar firmas',
            rla.Id
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.message);
    }

    @IsTest
    static void testEnviarDocumentosFirmar_ButtonInvalido() {
        ResidentialLoanApplication rla = getRla();

        try {
            FSC_FirmarDocumentoUtility.enviarDocumentosFirmar(
                'Boton Invalido',
                rla.Id
            );
            System.assert(false);
        } catch (Exception e) {
            System.assert(
                e.getMessage().contains('Tipo de proceso no reconocido')
            );
        }
    }

    @IsTest
    static void testEnviarDocumentosFirmar_ButtonVacio() {
        ResidentialLoanApplication rla = getRla();

        try {
            FSC_FirmarDocumentoUtility.enviarDocumentosFirmar('', rla.Id);
            System.assert(false);
        } catch (Exception e) {
            System.assert(e.getMessage().contains('no puede estar vacio'));
        }
    }

    @IsTest
    static void testEnviarDocumentosFirmar_RecordIdVacio() {
        try {
            FSC_FirmarDocumentoUtility.enviarDocumentosFirmar(
                'Gestionar firmas',
                ''
            );
            System.assert(false);
        } catch (Exception e) {
            System.assert(e.getMessage().contains('ID del registro'));
        }
    }

    @IsTest
    static void testEnviarPorProcesoCredito_NoExplota() {
        ResidentialLoanApplication rla = getRla();

        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

        Test.startTest();
        VFS_EsignSendingEnvelope.EnvelopeResult result = FSC_FirmarDocumentoUtility.enviarPorProceso(
            'CREDITO_PYME',
            rla.Id
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testEnviarPorProcesoPagare_NoExplota() {
        ResidentialLoanApplication rla = getRla();

        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

        Test.startTest();
        VFS_EsignSendingEnvelope.EnvelopeResult result = FSC_FirmarDocumentoUtility.enviarPorProceso(
            'PAGARE',
            rla.Id
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testEnviarPorProcesoSinArchivos() {
        Account acc = createTestAccount('Sin Archivos', 'sinarchivos@test.com');

        Date actaDate = Date.today();
        DateTime approvedDt = DateTime.newInstance(
            actaDate.year(),
            actaDate.month(),
            actaDate.day(),
            14,
            30,
            0
        );
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

        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

        Test.startTest();
        VFS_EsignSendingEnvelope.EnvelopeResult result = FSC_FirmarDocumentoUtility.enviarPorProceso(
            'CREDITO_PYME',
            rla.Id
        );
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(false, result.success);
        System.assert(
            result.message.contains('No se encontraron archivos pendientes')
        );
    }

    @IsTest
    static void testEnviarDocumentosFirmar_SinDocumentosPendientes_NoMarcaSolicitud() {
        Account acc = createTestAccount('Sin Pendientes', 'sinpendientes@test.com');

        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            AccountId = acc.Id,
            RecordTypeId = getRecordTypeId('FSC_Solicitud_Credito_PYME'),
            Name = 'RLA Sin Pendientes'
        );
        insert rla;

        insert new ContentVersion(
            Title = 'Crédito PyMe - Ya enviado',
            PathOnClient = 'credito-enviado.pdf',
            VersionData = Blob.valueOf('PDF CREDITO ENVIADO'),
            FirstPublishLocationId = rla.Id,
            FSC_EnviarDocumento__c = true,
            FSC_FechaEnvioFirma__c = System.now()
        );

        insert new ContentVersion(
            Title = 'Pagare Ya enviado',
            PathOnClient = 'pagare-enviado.pdf',
            VersionData = Blob.valueOf('PDF PAGARE ENVIADO'),
            FirstPublishLocationId = rla.Id,
            FSC_EnviarDocumento__c = true,
            FSC_FechaEnvioFirma__c = System.now()
        );

        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

        Test.startTest();
        FSC_FirmarDocumentoUtility.SendDocumentsResult result = FSC_FirmarDocumentoUtility.enviarDocumentosFirmar(
            'Gestionar firmas',
            rla.Id
        );
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(false, result.documentsSent);
        System.assert(result.message.contains('Sin documentos pendientes'));

        ResidentialLoanApplication updatedRla = [
            SELECT FSC_EnviadoAFirmar__c
            FROM ResidentialLoanApplication
            WHERE Id = :rla.Id
            LIMIT 1
        ];
        System.assertEquals(false, updatedRla.FSC_EnviadoAFirmar__c);
    }

    @IsTest
    static void testEnviarDocumentosFirmar_SoloPagarePendiente() {
        Account acc = createTestAccount('Solo Pagare', 'solopagare@test.com');

        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            AccountId = acc.Id,
            RecordTypeId = getRecordTypeId('FSC_Solicitud_Credito_PYME'),
            Name = 'RLA Solo Pagare'
        );
        insert rla;

        insert new ContentVersion(
            Title = 'Credito PyMe - Ya enviado',
            PathOnClient = 'credito-ya-enviado.pdf',
            VersionData = Blob.valueOf('PDF CREDITO YA ENVIADO'),
            FirstPublishLocationId = rla.Id,
            FSC_EnviarDocumento__c = true,
            FSC_FechaEnvioFirma__c = System.now()
        );

        insert new ContentVersion(
            Title = 'Pagare Solo Pendiente',
            PathOnClient = 'pagare-pendiente.pdf',
            VersionData = Blob.valueOf('PDF PAGARE PENDIENTE'),
            FirstPublishLocationId = rla.Id,
            FSC_EnviarDocumento__c = true
        );

        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

        Test.startTest();
        FSC_FirmarDocumentoUtility.SendDocumentsResult result = FSC_FirmarDocumentoUtility.enviarDocumentosFirmar(
            'Gestionar firmas',
            rla.Id
        );
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(false, result.documentsSent);
        System.assertEquals(false, result.creditoSent);
        System.assertEquals(false, result.pagareSent);
        System.assert(result.message.contains('Credito PYME'));
        System.assert(result.message.contains('Credito PYME'));
    }

    @IsTest
    static void testTieneArchivosPendientes_PorProceso() {
        ResidentialLoanApplication rla = getRla();

        System.assertEquals(
            true,
            FSC_FirmarDocumentoUtility.tieneArchivosPendientes('PAGARE', rla.Id)
        );
        System.assertEquals(
            true,
            FSC_FirmarDocumentoUtility.tieneArchivosPendientes(
                'CREDITO_PYME',
                rla.Id
            )
        );
    }

    @IsTest
    static void testTieneArchivosPendientes_CreditoPorRecordType() {
        Map<String, String> titleLabelByRecordType = new Map<String, String>{
            'FSC_Solicitud_Credito_PYME' => 'PyMe',
            'FSC_Solicitud_Credito_Consumo' => 'Consumo',
            'FSC_Solicitud_Credito_Vehiculo' => 'Vehiculo',
            'FSC_Solicitud_Credito_Hipotecario' => 'Hipotecario'
        };

        for (String recordTypeDeveloperName : titleLabelByRecordType.keySet()) {
            ResidentialLoanApplication rla = createRlaSinDocumentos(
                recordTypeDeveloperName
            );

            insert new ContentVersion(
                Title = 'Crédito ' +
                    titleLabelByRecordType.get(recordTypeDeveloperName) +
                    ' - Pendiente',
                PathOnClient = 'credito-' +
                    titleLabelByRecordType.get(recordTypeDeveloperName) +
                    '.pdf',
                VersionData = Blob.valueOf(
                    'PDF CREDITO ' +
                    titleLabelByRecordType.get(recordTypeDeveloperName)
                ),
                FirstPublishLocationId = rla.Id,
                FSC_EnviarDocumento__c = true
            );

            System.assertEquals(
                true,
                FSC_FirmarDocumentoUtility.tieneArchivosPendientes(
                    'CREDITO_PYME',
                    rla.Id
                ),
                'Debe encontrar documentos de credito para ' +
                recordTypeDeveloperName
            );
        }
    }

    @IsTest
    static void testEmailTextCreditoPorRecordType() {
        Map<String, String> emailLabelByRecordType = new Map<String, String>{
            'FSC_Solicitud_Credito_PYME' => 'PYME',
            'FSC_Solicitud_Credito_Consumo' => 'Consumo',
            'FSC_Solicitud_Credito_Vehiculo' => 'Vehiculo',
            'FSC_Solicitud_Credito_Hipotecario' => 'Hipotecario'
        };

        for (String recordTypeDeveloperName : emailLabelByRecordType.keySet()) {
            ResidentialLoanApplication rla = createRlaSinDocumentos(
                recordTypeDeveloperName
            );
            String expectedLabel = emailLabelByRecordType.get(
                recordTypeDeveloperName
            );

            String subject = FSC_FirmarDocumentoUtility.buildEmailSubject(
                'CREDITO_PYME',
                rla.Id
            );
            String body = FSC_FirmarDocumentoUtility.buildEmailBody(
                'CREDITO_PYME',
                rla.Id
            );

            System.assert(
                subject.contains(expectedLabel),
                'El asunto debe incluir el tipo de credito ' + expectedLabel
            );
            System.assert(
                body.contains(expectedLabel),
                'El cuerpo debe incluir el tipo de credito ' + expectedLabel
            );
        }
    }

    @IsTest
    static void testTieneArchivosPendientes_ProcesoInvalido() {
        ResidentialLoanApplication rla = getRla();

        try {
            FSC_FirmarDocumentoUtility.tieneArchivosPendientes(
                'INVALIDO',
                rla.Id
            );
            System.assert(false);
        } catch (Exception e) {
            System.assert(e.getMessage().contains('No existe configuracion'));
        }
    }

    @IsTest
    static void testMarcarSolicitudComoEnviada() {
        ResidentialLoanApplication rla = createRlaSinDocumentos();

        FSC_FirmarDocumentoUtility.marcarSolicitudComoEnviada(rla.Id);

        ResidentialLoanApplication updatedRla = [
            SELECT FSC_EnviadoAFirmar__c
            FROM ResidentialLoanApplication
            WHERE Id = :rla.Id
            LIMIT 1
        ];
        System.assertEquals(true, updatedRla.FSC_EnviadoAFirmar__c);
    }

    private static ResidentialLoanApplication createRlaSinDocumentos() {
        return createRlaSinDocumentos('FSC_Solicitud_Credito_PYME');
    }

    private static ResidentialLoanApplication createRlaSinDocumentos(
        String recordTypeDeveloperName
    ) {
        Account acc = createTestAccount('Sin Documentos ' + System.now().getTime(), 'sindocumentos@test.com');

        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            AccountId = acc.Id,
            RecordTypeId = getRecordTypeId(recordTypeDeveloperName),
            Name = 'RLA Sin Documentos ' + System.now().getTime()
        );
        insert rla;
        return rla;
    }

    @IsTest
    static void testObtenerEstadoEnvelope_Success() {
        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

        Test.startTest();
        FSC_FirmarDocumentoUtility.EnvelopeStatus result = FSC_FirmarDocumentoUtility.obtenerEstadoEnvelope(
            'env-001'
        );
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals('InProgress', result.envelopeStatus);
    }

    @IsTest
    static void testObtenerEstadoEnvelope_Error() {
        Test.setMock(HttpCalloutMock.class, new EnvelopeStatusErrorMock());

        Test.startTest();
        FSC_FirmarDocumentoUtility.EnvelopeStatus result = FSC_FirmarDocumentoUtility.obtenerEstadoEnvelope(
            'env-002'
        );
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals('ERR-1', result.errorId);
        System.assertEquals('Error envelope', result.message);
        System.assertEquals('TRACE-1', result.traceId);
    }

    @IsTest
    static void testObtenerEstadoEnvelope_Exception() {
        Test.setMock(HttpCalloutMock.class, new EnvelopeStatusExceptionMock());

        Test.startTest();
        FSC_FirmarDocumentoUtility.EnvelopeStatus result = FSC_FirmarDocumentoUtility.obtenerEstadoEnvelope(
            'env-003'
        );
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assert(result.message.contains('Mock exception'));
    }

    @IsTest
    static void testObtenerArchivosFirmadosEnvelope_Binario() {
        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());

        Test.startTest();
        List<FSC_FirmarDocumentoUtility.SignedEnvelopeFile> result =
            FSC_FirmarDocumentoUtility.obtenerArchivosFirmadosEnvelope('env-files-001');
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('Documento firmado.pdf', result[0].fileName);
        System.assertEquals('PDF FIRMADO MOCK', result[0].body.toString());
    }

    @IsTest
    static void testObtenerArchivosFirmadosEnvelope_JsonBase64() {
        Test.setMock(HttpCalloutMock.class, new EnvelopeFilesJsonMock());

        Test.startTest();
        List<FSC_FirmarDocumentoUtility.SignedEnvelopeFile> result =
            FSC_FirmarDocumentoUtility.obtenerArchivosFirmadosEnvelope('env-files-002');
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('Documento Test.pdf', result[0].fileName);
        System.assertEquals('PDF FIRMADO JSON', result[0].body.toString());
    }

    @IsTest
    static void testObtenerArchivosFirmadosEnvelope_JsonFileId() {
        Test.setMock(HttpCalloutMock.class, new EnvelopeFilesFileIdMock());

        Test.startTest();
        List<FSC_FirmarDocumentoUtility.SignedEnvelopeFile> result =
            FSC_FirmarDocumentoUtility.obtenerArchivosFirmadosEnvelope('env-files-004');
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('Documento FileId.pdf', result[0].fileName);
        System.assertEquals('PDF FIRMADO FILEID', result[0].body.toString());
    }

    @IsTest
    static void testObtenerArchivosFirmadosEnvelope_Error() {
        Test.setMock(HttpCalloutMock.class, new EnvelopeFilesErrorMock());

        Boolean thrown = false;
        try {
            FSC_FirmarDocumentoUtility.obtenerArchivosFirmadosEnvelope('env-files-003');
        } catch (Exception e) {
            thrown = true;
        }

        System.assertEquals(true, thrown, 'Debe lanzar excepcion cuando la descarga retorna error');
    }
}
