/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_EsignSendingEnvelope
 * Versión                :   1.0
 * Fecha de creación      :   10/06/2025
 * Función                :   Clase para enviar sobres (envelopes) a EsignAnywhere
 * Clase Test             :   VFS_EsignSendingEnvelopeTest
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        10/06/2025      Versión original
 *********************************************************************************************/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.NcssMethodCount,PMD.FieldNamingConventions')
public with sharing class VFS_EsignSendingEnvelope {
    // Método principal expuesto para enviar un solo sobre a EsignAnywhere
    @AuraEnabled
    public static EnvelopeResult sendEnvelope(EnvelopeRequest reqBody) {
        EnvelopeResult result = new EnvelopeResult();
        // Validar estructura y datos requeridos
        String validationError = validateEnvelopeRequest(reqBody);
        if (validationError != null) {
            result.success      = false;
            result.message      = validationError;
            result.debugInfo    = 'Validación fallida: ' + validationError;
            return result;
        }
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:VFS_Esignanywhere/Api/v6/envelope/send');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(buildApiRequestBody(reqBody)));
        HttpResponse res;
        Exception caughtException;
        try {
            Http http = new Http();
            res = http.send(req);
            caughtException = null;
            Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (respMap.containsKey('EnvelopeId')) {
                result.success      = true;
                result.envelopeId   = (String) respMap.get('EnvelopeId');
                result.debugInfo    = 'StatusCode: ' + res.getStatusCode() + '\nBody: ' + res.getBody();
            } else {
                result.success = false;
                result.errorId = (String) respMap.get('ErrorId');
                result.message = (String) respMap.get('Message');
                result.traceId = (String) respMap.get('TraceId');
                result.debugInfo = 'StatusCode: ' + res.getStatusCode() + '\nBody: ' + res.getBody();
            }
        } catch (Exception e) {
            res = new HttpResponse();
            caughtException = e;
            result.success = false;
            result.message = 'Error al consumir el servicio: ' + e.getMessage();
            result.debugInfo = 'Excepción: ' + e.getMessage();
        }
        // Registrar log de callout (siempre, al final)
        INTLogger.INTLoggerResult logResult = INTLogger.logCallout(
            'VFS_Esignanywhere', 'sendEnvelope', req, res
        );
        if (!logResult.success) {
            System.debug('Error guardando log: ' + logResult.message);
        }
        return result;
    }

    // Método expuesto para enviar múltiples sobres (soporte para Flow)
    @AuraEnabled
    public static List<EnvelopeResult> sendEnvelopes(List<EnvelopeRequest> reqBodies) {
        List<EnvelopeResult> results = new List<EnvelopeResult>();
        if (reqBodies == null){ return results; }
        for (EnvelopeRequest reqBody : reqBodies) {
            results.add(sendEnvelope(reqBody));
        }
        return results;
    }

    // Método privado para validar la estructura y datos requeridos del EnvelopeRequest
    // Retorna null si es válido, o un mensaje de error si falta algún dato
    private static String validateEnvelopeRequest(EnvelopeRequest req) {
        if (req == null){ return 'El request no puede ser nulo.'; }
        if (String.isBlank(req.Name)){ return 'El campo Name es obligatorio.'; }
        if (req.Documents == null || req.Documents.isEmpty()){ return 'Debe incluir al menos un documento.'; }
        for (EnvelopeDocument doc : req.Documents) {
            if (String.isBlank(doc.FileId)){ return 'Todos los documentos deben tener FileId.'; }
            if (doc.DocumentNumber == null){ return 'Todos los documentos deben tener DocumentNumber.'; }
        }
        if (req.Activities == null || req.Activities.isEmpty()){ return 'Debe incluir al menos una actividad.'; }
        for (EnvelopeActivity act : req.Activities) {
            if (act == null || act.Action == null){ return 'Cada actividad debe tener una acción.'; }
            EnvelopeAction action = act.Action;
            if (action.Sign == null && action.SendCopy == null){ return 'Cada acción debe tener Sign o SendCopy.'; }
            if (action.Sign != null) {
                EnvelopeSign sign = action.Sign;
                if (sign.RecipientConfiguration == null || sign.RecipientConfiguration.ContactInformation == null) {
                    return 'Sign debe tener RecipientConfiguration y ContactInformation.';
                }
                EnvelopeContactInformation ci = sign.RecipientConfiguration.ContactInformation;
                if (String.isBlank(ci.Email) || String.isBlank(ci.GivenName) || String.isBlank(ci.Surname)) {
                    return 'ContactInformation de Sign debe tener Email, GivenName y Surname.';
                }
                if (sign.Elements == null || sign.Elements.Signatures == null || sign.Elements.Signatures.isEmpty()) {
                    return 'Sign debe tener al menos una Signature.';
                }
                for (EnvelopeSignature sig : sign.Elements.Signatures) {
                    if (String.isBlank(sig.ElementId)){ return 'Cada Signature debe tener ElementId.'; }
                    if (sig.DocumentNumber == null){ return 'Cada Signature debe tener DocumentNumber.'; }
                    if (sig.AllowedSignatureTypes == null){ return 'AllowedSignatureTypes es requerido.'; }
                    if (sig.FieldDefinition == null){ return 'FieldDefinition es requerido.'; }
                    if (sig.FieldDefinition.Position == null || sig.FieldDefinition.Size == null) {
                        return 'Position y Size son requeridos.';
                    }
                    if (
                        sig.FieldDefinition.Position.PageNumber == null ||
                        sig.FieldDefinition.Position.X == null ||
                        sig.FieldDefinition.Position.Y == null ||
                        sig.FieldDefinition.Size.Width == null ||
                        sig.FieldDefinition.Size.Height == null
                    ) {
                        return 'PageNumber, X, Y, Width y Height son requeridos.';
                    }
                }
            }
            if (action.SendCopy != null) {
                EnvelopeSendCopy sendCopy = action.SendCopy;
                if (sendCopy.RecipientConfiguration == null || sendCopy.RecipientConfiguration.ContactInformation == null) {
                    return 'SendCopy debe tener RecipientConfiguration y ContactInformation.';
                }
                EnvelopeContactInformation ci = sendCopy.RecipientConfiguration.ContactInformation;
                if (String.isBlank(ci.Email) || String.isBlank(ci.GivenName) || String.isBlank(ci.Surname)) {
                    return 'ContactInformation de SendCopy debe tener Email, GivenName y Surname.';
                }
            }
        }
        return null;
    }

    private static Map<String, Object> buildApiRequestBody(EnvelopeRequest req) {
        Map<String, Object> body = new Map<String, Object>{
            'Documents' => req.Documents,
            'Name' => req.Name,
            'Activities' => req.Activities
        };

        Map<String, Object> emailConfiguration = buildEmailConfiguration(req);
        if (!emailConfiguration.isEmpty()) {
            body.put('EmailConfiguration', emailConfiguration);
        }

        return body;
    }

    private static Map<String, Object> buildEmailConfiguration(EnvelopeRequest req) {
        Map<String, Object> emailConfiguration = new Map<String, Object>();

        if (!String.isBlank(req.EmailSubject)) {
            emailConfiguration.put('Subject', req.EmailSubject);
        }
        if (!String.isBlank(req.EmailBody)) {
            emailConfiguration.put('Body', req.EmailBody);
            emailConfiguration.put('Message', req.EmailBody);
        }
        if (!String.isBlank(req.DisplayedEmailSender)) {
            emailConfiguration.put('SenderDisplayName', req.DisplayedEmailSender);
        }

        return emailConfiguration;
    }

    // --------------------- WRAPPERS PARA REQUEST Y RESPONSE ---------------------

    // Wrapper para la solicitud de envío de sobre
    public class EnvelopeRequest {
        @AuraEnabled public List<EnvelopeDocument> Documents;
        @AuraEnabled public String Name;
        @AuraEnabled public String EmailSubject;
        @AuraEnabled public String EmailBody;
        @AuraEnabled public String DisplayedEmailSender;
        @AuraEnabled public List<EnvelopeActivity> Activities;
    }
    // Wrapper para documento dentro del sobre
    public class EnvelopeDocument {
        @AuraEnabled public String FileId;
        @AuraEnabled public Integer DocumentNumber;
    }
    // Wrapper para actividad dentro del sobre
    public class EnvelopeActivity {
        @AuraEnabled public EnvelopeAction Action;
    }
    // Wrapper para acción de la actividad (firmar o enviar copia)
    public class EnvelopeAction {
        @AuraEnabled public EnvelopeSign Sign;
        @AuraEnabled public EnvelopeSendCopy SendCopy;
    }
    // Wrapper para la acción de firmar
    public class EnvelopeSign {
        @AuraEnabled public EnvelopeRecipientConfiguration RecipientConfiguration;
        @AuraEnabled public EnvelopeElements Elements;
        @AuraEnabled public String SigningGroup;
    }
    // Wrapper para la acción de enviar copia
    public class EnvelopeSendCopy {
        @AuraEnabled public EnvelopeRecipientConfiguration RecipientConfiguration;
    }
    // Wrapper para configuración de destinatario
    public class EnvelopeRecipientConfiguration {
        @AuraEnabled public EnvelopeContactInformation ContactInformation;
    }
    // Wrapper para información de contacto del destinatario
    public class EnvelopeContactInformation {
        @AuraEnabled public String Email;
        @AuraEnabled public String GivenName;
        @AuraEnabled public String Surname;
        @AuraEnabled public String LanguageCode;
    }
    // Wrapper para elementos de firma
    public class EnvelopeElements {
        @AuraEnabled public List<EnvelopeSignature> Signatures;
    }
    // Wrapper para definición de una firma
    public class EnvelopeSignature {
        @AuraEnabled public String ElementId;
        @AuraEnabled public Boolean Required;
        @AuraEnabled public Integer DocumentNumber;
        @AuraEnabled public String DisplayName;
        @AuraEnabled public EnvelopeAllowedSignatureTypes AllowedSignatureTypes;
        @AuraEnabled public EnvelopeFieldDefinition FieldDefinition;
    }
    // Wrapper para tipos de firma permitidos
    public class EnvelopeAllowedSignatureTypes {
        @AuraEnabled public EnvelopeClickToSign ClickToSign;
    }
    // Wrapper para click-to-sign
    public class EnvelopeClickToSign {}
    // Wrapper para definición de campo de firma
    public class EnvelopeFieldDefinition {
        @AuraEnabled public EnvelopePosition Position;
        @AuraEnabled public EnvelopeSize Size;
    }
    // Wrapper para posición de campo
    public class EnvelopePosition {
        @AuraEnabled public Integer PageNumber;
        @AuraEnabled public Integer X;
        @AuraEnabled public Integer Y;
    }
    // Wrapper para tamaño de campo
    public class EnvelopeSize {
        @AuraEnabled public Integer Width;
        @AuraEnabled public Integer Height;
    }
    // Wrapper para el resultado del envío
    public class EnvelopeResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String envelopeId;
        @AuraEnabled public String errorId;
        @AuraEnabled public String message;
        @AuraEnabled public String traceId;
        @AuraEnabled public String debugInfo; // Información de depuración
    }
}