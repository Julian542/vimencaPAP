@IsTest
private class FSC_ContratoFormatoServiceTest {
    @IsTest
    static void shouldCoverFormattingHelpers() {
        System.assertEquals('', FSC_ContratoFormatoService.formatearMonto(null));
        System.assertEquals('1,234.50', FSC_ContratoFormatoService.formatearMonto(1234.5));
        System.assertEquals('-12.30', FSC_ContratoFormatoService.formatearMonto(-12.3));

        System.assertEquals('', FSC_ContratoFormatoService.montoEnLetras(null, '1'));
        System.assert(FSC_ContratoFormatoService.montoEnLetras(1000000, '1').contains('DE PESOS'));
        System.assert(FSC_ContratoFormatoService.montoEnLetras(21.25, '2').contains('DÓLARES'));
        System.assertEquals('', FSC_ContratoFormatoService.decimalEnLetras(null));
        System.assertEquals('DIEZ', FSC_ContratoFormatoService.decimalEnLetras(10));
        System.assert(FSC_ContratoFormatoService.decimalEnLetras(10.25).contains('PUNTO'));

        List<Long> values = new List<Long>{
            0, -1, 1, 15, 16, 17, 20, 21, 22, 23, 26, 30, 31,
            100, 101, 999, 1000, 1001, 2000, 999999,
            1000000, 1000001, 2000000, 1000000000000L
        };
        for (Long value : values) {
            System.assertNotEquals('', FSC_ContratoFormatoService.numeroEnLetras(value));
        }
        System.assertEquals('', FSC_ContratoFormatoService.numeroEnLetras(null));
        System.assertEquals('VEINTIÚN', FSC_ContratoFormatoService.numeroMasculinoEnLetras(21));

        System.assertEquals('', FSC_ContratoFormatoService.fechaCompleta(null));
        System.assertEquals('', FSC_ContratoFormatoService.fechaCortaEnLetras(null));
        System.assert(FSC_ContratoFormatoService.fechaCompleta(Date.newInstance(2026, 9, 3)).contains('septiembre'));
        System.assert(FSC_ContratoFormatoService.fechaCortaEnLetras(Date.newInstance(2026, 1, 1)).contains('enero'));

        System.assertEquals(null, FSC_ContratoFormatoService.calcularCuota(null, 10, 12));
        System.assertEquals(null, FSC_ContratoFormatoService.calcularCuota(1000, null, 12));
        System.assertEquals(null, FSC_ContratoFormatoService.calcularCuota(1000, 10, 0));
        System.assertEquals(100, FSC_ContratoFormatoService.calcularCuota(1200, 0, 12));
        System.assertNotEquals(null, FSC_ContratoFormatoService.calcularCuota(1200, 12, 12));

        System.assertEquals('US$', FSC_ContratoFormatoService.simboloMoneda('2'));
        System.assertEquals('RD$', FSC_ContratoFormatoService.simboloMoneda('1'));
        System.assertEquals('dólares estadounidenses', FSC_ContratoFormatoService.nombreMoneda('2'));
        System.assertEquals('pesos dominicanos', FSC_ContratoFormatoService.nombreMoneda('1'));
        System.assertEquals('', FSC_ContratoFormatoService.mes(null));
        System.assertEquals('', FSC_ContratoFormatoService.mes(0));
        System.assertEquals('', FSC_ContratoFormatoService.mes(13));
        System.assertEquals('diciembre', FSC_ContratoFormatoService.mes(12));
    }
}