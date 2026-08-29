/*************************
* @Class Name:- OrderCheckbookHelperFunctionsTest
* @Description:- Test class for OrderCheckbookHelperFunctions
*                Which handles Case creation and service catalog request and 
*                extended attribute creation based on input parameter. 
**************************/
@IsTest
public with sharing class OrderCheckbookHelperFunctionsTest {
    // Set input values
    @IsTest(SeeAllData=true) 
    static void testCaseCreation() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();

        input.put('accountId', 'AccountId');
        input.put('accountSourceSystemId', '0000try54367seAAA');
        input.put('svcCatalogItemDefApiName', 'ReportandReplaceCard');
        input.put('caseSubject', 'Report and Replace Card Service Request');
        input.put('isCommunitySite', 'false');
        input.put('noofCheck', '25');
        input.put('financialAccountId', 'rtyugffgh566DES');
        input.put('financialAccountNumber', '34566');
        input.put('financialAccountName', 'Test Financial Account 1');
        input.put('financialAccountType', 'Savings Account');
        input.put('financialAccountSourceSystemId', 'gfft4566FeTYU');
        input.put('addressLine1', '1 street');
        input.put('addressLine2', '2nd stage,5th cross');
        input.put('city', 'sCity');
        input.put('state', 'cState');
        input.put('country', 'nCountry');
        input.put('postalCode', '567890');
        input.put('shippingPreference', 'Standard');
        input.put('addressType', 'Shipping Address');
        args.put('input',input);
        args.put('output',output);
        Callable cllableMethod = (Callable)Type.forName('OrderCheckbookHelperFunctions').newInstance();
        Object createCaseApiObj = cllableMethod.call('callCreateCaseApi', args);
        System.assertEquals('{apiResponse={}}', String.valueOf(createCaseApiObj));
    }
}