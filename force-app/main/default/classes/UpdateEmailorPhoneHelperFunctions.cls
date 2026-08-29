/*************************
* @Class Name:- UpdateEmailorPhoneHelperFunctions
* @Description:- Helper class for Update Email or Phone FSC service
**************************/
global with sharing class UpdateEmailorPhoneHelperFunctions implements System.Callable {
    
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = (Map<String, Object>)args.get('input');
        Map<String, Object> outputMap = (Map<String, Object>)args.get('output');
        
        if (action == 'callCreateCaseApi') {
            //retrieve the attributes from the request payload
            String accountId = String.valueOf(inputMap.get('accountId'));
            String svcCatalogItemDefApiName = String.valueOf(inputMap.get('svcCatalogItemDefApiName'));
            String caseSubject = String.valueOf(inputMap.get('caseSubject'));
            String currentEmail = String.valueOf(inputMap.get('currentEmail'));
            String newEmail = String.valueOf(inputMap.get('newEmail'));
            String currentPhoneNumber = String.valueOf(inputMap.get('currentPhoneNumber'));
            String newPhoneNumber = String.valueOf(inputMap.get('newPhoneNumber'));
            String currentMobileNumber = String.valueOf(inputMap.get('currentMobileNumber'));
            String newMobileNumber = String.valueOf(inputMap.get('newMobileNumber'));
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
            if (String.isNotBlank(currentMobileNumber) == true) {
                ConnectApi.GenericObject currentMobileNumberObj = new ConnectApi.GenericObject();
                currentMobileNumberObj.value = currentMobileNumber;
                input.attributes.put('current_mobile_number', currentMobileNumberObj);
            }
            if (String.isNotBlank(currentEmail) == true) {
                ConnectApi.GenericObject currentEmailObj = new ConnectApi.GenericObject();
                currentEmailObj.value = currentEmail;
                input.attributes.put('current_email', currentEmailObj);
            }
            if (String.isNotBlank(currentPhoneNumber) == true) {
                ConnectApi.GenericObject currentPhoneNumberObj = new ConnectApi.GenericObject();
                currentPhoneNumberObj.value = currentPhoneNumber;
                input.attributes.put('current_phone_number', currentPhoneNumberObj);
            }
            if (String.isNotBlank(newEmail) == true) {
                ConnectApi.GenericObject newEmailObj = new ConnectApi.GenericObject();
                newEmailObj.value = newEmail;
                input.attributes.put('new_email', newEmailObj);
            }
            if (String.isNotBlank(newPhoneNumber) == true) {
                ConnectApi.GenericObject newPhoneNumberObj = new ConnectApi.GenericObject();
                newPhoneNumberObj.value = newPhoneNumber;
                input.attributes.put('new_phone_number', newPhoneNumberObj);
            }
            if (String.isNotBlank(newMobileNumber) == true) {
                ConnectApi.GenericObject newMobileNumberObj = new ConnectApi.GenericObject();
                newMobileNumberObj.value = newMobileNumber;
                input.attributes.put('new_mobile_number', newMobileNumberObj);
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