/*************************
* @Class Name:- ReportandReplaceDebitCardIntegPrvdTest
* @Description:- This file includes tests response from method in ReportReissueCardIntegrationProvider.apex
**************************/

@IsTest
public with sharing class ReportandReplaceDebitCardIntegPrvdTest {
    private static final String PERSON_ACCOUNT_URL_PATH_KEY = 'Person_Account_URL_Path';
    private static final Map<String, Object> ATTRIBUTES = new Map<String, Object> {PERSON_ACCOUNT_URL_PATH_KEY => '/api/customers/{recordId}'};

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

        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList1 = new List<SvcCatalogReqExtdAttrVal>();
        List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
        //insert a list of account from test data factory
        Integer intNumber = 1;
        List<Account> listAccount = FSCRetailTestDataFactory.createAccounts(intNumber);
        //insert list of Service Catalog Request from test data factory
        List<FinServ__Card__c> listCardsCreated = FSCRetailTestDataFactory.createCards(listAccount);
        List<SvcCatalogRequest> listServiceCatalogReq = FSCRetailTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
        insert listServiceCatalogReq;
        
        SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName='TestCatalog0' LIMIT 1];
        for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
            if (svcCatAttr.DeveloperName == 'reason_for_card_block') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec1.TextValue = 'Stolen';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
            } else if (svcCatAttr.DeveloperName == 'comments') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec2.TextValue = 'None';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
            } else if (svcCatAttr.DeveloperName == 'shipping_preference') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec3.TextValue = 'Standard Shipping';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec3);
            } else if (svcCatAttr.DeveloperName == 'address_line_1') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec4.TextValue = '12 California Street';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec4);
            } else if (svcCatAttr.DeveloperName == 'address_line_2') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec5.TextValue = '12B Apartment';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
            } else if (svcCatAttr.DeveloperName == 'city') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec6.TextValue = 'New York';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec6);
            } else if (svcCatAttr.DeveloperName == 'state') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec7.TextValue = 'Paris';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec7);
            } else if (svcCatAttr.DeveloperName == 'postal_code') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec8.TextValue = '506098';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec8);
            } else if (svcCatAttr.DeveloperName == 'country') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec9.TextValue = 'US';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec9);
            } else if (svcCatAttr.DeveloperName == 'card_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec11.GroupNumber = 1;
                svcCatalogReqExtdAttrValRec11.TextValue = 'XXXX-6382';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec11);
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec16 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec16.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec16.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec16.GroupNumber = 2;
                svcCatalogReqExtdAttrValRec16.TextValue = 'XXXX-6383';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec16);
            } else if (svcCatAttr.DeveloperName == 'card_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec12.GroupNumber = 1;
                svcCatalogReqExtdAttrValRec12.TextValue = 'Debit Card';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec12);
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec17 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec17.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec17.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec17.GroupNumber = 2;
                svcCatalogReqExtdAttrValRec17.TextValue = 'Debit Card';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec17);
            } else if (svcCatAttr.DeveloperName == 'card_name') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec13.GroupNumber = 1;
                svcCatalogReqExtdAttrValRec13.TextValue = 'Star Wars';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec13);
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec18 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec18.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec18.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec18.GroupNumber = 2;
                svcCatalogReqExtdAttrValRec18.TextValue = 'Moon Wars';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec18);
            } else if (svcCatAttr.DeveloperName == 'replacement_required') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec14.GroupNumber = 1;
                svcCatalogReqExtdAttrValRec14.TextValue = 'Yes';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec14);
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec19 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec19.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec19.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec19.GroupNumber = 2;
                svcCatalogReqExtdAttrValRec19.TextValue = 'Yes';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec19);
            } else if (svcCatAttr.DeveloperName == 'financial_account_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec15.GroupNumber = 1;
                svcCatalogReqExtdAttrValRec15.TextValue = 'Savings Account';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec20 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec20.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec20.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec20.GroupNumber = 2;
                svcCatalogReqExtdAttrValRec20.TextValue = 'Checking Account';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec20);
            }
        }
        insert svcCatalogReqExtdAttrValList1;
    }
    
    //tests executeCallout method
    @IsTest static void testExecuteCalloutForDebitCards() {
        SvcCatalogRequest catalogReq = [SELECT Id FROM SvcCatalogRequest WHERE CatalogItemName='TestCatalog0' LIMIT 1];
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201, 'Success', '"cards": [{"cardId": "3765476354632323", "toBeReissued": true },{"cardId": "3765476354632324", "toBeReissued": true }], "reason": "Stolen", "remarks": "None", "shippingPreference": "Standard Shipping", "shippingAddress": {"addressLine1": "12 California Street", "state": "Paris", "countryCode": "US", "city": "New York", "addressLine2": "12B Apartment", "postalCode": "506098"}', headers));
        try {
            industriesintegrationfwk.IntegrationCalloutResponse  calloutResponse = ReportandReplaceDebitCardIntegPrvd.executeCallout('6533875', catalogReq.Id, null, ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), true);
            System.assertEquals(calloutResponse.getErrorMessage(), null);
        } catch (CalloutException ex) {
            System.assertEquals(true, isExpectedSecurityWrappedException(ex), ex.getMessage());
        }
        Test.stopTest();
    }

    //tests the exception
    @IsTest static void testExecuteCalloutException() {
        SvcCatalogRequest catalogReq = [SELECT Id FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        
        try {
            // Set mock callout class 
            Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201, 'Success', '"cards": [{"cardId": "3765476354632323", "toBeReissued": true },{"cardId": "3765476354632324", "toBeReissued": true }], "reason": "Stolen", "remarks": "None", "shippingPreference": "Standard Shipping", "shippingAddress": {"addressLine1": "12 California Street", "state": "Paris", "countryCode": "US", "city": "New York", "addressLine2": "12B Apartment", "postalCode": "506098"}', headers));
            industriesintegrationfwk.IntegrationCalloutResponse  calloutResponse = ReportandReplaceDebitCardIntegPrvd.executeCallout('6533875', '', null, ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), false);
        }
        catch(Exception ex) {
            System.assertEquals(ex.getMessage(), 'Service Process ID is null');
        }
    }
    
    @IsTest static void testgetProviderAttributes() {
        List<industriesintegrationfwk.ApexProviderAttr> attr = ReportandReplaceDebitCardIntegPrvd.getProviderAttributes();
        System.assertNotEquals(attr, null);
    }
}
