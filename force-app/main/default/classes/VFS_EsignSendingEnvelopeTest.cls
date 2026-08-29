/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_EsignSendingEnvelopeTest
 * Versión                :   1.0
 * Fecha de creación      :   10/06/2025
 * Función                :   ase para enviar sobres (envelopes) a EsignAnywhere
 * Clase que cubre        :   VFS_EsignSendingEnvelope
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        10/06/2025      Versión original
 *********************************************************************************************/
@isTest
private class VFS_EsignSendingEnvelopeTest {

    // Mock para respuesta exitosa
    private class VFS_EsignSendingEnvelopeMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"EnvelopeId":"ENVELOPE123456"}');
            return res;
        }
    }
    // Mock para respuesta de error
    private class VFS_EsignSendingEnvelopeMockError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('{"ErrorId":"ERR002","Message":"Envelope inválido","TraceId":"TRACE456"}');
            return res;
        }
    }

    // Utilidades para construir objetos válidos
    private static VFS_EsignSendingEnvelope.EnvelopeContactInformation buildContact() {
        VFS_EsignSendingEnvelope.EnvelopeContactInformation contact = new VFS_EsignSendingEnvelope.EnvelopeContactInformation();
        contact.Email = 'test@email.com';
        contact.GivenName = 'Test';
        contact.Surname = 'User';
        contact.LanguageCode = 'EN';
        return contact;
    }
    private static VFS_EsignSendingEnvelope.EnvelopeRecipientConfiguration buildRecipient() {
        VFS_EsignSendingEnvelope.EnvelopeRecipientConfiguration recipient = new VFS_EsignSendingEnvelope.EnvelopeRecipientConfiguration();
        recipient.ContactInformation = buildContact();
        return recipient;
    }
    private static VFS_EsignSendingEnvelope.EnvelopeSignature buildSignature() {
        VFS_EsignSendingEnvelope.EnvelopeSignature signature = new VFS_EsignSendingEnvelope.EnvelopeSignature();
        signature.ElementId = 'sig1';
        signature.Required = true;
        signature.DocumentNumber = 1;
        signature.DisplayName = 'Sign here';
        VFS_EsignSendingEnvelope.EnvelopeAllowedSignatureTypes allowedTypes = new VFS_EsignSendingEnvelope.EnvelopeAllowedSignatureTypes();
        allowedTypes.ClickToSign = new VFS_EsignSendingEnvelope.EnvelopeClickToSign();
        signature.AllowedSignatureTypes = allowedTypes;
        VFS_EsignSendingEnvelope.EnvelopeFieldDefinition fieldDef = new VFS_EsignSendingEnvelope.EnvelopeFieldDefinition();
        VFS_EsignSendingEnvelope.EnvelopePosition pos = new VFS_EsignSendingEnvelope.EnvelopePosition();
        pos.PageNumber = 1;
        pos.X = 100;
        pos.Y = 200;
        VFS_EsignSendingEnvelope.EnvelopeSize size = new VFS_EsignSendingEnvelope.EnvelopeSize();
        size.Width = 100;
        size.Height = 70;
        fieldDef.Position = pos;
        fieldDef.Size = size;
        signature.FieldDefinition = fieldDef;
        return signature;
    }
    private static VFS_EsignSendingEnvelope.EnvelopeRequest buildValidEnvelopeRequest() {
        VFS_EsignSendingEnvelope.EnvelopeDocument doc = new VFS_EsignSendingEnvelope.EnvelopeDocument();
        doc.FileId = 'fileid-1';
        doc.DocumentNumber = 1;
        VFS_EsignSendingEnvelope.EnvelopeSignature signature = buildSignature();
        VFS_EsignSendingEnvelope.EnvelopeElements elements = new VFS_EsignSendingEnvelope.EnvelopeElements();
        elements.Signatures = new List<VFS_EsignSendingEnvelope.EnvelopeSignature>{ signature };
        VFS_EsignSendingEnvelope.EnvelopeSign sign = new VFS_EsignSendingEnvelope.EnvelopeSign();
        sign.RecipientConfiguration = buildRecipient();
        sign.Elements = elements;
        sign.SigningGroup = 'group1';
        VFS_EsignSendingEnvelope.EnvelopeAction action = new VFS_EsignSendingEnvelope.EnvelopeAction();
        action.Sign = sign;
        VFS_EsignSendingEnvelope.EnvelopeActivity activity = new VFS_EsignSendingEnvelope.EnvelopeActivity();
        activity.Action = action;
        VFS_EsignSendingEnvelope.EnvelopeRequest req = new VFS_EsignSendingEnvelope.EnvelopeRequest();
        req.Documents = new List<VFS_EsignSendingEnvelope.EnvelopeDocument>{ doc };
        req.Name = 'TestEnv';
        req.Activities = new List<VFS_EsignSendingEnvelope.EnvelopeActivity>{ activity };
        return req;
    }

    @isTest
    static void testSendEnvelopeSuccess() {
        Test.setMock(HttpCalloutMock.class, new VFS_EsignSendingEnvelopeMock());
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_EsignSendingEnvelope.sendEnvelope(buildValidEnvelopeRequest());
        System.assert(result.success, 'El resultado debe ser exitoso');
        System.assertEquals('ENVELOPE123456', result.envelopeId, 'El EnvelopeId debe coincidir');
        System.assertEquals(null, result.errorId);
        System.assertEquals(null, result.message);
        System.assertEquals(null, result.traceId);
    }

    @isTest
    static void testSendEnvelopeError() {
        Test.setMock(HttpCalloutMock.class, new VFS_EsignSendingEnvelopeMockError());
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_EsignSendingEnvelope.sendEnvelope(buildValidEnvelopeRequest());
        System.assert(!result.success, 'El resultado debe ser error');
        System.assertEquals('ERR002', result.errorId);
        System.assertEquals('Envelope inválido', result.message);
        System.assertEquals('TRACE456', result.traceId);
        System.assertEquals(null, result.envelopeId);
    }

    @isTest
    static void testSendEnvelopesSuccess() {
        Test.setMock(HttpCalloutMock.class, new VFS_EsignSendingEnvelopeMock());
        List<VFS_EsignSendingEnvelope.EnvelopeResult> results = VFS_EsignSendingEnvelope.sendEnvelopes(new List<VFS_EsignSendingEnvelope.EnvelopeRequest>{ buildValidEnvelopeRequest() });
        System.assertEquals(1, results.size());
        System.assert(results[0].success);
        System.assertEquals('ENVELOPE123456', results[0].envelopeId);
    }

    @isTest
    static void testSendEnvelopesError() {
        Test.setMock(HttpCalloutMock.class, new VFS_EsignSendingEnvelopeMockError());
        List<VFS_EsignSendingEnvelope.EnvelopeResult> results = VFS_EsignSendingEnvelope.sendEnvelopes(new List<VFS_EsignSendingEnvelope.EnvelopeRequest>{ buildValidEnvelopeRequest() });
        System.assertEquals(1, results.size());
        System.assert(!results[0].success);
        System.assertEquals('ERR002', results[0].errorId);
        System.assertEquals('Envelope inválido', results[0].message);
        System.assertEquals('TRACE456', results[0].traceId);
        System.assertEquals(null, results[0].envelopeId);
    }

    @isTest
    static void testValidateEnvelopeRequest_NullRequest() {
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_EsignSendingEnvelope.sendEnvelope(null);
        System.assert(!result.success);
        System.assertEquals(null, result.envelopeId);
        System.assertEquals('El request no puede ser nulo.', result.message);
    }

    @isTest
    static void testValidateEnvelopeRequest_NoDocuments() {
        VFS_EsignSendingEnvelope.EnvelopeRequest req = buildValidEnvelopeRequest();
        req.Documents = new List<VFS_EsignSendingEnvelope.EnvelopeDocument>();
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_EsignSendingEnvelope.sendEnvelope(req);
        System.assert(!result.success);
        System.assertEquals('Debe incluir al menos un documento.', result.message);
    }

    @isTest
    static void testValidateEnvelopeRequest_NoActivities() {
        VFS_EsignSendingEnvelope.EnvelopeRequest req = buildValidEnvelopeRequest();
        req.Activities = new List<VFS_EsignSendingEnvelope.EnvelopeActivity>();
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_EsignSendingEnvelope.sendEnvelope(req);
        System.assert(!result.success);
        System.assertEquals('Debe incluir al menos una actividad.', result.message);
    }

    @isTest
    static void testValidateEnvelopeRequest_SignatureNoAllowedTypes() {
        VFS_EsignSendingEnvelope.EnvelopeRequest req = buildValidEnvelopeRequest();
        req.Activities[0].Action.Sign.Elements.Signatures[0].AllowedSignatureTypes = null;
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_EsignSendingEnvelope.sendEnvelope(req);
        System.assert(!result.success);
        System.assertEquals('AllowedSignatureTypes es requerido.', result.message);
    }

    @isTest
    static void testValidateEnvelopeRequest_SignatureNoFieldDefinition() {
        VFS_EsignSendingEnvelope.EnvelopeRequest req = buildValidEnvelopeRequest();
        req.Activities[0].Action.Sign.Elements.Signatures[0].FieldDefinition = null;
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_EsignSendingEnvelope.sendEnvelope(req);
        System.assert(!result.success);
        System.assertEquals('FieldDefinition es requerido.', result.message);
    }

    @isTest
    static void testValidateEnvelopeRequest_FieldDefinitionNoPositionOrSize() {
        VFS_EsignSendingEnvelope.EnvelopeRequest req = buildValidEnvelopeRequest();
        VFS_EsignSendingEnvelope.EnvelopeSignature sig = req.Activities[0].Action.Sign.Elements.Signatures[0];
        sig.FieldDefinition.Position = null;
        sig.FieldDefinition.Size = null;
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_EsignSendingEnvelope.sendEnvelope(req);
        System.assert(!result.success);
        System.assertEquals('Position y Size son requeridos.', result.message);
    }

    @isTest
    static void testValidateEnvelopeRequest_PositionOrSizeIncomplete() {
        VFS_EsignSendingEnvelope.EnvelopeRequest req = buildValidEnvelopeRequest();
        VFS_EsignSendingEnvelope.EnvelopeSignature sig = req.Activities[0].Action.Sign.Elements.Signatures[0];
        sig.FieldDefinition.Position.PageNumber = null;
        sig.FieldDefinition.Position.X = null;
        sig.FieldDefinition.Position.Y = null;
        sig.FieldDefinition.Size.Width = null;
        sig.FieldDefinition.Size.Height = null;
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_EsignSendingEnvelope.sendEnvelope(req);
        System.assert(!result.success);
        System.assertEquals('PageNumber, X, Y, Width y Height son requeridos.', result.message);
    }

    @isTest
    static void testValidateEnvelopeRequest_SignMissingRecipientConfiguration() {
        VFS_EsignSendingEnvelope.EnvelopeRequest req = buildValidEnvelopeRequest();
        req.Activities[0].Action.Sign.RecipientConfiguration = null;
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_EsignSendingEnvelope.sendEnvelope(req);
        System.assert(!result.success);
        System.assertEquals('Sign debe tener RecipientConfiguration y ContactInformation.', result.message);
    }

    @isTest
    static void testValidateEnvelopeRequest_SignMissingContactInformation() {
        VFS_EsignSendingEnvelope.EnvelopeRequest req = buildValidEnvelopeRequest();
        req.Activities[0].Action.Sign.RecipientConfiguration.ContactInformation = null;
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_EsignSendingEnvelope.sendEnvelope(req);
        System.assert(!result.success);
        System.assertEquals('Sign debe tener RecipientConfiguration y ContactInformation.', result.message);
    }

    @isTest
    static void testValidateEnvelopeRequest_SignMissingContactFields() {
        VFS_EsignSendingEnvelope.EnvelopeRequest req = buildValidEnvelopeRequest();
        VFS_EsignSendingEnvelope.EnvelopeContactInformation ci = req.Activities[0].Action.Sign.RecipientConfiguration.ContactInformation;
        ci.Email = null;
        ci.GivenName = null;
        ci.Surname = null;
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_EsignSendingEnvelope.sendEnvelope(req);
        System.assert(!result.success);
        System.assertEquals('ContactInformation de Sign debe tener Email, GivenName y Surname.', result.message);
    }

    @isTest
    static void testValidateEnvelopeRequest_SignMissingSignatures() {
        VFS_EsignSendingEnvelope.EnvelopeRequest req = buildValidEnvelopeRequest();
        req.Activities[0].Action.Sign.Elements.Signatures = new List<VFS_EsignSendingEnvelope.EnvelopeSignature>();
        VFS_EsignSendingEnvelope.EnvelopeResult result = VFS_EsignSendingEnvelope.sendEnvelope(req);
        System.assert(!result.success);
        System.assertEquals('Sign debe tener al menos una Signature.', result.message);
    }

    @isTest
    static void testEnvelopeRequestWrapperCoverage() {
        // Cobertura para getters/setters y constructor de EnvelopeRequest
        VFS_EsignSendingEnvelope.EnvelopeRequest req = new VFS_EsignSendingEnvelope.EnvelopeRequest();
        req.Name = 'TestName';
        req.Documents = new List<VFS_EsignSendingEnvelope.EnvelopeDocument>();
        req.Activities = new List<VFS_EsignSendingEnvelope.EnvelopeActivity>();
        System.assertEquals('TestName', req.Name);
        System.assertNotEquals(null, req.Documents);
        System.assertNotEquals(null, req.Activities);
    }
}