/*************************
* @Class Name:- FSCWlthManageBeneficiariesIntegProvider
* @Description:- Wealth Manage Beneficiaries process integration provider implementation
**************************/
global with sharing class FSCWlthManageBeneficiariesIntegProvider implements industriesintegrationfwk.ProcessIntegrationProvider {
    
    // Request time out in milliseconds
    private final static Integer TIMEOUT = 120000;
    // Named credential to get MuleSoft endpoint as stored in Setup
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final industriesintegrationfwk.ApexProviderAttr NAMED_CRED_ATTR = new industriesintegrationfwk.ApexProviderAttr('Named Credential', 
                                                                                                                                   NAMED_CREDENTIAL_KEY, 'FSC_wealth_integrations_V1_0_0', true, 'String');
    
    class ContingentBeneficiary {
        String MobileNumber;
        String RelationshipType;
        String SharePercentage;
        String BeneficiaryType;
        String EmailAddress;
        String BeneficiaryDob;
        String BeneficiaryName;
        String PerStirpes;
        String SSN;
        String IncorporationDate;
        Integer groupNumber;
        Map<String, Object> Address;
    }
    class PrimaryBeneficiary {
        String MobileNumber;
        String RelationshipType;
        String SharePercentage;
        String BeneficiaryType;
        String EmailAddress;
        String BeneficiaryDob;
        String BeneficiaryName;
        String PerStirpes;
        String SSN;
        String IncorporationDate;
        Integer groupNumber;
        Map<String, Object> Address;
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
            
            String hasContingentBenf;
            List<PrimaryBeneficiary> primaryBeneficiaryDetails = new List<PrimaryBeneficiary>();
            List<ContingentBeneficiary> contingentBeneficiaryDetails = new List<ContingentBeneficiary>();
            List<String> accountDetails = getFinancialAccountIds(svcCatalogReqExtdAttrVals, inputRecordId);
            
            Map<Integer, PrimaryBeneficiary> primBeneficiaryToAddAttrVal = getPrimaryBeneficiary(svcCatalogReqExtdAttrVals);
            for (Integer groupNumber : primBeneficiaryToAddAttrVal.keySet()) {
                PrimaryBeneficiary primBeneficiaryToAddDetailsObj = new PrimaryBeneficiary();
                primBeneficiaryToAddDetailsObj = primBeneficiaryToAddAttrVal.get(groupNumber);
                primaryBeneficiaryDetails.add(primBeneficiaryToAddDetailsObj);
            }
            for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
                If (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'has_contingent_beneficiaries') {
                    hasContingentBenf = svcCatalogReqExtdAttrVal.TextValue;
                }
            }
            If (hasContingentBenf == 'Yes'){                        
                Map<Integer, ContingentBeneficiary> contBeneficiaryToAddAttrVal = getContingentBeneficiary(svcCatalogReqExtdAttrVals);
                for (Integer groupNumber : contBeneficiaryToAddAttrVal.keySet()) {
                    ContingentBeneficiary contBeneficiaryToAddDetailsObj = new ContingentBeneficiary();
                    contBeneficiaryToAddDetailsObj = contBeneficiaryToAddAttrVal.get(groupNumber);
                    contingentBeneficiaryDetails.add(contBeneficiaryToAddDetailsObj);
                }
            }
            
            HttpResponse response = makeCallout(inputRecordId, primaryBeneficiaryDetails, contingentBeneficiaryDetails, accountDetails, attributes, requestGuid);
            
            Map<String, Object> responseGroup = getResponseGroupAfterCallout(response);        
            industriesintegrationfwk.IntegrationCalloutResponse integrationCalloutResponse = new industriesintegrationfwk.IntegrationCalloutResponse(true);
            integrationCalloutResponse.setReturnValue(responseGroup);
            return integrationCalloutResponse;
        } catch (Exception ex) {
            throw new CalloutException(ex);
        }
    }
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of financial accounts to add
    private static  List<String> getFinancialAccountIds(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals, String inputRecordId) {
        
        List<String> financialAccMap = new List<String>();
        String finAccountSourceSysId = null;
        String accountNumber = null;
        
        String recordId = FSCWlthUtilityClass.getAccountSourceSystemId(inputRecordId);
        if (recordId == null) {
            throw new IllegalArgumentException('Source System ID is null');
        }
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                when 'account_number' {
                    accountNumber = svcCatalogReqExtdAttrVal.TextValue;
                    finAccountSourceSysId = FSCWlthUtilityClass.getFinancialAccSourceSystemId(recordId, accountNumber);
                    financialAccMap.add(finAccountSourceSysId);
                }
            }
            
        }
        return financialAccMap;
    }
    
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of primary beneficiaries to add
    private static Map<Integer, PrimaryBeneficiary> getPrimaryBeneficiary(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        Map<Integer, PrimaryBeneficiary> groupNumberPrimaryBeneficiaryMap = new Map<Integer, PrimaryBeneficiary>();
        String mobileNumber = null;
        String relationshipType = null;
        String emailAddress = null;
        String beneficiaryDob = null;
        String beneficiaryName = null;
        String addressLine1 = null;
        String addressLine2 = null;
        String city = null;
        String country = null;
        String state = null;
        String postalCode = null;
        Decimal sharePercentage = null;      
        String beneficiarySSN = null;
        String perStirpes  = null;
        String beneficiaryType  = null;
        
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            Boolean isPrimary = false;
            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                when 'beneficiary_mobile_number' {
                    mobileNumber = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_relationship_type' {
                    relationshipType = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_type' {
                    beneficiaryType = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_email' {
                    emailAddress = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_birth_date_incorporation' {
                    beneficiaryDob = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_name' {
                    if(String.isNotBlank(svcCatalogReqExtdAttrVal.TextValue)) 
                        beneficiaryName = svcCatalogReqExtdAttrVal.TextValue;
                    else 
                        beneficiaryName = null; 
                    isPrimary = true;
                } when 'beneficiary_ssn' {
                    beneficiarySSN = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_address_line_1' {
                    addressLine1 = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_address_line_2' {
                    addressLine2 = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_city' {
                    city = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_state' {
                    state = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_country' {
                    country = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_postal_code' {
                    postalCode = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_per_stirpes' {
                    perStirpes = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_share_percentage' {
                    sharePercentage = svcCatalogReqExtdAttrVal.NumberValue;
                    isPrimary = true;
                }       
            }
            
            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null && isPrimary) {
                
                PrimaryBeneficiary primaryBeneficiary = groupNumberPrimaryBeneficiaryMap.get(groupNumber);               
                primaryBeneficiary = new PrimaryBeneficiary();
                groupNumberPrimaryBeneficiaryMap.put(groupNumber, primaryBeneficiary);
                primaryBeneficiary.groupNumber = groupNumber;
                primaryBeneficiary.MobileNumber = mobileNumber; 
                primaryBeneficiary.RelationshipType = relationshipType;
                primaryBeneficiary.SharePercentage = String.valueOf (sharePercentage);
                primaryBeneficiary.BeneficiaryType = beneficiaryType;  
                primaryBeneficiary.BeneficiaryName = beneficiaryName;
                primaryBeneficiary.PerStirpes = perStirpes;
                if (beneficiaryType == 'Individual')
                    primaryBeneficiary.BeneficiaryDob = beneficiaryDob;
                else
                    primaryBeneficiary.IncorporationDate = beneficiaryDob;
                if (emailAddress != null) {
                    primaryBeneficiary.EmailAddress = emailAddress;
                }
                if (beneficiarySSN != null) {
                    primaryBeneficiary.SSN = beneficiarySSN;
                }
                
                //set beneficiary address
                Map<String, Object> address = new Map<String, Object>();
                address.put('AddressLine1', addressLine1);
                if (addressLine2 != null) {
                    address.put('AddressLine2', addressLine2);
                }
                address.put('City', city);
                address.put('State', state);
                address.put('PostalCode', postalCode);
                address.put('Country', country);
                primaryBeneficiary.Address = address;
            }             
        }
        return groupNumberPrimaryBeneficiaryMap;
    }
    
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of contingent beneficiaries to add
    private static Map<Integer, ContingentBeneficiary> getContingentBeneficiary(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        Map<Integer, ContingentBeneficiary> groupNumberContingentBeneficiaryMap = new Map<Integer, ContingentBeneficiary>();
        String mobileNumber = null;
        String relationshipType = null;
        String emailAddress = null;
        String beneficiaryDob = null;
        String beneficiaryName = null;
        String addressLine1 = null;
        String addressLine2 = null;
        String city = null;
        String country = null;
        String state = null;
        String postalCode = null;
        Decimal sharePercentage = null;      
        String beneficiarySSN = null;
        String perStirpes  = null;
        String beneficiaryType  = null;
        
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                when 'contingent_mobile_number' {
                    mobileNumber = svcCatalogReqExtdAttrVal.TextValue;
                } when 'contingent_relationship_type' {
                    relationshipType = svcCatalogReqExtdAttrVal.TextValue;
                } when 'contingent_beneficiary_type' {
                    beneficiaryType = svcCatalogReqExtdAttrVal.TextValue;
                } when 'contingent_email' {
                    emailAddress = svcCatalogReqExtdAttrVal.TextValue;
                } when 'contingent_birth_date_incorporation' {
                    beneficiaryDob = svcCatalogReqExtdAttrVal.TextValue;
                } when 'contingent_beneficiary_name' {
                    beneficiaryName = svcCatalogReqExtdAttrVal.TextValue;
                } when 'contingent_ssn' {
                    beneficiarySSN = svcCatalogReqExtdAttrVal.TextValue;
                } when 'contingent_address_line_1' {
                    addressLine1 = svcCatalogReqExtdAttrVal.TextValue;
                } when 'contingent_address_line_2' {
                    addressLine2 = svcCatalogReqExtdAttrVal.TextValue;
                } when 'contingent_city' {
                    city = svcCatalogReqExtdAttrVal.TextValue;
                } when 'contingent_state' {
                    state = svcCatalogReqExtdAttrVal.TextValue;
                } when 'contingent_country' {
                    country = svcCatalogReqExtdAttrVal.TextValue;
                } when 'contingent_postal_code' {
                    postalCode = svcCatalogReqExtdAttrVal.TextValue;
                } when 'contingent_per_stirpes' {
                    perStirpes = svcCatalogReqExtdAttrVal.TextValue;
                } when 'contingent_share_percentage' {
                    sharePercentage = svcCatalogReqExtdAttrVal.NumberValue;
                } 
            }
            
            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null) {
                Map<String, Object> address = new Map<String, Object>();
                ContingentBeneficiary contingentBeneficiary = groupNumberContingentBeneficiaryMap.get(groupNumber);               
                contingentBeneficiary = new ContingentBeneficiary();
                groupNumberContingentBeneficiaryMap.put(groupNumber, contingentBeneficiary);
                contingentBeneficiary.groupNumber = groupNumber;
                //set beneficiary details
                contingentBeneficiary.MobileNumber = mobileNumber; 
                contingentBeneficiary.RelationshipType = relationshipType;
                contingentBeneficiary.SharePercentage = String.valueOf (sharePercentage);
                contingentBeneficiary.BeneficiaryType = beneficiaryType;                
                contingentBeneficiary.BeneficiaryName = beneficiaryName;
                contingentBeneficiary.PerStirpes = perStirpes;
                if (beneficiaryType == 'Individual') {
                    contingentBeneficiary.BeneficiaryDob = beneficiaryDob;
                } else {
                    contingentBeneficiary.IncorporationDate = beneficiaryDob;
                }
                if (emailAddress != null) {
                    contingentBeneficiary.EmailAddress = emailAddress;
                }
                if (beneficiarySSN != null) {
                    contingentBeneficiary.SSN = beneficiarySSN;
                }                
                //set beneficiary address
                address.put('AddressLine1', addressLine1);
                if (addressLine2 != null) {
                    address.put('AddressLine2', addressLine2);
                }
                address.put('City', city);
                address.put('State', state);
                address.put('PostalCode', postalCode);
                address.put('Country', country);
                contingentBeneficiary.Address = address;
            }             
        }
        return groupNumberContingentBeneficiaryMap;
    }
    
    //make callout with POST method to mulesoft
    private static HttpResponse makeCallout(String inputRecordId, List<PrimaryBeneficiary> primaryBeneficiaryValues, List<ContingentBeneficiary> contingentBeneficiaryDetails, List<String> accountDetails, Map<String, Object> attributes, String requestGuid) {
        
        String endPoint;
        String recordId = FSCWlthUtilityClass.getAccountSourceSystemId(inputRecordId);
        if (recordId == null) {
            throw new IllegalArgumentException('Source System ID is null');
        }
        
        String requestParams = '?requestId=' + inputRecordId;
        if (String.isNotBlank(requestGuid)){
            requestParams = requestParams + '&flowRefId=' + requestGuid;
        }
        HttpRequest request = new HttpRequest();
        endPoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api' + '/' + 'InvestmentAccounts/Initiate' + requestParams;
        request.setMethod('POST');
        Map<String, Object> payload = constructPayload(inputRecordId, primaryBeneficiaryValues, contingentBeneficiaryDetails, accountDetails);
        request.setBody(JSON.serialize(payload, true));
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setEndpoint(endpoint);
        request.setTimeout(TIMEOUT);
        HttpResponse response = new Http().send(request);
        return response;
    }
    
    //Construct the payload with the beneficiary details
    private static Map<String, Object> constructPayload(String inputRecordId, List<PrimaryBeneficiary> primaryBeneficiaryValues, List<ContingentBeneficiary> contingentBeneficiaryDetails, List<String> accountDetails) {
        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> primaryBenef = new Map<String, Object>();
        Map<String, Object> contingentBenef = new Map<String, Object>();
        Map<String, Object> InvestmentAccounts = new Map<String, Object>();
        
        List<PrimaryBeneficiary> primaryBenefToAddAttributeDetails = new List<PrimaryBeneficiary>();
        for (PrimaryBeneficiary benefToAddDets : primaryBeneficiaryValues) {
            if (benefToAddDets.BeneficiaryName != null) {
                PrimaryBeneficiary primBenefToAddDetails = new PrimaryBeneficiary();
                primBenefToAddDetails.MobileNumber = benefToAddDets.MobileNumber; 
                primBenefToAddDetails.RelationshipType = benefToAddDets.RelationshipType;
                primBenefToAddDetails.BeneficiaryType = benefToAddDets.BeneficiaryType;
                primBenefToAddDetails.EmailAddress = benefToAddDets.EmailAddress;
                primBenefToAddDetails.BeneficiaryDob = benefToAddDets.BeneficiaryDob; 
                primBenefToAddDetails.BeneficiaryName = benefToAddDets.BeneficiaryName;
                primBenefToAddDetails.SharePercentage = benefToAddDets.SharePercentage;
                primBenefToAddDetails.SSN = benefToAddDets.SSN;
                primBenefToAddDetails.IncorporationDate = benefToAddDets.IncorporationDate;
                primBenefToAddDetails.PerStirpes = benefToAddDets.PerStirpes;
                primBenefToAddDetails.Address = benefToAddDets.Address;
                primaryBenefToAddAttributeDetails.add(primBenefToAddDetails);
            }
        }
        
        List<ContingentBeneficiary> contingentBenefToAddAttributeDetails = new List<ContingentBeneficiary>();
        if(contingentBeneficiaryDetails.size()>0){
            for (ContingentBeneficiary benefToAddDets : contingentBeneficiaryDetails) {
                if (benefToAddDets.BeneficiaryName != null) {
                    ContingentBeneficiary contBenefToAddDetails = new ContingentBeneficiary();
                    contBenefToAddDetails.MobileNumber = benefToAddDets.MobileNumber; 
                    contBenefToAddDetails.RelationshipType = benefToAddDets.RelationshipType;
                    contBenefToAddDetails.BeneficiaryType = benefToAddDets.BeneficiaryType;
                    contBenefToAddDetails.EmailAddress = benefToAddDets.EmailAddress;
                    contBenefToAddDetails.BeneficiaryDob = benefToAddDets.BeneficiaryDob; 
                    contBenefToAddDetails.BeneficiaryName = benefToAddDets.BeneficiaryName;
                    contBenefToAddDetails.SharePercentage = benefToAddDets.SharePercentage;
                    contBenefToAddDetails.SSN = benefToAddDets.SSN;
                    contBenefToAddDetails.IncorporationDate = benefToAddDets.IncorporationDate;
                    contBenefToAddDetails.PerStirpes = benefToAddDets.PerStirpes;
                    contBenefToAddDetails.Address = benefToAddDets.Address;
                    contingentBenefToAddAttributeDetails.add(contBenefToAddDetails);
                }
            }
        }
        
        contingentBenef.put('Contingent', contingentBenefToAddAttributeDetails);
        primaryBenef.put('Primary', primaryBenefToAddAttributeDetails);
        contingentBenef.putAll(primaryBenef);
        InvestmentAccounts.put('AccountIds', accountDetails);            
        InvestmentAccounts.put('Beneficiaries', contingentBenef); 
        payload.put('InvestmentAccounts', InvestmentAccounts); 
        
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
        } catch (Exception ex) {
            Map<String, Object> responseMap = new Map<String,Object>();
            responseMap.put('response', responsebody);
            return responseMap;
        }
    }
    
}