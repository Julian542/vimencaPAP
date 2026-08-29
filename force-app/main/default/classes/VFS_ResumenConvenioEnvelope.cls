/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_ResumenConvenioEnvelope
 * Versión                :   1.0
 * Fecha de creación      :   16/07/2025
 * Función                :   Genera firma para resumenes de convenios únicos
 * Clase Test             :   VFS_ResumenConvenioEnvelopeTest
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        16/07/2025      Version inicial
 *********************************************************************************************/
public with sharing class VFS_ResumenConvenioEnvelope {
    
    public class VFS_ResumenConvenioEnvelopeException extends Exception {}
    
    @AuraEnabled
    public static List<VFS_EsignSendingEnvelope.EnvelopeAction> CreateSigns(String recordId, String buttonName) {
        try {
            if (String.isBlank(recordId)) {
                throw new VFS_ResumenConvenioEnvelopeException('El Id del registro no puede estar vacío.');
            }
            
            if (String.isBlank(buttonName)) {
                throw new VFS_ResumenConvenioEnvelopeException('El nombre del botón no puede estar vacío.');
            }
            
            String codigoLenguaje = obtenerCodigoLenguaje();
            Account acc;
            try {
                acc = [
                    SELECT Id, IsPersonAccount, PersonContactId, FirstName, LastName, ACC_Correo_Electronico_Cliente__c,
                           Owner.Email, Owner.FirstName, Owner.LastName
                    FROM Account
                    WHERE Id = :recordId
                    LIMIT 1
                ];
            } catch (QueryException e) {
                throw new VFS_ResumenConvenioEnvelopeException('No se pudo encontrar el registro solicitado. Verifique que el Id sea válido.');
            }
            
            if (acc == null) {
                throw new VFS_ResumenConvenioEnvelopeException('No se pudo encontrar el registro solicitado. Verifique que el Id sea válido.');
            }
            
            List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = new List<VFS_EsignSendingEnvelope.EnvelopeAction>();
            String email, firstName, lastName;
            String elementId = 'sig_resumen';
            Integer page = 1;
            Integer x = 100;
            Integer y = 100;
            Integer width = 120;
            Integer height = 40;
            
            // Asigna valores según el botón
            if (acc.IsPersonAccount) {
                String correoElectronico = obtenerCorreoPrincipal(acc);
                
                if (String.isBlank(correoElectronico)) {
                    throw new VFS_ResumenConvenioEnvelopeException('No se encontró una dirección de correo electrónico válida para la cuenta. Por favor, configure un ContactPointEmail.');
                }
                
                // Validar datos del titular
                if (String.isBlank(acc.FirstName) || String.isBlank(acc.LastName)) {
                    throw new VFS_ResumenConvenioEnvelopeException('La cuenta no tiene el nombre completo configurado. Se requiere FirstName y LastName para procesar la firma del Resumen de Convenio.');
                }
                
                email = correoElectronico;
                firstName = acc.FirstName;
                lastName = acc.LastName;
            } else {
                // Para jurídico, busca el participante principal
                List<Participante__c> participantes;
                try {
                    participantes = [
                        SELECT Participante__c, Participante__r.Id, Participante__r.FirstName, Participante__r.LastName
                        FROM Participante__c 
                        WHERE PAR_Cliente__c = :recordId AND VFS_FirmanteDeContratoAutorizado__c = true
                        ORDER BY PAR_Porcentaje__c DESC, Participante__r.LastName ASC, Participante__r.FirstName ASC
                        LIMIT 1
                    ];
                } catch (QueryException e) {
                    throw new VFS_ResumenConvenioEnvelopeException('No se pudo acceder a los datos de los participantes. Por favor, contacte al administrador del sistema.');
                }
                
                if (participantes.isEmpty()) {
                    throw new VFS_ResumenConvenioEnvelopeException('No se encontraron participantes autorizados para firmar el Resumen de Convenio. Se requiere al menos un participante con "Firmante de Contrato Autorizado" activo.');
                }
                
                Account accPart;
                try {
                    accPart = [
                        SELECT Id, PersonContactId, FirstName, LastName
                        FROM Account
                        WHERE Id = :participantes[0].Participante__r.Id
                        LIMIT 1
                    ];
                } catch (QueryException e) {
                    throw new VFS_ResumenConvenioEnvelopeException('No se pudo acceder a los datos del participante autorizado.');
                }
                
                if (accPart == null) {
                    throw new VFS_ResumenConvenioEnvelopeException('No se encontraron los datos de la cuenta del participante autorizado.');
                }
                
                // Validar datos del participante
                if (String.isBlank(accPart.FirstName) || String.isBlank(accPart.LastName)) {
                    throw new VFS_ResumenConvenioEnvelopeException('El participante autorizado no tiene el nombre completo configurado. Se requiere FirstName y LastName para procesar la firma del Resumen de Convenio.');
                }
                
                String correoElectronico = obtenerCorreoPrincipal(accPart);
                
                if (String.isBlank(correoElectronico)) {
                    throw new VFS_ResumenConvenioEnvelopeException('No se encontró una dirección de correo electrónico válida para el participante: ' + accPart.FirstName + ' ' + accPart.LastName + '. Por favor, configure un ContactPointEmail.');
                }
                
                email = correoElectronico;
                firstName = accPart.FirstName;
                lastName = accPart.LastName;
            }
            
            // Validar datos del Owner para las copias
            if (acc.Owner == null || String.isBlank(acc.Owner.Email) || String.isBlank(acc.Owner.FirstName) || String.isBlank(acc.Owner.LastName)) {
                throw new VFS_ResumenConvenioEnvelopeException('El propietario (Owner) de la cuenta no tiene los datos completos. Se requiere correo electrónico y nombre completo para enviar copias del resumen de convenio.');
            }
            
            // Switch simple para cada botón
            if (buttonName == 'Resumen Convenio Único Cuenta de Ahorro') {
                page = 2; x = 336; y = 438; width = 120; height = 40;
            } else if (buttonName == 'Resumen Convenio Único Cuenta Corriente') {
                page = 2; x = 336; y = 420; width = 120; height = 40;
            } else if (buttonName == 'Resumen Convenio Único Tarjeta de Credito') {
                page = 2; x = 336; y = 200; width = 120; height = 40;
            } else if (buttonName == 'Resumen Convenio Único Tarjeta de Prepago') {
                page = 2; x = 336; y = 613; width = 120; height = 40;
            } else if (buttonName == 'Resumen Convenio Único IB y Vimencash') {
                page = 2; x = 336; y = 668; width = 120; height = 40;
            } else if (buttonName == 'Resumen Convenio Único CAD') {
                page = 2; x = 326; y = 466; width = 120; height = 40;
            } else {
                throw new VFS_ResumenConvenioEnvelopeException('Nombre de botón no válido: ' + buttonName + '. Los botones válidos son: Resumen Convenio Único Cuenta de Ahorro, Resumen Convenio Único Cuenta Corriente, Resumen Convenio Único Tarjeta de Credito, Resumen Convenio Único Tarjeta de Prepago, Resumen Convenio Único IB y Vimencash, Resumen Convenio Único CAD.');
            }
            
            actions.add(buildSignActionHelper(email, firstName, lastName, 'firmante', elementId, 1, page, x, y, width, height));
            actions.add(createSendCopyAction(email, firstName, lastName, codigoLenguaje));
            
            // Agregar copia para el owner del Account
            actions.add(createSendCopyAction(acc.Owner.Email, acc.Owner.FirstName, acc.Owner.LastName, codigoLenguaje));
            
            if (actions.isEmpty()) {
                throw new VFS_ResumenConvenioEnvelopeException('No se pudieron generar las acciones de firma. Verifique que todos los datos requeridos estén completos.');
            }
            
            return actions;
                
        } catch (VFS_ResumenConvenioEnvelopeException e) {
            // Convertir excepción personalizada a AuraHandledException para LWC
            String errorMessage = e.getMessage();
            Exception auraEx = new CalloutException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (Exception e) {
            // Manejar cualquier otra excepción inesperada
            String errorMessage = 'Error inesperado al procesar la solicitud de firma del Resumen de Convenio. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new CalloutException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
    }

    // Utilidad para crear acción de firma electrónica
    private static VFS_EsignSendingEnvelope.EnvelopeAction buildSignActionHelper(String email, String firstName, String lastName, String role, String elementId, Integer documentNumber, Integer pageNumber, Integer x, Integer y, Integer width, Integer height) {
        List<VFS_FirmarDocumentoUtility.SignatureParams> firmas = new List<VFS_FirmarDocumentoUtility.SignatureParams>();
        VFS_FirmarDocumentoUtility.SignatureParams sig = new VFS_FirmarDocumentoUtility.SignatureParams();
        sig.ElementId = elementId;
        sig.DocumentNumber = documentNumber;
        sig.PageNumber = pageNumber;
        sig.X = x;
        sig.Y = y;
        sig.Width = width;
        sig.Height = height;
        firmas.add(sig);
        return VFS_FirmarDocumentoUtility.buildSignAction(email, firstName, lastName, role, firmas);
    }

    // Utilidad para crear acción de envío de copia del documento firmado
    private static VFS_EsignSendingEnvelope.EnvelopeAction createSendCopyAction(String email, String firstName, String lastName, String codigoLenguaje) {
        if (String.isBlank(codigoLenguaje) || codigoLenguaje == 'es_DO' || codigoLenguaje == 'ES_DO') {
            codigoLenguaje = 'en';
        }

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

    private static String obtenerCorreoPrincipal(Account account) {
        if (account == null) {
            throw new VFS_ResumenConvenioEnvelopeException('No se puede obtener el correo de una cuenta vacía.');
        }

        Set<Id> parentIds = new Set<Id>();
        parentIds.add(account.Id);

        if (account.PersonContactId != null) {
            parentIds.add(account.PersonContactId);
        }

        List<ContactPointEmail> correos = [
            SELECT Id, ParentId, EmailAddress, IsPrimary, CreatedDate
            FROM ContactPointEmail
            WHERE ParentId IN :parentIds
              AND EmailAddress != null
            ORDER BY IsPrimary DESC, CreatedDate ASC
        ];

        for (ContactPointEmail cpe : correos) {
            if (cpe.IsPrimary && String.isNotBlank(cpe.EmailAddress)) {
                return cpe.EmailAddress;
            }
        }

        for (ContactPointEmail cpe : correos) {
            if (String.isNotBlank(cpe.EmailAddress)) {
                return cpe.EmailAddress;
            }
        }

        return null;
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
}