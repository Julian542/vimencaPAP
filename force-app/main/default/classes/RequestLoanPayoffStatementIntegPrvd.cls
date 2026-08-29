/*************************
* @Class Name:- RequestLoanPayoffStatementIntegPrvd
* @Description:- Request Loan Payoff Statement process integration provider implementation
**************************/
global with sharing class RequestLoanPayoffStatementIntegPrvd implements industriesintegrationfwk.ServiceIntegrationProvider {  
    
    // Named credential for get request loan payoff statement MuleSoft endpoint as stored in Setup
    private static final String REQUEST_LOAN_PAYOFF_NAMED_CREDENTIAL = 'FSC_fsc_integrations_V1_0_0';
    private static final String NAME_CRED_DEV_NAME = 'Get_Request_Loan_Payoff_Named_Credential';
    // Financial Account source system id parameter
    private static final String SOURCE_SYSTEM_ID = 'sourceSystemId';
    // Financial Account record Id parameter
    private static final String ACCOUNT_RECORD_ID = 'recordId';
    // Payoff date parameter
    private static final String PAYOFF_DATE = 'payoffDate';
    
    private static final industriesintegrationfwk.ApexProviderAttr NAMED_CRED_ATTR = new industriesintegrationfwk.ApexProviderAttr('Get Request Loan Payoff Named Credential', 
                                                                                                                                   NAME_CRED_DEV_NAME, REQUEST_LOAN_PAYOFF_NAMED_CREDENTIAL, true, 'String');
    //make callout with GET method to mulesoft
    global static industriesintegrationfwk.IntegrationCalloutRequest getCalloutRequest(String requestGuid, Map<String, String> params, Map<String, Object> attributes) {  
        if (params == null) {
            // We expect at least a recordId to be passed in params
            String errorMessage = industriesintegrationfwk.ErrorMessageUtil.getMissingArgErrorMessage();
            throw new IllegalArgumentException(errorMessage);
        }
        String sourceSystemId = params.get(SOURCE_SYSTEM_ID);
        if (String.isBlank(sourceSystemId)) {
            throw new IllegalArgumentException(industriesintegrationfwk.ErrorMessageUtil.getMissingSourceSystemIdentifierMessage());
        }
        String recordId = params.get(ACCOUNT_RECORD_ID);
        if (String.isBlank(recordId)) {
            throw new IllegalArgumentException(industriesintegrationfwk.ErrorMessageUtil.getMissingArgErrorMessage());
        }
        // Use the Financial account Id to retrieve account type
        String accountType = industriesintegrationfwk.IntegrationsProviderUtil.getServiceDomain(recordId);
        String payoffDate = params.get(PAYOFF_DATE);
        if (String.isBlank(payoffDate)) {
            throw new IllegalArgumentException(industriesintegrationfwk.ErrorMessageUtil.getMissingArgErrorMessage());
        }
        
        // Create industriesintegrationfwk.IntegrationCalloutRequest object with endpoint read from named credential
        try{
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            String namedCred = (String)attributes.get(NAME_CRED_DEV_NAME);
            req.setEndpoint('callout:' + namedCred + '/api/' + accountType + '/' + sourceSystemId + '/Payoff/Details?payoffDate=' + payoffDate);
            industriesintegrationfwk.IntegrationCalloutRequest intgReq = new industriesintegrationfwk.IntegrationCalloutRequest();
            intgReq.addHttpRequest(req);
            return intgReq;
        } catch (Exception ex) {
            throw new CalloutException(ex);
        }
    }
    
    global static industriesintegrationfwk.IntegrationCalloutResponse getCalloutResponse(List<HttpResponse> httpResponseList, Object state, Map<String, Object> attributes) {
        // Parse response and create industriesintegrationfwk.IntegrationCalloutResponse object
        industriesintegrationfwk.IntegrationCalloutResponse intgResp;
        if (httpResponseList == null || httpResponseList.size() < 1) {
            intgResp = new industriesintegrationfwk.IntegrationCalloutResponse(false);
            intgResp.setErrorMessage('Http Response List is empty!');
            return intgResp;
        }
        HttpResponse response = httpResponseList.get(0);
        Integer statusCode = response.getStatusCode();
        if (statusCode.format() != '200') {
            String errorMessage = industriesintegrationfwk.ErrorMessageUtil.getErrorCodeMessage(statusCode.format());
            intgResp = new industriesintegrationfwk.IntegrationCalloutResponse(false);
            intgResp.setErrorMessage(errorMessage);
            return intgResp;
        }
        Map<String, Object> responseBody = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
        intgResp = new industriesintegrationfwk.IntegrationCalloutResponse(true);
        intgResp.setReturnValue(responseBody);
        return intgResp;
    }
    
    //Method to get the attribute values from the integration definition
    global static List<industriesintegrationfwk.ApexProviderAttr> getProviderAttributes() {
        List<industriesintegrationfwk.ApexProviderAttr> defaults = new List<industriesintegrationfwk.ApexProviderAttr>();
        defaults.add(NAMED_CRED_ATTR);
        return defaults;
    }
    
}