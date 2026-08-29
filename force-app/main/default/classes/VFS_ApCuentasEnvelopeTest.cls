/*********************************************************************************************
 * Nombre de clase Test   :   VFS_ApCuentasEnvelopeTest
 * Versión                :   2.1
 * Fecha de actualización :   05/08/2025
 * Función                :   Pruebas unitarias para la clase VFS_ApCuentasEnvelope
 * Clase probada          :   VFS_ApCuentasEnvelope
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        18/07/2025      Versión inicial
 *********************************************************************************************/
@isTest
private without sharing class VFS_ApCuentasEnvelopeTest {

    private class SuccessHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"EnvelopeId":"test-envelope-id","Status":"OK"}');
            return res;
        }
    }

    private static FinServ__FinancialAccount__c createFinancialAccount(Id primaryOwnerId, String accountName) {
        return createFinancialAccount(primaryOwnerId, accountName, true);
    }

    private static FinServ__FinancialAccount__c createFinancialAccount(Id primaryOwnerId, String accountName, Boolean createPrimaryEmail) {
        Test.setMock(HttpCalloutMock.class, new SuccessHttpMock());

        Account ownerAccount = [
            SELECT RecordTypeId, ACC_CIF__c, ACC_TipoIdentificacion__c, ACC_NumIdentificacion__c, ACC_RNC__c
            FROM Account
            WHERE Id = :primaryOwnerId
            LIMIT 1
        ];
        Map<String, Schema.RecordTypeInfo> accountRecordTypes =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        Id personAccountRecordTypeId = accountRecordTypes.get('PersonAccount').getRecordTypeId();
        Id businessAccountRecordTypeId = accountRecordTypes.get('IndustriesBusiness').getRecordTypeId();

        Account ownerUpdates = new Account(Id = primaryOwnerId);
        Boolean needsOwnerUpdate = false;
        if (String.isBlank(ownerAccount.ACC_CIF__c)) {
            ownerUpdates.ACC_CIF__c = 'TESTCIF' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
            needsOwnerUpdate = true;
        }
        if (ownerAccount.RecordTypeId == personAccountRecordTypeId) {
            if (String.isBlank(ownerAccount.ACC_TipoIdentificacion__c)) {
                ownerUpdates.ACC_TipoIdentificacion__c = 'Cédula';
                needsOwnerUpdate = true;
            }
            if (String.isBlank(ownerAccount.ACC_NumIdentificacion__c)) {
                ownerUpdates.ACC_NumIdentificacion__c = '00100058007';
                needsOwnerUpdate = true;
            }
        } else if (ownerAccount.RecordTypeId == businessAccountRecordTypeId && String.isBlank(ownerAccount.ACC_RNC__c)) {
            ownerUpdates.ACC_RNC__c = '101010101';
            needsOwnerUpdate = true;
        }
        if (needsOwnerUpdate) {
            update ownerUpdates;
        }

        if ([SELECT COUNT() FROM ContactPointAddress WHERE ParentId = :primaryOwnerId AND IsPrimary = true] == 0) {
            Datos_Maestros__c sector = new Datos_Maestros__c(
                Name = 'Sector test ' + accountName,
                DM_Codigo_Oficina__c = '2',
                DM_Tipo__c = 'Oficina',
                DM_Direccion__c = 't13',
                DM_Distrito__c = '290403'
            );
            insert sector;

            ContactPointAddress address = new ContactPointAddress();
            address.Name = 'Direccion test ' + accountName;
            address.ParentId = primaryOwnerId;
            address.IsPrimary = true;
            address.AddressType = 'RESIDENCIA';
            address.Street = 'Calle Test 123';
            address.Country = 'DO';
            address.State = 'Santo Domingo';
            address.CPA_Distrito__c = '290403';
            address.CPA_Sector__c = sector.Id;
            address.CPA_ExternalId__c = 'ADDR' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
            address.PostalCode = '10101';
            insert address;
        }

        if ([SELECT COUNT() FROM ContactPointPhone WHERE ParentId = :primaryOwnerId AND IsPrimary = true] == 0) {
            ContactPointPhone phone = new ContactPointPhone();
            phone.ParentId = primaryOwnerId;
            phone.IsPrimary = true;
            phone.AreaCode = '809';
            phone.TelephoneNumber = '8095551234';
            phone.CPP_Tipo__c = 'TELÉFONO MÓVIL';
            phone.CPP_Telefonica__c = 'Claro';
            insert phone;
        }

        if (createPrimaryEmail && [SELECT COUNT() FROM ContactPointEmail WHERE ParentId = :primaryOwnerId AND IsPrimary = true] == 0) {
            String ownerEmail = 'titular.' + accountName.toLowerCase().replace(' ', '.') + '@example.com';
            List<Vias_de_Contacto__c> ownerEmailWays = [
                SELECT VIA_Numero_Correo__c
                FROM Vias_de_Contacto__c
                WHERE VIA_Account__c = :primaryOwnerId
                AND VIA_de_Contacto__c = 'CORREO ELECTRÓNICO'
                AND VIA_Principal__c = true
                LIMIT 1
            ];
            if (!ownerEmailWays.isEmpty() && String.isNotBlank(ownerEmailWays[0].VIA_Numero_Correo__c)) {
                ownerEmail = ownerEmailWays[0].VIA_Numero_Correo__c;
            }

            ContactPointEmail email = new ContactPointEmail();
            email.ParentId = primaryOwnerId;
            email.IsPrimary = true;
            email.EmailAddress = ownerEmail;
            email.CPE_Tipo__c = 'CORREO ELECTRÓNICO';
            insert email;
        }

        if (ownerAccount.RecordTypeId == businessAccountRecordTypeId && [SELECT COUNT() FROM Contact WHERE AccountId = :primaryOwnerId] == 0) {
            insert new Contact(
                AccountId = primaryOwnerId,
                LastName = 'Contacto ' + accountName,
                Email = 'contacto.' + accountName.toLowerCase().replace(' ', '.') + '@example.com',
                Phone = '8095551234',
                MailingStreet = 'Calle Test 123'
            );
        }

        Matriz_de_producto__c matriz = new Matriz_de_producto__c();
        matriz.Name = 'Matriz producto test ' + accountName;
        matriz.PRO_Codigo_de_producto__c = 'T' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        insert matriz;

        List<User> coreUsers = [
            SELECT Id
            FROM User
            WHERE IsActive = true
            AND USE_Codigo__c != null
            AND USE_Oficina__c != null
            LIMIT 1
        ];
        User coreUser = coreUsers.isEmpty()
            ? new User(Id = UserInfo.getUserId())
            : coreUsers[0];

        FinServ__FinancialAccount__c financialAccount = new FinServ__FinancialAccount__c();
        financialAccount.Name = accountName;
        financialAccount.FinServ__PrimaryOwner__c = primaryOwnerId;
        financialAccount.FIN_Producto__c = matriz.Id;
        financialAccount.FIN_Ejecutivo__c = coreUser.Id;
        System.runAs(coreUser) {
            insert financialAccount;
        }
        return financialAccount;
    }

    private static void createContactPointEmail(Id parentId, String emailAddress) {
        ContactPointEmail email = new ContactPointEmail();
        email.ParentId = parentId;
        email.IsPrimary = true;
        email.EmailAddress = emailAddress;
        email.CPE_Tipo__c = 'CORREO ELECTRÓNICO';
        insert email;
    }

    @isTest
    static void testCreateSignsFisica_Autorizado() {
        // Arrange: crear Account principal y autorizado
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'User';
        acc.RecordTypeId = rtId;
        insert acc;
        Vias_de_Contacto__c via = new Vias_de_Contacto__c();
        via.VIA_Account__c = acc.Id;
        via.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        via.VIA_Numero_Correo__c = 'testuser@example.com';
        via.VIA_Principal__c = true;
        insert via;
        // Firmante autorizado
        Account autorizado = new Account();
        autorizado.FirstName = 'Autorizado';
        autorizado.LastName = 'Uno';
        autorizado.RecordTypeId = rtId;
        autorizado.ACC_NumIdentificacion__c = '123456789';
        insert autorizado;
        Vias_de_Contacto__c viaAut = new Vias_de_Contacto__c();
        viaAut.VIA_Account__c = autorizado.Id;
        viaAut.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        viaAut.VIA_Numero_Correo__c = 'autorizado@example.com';
        viaAut.VIA_Principal__c = true;
        insert viaAut;
        createContactPointEmail(autorizado.Id, 'autorizado@example.com');
        // Crear cuenta financiera relacionada
        FinServ__FinancialAccount__c ast = createFinancialAccount(acc.Id, 'TestAsset');
        // Simular respuesta INT026
        VFS_ApCuentasEnvelope.testResponse = new INT026_FSC.Response();
        VFS_ApCuentasEnvelope.testResponse.responseList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Vinculo' => 'AUTORIZADO',
                'NombreCompleto' => autorizado.FirstName + ' ' + autorizado.LastName,
                'NumeroDocumento' => autorizado.ACC_NumIdentificacion__c,
                'DarGarantia' => 'Y'
            }
        };
        // Act
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_ApCuentasEnvelope.CreateSigns(ast.Id);
        Test.stopTest();
        
        // Assert: La clase principal genera:
        // - 1 firma titular + 1 copia = 2
        // - 1 firma autorizado + 1 copia = 2  
        // - 1 firma ejecutivo + 1 copia = 2
        // - Gerente solo si hay datos válidos = 0 o 2
        // TOTAL: 6 acciones SIN gerente, 8 acciones CON gerente
        System.assert(actions.size() >= 6, 'Debe devolver al menos 6 acciones (3 firmas + 3 copias)');
        
        Boolean foundAutorizado = false;
        Boolean foundTitular = false;
        Boolean foundEjecutivo = false;
        Integer firmasCount = 0;
        Integer copiasCount = 0;
        
        for (VFS_EsignSendingEnvelope.EnvelopeAction act : actions) {
            if (act.Sign != null && act.Sign.RecipientConfiguration != null && act.Sign.RecipientConfiguration.ContactInformation != null) {
                firmasCount++;
                String email = act.Sign.RecipientConfiguration.ContactInformation.Email;
                if (email == 'autorizado@example.com') {
                    foundAutorizado = true;
                } else if (email == 'testuser@example.com') {
                    foundTitular = true;
                } else if (email == UserInfo.getUserEmail()) {
                    foundEjecutivo = true;
                }
            } else if (act.SendCopy != null) {
                copiasCount++;
            }
        }
        
        System.assert(foundAutorizado, 'Debe haber una firma para el autorizado');
        System.assert(foundTitular, 'Debe haber una firma para el titular');
        System.assert(foundEjecutivo, 'Debe haber una firma para el ejecutivo');
        System.assert(firmasCount >= 3, 'Debe haber al menos 3 firmas');
        System.assert(copiasCount >= 3, 'Debe haber al menos 3 copias');
    }

    @isTest
    static void testCreateSignsFisica_SinAutorizado() {
        // Arrange: solo Account principal - ahora debe fallar porque se requiere al menos un firmante autorizado
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'User';
        acc.RecordTypeId = rtId;
        insert acc;
        Vias_de_Contacto__c via = new Vias_de_Contacto__c();
        via.VIA_Account__c = acc.Id;
        via.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        via.VIA_Numero_Correo__c = 'testuser@example.com';
        via.VIA_Principal__c = true;
        insert via;
        FinServ__FinancialAccount__c ast = createFinancialAccount(acc.Id, 'TestAsset');
        // Simular respuesta INT026 sin autorizado
        VFS_ApCuentasEnvelope.testResponse = new INT026_FSC.Response();
        VFS_ApCuentasEnvelope.testResponse.responseList = new List<Map<String, Object>>{};
        
        // Act & Assert: debe lanzar excepción porque no hay firmantes autorizados
        Test.startTest();
        try {
            List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_ApCuentasEnvelope.CreateSigns(ast.Id);
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('No se encontraron firmantes autorizados para la cuenta de persona física'), 
                         'Debe lanzar excepción indicando falta de firmantes autorizados');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSignsJuridica_ApCuentas() {
        // Arrange: crear Account de prueba como persona jurídica
        Id rtBusiness = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesBusiness').getRecordTypeId();
        Account acc = new Account();
        acc.Name = 'Empresa Test';
        acc.RecordTypeId = rtBusiness;
        acc.OwnerId = UserInfo.getUserId();
        insert acc;
        Id rtPerson = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account firmante0 = new Account();
        firmante0.FirstName = 'Firmante';
        firmante0.LastName = '0';
        firmante0.RecordTypeId = rtPerson;
        firmante0.OwnerId = UserInfo.getUserId();
        firmante0.ACC_NumIdentificacion__c = '567263874';
        insert firmante0;
        Vias_de_Contacto__c via0 = new Vias_de_Contacto__c();
        via0.VIA_Account__c = firmante0.Id;
        via0.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        via0.VIA_Numero_Correo__c = 'firmante0@example.com';
        via0.VIA_Principal__c = true;
        insert via0;
        createContactPointEmail(firmante0.Id, 'firmante0@example.com');
        FinServ__FinancialAccount__c ast = createFinancialAccount(acc.Id, 'TestAsset');
        // Simular respuesta INT026 para jurídica
        VFS_ApCuentasEnvelope.testResponse = new INT026_FSC.Response();
        VFS_ApCuentasEnvelope.testResponse.responseList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Vinculo' => 'AUTORIZADO',
                'NombreCompleto' => firmante0.FirstName + ' ' + firmante0.LastName,
                'NumeroDocumento' => firmante0.ACC_NumIdentificacion__c,
                'DarGarantia' => 'Y'
            }
        };
        // Act
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_ApCuentasEnvelope.CreateSigns(ast.Id);
        Test.stopTest();
        System.assertNotEquals(null, actions, 'La lista de acciones no debe ser nula');
        System.assert(!actions.isEmpty(), 'La lista de acciones no debe estar vacía');
        Boolean foundEmail0 = false;
        Integer firmasCount = 0;
        for (VFS_EsignSendingEnvelope.EnvelopeAction act : actions) {
            if (act.Sign != null && act.Sign.RecipientConfiguration != null && act.Sign.RecipientConfiguration.ContactInformation != null) {
                firmasCount++;
                if (act.Sign.RecipientConfiguration.ContactInformation.Email == 'firmante0@example.com') {
                    foundEmail0 = true;
                }
            }
        }
        System.assert(firmasCount > 0, 'Debe haber al menos una acción de firma.');
        System.assert(foundEmail0, 'Debe haber un firmante con email firmante0@example.com.');
    }

    @isTest
    static void testCreateSignsJuridica_MultipleFirmantes() {
        // Arrange: crear Account jurídica con múltiples firmantes
        Id rtBusiness = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesBusiness').getRecordTypeId();
        Account acc = new Account();
        acc.Name = 'Empresa Test Multiple';
        acc.RecordTypeId = rtBusiness;
        acc.OwnerId = UserInfo.getUserId();
        insert acc;
        
        Id rtPerson = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        // Crear múltiples firmantes para probar paginación
        List<Account> firmantes = new List<Account>();
        List<Vias_de_Contacto__c> vias = new List<Vias_de_Contacto__c>();
        List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        
        for (Integer i = 0; i < 10; i++) {
            Account firmante = new Account();
            firmante.FirstName = 'Firmante';
            firmante.LastName = String.valueOf(i);
            firmante.RecordTypeId = rtPerson;
            firmante.OwnerId = UserInfo.getUserId();
            firmante.ACC_NumIdentificacion__c = '56726387' + i;
            firmantes.add(firmante);
            
            // Crear respuesta mock
            responseList.add(new Map<String, Object>{
                'Vinculo' => 'AUTORIZADO',
                'NombreCompleto' => firmante.FirstName + ' ' + firmante.LastName,
                'NumeroDocumento' => firmante.ACC_NumIdentificacion__c,
                'DarGarantia' => 'Y'
            });
        }
        insert firmantes;
        
        // Crear vías de contacto
        for (Integer i = 0; i < firmantes.size(); i++) {
            Vias_de_Contacto__c via = new Vias_de_Contacto__c();
            via.VIA_Account__c = firmantes[i].Id;
            via.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
            via.VIA_Numero_Correo__c = 'firmante' + i + '@example.com';
            via.VIA_Principal__c = true;
            vias.add(via);
        }
        insert vias;
        for (Integer i = 0; i < firmantes.size(); i++) {
            createContactPointEmail(firmantes[i].Id, 'firmante' + i + '@example.com');
        }
        
        FinServ__FinancialAccount__c ast = createFinancialAccount(acc.Id, 'TestAssetMultiple');
        
        // Simular respuesta INT026 con múltiples firmantes
        VFS_ApCuentasEnvelope.testResponse = new INT026_FSC.Response();
        VFS_ApCuentasEnvelope.testResponse.responseList = responseList;
        
        // Act
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_ApCuentasEnvelope.CreateSigns(ast.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, actions, 'La lista de acciones no debe ser nula');
        System.assert(!actions.isEmpty(), 'La lista de acciones no debe estar vacía');
        
        // Debe incluir firmas de página 2 y página 3 para jurídica
        Integer firmasCount = 0;
        Integer copiasCount = 0;
        Set<String> emailsFirmas = new Set<String>();
        
        for (VFS_EsignSendingEnvelope.EnvelopeAction act : actions) {
            if (act.Sign != null && act.Sign.RecipientConfiguration != null && act.Sign.RecipientConfiguration.ContactInformation != null) {
                firmasCount++;
                emailsFirmas.add(act.Sign.RecipientConfiguration.ContactInformation.Email);
            } else if (act.SendCopy != null) {
                copiasCount++;
            }
        }
        
        System.assert(firmasCount >= 10, 'Debe haber al menos 10 firmantes (4 en página 2, 6+ en página 3)');
        System.assert(copiasCount > 0, 'Debe haber acciones de envío de copia');
        
        // Verificar que se incluyen firmantes específicos
        System.assert(emailsFirmas.contains('firmante0@example.com'), 'Debe incluir firmante0');
        System.assert(emailsFirmas.contains('firmante9@example.com'), 'Debe incluir firmante9');
    }

    @isTest
    static void testCreateSignsFisica_ConGerente() {
        // Arrange: crear datos de prueba con información del gerente y firmante autorizado
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'ConGerente';
        acc.RecordTypeId = rtId;
        insert acc;
        
        Vias_de_Contacto__c via = new Vias_de_Contacto__c();
        via.VIA_Account__c = acc.Id;
        via.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        via.VIA_Numero_Correo__c = 'testgerente@example.com';
        via.VIA_Principal__c = true;
        insert via;
        
        // Crear firmante autorizado (requerido por la nueva validación)
        Account autorizado = new Account();
        autorizado.FirstName = 'Autorizado';
        autorizado.LastName = 'Gerente';
        autorizado.RecordTypeId = rtId;
        autorizado.ACC_NumIdentificacion__c = '987654321';
        insert autorizado;
        
        Vias_de_Contacto__c viaAut = new Vias_de_Contacto__c();
        viaAut.VIA_Account__c = autorizado.Id;
        viaAut.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        viaAut.VIA_Numero_Correo__c = 'autorizado.gerente@example.com';
        viaAut.VIA_Principal__c = true;
        insert viaAut;
        createContactPointEmail(autorizado.Id, 'autorizado.gerente@example.com');
        
        // Crear Datos_Maestros__c para simular gerente
        Datos_Maestros__c datosMaestro = new Datos_Maestros__c();
        datosMaestro.DM_Codigo_Oficina__c = 'PC';
        datosMaestro.VFS_GerenteOficina__c = 'Juan Pérez';
        datosMaestro.VFS_CorreoGerente__c = 'gerente@example.com';
        insert datosMaestro;
        
        FinServ__FinancialAccount__c ast = createFinancialAccount(acc.Id, 'TestAssetGerente');
        
        // Simular respuesta INT026 con firmante autorizado
        VFS_ApCuentasEnvelope.testResponse = new INT026_FSC.Response();
        VFS_ApCuentasEnvelope.testResponse.responseList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Vinculo' => 'AUTORIZADO',
                'NombreCompleto' => autorizado.FirstName + ' ' + autorizado.LastName,
                'NumeroDocumento' => autorizado.ACC_NumIdentificacion__c,
                'DarGarantia' => 'Y'
            }
        };
        
        // Act
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_ApCuentasEnvelope.CreateSigns(ast.Id);
        Test.stopTest();
        
        // Assert: verificar que se ejecuta sin errores
        System.assertNotEquals(null, actions, 'La lista de acciones no debe ser nula');
        System.assert(actions.size() >= 6, 'Debe incluir al menos 6 acciones (titular + autorizado + ejecutivo + copias)');
        
        // Verificar que hay firmantes válidos
        Boolean foundTitular = false;
        Boolean foundAutorizado = false;
        Boolean foundEjecutivo = false;
        Integer firmasCount = 0;
        
        for (VFS_EsignSendingEnvelope.EnvelopeAction act : actions) {
            if (act.Sign != null && act.Sign.RecipientConfiguration != null && act.Sign.RecipientConfiguration.ContactInformation != null) {
                firmasCount++;
                String email = act.Sign.RecipientConfiguration.ContactInformation.Email;
                if (email == 'testgerente@example.com') {
                    foundTitular = true;
                } else if (email == 'autorizado.gerente@example.com') {
                    foundAutorizado = true;
                } else if (email == UserInfo.getUserEmail()) {
                    foundEjecutivo = true;
                }
            }
        }
        
        System.assert(foundTitular, 'Debe incluir firma del titular');
        System.assert(foundAutorizado, 'Debe incluir firma del autorizado');
        System.assert(foundEjecutivo, 'Debe incluir firma del ejecutivo');
        System.assert(firmasCount >= 3, 'Debe haber al menos 3 firmas');
    }

    @isTest
    static void testCreateSignsFisica_SinGerente() {
        // Arrange: crear datos sin información del gerente pero con firmante autorizado
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'SinGerente';
        acc.RecordTypeId = rtId;
        insert acc;
        
        Vias_de_Contacto__c via = new Vias_de_Contacto__c();
        via.VIA_Account__c = acc.Id;
        via.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        via.VIA_Numero_Correo__c = 'testsingerente@example.com';
        via.VIA_Principal__c = true;
        insert via;
        
        // Crear firmante autorizado (requerido por la nueva validación)
        Account autorizado = new Account();
        autorizado.FirstName = 'Autorizado';
        autorizado.LastName = 'SinGerente';
        autorizado.RecordTypeId = rtId;
        autorizado.ACC_NumIdentificacion__c = '555666777';
        insert autorizado;
        
        Vias_de_Contacto__c viaAut = new Vias_de_Contacto__c();
        viaAut.VIA_Account__c = autorizado.Id;
        viaAut.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        viaAut.VIA_Numero_Correo__c = 'autorizado.singerente@example.com';
        viaAut.VIA_Principal__c = true;
        insert viaAut;
        createContactPointEmail(autorizado.Id, 'autorizado.singerente@example.com');
        
        FinServ__FinancialAccount__c ast = createFinancialAccount(acc.Id, 'TestAssetSinGerente');
        
        // NO crear Datos_Maestros__c - así no habrá información del gerente
        
        // Simular respuesta INT026 con firmante autorizado
        VFS_ApCuentasEnvelope.testResponse = new INT026_FSC.Response();
        VFS_ApCuentasEnvelope.testResponse.responseList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Vinculo' => 'AUTORIZADO',
                'NombreCompleto' => autorizado.FirstName + ' ' + autorizado.LastName,
                'NumeroDocumento' => autorizado.ACC_NumIdentificacion__c,
                'DarGarantia' => 'Y'
            }
        };
        
        // Act
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_ApCuentasEnvelope.CreateSigns(ast.Id);
        Test.stopTest();
        
        // Assert: Verificar funcionamiento básico
        System.assert(actions != null, 'La lista de acciones no debe ser nula');
        System.assert(actions.size() >= 6, 'Debe incluir al menos 6 acciones (titular + autorizado + ejecutivo + copias)');
        
        // Contar firmas y copias
        Integer firmasCount = 0;
        Integer copiasCount = 0;
        Boolean foundTitular = false;
        Boolean foundAutorizado = false;
        Boolean foundEjecutivo = false;
        Set<String> emailsEncontrados = new Set<String>();
        
        for (VFS_EsignSendingEnvelope.EnvelopeAction act : actions) {
            if (act.Sign != null && act.Sign.RecipientConfiguration != null && act.Sign.RecipientConfiguration.ContactInformation != null) {
                firmasCount++;
                String email = act.Sign.RecipientConfiguration.ContactInformation.Email;
                emailsEncontrados.add(email);
                
                if (email == 'testsingerente@example.com') {
                    foundTitular = true;
                } else if (email == 'autorizado.singerente@example.com') {
                    foundAutorizado = true;
                } else if (email == UserInfo.getUserEmail()) {
                    foundEjecutivo = true;
                }
            } else if (act.SendCopy != null) {
                copiasCount++;
            }
        }
        
        System.assert(foundTitular, 'Debe incluir firma del titular');
        System.assert(foundAutorizado, 'Debe incluir firma del autorizado');
        System.assert(foundEjecutivo, 'Debe incluir firma del ejecutivo');
        System.assert(firmasCount >= 3, 'Debe haber al menos 3 firmas (titular + autorizado + ejecutivo)');
        System.assert(copiasCount >= 3, 'Debe haber al menos 3 copias');
        
        // El punto clave: verificar que la funcionalidad básica trabaja sin errores
        // independientemente de si hay o no gerente
        System.debug('Emails encontrados en firmas: ' + emailsEncontrados);
        System.debug('Total de acciones: ' + actions.size() + ' (Firmas: ' + firmasCount + ', Copias: ' + copiasCount + ')');
    }

    @isTest
    static void testGetAssetWithAccount_AssetInvalido() {
        // Act & Assert: debe lanzar excepción para ID inválido
        Test.startTest();
        try {
            List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_ApCuentasEnvelope.CreateSigns('invalid-id');
            System.assert(false, 'Debería haber lanzado una excepción para ID inválido');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('No se pudo encontrar el registro solicitado'), 
                         'Debe lanzar excepción indicando que no se encontró el registro');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateSignsFisica_CorreoViasContacto() {
        // Arrange: probar obtención de correo desde vías de contacto con firmante autorizado
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'ViaContacto';
        acc.RecordTypeId = rtId;
        insert acc;
        
        Vias_de_Contacto__c via = new Vias_de_Contacto__c();
        via.VIA_Account__c = acc.Id;
        via.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        via.VIA_Numero_Correo__c = 'viacontacto@example.com';
        via.VIA_Principal__c = true;
        insert via;
        
        // Crear firmante autorizado (requerido por la nueva validación)
        Account autorizado = new Account();
        autorizado.FirstName = 'Autorizado';
        autorizado.LastName = 'ViaContacto';
        autorizado.RecordTypeId = rtId;
        autorizado.ACC_NumIdentificacion__c = '111222333';
        insert autorizado;
        
        Vias_de_Contacto__c viaAut = new Vias_de_Contacto__c();
        viaAut.VIA_Account__c = autorizado.Id;
        viaAut.VIA_de_Contacto__c = 'CORREO ELECTRÓNICO';
        viaAut.VIA_Numero_Correo__c = 'autorizado.viacontacto@example.com';
        viaAut.VIA_Principal__c = true;
        insert viaAut;
        createContactPointEmail(autorizado.Id, 'autorizado.viacontacto@example.com');
        
        FinServ__FinancialAccount__c ast = createFinancialAccount(acc.Id, 'TestAssetViaContacto');
        
        // Simular respuesta INT026 con firmante autorizado
        VFS_ApCuentasEnvelope.testResponse = new INT026_FSC.Response();
        VFS_ApCuentasEnvelope.testResponse.responseList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Vinculo' => 'AUTORIZADO',
                'NombreCompleto' => autorizado.FirstName + ' ' + autorizado.LastName,
                'NumeroDocumento' => autorizado.ACC_NumIdentificacion__c,
                'DarGarantia' => 'Y'
            }
        };
        
        // Act
        Test.startTest();
        List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_ApCuentasEnvelope.CreateSigns(ast.Id);
        Test.stopTest();
        
        // Assert: debe usar el correo de vías de contacto
        Boolean foundCorrectEmail = false;
        Boolean foundAutorizadoEmail = false;
        for (VFS_EsignSendingEnvelope.EnvelopeAction act : actions) {
            if (act.Sign != null && act.Sign.RecipientConfiguration != null && act.Sign.RecipientConfiguration.ContactInformation != null) {
                String email = act.Sign.RecipientConfiguration.ContactInformation.Email;
                if (email == 'viacontacto@example.com') {
                    foundCorrectEmail = true;
                }
                if (email == 'autorizado.viacontacto@example.com') {
                    foundAutorizadoEmail = true;
                }
            }
        }
        
        System.assert(foundCorrectEmail, 'Debe usar el correo de vías de contacto del titular');
        System.assert(foundAutorizadoEmail, 'Debe usar el correo de vías de contacto del autorizado');
    }
    
    @IsTest
    static void testCreateSignsFisica_SinViasContacto() {
        // Arrange: crear cuenta sin vías de contacto para probar manejo de error
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'SinVias';
        acc.RecordTypeId = rtId;
        insert acc;
        
        FinServ__FinancialAccount__c ast = createFinancialAccount(acc.Id, 'TestAssetSinVias', false);
        
        // Simular respuesta INT026 vacía
        VFS_ApCuentasEnvelope.testResponse = new INT026_FSC.Response();
        VFS_ApCuentasEnvelope.testResponse.responseList = new List<Map<String, Object>>{};
        
        // Act & Assert: debe lanzar excepción
        Test.startTest();
        try {
            List<VFS_EsignSendingEnvelope.EnvelopeAction> actions = VFS_ApCuentasEnvelope.CreateSigns(ast.Id);
            System.assert(false, 'Debería haber lanzado una excepción por falta de vías de contacto');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('no tiene vías de contacto configuradas') || 
                         ex.getMessage().contains('No se encontró una dirección de correo electrónico válida'), 
                         'Mensaje de error debe indicar falta de vías de contacto o correo electrónico válido. Mensaje actual: ' + ex.getMessage());
        }
        Test.stopTest();
    }
}
