/**
 * @description       : Servicio validador previo a la creación de productos financieros en CORE.
 *                      Valida que la cuenta financiera y sus datos relacionados FSC tengan la información obligatoria
 *                      antes de invocar la integración wsCreacionProd_FSC.
 * @author            : Jhonny Peroza / Keystone Advisors
 * @last modified on  : 18-05-2026
**/
@SuppressWarnings('PMD')
public with sharing class FinancialAccountCoreValidationService {

    public class ValidationResult {
        public Boolean isValid;
        public String message;

        public ValidationResult(Boolean isValid, String message) {
            this.isValid = isValid;
            this.message = message;
        }
    }

    public static ValidationResult validateBeforeInsert(FinServ__FinancialAccount__c financialAccount) {
        System.debug('FinancialAccountCoreValidationService.validateBeforeInsert | financialAccount=' + financialAccount);

        try {
            if (financialAccount == null) {
                return buildError('Para crear un producto financiero en el CORE, debe indicar la cuenta financiera.');
            }

            if (financialAccount.RecordTypeId == null) {
                return buildError('Para crear un producto financiero en el CORE, la cuenta financiera debe tener tipo de registro.');
            }

            System.debug('FinancialAccountCoreValidationService.validateBeforeInsert | Query RecordType');

            List<RecordType> recordTypes = [
                SELECT Id,
                       Name,
                       DeveloperName
                FROM RecordType
                WHERE SObjectType = 'FinServ__FinancialAccount__c'
                AND Id = :financialAccount.RecordTypeId
                LIMIT 1
            ];

            if (recordTypes.isEmpty()) {
                return buildError('Para crear un producto financiero en el CORE, no se pudo identificar el tipo de registro de la cuenta financiera.');
            }

            RecordType currentRecordType = recordTypes[0];

            System.debug('FinancialAccountCoreValidationService.validateBeforeInsert | currentRecordType=' + currentRecordType);

            Set<String> supportedDeveloperNames = new Set<String>{
                'SavingsAccount',
                'CheckingAccount'
            };

            if (!supportedDeveloperNames.contains(currentRecordType.DeveloperName)) {
                return buildError(
                    'Actualmente la integración de creación de producto financiero en CORE solo soporta Cuenta de Ahorro y Cuenta Corriente. ' +
                    'RecordType actual: ' + currentRecordType.Name + ' / ' + currentRecordType.DeveloperName
                );
            }

            if (financialAccount.FinServ__PrimaryOwner__c == null) {
                return buildError('Para crear un producto financiero en el CORE, debe indicar el cliente titular.');
            }

            if (financialAccount.FIN_Producto__c == null) {
                return buildError('Para crear un producto financiero en el CORE, debe seleccionar un producto de la matriz.');
            }

            if (financialAccount.FIN_Ejecutivo__c == null) {
                return buildError('Para crear un producto financiero en el CORE, debe indicar el ejecutivo del producto financiero.');
            }

            System.debug('FinancialAccountCoreValidationService.validateBeforeInsert | Query Account');

            List<Account> accounts = [
                SELECT Id,
                       Name,
                       FirstName,
                       MiddleName,
                       LastName,
                       Suffix,
                       RecordTypeId,
                       ACC_CIF__c,
                       ACC_TipoIdentificacion__c,
                       ACC_NumIdentificacion__c,
                       ACC_RNC__c,
                       Owner.USE_Oficina__c
                FROM Account
                WHERE Id = :financialAccount.FinServ__PrimaryOwner__c
                LIMIT 1
            ];

            if (accounts.isEmpty()) {
                return buildError('Para crear un producto financiero en el CORE, no se pudo obtener la información del cliente titular.');
            }

            Account primaryOwner = accounts[0];

            if (String.isBlank(primaryOwner.ACC_CIF__c)) {
                return buildError('Para crear un producto financiero en el CORE, el cliente debe tener CIF.');
            }

            Map<String, Schema.RecordTypeInfo> accountRecordTypes =
                Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();

            Id personaJuridicaRecordTypeId = accountRecordTypes.containsKey('IndustriesBusiness')
                ? accountRecordTypes.get('IndustriesBusiness').getRecordTypeId()
                : null;

            Id personAccountRecordTypeId = accountRecordTypes.containsKey('PersonAccount')
                ? accountRecordTypes.get('PersonAccount').getRecordTypeId()
                : null;

            if (personaJuridicaRecordTypeId == null) {
                return buildError('Para crear un producto financiero en el CORE, no existe el Record Type IndustriesBusiness.');
            }

            if (personAccountRecordTypeId == null) {
                return buildError('Para crear un producto financiero en el CORE, no existe el Record Type PersonAccount.');
            }

            if (primaryOwner.RecordTypeId == personaJuridicaRecordTypeId) {
                if (String.isBlank(primaryOwner.Name)) {
                    return buildError('Para crear un producto financiero en el CORE, el cliente jurídico debe tener nombre.');
                }

                if (String.isBlank(primaryOwner.ACC_RNC__c)) {
                    return buildError('Para crear un producto financiero en el CORE, el cliente jurídico debe tener RNC.');
                }
            } else if (primaryOwner.RecordTypeId == personAccountRecordTypeId) {
                Boolean hasFirstName = String.isNotBlank(primaryOwner.FirstName) || String.isNotBlank(primaryOwner.MiddleName);
                Boolean hasLastName = String.isNotBlank(primaryOwner.LastName) || String.isNotBlank(primaryOwner.Suffix);

                if (!hasFirstName) {
                    return buildError('Para crear un producto financiero en el CORE, el cliente debe tener nombre.');
                }

                if (!hasLastName) {
                    return buildError('Para crear un producto financiero en el CORE, el cliente debe tener apellido.');
                }

                if (String.isBlank(primaryOwner.ACC_TipoIdentificacion__c)) {
                    return buildError('Para crear un producto financiero en el CORE, el cliente debe tener tipo de identificación.');
                }

                if (String.isBlank(primaryOwner.ACC_NumIdentificacion__c)) {
                    return buildError('Para crear un producto financiero en el CORE, el cliente debe tener número de identificación.');
                }
            } else {
                System.debug('RTs: ' + primaryOwner.RecordTypeId + ' - ' + personaJuridicaRecordTypeId + ' - ' + personAccountRecordTypeId);
                return buildError('Para crear un producto financiero en el CORE, el cliente titular debe ser Persona Física o Persona Jurídica.');
            }

            System.debug('FinancialAccountCoreValidationService.validateBeforeInsert | Query producto matriz');

            Schema.DescribeFieldResult productFieldDescribe =
                FinServ__FinancialAccount__c.FIN_Producto__c.getDescribe();

            if (productFieldDescribe.getReferenceTo().isEmpty()) {
                return buildError('Para crear un producto financiero en el CORE, no se pudo identificar el objeto de la matriz de producto.');
            }

            String productObjectName = productFieldDescribe.getReferenceTo()[0].getDescribe().getName();
            Id productId = financialAccount.FIN_Producto__c;

            List<SObject> products = Database.query(
                'SELECT Id, Name, PRO_Codigo_de_producto__c ' +
                'FROM ' + productObjectName + ' ' +
                'WHERE Id = :productId ' +
                'LIMIT 1'
            );

            if (products.isEmpty()) {
                return buildError('Para crear un producto financiero en el CORE, no se pudo obtener la información del producto de la matriz.');
            }

            SObject productRecord = products[0];

            String productName = String.valueOf(productRecord.get('Name'));
            String productCode = String.valueOf(productRecord.get('PRO_Codigo_de_producto__c'));

            if (String.isBlank(productCode)) {
                return buildError('Para crear un producto financiero en el CORE, el producto seleccionado debe tener código de producto.');
            }

            if (String.isBlank(productName)) {
                return buildError('Para crear un producto financiero en el CORE, el producto seleccionado debe tener nombre.');
            }

            System.debug('FinancialAccountCoreValidationService.validateBeforeInsert | Query ejecutivo');

            List<User> executives = [
                SELECT Id,
                       Alias
                FROM User
                WHERE Id = :financialAccount.FIN_Ejecutivo__c
                LIMIT 1
            ];

            if (executives.isEmpty()) {
                return buildError('Para crear un producto financiero en el CORE, no se pudo obtener el ejecutivo del producto financiero.');
            }

            if (String.isBlank(executives[0].Alias)) {
                return buildError('Para crear un producto financiero en el CORE, el ejecutivo del producto financiero debe tener alias configurado.');
            }

            ValidationResult userValidation = validateCurrentUser();
            if (!userValidation.isValid) {
                return userValidation;
            }

            ValidationResult addressValidation = validatePrimaryAddress(financialAccount.FinServ__PrimaryOwner__c);
            if (!addressValidation.isValid) {
                return addressValidation;
            }

            ValidationResult phoneValidation = validatePrimaryPhone(financialAccount.FinServ__PrimaryOwner__c);
            if (!phoneValidation.isValid) {
                return phoneValidation;
            }

            return buildSuccess();

        } catch (Exception e) {
            System.debug('FinancialAccountCoreValidationService.validateBeforeInsert | Error=' + e.getMessage());
            System.debug('FinancialAccountCoreValidationService.validateBeforeInsert | StackTrace=' + e.getStackTraceString());

            return buildError(
                'Ha ocurrido un error validando la información requerida para crear el producto financiero en el CORE: ' +
                e.getMessage()
            );
        }
    }

    public static ValidationResult validate(Id financialAccountId) {
        System.debug('FinancialAccountCoreValidationService.validate | financialAccountId=' + financialAccountId);

        try {
            if (financialAccountId == null) {
                return buildError('Para crear un producto financiero en el CORE, debe indicar la cuenta financiera.');
            }

            System.debug('FinancialAccountCoreValidationService.validate | Query FinServ__FinancialAccount__c');

            List<FinServ__FinancialAccount__c> financialAccounts = [
                SELECT Id,
                       Name,
                       RecordTypeId,
                       FinServ__FinancialAccountNumber__c,
                       FinServ__PrimaryOwner__c,
                       FinServ__PrimaryOwner__r.Id,
                       FinServ__PrimaryOwner__r.Name,
                       FinServ__PrimaryOwner__r.FirstName,
                       FinServ__PrimaryOwner__r.MiddleName,
                       FinServ__PrimaryOwner__r.LastName,
                       FinServ__PrimaryOwner__r.Suffix,
                       FinServ__PrimaryOwner__r.RecordTypeId,
                       FinServ__PrimaryOwner__r.ACC_CIF__c,
                       FinServ__PrimaryOwner__r.ACC_TipoIdentificacion__c,
                       FinServ__PrimaryOwner__r.ACC_NumIdentificacion__c,
                       FinServ__PrimaryOwner__r.ACC_RNC__c,
                       FIN_Producto__c,
                       FIN_Producto__r.Id,
                       FIN_Producto__r.Name,
                       FIN_Producto__r.PRO_Codigo_de_producto__c,
                       FIN_Producto__r.PRO_Requiere_libreta_PF_PJ__c,
                       FIN_Ejecutivo__c,
                       FIN_Ejecutivo__r.Id,
                       FIN_Ejecutivo__r.Alias
                FROM FinServ__FinancialAccount__c
                WHERE Id = :financialAccountId
                LIMIT 1
            ];

            if (financialAccounts.isEmpty()) {
                return buildError('Para crear un producto financiero en el CORE, la cuenta financiera no existe.');
            }

            FinServ__FinancialAccount__c financialAccount = financialAccounts[0];

            ValidationResult recordTypeValidation = validateFinancialAccountRecordType(financialAccount);
            if (!recordTypeValidation.isValid) {
                return recordTypeValidation;
            }

            ValidationResult financialAccountValidation = validateFinancialAccountData(financialAccount);
            if (!financialAccountValidation.isValid) {
                return financialAccountValidation;
            }

            ValidationResult primaryOwnerValidation = validatePrimaryOwner(financialAccount);
            if (!primaryOwnerValidation.isValid) {
                return primaryOwnerValidation;
            }

            ValidationResult userValidation = validateCurrentUser();
            if (!userValidation.isValid) {
                return userValidation;
            }

            ValidationResult addressValidation = validatePrimaryAddress(financialAccount.FinServ__PrimaryOwner__c);
            if (!addressValidation.isValid) {
                return addressValidation;
            }

            ValidationResult phoneValidation = validatePrimaryPhone(financialAccount.FinServ__PrimaryOwner__c);
            if (!phoneValidation.isValid) {
                return phoneValidation;
            }

            return buildSuccess();

        } catch (Exception e) {
            System.debug('FinancialAccountCoreValidationService.validate | Error=' + e.getMessage());
            System.debug('FinancialAccountCoreValidationService.validate | StackTrace=' + e.getStackTraceString());

            return buildError(
                'Ha ocurrido un error validando la información requerida para crear el producto financiero en el CORE: ' +
                e.getMessage()
            );
        }
    }

    private static ValidationResult validateFinancialAccountRecordType(FinServ__FinancialAccount__c financialAccount) {
        System.debug('FinancialAccountCoreValidationService.validateFinancialAccountRecordType | financialAccount=' + financialAccount);

        if (financialAccount.RecordTypeId == null) {
            return buildError('Para crear un producto financiero en el CORE, la cuenta financiera debe tener tipo de registro.');
        }

        System.debug('FinancialAccountCoreValidationService.validateFinancialAccountRecordType | Query RecordType');

        List<RecordType> recordTypes = [
            SELECT Id,
                   Name,
                   DeveloperName
            FROM RecordType
            WHERE SObjectType = 'FinServ__FinancialAccount__c'
            AND Id = :financialAccount.RecordTypeId
            LIMIT 1
        ];

        if (recordTypes.isEmpty()) {
            return buildError('Para crear un producto financiero en el CORE, no se pudo identificar el tipo de registro de la cuenta financiera.');
        }

        RecordType currentRecordType = recordTypes[0];

        System.debug('FinancialAccountCoreValidationService.validateFinancialAccountRecordType | currentRecordType=' + currentRecordType);

        Set<String> supportedDeveloperNames = new Set<String>{
            'SavingsAccount',
            'CheckingAccount'
        };

        if (!supportedDeveloperNames.contains(currentRecordType.DeveloperName)) {
            return buildError(
                'Actualmente la integración de creación de producto financiero en CORE solo soporta Cuenta de Ahorro y Cuenta Corriente. ' +
                'RecordType actual: ' + currentRecordType.Name + ' / ' + currentRecordType.DeveloperName
            );
        }

        return buildSuccess();
    }

    private static ValidationResult validateFinancialAccountData(FinServ__FinancialAccount__c financialAccount) {
        System.debug('FinancialAccountCoreValidationService.validateFinancialAccountData | financialAccount=' + financialAccount);

        if (financialAccount.FinServ__PrimaryOwner__c == null) {
            return buildError('Para crear un producto financiero en el CORE, debe indicar el cliente titular.');
        }

        if (financialAccount.FIN_Producto__c == null) {
            return buildError('Para crear un producto financiero en el CORE, debe seleccionar un producto de la matriz.');
        }

        if (financialAccount.FIN_Producto__r == null) {
            return buildError('Para crear un producto financiero en el CORE, no se pudo obtener la información del producto de la matriz.');
        }

        if (String.isBlank(financialAccount.FIN_Producto__r.PRO_Codigo_de_producto__c)) {
            return buildError('Para crear un producto financiero en el CORE, el producto seleccionado debe tener código de producto.');
        }

        if (String.isBlank(financialAccount.FIN_Producto__r.Name)) {
            return buildError('Para crear un producto financiero en el CORE, el producto seleccionado debe tener nombre.');
        }

        if (financialAccount.FIN_Ejecutivo__c == null) {
            return buildError('Para crear un producto financiero en el CORE, debe indicar el ejecutivo del producto financiero.');
        }

        if (financialAccount.FIN_Ejecutivo__r == null || String.isBlank(financialAccount.FIN_Ejecutivo__r.Alias)) {
            return buildError('Para crear un producto financiero en el CORE, el ejecutivo del producto financiero debe tener alias configurado.');
        }

        return buildSuccess();
    }

    private static ValidationResult validatePrimaryOwner(FinServ__FinancialAccount__c financialAccount) {
        System.debug('FinancialAccountCoreValidationService.validatePrimaryOwner | financialAccount=' + financialAccount);

        if (financialAccount.FinServ__PrimaryOwner__r == null) {
            return buildError('Para crear un producto financiero en el CORE, no se pudo obtener la información del cliente titular.');
        }

        Account primaryOwner = financialAccount.FinServ__PrimaryOwner__r;

        if (String.isBlank(primaryOwner.ACC_CIF__c)) {
            return buildError('Para crear un producto financiero en el CORE, el cliente debe tener CIF.');
        }

        Map<String, Schema.RecordTypeInfo> accountRecordTypes =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();

        Id personaJuridicaRecordTypeId = accountRecordTypes.containsKey('IndustriesBusiness')
            ? accountRecordTypes.get('IndustriesBusiness').getRecordTypeId()
            : null;

        Id personAccountRecordTypeId = accountRecordTypes.containsKey('PersonAccount')
            ? accountRecordTypes.get('PersonAccount').getRecordTypeId()
            : null;

        if (personaJuridicaRecordTypeId == null) {
            return buildError('Para crear un producto financiero en el CORE, no existe el Record Type IndustriesBusiness.');
        }

        if (personAccountRecordTypeId == null) {
            return buildError('Para crear un producto financiero en el CORE, no existe el Record Type PersonAccount.');
        }

        if (primaryOwner.RecordTypeId == personaJuridicaRecordTypeId) {
            if (String.isBlank(primaryOwner.Name)) {
                return buildError('Para crear un producto financiero en el CORE, el cliente jurídico debe tener nombre.');
            }

            if (String.isBlank(primaryOwner.ACC_RNC__c)) {
                return buildError('Para crear un producto financiero en el CORE, el cliente jurídico debe tener RNC.');
            }

            return buildSuccess();
        }

        if (primaryOwner.RecordTypeId == personAccountRecordTypeId) {
            Boolean hasFirstName = String.isNotBlank(primaryOwner.FirstName) || String.isNotBlank(primaryOwner.MiddleName);
            Boolean hasLastName = String.isNotBlank(primaryOwner.LastName) || String.isNotBlank(primaryOwner.Suffix);

            if (!hasFirstName) {
                return buildError('Para crear un producto financiero en el CORE, el cliente debe tener nombre.');
            }

            if (!hasLastName) {
                return buildError('Para crear un producto financiero en el CORE, el cliente debe tener apellido.');
            }

            if (String.isBlank(primaryOwner.ACC_TipoIdentificacion__c)) {
                return buildError('Para crear un producto financiero en el CORE, el cliente debe tener tipo de identificación.');
            }

            if (String.isBlank(primaryOwner.ACC_NumIdentificacion__c)) {
                return buildError('Para crear un producto financiero en el CORE, el cliente debe tener número de identificación.');
            }

            return buildSuccess();
        }

        return buildError('Para crear un producto financiero en el CORE, el cliente titular debe ser Persona Física o Persona Jurídica.');
    }

    private static ValidationResult validateCurrentUser() {
        System.debug('FinancialAccountCoreValidationService.validateCurrentUser');

        System.debug('FinancialAccountCoreValidationService.validateCurrentUser | Query User');

        User currentUser = [
            SELECT Id,
                   Username,
                   USE_Codigo__c,
                   USE_Oficina__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        if (String.isBlank(currentUser.USE_Codigo__c)) {
            return buildError('Para crear un producto financiero en el CORE, el usuario debe tener código de empleado configurado.');
        }

        if (String.isBlank(currentUser.USE_Oficina__c)) {
            return buildError('Para crear un producto financiero en el CORE, el usuario debe tener oficina configurada.');
        }

        return buildSuccess();
    }

    private static ValidationResult validatePrimaryAddress(Id accountId) {
        System.debug('FinancialAccountCoreValidationService.validatePrimaryAddress | accountId=' + accountId);

        if (accountId == null) {
            return buildError('Para crear un producto financiero en el CORE, debe indicar el cliente titular para validar la dirección.');
        }

        System.debug('FinancialAccountCoreValidationService.validatePrimaryAddress | Query ContactPointAddress');

        List<ContactPointAddress> addresses = [
            SELECT Id,
                   AddressType,
                   Street,
                   Address,
                   CPA_N_Apartamento__c,
                   Country,
                   State,
                   CPA_Distrito__c,
                   CPA_Sector__c,
                   CPA_Sector__r.DM_Direccion__c,
                   CPA_ExternalId__c,
                   PostalCode
            FROM ContactPointAddress
            WHERE ParentId = :accountId
            AND IsPrimary = true
            LIMIT 1
        ];

        if (addresses.isEmpty()) {
            return buildError('Para crear un producto financiero en el CORE, el cliente debe tener una dirección primaria asociada.');
        }

        ContactPointAddress primaryAddress = addresses[0];

        if (String.isBlank(primaryAddress.CPA_ExternalId__c)) {
            return buildError('Para crear un producto financiero en el CORE, la dirección primaria debe tener identificador externo.');
        }

        if (String.isBlank(primaryAddress.AddressType)) {
            return buildError('Para crear un producto financiero en el CORE, la dirección primaria debe tener tipo de dirección.');
        }

        if (String.isBlank(primaryAddress.Street)) {
            return buildError('Para crear un producto financiero en el CORE, la dirección primaria debe tener calle.');
        }

        if (String.isBlank(primaryAddress.Country)) {
            return buildError('Para crear un producto financiero en el CORE, la dirección primaria debe tener país.');
        }

        if (String.isBlank(primaryAddress.State)) {
            return buildError('Para crear un producto financiero en el CORE, la dirección primaria debe tener provincia/estado.');
        }

        if (primaryAddress.CPA_Sector__c == null) {
            return buildError('Para crear un producto financiero en el CORE, la dirección primaria debe tener sector.');
        }

        if (primaryAddress.CPA_Sector__r == null || String.isBlank(primaryAddress.CPA_Sector__r.DM_Direccion__c)) {
            return buildError('Para crear un producto financiero en el CORE, el sector de la dirección primaria debe tener dirección configurada.');
        }

        return buildSuccess();
    }

    private static ValidationResult validatePrimaryPhone(Id accountId) {
        System.debug('FinancialAccountCoreValidationService.validatePrimaryPhone | accountId=' + accountId);

        if (accountId == null) {
            return buildError('Para crear un producto financiero en el CORE, debe indicar el cliente titular para validar el teléfono.');
        }

        System.debug('FinancialAccountCoreValidationService.validatePrimaryPhone | Query ContactPointPhone');

        List<ContactPointPhone> phones = [
            SELECT Id,
                   AreaCode,
                   TelephoneNumber,
                   CPP_Tipo__c,
                   CPP_Telefonica__c
            FROM ContactPointPhone
            WHERE ParentId = :accountId
            AND IsPrimary = true
            LIMIT 1
        ];

        if (phones.isEmpty()) {
            return buildError('Para crear un producto financiero en el CORE, el cliente debe tener un teléfono principal asociado.');
        }

        ContactPointPhone primaryPhone = phones[0];

        if (String.isBlank(primaryPhone.TelephoneNumber)) {
            return buildError('Para crear un producto financiero en el CORE, el teléfono principal del cliente debe tener número.');
        }

        if (String.isBlank(primaryPhone.CPP_Tipo__c)) {
            return buildError('Para crear un producto financiero en el CORE, el teléfono principal del cliente debe tener tipo de contacto.');
        }

        return buildSuccess();
    }

    private static ValidationResult buildSuccess() {
        return new ValidationResult(true, null);
    }

    private static ValidationResult buildError(String message) {
        System.debug('FinancialAccountCoreValidationService.buildError | message=' + message);
        return new ValidationResult(false, message);
    }
}