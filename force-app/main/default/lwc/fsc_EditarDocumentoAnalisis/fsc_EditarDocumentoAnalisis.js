import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDatosDocumentoAnalisis from '@salesforce/apex/FSC_RlaAccionesController.getDatosDocumentoAnalisis';
import guardarYRegenerarDocumentoAnalisis from '@salesforce/apex/FSC_RlaAccionesController.guardarYRegenerarDocumentoAnalisis';

const INFORME = 'INFORME';
const CAPACIDAD = 'CAPACIDAD';
const TEXT = 'text';
const INTEGER = 'integer';
const NUMBER = 'number';
const MONEY = 'money';
const MONEY_DOP = 'moneyDop';
const MONEY_USD = 'moneyUsd';
const PERCENT = 'percent';
const DATE = 'date';

// Los resultados calculados se muestran, pero no se editan.
const INFORME_FORMULA_FIELD_KEYS = new Set([
	'edad',
	'exposicionTotal',
	'prestamoSobreTasacion',
	'prestamoSobrePrecioVenta'
]);
const CAPACITY_CALCULATED_ROW_KEYS = new Set(['totalIngresos', 'totalAdeudado', 'totalPagosCreditos', 'totalPagos']);
const CAPACITY_FORMULA_FIELD_KEYS = new Set([
	'prestamoSobreTasacion',
	'montosPesos.cuotaTarjetas',
	'montosDolares.cuotaTarjetas',
	'cargaFinanciera',
	'resultadoCargaFinanciera',
	'capacidadIncluyendoVivienda',
	'resultadoCapacidadVivienda',
	'indiceApalancamiento',
	'resultadoApalancamiento',
	'capacidadEndeudamiento',
	'resultadoEndeudamiento',
	'patrimonio'
]);
const PYME_FORMULA_FIELD_KEYS = new Set([
	'tasaCambioUsd',
	'tasaCambioEuro',
	'deudaSistemaFinanciero',
	'exposicionConsolidadaBv',
	'cobertura',
	'certificadosTotalMontoApertura',
	'certificadosTotalBalance',
	'cuentasTotalBalancePromedio',
	'cuentasTotalDepositosPromedio',
	'productosBvTotalBalance',
	'productosBvTotalAutorizado',
	'creditosOtrosTotalDeuda',
	'compromisosTotalBalance',
	'compromisosTotalCuotas',
	'disponibilidadPorcentajeBalance',
	'disponibilidadPorcentajeFlujo',
	'utilidadNeta',
	'activosTotales',
	'pasivosTotales',
	'patrimonio',
	'apalancamiento',
	'activosFijos',
	'deudasBancarias'
]);

const CAPACITY_INCOME_DETAIL_KEYS = [
	'ingresoCartaTrabajo',
	'ingresoDepositos',
	'ingresoAlquiler',
	'ingresoInversiones',
	'ingresoOtros',
	'ingresoEstadosFinancieros'
];
const CAPACITY_DEBT_DETAIL_KEYS = ['deudaTarjetas', 'deudaPrestamos'];
const CAPACITY_PAYMENT_DETAIL_KEYS = ['cuotaTarjetas', 'cuotaPrestamos', 'cuotaNuevoPrestamo'];
const CAPACITY_PAYMENT_CANCEL_KEYS = ['cuotasCancelar', 'deudaTarjetasCancelar'];
const CARD_MINIMUM_PAYMENT_RATE = 0.08;
const CAPACITY_ALL_KEYS = [
	...CAPACITY_INCOME_DETAIL_KEYS,
	'totalIngresos',
	...CAPACITY_DEBT_DETAIL_KEYS,
	'totalAdeudado',
	...CAPACITY_PAYMENT_DETAIL_KEYS,
	...CAPACITY_PAYMENT_CANCEL_KEYS,
	'totalPagosCreditos',
	'pagoVivienda',
	'totalPagos'
];

const field = (key, label, format = TEXT, options = {}) => ({ key, label, format, ...options });
const options = (values) => values.map((value) => ({ label: value || '-- Ninguno --', value }));

const SECTOR_ECONOMICO_OPTIONS = options([
	'',
	'Comercio',
	'Construcción',
	'Industria',
	'Servicios',
	'Inmobiliario',
	'Manufactura',
	'Financiero',
	'Agropecuario',
	'Otro'
]);
const CLASIFICACION_RIESGO_OPTIONS = options(['', 'A', 'B', 'C', 'D1', 'D2', 'E', 'N/D']);
const TIPO_DEUDOR_OPTIONS = options(['', 'Menor Deudor', 'Mediano Deudor', 'Mayor Deudor', 'Sin clásificación']);
const TIPO_TRAMITACION_OPTIONS = options([
	'',
	'Nuevo',
	'Aumento',
	'Renovación',
	'Refinanciamiento',
	'Liberación de Garantía',
	'Inclusión de Garantía',
	'Revisión Anual',
	'Disminución',
	'Liquidación | Plan de Pagos',
	'Consolidación',
	'Cambio | Sustitución de Garantía',
	'Otro | Especificar en comentarios'
]);
const TIPO_GARANTIA_OPTIONS = options([
	'',
	'Hipotecaria',
	'Solidaria',
	'Mobiliaria',
	'Prendaria',
	'A sola firma',
	'Warrants de Inventario',
	'Otro'
]);
const TIPO_CREDITO_OPTIONS = options(['', 'Línea de Crédito', 'Préstamo Comercial', 'Tarjeta de Crédito']);
const TIPO_BIEN_GARANTIA_OPTIONS = options([
	'',
	'Terreno',
	'Vivienda Familiar',
	'Local Comercial',
	'Solar Yermo',
	'Apartamento',
	'Edificio',
	'Plaza',
	'Vehículo Liviano Nuevo',
	'Vehículo Pesado Nuevo',
	'Vehículo Comercial',
	'Certificado Financieros BV',
	'Certificado Financiero Otros Bancos',
	'Certificado CEVALDOM',
	'Vehículo Liviano Usado',
	'Vehículo Pesado Usado',
	'N/A'
]);
const SI_NO_OPTIONS = options(['', 'SI', 'NO']);
const DECISION_OPTIONS = options([
	'',
	'-|-',
	'APROBADO CON SALVEDADES',
	'APROBADO SIN SALVEDADES',
	'APROBADO BAJO RECOMENDACIÓN AC',
	'DECLINADO',
	'APLAZADO'
]);
const INSTANCIA_OPTIONS = options(['', '-|-', 'Instancias de Aprobación', 'Comité de Crédito I']);
const ANALISTA_OPTIONS = options([
	'',
	'Jeffrey Omar Reyes Peña',
	'Alexis Alberto Soto Martínez',
	'Enrique Alberto Díaz Matos',
	'Miguel Salas Mauricio',
	'Kenia Margarita Sena Calderon',
	'Ashley Nicole Santana Martínez',
	'Marcial José Suárez Goyco'
]);
const REVISOR_OPTIONS = options([
	'',
	'Jeffrey Omar Reyes Peña',
	'Alexis Alberto Soto Martínez',
	'Enrique Alberto Díaz Matos',
	'Miguel Salas Mauricio',
	'Kenia Margarita Sena Calderon',
	'-|-'
]);
const CAPACIDAD_OPTIONS = options(['', 'Excedente', 'Suficiente', 'Insuficiente', '-|-']);

