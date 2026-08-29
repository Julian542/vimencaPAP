/*************************
* @Class Name:- RequestLoanPayoffStatementHelperFunction
* @Description:- Helper class for Request Loan Payoff Statement FSC service
**************************/
global with sharing class RequestLoanPayoffStatementHelperFunction implements System.Callable {
    
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = (Map<String, Object>)args.get('input');
        Map<String, Object> outputMap = (Map<String, Object>)args.get('output');
        
        if (action == 'callCreateCaseApi') {
            //retrieve the attributes from the request payload
            String accountId = (String)inputMap.get('accountId');
            String svcCatalogItemDefApiName = (String)inputMap.get('svcCatalogItemDefApiName');
            String caseSubject = (String)inputMap.get('caseSubject');
            String viaPost = (String)inputMap.get('viaPost');
            String shippingPreference = (String)inputMap.get('shippingPreference');
            String addressLine1 = (String)inputMap.get('addressLine1');
            String addressLine2 = (String)inputMap.get('addressLine2');
            String city = (String)inputMap.get('city');
            String state = (String)inputMap.get('state');
            String postalCode = (String)inputMap.get('postalCode');
            String country = (String)inputMap.get('country');
            String viaEmail = (String)inputMap.get('viaEmail');
            String emailId = (String)inputMap.get('emailId');
            String financialAccountNumber = (String)inputMap.get('financialAccountNumber');
            String financialAccountName = (String)inputMap.get('financialAccountName');
            String payoffDate = (String)inputMap.get('payoffDate');
            String principalBalance = (String)inputMap.get('principalBalance');
            String interestBalance = (String)inputMap.get('interestBalance');
            String penaltyBalance = (String)inputMap.get('penaltyBalance');
            String feeBalance = (String)inputMap.get('feeBalance');
            String totalPayoffAmount = (String)inputMap.get('totalPayoffAmount');
            String accountName = (String)inputMap.get('accountName');
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
            //Set case Status to closed if both via email and via post is unchecked/No
            if (viaEmail == 'No' && viaPost == 'No') {
                ConnectApi.GenericObject caseStatusObj = new ConnectApi.GenericObject(); 
                caseStatusObj.value = 'Closed';
                input.caseInfo.put('Status', caseStatusObj);
            }
            
            // set attributes for case creation and Pdf generation
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
            if (String.isNotBlank(financialAccountId) == true) {
                ConnectApi.GenericObject financialAccountIdObj = new ConnectApi.GenericObject();
                financialAccountIdObj.value = financialAccountId;
                input.attributes.put('account_id', financialAccountIdObj);
            }
            if (String.isNotBlank(payoffDate) == true) {
                ConnectApi.GenericObject payoffDateObj = new ConnectApi.GenericObject();
                payoffDateObj.value = payoffDate;
                input.attributes.put('payoff_date', payoffDateObj);
            }
            if (String.isNotBlank(viaEmail) == true) {
                ConnectApi.GenericObject viaEmailObj = new ConnectApi.GenericObject();
                viaEmailObj.value = viaEmail;
                input.attributes.put('send_statement_via_email', viaEmailObj);
            }
            if (String.isNotBlank(viaPost) == true) {
                ConnectApi.GenericObject viaPostObj = new ConnectApi.GenericObject();
                viaPostObj.value = viaPost;
                input.attributes.put('send_statement_via_post', viaPostObj);
            }
            if (String.isNotBlank(principalBalance) == true) {
                ConnectApi.GenericObject principalBalanceObj = new ConnectApi.GenericObject();
                principalBalanceObj.value = Double.valueOf(principalBalance.split(' ')[1]);
                input.attributes.put('principal', principalBalanceObj);
            }
            if (String.isNotBlank(interestBalance) == true) {
                ConnectApi.GenericObject interestBalanceObj = new ConnectApi.GenericObject();
                interestBalanceObj.value = Double.valueOf(interestBalance.split(' ')[1]);
                input.attributes.put('interest', interestBalanceObj);
            }
            if (String.isNotBlank(feeBalance) == true) {
                ConnectApi.GenericObject feeBalanceObj = new ConnectApi.GenericObject();
                feeBalanceObj.value = Double.valueOf(feeBalance.split(' ')[1]);
                input.attributes.put('fee', feeBalanceObj);
            }
            if (String.isNotBlank(penaltyBalance) == true) {
                ConnectApi.GenericObject penaltyBalanceObj = new ConnectApi.GenericObject();
                penaltyBalanceObj.value = Double.valueOf(penaltyBalance.split(' ')[1]);
                input.attributes.put('penalty', penaltyBalanceObj);
            }
            if (String.isNotBlank(totalPayoffAmount) == true) {
                ConnectApi.GenericObject totalPayoffAmountObj = new ConnectApi.GenericObject();
                totalPayoffAmountObj.value = Double.valueOf(totalPayoffAmount.split(' ')[1]);
                input.attributes.put('total_payoff_amount', totalPayoffAmountObj);
            
                ConnectApi.GenericObject currencyCodeObj = new ConnectApi.GenericObject();
                currencyCodeObj.value = totalPayoffAmount.split(' ')[0];
                input.attributes.put('currency_code', currencyCodeObj);
            }
            //Checking If only required via email
            if (viaEmail == 'Yes') {
                if (String.isNotBlank(emailId) == true) {
                    ConnectApi.GenericObject emailIdObj = new ConnectApi.GenericObject();
                    emailIdObj.value = emailId;
                    input.attributes.put('email', emailIdObj);
                }
            }
            //Checking If only required via post
            if (viaPost == 'Yes') {
                if (String.isNotBlank(shippingPreference) == true) {
                    ConnectApi.GenericObject shippingPreferenceObj = new ConnectApi.GenericObject();
                    shippingPreferenceObj.value = shippingPreference;
                    input.attributes.put('shipping_preference', shippingPreferenceObj);
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
            }
            
            // Invoke API
            Map<String, String> responseMap = new Map<String, String>();
            if (!Test.isRunningTest()) {
                ConnectApi.ServiceProcessRepresentation output = ConnectApi.IServiceProcessConnectFamily.createCaseServiceProcess(input);
                responseMap.put('caseId', output.caseId);
                responseMap.put('caseNumber', output.caseNumber);
                responseMap.put('svcCatalogRequestId', output.svcCatalogRequestId);
            }
            //Return apiResponse which contains caseId, caseNumber and catalogRequsetId
            outputMap.put('apiResponse', responseMap);
            return outputMap;
        }
        return null;
    }
}