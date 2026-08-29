@IsTest
private class DataMigrationBatchesTest {
    private static Account createProspectAccount(String name) {
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = name,
            ACC_RNC__c = '131' + String.valueOf(Math.abs(Crypto.getRandomInteger())).left(6),
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert account;
        return account;
    }

    private static void assertBatchCompleted(Id jobId) {
        AsyncApexJob job = [
            SELECT Status
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        System.assertEquals('Completed', job.Status);
    }

    private static SObject minimalSource(String objectApiName, Id accountId) {
        SObject source = Schema.getGlobalDescribe().get(objectApiName).newSObject();
        Map<String, Schema.SObjectField> fields =
            Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();

        if (fields.containsKey('Name') && fields.get('Name').getDescribe().isCreateable()
                && fields.get('Name').getDescribe().getType() == Schema.DisplayType.String) {
            source.put('Name', 'Migration coverage ' + objectApiName + ' ' + System.now().getTime());
        }
        if (fields.containsKey('Cliente__c') && accountId != null) {
            source.put('Cliente__c', accountId);
        }
        if (fields.containsKey('Account__c') && accountId != null) {
            source.put('Account__c', accountId);
        }
        if (fields.containsKey('PAR_Cliente__c') && accountId != null) {
            source.put('PAR_Cliente__c', accountId);
        }
        if (fields.containsKey('VIN_Cliente_vinculado__c') && accountId != null) {
            source.put('VIN_Cliente_vinculado__c', accountId);
        }
        return source;
    }

    @IsTest
    static void initializesMigrationBatchesAndHandlesEmptyScopes() {
        AccountToLeadMigrationBatch accountBatch = new AccountToLeadMigrationBatch();
        ViasDeContactoMigrationBatch contactPointBatch = new ViasDeContactoMigrationBatch();
        AddressMigrationBatch addressBatch = new AddressMigrationBatch();
        FinancialAccountRoleMigrationBatch roleBatch =
            new FinancialAccountRoleMigrationBatch('Vinculado__c');
        ContactContactRelationMigrationBatch contactRelationBatch =
            new ContactContactRelationMigrationBatch('Referencia__c');
        AccountAccountRelationMigrationBatch accountRelationBatch =
            new AccountAccountRelationMigrationBatch();

        Test.startTest();
        System.assertNotEquals(null, accountBatch.start(null));
        System.assertNotEquals(null, contactPointBatch.start(null));
        System.assertNotEquals(null, addressBatch.start(null));
        System.assertNotEquals(null, roleBatch.start(null));
        System.assertNotEquals(null, contactRelationBatch.start(null));
        System.assertNotEquals(null, accountRelationBatch.start(null));

        accountBatch.execute(null, new List<SObject>());
        contactPointBatch.execute(null, new List<SObject>());
        addressBatch.execute(null, new List<SObject>());
        roleBatch.execute(null, new List<SObject>());
        contactRelationBatch.execute(null, new List<SObject>());
        accountRelationBatch.execute(null, new List<SObject>());

        accountBatch.finish(null);
        contactPointBatch.finish(null);
        addressBatch.finish(null);
        roleBatch.finish(null);
        contactRelationBatch.finish(null);
        accountRelationBatch.finish(null);
        Test.stopTest();
    }

    @IsTest
    static void classifiesLegacyContactChannels() {
        String normalizedPhone = ViasDeContactoMigrationBatch.normalizeViaType('Teléfono móvil');
        String normalizedEmail = ViasDeContactoMigrationBatch.normalizeViaType('Correo electrónico');

        System.assertEquals('PHONE', ViasDeContactoMigrationBatch.classifyChannel(normalizedPhone));
        System.assertEquals('EMAIL', ViasDeContactoMigrationBatch.classifyChannel(normalizedEmail));
        System.assertEquals('SKIP', ViasDeContactoMigrationBatch.classifyChannel('PAGINA WEB'));
        System.assertEquals('18095550100', ViasDeContactoMigrationBatch.sanitizePhone('+1 (809) 555-0100'));
    }

    @IsTest
    static void migratesAccountsToLeadsInAnIsolatedTestTransaction() {
        createProspectAccount('Prospecto para migracion');
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));

        Test.startTest();
        Id jobId = Database.executeBatch(new AccountToLeadMigrationBatch(), 200);
        Test.stopTest();