const INFORME_BASE = [
	{
		title: 'DATOS GENERALES DEL CLIENTE',
		fields: [
			field('solicitante', 'Solicitante'),
			field('cedula', 'Cédula'),
			field('destino', 'Destino', TEXT, { wide: true, maxlength: 255 }),
			field('oficialNegocios', 'Oficial de Negocios'),
			field('sucursal', 'Sucursal'),
			field('analista', 'Analista'),
			field('fechaEvaluacion', 'Fecha de Evaluación', DATE),
			field('exposicionTotal', 'Exposición Total', MONEY),
			field('garantiaResumen', 'Garantía')
		]
	},
	{
		title: 'CONDICIONES FINANCIERAS DEL PRÉSTAMO',
		// Esta sección conserva sus campos de solo lectura.
		readOnly: true,
		fields: [
			field('montoSolicitado', 'Monto Solicitado', MONEY),
			field('plazoMeses', 'Plazo en Meses', INTEGER),
			field('tasaInteres', 'Tasa de Interés', PERCENT),
			field('tiempoTasaFija', 'Tasa Fija por Meses', INTEGER),
			field('cuotaEstimada', 'Cuota Estimada', MONEY)
		]
	},
	{
		title: 'PERFIL DEL CLIENTE / DEUDOR',
		fields: [
			field('edad', 'Edad', INTEGER),
			field('estadoCivil', 'Estado Civil'),
			field('dependientes', 'Dependientes', INTEGER),
			field('actividadEconomica', 'Actividad Económica', TEXT, { textarea: true, wide: true }),
			field('antiguedadLaboral', 'Antigüedad', TEXT, { wide: true })
		]
	},
	{
		title: 'INGRESOS Y CAPACIDAD DE PAGO',
		fields: [
			field('ingresosMensualesPromedio', 'Ingresos Mensuales Promedio', MONEY),
			field('evidenciaIngresos', 'Evidencia de Ingresos', TEXT, { textarea: true, wide: true }),
			field('cuotasFinancieras', 'Cuotas Financieras', MONEY),
			field('relacionCuotaIngresos', 'Relación Cuota / Ingresos', PERCENT),
			field('endeudamientoTotal', 'Endeudamiento Total', MONEY),
			field('solvenciaEstimada', 'Solvencia Estimada', MONEY)
		]
	},
	{
		title: 'HISTORIAL CREDITICIO',
		fields: [
			field('scoreCrediticio', 'Score Crediticio', INTEGER),
			field('clasificacionRiesgo', 'Clasificación de Riesgo', TEXT, { maxlength: 255 }),
			field('historialPago', 'Historial de Pago', TEXT, { textarea: true, wide: true, maxlength: 5000 })
		]
	},
	{
		title: 'EXCEPCIONES',
		fields: [field('excepciones', 'Excepciones', TEXT, { textarea: true, wide: true })]
	},
	{
		title: 'RECOMENDACIÓN DEL ÁREA DE CRÉDITO',
		fields: [field('recomendacion', 'Recomendación', TEXT, { textarea: true, wide: true, maxlength: 5000 })]
	},
	{
		title: 'FECHA DE APROBACIÓN',
		fields: [field('fechaAprobacion', 'Fecha de Aprobación', DATE), field('montoAprobado', 'Monto Aprobado', MONEY)]
	}
];

const VEHICLE_GUARANTEE = {
	title: 'GARANTÍA',
	fields: [
		field('garantiaTipo', 'Tipo'),
		field('garantiaMarca', 'Marca'),
		field('garantiaModelo', 'Modelo'),
		field('garantiaAno', 'Año', INTEGER),
		field('garantiaTasador', 'Tasador'),
		field('garantiaFechaTasacion', 'Fecha de Tasación', DATE),
		field('garantiaValorTasacion', 'Valor de Tasación', MONEY),
		field('prestamoSobreTasacion', 'Monto Préstamo sobre Tasación', PERCENT)
	]
};

