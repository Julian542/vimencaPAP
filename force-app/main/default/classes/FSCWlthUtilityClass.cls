/*************************
* @Class Name:- FSCWlthUtilityClass
* @Description:- Common utility class for all the FSC Wealth related processes
**************************/
global with sharing class FSCWlthUtilityClass implements System.Callable {
    
    //Method to get the base Url
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = (Map<String, Object>)args.get('input');
        Map<String, Object> outputMap = (Map<String, Object>)args.get('output');
        
        if (action == 'getBasePath') {
            String path = Site.getPathPrefix();
            Map<String, String> responseMap = new Map<String, String>();
            responseMap.put('BasePath', path);
            outputMap.put('result', responseMap);
            return outputMap;
        }
        
        if (action == 'getLastSpecificYears') {
            List<Map<String, String>> dateList = new List<Map<String, String>>();
            for (integer i=0; i<30; i++) {
                Integer previousYear = Date.today().year() - i; 
                Map<String, String> selectMap = new Map<String, String>();
                selectMap.put('name', String.ValueOf(previousYear));
                selectMap.put('value', String.ValueOf(previousYear));
                dateList.add(selectMap);
            }
            outputMap.put('options', dateList);    
        }
        
        //fetch unique values in a list
        if (action == 'getUniqueList') {
            List<Object> inputList = (List<Object>)inputMap.get('InputList'); 
            Set<Object> uniqueSet = new Set<Object>();
            uniqueSet.addAll(inputList);
            outputMap.put('UniqueList', uniqueSet);
            return outputMap;
        }
        
        //converts string list to map
        if (action == 'convertListToMap') {
            List<Object> inputList = (List<Object>)inputMap.get('InputList'); 
            List<Map<String,Object>> convertedMapList = new List<Map<String,Object>>();
            for(Object inp:inputList){
                Map<String,Object> convertedMap = new Map<String,String>();
                convertedMap.put('Name',inp);
                convertedMapList.add(convertedMap);
            }
            outputMap.put('OutputMapList', convertedMapList);
            return outputMap;
        }
        
        //upload documents and create DCI records and content document link
        if (action == 'callCreateDCI') {
            List<Object> uploadedDocumentInfoList = (List<Object>)inputMap.get('documentInfo');
            String parentId = String.valueOf(inputMap.get('parentId'));
            List<Object> rejectedDocumentInfoList = new List<Object>();
            if (inputMap.get('rejectedDocuments') != null) {
                 rejectedDocumentInfoList = (List<Object>)inputMap.get('rejectedDocuments');
            }
            List<DocumentChecklistItem> listOfDocChecklistItem = new List<DocumentChecklistItem>();
            List<ContentDocumentLink> listOfContentDoc = new List<ContentDocumentLink>();
            Map<String, String> mapOfDocNameAndId = new Map<String, String>();
            Map<String, String> mapOfDocIdAndAccNumber = new Map<String, String>();
            try {
                if (uploadedDocumentInfoList != null && !uploadedDocumentInfoList.isEmpty()) {
                    if (rejectedDocumentInfoList != null && !rejectedDocumentInfoList.isEmpty()) {
                        for (Object uploadedDocInfoMap : uploadedDocumentInfoList) {
                            for (Object rejectedDocumentInfoMap : rejectedDocumentInfoList) {
                                Map<String, Object> uploadMap = (Map<String, Object>)uploadedDocInfoMap;
                                Map<String, Object> rejectedDocMap = (Map<String, Object>)rejectedDocumentInfoMap;
                                if (String.valueOf((String) uploadMap.get('id')) == String.valueOf(rejectedDocMap.get('Files')).split(',')[0].substringAfter('=')) {
                                    mapOfDocIdAndAccNumber.put(String.valueOf((String)uploadMap.get('id')), String.valueOf(rejectedDocMap.get('AccountNumber')));
                                }
                            }
                        }
                    }
                    for (Object uploadedDocInfoMap : uploadedDocumentInfoList) {
                        DocumentChecklistItem dciObj = new DocumentChecklistItem();
                        Map<String, Object> uploadMap = (Map<String, Object>)uploadedDocInfoMap;
                        if (!rejectedDocumentInfoList.isEmpty() && mapOfDocIdAndAccNumber != null && !mapOfDocIdAndAccNumber.isEmpty()) {
                            dciObj.Name = mapOfDocIdAndAccNumber.get((String)uploadMap.get('id')) +' - ' + (String) uploadMap.get('name');   
                        } else {
                            dciObj.Name = (String) uploadMap.get('name');
                        }
                        dciObj.DocumentTypeId = (String) uploadMap.get('typeId');
                        dciObj.ParentRecordId = parentId;
                        mapOfDocNameAndId.put(dciObj.Name, (String) uploadMap.get('id'));
                        listOfDocChecklistItem.add(dciObj);
                    }
                    insert listOfDocChecklistItem;
                    
                    List<DocumentChecklistItem> listOfDCIInserted = [Select Id,Name,ParentRecordId,Status FROM DocumentChecklistItem Where ParentRecordId =: parentId AND Status = 'New'];
                    if (listOfDCIInserted.size()>0) {
                        for (DocumentChecklistItem dciObj : listOfDCIInserted) {
                            if(mapOfDocNameAndId.containsKey(dciObj.Name)) {
                                ContentDocumentLink cdlObj = new ContentDocumentLink();
                                cdlObj.LinkedEntityId = dciObj.Id;
                                cdlObj.ContentDocumentId = mapOfDocNameAndId.get(dciObj.Name);
                                listOfContentDoc.add(cdlObj);
                            }
                        }
                        insert listOfContentDoc;
                    }
                }
            } catch (Exception ex) {
                Map<String, String> responseMap = new Map<String,String>();
                responseMap.put('response', ex.getMessage());
                return responseMap;
            }
        }
        return null;
    }
    
    //Method to get the Account Source System Id
    public static String getAccountSourceSystemId(String inputRecordId) {
        SvcCatalogRequest svcReq = [SELECT CaseId FROM SvcCatalogRequest WHERE Id =: inputRecordId WITH SECURITY_ENFORCED];
        Case caseDetail = [SELECT Id, Account.FinServ__SourceSystemId__c,AccountId FROM Case WHERE Id =: svcReq.CaseId WITH SECURITY_ENFORCED];
        String recordId = caseDetail.Account.FinServ__SourceSystemId__c;
        return recordId;
    }
    
    //Method to get the Financial Account Source System Id
    public static String getFinancialAccSourceSystemId(String recordId, String faNumber) {
        String faNum;
        String last4Number;
        String financialAccSourceSysId;
        List<FinServ__FinancialAccount__c> finAccList = [SELECT Id, FinServ__SourceSystemId__c, FinServ__FinancialAccountNumber__c FROM FinServ__FinancialAccount__c WHERE (FinServ__PrimaryOwner__r.FinServ__SourceSystemId__c =: recordId OR FinServ__JointOwner__r.FinServ__SourceSystemId__c =: recordId) WITH SECURITY_ENFORCED];
        for (FinServ__FinancialAccount__c numAttributes: finAccList) { 
            if (numAttributes.FinServ__FinancialAccountNumber__c != null && numAttributes.FinServ__FinancialAccountNumber__c != ' ') {
                faNum = String.valueOf(numAttributes.FinServ__FinancialAccountNumber__c);           
                last4Number = 'XXXX-' + faNum.right(4); 
                if (faNumber == last4Number) {
                    financialAccSourceSysId = numAttributes.FinServ__SourceSystemId__c;
                }
            }
        }
        return financialAccSourceSysId;
    }
    
    //Method to get the Financial Account Id
    public static String getFinancialAccountId(String recordId, String faNumber) {
        String financialAccountId;
        String faNum;
        String last4Number;
        List<FinServ__FinancialAccount__c> finAccList = [SELECT Id, FinServ__SourceSystemId__c, FinServ__FinancialAccountNumber__c FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__r.FinServ__SourceSystemId__c =: recordId WITH SECURITY_ENFORCED];
        
        for (FinServ__FinancialAccount__c numAttributes: finAccList) {        
            faNum = String.valueOf(numAttributes.FinServ__FinancialAccountNumber__c);
            last4Number = 'XXXX-' + faNum.right(4); 
            if (faNumber == last4Number) {
                financialAccountId = numAttributes.Id;
            }
        }
        return financialAccountId;
    }
    
    //Method to create table for email notifications
    public static string constructEmailBody(List<map<String,String>> tableDataDetails, String label, Boolean hasScroll) {
        
        String emailBody;        
        if(hasScroll)
            emailBody = label + '<table style="font-family: Segoe UI, Helvetica, Arial, sans-serif; border-collapse: collapse; width: 100%;display: block; overflow-x: auto; white-space: nowrap;"><tr style="background-color: #F3F3F3;">';
        else
            emailBody = label + '<table style="font-family: Segoe UI, Helvetica, Arial, sans-serif; border-collapse: collapse; width: 100%;"><tr style="background-color: #F3F3F3;">'; 
        String headerStartingTag = '<th style="border: 1px solid #C9C9C9; text-align: left;padding: 8px;">';
        String headerEndingTag = '</th>';
        String rowStartingTag = '<tr>';
        String rowEndingTag = '</tr>';
        String contentStartingTag = '<td style="border: 1px solid #C9C9C9; text-align: left;padding: 8px;">';
        String cellEndingTag = '</td>';
        
        for (String key: tableDataDetails[0].keyset()) {
            emailBody = emailBody + headerStartingTag + key + headerEndingTag;
        } 
        emailBody = emailBody + rowEndingTag;
        Integer intNum;
        for( intNum = 0; intNum < tableDataDetails.size(); intNum++) {
            emailBody = emailBody + rowStartingTag;
            for(String key : tableDataDetails[intNum].keyset()){
                emailBody = emailBody + contentStartingTag + tableDataDetails[intNum].get(key) + cellEndingTag;
            }
            emailBody = emailBody + rowEndingTag;
        }
        emailBody = emailBody+'</table>';
        return emailBody;
    }
}