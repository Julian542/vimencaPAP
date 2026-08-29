@isTest
private class AF_GetProductBalanceTest {

    @isTest
    static void testGetBalance_NoData_InvalidProduct() {

        AF_GetProductBalance.Request req =
            new AF_GetProductBalance.Request();

        req.accountNumber = '123456';
        req.productLine = 'producto invalido';
        req.currencyCode = 'DOP';

        Test.startTest();

        List<AF_GetProductBalance.Response> responses =
            AF_GetProductBalance.getBalance(
                new List<AF_GetProductBalance.Request>{ req }
            );

        Test.stopTest();

        System.assertEquals(1, responses.size());

        AF_GetProductBalance.Response r = responses[0];

        System.assertEquals('NO_DATA', r.status);
        System.assertEquals(false, r.hasBalance);

        System.assertNotEquals(null, r.errorText);
    }

    @isTest
    static void testGetBalance_BlankAccount() {

        AF_GetProductBalance.Request req =
            new AF_GetProductBalance.Request();

        req.accountNumber = '';
        req.productLine = 'cuentas de ahorro';
        req.currencyCode = 'DOP';

        Test.startTest();

        List<AF_GetProductBalance.Response> responses =
            AF_GetProductBalance.getBalance(
                new List<AF_GetProductBalance.Request>{ req }
            );

        Test.stopTest();

        System.assertEquals(1, responses.size());

        AF_GetProductBalance.Response r = responses[0];

        System.assertEquals('NO_DATA', r.status);
        System.assertEquals(false, r.hasBalance);

        System.assertNotEquals(null, r.errorText);
    }

    @isTest
    static void testGetBalance_NullCurrency() {

        AF_GetProductBalance.Request req =
            new AF_GetProductBalance.Request();

        req.accountNumber = '999999';
        req.productLine = 'cuentas corrientes';
        req.currencyCode = null;

        Test.startTest();

        List<AF_GetProductBalance.Response> responses =
            AF_GetProductBalance.getBalance(
                new List<AF_GetProductBalance.Request>{ req }
            );

        Test.stopTest();

        System.assertEquals(1, responses.size());

        AF_GetProductBalance.Response r = responses[0];

        System.assertEquals('NO_DATA', r.status);
        System.assertEquals(false, r.hasBalance);

        System.assertNotEquals(null, r.errorText);
    }

    // 🔥 Cubre el catch(Exception e)
    @isTest
    static void testGetBalance_Exception() {

        Test.startTest();

        List<AF_GetProductBalance.Response> responses =
            AF_GetProductBalance.getBalance(
                new List<AF_GetProductBalance.Request>{ null }
            );

        Test.stopTest();

        System.assertEquals(1, responses.size());

        AF_GetProductBalance.Response r = responses[0];

        System.assertEquals('ERROR', r.status);

        System.assertEquals(
            'UNEXPECTED_ERROR',
            r.errorCode
        );

        System.assertEquals(false, r.hasBalance);
    }

    @isTest
    static void testGetBalance_Success() {
        INT013Agente.Response core = new INT013Agente.Response();
        core.balance = 150;
        core.currencyCode = 'DOP';
        AF_GetProductBalance.testCoreResponse = core;

        AF_GetProductBalance.Request req = new AF_GetProductBalance.Request();
        req.accountNumber = '123456';
        req.productLine = 'cuentas de ahorro';
        req.currencyCode = 'DOP';

        List<AF_GetProductBalance.Response> responses =
            AF_GetProductBalance.getBalance(new List<AF_GetProductBalance.Request>{ req });

        System.assertEquals('SUCCESS', responses[0].status);
        System.assertEquals(true, responses[0].hasBalance);
        AF_GetProductBalance.testCoreResponse = null;
    }
}