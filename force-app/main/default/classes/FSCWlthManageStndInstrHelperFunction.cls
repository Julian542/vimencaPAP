/*************************
* @Class Name:- FSCWlthManageStndInstrHelperFunction
* @Description:- Helper class for Manage Standing Instruction FSC Wealth service process
**************************/
global with sharing class FSCWlthManageStndInstrHelperFunction implements System.Callable {
    
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
            String standingInstructionType = String.valueOf(inputMap.get('standingInstructionType')); 
            Boolean needFileUpload = false;

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
                input.attributes.put('account_name', financialAccNameObj);
            }
            if (String.isNotBlank(financialAccNumber) == true) {
                ConnectApi.GenericObject financialAccNumberObj = new ConnectApi.GenericObject();
                financialAccNumberObj.value = financialAccNumber;
                input.attributes.put('account_number', financialAccNumberObj);
            }
            if (String.isNotBlank(financialAccId) == true) {
                ConnectApi.GenericObject financialAccIdObj = new ConnectApi.GenericObject();
                financialAccIdObj.value = financialAccId;
                input.attributes.put('account_id', financialAccIdObj);
            }
            if (String.isNotBlank(standingInstructionType) == true) {
                ConnectApi.GenericObject standingInstructionTypeObj = new ConnectApi.GenericObject();
                standingInstructionTypeObj.value = standingInstructionType;
                input.attributes.put('standing_instruction_type', standingInstructionTypeObj);
            }
            
            if (standingInstructionType == 'Add') {
                // Set Attributes for Adding standing instructions  
                Object addStandingInstructionsObj = inputMap.get('addStandingInstructions');
                String addStandingInstructionsListStr;
                Map<String, String> fileIdAccNumMap = new Map<String, String>();
                if (addStandingInstructionsObj instanceof List<Object>) {
                    addStandingInstructionsListStr = JSON.serialize(addStandingInstructionsObj);
                } else {
                    addStandingInstructionsListStr = '['+ JSON.serialize(addStandingInstructionsObj) +']';
                }
                ConnectApi.GenericObject addStandingInstructionsList = new ConnectApi.GenericObject();
                List<Object> untypedListAddStandingInstructions = (List<Object>) JSON.deserializeUntyped(addStandingInstructionsListStr);
                List<Map<String, Object>> standingInstructionsToAddDetails = new List<Map<String, Object>>();
                Map<String, Object> standingInstructionsToAdd;
                for (Object jsonObj :untypedListAddStandingInstructions) {
                    Map<String, Object> standingInstructionsToAddJsonObj = (Map<String, Object>)jsonObj;
                    standingInstructionsToAdd = new Map<String, Object>();
                    if (String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('Mode'))) == true) {
                        standingInstructionsToAdd.put('mode', String.valueOf(standingInstructionsToAddJsonObj.get('Mode')));
                    }
                    if (String.valueOf(standingInstructionsToAddJsonObj.get('Mode')) == 'Wire Transfer' || String.valueOf(standingInstructionsToAddJsonObj.get('Mode')) == 'EFT') {
                        if (String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('BankName'))) == true) {
                            standingInstructionsToAdd.put('bank_name', String.valueOf(standingInstructionsToAddJsonObj.get('BankName')));
                        }
                        if (String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('AccountNumber'))) == true) {
                            standingInstructionsToAdd.put('payee_account_number', String.valueOf(standingInstructionsToAddJsonObj.get('AccountNumber')));
                        }
                        if (String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('RoutingNumber'))) == true) {
                            standingInstructionsToAdd.put('routing_number', String.valueOf(standingInstructionsToAddJsonObj.get('RoutingNumber')));
                        }  
                    }
                    
                    if (String.valueOf(standingInstructionsToAddJsonObj.get('Mode')) == 'Journal') {
                        if (String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('AccountNumber'))) == true) {
                            standingInstructionsToAdd.put('payee_account_number', String.valueOf(standingInstructionsToAddJsonObj.get('AccountNumber')));
                        }
                    }
                    if (String.valueOf(standingInstructionsToAddJsonObj.get('Mode')) == 'Check' || String.valueOf(standingInstructionsToAddJsonObj.get('Mode')) == 'Wire Transfer') {
                        if (String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('PayeeAddress'))) == true) {
                            standingInstructionsToAdd.put('payee_address', String.valueOf(standingInstructionsToAddJsonObj.get('PayeeAddress')));
                        }
                        if (String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('PayeeCity'))) == true) {
                            standingInstructionsToAdd.put('city', String.valueOf(standingInstructionsToAddJsonObj.get('PayeeCity')));
                        }
                        if (String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('PayeeState'))) == true) {
                            standingInstructionsToAdd.put('state', String.valueOf(standingInstructionsToAddJsonObj.get('PayeeState')));
                        }
                        if (String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('PayeeCountry'))) == true) {
                            standingInstructionsToAdd.put('country', String.valueOf(standingInstructionsToAddJsonObj.get('PayeeCountry')));
                        }
                        if (String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('PayeeZipcode'))) == true) {
                            standingInstructionsToAdd.put('zip_code', String.valueOf(standingInstructionsToAddJsonObj.get('PayeeZipcode')));
                        }
                    }
                    if (String.valueOf(standingInstructionsToAddJsonObj.get('Mode')) == 'Check') {
                        if (String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('Prefix'))) == true) {
                            standingInstructionsToAdd.put('prefix', String.valueOf(standingInstructionsToAddJsonObj.get('Prefix')));
                        }
                        standingInstructionsToAdd.put('memo', String.valueOf(standingInstructionsToAddJsonObj.get('Memo')));
                        standingInstructionsToAdd.put('check_stub_information', String.valueOf(standingInstructionsToAddJsonObj.get('CheckStubInformation')));
                    }
                    if (String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('PayeeName'))) == true) {
                        standingInstructionsToAdd.put('payee_name', String.valueOf(standingInstructionsToAddJsonObj.get('PayeeName')));
                    }
                    if (String.valueOf(standingInstructionsToAddJsonObj.get('Mode')) != 'Journal' && String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('Currency'))) == true) {
                        standingInstructionsToAdd.put('currency_code', String.valueOf(standingInstructionsToAddJsonObj.get('Currency')));
                    }
                    if (String.valueOf(standingInstructionsToAddJsonObj.get('Mode')) != 'Journal' && String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('TransferAmount'))) == true) {
                        standingInstructionsToAdd.put('max_amount', Double.valueOf(standingInstructionsToAddJsonObj.get('TransferAmount')));
                    }
                    if (String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('TransferType'))) == true) {
                        standingInstructionsToAdd.put('transfer_type', String.valueOf(standingInstructionsToAddJsonObj.get('TransferType')));
                    }
                    if (String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('Details'))) == true) {
                        standingInstructionsToAdd.put('details', String.valueOf(standingInstructionsToAddJsonObj.get('Details')));
                    }
                    if (String.isNotBlank(String.valueOf(standingInstructionsToAddJsonObj.get('AccountType'))) == true) {
                        standingInstructionsToAdd.put('eft_account_type', String.valueOf(standingInstructionsToAddJsonObj.get('AccountType')));
                    }
                    standingInstructionsToAddDetails.add(standingInstructionsToAdd); 
                    // If mode  EFT and Transfer type 1st party then Set needFileUpload to true
                    // Create fileIdAccNumMap Map<String, String> with FileId as key and Account Number as value
                    If (String.valueOf(standingInstructionsToAddJsonObj.get('Mode')) == 'EFT' && String.valueOf(standingInstructionsToAddJsonObj.get('TransferType')) == '1st Party Transfer') {
                        fileIdAccNumMap.put(String.valueOf(standingInstructionsToAddJsonObj.get('Files')).split('=')[1].split(',')[0], String.valueOf(standingInstructionsToAddJsonObj.get('AccountNumber')));
                        needFileUpload = true;
                    }
                }
                if (!standingInstructionsToAddDetails.isEmpty()) {
                    addStandingInstructionsList.value = standingInstructionsToAddDetails;
                    input.attributes.put('add_standing_instructions', addStandingInstructionsList);
                }  
                // If needFileUpload is true then upload the documents
                If (needFileUpload == true) {
                    // retrieve the documentInfo by the customer
                    List<Object> uploadedDocumentInfoList = (List<Object>)inputMap.get('documentInfo');
                    Set<ConnectApi.DocumentInfoAttributes> docInfoSet = new Set<ConnectApi.DocumentInfoAttributes>();
                    if (uploadedDocumentInfoList != null && !uploadedDocumentInfoList.isEmpty()) {
                        for (Object uploadedDocInfoMap : uploadedDocumentInfoList) {
                            ConnectApi.DocumentInfoAttributes doc = new ConnectApi.DocumentInfoAttributes();
                            Map<String, Object> uploadMap = (Map<String, Object>)uploadedDocInfoMap;
                            doc.id = (String) uploadMap.get('id');
                            //get Account Number from fileIdAccNumMap using FileId  and rename the file as Account Number - File Name
                            doc.name = fileIdAccNumMap.get(doc.id) +' - ' + (String) uploadMap.get('name');
                            doc.typeId = (String) uploadMap.get('typeId');
                            docInfoSet.add(doc);
                        }
                    }
                    for (ConnectApi.DocumentInfoAttributes docInfoAttr : docInfoSet) {
                        input.documentInfo.add(docInfoAttr);
                    }
                }
            }
            
            if (standingInstructionType == 'Cancel') {
                // Set Attributes for Delete standing instructions  
                Object deleteStandingInstructionsObj = inputMap.get('cancelStandingInstructions');
                String deleteStandingInstructionsListStr;
                if (deleteStandingInstructionsObj instanceof List<Object>) {
                    deleteStandingInstructionsListStr = JSON.serialize(deleteStandingInstructionsObj);
                } else {
                    deleteStandingInstructionsListStr = '['+ JSON.serialize(deleteStandingInstructionsObj) +']';
                }
                ConnectApi.GenericObject deleteStandingInstructionsList = new ConnectApi.GenericObject();
                List<Object> untypedListDeleteStandingInstructions = (List<Object>) JSON.deserializeUntyped(deleteStandingInstructionsListStr);
                List<Map<String, Object>> standingInstructionsToDeleteDetails = new List<Map<String, Object>>();
                Map<String, Object> standingInstructionsToDelete;
                for (Object jsonObj :untypedListDeleteStandingInstructions) {
                    Map<String, Object> standingInstructionsToDeleteJsonObj = (Map<String, Object>)jsonObj;
                    standingInstructionsToDelete = new Map<String, Object>();
                    if (String.isNotBlank(String.valueOf(standingInstructionsToDeleteJsonObj.get('StandingOrderId'))) == true) {
                        standingInstructionsToDelete.put('standing_instruction_id', String.valueOf(standingInstructionsToDeleteJsonObj.get('StandingOrderId')));
                    }
                    if (String.isNotBlank(String.valueOf(standingInstructionsToDeleteJsonObj.get('PayeeName'))) == true) {
                        standingInstructionsToDelete.put('cancel_payee_name', String.valueOf(standingInstructionsToDeleteJsonObj.get('PayeeName')));
                    }
                    if (String.isNotBlank(String.valueOf(standingInstructionsToDeleteJsonObj.get('PaymentMode'))) == true) {
                        standingInstructionsToDelete.put('cancel_mode', String.valueOf(standingInstructionsToDeleteJsonObj.get('PaymentMode')));
                    }
                    if (String.isNotBlank(String.valueOf(standingInstructionsToDeleteJsonObj.get('Bank Account Number'))) == true) {
                        standingInstructionsToDelete.put('cancel_account_number', String.valueOf(standingInstructionsToDeleteJsonObj.get('Bank Account Number')));
                    }
                    standingInstructionsToDeleteDetails.add(standingInstructionsToDelete);   
                }
                if (!standingInstructionsToDeleteDetails.isEmpty()) {
                    deleteStandingInstructionsList.value = standingInstructionsToDeleteDetails;
                    input.attributes.put('cancel_standing_instructions', deleteStandingInstructionsList);
                }  
            }
            
            //set has_file_upload svc attribute value
            if (needFileUpload == true) {
                ConnectApi.GenericObject hasFileUploadTypeObj = new ConnectApi.GenericObject();
                hasFileUploadTypeObj.value = 'Yes';
                input.attributes.put('has_file_upload', hasFileUploadTypeObj);
            } else {
                ConnectApi.GenericObject hasFileUploadTypeObj = new ConnectApi.GenericObject();
                hasFileUploadTypeObj.value = 'No';
                input.attributes.put('has_file_upload', hasFileUploadTypeObj);
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