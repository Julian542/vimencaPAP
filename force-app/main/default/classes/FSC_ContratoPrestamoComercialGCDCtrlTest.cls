@IsTest
private class FSC_ContratoPrestamoComercialGCDCtrlTest {

    @IsTest
    static void shouldInitializeControllerFromUnsavedStandardController() {
        Test.startTest();
        FSC_ContratoPrestamoComercialGCDCtrl ctrl = new FSC_ContratoPrestamoComercialGCDCtrl(
            FSC_ContratoPrestamoCtrlTestHelper.buildUnsavedStandardController()
        );
        Test.stopTest();

        FSC_ContratoPrestamoCtrlTestHelper.assertBaseControllerState(ctrl, 83, 'p083');
        System.assertEquals(null, ctrl.loanApplication, 'No debería cargar el RLA si el StandardController no tiene Id.');
        System.assertNotEquals(null, ctrl.mergeFields, 'La colección de placeholders debería inicializarse.');
        System.assertEquals(83, ctrl.mergeFields.size(), 'Debe crear 83 placeholders.');
        System.assertEquals('[p001]', ctrl.getPlaceholderValue('p001'));
        System.assertEquals('[p083]', ctrl.getPlaceholderValue('p083'));
        System.assertEquals('', ctrl.getPlaceholderValue('missing'));
        System.assertEquals(true, ctrl.hasAnnexImage, 'Debe indicar que hay anexo.');
        System.assertEquals('/resource/FSC_ContratoPrestamoComercial_Anexo', ctrl.annexImageUrl);
    }

    @IsTest
    static void shouldHandleInvalidIdParameterGracefully() {
        PageReference pageRef = new PageReference('/apex/FSC_ContratoPrestamoComercialGarantiaCD');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', 'not-a-valid-id');

        FSC_ContratoPrestamoComercialGCDCtrl ctrl = new FSC_ContratoPrestamoComercialGCDCtrl(null);

        System.assertEquals(null, ctrl.loanApplication, 'Con un id inválido no debería intentar cargar el RLA.');
        System.assertEquals(83, ctrl.mergeFields.size());
        System.assertEquals('[p020]', ctrl.getPlaceholderValue('p020'));
    }

    @IsTest
    static void shouldAttemptLoadWhenPageReceivesValidLookingId() {
        PageReference pageRef = new PageReference('/apex/FSC_ContratoPrestamoComercialGarantiaCD');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put(
            'id',
            FSC_ContratoPrestamoCtrlTestHelper.buildFakeResidentialLoanApplicationId()
        );

        try {
            new FSC_ContratoPrestamoComercialGCDCtrl(null);
            System.assert(false, 'Se esperaba QueryException porque el Id no existe realmente.');
        } catch (QueryException e) {
            System.assert(
                e.getMessage().contains('List has no rows for assignment to SObject') ||
                e.getMessage().contains('no rows for assignment'),
                'La excepción debería indicar que la query no devolvió filas. Mensaje real: ' + e.getMessage()
            );
        }
    }

    @IsTest
    static void testFormatDateForTest() {
        System.assertEquals(
            '',
            FSC_ContratoPrestamoComercialGCDCtrl.formatDateForTest(null),
            'Cuando la fecha es null debe devolver vacío.'
        );

        System.assertEquals(
            '15/3/2026',
            FSC_ContratoPrestamoComercialGCDCtrl.formatDateForTest(Date.newInstance(2026, 3, 15)),
            'Debe formatear la fecha como d/m/yyyy.'
        );
    }
}