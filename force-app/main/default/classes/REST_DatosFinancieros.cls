/**
 * @description       : Expone servicio para crear o actualizar Datos Financieros
 * @author            : Felix Emmanuel Infante Ramirez
 * 
 * Historial de cambios
 * 
 * Fecha            Desarrollador           Detalle 
 * 26-05-2023       Luis Naranjo            Se añade Response al log
 *
 */

//@RestResource(urlMapping='/datos-financieros/upsert/')
global  class REST_DatosFinancieros {
    /*private static final Map<Integer,String> RES_STATUS= new Map<Integer,String>{200=>'Success', 202=>'Partial Success', 404=>'Not found', 500=>'Error Internal Server'};

    @HttpPut
    global static void doPut(){

        ResponseWrapper resWrapper = new ResponseWrapper();
        RestRequest reqContext = RestContext.request;
        RestResponse resContext = RestContext.response;
        HttpRequest httpRequest = new HttpRequest();
        HttpResponse httpResponse = new HttpResponse();

        String reqBody = reqContext.requestBody.toString();

        try {
            DatosFinanDTO[]  DatosFinanDTOList = (DatosFinanDTO[]) JSON.deserialize(reqBody, DatosFinanDTO[].class);

            Set<String> accCIFSet = new Set<String>();
            for (DatosFinanDTO DatosFinanDTO : DatosFinanDTOList) {
                if(!String.isBlank(DatosFinanDTO.ACC_CIF_c)){     
                    accCIFSet.add(DatosFinanDTO.ACC_CIF_c);
                }
            }

            Map<String, Id> accounts = new Map<String,Id>();            
            for(Account acc : [SELECT Id, ACC_CIF__c FROM Account WHERE ACC_CIF__c IN : accCIFSet]){
                accounts.put(acc.ACC_CIF__c, acc.id);
            }

            if(accounts.isEmpty()){
                resWrapper.errors.add('Error Code: NINGUNO DE LOS CIF EXISTE. Fields: (ACC_CIF__c). Message: NINGUNO DE LOS CIF EXISTE');
                resContext.statusCode = 404;
            }else if(accounts.size() != accCIFSet.size()){
                resWrapper.errors.add('Error Code: UNO O ALGUNOS DE LOS CIF NO EXISTE. Fields: (ACC_CIF__c). Message: UNO O ALGUNOS DE LOS CIF NO EXISTE');
            }

            List<Informacion_Financiera__c> DatosFinanToUpsert = new List<Informacion_Financiera__c>();
            for (DatosFinanDTO DatoFinanDTO : DatosFinanDTOList) {
                if(accounts.containsKey(DatoFinanDTO.ACC_CIF_c)){
                    Informacion_Financiera__c info = new Informacion_Financiera__c();
                    info.INF_Cuenta__c = accounts.get(DatoFinanDTO.ACC_CIF_c);
                    info.INF_Periodo__c = DatoFinanDTO.INF_Periodo_c;
                    info.INF_Ingresos__c = DatoFinanDTO.INF_Ingresos_c;
                    info.INF_Fuente_de_ingresos__c = DatoFinanDTO.INF_Fuente_De_Ingresos_c;
                    info.INF_Id_Externo_Inf__c =  DatoFinanDTO.INF_Id_Externo_Inf_c;
                    DatosFinanToUpsert.add(info);   
                }
            }

            Schema.SObjectField externalField = Informacion_Financiera__c.Fields.INF_Id_Externo_Inf__c;
            Database.UpsertResult[] urListaDatoFinan = Database.upsert(DatosFinanToUpsert, externalField, false);
            for (Database.UpsertResult ur : urListaDatoFinan) {
                if (!ur.isSuccess()) {
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

            INTLogger.INTLoggerResult result = INTLogger.logCallout('Informacion Financiera', 'REST_DatosFinancieros.doPut', httpRequest, httpResponse);
        }
    }

    global class DatosFinanDTO{
        public string ACC_CIF_c;
        public string INF_Id_Externo_Inf_c;
        public string INF_Cuenta_c;
        public string INF_Fuente_De_Ingresos_c;
        public string INF_Ingresos_c;
        public string INF_Periodo_c;
    }

    global class ResponseWrapper{
        String message;
        List<String> errors;
        
        global ResponseWrapper(){
            this.errors= new List<String>();
        }
    }*/
    
}