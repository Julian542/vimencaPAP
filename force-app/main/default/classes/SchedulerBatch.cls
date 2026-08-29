global class SchedulerBatch implements Schedulable {    
   global void execute(SchedulableContext SC) {
   batchDatosFinancieros batch1 = new batchDatosFinancieros();
   Id batchId1 = Database.executeBatch(batch1);

   batchDirecciones batch2 = new batchDirecciones();
   Id batchId2 = Database.executeBatch(batch2);

   batchHistorialLaboral batch3= new batchHistorialLaboral();
   Id batchId3 = Database.executeBatch(batch3);

   batchReferencias batch4 = new batchReferencias();
   Id batchId4 = Database.executeBatch(batch4);

   batchVias batch5 = new batchVias();
   Id batchId5 = Database.executeBatch(batch5);       
   }
}