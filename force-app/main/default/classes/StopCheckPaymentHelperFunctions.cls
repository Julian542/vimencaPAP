/*************************
* @Class Name:- StopCheckPaymentHelperFunctions
* @Description:- Helper class for Stop Check Payment FSC service 
**************************/
global with sharing class StopCheckPaymentHelperFunctions implements System.Callable {
    
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = (Map<String, Object>)args.get('input');
        Map<String, Object> outputMap = (Map<String, Object>)args.get('output');
        
        if (action == 'callCreateCaseApi') {
            //retrieve the attributes from the request payload
            String accountId = String.valueOf(inputMap.get('accountId'));
            String svcCatalogItemDefApiName = String.valueOf(inputMap.get('svcCatalogItemDefApiName'));
            String caseSubject = String.valueOf(inputMap.get('caseSubject'));
            String accountNumber = String.valueOf(inputMap.get('accountNumber'));
            String accountType = String.valueOf(inputMap.get('accountType'));
            String checkType = String.valueOf(inputMap.get('checkType'));
            String reason = String.valueOf(inputMap.get('reason'));
            String checkDate = String.valueOf(inputMap.get('checkDate'));
            String checkNumber = String.valueOf(inputMap.get('checkNumber'));
            String payee = String.valueOf(inputMap.get('payee'));
            String amount = String.valueOf(inputMap.get('amount'));
            String lowestCheckNumber = String.valueOf(inputMap.get('lowestCheckNumber'));
            String highestCheckNumber = String.valueOf(inputMap.get('highestCheckNumber'));
            String financialAccountId = String.valueOf(inputMap.get('financialAccountId'));
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
            if (String.isNotBlank(accountNumber) == true) {
                ConnectApi.GenericObject accountNumberObj = new ConnectApi.GenericObject();
                accountNumberObj.value = accountNumber;
                input.attributes.put('account_number', accountNumberObj);
            }
            if (String.isNotBlank(accountType) == true) {
                ConnectApi.GenericObject accountTypeObj = new ConnectApi.GenericObject();
                accountTypeObj.value = accountType;
                input.attributes.put('account_type', accountTypeObj);
            }
            if (String.isNotBlank(checkType) == true) {
                ConnectApi.GenericObject checkTypeObj = new ConnectApi.GenericObject();
                checkTypeObj.value = checkType;
                input.attributes.put('check_type', checkTypeObj);
            }
            if (String.isNotBlank(reason) == true) {
                ConnectApi.GenericObject reasonObj = new ConnectApi.GenericObject();
                reasonObj.value = reason;
                input.attributes.put('reason', reasonObj);
            }
            if (String.isNotBlank(checkDate) == true) {
                ConnectApi.GenericObject checkDateObj = new ConnectApi.GenericObject();
                checkDateObj.value = checkDate;
                input.attributes.put('check_date', checkDateObj);
            }
            if (String.isNotBlank(checkNumber) == true) {
                ConnectApi.GenericObject checkNumberObj = new ConnectApi.GenericObject();
                checkNumberObj.value = checkNumber;
                input.attributes.put('check_number', checkNumberObj);
            }
            if (String.isNotBlank(amount) == true) {
                ConnectApi.GenericObject amountObj = new ConnectApi.GenericObject();
                amountObj.value = amount;
                input.attributes.put('amount', amountObj);
            }
            if (String.isNotBlank(payee) == true) {
                ConnectApi.GenericObject payeeObj = new ConnectApi.GenericObject();
                payeeObj.value = payee;
                input.attributes.put('payee', payeeObj);
            }
            if (String.isNotBlank(lowestCheckNumber) == true) {
                ConnectApi.GenericObject lowestCheckNumberObj = new ConnectApi.GenericObject();
                lowestCheckNumberObj.value = lowestCheckNumber;
                input.attributes.put('starting_check_number', lowestCheckNumberObj);
            }
            if (String.isNotBlank(highestCheckNumber) == true) {
                ConnectApi.GenericObject highestCheckNumberObj = new ConnectApi.GenericObject();
                highestCheckNumberObj.value = highestCheckNumber;
                input.attributes.put('ending_check_number', highestCheckNumberObj);
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