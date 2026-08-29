/*************************
* @Class Name:- TransferFundsToOwnAccountIntegProvider
* @Description:- Transfer Funds to Own Account process integration provider implementation
**************************/
global with sharing class TransferFundsToOwnAccountIntegProvider implements industriesintegrationfwk.ProcessIntegrationProvider {
    
    // Request time out in milliseconds
    private final static Integer TIMEOUT = 120000;
    
    // Named credential to get MuleSoft endpoint as stored in Setup
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    
    private static final industriesintegrationfwk.ApexProviderAttr NAMED_CRED_ATTR = new industriesintegrationfwk.ApexProviderAttr('Named Credential', 
                                                                                                                                   NAMED_CREDENTIAL_KEY, 'FSC_fsc_integrations_V1_0_0', true, 'String');
    class AttributeValueGroup { 
        String payerReferenceId;
        String payeeReferenceId;
        String paymentType;
        Decimal amount;
        String transferringFromAccountNumber;
        String transferringToAccountNumber;
        String transferringToAccountName;
        String transferringToAccountType;
        String transferringFromAccountType;
        String transferDate;
        String currencyCode;
        String remarks;
        String startDate;
        String endDate;
        String frequency;
        Decimal instalment;
        String recurringPaymentOption;
    }
    
/**
* @param requestGuid                 Request GUID provided by the client
* @param inputRecordId               Input Record ID provided by the client
* @param payload                     Payload to be passed to the Provider Class
* @param attributes                  Map of config attributes
* @return industriesintegrationfwk.IntegrationCalloutResponse
*         Response sent to the client
*/
    global static industriesintegrationfwk.IntegrationCalloutResponse executeCallout(String requestGuid, String inputRecordId, String payload, Map<String, Object> attributes) {
        if (String.isBlank(inputRecordId)) {
            throw new IllegalArgumentException('Service Process ID is null');
        }
        try {
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, TextValue, NumberValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :inputRecordId WITH SECURITY_ENFORCED];
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
    
    //getting all the update contact details by looping through SvcCatalogReqExtdAttrVals records
    private static AttributeValueGroup getAttributeValueGroup(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        
        AttributeValueGroup attributeValueGroups = new AttributeValueGroup();           
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'payment_type') {
                attributeValueGroups.paymentType = svcCatalogReqExtdAttrVal.TextValue.toLowercase();
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'amount') {
                attributeValueGroups.amount = svcCatalogReqExtdAttrVal.NumberValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'source_account_number') {
                attributeValueGroups.transferringFromAccountNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'destination_account_number') {
                attributeValueGroups.transferringToAccountNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'destination_account_name') {
                attributeValueGroups.transferringToAccountName = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'destination_account_type') {
                attributeValueGroups.transferringToAccountType = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'source_account_type') {
                attributeValueGroups.transferringFromAccountType = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'recurring_transfer_option') {
                attributeValueGroups.recurringPaymentOption = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'transfer_date') {
                attributeValueGroups.transferDate = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'currency_code') {
                attributeValueGroups.currencyCode = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'remarks') {
                attributeValueGroups.remarks = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'start_date') {
                attributeValueGroups.startDate = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'end_date') {
                attributeValueGroups.endDate = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'frequency') {
                attributeValueGroups.frequency = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'installment') {
                attributeValueGroups.instalment = svcCatalogReqExtdAttrVal.NumberValue;
            }
        }
        return attributeValueGroups;
    }
    
    //make callout with POST method to mulesoft
    private static HttpResponse makeCallout(String inputRecordId, AttributeValueGroup attributeValueGroups, Map<String, Object> attributes, String requestGuid) {
        String accountType;
        String recordId = FSCUtilityClass.getAccountSourceSystemId(inputRecordId);
        if (recordId == null) {
            throw new IllegalArgumentException('Source System ID is null');
        } 
        //Get Financial account Source system ID and if null throw exception
        String finAccSourceSysIdFromAcc = FSCUtilityClass.getFinancialAccSourceSystemId(recordId, attributeValueGroups.transferringFromAccountNumber);
        if (finAccSourceSysIdFromAcc == null) {
            throw new IllegalArgumentException('Source System ID is null');
        }
        // Get the record type of the financial account from transfer from account
        if (attributeValueGroups.transferringFromAccountType == 'Savings Account') {
            accountType = 'SavingsAccount';
        } else if (attributeValueGroups.transferringFromAccountType == 'Checking Account') {
            accountType = 'CurrentAccount';
        } else if (attributeValueGroups.transferringFromAccountType == 'HELOC') {
            accountType = 'HomeEquityLoan';
        }
        
        String requestParams = '?requestId=' + inputRecordId;
        If (String.isNotBlank(requestGuid))
            requestParams = requestParams + '&flowRefId=' + requestGuid;
        
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        String endPoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api/' + accountType + '/' + finAccSourceSysIdFromAcc + '/Payments/Initiate' + requestParams;
        Map<String, Object> payload = constructPayload(inputRecordId, attributeValueGroups, recordId);
        request.setBody(JSON.serialize(payload, true));
        // set headers
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setEndpoint(endpoint);
        request.setTimeout(TIMEOUT);
        HttpResponse response = new Http().send(request);
        return response;
    }
    
    //Construct the payload with the travel details
    private static Map<String, Object> constructPayload (String inputRecordId, AttributeValueGroup attributeValueGroups, String recordId) {
        
        //Get Financial account Source system ID and if null throw exception
        String finAccSourceSysIdToAcc = FSCUtilityClass.getFinancialAccSourceSystemId(recordId, attributeValueGroups.transferringToAccountNumber);
        if (finAccSourceSysIdToAcc == null) {
            throw new IllegalArgumentException('Source System ID is null');
        }
        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> payments = new Map<String, Object>();
        Map<String, Object> paymentDefinition = new Map<String, Object>();
        Map<String, Object> paymentAmount = new Map<String, Object>();
        Map<String, Object> autoPay = new Map<String, Object>();
        Map<String, Object> paymentSchedule = new Map<String, Object>();
        Map<String, Object> payeeReference = new Map<String, Object>();
        Map<String, Object> payeeAccountReference = new Map<String, Object>();
        
        if (attributeValueGroups.amount != null) {
            paymentAmount.put('Amount', String.valueOf(attributeValueGroups.amount));
        }
        if (attributeValueGroups.currencyCode != null) {
            paymentAmount.put('Currency', attributeValueGroups.currencyCode);
        }
        if (attributeValueGroups.recurringPaymentOption != null) {
            autoPay.put('AutoPayAmount', attributeValueGroups.recurringPaymentOption);
        }
        if (attributeValueGroups.paymentType == 'Recurring') {
            if (attributeValueGroups.frequency != null) {
                paymentSchedule.put('PaymentFrequency', attributeValueGroups.frequency);
            }
            if (attributeValueGroups.instalment != null) {
                paymentSchedule.put('NumberOfPayments', String.valueOf(attributeValueGroups.instalment)); 
            }
            if (attributeValueGroups.startDate != null) {
                paymentSchedule.put('PaymentStartDate', attributeValueGroups.startDate);
            }
            if (attributeValueGroups.endDate != null) {
                paymentSchedule.put('PaymentEndDate', attributeValueGroups.endDate); 
            }
        }
        if (attributeValueGroups.paymentType == 'One-time' && attributeValueGroups.transferDate != null) {
            paymentSchedule.put('PaymentStartDate', attributeValueGroups.transferDate);
        }
        if (attributeValueGroups.transferringToAccountName != null) {
            payeeReference.put('PayeeName', attributeValueGroups.transferringToAccountName);
        }
        if (finAccSourceSysIdToAcc != null) {
            payeeAccountReference.put('PayeeAccountNumber', finAccSourceSysIdToAcc);
        }
        if (attributeValueGroups.transferringToAccountType != null) {
            payeeAccountReference.put('PayeeAccountType', attributeValueGroups.transferringToAccountType);
        }
        if (attributeValueGroups.amount != null && attributeValueGroups.currencyCode != null ) {
            paymentDefinition.put('PaymentAmount', paymentAmount);
        }
        if (attributeValueGroups.recurringPaymentOption != null ) {
            paymentDefinition.put('AutoPay', autoPay);
        }
        if (attributeValueGroups.paymentType == 'Recurring') {
            payments.put('PaymentType','standing order');
        }
        if (attributeValueGroups.paymentType == 'One-time') {
            payments.put('PaymentType','direct debit');
        }
        payments.put('PaymentDefinition', paymentDefinition);
        payments.put('PaymentSchedule', paymentSchedule);
        payments.put('PayeeReference', payeeReference);
        if (attributeValueGroups.paymentType != null) {
            payments.put('PaymentMechanism', attributeValueGroups.paymentType);
        }
        if (attributeValueGroups.remarks != null) {
            payments.put('PaymentPurpose', attributeValueGroups.remarks);
        }
        payments.put('PayeeAccountReference', payeeAccountReference);
        payload.put('Payments', payments);
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
        } catch (Exception e) {
            Map<String, Object> responseMap = new Map<String, Object>(); 
            responseMap.put('response', responsebody);
            return responseMap;
        }
    }
    
}