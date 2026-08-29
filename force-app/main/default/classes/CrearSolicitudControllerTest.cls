@isTest
public class CrearSolicitudControllerTest {
    
    @isTest
    static void crearSolicitudTest() {
        
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        TestDataFactoryPrestamos.createTestData();
        
        // To specify fake response for a certain endpoint and include response body in a static resource.
        
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();        
        multimock.setStaticResource('callout:DataCreditoWS/getDecisionEngine', 'prestamoConsumo');
        multimock.setStaticResource('callout:DataCreditoWS/GetVehicular', 'prestamoVehiculo');
        multimock.setStaticResource('callout:DataCreditoWS/CreateCases', 'crearSolicitud');
        multimock.setStaticResource('callout:DataCreditoWS/CalCuotas', 'consultaMontos');
        multimock.setStaticResource('callout:DataCreditoWS/ConsultaEstado', 'sincronizarSolicitud');
        multimock.setStaticResource(Label.EndpointWs, 'INT007_request_frame');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, multimock);
        
        String oppId = [Select Id from Opportunity limit 1]?.Id;
        
        Test.startTest();
        String resp = CrearSolicitudController.crearSolicitud(oppId);
        Test.stopTest();
    }

    @isTest
    static void crearSolicitudTestValidate() {
        
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        List<Account> clientes = TestDataFactoryPrestamos.crearClientePF(1, true);
        Opportunity opp = TestDataFactoryPrestamos.crearOportunidadWithProduct(clientes[0]?.Id, null, true);
        
        // To specify fake response for a certain endpoint and include response body in a static resource.
        
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();        
        multimock.setStaticResource('callout:DataCreditoWS/getDecisionEngine', 'prestamoConsumo');
        multimock.setStaticResource('callout:DataCreditoWS/GetVehicular', 'prestamoVehiculo');
        multimock.setStaticResource('callout:DataCreditoWS/CreateCases', 'crearSolicitud');
        multimock.setStaticResource('callout:DataCreditoWS/CalCuotas', 'consultaMontos');
        multimock.setStaticResource('callout:DataCreditoWS/ConsultaEstado', 'sincronizarSolicitud');
        multimock.setStaticResource(Label.EndpointWs, 'INT007_request_frame');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, multimock);
        
        String oppId = [Select Id from Opportunity limit 1]?.Id;
        
        Test.startTest();
        String resp = CrearSolicitudController.crearSolicitud(oppId);
        Test.stopTest();
    }
    
    @isTest
    static void validarSolicitudTestValidate() {
        
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        List<Account> clientes = TestDataFactoryPrestamos.crearClientePF(1, true);
        Opportunity opp = TestDataFactoryPrestamos.crearOportunidadWithProduct(clientes[0]?.Id, null, true);
                
        String oppId = [Select Id from Opportunity limit 1]?.Id;
        
        CrearSolicitudHelper.Input data = new CrearSolicitudHelper.Input();
        data.account = new Account();
        data.facilidad = new Matriz_de_producto__c();
        data.opportunity = new opportunity();
        
        Test.startTest();
        CrearSolicitudHelper.validar(data);
        Test.stopTest();
    }

    
}
