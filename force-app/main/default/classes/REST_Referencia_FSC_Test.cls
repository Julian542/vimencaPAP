/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 06-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
private with sharing class REST_Referencia_FSC_Test {

    @TestSetup
    static void makeData(){
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        TestDataFactory_FSC.createDatosMaestro();
        TestDataFactory_FSC.createJuridicAccounts(2);
        TestDataFactory_FSC.createReciprocalRole(1);

        Account acc = new Account();
        //Verificar nombre del tipo de cliente en el entorno al que se vaya a pasar.
        acc.RecordTypeId              = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        acc.firstName                 = 'FirstNameIs';
        acc.lastname                  = 'Test Person Account 112';
        acc.ACC_CIF__c                = '000000000';
        acc.ACC_TipoIdentificacion__c = 'Cédula';
        acc.FinServ__IndividualId__c  = '12045678';
        acc.ACC_Nacionalidad__c       = 'REPUBLICA DOMINICANA';
        acc.PersonBirthdate           = Date.newInstance(2000, 1, 1);
        acc.ACC_Genero__c             = 'FEMENINO';
        acc.ACC_Estado_Civil__c       = 'SOLTERO/A';
        acc.ACC_RNC__c                = 'ABC13';
        acc.ACC_Volumen_Ventas_Anual__c = 13123;

        insert acc;

        FinServ__ReciprocalRole__c rr = new FinServ__ReciprocalRole__c();
        rr.Name = 'Sin Asignar';
        rr.FinServ__InverseRole__c = 'Sin Asignar';
        rr.FinServ__RelationshipType__c =  'Contact Contact Relation';
        rr.FinServ__CreateInverseRole__c = true;
        rr.recordTypeId = Schema.SObjectType.FinServ__ReciprocalRole__c.getRecordTypeInfosByDeveloperName().get('ContactRole').getRecordTypeId();
        insert rr;

        FinServ__ReciprocalRole__c rr2 = new FinServ__ReciprocalRole__c();
        rr2.Name = 'Sin Asignar';
        rr2.FinServ__InverseRole__c = 'Sin Asignar';
        rr2.FinServ__RelationshipType__c =  'Contact Contact Relation';
        rr2.FinServ__CreateInverseRole__c = true;
        rr2.recordTypeId = Schema.SObjectType.FinServ__ReciprocalRole__c.getRecordTypeInfosByDeveloperName().get('ContactRole').getRecordTypeId();
        insert rr2;

        rr.FinServ__InverseRelationship__c = rr2.Id;
        rr2.FinServ__InverseRelationship__c = rr.Id;

        update new List<FinServ__ReciprocalRole__c>{rr, rr2};
    }

    @isTest
    private static void testPut404(){
        List<REST_Referencia_FSC.ReferenciaDTO> ReferenciaList = new List<REST_Referencia_FSC.ReferenciaDTO>();
        REST_Referencia_FSC.ReferenciaDTO referencia0 = new REST_Referencia_FSC.ReferenciaDTO();
        referencia0.ACC_CIF_c           = 'TESTCIF0';
        referencia0.Account_c           = '0013J00000T4VeMQAV';
        referencia0.Banco_c             = 'Banco Vimenca';
        referencia0.Moneda_c            = 'DOP';
        referencia0.N_De_Cuenta_c       = '7895673451';
        referencia0.Pais_c              = 'DO';
        referencia0.REF_Direccion_c     = 'AV. JOHN F. KENNEDY';
        referencia0.REF_Id_Externo_c    = '1-3GIZV';
        referencia0.REF_Nombre_c        = 'BANCO POPULAR';
        referencia0.REF_Telefono_c      = '8095445556';
        referencia0.REF_Tipo_c          = 'PERSONAL';
        referencia0.Tipo_de_Cuenta_c    = 'Cuenta Corriente';
        ReferenciaList.add(referencia0);

        String reqBody = JSON.serialize(ReferenciaList);

        RestRequest request = new RestRequest();
        request.requestURI  = URL.getOrgDomainUrl()+'/services/apexrest/referencia/upsert/';
        request.httpMethod  = 'PUT';
        request.requestBody = Blob.valueOf(reqBody);

        RestResponse res     = new RestResponse();
        RestContext.request  = request;
        RestContext.response = res;
        REST_Referencia_FSC.doPut();
        System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    private static void testPut200(){
        Account account = buildNeutralAccount('Cliente PUT 200', 'CIFPUT200');
        insert account;
        Contact clientContact = new Contact(LastName = 'Cliente PUT 200', AccountId = account.Id);
        Contact referralContact = new Contact(LastName = 'BANCO POPULAR');
        insert new List<Contact>{ clientContact, referralContact };

        List<REST_Referencia_FSC.ReferenciaDTO> ReferenciaList = new List<REST_Referencia_FSC.ReferenciaDTO>();
        REST_Referencia_FSC.ReferenciaDTO referencia1 = new REST_Referencia_FSC.ReferenciaDTO();
        referencia1.ACC_CIF_c           = 'CIFPUT200';
        referencia1.Account_c           = account.Id;
        referencia1.Banco_c             = 'Banco Vimenca';
        referencia1.Moneda_c            = 'DOP';
        referencia1.N_De_Cuenta_c       = '7895673451';
        referencia1.Pais_c              = 'DO';
        referencia1.REF_Direccion_c     = 'AV. JOHN F. KENNEDY';
        referencia1.REF_Id_Externo_c    = '1-3GIZV';
        referencia1.REF_Nombre_c        = 'BANCO POPULAR';
        referencia1.REF_Telefono_c      = '8095445556';
        referencia1.REF_Tipo_c          = 'COMERCIAL';
        referencia1.Tipo_de_Cuenta_c    = 'Cuenta Corriente';
        ReferenciaList.add(referencia1);

        String reqBody = JSON.serialize(ReferenciaList);

        RestRequest request = new RestRequest();
        request.requestURI= URL.getOrgDomainUrl()+'/services/apexrest/referencia/upsert/';
        request.httpMethod = 'PUT';
        request.requestBody= Blob.valueOf(reqBody);

        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;
        REST_Referencia_FSC.doPut();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testPutReturns202() {

        Account acc = buildNeutralAccount('Cliente Test', 'CIF12345');
        insert acc;

        Contact con = new Contact(
            LastName = 'Contacto Cliente',
            AccountId = acc.Id
        );
        insert con;
        // Prepare the JSON body with one valid CIF and one invalid field value
        // to trigger partial success/error logic that leads to status 202
        String jsonBody = '[{' +
            '"ACC_CIF_c": "CIF12345",' + // Coincide con setup para evitar 404
            '"REF_Nombre_c": "Referencia Nueva",' +
            '"REF_Tipo_c": "Personal",' +
            '"REF_Id_Externo_c": null,' + // Esto suele causar error si es external ID requerido
            '"Banco_c": "Banco Test"' +
        '}]';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/referencia/upsert/';
        req.httpMethod = 'PUT';
        req.requestBody = Blob.valueOf(jsonBody);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        REST_Referencia_FSC.doPut();
        Test.stopTest();

        // Verificamos que sea 202
        System.assertEquals(202, res.statusCode, 'Se esperaba un status 202 por errores de procesamiento parcial.');
    }

    private static Account buildNeutralAccount(String name, String cif) {
        Account acc = new Account();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
        acc.Name = name;
        acc.ACC_RNC__c = 'RNC-' + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        acc.ACC_CIF__c = cif;
        acc.ACC_Condicion__c = 'PROSPECTO';
        acc.ACC_Estado__c = 'INICIADO';
        acc.ACC_TipoIdentificacion__c = 'RNC';
        return acc;
    }
}
