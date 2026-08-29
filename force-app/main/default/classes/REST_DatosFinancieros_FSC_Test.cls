/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 28-12-2025
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@isTest
private with sharing class REST_DatosFinancieros_FSC_Test {

    @TestSetup
    static void makeData(){
        TestDataFactory_FSC.createDatosMaestro();
        TestDataFactory_FSC.createJuridicAccounts(3);
    }

    @isTest
    private static void testPut404(){

        String accPrefix = new Account().getSObjectType().getDescribe().getKeyPrefix();
        List<REST_DatosFinancieros_FSC.DatosFinanDTO> datosFinanList = new List<REST_DatosFinancieros_FSC.DatosFinanDTO>();

        REST_DatosFinancieros_FSC.DatosFinanDTO datoFinan = new REST_DatosFinancieros_FSC.DatosFinanDTO();
        datoFinan.ACC_CIF_c                 = 'TESTCIF0';
        datoFinan.INF_Cuenta_c              = String.format('{0}3J00000T4QIFQA3', new List<String> { accPrefix });
        datoFinan.INF_Id_Externo_Inf_c      = String.format('{0}3J00000T4QIFQA3', new List<String> { accPrefix });
        datoFinan.INF_Fuente_De_Ingresos_c  = 'Ingresos Familiares';
        datoFinan.INF_Ingresos_c            = 'RD$ 15,001 A RD$ 35,000';
        datoFinan.INF_Periodo_c             = 'Semestral';
        datosFinanList.add(datoFinan);

        String reqBody = JSON.serialize(datosFinanList);

        RestRequest request = new RestRequest();
        request.requestURI  = Url.getOrgDomainUrl()+'/services/apexrest/datos-financieros/upsert/';
        request.httpMethod  = 'PUT';
        request.requestBody = Blob.valueOf(reqBody);

        RestResponse resp       = new RestResponse();
        RestContext.request     = request;
        RestContext.response    = resp;
        REST_DatosFinancieros_FSC.doPut();
        System.assertEquals(404, RestContext.response.StatusCode, '[!] Status Code is not 404');
    }

    @isTest
    private static void testPut200(){

        String accPrefix = new Account().getSObjectType().getDescribe().getKeyPrefix();
        List<REST_DatosFinancieros_FSC.DatosFinanDTO> datosFinanList = new List<REST_DatosFinancieros_FSC.DatosFinanDTO>();

        REST_DatosFinancieros_FSC.DatosFinanDTO datoFinan1 = new REST_DatosFinancieros_FSC.DatosFinanDTO();
        datoFinan1.ACC_CIF_c                = 'TESTCIF1';
        datoFinan1.INF_Cuenta_c             = String.format('{0}3J00000T4QIFQA3', new List<String> { accPrefix });
        datoFinan1.INF_Id_Externo_Inf_c     = String.format('{0}3J00000T4QIFQA3', new List<String> { accPrefix });
        datoFinan1.INF_Fuente_De_Ingresos_c = 'Ingresos Familiares';
        datoFinan1.INF_Ingresos_c           = 'RD$ 15,001 A RD$ 35,000';
        datoFinan1.INF_Periodo_c            = 'Semestral';
        datosFinanList.add(datoFinan1);

        String reqBody = JSON.serialize(datosFinanList);

        RestRequest request = new RestRequest();
        request.requestURI  = Url.getOrgDomainUrl()+'/services/apexrest/datos-financieros/upsert/';
        request.httpMethod  = 'PUT';
        request.requestBody = Blob.valueOf(reqBody);

        RestResponse resp       = new RestResponse();
        RestContext.request     = request;
        RestContext.response    = resp;
        REST_DatosFinancieros_FSC.doPut();
        System.assertEquals(200, RestContext.response.statusCode, '[!] Status Code is not 200');
    }

    @isTest
    private static void testPut202(){

        String accPrefix = new Account().getSObjectType().getDescribe().getKeyPrefix();

        List<REST_DatosFinancieros_FSC.DatosFinanDTO> datosFinanList = new List<REST_DatosFinancieros_FSC.DatosFinanDTO>();
        REST_DatosFinancieros_FSC.DatosFinanDTO datoFinan1 = new REST_DatosFinancieros_FSC.DatosFinanDTO();
        datoFinan1.ACC_CIF_c                = 'TESTCIF0';
        datoFinan1.INF_Cuenta_c             = String.format('{0}3J00000T4QIFQA3', new List<String> { accPrefix });
        datoFinan1.INF_Id_Externo_Inf_c     = String.format('{0}3J00000T4QIFQA3', new List<String> { accPrefix });
        datoFinan1.INF_Fuente_De_Ingresos_c = 'Ingresos Familiares';
        datoFinan1.INF_Ingresos_c           = 'RD$ 15,001 A RD$ 35,000';
        datoFinan1.INF_Periodo_c            = 'Semestral';
        datosFinanList.add(datoFinan1);

        REST_DatosFinancieros_FSC.DatosFinanDTO datoFinan2 = new REST_DatosFinancieros_FSC.DatosFinanDTO();
        datoFinan2.ACC_CIF_c                = 'TESTCIF2';
        datoFinan2.INF_Cuenta_c             = String.format('{0}3J00000T4QIFQA3', new List<String> { accPrefix });
        datoFinan2.INF_Id_Externo_Inf_c     = String.format('{0}3J00000T4QIFQA3', new List<String> { accPrefix });
        datoFinan2.INF_Ingresos_c           = 'RD$ 15,001 A RD$ 35,000';
        datoFinan2.INF_Periodo_c            = 'Semestral';
        datosFinanList.add(datoFinan2);

        String reqBody = JSON.serialize(datosFinanList);

        RestRequest request = new RestRequest();
        request.requestURI  = Url.getOrgDomainUrl()+'/services/apexrest/datos-financieros/upsert/';
        request.httpMethod  = 'PUT';
        request.requestBody = Blob.valueOf(reqBody);

        RestResponse resp       = new RestResponse();
        RestContext.request     = request;
        RestContext.response    = resp;
        REST_DatosFinancieros_FSC.doPut();
        System.assertEquals(202, RestContext.response.StatusCode, '[!] Status Code is not 202');
    }
}