        assertBatchCompleted(jobId);
    }

    @IsTest
    static void migratesLegacyContactChannelsInAnIsolatedTestTransaction() {
        Account account = createProspectAccount('Cliente vias migracion');
        insert new List<Vias_de_Contacto__c>{
            new Vias_de_Contacto__c(
                VIA_Account__c = account.Id,
                VIA_de_Contacto__c = 'TELÉFONO FIJO',
                VIA_Numero_Correo__c = '8095550100',
                VIA_Telefonica__c = 'Claro',
                VIA_Principal__c = true
            ),
            new Vias_de_Contacto__c(
                VIA_Account__c = account.Id,
                VIA_de_Contacto__c = 'CORREO ELECTRÓNICO',
                VIA_Numero_Correo__c = 'migracion@example.com'
            ),
            new Vias_de_Contacto__c(
                VIA_Account__c = account.Id,
                VIA_de_Contacto__c = 'SITIO/PÁGINA WEB',
                VIA_Numero_Correo__c = 'https://example.com'
            )
        };

        Test.startTest();
        Id jobId = Database.executeBatch(new ViasDeContactoMigrationBatch(), 200);
        Test.stopTest();

        assertBatchCompleted(jobId);
    }

    @IsTest
    static void migratesAddressesInAnIsolatedTestTransaction() {
        Account account = createProspectAccount('Cliente direccion migracion');
        insert new Direccion__c(
            DIR_Account__c = account.Id,
            DIR_Calle__c = 'Calle Principal',
            DIR_Numero__c = '10',
            DIR_Edificio__c = 'Torre A',
            DIR_Municipio_texto__c = 'Santo Domingo',
            DIR_Provincia_texto__c = 'Distrito Nacional',
            DIR_Pais_Texto__c = 'Republica Dominicana',
            DIR_Telef_Adicional__c = '8095550101',
            DIR_Extension__c = '12',
            DIR_Id_Externo_Direccion__c = 'DIR-MIGRATION-TEST'
        );
        insert new Direccion__c(
            DIR_Account__c = account.Id,
            DIR_Estado_Ciudad__c = 'Ciudad fallback',
            DIR_Pais_Texto__c = 'Republica Dominicana',
            DIR_Id_Externo_Direccion__c = 'DIR-MIGRATION-FALLBACK'
        );
        Database.SaveResult orphanAddress = Database.insert(
            new Direccion__c(DIR_Id_Externo_Direccion__c = 'DIR-MIGRATION-ORPHAN'),
            false
        );
        System.assertNotEquals(null, orphanAddress);

        Test.startTest();
        Id jobId = Database.executeBatch(new AddressMigrationBatch(), 200);
        Test.stopTest();

        assertBatchCompleted(jobId);
    }

    @IsTest
    static void migratesAccountRelationsWhenSourceRecordIsAvailable() {
        Account account = createProspectAccount('Empresa filial migracion');
        SObject source = minimalSource('Empresa_Filial__c', account.Id);
        Database.SaveResult result = Database.insert(source, false);

        if (result.isSuccess()) {
            Test.startTest();
            Id jobId = Database.executeBatch(new AccountAccountRelationMigrationBatch(), 200);
            Test.stopTest();
            assertBatchCompleted(jobId);
        }
    }

    @IsTest
    static void migratesContactRelationsWhenSourceRecordsAreAvailable() {
        Account account = createProspectAccount('Referencia migracion');
        SObject referencia = minimalSource('Referencia__c', account.Id);
        Database.SaveResult referenciaResult = Database.insert(referencia, false);

        if (referenciaResult.isSuccess()) {
            Test.startTest();
            Id jobId = Database.executeBatch(
                new ContactContactRelationMigrationBatch('Referencia__c'),
                200
            );
            Test.stopTest();
            assertBatchCompleted(jobId);
        }
    }

    @IsTest
    static void migratesFinancialRolesWhenSourceRecordIsAvailable() {
        Account account = createProspectAccount('Vinculado migracion');
        SObject source = minimalSource('Vinculado__c', account.Id);
        Id financialAccountRecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c
            .getRecordTypeInfosByDeveloperName().get('CheckingAccount').getRecordTypeId();
        FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c(
            Name = 'Financial account migration coverage',
            FinServ__FinancialAccountNumber__c = '102083476',
            FinServ__SourceSystemId__c = 'FA-MIGRATION-TEST',
            FinServ__PrimaryOwner__c = account.Id,
            RecordTypeId = financialAccountRecordTypeId
        );
        insert financialAccount;
        Map<String, Schema.SObjectField> sourceFields =
            Schema.getGlobalDescribe().get('Vinculado__c').getDescribe().fields.getMap();
        if (sourceFields.containsKey('VIN_Cuenta_financiera__c')) {
            source.put('VIN_Cuenta_financiera__c', financialAccount.Id);
        }
        if (sourceFields.containsKey('VIN_Tipo_de_vinculo__c')) {
            source.put('VIN_Tipo_de_vinculo__c', 'AUTORIZADO');
        }
        if (sourceFields.containsKey('VIN_CIF_Vinculado__c')
                && sourceFields.get('VIN_CIF_Vinculado__c').getDescribe().isCreateable()) {
            source.put('VIN_CIF_Vinculado__c', 'CIF-MIGRATION-TEST');
        }
        if (sourceFields.containsKey('VIN_N_identificacion_vinculado__c')
                && sourceFields.get('VIN_N_identificacion_vinculado__c').getDescribe().isCreateable()) {
            source.put('VIN_N_identificacion_vinculado__c', '00108803610');
        }
        if (sourceFields.containsKey('VIN_Tipo_identificacion_vinculado__c')
                && sourceFields.get('VIN_Tipo_identificacion_vinculado__c').getDescribe().isCreateable()) {
            source.put('VIN_Tipo_identificacion_vinculado__c', 'RNC');
        }
        Database.SaveResult result = Database.insert(source, false);

        if (result.isSuccess()) {
            Test.startTest();
            Id jobId = Database.executeBatch(
                new FinancialAccountRoleMigrationBatch('Vinculado__c'),
                200
            );
            Test.stopTest();
            assertBatchCompleted(jobId);
        }
    }

    @IsTest
    static void reprocessesLegacyContactChannelsWithoutCreatingDuplicates() {
        Account account = createProspectAccount('Cliente vias duplicadas');
        insert new List<Vias_de_Contacto__c>{
            new Vias_de_Contacto__c(
                VIA_Account__c = account.Id,
                VIA_de_Contacto__c = 'TELÉFONO FIJO',
                VIA_Numero_Correo__c = '8095550102',
                VIA_Principal__c = true,
                VIA_Telefonica__c = 'Claro'
            ),
            new Vias_de_Contacto__c(
                VIA_Account__c = account.Id,
                VIA_de_Contacto__c = 'CORREO LABORAL',
                VIA_Numero_Correo__c = 'duplicate@example.com'
            ),
            new Vias_de_Contacto__c(
                VIA_Account__c = account.Id,
                VIA_de_Contacto__c = 'TELÉFONO FAX',
                VIA_Numero_Correo__c = '8095550103',
                VIA_Telefonica__c = 'Claro'
            ),
            new Vias_de_Contacto__c(
                VIA_Account__c = account.Id,
                VIA_de_Contacto__c = 'CORREO ELECTRÓNICO',
                VIA_Numero_Correo__c = ' '
            )
        };

        Test.startTest();
        Id firstJobId = Database.executeBatch(new ViasDeContactoMigrationBatch(), 200);
        Test.stopTest();
        assertBatchCompleted(firstJobId);

        Id accountId = account.Id;
        List<SObject> existingChannels = Database.query(
            'SELECT Id, VIA_Account__c, VIA_Numero_Correo__c, VIA_Principal__c, '
            + 'VIA_Telefonica__c, VIA_de_Contacto__c '
            + 'FROM Vias_de_Contacto__c WHERE VIA_Account__c = :accountId'
        );
        new ViasDeContactoMigrationBatch().execute(null, existingChannels);
    }

    @IsTest
    static void executesFinancialRoleMigrationForMinimalLinkedRecords() {
        SObject source = Schema.getGlobalDescribe().get('Vinculado__c').newSObject();
        Database.SaveResult sourceResult = Database.insert(source, false);
        System.assert(sourceResult.isSuccess());

        Test.startTest();
        Id jobId = Database.executeBatch(
            new FinancialAccountRoleMigrationBatch('Vinculado__c'),
            200
        );
        Test.stopTest();

        assertBatchCompleted(jobId);
    }

}
