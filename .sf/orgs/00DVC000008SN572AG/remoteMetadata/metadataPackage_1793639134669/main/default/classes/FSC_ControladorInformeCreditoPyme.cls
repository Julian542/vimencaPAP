/**
 * Prepara el informe de análisis de crédito Pyme para persona física.
 */
@SuppressWarnings('PMD.ApexXSSFromURLParam')
public with sharing class FSC_ControladorInformeCreditoPyme {
	private static final String PREFIJO_DOCUMENTO = 'Informe de Crédito Pyme';
	private static final Decimal PORCENTAJE_PAGO_MINIMO_TARJETA = 0.08;

	public Map<String, String> datos { get; private set; }

	public FSC_ControladorInformeCreditoPyme() {
		datos = crearDatosVacios();
		PageReference paginaActual = ApexPages.currentPage();
		String solicitudId = paginaActual == null ? null : paginaActual.getParameters().get('id');
		if (String.isBlank(solicitudId) || !Pattern.matches('[a-zA-Z0-9]{15,18}', solicitudId)) {
			return;
		}

		Id solicitudValidaId = (Id) solicitudId.escapeHtml4();
		datos = construirDatosBase(solicitudValidaId);
		aplicarEdicionesGuardadas(solicitudValidaId, datos);
	}

	/** Devuelve el mismo modelo final que consume la plantilla PDF. */
	public static Map<String, Object> construirDatos(Id solicitudId) {
		Map<String, String> resultadoBase = construirDatosBase(solicitudId);
		aplicarEdicionesGuardadas(solicitudId, resultadoBase);
		Map<String, Object> resultado = new Map<String, Object>();
		for (String clave : resultadoBase.keySet()) {
			resultado.put(clave, resultadoBase.get(clave));
		}
		resultado.put('esPyme', true);
		return resultado;
	}

	private static Map<String, String> construirDatosBase(Id solicitudId) {
		Map<String, String> resultado = crearDatosVacios();
		if (solicitudId == null) {
			return resultado;
		}

		List<ResidentialLoanApplication> solicitudes = [
			SELECT
				Id,
				Name,
				AccountId,
				CreatedDate,
				CreatedBy.Name,
				CreatedBy.FSC_Sucursal__c,
				FSC_CreatedBy_Name__c,
				FSC_UsuarioAnalista__r.Name,
				FSC_UsuarioSupervisor__r.Name,
				FSC_NumeroCliente__c,
				FSC_Direccion_del_Negocio__c,
				FSC_Actividad_economica__c,
				FSC_Clasificacion_de_Riesgo__c,
				FSC_Grupo_de_Empresa__c,
				FSC_clasificacionSib__c,
				FSC_XCore_Buro__c,
				FSC_Tipo_de_solicitud__c,
				FSC_TipoGarantia__c,
				FSC_Tipo_de_Garantia__c,
				FSC_Porcentaje_de_Admisibilidad__c,
				FSC_productoBanco__c,
				FSC_Valor_de_la_Garantia__c,
				FSC_Monto__c,
				FSC_Plazo_meses__c,
				FSC_PlazoMeses__c,
				FSC_TasaInteres__c,
				FSC_Monto_De_La_Cuota__c,
				FSC_Destino_del_Prestamo__c,
				FSC_DescripcionPropositoFacilidad__c,
				FSC_Descripcion_de_la_Garantia__c,
				FSC_DestinoTaxonomiaVerde__c,
				FSC_CodigoTaxonomia__c,
				FSC_ActividadesTaxonomiaVerde__c,
				FSC_FechaYHoraAprobacionComite__c,
				FSC_FechaAprobacion__c,
				FSC_DiaEstadoSituacion__c,
				FSC_MesEstadoSituacion__c,
				FSC_AnoEstadoSituacion__c,
				FSC_ObservacionAnalistaDeCredito__c,
				FSC_Historial_del_cliente__c,
				FSC_HistorialPago__c,
				FSC_Recomendaciones__c,
				FSC_VentasSalario__c,
				FSC_ResultadoGananciasPerdida__c,
				FSC_Total_activos__c,
				FSC_Total_Pasivos__c,
				FSC_Capital__c,
				FSC_Total_Activos_Fijos__c,
				FSC_Inventario__c,
				FSC_Cuentas_por_cobrar_clientes__c,
				FSC_Efectivo_en_caja_y_bancos__c,
				FSC_Descripcion_del_Negocio__c,
				FSC_Tiempo_del_negocio__c,
				FSC_A_os_de_operacion__c,
				FSC_Situacion_Legal__c,
				FSC_Cantidad_de_empleados__c,
				FSC_VentasBrutasAnuales__c
			FROM ResidentialLoanApplication
			WHERE Id = :solicitudId
			WITH USER_MODE
			LIMIT 1
		];
		if (solicitudes.isEmpty()) {
			return resultado;
		}

		ResidentialLoanApplication solicitud = solicitudes[0];
		Account cuenta = seleccionarCuenta(solicitud.AccountId);
		List<LoanApplicant> participantes = seleccionarParticipantes(solicitud.Id);
		LoanApplicant deudor = encontrarDeudor(participantes);
		List<FSC_Garantia__c> garantias = seleccionarGarantias(solicitud.Id);
		FSC_Garantia__c garantia = garantias.isEmpty() ? null : garantias[0];
		List<FSC_Facilidades_De_Credito__c> facilidades = seleccionarFacilidades(solicitud.Id);
		List<LoanApplicationLiability> compromisos = seleccionarCompromisos(solicitud.Id);
		List<FSC_Facilidad_Otra_Institucion__c> facilidadesExternas = seleccionarFacilidadesExternas(participantes);
		List<FinServ__FinancialAccount__c> cuentasFinancieras = seleccionarCuentasFinancieras(solicitud.AccountId);

		Decimal deudaSistema = sumarDeudas(compromisos, facilidadesExternas);
		Decimal exposicionBanco = calcularExposicionBanco(solicitud.FSC_Monto__c, facilidades, cuentasFinancieras);
		Map<String, Decimal> tasasCambio = seleccionarTasasCambio();
		Decimal valorGarantia = primerDecimal(
			new List<Decimal>{
				garantia?.FSC_Valor_Tasado__c,
				garantia?.FSC_Valor_Vehiculo__c,
				garantia?.FSC_Valor_Inmueble__c,
				solicitud.FSC_Valor_de_la_Garantia__c
			}
		);

		resultado.put('numeroSolicitud', texto(solicitud.Name));
		resultado.put('fechaInforme', formatearFecha(Date.today()));
		resultado.put('unidadSucursal', resolverEtiquetaSucursal(solicitud.CreatedBy?.FSC_Sucursal__c));
		resultado.put('ejecutivo', primerTexto(new List<String>{ solicitud.FSC_CreatedBy_Name__c, solicitud.CreatedBy?.Name }));
		resultado.put('tasaCambioUsd', formatearNumero(tasasCambio.get('USD')));
		resultado.put('tasaCambioEuro', formatearNumero(tasasCambio.get('EUR')));
		resultado.put('solicitante', primerTexto(new List<String>{ nombreParticipante(deudor), cuenta?.Name }));
		resultado.put('cedula', primerTexto(new List<String>{ deudor?.FSC_NumIdentificacion__c, cuenta?.ACC_NumIdentificacion__c }));
		resultado.put('direccionResidencial', construirDireccion(cuenta));
		resultado.put('codigoAbanks', texto(solicitud.FSC_NumeroCliente__c));
		resultado.put('direccionComercial', texto(solicitud.FSC_Direccion_del_Negocio__c));
		resultado.put('sectorEconomico', etiquetaPicklist(Account.ACC_Tipo_Sector__c, cuenta?.ACC_Tipo_Sector__c));
		resultado.put('actividadComercial', texto(solicitud.FSC_Actividad_economica__c));
		resultado.put('clasificacionRiesgoBv', primerTexto(new List<String>{ cuenta?.ACC_Categoria_Riesgo_Cliente__c, solicitud.FSC_Clasificacion_de_Riesgo__c }));
		resultado.put('grupoRiesgo', texto(solicitud.FSC_Grupo_de_Empresa__c));
		resultado.put('tipoDeudor', texto(solicitud.FSC_clasificacionSib__c));
		resultado.put('clasificacionRiesgoSib', texto(solicitud.FSC_Clasificacion_de_Riesgo__c));
		resultado.put('scoreBuro', formatearEntero(solicitud.FSC_XCore_Buro__c));
		resultado.put('deudaSistemaFinanciero', formatearDinero(deudaSistema));
		resultado.put('exposicionConsolidadaBv', formatearDinero(exposicionBanco));

		resultado.put('tipoTramitacion', texto(solicitud.FSC_Tipo_de_solicitud__c));
		resultado.put('tipoGarantia', primerTexto(new List<String>{ solicitud.FSC_TipoGarantia__c, garantia?.FSC_Clase_de_Garantia__c }));
		resultado.put('admisibilidad', formatearPorcentaje(solicitud.FSC_Porcentaje_de_Admisibilidad__c));
		resultado.put('tipoCredito', primerTexto(new List<String>{ solicitud.FSC_productoBanco__c, primeraFacilidad(facilidades) }));
		resultado.put('valorGarantia', formatearDinero(valorGarantia));
		resultado.put('cobertura', formatearRelacion(valorGarantia, solicitud.FSC_Monto__c));
		resultado.put('montoSolicitado', formatearDinero(solicitud.FSC_Monto__c));
		resultado.put('fechaTasacion', formatearFecha(garantia?.FSC_Fecha_Tasacion__c));
		resultado.put('tipoBienGarantia', texto(garantia?.FSC_Tipo_de_Garantia__c));
		resultado.put('plazoMeses', primerTexto(new List<String>{ texto(solicitud.FSC_PlazoMeses__c), solicitud.FSC_Plazo_meses__c }));
		resultado.put('usoFondos', primerTexto(new List<String>{ solicitud.FSC_Destino_del_Prestamo__c, solicitud.FSC_DescripcionPropositoFacilidad__c }));
		resultado.put('tasaInteres', formatearPorcentaje(solicitud.FSC_TasaInteres__c));
		resultado.put('cuotaEstimada', formatearDinero(solicitud.FSC_Monto_De_La_Cuota__c));
		resultado.put('descripcionGarantia', primerTexto(new List<String>{ garantia?.FSC_Descripcion_de_la_Garantia__c, solicitud.FSC_Descripcion_de_la_Garantia__c }));

		resultado.put('destinoTaxonomiaVerde', texto(solicitud.FSC_DestinoTaxonomiaVerde__c));
		resultado.put('codigoActividadTaxonomia', texto(solicitud.FSC_CodigoTaxonomia__c));
		resultado.put(
			'actividadTaxonomiaVerde',
			etiquetaPicklist(ResidentialLoanApplication.FSC_ActividadesTaxonomiaVerde__c, solicitud.FSC_ActividadesTaxonomiaVerde__c)
		);
		resultado.put('fechaDecision', formatearFecha(resolverFechaDecision(solicitud)));
		resultado.put('realizadoPor', texto(solicitud.FSC_UsuarioAnalista__r?.Name));
		resultado.put('revisadoPor', texto(solicitud.FSC_UsuarioSupervisor__r?.Name));

		cargarFacilidadesSolicitadas(resultado, facilidades);
		cargarProductosBanco(resultado, cuentasFinancieras);
		cargarCreditosExternos(resultado, facilidadesExternas);
		cargarCompromisos(resultado, compromisos, solicitud);

		Decimal totalActivos = solicitud.FSC_Total_activos__c;
		Decimal totalPasivos = solicitud.FSC_Total_Pasivos__c;
		Decimal patrimonio = primerDecimal(new List<Decimal>{ solicitud.FSC_Capital__c, restar(totalActivos, totalPasivos) });
		resultado.put('perfilActividadComercial', construirPerfil(solicitud));
		resultado.put('fechaEstadosFinancieros', construirFechaEstadosFinancieros(solicitud));
		resultado.put('ingresosFinancieros', formatearDinero(solicitud.FSC_VentasSalario__c));
		resultado.put('utilidadNeta', formatearDinero(solicitud.FSC_ResultadoGananciasPerdida__c));
		resultado.put('activosTotales', formatearDinero(totalActivos));
		resultado.put('pasivosTotales', formatearDinero(totalPasivos));
		resultado.put('patrimonio', formatearDinero(patrimonio));
		resultado.put('apalancamiento', formatearRelacion(totalPasivos, patrimonio));
		resultado.put('activosFijos', formatearDinero(solicitud.FSC_Total_Activos_Fijos__c));
		resultado.put('deudasBancarias', formatearDinero(deudaSistema));
		resultado.put('inventario', formatearDinero(solicitud.FSC_Inventario__c));
		resultado.put('cuentasPorCobrar', formatearDinero(solicitud.FSC_Cuentas_por_cobrar_clientes__c));
		resultado.put('cajaBancos', formatearDinero(solicitud.FSC_Efectivo_en_caja_y_bancos__c));
		resultado.put('analisisFinanciero', texto(solicitud.FSC_ObservacionAnalistaDeCredito__c));
		resultado.put('comportamientoHistorico', primerTexto(new List<String>{ solicitud.FSC_HistorialPago__c, solicitud.FSC_Historial_del_cliente__c }));
		resultado.put('resumenClasificacionSib', construirResumenSib(solicitud));
		resultado.put('mitigantes', String.isBlank(resultado.get('tipoGarantia')) ? '' : 'Facilidad con garantía: ' + resultado.get('tipoGarantia'));
		resultado.put('conclusionesRecomendaciones', texto(solicitud.FSC_Recomendaciones__c));
		return resultado;
	}

	private static void cargarFacilidadesSolicitadas(Map<String, String> resultado, List<FSC_Facilidades_De_Credito__c> facilidades) {
		List<String> tipos = new List<String>();
		List<String> montos = new List<String>();
		List<String> plazos = new List<String>();
		List<String> tasas = new List<String>();
		List<String> cuotas = new List<String>();
		List<String> usos = new List<String>();
		for (FSC_Facilidades_De_Credito__c facilidad : facilidades) {
			tipos.add(primerTexto(new List<String>{ facilidad.FSC_Tipo_de_Facilidad__c, facilidad.FSC_Tipo_Facilidad__c, facilidad.FSC_Facilidad__c }));
			montos.add(formatearDinero(facilidad.FSC_Monto_Solicitado__c));
			plazos.add(formatearEntero(facilidad.FSC_Plazo_meses__c));
			tasas.add(formatearPorcentaje(primerDecimal(new List<Decimal>{ facilidad.FSC_Tasa_Interes__c, facilidad.FSC_Tasa__c })));
			cuotas.add(formatearDinero(facilidad.FSC_Monto_De_La_Cuota__c));
			usos.add(texto(facilidad.FSC_Descripcion_Proposito_Facilidad__c));
		}
		resultado.put('facilidadesTipoCredito', unirFilas(tipos));
		resultado.put('facilidadesMonto', unirFilas(montos));
		resultado.put('facilidadesPlazo', unirFilas(plazos));
		resultado.put('facilidadesTasa', unirFilas(tasas));
		resultado.put('facilidadesCuota', unirFilas(cuotas));
		resultado.put('facilidadesUsoFondos', unirFilas(usos));
	}

	private static void cargarProductosBanco(Map<String, String> resultado, List<FinServ__FinancialAccount__c> cuentas) {
		List<FinServ__FinancialAccount__c> certificados = new List<FinServ__FinancialAccount__c>();
		List<FinServ__FinancialAccount__c> cuentasDeposito = new List<FinServ__FinancialAccount__c>();
		List<FinServ__FinancialAccount__c> productosCredito = new List<FinServ__FinancialAccount__c>();
		for (FinServ__FinancialAccount__c cuenta : cuentas) {
			String tipo = descripcionCuenta(cuenta).toLowerCase();
			if (tipo.contains('certif') || tipo.contains('deposito a plazo') || tipo.contains('term deposit')) {
				certificados.add(cuenta);
			} else if (tipo.contains('prestamo') || tipo.contains('credito') || tipo.contains('tarjeta') || tipo.contains('loan') || tipo.contains('card')) {
				productosCredito.add(cuenta);
			} else {
				cuentasDeposito.add(cuenta);
			}
		}

		Decimal totalCertificadoApertura;
		Decimal totalCertificadoBalance;
		List<String> certificadoTipo = new List<String>();
		List<String> certificadoNumero = new List<String>();
		List<String> certificadoFecha = new List<String>();
		List<String> certificadoMonto = new List<String>();
		List<String> certificadoBalance = new List<String>();
		List<String> certificadoTasa = new List<String>();
		List<String> certificadoPignorado = new List<String>();
		for (FinServ__FinancialAccount__c cuenta : certificados) {
			Decimal montoApertura = primerDecimal(
				new List<Decimal>{ cuenta.FinServ__LoanAmount__c, decimalOpcional(cuenta, 'ASE_Monto_aprobado__c') }
			);
			Decimal balance = primerDecimal(
				new List<Decimal>{ cuenta.FinServ__Balance__c, decimalOpcional(cuenta, 'ASE_Balance_total__c') }
			);
			certificadoTipo.add(descripcionCuenta(cuenta));
			certificadoNumero.add(numeroCuenta(cuenta));
			certificadoFecha.add(formatearFecha(cuenta.FinServ__OpenDate__c));
			certificadoMonto.add(formatearDinero(montoApertura));
			certificadoBalance.add(formatearDinero(balance));
			certificadoTasa.add(formatearPorcentaje(cuenta.FinServ__InterestRate__c));
			certificadoPignorado.add(texto(cuenta.FinServ__LienHolder__c));
			totalCertificadoApertura = acumular(totalCertificadoApertura, montoApertura);
			totalCertificadoBalance = acumular(totalCertificadoBalance, balance);
		}
		resultado.put('certificadosTipoProducto', unirFilas(certificadoTipo));
		resultado.put('certificadosNumero', unirFilas(certificadoNumero));
		resultado.put('certificadosFechaApertura', unirFilas(certificadoFecha));
		resultado.put('certificadosMontoApertura', unirFilas(certificadoMonto));
		resultado.put('certificadosBalanceActual', unirFilas(certificadoBalance));
		resultado.put('certificadosTasaPasiva', unirFilas(certificadoTasa));
		resultado.put('certificadosPignorado', unirFilas(certificadoPignorado));
		resultado.put('certificadosTotalMontoApertura', formatearDinero(totalCertificadoApertura));
		resultado.put('certificadosTotalBalance', formatearDinero(totalCertificadoBalance));

		Decimal totalBalancePromedio;
		Decimal totalDepositosPromedio;
		List<String> cuentaTipo = new List<String>();
		List<String> cuentaNumero = new List<String>();
		List<String> cuentaFecha = new List<String>();
		List<String> cuentaEntidad = new List<String>();
		List<String> cuentaMoneda = new List<String>();
		List<String> cuentaBalance = new List<String>();
		List<String> cuentaDepositos = new List<String>();
		List<String> cuentaPeriodo = new List<String>();
		for (FinServ__FinancialAccount__c cuenta : cuentasDeposito) {
			Decimal balancePromedio = primerDecimal(new List<Decimal>{ cuenta.FinServ__AverageBalance__c, cuenta.FinServ__Balance__c });
			Decimal depositosPromedio = cuenta.FinServ__IncomingVolume__c;
			cuentaTipo.add(descripcionCuenta(cuenta));
			cuentaNumero.add(numeroCuenta(cuenta));
			cuentaFecha.add(formatearFecha(cuenta.FinServ__OpenDate__c));
			cuentaEntidad.add(primerTexto(new List<String>{ cuenta.FinServ__ServiceProvider__c, 'Banco Vimenca' }));
			cuentaMoneda.add(primerTexto(new List<String>{ cuenta.FIN_Moneda__c, textoOpcional(cuenta, 'ASE_Moneda__c') }));
			cuentaBalance.add(formatearDinero(balancePromedio));
			cuentaDepositos.add(formatearDinero(depositosPromedio));
			cuentaPeriodo.add('');
			totalBalancePromedio = acumular(totalBalancePromedio, balancePromedio);
			totalDepositosPromedio = acumular(totalDepositosPromedio, depositosPromedio);
		}
		resultado.put('cuentasTipoProducto', unirFilas(cuentaTipo));
		resultado.put('cuentasNumero', unirFilas(cuentaNumero));
		resultado.put('cuentasFechaApertura', unirFilas(cuentaFecha));
		resultado.put('cuentasEntidad', unirFilas(cuentaEntidad));
		resultado.put('cuentasMoneda', unirFilas(cuentaMoneda));
		resultado.put('cuentasBalancePromedio', unirFilas(cuentaBalance));
		resultado.put('cuentasDepositosPromedio', unirFilas(cuentaDepositos));
		resultado.put('cuentasPeriodo', unirFilas(cuentaPeriodo));
		resultado.put('cuentasTotalBalancePromedio', formatearDinero(totalBalancePromedio));
		resultado.put('cuentasTotalDepositosPromedio', formatearDinero(totalDepositosPromedio));

		Decimal totalBalanceCredito;
		Decimal totalAutorizadoCredito;
		List<String> creditoTipo = new List<String>();
		List<String> creditoBalance = new List<String>();
		List<String> creditoAutorizado = new List<String>();
		List<String> creditoScore = new List<String>();
		List<String> creditoGarantia = new List<String>();
		for (FinServ__FinancialAccount__c cuenta : productosCredito) {
			Decimal balance = primerDecimal(
				new List<Decimal>{
					cuenta.FinServ__PrincipalBalance__c,
					cuenta.FinServ__Balance__c,
					decimalOpcional(cuenta, 'ASE_Balance_total__c')
				}
			);
			Decimal autorizado = primerDecimal(
				new List<Decimal>{
					cuenta.FinServ__TotalCreditLimit__c,
					cuenta.FinServ__LoanAmount__c,
					decimalOpcional(cuenta, 'ASE_Monto_aprobado__c')
				}
			);
			creditoTipo.add(descripcionCuenta(cuenta));
			creditoBalance.add(formatearDinero(balance));
			creditoAutorizado.add(formatearDinero(autorizado));
			creditoScore.add('');
			creditoGarantia.add(texto(cuenta.FinServ__CollateralDesc__c));
			totalBalanceCredito = acumular(totalBalanceCredito, balance);
			totalAutorizadoCredito = acumular(totalAutorizadoCredito, autorizado);
		}
		resultado.put('productosBvTipoCredito', unirFilas(creditoTipo));
		resultado.put('productosBvBalanceActual', unirFilas(creditoBalance));
		resultado.put('productosBvMontoAutorizado', unirFilas(creditoAutorizado));
		resultado.put('productosBvScore', unirFilas(creditoScore));
		resultado.put('productosBvTipoGarantia', unirFilas(creditoGarantia));
		resultado.put('productosBvTotalBalance', formatearDinero(totalBalanceCredito));
		resultado.put('productosBvTotalAutorizado', formatearDinero(totalAutorizadoCredito));

		resultado.put('disponibilidadBalancePromedio', formatearDinero(totalBalancePromedio));
		resultado.put('disponibilidadFlujoPromedio', formatearDinero(totalDepositosPromedio));
	}

	private static void cargarCreditosExternos(
		Map<String, String> resultado,
		List<FSC_Facilidad_Otra_Institucion__c> facilidades
	) {
		Decimal totalDeuda;
		List<String> tipos = new List<String>();
		List<String> bancos = new List<String>();
		List<String> garantias = new List<String>();
		List<String> propositos = new List<String>();
		List<String> monedas = new List<String>();
		List<String> comportamientos = new List<String>();
		List<String> deudas = new List<String>();
		for (FSC_Facilidad_Otra_Institucion__c facilidad : facilidades) {
			tipos.add(primerTexto(new List<String>{ facilidad.FSC_TipoFacilidad__c, facilidad.FSC_Facilidad__c }));
			bancos.add(texto(facilidad.FSC_EntidadFinanciera__c));
			garantias.add('');
			propositos.add(texto(facilidad.FSC_DescripcionFacilidad__c));
			monedas.add(texto(facilidad.FSC_Moneda__c));
			comportamientos.add('');
			deudas.add(formatearDinero(facilidad.FSC_Balance__c));
			totalDeuda = acumular(totalDeuda, facilidad.FSC_Balance__c);
		}
		resultado.put('creditosOtrosTipoCredito', unirFilas(tipos));
		resultado.put('creditosOtrosBanco', unirFilas(bancos));
		resultado.put('creditosOtrosTipoGarantia', unirFilas(garantias));
		resultado.put('creditosOtrosProposito', unirFilas(propositos));
		resultado.put('creditosOtrosMoneda', unirFilas(monedas));
		resultado.put('creditosOtrosComportamiento', unirFilas(comportamientos));
		resultado.put('creditosOtrosDeudaActual', unirFilas(deudas));
		resultado.put('creditosOtrosTotalDeuda', formatearDinero(totalDeuda));
	}

	private static void cargarCompromisos(
		Map<String, String> resultado,
		List<LoanApplicationLiability> compromisos,
		ResidentialLoanApplication solicitud
	) {
		Decimal totalBalance;
		Decimal totalCuota;
		Decimal balanceASaldar;
		Decimal cuotaASaldar;
		for (LoanApplicationLiability compromiso : compromisos) {
			Decimal cuota = compromiso.MonthlyPaymentAmount;
			if (
				cuota == null &&
				esTarjeta(primerTexto(new List<String>{ compromiso.LoanType, compromiso.AccountType, compromiso.LiabilityClass })) &&
				compromiso.UnpaidBalanceAmount != null
			) {
				cuota = compromiso.UnpaidBalanceAmount * PORCENTAJE_PAGO_MINIMO_TARJETA;
			}
			totalBalance = acumular(totalBalance, compromiso.UnpaidBalanceAmount);
			totalCuota = acumular(totalCuota, cuota);
			if (compromiso.ShouldBePaidInFull == true) {
				balanceASaldar = acumular(balanceASaldar, compromiso.UnpaidBalanceAmount);
				cuotaASaldar = acumular(cuotaASaldar, cuota);
			}
		}
		resultado.put('compromisosTipo', 'Créditos Actuales\nNueva Facilidad\nA Saldar');
		resultado.put(
			'compromisosBalances',
			unirFilas(
				new List<String>{
					formatearDinero(totalBalance),
					formatearDinero(solicitud.FSC_Monto__c),
					formatearDinero(balanceASaldar == null ? null : -balanceASaldar)
				}
			)
		);
		resultado.put(
			'compromisosCuotas',
			unirFilas(
				new List<String>{
					formatearDinero(totalCuota),
					formatearDinero(solicitud.FSC_Monto_De_La_Cuota__c),
					formatearDinero(cuotaASaldar == null ? null : -cuotaASaldar)
				}
			)
		);
		Decimal totalBalanceFinal = sumar(new List<Decimal>{ totalBalance, solicitud.FSC_Monto__c, balanceASaldar == null ? null : -balanceASaldar });
		Decimal totalCuotasFinal = sumar(
			new List<Decimal>{ totalCuota, solicitud.FSC_Monto_De_La_Cuota__c, cuotaASaldar == null ? null : -cuotaASaldar }
		);
		resultado.put('compromisosTotalBalance', formatearDinero(totalBalanceFinal));
		resultado.put('compromisosTotalCuotas', formatearDinero(totalCuotasFinal));

		Decimal balancePromedio = decimalDesdeFormato(resultado.get('disponibilidadBalancePromedio'));
		Decimal flujoPromedio = decimalDesdeFormato(resultado.get('disponibilidadFlujoPromedio'));
		resultado.put('disponibilidadPorcentajeBalance', formatearRelacion(totalCuotasFinal, balancePromedio));
		resultado.put('disponibilidadPorcentajeFlujo', formatearRelacion(totalCuotasFinal, flujoPromedio));
	}

	private static Map<String, String> crearDatosVacios() {
		Map<String, String> resultado = new Map<String, String>();
		for (String clave : new List<String>{
			'numeroSolicitud', 'fechaInforme', 'unidadSucursal', 'ejecutivo', 'tasaCambioUsd', 'tasaCambioEuro',
			'solicitante', 'cedula', 'direccionResidencial', 'codigoAbanks', 'direccionComercial',
			'sectorEconomico', 'actividadComercial', 'clasificacionRiesgoBv', 'grupoRiesgo', 'tipoDeudor',
			'clasificacionRiesgoSib', 'scoreBuro', 'deudaSistemaFinanciero', 'exposicionConsolidadaBv',
			'tipoTramitacion', 'tipoGarantia', 'admisibilidad', 'tipoCredito', 'valorGarantia', 'cobertura',
			'montoSolicitado', 'fechaTasacion', 'tipoBienGarantia', 'plazoMeses', 'usoFondos', 'tasaInteres',
			'cuotaEstimada', 'descripcionGarantia', 'facilidadesTipoCredito', 'facilidadesMonto', 'facilidadesPlazo',
			'facilidadesTasa', 'facilidadesCuota', 'facilidadesUsoFondos', 'destinoTaxonomiaVerde',
			'codigoActividadTaxonomia', 'actividadTaxonomiaVerde', 'decision', 'instanciaDecision', 'fechaDecision',
			'realizadoPor', 'revisadoPor', 'certificadosTipoProducto', 'certificadosNumero', 'certificadosFechaApertura',
			'certificadosMontoApertura', 'certificadosBalanceActual', 'certificadosTasaPasiva', 'certificadosPignorado',
			'certificadosTotalMontoApertura', 'certificadosTotalBalance', 'cuentasTipoProducto', 'cuentasNumero',
			'cuentasFechaApertura', 'cuentasEntidad', 'cuentasMoneda', 'cuentasBalancePromedio', 'cuentasDepositosPromedio',
			'cuentasPeriodo', 'cuentasTotalBalancePromedio', 'cuentasTotalDepositosPromedio', 'productosBvTipoCredito',
			'productosBvBalanceActual', 'productosBvMontoAutorizado', 'productosBvScore', 'productosBvTipoGarantia',
			'productosBvTotalBalance', 'productosBvTotalAutorizado', 'creditosOtrosTipoCredito', 'creditosOtrosBanco',
			'creditosOtrosTipoGarantia', 'creditosOtrosProposito', 'creditosOtrosMoneda', 'creditosOtrosComportamiento',
			'creditosOtrosDeudaActual', 'creditosOtrosTotalDeuda', 'compromisosTipo', 'compromisosBalances',
			'compromisosCuotas', 'compromisosCreditosActuales', 'compromisosNuevaFacilidad', 'compromisosASaldar',
			'compromisosTotalBalance', 'compromisosTotalCuotas', 'disponibilidadBalancePromedio',
			'disponibilidadFlujoPromedio', 'disponibilidadPorcentajeBalance', 'disponibilidadPorcentajeFlujo',
			'resultadoCapacidad', 'perfilActividadComercial', 'fechaEstadosFinancieros', 'ingresosFinancieros',
			'utilidadNeta', 'activosTotales', 'pasivosTotales', 'patrimonio', 'apalancamiento', 'activosFijos',
			'deudasBancarias', 'inventario', 'cuentasPorCobrar', 'cajaBancos', 'analisisFinanciero',
			'comportamientoHistorico', 'resumenClasificacionSib', 'mitigantes', 'conclusionesRecomendaciones'
		}) {
			resultado.put(clave, '');
		}
		return resultado;
	}

	private static Account seleccionarCuenta(Id cuentaId) {
		if (cuentaId == null) {
			return null;
		}
		List<Account> cuentas = [
			SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingCountry, ACC_NumIdentificacion__c,
				ACC_Tipo_Sector__c, ACC_Categoria_Riesgo_Cliente__c
			FROM Account
			WHERE Id = :cuentaId
			WITH USER_MODE
			LIMIT 1
		];
		return cuentas.isEmpty() ? null : cuentas[0];
	}

	private static List<LoanApplicant> seleccionarParticipantes(Id solicitudId) {
		return [
			SELECT Id, FSC_TipoSolicitante__c, FSC_NumIdentificacion__c, FSC_Nombre__c, FSC_PrimerApellido__c, FSC_SegundoApellido__c
			FROM LoanApplicant
			WHERE LoanApplicationId = :solicitudId
			WITH USER_MODE
			ORDER BY CreatedDate
		];
	}

	private static List<FSC_Garantia__c> seleccionarGarantias(Id solicitudId) {
		return [
			SELECT FSC_Clase_de_Garantia__c, FSC_Tipo_de_Garantia__c, FSC_Descripcion_de_la_Garantia__c,
				FSC_Fecha_Tasacion__c, FSC_Valor_Tasado__c, FSC_Valor_Vehiculo__c, FSC_Valor_Inmueble__c
			FROM FSC_Garantia__c
			WHERE FSC_Residential_Loan_Application__c = :solicitudId
			WITH USER_MODE
			ORDER BY CreatedDate
		];
	}

	private static List<FSC_Facilidades_De_Credito__c> seleccionarFacilidades(Id solicitudId) {
		return [
			SELECT FSC_Tipo_de_Facilidad__c, FSC_Tipo_Facilidad__c, FSC_Facilidad__c, FSC_Monto_Solicitado__c,
				FSC_Plazo_meses__c, FSC_Tasa_Interes__c, FSC_Tasa__c, FSC_Monto_De_La_Cuota__c,
				FSC_Descripcion_Proposito_Facilidad__c, FSC_Deuda_Actual__c, FSC_Limite_Autorizado__c
			FROM FSC_Facilidades_De_Credito__c
			WHERE FSC_Residential_Loan_Application__c = :solicitudId
			WITH USER_MODE
			ORDER BY CreatedDate
		];
	}

	private static List<LoanApplicationLiability> seleccionarCompromisos(Id solicitudId) {
		return [
			SELECT AccountType, LiabilityClass, LoanType, MonthlyPaymentAmount, UnpaidBalanceAmount, ShouldBePaidInFull
			FROM LoanApplicationLiability
			WHERE LoanApplicationId = :solicitudId
			WITH USER_MODE
			ORDER BY CreatedDate
		];
	}

	private static List<FSC_Facilidad_Otra_Institucion__c> seleccionarFacilidadesExternas(List<LoanApplicant> participantes) {
		Set<Id> participantesIds = new Map<Id, LoanApplicant>(participantes).keySet();
		if (participantesIds.isEmpty()) {
			return new List<FSC_Facilidad_Otra_Institucion__c>();
		}
		return [
			SELECT FSC_TipoFacilidad__c, FSC_Facilidad__c, FSC_EntidadFinanciera__c, FSC_DescripcionFacilidad__c,
				FSC_Moneda__c, FSC_Balance__c
			FROM FSC_Facilidad_Otra_Institucion__c
			WHERE FSC_LoanApplicant__c IN :participantesIds
			WITH USER_MODE
			ORDER BY CreatedDate
		];
	}

	private static List<FinServ__FinancialAccount__c> seleccionarCuentasFinancieras(Id cuentaId) {
		if (cuentaId == null) {
			return new List<FinServ__FinancialAccount__c>();
		}
		try {
			List<String> campos = new List<String>{
				'Name',
				'RecordType.Name',
				'FinServ__FinancialAccountNumber__c',
				'FinServ__FinancialAccountType__c',
				'FinServ__Type__c',
				'FinServ__OpenDate__c',
				'FinServ__ServiceProvider__c',
				'FinServ__AverageBalance__c',
				'FinServ__IncomingVolume__c',
				'FinServ__Balance__c',
				'FinServ__InterestRate__c',
				'FinServ__LoanAmount__c',
				'FinServ__PrincipalBalance__c',
				'FinServ__TotalCreditLimit__c',
				'FinServ__CollateralDesc__c',
				'FinServ__LienHolder__c',
				'FIN_Linea_de_producto__c',
				'FIN_Moneda__c',
				'FIN_N_de_cuenta__c'
			};
			Map<String, Schema.SObjectField> camposDisponibles = Schema.SObjectType.FinServ__FinancialAccount__c.fields.getMap();
			for (String campoOpcional : new List<String>{
				'ASE_Linea_de_producto__c',
				'ASE_Moneda__c',
				'ASE_Monto_aprobado__c',
				'ASE_Balance_total__c'
			}) {
				if (camposDisponibles.containsKey(campoOpcional)) {
					campos.add(campoOpcional);
				}
			}
			return Database.query(
				'SELECT ' +
				String.join(campos, ', ') +
				' FROM FinServ__FinancialAccount__c' +
				' WHERE FinServ__PrimaryOwner__c = :cuentaId OR FinServ__JointOwner__c = :cuentaId' +
				' WITH USER_MODE ORDER BY FinServ__OpenDate__c, CreatedDate'
			);
		} catch (Exception error) {
			return new List<FinServ__FinancialAccount__c>();
		}
	}

	private static void aplicarEdicionesGuardadas(Id solicitudId, Map<String, String> base) {
		if (solicitudId == null || base == null) {
			return;
		}
		String ajustesJson = obtenerAjustesVersionActual(solicitudId);
		if (String.isBlank(ajustesJson)) {
			return;
		}
		try {
			Map<String, Object> ajustes = (Map<String, Object>) JSON.deserializeUntyped(ajustesJson);
			for (String clave : ajustes.keySet()) {
				if (base.containsKey(clave)) {
					base.put(clave, ajustes.get(clave) == null ? '' : String.valueOf(ajustes.get(clave)));
				}
			}
		} catch (Exception error) {
			System.debug(LoggingLevel.WARN, 'No se pudieron aplicar los ajustes del informe Pyme: ' + error.getMessage());
		}
	}

	private static String obtenerAjustesVersionActual(Id solicitudId) {
		Id contentDocumentId;
		for (ContentDocumentLink enlace : [
			SELECT ContentDocumentId, ContentDocument.Title
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :solicitudId
			ORDER BY SystemModstamp DESC
		]) {
			if (enlace.ContentDocument.Title != null && enlace.ContentDocument.Title.startsWith(PREFIJO_DOCUMENTO)) {
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
			WHERE ContentDocumentId = :contentDocumentId AND IsLatest = true
			LIMIT 1
		];
		return versiones.isEmpty() ? '' : versiones[0].FSC_DatosEditadosAnalisis__c;
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

	private static String construirPerfil(ResidentialLoanApplication solicitud) {
		List<String> partes = new List<String>();
		partes.add(texto(solicitud.FSC_Descripcion_del_Negocio__c));
		if (!String.isBlank(solicitud.FSC_Tiempo_del_negocio__c)) {
			partes.add('Tiempo del negocio: ' + solicitud.FSC_Tiempo_del_negocio__c);
		} else if (solicitud.FSC_A_os_de_operacion__c != null) {
			partes.add('Años de operación: ' + texto(solicitud.FSC_A_os_de_operacion__c));
		}
		if (!String.isBlank(solicitud.FSC_Situacion_Legal__c)) {
			partes.add('Situación legal: ' + solicitud.FSC_Situacion_Legal__c);
		}
		if (solicitud.FSC_Cantidad_de_empleados__c != null) {
			partes.add('Cantidad de empleados: ' + texto(solicitud.FSC_Cantidad_de_empleados__c));
		}
		if (solicitud.FSC_VentasBrutasAnuales__c != null) {
			partes.add('Ventas brutas anuales: ' + formatearDinero(solicitud.FSC_VentasBrutasAnuales__c));
		}
		return unir(partes, '\n');
	}

	private static String construirFechaEstadosFinancieros(ResidentialLoanApplication solicitud) {
		if (
			solicitud.FSC_DiaEstadoSituacion__c == null ||
			solicitud.FSC_AnoEstadoSituacion__c == null ||
			String.isBlank(solicitud.FSC_MesEstadoSituacion__c)
		) {
			return '';
		}
		Integer mes = resolverMes(solicitud.FSC_MesEstadoSituacion__c);
		if (mes == null) {
			return '';
		}
		try {
			return formatearFecha(
				Date.newInstance(
					solicitud.FSC_AnoEstadoSituacion__c.intValue(),
					mes,
					solicitud.FSC_DiaEstadoSituacion__c.intValue()
				)
			);
		} catch (Exception error) {
			return '';
		}
	}

	private static Integer resolverMes(String mesOriginal) {
		String mes = mesOriginal == null ? '' : mesOriginal.trim().toLowerCase();
		Map<String, Integer> meses = new Map<String, Integer>{
			'enero' => 1,
			'febrero' => 2,
			'marzo' => 3,
			'abril' => 4,
			'mayo' => 5,
			'junio' => 6,
			'julio' => 7,
			'agosto' => 8,
			'septiembre' => 9,
			'octubre' => 10,
			'noviembre' => 11,
			'diciembre' => 12
		};
		if (meses.containsKey(mes)) {
			return meses.get(mes);
		}
		try {
			Integer numeroMes = Integer.valueOf(mes);
			return numeroMes >= 1 && numeroMes <= 12 ? numeroMes : null;
		} catch (Exception error) {
			return null;
		}
	}

	private static String construirResumenSib(ResidentialLoanApplication solicitud) {
		List<String> partes = new List<String>();
		if (!String.isBlank(solicitud.FSC_Clasificacion_de_Riesgo__c)) {
			partes.add('Clasificación de riesgo ' + solicitud.FSC_Clasificacion_de_Riesgo__c + '.');
		}
		if (!String.isBlank(solicitud.FSC_clasificacionSib__c)) {
			partes.add(solicitud.FSC_clasificacionSib__c + '.');
		}
		return unir(partes, ' ');
	}

	private static Date resolverFechaDecision(ResidentialLoanApplication solicitud) {
		if (solicitud.FSC_FechaYHoraAprobacionComite__c != null) {
			return solicitud.FSC_FechaYHoraAprobacionComite__c.date();
		}
		return solicitud.FSC_FechaAprobacion__c;
	}

	private static String primeraFacilidad(List<FSC_Facilidades_De_Credito__c> facilidades) {
		if (facilidades.isEmpty()) {
			return '';
		}
		FSC_Facilidades_De_Credito__c facilidad = facilidades[0];
		return primerTexto(new List<String>{ facilidad.FSC_Tipo_de_Facilidad__c, facilidad.FSC_Tipo_Facilidad__c, facilidad.FSC_Facilidad__c });
	}

	private static Decimal sumarDeudas(
		List<LoanApplicationLiability> compromisos,
		List<FSC_Facilidad_Otra_Institucion__c> facilidadesExternas
	) {
		Decimal total;
		for (LoanApplicationLiability compromiso : compromisos) {
			total = acumular(total, compromiso.UnpaidBalanceAmount);
		}
		if (total == null) {
			for (FSC_Facilidad_Otra_Institucion__c facilidad : facilidadesExternas) {
				total = acumular(total, facilidad.FSC_Balance__c);
			}
		}
		return total;
	}

	private static Decimal calcularExposicionBanco(
		Decimal montoSolicitado,
		List<FSC_Facilidades_De_Credito__c> facilidades,
		List<FinServ__FinancialAccount__c> cuentas
	) {
		Decimal total = montoSolicitado;
		for (FSC_Facilidades_De_Credito__c facilidad : facilidades) {
			total = acumular(total, facilidad.FSC_Deuda_Actual__c);
		}
		for (FinServ__FinancialAccount__c cuenta : cuentas) {
			String tipo = descripcionCuenta(cuenta).toLowerCase();
			if (tipo.contains('prestamo') || tipo.contains('credito') || tipo.contains('tarjeta') || tipo.contains('loan') || tipo.contains('card')) {
				total = acumular(total, primerDecimal(new List<Decimal>{ cuenta.FinServ__PrincipalBalance__c, cuenta.FinServ__Balance__c }));
			}
		}
		return total;
	}

	private static String descripcionCuenta(FinServ__FinancialAccount__c cuenta) {
		return primerTexto(
			new List<String>{
				cuenta.FinServ__FinancialAccountType__c,
				cuenta.FIN_Linea_de_producto__c,
				textoOpcional(cuenta, 'ASE_Linea_de_producto__c'),
				cuenta.FinServ__Type__c,
				cuenta.RecordType?.Name,
				cuenta.Name
			}
		);
	}

	private static Decimal decimalOpcional(SObject registro, String nombreCampo) {
		Object valor = valorOpcional(registro, nombreCampo);
		return valor instanceof Decimal ? (Decimal) valor : null;
	}

	private static String textoOpcional(SObject registro, String nombreCampo) {
		Object valor = valorOpcional(registro, nombreCampo);
		return valor == null ? '' : String.valueOf(valor);
	}

	private static Object valorOpcional(SObject registro, String nombreCampo) {
		if (registro == null || !registro.getSObjectType().getDescribe().fields.getMap().containsKey(nombreCampo)) {
			return null;
		}
		return registro.get(nombreCampo);
	}

	private static String numeroCuenta(FinServ__FinancialAccount__c cuenta) {
		return primerTexto(new List<String>{ cuenta.FinServ__FinancialAccountNumber__c, cuenta.FIN_N_de_cuenta__c, cuenta.Name });
	}

	private static String etiquetaPicklist(Schema.SObjectField campo, String valor) {
		if (String.isBlank(valor)) {
			return '';
		}
		for (Schema.PicklistEntry opcion : campo.getDescribe().getPicklistValues()) {
			if (opcion.getValue() == valor) {
				return opcion.getLabel();
			}
		}
		return valor;
	}

	private static Map<String, Decimal> seleccionarTasasCambio() {
		Map<String, Decimal> resultado = new Map<String, Decimal>();
		try {
			List<SObject> monedas = Database.query(
				'SELECT IsoCode, ConversionRate FROM CurrencyType WHERE IsActive = true AND IsoCode IN (\'DOP\', \'USD\', \'EUR\')'
			);
			Map<String, Decimal> tasas = new Map<String, Decimal>();
			for (SObject moneda : monedas) {
				tasas.put(String.valueOf(moneda.get('IsoCode')), (Decimal) moneda.get('ConversionRate'));
			}
			Decimal tasaDop = tasas.get('DOP');
			if (tasaDop != null && tasaDop != 0) {
				for (String codigo : new List<String>{ 'USD', 'EUR' }) {
					if (tasas.get(codigo) != null) {
						resultado.put(codigo, tasas.get(codigo) / tasaDop);
					}
				}
			}
		} catch (Exception error) {
			return resultado;
		}
		return resultado;
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

	private static Boolean esTarjeta(String tipo) {
		String normalizado = texto(tipo).toLowerCase();
		return normalizado.contains('tarjeta') || normalizado.contains('card');
	}

	private static Decimal acumular(Decimal acumulado, Decimal valor) {
		return valor == null ? acumulado : (acumulado ?? 0) + valor;
	}

	private static Decimal sumar(List<Decimal> valores) {
		Decimal resultado;
		for (Decimal valor : valores) {
			resultado = acumular(resultado, valor);
		}
		return resultado;
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

	private static String unirFilas(List<String> valores) {
		return valores.isEmpty() ? '' : String.join(valores, '\n');
	}

	private static String texto(Object valor) {
		return valor == null ? '' : String.valueOf(valor);
	}

	private static String formatearDinero(Decimal valor) {
		return valor == null ? '' : 'RD$ ' + valor.setScale(2).format();
	}

	private static String formatearNumero(Decimal valor) {
		return valor == null ? '' : String.valueOf(valor.setScale(4));
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

	private static String formatearFecha(Date valor) {
		return valor == null
			? ''
			: String.valueOf(valor.day()).leftPad(2, '0') + '/' + String.valueOf(valor.month()).leftPad(2, '0') + '/' + valor.year();
	}

	private static Decimal decimalDesdeFormato(String valor) {
		if (String.isBlank(valor)) {
			return null;
		}
		String limpio = valor.replaceAll('[^0-9,\\.\\-]', '');
		Integer ultimaComa = limpio.lastIndexOf(',');
		Integer ultimoPunto = limpio.lastIndexOf('.');
		if (ultimaComa > ultimoPunto) {
			limpio = limpio.replace('.', '').replace(',', '.');
		} else {
			limpio = limpio.replace(',', '');
		}
		try {
			return Decimal.valueOf(limpio);
		} catch (Exception error) {
			return null;
		}
	}
}