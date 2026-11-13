public with sharing class FSC_ChecklistDocsPrecargaService {
	public static final String SOLICITUD_CREDITO = 'SOLICITUD_CREDITO';
	public static final String CAPACIDAD_PAGO = 'CAPACIDAD_PAGO';
	public static final String INFORME_CREDITO = 'INFORME_CREDITO';
	public static final String DOCUMENTO_IDENTIDAD = 'DOCUMENTO_IDENTIDAD';
	public static final String CEDULA_FIRMANTES = 'CEDULA_FIRMANTES';
	public static final String CEDULA_ACCIONISTAS = 'CEDULA_ACCIONISTAS';
	public static final String KYC = 'KYC';
	public static final String CONTRATO_UNICO = 'CONTRATO_UNICO';
	public static final String CONTRATOS_FIRMADOS = 'CONTRATOS_FIRMADOS';
	public static final String PAGARE = 'PAGARE';
	public static final String PAGARE_COMPLEMENTARIO = 'PAGARE_COMPLEMENTARIO';
	public static final String RNC = 'RNC';
	public static final String REGISTRO_MERCANTIL = 'REGISTRO_MERCANTIL';
	public static final String ESTATUTOS_SOCIALES = 'ESTATUTOS_SOCIALES';
	public static final String ACTA_CONSTITUTIVA = 'ACTA_CONSTITUTIVA';
	public static final String ACTA_CONDOMINIO = 'ACTA_CONDOMINIO';
	public static final String PODER_AUTORIZACION = 'PODER_AUTORIZACION';
	public static final String AUTORIZACION_PRESTAMO = 'AUTORIZACION_PRESTAMO';
	public static final String ACTA_DESIGNACION_FIRMANTES = 'ACTA_DESIGNACION_FIRMANTES';
	public static final String TARJETA_FIRMAS = 'TARJETA_FIRMAS';
	public static final String NOMINA_PRESENCIA = 'NOMINA_PRESENCIA';
	public static final String SOPORTE_INGRESOS = 'SOPORTE_INGRESOS';
	public static final String CARTA_LABORAL = 'CARTA_LABORAL';
	public static final String COMPROBANTE_INGRESOS = 'COMPROBANTE_INGRESOS';

	private class FileCandidate {
		private Id contentDocumentId;
		private Id groupId;
		private Datetime createdDate;
		private Integer priority;
		private Boolean linkToRla;

		private FileCandidate(
			Id contentDocumentId,
			Id groupId,
			Datetime createdDate,
			Integer priority,
			Boolean linkToRla
		) {
			this.contentDocumentId = contentDocumentId;
			this.groupId = groupId;
			this.createdDate = createdDate;
			this.priority = priority;
			this.linkToRla = linkToRla;
		}
	}

	public static void sincronizar(
		Id rlaId,
		Id accountId,
		List<FSC_ChecklistDocumentos__c> documentos,
		Map<Id, FSC_SolicitudDeCreditoYChecklistDeDocs__c> filasPorDocumentoId
	) {
		if (rlaId == null || documentos == null || documentos.isEmpty() || filasPorDocumentoId == null) {
			return;
		}

		Map<String, Set<Id>> filasPorClave = obtenerFilasPorClave(documentos, filasPorDocumentoId);
		if (filasPorClave.isEmpty()) {
			return;
		}

		// mergeQA todavía usa una sola fila para ambos documentos de análisis.
		agregarDestinoAlternativo(filasPorClave, INFORME_CREDITO, CAPACIDAD_PAGO);
		agregarDestinoAlternativo(filasPorClave, CARTA_LABORAL, SOPORTE_INGRESOS);
		agregarDestinoAlternativo(filasPorClave, COMPROBANTE_INGRESOS, SOPORTE_INGRESOS);

		Map<String, List<FileCandidate>> candidatosPorClave = obtenerCandidatos(rlaId, accountId);
		List<ContentDocumentLink> enlacesNuevos = construirEnlaces(rlaId, filasPorClave, candidatosPorClave);
		if (!enlacesNuevos.isEmpty()) {
			for (Database.SaveResult resultado : Database.insert(enlacesNuevos, false)) {
				if (!resultado.isSuccess()) {
					System.debug(LoggingLevel.WARN, 'No se pudo precargar un documento del checklist: ' + resultado.getErrors()[0].getMessage());
				}
			}
		}
	}

	public static String resolveGeneratedKey(String title) {
		String value = normalizar(title);
		if (String.isBlank(value)) {
			return null;
		}

		if (value.startsWith('informe de credito')) {
			return INFORME_CREDITO;
		}
		if (value.startsWith('capacidad de pago')) {
			return CAPACIDAD_PAGO;
		}
		if (
			value.startsWith('credito pyme ') ||
			value.startsWith('credito consumo ') ||
			value.startsWith('credito vehiculo ') ||
			value.startsWith('credito vehicular ') ||
			value.startsWith('credito hipotecario ') ||
			value.startsWith('solicitud de credito consumo')
		) {
			return SOLICITUD_CREDITO;
		}
		if (value.startsWith('conozca su cliente')) {
			return KYC;
		}
		if (value.startsWith('contrato unico')) {
			return CONTRATO_UNICO;
		}
		if (value.contains('pagare complementario') && value.contains('firmado')) {
			return PAGARE_COMPLEMENTARIO;
		}
		if (value.contains('pagare') && value.contains('firmado')) {
			return PAGARE;
		}
		if (esContratoFirmado(value)) {
			return CONTRATOS_FIRMADOS;
		}
		return null;
	}

	private static Map<String, Set<Id>> obtenerFilasPorClave(
		List<FSC_ChecklistDocumentos__c> documentos,
		Map<Id, FSC_SolicitudDeCreditoYChecklistDeDocs__c> filasPorDocumentoId
	) {
		Map<String, Set<Id>> resultado = new Map<String, Set<Id>>();
		for (FSC_ChecklistDocumentos__c documento : documentos) {
			FSC_SolicitudDeCreditoYChecklistDeDocs__c fila = filasPorDocumentoId.get(documento.Id);
			if (fila == null || fila.Id == null) {
				continue;
			}

			String clave = normalizarClave(documento.FSC_ClaveTecnicaPrecarga__c);
			if (String.isBlank(clave)) {
				clave = inferirClaveEtiqueta(documento.FSC_NombreDelDocumento__c);
			}
			if (String.isBlank(clave)) {
				continue;
			}

			if (!resultado.containsKey(clave)) {
				resultado.put(clave, new Set<Id>());
			}
			resultado.get(clave).add(fila.Id);
		}
		return resultado;
	}

	private static void agregarDestinoAlternativo(Map<String, Set<Id>> filasPorClave, String clave, String claveDestino) {
		if (!filasPorClave.containsKey(clave) && filasPorClave.containsKey(claveDestino)) {
			filasPorClave.put(clave, new Set<Id>(filasPorClave.get(claveDestino)));
		}
	}

	private static Map<String, List<FileCandidate>> obtenerCandidatos(Id rlaId, Id accountId) {
		Map<String, List<FileCandidate>> resultado = new Map<String, List<FileCandidate>>();
		Map<Id, String> clavePorDciId = new Map<Id, String>();

		if (accountId != null) {
			for (DocumentChecklistItem item : [
				SELECT Id, Name, Status, LastModifiedDate
				FROM DocumentChecklistItem
				WHERE ParentRecordId = :accountId
				ORDER BY LastModifiedDate DESC
			]) {
				if (normalizar(item.Status) != 'aprobado') {
					continue;
				}
				String clave = inferirClaveEtiqueta(item.Name);
				if (!String.isBlank(clave)) {
					clavePorDciId.put(item.Id, clave);
				}
			}
		}

		Set<Id> entidadesOrigen = new Set<Id>{ rlaId };
		if (accountId != null) {
			entidadesOrigen.add(accountId);
		}
		entidadesOrigen.addAll(clavePorDciId.keySet());

		for (ContentDocumentLink enlace : [
			SELECT LinkedEntityId, ContentDocumentId, ContentDocument.Title,
				ContentDocument.CreatedDate,
				ContentDocument.LatestPublishedVersion.FSC_ClaveTecnicaPrecarga__c
			FROM ContentDocumentLink
			WHERE LinkedEntityId IN :entidadesOrigen
		]) {
			String titulo = normalizar(enlace.ContentDocument.Title);
			Boolean esOrigenRla = enlace.LinkedEntityId == rlaId;
			Boolean esPagareFirmadoRla = esOrigenRla && esPagareFirmado(titulo);
			Boolean esContratoFirmadoRla = esOrigenRla && esContratoFirmado(titulo);
			String claveTecnica = normalizarClave(
				enlace.ContentDocument.LatestPublishedVersion.FSC_ClaveTecnicaPrecarga__c
			);
			String clave = claveTecnica;
			Integer prioridad = 100;
			Id grupoId = enlace.ContentDocumentId;
			Boolean enlazarRla = enlace.LinkedEntityId != rlaId;

			if (clavePorDciId.containsKey(enlace.LinkedEntityId)) {
				clave = clavePorDciId.get(enlace.LinkedEntityId);
				prioridad = 50;
				grupoId = enlace.LinkedEntityId;
			} else if (String.isBlank(clave)) {
				clave = resolveGeneratedKey(enlace.ContentDocument.Title);
				prioridad = enlace.LinkedEntityId == accountId ? 70 : 60;
			}

			// Pagarés y contratos solo se precargan desde archivos firmados del mismo RLA.
			if (esPagareFirmadoRla && clave != PAGARE_COMPLEMENTARIO) {
				clave = PAGARE;
			} else if (esContratoFirmadoRla) {
				clave = CONTRATOS_FIRMADOS;
			}
			if (
				(clave == PAGARE || clave == PAGARE_COMPLEMENTARIO) && !esPagareFirmadoRla ||
				clave == CONTRATOS_FIRMADOS && !esContratoFirmadoRla
			) {
				continue;
			}

			if (String.isBlank(clave)) {
				continue;
			}
			if (titulo.endsWith(' firmado') || titulo.contains(' firmado ')) {
				prioridad += 100;
			}
			agregarCandidato(
				resultado,
				clave,
				new FileCandidate(
					enlace.ContentDocumentId,
					grupoId,
					enlace.ContentDocument.CreatedDate,
					prioridad,
					enlazarRla
				)
			);
		}
		return resultado;
	}

	private static void agregarCandidato(
		Map<String, List<FileCandidate>> candidatosPorClave,
		String clave,
		FileCandidate candidato
	) {
		if (!candidatosPorClave.containsKey(clave)) {
			candidatosPorClave.put(clave, new List<FileCandidate>());
		}
		candidatosPorClave.get(clave).add(candidato);
	}

	private static List<ContentDocumentLink> construirEnlaces(
		Id rlaId,
		Map<String, Set<Id>> filasPorClave,
		Map<String, List<FileCandidate>> candidatosPorClave
	) {
		Set<Id> destinos = new Set<Id>{ rlaId };
		for (Set<Id> filasIds : filasPorClave.values()) {
			destinos.addAll(filasIds);
		}

		Set<String> enlacesExistentes = new Set<String>();
		for (ContentDocumentLink enlace : [
			SELECT LinkedEntityId, ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId IN :destinos
		]) {
			enlacesExistentes.add(claveEnlace(enlace.LinkedEntityId, enlace.ContentDocumentId));
		}

		List<ContentDocumentLink> resultado = new List<ContentDocumentLink>();
		for (String clave : filasPorClave.keySet()) {
			List<FileCandidate> candidatos = candidatosPorClave.get(clave);
			if (candidatos == null || candidatos.isEmpty()) {
				continue;
			}

			FileCandidate mejor = seleccionarMejor(candidatos);
			for (FileCandidate candidato : candidatos) {
				if (candidato.groupId != mejor.groupId) {
					continue;
				}
				for (Id filaId : filasPorClave.get(clave)) {
					agregarEnlace(resultado, enlacesExistentes, filaId, candidato.contentDocumentId);
				}
				if (candidato.linkToRla) {
					agregarEnlace(resultado, enlacesExistentes, rlaId, candidato.contentDocumentId);
				}
			}
		}
		return resultado;
	}

	private static FileCandidate seleccionarMejor(List<FileCandidate> candidatos) {
		FileCandidate mejor;
		for (FileCandidate candidato : candidatos) {
			if (
				mejor == null ||
				candidato.priority > mejor.priority ||
				(candidato.priority == mejor.priority && candidato.createdDate != null &&
					(mejor.createdDate == null || candidato.createdDate > mejor.createdDate))
			) {
				mejor = candidato;
			}
		}
		return mejor;
	}

	private static void agregarEnlace(
		List<ContentDocumentLink> enlaces,
		Set<String> enlacesExistentes,
		Id destinoId,
		Id contentDocumentId
	) {
		String clave = claveEnlace(destinoId, contentDocumentId);
		if (enlacesExistentes.contains(clave)) {
			return;
		}
		enlacesExistentes.add(clave);
		enlaces.add(new ContentDocumentLink(
			LinkedEntityId = destinoId,
			ContentDocumentId = contentDocumentId,
			ShareType = 'V',
			Visibility = 'InternalUsers'
		));
	}

	private static String claveEnlace(Id destinoId, Id contentDocumentId) {
		return String.valueOf(destinoId) + '|' + String.valueOf(contentDocumentId);
	}

	private static String inferirClaveEtiqueta(String label) {
		String value = normalizar(label);
		if (String.isBlank(value)) {
			return null;
		}

		if (value.contains('capacidad de pago')) return CAPACIDAD_PAGO;
		if (value.contains('informe de credito')) return INFORME_CREDITO;
		if (
			value.contains('planilla de solicitud') ||
			value.contains('solicitud digital para la tramitacion') ||
			value.contains('solicitud de la facilidad deseada')
		) return SOLICITUD_CREDITO;
		if (value.contains('conozca su cliente')) return KYC;
		if (value.contains('pagare complementario')) return PAGARE_COMPLEMENTARIO;
		if (value.startsWith('pagare ') || value == 'pagare') return PAGARE;
		if (value.startsWith('contratos firmados') || value.startsWith('contratos debidamente firmados')) return CONTRATOS_FIRMADOS;
		if (value.startsWith('contrato unico')) return CONTRATO_UNICO;
		if (value.contains('registro mercantil')) return REGISTRO_MERCANTIL;
		if (value.contains('estatutos sociales')) return ESTATUTOS_SOCIALES;
		if (value.contains('declaratoria de condominio') || value.contains('constitutiva de condominio')) return ACTA_CONDOMINIO;
		if (value.contains('asamblea general constitutiva')) return ACTA_CONSTITUTIVA;
		if (value.contains('poder de autorizacion') || value.startsWith('poder ')) return PODER_AUTORIZACION;
		if (value.contains('autorizacion') && value.contains('contratacion de prestamos')) return AUTORIZACION_PRESTAMO;
		if (
			(value.contains('designando funcionario') && value.contains('firmas')) ||
			(value.contains('designe las personas autorizadas') && value.contains('firmar'))
		) return ACTA_DESIGNACION_FIRMANTES;
		if (value.contains('tarjeta de firmas')) return TARJETA_FIRMAS;
		if (value.contains('nomina') && value.contains('presencia')) return NOMINA_PRESENCIA;
		if (value.contains('rnc') || value.contains('r n c')) return RNC;
		if (value.contains('certificacion de ingresos') || value.contains('evidencia de otros ingresos')) return SOPORTE_INGRESOS;
		if (value.contains('carta laboral')) return CARTA_LABORAL;
		if (value.contains('comprobante de ingresos')) return COMPROBANTE_INGRESOS;
		if ((value.contains('cedula') || value.contains('documento de identidad')) && value.contains('firmante')) return CEDULA_FIRMANTES;
		if ((value.contains('cedula') || value.contains('documento de identidad')) &&
			(value.contains('accionista') || value.contains('socio'))) return CEDULA_ACCIONISTAS;
		if (
			value == 'copia de cedula' ||
			(value.contains('documento de identidad') && value.contains('solicitante'))
		) return DOCUMENTO_IDENTIDAD;
		return null;
	}

	private static String normalizarClave(String value) {
		if (String.isBlank(value)) {
			return null;
		}
		return value.trim().toUpperCase().replaceAll('[^A-Z0-9]+', '_');
	}

	private static Boolean esPagareFirmado(String titulo) {
		return !String.isBlank(titulo) && titulo.contains('pagare') && titulo.contains('firmado');
	}

	private static Boolean esContratoFirmado(String titulo) {
		return !String.isBlank(titulo) && titulo.contains('contrato') && titulo.contains('firmado') &&
			!titulo.contains('unico');
	}

	private static String normalizar(String value) {
		if (String.isBlank(value)) {
			return null;
		}
		return value.toLowerCase()
			.replace('á', 'a').replace('é', 'e').replace('í', 'i').replace('ó', 'o').replace('ú', 'u')
			.replace('ü', 'u').replace('ñ', 'n')
			.replaceAll('[^a-z0-9]+', ' ')
			.trim();
	}
}