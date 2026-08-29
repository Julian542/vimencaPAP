/*********************************************************************************************
 * Nombre de clase Test   :   VFS_ResumenConvenioUnicoTest
 * Versión                :   1.0
 * Fecha de actualización :   15/07/2025
 * Función                :   Pruebas unitarias para la clase VFS_ResumenConvenioUnico
 * Clase probada          :   VFS_ResumenConvenioUnico
 *
 * Registro de modificaciones:
 * ---------------------------------------------------------------------------------------------------
 * Desarrollador                        Fecha           Descripción
 * Carlos David Ventura               15/07/2025      Versión inicial
 *********************************************************************************************/

 @isTest
public class VFS_ResumenConvenioUnicoTest {

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
            DIR_Estado_Ciudad__c = 'Test City',
            DIR_Calle__c = 'Test Street',
            DIR_Numero__c = '123',
            DIR_Edificio__c = 'Test Building',
            DIR_Direccion_Traduccion__c = 'Test Translation',
            DIR_N_Apartamento__c = '123',
            DIR_Distrito_texto__c = 'SANTO DOMINGO OESTE',
            DIR_Municipio_texto__c = 'SANTO DOMINGO OESTE',
            DIR_Provincia_texto__c = 'SANTO DOMINGO',
            DIR_Pais__c = 'DO'
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
        VFS_ResumenConvenioUnicoController controller = new VFS_ResumenConvenioUnicoController(stdCtrl);
        controller.getDireccionJuridicaFormateada(new List<Direccion__c>{dir});
    }
}
