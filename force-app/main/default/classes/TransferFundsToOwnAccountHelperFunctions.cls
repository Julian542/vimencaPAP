/*************************
* @Class Name:- TransferFundsToOwnAccountHelperFunctions
* @Description:- Helper class for TransferFundsToOwnAccount FSC service 
**************************/
global with sharing class TransferFundsToOwnAccountHelperFunctions implements System.Callable {
    
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = (Map<String, Object>)args.get('input');
        Map<String, Object> outputMap = (Map<String, Object>)args.get('output');
        
        if (action == 'callCreateCaseApi') {
            //retrieve the attributes from the request payload
            String accountId = String.valueOf(inputMap.get('accountId'));
            String svcCatalogItemDefApiName = String.valueOf(inputMap.get('svcCatalogItemDefApiName'));
            String caseSubject = String.valueOf(inputMap.get('caseSubject'));
            String transferFromAccountName = String.valueOf(inputMap.get('transferFromAccountName'));
            String transferFromAccountNumber = String.valueOf(inputMap.get('transferFromAccountNumber'));
            String transferToAccountName = String.valueOf(inputMap.get('transferToAccountName'));
            String transferFromAccountType = String.valueOf(inputMap.get('transferFromAccountType'));
            String transferToAccountType = String.valueOf(inputMap.get('transferToAccountType'));
            String transferToAccountNumber = String.valueOf(inputMap.get('transferToAccountNumber'));
            String transferFromAccountId = String.valueOf(inputMap.get('transferFromAccountId'));
            String transferToAccountId = String.valueOf(inputMap.get('transferToAccountId'));
            String currencyCode = String.valueOf(inputMap.get('currencyCode'));
            String frequency = String.valueOf(inputMap.get('frequency'));
            String remarks = String.valueOf(inputMap.get('remarks'));
            String paymentType = String.valueOf(inputMap.get('paymentType'));
            String amount = String.valueOf(inputMap.get('amount'));
            String instalment = String.valueOf(inputMap.get('instalment'));
            String startDate = String.valueOf(inputMap.get('startDate'));
            String endDate = String.valueOf(inputMap.get('endDate'));
            String transferDate = String.valueOf(inputMap.get('transferDate'));
            String recurringPaymentOption = String.valueOf(inputMap.get('recurringPaymentOption'));
            
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
            
            if (String.isNotBlank(transferFromAccountName) == true) {
                ConnectApi.GenericObject transferFromAccountNameObj = new ConnectApi.GenericObject();
                transferFromAccountNameObj.value = transferFromAccountName;
                input.attributes.put('source_account_name', transferFromAccountNameObj);
            }
            if (String.isNotBlank(transferFromAccountNumber) == true) {
                ConnectApi.GenericObject transferFromAccountNumberObj = new ConnectApi.GenericObject();
                transferFromAccountNumberObj.value = transferFromAccountNumber;
                input.attributes.put('source_account_number', transferFromAccountNumberObj);
            }
            if (String.isNotBlank(transferFromAccountType) == true) {
                ConnectApi.GenericObject transferFromAccountTypeObj = new ConnectApi.GenericObject();
                transferFromAccountTypeObj.value = transferFromAccountType;
                input.attributes.put('source_account_type', transferFromAccountTypeObj);
            }
            if (String.isNotBlank(transferFromAccountId) == true) {
                ConnectApi.GenericObject transferFromAccountIdObj = new ConnectApi.GenericObject();
                transferFromAccountIdObj.value = transferFromAccountId;
                input.attributes.put('source_account_id', transferFromAccountIdObj);
            }
            if (String.isNotBlank(currencyCode) == true) {
                ConnectApi.GenericObject currencyCodeObj = new ConnectApi.GenericObject();
                currencyCodeObj.value = currencyCode;
                input.attributes.put('currency_code', currencyCodeObj);
            }
            if (String.isNotBlank(transferToAccountName) == true) {
                ConnectApi.GenericObject transferToAccountNameObj = new ConnectApi.GenericObject();
                transferToAccountNameObj.value = transferToAccountName;
                input.attributes.put('destination_account_name', transferToAccountNameObj);
            }
            if (String.isNotBlank(transferToAccountNumber) == true) {
                ConnectApi.GenericObject transferToAccountNumberObj = new ConnectApi.GenericObject();
                transferToAccountNumberObj.value = transferToAccountNumber;
                input.attributes.put('destination_account_number', transferToAccountNumberObj);
            }
            if (String.isNotBlank(transferToAccountType) == true) {
                ConnectApi.GenericObject transferToAccountTypeObj = new ConnectApi.GenericObject();
                transferToAccountTypeObj.value = transferToAccountType;
                input.attributes.put('destination_account_type', transferToAccountTypeObj);
            }
            if (String.isNotBlank(transferToAccountId) == true) {
                ConnectApi.GenericObject transferToAccountIdObj = new ConnectApi.GenericObject();
                transferToAccountIdObj.value = transferToAccountId;
                input.attributes.put('destination_account_id', transferToAccountIdObj);
            }
            if (String.isNotBlank(remarks) == true) {
                ConnectApi.GenericObject remarksObj = new ConnectApi.GenericObject();
                remarksObj.value = remarks;
                input.attributes.put('remarks', remarksObj);
            }
            if (String.isNotBlank(paymentType) == true) {
                ConnectApi.GenericObject paymentTypeObj = new ConnectApi.GenericObject();
                paymentTypeObj.value = paymentType;
                input.attributes.put('payment_type', paymentTypeObj);
            }
            if (paymentType == 'Recurring') {
                if (String.isNotBlank(startDate) == true) {
                    ConnectApi.GenericObject startDateObj = new ConnectApi.GenericObject();
                    startDateObj.value = startDate;
                    input.attributes.put('start_date', startDateObj);
                }
                if (String.isNotBlank(endDate) == true) {
                    ConnectApi.GenericObject endDateObj = new ConnectApi.GenericObject();
                    endDateObj.value = endDate;
                    input.attributes.put('end_date', endDateObj);
                }
                if (String.isNotBlank(frequency) == true) {
                    ConnectApi.GenericObject frequencyObj = new ConnectApi.GenericObject();
                    frequencyObj.value = frequency;
                    input.attributes.put('frequency', frequencyObj);
                }
                if (String.isNotBlank(instalment) == true) {
                    ConnectApi.GenericObject instalmentObj = new ConnectApi.GenericObject();
                    instalmentObj.value = Integer.valueOf(instalment);
                    input.attributes.put('installment', instalmentObj);
                }
            }
            if (String.isNotBlank(transferDate) == true) {
                ConnectApi.GenericObject transferDateObj = new ConnectApi.GenericObject();
                transferDateObj.value = transferDate;
                input.attributes.put('transfer_date', transferDateObj);
            }
            if (String.isNotBlank(amount) == true) {
                ConnectApi.GenericObject amountObj = new ConnectApi.GenericObject();
                amountObj.value = Double.valueOf(amount.split(' ')[1]);
                input.attributes.put('amount', amountObj);
            } 
            if (String.isNotBlank(recurringPaymentOption) == true) {
                ConnectApi.GenericObject recurringPaymentOptionObj = new ConnectApi.GenericObject();
                recurringPaymentOptionObj.value = recurringPaymentOption;
                input.attributes.put('recurring_transfer_option', recurringPaymentOptionObj);
            }
            
            // Invoke API
            Map<String, String> responseMap = new Map<String, String>();
            if (!Test.isRunningTest()) {
                ConnectApi.ServiceProcessRepresentation output = ConnectApi.IServiceProcessConnectFamily.createCaseServiceProcess(input);
                responseMap.put('caseId', output.caseId);
                responseMap.put('caseNumber', output.caseNumber);
                responseMap.put('svcCatalogRequestId', output.svcCatalogRequestId);
                outputMap.put('apiResponse', responseMap);
            }
            return outputMap;
        }
        return null;
    }
}