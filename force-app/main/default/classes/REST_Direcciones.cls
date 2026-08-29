/**
 * @description       : Expone servicio para crear o actualizar Direcciones
 * @author            : Felix Emmanuel Infante Ramirez
 * 
 * Historial de cambios
 * 
 * Fecha            Desarrollador           Detalle 
 * 26-05-2023       Luis Naranjo            Se añade Response al log
 *
 */
//@RestResource(urlMapping='/direcciones/upsert/')
global class REST_Direcciones {

    /*private static Set<String> successSet = new Set<String>();
    private static final Map<Integer,String> RES_STATUS= new Map<Integer,String>{200=>'Success', 202=>'Partial Success', 404=>'Not found', 500=>'Error Internal Server'};

    @HttpPut
    global static void doPut(){

        ResponseWrapper resWrapper = new ResponseWrapper();
        RestRequest reqContext = RestContext.request;
        RestResponse resContext = RestContext.response;
        HttpRequest httpRequest = new HttpRequest();
        HttpResponse httpResponse = new HttpResponse();

        String reqBody = reqContext.requestBody.toString();

        try {
            
            DireccionesDTO[]  DireccionesDTOList = (DireccionesDTO[]) JSON.deserialize(reqBody, DireccionesDTO[].class);

            Set<String> accCIFSet = new Set<String>();
            for (DireccionesDTO DireccionDTO : DireccionesDTOList) {
                if(!String.isBlank(DireccionDTO.ACC_CIF_c)){     
                    accCIFSet.add(DireccionDTO.ACC_CIF_c);
                }
            }
            Set<String> DatMasterSet = new Set<String>();
            for (DireccionesDTO DireccionDTO : DireccionesDTOList) {
                if(!String.isBlank(DireccionDTO.DIR_Sector_c)){     
                    DatMasterSet.add(DireccionDTO.DIR_Sector_c);
                }
            }

            Map<String, Id> accounts = new Map<String,Id>();            
            for(Account acc : [SELECT Id, ACC_CIF__c FROM Account WHERE ACC_CIF__c IN : accCIFSet]){
                accounts.put(acc.ACC_CIF__c, acc.id);
            }

            Map<String, Id> DatoMaestro = new Map<String,Id>();            
            for(Datos_Maestros__c DTM : [SELECT Id,Name , DM_Direccion__c  FROM Datos_Maestros__c WHERE DM_Direccion__c IN : DatMasterSet]){
                DatoMaestro.put(DTM.DM_Direccion__c, DTM.id);
            }

            if(accounts.isEmpty()){
                resWrapper.errors.add('Error Code: NINGUNO DE LOS CIF EXISTE. Fields: (ACC_CIF__c). Message: NINGUNO DE LOS CIF EXISTE');
                resContext.statusCode = 404;
            }else if(accounts.size() != accCIFSet.size()){
                resWrapper.errors.add('Error Code: UNO O ALGUNOS DE LOS CIF NO EXISTE. Fields: (ACC_CIF__c). Message: UNO O ALGUNOS DE LOS CIF NO EXISTE');
            }

            List<Direccion__c> DireccionesToUpsert = new List<Direccion__c>();
            for (DireccionesDTO DirDTO : DireccionesDTOList) {
                if(accounts.containsKey(DirDTO.ACC_CIF_c)){
                    Direccion__c dir = new Direccion__c();
                    dir.DIR_Account__c = accounts.get(DirDTO.ACC_CIF_c);
                    dir.DIR_Apartado_postal__c =DirDTO.DIR_Apartado_Postal_c;
                    dir.DIR_Calle__c = DirDTO.DIR_Calle_c;
                    dir.DIR_Direccion_SIEBEL__c = DirDTO.DIR_Direccion_siebel_c;
                    dir.DIR_Distrito__c = DirDTO.DIR_Distrito_c;
                    dir.DIR_Edificio__c = DirDTO.DIR_Edificio_c;
                    dir.DIR_Estado_Ciudad__c = DirDTO.DIR_Estado_Ciudad_c;
                    dir.DIR_Extension__c = DirDTO.DIR_Extension_c;
                    dir.DIR_Id_Externo_Direccion__c = DirDTO.DIR_Id_Externo_c;
                    dir.DIR_Identificador__c =  DirDTO.DIR_Identificador_c;
                    dir.DIR_Numero__c = DirDTO.DIR_Numero_c;
                    dir.DIR_N_Apartamento__c = DirDTO.DIR_N_Apartamento_c;
                    dir.DIR_N_Telefono__c = DirDTO.DIR_N_Telefono_c;
                    dir.DIR_Pais__c = DirDTO.DIR_Pais_c;
                    dir.DIR_Provincia__c = DirDTO.DIR_Provincia_c;
                    dir.DIR_Referencia_Ubicacion__c = DirDTO.DIR_Referencia_ubicacion_c;
                    dir.DIR_Sector__c = DatoMaestro.get(DirDTO.DIR_Sector_c);
                    dir.DIR_Telef_Adicional__c = DirDTO.DIR_Telef_Adicional_c;
                    dir.DIR_Telefono_adicional__c = DirDTO.DIR_Telefono_adicional_c;
                    dir.DIR_Tipo_Direccion__c = DirDTO.DIR_Tipo_Direccion_c;
                    dir.DIR_Municipio__c = DirDTO.DIR_Municipio_c;
                    dir.DIR_Principal__c = DirDTO.DIR_Principal_c;
                    DireccionesToUpsert.add(dir);
                }
            }
            Schema.SObjectField externalField = Direccion__c.Fields.DIR_Id_Externo_Direccion__c;//DIR_Account__c;
            Database.UpsertResult[] urListaDireccion = Database.upsert(DireccionesToUpsert, externalField, false);
            for (Database.UpsertResult ur : urListaDireccion) {
                if (ur.isSuccess()) {
                    successSet.add(ur.getId());
                }else {
                    for(Database.Error err : ur.getErrors()) {
                        resWrapper.errors.add('Error Code: '+err.getStatusCode()+'. Fields: '+err.getFields()+'.Message: '+err.getMessage());
                    }
                }
            }
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

            INTLogger.INTLoggerResult result = INTLogger.logCallout('Direccion', 'REST_Direcciones.doPut', httpRequest, httpResponse);
        }
    }
    
    
    global class DireccionesDTO{
        public string ACC_CIF_c;
        public boolean DIR_Principal_c;
        public string DIR_Identificador_c;
        public string DIR_Id_Externo_c;
        public string DIR_Account_c;
        public string DIR_Tipo_Direccion_c;
        public string DIR_Calle_c;
        public string DIR_Numero_c;
        public string DIR_Edificio_c;
        public string DIR_N_Apartamento_c;
        public string DIR_Pais_c;
        public string DIR_Provincia_c;
        public string DIR_Municipio_c;
        public string DIR_Distrito_c;
        public string DIR_Sector_c;
        public string DIR_Apartado_Postal_c;
        public string DIR_Estado_Ciudad_c;
        public string DIR_Referencia_ubicacion_c;
        public string DIR_N_Telefono_c;
        public string DIR_Extension_c;
        public string DIR_Telefono_adicional_c;
        public string DIR_Telef_Adicional_c;
        public string DIR_Direccion_siebel_c;
    }

    global class ResponseWrapper{
        String message;
        List<String> errors;
        
        global ResponseWrapper(){
            this.errors= new List<String>();
        }
    }*/
}