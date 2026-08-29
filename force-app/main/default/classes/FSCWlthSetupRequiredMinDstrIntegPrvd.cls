/*************************
* @Class Name:- FSCWlthSetupRequiredMinDstrIntegPrvd
* @Description:- Setup Required Minimum Distribution integration provider implementation
**************************/
global with sharing class FSCWlthSetupRequiredMinDstrIntegPrvd implements industriesintegrationfwk.ProcessIntegrationProvider {
    
    // Request time out in milliseconds
    private final static Integer TIMEOUT = 120000;
    // Named credential to get MuleSoft endpoint as stored in Setup
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final industriesintegrationfwk.ApexProviderAttr NAMED_CRED_ATTR = new industriesintegrationfwk.ApexProviderAttr('Named Credential', 
                                                                                                                                   NAMED_CREDENTIAL_KEY, 'FSC_wealth_integrations_V1_0_0', true, 'String');
    class AttributeValueGroup { 
        String accountNumber;
        String scheduleType;
        String paymentSchedule;
        String rmdOptions;
        String rmdDate;
        String taxYear;
        String amountOption;
        String currencyCode;
        String amount;
        String paymentOption;
        String bankAccountNumber;
        String bankRoutingNumber;
        String bankAccountHolderName;
        String bankAccountType;
        String bankName;
        String payeeName;
        String bankAddress;
        String bankCity;
        String bankState;
        String bankZipcode;
        String bankCountry;
        String taxWithholdingOption;
        String fedralPercentage;
        String statePercentage;
        String ownersStateOfResidence;
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
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, GroupNumber,NumberValue, TextValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :inputRecordId WITH SECURITY_ENFORCED];
            AttributeValueGroup attributeValueGroups = getAttributeValueGroup(svcCatalogReqExtdAttrVals);
            HttpResponse response = makeCallout(inputRecordId, attributeValueGroups, attributes, requestGuid);
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
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'financial_account_number') {
                attributeValueGroups.accountNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'payment_schedule') {
                attributeValueGroups.paymentSchedule = svcCatalogReqExtdAttrVal.TextValue;                
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'automated_rmd_option') {
                attributeValueGroups.rmdOptions = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'automated_rmd_date') {
                attributeValueGroups.rmdDate = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'tax_year') {
                attributeValueGroups.taxYear = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'amount_option') {
                attributeValueGroups.amountOption = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'currency_code') {
                attributeValueGroups.currencyCode = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'amount') {
                attributeValueGroups.amount = String.valueOf(svcCatalogReqExtdAttrVal.NumberValue);
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'payment_option') {
                attributeValueGroups.paymentOption = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_account_number') {
                attributeValueGroups.bankAccountNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_routing_number') {
                attributeValueGroups.bankRoutingNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_account_holder_name') {
                attributeValueGroups.bankAccountHolderName = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_account_type') {
                attributeValueGroups.bankAccountType = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_name') {
                attributeValueGroups.bankName = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'payee_name') {
                attributeValueGroups.payeeName = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_address') {
                attributeValueGroups.bankAddress = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_city') {
                attributeValueGroups.bankCity = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_state') {
                attributeValueGroups.bankState = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_country') {
                attributeValueGroups.bankCountry = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'bank_zipcode') {
                attributeValueGroups.bankZipcode = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'tax_withholding_option') {
                attributeValueGroups.taxWithholdingOption = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'federal_percentage') {
                attributeValueGroups.fedralPercentage = String.valueOf(svcCatalogReqExtdAttrVal.NumberValue);
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'state_percentage') {
                attributeValueGroups.statePercentage =  String.valueOf(svcCatalogReqExtdAttrVal.NumberValue);
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'owners_state_of_residence') {
                attributeValueGroups.ownersStateOfResidence = svcCatalogReqExtdAttrVal.TextValue;
            }         
        }
        return attributeValueGroups;
    }
    
    //make callout with POST method to mulesoft
    private static HttpResponse makeCallout(String inputRecordId, AttributeValueGroup attributeValueGroups, Map<String, Object> attributes, String requestGuid) {
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
        endPoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api' + '/InvestmentAccounts/' + financialAccountSysId + '/RMD' + requestParams;
        request.setMethod('POST');
        
        Map<String, Object> payload = constructPayload(inputRecordId, attributeValueGroups, financialAccountSysId);
        request.setBody(JSON.serialize(payload, true));
        // set headers
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setEndpoint(endpoint);
        request.setTimeout(TIMEOUT);
        HttpResponse response = new Http().send(request);
        return response;
    }
    
    //Construct the payload with the distribution details
    private static Map<String, Object> constructPayload(String inputRecordId, AttributeValueGroup attributeValueGroups, String financialAccountSysId) {
        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> withdrawlAmount = new Map<String, Object>();
        Map<String, Object> paymentInstructions = new Map<String, Object>();
        Map<String, Object> taxWithholdings = new Map<String, Object>();
        Map<String, Object> bankAddress = new Map<String, Object>();
        Map<String, Object> bankAccountDetails = new Map<String, Object>();
        Map<String, Object> address = new Map<String, Object>();
        Map<String, Object> distributionSchedule = new Map<String, Object>();
        
        //payload for One-time RMD
        if (attributeValueGroups.paymentSchedule != null && 
            (attributeValueGroups.paymentSchedule == 'One-time RMD' || attributeValueGroups.paymentSchedule == 'RMD for Missed Years')) {
                payload.put('PaymentOption', 'ONETIME RMD');
                if (attributeValueGroups.taxYear != null) {
                    payload.put('TaxYear', attributeValueGroups.taxYear);
                }
                if (attributeValueGroups.amountOption != null) {
                    if(attributeValueGroups.amountOption == 'To be calculated') {
                        payload.put('CalculateRMDAmount', 'Yes');
                    } else if (attributeValueGroups.amountOption == 'Enter withdrawal amount') {
                        payload.put('CalculateRMDAmount', 'No');
                        if (attributeValueGroups.currencyCode != null) {
                            withdrawlAmount.put('Currency', attributeValueGroups.currencyCode);
                        }
                        if (attributeValueGroups.amount != null) {
                            withdrawlAmount.put('Amount', attributeValueGroups.amount);
                        }
                        payload.put('WithdrawalAmount', withdrawlAmount);
                    }
                }
            } else if (attributeValueGroups.paymentSchedule != null && attributeValueGroups.paymentSchedule == 'Automated RMD') {
                payload.put('PaymentOption', 'AUTOMATED RMD');
                if (attributeValueGroups.rmdOptions != null) {
                    if (attributeValueGroups.rmdOptions == 'Automated Annual payments') {
                        payload.put('PaymentFrequency', 'ANNUAL');
                    } else if (attributeValueGroups.rmdOptions == 'Automated Quarterly payments') {
                        payload.put('PaymentFrequency', 'QUARTERLY');
                    } else if (attributeValueGroups.rmdOptions == 'Automated Monthly payments') {
                        payload.put('PaymentFrequency', 'MONTHLY');
                    } else if (attributeValueGroups.rmdOptions == 'Automated Semi-Annual payments') {
                        payload.put('PaymentFrequency', 'SEMI-ANNUAL');
                    }
                }
                if (attributeValueGroups.rmdDate != null) {
                    distributionSchedule.put('PaymentDate', attributeValueGroups.rmdDate);
                }
                payload.put('DistributionSchedule', distributionSchedule);
            }
        if (attributeValueGroups.paymentOption != null) {
            if (attributeValueGroups.paymentOption == 'Check') {
                paymentInstructions.put('PaymentInstructionType', 'BY_CHECK');
                
                if (attributeValueGroups.payeeName != null) {
                    paymentInstructions.put('PayeeName', attributeValueGroups.payeeName);
                }
                if (attributeValueGroups.bankName != null) {
                    paymentInstructions.put('BankName', attributeValueGroups.bankName);
                }
                if (attributeValueGroups.bankAddress != null) {
                    address.put('AddressLine1', attributeValueGroups.bankAddress);
                }
                if (attributeValueGroups.bankCity != null) {
                    address.put('City', attributeValueGroups.bankCity);
                }
                if (attributeValueGroups.bankState != null) {
                    address.put('State', attributeValueGroups.bankState);
                }
                if (attributeValueGroups.bankCountry != null) {
                    address.put('Country', attributeValueGroups.bankCountry);
                }
                if (attributeValueGroups.bankZipcode != null) {
                    address.put('PostalCode', attributeValueGroups.bankZipcode);
                }
                paymentInstructions.put('BankAddress', address);
            } else if (attributeValueGroups.paymentOption == 'Existing EFT Account' || attributeValueGroups.paymentOption == 'New EFT Account') {
                paymentInstructions.put('PaymentInstructionType', 'TO_BANK');
                if (attributeValueGroups.paymentOption == 'New EFT Account') {
                    paymentInstructions.put('EFTAccountType', 'NEW');
                    if (attributeValueGroups.bankAccountHolderName != null) {
                        bankAccountDetails.put('AccountHolderName', attributeValueGroups.bankAccountHolderName);
                    }
                    if (attributeValueGroups.bankAccountNumber != null) {
                        bankAccountDetails.put('AccountNumber', attributeValueGroups.bankAccountNumber);
                    }
                    if (attributeValueGroups.bankAccountType != null) {
                        bankAccountDetails.put('AccountType', attributeValueGroups.bankAccountType);
                    }
                    if (attributeValueGroups.bankRoutingNumber != null) {
                        bankAccountDetails.put('RoutingNumber', attributeValueGroups.bankRoutingNumber);
                    }
                    if (attributeValueGroups.bankName != null) {
                        bankAccountDetails.put('BankName', attributeValueGroups.bankName);
                    }
                    if (attributeValueGroups.bankAddress != null) {
                        address.put('AddressLine1', attributeValueGroups.bankAddress);
                    }
                    if (attributeValueGroups.bankCity != null) {
                        address.put('City', attributeValueGroups.bankCity);
                    }
                    if (attributeValueGroups.bankState != null) {
                        address.put('State', attributeValueGroups.bankState);
                    }
                    if (attributeValueGroups.bankCountry != null) {
                        address.put('Country', attributeValueGroups.bankCountry);
                    }
                    if (attributeValueGroups.bankZipcode != null) {
                        address.put('PostalCode', attributeValueGroups.bankZipcode);
                    }
                    bankAccountDetails.put('Address', address);
                    paymentInstructions.put('BankAccountDetails', bankAccountDetails);
                } else if (attributeValueGroups.paymentOption == 'Existing EFT Account') {
                    paymentInstructions.put('EFTAccountType', 'EXISTING');
                    if (attributeValueGroups.bankAccountNumber != null) {
                        bankAccountDetails.put('AccountNumber', attributeValueGroups.bankAccountNumber);
                    }
                    paymentInstructions.put('BankAccountDetails', bankAccountDetails);
                }
            }
        }
        if (attributeValueGroups.taxWithholdingOption != null && attributeValueGroups.taxWithholdingOption == 'Elect to have federal and state') {
            if (attributeValueGroups.ownersStateOfResidence != null) {
                taxWithholdings.put('State', attributeValueGroups.ownersStateOfResidence);
            }
            if (attributeValueGroups.statePercentage != null) {
                taxWithholdings.put('StateTaxPercentage', attributeValueGroups.statePercentage);
            }
            if (attributeValueGroups.fedralPercentage != null) {
                taxWithholdings.put('FederalTaxPercentage', attributeValueGroups.fedralPercentage);
            }
            payload.put('TaxWithholdings', taxWithholdings);
        }
        payload.put('PaymentInstructions', paymentInstructions);
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