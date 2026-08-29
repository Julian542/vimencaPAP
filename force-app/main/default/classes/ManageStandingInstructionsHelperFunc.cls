/*************************
* @Class Name:- ManageStandingInstructionsHelperFunc
* @Description:- Helper class for ManageStandingInstructions FSC service
**************************/
global with sharing class ManageStandingInstructionsHelperFunc implements System.Callable {
    
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = (Map<String, Object>)args.get('input');
        Map<String, Object> outputMap = (Map<String, Object>)args.get('output');
        if (action == 'callCreateCaseApi') {
            //retrieve the attributes from the request payload
            String accountId = String.valueOf(inputMap.get('accountId'));
            String svcCatalogItemDefApiName = String.valueOf(inputMap.get('svcCatalogItemDefApiName'));
            String caseSubject = String.valueOf(inputMap.get('caseSubject'));
            String accountNumber = String.valueOf(inputMap.get('accountNumber'));
            String accountName = String.valueOf(inputMap.get('accountName'));
            String accountType = String.valueOf(inputMap.get('accountType'));
            String standingInstructionType = String.valueOf(inputMap.get('standingInstructionType'));
            String payeeName = String.valueOf(inputMap.get('payeeName'));
            String payeeRoutingNumber = String.valueOf(inputMap.get('payeeRoutingNumber'));
            String payeeAccountNumber = String.valueOf(inputMap.get('payeeAccountNumber'));
            String currencyValue = String.valueOf(inputMap.get('currency'));
            String frequency = String.valueOf(inputMap.get('frequency'));
            String remarks = String.valueOf(inputMap.get('remarks'));
            String amount = String.valueOf(inputMap.get('amount'));
            String noOfInstallment = String.valueOf(inputMap.get('noOfInstallment'));
            String startDate = String.valueOf(inputMap.get('startDate'));
            String endDate = String.valueOf(inputMap.get('endDate'));
            String standingInstructionId = String.valueOf(inputMap.get('standingInstructionId'));
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
            if (String.isNotBlank(accountName) == true) {
                ConnectApi.GenericObject accountNameObj = new ConnectApi.GenericObject();
                accountNameObj.value = accountName;
                input.attributes.put('account_name', accountNameObj);
            }
            if (String.isNotBlank(currencyValue) == true) {
                ConnectApi.GenericObject currencyObj = new ConnectApi.GenericObject();
                currencyObj.value = currencyValue;
                input.attributes.put('currency', currencyObj);
            }
            if (String.isNotBlank(accountType) == true) {
                ConnectApi.GenericObject accountTypeObj = new ConnectApi.GenericObject();
                accountTypeObj.value = accountType;
                input.attributes.put('account_type', accountTypeObj);
            }
            if (String.isNotBlank(financialAccountId) == true) {
                ConnectApi.GenericObject financialAccountIdObj = new ConnectApi.GenericObject();
                financialAccountIdObj.value = financialAccountId;
                input.attributes.put('account_id', financialAccountIdObj);
            }
            if (String.isNotBlank(standingInstructionType) == true) {
                ConnectApi.GenericObject standingInstructionTypeObj = new ConnectApi.GenericObject();
                standingInstructionTypeObj.value = standingInstructionType;
                input.attributes.put('standing_instruction_type', standingInstructionTypeObj);
            }
            if (String.isNotBlank(remarks) == true) {
                ConnectApi.GenericObject remarksObj = new ConnectApi.GenericObject();
                remarksObj.value = remarks;
                input.attributes.put('remarks', remarksObj);
            }
            if (String.isNotBlank(standingInstructionId) == true) {
                ConnectApi.GenericObject standingInstructionIdObj = new ConnectApi.GenericObject();
                standingInstructionIdObj.value = standingInstructionId;
                input.attributes.put('standing_instruction_id', standingInstructionIdObj);
            }
            if(String.isNotBlank(startDate) == true) {
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
            if (String.isNotBlank(noOfInstallment) == true) {
                ConnectApi.GenericObject installmentObj = new ConnectApi.GenericObject();
                installmentObj.value = Integer.valueOf(noOfInstallment);
                input.attributes.put('number_of_installments', installmentObj);
            }
            if (String.isNotBlank(amount) == true) {
                ConnectApi.GenericObject amountObj = new ConnectApi.GenericObject();
                amountObj.value = Double.valueOf(amount);
                input.attributes.put('amount', amountObj);
            }
            if (String.isNotBlank(payeeName) == true) {
                ConnectApi.GenericObject payeeNameObj = new ConnectApi.GenericObject();
                payeeNameObj.value = payeeName;
                input.attributes.put('payee_name', payeeNameObj);
            }
            if (String.isNotBlank(payeeAccountNumber) == true) {
                ConnectApi.GenericObject payeeAccountNumberObj = new ConnectApi.GenericObject();
                payeeAccountNumberObj.value = payeeAccountNumber;
                input.attributes.put('payee_account_number', payeeAccountNumberObj);
            }
            if (String.isNotBlank(payeeRoutingNumber) == true) {
                ConnectApi.GenericObject payeeRoutingNumberObj = new ConnectApi.GenericObject();
                payeeRoutingNumberObj.value = payeeRoutingNumber;
                input.attributes.put('payee_routing_number', payeeRoutingNumberObj);
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