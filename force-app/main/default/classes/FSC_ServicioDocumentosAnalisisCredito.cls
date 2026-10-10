/**
 * Identifica solicitudes elegibles y programa la generación de documentos de análisis.
 */
public with sharing class FSC_ServicioDocumentosAnalisisCredito {
	private static final String ESTADO_EN_PROCESO = 'En proceso';
	private static final String SUBESTADO_ANALISIS_CREDITO = 'Análisis de crédito';
	private static final Set<String> TIPOS_CREDITO_ELEGIBLES = new Set<String>{
		'FSC_Solicitud_Credito_Consumo',
		'FSC_Solicitud_Credito_Vehiculo',
		'FSC_Solicitud_Credito_Hipotecario',
		'FSC_Solicitud_Credito_PYME'
	};

	/**
	 * Programa de forma asíncrona la creación de los documentos para las solicitudes que
	 * acaban de entrar en En proceso - Análisis de crédito.
	 * @param solicitudesNuevas Registros posteriores a la actualización.
	 * @param solicitudesAnteriores Registros anteriores indexados por Id.
	 */
	public static void programarAlEntrarAnalisis(
		List<ResidentialLoanApplication> solicitudesNuevas,
		Map<Id, ResidentialLoanApplication> solicitudesAnteriores
	) {
		Set<Id> solicitudesIds = identificarSolicitudes(solicitudesNuevas, solicitudesAnteriores);
		if (solicitudesIds.isEmpty()) {
			return;
		}

		System.enqueueJob(new FSC_ColaGeneracionDocumentosAnalisis(new List<Id>(solicitudesIds)));
	}

	/** Genera al entrar y actualiza el informe cuando la solicitud sale de Análisis de crédito. */
	public static void programarSegunCambioAnalisis(
		List<ResidentialLoanApplication> solicitudesNuevas,
		Map<Id, ResidentialLoanApplication> solicitudesAnteriores
	) {
		Set<Id> entradasIds = identificarSolicitudes(solicitudesNuevas, solicitudesAnteriores);
		if (!entradasIds.isEmpty()) {
			System.enqueueJob(new FSC_ColaGeneracionDocumentosAnalisis(new List<Id>(entradasIds)));
		}

		Set<Id> salidasIds = identificarSalidas(solicitudesNuevas, solicitudesAnteriores);
		if (!salidasIds.isEmpty()) {
			System.enqueueJob(new FSC_ColaGeneracionDocumentosAnalisis(new List<Id>(salidasIds), true));
		}
	}

	private static Set<Id> identificarSolicitudes(
		List<ResidentialLoanApplication> solicitudesNuevas,
		Map<Id, ResidentialLoanApplication> solicitudesAnteriores
	) {
		Set<Id> solicitudesIds = new Set<Id>();
		if (solicitudesNuevas == null || solicitudesNuevas.isEmpty() || solicitudesAnteriores == null) {
			return solicitudesIds;
		}

		Map<Id, String> tipoCreditoPorRecordTypeId = obtenerTipoCreditoPorRecordTypeId();
		for (ResidentialLoanApplication solicitud : solicitudesNuevas) {
			ResidentialLoanApplication anterior = solicitudesAnteriores.get(solicitud.Id);
			if (anterior == null || !esEtapaObjetivo(solicitud) || esEtapaObjetivo(anterior)) {
				continue;
			}

			String tipoCredito = tipoCreditoPorRecordTypeId.get(solicitud.RecordTypeId);
			if (TIPOS_CREDITO_ELEGIBLES.contains(tipoCredito)) {
				solicitudesIds.add(solicitud.Id);
			}
		}
		return solicitudesIds;
	}

	private static Set<Id> identificarSalidas(
		List<ResidentialLoanApplication> solicitudesNuevas,
		Map<Id, ResidentialLoanApplication> solicitudesAnteriores
	) {
		Set<Id> solicitudesIds = new Set<Id>();
		if (solicitudesNuevas == null || solicitudesNuevas.isEmpty() || solicitudesAnteriores == null) {
			return solicitudesIds;
		}

		Map<Id, String> tipoCreditoPorRecordTypeId = obtenerTipoCreditoPorRecordTypeId();
		for (ResidentialLoanApplication solicitud : solicitudesNuevas) {
			ResidentialLoanApplication anterior = solicitudesAnteriores.get(solicitud.Id);
			if (anterior == null || !esEtapaObjetivo(anterior) || esEtapaObjetivo(solicitud)) {
				continue;
			}

			if (TIPOS_CREDITO_ELEGIBLES.contains(tipoCreditoPorRecordTypeId.get(solicitud.RecordTypeId))) {
				solicitudesIds.add(solicitud.Id);
			}
		}
		return solicitudesIds;
	}

	private static Boolean esEtapaObjetivo(ResidentialLoanApplication solicitud) {
		return solicitud != null && solicitud.Status == ESTADO_EN_PROCESO && solicitud.FSC_Subestado__c == SUBESTADO_ANALISIS_CREDITO;
	}

	private static Map<Id, String> obtenerTipoCreditoPorRecordTypeId() {
		Map<Id, String> resultado = new Map<Id, String>();
		for (String developerName : TIPOS_CREDITO_ELEGIBLES) {
			Schema.RecordTypeInfo info = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName().get(developerName);
			if (info != null) {
				resultado.put(info.getRecordTypeId(), developerName);
			}
		}
		return resultado;
	}
}