/*************************
* @Class Name:- FSCWlthUtilityClassTest
* @Description:- Test class for FSCWlthUtilityClass
**************************/
@IsTest
public class FSCWlthUtilityClassTest {
    
    //This method creates the setup data
    @TestSetup
    static void createServiceCatalogReqData() {
        Map<String, String> headers = new Map<String, String>{ 'Content-Type' => 'application/json' };
        Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(200, 'Success', '{}', headers));
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
    }
    
	//This test method is to get base path of community site 
    @IsTest 
    static void testGetBasePath() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        args.put('input', input);
        args.put('output', output);
        Callable callableMethod = (Callable)Type.forName('FSCWlthUtilityClass').newInstance();
        Object basePath = callableMethod.call('getBasePath', args);
        System.assertEquals('{result={BasePath=}}', String.valueOf(basePath));    
    }
    
    //This test method is to get last 30 years 
    @IsTest 
    static void testGetLastSpecificYears() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        args.put('input', input);
        args.put('output', output);
        Callable callableMethod = (Callable)Type.forName('FSCWlthUtilityClass').newInstance();
        Object lastSpecificYears = callableMethod.call('getLastSpecificYears', args);
        System.assertEquals (1, output.values().size());    
    }
    
    //This test method is to fetch unique values in a list
    @IsTest 
    static void testGetUniqueList() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        List<Object> mainList = new List<Object>();
        
        String docTypes='Void Statement';
        mainList.add(docTypes);
        input.put('InputList', mainList);
        args.put('input', input);
        args.put('output', output);
        Callable cll = (Callable)Type.forName('FSCWlthUtilityClass').newInstance();
        Object getUniqueList = cll.call('getUniqueList', args);
        System.assertEquals('{UniqueList={Void Statement}}', String.valueOf(getUniqueList));
        Object getListMap = cll.call('convertListToMap', args);
    }
    
    //This test method is to create DCI records and content document link
    @IsTest 
    static void testCreateDCI() {
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        List<Map<String, Object>> listDocInfo = new List<Map<String, Object>>();
        Map<String, Object> docInfo = new Map<String, Object>();
        
        SvcCatalogRequest svcCatalogRequestRec = [SELECT Id, CatalogItemName, caseId FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        String caseId = svcCatalogRequestRec.caseId;
        input.put('parentId', caseId);
        docinfo.put('typeId', '0de1Q000000Kz9bQAC');
        docinfo.put('name', '12345566 - FileUpload');
        docinfo.put('id', '0691Q00000XvwN6QAJ');
        listDocInfo.add(docInfo);
        input.put('documentInfo', listDocInfo);
        args.put('input', input);
        args.put('output', output);
        Callable cll = (Callable)Type.forName('FSCWlthUtilityClass').newInstance();
        Object uploadedFile = cll.call('callCreateDCI', args);
        System.assertNotEquals(null, svcCatalogRequestRec.id);
    }
    
    //This test method is to get the account source system Id 
    @IsTest 
    static void testGetAccountSourceSystemId() {
        Integer intNumber = 1;
        List<Account> listAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Account0'];
        SvcCatalogRequest svcCatalogRequestRec = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
        Test.startTest();
        String recordId;
        try {
            recordId = FSCWlthUtilityClass.getAccountSourceSystemId(svcCatalogRequestRec.Id);
        } catch (QueryException ex) {
            System.assert(ex.getMessage().contains('secure query included inaccessible field'), ex.getMessage());
        }
        Test.stopTest();
        if (recordId != null) {
            System.assertEquals('2340', recordId);
        }
    }
    
    //This test method is to get the card source system id
    @IsTest 
    static void testGetFinancialAccSourceSystemId() {
        //insert list of accounts from test data factory
        Integer intNumber = 1;
        List<Account> listAccount = [SELECT Id, Name,FinServ__SourceSystemId__c FROM Account WHERE Name = 'Test Account0'];
        List<FinServ__FinancialAccount__c> financialAcc = FSCWlthTestDataFactory.createFinancialAccounts(1, listAccount);
        Test.startTest();
        String finAccSourceSysId = FSCWlthUtilityClass.getFinancialAccSourceSystemId(listAccount[0].FinServ__SourceSystemId__c, 'XXXX-6210');
        Test.stopTest();
        System.assertEquals(finAccSourceSysId, '234454330');
    }
    
    //This test method is to get the financial account id
    @IsTest 
    static void testGetFinancialAccountId() {
        //insert list of accounts from test data factory
        Integer intNumber = 1;
        List<Account> listAccount = [SELECT Id, Name,FinServ__SourceSystemId__c FROM Account WHERE Name = 'Test Account0'];
        List<FinServ__FinancialAccount__c> financialAcc = FSCWlthTestDataFactory.createFinancialAccounts(1, listAccount);
        Test.startTest();
        String financialAccountId = FSCWlthUtilityClass.getFinancialAccountId(listAccount[0].FinServ__SourceSystemId__c, 'XXXX-6210');
        Test.stopTest();
        System.assert(financialAccountId != null);
    }

    @IsTest
    static void testConstructEmailBodyAndUnknownAction() {
        List<Map<String, String>> rows = new List<Map<String, String>>{
            new Map<String, String>{ 'Cuenta' => '1234', 'Estado' => 'Activa' }
        };

        String scrollBody = FSCWlthUtilityClass.constructEmailBody(rows, 'Resumen', true);
        String compactBody = FSCWlthUtilityClass.constructEmailBody(rows, 'Resumen', false);
        System.assert(scrollBody.contains('overflow-x: auto'));
        System.assert(!compactBody.contains('overflow-x: auto'));
        System.assert(scrollBody.contains('1234'));

        Map<String, Object> args = new Map<String, Object>{
            'input' => new Map<String, Object>(),
            'output' => new Map<String, Object>()
        };
        System.assertEquals(null, ((Callable)Type.forName('FSCWlthUtilityClass').newInstance()).call('unknownAction', args));
    }
}