const MORTGAGE_GUARANTEE = {
	title: 'GARANTÍA',
	fields: [
		field('garantiaTipo', 'Tipo'),
		field('garantiaUbicacion', 'Ubicación', TEXT, { wide: true }),
		field('garantiaSuperficie', 'Superficie', NUMBER),
		field('garantiaTasador', 'Tasador'),
		field('garantiaFechaTasacion', 'Fecha de Tasación', DATE),
		field('prestamoSobreTasacion', 'Monto Préstamo sobre Tasación', PERCENT),
		field('prestamoSobrePrecioVenta', 'Monto sobre Precio de Venta', PERCENT),
		field('garantiaValorTasacion', 'Valor de Tasación', MONEY),
		field('garantiaPrecioVenta', 'Precio de Venta', MONEY),
		field('garantiaPagoInicial', 'Pago Inicial', MONEY)
	]
};

const capacityMoneyFields = (rows) =>
	rows.flatMap(([key, label]) => [
		field(`montosPesos.${key}`, `${label} (RD$)`, MONEY_DOP, { calculated: CAPACITY_CALCULATED_ROW_KEYS.has(key) }),
		field(`montosDolares.${key}`, `${label} (USD)`, MONEY_USD, { calculated: CAPACITY_CALCULATED_ROW_KEYS.has(key) }),
		field(`totalesPesos.${key}`, `${label} (Total RD$)`, MONEY_DOP, { calculated: true })
	]);

const CAPACIDAD_SECTIONS = [
	{
		title: 'CLIENTE Y EJECUTIVO',
		fields: [field('solicitante', 'Nombre del Cliente'), field('oficialNegocios', 'Ejecutivo')]
	},
	{
		title: 'DATOS DE LA SOLICITUD',
		fields: [
			field('tipoPrestamo', 'Tipo de Préstamo'),
			field('tasaCambio', 'Tasa de Cambio', NUMBER),
			field('montoSolicitado', 'Monto', MONEY),
			field('tiempoTasaFija', 'Tiempo Tasa Fija', INTEGER),
			field('garantiaValorTasacion', 'Valor de Garantía', MONEY),
			field('plazoMeses', 'Plazo en Meses', INTEGER),
			field('prestamoSobreTasacion', 'Relación Préstamo vs. Garantía', PERCENT),
			field('tasaInteres', 'Tasa de Interés', PERCENT),
			field('cuotaEstimada', 'Cuota Mensual', MONEY),
			field('scorePredictivo', 'Score Predictivo', INTEGER),
			field('scoreInterno', 'Score Interno', INTEGER),
			field('perfilRiesgo', 'Perfil de Riesgo', TEXT, { maxlength: 100 })
		]
	},
	{
		title: 'MORAS REGISTRADAS',
		fields: [
			field('moraTc30', 'Mora Tarjetas de Crédito - 30 días', INTEGER),
			field('moraTc60', 'Mora Tarjetas de Crédito - 60 días', INTEGER),
			field('moraTc90', 'Mora Tarjetas de Crédito - 90 días', INTEGER),
			field('moraPrestamo30', 'Mora Préstamos de Consumo - 30 días', INTEGER),
			field('moraPrestamo60', 'Mora Préstamos de Consumo - 60 días', INTEGER),
			field('moraPrestamo90', 'Mora Préstamos de Consumo - 90 días', INTEGER)
		]
	},
	{
		title: 'INGRESOS MENSUALES',
		threeColumns: true,
		fields: capacityMoneyFields([
			['ingresoCartaTrabajo', 'Carta de trabajo o volantes de pago'],
			['ingresoDepositos', 'Promedio depósitos bancarios últimos 3 meses'],
			['ingresoAlquiler', 'Contratos de alquiler'],
			['ingresoInversiones', 'Intereses sobre inversiones'],
			['ingresoOtros', 'Otros ingresos mensuales evidenciados'],
			['ingresoEstadosFinancieros', 'Estados financieros'],
			['totalIngresos', 'Total de Ingresos Brutos']
		])
	},
	{
		title: 'FACILIDADES VIGENTES',
		threeColumns: true,
		fields: capacityMoneyFields([
			['deudaTarjetas', 'Monto Adeudado en Tarjetas de Crédito'],
			['deudaPrestamos', 'Monto Adeudado en Préstamos de Consumo'],
			['totalAdeudado', 'Total Adeudado']
		])
	},
	{
		title: 'CUOTAS MENSUALES',
		threeColumns: true,
		fields: capacityMoneyFields([
			['cuotaTarjetas', 'Pagos Mínimos de Tarjetas de Crédito'],
			['cuotaPrestamos', 'Pagos Mensuales de Préstamos de Consumo'],
			['cuotaNuevoPrestamo', 'Cuota de Nuevo Préstamo'],
			['cuotasCancelar', 'Cuotas de Préstamos a Cancelar'],
			['deudaTarjetasCancelar', 'Pago Mínimo de Tarjetas a Cancelar'],
			['totalPagosCreditos', 'Total Pagos Mínimos TC y Créditos'],
			['pagoVivienda', 'Pago Mensual de Alquiler o Préstamo Hipotecario'],
			['totalPagos', 'Total de Pagos']
		])
	},
	{
		title: 'INDICADORES DE CAPACIDAD',
		fields: [
			field('cargaFinanciera', 'Carga Financiera Mensual', PERCENT),
			field('resultadoCargaFinanciera', 'Resultado de Carga Financiera'),
			field('capacidadIncluyendoVivienda', 'Capacidad Incluyendo Vivienda', PERCENT),
			field('resultadoCapacidadVivienda', 'Resultado Incluyendo Vivienda'),
			field('totalActivos', 'Total de Activos', MONEY),
			field('indiceApalancamiento', 'Índice de Apalancamiento', PERCENT),
			field('resultadoApalancamiento', 'Resultado de Apalancamiento'),
			field('totalPasivos', 'Total de Pasivos', MONEY),
			field('capacidadEndeudamiento', 'Capacidad de Endeudamiento', PERCENT),
			field('resultadoEndeudamiento', 'Resultado de Endeudamiento'),
			field('patrimonio', 'Patrimonio', MONEY)
		]
	},
	{
		title: 'COMENTARIOS',
		fields: [field('comentarios', 'Comentarios', TEXT, { textarea: true, wide: true, maxlength: 2000 })]
	}
];

