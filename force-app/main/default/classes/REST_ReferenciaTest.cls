@isTest
public with sharing class REST_ReferenciaTest {
    @TestSetup
    static void makeData(){
        TestDataFactory.createDatosMaestro();
        List<Account> accounts = TestDataFactory.createJuridicAccounts(2);
        TestDataFactory_FSC.createReciprocalRole(1);
        insert new List<Contact>{
            new Contact(LastName = 'Cliente TESTCIF1', AccountId = accounts[0].Id),
            new Contact(LastName = 'Cliente TESTCIF2', AccountId = accounts[1].Id),
            new Contact(LastName = 'BANCO POPULAR')
        };
    }
    @isTest
    public static void testPut404(){
        List<REST_Referencia_FSC.ReferenciaDTO> ReferenciaList = new List<REST_Referencia_FSC.ReferenciaDTO>();
        REST_Referencia_FSC.ReferenciaDTO referencia0 = new REST_Referencia_FSC.ReferenciaDTO();
        referencia0.ACC_CIF_c ='TESTCIF0';
        referencia0.Account_c = '0013J00000T4VeMQAV';
        referencia0.Banco_c = 'Banco Vimenca';
        referencia0.Moneda_c = 'DOP';
        referencia0.N_De_Cuenta_c = '7895673451';
        referencia0.Pais_c = 'DO';
        referencia0.REF_Direccion_c = 'AV. JOHN F. KENNEDY';
        referencia0.REF_Id_Externo_c = '1-3GIZV';
        referencia0.REF_Nombre_c = 'BANCO POPULAR';
        referencia0.REF_Telefono_c = '8095445556';
        referencia0.REF_Tipo_c = 'PERSONAL';
        referencia0.Tipo_de_Cuenta_c = 'Cuenta Corriente';
        ReferenciaList.add(referencia0);

        String reqBody = JSON.serialize(ReferenciaList);
        
        RestRequest request = new RestRequest();
        request.requestURI= URL.getOrgDomainUrl()+'/services/apexrest/referencia/upsert/';
        request.httpMethod = 'PUT';
        request.requestBody= Blob.valueOf(reqBody);
        
        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;
        REST_Referencia_FSC.doPut();
        System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    public static void testPut200(){
        List<REST_Referencia_FSC.ReferenciaDTO> ReferenciaList = new List<REST_Referencia_FSC.ReferenciaDTO>(); 
        REST_Referencia_FSC.ReferenciaDTO referencia1 = new REST_Referencia_FSC.ReferenciaDTO();
        referencia1.ACC_CIF_c ='TESTCIF1';
        referencia1.Account_c = '0013J00000T4VeMQAV';
        referencia1.Banco_c = 'Banco Vimenca';
        referencia1.Moneda_c = 'DOP';
        referencia1.N_De_Cuenta_c = '7895673451';
        referencia1.Pais_c = 'DO';
        referencia1.REF_Direccion_c = 'AV. JOHN F. KENNEDY';
        referencia1.REF_Id_Externo_c = '1-3GIZV';
        referencia1.REF_Nombre_c = 'BANCO POPULAR';
        referencia1.REF_Telefono_c = '8095445556';
        referencia1.REF_Tipo_c = 'COMERCIAL';
        referencia1.Tipo_de_Cuenta_c = 'Cuenta Corriente';
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
        System.assertEquals(200, RestContext.response.statusCode, RestContext.response.responseBody.toString());
    }

    @isTest
    public static void testPut202(){
        List<REST_Referencia_FSC.ReferenciaDTO> ReferenciaList = new List<REST_Referencia_FSC.ReferenciaDTO>();
        REST_Referencia_FSC.ReferenciaDTO referencia0 = new REST_Referencia_FSC.ReferenciaDTO();
        referencia0.ACC_CIF_c ='TESTCIF0';
        referencia0.Account_c = '0013J00000T4VeMQAV';
        referencia0.Banco_c = 'Banco Vimenca';
        referencia0.Moneda_c = 'DOP';
        referencia0.N_De_Cuenta_c = '7895673451';
        referencia0.Pais_c = 'DO';
        referencia0.REF_Direccion_c = 'AV. JOHN F. KENNEDY';
        referencia0.REF_Id_Externo_c = '1-3GIZV';
        referencia0.REF_Nombre_c = 'BANCO POPULAR';
        referencia0.REF_Telefono_c = '8095445556';
        referencia0.REF_Tipo_c = 'PERSONAL';
        referencia0.Tipo_de_Cuenta_c = 'Cuenta Corriente';
        ReferenciaList.add(referencia0);
        
        REST_Referencia_FSC.ReferenciaDTO referencia1 = new REST_Referencia_FSC.ReferenciaDTO();
        referencia1.ACC_CIF_c ='TESTCIF1';
        referencia1.Account_c = '0013J00000T4VeMQAV';
        referencia1.Banco_c = 'Banco Vimenca';
        referencia1.Moneda_c = 'DOP';
        referencia1.N_De_Cuenta_c = '7895673451';
        referencia1.Pais_c = 'DO';
        referencia1.REF_Direccion_c = 'AV. JOHN F. KENNEDY';
        referencia1.REF_Id_Externo_c = '1-3GIZV';
        referencia1.REF_Nombre_c = 'BANCO POPULAR';
        referencia1.REF_Telefono_c = '8095445556';
        referencia1.REF_Tipo_c = 'Bancaria';
        referencia1.Tipo_de_Cuenta_c = 'Cuenta Corriente';
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
        System.assertEquals(202, RestContext.response.statusCode);
    }
}
