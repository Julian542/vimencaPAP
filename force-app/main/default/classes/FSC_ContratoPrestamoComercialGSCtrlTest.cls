@IsTest
private class FSC_ContratoPrestamoComercialGSCtrlTest {

    @IsTest
    static void shouldInitializeControllerFromUnsavedStandardController() {
        Test.startTest();
        FSC_ContratoPrestamoComercialGSCtrl ctrl = new FSC_ContratoPrestamoComercialGSCtrl(
            FSC_ContratoPrestamoCtrlTestHelper.buildUnsavedStandardController()
        );
        Test.stopTest();

        FSC_ContratoPrestamoCtrlTestHelper.assertBaseControllerState(ctrl, 76, 'p076');
        System.assertEquals(null, ctrl.loanApplication, 'No debería cargar el RLA si el StandardController no tiene Id.');
        System.assertNotEquals(null, ctrl.mergeFields, 'La colección de placeholders debería inicializarse.');
        System.assertEquals(76, ctrl.mergeFields.size(), 'Debe crear 76 placeholders.');
        System.assertEquals('[p001]', ctrl.getPlaceholderValue('p001'));
        System.assertEquals('[p076]', ctrl.getPlaceholderValue('p076'));
        System.assertEquals('', ctrl.getPlaceholderValue('missing'));
        System.assertEquals(true, ctrl.hasAnnexImage, 'Debe indicar que hay anexo.');
        System.assertEquals('/resource/FSC_ContratoPrestamoComercial_Anexo', ctrl.annexImageUrl);
    }

    @IsTest
    static void shouldHandleInvalidIdParameterGracefully() {
        PageReference pageRef = new PageReference('/apex/FSC_ContratoPrestamoComercialGS');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', 'not-a-valid-id');

        FSC_ContratoPrestamoComercialGSCtrl ctrl = new FSC_ContratoPrestamoComercialGSCtrl(null);

        System.assertEquals(null, ctrl.loanApplication, 'Con un id inválido no debería intentar cargar el RLA.');
        System.assertEquals(76, ctrl.mergeFields.size());
        System.assertEquals('[p040]', ctrl.getPlaceholderValue('p040'));
    }

    @IsTest
    static void shouldAttemptLoadWhenPageReceivesValidLookingId() {
        PageReference pageRef = new PageReference('/apex/FSC_ContratoPrestamoComercialGS');
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put(
            'id',
            FSC_ContratoPrestamoCtrlTestHelper.buildFakeResidentialLoanApplicationId()
        );

        try {
            new FSC_ContratoPrestamoComercialGSCtrl(null);
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
            FSC_ContratoPrestamoComercialGSCtrl.formatDateForTest(null),
            'Cuando la fecha es null debe devolver vacío.'
        );

        System.assertEquals(
            '15/3/2026',
            FSC_ContratoPrestamoComercialGSCtrl.formatDateForTest(Date.newInstance(2026, 3, 15)),
            'Debe formatear la fecha como d/m/yyyy.'
        );
    }
}