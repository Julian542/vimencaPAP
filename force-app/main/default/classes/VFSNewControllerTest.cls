@IsTest
private class VFSNewControllerTest {
    @TestSetup
    static void createData() {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount').getRecordTypeId(),
            FirstName = 'Visualforce',
            LastName = 'Coverage',
            ACC_TipoIdentificacion__c = 'Cédula',
            ACC_NumIdentificacion__c = '00108803888'
        );
        insert account;

        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
        insert new FinServ__FinancialAccount__c(
            RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c
                .getRecordTypeInfosByDeveloperName().get('CheckingAccount').getRecordTypeId(),
            Name = 'Cuenta Visualforce Coverage',
            FinServ__FinancialAccountNumber__c = '9988776655',
            FinServ__SourceSystemId__c = 'SRC9988776655',
            FinServ__PrimaryOwner__c = account.Id
        );
    }

    @IsTest
    static void loadsNewKycVisualforceController() {
        Account account = [
            SELECT Id
            FROM Account
            WHERE FirstName = 'Visualforce' AND LastName = 'Coverage'
            LIMIT 1
        ];

        Test.startTest();
        VFS_nKYCFisica_Controller controller = new VFS_nKYCFisica_Controller(
            new ApexPages.StandardController(account)
        );
        Test.stopTest();

        System.assertEquals(account.Id, controller.accountId);
        System.assertEquals(12, controller.lstParticipantes.size());
        System.assertEquals(8, controller.lstAccionistas.size());
        System.assertEquals(8, controller.lstMiembros.size());
        System.assertEquals('', controller.formatearDireccion(null));
    }

    @IsTest
    static void loadsNewKycVisualforceControllerForBusinessAccount() {
        Account businessAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'Visualforce Business Coverage',
            ACC_RNC__c = '131KYCBUS',
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert businessAccount;

        insert new List<ContactPointPhone>{
            new ContactPointPhone(
                ParentId = businessAccount.Id,
                TelephoneNumber = '8095550101',
                CPP_Tipo__c = 'TELÉFONO FIJO',
                CPP_Telefonica__c = 'Claro'
            ),
            new ContactPointPhone(
                ParentId = businessAccount.Id,
                TelephoneNumber = '8095550102',
                CPP_Tipo__c = 'TELÉFONO FAX',
                CPP_Telefonica__c = 'Claro'
            )
        };
        insert new ContactPointEmail(
            ParentId = businessAccount.Id,
            EmailAddress = 'coverage.business@example.test'
        );
        insert new ContactPointAddress(
            ParentId = businessAccount.Id,
            Name = 'Direccion empresarial de cobertura',
            AddressType = 'EMPRESARIAL',
            Street = 'Calle Empresarial',
            City = 'Santo Domingo',
            State = 'Distrito Nacional',
            PostalCode = '10101',
            Country = 'República Dominicana'
        );

        Test.startTest();
        VFS_nKYCFisica_Controller controller = new VFS_nKYCFisica_Controller(
            new ApexPages.StandardController(businessAccount)
        );
        Test.stopTest();

        System.assertEquals(false, controller.isFisica);
        System.assertNotEquals(null, controller.viaTelefonoEmpresa.Id);
        System.assertNotEquals(null, controller.viaFaxEmpresa.Id);
        System.assertNotEquals(null, controller.viaCorreoEmpresa.Id);
        System.assertNotEquals(null, controller.dirEmpresarial.Id);
    }

    @IsTest
    static void loadsNewAccountOpeningVisualforceController() {
        FinServ__FinancialAccount__c financialAccount = [
            SELECT Id
            FROM FinServ__FinancialAccount__c
            WHERE FinServ__FinancialAccountNumber__c = '9988776655'
            LIMIT 1
        ];
        PageReference page = new PageReference('/apex/VFSNewControllerTest');
        page.getParameters().put('id', financialAccount.Id);
        Test.setCurrentPage(page);

        VFS_nAperturaCuentasController.testResponse = new INT026_FSC.Response();

        Test.startTest();
        VFS_nAperturaCuentasController controller = new VFS_nAperturaCuentasController(
            new ApexPages.StandardController(financialAccount)
        );
        controller.consultarVinculadoAprobado();
        controller.getDireccionesTitular();
        controller.getDireccionesFirmaConjunta();
        controller.getDireccionesJuridica();
        controller.getViasOrdenadasTitular();
        controller.getViasOrdenadasFirmaConjunta();
        controller.getHistorialLaboralTitular();
        controller.getHistorialLaboralFirmaConjunta();
        controller.getPrimeraFirmaConjunta();
        controller.getSegundaFirmaConjunta();
        controller.getViasOrdenadasSegundaFirmaConjunta();
        controller.getHistorialLaboralSegundaFirmaConjunta();
        controller.getDireccionesSegundaFirmaConjunta();
        controller.getLstReferenciasBancarias();
        controller.getLstReferenciasComerciales();
        Test.stopTest();

        System.assertEquals('Titular unico', controller.tipoFirma);
        System.assertNotEquals('', controller.getUnidadNegocioNumeroCuenta());
        System.assertEquals('', controller.formatearDireccion(null));
    }

    @IsTest
    static void coversAccountOpeningSafeGettersAndFormatting() {
        FinServ__FinancialAccount__c financialAccount = [
            SELECT Id
            FROM FinServ__FinancialAccount__c
            WHERE FinServ__FinancialAccountNumber__c = '9988776655'
            LIMIT 1
        ];
        VFS_nAperturaCuentasController controller = new VFS_nAperturaCuentasController(
            new ApexPages.StandardController(financialAccount)
        );

        controller.financialAccount.FIN_InstruccionesEspeciales__c = 'Instrucciones';
        System.assertEquals('Instrucciones', controller.getInstruccionesEspeciales());
        System.assertEquals(null, controller.getUnidadNegocioNumeroCliente());
        System.assertEquals('', controller.getUnidadNegocioTasa());
        System.assertNotEquals(null, controller.getUnidadNegocioCodigoOficial());
        System.assertNotEquals(null, controller.getUnidadNegocioElaboradoPor());
        controller.verificadoPor = 'Verificador';
        System.assertEquals('Verificador', controller.getUnidadNegocioVerificadoPor());

        controller.financialAccount = new FinServ__FinancialAccount__c(
            FIN_N_de_cuenta__c = 'Cuenta alternativa'
        );
        System.assertEquals('Cuenta alternativa', controller.getUnidadNegocioNumeroCuenta());
        controller.financialAccount = null;
        controller.verificadoPor = null;
        System.assertEquals('', controller.getInstruccionesEspeciales());
        System.assertEquals('', controller.getUnidadNegocioNumeroCuenta());
        System.assertEquals('', controller.getUnidadNegocioVerificadoPor());

        controller.lstAccountFirmaConjunta = null;
        System.assertEquals('', controller.getDireccionesFirmaConjunta(-1));
        System.assertEquals(4, controller.getViasOrdenadasFirmaConjunta(-1).size());
        System.assertEquals(null, controller.getHistorialLaboralFirmaConjunta(-1));
        System.assertEquals(null, controller.getPrimeraFirmaConjunta());
        System.assertEquals(null, controller.getSegundaFirmaConjunta());

        Direccion__c address = new Direccion__c(
            DIR_Calle__c = 'Principal',
            DIR_Numero__c = '10',
            DIR_Edificio__c = 'A',
            DIR_N_Apartamento__c = '2B',
            DIR_Provincia_texto__c = 'Distrito'
        );
        String formatted = controller.formatearDireccion(address);
        System.assert(formatted.contains('Calle Principal No. 10'));
        System.assert(formatted.contains('Edif. A'));
        System.assert(formatted.contains('Apt. 2B'));
        System.assert(formatted.contains('Distrito'));
    }

    @IsTest
    static void coversAccountOpeningContactAndJointHolderDetails() {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        Account titular = [
            SELECT Id
            FROM Account
            WHERE FirstName = 'Visualforce' AND LastName = 'Coverage'
            LIMIT 1
        ];
        Account jointHolder = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount').getRecordTypeId(),
            FirstName = 'Joint',
            LastName = 'Coverage',
            ACC_TipoIdentificacion__c = 'Cédula',
            ACC_NumIdentificacion__c = '00108803889'
        );
        insert jointHolder;

        Datos_Maestros__c sector = new Datos_Maestros__c(
            Name = 'Sector VFS account opening',
            DM_Tipo__c = 'Sector'
        );
        insert sector;
        insert new List<Direccion__c>{
            new Direccion__c(
                DIR_Account__c = titular.Id,
                DIR_Tipo_Direccion__c = 'RESIDENCIA',
                DIR_Calle__c = 'Principal',
                DIR_Numero__c = '101',
                DIR_Edificio__c = 'A',
                DIR_N_Apartamento__c = '2B',
                DIR_Sector__c = sector.Id,
                DIR_Provincia_texto__c = 'Distrito Nacional'
            ),
            new Direccion__c(
                DIR_Account__c = jointHolder.Id,
                DIR_Tipo_Direccion__c = 'LABORAL',
                DIR_Calle__c = 'Trabajo',
                DIR_Numero__c = '22'
            )
        };

        List<ContactPointPhone> phones = new List<ContactPointPhone>{
            new ContactPointPhone(
                ParentId = titular.Id,
                TelephoneNumber = '8095550101',
                CPP_Tipo__c = 'TELÉFONO FIJO',
                CPP_Telefonica__c = 'Claro',
                IsPrimary = true
            ),
            new ContactPointPhone(
                ParentId = titular.Id,
                TelephoneNumber = '8095550102',
                CPP_Tipo__c = 'TELÉFONO FIJO',
                CPP_Telefonica__c = 'Claro'
            ),
            new ContactPointPhone(
                ParentId = jointHolder.Id,
                TelephoneNumber = '8095550103',
                CPP_Tipo__c = 'TELÉFONO FIJO',
                CPP_Telefonica__c = 'Claro'
            )
        };
        Map<String, Schema.SObjectField> phoneFields =
            Schema.SObjectType.ContactPointPhone.fields.getMap();
        if (phoneFields.containsKey('TelephoneType')) {
            phones[0].put('TelephoneType', 'Home');
            phones[1].put('TelephoneType', 'Work');
            phones[2].put('TelephoneType', 'Mobile');
        }
        insert phones;
        insert new ContactPointEmail(
            ParentId = titular.Id,
            EmailAddress = 'titular.coverage@example.test',
            IsPrimary = true
        );

        FinServ__FinancialAccount__c financialAccount = [
            SELECT Id
            FROM FinServ__FinancialAccount__c
            WHERE FinServ__FinancialAccountNumber__c = '9988776655'
            LIMIT 1
        ];
        VFS_nAperturaCuentasController controller =
            new VFS_nAperturaCuentasController(
                new ApexPages.StandardController(financialAccount)
            );
        controller.isFisica = false;
        controller.lstAccountFirmaConjunta = new List<Account>{ jointHolder };

        Test.startTest();
        String titularAddress = controller.getDireccionesTitular();
        String jointHolderAddress = controller.getDireccionesFirmaConjunta();
        List<String> titularContacts = controller.getViasOrdenadasTitular();
        List<String> jointHolderContacts = controller.getViasOrdenadasFirmaConjunta();
        List<String> secondJointHolderContacts = controller.getViasOrdenadasSegundaFirmaConjunta();
        Test.stopTest();

        System.assert(titularAddress.contains('Calle Principal No. 101'));
        System.assert(jointHolderAddress.contains('Calle Trabajo No. 22'));
        System.assertEquals('8095550101', titularContacts[0]);
        System.assertEquals('titular.coverage@example.test', titularContacts[3]);
        System.assert(jointHolderContacts.contains('8095550103'));
        System.assertEquals(4, secondJointHolderContacts.size());
    }

    @IsTest
    static void loadsAuthorizedSignersFromTheIntegrationResponse() {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        Account signer = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount').getRecordTypeId(),
            FirstName = 'Authorized',
            LastName = 'Coverage',
            ACC_TipoIdentificacion__c = 'Cédula',
            ACC_NumIdentificacion__c = '00108803890'
        );
        insert signer;
        signer = [
            SELECT Id, Name, ACC_NumIdentificacion__c
            FROM Account
            WHERE Id = :signer.Id
        ];

        insert new List<SObject>{
            new ContactPointEmail(
                ParentId = signer.Id,
                EmailAddress = 'authorized.coverage@example.test',
                IsPrimary = true
            ),
            new ContactPointPhone(
                ParentId = signer.Id,
                TelephoneNumber = '8095550190',
                CPP_Tipo__c = 'TELÉFONO FIJO',
                CPP_Telefonica__c = 'Claro',
                IsPrimary = true
            )
        };

        FinServ__FinancialAccount__c financialAccount = [
            SELECT Id
            FROM FinServ__FinancialAccount__c
            WHERE FinServ__FinancialAccountNumber__c = '9988776655'
            LIMIT 1
        ];
        VFS_nAperturaCuentasController controller =
            new VFS_nAperturaCuentasController(
                new ApexPages.StandardController(financialAccount)
            );
        INT026_FSC.Response response = new INT026_FSC.Response();
        response.responseList.add(new Map<String, Object>{
            'Vinculo' => 'AUTORIZADO',
            'NumeroDocumento' => signer.ACC_NumIdentificacion__c,
            'NombreCompleto' => signer.Name,
            'DarGarantia' => 'Y'
        });
        VFS_nAperturaCuentasController.testResponse = response;

        Test.startTest();
        controller.obtenerFirmantesAutorizados(financialAccount.Id);
        Test.stopTest();

        System.assertEquals('Conjunta Y', controller.tipoFirma);
        System.assertEquals(1, controller.lstAccountFirmaConjunta.size());
        System.assertEquals('Autorizado', controller.lstAccountFirmaConjunta[0].ACC_Ejecutivo__c);
        System.assertEquals(12, controller.lstFirmantesAutorizados.size());
        System.assertEquals('8095550190', controller.lstFirmantesAutorizados[0].Phone);
    }

    @IsTest
    static void loadsSingleContractAndAgreementSummaryControllers() {
        Account account = [
            SELECT Id
            FROM Account
            WHERE FirstName = 'Visualforce' AND LastName = 'Coverage'
            LIMIT 1
        ];
        ContactPointAddress address = new ContactPointAddress(
            Street = 'Calle Principal',
            City = 'Santo Domingo',
            State = 'Distrito Nacional',
            PostalCode = '10101',
            Country = 'República Dominicana',
            CPA_Distrito__c = 'Centro',
            CPA_N_Apartamento__c = '2A'
        );

        Test.startTest();
        VFS_nContratoUnicoController contractController =
            new VFS_nContratoUnicoController(new ApexPages.StandardController(account));
        VFS_nResumenConvenioUnicoController agreementController =
            new VFS_nResumenConvenioUnicoController(new ApexPages.StandardController(account));
        String contractAddress = contractController.getDireccionJuridicaFormateada(
            new List<ContactPointAddress>{ address }
        );
        String agreementAddress = agreementController.getDireccionJuridicaFormateada(
            new List<ContactPointAddress>{ address }
        );
        Test.stopTest();

        System.assertEquals(account.Id, contractController.accountId);
        System.assertEquals(account.Id, agreementController.accountId);
        System.assertNotEquals(null, contractController.getViaDeContacto());
        System.assert(contractAddress.contains('Apt. 2A'));
        System.assert(agreementAddress.contains('Santo Domingo'));
        System.assertEquals('', contractController.getDireccionJuridicaFormateada(null));
        System.assertEquals('', agreementController.getDireccionJuridicaFormateada(null));
    }

    @IsTest
    static void handlesSafeInt001AccountControllerBranches() {
        Account account = [
            SELECT Id
            FROM Account
            WHERE FirstName = 'Visualforce' AND LastName = 'Coverage'
            LIMIT 1
        ];
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));

        Test.startTest();
        INT001_VAER_Controller_FSC.Response validationResponse =
            INT001_VAER_Controller_FSC.updateAccount(account.Id);
        INT001_VAER_Controller_FSC.Response pepResponse =
            INT001_VAER_Controller_FSC.updateAccountPEP(account.Id);
        INT001_VAER_Controller_FSC.updateAccountPEPFlow(new List<Id>{ account.Id });
        Test.stopTest();

        System.assertNotEquals(null, validationResponse);
        System.assertNotEquals(null, pepResponse);
    }
}
