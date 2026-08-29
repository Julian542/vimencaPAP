public class batchReferencias implements Database.Batchable<sObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> accounts = new Set<Id>();

        // Se obtienen las cuentas a las que ya le fueron cargados registros de Referencias
        for(Referencia__c ref: [
            SELECT Account__c 
            FROM Referencia__c 
            WHERE 
                REF_Id_Externo_bk__c = null 
                and REF_Id_Externo__c != null
        ]){
            accounts.add(ref.Account__c);
        }

        // Se envian a eliminar solo los registros de Referencia antiguos (Los que tienen backup del Ext ID 
        // y el campo Ext ID vacio) que esten asociados a las cuentas que ya le fueron cargados registros 
        return Database.getQueryLocator([
            SELECT id 
            FROM Referencia__c 
            WHERE 
                Account__c in :accounts 
                and REF_Id_Externo_bk__c != null
                and REF_Id_Externo__c = null
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Referencia__c> scope){

        Database.DeleteResult[] drList = Database.delete(scope, false);
        for(Database.DeleteResult dr : drList) {
            if (dr.isSuccess()) {
                System.debug('Successfully deleted Ref with ID: ' + dr.getId());
            }
            else {
                for(Database.Error err : dr.getErrors()) {
                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Ref fields that affected this error: ' + err.getFields());
                }
            }
        }   
    }

    public void finish(Database.BatchableContext bc){}
}