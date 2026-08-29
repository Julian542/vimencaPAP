public class batchHistorialLaboral implements Database.Batchable<sObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> accounts = new Set<Id>();
        
        // Se obtienen las cuentas a las que ya le fueron cargados registros de Historial Laboral
        for(Historial_laboral__c his: [
            SELECT HIS_Cuenta__c 
            FROM Historial_laboral__c 
            WHERE 
                HIS_Id_Externo_Historial_bk__c = null 
                and HIS_Id_Externo_Historial__c != null
        ]){
            accounts.add(his.HIS_Cuenta__c);
        }

        // Se envian a eliminar solo los registros de Historial Laboral antiguos (Los que tienen backup del Ext ID 
        // y el campo Ext ID vacio) que esten asociados a las cuentas que ya le fueron cargados registros 
        return Database.getQueryLocator([
            SELECT id 
            FROM Historial_laboral__c 
            WHERE 
                HIS_Cuenta__c in :accounts 
                and HIS_Id_Externo_Historial__c = null 
                and HIS_Id_Externo_Historial_bk__c != null
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Historial_laboral__c> scope){

        Database.DeleteResult[] drList = Database.delete(scope, false);
        for(Database.DeleteResult dr : drList) {
            if (dr.isSuccess()) {
                System.debug('Successfully deleted His with ID: ' + dr.getId());
            }
            else {
                for(Database.Error err : dr.getErrors()) {
                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('His fields that affected this error: ' + err.getFields());
                }
            }
        }   
    }

    public void finish(Database.BatchableContext bc){}
}