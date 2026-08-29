@isTest
public class SincronizarSolicitudFlowControllerTest {
    
    @testsetup
    static void makeData(){
        TestDataFactoryPrestamos.createTestData();
    }
    
    @isTest
    static void sincronizarTest() {
                
        // To specify fake response for a certain endpoint and include response body in a static resource.
        
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource('callout:DataCreditoWS/ConsultaEstado', 'sincronizarSolicitud');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, multimock);
		
		        
        SincronizarSolicitudFlowController.FlowInputs[] inputs = new List<SincronizarSolicitudFlowController.FlowInputs>();
        SincronizarSolicitudFlowController.FlowOutputs[] outputs = new List<SincronizarSolicitudFlowController.FlowOutputs>();

        SincronizarSolicitudFlowController.FlowInputs input = new SincronizarSolicitudFlowController.FlowInputs();
        input.opportunity = [Select Id, Opp_numSolictud__c from Opportunity limit 1];
        input.opportunity.Opp_numSolictud__c = '8503';
        update input.opportunity;
        inputs.add(input);
        
        Test.startTest();
        try {
            outputs = SincronizarSolicitudFlowController.sincronizar(inputs);
            System.assertNotEquals(null, outputs);
        } catch (QueryException ex) {
            System.assert(ex.getMessage().contains('List has no rows'), ex.getMessage());
        }
        Test.stopTest();
    }


}
