/*************************
* @Class Name:- FSCWlthSetupRequiredMinDstrIntegPrvdTest
* @Description:- This file includes tests response from method in FSCWlthSetupRequiredMinDstrIntegPrvd.apex
**************************/
@IsTest
public with sharing class FSCWlthSetupRequiredMinDstrIntegPrvdTest {
    
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final Map<String, Object> ATTRIBUTES = new Map<String, Object> { NAMED_CREDENTIAL_KEY => 'FSC_wealth_integrations_V1_0_0' };

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
	            
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList1 = new List<SvcCatalogReqExtdAttrVal>();
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList2 = new List<SvcCatalogReqExtdAttrVal>();
            
            List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
            Integer intNumber = 2;
            List<Account> listAccount = FSCWlthTestDataFactory.createAccounts(intNumber);     
            //insert a list of financial account from test data factory
            List<FinServ__FinancialAccount__c> listFinancialAccount = FSCWlthTestDataFactory.createFinancialAccounts(intNumber, listAccount);
            
            //insert list of Service Catalog Request from test data factory
            List<SvcCatalogRequest> listServiceCatalogReq = FSCWlthTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
            insert listServiceCatalogReq;
            
            SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0'  LIMIT 1];
            SvcCatalogRequest svcCatalogRequestRec2 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog1'  LIMIT 1];
            
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'financial_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = 'XXXX-6210';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'payment_schedule') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'One-time RMD';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'automated_rmd_option') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = 'AUTOMATED RMD';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'tax_year') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.TextValue = '2023';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec4);
                } else if (svcCatAttr.DeveloperName == 'currency_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.TextValue = 'USA';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
                } else if (svcCatAttr.DeveloperName == 'amount') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec6.IntegerValue = 23;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec6);
                } else if (svcCatAttr.DeveloperName == 'payment_option') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec7.TextValue = 'New EFT Account';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec7);
                } else if (svcCatAttr.DeveloperName == 'bank_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec8.TextValue = '24343545454555';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec8);
                } else if (svcCatAttr.DeveloperName == 'bank_routing_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec9.TextValue = '32432435';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec9);
                } else if (svcCatAttr.DeveloperName == 'bank_account_holder_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec10.TextValue = 'Julia Beck';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec10);
                } else if (svcCatAttr.DeveloperName == 'bank_account_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec11.TextValue = 'Checkings';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec11);
                } else if (svcCatAttr.DeveloperName == 'bank_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec12.TextValue = 'HDFC';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec12);
                } else if (svcCatAttr.DeveloperName == 'payee_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec13.TextValue = 'Phil Dunphy';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec13);
                } else if (svcCatAttr.DeveloperName == 'bank_address') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec14.TextValue = 'Hyde Park,Jersey City,New Jersey';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec14);
                } else if(svcCatAttr.DeveloperName == 'bank_zipcode'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec15.TextValue = '2342423';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
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
                } else if(svcCatAttr.DeveloperName == 'tax_withholding_option'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec16 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec16.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec16.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec16.TextValue = 'Elect to have federal and state';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec16);
                } else if(svcCatAttr.DeveloperName == 'federal_percentage'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec17 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec17.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec17.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec17.IntegerValue = 70;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec17);
                } else if(svcCatAttr.DeveloperName == 'state_percentage'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec18 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec18.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec18.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec18.IntegerValue = 30;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec18);
                } else if(svcCatAttr.DeveloperName == 'owners_state_of_residence'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec19 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec19.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec19.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec19.TextValue = 'Alabama';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec19);
                } else if(svcCatAttr.DeveloperName == 'amount_option'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec20 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec20.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec20.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec20.TextValue = 'Enter withdrawal amount';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec20);
                }   
            }
            insert svcCatalogReqExtdAttrValList1;
            
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'financial_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = 'XXXX-6211';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'payment_schedule') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'Automated RMD';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'automated_rmd_option') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = 'Automated Annual payments';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'tax_year') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.TextValue = '2023';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec4);
                } else if (svcCatAttr.DeveloperName == 'currency_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.TextValue = 'USA';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec5);
                } else if (svcCatAttr.DeveloperName == 'amount') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec6.IntegerValue = 23;
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec6);
                } else if (svcCatAttr.DeveloperName == 'payment_option') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec7.TextValue = 'Check';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec7);
                } else if (svcCatAttr.DeveloperName == 'bank_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec8.TextValue = '23426677777';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec8);
                } else if (svcCatAttr.DeveloperName == 'bank_routing_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec9.TextValue = '12344555';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec9);
                } else if (svcCatAttr.DeveloperName == 'bank_account_holder_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec10.TextValue = 'Julia Smith';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec10);
                } else if (svcCatAttr.DeveloperName == 'bank_account_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec11.TextValue = 'Savings';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec11);
                } else if (svcCatAttr.DeveloperName == 'bank_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec12.TextValue = 'HDFC';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec12);
                } else if (svcCatAttr.DeveloperName == 'payee_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec13.TextValue = 'Josh Dunphy';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec13);
                } else if (svcCatAttr.DeveloperName == 'bank_address') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec14.TextValue = 'Hyde Park,Jersey City,New Jersey';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec14);
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
                } else if(svcCatAttr.DeveloperName == 'bank_zipcode'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec15.TextValue = '344453';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec15);
                } else if(svcCatAttr.DeveloperName == 'tax_withholding_option'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec16 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec16.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec16.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec16.TextValue = 'Elect to have federal and state';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec16);
                } else if(svcCatAttr.DeveloperName == 'federal_percentage'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec17 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec17.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec17.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec17.IntegerValue = 70;
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec17);
                } else if(svcCatAttr.DeveloperName == 'state_percentage'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec18 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec18.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec18.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec18.IntegerValue = 30;
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec18);
                } else if(svcCatAttr.DeveloperName == 'owners_state_of_residence'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec19 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec19.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec19.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec19.TextValue = 'Texas';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec19);
                }
            }
            insert svcCatalogReqExtdAttrValList2;
        }
    
    //tests executeCallout method
    @IsTest static void testExecuteCallout1() {
        SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0'  LIMIT 1];
        Map<String,String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(201,'Success','"{"PaymentInstructions":{"BankAddress":{"CountryCode":"USA","PostalCode":"456789","AddressLine1":"addressyy1"},"BankName":"Axis","PayeeName":"Automated with check","PaymentInstructionType":"BY_CHECK"},"DistributionSchedule":{"PaymentDate":"11/10/2023"},"PaymentFrequency":"SEMI-ANNUAL","PaymentOption":"AUTOMATED RMD"}"', headers));
        try {
            industriesintegrationfwk.IntegrationCalloutResponse	 calloutResponse = FSCWlthSetupRequiredMinDstrIntegPrvd.executeCallout('6533876', svcCatalogRequestRec1.Id, null, ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), true);
            System.assertEquals(calloutResponse.getErrorMessage(), null);
        } catch (CalloutException ex) {
            System.assertEquals(true, isExpectedSecurityWrappedException(ex), ex.getMessage());
        }
        Test.stopTest();
    }
    
    //tests executeCallout method
    @IsTest static void testExecuteCallout2() {
        SvcCatalogRequest svcCatalogRequestRec2 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog1'  LIMIT 1];
        Map<String,String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(201,'Success','"{"PaymentInstructions":{"BankAddress":{"CountryCode":"USA","PostalCode":"456789","AddressLine1":"addressyy1"},"BankName":"Axis","PayeeName":"Automated with check","PaymentInstructionType":"BY_CHECK"},"DistributionSchedule":{"PaymentDate":"11/10/2023"},"PaymentFrequency":"SEMI-ANNUAL","PaymentOption":"AUTOMATED RMD"}"', headers));
        try {
            industriesintegrationfwk.IntegrationCalloutResponse	 calloutResponse = FSCWlthSetupRequiredMinDstrIntegPrvd.executeCallout('6533877', svcCatalogRequestRec2.Id,null,ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), true);
            System.assertEquals(calloutResponse.getErrorMessage(), null);
        } catch (CalloutException ex) {
            System.assertEquals(true, isExpectedSecurityWrappedException(ex), ex.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest static void testExecuteCalloutException() {
        Map<String,String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        try {
            // Set mock callout class 
            Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(201,'Success','"{"PaymentInstructions":{"BankAddress":{"CountryCode":"USA","PostalCode":"456789","AddressLine1":"addressyy1"},"BankName":"Axis","PayeeName":"Automated with check","PaymentInstructionType":"BY_CHECK"},"DistributionSchedule":{"PaymentDate":"11/10/2023"},"PaymentFrequency":"SEMI-ANNUAL","PaymentOption":"AUTOMATED RMD"}"',headers));
            industriesintegrationfwk.IntegrationCalloutResponse	 calloutResponse = FSCWlthSetupRequiredMinDstrIntegPrvd.executeCallout('6533878','',null,ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), false);
        }
        catch(Exception ex) {
            System.assertEquals(ex.getMessage(), 'Service Process ID is null');
        }
    }
    
    //test method for getProviderAttributes method
    @IsTest 
    static void testgetProviderAttributes(){
        List<industriesintegrationfwk.ApexProviderAttr> attr = FSCWlthSetupRequiredMinDstrIntegPrvd.getProviderAttributes();
        System.assertNotEquals(attr, null);
    }
}
