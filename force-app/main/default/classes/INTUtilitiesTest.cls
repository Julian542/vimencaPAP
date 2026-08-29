@isTest
public class INTUtilitiesTest {
    public static Map<String, String> valuesClient = new Map<String, String>{
        '[function_document]' => 'ACC_NumIdentificacion__c',  //principal fields
            '[function_documentType]' => 'ACC_TipoIdentificacion__c',
            '[function_firstName]' => 'FirstName',
            '[function_lastName]' => 'LastName',
            '[function_midleName]' => 'MiddleName',
            '[function_sufijo]' => 'Suffix',
            '[function_gender]' => 'ACC_Genero__c',
            '[function_maritalStatus]' => 'ACC_Estado_Civil__c',
            '[function_birthDate]' => 'PersonBirthdate',
            '[function_nacionality]' => 'ACC_Nacionalidad__c',
            '[function_clientType]' => 'ACC_Tipo_Cliente_PF__c',
            '[function_laboralSector]' => 'ACC_Tipo_Sector__c',//Obligatoriio
            '[function_ActivityType]' => 'ACC_Tipo_Actividad__c',
            '[function_segment]' => 'ACC_Segmento__c',
            '[function_totalAssets]' => 'ACC_Total_Activos__c',
            '[function_numEmployees]' => 'ACC_NumEmpleados__c'//principal fields
            };

    public static Map<String, String> valuesAdresses = new Map<String, String>{
        '[function_addressId]' => 'DIR_Id_Externo_Direccion__c',
            '[function_addressExternalIdBk]' => 'DIR_Id_Externo_Direccion_bk__c', //Este fue el nuevo campo agregado
            '[function_addressIdentifier]' => 'DIR_Identificador__c',
            '[function_addressPrimary]' => 'DIR_Principal__c',
            '[function_addressType]' => 'DIR_Tipo_Direccion__c',
            '[function_addressStreet]' => 'DIR_Calle__c',
            '[function_addressNum]' => 'DIR_Numero__c',
            '[function_addressBuilding]' => 'DIR_Edificio__c',
            '[function_addressNumFloor]' => 'DIR_N_Apartamento__c',
            '[function_addressCountry]' => 'DIR_Pais_Texto__c',
            '[function_addressProvince]' => 'DIR_Provincia__c',
            '[function_addressMunicipality]' => 'DIR_Municipio__c',
            '[function_addressMunicipalDistrict]' => 'DIR_Distrito__c',
            '[function_addressSector]' => 'DIR_Sector__c',
            '[function_addressPostalCode]' => 'DIR_Apartado_postal__c',
            '[function_addressCityStatePC]' => 'DIR_Estado_Ciudad__c',
            '[function_addressPhone]' => 'DIR_N_Telefono__c',
            '[function_addressPhoneEx]' => 'DIR_Extension__c',
            '[function_addressExtraPhone1]' => 'DIR_Telefono_adicional__c',
            '[function_addressExtraPhone2]' => 'DIR_Telef_Adicional__c'
            };

    public static Map<String, String> valuesContactInfo = new Map<String, String>{
            '[function_contactInfoId]' => 'VIA_Id_Externo_Via__c',
                '[function_ViaIdExternoVia]' => 'VIA_Id_Externo_Via_bk__c', //Este fue el nuevo campo agregado
                '[function_contactInfoIdentifier]' => 'VIA_Identificador__c',
                '[function_contactPrincipal]' => 'VIA_Principal__c',
                '[function_contactWayType]' => 'VIA_de_Contacto__c',
                '[function_contactWayCant]' => 'VIA_Numero_Correo__c',
                '[function_contactCompany]' => 'VIA_Telefonica__c',
                '[function_contactSMS]' => 'VIA_Envio_SMS__c',
                '[function_contactExRef]' => 'VIA_Id_Externo_Via__c'
                };

    @isTest
    static void INTUtilTest(){        
        List<Account> accList= TestDataFactory.createPersonAccounts(2);
        
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
        accList[0].lastname = 'Test Person Account ';
        
        accList[0].ACC_RNC__c = 'RNC';
        accList[0].ACC_CIF__c = 'TESTCIF';
        accList[0].ACC_Condicion__c='PROSPECTO';
        accList[0].ACC_Estado__c='CONVERTIR';
        accList[0].ACC_TipoIdentificacion__c='Cédula';
        accList[0].ACC_NumEmpleados__c=150;
        accList[0].ACC_Volumen_Ventas_Anual__c=1500000000;
        //accList[0].ACC_Actividad_Economica__c = maestro[0].id;
        accList[0].PersonBirthdate = date.today();
        accList[0].ACC_Total_Activos__c=1500000000;        
        
        Test.startTest();
        INTUtilities.fillCorrectType(INTUtilitiesTest.valuesClient,accList[0],'prova');
        Test.stopTest();
    }

    @isTest
    static void addressValuesNameTest(){
        List<Account> accList = TestDataFactory.createPersonAccounts(2);
        List<Direccion__c> direcciones = TestDataFactory.createDirecciones(accList);

        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
        Test.startTest();
        INTUtilities.fillCorrectType(INTUtilitiesTest.valuesAdresses, direcciones[0], 'prova');
        Test.stopTest();
    }

    @isTest
    static void addressValuesIdentificadorTest(){
        List<Account> accList = TestDataFactory.createPersonAccounts(2);
        List<Direccion__c> direcciones = TestDataFactory.createDirecciones(accList);

        direcciones[0].DIR_Identificador__c = 'Test Identificador';

        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
        Test.startTest();
        INTUtilities.fillCorrectType(INTUtilitiesTest.valuesAdresses, direcciones[0], 'prova');
        Test.stopTest();
    }

