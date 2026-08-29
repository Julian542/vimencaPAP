/*************************
* @Class Name:- FSCWlthManageStandingInstrGetDCITest
* @Description:- Test class for FSCWlthManageStandingInstructionGetDCI
**************************/
@IsTest
public class FSCWlthManageStandingInstrGetDCITest {
    
    //tests uploaddocument method
    @IsTest 
    static void testUploadDocuments() {
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
            } else if (svcCatAttr.DeveloperName == 'account_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec2.TextValue = 'XXXX-6210';
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec2);
            } else if (svcCatAttr.DeveloperName == 'mode') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec3.TextValue = 'EFT';
                svcCatalogReqExtdAttrValRec3.GroupNumber = 1;
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec3);
            } else if (svcCatAttr.DeveloperName == 'payee_name') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec4.TextValue = 'Test Payee Name';
                svcCatalogReqExtdAttrValRec4.GroupNumber = 1;
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec4);
            } else if (svcCatAttr.DeveloperName == 'payee_account_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec5.TextValue = '12345566';
                svcCatalogReqExtdAttrValRec5.GroupNumber = 1;
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec5);
            } else if (svcCatAttr.DeveloperName == 'bank_name') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec6.TextValue = 'Bank Name 1';
                svcCatalogReqExtdAttrValRec6.GroupNumber = 1;
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec6);
            } else if (svcCatAttr.DeveloperName == 'routing_number') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec7.TextValue = 'ROUTNO123';
                svcCatalogReqExtdAttrValRec7.GroupNumber = 1;
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec7);
            } else if (svcCatAttr.DeveloperName == 'prefix') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec8.TextValue = 'Prefix.';
                svcCatalogReqExtdAttrValRec8.GroupNumber = 1;
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec8);
            } else if (svcCatAttr.DeveloperName == 'eft_account_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec9 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec9.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec9.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec9.TextValue = 'Savings';
                svcCatalogReqExtdAttrValRec9.GroupNumber = 1;
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec9);
            } else if (svcCatAttr.DeveloperName == 'currency_code') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec10 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec10.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec10.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec10.TextValue = 'CurrencyCode';
                svcCatalogReqExtdAttrValRec10.GroupNumber = 1;
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec10);
            } else if (svcCatAttr.DeveloperName == 'transfer_type') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec11 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec11.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec11.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec11.TextValue = '1st Party Transfer';
                svcCatalogReqExtdAttrValRec11.GroupNumber = 1;
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec11);
            } else if (svcCatAttr.DeveloperName == 'max_amount') {
                SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec12 = new SvcCatalogReqExtdAttrVal();
                svcCatalogReqExtdAttrValRec12.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                svcCatalogReqExtdAttrValRec12.SvcCatalogItemAttributeId = svcCatAttr.Id;
                svcCatalogReqExtdAttrValRec12.NumberValue = 300;
                svcCatalogReqExtdAttrValRec12.GroupNumber = 1;
                svcCatalogReqExtdAttrValList.add(svcCatalogReqExtdAttrValRec12);
            }
        }
        insert svcCatalogReqExtdAttrValList;
        
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        List<Map<String, Object>> listDocInfo = new List<Map<String, Object>>();
        Map<String, Object> docInfo = new Map<String, Object>();
        SvcCatalogRequest svcCatalogRequestRec = [SELECT Id, CatalogItemName, caseId FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        String caseId = svcCatalogRequestRec.caseId;
        Boolean isGetReviewedDCI = true;
        input.put('CaseId', caseId);
        input.put('isGetReviewedDCI', isGetReviewedDCI);
        docinfo.put('AccNumber', '12345566');
        docinfo.put('Name', '12345566 - FileUpload');
        docinfo.put('Status', 'Accepted');
        listDocInfo.add(docInfo);
        input.put('docinfo', listDocInfo);
        args.put('input', input);
        args.put('output', output);
        Callable cll = (Callable)Type.forName('FSCWlthManageStandingInstructionGetDCI').newInstance();
        try {
            Object uploadFile = cll.call('uploaddocument', args);
            System.assertEquals('{result=({Accepted={AccountNumber=12345566, BankName=Bank Name 1, ContentDocumentId=null, Name=12345566 - FileUpload, Remarks=null, RoutingNumber=ROUTNO123, Status=Accepted, dciId=null}})}', String.valueOf(uploadFile));
        } catch (QueryException ex) {
            System.assert(ex.getMessage().contains('secure query included inaccessible field'), ex.getMessage());
        }
    }   
}
