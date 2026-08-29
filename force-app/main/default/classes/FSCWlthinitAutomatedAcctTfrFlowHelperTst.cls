/*************************
* @Class Name:- FSCWlthinitAutomatedAcctTfrFlowHelperTst
* @Description:- This file includes tests response from method in FSCWlthInitAutomatedAcctTfrFlowHelper.apex
**************************/
@IsTest
public with sharing class FSCWlthinitAutomatedAcctTfrFlowHelperTst {
    private static void assertExpectedSecurityException(QueryException ex) {
        System.assertEquals(
            true,
            ex.getMessage() != null && ex.getMessage().contains('secure query included inaccessible field'),
            ex.getMessage()
        );
    }
    
    //tests executeCallout method of Annuity Transfer type custom securities
    @IsTest 
    static void testExecuteAnnuityTransfer() {
        
        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList1 = new List<SvcCatalogReqExtdAttrVal>();
        List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
        Integer intNumber = 2;
        List<Account> listAccount = FSCWlthTestDataFactory.createAccounts(intNumber);     
        
        //insert list of Service Catalog Request from test data factory
        List<SvcCatalogRequest> listServiceCatalogReq = FSCWlthTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
        insert listServiceCatalogReq;
        
        SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        
        for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
            if (svcCatAttr.DeveloperName == 'transfer_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec1.TextValue = 'Annuity Transfer';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
            } else if (svcCatAttr.DeveloperName == 'amount') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec2.NumberValue = 500;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
            }  else if (svcCatAttr.DeveloperName == 'mode') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec5.TextValue = 'Transfer partial cash amount';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
            }  else if (svcCatAttr.DeveloperName == 'currency_code') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec9.TextValue = 'USD';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec9);
            } 
        }
        insert svcCatalogReqExtdAttrValList1;
        
        Test.startTest();
        //Test (start) Invocable method of FSCWlthInitAutomatedAcctTfrFlowHelper
        FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs flowInputs = new FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs();
        flowInputs.inputRecordId = svcCatalogRequestRec1.Id;
        List<FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs> flowInputsList = new List<FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs>();
        flowInputsList.add(flowInputs);
        try {
            List<String> output = FSCWlthInitAutomatedAcctTfrFlowHelper.getSecuritiesList(flowInputsList);
            System.assertNotEquals(output, null);
        } catch (QueryException ex) {
            assertExpectedSecurityException(ex);
        }
        //Test (end) Invocable method of FSCWlthInitAutomatedAcctTfrFlowHelper
        Test.stopTest();
    }
    
    //tests executeCallout method of Managed Account Transfer type custom securities
    @IsTest 
    static void testExecuteManagedAccTransfer() {
        
        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList1 = new List<SvcCatalogReqExtdAttrVal>();
        List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
        Integer intNumber = 2;
        List<Account> listAccount = FSCWlthTestDataFactory.createAccounts(intNumber);     
        
        //insert list of Service Catalog Request from test data factory
        List<SvcCatalogRequest> listServiceCatalogReq = FSCWlthTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
        insert listServiceCatalogReq;
        
        SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        
        for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
            if (svcCatAttr.DeveloperName == 'transfer_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec1.TextValue = 'Managed Account Transfer';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
            } else if (svcCatAttr.DeveloperName == 'numberOfShares') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec2.NumberValue = 500;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
            }  else if (svcCatAttr.DeveloperName == 'mode') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec5.TextValue = 'Transfer the following number of whole shares';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
            }  
        }
        insert svcCatalogReqExtdAttrValList1;
        
        Test.startTest();
        //Test (start) Invocable method of FSCWlthInitAutomatedAcctTfrFlowHelper
        FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs flowInputs = new FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs();
        flowInputs.inputRecordId = svcCatalogRequestRec1.Id;
        List<FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs> flowInputsList = new List<FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs>();
        flowInputsList.add(flowInputs);
        try {
            List<String> output = FSCWlthInitAutomatedAcctTfrFlowHelper.getSecuritiesList(flowInputsList);
            System.assertNotEquals(output, null);
        } catch (QueryException ex) {
            assertExpectedSecurityException(ex);
        }
        //Test (end) Invocable method of FSCWlthInitAutomatedAcctTfrFlowHelper
        Test.stopTest();
    }
    
    //tests executeCallout method of Brokerage Transfer type custom securities
    @IsTest 
    static void testExecuteBrokerageTransfer() {
        
        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList1 = new List<SvcCatalogReqExtdAttrVal>();
        List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
        Integer intNumber = 2;
        List<Account> listAccount = FSCWlthTestDataFactory.createAccounts(intNumber);     
        
        //insert list of Service Catalog Request from test data factory
        List<SvcCatalogRequest> listServiceCatalogReq = FSCWlthTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
        insert listServiceCatalogReq;
        
        SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        
        for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
            if (svcCatAttr.DeveloperName == 'transfer_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec1.TextValue = 'Brokerage or Trust Company Transfer';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
            } else if (svcCatAttr.DeveloperName == 'amount') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec2.NumberValue = 500;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
            } else if (svcCatAttr.DeveloperName == 'transfer_action') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec3.TextValue = 'Individual';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec3);
            } else if (svcCatAttr.DeveloperName == 'transfer_entire_account') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec4.TextValue = 'No';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec4);
            } else if (svcCatAttr.DeveloperName == 'mode') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec5.TextValue = 'test Mode value';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
            } else if (svcCatAttr.DeveloperName == 'amount_mode') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec6.TextValue = 'Custom';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec6);
            } else if (svcCatAttr.DeveloperName == 'security') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec7.TextValue = 'Yes';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec7);
            } else if (svcCatAttr.DeveloperName == 'cash') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec8.TextValue = 'Yes';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec8);
            } else if (svcCatAttr.DeveloperName == 'currency_code') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec9.TextValue = 'USD';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec9);
            } else if (svcCatAttr.DeveloperName == 'number_of_shares') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec10.NumberValue = 100;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec10);
            } else if (svcCatAttr.DeveloperName == 'maturity_annuity_date') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec11.TextValue = '12/12/1212';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec11);
            } else if (svcCatAttr.DeveloperName == 'security_fund_name') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec12.TextValue = 'FUND- fund name';
                svcCatalogReqExtdAttrValRec12.GroupNumber = 1;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec12);
            } else if (svcCatAttr.DeveloperName == 'number_of_units') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec14.NumberValue = 100;
                svcCatalogReqExtdAttrValRec14.GroupNumber = 1;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec14);
            }  else if(svcCatAttr.DeveloperName == 'quantity_mode'){
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec15.TextValue = 'Custom';
                svcCatalogReqExtdAttrValRec15.GroupNumber = 1;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
            }  
        }
        insert svcCatalogReqExtdAttrValList1;
        
        Test.startTest();
        //Test (start) Invocable method of FSCWlthInitAutomatedAcctTfrFlowHelper
        FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs flowInputs = new FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs();
        flowInputs.inputRecordId = svcCatalogRequestRec1.Id;
        List<FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs> flowInputsList = new List<FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs>();
        flowInputsList.add(flowInputs);
        try {
            List<String> output = FSCWlthInitAutomatedAcctTfrFlowHelper.getSecuritiesList(flowInputsList);
            System.assertNotEquals(output, null);
        } catch (QueryException ex) {
            assertExpectedSecurityException(ex);
        }
        //Test (end) Invocable method of FSCWlthInitAutomatedAcctTfrFlowHelper
        Test.stopTest();
    }
    
    //tests executeCallout method of Mutual Fund Transfer type custom securities
    @IsTest 
    static void testExecuteMutualFundTransfer() {
        
        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList1 = new List<SvcCatalogReqExtdAttrVal>();
        List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
        Integer intNumber = 2;
        List<Account> listAccount = FSCWlthTestDataFactory.createAccounts(intNumber);     
        
        //insert list of Service Catalog Request from test data factory
        List<SvcCatalogRequest> listServiceCatalogReq = FSCWlthTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
        insert listServiceCatalogReq;
        
        SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        
        for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
            if (svcCatAttr.DeveloperName == 'transfer_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec1.TextValue = 'Mutual Fund Company Account Transfer';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
            } else if (svcCatAttr.DeveloperName == 'transfer_action') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec3.TextValue = 'Individual';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec3);
            } else if (svcCatAttr.DeveloperName == 'transfer_entire_account') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec4.TextValue = 'No';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec4);
            } else if (svcCatAttr.DeveloperName == 'security_fund_name') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec12.TextValue = 'FUND- fund name';
                svcCatalogReqExtdAttrValRec12.GroupNumber = 1;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec12);
            } else if (svcCatAttr.DeveloperName == 'number_of_units') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec14.NumberValue = 100;
                svcCatalogReqExtdAttrValRec14.GroupNumber = 1;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec14);
            }  else if(svcCatAttr.DeveloperName == 'quantity_mode'){
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec15.TextValue = 'Custom';
                svcCatalogReqExtdAttrValRec15.GroupNumber = 1;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
            }  
        }
        insert svcCatalogReqExtdAttrValList1;
        
        Test.startTest();
        //Test (start) Invocable method of FSCWlthInitAutomatedAcctTfrFlowHelper
        FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs flowInputs = new FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs();
        flowInputs.inputRecordId = svcCatalogRequestRec1.Id;
        List<FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs> flowInputsList = new List<FSCWlthInitAutomatedAcctTfrFlowHelper.flowInputs>();
        flowInputsList.add(flowInputs);
        try {
            List<String> output = FSCWlthInitAutomatedAcctTfrFlowHelper.getSecuritiesList(flowInputsList);
            System.assertNotEquals(output, null);
        } catch (QueryException ex) {
            assertExpectedSecurityException(ex);
        }
        //Test (end) Invocable method of FSCWlthInitAutomatedAcctTfrFlowHelper
        Test.stopTest();
    }
    
}
