/*************************
* @Class Name:- FSCWlthManageBeneficiariesHelperFunction
* @Description:- Helper class for Manage Beneficiaries FSC Wealth service process
**************************/
global with sharing class FSCWlthManageBeneficiariesHelperFunction implements System.Callable {
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = (Map<String, Object>)args.get('input');
        Map<String, Object> outputMap = (Map<String, Object>)args.get('output');
        
        if (action == 'callCreateCaseApi') {
            // retrieve the attributes from the request payload
            String svcCatalogItemDefApiName = String.valueOf(inputMap.get('svcCatalogItemDefApiName'));
            String caseSubject = String.valueOf(inputMap.get('caseSubject'));
            String accountId = String.valueOf(inputMap.get('accountId'));
            String addContingentBeneficiary = String.valueOf(inputMap.get('addContingentBeneficiary'));
            
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
            
            if (String.isNotBlank(addContingentBeneficiary) == true) {
                ConnectApi.GenericObject addContingentBeneficiaryObj = new ConnectApi.GenericObject();
                addContingentBeneficiaryObj.value = addContingentBeneficiary;
                input.attributes.put('has_contingent_beneficiaries', addContingentBeneficiaryObj);
            }
            //Set Attributes for Adding Primary Beneficiaries 
            Object primaryBeneficiaryToAddListObj = inputMap.get('primaryBeneficiaries');
            String primaryBeneficiaryToAddListStr;
            if (primaryBeneficiaryToAddListObj instanceof List<Object>) {
                primaryBeneficiaryToAddListStr = JSON.serialize(primaryBeneficiaryToAddListObj);
            } else {
                primaryBeneficiaryToAddListStr = '['+ JSON.serialize(primaryBeneficiaryToAddListObj) +']';
            }
            ConnectApi.GenericObject primaryBeneficiaryToAddList = new ConnectApi.GenericObject();
            List<Object> untypedListAddPrimary = (List<Object>) JSON.deserializeUntyped(primaryBeneficiaryToAddListStr);
            List<Map<String, Object>> primaryBeneficiaryToAddDetails = new List<Map<String, Object>>();
            Map<String, Object> beneficiaryToAdd;
            for (Object jsonObj :untypedListAddPrimary) {
                Map<String, Object> beneficiaryToAddJsonObj = (Map<String, Object>)jsonObj;
                beneficiaryToAdd = new Map<String, Object>();
                if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('BeneficiaryName'))) == true) {
                    beneficiaryToAdd.put('beneficiary_name', String.valueOf(beneficiaryToAddJsonObj.get('BeneficiaryName')));
                }
                if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('BeneficiaryType'))) == true) {
                    beneficiaryToAdd.put('beneficiary_type', String.valueOf(beneficiaryToAddJsonObj.get('BeneficiaryType')));
                } 
                if (String.valueOf(beneficiaryToAddJsonObj.get('BeneficiaryType')) == 'Individual') {
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('RelationshipType'))) == true) {
                        beneficiaryToAdd.put('beneficiary_relationship_type', String.valueOf(beneficiaryToAddJsonObj.get('RelationshipType')));
                    }
                    beneficiaryToAdd.put('beneficiary_birth_date_incorporation', String.valueOf(beneficiaryToAddJsonObj.get('Birth Date')));
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('SSN'))) == true) {
                        beneficiaryToAdd.put('beneficiary_ssn', 'XXXX-'+String.valueOf(beneficiaryToAddJsonObj.get('FullSSN')).right(4));
                    } else {
                        beneficiaryToAdd.put('beneficiary_ssn', String.valueOf(beneficiaryToAddJsonObj.get('FullSSN')));
                    }
                }
                if (String.valueOf(beneficiaryToAddJsonObj.get('BeneficiaryType')) == 'Institution') {
                    if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('InstitutionType'))) == true) {
                        beneficiaryToAdd.put('beneficiary_relationship_type', String.valueOf(beneficiaryToAddJsonObj.get('InstitutionType')));
                    }
                    beneficiaryToAdd.put('beneficiary_birth_date_incorporation', String.valueOf(beneficiaryToAddJsonObj.get('Incorporation Date')));
                }
                if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('NewShare'))) == true) {
                    beneficiaryToAdd.put('beneficiary_share_percentage', Double.valueOf(beneficiaryToAddJsonObj.get('NewShare')));
                } 
                if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('perStirpes'))) == true) {
                    beneficiaryToAdd.put('beneficiary_per_stirpes', (String.valueOf(beneficiaryToAddJsonObj.get('perStirpes')) == 'true')? 'Yes' : 'No');
                } else {
                    beneficiaryToAdd.put('beneficiary_per_stirpes', 'No');
                }
                if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('Mobile Number'))) == true) {
                    beneficiaryToAdd.put('beneficiary_mobile_number', String.valueOf(beneficiaryToAddJsonObj.get('Mobile Number')));
                }
                beneficiaryToAdd.put('beneficiary_email', String.valueOf(beneficiaryToAddJsonObj.get('Email')));
                if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('AddressLine1'))) == true) {
                    beneficiaryToAdd.put('beneficiary_address_line_1', String.valueOf(beneficiaryToAddJsonObj.get('AddressLine1')));
                }
                beneficiaryToAdd.put('beneficiary_address_line_2', String.valueOf(beneficiaryToAddJsonObj.get('AddressLine2')));
                if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('City'))) == true) {
                    beneficiaryToAdd.put('beneficiary_city', String.valueOf(beneficiaryToAddJsonObj.get('City')));
                }
                if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('State'))) == true) {
                    beneficiaryToAdd.put('beneficiary_state', String.valueOf(beneficiaryToAddJsonObj.get('State')));
                }
                if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('CountryCode'))) == true) {
                    beneficiaryToAdd.put('beneficiary_country', String.valueOf(beneficiaryToAddJsonObj.get('CountryCode')));
                }
                if (String.isNotBlank(String.valueOf(beneficiaryToAddJsonObj.get('PostalCode'))) == true) {
                    beneficiaryToAdd.put('beneficiary_postal_code', String.valueOf(beneficiaryToAddJsonObj.get('PostalCode')));
                }                   
                primaryBeneficiaryToAddDetails.add(beneficiaryToAdd);
            }
            if (!primaryBeneficiaryToAddDetails.isEmpty()) {
                primaryBeneficiaryToAddList.value = primaryBeneficiaryToAddDetails;
                input.attributes.put('primary_beneficiaries', primaryBeneficiaryToAddList);
            }
            
            //Set Attributes for Adding Contingent Beneficiaries 
            if (addContingentBeneficiary == 'Yes') {
                Object contingentBeneficiaryToAddListObj = inputMap.get('contingentBeneficiaries');
                String contingentBeneficiaryToAddListStr;
                if (contingentBeneficiaryToAddListObj instanceof List<Object>) {
                    contingentBeneficiaryToAddListStr = JSON.serialize(contingentBeneficiaryToAddListObj);
                } else {
                    contingentBeneficiaryToAddListStr = '['+ JSON.serialize(contingentBeneficiaryToAddListObj) +']';
                }
                ConnectApi.GenericObject contingentBeneficiaryToAddList = new ConnectApi.GenericObject();
                List<Object> untypedListAddContingent = (List<Object>) JSON.deserializeUntyped(contingentBeneficiaryToAddListStr);
                List<Map<String, Object>> contingentBeneficiaryToAddDetails = new List<Map<String, Object>>();
                Map<String, Object> contingentToAdd;
                for (Object jsonObj :untypedListAddContingent) {
                    Map<String, Object> contingentToAddJsonObj = (Map<String, Object>)jsonObj;
                    contingentToAdd = new Map<String, Object>();
                    if (String.isNotBlank(String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryName'))) == true) {
                        contingentToAdd.put('contingent_beneficiary_name', String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryName')));
                    }
                    if (String.isNotBlank(String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryType'))) == true) {
                        contingentToAdd.put('contingent_beneficiary_type', String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryType')));
                    } 
                    if (String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryType')) == 'Individual') {
                        if (String.isNotBlank(String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryRelationshipType'))) == true) {
                            contingentToAdd.put('contingent_relationship_type', String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryRelationshipType')));
                        }
                        contingentToAdd.put('contingent_birth_date_incorporation', String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryBirthDate')));
                        if (String.isNotBlank(String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiarySSN'))) == true) {
                            contingentToAdd.put('contingent_ssn', 'XXXX-'+String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiarySSN')).right(4));
                        } else{
                            contingentToAdd.put('contingent_ssn', String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiarySSN')));
                        }
                    }
                    if (String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryType')) == 'Institution') {
                        if (String.isNotBlank(String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryInstitutionType'))) == true) {
                            contingentToAdd.put('contingent_relationship_type', String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryInstitutionType')));
                        }
                        contingentToAdd.put('contingent_birth_date_incorporation', String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryDateOfIncorporation')));
                    }
                    if (String.isNotBlank(String.valueOf(contingentToAddJsonObj.get('NewShare'))) == true) {
                        contingentToAdd.put('contingent_share_percentage', Double.valueOf(contingentToAddJsonObj.get('NewShare')));
                    } 
                    if (String.isNotBlank(String.valueOf(contingentToAddJsonObj.get('perStirpes'))) == true) {
                        contingentToAdd.put('contingent_per_stirpes', (String.valueOf(contingentToAddJsonObj.get('perStirpes')) == 'true')? 'Yes' : 'No');
                    } else {
                        contingentToAdd.put('contingent_per_stirpes', 'No');
                    }
                    if (String.isNotBlank(String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryMobile'))) == true) {
                        contingentToAdd.put('contingent_mobile_number', String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryMobile')));
                    }
                    contingentToAdd.put('contingent_email', String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryEmail')));
                    if (String.isNotBlank(String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryAddressLine1'))) == true) {
                        contingentToAdd.put('contingent_address_line_1', String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryAddressLine1')));
                    }
                    contingentToAdd.put('contingent_address_line_2', String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryAddressLine2')));
                    if (String.isNotBlank(String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryCity'))) == true) {
                        contingentToAdd.put('contingent_city', String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryCity')));
                    }
                    if (String.isNotBlank(String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryState'))) == true) {
                        contingentToAdd.put('contingent_state', String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryState')));
                    }
                    if (String.isNotBlank(String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryCountry'))) == true) {
                        contingentToAdd.put('contingent_country', String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryCountry')));
                    }
                    if (String.isNotBlank(String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryPostalCode'))) == true) {
                        contingentToAdd.put('contingent_postal_code', String.valueOf(contingentToAddJsonObj.get('ContingentBeneficiaryPostalCode')));
                    }                   
                    contingentBeneficiaryToAddDetails.add(contingentToAdd);   
                }
                if (!contingentBeneficiaryToAddDetails.isEmpty()) {
                    contingentBeneficiaryToAddList.value = contingentBeneficiaryToAddDetails;
                    input.attributes.put('contingent_beneficiaries', contingentBeneficiaryToAddList);
                }
            }
            
            // Set Attributes for Adding Financial Accounts  
            Object financialAccountsToAddListObj = inputMap.get('financialAccounts');
            String financialAccountsToAddListStr;
            if (financialAccountsToAddListObj instanceof List<Object>) {
                financialAccountsToAddListStr = JSON.serialize(financialAccountsToAddListObj);
            } else {
                financialAccountsToAddListStr = '['+ JSON.serialize(financialAccountsToAddListObj) +']';
            }
            ConnectApi.GenericObject financialAccountsToAddList = new ConnectApi.GenericObject();
            List<Object> untypedListAddFinancialAccounts = (List<Object>) JSON.deserializeUntyped(financialAccountsToAddListStr);
            List<Map<String, Object>> financialAccountsToAddDetails = new List<Map<String, Object>>();
            Map<String, Object> financialAccountsToAdd;
            for (Object jsonObj :untypedListAddFinancialAccounts) {
                Map<String, Object> financialAccountsToAddJsonObj = (Map<String, Object>)jsonObj;
                financialAccountsToAdd = new Map<String, Object>();
                if (String.isNotBlank(String.valueOf(financialAccountsToAddJsonObj.get('Name'))) == true) {
                    financialAccountsToAdd.put('account_name', String.valueOf(financialAccountsToAddJsonObj.get('Name')));
                }
                if (String.isNotBlank(String.valueOf(financialAccountsToAddJsonObj.get('AccountNumber'))) == true) {
                    financialAccountsToAdd.put('account_number', String.valueOf(financialAccountsToAddJsonObj.get('AccountNumber')));
                } 
                if (String.isNotBlank(String.valueOf(financialAccountsToAddJsonObj.get('OwnershipType'))) == true) {
                    financialAccountsToAdd.put('account_ownership_type', String.valueOf(financialAccountsToAddJsonObj.get('OwnershipType')));
                } 
                financialAccountsToAddDetails.add(financialAccountsToAdd);   
            }
            if (!financialAccountsToAddDetails.isEmpty()) {
                financialAccountsToAddList.value = financialAccountsToAddDetails;
                input.attributes.put('financial_accounts', financialAccountsToAddList);
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