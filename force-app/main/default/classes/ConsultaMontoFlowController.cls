public class ConsultaMontoFlowController {

    public class FlowInputs {
        @InvocableVariable public Opportunity opportunity;
    }
    
    public class FlowOutputs {  
        @InvocableVariable public Decimal montoCuotas;
        @InvocableVariable public string responseCode;
        @InvocableVariable public string message;
    }

    @InvocableMethod( label='Consultar Monto' description='Consulta de Monto')
    public static List<FlowOutputs> qualify(FlowInputs[] input) {
        try {
            FlowOutputs[] responses = new List<FlowOutputs>();
            FlowOutputs fo = new FlowOutputs();
            for (FlowInputs record : input) {
                String body = createBody(record);
                fo = REST_WebService.consultaMonto(body);
                if (fo != null) {
                    responses.add(fo);
                }
            }
            return responses;
        } catch (System.FlowException e) { 
            throw new HandledException(e.getMessage());
        }
    }

    public static String createBody(FlowInputs input){
        wpConsultaMonto body = new wpConsultaMonto();
        body.plazo = input.opportunity.Plazo__c;
        body.tasainteres = input.opportunity.Tasa__c;
        body.montoprestamo = input.opportunity.Monto__c;
        body.tipo = input.opportunity.Forma_de_pago__c;
        return JSON.serialize(body);
    }

    public class wpConsultaMonto{
        public Decimal montoprestamo;
        public Decimal tasainteres;
        public Decimal plazo;
        public string tipo;
    } 

}