/*************************
* @Class Name:- NotifyTravelPlansIntegrationProviderTest
* @Description:- This file includes tests response from method in NotifyTravelPlansIntegrationProvider.apex
**************************/
@IsTest
public with sharing class NotifyTravelPlansIntegrationProviderTest {
    
    private static final String PERSON_ACCOUNT_URL_PATH_KEY = 'Person_Account_URL_Path';
    private static final Map<String, Object> attributes = new Map<String, Object> { PERSON_ACCOUNT_URL_PATH_KEY => '/api/customers/{recordId}' };

    private static Boolean isExpectedSecurityWrappedException(Exception ex) {
        return ex != null &&
            ex.getMessage() != null &&
            ex.getMessage() == 'Script-thrown exception';
    }

    //This method creates the setup data
    @TestSetup
    static void createServiceCatalogReqData() {
        Map<String, String> headers = new Map<String, String>{ 'Content-Type' => 'application/json' };
        Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(200, 'Success', '{}', headers));

        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList = new List<SvcCatalogReqExtdAttrVal>();
        List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
        //insert a list of account from test data factory
        Integer intNumber = 1;
        List<Account> listAccount = FSCRetailTestDataFactory.createAccounts(intNumber);
        //insert list of Card from test data factory
        List<FinServ__Card__c> listCardsCreated = FSCRetailTestDataFactory.createCards(listAccount);
        //insert list of Service Catalog Request from test data factory
        List<SvcCatalogRequest> listServiceCatalogReq = FSCRetailTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
        insert listServiceCatalogReq;   
        SvcCatalogRequest svcCatalogRequestRec = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
            if (svcCatAttr.DeveloperName == 'alternate_phone_country_code') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec1.TextValue = '+91';
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec1);
            } else if (svcCatAttr.DeveloperName == 'alternate_phone_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec2.TextValue = '9876541234';
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec2);
            } else if (svcCatAttr.DeveloperName == 'phone') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec3.TextValue = '9876541234';
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec3);
            } else if (svcCatAttr.DeveloperName == 'email') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec4.TextValue = 'bob@gmail.com';
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec4);
            } else if (svcCatAttr.DeveloperName == 'date_of_return') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec5.TextValue = '2023-06-08';
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec5);
            } else if (svcCatAttr.DeveloperName == 'date_of_departure') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec6.TextValue = '2023-05-08';
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec6);
            } else if (svcCatAttr.DeveloperName == 'domestic_destination') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec7.TextValue = 'California, Arizona';
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec7);
            } else if (svcCatAttr.DeveloperName == 'international_destination') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec8.TextValue = 'India, Afganistan';
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec8);
            } else if (svcCatAttr.DeveloperName == 'ownership_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec9.GroupNumber = 1;
                svcCatalogReqExtdAttrValRec9.TextValue = 'Primary Owner';
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec9);
            } else if (svcCatAttr.DeveloperName == 'card_valid_until') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec10.GroupNumber = 1;
                svcCatalogReqExtdAttrValRec10.TextValue = '6/2025';
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec10);
            } else if (svcCatAttr.DeveloperName == 'card_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec11.GroupNumber = 1;
                svcCatalogReqExtdAttrValRec11.TextValue = 'XXXX-6382';
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec11);
            } else if (svcCatAttr.DeveloperName == 'name_on_card') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec12.GroupNumber = 1;
                svcCatalogReqExtdAttrValRec12.TextValue = 'New Master Card';
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec12);
            } else if (svcCatAttr.DeveloperName == 'mobile') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec13.TextValue = '9876541234';
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec13);
            }
        }
        insert svcCatalogReqExtdAttrValList;
    }
    
    //tests executeCallout method
    @IsTest 
    static void testExecuteCallout() {
        SvcCatalogRequest catalogReq = [SELECT Id FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        //User autoUsr = [SELECT Id FROM User WHERE Alias ='autoproc'];
        //User adminUsr = [SELECT Id,ProfileId FROM User WHERE LastName ='Testing'];
        //System.runas(adminUsr){
            Test.startTest();
            // Set mock callout class 
            Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201, 'Success', '"customerId": "Test Account1", "travelDetail": { "departureDate": "2023-05-08", "returnDate": "2023-06-08", "usDestinations": [ "CA", "AZ" ], "internationalDestinations": [ "IN","AF" ] }, "communicationPreferences": { "email": "bob@gmail.com", "phone": { "countryCode": "+91", "phoneNumber": "9876541234" }, "mobile": { "countryCode": "+91", "phoneNumber": "9876541234" }, "alternatePhone": { "countryCode": "+91", "phoneNumber": "9876541234" } }, "cards": [ { "cardNumber": "4645191812341234", "cardName": "New Master Card", "role": "Primary Owner", "cardExpiryDate": "2025-06-08" } ]', headers));
            try {
                industriesintegrationfwk.IntegrationCalloutResponse	 calloutResponse = NotifyTravelPlansIntegrationProvider.executeCallout('6533875', catalogReq.Id, null, attributes);
                System.assertEquals(calloutResponse.isSuccess(), true);
                System.assertEquals(calloutResponse.getErrorMessage(), null);
            } catch (CalloutException ex) {
                System.assertEquals(true, isExpectedSecurityWrappedException(ex), ex.getMessage());
            }
            Test.stopTest();
        //}
    }
    
    //tests the exception
    @IsTest 
    static void testExecuteCalloutException() {
        SvcCatalogRequest catalogReq = [SELECT Id FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        try {
            // Set mock callout class 
            Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201, 'Success', '"customerId": "Test Account1", "travelDetail": { "departureDate": "2023-05-08", "returnDate": "2023-06-08", "usDestinations": [ "CA", "AZ" ], "internationalDestinations": [ "IN","AF" ] }, "communicationPreferences": { "email": "bob@gmail.com", "phone": { "countryCode": "+91", "phoneNumber": "9876541234" }, "mobile": { "countryCode": "+91", "phoneNumber": "9876541234" }, "alternatePhone": { "countryCode": "+91", "phoneNumber": "9876541234" } }, "cards": [ { "cardNumber": "4645191812341234", "cardName": "New Master Card", "role": "Primary Owner", "cardExpiryDate": "2025-06-08" } ]', headers));
            industriesintegrationfwk.IntegrationCalloutResponse	 calloutResponse = NotifyTravelPlansIntegrationProvider.executeCallout('6533875', '', null, attributes);
            System.assertEquals(calloutResponse.isSuccess(), false);
        } catch (Exception ex) {
            System.assertEquals(ex.getMessage(), 'Service Process ID is null');
        }
    }
    
    @IsTest 
    static void testGetProviderAttributes() {
        List<industriesintegrationfwk.ApexProviderAttr> attr = NotifyTravelPlansIntegrationProvider.getProviderAttributes();
        System.assertNotEquals(attr, null);
    }
}
