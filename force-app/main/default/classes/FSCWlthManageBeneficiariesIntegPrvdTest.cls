/*************************
* @Class Name:- FSCWlthManageBeneficiariesIntegPrvdTest
* @Description:- This file includes tests response from method in ManageBeneficiariesIntegrationProvider.apex
**************************/
@IsTest
public with sharing class FSCWlthManageBeneficiariesIntegPrvdTest {
    
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final Map<String, Object> ATTRIBUTES = new Map<String, Object> { NAMED_CREDENTIAL_KEY => 'FSCWlth_fsc_integrations_V1_0_0' };
        
        //tests executeCallout method to add beneficiary
        @IsTest 
        static void testExecuteCalloutAddBeneficary() {
            
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList1 = new List<SvcCatalogReqExtdAttrVal>();
            List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
            Integer intNumber = 2;
            List<Account> listAccount = FSCWlthTestDataFactory.createAccounts(intNumber);     
           
            //insert list of Service Catalog Request from test data factory
            List<SvcCatalogRequest> listServiceCatalogReq = FSCWlthTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
            insert listServiceCatalogReq;
           
            SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
            
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'beneficiary_mobile_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = '+9172772727';
                    svcCatalogReqExtdAttrValRec1.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_relationship_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'Son';
                    svcCatalogReqExtdAttrValRec2.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = 'Individual';
                    svcCatalogReqExtdAttrValRec3.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_email') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.GroupNumber = 1;
                    svcCatalogReqExtdAttrValRec4.TextValue = 'test2test.com';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec4);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_birth_date_incorporation') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.GroupNumber = 1;
                    svcCatalogReqExtdAttrValRec5.TextValue = '04/04/1994';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec6.TextValue = 'Tom';
                    svcCatalogReqExtdAttrValRec6.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec6);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_ssn') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec7.TextValue = '556-6778-0666';
                    svcCatalogReqExtdAttrValRec7.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec7);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_address_line_1') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec8.TextValue = '12 calf Street';
                    svcCatalogReqExtdAttrValRec8.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec8);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_address_line_2') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec9.TextValue = '12 California Street';
                    svcCatalogReqExtdAttrValRec9.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec9);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_city') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec10.TextValue = 'california';
                    svcCatalogReqExtdAttrValRec10.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec10);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_state') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec11.TextValue = 'CA';
                    svcCatalogReqExtdAttrValRec11.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec11);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_country') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec12.TextValue = 'UAS';
                    svcCatalogReqExtdAttrValRec12.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec12);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_postal_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec13.TextValue = '506098';
                    svcCatalogReqExtdAttrValRec13.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec13);
                } else if (svcCatAttr.DeveloperName == 'beneficiary_per_stirpes') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec14.TextValue = 'Yes';
                    svcCatalogReqExtdAttrValRec14.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec14);
                }  else if(svcCatAttr.DeveloperName == 'beneficiary_share_percentage'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec15.NumberValue = 100;
                    svcCatalogReqExtdAttrValRec15.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
                }  else if (svcCatAttr.DeveloperName == 'contingent_mobile_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec21 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec21.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec21.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec21.TextValue = '+9172772727';
                    svcCatalogReqExtdAttrValRec21.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec21);
                } else if (svcCatAttr.DeveloperName == 'contingent_relationship_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'Son';
                    svcCatalogReqExtdAttrValRec2.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'contingent_beneficiary_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = 'Individual';
                    svcCatalogReqExtdAttrValRec3.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'contingent_email') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.GroupNumber = 2;
                    svcCatalogReqExtdAttrValRec4.TextValue = 'test2test.com';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec4);
                } else if (svcCatAttr.DeveloperName == 'contingent_birth_date_incorporation') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.GroupNumber = 2;
                    svcCatalogReqExtdAttrValRec5.TextValue = '04/04/1994';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
                } else if (svcCatAttr.DeveloperName == 'contingent_beneficiary_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec6.TextValue = 'Tim';
                    svcCatalogReqExtdAttrValRec6.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec6);
                } else if (svcCatAttr.DeveloperName == 'contingent_ssn') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec7.TextValue = '556-6778-0666';
                    svcCatalogReqExtdAttrValRec7.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec7);
                } else if (svcCatAttr.DeveloperName == 'contingent_address_line_1') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec8.TextValue = '12 calf Street';
                    svcCatalogReqExtdAttrValRec8.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec8);
                } else if (svcCatAttr.DeveloperName == 'contingent_address_line_2') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec9.TextValue = '12 California Street';
                    svcCatalogReqExtdAttrValRec9.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec9);
                } else if (svcCatAttr.DeveloperName == 'contingent_city') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec10.TextValue = 'california';
                    svcCatalogReqExtdAttrValRec10.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec10);
                } else if (svcCatAttr.DeveloperName == 'contingent_state') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec11.TextValue = 'CA';
                    svcCatalogReqExtdAttrValRec11.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec11);
                } else if (svcCatAttr.DeveloperName == 'contingent_country') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec12.TextValue = 'UAS';
                    svcCatalogReqExtdAttrValRec12.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec12);
                } else if (svcCatAttr.DeveloperName == 'contingent_postal_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec13.TextValue = '506098';
                    svcCatalogReqExtdAttrValRec13.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec13);
                } else if (svcCatAttr.DeveloperName == 'contingent_per_stirpes') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec14.TextValue = 'Yes';
                    svcCatalogReqExtdAttrValRec14.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec14);
                }  else if(svcCatAttr.DeveloperName == 'contingent_share_percentage'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec15.NumberValue = 100;
                    svcCatalogReqExtdAttrValRec15.GroupNumber = 2;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
                }   else if (svcCatAttr.DeveloperName == 'account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec22 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec22.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec22.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec22.TextValue = 'XXXX-6210';
                    svcCatalogReqExtdAttrValRec22.GroupNumber = 3;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec22);
                } else if (svcCatAttr.DeveloperName == 'has_contingent_beneficiaries') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec23 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec23.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec23.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec23.TextValue = 'Yes';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec23);
                }
            }
            insert svcCatalogReqExtdAttrValList1;
            
            Map<String,String> headers = new Map<String, String>();
            headers.put('Content-Type', 'application/json');
            Test.startTest();
            // Set mock callout class 
            Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(201,'Success','“statement”:{“endDate”:”06/16/2023”, “sendVia”:{“emailId”:”john.doe@gmail.com”, “shippingAddress”{“addressLine1”:”12 California Street”,“addressLine2”:”12B Apartment”, “addressType”:”Shipping Address”, “city”:”California”, “countryCode”:”India”, “postalCode”:”281004”, “state”:”CA”}, “shippingPreference”:”Standard”}, “startDate”:”5/21/2023”}',headers));
            try {
                industriesintegrationfwk.IntegrationCalloutResponse calloutResponse = FSCWlthManageBeneficiariesIntegProvider.executeCallout('6533875', svcCatalogRequestRec1.Id, null, ATTRIBUTES);
                System.assertEquals(true, calloutResponse.isSuccess());
                System.assertEquals(null, calloutResponse.getErrorMessage());
            } catch (CalloutException ex) {
                System.assertEquals('Script-thrown exception', ex.getMessage());
            }
            Test.stopTest();
        }
        
    //test method for getProviderAttributes method
    @IsTest 
    static void testgetProviderAttributes(){
        List<industriesintegrationfwk.ApexProviderAttr> attr = FSCWlthManageBeneficiariesIntegProvider.getProviderAttributes();
        System.assertNotEquals(attr, null);
    }
}
