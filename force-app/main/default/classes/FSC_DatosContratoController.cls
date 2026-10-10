public without sharing class FSC_DatosContratoController {
	public class OpcionEntrada {
		@AuraEnabled
		public String label { get; set; }
		@AuraEnabled
		public String value { get; set; }
		// Valor del campo controlador para el que aplica la opcion (ej. la marca de un modelo).
		@AuraEnabled
		public String controlador { get; set; }

		public OpcionEntrada(String label, String value) {
			this.label = label;
			this.value = value;
		}
	}

	public class CampoEntrada {
		@AuraEnabled
		public String clave { get; set; }
		@AuraEnabled
		public String etiqueta { get; set; }
		@AuraEnabled
		public String valor { get; set; }
		@AuraEnabled
		public String tipo { get; set; }
		@AuraEnabled
		public Boolean requerido { get; set; }
		@AuraEnabled
		public Boolean esTexto { get; set; }
		@AuraEnabled
		public Boolean esAreaTexto { get; set; }
		@AuraEnabled
		public Boolean esFecha { get; set; }
		@AuraEnabled
		public Boolean esNumero { get; set; }
		@AuraEnabled
		public Boolean esLista { get; set; }
		@AuraEnabled
		public String paso { get; set; }
		@AuraEnabled
		public Decimal minimo { get; set; }
		@AuraEnabled
		public String mostrarParaTipoVendedor { get; set; }
		@AuraEnabled
		public String mostrarParaPropietarioGarantia { get; set; }
		@AuraEnabled
		public String mostrarParaConyuge { get; set; }
		@AuraEnabled
		public List<OpcionEntrada> opciones { get; set; }

		public CampoEntrada(String key, String label, String value, String type) {
			clave = key;
			etiqueta = label;
			valor = value;
			tipo = type;
			requerido = true;
			esTexto = type == 'text';
			esAreaTexto = type == 'textarea';
			esFecha = type == 'date';
			esNumero = type == 'number';
			esLista = type == 'picklist';
			paso = 'any';
			opciones = new List<OpcionEntrada>();
		}
	}

	public class SeccionEntrada {
		@AuraEnabled
		public String titulo { get; set; }
		@AuraEnabled
		public List<CampoEntrada> campos { get; set; }

		public SeccionEntrada(String title) {
			titulo = title;
			campos = new List<CampoEntrada>();
		}
	}

	public class ContextoGeneracion {
		@AuraEnabled
		public Boolean aplicaContrato { get; set; }
		@AuraEnabled
		public Boolean contratoDisponible { get; set; }
		@AuraEnabled
		public Boolean esPyme { get; set; }
		@AuraEnabled
		public Boolean esVehiculo { get; set; }
		@AuraEnabled
		public Boolean esHipotecario { get; set; }
		@AuraEnabled
		public Boolean generarContratoConPagareNotarial { get; set; }
		@AuraEnabled
		public Boolean requiereActoGarantia { get; set; }
		@AuraEnabled
		public Boolean actoGarantiaGenerado { get; set; }
		@AuraEnabled
		public Boolean requierePignoracion { get; set; }
		@AuraEnabled
		public Boolean pignoracionGenerada { get; set; }
		@AuraEnabled
		public Boolean esPersonaFisica { get; set; }
		@AuraEnabled
		public String tipoContrato { get; set; }
		@AuraEnabled
		public String nombreContrato { get; set; }
		@AuraEnabled
		public Boolean requierePagareNotarial { get; set; }
		@AuraEnabled
		public String codigoTipoPagare { get; set; }
		@AuraEnabled
		public String tipoPagare { get; set; }
		@AuraEnabled
		public String actoNumeroPagare { get; set; }
		@AuraEnabled
		public String numeroFolioPagare { get; set; }
		@AuraEnabled
		public String numeroPrestamoPagare { get; set; }
		@AuraEnabled
		public List<SeccionEntrada> seccionesContrato { get; set; }
		@AuraEnabled
		public List<SeccionEntrada> seccionesPagare { get; set; }
		@AuraEnabled
		public List<SeccionEntrada> seccionesActoGarantia { get; set; }
		@AuraEnabled
		public List<SeccionEntrada> seccionesPignoracion { get; set; }
		@AuraEnabled
		public List<String> erroresConfiguracion { get; set; }
		@AuraEnabled
		public List<String> erroresConfiguracionActo { get; set; }

		public ContextoGeneracion() {
			seccionesContrato = new List<SeccionEntrada>();
			seccionesPagare = new List<SeccionEntrada>();
			seccionesActoGarantia = new List<SeccionEntrada>();
			seccionesPignoracion = new List<SeccionEntrada>();
			erroresConfiguracion = new List<String>();
			erroresConfiguracionActo = new List<String>();
		}
	}

	@AuraEnabled(cacheable=true)
	public static ContextoGeneracion getContextoGeneracion(Id residentialLoanApplicationId) {
		FSC_RLAContractTemplateResolver.ContractResolution resolution = FSC_RLAContractTemplateResolver.resolve(residentialLoanApplicationId);

		ResidentialLoanApplication rla = queryRla(residentialLoanApplicationId);
		ContextoGeneracion context = new ContextoGeneracion();
		context.contratoDisponible = resolution.contratoDisponible;
		context.tipoContrato = resolution.templateCode;
		context.nombreContrato = resolution.nombreContrato;
		Boolean esPyme = rla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_PYME';
		Boolean esConsumo = rla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Consumo';
		Boolean esVehiculo = rla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Vehiculo';
		Boolean esHipotecario = rla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Hipotecario';
		context.esPyme = esPyme;
		context.esVehiculo = esVehiculo;
		context.esHipotecario = esHipotecario;
		FSC_ConsumoDocumentoResolver.ResolucionDocumento consumption;
		FSC_VehiculoDocumentoResolver.ResolucionDocumento vehicle;
		FSC_HipotecarioDocumentoResolver.ResolucionDocumento mortgage;
		if (esConsumo) {
			consumption = FSC_ConsumoDocumentoResolver.resolve(residentialLoanApplicationId);
			context.codigoTipoPagare = consumption.codigoPagare;
			context.tipoPagare = consumption.nombrePagare;
		} else if (esVehiculo) {
			vehicle = FSC_VehiculoDocumentoResolver.resolve(residentialLoanApplicationId);
			context.codigoTipoPagare = vehicle.codigoPagare;
			context.tipoPagare = vehicle.nombrePagare;
		} else if (esHipotecario) {
			mortgage = FSC_HipotecarioDocumentoResolver.resolve(residentialLoanApplicationId);
			context.codigoTipoPagare = mortgage.codigoPagare;
			context.tipoPagare = mortgage.nombrePagare;
		} else {
			context.codigoTipoPagare = esPyme && rla.FSC_RequiereContratoPagareNotarial__c != true
				? FSC_ConsumoDocumentoResolver.PAGARE_COMPLEMENTARIO
				: FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL;
			context.tipoPagare = context.codigoTipoPagare == FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL
				? 'Pagaré notarial'
				: 'Pagaré complementario';
		}
		context.requierePagareNotarial = context.codigoTipoPagare == FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL;
		context.generarContratoConPagareNotarial =
			(esPyme || esConsumo || esVehiculo || esHipotecario) && rla.FSC_Excepcion_Contrato_Notarial__c == true;
		context.aplicaContrato =
			resolution.aplicaContrato &&
			(esVehiculo ||
			esHipotecario ||
			!(esPyme || esConsumo) ||
			!context.requierePagareNotarial ||
			context.generarContratoConPagareNotarial);
		context.requiereActoGarantia = esPyme && rla.FSC_Requiere_Acto_Garantia__c == true;
		context.actoGarantiaGenerado = rla.FSC_Acto_Garantia_Generado__c == true;
		context.requierePignoracion =
			esConsumo &&
			context.codigoTipoPagare == FSC_ConsumoDocumentoResolver.PAGARE_COMPLEMENTARIO &&
			consumption.tipoGarantia == FSC_ConsumoDocumentoResolver.GARANTIA_CD;
		context.pignoracionGenerada = rla.FSC_Pignoracion_Generada__c == true;
		context.actoNumeroPagare = rla.FSC_ActoNumeroPagare__c;
		context.numeroFolioPagare = rla.FSC_NumeroFolioPagare__c == null ? '' : String.valueOf(rla.FSC_NumeroFolioPagare__c.setScale(0));
		context.numeroPrestamoPagare = rla.FSC_Numero_Prestamo_Pagare__c;

		Account account = rla.Account;
		context.esPersonaFisica = account.IsPersonAccount;
		if (
			context.codigoTipoPagare == FSC_ConsumoDocumentoResolver.PAGARE_SIMPLE ||
			context.codigoTipoPagare == FSC_ConsumoDocumentoResolver.PAGARE_SIMPLE_FIADOR
		) {
			buildPagareClientSection(context, rla, account);
			if (context.codigoTipoPagare == FSC_ConsumoDocumentoResolver.PAGARE_SIMPLE_FIADOR) {
				buildGuarantorSection(context, rla, residentialLoanApplicationId, true);
			}
		}

		if (context.requiereActoGarantia && !context.actoGarantiaGenerado) {
			buildActoGuaranteeSections(context, rla, account, resolution);
		}
		if (context.requierePignoracion && !context.pignoracionGenerada) {
			buildPignoracionSections(context, rla, account, consumption);
		}
		if (esVehiculo && vehicle.tieneContratoVehicular) {
			buildVehicleOwnerSection(context, vehicle.propietarioGarantia);
		}
		if (esHipotecario && mortgage.tieneGarantiaHipotecaria) {
			buildMortgageDecisionSection(context, mortgage, rla);
		}

		if (!resolution.contratoDisponible) {
			if (context.requiereActoGarantia && !context.actoGarantiaGenerado) {
				context.erroresConfiguracionActo.addAll(FSC_ContratoParticipanteService.getParticipantes('SOLIDARIO').errores);
				validateFinancialData(context.erroresConfiguracionActo, rla);
			}
			if (context.requierePignoracion && !context.pignoracionGenerada) {
				validatePignoracionFinancialData(context.erroresConfiguracion, rla);
			}
			return context;
		}

		buildClientSections(context, rla, account, resolution.templateCode);
		buildContractInterveners(context, rla, esVehiculo, esHipotecario);

		if (esHipotecario) {
			buildMortgagePurchaseSections(context, rla, mortgage);
		}

		if (resolution.templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_SOLIDARIA) {
			buildGuarantorSection(context, rla, residentialLoanApplicationId, false);
		} else if (resolution.templateCode != FSC_RLAContractTemplateResolver.TEMPLATE_SOLA_FIRMA) {
			FSC_Seguro__c insurance = queryInsurance(residentialLoanApplicationId, resolution.templateCode);
			if (resolution.loanApplicationAssetId != null) {
				LoanApplicationAsset guarantee = queryLoanApplicationAsset(resolution.loanApplicationAssetId);
				if (isMortgageTemplate(resolution.templateCode)) {
					buildMortgageSections(context, guarantee, insurance);
				} else if (resolution.templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION) {
					buildDepositCertificateSection(context, guarantee, account.Name, rla.FSC_Moneda__c);
				} else if (isVehicleTemplate(resolution.templateCode)) {
					buildVehicleSections(context, guarantee, insurance);
				}
			} else if (resolution.garantiaId != null) {
				FSC_Garantia__c guarantee = queryGuarantee(resolution.garantiaId);
				if (isMortgageTemplate(resolution.templateCode)) {
					buildMortgageSections(context, guarantee, insurance);
				} else if (resolution.templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION) {
					buildDepositCertificateSection(context, guarantee, account.Name);
				} else if (isVehicleTemplate(resolution.templateCode)) {
					buildVehicleSections(context, guarantee, insurance);
				}
			}
		}

		if (
			resolution.templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_CONSUMO_GARANTIA_HIPOTECARIA ||
			resolution.templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_CONSUMO_GARANTIA_MOBILIARIA
		) {
			addConsumptionInsurancePremium(context, queryInsurance(residentialLoanApplicationId, resolution.templateCode));
		}

		if (esHipotecario) {
			buildMortgageExpenseSection(context, rla);
		}

		if (context.aplicaContrato) {
			context.erroresConfiguracion.addAll(FSC_ContratoParticipanteService.getParticipantes(resolution.tipoContrato).errores);
		}
		if (context.requiereActoGarantia && !context.actoGarantiaGenerado) {
			context.erroresConfiguracionActo.addAll(FSC_ContratoParticipanteService.getParticipantes('SOLIDARIO').errores);
		}
		if (context.aplicaContrato) {
			validateFinancialData(context.erroresConfiguracion, rla);
		}
		if (context.requiereActoGarantia && !context.actoGarantiaGenerado) {
			validateFinancialData(context.erroresConfiguracionActo, rla);
		}
		return context;
	}

	@AuraEnabled
	public static void guardarDatosYPrepararGeneracion(
		Id residentialLoanApplicationId,
		String actoNumeroPagare,
		String numeroFolioPagare,
		String numeroPrestamoPagare,
		Boolean generarContratoConPagareNotarial,
		Boolean generarSoloActoGarantia,
		String datosContratoJson
	) {
		FSC_DocumentacionContratosService.validarAccesoResponsable(residentialLoanApplicationId);
		ResidentialLoanApplication pagareRla = queryRla(residentialLoanApplicationId);
		if (generarSoloActoGarantia != true) {
			FSC_DocumentacionContratosService.validarGeneracion(residentialLoanApplicationId);
			Boolean tipoPagareSeleccionadoEnModal =
				pagareRla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Vehiculo' ||
				pagareRla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Hipotecario';
			String tipoPagare = tipoPagareSeleccionadoEnModal
				? (generarContratoConPagareNotarial == true
						? FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL
						: FSC_ConsumoDocumentoResolver.PAGARE_COMPLEMENTARIO)
				: resolvePagareType(pagareRla);
			if (tipoPagare != FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL) {
				FSC_RlaAccionesController.guardarDatosPagareComplementario(residentialLoanApplicationId, numeroPrestamoPagare);
			} else {
				FSC_RlaAccionesController.guardarDatosPagare(residentialLoanApplicationId, actoNumeroPagare, numeroFolioPagare);
			}
		}

		Map<String, Object> values = String.isBlank(datosContratoJson)
			? new Map<String, Object>()
			: (Map<String, Object>) JSON.deserializeUntyped(datosContratoJson);
		FSC_RLAContractTemplateResolver.ContractResolution resolution = FSC_RLAContractTemplateResolver.resolve(residentialLoanApplicationId);
		if (!resolution.aplicaContrato && values.isEmpty())
			return;

		ResidentialLoanApplication currentRla = queryRla(residentialLoanApplicationId);
		Decimal gastosLegales = decimalValueOrCurrent(values, 'gastosLegalesContratos', currentRla.FSC_GastosLegalesContratos__c);
		Decimal gastosGarantiaHip2 = decimalValueOrCurrent(values, 'gastosGarantiaHip2', currentRla.FSC_GastosGarantiasHip2__c);
		Decimal gastosGarantiaHip3 = decimalValueOrCurrent(values, 'gastosGarantiaHip3', currentRla.FSC_GastosGarantiasHip3__c);
		validateMortgageExpenses(currentRla, gastosLegales, gastosGarantiaHip2, gastosGarantiaHip3);
		ResidentialLoanApplication rlaUpdate = new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_RNC_Cliente_Contrato__c = valueOrCurrent(values, 'clienteRnc', currentRla.FSC_RNC_Cliente_Contrato__c),
			FSC_Registro_Mercantil_Contrato__c = valueOrCurrent(values, 'clienteRegistroMercantil', currentRla.FSC_Registro_Mercantil_Contrato__c),
			FSC_Identificacion_Cliente_Contrato__c = valueOrCurrent(
				values,
				'clienteIdentificacion',
				currentRla.FSC_Identificacion_Cliente_Contrato__c
			),
			FSC_Nacionalidad_Cliente_Contrato__c = valueOrCurrent(values, 'clienteNacionalidad', currentRla.FSC_Nacionalidad_Cliente_Contrato__c),
			FSC_Estado_Civil_Cliente_Contrato__c = valueOrCurrent(values, 'clienteEstadoCivil', currentRla.FSC_Estado_Civil_Cliente_Contrato__c),
			FSC_Domicilio_Cliente_Contrato__c = valueOrCurrent(values, 'clienteDomicilio', currentRla.FSC_Domicilio_Cliente_Contrato__c),
			FSC_Nombre_Representante_Cliente__c = valueOrCurrent(values, 'representanteNombre', currentRla.FSC_Nombre_Representante_Cliente__c),
			FSC_Cargo_Representante_Cliente__c = valueOrCurrent(values, 'representanteCargo', currentRla.FSC_Cargo_Representante_Cliente__c),
			FSC_Nacionalidad_Representante__c = valueOrCurrent(values, 'representanteNacionalidad', currentRla.FSC_Nacionalidad_Representante__c),
			FSC_Estado_Civil_Representante__c = valueOrCurrent(values, 'representanteEstadoCivil', currentRla.FSC_Estado_Civil_Representante__c),
			FSC_Identificacion_Representante__c = valueOrCurrent(
				values,
				'representanteIdentificacion',
				currentRla.FSC_Identificacion_Representante__c
			),
			FSC_Domicilio_Representante__c = valueOrCurrent(values, 'representanteDomicilio', currentRla.FSC_Domicilio_Representante__c),
			FSC_Resolucion_Autorizacion__c = valueOrCurrent(values, 'autorizacionResolucion', currentRla.FSC_Resolucion_Autorizacion__c),
			FSC_Fecha_Acta_Autorizacion__c = dateValueOrCurrent(values, 'autorizacionFecha', currentRla.FSC_Fecha_Acta_Autorizacion__c),
			FSC_Personas_Autorizadas__c = valueOrCurrent(values, 'autorizacionPersonas', currentRla.FSC_Personas_Autorizadas__c),
			FSC_Calidad_Autorizados__c = valueOrCurrent(values, 'autorizacionCalidad', currentRla.FSC_Calidad_Autorizados__c),
			FSC_Nombre_Garante_Contrato__c = valueOrCurrent(values, 'garanteNombre', currentRla.FSC_Nombre_Garante_Contrato__c),
			FSC_Identificacion_Garante_Contrato__c = valueOrCurrent(
				values,
				'garanteIdentificacion',
				currentRla.FSC_Identificacion_Garante_Contrato__c
			),
			FSC_Nacionalidad_Garante_Contrato__c = valueOrCurrent(values, 'garanteNacionalidad', currentRla.FSC_Nacionalidad_Garante_Contrato__c),
			FSC_Estado_Civil_Garante_Contrato__c = valueOrCurrent(values, 'garanteEstadoCivil', currentRla.FSC_Estado_Civil_Garante_Contrato__c),
			FSC_Domicilio_Garante_Contrato__c = valueOrCurrent(values, 'garanteDomicilio', currentRla.FSC_Domicilio_Garante_Contrato__c),
			FSC_Excepcion_Contrato_Notarial__c = currentRla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_PYME' ||
				currentRla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Consumo' ||
				currentRla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Vehiculo' ||
				currentRla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Hipotecario'
				? generarContratoConPagareNotarial == true
				: currentRla.FSC_Excepcion_Contrato_Notarial__c,
			FSC_Propietario_Garantia_Vehiculo__c = valueOrCurrent(
				values,
				'vehiculoPropietarioGarantia',
				currentRla.FSC_Propietario_Garantia_Vehiculo__c
			),
			FSC_Propietario_Garantia_Hipotecaria__c = valueOrCurrent(
				values,
				'hipotecarioPropietarioGarantia',
				currentRla.FSC_Propietario_Garantia_Hipotecaria__c
			),
			FSC_Tipo_Vendedor_Hipotecario__c = valueOrCurrent(values, 'hipotecarioTipoVendedor', currentRla.FSC_Tipo_Vendedor_Hipotecario__c),
			FSC_Datos_Intervinientes_Contrato__c = generarSoloActoGarantia != true && resolution.aplicaContrato &&
				(currentRla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Vehiculo' ||
				currentRla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Hipotecario')
				? JSON.serialize(intervenerValues(values))
				: currentRla.FSC_Datos_Intervinientes_Contrato__c,
			FSC_GastosLegalesContratos__c = gastosLegales,
			FSC_GastosGarantiasHip2__c = gastosGarantiaHip2,
			FSC_GastosGarantiasHip3__c = gastosGarantiaHip3,
			FSC_Fecha_Contrato__c = generarSoloActoGarantia == true ? currentRla.FSC_Fecha_Contrato__c : Date.today(),
			FSC_Datos_Contrato_Hipotecario__c = generarSoloActoGarantia != true &&
				currentRla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Hipotecario'
				? JSON.serialize(nonIntervenerValues(values))
				: currentRla.FSC_Datos_Contrato_Hipotecario__c,
			FSC_Documento_Base_Acto_Garantia__c = valueOrCurrent(values, 'actoDocumentoBase', currentRla.FSC_Documento_Base_Acto_Garantia__c),
			FSC_Forma_Pago_Acto_Garantia__c = valueOrCurrent(values, 'actoFormaPago', currentRla.FSC_Forma_Pago_Acto_Garantia__c),
			FSC_Generales_Fiadores_Acto__c = valueOrCurrent(values, 'actoGeneralesFiadores', currentRla.FSC_Generales_Fiadores_Acto__c),
			FSC_Relacion_Propietario_CD__c = valueOrCurrent(values, 'pignoracionRelacionPropietario', currentRla.FSC_Relacion_Propietario_CD__c),
			FSC_Numero_Fisico_CD__c = valueOrCurrent(values, 'pignoracionNumeroFisico', currentRla.FSC_Numero_Fisico_CD__c),
			FSC_Identificacion_Propietario_CD__c = valueOrCurrent(
				values,
				'pignoracionIdentificacionPropietario',
				currentRla.FSC_Identificacion_Propietario_CD__c
			),
			FSC_Lugar_Pignoracion_CD__c = valueOrCurrent(values, 'pignoracionLugar', currentRla.FSC_Lugar_Pignoracion_CD__c),
			FSC_Nombre_Ejecutivo_Pignoracion__c = valueOrCurrent(
				values,
				'pignoracionEjecutivoNombre',
				currentRla.FSC_Nombre_Ejecutivo_Pignoracion__c
			),
			FSC_Cargo_Ejecutivo_Pignoracion__c = valueOrCurrent(values, 'pignoracionEjecutivoCargo', currentRla.FSC_Cargo_Ejecutivo_Pignoracion__c)
		);

		if (currentRla.Account.IsPersonAccount) {
			clearCorporateFields(rlaUpdate);
		}
		update rlaUpdate;

		// La selección del dueño define si existe una plantilla disponible para el contrato.
		resolution = FSC_RLAContractTemplateResolver.resolve(residentialLoanApplicationId);

		if (!resolution.aplicaContrato) {
			if (currentRla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Consumo') {
				FSC_ConsumoDocumentoResolver.ResolucionDocumento consumption = FSC_ConsumoDocumentoResolver.resolve(residentialLoanApplicationId);
				if (
					consumption.codigoPagare == FSC_ConsumoDocumentoResolver.PAGARE_COMPLEMENTARIO &&
					consumption.tipoGarantia == FSC_ConsumoDocumentoResolver.GARANTIA_CD &&
					consumption.garantiaId != null
				) {
					updatePignoracionGuarantee(consumption.garantiaId, values);
				}
			}
			validateSavedContext(residentialLoanApplicationId, generarSoloActoGarantia == true);
			return;
		}

		if (resolution.loanApplicationAssetId != null) {
			updateLoanApplicationAsset(resolution.loanApplicationAssetId, resolution.templateCode, values);
		} else if (resolution.garantiaId != null) {
			updateGuarantee(resolution.garantiaId, resolution.templateCode, values);
		}
		if (isMortgageTemplate(resolution.templateCode) || isVehicleTemplate(resolution.templateCode)) {
			upsertInsurance(residentialLoanApplicationId, resolution.templateCode, values);
		}

		validateSavedContext(residentialLoanApplicationId, generarSoloActoGarantia == true);
	}

	private static ResidentialLoanApplication queryRla(Id rlaId) {
		return [
			SELECT
				Id,
				AccountId,
				CreatedBy.Name,
				RecordType.DeveloperName,
				FSC_RequiereContratoPagareNotarial__c,
				FSC_Numero_Prestamo_Pagare__c,
				FSC_Excepcion_Contrato_Notarial__c,
				FSC_Requiere_Acto_Garantia__c,
				FSC_Propietario_Garantia_Vehiculo__c,
				FSC_Propietario_Garantia_Hipotecaria__c,
				FSC_Tipo_Vendedor_Hipotecario__c,
				FSC_Datos_Contrato_Hipotecario__c,
				FSC_Datos_Intervinientes_Contrato__c,
				FSC_GastosLegalesContratos__c,
				FSC_GastosGarantiasHip2__c,
				FSC_GastosGarantiasHip3__c,
				FSC_Acto_Garantia_Generado__c,
				FSC_Documento_Base_Acto_Garantia__c,
				FSC_Forma_Pago_Acto_Garantia__c,
				FSC_Generales_Fiadores_Acto__c,
				FSC_Relacion_Propietario_CD__c,
				FSC_Numero_Fisico_CD__c,
				FSC_Identificacion_Propietario_CD__c,
				FSC_Lugar_Pignoracion_CD__c,
				FSC_Nombre_Ejecutivo_Pignoracion__c,
				FSC_Cargo_Ejecutivo_Pignoracion__c,
				FSC_Pignoracion_Generada__c,
				FSC_ActoNumeroPagare__c,
				FSC_NumeroFolioPagare__c,
				FSC_MontoAprobado__c,
				FSC_Monto__c,
				FSC_PlazoMesesAprobado__c,
				FSC_Plazo_meses__c,
				FSC_TasaInteresAprobada__c,
				FSC_TasaInteres__c,
				FSC_TasaFijaPorMeses__c,
				FSC_Destino_del_Prestamo__c,
				FSC_DescripcionPropositoFacilidad__c,
				FSC_Moneda__c,
				FSC_Fecha_Contrato__c,
				FSC_RNC_Cliente_Contrato__c,
				FSC_Registro_Mercantil_Contrato__c,
				FSC_Identificacion_Cliente_Contrato__c,
				FSC_Nacionalidad_Cliente_Contrato__c,
				FSC_Estado_Civil_Cliente_Contrato__c,
				FSC_Domicilio_Cliente_Contrato__c,
				FSC_Nombre_Representante_Cliente__c,
				FSC_Cargo_Representante_Cliente__c,
				FSC_Nacionalidad_Representante__c,
				FSC_Estado_Civil_Representante__c,
				FSC_Identificacion_Representante__c,
				FSC_Domicilio_Representante__c,
				FSC_Resolucion_Autorizacion__c,
				FSC_Fecha_Acta_Autorizacion__c,
				FSC_Personas_Autorizadas__c,
				FSC_Calidad_Autorizados__c,
				FSC_Nombre_Garante_Contrato__c,
				FSC_Identificacion_Garante_Contrato__c,
				FSC_Nacionalidad_Garante_Contrato__c,
				FSC_Estado_Civil_Garante_Contrato__c,
				FSC_Domicilio_Garante_Contrato__c,
				Account.Id,
				Account.Name,
				Account.IsPersonAccount,
				Account.ACC_RNC__c,
				Account.VFS_RegistroMercantil__c,
				Account.ACC_NumIdentificacion__c,
				Account.ACC_Nacionalidad__c,
				Account.ACC_Estado_Civil__c,
				Account.BillingStreet,
				Account.BillingCity,
				Account.BillingState,
				Account.BillingPostalCode,
				Account.BillingCountry,
				CreatedBy.Title
			FROM ResidentialLoanApplication
			WHERE Id = :rlaId
			LIMIT 1
		];
	}

	private static FSC_Garantia__c queryGuarantee(Id guaranteeId) {
		return [
			SELECT
				Id,
				FSC_Descripcion_de_la_Garantia__c,
				FSC_Ubicacion__c,
				FSC_Numero_Titulo__c,
				FSC_Registro_de_Titulos__c,
				FSC_Fecha_Expedicion_Titulo__c,
				FSC_Tipo_Vehiculo__c,
				FSC_Marca_Vehiculo__c,
				FSC_Modelo_Vehiculo__c,
				FSC_Ano_Vehiculo__c,
				FSC_Color_Vehiculo__c,
				FSC_Numero_Chasis_Vehiculo__c,
				FSC_Serial_Motor_Vehiculo__c,
				FSC_Numero_Placa_Vehiculo__c,
				FSC_Numero_Matricula__c,
				FSC_Valor_Vehiculo__c,
				FSC_Numero_Certificado_Deposito__c,
				FSC_Fecha_Certificado_Deposito__c,
				FSC_Titular_Certificado_Deposito__c,
				FSC_Monto_Certificado_Deposito__c,
				FSC_Moneda_Certificado_Deposito__c,
				FSC_Emisor_Certificado_Deposito__c
			FROM FSC_Garantia__c
			WHERE Id = :guaranteeId
			LIMIT 1
		];
	}

	private static LoanApplicationAsset queryLoanApplicationAsset(Id assetId) {
		return [
			SELECT
				Id,
				AssetClass,
				AssetType,
				AccountType,
				AccountNumber,
				CashOrMarketValue,
				FinancialInstitutionName,
				FSC_Descripcion_de_la_Garantia__c,
				RealEstateStreet,
				RealEstateCity,
				RealEstateState,
				RealEstatePostalCode,
				RealEstateCountry,
				FSC_Descripcion_Contrato__c,
				FSC_Ubicacion_Contrato__c,
				FSC_Numero_Titulo_Contrato__c,
				FSC_Registro_Titulos_Contrato__c,
				FSC_Fecha_Titulo_Contrato__c,
				FSC_Tipo_Vehiculo_Contrato__c,
				FSC_Marca_Vehiculo_Contrato__c,
				FSC_Modelo_Vehiculo_Contrato__c,
				FSC_Ano_Vehiculo_Contrato__c,
				FSC_Color_Vehiculo_Contrato__c,
				FSC_Chasis_Vehiculo_Contrato__c,
				FSC_Motor_Vehiculo_Contrato__c,
				FSC_Placa_Vehiculo_Contrato__c,
				FSC_Matricula_Vehiculo_Contrato__c,
				FSC_Fecha_CD_Contrato__c,
				FSC_Titular_CD_Contrato__c,
				FSC_Moneda_CD_Contrato__c
			FROM LoanApplicationAsset
			WHERE Id = :assetId
			LIMIT 1
		];
	}

	private static FSC_Seguro__c queryInsurance(Id rlaId, String templateCode) {
		List<FSC_Seguro__c> records = [
			SELECT
				Id,
				FSC_Tipo_de_Seguro__c,
				FSC_Numero_Poliza_Contrato__c,
				FSC_Aseguradora_Contrato__c,
				FSC_Direccion_Aseguradora_Contrato__c,
				FSC_Fecha_Endoso_Contrato__c,
				FSC_Monto_Asegurado_Contrato__c,
				FSC_Monto_de_la_Prima__c
			FROM FSC_Seguro__c
			WHERE FSC_Residential_Loan_Application__c = :rlaId
			ORDER BY CreatedDate ASC, Id ASC
		];
		for (FSC_Seguro__c record : records) {
			if (hasContractInsuranceData(record))
				return record;
		}
		for (FSC_Seguro__c record : records) {
			String insuranceType = String.valueOf(record.FSC_Tipo_de_Seguro__c).toUpperCase();
			if (isMortgageTemplate(templateCode) && insuranceType.contains('INCENDIO'))
				return record;
			if (isVehicleTemplate(templateCode) && isVehicleInsurance(insuranceType))
				return record;
		}
		return null;
	}

	private static Boolean hasContractInsuranceData(FSC_Seguro__c insurance) {
		return !String.isBlank(insurance.FSC_Numero_Poliza_Contrato__c) ||
			!String.isBlank(insurance.FSC_Aseguradora_Contrato__c) ||
			insurance.FSC_Fecha_Endoso_Contrato__c != null ||
			insurance.FSC_Monto_Asegurado_Contrato__c != null;
	}

	private static Boolean isVehicleInsurance(String insuranceType) {
		return insuranceType.contains('AUTOM') ||
			insuranceType.contains('JEEP') ||
			insuranceType.contains('CAMION') ||
			insuranceType.contains('VEHICULO') ||
			insuranceType.contains('UNIVERSAL_NUEVO') ||
			insuranceType.contains('UNIVERSAL_USADO');
	}

	private static void buildClientSections(ContextoGeneracion context, ResidentialLoanApplication rla, Account account, String templateCode) {
		SeccionEntrada client = new SeccionEntrada('Datos obligatorios del cliente para el contrato');
		if (account.IsPersonAccount) {
			client.campos.add(
				field(
					'clienteIdentificacion',
					'Identificación del cliente',
					first(rla.FSC_Identificacion_Cliente_Contrato__c, account.ACC_NumIdentificacion__c),
					'text'
				)
			);
			client.campos.add(
				field(
					'clienteNacionalidad',
					'Nacionalidad del cliente',
					first(rla.FSC_Nacionalidad_Cliente_Contrato__c, account.ACC_Nacionalidad__c),
					'text'
				)
			);
			client.campos.add(
				field(
					'clienteEstadoCivil',
					'Estado civil del cliente',
					first(rla.FSC_Estado_Civil_Cliente_Contrato__c, account.ACC_Estado_Civil__c),
					'text'
				)
			);
		} else {
			client.campos.add(field('clienteRnc', 'RNC del cliente', first(rla.FSC_RNC_Cliente_Contrato__c, account.ACC_RNC__c), 'text'));
			client.campos.add(
				field(
					'clienteRegistroMercantil',
					'Registro mercantil del cliente',
					first(rla.FSC_Registro_Mercantil_Contrato__c, account.VFS_RegistroMercantil__c),
					'text'
				)
			);
		}
		client.campos.add(
			field('clienteDomicilio', 'Domicilio del cliente', first(rla.FSC_Domicilio_Cliente_Contrato__c, buildAddress(account)), 'textarea')
		);
		context.seccionesContrato.add(client);

		if (account.IsPersonAccount)
			return;

		Participante__c participant = queryAuthorizedParticipant(account.Id);
		SeccionEntrada representative = new SeccionEntrada('Representante autorizado del cliente');
		representative.campos.add(
			field('representanteNombre', 'Nombre completo', first(rla.FSC_Nombre_Representante_Cliente__c, participantName(participant)), 'text')
		);
		representative.campos.add(
			field(
				'representanteCargo',
				'Cargo o calidad',
				first(rla.FSC_Cargo_Representante_Cliente__c, participant == null ? null : participant.Cargo__c),
				'text'
			)
		);
		representative.campos.add(
			field(
				'representanteNacionalidad',
				'Nacionalidad',
				first(rla.FSC_Nacionalidad_Representante__c, participant == null ? null : participant.Participante__r.ACC_Nacionalidad__c),
				'text'
			)
		);
		representative.campos.add(
			field(
				'representanteEstadoCivil',
				'Estado civil',
				first(rla.FSC_Estado_Civil_Representante__c, participant == null ? null : participant.Participante__r.ACC_Estado_Civil__c),
				'text'
			)
		);
		representative.campos.add(
			field(
				'representanteIdentificacion',
				'Identificación',
				first(rla.FSC_Identificacion_Representante__c, participant == null ? null : participant.Participante__r.ACC_NumIdentificacion__c),
				'text'
			)
		);
		representative.campos.add(
			field('representanteDomicilio', 'Domicilio', first(rla.FSC_Domicilio_Representante__c, participantAddress(participant)), 'textarea')
		);
		context.seccionesContrato.add(representative);

		if (templateCode != FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION) {
			SeccionEntrada authorization = new SeccionEntrada('Autorización societaria');
			authorization.campos.add(
				field('autorizacionResolucion', 'Resolución o disposición del acta', rla.FSC_Resolucion_Autorizacion__c, 'text')
			);
			authorization.campos.add(field('autorizacionFecha', 'Fecha del acta', stringValue(rla.FSC_Fecha_Acta_Autorizacion__c), 'date'));
			authorization.campos.add(field('autorizacionPersonas', 'Personas autorizadas', rla.FSC_Personas_Autorizadas__c, 'text'));
			authorization.campos.add(field('autorizacionCalidad', 'Calidad de las personas autorizadas', rla.FSC_Calidad_Autorizados__c, 'text'));
			context.seccionesContrato.add(authorization);
		}
	}

	private static void buildPagareClientSection(ContextoGeneracion context, ResidentialLoanApplication rla, Account account) {
		SeccionEntrada section = new SeccionEntrada('Datos del firmante del pagaré');
		section.campos.add(
			field(
				'clienteIdentificacion',
				'Identificación',
				first(rla.FSC_Identificacion_Cliente_Contrato__c, account.ACC_NumIdentificacion__c),
				'text'
			)
		);
		section.campos.add(
			field('clienteNacionalidad', 'Nacionalidad', first(rla.FSC_Nacionalidad_Cliente_Contrato__c, account.ACC_Nacionalidad__c), 'text')
		);
		section.campos.add(
			field('clienteEstadoCivil', 'Estado civil', first(rla.FSC_Estado_Civil_Cliente_Contrato__c, account.ACC_Estado_Civil__c), 'text')
		);
		section.campos.add(field('clienteDomicilio', 'Dirección', first(rla.FSC_Domicilio_Cliente_Contrato__c, buildAddress(account)), 'textarea'));
		context.seccionesPagare.add(section);
	}

	private static void buildGuarantorSection(ContextoGeneracion context, ResidentialLoanApplication rla, Id rlaId, Boolean forPagare) {
		List<LoanApplicant> guarantors = [
			SELECT
				Id,
				Name,
				FSC_Nombre__c,
				FSC_PrimerApellido__c,
				FSC_SegundoApellido__c,
				FSC_NumIdentificacion__c,
				FSC_Nacionalidad__c,
				FSC_EstadoCivil__c,
				(SELECT Street, City, State, Country FROM Contact_Point_Addresses__r ORDER BY CreatedDate ASC, Id ASC LIMIT 1)
			FROM LoanApplicant
			WHERE LoanApplicationId = :rlaId AND FSC_TipoSolicitante__c = 'Garante'
			WITH USER_MODE
			ORDER BY CreatedDate ASC, Id ASC
			LIMIT 1
		];
		if (guarantors.isEmpty())
			return;
		LoanApplicant guarantor = guarantors[0];
		SeccionEntrada section = new SeccionEntrada(
			forPagare ? 'Datos del garante solidario del pagaré' : 'Datos obligatorios del garante solidario'
		);
		section.campos.add(field('garanteNombre', 'Nombre completo', first(rla.FSC_Nombre_Garante_Contrato__c, applicantName(guarantor)), 'text'));
		section.campos.add(
			field(
				'garanteIdentificacion',
				'Identificación',
				first(rla.FSC_Identificacion_Garante_Contrato__c, guarantor.FSC_NumIdentificacion__c),
				'text'
			)
		);
		section.campos.add(
			field('garanteNacionalidad', 'Nacionalidad', first(rla.FSC_Nacionalidad_Garante_Contrato__c, guarantor.FSC_Nacionalidad__c), 'text')
		);
		section.campos.add(
			field('garanteEstadoCivil', 'Estado civil', first(rla.FSC_Estado_Civil_Garante_Contrato__c, guarantor.FSC_EstadoCivil__c), 'text')
		);
		section.campos.add(
			field('garanteDomicilio', 'Domicilio', first(rla.FSC_Domicilio_Garante_Contrato__c, contactAddress(guarantor)), 'textarea')
		);
		if (forPagare)
			context.seccionesPagare.add(section);
		else
			context.seccionesContrato.add(section);
	}

	private static void buildActoGuaranteeSections(
		ContextoGeneracion context,
		ResidentialLoanApplication rla,
		Account account,
		FSC_RLAContractTemplateResolver.ContractResolution resolution
	) {
		ContextoGeneracion clientContext = new ContextoGeneracion();
		buildClientSections(clientContext, rla, account, FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_SOLIDARIA);
		for (SeccionEntrada section : clientContext.seccionesContrato) {
			if (!section.titulo.startsWith('Autorizaci')) {
				context.seccionesActoGarantia.add(section);
			}
		}

		List<LoanApplicant> guarantors = [
			SELECT
				Id,
				Name,
				FSC_Nombre__c,
				FSC_PrimerApellido__c,
				FSC_SegundoApellido__c,
				FSC_NumIdentificacion__c,
				FSC_Nacionalidad__c,
				FSC_EstadoCivil__c,
				(SELECT Street, City, State, Country FROM Contact_Point_Addresses__r ORDER BY CreatedDate ASC, Id ASC LIMIT 1)
			FROM LoanApplicant
			WHERE LoanApplicationId = :rla.Id AND FSC_TipoSolicitante__c = 'Garante'
			WITH USER_MODE
			ORDER BY CreatedDate, Id
		];
		if (guarantors.isEmpty()) {
			context.erroresConfiguracionActo.add('El acto de garantía solidaria requiere al menos un Loan Applicant de tipo Garante.');
		}

		SeccionEntrada act = new SeccionEntrada('Datos obligatorios del acto de garantía solidaria');
		act.campos.add(
			field(
				'actoDocumentoBase',
				'Nombre del contrato o documento garantizado',
				first(rla.FSC_Documento_Base_Acto_Garantia__c, resolution.nombreContrato),
				'text'
			)
		);
		act.campos.add(
			field(
				'actoGeneralesFiadores',
				'Generales completas de los fiadores solidarios',
				first(rla.FSC_Generales_Fiadores_Acto__c, buildGuarantorLegalDescription(rla, guarantors)),
				'textarea'
			)
		);
		act.campos.add(
			field(
				'actoFormaPago',
				'Descripción completa de la forma de pago',
				first(rla.FSC_Forma_Pago_Acto_Garantia__c, buildActPaymentDescription(rla)),
				'textarea'
			)
		);
		context.seccionesActoGarantia.add(act);
	}

	private static String buildGuarantorLegalDescription(ResidentialLoanApplication rla, List<LoanApplicant> guarantors) {
		List<String> descriptions = new List<String>();
		for (Integer index = 0; index < guarantors.size(); index++) {
			LoanApplicant guarantor = guarantors[index];
			String name = index == 0 ? first(rla.FSC_Nombre_Garante_Contrato__c, applicantName(guarantor)) : applicantName(guarantor);
			String identification = index == 0
				? first(rla.FSC_Identificacion_Garante_Contrato__c, guarantor.FSC_NumIdentificacion__c)
				: stringValue(guarantor.FSC_NumIdentificacion__c);
			String nationality = index == 0
				? first(rla.FSC_Nacionalidad_Garante_Contrato__c, guarantor.FSC_Nacionalidad__c)
				: stringValue(guarantor.FSC_Nacionalidad__c);
			String civilStatus = index == 0
				? first(rla.FSC_Estado_Civil_Garante_Contrato__c, guarantor.FSC_EstadoCivil__c)
				: stringValue(guarantor.FSC_EstadoCivil__c);
			String address = index == 0 ? first(rla.FSC_Domicilio_Garante_Contrato__c, contactAddress(guarantor)) : contactAddress(guarantor);
			descriptions.add(
				name +
					', de nacionalidad ' +
					nationality +
					', mayor de edad, estado civil ' +
					civilStatus +
					', portador(a) del documento de identidad No. ' +
					identification +
					', domiciliado(a) y residente en ' +
					address
			);
		}
		if (descriptions.size() == 1)
			return descriptions[0];
		String lastDescription = descriptions.remove(descriptions.size() - 1);
		return String.join(descriptions, '; ') + '; y ' + lastDescription;
	}

	private static String buildActPaymentDescription(ResidentialLoanApplication rla) {
		Decimal amount = rla.FSC_MontoAprobado__c == null ? rla.FSC_Monto__c : rla.FSC_MontoAprobado__c;
		Decimal rate = rla.FSC_TasaInteresAprobada__c == null ? rla.FSC_TasaInteres__c : rla.FSC_TasaInteresAprobada__c;
		Decimal monthsValue = rla.FSC_PlazoMesesAprobado__c;
		if (monthsValue == null && !String.isBlank(rla.FSC_Plazo_meses__c)) {
			monthsValue = Decimal.valueOf(rla.FSC_Plazo_meses__c);
		}
		Integer months = monthsValue == null ? null : monthsValue.intValue();
		if (months == null)
			return '';

		Decimal payment = FSC_ContratoFormatoService.calcularCuota(amount, rate, months);
		Date startDate = Date.today();
		Date expirationDate = startDate.addMonths(months);
		return 'LA DEUDORA se obliga a pagarla en el término de ' +
			FSC_ContratoFormatoService.numeroMasculinoEnLetras(months).toLowerCase() +
			' (' +
			months +
			') meses, contados a partir del ' +
			FSC_ContratoFormatoService.fechaCortaEnLetras(startDate) +
			', mediante ' +
			FSC_ContratoFormatoService.numeroMasculinoEnLetras(months).toLowerCase() +
			' (' +
			months +
			') cuotas mensuales, iguales y consecutivas, comprensivas de capital e intereses, por ' +
			FSC_ContratoFormatoService.montoEnLetras(payment, rla.FSC_Moneda__c) +
			' (' +
			FSC_ContratoFormatoService.simboloMoneda(rla.FSC_Moneda__c) +
			FSC_ContratoFormatoService.formatearMonto(payment) +
			'), con vencimiento final el ' +
			FSC_ContratoFormatoService.fechaCortaEnLetras(expirationDate) +
			'.';
	}

	private static void buildPignoracionSections(
		ContextoGeneracion context,
		ResidentialLoanApplication rla,
		Account account,
		FSC_ConsumoDocumentoResolver.ResolucionDocumento consumption
	) {
		if (consumption == null || consumption.garantiaId == null) {
			context.erroresConfiguracion.add('El certificado de depósito requiere una garantía FSC_Garantia__c relacionada.');
			return;
		}

		FSC_Garantia__c guarantee = queryGuarantee(consumption.garantiaId);
		String borrowerIdentification = first(rla.FSC_Identificacion_Cliente_Contrato__c, account.ACC_NumIdentificacion__c);
		String ownerIdentification = rla.FSC_Identificacion_Propietario_CD__c;
		if (rla.FSC_Relacion_Propietario_CD__c == 'Titular del préstamo') {
			ownerIdentification = borrowerIdentification;
		}

		SeccionEntrada section = new SeccionEntrada('Datos obligatorios del documento de pignoración');
		CampoEntrada ownerRelationship = field(
			'pignoracionRelacionPropietario',
			'Relación entre el titular del préstamo y el dueño del CD',
			rla.FSC_Relacion_Propietario_CD__c,
			'picklist'
		);
		ownerRelationship.opciones.add(new OpcionEntrada('Es el mismo dueño', 'Titular del préstamo'));
		ownerRelationship.opciones.add(new OpcionEntrada('Es una persona distinta', 'Persona distinta'));
		section.campos.add(ownerRelationship);
		section.campos.add(field('certificadoNumero', 'Número del certificado de depósito', guarantee.FSC_Numero_Certificado_Deposito__c, 'text'));
		section.campos.add(field('pignoracionNumeroFisico', 'Número físico del certificado', rla.FSC_Numero_Fisico_CD__c, 'text'));
		section.campos.add(
			field(
				'certificadoTitular',
				'Nombre del titular del certificado',
				first(guarantee.FSC_Titular_Certificado_Deposito__c, account.Name),
				'text'
			)
		);
		section.campos.add(
			field(
				'pignoracionIdentificacionPropietario',
				'Identificación del titular del certificado',
				first(ownerIdentification, borrowerIdentification),
				'text'
			)
		);
		section.campos.add(
			field('certificadoMonto', 'Monto o balance del certificado', stringValue(guarantee.FSC_Monto_Certificado_Deposito__c), 'number')
		);
		CampoEntrada currencyField = field(
			'certificadoMoneda',
			'Moneda del certificado',
			first(guarantee.FSC_Moneda_Certificado_Deposito__c, FSC_ContratoFormatoService.nombreMoneda(rla.FSC_Moneda__c)),
			'picklist'
		);
		currencyField.opciones.add(new OpcionEntrada('Pesos Dominicanos', 'Pesos Dominicanos'));
		currencyField.opciones.add(new OpcionEntrada('Dólares estadounidenses', 'Dólares estadounidenses'));
		section.campos.add(currencyField);
		section.campos.add(
			field(
				'certificadoEmisor',
				'Entidad emisora del certificado',
				first(guarantee.FSC_Emisor_Certificado_Deposito__c, 'Banco Múltiple Vimenca, S. A.'),
				'text'
			)
		);
		section.campos.add(
			field(
				'pignoracionLugar',
				'Municipio y provincia donde se otorga',
				first(rla.FSC_Lugar_Pignoracion_CD__c, joinAddress(null, account.BillingCity, account.BillingState, account.BillingCountry)),
				'text'
			)
		);
		section.campos.add(
			field(
				'pignoracionEjecutivoNombre',
				'Nombre del ejecutivo certificador',
				first(rla.FSC_Nombre_Ejecutivo_Pignoracion__c, rla.CreatedBy.Name),
				'text'
			)
		);
		section.campos.add(
			field(
				'pignoracionEjecutivoCargo',
				'Cargo del ejecutivo certificador',
				first(rla.FSC_Cargo_Ejecutivo_Pignoracion__c, rla.CreatedBy.Title),
				'text'
			)
		);
		context.seccionesPignoracion.add(section);
	}

	private static void buildMortgageSections(ContextoGeneracion context, FSC_Garantia__c guarantee, FSC_Seguro__c insurance) {
		SeccionEntrada collateral = new SeccionEntrada('Datos obligatorios de la garantía hipotecaria');
		collateral.campos.add(
			field('garantiaDescripcion', 'Descripción legal del inmueble', guarantee.FSC_Descripcion_de_la_Garantia__c, 'textarea')
		);
		collateral.campos.add(field('garantiaNumeroTitulo', 'Matrícula del certificado de título', guarantee.FSC_Numero_Titulo__c, 'text'));
		collateral.campos.add(field('garantiaRegistroTitulos', 'Registro de Títulos', guarantee.FSC_Registro_de_Titulos__c, 'text'));
		collateral.campos.add(
			field('garantiaFechaTitulo', 'Fecha de expedición del título', stringValue(guarantee.FSC_Fecha_Expedicion_Titulo__c), 'date')
		);
		context.seccionesContrato.add(collateral);
		context.seccionesContrato.add(buildInsuranceSection(insurance));
	}

	private static void buildMortgageSections(ContextoGeneracion context, LoanApplicationAsset guarantee, FSC_Seguro__c insurance) {
		SeccionEntrada collateral = new SeccionEntrada('Datos obligatorios de la garantía hipotecaria');
		collateral.campos.add(
			field(
				'garantiaDescripcion',
				'Descripción legal del inmueble',
				first(guarantee.FSC_Descripcion_Contrato__c, loanAssetGuaranteeLabel(guarantee)),
				'textarea'
			)
		);
		collateral.campos.add(field('garantiaNumeroTitulo', 'Matrícula del certificado de título', guarantee.FSC_Numero_Titulo_Contrato__c, 'text'));
		collateral.campos.add(field('garantiaRegistroTitulos', 'Registro de Títulos', guarantee.FSC_Registro_Titulos_Contrato__c, 'text'));
		collateral.campos.add(
			field('garantiaFechaTitulo', 'Fecha de expedición del título', stringValue(guarantee.FSC_Fecha_Titulo_Contrato__c), 'date')
		);
		context.seccionesContrato.add(collateral);
		context.seccionesContrato.add(buildInsuranceSection(insurance));
	}

	private static void buildVehicleOwnerSection(ContextoGeneracion context, String currentOwner) {
		SeccionEntrada owner = new SeccionEntrada('Propietario de la garantía vehicular');
		CampoEntrada ownerField = field(
			'vehiculoPropietarioGarantia',
			'Dueño de la garantía',
			String.isBlank(currentOwner) ? FSC_VehiculoDocumentoResolver.PROPIETARIO_DEUDOR : currentOwner,
			'picklist'
		);
		ownerField.opciones.add(new OpcionEntrada('Deudor', FSC_VehiculoDocumentoResolver.PROPIETARIO_DEUDOR));
		ownerField.opciones.add(new OpcionEntrada('Otra persona (Garante mobiliario)', FSC_VehiculoDocumentoResolver.PROPIETARIO_DISTINTO));
		owner.campos.add(ownerField);
		context.seccionesPagare.add(owner);
	}

	private static void buildMortgageDecisionSection(
		ContextoGeneracion context,
		FSC_HipotecarioDocumentoResolver.ResolucionDocumento resolution,
		ResidentialLoanApplication rla
	) {
		SeccionEntrada decision = new SeccionEntrada('Selección del contrato hipotecario');
		CampoEntrada owner = field('hipotecarioPropietarioGarantia', 'Dueño de la garantía hipotecaria', resolution.propietarioGarantia, 'picklist');
		owner.opciones.add(new OpcionEntrada('Deudor', FSC_HipotecarioDocumentoResolver.PROPIETARIO_DEUDOR));
		owner.opciones.add(new OpcionEntrada('Otra persona (Garante real)', FSC_HipotecarioDocumentoResolver.PROPIETARIO_DISTINTO));
		decision.campos.add(owner);

		CampoEntrada sellerType = field(
			'hipotecarioTipoVendedor',
			'Tipo de vendedor del inmueble',
			resolution.tieneCertificadoConfotur ? FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA : resolution.tipoVendedor,
			'picklist'
		);
		sellerType.opciones.add(new OpcionEntrada('Persona física', FSC_HipotecarioDocumentoResolver.VENDEDOR_PERSONA_FISICA));
		sellerType.opciones.add(new OpcionEntrada('Empresa', FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA));
		sellerType.opciones.add(new OpcionEntrada('Fideicomiso', FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO));
		decision.campos.add(sellerType);

		Map<String, Object> saved = FSC_ContratoIntervinienteService.parse(rla.FSC_Datos_Intervinientes_Contrato__c);
		FSC_ContratoIntervinienteService.Interviniente spouse = FSC_ContratoIntervinienteService.getConyuge(rla.AccountId, saved);
		String spouseSelection = stored(saved, 'hipotecarioConyugeInterviniente');
		if (String.isBlank(spouseSelection)) {
			String civilStatus = first(rla.FSC_Estado_Civil_Cliente_Contrato__c, rla.Account.ACC_Estado_Civil__c).toUpperCase();
			spouseSelection = civilStatus.contains('CASAD') &&
				!FSC_ContratoIntervinienteService.isApplicant(rla.Id, spouse.identificacion)
				? 'Sí'
				: 'No';
		}
		CampoEntrada spouseField = field(
			'hipotecarioConyugeInterviniente',
			'Incluir cónyuge interviniente',
			spouseSelection,
			'picklist'
		);
		spouseField.opciones.add(new OpcionEntrada('Sí', 'Sí'));
		spouseField.opciones.add(new OpcionEntrada('No', 'No'));
		decision.campos.add(spouseField);
		context.seccionesPagare.add(decision);
	}

	private static void buildContractInterveners(
		ContextoGeneracion context,
		ResidentialLoanApplication rla,
		Boolean esVehiculo,
		Boolean esHipotecario
	) {
		if (!esVehiculo && !esHipotecario) return;
		Map<String, Object> saved = FSC_ContratoIntervinienteService.parse(rla.FSC_Datos_Intervinientes_Contrato__c);
		List<FSC_ContratoIntervinienteService.Interviniente> coBorrowers = FSC_ContratoIntervinienteService.getApplicants(
			rla.Id,
			FSC_ContratoIntervinienteService.TIPO_CODEUDOR,
			'codeudor_',
			saved,
			false
		);
		addIntervenerSections(context, coBorrowers, 'codeudor_', 'Datos obligatorios del prestatario adicional', null, null, true);

		String ownerValue = esVehiculo
			? FSC_VehiculoDocumentoResolver.PROPIETARIO_DISTINTO
			: FSC_HipotecarioDocumentoResolver.PROPIETARIO_DISTINTO;
		List<FSC_ContratoIntervinienteService.Interviniente> guarantors = FSC_ContratoIntervinienteService.getApplicants(
			rla.Id,
			FSC_ContratoIntervinienteService.TIPO_GARANTE,
			'garanteContrato_',
			saved,
			true
		);
		addIntervenerSections(
			context,
			guarantors,
			'garanteContrato_',
			esVehiculo ? 'Datos obligatorios del garante mobiliario' : 'Datos obligatorios del garante real',
			ownerValue,
			null,
			(esVehiculo ? rla.FSC_Propietario_Garantia_Vehiculo__c : rla.FSC_Propietario_Garantia_Hipotecaria__c) == ownerValue
		);

		if (esHipotecario) {
			FSC_ContratoIntervinienteService.Interviniente spouse = FSC_ContratoIntervinienteService.getConyuge(rla.AccountId, saved);
			String spouseSelection = stored(saved, 'hipotecarioConyugeInterviniente');
			if (String.isBlank(spouseSelection)) {
				String civilStatus = first(rla.FSC_Estado_Civil_Cliente_Contrato__c, rla.Account.ACC_Estado_Civil__c).toUpperCase();
				spouseSelection = civilStatus.contains('CASAD') &&
					!FSC_ContratoIntervinienteService.isApplicant(rla.Id, spouse.identificacion)
					? 'Sí'
					: 'No';
			}
			addIntervenerSections(
				context,
				new List<FSC_ContratoIntervinienteService.Interviniente>{ spouse },
				'conyuge_',
				'Datos obligatorios del cónyuge interviniente',
				null,
				'Sí',
				spouseSelection == 'Sí'
			);
		}
	}

	private static void addIntervenerSections(
		ContextoGeneracion context,
		List<FSC_ContratoIntervinienteService.Interviniente> people,
		String keyPrefix,
		String title,
		String ownerCondition,
		String spouseCondition,
		Boolean required
	) {
		for (Integer index = 0; index < people.size(); index++) {
			FSC_ContratoIntervinienteService.Interviniente person = people[index];
			String prefix = keyPrefix == 'conyuge_' ? keyPrefix : keyPrefix + String.valueOf(index) + '_';
			SeccionEntrada section = new SeccionEntrada(title + (people.size() > 1 ? ' ' + String.valueOf(index + 1) : ''));
			List<CampoEntrada> fields = new List<CampoEntrada>{
				field(prefix + 'nombre', 'Nombre completo', person.nombre, 'text'),
				field(prefix + 'identificacion', 'Identificación', person.identificacion, 'text'),
				field(prefix + 'nacionalidad', 'Nacionalidad', person.nacionalidad, 'text'),
				field(prefix + 'estadoCivil', 'Estado civil', person.estadoCivil, 'text'),
				field(prefix + 'domicilio', 'Domicilio', person.domicilio, 'textarea')
			};
			for (CampoEntrada input : fields) {
				input.mostrarParaPropietarioGarantia = ownerCondition;
				input.mostrarParaConyuge = spouseCondition;
				input.requerido = required;
				section.campos.add(input);
			}
			context.seccionesContrato.add(section);
		}
	}

	private static void buildMortgageExpenseSection(ContextoGeneracion context, ResidentialLoanApplication rla) {
		SeccionEntrada expenses = new SeccionEntrada('Gastos del contrato hipotecario');
		CampoEntrada legalExpenses = field('gastosLegalesContratos', 'Gastos legales', rla.FSC_GastosLegalesContratos__c, 'number');
		CampoEntrada mortgageExpenses2 = field('gastosGarantiaHip2', 'Gastos garantía hipotecaria 2%', rla.FSC_GastosGarantiasHip2__c, 'number');
		CampoEntrada mortgageExpenses3 = field('gastosGarantiaHip3', 'Gastos garantía hipotecaria 3%', rla.FSC_GastosGarantiasHip3__c, 'number');
		for (CampoEntrada expense : new List<CampoEntrada>{ legalExpenses, mortgageExpenses2, mortgageExpenses3 }) {
			expense.requerido = false;
			expense.paso = '0.01';
			expense.minimo = 0;
			expenses.campos.add(expense);
		}
		context.seccionesContrato.add(expenses);
	}

	private static void validateMortgageExpenses(
		ResidentialLoanApplication rla,
		Decimal legalExpenses,
		Decimal mortgageExpenses2,
		Decimal mortgageExpenses3
	) {
		Boolean hasExpenses = legalExpenses != null || mortgageExpenses2 != null || mortgageExpenses3 != null;
		if (hasExpenses && rla.RecordType.DeveloperName != 'FSC_Solicitud_Credito_Hipotecario') {
			throw new AuraHandledException('Los gastos de contrato solo aplican a créditos hipotecarios.');
		}
		if (mortgageExpenses2 != null && mortgageExpenses3 != null) {
			// Los porcentajes de garantía son excluyentes.
			throw new AuraHandledException('Debe indicar únicamente uno entre gastos de garantía hipotecaria 2% y 3%.');
		}
		for (Decimal expense : new List<Decimal>{ legalExpenses, mortgageExpenses2, mortgageExpenses3 }) {
			if (expense != null && (expense < 0 || expense.scale() > 2)) {
				throw new AuraHandledException('Los gastos deben ser positivos y admitir como máximo dos decimales.');
			}
		}
	}

	private static void buildMortgagePurchaseSections(
		ContextoGeneracion context,
		ResidentialLoanApplication rla,
		FSC_HipotecarioDocumentoResolver.ResolucionDocumento resolution
	) {
		Map<String, Object> saved = parseStoredValues(rla.FSC_Datos_Contrato_Hipotecario__c);

		SeccionEntrada sale = new SeccionEntrada('Datos obligatorios de la compraventa');
		sale.campos.add(field('hipotecarioPrecioVenta', 'Precio de venta del inmueble', stored(saved, 'hipotecarioPrecioVenta'), 'number'));
		sale.campos.add(
			field('hipotecarioAporteInicial', 'Monto pagado por el cliente como inicial', stored(saved, 'hipotecarioAporteInicial'), 'number')
		);
		sale.campos.add(
			field('hipotecarioFechaPagoInicial', 'Fecha del comprobante de pago inicial', stored(saved, 'hipotecarioFechaPagoInicial'), 'date')
		);
		sale.campos.add(field('hipotecarioMedioPagoInicial', 'Medio de pago de la inicial', stored(saved, 'hipotecarioMedioPagoInicial'), 'text'));
		sale.campos.add(
			field('hipotecarioMedioPagoFinanciado', 'Medio de pago del monto financiado', stored(saved, 'hipotecarioMedioPagoFinanciado'), 'text')
		);
		sale.campos.add(
			field(
				'hipotecarioPeriodoTasaFija',
				'Período de tasa fija en meses',
				first(stored(saved, 'hipotecarioPeriodoTasaFija'), stringValue(rla.FSC_TasaFijaPorMeses__c)),
				'number'
			)
		);
		context.seccionesContrato.add(sale);

		SeccionEntrada naturalSeller = new SeccionEntrada('Datos obligatorios del vendedor persona física');
		naturalSeller.campos.add(
			conditionalField(
				'hipotecarioVendedorNombre',
				'Nombre completo',
				stored(saved, 'hipotecarioVendedorNombre'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_PERSONA_FISICA
			)
		);
		naturalSeller.campos.add(
			conditionalField(
				'hipotecarioVendedorNacionalidad',
				'Nacionalidad',
				stored(saved, 'hipotecarioVendedorNacionalidad'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_PERSONA_FISICA
			)
		);
		naturalSeller.campos.add(
			conditionalField(
				'hipotecarioVendedorEstadoCivil',
				'Estado civil',
				stored(saved, 'hipotecarioVendedorEstadoCivil'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_PERSONA_FISICA
			)
		);
		naturalSeller.campos.add(
			conditionalField(
				'hipotecarioVendedorIdentificacion',
				'Identificación',
				stored(saved, 'hipotecarioVendedorIdentificacion'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_PERSONA_FISICA
			)
		);
		naturalSeller.campos.add(
			conditionalField(
				'hipotecarioVendedorDomicilio',
				'Domicilio',
				stored(saved, 'hipotecarioVendedorDomicilio'),
				'textarea',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_PERSONA_FISICA
			)
		);
		context.seccionesContrato.add(naturalSeller);

		SeccionEntrada companySeller = new SeccionEntrada('Datos obligatorios de la empresa vendedora');
		companySeller.campos.add(
			conditionalField(
				'hipotecarioVendedorNombre',
				'Razón social',
				stored(saved, 'hipotecarioVendedorNombre'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA
			)
		);
		companySeller.campos.add(
			conditionalField(
				'hipotecarioVendedorRnc',
				'RNC',
				stored(saved, 'hipotecarioVendedorRnc'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA
			)
		);
		companySeller.campos.add(
			conditionalField(
				'hipotecarioVendedorRegistroMercantil',
				'Registro mercantil',
				stored(saved, 'hipotecarioVendedorRegistroMercantil'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA
			)
		);
		companySeller.campos.add(
			conditionalField(
				'hipotecarioVendedorDomicilio',
				'Domicilio social',
				stored(saved, 'hipotecarioVendedorDomicilio'),
				'textarea',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA
			)
		);
		companySeller.campos.add(
			conditionalField(
				'hipotecarioVendedorRepresentanteCargo',
				'Cargo del representante',
				stored(saved, 'hipotecarioVendedorRepresentanteCargo'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA
			)
		);
		companySeller.campos.add(
			conditionalField(
				'hipotecarioVendedorRepresentanteNombre',
				'Nombre del representante',
				stored(saved, 'hipotecarioVendedorRepresentanteNombre'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA
			)
		);
		companySeller.campos.add(
			conditionalPicklistField(
				'hipotecarioVendedorRepresentanteNacionalidad',
				'Nacionalidad del representante',
				stored(saved, 'hipotecarioVendedorRepresentanteNacionalidad'),
				FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA,
				LoanApplicant.FSC_Nacionalidad__c.getDescribe()
			)
		);
		companySeller.campos.add(
			conditionalField(
				'hipotecarioVendedorRepresentanteEstadoCivil',
				'Estado civil del representante',
				stored(saved, 'hipotecarioVendedorRepresentanteEstadoCivil'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA
			)
		);
		companySeller.campos.add(
			conditionalField(
				'hipotecarioVendedorRepresentanteIdentificacion',
				'Identificación del representante',
				stored(saved, 'hipotecarioVendedorRepresentanteIdentificacion'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA
			)
		);
		companySeller.campos.add(
			conditionalField(
				'hipotecarioVendedorRepresentanteDomicilio',
				'Domicilio del representante',
				stored(saved, 'hipotecarioVendedorRepresentanteDomicilio'),
				'textarea',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA
			)
		);
		companySeller.campos.add(
			conditionalField(
				'hipotecarioVendedorAutorizacion',
				'Certificación o autorización societaria para la venta',
				stored(saved, 'hipotecarioVendedorAutorizacion'),
				'textarea',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_EMPRESA
			)
		);
		context.seccionesContrato.add(companySeller);

		SeccionEntrada trust = new SeccionEntrada('Datos obligatorios del fideicomiso vendedor');
		trust.campos.add(
			conditionalField(
				'hipotecarioFideicomisoNombre',
				'Nombre del fideicomiso',
				stored(saved, 'hipotecarioFideicomisoNombre'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO
			)
		);
		trust.campos.add(
			conditionalField(
				'hipotecarioFideicomisoRnc',
				'RNC del fideicomiso',
				stored(saved, 'hipotecarioFideicomisoRnc'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO
			)
		);
		trust.campos.add(
			conditionalField(
				'hipotecarioFideicomisoRegistro',
				'Registro mercantil del fideicomiso',
				stored(saved, 'hipotecarioFideicomisoRegistro'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO
			)
		);
		trust.campos.add(
			conditionalField(
				'hipotecarioFiduciariaNombre',
				'Razón social de la fiduciaria',
				stored(saved, 'hipotecarioFiduciariaNombre'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO
			)
		);
		trust.campos.add(
			conditionalField(
				'hipotecarioFiduciariaRnc',
				'RNC de la fiduciaria',
				stored(saved, 'hipotecarioFiduciariaRnc'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO
			)
		);
		trust.campos.add(
			conditionalField(
				'hipotecarioFiduciariaRegistro',
				'Registro mercantil de la fiduciaria',
				stored(saved, 'hipotecarioFiduciariaRegistro'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO
			)
		);
		trust.campos.add(
			conditionalField(
				'hipotecarioFiduciariaDomicilio',
				'Domicilio de la fiduciaria',
				stored(saved, 'hipotecarioFiduciariaDomicilio'),
				'textarea',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO
			)
		);
		trust.campos.add(
			conditionalField(
				'hipotecarioFiduciariaRepresentantes',
				'Generales completas de los representantes de la fiduciaria',
				stored(saved, 'hipotecarioFiduciariaRepresentantes'),
				'textarea',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO
			)
		);
		trust.campos.add(
			conditionalField(
				'hipotecarioFiduciariaFirmantes',
				'Nombres de los representantes de la fiduciaria',
				stored(saved, 'hipotecarioFiduciariaFirmantes'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO
			)
		);
		trust.campos.add(
			conditionalField(
				'hipotecarioFiduciariaAutorizacion',
				'Documento que faculta a los representantes',
				stored(saved, 'hipotecarioFiduciariaAutorizacion'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO
			)
		);
		trust.campos.add(
			conditionalField(
				'hipotecarioPromotoresGenerales',
				'Generales completas de los fideicomitentes-promotores',
				stored(saved, 'hipotecarioPromotoresGenerales'),
				'textarea',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO
			)
		);
		trust.campos.add(
			conditionalField(
				'hipotecarioPromotoresFirmantes',
				'Nombres de los representantes de los promotores',
				stored(saved, 'hipotecarioPromotoresFirmantes'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO
			)
		);
		trust.campos.add(
			conditionalField(
				'hipotecarioProyectoNombre',
				'Nombre del proyecto o residencial',
				stored(saved, 'hipotecarioProyectoNombre'),
				'text',
				FSC_HipotecarioDocumentoResolver.VENDEDOR_FIDEICOMISO
			)
		);
		context.seccionesContrato.add(trust);

		for (SeccionEntrada section : context.seccionesContrato) {
			for (CampoEntrada item : section.campos) {
				if (!String.isBlank(item.mostrarParaTipoVendedor)) {
					item.requerido = item.mostrarParaTipoVendedor == resolution.tipoVendedor;
				}
			}
		}
	}

	private static CampoEntrada conditionalField(String key, String label, Object valueToUse, String type, String sellerType) {
		CampoEntrada result = field(key, label, valueToUse, type);
		result.mostrarParaTipoVendedor = sellerType;
		return result;
	}

	private static CampoEntrada conditionalPicklistField(
		String key,
		String label,
		Object valueToUse,
		String sellerType,
		Schema.DescribeFieldResult fieldDescription
	) {
		CampoEntrada result = picklistField(key, label, valueToUse, fieldDescription);
		result.mostrarParaTipoVendedor = sellerType;
		return result;
	}

	private static Map<String, Object> parseStoredValues(String storedJson) {
		if (String.isBlank(storedJson))
			return new Map<String, Object>();
		try {
			return (Map<String, Object>) JSON.deserializeUntyped(storedJson);
		} catch (Exception ignored) {
			return new Map<String, Object>();
		}
	}

	private static Map<String, Object> intervenerValues(Map<String, Object> values) {
		Map<String, Object> result = new Map<String, Object>();
		for (String key : values.keySet()) {
			if (
				key.startsWith('codeudor_') ||
				key.startsWith('garanteContrato_') ||
				key.startsWith('conyuge_') ||
				key == 'hipotecarioConyugeInterviniente'
			) {
				result.put(key, values.get(key));
			}
		}
		return result;
	}

	private static Map<String, Object> nonIntervenerValues(Map<String, Object> values) {
		Map<String, Object> result = new Map<String, Object>();
		for (String key : values.keySet()) {
			if (
				!key.startsWith('codeudor_') &&
				!key.startsWith('garanteContrato_') &&
				!key.startsWith('conyuge_') &&
				key != 'hipotecarioConyugeInterviniente'
			) {
				result.put(key, values.get(key));
			}
		}
		return result;
	}

	private static String stored(Map<String, Object> values, String key) {
		return values.containsKey(key) && values.get(key) != null ? String.valueOf(values.get(key)) : null;
	}

	private static void buildVehicleSections(ContextoGeneracion context, FSC_Garantia__c guarantee, FSC_Seguro__c insurance) {
		SeccionEntrada vehicle = new SeccionEntrada('Datos obligatorios del vehículo en garantía');
		vehicle.campos.add(field('vehiculoTipo', 'Tipo de vehículo', guarantee.FSC_Tipo_Vehiculo__c, 'text'));
		vehicle.campos.add(vehicleBrandField(guarantee.FSC_Marca_Vehiculo__c));
		vehicle.campos.add(vehicleModelField(guarantee.FSC_Marca_Vehiculo__c, guarantee.FSC_Modelo_Vehiculo__c));
		vehicle.campos.add(field('vehiculoAno', 'Año', stringValue(guarantee.FSC_Ano_Vehiculo__c), 'number'));
		vehicle.campos.add(field('vehiculoColor', 'Color', guarantee.FSC_Color_Vehiculo__c, 'text'));
		vehicle.campos.add(field('vehiculoChasis', 'Número de chasis', guarantee.FSC_Numero_Chasis_Vehiculo__c, 'text'));
		vehicle.campos.add(field('vehiculoMotor', 'Número de motor', guarantee.FSC_Serial_Motor_Vehiculo__c, 'text'));
		vehicle.campos.add(field('vehiculoPlaca', 'Placa', guarantee.FSC_Numero_Placa_Vehiculo__c, 'text'));
		vehicle.campos.add(field('vehiculoMatricula', 'Matrícula', guarantee.FSC_Numero_Matricula__c, 'text'));
		vehicle.campos.add(field('vehiculoValor', 'Valor del vehículo', stringValue(guarantee.FSC_Valor_Vehiculo__c), 'number'));
		vehicle.campos.add(field('vehiculoUbicacion', 'Ubicación del vehículo', guarantee.FSC_Ubicacion__c, 'textarea'));
		context.seccionesContrato.add(vehicle);
		context.seccionesContrato.add(buildInsuranceSection(insurance));
	}

	private static void buildVehicleSections(ContextoGeneracion context, LoanApplicationAsset guarantee, FSC_Seguro__c insurance) {
		SeccionEntrada vehicle = new SeccionEntrada('Datos obligatorios del vehículo en garantía');
		vehicle.campos.add(field('vehiculoTipo', 'Tipo de vehículo', guarantee.FSC_Tipo_Vehiculo_Contrato__c, 'text'));
		vehicle.campos.add(field('vehiculoMarca', 'Marca', guarantee.FSC_Marca_Vehiculo_Contrato__c, 'text'));
		vehicle.campos.add(field('vehiculoModelo', 'Modelo', guarantee.FSC_Modelo_Vehiculo_Contrato__c, 'text'));
		vehicle.campos.add(field('vehiculoAno', 'Año', stringValue(guarantee.FSC_Ano_Vehiculo_Contrato__c), 'number'));
		vehicle.campos.add(field('vehiculoColor', 'Color', guarantee.FSC_Color_Vehiculo_Contrato__c, 'text'));
		vehicle.campos.add(field('vehiculoChasis', 'Número de chasis', guarantee.FSC_Chasis_Vehiculo_Contrato__c, 'text'));
		vehicle.campos.add(field('vehiculoMotor', 'Número de motor', guarantee.FSC_Motor_Vehiculo_Contrato__c, 'text'));
		vehicle.campos.add(field('vehiculoPlaca', 'Placa', guarantee.FSC_Placa_Vehiculo_Contrato__c, 'text'));
		vehicle.campos.add(field('vehiculoMatricula', 'Matrícula', guarantee.FSC_Matricula_Vehiculo_Contrato__c, 'text'));
		vehicle.campos.add(field('vehiculoValor', 'Valor del vehículo', stringValue(guarantee.CashOrMarketValue), 'number'));
		vehicle.campos.add(
			field('vehiculoUbicacion', 'Ubicación del vehículo', first(guarantee.FSC_Ubicacion_Contrato__c, loanAssetAddress(guarantee)), 'textarea')
		);
		context.seccionesContrato.add(vehicle);
		context.seccionesContrato.add(buildInsuranceSection(insurance));
	}

	private static void buildDepositCertificateSection(ContextoGeneracion context, FSC_Garantia__c guarantee, String accountName) {
		SeccionEntrada certificate = new SeccionEntrada('Datos obligatorios del certificado de depósito');
		certificate.campos.add(field('certificadoNumero', 'Número del certificado', guarantee.FSC_Numero_Certificado_Deposito__c, 'text'));
		certificate.campos.add(field('certificadoFecha', 'Fecha de emisión', stringValue(guarantee.FSC_Fecha_Certificado_Deposito__c), 'date'));
		certificate.campos.add(field('certificadoTitular', 'Titular', first(guarantee.FSC_Titular_Certificado_Deposito__c, accountName), 'text'));
		certificate.campos.add(field('certificadoMonto', 'Monto nominal', stringValue(guarantee.FSC_Monto_Certificado_Deposito__c), 'number'));
		CampoEntrada currencyField = field('certificadoMoneda', 'Moneda del certificado', guarantee.FSC_Moneda_Certificado_Deposito__c, 'picklist');
		currencyField.opciones.add(new OpcionEntrada('Pesos Dominicanos', 'Pesos Dominicanos'));
		currencyField.opciones.add(new OpcionEntrada('Dólares estadounidenses', 'Dólares estadounidenses'));
		certificate.campos.add(currencyField);
		certificate.campos.add(
			field(
				'certificadoEmisor',
				'Entidad emisora',
				first(guarantee.FSC_Emisor_Certificado_Deposito__c, 'Banco Múltiple Vimenca, S. A.'),
				'text'
			)
		);
		context.seccionesContrato.add(certificate);
	}

	private static void buildDepositCertificateSection(
		ContextoGeneracion context,
		LoanApplicationAsset guarantee,
		String accountName,
		String creditCurrency
	) {
		SeccionEntrada certificate = new SeccionEntrada('Datos obligatorios del certificado de depósito');
		certificate.campos.add(field('certificadoNumero', 'Número del certificado', guarantee.AccountNumber, 'text'));
		certificate.campos.add(field('certificadoFecha', 'Fecha de emisión', stringValue(guarantee.FSC_Fecha_CD_Contrato__c), 'date'));
		certificate.campos.add(field('certificadoTitular', 'Titular', first(guarantee.FSC_Titular_CD_Contrato__c, accountName), 'text'));
		certificate.campos.add(field('certificadoMonto', 'Monto nominal', stringValue(guarantee.CashOrMarketValue), 'number'));
		CampoEntrada currencyField = field(
			'certificadoMoneda',
			'Moneda del certificado',
			first(guarantee.FSC_Moneda_CD_Contrato__c, FSC_ContratoFormatoService.nombreMoneda(creditCurrency)),
			'picklist'
		);
		currencyField.opciones.add(new OpcionEntrada('Pesos Dominicanos', 'Pesos Dominicanos'));
		currencyField.opciones.add(new OpcionEntrada('Dólares estadounidenses', 'Dólares estadounidenses'));
		certificate.campos.add(currencyField);
		certificate.campos.add(
			field('certificadoEmisor', 'Entidad emisora', first(guarantee.FinancialInstitutionName, 'Banco Múltiple Vimenca, S. A.'), 'text')
		);
		context.seccionesContrato.add(certificate);
	}

	private static SeccionEntrada buildInsuranceSection(FSC_Seguro__c insurance) {
		SeccionEntrada section = new SeccionEntrada('Datos obligatorios del seguro de propiedad');
		section.campos.add(field('seguroPoliza', 'Número de póliza', insurance == null ? null : insurance.FSC_Numero_Poliza_Contrato__c, 'text'));
		section.campos.add(
			field('seguroAseguradora', 'Compañía aseguradora', insurance == null ? null : insurance.FSC_Aseguradora_Contrato__c, 'text')
		);
		section.campos.add(
			field(
				'seguroDireccion',
				'Dirección de la aseguradora',
				insurance == null ? null : insurance.FSC_Direccion_Aseguradora_Contrato__c,
				'textarea'
			)
		);
		section.campos.add(
			field('seguroFechaEndoso', 'Fecha del endoso', insurance == null ? null : stringValue(insurance.FSC_Fecha_Endoso_Contrato__c), 'date')
		);
		section.campos.add(
			field('seguroMonto', 'Monto asegurado', insurance == null ? null : stringValue(insurance.FSC_Monto_Asegurado_Contrato__c), 'number')
		);
		return section;
	}

	private static void addConsumptionInsurancePremium(ContextoGeneracion context, FSC_Seguro__c insurance) {
		for (SeccionEntrada section : context.seccionesContrato) {
			if (section.titulo == 'Datos obligatorios del seguro de propiedad') {
				section.campos.add(
					field(
						'seguroPrima',
						'Prima mensual del seguro',
						insurance == null ? null : stringValue(insurance.FSC_Monto_de_la_Prima__c),
						'number'
					)
				);
				return;
			}
		}
	}

	private static void updateGuarantee(Id guaranteeId, String templateCode, Map<String, Object> values) {
		FSC_Garantia__c updateItem = new FSC_Garantia__c(Id = guaranteeId);
		if (isMortgageTemplate(templateCode)) {
			updateItem.FSC_Descripcion_de_la_Garantia__c = value(values, 'garantiaDescripcion');
			updateItem.FSC_Numero_Titulo__c = value(values, 'garantiaNumeroTitulo');
			updateItem.FSC_Registro_de_Titulos__c = value(values, 'garantiaRegistroTitulos');
			updateItem.FSC_Fecha_Expedicion_Titulo__c = dateValue(values, 'garantiaFechaTitulo');
		} else if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION) {
			updateItem.FSC_Numero_Certificado_Deposito__c = value(values, 'certificadoNumero');
			updateItem.FSC_Fecha_Certificado_Deposito__c = dateValue(values, 'certificadoFecha');
			updateItem.FSC_Titular_Certificado_Deposito__c = value(values, 'certificadoTitular');
			updateItem.FSC_Monto_Certificado_Deposito__c = decimalValue(values, 'certificadoMonto');
			updateItem.FSC_Moneda_Certificado_Deposito__c = value(values, 'certificadoMoneda');
			updateItem.FSC_Emisor_Certificado_Deposito__c = value(values, 'certificadoEmisor');
		} else if (isVehicleTemplate(templateCode)) {
			updateItem.FSC_Tipo_Vehiculo__c = value(values, 'vehiculoTipo');
			updateItem.FSC_Marca_Vehiculo__c = value(values, 'vehiculoMarca');
			updateItem.FSC_Modelo_Vehiculo__c = value(values, 'vehiculoModelo');
			updateItem.FSC_Ano_Vehiculo__c = decimalValue(values, 'vehiculoAno');
			updateItem.FSC_Color_Vehiculo__c = value(values, 'vehiculoColor');
			updateItem.FSC_Numero_Chasis_Vehiculo__c = value(values, 'vehiculoChasis');
			updateItem.FSC_Serial_Motor_Vehiculo__c = value(values, 'vehiculoMotor');
			updateItem.FSC_Numero_Placa_Vehiculo__c = value(values, 'vehiculoPlaca');
			updateItem.FSC_Numero_Matricula__c = value(values, 'vehiculoMatricula');
			updateItem.FSC_Valor_Vehiculo__c = decimalValue(values, 'vehiculoValor');
			updateItem.FSC_Ubicacion__c = value(values, 'vehiculoUbicacion');
		}
		update updateItem;
	}

	private static void updatePignoracionGuarantee(Id guaranteeId, Map<String, Object> values) {
		update new FSC_Garantia__c(
			Id = guaranteeId,
			FSC_Numero_Certificado_Deposito__c = value(values, 'certificadoNumero'),
			FSC_Titular_Certificado_Deposito__c = value(values, 'certificadoTitular'),
			FSC_Monto_Certificado_Deposito__c = decimalValue(values, 'certificadoMonto'),
			FSC_Moneda_Certificado_Deposito__c = value(values, 'certificadoMoneda'),
			FSC_Emisor_Certificado_Deposito__c = value(values, 'certificadoEmisor')
		);
	}

	private static void updateLoanApplicationAsset(Id assetId, String templateCode, Map<String, Object> values) {
		LoanApplicationAsset updateItem = new LoanApplicationAsset(Id = assetId);
		if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_HIPOTECARIA) {
			updateItem.FSC_Descripcion_Contrato__c = value(values, 'garantiaDescripcion');
			updateItem.FSC_Numero_Titulo_Contrato__c = value(values, 'garantiaNumeroTitulo');
			updateItem.FSC_Registro_Titulos_Contrato__c = value(values, 'garantiaRegistroTitulos');
			updateItem.FSC_Fecha_Titulo_Contrato__c = dateValue(values, 'garantiaFechaTitulo');
		} else if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION) {
			updateItem.AccountNumber = value(values, 'certificadoNumero');
			updateItem.FSC_Fecha_CD_Contrato__c = dateValue(values, 'certificadoFecha');
			updateItem.FSC_Titular_CD_Contrato__c = value(values, 'certificadoTitular');
			updateItem.CashOrMarketValue = decimalValue(values, 'certificadoMonto');
			updateItem.FSC_Moneda_CD_Contrato__c = value(values, 'certificadoMoneda');
			updateItem.FinancialInstitutionName = value(values, 'certificadoEmisor');
		} else if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION) {
			updateItem.FSC_Tipo_Vehiculo_Contrato__c = value(values, 'vehiculoTipo');
			updateItem.FSC_Marca_Vehiculo_Contrato__c = value(values, 'vehiculoMarca');
			updateItem.FSC_Modelo_Vehiculo_Contrato__c = value(values, 'vehiculoModelo');
			updateItem.FSC_Ano_Vehiculo_Contrato__c = decimalValue(values, 'vehiculoAno');
			updateItem.FSC_Color_Vehiculo_Contrato__c = value(values, 'vehiculoColor');
			updateItem.FSC_Chasis_Vehiculo_Contrato__c = value(values, 'vehiculoChasis');
			updateItem.FSC_Motor_Vehiculo_Contrato__c = value(values, 'vehiculoMotor');
			updateItem.FSC_Placa_Vehiculo_Contrato__c = value(values, 'vehiculoPlaca');
			updateItem.FSC_Matricula_Vehiculo_Contrato__c = value(values, 'vehiculoMatricula');
			updateItem.CashOrMarketValue = decimalValue(values, 'vehiculoValor');
			updateItem.FSC_Ubicacion_Contrato__c = value(values, 'vehiculoUbicacion');
		}
		update updateItem;
	}

	private static void upsertInsurance(Id rlaId, String templateCode, Map<String, Object> values) {
		FSC_Seguro__c insurance = queryInsurance(rlaId, templateCode);
		if (insurance == null) {
			insurance = new FSC_Seguro__c(
				FSC_Residential_Loan_Application__c = rlaId,
				FSC_Tipo_de_Seguro__c = isMortgageTemplate(templateCode) ? 'Seguro_Incendio_Universal' : 'Seguros_de_Vehiculos_Universal'
			);
		}
		insurance.FSC_Numero_Poliza_Contrato__c = value(values, 'seguroPoliza');
		insurance.FSC_Aseguradora_Contrato__c = value(values, 'seguroAseguradora');
		insurance.FSC_Direccion_Aseguradora_Contrato__c = value(values, 'seguroDireccion');
		insurance.FSC_Fecha_Endoso_Contrato__c = dateValue(values, 'seguroFechaEndoso');
		insurance.FSC_Monto_Asegurado_Contrato__c = decimalValue(values, 'seguroMonto');
		if (values.containsKey('seguroPrima')) {
			insurance.FSC_Monto_de_la_Prima__c = decimalValue(values, 'seguroPrima');
		}
		upsert insurance;
	}

	private static void clearCorporateFields(ResidentialLoanApplication rla) {
		rla.FSC_RNC_Cliente_Contrato__c = null;
		rla.FSC_Registro_Mercantil_Contrato__c = null;
		rla.FSC_Nombre_Representante_Cliente__c = null;
		rla.FSC_Cargo_Representante_Cliente__c = null;
		rla.FSC_Nacionalidad_Representante__c = null;
		rla.FSC_Estado_Civil_Representante__c = null;
		rla.FSC_Identificacion_Representante__c = null;
		rla.FSC_Domicilio_Representante__c = null;
		rla.FSC_Resolucion_Autorizacion__c = null;
		rla.FSC_Fecha_Acta_Autorizacion__c = null;
		rla.FSC_Personas_Autorizadas__c = null;
		rla.FSC_Calidad_Autorizados__c = null;
	}

	private static Participante__c queryAuthorizedParticipant(Id accountId) {
		List<Participante__c> records = [
			SELECT
				Id,
				Cargo__c,
				Participante__r.Name,
				Participante__r.ACC_NumIdentificacion__c,
				Participante__r.ACC_Nacionalidad__c,
				Participante__r.ACC_Estado_Civil__c,
				Participante__r.BillingStreet,
				Participante__r.BillingCity,
				Participante__r.BillingState,
				Participante__r.BillingCountry
			FROM Participante__c
			WHERE PAR_Cliente__c = :accountId AND VFS_FirmanteDeContratoAutorizado__c = TRUE
			ORDER BY CreatedDate ASC, Id ASC
			LIMIT 1
		];
		return records.isEmpty() ? null : records[0];
	}

	private static CampoEntrada field(String key, String label, Object valueToUse, String type) {
		return new CampoEntrada(key, label, stringValue(valueToUse), type);
	}

	// Con catalogo sincronizado, marca y modelo vienen del API; sin catalogo se usan los picklists historicos.
	@TestVisible
	private static CampoEntrada vehicleBrandField(String brand) {
		List<FSC_LoanFacilityController.VehicleOptionDTO> catalog = FSC_LoanFacilityController.getVehicleCatalog();
		if (catalog.isEmpty()) {
			return picklistField('vehiculoMarca', 'Marca', brand, FSC_Garantia__c.FSC_Marca_Vehiculo__c.getDescribe());
		}
		CampoEntrada result = field('vehiculoMarca', 'Marca', brand, 'picklist');
		Boolean currentValueListed = String.isBlank(brand);
		for (FSC_LoanFacilityController.VehicleOptionDTO option : catalog) {
			result.opciones.add(new OpcionEntrada(option.label, option.value));
			// equals distingue mayusculas como el combobox; == en Apex no lo hace.
			currentValueListed = currentValueListed || option.value.equals(brand);
		}
		// Una garantia historica conserva su valor aunque el API lo escriba distinto.
		if (!currentValueListed) {
			result.opciones.add(0, new OpcionEntrada(brand, brand));
		}
		return result;
	}

	@TestVisible
	private static CampoEntrada vehicleModelField(String brand, String model) {
		List<FSC_LoanFacilityController.VehicleOptionDTO> catalog = FSC_LoanFacilityController.getVehicleCatalog();
		if (catalog.isEmpty()) {
			return picklistField('vehiculoModelo', 'Modelo', model, FSC_Garantia__c.FSC_Modelo_Vehiculo__c.getDescribe());
		}
		CampoEntrada result = field('vehiculoModelo', 'Modelo', model, 'picklist');
		Boolean currentValueListed = String.isBlank(model);
		for (FSC_LoanFacilityController.VehicleOptionDTO brandOption : catalog) {
			for (FSC_LoanFacilityController.VehicleOptionDTO modelOption : brandOption.models) {
				OpcionEntrada option = new OpcionEntrada(modelOption.label, modelOption.value);
				option.controlador = brandOption.value;
				result.opciones.add(option);
				currentValueListed = currentValueListed || (brandOption.value.equals(brand) && modelOption.value.equals(model));
			}
		}
		if (!currentValueListed) {
			OpcionEntrada historical = new OpcionEntrada(model, model);
			historical.controlador = brand;
			result.opciones.add(historical);
		}
		return result;
	}

	private static CampoEntrada picklistField(String key, String label, Object valueToUse, Schema.DescribeFieldResult fieldDescription) {
		CampoEntrada result = field(key, label, valueToUse, 'picklist');
		for (Schema.PicklistEntry entry : fieldDescription.getPicklistValues()) {
			if (entry.isActive())
				result.opciones.add(new OpcionEntrada(entry.getLabel(), entry.getValue()));
		}
		return result;
	}

	private static List<String> getMissingFieldLabels(ContextoGeneracion context, Boolean soloActoGarantia) {
		List<String> labels = new List<String>();
		List<SeccionEntrada> sections = new List<SeccionEntrada>();
		if (soloActoGarantia == true) {
			sections.addAll(context.seccionesActoGarantia);
		} else {
			sections.addAll(context.seccionesPagare);
			if (context.aplicaContrato)
				sections.addAll(context.seccionesContrato);
			if (context.requierePignoracion && !context.pignoracionGenerada) {
				sections.addAll(context.seccionesPignoracion);
			}
		}
		for (SeccionEntrada section : sections) {
			for (CampoEntrada item : section.campos) {
				if (item.requerido && String.isBlank(item.valor))
					labels.add('Falta ' + item.etiqueta + '.');
			}
		}
		return labels;
	}

	private static void validateSavedContext(Id rlaId, Boolean soloActoGarantia) {
		ContextoGeneracion refreshed = getContextoGeneracion(rlaId);
		List<String> missingFields = getMissingFieldLabels(refreshed, soloActoGarantia);
		List<String> configurationErrors = soloActoGarantia == true ? refreshed.erroresConfiguracionActo : refreshed.erroresConfiguracion;
		if (!configurationErrors.isEmpty())
			missingFields.addAll(configurationErrors);
		if (!missingFields.isEmpty()) {
			throw new AuraHandledException('No se pueden generar los documentos. ' + String.join(missingFields, ' | '));
		}
	}

	private static String resolvePagareType(ResidentialLoanApplication rla) {
		if (rla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Consumo') {
			return FSC_ConsumoDocumentoResolver.resolve(rla.Id).codigoPagare;
		}
		if (rla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Vehiculo') {
			return FSC_VehiculoDocumentoResolver.resolve(rla.Id).codigoPagare;
		}
		if (rla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_Hipotecario') {
			return FSC_HipotecarioDocumentoResolver.resolve(rla.Id).codigoPagare;
		}
		if (rla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_PYME' && rla.FSC_RequiereContratoPagareNotarial__c != true) {
			return FSC_ConsumoDocumentoResolver.PAGARE_COMPLEMENTARIO;
		}
		return FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL;
	}

	private static Boolean isMortgageTemplate(String templateCode) {
		return templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_HIPOTECARIA ||
			templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_CONSUMO_GARANTIA_HIPOTECARIA ||
			FSC_RLAContractTemplateResolver.isMortgagePurchaseTemplate(templateCode);
	}

	private static Boolean isVehicleTemplate(String templateCode) {
		return templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION ||
			templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_CONSUMO_GARANTIA_MOBILIARIA;
	}

	private static void validateFinancialData(List<String> errors, ResidentialLoanApplication rla) {
		if (rla.FSC_MontoAprobado__c == null && rla.FSC_Monto__c == null)
			errors.add('Falta el monto del crédito.');
		if (rla.FSC_PlazoMesesAprobado__c == null && rla.FSC_Plazo_meses__c == null)
			errors.add('Falta el plazo del crédito.');
		if (rla.FSC_TasaInteresAprobada__c == null && rla.FSC_TasaInteres__c == null)
			errors.add('Falta la tasa del crédito.');
		if (String.isBlank(rla.FSC_Destino_del_Prestamo__c) && String.isBlank(rla.FSC_DescripcionPropositoFacilidad__c)) {
			errors.add('Falta el destino o propósito del préstamo en el RLA.');
		}
	}

	private static void validatePignoracionFinancialData(List<String> errors, ResidentialLoanApplication rla) {
		if (rla.FSC_MontoAprobado__c == null && rla.FSC_Monto__c == null) {
			errors.add('Falta el monto del crédito para generar la pignoración.');
		}
	}

	private static String value(Map<String, Object> values, String key) {
		if (!values.containsKey(key) || values.get(key) == null)
			return null;
		String result = String.valueOf(values.get(key)).trim();
		return String.isBlank(result) ? null : result;
	}

	private static String valueOrCurrent(Map<String, Object> values, String key, Object currentValue) {
		return values.containsKey(key) ? value(values, key) : stringValue(currentValue);
	}

	private static Date dateValue(Map<String, Object> values, String key) {
		String rawValue = value(values, key);
		return String.isBlank(rawValue) ? null : Date.valueOf(rawValue);
	}

	private static Date dateValueOrCurrent(Map<String, Object> values, String key, Date currentValue) {
		return values.containsKey(key) ? dateValue(values, key) : currentValue;
	}

	private static Decimal decimalValue(Map<String, Object> values, String key) {
		String rawValue = value(values, key);
		return String.isBlank(rawValue) ? null : Decimal.valueOf(rawValue);
	}

	private static Decimal decimalValueOrCurrent(Map<String, Object> values, String key, Decimal currentValue) {
		return values.containsKey(key) ? decimalValue(values, key) : currentValue;
	}

	private static String first(Object firstValue, Object secondValue) {
		String firstText = stringValue(firstValue);
		return String.isBlank(firstText) ? stringValue(secondValue) : firstText;
	}

	private static String stringValue(Object input) {
		if (input == null)
			return '';
		if (input instanceof Date)
			return String.valueOf((Date) input);
		if (input instanceof Decimal)
			return String.valueOf((Decimal) input);
		return String.valueOf(input).trim();
	}

	private static String buildAddress(Account account) {
		return joinAddress(account.BillingStreet, account.BillingCity, account.BillingState, account.BillingCountry);
	}

	private static String participantAddress(Participante__c participant) {
		if (participant == null || participant.Participante__r == null)
			return '';
		return joinAddress(
			participant.Participante__r.BillingStreet,
			participant.Participante__r.BillingCity,
			participant.Participante__r.BillingState,
			participant.Participante__r.BillingCountry
		);
	}

	private static String contactAddress(LoanApplicant applicant) {
		if (applicant.Contact_Point_Addresses__r == null || applicant.Contact_Point_Addresses__r.isEmpty())
			return '';
		ContactPointAddress address = applicant.Contact_Point_Addresses__r[0];
		return joinAddress(address.Street, address.City, address.State, address.Country);
	}

	private static String loanAssetAddress(LoanApplicationAsset asset) {
		List<String> parts = new List<String>();
		for (
			String item : new List<String>{
				asset.RealEstateStreet,
				asset.RealEstateCity,
				asset.RealEstateState,
				asset.RealEstatePostalCode,
				asset.RealEstateCountry
			}
		) {
			if (!String.isBlank(item))
				parts.add(item.trim());
		}
		return String.join(parts, ', ');
	}

	private static String loanAssetGuaranteeLabel(LoanApplicationAsset asset) {
		String storedValue = asset.FSC_Descripcion_de_la_Garantia__c;
		if (String.isBlank(storedValue))
			return '';
		for (Schema.PicklistEntry entry : LoanApplicationAsset.FSC_Descripcion_de_la_Garantia__c.getDescribe().getPicklistValues()) {
			if (entry.getValue() == storedValue)
				return entry.getLabel();
		}
		return storedValue;
	}

	private static String joinAddress(String street, String city, String state, String country) {
		List<String> parts = new List<String>();
		for (String item : new List<String>{ street, city, state, country }) {
			if (!String.isBlank(item))
				parts.add(item.trim());
		}
		return String.join(parts, ', ');
	}

	private static String participantName(Participante__c participant) {
		return participant == null || participant.Participante__r == null ? '' : participant.Participante__r.Name;
	}

	private static String applicantName(LoanApplicant applicant) {
		List<String> parts = new List<String>();
		for (String item : new List<String>{ applicant.FSC_Nombre__c, applicant.FSC_PrimerApellido__c, applicant.FSC_SegundoApellido__c }) {
			if (!String.isBlank(item))
				parts.add(item.trim());
		}
		return parts.isEmpty() ? applicant.Name : String.join(parts, ' ');
	}
}