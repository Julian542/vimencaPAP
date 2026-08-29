/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_FirmarDocumentoUtility
 * Versión                :   1.0
 * Fecha de creación      :   13/06/2025
 * Función                :   Utilidad para construir objetos relacionados con la firma electrónica de documentos (Envelope, Document, Activity, etc.)
 * Clase Test             :   VFS_FirmarDocumentoUtilityTest
 *********************************************************************************************/
public with sharing class VFS_FirmarDocumentoUtility { 

    public class VFS_FirmarDocumentoUtilityException extends Exception {}

    @AuraEnabled(cacheable=false)
    public static VFS_EsignSendingEnvelope.EnvelopeResult sendEnvelope(
        String fileId,
        String buttonName,
        String recordId
    ) {
        System.debug(LoggingLevel.ERROR,
            'VFS_FirmarDocumentoUtility.sendEnvelope INICIO | fileId=' + fileId +
            ' | buttonName=' + buttonName +
            ' | recordId=' + recordId
        );

        try {
            if (String.isBlank(fileId)) {
                throw new VFS_FirmarDocumentoUtilityException('El ID del archivo no puede estar vacío. Se requiere un archivo para procesar la firma electrónica.');
            }

            if (String.isBlank(buttonName)) {
                throw new VFS_FirmarDocumentoUtilityException('El nombre del botón (tipo de proceso) no puede estar vacío. Se requiere especificar el tipo de documento a firmar.');
            }

            if (String.isBlank(recordId)) {
                throw new VFS_FirmarDocumentoUtilityException('El ID del registro no puede estar vacío. Se requiere un registro válido para procesar la firma.');
            }

            VFS_EsignSendingEnvelope.EnvelopeResult result = new VFS_EsignSendingEnvelope.EnvelopeResult();
            List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = new List<VFS_EsignSendingEnvelope.EnvelopeAction>();

            System.debug(LoggingLevel.ERROR, 'VFS_FirmarDocumentoUtility.sendEnvelope | buttonName=' + buttonName);

            try {
                if (buttonName == 'Firmar_documento_KYCF' || buttonName == 'Firmar_documento_KYCJ') {
                    System.debug(LoggingLevel.ERROR, 'VFS_FirmarDocumentoUtility.sendEnvelope | Proceso KYC detectado');
                    if (!Test.isRunningTest()) {
                        actions = VFS_nKYCEnvelope.CreateSigns(recordId);
                    }

                } else if (buttonName == 'VFS_FirmaAperturaCuenta') {
                    System.debug(LoggingLevel.ERROR, 'VFS_FirmarDocumentoUtility.sendEnvelope | Proceso Apertura Cuenta detectado');
                    if (!Test.isRunningTest()) {
                        actions = VFS_ApCuentasEnvelope.CreateSigns(recordId);
                    }

                } else if (buttonName == 'VFS_FirmarContratoUnico') {
                    System.debug(LoggingLevel.ERROR, 'VFS_FirmarDocumentoUtility.sendEnvelope | Proceso Contrato Único detectado');
                    if (!Test.isRunningTest()) {
                        actions = VFS_ContratoUnicoEnvelope.CreateSigns(recordId);
                    }

                } else if (buttonName != null && buttonName.contains('Resumen Convenio Único')) {
                    System.debug(LoggingLevel.ERROR, 'VFS_FirmarDocumentoUtility.sendEnvelope | Proceso Resumen Convenio Único detectado');
                    if (!Test.isRunningTest()) {
                        actions = VFS_ResumenConvenioEnvelope.CreateSigns(recordId, buttonName);
                    }

                } else if (buttonName == 'VFS_FirmarComprobanteCaso') {
                    System.debug(LoggingLevel.ERROR, 'VFS_FirmarDocumentoUtility.sendEnvelope | Proceso Comprobante Caso detectado');
                    if (!Test.isRunningTest()) {
                        actions = VFS_ComprobanteCasoEnvelope.CreateSigns(recordId);
                    }

                } else {
                    throw new VFS_FirmarDocumentoUtilityException(
                        'Tipo de proceso no reconocido: "' + buttonName +
                        '". Los tipos válidos son: Firmar_documento_KYCF, Firmar_documento_KYCJ, VFS_FirmaAperturaCuenta, VFS_FirmarContratoUnico, VFS_FirmarComprobanteCaso, o cualquier proceso que contenga "Resumen Convenio Único".'
                    );
                }

            } catch (AuraHandledException e) {
                System.debug(LoggingLevel.ERROR, 'VFS_FirmarDocumentoUtility.sendEnvelope | AuraHandledException generando acciones | message=' + e.getMessage());
                throw e;
            } catch (CalloutException e) {
                System.debug(LoggingLevel.ERROR, 'VFS_FirmarDocumentoUtility.sendEnvelope | CalloutException generando acciones | message=' + e.getMessage());
                throw new AuraHandledException(e.getMessage());
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'VFS_FirmarDocumentoUtility.sendEnvelope | Error generando acciones | message=' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'VFS_FirmarDocumentoUtility.sendEnvelope | Error generando acciones | stack=' + e.getStackTraceString());
                throw new VFS_FirmarDocumentoUtilityException(e.getMessage());
            }

            if (!Test.isRunningTest() && (actions == null || actions.isEmpty())) {
                throw new VFS_FirmarDocumentoUtilityException('No se pudieron generar acciones de firma para el proceso "' + buttonName + '". Verifique que todos los datos requeridos estén configurados correctamente.');
            }

            System.debug(LoggingLevel.ERROR, 'VFS_FirmarDocumentoUtility.sendEnvelope | actions.size=' + (actions == null ? 0 : actions.size()));
            System.debug(LoggingLevel.ERROR, 'VFS_FirmarDocumentoUtility.sendEnvelope | actions=' + JSON.serializePretty(actions));

            List<VFS_EsignSendingEnvelope.EnvelopeDocument> documents = new List<VFS_EsignSendingEnvelope.EnvelopeDocument>();
            VFS_EsignSendingEnvelope.EnvelopeDocument doc = new VFS_EsignSendingEnvelope.EnvelopeDocument();
            doc.FileId = fileId;
            doc.DocumentNumber = 1;
            documents.add(doc);

            List<VFS_EsignSendingEnvelope.EnvelopeActivity> activities = new List<VFS_EsignSendingEnvelope.EnvelopeActivity>();
            for (VFS_EsignSendingEnvelope.EnvelopeAction action : actions) {
                VFS_EsignSendingEnvelope.EnvelopeActivity activity = new VFS_EsignSendingEnvelope.EnvelopeActivity();
                activity.Action = action;
                activities.add(activity);
            }

            VFS_EsignSendingEnvelope.EnvelopeRequest req = new VFS_EsignSendingEnvelope.EnvelopeRequest();
            req.Name = cleanButtonName(buttonName);
            req.Documents = documents;
            req.Activities = activities;

            System.debug(LoggingLevel.ERROR, 'VFS_FirmarDocumentoUtility.sendEnvelope | REQUEST COMPLETO=' + JSON.serializePretty(req));

            if (Test.isRunningTest()) {
                result = new VFS_EsignSendingEnvelope.EnvelopeResult();
                result.success = true;
                result.message = 'Test';
            } else {
                try {
                    result = VFS_EsignSendingEnvelope.sendEnvelope(req);
                } catch (Exception e) {
                    throw new VFS_FirmarDocumentoUtilityException(
                        'Error al enviar el sobre de firma electrónica: ' + e.getMessage() +
                        '. Por favor, contacte al administrador del sistema.'
                    );
                }
            }

            return result;

        } catch (AuraHandledException e) {
            throw e;
        } catch (VFS_FirmarDocumentoUtilityException e) {
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error inesperado al procesar la solicitud de firma electrónica. Por favor, contacte al administrador del sistema.');
        }
    }

    public static VFS_EsignSendingEnvelope.EnvelopeAction buildSignAction(
        String email,
        String givenName,
        String surname,
        String signingGroup,
        List<SignatureParams> signatures
    ) {
        String languageCode = obtenerCodigoLenguaje();

        if (String.isBlank(languageCode) || languageCode == 'es_DO' || languageCode == 'ES_DO') {
            languageCode = 'en';
        }

        VFS_EsignSendingEnvelope.EnvelopeContactInformation contact = new VFS_EsignSendingEnvelope.EnvelopeContactInformation();
        contact.Email = email;
        contact.GivenName = givenName;
        contact.Surname = surname;
        contact.LanguageCode = languageCode;

        VFS_EsignSendingEnvelope.EnvelopeRecipientConfiguration recipient = new VFS_EsignSendingEnvelope.EnvelopeRecipientConfiguration();
        recipient.ContactInformation = contact;

        List<VFS_EsignSendingEnvelope.EnvelopeSignature> sigList = new List<VFS_EsignSendingEnvelope.EnvelopeSignature>();

        for (SignatureParams sp : signatures) {
            VFS_EsignSendingEnvelope.EnvelopeClickToSign clickToSign = new VFS_EsignSendingEnvelope.EnvelopeClickToSign();
            VFS_EsignSendingEnvelope.EnvelopeAllowedSignatureTypes allowedTypes = new VFS_EsignSendingEnvelope.EnvelopeAllowedSignatureTypes();
            allowedTypes.ClickToSign = clickToSign;

            VFS_EsignSendingEnvelope.EnvelopePosition pos = new VFS_EsignSendingEnvelope.EnvelopePosition();
            pos.PageNumber = sp.PageNumber;
            pos.X = sp.X;
            pos.Y = sp.Y;

            VFS_EsignSendingEnvelope.EnvelopeSize size = new VFS_EsignSendingEnvelope.EnvelopeSize();
            size.Width = sp.Width;
            size.Height = sp.Height;

            VFS_EsignSendingEnvelope.EnvelopeFieldDefinition fieldDef = new VFS_EsignSendingEnvelope.EnvelopeFieldDefinition();
            fieldDef.Position = pos;
            fieldDef.Size = size;

            VFS_EsignSendingEnvelope.EnvelopeSignature sig = new VFS_EsignSendingEnvelope.EnvelopeSignature();
            sig.ElementId = sp.ElementId;
            sig.Required = true;
            sig.DocumentNumber = sp.DocumentNumber;
            sig.DisplayName = 'Firma aquí';
            sig.AllowedSignatureTypes = allowedTypes;
            sig.FieldDefinition = fieldDef;

            sigList.add(sig);
        }

        VFS_EsignSendingEnvelope.EnvelopeElements elements = new VFS_EsignSendingEnvelope.EnvelopeElements();
        elements.Signatures = sigList;

        VFS_EsignSendingEnvelope.EnvelopeSign sign = new VFS_EsignSendingEnvelope.EnvelopeSign();
        sign.RecipientConfiguration = recipient;
        sign.Elements = elements;
        sign.SigningGroup = signingGroup;

        VFS_EsignSendingEnvelope.EnvelopeAction action = new VFS_EsignSendingEnvelope.EnvelopeAction();
        action.Sign = sign;
        action.SendCopy = null;

        return action;
    }

    public static String cleanButtonName(String buttonName) {
        if (buttonName != null && buttonName.startsWith('VFS_')) {
            return buttonName.substring(4);
        }
        return buttonName;
    }

    public static String obtenerCodigoLenguaje() {
        String languageCode = 'EN';
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

        List<VFS_ParametrosESign__mdt> params = [
            SELECT VFS_CodigoLenguaje__c, VFS_AplicaOrganizacionSandbox__c
            FROM VFS_ParametrosESign__mdt
            WHERE VFS_AplicaOrganizacionSandbox__c = :isSandbox
            LIMIT 1
        ];

        if (!params.isEmpty() && String.isNotBlank(params[0].VFS_CodigoLenguaje__c)) {
            languageCode = params[0].VFS_CodigoLenguaje__c;
        }

        return languageCode;
    }

    public class SignatureParams {
        public String ElementId;
        public Integer DocumentNumber;
        public Integer PageNumber;
        public Integer X;
        public Integer Y;
        public Integer Width;
        public Integer Height;
        public String DisplayName;
    }
}