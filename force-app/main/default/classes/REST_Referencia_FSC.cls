/**
 * @description       : an adapted version of REST_Referencia to FinServ Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 14-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@RestResource(urlMapping='/referencia/upsert/')
global with sharing class REST_Referencia_FSC {

    private static final Map<Integer,String> RES_STATUS = UtilVariables.RES_STATUS;
    private static final string DEV_RT_PERSONAL         = UtilVariables.DEV_RT_PERSONAL;
    private static final string DEV_RT_COMERCIAL        = UtilVariables.DEV_RT_COMERCIAL;
    private static final string DEV_RT_BANCARIA         = UtilVariables.DEV_RT_BANCARIA;
    private static Id persRecTypeId  = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('IndustriesIndividual').getRecordTypeId();
    private static Id businessRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('IndustriesBusiness').getRecordTypeId();
    private static Id recordTypeId;

    @HttpPut
    global static void doPut(){

        ResponseWrapper resWrapper  = new ResponseWrapper();
        RestRequest reqContext      = RestContext.request;
        RestResponse resContext     = RestContext.response;
        HttpRequest httpRequest     = new HttpRequest();
        HttpResponse httpResponse   = new HttpResponse();

        String reqBody = reqContext.requestBody.toString();

        try{
            ReferenciaDTO[] referenciaDTOList = (ReferenciaDTO[])JSON.deserialize(reqBody, ReferenciaDTO[].class);
            Set<String> refNames = new Set<String>();
            Set<String> accCIFSet = new Set<String>();
            for (ReferenciaDTO reDTO : referenciaDTOList) {
                if(!String.isBlank(reDTO.ACC_CIF_c)){
                    accCIFSet.add(reDTO.ACC_CIF_c);
                    refNames.add(reDTO.REF_Nombre_c);
                }
            }

            Map<String, Contact> contactos = new Map<String,Contact>();
            for(Contact con : [SELECT Id, Account.ACC_CIF__c FROM Contact WHERE Account.ACC_CIF__c IN : accCIFSet]){
                contactos.put(con.Account.ACC_CIF__c, con);
                System.debug('**** con.Account.ACC_CIF__c '+con.Account.ACC_CIF__c);
            }

            if(contactos.isEmpty()){
                resWrapper.errors.add('Error Code: NINGUNO DE LOS CIF EXISTE. Fields: (ACC_CIF__c). Message: NINGUNO DE LOS CIF EXISTE');
                resContext.statusCode = 404;
            }else if(contactos.size() != accCIFSet.size()){
                resWrapper.errors.add('Error Code: UNO O ALGUNOS DE LOS CIF NO EXISTE. Fields: (ACC_CIF__c). Message: UNO O ALGUNOS DE LOS CIF NO EXISTE');
            }
            Contact thisContact;
            List<FinServ__ContactContactRelation__c> referenciaToUpsert = new List<FinServ__ContactContactRelation__c>();

            for (referenciaDTO refDTO : referenciaDTOList) {
                if(contactos.containsKey(refDTO.ACC_CIF_c)){
                    thisContact = contactos.get(refDTO.ACC_CIF_c);
                }
            }
            List<Contact> existentReferals = [SELECT Id, Name, LastName FROM Contact WHERE LastName IN :refNames];
            
            Map<String,String> refMap = new Map<String,String>();

            if(!existentReferals.isEmpty()){
                for(Contact con :existentReferals){
                    refMap.put(con.Name, con.Id);
                }
            }
			
            List<Contact> contactsToCreate = new List<Contact>();

            for (referenciaDTO refDTO : referenciaDTOList) {
                if( !refMap.containsKey(refDTO.REF_Nombre_c) ){ //If the referral does not exist as an account, we need to create it
                    //En vez de cuenta, crear un contacto (referencia) relacionado a la cuenta del cliente
                    //contacto mi cliente
                    //contacto relacionado la referencia. Debe ser huerfano
					
                    Contact con = new Contact();
                    con.LastName                        = refDTO.REF_Nombre_c;
                    con.FinServ__CountryOfResidence__c  = refDTO.Pais_c;
                    con.Phone                           = refDTO.REF_Telefono_c;

                    if (DEV_RT_PERSONAL.capitalize() == refDTO.REF_Tipo_c) {
                        recordTypeId        = persRecTypeId;
                    }else if (DEV_RT_COMERCIAL.capitalize() == refDTO.REF_Tipo_c || DEV_RT_BANCARIA.capitalize() == refDTO.REF_Tipo_c) {
                        recordTypeId        = businessRecTypeId;
                    }
                    con.MailingStreet   = refDTO.REF_Direccion_c;
                    con.RecordTypeId    = recordTypeId;

                    contactsToCreate.add(con);
                    refMap.put(con.Name, con.Id);
                }
            }
			
            Database.UpsertResult[] contsRes = Database.upsert(contactsToCreate, false);
			
            for (Database.UpsertResult ur : contsRes) {
                if (!ur.isSuccess()) {
                    for(Database.Error err : ur.getErrors()) {
                        resWrapper.errors.add('Error Code: '+err.getStatusCode()+'. Fields: '+err.getFields()+'.Message: '+err.getMessage());
                    }
                }
            }

            
            //FinServ__ReciprocalRole__c rr = [SELECT Id FROM FinServ__ReciprocalRole__c WHERE Name = 'Sin Asignar' LIMIT 1];
            FinServ__ReciprocalRole__c rr;
            List<FinServ__ReciprocalRole__c> rrList = [
                SELECT Id 
                FROM FinServ__ReciprocalRole__c 
                ORDER BY CreatedDate ASC 
                LIMIT 1
            ];
            
            if(!rrList.isEmpty()){
                rr = rrList[0];
            }
            
            String referidoId;
            for (referenciaDTO refDTO : referenciaDTOList) {
                if(contactos.containsKey(refDTO.ACC_CIF_c)){
                    thisContact = contactos.get(refDTO.ACC_CIF_c);
                    referidoId  = refMap.get(refDTO.REF_Nombre_c);

                    // ex Referencia__c
                    FinServ__ContactContactRelation__c ref = new FinServ__ContactContactRelation__c();
                    System.debug('**** thisContact '+thisContact);

                    System.debug('**** thisContact.Id '+thisContact.Id);
                    if(thisContact != null){
                        ref.FinServ__Contact__c         = thisContact.Id;
                        ref.CCR_Banco__c                = refDTO.Banco_c;
                        ref.FinServ__ExternalId__c      = refDTO.REF_Id_Externo_c;
                        //ref.Moneda__c                   = refDTO.Moneda_c;
                        ref.CCR_Moneda__c                   = refDTO.Moneda_c;
                        
                        if(rr != null)
                        	ref.FinServ__Role__c            = rr.Id;
                        

                        ref.FinServ__RelatedContact__c  = referidoId;
                        //Aca hay que crear un contacto/cuenta y relacionarlo
                        ref.CCR_N_de_cuenta__c          = refDTO.N_De_Cuenta_c;
                        ref.CCR_Tipo__c                 = refDTO.REF_Tipo_c;
                        ref.CCR_Tipo_de_cuenta__c       = refDTO.Tipo_de_Cuenta_c;
                        referenciaToUpsert.add(ref);
                    }
                }
            }
			
            Schema.SObjectField externalField    = FinServ__ContactContactRelation__c.Fields.FinServ__ExternalId__c;
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
                System.debug(LoggingLevel.ERROR, '=> ' + resWrapper.errors);
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

            INTLogger.INTLoggerResult result = INTLogger.logCallout('Referencia', 'REST_Referencia_FSC.doPut', httpRequest, httpResponse);
        }
    }

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