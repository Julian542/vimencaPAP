public class batchDatosFinancieros implements Database.Batchable<sObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<Id> accounts = new Set<Id>();

        // Se obtienen las cuentas a las que ya le fueron cargados registros de Datos Financieros
        for(Informacion_Financiera__c inf: [
            SELECT INF_Cuenta__c 
            from Informacion_Financiera__c 
            where 
                INF_Id_Externo_Inf_bk__c = null 
                and INF_Id_Externo_Inf__c != null
        ]){
            accounts.add(inf.INF_Cuenta__c);
        }

        // Se envian a eliminar solo los registros de Datos Financieros antiguos (Los que tienen backup del Ext ID 
        // y el campo Ext ID vacio) que esten asociados a las cuentas que ya le fueron cargados registros 
        return Database.getQueryLocator([
            Select id 
            from Informacion_Financiera__c 
            where 
                INF_Cuenta__c in :accounts
                and INF_Id_Externo_Inf__c = null 
                and INF_Id_Externo_Inf_bk__c != null
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Informacion_Financiera__c> scope){

        Database.DeleteResult[] drList = Database.delete(scope, false);
        for(Database.DeleteResult dr : drList) {
            if (dr.isSuccess()) {
                System.debug('Successfully deleted Inf with ID: ' + dr.getId());
            }
            else {
                for(Database.Error err : dr.getErrors()) {
                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Inf fields that affected this error: ' + err.getFields());
                }
            }
        }   
    }

    public void finish(Database.BatchableContext bc){}
}