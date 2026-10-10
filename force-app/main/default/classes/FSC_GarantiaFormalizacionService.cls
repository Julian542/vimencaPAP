public inherited sharing class FSC_GarantiaFormalizacionService {
	public static final String SUBESTADO_FORMALIZACION = 'Formalización';
	public static final String SUBESTADO_DOCUMENTACION_DESEMBOLSO = 'Documentación para desembolso y firmas';
	public static final String RESPUESTA_SI = 'Sí';
	public static final String RESPUESTA_NO = 'No';
	private static final String SUBESTADO_COMPLETADO = 'Completado';
	private static final String SUBESTADO_ARCHIVO_CUSTODIA = 'Archivo y custodia';
	private static final String STATUS_CERRADA_GANADA = 'Cerrada Ganada';
	private static final String GRUPO_HIPOTECARIO = 'real-estate';
	private static final String GRUPO_VEHICULO = 'vehicle';
	private static final String MENSAJE_CIERRE_BLOQUEADO = 'No se puede cerrar la solicitud porque existen garantías hipotecarias o vehiculares pendientes de formalización.';
	private static final String MENSAJE_APROBACION_BLOQUEADA = 'No se puede aprobar Archivo y custodia porque existen garantías hipotecarias o vehiculares pendientes de formalización.';

	private static Map<String, String> grupoPorClase;

	public static Map<Id, String> resolverSubestadoPosteriorAFirmas(Set<Id> residentialLoanApplicationIds) {
		Map<Id, String> subestadoPorSolicitud = new Map<Id, String>();
		if (residentialLoanApplicationIds == null || residentialLoanApplicationIds.isEmpty()) {
			return subestadoPorSolicitud;
		}

		for (Id residentialLoanApplicationId : residentialLoanApplicationIds) {
			subestadoPorSolicitud.put(residentialLoanApplicationId, SUBESTADO_DOCUMENTACION_DESEMBOLSO);
		}

		// El enrutamiento de firmas no puede omitir garantías por los permisos del usuario que completa la firma.
		for (FSC_Garantia__c garantia : [
			SELECT FSC_Residential_Loan_Application__c, FSC_Clase_de_Garantia__c
			FROM FSC_Garantia__c
			WHERE FSC_Residential_Loan_Application__c IN :residentialLoanApplicationIds
			WITH SYSTEM_MODE
		]) {
			if (esGarantiaAplicable(garantia.FSC_Clase_de_Garantia__c)) {
				subestadoPorSolicitud.put(garantia.FSC_Residential_Loan_Application__c, SUBESTADO_FORMALIZACION);
			}
		}

		return subestadoPorSolicitud;
	}

	public static void validarCierre(List<ResidentialLoanApplication> nuevasSolicitudes, Map<Id, ResidentialLoanApplication> solicitudesAnteriores) {
		if (nuevasSolicitudes == null || nuevasSolicitudes.isEmpty()) {
			return;
		}

		Map<Id, ResidentialLoanApplication> solicitudesQueCierran = obtenerSolicitudesQueCierran(nuevasSolicitudes, solicitudesAnteriores);
		if (solicitudesQueCierran.isEmpty()) {
			return;
		}

		for (Id solicitudId : obtenerSolicitudesConGarantiaPendiente(solicitudesQueCierran.keySet())) {
			solicitudesQueCierran.get(solicitudId).addError(MENSAJE_CIERRE_BLOQUEADO);
		}
	}

	public static void validarAprobacionArchivoCustodia(Id residentialLoanApplicationId, String subestado) {
		if (residentialLoanApplicationId == null || subestado != SUBESTADO_ARCHIVO_CUSTODIA) {
			return;
		}

		if (obtenerSolicitudesConGarantiaPendiente(new Set<Id>{ residentialLoanApplicationId }).contains(residentialLoanApplicationId)) {
			throw new AuraHandledException(MENSAJE_APROBACION_BLOQUEADA);
		}
	}

	private static Map<Id, ResidentialLoanApplication> obtenerSolicitudesQueCierran(
		List<ResidentialLoanApplication> nuevasSolicitudes,
		Map<Id, ResidentialLoanApplication> solicitudesAnteriores
	) {
		Map<Id, ResidentialLoanApplication> solicitudesQueCierran = new Map<Id, ResidentialLoanApplication>();
		for (ResidentialLoanApplication solicitud : nuevasSolicitudes) {
			ResidentialLoanApplication anterior = solicitudesAnteriores?.get(solicitud.Id);
			if (solicitud.Id != null && estaCerrando(solicitud, anterior)) {
				solicitudesQueCierran.put(solicitud.Id, solicitud);
			}
		}
		return solicitudesQueCierran;
	}

	private static Set<Id> obtenerSolicitudesConGarantiaPendiente(Set<Id> solicitudIds) {
		Set<Id> solicitudesConGarantiaPendiente = new Set<Id>();
		// La regla de cierre es una invariante y debe detectar pendientes aunque el aprobador no vea la garantía.
		for (FSC_Garantia__c garantia : [
			SELECT
				FSC_Residential_Loan_Application__c,
				FSC_Clase_de_Garantia__c,
				FSC_Titulo_Registrado__c,
				FSC_Fecha_Formalizacion_Hipotecaria__c,
				FSC_Garantia_Constituida__c,
				FSC_Comentario_Formalizacion_Vehiculo__c,
				FSC_Fecha_Constitucion_Garantia__c
			FROM FSC_Garantia__c
			WHERE FSC_Residential_Loan_Application__c IN :solicitudIds
			WITH SYSTEM_MODE
		]) {
			String grupo = obtenerGrupo(garantia.FSC_Clase_de_Garantia__c);
			if (!esGrupoAplicable(grupo)) {
				continue;
			}

			if (!estaFormalizada(garantia, grupo)) {
				solicitudesConGarantiaPendiente.add(garantia.FSC_Residential_Loan_Application__c);
			}
		}
		return solicitudesConGarantiaPendiente;
	}

	public static Boolean esGarantiaAplicable(String claseGarantia) {
		return esGrupoAplicable(obtenerGrupo(claseGarantia));
	}

	public static Boolean estaFormalizada(FSC_Garantia__c garantia) {
		if (garantia == null) {
			return false;
		}
		return estaFormalizada(garantia, obtenerGrupo(garantia.FSC_Clase_de_Garantia__c));
	}

	public static String obtenerGrupo(String claseGarantia) {
		if (String.isBlank(claseGarantia)) {
			return null;
		}
		cargarGrupos();
		return grupoPorClase.get(normalizar(claseGarantia));
	}

	private static Boolean estaCerrando(ResidentialLoanApplication solicitud, ResidentialLoanApplication anterior) {
		Boolean cambiaACerradaGanada = solicitud.Status == STATUS_CERRADA_GANADA && (anterior == null || anterior.Status != STATUS_CERRADA_GANADA);
		Boolean cambiaACompletado =
			solicitud.FSC_Subestado__c == SUBESTADO_COMPLETADO && (anterior == null || anterior.FSC_Subestado__c != SUBESTADO_COMPLETADO);
		return cambiaACerradaGanada || cambiaACompletado;
	}

	private static Boolean estaFormalizada(FSC_Garantia__c garantia, String grupo) {
		if (grupo == GRUPO_HIPOTECARIO) {
			return garantia.FSC_Titulo_Registrado__c == RESPUESTA_SI && garantia.FSC_Fecha_Formalizacion_Hipotecaria__c != null;
		}
		if (grupo == GRUPO_VEHICULO) {
			return garantia.FSC_Garantia_Constituida__c == RESPUESTA_SI &&
				garantia.FSC_Fecha_Constitucion_Garantia__c != null &&
				!String.isBlank(garantia.FSC_Comentario_Formalizacion_Vehiculo__c);
		}
		return true;
	}

	private static Boolean esGrupoAplicable(String grupo) {
		return grupo == GRUPO_HIPOTECARIO || grupo == GRUPO_VEHICULO;
	}

	private static void cargarGrupos() {
		if (grupoPorClase != null) {
			return;
		}

		// Reconoce los textos historicos del CMT y la descripcion actual del API para la misma clase.
		grupoPorClase = FSC_CatalogoGarantiaService.getGrupoPorClase();
	}

	private static String normalizar(String valor) {
		return FSC_CatalogoGarantiaService.normalizarClave(valor);
	}
}