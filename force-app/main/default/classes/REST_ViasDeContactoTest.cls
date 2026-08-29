@isTest
public with sharing class REST_ViasDeContactoTest {

    @TestSetup
    static void makeData(){
        TestDataFactory.createDatosMaestro();
        TestDataFactory.createJuridicAccounts(1);
    }

    @isTest 
    public static void testPut404(){
        List<REST_ViasDeContacto_FSC.ViaDTO> viaDTOList = new List<REST_ViasDeContacto_FSC.ViaDTO>();

        REST_ViasDeContacto_FSC.ViaDTO viaDTO0 = new REST_ViasDeContacto_FSC.ViaDTO();
        viaDTO0.ACC_CIF_c = 'TESTCIF0';
        viaDTO0.VIA_de_Contacto_c = 'CORREO ELECTRÓNICO';
        viaDTO0.VIA_Envio_SMS_c = false;
        viaDTO0.VIA_Id_Externo_Via_c = '1-1PP-541'; 
        viaDTO0.VIA_Identificador_c = '124233';
        viaDTO0.VIA_Numero_Correo_c = 'test.viseo@viseo.com';
        viaDTO0.VIA_Principal_c = true;
        viaDTO0.VIA_Telefonica_c = '';
        viaDTOList.add(viaDTO0);
        
        String reqBody = JSON.serialize(viaDTOList);
        
        RestRequest request = new RestRequest();
        request.requestURI= URL.getOrgDomainUrl()+'/services/apexrest/vias-de-contacto/upsert/';
        request.httpMethod = 'PUT';
        request.requestBody= Blob.valueOf(reqBody);
        
        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;
        REST_ViasDeContacto_FSC.doPut();
        System.assertEquals(404, RestContext.response.statusCode);
    }


    @isTest 
    public static void testPut200(){
        List<REST_ViasDeContacto_FSC.ViaDTO> viaDTOList = new List<REST_ViasDeContacto_FSC.ViaDTO>();
        
        REST_ViasDeContacto_FSC.ViaDTO viaDTO1 = new REST_ViasDeContacto_FSC.ViaDTO();
        viaDTO1.ACC_CIF_c = 'TESTCIF1';
        viaDTO1.VIA_de_Contacto_c = 'CORREO ELECTRÓNICO';
        viaDTO1.VIA_Envio_SMS_c = false;
        viaDTO1.VIA_Id_Externo_Via_c = '1-1PP-541'; 
        viaDTO1.VIA_Identificador_c = '124233';
        viaDTO1.VIA_Numero_Correo_c = 'test.viseo@viseo.com';
        viaDTO1.VIA_Principal_c = true;
        viaDTO1.VIA_Telefonica_c = '';
        viaDTOList.add(viaDTO1);
        
        String reqBody = JSON.serialize(viaDTOList);

        RestRequest request = new RestRequest();
        request.requestURI= URL.getOrgDomainUrl()+'/services/apexrest/vias-de-contacto/upsert/';
        request.httpMethod = 'PUT';
        request.requestBody= Blob.valueOf(reqBody);

        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;
        REST_ViasDeContacto_FSC.doPut();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest 
    public static void testPut202(){
        List<REST_ViasDeContacto_FSC.ViaDTO> viaDTOList = new List<REST_ViasDeContacto_FSC.ViaDTO>();

        REST_ViasDeContacto_FSC.ViaDTO viaDTO0 = new REST_ViasDeContacto_FSC.ViaDTO();
        viaDTO0.ACC_CIF_c = 'TESTCIF0';
        viaDTO0.VIA_de_Contacto_c = 'CORREO ELECTRÓNICO';
        viaDTO0.VIA_Envio_SMS_c = false;
        viaDTO0.VIA_Id_Externo_Via_c = '1-1PP-541'; 
        viaDTO0.VIA_Identificador_c = '124233';
        viaDTO0.VIA_Numero_Correo_c = 'test.viseo@viseo.com';
        viaDTO0.VIA_Principal_c = true;
        viaDTO0.VIA_Telefonica_c = '';
        viaDTOList.add(viaDTO0);
        
        REST_ViasDeContacto_FSC.ViaDTO viaDTO1 = new REST_ViasDeContacto_FSC.ViaDTO();
        viaDTO1.ACC_CIF_c = 'TESTCIF1';
        viaDTO1.VIA_de_Contacto_c = 'CORREO ELECTRÓNICO';
        viaDTO1.VIA_Envio_SMS_c = false;
        viaDTO1.VIA_Id_Externo_Via_c = '1-1PP-541'; 
        viaDTO1.VIA_Identificador_c = '124233';
        viaDTO1.VIA_Numero_Correo_c = 'test.viseo@viseo.com';
        viaDTO1.VIA_Principal_c = true;
        viaDTO1.VIA_Telefonica_c = '';
        viaDTOList.add(viaDTO1);
        
        String reqBody = JSON.serialize(viaDTOList);

        RestRequest request = new RestRequest();
        request.requestURI= URL.getOrgDomainUrl()+'/services/apexrest/vias-de-contacto/upsert/';
        request.httpMethod = 'PUT';
        request.requestBody= Blob.valueOf(reqBody);

        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;
        REST_ViasDeContacto_FSC.doPut();
        System.assertEquals(202, RestContext.response.statusCode);
    }
}