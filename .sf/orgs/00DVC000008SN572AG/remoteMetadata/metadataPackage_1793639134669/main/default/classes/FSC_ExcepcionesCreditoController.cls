public with sharing class FSC_ExcepcionesCreditoController {
	@TestVisible
	private static Boolean testForceAuthorized = false;
	private static final Integer LONGITUD_COMENTARIO_APROBACION = 255;
	private static final String ESTADO_EN_PROCESO = 'En proceso';
	private static final String ESTADO_NO_APLICA = 'No aplica';
	private static final String ESTADO_PENDIENTE = 'Pendiente';
	private static final String ESTADO_APROBADA = 'Aprobada';
	private static final String ESTADO_RECHAZADA = 'Rechazada';
	private static final String TIPO_NEGOCIOS = 'Excepciones de Negocios';
	private static final String SUBESTADO_RECHAZADA_ANALISTA = 'Rechazado por análisis';
	private static final String SUBESTADO_RECHAZADA_CLIENTE = 'Rechazada por cliente';
	private static final String PERMISO_ADMINISTRADOR = 'FSC_CP_Administrador';
	private static final String PERMISO_OFICIAL_NEGOCIO = 'FSC_CP_Oficial_Negocio';
	private static final Set<String> SUBESTADOS_PERMITIDOS = new Set<String>{
		'En validación PEP/Listas',
		'En Motor Buró',
		'Recepción de documentos – Análisis'
	};

	public class FSC_OpcionExcepcion {
		@AuraEnabled
		public String tipo { get; set; }
		@AuraEnabled
		public String detalle { get; set; }
	}

	private class TargetSnapshot {
		private Id targetId;
		private String estado;
		private String condicion;
		private String tipo;
		private String detalle;
	}

	@AuraEnabled(cacheable=true)
	public static Map<String, Object> getContextoExcepcion(Id residentialLoanApplicationId) {
		ResidentialLoanApplication solicitud = requireSolicitud(residentialLoanApplicationId);
		List<FSC_Excepcion__c> excepciones = FSC_ExcepcionSelector.selectBySolicitud(residentialLoanApplicationId);
		Integer cantidad = getChildCount(solicitud);

		Set<Id> targetIds = new Set<Id>();
		for (FSC_Excepcion__c excepcion : excepciones) {
			targetIds.add(excepcion.Id);
		}
		Map<Id, List<ProcessInstanceWorkitem>> workItemsByTarget = FSC_ExcepcionApprovalService.getWorkItemsByTarget(targetIds);
		Set<Id> actionableTargetIds = FSC_ExcepcionApprovalService.getActionableTargetIds(workItemsByTarget);
		TargetSnapshot selected = selectCurrentTarget(excepciones, workItemsByTarget, actionableTargetIds);
		List<ProcessInstanceWorkitem> selectedWorkItems = selected == null || !workItemsByTarget.containsKey(selected.targetId)
			? new List<ProcessInstanceWorkitem>()
			: workItemsByTarget.get(selected.targetId);
		Boolean hasActiveApproval = !selectedWorkItems.isEmpty();
		Boolean autorizadoSolicitud = isOficialOAdministrador();
		Boolean tienePendientes = hasPendingException(excepciones);
		Integer maximoExcepciones = FSC_ExcepcionConfig.getMaximoExcepciones();

		return new Map<String, Object>{
			'excepcionId' => selected?.targetId,
			'solicitada' => cantidad > 0,
			'cantidad' => cantidad,
			'maximo' => maximoExcepciones,
			'disponibles' => Math.max(0, maximoExcepciones - cantidad),
			'limiteAlcanzado' => cantidad >= maximoExcepciones,
			'estado' => selected?.estado ?? ESTADO_NO_APLICA,
			'condicion' => selected?.condicion,
			'tipo' => selected?.tipo,
			'detalle' => selected?.detalle,
			'tienePendientes' => tienePendientes,
			'hasActiveApproval' => hasActiveApproval,
			'canActOnApproval' => selected != null && actionableTargetIds.contains(selected.targetId),
			'puedeSolicitar' => autorizadoSolicitud &&
			isSolicitudElegible(solicitud) &&
			cantidad < maximoExcepciones,
			'puedeResponderCondicion' => autorizadoSolicitud &&
			selected != null &&
			selected.estado == ESTADO_PENDIENTE &&
			String.isNotBlank(selected.condicion) &&
			!hasActiveApproval
		};
	}

	@AuraEnabled(cacheable=true)
	public static List<FSC_OpcionExcepcion> getOpcionesExcepcion() {
		List<FSC_OpcionExcepcion> opciones = new List<FSC_OpcionExcepcion>();
		for (FSC_ExcepcionesDeCredito__mdt configuracion : FSC_ExcepcionesDeCredito__mdt.getAll().values()) {
			if (String.isBlank(configuracion.FSC_Tipo__c) || String.isBlank(configuracion.FSC_Detalle__c)) {
				continue;
			}
			FSC_OpcionExcepcion opcion = new FSC_OpcionExcepcion();
			opcion.tipo = configuracion.FSC_Tipo__c;
			opcion.detalle = configuracion.FSC_Detalle__c;
			opciones.add(opcion);
		}
		return opciones;
	}

	@AuraEnabled
	public static Id solicitarExcepcion(Id residentialLoanApplicationId, String tipo, String detalle, String descripcion) {
		validateOficialOAdministrador();
		validateRequiredRequest(residentialLoanApplicationId, tipo, detalle, descripcion);
		ResidentialLoanApplication solicitud = requireSolicitud(residentialLoanApplicationId);
		if (!isSolicitudElegible(solicitud)) {
			throw new AuraHandledException('La excepción solo puede solicitarse en estado En proceso y en uno de los subestados habilitados.');
		}

		Integer cantidad = getChildCount(solicitud);
		if (cantidad >= FSC_ExcepcionConfig.getMaximoExcepciones()) {
			throw new AuraHandledException(FSC_ExcepcionConfig.getMensajeLimite());
		}

		FSC_ExcepcionesDeCredito__mdt configuracion = findConfiguration(tipo.trim(), detalle.trim());
		if (configuracion == null) {
			throw new AuraHandledException('El tipo y detalle seleccionados no corresponden a una excepción configurada.');
		}
		if (tipo.trim() != TIPO_NEGOCIOS && (solicitud.FSC_Monto__c == null || solicitud.FSC_Monto__c <= 0)) {
			throw new AuraHandledException('La solicitud debe tener un monto mayor que cero para determinar la ruta de aprobación.');
		}

		FSC_Excepcion__c excepcion = new FSC_Excepcion__c(
			FSC_Solicitud_Prestamo__c = residentialLoanApplicationId,
			FSC_Tipo__c = configuracion.FSC_Tipo__c,
			FSC_Detalle__c = configuracion.FSC_Detalle__c,
			FSC_Motivo__c = descripcion.trim(),
			FSC_Estado__c = ESTADO_PENDIENTE
		);
		Database.insert(excepcion, AccessLevel.USER_MODE);
		FSC_ExcepcionApprovalService.submit(excepcion.Id);
		return excepcion.Id;
	}

	@AuraEnabled
	public static void aprobarExcepcion(Id excepcionId) {
		FSC_ExcepcionApprovalService.process(excepcionId, 'Approve', 'Excepción aprobada.');
	}

	@AuraEnabled
	public static void aprobarExcepcionConCondicion(Id excepcionId, String condicion) {
		if (String.isBlank(condicion)) {
			throw new AuraHandledException('Condición requerida.');
		}
		if (condicion.length() > 32768) {
			throw new AuraHandledException('La condición excede el máximo permitido.');
		}
		FSC_ExcepcionApprovalService.assertCurrentUserCanAct(excepcionId);
		updateTargetCondition(excepcionId, condicion.trim());
		String comentario = 'Aprobada con condición: ' + condicion.trim();
		if (comentario.length() > LONGITUD_COMENTARIO_APROBACION) {
			comentario = comentario.substring(0, LONGITUD_COMENTARIO_APROBACION);
		}
		Approval.ProcessResult result = FSC_ExcepcionApprovalService.process(excepcionId, 'Approve', comentario);
		if (result.getInstanceStatus() != 'Approved') {
			throw new AuraHandledException('No se pudo finalizar la aprobación condicionada.');
		}
		updateTargetState(excepcionId, ESTADO_PENDIENTE);
	}

	@AuraEnabled
	public static void rechazarExcepcion(Id excepcionId, String motivo) {
		if (String.isBlank(motivo)) {
			throw new AuraHandledException('Motivo requerido.');
		}
		String motivoNormalizado = motivo.trim();
		if (motivoNormalizado.length() > LONGITUD_COMENTARIO_APROBACION) {
			throw new AuraHandledException('Motivo máximo 255 caracteres.');
		}
		requireTarget(excepcionId);
		FSC_ExcepcionTriggerHandler.setRejectionContext(excepcionId, SUBESTADO_RECHAZADA_ANALISTA, motivoNormalizado);
		try {
			Approval.ProcessResult result = FSC_ExcepcionApprovalService.process(excepcionId, 'Reject', motivoNormalizado);
			if (result.getInstanceStatus() != 'Rejected') {
				throw new AuraHandledException('No se pudo finalizar el rechazo de la excepción.');
			}
		} finally {
			FSC_ExcepcionTriggerHandler.clearRejectionContext(excepcionId);
		}
	}

	@AuraEnabled
	public static void responderCondicionCliente(Id excepcionId, Boolean clienteAprueba) {
		validateOficialOAdministrador();
		if (excepcionId == null || clienteAprueba == null) {
			throw new AuraHandledException('Excepción y respuesta del cliente requeridas.');
		}
		TargetSnapshot target = requireTarget(excepcionId);
		if (target.estado != ESTADO_PENDIENTE || String.isBlank(target.condicion)) {
			throw new AuraHandledException('La excepción no tiene una condición pendiente de respuesta.');
		}
		if (FSC_ExcepcionApprovalService.hasActiveWorkItem(excepcionId)) {
			throw new AuraHandledException('La aprobación condicionada aún no ha finalizado.');
		}
		if (clienteAprueba) {
			updateTargetState(excepcionId, ESTADO_APROBADA);
			return;
		}

		FSC_ExcepcionTriggerHandler.setRejectionContext(excepcionId, SUBESTADO_RECHAZADA_CLIENTE, null);
		try {
			updateTargetState(excepcionId, ESTADO_RECHAZADA);
		} finally {
			FSC_ExcepcionTriggerHandler.clearRejectionContext(excepcionId);
		}
	}

	private static TargetSnapshot selectCurrentTarget(
		List<FSC_Excepcion__c> excepciones,
		Map<Id, List<ProcessInstanceWorkitem>> workItemsByTarget,
		Set<Id> actionableTargetIds
	) {
		for (FSC_Excepcion__c excepcion : excepciones) {
			if (excepcion.FSC_Estado__c == ESTADO_PENDIENTE && actionableTargetIds.contains(excepcion.Id)) {
				return childSnapshot(excepcion);
			}
		}
		for (FSC_Excepcion__c excepcion : excepciones) {
			if (excepcion.FSC_Estado__c == ESTADO_PENDIENTE && workItemsByTarget.containsKey(excepcion.Id)) {
				return childSnapshot(excepcion);
			}
		}
		for (FSC_Excepcion__c excepcion : excepciones) {
			if (excepcion.FSC_Estado__c == ESTADO_PENDIENTE && String.isNotBlank(excepcion.FSC_Condicion__c)) {
				return childSnapshot(excepcion);
			}
		}
		if (!excepciones.isEmpty()) {
			return childSnapshot(excepciones[0]);
		}
		return null;
	}

	private static TargetSnapshot requireTarget(Id targetId) {
		if (targetId == null) {
			throw new AuraHandledException('Excepción requerida.');
		}
		if (targetId.getSObjectType() != FSC_Excepcion__c.SObjectType) {
			throw new AuraHandledException('El identificador no corresponde a una excepción FSC.');
		}
		FSC_Excepcion__c excepcion = FSC_ExcepcionSelector.selectById(targetId);
		if (excepcion == null) {
			throw new AuraHandledException('No se encontró la excepción.');
		}
		return childSnapshot(excepcion);
	}

	private static TargetSnapshot childSnapshot(FSC_Excepcion__c excepcion) {
		TargetSnapshot target = new TargetSnapshot();
		target.targetId = excepcion.Id;
		target.estado = excepcion.FSC_Estado__c;
		target.condicion = excepcion.FSC_Condicion__c;
		target.tipo = excepcion.FSC_Tipo__c;
		target.detalle = excepcion.FSC_Detalle__c;
		return target;
	}

	private static ResidentialLoanApplication requireSolicitud(Id solicitudId) {
		if (solicitudId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		ResidentialLoanApplication solicitud = FSC_ExcepcionSelector.selectSolicitud(solicitudId);
		if (solicitud == null) {
			throw new AuraHandledException('No se encontró la solicitud.');
		}
		return solicitud;
	}

	private static Boolean hasPendingException(List<FSC_Excepcion__c> excepciones) {
		for (FSC_Excepcion__c excepcion : excepciones) {
			if (excepcion.FSC_Estado__c == ESTADO_PENDIENTE) {
				return true;
			}
		}
		return false;
	}

	private static Integer getChildCount(ResidentialLoanApplication solicitud) {
		return solicitud.FSC_Cantidad_Excepciones__c == null ? 0 : solicitud.FSC_Cantidad_Excepciones__c.intValue();
	}

	private static Boolean isSolicitudElegible(ResidentialLoanApplication solicitud) {
		return solicitud.Status == ESTADO_EN_PROCESO && SUBESTADOS_PERMITIDOS.contains(solicitud.FSC_Subestado__c);
	}

	private static FSC_ExcepcionesDeCredito__mdt findConfiguration(String tipo, String detalle) {
		for (FSC_ExcepcionesDeCredito__mdt configuracion : FSC_ExcepcionesDeCredito__mdt.getAll().values()) {
			if (configuracion.FSC_Tipo__c == tipo && configuracion.FSC_Detalle__c == detalle) {
				return configuracion;
			}
		}
		return null;
	}

	private static void updateTargetCondition(Id targetId, String condicion) {
		requireTarget(targetId);
		Database.update(new FSC_Excepcion__c(Id = targetId, FSC_Condicion__c = condicion), AccessLevel.SYSTEM_MODE);
	}

	private static void updateTargetState(Id targetId, String estado) {
		requireTarget(targetId);
		Database.update(new FSC_Excepcion__c(Id = targetId, FSC_Estado__c = estado), AccessLevel.SYSTEM_MODE);
	}

	private static void validateRequiredRequest(Id solicitudId, String tipo, String detalle, String descripcion) {
		if (solicitudId == null || String.isBlank(tipo) || String.isBlank(detalle) || String.isBlank(descripcion)) {
			throw new AuraHandledException('Tipo, detalle y descripción son obligatorios.');
		}
		if (descripcion.length() > 32768) {
			throw new AuraHandledException('La descripción excede el máximo permitido.');
		}
	}

	private static void validateOficialOAdministrador() {
		if (!isOficialOAdministrador()) {
			throw new AuraHandledException('Solo el oficial de negocio o un administrador puede realizar esta acción.');
		}
	}

	private static Boolean isOficialOAdministrador() {
		return (Test.isRunningTest() && testForceAuthorized) ||
			FeatureManagement.checkPermission(PERMISO_OFICIAL_NEGOCIO) ||
			FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR);
	}
}