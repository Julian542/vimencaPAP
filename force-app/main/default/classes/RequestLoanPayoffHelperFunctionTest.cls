/*************************
* @Class Name:- RequestLoanPayoffHelperFunctionTest
* @Description:- Test class for RequestLoanPayoffStatementHelperFunction
*                Which handles Case creation and service catalog request and 
*                extended attribute creation based on input parameter. 
**************************/
@IsTest
public with sharing class RequestLoanPayoffHelperFunctionTest {
    // Set input values considering both Via email and Via post set to True/Yes
    @IsTest(SeeAllData=true) 
    static void testCaseCreationWithEmailandPost() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        input.put('svcCatalogItemDefApiName', 'RequestLoanPayoffStatements');
        input.put('caseSubject', 'Request Loan Payoff Service Request');
        input.put('isCommunitySite', 'false');
        input.put('financialAccountNumber', 'XXXX-5345');
        input.put('financialAccountName', 'Financial Account name 1');
        input.put('viaEmail', 'Yes');
        input.put('viaPost', 'Yes');
        input.put('emailId', 'test@gmail.com');
        input.put('payoffDate', '12/10/2023');
        input.put('addressLine1', '4547 18th Street');
        input.put('addressLine2', '7888');
        input.put('state', 'United States');
        input.put('city', 'San Francisco');
        input.put('country', 'United States');
        input.put('postalCode', '45454');
        input.put('principalBalance', 'USD 1000');
        input.put('interestBalance', 'USD 100');
        input.put('feeBalance', 'USD 100');
        input.put('penaltyBalance', 'USD 200');
        input.put('totalPayoffAmount', 'USD 1400');
        input.put('shippingPreference', 'Standard');
        input.put('accountName', 'AccountName1');
        args.put('input', input);
        args.put('output', output);
        Callable cllableMethod = (Callable)Type.forName('RequestLoanPayoffStatementHelperFunction').newInstance();
        Object caseCreateApiObj = cllableMethod.call('callCreateCaseApi', args);  
        System.assertEquals('{apiResponse={}}', String.valueOf(caseCreateApiObj));
    }
    
    // Set input values considering both Via email and Via post set to False/No
    @IsTest(SeeAllData=true) 
    static void testCaseCreationWithoutEmailandPost() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        input.put('svcCatalogItemDefApiName', 'RequestLoanPayoffStatements');
        input.put('caseSubject', 'Request Loan Payoff Service Request');
        input.put('isCommunitySite', 'true');
        input.put('financialAccountNumber', 'XXXX-5345');
        input.put('financialAccountName', 'Account name Test 1');
        input.put('viaEmail', 'No');
        input.put('viaPost', 'No');
        input.put('payoffDate', '12/10/2023');
        input.put('principalBalance', 'USD 1000');
        input.put('interestBalance', 'USD 100');
        input.put('feeBalance', 'USD 100');
        input.put('penaltyBalance', 'USD 200');
        input.put('totalPayoffAmount', 'USD 1400');
        args.put('input', input);
        args.put('output', output);
        Callable cllableMethod = (Callable)Type.forName('RequestLoanPayoffStatementHelperFunction').newInstance();
        Object caseCreateApiObj = cllableMethod.call('callCreateCaseApi', args);  
        System.assertEquals('{apiResponse={}}', String.valueOf(caseCreateApiObj));
    }
}