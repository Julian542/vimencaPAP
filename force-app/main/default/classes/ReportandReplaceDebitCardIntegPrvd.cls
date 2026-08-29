/*************************
* @Class Name:- ReportandReplaceDebitCardIntegPrvd
* @Description:- Report And Replace Debit Card process integration provider implementation
**************************/
global with sharing class ReportandReplaceDebitCardIntegPrvd implements industriesintegrationfwk.ProcessIntegrationProvider {
    
    // Request time out in milliseconds
    private final static Integer TIMEOUT = 120000;  
    // Named credential to get MuleSoft endpoint as stored in Setup
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final industriesintegrationfwk.ApexProviderAttr NAMED_CRED_ATTR = new industriesintegrationfwk.ApexProviderAttr('Named Credential', NAMED_CREDENTIAL_KEY, 'FSC_fsc_integrations_V1_0_0', true, 'String');
    
    class AttributeValueGroup {         
        String reason;
        String remarks;
        String shippingPreference;
        String addressLine1;
        String addressLine2;
        String city;
        String state;
        String postalCode;
        String country;  
    }
    
    class CardAttributeValue {
        String CardId;
        String cardNumber;
        String ToBeReissued;
        String cardType;     
        String financialAccountType;      
        Integer groupNumber;
    }
    
    class CardFinAccAttributeValue {
        String AccountId;
        List<CardAttributeValue> Cards;
    }
    
    /**
* @param requestGuid                 Request GUID provided by the client
* @param inputRecordId               Input Record ID provided by the client
* @param payload                     Payload to be passed to the Provider Class
* @param attributes                  Map of config attributes
* @return industriesintegrationfwk.IntegrationCalloutResponse sent to the client
*/
    global static industriesintegrationfwk.IntegrationCalloutResponse executeCallout(String requestGuid, String inputRecordId, String payload, Map<String, Object> attributes) {
        
        if (String.isBlank(inputRecordId)) {
            throw new IllegalArgumentException('Service Process ID is null');
        }
        try {
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, GroupNumber, TextValue, IntegerValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :inputRecordId WITH SECURITY_ENFORCED ORDER BY GroupNumber ASC NULLS FIRST];
            AttributeValueGroup attributeValueGroups = getAttributeValueGroup(svcCatalogReqExtdAttrVals);
            Map<Integer, CardAttributeValue> cardAttributeValues = getCardAttributeValue(svcCatalogReqExtdAttrVals);
            List<CardAttributeValue> savingsCardAttributeValueDetails = new List<CardAttributeValue>();
            List<CardAttributeValue> checkingCardAttributeValueDetails = new List<CardAttributeValue>();
            for (Integer groupNumber : cardAttributeValues.keySet()) {
                CardAttributeValue cardDetailsObj = new CardAttributeValue();
                cardDetailsObj = cardAttributeValues.get(groupNumber);
                if (cardDetailsObj.cardType == 'Debit Card') {
                    if (cardDetailsObj.financialAccountType == 'Savings Account') {
                        savingsCardAttributeValueDetails.add(cardDetailsObj);
                    } else if (cardDetailsObj.financialAccountType == 'Checking Account') {
                        checkingCardAttributeValueDetails.add(cardDetailsObj); 
                    }
                }
            }
            if((savingsCardAttributeValueDetails.size() > 0 && savingsCardAttributeValueDetails != null) || (checkingCardAttributeValueDetails.size() > 0 && checkingCardAttributeValueDetails != null)) {
                HttpResponse response = makeCallout(inputRecordId, attributeValueGroups, savingsCardAttributeValueDetails, checkingCardAttributeValueDetails, attributes, requestGuid);
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
    
    //getting all the Reissue details by looping through svcCatalogReqExtdAttrVals records
    private static AttributeValueGroup getAttributeValueGroup(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        AttributeValueGroup attributeValueGroups = new AttributeValueGroup();           
        for(SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'reason_for_card_block') {
                attributeValueGroups.reason = svcCatalogReqExtdAttrVal.TextValue;                
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'comments') {
                attributeValueGroups.remarks = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'shipping_preference') {
                attributeValueGroups.shippingPreference = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'address_line_1') {
                attributeValueGroups.addressLine1 = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'address_line_2') {
                attributeValueGroups.addressLine2 = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'city') {
                attributeValueGroups.city = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'state') {
                attributeValueGroups.state = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'postal_code') {
                attributeValueGroups.postalCode = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'country') {
                attributeValueGroups.country = svcCatalogReqExtdAttrVal.TextValue;
            }
        }
        return attributeValueGroups;
    }
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of cards
    private static Map<Integer, CardAttributeValue> getCardAttributeValue(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        Map<Integer, CardAttributeValue> cardAttributeValues = new Map<Integer, CardAttributeValue>();
        String cardNumber = null;
        String toBeReissued;
        String cardType = null;
        String financialAccountType = null;
        
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'card_number') {
                cardNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'replacement_required') {
                toBeReissued = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'card_type') {
                cardType = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'financial_account_type') {     
                financialAccountType = svcCatalogReqExtdAttrVal.TextValue;
            }
            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null) {
                CardAttributeValue cardAttributeValue = cardAttributeValues.get(groupNumber);               
                cardAttributeValue = new CardAttributeValue();
                cardAttributeValues.put(groupNumber, cardAttributeValue);
                cardAttributeValue.groupNumber = groupNumber;
                cardAttributeValue.cardType = cardType; 
                cardAttributeValue.cardNumber = cardNumber;
                cardAttributeValue.ToBeReissued = toBeReissued;   
                cardAttributeValue.financialAccountType = financialAccountType;            
            }             
        }
        return cardAttributeValues;
    }
    
    //make callout with POST method to mulesoft
    private static HttpResponse makeCallout(String inputRecordId, AttributeValueGroup attributeValueGroups, List<CardAttributeValue> savingsCardAttributeValueDetails, List<CardAttributeValue> checkingCardAttributeValueDetails, Map<String, Object> attributes, String requestGuid) {
        Integer savingsResponseStatusCode;
        Integer checkingResponseStatusCode;
        String savingsResponseStatus;
        String checkingResponseStatus;
        String finalResponseBody = '';
        String recordId = FSCUtilityClass.getAccountSourceSystemId(inputRecordId);
        
        if (recordId == null) {
            throw new IllegalArgumentException('Source System ID is null');
        }
        HttpResponse finalresponse = new HttpResponse();
        String requestParams = '?requestId=' + inputRecordId;
        if (String.isNotBlank(requestGuid)) {
            requestParams = requestParams + '&flowRefId=' + requestGuid;
        }
        
        if (savingsCardAttributeValueDetails.size() > 0 && savingsCardAttributeValueDetails != null) {
            HttpRequest savingsRequest = new HttpRequest();
            savingsRequest.setMethod('PUT');
            String savingsEndpoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api/SavingsAccount/IssuedDevice/Request' + requestParams;
            Map<String, Object> payload = constructPayload(inputRecordId, attributeValueGroups, savingsCardAttributeValueDetails, recordId);
            savingsRequest.setBody(JSON.serialize(payload, true));
            // set headers
            savingsRequest.setHeader('Content-Type', 'application/json');
            savingsRequest.setHeader('Accept', 'application/json');
            savingsRequest.setEndpoint(savingsEndpoint);
            savingsRequest.setTimeout(TIMEOUT);
            HttpResponse savingsResponse = new Http().send(savingsRequest);
            savingsResponseStatusCode = savingsResponse.getStatusCode();
            savingsResponseStatus = savingsResponse.getStatus();
            finalResponseBody = finalResponseBody+'SavingsResponse:'+savingsResponse.getBody();
        }
        if (checkingCardAttributeValueDetails.size() > 0 && checkingCardAttributeValueDetails != null) {
            HttpRequest checkingRequest = new HttpRequest();
            checkingRequest.setMethod('PUT');
            String checkingEndpoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api/CurrentAccount/IssuedDevice/Request' + requestParams;
            Map<String, Object> payload = constructPayload(inputRecordId, attributeValueGroups, checkingCardAttributeValueDetails, recordId);
            checkingRequest.setBody(JSON.serialize(payload, true));
            // set headers
            checkingRequest.setHeader('Content-Type', 'application/json');
            checkingRequest.setHeader('Accept', 'application/json');
            checkingRequest.setEndpoint(checkingendpoint);
            checkingRequest.setTimeout(TIMEOUT);
            HttpResponse checkingResponse = new Http().send(checkingRequest);
            checkingResponseStatusCode = checkingResponse.getStatusCode();
            checkingResponseStatus = checkingResponse.getStatus();
            finalResponseBody = finalResponseBody+'CheckingResponse:'+checkingResponse.getBody();
        }
        if (savingsResponseStatusCode !=null && checkingResponseStatusCode !=null ) {//Both Savings and Checkings Selected
            if (savingsResponseStatusCode == 200 && checkingResponseStatusCode == 200) {
                finalresponse.setStatus('Created');
                finalresponse.setStatusCode(200);
                finalresponse.setBody(finalResponseBody);
            } else {
                if (savingsResponseStatusCode != 200) {//Only Savings Request Failed
                    finalresponse.setStatus(savingsResponseStatus);
                    finalresponse.setStatusCode(savingsResponseStatusCode);
                } else if (checkingResponseStatusCode != 200) {//Only Checking Request Failed
                    finalresponse.setStatus(checkingResponseStatus);
                    finalresponse.setStatusCode(checkingResponseStatusCode);
                }
                finalresponse.setBody(finalResponseBody);
            }
        } else if (savingsResponseStatusCode != null) {//Only Savings Selected
            finalresponse.setStatus(savingsResponseStatus);
            finalresponse.setStatusCode(savingsResponseStatusCode);
            finalresponse.setBody(finalResponseBody);
        } else if (checkingResponseStatusCode != null) {//Only Checkings Selected
            finalresponse.setStatus(checkingResponseStatus);
            finalresponse.setStatusCode(checkingResponseStatusCode);
            finalresponse.setBody(finalResponseBody);
        }
        return finalresponse;
    }
    
    //Construct the payload with the Report and Reissue details
    private static Map<String, Object> constructPayload(String inputRecordId, AttributeValueGroup attributeValueGroups, List<CardAttributeValue> cardAttributeValues, String recordId) {
        //Check to add reissue required attributes to payload
        Boolean isReissue = false;
        Map<String, Map<String,String>> cardDet = FSCUtilityClass.getCardsSourceSystemId(recordId);
        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> issuedInventoryOptionDefinition = new Map<String, Object>();
        Map<String, Object> issuedDevice = new Map<String, Object>();
        Map<String, String> cardAttr = new Map<String, String>();
        Map<String, String> cardFinAccAttr = new Map<String, String>();
        Set<String> setOfFinAccIds = new Set<String>();
        List<CardFinAccAttributeValue> cardFinAccAttributeValue  = new List<CardFinAccAttributeValue>();
        cardAttr = cardDet.get('SourceSystemId');
        cardFinAccAttr = cardDet.get('FASourceSystemId');  
        setOfFinAccIds.addAll(cardFinAccAttr.values()); 
        
        for (String finAttr : setOfFinAccIds) {
            CardFinAccAttributeValue cardFinAccDetails = new CardFinAccAttributeValue();
            List<CardAttributeValue> cardAttributeDetails = new List<CardAttributeValue>();
            for (CardAttributeValue cardDets : cardAttributeValues) {
                CardAttributeValue cardDetails = new CardAttributeValue();
                if (finAttr == cardFinAccAttr.get(cardDets.cardNumber)) {
                    cardDetails.CardId = cardAttr.get(cardDets.cardNumber); 
                    cardDetails.ToBeReissued = cardDets.ToBeReissued;
                    if (cardDets.ToBeReissued == 'Yes' && isReissue == false) {
                        isReissue = true;
                    }
                    cardAttributeDetails.add(cardDetails);
                }
            }
            cardFinAccDetails.AccountId= finAttr;
            cardFinAccDetails.Cards = new List<CardAttributeValue>();
            cardFinAccDetails.Cards.addAll(cardAttributeDetails);
            if (cardAttributeDetails.size() >0) {
                cardFinAccAttributeValue.add(cardFinAccDetails);
            }
        }
        issuedInventoryOptionDefinition.put('Accounts', cardFinAccAttributeValue);
        if (attributeValueGroups.reason != null) {
            issuedInventoryOptionDefinition.put('Reason', attributeValueGroups.reason);
        }
        if (attributeValueGroups.remarks != null) {
            issuedInventoryOptionDefinition.put('Remarks', attributeValueGroups.remarks);
        }
        if (isReissue == true) {
            if(attributeValueGroups.shippingPreference != null) {
                issuedInventoryOptionDefinition.put('ShippingPreference', attributeValueGroups.shippingPreference);
            }
            Map<String, Object> shippingAddress = new Map<String, Object>();
            if (attributeValueGroups.addressLine1 != null) {
                shippingAddress.put('AddressLine1', attributeValueGroups.addressLine1);
            }
            if (attributeValueGroups.state != null) {
                shippingAddress.put('State', attributeValueGroups.state);
            }
            if (attributeValueGroups.country != null) {
                shippingAddress.put('CountryCode', attributeValueGroups.country);
            }
            if (attributeValueGroups.city != null) {
                shippingAddress.put('City', attributeValueGroups.city);
            }
            if (attributeValueGroups.addressLine2 != null) {
                shippingAddress.put('AddressLine2', attributeValueGroups.addressLine2);
            }
            if (attributeValueGroups.postalCode != null) {
                shippingAddress.put('PostalCode', attributeValueGroups.postalCode);
            }
            issuedInventoryOptionDefinition.put('ShippingAddress', shippingAddress);
        }
        issuedDevice.put('IssuedInventoryOptionDefinition', issuedInventoryOptionDefinition);
        issuedDevice.put('IssuedInventoryStatus', 'REPLACE');
        issuedDevice.put('IssuedInventoryDescription', 'replace debit card');
        issuedDevice.put('IssuedInventoryType', 'debit card');
        payload.put('IssuedDevice', issuedDevice);
        return payload;
    }
    
    global static List<industriesintegrationfwk.ApexProviderAttr> getProviderAttributes() {
        List<industriesintegrationfwk.ApexProviderAttr> defaults = new List<industriesintegrationfwk.ApexProviderAttr>();
        defaults.add(NAMED_CRED_ATTR);
        return defaults;
    }
    
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