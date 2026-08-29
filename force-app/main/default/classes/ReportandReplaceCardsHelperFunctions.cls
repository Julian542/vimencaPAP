/*************************
* @Class Name:- ReportandReplaceCardsHelperFunctions
* @Description:- This apex class is helper class for Report and Replace Card FSC service
**************************/

global with sharing class ReportandReplaceCardsHelperFunctions implements System.Callable {
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = (Map<String, Object>)args.get('input');
        Map<String, Object> outputMap = (Map<String, Object>)args.get('output');
        if (action == 'callCreateCaseApi') {
            //retrieve the attributes from the request payload
            String accountId = String.valueOf(inputMap.get('accountId'));
            String svcCatalogItemDefApiName = String.valueOf(inputMap.get('svcCatalogItemDefApiName'));
            String caseSubject = String.valueOf(inputMap.get('caseSubject'));
            String reason = String.valueOf(inputMap.get('reason'));
            String remarks = String.valueOf(inputMap.get('remarks'));
            String addressLine1 = String.valueOf(inputMap.get('addressLine1'));
            String addressLine2 = String.valueOf(inputMap.get('addressLine2'));
            String city = String.valueOf(inputMap.get('city'));
            String state = String.valueOf(inputMap.get('state'));
            String postalCode = String.valueOf(inputMap.get('postalCode'));
            String country = String.valueOf(inputMap.get('country'));
            String shippingPreference = String.valueOf(inputMap.get('shippingPreference'));
            String replaceCard = String.valueOf(inputMap.get('replaceCard'));
            // Set the input rep
            ConnectApi.ServiceProcessRequestInputRepresentation input = new ConnectApi.ServiceProcessRequestInputRepresentation();
            input.svcCatalogItemDefApiName = svcCatalogItemDefApiName;
            input.caseInfo = new Map<String, ConnectApi.GenericObject>();
            input.attributes = new Map<String, ConnectApi.GenericObject>();
            // set case info
            ConnectApi.GenericObject caseAccountId = new ConnectApi.GenericObject();
            caseAccountId.value = accountId;
            input.caseInfo.put('AccountId', caseAccountId);
            ConnectApi.GenericObject caseSubjectGenObj = new ConnectApi.GenericObject();
            caseSubjectGenObj.value = caseSubject;
            input.caseInfo.put('Subject', caseSubjectGenObj);
            Object isCommunitySite = inputMap.get('isCommunitySite');
            ConnectApi.GenericObject caseOriginObj = new ConnectApi.GenericObject();
            if (isCommunitySite != null && Boolean.valueOf(isCommunitySite)) {
                caseOriginObj.value = 'Web';
            } else {
                caseOriginObj.value = 'Phone';
            }
            input.caseInfo.put('Origin', caseOriginObj);
            if (String.isNotBlank(reason) == true) {
                ConnectApi.GenericObject reasonObj = new ConnectApi.GenericObject();
                reasonObj.value = reason;
                input.attributes.put('reason_for_card_block', reasonObj);
            }
            if (String.isNotBlank(remarks) == true) {
                ConnectApi.GenericObject remarksObj = new ConnectApi.GenericObject();
                remarksObj.value = remarks;
                input.attributes.put('comments', remarksObj);
            }
            if (replaceCard == 'Yes') {
                if (String.isNotBlank(addressLine1) == true) {
                    ConnectApi.GenericObject addressLine1Obj = new ConnectApi.GenericObject();
                    addressLine1Obj.value = addressLine1;
                    input.attributes.put('address_line_1', addressLine1Obj);
                }
                if (String.isNotBlank(addressLine2) == true) {
                    ConnectApi.GenericObject addressLine2Obj = new ConnectApi.GenericObject();
                    addressLine2Obj.value = addressLine2;
                    input.attributes.put('address_line_2', addressLine2Obj);
                }
                if (String.isNotBlank(city) == true) {
                    ConnectApi.GenericObject cityObj = new ConnectApi.GenericObject();
                    cityObj.value = city;
                    input.attributes.put('city', cityObj);
                }
                if (String.isNotBlank(state) == true) {
                    ConnectApi.GenericObject stateObj = new ConnectApi.GenericObject();
                    stateObj.value = state;
                    input.attributes.put('state', stateObj);
                }
                if (String.isNotBlank(postalCode) == true) {
                    ConnectApi.GenericObject postalCodeObj = new ConnectApi.GenericObject();
                    postalCodeObj.value = postalCode;
                    input.attributes.put('postal_code', postalCodeObj);
                }
                if (String.isNotBlank(country) == true) {
                    ConnectApi.GenericObject countryObj = new ConnectApi.GenericObject();
                    countryObj.value = country;
                    input.attributes.put('country', countryObj);
                }
                if (String.isNotBlank(shippingPreference) == true) {
                    ConnectApi.GenericObject shippingPreferenceObj = new ConnectApi.GenericObject();
                    shippingPreferenceObj.value = shippingPreference;
                    input.attributes.put('shipping_preference', shippingPreferenceObj);
                }
            }
            Object cardListObj =inputMap.get('selectedCardData');
            String resultStr;
            if (cardListObj instanceof List<Object>) {
                resultStr = JSON.serialize(cardListObj);
            } else {
                resultStr = '['+ JSON.serialize(cardListObj) +']';
            }
            ConnectApi.GenericObject cardDetailsList = new ConnectApi.GenericObject();
            List<Object> untypedList = (List<Object>) JSON.deserializeUntyped(resultStr);
            List<Map<String, String>> cardDetails = new List<Map<String, String>>();
            Map<String, String> cards;
            for (Object jsonObj :untypedList) {
                Map<String, Object> castJsonObj = (Map<String, Object>)jsonObj;
                cards = new Map<String, String>();
                cards.put('card_number', String.valueOf(castJsonObj.get('CardNumberLast4')));
                cards.put('card_type', String.valueOf(castJsonObj.get('CardType')));
                cards.put('replacement_required', String.valueOf(castJsonObj.get('Reissue')));
                cards.put('card_name', String.valueOf(castJsonObj.get('CardName')));
                cards.put('financial_account_type', String.valueOf(castJsonObj.get('RecordTypeName')));
                cardDetails.add(cards);
            }
            if (!cardDetails.isEmpty()) {
                cardDetailsList.value = cardDetails;
                input.attributes.put('cards', cardDetailsList);
            }
            // Invoke API
            Map<String, String> responseMap = new Map<String, String>();
            if (!Test.isRunningTest()) {
                ConnectApi.ServiceProcessRepresentation output = ConnectApi.IServiceProcessConnectFamily.createCaseServiceProcess(input);
                responseMap.put('caseId', output.caseId);
                responseMap.put('caseNumber', output.caseNumber);
                responseMap.put('svcCatalogRequestId', output.svcCatalogRequestId);
            }
            outputMap.put('apiResponse', responseMap);
            return outputMap;
        }
        if (action == 'getUniqueAddress') {
            List<Object> cardListObj = (List<Object>)inputMap.get('MainList'); 
            Set<object> myset = new Set<object>();
            myset.addAll(cardListObj);
            outputMap.put('AddressList', myset);
            return outputMap;
        }
        if (action == 'getCardsData') {
            Object selectedCardData = (inputMap.get('replaceCard') == 'Yes'? inputMap.get('finalListofSelectedCard'):inputMap.get('selectedCardData'));
            outputMap.put('selectedCardData', selectedCardData);
            return outputMap;
        }
        return null;
    }
}