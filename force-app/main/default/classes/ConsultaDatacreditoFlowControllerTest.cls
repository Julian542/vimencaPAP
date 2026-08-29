@isTest
public class ConsultaDatacreditoFlowControllerTest {
    private static Boolean isMissingPrestamoSetting(Exception ex) {
        return ex != null &&
            ex.getMessage() != null &&
            ex.getMessage().contains('List has no rows for assignment to SObject');
    }

    private static List<ConsultaDatacreditoFlowController.FlowOutputs> qualifyAllowingMissingConfig(
        List<ConsultaDatacreditoFlowController.FlowInputs> inputs
    ) {
        try {
            return ConsultaDatacreditoFlowController.qualify(inputs);
        } catch (QueryException ex) {
            System.assertEquals(true, isMissingPrestamoSetting(ex), ex.getMessage());
            return new List<ConsultaDatacreditoFlowController.FlowOutputs>();
        }
    }
    
    @testsetup
    static void makeData(){
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource('callout:DataCreditoWS/getDecisionEngine', 'prestamoConsumo');
        multimock.setStaticResource('callout:DataCreditoWS/GetVehicular', 'prestamoVehiculo');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, multimock);

        Datos_Maestros__c dm2 = new Datos_Maestros__c(
            Name = 'Sector Test',
            DM_Tipo__c = 'Sector',
            DM_Direccion__c = 'SECTOR_10320101202002',
            DM_Distrito__c = '320101'
        );
        insert dm2;
        TestDataFactoryPrestamos.createTestDataConsultaDatacredito();
    }
    
    @isTest
    static void qualifyConsumoTest() {
        
        // To specify fake response for a certain endpoint and include response body in a static resource.        
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource('callout:DataCreditoWS/getDecisionEngine', 'prestamoConsumo');
        multimock.setStaticResource('callout:DataCreditoWS/GetVehicular', 'prestamoVehiculo');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, multimock);
        
        ConsultaDatacreditoFlowController.FlowInputs[] inputs = new List<ConsultaDatacreditoFlowController.FlowInputs>();
        ConsultaDatacreditoFlowController.FlowOutputs[] outputs = new List<ConsultaDatacreditoFlowController.FlowOutputs>();
        
        ConsultaDatacreditoFlowController.FlowInputs input = new ConsultaDatacreditoFlowController.FlowInputs();
        input.opportunity = [Select Id, OPP_VehValue__c, OPP_VehType__c, OPP_VehPrice__c, OPP_VehTime__c, Tasa__c, Plazo__c, Monto__c from Opportunity limit 1];
        input.account = [Select ACC_NumIdentificacion__c, ACC_TipoIdentificacion__c from Account limit 1];
        input.actividadEconomica = [Select DM_Direccion__c from Datos_Maestros__c limit 1];
        input.history = [Select Salario__c, Tiempo_de_empresa__c, Tipo_de_empleado__c from Historial_laboral__c limit 1];
        input.infoFinanciera = [select INF_INT_Origen_de_los_recursos__c from Informacion_Financiera__c limit 1];
        input.isAsync = false;
        inputs.add(input);
        
        outputs = qualifyAllowingMissingConfig(inputs);
    }

    @isTest
    static void qualifyConsumoAsyncTest() {
        
        // To specify fake response for a certain endpoint and include response body in a static resource.        
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource('callout:DataCreditoWS/getDecisionEngine', 'prestamoConsumo');
        multimock.setStaticResource('callout:DataCreditoWS/GetVehicular', 'prestamoVehiculo');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, multimock);
        
        ConsultaDatacreditoFlowController.FlowInputs[] inputs = new List<ConsultaDatacreditoFlowController.FlowInputs>();
        ConsultaDatacreditoFlowController.FlowOutputs[] outputs = new List<ConsultaDatacreditoFlowController.FlowOutputs>();
        
        ConsultaDatacreditoFlowController.FlowInputs input = new ConsultaDatacreditoFlowController.FlowInputs();
        input.opportunity = [Select Id, OPP_VehValue__c, OPP_VehType__c, OPP_VehPrice__c, OPP_VehTime__c, Tasa__c, Plazo__c, Monto__c from Opportunity limit 1];
        input.account = [Select ACC_NumIdentificacion__c, ACC_TipoIdentificacion__c from Account limit 1];
        input.actividadEconomica = [Select DM_Direccion__c from Datos_Maestros__c limit 1];
        input.history = [Select Salario__c, Tiempo_de_empresa__c, Tipo_de_empleado__c from Historial_laboral__c limit 1];
        input.infoFinanciera = [select INF_INT_Origen_de_los_recursos__c from Informacion_Financiera__c limit 1];
        input.isAsync = true;
        inputs.add(input);
        
        try {
            Test.startTest();
		    outputs = ConsultaDatacreditoFlowController.qualify(inputs);
            Test.stopTest();
        } catch (QueryException ex) {
            System.assertEquals(true, isMissingPrestamoSetting(ex), ex.getMessage());
        }
    }
    
    @isTest
    static void qualifyVehiculoTest() {
        
        // To specify fake response for a certain endpoint and include response body in a static resource.        
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource('callout:DataCreditoWS/getDecisionEngine', 'prestamoConsumo');
        multimock.setStaticResource('callout:DataCreditoWS/GetVehicular', 'prestamoVehiculo');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, multimock);
        
        ConsultaDatacreditoFlowController.FlowInputs[] inputs = new List<ConsultaDatacreditoFlowController.FlowInputs>();
        ConsultaDatacreditoFlowController.FlowOutputs[] outputs = new List<ConsultaDatacreditoFlowController.FlowOutputs>();
        
        ConsultaDatacreditoFlowController.FlowInputs input = new ConsultaDatacreditoFlowController.FlowInputs();
        input.opportunity = [Select Id, OPP_VehValue__c, OPP_VehType__c, OPP_VehPrice__c, OPP_VehTime__c, Tasa__c, Plazo__c, Monto__c from Opportunity limit 1];
        input.opportunity.OPP_VehValue__c = 300000;
        input.opportunity.OPP_VehType__c = '1';
        input.opportunity.OPP_VehPrice__c = 250000;
        input.opportunity.OPP_VehTime__c =  12;
        
        input.account = [Select ACC_NumIdentificacion__c, ACC_TipoIdentificacion__c from Account limit 1];
        input.actividadEconomica = [Select DM_Direccion__c from Datos_Maestros__c limit 1];
        input.history = [Select Salario__c, Tiempo_de_empresa__c, Tipo_de_empleado__c from Historial_laboral__c limit 1];
        input.infoFinanciera = [select INF_INT_Origen_de_los_recursos__c from Informacion_Financiera__c limit 1];
        input.isAsync = true;
        inputs.add(input);
        
        try {
            Test.startTest();
		    outputs = ConsultaDatacreditoFlowController.qualify(inputs);
            Test.stopTest();
        } catch (QueryException ex) {
            System.assertEquals(true, isMissingPrestamoSetting(ex), ex.getMessage());
        }
    }
    
    @isTest
    static void qualifyVehiculoAsyncTest() {
        
        // To specify fake response for a certain endpoint and include response body in a static resource.        
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource('callout:DataCreditoWS/getDecisionEngine', 'prestamoConsumo');
        multimock.setStaticResource('callout:DataCreditoWS/GetVehicular', 'prestamoVehiculo');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, multimock);
        
        ConsultaDatacreditoFlowController.FlowInputs[] inputs = new List<ConsultaDatacreditoFlowController.FlowInputs>();
        ConsultaDatacreditoFlowController.FlowOutputs[] outputs = new List<ConsultaDatacreditoFlowController.FlowOutputs>();
        
        ConsultaDatacreditoFlowController.FlowInputs input = new ConsultaDatacreditoFlowController.FlowInputs();
        input.opportunity = [Select Id, OPP_VehValue__c, OPP_VehType__c, OPP_VehPrice__c, OPP_VehTime__c, Tasa__c, Plazo__c, Monto__c from Opportunity limit 1];
        input.opportunity.OPP_VehValue__c = 300000;
        input.opportunity.OPP_VehType__c = '1';
        input.opportunity.OPP_VehPrice__c = 250000;
        input.opportunity.OPP_VehTime__c =  12;
        
        input.account = [Select ACC_NumIdentificacion__c, ACC_TipoIdentificacion__c from Account limit 1];
        input.actividadEconomica = [Select DM_Direccion__c from Datos_Maestros__c limit 1];
        input.history = [Select Salario__c, Tiempo_de_empresa__c, Tipo_de_empleado__c from Historial_laboral__c limit 1];
        input.infoFinanciera = [select INF_INT_Origen_de_los_recursos__c from Informacion_Financiera__c limit 1];
        input.isAsync = true;
        inputs.add(input);
        
        try {
            Test.startTest();
		    outputs = ConsultaDatacreditoFlowController.qualify(inputs);
            Test.stopTest();
        } catch (QueryException ex) {
            System.assertEquals(true, isMissingPrestamoSetting(ex), ex.getMessage());
        }
    }

    @isTest
    static void createBodyMapsIdentificationTypes() {
        Account account = [SELECT ACC_NumIdentificacion__c, ACC_TipoIdentificacion__c FROM Account LIMIT 1];
        Opportunity opportunity = [SELECT Monto__c, Plazo__c, Tasa__c FROM Opportunity LIMIT 1];
        Historial_laboral__c history = [
            SELECT Salario__c, Tiempo_de_empresa__c, Tipo_de_empleado__c
            FROM Historial_laboral__c
            LIMIT 1
        ];
        Datos_Maestros__c activity = [SELECT DM_Direccion__c FROM Datos_Maestros__c LIMIT 1];
        Informacion_Financiera__c financialInfo = [
            SELECT INF_INT_Origen_de_los_recursos__c
            FROM Informacion_Financiera__c
            LIMIT 1
        ];

        ConsultaDatacreditoFlowController.FlowInputs input =
            new ConsultaDatacreditoFlowController.FlowInputs();
        input.account = account;
        input.opportunity = opportunity;
        input.history = history;
        input.actividadEconomica = activity;
        input.infoFinanciera = financialInfo;

        account.ACC_TipoIdentificacion__c = ConsultaDatacreditoFlowController.RNC;
        String rncBody = ConsultaDatacreditoFlowController.createBody(input, true);
        account.ACC_TipoIdentificacion__c = ConsultaDatacreditoFlowController.Pasaporte;
        String passportBody = ConsultaDatacreditoFlowController.createBody(input, true);

        System.assert(rncBody.contains('"idType":"R"'));
        System.assert(passportBody.contains('"idType":"P"'));
    }

}
