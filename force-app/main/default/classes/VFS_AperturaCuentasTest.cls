/*********************************************************************************************
 * Nombre de clase Test   :   VFS_AperturaCuentasTest
 * Versión                :   1.0
 * Fecha de creación      :   30/06/2025
 * Función                :   Pruebas unitarias para VFS_AperturaCuentasController
 * Clase probada          :   VFS_AperturaCuentasController
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Edgar H. Luna                        30/06/2025      Versión inicial
 *********************************************************************************************/

@isTest
private class VFS_AperturaCuentasTest {

    private static Account createAccount(String name, String email, String documentNumber) {
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = name,
            ACC_Correo_Electronico_Cliente__c = email,
            ACC_NumIdentificacion__c = documentNumber,
            ACC_RNC__c = documentNumber,
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert account;
        return account;
    }

    @isTest
    static void testControllerAndGetters() {
        // Arrange: crear Account y Asset relacionados
        Account acc = createAccount('Titular Test', 'testuser@example.com', '131000008');
        Asset ast = new Asset(Name = 'AssetTest', AccountId = acc.Id);
        insert ast;
        ApexPages.StandardController sc = new ApexPages.StandardController(ast);

        // Crear un Historial_laboral__c relacionado para evitar QueryException
        Historial_laboral__c hist = new Historial_laboral__c(HIS_Empleo__c = 'Actual', HIS_Cuenta__c = acc.Id, HIS_Empresa__c = 'Empresa Test');
        insert hist;

        // Act
        VFS_AperturaCuentasController ctrl = new VFS_AperturaCuentasController(sc);

        // Assert básicos
        System.assertNotEquals(null, ctrl.accountTitular, 'Debe asignar el titular');
        System.assertEquals(false, ctrl.isFisica, 'No debe detectar persona física si no hay PersonContactId');

        // Cobertura de getters públicos
        ctrl.getDireccionesTitular();
        ctrl.getDireccionesFirmaConjunta();
        ctrl.getViasOrdenadasTitular();
        ctrl.getViasOrdenadasFirmaConjunta();
        ctrl.getHistorialLaboralTitular();
        ctrl.getHistorialLaboralFirmaConjunta();
        ctrl.getLstReferenciasBancarias();
        ctrl.getLstReferenciasComerciales();
        // Cobertura de consultarVinculadoAprobado
        ctrl.consultarVinculadoAprobado();
    }

    @isTest
    static void testConsultarVinculadoAprobado_Autorizado() {
        // Arrange: crear Account principal y autorizado
        Account acc = createAccount('Titular Test', 'testuser@example.com', '131000009');
        Account autorizado = createAccount('Autorizado Uno', 'autorizado@example.com', '131000010');
        Direccion__c nuevaDireccion = new Direccion__c(
            DIR_Calle__c = 'Avenida Profesor Juan Bosch #1842, Edificio Residencial Los Jardines del Este',
            DIR_Numero__c = '23',
            DIR_Edificio__c = '2t',
            DIR_N_Apartamento__c = '323',
            DIR_Provincia_texto__c = '32',
            DIR_Account__c = autorizado.Id
        );
        insert nuevaDireccion;

        System.debug('autorizado.ACC_NumIdentificacion__c: ' + autorizado.ACC_NumIdentificacion__c);
        Vias_de_Contacto__c viaAut = new Vias_de_Contacto__c(VIA_Account__c = autorizado.Id, VIA_de_Contacto__c = 'CORREO ELECTRÓNICO', VIA_Numero_Correo__c = 'autorizado@example.com', VIA_Principal__c = true);
        insert viaAut;
        Vias_de_Contacto__c viaAuttel = new Vias_de_Contacto__c(VIA_Account__c = autorizado.Id, VIA_de_Contacto__c = 'TELÉFONO TRABAJO', VIA_Numero_Correo__c = '1341241243142', VIA_Principal__c = true);
        insert viaAuttel;
        Vias_de_Contacto__c viaAut2 = new Vias_de_Contacto__c(VIA_Account__c = acc.Id, VIA_de_Contacto__c = 'CORREO ELECTRÓNICO', VIA_Numero_Correo__c = 'autorizado@example.com', VIA_Principal__c = true);
        insert viaAut2;
        Asset ast = new Asset(Name = 'AssetTest', AccountId = acc.Id);
        insert ast;
        ApexPages.StandardController sc = new ApexPages.StandardController(ast);
        // Simular respuesta INT026
        VFS_AperturaCuentasController.testResponse = new INT026.Response();
        VFS_AperturaCuentasController.testResponse.responseList = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Vinculo' => 'AUTORIZADO',
                'NombreCompleto' => autorizado.Name, // Debe coincidir con el Name del Account autorizado
                'NumeroDocumento' => autorizado.ACC_NumIdentificacion__c, // Debe coincidir con el campo en Account
                'DarGarantia' => 'Y'
            }
        };
        // Act
        VFS_AperturaCuentasController ctrl = new VFS_AperturaCuentasController(sc);
        ctrl.consultarVinculadoAprobado();
        System.debug('ctrl.tipoFirma: ' + ctrl.tipoFirma);
        // Assert
       ctrl.obtenerFirmantesAutorizados(ast.Id);
       ctrl.formatearDireccion(nuevaDireccion);
       ctrl.getPrimeraFirmaConjunta();
       ctrl.getViasOrdenadasSegundaFirmaConjunta();
       ctrl.getHistorialLaboralSegundaFirmaConjunta();
       ctrl.getDireccionesSegundaFirmaConjunta();

    }
}
