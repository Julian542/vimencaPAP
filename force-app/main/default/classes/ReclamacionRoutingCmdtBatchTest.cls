@IsTest
private class ReclamacionRoutingCmdtBatchTest {
    @IsTest
    static void buildsAllConfiguredRecordsWithoutDeployingMetadata() {
        Test.startTest();
        Integer totalBatches = ReclamacionRoutingCmdtBatch.getTotalBatches();
        Id jobId = ReclamacionRoutingCmdtBatch.runBatch(totalBatches + 1);
        Test.stopTest();

        System.assert(totalBatches > 0, 'Debe existir al menos un lote configurado.');
        System.assertEquals(null, jobId, 'Un lote posterior al ultimo no debe desplegar metadata.');
    }

    @IsTest
    static void rejectsInvalidBatchArguments() {
        Boolean invalidBatchNumberRejected = false;
        try {
            ReclamacionRoutingCmdtBatch.runBatch(0);
        } catch (AuraHandledException expected) {
            invalidBatchNumberRejected = true;
        }

        Boolean invalidBatchSizeRejected = false;
        try {
            ReclamacionRoutingCmdtBatch.runBatch(1, 0);
        } catch (AuraHandledException expected) {
            invalidBatchSizeRejected = true;
        }

        System.assert(invalidBatchNumberRejected, 'Debe rechazar numeros de lote no positivos.');
        System.assert(invalidBatchSizeRejected, 'Debe rechazar tamanos de lote no positivos.');
    }
}
