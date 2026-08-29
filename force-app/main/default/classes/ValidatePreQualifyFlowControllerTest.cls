@isTest
public class ValidatePreQualifyFlowControllerTest {
   
    @isTest
    public static void ValidatePreQualifyFlowControllerPF(){

        List<ValidatePreQualifyFlowController.FlowInputs> flowInpList = new List<ValidatePreQualifyFlowController.FlowInputs>();
        ValidatePreQualifyFlowController.FlowInputs flowInp = new ValidatePreQualifyFlowController.FlowInputs();
        
        List<Account> candidatoPFList = TestDataFactoryPreQualifyFlow.crearBasicCandidatoPF(1);
        List<Historial_laboral__c> historialList = TestDataFactoryPreQualifyFlow.createHistorial(candidatoPFList);
        List<Informacion_Financiera__c> infoFinanList = TestDataFactoryPreQualifyFlow.createBasicInfoFinan(candidatoPFList);
        
        flowInp.account = candidatoPFList[0];
        flowInp.infoFinanciera = infoFinanList[0];
        flowInp.history = historialList[0];
        flowInpList.add(flowInp);        
        ValidatePreQualifyFlowController.validatePrequalify(flowInpList);
    }
    @isTest
    public static void ValidatePreQualifyFlowControllerPJ(){
        
        List<ValidatePreQualifyFlowController.FlowInputs> flowInpList = new List<ValidatePreQualifyFlowController.FlowInputs>();
        ValidatePreQualifyFlowController.FlowInputs flowInp = new ValidatePreQualifyFlowController.FlowInputs();
        
        List<Account> candidatoPJList = TestDataFactoryPreQualifyFlow.crearBasicCandidatoPJ(1);
        List<Informacion_Financiera__c> infoFinanList = TestDataFactoryPreQualifyFlow.createBasicInfoFinan(candidatoPJList);
        List<Participante__c> accionistaList = TestDataFactoryPreQualifyFlow.createBasicAcionista(candidatoPJList);
        List<Participante__c> representanteList = TestDataFactoryPreQualifyFlow.createBasicRepresentante(candidatoPJList);
        
        flowInp.account = candidatoPJList[0];
        flowInp.infoFinanciera = infoFinanList[0];
        flowInp.accionista = accionistaList[0];
		flowInp.representante = representanteList[0];
        flowInpList.add(flowInp);        
        ValidatePreQualifyFlowController.validatePrequalify(flowInpList);
    }    
}