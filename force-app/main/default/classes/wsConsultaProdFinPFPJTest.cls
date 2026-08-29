@isTest
public class wsConsultaProdFinPFPJTest {

    /* Test de funcionamiento cuando la Acccount no existe */
    @isTest
    public static void testNoAccount(){
        String response;
        Test.startTest();
            /* Prueba con un ID de cuenta aleatorio */
            response = wsConsultaProdFinPFPJ.consultaProdFinPFPJ('9063A000000lG9mQAE');
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
        ID rt_pj  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Personas_Juridicas').getRecordTypeId();
        ID rt_pf  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        /* Se crea un PJ */
        newAccounts.add(new Account(Name = 'TEST ERROR Controlado PJ', recordTypeId = rt_pj));
        /* Se crea un PF */
        newAccounts.add(new Account(LastName = 'TEST ERROR Controlado PF', recordTypeId = rt_pf));
        insert newAccounts;
    
        Test.startTest();
        /* Se prueba PJ */
            /* Mock que dispone de un mensaje de error del CORE para PJ */
            Test.setMock(HttpCalloutMock.class, new wsConsultaProdFinPFPJMock_error('PJ'));
            response = wsConsultaProdFinPFPJ.consultaProdFinPFPJ(newAccounts[0].Id);
            System.assertEquals('Ha sucedido un error en la integración:\nCode: 9709\nText: CUSTOMER NOT FOUND OR DO NOT HAVE ANY PRODUCT', response);
            
            /* Mock que dispone de un mensaje de error del CORE para PF */
            Test.setMock(HttpCalloutMock.class, new wsConsultaProdFinPFPJMock_error('PF'));
            response = wsConsultaProdFinPFPJ.consultaProdFinPFPJ(newAccounts[1].Id);
//        System.assertEquals('Ha sucedido un error en la integración:\nCode: 9709\nText: CUSTOMER NOT FOUND OR DO NOT HAVE ANY PRODUCT', response);
        Test.stopTest();
        
    }
    
    /* Test de funcionamiento cuando sucede un error NO controlado (Timeout, excepcion...) 
        CASO1 - El FORMATO NO CORRESPONDE CON EL ACORDADO -> Etiqueta 'Result' como 'Resultado'
        CASO2 - Codigo de error distinto de 200
    */
    @isTest
    public static void testErrorNoControlado(){
        
        String response;
        ID rt_pf  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
            
        /* Se crea un PF */
        Account newAccount = new Account(LastName = 'TEST ERROR NO Controlado PF', recordTypeId = rt_pf);
        insert newAccount;
        
        Test.startTest();
            /* El Mock dispone de un mensaje con sin el formato correcto: Result -> Resultado */
            Test.setMock(HttpCalloutMock.class, new wsConsultaProdFinPFPJMock_Error('ERROR'));
            response = wsConsultaProdFinPFPJ.consultaProdFinPFPJ(newAccount.Id);
            System.assertEquals('Ha sucedido un error no controlado durante la integración de Consulta de productos financieros:\nAttempt to de-reference a null object', response);
            
            /* El Mock dispone de un mensaje con statusCode distinto de 200 */
            Test.setMock(HttpCalloutMock.class, new wsConsultaProdFinPFPJMock_Error('ERRCODE'));
            response = wsConsultaProdFinPFPJ.consultaProdFinPFPJ(newAccount.Id);
         //   System.assertEquals('Ha sucedido un error durante la consulta en la integración de Consulta de productos financieros: \nCode: 500\nMessage: <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><soap:Header></soap:Header><soap:Body></soap:Body></soap:Envelope>', response);
       
        Test.stopTest();
    }
    
    /* Test de funcionamiento correcto de PF, con creación y actualizacion de un Asset con producto existente */
    @isTest
    public static void testCorrectoPF(){
        String response;
        List<Asset> receibeAssets = new List <Asset>();
        ID rt_pf  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        
        /* Se crea un PF */
        Account newAccount = new Account(FirstName = 'TEST ERROR Controlado PF', LastName = 'TEST ERROR Controlado PF', recordTypeId = rt_pf, ACC_TipoIdentificacion__c = 'Cédula', ACC_NumIdentificacion__c='90282320312', ACC_CIF__c = '1532489');
        insert newAccount;
        /* Se crea un Producto */
        Matriz_de_producto__c newProducto = new Matriz_de_producto__c(Name = 'PRODUCTO DE TEST', PRO_Codigo_de_producto__c = '34');
        insert newProducto;
        
        Test.startTest();
            /* El Mock dispone de: 1 CF con producto existente, 1 CF sin producto existente, 1 CF como autorizado( No Se ignora) */
            Test.setMock(HttpCalloutMock.class, new wsConsultaProdFinPFPJMock_OK('PF'));
            response = wsConsultaProdFinPFPJ.consultaProdFinPFPJ(newAccount.Id);
           // System.assertEquals('', response);
        
            /* Se deben de haber creado las 2 CF con el contacto como principal y 1 como autorizado */
          //  System.assertEquals(3,[Select Id From Asset].size());
        
            /* Se debe haber creado al menos 1 CF con el nuevo producto*/
        //    System.assert([Select Id, ASE_Producto__c From Asset where ASE_Producto__c =:newProducto.Id].size() > 0);
        
        Test.stopTest();  
    } 
    
    /* Test de funcionamiento correcto de PJ, con creación y actualizacion de un Asset con producto existente */
    @isTest
    public static void testCorrectoPJFuture(){
        
        List<Asset> receibeAssets = new List <Asset>();
        ID rt_pj  = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Personas_Juridicas').getRecordTypeId();
        
        /* Se crea un PJ */
        Account newAccount = new Account(Name = 'TEST ERROR Controlado PJ', recordTypeId = rt_pj, ACC_RNC__c = '90282320312', ACC_CIF__c = '1532482');
        insert newAccount;
        /* Se crea un Producto */
        Matriz_de_producto__c newProducto = new Matriz_de_producto__c(Name = 'PRODUCTO DE TEST', PRO_Codigo_de_producto__c = '34');
        insert newProducto;
        
        Test.startTest();
            /* El Mock dispone de: 1 CF con producto existente, 1 CF sin producto existente, 1 CF como autorizado(No Se ignora) */
            Test.setMock(HttpCalloutMock.class, new wsConsultaProdFinPFPJMock_OK('PJ'));
            wsConsultaProdFinPFPJ.futureConsultaProdFin_PF_PJ(newAccount.Id);
        Test.stopTest();
        
        /* Se deben de haber creado las 2 CF con el contacto como principal y 1 como el autorizado*/
       // System.assertEquals(3,[Select Id From Asset].size());
        
        /* Se debe haber creado al menos 1 CF con el nuevo producto*/
      //  System.assert([Select Id, ASE_Producto__c From Asset where ASE_Producto__c =:newProducto.Id].size() > 0);
    }
}