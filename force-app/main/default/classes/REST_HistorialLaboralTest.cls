@isTest
public with sharing class REST_HistorialLaboralTest {
    @TestSetup
    static void makeData(){
        TestDataFactory.createDatosMaestro();
        TestDataFactory.createJuridicAccounts(2);
    }

    @isTest
    public static void testPut404(){
        List<REST_HistorialLaboralPF_FSC.HistorialLaboralDTO> HistorialLaboralList = new List<REST_HistorialLaboralPF_FSC.HistorialLaboralDTO>();

        REST_HistorialLaboralPF_FSC.HistorialLaboralDTO Historial0 = new REST_HistorialLaboralPF_FSC.HistorialLaboralDTO();
        Historial0.ACC_CIF_c = 'TESTCIF0';
        Historial0.HIS_Id_Externo_Historial_c = '0013J00000T4QIFQA3';
        Historial0.HIS_Cuenta_c = '0013J00000T4QIFQA3';
        Historial0.HIS_Principal_c = true;
        Historial0.HIS_Empleo_c = 'Actual';
        Historial0.HIS_Empresa_c = 'CONSEJO DEL PODER JUDICIAL';
        Historial0.HIS_Fecha_de_ingreso_c = '4/1/2016';
        Historial0.HIS_Fecha_de_fin_c = '4/2/2016';
        Historial0.HIS_Ocupacion_c = 'OFICINISTA';
        Historial0.HIS_Puesto_de_trabajo_c = 'OFICINISTA DE LA UNIDAD DE SERVICIO PENAL';
        HistorialLaboralList.add(Historial0);

        String reqBody = JSON.serialize(HistorialLaboralList);
        
        RestRequest request = new RestRequest();
        request.requestURI= URL.getOrgDomainUrl()+'/services/apexrest/historial-laboral/upsert/';
        request.httpMethod = 'PUT';
        request.requestBody= Blob.valueOf(reqBody);
        
        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;
        REST_HistorialLaboralPF_FSC.doPut();
        System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    public static void testPut200(){
        List<REST_HistorialLaboralPF_FSC.HistorialLaboralDTO> HistorialLaboralList = new List<REST_HistorialLaboralPF_FSC.HistorialLaboralDTO>();

        REST_HistorialLaboralPF_FSC.HistorialLaboralDTO Historial0 = new REST_HistorialLaboralPF_FSC.HistorialLaboralDTO();
        Historial0.ACC_CIF_c = 'TESTCIF1';
        Historial0.HIS_Id_Externo_Historial_c = '0013J00000T4QIFQA3';
        Historial0.HIS_Cuenta_c = '0013J00000T4QIFQA3';
        Historial0.HIS_Principal_c = true;
        Historial0.HIS_Empleo_c = 'Actual';
        Historial0.HIS_Empresa_c = 'CONSEJO DEL PODER JUDICIAL';
        Historial0.HIS_Fecha_de_ingreso_c = '4/1/2016';
        Historial0.HIS_Fecha_de_fin_c = '4/2/2016';
        Historial0.HIS_Ocupacion_c = 'OFICINISTA';
        Historial0.HIS_Puesto_de_trabajo_c = 'OFICINISTA DE LA UNIDAD DE SERVICIO PENAL';
        HistorialLaboralList.add(Historial0);

        String reqBody = JSON.serialize(HistorialLaboralList);
        
        RestRequest request = new RestRequest();
        request.requestURI= URL.getOrgDomainUrl()+'/services/apexrest/historial-laboral/upsert/';
        request.httpMethod = 'PUT';
        request.requestBody= Blob.valueOf(reqBody);
        
        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;
        REST_HistorialLaboralPF_FSC.doPut();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    public static void testPut202(){
        List<REST_HistorialLaboralPF_FSC.HistorialLaboralDTO> HistorialLaboralList = new List<REST_HistorialLaboralPF_FSC.HistorialLaboralDTO>();

        REST_HistorialLaboralPF_FSC.HistorialLaboralDTO Historial0 = new REST_HistorialLaboralPF_FSC.HistorialLaboralDTO();
        Historial0.ACC_CIF_c = 'TESTCIF0';
        Historial0.HIS_Id_Externo_Historial_c = '0013J00000T4QIFQA3';
        Historial0.HIS_Cuenta_c = '0013J00000T4QIFQA3';
        Historial0.HIS_Principal_c = true;
        Historial0.HIS_Empleo_c = 'Actual';
        Historial0.HIS_Empresa_c = 'CONSEJO DEL PODER JUDICIAL';
        Historial0.HIS_Fecha_de_ingreso_c = '4/1/2016';
        Historial0.HIS_Fecha_de_fin_c = '4/2/2016';
        Historial0.HIS_Ocupacion_c = 'OFICINISTA';
        Historial0.HIS_Puesto_de_trabajo_c = 'OFICINISTA DE LA UNIDAD DE SERVICIO PENAL';
        HistorialLaboralList.add(Historial0);

        REST_HistorialLaboralPF_FSC.HistorialLaboralDTO Historial1 = new REST_HistorialLaboralPF_FSC.HistorialLaboralDTO();
        Historial1.ACC_CIF_c = 'TESTCIF1';
        Historial1.HIS_Id_Externo_Historial_c = '0013J00000T4QIFQA3';
        Historial1.HIS_Cuenta_c = '0013J00000T4QIFQA3';
        Historial1.HIS_Principal_c = true;
        Historial1.HIS_Empleo_c = 'Actual';
        Historial1.HIS_Empresa_c = 'CONSEJO DEL PODER JUDICIAL';
        Historial1.HIS_Fecha_de_ingreso_c = '4/1/2016';
        Historial1.HIS_Fecha_de_fin_c = '4/3/2016';
        Historial1.HIS_Ocupacion_c = 'OFICINISTA';
        Historial1.HIS_Puesto_de_trabajo_c = 'OFICINISTA DE LA UNIDAD DE SERVICIO PENAL';
        HistorialLaboralList.add(Historial1);

        String reqBody = JSON.serialize(HistorialLaboralList);
        
        RestRequest request = new RestRequest();
        request.requestURI= URL.getOrgDomainUrl()+'/services/apexrest/historial-laboral/upsert/';
        request.httpMethod = 'PUT';
        request.requestBody= Blob.valueOf(reqBody);
        
        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;
        REST_HistorialLaboralPF_FSC.doPut();
        System.assertEquals(202, RestContext.response.statusCode);
    }
}