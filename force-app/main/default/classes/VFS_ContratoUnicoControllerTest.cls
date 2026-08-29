/*********************************************************************************************
 * Nombre de clase Test   :   VFS_ContratoUnicoControllerTest
 * Versión                :   1.0
 * Fecha de actualización :   13/08/2025
 * Función                :   Pruebas unitarias para la clase VFS_ContratoUnicoController
 * Clase probada          :   VFS_ContratoUnicoController
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Carlos David Ventur                13/08/2025      Versión inicial
 *********************************************************************************************/

 @isTest
public class VFS_ContratoUnicoControllerTest {

    @isTest
    static void testConDatosCompletos() {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        // Crea un account de prueba
        Account acc = new Account(
            FirstName = 'Juan',
            LastName = 'Pérez',
            ACC_CIF__c = 'CIF123',
            VFS_ActividadEconomica__c = 'Sector Agrícola',
            VFS_EspecifiqueOtro__c = 'Otro'
        );
        insert acc;

        // Crea una dirección de prueba
        Direccion__c dir = new Direccion__c(
            DIR_Account__c = acc.Id,
            DIR_Tipo_Direccion__c = 'RESIDENCIA'
        );
        insert dir;

        // Crea vía de contacto de prueba
        Vias_de_Contacto__c via = new Vias_de_Contacto__c(
            VIA_Account__c = acc.Id,
            VIA_de_Contacto__c = 'CORREO ELECTRÓNICO',
            VIA_Numero_Correo__c = 'test@correo.com'
        );
        insert via;

        // Instancia el controller
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(acc);
        VFS_ContratoUnicoController controller = new VFS_ContratoUnicoController(stdCtrl);
        controller.getDireccionJuridicaFormateada(new List<Direccion__c>{dir});


        // Verifica los datos cargados
        System.assertEquals(acc.Id, controller.cuenta.Id);
        System.assertNotEquals(null, controller.direccion);
        //System.assertEquals(dir.Id, controller.direccion.Id);
        System.assertNotEquals(null, controller.via);
        System.assertEquals(via.Id, controller.via.Id);
        System.assertNotEquals(null, controller.diaActual);
        System.assertNotEquals(null, controller.mesActual);
        System.assertNotEquals(null, controller.anioActual);
    }

    @isTest
    static void testSinDatosRelacionados() {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        // Crea un account sin relaciones
        Account acc = new Account(
            FirstName = 'Ana',
            LastName = 'García'
        );
        insert acc;

        // Instancia el controller
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(acc);
        VFS_ContratoUnicoController controller = new VFS_ContratoUnicoController(stdCtrl);
       
        // Debe retornar un objeto vacío para direccion y via
        System.assertEquals(acc.Id, controller.cuenta.Id);
        System.assertEquals(null, controller.direccion.Id);
        System.assertEquals(null, controller.via.Id);
    }
}
