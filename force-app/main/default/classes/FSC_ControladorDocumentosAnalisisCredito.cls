/**
 * Prepara la información presentada en los PDF de capacidad de pago e informe de crédito.
 */
// El parámetro URL se restringe a un Id Salesforce de 15/18 caracteres antes de usarse;
// Visualforce escapa por defecto todos los valores mostrados en las plantillas.
@SuppressWarnings('PMD.ApexXSSFromURLParam')
public with sharing class FSC_ControladorDocumentosAnalisisCredito {
	private static final Decimal PORCENTAJE_PAGO_MINIMO_TARJETA = 0.08;
	private static final Decimal LIMITE_CARGA_FINANCIERA = 0.35;
	private static final Decimal LIMITE_CAPACIDAD_VIVIENDA = 0.40;
	private static final Decimal LIMITE_APALANCAMIENTO = 0.70;
	private static final Decimal LIMITE_ENDEUDAMIENTO = 0.40;
	private static final Decimal MONTO_MINIMO_ACTIVOS_PASIVOS = 500000;
	private static final String TIPO_CONSUMO = 'FSC_Solicitud_Credito_Consumo';
	private static final String TIPO_VEHICULO = 'FSC_Solicitud_Credito_Vehiculo';
	private static final String TIPO_HIPOTECARIO = 'FSC_Solicitud_Credito_Hipotecario';
	private Decimal tasaCambioActual;
	private String simboloMonedaSolicitud = 'RD$';

	public FSC_DatosDocumentosAnalisisCredito datos { get; private set; }

	/** Carga la solicitud indicada en el parámetro id de la página Visualforce. */
	public FSC_ControladorDocumentosAnalisisCredito() {
		this(true);
		PageReference paginaActual = ApexPages.currentPage();
		if (paginaActual == null) {
			return;
		}

		String solicitudId = paginaActual.getParameters().get('id');
		if (String.isBlank(solicitudId) || !Pattern.matches('[a-zA-Z0-9]{15,18}', solicitudId)) {
			return;
		}

		Id solicitudValidaId = (Id) solicitudId.escapeHtml4();
		cargarDatos(solicitudValidaId);
		String tipoDocumento = paginaActual.getParameters().get('tipoDocumento');
		if (String.isBlank(tipoDocumento)) {
			tipoDocumento = paginaActual.getUrl().toLowerCase().contains('capacidadpago')
				? FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_CAPACIDAD
				: FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME;
		}
		aplicarEdicionesGuardadas(solicitudValidaId, tipoDocumento);
		if (tipoDocumento == FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_CAPACIDAD) {
			recalcularPatrimonioCapacidad();
		}
	}

	private FSC_ControladorDocumentosAnalisisCredito(Boolean inicializarSolo) {
		datos = new FSC_DatosDocumentosAnalisisCredito();
	}

	/** Devuelve exactamente el mismo modelo final que consumen las páginas Visualforce. */
	public static Map<String, Object> construirDatos(Id solicitudId, String tipoDocumento) {
		FSC_ControladorDocumentosAnalisisCredito controlador = new FSC_ControladorDocumentosAnalisisCredito(true);
		controlador.cargarDatos(solicitudId);
		controlador.aplicarEdicionesGuardadas(solicitudId, tipoDocumento);
		if (tipoDocumento == FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_CAPACIDAD) {
			controlador.recalcularPatrimonioCapacidad();
		}
		return (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(controlador.datos));
	}

	private void aplicarEdicionesGuardadas(Id solicitudId, String tipoDocumento) {
		if (solicitudId == null || datos == null) {
			return;
		}

		String ajustesJson = obtenerAjustesVersionActual(solicitudId, tipoDocumento);
		if (String.isBlank(ajustesJson)) {
			return;
		}

		try {
			Map<String, Object> base = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(datos));
			Map<String, Object> ajustes = (Map<String, Object>) JSON.deserializeUntyped(ajustesJson);
			fusionarMapas(base, ajustes);
			datos = (FSC_DatosDocumentosAnalisisCredito) JSON.deserialize(JSON.serialize(base), FSC_DatosDocumentosAnalisisCredito.class);
			if (tipoDocumento == FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_CAPACIDAD) {
				recalcularIndicadoresCapacidad();
			}
		} catch (Exception error) {
			// Un ajuste histórico inválido nunca debe impedir la generación del PDF base.
			System.debug(LoggingLevel.WARN, 'No se pudieron aplicar los ajustes del documento: ' + error.getMessage());
		}
	}

	private void recalcularPatrimonioCapacidad() {
		// Usa los valores visibles finales, incluidos los ajustes del documento.
		Decimal activos = leerMontoDocumento(datos.totalActivos);
		Decimal pasivos = leerMontoDocumento(datos.totalPasivos);
		datos.patrimonio = formatearDineroSolicitud(activos == null || pasivos == null ? null : activos - pasivos);
	}

	private void recalcularIndicadoresCapacidad() {
		// Los porcentajes usan los totales finales, incluidos los ajustes del documento.
		Decimal ingresos = leerMontoDocumento(datos.totalesPesos.get('totalIngresos'));
		Decimal pagosCredito = leerMontoDocumento(datos.totalesPesos.get('totalPagosCreditos'));
		Decimal totalPagos = leerMontoDocumento(datos.totalesPesos.get('totalPagos'));
		datos.cargaFinanciera = formatearRelacion(pagosCredito, ingresos);
		datos.resultadoCargaFinanciera = evaluarRelacion(
			pagosCredito, ingresos, LIMITE_CARGA_FINANCIERA, 'CAPACIDAD DE PAGO OK', 'NO DEBE EXCEDER DEL 35%'
		);
		datos.capacidadIncluyendoVivienda = formatearRelacion(totalPagos, ingresos);
		datos.resultadoCapacidadVivienda = evaluarRelacion(
			totalPagos, ingresos, LIMITE_CAPACIDAD_VIVIENDA, 'CAPACIDAD DE PAGO OK', 'CAPACIDAD DE PAGO ESTRECHA'
		);
	}

	private static Decimal leerMontoDocumento(String valor) {
		if (String.isBlank(valor)) {
			return null;
		}
		String numero = valor.replaceAll('[^0-9,\\.\\-]', '');
		// Los PDF pueden guardar importes con formato dominicano o español.
		Integer coma = numero.lastIndexOf(',');
		Integer punto = numero.lastIndexOf('.');
		if (coma >= 0 && punto >= 0 && coma > punto) {
			numero = numero.replace('.', '').replace(',', '.');
		} else if (coma >= 0 && punto < 0) {
			numero = numero.length() - coma - 1 == 3 ? numero.replace(',', '') : numero.replace(',', '.');
		} else if (punto >= 0 && coma < 0 && numero.length() - punto - 1 == 3) {
			numero = numero.replace('.', '');
		} else {
			numero = numero.replace(',', '');
		}
		return Decimal.valueOf(numero);
	}

	private static String obtenerAjustesVersionActual(Id solicitudId, String tipoDocumento) {
		String tipoNormalizado = String.isBlank(tipoDocumento) ? '' : tipoDocumento.trim().toUpperCase();
		String prefijoTitulo = tipoNormalizado == FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_CAPACIDAD
			? 'Capacidad de Pago'
			: 'Informe de Crédito';
		Id contentDocumentId;
		for (ContentDocumentLink enlace : [
			SELECT ContentDocumentId, ContentDocument.Title
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :solicitudId
			ORDER BY SystemModstamp DESC
		]) {
			if (enlace.ContentDocument.Title != null && enlace.ContentDocument.Title.startsWith(prefijoTitulo)) {
				contentDocumentId = enlace.ContentDocumentId;
				break;
			}
		}
		if (contentDocumentId == null) {
			return '';
		}

		List<ContentVersion> versiones = [
			SELECT FSC_DatosEditadosAnalisis__c
			FROM ContentVersion
			WHERE ContentDocumentId = :contentDocumentId AND IsLatest = TRUE
			LIMIT 1
		];
		return versiones.isEmpty() ? '' : versiones[0].FSC_DatosEditadosAnalisis__c;
	}

	private static void fusionarMapas(Map<String, Object> destino, Map<String, Object> cambios) {
		if (destino == null || cambios == null) {
			return;
		}
		for (String clave : cambios.keySet()) {
			Object valorNuevo = cambios.get(clave);
			Object valorActual = destino.get(clave);
			if (valorNuevo instanceof Map<String, Object> && valorActual instanceof Map<String, Object>) {
				fusionarMapas((Map<String, Object>) valorActual, (Map<String, Object>) valorNuevo);
			} else if (destino.containsKey(clave)) {
				destino.put(clave, valorNuevo);
			}
		}
	}

	private void cargarDatos(Id solicitudId) {
		ResidentialLoanApplication solicitud = FSC_ConsultaDocumentosAnalisisCredito.seleccionarSolicitud(solicitudId);
		if (solicitud == null) {
			return;
		}

		Account cuenta = FSC_ConsultaDocumentosAnalisisCredito.seleccionarCuenta(solicitud.AccountId);
		List<LoanApplicant> participantes = FSC_ConsultaDocumentosAnalisisCredito.seleccionarParticipantes(solicitudId);
		LoanApplicant deudor = encontrarDeudor(participantes);
		Set<Id> participantesEconomicosIds = obtenerParticipantesEconomicosIds(participantes, deudor);
		LoanApplicantEmployment empleo = FSC_ConsultaDocumentosAnalisisCredito.seleccionarEmpleo(deudor?.Id);
		List<LoanApplicantIncome> ingresos = FSC_ConsultaDocumentosAnalisisCredito.seleccionarIngresos(solicitudId);
		List<LoanApplicationLiability> deudas = FSC_ConsultaDocumentosAnalisisCredito.seleccionarDeudas(solicitudId);
		List<FSC_Facilidad_Otra_Institucion__c> facilidadesExternas = FSC_ConsultaDocumentosAnalisisCredito.seleccionarFacilidadesExternas(
			participantesEconomicosIds
		);
		List<FSC_Facilidades_De_Credito__c> facilidadesCredito = FSC_ConsultaDocumentosAnalisisCredito.seleccionarFacilidadesCredito(solicitudId);
		List<LoanApplicationAsset> activos = FSC_ConsultaDocumentosAnalisisCredito.seleccionarActivos(solicitudId);
		List<FSC_Garantia__c> garantias = FSC_ConsultaDocumentosAnalisisCredito.seleccionarGarantias(solicitudId);
		List<FSC_Excepcion__c> excepciones = FSC_ConsultaDocumentosAnalisisCredito.seleccionarExcepciones(solicitudId);
		List<String> evidenciasIngresos = FSC_ConsultaDocumentosAnalisisCredito.seleccionarEvidenciasIngresos(solicitudId);

		String tipoRegistro = solicitud.RecordType?.DeveloperName;
		Decimal montoSolicitado = solicitud.FSC_Monto__c;
		Decimal cuotaNueva = solicitud.FSC_Monto_De_La_Cuota__c;
		configurarMoneda(solicitud.FSC_Moneda__c);
		configurarDatosGenerales(
			solicitud,
			cuenta,
			deudor,
			empleo,
			tipoRegistro,
			!garantias.isEmpty(),
			montoSolicitado,
			cuotaNueva,
			facilidadesCredito
		);

		ResumenIngresos resumenIngresos = resumirIngresos(ingresos, participantes, participantesEconomicosIds, deudor, empleo, solicitud);
		ResumenDeudas resumenDeudas = resumirDeudas(deudas, facilidadesExternas);
		Decimal totalActivos = resumirActivos(activos, cuenta, solicitud);
		Decimal totalPasivos = primerDecimal(
			new List<Decimal>{ resumenDeudas.totalBalance, cuenta?.VFS_TotalPasivo__c, solicitud.FSC_Total_Pasivos__c }
		);
		// FSC_Cuotas__c recibe el plazo en meses del formulario de consumo, no un importe mensual.
		Decimal pagosCreditoInforme = calcularPagosCreditos(resumenDeudas.totalCuotas, cuotaNueva, resumenDeudas.totalCuotasCancelar);
		aplicarFacilidadesBuro(resumenDeudas, solicitud, datos.esMonedaDolar);
		Decimal pagosCredito = calcularPagosCreditos(resumenDeudas.totalCuotas, cuotaNueva, resumenDeudas.totalCuotasCancelar);
		Decimal pagoVivienda = solicitud.FSC_Alquiler_Personales__c;
		Decimal totalPagos = sumarValores(new List<Decimal>{ pagosCredito, pagoVivienda });
		Decimal patrimonio = restar(totalActivos, totalPasivos);

		configurarAnalisisFinanciero(
			solicitud,
			cuenta,
			deudor,
			resumenIngresos,
			montoSolicitado,
			pagosCreditoInforme,
			totalPasivos,
			patrimonio,
			excepciones,
			evidenciasIngresos,
			facilidadesCredito
		);
		cargarGarantia(solicitud, garantias, participantes, facilidadesCredito, montoSolicitado);
		cargarCapacidadPago(
			resumenIngresos,
			resumenDeudas,
			cuotaNueva,
			pagosCredito,
			pagoVivienda,
			totalPagos,
			totalActivos,
			totalPasivos,
			patrimonio,
			solicitud
		);
	}

	private void configurarDatosGenerales(
		ResidentialLoanApplication solicitud,
		Account cuenta,
		LoanApplicant deudor,
		LoanApplicantEmployment empleo,
		String tipoRegistro,
		Boolean tieneGarantia,
		Decimal montoSolicitado,
		Decimal cuotaNueva,
		List<FSC_Facilidades_De_Credito__c> facilidadesCredito
	) {
		datos.numeroSolicitud = texto(solicitud.Name);
		datos.tipoPrestamo = resolverTipoPrestamo(tipoRegistro);
		datos.esVehiculo = tipoRegistro == TIPO_VEHICULO || (tipoRegistro == TIPO_CONSUMO && tieneGarantia);
		datos.esHipotecario = tipoRegistro == TIPO_HIPOTECARIO;
		datos.solicitante = primerTexto(new List<String>{ nombreParticipante(deudor), cuenta?.Name });
		datos.cedula = primerTexto(new List<String>{ deudor?.FSC_NumIdentificacion__c, cuenta?.ACC_NumIdentificacion__c });
		datos.destino = primerTexto(new List<String>{ solicitud.FSC_Destino_del_Prestamo__c, solicitud.FSC_DescripcionPropositoFacilidad__c });
		datos.oficialNegocios = primerTexto(new List<String>{ solicitud.FSC_CreatedBy_Name__c, solicitud.CreatedBy?.Name });
		datos.sucursal = resolverEtiquetaSucursal(solicitud.CreatedBy?.FSC_Sucursal__c);
		datos.analista = texto(solicitud.FSC_UsuarioAnalista__r?.Name);
		datos.fechaEvaluacion = formatearFecha(Date.today());
		datos.montoSolicitado = formatearDineroSolicitud(montoSolicitado);
		datos.plazoMeses = primerTexto(new List<String>{ texto(solicitud.FSC_PlazoMeses__c), solicitud.FSC_Plazo_meses__c });
		datos.tasaInteres = formatearPorcentaje(solicitud.FSC_TasaInteres__c);
		Decimal tiempoTasaFija = primerDecimal(
			new List<Decimal>{
				facilidadesCredito.isEmpty() ? null : facilidadesCredito[0].FSC_Tiempo_Tasa_Fija__c,
				solicitud.FSC_TasaFijaPorMeses__c,
				0
			}
		);
		datos.tiempoTasaFija = formatearEntero(tiempoTasaFija);
		datos.cuotaEstimada = formatearDineroSolicitud(cuotaNueva);

		Date fechaNacimiento = deudor?.FSC_FechaNacimiento__c ?? cuenta?.PersonBirthdate;
		datos.edad = calcularEdad(fechaNacimiento);
		datos.estadoCivil = primerTexto(new List<String>{ deudor?.FSC_EstadoCivil__c, cuenta?.ACC_Estado_Civil__c });
		datos.dependientes = primerTexto(new List<String>{ texto(deudor?.FSC_NumeroDependientes__c), texto(cuenta?.ACC_N_Dependientes__c) });
		datos.nacionalidad = primerTexto(new List<String>{ deudor?.FSC_Nacionalidad__c, cuenta?.ACC_Nacionalidad__c });
		datos.residencial = construirDireccion(cuenta);
		String actividadEconomica = primerTexto(
			new List<String>{ deudor?.FSC_Ocupacion__c, solicitud.FSC_Actividad_economica__c, cuenta?.Actividad_Economica_Name__c }
		);
		String lugarLabora = primerTexto(new List<String>{ deudor?.FSC_LugarFondeLabora__c, empleo?.EmployerName });
		datos.actividadEconomica = unir(
			new List<String>{
				actividadEconomica,
				String.isBlank(lugarLabora) ? '' : 'Lugar donde labora: ' + lugarLabora,
				String.isBlank(empleo?.JobTitle) ? '' : 'Posición: ' + empleo.JobTitle
			},
			'\n'
		);
		datos.antiguedadLaboral = resolverAntiguedad(deudor, empleo);
	}

	private void configurarAnalisisFinanciero(
		ResidentialLoanApplication solicitud,
		Account cuenta,
		LoanApplicant deudor,
		ResumenIngresos ingresos,
		Decimal montoSolicitado,
		Decimal pagosCredito,
		Decimal totalPasivos,
		Decimal patrimonio,
		List<FSC_Excepcion__c> excepciones,
		List<String> evidenciasIngresos,
		List<FSC_Facilidades_De_Credito__c> facilidadesCredito
	) {
		datos.ingresosMensualesPromedio = formatearDineroSolicitud(ingresos.total);
		datos.evidenciaIngresos = String.join(evidenciasIngresos, '\n');
		datos.cuotasFinancieras = formatearDineroSolicitud(pagosCredito);
		datos.relacionCuotaIngresos = formatearRelacion(pagosCredito, ingresos.total);
		datos.endeudamientoTotal = formatearDineroSolicitud(totalPasivos);
		datos.solvenciaEstimada = formatearDineroSolicitud(patrimonio);
		datos.exposicionTotal = formatearDineroSolicitud(calcularExposicionTotal(montoSolicitado, facilidadesCredito));
		datos.scoreCrediticio = formatearEntero(solicitud.FSC_XCore_Buro__c);
		datos.scorePredictivo = formatearEntero(solicitud.FSC_XCore_Buro__c);
		datos.scoreInterno = '';
		datos.clasificacionRiesgo = primerTexto(new List<String>{ solicitud.FSC_Clasificacion_de_Riesgo__c, deudor?.FSC_ClasificacionSIB__c });
		datos.perfilRiesgo = texto(solicitud.FSC_CategoriaRiesgoBuro__c);
		datos.moraTc30 = formatearNumero(solicitud.FSC_MoraTC30Dias__c);
		datos.moraTc60 = formatearNumero(solicitud.FSC_MoraTC60Dias__c);
		datos.moraTc90 = formatearNumero(solicitud.FSC_MoraTC90Dias__c);
		datos.moraPrestamo30 = formatearNumero(solicitud.FSC_MoraPrestamo30Dias__c);
		datos.moraPrestamo60 = formatearNumero(solicitud.FSC_MoraPrestamo60Dias__c);
		datos.moraPrestamo90 = formatearNumero(solicitud.FSC_MoraPrestamo90Dias__c);
		datos.historialPago = FSC_ConsultaDocumentosAnalisisCredito.seleccionarHistorialPago(solicitud.Id);
		datos.excepciones = formatearExcepciones(excepciones);
		datos.recomendacion = primerTexto(new List<String>{ solicitud.FSC_Recomendaciones__c, solicitud.FSC_ObservacionAnalistaDeCredito__c });
		datos.fechaAprobacion = formatearFecha(
			solicitud.FSC_FechaYHoraAprobacionComite__c == null ? null : solicitud.FSC_FechaYHoraAprobacionComite__c.date()
		);
		datos.montoAprobado = formatearDineroSolicitud(solicitud.FSC_MontoAprobado__c);
	}

	private static String formatearExcepciones(List<FSC_Excepcion__c> excepciones) {
		if (excepciones == null || excepciones.isEmpty()) {
			return '';
		}

		List<String> resumenes = new List<String>();
		for (FSC_Excepcion__c excepcion : excepciones) {
			List<String> partes = new List<String>{
				'Tipo: ' + texto(excepcion.FSC_Tipo__c),
				'Detalle: ' + texto(excepcion.FSC_Detalle__c),
				'Motivo: ' + texto(excepcion.FSC_Motivo__c),
				'Condición: ' + texto(excepcion.FSC_Condicion__c),
				'Estado: ' + texto(excepcion.FSC_Estado__c)
			};
			resumenes.add(unir(partes, ', '));
		}
		return unir(resumenes, '\n\n');
	}

	private void cargarGarantia(
		ResidentialLoanApplication solicitud,
		List<FSC_Garantia__c> garantias,
		List<LoanApplicant> participantes,
		List<FSC_Facilidades_De_Credito__c> facilidadesCredito,
		Decimal montoSolicitado
	) {
		FSC_Garantia__c garantia = garantias.isEmpty() ? null : garantias[0];
		datos.mostrarGarantia = datos.esVehiculo || datos.esHipotecario;
		datos.garantiaTipo = primerTexto(
			new List<String>{ garantia?.FSC_Tipo_de_Garantia__c, garantia?.FSC_Clase_de_Garantia__c, solicitud.FSC_TipoGarantia__c }
		);
		datos.garantiaResumen = resolverResumenGarantia(solicitud, garantias, participantes, facilidadesCredito, datos.garantiaTipo);
		datos.garantiaUbicacion = texto(garantia?.FSC_Ubicacion__c);
		datos.garantiaSuperficie = formatearNumero(garantia?.FSC_Metros_Cuadrados_de_Construccion__c);
		datos.garantiaTasador = garantia?.FSC_EsTasadorExterno__c == true
			? texto(garantia?.FSC_NombreTasadorExterno__c)
			: texto(garantia?.FSC_Tasado_Por__c);
		datos.garantiaFechaTasacion = formatearFecha(garantia?.FSC_Fecha_Tasacion__c);
		Decimal valorTasacion = primerDecimal(
			new List<Decimal>{
				garantia?.FSC_Valor_Tasado__c,
				garantia?.FSC_Valor_Vehiculo__c,
				garantia?.FSC_Valor_Inmueble__c,
				solicitud.FSC_Valor_de_la_Garantia__c
			}
		);
		datos.garantiaValorTasacion = formatearDineroSolicitud(valorTasacion);
		datos.garantiaPrecioVenta = formatearDineroSolicitud(garantia?.FSC_Precio_de_Venta__c);
		datos.garantiaPagoInicial = formatearDineroSolicitud(garantia?.FSC_Monto_Inicial_Avance_Pagado__c);
		datos.garantiaMarca = texto(garantia?.FSC_Marca_Vehiculo__c);
		datos.garantiaModelo = texto(garantia?.FSC_Modelo_Vehiculo__c);
		datos.garantiaAno = formatearNumero(garantia?.FSC_Ano_Vehiculo__c);
		datos.prestamoSobreTasacion = formatearRelacion(montoSolicitado, valorTasacion);
		datos.prestamoSobrePrecioVenta = formatearRelacion(montoSolicitado, garantia?.FSC_Precio_de_Venta__c);
	}

	private void cargarCapacidadPago(
		ResumenIngresos ingresos,
		ResumenDeudas deudas,
		Decimal cuotaNueva,
		Decimal pagosCredito,
		Decimal pagoVivienda,
		Decimal totalPagos,
		Decimal totalActivos,
		Decimal totalPasivos,
		Decimal patrimonio,
		ResidentialLoanApplication solicitud
	) {
		datos.ingresoCartaTrabajo = formatearDineroSolicitud(ingresos.cartaTrabajo);
		datos.ingresoDepositos = formatearDineroSolicitud(ingresos.depositos);
		datos.ingresoAlquiler = formatearDineroSolicitud(ingresos.alquiler);
		datos.ingresoInversiones = formatearDineroSolicitud(ingresos.inversiones);
		datos.ingresoOtros = formatearDineroSolicitud(ingresos.otros);
		datos.ingresoEstadosFinancieros = formatearDineroSolicitud(ingresos.estadosFinancieros);
		datos.totalIngresos = formatearDineroSolicitud(ingresos.total);
		datos.deudaTarjetas = formatearDineroSolicitud(deudas.balanceTarjetas);
		datos.deudaPrestamos = formatearDineroSolicitud(deudas.balancePrestamos);
		datos.totalAdeudado = formatearDineroSolicitud(deudas.totalBalance);
		datos.cuotaTarjetas = formatearDineroSolicitud(deudas.cuotasTarjetas);
		datos.cuotaPrestamos = formatearDineroSolicitud(deudas.cuotasPrestamos);
		datos.cuotaNuevoPrestamo = formatearDineroSolicitud(cuotaNueva);
		datos.cuotasCancelar = formatearDineroSolicitud(deudas.cuotasPrestamosCancelar);
		datos.deudaTarjetasCancelar = formatearDineroSolicitud(deudas.cuotasTarjetasCancelar);
		datos.totalPagosCreditos = formatearDineroSolicitud(pagosCredito);
		datos.pagoVivienda = formatearDineroSolicitud(pagoVivienda);
		datos.totalPagos = formatearDineroSolicitud(totalPagos);
		datos.cargaFinanciera = formatearRelacion(pagosCredito, ingresos.total);
		datos.resultadoCargaFinanciera = evaluarRelacion(
			pagosCredito,
			ingresos.total,
			LIMITE_CARGA_FINANCIERA,
			'CAPACIDAD DE PAGO OK',
			'NO DEBE EXCEDER DEL 35%'
		);
		datos.capacidadIncluyendoVivienda = formatearRelacion(totalPagos, ingresos.total);
		datos.resultadoCapacidadVivienda = evaluarRelacion(
			totalPagos,
			ingresos.total,
			LIMITE_CAPACIDAD_VIVIENDA,
			'CAPACIDAD DE PAGO OK',
			'CAPACIDAD DE PAGO ESTRECHA'
		);
		Boolean mostrarActivosPasivos =
			datos.esMonedaPesos &&
			solicitud.FSC_Monto__c != null &&
			solicitud.FSC_Monto__c > MONTO_MINIMO_ACTIVOS_PASIVOS;
		datos.totalActivos = mostrarActivosPasivos ? formatearDineroSolicitud(totalActivos) : '';
		datos.totalPasivos = mostrarActivosPasivos ? formatearDineroSolicitud(totalPasivos) : '';
		datos.patrimonio = formatearDineroSolicitud(patrimonio);
		datos.indiceApalancamiento = formatearRelacion(totalPasivos, patrimonio);
		datos.resultadoApalancamiento = evaluarRelacion(
			totalPasivos,
			patrimonio,
			LIMITE_APALANCAMIENTO,
			'APALANCAMIENTO ADECUADO',
			'APALANCAMIENTO ELEVADO'
		);
		datos.capacidadEndeudamiento = formatearRelacion(totalPasivos, totalActivos);
		datos.resultadoEndeudamiento = evaluarRelacion(
			totalPasivos,
			totalActivos,
			LIMITE_ENDEUDAMIENTO,
			'ENDEUDAMIENTO ADECUADO',
			'ENDEUDAMIENTO ELEVADO'
		);
		registrarMontoMoneda('ingresoCartaTrabajo', ingresos.cartaTrabajo);
		registrarMontoMoneda('ingresoDepositos', ingresos.depositos);
		registrarMontoMoneda('ingresoAlquiler', ingresos.alquiler);
		registrarMontoMoneda('ingresoInversiones', ingresos.inversiones);
		registrarMontoMoneda('ingresoOtros', ingresos.otros);
		registrarMontoMoneda('ingresoEstadosFinancieros', ingresos.estadosFinancieros);
		registrarMontoMoneda('totalIngresos', ingresos.total);
		registrarMontoMoneda('deudaTarjetas', deudas.balanceTarjetas);
		registrarMontoMoneda('deudaPrestamos', deudas.balancePrestamos);
		registrarMontoMoneda('totalAdeudado', deudas.totalBalance);
		registrarMontoMoneda('cuotaTarjetas', deudas.cuotasTarjetas);
		registrarMontoMoneda('cuotaPrestamos', deudas.cuotasPrestamos);
		registrarMontoMoneda('cuotaNuevoPrestamo', cuotaNueva);
		registrarMontoMoneda('cuotasCancelar', deudas.cuotasPrestamosCancelar);
		registrarMontoMoneda('deudaTarjetasCancelar', deudas.cuotasTarjetasCancelar);
		registrarMontoMoneda('totalPagosCreditos', pagosCredito);
		registrarMontoMoneda('pagoVivienda', pagoVivienda);
		registrarMontoMoneda('totalPagos', totalPagos);
		datos.comentarios = texto(solicitud.FSC_ObservacionAnalistaDeCredito__c);
	}

	private static ResumenIngresos resumirIngresos(
		List<LoanApplicantIncome> ingresos,
		List<LoanApplicant> participantes,
		Set<Id> participantesEconomicosIds,
		LoanApplicant deudor,
		LoanApplicantEmployment empleo,
		ResidentialLoanApplication solicitud
	) {
		ResumenIngresos resumen = new ResumenIngresos();
		for (LoanApplicantIncome ingreso : ingresos) {
			if (!participantesEconomicosIds.contains(ingreso.LoanApplicantId) || ingreso.MonthlyIncomeAmount == null) {
				continue;
			}
			agregarIngreso(resumen, ingreso.IncomeSourceType, ingreso.MonthlyIncomeAmount);
		}

		if (resumen.total == null || resumen.total == 0) {
			for (LoanApplicant participante : participantes) {
				if (!participantesEconomicosIds.contains(participante.Id)) {
					continue;
				}
				Decimal ingresoBase = participante.FSC_IngresosMensuales__c;
				if (participante.Id == deudor?.Id && ingresoBase == null) {
					ingresoBase = empleo?.MonthlyTotalIncomeAmount;
				}
				Decimal otrosIngresos = participante.FSC_OtrosIngresos__c;
				if (
					ingresoBase == null &&
					otrosIngresos == null &&
					participante.FSC_TotalIngresos__c != null &&
					participante.FSC_TotalIngresos__c > 0
				) {
					ingresoBase = participante.FSC_TotalIngresos__c;
				}
				agregarIngreso(resumen, participante.FSC_FuenteIngreso__c, ingresoBase);
				resumen.otros = acumular(resumen.otros, otrosIngresos);
				resumen.total = acumular(resumen.total, otrosIngresos);
			}
		}

		if (resumen.total == null || resumen.total == 0) {
			Decimal ingresoSolicitud = primerDecimal(
				new List<Decimal>{ solicitud.FSC_Ingresos_Mensuales__c, solicitud.FSC_Monto_de_los_Ingresos__c }
			);
			agregarIngreso(resumen, solicitud.FSC_Origen_de_los_Ingresos__c, ingresoSolicitud);
		}
		return resumen;
	}

	private static void agregarIngreso(ResumenIngresos resumen, String fuenteOriginal, Decimal monto) {
		if (monto == null) {
			return;
		}
		String fuente = texto(fuenteOriginal).toLowerCase();
		if (fuente.contains('estado financiero')) {
			resumen.estadosFinancieros = acumular(resumen.estadosFinancieros, monto);
		} else if (fuente.contains('alquiler') || fuente.contains('rental')) {
			resumen.alquiler = acumular(resumen.alquiler, monto);
		} else if (fuente.contains('invers') || fuente.contains('interest')) {
			resumen.inversiones = acumular(resumen.inversiones, monto);
		} else if (fuente.contains('independ') || fuente.contains('business') || fuente.contains('negocio')) {
			resumen.depositos = acumular(resumen.depositos, monto);
		} else if (fuente.contains('otro')) {
			resumen.otros = acumular(resumen.otros, monto);
		} else {
			resumen.cartaTrabajo = acumular(resumen.cartaTrabajo, monto);
		}
		resumen.total = acumular(resumen.total, monto);
	}

	private static ResumenDeudas resumirDeudas(List<LoanApplicationLiability> deudas, List<FSC_Facilidad_Otra_Institucion__c> facilidadesExternas) {
		ResumenDeudas resumen = new ResumenDeudas();
		for (LoanApplicationLiability deuda : deudas) {
			Decimal balance = deuda.UnpaidBalanceAmount;
			Boolean esTarjeta = esTarjeta(texto(deuda.AccountType) + ' ' + texto(deuda.LiabilityClass) + ' ' + texto(deuda.LoanType));
			Decimal cuota = esTarjeta && balance != null ? balance * PORCENTAJE_PAGO_MINIMO_TARJETA : deuda.MonthlyPaymentAmount;
			agregarDeuda(resumen, esTarjeta, balance, cuota, deuda.ShouldBePaidInFull == true);
		}

		if (resumen.totalBalance == null && resumen.totalCuotas == null) {
			for (FSC_Facilidad_Otra_Institucion__c facilidad : facilidadesExternas) {
				String tipo = texto(facilidad.FSC_TipoFacilidad__c) + ' ' + texto(facilidad.FSC_Facilidad__c);
				Boolean esFacilidadTarjeta = esTarjeta(tipo);
				Decimal cuota = esFacilidadTarjeta && facilidad.FSC_Balance__c != null
					? facilidad.FSC_Balance__c * PORCENTAJE_PAGO_MINIMO_TARJETA
					: null;
				agregarDeuda(resumen, esFacilidadTarjeta, facilidad.FSC_Balance__c, cuota, false);
			}
		}
		return resumen;
	}

	private static void agregarDeuda(ResumenDeudas resumen, Boolean esTarjetaCredito, Decimal balance, Decimal cuota, Boolean cancelar) {
		if (esTarjetaCredito) {
			resumen.balanceTarjetas = acumular(resumen.balanceTarjetas, balance);
			resumen.cuotasTarjetas = acumular(resumen.cuotasTarjetas, cuota);
			if (cancelar) {
				resumen.cuotasTarjetasCancelar = acumular(resumen.cuotasTarjetasCancelar, cuota);
			}
		} else {
			resumen.balancePrestamos = acumular(resumen.balancePrestamos, balance);
			resumen.cuotasPrestamos = acumular(resumen.cuotasPrestamos, cuota);
			if (cancelar) {
				resumen.cuotasPrestamosCancelar = acumular(resumen.cuotasPrestamosCancelar, cuota);
			}
		}
		resumen.totalBalance = acumular(resumen.totalBalance, balance);
		resumen.totalCuotas = acumular(resumen.totalCuotas, cuota);
		if (cancelar) {
			resumen.totalCuotasCancelar = acumular(resumen.totalCuotasCancelar, cuota);
		}
	}

	private static Set<Id> obtenerParticipantesEconomicosIds(List<LoanApplicant> participantes, LoanApplicant deudor) {
		Set<Id> resultado = new Set<Id>();
		for (LoanApplicant participante : participantes) {
			String tipo = texto(participante.FSC_TipoSolicitante__c).toLowerCase();
			if (participante.Id == deudor?.Id || tipo.contains('co-deudor') || tipo.contains('codeudor')) {
				resultado.add(participante.Id);
			}
		}
		return resultado;
	}

	private static Decimal resumirActivos(List<LoanApplicationAsset> activos, Account cuenta, ResidentialLoanApplication solicitud) {
		Decimal total;
		for (LoanApplicationAsset activo : activos) {
			total = acumular(total, primerDecimal(new List<Decimal>{ activo.CashOrMarketValue, activo.PresentMarketValue }));
		}
		return primerDecimal(new List<Decimal>{ total, cuenta?.ACC_Total_Activos__c, solicitud.FSC_Total_activos__c });
	}

	private static LoanApplicant encontrarDeudor(List<LoanApplicant> participantes) {
		for (LoanApplicant participante : participantes) {
			String tipo = texto(participante.FSC_TipoSolicitante__c).toLowerCase();
			if (tipo.contains('deudor') && !tipo.contains('co')) {
				return participante;
			}
		}
		return participantes.isEmpty() ? null : participantes[0];
	}

	private static String resolverTipoPrestamo(String recordTypeDeveloperName) {
		if (recordTypeDeveloperName == TIPO_HIPOTECARIO) {
			return 'Hipotecario';
		}
		if (recordTypeDeveloperName == TIPO_VEHICULO) {
			return 'Vehículo';
		}
		return 'Consumo';
	}

	private static String nombreParticipante(LoanApplicant participante) {
		return participante == null
			? ''
			: unir(new List<String>{ participante.FSC_Nombre__c, participante.FSC_PrimerApellido__c, participante.FSC_SegundoApellido__c }, ' ');
	}

	private static String construirDireccion(Account cuenta) {
		return cuenta == null
			? ''
			: unir(new List<String>{ cuenta.BillingStreet, cuenta.BillingCity, cuenta.BillingState, cuenta.BillingCountry }, ', ');
	}

	private static String resolverAntiguedad(LoanApplicant deudor, LoanApplicantEmployment empleo) {
		if (empleo?.CurrentJobYearCount != null || empleo?.CurrentJobAdditionalMonthCount != null) {
			return unir(
				new List<String>{
					empleo?.CurrentJobYearCount == null ? '' : texto(empleo.CurrentJobYearCount) + ' años',
					empleo?.CurrentJobAdditionalMonthCount == null ? '' : texto(empleo.CurrentJobAdditionalMonthCount) + ' meses'
				},
				', '
			);
		}
		return formatearAntiguedadDesde(deudor?.FSC_TiempoLaborando__c);
	}

	private static String formatearAntiguedadDesde(Date fechaInicio) {
		if (fechaInicio == null || fechaInicio > Date.today()) {
			return '';
		}
		Date hoy = Date.today();
		Integer meses = (hoy.year() - fechaInicio.year()) * 12 + hoy.month() - fechaInicio.month();
		if (hoy.day() < fechaInicio.day()) {
			meses--;
		}
		Integer anos = meses / 12;
		Integer mesesRestantes = Math.mod(meses, 12);
		if (anos == 0 && mesesRestantes == 0) {
			return 'Menos de 1 mes';
		}
		return unir(
			new List<String>{ anos == 0 ? '' : String.valueOf(anos) + ' años', mesesRestantes == 0 ? '' : String.valueOf(mesesRestantes) + ' meses' },
			', '
		);
	}

	private static String calcularEdad(Date nacimiento) {
		if (nacimiento == null) {
			return '';
		}
		Date hoy = Date.today();
		Integer edad = hoy.year() - nacimiento.year();
		if (hoy.month() < nacimiento.month() || (hoy.month() == nacimiento.month() && hoy.day() < nacimiento.day())) {
			edad--;
		}
		return String.valueOf(edad);
	}

	private static Decimal calcularPagosCreditos(Decimal pagosExistentes, Decimal cuotaNueva, Decimal pagosCancelar) {
		Decimal total = sumarValores(new List<Decimal>{ pagosExistentes, cuotaNueva, pagosCancelar == null ? null : -pagosCancelar });
		return total != null && total < 0 ? 0 : total;
	}

	private static Decimal acumular(Decimal acumulado, Decimal monto) {
		return monto == null ? acumulado : (acumulado ?? 0) + monto;
	}

	private static Decimal sumarValores(List<Decimal> valores) {
		Decimal total;
		for (Decimal valor : valores) {
			total = acumular(total, valor);
		}
		return total;
	}

	private static Decimal calcularExposicionTotal(Decimal montoSolicitado, List<FSC_Facilidades_De_Credito__c> facilidadesCredito) {
		if (facilidadesCredito == null || facilidadesCredito.isEmpty()) {
			return null;
		}

		Decimal total = montoSolicitado;
		Boolean facilidadPrincipalEncontrada = false;
		for (FSC_Facilidades_De_Credito__c facilidad : facilidadesCredito) {
			Decimal montoFacilidad = facilidad.FSC_Monto_Solicitado__c;
			if (!facilidadPrincipalEncontrada && montoSolicitado != null && montoFacilidad == montoSolicitado) {
				facilidadPrincipalEncontrada = true;
				continue;
			}
			total = acumular(total, montoFacilidad);
		}
		return total;
	}

	private static String resolverResumenGarantia(
		ResidentialLoanApplication solicitud,
		List<FSC_Garantia__c> garantias,
		List<LoanApplicant> participantes,
		List<FSC_Facilidades_De_Credito__c> facilidadesCredito,
		String tipoGarantia
	) {
		Boolean requierePagareNotarial = solicitud.FSC_RequiereContratoPagareNotarial__c == true;
		for (FSC_Facilidades_De_Credito__c facilidad : facilidadesCredito) {
			requierePagareNotarial = requierePagareNotarial || facilidad.FSC_Requiere_Contrato_Pagare_Notarial__c == true;
		}
		if (requierePagareNotarial) {
			return 'Pagaré notarial';
		}

		for (LoanApplicant participante : participantes) {
			if (texto(participante.FSC_TipoSolicitante__c).toLowerCase().contains('garante')) {
				return 'Con garantía solidaria';
			}
		}

		if (!garantias.isEmpty() || solicitud.FSC_PrestamoGarantia__c == true) {
			return String.isBlank(tipoGarantia) ? 'Con garantía' : tipoGarantia;
		}
		return 'A sola firma';
	}

	private static Decimal restar(Decimal uno, Decimal dos) {
		return uno == null && dos == null ? null : (uno ?? 0) - (dos ?? 0);
	}

	private static Decimal primerDecimal(List<Decimal> valores) {
		for (Decimal valor : valores) {
			if (valor != null) {
				return valor;
			}
		}
		return null;
	}

	private static String primerTexto(List<String> valores) {
		for (String valor : valores) {
			if (!String.isBlank(valor)) {
				return valor;
			}
		}
		return '';
	}

	private static String unir(List<String> valores, String separador) {
		List<String> limpios = new List<String>();
		for (String valor : valores) {
			if (!String.isBlank(valor)) {
				limpios.add(valor.trim());
			}
		}
		return String.join(limpios, separador);
	}

	private static Boolean esTarjeta(String tipo) {
		String tipoNormalizado = texto(tipo).toLowerCase();
		return tipoNormalizado.contains('card') || tipoNormalizado.contains('tarjeta');
	}

	private void configurarMoneda(String monedaOriginal) {
		String moneda = texto(monedaOriginal).trim().toUpperCase();
		datos.esMonedaDolar = moneda == '2' || moneda == 'USD' || moneda.contains('DOLAR');
		Boolean esEuro = moneda == '3' || moneda == 'EUR' || moneda.contains('EURO');
		datos.esMonedaPesos = !datos.esMonedaDolar && !esEuro;
		simboloMonedaSolicitud = datos.esMonedaDolar ? 'US$' : (esEuro ? 'EUR' : 'RD$');
		tasaCambioActual = FSC_ConsultaDocumentosAnalisisCredito.seleccionarTasaCambioActual();
		datos.tasaCambio = tasaCambioActual == null ? '' : tasaCambioActual.setScale(4).format();
	}

	private void registrarMontoMoneda(String clave, Decimal valor) {
		datos.montosPesos.put(clave, '');
		datos.montosDolares.put(clave, '');
		datos.totalesPesos.put(clave, '');

		if (datos.esMonedaDolar) {
			datos.montosDolares.put(clave, formatearDineroConSimbolo(valor, 'US$'));
			datos.totalesPesos.put(clave, tasaCambioActual == null || valor == null ? '' : formatearDinero(valor * tasaCambioActual));
		} else if (datos.esMonedaPesos) {
			datos.montosPesos.put(clave, formatearDinero(valor));
			datos.totalesPesos.put(clave, formatearDinero(valor));
		}
	}

	private static void aplicarFacilidadesBuro(ResumenDeudas resumen, ResidentialLoanApplication solicitud, Boolean usarDolares) {
		Decimal deudaTarjetas = usarDolares == true ? solicitud.FSC_DeudaTCBuroUSD__c : solicitud.FSC_DeudaTCBuroDOP__c;
		Decimal deudaPrestamos = usarDolares == true ? solicitud.FSC_DeudaPrestamoBuroUSD__c : solicitud.FSC_DeudaPrestamoBuroDOP__c;
		Decimal cuotaTarjetas = usarDolares == true ? solicitud.FSC_CuotaTCBuroUSD__c : solicitud.FSC_CuotaTCBuroDOP__c;
		Decimal cuotaPrestamos = usarDolares == true ? solicitud.FSC_CuotaPrestamoBuroUSD__c : solicitud.FSC_CuotaPrestamoBuroDOP__c;
		if (deudaTarjetas == null && deudaPrestamos == null && cuotaTarjetas == null && cuotaPrestamos == null) {
			return;
		}

		resumen.balanceTarjetas = deudaTarjetas ?? 0;
		resumen.balancePrestamos = deudaPrestamos ?? 0;
		// El pago mínimo de tarjetas siempre es el 8% del monto adeudado en tarjetas.
		resumen.cuotasTarjetas = deudaTarjetas != null ? deudaTarjetas * PORCENTAJE_PAGO_MINIMO_TARJETA : (cuotaTarjetas ?? 0);
		resumen.cuotasPrestamos = cuotaPrestamos ?? 0;
		resumen.totalBalance = resumen.balanceTarjetas + resumen.balancePrestamos;
		resumen.totalCuotas = resumen.cuotasTarjetas + resumen.cuotasPrestamos;
	}

	private String formatearDineroSolicitud(Decimal valor) {
		return formatearDineroConSimbolo(valor, simboloMonedaSolicitud);
	}

	private static String formatearDinero(Decimal valor) {
		return formatearDineroConSimbolo(valor, 'RD$');
	}

	private static String formatearDineroConSimbolo(Decimal valor, String simbolo) {
		return valor == null ? '' : simbolo + ' ' + valor.setScale(2).format();
	}

	private static String formatearNumero(Decimal valor) {
		return valor == null ? '' : String.valueOf(valor);
	}

	private static String formatearEntero(Decimal valor) {
		return valor == null ? '' : String.valueOf(valor.setScale(0));
	}

	private static String formatearPorcentaje(Decimal valor) {
		return valor == null ? '' : valor.setScale(2).format() + '%';
	}

	private static String formatearRelacion(Decimal numerador, Decimal denominador) {
		if (numerador == null || denominador == null || denominador == 0) {
			return '';
		}
		return (numerador / denominador * 100).setScale(2).format() + '%';
	}

	private static String evaluarRelacion(
		Decimal numerador,
		Decimal denominador,
		Decimal limite,
		String resultadoPositivo,
		String resultadoNegativo
	) {
		if (numerador == null || denominador == null || denominador == 0) {
			return '';
		}
		return numerador / denominador <= limite ? resultadoPositivo : resultadoNegativo;
	}

	private static String formatearFecha(Date valor) {
		return valor == null
			? ''
			: String.valueOf(valor.day()).leftPad(2, '0') + '/' + String.valueOf(valor.month()).leftPad(2, '0') + '/' + valor.year();
	}

	private static String resolverEtiquetaSucursal(String valorSucursal) {
		if (String.isBlank(valorSucursal)) {
			return '';
		}
		for (Schema.PicklistEntry opcion : User.FSC_Sucursal__c.getDescribe().getPicklistValues()) {
			if (opcion.getValue() == valorSucursal) {
				return opcion.getLabel();
			}
		}
		return valorSucursal;
	}

	private static String texto(Object valor) {
		return valor == null ? '' : String.valueOf(valor);
	}

	private class ResumenIngresos {
		private Decimal cartaTrabajo;
		private Decimal depositos;
		private Decimal alquiler;
		private Decimal inversiones;
		private Decimal otros;
		private Decimal estadosFinancieros;
		private Decimal total;
	}

	private class ResumenDeudas {
		private Decimal balanceTarjetas;
		private Decimal balancePrestamos;
		private Decimal totalBalance;
		private Decimal cuotasTarjetas;
		private Decimal cuotasPrestamos;
		private Decimal totalCuotas;
		private Decimal totalCuotasCancelar;
		private Decimal cuotasPrestamosCancelar;
		private Decimal cuotasTarjetasCancelar;
	}
}
