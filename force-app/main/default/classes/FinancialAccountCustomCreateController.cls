/**
 * @description       : Controlador para formulario custom de creación de productos financieros.
 *                      Carga información diferenciada para Persona Física y Persona Jurídica,
 *                      permite preparar datos generales del cliente, seleccionar producto financiero,
 *                      crear/actualizar la cuenta financiera, manejar vinculados/mancomunados
 *                      y llamar a la integración de creación de producto en core.
 * @author            : Jhonny Peroza / Keystone Advisors
 * @last modified on  : 01-06-2026
**/
public with sharing class FinancialAccountCustomCreateController {

    public class BusinessException extends Exception {}

    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    public class DisplayField {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
        @AuraEnabled public String value;

        public DisplayField(String label, String apiName, String value) {
            this.key = label + '_' + apiName;
            this.label = label;
            this.apiName = apiName;
            this.value = value;
        }
    }

    public class FormField {
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
        @AuraEnabled public String value;
        @AuraEnabled public String fieldType;
        @AuraEnabled public Boolean required;
        @AuraEnabled public Boolean isPicklist;
        @AuraEnabled public Boolean isLookup;
        @AuraEnabled public Boolean isDate;
        @AuraEnabled public Boolean isCheckbox;
        @AuraEnabled public Boolean isText;
        @AuraEnabled public String objectApiName;
        @AuraEnabled public List<PicklistOption> options;

        public FormField() {
            options = new List<PicklistOption>();
            required = false;
            isPicklist = false;
            isLookup = false;
            isDate = false;
            isCheckbox = false;
            isText = false;
        }
    }

    public class LinkedClientResponse {
        @AuraEnabled public Id roleId;
        @AuraEnabled public Id clienteVinculadoId;
        @AuraEnabled public String clienteVinculadoName;
        @AuraEnabled public String claseCliente;
        @AuraEnabled public String relacion;
        @AuraEnabled public String firmante;
        @AuraEnabled public String codigo;
        @AuraEnabled public Boolean existingRecord;
        @AuraEnabled public Boolean markedForDelete;
    }

    public class LinkedClientRequest {
        @AuraEnabled public Id roleId { get; set; }
        @AuraEnabled public Id clienteVinculadoId { get; set; }
        @AuraEnabled public String clienteVinculadoName { get; set; }
        @AuraEnabled public String claseCliente { get; set; }
        @AuraEnabled public String relacion { get; set; }
        @AuraEnabled public String firmante { get; set; }
        @AuraEnabled public String codigo { get; set; }
        @AuraEnabled public Boolean existingRecord { get; set; }
        @AuraEnabled public Boolean markedForDelete { get; set; }
    }

    public class FieldValueRequest {
        @AuraEnabled public String apiName { get; set; }
        @AuraEnabled public String value { get; set; }
    }

    public class ClientInfo {
        @AuraEnabled public Id accountId;
        @AuraEnabled public Id financialAccountId;
        @AuraEnabled public String accountRecordTypeDeveloperName;
        @AuraEnabled public Boolean isPersonAccount;
        @AuraEnabled public Boolean isBusinessAccount;
        @AuraEnabled public List<DisplayField> displayFields;
        @AuraEnabled public List<FormField> formFields;

        public ClientInfo() {
            displayFields = new List<DisplayField>();
            formFields = new List<FormField>();
            isPersonAccount = false;
            isBusinessAccount = false;
        }
    }

    public class ProductCreationFormRequest {
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public Id financialAccountId { get; set; }
        @AuraEnabled public Id productId { get; set; }
        @AuraEnabled public String recordTypeDeveloperName { get; set; }
        @AuraEnabled public List<FieldValueRequest> formFields { get; set; }
        @AuraEnabled public List<LinkedClientRequest> vinculados { get; set; }
    }

    public class ProductCreationFormResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Id recordTypeId;
        @AuraEnabled public Id productId;
        @AuraEnabled public Id financialAccountId;
        @AuraEnabled public String recordTypeDeveloperName;
        @AuraEnabled public String integrationMessage;
        @AuraEnabled public String requestPreview;
    }

    public class InitResponse {
        @AuraEnabled public ClientInfo cliente;
        @AuraEnabled public String productObjectApiName;
        @AuraEnabled public List<PicklistOption> claseClienteOptions;
        @AuraEnabled public List<PicklistOption> relacionOptions;
        @AuraEnabled public List<PicklistOption> firmanteOptions;
        @AuraEnabled public List<PicklistOption> codigoOptions;
        @AuraEnabled public List<LinkedClientResponse> vinculadosExistentes;

        public InitResponse() {
            claseClienteOptions = new List<PicklistOption>();
            relacionOptions = new List<PicklistOption>();
            firmanteOptions = new List<PicklistOption>();
            codigoOptions = new List<PicklistOption>();
            vinculadosExistentes = new List<LinkedClientResponse>();
        }
    }

    @AuraEnabled(cacheable=true)
    public static InitResponse getInitialData(Id accountId, Id financialAccountId) {
        System.debug('FinancialAccountCustomCreateController.getInitialData | Inicio');
        System.debug('FinancialAccountCustomCreateController.getInitialData | accountId: ' + accountId);
        System.debug('FinancialAccountCustomCreateController.getInitialData | financialAccountId: ' + financialAccountId);

        try {
            if (accountId == null) {
                throw new BusinessException('No se recibió el Id del cliente.');
            }

            Map<String, Schema.SObjectField> accountFields = Account.SObjectType.getDescribe().fields.getMap();

            List<FieldConfig> displayConfigs = getDisplayFieldConfigs(accountFields);
            List<FieldConfig> formConfigs = getFormFieldConfigs(accountFields);

            Set<String> queryFieldSet = new Set<String>();
            queryFieldSet.add('Id');
            queryFieldSet.add('Name');
            queryFieldSet.add('RecordTypeId');
            queryFieldSet.add('RecordType.DeveloperName');

            for (FieldConfig config : displayConfigs) {
                if (String.isNotBlank(config.apiName) && accountFields.containsKey(config.apiName)) {
                    queryFieldSet.add(config.apiName);
                }
            }

            for (FieldConfig config : formConfigs) {
                if (String.isNotBlank(config.apiName) && accountFields.containsKey(config.apiName)) {
                    queryFieldSet.add(config.apiName);
                }
            }

            List<String> queryFields = new List<String>();
            queryFields.addAll(queryFieldSet);
            queryFields.sort();

            String query = 'SELECT ' + String.join(queryFields, ',') + ' FROM Account WHERE Id = :accountId LIMIT 1';
            System.debug('FinancialAccountCustomCreateController.getInitialData | Query Account: ' + query);

            Account acc = Database.query(query);

            String accountRecordTypeDeveloperName = '';
            if (acc.RecordType != null) {
                accountRecordTypeDeveloperName = acc.RecordType.DeveloperName;
            }

            Boolean isPersonAccount = accountRecordTypeDeveloperName == 'PersonAccount';
            Boolean isBusinessAccount = accountRecordTypeDeveloperName == 'IndustriesBusiness';

            ClientInfo cliente = new ClientInfo();
            cliente.accountId = acc.Id;
            cliente.financialAccountId = financialAccountId;
            cliente.accountRecordTypeDeveloperName = accountRecordTypeDeveloperName;
            cliente.isPersonAccount = isPersonAccount;
            cliente.isBusinessAccount = isBusinessAccount;

            for (FieldConfig config : displayConfigs) {
                if (String.isBlank(config.apiName)) {
                    continue;
                }

                if (!accountFields.containsKey(config.apiName)) {
                    continue;
                }

                if (config.onlyPersonAccount && !isPersonAccount) {
                    continue;
                }

                if (config.onlyBusinessAccount && !isBusinessAccount) {
                    continue;
                }

                cliente.displayFields.add(
                    new DisplayField(
                        config.label,
                        config.apiName,
                        getDisplayValue(acc, config.apiName)
                    )
                );
            }

            for (FieldConfig config : formConfigs) {
                if (String.isBlank(config.apiName)) {
                    continue;
                }

                if (!accountFields.containsKey(config.apiName)) {
                    continue;
                }

                if (config.onlyPersonAccount && !isPersonAccount) {
                    continue;
                }

                if (config.onlyBusinessAccount && !isBusinessAccount) {
                    continue;
                }

                cliente.formFields.add(buildFormField(acc, config, accountFields));
            }

            InitResponse response = new InitResponse();
            response.cliente = cliente;
            response.productObjectApiName = getFinancialAccountProductLookupObjectApiName();

            response.claseClienteOptions = getPicklistOptions(FinServ__FinancialAccountRole__c.SObjectType, 'FinServ__Role__c');

            if (response.claseClienteOptions.isEmpty()) {
                response.claseClienteOptions = getDefaultClaseClienteOptions();
            }

            response.relacionOptions = getPicklistOptions(FinServ__FinancialAccountRole__c.SObjectType, 'FAR_Relacion__c');
            response.firmanteOptions = getPicklistOptions(FinServ__FinancialAccountRole__c.SObjectType, 'FAR_Firmante__c');
            response.codigoOptions = getPicklistOptions(FinServ__FinancialAccountRole__c.SObjectType, 'FAR_LegacyLinkedCode__c');

            if (response.relacionOptions.isEmpty()) {
                response.relacionOptions = getDefaultRelacionOptions();
            }

            if (response.firmanteOptions.isEmpty()) {
                response.firmanteOptions = getDefaultFirmanteOptions();
            }

            if (response.codigoOptions.isEmpty()) {
                response.codigoOptions = getDefaultCodigoOptions();
            }

            if (financialAccountId != null) {
                response.vinculadosExistentes = getExistingLinkedClients(financialAccountId);
            }

            System.debug('FinancialAccountCustomCreateController.getInitialData | productObjectApiName: ' + response.productObjectApiName);
            System.debug('FinancialAccountCustomCreateController.getInitialData | Fin');

            return response;

        } catch (BusinessException e) {
            System.debug('FinancialAccountCustomCreateController.getInitialData | BusinessException: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());

        } catch (Exception e) {
            System.debug('FinancialAccountCustomCreateController.getInitialData | Error: ' + e.getMessage());
            System.debug('FinancialAccountCustomCreateController.getInitialData | StackTrace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error al obtener información del cliente: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static ProductCreationFormResponse saveFormData(ProductCreationFormRequest request) {
        System.debug('FinancialAccountCustomCreateController.saveFormData | Inicio');
        System.debug('FinancialAccountCustomCreateController.saveFormData | request: ' + JSON.serialize(request));

        try {
            validateRequest(request);

            Id recordTypeId = getFinancialAccountRecordTypeId(request.recordTypeDeveloperName);

            updateClientData(request);

            validateClientsCreatedInCore(request);

            Id financialAccountId = createOrUpdateFinancialAccount(request, recordTypeId);

            deleteMarkedLinkedClients(request.vinculados);

            createLinkedClients(financialAccountId, request.vinculados);

            /*
            * No se llama directamente a wsCreacionProd_FSC desde el controller.
            * La creación en core se dispara desde FinancialAccountTrigger.afterInsert
            * mediante FinancialAccountCoreCreationQueueable.
            * Esto evita duplicar la creación del producto en el core.
            */
            // System.debug('FinancialAccountCustomCreateController.saveFormData | Llamando integración wsCreacionProd_FSC con financialAccountId: ' + financialAccountId);
            // wsCreacionProd_FSC.Future_creacionProdCA_CC_CF(financialAccountId);

            ProductCreationFormResponse response = new ProductCreationFormResponse();
            response.success = true;
            response.message = 'Producto financiero creado en Salesforce. La creación en core será procesada automáticamente.';
            response.recordTypeId = recordTypeId;
            response.productId = request.productId;
            response.financialAccountId = financialAccountId;
            response.recordTypeDeveloperName = request.recordTypeDeveloperName;
            response.integrationMessage = 'La creación en core será procesada por el trigger del producto financiero.';
            response.requestPreview = JSON.serializePretty(request);

            System.debug('FinancialAccountCustomCreateController.saveFormData | FinancialAccountId: ' + financialAccountId);
            System.debug('FinancialAccountCustomCreateController.saveFormData | Request preview: ' + response.requestPreview);
            System.debug('FinancialAccountCustomCreateController.saveFormData | Fin');

            return response;

        } catch (BusinessException e) {
            System.debug('FinancialAccountCustomCreateController.saveFormData | BusinessException: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());

        } catch (DmlException e) {
            String dmlMessage = getDmlExceptionMessage(e);
            System.debug('FinancialAccountCustomCreateController.saveFormData | DmlException: ' + dmlMessage);
            System.debug('FinancialAccountCustomCreateController.saveFormData | StackTrace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error al guardar el producto financiero: ' + dmlMessage);

        } catch (Exception e) {
            System.debug('FinancialAccountCustomCreateController.saveFormData | Error: ' + e.getMessage());
            System.debug('FinancialAccountCustomCreateController.saveFormData | StackTrace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error al crear el producto financiero: ' + e.getMessage());
        }
    }

    private static void validateRequest(ProductCreationFormRequest request) {
        System.debug('FinancialAccountCustomCreateController.validateRequest | Inicio');

        if (request == null) {
            throw new BusinessException('No se recibió información del formulario.');
        }

        if (request.accountId == null) {
            throw new BusinessException('No se recibió el Id del cliente.');
        }

        if (String.isBlank(request.recordTypeDeveloperName)) {
            throw new BusinessException('Debe seleccionar el tipo de producto financiero.');
        }

        if (request.productId == null) {
            throw new BusinessException('Debe seleccionar el producto financiero.');
        }

        if (request.formFields != null) {
            for (FieldValueRequest fieldValue : request.formFields) {
                if (String.isBlank(fieldValue.apiName)) {
                    throw new BusinessException('Existe un campo del formulario sin API Name.');
                }
            }
        }

        if (request.vinculados != null) {
            for (LinkedClientRequest vinculado : request.vinculados) {
                if (vinculado == null || vinculado.markedForDelete == true) {
                    continue;
                }

                if (vinculado.clienteVinculadoId == null) {
                    throw new BusinessException('Existe un vinculado sin cliente seleccionado.');
                }

                if (String.isBlank(vinculado.claseCliente)) {
                    throw new BusinessException('Existe un vinculado sin clase de cliente.');
                }

                if (String.isBlank(vinculado.relacion)) {
                    throw new BusinessException('Existe un vinculado sin relación.');
                }

                if (String.isBlank(vinculado.firmante)) {
                    throw new BusinessException('Existe un vinculado sin valor de firmante.');
                }

                if (String.isBlank(vinculado.codigo)) {
                    throw new BusinessException('Existe un vinculado sin código.');
                }
            }
        }

        System.debug('FinancialAccountCustomCreateController.validateRequest | Fin');
    }

    private static void validateClientsCreatedInCore(ProductCreationFormRequest request) {
        System.debug('FinancialAccountCustomCreateController.validateClientsCreatedInCore | Inicio');

        Set<Id> accountIds = new Set<Id>();

        if (request.accountId != null) {
            accountIds.add(request.accountId);
        }

        if (request.vinculados != null) {
            for (LinkedClientRequest vinculado : request.vinculados) {
                if (vinculado == null || vinculado.markedForDelete == true) {
                    continue;
                }

                if (vinculado.clienteVinculadoId != null) {
                    accountIds.add(vinculado.clienteVinculadoId);
                }
            }
        }

        if (accountIds.isEmpty()) {
            throw new BusinessException('No se encontraron clientes para validar en core.');
        }

        List<Account> accounts = [
            SELECT Id,
                   Name,
                   ACC_CIF__c,
                   Resultado_de_la_Integracion__c
            FROM Account
            WHERE Id IN :accountIds
        ];

        Map<Id, Account> accountsById = new Map<Id, Account>(accounts);
        String expectedResult = 'Registro creado correctamente en el core.';

        for (Id accountId : accountIds) {
            if (!accountsById.containsKey(accountId)) {
                throw new BusinessException('No se encontró uno de los clientes seleccionados para validar en core.');
            }

            Account acc = accountsById.get(accountId);
            String integrationResult = acc.Resultado_de_la_Integracion__c;

            System.debug('FinancialAccountCustomCreateController.validateClientsCreatedInCore | Account: ' + acc.Id);
            System.debug('FinancialAccountCustomCreateController.validateClientsCreatedInCore | Name: ' + acc.Name);
            System.debug('FinancialAccountCustomCreateController.validateClientsCreatedInCore | ACC_CIF__c: ' + acc.ACC_CIF__c);
            System.debug('FinancialAccountCustomCreateController.validateClientsCreatedInCore | Resultado_de_la_Integracion__c: ' + integrationResult);

            if (String.isBlank(integrationResult) || integrationResult.trim() != expectedResult) {
                throw new BusinessException(
                    'El cliente "' + acc.Name + '" debe existir en el core bancario para poder ser ingresado como vinculado.'
                );
            }

            if (String.isBlank(acc.ACC_CIF__c)) {
                throw new BusinessException(
                    'El cliente "' + acc.Name + '" no tiene CIF. Debe estar creado correctamente en el core antes de asociarlo al producto.'
                );
            }
        }

        System.debug('FinancialAccountCustomCreateController.validateClientsCreatedInCore | Fin');
    }

    private static Id getFinancialAccountRecordTypeId(String recordTypeDeveloperName) {
        System.debug('FinancialAccountCustomCreateController.getFinancialAccountRecordTypeId | recordTypeDeveloperName: ' + recordTypeDeveloperName);

        Map<String, Schema.RecordTypeInfo> rtMap =
            Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName();

        if (!rtMap.containsKey(recordTypeDeveloperName)) {
            List<String> availableRecordTypes = new List<String>();
            availableRecordTypes.addAll(rtMap.keySet());
            availableRecordTypes.sort();

            System.debug('FinancialAccountCustomCreateController.getFinancialAccountRecordTypeId | RecordTypes disponibles: ' + availableRecordTypes);

            throw new BusinessException(
                'No existe el Record Type indicado para Cuenta Financiera: ' +
                recordTypeDeveloperName +
                '. Record Types disponibles: ' +
                String.join(availableRecordTypes, ', ')
            );
        }

        return rtMap.get(recordTypeDeveloperName).getRecordTypeId();
    }

    private static String getFinancialAccountProductLookupObjectApiName() {
        System.debug('FinancialAccountCustomCreateController.getFinancialAccountProductLookupObjectApiName | Inicio');

        Map<String, Schema.SObjectField> fields =
            FinServ__FinancialAccount__c.SObjectType.getDescribe().fields.getMap();

        if (!fields.containsKey('FIN_Producto__c')) {
            System.debug('FinancialAccountCustomCreateController.getFinancialAccountProductLookupObjectApiName | No existe FIN_Producto__c');
            return null;
        }

        Schema.DescribeFieldResult describeResult =
            fields.get('FIN_Producto__c').getDescribe();

        if (describeResult.getReferenceTo() == null || describeResult.getReferenceTo().isEmpty()) {
            System.debug('FinancialAccountCustomCreateController.getFinancialAccountProductLookupObjectApiName | FIN_Producto__c no es lookup');
            return null;
        }

        String objectApiName = describeResult.getReferenceTo()[0].getDescribe().getName();

        System.debug('FinancialAccountCustomCreateController.getFinancialAccountProductLookupObjectApiName | objectApiName: ' + objectApiName);

        return objectApiName;
    }

    private static void updateClientData(ProductCreationFormRequest request) {
        System.debug('FinancialAccountCustomCreateController.updateClientData | Inicio');

        if (request.formFields == null || request.formFields.isEmpty()) {
            System.debug('FinancialAccountCustomCreateController.updateClientData | No hay campos editables para actualizar');
            return;
        }

        Map<String, Schema.SObjectField> accountFields = Account.SObjectType.getDescribe().fields.getMap();

        Account accToUpdate = new Account(Id = request.accountId);
        Boolean hasFieldToUpdate = false;

        for (FieldValueRequest fieldValue : request.formFields) {
            if (String.isBlank(fieldValue.apiName)) {
                continue;
            }

            if (!accountFields.containsKey(fieldValue.apiName)) {
                System.debug('FinancialAccountCustomCreateController.updateClientData | Campo no existe en Account: ' + fieldValue.apiName);
                continue;
            }

            Schema.DescribeFieldResult describeResult = accountFields.get(fieldValue.apiName).getDescribe();

            Object convertedValue = convertValueByFieldType(fieldValue.value, describeResult);

            accToUpdate.put(fieldValue.apiName, convertedValue);
            hasFieldToUpdate = true;
        }

        if (hasFieldToUpdate) {
            System.debug('FinancialAccountCustomCreateController.updateClientData | Update Account: ' + accToUpdate);
            update accToUpdate;
        }

        System.debug('FinancialAccountCustomCreateController.updateClientData | Fin');
    }

    private static Id createOrUpdateFinancialAccount(ProductCreationFormRequest request, Id recordTypeId) {
        System.debug('FinancialAccountCustomCreateController.createOrUpdateFinancialAccount | Inicio');
        System.debug('FinancialAccountCustomCreateController.createOrUpdateFinancialAccount | financialAccountId: ' + request.financialAccountId);
        System.debug('FinancialAccountCustomCreateController.createOrUpdateFinancialAccount | recordTypeId: ' + recordTypeId);
        System.debug('FinancialAccountCustomCreateController.createOrUpdateFinancialAccount | productId: ' + request.productId);
        System.debug('FinancialAccountCustomCreateController.createOrUpdateFinancialAccount | currentUserId: ' + UserInfo.getUserId());

        FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c();

        if (request.financialAccountId != null) {
            financialAccount.Id = request.financialAccountId;
        }

        financialAccount.RecordTypeId = recordTypeId;
        financialAccount.FinServ__PrimaryOwner__c = request.accountId;
        financialAccount.FIN_Producto__c = request.productId;
        financialAccount.FIN_Ejecutivo__c = UserInfo.getUserId();
        financialAccount.OwnerId = UserInfo.getUserId();

        if (request.financialAccountId == null) {
            financialAccount.Name = 'Producto financiero pendiente';
            System.debug('FinancialAccountCustomCreateController.createOrUpdateFinancialAccount | Insert Financial Account: ' + financialAccount);
            insert financialAccount;
        } else {
            System.debug('FinancialAccountCustomCreateController.createOrUpdateFinancialAccount | Update Financial Account: ' + financialAccount);
            update financialAccount;
        }

        System.debug('FinancialAccountCustomCreateController.createOrUpdateFinancialAccount | Fin | Id: ' + financialAccount.Id);
        return financialAccount.Id;
    }

    private static void createLinkedClients(Id financialAccountId, List<LinkedClientRequest> vinculados) {
        System.debug('FinancialAccountCustomCreateController.createLinkedClients | Inicio');
        System.debug('FinancialAccountCustomCreateController.createLinkedClients | financialAccountId: ' + financialAccountId);

        if (financialAccountId == null) {
            throw new BusinessException('No se pudo identificar la cuenta financiera para crear vinculados.');
        }

        if (vinculados == null || vinculados.isEmpty()) {
            System.debug('FinancialAccountCustomCreateController.createLinkedClients | No hay vinculados para crear');
            return;
        }

        List<FinServ__FinancialAccountRole__c> rolesToInsert = new List<FinServ__FinancialAccountRole__c>();

        for (LinkedClientRequest linkedClient : vinculados) {
            if (linkedClient == null) {
                continue;
            }

            if (linkedClient.markedForDelete == true) {
                continue;
            }

            if (linkedClient.existingRecord == true && linkedClient.roleId != null) {
                continue;
            }

            FinServ__FinancialAccountRole__c roleRecord = new FinServ__FinancialAccountRole__c();
            roleRecord.FinServ__FinancialAccount__c = financialAccountId;
            roleRecord.FinServ__RelatedAccount__c = linkedClient.clienteVinculadoId;
            roleRecord.FinServ__Role__c = linkedClient.claseCliente;
            roleRecord.FAR_Relacion__c = linkedClient.relacion;
            roleRecord.FAR_Firmante__c = linkedClient.firmante;
            roleRecord.FAR_LegacyLinkedCode__c = linkedClient.codigo;

            rolesToInsert.add(roleRecord);
        }

        if (!rolesToInsert.isEmpty()) {
            System.debug('FinancialAccountCustomCreateController.createLinkedClients | Insert Roles: ' + rolesToInsert);
            insert rolesToInsert;
        }

        System.debug('FinancialAccountCustomCreateController.createLinkedClients | Fin');
    }

    private static Object convertValueByFieldType(String value, Schema.DescribeFieldResult describeResult) {
        if (String.isBlank(value)) {
            if (describeResult.getType() == Schema.DisplayType.Boolean) {
                return false;
            }

            return null;
        }

        Schema.DisplayType fieldType = describeResult.getType();

        if (fieldType == Schema.DisplayType.Date) {
            return Date.valueOf(value);
        }

        if (fieldType == Schema.DisplayType.DateTime) {
            return Datetime.valueOf(value);
        }

        if (fieldType == Schema.DisplayType.Boolean) {
            return value == 'true' || value == 'TRUE' || value == '1';
        }

        if (fieldType == Schema.DisplayType.Integer) {
            return Integer.valueOf(value);
        }

        if (fieldType == Schema.DisplayType.Double ||
            fieldType == Schema.DisplayType.Currency ||
            fieldType == Schema.DisplayType.Percent) {
            return Decimal.valueOf(value);
        }

        if (fieldType == Schema.DisplayType.Reference) {
            return (Id) value;
        }

        return value;
    }

    private static void deleteMarkedLinkedClients(List<LinkedClientRequest> vinculados) {
        System.debug('FinancialAccountCustomCreateController.deleteMarkedLinkedClients | Inicio');

        if (vinculados == null || vinculados.isEmpty()) {
            System.debug('FinancialAccountCustomCreateController.deleteMarkedLinkedClients | No hay vinculados');
            return;
        }

        List<FinServ__FinancialAccountRole__c> rolesToDelete = new List<FinServ__FinancialAccountRole__c>();

        for (LinkedClientRequest linkedClient : vinculados) {
            if (linkedClient.existingRecord == true &&
                linkedClient.markedForDelete == true &&
                linkedClient.roleId != null) {
                rolesToDelete.add(new FinServ__FinancialAccountRole__c(Id = linkedClient.roleId));
            }
        }

        if (!rolesToDelete.isEmpty()) {
            System.debug('FinancialAccountCustomCreateController.deleteMarkedLinkedClients | Delete Roles: ' + rolesToDelete);
            delete rolesToDelete;
        }

        System.debug('FinancialAccountCustomCreateController.deleteMarkedLinkedClients | Fin');
    }

    private static List<LinkedClientResponse> getExistingLinkedClients(Id financialAccountId) {
        System.debug('FinancialAccountCustomCreateController.getExistingLinkedClients | financialAccountId: ' + financialAccountId);

        List<LinkedClientResponse> result = new List<LinkedClientResponse>();

        List<FinServ__FinancialAccountRole__c> roles = [
            SELECT Id,
                   FinServ__RelatedAccount__c,
                   FinServ__RelatedAccount__r.Name,
                   FinServ__Role__c,
                   FAR_Relacion__c,
                   FAR_Firmante__c,
                   FAR_LegacyLinkedCode__c
            FROM FinServ__FinancialAccountRole__c
            WHERE FinServ__FinancialAccount__c = :financialAccountId
            ORDER BY CreatedDate ASC
        ];

        for (FinServ__FinancialAccountRole__c roleRecord : roles) {
            LinkedClientResponse linkedClient = new LinkedClientResponse();
            linkedClient.roleId = roleRecord.Id;
            linkedClient.clienteVinculadoId = roleRecord.FinServ__RelatedAccount__c;
            linkedClient.clienteVinculadoName = roleRecord.FinServ__RelatedAccount__r == null ? '' : roleRecord.FinServ__RelatedAccount__r.Name;
            linkedClient.claseCliente = roleRecord.FinServ__Role__c;
            linkedClient.relacion = roleRecord.FAR_Relacion__c;
            linkedClient.firmante = roleRecord.FAR_Firmante__c;
            linkedClient.codigo = roleRecord.FAR_LegacyLinkedCode__c;
            linkedClient.existingRecord = true;
            linkedClient.markedForDelete = false;

            result.add(linkedClient);
        }

        return result;
    }

    private static FormField buildFormField(Account acc, FieldConfig config, Map<String, Schema.SObjectField> accountFields) {
        FormField formField = new FormField();
        formField.label = config.label;
        formField.apiName = config.apiName;
        formField.required = config.required;

        Schema.DescribeFieldResult describeResult = accountFields.get(config.apiName).getDescribe();
        Schema.DisplayType displayType = describeResult.getType();

        formField.fieldType = String.valueOf(displayType);
        formField.value = getRawStringValue(acc, config.apiName);

        if (displayType == Schema.DisplayType.Picklist) {
            formField.isPicklist = true;
            formField.options = getPicklistOptions(Account.SObjectType, config.apiName);
        } else if (displayType == Schema.DisplayType.Reference) {
            formField.isLookup = true;
            formField.objectApiName = getLookupObjectApiName(Account.SObjectType, config.apiName);
        } else if (displayType == Schema.DisplayType.Date) {
            formField.isDate = true;
        } else if (displayType == Schema.DisplayType.Boolean) {
            formField.isCheckbox = true;
        } else {
            formField.isText = true;
        }

        return formField;
    }

    private static String getRawStringValue(SObject record, String fieldName) {
        Map<String, Schema.SObjectField> fields = record.getSObjectType().getDescribe().fields.getMap();

        if (!fields.containsKey(fieldName)) {
            return null;
        }

        Object value = record.get(fieldName);

        if (value == null) {
            return null;
        }

        if (value instanceof Date) {
            return String.valueOf((Date) value);
        }

        if (value instanceof Boolean) {
            return String.valueOf((Boolean) value);
        }

        return String.valueOf(value);
    }

    private static String getDisplayValue(SObject record, String fieldName) {
        Map<String, Schema.SObjectField> fields = record.getSObjectType().getDescribe().fields.getMap();

        if (!fields.containsKey(fieldName)) {
            return '';
        }

        Object value = record.get(fieldName);

        if (value == null) {
            return '';
        }

        Schema.DescribeFieldResult describeResult = fields.get(fieldName).getDescribe();

        if (describeResult.getType() == Schema.DisplayType.Picklist) {
            String stringValue = String.valueOf(value);

            for (Schema.PicklistEntry entry : describeResult.getPicklistValues()) {
                if (entry.getValue() == stringValue) {
                    return entry.getLabel();
                }
            }
        }

        if (describeResult.getType() == Schema.DisplayType.Date && value instanceof Date) {
            Date dateValue = (Date) value;
            return String.valueOf(dateValue.day()) + '/' + String.valueOf(dateValue.month()) + '/' + String.valueOf(dateValue.year());
        }

        if (describeResult.getType() == Schema.DisplayType.Reference) {
            return String.valueOf(value);
        }

        return String.valueOf(value);
    }

    private static String getLookupObjectApiName(Schema.SObjectType objectType, String fieldName) {
        Map<String, Schema.SObjectField> fields = objectType.getDescribe().fields.getMap();

        if (!fields.containsKey(fieldName)) {
            return null;
        }

        Schema.DescribeFieldResult describeResult = fields.get(fieldName).getDescribe();

        if (describeResult.getReferenceTo() == null || describeResult.getReferenceTo().isEmpty()) {
            return null;
        }

        return describeResult.getReferenceTo()[0].getDescribe().getName();
    }

    private static List<PicklistOption> getPicklistOptions(Schema.SObjectType objectType, String fieldName) {
        List<PicklistOption> options = new List<PicklistOption>();

        Map<String, Schema.SObjectField> fields = objectType.getDescribe().fields.getMap();

        if (!fields.containsKey(fieldName)) {
            return options;
        }

        Schema.DescribeFieldResult describeResult = fields.get(fieldName).getDescribe();

        if (describeResult.getType() != Schema.DisplayType.Picklist) {
            return options;
        }

        for (Schema.PicklistEntry entry : describeResult.getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
            }
        }

        return options;
    }

    private static List<PicklistOption> getDefaultClaseClienteOptions() {
        return new List<PicklistOption>{
            new PicklistOption('Principal', 'Principal'),
            new PicklistOption('Vinculado', 'Vinculado')
        };
    }

    private static List<PicklistOption> getDefaultRelacionOptions() {
        return new List<PicklistOption>{
            new PicklistOption('Obligatorio', 'Obligatorio'),
            new PicklistOption('Opcional', 'Opcional')
        };
    }

    private static List<PicklistOption> getDefaultFirmanteOptions() {
        return new List<PicklistOption>{
            new PicklistOption('Es Firmante', 'Es Firmante'),
            new PicklistOption('No es Firmante', 'No es Firmante')
        };
    }

    private static List<PicklistOption> getDefaultCodigoOptions() {
        return new List<PicklistOption>{
            new PicklistOption('N/A', 'N/A')
        };
    }

    private static String getDmlExceptionMessage(DmlException e) {
        List<String> messages = new List<String>();

        for (Integer i = 0; i < e.getNumDml(); i++) {
            messages.add(e.getDmlMessage(i));
        }

        if (messages.isEmpty()) {
            return e.getMessage();
        }

        return String.join(messages, ' | ');
    }

    private class FieldConfig {
        public String label;
        public String apiName;
        public Boolean required;
        public Boolean onlyPersonAccount;
        public Boolean onlyBusinessAccount;

        public FieldConfig(String label, String apiName, Boolean required, Boolean onlyPersonAccount, Boolean onlyBusinessAccount) {
            this.label = label;
            this.apiName = apiName;
            this.required = required;
            this.onlyPersonAccount = onlyPersonAccount;
            this.onlyBusinessAccount = onlyBusinessAccount;
        }
    }

    private static List<FieldConfig> getDisplayFieldConfigs(Map<String, Schema.SObjectField> accountFields) {
        List<FieldConfig> configs = new List<FieldConfig>();

        configs.add(new FieldConfig('Nombre corto/comercial', 'Name', false, false, true));
        configs.add(new FieldConfig('Razón/denominación social', 'Name', false, false, true));
        configs.add(new FieldConfig('R.N.C', 'ACC_RNC__c', false, false, true));
        configs.add(new FieldConfig('Fecha de fundación', getFirstExistingField(accountFields, new List<String>{
            'ACC_Fecha_Fundacion__c',
            'ACC_Fecha_de_Fundacion__c'
        }), false, false, true));
        configs.add(new FieldConfig('Nacionalidad', 'ACC_Nacionalidad__c', false, false, true));
        configs.add(new FieldConfig('Tipo de persona', 'ACC_Traduccion_tipo_persona__c', false, false, true));
        configs.add(new FieldConfig('Tipo de organización', 'ACC_Tipo_Organizacion__c', false, false, true));
        configs.add(new FieldConfig('Relación con el exterior', 'ACC_Relacion_Exterior__c', false, false, true));
        configs.add(new FieldConfig('Tipo de depositante', 'ACC_Tipo_Depositante__c', false, false, true));
        configs.add(new FieldConfig('Código depositante', 'ACC_Codigo_Depositante__c', false, false, true));

        configs.add(new FieldConfig('Tipo de identificación', 'ACC_TipoIdentificacion__c', false, true, false));
        configs.add(new FieldConfig('N° de identificación', 'ACC_NumIdentificacion__c', false, true, false));
        configs.add(new FieldConfig('Primer Nombre', 'FirstName', false, true, false));
        configs.add(new FieldConfig('Segundo Nombre', 'MiddleName', false, true, false));
        configs.add(new FieldConfig('Apellidos', 'LastName', false, true, false));
        configs.add(new FieldConfig('Sufijo', 'Suffix', false, true, false));
        configs.add(new FieldConfig('Fecha de Nacimiento', 'PersonBirthdate', false, true, false));
        configs.add(new FieldConfig('Código de persona', 'ACC_Codigo_Persona_PF__c', false, true, false));
        configs.add(new FieldConfig('Género', 'ACC_Genero__c', false, true, false));
        configs.add(new FieldConfig('Estado Civil', 'ACC_Estado_Civil__c', false, true, false));
        configs.add(new FieldConfig('Tipo de Cliente', 'ACC_Traduccion_tipo_cliente__c', false, true, false));
        configs.add(new FieldConfig('Tipo de persona', 'ACC_Traduccion_tipo_persona__c', false, true, false));

        return cleanConfigs(configs);
    }

    private static List<FieldConfig> getFormFieldConfigs(Map<String, Schema.SObjectField> accountFields) {
        List<FieldConfig> configs = new List<FieldConfig>();

        configs.add(new FieldConfig('Fecha de cierre fiscal', getFirstExistingField(accountFields, new List<String>{
            'ACC_Fecha_Cierre_Fiscal__c',
            'ACC_Fecha_de_cierre_fiscal__c'
        }), false, false, true));
        configs.add(new FieldConfig('Actividad económica', 'ACC_Actividad_Economica__c', true, false, true));
        configs.add(new FieldConfig('Tipo de actividad', 'ACC_Tipo_Actividad__c', true, false, true));
        configs.add(new FieldConfig('Tipo de sector', 'ACC_Tipo_Sector__c', true, false, true));

        configs.add(new FieldConfig('N° Dependientes', getFirstExistingField(accountFields, new List<String>{
            'ACC_Numero_Dependientes__c',
            'ACC_N_Dependientes__c',
            'NumberOfDependents'
        }), true, true, false));

        configs.add(new FieldConfig('País de Nacimiento', getFirstExistingField(accountFields, new List<String>{
            'ACC_Pais_Nacimiento__c',
            'FIN_Pais_Nacimiento__c'
        }), false, true, false));

        configs.add(new FieldConfig('Provincia de Nacimiento', getFirstExistingField(accountFields, new List<String>{
            'ACC_Provincia_Nacimiento__c',
            'FIN_Provincia_Nacimiento__c'
        }), false, true, false));

        configs.add(new FieldConfig('Ciudad de Nacimiento', getFirstExistingField(accountFields, new List<String>{
            'ACC_Ciudad_Nacimiento__c',
            'FIN_Ciudad_Nacimiento__c'
        }), false, true, false));

        configs.add(new FieldConfig('Nacionalidad', 'ACC_Nacionalidad__c', true, true, false));
        configs.add(new FieldConfig('Residencia en REP. Dom.', 'ACC_Residencia_Rep_Dom__c', true, true, false));

        configs.add(new FieldConfig('Posee otra nacionalidad', getFirstExistingField(accountFields, new List<String>{
            'ACC_Posee_Otra_Nacionalidad__c',
            'ACC_Posee_otra_nacionalidad__c'
        }), false, true, false));

        configs.add(new FieldConfig('Otra Nacionalidad', 'ACC_Otra_Nacionalidad__c', false, true, false));

        configs.add(new FieldConfig('Posee residencia en otro país', getFirstExistingField(accountFields, new List<String>{
            'ACC_Posee_Residencia_Otro_Pais__c',
            'ACC_Posee_residencia_en_otro_pais__c'
        }), false, true, false));

        configs.add(new FieldConfig('País de residencia legal', 'ACC_Pais_Residencia_Legal__c', true, true, false));

        configs.add(new FieldConfig('Tipo de actividad', 'ACC_Tipo_Actividad__c', true, true, false));
        configs.add(new FieldConfig('Actividad económica SIB', 'ACC_Actividad_Economica__c', true, true, false));
        configs.add(new FieldConfig('Tipo de Sector', 'ACC_Tipo_Sector__c', true, true, false));
        configs.add(new FieldConfig('Motivo de acercamiento al banco', 'ACC_Motivo_Acercamiento__c', true, true, false));
        configs.add(new FieldConfig('Preferencias de correspondencia', 'ACC_Preferencias_Correspondencia__c', true, true, false));
        configs.add(new FieldConfig('Tipo de cliente', 'ACC_Traduccion_tipo_cliente__c', true, true, false));

        configs.add(new FieldConfig('Género - Identificación', getFirstExistingField(accountFields, new List<String>{
            'ACC_Genero_Identificacion__c',
            'FIN_Genero_Identificacion__c'
        }), false, true, false));

        configs.add(new FieldConfig('Tipo de persona', 'ACC_Traduccion_tipo_persona__c', false, true, false));
        configs.add(new FieldConfig('Es empleado Vimenca', 'ACC_EsEmpleado_Vimenca__c', false, true, false));

        return cleanConfigs(configs);
    }

    private static List<FieldConfig> cleanConfigs(List<FieldConfig> configs) {
        List<FieldConfig> cleanList = new List<FieldConfig>();

        for (FieldConfig config : configs) {
            if (String.isBlank(config.apiName)) {
                continue;
            }

            cleanList.add(config);
        }

        return cleanList;
    }

    private static String getFirstExistingField(Map<String, Schema.SObjectField> fields, List<String> candidates) {
        for (String candidate : candidates) {
            if (fields.containsKey(candidate)) {
                return candidate;
            }
        }

        return null;
    }
}