/*************************
* @Class Name:- StopCheckPaymentIntegrationProviderTest
* @Description:- This file includes tests response from method in StopCheckPaymentIntegrationProvider.apex
**************************/
@IsTest
public with sharing class StopCheckPaymentIntegrationProviderTest {
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

            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList1 = new List<SvcCatalogReqExtdAttrVal>();
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList2 = new List<SvcCatalogReqExtdAttrVal>();
            List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
            //insert a list of account from test data factory
            Integer intNumber = 2;
            List<Account> listAccount = FSCRetailTestDataFactory.createAccounts(intNumber);
            //insert a list of financial account from test data factory
            List<FinServ__FinancialAccount__c> listFinancialAccount = FSCRetailTestDataFactory.createFinancialAccounts(intNumber, listAccount);
            //insert list of Service Catalog Request from test data factory
            List<SvcCatalogRequest> listServiceCatalogReq = FSCRetailTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
            insert listServiceCatalogReq;
            SvcCatalogRequest svcCatalogRequestRec = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName='TestCatalog0' LIMIT 1];
            
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'check_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = '632551001';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'reason') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'Lost checkbook';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'payee') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = 'Bob';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'amount') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.TextValue = '2000';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec4);
                } else if (svcCatAttr.DeveloperName == 'check_date') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.TextValue = '05/08/2023';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
                } else if (svcCatAttr.DeveloperName == 'check_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec6.TextValue = 'Single check';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec6);
                } else if (svcCatAttr.DeveloperName == 'account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec7.TextValue = 'XXXX-6210';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec7);
                } else if (svcCatAttr.DeveloperName == 'account_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                    svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec8.TextValue = 'Savings Account';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec8);
                }
            }
            insert svcCatalogReqExtdAttrValList1;
            SvcCatalogRequest svcCatalogRequestRec2 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName='TestCatalog1' LIMIT 1];
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'reason') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = 'Lost checkbook';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'starting_check_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = '632551001';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'ending_check_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = '632551003';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.TextValue = 'XXXX-6211';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec4);
                } else if (svcCatAttr.DeveloperName == 'check_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.TextValue = 'Range';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec5);
                }
            }
            insert svcCatalogReqExtdAttrValList2;
        }
    
    //tests executeCallout method for single check
    @IsTest 
    static void testExecuteCalloutSingleCheck() {
        SvcCatalogRequest catalogReq = [SELECT Id FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201, 'Success', '"amount":"2000", "checkDate":"05/08/2023", "checkNumber":"632551001", "payee":"Bob", "reason":"Lost checkbook", "status":"Stopped"', headers));
        try {
            industriesintegrationfwk.IntegrationCalloutResponse  calloutResponse = StopCheckPaymentIntegrationProvider.executeCallout('6533875', catalogReq.Id, null, attributes);
            System.assertEquals(calloutResponse.isSuccess(), true);
            System.assertEquals(calloutResponse.getErrorMessage(), null);
        } catch (CalloutException ex) {
            System.assertEquals(true, isExpectedSecurityWrappedException(ex), ex.getMessage());
        }
        Test.stopTest();
    }
    
    //tests executeCallout method for range
    @IsTest 
    static void testExecuteCalloutRangeCheck() {
        SvcCatalogRequest catalogReq = [SELECT Id FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog1' LIMIT 1];
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201, 'Success', '"highestCheckNumber":"632551003", "lowestCheckNumber":"632551001", "reason":"Lost checkbook", "status":"Stopped"', headers));
        try {
            industriesintegrationfwk.IntegrationCalloutResponse  calloutResponse = StopCheckPaymentIntegrationProvider.executeCallout('6533875', catalogReq.Id, null, attributes);
            System.assertEquals(calloutResponse.isSuccess(), true);
            System.assertEquals(calloutResponse.getErrorMessage(), null);
        } catch (CalloutException ex) {
            System.assertEquals(true, isExpectedSecurityWrappedException(ex), ex.getMessage());
        }
        Test.stopTest();
    }
    
    //tests the exception
    @IsTest 
    static void testExecuteCalloutExceptionRange() {
        SvcCatalogRequest catalogReq = [SELECT Id FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog1' LIMIT 1];
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        try {
            // Set mock callout class 
            Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201, 'Success', '"highestCheckNumber":"3243", "lowestCheckNumber":"3240", "reason":"Lost checkbook", "status":"Stopped"', headers));
            industriesintegrationfwk.IntegrationCalloutResponse  calloutResponse = StopCheckPaymentIntegrationProvider.executeCallout('6533875', '', null, attributes);
            System.assertEquals(calloutResponse.isSuccess(), false);
        } catch (Exception ex) {
            System.assertEquals(ex.getMessage(), 'Service Process ID is null');
        }
    }
    
    //test method for getProviderAttributes method
    @IsTest 
    static void testGetProviderAttributes() {
        List<industriesintegrationfwk.ApexProviderAttr> attr = StopCheckPaymentIntegrationProvider.getProviderAttributes();
        System.assertNotEquals(attr, null);
    }
}
