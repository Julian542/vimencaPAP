/*************************
* @Class Name:- RecurringTransactionsServiceIntegPrvd
* @Description:- Process integration provider implementation to get the recurring transactions details
**************************/
global with sharing class RecurringTransactionsServiceIntegPrvd implements industriesintegrationfwk.ServiceIntegrationProvider {  
    
    // Named credential for get recurring transcation MuleSoft endpoint as stored in Setup
    private static final String RECURRING_TRANSACTION_NAMED_CREDENTIAL = 'FSC_fsc_integrations_V1_0_0';
    private static final String NAME_CRED_DEV_NAME = 'FSC_fsc_integrations_V1_0_0';
    // Financial Account source system id parameter
    private static final String SOURCE_SYSTEM_ID = 'sourceSystemId';
    // Financial Account record Id parameter
    private static final String ACCOUNT_RECORD_ID = 'recordId';
    private static final industriesintegrationfwk.ApexProviderAttr NAMED_CRED_ATTR = new industriesintegrationfwk.ApexProviderAttr('Get Transaction Named Credential', NAME_CRED_DEV_NAME, RECURRING_TRANSACTION_NAMED_CREDENTIAL, true, 'String');
    
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
        
        // Use the account record Id to retrieve account type
        String recordId = params.get(ACCOUNT_RECORD_ID);
        if (String.isBlank(recordId)) {
            throw new IllegalArgumentException(industriesintegrationfwk.ErrorMessageUtil.getMissingArgErrorMessage());
        }
        String accountType = industriesintegrationfwk.IntegrationsProviderUtil.getServiceDomain(recordId);
        
        // Create industriesintegrationfwk.IntegrationCalloutRequest object with endpoint read from named credential
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        String namedCred = (String)attributes.get(NAME_CRED_DEV_NAME);
        req.setEndpoint('callout:' + namedCred + '/api/' + accountType + '/' + sourceSystemId + '/Payments/Retrieve');
        industriesintegrationfwk.IntegrationCalloutRequest intgReq = new industriesintegrationfwk.IntegrationCalloutRequest();
        intgReq.addHttpRequest(req);
        return intgReq;
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
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
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