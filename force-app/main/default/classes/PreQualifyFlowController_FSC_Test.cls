/**
 * @description       : 
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 28-12-2025
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
@isTest
private with sharing class PreQualifyFlowController_FSC_Test {

    @isTest
    private static void runTest(){

        PreQualifyFlowController.FlowInputs toPrequalify = new PreQualifyFlowController.FlowInputs();
        List<Account> account = TestDataFactoryPreQualifyFlow.crearBasicCandidatoPJ(1);
        toPrequalify.account = account[0];
        toPrequalify.infoFinanciera = TestDataFactoryPreQualifyFlow.createInfoFinan(account)[0];
        toPrequalify.accionista = TestDataFactoryPreQualifyFlow.createBasicAcionista(account)[0];
        toPrequalify.representante = TestDataFactoryPreQualifyFlow.createBasicRepresentante(account)[0];

        PreQualifyFlowController.prequalify(new List<PreQualifyFlowController.FlowInputs>{toPrequalify});
    }
}