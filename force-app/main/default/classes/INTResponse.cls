public virtual class INTResponse {
	@AuraEnabled public Integer requestStatusCode;
    @AuraEnabled public String requestStatus;
    @AuraEnabled public String ErrorCode = '';
    @AuraEnabled public String ErrorText = '';
    
    @AuraEnabled public Map<String, Object> values = new Map<String, Object>();
}