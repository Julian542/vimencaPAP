/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 28-12-2025
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
private with sharing class REST_PersonaFisica_FSC_Test {

    @TestSetup
    static void makeData(){
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        TestDataFactory_FSC.createDatosMaestro();
        TestDataFactory_FSC.createPersonAccounts(1);
    }

    @isTest
    private static void testPut(){

        REST_PersonaFisica_FSC.PersonaFisicaDTO pfDTO       = new REST_PersonaFisica_FSC.PersonaFisicaDTO();
        pfDTO.ACC_Id_Externo_Cuenta_c                   = '1-12TEST';
        pfDTO.ACC_PERSONA_FISICA_C                      = true;
        pfDTO.LASTNAME                                  = 'ALVAREZ';
        pfDTO.SUFFIX                                    = 'MELLA';
        pfDTO.FIRSTNAME                                 = 'YESSENIA';
        pfDTO.MIDDLENAME                                = 'MARIA';
        pfDTO.ACC_GENERO_IDENTIFICACI_N_C               = 'Pasaporte Femenino';
        pfDTO.ACC_TIPOIDENTIFICACION_C                  = 'Cédula';
        pfDTO.ACC_NUMIDENTIFICACION_C                   = '115335218';
        pfDTO.ACC_NACIONALIDAD_C                        = 'REPUBLICA DOMINICANA';
        pfDTO.ACC_CONDICION_C                           = 'CLIENTE';
        pfDTO.ACC_ESTADO_C                              = 'CANCELADO';
        pfDTO.ACC_SUBESTADO_C                           = 'DESVINCULADO POR CLIENTE';
        pfDTO.ACC_SEGMENTO_C                            = 99;
        pfDTO.ACC_Ultima_Segmentacion_c                 = '2020-11-23';
        pfDTO.ACC_TELEFONO_CAMPANAS_C                   = '8099098765';
        pfDTO.ACC_Correo_Electronico_Campanas_c         = 'test.campanas@viseo.com';
        pfDTO.ACC_Fecha_Vencimiento_Pasaporte_c         = '2020-11-23';
        pfDTO.ACC_ES_EMPLEADO_VIMENCA_C                 = true;
        pfDTO.ACC_EMPRESA_GRUPO_C                       = 'Banco Vimenca';
        pfDTO.ACC_CLIENTE_CONOCIDO_C                    = true;
        pfDTO.PERSONBIRTHDATE                           = '2020-11-23';
        pfDTO.ACC_GENERO_C                              = 'FEMENINO';
        pfDTO.ACC_ESTADO_CIVIL_C                        = 'CASADO/A';
        pfDTO.ACC_SCORE_CREDITICIO_C                    = 999;
        pfDTO.ACC_Ultima_Actualizacion_Score_c          = '2020-11-23';
        pfDTO.ACC_Categoria_Riesgo_Cliente_c            = 'A';
        pfDTO.ACC_CIF_C                                 = 1089007;
        pfDTO.ACC_UNIFICADO_CON_C                       = 'Test Viseo Unificado';
        pfDTO.ACC_Motivo_Rechazo_Cancelacion_c          = 'Test Viseo Motivo Rechazo';
        pfDTO.ACC_CODIGO_DEPOSITANTE_C                  = 'V12345';
        pfDTO.ejecutivoSiebel                           = 'kbermudez@bv.com.do';
        pfDTO.codigoOWNER                               = 'KBERM001';
        pfDTO.codigoUsuarioCaptador                     = 'KBERM001';
        //pfDTO.DIRECCION_PRIN= '1-68QVG';
        //pfDTO.VIA_CONTACTO_PRIN= '1-68QVB';
        pfDTO.ACC_Tipo_Identificacion_Anterior_c        = 'Cédula';
        pfDTO.ACC_N_Identificacion_Anterior_c           = '1-111-2222';
        pfDTO.ACC_PAIS_NACIMIENTO_C                     = 'REPUBLICA DOMINICANA';
        pfDTO.ACC_PROVINCIA_NACIMIENTO_C                = '02';
        pfDTO.Ciudad_Nacimiento_Codigo_c                = 101;
        pfDTO.ACC_CIUDAD_DE_NACIMIENTO_C                = 'BONAO';
        pfDTO.ACC_RELACION_EXTERIOR_C                   = 'Importador';
        pfDTO.ACC_APLICA_FATCA_C                        = true;
        pfDTO.ACC_TIPO_PERSONA_PF_C                     = 'P6';
        pfDTO.ACC_POSEE_OTRA_NACIONALIDAD_C             = true;
        pfDTO.ACC_OTRA_NACIONALIDAD_C                   = 'BRASIL';
        pfDTO.ACC_RESIDENCIA_REP_DOM_C                  = 'PERMANENTE';
        pfDTO.ACC_POSEE_RESID_OTRO_PAIS_C               = true;
        pfDTO.ACC_PAIS_RESIDENCIA_LEGAL_C               = 'BULGARIA';
        pfDTO.ACC_CUENTA_NOMINA_C                       = true;
        pfDTO.ACC_N_DEPENDIENTES_C                      = 2;
        pfDTO.ACC_TIPO_DEPOSITANTE_C                    = 'Mayoristas';
        pfDTO.ACC_MOTIVO_ACERCAMIENTO_C                 = 'Productos que ofrece';
        pfDTO.codigoEmpleadoRefiere                     = 'EBASORA';
        pfDTO.ACC_ORIGEN_C                              = 'Test Viseo Origen';
        pfDTO.ACC_RENTABILIDAD_C                        = 'Test VISEO Rentabilidad';
        pfDTO.ACC_TIPO_CLIENTE_PF_C                     = 511;
        pfDTO.ACC_TIPO_VINCULACION_C                    = 'DEUDOR O EMISOR NO VINCULADO';
        pfDTO.ACC_TIPO_ACTIVIDAD_C                      = 'EMPLEADO PRIVADO';
        pfDTO.Actividad_Economica_External_ID           = '1-ECO-TEST';
        pfDTO.ACC_TIPO_SECTOR_C                         = 'PRIVADO';
        pfDTO.ACC_Fecha_Conversion_Cliente_c            = '2020-11-23';
        pfDTO.ACC_Fecha_Reconversion_Cliente_c          = '2020-11-23';
        pfDTO.ACC_PUNTOS_ACUMULADOS_C                   = 100;
        pfDTO.ACC_PUNTOS_CANJEADOS_C                    = 25;
        pfDTO.ACC_PUNTOS_GENERADOS_C                    = 125;
        pfDTO.ACC_PUNTOS_POR_VENCER_C                   = 75;
        pfDTO.ACC_PUNTOS_VENCIDOS_C                     = 125;
        pfDTO.PERSONDONOTCALL                           = true;
        pfDTO.PERSONHASOPTEDOUTOFEMAIL                  = true;
        pfDTO.ACC_MEJOR_HORA_LLAMAR_C                   = 'Por la Tarde';
        pfDTO.ACC_Preferencias_Correspondencia_c        = 'Fax';
        pfDTO.ACC_Coincidencia_Listas_Externas_c        = true;
        pfDTO.ACC_Ultima_Actualizacion_Listas_Externas_c= '2020-11-23';
        pfDTO.ACC_Coincidencia_Listas_Internas_c        = true;
        pfDTO.ACC_Ultima_Actualizacion_Listas_Internas_c= '2020-11-23';
        pfDTO.ACC_APROBADO_CUMPLIMIENTO_C               = true;
        pfDTO.ACC_APROBADO_POR_C                        = 'Test Viseo Aprobado por';
        pfDTO.ACC_FECHA_APROBACION_C                    = '2020-11-23';
        pfDTO.ACC_RESULTADO_VALIDACION_C                = 'APROBADO';
        pfDTO.ACC_LISTAS_C                              = 'Lista 1 Lista2 Lista 3 ';
        pfDTO.ACC_FECHA_INFORMACION_C                   = '2020-11-23';
        pfDTO.ACC_TOTAL_ACTIVOS_C                       = 150000;
        pfDTO.ACC_MONEDA_C                              = 'DOP';
        pfDTO.ACC_VENTAS_INGRESOS_ANUALES_C             = 1800000;
        pfDTO.ACC_PATRIMONIO_DESC_C                     = 'Test Patrimono';
        pfDTO.ACC_NUMEMPLEADOS_C                        = 342;
        pfDTO.ACC_FUENTE_INFORMACION_C                  = 'E';
        pfDTO.ACC_PATRIMONIO_NUM_C                      = 12321;
        pfDTO.ACC_PERSONA_PEP_C                         = 'NO';
        pfDTO.ACC_TIPO_IDENTIF_PEP_C                    = 'Otros';
        pfDTO.ACC_N_IDENTIFICACION_PEP_C                = 67854;
        pfDTO.ACC_PRIMER_NOMBRE_PEP_C                   = 'Test FST Name PEP';
        pfDTO.ACC_SEGUNDO_NOMBRE_PEP_C                  = 'Test 2ND Name PEP';
        pfDTO.ACC_PRIMER_APELLIDO_PEP_C                 = 'Test FST APE PEP';
        pfDTO.ACC_SEGUNDO_APELLIDO_PEP_C                = 'Test 2ND APE PEP';
        pfDTO.ACC_TIPO_RELACION_PEP_C                   = '';
        pfDTO.ACC_OCUPACION_PEP_C                       = 'COLECTOR';
        pfDTO.ACC_PUESTO_CARGO_PEP_C                    = 'Test VISEO Cargo PEP';
        pfDTO.ACC_INSTITUCION_TRABAJO_PEP_C             = 'AYUNTAMIENTO DE JAIBA';
        pfDTO.ACC_DIRECCION_TRABAJO_PEP_C               = 'Test VISEO Dir Trabajo PEP';
        pfDTO.ACC_FECHA_DECRETO_PEP_C                   = '2020-11-23';
        pfDTO.ACC_N_DECRETO_PEP_C                       = 767676;
        pfDTO.ACC_NACIONALIDAD_PEP_C                    = 'ALAND';
        pfDTO.ACC_NOMBRE_FATCA_C                        = 'Test Nombre FATCA';
        pfDTO.ACC_APELLIDO_FATCA_C                      = 'Test Ape FATCA';
        pfDTO.ACC_N_PASAPORTE_FATCA_C                   = 'US7971';
        pfDTO.ACC_FECHA_EXPIRACION_FATCA_C              = '2020-11-23';
        pfDTO.ACC_SSN_FATCA_C                           = 123456787;
        pfDTO.ACC_TIN_FATCA_C                           = 987656780;
        pfDTO.ACC_NACIONALIDAD_FATCA_C                  = 'BURMA';
        pfDTO.ACC_DIRECCION_FATCA_C                     = 'Test Dire FATCA';
        pfDTO.ACC_CIUDAD_FATCA_C                        = 'Test VISEO Ciudad FATCA';
        pfDTO.ACC_CODIGO_POSTAL_FATCA_C                 = '78978796111';
        pfDTO.ACC_TELEFONO_FATCA_C                      = '8090987651';
        pfDTO.Lugar_de_nacimiento_Padron_Electoral_c    = 'Pedernales';
        pfDTO.Tipo_de_vivienda_c                        = 1;
        pfDTO.Tiempo_en_Vivienda_c                      = '5 meses';
        pfDTO.ACC_Correo_Electronico_Cliente_c          = 'testcorreocliente@test.do';
        pfDTO.PHONE                                     = '8090987678';
        pfDTO.SALUTATION                                = 'Ms.';
        pfDTO.BillingStreet                             = 'Avenida Abraham Lincoln';
        pfDTO.BillingCity                               = 'Santo Domingo';
        pfDTO.BillingPostalCode                         = 'Santo Domingo BS';
        pfDTO.BillingState                              = 'Santo Domingo ZPC';
        pfDTO.BillingCountry                            = 'Dominican Republic';
        pfDTO.ACC_Calificacion_de_cliente_c             = 'ALTO';
        pfDTO.ACC_Fecha_de_calificacion_c               = '2023-02-02';
        pfDTO.ACC_NoIndicaTipoMonedaProdTrans_c         = 'Local';
        pfDTO.ACC_DeclaracionSiManejaOpInternacionales_c= true;
        pfDTO.ACC_Productos_a_solicitar_c               = '10;9';
        pfDTO.ACC_Canales_a_utilizar_c                  = 'Cajeros Automáticos y Tarjetas de Débito';
        pfDTO.ACC_IndicarVolMensualEstimadoTransaccion_c= 60000;
        pfDTO.ACC_DeclaracionSiProyectaManejarEfectivo_c= true;
        pfDTO.ACC_Tipo_beneficio_final_c                = 1;
        pfDTO.ACC_Servicios_a_solicitar_c               = 'b';

        String reqBody = JSON.serialize(pfDTO);

        RestRequest request = new RestRequest();
        request.requestURI = URL.getOrgDomainUrl()+'/services/apexrest/cliente/upsert-persona-fisica/';
        request.httpMethod = 'PUT';
        request.requestBody= Blob.valueOf(reqBody);

        RestResponse res = new RestResponse();
        RestContext.request = request;
        RestContext.response = res;

        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        REST_PersonaFisica_FSC.doPut();
        System.assertEquals(200, RestContext.response.statusCode);
    }
}
