/*************************
* @Class Name:- RequestStatementCopiesIntegProviderTest
* @Description:- This file includes tests response from method in RequestStatementCopiesIntegPrvd.apex
**************************/
@IsTest
public with sharing class RequestStatementCopiesIntegProviderTest {
    private static final String PERSON_ACCOUNT_URL_PATH_KEY = 'Person_Account_URL_Path';
    private static final Map<String, Object> ATTRIBUTES = new Map<String, Object> { PERSON_ACCOUNT_URL_PATH_KEY => '/api/{recordId}'};

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
            List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute ];
            Integer intNumber = 1;
            List<Account> listAccount = FSCRetailTestDataFactory.createAccounts(intNumber);  
            //insert a list of financial account from test data factory
            List<FinServ__FinancialAccount__c> listFinancialAccount = FSCRetailTestDataFactory.createFinancialAccounts(intNumber, listAccount);
            //insert list of Service Catalog Request from test data factory
            List<SvcCatalogRequest> listServiceCatalogReq = FSCRetailTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
            insert listServiceCatalogReq;
            SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
            
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'start_date') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = '06/16/2023';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'end_date') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = '08/16/2023';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'account_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = 'Auto Loan';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.TextValue = 'XXXX-6210';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec4);
                } else if (svcCatAttr.DeveloperName == 'send_statement_via_email') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.TextValue = 'Yes';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
                } else if (svcCatAttr.DeveloperName == 'email') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec6.TextValue = 'john.doe@gmail.com';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec6);
                } else if (svcCatAttr.DeveloperName == 'send_statement_via_post') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec7.TextValue = 'Yes';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec7);
                } else if (svcCatAttr.DeveloperName == 'shipping_preference') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec8.TextValue = 'Standard';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec8);
                } else if (svcCatAttr.DeveloperName == 'address_line_1') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec9.TextValue = '12 California Street';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec9);
                } else if (svcCatAttr.DeveloperName == 'address_line_2') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec10.TextValue = '12B Apartment';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec10);
                } else if (svcCatAttr.DeveloperName == 'city') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec11.TextValue = 'California';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec11);
                } else if (svcCatAttr.DeveloperName == 'state') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec12.TextValue = 'CA';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec12);
                } else if (svcCatAttr.DeveloperName == 'postal_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec13.TextValue = '506098';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec13);
                } else if (svcCatAttr.DeveloperName == 'country') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec14.TextValue = 'US';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec14);
                }  else if (svcCatAttr.DeveloperName == 'address_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec15.TextValue = 'Shipping address';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
                }
            }
            insert svcCatalogReqExtdAttrValList1;
        }
    
    //tests executeCallout method
    @IsTest 
    static void testExecuteCalloutForRequestStatemnet() {
        SvcCatalogRequest catalogReq = [SELECT Id FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201, 'Success', '“statement”:{“endDate”:”06/16/2023”, “sendVia”:{“emailId”:”john.doe@gmail.com”, “shippingAddress”{“addressLine1”:”12 California Street”,“addressLine2”:”12B Apartment”, “addressType”:”Shipping Address”, “city”:”California”, “countryCode”:”India”, “postalCode”:”281004”, “state”:”CA”}, “shippingPreference”:”Standard”}, “startDate”:”5/21/2023”}', headers));
        try {
            industriesintegrationfwk.IntegrationCalloutResponse	 calloutResponse = RequestStatementCopiesIntegPrvd.executeCallout('6533875', catalogReq.Id, null, ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), true);
            System.assertEquals(calloutResponse.getErrorMessage(), null);
        } catch (CalloutException ex) {
            System.assertEquals(true, isExpectedSecurityWrappedException(ex), ex.getMessage());
        }
        Test.stopTest();
    }
    
    //tests the exception
    @IsTest 
    static void testExecuteCalloutException() {
        SvcCatalogRequest catalogReq = [SELECT Id FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        try {
            // Set mock callout class 
            Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201,'Success','“statement”:{“endDate”:”06/16/2023”, “sendVia”:{“emailId”:”john.doe@gmail.com”, “shippingAddress”{“addressLine1”:”12 California Street”,“addressLine2”:”12B Apartment”, “addressType”:”Shipping Address”, “city”:”California”, “countryCode”:”India”, “postalCode”:”281004”, “state”:”CA”}, “shippingPreference”:”Standard”}, “startDate”:”5/21/2023”}', headers));
            industriesintegrationfwk.IntegrationCalloutResponse	 calloutResponse = RequestStatementCopiesIntegPrvd.executeCallout('6533875', '', null, ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), false);
        } catch (Exception ex) {
            System.assertEquals(ex.getMessage(), 'Service Process ID is null');
        }
    }
    
    //test method for getProviderAttributes method
    @IsTest 
    static void testgetProviderAttributes(){
        List<industriesintegrationfwk.ApexProviderAttr> attr = RequestStatementCopiesIntegPrvd.getProviderAttributes();
        System.assertNotEquals(attr, null);
    }
}
