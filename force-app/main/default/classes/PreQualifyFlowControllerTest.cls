@isTest
public class PreQualifyFlowControllerTest {

    @isTest
    public static void runTest(){
        
        PreQualifyFlowController.FlowInputs toPrequalify = new PreQualifyFlowController.FlowInputs();
        List<Account> account = TestDataFactoryPreQualifyFlow.crearBasicCandidatoPJ(1);
        toPrequalify.account = account[0];
        toPrequalify.infoFinanciera = TestDataFactoryPreQualifyFlow.createInfoFinan(account)[0];
        toPrequalify.accionista = TestDataFactoryPreQualifyFlow.createBasicAcionista(account)[0];
        toPrequalify.representante = TestDataFactoryPreQualifyFlow.createBasicRepresentante(account)[0];
        
        PreQualifyFlowController.prequalify(new List<PreQualifyFlowController.FlowInputs>{toPrequalify});
        
        
    }
}