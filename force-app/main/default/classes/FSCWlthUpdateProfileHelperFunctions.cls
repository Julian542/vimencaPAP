/*************************
* @Class Name:- FSCWlthUpdateProfileHelperFunctions
* @Description:- Helper class for Update Profile FSC Wealth service process
**************************/
global with sharing class FSCWlthUpdateProfileHelperFunctions implements System.Callable {
    
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = (Map<String, Object>)args.get('input');
        Map<String, Object> outputMap = (Map<String, Object>)args.get('output');
        
        if (action == 'callCreateCaseApi') {
            //retrieve the attributes from the request payload
            String accountId = String.valueOf(inputMap.get('accountId'));
            String svcCatalogItemDefApiName = String.valueOf(inputMap.get('svcCatalogItemDefApiName'));
            String caseSubject = String.valueOf(inputMap.get('caseSubject'));
            String selectedEmail = String.valueOf(inputMap.get('selectedEmail'));
            String selectedName = String.valueOf(inputMap.get('selectedName'));
            String selectedPhone = String.valueOf(inputMap.get('selectedPhone'));
            String selectedMobile = String.valueOf(inputMap.get('selectedMobile'));
            String selectedAddress = String.valueOf(inputMap.get('selectedAddress'));
            String selectedMaritalStatus = String.valueOf(inputMap.get('selectedMaritalStatus'));
            String selectedEmployerName = String.valueOf(inputMap.get('selectedEmployerName'));
            String selectedOccupation = String.valueOf(inputMap.get('selectedOccupation'));
            String currentEmail = String.valueOf(inputMap.get('currentEmail'));
            String newEmail = String.valueOf(inputMap.get('newEmail'));
            String currentPhoneNumber = String.valueOf(inputMap.get('currentPhoneNumber'));
            String newPhoneNumber = String.valueOf(inputMap.get('newPhoneNumber'));
            String currentMobileNumber = String.valueOf(inputMap.get('currentMobileNumber'));
            String newMobileNumber = String.valueOf(inputMap.get('newMobileNumber'));
            String currentMaritalStatus = String.valueOf(inputMap.get('currentMaritalStatus'));
            String newMaritalStatus = String.valueOf(inputMap.get('newMaritalStatus'));
            String currentEmployerName = String.valueOf(inputMap.get('currentEmployerName'));
            String newEmployerName = String.valueOf(inputMap.get('newEmployerName'));
            String currentOccupation = String.valueOf(inputMap.get('currentOccupation'));
            String newOccupation = String.valueOf(inputMap.get('newOccupation'));
            String currentFirstName = String.valueOf(inputMap.get('currentFirstName'));
            String currentLastName = String.valueOf(inputMap.get('currentLastName'));
            String newFirstName = String.valueOf(inputMap.get('newFirstName'));
            String newLastName = String.valueOf(inputMap.get('newLastName'));
            String addressLine1 = String.valueOf(inputMap.get('addressLine1'));
            String addressLine2 = String.valueOf(inputMap.get('addressLine2'));
            String city = String.valueOf(inputMap.get('city'));
            String state = String.valueOf(inputMap.get('state'));
            String country = String.valueOf(inputMap.get('country'));
            String zipCode = String.valueOf(inputMap.get('zipCode'));
            String updateCustomerAccount = String.valueOf(inputMap.get('updateCustomerAccount'));
            String updateFinancialAccount = String.valueOf(inputMap.get('updateFinancialAccount'));
            // Set the input rep
            ConnectApi.ServiceProcessRequestInputRepresentation input = new ConnectApi.ServiceProcessRequestInputRepresentation();
            input.svcCatalogItemDefApiName = svcCatalogItemDefApiName;
            input.caseInfo = new Map<String, ConnectApi.GenericObject>();
            input.attributes = new Map<String, ConnectApi.GenericObject>();
            input.documentInfo = new List<ConnectApi.DocumentInfoAttributes>();
            
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
            if (String.isNotBlank(currentMobileNumber) == true && selectedMobile == 'true') {
                ConnectApi.GenericObject currentMobileNumberObj = new ConnectApi.GenericObject();
                currentMobileNumberObj.value = currentMobileNumber;
                input.attributes.put('current_mobile_number', currentMobileNumberObj);
            }
            if (String.isNotBlank(currentEmail) == true && selectedEmail == 'true') {
                ConnectApi.GenericObject currentEmailObj = new ConnectApi.GenericObject();
                currentEmailObj.value = currentEmail;
                input.attributes.put('current_email', currentEmailObj);
            }
            if (String.isNotBlank(currentPhoneNumber) == true && selectedPhone == 'true') {
                ConnectApi.GenericObject currentPhoneNumberObj = new ConnectApi.GenericObject();
                currentPhoneNumberObj.value = currentPhoneNumber;
                input.attributes.put('current_phone_number', currentPhoneNumberObj);
            }
            if (String.isNotBlank(currentFirstName) == true && selectedName == 'true') {
                ConnectApi.GenericObject currentfirstNameObj = new ConnectApi.GenericObject();
                currentfirstNameObj.value = currentFirstName;
                input.attributes.put('current_first_name', currentfirstNameObj);
            }
            if (String.isNotBlank(currentLastName) == true && selectedName == 'true') {
                ConnectApi.GenericObject currentLastNameObj = new ConnectApi.GenericObject();
                currentLastNameObj.value = currentLastName;
                input.attributes.put('current_last_name', currentLastNameObj);
            }
            if (String.isNotBlank(currentMaritalStatus) == true && selectedMaritalStatus == 'true') {
                ConnectApi.GenericObject currentMaritalStatusObj = new ConnectApi.GenericObject();
                currentMaritalStatusObj.value = currentMaritalStatus;
                input.attributes.put('current_marital_status', currentMaritalStatusObj);
            }
            if (String.isNotBlank(currentEmployerName) == true && selectedEmployerName == 'true') {
                ConnectApi.GenericObject currentEmployerNameObj = new ConnectApi.GenericObject();
                currentEmployerNameObj.value = currentEmployerName;
                input.attributes.put('current_company', currentEmployerNameObj);
            }
            if (String.isNotBlank(currentOccupation) == true && selectedOccupation == 'true') {
                ConnectApi.GenericObject currentOccupationObj = new ConnectApi.GenericObject();
                currentOccupationObj.value = currentOccupation;
                input.attributes.put('current_occupation', currentOccupationObj);
            }
            if (String.isNotBlank(newEmail) == true && selectedEmail == 'true') {
                ConnectApi.GenericObject newEmailObj = new ConnectApi.GenericObject();
                newEmailObj.value = newEmail;
                input.attributes.put('new_email', newEmailObj);
            }
            if (String.isNotBlank(newPhoneNumber) == true && selectedPhone == 'true') {
                ConnectApi.GenericObject newPhoneNumberObj = new ConnectApi.GenericObject();
                newPhoneNumberObj.value = newPhoneNumber;
                input.attributes.put('new_phone_number', newPhoneNumberObj);
            }
            if (String.isNotBlank(newMobileNumber) == true && selectedMobile == 'true') {
                ConnectApi.GenericObject newMobileNumberObj = new ConnectApi.GenericObject();
                newMobileNumberObj.value = newMobileNumber;
                input.attributes.put('new_mobile_number', newMobileNumberObj);
            }
            if (selectedName == 'true') {
                if (String.isNotBlank(newFirstName) == true) {
                    ConnectApi.GenericObject newFirstNameObj = new ConnectApi.GenericObject();
                    newFirstNameObj.value = newFirstName;
                    input.attributes.put('new_first_name', newFirstNameObj);
                }
                if (String.isNotBlank(newLastName) == true) {
                    ConnectApi.GenericObject newLastNameObj = new ConnectApi.GenericObject();
                    newLastNameObj.value = newLastName;
                    input.attributes.put('new_last_name', newLastNameObj);
                }
                // retrieve the documentInfo by the customer
                List<Object> uploadedDocumentInfoList = (List<Object>)inputMap.get('documentInfo');
                Set<ConnectApi.DocumentInfoAttributes> docInfoSet = new Set<ConnectApi.DocumentInfoAttributes>();
                if (uploadedDocumentInfoList != null && !uploadedDocumentInfoList.isEmpty()) {
                    for (Object uploadedDocInfoMap : uploadedDocumentInfoList) {
                        ConnectApi.DocumentInfoAttributes doc = new ConnectApi.DocumentInfoAttributes();
                        Map<String, Object> uploadMap = (Map<String, Object>)uploadedDocInfoMap;
                        doc.id = (String) uploadMap.get('id');
                        doc.name = (String) uploadMap.get('name');
                        doc.typeId = (String) uploadMap.get('typeId');
                        docInfoSet.add(doc);
                    }
                }
                for (ConnectApi.DocumentInfoAttributes docInfoAttr : docInfoSet) {
                    input.documentInfo.add(docInfoAttr);
                }
            }
            if (String.isNotBlank(newMaritalStatus) == true && selectedMaritalStatus == 'true') {
                ConnectApi.GenericObject newMaritalStatusObj = new ConnectApi.GenericObject();
                newMaritalStatusObj.value = newMaritalStatus;
                input.attributes.put('new_marital_status', newMaritalStatusObj);
            }
            if (String.isNotBlank(newEmployerName) == true && selectedEmployerName == 'true') {
                ConnectApi.GenericObject newEmployerNameObj = new ConnectApi.GenericObject();
                newEmployerNameObj.value = newEmployerName;
                input.attributes.put('new_company', newEmployerNameObj);
            }
            if (String.isNotBlank(newOccupation) == true && selectedOccupation == 'true') {
                ConnectApi.GenericObject newOccupationObj = new ConnectApi.GenericObject();
                newOccupationObj.value = newOccupation;
                input.attributes.put('new_occupation', newOccupationObj);
            }
            if (String.isNotBlank(updateCustomerAccount) == true) {
                    ConnectApi.GenericObject updateCustomerAccountObj = new ConnectApi.GenericObject();
                    updateCustomerAccountObj.value = updateCustomerAccount;
                    input.attributes.put('update_customer_account', updateCustomerAccountObj);
            }
            if (selectedAddress == 'true') {
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
                if (String.isNotBlank(country) == true) {
                    ConnectApi.GenericObject countryObj = new ConnectApi.GenericObject();
                    countryObj.value = country;
                    input.attributes.put('country', countryObj);
                }
                if (String.isNotBlank(zipCode) == true) {
                    ConnectApi.GenericObject zipCodeObj = new ConnectApi.GenericObject();
                    zipCodeObj.value = zipCode;
                    input.attributes.put('zip_code', zipCodeObj);
                }
                if (String.isNotBlank(updateFinancialAccount) == true) {
                    ConnectApi.GenericObject updateFinancialAccountObj = new ConnectApi.GenericObject();
                    updateFinancialAccountObj.value = updateFinancialAccount;
                    input.attributes.put('update_financial_account', updateFinancialAccountObj);
                }
                // Set Attributes for Adding selected Accounts and addresses  
                Object addressesToAddListObj = inputMap.get('selectedAddresses');
                String accountsToAddListStr;
                if (addressesToAddListObj instanceof List<Object>) {
                    accountsToAddListStr = JSON.serialize(addressesToAddListObj);
                } else {
                    accountsToAddListStr = '['+ JSON.serialize(addressesToAddListObj) +']';
                }
                ConnectApi.GenericObject accountsToAddList = new ConnectApi.GenericObject();
                List<Object> untypedListAddAccounts = (List<Object>) JSON.deserializeUntyped(accountsToAddListStr);
                List<Map<String, Object>> accountsToAddDetails = new List<Map<String, Object>>();
                Map<String, Object> accountsToAdd;
                for (Object jsonObj :untypedListAddAccounts) {
                    Map<String, Object> accountsToAddJsonObj = (Map<String, Object>)jsonObj;
                    accountsToAdd = new Map<String, Object>();
                    if (String.isNotBlank(String.valueOf(accountsToAddJsonObj.get('Type'))) == true) {
                        accountsToAdd.put('account_type', String.valueOf(accountsToAddJsonObj.get('Type')));
                    }
                    if (String.isNotBlank(String.valueOf(accountsToAddJsonObj.get('AccountNumberLast4'))) == true) {
                        accountsToAdd.put('account_number', 'XXXX-'+String.valueOf(accountsToAddJsonObj.get('AccountNumberLast4')));
                    } 
                    accountsToAdd.put('addresses_to_update', String.valueOf(accountsToAddJsonObj.get('Address')));
                    accountsToAddDetails.add(accountsToAdd);   
                }
                if (!accountsToAddDetails.isEmpty()) {
                    accountsToAddList.value = accountsToAddDetails;
                    input.attributes.put('accounts', accountsToAddList);
                }
            }
            
            // Invoke API
            Map<String, String> responseMap = new Map<String, String>();
            if(!Test.isRunningTest()) {
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