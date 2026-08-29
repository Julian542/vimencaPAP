/*********************************************************************************************
 * Nombre de clase Apex   :   VFS_ApCuentasEnvelope
 * Versión                :   1.0
 * Fecha de creación      :   27/06/2025
 * Función                :   Genera las acciones de firma y envío de copia para el proceso de apertura de cuentas, tanto para persona física como jurídica
 * Clase Test             :   VFS_ApCuentasEnvelopeTest
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        27/06/2025      Versión inicial
 *********************************************************************************************/
public with sharing class VFS_ApCuentasEnvelope {
    
    public class VFS_ApCuentasEnvelopeException extends Exception {}
    
    private static final Integer SIGNATURE_WIDTH = 140;
    private static final Integer SIGNATURE_HEIGHT_SMALL = 40;
    private static final Integer SIGNATURE_HEIGHT_LARGE = 50;
    
    public static INT026_FSC.Response testResponse;

    @AuraEnabled
    public static List<VFS_EsignSendingEnvelope.EnvelopeAction> CreateSigns(String recordId) {
        try {
            if (String.isBlank(recordId)) {
                throw new VFS_ApCuentasEnvelopeException('El Id del registro no puede estar vacío.');
            }
            
            FinServ__FinancialAccount__c financialAccount = getFinancialAccountWithOwner(recordId);
            
            if (financialAccount == null) {
                throw new VFS_ApCuentasEnvelopeException('No se pudo encontrar el registro solicitado. Verifique que el Id sea válido.');
            }
            
            if (financialAccount.FinServ__PrimaryOwner__c == null) {
                throw new VFS_ApCuentasEnvelopeException('La cuenta financiera no tiene un propietario principal asociado. No se puede procesar la solicitud de firma.');
            }
            
            Account account;
            try {
                account = [
                    SELECT Id, IsPersonAccount
                    FROM Account
                    WHERE Id = :financialAccount.FinServ__PrimaryOwner__c
                    LIMIT 1
                ];
            } catch (QueryException e) {
                throw new VFS_ApCuentasEnvelopeException('No se pudo acceder a la información de la cuenta titular. Por favor, contacte al administrador del sistema.');
            }
            
            List<VFS_EsignSendingEnvelope.EnvelopeAction> result;
            String codigoLenguaje = obtenerCodigoLenguaje();

            if (account.IsPersonAccount) {
                result = createSignsFisica(financialAccount.FinServ__PrimaryOwner__c, financialAccount.Id, codigoLenguaje);
            } else {
                result = createSignsJuridica(financialAccount.FinServ__PrimaryOwner__c, financialAccount.Id, codigoLenguaje);
            }
            
            if (result.isEmpty()) {
                throw new VFS_ApCuentasEnvelopeException('No se pudieron generar las acciones de firma. Verifique que todos los datos requeridos estén completos.');
            }
            
            return result;
                
        } catch (VFS_ApCuentasEnvelopeException e) {
            String errorMessage = e.getMessage();
            Exception auraEx = new CalloutException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        } catch (Exception e) {
            String errorMessage = 'Error inesperado al procesar la solicitud de firma. Por favor, contacte al administrador del sistema.';
            Exception auraEx = new CalloutException(errorMessage);
            auraEx.setMessage(errorMessage);
            throw auraEx;
        }
    }

    private static FinServ__FinancialAccount__c getFinancialAccountWithOwner(String recordId) {
        List<FinServ__FinancialAccount__c> financialAccounts = [
            SELECT Id, FinServ__PrimaryOwner__c
            FROM FinServ__FinancialAccount__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        return financialAccounts.isEmpty() ? null : financialAccounts[0];
    }

    private static List<VFS_EsignSendingEnvelope.EnvelopeAction> createSignsFisica(Id accountId, Id financialAccountId, String codigoLenguaje) {
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = new List<VFS_EsignSendingEnvelope.EnvelopeAction>();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> copyActions = new List<VFS_EsignSendingEnvelope.EnvelopeAction>();
        
        try {
            Account account = obtenerAccountConVias(accountId);
            String correo = obtenerCorreoPrincipal(account);
            List<Account> autorizados = getFirmantesAutorizados(financialAccountId);
            
            // Validar que haya al menos un firmante autorizado para persona física
            if (autorizados.isEmpty()) {
                //throw new VFS_ApCuentasEnvelopeException('No se encontraron firmantes autorizados para la cuenta de persona física. Se requiere al menos un firmante autorizado para procesar la solicitud de firma.');
            }
            
            Integer yPosition = 260;
            
            actions.add(buildSignActionHelper(correo, account.FirstName, account.LastName, 
                'firstSigner', 'sig_account', 1, 2, 64, yPosition, SIGNATURE_WIDTH, SIGNATURE_HEIGHT_LARGE));
            copyActions.add(buildSendCopyHelper(correo, account.FirstName, account.LastName, codigoLenguaje));
            
            for (Integer i = 0; i < Math.min(autorizados.size(), 2); i++) {
                Account autorizado = autorizados[i];
                String correoAutorizado = obtenerCorreoPrincipal(autorizado);
                Integer xPosition = (i == 0) ? 238 : 408;
                String elementId = 'sig_conjunto' + (i + 1);
                String role = 'conjuntoSigner' + (i + 1);
                
                actions.add(buildSignActionHelper(correoAutorizado, autorizado.FirstName, autorizado.LastName, 
                    role, elementId, 1, 2, xPosition, yPosition, SIGNATURE_WIDTH, SIGNATURE_HEIGHT_LARGE));
                copyActions.add(buildSendCopyHelper(correoAutorizado, autorizado.FirstName, autorizado.LastName, codigoLenguaje));
            }

            if (account.LastModifiedBy != null) {
                actions.add(buildSignActionHelper(account.LastModifiedBy.Email, account.LastModifiedBy.FirstName, account.LastModifiedBy.LastName, 
                    'secondSigner', 'sig_ejecutivo', 1, 3, 113, 622, SIGNATURE_WIDTH, SIGNATURE_HEIGHT_SMALL));
                copyActions.add(buildSendCopyHelper(account.LastModifiedBy.Email, account.LastModifiedBy.FirstName, account.LastModifiedBy.LastName, codigoLenguaje));
            }

            actions.add(buildSignActionHelper(account.Owner.Email, account.Owner.FirstName, account.Owner.LastName, 
                'thirdSigner', 'sig_verified', 1, 3, 369, 622, SIGNATURE_WIDTH, SIGNATURE_HEIGHT_SMALL));
            copyActions.add(buildSendCopyHelper(account.Owner.Email, account.Owner.FirstName, account.Owner.LastName, codigoLenguaje));

            actions.addAll(copyActions);
            
        } catch (VFS_ApCuentasEnvelopeException e) {
            throw e;
        } catch (Exception e) {
            throw new VFS_ApCuentasEnvelopeException('Error al generar las firmas para persona física: ' + e.getMessage());
        }
        
        return actions;
    }

    private static List<VFS_EsignSendingEnvelope.EnvelopeAction> createSignsJuridica(Id accountId, Id financialAccountId, String codigoLenguaje) {
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = new List<VFS_EsignSendingEnvelope.EnvelopeAction>();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> copyActions = new List<VFS_EsignSendingEnvelope.EnvelopeAction>();
        
        try {
            Account account = obtenerAccountConVias(accountId);
            List<Account> firmantes = getFirmantesAutorizados(financialAccountId);
            
            // Validar que haya al menos un firmante autorizado para persona jurídica
            if (firmantes.isEmpty()) {
                throw new VFS_ApCuentasEnvelopeException('No se encontraron firmantes autorizados para la cuenta de persona jurídica. Se requiere al menos un firmante autorizado para procesar la solicitud de firma.');
            }
            
            List<Integer> xPositions = new List<Integer>{105, 365};
            Integer baseY_page2 = 205, stepY_page2 = 84, yOffset_page2 = 50; 
            Integer baseY_page3 = 643, stepY_page3 = 84, yOffset_page3 = 50;
            
            addFirmantesSignatures(actions, firmantes, xPositions, baseY_page2, stepY_page2, yOffset_page2, 2, 0, 4);
            addFirmantesSignatures(actions, firmantes, xPositions, baseY_page3, stepY_page3, yOffset_page3, 3, 4, 12);
            
            if (account.LastModifiedBy != null) {
                actions.add(buildSignActionHelper(account.LastModifiedBy.Email, account.LastModifiedBy.FirstName, account.LastModifiedBy.LastName, 
                    'secondSigner', 'sig_ejecutivo', 1, 4, 113, 623, SIGNATURE_WIDTH, SIGNATURE_HEIGHT_SMALL));
                copyActions.add(buildSendCopyHelper(account.LastModifiedBy.Email, account.LastModifiedBy.FirstName, account.LastModifiedBy.LastName, codigoLenguaje));
            }

            actions.add(buildSignActionHelper(account.Owner.Email, account.Owner.FirstName, account.Owner.LastName, 
                'thirdSigner', 'sig_verified', 1, 4, 365, 623, SIGNATURE_WIDTH, SIGNATURE_HEIGHT_SMALL));
            copyActions.add(buildSendCopyHelper(account.Owner.Email, account.Owner.FirstName, account.Owner.LastName, codigoLenguaje));
            
            // Agregar las copias de los firmantes
            addFirmantesCopyActions(copyActions, firmantes, codigoLenguaje);
            
            // Agregar todas las copyActions solo una vez
            actions.addAll(copyActions);
                
        } catch (VFS_ApCuentasEnvelopeException e) {
            throw e;
        } catch (Exception e) {
            throw new VFS_ApCuentasEnvelopeException('Error al generar las firmas para persona jurídica: ' + e.getMessage());
        }
        
        return actions;
    }
    
    private static void addFirmantesSignatures(
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions, List<Account> firmantes, 
        List<Integer> xPositions, Integer baseY, Integer stepY, Integer yOffset, Integer pageNumber,
        Integer startIndex, Integer endIndex) {
        
        for (Integer i = startIndex; i < Math.min(firmantes.size(), endIndex); i++) {
            Account firmante = firmantes[i];
            String correo = obtenerCorreoPrincipal(firmante);
            
            if (String.isNotBlank(correo) && String.isNotBlank(firmante.FirstName) && String.isNotBlank(firmante.LastName)) {
                Integer col = Math.mod(i - startIndex, 2);
                Integer row = (i - startIndex) / 2;
                Integer yPosition = baseY - (row * stepY) + yOffset;
                
                actions.add(buildSignActionHelper(correo, firmante.FirstName, firmante.LastName, 
                    'accionista' + (i + 1), 'sig_accionista' + (i + 1), 1, pageNumber, xPositions[col], yPosition, 
                    SIGNATURE_WIDTH, SIGNATURE_HEIGHT_SMALL));
            }
        }
    }
    
    private static void addFirmantesCopyActions(
        List<VFS_EsignSendingEnvelope.EnvelopeAction> copyActions, List<Account> firmantes, String codigoLenguaje) {
        
        for (Account firmante : firmantes) {
            String correo = obtenerCorreoPrincipal(firmante);
            
            if (String.isNotBlank(correo) && String.isNotBlank(firmante.FirstName) && String.isNotBlank(firmante.LastName)) {
                copyActions.add(buildSendCopyHelper(correo, firmante.FirstName, firmante.LastName, codigoLenguaje));
            }
        }
    }
    
    private class ManagerInfo {
        public String email;
        public String firstName;
        public String lastName;
        
        public ManagerInfo(String email, String firstName, String lastName) {
            this.email = email;
            this.firstName = firstName;
            this.lastName = lastName;
        }
        
        public Boolean isValid() {
            return String.isNotBlank(this.email);
        }
    }
    
    private static ManagerInfo getManagerInfo(Id ownerId) {
        try {
            User ownerUser = [SELECT USE_Codigo__c FROM User WHERE Id = :ownerId LIMIT 1];
            
            if (String.isNotBlank(ownerUser.USE_Codigo__c)) {
                List<Datos_Maestros__c> datosMaestro = [
                    SELECT VFS_GerenteOficina__c, VFS_CorreoGerente__c 
                    FROM Datos_Maestros__c 
                    WHERE DM_Codigo_Oficina__c = :ownerUser.USE_Codigo__c 
                    LIMIT 1
                ];
                
                if (!datosMaestro.isEmpty() && String.isNotBlank(datosMaestro[0].VFS_GerenteOficina__c)) {
                    String nombreCompleto = datosMaestro[0].VFS_GerenteOficina__c;
                    List<String> nombrePartes = nombreCompleto.split(' ', 2);
                    
                    String firstName = nombrePartes.size() > 0 ? nombrePartes[0] : '';
                    String lastName = nombrePartes.size() > 1 ? nombrePartes[1] : '';
                    String email = datosMaestro[0].VFS_CorreoGerente__c;
                    
                    return new ManagerInfo(email, firstName, lastName);
                }
            }
        } catch (Exception e) {
            throw new VFS_ApCuentasEnvelopeException('Error al consultar la información del gerente: ' + e.getMessage());
        }
        
        return new ManagerInfo('', '', '');
    }

    private static Account obtenerAccountConVias(Id accountId) {
        return [
            SELECT Id,
                   FirstName,
                   LastName,
                   PersonContactId,
                   OwnerId,
                   Owner.Name,
                   Owner.Email,
                   Owner.FirstName,
                   Owner.LastName,
                   LastModifiedBy.FirstName,
                   LastModifiedBy.LastName,
                   LastModifiedBy.Email
            FROM Account 
            WHERE Id = :accountId 
            LIMIT 1
        ];
    }

    private static String obtenerCorreoPrincipal(Account account) {
        if (account == null) {
            throw new VFS_ApCuentasEnvelopeException('No se puede obtener el correo de una cuenta vacía.');
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
        
        throw new VFS_ApCuentasEnvelopeException('No se encontró una dirección de correo electrónico válida para la cuenta: ' + account.Id + ' (' + account.FirstName + ' ' + account.LastName + '). Por favor, configure un ContactPointEmail.');
    }

    private static List<Account> getFirmantesAutorizados(Id financialAccountId) {
        List<Account> firmantesAutorizados = new List<Account>();
        
        try {
            INT026_FSC.Response resp = Test.isRunningTest() && testResponse != null ? testResponse : INT026_FSC.consultVin2(financialAccountId);
            
            Set<String> nombresCompletos = new Set<String>();
            Set<String> numerosDocumentosAutorizados = new Set<String>();
            Set<String> numerosDocumentosGarantia = new Set<String>();
            
            String numIdentificacionTitular = getTitularNumIdentificacion(financialAccountId);
            String accountTitularId = getTitularAccountId(financialAccountId);
            
            for (Map<String, Object> vinculado : resp.responseList) {
                String vinculo = String.valueOf(vinculado.get('Vinculo'));
                String numeroDocumento = String.valueOf(vinculado.get('NumeroDocumento'));
                String nombreCompleto = String.valueOf(vinculado.get('NombreCompleto'));
                
                if (vinculo.equalsIgnoreCase('AUTORIZADO')) {
                    if (!String.isBlank(nombreCompleto)) nombresCompletos.add(nombreCompleto);
                    if (!String.isBlank(numeroDocumento)) numerosDocumentosAutorizados.add(numeroDocumento);
                }
                
                if (String.valueOf(vinculado.get('DarGarantia')).equalsIgnoreCase('Y')) {
                    if (!String.isBlank(numeroDocumento)) {
                        if (String.isBlank(numIdentificacionTitular) || !numIdentificacionTitular.equals(numeroDocumento)) {
                            numerosDocumentosGarantia.add(numeroDocumento);
                        }
                    }
                }
            }
            
            if (!nombresCompletos.isEmpty() || !numerosDocumentosAutorizados.isEmpty()) {
                List<String> whereConditions = new List<String>();
                if (!nombresCompletos.isEmpty()) {
                    whereConditions.add('Name IN :nombresCompletos');
                }
                if (!numerosDocumentosAutorizados.isEmpty()) {
                    whereConditions.add('ACC_NumIdentificacion__c IN :numerosDocumentosAutorizados');
                }
                
                String query = 'SELECT Id, Name, FirstName, LastName, PersonContactId, PersonBirthdate, ACC_Nacionalidad__c, ACC_Genero__c, ACC_NumIdentificacion__c ' +
                              'FROM Account WHERE (' + String.join(whereConditions, ' OR ') + ')';
                
                List<Account> allAuthorizedAccounts = Database.query(query);
                
                for (Account acc : allAuthorizedAccounts) {
                    if (String.isBlank(accountTitularId) || acc.Id != accountTitularId) {
                        firmantesAutorizados.add(acc);
                    }
                }
            }
            
            if (!numerosDocumentosGarantia.isEmpty()) {
                List<Account> firmantesGarantia = [
                    SELECT Id, FirstName, LastName, PersonContactId
                    FROM Account 
                    WHERE ACC_NumIdentificacion__c IN :numerosDocumentosGarantia
                    LIMIT 12
                ];
                
                for (Account firmante : firmantesGarantia) {
                    if (!accountAlreadyExists(firmantesAutorizados, firmante.Id)) {
                        firmantesAutorizados.add(firmante);
                    }
                }
            }
            
        } catch (Exception e) {
            throw new VFS_ApCuentasEnvelopeException('Error al consultar los firmantes autorizados: ' + e.getMessage() + '. Verifique la configuración de la integración y los datos del registro.');
        }
        
        return firmantesAutorizados;
    }
    
    private static String getTitularNumIdentificacion(Id financialAccountId) {
        try {
            List<FinServ__FinancialAccount__c> fas = [
                SELECT Id, FinServ__PrimaryOwner__c
                FROM FinServ__FinancialAccount__c
                WHERE Id = :financialAccountId
                LIMIT 1
            ];

            if (!fas.isEmpty() && fas[0].FinServ__PrimaryOwner__c != null) {
                List<Account> titulares = [
                    SELECT Id, ACC_NumIdentificacion__c
                    FROM Account
                    WHERE Id = :fas[0].FinServ__PrimaryOwner__c
                    LIMIT 1
                ];
                if (!titulares.isEmpty()) {
                    return titulares[0].ACC_NumIdentificacion__c;
                }
            }
        } catch (Exception ex) {
            throw new VFS_ApCuentasEnvelopeException('Error al obtener el número de identificación del titular: ' + ex.getMessage());
        }
        return '';
    }
    
    private static String getTitularAccountId(Id financialAccountId) {
        try {
            List<FinServ__FinancialAccount__c> fas = [
                SELECT Id, FinServ__PrimaryOwner__c
                FROM FinServ__FinancialAccount__c
                WHERE Id = :financialAccountId
                LIMIT 1
            ];
            if (!fas.isEmpty()) {
                return (String)fas[0].FinServ__PrimaryOwner__c;
            }
        } catch (Exception ex) {
            throw new VFS_ApCuentasEnvelopeException('Error al obtener el ID de la cuenta titular: ' + ex.getMessage());
        }
        return '';
    }
    
    private static Boolean accountAlreadyExists(List<Account> accounts, Id accountId) {
        for (Account existente : accounts) {
            if (existente.Id == accountId) {
                return true;
            }
        }
        return false;
    }

    private static VFS_EsignSendingEnvelope.EnvelopeAction buildSignActionHelper(
        String email, String firstName, String lastName, String role, String elementId, 
        Integer documentNumber, Integer pageNumber, Integer x, Integer y, Integer width, Integer height) {
        
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

    private static VFS_EsignSendingEnvelope.EnvelopeAction buildSendCopyHelper(String email, String firstName, String lastName, String codigoLenguaje) {
        VFS_EsignSendingEnvelope.EnvelopeAction sendCopy = new VFS_EsignSendingEnvelope.EnvelopeAction();
        sendCopy.Sign = null;
        
        VFS_EsignSendingEnvelope.EnvelopeSendCopy sendCopyObj = new VFS_EsignSendingEnvelope.EnvelopeSendCopy();
        VFS_EsignSendingEnvelope.EnvelopeRecipientConfiguration recConf = new VFS_EsignSendingEnvelope.EnvelopeRecipientConfiguration();
        VFS_EsignSendingEnvelope.EnvelopeContactInformation contact = new VFS_EsignSendingEnvelope.EnvelopeContactInformation();
        
        if (String.isBlank(codigoLenguaje) || codigoLenguaje == 'es_DO' || codigoLenguaje == 'ES_DO') {
            codigoLenguaje = 'en';
        }

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
    public static String obtenerCodigoLenguaje(){
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
}