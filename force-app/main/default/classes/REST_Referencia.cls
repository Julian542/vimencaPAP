/**
 * @description       : Expone servicio para crear o actualizar Referencias
 * @author            : Luis Naranjo Pastrana
 * 
 * Historial de cambios
 * Fecha            Desarrollador           Detalle 
 * 26-05-2023       Luis Naranjo            Se añade Response al log
 *
 */
//@RestResource(urlMapping='/referencia/upsert/')
global class REST_Referencia {

    /*private static final Map<Integer,String> RES_STATUS= new Map<Integer,String>{200=>'Success', 202=>'Partial Success', 404=>'Not found', 500=>'Error Internal Server'};
    private static final string DEV_RT_PERSONAL = 'Personal';
    private static final string DEV_RT_COMERCIAL = 'Comercial';
    private static final string DEV_RT_BANCARIA = 'Bancaria';
    private static  RecordType recordTypeId;

    @HttpPut
    global static void doPut(){

        ResponseWrapper resWrapper = new ResponseWrapper();
        RestRequest reqContext = RestContext.request;
        RestResponse resContext = RestContext.response;
        HttpRequest httpRequest = new HttpRequest();
        HttpResponse httpResponse = new HttpResponse();

        String reqBody = reqContext.requestBody.toString();        

        try{
            ReferenciaDTO[] referenciaDTOList = (ReferenciaDTO[])JSON.deserialize(reqBody, ReferenciaDTO[].class);

           
            Set<String> accCIFSet = new Set<String>();
            for (ReferenciaDTO reDTO : referenciaDTOList) {
                if(!String.isBlank(reDTO.ACC_CIF_c)){     
                    accCIFSet.add(reDTO.ACC_CIF_c);
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

            List<Referencia__c> referenciaToUpsert = new List<Referencia__c>();
            for (referenciaDTO refDTO : referenciaDTOList) {
                if(accounts.containsKey(refDTO.ACC_CIF_c)){
                    if (DEV_RT_PERSONAL == refDTO.REF_Tipo_c) {
                        recordTypeId = [SELECT id FROM RecordType WHERE Name = :DEV_RT_PERSONAL];
                        //Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(DEV_RT_PERSONAL).getRecordTypeId();
                    }else if (DEV_RT_COMERCIAL == refDTO.REF_Tipo_c) {
                        recordTypeId = [SELECT id FROM RecordType WHERE Name = :DEV_RT_COMERCIAL];
                        //Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(DEV_RT_COMERCIAL).getRecordTypeId();
                    }else if (DEV_RT_BANCARIA == refDTO.REF_Tipo_c) {
                        recordTypeId =  [SELECT id FROM RecordType WHERE Name = :DEV_RT_BANCARIA];
                        //Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(DEV_RT_BANCARIA).getRecordTypeId();
                    }
                    Referencia__c ref = new Referencia__c();
                    ref.RecordTypeId = (String)recordTypeId.Id;
                    ref.Account__c = accounts.get(refDTO.ACC_CIF_c);
                    ref.Banco__c = refDTO.Banco_c;
                    ref.REF_Direccion__c = refDTO.REF_Direccion_c;
                    ref.REF_Id_Externo__c = refDTO.REF_Id_Externo_c;
                    ref.Moneda__c = refDTO.Moneda_c;
                    ref.REF_Nombre__c = refDTO.REF_Nombre_c;
                    ref.N_de_cuenta__c = refDTO.N_De_Cuenta_c;
                    ref.Pais__c = refDTO.Pais_c;
                    ref.REF_Telefono__c = refDTO.REF_Telefono_c;
                    ref.REF_Tipo__c = refDTO.REF_Tipo_c;
                    ref.Tipo_de_cuenta__c = refDTO.Tipo_de_Cuenta_c;
                    referenciaToUpsert.add(ref);
                }
            }

            Schema.SObjectField externalField = Referencia__c.Fields.REF_Id_Externo__c;
            Database.UpsertResult[] urReferencia = Database.upsert(referenciaToUpsert, externalField, false);
            for (Database.UpsertResult ur : urReferencia) {
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

            INTLogger.INTLoggerResult result = INTLogger.logCallout('Referencia', 'REST_Referencia.doPut', httpRequest, httpResponse);
        }   
    }*/

    global class ReferenciaDTO{
        public string ACC_CIF_c;
        public string REF_Id_Externo_c;
        public string Account_c;
        public string REF_Tipo_c;
        public string REF_Nombre_c;
        public string REF_Telefono_c;
        public string REF_Direccion_c;
        public string Pais_c;
        public string Banco_c;
        public string Tipo_de_Cuenta_c;
        public string Moneda_c;
        public string N_De_Cuenta_c;
        public string RecordTypeId;
    }

    global class ResponseWrapper{
        String message;
        List<String> errors;
        
        global ResponseWrapper(){
            this.errors= new List<String>();
        }
    }
}