global class CaducarDocumentos implements Schedulable{    
    global void execute(SchedulableContext sc){
        Datetime ayer=system.now();
        ayer = ayer.addDays(-1);
       // System.debug(ayer);
        List<Documentacion_Legal__c> documentExpiration =[SELECT id 
                                     FROM Documentacion_Legal__c 
                                     WHERE DOC_Fecha_Vencimiento__c<=:ayer.date()]; 
        delete documentExpiration;     
    }   
}