    @isTest
    static void addressValuesNOIdentificadorTest(){
        List<Account> accList = TestDataFactory.createPersonAccounts(2);
        List<Direccion__c> direcciones = TestDataFactory.createDirecciones(accList);

        direcciones[0].DIR_Id_Externo_Direccion__c = 'Test Identificador';

        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
        Test.startTest();
        INTUtilities.fillCorrectType(INTUtilitiesTest.valuesAdresses, direcciones[0], 'prova');
        Test.stopTest();
    }

    @isTest
    static void addressValuesDatosMaestrosTest(){
        List<Account> accList = TestDataFactory.createPersonAccounts(2);
        List<Direccion__c> direcciones = TestDataFactory.createDirecciones(accList);

        Datos_Maestros__c datos = new Datos_Maestros__c();
        datos.Name = 'Test datos Maestros';
        insert datos;

        direcciones[0].DIR_Sector__c = datos.Id;

        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
        Test.startTest();
        INTUtilities.fillCorrectType(INTUtilitiesTest.valuesAdresses, direcciones[0], 'prova');
        Test.stopTest();
    }

    @isTest
    static void contactWaysValuesNameTest(){
        List<Account> accList = TestDataFactory.createPersonAccounts(2);
        List<Direccion__c> direcciones = TestDataFactory.createDirecciones(accList);
        List<Vias_de_Contacto__c> viasList = TestDataFactory.createViasDeContacto(accList);

        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
        Test.startTest();
        INTUtilities.fillCorrectType(INTUtilitiesTest.valuesContactInfo,viasList[0],'prova');
        Test.stopTest();
    }

    @isTest
    static void contactWaysIdentificadorValuesTest(){
        List<Account> accList = TestDataFactory.createPersonAccounts(2);
        List<Direccion__c> direcciones = TestDataFactory.createDirecciones(accList);
        List<Vias_de_Contacto__c> viasList = TestDataFactory.createViasDeContacto(accList);

        viasList[0].VIA_Identificador__c = 'Test Identificador';

        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
        Test.startTest();
        INTUtilities.fillCorrectType(INTUtilitiesTest.valuesContactInfo,viasList[0],'prova');
        Test.stopTest();
    }

    @isTest
    static void contactWaysNOIdentificadorValuesTest(){
        List<Account> accList = TestDataFactory.createPersonAccounts(2);
        List<Direccion__c> direcciones = TestDataFactory.createDirecciones(accList);
        List<Vias_de_Contacto__c> viasList = TestDataFactory.createViasDeContacto(accList);

        viasList[0].VIA_Id_Externo_Via__c = 'Test Identificador';

        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
        Test.startTest();
        INTUtilities.fillCorrectType(INTUtilitiesTest.valuesContactInfo,viasList[0],'prova');
        Test.stopTest();
    }

    @isTest
    static void scalarDateTimeBooleanAndEmptyValuesTest() {
        Account scalarAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'INT Utilities scalar ' + String.valueOf(DateTime.now().getTime()),
            ACC_Persona_Fisica__c = false,
            ACC_RNC__c = 'RNC-INT-UTIL-' + String.valueOf(DateTime.now().getTime()),
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC'
        );
        insert scalarAccount;
        Account account = [
            SELECT Id, LastModifiedDate, ACC_Persona_Fisica__c, PersonBirthdate
            FROM Account
            WHERE Id = :scalarAccount.Id
            LIMIT 1
        ];

        String frame = INTUtilities.fillCorrectType(
            new Map<String, String>{
                '[date]' => 'PersonBirthdate',
                '[datetime]' => 'LastModifiedDate',
                '[boolean]' => 'ACC_Persona_Fisica__c',
                '[empty]' => ''
            },
            account,
            '[date]|[datetime]|[boolean]|[empty]'
        );

        Datos_Maestros__c master = new Datos_Maestros__c(
            Name = 'INT Utilities master data',
            DM_Direccion__c = 'MASTER-001'
        );
        insert master;
        ContactPointAddress address = new ContactPointAddress();
        address.put('CPA_Sector__c', master.Id);
        String masterFrame = INTUtilities.fillCorrectType(
            new Map<String, String>{ '[sector]' => 'CPA_Sector__c' },
            address,
            '[sector]'
        );
        account.ACC_NumEmpleados__c = null;
        String numericFallback = INTUtilities.fillCorrectType(
            new Map<String, String>{ '[function_numEmployees]' => 'ACC_NumEmpleados__c' },
            account,
            '[function_numEmployees]'
        );
        Account addressAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'INT Utilities address ' + String.valueOf(DateTime.now().getTime()),
            ACC_RNC__c = 'RNC-INT-ADDR-' + String.valueOf(DateTime.now().getTime()),
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC'
        );
        insert addressAccount;
        List<Direccion__c> createdAddresses = TestDataFactory.createDirecciones(
            new List<Account>{ addressAccount }
        );
        Direccion__c fallbackAddress = [
            SELECT Id, Name, DIR_Identificador__c
            FROM Direccion__c
            WHERE Id = :createdAddresses[0].Id
            LIMIT 1
        ];
        String addressFallback = INTUtilities.fillCorrectType(
            new Map<String, String>{ '[identifier]' => 'DIR_Identificador__c' },
            fallbackAddress,
            '[identifier]'
        );

        System.assert(frame.contains('|'));
        System.assert(masterFrame.contains('INT Utilities master data'));
        System.assert(numericFallback.contains('0'));
        System.assertNotEquals(null, addressFallback);
    }
    
}
