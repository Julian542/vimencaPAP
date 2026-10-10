/**
 * Genera y publica en Salesforce Files los documentos PDF de análisis de crédito.
 */
public with sharing class FSC_ColaGeneracionDocumentosAnalisis implements Queueable, Database.AllowsCallouts {
	private static final Integer TAMANO_BLOQUE = 5;
	private static final Integer PROFUNDIDAD_MAXIMA = 40;
	private static final String ESTADO_EN_PROCESO = 'En proceso';
	private static final String SUBESTADO_ANALISIS_CREDITO = 'Análisis de crédito';
	private static final String TIPO_CONSUMO = 'FSC_Solicitud_Credito_Consumo';
	private static final String TIPO_VEHICULO = 'FSC_Solicitud_Credito_Vehiculo';
	private static final String TIPO_HIPOTECARIO = 'FSC_Solicitud_Credito_Hipotecario';
	private static final String TIPO_PYME = 'FSC_Solicitud_Credito_PYME';
	private static final String SEPARADOR_LOG = '\n--------------------\n';
	public static final String DOCUMENTO_AMBOS = 'AMBOS';
	public static final String DOCUMENTO_INFORME = 'INFORME';
	public static final String DOCUMENTO_CAPACIDAD = 'CAPACIDAD';

	private final List<Id> solicitudesIds;
	private final Integer profundidad;
	private final String documentoObjetivo;
	private final Boolean forzarNuevaVersion;

	/**
	 * Crea un trabajo de generación para las solicitudes indicadas.
	 * @param solicitudesIds Ids de ResidentialLoanApplication.
	 */
	public FSC_ColaGeneracionDocumentosAnalisis(List<Id> solicitudesIds) {
		this(solicitudesIds, 0, DOCUMENTO_AMBOS, false);
	}

	/** Crea un trabajo que regenera únicamente el informe de crédito existente. */
	public FSC_ColaGeneracionDocumentosAnalisis(List<Id> solicitudesIds, Boolean regenerarSoloInforme) {
		this(
			solicitudesIds,
			0,
			regenerarSoloInforme == true ? DOCUMENTO_INFORME : DOCUMENTO_AMBOS,
			regenerarSoloInforme == true
		);
	}

	/** Crea un trabajo que reemplaza uno de los documentos editables. */
	public FSC_ColaGeneracionDocumentosAnalisis(List<Id> solicitudesIds, String documentoObjetivo) {
		this(solicitudesIds, 0, validarDocumentoObjetivo(documentoObjetivo), true);
	}

	/**
	 * Crea un trabajo de generación con control explícito de encadenamiento.
	 * @param solicitudesIds Ids de ResidentialLoanApplication.
	 * @param profundidad Profundidad actual de la cadena Queueable.
	 */
	public FSC_ColaGeneracionDocumentosAnalisis(List<Id> solicitudesIds, Integer profundidad) {
		this(solicitudesIds, profundidad, DOCUMENTO_AMBOS, false);
	}

	private FSC_ColaGeneracionDocumentosAnalisis(
		List<Id> solicitudesIds,
		Integer profundidad,
		String documentoObjetivo,
		Boolean forzarNuevaVersion
	) {
		this.solicitudesIds = solicitudesIds == null ? new List<Id>() : new List<Id>(solicitudesIds);
		this.profundidad = profundidad ?? 0;
		this.documentoObjetivo = validarDocumentoObjetivo(documentoObjetivo);
		this.forzarNuevaVersion = forzarNuevaVersion == true;
	}

	/**
	 * Genera hasta diez solicitudes por transacción y encadena el remanente.
	 * @param contexto Contexto del trabajo Queueable.
	 */
	public void execute(QueueableContext contexto) {
		if (solicitudesIds.isEmpty()) {
			return;
		}

		List<Id> bloqueIds = new List<Id>();
		List<Id> restantesIds = new List<Id>();
		for (Integer indice = 0; indice < solicitudesIds.size(); indice++) {
			if (indice < TAMANO_BLOQUE) {
				bloqueIds.add(solicitudesIds[indice]);
			} else {
				restantesIds.add(solicitudesIds[indice]);
			}
		}

		procesarBloque(bloqueIds, documentoObjetivo, forzarNuevaVersion);
		if (!restantesIds.isEmpty() && profundidad < PROFUNDIDAD_MAXIMA) {
			System.enqueueJob(
				new FSC_ColaGeneracionDocumentosAnalisis(
					restantesIds,
					profundidad + 1,
					documentoObjetivo,
					forzarNuevaVersion
				)
			);
		}
	}

	private static void procesarBloque(List<Id> bloqueIds, String documentoObjetivo, Boolean forzarNuevaVersion) {
		List<ResidentialLoanApplication> solicitudes = [
			SELECT Id, Name, Status, FSC_Subestado__c, FSC_Monto__c, FSC_LogErrores__c, RecordType.DeveloperName
			FROM ResidentialLoanApplication
			WHERE Id IN :bloqueIds
			WITH USER_MODE
		];
		Map<Id, Map<String, Id>> archivosPorSolicitud = obtenerArchivosExistentes(new Set<Id>(bloqueIds));
		Map<Id, String> ajustesPorDocumento = obtenerAjustesDocumentos(archivosPorSolicitud);
		Set<Id> solicitudesConGarantia = obtenerSolicitudesConGarantia(new Set<Id>(bloqueIds));
		Map<Id, String> logActualPorSolicitud = new Map<Id, String>();
		Map<Id, String> logPendientePorSolicitud = new Map<Id, String>();
		List<ArchivoPendiente> archivosPendientes = new List<ArchivoPendiente>();

		for (ResidentialLoanApplication solicitud : solicitudes) {
			logActualPorSolicitud.put(solicitud.Id, solicitud.FSC_LogErrores__c);
			if (!esSolicitudProcesable(solicitud, forzarNuevaVersion)) {
				continue;
			}

			Map<String, Id> archivosExistentes = archivosPorSolicitud.get(solicitud.Id);
			if (archivosExistentes == null) {
				archivosExistentes = new Map<String, Id>();
			}

			Boolean esPyme = solicitud.RecordType.DeveloperName == TIPO_PYME;
			if (!esPyme && (documentoObjetivo == DOCUMENTO_AMBOS || documentoObjetivo == DOCUMENTO_CAPACIDAD)) {
				String tituloCapacidad = construirTitulo('Capacidad de Pago', solicitud);
				generarDocumento(
					solicitud,
					tituloCapacidad,
					Page.FSC_CapacidadPagoPDF,
					archivosExistentes.get(tituloCapacidad),
					forzarNuevaVersion,
					DOCUMENTO_CAPACIDAD,
					ajustesPorDocumento.get(archivosExistentes.get(tituloCapacidad)),
					archivosPendientes,
					logActualPorSolicitud,
					logPendientePorSolicitud
				);
			}

			if (documentoObjetivo == DOCUMENTO_AMBOS || documentoObjetivo == DOCUMENTO_INFORME) {
				String tituloInforme = construirTitulo(
					resolverNombreInforme(solicitud, solicitudesConGarantia.contains(solicitud.Id)),
					solicitud
				);
				Id informeExistenteId = buscarInformeExistente(archivosExistentes, tituloInforme);
				generarDocumento(
					solicitud,
					tituloInforme,
					esPyme ? Page.FSC_InformeCreditoPymePDF : Page.FSC_InformeCreditoAnalisisPDF,
					informeExistenteId,
					forzarNuevaVersion,
					DOCUMENTO_INFORME,
					ajustesPorDocumento.get(informeExistenteId),
					archivosPendientes,
					logActualPorSolicitud,
					logPendientePorSolicitud
				);
			}
		}

		guardarArchivos(archivosPendientes, logActualPorSolicitud, logPendientePorSolicitud);
		guardarErrores(logPendientePorSolicitud);
	}

	private static void generarDocumento(
		ResidentialLoanApplication solicitud,
		String titulo,
		PageReference pagina,
		Id contentDocumentId,
		Boolean forzarNuevaVersion,
		String tipoDocumento,
		String ajustesJson,
		List<ArchivoPendiente> archivosPendientes,
		Map<Id, String> logActualPorSolicitud,
		Map<Id, String> logPendientePorSolicitud
	) {
		if (contentDocumentId != null && !forzarNuevaVersion) {
			return;
		}

		try {
			pagina.getParameters().put('id', solicitud.Id);
			pagina.getParameters().put('tipoDocumento', tipoDocumento);
			Blob contenido = Test.isRunningTest() ? Blob.valueOf('PDF DE PRUEBA') : pagina.getContentAsPDF();
			if (contenido == null || contenido.size() == 0) {
				throw new FSC_ErrorGeneracionDocumentoException('El contenido PDF se generó vacío.');
			}
			archivosPendientes.add(new ArchivoPendiente(
				solicitud.Id,
				titulo,
				contenido,
				contentDocumentId,
				ajustesJson,
				tipoDocumento == DOCUMENTO_CAPACIDAD
					? FSC_ChecklistDocsPrecargaService.CAPACIDAD_PAGO
					: FSC_ChecklistDocsPrecargaService.INFORME_CREDITO
			));
		} catch (Exception error) {
			registrarError(
				logActualPorSolicitud,
				logPendientePorSolicitud,
				solicitud.Id,
				'No se pudo generar ' + titulo + ': ' + limitar(error.getMessage(), 500)
			);
		}
	}

	private static void guardarArchivos(
		List<ArchivoPendiente> archivosPendientes,
		Map<Id, String> logActualPorSolicitud,
		Map<Id, String> logPendientePorSolicitud
	) {
		if (archivosPendientes.isEmpty()) {
			return;
		}

		List<ContentVersion> versiones = new List<ContentVersion>();
		for (ArchivoPendiente archivo : archivosPendientes) {
			ContentVersion version = new ContentVersion(
				Title = archivo.titulo,
				PathOnClient = archivo.titulo + '.pdf',
				VersionData = archivo.contenido,
				FSC_DatosEditadosAnalisis__c = archivo.ajustesJson,
				FSC_ClaveTecnicaPrecarga__c = archivo.claveTecnica
			);
			if (archivo.contentDocumentId == null) {
				version.FirstPublishLocationId = archivo.solicitudId;
			} else {
				version.ContentDocumentId = archivo.contentDocumentId;
			}
			versiones.add(version);
		}

		// La metadata técnica del PDF no se expone mediante perfiles; la cola autorizada la escribe en modo sistema.
		Database.SaveResult[] resultados = Database.insert(versiones, false, AccessLevel.SYSTEM_MODE);
		Map<Id, Id> solicitudPorVersionNueva = new Map<Id, Id>();
		for (Integer indice = 0; indice < resultados.size(); indice++) {
			if (resultados[indice].isSuccess()) {
				if (archivosPendientes[indice].contentDocumentId == null) {
					solicitudPorVersionNueva.put(resultados[indice].getId(), archivosPendientes[indice].solicitudId);
				}
				continue;
			}
			registrarError(
				logActualPorSolicitud,
				logPendientePorSolicitud,
				archivosPendientes[indice].solicitudId,
				'No se pudo guardar ' + archivosPendientes[indice].titulo + ': ' + obtenerMensajeErrores(resultados[indice].getErrors())
			);
		}
		habilitarEdicionDocumentos(solicitudPorVersionNueva, logActualPorSolicitud, logPendientePorSolicitud);
	}

	private static void habilitarEdicionDocumentos(
		Map<Id, Id> solicitudPorVersionNueva,
		Map<Id, String> logActualPorSolicitud,
		Map<Id, String> logPendientePorSolicitud
	) {
		if (solicitudPorVersionNueva.isEmpty()) {
			return;
		}
		Map<Id, Id> solicitudPorDocumento = new Map<Id, Id>();
		for (ContentVersion version : [
			SELECT Id, ContentDocumentId
			FROM ContentVersion
			WHERE Id IN :solicitudPorVersionNueva.keySet()
		]) {
			solicitudPorDocumento.put(version.ContentDocumentId, solicitudPorVersionNueva.get(version.Id));
		}
		List<ContentDocumentLink> enlaces = [
			SELECT Id, ContentDocumentId, LinkedEntityId, ShareType
			FROM ContentDocumentLink
			WHERE ContentDocumentId IN :solicitudPorDocumento.keySet()
			AND LinkedEntityId IN :solicitudPorVersionNueva.values()
		];
		List<ContentDocumentLink> enlacesPorActualizar = new List<ContentDocumentLink>();
		for (ContentDocumentLink enlace : enlaces) {
			if (enlace.ShareType != 'I') {
				enlace.ShareType = 'I';
				enlacesPorActualizar.add(enlace);
			}
		}
		// El acceso al archivo sigue los permisos de la solicitud.
		Database.SaveResult[] resultados = Database.update(enlacesPorActualizar, false, AccessLevel.SYSTEM_MODE);
		for (Integer indice = 0; indice < resultados.size(); indice++) {
			if (!resultados[indice].isSuccess()) {
				registrarError(
					logActualPorSolicitud,
					logPendientePorSolicitud,
					solicitudPorDocumento.get(enlacesPorActualizar[indice].ContentDocumentId),
					'No se pudo habilitar la edición del PDF: ' + obtenerMensajeErrores(resultados[indice].getErrors())
				);
			}
		}
		compartirConAnalistas(solicitudPorDocumento, logActualPorSolicitud, logPendientePorSolicitud);
	}

	private static void compartirConAnalistas(
		Map<Id, Id> solicitudPorDocumento,
		Map<Id, String> logActualPorSolicitud,
		Map<Id, String> logPendientePorSolicitud
	) {
		Map<Id, Set<Id>> analistasPorSolicitud = new AnalistasPendientesSelector().seleccionar(
			new Set<Id>(solicitudPorDocumento.values())
		);
		Set<Id> analistasIds = new Set<Id>();
		for (Set<Id> ids : analistasPorSolicitud.values()) {
			analistasIds.addAll(ids);
		}
		if (analistasIds.isEmpty()) {
			return;
		}
		Set<String> enlacesExistentes = new Set<String>();
		for (ContentDocumentLink enlace : [
			SELECT ContentDocumentId, LinkedEntityId
			FROM ContentDocumentLink
			WHERE ContentDocumentId IN :solicitudPorDocumento.keySet()
			AND LinkedEntityId IN :analistasIds
		]) {
			enlacesExistentes.add(enlace.ContentDocumentId + ':' + enlace.LinkedEntityId);
		}
		List<ContentDocumentLink> enlacesNuevos = new List<ContentDocumentLink>();
		for (Id documentoId : solicitudPorDocumento.keySet()) {
			Set<Id> analistas = analistasPorSolicitud.get(solicitudPorDocumento.get(documentoId));
			if (analistas == null) {
				continue;
			}
			for (Id analistaId : analistas) {
				if (analistaId == UserInfo.getUserId() || enlacesExistentes.contains(documentoId + ':' + analistaId)) {
					continue;
				}
				enlacesNuevos.add(new ContentDocumentLink(
					ContentDocumentId = documentoId,
					LinkedEntityId = analistaId,
					ShareType = 'C',
					Visibility = 'AllUsers'
				));
			}
		}
		if (enlacesNuevos.isEmpty()) {
			return;
		}
		Database.SaveResult[] resultados = Database.insert(enlacesNuevos, false, AccessLevel.SYSTEM_MODE);
		for (Integer indice = 0; indice < resultados.size(); indice++) {
			if (!resultados[indice].isSuccess()) {
				registrarError(
					logActualPorSolicitud,
					logPendientePorSolicitud,
					solicitudPorDocumento.get(enlacesNuevos[indice].ContentDocumentId),
					'No se pudo compartir el PDF con el analista: ' + obtenerMensajeErrores(resultados[indice].getErrors())
				);
			}
		}
	}

	private without sharing class AnalistasPendientesSelector {
		public Map<Id, Set<Id>> seleccionar(Set<Id> solicitudesIds) {
			Map<Id, Set<Id>> resultado = new Map<Id, Set<Id>>();
			for (ProcessInstanceWorkitem pendiente : [
				SELECT ActorId, ProcessInstance.TargetObjectId
				FROM ProcessInstanceWorkitem
				WHERE ProcessInstance.TargetObjectId IN :solicitudesIds
				AND ProcessInstance.ProcessDefinition.DeveloperName = 'FSC_AnalistasDeCredito'
				WITH SYSTEM_MODE
			]) {
				if (pendiente.ActorId == null || pendiente.ActorId.getSObjectType() != User.SObjectType) {
					continue;
				}
				Id solicitudId = pendiente.ProcessInstance.TargetObjectId;
				if (!resultado.containsKey(solicitudId)) {
					resultado.put(solicitudId, new Set<Id>());
				}
				resultado.get(solicitudId).add(pendiente.ActorId);
			}
			return resultado;
		}
	}

	private static Map<Id, Map<String, Id>> obtenerArchivosExistentes(Set<Id> solicitudesIds) {
		Map<Id, Map<String, Id>> resultado = new Map<Id, Map<String, Id>>();
		for (ContentDocumentLink enlace : [
			SELECT LinkedEntityId, ContentDocumentId, ContentDocument.Title
			FROM ContentDocumentLink
			WHERE LinkedEntityId IN :solicitudesIds
			WITH USER_MODE
		]) {
			if (!resultado.containsKey(enlace.LinkedEntityId)) {
				resultado.put(enlace.LinkedEntityId, new Map<String, Id>());
			}
			resultado.get(enlace.LinkedEntityId).put(enlace.ContentDocument.Title, enlace.ContentDocumentId);
		}
		return resultado;
	}

	private static Map<Id, String> obtenerAjustesDocumentos(Map<Id, Map<String, Id>> archivosPorSolicitud) {
		Set<Id> documentosIds = new Set<Id>();
		for (Map<String, Id> archivos : archivosPorSolicitud.values()) {
			documentosIds.addAll(archivos.values());
		}
		Map<Id, String> resultado = new Map<Id, String>();
		if (documentosIds.isEmpty()) {
			return resultado;
		}
		for (ContentVersion versionActual : [
			SELECT ContentDocumentId, FSC_DatosEditadosAnalisis__c
			FROM ContentVersion
			WHERE ContentDocumentId IN :documentosIds AND IsLatest = true
		]) {
			resultado.put(versionActual.ContentDocumentId, versionActual.FSC_DatosEditadosAnalisis__c);
		}
		return resultado;
	}

	private static Set<Id> obtenerSolicitudesConGarantia(Set<Id> solicitudesIds) {
		Set<Id> resultado = new Set<Id>();
		for (FSC_Garantia__c garantia : [
			SELECT FSC_Residential_Loan_Application__c
			FROM FSC_Garantia__c
			WHERE FSC_Residential_Loan_Application__c IN :solicitudesIds
			WITH USER_MODE
		]) {
			resultado.add(garantia.FSC_Residential_Loan_Application__c);
		}
		return resultado;
	}

	private static Id buscarInformeExistente(Map<String, Id> archivosExistentes, String tituloEsperado) {
		if (archivosExistentes.containsKey(tituloEsperado)) {
			return archivosExistentes.get(tituloEsperado);
		}
		for (String titulo : archivosExistentes.keySet()) {
			if (titulo.startsWith('Informe de Crédito')) {
				return archivosExistentes.get(titulo);
			}
		}
		return null;
	}

	private static Boolean esSolicitudProcesable(ResidentialLoanApplication solicitud, Boolean regenerarSoloInforme) {
		String tipo = solicitud.RecordType.DeveloperName;
		Boolean tipoElegible = tipo == TIPO_CONSUMO ||
			tipo == TIPO_VEHICULO ||
			tipo == TIPO_HIPOTECARIO ||
			tipo == TIPO_PYME;
		return tipoElegible &&
			(regenerarSoloInforme || (solicitud.Status == ESTADO_EN_PROCESO && solicitud.FSC_Subestado__c == SUBESTADO_ANALISIS_CREDITO));
	}

	private static String validarDocumentoObjetivo(String documentoObjetivo) {
		String normalizado = String.isBlank(documentoObjetivo) ? DOCUMENTO_AMBOS : documentoObjetivo.trim().toUpperCase();
		if (
			normalizado != DOCUMENTO_AMBOS &&
			normalizado != DOCUMENTO_INFORME &&
			normalizado != DOCUMENTO_CAPACIDAD
		) {
			throw new FSC_ErrorGeneracionDocumentoException('Tipo de documento de análisis no soportado.');
		}
		return normalizado;
	}

	private static String resolverNombreInforme(ResidentialLoanApplication solicitud, Boolean tieneGarantia) {
		String tipo = solicitud.RecordType.DeveloperName;
		if (tipo == TIPO_PYME) {
			return 'Informe de Crédito Pyme - Persona Física';
		}
		if (tipo == TIPO_HIPOTECARIO) {
			return 'Informe de Crédito Hipotecario';
		}
		if (tipo == TIPO_VEHICULO || (tipo == TIPO_CONSUMO && tieneGarantia)) {
			return 'Informe de Crédito de Consumo - Vehículo';
		}
		return 'Informe de Crédito de Consumo';
	}

	private static String construirTitulo(String tipoDocumento, ResidentialLoanApplication solicitud) {
		String nombreSolicitud = String.isBlank(solicitud.Name) ? String.valueOf(solicitud.Id) : solicitud.Name;
		nombreSolicitud = nombreSolicitud.replace('/', '-').replace('\\', '-').replace(':', '-');
		return tipoDocumento + ' - ' + nombreSolicitud;
	}

	@TestVisible
	private static void registrarError(
		Map<Id, String> logActualPorSolicitud,
		Map<Id, String> logPendientePorSolicitud,
		Id solicitudId,
		String mensaje
	) {
		String actual = logPendientePorSolicitud.containsKey(solicitudId)
			? logPendientePorSolicitud.get(solicitudId)
			: logActualPorSolicitud.get(solicitudId);
		String entrada = Datetime.now().format('yyyy-MM-dd HH:mm:ss') + ' | ' + mensaje;
		String nuevoLog = String.isBlank(actual) ? entrada : actual + SEPARADOR_LOG + entrada;
		logPendientePorSolicitud.put(solicitudId, limitar(nuevoLog, 100000));
	}

	private static void guardarErrores(Map<Id, String> logPendientePorSolicitud) {
		if (logPendientePorSolicitud.isEmpty()) {
			return;
		}
		List<ResidentialLoanApplication> actualizaciones = new List<ResidentialLoanApplication>();
		for (Id solicitudId : logPendientePorSolicitud.keySet()) {
			actualizaciones.add(new ResidentialLoanApplication(Id = solicitudId, FSC_LogErrores__c = logPendientePorSolicitud.get(solicitudId)));
		}
		Database.SaveResult[] resultados = Database.update(actualizaciones, false, AccessLevel.USER_MODE);
		for (Integer indice = 0; indice < resultados.size(); indice++) {
			if (!resultados[indice].isSuccess()) {
				System.debug(LoggingLevel.ERROR, 'No se pudo registrar el error del PDF para ' +
					actualizaciones[indice].Id + ': ' + obtenerMensajeErrores(resultados[indice].getErrors()));
			}
		}
	}

	private static String obtenerMensajeErrores(Database.Error[] errores) {
		List<String> mensajes = new List<String>();
		for (Database.Error errorItem : errores) {
			mensajes.add(limitar(errorItem.getMessage(), 300));
		}
		return String.join(mensajes, ' | ');
	}

	@TestVisible
	private static String limitar(String valor, Integer longitud) {
		if (String.isBlank(valor) || valor.length() <= longitud) {
			return valor;
		}
		return valor.substring(0, longitud) + '...';
	}

	private class ArchivoPendiente {
		private Id solicitudId;
		private String titulo;
		private Blob contenido;
		private Id contentDocumentId;
		private String ajustesJson;
		private String claveTecnica;

		private ArchivoPendiente(
			Id solicitudId,
			String titulo,
			Blob contenido,
			Id contentDocumentId,
			String ajustesJson,
			String claveTecnica
		) {
			this.solicitudId = solicitudId;
			this.titulo = titulo;
			this.contenido = contenido;
			this.contentDocumentId = contentDocumentId;
			this.ajustesJson = ajustesJson;
			this.claveTecnica = claveTecnica;
		}
	}

	public class FSC_ErrorGeneracionDocumentoException extends Exception {
	}
}