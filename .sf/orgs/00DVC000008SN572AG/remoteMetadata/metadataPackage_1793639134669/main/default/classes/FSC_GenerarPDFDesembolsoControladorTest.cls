@IsTest
private class FSC_GenerarPDFDesembolsoControladorTest {
	@IsTest
	static void testController_AssignsParams_AndFormatsDates() {
		PageReference pr = Page.FSC_GenerarPDFDesembolso;

		pr.getParameters().put('FormulaCedula', '001-0000000-0');
		pr.getParameters().put('FormulaFecha', '2026-01-31T19:42:46.000Z');
		pr.getParameters().put('FormulaMontoAprobado', '1000000');
		pr.getParameters().put('FormulaNombreCliente', 'Juan Perez');
		pr.getParameters().put('FormulaOficialActuante', 'OF-001');

		pr.getParameters().put('FSC_AyuntamientoRegistroCivil__c', 'Ayuntamiento X');
		pr.getParameters().put('FSC_ClasificacionSib__c', 'A1');
		pr.getParameters().put('FSC_CodigoAprobacion__c', 'APR-777');
		pr.getParameters().put('FSC_ComisionAdminSeguroMonto__c', '150.00');
		pr.getParameters().put('FSC_ComisionEndosoPoliza__c', '50.00');
		pr.getParameters().put('FSC_ConfeccionCheque__c', '10.00');
		pr.getParameters().put('FSC_DesembolsoNeto__c', '999.00');

		pr.getParameters().put('FSC_FechaAprobacion__c', '2026-01-15T03:00:00.000Z');
		pr.getParameters().put('FSC_FechaVencimiento__c', '2027-12-31T03:00:00.000Z');
		pr.getParameters().put('FSC_FechaVencimientoContrato__c', '2028-06-30T03:00:00.000Z');

		pr.getParameters().put('FSC_FormaDesembolso__c', 'Parcial');
		pr.getParameters().put('FSC_FormaPago__c', 'Transferencia');
		pr.getParameters().put('FSC_GastosTramitacion__c', '100.00');
		pr.getParameters().put('FSC_HonorariosLegalizacion__c', '200.00');
		pr.getParameters().put('FSC_InscripcionHipoteca__c', '300.00');
		pr.getParameters().put('FSC_LineaCreditoNumero__c', 'LC-123');
		pr.getParameters().put('FSC_LineaFinanciera__c', 'LF-01');
		pr.getParameters().put('FSC_MontoCuotaRegular__c', '15000.00');
		pr.getParameters().put('FSC_MontoDesembolsar__c', '500000.00');
		pr.getParameters().put('FSC_MontoDesembolso__c', '500000.00');
		pr.getParameters().put('FSC_MontoTotalCuotaMensual__c', '15500.00');
		pr.getParameters().put('FSC_Mora__c', '0.00');
		pr.getParameters().put('FSC_NumeroCliente__c', 'C-999');
		pr.getParameters().put('FSC_Observaciones__c', 'Obs test');
		pr.getParameters().put('FSC_OtrosGastosLegales__c', '25.00');
		pr.getParameters().put('FSC_PlazoMeses__c', '240');
		pr.getParameters().put('FSC_ProductoBanco__c', 'Hipotecario X');
		pr.getParameters().put('FSC_SeguroPropiedadMonto__c', '12.00');
		pr.getParameters().put('FSC_SeguroVidaMonto__c', '30.00');
		pr.getParameters().put('FSC_SubAplicacion__c', 'SUB-01');
		pr.getParameters().put('FSC_Sucursal__c', 'SUC-01');
		pr.getParameters().put('FSC_TasaFijaPorMeses__c', '13');
		pr.getParameters().put('FSC_TasaInteres__c', '12.5');
		pr.getParameters().put('FSC_TasasServicios__c', '5.00');
		pr.getParameters().put('FSC_TipoCredito__c', 'Residencial');
		pr.getParameters().put('FSC_TipoDesembolsoSolicitado__c', 'Total');
		pr.getParameters().put('FSC_TipoGarantia__c', 'Hipoteca');
		pr.getParameters().put('FSC_TotalDescuentos__c', '500.00');
		pr.getParameters().put('FSC_TransferenciaInmobiliaria__c', '3%');

		Test.setCurrentPage(pr);

		FSC_GenerarPDFDesembolsoControlador c = new FSC_GenerarPDFDesembolsoControlador();

		System.assertEquals('001-0000000-0', c.FormulaCedula);
		System.assertEquals('Juan Perez', c.FormulaNombreCliente);
		System.assertEquals('OF-001', c.FormulaOficialActuante);
		System.assertEquals('Ayuntamiento X', c.FSCAyuntamientoRegistroCivil);
		System.assertEquals('A1', c.FSCClasificacionSib);
		System.assertEquals('APR-777', c.FSCCodigoAprobacion);

		System.assertEquals('31-01-2026', c.FormulaFecha);
		System.assertEquals('15-01-2026', c.FSCFechaAprobacion);
		System.assertEquals('31-12-2027', c.FSCFechaVencimiento);
		System.assertEquals('30-06-2028', c.FSCFechaVencimientoContrato);

		System.assertEquals('Parcial', c.FSCFormaDesembolso);
		System.assertEquals('SUC-01', c.FSCSucursal);
		System.assertEquals('500000.00', c.FSCMontoDesembolsar);
		System.assertEquals('500000.00', c.FSCMontoDesembolso);
		System.assertEquals('13', c.FSCTasaFijaPor);
		System.assertEquals('12.5', c.FSCTasaInteres);
		System.assertEquals('Obs test', c.FSCObservaciones);
	}

	@IsTest
	static void testController_OptionalDatesNull_DoNotThrow() {
		PageReference pr = Page.FSC_GenerarPDFDesembolso;
		pr.getParameters().put('FormulaFecha', '2027-01-31T03:00:00.000Z');

		Test.setCurrentPage(pr);

		FSC_GenerarPDFDesembolsoControlador c = new FSC_GenerarPDFDesembolsoControlador();

		System.assertEquals('31-01-2027', c.FormulaFecha);
		System.assertEquals(null, c.FSCFechaAprobacion);
		System.assertEquals(null, c.FSCFechaVencimiento);
		System.assertEquals(null, c.FSCFechaVencimientoContrato);
	}
}