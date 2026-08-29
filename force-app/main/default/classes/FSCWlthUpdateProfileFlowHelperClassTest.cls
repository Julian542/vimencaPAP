/*************************
* @Class Name:- FSCWlthUpdateProfileFlowHelperClassTest
* @Description:- This file includes tests response from method in FSCWlthUpdateProfileFlowHelperClass.apex
**************************/
@IsTest
public class FSCWlthUpdateProfileFlowHelperClassTest {
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final Map<String, Object> ATTRIBUTES = new Map<String, Object> { NAMED_CREDENTIAL_KEY => 'FSCWlth_fsc_integrations_V1_0_0' };
        //tests executeCallout method to add beneficiary
        @IsTest 
        static void testGetAddressesList() {
            
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrValList = new List<SvcCatalogReqExtdAttrVal>();
            List<SvcCatalogItemAttribute> listOfAllCatAttr = [SELECT Id, Label, DeveloperName FROM SvcCatalogItemAttribute];
            Integer intNumber = 1;
            List<Account> listAccount = FSCWlthTestDataFactory.createAccounts(intNumber);     
            
            //insert list of Service Catalog Request from test data factory
            List<SvcCatalogRequest> listServiceCatalogReq = FSCWlthTestDataFactory.createServiceCatalogRequest(intNumber, listAccount);
            insert listServiceCatalogReq;
            
            SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
            
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'addresses_to_update') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = '1028,Hyde Park, New Jersey, US,092892';
                    svcCatalogReqExtdAttrValRec1.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'account_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'Shipping Address';
                    svcCatalogReqExtdAttrValRec2.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec2);
                }
            }
            insert svcCatalogReqExtdAttrValList;
            
            Test.startTest();
            //Test (start) Invocable method of FSCWlthUpdateProfileFlowHelperClass
            FSCWlthUpdateProfileFlowHelperClass.flowInputs flowInputs = new FSCWlthUpdateProfileFlowHelperClass.flowInputs();
            flowInputs.inputRecordId = svcCatalogRequestRec1.Id;
            List<FSCWlthUpdateProfileFlowHelperClass.flowInputs> flowInputsList = new List<FSCWlthUpdateProfileFlowHelperClass.flowInputs>();
            flowInputsList.add(flowInputs);
            try {
                List<String> output = FSCWlthUpdateProfileFlowHelperClass.getAddressesList(flowInputsList);
                System.assertNotEquals(output, null);
            } catch (QueryException ex) {
                System.assert(ex.getMessage().contains('secure query included inaccessible field'), ex.getMessage());
            }
            //Test (end) Invocable method of FSCWlthUpdateProfileFlowHelperClass
            Test.stopTest();
        }
}