const tableField = (key, label) => field(key, label, TEXT, { textarea: true, maxlength: 20000 });
const PYME_SECTIONS = [
	{
		title: 'ENCABEZADO DEL INFORME',
		fields: [
			field('fechaInforme', 'Fecha del Informe', DATE),
			field('unidadSucursal', 'Unidad / Sucursal'),
			field('ejecutivo', 'Ejecutivo(a)'),
			field('tasaCambioUsd', 'Tasa de Cambio US$', NUMBER),
			field('tasaCambioEuro', 'Tasa de Cambio EURO', NUMBER),
			field('numeroSolicitud', 'Número de Solicitud')
		]
	},
	{
		title: 'DATOS GENERALES DEL CLIENTE',
		fields: [
			field('solicitante', 'Solicitante'),
			field('cedula', 'Cédula'),
			field('direccionResidencial', 'Dirección Residencial', TEXT, { textarea: true, wide: true }),
			field('codigoAbanks', 'Código Abanks'),
			field('direccionComercial', 'Dirección Comercial', TEXT, { textarea: true, wide: true }),
			field('sectorEconomico', 'Sector Económico', TEXT, { options: SECTOR_ECONOMICO_OPTIONS }),
			field('actividadComercial', 'Actividad Comercial', TEXT, { textarea: true, wide: true }),
			field('clasificacionRiesgoBv', 'Clasificación de Riesgo BV', TEXT, { options: CLASIFICACION_RIESGO_OPTIONS }),
			field('grupoRiesgo', 'Grupo de Riesgo'),
			field('tipoDeudor', 'Tipo Deudor', TEXT, { options: TIPO_DEUDOR_OPTIONS }),
			field('clasificacionRiesgoSib', 'Clasificación de Riesgo Actual SIB', TEXT, { options: CLASIFICACION_RIESGO_OPTIONS }),
			field('scoreBuro', 'Score Buró', INTEGER),
			field('deudaSistemaFinanciero', 'Monto Adeudado en el Sistema Financiero', MONEY),
			field('exposicionConsolidadaBv', 'Exposición Consolidada en BV', MONEY)
		]
	},
	{
		title: 'DATOS GENERALES DE LA SOLICITUD',
		fields: [
			field('tipoTramitacion', 'Tipo de Tramitación', TEXT, { options: TIPO_TRAMITACION_OPTIONS }),
			field('tipoGarantia', 'Tipo de Garantía', TEXT, { options: TIPO_GARANTIA_OPTIONS }),
			field('admisibilidad', 'Admisibilidad', PERCENT),
			field('tipoCredito', 'Tipo de Crédito', TEXT, { options: TIPO_CREDITO_OPTIONS }),
			field('valorGarantia', 'Valor Garantía', MONEY),
			field('cobertura', 'Cobertura', PERCENT),
			field('montoSolicitado', 'Monto RD$', MONEY),
			field('fechaTasacion', 'Fecha de Tasación', DATE),
			field('tipoBienGarantia', 'Tipo de Bien en Garantía', TEXT, { options: TIPO_BIEN_GARANTIA_OPTIONS }),
			field('plazoMeses', 'Plazo en Meses', INTEGER),
			field('tasaInteres', 'Tasa de Interés', PERCENT),
			field('cuotaEstimada', 'Cuota Estimada', MONEY),
			field('usoFondos', 'Uso de los Fondos', TEXT, { textarea: true, wide: true }),
			field('descripcionGarantia', 'Descripción de la Garantía', TEXT, { textarea: true, wide: true })
		]
	},
	{
		title: 'FACILIDADES ADICIONALES SOLICITADAS',
		threeColumns: true,
		fields: [
			tableField('facilidadesTipoCredito', 'Tipo de Crédito'),
			tableField('facilidadesMonto', 'Monto'),
			tableField('facilidadesPlazo', 'Plazo'),
			tableField('facilidadesTasa', 'Tasa'),
			tableField('facilidadesCuota', 'Cuota'),
			tableField('facilidadesUsoFondos', 'Uso de Fondos')
		]
	},
	{
		title: 'TAXONOMÍA VERDE',
		fields: [
			field('destinoTaxonomiaVerde', 'Destino del Crédito Taxonomía Verde', TEXT, { options: SI_NO_OPTIONS }),
			field('codigoActividadTaxonomia', 'Código Actividad Económica'),
			field('actividadTaxonomiaVerde', 'Actividad Económica Taxonomía Verde', TEXT, { textarea: true, wide: true })
		]
	},
	{
		title: 'DECISIÓN INSTANCIA DE APROBACIÓN Y/O COMITÉ DE CRÉDITO',
		fields: [
			field('decision', 'Decisión', TEXT, { options: DECISION_OPTIONS }),
			field('instanciaDecision', 'Instancia o Comité', TEXT, { options: INSTANCIA_OPTIONS }),
			field('fechaDecision', 'Fecha', DATE),
			field('realizadoPor', 'Realizado por', TEXT, { options: ANALISTA_OPTIONS }),
			field('revisadoPor', 'Revisado por', TEXT, { options: REVISOR_OPTIONS })
		]
	},
	{
		title: 'CERTIFICADOS DE DEPÓSITO DEL CLIENTE Y RELACIONADOS',
		threeColumns: true,
		fields: [
			tableField('certificadosTipoProducto', 'Tipo de Producto'),
			tableField('certificadosNumero', 'No.'),
			tableField('certificadosFechaApertura', 'Fecha Apertura'),
			tableField('certificadosMontoApertura', 'Monto Apertura'),
			tableField('certificadosBalanceActual', 'Balance Actual'),
			tableField('certificadosTasaPasiva', 'Tasa Pasiva'),
			tableField('certificadosPignorado', 'Pignorado'),
			field('certificadosTotalMontoApertura', 'Total Monto Apertura', MONEY),
			field('certificadosTotalBalance', 'Total Balance', MONEY)
		]
	},
	{
		title: 'CUENTAS BANCARIAS DEL CLIENTE Y RELACIONADOS',
		threeColumns: true,
		fields: [
			tableField('cuentasTipoProducto', 'Tipo de Producto'),
			tableField('cuentasNumero', 'No.'),
			tableField('cuentasFechaApertura', 'Fecha Apertura'),
			tableField('cuentasEntidad', 'Entidad'),
			tableField('cuentasMoneda', 'Moneda'),
			tableField('cuentasBalancePromedio', 'Balance Promedio'),
			tableField('cuentasDepositosPromedio', 'Prom. Depósitos Mensuales'),
			tableField('cuentasPeriodo', 'Período'),
			field('cuentasTotalBalancePromedio', 'Total Balance Promedio', MONEY),
			field('cuentasTotalDepositosPromedio', 'Total Depósitos Promedio', MONEY)
		]
	},
	{
		title: 'PRODUCTOS DE CRÉDITO DEL CLIENTE Y RELACIONADOS EN BV',
		threeColumns: true,
		fields: [
			tableField('productosBvTipoCredito', 'Tipo de Crédito'),
			tableField('productosBvBalanceActual', 'Balance Actual'),
			tableField('productosBvMontoAutorizado', 'Monto Autorizado'),
			tableField('productosBvScore', 'BV Score'),
			tableField('productosBvTipoGarantia', 'Tipo Garantía'),
			field('productosBvTotalBalance', 'Total Balance', MONEY),
			field('productosBvTotalAutorizado', 'Total Autorizado', MONEY)
		]
	},
	{
		title: 'CRÉDITOS VIGENTES CON OTROS BANCOS',
		threeColumns: true,
		fields: [
			tableField('creditosOtrosTipoCredito', 'Tipo de Crédito'),
			tableField('creditosOtrosBanco', 'Banco'),
			tableField('creditosOtrosTipoGarantia', 'Tipo Garantía'),
			tableField('creditosOtrosProposito', 'Propósito y Uso de Fondos'),
			tableField('creditosOtrosMoneda', 'RD$ / US$'),
			tableField('creditosOtrosComportamiento', 'Comportamiento Histórico'),
			tableField('creditosOtrosDeudaActual', 'Deuda Actual'),
			field('creditosOtrosTotalDeuda', 'Total Deuda', MONEY)
		]
	},
	{
		title: 'CAPACIDAD DE PAGO',
		threeColumns: true,
		fields: [
			tableField('compromisosTipo', 'Tipo de Compromiso'),
			tableField('compromisosBalances', 'Balances Adeudados'),
			tableField('compromisosCuotas', 'Cuotas Mensuales'),
			field('compromisosTotalBalance', 'Total Balance', MONEY),
			field('compromisosTotalCuotas', 'Total Cuotas', MONEY),
			field('disponibilidadBalancePromedio', 'Total Balance Promedio Cuenta(s)', MONEY),
			field('disponibilidadFlujoPromedio', 'Total Flujo Promedio Cuenta(s)', MONEY),
			field('disponibilidadPorcentajeBalance', '% Sobre Balance', PERCENT),
			field('disponibilidadPorcentajeFlujo', '% Sobre Flujo', PERCENT),
			field('resultadoCapacidad', 'Resultado Capacidad de Pago', TEXT, { options: CAPACIDAD_OPTIONS })
		]
	},
	{
		title: 'PERFIL Y ACTIVIDAD COMERCIAL',
		fields: [field('perfilActividadComercial', 'Perfil y Actividad Comercial', TEXT, { textarea: true, wide: true })]
	},
	{
		title: 'ANÁLISIS FINANCIERO',
		fields: [
			field('fechaEstadosFinancieros', 'Estados Financieros al', DATE),
			field('ingresosFinancieros', 'Ingresos', MONEY),
			field('utilidadNeta', 'Utilidad Neta', MONEY),
			field('activosTotales', 'Activos Totales', MONEY),
			field('pasivosTotales', 'Pasivos Totales', MONEY),
			field('patrimonio', 'Patrimonio', MONEY),
			field('apalancamiento', 'Apalancamiento', PERCENT),
			field('activosFijos', 'Activos Fijos', MONEY),
			field('deudasBancarias', 'Deudas Bancarias', MONEY),
			field('inventario', 'Inventario', MONEY),
			field('cuentasPorCobrar', 'Cuentas por Cobrar', MONEY),
			field('cajaBancos', 'Caja y Bancos', MONEY),
			field('analisisFinanciero', 'Análisis Financiero', TEXT, { textarea: true, wide: true })
		]
	},
	{
		title: 'COMPORTAMIENTO HISTÓRICO DE PAGOS Y CLASIFICACIÓN DE RIESGO',
		fields: [
			field('comportamientoHistorico', 'Comportamiento Histórico de Pagos', TEXT, { textarea: true, wide: true }),
			field('resumenClasificacionSib', 'Clasificación SIB', TEXT, { textarea: true, wide: true }),
			field('mitigantes', 'Mitigantes', TEXT, { textarea: true, wide: true })
		]
	},
	{
		title: 'CONCLUSIONES Y RECOMENDACIONES',
		fields: [field('conclusionesRecomendaciones', 'Conclusiones y Recomendaciones', TEXT, { textarea: true, wide: true })]
	}
];

