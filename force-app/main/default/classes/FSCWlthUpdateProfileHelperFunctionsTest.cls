/*************************
* @Class Name:- FSCWlthUpdateProfileHelperFunctionsTest
* @Description:- Test class for UpdateProfileHelperFunctions
*                Which handles Case creation and service catalog request and 
*                extended attribute creation based on input parameter. 
**************************/
@IsTest
public with sharing class FSCWlthUpdateProfileHelperFunctionsTest {
    // Set input values
    @IsTest 
    static void testCaseCreation() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> docs = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        Map<String, Object> selectedAddresses = new Map<String, Object>();
        //set selectedAddresses details
        selectedAddresses.put('Type', 'Billing Address');
        selectedAddresses.put('Address', 'IndividualAccountAddress1');
        selectedAddresses.put('AccountNumberLast4', '4567');
        //set uploadedDocuments details
        docs.put('id', 'DocId');
        docs.put('typeId', 'typeId');
        docs.put('name', 'Doc name1');
        //set input attributes details
        input.put('accountId', 'AccountId');
        input.put('svcCatalogItemDefApiName', 'FSCWlth_ProfileUpdate');
        input.put('caseSubject', 'Profile Update Service Request');
        input.put('isCommunitySite', 'false');
        input.put('selectedEmail', 'true');
        input.put('selectedMobile', 'true');
        input.put('selectedPhone', 'true');
        input.put('selectedName', 'true');
        input.put('selectedAddress', 'true');
        input.put('selectedMaritalStatus', 'true');
        input.put('selectedOccupation', 'true');
        input.put('selectedEmployerName', 'true');
        input.put('newEmail', 'testNewEmai@test.com');
        input.put('currentEmail', 'currentEmail@test.com');
        input.put('newPhoneNumber', '+1234567890');
        input.put('currentPhoneNumber', '+1987654321');
        input.put('newMobileNumber', '+4456789012');
        input.put('currentMobileNumber', '+6754321897');
        input.put('newFirstName', 'TestFirst');
        input.put('newLastName', 'TestSecond');
        input.put('currentFirstName', 'Tommy');
        input.put('currentLastName', 'Tim');
        input.put('addressLine1', 'test address 1');
        input.put('addressLine2', 'test address 2');
        input.put('city', 'testcity');
        input.put('state', 'test state');
        input.put('country', 'testCountry');
        input.put('zipCode', '1234567');
        input.put('updateCustomerAccount', 'Yes');
        input.put('updateFinancialAccount', 'Yes');
        input.put('currentMaritalStatus', 'N/A');
        input.put('currentOccupation', 'N/A');
        input.put('currentEmployerName', 'N/A');
        input.put('newMaritalStatus', 'Married');
        input.put('newOccupation', 'Self-employed');
        input.put('newEmployerName', 'Self');
        input.put('selectedAddresses', selectedAddresses);
        args.put('input', input);
        args.put('output', output);
        args.put('documentInfo', docs);
        Callable cllableMethod = (Callable)Type.forName('FSCWlthUpdateProfileHelperFunctions').newInstance();
        Object caseCreateApiObj = cllableMethod.call('callCreateCaseApi', args);  
        System.assertEquals('{apiResponse={}}', String.valueOf(caseCreateApiObj));   
    }
}