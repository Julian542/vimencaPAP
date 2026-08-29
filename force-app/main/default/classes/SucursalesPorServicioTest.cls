@isTest
private class SucursalesPorServicioTest {

    @isTest
    static void testExecute() {

        List<Sucursal__c> sucursales = new List<Sucursal__c>();

        //  Debe aparecer
        sucursales.add(new Sucursal__c(
            Name = 'Banco Vimenca Santiago Centro',
            External_ID__c = '200',
            SUC_Active__c = true,

            SUC_BranchType__c = 'Sucursal',

            // Dirección obligatoria
            SUC_Country__c = 'República Dominicana',
            SUC_Province__c = 'Santiago',
            SUC_City__c = 'Santiago',
            SUC_Street__c = 'Av Principal',
            SUC_Neighborhood__c = 'Centro',
            SUC_Address__c = 'Av Principal #123',

            Horarios__c = '8AM - 5PM',

            // Valores reales del multipicklist
            SUC_ServicesOffered__c = 'Paga Todo;Banco Vimenca'
        ));

        //  Otro servicio
        sucursales.add(new Sucursal__c(
            Name = 'Sucursal Remesas',
            External_ID__c = '201',
            SUC_Active__c = true,

            SUC_BranchType__c = 'Sucursal',

            SUC_Country__c = 'República Dominicana',
            SUC_Province__c = 'Santiago',
            SUC_City__c = 'Santiago',
            SUC_Street__c = 'Calle 2',
            SUC_Neighborhood__c = 'Norte',
            SUC_Address__c = 'Calle 2 #456',

            SUC_ServicesOffered__c = 'Remesas Vimenca'
        ));

        //  Otra ciudad
        sucursales.add(new Sucursal__c(
            Name = 'Sucursal Punta Cana',
            External_ID__c = '202',
            SUC_Active__c = true,

            SUC_BranchType__c = 'Sucursal',

            SUC_Country__c = 'República Dominicana',
            SUC_Province__c = 'Punta Cana',
            SUC_City__c = 'Punta Cana',
            SUC_Street__c = 'Av Bavaro',
            SUC_Neighborhood__c = 'Centro',
            SUC_Address__c = 'Av Bavaro #999',

            SUC_ServicesOffered__c = 'Paga Todo'
        ));

        //  Inactiva
        sucursales.add(new Sucursal__c(
            Name = 'Sucursal Inactiva',
            External_ID__c = '203',
            SUC_Active__c = false,

            SUC_BranchType__c = 'Sucursal',

            SUC_Country__c = 'República Dominicana',
            SUC_Province__c = 'Santiago',
            SUC_City__c = 'Santiago',
            SUC_Street__c = 'Calle 3',
            SUC_Neighborhood__c = 'Sur',
            SUC_Address__c = 'Calle 3 #789',

            SUC_ServicesOffered__c = 'Paga Todo'
        ));

        insert sucursales;

        // Request
        SucursalesPorServicio.Request req =
            new SucursalesPorServicio.Request();

        req.ciudad = 'Santiago';

        // Probamos normalización
        req.servicio = 'pagatodo';

        Test.startTest();

        List<List<SucursalesPorServicio.Response>> result =
            SucursalesPorServicio.execute(
                new List<SucursalesPorServicio.Request>{ req }
            );

        Test.stopTest();

        // Validaciones
        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());

        List<SucursalesPorServicio.Response> responses = result[0];

        // Solo debe venir 1
        System.assertEquals(1, responses.size());

        System.assertEquals(
            'Banco Vimenca Santiago Centro',
            responses[0].nombre
        );

        // Validar multipicklist sin depender del orden
        System.assert(
            responses[0].servicios.contains('Paga Todo')
        );

        System.assert(
            responses[0].servicios.contains('Banco Vimenca')
        );
    }
}