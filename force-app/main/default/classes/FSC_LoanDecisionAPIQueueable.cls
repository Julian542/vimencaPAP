public without sharing class FSC_LoanDecisionAPIQueueable implements Queueable, Database.AllowsCallouts{
    
    private List<Id> residentialLoanApplicationIds;
    
    public FSC_LoanDecisionAPIQueueable(List<Id> residentialLoanApplicationIds) {
        this.residentialLoanApplicationIds = new List<Id>();
        if(residentialLoanApplicationIds != null){
            this.residentialLoanApplicationIds.addAll(residentialLoanApplicationIds);
            system.debug('Ids a ejecutar ' + this.residentialLoanApplicationIds);
        }
    }

    public void execute(QueueableContext context){
        FSC_LoanDecisionAPI.callAPI(residentialLoanApplicationIds);
    }
}