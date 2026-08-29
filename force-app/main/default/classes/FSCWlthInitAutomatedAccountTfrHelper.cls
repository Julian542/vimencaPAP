/*************************
* @Class Name:- FSCWlthInitAutomatedAccountTfrHelper
* @Description:- Helper class for Automated Customer Account Transfer FSC Wealth service process
**************************/
global with sharing class FSCWlthInitAutomatedAccountTfrHelper implements System.Callable {
    
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
            String transferAction = String.valueOf(inputMap.get('transferAction')); 
            String extnAccountNumber = String.valueOf(inputMap.get('extnAccountNumber'));
            String extnAccountType = String.valueOf(inputMap.get('extnAccountType'));
            String extnAccountOwner = String.valueOf(inputMap.get('extnAccountOwner'));
            String transFirmName = String.valueOf(inputMap.get('transFirmName'));
            String transFirmAddress = String.valueOf(inputMap.get('transFirmAddress'));
            String transFirmCity = String.valueOf(inputMap.get('transFirmCity'));
            String transFirmState = String.valueOf(inputMap.get('transFirmState'));
            String transFirmCountry = String.valueOf(inputMap.get('transFirmCountry'));
            String transFirmZipCode = String.valueOf(inputMap.get('transFirmZipCode'));
            String transFirmPhone = String.valueOf(inputMap.get('transFirmPhone'));
            String transferType = String.valueOf(inputMap.get('transferType'));
            String transferEntireAccount = String.valueOf(inputMap.get('transferEntireAccount'));
            String maturityAnnuityDate = String.valueOf(inputMap.get('maturityAnnuityDate'));
            String mode = String.valueOf(inputMap.get('mode'));
            String cash = String.valueOf(inputMap.get('cash'));
            String security = String.valueOf(inputMap.get('security'));
            String amountMode = String.valueOf(inputMap.get('amountMode'));
            String currencyCode = String.valueOf(inputMap.get('currencyCode'));
            String amount = String.valueOf(inputMap.get('amount'));
            String numOfShares = String.valueOf(inputMap.get('numOfShares'));
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
            if (String.isNotBlank(transferAction) == true) {
                ConnectApi.GenericObject transferActionObj = new ConnectApi.GenericObject();
                transferActionObj.value = transferAction;
                input.attributes.put('transfer_action', transferActionObj);
            }
            if (String.isNotBlank(extnAccountNumber) == true) {
                ConnectApi.GenericObject extnAccountNumberObj = new ConnectApi.GenericObject();
                extnAccountNumberObj.value = extnAccountNumber;
                input.attributes.put('external_account_number', extnAccountNumberObj);
            }
            if (String.isNotBlank(extnAccountType) == true) {
                ConnectApi.GenericObject extnAccountTypeObj = new ConnectApi.GenericObject();
                extnAccountTypeObj.value = extnAccountType;
                input.attributes.put('external_account_type', extnAccountTypeObj);
            }
            if (String.isNotBlank(extnAccountOwner) == true) {
                ConnectApi.GenericObject extnAccountOwnerObj = new ConnectApi.GenericObject();
                extnAccountOwnerObj.value = extnAccountOwner;
                input.attributes.put('external_account_owner', extnAccountOwnerObj);
            }  
            if (String.isNotBlank(transFirmName) == true) {
                ConnectApi.GenericObject transFirmNameObj = new ConnectApi.GenericObject();
                transFirmNameObj.value = transFirmName;
                input.attributes.put('transferring_firm_name', transFirmNameObj);
            }
            if (String.isNotBlank(transFirmAddress) == true) {
                ConnectApi.GenericObject transFirmAddressObj = new ConnectApi.GenericObject();
                transFirmAddressObj.value = transFirmAddress;
                input.attributes.put('transferring_firm_address', transFirmAddressObj);
            }
            if (String.isNotBlank(transFirmCity) == true) {
                ConnectApi.GenericObject transFirmCityObj = new ConnectApi.GenericObject();
                transFirmCityObj.value = transFirmCity;
                input.attributes.put('transferring_firm_city', transFirmCityObj);
            }
            if (String.isNotBlank(transFirmState) == true) {
                ConnectApi.GenericObject transFirmStateObj = new ConnectApi.GenericObject();
                transFirmStateObj.value = transFirmState;
                input.attributes.put('transferring_firm_state', transFirmStateObj);
            }
            if (String.isNotBlank(transFirmCountry) == true) {
                ConnectApi.GenericObject transFirmCountryObj = new ConnectApi.GenericObject();
                transFirmCountryObj.value = transFirmCountry;
                input.attributes.put('transferring_firm_country', transFirmCountryObj);
            }
            if (String.isNotBlank(transFirmZipCode) == true) {
                ConnectApi.GenericObject transFirmZipCodeObj = new ConnectApi.GenericObject();
                transFirmZipCodeObj.value = transFirmZipCode;
                input.attributes.put('transferring_firm_zip_code', transFirmZipCodeObj);
            }
            if (String.isNotBlank(transFirmPhone) == true) {
                ConnectApi.GenericObject transFirmPhoneObj = new ConnectApi.GenericObject();
                transFirmPhoneObj.value = transFirmPhone;
                input.attributes.put('transferring_firm_phone', transFirmPhoneObj);
            }
            if (String.isNotBlank(transferType) == true) {
                ConnectApi.GenericObject transferTypeObj = new ConnectApi.GenericObject();
                transferTypeObj.value = transferType;
                input.attributes.put('transfer_type', transferTypeObj);
            } 
            if (transferType == 'Brokerage or Trust Company Transfer' || transferType == 'Mutual Fund Company Account Transfer') {
                if (String.isNotBlank(transferEntireAccount) == true) {
                    ConnectApi.GenericObject transferEntireAccountObj = new ConnectApi.GenericObject();
                    transferEntireAccountObj.value = transferEntireAccount;
                    input.attributes.put('transfer_entire_account', transferEntireAccountObj);
                }
                if (transferType == 'Brokerage or Trust Company Transfer' && transferEntireAccount == 'No') {
                    if (String.isNotBlank(cash) == true) {
                        ConnectApi.GenericObject cashObj = new ConnectApi.GenericObject();
                        cashObj.value = cash;
                        input.attributes.put('cash', cashObj);
                    } 
                    if (String.isNotBlank(security) == true) {
                        ConnectApi.GenericObject securityObj = new ConnectApi.GenericObject();
                        securityObj.value = security;
                        input.attributes.put('security', securityObj);
                    }
                }
            }
            if (transferType != 'Brokerage or Trust Company Transfer' && transferType != 'Mutual Fund Company Account Transfer') {
                if (String.isNotBlank(mode) == true) {
                    ConnectApi.GenericObject modeObj = new ConnectApi.GenericObject();
                    modeObj.value = mode;
                    input.attributes.put('mode', modeObj);
                }
            }
            if (mode == 'Liquidate CD at maturity and send cash' || mode == 'Full Annuity Surrender, dated') {
                if (String.isNotBlank(maturityAnnuityDate) == true) {
                    ConnectApi.GenericObject maturityDateObj = new ConnectApi.GenericObject();
                    maturityDateObj.value = maturityAnnuityDate;
                    input.attributes.put('maturity_annuity_date', maturityDateObj);
                }
            }
            if (mode == 'Transfer partial cash amount' || mode == 'Partial Annuity Surrender' || (transferType == 'Brokerage or Trust Company Transfer' && cash == 'Yes')) {
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
                if ((transferType == 'Brokerage or Trust Company Transfer' && cash == 'Yes') && String.isNotBlank(amountMode) == true){
                    ConnectApi.GenericObject amountModeObj = new ConnectApi.GenericObject();
                    amountModeObj.value = amountMode;
                    input.attributes.put('amount_mode', amountModeObj);
                }
            }
            if (mode == 'Transfer the following number of whole shares') {
                if (String.isNotBlank(numOfShares) == true) {
                    ConnectApi.GenericObject numOfSharesObj = new ConnectApi.GenericObject();
                    numOfSharesObj.value = Double.valueOf(numOfShares);
                    input.attributes.put('number_of_shares', numOfSharesObj);
                }  
            }
            if (transferType == 'Brokerage or Trust Company Transfer' && security == 'Yes') {
                // Set Attributes for Brokerage or Trust Company Transfer  
                Object brokerageTrustCompanyTransferObj = inputMap.get('brokerageTrustCompanyTransfer');
                String brokerageTrustCompanyTransferListStr;
                if (brokerageTrustCompanyTransferObj instanceof List<Object>) {
                    brokerageTrustCompanyTransferListStr = JSON.serialize(brokerageTrustCompanyTransferObj);
                } else {
                    brokerageTrustCompanyTransferListStr = '['+ JSON.serialize(brokerageTrustCompanyTransferObj) +']';
                }
                ConnectApi.GenericObject brokerageTrustCompanyTransferList = new ConnectApi.GenericObject();
                List<Object> untypedListbrokerageTrustCompanyTransfer = (List<Object>) JSON.deserializeUntyped(brokerageTrustCompanyTransferListStr);
                List<Map<String, Object>> brokerageTrustCompanyTransferDetails = new List<Map<String, Object>>();
                Map<String, Object> brokerageTrustCompanyTransfer;
                for (Object jsonObj :untypedListbrokerageTrustCompanyTransfer) {
                    Map<String, Object> brokerageTrustCompanyTransferJsonObj = (Map<String, Object>)jsonObj;
                    brokerageTrustCompanyTransfer = new Map<String, Object>();
                    if (String.isNotBlank(String.valueOf(brokerageTrustCompanyTransferJsonObj.get('HoldingsName'))) == true) {
                        brokerageTrustCompanyTransfer.put('security_fund_name', String.valueOf(brokerageTrustCompanyTransferJsonObj.get('HoldingsName')));
                    }
                    if (String.isNotBlank(String.valueOf(brokerageTrustCompanyTransferJsonObj.get('SecurityQuantity'))) == true) {
                        brokerageTrustCompanyTransfer.put('quantity_mode', String.valueOf(brokerageTrustCompanyTransferJsonObj.get('SecurityQuantity')));
                    }
                    if (String.valueOf(brokerageTrustCompanyTransferJsonObj.get('SecurityQuantity')) == 'Custom' && String.isNotBlank(String.valueOf(brokerageTrustCompanyTransferJsonObj.get('SecuritiesNumberOfUnits'))) == true) {
                        brokerageTrustCompanyTransfer.put('number_of_units', Double.valueOf(brokerageTrustCompanyTransferJsonObj.get('SecuritiesNumberOfUnits')));
                    } 
                    brokerageTrustCompanyTransferDetails.add(brokerageTrustCompanyTransfer);   
                }
                if (!brokerageTrustCompanyTransferDetails.isEmpty()) {
                    brokerageTrustCompanyTransferList.value = brokerageTrustCompanyTransferDetails;
                    input.attributes.put('financial_instruments', brokerageTrustCompanyTransferList);
                }   
            }
            if (transferType == 'Mutual Fund Company Account Transfer' && transferEntireAccount == 'No') {
                // Set Attributes for Mutual Fund Company Account Transfer  
                Object mutualFundCompanyTransferObj = inputMap.get('mutualFundCompanyTransfer');
                String mutualFundCompanyTransferListStr;
                if (mutualFundCompanyTransferObj instanceof List<Object>) {
                    mutualFundCompanyTransferListStr = JSON.serialize(mutualFundCompanyTransferObj);
                } else {
                    mutualFundCompanyTransferListStr = '['+ JSON.serialize(mutualFundCompanyTransferObj) +']';
                }
                ConnectApi.GenericObject mutualFundCompanyTransferList = new ConnectApi.GenericObject();
                List<Object> untypedListmutualFundCompanyTransfer = (List<Object>) JSON.deserializeUntyped(mutualFundCompanyTransferListStr);
                List<Map<String, Object>> mutualFundCompanyTransferDetails = new List<Map<String, Object>>();
                Map<String, Object> mutualFundCompanyTransfer;
                for (Object jsonObj :untypedListmutualFundCompanyTransfer) {
                    Map<String, Object> mutualFundCompanyTransferJsonObj = (Map<String, Object>)jsonObj;
                    mutualFundCompanyTransfer = new Map<String, Object>();
                    if (String.isNotBlank(String.valueOf(mutualFundCompanyTransferJsonObj.get('FundName'))) == true) {
                        mutualFundCompanyTransfer.put('security_fund_name', String.valueOf(mutualFundCompanyTransferJsonObj.get('FundName')));
                    }
                    if (String.isNotBlank(String.valueOf(mutualFundCompanyTransferJsonObj.get('MutualFundQuantity'))) == true) {
                        mutualFundCompanyTransfer.put('quantity_mode', String.valueOf(mutualFundCompanyTransferJsonObj.get('MutualFundQuantity')));
                    }
                    if (String.isNotBlank(String.valueOf(mutualFundCompanyTransferJsonObj.get('MutualFundAccountNumber'))) == true) {
                        mutualFundCompanyTransfer.put('financial_instrument_account_number', String.valueOf(mutualFundCompanyTransferJsonObj.get('MutualFundAccountNumber')));
                    }
                    if (String.valueOf(mutualFundCompanyTransferJsonObj.get('MutualFundQuantity')) == 'Custom' && String.isNotBlank(String.valueOf(mutualFundCompanyTransferJsonObj.get('FundQuantity'))) == true) {
                        mutualFundCompanyTransfer.put('number_of_units', Double.valueOf(mutualFundCompanyTransferJsonObj.get('FundQuantity')));
                    }
                    if (String.isNotBlank(String.valueOf(mutualFundCompanyTransferJsonObj.get('TransferOptions'))) == true) {
                        mutualFundCompanyTransfer.put('transfer_option', String.valueOf(mutualFundCompanyTransferJsonObj.get('TransferOptions')));
                    }
                    mutualFundCompanyTransferDetails.add(mutualFundCompanyTransfer);   
                }
                if (!mutualFundCompanyTransferDetails.isEmpty()) {
                    mutualFundCompanyTransferList.value = mutualFundCompanyTransferDetails;
                    input.attributes.put('financial_instruments', mutualFundCompanyTransferList);
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