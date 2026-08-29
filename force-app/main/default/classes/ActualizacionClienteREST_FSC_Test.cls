/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 28-12-2025
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
public with sharing class ActualizacionClienteREST_FSC_Test {
    @TestSetup
    static void makeData(){
        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
        TestDataFactory_FSC.createTestData();
    }

    @isTest
    public static void testPut(){
        Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
        List<ActualizacionClienteREST_FSC.ClienteDTO> listClientes = new List<ActualizacionClienteREST_FSC.ClienteDTO>();
        ActualizacionClienteREST_FSC.ClienteDTO cliente = new ActualizacionClienteREST_FSC.ClienteDTO();
        cliente.CIF         = 'TESTCIF1';
        cliente.estado      = 'PENDIENTE';
        cliente.segmento    = 'testing';
        cliente.ejecutivo   = 'TEST EJECUTIVO';
        cliente.CIIU        = 'TESTING';

        listClientes.add(cliente);
        String reqBody = JSON.serialize(listClientes);

        RestRequest request = new RestRequest();
        request.requestURI  = URL.getOrgDomainUrl()+'/services/apexrest/Account/actualizacionCliente';
        request.httpMethod  = 'PUT';
        request.requestBody = Blob.valueOf(reqBody);

        RestResponse res        = new RestResponse();
        RestContext.request     = request;
        RestContext.response    = res;

        system.debug(reqBody);
        ActualizacionClienteREST_FSC.doPut();

    }
}
