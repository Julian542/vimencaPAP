/*************************
* @Class Name:- OrderCheckbookHelperFunctions
* @Description:-  Helper class for Order Checkbook FSC service
**************************/
global with sharing class OrderCheckbookHelperFunctions implements System.Callable {

    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = (Map<String, Object>)args.get('input');
        Map<String, Object> outputMap = (Map<String, Object>)args.get('output');

        if (action == 'callCreateCaseApi') {
            //retrieve the attributes from the request payload
            String accountId = String.valueOf(inputMap.get('accountId'));
            String svcCatalogItemDefApiName = String.valueOf(inputMap.get('svcCatalogItemDefApiName'));
            String caseSubject = String.valueOf(inputMap.get('caseSubject'));
            String noofCheck = String.valueOf(inputMap.get('noofCheck'));
            String addressLine1 = String.valueOf(inputMap.get('addressLine1'));
            String addressLine2 = String.valueOf(inputMap.get('addressLine2'));
            String city = String.valueOf(inputMap.get('city'));
            String state = String.valueOf(inputMap.get('state'));
            String postalCode = String.valueOf(inputMap.get('postalCode'));
            String country = String.valueOf(inputMap.get('country'));
            String shippingPreference = String.valueOf(inputMap.get('shippingPreference'));
            String financialAccountNumber = String.valueOf(inputMap.get('financialAccountNumber'));
            String financialAccountType = String.valueOf(inputMap.get('financialAccountType'));
            String financialAccountId = String.valueOf(inputMap.get('financialAccountId'));
            String financialAccountName = String.valueOf(inputMap.get('financialAccountName'));
            String addressType = String.valueOf(inputMap.get('addressType'));
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
            if (String.isNotBlank(noofCheck) == true) {
                ConnectApi.GenericObject noofCheckObj = new ConnectApi.GenericObject();
                noofCheckObj.value = noofCheck;
                input.attributes.put('check_leaves', noofCheckObj);
            }
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
            if (String.isNotBlank(financialAccountNumber) == true) {
                ConnectApi.GenericObject financialAccountNumberObj = new ConnectApi.GenericObject();
                financialAccountNumberObj.value = financialAccountNumber;
                input.attributes.put('account_number', financialAccountNumberObj);
            }
            if (String.isNotBlank(financialAccountName) == true) {
                ConnectApi.GenericObject financialAccountNameObj = new ConnectApi.GenericObject();
                financialAccountNameObj.value = financialAccountName;
                input.attributes.put('account_name', financialAccountNameObj);
            }
            if (String.isNotBlank(financialAccountType) == true) {
                ConnectApi.GenericObject financialAccountTypeObj = new ConnectApi.GenericObject();
                financialAccountTypeObj.value = financialAccountType;
                input.attributes.put('account_type', financialAccountTypeObj);
            }
            if (String.isNotBlank(addressType) == true) {
                ConnectApi.GenericObject addressTypeObj = new ConnectApi.GenericObject();
                addressTypeObj.value = addressType;
                input.attributes.put('address_type', addressTypeObj);
            }
            if (String.isNotBlank(financialAccountId) == true) {
                ConnectApi.GenericObject financialAccountIdObj = new ConnectApi.GenericObject();
                financialAccountIdObj.value = financialAccountId;
                input.attributes.put('account_id', financialAccountIdObj);
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
        return null;
    }
}