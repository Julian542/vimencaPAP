/*************************
* @Class Name:- ManageStandingInstructionsHelperFuncTst
* @Description:- Test class for ManageStandingInstructionsHelperFunc
*                Which handles Case creation and service catalog request and 
*                extended attribute creation based on input parameter. 
**************************/
@IsTest
public with sharing class ManageStandingInstructionsHelperFuncTst {
    
    @IsTest(SeeAllData=true) 
    static void testCaseCreation() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        
        input.put('accountId', 'AccountId');
        input.put('svcCatalogItemDefApiName', 'ManageStandingInstructions');
        input.put('caseSubject', 'Mansge Standing Instructions Service Request');
        input.put('isCommunitySite', 'false');
        input.put('accountNumber', 'XXXX-2345');
        input.put('accountName', 'TestAccountName');
        input.put('accountType', 'Savings Account');
        input.put('payeeName', 'XXXX-9876');
        input.put('payeeRoutingNumber', 'RONO9876');
        input.put('payeeAccountNumber', 'ACCNO9876');
        input.put('currency', 'USD');
        input.put('frequency', 'Monthly');
        input.put('remarks', 'Remarks added for testing');
        input.put('standingInstructionType', 'Add');
        input.put('amount', '77.88');
        input.put('noOfInstallment', '7');
        input.put('startDate', '03/03/2023');
        input.put('endDate', '05/05/2023');
        input.put('standingInstructionId', 'SOID5678');
        args.put('input', input);
        args.put('output', output);
        Callable callableMethod = (Callable)Type.forName('ManageStandingInstructionsHelperFunc').newInstance();
        Object createCaseApiObj = callableMethod.call('callCreateCaseApi', args);
        System.assertEquals('{}', String.valueOf(createCaseApiObj));
    }
    
}