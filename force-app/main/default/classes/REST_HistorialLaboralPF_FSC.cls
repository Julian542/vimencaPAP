/**
 * @description       : an adapted version of REST_HistorialLaboralPF to FinServ Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 28-12-2025
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@RestResource(urlMapping='/historial-laboral/upsert/')
global with sharing class REST_HistorialLaboralPF_FSC {
    private static final Map<Integer,String> RES_STATUS = UtilVariables.RES_STATUS;

    @HttpPut
    global static void doPut(){

        ResponseWrapper resWrapper  = new ResponseWrapper();
        RestRequest reqContext      = RestContext.request;
        RestResponse resContext     = RestContext.response;
        HttpRequest httpRequest     = new HttpRequest();
        HttpResponse httpResponse   = new HttpResponse();

        String reqBody = reqContext.requestBody.toString();

        try {
            HistorialLaboralDTO[] HistorialLaboralDTOList = (HistorialLaboralDTO[])JSON.deserialize(reqBody, HistorialLaboralDTO[].class);
            Set<String> accNamesSet = new Set<String>();
            Set<String> accCIFSet   = new Set<String>();
            for (HistorialLaboralDTO HisLaboDTO : HistorialLaboralDTOList) {
                if(!String.isBlank(HisLaboDTO.ACC_CIF_c)){
                    accCIFSet.add(HisLaboDTO.ACC_CIF_c);
                }
            }
            Map<String, Account> accounts = new Map<String,Account>();
            for(Account acc : [SELECT Id, ACC_CIF__c, PersonContactId FROM Account WHERE ACC_CIF__c IN : accCIFSet]){
                accounts.put(acc.ACC_CIF__c, acc);
            }

            if(accounts.isEmpty()){
                resWrapper.errors.add('Error Code: NINGUNO DE LOS CIF EXISTE. Fields: (ACC_CIF__c). Message: NINGUNO DE LOS CIF EXISTE');
                resContext.statusCode = 404;
            }else if(accounts.size() != accCIFSet.size()){
                resWrapper.errors.add('Error Code: UNO O ALGUNOS DE LOS CIF NO EXISTE. Fields: (ACC_CIF__c). Message: UNO O ALGUNOS DE LOS CIF NO EXISTE');
            }

            List<FinServ__Employment__c> HistorialToUpsert = new List<FinServ__Employment__c>();
            Account thisAccount;

            for (HistorialLaboralDTO HisDTO : HistorialLaboralDTOList) {
                if(accounts.containsKey(HisDTO.ACC_CIF_c)){
                    thisAccount = accounts.get(HisDTO.ACC_CIF_c);

                    FinServ__Employment__c his      = new FinServ__Employment__c();
                    his.FinServ__Contact__c         = thisAccount.PersonContactId;
                    his.FinServ__SourceSystemId__c  = HisDTO.HIS_Id_Externo_Historial_c;
                    his.EMP_Principal__c            = HisDTO.HIS_Principal_c;
                    his.EMP_Empleo__c               = HisDTO.HIS_Empleo_c;
                    his.EMP_Empresa__c              = HisDTO.HIS_Empresa_c;
                    his.FinServ__StartDate__c       = procesarFecha(HisDTO.HIS_Fecha_de_ingreso_c);
                    his.FinServ__EndDate__c         = procesarFecha(HisDTO.HIS_Fecha_de_fin_c);
                    his.FinServ__Occupation__c      = HisDTO.HIS_Ocupacion_c;
                    his.FinServ__Position__c        = HisDTO.HIS_Puesto_de_trabajo_c;
                    his.FinServ__AnnualIncome__c    = HisDTO.Salario_c;
                    HistorialToUpsert.add(his);
                }
            }
			Schema.SObjectField externalField = FinServ__Employment__c.Fields.FinServ__SourceSystemId__c;
            Database.UpsertResult[] urListaHistorial = Database.upsert(HistorialToUpsert, externalField, false);
            for (Database.UpsertResult ur : urListaHistorial) {
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

            INTLogger.INTLoggerResult result = INTLogger.logCallout('Historial Laboral PF', 'REST_HistorialLaboral.doPut', httpRequest, httpResponse);

        }
    }

    global class HistorialLaboralDTO{
        public string ACC_CIF_c;
        public string HIS_Id_Externo_Historial_c;
        public string HIS_Cuenta_c;
        public boolean HIS_Principal_c;
        public string HIS_Empleo_c;
        public string HIS_Empresa_c;
        public string HIS_Fecha_de_ingreso_c;
        public string HIS_Fecha_de_fin_c;
        public string HIS_Ocupacion_c;
        public string HIS_Puesto_de_trabajo_c;
        public decimal Salario_c;
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
            return Date.parse(value.trim());
        }else return null;
    }
}