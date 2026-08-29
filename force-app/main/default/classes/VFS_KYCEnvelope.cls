/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_KYCEnvelope
 * Versión                :   1.0
 * Fecha de creación      :   20/06/2025
 * Función                :   Genera las acciones de firma y envío de copia para el proceso KYC 
 * Clase Test             :   VFS_KYCEnvelopeTest
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        20/06/2025      Versión inicial
 *********************************************************************************************/
public with sharing class VFS_KYCEnvelope {
    
    public class VFS_KYCEnvelopeException extends Exception {}
    
    @AuraEnabled
    public static List<VFS_EsignSendingEnvelope.EnvelopeAction> CreateSigns(String recordId) {
        try {
            if (String.isBlank(recordId)) {
                throw new VFS_KYCEnvelopeException('El Id del registro no puede estar vacío.');
            }
            
            Account acc;
            try {
                acc = [SELECT Id, IsPersonAccount FROM Account WHERE Id = :recordId LIMIT 1];
            } catch (QueryException e) {
                throw new VFS_KYCEnvelopeException('No se pudo encontrar el registro solicitado. Verifique que el Id sea válido.');
            }
            
            List<VFS_EsignSendingEnvelope.EnvelopeAction> result;
            
            if (acc.IsPersonAccount) {
                result = createSignsFisica(recordId);
            } else {
                result = createSignsJuridica(recordId);
            }
            
            if (result.isEmpty()) {
                throw new VFS_KYCEnvelopeException('No se pudieron generar las acciones de firma. Verifique que todos los datos requeridos estén completos.');
            }
            
            return result;
                
        } catch (VFS_KYCEnvelopeException e) {
            // Convertir excepción personalizada a AuraHandledException para LWC
            String errorMessage = e.getMessage();
            Exception auraEx = new CalloutException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (Exception e) {
            // Manejar cualquier otra excepción inesperada
            String errorMessage = 'Error inesperado al procesar la solicitud de firma KYC. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new CalloutException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
    }

    // Método para persona física: genera acciones de firma y envío de copia para el proceso KYC persona física
    private static List<VFS_EsignSendingEnvelope.EnvelopeAction> createSignsFisica(String recordId) {
        try {
            String languageCode = obtenerCodigoLenguaje();
            // Consulta los datos principales del Account y sus relaciones necesarias
            Account acc = [SELECT Id, FirstName, LastName, LastModifiedBy.Name, LastModifiedBy.Email, LastModifiedBy.FirstName, LastModifiedBy.LastName, Owner.Email, Owner.FirstName, Owner.LastName, ACC_Correo_Electronico_Cliente__c, CreatedBy.Email, CreatedBy.FirstName, CreatedBy.LastName, (SELECT VIA_Numero_Correo__c, VIA_de_Contacto__c, VIA_Principal__c, CreatedDate FROM Vias_de_Contacto__r) FROM Account WHERE Id = :recordId LIMIT 1];
            
            // Obtener el correo electrónico correcto desde las vías de contacto
            String correoElectronico = '';
            Boolean correoPrincipal = false;
            
            if (acc.Vias_de_Contacto__r == null || acc.Vias_de_Contacto__r.isEmpty()) {
                throw new VFS_KYCEnvelopeException('La cuenta no tiene vías de contacto configuradas. Es necesario configurar al menos una dirección de correo electrónico para proceder con el proceso KYC.');
            }
            
            for (Vias_de_Contacto__c via : acc.Vias_de_Contacto__r) {
                if (via.VIA_de_Contacto__c == 'CORREO ELECTRÓNICO') {
                    if (via.VIA_Principal__c) {
                        correoElectronico = via.VIA_Numero_Correo__c;
                        correoPrincipal = true;
                    } else if (!correoPrincipal && String.isBlank(correoElectronico)) {
                        correoElectronico = via.VIA_Numero_Correo__c;
                    }
                }
            }
            
            if (String.isBlank(correoElectronico)) {
                throw new VFS_KYCEnvelopeException('No se encontró una dirección de correo electrónico válida para la cuenta. Por favor, configure una vía de contacto de correo electrónico para proceder con el proceso KYC.');
            }
            
            Integer pageAccount = 4;
            Integer pageOthers = 5;
            List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = new List<VFS_EsignSendingEnvelope.EnvelopeAction>();
            
            // Acciones de firma
            actions.add(createSignAction(correoElectronico, acc.FirstName, acc.LastName, 'firstSigner', pageAccount, 245, 355, 130, 80));
            actions.add(createSignAction(acc.LastModifiedBy.Email, acc.LastModifiedBy.FirstName, acc.LastModifiedBy.LastName, 'secondSigner', pageOthers, 355, 659, 120, 89));
            actions.add(createSignAction(acc.Owner.Email, acc.Owner.FirstName, acc.Owner.LastName, 'thirdSigner', pageOthers, 355, 480, 120, 90));
            
            // Acciones de envío de copia - se agregan al final
            actions.add(createSendCopyAction(correoElectronico, acc.FirstName, acc.LastName, languageCode));
            actions.add(createSendCopyAction(acc.LastModifiedBy.Email, acc.LastModifiedBy.FirstName, acc.LastModifiedBy.LastName, languageCode));
            actions.add(createSendCopyAction(acc.Owner.Email, acc.Owner.FirstName, acc.Owner.LastName, languageCode));
            
            return actions;
            
        } catch (VFS_KYCEnvelopeException e) {
            throw e;
        } catch (Exception e) {
            throw new VFS_KYCEnvelopeException('Error al generar las firmas para persona física en el proceso KYC: ' + e.getMessage());
        }
    }

    // Método para persona jurídica: genera acciones de firma para los accionistas en dos columnas
    private static List<VFS_EsignSendingEnvelope.EnvelopeAction> createSignsJuridica(String recordId) {
        try {
            String languageCode = obtenerCodigoLenguaje();

            // Consulta los accionistas y sus datos de contacto
            List<Participante__c> accionistas = [
                SELECT Participante__c, Participante__r.Id, Participante__r.FirstName, Participante__r.LastName
                FROM Participante__c 
                WHERE PAR_Cliente__c = :recordId AND VFS_FirmanteConozcaCliente__c= TRUE
                ORDER BY PAR_Porcentaje__c DESC LIMIT 2
            ];
            System.debug('Participantes: ' + accionistas);

            // Validar que haya al menos un firmante autorizado para persona jurídica
            if (accionistas.isEmpty()) {
                throw new VFS_KYCEnvelopeException('No se encontraron firmantes autorizados para la cuenta de persona jurídica en el proceso KYC. Se requiere al menos un firmante autorizado para procesar la solicitud de firma.');
            }

            // Obtener los IDs de los Accounts relacionados
            Set<Id> accountIds = new Set<Id>();
            for (Participante__c accio : accionistas) {
                if (accio.Participante__r != null) {
                    accountIds.add(accio.Participante__r.Id);
                }
            }
            
            // Consultar Accounts con sus vías de contacto
            Map<Id, Account> accountMap = new Map<Id, Account>([
                SELECT Id, FirstName, LastName, (SELECT VIA_Numero_Correo__c, VIA_de_Contacto__c, VIA_Principal__c, CreatedDate FROM Vias_de_Contacto__r)
                FROM Account WHERE Id IN :accountIds
            ]);
           
            List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = new List<VFS_EsignSendingEnvelope.EnvelopeAction>();
            List<VFS_EsignSendingEnvelope.EnvelopeAction> copyActions = new List<VFS_EsignSendingEnvelope.EnvelopeAction>();
            
            // Recorre los accionistas y genera la acción de firma para cada uno
            for (Integer idx = 0; idx < accionistas.size(); idx++) {
                Integer posX;
                Integer posY;
                Participante__c accio = accionistas[idx];
                if (accio.Participante__r == null) continue; // Valida que exista el Account relacionado
                Account acc = accountMap.get(accio.Participante__r.Id);
                
                // Obtener el correo electrónico correcto desde las vías de contacto
                String correoElectronico = '';
                Boolean correoPrincipal = false;
                
                if (acc != null && acc.Vias_de_Contacto__r != null) {
                    for (Vias_de_Contacto__c via : acc.Vias_de_Contacto__r) {
                        if (via.VIA_de_Contacto__c == 'CORREO ELECTRÓNICO') {
                            if (via.VIA_Principal__c) {
                                correoElectronico = via.VIA_Numero_Correo__c;
                                correoPrincipal = true;
                            } else if (!correoPrincipal && String.isBlank(correoElectronico)) {
                                correoElectronico = via.VIA_Numero_Correo__c;
                            }
                        }
                    }
                }
                
                if (String.isBlank(correoElectronico)) {
                    String accountName = (acc != null) ? (acc.FirstName + ' ' + acc.LastName) : 'Desconocido';
                    throw new VFS_KYCEnvelopeException('No se encontró una dirección de correo electrónico válida para el firmante: ' + accountName + '. Por favor, configure una vía de contacto de correo electrónico.');
                }
                
                if(idx == 0){
                posX = 260;
                posY = 425;
            }else{
                posX = 260;
                posY = 475;
            }

            actions.add(createSignAction(
                correoElectronico,
                acc != null ? acc.FirstName : '',
                acc != null ? acc.LastName : '',
                'accionista_' + idx,
                7, posX, posY, 120, 40
            ));
            copyActions.add(createSendCopyAction(
                correoElectronico,
                acc != null ? acc.FirstName : '',
                acc != null ? acc.LastName : '',
                languageCode
            ));
        }
        
        // Agrega firmantes Owner y CreatedBy igual que en persona física, usando mismas posiciones
        Account accMain = [SELECT Id, Owner.Email, LastModifiedBy.Name, LastModifiedBy.Email, LastModifiedBy.FirstName, LastModifiedBy.LastName, Owner.FirstName, Owner.LastName, CreatedBy.Email, CreatedBy.FirstName, CreatedBy.LastName FROM Account WHERE Id = :recordId LIMIT 1];
        actions.add(createSignAction(accMain.LastModifiedBy.Email, accMain.LastModifiedBy.FirstName, accMain.LastModifiedBy.LastName, 'Ejecutivo Responsable', 8, 357, 650, 120, 89));
        actions.add(createSignAction(accMain.Owner.Email, accMain.Owner.FirstName, accMain.Owner.LastName, 'Verificador', 8, 357, 470, 120, 90));
        
        // Agregar las acciones de copia al final - se agregan después de todas las acciones de firma
        actions.addAll(copyActions);
        actions.add(createSendCopyAction(accMain.Owner.Email, accMain.Owner.FirstName, accMain.Owner.LastName, languageCode));
        actions.add(createSendCopyAction(accMain.LastModifiedBy.Email, accMain.LastModifiedBy.FirstName, accMain.LastModifiedBy.LastName, languageCode));
        
        return actions;
        
        } catch (VFS_KYCEnvelopeException e) {
            throw e;
        } catch (Exception e) {
            throw new VFS_KYCEnvelopeException('Error al generar las firmas para persona jurídica en el proceso KYC: ' + e.getMessage());
        }
    }


    /*
     * Devuelve el código de lenguaje para el envío de copias de documentos a firmar
     * que aplica para el ambiente en el que se ejecuta el código, sea Sandbox o Producción.
    */
    public static String obtenerCodigoLenguaje(){
        String languageCode = 'EN'; //Se establece un lenguaje default, es importante establecer este valor en base a la metadata porque el dato debe estar activo en eSignAnyWhere y cambia entre ambientes
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

    // Utilidad para crear acción de firma electrónica
    // Recibe los datos del firmante, posición y tamaño de la firma
    private static VFS_EsignSendingEnvelope.EnvelopeAction createSignAction(String email, String firstName, String lastName, String role, Integer page, Integer x, Integer y, Integer width, Integer height) {
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
        System.debug('firmas:' + firmas);
        return VFS_FirmarDocumentoUtility.buildSignAction(email, firstName, lastName, role, firmas);
    }

    // Utilidad para crear acción de envío de copia del documento firmado
    // Recibe los datos del destinatario
    private static VFS_EsignSendingEnvelope.EnvelopeAction createSendCopyAction(String email, String firstName, String lastName, String languageCode) {
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
        return sendCopy;
    }

    private static Account obtenerAccountConVias(String accountId) {
        try {
            return [
                SELECT Id, FirstName, LastName, OwnerId, Owner.Name, Owner.Email, Owner.FirstName, Owner.LastName, 
                       LastModifiedBy.FirstName, LastModifiedBy.LastName, LastModifiedBy.Email,
                       (SELECT VIA_Numero_Correo__c, VIA_de_Contacto__c, VIA_Principal__c FROM Vias_de_Contacto__r) 
                FROM Account 
                WHERE Id = :accountId 
                LIMIT 1
            ];
        } catch (QueryException e) {
            throw new VFS_KYCEnvelopeException('No se pudo acceder a la información de la cuenta para el proceso KYC. Por favor, contacte al administrador del sistema.');
        }
    }

    private static String obtenerCorreoPrincipal(Account account) {
        if (account == null) {
            throw new VFS_KYCEnvelopeException('No se puede obtener el correo de una cuenta vacía.');
        }
        
        if (account.Vias_de_Contacto__r == null || account.Vias_de_Contacto__r.isEmpty()) {
            throw new VFS_KYCEnvelopeException('La cuenta ' + account.Id + ' (' + account.FirstName + ' ' + account.LastName + ') no tiene vías de contacto configuradas para el proceso KYC.');
        }
        
        // Buscar correo principal
        for (Vias_de_Contacto__c via : account.Vias_de_Contacto__r) {
            if (via.VIA_de_Contacto__c == 'CORREO ELECTRÓNICO' && via.VIA_Principal__c && String.isNotBlank(via.VIA_Numero_Correo__c)) {
                return via.VIA_Numero_Correo__c;    
            }
        }
        
        // Buscar cualquier correo válido como alternativa
        for (Vias_de_Contacto__c via : account.Vias_de_Contacto__r) {
            if (via.VIA_de_Contacto__c == 'CORREO ELECTRÓNICO' && String.isNotBlank(via.VIA_Numero_Correo__c)) {
                return via.VIA_Numero_Correo__c;
            }
        }
        
        throw new VFS_KYCEnvelopeException('No se encontró una dirección de correo electrónico válida para la cuenta: ' + account.Id + ' (' + account.FirstName + ' ' + account.LastName + ') en el proceso KYC. Por favor, configure una vía de contacto de correo electrónico.');
    }
}