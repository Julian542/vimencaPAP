/**
 * @description       : Expone servicio para crear o actualizar Vias de contacto de Clientes
 * @author            : Luis Naranjo Pastrana
 * 
 * Historial de cambios
 * Fecha            Desarrollador           Detalle 
 * 26-05-2023       Luis Naranjo            Se añade Response al log
 *
 */
//@RestResource(urlMapping='/vias-de-contacto/upsert/')
global class REST_ViasDeContacto {
    
    /*private static final Map<Integer,String> RES_STATUS= new Map<Integer,String>{200=>'Success', 202=>'Partial Success', 404=>'Not found', 500=>'Error Internal Server'};
                
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
            ViaDTO[] viasDTOList = (ViaDTO[]) JSON.deserialize(reqBody, ViaDTO[].class);
            
            // Se filtran los Identificadores Externos de los clientes
            Set<String> accCIFSet = new Set<String>();
            for (ViaDTO viaDTO : viasDTOList) {
                if(!String.isBlank(viaDTO.ACC_CIF_c)){     
                    accCIFSet.add(viaDTO.ACC_CIF_c);
                }
            }
            
            // Se consultan los ID de los clientes a partir de los Identificadores Externos
            Map<String, Id> accounts = new Map<String,Id>();            
            for(Account acc : [SELECT Id, ACC_CIF__c FROM Account WHERE ACC_CIF__c IN : accCIFSet]){
                accounts.put(acc.ACC_CIF__c, acc.id);
            }
            
            // Se valida consulta de los clientes, de esta depende la creación o actualización de una Vía de contacto
            if(accounts.isEmpty()){
                resWrapper.errors.add('Error Code: NINGUNO DE LOS CIF EXISTE. Fields: (ACC_CIF__c). Message: NINGUNO DE LOS CIF EXISTE');
                resContext.statusCode = 404;
            }else if(accounts.size() != accCIFSet.size()){
                resWrapper.errors.add('Error Code: UNO O ALGUNOS DE LOS CIF NO EXISTE. Fields: (ACC_CIF__c). Message: UNO O ALGUNOS DE LOS CIF NO EXISTE');
            }
            
            // Se realiza el mapeo de la información recibida en el objeto correspondiente en Salesforce
            Vias_de_Contacto__c[] viasToUpsert = new List<Vias_de_Contacto__c>();
            for (ViaDTO viaDTO : viasDTOList) {
                if(accounts.containsKey(viaDTO.ACC_CIF_c)){
                    Vias_de_Contacto__c via = new Vias_de_Contacto__c();
                    via.VIA_Account__c = accounts.get(viaDTO.ACC_CIF_c);
                    via.VIA_de_Contacto__c = viaDTO.VIA_de_Contacto_c;
                    via.VIA_Envio_SMS__c = viaDTO.VIA_Envio_SMS_c;
                    via.VIA_Id_Externo_Via__c = viaDTO.VIA_Id_Externo_Via_c;
                    via.VIA_Identificador__c = viaDTO.VIA_Identificador_c;
                    via.VIA_Numero_Correo__c = viaDTO.VIA_Numero_Correo_c;
                    via.VIA_Principal__c = viaDTO.VIA_Principal_c;
                    via.VIA_Telefonica__c = viaDTO.VIA_Telefonica_c;
                    viasToUpsert.add(via);   
                }
            }
            
            // Se guarda la información mapeada
            Schema.SObjectField externalField = Vias_de_Contacto__c.Fields.VIA_Id_Externo_Via__c;
            Database.UpsertResult[] urListaVia = Database.upsert(viasToUpsert, externalField, false);
            for (Database.UpsertResult ur : urListaVia) {
                if (!ur.isSuccess()) {
                    for(Database.Error err : ur.getErrors()) {
                        resWrapper.errors.add('Error Code: '+err.getStatusCode()+'. Fields: '+err.getFields()+'.Message: '+err.getMessage());
                    }
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
            
            INTLogger.INTLoggerResult result = INTLogger.logCallout('Vias de contacto', 'REST_ViasDeContacto.doPut', httpRequest, httpResponse);
        }       
    }
    
    global class ViaDTO{
        public string ACC_CIF_c;
        public string VIA_de_Contacto_c;
        public boolean VIA_Envio_SMS_c;
        public string VIA_Id_Externo_Via_c;
        public string VIA_Identificador_c;
        public string VIA_Numero_Correo_c;
        public boolean VIA_Principal_c;
        public string VIA_Telefonica_c;
    }
    
    global class ResponseWrapper{
        String message;
        List<String> errors;
        
        global ResponseWrapper(){
            this.errors= new List<String>();
        }
    }*/
}