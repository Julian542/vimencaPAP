/*************************
* @Class Name:- FSCWlthUpdateProfileCustomerIntegPrvdTst
* @Description:- This file includes tests response from method in FSCWlthUpdateProfileCustomerIntegPrvd.apex
**************************/
@IsTest
public with sharing class FSCWlthUpdateProfileCustomerIntegPrvdTst {
    
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
            Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(200, 'Success', '{}', headers));

	        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList = new List<SvcCatalogReqExtdAttrVal>();
	        List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
            //insert a list of account from test data factory
            Integer intNumber = 1;
            List<Account> listAccount = FSCWlthTestDataFactory.createAccounts(intNumber);
            //insert list of Service Catalog Request from test data factory
            List<SvcCatalogRequest> listServiceCatalogReq = FSCWlthTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
            insert listServiceCatalogReq;
	        SvcCatalogRequest svcCatalogRequestRec = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName='TestCatalog0' LIMIT 1];
            
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'new_first_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = 'bob';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'new_last_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'Marley';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'new_email') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = 'bob@marley.com';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'new_phone_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.TextValue = '+91872673565376';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec4);
                } else if (svcCatAttr.DeveloperName == 'new_mobile_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.TextValue = '+18766546562';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec5);
                } else if (svcCatAttr.DeveloperName == 'new_marital_status') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec6.TextValue = 'Married';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec6);
                } else if (svcCatAttr.DeveloperName == 'new_employer_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec7.TextValue = 'Self';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec7);
                } else if (svcCatAttr.DeveloperName == 'new_occupation') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec8.TextValue = 'Engineer';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec8);
                } else if (svcCatAttr.DeveloperName == 'update_customer_account') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec9.TextValue = 'Yes';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec9);
                } else if (svcCatAttr.DeveloperName == 'address_line_1') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec10.TextValue = '1023';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec10);
                } else if (svcCatAttr.DeveloperName == 'address_line_2') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec11.TextValue = 'Hyde Park';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec11);
                } else if (svcCatAttr.DeveloperName == 'city') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec12.TextValue = 'New Jersey';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec12);
                } else if (svcCatAttr.DeveloperName == 'state') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec13.TextValue = 'NJ';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec13);
                } else if (svcCatAttr.DeveloperName == 'zip_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec14.TextValue = '343433';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec14);
                }  else if (svcCatAttr.DeveloperName == 'country') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec15.TextValue = 'US';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec15);
                } else if (svcCatAttr.DeveloperName == 'account_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec16 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec16.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec16.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec16.TextValue = 'Shipping Address';
                    svcCatalogReqExtdAttrValRec16.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec16);
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
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(200, 'Success', '"responseStatus": "SUCCESS"', headers));
        try {
            industriesintegrationfwk.IntegrationCalloutResponse  calloutResponse = FSCWlthUpdateProfileCustomerIntegPrvd.executeCallout('6533875', catalogReq.Id, null, attributes);
            System.assertEquals(calloutResponse.isSuccess(), true);
            System.assertEquals(calloutResponse.getErrorMessage(), null);
        } catch (CalloutException ex) {
            System.assertEquals(true, isExpectedSecurityWrappedException(ex), ex.getMessage());
        }
        Test.stopTest();
    }
    
    //test method for getProviderAttributes method
    @IsTest 
    static void testgetProviderAttributes(){
        List<industriesintegrationfwk.ApexProviderAttr> attr = FSCWlthUpdateProfileCustomerIntegPrvd.getProviderAttributes();
        System.assertNotEquals(attr, null);
    }
}
