/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_ContratoUnicoEnvelope
 * Versión                :   1.0
 * Fecha de creación      :   16/07/2025
 * Función                :   Genera una sola acción de firma para el Contrato Único
 * Clase Test             :   VFS_ContratoUnicoEnvelopeTest
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        16/07/2025      Versión inicial 
 *********************************************************************************************/
public with sharing class VFS_ContratoUnicoEnvelope {
    
    public class VFS_ContratoUnicoEnvelopeException extends Exception {}
    
    @AuraEnabled
    public static List<VFS_EsignSendingEnvelope.EnvelopeAction> CreateSigns(String recordId) {
        System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns INICIO | recordId=' + recordId);

        try {
            if (String.isBlank(recordId)) {
                throw new VFS_ContratoUnicoEnvelopeException('El Id del registro no puede estar vacío.');
            }

            String codigoLenguaje = normalizarCodigoLenguajeParaESign(obtenerCodigoLenguaje());
            System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns | codigoLenguaje=' + codigoLenguaje);

            String email;
            String firstName;
            String lastName;
            Account acc;

            try {
                System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns | Query Account principal');
                acc = [
                    SELECT Id,
                           IsPersonAccount,
                           FirstName,
                           LastName,
                           Name,
                           PersonContactId,
                           OwnerId,
                           Owner.Email,
                           Owner.FirstName,
                           Owner.LastName,
                           ACC_Correo_Electronico_Cliente__c
                    FROM Account
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns | Account principal=' + acc);
            } catch (QueryException e) {
                System.debug(LoggingLevel.ERROR, ' ERROR VFS_ContratoUnicoEnvelope.CreateSigns | Query Account principal | ' + e.getMessage());
                throw new VFS_ContratoUnicoEnvelopeException('No se pudo acceder a la información de la cuenta. Por favor, contacte al administrador del sistema.');
            }

            if (acc == null) {
                throw new VFS_ContratoUnicoEnvelopeException('No se pudo encontrar el registro solicitado. Verifique que el Id sea válido.');
            }

            if (acc.IsPersonAccount) {
                System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns | Flujo Persona Física');

                email = obtenerCorreoPrincipal(acc);

                if (String.isBlank(acc.FirstName) || String.isBlank(acc.LastName)) {
                    throw new VFS_ContratoUnicoEnvelopeException('La cuenta no tiene el nombre completo configurado. Se requiere FirstName y LastName para procesar la firma del Contrato Único.');
                }

                firstName = acc.FirstName;
                lastName = acc.LastName;

            } else {
                System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns | Flujo Persona Jurídica');

                List<Participante__c> participantes;
                try {
                    System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns | Query Participante__c');
                    participantes = [
                        SELECT Participante__c,
                               Participante__r.Id,
                               Participante__r.FirstName,
                               Participante__r.LastName
                        FROM Participante__c 
                        WHERE PAR_Cliente__c = :recordId
                          AND VFS_FirmanteDeContratoAutorizado__c = true
                        ORDER BY PAR_Porcentaje__c DESC,
                                 Participante__r.LastName ASC,
                                 Participante__r.FirstName ASC
                        LIMIT 1
                    ];
                    System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns | participantes=' + participantes);
                } catch (QueryException e) {
                    System.debug(LoggingLevel.ERROR, ' ERROR VFS_ContratoUnicoEnvelope.CreateSigns | Query Participante__c | ' + e.getMessage());
                    throw new VFS_ContratoUnicoEnvelopeException('No se pudo acceder a los datos de los participantes. Por favor, contacte al administrador del sistema.');
                }

                if (participantes.isEmpty()) {
                    throw new VFS_ContratoUnicoEnvelopeException('No se encontraron participantes autorizados para firmar el Contrato Único. Se requiere al menos un participante con "Firmante de Contrato Autorizado" activo.');
                }

                Account accPart;
                try {
                    System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns | Query Account participante');
                    accPart = [
                        SELECT Id,
                               FirstName,
                               LastName,
                               Name,
                               PersonContactId
                        FROM Account
                        WHERE Id = :participantes[0].Participante__r.Id
                        LIMIT 1
                    ];
                    System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns | accPart=' + accPart);
                } catch (QueryException e) {
                    System.debug(LoggingLevel.ERROR, ' ERROR VFS_ContratoUnicoEnvelope.CreateSigns | Query Account participante | ' + e.getMessage());
                    throw new VFS_ContratoUnicoEnvelopeException('No se pudo acceder a los datos del participante autorizado.');
                }

                if (accPart == null) {
                    throw new VFS_ContratoUnicoEnvelopeException('No se encontraron los datos de la cuenta del participante autorizado.');
                }

                if (String.isBlank(accPart.FirstName) || String.isBlank(accPart.LastName)) {
                    throw new VFS_ContratoUnicoEnvelopeException('El participante autorizado no tiene el nombre completo configurado. Se requiere FirstName y LastName para procesar la firma del Contrato Único.');
                }

                email = obtenerCorreoPrincipal(accPart);
                firstName = accPart.FirstName;
                lastName = accPart.LastName;
            }

            System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns | email firmante=' + email + ' | firstName=' + firstName + ' | lastName=' + lastName);

            if (acc.Owner == null || String.isBlank(acc.Owner.Email) || String.isBlank(acc.Owner.FirstName) || String.isBlank(acc.Owner.LastName)) {
                throw new VFS_ContratoUnicoEnvelopeException('El propietario (Owner) de la cuenta no tiene los datos completos. Se requiere correo electrónico y nombre completo para enviar copias del contrato.');
            }

            VFS_FirmarDocumentoUtility.SignatureParams sig = new VFS_FirmarDocumentoUtility.SignatureParams();
            sig.ElementId = 'sig_contrato_unico';
            sig.DocumentNumber = 1;
            sig.PageNumber = 29;
            sig.X = 341;
            sig.Y = 240;
            sig.Width = 120;
            sig.Height = 40;

            List<VFS_FirmarDocumentoUtility.SignatureParams> firmas = new List<VFS_FirmarDocumentoUtility.SignatureParams>{ sig };
            List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = new List<VFS_EsignSendingEnvelope.EnvelopeAction>();

            System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns | Construyendo acción de firma');
            actions.add(VFS_FirmarDocumentoUtility.buildSignAction(email, firstName, lastName, 'firmante', firmas));

            System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns | Construyendo copia para firmante');
            actions.add(createSendCopyAction(email, firstName, lastName, codigoLenguaje));

            if (acc.OwnerId != null && acc.Owner.Email != null) {
                System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns | Construyendo copia para Owner');
                actions.add(createSendCopyAction(acc.Owner.Email, acc.Owner.FirstName, acc.Owner.LastName, codigoLenguaje));
            }

            System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns | actions.size=' + actions.size());

            if (actions.isEmpty()) {
                throw new VFS_ContratoUnicoEnvelopeException('No se pudieron generar las acciones de firma. Verifique que todos los datos requeridos estén completos.');
            }

            System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.CreateSigns FIN OK');
            return actions;
                
        } catch (VFS_ContratoUnicoEnvelopeException e) {
            String errorMessage = e.getMessage();
            System.debug(LoggingLevel.ERROR, ' ERROR CONTROLADO VFS_ContratoUnicoEnvelope.CreateSigns | ' + errorMessage);
            Exception auraEx = new CalloutException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, ' ERROR NO CONTROLADO VFS_ContratoUnicoEnvelope.CreateSigns | message=' + e.getMessage() + ' | stack=' + e.getStackTraceString());
            String errorMessage = 'Error inesperado al procesar la solicitud de firma del Contrato Único. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new CalloutException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
    }

    private static String obtenerCorreoPrincipal(Account acc) {
        System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.obtenerCorreoPrincipal INICIO | accountId=' + (acc != null ? acc.Id : null));

        if (acc == null) {
            throw new VFS_ContratoUnicoEnvelopeException('No se puede obtener el correo electrónico de una cuenta vacía.');
        }

        Set<Id> parentIds = new Set<Id>();
        parentIds.add(acc.Id);

        if (acc.PersonContactId != null) {
            parentIds.add(acc.PersonContactId);
        }

        System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.obtenerCorreoPrincipal | parentIds=' + parentIds);

        List<ContactPointEmail> correos = [
            SELECT Id,
                   ParentId,
                   EmailAddress,
                   IsPrimary,
                   CreatedDate
            FROM ContactPointEmail
            WHERE ParentId IN :parentIds
              AND EmailAddress != null
            ORDER BY IsPrimary DESC, CreatedDate ASC
        ];

        System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.obtenerCorreoPrincipal | correos=' + correos);

        for (ContactPointEmail cpe : correos) {
            if (cpe.IsPrimary && String.isNotBlank(cpe.EmailAddress)) {
                System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.obtenerCorreoPrincipal | correo primario=' + cpe.EmailAddress);
                return cpe.EmailAddress;
            }
        }

        for (ContactPointEmail cpe : correos) {
            if (String.isNotBlank(cpe.EmailAddress)) {
                System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.obtenerCorreoPrincipal | correo alternativo=' + cpe.EmailAddress);
                return cpe.EmailAddress;
            }
        }

        throw new VFS_ContratoUnicoEnvelopeException(
            'No se encontró una dirección de correo electrónico válida para la cuenta. Se requiere al menos un correo electrónico para procesar la firma del Contrato Único.'
        );
    }

    private static VFS_EsignSendingEnvelope.EnvelopeAction createSendCopyAction(
        String email,
        String firstName,
        String lastName,
        String codigoLenguaje
    ) {
        System.debug(LoggingLevel.INFO,
            ' VFS_ContratoUnicoEnvelope.createSendCopyAction INICIO | email=' + email +
            ' | firstName=' + firstName +
            ' | lastName=' + lastName +
            ' | codigoLenguaje=' + codigoLenguaje
        );

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

        System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.createSendCopyAction FIN OK | email=' + email);
        return sendCopy;
    }

    private static String normalizarCodigoLenguajeParaESign(String codigoLenguaje) {
        System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.normalizarCodigoLenguajeParaESign INICIO | codigoLenguaje=' + codigoLenguaje);

        if (String.isBlank(codigoLenguaje) || codigoLenguaje == 'es_DO' || codigoLenguaje == 'ES_DO') {
            return 'en';
        }

        return codigoLenguaje;
    }

    /*
     * Devuelve el código de lenguaje para el envío de copias de documentos a firmar
     * que aplica para el ambiente en el que se ejecuta el código, sea Sandbox o Producción.
    */
    public static String obtenerCodigoLenguaje() {
        System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.obtenerCodigoLenguaje INICIO');

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

        System.debug(LoggingLevel.INFO, ' VFS_ContratoUnicoEnvelope.obtenerCodigoLenguaje FIN | languageCode=' + languageCode);
        return languageCode;
    }
}