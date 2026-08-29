/*************************
* @Class Name:- FSCWlthinitAutomatedAcctTfrIntegTest
* @Description:- This file includes tests response from method in ManageBeneficiariesIntegrationProvider.apex
**************************/
@IsTest
public with sharing class FSCWlthinitAutomatedAcctTfrIntegTest {
    
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final Map<String, Object> ATTRIBUTES = new Map<String, Object> { NAMED_CREDENTIAL_KEY => 'FSC_wealth_integrations_V1_0_0' };

    private static Boolean isExpectedSecurityWrappedException(Exception ex) {
        return ex != null &&
            ex.getMessage() != null &&
            ex.getMessage() == 'Script-thrown exception';
    }

    private static void executeCalloutAndAssertSuccess(Id catalogRequestId) {
        try {
            industriesintegrationfwk.IntegrationCalloutResponse calloutResponse =
                FSCWlthInitAutomatedAcctTrfrIntegPrvd.executeCallout('6533875', catalogRequestId, null, ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), true);
            System.assertEquals(calloutResponse.getErrorMessage(), null);
        } catch (CalloutException ex) {
            System.assertEquals(true, isExpectedSecurityWrappedException(ex), ex.getMessage());
        }
    }
	        
        //This method creates the setup data
      @TestSetup
        static void createServiceCatalogReqData() {
            Map<String, String> headers = new Map<String, String>{ 'Content-Type' => 'application/json' };
            Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(200, 'Success', '{}', headers));
            
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList1 = new List<SvcCatalogReqExtdAttrVal>();
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList2 = new List<SvcCatalogReqExtdAttrVal>();
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList3 = new List<SvcCatalogReqExtdAttrVal>();
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList4 = new List<SvcCatalogReqExtdAttrVal>();
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList5 = new List<SvcCatalogReqExtdAttrVal>();
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList6 = new List<SvcCatalogReqExtdAttrVal>();
            List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
            Integer intNumber = 6;
            List<Account> listAccount = FSCWlthTestDataFactory.createAccounts(intNumber);     
            //insert a list of financial account from test data factory
            List<FinServ__FinancialAccount__c> listFinancialAccount = FSCWlthTestDataFactory.createFinancialAccounts(intNumber, listAccount);
            
            //insert list of Service Catalog Request from test data factory
            List<SvcCatalogRequest> listServiceCatalogReq = FSCWlthTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
            insert listServiceCatalogReq;

            SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0'  LIMIT 1];
            SvcCatalogRequest svcCatalogRequestRec2 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog1'  LIMIT 1];
            SvcCatalogRequest svcCatalogRequestRec3 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog2'  LIMIT 1];
            SvcCatalogRequest svcCatalogRequestRec4 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog3'  LIMIT 1];
            SvcCatalogRequest svcCatalogRequestRec5 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog4'  LIMIT 1];
            SvcCatalogRequest svcCatalogRequestRec6 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog5'  LIMIT 1];
            
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'transfer_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = 'Managed Account Transfer';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'financial_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'XXXX-6210';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'transfer_action') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = 'Transfer Inwards';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'external_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.TextValue = '45678';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec4);
                }  else if (svcCatAttr.DeveloperName == 'external_account_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.TextValue = 'test';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
                }  else if (svcCatAttr.DeveloperName == 'external_account_owner') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec6.TextValue = 'Test name';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec6);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec7.TextValue = 'ABC';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec7);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_phone') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec8.TextValue = '23232323';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec8);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_address') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec9.TextValue = '12 California Street';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec9);
                } else if (svcCatAttr.DeveloperName == 'transfer_entire_account') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec10.TextValue = 'Yes';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec10);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_city') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec11.TextValue = 'California';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec11);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_state') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec12.TextValue = 'CA';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec12);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_zip_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec13.TextValue = '506098';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec13);
                } else if (svcCatAttr.DeveloperName == 'mode') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec14.TextValue = 'Transfer all whole shares, sell fractions, and close account';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec14);
                }  else if (svcCatAttr.DeveloperName == 'transfer_option') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec15.TextValue = 'test';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
                }  else if (svcCatAttr.DeveloperName == 'transferring_firm_country') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec16 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec16.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec16.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec16.TextValue = 'USA';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec16);
                }
            }
            insert svcCatalogReqExtdAttrValList1;
             for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'transfer_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = 'Brokerage or Trust Company Transfer';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'financial_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'XXXX-6211';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'transfer_action') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = 'Transfer Inwards';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'external_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.TextValue = '45678';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec4);
                }  else if (svcCatAttr.DeveloperName == 'external_account_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.TextValue = 'test';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec5);
                }  else if (svcCatAttr.DeveloperName == 'external_account_owner') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec6.TextValue = 'Test name';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec6);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec7.TextValue = 'ABC';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec7);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_phone') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec8.TextValue = '23232323';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec8);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_address') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec9.TextValue = '12 California Street';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec9);
                } else if (svcCatAttr.DeveloperName == 'transfer_entire_account') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec10.TextValue = 'No';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec10);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_city') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec11.TextValue = 'California';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec11);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_state') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec12.TextValue = 'CA';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec12);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_zip_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec13.TextValue = '506098';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec13);
                } else if (svcCatAttr.DeveloperName == 'amount_mode') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec14.TextValue = 'Test';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec14);
                } else if (svcCatAttr.DeveloperName == 'security') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec15.TextValue = 'Yes';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec15);
                }  else if (svcCatAttr.DeveloperName == 'cash') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec16 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec16.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec16.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec16.TextValue = 'Yes';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec16);
                }  else if (svcCatAttr.DeveloperName == 'amount') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec17 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec17.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec17.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec17.NumberValue = 34;
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec17);
                }  else if (svcCatAttr.DeveloperName == 'currency_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec18 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec18.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec18.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec18.TextValue = 'USD';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec18);
                }  else if (svcCatAttr.DeveloperName == 'maturity_annuity_date') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec19 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec19.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec19.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec19.TextValue = '12/09/2022';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec19);
                }  else if (svcCatAttr.DeveloperName == 'number_of_shares') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec20 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec20.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec20.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec20.NumberValue = 4;
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec20);
                }  else if (svcCatAttr.DeveloperName == 'security_fund_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec21 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec21.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec21.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec21.TextValue = 'Test 500 Index Fund';
                    svcCatalogReqExtdAttrValRec21.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec21);
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec25 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec25.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec25.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec25.TextValue = 'Test 400 Index Fund';
                    svcCatalogReqExtdAttrValRec25.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec25);
                }  else if (svcCatAttr.DeveloperName == 'quantity_mode') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec22 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec22.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec22.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec22.TextValue = 'Custom';
                    svcCatalogReqExtdAttrValRec22.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec22);
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec26 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec26.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec26.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec26.TextValue = 'All';
                    svcCatalogReqExtdAttrValRec26.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec26);
                } else if (svcCatAttr.DeveloperName == 'number_of_units') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec23 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec23.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec23.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec23.NumberValue = 2;
                    svcCatalogReqExtdAttrValRec23.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec23);
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec27 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec27.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec27.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec27.NumberValue = 2;
                    svcCatalogReqExtdAttrValRec27.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec27);
                } else if (svcCatAttr.DeveloperName == 'financial_instrument_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec24 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec24.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec24.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec24.TextValue = '343434';
                    svcCatalogReqExtdAttrValRec24.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec24);
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec28 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec28.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec28.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec28.TextValue = '343434';
                    svcCatalogReqExtdAttrValRec28.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec28);
                } 
            }
            insert svcCatalogReqExtdAttrValList2;            
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'transfer_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = 'Mutual Fund Company Account Transfer';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'financial_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'XXXX-6212';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'transfer_action') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = 'Transfer Inwards';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'external_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.TextValue = '45678';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec4);
                }  else if (svcCatAttr.DeveloperName == 'external_account_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.TextValue = 'test';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec5);
                }  else if (svcCatAttr.DeveloperName == 'external_account_owner') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec6.TextValue = 'Test name';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec6);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec7.TextValue = 'ABC';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec7);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_phone') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec8.TextValue = '23232323';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec8);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_address') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec9.TextValue = '12 California Street';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec9);
                } else if (svcCatAttr.DeveloperName == 'transfer_entire_account') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec10.TextValue = 'No';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec10);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_city') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec11.TextValue = 'California';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec11);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_state') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec12.TextValue = 'CA';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec12);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_zip_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec13.TextValue = '506098';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec13);
                } else if (svcCatAttr.DeveloperName == 'amount_mode') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec14.TextValue = 'Test';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec14);
                } else if (svcCatAttr.DeveloperName == 'security') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec15.TextValue = 'Yes';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec15);
                }  else if (svcCatAttr.DeveloperName == 'cash') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec16 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec16.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec16.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec16.TextValue = 'Yes';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec16);
                }  else if (svcCatAttr.DeveloperName == 'amount') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec17 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec17.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec17.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec17.NumberValue = 34;
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec17);
                }  else if (svcCatAttr.DeveloperName == 'currency_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec18 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec18.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec18.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec18.TextValue = 'USD';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec18);
                }  else if (svcCatAttr.DeveloperName == 'maturity_annuity_date') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec19 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec19.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec19.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec19.TextValue = '12/09/2022';
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec19);
                }  else if (svcCatAttr.DeveloperName == 'number_of_shares') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec20 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec20.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec20.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec20.NumberValue = 4;
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec20);
                }  else if (svcCatAttr.DeveloperName == 'security_fund_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec21 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec21.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec21.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec21.TextValue = 'Test 500 Index Fund';
                    svcCatalogReqExtdAttrValRec21.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec21);
                }  else if (svcCatAttr.DeveloperName == 'quantity_mode') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec22 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec22.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec22.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec22.TextValue = 'Custom';
                    svcCatalogReqExtdAttrValRec22.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec22);
                     SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec26 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec26.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec26.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec26.TextValue = 'All';
                    svcCatalogReqExtdAttrValRec26.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec26);
                } else if (svcCatAttr.DeveloperName == 'number_of_units') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec23 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec23.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec23.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec23.NumberValue = 2;
                    svcCatalogReqExtdAttrValRec23.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec23);
                } else if (svcCatAttr.DeveloperName == 'financial_instrument_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec24 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec24.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec24.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec24.TextValue = '343434';
                    svcCatalogReqExtdAttrValRec24.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec24);
                } else if (svcCatAttr.DeveloperName == 'transfer_option') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec25 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec25.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                    svcCatalogReqExtdAttrValRec25.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec25.TextValue = 'test';
                    svcCatalogReqExtdAttrValRec25.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec25);
                } 
            }
            insert svcCatalogReqExtdAttrValList3;
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'transfer_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = 'Bank or Credit Union Account Transfer';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'financial_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'XXXX-6213';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'transfer_action') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = 'Transfer Inwards';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'external_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.TextValue = '45678';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec4);
                }  else if (svcCatAttr.DeveloperName == 'external_account_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.TextValue = 'test';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec5);
                }  else if (svcCatAttr.DeveloperName == 'external_account_owner') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec6.TextValue = 'Test name';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec6);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec7.TextValue = 'ABC';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec7);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_phone') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec8.TextValue = '23232323';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec8);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_address') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec9.TextValue = '12 California Street';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec9);
                } else if (svcCatAttr.DeveloperName == 'transfer_entire_account') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec10.TextValue = 'No';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec10);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_city') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec11.TextValue = 'California';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec11);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_state') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec12.TextValue = 'CA';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec12);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_zip_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec13.TextValue = '506098';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec13);
                } else if (svcCatAttr.DeveloperName == 'amount_mode') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec14.TextValue = 'Test';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec14);
                }  else if (svcCatAttr.DeveloperName == 'amount') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec15.NumberValue = 34;
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec15);
                }  else if (svcCatAttr.DeveloperName == 'currency_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec18 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec18.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec18.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec18.TextValue = 'USD';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec18);
                }  else if (svcCatAttr.DeveloperName == 'maturity_annuity_date') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec19 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec19.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec19.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec19.TextValue = '12/09/2022';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec19);
                }  else if (svcCatAttr.DeveloperName == 'number_of_shares') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec16 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec16.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec16.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec16.NumberValue = 4;
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec16);
                }  else if (svcCatAttr.DeveloperName == 'mode') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec17 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec17.SvcCatalogRequestId = svcCatalogRequestRec4.Id;
                    svcCatalogReqExtdAttrValRec17.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec17.TextValue = 'Transfer partial cash amount';
                    svcCatalogReqExtdAttrValList4.add(svcCatalogReqExtdAttrValRec17);
                }
            }
            insert svcCatalogReqExtdAttrValList4;
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'transfer_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = 'Annuity Transfer';
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'financial_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'XXXX-6214';
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'transfer_action') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = 'Transfer Inwards';
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'external_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.TextValue = '45678';
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec4);
                }  else if (svcCatAttr.DeveloperName == 'external_account_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.TextValue = 'test';
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec5);
                }  else if (svcCatAttr.DeveloperName == 'external_account_owner') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec6.TextValue = 'Test name';
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec6);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec7.TextValue = 'ABC';
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec7);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_phone') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec8.TextValue = '23232323';
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec8);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_address') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec9.TextValue = '12 California Street';
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec9);
                } else if (svcCatAttr.DeveloperName == 'transfer_entire_account') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec10.TextValue = 'No';
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec10);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_city') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec11.TextValue = 'California';
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec11);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_state') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec12.TextValue = 'CA';
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec12);
                } else if (svcCatAttr.DeveloperName == 'transferring_firm_zip_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec13.TextValue = '506098';
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec13);
                } else if (svcCatAttr.DeveloperName == 'amount') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec15.NumberValue = 34;
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec15);
                }  else if (svcCatAttr.DeveloperName == 'currency_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec14.TextValue = 'USD';
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec14);
                } else if (svcCatAttr.DeveloperName == 'mode') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec16 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec16.SvcCatalogRequestId = svcCatalogRequestRec5.Id;
                    svcCatalogReqExtdAttrValRec16.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec16.TextValue = 'Partial Annuity Surrender';
                    svcCatalogReqExtdAttrValList5.add(svcCatalogReqExtdAttrValRec16);
                }
            }
            insert svcCatalogReqExtdAttrValList5;
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'transfer_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec6.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = 'Brokerage or Trust Company Transfer';
                    svcCatalogReqExtdAttrValList6.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'financial_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec6.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'XXXX-6011';
                    svcCatalogReqExtdAttrValList6.add(svcCatalogReqExtdAttrValRec2);
                } 
        }
            insert svcCatalogReqExtdAttrValList6;
        }     
    //tests executeCallout method for different modes
    @IsTest static void testExecuteCallout1() {
        
            SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0'  LIMIT 1];           
            Map<String,String> headers = new Map<String, String>();
            headers.put('Content-Type', 'application/json');
            Test.startTest();
            // Set mock callout class 
            Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(201,'Success','"{"AcatDetails":{"ExternalAccountDetails":{"TransferringFirmDetails":{"Address":{"CountryCode":"USA","PostalCode":"2323","City":"wewe","State":"wew","AddressLine1":"dd"},"Phone":"2323233","FirmName":"wewewe"},"AccountTitle":"dd","AccountType":"Individual","AccountNumber":"22"},"TransferAction":"Transfer Inwards","TransferDetails":{"ManagedAccountTransfer":{"SellFractions":{"TransferAll":"Yes"},"Shares":{"TransferAll":"Yes"},"CloseAccount":"Yes"}},"TransferType":"Managed Account Transfer"}}"', headers));
            executeCalloutAndAssertSuccess(svcCatalogRequestRec1.Id);
            Test.stopTest();
        }
    
     //tests executeCallout method for different modes
    @IsTest static void testExecuteCallout2() {
        SvcCatalogRequest svcCatalogRequestRec2 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog1'  LIMIT 1];        
        Map<String,String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(201,'Success','"{"AcatDetails":{"ExternalAccountDetails":{"TransferringFirmDetails":{"Address":{"CountryCode":"USA","PostalCode":"2323","City":"wewe","State":"wew","AddressLine1":"dd"},"Phone":"2323233","FirmName":"wewewe"},"AccountTitle":"dd","AccountType":"Individual","AccountNumber":"22"},"TransferAction":"Transfer Inwards","TransferDetails":{"ManagedAccountTransfer":{"SellFractions":{"TransferAll":"Yes"},"Shares":{"TransferAll":"Yes"},"CloseAccount":"Yes"}},"TransferType":"Managed Account Transfer"}}"', headers));
        executeCalloutAndAssertSuccess(svcCatalogRequestRec2.Id);
        Test.stopTest();
    }
    //tests executeCallout method for different modes
    @IsTest static void testExecuteCallout3() {
        SvcCatalogRequest svcCatalogRequestRec3 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog2'  LIMIT 1];        
        Map<String,String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(201,'Success','"{"AcatDetails":{"ExternalAccountDetails":{"TransferringFirmDetails":{"Address":{"CountryCode":"USA","PostalCode":"2323","City":"wewe","State":"wew","AddressLine1":"dd"},"Phone":"2323233","FirmName":"wewewe"},"AccountTitle":"dd","AccountType":"Individual","AccountNumber":"22"},"TransferAction":"Transfer Inwards","TransferDetails":{"ManagedAccountTransfer":{"SellFractions":{"TransferAll":"Yes"},"Shares":{"TransferAll":"Yes"},"CloseAccount":"Yes"}},"TransferType":"Managed Account Transfer"}}"', headers));
        executeCalloutAndAssertSuccess(svcCatalogRequestRec3.Id);
        Test.stopTest();
    }
     //tests executeCallout method for different modes
    @IsTest static void testExecuteCallout4() {
        SvcCatalogRequest svcCatalogRequestRec4 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog3'  LIMIT 1];        
        Map<String,String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(201,'Success','"{"AcatDetails":{"ExternalAccountDetails":{"TransferringFirmDetails":{"Address":{"CountryCode":"USA","PostalCode":"2323","City":"wewe","State":"wew","AddressLine1":"dd"},"Phone":"2323233","FirmName":"wewewe"},"AccountTitle":"dd","AccountType":"Individual","AccountNumber":"22"},"TransferAction":"Transfer Inwards","TransferDetails":{"ManagedAccountTransfer":{"SellFractions":{"TransferAll":"Yes"},"Shares":{"TransferAll":"Yes"},"CloseAccount":"Yes"}},"TransferType":"Managed Account Transfer"}}"', headers));
        executeCalloutAndAssertSuccess(svcCatalogRequestRec4.Id);
        Test.stopTest();
    }
    //tests executeCallout method for different modes
    @IsTest static void testExecuteCallout5() {
        SvcCatalogRequest svcCatalogRequestRec5 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog4'  LIMIT 1];        
        Map<String,String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(201,'Success','"{"AcatDetails":{"ExternalAccountDetails":{"TransferringFirmDetails":{"Address":{"CountryCode":"USA","PostalCode":"2323","City":"wewe","State":"wew","AddressLine1":"dd"},"Phone":"2323233","FirmName":"wewewe"},"AccountTitle":"dd","AccountType":"Individual","AccountNumber":"22"},"TransferAction":"Transfer Inwards","TransferDetails":{"ManagedAccountTransfer":{"SellFractions":{"TransferAll":"Yes"},"Shares":{"TransferAll":"Yes"},"CloseAccount":"Yes"}},"TransferType":"Managed Account Transfer"}}"', headers));
        executeCalloutAndAssertSuccess(svcCatalogRequestRec5.Id);
        Test.stopTest();
    }
     @IsTest static void testExecuteCalloutException() {
        Map<String,String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        try {
            // Set mock callout class 
            Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(201,'Success','"{"AcatDetails":{"ExternalAccountDetails":{"TransferringFirmDetails":{"Address":{"CountryCode":"USA","PostalCode":"2323","City":"wewe","State":"wew","AddressLine1":"dd"},"Phone":"2323233","FirmName":"wewewe"},"AccountTitle":"dd","AccountType":"Individual","AccountNumber":"22"},"TransferAction":"Transfer Inwards","TransferDetails":{"ManagedAccountTransfer":{"SellFractions":{"TransferAll":"Yes"},"Shares":{"TransferAll":"Yes"},"CloseAccount":"Yes"}},"TransferType":"Managed Account Transfer"}}"', headers));
            industriesintegrationfwk.IntegrationCalloutResponse	 calloutResponse = FSCWlthInitAutomatedAcctTrfrIntegPrvd.executeCallout('6533875','',null,ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), false);
        }
        catch(Exception ex) {
            System.assertEquals(ex.getMessage(), 'Service Process ID is null');
        }
    }

    @IsTest static void testExecuteCalloutException2() {
        SvcCatalogRequest svcCatalogRequestRec6 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog5'  LIMIT 1];        
        Map<String,String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        try {
            // Set mock callout class 
            Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(201,'Success','"{"AcatDetails":{"ExternalAccountDetails":{"TransferringFirmDetails":{"Address":{"CountryCode":"USA","PostalCode":"2323","City":"wewe","State":"wew","AddressLine1":"dd"},"Phone":"2323233","FirmName":"wewewe"},"AccountTitle":"dd","AccountType":"Individual","AccountNumber":"22"},"TransferAction":"Transfer Inwards","TransferDetails":{"ManagedAccountTransfer":{"SellFractions":{"TransferAll":"Yes"},"Shares":{"TransferAll":"Yes"},"CloseAccount":"Yes"}},"TransferType":"Managed Account Transfer"}}"', headers));
            industriesintegrationfwk.IntegrationCalloutResponse	 calloutResponse = FSCWlthInitAutomatedAcctTrfrIntegPrvd.executeCallout('6533875',svcCatalogRequestRec6.Id,null,ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), false);
        }
        catch(Exception ex) {
            System.assertEquals(ex.getMessage(), 'Script-thrown exception');
        }
    }
    
    //test method for getProviderAttributes method
    @IsTest 
    static void testgetProviderAttributes(){
        List<industriesintegrationfwk.ApexProviderAttr> attr = FSCWlthManageStndInstrIntegProvider.getProviderAttributes();
        System.assertNotEquals(attr, null);
    }
}
