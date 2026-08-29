/*************************
* @Class Name:- TransferFundsToOwnAccountIntegTest
* @Description:- This file includes tests response from method in TransferFundsToOwnAccountIntgnProvider.apex
**************************/

@IsTest
public with sharing class TransferFundsToOwnAccountIntegTest {
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final Map<String, Object> attributes = new Map<String, Object> { NAMED_CREDENTIAL_KEY => 'FSC_fsc_integrations_V1_0_0' };

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
        SvcCatalogRequest svcCatalogRequestRec = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName='TestCatalog0' LIMIT 1 ];
        
        for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
            if (svcCatAttr.DeveloperName == 'currency_code') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec1.TextValue = 'USD';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
            }
            else if (svcCatAttr.DeveloperName == 'payment_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec2.TextValue = 'One-time';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
            }
            else if (svcCatAttr.DeveloperName == 'amount') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec3.NumberValue = 123.8;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec3);
            }
            else if (svcCatAttr.DeveloperName == 'source_account_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec4.TextValue = 'XXXX-6210';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec4);
            }
            else if (svcCatAttr.DeveloperName == 'source_account_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec8.TextValue = 'Savings Account';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec8);
            }
            else if (svcCatAttr.DeveloperName == 'destination_account_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec5.TextValue = 'XXXX-6210';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
            }
            else if (svcCatAttr.DeveloperName == 'transfer_date') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec6.TextValue = '2022-08-12';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec6);
            }
            else if (svcCatAttr.DeveloperName == 'remarks') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec.Id;
                svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec7.TextValue = 'test';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec7);
            } 
        }
        insert svcCatalogReqExtdAttrValList1;
        
        SvcCatalogRequest svcCatalogRequestRec2 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName='TestCatalog1' LIMIT 1];
        for(SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr){
            if (svcCatAttr.DeveloperName == 'currency_code') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec1.TextValue = 'USD';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec1);
            }
            else if (svcCatAttr.DeveloperName == 'payment_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec2.TextValue = 'Recurring';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec2);
            }
            else if (svcCatAttr.DeveloperName == 'amount') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec3.NumberValue = 123.8;
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec3);
            }
            else if (svcCatAttr.DeveloperName == 'source_account_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRe4 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRe4.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRe4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRe4.TextValue = 'XXXX-6211';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRe4);
            }
            else if (svcCatAttr.DeveloperName == 'destination_account_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec5.TextValue = 'XXXX-6211';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec5);
            }
             else if (svcCatAttr.DeveloperName == 'source_account_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec11.TextValue = 'Savings Account';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec11);
            }
            else if (svcCatAttr.DeveloperName == 'start_date') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRe6 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRe6.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRe6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRe6.TextValue = '2022-08-12';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRe6);
            }
            else if (svcCatAttr.DeveloperName == 'remarks') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec7.TextValue = 'test';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec7);
            }
            else if (svcCatAttr.DeveloperName == 'end_date') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec8.TextValue = '2022-10-10';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec8);
            }
            else if (svcCatAttr.DeveloperName == 'frequency') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec9.TextValue = 'test';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec9);
            }
            else if (svcCatAttr.DeveloperName == 'installment') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec10.NumberValue = 5;
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec10);
            }
        }
        insert SvcCatalogReqExtdAttrValList2;
        
    }
    
    //tests executeCallout method for transfer funds (one-time)
    @isTest static void testExecuteCalloutTransferFunds() {
        SvcCatalogRequest catalogReq = [SELECT Id FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201, 'Success', '"amount": "678.87", "paymentSchedule": { "frequency": "Monthly", "instalment": "8", "paymentStartDate": "06/23/2023" }, "remarks": "recurring with instalment", "currency": "USD" , "payeeReferenceId": "3765476354632323", "payerReferenceId": "2343534545646453"', headers));
        try {
            industriesintegrationfwk.IntegrationCalloutResponse  calloutResponse = TransferFundsToOwnAccountIntegProvider.executeCallout('6533875', catalogReq.Id, null, attributes);
            System.assertEquals(calloutResponse.isSuccess(), true);
            System.assertEquals(calloutResponse.getErrorMessage(), null);
        } catch (CalloutException ex) {
            System.assertEquals(true, isExpectedSecurityWrappedException(ex), ex.getMessage());
        }
        Test.stopTest();
    }
    
    //tests executeCallout method for transfer funds (recurring)
    @isTest static void testExecuteCalloutRecurring() {
        SvcCatalogRequest catalogReq = [SELECT Id FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog1' LIMIT 1];
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201, 'Success', '"amount": "678.87", "paymentSchedule": { "frequency": "Monthly", "instalment": "8", "paymentStartDate": "06/23/2023" }, "remarks": "recurring with instalment", "currency": "USD" , "payeeReferenceId": "3765476354632323", "payerReferenceId": "2343534545646453"', headers));
        try {
            industriesintegrationfwk.IntegrationCalloutResponse  calloutResponse = TransferFundsToOwnAccountIntegProvider.executeCallout('6533875', catalogReq.Id, null, attributes);
            System.assertEquals(calloutResponse.isSuccess(), true);
            System.assertEquals(calloutResponse.getErrorMessage(), null);
        } catch (CalloutException ex) {
            System.assertEquals(true, isExpectedSecurityWrappedException(ex), ex.getMessage());
        }
        Test.stopTest();
    }
    
    //tests the exception
    @IsTest static void testExecuteCalloutExceptionRecurring() {
        SvcCatalogRequest catalogReq = [SELECT Id FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog1' LIMIT 1];
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        try {
            // Set mock callout class 
            Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201, 'Success', '"amount": "678.87", "paymentSchedule": { "frequency": "Monthly", "instalment": "8", "paymentStartDate": "06/23/2023" }, "remarks": "recurring with instalment", "currency": "USD" , "payeeReferenceId": "3765476354632323", "payerReferenceId": "2343534545646453"', headers));
            industriesintegrationfwk.IntegrationCalloutResponse  calloutResponse = TransferFundsToOwnAccountIntegProvider.executeCallout('6533875', '', null, null);
            System.assertEquals(calloutResponse.isSuccess(), false);
        }
        catch(Exception ex) {
            System.assertEquals(ex.getMessage(), 'Service Process ID is null');
        }
    }
    
    @IsTest static void testgetProviderAttributes() {
        List<industriesintegrationfwk.ApexProviderAttr> attr = TransferFundsToOwnAccountIntegProvider.getProviderAttributes();
        System.assertNotEquals(attr, null);
    }
}
