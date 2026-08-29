public class batchDirecciones implements Database.Batchable<sObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> accounts = new Set<Id>();

        // Se obtienen las cuentas a las que ya le fueron cargados registros de Direcciones
        for(Direccion__c dir: [
            SELECT DIR_Account__c 
            from Direccion__c 
            where 
                DIR_Id_Externo_Direccion_bk__c = null 
                and DIR_Id_Externo_Direccion__c != null
        ]){
            accounts.add(dir.DIR_Account__c);
        }

        // Se envian a eliminar solo los registros de Direcciones antiguos (Los que tienen backup del Ext ID 
        // y el campo Ext ID vacio) que esten asociados a las cuentas que ya le fueron cargados registros 
        return Database.getQueryLocator([
            Select id 
            from Direccion__c 
            where 
                DIR_Account__c in :accounts 
                and DIR_Id_Externo_Direccion__c = null 
                and DIR_Id_Externo_Direccion_bk__c != null
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Direccion__c> scope){

        Database.DeleteResult[] drList = Database.delete(scope, false);
        for(Database.DeleteResult dr : drList) {
            if (dr.isSuccess()) {
                System.debug('Successfully deleted Dir with ID: ' + dr.getId());
            }
            else {
                for(Database.Error err : dr.getErrors()) {
                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Dir fields that affected this error: ' + err.getFields());
                }
            }
        }   
    }

    public void finish(Database.BatchableContext bc){}
}