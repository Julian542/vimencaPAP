/*************************
* @Class Name:- FSCWlthUpdateProfileCustomerIntegPrvd
* @Description:- Update Customer Profile integration provider implementation
**************************/
global with sharing class FSCWlthUpdateProfileCustomerIntegPrvd  implements industriesintegrationfwk.ProcessIntegrationProvider {
    
    // Request time out in milliseconds
    private final static Integer TIMEOUT = 120000;
    // Named credential to get MuleSoft endpoint as stored in Setup
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final String PERSON_ACCOUNT_URL_PATH_KEY = 'Person_Account_URL_Path';
    private static final industriesintegrationfwk.ApexProviderAttr NAMED_CRED_ATTR = new industriesintegrationfwk.ApexProviderAttr('Named Credential', NAMED_CREDENTIAL_KEY, 'FSC_wealth_integrations_V1_0_0', true, 'String');
    private static final industriesintegrationfwk.ApexProviderAttr PERSON_ACCOUNT_URL_PATH_ATTR = new industriesintegrationfwk.ApexProviderAttr('Person Account URL Path', PERSON_ACCOUNT_URL_PATH_KEY, '/api/customers/{recordId}', true, 'String');
    
    class FinAccountAttributeValue { 
        String AddressType;
        String AddressLine1;
        String AddressLine2;
        String City;
        String Country;
        String State;
        String PostalCode;
        Integer groupNumber;
    }
    
    class AttributeValueGroup {         
        String phone;
        String mobile;
        String email;
        String firstName;
        String lastName;
        String maritalStatus;
        String employerName;
        String occupation;
        String customerAccountUpdated;
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
            
            for (Integer groupNumber : finAccAttributeValues.keySet()) {
                FinAccountAttributeValue finAccDetailsObj = new FinAccountAttributeValue();
                finAccDetailsObj = finAccAttributeValues.get(groupNumber);
                if (finAccDetailsObj.AddressType =='Shipping Address' || finAccDetailsObj.AddressType =='Billing Address') {
                    finAccAttributeValueDetails.add(finAccDetailsObj);
                }
            }
            if (attributeValueGroups.customerAccountUpdated != null && attributeValueGroups.customerAccountUpdated == 'Yes'){
                HttpResponse response = makeCallout(inputRecordId, attributeValueGroups, finAccAttributeValueDetails, attributes, requestGuid);      
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
                when 'new_first_name' {
                    attributeValueGroups.firstName = svcCatalogReqExtdAttrVal.TextValue;
                } when 'new_last_name' {
                    attributeValueGroups.lastName = svcCatalogReqExtdAttrVal.TextValue;
                } when 'new_email' {
                    attributeValueGroups.email = svcCatalogReqExtdAttrVal.TextValue;
                } when 'new_phone_number' {
                    attributeValueGroups.phone = svcCatalogReqExtdAttrVal.TextValue;
                } when 'new_mobile_number' {
                    attributeValueGroups.mobile = svcCatalogReqExtdAttrVal.TextValue;
                } when 'new_marital_status' {
                    attributeValueGroups.maritalStatus = svcCatalogReqExtdAttrVal.TextValue;
                } when 'new_company' {
                    attributeValueGroups.employerName = svcCatalogReqExtdAttrVal.TextValue;
                } when 'new_occupation' {
                    attributeValueGroups.occupation = svcCatalogReqExtdAttrVal.TextValue;
                } when 'update_customer_account' {
                    attributeValueGroups.customerAccountUpdated = svcCatalogReqExtdAttrVal.TextValue;
                }
            }
        }
        return attributeValueGroups;
    }
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of financial account details
    private static Map<Integer, FinAccountAttributeValue> getFinAccountAttributeValue(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        
        Map<Integer, FinAccountAttributeValue> finAccAttributeValues = new Map<Integer, FinAccountAttributeValue>();
        String addressType = null;
        String addressLine1 = null;
        String addressLine2 = null;
        String city = null;
        String countryCode = null;
        String state = null;
        String postalCode = null;
        
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                when 'account_type' {
                    addressType = svcCatalogReqExtdAttrVal.TextValue;
                } when 'address_line_1' {
                    addressLine1 = svcCatalogReqExtdAttrVal.TextValue;
                } when 'address_line_2' {
                    addressLine2 = svcCatalogReqExtdAttrVal.TextValue;
                } when 'city' {
                    city = svcCatalogReqExtdAttrVal.TextValue;
                } when 'state' {
                    state = svcCatalogReqExtdAttrVal.TextValue;
                } when 'zip_code' {
                    postalCode = svcCatalogReqExtdAttrVal.TextValue;
                } when 'country' {
                    countryCode = svcCatalogReqExtdAttrVal.TextValue;
                }
            }
            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null) {
                FinAccountAttributeValue finAccAttributeValue = finAccAttributeValues.get(groupNumber);  
                Map<String, Object> address = new Map<String, Object>();             
                finAccAttributeValue = new FinAccountAttributeValue();
                finAccAttributeValues.put(groupNumber, finAccAttributeValue);
                finAccAttributeValue.groupNumber = groupNumber;
                finAccAttributeValue.AddressType = addressType; 
                finAccAttributeValue.AddressLine1 = addressLine1;
                finAccAttributeValue.AddressLine2 = addressLine2;
                finAccAttributeValue.City = city;
                finAccAttributeValue.State = state;
                finAccAttributeValue.PostalCode = postalCode;
                finAccAttributeValue.Country = countryCode;  
            }             
        }
        return finAccAttributeValues;
    }
    
    //make callout with POST method to mulesoft
    private static HttpResponse makeCallout(String inputRecordId, AttributeValueGroup attributeValueGroups, List<FinAccountAttributeValue> finAccAttributeValues, Map<String, Object> attributes, String requestGuid) {
        
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
        String endpoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + ((String)attributes.get(PERSON_ACCOUNT_URL_PATH_KEY)).replace('{recordId}', recordId) + requestParams;
        Map<String, Object> payload = constructPayload(inputRecordId, attributeValueGroups, finAccAttributeValues, recordId);
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
    private static Map<String, Object> constructPayload(String inputRecordId, AttributeValueGroup attributeValueGroups, List<FinAccountAttributeValue> finAccAttributeValues, String requestGuid) {
        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> profileInformation = new Map<String, Object>();
        Map<String, Object> employmentDetails = new Map<String, Object>();
        List<FinAccountAttributeValue> finAccountAttributeDetails = new List<FinAccountAttributeValue>();
        
        if (attributeValueGroups.firstName != null) {
            profileInformation.put('FirstName', attributeValueGroups.firstName);
        }
        if (attributeValueGroups.lastName != null) {
            profileInformation.put('LastName', attributeValueGroups.lastName);
        }
        if (attributeValueGroups.mobile != null) {
            profileInformation.put('Mobile', attributeValueGroups.mobile);
        }
        if (attributeValueGroups.email != null) {
            profileInformation.put('Email', attributeValueGroups.email);
        }
        if (attributeValueGroups.phone != null) {
            profileInformation.put('Phone', attributeValueGroups.phone);
        }
        if (attributeValueGroups.mobile != null) {
            profileInformation.put('Mobile', attributeValueGroups.mobile);
        }
        if (attributeValueGroups.maritalStatus != null) {
            profileInformation.put('MaritalStatus', attributeValueGroups.maritalStatus);
        }
        if (attributeValueGroups.employerName != null) {
            employmentDetails.put('EmployerName', attributeValueGroups.employerName);
        }
        if (attributeValueGroups.occupation != null) {
            employmentDetails.put('Occupation', attributeValueGroups.occupation);
        }
        if (attributeValueGroups.employerName != null || attributeValueGroups.occupation != null) {
            profileInformation.put('EmploymentDetails', employmentDetails);
        }
        for (FinAccountAttributeValue finAccDetailsObj : finAccAttributeValues) {
            FinAccountAttributeValue finAccDetails = new FinAccountAttributeValue();
            if (finAccDetailsObj.AddressType != null) {
                finAccDetails.AddressType = finAccDetailsObj.AddressType;
            }
            if (finAccDetailsObj.AddressLine1 != null) {
                finAccDetails.AddressLine1 = finAccDetailsObj.AddressLine1;
            }
            if (finAccDetailsObj.AddressLine2 != null) {
                finAccDetails.AddressLine2 = finAccDetailsObj.AddressLine2;
            }
            if (finAccDetailsObj.City != null) {
                finAccDetails.City = finAccDetailsObj.City;
            }
            if (finAccDetailsObj.State != null) {
                finAccDetails.State = finAccDetailsObj.State;
            }
            if (finAccDetailsObj.PostalCode != null) {
                finAccDetails.PostalCode = finAccDetailsObj.PostalCode;
            }
            if (finAccDetailsObj.Country != null) {
                finAccDetails.Country = finAccDetailsObj.Country;
            }
            finAccountAttributeDetails.add(finAccDetails);
        }
        if (finAccountAttributeDetails.size()>0) {
            profileInformation.put('Addresses', finAccountAttributeDetails);
        }
        payload.put('ProfileInformation', profileInformation);
        return payload;
    }
    
    //Method to get the attribute values from the integration definition
    global static List<industriesintegrationfwk.ApexProviderAttr> getProviderAttributes() {
        List<industriesintegrationfwk.ApexProviderAttr> defaults = new List<industriesintegrationfwk.ApexProviderAttr>();
        defaults.add(NAMED_CRED_ATTR);
        defaults.add(PERSON_ACCOUNT_URL_PATH_ATTR);
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