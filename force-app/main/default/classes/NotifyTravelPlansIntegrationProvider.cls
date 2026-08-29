/*************************
* @Class Name:- NotifyTravelPlansIntegrationProvider
* @Description:- Notify Travel Plan process integration provider implementation
**************************/
global with sharing class NotifyTravelPlansIntegrationProvider implements industriesintegrationfwk.ProcessIntegrationProvider {
    
    // Request time out in milliseconds
    private final static Integer TIMEOUT = 120000;
    // Named credential to get MuleSoft endpoint as stored in Setup
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final String PERSON_ACCOUNT_URL_PATH_KEY = 'Person_Account_URL_Path';
    private static final industriesintegrationfwk.ApexProviderAttr NAMED_CRED_ATTR = new industriesintegrationfwk.ApexProviderAttr('Named Credential', 
                                                                                                                                   NAMED_CREDENTIAL_KEY, 'FSC_fsc_integrations_V1_0_0', true, 'String');
    private static final industriesintegrationfwk.ApexProviderAttr PERSON_ACCOUNT_URL_PATH_ATTR = new industriesintegrationfwk.ApexProviderAttr('Person Account URL Path', 
                                                                                                                                                PERSON_ACCOUNT_URL_PATH_KEY, '/api/customers/{recordId}', true, 'String');
    class AttributeValueGroup {  
        String alternatePhNumber;
        String phone;
        String mobile;
        String email;
        String altPhCountryCode;
        String returnDate;            
        List<String> domesticDestination;
        String departureDate;
        List<String> internationalDestination;
        String dateOfReturn;
    }
    
    class CardAttributeValue {
        String Role;
        String Id;
        String ExpiryDate;
        String Name;
        String cardNum;
        Integer groupNumber;
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
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = new List<SvcCatalogReqExtdAttrVal>();
            svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, GroupNumber, TextValue, IntegerValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :inputRecordId WITH SECURITY_ENFORCED ORDER BY GroupNumber ASC NULLS FIRST];
            AttributeValueGroup attributeValueGroups = getAttributeValueGroup(svcCatalogReqExtdAttrVals);
            Map<Integer, CardAttributeValue> cardAttributeValues = getCardAttributeValue(svcCatalogReqExtdAttrVals);
            List<CardAttributeValue> cardAttributeValueDetails = new List<CardAttributeValue>();
            for (Integer groupNumber : cardAttributeValues.keySet()) {
                CardAttributeValue cardDetailsObj = new CardAttributeValue();
                cardDetailsObj = cardAttributeValues.get(groupNumber);
                cardAttributeValueDetails.add(cardDetailsObj);
            }
            HttpResponse response = makeCallout(inputRecordId, attributeValueGroups, cardAttributeValueDetails, attributes, requestGuid);
            Map<String, Object> responseGroup = getResponseGroupAfterCallout(response);        
            industriesintegrationfwk.IntegrationCalloutResponse integrationCalloutResponse = new industriesintegrationfwk.IntegrationCalloutResponse(true);
            integrationCalloutResponse.setReturnValue(responseGroup);
            return integrationCalloutResponse;
        } catch (Exception ex) {
            throw new CalloutException(ex);
        }
    }
    
    //getting all the trave details by looping through svcCatalogReqExtdAttrVals records
    private static AttributeValueGroup getAttributeValueGroup(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        AttributeValueGroup attributeValueGroups = new AttributeValueGroup();           
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'alternate_phone_country_code') {
                attributeValueGroups.altPhCountryCode = svcCatalogReqExtdAttrVal.TextValue;                
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'alternate_phone_number') {
                attributeValueGroups.alternatePhNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'phone') {
                attributeValueGroups.phone = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'email') {
                attributeValueGroups.email = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'mobile') {
                attributeValueGroups.mobile = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'date_of_return') {
                attributeValueGroups.dateOfReturn = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'date_of_departure') {
                attributeValueGroups.departureDate = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'domestic_destination') {
                attributeValueGroups.domesticDestination = new List<String>();
                for (String domDestination : svcCatalogReqExtdAttrVal.TextValue.split(',')) {
                    if (!String.isBlank(domDestination)) {
                        attributeValueGroups.domesticDestination.add(domDestination.trim());
                    }
                }                
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'international_destination') {
                attributeValueGroups.internationalDestination = new List<String>();
                for (String intDestination : svcCatalogReqExtdAttrVal.TextValue.split(',')) {
                    if (!String.isBlank(intDestination)) {
                        attributeValueGroups.internationalDestination.add(intDestination.trim());
                    }
                }      
            }
        }
        return attributeValueGroups;
    }
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of cards
    private static Map<Integer, CardAttributeValue> getCardAttributeValue(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        Map<Integer, CardAttributeValue> groupNumberToCardAttributeValuesMap = new Map<Integer, CardAttributeValue>();
        String name = null;
        String id = null;
        String expiryDate = null;
        String role = null;
        String cardNum = null;
        
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'ownership_type') {
                role = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'card_number') {
                cardNum = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'card_valid_until') {
                expiryDate = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'name_on_card') {
                name = svcCatalogReqExtdAttrVal.TextValue;
            }
            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null) {
                CardAttributeValue cardAttributeValue = groupNumberToCardAttributeValuesMap.get(groupNumber);               
                cardAttributeValue = new CardAttributeValue();
                groupNumberToCardAttributeValuesMap.put(groupNumber, cardAttributeValue);
                cardAttributeValue.groupNumber = groupNumber;
                cardAttributeValue.Name = name;
                cardAttributeValue.ExpiryDate = expiryDate;
                cardAttributeValue.Role = role;
                cardAttributeValue.cardNum = cardNum;               
            }             
        }
        return groupNumberToCardAttributeValuesMap;
    }
    
    //make callout with POST method to mulesoft
    private static HttpResponse makeCallout(String inputRecordId, AttributeValueGroup attributeValueGroups, List<CardAttributeValue> cardAttributeValues, Map<String, Object> attributes, String requestGuid) {
        String recordId = FSCUtilityClass.getAccountSourceSystemId(inputRecordId);
        if (recordId == null) {
            throw new IllegalArgumentException('Source System ID is null');
        }
        
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        String requestParams = '?requestId=' + inputRecordId;
        If (String.isNotBlank(requestGuid)){
            requestParams = requestParams + '&flowRefId=' + requestGuid;
        }
        String endpoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + ((String) attributes.get(PERSON_ACCOUNT_URL_PATH_KEY)).replace('{recordId}', recordId) + '/travel-notifications' + requestParams;
        Map<String, Object> payload = constructPayload(inputRecordId, attributeValueGroups, cardAttributeValues, recordId);
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
    private static Map<String, Object> constructPayload(String inputRecordId, AttributeValueGroup attributeValueGroups, List<CardAttributeValue> cardAttributeValues, String recordId) {
        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> travelDetail = new Map<String, Object>();
        Map<String, Object> communicationPreferences = new Map<String, Object>();
        Map<String, Object> phoneNumber = new Map<String, Object>();
        Map<String, Object> mobileNumber = new Map<String, Object>();
        Map<String, Object> alternatePhone = new Map<String, Object>();
        Map<String, Map<String, String>> cardDet = FSCUtilityClass.getCardsSourceSystemId(recordId);
        Map<String, String> cardAttr = new Map<String, String>();
        Map<String, String> cardValidMap = new Map<String, String>();
        List<CardAttributeValue> cardAttributeDetails = new List<CardAttributeValue>();
        
        travelDetail.put('ReturnDate', attributeValueGroups.dateOfReturn);
        travelDetail.put('DepartureDate', attributeValueGroups.departureDate);
        if (attributeValueGroups.domesticDestination != null) {
            travelDetail.put('UsDestinations', attributeValueGroups.domesticDestination);
        }
        if (attributeValueGroups.internationalDestination != null) {
            travelDetail.put('InternationalDestinations', attributeValueGroups.internationalDestination);
        }
        if (attributeValueGroups.alternatePhNumber != null) {
            alternatePhone.put('CountryCode', attributeValueGroups.altPhCountryCode);
            alternatePhone.put('PhoneNumber', attributeValueGroups.alternatePhNumber);
            communicationPreferences.put('AlternatePhone', alternatePhone);
        }
        if (attributeValueGroups.mobile != null) {
            mobileNumber.put('PhoneNumber', attributeValueGroups.mobile);
            communicationPreferences.put('Mobile', mobileNumber);
        }
        if (attributeValueGroups.phone != null) {
            phoneNumber.put('PhoneNumber', attributeValueGroups.phone);
            communicationPreferences.put('Phone', phoneNumber);
        }
        if (attributeValueGroups.email != null) {
            communicationPreferences.put('Email', attributeValueGroups.email);
        }
        payload.put('TravelDetail', travelDetail);
        payload.put('CommunicationPreferences', communicationPreferences);
        
        cardAttr = cardDet.get('SourceSystemId');
        cardValidMap = cardDet.get('ValidUntill');
        for (CardAttributeValue cardDets : cardAttributeValues) {
            CardAttributeValue cardDetails = new CardAttributeValue();
            cardDetails.Role = cardDets.Role;
            if (cardValidMap.get(cardDets.cardNum) == cardDets.ExpiryDate) {
                cardDetails.Id = cardAttr.get(cardDets.cardNum); 
            }
            cardDetails.ExpiryDate = cardDets.ExpiryDate;
            cardDetails.Name = cardDets.Name;
            cardAttributeDetails.add(cardDetails);
        }
        payload.put('Cards', cardAttributeDetails);
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
            Map<String, Object> responseMap = new Map<String, Object>();
            responseMap.put('response', responsebody);
            return responseMap;
        }
    }
}