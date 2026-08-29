/*************************
* @Class Name:- ManageBeneficiariesIntgnProviderTest
* @Description:- This file includes tests response from method in ManageBeneficiariesIntegrationProvider.apex
**************************/
@IsTest
public with sharing class ManageBeneficiariesIntgnProviderTest {
    
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final Map<String, Object> ATTRIBUTES = new Map<String, Object> { NAMED_CREDENTIAL_KEY => 'FSC_fsc_integrations_V1_0_0' };
    private static void assertExpectedSecurityException(QueryException ex) {
        System.assertEquals(
            true,
            ex.getMessage() != null && ex.getMessage().contains('secure query included inaccessible field'),
            ex.getMessage()
        );
    }
        
        //tests executeCallout method to add beneficiary
        @IsTest 
        static void testExecuteCalloutAddBeneficary() {
            
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList1 = new List<SvcCatalogReqExtdAttrVal>();
            List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
            Integer intNumber = 2;
            List<Account> listAccount = FSCRetailTestDataFactory.createAccounts(intNumber);     
            //insert a list of financial account from test data factory
            List<FinServ__FinancialAccount__c> listFinancialAccount = FSCRetailTestDataFactory.createFinancialAccounts(intNumber, listAccount);
            
            //insert list of Service Catalog Request from test data factory
            List<SvcCatalogRequest> listServiceCatalogReq = FSCRetailTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
            insert listServiceCatalogReq;
            
            //insert list of Financial Account Role from test data factory
            List<FinServ__FinancialAccountRole__c> listFinAccRole = FSCRetailTestDataFactory.createFinancialAccRole(1, listAccount, listFinancialAccount);
            
            SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
            
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'beneficiary_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = 'John Doe';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_birth_date') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = '08/16/2023';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'account_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = 'Checking Account';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.TextValue = 'XXXX-6210';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec4);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_relationship') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.GroupNumber = 1;
                    svcCatalogReqExtdAttrValRec5.TextValue = 'Father';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_mobile') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec6.TextValue = '765454534535';
                    svcCatalogReqExtdAttrValRec6.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec6);
                } else if (svcCatAttr.DeveloperName == 'is_beneficiary_minor') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec7.TextValue = 'Yes';
                    svcCatalogReqExtdAttrValRec7.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec7);
                } else if (svcCatAttr.DeveloperName == 'guardian_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec8.TextValue = 'Tim';
                    svcCatalogReqExtdAttrValRec8.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec8);
                } else if (svcCatAttr.DeveloperName == 'address_line_1') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec9.TextValue = '12 California Street';
                    svcCatalogReqExtdAttrValRec9.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec9);
                } else if (svcCatAttr.DeveloperName == 'address_line_2') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec10.TextValue = '12B Apartment';
                    svcCatalogReqExtdAttrValRec10.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec10);
                } else if (svcCatAttr.DeveloperName == 'city') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec11.TextValue = 'California';
                    svcCatalogReqExtdAttrValRec11.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec11);
                } else if (svcCatAttr.DeveloperName == 'state') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec12.TextValue = 'CA';
                    svcCatalogReqExtdAttrValRec12.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec12);
                } else if (svcCatAttr.DeveloperName == 'postal_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec13.TextValue = '506098';
                    svcCatalogReqExtdAttrValRec13.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec13);
                } else if (svcCatAttr.DeveloperName == 'country') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec14.TextValue = 'US';
                    svcCatalogReqExtdAttrValRec14.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec14);
                }  else if(svcCatAttr.DeveloperName == 'guardian_mobile'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec15.TextValue = '765453534545';
                    svcCatalogReqExtdAttrValRec15.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
                }   else if(svcCatAttr.DeveloperName == 'guardian_relationship'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec16 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec16.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec16.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec16.TextValue = 'Father';
                    svcCatalogReqExtdAttrValRec16.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec16);
                }  else if (svcCatAttr.DeveloperName == 'guardian_address_line_1') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec17 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec17.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec17.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec17.TextValue = '12 California Street';
                    svcCatalogReqExtdAttrValRec17.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec17);
                } else if (svcCatAttr.DeveloperName == 'guardian_address_line_2') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec18 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec18.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec18.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec18.TextValue = '12B Apartment';
                    svcCatalogReqExtdAttrValRec18.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec18);
                } else if (svcCatAttr.DeveloperName == 'guardian_city') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec19 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec19.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec19.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec19.TextValue = 'California';
                    svcCatalogReqExtdAttrValRec19.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec19);
                } else if (svcCatAttr.DeveloperName == 'guardian_state') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec20 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec20.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec20.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec20.TextValue = 'CA';
                    svcCatalogReqExtdAttrValRec20.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec20);
                } else if (svcCatAttr.DeveloperName == 'guardian_postal_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec21 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec21.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec21.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec21.TextValue = '506098';
                    svcCatalogReqExtdAttrValRec21.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec21);
                } else if (svcCatAttr.DeveloperName == 'guardian_country') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec22 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec22.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec22.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec22.TextValue = 'US';
                    svcCatalogReqExtdAttrValRec22.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec22);
                } else if (svcCatAttr.DeveloperName == 'action_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec23 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec23.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec23.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec23.TextValue = 'Add';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec23);
                }
            }
            insert svcCatalogReqExtdAttrValList1;
            
            Map<String,String> headers = new Map<String, String>();
            headers.put('Content-Type', 'application/json');
            Test.startTest();
            // Set mock callout class 
            Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201,'Success','“statement”:{“endDate”:”06/16/2023”, “sendVia”:{“emailId”:”john.doe@gmail.com”, “shippingAddress”{“addressLine1”:”12 California Street”,“addressLine2”:”12B Apartment”, “addressType”:”Shipping Address”, “city”:”California”, “countryCode”:”India”, “postalCode”:”281004”, “state”:”CA”}, “shippingPreference”:”Standard”}, “startDate”:”5/21/2023”}',headers));
            try {
                industriesintegrationfwk.IntegrationCalloutResponse	 calloutResponse = ManageBeneficiariesIntegrationProvider.executeCallout('6533875', svcCatalogRequestRec1.Id, null, ATTRIBUTES);
                System.assertEquals(calloutResponse.isSuccess(), true);
                System.assertEquals(calloutResponse.getErrorMessage(), null);
            } catch (CalloutException ex) {
                System.assertEquals('Script-thrown exception', ex.getMessage());
            }
            //Test (start) Invocable method of ManageBeneficiariesFlowHelperClass
            ManageBeneficiariesFlowHelperClass.flowInputs flowInputs = new ManageBeneficiariesFlowHelperClass.flowInputs();
            flowInputs.action = 'Add';
            flowInputs.inputRecordId = svcCatalogRequestRec1.Id;
            List<ManageBeneficiariesFlowHelperClass.flowInputs> flowInputsList = new List<ManageBeneficiariesFlowHelperClass.flowInputs>();
            flowInputsList.add(flowInputs);
            try {
                List<String> output = ManageBeneficiariesFlowHelperClass.getBeneficiariesList(flowInputsList);
                System.assertNotEquals(output, null);
            } catch (QueryException ex) {
                assertExpectedSecurityException(ex);
            }
            //Test (end) Invocable method of ManageBeneficiariesFlowHelperClass
            Test.stopTest();
        }
    
    //tests executeCallout method to delete beneficiary
    @IsTest 
    static void testExecuteCalloutDeleteBeneficary() {
        
        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList2 = new List<SvcCatalogReqExtdAttrVal>();
        List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
        Integer intNumber = 2;
        List<Account> listAccount = FSCRetailTestDataFactory.createAccounts(intNumber);     
        //insert a list of financial account from test data factory
        List<FinServ__FinancialAccount__c> listFinancialAccount = FSCRetailTestDataFactory.createFinancialAccounts(intNumber, listAccount);
        
        //insert list of Service Catalog Request from test data factory
        List<SvcCatalogRequest> listServiceCatalogReq = FSCRetailTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
        insert listServiceCatalogReq;
        
        //insert list of Financial Account Role from test data factory
        List<FinServ__FinancialAccountRole__c> listFinAccRole = FSCRetailTestDataFactory.createFinancialAccRole(1, listAccount, listFinancialAccount);
        
        SvcCatalogRequest svcCatalogRequestRec2 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
            if (svcCatAttr.DeveloperName == 'beneficiary_name_to_delete') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec1.TextValue = 'Test Account0';
                svcCatalogReqExtdAttrValRec1.GroupNumber = 1;
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec1);
            } else if (svcCatAttr.DeveloperName == 'mobile') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec2.TextValue = '65456456460';
                svcCatalogReqExtdAttrValRec2.GroupNumber = 1;
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec2);
            }  else if (svcCatAttr.DeveloperName == 'account_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec3.TextValue = 'Checking Account';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec3);
            } else if (svcCatAttr.DeveloperName == 'account_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec4.TextValue = 'XXXX-6210';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec4);
            } else if (svcCatAttr.DeveloperName == 'action_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec23 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec23.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                svcCatalogReqExtdAttrValRec23.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec23.TextValue = 'Delete';
                svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec23);
            }
        }
        insert svcCatalogReqExtdAttrValList2;
        
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        Test.startTest();
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new FSCRetailMockHttpResponseGenerator(201, 'Success', '"highestCheckNumber":"632551003", "lowestCheckNumber":"632551001", "reason":"Lost checkbook", "status":"Stopped"', headers));
        try {
            industriesintegrationfwk.IntegrationCalloutResponse  calloutResponse = ManageBeneficiariesIntegrationProvider.executeCallout('6533875', svcCatalogRequestRec2.Id, null, ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), true);
            System.assertEquals(calloutResponse.getErrorMessage(), null);
        } catch (CalloutException ex) {
            System.assertEquals('Script-thrown exception', ex.getMessage());
        }
        //Test (start) Invocable method of ManageBeneficiariesFlowHelperClass
        ManageBeneficiariesFlowHelperClass.flowInputs flowInputs = new ManageBeneficiariesFlowHelperClass.flowInputs();
        flowInputs.action = 'Delete';
        flowInputs.inputRecordId = svcCatalogRequestRec2.Id;
        List<ManageBeneficiariesFlowHelperClass.flowInputs> flowInputsList = new List<ManageBeneficiariesFlowHelperClass.flowInputs>();
        flowInputsList.add(flowInputs);
        try {
            List<String> output = ManageBeneficiariesFlowHelperClass.getBeneficiariesList(flowInputsList);
            System.assertNotEquals(output, null);
        } catch (QueryException ex) {
            assertExpectedSecurityException(ex);
        }
        //Test (end) Invocable method of ManageBeneficiariesFlowHelperClass
        Test.stopTest();
    }
    
    //test method for getProviderAttributes method
    @IsTest 
    static void testgetProviderAttributes(){
        List<industriesintegrationfwk.ApexProviderAttr> attr = ManageBeneficiariesIntegrationProvider.getProviderAttributes();
        System.assertNotEquals(attr, null);
    }
}
