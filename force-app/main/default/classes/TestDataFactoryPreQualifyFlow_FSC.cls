/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 13-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
public with sharing class TestDataFactoryPreQualifyFlow_FSC {

    public static void createTestData() {

        Profile p = [SELECT Id FROM Profile WHERE id='00e3i000001RR1rAAG']; //Id de usuario estandar 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertestvimenca@testorg.com',
                          USE_Codigo__c = 'TESTCODE');

        insert u;

        List<Account> personAccountList = crearCandidatoPF(2);
        //List<FinServ__FinancialAccountRole__c> participanteList = createBasicAcionista(personAccountList);
        List<FinServ__Employment__c> historialList = createHistorial(personAccountList);
    }

    public static List<Profile> createProfile() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE id='00e3i000001RR1rAAG'];
        return profiles;
    }

    /**
     * Metodos para ValidatePreQualifyFlowController
    **/
    public static List<Account> crearBasicCandidatoPJ(Integer n) {
        Account acc;
        List<Account> accList = new List<Account>();

        for(Integer i = 1; i <= n; i++) {
            acc = new Account();
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
            acc.Name = 'Test Account ' + i;
            acc.ACC_TipoIdentificacion__c = 'RNC';
            accList.add(acc);
        }

        insert accList;
        return accList;
    }

    public static List<Account> crearBasicCandidatoPF(Integer n) {
        Account acc;
        List<Account> accList = new List<Account>();

        for(Integer i = 1; i <= n; i++) {
            acc = new Account();
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Fisica').getRecordTypeId();
            acc.lastname = 'Test Person Account ' + i;
            acc.ACC_TipoIdentificacion__c = 'Cédula';
            acc.ACC_Persona_Fisica__c = true;
            accList.add(acc);
        }

        insert accList;
        return accList;
    }

    public static List<Informacion_Financiera__c> createBasicInfoFinan(List<Account> accList){
        List<Informacion_Financiera__c> infoFinanLIst = new List<Informacion_Financiera__c>();
        for(Account acc: accList){
            Informacion_Financiera__c info = new Informacion_Financiera__c();
            info.INF_Cuenta__c = acc.Id;
            infoFinanLIst.add(info);
        }
        insert infoFinanLIst;
        return infoFinanLIst;
    }

    /*public static List<FinServ__FinancialAccountRole__c> createBasicAcionista(List<Account> accList){
        List<FinServ__FinancialAccountRole__c> accioList = new List<FinServ__FinancialAccountRole__c>();
        for(Account acc: accList){
            FinServ__FinancialAccountRole__c accionista = new FinServ__FinancialAccountRole__c();
            accionista.FinServ__FinancialAccountRole__c = acc.id;
            accioList.add(accionista);
        }
        insert accioList;
        return accioList;
    }

    public static List<FinServ__FinancialAccountRole__c> createBasicRepresentante(List<Account> accList){
        List<FinServ__FinancialAccountRole__c> repreList = new List<FinServ__FinancialAccountRole__c>();
        for(Account acc: accList){
            FinServ__FinancialAccountRole__c repre = new FinServ__FinancialAccountRole__c();
            repre.FinServ__FinancialAccountRole__c = acc.id;
            repreList.add(repre);
        }
        insert repreList;
        return repreList;
    }*/

    public static List<FinServ__Employment__c> createBasicHistorial(List<Account> accList){
        List<FinServ__Employment__c> histList = new List<FinServ__Employment__c>();
        FinServ__Employment__c histL;
        for(Account acc: accList){
            histL = new FinServ__Employment__c();
            histL.Cliente__c = acc.Id;
            histList.add(histL);
        }
        insert histList;
        return histList;
    }

    /**
     * Metodos para PreQualifyFlowHandlertest
     **/
    public static List<Account> crearCandidatoPF(Integer n) {
        Account acc;
        List<Account> accList = new List<Account>();

        for(Integer i = 1; i <= n; i++) {
            acc = new Account();
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Fisica').getRecordTypeId();
            acc.ACC_Persona_Fisica__c = true;
            acc.firstName = 'FirstName ' + i;
            acc.middleName = 'MiddleName '+ i;
            acc.lastname = 'Test Person Account ' + i;
            acc.Suffix = 'suffix '+ i;
            acc.ACC_CIF__c = 'TESTCIF'+i;
            acc.ACC_TipoIdentificacion__c = null;
            acc.ACC_NumIdentificacion__c = '12345678';
            acc.ACC_DeclaracionSiManejaOpInternacionales__c = true;
            acc.ACC_DeclaracionSiProyectaManejarEfectivo__c = true;
            acc.ACC_Nombre_Corto_Comercial__c = 'Gustavo';
            acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
            acc.ACC_Fecha_Fundacion__c = Date.newInstance(2000, 1, 1);
            acc.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
            acc.ACC_Pais_Nacimiento__c = 'REPUBLICA DOMINICANA';
            acc.ACC_Actividad_Economica__c = null;
            acc.ACC_Canales_a_utilizar__c = 'Cajeros Automáticos y Tarjetas de Débito';
            acc.ACC_ProductosASolicitar__c = '10;9';
            acc.ACC_servicios_a_solicitar__c = 'b;d';
            acc.ACC_Tipo_beneficio_final__c = '1';
            acc.ACC_Relacion_de_dignatarios__c = '1';
            acc.ACC_Persona_PEP__c = 'SI';
            acc.ACC_Familiar_PEP__c = true;
            acc.ACC_Colaborador_de_PEP__c = true;
            acc.ACC_Tipo_Organizacion__c = 'CONSORCIOS';
            accList.add(acc);
        }

        insert accList;
        return accList;
    }

    public static List<FinServ__Employment__c> createHistorial(List<Account> accList){
        List<FinServ__Employment__c> histList = new List<FinServ__Employment__c>();
        FinServ__Employment__c histL;

        for(Account acc: accList){
            histL = new FinServ__Employment__c();
            histL.Cliente__c = acc.Id;
            histL.EMP_Empleo__c = 'ACTUAL';
            histL.FinServ__Occupation__c = '  ABOGADO';
            histL.FinServ__StartDate__c = Date.newInstance(2000, 1, 1);
            histList.add(histL);
        }
        insert histList;
        return histList;
    }


    public static List<Informacion_Financiera__c> createInfoFinan(List<Account> accList){
        List<Informacion_Financiera__c> infoFinanLIst = new List<Informacion_Financiera__c>();
        for(Account acc: accList){
            Informacion_Financiera__c info = new Informacion_Financiera__c();
            info.INF_Cuenta__c = acc.Id;
            info.INF_Ingresos__c = 'RD$ 100,001 A RD$ 135,000';
            infoFinanLIst.add(info);
        }
        insert infoFinanLIst;
        return infoFinanLIst;
    }

    public static List<Account> createAccounts(Integer n) {
        Account acc;
        List<Account> accList = new List<Account>();

        for(Integer i = 1; i <= n; i++) {
            acc = new Account();
            //Verificar nombre del tipo de cliente en el entorno al que se vaya a pasar.
            acc.firstName = 'FirstName ' + i;
            acc.middleName = 'MiddleName '+ i;
            acc.lastname = 'Test Person Account ' + i;
            acc.Suffix = 'suffix '+ i;
            acc.ACC_CIF__c = 'TESTCIF'+i;
            //acc.ACC_Fecha_Fundacion__c = Date.newInstance(2000, 1, 1);
            acc.ACC_INT_Tipo_de_identificacion__c='Cédula';
            acc.ACC_TipoIdentificacion__c = 'Cédula';
            acc.ACC_NumIdentificacion__c='12345678';
            acc.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
            //acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
            acc.ACC_Genero__c = 'FEMENINO';
            acc.ACC_Estado_Civil__c = 'SOLTERO/A';
            //acc.ACC_Nombre_Corto_Comercial__c = 'pelope';
            accList.add(acc);
        }

        insert accList;
        return accList;
    }

}
