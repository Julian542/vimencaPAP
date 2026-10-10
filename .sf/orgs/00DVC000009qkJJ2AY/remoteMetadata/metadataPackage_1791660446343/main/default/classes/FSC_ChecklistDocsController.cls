public with sharing class FSC_ChecklistDocsController {
	@TestVisible private static Boolean testBypassPermissions = false;
	private static final String PERMISO_ANALISTA_CREDITO = 'FSC_CP_Analista_Credito';
	private static final String PERMISO_ADMINISTRADOR = 'FSC_CP_Administrador';
	private static final String PERMISO_CONTROL_DOCUMENTOS = 'FSC_CP_Recepcion_Control_Documentos';
	private static final String PERMISO_OFICIAL_NEGOCIO = 'FSC_CP_Oficial_Negocio';

	private static final String ESTADO_PENDIENTE = 'Pendiente';
	private static final String ESTADO_APROBADO = 'Aprobado';
	private static final String ESTADO_OBSERVADO = 'Observado';
	private static final Set<String> EXTENSIONES_ARCHIVO_PERMITIDAS = new Set<String>{
		'pdf',
		'jpg',
		'jpeg',
		'png',
		'gif',
		'bmp',
		'tif',
		'tiff',
		'webp',
		'heic',
		'doc',
		'docx'
	};

	private static final String RT_PYME = 'FSC_Solicitud_Credito_PYME';
	private static final String RT_CONSUMO = 'FSC_Solicitud_Credito_Consumo';
	private static final String RT_HIPOTECARIO = 'FSC_Solicitud_Credito_Hipotecario';
	private static final String RT_VEHICULO = 'FSC_Solicitud_Credito_Vehiculo';

	private static final String TIPO_PYME = 'Solicitud de crédito pyme';
	private static final String TIPO_VEHICULAR = 'Solicitud de crédito vehicular';
	private static final String TIPO_HIPOTECARIO = 'Solicitud de crédito hipotecario';
	private static final String TIPO_CONSUMO_SOLA_FIRMA = 'Solicitud de crédito consumo a sola firma';
	private static final String TIPO_CONSUMO_GARANTIA_HIPOTECARIA = 'Solicitud de crédito consumo con garantía hipotecaria';
	private static final String TIPO_CONSUMO_GARANTIA_CD = 'Solicitud de crédito consumo con garantía de CD';
	private static final String TIPO_CONSUMO_GARANTIA_SOLIDARIA = 'Solicitud de crédito consumo con garantía solidaria';
	private static final String TIPO_CONSUMO_GARANTIA_VEHICULO = 'Solicitud de crédito consumo con garantía de vehículo';

	private static final String CLASE_GARANTIA_FIRMA_SOLIDARIA = 'FIRMA SOLIDARIA';
	private static final String CLASE_GARANTIA_VEHICULOS_MAQUINARIAS = 'VEHICULOS, MAQUINARIAS';
	private static final String CLASE_GARANTIA_VEHICULOS_USADOS = 'VEHICULOS USADOS-P2';
	private static final String CLASE_GARANTIA_VEHICULOS_NUEVOS = 'VEHICULOS NUEVOS -P2';
	private static final String CLASE_GARANTIA_BIENES_INMUEBLES = 'BIENES INMUEBLES';
	private static final String CLASE_GARANTIA_SOLARES_TERRENOS = 'SOLARES O TERRENOS I1';
	private static final String CLASE_GARANTIA_SOLARES_AGRO = 'SOLARES O TERRENOS PARA FINES AGROPECUARIOS I2';
	private static final String CLASE_GARANTIA_CERTIFICADOS_DEPOSITOS = 'CERTIFICADOS DEPOSITOS';

	public class RowDTO {
		@AuraEnabled
		public Id checklistId;
		@AuraEnabled
		public String nombreDocumento;
		@AuraEnabled
		public Integer nroDocumento;
		@AuraEnabled
		public String categoria;

		@AuraEnabled
		public Id joinId;
		@AuraEnabled
		public Boolean noAplica;
		@AuraEnabled
		public String comentario;
		@AuraEnabled
		public String comentarioOficial;
		@AuraEnabled
		public String estadoRevision;

		@AuraEnabled
		public String ultimaModificacionPor;
		@AuraEnabled
		public Datetime fechaUltimaModificacion;

		@AuraEnabled
		public List<FileDTO> files;
	}

	public class FileDTO {
		@AuraEnabled
		public Id contentDocumentId;
		@AuraEnabled
		public String title;
		@AuraEnabled
		public String fileType;
		@AuraEnabled
		public Datetime createdDate;
		@AuraEnabled
		public String createdByName;
	}

	public class UploadResultDTO {
		@AuraEnabled
		public List<Id> acceptedContentDocumentIds = new List<Id>();
		@AuraEnabled
		public List<String> rejectedFileNames = new List<String>();
	}

	@AuraEnabled
	public static List<RowDTO> initAndGetRows(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('residentialLoanApplicationId requerido');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, AccountId, Status, RecordType.DeveloperName
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		String rtDev = rla.RecordType != null ? rla.RecordType.DeveloperName : null;
		if (String.isBlank(rtDev))
			return new List<RowDTO>();

		String tipoSolicitud = resolveTipoSolicitud(rla.Id, rtDev);

		if (String.isBlank(tipoSolicitud)) {
			return new List<RowDTO>();
		}

		List<FSC_ChecklistDocumentos__c> docs = [
			SELECT Id, FSC_TipoDeSolicitudDeCredito__c, FSC_CategoriaDelDocumento__c, FSC_NroDeDocumento__c,
				FSC_NombreDelDocumento__c, FSC_ClaveTecnicaPrecarga__c
			FROM FSC_ChecklistDocumentos__c
			WHERE FSC_TipoDeSolicitudDeCredito__c = :tipoSolicitud
			ORDER BY FSC_NroDeDocumento__c ASC
		];
		if (docs.isEmpty())
			return new List<RowDTO>();

		Set<Id> docIds = new Set<Id>();
		for (FSC_ChecklistDocumentos__c d : docs) {
			docIds.add(d.Id);
		}

		Map<Id, FSC_SolicitudDeCreditoYChecklistDeDocs__c> joinByDocId = new Map<Id, FSC_SolicitudDeCreditoYChecklistDeDocs__c>();
		for (FSC_SolicitudDeCreditoYChecklistDeDocs__c j : [
			SELECT
				Id,
				FSC_Documento__c,
				FSC_NoAplica__c,
				FSC_Comentario__c,
				FSC_ComentarioOficialNegocio__c,
				FSC_EstadoRevision__c,
				LastModifiedDate,
				LastModifiedBy.Name
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE FSC_SolicitudDeCredito__c = :rla.Id AND FSC_Documento__c IN :docIds
		]) {
			joinByDocId.put(j.FSC_Documento__c, j);
		}

		List<FSC_SolicitudDeCreditoYChecklistDeDocs__c> toInsert = new List<FSC_SolicitudDeCreditoYChecklistDeDocs__c>();
		for (FSC_ChecklistDocumentos__c d : docs) {
			if (!joinByDocId.containsKey(d.Id)) {
				toInsert.add(
					new FSC_SolicitudDeCreditoYChecklistDeDocs__c(
						FSC_SolicitudDeCredito__c = residentialLoanApplicationId,
						FSC_Documento__c = d.Id,
						FSC_NoAplica__c = false,
						FSC_Comentario__c = null,
						FSC_ComentarioOficialNegocio__c = null,
						FSC_EstadoRevision__c = ESTADO_PENDIENTE
					)
				);
			}
		}

		if (!toInsert.isEmpty()) {
			insert toInsert;

			Set<Id> insertedIds = new Set<Id>();
			for (FSC_SolicitudDeCreditoYChecklistDeDocs__c rec : toInsert) {
				insertedIds.add(rec.Id);
			}

			for (FSC_SolicitudDeCreditoYChecklistDeDocs__c j : [
				SELECT
					Id,
					FSC_Documento__c,
					FSC_NoAplica__c,
					FSC_Comentario__c,
					FSC_ComentarioOficialNegocio__c,
					FSC_EstadoRevision__c,
					LastModifiedDate,
					LastModifiedBy.Name
				FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
				WHERE Id IN :insertedIds
			]) {
				joinByDocId.put(j.FSC_Documento__c, j);
			}
		}

		Set<Id> joinIds = new Set<Id>();
		for (FSC_SolicitudDeCreditoYChecklistDeDocs__c j : joinByDocId.values()) {
			joinIds.add(j.Id);
		}

		FSC_ChecklistDocsPrecargaService.sincronizar(rla.Id, rla.AccountId, docs, joinByDocId);

		Map<Id, List<FileDTO>> filesByJoinId = new Map<Id, List<FileDTO>>();
		if (!joinIds.isEmpty()) {
			for (ContentDocumentLink cdl : [
				SELECT
					LinkedEntityId,
					ContentDocumentId,
					ContentDocument.Title,
					ContentDocument.FileType,
					ContentDocument.CreatedDate,
					ContentDocument.CreatedBy.Name
				FROM ContentDocumentLink
				WHERE LinkedEntityId IN :joinIds
				ORDER BY ContentDocument.CreatedDate DESC
			]) {
				FileDTO f = new FileDTO();
				f.contentDocumentId = cdl.ContentDocumentId;
				f.title = cdl.ContentDocument.Title;
				f.fileType = cdl.ContentDocument.FileType;
				f.createdDate = cdl.ContentDocument.CreatedDate;
				f.createdByName = cdl.ContentDocument.CreatedBy != null ? cdl.ContentDocument.CreatedBy.Name : null;

				if (!filesByJoinId.containsKey(cdl.LinkedEntityId)) {
					filesByJoinId.put(cdl.LinkedEntityId, new List<FileDTO>());
				}
				filesByJoinId.get(cdl.LinkedEntityId).add(f);
			}
		}

		List<RowDTO> out = new List<RowDTO>();
		for (FSC_ChecklistDocumentos__c d : docs) {
			FSC_SolicitudDeCreditoYChecklistDeDocs__c j = joinByDocId.get(d.Id);
			List<FileDTO> rowFiles = (j != null && filesByJoinId.containsKey(j.Id)) ? filesByJoinId.get(j.Id) : new List<FileDTO>();

			Datetime ultimaFecha = j != null ? j.LastModifiedDate : null;
			String ultimoUsuario = (j != null && j.LastModifiedBy != null) ? j.LastModifiedBy.Name : null;

			for (FileDTO fileDto : rowFiles) {
				if (fileDto.createdDate != null && (ultimaFecha == null || fileDto.createdDate.getTime() > ultimaFecha.getTime())) {
					ultimaFecha = fileDto.createdDate;
					ultimoUsuario = fileDto.createdByName;
				}
			}

			RowDTO row = new RowDTO();
			row.checklistId = d.Id;
			row.nombreDocumento = d.FSC_NombreDelDocumento__c;
			row.nroDocumento = (Integer) d.FSC_NroDeDocumento__c;
			row.categoria = d.FSC_CategoriaDelDocumento__c;

			row.joinId = j != null ? j.Id : null;
			row.noAplica = j != null ? j.FSC_NoAplica__c : false;
			row.comentario = j != null ? j.FSC_Comentario__c : null;
			row.comentarioOficial = j != null ? j.FSC_ComentarioOficialNegocio__c : null;
			row.estadoRevision = j != null ? j.FSC_EstadoRevision__c : ESTADO_PENDIENTE;

			row.ultimaModificacionPor = ultimoUsuario;
			row.fechaUltimaModificacion = ultimaFecha;
			row.files = rowFiles;

			out.add(row);
		}

		return out;
	}

	@AuraEnabled
	public static void saveRows(
		List<Id> joinIds,
		List<Boolean> noAplicaList,
		List<String> comentarioList,
		List<String> comentarioOficialList,
		List<String> estadoRevisionList
	) {
		if (joinIds == null || joinIds.isEmpty())
			return;

		if (
			noAplicaList == null ||
			comentarioList == null ||
			comentarioOficialList == null ||
			estadoRevisionList == null ||
			joinIds.size() != noAplicaList.size() ||
			joinIds.size() != comentarioList.size() ||
			joinIds.size() != comentarioOficialList.size() ||
			joinIds.size() != estadoRevisionList.size()
		) {
			throw new AuraHandledException('Parámetros inconsistentes.');
		}

		Boolean esAdministrador = testBypassPermissions || FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR);
		Map<Id, FSC_SolicitudDeCreditoYChecklistDeDocs__c> actuales = new Map<Id, FSC_SolicitudDeCreditoYChecklistDeDocs__c>(
			[
				SELECT Id, FSC_SolicitudDeCredito__c, FSC_NoAplica__c, FSC_Comentario__c, FSC_ComentarioOficialNegocio__c, FSC_EstadoRevision__c,
					FSC_Documento__r.FSC_CategoriaDelDocumento__c, FSC_SolicitudDeCredito__r.FSC_Subestado__c,
					FSC_SolicitudDeCredito__r.CreatedById, FSC_SolicitudDeCredito__r.FSC_UsuarioPagaresYContratos__c
				FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
				WHERE Id IN :joinIds
			]
		);

		List<FSC_SolicitudDeCreditoYChecklistDeDocs__c> upd = new List<FSC_SolicitudDeCreditoYChecklistDeDocs__c>();
		Set<Id> solicitudesConRevisionModificada = new Set<Id>();
		Set<Id> conArchivo = new Set<Id>();
		for (ContentDocumentLink enlace : [SELECT LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :joinIds]) conArchivo.add(enlace.LinkedEntityId);

		for (Integer i = 0; i < joinIds.size(); i++) {
			Id joinId = joinIds[i];
			if (joinId == null || !actuales.containsKey(joinId))
				continue;

			FSC_SolicitudDeCreditoYChecklistDeDocs__c actual = actuales.get(joinId);
			String categoria = actual.FSC_Documento__r.FSC_CategoriaDelDocumento__c;
			String subestado = actual.FSC_SolicitudDeCredito__r.FSC_Subestado__c;
			Boolean esContrato = categoria == FSC_DocumentacionContratosService.CATEGORIA;
			Boolean etapaContratos = subestado == FSC_DocumentacionContratosService.SUBESTADO_CARGA || subestado == FSC_DocumentacionContratosService.SUBESTADO_GENERACION;
			Boolean puedeRevisar = esAdministrador || tienePermisoRevisor();
			Boolean puedeEditarComoOficial = esAdministrador || FeatureManagement.checkPermission(PERMISO_OFICIAL_NEGOCIO);
			if (esContrato || etapaContratos) {
				puedeRevisar = esContrato && subestado == FSC_DocumentacionContratosService.SUBESTADO_GENERACION &&
					(esAdministrador || actual.FSC_SolicitudDeCredito__r.FSC_UsuarioPagaresYContratos__c == UserInfo.getUserId());
				puedeEditarComoOficial = esContrato && subestado == FSC_DocumentacionContratosService.SUBESTADO_CARGA &&
					(esAdministrador || actual.FSC_SolicitudDeCredito__r.CreatedById == UserInfo.getUserId());
			}
			if (!puedeRevisar && !puedeEditarComoOficial) throw new AuraHandledException('No tienes permisos para modificar esta categoría en el subestado actual.');

			Boolean nuevoNoAplica = noAplicaList[i] == null ? actual.FSC_NoAplica__c : noAplicaList[i];

			String nuevoComentario = comentarioList[i] == null ? actual.FSC_Comentario__c : comentarioList[i];

			String nuevoComentarioOficial = comentarioOficialList[i] == null ? actual.FSC_ComentarioOficialNegocio__c : comentarioOficialList[i];

			String nuevoEstado = String.isBlank(estadoRevisionList[i]) ? actual.FSC_EstadoRevision__c : estadoRevisionList[i];
			if (esContrato) {
				if (!puedeRevisar && (nuevoComentario != actual.FSC_Comentario__c || (nuevoEstado != actual.FSC_EstadoRevision__c && nuevoEstado != ESTADO_PENDIENTE))) {
					throw new AuraHandledException('Solo el responsable de pagarés y contratos puede revisar esta documentación.');
				}
				if (!puedeEditarComoOficial && (nuevoNoAplica != actual.FSC_NoAplica__c || nuevoComentarioOficial != actual.FSC_ComentarioOficialNegocio__c)) {
					throw new AuraHandledException('Solo el creador o un administrador puede completar la documentación en Documentación para contratos.');
				}
				if (puedeRevisar && nuevoEstado == ESTADO_APROBADO && nuevoNoAplica != true && !conArchivo.contains(joinId)) {
					throw new AuraHandledException('No se puede aprobar un documento sin archivo, salvo que esté marcado No aplica.');
				}
			}

			if (
				puedeRevisar &&
				actual.FSC_SolicitudDeCredito__c != null &&
				(nuevoComentario != actual.FSC_Comentario__c ||
				nuevoEstado != actual.FSC_EstadoRevision__c)
			) {
				solicitudesConRevisionModificada.add(actual.FSC_SolicitudDeCredito__c);
			}

			Boolean changesApprovedOnlyComment =
				puedeRevisar &&
				actual.FSC_EstadoRevision__c == ESTADO_APROBADO &&
				nuevoNoAplica == actual.FSC_NoAplica__c &&
				nuevoEstado == actual.FSC_EstadoRevision__c &&
				nuevoComentarioOficial == actual.FSC_ComentarioOficialNegocio__c;

			if (!esAdministrador && actual.FSC_EstadoRevision__c == ESTADO_APROBADO && !changesApprovedOnlyComment) {
				throw new AuraHandledException('No puedes modificar documentos con estado de revisión "Aprobado".');
			}

			if (puedeRevisar && nuevoEstado == ESTADO_OBSERVADO && String.isBlank(nuevoComentario)) {
				throw new AuraHandledException('Si el estado de revisión es "Observado", debes ingresar un comentario.');
			}

			FSC_SolicitudDeCreditoYChecklistDeDocs__c rowToUpdate = new FSC_SolicitudDeCreditoYChecklistDeDocs__c(Id = joinId);

			if (puedeRevisar) {
				rowToUpdate.FSC_Comentario__c = nuevoComentario;
				rowToUpdate.FSC_EstadoRevision__c = nuevoEstado;
			}
			if (puedeEditarComoOficial) {
				rowToUpdate.FSC_NoAplica__c = nuevoNoAplica;
				rowToUpdate.FSC_ComentarioOficialNegocio__c = nuevoComentarioOficial;
				if (!puedeRevisar) {
					rowToUpdate.FSC_EstadoRevision__c = ESTADO_PENDIENTE;
				}
			}

			upd.add(rowToUpdate);
		}

		if (!upd.isEmpty()) {
			update upd;
		}

		resetAnalystValidation(solicitudesConRevisionModificada);
	}

	@AuraEnabled
	public static void markDocumentAsPending(Id joinId) {
		if (joinId == null)
			return;
		validarCargaDocumento(joinId);

		FSC_SolicitudDeCreditoYChecklistDeDocs__c row = [
			SELECT Id, FSC_SolicitudDeCredito__c, FSC_EstadoRevision__c
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE Id = :joinId
			LIMIT 1
		];

		if (row.FSC_EstadoRevision__c == ESTADO_APROBADO) {
			throw new AuraHandledException('No puedes modificar documentos con estado de revisión "Aprobado".');
		}

		update new FSC_SolicitudDeCreditoYChecklistDeDocs__c(Id = joinId, FSC_EstadoRevision__c = ESTADO_PENDIENTE);
		resetAnalystValidation(new Set<Id>{ row.FSC_SolicitudDeCredito__c });
	}

	private static void resetAnalystValidation(Set<Id> residentialLoanApplicationIds) {
		residentialLoanApplicationIds.remove(null);
		if (residentialLoanApplicationIds.isEmpty()) {
			return;
		}

		List<ResidentialLoanApplication> solicitudes = [
			SELECT Id, FSC_DocumentacionValidadaAnalista__c
			FROM ResidentialLoanApplication
			WHERE Id IN :residentialLoanApplicationIds AND FSC_DocumentacionValidadaAnalista__c = TRUE AND FSC_Subestado__c = 'Análisis de crédito'
		];

		for (ResidentialLoanApplication solicitud : solicitudes) {
			solicitud.FSC_DocumentacionValidadaAnalista__c = false;
		}

		if (!solicitudes.isEmpty()) {
			update solicitudes;
		}
	}

	@AuraEnabled
	public static UploadResultDTO processUploadedFiles(
		Id residentialLoanApplicationId,
		Id joinId,
		List<Id> contentDocumentIds
	) {
		if (residentialLoanApplicationId == null || joinId == null) {
			throw new AuraHandledException('No se pudo identificar la solicitud o el ítem de la checklist.');
		}
		validarCargaDocumento(joinId);

		UploadResultDTO result = new UploadResultDTO();
		if (contentDocumentIds == null || contentDocumentIds.isEmpty()) {
			return result;
		}

		List<FSC_SolicitudDeCreditoYChecklistDeDocs__c> checklistRows = [
			SELECT Id, FSC_SolicitudDeCredito__c
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE Id = :joinId
			LIMIT 1
		];
		if (checklistRows.isEmpty() || checklistRows[0].FSC_SolicitudDeCredito__c != residentialLoanApplicationId) {
			throw new AuraHandledException('El ítem de la checklist no corresponde a la solicitud indicada.');
		}

		Set<Id> requestedDocumentIds = new Set<Id>();
		for (Id contentDocumentId : contentDocumentIds) {
			if (contentDocumentId != null) {
				requestedDocumentIds.add(contentDocumentId);
			}
		}
		if (requestedDocumentIds.isEmpty()) {
			return result;
		}

		Set<Id> linkedDocumentIds = new Set<Id>();
		for (ContentDocumentLink link : [
			SELECT ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :joinId AND ContentDocumentId IN :requestedDocumentIds
		]) {
			linkedDocumentIds.add(link.ContentDocumentId);
		}

		Map<Id, ContentVersion> latestVersionByDocumentId = new Map<Id, ContentVersion>();
		for (ContentVersion version : [
			SELECT ContentDocumentId, Title, FileExtension
			FROM ContentVersion
			WHERE ContentDocumentId IN :linkedDocumentIds AND IsLatest = TRUE
		]) {
			latestVersionByDocumentId.put(version.ContentDocumentId, version);
		}

		Set<Id> rejectedDocumentIds = new Set<Id>();
		for (Id contentDocumentId : requestedDocumentIds) {
			ContentVersion version = latestVersionByDocumentId.get(contentDocumentId);
			String extension = version == null ? null : version.FileExtension;
			if (
				!linkedDocumentIds.contains(contentDocumentId) ||
				String.isBlank(extension) ||
				!EXTENSIONES_ARCHIVO_PERMITIDAS.contains(extension.toLowerCase())
			) {
				rejectedDocumentIds.add(contentDocumentId);
				String fileName = version == null ? String.valueOf(contentDocumentId) : version.Title;
				if (version != null && !String.isBlank(extension)) {
					fileName += '.' + extension;
				}
				result.rejectedFileNames.add(fileName);
			} else {
				result.acceptedContentDocumentIds.add(contentDocumentId);
			}
		}

		if (!rejectedDocumentIds.isEmpty()) {
			List<ContentDocumentLink> rejectedLinks = [
				SELECT Id
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :joinId AND ContentDocumentId IN :rejectedDocumentIds
			];
			if (!rejectedLinks.isEmpty()) {
				delete rejectedLinks;
			}
		}

		linkUploadedFilesToRla(residentialLoanApplicationId, result.acceptedContentDocumentIds);
		return result;
	}

	@AuraEnabled
	public static void enforceSingleFileOnJoin(Id joinId, Id keepContentDocumentId) {
		if (joinId == null || keepContentDocumentId == null)
			return;
		validarCargaDocumento(joinId);

		List<ContentDocumentLink> toDelete = [
			SELECT Id, ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :joinId AND ContentDocumentId != :keepContentDocumentId
		];

		if (!toDelete.isEmpty()) {
			delete toDelete;
		}
	}

	@AuraEnabled
	public static void linkUploadedFilesToRla(Id residentialLoanApplicationId, List<Id> contentDocumentIds) {
		if (residentialLoanApplicationId == null)
			return;
		if (contentDocumentIds == null || contentDocumentIds.isEmpty())
			return;

		List<ContentDocumentLink> existingLinks = [
			SELECT Id, ContentDocumentId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :residentialLoanApplicationId AND ContentDocumentId IN :contentDocumentIds
		];

		Set<Id> alreadyLinked = new Set<Id>();
		for (ContentDocumentLink link : existingLinks) {
			alreadyLinked.add(link.ContentDocumentId);
		}

		List<ContentDocumentLink> links = new List<ContentDocumentLink>();
		for (Id cdId : contentDocumentIds) {
			if (!alreadyLinked.contains(cdId)) {
				links.add(
					new ContentDocumentLink(
						LinkedEntityId = residentialLoanApplicationId,
						ContentDocumentId = cdId,
						ShareType = 'V',
						Visibility = 'AllUsers'
					)
				);
			}
		}

		if (!links.isEmpty()) {
			insert links;
		}
	}

	private static void validarCargaDocumento(Id joinId) {
		FSC_SolicitudDeCreditoYChecklistDeDocs__c fila = [
			SELECT FSC_EstadoRevision__c, FSC_Documento__r.FSC_CategoriaDelDocumento__c,
				FSC_SolicitudDeCredito__r.CreatedById, FSC_SolicitudDeCredito__r.FSC_Subestado__c
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c WHERE Id = :joinId
		];
		String categoria = fila.FSC_Documento__r.FSC_CategoriaDelDocumento__c;
		String subestado = fila.FSC_SolicitudDeCredito__r.FSC_Subestado__c;
		Boolean permitido = false;
		Boolean esAdmin = testBypassPermissions || FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR);
		if (categoria == FSC_DocumentacionContratosService.CATEGORIA) {
			permitido = subestado == FSC_DocumentacionContratosService.SUBESTADO_CARGA &&
				(esAdmin || fila.FSC_SolicitudDeCredito__r.CreatedById == UserInfo.getUserId());
		} else if (esAdmin || FeatureManagement.checkPermission(PERMISO_OFICIAL_NEGOCIO)) {
			permitido = (subestado == 'Recepción de documentos – Análisis' && categoria == 'Documentos para análisis') ||
				(subestado == 'Documentación para desembolso y firmas' && categoria == 'Documentos para desembolso');
		}
		if (!permitido || fila.FSC_EstadoRevision__c == ESTADO_APROBADO) {
			throw new AuraHandledException('No puede cargar archivos en este documento. Revise el subestado, el responsable y el estado de revisión.');
		}
	}

	private static Boolean tienePermisoRevisor() {
		return FeatureManagement.checkPermission(PERMISO_ANALISTA_CREDITO) || FeatureManagement.checkPermission(PERMISO_CONTROL_DOCUMENTOS);
	}

	public static Map<Id, String> resolveTiposSolicitud(List<ResidentialLoanApplication> solicitudes) {
		Map<Id, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosById();
		Set<Id> consumoIds = new Set<Id>();
		Map<Id, String> resultado = new Map<Id, String>();
		for (ResidentialLoanApplication solicitud : solicitudes) {
			Schema.RecordTypeInfo tipo = recordTypes.get(solicitud.RecordTypeId);
			if (tipo == null) continue;
			String nombre = tipo.getDeveloperName();
			if (nombre == RT_CONSUMO) {
				consumoIds.add(solicitud.Id);
				resultado.put(solicitud.Id, TIPO_CONSUMO_SOLA_FIRMA);
			} else {
				resultado.put(solicitud.Id, resolveTipoSolicitud(solicitud.Id, nombre));
			}
		}
		Set<Id> resueltas = new Set<Id>();
		if (!consumoIds.isEmpty()) {
			for (FSC_Garantia__c garantia : [
				SELECT FSC_Residential_Loan_Application__c, FSC_Clase_de_Garantia__c FROM FSC_Garantia__c
				WHERE FSC_Residential_Loan_Application__c IN :consumoIds ORDER BY CreatedDate ASC
			]) {
				Id solicitudId = garantia.FSC_Residential_Loan_Application__c;
				String tipo = resolveTipoSolicitudByClaseGarantia(garantia.FSC_Clase_de_Garantia__c);
				if (tipo != null && !resueltas.contains(solicitudId)) {
					resultado.put(solicitudId, tipo);
					resueltas.add(solicitudId);
				}
			}
		}
		return resultado;
	}

	private static String resolveTipoSolicitud(Id residentialLoanApplicationId, String recordTypeDeveloperName) {
		if (recordTypeDeveloperName == RT_PYME) {
			return TIPO_PYME;
		}

		if (recordTypeDeveloperName == RT_VEHICULO) {
			return TIPO_VEHICULAR;
		}

		if (recordTypeDeveloperName == RT_HIPOTECARIO) {
			return TIPO_HIPOTECARIO;
		}

		if (recordTypeDeveloperName == RT_CONSUMO) {
			return resolveTipoSolicitudConsumo(residentialLoanApplicationId);
		}

		return null;
	}

	private static String resolveTipoSolicitudConsumo(Id residentialLoanApplicationId) {
		List<FSC_Garantia__c> garantias = [
			SELECT FSC_Clase_de_Garantia__c
			FROM FSC_Garantia__c
			WHERE FSC_Residential_Loan_Application__c = :residentialLoanApplicationId
			ORDER BY CreatedDate ASC
		];

		if (garantias.isEmpty()) {
			return TIPO_CONSUMO_SOLA_FIRMA;
		}

		for (FSC_Garantia__c garantia : garantias) {
			String tipoSolicitud = resolveTipoSolicitudByClaseGarantia(garantia.FSC_Clase_de_Garantia__c);
			if (!String.isBlank(tipoSolicitud)) {
				return tipoSolicitud;
			}
		}

		return TIPO_CONSUMO_SOLA_FIRMA;
	}

	@TestVisible
	private static String resolveTipoSolicitudByClaseGarantia(String claseGarantia) {
		if (String.isBlank(claseGarantia)) {
			return null;
		}

		if (claseGarantia.contains(CLASE_GARANTIA_FIRMA_SOLIDARIA)) {
			return TIPO_CONSUMO_GARANTIA_SOLIDARIA;
		}

		// El API puede variar espacios o guiones respecto del texto historico (ej. "I2" y "-I2").
		String claveClase = FSC_CatalogoGarantiaService.normalizarClave(claseGarantia);
		if (
			esMismaClase(claveClase, CLASE_GARANTIA_VEHICULOS_MAQUINARIAS) ||
			esMismaClase(claveClase, CLASE_GARANTIA_VEHICULOS_USADOS) ||
			esMismaClase(claveClase, CLASE_GARANTIA_VEHICULOS_NUEVOS)
		) {
			return TIPO_CONSUMO_GARANTIA_VEHICULO;
		}

		if (
			esMismaClase(claveClase, CLASE_GARANTIA_BIENES_INMUEBLES) ||
			esMismaClase(claveClase, CLASE_GARANTIA_SOLARES_TERRENOS) ||
			esMismaClase(claveClase, CLASE_GARANTIA_SOLARES_AGRO)
		) {
			return TIPO_CONSUMO_GARANTIA_HIPOTECARIA;
		}

		if (claseGarantia.contains(CLASE_GARANTIA_CERTIFICADOS_DEPOSITOS)) {
			return TIPO_CONSUMO_GARANTIA_CD;
		}

		return null;
	}

	private static Boolean esMismaClase(String claveClase, String claseEsperada) {
		return claveClase == FSC_CatalogoGarantiaService.normalizarClave(claseEsperada);
	}
}