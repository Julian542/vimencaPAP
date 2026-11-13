public inherited sharing class FSC_ExcepcionTriggerHandler {
	private static final String MENSAJE_ELIMINACION = 'No se pueden eliminar excepciones porque el límite configurado es histórico. Corrija el registro en lugar de eliminarlo.';
	private static final String ESTADO_RECHAZADA = 'Rechazada';
	private static final String ESTADO_CERRADA_PERDIDA = 'Cerrada Perdida';
	private static final String SUBESTADO_RECHAZADA_ANALISTA = 'Rechazado por análisis';
	private static Map<Id, RejectionContext> rejectionContextByExceptionId = new Map<Id, RejectionContext>();

	private class RejectionContext {
		private String subestado;
		private String motivo;
	}

	public static void setRejectionContext(Id excepcionId, String subestado, String motivo) {
		if (excepcionId == null || String.isBlank(subestado)) {
			return;
		}
		RejectionContext context = new RejectionContext();
		context.subestado = subestado;
		context.motivo = motivo;
		rejectionContextByExceptionId.put(excepcionId, context);
	}

	public static void clearRejectionContext(Id excepcionId) {
		if (excepcionId != null) {
			rejectionContextByExceptionId.remove(excepcionId);
		}
	}

	public static void beforeInsert(List<FSC_Excepcion__c> nuevosRegistros) {
		Integer maximoExcepciones = FSC_ExcepcionConfig.getMaximoExcepciones();
		Map<Id, Integer> entrantesPorSolicitud = contarEntrantes(nuevosRegistros);
		if (entrantesPorSolicitud.isEmpty()) {
			return;
		}

		Set<Id> solicitudIds = bloquearSolicitudes(entrantesPorSolicitud.keySet());
		Map<Id, Integer> existentesPorSolicitud = contarExistentes(solicitudIds);
		Map<Id, Integer> conteoEfectivo = new Map<Id, Integer>();
		for (Id solicitudId : solicitudIds) {
			conteoEfectivo.put(solicitudId, existentesPorSolicitud.get(solicitudId) ?? 0);
		}

		for (FSC_Excepcion__c excepcion : nuevosRegistros) {
			Id solicitudId = excepcion.FSC_Solicitud_Prestamo__c;
			if (solicitudId == null || !conteoEfectivo.containsKey(solicitudId)) {
				continue;
			}
			Integer cantidadEfectiva = conteoEfectivo.get(solicitudId);
			if (cantidadEfectiva >= maximoExcepciones) {
				Boolean reglaValidacionPuedeBloquear =
					(existentesPorSolicitud.get(solicitudId) ?? 0) >= maximoExcepciones &&
					entrantesPorSolicitud.get(solicitudId) == 1;
				if (!reglaValidacionPuedeBloquear) {
					excepcion.addError(FSC_ExcepcionConfig.getMensajeLimite());
				}
				continue;
			}
			conteoEfectivo.put(solicitudId, cantidadEfectiva + 1);
		}
	}

	private static Map<Id, Integer> contarEntrantes(List<FSC_Excepcion__c> nuevosRegistros) {
		Map<Id, Integer> cantidades = new Map<Id, Integer>();
		for (FSC_Excepcion__c excepcion : nuevosRegistros) {
			Id solicitudId = excepcion.FSC_Solicitud_Prestamo__c;
			if (solicitudId != null) {
				cantidades.put(solicitudId, (cantidades.get(solicitudId) ?? 0) + 1);
			}
		}
		return cantidades;
	}

	private static Set<Id> bloquearSolicitudes(Set<Id> solicitudIds) {
		return new Map<Id, ResidentialLoanApplication>(
				[
					SELECT Id
					FROM ResidentialLoanApplication
					WHERE Id IN :solicitudIds
					WITH SYSTEM_MODE
					FOR UPDATE
				]
			)
			.keySet();
	}

	private static Map<Id, Integer> contarExistentes(Set<Id> solicitudIds) {
		Map<Id, Integer> existentesPorSolicitud = new Map<Id, Integer>();
		for (FSC_Excepcion__c existente : [
			SELECT FSC_Solicitud_Prestamo__c
			FROM FSC_Excepcion__c
			WHERE FSC_Solicitud_Prestamo__c IN :solicitudIds
			WITH SYSTEM_MODE
		]) {
			Id solicitudId = existente.FSC_Solicitud_Prestamo__c;
			existentesPorSolicitud.put(solicitudId, (existentesPorSolicitud.get(solicitudId) ?? 0) + 1);
		}
		return existentesPorSolicitud;
	}

	public static void beforeDelete(List<FSC_Excepcion__c> registrosEliminados) {
		for (FSC_Excepcion__c excepcion : registrosEliminados) {
			excepcion.addError(MENSAJE_ELIMINACION);
		}
	}

	public static void afterUpdate(Map<Id, FSC_Excepcion__c> nuevos, Map<Id, FSC_Excepcion__c> anteriores) {
		Map<Id, RejectionContext> contextBySolicitudId = new Map<Id, RejectionContext>();
		for (Id excepcionId : nuevos.keySet()) {
			FSC_Excepcion__c actual = nuevos.get(excepcionId);
			FSC_Excepcion__c anterior = anteriores.get(excepcionId);
			if (actual.FSC_Estado__c != ESTADO_RECHAZADA || anterior.FSC_Estado__c == ESTADO_RECHAZADA) {
				continue;
			}
			RejectionContext context = rejectionContextByExceptionId.get(excepcionId);
			if (!contextBySolicitudId.containsKey(actual.FSC_Solicitud_Prestamo__c) || context != null) {
				contextBySolicitudId.put(actual.FSC_Solicitud_Prestamo__c, context);
			}
		}

		List<ResidentialLoanApplication> solicitudesActualizar = new List<ResidentialLoanApplication>();
		for (Id solicitudId : contextBySolicitudId.keySet()) {
			RejectionContext context = contextBySolicitudId.get(solicitudId);
			ResidentialLoanApplication solicitud = new ResidentialLoanApplication(
				Id = solicitudId,
				Status = ESTADO_CERRADA_PERDIDA,
				FSC_Subestado__c = context?.subestado ?? SUBESTADO_RECHAZADA_ANALISTA
			);
			if (String.isNotBlank(context?.motivo)) {
				solicitud.FSC_Motivo_Rechazo__c = context.motivo;
			}
			solicitudesActualizar.add(solicitud);
		}
		if (!solicitudesActualizar.isEmpty()) {
			Database.update(solicitudesActualizar, AccessLevel.SYSTEM_MODE);
		}
	}
}