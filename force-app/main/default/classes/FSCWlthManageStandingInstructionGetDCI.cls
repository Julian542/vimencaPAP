/*************************
* @Class Name:- FSCWlthManageStandingInstructionGetDCI
* @Description:- Class to get New Document checklist item for wealth manage standing instruction
**************************/
global with sharing class FSCWlthManageStandingInstructionGetDCI implements System.Callable {
    //Method to get the base Url
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = (Map<String, Object>)args.get('input');
        Map<String, Object> outputMap = (Map<String, Object>)args.get('output');
        
        if (action == 'uploaddocument') {
            List<Map<String, String>> addModeSIDetails = new List<Map<String, String>>();
            List<Object> docList = (List<Object>)inputMap.get('docinfo'); 
            String caseId = (String)inputMap.get('CaseId'); 
            Boolean isGetReviewedDCI = (Boolean)inputMap.get('isGetReviewedDCI');
            
            SvcCatalogRequest svcId = [Select Id from SvcCatalogRequest where CaseId =: caseId WITH SECURITY_ENFORCED LIMIT 1];
            List<SvcCatalogReqExtdAttrVal> svcCatalogReqExtdAttrVals = [SELECT Id, SvcCtlgItemAttrDeveloperName, GroupNumber, TextValue, NumberValue FROM SvcCatalogReqExtdAttrVal WHERE SvcCatalogRequestId = :svcId.Id WITH SECURITY_ENFORCED ORDER BY GroupNumber ASC NULLS FIRST];
            for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
                if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'standing_instruction_type') {
                    action = svcCatalogReqExtdAttrVal.TextValue;
                }   
            }
            if (action == 'Add') {
                //construct GroupNumberSet per modes
                Set<Integer> eftGroupNumSet = new Set<Integer>();
                for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
                    if (svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName == 'mode' && svcCatalogReqExtdAttrVal.TextValue == 'EFT') {
                        eftGroupNumSet.add(svcCatalogReqExtdAttrVal.GroupNumber);
                    } 
                }
                
                if (!eftGroupNumSet.isEmpty()) {
                    Map<Integer, Map<String, String>> addModeSIGroupNumMap = new Map<Integer, Map<String, String>>();
                    String accountNumber = null;
                    String mode = null;
                    String routingNumber = null;
                    String bankName = null;
                    String transferType = null;
                    for (SvcCatalogReqExtdAttrVal svcCatalogReqExtdAttrVal : svcCatalogReqExtdAttrVals) {
                        if (svcCatalogReqExtdAttrVal.GroupNumber != null && eftGroupNumSet.contains(svcCatalogReqExtdAttrVal.GroupNumber)) {
                            switch on svcCatalogReqExtdAttrVal.SvcCtlgItemAttrDeveloperName {
                                when 'payee_account_number' {
                                    accountNumber = svcCatalogReqExtdAttrVal.TextValue;
                                } when 'mode' {
                                    mode = svcCatalogReqExtdAttrVal.TextValue;
                                } when 'routing_number' {
                                    routingNumber = svcCatalogReqExtdAttrVal.TextValue;
                                } when 'bank_name' {
                                    bankName = svcCatalogReqExtdAttrVal.TextValue;
                                } when 'transfer_type' {
                                    transferType = svcCatalogReqExtdAttrVal.TextValue;
                                }
                            }
                            Map<String, String> addModeSIMap = addModeSIGroupNumMap.get(svcCatalogReqExtdAttrVal.GroupNumber);               
                            addModeSIMap = new Map<String, String>();
                            addModeSIGroupNumMap.put(svcCatalogReqExtdAttrVal.GroupNumber, addModeSIMap);
                            if( mode == 'EFT') {
                                if(transferType == '1st Party Transfer'){
                                    addModeSIMap.put('Account Number', accountNumber);
                                    addModeSIMap.put('Bank Name', bankName);
                                    addModeSIMap.put('Routing Number', routingNumber);
                                }
                            }
                        }   
                    }
                    Map<String, String> addModeSIDetailsObj = new Map<String, String>();
                    
                    if (addModeSIGroupNumMap != null) {
                        for (Integer groupNumber : addModeSIGroupNumMap.keySet()) {               
                            addModeSIDetailsObj = addModeSIGroupNumMap.get(groupNumber);
                            addModeSIDetails.add(addModeSIDetailsObj);
                        }
                    }
                }      
            }
            List<Object> finalDocList = new List<Object>();
            for(Integer intNum = 0; intNum < addModeSIDetails.size(); intNum++) {
                for(String key : addModeSIDetails[intNum].keyset()){
                    for(Object documentInfo : docList){
                        Map<String, Object> docToAddObj = (Map<String, Object>)documentInfo;
                        if ((String.valueOf(docToAddObj.get('AccNumber')) == addModeSIDetails[intNum].get(key))) {
                            map<String, String> documentList = new map<String, String>(); 
                            map<String, Object> mapOfStatusAndDoc = new map<String, Object>(); 
                            documentList.put('Status', String.valueOf(docToAddObj.get('Status')));
                            documentList.put('dciId', String.valueOf(docToAddObj.get('dciId')));
                            documentList.put('ContentDocumentId', String.valueOf(docToAddObj.get('ContentDocumentId')));
                            documentList.put('Name', String.valueOf(docToAddObj.get('Name')));
                            documentList.put('AccountNumber', String.valueOf(docToAddObj.get('AccNumber')));
                            documentList.put('BankName', addModeSIDetails[intNum].get('Bank Name'));
                            documentList.put('RoutingNumber', addModeSIDetails[intNum].get('Routing Number'));
                            documentList.put('Remarks', String.valueOf(docToAddObj.get('Remarks')));
                            if (isGetReviewedDCI == true) {
                                if (String.valueOf(docToAddObj.get('Status')) == 'Accepted') {
                                    mapOfStatusAndDoc.put('Accepted', documentList);
                                }
                                else if (String.valueOf(docToAddObj.get('Status')) == 'Rejected') {
                                    mapOfStatusAndDoc.put('Rejected', documentList);
                                }
                                finalDocList.add(mapOfStatusAndDoc);
                            }
                            else {
                                finalDocList.add(documentList);
                            } 
                        }
                    }
                }
            }
            outputMap.put('result', finalDocList);
            return outputMap;
        }
        return null;
    }
}