@IsTest
private class SucursalesService_Test {

    /*
    =========================
    MOCK
    =========================
    */
    private class SucursalesMock implements HttpCalloutMock {

        Integer statusCode;
        String body;

        SucursalesMock(Integer code,String body){
            statusCode=code;
            this.body=body;
        }

        public HttpResponse respond(HttpRequest req){

            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);

            System.assertEquals(
                'GET',
                req.getMethod()
            );

            return res;
        }
    }



    private static String mockJson(){

        return
        '['+
        '{'+
        '"id":1,'+
        '"nombre_oficina":"Sucursal Centro",'+
        '"direccion":"Av Principal 123",'+
        '"telefono":"8095551111",'+
        '"latitud":18.45,'+
        '"longitud":-69.93,'+
        '"provincia":"Santo Domingo",'+
        '"tipo_de_oficina":"Sucursal",'+
        '"servicio_principal":"Banco Vimenca",'+

        '"banco_vimenca":"Y",'+
        '"remesas":"Y",'+
        '"pagatodo":"Y",'+
        '"cajero_automaticos":"Y",'+

        '"d_lunes_viernes":"8-5",'+
        '"d_sabado":"8-12",'+
        '"d_domingo":"Cerrado"'+
        '},'+

        '{'+
        '"id":2,'+
        '"nombre_oficina":"Sucursal Norte",'+
        '"direccion":"Calle 2",'+
        '"telefono":"8095552222",'+
        '"provincia":"Santiago",'+
        '"tipo_de_oficina":"Agencia",'+
        '"banco_vimenca":"Y"'+
        '}'+
        ']';
    }



    /*
    =========================
    HAPPY PATH
    =========================
    */
    @IsTest
    static void testSyncSucursales(){

        Test.setMock(
            HttpCalloutMock.class,
            new SucursalesMock(
                200,
                mockJson()
            )
        );

        Test.startTest();

        SucursalesService.syncSucursales();

        Test.stopTest();

        List<Sucursal__c> sucursales = [
            SELECT
                Name,
                External_ID__c,
                SUC_Country__c,
                SUC_ServicesOffered__c,
                Horarios__c,
                SUC_Active__c
            FROM Sucursal__c
        ];

        System.assertEquals(
            2,
            sucursales.size()
        );

        System.assertEquals(
            'República Dominicana',
            sucursales[0].SUC_Country__c
        );

        System.assert(
            sucursales[0].SUC_Active__c
        );
    }



    /*
    =========================
    HTTP ERROR BRANCH
    =========================
    */
    @IsTest
    static void testHttpError(){

        Test.setMock(
            HttpCalloutMock.class,
            new SucursalesMock(
                500,
                'error'
            )
        );

        try{

            Test.startTest();

            SucursalesService.syncSucursales();

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



    /*
    =========================
    EMPTY RESPONSE
    =========================
    */
    @IsTest
    static void testEmptyResponse(){

        Test.setMock(
            HttpCalloutMock.class,
            new SucursalesMock(
                200,
                '[]'
            )
        );

        Test.startTest();

        SucursalesService.syncSucursales();

        Test.stopTest();

        Integer countRecords = [
            SELECT count()
            FROM Sucursal__c
        ];

        System.assertEquals(
            0,
            countRecords
        );
    }

}