/*************************
* @Class Name:- StopCheckPaymentHelperFunctionsTest
* @Description:- Test class for StopCheckPaymentHelperFunctions
*                Which handles Case creation and service catalog request and 
*                extended attribute creation based on input parameter. 
**************************/
@IsTest
public with sharing class StopCheckPaymentHelperFunctionsTest {
    // Set input values
    @IsTest(SeeAllData=true) 
    static void testCaseCreation() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        input.put('accountId', 'AccountId');
        input.put('svcCatalogItemDefApiName', 'StopCheckPayment');
        input.put('accountSourceSystemId', '123testid');
        input.put('caseSubject', 'Stop Check Payment Service Request');
        input.put('isCommunitySite', 'false');
        input.put('accountNumber', '986245i0aa');
        input.put('accountType', 'Checking Account');
        input.put('checkType', 'Single check');
        input.put('reason', 'Checkbook lost');
        input.put('checkDate', '06/06/2023');
        input.put('checkNumber', '67543478');
        input.put('payee', '67543478');
        input.put('amount', '5000');
        input.put('lowestCheckNumber', '67543478');
        input.put('highestCheckNumber', '67543480');
        input.put('financialAccountSourceSystemId', '675RFh478SCD');
        input.put('financialAccountId', '67543478ih5AAA');
        args.put('input', input);
        args.put('output', output);
        Callable cllableMethod = (Callable)Type.forName('StopCheckPaymentHelperFunctions').newInstance();
        Object caseCreateApiObj = cllableMethod.call('callCreateCaseApi', args);  
        System.assertEquals('{apiResponse={}}', String.valueOf(caseCreateApiObj));
    }
}