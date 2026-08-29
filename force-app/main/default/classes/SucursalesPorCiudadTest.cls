@isTest
private class SucursalesPorCiudadTest {

    @isTest
    static void testExecute() {

        List<Sucursal__c> sucursales = new List<Sucursal__c>();

        // ✅ Sucursal con horarios
        sucursales.add(new Sucursal__c(
            Name = 'Banco Vimenca Santiago Centro',
            External_ID__c = '100',
            SUC_Active__c = true,

            SUC_BranchType__c = 'Sucursal',

            SUC_Country__c = 'República Dominicana',
            SUC_Province__c = 'Santiago',
            SUC_City__c = 'Santiago',
            SUC_Street__c = 'Av. Principal',
            SUC_Neighborhood__c = 'Centro',
            SUC_Address__c = 'Av. Principal #123',

            Horarios__c = '8AM - 5PM'
        ));

        // ✅ Sucursal sin horarios
        sucursales.add(new Sucursal__c(
            Name = 'Banco Vimenca Santiago Norte',
            External_ID__c = '101',
            SUC_Active__c = true,

            SUC_BranchType__c = 'Sucursal',

            SUC_Country__c = 'República Dominicana',
            SUC_Province__c = 'Santiago',
            SUC_City__c = 'Santiago',
            SUC_Street__c = 'Calle Norte',
            SUC_Neighborhood__c = 'Zona Norte',
            SUC_Address__c = 'Calle Norte #456'
        ));

        // ❌ No debería venir porque está inactiva
        sucursales.add(new Sucursal__c(
            Name = 'Banco Vimenca Santiago Inactiva',
            External_ID__c = '102',
            SUC_Active__c = false,

            SUC_BranchType__c = 'Sucursal',

            SUC_Country__c = 'República Dominicana',
            SUC_Province__c = 'Santiago',
            SUC_City__c = 'Santiago',
            SUC_Street__c = 'Calle Inactiva',
            SUC_Neighborhood__c = 'Zona Oeste',
            SUC_Address__c = 'Calle Inactiva #789'
        ));

        // ❌ No debería venir porque es otra ciudad
        sucursales.add(new Sucursal__c(
            Name = 'Banco Vimenca Punta Cana',
            External_ID__c = '103',
            SUC_Active__c = true,

            SUC_BranchType__c = 'Sucursal',

            SUC_Country__c = 'República Dominicana',
            SUC_Province__c = 'Punta Cana',
            SUC_City__c = 'Punta Cana',
            SUC_Street__c = 'Av. Bavaro',
            SUC_Neighborhood__c = 'Centro',
            SUC_Address__c = 'Av. Bavaro #999'
        ));

        insert sucursales;

        // Request
        SucursalesPorCiudad.Request req =
            new SucursalesPorCiudad.Request();

        req.ciudad = 'Santiago';

        Test.startTest();

        List<List<SucursalesPorCiudad.Response>> result =
            SucursalesPorCiudad.execute(
                new List<SucursalesPorCiudad.Request>{ req }
            );

        Test.stopTest();

        // Validaciones
        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());

        List<SucursalesPorCiudad.Response> responses = result[0];

        // Solo deben venir 2
        System.assertEquals(2, responses.size());

        // La que tiene horarios debe venir primero
        System.assertEquals(
            'Banco Vimenca Santiago Centro',
            responses[0].nombre
        );

        System.assertEquals(
            '8AM - 5PM',
            responses[0].horarios
        );

        // Validar segunda sucursal
        System.assertEquals(
            'Banco Vimenca Santiago Norte',
            responses[1].nombre
        );
    }
}