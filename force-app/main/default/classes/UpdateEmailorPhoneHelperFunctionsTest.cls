/*************************
* @Class Name:- UpdateEmailorPhoneHelperFunctionsTest
* @Description:- Test class for UpdateEmailorPhoneHelperFunctions
*                Which handles Case creation and service catalog request and 
*                extended attribute creation based on input parameter. 
**************************/
@IsTest
public with sharing class UpdateEmailorPhoneHelperFunctionsTest {
    // Set input values
    @IsTest(SeeAllData=true) 
    static void testCaseCreation() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        input.put('accountId', 'AccountId');
        input.put('svcCatalogItemDefApiName', 'UpdateEmailorPhone');
        input.put('accountSourceSystemId', '123testid');
        input.put('caseSubject', 'Contact Update Service Request');
        input.put('isCommunitySite', 'false');
        input.put('newEmail', 'testNewEmai@test.com');
        input.put('currentEmail', 'currentEmail@test.com');
        input.put('newPhoneNumber', '+1234567890');
        input.put('currentPhoneNumber', '+1987654321');
        input.put('newMobileNumber', '+4456789012');
        input.put('currentMobileNumber', '+6754321897');
        args.put('input', input);
        args.put('output', output);
        Callable cllableMethod = (Callable)Type.forName('UpdateEmailorPhoneHelperFunctions').newInstance();
        Object caseCreateApiObj = cllableMethod.call('callCreateCaseApi', args);  
        System.assertEquals('{apiResponse={}}', String.valueOf(caseCreateApiObj));   
    }
}