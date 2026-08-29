@isTest
public with sharing class REST_DatosFinancierosTest {

    @TestSetup
    static void makeData(){
        TestDataFactory.createDatosMaestro();
        TestDataFactory.createJuridicAccounts(3);
    }

    @isTest
    public static void testPut404(){
        List<REST_DatosFinancieros_FSC.DatosFinanDTO> DatosFinanList = new List<REST_DatosFinancieros_FSC.DatosFinanDTO>();

        REST_DatosFinancieros_FSC.DatosFinanDTO datoFinan = new REST_DatosFinancieros_FSC.DatosFinanDTO();
        datoFinan.ACC_CIF_c = 'TESTCIF0';
        datoFinan.INF_Cuenta_c = '0013J00000T4QIFQA3';
        datoFinan.INF_Id_Externo_Inf_c = '0013J00000T4QIFQA3';
        datoFinan.INF_Fuente_De_Ingresos_c = 'Ingresos Familiares';
        datoFinan.INF_Ingresos_c = 'RD$ 15,001 A RD$ 35,000';
        datoFinan.INF_Periodo_c = 'Semestral';
        DatosFinanList.add(datoFinan);

        String reqBody = JSON.serialize(DatosFinanList);

        RestRequest request = new RestRequest();
        request.requestURI = Url.getOrgDomainUrl()+'/services/apexrest/datos-financieros/upsert/';
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf(reqBody);

        RestResponse resp = new RestResponse();
        RestContext.request = request;
        RestContext.response = resp;
        REST_DatosFinancieros_FSC.doPut();
        System.assertEquals(404, RestContext.response.StatusCode);
    }

    @isTest
    public static void testPut200(){
        List<REST_DatosFinancieros_FSC.DatosFinanDTO> DatosFinanList = new List<REST_DatosFinancieros_FSC.DatosFinanDTO>();
        REST_DatosFinancieros_FSC.DatosFinanDTO datoFinan1 = new REST_DatosFinancieros_FSC.DatosFinanDTO();
        datoFinan1.ACC_CIF_c = 'TESTCIF1';
        datoFinan1.INF_Cuenta_c = '1013J00000T4QIFQA3';
        datoFinan1.INF_Id_Externo_Inf_c = '1013J00000T4QIFQA3';
        datoFinan1.INF_Fuente_De_Ingresos_c = 'Ingresos Familiares';
        datoFinan1.INF_Ingresos_c = 'RD$ 15,001 A RD$ 35,000';
        datoFinan1.INF_Periodo_c = 'Semestral';
        DatosFinanList.add(datoFinan1);

        String reqBody = JSON.serialize(DatosFinanList);

        RestRequest request = new RestRequest();
        request.requestURI = Url.getOrgDomainUrl()+'/services/apexrest/datos-financieros/upsert/';
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf(reqBody);

        RestResponse resp = new RestResponse();
        RestContext.request = request;
        RestContext.response = resp;
        REST_DatosFinancieros_FSC.doPut();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    public static void testPut202(){
        List<REST_DatosFinancieros_FSC.DatosFinanDTO> DatosFinanList = new List<REST_DatosFinancieros_FSC.DatosFinanDTO>();
        REST_DatosFinancieros_FSC.DatosFinanDTO datoFinan1 = new REST_DatosFinancieros_FSC.DatosFinanDTO();
        datoFinan1.ACC_CIF_c = 'TESTCIF0';
        datoFinan1.INF_Cuenta_c = '1013J00000T4QIFQA3';
        datoFinan1.INF_Id_Externo_Inf_c = '1013J00000T4QIFQA3';
        datoFinan1.INF_Fuente_De_Ingresos_c = 'Ingresos Familiares';
        datoFinan1.INF_Ingresos_c = 'RD$ 15,001 A RD$ 35,000';
        datoFinan1.INF_Periodo_c = 'Semestral';
        DatosFinanList.add(datoFinan1);

        REST_DatosFinancieros_FSC.DatosFinanDTO datoFinan2 = new REST_DatosFinancieros_FSC.DatosFinanDTO();
        datoFinan2.ACC_CIF_c = 'TESTCIF2';
        datoFinan2.INF_Cuenta_c = '1013J00000T4QIFQA3';
        datoFinan2.INF_Id_Externo_Inf_c = '1013J00000T4QIFQA3';
        datoFinan2.INF_Fuente_De_Ingresos_c = 'Herencia';
        datoFinan2.INF_Ingresos_c = 'RD$ 15,001 A RD$ 35,000';
        datoFinan2.INF_Periodo_c = 'Semestral';
        DatosFinanList.add(datoFinan2);

        String reqBody = JSON.serialize(DatosFinanList);

        RestRequest request = new RestRequest();
        request.requestURI = Url.getOrgDomainUrl()+'/services/apexrest/datos-financieros/upsert/';
        request.httpMethod = 'PUT';
        request.requestBody = Blob.valueOf(reqBody);

        RestResponse resp = new RestResponse();
        RestContext.request = request;
        RestContext.response = resp;
        REST_DatosFinancieros_FSC.doPut();
        System.assertEquals(202, RestContext.response.StatusCode);
    }
}