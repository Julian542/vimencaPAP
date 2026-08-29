/*********************************************************************************************
 * Nombre de clase Test   :   VFS_KYCFisica_ControllerTest
 * Versión                :   1.0
 * Fecha de actualización :   15/07/2025
 * Función                :   Pruebas unitarias para la clase VFS_KYCFisica_Controller
 * Clase probada          :   VFS_KYCFisica_Controller
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Carlos David Ventura               15/07/2025      Versión inicial
 *********************************************************************************************/


@isTest
public class VFS_KYCFisica_ControllerTest {
    private static Account createNeutralAccount(String name) {
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = name,
            ACC_RNC__c = String.valueOf(Math.abs(Crypto.getRandomInteger())).leftPad(9, '0').substring(0, 9),
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC',
            OwnerId = UserInfo.getUserId(),
            VFS_ActividadEconomica__c = 'Sector Agrícola',
            VFS_EspecifiqueOtro__c = 'Otro'
        );
        insert acc;
        return acc;
    }

    @isTest
    static void MakeData(){
        RecordType personalRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        Account personalAccount = new Account(
            FirstName = 'Personal Account',
            LastName = 'test',
            RecordTypeId = personalRecordType.Id
        );
        insert personalAccount;
        
        // Consulta la cuenta creada anteriormente
        Account queriedAccount = [SELECT Id, FirstName, LastName, PersonContactId FROM Account WHERE Id = :personalAccount.Id LIMIT 1];


    // Create a test Account
        Account testAccount = createNeutralAccount('Test Account');

        AccountContactRelation acr = new AccountContactRelation(
            AccountId = testAccount.Id,
            ContactId = queriedAccount.PersonContactId,
            Tipo_de_relacion__c = 'Relacionado'
        );
        insert acr;
        
        Account testAccount1 = createNeutralAccount('Test Account 1');

        // Create a test Contact
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe'
        );
        insert testContact;

        // Create a test Referencia__c
        Referencia__c testReferencia = new Referencia__c(
            Account__c = testAccount.Id,
            REF_Tipo__c = 'Bancaria',
            Tipo_de_cuenta__c = 'Cuenta de Ahorro',
            Banco__c = 'Test Bank',
            Pais__c = 'DO',
            Moneda__c = 'USD',
            N_de_cuenta__c = '1234567890',
            VFS_RNC__c = 'RNC123',
            REF_Nombre__c = 'Test Name',
            REF_Telefono__c = '1234567890',
            REF_Direccion__c = 'Test Address'
        );
        insert testReferencia;
        
        // Create a test Referencia__c
        Referencia__c testReferenciaPersonal = new Referencia__c(
            Account__c = testAccount.Id,
            REF_Tipo__c = 'Personal',
            Tipo_de_cuenta__c = 'Cuenta de Ahorro',
            Banco__c = 'Test Bank',
            Pais__c = 'DO',
            Moneda__c = 'USD',
            N_de_cuenta__c = '1234567890',
            VFS_RNC__c = 'RNC123',
            REF_Nombre__c = 'Test Name',
            REF_Telefono__c = '1234567890',
            REF_Direccion__c = 'Test Address'
        );
        insert testReferenciaPersonal;
        
        // Create a test Referencia__c
        Referencia__c testReferenciaComercial = new Referencia__c(
            Account__c = testAccount.Id,
            REF_Tipo__c = 'Comercial',
            Tipo_de_cuenta__c = 'Cuenta de Ahorro',
            Banco__c = 'Test Bank',
            Pais__c = 'DO',
            Moneda__c = 'USD',
            N_de_cuenta__c = '1234567890',
            VFS_RNC__c = 'RNC123',
            REF_Nombre__c = 'Test Name',
            REF_Telefono__c = '1234567890',
            REF_Direccion__c = 'Test Address'
        );
        insert testReferenciaComercial;

        // Create a test Direccion__c
        Direccion__c testDireccion = new Direccion__c(
            DIR_Account__c = testAccount.Id,
            DIR_Estado_Ciudad__c = 'Test City',
            DIR_Calle__c = 'Test Street',
            DIR_Numero__c = '123',
            DIR_Edificio__c = 'Test Building',
            DIR_Direccion_Traduccion__c = 'Test Translation',
            DIR_N_Apartamento__c = '123',
            DIR_Distrito_texto__c = 'SANTO DOMINGO OESTE',
            DIR_Municipio_texto__c = 'SANTO DOMINGO OESTE',
            DIR_Provincia_texto__c = 'SANTO DOMINGO',
            DIR_Pais__c = 'DO'
        );
        insert testDireccion;

        // Create a test Historial_laboral__c
        Historial_laboral__c testHistorial = new Historial_laboral__c(
            HIS_Cuenta__c = testAccount.Id,
            HIS_Ocupacion__c = 'ADMINISTRADOR',
            Tipo_de_empleado__c = '1',
            HIS_Empresa__c = 'Test Company',
            Tiempo_de_empresa__c = '1 year',
            HIS_Puesto_de_trabajo__c = 'Test Position'
        );
        insert testHistorial;

        // Create a test Vias_de_Contacto__c
        Vias_de_Contacto__c testVia = new Vias_de_Contacto__c(
            VIA_Account__c = testAccount.Id,
            VIA_Numero_Correo__c = '8097897894',
            VIA_de_Contacto__c = 'TELÉFONO MÓVIL',
            VIA_Telefonica__c = 'Claro'
        );
        Database.insert(testVia, false);

        // Create a test Informacion_Financiera__c
        Informacion_Financiera__c testInfoFinanciera = new Informacion_Financiera__c(
            INF_Cuenta__c = testAccount.Id,
            Otros_Ingresos__c = 1000,
            INF_Fuente_de_ingresos__c = 'Herencia'
        );
        insert testInfoFinanciera;

        // Create a test AccountContactRelation


        // Create a test Productos_y_Servicios__c
        Productos_y_Servicios__c testProductoServicio = new Productos_y_Servicios__c(
            Cliente__c = testAccount.Id,
            Name = 'Test Product'
        );
        insert testProductoServicio;

        // Create a test Cliente_c
        Participante__c testClientePrincipal = new Participante__c(
            PAR_Cliente__c = testAccount.Id,
            Participante__c = testAccount1.id
        );
        insert testClientePrincipal;

        // Create a test Proveedor__c
        Principal_Proveedor__c testProveedorPrincipal = new Principal_Proveedor__c(
            Cliente__c = testAccount.Id,
            Name = 'Test Provider',
            Tipo_de_identificaci_n__c = 'RNC',
            N_de_Identificacion__c = '1234567890'
        );
        insert testProveedorPrincipal;

        // Create a test Participante__c
        Participante__c testParticipante = new Participante__c(
            PAR_Cliente__c = testAccount.Id,
            PAR_Cargo__c = 'Representante legal',
            Participante__c = testAccount1.id
        );
        insert testParticipante;

        // Create a test Empresa_Filial__c
        Empresa_Filial__c testEmpresaFilial = new Empresa_Filial__c(
            Cliente__c = testAccount.Id,
            Name = 'Test Branch',
            RNC__c = 'RNC123',
            Pais_donde_opera__c = 'DO',
            Grupo_economico__c = 'Test Group',
            Grupo_financiero__c = 'Test Financial Group'
        );
        insert testEmpresaFilial;

        // Create a test Participante__c for Socio Extranjero
        Participante__c testSocioExtranjero = new Participante__c(
            PAR_Cliente__c = testAccount.Id,
            PAR_Cargo__c = 'Accionista',
            Participante__r = testAccount1,
            Participante__c = testAccount1.id
            /*new Account(
                ACC_SSN_FATCA__c = '123456789',
                ACC_N_Pasaporte_FATCA__c = 'Passport123',
                ACC_Nacionalidad_FATCA__c = 'ESTADOS UNIDOS',
                ACC_Pais_Residencia_Legal__c = 'ESTADOS UNIDOS'
            )*/
        );
        insert testSocioExtranjero;

        // Create a test StandardController
        ApexPages.StandardController stdController = new ApexPages.StandardController(testAccount);

        // Instantiate the VFS_KYCFisica_Controller
        VFS_KYCFisica_Controller controller = new VFS_KYCFisica_Controller(stdController);
        controller.formatearDireccion(testDireccion);
    }
    
    @isTest
    static void EmptyFiles(){
        // Create a test Account
        Account testAccount = createNeutralAccount('Test Account');
        
        // Create a test StandardController
        ApexPages.StandardController stdController = new ApexPages.StandardController(testAccount);

        // Instantiate the VFS_KYCFisica_Controller
        VFS_KYCFisica_Controller controller = new VFS_KYCFisica_Controller(stdController);
    }

    @isTest
    static void rendersPersonAccountPdfWithFormattedAddresses(){
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        RecordType personalRecordType = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account' AND IsPersonType = true
            LIMIT 1
        ];
        Account personAccount = new Account(
            FirstName = 'Kyc',
            LastName = 'Pdf',
            RecordTypeId = personalRecordType.Id
        );
        insert personAccount;

        insert new List<Direccion__c>{
            new Direccion__c(
                DIR_Account__c = personAccount.Id,
                DIR_Tipo_Direccion__c = 'RESIDENCIA',
                DIR_Calle__c = 'Principal',
                DIR_Numero__c = '14',
                DIR_Edificio__c = 'Torre B',
                DIR_N_Apartamento__c = '4C',
                DIR_Pais__c = 'DO'
            ),
            new Direccion__c(
                DIR_Account__c = personAccount.Id,
                DIR_Tipo_Direccion__c = 'LABORAL',
                DIR_Calle__c = 'Trabajo',
                DIR_Numero__c = '20',
                DIR_Pais__c = 'DO'
            ),
            new Direccion__c(
                DIR_Account__c = personAccount.Id,
                DIR_Tipo_Direccion__c = 'EMPRESARIAL',
                DIR_Calle__c = 'Empresa',
                DIR_Numero__c = '30',
                DIR_Pais__c = 'DO'
            )
        };
        insert new List<Vias_de_Contacto__c>{
            new Vias_de_Contacto__c(
                VIA_Account__c = personAccount.Id,
                VIA_de_Contacto__c = 'TELÉFONO FIJO',
                VIA_Numero_Correo__c = '8095550104',
                VIA_Telefonica__c = 'Claro'
            ),
            new Vias_de_Contacto__c(
                VIA_Account__c = personAccount.Id,
                VIA_de_Contacto__c = 'CORREO ELECTRÓNICO',
                VIA_Numero_Correo__c = 'kyc.pdf@example.com'
            )
        };
        insert new Informacion_Financiera__c(
            INF_Cuenta__c = personAccount.Id,
            Otros_Ingresos__c = 500,
            INF_Fuente_de_ingresos__c = 'Herencia'
        );

        Test.setCurrentPageReference(new PageReference('/apex/VFSKYC'));
        ApexPages.currentPage().getParameters().put('pdf', '1');
        Test.startTest();
        VFS_KYCFisica_Controller controller = new VFS_KYCFisica_Controller(
            new ApexPages.StandardController(personAccount)
        );
        Test.stopTest();

        System.assert(controller.isFisica);
        System.assertEquals('Calle Principal No. 14, Edif. Torre B, Apt. 4C',
            controller.dirResidencia.DIR_Direccion_Traduccion__c);
        System.assertEquals('No. 7', controller.formatearDireccion(
            new Direccion__c(DIR_Numero__c = '7')
        ));
        System.assertEquals('', controller.formatearDireccion(null));
    }
}
