@IsTest
private class FinAccountCoreValidationTest {
    @IsTest
    static void reportsRequiredFinancialAccountDataBeforeAnyDml() {
        FinancialAccountCoreValidationService.ValidationResult missingAccount =
            FinancialAccountCoreValidationService.validateBeforeInsert(null);
        FinancialAccountCoreValidationService.ValidationResult missingRecordType =
            FinancialAccountCoreValidationService.validateBeforeInsert(
                new FinServ__FinancialAccount__c()
            );
        Id checkingAccountRecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c
            .getRecordTypeInfosByDeveloperName().get('CheckingAccount').getRecordTypeId();
        FinancialAccountCoreValidationService.ValidationResult missingOwner =
            FinancialAccountCoreValidationService.validateBeforeInsert(
                new FinServ__FinancialAccount__c(RecordTypeId = checkingAccountRecordTypeId)
            );
        FinancialAccountCoreValidationService.ValidationResult missingStoredAccount =
            FinancialAccountCoreValidationService.validate('a0k000000000001AAA');

        System.assertEquals(false, missingAccount.isValid);
        System.assertEquals(false, missingRecordType.isValid);
        System.assertEquals(false, missingOwner.isValid);
        System.assertEquals(false, missingStoredAccount.isValid);
    }

    @IsTest
    static void reportsAdditionalEarlyValidationFailures() {
        Id checkingAccountRecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c
            .getRecordTypeInfosByDeveloperName().get('CheckingAccount').getRecordTypeId();
        Id unsupportedRecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c
            .getRecordTypeInfosByDeveloperName().get('CreditCard').getRecordTypeId();
        Id missingAccountId = Id.valueOf('001000000000001');

        FinancialAccountCoreValidationService.ValidationResult unsupportedRecordType =
            FinancialAccountCoreValidationService.validateBeforeInsert(
                new FinServ__FinancialAccount__c(RecordTypeId = unsupportedRecordTypeId)
            );
        FinancialAccountCoreValidationService.ValidationResult missingProduct =
            FinancialAccountCoreValidationService.validateBeforeInsert(
                new FinServ__FinancialAccount__c(
                    RecordTypeId = checkingAccountRecordTypeId,
                    FinServ__PrimaryOwner__c = missingAccountId
                )
            );
        FinancialAccountCoreValidationService.ValidationResult missingExecutive =
            FinancialAccountCoreValidationService.validateBeforeInsert(
                new FinServ__FinancialAccount__c(
                    RecordTypeId = checkingAccountRecordTypeId,
                    FinServ__PrimaryOwner__c = missingAccountId,
                    FIN_Producto__c = UserInfo.getUserId()
                )
            );
        FinancialAccountCoreValidationService.ValidationResult missingOwnerRecord =
            FinancialAccountCoreValidationService.validateBeforeInsert(
                new FinServ__FinancialAccount__c(
                    RecordTypeId = checkingAccountRecordTypeId,
                    FinServ__PrimaryOwner__c = missingAccountId,
                    FIN_Producto__c = UserInfo.getUserId(),
                    FIN_Ejecutivo__c = UserInfo.getUserId()
                )
            );
        String missingFinancialAccountId = String.valueOf(
            Schema.SObjectType.FinServ__FinancialAccount__c.getKeyPrefix()
        ) + '000000000000';
        FinancialAccountCoreValidationService.ValidationResult missingStoredAccount =
            FinancialAccountCoreValidationService.validate(Id.valueOf(missingFinancialAccountId));

        System.assertEquals(false, unsupportedRecordType.isValid);
        System.assertEquals(false, missingProduct.isValid);
        System.assertEquals(false, missingExecutive.isValid);
        System.assertEquals(false, missingOwnerRecord.isValid);
        System.assertEquals(false, missingStoredAccount.isValid);
    }

    @IsTest
    static void acceptsACompleteFinancialAccountBeforeInsert() {
        List<User> coreUsers = [
            SELECT Id
            FROM User
            WHERE IsActive = true
            AND USE_Codigo__c != null
            AND USE_Oficina__c != null
            LIMIT 1
        ];
        System.assert(!coreUsers.isEmpty());
        User coreUser = coreUsers[0];

        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        Account ownerAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount').getRecordTypeId(),
            FirstName = 'Core',
            LastName = 'Owner',
            ACC_CIF__c = 'CIF-CORE-TEST',
            ACC_TipoIdentificacion__c = 'Cédula',
            ACC_NumIdentificacion__c = '00108803777'
        );
        insert ownerAccount;

        ContactPointAddress primaryAddress = TestDataFactory_FSC.createDirecciones(
            new List<Account>{ ownerAccount }
        )[0];
        primaryAddress.IsPrimary = true;
        primaryAddress.AddressType = 'RESIDENCIA';
        update primaryAddress;
        insert new ContactPointPhone(
            ParentId = ownerAccount.Id,
            IsPrimary = true,
            AreaCode = '809',
            TelephoneNumber = '8095550105',
            CPP_Tipo__c = 'TELÉFONO FIJO',
            CPP_Telefonica__c = 'Claro'
        );

        Matriz_de_producto__c product = new Matriz_de_producto__c(
            Name = 'Producto validacion Core',
            PRO_Codigo_de_producto__c = 'CORE-01'
        );
        insert product;
        FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
            RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c
                .getRecordTypeInfosByDeveloperName().get('CheckingAccount').getRecordTypeId(),
            FinServ__PrimaryOwner__c = ownerAccount.Id,
            FIN_Producto__c = product.Id,
            FIN_Ejecutivo__c = coreUser.Id
        );

        FinancialAccountCoreValidationService.ValidationResult result;
        System.runAs(coreUser) {
            Test.startTest();
            result = FinancialAccountCoreValidationService.validateBeforeInsert(financialAccount);
            Test.stopTest();
        }

        System.assertEquals(true, result.isValid);
    }
}
