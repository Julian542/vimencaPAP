@IsTest
private class INT013Agente_Test {

    private class BalanceMock implements HttpCalloutMock {

        Integer code;
        String body;

        BalanceMock(Integer c,String b){
            code=c;
            body=b;
        }

        public HttpResponse respond(HttpRequest req){
            HttpResponse r = new HttpResponse();
            r.setStatusCode(code);
            r.setBody(body);
            return r;
        }
    }

    private static String xmlMock(){
        return
        '<?xml version="1.0"?>'+
        '<Envelope><Body>'+
        '<SaldoDisponible>1000</SaldoDisponible>'+
        '<Moneda>DOP</Moneda>'+
        '</Body></Envelope>';
    }


    @IsTest
    static void testValidation1(){
        Object x=INT013Agente.getBalance('','cuentas de ahorro','DOP');
        System.assert(x!=null);
    }

    @IsTest
    static void testValidation2(){
        Object x=INT013Agente.getBalance('123','','DOP');
        System.assert(x!=null);
    }

    @IsTest
    static void testValidation3(){
        Object x=INT013Agente.getBalance('123','cuentas de ahorro','');
        System.assert(x!=null);
    }

    @IsTest
    static void testUnsupported(){
        Object x=INT013Agente.getBalance('123','bitcoin','USD');
        System.assert(x!=null);
    }

    @IsTest
    static void testHttpError(){

        Test.setMock(
            HttpCalloutMock.class,
            new BalanceMock(
                500,
                'error'
            )
        );

        Object x=INT013Agente.getBalance(
            '1',
            'cuentas de ahorro',
            'DOP'
        );

        System.assert(x!=null);
    }

    @IsTest
    static void testSavings(){

        Test.setMock(
            HttpCalloutMock.class,
            new BalanceMock(200,xmlMock())
        );

        Object x=INT013Agente.getBalance(
            '1',
            'cuentas de ahorro',
            'DOP'
        );

        System.assert(x!=null);
    }

    @IsTest
    static void testCorriente(){

        Test.setMock(
            HttpCalloutMock.class,
            new BalanceMock(200,xmlMock())
        );

        Object x=INT013Agente.getBalance(
            '1',
            'cuentas corrientes',
            'DOP'
        );

        System.assert(x!=null);
    }

    @IsTest
    static void testPrestamos(){

        Test.setMock(
            HttpCalloutMock.class,
            new BalanceMock(200,xmlMock())
        );

        Object x=INT013Agente.getBalance(
            '1',
            'préstamos',
            'DOP'
        );

        System.assert(x!=null);
    }

    @IsTest
    static void testTC(){

        Test.setMock(
            HttpCalloutMock.class,
            new BalanceMock(200,xmlMock())
        );

        Object x=INT013Agente.getBalance(
            '1',
            'tarjetas de crédito',
            'USD'
        );

        System.assert(x!=null);
    }

    @IsTest
    static void testPrepago(){

        Test.setMock(
            HttpCalloutMock.class,
            new BalanceMock(200,xmlMock())
        );

        Object x=INT013Agente.getBalance(
            '1',
            'tarjetas prepago',
            'USD'
        );

        System.assert(x!=null);
    }

    @IsTest
    static void testCertificados(){

        Test.setMock(
            HttpCalloutMock.class,
            new BalanceMock(200,xmlMock())
        );

        Object x=INT013Agente.getBalance(
            '1',
            'certificados financieros',
            'DOP'
        );

        System.assert(x!=null);
    }

    @IsTest
    static void testLineaCredito(){

        Test.setMock(
            HttpCalloutMock.class,
            new BalanceMock(200,xmlMock())
        );

        Object x=INT013Agente.getBalance(
            '1',
            'líneas de crédito',
            'DOP'
        );

        System.assert(x!=null);
    }

}