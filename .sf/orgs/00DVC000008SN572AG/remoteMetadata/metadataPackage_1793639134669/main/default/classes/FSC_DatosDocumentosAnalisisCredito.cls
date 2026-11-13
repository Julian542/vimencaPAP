/**
 * Modelo de presentación compartido por los PDF de análisis de crédito.
 */
public class FSC_DatosDocumentosAnalisisCredito {
	public String numeroSolicitud { get; set; }
	public String tipoPrestamo { get; set; }
	public Boolean esVehiculo { get; set; }
	public Boolean esHipotecario { get; set; }
	public String solicitante { get; set; }
	public String cedula { get; set; }
	public String destino { get; set; }
	public String oficialNegocios { get; set; }
	public String sucursal { get; set; }
	public String analista { get; set; }
	public String fechaEvaluacion { get; set; }
	public String exposicionTotal { get; set; }
	public String garantiaResumen { get; set; }
	public String montoSolicitado { get; set; }
	public String plazoMeses { get; set; }
	public String tasaInteres { get; set; }
	public String tiempoTasaFija { get; set; }
	public String cuotaEstimada { get; set; }
	public String tasaCambio { get; set; }
	public Boolean esMonedaPesos { get; set; }
	public Boolean esMonedaDolar { get; set; }
	public Map<String, String> montosPesos { get; set; }
	public Map<String, String> montosDolares { get; set; }
	public Map<String, String> totalesPesos { get; set; }
	public String edad { get; set; }
	public String estadoCivil { get; set; }
	public String dependientes { get; set; }
	public String residencial { get; set; }
	public String nacionalidad { get; set; }
	public String actividadEconomica { get; set; }
	public String antiguedadLaboral { get; set; }
	public String ingresosMensualesPromedio { get; set; }
	public String evidenciaIngresos { get; set; }
	public String cuotasFinancieras { get; set; }
	public String relacionCuotaIngresos { get; set; }
	public String endeudamientoTotal { get; set; }
	public String solvenciaEstimada { get; set; }
	public Boolean mostrarGarantia { get; set; }
	public String garantiaTipo { get; set; }
	public String garantiaUbicacion { get; set; }
	public String garantiaSuperficie { get; set; }
	public String garantiaTasador { get; set; }
	public String garantiaFechaTasacion { get; set; }
	public String garantiaValorTasacion { get; set; }
	public String garantiaPrecioVenta { get; set; }
	public String garantiaPagoInicial { get; set; }
	public String garantiaMarca { get; set; }
	public String garantiaModelo { get; set; }
	public String garantiaAno { get; set; }
	public String prestamoSobreTasacion { get; set; }
	public String prestamoSobrePrecioVenta { get; set; }
	public String scoreCrediticio { get; set; }
	public String scorePredictivo { get; set; }
	public String scoreInterno { get; set; }
	public String clasificacionRiesgo { get; set; }
	public String perfilRiesgo { get; set; }
	public String moraTc30 { get; set; }
	public String moraTc60 { get; set; }
	public String moraTc90 { get; set; }
	public String moraPrestamo30 { get; set; }
	public String moraPrestamo60 { get; set; }
	public String moraPrestamo90 { get; set; }
	public String historialPago { get; set; }
	public String excepciones { get; set; }
	public String recomendacion { get; set; }
	public String fechaAprobacion { get; set; }
	public String montoAprobado { get; set; }
	public String ingresoCartaTrabajo { get; set; }
	public String ingresoDepositos { get; set; }
	public String ingresoAlquiler { get; set; }
	public String ingresoInversiones { get; set; }
	public String ingresoOtros { get; set; }
	public String ingresoEstadosFinancieros { get; set; }
	public String totalIngresos { get; set; }
	public String deudaTarjetas { get; set; }
	public String deudaPrestamos { get; set; }
	public String totalAdeudado { get; set; }
	public String cuotaTarjetas { get; set; }
	public String cuotaPrestamos { get; set; }
	public String cuotaNuevoPrestamo { get; set; }
	public String cuotasCancelar { get; set; }
	public String deudaTarjetasCancelar { get; set; }
	public String totalPagosCreditos { get; set; }
	public String pagoVivienda { get; set; }
	public String totalPagos { get; set; }
	public String cargaFinanciera { get; set; }
	public String resultadoCargaFinanciera { get; set; }
	public String capacidadIncluyendoVivienda { get; set; }
	public String resultadoCapacidadVivienda { get; set; }
	public String totalActivos { get; set; }
	public String totalPasivos { get; set; }
	public String patrimonio { get; set; }
	public String indiceApalancamiento { get; set; }
	public String resultadoApalancamiento { get; set; }
	public String capacidadEndeudamiento { get; set; }
	public String resultadoEndeudamiento { get; set; }
	public String comentarios { get; set; }

	/** Inicializa las banderas consumidas por Visualforce. */
	public FSC_DatosDocumentosAnalisisCredito() {
		esVehiculo = false;
		esHipotecario = false;
		mostrarGarantia = false;
		esMonedaPesos = true;
		esMonedaDolar = false;
		montosPesos = new Map<String, String>();
		montosDolares = new Map<String, String>();
		totalesPesos = new Map<String, String>();
	}
}