/*************************
* @Class Name:- RequestLoanPayoffStatementIntegPrvdTest
* @Description:- Test class for apex RequestLoanPayoffStatementIntegPrvd which returns Loan payoff statement balances
**************************/
@IsTest
public with sharing class RequestLoanPayoffStatementIntegPrvdTest {
    
    private static final String PERSON_ACCOUNT_URL_PATH_KEY = 'Person_Account_URL_Path';
    private static final Map<String, Object> attributes = new Map<String, Object> { PERSON_ACCOUNT_URL_PATH_KEY => '/api/customers/{recordId}' };
    private static final Map<String, String> params = new Map<String, String>();  
        
    //tests getCalloutRequest method
    @IsTest 
    static void testExecuteCallout() {
        Integer intNumber = 1;
        List<Account> listAccount = FSCRetailTestDataFactory.createAccounts(intNumber);     
        //insert a list of financial account from test data factory
        List<FinServ__FinancialAccount__c> listFinancialAccount = FSCRetailTestDataFactory.createFinancialAccounts(intNumber, listAccount);
        params.put('sourceSystemId', 'sourceId456');
        params.put('recordId', listFinancialAccount[0].id);
        params.put('payoffDate', '02/02/2024');
        // Create a mock response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"example":"test"}');
        res.setStatusCode(200);
        List<HttpResponse> resList = new List<HttpResponse>{res};
        Test.startTest();
        try {
            industriesintegrationfwk.IntegrationCalloutRequest getCalloutRequest = RequestLoanPayoffStatementIntegPrvd.getCalloutRequest('67543', params, attributes);
        } catch (ListException ex) {
            System.assertEquals(true, ex.getMessage().contains('List index out of bounds'), ex.getMessage());
        }
        industriesintegrationfwk.IntegrationCalloutResponse getCalloutResponse = RequestLoanPayoffStatementIntegPrvd.getCalloutResponse(resList, null , attributes);
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
        industriesintegrationfwk.IntegrationCalloutRequest getCalloutRequest = RequestLoanPayoffStatementIntegPrvd.getCalloutRequest('67543', null, attributes);
        } catch (Exception ex) {   
         System.assert(ex.getMessage().contains('input argument') || ex.getMessage().contains('argumento de entrada'), ex.getMessage());
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
        industriesintegrationfwk.IntegrationCalloutResponse getCalloutResponse = RequestLoanPayoffStatementIntegPrvd.getCalloutResponse(resList, null , attributes);
        System.assertEquals(getCalloutResponse.isSuccess(), false);
        Test.stopTest();
    }
    
    //tests getCalloutRequest method with No HttpResponse 
    @IsTest 
    static void testExecuteCalloutforNoResponse() {
        Test.startTest();
        industriesintegrationfwk.IntegrationCalloutResponse getCalloutResponse = RequestLoanPayoffStatementIntegPrvd.getCalloutResponse(new List<HttpResponse>(), null , attributes);
        System.assertEquals(getCalloutResponse.isSuccess(), false);
        Test.stopTest();
    }
    
    @IsTest 
    static void testgetProviderAttributes() {
        List<industriesintegrationfwk.ApexProviderAttr> attr = RequestLoanPayoffStatementIntegPrvd.getProviderAttributes();
        System.assertNotEquals(attr, null);
    }

    @IsTest
    static void testExecuteCalloutMissingArguments() {
        Integer rejected = 0;

        try {
            RequestLoanPayoffStatementIntegPrvd.getCalloutRequest(
                'guid',
                new Map<String, String>{
                    'sourceSystemId' => '',
                    'recordId' => 'record',
                    'payoffDate' => '02/02/2024'
                },
                attributes
            );
        } catch (IllegalArgumentException expected) {
            rejected++;
        }

        try {
            RequestLoanPayoffStatementIntegPrvd.getCalloutRequest(
                'guid',
                new Map<String, String>{
                    'sourceSystemId' => 'source',
                    'recordId' => '',
                    'payoffDate' => '02/02/2024'
                },
                attributes
            );
        } catch (IllegalArgumentException expected) {
            rejected++;
        }

        System.assertEquals(2, rejected);
    }
}
