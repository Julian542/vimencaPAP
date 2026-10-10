@IsTest
private class FSC_RLAContractTplResTest {

    @IsTest
    static void testResolvePageReference_DefaultTemplate() {
        ResidentialLoanApplication solicitud = createPyme('sola firma', 'Sin Garantía', '1');

        Test.startTest();
        PageReference pageRef = FSC_RLAContractTemplateResolver.resolvePageReference(solicitud.Id);
        Test.stopTest();

        System.assertNotEquals(null, pageRef, 'El PageReference no debe ser null.');

        String url = pageRef.getUrl();
        System.assertNotEquals(null, url, 'La URL no debe ser null.');

        String normalizedUrl = url.toLowerCase();
        System.assert(
            normalizedUrl.startsWith('/apex/fsc_contratoprestamocomercialsf'),
            'El PageReference debe apuntar al contrato de sola firma. URL actual: ' + url
        );
        System.assert(
            normalizedUrl.contains('id=' + String.valueOf(solicitud.Id).toLowerCase()),
            'La URL debe incluir el parámetro id. URL actual: ' + url
        );
    }

    @IsTest
    static void testResolvePageReference_NullId_ThrowsException() {
        try {
            Test.startTest();
            FSC_RLAContractTemplateResolver.resolvePageReference(null);
            Test.stopTest();
            System.assert(false, 'Se esperaba una excepción cuando el Id es null.');
        } catch (FSC_RLAContractTemplateResolver.FSC_RLAContractTemplateResolverException e) {
            System.assert(
                e.getMessage().contains('Se requiere el Id de la solicitud'),
                'El mensaje de error no fue el esperado. Mensaje actual: ' + e.getMessage()
            );
        }
    }

    @IsTest
    static void testResolvePageReference_AllExplicitTemplates() {
        Id anyId = UserInfo.getUserId();
        List<String> templateCodes = new List<String>{
            FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION,
            FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_HIPOTECARIA,
            FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION,
            FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_SOLIDARIA
        };

        Test.startTest();
        for (String templateCode : templateCodes) {
            PageReference pageRef = FSC_RLAContractTemplateResolver.resolvePageReference(anyId, templateCode);
            System.assertNotEquals(null, pageRef, 'Debe resolver template ' + templateCode);
            System.assert(
                pageRef.getUrl().toLowerCase().contains('id=' + String.valueOf(anyId).toLowerCase()),
                'La URL debe incluir el id para ' + templateCode
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testResolvePageReference_BlankAndUnknownTemplateThrowException() {
        Id anyId = UserInfo.getUserId();

        try {
            FSC_RLAContractTemplateResolver.resolvePageReference(anyId, ' ');
            System.assert(false, 'Se esperaba excepcion por template en blanco.');
        } catch (FSC_RLAContractTemplateResolver.FSC_RLAContractTemplateResolverException e) {
            System.assert(e.getMessage().contains('Se requiere la solicitud y el tipo de contrato'));
        }

        try {
            FSC_RLAContractTemplateResolver.resolvePageReference(anyId, 'NO_EXISTE');
            System.assert(false, 'Se esperaba excepcion por template desconocido.');
        } catch (FSC_RLAContractTemplateResolver.FSC_RLAContractTemplateResolverException e) {
            System.assert(e.getMessage().contains('No existe una página para el tipo de contrato'));
        }
    }

    @IsTest
    static void testResolvePymeGuaranteeTemplatesAndMetadataTypes() {
        ResidentialLoanApplication mortgage = createPyme('hipoteca', 'Garantía Real', '1');
        insert new LoanApplicationAsset(
            Name = 'Inmueble resolver',
            LoanApplicationId = mortgage.Id,
            AssetClass = 'Bienes inmuebles',
            AssetType = 'Otro',
            FSC_Descripcion_de_la_Garantia__c = '3'
        );

        ResidentialLoanApplication vehicle = createPyme('vehículo', 'Garantía Prendaria y/o Mobiliaria', '1');
        insert new LoanApplicationAsset(
            Name = 'Vehículo resolver',
            LoanApplicationId = vehicle.Id,
            AssetClass = 'Otro',
            AssetType = 'Otro',
            FSC_Descripcion_de_la_Garantia__c = '28'
        );

        ResidentialLoanApplication certificate = createPyme('certificado', 'Garantía Prendaria y/o Mobiliaria', '2');
        insert new LoanApplicationAsset(
            Name = 'Certificado resolver',
            LoanApplicationId = certificate.Id,
            AssetClass = 'Financiero',
            AccountType = 'Certificado de depósito',
            FSC_Descripcion_de_la_Garantia__c = '31'
        );

        Test.startTest();
        FSC_RLAContractTemplateResolver.ContractResolution mortgageResolution = FSC_RLAContractTemplateResolver.resolve(mortgage.Id);
        FSC_RLAContractTemplateResolver.ContractResolution vehicleResolution = FSC_RLAContractTemplateResolver.resolve(vehicle.Id);
        FSC_RLAContractTemplateResolver.ContractResolution certificateResolution = FSC_RLAContractTemplateResolver.resolve(certificate.Id);
        Test.stopTest();

        System.assertEquals(FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_HIPOTECARIA, mortgageResolution.templateCode);
        System.assertEquals(FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION, vehicleResolution.templateCode);
        System.assertEquals(FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION, certificateResolution.templateCode);
        System.assertEquals('HIPOTECARIO', FSC_RLAContractTemplateResolver.getMetadataContractType(mortgageResolution.templateCode));
        System.assertEquals('MOBILIARIO_SIN_POSESION', FSC_RLAContractTemplateResolver.getMetadataContractType(vehicleResolution.templateCode));
        System.assertEquals('MOBILIARIO_CON_POSESION', FSC_RLAContractTemplateResolver.getMetadataContractType(certificateResolution.templateCode));
        System.assert(certificateResolution.tituloArchivo.endsWith('EN DOLARES'));
        System.assertEquals(null, FSC_RLAContractTemplateResolver.getMetadataContractType('NO_EXISTE'));
    }

    private static ResidentialLoanApplication createPyme(String suffix, String guaranteeType, String currencyCode) {
        Account account = new Account(Name = 'Cuenta resolver ' + suffix);
        insert account;
        ResidentialLoanApplication solicitud = new ResidentialLoanApplication(
            Name = 'Solicitud resolver ' + suffix,
            AccountId = account.Id,
            RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
                .get('FSC_Solicitud_Credito_PYME').getRecordTypeId(),
            Status = 'En proceso',
            FSC_Subestado__c = 'Generación de contrato',
            FSC_TipoSolicitud__c = 'BPR',
            FSC_Moneda__c = currencyCode,
            FSC_Tipo_de_Garantia__c = guaranteeType
        );
        insert solicitud;
        return solicitud;
    }
}