/**
 * @description       : an adapted version of REST_Direcciones to FinServ Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 14-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@RestResource(urlMapping='/direcciones/upsert/')
global with sharing class REST_Direcciones_FSC {

    private static Set<String> successSet = new Set<String>();
    private static final Map<Integer,String> RES_STATUS = UtilVariables.RES_STATUS;

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
            Set<String> telefonosSet = new Set<String>();
            Set<String> accCIFSet = new Set<String>();
            for (DireccionesDTO DireccionDTO : DireccionesDTOList) {
                if(!String.isBlank(DireccionDTO.ACC_CIF_c)){
                    accCIFSet.add(DireccionDTO.ACC_CIF_c);
                }
                System.debug('*** DireccionDTO.DIR_N_Telefono_c '+DireccionDTO.DIR_N_Telefono_c );
                if(DireccionDTO.DIR_N_Telefono_c != ''){
                    telefonosSet.add(DireccionDTO.DIR_N_Telefono_c);
                }
                System.debug('*** DireccionDTO.DIR_Telef_Adicional_c '+DireccionDTO.DIR_Telef_Adicional_c );
                if(DireccionDTO.DIR_Telef_Adicional_c != ''){
                    telefonosSet.add(DireccionDTO.DIR_Telef_Adicional_c);
                }
                System.debug('*** telefonosSet '+telefonosSet );
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

            Map<String, String> telefonos = new Map<String,String>();
            for(ContactPointPhone tlfn : [SELECT Id, ExternalId__c, TelephoneNumber FROM ContactPointPhone WHERE TelephoneNumber IN : telefonosSet]){
                telefonos.put(tlfn.TelephoneNumber, tlfn.ExternalId__c);
            }
            System.debug('*** telefonos '+telefonos );

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

            List<ContactPointPhone> phoneListToUpsert = new List<ContactPointPhone>();
            for (DireccionesDTO DirDTO : DireccionesDTOList) {

                ContactPointPhone tlf = new ContactPointPhone();
                tlf.ParentId          = accounts.get(DirDTO.ACC_CIF_c);
                tlf.ExtensionNumber   = DirDTO.DIR_Extension_c;
                tlf.ExternalId__c     = UserInfo.getUserId().left(5) + '-' + DateTime.now().getTime() + Integer.valueOf(Math.random() * 21);
                tlf.TelephoneNumber   = DirDTO.DIR_N_Telefono_c;

                if(telefonos.containsKey(DirDTO.DIR_N_Telefono_c)){
                    tlf.ExternalId__c = telefonos.get(DirDTO.DIR_N_Telefono_c);
                }
                System.debug('*** tlf.ExternalId__c '+tlf.ExternalId__c );

                System.debug('*** DirDTO.DIR_N_Telefono_c '+DirDTO.DIR_N_Telefono_c);
                System.debug('*** tlf '+tlf.TelephoneNumber );
                phoneListToUpsert.add(tlf);

                ContactPointPhone tlfad = new ContactPointPhone();
                tlfad.ParentId          = accounts.get(DirDTO.ACC_CIF_c);
                tlfad.ExtensionNumber   = DirDTO.DIR_Extension_c;
                tlfad.TelephoneNumber   = DirDTO.DIR_Telef_Adicional_c;
                tlfad.ExternalId__c     = UserInfo.getUserId().left(5) + '-' + DateTime.now().getTime() + Integer.valueOf(Math.random() * 21);

                if(telefonos.containsKey(DirDTO.DIR_Telef_Adicional_c)){
                    System.debug('*** DirDTO.DIR_Telef_Adicional_c '+DirDTO.DIR_Telef_Adicional_c);
                    tlfad.TelephoneNumber   = telefonos.get(DirDTO.DIR_Telef_Adicional_c);
                    System.debug('*** tlfad '+tlfad.TelephoneNumber );
                    System.debug('*** tlfad.ExternalId__c '+tlfad.ExternalId__c );
                }
                phoneListToUpsert.add(tlfad);
            }

             //Anotarlo en la tabla para la migracion de datos
            Schema.SObjectField externalPhoneField = ContactPointPhone.Fields.ExternalId__c;
            Database.UpsertResult[] urListaTelefonos = Database.upsert(phoneListToUpsert, externalPhoneField, false);
            for (Database.UpsertResult ur : urListaTelefonos) {
                if (ur.isSuccess()) {
                    successSet.add(ur.getId());
                }else {
                    for(Database.Error err : ur.getErrors()) {
                        resWrapper.errors.add('Error Code: '+err.getStatusCode()+'. Fields: '+err.getFields()+'.Message: '+err.getMessage());
                        System.debug('Error Code: '+err.getStatusCode()+'. Fields: '+err.getFields()+'.Message: '+err.getMessage());
                    }
                }
            }

            List<ContactPointAddress> DireccionesToUpsert = new List<ContactPointAddress>();
            for (DireccionesDTO DirDTO : DireccionesDTOList) {
                if(accounts.containsKey(DirDTO.ACC_CIF_c)){
                    String direc = DirDTO.DIR_Calle_c + ' ' + DirDTO.DIR_Numero_c + ' '  + DirDTO.DIR_Edificio_c + ', ' + DirDTO.DIR_Municipio_c;
                    ContactPointAddress dir         = new ContactPointAddress();
                    dir.Name                        = direc;
                    dir.ParentId                    = accounts.get(DirDTO.ACC_CIF_c);
                    dir.postalCode                  = DirDTO.DIR_Apartado_Postal_c;
                    dir.Street                      = direc;
                    dir.CPA_Distrito__c             = DirDTO.DIR_Distrito_c;
                    dir.City                        = DirDTO.DIR_Estado_Ciudad_c;
                    dir.CPA_N_Apartamento__c        = DirDTO.DIR_N_Apartamento_c;
                    dir.Country                     = DirDTO.DIR_Pais_c;
                    dir.State                       = DirDTO.DIR_Provincia_c;
                    dir.CPA_Referencia_Ubicacion__c = DirDTO.DIR_Referencia_ubicacion_c;
                    dir.CPA_Sector__c                   = DatoMaestro.get(DirDTO.DIR_Sector_c);
                    dir.AddressType                 = DirDTO.DIR_Tipo_Direccion_c;
                    dir.isPrimary                   = DirDTO.DIR_Principal_c;
                    dir.CPA_ExternalId__c               = UserInfo.getUserId().left(5) + '-' + DateTime.now().getTime();
                    DireccionesToUpsert.add(dir);
                }
            }
            // Invalid field for upsert, must be an External Id custom or standard indexed field
            //Anotarlo en la tabla para la migracion de datos
            Schema.SObjectField externalField = ContactPointAddress.Fields.CPA_ExternalId__c;
            Database.UpsertResult[] urListaDireccion = Database.upsert(DireccionesToUpsert, externalField, false);
            for (Database.UpsertResult ur : urListaDireccion) {
                if (ur.isSuccess()) {
                    successSet.add(ur.getId());
                }else {
                    for(Database.Error err : ur.getErrors()) {
                        resWrapper.errors.add('Error Code: '+err.getStatusCode()+'. Fields: '+err.getFields()+'.Message: '+err.getMessage());
                        System.debug('Error Code: '+err.getStatusCode()+'. Fields: '+err.getFields()+'.Message: '+err.getMessage());
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

            resWrapper.message      = RES_STATUS.get(resContext.StatusCode);
            resContext.responseBody = Blob.valueOf(JSON.serialize(resWrapper));

            // Registro del Log
            httpResponse.setBody(JSON.serialize(resWrapper));
            httpResponse.setStatusCode(resContext.StatusCode);
            httpResponse.setStatus(RES_STATUS.get(resContext.StatusCode));
            httpRequest.setBody(reqBody);

            INTLogger.INTLoggerResult result = INTLogger.logCallout('Direccion', 'REST_Direcciones_FSC.doPut', httpRequest, httpResponse);
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
    }
}