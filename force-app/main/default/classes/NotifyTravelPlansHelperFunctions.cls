/*************************
* @Class Name:- NotifyTravelPlansHelperFunctions
* @Description:- Helper class for Notify Travel Plans FSC service
**************************/
global with sharing class NotifyTravelPlansHelperFunctions implements System.Callable {
    
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = (Map<String, Object>)args.get('input');
        Map<String, Object> outputMap = (Map<String, Object>)args.get('output');
        
        if (action == 'callCreateCaseApi') {
            // retrieve the attributes from the request payload
            String dateOfDeparture = String.valueOf(inputMap.get('dateOfDeparture'));
            String dateOfReturn = String.valueOf(inputMap.get('dateOfReturn'));
            String email = String.valueOf(inputMap.get('email'));
            String phone = String.valueOf(inputMap.get('phone'));
            String mobile = String.valueOf(inputMap.get('mobile'));
            String alternatePhoneCountryCode = String.valueOf(inputMap.get('alternatePhoneCountryCode'));
            String alternatePhoneNumber = String.valueOf(inputMap.get('alternatePhoneNumber'));
            String accountId = String.valueOf(inputMap.get('accountId'));
            String svcCatalogItemDefApiName = String.valueOf(inputMap.get('svcCatalogItemDefApiName'));
            String caseSubject = String.valueOf(inputMap.get('caseSubject'));
            String domesticDestination = String.valueOf(inputMap.get('domesticDestination'));
            String internationalDestination = String.valueOf(inputMap.get('internationalDestination'));
            
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
            
            // set attributes
            if (String.isNotBlank(dateOfDeparture) == true) {
                ConnectApi.GenericObject dateOfDepartureObj = new ConnectApi.GenericObject();
                dateOfDepartureObj.value = dateOfDeparture;
                input.attributes.put('date_of_departure', dateOfDepartureObj);
            }
            if (String.isNotBlank(dateOfReturn) == true) {
                ConnectApi.GenericObject dateOfReturnObj = new ConnectApi.GenericObject();
                dateOfReturnObj.value = dateOfReturn;
                input.attributes.put('date_of_return', dateOfReturnObj);
            }
            if (String.isNotBlank(email) == true) {
                ConnectApi.GenericObject emailObj = new ConnectApi.GenericObject();
                emailObj.value = email;
                input.attributes.put('email', emailObj);
            }
            if (String.isNotBlank(phone) == true) {
                ConnectApi.GenericObject phoneObj = new ConnectApi.GenericObject();
                phoneObj.value = phone;
                input.attributes.put('phone', phoneObj);
            }
            if (String.isNotBlank(mobile) == true) {
                ConnectApi.GenericObject mobileObj = new ConnectApi.GenericObject();
                mobileObj.value = mobile;
                input.attributes.put('mobile', mobileObj);
            }
            if (String.isNotBlank(alternatePhoneCountryCode) == true) {
                ConnectApi.GenericObject alternatePhoneCountryCodeObj = new ConnectApi.GenericObject();
                alternatePhoneCountryCodeObj.value = alternatePhoneCountryCode;
                input.attributes.put('alternate_phone_country_code', alternatePhoneCountryCodeObj);
            }
            if (String.isNotBlank(alternatePhoneNumber) == true) {
                ConnectApi.GenericObject alternatePhoneNumberObj = new ConnectApi.GenericObject();
                alternatePhoneNumberObj.value = alternatePhoneNumber;
                input.attributes.put('alternate_phone_number', alternatePhoneNumberObj);
            }
            if (String.isNotBlank(domesticDestination) == true) {
                ConnectApi.GenericObject domesticDestinationObj = new ConnectApi.GenericObject();
                domesticDestinationObj.value = domesticDestination;
                input.attributes.put('domestic_destination', domesticDestinationObj);
            }
            if (String.isNotBlank(internationalDestination) == true) {
                ConnectApi.GenericObject internationalDestinationObj = new ConnectApi.GenericObject();
                internationalDestinationObj.value = internationalDestination;
                input.attributes.put('international_destination', internationalDestinationObj);
            }
            
            Object cardListObj = inputMap.get('selectedCards');
            String cardListStr;
            if (cardListObj instanceof List<Object>) {
                cardListStr = JSON.serialize(cardListObj);
            } else {
                cardListStr = '['+ JSON.serialize(cardListObj) +']';
            }
            ConnectApi.GenericObject cardDetailsList = new ConnectApi.GenericObject();
            List<Object> untypedList = (List<Object>) JSON.deserializeUntyped(cardListStr);
            List<Map<String, String>> cardDetails = new List<Map<String, String>>();
            Map<String, String> cards;
            for (Object jsonObj :untypedList) {
                Map<String, Object> cardJsonObj = (Map<String, Object>)jsonObj;
                cards = new Map<String, String>();
                cards.put('card_number', String.valueOf(cardJsonObj.get('CardNumberLast4')));
                cards.put('name_on_card', String.valueOf(cardJsonObj.get('CardName')));
                cards.put('ownership_type', String.valueOf(cardJsonObj.get('Role')));
                cards.put('card_valid_until', String.valueOf(cardJsonObj.get('CardValidDate')));
                cardDetails.add(cards);
            }
            if (!cardDetails.isEmpty()) {
                cardDetailsList.value = cardDetails;
                input.attributes.put('cards', cardDetailsList);
            }
            
            // Invoke API
            Map<String, String> responseMap = new Map<String, String>();
            try {
                if (!Test.isRunningTest()) {
                    ConnectApi.ServiceProcessRepresentation output = ConnectApi.IServiceProcessConnectFamily.createCaseServiceProcess(input);
                    responseMap.put('caseId', output.caseId);
                    responseMap.put('caseNumber', output.caseNumber);
                    responseMap.put('svcCatalogRequestId', output.svcCatalogRequestId);
                    outputMap.put('apiResponse', responseMap);
                }
                return outputMap;
            } catch (Exception ex) {
                throw new CalloutException(ex);
            }
        }
        
        //Returns list of countries to the omniscript when remote action is 'getCountryPicklistValues'
        if (action == 'getCountryPicklistValues') {
            Schema.DescribeFieldResult contactCountry = Contact.Finserv__CountryOfBirth__c.getDescribe();
            List<Schema.PicklistEntry> countryPicklistValues = contactCountry.getPicklistValues();
            outputMap.put('countryPicklistValues', countryPicklistValues);
            return outputMap;
        }
        return null;
    }
}