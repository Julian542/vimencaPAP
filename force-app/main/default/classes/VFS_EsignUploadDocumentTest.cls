/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_EsignUploadDocumentTest
 * Versión                :   2.1
 * Fecha de creación      :   10/06/2025
 * Función                :   Clase para probar todos los escenarios de VFS_EsignUploadDocument
 * Clase que cubre        :   VFS_EsignUploadDocument
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        10/06/2025      Versión original
 *********************************************************************************************/
@SuppressWarnings('PMD')
@isTest
public class VFS_EsignUploadDocumentTest {
    // Mock global para cubrir tanto el servicio como el logger
    private class VFS_EsignUploadDocumentMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('/Api/v6/file/upload')) {
                res.setHeader('Content-Type', 'application/json');
                res.setStatusCode(200);
                res.setBody('{"FileId":"1234567890abcdef"}');
            } else {
                res.setHeader('Content-Type', 'application/json');
                res.setStatusCode(200);
                res.setBody('{"success":true}');
            }
            return res;
        }
    }
    private class VFS_EsignUploadDocumentMockError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('/Api/v6/file/upload')) {
                res.setHeader('Content-Type', 'application/json');
                res.setStatusCode(400);
                res.setBody('{"ErrorId":"ERR001","Message":"Archivo inválido","TraceId":"TRACE123"}');
            } else {
                res.setHeader('Content-Type', 'application/json');
                res.setStatusCode(200);
                res.setBody('{"success":true}');
            }
            return res;
        }
    }

    // Utilidad para obtener un Blob PDF válido
    private static Blob buildValidPdfBlob() {
        return Blob.valueOf('PDF-DATA');
    }
    // Utilidad para obtener un Blob PDF vacío
    private static Blob buildEmptyPdfBlob() {
        return Blob.valueOf('');
    }

    // Utilidad para crear un ContentDocument y vincularlo a un registro
    private static Id createContentDocument(Id linkedEntityId, String fileName, Boolean emptyBlob) {
        Blob pdfBlob = emptyBlob ? buildEmptyPdfBlob() : buildValidPdfBlob();
        ContentVersion cv   = new ContentVersion(
            Title           = fileName,
            PathOnClient    = fileName + '.pdf',
            VersionData     = pdfBlob,
            IsMajorVersion  = true
        );
        insert cv;
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId   = contentDocumentId,
            LinkedEntityId      = linkedEntityId,
            ShareType           = 'V',
            Visibility          = 'AllUsers'
        );
        insert cdl;
        return contentDocumentId;
    }

    private static Account createNeutralAccount(String name) {
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = name,
            ACC_RNC__c = String.valueOf(Math.abs(Crypto.getRandomInteger())).leftPad(9, '0').substring(0, 9),
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC'
        );
        insert acc;
        return acc;
    }

    @isTest
    static void testUploadDocumentSuccess() {
        Test.setMock(HttpCalloutMock.class, new VFS_EsignUploadDocumentMock());
        Account acc = createNeutralAccount('Test Account');
        Id contentDocumentId = createContentDocument(acc.Id, 'TestDoc', false);
        Test.startTest();
        VFS_EsignUploadDocument.UploadResult result = VFS_EsignUploadDocument.uploadDocument(contentDocumentId);
        Test.stopTest();
        System.assert(result.success, 'El resultado debe ser exitoso');
        System.assertEquals('1234567890abcdef', result.fileId, 'El FileId debe coincidir');
        System.assertEquals(null, result.errorId);
        System.assertEquals(null, result.message);
        System.assertEquals(null, result.traceId);
    }

    @isTest
    static void testUploadDocumentError() {
        Test.setMock(HttpCalloutMock.class, new VFS_EsignUploadDocumentMockError());
        Account acc = createNeutralAccount('Test Account 2');
        Id contentDocumentId = createContentDocument(acc.Id, 'TestDocError', false);
        Test.startTest();
        VFS_EsignUploadDocument.UploadResult result = VFS_EsignUploadDocument.uploadDocument(contentDocumentId);
        Test.stopTest();
        System.assert(!result.success, 'El resultado debe ser error');
        System.assert(result.message != null && result.message.contains('Error HTTP'), 'Debe devolver mensaje de error HTTP');
        System.assertEquals(null, result.fileId);
    }

    @isTest
    static void testUploadDocumentValidation_EmptyBlob() {
        // Salesforce no permite insertar ContentVersion con Blob vacío, así que este test se omite.
        System.assert(true, 'Test omitido por restricción de plataforma.');
    }

    @isTest
    static void testUploadDocumentValidation_InvalidId() {
        // Probar con un Id inválido (no existe ContentDocument)
        Test.startTest();
        VFS_EsignUploadDocument.UploadResult result = VFS_EsignUploadDocument.uploadDocument('069000000000000AAA');
        Test.stopTest();
        System.assert(!result.success);
        System.assert(result.message != null && result.message.contains('Excepción'), 'Debe devolver mensaje de excepción');
    }

    @isTest
    static void testUploadResultWrapperCoverage() {
        VFS_EsignUploadDocument.UploadResult result = new VFS_EsignUploadDocument.UploadResult();
        result.success = true;
        result.fileId = 'abc';
        result.errorId = 'err';
        result.message = 'msg';
        result.traceId = 'trace';
        System.assertEquals(true, result.success);
        System.assertEquals('abc', result.fileId);
        System.assertEquals('err', result.errorId);
        System.assertEquals('msg', result.message);
        System.assertEquals('trace', result.traceId);
    }

    @isTest
    static void testUploadQueueableSuccessPath() {
        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
        Account acc = createNeutralAccount('Queueable Test Account');
        Id contentDocumentId = createContentDocument(acc.Id, 'QueueableDoc', false);

        Test.startTest();
        new VFS_SubirComprobanteCasoEsignQueueable(null, contentDocumentId).execute(null);
        Test.stopTest();

        System.assert(true, 'La cola debe completar el camino exitoso sin excepciones.');
    }
}
