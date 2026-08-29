/*************************
* @Class Name:- FSCWlthBeneficiaryDetailSrvcIntegPrvdTst
* @Description:- This file includes test response from method in FSCWlthBeneficiaryDetailsSrvcIntegPrvd.apex
**************************/
@IsTest
public with sharing class FSCWlthBeneficiaryDetailSrvcIntegPrvdTst {
    
    private static final String PERSON_ACCOUNT_URL_PATH_KEY = 'Person_Account_URL_Path';
    private static final Map<String, Object> attributes = new Map<String, Object> { PERSON_ACCOUNT_URL_PATH_KEY => '/api/customers/{recordId}' };
    private static final Map<String, String> params = new Map<String, String>();  
    
    //tests getCalloutRequest method
    @IsTest 
    static void testExecuteCallout() {
        Map<String, String> headers = new Map<String, String>{ 'Content-Type' => 'application/json' };
        Test.setMock(HttpCalloutMock.class, new FSCWlthMockHttpResponseGenerator(200, 'Success', '{}', headers));

        Integer intNumber = 1;
        List<Account> listAccount = FSCWlthTestDataFactory.createAccounts(intNumber);     
        //insert a list of financial account from test data factory
        List<FinServ__FinancialAccount__c> listFinancialAccount = FSCWlthTestDataFactory.createFinancialAccounts(intNumber, listAccount);
        params.put('sourceSystemId', 'sourceId456');
        params.put('recordId', listFinancialAccount[0].id);
        // Create a mock response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"example":"test"}');
        res.setStatusCode(200);
        List<HttpResponse> resList = new List<HttpResponse>{res};
        Test.startTest();
        industriesintegrationfwk.IntegrationCalloutRequest getCalloutRequest = FSCWlthBeneficiaryDetailsSrvcIntegPrvd.getCalloutRequest('67543', params, attributes);
        industriesintegrationfwk.IntegrationCalloutResponse getCalloutResponse = FSCWlthBeneficiaryDetailsSrvcIntegPrvd.getCalloutResponse(resList, null , attributes);
        System.assertEquals(getCalloutResponse.isSuccess(), true);
        System.assertEquals(getCalloutResponse.getErrorMessage(), null);
        Test.stopTest();
    }
    
    //tests getCalloutRequest method Exception with parameters as null
    @IsTest 
    static void testExecuteCalloutParametersNullException() {
        Test.startTest();
        //passing null in parameters
        try {
            industriesintegrationfwk.IntegrationCalloutRequest getCalloutRequest = FSCWlthBeneficiaryDetailsSrvcIntegPrvd.getCalloutRequest('67543', null, attributes);
        } catch (Exception ex) {   
            System.assert(
                ex.getMessage().contains('input argument is invalid') ||
                ex.getMessage().contains('argumento de entrada no es válido'),
                ex.getMessage()
            );
        }
        Test.stopTest();
    }
    
    //tests getCalloutRequest method Exception 
    @IsTest 
    static void testExecuteCalloutException() {
        // Create a mock response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"example":"test"}');
        res.setStatusCode(401);
        List<HttpResponse> resList = new List<HttpResponse>{res};
        Test.startTest();
        industriesintegrationfwk.IntegrationCalloutResponse getCalloutResponse = FSCWlthBeneficiaryDetailsSrvcIntegPrvd.getCalloutResponse(resList, null , attributes);
        System.assertEquals(getCalloutResponse.isSuccess(), false);
        Test.stopTest();
    }
    
    //tests getCalloutRequest method with No HttpResponse 
    @IsTest 
    static void testExecuteCalloutforNoResponse() {
        Test.startTest();
        industriesintegrationfwk.IntegrationCalloutResponse getCalloutResponse = FSCWlthBeneficiaryDetailsSrvcIntegPrvd.getCalloutResponse(new List<HttpResponse>(), null , attributes);
        System.assertEquals(getCalloutResponse.isSuccess(), false);
        Test.stopTest();
    }
    
    @IsTest 
    static void testgetProviderAttributes() {
        List<industriesintegrationfwk.ApexProviderAttr> attr = FSCWlthBeneficiaryDetailsSrvcIntegPrvd.getProviderAttributes();
        System.assertNotEquals(attr, null);
    }
}