export default class FscEditarDocumentoAnalisis extends LightningElement {
	@api recordId;
	@api tipoDocumento;
	@track sections = [];
	@track loading = true;
	@track saving = false;
	@track errorMessage = '';
	esPyme = false;
	baseline = new Map();

	connectedCallback() {
		this.loadData();
	}

	get modalTitle() {
		return this.tipoDocumento === INFORME ? 'Editar informe de crédito' : 'Editar capacidad de pago';
	}

	get showSpinner() {
		return this.loading || this.saving;
	}

	get disableActions() {
		return this.showSpinner;
	}

	async loadData() {
		this.loading = true;
		this.errorMessage = '';
		try {
			const data = await getDatosDocumentoAnalisis({
				residentialLoanApplicationId: this.recordId,
				tipoDocumento: this.tipoDocumento
			});
			this.esPyme = data?.esPyme === true;
			const configs = this.esPyme
				? PYME_SECTIONS
				: this.tipoDocumento === INFORME
					? this.buildInformeSections(data)
					: CAPACIDAD_SECTIONS;
			this.sections = configs.map((section, sectionIndex) => ({
				...section,
				id: `section-${sectionIndex}`,
				gridClass: section.threeColumns ? 'fieldsGrid fieldsGrid_threeColumns' : 'fieldsGrid',
				fields: section.fields.map((config) =>
					this.prepareField({ ...config, readOnly: config.readOnly ?? section.readOnly }, data)
				)
			}));
			if (!this.esPyme && this.tipoDocumento === CAPACIDAD) {
				// Muestra las fórmulas al día aunque la versión guardada del PDF las tenga incompletas.
				this.recalculateCapacityFields();
			}
		} catch (error) {
			this.errorMessage = this.getErrorMessage(error, 'No fue posible cargar la información del documento.');
		} finally {
			this.loading = false;
			this.refreshFieldDisabledState();
		}
	}

