@IsTest
private class SucursalesBatch_Test {

    private class BatchMock implements HttpCalloutMock {

        Integer statusCode;
        String body;

        BatchMock(Integer c,String b){
            statusCode=c;
            body=b;
        }

        public HttpResponse respond(HttpRequest req){

            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);

            return res;
        }
    }



    private static String mockJson(){

        return
        '['+

        '{'+
        '"id":1,'+
        '"nombre_oficina":"Sucursal Centro",'+
        '"direccion":"Av 1",'+
        '"telefono":"8091111111",'+
        '"provincia":"Santo Domingo",'+
        '"tipo_de_oficina":"Sucursal",'+
        '"servicio_principal":"Banco",'+
        '"latitud":18.45,'+
        '"longitud":-69.90,'+
        '"banco_vimenca":"Y",'+
        '"remesas":"Y",'+
        '"pagatodo":"Y",'+
        '"vimenpaq":"Y",'+
        '"cajero_automaticos":"Y",'+
        '"d_lunes_viernes":"8-5",'+
        '"d_sabado":"8-12"'+
        '},'+

        '{'+
        '"id":2,'+
        '"nombre_oficina":"Representante Norte",'+
        '"tipo_de_oficina":"Representante",'+
        '"provincia":"Santiago"'+
        '},'+

        '{'+
        '"id":3,'+
        '"nombre_oficina":"ATM 1",'+
        '"tipo_de_oficina":"N",'+
        '"provincia":"La Vega"'+
        '},'+

        '{'+
        '"id":4,'+
        '"nombre_oficina":"Tipo raro",'+
        '"tipo_de_oficina":"DESCONOCIDO",'+
        '"provincia":"Moca"'+
        '}'+

        ']';
    }



    @IsTest
    static void testBatchRun(){

        Test.setMock(
            HttpCalloutMock.class,
            new BatchMock(
                200,
                mockJson()
            )
        );

        Test.startTest();

        Database.executeBatch(
            new SucursalesBatch(),
            200
        );

        Test.stopTest();

        List<Sucursal__c> sucursales=[
            SELECT Id
            FROM Sucursal__c
        ];

        System.assertEquals(
            4,
            sucursales.size()
        );
    }



    @IsTest
    static void testApiError(){

        Test.setMock(
            HttpCalloutMock.class,
            new BatchMock(
                500,
                'error'
            )
        );

        try{

            Test.startTest();

            Database.executeBatch(
                new SucursalesBatch(),
                2
            );

            Test.stopTest();

            System.assert(false);

        } catch(Exception e){

            System.assert(
                e.getMessage().contains(
                    'Error en API'
                )
            );
        }
    }



    @IsTest
    static void testEmptyResponse(){

        Test.setMock(
            HttpCalloutMock.class,
            new BatchMock(
                200,
                '[]'
            )
        );

        Test.startTest();

        Database.executeBatch(
            new SucursalesBatch(),
            1
        );

        Test.stopTest();

        Integer total=[
            SELECT count()
            FROM Sucursal__c
        ];

        System.assertEquals(
            0,
            total
        );
    }



    @IsTest
    static void testNombreFallback(){

        String jsonData=
        '['+
        '{'+
        '"id":9,'+
        '"nombre_oficina":"",'+
        '"tipo_de_oficina":"Sucursal",'+
        '"provincia":"SD"'+
        '}'+
        ']';

        Test.setMock(
            HttpCalloutMock.class,
            new BatchMock(
                200,
                jsonData
            )
        );

        Test.startTest();

        Database.executeBatch(
            new SucursalesBatch(),
            1
        );

        Test.stopTest();

        Sucursal__c s=[
            SELECT Name
            FROM Sucursal__c
            WHERE External_ID__c='9'
            LIMIT 1
        ];

        System.assertEquals(
            'Sucursal sin nombre',
            s.Name
        );
    }



    /*
    NUEVO:
    CUBRE TRUNCADO >80
    */
    @IsTest
    static void testNombreTruncado(){

        String largo=
        'ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ12345';

        String jsonData=
        '['+
        '{'+
        '"id":99,'+
        '"nombre_oficina":"'+largo+'",'+
        '"tipo_de_oficina":"Sucursal",'+
        '"provincia":"SD"'+
        '}'+
        ']';

        Test.setMock(
            HttpCalloutMock.class,
            new BatchMock(
                200,
                jsonData
            )
        );

        Test.startTest();

        Database.executeBatch(
            new SucursalesBatch(),
            1
        );

        Test.stopTest();

        Sucursal__c s=[
            SELECT Name
            FROM Sucursal__c
            WHERE External_ID__c='99'
            LIMIT 1
        ];

        System.assert(
            s.Name.length()<=80
        );
    }



    /*
    NUEVO:
    CUBRE FALSE PATHS
    */
    @IsTest
    static void testSinGeoNiServicios(){

        String jsonData=
        '['+
        '{'+
        '"id":100,'+
        '"nombre_oficina":"Minimal",'+
        '"tipo_de_oficina":"Sucursal",'+
        '"provincia":"SD"'+
        '}'+
        ']';

        Test.setMock(
            HttpCalloutMock.class,
            new BatchMock(
                200,
                jsonData
            )
        );

        Test.startTest();

        Database.executeBatch(
            new SucursalesBatch(),
            1
        );

        Test.stopTest();

        Sucursal__c s=[
            SELECT Id
            FROM Sucursal__c
            WHERE External_ID__c='100'
            LIMIT 1
        ];

        System.assert(
            s!=null
        );
    }

}