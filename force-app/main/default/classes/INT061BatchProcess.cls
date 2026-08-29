global class INT061BatchProcess implements Schedulable{
    
    global void execute(SchedulableContext sc){
        INT061.UpdateListOfBanks();
    }
    
}