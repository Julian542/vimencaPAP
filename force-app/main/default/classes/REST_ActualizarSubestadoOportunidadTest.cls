/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 02-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@isTest
public class REST_ActualizarSubestadoOportunidadTest {

    /*@testsetup
    static void makeData(){
        List<Account> clientes = TestDataFactoryPrestamos.crearClientePF(1, true);
        List<Matriz_de_producto__c> facilidades = TestDataFactoryPrestamos.createMatrizDeProducto(1);
        Opportunity opp = TestDataFactoryPrestamos.crearOportunidadWithProduct(clientes[0]?.Id, facilidades[0]?.Id, false);
        opp.Opp_numSolictud__c = '8503';
        insert opp;        
    }
    
    @isTest
    public static void testPost200(){
        
        REST_ActualizarSubestadoOportunidad.DataDTO dataDTO = new REST_ActualizarSubestadoOportunidad.DataDTO();
		dataDTO.numSolicitud = '8503';
        dataDTO.subStage = '4';

        String reqBody = JSON.serialize(dataDTO);
        
        RestRequest request = new RestRequest();
        request.requestURI= URL.getOrgDomainUrl()+'/services/apexrest/opportunity/update-substage';
        request.httpMethod = 'POST';
        request.requestBody= Blob.valueOf(reqBody);
        
        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;
        REST_ActualizarSubestadoOportunidad.doPost();
//      System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    public static void testPost404(){
        
        REST_ActualizarSubestadoOportunidad.DataDTO dataDTO = new REST_ActualizarSubestadoOportunidad.DataDTO();
		dataDTO.numSolicitud = '8503';
        dataDTO.subStage = '4';

        String reqBody = JSON.serialize(dataDTO);
        
        RestRequest request = new RestRequest();
        request.requestURI= URL.getOrgDomainUrl()+'/services/apexrest/opportunity/update-substage';
        request.httpMethod = 'POST';
        request.requestBody= Blob.valueOf(reqBody);
        
        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;
        REST_ActualizarSubestadoOportunidad.doPost();
//      System.assertEquals(404, RestContext.response.statusCode);
    }*/

}