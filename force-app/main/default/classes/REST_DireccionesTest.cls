@isTest
public class REST_DireccionesTest {
    @TestSetup
    static void makeData(){
        
        Datos_Maestros__c dm2 = new Datos_Maestros__c(
        	Name = 'Sector Test',
            DM_Tipo__c = 'Sector',
            DM_Direccion__c = 'SECTOR_10320101202002',
            DM_Distrito__c = '320101'
        );
        
        insert dm2;
        
        TestDataFactory.createDatosMaestro();
        TestDataFactory.createJuridicAccounts(2);
    }

    @isTest
    public static void testPut404(){
        List<REST_Direcciones_FSC.DireccionesDTO> DireccionesList = new List<REST_Direcciones_FSC.DireccionesDTO>();

        REST_Direcciones_FSC.DireccionesDTO Direccion1 = new REST_Direcciones_FSC.DireccionesDTO();
        Direccion1.ACC_CIF_c = 'TESTCIF0';
        Direccion1.DIR_Account_c = '0013J00000T4QIFQA3';
        Direccion1.DIR_Apartado_Postal_c = '10802';
        Direccion1.DIR_Calle_c = 'C/ CAMINO 2';
        Direccion1.DIR_Direccion_siebel_c = 'REPUBLICA DOMINICANA SANTO DOMINGO ESTE LOS FRAILES';
        Direccion1.DIR_Edificio_c = 'calle edificio 1';
        Direccion1.DIR_Estado_Ciudad_c = 'LOS FRAILES';
        Direccion1.DIR_Extension_c = '802';
        Direccion1.DIR_Id_Externo_c = '1-6ATGB';
        Direccion1.DIR_Identificador_c =  '1-6ATGB';
        Direccion1.DIR_Numero_c = '69';
        Direccion1.DIR_N_Apartamento_c = '1';
        Direccion1.DIR_N_Telefono_c = '8090000001';
        Direccion1.DIR_Pais_c = 'DO';
        Direccion1.DIR_Provincia_c = '32';
        Direccion1.DIR_Municipio_c = '3201';
        Direccion1.DIR_Distrito_c = '320101';
        Direccion1.DIR_Sector_c = 'SECTOR_10320101202002';
        Direccion1.DIR_Referencia_ubicacion_c = 'Test referencia ubicación 1';
        Direccion1.DIR_Telef_Adicional_c = '8090000111';
        Direccion1.DIR_Telefono_adicional_c = '8090000011';
        Direccion1.DIR_Tipo_Direccion_c = 'RESIDENCIA';
        Direccion1.DIR_Principal_c = false;
        DireccionesList.add(Direccion1);

        String reqBody = JSON.serialize(DireccionesList);
        
        RestRequest request = new RestRequest();
        request.requestURI= URL.getOrgDomainUrl()+'/services/apexrest/direcciones/upsert/';
        request.httpMethod = 'PUT';
        request.requestBody= Blob.valueOf(reqBody);
        
        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;
        REST_Direcciones_FSC.doPut();
        System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest 
    public static void testPut200(){
        List<REST_Direcciones_FSC.DireccionesDTO> DireccionesList = new List<REST_Direcciones_FSC.DireccionesDTO>();

        REST_Direcciones_FSC.DireccionesDTO Direccion = new REST_Direcciones_FSC.DireccionesDTO();
        Direccion.ACC_CIF_c = 'TESTCIF1';
        Direccion.DIR_Account_c = '0013J00000T4QIFQA3';
        Direccion.DIR_Apartado_Postal_c = '10802';
        Direccion.DIR_Calle_c = 'C/ CAMINO 2';
        Direccion.DIR_Direccion_siebel_c = 'REPUBLICA DOMINICANA SANTO DOMINGO ESTE LOS FRAILES';
        Direccion.DIR_Pais_c = 'DO';
        Direccion.DIR_Provincia_c = '32';
        Direccion.DIR_Municipio_c = '3201';
        Direccion.DIR_Distrito_c = '320101';
        Direccion.DIR_Edificio_c = 'calle edificio 1';
        Direccion.DIR_Estado_Ciudad_c = 'LOS FRAILES';
        Direccion.DIR_Extension_c = '802';
        Direccion.DIR_Id_Externo_c = '1-6ATGB';
        Direccion.DIR_Identificador_c =  '1-6ATGB';
        Direccion.DIR_Numero_c = '69';
        Direccion.DIR_N_Apartamento_c = '1';
        Direccion.DIR_N_Telefono_c = '8090000001';
        Direccion.DIR_Referencia_ubicacion_c = 'Test referencia ubicación 1';
        Direccion.DIR_Sector_c = '1-B2-10120';
        Direccion.DIR_Telef_Adicional_c = '8090000111';
        Direccion.DIR_Telefono_adicional_c = '8090000011';
        Direccion.DIR_Tipo_Direccion_c = 'RESIDENCIA';
        Direccion.DIR_Principal_c = false;
        DireccionesList.add(Direccion);

        String reqBody = JSON.serialize(DireccionesList);
        
        RestRequest request = new RestRequest();
        request.requestURI= URL.getOrgDomainUrl()+'/services/apexrest/direcciones/upsert/';
        request.httpMethod = 'PUT';
        request.requestBody= Blob.valueOf(reqBody);
        
        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;
        REST_Direcciones_FSC.doPut();
        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest 
    public static void testPut202(){
        List<REST_Direcciones_FSC.DireccionesDTO> DireccionesList = new List<REST_Direcciones_FSC.DireccionesDTO>();

        REST_Direcciones_FSC.DireccionesDTO Direccion = new REST_Direcciones_FSC.DireccionesDTO();
        Direccion.ACC_CIF_c = 'TESTCIF0';
        //Direccion.DIR_Account_c = '0013J00000T4QIFQA3';
        Direccion.DIR_Apartado_Postal_c = '10802';
        Direccion.DIR_Calle_c = 'C/ CAMINO 2';
        Direccion.DIR_Direccion_siebel_c = 'REPUBLICA DOMINICANA SANTO DOMINGO ESTE LOS FRAILES';
        Direccion.DIR_Distrito_c = '320101';
        Direccion.DIR_Edificio_c = 'calle edificio 1';
        Direccion.DIR_Estado_Ciudad_c = 'LOS FRAILES';
        Direccion.DIR_Extension_c = '802';
        Direccion.DIR_Id_Externo_c = '1-6ATGB';
        Direccion.DIR_Identificador_c =  '1-6ATGB';
        Direccion.DIR_Numero_c = '69';
        Direccion.DIR_N_Apartamento_c = '1';
        Direccion.DIR_N_Telefono_c = '8090000001';
        Direccion.DIR_Pais_c = 'DO';
        Direccion.DIR_Provincia_c = '32';
        Direccion.DIR_Referencia_ubicacion_c = 'Test referencia ubicación 1';
        Direccion.DIR_Sector_c = 'SAN LUIS';//'a003J000000xOX2QAM';
        Direccion.DIR_Telef_Adicional_c = '8090000111';
        Direccion.DIR_Telefono_adicional_c = '8090000011';
        Direccion.DIR_Tipo_Direccion_c = 'RESIDENCIA';
        Direccion.DIR_Municipio_c = '3201';
        Direccion.DIR_Principal_c = true;
        DireccionesList.add(Direccion);

        REST_Direcciones_FSC.DireccionesDTO Direccion1 = new REST_Direcciones_FSC.DireccionesDTO();
        Direccion1.ACC_CIF_c = 'TESTCIF2';
        Direccion1.DIR_Account_c = '0013J00000T4QIFQA3';
        Direccion1.DIR_Apartado_Postal_c = '10802';
        Direccion1.DIR_Calle_c = 'C/ CAMINO 2';
        Direccion1.DIR_Direccion_siebel_c = 'REPUBLICA DOMINICANA SANTO DOMINGO ESTE LOS FRAILES';
        Direccion1.DIR_Distrito_c = '320101';
        Direccion1.DIR_Edificio_c = 'calle edificio 1';
        Direccion1.DIR_Estado_Ciudad_c = 'LOS FRAILES';
        Direccion1.DIR_Extension_c = '802';
        Direccion1.DIR_Id_Externo_c = '1-6ATGB';
        Direccion1.DIR_Identificador_c =  '1-6ATGB';
        Direccion1.DIR_Numero_c = '69';
        Direccion1.DIR_N_Apartamento_c = '1';
        Direccion1.DIR_N_Telefono_c = '8090000001';
        Direccion1.DIR_Pais_c = 'DO';
        Direccion1.DIR_Provincia_c = '32';
        Direccion1.DIR_Referencia_ubicacion_c = 'Test referencia ubicación 1';
        Direccion1.DIR_Sector_c = 'SAN LUIS';//'a003J000000xOX2QAM';
        Direccion1.DIR_Telef_Adicional_c = '8090000111';
        Direccion1.DIR_Telefono_adicional_c = '8090000011';
        Direccion1.DIR_Tipo_Direccion_c = 'RESIDENCIA';
        Direccion1.DIR_Municipio_c = '3201';
        Direccion1.DIR_Principal_c = false;
        DireccionesList.add(Direccion1);

        String reqBody = JSON.serialize(DireccionesList);

        RestRequest request = new RestRequest();
        request.requestURI= URL.getOrgDomainUrl()+'/services/apexrest/direcciones/upsert/';
        request.httpMethod = 'PUT';
        request.requestBody= Blob.valueOf(reqBody);

        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;
        REST_Direcciones_FSC.doPut();
        System.assertEquals(202, RestContext.response.statusCode);
    }
}