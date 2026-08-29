public with sharing class VFS_nKYCEnvelope {

    public class VFS_KYCEnvelopeException extends Exception {}

    @AuraEnabled
    public static List<VFS_EsignSendingEnvelope.EnvelopeAction> CreateSigns(String recordId) {
        System.debug(LoggingLevel.INFO, 'VFS_nKYCEnvelope.CreateSigns INICIO | recordId=' + recordId);

        try {
            if (String.isBlank(recordId)) {
                throw new VFS_KYCEnvelopeException('El Id del registro no puede estar vacío.');
            }

            System.debug(LoggingLevel.INFO, 'VFS_nKYCEnvelope.CreateSigns | Query Account base');
            Account acc;
            try {
                acc = [
                    SELECT Id, IsPersonAccount, PersonContactId
                    FROM Account
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.CreateSigns | Account encontrado=' + acc);
            } catch (QueryException e) {
                System.debug(LoggingLevel.ERROR, ' ERROR en VFS_nKYCEnvelope.CreateSigns | QueryException=' + e.getMessage());
                throw new VFS_KYCEnvelopeException('No se pudo encontrar el registro solicitado. Verifique que el Id sea válido.');
            }

            List<VFS_EsignSendingEnvelope.EnvelopeAction> result = new List<VFS_EsignSendingEnvelope.EnvelopeAction>();

            if (acc.IsPersonAccount) {
                System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.CreateSigns | Flujo Persona Física');
                result = createSignsFisica(recordId);
            } else {
                System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.CreateSigns | Flujo Persona Jurídica');
                result = createSignsJuridica(recordId);
            }

            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.CreateSigns | result.size=' + (result == null ? 0 : result.size()));

            if (result == null || result.isEmpty()) {
                throw new VFS_KYCEnvelopeException('No se pudieron generar las acciones de firma. Verifique que todos los datos requeridos estén completos.');
            }

            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.CreateSigns FIN OK | recordId=' + recordId);
            return result;

        } catch (VFS_KYCEnvelopeException e) {
            System.debug(LoggingLevel.ERROR, ' ERROR CONTROLADO en VFS_nKYCEnvelope.CreateSigns | ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, ' ERROR NO CONTROLADO en VFS_nKYCEnvelope.CreateSigns | message=' + e.getMessage() + ' | stack=' + e.getStackTraceString());
            throw new AuraHandledException('Error inesperado al procesar la solicitud de firma KYC. Por favor, contacte al administrador del sistema.');
        }
    }

    private static List<VFS_EsignSendingEnvelope.EnvelopeAction> createSignsFisica(String recordId) {
        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsFisica INICIO | recordId=' + recordId);

        try {
            String languageCode = obtenerCodigoLenguaje();
            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsFisica | languageCode=' + languageCode);

            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsFisica | Query Account principal');
            Account acc = [
                SELECT Id,
                       Name,
                       FirstName,
                       LastName,
                       IsPersonAccount,
                       PersonContactId,
                       ACC_Correo_Electronico_Cliente__c,
                       LastModifiedBy.Name,
                       LastModifiedBy.Email,
                       LastModifiedBy.FirstName,
                       LastModifiedBy.LastName,
                       Owner.Email,
                       Owner.FirstName,
                       Owner.LastName,
                       CreatedBy.Email,
                       CreatedBy.FirstName,
                       CreatedBy.LastName
                FROM Account
                WHERE Id = :recordId
                LIMIT 1
            ];
            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsFisica | Account=' + acc);

            String correoElectronico = obtenerCorreoPrincipal(acc);
            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsFisica | correoElectronico=' + correoElectronico);

            validarEmailRequerido(acc.LastModifiedBy.Email, 'Último Modificador');
            validarEmailRequerido(acc.Owner.Email, 'Owner');

            Integer pageAccount = 4;
            Integer pageOthers = 5;
            List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = new List<VFS_EsignSendingEnvelope.EnvelopeAction>();

            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsFisica | Construyendo acciones');

            actions.add(createSignAction(correoElectronico, acc.FirstName, acc.LastName, 'firstSigner', pageAccount, 245, 355, 130, 80));
            actions.add(createSignAction(acc.LastModifiedBy.Email, acc.LastModifiedBy.FirstName, acc.LastModifiedBy.LastName, 'secondSigner', pageOthers, 355, 659, 120, 89));
            actions.add(createSignAction(acc.Owner.Email, acc.Owner.FirstName, acc.Owner.LastName, 'thirdSigner', pageOthers, 355, 480, 120, 90));

            actions.add(createSendCopyAction(correoElectronico, acc.FirstName, acc.LastName, languageCode));
            actions.add(createSendCopyAction(acc.LastModifiedBy.Email, acc.LastModifiedBy.FirstName, acc.LastModifiedBy.LastName, languageCode));
            actions.add(createSendCopyAction(acc.Owner.Email, acc.Owner.FirstName, acc.Owner.LastName, languageCode));

            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsFisica FIN OK | total actions=' + actions.size());
            return actions;

        } catch (VFS_KYCEnvelopeException e) {
            System.debug(LoggingLevel.ERROR, ' ERROR CONTROLADO en VFS_nKYCEnvelope.createSignsFisica | ' + e.getMessage());
            throw e;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, ' ERROR NO CONTROLADO en VFS_nKYCEnvelope.createSignsFisica | message=' + e.getMessage() + ' | stack=' + e.getStackTraceString());
            throw new VFS_KYCEnvelopeException('Error al generar las firmas para persona física en el proceso KYC: ' + e.getMessage());
        }
    }

    private static List<VFS_EsignSendingEnvelope.EnvelopeAction> createSignsJuridica(String recordId) {
        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsJuridica INICIO | recordId=' + recordId);

        try {
            String languageCode = obtenerCodigoLenguaje();
            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsJuridica | languageCode=' + languageCode);

            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsJuridica | Query AccountAccountRelation');
            List<AccountAccountRelation> accionistas = [
                SELECT Id,
                       AccountId,
                       RelatedAccountId,
                       AAR_FirmanteConozcaCliente__c,
                       AAR_Porcentaje__c
                FROM AccountAccountRelation
                WHERE AccountId = :recordId
                  AND AAR_FirmanteConozcaCliente__c = TRUE
                ORDER BY AAR_Porcentaje__c DESC
                LIMIT 2
            ];
            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsJuridica | accionistas=' + accionistas);

            if (accionistas.isEmpty()) {
                throw new VFS_KYCEnvelopeException('No se encontraron firmantes autorizados para la cuenta de persona jurídica en el proceso KYC. Se requiere al menos un firmante autorizado para procesar la solicitud de firma.');
            }

            Set<Id> accountIds = new Set<Id>();
            for (AccountAccountRelation rel : accionistas) {
                if (rel.RelatedAccountId != null) {
                    accountIds.add(rel.RelatedAccountId);
                }
            }
            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsJuridica | accountIds=' + accountIds);

            if (accountIds.isEmpty()) {
                throw new VFS_KYCEnvelopeException('Las relaciones de firmantes no tienen cuentas relacionadas para el proceso KYC.');
            }

            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsJuridica | Query Accounts relacionados');
            Map<Id, Account> accountMap = new Map<Id, Account>([
                SELECT Id,
                       Name,
                       FirstName,
                       LastName,
                       IsPersonAccount,
                       PersonContactId
                FROM Account
                WHERE Id IN :accountIds
            ]);
            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsJuridica | accountMap=' + accountMap);

            Map<Id, String> correosPorCuenta = obtenerCorreosPrincipalesPorCuentas(accountMap);
            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsJuridica | correosPorCuenta=' + correosPorCuenta);

            List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = new List<VFS_EsignSendingEnvelope.EnvelopeAction>();
            List<VFS_EsignSendingEnvelope.EnvelopeAction> copyActions = new List<VFS_EsignSendingEnvelope.EnvelopeAction>();

            for (Integer idx = 0; idx < accionistas.size(); idx++) {
                Integer posX;
                Integer posY;

                AccountAccountRelation rel = accionistas[idx];
                System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsJuridica | Procesando idx=' + idx + ' | rel=' + rel);

                if (rel.RelatedAccountId == null) {
                    throw new VFS_KYCEnvelopeException('La relación de firmante no tiene cuenta relacionada. RelationId=' + rel.Id);
                }

                Account acc = accountMap.get(rel.RelatedAccountId);
                if (acc == null) {
                    throw new VFS_KYCEnvelopeException('No se encontró la cuenta relacionada del firmante con Id: ' + rel.RelatedAccountId);
                }

                String correoElectronico = correosPorCuenta.get(acc.Id);
                if (String.isBlank(correoElectronico)) {
                    throw new VFS_KYCEnvelopeException('No se encontró un ContactPointEmail válido para el firmante relacionado: ' + acc.Id + ' (' + acc.Name + ').');
                }

                System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsJuridica | correo firmante=' + correoElectronico);

                if (idx == 0) {
                    posX = 260;
                    posY = 425;
                } else {
                    posX = 260;
                    posY = 475;
                }

                String signerFirstName = String.isNotBlank(acc.FirstName) ? acc.FirstName : acc.Name;
                String signerLastName = String.isNotBlank(acc.LastName) ? acc.LastName : '';

                actions.add(createSignAction(
                    correoElectronico,
                    signerFirstName,
                    signerLastName,
                    'accionista_' + idx,
                    7,
                    posX,
                    posY,
                    120,
                    40
                ));

                copyActions.add(createSendCopyAction(
                    correoElectronico,
                    signerFirstName,
                    signerLastName,
                    languageCode
                ));
            }

            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsJuridica | Query Account principal');
            Account accMain = [
                SELECT Id,
                       Name,
                       Owner.Email,
                       Owner.FirstName,
                       Owner.LastName,
                       LastModifiedBy.Name,
                       LastModifiedBy.Email,
                       LastModifiedBy.FirstName,
                       LastModifiedBy.LastName,
                       CreatedBy.Email,
                       CreatedBy.FirstName,
                       CreatedBy.LastName
                FROM Account
                WHERE Id = :recordId
                LIMIT 1
            ];
            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsJuridica | accMain=' + accMain);

            validarEmailRequerido(accMain.LastModifiedBy.Email, 'Ejecutivo Responsable');
            validarEmailRequerido(accMain.Owner.Email, 'Verificador');

            actions.add(createSignAction(accMain.LastModifiedBy.Email, accMain.LastModifiedBy.FirstName, accMain.LastModifiedBy.LastName, 'Ejecutivo Responsable', 8, 357, 650, 120, 89));
            actions.add(createSignAction(accMain.Owner.Email, accMain.Owner.FirstName, accMain.Owner.LastName, 'Verificador', 8, 357, 470, 120, 90));

            actions.addAll(copyActions);
            actions.add(createSendCopyAction(accMain.Owner.Email, accMain.Owner.FirstName, accMain.Owner.LastName, languageCode));
            actions.add(createSendCopyAction(accMain.LastModifiedBy.Email, accMain.LastModifiedBy.FirstName, accMain.LastModifiedBy.LastName, languageCode));

            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignsJuridica FIN OK | total actions=' + actions.size());
            return actions;

        } catch (VFS_KYCEnvelopeException e) {
            System.debug(LoggingLevel.ERROR, ' ERROR CONTROLADO en VFS_nKYCEnvelope.createSignsJuridica | ' + e.getMessage());
            throw e;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, ' ERROR NO CONTROLADO en VFS_nKYCEnvelope.createSignsJuridica | message=' + e.getMessage() + ' | stack=' + e.getStackTraceString());
            throw new VFS_KYCEnvelopeException('Error al generar las firmas para persona jurídica en el proceso KYC: ' + e.getMessage());
        }
    }

    /*
     * Devuelve el código de lenguaje para el envío de copias de documentos a firmar
     * que aplica para el ambiente en el que se ejecuta el código, sea Sandbox o Producción.
     * Se deja sin forzar fallback para no alterar el comportamiento original.
    */
    public static String obtenerCodigoLenguaje() {
        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCodigoLenguaje INICIO');

        String languageCode = 'EN';

        try {
            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCodigoLenguaje | Query Organization');
            Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCodigoLenguaje | isSandbox=' + isSandbox);

            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCodigoLenguaje | Query VFS_ParametrosESign__mdt');
            List<VFS_ParametrosESign__mdt> params = [
                SELECT VFS_CodigoLenguaje__c, VFS_AplicaOrganizacionSandbox__c
                FROM VFS_ParametrosESign__mdt
                WHERE VFS_AplicaOrganizacionSandbox__c = :isSandbox
                LIMIT 1
            ];
            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCodigoLenguaje | params=' + params);

            if (!params.isEmpty() && String.isNotBlank(params[0].VFS_CodigoLenguaje__c)) {
                languageCode = params[0].VFS_CodigoLenguaje__c.trim();
            }

            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCodigoLenguaje FIN OK | languageCode=' + languageCode);
            return languageCode;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, ' ERROR en VFS_nKYCEnvelope.obtenerCodigoLenguaje | message=' + e.getMessage() + ' | stack=' + e.getStackTraceString());
            return languageCode;
        }
    }

    private static VFS_EsignSendingEnvelope.EnvelopeAction createSignAction(
        String email,
        String firstName,
        String lastName,
        String role,
        Integer page,
        Integer x,
        Integer y,
        Integer width,
        Integer height
    ) {
        System.debug(
            LoggingLevel.INFO,
            ' VFS_nKYCEnvelope.createSignAction INICIO | email=' + email +
            ' | firstName=' + firstName +
            ' | lastName=' + lastName +
            ' | role=' + role +
            ' | page=' + page
        );

        List<VFS_FirmarDocumentoUtility.SignatureParams> firmas = new List<VFS_FirmarDocumentoUtility.SignatureParams>();
        VFS_FirmarDocumentoUtility.SignatureParams sig = new VFS_FirmarDocumentoUtility.SignatureParams();
        sig.ElementId = 'sig_' + role;
        sig.DocumentNumber = 1;
        sig.PageNumber = page;
        sig.X = x;
        sig.Y = y;
        sig.Width = width;
        sig.Height = height;
        firmas.add(sig);

        VFS_EsignSendingEnvelope.EnvelopeAction action =
            VFS_FirmarDocumentoUtility.buildSignAction(email, firstName, lastName, role, firmas);

        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSignAction | action=' + JSON.serialize(action));
        return action;
    }

    private static VFS_EsignSendingEnvelope.EnvelopeAction createSendCopyAction(
        String email,
        String firstName,
        String lastName,
        String languageCode
    ) {
        System.debug(
            LoggingLevel.INFO,
            ' VFS_nKYCEnvelope.createSendCopyAction INICIO | email=' + email +
            ' | firstName=' + firstName +
            ' | lastName=' + lastName +
            ' | languageCode original=' + languageCode
        );

        if (String.isBlank(languageCode) || languageCode == 'es_DO' || languageCode == 'ES_DO') {
            languageCode = 'en';
        }

        System.debug(
            LoggingLevel.INFO,
            ' VFS_nKYCEnvelope.createSendCopyAction | languageCode final=' + languageCode
        );

        VFS_EsignSendingEnvelope.EnvelopeAction sendCopy = new VFS_EsignSendingEnvelope.EnvelopeAction();
        sendCopy.Sign = null;

        VFS_EsignSendingEnvelope.EnvelopeSendCopy sendCopyObj = new VFS_EsignSendingEnvelope.EnvelopeSendCopy();
        VFS_EsignSendingEnvelope.EnvelopeRecipientConfiguration recConf = new VFS_EsignSendingEnvelope.EnvelopeRecipientConfiguration();
        VFS_EsignSendingEnvelope.EnvelopeContactInformation contact = new VFS_EsignSendingEnvelope.EnvelopeContactInformation();

        contact.Email = email;
        contact.GivenName = firstName;
        contact.Surname = lastName;
        contact.LanguageCode = languageCode;

        recConf.ContactInformation = contact;
        sendCopyObj.RecipientConfiguration = recConf;
        sendCopy.SendCopy = sendCopyObj;

        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.createSendCopyAction FIN OK | email=' + email);
        return sendCopy;
    }

    private static void validarEmailRequerido(String email, String actor) {
        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.validarEmailRequerido INICIO | actor=' + actor + ' | email=' + email);

        if (String.isBlank(email)) {
            throw new VFS_KYCEnvelopeException('El usuario configurado como "' + actor + '" no tiene correo electrónico. Por favor, complete ese dato antes de continuar con la firma KYC.');
        }

        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.validarEmailRequerido FIN OK | actor=' + actor);
    }

    private static String obtenerCorreoPrincipal(Account account) {
        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCorreoPrincipal INICIO | accountId=' + (account != null ? account.Id : null));

        if (account == null) {
            throw new VFS_KYCEnvelopeException('No se puede obtener el correo de una cuenta vacía.');
        }

        Map<Id, Account> accountMap = new Map<Id, Account>();
        accountMap.put(account.Id, account);

        Map<Id, String> correos = obtenerCorreosPrincipalesPorCuentas(accountMap);
        String correo = correos.get(account.Id);

        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCorreoPrincipal | correo=' + correo + ' | accountId=' + account.Id);

        if (String.isBlank(correo)) {
            throw new VFS_KYCEnvelopeException(
                'No se encontró una dirección de correo electrónico válida en ContactPointEmail para la cuenta: ' +
                account.Id + ' (' + account.Name + ') en el proceso KYC.'
            );
        }

        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCorreoPrincipal FIN OK | accountId=' + account.Id);
        return correo;
    }

    private static Map<Id, String> obtenerCorreosPrincipalesPorCuentas(Map<Id, Account> accountMap) {
        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCorreosPrincipalesPorCuentas INICIO | size=' + (accountMap == null ? 0 : accountMap.size()));

        Map<Id, String> result = new Map<Id, String>();

        if (accountMap == null || accountMap.isEmpty()) {
            System.debug(LoggingLevel.WARN, ' VFS_nKYCEnvelope.obtenerCorreosPrincipalesPorCuentas | accountMap vacío');
            return result;
        }

        Map<Id, Set<Id>> accountToParentIds = new Map<Id, Set<Id>>();
        Set<Id> allParentIds = new Set<Id>();

        for (Account acc : accountMap.values()) {
            Set<Id> parentIds = new Set<Id>();
            parentIds.add(acc.Id);

            if (acc.PersonContactId != null) {
                parentIds.add(acc.PersonContactId);
            }

            accountToParentIds.put(acc.Id, parentIds);
            allParentIds.addAll(parentIds);
        }

        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCorreosPrincipalesPorCuentas | accountToParentIds=' + accountToParentIds);
        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCorreosPrincipalesPorCuentas | allParentIds=' + allParentIds);

        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCorreosPrincipalesPorCuentas | Query ContactPointEmail');
        List<ContactPointEmail> cpeList = [
            SELECT Id,
                   ParentId,
                   EmailAddress,
                   IsPrimary,
                   CreatedDate
            FROM ContactPointEmail
            WHERE ParentId IN :allParentIds
              AND EmailAddress != null
            ORDER BY IsPrimary DESC, CreatedDate ASC
        ];
        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCorreosPrincipalesPorCuentas | cpeList.size=' + cpeList.size());

        Map<Id, List<ContactPointEmail>> cpeByParentId = new Map<Id, List<ContactPointEmail>>();
        for (ContactPointEmail cpe : cpeList) {
            if (!cpeByParentId.containsKey(cpe.ParentId)) {
                cpeByParentId.put(cpe.ParentId, new List<ContactPointEmail>());
            }
            cpeByParentId.get(cpe.ParentId).add(cpe);
        }

        for (Id accountId : accountToParentIds.keySet()) {
            Account acc = accountMap.get(accountId);
            List<ContactPointEmail> candidateEmails = new List<ContactPointEmail>();

            for (Id parentId : accountToParentIds.get(accountId)) {
                if (cpeByParentId.containsKey(parentId)) {
                    candidateEmails.addAll(cpeByParentId.get(parentId));
                }
            }

            System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCorreosPrincipalesPorCuentas | accountId=' + accountId + ' | candidateEmails=' + candidateEmails);

            String correoSeleccionado = seleccionarCorreo(candidateEmails, acc);
            if (String.isNotBlank(correoSeleccionado)) {
                result.put(accountId, correoSeleccionado);
            }
        }

        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.obtenerCorreosPrincipalesPorCuentas FIN OK | result=' + result);
        return result;
    }

    private static String seleccionarCorreo(List<ContactPointEmail> candidateEmails, Account acc) {
        System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.seleccionarCorreo INICIO | accountId=' + (acc != null ? acc.Id : null));

        if (candidateEmails == null || candidateEmails.isEmpty()) {
            System.debug(LoggingLevel.WARN, ' VFS_nKYCEnvelope.seleccionarCorreo | Sin candidateEmails');
            return null;
        }

        for (ContactPointEmail cpe : candidateEmails) {
            if (cpe.IsPrimary && String.isNotBlank(cpe.EmailAddress)) {
                System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.seleccionarCorreo | correo primario=' + cpe.EmailAddress + ' | parentId=' + cpe.ParentId);
                return cpe.EmailAddress;
            }
        }

        for (ContactPointEmail cpeAlt : candidateEmails) {
            if (String.isNotBlank(cpeAlt.EmailAddress)) {
                System.debug(LoggingLevel.INFO, ' VFS_nKYCEnvelope.seleccionarCorreo | correo alternativo=' + cpeAlt.EmailAddress + ' | parentId=' + cpeAlt.ParentId);
                return cpeAlt.EmailAddress;
            }
        }

        System.debug(LoggingLevel.WARN, ' VFS_nKYCEnvelope.seleccionarCorreo | No se pudo seleccionar correo');
        return null;
    }
}