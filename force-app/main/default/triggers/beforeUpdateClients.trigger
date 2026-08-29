trigger beforeUpdateClients on Account (before update,before insert) {
    // beforeUpdateClientsHelper helper=new beforeUpdateClientsHelper();       
    // List<Account> recordTOld = new List<Account>();
    // String username= UserInfo.getUserName();
    // Bypass_Trigger__c btInstance = Bypass_Trigger__c.getInstance();
    // List<String> listUsersBypass= (btInstance.Usernames_Allowed__c!=null)? btInstance.Usernames_Allowed__c.split(';'): new List<String>();
    // //Account recordTCondition ;
    // if(Trigger.isUpdate){
    //     for(Account a : Trigger.old) {
    //         //  recordTCondition= [SELECT id, RecordType.name, ACC_Condicion__c, ACC_Estado__c FROM Account WHERE id = :a.Id];                    
    //         recordTOld.add(a);
    //     }
    // }
    // for(Account recordT : Trigger.New) {
    //     System.debug('For');
    //     if(Trigger.isUpdate){
    //         System.debug('Trigger isUpdate');
    //         if(!listUsersBypass.contains(username)){
    //             System.debug('Entrando a HelperUpdateCIF');
    //             helper.updateCIF(recordT,recordTOld[0]);
    //         }      
    //         // helper.CalculateClasification(recordT, oldClientType,oldOrganitationtType);
    //         // helper.updateCIF(recordT,recordTCondition[0],personAccountAndProspect);        
    //         helper.CalculateClasification(recordT, recordTOld[0]);
    //         helper.Traducir_Valores_Cliente(recordT);
    //     }
    //     if(Trigger.isInsert){
    //         system.debug('@@USER'+UserInfo.getLastName());
    //         helper.Traducir_Valores_Cliente(recordT);
    //     }        
    // }    
}