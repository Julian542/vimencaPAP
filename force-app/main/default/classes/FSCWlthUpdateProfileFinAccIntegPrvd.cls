/*************************
* @Class Name:- FSCWlthUpdateProfileFinAccIntegPrvd
* @Description:- Update Financial Account Profile integration provider implementation
**************************/
global with sharing class FSCWlthUpdateProfileFinAccIntegPrvd  implements industriesintegrationfwk.ProcessIntegrationProvider {
    
    // Request time out in milliseconds
    private final static Integer TIMEOUT = 120000;
    // Named credential to get MuleSoft endpoint as stored in Setup
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final industriesintegrationfwk.ApexProviderAttr NAMED_CRED_ATTR = new industriesintegrationfwk.ApexProviderAttr('Named Credential', NAMED_CREDENTIAL_KEY, 'FSC_wealth_integrations_V1_0_0', true, 'String');
    
    class FinAccountAttributeValue { 
        String AccountNumber;
        String AddressType;
        Integer groupNumber;
    }

    class AttributeValueGroup {   
        String financialAccountUpdated;
        String addressLine1;
        String addressLine2;
        String city;
        String countryCode;
        String state;
        String postalCode;
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
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, GroupNumber, TextValue, NumberValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :inputRecordId WITH SECURITY_ENFORCED ORDER BY GroupNumber ASC NULLS FIRST];
            AttributeValueGroup attributeValueGroups = getAttributeValueGroup(svcCatalogReqExtdAttrVals);
            Map<Integer, FinAccountAttributeValue> finAccAttributeValues = getFinAccountAttributeValue(svcCatalogReqExtdAttrVals);
            List<FinAccountAttributeValue> finAccAttributeValueDetails = new List<FinAccountAttributeValue>();
            List<String> finAccNumberList = new List<String>();
            
            for (Integer groupNumber : finAccAttributeValues.keySet()) {
                FinAccountAttributeValue finAccDetailsObj = new FinAccountAttributeValue();
                finAccDetailsObj = finAccAttributeValues.get(groupNumber);
                if (finAccDetailsObj.AddressType != 'Shipping Address' && finAccDetailsObj.AddressType != 'Billing Address') {
                    finAccAttributeValueDetails.add(finAccDetailsObj);
                    finAccNumberList.add(finAccDetailsObj.AccountNumber);
                }
            }
            if (finAccAttributeValueDetails.size() > 0 && finAccAttributeValueDetails != null && attributeValueGroups.financialAccountUpdated == 'Yes') {
                List<String> accountDetails = getFinancialAccountIds(finAccNumberList, inputRecordId);
                HttpResponse response = makeCallout(inputRecordId, attributeValueGroups, finAccAttributeValueDetails, accountDetails, attributes, requestGuid);      
                Map<String, Object> responseGroup = getResponseGroupAfterCallout(response);        
                industriesintegrationfwk.IntegrationCalloutResponse integrationCalloutResponse = new industriesintegrationfwk.IntegrationCalloutResponse(true);
                integrationCalloutResponse.setReturnValue(responseGroup);
                return integrationCalloutResponse;
            } else {
                return null;
            }
        } catch (Exception ex) {
            throw new CalloutException(ex);
        }
    }

    //getting all the update contact details by looping through svcCatalogReqExtdAttrVals records
    private static AttributeValueGroup getAttributeValueGroup(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        AttributeValueGroup attributeValueGroups = new AttributeValueGroup();           
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                when 'update_financial_account' {
                    attributeValueGroups.financialAccountUpdated = svcCatalogReqExtdAttrVal.TextValue;
                } when 'address_line_1' {
                    attributeValueGroups.addressLine1 = svcCatalogReqExtdAttrVal.TextValue;
                } when 'address_line_2' {
                    attributeValueGroups.addressLine2 = svcCatalogReqExtdAttrVal.TextValue;
                } when 'city' {
                    attributeValueGroups.city = svcCatalogReqExtdAttrVal.TextValue;
                } when 'state' {
                    attributeValueGroups.state = svcCatalogReqExtdAttrVal.TextValue;
                } when 'zip_code' {
                    attributeValueGroups.postalCode = svcCatalogReqExtdAttrVal.TextValue;
                } when 'country' {
                    attributeValueGroups.countryCode = svcCatalogReqExtdAttrVal.TextValue;
                }
            }
        }
        return attributeValueGroups;
    }

    //looping through the svcCatalogReqExtdAttrVals records to get the array of financial account details
    private static Map<Integer, FinAccountAttributeValue> getFinAccountAttributeValue(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        Map<Integer, FinAccountAttributeValue> finAccAttributeValues = new Map<Integer, FinAccountAttributeValue>();
        String accountNumber = null;
        String addressType = null;

        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                when 'account_type' {
                    addressType = svcCatalogReqExtdAttrVal.TextValue;
                } when 'account_number' {
                    accountNumber = svcCatalogReqExtdAttrVal.TextValue;
                }
            }
            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null) {
                FinAccountAttributeValue finAccAttributeValue = finAccAttributeValues.get(groupNumber);  
                Map<String, Object> address = new Map<String, Object>();             
                finAccAttributeValue = new FinAccountAttributeValue();
                finAccAttributeValues.put(groupNumber, finAccAttributeValue);
                finAccAttributeValue.groupNumber = groupNumber;
                finAccAttributeValue.AccountNumber = accountNumber;
                finAccAttributeValue.AddressType = addressType;
            }             
        }
        return finAccAttributeValues;
    }

    //looping through the financial account numbers to get the array of financial accounts to add
    private static  List<String> getFinancialAccountIds(List<String> finAccountNumberList, String inputRecordId) {
        List<String> listOfFinAccountIds = new List<String>();
        String finAccountSourceSysId = null;
        String recordId = FSCWlthUtilityClass.getAccountSourceSystemId(inputRecordId);
        if (recordId == null) {
            throw new IllegalArgumentException('Source System ID is null');
        }
        for (String accountNumber : finAccountNumberList) {
            finAccountSourceSysId = FSCWlthUtilityClass.getFinancialAccSourceSystemId(recordId, accountNumber);
            listOfFinAccountIds.add(finAccountSourceSysId);
        }
        return listOfFinAccountIds;
    }

    //make callout with POST method to mulesoft
    private static HttpResponse makeCallout(String inputRecordId, AttributeValueGroup attributeValueGroups, List<FinAccountAttributeValue> finAccAttributeValues, List<String> accountDetails, Map<String, Object> attributes, String requestGuid) {
        
        String recordId = FSCWlthUtilityClass.getAccountSourceSystemId(inputRecordId);
        if (recordId == null) {
            throw new IllegalArgumentException('Source System ID is null');
        }
        String requestParams = '?requestId=' + inputRecordId;
        if (String.isNotBlank(requestGuid)) {
            requestParams = requestParams + '&flowRefId=' + requestGuid;
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('PATCH');
        String endpoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api' + '/' + 'InvestmentAccounts/Update' + requestParams;
        Map<String, Object> payload = constructPayload(inputRecordId, attributeValueGroups, finAccAttributeValues, accountDetails, recordId);
        request.setBody(JSON.serialize(payload, true));
        // set headers
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setEndpoint(endpoint);
        request.setTimeout(TIMEOUT);
        HttpResponse reponse = new Http().send(request);   
        return reponse;      
    }

    //Construct the payload with the travel details
    private static Map<String, Object> constructPayload(String inputRecordId, AttributeValueGroup attributeValueGroups, List<FinAccountAttributeValue> finAccAttributeValues,List<String> accountDetails, String requestGuid) {
        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> investmentAccounts = new Map<String, Object>();
        Map<String, Object> address = new Map<String, Object>();
        List<Map<String, Object>> addressList = new List<Map<String, Object>>();
        
        if (attributeValueGroups.addressLine1 != null) {
            address.put('AddressLine1', attributeValueGroups.addressLine1);
        }
        if (attributeValueGroups.addressLine2 != null) {
            address.put('AddressLine2', attributeValueGroups.addressLine2);
        }
        if (attributeValueGroups.city != null) {
            address.put('City', attributeValueGroups.city);
        }
        if (attributeValueGroups.state != null) {
            address.put('State', attributeValueGroups.state);
        }
        if (attributeValueGroups.postalCode != null) {
            address.put('PostalCode', attributeValueGroups.postalCode);
        }
        if (attributeValueGroups.countryCode != null) {
            address.put('Country', attributeValueGroups.countryCode);
        }
        if (attributeValueGroups.financialAccountUpdated != null) {
            address.put('AddressType', 'Financial Account Address');
        }
        addressList.add(address);
        investmentAccounts.put('AccountIds', accountDetails);
        investmentAccounts.put('Addresses', addressList);
        payload.put('InvestmentAccounts', investmentAccounts);
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