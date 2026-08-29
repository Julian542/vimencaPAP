/*************************
* @Class Name:- FSCWlthInitAutomatedAcctTrfrIntegPrvd
* @Description:- Automated Customer Account Transfer process integration provider implementation
**************************/
global with sharing class FSCWlthInitAutomatedAcctTrfrIntegPrvd implements industriesintegrationfwk.ProcessIntegrationProvider {
    
    // Request time out in milliseconds
    private final static Integer TIMEOUT = 120000;
    // Named credential to get MuleSoft endpoint as stored in Setup
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final industriesintegrationfwk.ApexProviderAttr NAMED_CRED_ATTR = new industriesintegrationfwk.ApexProviderAttr('Named Credential', 
                                                                                                                                   NAMED_CREDENTIAL_KEY, 'FSC_wealth_integrations_V1_0_0', true, 'String');
    class AttributeValueGroup { 
        
        String accountNumber;
        String transferType;
        String externalAccountNumber;
        String externalAccountType;
        String externalAccountOwner;
        String transferringFirmName;
        String transferringFirmAddress;
        String transferringFirmState;
        String transferringFirmCountry;
        String transferringFirmCity;
        String transferringZipCode;
        String transferringPhone;
        String transferAction;
        String transferEntireAccount;
        String mode;
        String amountMode;
        String security;
        String cash;
        String amount;
        String currencyCode;
        String maturityannuityDate;
        String numberofShares;
    }
    
    class ACATFinancialInstrumentsAttrValue {
        
        Integer groupNumber;
        String SecurityName;
        String Quantity;
        String NumberofUnits;
        String AccountNumber;
        String TransferInstruction; 
        String TransferAll;
        String FundName;
    }
    
    /**
* @param requestGuid                 Request GUID provided by the client
* @param inputRecordId               Input Record ID provided by the client
* @param payload                     Payload to be passed to the Provider Class
* @param attributes                  Map of config attributes
*
* @return industriesintegrationfwk.IntegrationCalloutResponse
*         Response sent to the client
*/
    global static industriesintegrationfwk.IntegrationCalloutResponse executeCallout(String requestGuid, String inputRecordId, String payload, Map<String, Object> attributes) {
        if (String.isBlank(inputRecordId)) {
            throw new IllegalArgumentException('Service Process ID is null');
        }
        try {
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, GroupNumber,NumberValue, TextValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :inputRecordId WITH SECURITY_ENFORCED ORDER BY GroupNumber ASC NULLS FIRST];
            AttributeValueGroup attributeValueGroups = getAttributeValueGroup(svcCatalogReqExtdAttrVals);
            List<ACATFinancialInstrumentsAttrValue> ACATFinancialInstrumentsToAddAttrValueDetails = new List<ACATFinancialInstrumentsAttrValue>();
            
            Map<Integer, ACATFinancialInstrumentsAttrValue> acatFinancialInstrumentAttrVal = getAcatFinancialInstrumentsAttrValue(svcCatalogReqExtdAttrVals);
            for (Integer groupNumber : acatFinancialInstrumentAttrVal.keySet()) {
                
                ACATFinancialInstrumentsAttrValue acatFinancialInstrumentToAddDetailsObj = new ACATFinancialInstrumentsAttrValue();
                acatFinancialInstrumentToAddDetailsObj = acatFinancialInstrumentAttrVal.get(groupNumber);
                ACATFinancialInstrumentsToAddAttrValueDetails.add(acatFinancialInstrumentToAddDetailsObj);
            }
            
            HttpResponse response = makeCallout(inputRecordId, attributeValueGroups, ACATFinancialInstrumentsToAddAttrValueDetails, attributes, requestGuid);
            Map<String, Object> responseGroup = getResponseGroupAfterCallout(response);        
            industriesintegrationfwk.IntegrationCalloutResponse integrationCalloutResponse = new industriesintegrationfwk.IntegrationCalloutResponse(true);
            integrationCalloutResponse.setReturnValue(responseGroup);
            return integrationCalloutResponse;
            
        } catch (Exception ex) {
            throw new CalloutException(ex);
        }
    }
    
    //getting all the attribute detail values by looping through svcCatalogReqExtdAttrVals records
    private static AttributeValueGroup getAttributeValueGroup(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        
        AttributeValueGroup attributeValueGroups = new AttributeValueGroup(); 
        
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'transfer_type') {
                attributeValueGroups.transferType = svcCatalogReqExtdAttrVal.TextValue;                
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'financial_account_number') {
                attributeValueGroups.accountNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'transfer_action') {
                attributeValueGroups.transferAction = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'external_account_number') {
                attributeValueGroups.externalAccountNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'external_account_type') {
                attributeValueGroups.externalAccountType = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'external_account_owner') {
                attributeValueGroups.externalAccountOwner = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'transferring_firm_name') {
                attributeValueGroups.transferringFirmName = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'transferring_firm_address') {
                attributeValueGroups.transferringFirmAddress = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'transferring_firm_city') {
                attributeValueGroups.transferringFirmCity = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'transferring_firm_state') {
                attributeValueGroups.transferringFirmState = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'transferring_firm_country') {
                attributeValueGroups.transferringFirmCountry = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'transferring_firm_zip_code') {
                attributeValueGroups.transferringZipCode = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'transferring_firm_phone') {
                attributeValueGroups.transferringPhone = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'transfer_entire_account') {
                attributeValueGroups.transferEntireAccount = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'mode') {
                attributeValueGroups.mode = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'amount_mode') {
                attributeValueGroups.amountMode = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'security') {
                attributeValueGroups.security = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'cash') {
                attributeValueGroups.cash = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'amount') {
                attributeValueGroups.amount = String.valueOf(svcCatalogReqExtdAttrVal.NumberValue);
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'currency_code') {
                attributeValueGroups.currencyCode = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'maturity_annuity_date') {
                attributeValueGroups.maturityannuityDate = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'number_of_shares') {
                attributeValueGroups.numberofShares  = String.valueOf(svcCatalogReqExtdAttrVal.NumberValue);
            }           
        }
        return attributeValueGroups;
    }
    
    //looping through the svcCatalogReqExtdAttrVals records to get the list of financial instruments to add
    private static  Map<Integer, ACATFinancialInstrumentsAttrValue> getAcatFinancialInstrumentsAttrValue(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        
        Map<Integer, ACATFinancialInstrumentsAttrValue> groupNumberToACATFinancialInstrumentsValuesMap = new Map<Integer, ACATFinancialInstrumentsAttrValue>();
        String securityFundName = null;
        String quantityMode = null;
        String numberofUnits = null;
        String finAccountNumber = null;
        String transferOption = null;    
        
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                when 'security_fund_name' {
                    securityFundName = svcCatalogReqExtdAttrVal.TextValue;
                } when 'quantity_mode' {
                    quantityMode = svcCatalogReqExtdAttrVal.TextValue;
                } when 'number_of_units' {
                    numberofUnits = String.valueOf(svcCatalogReqExtdAttrVal.NumberValue);
                } when 'transfer_option' {
                    transferOption = svcCatalogReqExtdAttrVal.TextValue;
                } when 'financial_instrument_account_number' {
                    finAccountNumber = svcCatalogReqExtdAttrVal.TextValue;
                }
            }
            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null) {
                
                ACATFinancialInstrumentsAttrValue acatFinancialInstrumentsAddAttrValue = groupNumberToACATFinancialInstrumentsValuesMap.get(groupNumber);               
                acatFinancialInstrumentsAddAttrValue = new ACATFinancialInstrumentsAttrValue();
                
                groupNumberToACATFinancialInstrumentsValuesMap.put(groupNumber, acatFinancialInstrumentsAddAttrValue);
                acatFinancialInstrumentsAddAttrValue.groupNumber = groupNumber;
                //assign add attribute values 
                acatFinancialInstrumentsAddAttrValue.SecurityName = securityFundName; 
                acatFinancialInstrumentsAddAttrValue.Quantity = quantityMode;
                acatFinancialInstrumentsAddAttrValue.NumberofUnits = numberofUnits;
                acatFinancialInstrumentsAddAttrValue.TransferInstruction = transferOption;
                acatFinancialInstrumentsAddAttrValue.AccountNumber = finAccountNumber;
            }
        }
        
        return groupNumberToACATFinancialInstrumentsValuesMap;
    }
    
    //make callout with POST method to mulesoft
    private static HttpResponse makeCallout(String inputRecordId, AttributeValueGroup attributeValueGroups, List<ACATFinancialInstrumentsAttrValue> ACATFinancialInstrumentsToAddAttrValueDetails, Map<String, Object> attributes, String requestGuid) {
        String endPoint;
        String recordId = FSCWlthUtilityClass.getAccountSourceSystemId(inputRecordId);
        if (recordId == null) {
            throw new IllegalArgumentException('Source System ID is null');
        }
        String financialAccountSysId = FSCWlthUtilityClass.getFinancialAccSourceSystemId(recordId, attributeValueGroups.accountNumber);
        if (financialAccountSysId == null) {
            throw new IllegalArgumentException('Financial Account Source System ID is null');
        }
        String requestParams = '?requestId=' + inputRecordId;
        if (String.isNotBlank(requestGuid)){
            requestParams = requestParams + '&flowRefId=' + requestGuid;
        }
        HttpRequest request = new HttpRequest();
        endPoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api' + '/InvestmentAccounts/' + financialAccountSysId + '/Acats' + requestParams;
        //endPoint = 'callout:FSC_wealth_integrations_V1_0_0/api/InvestmentAccounts/' + financialAccountSysId + '/Acats' + requestParams;
        request.setMethod('POST');
        
        Map<String, Object> payload = constructPayload(inputRecordId, attributeValueGroups, ACATFinancialInstrumentsToAddAttrValueDetails, financialAccountSysId);
        request.setBody(JSON.serialize(payload, true));
        // set headers
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setEndpoint(endpoint);
        request.setTimeout(TIMEOUT);
        HttpResponse response = new Http().send(request);
        return response;
    }
    
    //Construct the payload with the beneficiary details
    private static Map<String, Object> constructPayload(String inputRecordId, AttributeValueGroup attributeValueGroups, List<ACATFinancialInstrumentsAttrValue> ACATFinancialInstrumentsToAddAttrValueDetails, String financialAccountSysId) {
        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> acatDetails = new Map<String, Object>();
        Map<String, Object> externalAccountDetails = new Map<String, Object>();
        Map<String, Object> transferringFirmDetails = new Map<String, Object>();
        Map<String, Object> address = new Map<String, Object>();
        Map<String, Object> transferDetails = new Map<String, Object>();
        Map<String, Object> cash = new Map<String, Object>();
        Map<String, Object> annuity = new Map<String, Object>();
        Map<String, Object> shares = new Map<String, Object>();
        Map<String, Object> sellFractions = new Map<String, Object>();
        List<object> securityList = new List<object>();
        
        acatDetails.put('TransferType', attributeValueGroups.transferType);
        If (attributeValueGroups.transferEntireAccount == 'No') {
            acatDetails.put('AcatType', 'PARTIAL_TRANSFER');
            if (attributeValueGroups.transferType == 'Brokerage or Trust Company Transfer') {          
                if (attributeValueGroups.cash == 'Yes') {
                    if(attributeValueGroups.amountMode == 'All') {
                        cash.put('TransferAll', 'Yes'); 
                    } else {
                        cash.put('Amount', attributeValueGroups.amount);
                        cash.put('Currency', attributeValueGroups.currencyCode);
                    }
                    transferDetails.put('Cash', cash);
                }
                if (attributeValueGroups.security == 'Yes') {  
                    for (ACATFinancialInstrumentsAttrValue acatFinancialInstrumentsToAddDets : ACATFinancialInstrumentsToAddAttrValueDetails) {
                        ACATFinancialInstrumentsAttrValue FinancialInstrumentsDetails = new ACATFinancialInstrumentsAttrValue();
                        if (acatFinancialInstrumentsToAddDets.Quantity == 'All') {
                            FinancialInstrumentsDetails.TransferAll =  'Yes';
                            FinancialInstrumentsDetails.SecurityName = acatFinancialInstrumentsToAddDets.SecurityName;
                        } else {
                            FinancialInstrumentsDetails.SecurityName = acatFinancialInstrumentsToAddDets.SecurityName;
                            FinancialInstrumentsDetails.Quantity = acatFinancialInstrumentsToAddDets.NumberofUnits;
                        }
                        securityList.add(FinancialInstrumentsDetails);
                    }
                    transferDetails.put('Securities', securityList);
                }
                
            }
            else if (attributeValueGroups.transferType == 'Mutual Fund Company Account Transfer') {
                for (ACATFinancialInstrumentsAttrValue acatFinancialInstrumentsToAddDets : ACATFinancialInstrumentsToAddAttrValueDetails) {
                    ACATFinancialInstrumentsAttrValue FinancialInstrumentsDetails = new ACATFinancialInstrumentsAttrValue();
                    if (acatFinancialInstrumentsToAddDets.Quantity == 'All') {
                        FinancialInstrumentsDetails.TransferAll =  'Yes';
                    } else {
                        FinancialInstrumentsDetails.Quantity = acatFinancialInstrumentsToAddDets.NumberofUnits;
                    }
                    FinancialInstrumentsDetails.FundName = acatFinancialInstrumentsToAddDets.SecurityName;
                    FinancialInstrumentsDetails.AccountNumber = acatFinancialInstrumentsToAddDets.AccountNumber;
                    FinancialInstrumentsDetails.TransferInstruction = acatFinancialInstrumentsToAddDets.TransferInstruction;
                    securityList.add(FinancialInstrumentsDetails);
                }
                transferDetails.put('FundsTransfer', securityList);
            }
            acatDetails.put('TransferDetails', transferDetails);
        }
        else if (attributeValueGroups.transferEntireAccount == 'Yes') {
            acatDetails.put('AcatType', 'FULL_TRANSFER');
        }
        
        if (attributeValueGroups.transferType == 'Bank or Credit Union Account Transfer') { 
            String modeofBank = null;
            if ((attributeValueGroups.mode) == 'Transfer All cash only'){
                cash.put('TransferAll', 'Yes');
                modeofBank = 'cash';
            } else if ((attributeValueGroups.mode) == 'Transfer partial cash amount') {
                cash.put('Amount', attributeValueGroups.amount);
                cash.put('Currency', attributeValueGroups.currencyCode);
                modeofBank = 'cash';
            } else if ((attributeValueGroups.mode).contains('Liquidate CD immediately')) {
                cash.put('LiquidateAt', 'immediately');
                modeofBank = 'cd'; 
            } else if ((attributeValueGroups.mode) == 'Liquidate CD at maturity and send cash') {
                cash.put('LiquidateAt', attributeValueGroups.maturityannuityDate);
                modeofBank = 'cd'; 
            }
            if (modeofBank == 'cash') 
                transferDetails.put('CashTransfer', cash);  
            else 
                transferDetails.put('CDTransfer', cash);  
            acatDetails.put('TransferDetails', transferDetails);
            
        } else if (attributeValueGroups.transferType == 'Annuity Transfer') {
            if ((attributeValueGroups.mode).contains('Full Annuity Surrender')){
                cash.put('AnnuityType', 'FULL');
                if (attributeValueGroups.maturityannuityDate != null)
                    cash.put('AnnuityDate', attributeValueGroups.maturityannuityDate); 
            } else {
                cash.put('AnnuityType', 'PARTIAL');
                if (attributeValueGroups.mode == 'Partial Annuity Surrender') {
                    annuity.put('Amount', attributeValueGroups.amount); 
                    annuity.put('Currency', attributeValueGroups.currencyCode);
                    cash.put('AnnuityAmount', annuity);
                }
            }
            transferDetails.put('AnnuityTransfer', cash); 
            acatDetails.put('TransferDetails', transferDetails);
        }
        else if (attributeValueGroups.transferType == 'Managed Account Transfer') {
            if ((attributeValueGroups.mode) == 'Transfer all whole shares and sell fractions') {
                shares.put('TransferAll', 'Yes');
                sellFractions.put('TransferAll', 'Yes'); 
                cash.put('Shares', shares);
                cash.put('SelfFractions', sellFractions);
            } else if ((attributeValueGroups.mode) == 'Transfer all whole shares only') {
                shares.put('TransferAll', 'Yes');
                cash.put('Shares', shares);
            } else if ((attributeValueGroups.mode) == 'Transfer all whole shares, sell fractions, and close account') {
                shares.put('TransferAll', 'Yes');
                sellFractions.put('TransferAll', 'Yes');
                cash.put('CloseAccount', 'Yes');
                cash.put('Shares', shares);
                cash.put('SellFractions', sellFractions);
            } else if ((attributeValueGroups.mode) == 'Transfer the following number of whole shares') {
                shares.put('Quantity', attributeValueGroups.numberofShares);
                cash.put('Shares', shares);
            }
            transferDetails.put('ManagedAccountTransfer', cash); 
            acatDetails.put('TransferDetails', transferDetails);
        }
        acatDetails.put('TransferAction', attributeValueGroups.transferAction);        
        transferringFirmDetails.put('FirmName', attributeValueGroups.transferringFirmName);
        transferringFirmDetails.put('Phone', attributeValueGroups.transferringPhone);
        if(attributeValueGroups.transferringFirmAddress != null){
            address.put('AddressLine1', attributeValueGroups.transferringFirmAddress);
        }
        if(attributeValueGroups.transferringFirmState != null){
            address.put('State', attributeValueGroups.transferringFirmState);
        }
        if(attributeValueGroups.transferringFirmCity != null){
            address.put('City', attributeValueGroups.transferringFirmCity);
        }
        if(attributeValueGroups.transferringZipCode != null){
            address.put('PostalCode', attributeValueGroups.transferringZipCode);
        }
        if(attributeValueGroups.transferringFirmCountry != null){
            address.put('Country',  attributeValueGroups.transferringFirmCountry);
        }
        externalAccountDetails.put('AccountNumber', attributeValueGroups.externalAccountNumber);
        externalAccountDetails.put('AccountType', attributeValueGroups.externalAccountType);
        externalAccountDetails.put('AccountTitle', attributeValueGroups.externalAccountOwner);
        if(address.size() > 0){
        	transferringFirmDetails.put('Address', address);
        }
        externalAccountDetails.put('TransferringFirmDetails', transferringFirmDetails);               
        acatDetails.put('ExternalAccountDetails', externalAccountDetails);
        payload.put('AcatDetails', acatDetails);
        
        return payload;
    }
    
    //Method to get the attribute values from the integration definition
    global static List<industriesintegrationfwk.ApexProviderAttr> getProviderAttributes() {
        List<industriesintegrationfwk.ApexProviderAttr> defaults = new List<industriesintegrationfwk.ApexProviderAttr>();
        defaults.add(NAMED_CRED_ATTR);
        return defaults;
    }
    
    //Method to check for the status code
    private static Map<String, Object> getResponseGroupAfterCallout(HttpResponse response) {
        Map<String, Object> responseGroup = new Map<String, Object>();
        if (response.getStatusCode() == 201) {
            responseGroup.put('isSuccess', true);
        } else {
            responseGroup.put('isSuccess', false);
        }
        responseGroup.put('response', getResponseMap(response.getBody()));
        return responseGroup;
    }
    
    //Method to generate the response
    private static Map<String, Object> getResponseMap(String responsebody) {
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(responsebody);
        } catch (Exception ex) {
            Map<String, Object> responseMap = new Map<String,Object>();
            responseMap.put('response', responsebody);
            return responseMap;
        }
    }
    
}