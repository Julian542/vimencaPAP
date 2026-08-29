public class SincronizarSolicitudFlowController {
    
    public class FlowInputs {
        @InvocableVariable public Opportunity opportunity;
    }
    
    public class FlowOutputs {  
        @InvocableVariable public Decimal codeSubEstado;
        @InvocableVariable public String descSubEstado;
    }

    @InvocableMethod(label='Sincronizar Solicitud')
    public static List<FlowOutputs> sincronizar(FlowInputs[] input) {
        try {
            FlowOutputs[] responses = new List<FlowOutputs>();
            FlowOutputs fo = new FlowOutputs();
            for (FlowInputs record : input) {
                String body = createBody(record);
                fo = REST_WebService.sincronizarSolicitud(body);
                if (fo != null) {
                    responses.add(fo);
                }
            }
            return responses;
        } catch (System.FlowException e) { throw new HandledException(e.getMessage()); }
    }

    public static String createBody(FlowInputs input){
        wpSincronizarSolicitud body = new wpSincronizarSolicitud();
        body.reqEstadoSolBiz = Integer.valueOf(input.opportunity.Opp_numSolictud__c);
        return JSON.serialize(body);
    }

    public class wpSincronizarSolicitud{
        public Integer reqEstadoSolBiz;
    } 


}