public without sharing class FSC_CreditoAprobadoLockService {
	private static final String PERMISO_ADMINISTRADOR = 'FSC_CP_Administrador';
	private static final String MENSAJE_BLOQUEO =
		'No es posible editar esta información del crédito ya que se encuentra Aprobada';
	private static final Set<String> CAMPOS_TASADOR_EDITABLES = new Set<String>{
		'FSC_EsTasadorExterno__c',
		'FSC_NombreTasadorExterno__c',
		'FSC_Tasado_Por__c'
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
	private static Boolean permitirDecisionComite = false;

	public static void iniciarDecisionComite() {
		permitirDecisionComite = true;
	}

	public static void finalizarDecisionComite() {
		permitirDecisionComite = false;
	}

	public static void validarParticipantes(List<LoanApplicant> registros) {
		List<SObject> registrosGenericos = new List<SObject>();
		for (LoanApplicant registro : registros) {
			registrosGenericos.add(registro);
		}
		validarRegistrosBloqueados(registrosGenericos, 'LoanApplicationId');
	}

	public static void validarActivosSolicitud(List<LoanApplicationAsset> registros) {
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
			if (anterior == null || tieneCambiosFueraDelTasador(registro, anterior)) {
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

	private static Boolean tieneCambiosFueraDelTasador(FSC_Garantia__c registro, FSC_Garantia__c anterior) {
		Map<String, Schema.SObjectField> campos = Schema.SObjectType.FSC_Garantia__c.fields.getMap();
		for (String campo : campos.keySet()) {
			Schema.DescribeFieldResult descripcion = campos.get(campo).getDescribe();
			if (
				CAMPOS_TASADOR_EDITABLES.contains(campo) ||
				descripcion.isCalculated() ||
				descripcion.isAutoNumber() ||
				campo == 'Id' ||
				campo == 'CreatedById' ||
				campo == 'CreatedDate' ||
				campo == 'LastModifiedById' ||
				campo == 'LastModifiedDate' ||
				campo == 'SystemModstamp'
			) {
				continue;
			}
			if (registro.get(campo) != anterior.get(campo)) {
				return true;
			}
		}
		return false;
	}

	private static Boolean esAdministrador() {
		return FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR);
	}
}