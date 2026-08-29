/**
 * @description       : test class for REST_ActualizarSubestadoOportunidad_FSC
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 02-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
private with sharing class RESTActualizarSubestadoOportunidadFSCTst {

    @testsetup
    static void makeData(){
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        List<Account> clientes = TestDataFactoryPrestamos.crearClientePF(1, true);
        List<Matriz_de_producto__c> facilidades = TestDataFactoryPrestamos.createMatrizDeProducto(1);
        Opportunity opp = TestDataFactoryPrestamos.crearOportunidadWithProduct(clientes[0]?.Id, facilidades[0]?.Id, false);
        opp.Opp_numSolictud__c = '8503';
        insert opp;
    }

    @isTest
    private static void testPost200(){

        REST_ActualizarSubestadoOportunidad_FSC.DataDTO dataDTO = new REST_ActualizarSubestadoOportunidad_FSC.DataDTO();
		dataDTO.numSolicitud    = '8503';
        dataDTO.subStage        = '4';

        String reqBody = JSON.serialize(dataDTO);

        RestRequest request = new RestRequest();
        request.requestURI  = URL.getOrgDomainUrl()+'/services/apexrest/opportunity/update-substage';
        request.httpMethod  = 'POST';
        request.requestBody = Blob.valueOf(reqBody);

        RestResponse res        = new RestResponse();
        RestContext.request     = request;
        RestContext.response    = res;
        REST_ActualizarSubestadoOportunidad_FSC.doPost();
        //System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    private static void testPost404(){

        REST_ActualizarSubestadoOportunidad_FSC.DataDTO dataDTO = new REST_ActualizarSubestadoOportunidad_FSC.DataDTO();
		dataDTO.numSolicitud    = '8503';
        dataDTO.subStage        = '4';

        String reqBody = JSON.serialize(dataDTO);

        RestRequest request = new RestRequest();
        request.requestURI  = URL.getOrgDomainUrl()+'/services/apexrest/opportunity/update-substage';
        request.httpMethod  = 'POST';
        request.requestBody = Blob.valueOf(reqBody);

        RestResponse res        = new RestResponse();
        RestContext.request     = request;
        RestContext.response    = res;
        REST_ActualizarSubestadoOportunidad_FSC.doPost();
        //System.assertEquals(404, RestContext.response.statusCode);
    }

}
