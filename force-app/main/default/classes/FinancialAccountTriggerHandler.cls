/**
 * @description       : Handler del trigger de FinServ__FinancialAccount__c.
 *                      Filtra las cuentas financieras que deben enviarse automáticamente al CORE.
 * @author            : Jhonny Peroza / Keystone Advisors
 * @last modified on  : 06-07-2026
**/
@SuppressWarnings('PMD')
public with sharing class FinancialAccountTriggerHandler {

    public static void beforeInsert(List<FinServ__FinancialAccount__c> newList) {
        System.debug('FinancialAccountTriggerHandler.beforeInsert | newList=' + newList);

        try {
            if (newList == null || newList.isEmpty()) {
                System.debug('FinancialAccountTriggerHandler.beforeInsert | No hay registros para validar');
                return;
            }

            setDefaultFinancialAccountValues(newList);

            for (FinServ__FinancialAccount__c financialAccount : newList) {
                System.debug('FinancialAccountTriggerHandler.beforeInsert | Evaluando FinancialAccount=' + financialAccount);

                /*
                 * Si la cuenta financiera ya trae número de cuenta, viene desde la consulta del CORE.
                 * En ese caso NO debe validarse como creación de producto en CORE.
                 */
                if (String.isNotBlank(financialAccount.FinServ__FinancialAccountNumber__c)) {
                    System.debug(
                        'FinancialAccountTriggerHandler.beforeInsert | Se omite validación CORE porque ya tiene número de cuenta: ' +
                        financialAccount.FinServ__FinancialAccountNumber__c
                    );
                    continue;
                }

                FinancialAccountCoreValidationService.ValidationResult validationResult =
                    FinancialAccountCoreValidationService.validateBeforeInsert(financialAccount);

                if (validationResult != null && !validationResult.isValid) {
                    financialAccount.addError(validationResult.message);
                }
            }

        } catch (Exception e) {
            System.debug('FinancialAccountTriggerHandler.beforeInsert | Error=' + e.getMessage());
            System.debug('FinancialAccountTriggerHandler.beforeInsert | StackTrace=' + e.getStackTraceString());

            for (FinServ__FinancialAccount__c financialAccount : newList) {
                financialAccount.addError(
                    'Ha ocurrido un error validando la información requerida para crear el producto financiero en el CORE: ' +
                    e.getMessage()
                );
            }
        }
    }

    public static void afterInsert(List<FinServ__FinancialAccount__c> newList) {
        System.debug('FinancialAccountTriggerHandler.afterInsert | newList=' + newList);

        try {
            if (newList == null || newList.isEmpty()) {
                System.debug('FinancialAccountTriggerHandler.afterInsert | No hay registros para procesar');
                return;
            }

            updateAccountStatusToActiveWhenFirstFinancialAccount(newList);

            Map<String, Schema.RecordTypeInfo> recordTypes =
                Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName();

            Id cuentaAhorroRecordTypeId = recordTypes.containsKey('SavingsAccount')
                ? recordTypes.get('SavingsAccount').getRecordTypeId()
                : null;

            Id cuentaCorrienteRecordTypeId = recordTypes.containsKey('CheckingAccount')
                ? recordTypes.get('CheckingAccount').getRecordTypeId()
                : null;

            List<Id> financialAccountIds = new List<Id>();

            for (FinServ__FinancialAccount__c financialAccount : newList) {
                System.debug('FinancialAccountTriggerHandler.afterInsert | Evaluando FinancialAccount=' + financialAccount);

                if (financialAccount.Id == null) {
                    continue;
                }

                /*
                 * Si ya tiene número de cuenta, este producto fue consultado desde el CORE.
                 * No debe enviarse nuevamente a creación en CORE.
                 */
                if (String.isNotBlank(financialAccount.FinServ__FinancialAccountNumber__c)) {
                    System.debug(
                        'FinancialAccountTriggerHandler.afterInsert | Se omite creación CORE porque ya tiene número de cuenta: ' +
                        financialAccount.FinServ__FinancialAccountNumber__c
                    );
                    continue;
                }

                if (String.isNotBlank(financialAccount.FIN_Res_Creacion__c)) {
                    System.debug('FinancialAccountTriggerHandler.afterInsert | Se omite porque ya tiene resultado de creación');
                    continue;
                }

                if (cuentaAhorroRecordTypeId != null &&
                    financialAccount.RecordTypeId == cuentaAhorroRecordTypeId) {

                    financialAccountIds.add(financialAccount.Id);
                    continue;
                }

                if (cuentaCorrienteRecordTypeId != null &&
                    financialAccount.RecordTypeId == cuentaCorrienteRecordTypeId) {

                    financialAccountIds.add(financialAccount.Id);
                    continue;
                }

                System.debug(
                    'FinancialAccountTriggerHandler.afterInsert | ' +
                    'Se omite porque el RecordType no está soportado por la integración actual'
                );
            }

            if (!financialAccountIds.isEmpty()) {
                System.debug(
                    'FinancialAccountTriggerHandler.afterInsert | ' +
                    'Se encola FinancialAccountCoreCreationQueueable con ids=' +
                    financialAccountIds
                );

                System.enqueueJob(
                    new FinancialAccountCoreCreationQueueable(financialAccountIds)
                );
            }

        } catch (Exception e) {
            System.debug('FinancialAccountTriggerHandler.afterInsert | Error=' + e.getMessage());
            System.debug('FinancialAccountTriggerHandler.afterInsert | StackTrace=' + e.getStackTraceString());

            throw e;
        }
    }

    public static void afterUpdate(List<FinServ__FinancialAccount__c> newList) {
        System.debug('FinancialAccountTriggerHandler.afterUpdate | newList=' + newList);

        try {
            if (newList == null || newList.isEmpty()) {
                System.debug('FinancialAccountTriggerHandler.afterUpdate | No hay registros para procesar');
                return;
            }

            /*
             * En actualización únicamente se revisa si el cliente
             * debe pasar a estado ACTIVO.
             *
             * No se relanza la creación del producto en CORE.
             */
            updateAccountStatusToActiveWhenFirstFinancialAccount(newList);

        } catch (Exception e) {
            System.debug('FinancialAccountTriggerHandler.afterUpdate | Error=' + e.getMessage());
            System.debug('FinancialAccountTriggerHandler.afterUpdate | StackTrace=' + e.getStackTraceString());

            throw e;
        }
    }

    private static void setDefaultFinancialAccountValues(List<FinServ__FinancialAccount__c> newList) {
        System.debug('FinancialAccountTriggerHandler.setDefaultFinancialAccountValues | newList=' + newList);

        if (newList == null || newList.isEmpty()) {
            System.debug('FinancialAccountTriggerHandler.setDefaultFinancialAccountValues | No hay registros para asignar valores por defecto');
            return;
        }

        Map<String, Schema.RecordTypeInfo> recordTypes =
            Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName();

        Id cuentaAhorroRecordTypeId = recordTypes.containsKey('SavingsAccount')
            ? recordTypes.get('SavingsAccount').getRecordTypeId()
            : null;

        Id cuentaCorrienteRecordTypeId = recordTypes.containsKey('CheckingAccount')
            ? recordTypes.get('CheckingAccount').getRecordTypeId()
            : null;

        for (FinServ__FinancialAccount__c financialAccount : newList) {
            System.debug('FinancialAccountTriggerHandler.setDefaultFinancialAccountValues | Evaluando FinancialAccount=' + financialAccount);

            if (cuentaCorrienteRecordTypeId != null &&
                financialAccount.RecordTypeId == cuentaCorrienteRecordTypeId &&
                String.isBlank(financialAccount.FIN_Linea_de_producto__c)) {

                financialAccount.FIN_Linea_de_producto__c = 'Cuentas corrientes';
            }

            if (cuentaAhorroRecordTypeId != null &&
                financialAccount.RecordTypeId == cuentaAhorroRecordTypeId &&
                String.isBlank(financialAccount.FIN_Linea_de_producto__c)) {

                financialAccount.FIN_Linea_de_producto__c = 'Cuentas de ahorro';
            }

            if (financialAccount.FinServ__Balance__c == null) {
                financialAccount.FinServ__Balance__c = 0.00;
            }

            if (String.isBlank(financialAccount.FinServ__Status__c)) {
                financialAccount.FinServ__Status__c = 'VIGENTE';
            }

            if (String.isNotBlank(financialAccount.FinServ__FinancialAccountNumber__c)) {
                financialAccount.Name = financialAccount.FinServ__FinancialAccountNumber__c;
                financialAccount.FinServ__SecondaryBankerName__c =
                    financialAccount.FinServ__FinancialAccountNumber__c;
            }

            System.debug(
                'FinancialAccountTriggerHandler.setDefaultFinancialAccountValues | Valores finales' +
                ' | RecordTypeId=' + financialAccount.RecordTypeId +
                ' | Name=' + financialAccount.Name +
                ' | FinServ__FinancialAccountNumber__c=' + financialAccount.FinServ__FinancialAccountNumber__c +
                ' | FinServ__SecondaryBankerName__c=' + financialAccount.FinServ__SecondaryBankerName__c +
                ' | FIN_Linea_de_producto__c=' + financialAccount.FIN_Linea_de_producto__c +
                ' | FinServ__Balance__c=' + financialAccount.FinServ__Balance__c +
                ' | FinServ__Status__c=' + financialAccount.FinServ__Status__c
            );
        }
    }

    private static void updateAccountStatusToActiveWhenFirstFinancialAccount(
        List<FinServ__FinancialAccount__c> newList
    ) {
        System.debug(
            'FinancialAccountTriggerHandler.updateAccountStatusToActiveWhenFirstFinancialAccount | newList=' +
            newList
        );

        try {
            if (newList == null || newList.isEmpty()) {
                System.debug(
                    'FinancialAccountTriggerHandler.updateAccountStatusToActiveWhenFirstFinancialAccount | ' +
                    'No hay registros para evaluar'
                );
                return;
            }

            Set<Id> accountIds = new Set<Id>();
            Map<Id, Integer> insertedFinancialAccountsByAccountId = new Map<Id, Integer>();

            for (FinServ__FinancialAccount__c financialAccount : newList) {
                if (financialAccount.FinServ__PrimaryOwner__c == null) {
                    continue;
                }

                accountIds.add(financialAccount.FinServ__PrimaryOwner__c);

                Integer currentCount =
                    insertedFinancialAccountsByAccountId.containsKey(
                        financialAccount.FinServ__PrimaryOwner__c
                    )
                    ? insertedFinancialAccountsByAccountId.get(
                        financialAccount.FinServ__PrimaryOwner__c
                    )
                    : 0;

                insertedFinancialAccountsByAccountId.put(
                    financialAccount.FinServ__PrimaryOwner__c,
                    currentCount + 1
                );
            }

            if (accountIds.isEmpty()) {
                System.debug(
                    'FinancialAccountTriggerHandler.updateAccountStatusToActiveWhenFirstFinancialAccount | ' +
                    'No hay clientes titulares para evaluar'
                );
                return;
            }

            System.debug(
                'FinancialAccountTriggerHandler.updateAccountStatusToActiveWhenFirstFinancialAccount | ' +
                'Query FinServ__FinancialAccount__c agrupado por cliente'
            );

            Map<Id, Integer> totalFinancialAccountsByAccountId = new Map<Id, Integer>();

            for (AggregateResult result : [
                SELECT
                    FinServ__PrimaryOwner__c accountId,
                    COUNT(Id) totalFinancialAccounts
                FROM FinServ__FinancialAccount__c
                WHERE FinServ__PrimaryOwner__c IN :accountIds
                GROUP BY FinServ__PrimaryOwner__c
            ]) {
                totalFinancialAccountsByAccountId.put(
                    (Id) result.get('accountId'),
                    (Integer) result.get('totalFinancialAccounts')
                );
            }

            System.debug(
                'FinancialAccountTriggerHandler.updateAccountStatusToActiveWhenFirstFinancialAccount | Query Account'
            );

            List<Account> accountsToUpdate = new List<Account>();

            for (Account accountRecord : [
                SELECT
                    Id,
                    FinServ__Status__c
                FROM Account
                WHERE Id IN :accountIds
            ]) {
                Integer totalFinancialAccounts =
                    totalFinancialAccountsByAccountId.containsKey(accountRecord.Id)
                    ? totalFinancialAccountsByAccountId.get(accountRecord.Id)
                    : 0;

                Integer insertedFinancialAccounts =
                    insertedFinancialAccountsByAccountId.containsKey(accountRecord.Id)
                    ? insertedFinancialAccountsByAccountId.get(accountRecord.Id)
                    : 0;

                System.debug(
                    'FinancialAccountTriggerHandler.updateAccountStatusToActiveWhenFirstFinancialAccount | Evaluando Account' +
                    ' | accountId=' + accountRecord.Id +
                    ' | estadoActual=' + accountRecord.FinServ__Status__c +
                    ' | totalFinancialAccounts=' + totalFinancialAccounts +
                    ' | insertedFinancialAccounts=' + insertedFinancialAccounts
                );

                if (
                    totalFinancialAccounts > 0 &&
                    accountRecord.FinServ__Status__c != 'ACTIVO'
                ) {
                    accountsToUpdate.add(
                        new Account(
                            Id = accountRecord.Id,
                            FinServ__Status__c = 'ACTIVO'
                        )
                    );
                }
            }

            if (!accountsToUpdate.isEmpty()) {
                System.debug(
                    'FinancialAccountTriggerHandler.updateAccountStatusToActiveWhenFirstFinancialAccount | ' +
                    'Se actualizan Accounts=' +
                    accountsToUpdate
                );

                update accountsToUpdate;
            }

        } catch (Exception e) {
            System.debug(
                'FinancialAccountTriggerHandler.updateAccountStatusToActiveWhenFirstFinancialAccount | Error=' +
                e.getMessage()
            );

            System.debug(
                'FinancialAccountTriggerHandler.updateAccountStatusToActiveWhenFirstFinancialAccount | StackTrace=' +
                e.getStackTraceString()
            );

            throw e;
        }
    }
}