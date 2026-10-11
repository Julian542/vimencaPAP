public without sharing class FSC_RlaAccionesController {
	@TestVisible
	private static Boolean testForcePrivilegedSupervisorReview = false;
	@TestVisible
	private static Boolean testBypassPermissions = false;
	private static final String SUBESTADO_RECEPCION_ANALISIS = 'Recepción de documentos – Análisis';
	private static final String SUBESTADO_DOCS_DESEMBOLSO = 'Documentación para desembolso y firmas';
	private static final String CAT_ANALISIS = 'Documentos para análisis';
	private static final String CAT_CONTRATO = 'Documentos para confección de contrato';
	private static final String CAT_DESEMBOLSO = 'Documentos para desembolso';
	private static final String ESTADO_PENDIENTE = 'Pendiente';
	private static final String ESTADO_APROBADO = 'Aprobado';
	private static final String ESTADO_OBSERVADO = 'Observado';
	private static final String SUBESTADO_RECEPCION_ANALISIS_NORM = 'recepcion de documentos analisis';
	private static final String SUBESTADO_ANALISIS_CREDITO_NORM = 'analisis de credito';
	private static final String SUBESTADO_DOCS_DESEMBOLSO_NORM = 'documentacion para desembolso y firmas';
	private static final String CAT_ANALISIS_NORM = 'documentos para analisis';
	private static final String CAT_CONTRATO_NORM = 'documentos para confeccion de contrato';
	private static final String CAT_DESEMBOLSO_NORM = 'documentos para desembolso';
	private static final String MSG_PAGARES_SIN_AUTORIZACION = 'Usted no tiene autorización para realizar esta acción, solo la persona asignada o un administrador tienen permiso.';
	private static final String SUBESTADO_CREACION_CREDITO = 'Creación de crédito';
	private static final String SUBESTADO_DESEMBOLSO = 'Desembolso';
	private static final String FORMA_DESEMBOLSO_CUENTA_AHORRO = 'Cuenta de ahorro';
	private static final String RT_SOLICITUD_CREDITO_PYME = 'FSC_Solicitud_Credito_PYME';
	private static final String IP_VALIDAR_CLASIFICACION_MIPYMES = 'FSC_ValidarClasificacionMIPYMES';
	private static final String RESPUESTA_CLASIFICACION_MIPYMES_VALIDA = 'ClasificacionMIPYMESValida';
	private static final String PROCESO_ANALISTA = 'FSC_AnalistasDeCredito';
	private static final String PROCESO_BANCA_SEGURO = 'FSC_BancaSeguro';
	private static final String PROCESO_VALIDACION_ABANKS = 'FSC_ValidacionEnAbanks';
	private static final String PERMISO_ADMINISTRADOR = 'FSC_CP_Administrador';
	private static final String PERMISO_ANALISTA_CREDITO = 'FSC_CP_Analista_Credito';
	private static final String PERMISO_ARCHIVO_CUSTODIA_VALORES = 'FSC_CP_Archivo_Custodia_Valores';
	private static final String PERMISO_COMITE_CREDITO = 'FSC_CP_Comite_Credito';
	private static final String PERMISO_PREVENCION_LAVADO_ACTIVOS = 'FSC_CP_Prevencion_Lavado_Activos';
	private static final String PERMISO_CONTROL_DOCUMENTOS = 'FSC_CP_Recepcion_Control_Documentos';
	private static final String PERMISO_SUPERVISOR = 'FSC_CP_Supervisor';
	private static final String PERMISO_OFICIAL_NEGOCIO = 'FSC_CP_Oficial_Negocio';
	private static final String SUBESTADO_GENERACION_PAGARES = 'Generación de pagarés y plantillas';
	private static final String COLA_PAGARES_Y_CONTRATOS = 'FSC_GestionDePagaresYContratos';
	private static final String PERMISO_BANCA_SEGURO = 'FSC_CP_BancaSeguro';
	private static final String RT_SOLICITUD_CREDITO_CONSUMO = 'FSC_Solicitud_Credito_Consumo';
	private static final String RT_SOLICITUD_CREDITO_VEHICULO = 'FSC_Solicitud_Credito_Vehiculo';
	private static final String RT_SOLICITUD_CREDITO_HIPOTECARIO = 'FSC_Solicitud_Credito_Hipotecario';
	private static final String FORMATO_TEXTO = 'text';
	private static final String FORMATO_ENTERO = 'integer';
	private static final String FORMATO_NUMERO = 'number';
	private static final String FORMATO_DINERO = 'money';
	private static final String FORMATO_DINERO_DOP = 'moneyDop';
	private static final String FORMATO_DINERO_USD = 'moneyUsd';
	private static final String FORMATO_PORCENTAJE = 'percent';
	private static final String FORMATO_FECHA = 'date';
	private static final Set<String> CAMPOS_CALCULADOS_INFORME = new Set<String>{
		'edad',
		'antiguedadLaboral',
		'ingresosMensualesPromedio',
		'cuotasFinancieras',
		'relacionCuotaIngresos',
		'endeudamientoTotal',
		'solvenciaEstimada',
		'exposicionTotal',
		'prestamoSobreTasacion',
		'prestamoSobrePrecioVenta'
	};
	private static final Set<String> CAMPOS_CALCULADOS_INFORME_PYME = new Set<String>{
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
	};
	private static final Set<String> CAMPOS_CALCULADOS_CAPACIDAD = new Set<String>{
		'prestamoSobreTasacion',
		'montosPesos.cuotaTarjetas',
		'montosPesos.deudaTarjetasCancelar',
		'cargaFinanciera',
		'resultadoCargaFinanciera',
		'capacidadIncluyendoVivienda',
		'resultadoCapacidadVivienda',
		'indiceApalancamiento',
		'resultadoApalancamiento',
		'capacidadEndeudamiento',
		'resultadoEndeudamiento',
		'patrimonio'
	};
	private static final Set<String> FILAS_CALCULADAS_CAPACIDAD = new Set<String>{
		'totalIngresos',
		'totalAdeudado',
		'totalPagosCreditos',
		'totalPagos'
	};
	private static final List<String> CONCEPTOS_INGRESOS_CAPACIDAD = new List<String>{
		'ingresoCartaTrabajo',
		'ingresoDepositos',
		'ingresoAlquiler',
		'ingresoInversiones',
		'ingresoOtros',
		'ingresoEstadosFinancieros'
	};
	private static final List<String> CONCEPTOS_DEUDAS_CAPACIDAD = new List<String>{ 'deudaTarjetas', 'deudaPrestamos' };
	private static final List<String> CONCEPTOS_PAGOS_CAPACIDAD = new List<String>{ 'cuotaTarjetas', 'cuotaPrestamos', 'cuotaNuevoPrestamo' };
	private static final List<String> CONCEPTOS_CANCELACIONES_CAPACIDAD = new List<String>{ 'cuotasCancelar', 'deudaTarjetasCancelar' };
	private static final List<String> TODOS_CONCEPTOS_CAPACIDAD = new List<String>{
		'ingresoCartaTrabajo',
		'ingresoDepositos',
		'ingresoAlquiler',
		'ingresoInversiones',
		'ingresoOtros',
		'ingresoEstadosFinancieros',
		'totalIngresos',
		'deudaTarjetas',
		'deudaPrestamos',
		'totalAdeudado',
		'cuotaTarjetas',
		'cuotaPrestamos',
		'cuotaNuevoPrestamo',
		'cuotasCancelar',
		'deudaTarjetasCancelar',
		'totalPagosCreditos',
		'pagoVivienda',
		'totalPagos'
	};
	@TestVisible
	private static Boolean testClasificacionMIPYMESValida;
	@TestVisible
	private static Boolean testPermitirEdicionDocumentosAnalisis = false;

	/** Obtiene el modelo final ya calculado que se imprime en uno de los PDF editables. */
	@AuraEnabled(cacheable=true)
	public static Map<String, Object> getDatosDocumentoAnalisis(Id residentialLoanApplicationId, String tipoDocumento) {
		String tipoNormalizado = validarTipoDocumentoAnalisis(tipoDocumento);
		ResidentialLoanApplication solicitud = validarContextoEdicionDocumento(residentialLoanApplicationId);
		validarDocumentoParaTipoCredito(solicitud, tipoNormalizado);
		if (solicitud.RecordType?.DeveloperName == RT_SOLICITUD_CREDITO_PYME) {
			return FSC_ControladorInformeCreditoPyme.construirDatos(residentialLoanApplicationId);
		}
		return FSC_ControladorDocumentosAnalisisCredito.construirDatos(residentialLoanApplicationId, tipoNormalizado);
	}

	/** Guarda únicamente los valores modificados y publica una nueva versión del PDF correspondiente. */
	@AuraEnabled
	public static void guardarYRegenerarDocumentoAnalisis(Id residentialLoanApplicationId, String tipoDocumento, String cambiosJson) {
		String tipoNormalizado = validarTipoDocumentoAnalisis(tipoDocumento);
		ResidentialLoanApplication solicitud = validarContextoEdicionDocumento(residentialLoanApplicationId);
		validarDocumentoParaTipoCredito(solicitud, tipoNormalizado);
		if (String.isBlank(cambiosJson)) {
			throw new AuraHandledException('No se recibieron cambios para guardar.');
		}

		Object cambiosSinTipo;
		try {
			cambiosSinTipo = JSON.deserializeUntyped(cambiosJson);
		} catch (Exception error) {
			throw new AuraHandledException('Los cambios enviados no tienen un formato válido.');
		}
		if (!(cambiosSinTipo instanceof Map<String, Object>)) {
			throw new AuraHandledException('Los cambios enviados no tienen un formato válido.');
		}

		Map<String, Object> cambios = (Map<String, Object>) cambiosSinTipo;
		if (cambios.isEmpty()) {
			throw new AuraHandledException('No se modificó ningún campo.');
		}
		Map<String, String> formatosPermitidos = obtenerFormatosDocumento(tipoNormalizado, solicitud.RecordType?.DeveloperName);
		VersionDocumentoAnalisis versionDocumento = obtenerVersionDocumentoAnalisis(residentialLoanApplicationId, tipoNormalizado);
		if (versionDocumento == null) {
			throw new AuraHandledException('No se encontró el PDF que desea editar en la solicitud.');
		}
		Map<String, Object> ajustes = versionDocumento.ajustes;
		Boolean esInformePyme = solicitud.RecordType?.DeveloperName == RT_SOLICITUD_CREDITO_PYME;
		Map<String, Object> datosEfectivos = tipoNormalizado == FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_CAPACIDAD
			? FSC_ControladorDocumentosAnalisisCredito.construirDatos(residentialLoanApplicationId, tipoNormalizado)
			: (esInformePyme ? FSC_ControladorInformeCreditoPyme.construirDatos(residentialLoanApplicationId) : null);
		Integer cantidadCambios = 0;
		Boolean requiereRecalculoCapacidad = false;

		for (String ruta : cambios.keySet()) {
			if (!formatosPermitidos.containsKey(ruta)) {
				throw new AuraHandledException('El campo ' + ruta + ' no puede editarse en este documento.');
			}
			Object detalleSinTipo = cambios.get(ruta);
			if (!(detalleSinTipo instanceof Map<String, Object>)) {
				throw new AuraHandledException('El valor enviado para ' + ruta + ' no tiene un formato válido.');
			}
			Map<String, Object> detalle = (Map<String, Object>) detalleSinTipo;
			String formatoEsperado = formatosPermitidos.get(ruta);
			String formatoRecibido = detalle.get('format') == null ? '' : String.valueOf(detalle.get('format'));
			if (formatoRecibido != formatoEsperado) {
				throw new AuraHandledException('El formato enviado para ' + ruta + ' no es válido.');
			}

			Object valorEntrada = detalle.get('value');
			String valorPdf = normalizarValorDocumento(valorEntrada, formatoEsperado, solicitud.FSC_Moneda__c, ruta);
			ponerValorEnRuta(ajustes, ruta, valorPdf);
			if (datosEfectivos != null) {
				ponerValorEnRuta(datosEfectivos, ruta, valorPdf);
				requiereRecalculoCapacidad =
					requiereRecalculoCapacidad ||
					ruta == 'tasaCambio' ||
					ruta.startsWith('montosPesos.') ||
					ruta.startsWith('montosDolares.');
			}
			cantidadCambios++;
		}

		if (cantidadCambios == 0) {
			throw new AuraHandledException('No se modificó ningún campo.');
		}
		if (requiereRecalculoCapacidad) {
			recalcularCapacidadPago(ajustes, datosEfectivos);
		}
		if (esInformePyme) {
			recalcularInformePyme(ajustes, datosEfectivos, solicitud.FSC_Moneda__c);
		}

		String ajustesJson = JSON.serialize(ajustes);
		if (ajustesJson.length() > 131072) {
			throw new AuraHandledException('Los cambios exceden el tamaño máximo permitido para el documento.');
		}
		update new ContentVersion(Id = versionDocumento.contentVersionId, FSC_DatosEditadosAnalisis__c = ajustesJson);
		System.enqueueJob(new FSC_ColaGeneracionDocumentosAnalisis(new List<Id>{ residentialLoanApplicationId }, tipoNormalizado));
	}

	@AuraEnabled
	public static Boolean validarClasificacionMIPYMES(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		ResidentialLoanApplication rla = [
			SELECT RecordType.DeveloperName, FSC_Cantidad_de_empleados__c, FSC_VentasBrutasAnuales__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			WITH USER_MODE
			LIMIT 1
		];

		if (rla.RecordType == null || rla.RecordType.DeveloperName != RT_SOLICITUD_CREDITO_PYME) {
			return true;
		}

		if (Test.isRunningTest() && testClasificacionMIPYMESValida != null) {
			return testClasificacionMIPYMESValida;
		}

		Map<String, Object> inputMap = new Map<String, Object>{
			'CantidadEmpleados' => rla.FSC_Cantidad_de_empleados__c,
			'VentasBrutasAnuales' => rla.FSC_VentasBrutasAnuales__c
		};

		try {
			Object rawResponse = omnistudio.IntegrationProcedureService.runIntegrationService(
				IP_VALIDAR_CLASIFICACION_MIPYMES,
				inputMap,
				new Map<String, Object>()
			);
			if (!(rawResponse instanceof Map<String, Object>)) {
				throw new AuraHandledException('La validación MIPYMES no devolvió una respuesta válida.');
			}

			Map<String, Object> response = (Map<String, Object>) rawResponse;
			Object clasificacionValida = response.get(RESPUESTA_CLASIFICACION_MIPYMES_VALIDA);
			if (clasificacionValida == null) {
				throw new AuraHandledException('La validación MIPYMES no devolvió un resultado.');
			}

			return Boolean.valueOf(String.valueOf(clasificacionValida));
		} catch (Exception exceptionInstance) {
			throw new AuraHandledException('No se pudo validar la clasificación MIPYMES de la solicitud.');
		}
	}

	@AuraEnabled(cacheable=true)
	public static Map<String, Object> getApprovalContext(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Id requerido');
		}

		Map<String, Object> result = new Map<String, Object>{
			'hasActiveApproval' => false,
			'workItemCount' => 0,
			'currentApproverName' => '',
			'currentApproverId' => null,
			'currentApproverType' => '',
			'isCurrentUserQueueMember' => false,
			'currentProcessDefinitionDeveloperName' => ''
		};

		List<ProcessInstanceWorkitem> workItems = [
			SELECT Id, ActorId, Actor.Name, Actor.Type, ProcessInstanceId
			FROM ProcessInstanceWorkitem
			WHERE ProcessInstance.TargetObjectId = :residentialLoanApplicationId
			ORDER BY CreatedDate DESC
		];

		result.put('hasActiveApproval', !workItems.isEmpty());
		result.put('workItemCount', workItems.size());

		if (!workItems.isEmpty() && workItems[0].ActorId != null) {
			Id actorId = workItems[0].ActorId;
			String actorName = workItems[0].Actor != null ? workItems[0].Actor.Name : '';
			String actorType = workItems[0].Actor != null ? String.valueOf(workItems[0].Actor.Type) : '';
			String currentProcessDefinitionDeveloperName = getProcessDefinitionDeveloperName(workItems[0].ProcessInstanceId);

			result.put('currentApproverName', actorName);
			result.put('currentApproverId', actorId);
			result.put('currentApproverType', actorType);
			result.put('currentProcessDefinitionDeveloperName', currentProcessDefinitionDeveloperName);

			if (String.valueOf(actorId).startsWith('00G')) {
				result.put('isCurrentUserQueueMember', isUserMemberOfGroupRecursive(actorId, UserInfo.getUserId()));
			}
		}

		return result;
	}

	@AuraEnabled(cacheable=true)
	public static List<Map<String, String>> getAssignableUsers() {
		validarPermisoAdministrador('Solo un administrador puede consultar usuarios para reasignar aprobaciones.');
		List<Map<String, String>> options = new List<Map<String, String>>();

		for (User u : [
			SELECT Id, Name
			FROM User
			WHERE IsActive = TRUE
			ORDER BY Name
		]) {
			options.add(new Map<String, String>{ 'label' => u.Name, 'value' => u.Id });
		}

		return options;
	}

	@AuraEnabled(cacheable=true)
	public static Map<String, Object> getDocumentacionContratosContext(Id residentialLoanApplicationId) {
		return FSC_DocumentacionContratosService.getContexto(residentialLoanApplicationId);
	}

	@AuraEnabled
	public static void enviarDocumentacionContratos(Id residentialLoanApplicationId) {
		FSC_DocumentacionContratosService.enviarARevision(residentialLoanApplicationId);
	}

	@AuraEnabled
	public static void solicitarDocumentacionContratos(Id residentialLoanApplicationId, String pedido) {
		FSC_DocumentacionContratosService.solicitarDocumentacion(residentialLoanApplicationId, pedido);
	}

	@AuraEnabled(cacheable=true)
	public static Map<String, Object> getPagaresContext(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, FSC_UsuarioPagaresYContratos__c, FSC_UsuarioPagaresYContratos__r.Name
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		Boolean canManagePagares = FSC_RoleAuthorizationService.canManagePagares(rla.FSC_UsuarioPagaresYContratos__c);

		return new Map<String, Object>{
			'assignedUserId' => rla.FSC_UsuarioPagaresYContratos__c,
			'assignedUserName' => rla.FSC_UsuarioPagaresYContratos__r != null ? rla.FSC_UsuarioPagaresYContratos__r.Name : '',
			'canGeneratePagare' => canManagePagares
		};
	}

	@AuraEnabled(cacheable=true)
	public static List<Map<String, String>> getFormaDesembolsoOptions() {
		List<Map<String, String>> options = new List<Map<String, String>>();
		Schema.DescribeFieldResult fieldDescribe = ResidentialLoanApplication.FSC_FormaDeDesembolso__c.getDescribe();

		for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
			if (entry.isActive()) {
				options.add(new Map<String, String>{ 'label' => entry.getLabel(), 'value' => entry.getValue() });
			}
		}

		return options;
	}

	@AuraEnabled(cacheable=true)
	public static List<Map<String, String>> getCuentasDesembolsoOptions(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, AccountId
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		List<Map<String, String>> options = new List<Map<String, String>>();
		if (rla.AccountId == null) {
			return options;
		}

		for (FinServ__FinancialAccount__c financialAccount : [
			SELECT Id, Name, FinServ__FinancialAccountNumber__c
			FROM FinServ__FinancialAccount__c
			WHERE
				FinServ__PrimaryOwner__c = :rla.AccountId
				AND (RecordType.DeveloperName = 'CheckingAccount'
				OR RecordType.DeveloperName = 'SavingsAccount')
			ORDER BY Name
		]) {
			options.add(
				new Map<String, String>{ 'label' => buildCuentaDesembolsoLabel(financialAccount), 'value' => String.valueOf(financialAccount.Id) }
			);
		}

		return options;
	}

	@AuraEnabled
	public static void guardarFormaDesembolsoGestionPlanillas(Id residentialLoanApplicationId, String formaDeDesembolso, Id financialAccountId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (String.isBlank(formaDeDesembolso)) {
			throw new AuraHandledException('Forma de desembolso requerida.');
		}

		validateCurrentUserCanCompleteGestionPlanillas(residentialLoanApplicationId);
		validateFormaDeDesembolsoValue(formaDeDesembolso);
		updateFormaDeDesembolso(residentialLoanApplicationId, formaDeDesembolso, financialAccountId);
	}

	@AuraEnabled
	public static void guardarDatosPagare(Id residentialLoanApplicationId, String actoNumeroPagare, String numeroFolioPagare) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (String.isBlank(actoNumeroPagare) || String.isBlank(numeroFolioPagare)) {
			throw new AuraHandledException('Debe completar los campos del pagaré.');
		}

		validateCurrentUserCanCompletePagares(residentialLoanApplicationId);
		Decimal numeroFolioPagareValue;
		try {
			numeroFolioPagareValue = Decimal.valueOf(numeroFolioPagare.trim());
		} catch (Exception ex) {
			throw new AuraHandledException('Número de folio pagaré debe ser numérico.');
		}

		update new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_ActoNumeroPagare__c = actoNumeroPagare.trim(),
			FSC_NumeroFolioPagare__c = numeroFolioPagareValue
		);
	}

	@AuraEnabled
	public static void guardarDatosPagareComplementario(Id residentialLoanApplicationId, String numeroPrestamoPagare) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		validateCurrentUserCanCompletePagares(residentialLoanApplicationId);
		update new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_Numero_Prestamo_Pagare__c = String.isBlank(numeroPrestamoPagare) ? null : numeroPrestamoPagare.trim()
		);
	}

	@AuraEnabled
	public static Boolean validateChecklistApprovalReadiness(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		validateChecklistApprovalReadinessInternal(residentialLoanApplicationId);
		return true;
	}

	@AuraEnabled
	public static void validarDocumentacionAnalista(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		validateCurrentUserCanActOnApproval(residentialLoanApplicationId, PROCESO_ANALISTA);
		validateChecklistApprovalReadinessInternal(residentialLoanApplicationId);

		update new ResidentialLoanApplication(Id = residentialLoanApplicationId, FSC_DocumentacionValidadaAnalista__c = true);
	}

	@AuraEnabled
	public static void aprobarProcesoActual(Id residentialLoanApplicationId, String comentario) {
		aprobarProcesoActualInterno(residentialLoanApplicationId, comentario, null, false);
	}

	@AuraEnabled
	public static void aprobarProcesoActualConHistorial(Id residentialLoanApplicationId, String comentario, String historialPago) {
		aprobarProcesoActualInterno(residentialLoanApplicationId, comentario, historialPago, true);
	}

	private static void aprobarProcesoActualInterno(
		Id residentialLoanApplicationId,
		String comentario,
		String historialPago,
		Boolean exigirHistorialAnalista
	) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (String.isBlank(comentario)) {
			throw new AuraHandledException('Comentario requerido.');
		}
		if (comentario.length() > 255) {
			throw new AuraHandledException('Comentario máximo 255 caracteres.');
		}
		ResidentialLoanApplication rlaAntesAprobacion = [
			SELECT
				Id,
				FSC_Subestado__c,
				FSC_DebeRevisarComite__c,
				FSC_Aprobado_con_Condiciones__c,
				FSC_Monto__c,
				FSC_Plazo_meses__c,
				FSC_TasaInteres__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			WITH USER_MODE
			LIMIT 1
		];
		FSC_GarantiaFormalizacionService.validarAprobacionArchivoCustodia(residentialLoanApplicationId, rlaAntesAprobacion.FSC_Subestado__c);

		Boolean esProcesoAnalista = hasActiveApprovalForProcess(residentialLoanApplicationId, PROCESO_ANALISTA);
		Boolean esProcesoBancaSeguro = hasActiveApprovalForProcess(residentialLoanApplicationId, PROCESO_BANCA_SEGURO);
		if (esProcesoBancaSeguro) {
			validarPermisoBancaSeguroOAdministrador();
			validateCurrentUserCanActOnApproval(residentialLoanApplicationId, PROCESO_BANCA_SEGURO);
		}
		if (esProcesoAnalista) {
			if (exigirHistorialAnalista && String.isBlank(historialPago)) {
				throw new AuraHandledException('Historial de pago requerido.');
			}
			if (exigirHistorialAnalista && historialPago.length() > 5000) {
				throw new AuraHandledException('Historial de pago máximo 5000 caracteres.');
			}
			validateAnalystDecisionReadiness(residentialLoanApplicationId);
		} else {
			validateChecklistApprovalReadinessInternal(residentialLoanApplicationId);
		}

		Boolean esAprobacionSimpleComite =
			rlaAntesAprobacion.FSC_DebeRevisarComite__c == true &&
			rlaAntesAprobacion.FSC_Aprobado_con_Condiciones__c != true &&
			normalize(rlaAntesAprobacion.FSC_Subestado__c) == SUBESTADO_ANALISIS_CREDITO_NORM;

		List<ProcessInstanceWorkitem> workItems = getActiveWorkItems(residentialLoanApplicationId);
		if (workItems.isEmpty()) {
			System.debug('No hay proceso de aprobación activo.');
		}

		for (ProcessInstanceWorkitem wi : workItems) {
			Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
			req.setWorkitemId(wi.Id);
			req.setAction('Approve');
			req.setComments(comentario.trim());

			Approval.ProcessResult result = Approval.process(req);

			if (!result.isSuccess()) {
				throw new AuraHandledException('No se pudo aprobar el proceso de aprobación actual.' + getApprovalErrorDetail(result));
			}
		}

		if (esProcesoAnalista) {
			ResidentialLoanApplication actualizacionAnalista = new ResidentialLoanApplication(
				Id = residentialLoanApplicationId,
				FSC_Recomendaciones__c = comentario.trim()
			);
			if (exigirHistorialAnalista) {
				actualizacionAnalista.FSC_HistorialPago__c = historialPago.trim();
			}
			update actualizacionAnalista;
		}

		ResidentialLoanApplication rla = [
			SELECT Id, FSC_Subestado__c, FSC_DebeRevisarComite__c, FSC_SolicitudAprobadaPorComite__c, FSC_FechaYHoraAprobacionComite__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (esAprobacionSimpleComite && !workItems.isEmpty()) {
			rla.FSC_SolicitudAprobadaPorComite__c = true;
			rla.FSC_FechaYHoraAprobacionComite__c = System.now();
			// Una aprobacion simple conserva las condiciones solicitadas.
			rla.FSC_MontoAprobado__c = rlaAntesAprobacion.FSC_Monto__c;
			rla.FSC_PlazoMesesAprobado__c = rlaAntesAprobacion.FSC_Plazo_meses__c == null
				? null
				: Integer.valueOf(rlaAntesAprobacion.FSC_Plazo_meses__c);
			rla.FSC_TasaInteresAprobada__c = rlaAntesAprobacion.FSC_TasaInteres__c;

			FSC_CreditoAprobadoLockService.iniciarDecisionComite();
			try {
				update rla;
			} finally {
				FSC_CreditoAprobadoLockService.finalizarDecisionComite();
			}
		}
	}

	@AuraEnabled
	public static void rechazarBancaSeguro(Id residentialLoanApplicationId, String motivo, String comentario) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (String.isBlank(motivo) || motivo.trim().length() > 255) {
			throw new AuraHandledException('Ingrese un motivo de hasta 255 caracteres.');
		}
		if (String.isBlank(comentario) || comentario.trim().length() > 2000) {
			throw new AuraHandledException('Ingrese un comentario de hasta 2.000 caracteres.');
		}

		validarPermisoBancaSeguroOAdministrador();
		validateCurrentUserCanActOnApproval(residentialLoanApplicationId, PROCESO_BANCA_SEGURO);

		Database.update(
			new ResidentialLoanApplication(
				Id = residentialLoanApplicationId,
				FSC_MotivoRechazoBancaSeguro__c = motivo.trim(),
				FSC_ComentarioBancaSeguro__c = comentario.trim()
			),
			AccessLevel.USER_MODE
		);

		ProcessInstanceWorkitem workItem = getActiveWorkItemForProcess(residentialLoanApplicationId, PROCESO_BANCA_SEGURO);
		Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
		request.setWorkitemId(workItem.Id);
		request.setAction('Reject');
		request.setComments(motivo.trim() + ' - ' + comentario.trim());

		Approval.ProcessResult result = Approval.process(request);
		if (!result.isSuccess()) {
			throw new AuraHandledException('No se pudo registrar la decisión de Banca Seguro.' + getApprovalErrorDetail(result));
		}
	}

	private static String getApprovalErrorDetail(Approval.ProcessResult result) {
		List<String> messages = new List<String>();
		if (result != null && result.getErrors() != null) {
			for (Database.Error approvalError : result.getErrors()) {
				if (approvalError != null && !String.isBlank(approvalError.getMessage())) {
					messages.add(approvalError.getMessage());
				}
			}
		}

		return messages.isEmpty() ? '' : ' Detalle: ' + String.join(messages, ' | ');
	}

	@AuraEnabled
	public static void rechazarProcesoActual(Id residentialLoanApplicationId, String motivo, String motivoDeRechazo) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (String.isBlank(motivo)) {
			throw new AuraHandledException('Motivo requerido.');
		}
		if (motivo.length() > 255) {
			throw new AuraHandledException('Motivo máximo 255 caracteres.');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, RecordType.DeveloperName
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];
		String recordTypeDeveloperName = rla.RecordType != null ? rla.RecordType.DeveloperName : null;
		Boolean isPymeRla = recordTypeDeveloperName == RT_SOLICITUD_CREDITO_PYME;

		if (isPymeRla && String.isBlank(motivoDeRechazo)) {
			throw new AuraHandledException('Motivo de rechazo requerido.');
		}

		List<ProcessInstanceWorkitem> workItems = getActiveWorkItems(residentialLoanApplicationId);
		if (workItems.isEmpty()) {
			System.debug('No hay proceso de aprobación activo.');
		}

		for (ProcessInstanceWorkitem wi : workItems) {
			Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
			req.setWorkitemId(wi.Id);
			req.setAction('Reject');
			req.setComments(motivo);

			Approval.ProcessResult result = Approval.process(req);

			if (!result.isSuccess()) {
				throw new AuraHandledException('No se pudo rechazar el proceso de aprobación actual.' + getApprovalErrorDetail(result));
			}
		}

		ResidentialLoanApplication upd = new ResidentialLoanApplication(Id = residentialLoanApplicationId);
		if (isPymeRla) {
			upd.FSC_MotivosDeRechazo__c = motivoDeRechazo.trim();
		}

		aplicarObservacionPorPermiso(upd, motivo);

		update upd;
	}

	@AuraEnabled
	public static void reasignarProcesoActual(Id residentialLoanApplicationId, Id newActorId) {
		validarPermisoAdministrador('Solo un administrador puede reasignar procesos de aprobación.');
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (newActorId == null) {
			throw new AuraHandledException('Debe seleccionar un usuario.');
		}

		List<ProcessInstanceWorkitem> workItems = getActiveWorkItems(residentialLoanApplicationId);
		if (workItems.isEmpty()) {
			System.debug('No hay proceso de aprobación activo.');
		}

		for (ProcessInstanceWorkitem wi : workItems) {
			Boolean success = false;

			try {
				Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
				req.setWorkitemId(wi.Id);
				req.setAction('Reassign');
				req.setComments('Reasignado desde acciones.');
				req.setNextApproverIds(new List<Id>{ newActorId });

				Approval.ProcessResult result = Approval.process(req);
				success = result != null && result.isSuccess();
			} catch (Exception ex) {
				success = false;
			}

			if (!success) {
				try {
					ProcessInstanceWorkitem wiUpd = new ProcessInstanceWorkitem(Id = wi.Id, ActorId = newActorId);
					update wiUpd;
					success = true;
				} catch (Exception ex2) {
					throw new AuraHandledException('No se pudo reasignar el proceso de aprobación actual. ' + ex2.getMessage());
				}
			}
		}
	}

	@AuraEnabled
	public static String reintentarListas(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Id requerido');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, AccountId
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		Map<String, Object> inputMap = new Map<String, Object>{ 'accountId' => rla.AccountId, 'solicitudDeCreditoId' => rla.Id };

		Map<String, Object> options = new Map<String, Object>();

		Object response = omnistudio.IntegrationProcedureService.runIntegrationService('FSC_ValidaListasControl', inputMap, options);

		if (response == null) {
			return JSON.serialize(
				new Map<String, Object>{
					'success' => false,
					'apiExecuted' => false,
					'message' => 'El procedimiento de validación no devolvió una respuesta.'
				}
			);
		}

		return JSON.serialize(response);
	}

	@AuraEnabled
	public static String reintentarBuro(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Id requerido');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, RecordType.DeveloperName
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (!FSC_BuroConfigService.isMotorEncendido(rla.RecordType?.DeveloperName)) {
			ResidentialLoanApplication upd = new ResidentialLoanApplication(Id = residentialLoanApplicationId);
			FSC_BuroConfigService.aplicarMotorApagado(upd);
			update upd;
			return FSC_BuroConfigService.RESULTADO_REFERIDO;
		}

		if (rla.RecordType != null && rla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_PYME') {
			Map<String, Object> inputMap = new Map<String, Object>{ 'residentialLoanApplicationId' => residentialLoanApplicationId };

			Object response = omnistudio.IntegrationProcedureService.runIntegrationService(
				'FSC_APIBuroCreditoPyme',
				inputMap,
				new Map<String, Object>()
			);

			return response != null ? String.valueOf(response) : 'OK';
		}

		FSC_LoanDecisionAPI.callAPI(new List<Id>{ residentialLoanApplicationId });
		return 'OK';
	}

	@AuraEnabled
	public static String validarCreacionEnAbanks(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		validateCurrentUserCanActOnApproval(residentialLoanApplicationId, PROCESO_VALIDACION_ABANKS);

		ResidentialLoanApplication rla = [
			SELECT FSC_Subestado__c, FSC_FormaDeDesembolso__c, FSC_NumeroPrestamoAbanks__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (
			rla.FSC_Subestado__c != SUBESTADO_CREACION_CREDITO ||
			rla.FSC_FormaDeDesembolso__c != FORMA_DESEMBOLSO_CUENTA_AHORRO ||
			String.isBlank(rla.FSC_NumeroPrestamoAbanks__c)
		) {
			throw new AuraHandledException('La solicitud no esta lista para validar la creacion del credito en ABANKS.');
		}

		ProcessInstanceWorkitem workItem = getActiveWorkItemForProcess(residentialLoanApplicationId, PROCESO_VALIDACION_ABANKS);
		Approval.ProcessWorkitemRequest request = new Approval.ProcessWorkitemRequest();
		request.setWorkitemId(workItem.Id);
		request.setAction('Approve');
		request.setComments('Credito validado correctamente en ABANKS.');

		Approval.ProcessResult result = Approval.process(request);
		if (!result.isSuccess()) {
			throw new AuraHandledException('No se pudo completar la validacion en ABANKS.');
		}

		return 'Credito validado en ABANKS.';
	}

	public class ReintentoPrestamoResult {
		@AuraEnabled
		public Boolean success { get; set; }

		@AuraEnabled
		public String message { get; set; }

		public ReintentoPrestamoResult(Boolean success, String message) {
			this.success = success;
			this.message = message;
		}
	}

	@AuraEnabled
	public static ReintentoPrestamoResult reintentarCreacionPrestamo(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, FSC_Subestado__c, FSC_FormaDeDesembolso__c, FSC_lineaFinanciera__c, FSC_subAplicacion__c, FSC_ClaveProducto__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (rla.FSC_Subestado__c != SUBESTADO_CREACION_CREDITO) {
			throw new AuraHandledException('La solicitud debe estar en Creacion de credito para reintentar.');
		}
		if (rla.FSC_FormaDeDesembolso__c != FORMA_DESEMBOLSO_CUENTA_AHORRO) {
			throw new AuraHandledException('La forma de desembolso debe ser Cuenta de ahorro.');
		}

		FSC_APIPrestamoProductos.Input productoInput = new FSC_APIPrestamoProductos.Input();
		productoInput.lineaFinanciera = rla.FSC_lineaFinanciera__c;
		productoInput.subAplicacion = rla.FSC_subAplicacion__c;
		productoInput.claveProducto = rla.FSC_ClaveProducto__c;

		List<FSC_APIPrestamoProductos.Output> productoOutputs = FSC_APIPrestamoProductos.run(
			new List<FSC_APIPrestamoProductos.Input>{ productoInput }
		);
		FSC_APIPrestamoProductos.Output productoOutput = productoOutputs == null || productoOutputs.isEmpty() ? null : productoOutputs[0];

		if (productoOutput == null) {
			throw new AuraHandledException('No se pudo consultar el producto del prestamo.');
		}
		if (productoOutput.success != true) {
			throw new AuraHandledException(
				String.isBlank(productoOutput.message) ? 'No se pudo consultar el producto del prestamo.' : productoOutput.message
			);
		}
		if (productoOutput.found != true || String.isBlank(productoOutput.productoJson)) {
			throw new AuraHandledException(
				String.isBlank(productoOutput.message)
					? 'No se encontro producto para la linea financiera y sub aplicacion indicadas.'
					: productoOutput.message
			);
		}

		User currentUser = [
			SELECT FSC_CodigoAbanks__c, USE_Oficina__c
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];

		FSC_APIPrestamoPrestamos.Input prestamoInput = new FSC_APIPrestamoPrestamos.Input();
		prestamoInput.residentialLoanApplicationId = residentialLoanApplicationId;
		prestamoInput.productoJson = productoOutput.productoJson;
		prestamoInput.codigoUsuario = currentUser.FSC_CodigoAbanks__c;
		prestamoInput.codigoAgencia = currentUser.USE_Oficina__c;
		prestamoInput.codigoEjecutivo = 'ABANKS';

		List<FSC_APIPrestamoPrestamos.Output> prestamoOutputs = FSC_APIPrestamoPrestamos.run(
			new List<FSC_APIPrestamoPrestamos.Input>{ prestamoInput }
		);
		FSC_APIPrestamoPrestamos.Output prestamoOutput = prestamoOutputs == null || prestamoOutputs.isEmpty() ? null : prestamoOutputs[0];

		if (prestamoOutput == null) {
			return new ReintentoPrestamoResult(false, 'No se pudo crear el prestamo en ABANKS.');
		}
		if (prestamoOutput.success != true) {
			return new ReintentoPrestamoResult(
				false,
				String.isBlank(prestamoOutput.message) ? 'No se pudo crear el prestamo en ABANKS.' : prestamoOutput.message
			);
		}

		return new ReintentoPrestamoResult(true, String.isBlank(prestamoOutput.message) ? 'Prestamo creado en ABANKS.' : prestamoOutput.message);
	}

	@AuraEnabled
	public static String reintentarDesembolso(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, FSC_Subestado__c, FSC_FormaDeDesembolso__c, FSC_FlagErrorAPIDesembolso__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (rla.FSC_FlagErrorAPIDesembolso__c != true) {
			throw new AuraHandledException('No hay error de desembolso para reintentar.');
		}
		if (rla.FSC_Subestado__c != SUBESTADO_DESEMBOLSO) {
			throw new AuraHandledException('La solicitud debe estar en Desembolso para reintentar el desembolso.');
		}
		if (rla.FSC_FormaDeDesembolso__c != FORMA_DESEMBOLSO_CUENTA_AHORRO) {
			throw new AuraHandledException('La forma de desembolso debe ser Cuenta de ahorro.');
		}

		User currentUser = [
			SELECT FSC_CodigoAbanks__c, USE_Oficina__c
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];

		FSC_APIPrestamoDesembolso.Input desembolsoInput = new FSC_APIPrestamoDesembolso.Input();
		desembolsoInput.residentialLoanApplicationId = residentialLoanApplicationId;
		desembolsoInput.codigoUsuario = currentUser.FSC_CodigoAbanks__c;
		desembolsoInput.codigoAgencia = currentUser.USE_Oficina__c;

		List<FSC_APIPrestamoDesembolso.Output> outputs = FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{ desembolsoInput });
		FSC_APIPrestamoDesembolso.Output output = outputs == null || outputs.isEmpty() ? null : outputs[0];

		if (output == null) {
			throw new AuraHandledException('No se pudo ejecutar el desembolso en ABANKS.');
		}
		if (output.success != true) {
			throw new AuraHandledException(String.isBlank(output.message) ? 'No se pudo ejecutar el desembolso en ABANKS.' : output.message);
		}

		return String.isBlank(output.message) ? 'Desembolso creado en ABANKS.' : output.message;
	}

	@AuraEnabled
	public static void cancelarAprobacion(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Id requerido');
		}

		List<ProcessInstanceWorkitem> workItems = getActiveWorkItems(residentialLoanApplicationId);

		if (workItems.isEmpty()) {
			System.debug('No hay proceso de aprobación activo.');
		}

		for (ProcessInstanceWorkitem wi : workItems) {
			Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
			req.setWorkitemId(wi.Id);
			req.setAction('Removed');
			req.setComments('Proceso cancelado desde sistema.');

			Approval.ProcessResult result = Approval.process(req);

			if (!result.isSuccess()) {
				throw new AuraHandledException('No se pudo cancelar el proceso.');
			}
		}
	}

	@AuraEnabled
	public static void aprobarConCondicion(
		Id residentialLoanApplicationId,
		Decimal montoAprobado,
		Integer plazoMesesAprobado,
		Decimal tasaInteresAprobada,
		String otrasCondicionesComite
	) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (otrasCondicionesComite != null && otrasCondicionesComite.length() > 2000) {
			throw new AuraHandledException('Otras condiciones máximo 2000 caracteres.');
		}

		ResidentialLoanApplication upd = new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_MontoAprobado__c = montoAprobado,
			FSC_PlazoMesesAprobado__c = plazoMesesAprobado,
			FSC_TasaInteresAprobada__c = tasaInteresAprobada,
			FSC_OtrasCondicionesComite__c = otrasCondicionesComite,
			FSC_Aprobado_con_Condiciones__c = true,
			FSC_SolicitudAprobadaPorComite__c = true,
			FSC_FechaYHoraAprobacionComite__c = System.now()
		);

		update upd;
	}

	@AuraEnabled
	public static void devolverAOficial(Id residentialLoanApplicationId, String motivo) {
		if (residentialLoanApplicationId == null)
			throw new AuraHandledException('Solicitud requerida.');
		if (String.isBlank(motivo))
			throw new AuraHandledException('Motivo requerido.');
		if (motivo.length() > 255)
			throw new AuraHandledException('Motivo excede 255 caracteres.');

		validateCurrentUserCanActOnApproval(residentialLoanApplicationId, null);

		String permisoOrigen = obtenerPermisoRolActual();

		if (shouldUsePrivilegedSupervisorFallback(residentialLoanApplicationId)) {
			FSC_RlaApprovalAdminClient.returnToBusiness(residentialLoanApplicationId, motivo, permisoOrigen);
			return;
		}

		FSC_RlaApprovalAdminService.returnToBusiness(residentialLoanApplicationId, motivo, permisoOrigen);
	}

	@AuraEnabled
	public static void devolverAAnalista(Id residentialLoanApplicationId, String motivo) {
		if (residentialLoanApplicationId == null)
			throw new AuraHandledException('Solicitud requerida.');
		if (String.isBlank(motivo))
			throw new AuraHandledException('Motivo requerido.');
		if (motivo.length() > 255)
			throw new AuraHandledException('Motivo excede 255 caracteres.');

		if (shouldUsePrivilegedSupervisorFallback(residentialLoanApplicationId)) {
			FSC_RlaApprovalAdminClient.returnToAnalyst(residentialLoanApplicationId, motivo);
			return;
		}

		FSC_RlaApprovalAdminService.returnToAnalyst(residentialLoanApplicationId, motivo);
	}

	@AuraEnabled
	public static void enviarRevisionSupervisor(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		validateAnalystDecisionReadiness(residentialLoanApplicationId);

		if (shouldUsePrivilegedSupervisorFallback(residentialLoanApplicationId)) {
			FSC_RlaApprovalAdminClient.sendToSupervisor(residentialLoanApplicationId);
			return;
		}

		FSC_RlaApprovalAdminService.sendToSupervisor(residentialLoanApplicationId);
	}

	@TestVisible
	private static Boolean shouldUsePrivilegedSupervisorFallback(Id residentialLoanApplicationId) {
		if (testForcePrivilegedSupervisorReview) {
			return true;
		}

		Id currentUserId = UserInfo.getUserId();
		if (FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR)) {
			return false;
		}

		List<ProcessInstance> activeProcesses = [
			SELECT Id, SubmittedById
			FROM ProcessInstance
			WHERE TargetObjectId = :residentialLoanApplicationId AND Status = 'Pending'
			ORDER BY CreatedDate DESC
			LIMIT 1
		];

		if (activeProcesses.isEmpty()) {
			return false;
		}

		return activeProcesses[0].SubmittedById != currentUserId;
	}

	@AuraEnabled
	public static void marcarFirmaCompletaYPasarADocDesembolso(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		String siguienteSubestado = FSC_GarantiaFormalizacionService.resolverSubestadoPosteriorAFirmas(new Set<Id>{ residentialLoanApplicationId })
			.get(residentialLoanApplicationId);
		ResidentialLoanApplication upd = new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_Firma_completada__c = true,
			FSC_Subestado__c = siguienteSubestado
		);

		update upd;
	}

	@AuraEnabled
	public static void marcarEnviadoAFirmar(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		update new ResidentialLoanApplication(Id = residentialLoanApplicationId, FSC_EnviadoAFirmar__c = true);
	}

	@AuraEnabled
	public static void marcarDocumentosFirmadosFisicamente(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		update new ResidentialLoanApplication(Id = residentialLoanApplicationId, FSC_DocumentosFirmadosFis__c = true);
		ResidentialLoanApplication rla = [
			SELECT Id, RecordType.DeveloperName
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];
		String recordTypeDeveloperName = rla.RecordType == null ? null : rla.RecordType.DeveloperName;
		if (!FSC_ConfiguracionFirmaDocumentosService.hasDocumentosFirmaDigital(recordTypeDeveloperName)) {
			String siguienteSubestado = FSC_GarantiaFormalizacionService.resolverSubestadoPosteriorAFirmas(
					new Set<Id>{ residentialLoanApplicationId }
				)
				.get(residentialLoanApplicationId);
			update new ResidentialLoanApplication(
				Id = residentialLoanApplicationId,
				FSC_Firma_completada__c = true,
				FSC_Subestado__c = siguienteSubestado
			);
			return;
		}

		FSC_ContentVersionTriggerHandler.actualizarSiFirmasCompletas(new Set<Id>{ residentialLoanApplicationId });
	}

	@AuraEnabled(cacheable=false)
	public static FirmaValidationState getFirmaValidationState(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		FirmaValidationState state = new FirmaValidationState();

		Boolean hasPhysicalField = ResidentialLoanApplication.SObjectType.getDescribe().fields.getMap().containsKey('FSC_DocumentosFirmadosFis__c');
		String soql = 'SELECT Id, RecordType.DeveloperName';
		if (hasPhysicalField) {
			soql += ', FSC_DocumentosFirmadosFis__c';
		}
		soql += ' FROM ResidentialLoanApplication WHERE Id = :residentialLoanApplicationId LIMIT 1';

		ResidentialLoanApplication rla = (ResidentialLoanApplication) Database.query(soql);
		String recordTypeDeveloperName = rla.RecordType == null ? null : rla.RecordType.DeveloperName;
		Boolean digitalRequired = FSC_ConfiguracionFirmaDocumentosService.hasDocumentosFirmaDigital(recordTypeDeveloperName);
		state.digitalComplete = !digitalRequired || tieneFirmasDigitalesCompletas(residentialLoanApplicationId);
		state.physicalRequired = FSC_ConfiguracionFirmaDocumentosService.hasDocumentosFirmaFisica(recordTypeDeveloperName);
		state.physicalConfirmed = hasPhysicalField && Boolean.valueOf(rla.get('FSC_DocumentosFirmadosFis__c'));
		state.shouldAskPhysicalConfirmation = state.digitalComplete && state.physicalRequired && !state.physicalConfirmed;
		return state;
	}

	private static Boolean tieneFirmasDigitalesCompletas(Id residentialLoanApplicationId) {
		Set<Id> latestVersionIds = new Set<Id>();
		for (ContentDocumentLink link : [
			SELECT ContentDocument.LatestPublishedVersionId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :residentialLoanApplicationId
		]) {
			if (link.ContentDocument.LatestPublishedVersionId != null) {
				latestVersionIds.add(link.ContentDocument.LatestPublishedVersionId);
			}
		}

		if (latestVersionIds.isEmpty()) {
			return false;
		}

		Integer documentosDigitalesEnviados = 0;
		Boolean tieneArchivoFirmadoDescargado = false;

		for (ContentVersion document : [
			SELECT Id, Title, FSC_EnviarDocumento__c, FSC_FechaEnvioFirma__c, FSC_Firmado__c
			FROM ContentVersion
			WHERE Id IN :latestVersionIds
		]) {
			if (isDocumentoDigitalEnviado(document)) {
				documentosDigitalesEnviados++;
				if (document.FSC_Firmado__c != true) {
					return false;
				}
			}

			if (isArchivoFirmadoDescargado(document)) {
				tieneArchivoFirmadoDescargado = true;
			}
		}

		if (documentosDigitalesEnviados > 0) {
			return true;
		}

		return tieneArchivoFirmadoDescargado;
	}

	private static Boolean isDocumentoDigitalEnviado(ContentVersion version) {
		return version != null && version.FSC_EnviarDocumento__c == true && version.FSC_FechaEnvioFirma__c != null;
	}

	private static Boolean isArchivoFirmadoDescargado(ContentVersion version) {
		if (version == null || version.FSC_Firmado__c != true || String.isBlank(version.Title)) {
			return false;
		}

		return version.Title.trim().toLowerCase().endsWith('_firmado');
	}

	public class FirmaValidationState {
		@AuraEnabled
		public Boolean digitalComplete;
		@AuraEnabled
		public Boolean physicalRequired;
		@AuraEnabled
		public Boolean physicalConfirmed;
		@AuraEnabled
		public Boolean shouldAskPhysicalConfirmation;
	}

	@AuraEnabled
	public static void marcarDocCompletaDesembolso(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		validateChecklistUploadCompletenessInternal(residentialLoanApplicationId);

		ResidentialLoanApplication upd = new ResidentialLoanApplication(Id = residentialLoanApplicationId, FSC_Doc_Completa_Desembolso__c = true);

		update upd;
	}

	@AuraEnabled
	public static void marcarCreadoEnAbanks(Id residentialLoanApplicationId) {
		FSC_CapturaOperacionesService.guardarCaptura(residentialLoanApplicationId, null, false, false, false);
	}

	@AuraEnabled
	public static void marcarDesembolsado(Id residentialLoanApplicationId) {
		FSC_CapturaOperacionesService.confirmarDesembolso(residentialLoanApplicationId, null, null);
	}

	@AuraEnabled(cacheable=true)
	public static Map<String, Object> getCapturaOperacionesContext(Id residentialLoanApplicationId) {
		return FSC_CapturaOperacionesService.contexto(residentialLoanApplicationId);
	}

	@AuraEnabled
	public static void guardarCapturaAbanks(
		Id residentialLoanApplicationId,
		String numeroPrestamo,
		Boolean credito,
		Boolean garantias,
		Boolean seguros
	) {
		FSC_CapturaOperacionesService.guardarCaptura(residentialLoanApplicationId, numeroPrestamo, credito, garantias, seguros);
	}

	@AuraEnabled
	public static void confirmarDesembolsoManual(Id residentialLoanApplicationId, List<Id> amortizacion, List<Id> recibos) {
		FSC_CapturaOperacionesService.confirmarDesembolso(residentialLoanApplicationId, amortizacion, recibos);
	}

	@AuraEnabled
	public static List<Map<String, String>> getUsuariosCapturaOperaciones(Id residentialLoanApplicationId) {
		return FSC_CapturaOperacionesService.opcionesReasignacion(residentialLoanApplicationId);
	}

	@AuraEnabled
	public static void reasignarCapturaOperaciones(Id residentialLoanApplicationId, Id usuarioId, String etapa) {
		FSC_CapturaOperacionesService.reasignar(residentialLoanApplicationId, usuarioId, etapa);
	}

	@AuraEnabled
	public static List<Map<String, String>> getUsuariosPagares(Id residentialLoanApplicationId) {
		validarPermisoSupervisorOAdministrador();
		validarSolicitudEnGeneracionPagares(residentialLoanApplicationId);

		List<Map<String, String>> opciones = new List<Map<String, String>>();
		for (User usuario : obtenerUsuariosColaPagares()) {
			opciones.add(new Map<String, String>{ 'label' => usuario.Name, 'value' => usuario.Id });
		}
		return opciones;
	}

	@AuraEnabled
	public static void reasignarUsuarioPagares(Id residentialLoanApplicationId, Id usuarioId) {
		validarPermisoSupervisorOAdministrador();
		validarSolicitudEnGeneracionPagares(residentialLoanApplicationId);

		Boolean usuarioElegible = false;
		for (User usuario : obtenerUsuariosColaPagares()) {
			if (usuario.Id == usuarioId) {
				usuarioElegible = true;
			}
		}
		if (!usuarioElegible) {
			throw new AuraHandledException('Seleccione un usuario activo de la cola de Gestión de pagarés y contratos.');
		}

		update new ResidentialLoanApplication(Id = residentialLoanApplicationId, FSC_UsuarioPagaresYContratos__c = usuarioId);
	}

	private static void validarSolicitudEnGeneracionPagares(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		List<ResidentialLoanApplication> solicitudes = [
			SELECT FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];
		if (solicitudes.isEmpty() || solicitudes[0].FSC_Subestado__c != SUBESTADO_GENERACION_PAGARES) {
			throw new AuraHandledException('La solicitud no está en Generación de pagarés y plantillas.');
		}
	}

	private static List<User> obtenerUsuariosColaPagares() {
		List<Group> colas = [
			SELECT Id
			FROM Group
			WHERE Type = 'Queue' AND DeveloperName = :COLA_PAGARES_Y_CONTRATOS
			LIMIT 1
		];
		if (colas.isEmpty()) {
			return new List<User>();
		}

		Set<Id> miembros = FSC_RandomQueueApproverAction.collectCandidatePrincipalIds(colas[0].Id);
		return [SELECT Id, Name FROM User WHERE Id IN :miembros AND IsActive = TRUE ORDER BY Name];
	}

	@AuraEnabled
	public static void descartarArchivosDesembolso(List<Id> documentosIds) {
		FSC_CapturaOperacionesService.descartarArchivos(documentosIds);
	}

	private static void updateFormaDeDesembolso(Id residentialLoanApplicationId, String formaDeDesembolso, Id financialAccountId) {
		ResidentialLoanApplication upd = new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_FormaDeDesembolso__c = formaDeDesembolso
		);

		if (formaDeDesembolso == FORMA_DESEMBOLSO_CUENTA_AHORRO) {
			FinServ__FinancialAccount__c cuentaDesembolso = getValidCuentaDesembolso(residentialLoanApplicationId, financialAccountId);
			upd.FSC_NumeroCuentaDesembolso__c = cuentaDesembolso.FinServ__FinancialAccountNumber__c;
		} else {
			upd.FSC_NumeroCuentaDesembolso__c = null;
		}

		update upd;
	}

	@AuraEnabled
	public static void enviarAArchivoYCustodia(Id residentialLoanApplicationId, String motivo) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (String.isBlank(motivo)) {
			throw new AuraHandledException('Motivo requerido.');
		}
		if (motivo.length() > 2000) {
			throw new AuraHandledException('Motivo máximo 2000 caracteres.');
		}

		ResidentialLoanApplication upd = new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_Doc_Incompleta_Post_Desembolso__c = false,
			FSC_ObservacionesParaArchivo__c = motivo.trim()
		);

		update upd;
	}

	@AuraEnabled
	public static void solicitarExcepcionBuro(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		ResidentialLoanApplication upd = new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_SolicitaExcepcionParaRechazoDeBuro__c = true
		);

		update upd;
	}

	@AuraEnabled
	public static void marcarDocCompletaAnalisis(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		validateChecklistUploadCompletenessInternal(residentialLoanApplicationId);

		ResidentialLoanApplication upd = new ResidentialLoanApplication(Id = residentialLoanApplicationId, FSC_Doc_Completa_Analisis__c = true);

		update upd;
	}

	@AuraEnabled
	public static Id consultarEstadoFirma(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null || residentialLoanApplicationId.getSObjectType() != ResidentialLoanApplication.SObjectType) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		try {
			List<ResidentialLoanApplication> applications = [
				SELECT Id
				FROM ResidentialLoanApplication
				WHERE Id = :residentialLoanApplicationId
				WITH USER_MODE
				LIMIT 1
			];
			if (applications.isEmpty()) {
				throw new AuraHandledException('La solicitud no existe o no tiene acceso.');
			}
			return Database.executeBatch(
				new FSC_ConsultarEstadoEnvelopeBatch(residentialLoanApplicationId),
				FSC_ConsultarEstadoEnvelopeBatch.batchSize
			);
		} catch (QueryException e) {
			throw new AuraHandledException('No tiene permisos para consultar la solicitud.');
		}
	}

	@AuraEnabled
	public static void actualizarSubestadoGeneracionPagares(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		validarPermisoOficialOAdministrador();
		String comentarioAuditoria = construirComentarioDecisionCliente('Cliente acepta condiciones del comité.');

		// El recall de la aprobación del comité requiere admin; el Oficial lo ejecuta vía Named Credential.
		if (shouldUsePrivilegedSupervisorFallback(residentialLoanApplicationId)) {
			FSC_RlaApprovalAdminClient.clienteAceptaCondicion(residentialLoanApplicationId, comentarioAuditoria);
			return;
		}

		FSC_RlaApprovalAdminService.clienteAceptaCondicion(residentialLoanApplicationId, comentarioAuditoria);
	}

	@AuraEnabled
	public static void generarPagare(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		validateCurrentUserCanCompletePagares(residentialLoanApplicationId);

		FSC_GenerarPagarePDF_Action.Input inputItem = new FSC_GenerarPagarePDF_Action.Input();
		inputItem.residentialLoanApplicationId = residentialLoanApplicationId;

		List<FSC_GenerarPagarePDF_Action.Output> outputs = FSC_GenerarPagarePDF_Action.run(new List<FSC_GenerarPagarePDF_Action.Input>{ inputItem });

		FSC_GenerarPagarePDF_Action.Output outputItem = (outputs == null || outputs.isEmpty()) ? null : outputs[0];

		if (outputItem == null || outputItem.status != 'OK') {
			String message = (outputItem == null || String.isBlank(outputItem.message)) ? 'No se pudo generar el pagare.' : outputItem.message;
			throw new AuraHandledException(message);
		}
	}

	@AuraEnabled
	public static void rechazarPorCliente(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		validarPermisoOficialOAdministrador();
		String comentarioAuditoria = construirComentarioDecisionCliente('Cliente no acepta condiciones del comité.');

		if (shouldUsePrivilegedSupervisorFallback(residentialLoanApplicationId)) {
			FSC_RlaApprovalAdminClient.clienteRechazaCondicion(residentialLoanApplicationId, comentarioAuditoria);
			return;
		}

		FSC_RlaApprovalAdminService.clienteRechazaCondicion(residentialLoanApplicationId, comentarioAuditoria);
	}

	@TestVisible
	private static String construirComentarioDecisionCliente(String decision) {
		return decision + ' Ejecutado por: ' + UserInfo.getName() + ' (' + UserInfo.getUserId() + ').';
	}

	private static String validarTipoDocumentoAnalisis(String tipoDocumento) {
		String tipoNormalizado = String.isBlank(tipoDocumento) ? '' : tipoDocumento.trim().toUpperCase();
		if (
			tipoNormalizado != FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME &&
			tipoNormalizado != FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_CAPACIDAD
		) {
			throw new AuraHandledException('Tipo de documento de análisis no soportado.');
		}
		return tipoNormalizado;
	}

	private static ResidentialLoanApplication validarContextoEdicionDocumento(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		ResidentialLoanApplication solicitud = [
			SELECT
				Id,
				RecordType.DeveloperName,
				Status,
				FSC_Subestado__c,
				FSC_Resultado_Buro__c,
				FSC_Doc_Completa_Analisis__c,
				FSC_DocumentacionValidadaAnalista__c,
				FSC_DebeRevisarComite__c,
				FSC_DebeRevisarSupervisor__c,
				FSC_Aprobado_con_Condiciones__c,
				FSC_Moneda__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];
		Set<String> tiposElegibles = new Set<String>{
			RT_SOLICITUD_CREDITO_CONSUMO,
			RT_SOLICITUD_CREDITO_VEHICULO,
			RT_SOLICITUD_CREDITO_HIPOTECARIO,
			RT_SOLICITUD_CREDITO_PYME
		};
		Boolean etapaValida =
			tiposElegibles.contains(solicitud.RecordType?.DeveloperName) &&
			solicitud.Status == 'En proceso' &&
			normalize(solicitud.FSC_Subestado__c) == SUBESTADO_ANALISIS_CREDITO_NORM &&
			solicitud.FSC_Resultado_Buro__c == 'Referido' &&
			solicitud.FSC_Doc_Completa_Analisis__c == true &&
			solicitud.FSC_DocumentacionValidadaAnalista__c == true &&
			solicitud.FSC_DebeRevisarComite__c == false &&
			solicitud.FSC_DebeRevisarSupervisor__c == false &&
			solicitud.FSC_Aprobado_con_Condiciones__c == false;
		if (!etapaValida) {
			throw new AuraHandledException('Los documentos solo pueden editarse durante la decisión del analista, antes de enviarlos a Comité.');
		}

		if (!(Test.isRunningTest() && testPermitirEdicionDocumentosAnalisis)) {
			Boolean tienePermiso =
				FeatureManagement.checkPermission(PERMISO_ANALISTA_CREDITO) || FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR);
			if (!tienePermiso) {
				throw new AuraHandledException('No tiene autorización para editar los documentos de análisis.');
			}
			validateCurrentUserCanActOnApproval(residentialLoanApplicationId, PROCESO_ANALISTA);
		}
		return solicitud;
	}

	private static void validarDocumentoParaTipoCredito(ResidentialLoanApplication solicitud, String tipoDocumento) {
		if (
			solicitud?.RecordType?.DeveloperName == RT_SOLICITUD_CREDITO_PYME &&
			tipoDocumento != FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME
		) {
			throw new AuraHandledException('Para créditos Pyme solo está disponible el informe de crédito.');
		}
	}

	private static VersionDocumentoAnalisis obtenerVersionDocumentoAnalisis(Id solicitudId, String tipoDocumento) {
		String prefijoTitulo = tipoDocumento == FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_CAPACIDAD ? 'Capacidad de Pago' : 'Informe de Crédito';
		Id versionActualId;
		for (ContentDocumentLink enlace : [
			SELECT ContentDocument.Title, ContentDocument.LatestPublishedVersionId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :solicitudId
			ORDER BY SystemModstamp DESC
		]) {
			if (enlace.ContentDocument.Title != null && enlace.ContentDocument.Title.startsWith(prefijoTitulo)) {
				versionActualId = enlace.ContentDocument.LatestPublishedVersionId;
				break;
			}
		}
		if (versionActualId == null) {
			return null;
		}

		ContentVersion versionActual = [
			SELECT Id, FSC_DatosEditadosAnalisis__c
			FROM ContentVersion
			WHERE Id = :versionActualId
			LIMIT 1
		];
		Map<String, Object> ajustes = new Map<String, Object>();
		if (!String.isBlank(versionActual.FSC_DatosEditadosAnalisis__c)) {
			try {
				ajustes = (Map<String, Object>) JSON.deserializeUntyped(versionActual.FSC_DatosEditadosAnalisis__c);
			} catch (Exception error) {
				ajustes = new Map<String, Object>();
			}
		}
		return new VersionDocumentoAnalisis(versionActual.Id, ajustes);
	}

	private class VersionDocumentoAnalisis {
		private Id contentVersionId;
		private Map<String, Object> ajustes;

		private VersionDocumentoAnalisis(Id contentVersionId, Map<String, Object> ajustes) {
			this.contentVersionId = contentVersionId;
			this.ajustes = ajustes;
		}
	}

	private static Map<String, String> obtenerFormatosDocumento(String tipoDocumento, String tipoCredito) {
		Map<String, String> formatos = new Map<String, String>();
		if (tipoDocumento == FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME && tipoCredito == RT_SOLICITUD_CREDITO_PYME) {
			agregarFormatos(
				formatos,
				new List<String>{
					'numeroSolicitud',
					'solicitante',
					'cedula',
					'direccionResidencial',
					'codigoAbanks',
					'direccionComercial',
					'sectorEconomico',
					'actividadComercial',
					'clasificacionRiesgoBv',
					'grupoRiesgo',
					'tipoDeudor',
					'clasificacionRiesgoSib',
					'tipoTramitacion',
					'tipoGarantia',
					'tipoCredito',
					'tipoBienGarantia',
					'usoFondos',
					'descripcionGarantia',
					'facilidadesTipoCredito',
					'facilidadesMonto',
					'facilidadesPlazo',
					'facilidadesTasa',
					'facilidadesCuota',
					'facilidadesUsoFondos',
					'destinoTaxonomiaVerde',
					'codigoActividadTaxonomia',
					'actividadTaxonomiaVerde',
					'decision',
					'instanciaDecision',
					'realizadoPor',
					'revisadoPor',
					'certificadosTipoProducto',
					'certificadosNumero',
					'certificadosFechaApertura',
					'certificadosMontoApertura',
					'certificadosBalanceActual',
					'certificadosTasaPasiva',
					'certificadosPignorado',
					'cuentasTipoProducto',
					'cuentasNumero',
					'cuentasFechaApertura',
					'cuentasEntidad',
					'cuentasMoneda',
					'cuentasBalancePromedio',
					'cuentasDepositosPromedio',
					'cuentasPeriodo',
					'productosBvTipoCredito',
					'productosBvBalanceActual',
					'productosBvMontoAutorizado',
					'productosBvScore',
					'productosBvTipoGarantia',
					'creditosOtrosTipoCredito',
					'creditosOtrosBanco',
					'creditosOtrosTipoGarantia',
					'creditosOtrosProposito',
					'creditosOtrosMoneda',
					'creditosOtrosComportamiento',
					'creditosOtrosDeudaActual',
					'compromisosTipo',
					'compromisosBalances',
					'compromisosCuotas',
					'resultadoCapacidad',
					'perfilActividadComercial',
					'analisisFinanciero',
					'comportamientoHistorico',
					'resumenClasificacionSib',
					'mitigantes',
					'conclusionesRecomendaciones',
					'unidadSucursal',
					'ejecutivo'
				},
				FORMATO_TEXTO
			);
			agregarFormatos(formatos, new List<String>{ 'scoreBuro', 'plazoMeses' }, FORMATO_ENTERO);
			agregarFormatos(formatos, new List<String>{ 'admisibilidad', 'tasaInteres' }, FORMATO_PORCENTAJE);
			agregarFormatos(
				formatos,
				new List<String>{
					'valorGarantia',
					'montoSolicitado',
					'cuotaEstimada',
					'ingresosFinancieros',
					'inventario',
					'cuentasPorCobrar',
					'cajaBancos',
					'disponibilidadBalancePromedio',
					'disponibilidadFlujoPromedio'
				},
				FORMATO_DINERO
			);
			agregarFormatos(formatos, new List<String>{ 'fechaInforme', 'fechaTasacion', 'fechaDecision', 'fechaEstadosFinancieros' }, FORMATO_FECHA);
			for (String campo : CAMPOS_CALCULADOS_INFORME_PYME) {
				formatos.remove(campo);
			}
			return formatos;
		}
		if (tipoDocumento == FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME) {
			agregarFormatos(
				formatos,
				new List<String>{
					'solicitante',
					'cedula',
					'destino',
					'oficialNegocios',
					'sucursal',
					'analista',
					'estadoCivil',
					'nacionalidad',
					'residencial',
					'actividadEconomica',
					'antiguedadLaboral',
					'evidenciaIngresos',
					'garantiaResumen',
					'garantiaTipo',
					'garantiaUbicacion',
					'garantiaTasador',
					'garantiaMarca',
					'garantiaModelo',
					'clasificacionRiesgo',
					'historialPago',
					'excepciones',
					'recomendacion'
				},
				FORMATO_TEXTO
			);
			agregarFormatos(formatos, new List<String>{ 'edad', 'dependientes', 'garantiaAno', 'scoreCrediticio' }, FORMATO_ENTERO);
			agregarFormatos(formatos, new List<String>{ 'garantiaSuperficie' }, FORMATO_NUMERO);
			agregarFormatos(
				formatos,
				new List<String>{
					'ingresosMensualesPromedio',
					'cuotasFinancieras',
					'endeudamientoTotal',
					'solvenciaEstimada',
					'exposicionTotal',
					'garantiaValorTasacion',
					'garantiaPrecioVenta',
					'garantiaPagoInicial',
					'montoAprobado'
				},
				FORMATO_DINERO
			);
			agregarFormatos(
				formatos,
				new List<String>{ 'relacionCuotaIngresos', 'prestamoSobreTasacion', 'prestamoSobrePrecioVenta' },
				FORMATO_PORCENTAJE
			);
			agregarFormatos(formatos, new List<String>{ 'fechaEvaluacion', 'garantiaFechaTasacion', 'fechaAprobacion' }, FORMATO_FECHA);
			// El servidor tampoco permite sobrescribir los resultados calculados.
			for (String campo : CAMPOS_CALCULADOS_INFORME) {
				formatos.remove(campo);
			}
			return formatos;
		}

		// Se habilitan los datos de entrada y se excluyen las fórmulas.
		agregarFormatos(
			formatos,
			new List<String>{
				'solicitante',
				'oficialNegocios',
				'tipoPrestamo',
				'perfilRiesgo',
				'resultadoCargaFinanciera',
				'resultadoCapacidadVivienda',
				'resultadoApalancamiento',
				'resultadoEndeudamiento',
				'comentarios'
			},
			FORMATO_TEXTO
		);
		agregarFormatos(
			formatos,
			new List<String>{
				'tiempoTasaFija',
				'plazoMeses',
				'scorePredictivo',
				'scoreInterno',
				'moraTc30',
				'moraTc60',
				'moraTc90',
				'moraPrestamo30',
				'moraPrestamo60',
				'moraPrestamo90'
			},
			FORMATO_ENTERO
		);
		agregarFormatos(formatos, new List<String>{ 'tasaCambio' }, FORMATO_NUMERO);
		agregarFormatos(
			formatos,
			new List<String>{ 'montoSolicitado', 'garantiaValorTasacion', 'cuotaEstimada', 'totalActivos', 'totalPasivos', 'patrimonio' },
			FORMATO_DINERO
		);
		agregarFormatos(
			formatos,
			new List<String>{
				'prestamoSobreTasacion',
				'tasaInteres',
				'cargaFinanciera',
				'capacidadIncluyendoVivienda',
				'indiceApalancamiento',
				'capacidadEndeudamiento'
			},
			FORMATO_PORCENTAJE
		);
		for (String concepto : TODOS_CONCEPTOS_CAPACIDAD) {
			if (FILAS_CALCULADAS_CAPACIDAD.contains(concepto)) {
				continue;
			}
			formatos.put('montosPesos.' + concepto, FORMATO_DINERO_DOP);
			formatos.put('montosDolares.' + concepto, FORMATO_DINERO_USD);
		}
		for (String campo : CAMPOS_CALCULADOS_CAPACIDAD) {
			formatos.remove(campo);
		}
		return formatos;
	}

	private static void recalcularInformePyme(Map<String, Object> ajustes, Map<String, Object> datosEfectivos, String moneda) {
		Map<String, String> totalPorColumna = new Map<String, String>{
			'certificadosMontoApertura' => 'certificadosTotalMontoApertura',
			'certificadosBalanceActual' => 'certificadosTotalBalance',
			'cuentasBalancePromedio' => 'cuentasTotalBalancePromedio',
			'cuentasDepositosPromedio' => 'cuentasTotalDepositosPromedio',
			'productosBvBalanceActual' => 'productosBvTotalBalance',
			'productosBvMontoAutorizado' => 'productosBvTotalAutorizado',
			'creditosOtrosDeudaActual' => 'creditosOtrosTotalDeuda',
			'compromisosBalances' => 'compromisosTotalBalance',
			'compromisosCuotas' => 'compromisosTotalCuotas'
		};
		for (String columna : totalPorColumna.keySet()) {
			guardarValorCalculadoDocumento(
				ajustes,
				datosEfectivos,
				totalPorColumna.get(columna),
				sumarColumnaDocumento(datosEfectivos.get(columna)),
				FORMATO_DINERO,
				moneda
			);
		}

		Decimal montoSolicitado = obtenerDecimalEnRuta(datosEfectivos, 'montoSolicitado');
		Decimal valorGarantia = obtenerDecimalEnRuta(datosEfectivos, 'valorGarantia');
		guardarValorCalculadoDocumento(
			ajustes,
			datosEfectivos,
			'cobertura',
			calcularPorcentaje(valorGarantia, montoSolicitado),
			FORMATO_PORCENTAJE,
			null
		);

		Decimal totalCuotas = obtenerDecimalEnRuta(datosEfectivos, 'compromisosTotalCuotas');
		guardarValorCalculadoDocumento(
			ajustes,
			datosEfectivos,
			'disponibilidadPorcentajeBalance',
			calcularPorcentaje(totalCuotas, obtenerDecimalEnRuta(datosEfectivos, 'disponibilidadBalancePromedio')),
			FORMATO_PORCENTAJE,
			null
		);
		guardarValorCalculadoDocumento(
			ajustes,
			datosEfectivos,
			'disponibilidadPorcentajeFlujo',
			calcularPorcentaje(totalCuotas, obtenerDecimalEnRuta(datosEfectivos, 'disponibilidadFlujoPromedio')),
			FORMATO_PORCENTAJE,
			null
		);
	}

	private static void guardarValorCalculadoDocumento(
		Map<String, Object> ajustes,
		Map<String, Object> datosEfectivos,
		String ruta,
		Decimal valor,
		String formato,
		String moneda
	) {
		String valorPdf = valor == null ? '' : normalizarValorDocumento(valor, formato, moneda, ruta);
		ponerValorEnRuta(ajustes, ruta, valorPdf);
		ponerValorEnRuta(datosEfectivos, ruta, valorPdf);
	}

	private static Decimal sumarColumnaDocumento(Object valorColumna) {
		if (valorColumna == null || String.isBlank(String.valueOf(valorColumna))) {
			return null;
		}
		Decimal total;
		for (String linea : String.valueOf(valorColumna).split('\\r?\\n')) {
			Decimal valor = obtenerDecimalDocumento(linea, true);
			if (valor != null) {
				total = (total ?? 0) + valor;
			}
		}
		return total;
	}

	private static Decimal calcularPorcentaje(Decimal numerador, Decimal denominador) {
		return numerador == null || denominador == null || denominador == 0 ? null : numerador / denominador * 100;
	}

	private static void recalcularCapacidadPago(Map<String, Object> ajustes, Map<String, Object> datosEfectivos) {
		for (String rutaMoneda : new List<String>{ 'montosPesos', 'montosDolares' }) {
			String formato = rutaMoneda == 'montosDolares' ? FORMATO_DINERO_USD : FORMATO_DINERO_DOP;
			guardarMontoCalculado(
				ajustes,
				datosEfectivos,
				rutaMoneda,
				'totalIngresos',
				sumarConceptos(datosEfectivos, rutaMoneda, CONCEPTOS_INGRESOS_CAPACIDAD, new List<String>(), false),
				formato
			);
			guardarMontoCalculado(
				ajustes,
				datosEfectivos,
				rutaMoneda,
				'totalAdeudado',
				sumarConceptos(datosEfectivos, rutaMoneda, CONCEPTOS_DEUDAS_CAPACIDAD, new List<String>(), false),
				formato
			);
			guardarMontoCalculado(
				ajustes,
				datosEfectivos,
				rutaMoneda,
				'totalPagosCreditos',
				sumarConceptos(datosEfectivos, rutaMoneda, CONCEPTOS_PAGOS_CAPACIDAD, CONCEPTOS_CANCELACIONES_CAPACIDAD, true),
				formato
			);
			guardarMontoCalculado(
				ajustes,
				datosEfectivos,
				rutaMoneda,
				'totalPagos',
				sumarConceptos(datosEfectivos, rutaMoneda, new List<String>{ 'totalPagosCreditos', 'pagoVivienda' }, new List<String>(), true),
				formato
			);
		}

		Decimal tasaCambio = obtenerDecimalDocumento(datosEfectivos.get('tasaCambio'), false);
		for (String concepto : TODOS_CONCEPTOS_CAPACIDAD) {
			Decimal montoPesos = obtenerDecimalEnRuta(datosEfectivos, 'montosPesos.' + concepto);
			Decimal montoDolares = obtenerDecimalEnRuta(datosEfectivos, 'montosDolares.' + concepto);
			Decimal totalPesos;
			if (montoPesos != null || montoDolares != null) {
				totalPesos = montoDolares != null && tasaCambio == null ? null : (montoPesos ?? 0) + (montoDolares ?? 0) * (tasaCambio ?? 0);
			}
			guardarMontoCalculado(ajustes, datosEfectivos, 'totalesPesos', concepto, totalPesos, FORMATO_DINERO_DOP);
		}
	}

	private static Decimal sumarConceptos(
		Map<String, Object> datos,
		String rutaMoneda,
		List<String> conceptosPositivos,
		List<String> conceptosNegativos,
		Boolean limitarACero
	) {
		Decimal total;
		for (String concepto : conceptosPositivos) {
			Decimal valor = obtenerDecimalEnRuta(datos, rutaMoneda + '.' + concepto);
			if (valor != null) {
				total = (total ?? 0) + valor;
			}
		}
		for (String concepto : conceptosNegativos) {
			Decimal valor = obtenerDecimalEnRuta(datos, rutaMoneda + '.' + concepto);
			if (valor != null) {
				total = (total ?? 0) - valor;
			}
		}
		return limitarACero && total != null && total < 0 ? 0 : total;
	}

	private static void guardarMontoCalculado(
		Map<String, Object> ajustes,
		Map<String, Object> datosEfectivos,
		String rutaMapa,
		String concepto,
		Decimal valor,
		String formato
	) {
		String ruta = rutaMapa + '.' + concepto;
		String valorPdf = valor == null ? '' : normalizarValorDocumento(valor, formato, null, ruta);
		ponerValorEnRuta(ajustes, ruta, valorPdf);
		ponerValorEnRuta(datosEfectivos, ruta, valorPdf);
	}

	private static Decimal obtenerDecimalEnRuta(Map<String, Object> origen, String ruta) {
		Object actual = origen;
		for (String parte : ruta.split('\\.')) {
			if (!(actual instanceof Map<String, Object>)) {
				return null;
			}
			actual = ((Map<String, Object>) actual).get(parte);
		}
		return obtenerDecimalDocumento(actual, true);
	}

	private static Decimal obtenerDecimalDocumento(Object valor, Boolean esMoneda) {
		if (valor == null || String.isBlank(String.valueOf(valor))) {
			return null;
		}
		String limpio = String.valueOf(valor).replaceAll('[^0-9,\\.\\-]', '');
		Integer ultimaComa = limpio.lastIndexOf(',');
		Integer ultimoPunto = limpio.lastIndexOf('.');
		if (ultimaComa >= 0 && ultimoPunto >= 0) {
			if (ultimaComa > ultimoPunto) {
				limpio = limpio.replace('.', '').replace(',', '.');
			} else {
				limpio = limpio.replace(',', '');
			}
		} else if (ultimaComa >= 0) {
			Integer decimales = limpio.length() - ultimaComa - 1;
			limpio = esMoneda && decimales == 3
				? limpio.replace(',', '')
				: (decimales > 0 && decimales <= 4 ? limpio.replace(',', '.') : limpio.replace(',', ''));
		} else if (esMoneda && ultimoPunto >= 0 && limpio.length() - ultimoPunto - 1 == 3) {
			limpio = limpio.replace('.', '');
		} else if (ultimoPunto >= 0 && limpio.indexOf('.') != ultimoPunto) {
			List<String> partes = limpio.split('\\.');
			String parteDecimal = partes.remove(partes.size() - 1);
			limpio = String.join(partes, '') + '.' + parteDecimal;
		}
		try {
			return String.isBlank(limpio) || limpio == '-' ? null : Decimal.valueOf(limpio);
		} catch (Exception error) {
			return null;
		}
	}

	private static void agregarFormatos(Map<String, String> formatos, List<String> rutas, String formato) {
		for (String ruta : rutas) {
			formatos.put(ruta, formato);
		}
	}

	private static String normalizarValorDocumento(Object valorEntrada, String formato, String moneda, String ruta) {
		String textoEntrada = valorEntrada == null ? '' : String.valueOf(valorEntrada).trim();
		if (textoEntrada.length() > 20000) {
			throw new AuraHandledException('El valor de ' + ruta + ' excede el tamaño permitido.');
		}
		if (formato == FORMATO_TEXTO) {
			return textoEntrada;
		}
		if (String.isBlank(textoEntrada)) {
			return '';
		}
		if (formato == FORMATO_FECHA) {
			try {
				Date fecha = Date.valueOf(textoEntrada);
				return fecha.day() + '/' + fecha.month() + '/' + fecha.year();
			} catch (Exception error) {
				throw new AuraHandledException('La fecha de ' + ruta + ' no es válida.');
			}
		}

		Decimal numero = obtenerDecimalEntrada(valorEntrada, ruta);
		validarRangoNumeroDocumento(numero, formato, ruta);
		if (formato == FORMATO_ENTERO) {
			if (numero != numero.setScale(0)) {
				throw new AuraHandledException('El valor de ' + ruta + ' debe ser un número entero.');
			}
			return String.valueOf(numero.setScale(0));
		}
		if (formato == FORMATO_NUMERO) {
			return String.valueOf(numero);
		}
		if (formato == FORMATO_PORCENTAJE) {
			return numero.setScale(2).format() + '%';
		}

		String simbolo = 'RD$';
		if (formato == FORMATO_DINERO_USD) {
			simbolo = 'US$';
		} else if (formato == FORMATO_DINERO) {
			String monedaNormalizada = String.isBlank(moneda) ? '' : moneda.trim().toUpperCase();
			simbolo = monedaNormalizada == '2' ||
				monedaNormalizada == 'USD' ||
				monedaNormalizada.contains('DOLAR')
				? 'US$'
				: (monedaNormalizada == '3' || monedaNormalizada == 'EUR' || monedaNormalizada.contains('EURO') ? 'EUR' : 'RD$');
		}
		return simbolo + ' ' + numero.setScale(2).format();
	}

	private static void validarRangoNumeroDocumento(Decimal numero, String formato, String ruta) {
		if (numero < 0 && (formato == FORMATO_ENTERO || formato == FORMATO_PORCENTAJE)) {
			throw new AuraHandledException('El valor de ' + ruta + ' no puede ser negativo.');
		}
		if (ruta == 'plazoMeses' && (numero < 1 || numero > 99)) {
			throw new AuraHandledException('El plazo en meses debe estar entre 1 y 99.');
		}
		if (ruta == 'tiempoTasaFija' && numero > 99) {
			throw new AuraHandledException('El tiempo de tasa fija no puede exceder 99 meses.');
		}
		if (ruta == 'edad' && numero > 150) {
			throw new AuraHandledException('La edad no puede exceder 150 años.');
		}
	}

	private static Decimal obtenerDecimalEntrada(Object valorEntrada, String ruta) {
		try {
			return Decimal.valueOf(String.valueOf(valorEntrada));
		} catch (Exception error) {
			throw new AuraHandledException('El valor de ' + ruta + ' debe ser numérico.');
		}
	}

	private static void ponerValorEnRuta(Map<String, Object> destino, String ruta, Object valor) {
		List<String> partes = ruta.split('\\.');
		Map<String, Object> nivel = destino;
		for (Integer indice = 0; indice < partes.size() - 1; indice++) {
			Object siguiente = nivel.get(partes[indice]);
			if (!(siguiente instanceof Map<String, Object>)) {
				siguiente = new Map<String, Object>();
				nivel.put(partes[indice], siguiente);
			}
			nivel = (Map<String, Object>) siguiente;
		}
		nivel.put(partes[partes.size() - 1], valor);
	}

	private static void validateChecklistApprovalReadinessInternal(Id residentialLoanApplicationId) {
		ResidentialLoanApplication rla = [
			SELECT Id, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		Set<String> relevantCategories = getRelevantChecklistCategories(rla.FSC_Subestado__c);
		if (relevantCategories.isEmpty()) {
			return;
		}

		List<FSC_ChecklistDocsController.RowDTO> rows = FSC_ChecklistDocsController.initAndGetRows(residentialLoanApplicationId);

		List<FSC_ChecklistDocsController.RowDTO> relevantRows = new List<FSC_ChecklistDocsController.RowDTO>();
		for (FSC_ChecklistDocsController.RowDTO row : rows) {
			if (row != null && relevantCategories.contains(normalize(row.categoria))) {
				relevantRows.add(row);
			}
		}

		if (relevantRows.isEmpty()) {
			throw new AuraHandledException('Debe revisar todos los documentos de la categoría correspondiente antes de aprobar.');
		}

		for (FSC_ChecklistDocsController.RowDTO row : relevantRows) {
			if (String.isBlank(row.estadoRevision) || (row.estadoRevision != ESTADO_APROBADO && row.estadoRevision != ESTADO_OBSERVADO)) {
				throw new AuraHandledException(
					'Debe completar el estado de revisión de todos los documentos de la categoría correspondiente antes de aprobar.'
				);
			}

			if (row.estadoRevision == ESTADO_OBSERVADO && String.isBlank(row.comentario)) {
				throw new AuraHandledException('Si un documento queda con estado "Observado", debe ingresar un comentario antes de aprobar.');
			}
		}
	}

	private static void validateChecklistUploadCompletenessInternal(Id residentialLoanApplicationId) {
		ResidentialLoanApplication rla = [
			SELECT Id, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		Set<String> relevantCategories = getRelevantChecklistCategories(rla.FSC_Subestado__c);
		if (relevantCategories.isEmpty()) {
			return;
		}

		List<FSC_ChecklistDocsController.RowDTO> rows = FSC_ChecklistDocsController.initAndGetRows(residentialLoanApplicationId);

		List<FSC_ChecklistDocsController.RowDTO> relevantRows = new List<FSC_ChecklistDocsController.RowDTO>();
		for (FSC_ChecklistDocsController.RowDTO row : rows) {
			if (row != null && relevantCategories.contains(normalize(row.categoria))) {
				relevantRows.add(row);
			}
		}

		if (relevantRows.isEmpty()) {
			throw new AuraHandledException(
				'Debe cargar o marcar como "No aplica" todos los documentos de la categoria correspondiente antes de enviar a revision.'
			);
		}

		for (FSC_ChecklistDocsController.RowDTO row : relevantRows) {
			Boolean hasFile = row.files != null && !row.files.isEmpty();
			if (row.noAplica != true && !hasFile) {
				throw new AuraHandledException(
					'Debe cargar o marcar como "No aplica" todos los documentos de la categoria correspondiente antes de enviar a revision.'
				);
			}
		}
	}

	private static Set<String> getRelevantChecklistCategories(String subestado) {
		Set<String> categories = new Set<String>();

		String normalizedSubestado = normalize(subestado).replace('–', ' ').replace('-', ' ').replaceAll('\\s+', ' ').trim();

		if (normalizedSubestado == SUBESTADO_RECEPCION_ANALISIS_NORM || normalizedSubestado == SUBESTADO_ANALISIS_CREDITO_NORM) {
			categories.add(CAT_ANALISIS_NORM);
		} else if (normalizedSubestado == SUBESTADO_DOCS_DESEMBOLSO_NORM) {
			categories.add(CAT_DESEMBOLSO_NORM);
		} else if (
			normalizedSubestado == normalize(FSC_DocumentacionContratosService.SUBESTADO_CARGA) ||
			normalizedSubestado == normalize(FSC_DocumentacionContratosService.SUBESTADO_GENERACION)
		) {
			categories.add(CAT_CONTRATO_NORM);
		}

		return categories;
	}

	private static List<ProcessInstanceWorkitem> getActiveWorkItems(Id residentialLoanApplicationId) {
		return [
			SELECT Id, ActorId, OriginalActorId, ProcessInstanceId
			FROM ProcessInstanceWorkitem
			WHERE ProcessInstance.TargetObjectId = :residentialLoanApplicationId
			ORDER BY CreatedDate DESC
		];
	}

	private static void validateAnalystDecisionReadiness(Id residentialLoanApplicationId) {
		validateCurrentUserCanActOnApproval(residentialLoanApplicationId, PROCESO_ANALISTA);

		ResidentialLoanApplication rla = [
			SELECT FSC_DocumentacionValidadaAnalista__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (!rla.FSC_DocumentacionValidadaAnalista__c) {
			throw new AuraHandledException('Debe validar la documentación en pestaña Checklist de Documentos antes de continuar.');
		}

		validateChecklistApprovalReadinessInternal(residentialLoanApplicationId);
	}

	private static Boolean hasActiveApprovalForProcess(Id residentialLoanApplicationId, String processDeveloperName) {
		return getActiveWorkItemForProcess(residentialLoanApplicationId, processDeveloperName) != null;
	}

	private static void validateCurrentUserCanActOnApproval(Id residentialLoanApplicationId, String expectedProcessDeveloperName) {
		ProcessInstanceWorkitem workItem = getActiveWorkItemForProcess(residentialLoanApplicationId, expectedProcessDeveloperName);

		if (workItem == null) {
			throw new AuraHandledException('No hay un proceso de aprobación activo para esta acción.');
		}

		Id currentUserId = UserInfo.getUserId();
		Boolean canAct =
			FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR) ||
			workItem.ActorId == currentUserId ||
			(workItem.ActorId != null &&
			String.valueOf(workItem.ActorId).startsWith('00G') &&
			isUserMemberOfGroupRecursive(workItem.ActorId, currentUserId));

		if (!canAct) {
			throw new AuraHandledException(
				'Usted no tiene autorización para realizar esta acción, solo la persona asignada o un administrador tienen permiso.'
			);
		}
	}

	private static ProcessInstanceWorkitem getActiveWorkItemForProcess(Id residentialLoanApplicationId, String expectedProcessDeveloperName) {
		for (ProcessInstanceWorkitem workItem : getActiveWorkItems(residentialLoanApplicationId)) {
			if (
				String.isBlank(expectedProcessDeveloperName) ||
				getProcessDefinitionDeveloperName(workItem.ProcessInstanceId) == expectedProcessDeveloperName
			) {
				return workItem;
			}
		}

		return null;
	}

	private static void validateCurrentUserCanCompleteGestionPlanillas(Id residentialLoanApplicationId) {
		if (testBypassPermissions)
			return;
		ResidentialLoanApplication rla = [
			SELECT Id, FSC_UsuarioGestionPlanilla__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (FSC_RoleAuthorizationService.canManageDisbursement(rla.FSC_UsuarioGestionPlanilla__c)) {
			return;
		}

		throw new AuraHandledException(
			'Usted no tiene autorización para realizar esta acción, solo la persona asignada o un administrador tienen permiso.'
		);
	}

	private static void validateCurrentUserCanCompletePagares(Id residentialLoanApplicationId) {
		ResidentialLoanApplication rla = [
			SELECT Id, FSC_UsuarioPagaresYContratos__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (FSC_RoleAuthorizationService.canManagePagares(rla.FSC_UsuarioPagaresYContratos__c)) {
			return;
		}

		throw new AuraHandledException(MSG_PAGARES_SIN_AUTORIZACION);
	}

	private static void validateFormaDeDesembolsoValue(String formaDeDesembolso) {
		Set<String> validValues = new Set<String>();
		for (Schema.PicklistEntry entry : ResidentialLoanApplication.FSC_FormaDeDesembolso__c.getDescribe().getPicklistValues()) {
			if (entry.isActive()) {
				validValues.add(entry.getValue());
			}
		}

		if (!validValues.contains(formaDeDesembolso)) {
			throw new AuraHandledException('Forma de desembolso no valida.');
		}
	}

	private static FinServ__FinancialAccount__c getValidCuentaDesembolso(Id residentialLoanApplicationId, Id financialAccountId) {
		if (financialAccountId == null) {
			throw new AuraHandledException('Cuenta de desembolso requerida.');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, AccountId
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (rla.AccountId == null) {
			throw new AuraHandledException('La solicitud no tiene cliente asociado.');
		}

		List<FinServ__FinancialAccount__c> cuentas = [
			SELECT Id, Name, FinServ__FinancialAccountNumber__c
			FROM FinServ__FinancialAccount__c
			WHERE
				Id = :financialAccountId
				AND FinServ__PrimaryOwner__c = :rla.AccountId
				AND (RecordType.DeveloperName = 'CheckingAccount'
				OR RecordType.DeveloperName = 'SavingsAccount')
			LIMIT 1
		];

		if (cuentas.isEmpty()) {
			throw new AuraHandledException('Cuenta de desembolso no valida para esta solicitud.');
		}
		if (String.isBlank(cuentas[0].FinServ__FinancialAccountNumber__c)) {
			throw new AuraHandledException('La cuenta de desembolso seleccionada no tiene numero de cuenta.');
		}

		return cuentas[0];
	}

	private static String buildCuentaDesembolsoLabel(FinServ__FinancialAccount__c financialAccount) {
		if (financialAccount == null) {
			return '';
		}

		if (String.isBlank(financialAccount.FinServ__FinancialAccountNumber__c) && !String.isBlank(financialAccount.Name)) {
			return financialAccount.Name;
		}
		if (!String.isBlank(financialAccount.FinServ__FinancialAccountNumber__c) && String.isBlank(financialAccount.Name)) {
			return financialAccount.FinServ__FinancialAccountNumber__c;
		}
		if (String.isBlank(financialAccount.FinServ__FinancialAccountNumber__c) && String.isBlank(financialAccount.Name)) {
			return String.valueOf(financialAccount.Id);
		}

		return financialAccount.Name + ' - ' + financialAccount.FinServ__FinancialAccountNumber__c;
	}

	@TestVisible
	private static String getProcessDefinitionDeveloperName(Id processInstanceId) {
		if (processInstanceId == null) {
			return '';
		}

		List<ProcessInstance> processInstances = [
			SELECT Id, ProcessDefinitionId
			FROM ProcessInstance
			WHERE Id = :processInstanceId
			LIMIT 1
		];

		if (processInstances.isEmpty() || processInstances[0].ProcessDefinitionId == null) {
			return '';
		}

		List<ProcessDefinition> processDefinitions = [
			SELECT Id, DeveloperName
			FROM ProcessDefinition
			WHERE Id = :processInstances[0].ProcessDefinitionId
			LIMIT 1
		];

		return processDefinitions.isEmpty() ? '' : processDefinitions[0].DeveloperName;
	}

	private static void aplicarObservacionPorPermiso(ResidentialLoanApplication solicitudCredito, String motivo) {
		if (testBypassPermissions) {
			solicitudCredito.FSC_ObservacionAdministrador__c = motivo;
			return;
		}
		if (FeatureManagement.checkPermission(PERMISO_PREVENCION_LAVADO_ACTIVOS)) {
			solicitudCredito.FSC_ObservacionPLA__c = motivo;
		} else if (FeatureManagement.checkPermission(PERMISO_CONTROL_DOCUMENTOS)) {
			solicitudCredito.FSC_ObservacionRecepcionYControlDeDocs__c = motivo;
		} else if (FeatureManagement.checkPermission(PERMISO_ANALISTA_CREDITO)) {
			solicitudCredito.FSC_ObservacionAnalistaDeCredito__c = motivo;
		} else if (FeatureManagement.checkPermission(PERMISO_SUPERVISOR)) {
			solicitudCredito.FSC_ObservacionSupervisor__c = motivo;
		} else if (FeatureManagement.checkPermission(PERMISO_COMITE_CREDITO)) {
			solicitudCredito.FSC_ObservacionesComite__c = motivo;
		} else if (FeatureManagement.checkPermission(PERMISO_ARCHIVO_CUSTODIA_VALORES)) {
			solicitudCredito.FSC_ObservacionArchyCustodiaDeValores__c = motivo;
		} else if (FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR)) {
			solicitudCredito.FSC_ObservacionAdministrador__c = motivo;
		} else {
			throw new AuraHandledException('No tiene un permiso personalizado habilitado para rechazar la solicitud.');
		}
	}

	private static void validarPermisoAdministrador(String mensajeError) {
		if (testBypassPermissions)
			return;
		if (!FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR)) {
			throw new AuraHandledException(mensajeError);
		}
	}

	private static void validarPermisoSupervisorOAdministrador() {
		if (testBypassPermissions)
			return;
		if (!FeatureManagement.checkPermission(PERMISO_SUPERVISOR) && !FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR)) {
			throw new AuraHandledException('Solo un Supervisor o un administrador puede reasignar esta etapa.');
		}
	}

	private static void validarPermisoOficialOAdministrador() {
		if (testBypassPermissions)
			return;
		if (!FeatureManagement.checkPermission(PERMISO_OFICIAL_NEGOCIO) && !FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR)) {
			throw new AuraHandledException('Solo un Oficial de Negocio o un administrador puede registrar la decisión del cliente.');
		}
	}

	private static void validarPermisoBancaSeguroOAdministrador() {
		if (!FeatureManagement.checkPermission(PERMISO_BANCA_SEGURO) && !FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR)) {
			throw new AuraHandledException('Solo Banca Seguro o un administrador puede realizar esta acción.');
		}
	}

	private static String obtenerPermisoRolActual() {
		if (FeatureManagement.checkPermission(PERMISO_ANALISTA_CREDITO)) {
			return PERMISO_ANALISTA_CREDITO;
		}
		if (FeatureManagement.checkPermission(PERMISO_SUPERVISOR)) {
			return PERMISO_SUPERVISOR;
		}
		if (FeatureManagement.checkPermission(PERMISO_COMITE_CREDITO)) {
			return PERMISO_COMITE_CREDITO;
		}
		if (FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR)) {
			return PERMISO_ADMINISTRADOR;
		}
		throw new AuraHandledException('No tiene un permiso personalizado habilitado para devolver la solicitud.');
	}

	@TestVisible
	private static String normalize(String s) {
		if (s == null)
			return '';
		String out = s.trim().toLowerCase();
		out = out.replace('á', 'a').replace('é', 'e').replace('í', 'i').replace('ó', 'o').replace('ú', 'u');
		out = out.replace('ü', 'u').replace('ñ', 'n');
		out = out.replace('á', 'a').replace('é', 'e').replace('í', 'i').replace('ó', 'o').replace('ú', 'u');
		out = out.replace('ü', 'u').replace('ñ', 'n');
		out = out.replace('á', 'a').replace('é', 'e').replace('í', 'i').replace('ó', 'o').replace('ú', 'u');
		out = out.replace('ü', 'u').replace('ñ', 'n');
		out = out.replace('â€“', ' ').replace('–', ' ').replace('-', ' ');
		out = out.replaceAll('\\s+', ' ').trim();
		return out;
	}

	@TestVisible
	private static Boolean isUserMemberOfGroupRecursive(Id rootGroupId, Id userId) {
		if (rootGroupId == null || userId == null) {
			return false;
		}

		User currentUser = [
			SELECT Id, UserRoleId
			FROM User
			WHERE Id = :userId
			LIMIT 1
		];

		Set<Id> targetIds = new Set<Id>{ userId };
		if (currentUser.UserRoleId != null) {
			targetIds.add(currentUser.UserRoleId);
		}

		Set<Id> visitedGroupIds = new Set<Id>();
		Set<Id> groupsToProcess = new Set<Id>{ rootGroupId };

		while (!groupsToProcess.isEmpty()) {
			Set<Id> currentBatch = new Set<Id>(groupsToProcess);
			groupsToProcess.clear();

			for (GroupMember gm : [
				SELECT GroupId, UserOrGroupId
				FROM GroupMember
				WHERE GroupId IN :currentBatch
			]) {
				if (targetIds.contains(gm.UserOrGroupId)) {
					return true;
				}

				String memberIdStr = String.valueOf(gm.UserOrGroupId);
				if (memberIdStr.startsWith('00G') && !visitedGroupIds.contains(gm.UserOrGroupId)) {
					visitedGroupIds.add(gm.UserOrGroupId);
					groupsToProcess.add(gm.UserOrGroupId);
				}
			}
		}

		return false;
	}
}