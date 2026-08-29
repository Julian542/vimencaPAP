/*************************
* @Class Name:- ManageBeneficiariesIntegrationProvider
* @Description:- Manage Beneficiaries process integration provider implementation
**************************/
global with sharing class ManageBeneficiariesIntegrationProvider implements industriesintegrationfwk.ProcessIntegrationProvider {
    
    // Request time out in milliseconds
    private final static Integer TIMEOUT = 120000;
    // Named credential to get MuleSoft endpoint as stored in Setup
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final String PERSON_ACCOUNT_URL_PATH_KEY = 'Person_Account_URL_Path';
    private static final industriesintegrationfwk.ApexProviderAttr NAMED_CRED_ATTR = new industriesintegrationfwk.ApexProviderAttr('Named Credential', 
                                                                                                                                   NAMED_CREDENTIAL_KEY, 'FSC_fsc_integrations_V1_0_0', true, 'String');
    class AttributeValueGroup { 
        String accountType;
        String accountNumber;
        String actionType;
    }
    
    class BeneficiaryToDeleteAttrValue {
        String BeneficiaryId;
        String BeneficiaryName;
        String BeneficiaryMobile;
        Integer groupNumber;
    }
    
    class BeneficiaryToAddAttrValue {
        String MobileNumber;
        String RelationshipType;
        String IsMinor;
        String EmailAddress;
        String BeneficiaryDob;
        String BeneficiaryName;
        String SSN;
        Integer groupNumber;
        Map<String, Object> Address;
        Map<String, Object> GuardianDetails; 
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
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, GroupNumber, TextValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :inputRecordId WITH SECURITY_ENFORCED ORDER BY GroupNumber ASC NULLS FIRST];
            AttributeValueGroup attributeValueGroups = getAttributeValueGroup(svcCatalogReqExtdAttrVals);
            List<BeneficiaryToDeleteAttrValue> beneficiaryToDeleteAttrValueDetails = new List<BeneficiaryToDeleteAttrValue>();
            List<BeneficiaryToAddAttrValue> beneficiaryToAddAttrValueDetails = new List<BeneficiaryToAddAttrValue>();
            
            if (attributeValueGroups.actionType == 'Delete') {
                Map<Integer, BeneficiaryToDeleteAttrValue> beneficiaryToDeleteAttrVal = getBeneficiaryToDeleteAttrValue(svcCatalogReqExtdAttrVals);
                for (Integer groupNumber : beneficiaryToDeleteAttrVal.keySet()) {
                    BeneficiaryToDeleteAttrValue beneficiaryToDeleteDetailsObj = new BeneficiaryToDeleteAttrValue();
                    beneficiaryToDeleteDetailsObj = beneficiaryToDeleteAttrVal.get(groupNumber);
                    beneficiaryToDeleteAttrValueDetails.add(beneficiaryToDeleteDetailsObj);
                }
            }
            
            if (attributeValueGroups.actionType == 'Add') {
                Map<Integer, BeneficiaryToAddAttrValue> beneficiaryToAddAttrVal = getBeneficiaryToAddAttrValue(svcCatalogReqExtdAttrVals);
                for (Integer groupNumber : beneficiaryToAddAttrVal.keySet()) {
                    BeneficiaryToAddAttrValue beneficiaryToAddDetailsObj = new BeneficiaryToAddAttrValue();
                    beneficiaryToAddDetailsObj = beneficiaryToAddAttrVal.get(groupNumber);
                    beneficiaryToAddAttrValueDetails.add(beneficiaryToAddDetailsObj);
                }
            }
            
            HttpResponse response = makeCallout(inputRecordId, attributeValueGroups, beneficiaryToDeleteAttrValueDetails, beneficiaryToAddAttrValueDetails, attributes, requestGuid);
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
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'action_type') {
                attributeValueGroups.actionType = svcCatalogReqExtdAttrVal.TextValue;                
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'account_type') {
                attributeValueGroups.accountType = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'account_number') {
                attributeValueGroups.accountNumber = svcCatalogReqExtdAttrVal.TextValue;
            } 
        }
        return attributeValueGroups;
    }
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of beneficiary to delete
    private static Map<Integer, BeneficiaryToDeleteAttrValue> getBeneficiaryToDeleteAttrValue(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        Map<Integer, BeneficiaryToDeleteAttrValue> groupNumberToBeneficiaryToDeleteAttrValuesMap = new Map<Integer, BeneficiaryToDeleteAttrValue>();
        String name = null;
        String mobile = null;
        
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'beneficiary_name_to_delete') {
                name = svcCatalogReqExtdAttrVal.TextValue;
            }  else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'mobile') {
                mobile = svcCatalogReqExtdAttrVal.TextValue;
            }
            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null) {
                BeneficiaryToDeleteAttrValue beneficiaryToDeleteAttrValue = groupNumberToBeneficiaryToDeleteAttrValuesMap.get(groupNumber);               
                beneficiaryToDeleteAttrValue = new BeneficiaryToDeleteAttrValue();
                groupNumberToBeneficiaryToDeleteAttrValuesMap.put(groupNumber, beneficiaryToDeleteAttrValue);
                beneficiaryToDeleteAttrValue.groupNumber = groupNumber;
                beneficiaryToDeleteAttrValue.BeneficiaryName = name; 
                beneficiaryToDeleteAttrValue.BeneficiaryMobile = mobile;         
            }             
        }
        return groupNumberToBeneficiaryToDeleteAttrValuesMap;
    }
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of beneficiary to add
    private static Map<Integer, BeneficiaryToAddAttrValue> getBeneficiaryToAddAttrValue(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        Map<Integer, BeneficiaryToAddAttrValue> groupNumberToBeneficiaryToAddAttrValuesMap = new Map<Integer, BeneficiaryToAddAttrValue>();
        String mobileNumber = null;
        String relationshipType = null;
        String isMinor = null;
        String emailAddress = null;
        String beneficiaryDob = null;
        String beneficiaryName = null;
        String addressLine1 = null;
        String addressLine2 = null;
        String city = null;
        String state = null;
        String postalCode = null;
        String country = null;
        String guardianName = null;
        String guardianMobileNumber = null;
        String guardianRelationshipType = null;
        String guardianAddressLine1 = null;
        String guardianAddressLine2 = null;
        String guardianCity = null;
        String guardianState = null;
        String guardianPostalCode = null;
        String guardianCountry = null;
        String beneficiarySSN = null;
        String guardianSSN = null;
        
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                when 'beneficiary_mobile' {
                    mobileNumber = svcCatalogReqExtdAttrVal.TextValue;
                } when 'beneficiary_relationship' {
                    relationshipType = svcCatalogReqExtdAttrVal.TextValue;
                } when 'is_beneficiary_minor' {
                    isMinor = svcCatalogReqExtdAttrVal.TextValue;
                } when 'beneficiary_email' {
                    emailAddress = svcCatalogReqExtdAttrVal.TextValue;
                } when 'beneficiary_birth_date' {
                    beneficiaryDob = svcCatalogReqExtdAttrVal.TextValue;
                } when 'beneficiary_name' {
                    beneficiaryName = svcCatalogReqExtdAttrVal.TextValue;
                } when 'beneficiary_ssn' {
                    beneficiarySSN = svcCatalogReqExtdAttrVal.TextValue;
                } when 'guardian_ssn' {
                    guardianSSN = svcCatalogReqExtdAttrVal.TextValue;
                } when 'address_line_1' {
                    addressLine1 = svcCatalogReqExtdAttrVal.TextValue;
                } when 'address_line_2' {
                    addressLine2 = svcCatalogReqExtdAttrVal.TextValue;
                } when 'city' {
                    city = svcCatalogReqExtdAttrVal.TextValue;
                } when 'state' {
                    state = svcCatalogReqExtdAttrVal.TextValue;
                } when 'country' {
                    country = svcCatalogReqExtdAttrVal.TextValue;
                } when 'postal_code' {
                    postalCode = svcCatalogReqExtdAttrVal.TextValue;
                } when 'guardian_name' {
                    guardianName = svcCatalogReqExtdAttrVal.TextValue;
                } when 'guardian_mobile' {
                    guardianMobileNumber = svcCatalogReqExtdAttrVal.TextValue;
                } when 'guardian_relationship' {
                    guardianRelationshipType = svcCatalogReqExtdAttrVal.TextValue;
                } when 'guardian_address_line_1' {
                    guardianAddressLine1 = svcCatalogReqExtdAttrVal.TextValue;
                } when 'guardian_address_line_2' {
                    guardianAddressLine2 = svcCatalogReqExtdAttrVal.TextValue;
                } when 'guardian_city' {
                    guardianCity = svcCatalogReqExtdAttrVal.TextValue;
                } when 'guardian_state' {
                    guardianState = svcCatalogReqExtdAttrVal.TextValue;
                } when 'guardian_country' {
                    guardianCountry = svcCatalogReqExtdAttrVal.TextValue;
                } when 'guardian_postal_code' {
                    guardianPostalCode = svcCatalogReqExtdAttrVal.TextValue;
                }
            }
          
            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null) {
                Map<String, Object> address = new Map<String, Object>();
                Map<String, Object> guardianAddress = new Map<String, Object>();
                Map<String, Object> guardianDetails = new Map<String, Object>();
                BeneficiaryToAddAttrValue beneficiaryToAddAttrValue = groupNumberToBeneficiaryToAddAttrValuesMap.get(groupNumber);               
                beneficiaryToAddAttrValue = new BeneficiaryToAddAttrValue();
                groupNumberToBeneficiaryToAddAttrValuesMap.put(groupNumber, beneficiaryToAddAttrValue);
                beneficiaryToAddAttrValue.groupNumber = groupNumber;
                //set beneficiary details
                beneficiaryToAddAttrValue.MobileNumber = mobileNumber; 
                beneficiaryToAddAttrValue.RelationshipType = relationshipType;
                beneficiaryToAddAttrValue.IsMinor = isMinor;
                if (emailAddress != null) {
                    beneficiaryToAddAttrValue.EmailAddress = emailAddress;
                }
                if (beneficiarySSN != null) {
                    beneficiaryToAddAttrValue.SSN = beneficiarySSN;
                }
                beneficiaryToAddAttrValue.BeneficiaryDob = beneficiaryDob;
                beneficiaryToAddAttrValue.BeneficiaryName = beneficiaryName;
                //set beneficiary address
                address.put('AddressLine1', addressLine1);
                address.put('AddressLine2', addressLine2);
                address.put('City', city);
                address.put('State', state);
                address.put('PostalCode', postalCode);
                address.put('CountryCode', country);
                beneficiaryToAddAttrValue.Address = address;
                //set Guardian Details if isMinor  True/Yes
                if (isMinor == 'Yes') {
                    guardianDetails.put('Name', guardianName);
                    guardianDetails.put('MobileNumber', guardianMobileNumber);
                    guardianDetails.put('RelationshipType', guardianRelationshipType);
                    if (guardianSSN != null) {
                        guardianDetails.put('SSN', guardianSSN);  
                    }
                    //set guardian address
                    guardianAddress.put('AddressLine1', guardianAddressLine1);
                    guardianAddress.put('AddressLine2', guardianAddressLine2);
                    guardianAddress.put('City', guardianCity);
                    guardianAddress.put('State', guardianState);
                    guardianAddress.put('PostalCode', guardianPostalCode);
                    guardianAddress.put('CountryCode', guardianCountry);
                    guardianDetails.put('Address', guardianAddress);
                    beneficiaryToAddAttrValue.GuardianDetails = guardianDetails;
                }
            }             
        }
        return groupNumberToBeneficiaryToAddAttrValuesMap;
    }
    
    //make callout with POST method to mulesoft
    private static HttpResponse makeCallout(String inputRecordId, AttributeValueGroup attributeValueGroups, List<BeneficiaryToDeleteAttrValue> beneficiaryToDeleteAttrValue, List<BeneficiaryToAddAttrValue> beneficiaryToAddAttrValue, Map<String, Object> attributes, String requestGuid) {
        String financialAccountRoleId;
        String endPoint;
        String recordId = FSCUtilityClass.getAccountSourceSystemId(inputRecordId);
        if (recordId == null) {
            throw new IllegalArgumentException('Source System ID is null');
        }
        String financialAccountId = FSCUtilityClass.getFinancialAccountId(recordId, attributeValueGroups.accountNumber);
        if (financialAccountId == null) {
            throw new IllegalArgumentException('Financial Account ID is null');
        }
        String financialAccountSysId = FSCUtilityClass.getFinancialAccSourceSystemId(recordId, attributeValueGroups.accountNumber);
        if (financialAccountSysId == null) {
            throw new IllegalArgumentException('Financial Account Source System ID is null');
        }
        String accountType = industriesintegrationfwk.IntegrationsProviderUtil.getServiceDomain(financialAccountId);  
        String requestParams = '?requestId=' + inputRecordId;
        if (String.isNotBlank(requestGuid)){
            requestParams = requestParams + '&flowRefId=' + requestGuid;
        }
        HttpRequest request = new HttpRequest();
        if (attributeValueGroups.actionType == 'Add') {
            endPoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api' + '/' + accountType + '/' + recordId + '/Initiate' + requestParams;
            request.setMethod('POST');
        } else if (attributeValueGroups.actionType == 'Delete') {
            endPoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api' + '/' + accountType + '/' + recordId + '/Delete' + requestParams;
            request.setMethod('DELETE');
        }
        Map<String, Object> payload = constructPayload(inputRecordId, attributeValueGroups, beneficiaryToDeleteAttrValue, beneficiaryToAddAttrValue, financialAccountSysId);
        request.setBody(JSON.serialize(payload, true));
        // set headers
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setEndpoint(endpoint);
        request.setTimeout(TIMEOUT);
        HttpResponse response = new Http().send(request);
        return response;
    }
    
    //Construct the payload with the beneficiary details
    private static Map<String, Object> constructPayload(String inputRecordId, AttributeValueGroup attributeValueGroups, List<BeneficiaryToDeleteAttrValue> beneficiaryToDeleteAttrValue, List<BeneficiaryToAddAttrValue> beneficiaryToAddAttrValue, String financialAccountSysId) {
        Map<String, Object> payload = new Map<String, Object>();
        
        if (attributeValueGroups.actionType == 'Add') {
            List<BeneficiaryToAddAttrValue> benefToAddAttributeDetails = new List<BeneficiaryToAddAttrValue>();
            for (BeneficiaryToAddAttrValue benefToAddDets : beneficiaryToAddAttrValue) {
                BeneficiaryToAddAttrValue benefToAddDetails = new BeneficiaryToAddAttrValue();
                benefToAddDetails.MobileNumber = benefToAddDets.MobileNumber; 
                benefToAddDetails.RelationshipType = benefToAddDets.RelationshipType;
                benefToAddDetails.IsMinor = benefToAddDets.IsMinor; 
                benefToAddDetails.EmailAddress = benefToAddDets.EmailAddress;
                benefToAddDetails.BeneficiaryDob = benefToAddDets.BeneficiaryDob; 
                benefToAddDetails.BeneficiaryName = benefToAddDets.BeneficiaryName;
                benefToAddDetails.Address = benefToAddDets.Address;
                if (benefToAddDets.IsMinor == 'Yes'){
                    benefToAddDetails.GuardianDetails = benefToAddDets.GuardianDetails;  
                }
                benefToAddAttributeDetails.add(benefToAddDetails);
            }
            payload.put('Beneficiaries', benefToAddAttributeDetails); 
        }
        else if (attributeValueGroups.actionType == 'Delete') {
            Map<String, String> benefToDeleteAttr = new Map<String, String>();
            Map<String, String> benefToDeleteMobileMap = new Map<String, String>();
            List<BeneficiaryToDeleteAttrValue> benefToDeleteAttributeDetails = new List<BeneficiaryToDeleteAttrValue>();
            Map<String, Map<String, String>> benefToDeleteDetail = FSCUtilityClass.getFinanAccRoleSourceSystemId(financialAccountSysId);
            benefToDeleteAttr = benefToDeleteDetail.get('SourceSystemId');
            benefToDeleteMobileMap = benefToDeleteDetail.get('Mobile');
            for (BeneficiaryToDeleteAttrValue benefToDeleteDets : beneficiaryToDeleteAttrValue) {
                BeneficiaryToDeleteAttrValue benefToDeleteDetails = new BeneficiaryToDeleteAttrValue();
                if (benefToDeleteMobileMap.get(benefToDeleteDets.BeneficiaryName) == benefToDeleteDets.BeneficiaryMobile) {
                    benefToDeleteDetails.BeneficiaryId = benefToDeleteAttr.get(benefToDeleteDets.BeneficiaryName); 
                }
                benefToDeleteDetails.BeneficiaryName = benefToDeleteDets.BeneficiaryName;
                benefToDeleteAttributeDetails.add(benefToDeleteDetails);
            }
            payload.put('Beneficiaries', benefToDeleteAttributeDetails);
        }
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
        if (response.getStatusCode() == 201 || response.getStatusCode() == 200) {
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
            Map<String, Object> responseMap = new Map<String,Object>();
            responseMap.put('response', responsebody);
            return responseMap;
        }
    }
    
}