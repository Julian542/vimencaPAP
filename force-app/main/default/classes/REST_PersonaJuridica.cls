/**
 * @description       : Expone servicio para crear o actualizar Clientes Persona Física
 * @author            : Luis Naranjo Pastrana
 * 
 * Historial de cambios
 * Fecha            Desarrollador           Detalle 
 * 26-05-2023       Luis Naranjo            Se añade Response al log
 *
 */
//@RestResource(urlMapping='/cliente/upsert-persona-juridica/')
global class REST_PersonaJuridica {
    
    /*private static final Map<Integer,String> RES_STATUS= new Map<Integer,String>{200=>'Success', 202=>'Partial Success', 404=>'Not found', 500=>'Error Internal Server'};
    private static final string DEV_RT_PERSONA_JURIDICA = 'Personas_Juridicas';

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
            PersonaJuridicaDTO personaJuridicaDTO = (PersonaJuridicaDTO) JSON.deserialize(reqBody, PersonaJuridicaDTO.class);
            
            // Se realiza el mapeo de la información recibida en el objeto correspondiente en Salesforce
            Account accountToUpsert;
            try {
                accountToUpsert = mapearClientePersonaJuridica(personaJuridicaDTO);
            } catch (Exception e) { resWrapper.errors.add('Error Code: '+e.getTypeName()+'. Fields: '+e.getCause()+'. Message: '+ e.getMessage()); }

            // Se guarda la información mapeada
            Schema.SObjectField externalField = Account.Fields.ACC_CIF__c;
            Database.UpsertResult urAccount = Database.upsert(accountToUpsert, externalField, false);
            if (!urAccount.isSuccess()) {
                for(Database.Error err : urAccount.getErrors()) { resWrapper.errors.add('Error Code: '+err.getStatusCode()+'. Fields: '+err.getFields()+'. Message: '+err.getMessage());}
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

            INTLogger.INTLoggerResult result = INTLogger.logCallout('Cliente Persona Juridica', 'REST_PersonaJuridica.doPut', httpRequest, httpResponse);
        }   
    }

    public static Account mapearClientePersonaJuridica(PersonaJuridicaDTO personaJuridicaDTO){
        try {

            // Buscar cuentas
            Set<String> setExternalIdCuentas = new Set<String>();
            if (personaJuridicaDTO.Id_Externo_Cuenta_Parent != null) {
                setExternalIdCuentas.add(personaJuridicaDTO.Id_Externo_Cuenta_Parent);
            }
            // Equivalencia Codigo cuentas - Salesforce Id
            Map<String, Id> cuentasMap = new Map<String,Id>();
            if (setExternalIdCuentas.size() > 0 ) {
                for (Account acc : [select Id, ACC_Id_Externo_Cuenta__c from Account where ACC_Id_Externo_Cuenta__c in :setExternalIdCuentas]) {
                    cuentasMap.put(acc.ACC_Id_Externo_Cuenta__c, acc.Id);
                }
            }

            // Guardar Codigos de actividades
            Set<String> setCodigoActividaEco = new Set<String>();
            if (personaJuridicaDTO.Actividad_Economica_External_ID != null) {
                setCodigoActividaEco.add(personaJuridicaDTO.Actividad_Economica_External_ID);
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
            if (personaJuridicaDTO.codigoUsuarioCaptador!= null) {
                setCodigoUsuario.add(personaJuridicaDTO.codigoUsuarioCaptador);
            }
            if (personaJuridicaDTO.codigoOWNER!= null) {
                setCodigoUsuario.add(personaJuridicaDTO.codigoOWNER);
            }

            // Equivalencia Codigo usuario - Salesforce Id
            Map<String, Id> usuariosMap = new Map<String,Id>();
            if (setCodigoUsuario.size() > 0 ) {
                for (user user : [SELECT id, alias FROM USER WHERE Alias in :setCodigoUsuario]) {
                    usuariosMap.put(user.alias, user.Id);
                }
            }
            
            // Record Type Id para Account Persona Juridica
            Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(DEV_RT_PERSONA_JURIDICA).getRecordTypeId();

            // Mapeo de Cliente DTO en Account
            Account acc = new Account();
            if (actividadesMap.containsKey(personaJuridicaDTO.Actividad_Economica_External_ID)) {
                acc.ACC_Actividad_Economica__c = actividadesMap.get(personaJuridicaDTO.Actividad_Economica_External_ID);
            }
            if (usuariosMap.containsKey(personaJuridicaDTO.codigoUsuarioCaptador)) {
                acc.ACC_Usuario_Captador__c = usuariosMap.get(personaJuridicaDTO.codigoUsuarioCaptador);
            }
            if (usuariosMap.containsKey(personaJuridicaDTO.codigoOWNER)) {
                acc.OwnerId = usuariosMap.get(personaJuridicaDTO.codigoOWNER);
            }
            if (cuentasMap.containsKey(personaJuridicaDTO.Id_Externo_Cuenta_Parent)) {
                acc.ParentId = cuentasMap.get(personaJuridicaDTO.Id_Externo_Cuenta_Parent);
            }
            
            acc.RecordTypeId = recordTypeId;
            acc.ACC_Id_Externo_Cuenta__c = personaJuridicaDTO.ACC_Id_Externo_Cuenta_c;
            acc.ACC_Coincidencia_Listas_Externas__c = personaJuridicaDTO.ACC_Coincidencia_Listas_Externas_c;
            acc.ACC_Clasificacion_Empresa__c = personaJuridicaDTO.ACC_Clasificacion_Empresa_c;
            acc.ACC_Num_Acuerdo__c = personaJuridicaDTO.ACC_Num_Acuerdo_c;
            acc.ACC_Cliente_Conocido__c = personaJuridicaDTO.ACC_Cliente_Conocido_c;
            acc.ACC_CIF__c = personaJuridicaDTO.ACC_CIF_c;
            acc.ACC_Internet_Banking__c = personaJuridicaDTO.ACC_Internet_Banking_c;
            acc.ACC_Telefono_FATCA__c = personaJuridicaDTO.ACC_Telefono_FATCA_c;
            acc.ACC_Condicion__c = personaJuridicaDTO.ACC_Condicion_c;
            acc.ACC_Categoria_Riesgo_Cliente__c = personaJuridicaDTO.ACC_Categoria_Riesgo_Cliente_c;
            acc.ACC_Tipo_Depositante__c = personaJuridicaDTO.ACC_Tipo_Depositante_c;
            acc.ACC_Objeto_Negocio__c = personaJuridicaDTO.ACC_Objeto_Negocio_c;
            acc.ACC_Tipo_Sector__c = personaJuridicaDTO.ACC_Tipo_Sector_c;
            acc.ACC_Total_Activos__c = personaJuridicaDTO.ACC_Total_Activos_c;
            acc.ACC_Patrimonio_Desc__c = personaJuridicaDTO.ACC_Patrimonio_Desc_c;
            acc.ACC_Tipo_Vinculacion__c = personaJuridicaDTO.ACC_Tipo_Vinculacion_c;
            acc.ACC_Volumen_Ventas_Anual__c = personaJuridicaDTO.ACC_Volumen_Ventas_Anual_c;
            acc.ACC_Tipo_Organizacion__c = personaJuridicaDTO.ACC_Tipo_Organizacion_c;
            acc.ACC_Relacion_Exterior__c = personaJuridicaDTO.ACC_Relacion_Exterior_c;
            acc.ACC_Ultima_Actualizacion_Listas_Internas__c = procesarFecha(personaJuridicaDTO.ACC_Ultima_Actualizacion_Listas_Internas_c);
            acc.BillingCity = personaJuridicaDTO.BillingCity;
            acc.ACC_SubEstado__c = personaJuridicaDTO.ACC_SubEstado_c;
            acc.ACC_RNC__c = personaJuridicaDTO.ACC_RNC_c;
            acc.ACC_Fecha_Informacion__c = procesarFecha(personaJuridicaDTO.ACC_Fecha_Informacion_c);
            acc.ACC_Fuente_Informacion__c = personaJuridicaDTO.ACC_Fuente_Informacion_c;
            acc.ACC_Id_Externo_Cuenta__c = personaJuridicaDTO.ACC_Id_Externo_Cuenta_c;
            acc.ACC_Tipo_Ingreso__c = personaJuridicaDTO.ACC_Tipo_Ingreso_c;
            acc.ACC_Coincidencia_Listas_Internas__c = personaJuridicaDTO.ACC_Coincidencia_Listas_Internas_c;
            acc.ACC_Cuenta_Nomina__c = personaJuridicaDTO.ACC_Cuenta_Nomina_c;
            acc.BillingPostalCode = personaJuridicaDTO.BillingPostalCode;
            acc.ACC_Codigo_Depositante__c = personaJuridicaDTO.ACC_Codigo_Depositante_c;
            acc.ACC_Nacionalidad__c = personaJuridicaDTO.ACC_Nacionalidad_c;
            acc.ACC_Estado__c = personaJuridicaDTO.ACC_Estado_c;
            acc.ACC_Segmento_FATCA__c = personaJuridicaDTO.ACC_Segmento_FATCA_c;
            acc.ACC_Codigo_Postal_FATCA__c = personaJuridicaDTO.ACC_Codigo_Postal_FATCA_c;
            acc.ACC_Puntos_Canjeados__c = personaJuridicaDTO.ACC_Puntos_Canjeados_c;
            acc.ACC_Ultima_Segmentacion__c = procesarFecha(personaJuridicaDTO.ACC_Ultima_Segmentacion_c);
            acc.ACC_Tipo_Actividad__c = personaJuridicaDTO.ACC_Tipo_Actividad_c;
            acc.ACC_NumEmpleados__c = personaJuridicaDTO.ACC_NumEmpleados_c;
            acc.ACC_Nombre_Corto_Comercial__c = personaJuridicaDTO.ACC_Nombre_Corto_Comercial_c;
            acc.ACC_Fecha_Reconversion_Cliente__c = procesarFecha(personaJuridicaDTO.ACC_Fecha_Reconversion_Cliente_c);
            acc.ACC_Patrimonio_Num__c = personaJuridicaDTO.ACC_Patrimonio_Num_c;
            acc.ACC_Fecha_Conversion_Cliente__c = procesarFecha(personaJuridicaDTO.ACC_Fecha_Conversion_Cliente_c);
            acc.ACC_Ciudad_FATCA__c = personaJuridicaDTO.ACC_Ciudad_FATCA_c;
            acc.ACC_Fecha_Cierre_Fiscal__c = procesarFecha(personaJuridicaDTO.ACC_Fecha_Cierre_Fiscal_c);
            acc.BillingState = personaJuridicaDTO.BillingState;
            acc.ACC_Moneda__c = personaJuridicaDTO.ACC_Moneda_c;
            acc.ACC_Puntos_Acumulados__c = personaJuridicaDTO.ACC_Puntos_Acumulados_c;
            acc.ACC_Ejecutivo__c = personaJuridicaDTO.EJECUTIVO_SIEBEL;
            acc.ACC_Posee_Acuerdo_IRS__c = personaJuridicaDTO.ACC_Posee_Acuerdo_IRS_c;
            acc.ACC_Tipo_Cliente_PJ__c = personaJuridicaDTO.ACC_Tipo_Cliente_PJ_c;
            acc.ACC_Listas__c = personaJuridicaDTO.ACC_Listas_c;
            acc.BillingCountry = personaJuridicaDTO.BillingCountry;
            acc.ACC_TipoIdentificacion__c = personaJuridicaDTO.ACC_TipoIdentificacion_c;
            acc.ACC_Tipo_Persona_PJ__c = personaJuridicaDTO.ACC_Tipo_Persona_PJ_c;
            acc.ACC_Puntos_Por_Vencer__c = personaJuridicaDTO.ACC_Puntos_Por_Vencer_c;
            acc.ACC_Fecha_Fundacion__c = procesarFecha(personaJuridicaDTO.ACC_Fecha_Fundacion_c);
            acc.ACC_Tipo_Acuerdo__c = personaJuridicaDTO.ACC_Tipo_Acuerdo_c;
            acc.ACC_Resultado_Validacion__c = personaJuridicaDTO.ACC_Resultado_Validacion_c;
            acc.ACC_Correo_Electronico_Cliente__c = personaJuridicaDTO.ACC_Correo_Electronico_Cliente_c;
            acc.ACC_GIIN__c = personaJuridicaDTO.ACC_GIIN_c;
            acc.Phone = personaJuridicaDTO.Phone;
            acc.ACC_Aplica_FATCA__c = personaJuridicaDTO.ACC_Aplica_FATCA_c;
            acc.ACC_Puntos_Vencidos__c = personaJuridicaDTO.ACC_Puntos_Vencidos_c;
            acc.ACC_Puntos_Generados__c = personaJuridicaDTO.ACC_Puntos_Generados_c;
            acc.ACC_Segmento__c = personaJuridicaDTO.ACC_Segmento_c;
            acc.ACC_Ultima_Actualizacion_Listas_Externas__c = procesarFecha(personaJuridicaDTO.ACC_Ultima_Actualizacion_Listas_Externas_c);
            acc.ACC_Estado_FATCA__c = personaJuridicaDTO.ACC_Estado_FATCA_c;
            acc.BillingStreet = personaJuridicaDTO.BillingStreet;
            acc.ACC_Direccion_FATCA__c = personaJuridicaDTO.ACC_Direccion_FATCA_c;
            // Prevención a nivel de registro de que actualicen valores de campos.
            // Por Validation Rule "VR_Validacion_Cliente_PJ"
            if (!isEmpty(personaJuridicaDTO.Name)) {
                acc.Name = personaJuridicaDTO.Name;                
            }

            return acc;                
        } catch (Exception e) {
            throw e;
        }
    }


    global class PersonaJuridicaDTO{
        public string Actividad_Economica_External_ID;
        public boolean ACC_Aplica_FATCA_c;
        public string ACC_Categoria_Riesgo_Cliente_c;
        public string ACC_CIF_c;
        public string ACC_Ciudad_FATCA_c;
        public string ACC_Clasificacion_Empresa_c;
        public boolean ACC_Cliente_Conocido_c;
        public string ACC_Codigo_Depositante_c;
        public string ACC_Codigo_Postal_FATCA_c;
        public boolean ACC_Coincidencia_Listas_Externas_c;
        public boolean ACC_Coincidencia_Listas_Internas_c;
        public string ACC_Condicion_c;
        public string ACC_Correo_Electronico_Cliente_c;
        public boolean ACC_Cuenta_Nomina_c;
        public string ACC_Direccion_FATCA_c;
        public string EJECUTIVO_SIEBEL;
        public string ACC_Estado_c;
        public string ACC_Estado_FATCA_c;
        public string ACC_Fecha_Cierre_Fiscal_c;
        public string ACC_Fecha_Conversion_Cliente_c;
        public string ACC_Fecha_Fundacion_c;
        public string ACC_Fecha_Informacion_c;
        public string ACC_Fecha_Reconversion_Cliente_c;
        public string ACC_Fuente_Informacion_c;
        public string ACC_GIIN_c;
        public string ACC_Id_Externo_Cuenta_c;
        public boolean ACC_Internet_Banking_c;
        public string ACC_Listas_c;
        public string ACC_Moneda_c;
        public string ACC_Nacionalidad_c;
        public string ACC_Nombre_Corto_Comercial_c;
        public string ACC_Num_Acuerdo_c;
        public decimal ACC_NumEmpleados_c;
        public string ACC_Objeto_Negocio_c;
        public string ACC_Patrimonio_Desc_c;
        public decimal ACC_Patrimonio_Num_c;
        public boolean ACC_Posee_Acuerdo_IRS_c;
        public decimal ACC_Puntos_Acumulados_c;
        public decimal ACC_Puntos_Canjeados_c;
        public decimal ACC_Puntos_Generados_c;
        public decimal ACC_Puntos_Por_Vencer_c;
        public decimal ACC_Puntos_Vencidos_c;
        public string ACC_Relacion_Exterior_c;
        public string ACC_Resultado_Validacion_c;
        public string ACC_RNC_c;
        public string ACC_Segmento_c;
        public string ACC_Segmento_FATCA_c;
        public string ACC_SubEstado_c;
        public string ACC_Telefono_FATCA_c;
        public string ACC_Tipo_Actividad_c;
        public string ACC_Tipo_Acuerdo_c;
        public string ACC_Tipo_Cliente_PJ_c;
        public string ACC_Tipo_Depositante_c;
        public string ACC_Tipo_Ingreso_c;
        public string ACC_Tipo_Organizacion_c;
        public string ACC_Tipo_Persona_PJ_c;
        public string ACC_Tipo_Sector_c;
        public string ACC_Tipo_Vinculacion_c;
        public string ACC_TipoIdentificacion_c;
        public decimal ACC_Total_Activos_c;
        public string ACC_Ultima_Actualizacion_Listas_Externas_c;
        public string ACC_Ultima_Actualizacion_Listas_Internas_c;
        public string ACC_Ultima_Segmentacion_c;
        public string codigoUsuarioCaptador;
        public decimal ACC_Volumen_Ventas_Anual_c;
        public string BillingCity;
        public string BillingCountry;
        public string BillingPostalCode;
        public string BillingState;
        public string BillingStreet;
        public string Name;
        public string codigoOWNER;
        public string Id_Externo_Cuenta_Parent;
        public string Phone;
        public string RecordTypeId;
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