	buildInformeSections(data) {
		const sections = INFORME_BASE.map((section) => ({ ...section, fields: [...section.fields] }));
		const profile = sections.find((section) => section.title === 'PERFIL DEL CLIENTE / DEUDOR');
		if (data?.esHipotecario) {
			const general = sections.find((section) => section.title === 'DATOS GENERALES DEL CLIENTE');
			general.fields = general.fields.filter((item) => item.key !== 'garantiaResumen');
			profile.fields.splice(3, 0, field('residencial', 'Residencial', TEXT, { wide: true }), field('nacionalidad', 'Nacionalidad'));
			sections.splice(4, 0, MORTGAGE_GUARANTEE);
		} else if (data?.esVehiculo) {
			sections.splice(4, 0, VEHICLE_GUARANTEE);
		}
		return sections;
	}

	prepareField(config, data) {
		const rawValue = this.getByPath(data, config.key);
		const value = this.toInputValue(rawValue, config.format);
		const picklistOptions = config.options ? [...config.options] : [];
		if (config.options && value && !picklistOptions.some((item) => item.value === value)) {
			picklistOptions.push({ label: value, value });
		}
		this.baseline.set(config.key, this.compareValue(value));
		return {
			...config,
			id: config.key.replaceAll('.', '-'),
			value,
			inputType: config.format === DATE ? 'date' : this.isNumericFormat(config.format) ? 'number' : 'text',
			step: config.format === INTEGER ? '1' : this.isNumericFormat(config.format) ? 'any' : undefined,
			min: config.min ?? ([INTEGER, PERCENT].includes(config.format) ? '0' : undefined),
			max:
				config.max ??
				(config.key === 'plazoMeses' || config.key === 'tiempoTasaFija' ? '99' : config.key === 'edad' ? '150' : undefined),
			fieldClass: config.wide ? 'field field_wide' : 'field',
			picklist: !!config.options,
			options: picklistOptions,
			readOnly:
				config.readOnly === true ||
				config.calculated === true ||
				(this.esPyme
					? PYME_FORMULA_FIELD_KEYS
					: this.tipoDocumento === INFORME
						? INFORME_FORMULA_FIELD_KEYS
						: CAPACITY_FORMULA_FIELD_KEYS
				).has(config.key),
			disabled: this.disableActions,
			maxlength: config.maxlength ?? (config.textarea || config.format === TEXT ? 20000 : undefined)
		};
	}

	handleChange(event) {
		const key = event.target.dataset.key;
		const changedField = this.sections.flatMap((section) => section.fields).find((item) => item.key === key);
		if (!changedField || changedField.readOnly || changedField.disabled) {
			return;
		}
		const value = event.detail?.value ?? event.target.value;
		this.sections = this.sections.map((section) => ({
			...section,
			fields: section.fields.map((item) => (item.key === key ? { ...item, value } : item))
		}));
		if (this.tipoDocumento === CAPACIDAD && this.affectsCapacityCalculations(key)) {
			this.recalculateCapacityFields();
		}
		if (this.esPyme && this.affectsPymeCalculations(key)) {
			this.recalculatePymeFields();
		}
	}

	refreshFieldDisabledState() {
		this.sections = this.sections.map((section) => ({
			...section,
			fields: section.fields.map((item) => ({
				...item,
				disabled: this.disableActions
			}))
		}));
	}

	affectsCapacityCalculations(key) {
		return ['tasaCambio', 'totalActivos', 'totalPasivos'].includes(key) || key.startsWith('montosPesos.') || key.startsWith('montosDolares.');
	}

