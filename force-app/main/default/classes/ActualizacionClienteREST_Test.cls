/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 02-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@isTest
public with sharing class ActualizacionClienteREST_Test {

    /*@TestSetup
    static void makeData(){
        TestDataFactory.createTestData();
    }

    @isTest 
    public static void testPut(){
        List<ActualizacionClienteREST.ClienteDTO> listClientes = new List<ActualizacionClienteREST.ClienteDTO>();
        ActualizacionClienteREST.ClienteDTO cliente = new ActualizacionClienteREST.ClienteDTO();
        cliente.CIF = 'TESTCIF1';
        cliente.estado= 'PENDIENTE';
        cliente.segmento= 'testing';
        cliente.ejecutivo= 'TEST EJECUTIVO';
        cliente.CIIU= 'TESTING';

        listClientes.add(cliente);
        String reqBody = JSON.serialize(listClientes);

        RestRequest request = new RestRequest();
        request.requestURI= URL.getOrgDomainUrl()+'/services/apexrest/Account/actualizacionCliente';
        request.httpMethod = 'PUT';
        request.requestBody= Blob.valueOf(reqBody);

        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;

        system.debug(reqBody);
        ActualizacionClienteREST.doPut();

    }*/
}