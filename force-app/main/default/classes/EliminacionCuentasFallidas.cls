global class EliminacionCuentasFallidas implements Schedulable, Database.Batchable<sObject>{    

    public static Integer batchSize = 200;

    private static Map<Id, String> mapErrors;

    global void execute(SchedulableContext sc){

        Database.executeBatch(new EliminacionCuentasFallidas(), batchSize);
    } 

    global Database.QueryLocator start(Database.BatchableContext bc) {

        Date todayDT = Date.today();
        mapErrors= new Map<Id, String>();

        return Database.getQueryLocator('SELECT Id, (SELECT id FROM Cases) FROM Asset WHERE ASE_Estado__c=\'PTE. APERTURA\' AND ASE_Fecha_de_apertura__c= null AND CreatedDate<=:todayDT AND (ASE_N_de_cuenta__c != null OR Es_Numero_Diferente__c=False) ');
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope){
        
        List<Id> idsToDelete = new List<Id>();
        List<Id> idAsset = new List<Id>();
        for(Asset a : (List<Asset>) scope){
            idAsset.add(a.Id);
            for(Case c : a.Cases){
                idsToDelete.add(c.Id);
            }
        }

        idsToDelete.addAll(idAsset);
        List<Database.DeleteResult> sr = Database.delete(idsToDelete, false);

        for(Database.DeleteResult r : sr){

            if(!r.isSuccess()){
                String errorStr = '';
                for(Database.Error rError : r.getErrors()){
                        errorStr+= rError.getMessage()+'; ';
                }
                
                mapErrors.put(r.getId(),errorStr);

            }
        }

    }

    global void finish(Database.BatchableContext bc){

    }
    
    
}