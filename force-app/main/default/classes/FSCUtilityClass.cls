/*************************
* @Class Name:- FSCUtilityClass
* @Description:- Common utility class for all the processes
**************************/
global with sharing class FSCUtilityClass implements System.Callable {
    
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
        return null;
    }
    
    //Method to get the Account Source System Id
    public static String getAccountSourceSystemId(String inputRecordId) {
        SvcCatalogRequest svcReq = [SELECT CaseId FROM SvcCatalogRequest WHERE Id =: inputRecordId WITH SECURITY_ENFORCED];
        Case caseDetail = [SELECT Id, Account.FinServ__SourceSystemId__c,AccountId FROM Case WHERE Id =: svcReq.CaseId WITH SECURITY_ENFORCED];
        String recordId = caseDetail.Account.FinServ__SourceSystemId__c;
        return recordId;
    }
    
    //Method to get the Card Source System Id
    public static Map<String, Map<String, String>> getCardsSourceSystemId(String recordId) {
        String cardNum;
        String last4Number;
        String dateStr; 
        Date dateVal;
        List<FinServ__Card__c> cardData = [SELECT Id, Card_Number__c, FinServ__ValidUntil__c, FinServ__AccountHolder__c, FinServ__SourceSystemId__c, FinServ__FinancialAccount__r.FinServ__SourceSystemId__c
                                             FROM FinServ__Card__c WHERE FinServ__AccountHolder__r.FinServ__SourceSystemId__c =: recordId WITH SECURITY_ENFORCED];
        Map<String, String> cardAttr = new Map<String, String>();
        Map<String, Map<String, String>> finalCardDetails = new Map<String, Map<String, String>>();
        Map<String, String> cardValidMap = new Map<String, String>();
        Map<String, String> cardFATypeMap = new Map<String, String>();
        
        for (FinServ__Card__c cardAttributes : cardData) {        
            cardNum = String.valueOf(cardAttributes.Card_Number__c);
            last4Number = 'XXXX-' + cardNum.right(4); 
            dateVal = cardAttributes.FinServ__ValidUntil__c;
            dateStr = dateVal.month() + '/' + dateVal.year();
            cardAttr.put(last4Number, cardAttributes.FinServ__SourceSystemId__c);
            cardValidMap.put(last4Number, dateStr);   
            cardFATypeMap.put(last4Number, cardAttributes.FinServ__FinancialAccount__r.FinServ__SourceSystemId__c);
        }  
        finalCardDetails.put('SourceSystemId', cardAttr);
        finalCardDetails.put('ValidUntill', cardValidMap);
        finalCardDetails.put('FASourceSystemId', cardFATypeMap);
        return finalCardDetails;
    }
    
    //Method to get the Financial Account Source System Id
    public static String getFinancialAccSourceSystemId(String recordId, String faNumber) {
        String faNum;
        String last4Number;
        String financialAccSourceSysId;
        List<FinServ__FinancialAccount__c> finAccList = [SELECT Id, FinServ__SourceSystemId__c, FinServ__FinancialAccountNumber__c FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__r.FinServ__SourceSystemId__c =: recordId WITH SECURITY_ENFORCED];
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
    
    //Method to get the Financial Account Role Source System Id
    public static Map<String, Map<String, String>> getFinanAccRoleSourceSystemId(String financialAccountId) {
        String mobileNumber;
        String name;
        Map<String, String> beneficiaryToDeleteAttr = new Map<String, String>();
        Map<String, String> beneficiaryToDeleteMobileMap = new Map<String, String>();
        Map<String, Map<String, String>> finalBenefToDeleteDetails = new Map<String, Map<String, String>>();

        List<FinServ__FinancialAccountRole__c> finAccRoleList = [SELECT Id, FinServ__SourceSystemId__c, FinServ__Role__c,FinServ__FinancialAccount__c, FinServ__RelatedAccount__c, FinServ__RelatedAccount__r.Name, FinServ__RelatedAccount__r.PersonMobilePhone FROM FinServ__FinancialAccountRole__c WHERE FinServ__FinancialAccount__r.FinServ__SourceSystemId__c =:financialAccountId
                                                                 AND FinServ__Role__c =:'Beneficiary' WITH SECURITY_ENFORCED];
        for (FinServ__FinancialAccountRole__c finAccObj: finAccRoleList) { 
    		name = String.valueOf(finAccObj.FinServ__RelatedAccount__r.Name);       
            mobileNumber = String.valueOf(finAccObj.FinServ__RelatedAccount__r.PersonMobilePhone);
            beneficiaryToDeleteAttr.put(name, finAccObj.FinServ__SourceSystemId__c);
            beneficiaryToDeleteMobileMap.put(name, mobileNumber);  
        }
        finalBenefToDeleteDetails.put('SourceSystemId', beneficiaryToDeleteAttr);
        finalBenefToDeleteDetails.put('Mobile', beneficiaryToDeleteMobileMap);
        return finalBenefToDeleteDetails;
    }  
}