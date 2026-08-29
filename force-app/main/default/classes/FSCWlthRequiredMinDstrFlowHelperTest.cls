/*************************
* @Class Name:- FSCWlthRequiredMinDstrFlowHelperTest
* @Description:- This file includes tests response from method in FSCWlthRequiredMinDistributionFlowHelper.apex
**************************/
@IsTest
public with sharing class FSCWlthRequiredMinDstrFlowHelperTest {
    private static void assertExpectedSecurityException(QueryException ex) {
        System.assertEquals(
            true,
            ex.getMessage() != null && ex.getMessage().contains('secure query included inaccessible field'),
            ex.getMessage()
        );
    }
    
    //tests executeCallout method of Automated RMD with New EFT Account
    @IsTest 
    static void testAutomatedRMDNewEFT() {
        
        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList1 = new List<SvcCatalogReqExtdAttrVal>();
        List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
        Integer intNumber = 2;
        List<Account> listAccount = FSCWlthTestDataFactory.createAccounts(intNumber);     
        
        //insert list of Service Catalog Request from test data factory
        List<SvcCatalogRequest> listServiceCatalogReq = FSCWlthTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
        insert listServiceCatalogReq;
        
        SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        
        for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
            if (svcCatAttr.DeveloperName == 'payment_schedule') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec1.TextValue = 'Automated RMD';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
            } else if (svcCatAttr.DeveloperName == 'automated_rmd_option') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec2.TextValue = 'Autoated Annual Payment';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
            }  else if (svcCatAttr.DeveloperName == 'automated_rmd_date') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec5.TextValue = '12/12/2112';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
            }  else if (svcCatAttr.DeveloperName == 'payment_option') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec9.TextValue = 'New EFT Account';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec9);
            } else if (svcCatAttr.DeveloperName == 'bank_account_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec3.TextValue = 'AccNum1';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec3);
            } else if (svcCatAttr.DeveloperName == 'bank_routing_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec4.TextValue = 'RoutNum11';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec4);
            } else if (svcCatAttr.DeveloperName == 'bank_account_holder_name') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec6.TextValue = 'Owner Test';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec6);
            } else if (svcCatAttr.DeveloperName == 'bank_account_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec7.TextValue = 'Savings';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec7);
            } else if (svcCatAttr.DeveloperName == 'bank_name') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec8.TextValue = 'Bank Name';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec8);
            } else if (svcCatAttr.DeveloperName == 'bank_address') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec10.TextValue = 'address1,address2';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec10);
            } else if (svcCatAttr.DeveloperName == 'bank_zipcode') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec11.TextValue = '4567890';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec11);
            } else if(svcCatAttr.DeveloperName == 'bank_city'){
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec15.TextValue = 'city';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
            } else if(svcCatAttr.DeveloperName == 'bank_state'){
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec15.TextValue = 'NY';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
            } else if(svcCatAttr.DeveloperName == 'bank_country'){
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec15.TextValue = 'USA';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
            } else if (svcCatAttr.DeveloperName == 'tax_withholding_option') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec12.TextValue = 'Elect to have federal and state';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec12);
            } else if (svcCatAttr.DeveloperName == 'owners_state_of_residence') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec14.TextValue = 'State';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec14);
            }  else if(svcCatAttr.DeveloperName == 'federal_percentage'){
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec15.NumberValue = 20;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
            }  else if(svcCatAttr.DeveloperName == 'state_percentage'){
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec15.NumberValue = 20;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
            } 
        }
        insert svcCatalogReqExtdAttrValList1;
        
        Test.startTest();
        //Test (start) Invocable method of FSCWlthRequiredMinDistributionFlowHelper
        FSCWlthRequiredMinDistributionFlowHelper.flowInputs flowInputs = new FSCWlthRequiredMinDistributionFlowHelper.flowInputs();
        flowInputs.inputRecordId = svcCatalogRequestRec1.Id;
        List<FSCWlthRequiredMinDistributionFlowHelper.flowInputs> flowInputsList = new List<FSCWlthRequiredMinDistributionFlowHelper.flowInputs>();
        flowInputsList.add(flowInputs);
        try {
            List<String> output = FSCWlthRequiredMinDistributionFlowHelper.getPaymentDetails(flowInputsList);
            System.assertNotEquals(output, null);
        } catch (QueryException ex) {
            assertExpectedSecurityException(ex);
        }
        //Test (end) Invocable method of FSCWlthRequiredMinDistributionFlowHelper
        Test.stopTest();
    } 
    
    //tests executeCallout method of One-time RMD with check
    @IsTest 
    static void testOnetimeRMDwithCheck() {
        
        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList1 = new List<SvcCatalogReqExtdAttrVal>();
        List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
        Integer intNumber = 2;
        List<Account> listAccount = FSCWlthTestDataFactory.createAccounts(intNumber);     
        
        //insert list of Service Catalog Request from test data factory
        List<SvcCatalogRequest> listServiceCatalogReq = FSCWlthTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
        insert listServiceCatalogReq;
        
        SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        
        for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
            if (svcCatAttr.DeveloperName == 'payment_schedule') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec1.TextValue = 'One-Time RMD';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
            } else if (svcCatAttr.DeveloperName == 'tax_year') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec2.TextValue = '2023';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
            }  else if (svcCatAttr.DeveloperName == 'currency_code') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec5.TextValue = 'USD';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
            }  else if (svcCatAttr.DeveloperName == 'amount') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec9.NumberValue = 100;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec9);
            } else if (svcCatAttr.DeveloperName == 'payment_option') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec9.TextValue = 'Check';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec9);
            } else if (svcCatAttr.DeveloperName == 'bank_name') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec8.TextValue = 'Bank Name';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec8);
            } else if (svcCatAttr.DeveloperName == 'bank_address') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec10.TextValue = 'address1,address2';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec10);
            } else if (svcCatAttr.DeveloperName == 'bank_zipcode') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec11.TextValue = '4567890';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec11);
            } else if(svcCatAttr.DeveloperName == 'bank_city'){
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec15.TextValue = 'city';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
            } else if(svcCatAttr.DeveloperName == 'bank_state'){
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec15.TextValue = 'NY';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
            } else if(svcCatAttr.DeveloperName == 'bank_country'){
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec15.TextValue = 'USA';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
            } else if (svcCatAttr.DeveloperName == 'tax_withholding_option') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec12.TextValue = 'Elect not to have federal and state';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec12);
            } else if (svcCatAttr.DeveloperName == 'payee_name') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec14.TextValue = 'Payee Name';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec14);
            } else if (svcCatAttr.DeveloperName == 'amount_option') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec14.TextValue = 'Enter withdrawal amount';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec14);
            }  
        }
        insert svcCatalogReqExtdAttrValList1;
        
        Test.startTest();
        //Test (start) Invocable method of FSCWlthRequiredMinDistributionFlowHelper
        FSCWlthRequiredMinDistributionFlowHelper.flowInputs flowInputs = new FSCWlthRequiredMinDistributionFlowHelper.flowInputs();
        flowInputs.inputRecordId = svcCatalogRequestRec1.Id;
        List<FSCWlthRequiredMinDistributionFlowHelper.flowInputs> flowInputsList = new List<FSCWlthRequiredMinDistributionFlowHelper.flowInputs>();
        flowInputsList.add(flowInputs);
        try {
            List<String> output = FSCWlthRequiredMinDistributionFlowHelper.getPaymentDetails(flowInputsList);
            System.assertNotEquals(output, null);
        } catch (QueryException ex) {
            assertExpectedSecurityException(ex);
        }
        //Test (end) Invocable method of FSCWlthRequiredMinDistributionFlowHelper
        Test.stopTest();
    } 
}
