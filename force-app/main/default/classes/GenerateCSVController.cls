public with sharing class GenerateCSVController {
    @AuraEnabled
    public static String executeBatch(String objectType, Integer months) {
        if (months == null || months <= 0) {
            throw new AuraHandledException('El número de meses debe ser mayor a 0.');
        }

        try {
            GenerateCSVBatch batch = new GenerateCSVBatch(objectType, months);
            Id batchJobId = Database.executeBatch(batch, 200);
            return 'Batch iniciado con Job ID: ' + batchJobId;
        } catch (Exception e) {
            return 'Error al ejecutar el batch: ' + e.getMessage();
        }
    }

}