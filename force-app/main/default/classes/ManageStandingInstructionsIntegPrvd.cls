/*************************
* @Class Name:- ManageStandingInstructionsIntegPrvd
* @Description:- Manage Standing Instructions integration provider implementation
**************************/
global with sharing class ManageStandingInstructionsIntegPrvd implements industriesintegrationfwk.ProcessIntegrationProvider {
    
    // Request time out in milliseconds
    private final static Integer TIMEOUT = 120000;
    // Named credential to get MuleSoft endpoint as stored in Setup
    private static final String NAMED_CREDENTIAL_KEY = 'Named_Credential';
    private static final String PERSON_ACCOUNT_URL_PATH_KEY = 'Person_Account_URL_Path';
    private static final industriesintegrationfwk.ApexProviderAttr NAMED_CRED_ATTR = new industriesintegrationfwk.ApexProviderAttr('Named Credential', NAMED_CREDENTIAL_KEY, 'FSC_fsc_integrations_V1_0_0', true, 'String');
    private static final industriesintegrationfwk.ApexProviderAttr PERSON_ACCOUNT_URL_PATH_ATTR = new industriesintegrationfwk.ApexProviderAttr('Person Account URL Path', PERSON_ACCOUNT_URL_PATH_KEY, '/api/customers/{recordId}', true, 'String');
    
    class AttributeValueGroup { 
        String accountNumber;
        String accountType;
        String payeeName;
        String payeeAccountNumber;
        String payeeRoutingNumber;
        String standingInstructionType;
        String standingInstructionId;
        String amount;
        String currencyValue;
        String startDate;
        String endDate;
        String frequency;
        String noOfInstallment;
        String remarks;
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
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, TextValue, IntegerValue, NumberValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :inputRecordId WITH SECURITY_ENFORCED];
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
    
    //getting all the manage standing instructions details by looping through svcCatalogReqExtdAttrVals records
    private static AttributeValueGroup getAttributeValueGroup(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        
        AttributeValueGroup attributeValueGroups = new AttributeValueGroup();           
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'account_number') {
                attributeValueGroups.accountNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'amount') {
                attributeValueGroups.amount = string.valueOf(svcCatalogReqExtdAttrVal.NumberValue);
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'account_type') {
                attributeValueGroups.accountType = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'payee_name') {
                attributeValueGroups.payeeName = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'payee_account_number') {
                attributeValueGroups.payeeAccountNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'payee_routing_number') {
                attributeValueGroups.payeeRoutingNumber = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'standing_instruction_type') {
                attributeValueGroups.standingInstructionType = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'standing_instruction_id') {
                attributeValueGroups.standingInstructionId = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'currency') {
                attributeValueGroups.currencyValue = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'remarks') {
                attributeValueGroups.remarks = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'start_date') {
                attributeValueGroups.startDate = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'end_date') {
                attributeValueGroups.endDate = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'frequency') {
                attributeValueGroups.frequency = svcCatalogReqExtdAttrVal.TextValue;
            } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'number_of_installments') {
                attributeValueGroups.noOfInstallment = string.valueOf(svcCatalogReqExtdAttrVal.IntegerValue);
            }
        }
        return attributeValueGroups;
    }
    
    //make callout with POST/PUT/PATCH method to mulesoft based on standingInstructionType
    private static HttpResponse makeCallout(String inputRecordId, AttributeValueGroup attributeValueGroups, Map<String, Object> attributes, String requestGuid) {
        String accountType;
        //Get Accounts Source system ID and if null throw exception
        String recordId = FSCUtilityClass.getAccountSourceSystemId(inputRecordId);
        if (recordId == null) {
            throw new IllegalArgumentException('Source System ID is null');
        } 
        //Get Financial account Source system ID and if null throw exception
        String financialAccountSourceSysId = FSCUtilityClass.getFinancialAccSourceSystemId(recordId, attributeValueGroups.accountNumber);
        if (financialAccountSourceSysId == null) {
            throw new IllegalArgumentException('Source System ID is null');
        }
        // Check if Standing Order ID is null for standingInstructionType Modify/Cancel then throw exception
        if (attributeValueGroups.standingInstructionId == null && (attributeValueGroups.standingInstructionType == 'Modify' || attributeValueGroups.standingInstructionType == 'Cancel')){
            throw new IllegalArgumentException('Standing Order ID is null'); 
        }
        // Get the record type of the financial account
        if (attributeValueGroups.accountType == 'Savings Account') {
            accountType = 'SavingsAccount';
        } else if (attributeValueGroups.accountType == 'Checking Account') {
            accountType = 'CurrentAccount';
        }

        String requestParams = '?requestId=' + inputRecordId;
        if (String.isNotBlank(requestGuid)){
            requestParams = requestParams + '&flowRefId=' + requestGuid;
        }
        HttpRequest request = new HttpRequest();
        String endPoint;
        if ((attributeValueGroups.standingInstructionType) == 'Add') {
            request.setMethod('POST');
            endPoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api/' + accountType + '/' + financialAccountSourceSysId + '/Payments/Initiate' + requestParams;
        } else if ((attributeValueGroups.standingInstructionType) == 'Modify') {
            request.setMethod('PUT');
            endPoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api/' + accountType + '/' + financialAccountSourceSysId + '/Payments/' + attributeValueGroups.standingInstructionId + '/Update' + requestParams;
        } else if ((attributeValueGroups.standingInstructionType) == 'Cancel') {
            request.setMethod('PATCH');
            endPoint = 'callout:' + attributes.get(NAMED_CREDENTIAL_KEY) + '/api/' + accountType + '/' + financialAccountSourceSysId + '/Payments/' + attributeValueGroups.standingInstructionId
                + '/Update' + requestParams;
        }
        Map<String, Object> payload = constructPayload(inputRecordId, attributeValueGroups, recordId);
        request.setBody(JSON.serialize(payload, true));
        // set headers
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setEndpoint(endPoint);
        request.setTimeout(TIMEOUT);
        HttpResponse response = new Http().send(request);
        return response;
    }
    
    //Construct the payload with the manage standing instruction details
    private static Map<String, Object> constructPayload (String inputRecordId, AttributeValueGroup attributeValueGroups, String recordId) {
        
        Map<String, Object> payload = new Map<String, Object>();
        Map<String, Object> payments = new Map<String, Object>();
        Map<String, Object> paymentDefinition = new Map<String, Object>();
        Map<String, Object> paymentAmount = new Map<String, Object>();
        Map<String, Object> paymentSchedule = new Map<String, Object>();
        Map<String, Object> payeeReference = new Map<String, Object>();
        Map<String, Object> payeeBankReference = new Map<String, Object>();
        Map<String, Object> payeeAccountReference = new Map<String, Object>();
        
        if ((attributeValueGroups.standingInstructionType)!='Cancel') {
            if (attributeValueGroups.amount != null) {
                paymentAmount.put('Amount', attributeValueGroups.amount);
            }
            if (attributeValueGroups.currencyValue != null) {
                paymentAmount.put('Currency', attributeValueGroups.currencyValue);
            }
            if (attributeValueGroups.frequency != null) {
                paymentSchedule.put('PaymentFrequency', attributeValueGroups.frequency);
            }
            if (attributeValueGroups.noOfInstallment != null) {
                paymentSchedule.put('NumberOfPayments', attributeValueGroups.noOfInstallment); 
            }
            if (attributeValueGroups.startDate != null) {
                paymentSchedule.put('PaymentStartDate', attributeValueGroups.startDate);
            }
            if (attributeValueGroups.endDate != null) {
                paymentSchedule.put('PaymentEndDate', attributeValueGroups.endDate); 
            }
            if (attributeValueGroups.payeeName != null) {
                payeeReference.put('PayeeName', attributeValueGroups.payeeName);
            }
            if (attributeValueGroups.payeeRoutingNumber != null) {
                payeeBankReference.put('RoutingNumber', attributeValueGroups.payeeRoutingNumber);
            }
            if (attributeValueGroups.payeeAccountNumber != null) {
                payeeAccountReference.put('PayeeAccountNumber', attributeValueGroups.payeeAccountNumber);
            }
            paymentDefinition.put('PaymentAmount', paymentAmount);
            payments.put('PaymentType','standing order');
            payments.put('PaymentDefinition', paymentDefinition);
            payments.put('PaymentSchedule', paymentSchedule);
            payments.put('PayeeReference', payeeReference);
            if (attributeValueGroups.remarks != null) {
                payments.put('PaymentPurpose', attributeValueGroups.remarks);
            }
            payments.put('PayeeBankReference', payeeBankReference);
            payments.put('PayeeAccountReference', payeeAccountReference);
            payload.put('Payments', payments);
        }
        else if ((attributeValueGroups.standingInstructionType)=='Cancel') {
            if (attributeValueGroups.remarks != null) {
                payload.put('PaymentCancelPurpose', attributeValueGroups.remarks);
            }
        }
        return payload;
    }
    
    global static List<industriesintegrationfwk.ApexProviderAttr> getProviderAttributes() {
        List<industriesintegrationfwk.ApexProviderAttr> defaults = new List<industriesintegrationfwk.ApexProviderAttr>();
        defaults.add(NAMED_CRED_ATTR);
        defaults.add(PERSON_ACCOUNT_URL_PATH_ATTR);
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
        } catch (Exception e) {
            Map<String, Object> responseMap = new Map<String, Object>();
            responseMap.put('response', responsebody);
            return responseMap;
        }
    }
    
}