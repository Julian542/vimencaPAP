trigger CompleteResolutionTimeMilestone on Case (after update) {
    if (UserInfo.getUserType() == 'Standard'){
        DateTime completionDate = System.now(); 
            List<Id> updateCases = new List<Id>();
            for (Case c : Trigger.new){
                    if ((((c.isClosed == true)||(c.Status == 'Closed'))&&((c.SlaStartDate 
                        <= completionDate)&&(c.SlaExitDate == null)))||(c.Status == 'Rechazado'))
        updateCases.add(c.Id);
        }
    if (updateCases.isEmpty() == false)
        milestoneUtils.completeMilestone(updateCases, 'SLA Cliente', completionDate);
    }
}