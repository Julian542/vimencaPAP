public with sharing class FSC_GenerarPDFDesembolsoControlador {
	public String FormulaCedula { get; private set; }
	public String FormulaFecha { get; private set; }
	public String FormulaMontoAprobado { get; private set; }
	public String FormulaNombreCliente { get; private set; }
	public String FormulaOficialActuante { get; private set; }
	public String FSCAyuntamientoRegistroCivil { get; private set; }
	public String FSCClasificacionSib { get; private set; }
	public String FSCCodigoAprobacion { get; private set; }
	public String FSCComisionAdminSeguroMonto { get; private set; }
	public String FSCComisionEndosoPoliza { get; private set; }
	public String FSCConfeccionCheque { get; private set; }
	public String FSCDesembolsoNeto { get; private set; }
	public String FSCFechaAprobacion { get; private set; }
	public String FSCFechaVencimiento { get; private set; }
	public String FSCFechaVencimientoContrato { get; private set; }
	public String FSCFormaDesembolso { get; private set; }
	public String FSCFormaPago { get; private set; }
	public String FSCGastosTramitacion { get; private set; }
	public String FSCHonorariosLegalizacion { get; private set; }
	public String FSCInscripcionHipoteca { get; private set; }
	public String FSCLineaCreditoNumero { get; private set; }
	public String FSCLineaFinanciera { get; private set; }
	public String FSCMontoCuotaRegular { get; private set; }
	public String FSCMontoDesembolsar { get; private set; }
	public String FSCMontoDesembolso { get; private set; }
	public String FSCMontoTotalCuotaMensual { get; private set; }
	public String FSCMora { get; private set; }
	public String FSCTasaFijaPor { get; private set; }
	public String FSCNumeroCliente { get; private set; }
	public String FSCObservaciones { get; private set; }
	public String FSCOtrosGastosLegales { get; private set; }
	public String FSCPlazoMeses { get; private set; }
	public String FSCProductoBanco { get; private set; }
	public String FSCSeguroPropiedadMonto { get; private set; }
	public String FSCNumeroPolizaSeguroVida { get; private set; }
	public String FSCSeguroVidaMonto { get; private set; }
	public String FSCSubAplicacion { get; private set; }
	public String FSCSucursal { get; private set; }
	public String FSCTasaInteres { get; private set; }
	public String FSCTasasServicios { get; private set; }
	public String FSCTipoCredito { get; private set; }
	public String FSCTipoDesembolsoSolicitado { get; private set; }
	public String FSCTipoGarantia { get; private set; }
	public String FSCTotalDescuentos { get; private set; }
	public String FSCTransferenciaInmobiliaria { get; private set; }

	public FSC_GenerarPDFDesembolsoControlador() {
		Map<String, String> p = ApexPages.currentPage().getParameters();
		FormulaCedula = p.get('FormulaCedula');
		if (p.get('FormulaFecha') != null) {
			FormulaFecha = ((Datetime) JSON.deserialize('"' + p.get('FormulaFecha') + '"', Datetime.class)).formatGMT('dd-MM-yyyy');
		}
		FormulaMontoAprobado = p.get('FormulaMontoAprobado');
		FormulaNombreCliente = p.get('FormulaNombreCliente');
		FormulaOficialActuante = p.get('FormulaOficialActuante');
		FSCAyuntamientoRegistroCivil = p.get('FSC_AyuntamientoRegistroCivil__c');
		FSCClasificacionSib = p.get('FSC_ClasificacionSib__c');
		FSCCodigoAprobacion = p.get('FSC_CodigoAprobacion__c');
		FSCComisionAdminSeguroMonto = p.get('FSC_ComisionAdminSeguroMonto__c');
		FSCComisionEndosoPoliza = p.get('FSC_ComisionEndosoPoliza__c');
		FSCConfeccionCheque = p.get('FSC_ConfeccionCheque__c');
		FSCDesembolsoNeto = p.get('FSC_DesembolsoNeto__c');
		if (p.get('FSC_FechaAprobacion__c') != null) {
			FSCFechaAprobacion = ((Datetime) JSON.deserialize('"' + p.get('FSC_FechaAprobacion__c') + '"', Datetime.class)).formatGMT('dd-MM-yyyy');
		}
		if (p.get('FSC_FechaVencimiento__c') != null) {
			FSCFechaVencimiento = ((Datetime) JSON.deserialize('"' + p.get('FSC_FechaVencimiento__c') + '"', Datetime.class)).formatGMT('dd-MM-yyyy');
		}
		if (p.get('FSC_FechaVencimientoContrato__c') != null) {
			FSCFechaVencimientoContrato = ((Datetime) JSON.deserialize('"' + p.get('FSC_FechaVencimientoContrato__c') + '"', Datetime.class))
				.formatGMT('dd-MM-yyyy');
		}
		FSCFormaDesembolso = p.get('FSC_FormaDesembolso__c');
		FSCFormaPago = p.get('FSC_FormaPago__c');
		FSCGastosTramitacion = p.get('FSC_GastosTramitacion__c');
		FSCHonorariosLegalizacion = p.get('FSC_HonorariosLegalizacion__c');
		FSCInscripcionHipoteca = p.get('FSC_InscripcionHipoteca__c');
		FSCLineaCreditoNumero = p.get('FSC_LineaCreditoNumero__c');
		FSCLineaFinanciera = p.get('FSC_LineaFinanciera__c');
		FSCMontoCuotaRegular = p.get('FSC_MontoCuotaRegular__c');
		FSCMontoDesembolsar = p.get('FSC_MontoDesembolsar__c');
		FSCMontoDesembolso = p.get('FSC_MontoDesembolsar__c');
		FSCMontoTotalCuotaMensual = p.get('FSC_MontoTotalCuotaMensual__c');
		FSCMora = p.get('FSC_Mora__c');
		FSCTasaFijaPor = p.get('FSC_TasaFijaPorMeses__c');
		FSCNumeroCliente = p.get('FSC_NumeroCliente__c');
		FSCObservaciones = p.get('FSC_Observaciones__c');
		FSCOtrosGastosLegales = p.get('FSC_OtrosGastosLegales__c');
		FSCPlazoMeses = p.get('FSC_PlazoMeses__c');
		FSCProductoBanco = p.get('FSC_ProductoBanco__c');
		FSCSeguroPropiedadMonto = p.get('FSC_SeguroPropiedadMonto__c');
		FSCNumeroPolizaSeguroVida = p.get('FSC_NumeroPolizaSeguroDeVida__c');
		FSCSeguroVidaMonto = p.get('FSC_SeguroVidaMonto__c');
		FSCSubAplicacion = p.get('FSC_SubAplicacion__c');
		FSCSucursal = p.get('FSC_Sucursal__c');
		FSCTasaInteres = p.get('FSC_TasaInteres__c');
		FSCTasasServicios = p.get('FSC_TasasServicios__c');
		FSCTipoCredito = p.get('FSC_TipoCredito__c');
		FSCTipoDesembolsoSolicitado = p.get('FSC_TipoDesembolsoSolicitado__c');
		FSCTipoGarantia = p.get('FSC_TipoGarantia__c');
		FSCTotalDescuentos = p.get('FSC_TotalDescuentos__c');
		FSCTransferenciaInmobiliaria = p.get('FSC_TransferenciaInmobiliaria__c');
	}
}