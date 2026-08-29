/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 28-12-2025
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
private with sharing class REST_PersonaJuridica_FSC_Test {

    @TestSetup
    static void makeData(){
        TestDataFactory_FSC.createDatosMaestro();
        TestDataFactory_FSC.createJuridicAccounts(1);
    }

    @isTest
    private static void testPut(){

        REST_PersonaJuridica_FSC.PersonaJuridicaDTO pjDTO = new REST_PersonaJuridica_FSC.PersonaJuridicaDTO();
        pjDTO.ACC_Id_Externo_Cuenta_c                       = '1-12TEST';
        pjDTO.Actividad_Economica_External_ID               = '1-ECO-TEST';
        pjDTO.EJECUTIVO_SIEBEL                              = 'kbermudez@bv.com.do';
        pjDTO.codigoOWNER                                   = 'KBERM001';
        pjDTO.codigoUsuarioCaptador                         = 'KBERM001';
        pjDTO.Id_Externo_Cuenta_Parent                      = '1-11TEST1';
        pjDTO.ACC_Nombre_Corto_Comercial_c                  = 'TIVALSA S A';
        pjDTO.NAME                                          = 'Name Test';
        pjDTO.ACC_RNC_C                                     = '131047666';
        pjDTO.ACC_CONDICION_C                               = 'CLIENTE';
        pjDTO.ACC_ESTADO_C                                  = 'CANCELADO';
        pjDTO.ACC_SUBESTADO_C                               = 'DESVINCULADO POR CLIENTE';
        pjDTO.ACC_CIF_C                                     = '1071666';
        pjDTO.ACC_TIPO_ORGANIZACION_C                       = 'CONSORCIOS';
        pjDTO.ACC_FECHA_FUNDACION_C                         = '2013-07-19';
        pjDTO.ACC_FECHA_CIERRE_FISCAL_C                     = '2018-12-31';
        pjDTO.ACC_NACIONALIDAD_C                            = 'REPUBLICA DOMINICANA';
        pjDTO.ACC_CLASIFICACION_EMPRESA_C                   = 'Corporativa';
        pjDTO.ACC_TIPO_CLIENTE_PJ_C                         = '143';
        pjDTO.ACC_Categoria_Riesgo_Cliente_c                = 'A';
        pjDTO.ACC_SEGMENTO_C                                = '13';
        pjDTO.ACC_ULTIMA_SEGMENTACION_C                     = '2013-07-19';
        pjDTO.ACC_CLIENTE_CONOCIDO_C                        = true;
        pjDTO.ACC_CODIGO_DEPOSITANTE_C                      = 'V12345';
        pjDTO.ACC_RESULTADO_VALIDACION_C                    = 'APROBADO';
        pjDTO.ACC_RELACION_EXTERIOR_C                       = 'Importador';
        pjDTO.ACC_TIPO_DEPOSITANTE_C                        = 'Mayoristas';
        pjDTO.ACC_TIPO_PERSONA_PJ_C                         = 'E1F';
        pjDTO.ACC_INTERNET_BANKING_C                        = true;
        pjDTO.ACC_APLICA_FATCA_C                            = true;
        pjDTO.ACC_CUENTA_NOMINA_C                           = true;
        pjDTO.ACC_Objeto_Negocio_c                          = 'REALIZAR DE FORMA HABITUAL , ACTIVIDADES DE INTERMEDIACION DE VALORES OBJETO DE FORMA PUBLICA EN LOS MERCADOS BURSATIL.'; // cambiar
        pjDTO.ACC_TIPO_VINCULACION_C                        = 'DEUDOR O EMISOR NO VINCULADO';
        pjDTO.ACC_TIPO_SECTOR_C                             = 'PRIVADO';
        pjDTO.ACC_TIPO_ACTIVIDAD_C                          = 'SERVICIOS COMUNALES, SOCIALES Y PERSONAL';
        pjDTO.ACC_Fecha_Conversion_Cliente_c                = '2019-12-23';
        pjDTO.ACC_Fecha_Reconversion_Cliente_c              = '2019-12-23';
        pjDTO.ACC_PUNTOS_ACUMULADOS_C                       = 100;
        pjDTO.ACC_PUNTOS_CANJEADOS_C                        = 25;
        pjDTO.ACC_PUNTOS_GENERADOS_C                        = 125;
        pjDTO.ACC_PUNTOS_POR_VENCER_C                       = 75;
        pjDTO.ACC_PUNTOS_VENCIDOS_C                         = 125;
        pjDTO.ACC_Coincidencia_Listas_Externas_c            = true;
        pjDTO.ACC_Ultima_Actualizacion_Listas_Externas_c    = '2019-12-23';
        pjDTO.ACC_Coincidencia_Listas_Internas_c            = true;
        pjDTO.ACC_Ultima_Actualizacion_Listas_Internas_c    = '2019-12-23';
        pjDTO.ACC_LISTAS_C                                  = 'Lista1 Lista 2 Lista 3';
        pjDTO.ACC_FECHA_INFORMACION_C                       = '2018-07-31';
        pjDTO.ACC_TOTAL_ACTIVOS_C                           = 2290943954.36;
        pjDTO.ACC_MONEDA_C                                  = 'DOP';
        pjDTO.ACC_Volumen_Ventas_Anual_c                    = 27907595.81;
        pjDTO.ACC_PATRIMONIO_DESC_C                         = 'Test VISEO Patrimonio';
        pjDTO.ACC_NUMEMPLEADOS_C                            = 35;
        pjDTO.ACC_FUENTE_INFORMACION_C                      = 'E';
        pjDTO.ACC_PATRIMONIO_NUM_C                          = 346372934.05;
        pjDTO.ACC_TIPO_INGRESO_C                            = 'PASIVA';
        pjDTO.ACC_Segmento_FATCA_c                          = 'CONSORCIO';
        pjDTO.ACC_POSEE_ACUERDO_IRS_C                       = true;
        pjDTO.ACC_TIPO_ACUERDO_C                            = 'Qualified intermediary - Intermediario Calificado';
        pjDTO.ACC_NUM_ACUERDO_C                             = '7898234567';
        pjDTO.ACC_GIIN_C                                    = '131047165';
        pjDTO.ACC_DIRECCION_FATCA_C                         = 'DGII';
        pjDTO.ACC_ESTADO_FATCA_C                            = 'DISTRITO  NACIONAL';
        pjDTO.ACC_CIUDAD_FATCA_C                            = 'PIANTINI';
        pjDTO.ACC_CODIGO_POSTAL_FATCA_C                     = '10127';
        pjDTO.ACC_TELEFONO_FATCA_C                          = '8094750888';
        pjDTO.ACC_Correo_Electronico_Cliente_c              = 'testcorreocliente@test.do';
        pjDTO.PHONE                                         = '8090987678';
        pjDTO.BillingStreet                                 = 'Avenida Abraham Lincoln';
        pjDTO.BillingCity                                   = 'Santo Domingo';
        pjDTO.BillingPostalCode                             = 'Santo Domingo BS';
        pjDTO.BillingState                                  = 'Santo Domingo ZPC';
        pjDTO.BillingCountry                                = 'Dominican Republic';
        pjDTO.ACC_TipoIdentificacion_c                      = 'RNC';

        String reqBody = JSON.serialize(pjDTO);

        RestRequest request = new RestRequest();
        request.requestURI  = URL.getOrgDomainUrl()+'/services/apexrest/cliente/upsert-persona-juridica/';
        request.httpMethod  = 'PUT';
        request.requestBody = Blob.valueOf(reqBody);

        RestResponse res        = new RestResponse();
        RestContext.request     = request;
        RestContext.response    = res;

        REST_PersonaJuridica_FSC.doPut();
        System.assertEquals(200, RestContext.response.statusCode);
    }
}