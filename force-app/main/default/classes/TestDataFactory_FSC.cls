/**
 * @description       : an adapted version of TestDataFactory to FinServ Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 30-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
public with sharing class TestDataFactory_FSC {

    public static void createTestData() {

        List<Datos_Maestros__c> dmList = createDatosMaestro();

        Profile p = [SELECT Id FROM Profile WHERE id = '00e3i000001RR1rAAG']; //Id de usuario estandar
        User u = new User(Alias = 'standt', Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
            LocaleSidKey ='en_US', ProfileId = p.Id,
            TimeZoneSidKey ='America/Los_Angeles', UserName = 'standardusertestvimenca@testorg.com',
            USE_Codigo__c = 'TESTCODE',
            USE_Oficina__c = dmList[0].DM_Codigo_Oficina__c
        );

        insert u;

        List<Account> personAccountList                      = createPersonAccounts(20);
        List<ContactPointAddress> direcciones                = createDirecciones(personAccountList);
        List<ContactPointPhone> viasList                     = createViasDeContacto(personAccountList);
        List<Matriz_de_producto__c> matrizList               = createMatrizDeProducto(10);
        List<FinServ__FinancialAccount__c> assetList         = createAssets_CuentaCorriente(personAccountList, direcciones, matrizList, u, 1);
        List<FinServ__FinancialAccountRole__c> vinculadoList = createVinculados(personAccountList, assetList);
    }

    public static List<Profile> createProfile() {
       List<Profile> profiles = [SELECT Id FROM Profile WHERE id='00e3i000001RR1rAAG'];
        return profiles;
    }

    public static List<Account> createPersonAccounts(Integer n) {
        Account acc;
        List<Account> accList = new List<Account>();

        for(Integer i = 1; i <= n; i++) {
            acc = new Account();
            //Verificar nombre del tipo de cliente en el entorno al que se vaya a pasar.
            acc.RecordTypeId              = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
            acc.firstName                 = 'FirstName ' + i;
            acc.lastname                  = 'Test Person Account ' + i;
            acc.ACC_CIF__c                = 'TESTCIF' + i;
            acc.ACC_TipoIdentificacion__c = 'Cédula';
            acc.FinServ__IndividualId__c  = '12345678' + i;
            acc.ACC_Nacionalidad__c       = 'REPUBLICA DOMINICANA';
            acc.PersonBirthdate           = Date.newInstance(2000, 1, 1);
            acc.ACC_Genero__c             = 'FEMENINO';
            acc.ACC_Estado_Civil__c       = 'SOLTERO/A';
            acc.ACC_RNC__c                = 'ABC13' + i;
            acc.Phone                       = '158654'+i;
            acc.ACC_Volumen_Ventas_Anual__c = 13123;
            accList.add(acc);
        }

        insert accList;
        return accList;
    }

    public static List<Account> createJuridicAccounts(Integer n) {
        Account acc;
        List<Account> accList = new List<Account>();

        for(Integer i = 1; i <= n; i++) {
            acc = new Account();
            acc.RecordTypeId              = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
            acc.name                      = 'Test Account ' + i;
            //acc.lastname                = 'Test Person Account ' + i;
            acc.ACC_RNC__c                = 'RNC' + i;
            acc.ACC_CIF__c                = 'TESTCIF'+i;
            acc.ACC_Condicion__c          = 'PROSPECTO';
            acc.ACC_Estado__c             = 'INICIADO';
            acc.ACC_TipoIdentificacion__c = 'RNC';
            accList.add(acc);
        }

        insert accList;
        createContactsForAccounts(accList);
        return accList;
    }

    private static void createContactsForAccounts(List<Account> accList) {
        List<Contact> contactList = new List<Contact>();
        Integer contactIndex = 1;
        for(Account insertedAcc : accList) {
            contactList.add(new Contact(
                AccountId = insertedAcc.Id,
                LastName = 'Contacto Test ' + contactIndex,
                Email = 'contacto.test.' + contactIndex + '@example.com'
            ));
            contactIndex++;
        }
        insert contactList;
    }

    public static List<FinServ__FinancialAccountRole__c> createVinculados(List<Account> accList, List<FinServ__FinancialAccount__c> assetList) {
        FinServ__FinancialAccountRole__c linked;
        List<FinServ__FinancialAccountRole__c> linkedList = new List<FinServ__FinancialAccountRole__c>();

        for(Account acc: accList) {
            for(FinServ__FinancialAccount__c ast: assetList) {
                linked = new FinServ__FinancialAccountRole__c();

                linked.FinServ__Role__c = 'AUTORIZADO';
                linked.FinServ__FinancialAccount__c = ast.id;
                linked.FinServ__RelatedAccount__c  = acc.id;
                linked.FAR_LegacyLinkedCode__c = 'L';
                // linked.DocumentType__c = 'RNC';

                linkedList.add(linked);
            }
        }

        insert linkedList;
        return linkedList;
    }

    public static List<FinServ__FinancialAccount__c> createAssets_CuentaCorriente(List<Account> accList, List<ContactPointAddress> dirsList, List<Matriz_de_producto__c> matrizList, User u, Integer assetsPerAccount) {
        FinServ__FinancialAccount__c ast;
        List<FinServ__FinancialAccount__c> assetList = new List<FinServ__FinancialAccount__c>();
        Integer j = 0;
        Map<Id, ContactPointAddress> direccionMapByAccountId = new Map<Id, ContactPointAddress>();

        for(ContactPointAddress d: dirsList) {
            direccionMapByAccountId.put(d.ParentId, d);
        }

        Matriz_de_producto__c matriz = new Matriz_de_producto__c();
        matriz.name = 'Matriz de producto TEST';
        matriz.PRO_Codigo_de_producto__c =  'TEST';
        insert matriz;

        Map<String, Schema.RecordTypeInfo> financialAccountRecordTypes =
            Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName();
        Id cuentaCorrienteRecordTypeId;
        if(financialAccountRecordTypes.containsKey('Cuenta_Corriente')) {
            cuentaCorrienteRecordTypeId = financialAccountRecordTypes.get('Cuenta_Corriente').getRecordTypeId();
        } else if(financialAccountRecordTypes.containsKey('Cuentas_corrientes')) {
            cuentaCorrienteRecordTypeId = financialAccountRecordTypes.get('Cuentas_corrientes').getRecordTypeId();
        } else if(financialAccountRecordTypes.containsKey('CheckingAccount')) {
            cuentaCorrienteRecordTypeId = financialAccountRecordTypes.get('CheckingAccount').getRecordTypeId();
        }

        for(Account acc: accList) {

            for(Integer i = 1; i <= assetsPerAccount; i++) {
                ast                                     = new FinServ__FinancialAccount__c();
                ast.RecordTypeId                        = cuentaCorrienteRecordTypeId;//Certificados_financieros en Asset
                ast.name                                = 'Cuenta Corriente ' + i;
                ast.FinServ__PrimaryOwner__c            = acc.id;
                ast.FIN_Moneda__c                       = 'DOP';
                ast.FinServ__FinancialAccountNumber__c  = 'CC'+j+'--'+i;
                ast.FinServ__Nickname__c                = 'ALIAS'+acc.name+j+'--'+i;
                //ast.ASE_Direccion__c                    = direccionMapByAccountId.get(acc.id).id; // TODO ver file Account.ACC_Direccion_Principal__c o FinServ__FinancialAccount__c.FinServ__Address1__c
                ast.FinServ__FinancialAccountType__c    = 'TEST'; //TODO no existe en la org?
                ast.FIN_Producto__c                     = matriz.id;
                ast.FIN_Ejecutivo__c                    = u.id; //TODO ver file
                ast.ownerId                             = u.id;
                ast.FIN_N_de_libreta__c                 = j+''+i; // TODO ver file
                ast.FIN_Tipo_de_vinculacion__c          = 'Principal'; //TODO ver file
                ast.FIN_Linea_de_producto__c            = 'Préstamos';
                assetList.add(ast);
            }
            j++;
        }

        insert assetList;
        return assetList;
    }

    public static List<ContactPointAddress> createDirecciones(List<Account> accList) {
        List<ContactPointAddress> direccionList = new List<ContactPointAddress>();
        ContactPointAddress dir;

        Datos_Maestros__c dm;

        dm = new Datos_Maestros__c(
            Name = 'Datosasd TEST',
            DM_Codigo_Oficina__c = '2',
            DM_Tipo__c = 'Oficina',
            DM_Direccion__c = 't13',
            DM_Distrito__c = '290403'
        );
        insert dm;
        Decimal i = 0;
        for(Account acc: accList) {
            dir = new ContactPointAddress();
            dir.Name                 = 'Test '+acc.Name +i;
            dir.ParentId             = acc.id;
            dir.CPA_N_Apartamento__c = '8';
            dir.Street               = 'AVENIDA ' + acc.name;
            dir.Country              = 'AZ';
            dir.State                = 'SA';
            dir.CPA_Distrito__c      = '290403';
            dir.City                 = 'A';
            dir.PostalCode           = '146';
            dir.CPA_Sector__c            = dm.Id;
            dir.CPA_ExternalId__c        = 'H-154'+i;
            i++;
            direccionList.add(dir);
        }

        insert direccionList;
        return direccionList;
    }

    public static List<ContactPointPhone> createViasDeContacto(List<Account> accList) {
        List<ContactPointPhone> viasList = new List<ContactPointPhone>();
        ContactPointPhone via;
        Decimal n = 0;

        for(Account acc: accList) {
            via = new ContactPointPhone();
            via.ParentId = acc.id;
            via.ExtensionNumber = '011';
            via.TelephoneNumber = '1156541'+n;
            viasList.add(via);
            n++;
        }

        insert viasList;
        return viasList;
    }

    public static List<Datos_Maestros__c> createDatosMaestro() {
        List<Datos_Maestros__c> dmList = new List<Datos_Maestros__c>();
        Datos_Maestros__c dm;
        Datos_Maestros__c dm2;

        dm = new Datos_Maestros__c(
            Name = 'Datos TEST',
            DM_Codigo_Oficina__c = '1',
            DM_Tipo__c = 'Oficina'
        );
        dmList.add(dm);

        dm2 = new Datos_Maestros__c(
            Name = 'Datos TEST 2',
            DM_Codigo_Externo__c = '1-AQ-4432',
            DM_Tipo__c = 'Actividad Económica',
            DM_Direccion__c = '361033'
        );
        dmList.add(dm2);

        insert dmList;
        return dmList;
    }

    public static List<Matriz_de_producto__c> createMatrizDeProducto(Integer n) {
        List<Matriz_de_producto__c> matrizList = new List<Matriz_de_producto__c>();
        Matriz_de_producto__c matriz;
        for(Integer i = 1; i <= n; i++) {
            matriz = new Matriz_de_producto__c();
            matriz.name = 'Matriz de producto TEST' + i;
            matriz.PRO_Codigo_de_producto__c =  'TEST'+i;
            matrizList.add(matriz);
        }

        insert matrizList;
        return matrizList;
    }

    public static List<FinServ__ReciprocalRole__c> createReciprocalRole(Integer n){
        List<FinServ__ReciprocalRole__c> rrList = new List<FinServ__ReciprocalRole__c>();
        FinServ__ReciprocalRole__c rr;
        Id rcId = Schema.SObjectType.FinServ__ReciprocalRole__c.getRecordTypeInfosByDeveloperName().get('ContactRole').getRecordTypeId();
        for(Integer i = 1; i <= n; i++) {
            rr = new FinServ__ReciprocalRole__c();
            rr.Name = 'Test'+i;
            rr.FinServ__InverseRole__c = 'Test'+i;
            rr.FinServ__RelationshipType__c =  'All';
            rr.FinServ__CreateInverseRole__c = true;
            rr.recordTypeId = rcId;
            rrList.add(rr);
        }

        insert rrList;
        return rrList;
    }

    public static List<FinServ__ReciprocalRole__c> createReciprocalRoleAccountRole(Integer n){
        List<FinServ__ReciprocalRole__c> rrList = new List<FinServ__ReciprocalRole__c>();
        FinServ__ReciprocalRole__c rr;
        Id rcId = Schema.SObjectType.FinServ__ReciprocalRole__c.getRecordTypeInfosByDeveloperName().get('AccountRole').getRecordTypeId();
        for(Integer i = 1; i <= n; i++) {
            rr = new FinServ__ReciprocalRole__c();
            rr.Name = 'Test';
            rr.FinServ__InverseRole__c = 'InverseTest';
            rr.FinServ__RelationshipType__c =  'All';
            rr.FinServ__CreateInverseRole__c = true;
            rrList.add(rr);
        }

        insert rrList;
        return rrList;
    }

    /*public static FinServ__Employment__c createEmployment(Account accList){

        FinServ__Employment__c emp;
        Decimal n = 0;
        List<Account> contact = [SELECT PersonContactId FROM Account WHERE Id =: accList[0].Id];

        emp = new ContactPointPhone();
        emp.Cliente__c = contact.PersonContactId;
        emp.

        insert emp;
        return emp;
    }*/
}
