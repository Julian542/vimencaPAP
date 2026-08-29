/**
 * @description       : an adapted version of REST_ActualizarSubestadoOportunidad to FinServ Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 28-12-2025
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@RestResource(urlMapping='/opportunity/update-substage')
global with sharing class REST_ActualizarSubestadoOportunidad_FSC {

    private static Set<String> successSet = new Set<String>();
    private static final Map<Integer,String> RES_STATUS = UtilVariables.RES_STATUS;

    @HttpPost
    global static void doPost(){

        ResponseWrapper resWrapper  = new ResponseWrapper();
        RestRequest reqContext      = RestContext.request;
        RestResponse resContext     = RestContext.response;
        HttpRequest httpRequest     = new HttpRequest();
        HttpResponse httpResponse   = new HttpResponse();

        String reqBody = reqContext.requestBody.toString();

        try {

            DataDTO dataDTO = (DataDTO) JSON.deserialize(reqBody, DataDTO.class);
            Opportunity opp;

            List<Opportunity> opps = [
                SELECT id, Opp_numSolictud__c, Opp_subEstadoSolictud__c
                FROM Opportunity
                WHERE Opp_numSolictud__c =: dataDTO.numSolicitud
            ];

            if (opps.size() == 0) {
                resWrapper.errors.add('Error Code: No se encontró la solicitud. Fields: (Opp_numSolictud__c). Message: No se encontró la solicitud'); resContext.statusCode = 404;
            }else {
                opp = opps[0];
                opp.Opp_subEstadoSolictud__c = dataDTO.subStage;

                Database.SaveResult srOpp = Database.update(opp);
                if (!srOpp.isSuccess()) {
                    for(Database.Error err : srOpp.getErrors()) { resWrapper.errors.add('Error Code: '+err.getStatusCode()+'. Fields: '+err.getFields()+'.Message: '+err.getMessage());}
                }
            }

            if(resWrapper.errors.isEmpty()){
                resContext.StatusCode = 200;
            }

        } catch(Exception e) {
            resWrapper.errors.add('Error Code: <>. Fields: <>. Message: '+e.getMessage()); resContext.StatusCode = 500; System.debug('Error :: ' + e);
        } finally {
            resWrapper.message = RES_STATUS.get(resContext.StatusCode);
            resContext.responseBody= Blob.valueOf(JSON.serialize(resWrapper));

            // Registro del Log
            httpResponse.setBody(JSON.serialize(resWrapper));
            httpResponse.setStatusCode(resContext.StatusCode);
            httpResponse.setStatus(RES_STATUS.get(resContext.StatusCode));
            httpRequest.setBody(reqBody);

            INTLogger.INTLoggerResult result = INTLogger.logCallout('Actualizar Solicitud', 'REST_ActualizarSubestadoOportunidad_FSC.doPost', httpRequest, httpResponse);
        }
    }

    global class DataDTO{
        public string numSolicitud;
        public string subStage;
    }

    global class ResponseWrapper{
        String message;
        List<String> errors;

        global ResponseWrapper(){
            this.errors= new List<String>();
        }
    }
}