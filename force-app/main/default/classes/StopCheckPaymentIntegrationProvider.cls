/*************************
* @Class Name:- StopCheckPaymentIntegrationProvider
* @Description:- Stop Check process integration provider implementation
**************************/
global with sharing class StopCheckPaymentIntegrationProvider implements industriesintegrationfwk.ProcessIntegrationProvider {
    // Request time out in milliseconds
    private final static Integer TIMEOUT = 120000;
    // Named credential to get MuleSoft endpoint as stored in Setup
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final industriesintegrationfwk.ApexProviderAttr NAMED_CRED_ATTR = new industriesintegrationfwk.ApexProviderAttr('Named Credential', 
                                                                                                                                   NAMED_CREDENTIAL_KEY, 'FSC_fsc_integrations_V1_0_0', true, 'String');
    class AttributeValueGroup {  
        String checkNumber;
        String reason;
        String payee;
        String amount;
        String checkDate; 
        String lowestCheckNumber;
        String highestCheckNumber;
        String checkType;
        String accountNumber;
        String accountType;
    }
    
    /**
    * @param requestGuid                 Request GUID provided by the client
    * @param inputRecordId               Input Record ID provided by the client
    * @param payload                     Payload to be passed to the Provider Class
    * @param attributes                  Map of config attributes
    *
    * @return industriesintegrationfwk.IntegrationCalloutResponse
    *         Response sent to the client
    */
    global static industriesintegrationfwk.IntegrationCalloutResponse executeCallout(String requestGuid, String inputRecordId, String payload, Map<String, Object> attributes) {
        if (String.isBlank(inputRecordId)) {
            throw new IllegalArgumentException('Service Process ID is null');
        }
        try {
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, TextValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :inputRecordId WITH SECURITY_ENFORCED];
            AttributeValueGroup attributeValueGroups = getAttributeValueGroup(svcCatalogReqExtdAttrVals);
            HttpResponse response = makeCallout(inputRecordId, attributeValueGroups, attributes, requestGuid);
            Map<String, Object> responseGroup = getResponseGroupAfterCallout(response);        
            industriesintegrationfwk.IntegrationCalloutResponse integrationCalloutResponse = new industriesintegrationfwk.IntegrationCalloutResponse(true);
            integrationCalloutResponse.setReturnValue(responseGroup);
            return integrationCalloutResponse;
        } catch (Exception ex) {
            throw new CalloutException(ex);
        }
    }
    
    //getting all the update contact details by looping through svcCatalogReqExtdAttrVals records
    private static AttributeValueGroup getAttributeValueGroup(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        AttributeValueGroup attributeValueGroups = new AttributeValueGroup();           
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'check_number') {
                attributeValueGroups.checkNumber = svcCatalogReqExtdAttrVal.TextValue;                
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'reason') {
                attributeValueGroups.reason = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'payee') {
                attributeValueGroups.payee = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'amount') {
                attributeValueGroups.amount = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'check_date') {
                attributeValueGroups.checkDate = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'starting_check_number') {
                attributeValueGroups.lowestCheckNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'ending_check_number') {
                attributeValueGroups.highestCheckNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'check_type') {
                attributeValueGroups.checkType = svcCatalogReqExtdAttrVal.TextValue;
            }  else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'account_type') {
                attributeValueGroups.accountType = svcCatalogReqExtdAttrVal.TextValue;
            }  else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'account_number') {
                attributeValueGroups.accountNumber = svcCatalogReqExtdAttrVal.TextValue;
            }
        }
        return attributeValueGroups;
    }
    
    //make callout with POST method to mulesoft
    private static HttpResponse makeCallout(String inputRecordId, AttributeValueGroup attributeValueGroups, Map<String, Object> attributes, String requestGuid) {
        String accountType;
        String recordId = FSCUtilityClass.getAccountSourceSystemId(inputRecordId);
        if (recordId == null) {
            throw new IllegalArgumentException('Source System ID is null');
        }
        String financialAccountSourceSysId = FSCUtilityClass.getFinancialAccSourceSystemId(recordId, attributeValueGroups.accountNumber);
        if (financialAccountSourceSysId == null) {
            throw new IllegalArgumentException('Source System ID is null');
        }
        // Get the record type of the financial account
        if (attributeValueGroups.accountType == 'Savings Account') {
            accountType = 'SavingsAccount';
        } else if (attributeValueGroups.accountType == 'Checking Account') {
            accountType = 'CurrentAccount';
        }
        
        String requestParams = '?requestId=' + inputRecordId;
        if (String.isNotBlank(requestGuid)) {
            requestParams = requestParams + '&flowRefId=' + requestGuid;
        }
        HttpRequest request = new HttpRequest();
        request.setMethod('PUT');
        String endPoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api/' + accountType + '/' + financialAccountSourceSysId + '/IssuedDevice/Update' + requestParams;
        Map<String, Object> payload = constructPayload(inputRecordId, attributeValueGroups);
        request.setBody(JSON.serialize(payload, true));
        
        // set headers
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setEndpoint(endpoint);
        request.setTimeout(TIMEOUT);
        HttpResponse response = new Http().send(request);
        return response;
    }
    
    //Construct the payload with the travel details
    private static Map<String, Object> constructPayload(String inputRecordId, AttributeValueGroup attributeValueGroups) {
        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> issuedInventoryOptionDefinition = new Map<String, Object>();
        Map<String, Object> issuedDevice = new Map<String, Object>();
        
        if (attributeValueGroups.checkType != null && attributeValueGroups.checkType == 'Single check') {
            if (attributeValueGroups.checkNumber != null) {
                issuedInventoryOptionDefinition.put('CheckNumber', attributeValueGroups.checkNumber);
            }
            if (attributeValueGroups.reason != null) {
                issuedInventoryOptionDefinition.put('Reason', attributeValueGroups.reason);
            }
            if (attributeValueGroups.payee != null) {
                issuedInventoryOptionDefinition.put('Payee', attributeValueGroups.payee);
            }
            if (attributeValueGroups.amount != null) {
                issuedInventoryOptionDefinition.put('Amount', attributeValueGroups.amount);
            }
            if (attributeValueGroups.checkDate != null) {
                issuedInventoryOptionDefinition.put('CheckDate', attributeValueGroups.checkDate);
            }
        }
        else if (attributeValueGroups.checkType != null && attributeValueGroups.checkType == 'Range') {
            if (attributeValueGroups.reason != null) {
                issuedInventoryOptionDefinition.put('Reason', attributeValueGroups.reason);
            }
            if (attributeValueGroups.lowestCheckNumber != null) {
                issuedInventoryOptionDefinition.put('LowestCheckNumber', attributeValueGroups.lowestCheckNumber);
            }
            if (attributeValueGroups.highestCheckNumber != null) {
                issuedInventoryOptionDefinition.put('HighestCheckNumber', attributeValueGroups.highestCheckNumber);
            }
        }
        issuedDevice.put('IssuedInventoryOptionDefinition', IssuedInventoryOptionDefinition);
        issuedDevice.put('IssuedInventoryStatus', 'STOP');
        issuedDevice.put('IssuedInventoryDescription', 'stop check');
        issuedDevice.put('IssuedInventoryType', 'check');
        payload.put('IssuedDevice', issuedDevice);
        return payload;
    }
    
    //Method to get the attribute values from the integration definition
    global static List<industriesintegrationfwk.ApexProviderAttr> getProviderAttributes() {
        List<industriesintegrationfwk.ApexProviderAttr> defaults = new List<industriesintegrationfwk.ApexProviderAttr>();
        defaults.add(NAMED_CRED_ATTR);
        return defaults;
    }
    
    //Method to check for the status code
    private static Map<String, Object> getResponseGroupAfterCallout(HttpResponse response) {
        Map<String, Object> responseGroup = new Map<String, Object>();
        if (response.getStatusCode() == 200) {
            responseGroup.put('isSuccess', true);
        } else {
            responseGroup.put('isSuccess', false);
        }
        responseGroup.put('response', getResponseMap(response.getBody()));
        return responseGroup;
    }
    //Method to generate the response
    private static Map<String, Object> getResponseMap(String responsebody) {
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(responsebody);
        } catch (Exception ex) {
            Map<String, Object> responseMap = new Map<String, Object>();
            responseMap.put('response', responsebody);
            return responseMap;
        }
    }
}