	recalculateCapacityFields() {
		const assets = this.numericFieldValue('totalActivos');
		const liabilities = this.numericFieldValue('totalPasivos');
		const calculatedValues = {
			patrimonio: assets === null || liabilities === null ? '' : this.roundMoney(assets - liabilities)
		};
		['montosPesos', 'montosDolares'].forEach((currencyPath) => {
			const cardDebt = this.numericFieldValue(`${currencyPath}.deudaTarjetas`);
			calculatedValues[`${currencyPath}.cuotaTarjetas`] =
				cardDebt === null ? '' : this.roundMoney(cardDebt * CARD_MINIMUM_PAYMENT_RATE);
			calculatedValues[`${currencyPath}.totalIngresos`] = this.sumCapacityValues(
				currencyPath,
				CAPACITY_INCOME_DETAIL_KEYS
			);
			calculatedValues[`${currencyPath}.totalAdeudado`] = this.sumCapacityValues(
				currencyPath,
				CAPACITY_DEBT_DETAIL_KEYS
			);
			calculatedValues[`${currencyPath}.totalPagosCreditos`] = this.sumCapacityValues(
				currencyPath,
				CAPACITY_PAYMENT_DETAIL_KEYS,
				CAPACITY_PAYMENT_CANCEL_KEYS,
				true,
				calculatedValues
			);
			calculatedValues[`${currencyPath}.totalPagos`] = this.sumCapacityValues(
				currencyPath,
				['totalPagosCreditos', 'pagoVivienda'],
				[],
				true,
				calculatedValues
			);
		});

		const exchangeRate = this.numericFieldValue('tasaCambio');
		CAPACITY_ALL_KEYS.forEach((concept) => {
			const dop = this.numericFieldValue(`montosPesos.${concept}`, calculatedValues);
			const usd = this.numericFieldValue(`montosDolares.${concept}`, calculatedValues);
			let total = '';
			if (dop !== null || usd !== null) {
				total = usd !== null && exchangeRate === null ? '' : this.roundMoney((dop ?? 0) + (usd ?? 0) * (exchangeRate ?? 0));
			}
			calculatedValues[`totalesPesos.${concept}`] = total;
		});

		// Los indicadores deben reflejar los importes que se están editando.
		const income = this.numericFieldValue('totalesPesos.totalIngresos', calculatedValues);
		const creditPayments = this.numericFieldValue('totalesPesos.totalPagosCreditos', calculatedValues);
		const totalPayments = this.numericFieldValue('totalesPesos.totalPagos', calculatedValues);
		calculatedValues.cargaFinanciera = this.calculatePercentage(creditPayments, income);
		calculatedValues.resultadoCargaFinanciera =
			calculatedValues.cargaFinanciera === ''
				? ''
				: creditPayments / income <= 0.35 ? 'CAPACIDAD DE PAGO OK' : 'NO DEBE EXCEDER DEL 35%';
		calculatedValues.capacidadIncluyendoVivienda = this.calculatePercentage(totalPayments, income);
		calculatedValues.resultadoCapacidadVivienda =
			calculatedValues.capacidadIncluyendoVivienda === ''
				? ''
				: totalPayments / income <= 0.4 ? 'CAPACIDAD DE PAGO OK' : 'CAPACIDAD DE PAGO ESTRECHA';

		this.sections = this.sections.map((section) => ({
			...section,
			fields: section.fields.map((item) =>
				(Object.prototype.hasOwnProperty.call(calculatedValues, item.key)
					? { ...item, value: calculatedValues[item.key] }
					: item)
			)
		}));
	}

	affectsPymeCalculations(key) {
		return [
			'montoSolicitado',
			'valorGarantia',
			'certificadosMontoApertura',
			'certificadosBalanceActual',
			'cuentasBalancePromedio',
			'cuentasDepositosPromedio',
			'productosBvBalanceActual',
			'productosBvMontoAutorizado',
			'creditosOtrosDeudaActual',
			'compromisosBalances',
			'compromisosCuotas',
			'disponibilidadBalancePromedio',
			'disponibilidadFlujoPromedio'
		].includes(key);
	}

	recalculatePymeFields() {
		const calculatedValues = {};
		const totalsByColumn = {
			certificadosMontoApertura: 'certificadosTotalMontoApertura',
			certificadosBalanceActual: 'certificadosTotalBalance',
			cuentasBalancePromedio: 'cuentasTotalBalancePromedio',
			cuentasDepositosPromedio: 'cuentasTotalDepositosPromedio',
			productosBvBalanceActual: 'productosBvTotalBalance',
			productosBvMontoAutorizado: 'productosBvTotalAutorizado',
			creditosOtrosDeudaActual: 'creditosOtrosTotalDeuda',
			compromisosBalances: 'compromisosTotalBalance',
			compromisosCuotas: 'compromisosTotalCuotas'
		};
		Object.entries(totalsByColumn).forEach(([source, target]) => {
			const total = this.sumMultilineMoney(this.findFieldValue(source));
			calculatedValues[target] = total === null ? '' : this.roundMoney(total);
		});

		const monto = this.numericFieldValue('montoSolicitado');
		const garantia = this.numericFieldValue('valorGarantia');
		calculatedValues.cobertura = this.calculatePercentage(garantia, monto);
		const cuotas = this.numericValue(calculatedValues.compromisosTotalCuotas);
		calculatedValues.disponibilidadPorcentajeBalance = this.calculatePercentage(
			cuotas,
			this.numericFieldValue('disponibilidadBalancePromedio')
		);
		calculatedValues.disponibilidadPorcentajeFlujo = this.calculatePercentage(
			cuotas,
			this.numericFieldValue('disponibilidadFlujoPromedio')
		);

		this.sections = this.sections.map((section) => ({
			...section,
			fields: section.fields.map((item) =>
				(Object.prototype.hasOwnProperty.call(calculatedValues, item.key)
					? { ...item, value: calculatedValues[item.key] }
					: item)
			)
		}));
	}

	sumMultilineMoney(value) {
		if (value === null || value === undefined || String(value).trim() === '') {
			return null;
		}
		let total = 0;
		let hasValue = false;
		String(value)
			.split(/\r?\n/)
			.forEach((line) => {
				const parsed = this.numericValue(this.parseDisplayNumber(line, MONEY));
				if (parsed !== null) {
					hasValue = true;
					total += parsed;
				}
			});
		return hasValue ? total : null;
	}

	calculatePercentage(numerator, denominator) {
		if (numerator === null || denominator === null || denominator === 0) {
			return '';
		}
		return String(Math.round(((numerator / denominator) * 100 + Number.EPSILON) * 100) / 100);
	}

