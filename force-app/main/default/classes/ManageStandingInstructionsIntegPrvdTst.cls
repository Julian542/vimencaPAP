/*************************
* @Class Name:- ManageStandingInstructionsIntegPrvdTst
* @Description:- This file includes tests response from method in ManageStandingInstructionsIntegPrvd.apex 
**************************/

@IsTest
public with sharing class ManageStandingInstructionsIntegPrvdTst {
    private static final String PERSON_ACCOUNT_URL_PATH_KEY = 'Person_Account_URL_Path';
    private static final Map<String, Object> ATTRIBUTES = new Map<String, Object> { PERSON_ACCOUNT_URL_PATH_KEY => '/api/customers/{recordId}'};

    private static Boolean isExpectedSecurityWrappedException(Exception ex) {
        return ex != null &&
            ex.getMessage() != null &&
            (ex.getMessage() == 'Script-thrown exception' ||
             ex.getMessage().contains('secure query included inaccessible field'));
    }
                
    //This method creates the setup data
    @TestSetup
    static void createServiceCatalogReqData() {
        Map<String, String> headers = new Map<String, String>{ 'Content-Type' => 'application/json' };
        Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(200, 'Success', '{}', headers));
        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList1 = new List<SvcCatalogReqExtdAttrVal>();
        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList2 = new List<SvcCatalogReqExtdAttrVal>();
        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList3 = new List<SvcCatalogReqExtdAttrVal>();
        List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
        //insert a list of account from test data factory
        Integer intNumber = 3;
        List<Account> listAccount = FSCRetailTestDataFactory.createAccounts(intNumber);
        //insert a list of financial account from test data factory
        List<FinServ__FinancialAccount__c> listFinancialAccount = FSCRetailTestDataFactory.createFinancialAccounts(intNumber, listAccount);
        //insert list of Service Catalog Request from test data factory
        List<SvcCatalogRequest> listServiceCatalogReq = FSCRetailTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
        insert listServiceCatalogReq;        
        SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0'  LIMIT 1];
        SvcCatalogRequest svcCatalogRequestRec2 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog1'  LIMIT 1];
        SvcCatalogRequest svcCatalogRequestRec3 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog2'  LIMIT 1];
        
        for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
            if (svcCatAttr.DeveloperName == 'account_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec1.TextValue = 'XXXX-6210';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
            } else if (svcCatAttr.DeveloperName == 'amount') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec2.NumberValue = 100;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
            } else if (svcCatAttr.DeveloperName == 'account_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec3.TextValue = 'Savings Account';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec3);
            } else if (svcCatAttr.DeveloperName == 'payee_name') { 
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec4.TextValue = 'Netflix';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec4);
            } else if (svcCatAttr.DeveloperName == 'payee_account_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec5.TextValue = '4345324543';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
            } else if (svcCatAttr.DeveloperName == 'payee_routing_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec6.TextValue = 'CJJS54345';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec6);
            } else if (svcCatAttr.DeveloperName == 'standing_instruction_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec7.TextValue = 'Modify';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec7);
            } else if (svcCatAttr.DeveloperName == 'standing_instruction_id') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec8.TextValue = '506098';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec8);
            } else if (svcCatAttr.DeveloperName == 'currency_code') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec9.TextValue = 'USD';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec9);
            } else if (svcCatAttr.DeveloperName == 'remarks') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec10.TextValue = 'Test Modify Savings Account Standing Instructions';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec10);
            } else if (svcCatAttr.DeveloperName == 'start_date') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec11.TextValue = '11/12/2022';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec11);
            } else if (svcCatAttr.DeveloperName == 'frequency') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec12.TextValue = 'Monthly';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec12);
            } else if (svcCatAttr.DeveloperName == 'end_date') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec13.TextValue = '12/12/2022';
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec13);
            } else if (svcCatAttr.DeveloperName == 'number_of_installments') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec13.IntegerValue = 12;
                svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec13);
            } 
        }
        insert svcCatalogReqExtdAttrValList1;
        for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
            if (svcCatAttr.DeveloperName == 'account_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec1.TextValue = 'XXXX-6211';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec1);
            } else if (svcCatAttr.DeveloperName == 'amount') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec2.NumberValue = 100;
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec2);
            } else if (svcCatAttr.DeveloperName == 'account_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec3.TextValue = 'Checking Account';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec3);
            } else if (svcCatAttr.DeveloperName == 'payee_name') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec4.TextValue = 'Netflix';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec4);
            } else if (svcCatAttr.DeveloperName == 'payee_account_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec5.TextValue = '4345324543';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec5);
            } else if (svcCatAttr.DeveloperName == 'payee_routing_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec6.TextValue = 'CJJS54345';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec6);
            } else if (svcCatAttr.DeveloperName == 'standing_instruction_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec7.TextValue = 'Cancel';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec7);
            } else if (svcCatAttr.DeveloperName == 'standing_instruction_id') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec8.TextValue = '506098';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec8);
            } else if (svcCatAttr.DeveloperName == 'currency') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec9.TextValue = 'USD';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec9);
            } else if (svcCatAttr.DeveloperName == 'remarks') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec10.TextValue = 'Test Cancel Checking Account Standing Instructions';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec10);
            } else if (svcCatAttr.DeveloperName == 'start_date') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec11.TextValue = '11/12/2022';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec11);
            } else if (svcCatAttr.DeveloperName == 'frequency') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec12.TextValue = 'Monthly';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec12);
            } else if (svcCatAttr.DeveloperName == 'end_date') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec13.TextValue = '12/12/2022';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec13);
            }
        }
        insert svcCatalogReqExtdAttrValList2;
        for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
            if (svcCatAttr.DeveloperName == 'account_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec1.TextValue = 'XXXX-6212';
                svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec1);
            } else if (svcCatAttr.DeveloperName == 'amount') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec2.NumberValue = 100;
                svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec2);
            } else if (svcCatAttr.DeveloperName == 'account_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec3.TextValue = 'Checking Account';
                svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec3);
            } else if (svcCatAttr.DeveloperName == 'payee_name') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec4.TextValue = 'Netflix';
                svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec4);
            } else if (svcCatAttr.DeveloperName == 'payee_account_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec5.TextValue = '4345324543';
                svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec5);
            } else if (svcCatAttr.DeveloperName == 'payee_routing_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec6.TextValue = 'CJJS54345';
                svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec6);
            } else if (svcCatAttr.DeveloperName == 'standing_instruction_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec7.TextValue = 'Add';
                svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec7);
            } else if (svcCatAttr.DeveloperName == 'standing_instruction_id') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec8.TextValue = '506098';
                svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec8);
            } else if (svcCatAttr.DeveloperName == 'currency') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec9.TextValue = 'USD';
                svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec9);
            } else if (svcCatAttr.DeveloperName == 'remarks') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec10.TextValue = 'Test Cancel Checking Account Standing Instructions';
                svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec10);
            } else if (svcCatAttr.DeveloperName == 'start_date') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec11.TextValue = '11/12/2022';
                svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec11);
            } else if (svcCatAttr.DeveloperName == 'frequency') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec12.TextValue = 'Monthly';
                svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec12);
            } else if (svcCatAttr.DeveloperName == 'end_date') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec3.Id;
                svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec13.TextValue = '12/12/2022';
                svcCatalogReqExtdAttrValList3.add(svcCatalogReqExtdAttrValRec13);
            }
        }
        insert svcCatalogReqExtdAttrValList3;
    }
    
    //tests executeCallout method
    @IsTest static void testExecuteCalloutModify() {
        SvcCatalogRequest catalogReq = [SELECT Id FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        Map<String,String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201,'Success','{ "StandingOrderId": "SOT00010000", "CreationDateTime": "2023-06-27T11:56:59.001502Z", "Payments": { "PaymentType": "standing order", "PaymentDefinition": { "PaymentAmount": { "Amount": "1000", "Currency": "USD" } }, "PaymentSchedule": { "PaymentStartDate": "10/25/2023", "PaymentEndDate": "10/25/2024", "PaymentFrequency": "MONTHLY", "NumberOfPayments": "12" }, "PayeeReference": { "PayeeName": "Amazon" }, "PaymentPurpose": "Standing instruction for phone bill 1000 USD", "PayeeBankReference": { "RoutingNumber": "2000123008" }, "PayeeAccountReference": { "PayeeAccountNumber": "AMZ10012" } } }',headers));
        try {
            industriesintegrationfwk.IntegrationCalloutResponse	 calloutResponse = ManageStandingInstructionsIntegPrvd.executeCallout('6533875',catalogReq.Id,null,ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), true);
            System.assertEquals(calloutResponse.getErrorMessage(), null);
        } catch (CalloutException ex) {
            System.assert(isExpectedSecurityWrappedException(ex), 'Unexpected exception: ' + ex.getMessage());
        }
        Test.stopTest();
    }
    
    //tests executeCallout method
    @IsTest static void testExecuteCalloutCancel() {
        SvcCatalogRequest catalogReq = [SELECT Id FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog1' LIMIT 1];
        Map<String,String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201,'Success','{ "StandingInstructionId": "SOT00010000", "CreationDateTime": "2023-06-27T11:56:59.001502Z", "Payments": { "PaymentType": "standing order", "PaymentDefinition": { "PaymentAmount": { "Amount": "1000", "Currency": "USD" } }, "PaymentSchedule": { "PaymentStartDate": "10/25/2023", "PaymentEndDate": "10/25/2024", "PaymentFrequency": "MONTHLY", "NumberOfPayments": "12" }, "PayeeReference": { "PayeeName": "Amazon" }, "PaymentPurpose": "Standing instruction for phone bill 1000 USD", "PayeeBankReference": { "RoutingNumber": "2000123008" }, "PayeeAccountReference": { "PayeeAccountNumber": "AMZ10012" } } }',headers));
        try {
            industriesintegrationfwk.IntegrationCalloutResponse	 calloutResponse = ManageStandingInstructionsIntegPrvd.executeCallout('6533875',catalogReq.Id,null,ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), true);
            System.assertEquals(calloutResponse.getErrorMessage(), null);
        } catch (CalloutException ex) {
            System.assert(isExpectedSecurityWrappedException(ex), 'Unexpected exception: ' + ex.getMessage());
        }
        Test.stopTest();
    }
    
    //tests executeCallout method
    @IsTest static void testExecuteCalloutAdd() {
        SvcCatalogRequest catalogReq = [SELECT Id FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog2' LIMIT 1];
        Map<String,String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201,'Success','{ "StandingInstructionId": "SOT00010000", "CreationDateTime": "2023-06-27T11:56:59.001502Z", "Payments": { "PaymentType": "standing order", "PaymentDefinition": { "PaymentAmount": { "Amount": "1000", "Currency": "USD" } }, "PaymentSchedule": { "PaymentStartDate": "10/25/2023", "PaymentEndDate": "10/25/2024", "PaymentFrequency": "MONTHLY", "NumberOfPayments": "12" }, "PayeeReference": { "PayeeName": "Amazon" }, "PaymentPurpose": "Standing instruction for phone bill 1000 USD", "PayeeBankReference": { "RoutingNumber": "2000123008" }, "PayeeAccountReference": { "PayeeAccountNumber": "AMZ10012" } } }',headers));
        try {
            industriesintegrationfwk.IntegrationCalloutResponse	 calloutResponse = ManageStandingInstructionsIntegPrvd.executeCallout('6533875',catalogReq.Id,null,ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), true);
            System.assertEquals(calloutResponse.getErrorMessage(), null);
        } catch (CalloutException ex) {
            System.assert(isExpectedSecurityWrappedException(ex), 'Unexpected exception: ' + ex.getMessage());
        }
        Test.stopTest();
    }
    
    //tests the exception
    @IsTest static void testExecuteCalloutException() {
        Map<String,String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        try {
            // Set mock callout class 
            Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201,'Success','{ "StandingInstructionId": "SOT00010000", "CreationDateTime": "2023-06-27T11:56:59.001502Z", "Payments": { "PaymentType": "standing order", "PaymentDefinition": { "PaymentAmount": { "Amount": "1000", "Currency": "USD" } }, "PaymentSchedule": { "PaymentStartDate": "10/25/2023", "PaymentEndDate": "10/25/2024", "PaymentFrequency": "MONTHLY", "NumberOfPayments": "12" }, "PayeeReference": { "PayeeName": "Amazon" }, "PaymentPurpose": "Standing instruction for phone bill 1000 USD", "PayeeBankReference": { "RoutingNumber": "2000123008" }, "PayeeAccountReference": { "PayeeAccountNumber": "AMZ10012" } } }',headers));
            industriesintegrationfwk.IntegrationCalloutResponse	 calloutResponse = ManageStandingInstructionsIntegPrvd.executeCallout('6533875','',null,ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), false);
        }
        catch(Exception ex) {
            System.assertEquals(ex.getMessage(), 'Service Process ID is null');
        }
    }
    
    @IsTest static void testgetProviderAttributes() {
        List<industriesintegrationfwk.ApexProviderAttr> attr = ManageStandingInstructionsIntegPrvd.getProviderAttributes();
        System.assertNotEquals(attr, null);
    }
}
