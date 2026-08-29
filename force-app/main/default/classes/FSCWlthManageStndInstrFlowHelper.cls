/*************************
* @Class Name:- FSCWlthManageStndInstrFlowHelper
* @Description:- Manage Standing Instruction process case creation email flow helper class
**************************/
public with sharing class FSCWlthManageStndInstrFlowHelper {
    
    public class FlowInputs {
        @InvocableVariable(label='Service Catalog Request Id' required=true)
        public String inputRecordId;
    }
    
    //Invocable method used in the flow to get the standing instruction list
    @InvocableMethod(label='Get Wealth Standing Instructions' description='Process all extended attribute records')
    public static List<String> getStandingInstructionsList(List<FlowInputs> flowInput) {
        String svcRecordId = flowInput[0].inputRecordId;
        String action;
        List<String> bodyList = new List<String>();
        //Fetch all SvcCatalogReqExtdAttrVal
        List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, GroupNumber, TextValue, NumberValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :svcRecordId WITH SECURITY_ENFORCED ORDER BY GroupNumber ASC NULLS FIRST];
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            If (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'standing_instruction_type') {
                action = svcCatalogReqExtdAttrVal.TextValue;
            }            
        } 
        
        // if action equals Delete/Cancel Standing Instruction construct email body
        if (action == 'Cancel') {
            Map<Integer, Map<String, String>> standingInstructionToDeleteAttrVal = getDeleteStandingInstructions(svcCatalogReqExtdAttrVals);            
            Map<String, String> standingInstructionToDeleteDetailsObj = new Map<String, String>();
            List<Map<String, String>> standingInstructionToDeleteDetails = new List<Map<String, String>>();
            for (Integer groupNumber : standingInstructionToDeleteAttrVal.keySet()) {               
                standingInstructionToDeleteDetailsObj = standingInstructionToDeleteAttrVal.get(groupNumber);
                standingInstructionToDeleteDetails.add(standingInstructionToDeleteDetailsObj);
            }
            String standingInstructionToDeleteLabel = '<br><b>Standing instructions to be deleted</b><br>';
            String siToDeleteEmailBody = FSCWlthUtilityClass.constructEmailBody(standingInstructionToDeleteDetails, standingInstructionToDeleteLabel, false);
            bodyList.add(siToDeleteEmailBody);
        }
        
        // if action equals Add Standing Instructions construct email body
        if (action == 'Add') {
            //construct GroupNumberSet per modes
            Set<Integer> bankWireGroupNumSet = new Set<Integer>();
            Set<Integer> eftGroupNumSet = new Set<Integer>();
            Set<Integer> journalGroupNumSet = new Set<Integer>();
            Set<Integer> checkDisGroupNumSet = new Set<Integer>();
            String finalEmailBody = '';
            for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
                If (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'mode' && svcCatalogReqExtdAttrVal.TextValue == 'Wire Transfer') {
                    bankWireGroupNumSet.add(svcCatalogReqExtdAttrVal.GroupNumber);
                } 
                If (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'mode' && svcCatalogReqExtdAttrVal.TextValue == 'EFT') {
                    eftGroupNumSet.add(svcCatalogReqExtdAttrVal.GroupNumber);
                } 
                If (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'mode' && svcCatalogReqExtdAttrVal.TextValue == 'Journal') {
                    journalGroupNumSet.add(svcCatalogReqExtdAttrVal.GroupNumber);
                } 
                If (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'mode' && svcCatalogReqExtdAttrVal.TextValue == 'Check') {
                    checkDisGroupNumSet.add(svcCatalogReqExtdAttrVal.GroupNumber);
                } 
            }
            // when Add SI mode = Wire Transfer
            if (!bankWireGroupNumSet.isEmpty()) {
                String addBankWireSIEmailBody = createTableBody(svcCatalogReqExtdAttrVals, bankWireGroupNumSet, 'Wire Transfer');
                finalEmailBody = finalEmailBody + addBankWireSIEmailBody;
            }
            // when Add SI mode = EFT
            if (!eftGroupNumSet.isEmpty()) {
                String addEftSIEmailBody = createTableBody(svcCatalogReqExtdAttrVals, eftGroupNumSet, 'EFT');
                finalEmailBody = finalEmailBody + addEftSIEmailBody;
            }
            // when Add SI mode = Journal
            if (!journalGroupNumSet.isEmpty()) {
                String addJournalSIEmailBody = createTableBody(svcCatalogReqExtdAttrVals, journalGroupNumSet, 'Journal');
                finalEmailBody = finalEmailBody + addJournalSIEmailBody;
            }
            // when Add SI  mode = Check
            if (!checkDisGroupNumSet.isEmpty()) {
                String addCheckDisSIEmailBody = createTableBody(svcCatalogReqExtdAttrVals, checkDisGroupNumSet, 'Check');
                finalEmailBody = finalEmailBody + addCheckDisSIEmailBody;
            }
            bodyList.add(finalEmailBody);
        } 
        return bodyList;
    }
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of standing instructions to delete/cancel
    private static Map<Integer, Map<String, String>> getDeleteStandingInstructions(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals) {
        Map<Integer, Map<String, String>> deleteStandingInstructionGroupNumMap = new Map<Integer, Map<String, String>>();
        String payeeName = null;
        String accountNumber = null;
        String mode = null;
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                when 'cancel_payee_name' {
                    payeeName = svcCatalogReqExtdAttrVal.TextValue;
                } when 'cancel_account_number' {
                    accountNumber = svcCatalogReqExtdAttrVal.TextValue;
                } when 'cancel_mode' {
                    mode = svcCatalogReqExtdAttrVal.TextValue;
                }  
            }
            Integer groupNumber = svcCatalogReqExtdAttrVal.GroupNumber;
            if (groupNumber != null) {
                Map<String, String> deleteStandingInstMap = deleteStandingInstructionGroupNumMap.get(groupNumber);               
                deleteStandingInstMap = new Map<String, String>();
                deleteStandingInstructionGroupNumMap.put(groupNumber, deleteStandingInstMap);
                //set Standing instructions details
                deleteStandingInstMap.put('Payee Name', payeeName);
                deleteStandingInstMap.put('Payment Method', mode);
                deleteStandingInstMap.put('Account Number', accountNumber);
            }
        }
        return deleteStandingInstructionGroupNumMap;
    }
    
    //Construct email table body based on different mode values
    private static string createTableBody(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals, Set<Integer>modeGroupNumSet, String addMode){
        String tableBody;
        Map<Integer, Map<String, String>> addModeSIAttrVal = getAddModeSI(svcCatalogReqExtdAttrVals, modeGroupNumSet, addMode);            
        Map<String, String> addModeSIDetailsObj = new Map<String, String>();
        List<Map<String, String>> addModeSIDetails = new List<Map<String, String>>();
        if (addModeSIAttrVal != null) {
            for (Integer groupNumber : addModeSIAttrVal.keySet()) {               
                addModeSIDetailsObj = addModeSIAttrVal.get(groupNumber);
                addModeSIDetails.add(addModeSIDetailsObj);
            }
            String addModeSILabel = '<br><b> New '+ addMode +' standing instructions</b><br>';
            tableBody = FSCWlthUtilityClass.constructEmailBody(addModeSIDetails, addModeSILabel, true);
        } 
        return tableBody;
    }
    
    //looping through the svcCatalogReqExtdAttrVals records to get the array of standing instructions to Add mode
    private static Map<Integer, Map<String, String>> getAddModeSI(List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals, Set<Integer> addModeGroupNumSet, String addMode) {
        Map<Integer, Map<String, String>> addModeSIGroupNumMap = new Map<Integer, Map<String, String>>();
        String payeeName = null;
        String accountNumber = null;
        String mode = null;
        String routingNumber = null;
        String bankName = null;
        String payeeAddress = null;
        String city = null;
        String state = null;
        String zipCode = null;
        String country = null;
        String transferType = null;
        Double amount = null;
        String currencyCode =null;
        String prefix = null;
        String memo = null;
        String checkStub = null;
        String accountType = null;
        for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
            if (svcCatalogReqExtdAttrVal.GroupNumber != null && addModeGroupNumSet.contains(svcCatalogReqExtdAttrVal.GroupNumber)) {
                switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                    when 'payee_name' {
                        payeeName = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'payee_account_number' {
                        accountNumber = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'mode' {
                        mode = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'routing_number' {
                        routingNumber = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'bank_name' {
                        bankName = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'payee_address' {
                        payeeAddress = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'city' {
                        city = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'state' {
                        state = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'zip_code' {
                        zipCode = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'country' {
                        country = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'transfer_type' {
                        if(String.isNotBlank(svcCatalogReqExtdAttrVal.TextValue)) {
                            transferType = svcCatalogReqExtdAttrVal.TextValue;
                        } else {
                            transferType = null;
                        }
                    } when 'max_amount' {
                        amount = svcCatalogReqExtdAttrVal.NumberValue;
                    } when 'currency_code' {
                        currencyCode = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'prefix' {
                        prefix = svcCatalogReqExtdAttrVal.TextValue;
                    } when 'memo' {
                        if(String.isNotBlank(svcCatalogReqExtdAttrVal.TextValue)) {
                            memo = svcCatalogReqExtdAttrVal.TextValue;
                        } else {
                            memo = null;
                        }   
                    } when 'check_stub_information' {
                        if(String.isNotBlank(svcCatalogReqExtdAttrVal.TextValue)) {
                            checkStub = svcCatalogReqExtdAttrVal.TextValue;
                        } else {
                            checkStub = null;
                        }
                    } when 'eft_account_type' {
                        accountType = svcCatalogReqExtdAttrVal.TextValue;
                    } 
                } 
                Map<String, String> addModeSIMap = addModeSIGroupNumMap.get(svcCatalogReqExtdAttrVal.GroupNumber);               
                addModeSIMap = new Map<String, String>();
                addModeSIGroupNumMap.put(svcCatalogReqExtdAttrVal.GroupNumber, addModeSIMap);
                //set Standing instructions details
                addModeSIMap.put('Payee Name', payeeName);
                addModeSIMap.put('Payment Method', mode);
                if( addMode != 'Check') {
                    addModeSIMap.put('Account Number', accountNumber);
                }
                if( addMode == 'Wire Transfer' || addMode == 'EFT') {
                    addModeSIMap.put('Bank Name', bankName);
                    addModeSIMap.put('Routing Number', routingNumber);
                    if (addMode == 'EFT') {
                        addModeSIMap.put('Current/Savings', accountType);
                    }
                }
                if( addMode == 'Check') {
                    addModeSIMap.put('Title', prefix);
                    if(memo != null) {
                        addModeSIMap.put('Comments', memo);
                    } else {
                        addModeSIMap.put('Comments', 'N/A');
                    } 
                    if(checkStub != null) {
                        addModeSIMap.put('Stub Details', checkStub);
                    } else {
                        addModeSIMap.put('Stub Details', 'N/A');
                    }
                }
                if( addMode == 'Wire Transfer' || addMode == 'Check') {
                    String finalAddress = payeeAddress+', '+city+', '+state+', '+country+', '+zipCode;
                    addModeSIMap.put('Address', finalAddress);
                }
                if( addMode != 'Journal') {
                    if(transferType != null) {
                       addModeSIMap.put('Transfer Type', transferType);
                    } else {
                       addModeSIMap.put('Transfer Type', 'N/A');
                    }
                    String finalAmount = currencyCode + ' ' + String.valueOf(amount);
                    addModeSIMap.put('Amount', finalAmount);
                }
            }
        }
        return addModeSIGroupNumMap;
    }
}