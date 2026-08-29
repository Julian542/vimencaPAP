/*************************
* @Class Name:- RequestStatementCopiesIntegPrvd
* @Description:- Request Statement Copies process integration provider implementation
**************************/
global with sharing class RequestStatementCopiesIntegPrvd implements industriesintegrationfwk.ProcessIntegrationProvider {
    // Request time out in milliseconds
    private final static Integer TIMEOUT = 120000;
    // Named credential to get MuleSoft endpoint as stored in Setup
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final industriesintegrationfwk.ApexProviderAttr NAMED_CRED_ATTR = new industriesintegrationfwk.ApexProviderAttr('Named Credential', 
                                                                                                                                   NAMED_CREDENTIAL_KEY, 'FSC_fsc_integrations_V1_0_0', true, 'String');
    class AttributeValueGroup {  
        String endDate;
        String accountType;
        String addressType;
        String accountNumber;
        String startDate;
        String emailId;
        String viaEmail;
        String sendVia;
        String viaPost;
        String shippingPreference;
        String shippingAddress;
        String addressLine1;
        String addressLine2;
        String city;
        String state;
        String postalCode;
        String countryCode; 
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
            HttpResponse response = makeCallout(inputRecordId, attributeValueGroups, attributes,requestGuid);
            Map<String, Object> responseGroup = getResponseGroupAfterCallout(response);        
            industriesintegrationfwk.IntegrationCalloutResponse integrationCalloutResponse = new industriesintegrationfwk.IntegrationCalloutResponse(true);
            integrationCalloutResponse.setReturnValue(responseGroup);
            return integrationCalloutResponse;
        } catch (Exception ex) {
            throw new CalloutException(ex);
        }
    }
    
    //getting all the update contact details by looping through SvcCatalogReqExtdAttrVals records
    private static AttributeValueGroup getAttributeValueGroup(List<SvcCatalogReqExtdAttrVal> SvcCatalogReqExtdAttrVals) {
        AttributeValueGroup attributeValueGroups = new AttributeValueGroup();           
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : SvcCatalogReqExtdAttrVals) {
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'start_date') {
                attributeValueGroups.startDate = svcCatalogReqExtdAttrVal.TextValue;                
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'end_date') {
                attributeValueGroups.endDate = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'account_type') {
                attributeValueGroups.accountType = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'account_number') {
                attributeValueGroups.accountNumber = svcCatalogReqExtdAttrVal.TextValue;
            }  else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'send_statement_via_email') {
                attributeValueGroups.viaEmail = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'email') {
                attributeValueGroups.emailId = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'send_statement_via_post') {
                attributeValueGroups.viaPost = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'shipping_preference') {
                attributeValueGroups.shippingPreference = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'address_line_1') {
                attributeValueGroups.addressLine1 = svcCatalogReqExtdAttrVal.TextValue;
            }  else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'address_line_2') {
                attributeValueGroups.addressLine2 = svcCatalogReqExtdAttrVal.TextValue;
            }  else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'city') {
                attributeValueGroups.city = svcCatalogReqExtdAttrVal.TextValue;
            }  else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'state') {
                attributeValueGroups.state = svcCatalogReqExtdAttrVal.TextValue;
            }  else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'country') {
                attributeValueGroups.countryCode = svcCatalogReqExtdAttrVal.TextValue;
            }  else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'postal_code') {
                attributeValueGroups.postalCode = svcCatalogReqExtdAttrVal.TextValue;
            }  else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'address_type') {
                attributeValueGroups.addressType = svcCatalogReqExtdAttrVal.TextValue;
            }
        }
        return attributeValueGroups;
    }
    
    //make callout with POST method to mulesoft
    private static HttpResponse makeCallout(String inputRecordId, AttributeValueGroup attributeValueGroups, Map<String, Object> attributes, String requestGuid) {
        String recordId = FSCUtilityClass.getAccountSourceSystemId(inputRecordId);
        if (recordId == null) {
            throw new IllegalArgumentException('Source System ID is null');
        } 
        String financialAccountId = FSCUtilityClass.getFinancialAccountId(recordId, attributeValueGroups.accountNumber);
        if (financialAccountId == null) {
            throw new IllegalArgumentException('Financial Account ID is null');
        }
        String accountType = industriesintegrationfwk.IntegrationsProviderUtil.getServiceDomain(financialAccountId);
        String financialAccSourceSysId = FSCUtilityClass.getFinancialAccSourceSystemId(recordId, attributeValueGroups.accountNumber);
        if (financialAccSourceSysId == null) {
            throw new IllegalArgumentException('Financial Account Source System ID is null');
        }
        
        String requestParams = '?requestId=' + inputRecordId;
        If (String.isNotBlank(requestGuid))
            requestParams = requestParams + '&flowRefId=' + requestGuid;
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        // Endpoint
        String endPoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api' + '/' + accountType + '/' + financialAccSourceSysId + '/Statement/Request' + requestParams;
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
        Map<String, Object> sendVia = new Map<String, Object>();
        Map<String, Object> shippingAddress = new Map<String, Object>();
        Map<String, Object> statement = new Map<String, Object>();
        
        if (attributeValueGroups.startDate != null) {
            statement.put('StartDate', attributeValueGroups.startDate);
        }
        if (attributeValueGroups.endDate != null) {
            statement.put('EndDate', attributeValueGroups.endDate);
        }
        if (attributeValueGroups.viaEmail != null && attributeValueGroups.viaEmail == 'Yes') {
            if (attributeValueGroups.emailId != null) {
                sendVia.put('EmailId', attributeValueGroups.emailId);
            }
        }
        if (attributeValueGroups.viaPost != null && attributeValueGroups.viaPost == 'Yes') {
            if (attributeValueGroups.shippingPreference != null) {
                sendVia.put('ShippingPreference', attributeValueGroups.shippingPreference);
            }
            if (attributeValueGroups.addressLine1 != null) {
                shippingAddress.put('AddressLine1', attributeValueGroups.addressLine1);
            }
            if (attributeValueGroups.addressLine2 != null) {
                shippingAddress.put('AddressLine2', attributeValueGroups.addressLine2);
            }
            if (attributeValueGroups.city != null) {
                shippingAddress.put('City', attributeValueGroups.city);
            }
            if (attributeValueGroups.state != null) {
                shippingAddress.put('State', attributeValueGroups.state);
            }
            if (attributeValueGroups.countryCode != null) {
                shippingAddress.put('CountryCode', attributeValueGroups.countryCode);
            }
            if (attributeValueGroups.postalCode != null) {
                shippingAddress.put('PostalCode', attributeValueGroups.postalCode);
            }
            if (attributeValueGroups.addressType != null) {
                shippingAddress.put('AddressType', attributeValueGroups.addressType);
            }
            sendVia.put('ShippingAddress', shippingAddress);
        }
        statement.put('SendVia', sendVia);
        payload.put('Statement', statement);
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
        if (response.getStatusCode() == 201) {
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
        } catch (Exception e) {
            Map<String, Object> responseMap = new Map<String, Object>();
            responseMap.put('response', responsebody);
            return responseMap;
        }
    }
    
}