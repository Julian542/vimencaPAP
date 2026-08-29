/*************************
* @Class Name:- FSCWlthManageStndInstrIntegProvider
* @Description:- Manage Standing Instruction process integration provider implementation
**************************/
global with sharing class FSCWlthManageStndInstrIntegProvider implements industriesintegrationfwk.ProcessIntegrationProvider {
    
    // Request time out in milliseconds
    private final static Integer TIMEOUT = 120000;
    // Named credential to get MuleSoft endpoint as stored in Setup
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final industriesintegrationfwk.ApexProviderAttr NAMED_CRED_ATTR = new industriesintegrationfwk.ApexProviderAttr('Named Credential', 
                                                                                                                                   NAMED_CREDENTIAL_KEY, 'FSC_wealth_integrations_V1_0_0', true, 'String');
    class AttributeValueGroup { 
        String accountNumber;
        String standinginstructiontype ;
    }
    
    class StandingInstructionToAddAttrValue {
        
        String Mode;
        String BankName;
        String PayeeAccountNumber;
        String RoutingNumber;
        String Details;
        String PayeeName;
        String AccountType;
        String PayeeAddress;
        String City;
        String State;
        String PostalCode;
        String Country;
        String TransferType;
        String CurrencyCode;
        String MaxAmount;
        String Prefix;
        String Memo;
        String CheckStubInformation;
        Integer groupNumber;
        Map<String, Object> Payments;        
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
            List<String> standingInstructionToDeleteAttrVal = new List<String>();
            List<StandingInstructionToAddAttrValue> standingInstructionToAddAttrValueDetails = new List<StandingInstructionToAddAttrValue>();
            
            if (attributeValueGroups.standinginstructiontype == 'Cancel') {
                standingInstructionToDeleteAttrVal = getStandingInstructionToDeleteAttrValue(svcCatalogReqExtdAttrVals);
            }
            
            if (attributeValueGroups.standinginstructiontype == 'Add') {
                Map<Integer, StandingInstructionToAddAttrValue> standingInstructionToAddAttrVal = getStandingInstructionToAddAttrValue(svcCatalogReqExtdAttrVals);
                for (Integer groupNumber : standingInstructionToAddAttrVal.keySet()) {
                    StandingInstructionToAddAttrValue standingInstructionToAddDetailsObj = new StandingInstructionToAddAttrValue();
                    standingInstructionToAddDetailsObj = standingInstructionToAddAttrVal.get(groupNumber);
                    standingInstructionToAddAttrValueDetails.add(standingInstructionToAddDetailsObj);
                }
            }
            
            HttpResponse response = makeCallout(inputRecordId, attributeValueGroups, standingInstructionToDeleteAttrVal, standingInstructionToAddAttrValueDetails, attributes, requestGuid);
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
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'standing_instruction_type') {
                attributeValueGroups.standinginstructiontype = svcCatalogReqExtdAttrVal.TextValue; 
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'account_number') {
                attributeValueGroups.accountNumber = svcCatalogReqExtdAttrVal.TextValue;
            } 
        }
        return attributeValueGroups;
    }
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of standing instruction to delete
    private static List<String> getStandingInstructionToDeleteAttrValue(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        
        String standingInstructionId  = null;
        List<String> paymentIdsList = new List<String>();
        
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'standing_instruction_id') {
                standingInstructionId = svcCatalogReqExtdAttrVal.TextValue;
                paymentIdsList.add(standingInstructionId);
            }        
        }
        return paymentIdsList;
    }
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of standing instructions to add
    private static Map<Integer, StandingInstructionToAddAttrValue> getStandingInstructionToAddAttrValue(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        Map<Integer, StandingInstructionToAddAttrValue> groupNumberToStandingInstructionToAddAttrValuesMap = new Map<Integer, StandingInstructionToAddAttrValue>();
        
        String mode = null;
        String bankName = null;
        String payeeAccountNumber  = null;
        String routingNumber  = null;
        String details = null;
        String payeeName  = null;
        String eftAccountType  = null;
        String payeeAddress  = null;
        String city = null;
        String state = null;
        String postalCode = null;
        String country = null;
        String transferType  = null;
        String currencyCode  = null;
        String maxAmount  = null;
        String prefix  = null;
        String memo  = null;
        String checkStubInformation  = null;
        String cancelPayeeName  = null;
        String cancelMode  = null;
        String cancelAccountNumber  = null;
        String standingInstructionId = null;
        
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            Boolean isAdd = false;
            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                when 'mode' {
                    mode = svcCatalogReqExtdAttrVal.TextValue;
                    isAdd = true;
                } when 'bank_name' {
                    bankName = svcCatalogReqExtdAttrVal.TextValue;
                    isAdd = true;
                } when 'payee_account_number' {
                    payeeAccountNumber = svcCatalogReqExtdAttrVal.TextValue;
                    isAdd = true;
                } when 'routing_number' {
                    routingNumber = svcCatalogReqExtdAttrVal.TextValue;
                    isAdd = true;
                } when 'details' {
                    if(String.isNotBlank(svcCatalogReqExtdAttrVal.TextValue)) {
                        details = svcCatalogReqExtdAttrVal.TextValue;
                    } else {
                        details = null;
                    }
                    isAdd = true;
                } when 'payee_name' {
                    payeeName  = svcCatalogReqExtdAttrVal.TextValue;
                    isAdd = true;
                } when 'eft_account_type' {
                    if(String.isNotBlank(svcCatalogReqExtdAttrVal.TextValue)) {
                        eftAccountType = svcCatalogReqExtdAttrVal.TextValue;
                    } else { 
                        eftAccountType = null; 
                    }
                    isAdd = true;
                } when 'payee_address' {
                    payeeAddress = svcCatalogReqExtdAttrVal.TextValue;
                    isAdd = true;
                } when 'city' {
                    city = svcCatalogReqExtdAttrVal.TextValue;
                    isAdd = true;
                } when 'state' {
                    state = svcCatalogReqExtdAttrVal.TextValue;
                    isAdd = true;
                } when 'country' {
                    country = svcCatalogReqExtdAttrVal.TextValue;
                    isAdd = true;
                } when 'zip_code' {
                    postalCode = svcCatalogReqExtdAttrVal.TextValue;
                    isAdd = true;
                } when 'transfer_type' {
                    if(String.isNotBlank(svcCatalogReqExtdAttrVal.TextValue)) {
                        transferType = svcCatalogReqExtdAttrVal.TextValue;
                    } else {
                        transferType = null; 
                    }
                    isAdd = true;
                } when 'currency_code' {
                    currencyCode = svcCatalogReqExtdAttrVal.TextValue;
                    isAdd = true;
                } when 'max_amount' {
                    maxAmount = String.valueOf(svcCatalogReqExtdAttrVal.NumberValue);
                    isAdd = true;
                } when 'prefix' {
                    prefix  = svcCatalogReqExtdAttrVal.TextValue;
                    isAdd = true;
                } when 'memo' {
                    if(String.isNotBlank(svcCatalogReqExtdAttrVal.TextValue)) {
                        memo = svcCatalogReqExtdAttrVal.TextValue;
                    } else {
                        memo = null;
                    }
                    isAdd = true;
                } when 'check_stub_information' {
                    if(String.isNotBlank(svcCatalogReqExtdAttrVal.TextValue)) {
                        checkStubInformation = svcCatalogReqExtdAttrVal.TextValue;
                    } else {
                        checkStubInformation = null;
                    }
                    isAdd = true;
                } 
            }
            
            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null && isAdd) {
                Map<String, List<String>> payeeAccountNumbersMap = new Map<String, List<String>>();
                List<String> payeeAccountNumbersList = new List<String>();
                
                StandingInstructionToAddAttrValue standingInstructionToAddAttrValue = groupNumberToStandingInstructionToAddAttrValuesMap.get(groupNumber);               
                standingInstructionToAddAttrValue = new StandingInstructionToAddAttrValue();
                
                groupNumberToStandingInstructionToAddAttrValuesMap.put(groupNumber, standingInstructionToAddAttrValue);
                standingInstructionToAddAttrValue.groupNumber = groupNumber;
                //assign add attribute values 
                standingInstructionToAddAttrValue.Mode = mode; 
                standingInstructionToAddAttrValue.BankName = bankName;
                standingInstructionToAddAttrValue.PayeeAccountNumber = payeeAccountNumber;
                standingInstructionToAddAttrValue.RoutingNumber = routingNumber;
                standingInstructionToAddAttrValue.PayeeName = payeeName;
                if (eftAccountType != null) {
                    standingInstructionToAddAttrValue.AccountType = eftAccountType;
                }
                standingInstructionToAddAttrValue.PayeeAddress = payeeAddress;
                standingInstructionToAddAttrValue.City = city;
                standingInstructionToAddAttrValue.State = state;
                standingInstructionToAddAttrValue.Country = country;
                standingInstructionToAddAttrValue.PostalCode = postalCode;
                if (transferType != null) {
                    standingInstructionToAddAttrValue.TransferType = transferType;
                }
                standingInstructionToAddAttrValue.MaxAmount = maxAmount; 
                standingInstructionToAddAttrValue.CurrencyCode = currencyCode;
                if (details != null) {
                    standingInstructionToAddAttrValue.Details = details;
                }
                standingInstructionToAddAttrValue.Prefix = prefix;
                if (memo != null) {
                    standingInstructionToAddAttrValue.Memo = memo; 
                }
                if (checkStubInformation != null) {
                    standingInstructionToAddAttrValue.CheckStubInformation = checkStubInformation;
                }
            }             
        }
        return groupNumberToStandingInstructionToAddAttrValuesMap;
    }
    
    //make callout with POST method to mulesoft
    private static HttpResponse makeCallout(String inputRecordId, AttributeValueGroup attributeValueGroups, List<String> standingInstructionToDeleteAttrVal, List<StandingInstructionToAddAttrValue> standingInstructionToAddAttrValue, Map<String, Object> attributes, String requestGuid) {
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
        if (attributeValueGroups.standinginstructiontype == 'Add') {
            endPoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api' + '/InvestmentAccounts/' + financialAccountSysId + '/Payments/Initiate' + requestParams;
            request.setMethod('POST');
        } else if (attributeValueGroups.standinginstructiontype == 'Cancel') {
            endPoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api' + '/InvestmentAccounts/' + financialAccountSysId + '/Payments/Update' + requestParams;
            request.setMethod('PATCH');
        }
        
        Map<String, Object> payload = constructPayload(inputRecordId, attributeValueGroups, standingInstructionToDeleteAttrVal, standingInstructionToAddAttrValue, financialAccountSysId);
        request.setBody(JSON.serialize(payload, true));
        // set headers
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setEndpoint(endpoint);
        request.setTimeout(TIMEOUT);
        HttpResponse response = new Http().send(request);
        return response;
    }
    
    //Construct the payload with the standing instruction details
    private static Map<String, Object> constructPayload(String inputRecordId, AttributeValueGroup attributeValueGroups, List<String> standingInstructionToDeleteAttrValue, List<StandingInstructionToAddAttrValue> standingInstructionToAddAttrValue, String financialAccountSysId) {
        Map<String, Object> payload = new Map<String, Object>();
        List<object> paymentsList = new List<object>();
        
        if (attributeValueGroups.standinginstructiontype == 'Add') {         
            for (StandingInstructionToAddAttrValue standingInstructionToAddDets : standingInstructionToAddAttrValue) {
                Map<String, Object> payments = new Map<String, Object>();
                Map<String, Object> paymentAmount = new Map<String, Object>();
                Map<String, Object> paymentDefinition = new Map<String, Object>();
                Map<String, Object> payeeBankReference = new Map<String, Object>();
                Map<String, Object> payeeAccountReference = new Map<String, Object>();
                Map<String, Object> payeeCheckReference = new Map<String, Object>();
                Map<String, Object> payeeAddress = new Map<String, Object>();       
                Map<String, Object> payeeReference = new Map<String, Object>();
                
                payments.put('PaymentType', 'standing order');
                payments.put('PaymentMode', standingInstructionToAddDets.Mode);
                if (standingInstructionToAddDets.TransferType != null) {
                    payments.put('PaymentTransferType', standingInstructionToAddDets.TransferType);
                }
                if (standingInstructionToAddDets.Mode != 'Journal') {
                    paymentAmount.put('MaxAmount',standingInstructionToAddDets.MaxAmount);
                    paymentAmount.put('Currency',standingInstructionToAddDets.CurrencyCode);
                    paymentDefinition.put('PaymentAmount', paymentAmount);
                    payments.put('PaymentDefinition', paymentDefinition);   
                }
                if (standingInstructionToAddDets.Mode == 'Wire Transfer' || standingInstructionToAddDets.Mode == 'EFT') {
                    payeeBankReference.put('BankName', standingInstructionToAddDets.BankName);
                    payeeBankReference.put('RoutingNumber', standingInstructionToAddDets.RoutingNumber);
                    payments.put('PayeeBankReference', payeeBankReference);
                }
                if (standingInstructionToAddDets.Mode != 'Check') {
                    payeeAccountReference.put('PayeeAccountNumber', standingInstructionToAddDets.PayeeAccountNumber);
                    if(standingInstructionToAddDets.AccountType != null) {
                        payeeAccountReference.put('PayeeAccountType', standingInstructionToAddDets.AccountType);
                    }
                    if(standingInstructionToAddDets.Details != null) {
                        payeeAccountReference.put('PayeeAccountDetails', standingInstructionToAddDets.Details);
                    }
                    payments.put('PayeeAccountReference', payeeAccountReference);
                }
                if (standingInstructionToAddDets.Mode == 'Check') {
                    payeeCheckReference.put('PayeeCheckMode', standingInstructionToAddDets.Prefix);
                    if(standingInstructionToAddDets.Memo != null) {
                        payeeCheckReference.put('PayeeCheckMemo', standingInstructionToAddDets.Memo);
                    }
                    if(standingInstructionToAddDets.CheckStubInformation != null) {
                        payeeCheckReference.put('PayeeCheckStubInformation', standingInstructionToAddDets.CheckStubInformation);
                    }
                    payments.put('PayeeCheckReference', payeeCheckReference);
                }
                if (standingInstructionToAddDets.Mode == 'Check' || standingInstructionToAddDets.Mode == 'Wire Transfer') {
                    payeeAddress.put('AddressLine1', standingInstructionToAddDets.PayeeAddress);
                    payeeAddress.put('City', standingInstructionToAddDets.City);
                    payeeAddress.put('State', standingInstructionToAddDets.State);
                    payeeAddress.put('PostalCode', standingInstructionToAddDets.PostalCode);
                    payeeAddress.put('Country', standingInstructionToAddDets.Country);
                    payeeReference.put('PayeeAddress', payeeAddress);
                }
                payeeReference.put('PayeeName',standingInstructionToAddDets.PayeeName);
                payments.put('PayeeReference', payeeReference);
                paymentsList.add(payments);
            }
            payload.put('Payments', paymentsList);             
        }
        else if (attributeValueGroups.standinginstructiontype == 'Cancel') {  
            payload.put('PaymentIds', standingInstructionToDeleteAttrValue);
        }
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
        if (response.getStatusCode() == 201 || response.getStatusCode() == 200) {
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