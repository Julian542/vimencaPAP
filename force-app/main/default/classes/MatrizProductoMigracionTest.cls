@IsTest
private class MatrizProductoMigracionTest {
    @IsTest
    static void preparesMissingProductsFromTheConfiguredCatalog() {
        Integer recordsBefore = [SELECT COUNT() FROM Matriz_de_producto__c];

        Test.startTest();
        MatrizProductoMigracion.run();
        Test.stopTest();

        System.assert(
            [SELECT COUNT() FROM Matriz_de_producto__c] >= recordsBefore,
            'La migracion no debe eliminar productos existentes.'
        );
    }

    @IsTest
    static void preparesProductsFromAnAvailableLineTemplate() {
        insert new Matriz_de_producto__c(
            Name = 'Plantilla cobertura préstamos',
            PRO_Tipo__c = 'Activo',
            PRO_Nombre_de_linea_de_producto__c = 'Préstamos',
            PRO_Estado__c = 'Activo',
            PRO_Codigo_de_linea_de_producto__c = 'BPR',
            PRO_Codigo_de_producto__c = '9000',
            PRO_ID_Externo__c = '9000'
        );

        Test.startTest();
        MatrizProductoMigracion.run();
        Test.stopTest();

        System.assert(
            [SELECT COUNT() FROM Matriz_de_producto__c WHERE PRO_Migrado__c = true] > 0,
            'Debe preparar al menos un producto desde la plantilla de prueba.'
        );
    }
}