	numericValue(value) {
		if (value === null || value === undefined || value === '') {
			return null;
		}
		const parsed = Number(value);
		return Number.isFinite(parsed) ? parsed : null;
	}

	sumCapacityValues(currencyPath, positiveKeys, negativeKeys = [], clampAtZero = false, pendingValues = {}) {
		let hasValue = false;
		let total = 0;
		positiveKeys.forEach((key) => {
			const value = this.numericFieldValue(`${currencyPath}.${key}`, pendingValues);
			if (value !== null) {
				hasValue = true;
				total += value;
			}
		});
		negativeKeys.forEach((key) => {
			const value = this.numericFieldValue(`${currencyPath}.${key}`, pendingValues);
			if (value !== null) {
				hasValue = true;
				total -= value;
			}
		});
		if (!hasValue) {
			return '';
		}
		return this.roundMoney(clampAtZero ? Math.max(0, total) : total);
	}

	numericFieldValue(key, pendingValues = {}) {
		const pendingValue = pendingValues[key];
		const fieldValue = Object.prototype.hasOwnProperty.call(pendingValues, key) ? pendingValue : this.findFieldValue(key);
		if (fieldValue === null || fieldValue === undefined || fieldValue === '') {
			return null;
		}
		const parsed = Number(fieldValue);
		return Number.isFinite(parsed) ? parsed : null;
	}

	findFieldValue(key) {
		for (const section of this.sections) {
			const found = section.fields.find((item) => item.key === key);
			if (found) {
				return found.value;
			}
		}
		return null;
	}

	roundMoney(value) {
		return String(Math.round((value + Number.EPSILON) * 100) / 100);
	}

	handleCancel() {
		if (!this.saving) {
			this.dispatchEvent(new CustomEvent('cancel'));
		}
	}

	async handleSave() {
		const inputs = [...this.template.querySelectorAll('lightning-input, lightning-textarea, lightning-combobox')];
		if (!inputs.reduce((valid, input) => input.reportValidity() && valid, true)) {
			return;
		}

		const changes = {};
		this.sections.forEach((section) => {
			section.fields.forEach((item) => {
				if (!item.readOnly && this.compareValue(item.value) !== this.baseline.get(item.key)) {
					changes[item.key] = { value: item.value ?? '', format: item.format };
				}
			});
		});
		if (!Object.keys(changes).length) {
			this.dispatchEvent(
				new ShowToastEvent({ title: 'Sin cambios', message: 'Modifique al menos un campo antes de guardar.', variant: 'info' })
			);
			return;
		}

		this.saving = true;
		this.refreshFieldDisabledState();
		this.errorMessage = '';
		try {
			await guardarYRegenerarDocumentoAnalisis({
				residentialLoanApplicationId: this.recordId,
				tipoDocumento: this.tipoDocumento,
				cambiosJson: JSON.stringify(changes)
			});
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Cambios guardados',
					message: 'El PDF se está regenerando con la información actualizada.',
					variant: 'success'
				})
			);
			this.dispatchEvent(new CustomEvent('saved'));
		} catch (error) {
			this.errorMessage = this.getErrorMessage(error, 'No fue posible guardar y regenerar el documento.');
		} finally {
			this.saving = false;
			this.refreshFieldDisabledState();
		}
	}

	getByPath(source, path) {
		return path.split('.').reduce((current, part) => current?.[part], source);
	}

	isNumericFormat(format) {
		return [INTEGER, NUMBER, MONEY, MONEY_DOP, MONEY_USD, PERCENT].includes(format);
	}

	toInputValue(value, format) {
		if (value === null || value === undefined || value === '') {
			return '';
		}
		if (format === DATE) {
			const match = String(value).match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
			return match ? `${match[3]}-${match[2].padStart(2, '0')}-${match[1].padStart(2, '0')}` : value;
		}
		if (!this.isNumericFormat(format)) {
			return String(value);
		}
		return this.parseDisplayNumber(value, format);
	}

	parseDisplayNumber(value, format) {
		let normalized = String(value)
			.replace(/RD\$|US\$|EUR|%/gi, '')
			.replace(/\s/g, '')
			.replace(/[^0-9.,-]/g, '');
		const lastComma = normalized.lastIndexOf(',');
		const lastDot = normalized.lastIndexOf('.');
		const usesGroupedWholeNumber = [INTEGER, MONEY, MONEY_DOP, MONEY_USD].includes(format);
		if (lastComma >= 0 && lastDot >= 0) {
			const decimalSeparator = lastComma > lastDot ? ',' : '.';
			normalized = normalized
				.replace(decimalSeparator === ',' ? /\./g : /,/g, '')
				.replace(decimalSeparator, '.');
		} else if (lastComma >= 0) {
			normalized = this.normalizeSingleSeparator(normalized, ',', usesGroupedWholeNumber);
		} else if (lastDot >= 0 && normalized.split('.').length > 2) {
			normalized = this.normalizeSingleSeparator(normalized, '.', usesGroupedWholeNumber);
		} else if (lastDot >= 0) {
			normalized = this.normalizeSingleSeparator(normalized, '.', usesGroupedWholeNumber);
		}
		const parsed = Number(normalized);
		return Number.isFinite(parsed) ? String(parsed) : '';
	}

	normalizeSingleSeparator(value, separator, usesGroupedWholeNumber) {
		const parts = value.split(separator);
		const isThousandsGrouping =
			usesGroupedWholeNumber && parts.length > 1 && parts.slice(1).every((part) => part.length === 3);
		if (isThousandsGrouping) {
			return parts.join('');
		}
		const decimalPart = parts.pop();
		return `${parts.join('')}.${decimalPart}`;
	}

	compareValue(value) {
		return value === null || value === undefined ? '' : String(value);
	}

	getErrorMessage(error, fallback) {
		return error?.body?.message || error?.message || fallback;
	}
}
