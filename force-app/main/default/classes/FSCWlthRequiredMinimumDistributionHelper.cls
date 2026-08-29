/*************************
* @Class Name:- FSCWlthRequiredMinimumDistributionHelper
* @Description:- Helper class for Setup Required Minimum Distribution FSC Wealth service process
**************************/
global with sharing class FSCWlthRequiredMinimumDistributionHelper implements System.Callable {
    
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = (Map<String, Object>)args.get('input');
        Map<String, Object> outputMap = (Map<String, Object>)args.get('output');
        
        if (action == 'callCreateCaseApi') {
            //retrieve the attributes from the request payload
            String accountId = String.valueOf(inputMap.get('accountId'));
            String svcCatalogItemDefApiName = String.valueOf(inputMap.get('svcCatalogItemDefApiName'));
            String caseSubject = String.valueOf(inputMap.get('caseSubject'));
            String financialAccName = String.valueOf(inputMap.get('financialAccName'));
            String financialAccId = String.valueOf(inputMap.get('financialAccId'));
            String financialAccNumber = String.valueOf(inputMap.get('financialAccNumber'));
            String paymentSchedule = String.valueOf(inputMap.get('paymentSchedule')); 
            String automatedRMDOption = String.valueOf(inputMap.get('automatedRMDOption'));
            String automatedRMDDate = String.valueOf(inputMap.get('automatedRMDDate'));
            String taxYear = String.valueOf(inputMap.get('taxYear'));
            String amountOption = String.valueOf(inputMap.get('amountOption'));
            String currencyCode = String.valueOf(inputMap.get('currencyCode'));
            String amount = String.valueOf(inputMap.get('amount'));
            String paymentOption = String.valueOf(inputMap.get('paymentOption'));
            String bankAccountNumber = String.valueOf(inputMap.get('bankAccountNumber'));
            String bankRoutingNumber = String.valueOf(inputMap.get('bankRoutingNumber'));
            String bankAccHolderName = String.valueOf(inputMap.get('bankAccHolderName'));
            String bankAccountType = String.valueOf(inputMap.get('bankAccountType'));
            String bankName = String.valueOf(inputMap.get('bankName'));
            String bankAddress = String.valueOf(inputMap.get('bankAddress'));
            String bankCity = String.valueOf(inputMap.get('bankCity'));
            String bankState = String.valueOf(inputMap.get('bankState'));
            String bankCountry = String.valueOf(inputMap.get('bankCountry'));
            String bankZipcode = String.valueOf(inputMap.get('bankZipcode'));
            String payeeName = String.valueOf(inputMap.get('payeeName'));
            String taxWithholdOption = String.valueOf(inputMap.get('taxWithholdOption'));
            String fedral = String.valueOf(inputMap.get('fedral'));
            String state = String.valueOf(inputMap.get('state'));
            String ownersState = String.valueOf(inputMap.get('ownersState'));
           
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
            if (String.isNotBlank(financialAccName) == true) {
                ConnectApi.GenericObject financialAccNameObj = new ConnectApi.GenericObject();
                financialAccNameObj.value = financialAccName;
                input.attributes.put('financial_account_name', financialAccNameObj);
            }
            if (String.isNotBlank(financialAccNumber) == true) {
                ConnectApi.GenericObject financialAccNumberObj = new ConnectApi.GenericObject();
                financialAccNumberObj.value = financialAccNumber;
                input.attributes.put('financial_account_number', financialAccNumberObj);
            }
            if (String.isNotBlank(financialAccId) == true) {
                ConnectApi.GenericObject financialAccIdObj = new ConnectApi.GenericObject();
                financialAccIdObj.value = financialAccId;
                input.attributes.put('financial_account_id', financialAccIdObj);
            }
            if (String.isNotBlank(paymentSchedule) == true) {
                ConnectApi.GenericObject paymentScheduleObj = new ConnectApi.GenericObject();
                paymentScheduleObj.value = paymentSchedule;
                input.attributes.put('payment_schedule', paymentScheduleObj);
            }
            if (paymentSchedule == 'Automated RMD') {
                if (String.isNotBlank(automatedRMDOption) == true) {
                    ConnectApi.GenericObject automatedRMDOptionObj = new ConnectApi.GenericObject();
                    automatedRMDOptionObj.value = automatedRMDOption;
                    input.attributes.put('automated_rmd_option', automatedRMDOptionObj);
                }
                if (String.isNotBlank(automatedRMDDate) == true) {
                    ConnectApi.GenericObject automatedRMDDateObj = new ConnectApi.GenericObject();
                    automatedRMDDateObj.value = automatedRMDDate;
                    input.attributes.put('automated_rmd_date', automatedRMDDateObj);
                }
            }
            if (String.isNotBlank(taxYear) == true) {
                ConnectApi.GenericObject taxYearObj = new ConnectApi.GenericObject();
                taxYearObj.value = taxYear;
                input.attributes.put('tax_year', taxYearObj);
            }  
            if (String.isNotBlank(amountOption) == true) {
                ConnectApi.GenericObject amountOptionObj = new ConnectApi.GenericObject();
                if (amountOption == 'Calculate RMD amount'){
                    amountOptionObj.value = 'To be calculated';
                    input.attributes.put('amount_option', amountOptionObj);
                } else {
                    amountOptionObj.value = amountOption;
                    input.attributes.put('amount_option', amountOptionObj);
                }
            }
            if (amountOption == 'Enter withdrawal amount'){
                if (String.isNotBlank(currencyCode) == true) {
                    ConnectApi.GenericObject currencyCodeObj = new ConnectApi.GenericObject();
                    currencyCodeObj.value = currencyCode;
                    input.attributes.put('currency_code', currencyCodeObj);
                }
                if (String.isNotBlank(amount) == true) {
                    ConnectApi.GenericObject amountObj = new ConnectApi.GenericObject();
                    amountObj.value = Double.valueOf(amount);
                    input.attributes.put('amount', amountObj);
                }
            }
            if (String.isNotBlank(paymentOption) == true) {
                ConnectApi.GenericObject paymentOptionObj = new ConnectApi.GenericObject();
                paymentOptionObj.value = paymentOption;
                input.attributes.put('payment_option', paymentOptionObj);
            }
            if (String.isNotBlank(bankAccountNumber) == true) {
                ConnectApi.GenericObject bankAccountNumberObj = new ConnectApi.GenericObject();
                bankAccountNumberObj.value = bankAccountNumber;
                input.attributes.put('bank_account_number', bankAccountNumberObj);
            }
            if (String.isNotBlank(bankRoutingNumber) == true) {
                ConnectApi.GenericObject bankRoutingNumberObj = new ConnectApi.GenericObject();
                bankRoutingNumberObj.value = bankRoutingNumber;
                input.attributes.put('bank_routing_number', bankRoutingNumberObj);
            }
            if (String.isNotBlank(bankAccHolderName) == true) {
                ConnectApi.GenericObject bankAccHolderNameObj = new ConnectApi.GenericObject();
                bankAccHolderNameObj.value = bankAccHolderName;
                input.attributes.put('bank_account_holder_name', bankAccHolderNameObj);
            }
            if (String.isNotBlank(bankAccountType) == true) {
                ConnectApi.GenericObject bankAccountTypeObj = new ConnectApi.GenericObject();
                bankAccountTypeObj.value = bankAccountType;
                input.attributes.put('bank_account_type', bankAccountTypeObj);
            }
            if (String.isNotBlank(bankName) == true) {
                ConnectApi.GenericObject bankNameObj = new ConnectApi.GenericObject();
                bankNameObj.value = bankName;
                input.attributes.put('bank_name', bankNameObj);
            }
            if (String.isNotBlank(payeeName) == true && paymentOption == 'Check') {
                ConnectApi.GenericObject transFirmAddressObj = new ConnectApi.GenericObject();
                transFirmAddressObj.value = payeeName;
                input.attributes.put('payee_name', transFirmAddressObj);
            }
            if (paymentOption == 'New EFT Account' || paymentOption == 'Check') {
                if (String.isNotBlank(bankAddress) == true) {
                    ConnectApi.GenericObject transFirmAddressObj = new ConnectApi.GenericObject();
                    transFirmAddressObj.value = bankAddress;
                    input.attributes.put('bank_address', transFirmAddressObj);
                }
                if (String.isNotBlank(bankCity) == true) {
                    ConnectApi.GenericObject transFirmCityObj = new ConnectApi.GenericObject();
                    transFirmCityObj.value = bankCity;
                    input.attributes.put('bank_city', transFirmCityObj);
                }
                if (String.isNotBlank(bankState) == true) {
                    ConnectApi.GenericObject transFirmStateObj = new ConnectApi.GenericObject();
                    transFirmStateObj.value = bankState;
                    input.attributes.put('bank_state', transFirmStateObj);
                }
                if (String.isNotBlank(bankCountry) == true) {
                    ConnectApi.GenericObject transFirmCountryObj = new ConnectApi.GenericObject();
                    transFirmCountryObj.value = bankCountry;
                    input.attributes.put('bank_country', transFirmCountryObj);
                }
                if (String.isNotBlank(bankZipcode) == true ) {
                    ConnectApi.GenericObject transFirmZipCodeObj = new ConnectApi.GenericObject();
                    transFirmZipCodeObj.value = bankZipcode;
                    input.attributes.put('bank_zipcode', transFirmZipCodeObj);
                }
            }
            if (String.isNotBlank(taxWithholdOption) == true) {
                ConnectApi.GenericObject taxWithholdOptionObj = new ConnectApi.GenericObject();
                taxWithholdOptionObj.value = taxWithholdOption;
                input.attributes.put('tax_withholding_option', taxWithholdOptionObj);
            }
            if (taxWithholdOption == 'Elect to have federal and state') {
                if (String.isNotBlank(fedral) == true) {
                    ConnectApi.GenericObject fedralObj = new ConnectApi.GenericObject();
                    fedralObj.value = Double.valueOf(fedral);
                    input.attributes.put('federal_percentage', fedralObj);
                } 
                if (String.isNotBlank(state) == true) {
                    ConnectApi.GenericObject stateObj = new ConnectApi.GenericObject();
                    stateObj.value = Double.valueOf(state);
                    input.attributes.put('state_percentage', stateObj);
                } 
                if (String.isNotBlank(ownersState) == true) {
                    ConnectApi.GenericObject ownersStateObj = new ConnectApi.GenericObject();
                    ownersStateObj.value = ownersState;
                    input.attributes.put('owners_state_of_residence', ownersStateObj);
                }
            }
            if (paymentOption == 'New EFT Account') {
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