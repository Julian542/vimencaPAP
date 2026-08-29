public with sharing class FSC_ChecklistDocsController {
	private static final Set<String> REVIEWER_PROFILES = new Set<String>{
		'Recepción y control de documentos',
		'Analista de crédito',
		'System Administrator',
		'Administrador del sistema'
	};

	private static final Set<String> OFFICIAL_PROFILES = new Set<String>{ 'Oficial de negocio', 'System Administrator', 'Administrador del sistema' };

	private static final String ESTADO_PENDIENTE = 'Pendiente';
	private static final String ESTADO_APROBADO = 'Aprobado';
	private static final String ESTADO_OBSERVADO = 'Observado';

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

	@AuraEnabled
	public static List<RowDTO> initAndGetRows(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('residentialLoanApplicationId requerido');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, Status, RecordType.DeveloperName
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
			SELECT Id, FSC_TipoDeSolicitudDeCredito__c, FSC_CategoriaDelDocumento__c, FSC_NroDeDocumento__c, FSC_NombreDelDocumento__c
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

		String currentProfileName = getCurrentProfileName();

		Boolean isAdmin = currentProfileName == 'System Administrator' || currentProfileName == 'Administrador del sistema';

		Boolean isReviewerOnly =
			currentProfileName == 'Recepción y control de documentos' ||
			currentProfileName == 'Analista de crédito';
		Boolean isOfficialOnly = currentProfileName == 'Oficial de negocio';

		if (!isAdmin && !isReviewerOnly && !isOfficialOnly) {
			throw new AuraHandledException('No tienes permisos para modificar esta checklist.');
		}

		Map<Id, FSC_SolicitudDeCreditoYChecklistDeDocs__c> actuales = new Map<Id, FSC_SolicitudDeCreditoYChecklistDeDocs__c>(
			[
				SELECT
					Id,
					FSC_SolicitudDeCredito__c,
					FSC_NoAplica__c,
					FSC_Comentario__c,
					FSC_ComentarioOficialNegocio__c,
					FSC_EstadoRevision__c
				FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
				WHERE Id IN :joinIds
			]
		);

		List<FSC_SolicitudDeCreditoYChecklistDeDocs__c> upd = new List<FSC_SolicitudDeCreditoYChecklistDeDocs__c>();
		Set<Id> solicitudesConRevisionModificada = new Set<Id>();

		for (Integer i = 0; i < joinIds.size(); i++) {
			Id joinId = joinIds[i];
			if (joinId == null || !actuales.containsKey(joinId))
				continue;

			FSC_SolicitudDeCreditoYChecklistDeDocs__c actual = actuales.get(joinId);

			Boolean nuevoNoAplica = noAplicaList[i] == null ? actual.FSC_NoAplica__c : noAplicaList[i];

			String nuevoComentario = comentarioList[i] == null ? actual.FSC_Comentario__c : comentarioList[i];

			String nuevoComentarioOficial = comentarioOficialList[i] == null ? actual.FSC_ComentarioOficialNegocio__c : comentarioOficialList[i];

			String nuevoEstado = String.isBlank(estadoRevisionList[i]) ? actual.FSC_EstadoRevision__c : estadoRevisionList[i];

			if (
				(isAdmin || isReviewerOnly) &&
				actual.FSC_SolicitudDeCredito__c != null &&
				(nuevoComentario != actual.FSC_Comentario__c || nuevoEstado != actual.FSC_EstadoRevision__c)
			) {
				solicitudesConRevisionModificada.add(actual.FSC_SolicitudDeCredito__c);
			}

			Boolean changesApprovedOnlyComment =
				isReviewerOnly &&
				actual.FSC_EstadoRevision__c == ESTADO_APROBADO &&
				nuevoNoAplica == actual.FSC_NoAplica__c &&
				nuevoEstado == actual.FSC_EstadoRevision__c;

			if (!isAdmin && actual.FSC_EstadoRevision__c == ESTADO_APROBADO && !changesApprovedOnlyComment) {
				throw new AuraHandledException('No puedes modificar documentos con estado de revisión "Aprobado".');
			}

			if (
				(isAdmin || isOfficialOnly) &&
				actual.FSC_EstadoRevision__c == ESTADO_APROBADO &&
				nuevoComentarioOficial != actual.FSC_ComentarioOficialNegocio__c
			) {
				throw new AuraHandledException('No puedes modificar el comentario oficial de documentos con estado de revision "Aprobado".');
			}

			if ((isAdmin || isReviewerOnly) && nuevoEstado == ESTADO_OBSERVADO && String.isBlank(nuevoComentario)) {
				throw new AuraHandledException('Si el estado de revisión es "Observado", debes ingresar un comentario.');
			}

			FSC_SolicitudDeCreditoYChecklistDeDocs__c rowToUpdate = new FSC_SolicitudDeCreditoYChecklistDeDocs__c(Id = joinId);

			if (isAdmin) {
				rowToUpdate.FSC_NoAplica__c = nuevoNoAplica;
				rowToUpdate.FSC_Comentario__c = nuevoComentario;
				rowToUpdate.FSC_ComentarioOficialNegocio__c = nuevoComentarioOficial;
				rowToUpdate.FSC_EstadoRevision__c = nuevoEstado;
			} else if (isReviewerOnly) {
				rowToUpdate.FSC_Comentario__c = nuevoComentario;
				rowToUpdate.FSC_EstadoRevision__c = nuevoEstado;
			} else if (isOfficialOnly) {
				rowToUpdate.FSC_NoAplica__c = nuevoNoAplica;
				rowToUpdate.FSC_Comentario__c = actual.FSC_Comentario__c;
				rowToUpdate.FSC_ComentarioOficialNegocio__c = nuevoComentarioOficial;
				rowToUpdate.FSC_EstadoRevision__c = ESTADO_PENDIENTE;
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

		String currentProfileName = getCurrentProfileName();
		if (!isOfficialProfile(currentProfileName)) {
			throw new AuraHandledException('No tienes permisos para modificar esta checklist.');
		}

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
			WHERE
				Id IN :residentialLoanApplicationIds
				AND FSC_DocumentacionValidadaAnalista__c = TRUE
				AND FSC_Subestado__c = 'Análisis de crédito'
		];

		for (ResidentialLoanApplication solicitud : solicitudes) {
			solicitud.FSC_DocumentacionValidadaAnalista__c = false;
		}

		if (!solicitudes.isEmpty()) {
			update solicitudes;
		}
	}

	@AuraEnabled
	public static void enforceSingleFileOnJoin(Id joinId, Id keepContentDocumentId) {
		if (joinId == null || keepContentDocumentId == null)
			return;

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

	private static String getCurrentProfileName() {
		User u = [
			SELECT Profile.Name
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];
		return u.Profile != null ? u.Profile.Name : null;
	}

	private static Boolean isReviewerProfile(String profileName) {
		return REVIEWER_PROFILES.contains(profileName);
	}

	private static Boolean isOfficialProfile(String profileName) {
		return OFFICIAL_PROFILES.contains(profileName);
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

	private static String resolveTipoSolicitudByClaseGarantia(String claseGarantia) {
		if (String.isBlank(claseGarantia)) {
			return null;
		}

		if (claseGarantia.contains(CLASE_GARANTIA_FIRMA_SOLIDARIA)) {
			return TIPO_CONSUMO_GARANTIA_SOLIDARIA;
		}

		if (
			claseGarantia == CLASE_GARANTIA_VEHICULOS_MAQUINARIAS ||
			claseGarantia == CLASE_GARANTIA_VEHICULOS_USADOS ||
			claseGarantia == CLASE_GARANTIA_VEHICULOS_NUEVOS
		) {
			return TIPO_CONSUMO_GARANTIA_VEHICULO;
		}

		if (
			claseGarantia == CLASE_GARANTIA_BIENES_INMUEBLES ||
			claseGarantia == CLASE_GARANTIA_SOLARES_TERRENOS ||
			claseGarantia == CLASE_GARANTIA_SOLARES_AGRO
		) {
			return TIPO_CONSUMO_GARANTIA_HIPOTECARIA;
		}

		if (claseGarantia.contains(CLASE_GARANTIA_CERTIFICADOS_DEPOSITOS)) {
			return TIPO_CONSUMO_GARANTIA_CD;
		}

		return null;
	}
}