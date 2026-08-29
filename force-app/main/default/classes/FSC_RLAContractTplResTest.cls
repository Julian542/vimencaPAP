@IsTest
private class FSC_RLAContractTplResTest {

 @IsTest
    static void testResolvePageReference_DefaultTemplate() {
        Id anyId = UserInfo.getUserId();

        Test.startTest();
        PageReference pageRef = FSC_RLAContractTemplateResolver.resolvePageReference(anyId);
        Test.stopTest();

        System.assertNotEquals(null, pageRef, 'El PageReference no debe ser null.');

        String url = pageRef.getUrl();
        System.assertNotEquals(null, url, 'La URL no debe ser null.');

        String normalizedUrl = url.toLowerCase();
        System.assert(
            normalizedUrl.startsWith('/apex/fsc_contratoprestamocomercialgarantiacd'),
            'El PageReference debe apuntar al template por defecto. URL actual: ' + url
        );
        System.assert(
            normalizedUrl.contains('id=' + String.valueOf(anyId).toLowerCase()),
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
                e.getMessage().contains('Se requiere el Id de ResidentialLoanApplication'),
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
            System.assert(e.getMessage().contains('código de template'));
        }

        try {
            FSC_RLAContractTemplateResolver.resolvePageReference(anyId, 'NO_EXISTE');
            System.assert(false, 'Se esperaba excepcion por template desconocido.');
        } catch (FSC_RLAContractTemplateResolver.FSC_RLAContractTemplateResolverException e) {
            System.assert(e.getMessage().contains('No existe una Visualforce Page'));
        }
    }
}