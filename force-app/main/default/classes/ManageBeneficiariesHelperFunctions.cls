/*************************
* @Class Name:- ManageBeneficiariesHelperFunctions
* @Description:- Helper class for Manage Beneficiaries FSC service
**************************/
global with sharing class ManageBeneficiariesHelperFunctions implements System.Callable {
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = (Map<String, Object>)args.get('input');
        Map<String, Object> outputMap = (Map<String, Object>)args.get('output');
        
        if (action == 'callCreateCaseApi') {
            // retrieve the attributes from the request payload
            String accountNumber  = String.valueOf(inputMap.get('accountNumber'));
            String accountType  = String.valueOf(inputMap.get('accountType'));
            String financialAccountId = String.valueOf(inputMap.get('financialAccountId'));
            String financialAccountName = String.valueOf(inputMap.get('financialAccountName'));
            String svcCatalogItemDefApiName = String.valueOf(inputMap.get('svcCatalogItemDefApiName'));
            String caseSubject = String.valueOf(inputMap.get('caseSubject'));
            String accountId = String.valueOf(inputMap.get('accountId'));
            String actionType = String.valueOf(inputMap.get('action'));
           
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
            if (String.isNotBlank(financialAccountName) == true) {
                ConnectApi.GenericObject financialAccountNameObj = new ConnectApi.GenericObject();
                financialAccountNameObj.value = financialAccountName;
                input.attributes.put('account_name', financialAccountNameObj);
            }
            if (String.isNotBlank(actionType) == true) {
                ConnectApi.GenericObject actionTypeObj = new ConnectApi.GenericObject();
                actionTypeObj.value = actionType;
                input.attributes.put('action_type', actionTypeObj);
            }
            
            //Set Attributes for Delete Beneficiary 
            if (inputMap.get('action') == 'Delete') {
                Object beneficiaryToDeleteListObj = inputMap.get('selectedBeneficiariesToDelete');
                String beneficiaryToDeleteListStr;
                if (beneficiaryToDeleteListObj instanceof List<Object>) {
                    beneficiaryToDeleteListStr = JSON.serialize(beneficiaryToDeleteListObj);
                } else {
                    beneficiaryToDeleteListStr = '['+ JSON.serialize(beneficiaryToDeleteListObj) +']';
                }
                ConnectApi.GenericObject beneficiaryToDeleteList = new ConnectApi.GenericObject();
                List<Object> untypedList = (List<Object>) JSON.deserializeUntyped(beneficiaryToDeleteListStr);
                List<Map<String, String>> beneficiaryToDeleteDetails = new List<Map<String, String>>();
                Map<String, String> beneficiaryToDelete;
                for (Object jsonObj :untypedList) {
                    Map<String, Object> beneficiaryToDeleteJsonObj = (Map<String, Object>)jsonObj;
                    beneficiaryToDelete = new Map<String, String>();
                    if (String.isNotBlank(String.valueOf(beneficiaryToDeleteJsonObj.get('BeneficiaryName'))) == true) {
                        beneficiaryToDelete.put('beneficiary_name_to_delete', String.valueOf(beneficiaryToDeleteJsonObj.get('BeneficiaryName')));
                    }
                        beneficiaryToDelete.put('mobile', String.valueOf(beneficiaryToDeleteJsonObj.get('Mobile')));
                    beneficiaryToDeleteDetails.add(beneficiaryToDelete);
                }
                if (!beneficiaryToDeleteDetails.isEmpty()) {
                    beneficiaryToDeleteList.value = beneficiaryToDeleteDetails;
                    input.attributes.put('beneficiaries_to_delete', beneficiaryToDeleteList);
                }
            }
            
            //Set Attributes for Add Beneficiary 
            if (inputMap.get('action') == 'Add') {
                Object beneficiaryToAddListObj = inputMap.get('selectedBeneficiariesToAdd');
                String beneficiaryToAddListStr;
                if (beneficiaryToAddListObj instanceof List<Object>) {
                    beneficiaryToAddListStr = JSON.serialize(beneficiaryToAddListObj);
                } else {
                    beneficiaryToAddListStr = '['+ JSON.serialize(beneficiaryToAddListObj) +']';
                }
                ConnectApi.GenericObject beneficiaryToAddList = new ConnectApi.GenericObject();
                List<Object> untypedListAdd = (List<Object>) JSON.deserializeUntyped(beneficiaryToAddListStr);
                List<Map<String, String>> beneficiaryToAddDetails = new List<Map<String, String>>();
                Map<String, String> beneficiaryToAdd;
                for (Object jsonObj :untypedListAdd) {
                    Map<String, Object> beneficiaryToAddJsonObj = (Map<String, Object>)jsonObj;
                    beneficiaryToAdd = new Map<String, String>();
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('BeneficiaryName'))) == true) {
                        beneficiaryToAdd.put('beneficiary_name', String.valueOf(beneficiaryToAddJsonObj.get('BeneficiaryName')));
                    }
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('BeneficiaryBirthDate'))) == true) {
                        beneficiaryToAdd.put('beneficiary_birth_date', String.valueOf(beneficiaryToAddJsonObj.get('BeneficiaryBirthDate')));
                    }
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('RelationshipWithAccountHolder'))) == true) {
                        beneficiaryToAdd.put('beneficiary_relationship', String.valueOf(beneficiaryToAddJsonObj.get('RelationshipWithAccountHolder')));
                    }
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('BeneficiaryMobileNumber'))) == true) {
                        beneficiaryToAdd.put('beneficiary_mobile', String.valueOf(beneficiaryToAddJsonObj.get('BeneficiaryMobileNumber')));
                    }
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('BeneficiaryEmail'))) == true) {
                        beneficiaryToAdd.put('beneficiary_email', String.valueOf(beneficiaryToAddJsonObj.get('BeneficiaryEmail')));
                    }
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('BeneficiarySSN'))) == true) {
                        beneficiaryToAdd.put('beneficiary_ssn', String.valueOf(beneficiaryToAddJsonObj.get('BeneficiarySSN')));
                    }
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('AddressLine1'))) == true) {
                        beneficiaryToAdd.put('address_line_1', String.valueOf(beneficiaryToAddJsonObj.get('AddressLine1')));
                    }
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('AddressLine2'))) == true) {
                        beneficiaryToAdd.put('address_line_2', String.valueOf(beneficiaryToAddJsonObj.get('AddressLine2')));
                    }
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('City'))) == true) {
                        beneficiaryToAdd.put('city', String.valueOf(beneficiaryToAddJsonObj.get('City')));
                    }
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('State'))) == true) {
                        beneficiaryToAdd.put('state', String.valueOf(beneficiaryToAddJsonObj.get('State')));
                    }
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('Country'))) == true) {
                        beneficiaryToAdd.put('country', String.valueOf(beneficiaryToAddJsonObj.get('Country')));
                    }
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('PostalCode'))) == true) {
                        beneficiaryToAdd.put('postal_code', String.valueOf(beneficiaryToAddJsonObj.get('PostalCode')));
                    }
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('SelectBeneficiaryMinorStatus'))) == true) {
                        beneficiaryToAdd.put('is_beneficiary_minor', String.valueOf(beneficiaryToAddJsonObj.get('SelectBeneficiaryMinorStatus')));
                    }
                    if (String.valueOf(beneficiaryToAddJsonObj.get('SelectBeneficiaryMinorStatus')) == 'Yes') {
                        if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('GuardianName'))) == true) {
                            beneficiaryToAdd.put('guardian_name', String.valueOf(beneficiaryToAddJsonObj.get('GuardianName')));
                        }
                        if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('GuardianMobileNumber'))) == true) {
                            beneficiaryToAdd.put('guardian_mobile', String.valueOf(beneficiaryToAddJsonObj.get('GuardianMobileNumber')));
                        }
                        if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('RelationshipWithBeneficiary'))) == true) {
                            beneficiaryToAdd.put('guardian_relationship', String.valueOf(beneficiaryToAddJsonObj.get('RelationshipWithBeneficiary')));
                        }
                        if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('GuardianSSN'))) == true) {
                            beneficiaryToAdd.put('guardian_ssn', String.valueOf(beneficiaryToAddJsonObj.get('GuardianSSN')));
                        }
                        if (String.valueOf(beneficiaryToAddJsonObj.get('IsGuardianAddressSameAsBeneficiary')) == 'Yes') {
                            if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('AddressLine1'))) == true) {
                                beneficiaryToAdd.put('guardian_address_line_1', String.valueOf(beneficiaryToAddJsonObj.get('AddressLine1')));
                            }
                            if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('AddressLine2'))) == true) {
                                beneficiaryToAdd.put('guardian_address_line_2', String.valueOf(beneficiaryToAddJsonObj.get('AddressLine2')));
                            }
                            if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('City'))) == true) {
                                beneficiaryToAdd.put('guardian_city', String.valueOf(beneficiaryToAddJsonObj.get('City')));
                            }
                            if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('State'))) == true) {
                                beneficiaryToAdd.put('guardian_state', String.valueOf(beneficiaryToAddJsonObj.get('State')));
                            }
                            if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('Country'))) == true) {
                                beneficiaryToAdd.put('guardian_country', String.valueOf(beneficiaryToAddJsonObj.get('Country')));
                            }
                            if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('PostalCode'))) == true) {
                                beneficiaryToAdd.put('guardian_postal_code', String.valueOf(beneficiaryToAddJsonObj.get('PostalCode')));
                            }
                        } else {
                            if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('GuardianAddressLine1'))) == true) {
                                beneficiaryToAdd.put('guardian_address_line_1', String.valueOf(beneficiaryToAddJsonObj.get('GuardianAddressLine1')));
                            }
                            if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('GuardianAddressLine2'))) == true) {
                                beneficiaryToAdd.put('guardian_address_line_2', String.valueOf(beneficiaryToAddJsonObj.get('GuardianAddressLine2')));
                            }
                            if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('GuardianCity'))) == true) {
                                beneficiaryToAdd.put('guardian_city', String.valueOf(beneficiaryToAddJsonObj.get('GuardianCity')));
                            }
                            if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('GuardianState'))) == true) {
                                beneficiaryToAdd.put('guardian_state', String.valueOf(beneficiaryToAddJsonObj.get('GuardianState')));
                            }
                            if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('GuardianCountry'))) == true) {
                                beneficiaryToAdd.put('guardian_country', String.valueOf(beneficiaryToAddJsonObj.get('GuardianCountry')));
                            }
                            if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('GuardianPostalCode'))) == true) {
                                beneficiaryToAdd.put('guardian_postal_code', String.valueOf(beneficiaryToAddJsonObj.get('GuardianPostalCode')));
                            }
                        }
                    }
                    beneficiaryToAddDetails.add(beneficiaryToAdd);
                }
                if (!beneficiaryToAddDetails.isEmpty()) {
                    beneficiaryToAddList.value = beneficiaryToAddDetails;
                    input.attributes.put('beneficiaries_to_add', beneficiaryToAddList);
                }
            }
            
            // Invoke API
            Map<String, String> responseMap = new Map<String, String>();
            try {
                if (!Test.isRunningTest()) {
                    ConnectApi.ServiceProcessRepresentation output = ConnectApi.IServiceProcessConnectFamily.createCaseServiceProcess(input);
                    responseMap.put('caseId', output.caseId);
                    responseMap.put('caseNumber', output.caseNumber);
                    responseMap.put('svcCatalogRequestId', output.svcCatalogRequestId);
                }
                outputMap.put('apiResponse', responseMap);
                return outputMap;
            } catch (Exception ex) {
                throw new CalloutException(ex);
            }
        }
        return null;
    }
}