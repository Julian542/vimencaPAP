/*************************
* @Class Name:- FSCWlthManageStndInstrIntegPrvdTest
* @Description:- This file includes tests response from method in FSCWlthManageStandingInstructionsIntegrationProvider.apex
**************************/
@IsTest
public with sharing class FSCWlthManageStndInstrIntegPrvdTest {
    
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

            SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
            SvcCatalogRequest svcCatalogRequestRec2 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog1' LIMIT 1];
            for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'standing_instruction_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = 'Add';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'XXXX-6210';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec2);
                } else if (svcCatAttr.DeveloperName == 'routing_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = '6378383';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec3);
                } else if (svcCatAttr.DeveloperName == 'currency_code') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec4 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec4.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec4.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec4.GroupNumber = 1;
                    svcCatalogReqExtdAttrValRec4.TextValue = 'USD';
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec4);
                }  else if (svcCatAttr.DeveloperName == 'max_amount') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec5 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec5.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec5.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec5.TextValue = '1225627';
                    svcCatalogReqExtdAttrValRec5.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec5);
                }  else if (svcCatAttr.DeveloperName == 'max_amount') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec6 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec6.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec6.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec6.TextValue = '7654545';
                    svcCatalogReqExtdAttrValRec6.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec6);
                } else if (svcCatAttr.DeveloperName == 'mode') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec7 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec7.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec7.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec7.TextValue = 'Wire Transfer';
                    svcCatalogReqExtdAttrValRec7.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec7);
                } else if (svcCatAttr.DeveloperName == 'prefix') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec8 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec8.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec8.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec8.TextValue = 'Test';
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
                } else if (svcCatAttr.DeveloperName == 'zip_code') {
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
                }  else if(svcCatAttr.DeveloperName == 'payee_name'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec15 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec15.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec15.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec15.TextValue = 'James William';
                    svcCatalogReqExtdAttrValRec15.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec15);
                }   else if(svcCatAttr.DeveloperName == 'currency_code'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec16 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec16.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec16.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec16.TextValue = 'USD';
                    svcCatalogReqExtdAttrValRec16.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec16);
                }  else if(svcCatAttr.DeveloperName == 'bank_name'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec17 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec17.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec17.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec17.TextValue = 'Test Bank';
                    svcCatalogReqExtdAttrValRec17.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec17);
                }  else if(svcCatAttr.DeveloperName == 'payee_account_number'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec18 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec18.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec18.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec18.TextValue = '121344';
                    svcCatalogReqExtdAttrValRec18.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec18);
                }   else if(svcCatAttr.DeveloperName == 'details'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec19 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec19.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec19.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec19.TextValue = 'test purpose';
                    svcCatalogReqExtdAttrValRec19.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec19);
                }   else if(svcCatAttr.DeveloperName == 'eft_account_type'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec20 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec20.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec20.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec20.TextValue = 'savings';
                    svcCatalogReqExtdAttrValRec20.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec20);
                }   else if(svcCatAttr.DeveloperName == 'transfer_type'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec21 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec21.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec21.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec21.TextValue = '1st party transfer';
                    svcCatalogReqExtdAttrValRec21.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec21);
                }  else if(svcCatAttr.DeveloperName == 'memo'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec22 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec22.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec22.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec22.TextValue = 'Test';
                    svcCatalogReqExtdAttrValRec22.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec22);
                }  else if(svcCatAttr.DeveloperName == 'check_stub_information'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec23 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec23.SvcCatalogRequestId = svcCatalogRequestRec1.Id;
                    svcCatalogReqExtdAttrValRec23.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec23.TextValue = 'test';
                    svcCatalogReqExtdAttrValRec23.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList1.add(svcCatalogReqExtdAttrValRec23);
                }  
            }
            insert svcCatalogReqExtdAttrValList1;
             for (SvcCatalogItemAttribute svcCatAttr : listOfAllCatAttr) {
                if (svcCatAttr.DeveloperName == 'standing_instruction_type') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec1 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec1.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec1.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec1.TextValue = 'Cancel';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec1);
                } else if (svcCatAttr.DeveloperName == 'account_number') {
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec2 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec2.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec2.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec2.TextValue = 'XXXX-6211';
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec2);
                } else if(svcCatAttr.DeveloperName == 'standing_instruction_id'){
                    SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrValRec3 = new SvcCatalogReqExtdAttrVal();
                    svcCatalogReqExtdAttrValRec3.SvcCatalogRequestId = svcCatalogRequestRec2.Id;
                    svcCatalogReqExtdAttrValRec3.SvcCatalogItemAttributeId = svcCatAttr.Id;
                    svcCatalogReqExtdAttrValRec3.TextValue = '5887686';
                    svcCatalogReqExtdAttrValRec3.GroupNumber = 1;
                    svcCatalogReqExtdAttrValList2.add(svcCatalogReqExtdAttrValRec3);
                }  
            }
            insert svcCatalogReqExtdAttrValList2;
        }
            
    //tests executeCallout method
    @IsTest static void testExecuteCalloutAdd() {
        
            SvcCatalogRequest svcCatalogRequestRec1 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog0' LIMIT 1];
           
            Map<String, String> headers = new Map<String, String>();
            headers.put('Content-Type', 'application/json');
	            Test.startTest();
	            // Set mock callout class 
	            Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(201,'Success','"{"CreationDateTime":"2023-06-27T11:56:59.001502Z","Payments":{"PaymentType":"standing order","PaymentMode":"Wire Transfer","PaymentMechanism":"recurring","PaymentPurpose":"Standing instruction for phone bill 1000 USD","PaymentDefinition":{"PaymentAmount":{"MaxAmount":"1000","Currency":"USD"}},"PayeeBankReference":{"BankName":"ABC","RoutingNumber":"2000123008"},"PayeeAccountReference":{"PayeeAccountNumber":"AMZ10012","PayeeAccountType":"savings","PayeeAccountDetails":"accountDetails"},"PayeeJournalReference":{"PayeeAccountNumbers":["AMZ10012"]},"PayeeCheckReference":{"PayeeCheckMode":"AMZ10012","PayeeCheckMemo":"savings","PayeeCheckStubInformation":"savings"},"PaymentTransferType":"1st Party Transfer","PayeeReference":{"PayeeName":"Amazon","PayeeAddress":{"AddressType":"Mailing Address","AddressLine1":"415 Mission St","AddressLine2":"Floor 61","City":"San Francisco","State":"CA","PostalCode":"94105","CountryCode":"USA"}}},"PaymentId":"SOT00010000"}"', headers));
	            try {
	                industriesintegrationfwk.IntegrationCalloutResponse  calloutResponse = FSCWlthManageStndInstrIntegProvider.executeCallout('6533875', svcCatalogRequestRec1.Id, null, ATTRIBUTES);
	                System.assertEquals(calloutResponse.isSuccess(), true);
	                System.assertEquals(calloutResponse.getErrorMessage(), null);
	            } catch (CalloutException ex) {
	                System.assertEquals(true, isExpectedSecurityWrappedException(ex), ex.getMessage());
	            }
	            Test.stopTest();
	        }
    
     //tests executeCallout method for cancel
    @IsTest static void testExecuteCalloutCancel() {
        SvcCatalogRequest svcCatalogRequestRec2 = [SELECT Id, CatalogItemName FROM SvcCatalogRequest WHERE CatalogItemName = 'TestCatalog1' LIMIT 1];
        
        Map<String,String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        
	        Test.startTest();
	        // Set mock callout class 
	        Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(201,'Success','"{"CreationDateTime":"2023-06-27T11:56:59.001502Z","Payments":{"PaymentType":"standing order","PaymentMode":"Wire Transfer","PaymentMechanism":"recurring","PaymentPurpose":"Standing instruction for phone bill 1000 USD","PaymentDefinition":{"PaymentAmount":{"MaxAmount":"1000","Currency":"USD"}},"PayeeBankReference":{"BankName":"ABC","RoutingNumber":"2000123008"},"PayeeAccountReference":{"PayeeAccountNumber":"AMZ10012","PayeeAccountType":"savings","PayeeAccountDetails":"accountDetails"},"PayeeJournalReference":{"PayeeAccountNumbers":["AMZ10012"]},"PayeeCheckReference":{"PayeeCheckMode":"AMZ10012","PayeeCheckMemo":"savings","PayeeCheckStubInformation":"savings"},"PaymentTransferType":"1st Party Transfer","PayeeReference":{"PayeeName":"Amazon","PayeeAddress":{"AddressType":"Mailing Address","AddressLine1":"415 Mission St","AddressLine2":"Floor 61","City":"San Francisco","State":"CA","PostalCode":"94105","CountryCode":"USA"}}},"PaymentId":"SOT00010000"}"', headers));
	        try {
	            industriesintegrationfwk.IntegrationCalloutResponse  calloutResponse = FSCWlthManageStndInstrIntegProvider.executeCallout('6533875', svcCatalogRequestRec2.Id,null,ATTRIBUTES);
	            System.assertEquals(calloutResponse.isSuccess(), true);
	            System.assertEquals(calloutResponse.getErrorMessage(), null);
	        } catch (CalloutException ex) {
	            System.assertEquals(true, isExpectedSecurityWrappedException(ex), ex.getMessage());
	        }
	        Test.stopTest();
	    }
    
     @IsTest static void testExecuteCalloutException() {
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        try {
            // Set mock callout class 
            Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(201,'Success','{ "StandingInstructionId": "SOT00010000", "CreationDateTime": "2023-06-27T11:56:59.001502Z", "Payments": { "PaymentType": "standing order", "PaymentDefinition": { "PaymentAmount": { "Amount": "1000", "Currency": "USD" } }, "PaymentSchedule": { "PaymentStartDate": "10/25/2023", "PaymentEndDate": "10/25/2024", "PaymentFrequency": "MONTHLY", "NumberOfPayments": "12" }, "PayeeReference": { "PayeeName": "Amazon" }, "PaymentPurpose": "Standing instruction for phone bill 1000 USD", "PayeeBankReference": { "RoutingNumber": "2000123008" }, "PayeeAccountReference": { "PayeeAccountNumber": "AMZ10012" } } }',headers));
            industriesintegrationfwk.IntegrationCalloutResponse  calloutResponse = FSCWlthManageStndInstrIntegProvider.executeCallout('6533875','',null,ATTRIBUTES);
            System.assertEquals(calloutResponse.isSuccess(), false);
        }
        catch(Exception ex) {
            System.assertEquals(ex.getMessage(), 'Service Process ID is null');
        }
    }

    
    //test method for getProviderAttributes method
    @IsTest 
    static void testgetProviderAttributes(){
        List<industriesintegrationfwk.ApexProviderAttr> attr = FSCWlthManageStndInstrIntegProvider.getProviderAttributes();
        System.assertNotEquals(attr, null);
    }
}
