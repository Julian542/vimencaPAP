public inherited sharing class FSC_DocumentacionContratosService {
	public static final String SUBESTADO_CARGA = 'Documentación para contratos';
	public static final String SUBESTADO_GENERACION = 'Generación de pagarés y plantillas';
	public static final String SUBESTADO_BANCA_SEGURO = 'Banca Seguro';
	public static final String CATEGORIA = 'Documentos para confección de contrato';
	private static final String PERMISO_ADMIN = 'FSC_CP_Administrador';
	private static final Set<String> TIPOS_CON_BANCA_SEGURO = new Set<String>{
		'FSC_Solicitud_Credito_Vehiculo',
		'FSC_Solicitud_Credito_Hipotecario'
	};

	private class DocumentoContrato {
		Boolean noAplica;
		Boolean tieneArchivo;
		String estadoRevision;
	}

	// Todas las entradas a pagarés pasan por la misma regla, incluida la aprobación del motor.
	public static void encaminarEntradas(List<ResidentialLoanApplication> solicitudes, Map<Id, ResidentialLoanApplication> anteriores) {
		List<ResidentialLoanApplication> candidatas = new List<ResidentialLoanApplication>();
		for (ResidentialLoanApplication solicitud : solicitudes) {
			ResidentialLoanApplication anterior = anteriores == null ? null : anteriores.get(solicitud.Id);
			if (
				solicitud.Status == 'En proceso' &&
				solicitud.FSC_Subestado__c == SUBESTADO_GENERACION &&
				(anterior == null || (anterior.FSC_Subestado__c != SUBESTADO_GENERACION && anterior.FSC_Subestado__c != SUBESTADO_CARGA))
			) {
				Boolean vieneDeBancaSeguro = anterior != null && anterior.FSC_Subestado__c == SUBESTADO_BANCA_SEGURO;
				if (requiereRevisionBancaSeguro(solicitud) && solicitud.FSC_BancaSeguroAprobada__c != true && !vieneDeBancaSeguro) {
					solicitud.FSC_Subestado__c = SUBESTADO_BANCA_SEGURO;
					continue;
				}
				candidatas.add(solicitud);
			}
		}
		if (candidatas.isEmpty())
			return;
		Map<Id, String> tipos = FSC_ChecklistDocsController.resolveTiposSolicitud(candidatas);
		Set<String> tiposConContrato = new Set<String>();
		Set<String> tiposSolicitud = new Set<String>(tipos.values());
		for (FSC_ChecklistDocumentos__c documento : [
			SELECT FSC_TipoDeSolicitudDeCredito__c
			FROM FSC_ChecklistDocumentos__c
			WHERE FSC_TipoDeSolicitudDeCredito__c IN :tiposSolicitud AND FSC_CategoriaDelDocumento__c = :CATEGORIA
		]) {
			tiposConContrato.add(documento.FSC_TipoDeSolicitudDeCredito__c);
		}
		for (ResidentialLoanApplication solicitud : candidatas) {
			if (tiposConContrato.contains(tipos.get(solicitud.Id)))
				solicitud.FSC_Subestado__c = SUBESTADO_CARGA;
		}
	}

	@TestVisible
	private static Boolean requiereRevisionBancaSeguro(ResidentialLoanApplication solicitud) {
		if (solicitud == null || solicitud.RecordTypeId == null) {
			return false;
		}
		Schema.RecordTypeInfo recordTypeInfo = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosById().get(solicitud.RecordTypeId);
		return recordTypeInfo != null && TIPOS_CON_BANCA_SEGURO.contains(recordTypeInfo.getDeveloperName());
	}

	public static Map<String, Object> getContexto(Id residentialLoanApplicationId) {
		ResidentialLoanApplication solicitud = obtenerSolicitud(residentialLoanApplicationId, false);
		Boolean esAdmin = FeatureManagement.checkPermission(PERMISO_ADMIN);
		Boolean puedeGestionarPagares = FSC_RoleAuthorizationService.canManagePagares(solicitud.FSC_UsuarioPagaresYContratos__c);
		List<DocumentoContrato> documentos = obtenerDocumentos(solicitud);
		Boolean aprobados = true;
		for (DocumentoContrato documento : documentos) {
			if (documento.estadoRevision != 'Aprobado' || (documento.noAplica != true && !documento.tieneArchivo))
				aprobados = false;
		}
		return new Map<String, Object>{
			'puedeCargar' => esAdmin || solicitud.CreatedById == UserInfo.getUserId(),
			'puedeRevisar' => puedeGestionarPagares,
			'documentosAprobados' => aprobados,
			'tieneCategoria' => !documentos.isEmpty(),
			'pedidoDocumentacion' => solicitud.FSC_DocumentacionExtraContratos__c,
			'fechaPedido' => solicitud.FSC_FechaPedidoDocsContratos__c
		};
	}

	public static void enviarARevision(Id residentialLoanApplicationId) {
		ResidentialLoanApplication solicitud = obtenerSolicitud(residentialLoanApplicationId, true);
		if (solicitud.Status != 'En proceso' || solicitud.FSC_Subestado__c != SUBESTADO_CARGA) {
			throw new AuraHandledException('La solicitud ya no está en Documentación para contratos. Actualice la página.');
		}
		if (!FeatureManagement.checkPermission(PERMISO_ADMIN) && solicitud.CreatedById != UserInfo.getUserId()) {
			throw new AuraHandledException('Solo el creador de la solicitud o un administrador puede enviar la documentación.');
		}
		FSC_ChecklistDocsController.initAndGetRows(solicitud.Id);
		for (DocumentoContrato documento : obtenerDocumentos(solicitud)) {
			if (documento.noAplica != true && !documento.tieneArchivo) {
				throw new AuraHandledException('Debe cargar o marcar como "No aplica" todos los documentos para confección de contrato.');
			}
		}
		if (solicitud.FSC_FechaPedidoDocsContratos__c != null)
			validarArchivoDelPedido(solicitud);
		// Se conservan el responsable, la aprobación y su fecha original.
		update new ResidentialLoanApplication(Id = solicitud.Id, FSC_Subestado__c = SUBESTADO_GENERACION);
	}

	public static void solicitarDocumentacion(Id residentialLoanApplicationId, String pedido) {
		ResidentialLoanApplication solicitud = obtenerSolicitud(residentialLoanApplicationId, true);
		validarResponsable(solicitud);
		validarEtapaGeneracion(solicitud);
		if (String.isBlank(pedido) || pedido.trim().length() > 500) {
			throw new AuraHandledException('Ingrese el pedido de documentación, con un máximo de 500 caracteres.');
		}
		String entrada = System.now().format('dd/MM/yyyy HH:mm') + ' - ' + UserInfo.getName() + ':\n' + pedido.trim();
		String historial = String.isBlank(solicitud.FSC_DocumentacionExtraContratos__c)
			? entrada
			: solicitud.FSC_DocumentacionExtraContratos__c + '\n\n' + entrada;
		if (historial.length() > 2000) {
			throw new AuraHandledException(
				'El historial de pedidos supera los 2.000 caracteres. Acorte el nuevo pedido; los anteriores se conservarán.'
			);
		}
		FSC_ChecklistDocsController.initAndGetRows(solicitud.Id);
		List<FSC_SolicitudDeCreditoYChecklistDeDocs__c> documentos = [
			SELECT Id, FSC_EstadoRevision__c
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE FSC_SolicitudDeCredito__c = :solicitud.Id AND FSC_Documento__r.FSC_CategoriaDelDocumento__c = :CATEGORIA
		];
		// El pedido es general: se reabre la categoría para permitir completar archivos y revisarla nuevamente.
		for (FSC_SolicitudDeCreditoYChecklistDeDocs__c documento : documentos)
			documento.FSC_EstadoRevision__c = 'Pendiente';
		if (!documentos.isEmpty())
			update documentos;
		update new ResidentialLoanApplication(
			Id = solicitud.Id,
			FSC_Subestado__c = SUBESTADO_CARGA,
			FSC_DocumentacionExtraContratos__c = historial,
			FSC_FechaPedidoDocsContratos__c = System.now()
		);
	}

	public static void validarGeneracion(Id solicitudId) {
		ResidentialLoanApplication solicitud = obtenerSolicitud(solicitudId, false);
		validarResponsable(solicitud);
		validarEtapaGeneracion(solicitud);
		for (DocumentoContrato documento : obtenerDocumentos(solicitud)) {
			if (documento.estadoRevision != 'Aprobado' || (documento.noAplica != true && !documento.tieneArchivo)) {
				throw new AuraHandledException(
					'Debe aprobar todos los documentos para confección de contrato en la pestaña Checklist de Documentos antes de generar.'
				);
			}
		}
	}

	public static void validarAccesoResponsable(Id solicitudId) {
		validarResponsable(obtenerSolicitud(solicitudId, false));
	}

	private static void validarResponsable(ResidentialLoanApplication solicitud) {
		if (!FSC_RoleAuthorizationService.canManagePagares(solicitud.FSC_UsuarioPagaresYContratos__c)) {
			throw new AuraHandledException('Solo el responsable de pagarés y contratos o un administrador puede realizar esta acción.');
		}
	}

	private static void validarEtapaGeneracion(ResidentialLoanApplication solicitud) {
		if (
			solicitud.Status != 'En proceso' ||
			solicitud.FSC_Subestado__c != SUBESTADO_GENERACION ||
			solicitud.FSC_Pagares_y_Plantillas_Generados__c
		) {
			throw new AuraHandledException('Esta acción solo está disponible antes de generar los pagarés y contratos. Actualice la página.');
		}
	}

	private static ResidentialLoanApplication obtenerSolicitud(Id solicitudId, Boolean bloquear) {
		if (solicitudId == null)
			throw new AuraHandledException('Solicitud requerida.');
		String consulta =
			'SELECT Id, RecordTypeId, Status, FSC_Subestado__c, CreatedById, FSC_UsuarioPagaresYContratos__c, ' +
			'FSC_Pagares_y_Plantillas_Generados__c, FSC_DocumentacionExtraContratos__c, FSC_FechaPedidoDocsContratos__c ' +
			'FROM ResidentialLoanApplication WHERE Id = :solicitudId';
		if (bloquear)
			consulta += ' FOR UPDATE';
		return (ResidentialLoanApplication) Database.query(consulta);
	}

	private static List<DocumentoContrato> obtenerDocumentos(ResidentialLoanApplication solicitud) {
		String tipo = FSC_ChecklistDocsController.resolveTiposSolicitud(new List<ResidentialLoanApplication>{ solicitud }).get(solicitud.Id);
		List<FSC_ChecklistDocumentos__c> catalogo = [
			SELECT Id
			FROM FSC_ChecklistDocumentos__c
			WHERE FSC_TipoDeSolicitudDeCredito__c = :tipo AND FSC_CategoriaDelDocumento__c = :CATEGORIA
		];
		Set<Id> documentoIds = new Map<Id, FSC_ChecklistDocumentos__c>(catalogo).keySet();
		Map<Id, FSC_SolicitudDeCreditoYChecklistDeDocs__c> porDocumento = new Map<Id, FSC_SolicitudDeCreditoYChecklistDeDocs__c>();
		Set<Id> joinIds = new Set<Id>();
		for (FSC_SolicitudDeCreditoYChecklistDeDocs__c fila : [
			SELECT Id, FSC_Documento__c, FSC_NoAplica__c, FSC_EstadoRevision__c
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE FSC_SolicitudDeCredito__c = :solicitud.Id AND FSC_Documento__c IN :documentoIds
		]) {
			porDocumento.put(fila.FSC_Documento__c, fila);
			joinIds.add(fila.Id);
		}
		Set<Id> conArchivo = new Set<Id>();
		if (!joinIds.isEmpty()) {
			for (ContentDocumentLink enlace : [SELECT LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :joinIds])
				conArchivo.add(enlace.LinkedEntityId);
		}
		List<DocumentoContrato> resultado = new List<DocumentoContrato>();
		for (FSC_ChecklistDocumentos__c documento : catalogo) {
			FSC_SolicitudDeCreditoYChecklistDeDocs__c fila = porDocumento.get(documento.Id);
			DocumentoContrato dto = new DocumentoContrato();
			dto.noAplica = fila != null && fila.FSC_NoAplica__c;
			dto.estadoRevision = fila == null ? 'Pendiente' : fila.FSC_EstadoRevision__c;
			dto.tieneArchivo = fila != null && conArchivo.contains(fila.Id);
			resultado.add(dto);
		}
		return resultado;
	}

	private static void validarArchivoDelPedido(ResidentialLoanApplication solicitud) {
		Set<Id> documentoIds = new Set<Id>();
		for (ContentDocumentLink enlace : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :solicitud.Id])
			documentoIds.add(enlace.ContentDocumentId);
		Integer nuevos = [
			SELECT COUNT()
			FROM ContentVersion
			WHERE ContentDocumentId IN :documentoIds AND CreatedDate >= :solicitud.FSC_FechaPedidoDocsContratos__c
		];
		if (nuevos == 0)
			throw new AuraHandledException(
				'Debe cargar un archivo nuevo o una nueva versión para atender el último pedido, en el checklist o en Relacionados > Archivos.'
			);
	}
}