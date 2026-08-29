/*************************
* @Class Name:- FSCWlthManageStndInstrFlowHelperTest
* @Description:- This file includes tests response from method in FSCWlthManageStndInstrFlowHelper.apex
**************************/
@IsTest
public class FSCWlthManageStndInstrFlowHelperTest {
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final Map<String, Object> ATTRIBUTES = new Map<String, Object> { NAMED_CREDENTIAL_KEY => 'FSCWlth_fsc_integrations_V1_0_0' };
    private static void assertExpectedSecurityException(QueryException ex) {
        System.assertEquals(
            true,
            ex.getMessage() != null && ex.getMessage().contains('secure query included inaccessible field'),
            ex.getMessage()
        );
    }
        //tests executeCallout method to add standing instruction
        @IsTest 
        static void testGetAddStandingInstructionList() {
            
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList = new List<SvcCatalogReqExtdAttrVal>();
            List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
            Integer intNumber = 1;
            List<Account> listAccount = FSCWlthTestDataFactory.createAccounts(intNumber);     
            //insert list of Service Catalog Request from test data factory
            List<SvcCatalogRequest> listServiceCatalogReq = FSCWlthTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
            insert listServiceCatalogReq;
            SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
            
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'standing_instruction_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = 'Add';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'mode') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'Wire Transfer';
                    svcCatalogReqExtdAttrValRec2.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'payee_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = 'Test Payee Name';
                    svcCatalogReqExtdAttrValRec3.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'payee_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.TextValue = 'ACCNo 12345';
                    svcCatalogReqExtdAttrValRec4.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec4);
                } else if (svcCatAttr.DeveloperName == 'bank_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.TextValue = 'Bank Name 1';
                    svcCatalogReqExtdAttrValRec5.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec5);
                } else if (svcCatAttr.DeveloperName == 'routing_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec6.TextValue = 'ROUTNO123';
                    svcCatalogReqExtdAttrValRec6.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec6);
                } else if (svcCatAttr.DeveloperName == 'payee_address') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec7.TextValue = 'Address line 1 and linne 2';
                    svcCatalogReqExtdAttrValRec7.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec7);
                } else if (svcCatAttr.DeveloperName == 'check_stub_information') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec8.TextValue = 'test';
                    svcCatalogReqExtdAttrValRec8.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec8);
                } else if (svcCatAttr.DeveloperName == 'memo') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec9.TextValue = 'Memo';
                    svcCatalogReqExtdAttrValRec9.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec9);
                } else if (svcCatAttr.DeveloperName == 'prefix') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec10.TextValue = 'Prefix.';
                    svcCatalogReqExtdAttrValRec10.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec10);
                } else if (svcCatAttr.DeveloperName == 'city') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec11.TextValue = 'test city';
                    svcCatalogReqExtdAttrValRec11.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec11);
                } else if (svcCatAttr.DeveloperName == 'state') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec12.TextValue = 'test state';
                    svcCatalogReqExtdAttrValRec12.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec12);
                } else if (svcCatAttr.DeveloperName == 'zip_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec13 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec13.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec13.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec13.TextValue = '567867';
                    svcCatalogReqExtdAttrValRec13.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec13);
                } else if (svcCatAttr.DeveloperName == 'country') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec14 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec14.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec14.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec14.TextValue = 'Country';
                    svcCatalogReqExtdAttrValRec14.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec14);
                } else if (svcCatAttr.DeveloperName == 'eft_account_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec15.TextValue = 'Savings';
                    svcCatalogReqExtdAttrValRec15.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec15);
                } else if (svcCatAttr.DeveloperName == 'currency_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec16 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec16.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec16.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec16.TextValue = 'CurrencyCode';
                    svcCatalogReqExtdAttrValRec16.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec16);
                } else if (svcCatAttr.DeveloperName == 'transfer_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec17 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec17.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec17.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec17.TextValue = '1st party';
                    svcCatalogReqExtdAttrValRec17.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec17);
                } else if (svcCatAttr.DeveloperName == 'max_amount') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec18 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec18.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec18.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec18.NumberValue = 300;
                    svcCatalogReqExtdAttrValRec18.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec18);
                }
            }
            insert svcCatalogReqExtdAttrValList;
            
            Test.startTest();
            //Test (start) Invocable method of FSCWlthManageStndInstrFlowHelper
            FSCWlthManageStndInstrFlowHelper.flowInputs flowInputs = new FSCWlthManageStndInstrFlowHelper.flowInputs();
            flowInputs.inputRecordId = svcCatalogRequestRec1.Id;
            List<FSCWlthManageStndInstrFlowHelper.flowInputs> flowInputsList = new List<FSCWlthManageStndInstrFlowHelper.flowInputs>();
            flowInputsList.add(flowInputs);
            try {
                List<String> output = FSCWlthManageStndInstrFlowHelper.getStandingInstructionsList(flowInputsList);
                System.assertNotEquals(output, null);
            } catch (QueryException ex) {
                assertExpectedSecurityException(ex);
            }
            //Test (end) Invocable method of FSCWlthManageStndInstrFlowHelper
            Test.stopTest();
        }
    
    //tests executeCallout method to cancel standing instruction
        @IsTest 
        static void testGetCancelStandingInstructionList() {
            
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList = new List<SvcCatalogReqExtdAttrVal>();
            List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
            Integer intNumber = 1;
            List<Account> listAccount = FSCWlthTestDataFactory.createAccounts(intNumber);     
            //insert list of Service Catalog Request from test data factory
            List<SvcCatalogRequest> listServiceCatalogReq = FSCWlthTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
            insert listServiceCatalogReq;
            SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
            
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'standing_instruction_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = 'Cancel';
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'cancel_mode') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'Wire Transfer';
                    svcCatalogReqExtdAttrValRec2.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'cancel_payee_name') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = 'Test Payee Name';
                    svcCatalogReqExtdAttrValRec3.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'cancel_account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.TextValue = 'ACCNo 12345';
                    svcCatalogReqExtdAttrValRec4.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec4);
                } 
            }
            insert svcCatalogReqExtdAttrValList;
            
            Test.startTest();
            //Test (start) Invocable method of FSCWlthManageStndInstrFlowHelper
            FSCWlthManageStndInstrFlowHelper.flowInputs flowInputs = new FSCWlthManageStndInstrFlowHelper.flowInputs();
            flowInputs.inputRecordId = svcCatalogRequestRec1.Id;
            List<FSCWlthManageStndInstrFlowHelper.flowInputs> flowInputsList = new List<FSCWlthManageStndInstrFlowHelper.flowInputs>();
            flowInputsList.add(flowInputs);
            try {
                List<String> output = FSCWlthManageStndInstrFlowHelper.getStandingInstructionsList(flowInputsList);
                System.assertNotEquals(output, null);
            } catch (QueryException ex) {
                assertExpectedSecurityException(ex);
            }
            //Test (end) Invocable method of FSCWlthManageStndInstrFlowHelper
            Test.stopTest();
        }
}
