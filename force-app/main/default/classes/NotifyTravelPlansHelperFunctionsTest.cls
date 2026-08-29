/*************************
* @Class Name:- NotifyTravelPlansHelperFunctionsTest
* @Description:- Test class for NotifyTravelPlansHelperFunctions
*                Which handles Case creation and service catalog request and 
*                extended attribute creation based on input parameter. 
**************************/
@IsTest
public with sharing class NotifyTravelPlansHelperFunctionsTest {
    
    @IsTest(SeeAllData=true) 
    static void testCaseCreation() {
        List<Object> cardList = new List<Object>();
        Map<String, Object> card = new Map<String, Object>();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        
        card.put('CardNumber', '123456789012');
        card.put('CardName', 'TestCard');
        card.put('CardValidDate', '05/05/2024');
        card.put('CardSourceSystemId', '1234retAST');
        card.put('Role', 'Primary');
        cardList.add(card);
        input.put('accountId', 'AccountId');
        input.put('accountSourceSystemId', '0000try54367seAAA');
        input.put('svcCatalogItemDefApiName', 'TravelNotification');
        input.put('caseSubject', 'Travel Notification Service Request');
        input.put('isCommunitySite', 'false');
        input.put('dateOfDeparture', '02/02/2023');
        input.put('email', 'currentEmail@test.com');
        input.put('dateOfReturn', '05/05/2023');
        input.put('phone', '1987654321');
        input.put('mobile', '4567890123');
        input.put('alternatePhoneCountryCode', '+91');
        input.put('alternatePhoneNumber', '1234567890');
        input.put('internationalDestination', '(India)');
        input.put('domesticDestination', '(New york)');
        input.put('selectedCards', cardList);
        args.put('input', input);
        args.put('output', output);
        Callable callableMethod = (Callable)Type.forName('NotifyTravelPlansHelperFunctions').newInstance();
        Object createCaseApiObj = callableMethod.call('callCreateCaseApi', args);
        System.assertEquals('{}', String.valueOf(createCaseApiObj));
    }
    
    //Test method to get Country Picklist value 
    @IsTest 
    static void testgetCountryPicklist() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        
        args.put('input', input);
        args.put('output', output);
        Callable callableMethod = (Callable)Type.forName('NotifyTravelPlansHelperFunctions').newInstance();
        Object countryPicklistValueObj = callableMethod.call('getCountryPicklistValues', args);
    }
}