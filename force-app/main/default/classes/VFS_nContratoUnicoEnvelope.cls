public with sharing class VFS_nContratoUnicoEnvelope {

    public class VFS_ContratoUnicoEnvelopeException extends Exception {}

    @AuraEnabled
    public static List<VFS_EsignSendingEnvelope.EnvelopeAction> CreateSigns(String recordId) {
        try {
            if (String.isBlank(recordId)) {
                throw new VFS_ContratoUnicoEnvelopeException('El Id del registro no puede estar vacío.');
            }

            String codigoLenguaje = obtenerCodigoLenguaje();
            String email, firstName, lastName;

            Account acc;
            try {
                // Se elimina subquery de Vias_de_Contacto__r (modelo viejo)
                acc = [
                    SELECT Id, IsPersonAccount, FirstName, LastName, OwnerId,
                           Owner.Email, Owner.FirstName, Owner.LastName,
                           ACC_Correo_Electronico_Cliente__c
                    FROM Account
                    WHERE Id = :recordId
                    LIMIT 1
                ];
            } catch (QueryException e) {
                throw new VFS_ContratoUnicoEnvelopeException('No se pudo acceder a la información de la cuenta. Por favor, contacte al administrador del sistema.');
            }

            if (acc == null) {
                throw new VFS_ContratoUnicoEnvelopeException('No se pudo encontrar el registro solicitado. Verifique que el Id sea válido.');
            }

            if (acc.IsPersonAccount) {
                // PERSONA FÍSICA: correo desde ContactPointEmail (modelo nuevo)
                ContactPointEmail cpe = obtenerEmailPrincipal(recordId);
                if (cpe == null || String.isBlank(cpe.EmailAddress)) {
                    throw new VFS_ContratoUnicoEnvelopeException('No se encontró una dirección de correo electrónico válida para la cuenta. Por favor, configure un Contact Point Email.');
                }

                if (String.isBlank(acc.FirstName) || String.isBlank(acc.LastName)) {
                    throw new VFS_ContratoUnicoEnvelopeException('La cuenta no tiene el nombre completo configurado. Se requiere FirstName y LastName para procesar la firma del Contrato Único.');
                }

                email = cpe.EmailAddress;
                firstName = acc.FirstName;
                lastName = acc.LastName;

            } else {
                // PERSONA JURÍDICA: firmante autorizado desde AccountAccountRelation (AAR)
                AccountAccountRelation aar;
                try {
                    aar = [
                        SELECT Id, AccountId, RelatedAccountId, AAR_Porcentaje__c,
                               RelatedAccount.FirstName, RelatedAccount.LastName
                        FROM AccountAccountRelation
                        WHERE AccountId = :recordId
                          AND AAR_FirmanteDeContratoAutorizado__c = true
                        ORDER BY AAR_Porcentaje__c DESC, RelatedAccount.LastName ASC, RelatedAccount.FirstName ASC
                        LIMIT 1
                    ];
                } catch (QueryException e) {
                    throw new VFS_ContratoUnicoEnvelopeException('No se pudo acceder a los datos de los firmantes autorizados. Por favor, contacte al administrador del sistema.');
                }

                if (aar == null || aar.RelatedAccountId == null) {
                    throw new VFS_ContratoUnicoEnvelopeException('No se encontraron firmantes autorizados para firmar el Contrato Único. Se requiere al menos un relacionado con "Firmante de Contrato Autorizado" activo.');
                }

                // Datos del firmante (RelatedAccount)
                if (String.isBlank(aar.RelatedAccount.FirstName) || String.isBlank(aar.RelatedAccount.LastName)) {
                    throw new VFS_ContratoUnicoEnvelopeException('El firmante autorizado no tiene el nombre completo configurado. Se requiere FirstName y LastName para procesar la firma del Contrato Único.');
                }

                // Email del firmante desde ContactPointEmail del RelatedAccount
                ContactPointEmail cpeFirmante = obtenerEmailPrincipal(aar.RelatedAccountId);
                if (cpeFirmante == null || String.isBlank(cpeFirmante.EmailAddress)) {
                    throw new VFS_ContratoUnicoEnvelopeException(
                        'No se encontró una dirección de correo electrónico válida para el firmante autorizado: ' +
                        aar.RelatedAccount.FirstName + ' ' + aar.RelatedAccount.LastName +
                        '. Por favor, configure un Contact Point Email.'
                    );
                }

                email = cpeFirmante.EmailAddress;
                firstName = aar.RelatedAccount.FirstName;
                lastName = aar.RelatedAccount.LastName;
            }

            // Validar datos del Owner para las copias
            if (acc.Owner == null || String.isBlank(acc.Owner.Email) || String.isBlank(acc.Owner.FirstName) || String.isBlank(acc.Owner.LastName)) {
                throw new VFS_ContratoUnicoEnvelopeException('El propietario (Owner) de la cuenta no tiene los datos completos. Se requiere correo electrónico y nombre completo para enviar copias del contrato.');
            }

            // Parámetros de la firma
            VFS_FirmarDocumentoUtility.SignatureParams sig = new VFS_FirmarDocumentoUtility.SignatureParams();
            sig.ElementId = 'sig_contrato_unico';
            sig.DocumentNumber = 1;
            sig.PageNumber = 29;
            sig.X = 341;
            sig.Y = 240;  // Mantener la Y modificada = 240
            sig.Width = 120;
            sig.Height = 40;

            // Acción de firma
            List<VFS_FirmarDocumentoUtility.SignatureParams> firmas = new List<VFS_FirmarDocumentoUtility.SignatureParams>{ sig };
            List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = new List<VFS_EsignSendingEnvelope.EnvelopeAction>();
            actions.add(VFS_FirmarDocumentoUtility.buildSignAction(email, firstName, lastName, 'firmante', firmas));

            // Acción de copia al firmante
            actions.add(createSendCopyAction(email, firstName, lastName, codigoLenguaje));

            // Acción de copia al Owner del Account
            actions.add(createSendCopyAction(acc.Owner.Email, acc.Owner.FirstName, acc.Owner.LastName, codigoLenguaje));

            if (actions.isEmpty()) {
                throw new VFS_ContratoUnicoEnvelopeException('No se pudieron generar las acciones de firma. Verifique que todos los datos requeridos estén completos.');
            }

            return actions;

        } catch (VFS_ContratoUnicoEnvelopeException e) {
            // Para LWC/Aura usar AuraHandledException para mostrar el mensaje exacto
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            // Mensaje genérico controlado para el front.
            throw new AuraHandledException('Error inesperado al procesar la solicitud de firma del Contrato Único. Por favor, contacte al administrador del sistema.');
        }
    }

    // Obtiene el ContactPointEmail principal (o el más reciente) para el Account indicado
    private static ContactPointEmail obtenerEmailPrincipal(Id accountId) {
        if (accountId == null) return null;

        List<ContactPointEmail> emails = [
            SELECT Id, ParentId, EmailAddress, IsPrimary, CreatedDate
            FROM ContactPointEmail
            WHERE ParentId = :accountId
              AND EmailAddress != null
            ORDER BY IsPrimary DESC, CreatedDate DESC
            LIMIT 1
        ];
        return emails.isEmpty() ? null : emails[0];
    }

    // Utilidad para crear acción de envío de copia del documento firmado
    private static VFS_EsignSendingEnvelope.EnvelopeAction createSendCopyAction(String email, String firstName, String lastName, String codigoLenguaje) {
        VFS_EsignSendingEnvelope.EnvelopeAction sendCopy = new VFS_EsignSendingEnvelope.EnvelopeAction();
        sendCopy.Sign = null;

        VFS_EsignSendingEnvelope.EnvelopeSendCopy sendCopyObj = new VFS_EsignSendingEnvelope.EnvelopeSendCopy();
        VFS_EsignSendingEnvelope.EnvelopeRecipientConfiguration recConf = new VFS_EsignSendingEnvelope.EnvelopeRecipientConfiguration();
        VFS_EsignSendingEnvelope.EnvelopeContactInformation contact = new VFS_EsignSendingEnvelope.EnvelopeContactInformation();

        contact.Email = email;
        contact.GivenName = firstName;
        contact.Surname = lastName;
        contact.LanguageCode = codigoLenguaje;

        recConf.ContactInformation = contact;
        sendCopyObj.RecipientConfiguration = recConf;
        sendCopy.SendCopy = sendCopyObj;

        return sendCopy;
    }

    /*
     * Devuelve el código de lenguaje para el envío de copias de documentos a firmar
     * que aplica para el ambiente en el que se ejecuta el código, sea Sandbox o Producción.
     */
    public static String obtenerCodigoLenguaje() {
        String languageCode = 'EN'; // default
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
}