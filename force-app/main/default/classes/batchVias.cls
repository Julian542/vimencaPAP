public class batchVias implements Database.Batchable<sObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> accounts = new Set<Id>();

        // Se obtienen las cuentas a las que ya le fueron cargados registros de Vias
        for(Vias_de_Contacto__c via: [
            SELECT VIA_Account__c 
            FROM Vias_de_Contacto__c 
            WHERE 
                VIA_Id_Externo_Via_bk__c = null 
                and VIA_Id_Externo_Via__c != null
        ]){
            accounts.add(via.VIA_Account__c);
        }

        // Se envian a eliminar solo los registros de Vias antiguos (Los que tienen backup del Ext ID 
        // y el campo Ext ID vacio) que esten asociados a las cuentas que ya le fueron cargados registros 
        return Database.getQueryLocator([
            SELECT id 
            FROM Vias_de_Contacto__c 
            WHERE 
                VIA_Account__c in :accounts and 
                VIA_Id_Externo_Via_bk__c != null
                and VIA_Id_Externo_Via__c = null
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Vias_de_Contacto__c> scope){

        Database.DeleteResult[] drList = Database.delete(scope, false);
        for(Database.DeleteResult dr : drList) {
            if (dr.isSuccess()) {
                System.debug('Successfully deleted Via with ID: ' + dr.getId());
            }
            else {
                for(Database.Error err : dr.getErrors()) {
                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Via fields that affected this error: ' + err.getFields());
                }
            }
        }   
    }

    public void finish(Database.BatchableContext bc){}
}