@isTest
private class SucursalesPrincipalesActionTest {

    @isTest
    static void testExecute() {

        List<Sucursal__c> sucursales = new List<Sucursal__c>();

        sucursales.add(new Sucursal__c(
            Name = 'Banco Múltiple Vimenca - Santiago',
            External_ID__c = '1',
            SUC_Active__c = true,

            // Tipo
            SUC_BranchType__c = 'Sucursal',

            // Dirección requerida por validation rule
            SUC_Country__c = 'República Dominicana',
            SUC_Province__c = 'Santiago',
            SUC_City__c = 'Santiago',
            SUC_Street__c = 'Av. Principal',
            SUC_Neighborhood__c = 'Centro',
            SUC_Address__c = 'Av. Principal #123',

            // Otros campos
            SUC_Phone__c = '8091111111',
            Horarios__c = '8AM - 5PM'
        ));

        sucursales.add(new Sucursal__c(
            Name = 'Banco Múltiple Vimenca - San Cristóbal',
            External_ID__c = '2',
            SUC_Active__c = true,

            SUC_BranchType__c = 'Sucursal',

            SUC_Country__c = 'República Dominicana',
            SUC_Province__c = 'San Cristóbal',
            SUC_City__c = 'San Cristóbal',
            SUC_Street__c = 'Calle Central',
            SUC_Neighborhood__c = 'Zona Colonial',
            SUC_Address__c = 'Calle Central #456',

            SUC_Phone__c = '8092222222',
            Horarios__c = '8AM - 5PM'
        ));

        insert sucursales;

        SucursalesPrincipalesAction.Request req =
            new SucursalesPrincipalesAction.Request();

        req.dummy = 'test';

        Test.startTest();

        List<List<SucursalesPrincipalesAction.Response>> result =
            SucursalesPrincipalesAction.execute(
                new List<SucursalesPrincipalesAction.Request>{ req }
            );

        Test.stopTest();

        // Validaciones
        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
        System.assertEquals(2, result[0].size());

        System.assertEquals(
            'Banco Múltiple Vimenca - Santiago',
            result[0][0].nombre
        );
    }
}