@IsTest
private class FSC_DescargarEnvelopeFirmadoQblTest {
    private class EnvelopeFilesBinaryMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/pdf');
            res.setBodyAsBlob(Blob.valueOf('PDF FIRMADO QUEUEABLE'));
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

    @IsTest
    static void testQueueable_GuardaFirmadoYMarcaOriginal() {
        ContentVersion original = createContentVersion('ENV-Q-001', 'Documento Queueable');
        Id rlaId = getRlaId(original.ContentDocumentId);

        Test.setMock(HttpCalloutMock.class, new EnvelopeFilesBinaryMock());

        Test.startTest();
        System.enqueueJob(new FSC_DescargarEnvelopeFirmadoQueueable(
            'ENV-Q-001',
            '2026-03-18T00:03:40+00:00'
        ));
        Test.stopTest();

        List<ContentVersion> activeOriginals = [
            SELECT Id
            FROM ContentVersion
            WHERE Id = :original.Id
        ];
        System.assertEquals(0, activeOriginals.size(), 'Debe eliminar el archivo original sin firma despues de guardar el firmado');

        List<ContentDocumentLink> signedLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :rlaId
            AND ContentDocument.LatestPublishedVersion.Title = 'Documento Queueable_firmado'
        ];
        System.assertEquals(1, signedLinks.size(), 'Debe crear un archivo separado con sufijo _firmado');
    }

    @IsTest
    static void testQueueable_NoDuplicaFirmadoExistente() {
        ContentVersion original = createContentVersion('ENV-Q-002', 'Documento Duplicado');
        Id rlaId = getRlaId(original.ContentDocumentId);

        insert new ContentVersion(
            Title = 'Documento Duplicado_firmado',
            PathOnClient = 'Documento Duplicado_firmado.pdf',
            VersionData = Blob.valueOf('PDF YA EXISTE'),
            FirstPublishLocationId = rlaId,
            FSC_Firmado__c = true
        );

        Test.setMock(HttpCalloutMock.class, new EnvelopeFilesBinaryMock());

        Test.startTest();
        System.enqueueJob(new FSC_DescargarEnvelopeFirmadoQueueable(
            'ENV-Q-002',
            '2026-03-18T00:03:40+00:00'
        ));
        Test.stopTest();

        List<ContentDocumentLink> signedLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :rlaId
            AND ContentDocument.LatestPublishedVersion.Title = 'Documento Duplicado_firmado'
        ];
        System.assertEquals(1, signedLinks.size(), 'No debe duplicar el archivo firmado');

        List<ContentVersion> activeOriginals = [
            SELECT Id
            FROM ContentVersion
            WHERE Id = :original.Id
        ];
        System.assertEquals(0, activeOriginals.size(), 'Debe eliminar el original si el firmado ya existia');
    }

    @IsTest
    static void testQueueable_NoMarcaOriginal_CuandoDescargaFalla() {
        ContentVersion original = createContentVersion('ENV-Q-003', 'Documento Error');

        Test.setMock(HttpCalloutMock.class, new EnvelopeFilesErrorMock());

        try {
            Test.startTest();
            System.enqueueJob(new FSC_DescargarEnvelopeFirmadoQueueable(
                'ENV-Q-003',
                '2026-03-18T00:03:40+00:00'
            ));
            Test.stopTest();
        } catch (Exception e) {
            // El fallo del callout debe dejar el original sin marcar.
        }

        ContentVersion updatedOriginal = [
            SELECT FSC_Firmado__c, FSC_FechaDeFirmaCliente__c
            FROM ContentVersion
            WHERE Id = :original.Id
            LIMIT 1
        ];
        System.assertEquals(false, updatedOriginal.FSC_Firmado__c);
        System.assertEquals(null, updatedOriginal.FSC_FechaDeFirmaCliente__c);
    }

    private static ContentVersion createContentVersion(String envelopeId, String title) {
        ResidentialLoanApplication rla = createRla();

        insert new ContentVersion(
            Title = title,
            PathOnClient = title + '.pdf',
            VersionData = Blob.valueOf('PDF ORIGINAL'),
            FirstPublishLocationId = rla.Id,
            FSC_EnviarDocumento__c = true,
            FSC_FechaEnvioFirma__c = System.now(),
            FSC_EnvelopeId__c = envelopeId,
            FSC_Firmado__c = false
        );

        return [
            SELECT Id, Title, ContentDocumentId, FSC_Firmado__c
            FROM ContentVersion
            WHERE Title = :title
            LIMIT 1
        ];
    }

    private static Id getRlaId(Id contentDocumentId) {
        for (ContentDocumentLink link : [
            SELECT LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId
        ]) {
            if (link.LinkedEntityId != null &&
                link.LinkedEntityId.getSObjectType() == ResidentialLoanApplication.SObjectType) {
                return link.LinkedEntityId;
            }
        }

        return null;
    }

    private static ResidentialLoanApplication createRla() {
        Account a = new Account();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
        a.Name = 'Cliente Queueable';
        a.ACC_NumIdentificacion__c = '00298765432';
        a.ACC_RNC__c = '131000005';
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
        rla.Name = 'RLA Queueable Test';
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
}
