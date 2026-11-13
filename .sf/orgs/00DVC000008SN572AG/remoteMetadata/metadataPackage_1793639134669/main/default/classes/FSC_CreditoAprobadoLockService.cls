public without sharing class FSC_CreditoAprobadoLockService {
	private static final String PERMISO_ADMINISTRADOR = 'FSC_CP_Administrador';
	private static final String MENSAJE_BLOQUEO =
		'No es posible editar esta información del crédito ya que se encuentra Aprobada';
	private static final Set<String> CAMPOS_TASADOR_EDITABLES = new Set<String>{
		'FSC_EsTasadorExterno__c',
		'FSC_NombreTasadorExterno__c',
		'FSC_Tasado_Por__c'
	};
	// La formalización de garantías ocurre siempre después de la aprobación del comité.
	private static final Set<String> CAMPOS_FORMALIZACION_GARANTIA = new Set<String>{
		'FSC_Titulo_Registrado__c',
		'FSC_Fecha_Formalizacion_Hipotecaria__c',
		'FSC_Garantia_Constituida__c',
		'FSC_Comentario_Formalizacion_Vehiculo__c',
		'FSC_Fecha_Constitucion_Garantia__c'
	};
	private static final Set<String> CAMPOS_CRITICOS_SOLICITUD = new Set<String>{
		'AccountId',
		'FSC_TipoSolicitud__c',
		'FSC_TipoCredito__c',
		'FSC_Facilidad__c',
		'FSC_Tipo_Modalidad__c',
		'FSC_Moneda__c',
		'FSC_Destino_del_Prestamo__c',
		'FSC_DescripcionPropositoFacilidad__c',
		'FSC_Monto__c',
		'FSC_Plazo_meses__c',
		'FSC_TasaInteres__c',
		'FSC_Tasa_Fija__c',
		'FSC_TasaFijaPorMeses__c',
		'FSC_FormaPago__c',
		'FSC_Monto_De_La_Cuota__c',
		'FSC_Cuotas__c',
		'FSC_RequiereContratoPagareNotarial__c',
		'FSC_Condiciones_de_la_Facilidad__c',
		'FSC_CondicionComite__c',
		'FSC_Aprobado_con_Condiciones__c',
		'FSC_MontoAprobado__c',
		'FSC_PlazoMesesAprobado__c',
		'FSC_TasaInteresAprobada__c',
		'FSC_OtrasCondicionesComite__c',
		'FSC_Recomendaciones__c',
		'FSC_HistorialPago__c',
		'FSC_SolicitudAprobadaPorComite__c',
		'FSC_FechaYHoraAprobacionComite__c'
	};
	// Datos de redacción del contrato que se capturan al generar pagarés y contratos, después de la aprobación.
	private static final Set<String> CAMPOS_CONTRATO_GARANTIA = minusculas(new Set<String>{
		'FSC_Descripcion_de_la_Garantia__c',
		'FSC_Numero_Titulo__c',
		'FSC_Registro_de_Titulos__c',
		'FSC_Fecha_Expedicion_Titulo__c',
		'FSC_Numero_Certificado_Deposito__c',
		'FSC_Fecha_Certificado_Deposito__c',
		'FSC_Titular_Certificado_Deposito__c',
		'FSC_Moneda_Certificado_Deposito__c',
		'FSC_Emisor_Certificado_Deposito__c',
		'FSC_Tipo_Vehiculo__c',
		'FSC_Marca_Vehiculo__c',
		'FSC_Codigo_Marca_Vehiculo__c',
		'FSC_Modelo_Vehiculo__c',
		'FSC_Codigo_Modelo_Vehiculo__c',
		'FSC_Ano_Vehiculo__c',
		'FSC_Color_Vehiculo__c',
		'FSC_Numero_Chasis_Vehiculo__c',
		'FSC_Serial_Motor_Vehiculo__c',
		'FSC_Numero_Placa_Vehiculo__c',
		'FSC_Numero_Matricula__c',
		'FSC_Ubicacion__c'
	});
	private static final Set<String> MONTOS_CONTRATO_GARANTIA = minusculas(new Set<String>{
		'FSC_Monto_Certificado_Deposito__c',
		'FSC_Valor_Vehiculo__c'
	});
	private static final Set<String> CAMPOS_CONTRATO_ACTIVO = minusculas(new Set<String>{
		'FSC_Descripcion_Contrato__c',
		'FSC_Numero_Titulo_Contrato__c',
		'FSC_Registro_Titulos_Contrato__c',
		'FSC_Fecha_Titulo_Contrato__c',
		'AccountNumber',
		'FSC_Fecha_CD_Contrato__c',
		'FSC_Titular_CD_Contrato__c',
		'FSC_Moneda_CD_Contrato__c',
		'FinancialInstitutionName',
		'FSC_Tipo_Vehiculo_Contrato__c',
		'FSC_Marca_Vehiculo_Contrato__c',
		'FSC_Modelo_Vehiculo_Contrato__c',
		'FSC_Ano_Vehiculo_Contrato__c',
		'FSC_Color_Vehiculo_Contrato__c',
		'FSC_Chasis_Vehiculo_Contrato__c',
		'FSC_Motor_Vehiculo_Contrato__c',
		'FSC_Placa_Vehiculo_Contrato__c',
		'FSC_Matricula_Vehiculo_Contrato__c',
		'FSC_Ubicacion_Contrato__c'
	});
	private static final Set<String> MONTOS_CONTRATO_ACTIVO = minusculas(new Set<String>{ 'CashOrMarketValue' });
	private static final Set<String> CAMPOS_CONTRATO_SEGURO = minusculas(new Set<String>{
		'FSC_Numero_Poliza_Contrato__c',
		'FSC_Aseguradora_Contrato__c',
		'FSC_Direccion_Aseguradora_Contrato__c',
		'FSC_Fecha_Endoso_Contrato__c',
		'FSC_Monto_Asegurado_Contrato__c'
	});
	private static final Set<String> MONTOS_CONTRATO_SEGURO = minusculas(new Set<String>{ 'FSC_Monto_de_la_Prima__c' });
	private static final Set<String> CAMPOS_SISTEMA = minusculas(new Set<String>{
		'Id',
		'CreatedById',
		'CreatedDate',
		'LastModifiedById',
		'LastModifiedDate',
		'SystemModstamp',
		'LastViewedDate',
		'LastReferencedDate'
	});
	private static Boolean permitirDecisionComite = false;
	private static Boolean permitirPlanillaDesembolso = false;
	private static Boolean permitirDatosContrato = false;

	public static void iniciarDecisionComite() {
		permitirDecisionComite = true;
	}

	public static void finalizarDecisionComite() {
		permitirDecisionComite = false;
	}

	// La planilla de desembolso completa campos críticos vacíos; nunca puede cambiar un valor ya aprobado.
	public static void iniciarPlanillaDesembolso() {
		permitirPlanillaDesembolso = true;
	}

	public static void finalizarPlanillaDesembolso() {
		permitirPlanillaDesembolso = false;
	}

	// Pagarés y contratos completan los datos de redacción del contrato; los montos solo si estaban vacíos.
	public static void iniciarDatosContrato() {
		permitirDatosContrato = true;
	}

	public static void finalizarDatosContrato() {
		permitirDatosContrato = false;
	}

	public static void validarParticipantes(List<LoanApplicant> registros) {
		List<SObject> registrosGenericos = new List<SObject>();
		for (LoanApplicant registro : registros) {
			registrosGenericos.add(registro);
		}
		validarRegistrosBloqueados(registrosGenericos, 'LoanApplicationId');
	}

	public static void validarActivosSolicitud(List<LoanApplicationAsset> registros) {
		validarActivosSolicitud(registros, null);
	}

	public static void validarActivosSolicitud(List<LoanApplicationAsset> registros, Map<Id, LoanApplicationAsset> anteriores) {
		if (permitirDatosContrato && anteriores != null) {
			validarDatosContrato(registros, anteriores, 'LoanApplicationId', CAMPOS_CONTRATO_ACTIVO, MONTOS_CONTRATO_ACTIVO);
			return;
		}
		List<SObject> registrosGenericos = new List<SObject>();
		for (LoanApplicationAsset registro : registros) {
			registrosGenericos.add(registro);
		}
		validarRegistrosBloqueados(registrosGenericos, 'LoanApplicationId');
	}

	public static void validarFacilidades(List<FSC_Facilidades_De_Credito__c> registros) {
		List<SObject> registrosGenericos = new List<SObject>();
		for (FSC_Facilidades_De_Credito__c registro : registros) {
			registrosGenericos.add(registro);
		}
		validarRegistrosBloqueados(registrosGenericos, 'FSC_Residential_Loan_Application__c');
	}

	public static void validarSeguros(List<FSC_Seguro__c> registros) {
		validarSeguros(registros, null, false);
	}

	public static void validarSeguros(List<FSC_Seguro__c> registros, Map<Id, FSC_Seguro__c> anteriores, Boolean esInsercion) {
		if (permitirDatosContrato && esInsercion == true) {
			// El contrato crea el seguro de incendio o vehículo cuando la solicitud aún no lo tiene.
			return;
		}
		if (permitirDatosContrato && anteriores != null) {
			validarDatosContrato(registros, anteriores, 'FSC_Residential_Loan_Application__c', CAMPOS_CONTRATO_SEGURO, MONTOS_CONTRATO_SEGURO);
			return;
		}
		List<SObject> registrosGenericos = new List<SObject>();
		for (FSC_Seguro__c registro : registros) {
			registrosGenericos.add(registro);
		}
		validarRegistrosBloqueados(registrosGenericos, 'FSC_Residential_Loan_Application__c');
	}

	public static void validarGarantias(
		List<FSC_Garantia__c> registros,
		Map<Id, FSC_Garantia__c> anteriores,
		Boolean esActualizacion
	) {
		if (esAdministrador() || registros == null || registros.isEmpty()) {
			return;
		}

		Set<Id> solicitudesAprobadas = obtenerSolicitudesAprobadas(registros, 'FSC_Residential_Loan_Application__c');
		if (solicitudesAprobadas.isEmpty()) {
			return;
		}

		for (FSC_Garantia__c registro : registros) {
			Id solicitudId = (Id) registro.get('FSC_Residential_Loan_Application__c');
			if (!solicitudesAprobadas.contains(solicitudId)) {
				continue;
			}

			FSC_Garantia__c anterior = esActualizacion && anteriores != null ? anteriores.get(registro.Id) : null;
			Set<String> permitidos = new Set<String>(CAMPOS_TASADOR_EDITABLES);
			permitidos.addAll(CAMPOS_FORMALIZACION_GARANTIA);
			Set<String> montosPermitidos = new Set<String>();
			if (permitirDatosContrato) {
				permitidos.addAll(CAMPOS_CONTRATO_GARANTIA);
				montosPermitidos.addAll(MONTOS_CONTRATO_GARANTIA);
			}
			if (anterior == null || tieneCambiosNoPermitidos(registro, anterior, permitidos, montosPermitidos)) {
				registro.addError(MENSAJE_BLOQUEO);
			}
		}
	}

	private static void validarDatosContrato(
		List<SObject> registros,
		Map<Id, SObject> anteriores,
		String campoSolicitud,
		Set<String> permitidos,
		Set<String> montosPermitidos
	) {
		if (esAdministrador() || registros == null || registros.isEmpty()) {
			return;
		}
		Set<Id> solicitudesAprobadas = obtenerSolicitudesAprobadas(registros, campoSolicitud);
		for (SObject registro : registros) {
			if (!solicitudesAprobadas.contains((Id) registro.get(campoSolicitud))) {
				continue;
			}
			SObject anterior = anteriores.get(registro.Id);
			if (anterior == null || tieneCambiosNoPermitidos(registro, anterior, permitidos, montosPermitidos)) {
				registro.addError(MENSAJE_BLOQUEO);
			}
		}
	}

	public static void validarCamposCriticosSolicitud(
		List<ResidentialLoanApplication> registros,
		Map<Id, ResidentialLoanApplication> anteriores
	) {
		if (esAdministrador() || permitirDecisionComite || registros == null || anteriores == null) {
			return;
		}

		for (ResidentialLoanApplication registro : registros) {
			ResidentialLoanApplication anterior = anteriores.get(registro.Id);
			if (anterior?.FSC_SolicitudAprobadaPorComite__c != true) {
				continue;
			}

			for (String campo : CAMPOS_CRITICOS_SOLICITUD) {
				if (permitirPlanillaDesembolso && esValorVacio(anterior.get(campo))) {
					continue;
				}
				if (registro.get(campo) != anterior.get(campo)) {
					registro.addError(MENSAJE_BLOQUEO);
					break;
				}
			}
		}
	}

	private static void validarRegistrosBloqueados(List<SObject> registros, String campoSolicitud) {
		if (esAdministrador() || registros == null || registros.isEmpty()) {
			return;
		}

		Set<Id> solicitudesAprobadas = obtenerSolicitudesAprobadas(registros, campoSolicitud);
		for (SObject registro : registros) {
			if (solicitudesAprobadas.contains((Id) registro.get(campoSolicitud))) {
				registro.addError(MENSAJE_BLOQUEO);
			}
		}
	}

	private static Set<Id> obtenerSolicitudesAprobadas(List<SObject> registros, String campoSolicitud) {
		Set<Id> solicitudesIds = new Set<Id>();
		for (SObject registro : registros) {
			Id solicitudId = (Id) registro.get(campoSolicitud);
			if (solicitudId != null) {
				solicitudesIds.add(solicitudId);
			}
		}

		Set<Id> solicitudesAprobadas = new Set<Id>();
		if (solicitudesIds.isEmpty()) {
			return solicitudesAprobadas;
		}

		for (ResidentialLoanApplication solicitud : [
			SELECT Id
			FROM ResidentialLoanApplication
			WHERE Id IN :solicitudesIds AND FSC_SolicitudAprobadaPorComite__c = true
		]) {
			solicitudesAprobadas.add(solicitud.Id);
		}
		return solicitudesAprobadas;
	}

	// Las claves del describe vienen en minúsculas, por eso todos los conjuntos se comparan en minúsculas.
	private static Boolean tieneCambiosNoPermitidos(
		SObject registro,
		SObject anterior,
		Set<String> permitidos,
		Set<String> montosPermitidos
	) {
		Set<String> libres = minusculas(permitidos);
		Map<String, Schema.SObjectField> campos = registro.getSObjectType().getDescribe().fields.getMap();
		for (String campo : campos.keySet()) {
			String clave = campo.toLowerCase();
			Schema.DescribeFieldResult descripcion = campos.get(campo).getDescribe();
			if (libres.contains(clave) || CAMPOS_SISTEMA.contains(clave) || descripcion.isCalculated() || descripcion.isAutoNumber()) {
				continue;
			}
			if (montosPermitidos.contains(clave) && esValorVacio(anterior.get(campo))) {
				continue;
			}
			if (registro.get(campo) != anterior.get(campo)) {
				return true;
			}
		}
		return false;
	}

	private static Set<String> minusculas(Set<String> valores) {
		Set<String> resultado = new Set<String>();
		for (String valor : valores) {
			resultado.add(valor.toLowerCase());
		}
		return resultado;
	}

	private static Boolean esValorVacio(Object valor) {
		return valor == null || (valor instanceof String && String.isBlank((String) valor));
	}

	private static Boolean esAdministrador() {
		return FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR);
	}
}