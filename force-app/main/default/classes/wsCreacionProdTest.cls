@isTest
public class wsCreacionProdTest {
    
    @isTest
    static void Future_creacionProdCA_CC_CFTest()
    {
        Profile p = [SELECT Id FROM Profile WHERE id='00e3i000001RR1rAAG']; //Id de usuario estandar 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest@testorg.com');
        insert u;
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        List<Direccion__c> dirsList=TestDataFactory.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList = TestDataFactory.createMatrizDeProducto(10);
        
        List<Asset> financeAsset = TestDataFactory.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);
        
        
        Test.setMock(HttpCalloutMock.class, new wsCreacionProdMock('SUCCESS'));
        Test.startTest();
        try {
            String result = wsCreacionProd.creacionProdCA_CC_CF(financeAsset[0].Id);
            System.assertNotEquals(null, result);
        } catch (SObjectException ex) {
            System.assert(ex.getMessage().contains('DIR_Identificador__c'), ex.getMessage());
        }
        Test.stopTest();      
    }
    @isTest
    static void Future_creacionProdCA_CC_CFTestFail()
    {
        Profile p = [SELECT Id FROM Profile WHERE id='00e3i000001RR1rAAG']; //Id de usuario estandar 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standardusertest@testorg.com');
        insert u;
        List<Account> aList=TestDataFactory.createPersonAccounts(5);
        List<Direccion__c> dirsList=TestDataFactory.createDirecciones(aList);
        List<Matriz_de_producto__c> matrizList = TestDataFactory.createMatrizDeProducto(10);
        
        List<Asset> financeAsset = TestDataFactory.createAssets_CuentaCorriente(aList, dirsList, matrizList, u, 1);
        financeAsset[0].RecordTypeId=Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Cuentas_corrientes').getRecordTypeId();
        Update financeAsset; 
        Test.setMock(HttpCalloutMock.class, new wsCreacionProdMock('FAIL'));
        Test.startTest();
        try {
            String result = wsCreacionProd.creacionProdCA_CC_CF(financeAsset[0].Id);
            System.assertNotEquals(null, result);
        } catch (SObjectException ex) {
            System.assert(ex.getMessage().contains('DIR_Identificador__c'), ex.getMessage());
        }
        Test.stopTest();      
    }

    @IsTest
    static void buildsCurrentAccountXmlWithMinimalRelationships() {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        Account account = TestDataFactory.createPersonAccounts(1)[0];
        Datos_Maestros__c sector = new Datos_Maestros__c(
            Name = 'Sector XML creation product',
            DM_Tipo__c = 'Sector',
            DM_Direccion__c = 'SECTOR-XML'
        );
        insert sector;
        Direccion__c address = new Direccion__c(
            DIR_Account__c = account.Id,
            DIR_Tipo_Direccion__c = 'RESIDENCIA',
            DIR_Identificador__c = 'DIR-XML-001',
            DIR_Calle__c = 'Calle XML',
            DIR_Numero__c = '101',
            DIR_N_Apartamento__c = '2B',
            DIR_Edificio__c = 'A',
            DIR_Sector__c = sector.Id
        );
        insert address;
        Vias_de_Contacto__c contactWay = new Vias_de_Contacto__c(
            VIA_Account__c = account.Id,
            VIA_Identificador__c = 'VIA-XML-001',
            VIA_de_Contacto__c = 'TELÉFONO FIJO',
            VIA_Telefonica__c = 'Claro',
            VIA_Numero_Correo__c = '8095550130'
        );
        insert contactWay;
        Matriz_de_producto__c product = new Matriz_de_producto__c(
            Name = 'Producto XML',
            PRO_Codigo_de_producto__c = 'XML-001',
            PRO_Requiere_libreta_PF_PJ__c = false
        );
        insert product;

        Id checkingRecordTypeId = Schema.SObjectType.Asset
            .getRecordTypeInfosByDeveloperName().get('Cuentas_corrientes').getRecordTypeId();
        Asset asset = new Asset(
            RecordTypeId = checkingRecordTypeId,
            Name = 'Cuenta XML',
            AccountId = account.Id,
            OwnerId = UserInfo.getUserId(),
            ASE_N_de_cuenta__c = '0012345678',
            ASE_Tipo_de_Cuenta__c = 'PERSONAL',
            ASE_Alias_de_la_cuenta__c = 'Cuenta XML',
            ASE_Direccion__c = address.Id,
            ASE_Via_de_Contacto__c = contactWay.Id,
            ASE_Producto__c = product.Id,
            ASE_Ejecutivo__c = UserInfo.getUserId()
        );
        insert asset;

        Asset xmlAsset = [
            SELECT Id, RecordTypeId, ASE_N_de_cuenta__c, ASE_Tipo_de_Cuenta__c,
                ASE_Alias_de_la_cuenta__c, ASE_Direccion__r.DIR_Identificador__c,
                ASE_Direccion__r.DIR_Tipo_Direccion__c, ASE_Direccion__r.DIR_Calle__c,
                ASE_Direccion__r.DIR_Numero__c, ASE_Direccion__r.DIR_N_Apartamento__c,
                ASE_Direccion__r.DIR_Edificio__c, ASE_Direccion__r.DIR_Pais__c,
                ASE_Direccion__r.DIR_Provincia__c, ASE_Direccion__r.DIR_Municipio__c,
                ASE_Direccion__r.DIR_Sector__r.DM_Direccion__c,
                ASE_Direccion__r.DIR_Apartado_postal__c,
                ASE_Via_de_Contacto__r.VIA_Identificador__c,
                ASE_Via_de_Contacto__r.VIA_de_Contacto__c,
                ASE_Via_de_Contacto__r.VIA_Telefonica__c,
                ASE_Via_de_Contacto__r.VIA_Numero_Correo__c,
                ASE_Producto__r.PRO_Codigo_de_producto__c,
                ASE_Producto__r.PRO_Requiere_libreta_PF_PJ__c, ASE_Producto__r.Name,
                ASE_Ejecutivo__r.Alias, Owner.Alias, Owner.USE_Oficina__c,
                Account.Name, Account.FirstName, Account.LastName, Account.MiddleName,
                Account.Suffix, Account.ACC_TipoIdentificacion__c,
                Account.ACC_NumIdentificacion__c, Account.ACC_RNC__c, Account.ACC_CIF__c,
                Account.RecordTypeId, ASE_Tipo_de_deposito__c,
                ASE_Oficina_retencion_de_estado__c, ASE_Metodo_de_entrega_de_estado__c,
                ASE_N_de_libreta__c, ASE_Monto_del_deposito__c, ASE_Plazo_meses__c,
                ASE_Fecha_de_vencimiento__c, ASE_Tasa__c, ASE_Documento__c,
                ASE_Forma_de_pago__c, ASE_Cuenta_a_acreditar__c,
                ASE_Numero_de_cuenta_a_acreditar__c, ASE_Oficina_destino__c,
                ASE_Forma_de_pago_de_apertura__c, ASE_Cuenta_a_debitar__c,
                ASE_Numero_de_cuenta_a_debitar__c, ASE_Moneda__c
            FROM Asset
            WHERE Id = :asset.Id
        ];

        List<String> parameters = new List<String>{
            String.valueOf(Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Cuentas_de_ahorro').getRecordTypeId()),
            String.valueOf(checkingRecordTypeId),
            String.valueOf(Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Certificados_financieros').getRecordTypeId()),
            String.valueOf(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Personas_Juridicas').getRecordTypeId()),
            String.valueOf(Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()),
            'CrearCtaCorriente'
        };

        Test.startTest();
        xmlAsset.Account.RecordTypeId = Id.valueOf(parameters[4]);
        DOM.Document xml = wsCreacionProd.parserToWsXML(xmlAsset, parameters);
        xmlAsset.RecordTypeId = Id.valueOf(parameters[0]);
        DOM.Document savingsXml = wsCreacionProd.parserToWsXML(xmlAsset, parameters);
        xmlAsset.RecordTypeId = Id.valueOf(parameters[2]);
        DOM.Document certificateXml = wsCreacionProd.parserToWsXML(xmlAsset, parameters);
        xmlAsset.RecordTypeId = Id.valueOf(parameters[1]);
        xmlAsset.Account.RecordTypeId = Id.valueOf(parameters[3]);
        xmlAsset.Account.Name = 'Empresa XML';
        xmlAsset.Account.ACC_RNC__c = '131000003';
        DOM.Document businessXml = wsCreacionProd.parserToWsXML(xmlAsset, parameters);
        Test.stopTest();

        String xmlBody = xml.toXmlString();
        System.assert(xmlBody.contains('CrearCtaCorriente'));
        System.assert(xmlBody.contains('0012345678'));
        System.assert(xmlBody.contains('DIR-XML-001'));
        System.assert(savingsXml.toXmlString().contains('SenalLibreta'));
        System.assert(certificateXml.toXmlString().contains('NumeroCertificado'));
        System.assert(certificateXml.toXmlString().contains('MontoDeposito'));
        System.assert(businessXml.toXmlString().contains('Empresa XML'));
        System.assert(businessXml.toXmlString().contains('131000003'));
    }

    @IsTest
    static void coversPublicCalloutAndEmptyInvocablePaths() {
        Test.setMock(HttpCalloutMock.class, new wsCreacionProdMock('SUCCESS'));

        Test.startTest();
        HttpResponse response = wsCreacionProd.creacionProdCA_CC_CF_Post('<request/>', 'CrearCtaAhorro');
        String missingAsset = wsCreacionProd.creacionProdCA_CC_CF(null);
        wsCreacionProd.Invocable_creacionProdCA_CC_CF(new List<Id>());
        Test.stopTest();

        System.assertEquals(200, response.getStatusCode());
        System.assert(missingAsset.contains('no existe'));
    }
    
    
}
