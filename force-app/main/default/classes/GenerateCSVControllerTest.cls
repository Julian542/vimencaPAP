@isTest
private class GenerateCSVControllerTest {

    @TestSetup
    static void makeData(){
        INT_Request__c request = new INT_Request__c();
        request.Funci_n__c = 'test funcion';
        request.Integraci_n__c = '11';
        request.Trama_de_env_o__c = 'test trama de envio';
        insert request;

        INT_Response__c response = new INT_Response__c();
        response.INT_Request__c = request.Id;
        response.Http_Status_Code__c = 200;
        response.Status__c = 'Success';
        response.Trama_de_respuesta__c = 'test trama de respuesta';
        insert response;
    }

    @isTest
    static void startBatchRequest() {
        Integer months = 3;
        String objectType = 'INT_Request__c';
        Test.startTest();
        GenerateCSVController.executeBatch(objectType, months);
        Test.stopTest();
    }

    @isTest
    static void startBatchResponse() {
        Integer months = 3;
        String objectType = 'INT_Response__c';
        Test.startTest();
        GenerateCSVController.executeBatch(objectType, months);
        Test.stopTest();
    }

    @isTest
    static void errorMonthsNull() {
        Integer months = null;
        String objectType = 'INT_Response__c';

        Test.startTest();
        try {
            GenerateCSVController.executeBatch(objectType, months);
            System.assert(false, 'Se esperaba que se lanzara una excepción');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'El mensaje de error no coincide');
        }
        Test.stopTest();
    }

    @isTest
    static void executeScheduleBatchRequest() {
        Integer months = 3;
        String objectType = 'Request';

        Test.startTest();
        GenerateCSVBatchScheduler.startBatch(objectType, months);
        Test.stopTest();
    }

    @isTest
    static void executeScheduleBatchResponse() {
        Integer months = 3;
        String objectType = 'Response';

        Test.startTest();
        GenerateCSVBatchScheduler.startBatch(objectType, months);
        Test.stopTest();
    }
}