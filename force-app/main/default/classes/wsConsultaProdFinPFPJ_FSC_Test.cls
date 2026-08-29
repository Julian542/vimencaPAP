/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
*/
@SuppressWarnings('PMD')
@isTest
private class wsConsultaProdFinPFPJ_FSC_Test {
    /* Test de funcionamiento cuando la Acccount no existe */
    @isTest
    public static void testNoAccount(){
        String response;
        Test.startTest();
            /* Prueba con un ID de cuenta aleatorio */
            response = wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ('9063A000000lG9mQAE');
        Test.stopTest();
        System.assertEquals('La persona física o jurídica no existe en Salesforce: \nList has no rows for assignment to SObject', response);
    }

    /* Test de funcionamiento cuando sucede un error controlado (ErrorCode != 200 o ErrorText != 'TRANSACCION PROCESADA')
        CASO - EL CLIENTE NO EXISTE EN EL CORE
    */
    @isTest
    public static void testErrorControlado(){

        String response;
        List<Account> newAccounts = new List <Account>();
        ID rtpj  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Personas_Juridicas').getRecordTypeId();
        ID rtpf  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

        /* Se crea un PJ */
        newAccounts.add(new Account(Name = 'TEST ERROR Controlado PJ', recordTypeId = rtpj));
        /* Se crea un PF */
        newAccounts.add(new Account(LastName = 'TEST ERROR Controlado PF', recordTypeId = rtpf));
        insert newAccounts;

        Test.startTest();
        /* Se prueba PJ */
            /* Mock que dispone de un mensaje de error del CORE para PJ */
            Test.setMock(HttpCalloutMock.class, new wsConsultaProdFinPFPJMock_error('PJ'));
            response = wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ(newAccounts[0].Id);
            System.assert(response == 'NO_PRODUCTS_FOUND' || response.contains('CUSTOMER NOT FOUND OR DO NOT HAVE ANY PRODUCT'));
        Test.stopTest();
    }

    /* Test de funcionamiento cuando sucede un error NO controlado (Timeout, excepcion...)
        CASO1 - El FORMATO NO CORRESPONDE CON EL ACORDADO -> Etiqueta 'Result' como 'Resultado'
        CASO2 - Codigo de error distinto de 200
    */
    @isTest
    public static void testErrorNoControlado(){

        String response;
        ID rtpf  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

        /* Se crea un PF */
        Account newAccount = new Account(LastName = 'TEST ERROR NO Controlado PF', recordTypeId = rtpf);
        insert newAccount;

        Test.startTest();
            /* El Mock dispone de un mensaje con sin el formato correcto: Result -> Resultado */
            Test.setMock(HttpCalloutMock.class, new wsConsultaProdFinPFPJMock_Error('ERROR'));
            response = wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ(newAccount.Id);
            System.assert(response.contains('Ha sucedido un error') && response.contains('Consulta de productos financieros'));

            /* El Mock dispone de un mensaje con statusCode distinto de 200 */
            Test.setMock(HttpCalloutMock.class, new wsConsultaProdFinPFPJMock_Error('ERRCODE'));
            response = wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ(newAccount.Id);

            Boolean errBool = response.contains('Ha sucedido un error no controlado durante la integración de Consulta de productos financieros');
            System.assertEquals(true, errBool);

        try {
            Test.stopTest();
        } catch (AsyncException ex) {
            System.assertEquals(true, ex.getMessage().contains('profundidad') || ex.getMessage().contains('maximum stack'));
        }
    }

    /* Test de funcionamiento correcto de PF, con creación y actualizacion de un Financial Account con producto existente */
    @isTest
    public static void testCorrectoPF(){
        ID rtpf  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();

        /* Se crea un PF */
        Account newAccount = new Account(FirstName = 'TEST ERROR Controlado PF', LastName = 'TEST ERROR Controlado PF', recordTypeId = rtpf, ACC_TipoIdentificacion__c = 'Cédula', ACC_NumIdentificacion__c='90282320312', ACC_CIF__c = '1532489');
        insert newAccount;
        /* Se crea un Producto */
        Matriz_de_producto__c newProducto = new Matriz_de_producto__c(Name = 'PRODUCTO DE TEST', PRO_Codigo_de_producto__c = '34');
        insert newProducto;

        String response;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleProductMock('PF'));
        response = wsConsultaProdFinPFPJ_FSC.consultaProdFinPFPJ(newAccount.Id);
        Test.stopTest();

        System.assertEquals('', response);
        assertFinancialAccountCreated(newAccount.Id, newProducto.Id);
    }

    /* Test de funcionamiento correcto de PJ, con creación y actualizacion de un FinServ__FinancialAccount__c con producto existente */
    @isTest
    public static void testCorrectoPJFuture(){
        ID rtpj  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Personas_Juridicas').getRecordTypeId();

        /* Se crea un PJ */
        Account newAccount = new Account(Name = 'TEST ERROR Controlado PJ', recordTypeId = rtpj, ACC_RNC__c = '90282320312', ACC_CIF__c = '1532482');
        insert newAccount;
        /* Se crea un Producto */
        Matriz_de_producto__c newProducto = new Matriz_de_producto__c(Name = 'PRODUCTO DE TEST', PRO_Codigo_de_producto__c = '34');
        insert newProducto;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SingleProductMock('PJ'));
        wsConsultaProdFinPFPJ_FSC.futureConsultaProdFin_PF_PJ(newAccount.Id);
        Test.stopTest();

        assertFinancialAccountCreated(newAccount.Id, newProducto.Id);
    }

    private static void assertFinancialAccountCreated(Id ownerId, Id productId) {
        List<FinServ__FinancialAccount__c> assets = [
            SELECT FinServ__FinancialAccountNumber__c, FinServ__PrimaryOwner__c, FIN_Producto__c
            FROM FinServ__FinancialAccount__c
            WHERE FinServ__PrimaryOwner__c = :ownerId
            AND FinServ__FinancialAccountNumber__c = 'TEST-CONSULTA-001'
        ];

        System.assertEquals(1, assets.size());
        System.assertEquals(ownerId, assets[0].FinServ__PrimaryOwner__c);
        System.assertEquals(productId, assets[0].FIN_Producto__c);
    }

    private class SingleProductMock implements HttpCalloutMock {
        private String responseNamespace;

        SingleProductMock(String personType) {
            responseNamespace = personType == 'PF'
                ? 'http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20VBC%20Response%20IO'
                : 'http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PJ%20Response%20IO';
        }

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setHeader('Content-Type', 'text/xml');
            response.setBody(
                '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<soap:Body><ListOfBREAIFuncionGeneral xmlns="' + responseNamespace + '">' +
                '<Result><ErrorCode>000</ErrorCode><ErrorText>TRANSACCION PROCESADA</ErrorText>' +
                '<Producto><NumCuenta>TEST-CONSULTA-001</NumCuenta><CodigoProducto>34</CodigoProducto>' +
                '<Estado>VIGENTE</Estado><FechaApertura>25/12/2018</FechaApertura>' +
                '<LineaProducto>Tarjetas de crédito</LineaProducto><SaldoRD>14925.08</SaldoRD>' +
                '<Titulares>PRINCIPAL TESTER TEST</Titulares></Producto></Result>' +
                '</ListOfBREAIFuncionGeneral></soap:Body></soap:Envelope>'
            );
            return response;
        }
    }
}
