/**
 * @description       : Expone servicio para crear o actualizar Clientes Persona Física
 * @author            : Luis Naranjo Pastrana
 * Historial de cambios
 * 
 * Fecha            Desarrollador           Detalle 
 * 26-05-2023       Luis Naranjo            Se añade Response al log
 *
 */
//@RestResource(urlMapping='/cliente/upsert-persona-fisica/')
global class REST_PersonaFisica {
    
    /*private static final Map<Integer,String> RES_STATUS= new Map<Integer,String>{200=>'Success', 202=>'Partial Success', 404=>'Not found', 500=>'Error Internal Server'};
    private static final string DEV_RT_PERSONA_FISICA = 'PersonAccount';

    @HttpPut
    global static void doPut(){

        ResponseWrapper resWrapper = new ResponseWrapper();
        RestRequest reqContext = RestContext.request;
        RestResponse resContext = RestContext.response;
        HttpRequest httpRequest = new HttpRequest();
        HttpResponse httpResponse = new HttpResponse();

        String reqBody = reqContext.requestBody.toString();
        
        try{
            
            // Se deserializa el request recibido
            PersonaFisicaDTO personaFisicaDTO = (PersonaFisicaDTO) JSON.deserialize(reqBody, PersonaFisicaDTO.class);
                        
            // Se realiza el mapeo de la información recibida en el objeto correspondiente en Salesforce
            Account accountToUpsert = new Account();
            try {
                accountToUpsert = mapearClientePersonaFisica(personaFisicaDTO);
            } catch (Exception e) {
                resWrapper.errors.add('Error Code: '+e.getTypeName()+'. Fields: '+e.getCause()+'. Message: '+ e.getMessage());
            }

            // Se guarda la información mapeada
            Schema.SObjectField externalField = Account.Fields.ACC_CIF__c;
            Database.UpsertResult urAccount = Database.upsert(accountToUpsert, externalField, false);
            if (!urAccount.isSuccess()) {
                for(Database.Error err : urAccount.getErrors()) {
                    resWrapper.errors.add('Error Code: '+err.getStatusCode()+'. Fields: '+err.getFields()+'. Message: '+err.getMessage());
                }
            }

            // Se prepara la respuesta
            if(resWrapper.errors.isEmpty()){
                resContext.StatusCode = 200;
            }else if(resContext.statusCode == null){
                resContext.StatusCode = 202;
            }

        }catch(Exception e){

            System.debug('Error :: ' + e);
            resWrapper.errors.add('Error Code: <>. Fields: <>. Message: '+e.getMessage());
            resContext.StatusCode = 500;

        }finally{

            resWrapper.message = RES_STATUS.get(resContext.StatusCode);
            resContext.responseBody= Blob.valueOf(JSON.serialize(resWrapper));
            
            // Registro del Log
            httpResponse.setBody(JSON.serialize(resWrapper));
            httpResponse.setStatusCode(resContext.StatusCode);
            httpResponse.setStatus(RES_STATUS.get(resContext.StatusCode));
            httpRequest.setBody(reqBody);
            
            INTLogger.INTLoggerResult result = INTLogger.logCallout('Cliente Persona Fisica', 'REST_PersonaFisica.doPut', httpRequest, httpResponse);
        }   
    }

    public static Account mapearClientePersonaFisica(PersonaFisicaDTO personaFisicaDTO){
        try {

            // Guardar Codigos de actividades
            Set<String> setCodigoActividaEco = new Set<String>();
            if (personaFisicaDTO.Actividad_Economica_External_ID != null) {
                setCodigoActividaEco.add(personaFisicaDTO.Actividad_Economica_External_ID);
            }
            // Equivalencia Codigo actividad eco - Salesforce Id
            Map<String, Id> actividadesMap = new Map<String,Id>();
            if (setCodigoActividaEco.size() > 0) {
                for (Datos_Maestros__c act : [select Id, DM_Direccion__c from Datos_Maestros__c where DM_Direccion__c in :setCodigoActividaEco]) {
                    actividadesMap.put(act.DM_Direccion__c, act.Id);
                }
            }

            // Guardar Codigos de usuarios
            Set<String> setCodigoUsuario = new Set<String>();
            if (personaFisicaDTO.codigoUsuarioCaptador!= null) {
                setCodigoUsuario.add(personaFisicaDTO.codigoUsuarioCaptador);
            }
            if (personaFisicaDTO.codigoOWNER!= null) {
                setCodigoUsuario.add(personaFisicaDTO.codigoOWNER);
            }
            if (personaFisicaDTO.codigoEmpleadoRefiere!= null) {
                setCodigoUsuario.add(personaFisicaDTO.codigoEmpleadoRefiere);
            }

            // Equivalencia Codigo usuario - Salesforce Id
            Map<String, Id> usuariosMap = new Map<String,Id>();
            if (setCodigoUsuario.size() > 0 ) {
                for (user user : [SELECT id, alias FROM USER WHERE Alias in :setCodigoUsuario]) {
                    usuariosMap.put(user.alias, user.Id);
                }
            }

            // Record Type Id para Account Persona Fisica
            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(DEV_RT_PERSONA_FISICA).getRecordTypeId();

            // Mapeo de Cliente DTO en Account
            Account acc = new Account();
            if (actividadesMap.containsKey(personaFisicaDTO.Actividad_Economica_External_ID)) {
                acc.ACC_Actividad_Economica__c = actividadesMap.get(personaFisicaDTO.Actividad_Economica_External_ID);
            }
            if (usuariosMap.containsKey(personaFisicaDTO.codigoUsuarioCaptador)) {
                acc.ACC_Usuario_Captador__c = usuariosMap.get(personaFisicaDTO.codigoUsuarioCaptador);
            }
            if (usuariosMap.containsKey(personaFisicaDTO.codigoOWNER)) {
                acc.OwnerId = usuariosMap.get(personaFisicaDTO.codigoOWNER);
            }
            if (usuariosMap.containsKey(personaFisicaDTO.codigoEmpleadoRefiere)) {
                acc.ACC_Empleado_Refiere__c = usuariosMap.get(personaFisicaDTO.codigoEmpleadoRefiere);
            }
            acc.RecordTypeId = recordTypeId;
            acc.ACC_Apellido_FATCA__c = personaFisicaDTO.ACC_Apellido_FATCA_c;
            acc.ACC_Aplica_FATCA__c = personaFisicaDTO.ACC_Aplica_FATCA_c;
            acc.ACC_Aprobado_Cumplimiento__c = personaFisicaDTO.ACC_Aprobado_Cumplimiento_c;
            acc.ACC_Aprobado_Por__c = personaFisicaDTO.ACC_Aprobado_Por_c;
            acc.ACC_Calificacion_de_cliente__c = personaFisicaDTO.ACC_Calificacion_de_cliente_c;
            acc.ACC_Canales_a_utilizar__c = personaFisicaDTO.ACC_Canales_a_utilizar_c;
            acc.ACC_Categoria_Riesgo_Cliente__c = personaFisicaDTO.ACC_Categoria_Riesgo_Cliente_c;
            acc.ACC_CIF__c = String.valueOf(personaFisicaDTO.ACC_CIF_c);
            acc.ACC_Ciudad_de_nacimiento__c = personaFisicaDTO.ACC_Ciudad_de_nacimiento_c;
            acc.ACC_Ciudad_FATCA__c = personaFisicaDTO.ACC_Ciudad_FATCA_c;
            acc.Ciudad_Nacimiento_Codigo__c = String.valueOf(personaFisicaDTO.Ciudad_Nacimiento_Codigo_c);
            acc.ACC_Cliente_Conocido__c = personaFisicaDTO.ACC_Cliente_Conocido_c;
            acc.ACC_Codigo_Depositante__c = personaFisicaDTO.ACC_Codigo_Depositante_c;
            acc.ACC_Codigo_Postal_FATCA__c = personaFisicaDTO.ACC_Codigo_Postal_FATCA_c;
            acc.ACC_Coincidencia_Listas_Externas__c = personaFisicaDTO.ACC_Coincidencia_Listas_Externas_c;
            acc.ACC_Coincidencia_Listas_Internas__c = personaFisicaDTO.ACC_Coincidencia_Listas_Internas_c;
            acc.ACC_Condicion__c = personaFisicaDTO.ACC_Condicion_c;
            acc.ACC_Correo_Electronico_Campanas__c = personaFisicaDTO.ACC_Correo_Electronico_Campanas_c;
            acc.ACC_Correo_Electronico_Cliente__c = personaFisicaDTO.ACC_Correo_Electronico_Cliente_c;
            acc.ACC_Cuenta_Nomina__c = personaFisicaDTO.ACC_Cuenta_Nomina_c;
            acc.ACC_DeclaracionSiManejaOpInternacionales__c = personaFisicaDTO.ACC_DeclaracionSiManejaOpInternacionales_c;
            acc.ACC_DeclaracionSiProyectaManejarEfectivo__c = personaFisicaDTO.ACC_DeclaracionSiProyectaManejarEfectivo_c;
            acc.ACC_Direccion_FATCA__c = personaFisicaDTO.ACC_Direccion_FATCA_c;
            acc.ACC_Direccion_Trabajo_PEP__c = personaFisicaDTO.ACC_Direccion_Trabajo_PEP_c;
            acc.ACC_Empresa_Grupo__c = personaFisicaDTO.ACC_Empresa_Grupo_c;
            acc.ACC_Es_Empleado_Vimenca__c = personaFisicaDTO.ACC_Es_Empleado_Vimenca_c;
            acc.ACC_Estado__c = personaFisicaDTO.ACC_Estado_c;
            acc.ACC_Estado_Civil__c = personaFisicaDTO.ACC_Estado_Civil_c;
            acc.ACC_Estado_FATCA__c = personaFisicaDTO.ACC_Estado_FATCA_c;
            acc.ACC_Fecha_Aprobacion__c = procesarFecha(personaFisicaDTO.ACC_Fecha_Aprobacion_c);
            acc.ACC_Fecha_Conversion_Cliente__c = procesarFecha(personaFisicaDTO.ACC_Fecha_Conversion_Cliente_c);
            acc.ACC_Fecha_de_calificacion__c = procesarFecha(personaFisicaDTO.ACC_Fecha_de_calificacion_c);
            acc.ACC_Fecha_Decreto_PEP__c = procesarFecha(personaFisicaDTO.ACC_Fecha_Decreto_PEP_c);
            acc.ACC_Fecha_Expiracion_FATCA__c =procesarFecha(personaFisicaDTO.ACC_Fecha_Expiracion_FATCA_c);
            acc.ACC_Fecha_Informacion__c =procesarFecha(personaFisicaDTO.ACC_Fecha_Informacion_c);
            acc.ACC_Fecha_Reconversion_Cliente__c =procesarFecha(personaFisicaDTO.ACC_Fecha_Reconversion_Cliente_c);
            acc.ACC_Fecha_Vencimiento_Pasaporte__c =procesarFecha(personaFisicaDTO.ACC_Fecha_Vencimiento_Pasaporte_c);
            acc.ACC_Fuente_Informacion__c = personaFisicaDTO.ACC_Fuente_Informacion_c;
            acc.ACC_Genero__c = personaFisicaDTO.ACC_Genero_c;
            acc.ACC_Genero_Identificaci_n__c = personaFisicaDTO.ACC_Genero_Identificaci_n_c;
            acc.ACC_Id_Externo_Cuenta__c = personaFisicaDTO.ACC_Id_Externo_Cuenta_c;
            acc.ACC_IndicarVolMensualEstimadoTransaccion__c = personaFisicaDTO.ACC_IndicarVolMensualEstimadoTransaccion_c;
            acc.ACC_Institucion_Trabajo_PEP__c = personaFisicaDTO.ACC_Institucion_Trabajo_PEP_c;
            acc.ACC_Listas__c = personaFisicaDTO.ACC_Listas_c;
            acc.ACC_Mejor_Hora_Llamar__c = personaFisicaDTO.ACC_Mejor_Hora_Llamar_c;
            acc.ACC_Moneda__c = personaFisicaDTO.ACC_Moneda_c;
            acc.ACC_Motivo_Acercamiento__c = personaFisicaDTO.ACC_Motivo_Acercamiento_c;
            acc.ACC_Motivo_Rechazo_Cancelacion__c = personaFisicaDTO.ACC_Motivo_Rechazo_Cancelacion_c;
            acc.ACC_N_Decreto_PEP__c = String.valueOf(personaFisicaDTO.ACC_N_Decreto_PEP_c);
            acc.ACC_N_Dependientes__c = personaFisicaDTO.ACC_N_Dependientes_c;
            acc.ACC_N_Identificacion_Anterior__c = personaFisicaDTO.ACC_N_Identificacion_Anterior_c;
            acc.ACC_N_Identificacion_PEP__c = String.valueOf(personaFisicaDTO.ACC_N_Identificacion_PEP_c);
            acc.ACC_N_Pasaporte_FATCA__c = personaFisicaDTO.ACC_N_Pasaporte_FATCA_c;
            acc.ACC_Nacionalidad__c = personaFisicaDTO.ACC_Nacionalidad_c;
            acc.ACC_Nacionalidad_FATCA__c = personaFisicaDTO.ACC_Nacionalidad_FATCA_c;
            acc.ACC_Nacionalidad_PEP__c = personaFisicaDTO.ACC_Nacionalidad_PEP_c;
            acc.ACC_NoIndicaTipoMonedaProdTrans__c = personaFisicaDTO.ACC_NoIndicaTipoMonedaProdTrans_c;
            acc.ACC_Nombre_FATCA__c = personaFisicaDTO.ACC_Nombre_FATCA_c;
            acc.ACC_NumEmpleados__c = personaFisicaDTO.ACC_NumEmpleados_c;
            acc.ACC_NumIdentificacion__c = String.valueOf(personaFisicaDTO.ACC_NumIdentificacion_c);
            acc.ACC_Ocupacion_PEP__c = personaFisicaDTO.ACC_Ocupacion_PEP_c;
            acc.ACC_Origen__c = personaFisicaDTO.ACC_Origen_c;
            acc.ACC_Otra_Nacionalidad__c = personaFisicaDTO.ACC_Otra_Nacionalidad_c;
            acc.ACC_Pais_Nacimiento__c = personaFisicaDTO.ACC_Pais_Nacimiento_c;
            acc.ACC_Pais_Residencia_Legal__c = personaFisicaDTO.ACC_Pais_Residencia_Legal_c;
            acc.ACC_Patrimonio_Desc__c = personaFisicaDTO.ACC_Patrimonio_Desc_c;
            acc.ACC_Patrimonio_Num__c = personaFisicaDTO.ACC_Patrimonio_Num_c;
            acc.ACC_Persona_Fisica__c = personaFisicaDTO.ACC_Persona_Fisica_c;
            acc.ACC_Persona_PEP__c = personaFisicaDTO.ACC_Persona_PEP_c;
            acc.ACC_Posee_Otra_Nacionalidad__c = personaFisicaDTO.ACC_Posee_Otra_Nacionalidad_c;
            acc.ACC_Posee_Resid_Otro_Pais__c = personaFisicaDTO.ACC_Posee_Resid_Otro_Pais_c;
            acc.ACC_Preferencias_Correspondencia__c = personaFisicaDTO.ACC_Preferencias_Correspondencia_c;
            acc.ACC_Primer_Apellido_PEP__c = personaFisicaDTO.ACC_Primer_Apellido_PEP_c;
            acc.ACC_Primer_Nombre_PEP__c = personaFisicaDTO.ACC_Primer_Nombre_PEP_c;
            acc.ACC_ProductosASolicitar__c = personaFisicaDTO.ACC_Productos_a_solicitar_c;
            acc.ACC_Provincia_Nacimiento__c = personaFisicaDTO.ACC_Provincia_Nacimiento_c;
            acc.ACC_Puesto_Cargo_PEP__c = personaFisicaDTO.ACC_Puesto_Cargo_PEP_c;
            acc.ACC_Puntos_Acumulados__c = personaFisicaDTO.ACC_Puntos_Acumulados_c;
            acc.ACC_Puntos_Canjeados__c = personaFisicaDTO.ACC_Puntos_Canjeados_c;
            acc.ACC_Puntos_Generados__c = personaFisicaDTO.ACC_Puntos_Generados_c;
            acc.ACC_Puntos_Por_Vencer__c = personaFisicaDTO.ACC_Puntos_Por_Vencer_c;
            acc.ACC_Puntos_Vencidos__c = personaFisicaDTO.ACC_Puntos_Vencidos_c;
            acc.ACC_Relacion_Exterior__c = personaFisicaDTO.ACC_Relacion_Exterior_c;
            acc.ACC_Rentabilidad__c = personaFisicaDTO.ACC_Rentabilidad_c;
            acc.ACC_Residencia_Rep_Dom__c = personaFisicaDTO.ACC_Residencia_Rep_Dom_c;
            acc.ACC_Resultado_Validacion__c = personaFisicaDTO.ACC_Resultado_Validacion_c;
            acc.ACC_Score_Crediticio__c = String.valueOf(personaFisicaDTO.ACC_Score_Crediticio_c);
            acc.ACC_Segmento__c = String.valueOf(personaFisicaDTO.ACC_Segmento_c);
            acc.ACC_Segundo_Apellido_PEP__c = personaFisicaDTO.ACC_Segundo_Apellido_PEP_c;
            acc.ACC_Segundo_Nombre_PEP__c = personaFisicaDTO.ACC_Segundo_Nombre_PEP_c;
            acc.ACC_Servicios_a_solicitar__c = personaFisicaDTO.ACC_Servicios_a_solicitar_c;
            acc.ACC_SSN_FATCA__c = String.valueOf(personaFisicaDTO.ACC_SSN_FATCA_c);
            acc.ACC_SubEstado__c = personaFisicaDTO.ACC_SubEstado_c;
            acc.ACC_Telefono_Campanas__c = personaFisicaDTO.ACC_Telefono_Campanas_c;
            acc.ACC_Telefono_FATCA__c = personaFisicaDTO.ACC_Telefono_FATCA_c;
            acc.ACC_TIN_FATCA__c = String.valueOf(personaFisicaDTO.ACC_TIN_FATCA_c);
            acc.ACC_Tipo_Actividad__c = personaFisicaDTO.ACC_Tipo_Actividad_c;
            acc.ACC_Tipo_beneficio_final__c = String.valueOf(personaFisicaDTO.ACC_Tipo_beneficio_final_c);
            acc.ACC_Tipo_Cliente_PF__c = String.valueOf(personaFisicaDTO.ACC_Tipo_Cliente_PF_c);
            acc.ACC_Tipo_Depositante__c = personaFisicaDTO.ACC_Tipo_Depositante_c;
            acc.ACC_Tipo_Identificacion_Anterior__c = personaFisicaDTO.ACC_Tipo_Identificacion_Anterior_c;
            acc.ACC_Tipo_Identif_PEP__c = personaFisicaDTO.ACC_Tipo_Identif_PEP_c;
            acc.ACC_Tipo_Persona_PF__c = personaFisicaDTO.ACC_Tipo_Persona_PF_c;
            acc.ACC_Tipo_Relacion_PEP__c = personaFisicaDTO.ACC_Tipo_Relacion_PEP_c;
            acc.ACC_Tipo_Sector__c = personaFisicaDTO.ACC_Tipo_Sector_c;
            acc.ACC_Tipo_Vinculacion__c = personaFisicaDTO.ACC_Tipo_Vinculacion_c;
            acc.ACC_TipoIdentificacion__c = personaFisicaDTO.ACC_TipoIdentificacion_c;
            acc.ACC_Total_Activos__c = personaFisicaDTO.ACC_Total_Activos_c;
            acc.ACC_Ultima_Actualizacion_Listas_Externas__c = procesarFecha(personaFisicaDTO.ACC_Ultima_Actualizacion_Listas_Externas_c);
            acc.ACC_Ultima_Actualizacion_Listas_Internas__c = procesarFecha(personaFisicaDTO.ACC_Ultima_Actualizacion_Listas_Internas_c);
            acc.ACC_Ultima_Actualizacion_Score__c = procesarFecha(personaFisicaDTO.ACC_Ultima_Actualizacion_Score_c);
            acc.ACC_Ultima_Segmentacion__c = procesarFecha(personaFisicaDTO.ACC_Ultima_Segmentacion_c);
            acc.ACC_Unificado_Con__c = personaFisicaDTO.ACC_Unificado_Con_c;
            acc.ACC_Ventas_Ingresos_Anuales__c = personaFisicaDTO.ACC_Ventas_Ingresos_Anuales_c;
            acc.BillingCity = personaFisicaDTO.BillingCity;
            acc.BillingCountry = personaFisicaDTO.BillingCountry;
            acc.BillingState = personaFisicaDTO.BillingState;
            acc.BillingPostalCode = personaFisicaDTO.BillingPostalCode;
            acc.BillingStreet = personaFisicaDTO.BillingStreet;
            acc.ACC_Ejecutivo__c = personaFisicaDTO.ejecutivoSiebel;
            acc.Lugar_de_nacimiento_Padron_Electoral__c = personaFisicaDTO.Lugar_de_nacimiento_Padron_Electoral_c;
            acc.PersonBirthdate = procesarFecha(personaFisicaDTO.PersonBirthdate);
            acc.PersonDoNotCall = personaFisicaDTO.PersonDoNotCall;
            acc.PersonHasOptedOutOfEmail = personaFisicaDTO.PersonHasOptedOutOfEmail;
            acc.Phone = personaFisicaDTO.Phone;
            acc.Salutation = personaFisicaDTO.Salutation;
            acc.Tiempo_en_Vivienda__c = personaFisicaDTO.Tiempo_en_Vivienda_c;
            acc.Tipo_de_vivienda__c = String.valueOf(personaFisicaDTO.Tipo_de_vivienda_c);
            // Por Validation Rule "VR_Validacion_Cliente_PF"
            // Prevención a nivel de registro de que actualicen valores de campos.
            if (!isEmpty(personaFisicaDTO.LastName)) {
                acc.FirstName = personaFisicaDTO.FirstName;
                acc.LastName = personaFisicaDTO.LastName;
                acc.MiddleName = personaFisicaDTO.MiddleName;
                acc.Suffix = personaFisicaDTO.Suffix;
            }

            return acc;                
        } catch (Exception e) {
            throw e;
        }
    }

    global class PersonaFisicaDTO{
        public string Actividad_Economica_External_ID; 
        public string ACC_Apellido_FATCA_c;
        public boolean ACC_Aplica_FATCA_c;
        public boolean ACC_Aprobado_Cumplimiento_c;
        public string ACC_Aprobado_Por_c;
        public string ACC_Calificacion_de_cliente_c;
        public string ACC_Canales_a_utilizar_c;
        public string ACC_Categoria_Riesgo_Cliente_c;
        public integer ACC_CIF_c;
        public string ACC_Ciudad_de_nacimiento_c;
        public string ACC_Ciudad_FATCA_c;
        public integer Ciudad_Nacimiento_Codigo_c;
        public boolean ACC_Cliente_Conocido_c;
        public string ACC_Codigo_Depositante_c;
        public string ACC_Codigo_Postal_FATCA_c;
        public boolean ACC_Coincidencia_Listas_Externas_c;
        public boolean ACC_Coincidencia_Listas_Internas_c;
        public string ACC_Condicion_c;
        public string ACC_Correo_Electronico_Campanas_c;
        public string ACC_Correo_Electronico_Cliente_c;
        public boolean ACC_Cuenta_Nomina_c;
        public boolean ACC_DeclaracionSiManejaOpInternacionales_c;
        public boolean ACC_DeclaracionSiProyectaManejarEfectivo_c;
        public string ACC_Direccion_FATCA_c;
        public string ACC_Direccion_Trabajo_PEP_c;
        public string codigoEmpleadoRefiere;
        public string ACC_Empresa_Grupo_c;
        public boolean ACC_Es_Empleado_Vimenca_c;
        public string ACC_Estado_c;
        public string ACC_Estado_Civil_c;
        public string ACC_Estado_FATCA_c;
        public string ACC_Fecha_Aprobacion_c;
        public string ACC_Fecha_Conversion_Cliente_c;
        public string ACC_Fecha_de_calificacion_c;
        public string ACC_Fecha_Decreto_PEP_c;
        public string ACC_Fecha_Expiracion_FATCA_c;
        public string ACC_Fecha_Informacion_c;
        public string ACC_Fecha_Reconversion_Cliente_c;
        public string ACC_Fecha_Vencimiento_Pasaporte_c;
        public string ACC_Fuente_Informacion_c;
        public string ACC_Genero_c;
        public string ACC_Genero_Identificaci_n_c;
        public string ACC_Id_Externo_Cuenta_c;
        public decimal ACC_IndicarVolMensualEstimadoTransaccion_c;
        public string ACC_Institucion_Trabajo_PEP_c;
        public string ACC_Listas_c;
        public string ACC_Mejor_Hora_Llamar_c;
        public string ACC_Moneda_c;
        public string ACC_Motivo_Acercamiento_c;
        public string ACC_Motivo_Rechazo_Cancelacion_c;
        public integer ACC_N_Decreto_PEP_c;
        public integer ACC_N_Dependientes_c;
        public string ACC_N_Identificacion_Anterior_c;
        public integer ACC_N_Identificacion_PEP_c;
        public string ACC_N_Pasaporte_FATCA_c;
        public string ACC_Nacionalidad_c;
        public string ACC_Nacionalidad_FATCA_c;
        public string ACC_Nacionalidad_PEP_c;
        public string ACC_NoIndicaTipoMonedaProdTrans_c;
        public string ACC_Nombre_FATCA_c;
        public integer ACC_NumEmpleados_c;
        public string ACC_NumIdentificacion_c;
        public string ACC_Ocupacion_PEP_c;
        public string ACC_Origen_c;
        public string ACC_Otra_Nacionalidad_c;
        public string ACC_Pais_Nacimiento_c;
        public string ACC_Pais_Residencia_Legal_c;
        public string ACC_Patrimonio_Desc_c;
        public integer ACC_Patrimonio_Num_c;
        public boolean ACC_Persona_Fisica_c;
        public string ACC_Persona_PEP_c;
        public boolean ACC_Posee_Otra_Nacionalidad_c;
        public boolean ACC_Posee_Resid_Otro_Pais_c;
        public string ACC_Preferencias_Correspondencia_c;
        public string ACC_Primer_Apellido_PEP_c;
        public string ACC_Primer_Nombre_PEP_c;
        public string ACC_Productos_a_solicitar_c;
        public string ACC_Provincia_Nacimiento_c;
        public string ACC_Puesto_Cargo_PEP_c;
        public integer ACC_Puntos_Acumulados_c;
        public integer ACC_Puntos_Canjeados_c;
        public integer ACC_Puntos_Generados_c;
        public integer ACC_Puntos_Por_Vencer_c;
        public integer ACC_Puntos_Vencidos_c;
        public string ACC_Relacion_Exterior_c;
        public string ACC_Rentabilidad_c;
        public string ACC_Residencia_Rep_Dom_c;
        public string ACC_Resultado_Validacion_c;
        public integer ACC_Score_Crediticio_c;
        public integer ACC_Segmento_c;
        public string ACC_Segundo_Apellido_PEP_c;
        public string ACC_Segundo_Nombre_PEP_c;
        public string ACC_Servicios_a_solicitar_c;
        public integer ACC_SSN_FATCA_c;
        public string ACC_SubEstado_c;
        public string ACC_Telefono_Campanas_c;
        public string ACC_Telefono_FATCA_c;
        public integer ACC_TIN_FATCA_c;
        public string ACC_Tipo_Actividad_c;
        public integer ACC_Tipo_beneficio_final_c;
        public integer ACC_Tipo_Cliente_PF_c;
        public string ACC_Tipo_Depositante_c;
        public string ACC_Tipo_Identificacion_Anterior_c;
        public string ACC_Tipo_Identif_PEP_c;
        public string ACC_Tipo_Persona_PF_c;
        public string ACC_Tipo_Relacion_PEP_c;
        public string ACC_Tipo_Sector_c;
        public string ACC_Tipo_Vinculacion_c;
        public string ACC_TipoIdentificacion_c;
        public integer ACC_Total_Activos_c;
        public string ACC_Ultima_Actualizacion_Listas_Externas_c;
        public string ACC_Ultima_Actualizacion_Listas_Internas_c;
        public string ACC_Ultima_Actualizacion_Score_c;
        public string ACC_Ultima_Segmentacion_c;
        public string ACC_Unificado_Con_c;
        public string codigoUsuarioCaptador;
        public integer ACC_Ventas_Ingresos_Anuales_c;
        public string BillingCity;
        public string BillingCountry;
        public string BillingState;
        public string BillingPostalCode;
        public string BillingStreet;
        public string ejecutivoSiebel;
        public string FirstName;
        public string LastName;
        public string Lugar_de_nacimiento_Padron_Electoral_c;
        public string MiddleName;
        public string codigoOWNER;
        public string PersonBirthdate;
        public boolean PersonDoNotCall;
        public boolean PersonHasOptedOutOfEmail;
        public string Phone;
        public string RecordTypeId;
        public string Salutation;
        public string Suffix;
        public string Tiempo_en_Vivienda_c;
        public integer Tipo_de_vivienda_c;
    }

    global class ResponseWrapper{
        String message;
        List<String> errors;
        
        global ResponseWrapper(){
            this.errors= new List<String>();
        }
    }

    private static Date procesarFecha(String value){
        if(value != null && value.trim() != ''){
            return Date.valueOf(value.trim());
        }else return null;
    }

    public static boolean isEmpty(String value){
        return (value == null || value.trim() == '');
    }*/
}