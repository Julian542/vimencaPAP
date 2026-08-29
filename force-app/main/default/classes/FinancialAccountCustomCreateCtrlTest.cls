@IsTest
private class FinancialAccountCustomCreateCtrlTest {
    private static Account createBusinessProspect() {
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'Financial form coverage',
            ACC_RNC__c = '131FINFORM',
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert account;
        return account;
    }

    @IsTest
    static void loadsInitialClientFormConfiguration() {
        Account account = createBusinessProspect();

        Test.startTest();
        FinancialAccountCustomCreateController.InitResponse response =
            FinancialAccountCustomCreateController.getInitialData(account.Id, null);
        Test.stopTest();

        System.assertEquals(account.Id, response.cliente.accountId);
        System.assertNotEquals(null, response.cliente.displayFields);
        System.assertNotEquals(null, response.cliente.formFields);
        System.assertNotEquals(null, response.claseClienteOptions);
    }

    @IsTest
    static void rejectsIncompleteAndUnsupportedSaveRequests() {
        Account account = createBusinessProspect();
        Integer rejected = 0;

        try {
            FinancialAccountCustomCreateController.saveFormData(null);
        } catch (AuraHandledException expected) {
            rejected++;
        }

        FinancialAccountCustomCreateController.ProductCreationFormRequest request =
            new FinancialAccountCustomCreateController.ProductCreationFormRequest();
        request.accountId = account.Id;
        request.productId = account.Id;
        request.recordTypeDeveloperName = 'RECORD_TYPE_INEXISTENTE';
        try {
            FinancialAccountCustomCreateController.saveFormData(request);
        } catch (AuraHandledException expected) {
            rejected++;
        }

        request.recordTypeDeveloperName = null;
        request.formFields = new List<FinancialAccountCustomCreateController.FieldValueRequest>{
            new FinancialAccountCustomCreateController.FieldValueRequest()
        };
        try {
            FinancialAccountCustomCreateController.saveFormData(request);
        } catch (AuraHandledException expected) {
            rejected++;
        }

        System.assertEquals(3, rejected);
    }

    @IsTest
    static void rejectsEachMissingLinkedClientValue() {
        Account account = createBusinessProspect();
        String financialAccountRecordType;
        for (String developerName : Schema.SObjectType.FinServ__FinancialAccount__c
            .getRecordTypeInfosByDeveloperName().keySet()) {
            financialAccountRecordType = developerName;
            break;
        }
        System.assertNotEquals(null, financialAccountRecordType);

        Integer rejected = 0;

        try {
            FinancialAccountCustomCreateController.getInitialData(null, null);
        } catch (AuraHandledException expected) {
            rejected++;
        }

        FinancialAccountCustomCreateController.ProductCreationFormRequest missingAccount =
            new FinancialAccountCustomCreateController.ProductCreationFormRequest();
        try {
            FinancialAccountCustomCreateController.saveFormData(missingAccount);
        } catch (AuraHandledException expected) {
            rejected++;
        }

        FinancialAccountCustomCreateController.ProductCreationFormRequest missingRecordType =
            new FinancialAccountCustomCreateController.ProductCreationFormRequest();
        missingRecordType.accountId = account.Id;
        try {
            FinancialAccountCustomCreateController.saveFormData(missingRecordType);
        } catch (AuraHandledException expected) {
            rejected++;
        }

        FinancialAccountCustomCreateController.ProductCreationFormRequest missingProduct =
            new FinancialAccountCustomCreateController.ProductCreationFormRequest();
        missingProduct.accountId = account.Id;
        missingProduct.recordTypeDeveloperName = financialAccountRecordType;
        try {
            FinancialAccountCustomCreateController.saveFormData(missingProduct);
        } catch (AuraHandledException expected) {
            rejected++;
        }

        for (Integer missingValueIndex = 0; missingValueIndex < 5; missingValueIndex++) {
            FinancialAccountCustomCreateController.LinkedClientRequest linkedClient =
                new FinancialAccountCustomCreateController.LinkedClientRequest();
            linkedClient.clienteVinculadoId = missingValueIndex == 0 ? null : account.Id;
            linkedClient.claseCliente = missingValueIndex == 1 ? null : 'TITULAR';
            linkedClient.relacion = missingValueIndex == 2 ? null : 'RELACION';
            linkedClient.firmante = missingValueIndex == 3 ? null : 'SI';
            linkedClient.codigo = missingValueIndex == 4 ? null : '001';

            FinancialAccountCustomCreateController.ProductCreationFormRequest invalidLinkedClient =
                new FinancialAccountCustomCreateController.ProductCreationFormRequest();
            invalidLinkedClient.accountId = account.Id;
            invalidLinkedClient.productId = account.Id;
            invalidLinkedClient.recordTypeDeveloperName = financialAccountRecordType;
            invalidLinkedClient.vinculados =
                new List<FinancialAccountCustomCreateController.LinkedClientRequest>{ linkedClient };

            try {
                FinancialAccountCustomCreateController.saveFormData(invalidLinkedClient);
            } catch (AuraHandledException expected) {
                rejected++;
            }
        }

        System.assertEquals(9, rejected);
    }

    @IsTest
    static void initializesPublicResponseWrappers() {
        FinancialAccountCustomCreateController.FormField formField =
            new FinancialAccountCustomCreateController.FormField();
        FinancialAccountCustomCreateController.ClientInfo client =
            new FinancialAccountCustomCreateController.ClientInfo();
        FinancialAccountCustomCreateController.InitResponse response =
            new FinancialAccountCustomCreateController.InitResponse();
        FinancialAccountCustomCreateController.PicklistOption option =
            new FinancialAccountCustomCreateController.PicklistOption('Label', 'VALUE');
        FinancialAccountCustomCreateController.DisplayField display =
            new FinancialAccountCustomCreateController.DisplayField('Label', 'Name', 'Value');

        System.assertEquals(0, formField.options.size());
        System.assertEquals(0, client.displayFields.size());
        System.assertEquals(0, response.vinculadosExistentes.size());
        System.assertEquals('VALUE', option.value);
        System.assertEquals('Label_Name', display.key);
    }

}
