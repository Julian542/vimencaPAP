@isTest
public class ConsultaMontoFlowControllerTest {

    @testsetup
    static void makeData(){
        TestDataFactoryPrestamos.createTestData();        
    }
    
    @isTest
    static void qualifyTest() {
                
        // To specify fake response for a certain endpoint and include response body in a static resource.
        
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource('callout:DataCreditoWS/CalCuotas', 'consultaMontos');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, multimock);
		
		        
        ConsultaMontoFlowController.FlowOutputs[] outputs = new List<ConsultaMontoFlowController.FlowOutputs>();
        ConsultaMontoFlowController.FlowInputs[] inputs = new List<ConsultaMontoFlowController.FlowInputs>();
        
        ConsultaMontoFlowController.FlowInputs input = new ConsultaMontoFlowController.FlowInputs();        
        input.opportunity = [Select Id, Forma_de_pago__c, Monto__c, Tasa__c, Plazo__c from Opportunity limit 1];
        inputs.add(input);
        
        Test.startTest();
        try {
            outputs = ConsultaMontoFlowController.qualify(inputs);
            System.assertNotEquals(null, outputs);
        } catch (QueryException ex) {
            System.assert(ex.getMessage().contains('List has no rows'), ex.getMessage());
        }
        Test.stopTest();
    }
}
