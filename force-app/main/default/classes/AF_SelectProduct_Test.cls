@IsTest
private class AF_SelectProduct_Test {

    private static String getProductsJson() {

        List<AF_SelectProduct.ProductOption> products =
            new List<AF_SelectProduct.ProductOption>();

        AF_SelectProduct.ProductOption p1 =
            new AF_SelectProduct.ProductOption();
        p1.accountNumberRaw = '123456789';
        p1.displayLabel = 'Cuenta Ahorro';
        p1.integrationProductType = 'SAVINGS';
        p1.currencyCode = 'DOP';
        products.add(p1);

        AF_SelectProduct.ProductOption p2 =
            new AF_SelectProduct.ProductOption();
        p2.accountNumberRaw = '987654321';
        p2.displayLabel = 'Tarjeta Visa';
        p2.integrationProductType = 'CREDIT_CARD';
        p2.currencyCode = 'USD';
        products.add(p2);

        return JSON.serialize(products);
    }


    @IsTest
    static void testSelectProduct_ByNumber_Success() {

        AF_SelectProduct.Input inp = new AF_SelectProduct.Input();
        inp.productsJson = getProductsJson();
        inp.userSelection = '1';

        Test.startTest();
        List<AF_SelectProduct.Output> result =
            AF_SelectProduct.selectProduct(
                new List<AF_SelectProduct.Input>{ inp }
            );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(true, result[0].success);
        System.assertEquals('123456789', result[0].accountNumber);
        System.assertEquals('Cuenta Ahorro', result[0].productLabel);
        System.assertEquals('SAVINGS', result[0].productLine);
        System.assertEquals('DOP', result[0].currencyCode);
    }


    @IsTest
    static void testSelectProduct_ByText_Success() {

        AF_SelectProduct.Input inp = new AF_SelectProduct.Input();
        inp.productsJson = getProductsJson();
        inp.userSelection = 'Quiero mi Tarjeta Visa';

        Test.startTest();
        List<AF_SelectProduct.Output> result =
            AF_SelectProduct.selectProduct(
                new List<AF_SelectProduct.Input>{ inp }
            );
        Test.stopTest();

        System.assert(result[0].success);
        System.assertEquals('987654321', result[0].accountNumber);
        System.assertEquals('CREDIT_CARD', result[0].productLine);
    }


    @IsTest
    static void testInvalidOptionNumber() {

        AF_SelectProduct.Input inp = new AF_SelectProduct.Input();
        inp.productsJson = getProductsJson();
        inp.userSelection = '5';

        List<AF_SelectProduct.Output> result =
            AF_SelectProduct.selectProduct(
                new List<AF_SelectProduct.Input>{ inp }
            );

        System.assertEquals(false, result[0].success);
        System.assert(
            result[0].message.contains('La opción seleccionada no es válida')
        );
    }


    @IsTest
    static void testInvalidTextSelection() {

        AF_SelectProduct.Input inp = new AF_SelectProduct.Input();
        inp.productsJson = getProductsJson();
        inp.userSelection = 'Producto inventado';

        List<AF_SelectProduct.Output> result =
            AF_SelectProduct.selectProduct(
                new List<AF_SelectProduct.Input>{ inp }
            );

        System.assertEquals(false, result[0].success);
        System.assert(
            result[0].message.contains('No pude identificar el producto')
        );
    }


    @IsTest
    static void testEmptyProductsJson() {

        AF_SelectProduct.Input inp = new AF_SelectProduct.Input();
        inp.productsJson = '';
        inp.userSelection = '1';

        List<AF_SelectProduct.Output> result =
            AF_SelectProduct.selectProduct(
                new List<AF_SelectProduct.Input>{ inp }
            );

        System.assertEquals(false, result[0].success);
        System.assert(
            result[0].message.contains('No hay productos para seleccionar')
        );
    }


    @IsTest
    static void testEmptySelection() {

        AF_SelectProduct.Input inp = new AF_SelectProduct.Input();
        inp.productsJson = getProductsJson();
        inp.userSelection = '';

        List<AF_SelectProduct.Output> result =
            AF_SelectProduct.selectProduct(
                new List<AF_SelectProduct.Input>{ inp }
            );

        System.assertEquals(false, result[0].success);
        System.assert(
            result[0].message.contains('Debe indicar una opción')
        );
    }


    @IsTest
    static void testInvalidAccountNumber() {

        List<AF_SelectProduct.ProductOption> products =
            new List<AF_SelectProduct.ProductOption>();

        AF_SelectProduct.ProductOption p =
            new AF_SelectProduct.ProductOption();

        p.accountNumberRaw = '';
        p.displayLabel = 'Cuenta Corriente';
        p.integrationProductType = 'CHECKING';
        products.add(p);

        AF_SelectProduct.Input inp = new AF_SelectProduct.Input();
        inp.productsJson = JSON.serialize(products);
        inp.userSelection = '1';

        List<AF_SelectProduct.Output> result =
            AF_SelectProduct.selectProduct(
                new List<AF_SelectProduct.Input>{ inp }
            );

        System.assertEquals(false, result[0].success);
        System.assert(
            result[0].message.contains('Cuenta inválida')
        );
    }


    @IsTest
    static void testMissingProductType() {

        List<AF_SelectProduct.ProductOption> products =
            new List<AF_SelectProduct.ProductOption>();

        AF_SelectProduct.ProductOption p =
            new AF_SelectProduct.ProductOption();

        p.accountNumberRaw = '12345';
        p.displayLabel = 'Cuenta Corriente';
        p.integrationProductType = '';
        products.add(p);

        AF_SelectProduct.Input inp = new AF_SelectProduct.Input();
        inp.productsJson = JSON.serialize(products);
        inp.userSelection = '1';

        List<AF_SelectProduct.Output> result =
            AF_SelectProduct.selectProduct(
                new List<AF_SelectProduct.Input>{ inp }
            );

        System.assertEquals(false, result[0].success);
        System.assert(
            result[0].message.contains('Tipo de producto no definido')
        );
    }


    @IsTest
    static void testBulkInputs() {

        AF_SelectProduct.Input inp1 = new AF_SelectProduct.Input();
        inp1.productsJson = getProductsJson();
        inp1.userSelection = '1';

        AF_SelectProduct.Input inp2 = new AF_SelectProduct.Input();
        inp2.productsJson = getProductsJson();
        inp2.userSelection = '2';

        List<AF_SelectProduct.Output> results =
            AF_SelectProduct.selectProduct(
                new List<AF_SelectProduct.Input>{
                    inp1,
                    inp2
                }
            );

        System.assertEquals(2, results.size());
        System.assert(results[0].success);
        System.assert(results[1].success);
    }
}