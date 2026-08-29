/*************************
* @Class Name:- ManageBeneficiariesFlowHelperClass
* @Description:- Manage Beneficiaries process case creation email flow helper class
**************************/
public with sharing class ManageBeneficiariesFlowHelperClass {

    class BeneficiariesList {
        String beneficiaryName;
        String beneficiaryMobile;
        String beneficiaryDob;
        String isMinor;
        String guardianName;
        String guardianMobile;
        Integer groupNumber;
    }
    
    public class FlowInputs{
        @InvocableVariable(label='Service Catalog Request Id' required=true)
        public String inputRecordId;
        @InvocableVariable(label='Action' required=true)
        public String action;
    }
    
    //Invocable method used in the flow to get the beneficiaries list
    @InvocableMethod(label='Get Added/Deleted Beneficiaries' description='Process all extended attribute records')
    public static List<String> getBeneficiariesList(List<FlowInputs> flowInput) {
       String svcRecordId = flowInput[0].inputRecordId;
       String actionType = flowInput[0].action;
       List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, GroupNumber, TextValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :svcRecordId WITH SECURITY_ENFORCED ORDER BY GroupNumber ASC NULLS FIRST];
       Map<Integer, BeneficiariesList> beneficiariesList = getBeneficiaryAttrValue(svcCatalogReqExtdAttrVals, actionType);
       String body = constructEmailBody(beneficiariesList.values(), actionType);
       List<String> bodyList = new List<String>();
       bodyList.add(body);
       return bodyList;
    } 
    
    //Constructs the email body with beneficiaries details
    private static string constructEmailBody(List<BeneficiariesList> beneficiaryList, String actionType) {
        String emailBody = '';
        if (actionType == 'Add') {
            for (BeneficiariesList benList : beneficiaryList) {
                String beneficiaryDetailsStr = '<p style="padding: 0;margin: 16px 0;font-family: Segoe UI, Helvetica, Arial, sans-serif;">';
                beneficiaryDetailsStr = beneficiaryDetailsStr + '<Strong>Beneficiary '+benList.groupNumber+'</Strong><br>';
                beneficiaryDetailsStr = beneficiaryDetailsStr + 'Name: <Strong>'+benList.beneficiaryName+'</strong><br>';
                beneficiaryDetailsStr = beneficiaryDetailsStr + 'Mobile: <Strong>'+benList.beneficiaryMobile+'</strong><br>';
                beneficiaryDetailsStr = beneficiaryDetailsStr + 'Date of Birth: <Strong>'+benList.beneficiaryDob+'</strong><br>';
                beneficiaryDetailsStr = beneficiaryDetailsStr + 'Minor: <Strong>'+benList.isMinor+'</strong><br>';
                if(benList.isMinor == 'Yes') {
                    beneficiaryDetailsStr = beneficiaryDetailsStr + 'Guardian: <Strong>'+benList.guardianName+'</strong><br>';
                    beneficiaryDetailsStr = beneficiaryDetailsStr + 'Guardian Mobile: <Strong>'+benList.guardianMobile+'</strong><br>';                
                }
                beneficiaryDetailsStr = beneficiaryDetailsStr +'</p>';
                emailBody = emailBody + beneficiaryDetailsStr;
            }
        } else if (actionType == 'Delete'){
            for (BeneficiariesList benList : beneficiaryList) {
                String beneficiaryDetailsStr = '<p style="padding: 0;margin: 16px 0;font-family: Segoe UI, Helvetica, Arial, sans-serif;">';
                beneficiaryDetailsStr = beneficiaryDetailsStr + '<Strong>Beneficiary '+benList.groupNumber+'</Strong><br>';
                beneficiaryDetailsStr = beneficiaryDetailsStr + 'Name: <Strong>'+benList.beneficiaryName+'</strong><br>';
                if (benList.beneficiaryMobile != null) {
                    beneficiaryDetailsStr = beneficiaryDetailsStr + 'Mobile: <Strong>'+benList.beneficiaryMobile+'</strong><br>';
                }
                beneficiaryDetailsStr = beneficiaryDetailsStr +'</p>';
                emailBody = emailBody+ beneficiaryDetailsStr;
            }
        }
        return emailBody;
    }
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of beneficiaries
    private static Map<Integer, BeneficiariesList> getBeneficiaryAttrValue(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals, String actionType) {
        Map<Integer, BeneficiariesList> beneficiaryAttrValuesMap = new Map<Integer, BeneficiariesList>();
        String name = null;
        String mobile = null;
        String dob = null;
        String isMinor = null;
        String guardianName = null;
        String guardianMobile = null;
        if (actionType == 'Delete') {
            for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
                if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'beneficiary_name_to_delete') {
                    name = svcCatalogReqExtdAttrVal.TextValue;
                } else if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'mobile') {
                    mobile = svcCatalogReqExtdAttrVal.TextValue;
                }
                Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
                if (groupNumber != null) {
                    BeneficiariesList beneficiaryAttrValue = beneficiaryAttrValuesMap.get(groupNumber);               
                    beneficiaryAttrValue = new BeneficiariesList();
                    beneficiaryAttrValuesMap.put(groupNumber, beneficiaryAttrValue);
                    beneficiaryAttrValue.groupNumber = groupNumber;
                    beneficiaryAttrValue.beneficiaryName = name; 
                    beneficiaryAttrValue.beneficiaryMobile = mobile;         
                }             
            }            
        }else if(actionType == 'Add') {
            for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
                switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                    when 'beneficiary_name' {
                        name = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'beneficiary_mobile' {
                        mobile = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'beneficiary_birth_date' {
                        dob = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'is_beneficiary_minor' {
                        isMinor = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'guardian_name' {
                        guardianName = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'guardian_mobile' {
                        guardianMobile = svcCatalogReqExtdAttrVal.TextValue;
                    } 
                }
                Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
                if (groupNumber != null) {
                    BeneficiariesList beneficiaryAttrValue = beneficiaryAttrValuesMap.get(groupNumber);               
                    beneficiaryAttrValue = new BeneficiariesList();
                    beneficiaryAttrValuesMap.put(groupNumber, beneficiaryAttrValue);
                    beneficiaryAttrValue.groupNumber = groupNumber;
                    beneficiaryAttrValue.beneficiaryName = name; 
                    beneficiaryAttrValue.beneficiaryMobile = mobile;      
                    beneficiaryAttrValue.beneficiaryDob = dob;  
                    beneficiaryAttrValue.isMinor = isMinor;  
                    beneficiaryAttrValue.guardianName = guardianName;  
                    beneficiaryAttrValue.guardianMobile = guardianMobile;  
                }             
            }            
        }
        return beneficiaryAttrValuesMap;
    }  
}