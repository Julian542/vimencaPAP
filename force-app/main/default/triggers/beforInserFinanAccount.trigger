trigger beforInserFinanAccount on Asset (before update,before insert) {
    String productAccountID = '';  
    for(Asset newProduct : Trigger.New) {
        //Si el nombre del producto es igual al numero de cuenta
        // quiere decir que la clase wsCreacionProd recibio la trama de respuesta correctamente
        if(newProduct.Name == newProduct.ASE_N_de_cuenta__c){                         
           productAccountID = newProduct.AccountId;            
        }
    }
    if(productAccountID!=''){
        List<Account> productAccount = [SELECT id, ACC_Estado__c 
                                  FROM Account 
                                  WHERE id=:productAccountID 
                                 	AND ACC_Condicion__c='CLIENTE'
                                 	AND Account.ACC_Estado__c='CREADO'];
        if(productAccount.size()!=0){
            System.debug('PASO!!!!!!!');
            productAccount[0].ACC_Estado__c='ACTIVO';
            update productAccount; 
        }    
    }   
}