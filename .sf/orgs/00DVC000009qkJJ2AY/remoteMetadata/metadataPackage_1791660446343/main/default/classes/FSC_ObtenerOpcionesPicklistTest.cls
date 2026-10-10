@IsTest
public class FSC_ObtenerOpcionesPicklistTest {
    @IsTest
    static void testCallableCodigoAprobacion() {
        List<FSC_Codigo_de_Aprobacion_Desembolso__mdt> cad = [SELECT Id,Label,FSC_Codigo_de_Aprobacion__c,FSC_Descripcion__c FROM FSC_Codigo_de_Aprobacion_Desembolso__mdt];
        FSC_ObtenerOpcionesPicklist callableClass = new FSC_ObtenerOpcionesPicklist();

        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input'  => inputMap,
            'output' => outputMap
        };

        Test.startTest();
        Object result = callableClass.call('codigoAprobacion', args);
        Test.stopTest();

        System.assertNotEquals(null, result, 'El resultado no debe ser null');
        System.assert(result instanceof List<Map<String, Object>>, 'Debe retornar una lista de mapas');

        List<Map<String, Object>> options = (List<Map<String, Object>>) result;

        System.assertEquals(cad.size(), options.size(), 'Debe retornar ' + cad.size() + ' opciones');

        Map<String, Object> firstOption = options[0];
        System.assert(firstOption.containsKey('name'), 'Debe contener la key name');
        System.assert(firstOption.containsKey('value'), 'Debe contener la key value');

        System.assertEquals(true, outputMap.containsKey('options'), 'El outMap debe contener options');

        List<Map<String, Object>> outOptions =
            (List<Map<String, Object>>) outputMap.get('options');

        System.assertEquals(cad.size(), outOptions.size(), 'outMap.options debe tener ' + cad.size() + ' elementos');
    }

    @IsTest
    static void testCallableInvalidAction() {
        FSC_ObtenerOpcionesPicklist callableClass = new FSC_ObtenerOpcionesPicklist();

        Map<String, Object> args = new Map<String, Object>{
            'input'  => new Map<String, Object>(),
            'output' => new Map<String, Object>()
        };

        Test.startTest();
        Object result = callableClass.call('accionInvalida', args);
        Test.stopTest();

        System.assertEquals(null, result, 'Para acciones inválidas debe devolver null');
    }
}