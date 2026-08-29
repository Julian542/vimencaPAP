/*************************
* @Class Name:- RequestStatementCopiesHelperFunctionTest
* @Description:- Test class for RequestStatementCopiesHelperFunctions
*                Which handles Case creation and service catalog request and 
*                extended attribute creation based on input parameter.
**************************/
@IsTest
public with sharing class RequestStatementCopiesHelperFunctionTest {
    // Set input values
    @IsTest(SeeAllData=true) 
    static void testCaseCreation() {
        Map<String,Object> input = new Map<String,Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object>args = new Map<String, Object>();
        input.put('accountId', 'AccountId');
        input.put('svcCatalogItemDefApiName', 'RequestStatementCopies');
        input.put('accountSourceSystemId', '0000try54367seAAA');
        input.put('caseSubject', 'Request Statement Copies Service Request');
        input.put('isCommunitySite', 'false');
        input.put('accountNumber', '9862425728');
        input.put('accountType', 'Savings Account');
        input.put('viaPost', 'Yes');
        input.put('shippingPreference', 'Standard');
        input.put('addressLine1', '5396');
        input.put('addressLine2', 'North Reese Avenue`');
        input.put('city', 'NY');
        input.put('state', 'NY');
        input.put('postalCode', '67543478');
        input.put('country', 'US');
        input.put('startDate', '5/20/2023');
        input.put('endDate', '6/20/2023');
        input.put('viaEmail', 'Yes');
        input.put('emailId', 'swapnil.pal@salesforce.com');
        input.put('duration', 'Last 1 month');
        input.put('addressType', 'Billing');
        input.put('financialAccountNumber', '67543478ih5AAA');
        input.put('financialAccountType', '67543478ih5AAA');
        input.put('financialAccountName', 'Test FA1');
        args.put('input', input);
        args.put('output', output);
        Callable cllableMethod = (Callable)Type.forName('RequestStatementCopiesHelperFunctions').newInstance();
        Object caseCreateApiObj = cllableMethod.call('callCreateCaseApi', args);  
        System.assertEquals('{apiResponse={}}', String.valueOf(caseCreateApiObj));
    }
}