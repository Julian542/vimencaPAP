/*************************
* @Class Name:- FSCWlthManageBeneficiariesFlowHelper
* @Description:- Manage Wealth Beneficiaries process case creation email flow helper class
**************************/
public with sharing class FSCWlthManageBeneficiariesFlowHelper {
    
    public class FlowInputs {
        @InvocableVariable(label='Service Catalog Request Id' required=true)
        public String inputRecordId;
    }
    
    //Invocable method used in the flow to get the beneficiaries list
    @InvocableMethod(label='Get Wealth Beneficiaries' description='Process all extended attribute records')
    public static List<String> getBeneficiariesList(List<FlowInputs> flowInput) {
        String svcRecordId = flowInput[0].inputRecordId;
        String hasContingentBenf;
        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, GroupNumber, TextValue, NumberValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :svcRecordId WITH SECURITY_ENFORCED ORDER BY GroupNumber ASC NULLS FIRST];
        map<String, String> financialAccountDetailsObj = new map<String, String>();
        List<map<String, String>> financialAccountDetails = new List<map<String, String>>();
        map<String, String> primBeneficiaryToAddDetailsObj = new map<String, String>();
        List<map<String, String>> primaryBeneficiariesDetails = new List<map<String, String>>();
        map<String, String> contingentBeneficiaryToAddDetailsObj = new map<String, String>();
        List<map<String, String>> contingentBeneficiariesDetails = new List<map<String, String>>();
        Map<Integer, map<String, String>> financialAccountDetailsAttrVal = getFinancialAccountDetails(svcCatalogReqExtdAttrVals);
        Map<Integer, map<String, String>> primBeneficiaryToAddAttrVal = getPrimaryBeneficiary(svcCatalogReqExtdAttrVals);
        
        for (Integer groupNumber: financialAccountDetailsAttrVal.keyset()){            
            financialAccountDetailsObj = financialAccountDetailsAttrVal.get(groupNumber); 
            financialAccountDetails.add(financialAccountDetailsObj);
        }        
        for (Integer groupNumber : primBeneficiaryToAddAttrVal.keySet()) {           
            if(primBeneficiaryToAddAttrVal.get(groupNumber) != null)
                primBeneficiaryToAddDetailsObj = primBeneficiaryToAddAttrVal.get(groupNumber);
            primaryBeneficiariesDetails.add(primBeneficiaryToAddDetailsObj);
        }       
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            If (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'has_contingent_beneficiaries') {
                hasContingentBenf = svcCatalogReqExtdAttrVal.TextValue;
            }            
        }        
        // If there are contigent beneficiaries 
        If (hasContingentBenf == 'Yes'){            
            Map<Integer, map<String, String>> contBeneficiaryToAddAttrVal = getContingentBeneficiary(svcCatalogReqExtdAttrVals);            
            for (Integer groupNumber : contBeneficiaryToAddAttrVal.keySet()) {               
                contingentBeneficiaryToAddDetailsObj = contBeneficiaryToAddAttrVal.get(groupNumber);
                contingentBeneficiariesDetails.add(contingentBeneficiaryToAddDetailsObj);
            }
        }
        
        String faAccountlabel = '<b> Accounts to be updated</b><br><br>';
        String primaryBeneficiaryLabel = '<br><b>Primary Beneficiaries</b><br><br>';
        String faBody = FSCWlthUtilityClass.constructEmailBody(financialAccountDetails, faAccountlabel, false);
        String primaryBody = FSCWlthUtilityClass.constructEmailBody(primaryBeneficiariesDetails, primaryBeneficiaryLabel, true);
        String FinalBody = faBody + primaryBody;
        If (hasContingentBenf == 'Yes') {  
            String contingentBeneficiarylabel = '<br><b>Contingent Beneficiaries</b><br><br>';
            String contingentBody = FSCWlthUtilityClass.constructEmailBody(contingentBeneficiariesDetails, contingentBeneficiarylabel, true);
            FinalBody = FinalBody + contingentBody;
        }          
        List<String> bodyList = new List<String>();
        bodyList.add(FinalBody);
        return bodyList;
    } 
    
    private static Map<Integer, map<String, String>> getFinancialAccountDetails(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        
        Map<Integer, map<String, String>> faGroupNumMap = new Map<Integer, map<String, String>>();
        String accountName = null;
        String accountNumber = null;
        String ownerShipType  = null;
        
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            Boolean isFA = false;
            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                when 'account_name' {
                    accountName = svcCatalogReqExtdAttrVal.TextValue;  
                    isFA = true;
                } when 'account_ownership_type' {
                    ownerShipType = svcCatalogReqExtdAttrVal.TextValue;
                    isFA = true;
                }  when 'account_number' {
                    accountNumber = svcCatalogReqExtdAttrVal.TextValue;
                    isFA = true;
                }
            }           
            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null && isFA) {
                map<String, String> faMap = faGroupNumMap.get(groupNumber);
                faMap = new map<String, String>();
                faGroupNumMap.put(groupNumber, faMap);
                faMap.put('Account Name', accountName);
                faMap.put('Account Number', accountNumber);
                faMap.put('Ownership Type', ownerShipType);                
            }             
        }
        return faGroupNumMap;
    }
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of primary beneficiaries to add
    private static Map<Integer, map<String, String>> getPrimaryBeneficiary(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        Map<Integer, map<String, String>> primaryGroupNumMap = new Map<Integer, map<String, String>>();
        String relationshipType = null;
        String beneficiaryName = null;
        Decimal sharePercentage = null;      
        String perStirpes  = null;
        String emailAddress = null;
        String beneficiaryType  = null;
        String beneficiaryDob = null;
        String beneficiarySSN = null;
        String addressLine1 = null;
        String addressLine2 = null;
        String city = null;
        String state = null;
        String country = null;
        String postalCode = null;
        
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            Boolean isPrimary = false;
            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                when 'beneficiary_relationship_type' {
                    relationshipType = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_type' {
                    beneficiaryType = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                }  when 'beneficiary_name' {
                    beneficiaryName = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                }  when 'beneficiary_per_stirpes' {
                    perStirpes = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_share_percentage' {
                    sharePercentage = svcCatalogReqExtdAttrVal.NumberValue;
                    isPrimary = true;
                } when 'beneficiary_birth_date_incorporation' {
                    if(String.isNotBlank(svcCatalogReqExtdAttrVal.TextValue)) {
                        beneficiaryDob = svcCatalogReqExtdAttrVal.TextValue;
                    } else {
                        beneficiaryDob = null;  
                    }
                    isPrimary = true;
                } when 'beneficiary_ssn' {
                    if(String.isNotBlank(svcCatalogReqExtdAttrVal.TextValue)){ 
                        beneficiarySSN = svcCatalogReqExtdAttrVal.TextValue;
                    } else {
                        beneficiarySSN = null;
                    }
                    isPrimary = true;
                } when 'beneficiary_address_line_1' {
                    addressLine1 = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_address_line_2' {
                    addressLine2 = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_city' {
                    city = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_state' {
                    state = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_country' {
                    country = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_postal_code' {
                    postalCode = svcCatalogReqExtdAttrVal.TextValue;
                    isPrimary = true;
                } when 'beneficiary_email' {
                    if(String.isNotBlank(svcCatalogReqExtdAttrVal.TextValue)) {
                        emailAddress = svcCatalogReqExtdAttrVal.TextValue;
                    } else {
                        emailAddress = null;
                    }
                    isPrimary = true;
                }                
            }         
            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null && isPrimary) {
                map<String, String> primaryBenfMap = primaryGroupNumMap.get(groupNumber);
                primaryBenfMap = new map<String, String>();
                primaryGroupNumMap.put(groupNumber, primaryBenfMap);
                //set beneficiary details
                primaryBenfMap.put('Beneficiary Name', beneficiaryName);
                primaryBenfMap.put('Beneficiary Type', beneficiaryType);
                primaryBenfMap.put('Relationship Type', relationshipType);
                primaryBenfMap.put('New Share', String.valueOf (sharePercentage));
                primaryBenfMap.put('PerStirpes', perStirpes);
                if (beneficiaryDob != null) {
                    primaryBenfMap.put('Date of Birth', beneficiaryDob);
                } else {
                    primaryBenfMap.put('Date of Birth', '-');
                }
                if (emailAddress != null) {
                    primaryBenfMap.put('Email', emailAddress);
                } else {
                    primaryBenfMap.put('Email', '-'); 
                }
                if (beneficiarySSN != null) {
                    primaryBenfMap.put('SSN', beneficiarySSN);
                } else {
                    primaryBenfMap.put('SSN', '-'); 
                }
                String AddressLine;
                if(addressLine2 != null) {
                    AddressLine = addressLine1 + ' ' + addressLine2 +', ';
                } else {
                    AddressLine = addressLine1+ ', ';
                }
                String primaryBenificiaryAddress = AddressLine + city +', '+ state +', '+ country +', '+ postalCode;
                primaryBenfMap.put('Address', primaryBenificiaryAddress);                
            }             
        }
        return primaryGroupNumMap;
    }
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of contingent beneficiaries to add
    private static Map<Integer, map<String,String>> getContingentBeneficiary(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        
        Map<Integer, map<String,String>> ContingentBeneficiaryGroupNumMap = new Map<Integer, map<String,String>>();
        String relationshipType = null;
        String beneficiaryName = null;
        Decimal sharePercentage = null;      
        String perStirpes  = null;
        String emailAddress = null;
        String beneficiaryType  = null;
        String beneficiaryDob = null;
        String beneficiarySSN = null;
        String addressLine1 = null;
        String addressLine2 = null;
        String city = null;
        String state = null;
        String country = null;
        String postalCode = null;
        
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            Boolean isContingent = false;
            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                when 'contingent_relationship_type' {
                    relationshipType = svcCatalogReqExtdAttrVal.TextValue;
                    isContingent = true;
                } when 'contingent_beneficiary_type' {
                    beneficiaryType = svcCatalogReqExtdAttrVal.TextValue;
                    isContingent = true;
                }   when 'contingent_beneficiary_name' {
                    beneficiaryName = svcCatalogReqExtdAttrVal.TextValue;
                    isContingent = true;
                }    when 'contingent_per_stirpes' {
                    perStirpes = svcCatalogReqExtdAttrVal.TextValue;
                    isContingent = true;
                } when 'contingent_share_percentage' {
                    sharePercentage = svcCatalogReqExtdAttrVal.NumberValue;
                    isContingent = true;
                } when 'contingent_birth_date_incorporation' {
                    if(String.isNotBlank(svcCatalogReqExtdAttrVal.TextValue)) { 
                        beneficiaryDob = svcCatalogReqExtdAttrVal.TextValue;
                    } else {
                        beneficiaryDob = null;
                    }
                    isContingent = true;
                } when 'contingent_email' {
                    if(String.isNotBlank(svcCatalogReqExtdAttrVal.TextValue)) {
                        emailAddress = svcCatalogReqExtdAttrVal.TextValue;
                    } else {
                        emailAddress = null; 
                    }
                    isContingent = true;
                } when 'contingent_ssn' {
                    if(String.isNotBlank(svcCatalogReqExtdAttrVal.TextValue)){
                        beneficiarySSN = svcCatalogReqExtdAttrVal.TextValue;
                    } else {
                        beneficiarySSN = null; 
                    }
                    isContingent = true;
                } when 'contingent_address_line_1' {
                    addressLine1 = svcCatalogReqExtdAttrVal.TextValue;
                    isContingent = true;
                } when 'contingent_address_line_2' {
                    addressLine2 = svcCatalogReqExtdAttrVal.TextValue;
                    isContingent = true;
                } when 'contingent_city' {
                    city = svcCatalogReqExtdAttrVal.TextValue;
                    isContingent = true;
                } when 'contingent_state' {
                    state = svcCatalogReqExtdAttrVal.TextValue;
                    isContingent = true;
                } when 'contingent_country' {
                    country = svcCatalogReqExtdAttrVal.TextValue;
                    isContingent = true;
                } when 'contingent_postal_code' {
                    postalCode = svcCatalogReqExtdAttrVal.TextValue;
                    isContingent = true;
                }
            }            
            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null && isContingent) {
                map<String, String> contingentBenfMap = ContingentBeneficiaryGroupNumMap.get(groupNumber);               
                contingentBenfMap = new map<String, String>();
                ContingentBeneficiaryGroupNumMap.put(groupNumber, contingentBenfMap);
                //set beneficiary details
                contingentBenfMap.put('Beneficiary Name', beneficiaryName);
                contingentBenfMap.put('Beneficiary Type', beneficiaryType);
                contingentBenfMap.put('Relationship Type', relationshipType);
                contingentBenfMap.put('New Share', String.valueOf (sharePercentage));
                contingentBenfMap.put('PerStirpes', perStirpes);
                if (beneficiaryDob != null) {
                    contingentBenfMap.put('Date of Birth', beneficiaryDob);
                } else {
                    contingentBenfMap.put('Date of Birth', '-');
                }
                if (emailAddress != null) {
                    contingentBenfMap.put('Email', emailAddress);
                } else {
                    contingentBenfMap.put('Email', '-');
                }
                if (beneficiarySSN != null) {
                    contingentBenfMap.put('SSN', beneficiarySSN);
                } else {
                    contingentBenfMap.put('SSN', '-'); 
                }
                String AddressLine;
                if (addressLine2 != null) {
                    AddressLine = addressLine1 + ' ' + addressLine2 +', ';
                } else {
                    AddressLine = addressLine1+ ', '; 
                }
                String contingentBenificiaryAddress = AddressLine + city +', '+ state +', '+ country +', '+ postalCode;
                contingentBenfMap.put('Address', contingentBenificiaryAddress);
            }             
        }
        return ContingentBeneficiaryGroupNumMap;
    }
}