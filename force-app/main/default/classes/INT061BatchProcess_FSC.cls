/**
 * @description       : an adapted version of INT061BatchProcess to Fin Serv Cloud
 * @author            : lplatino@keystoneadvisors.cl
 * @group             : 
 * @last modified on  : 10-01-2026
 * @last modified by  : lplatino@keystoneadvisors.cl
**/
@SuppressWarnings('PMD')
global with sharing class INT061BatchProcess_FSC implements Schedulable{
    global void execute(SchedulableContext sc){
        INT061_FSC.UpdateListOfBanks();
    }
}