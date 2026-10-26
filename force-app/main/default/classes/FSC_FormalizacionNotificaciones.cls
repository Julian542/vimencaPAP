// Avisos (campanita y correo) al responsable de cada etapa de la formalización de garantías.
// Se envían de forma asíncrona y nunca interrumpen la transacción que cambió la etapa:
// cualquier error se descarta y solo se pierde el aviso.
public without sharing class FSC_FormalizacionNotificaciones implements Queueable {
	public static final String TIPO_NOTIFICACION = 'FSC_FormalizacionGarantias';
	private static final String COLA_FORMALIZACION = 'FSC_GestionFormalizacion';
	private static final Map<String, String> COLA_POR_ETAPA = new Map<String, String>{
		FSC_FormalizacionGarantiasService.ETAPA_SOLICITUD_CHEQUE => 'FSC_ColaOperaciones',
		FSC_FormalizacionGarantiasService.ETAPA_MANTENIMIENTO => 'FSC_ColaMantenimientoOperaciones',
		FSC_FormalizacionGarantiasService.ETAPA_CUSTODIA => 'FSC_Cola_Archivo_y_custodia_de_valores',
		FSC_FormalizacionGarantiasService.ETAPA_CDD => 'FSC_ColaCDD'
	};
	private static final Set<String> ETAPAS_OFICIAL = new Set<String>{
		FSC_FormalizacionGarantiasService.ETAPA_DEVUELTA_OFICIAL,
		FSC_FormalizacionGarantiasService.ETAPA_PENDIENTE_MATRICULA
	};
	private static final Map<String, String> PENDIENTE_POR_ETAPA = new Map<String, String>{
		FSC_FormalizacionGarantiasService.ETAPA_REVISION => 'Revisar el expediente y definir la modalidad de formalización.',
		FSC_FormalizacionGarantiasService.ETAPA_DEVUELTA_OFICIAL => 'Completar la documentación indicada por Formalización y reenviar la solicitud.',
		FSC_FormalizacionGarantiasService.ETAPA_FIRMAS => 'Gestionar la recolección de firmas y notarización.',
		FSC_FormalizacionGarantiasService.ETAPA_AUTORIZACION_DGII => 'Solicitar a la DGII la autorización de pago y enviar a Ejecución de Operaciones.',
		FSC_FormalizacionGarantiasService.ETAPA_SOLICITUD_CHEQUE => 'Solicitar el cheque de pago de impuestos, adjuntarlo y devolver a Formalización.',
		FSC_FormalizacionGarantiasService.ETAPA_PAGO_DGII => 'Dar seguimiento al pago de impuestos en la DGII.',
		FSC_FormalizacionGarantiasService.ETAPA_DEPOSITO_TITULOS => 'Continuar con el depósito en el Registro de Títulos.',
		FSC_FormalizacionGarantiasService.ETAPA_SEGM => 'Registrar el aviso de la garantía en el SEGM.',
		FSC_FormalizacionGarantiasService.ETAPA_PENDIENTE_MATRICULA => 'Gestionar con el cliente la matrícula original y enviarla a Formalización.',
		FSC_FormalizacionGarantiasService.ETAPA_OPOSICION_MATRICULA => 'Generar la autorización de oposición y depositar la matrícula en la DGII.',
		FSC_FormalizacionGarantiasService.ETAPA_MATRICULA_DGII => 'Dar seguimiento a la oposición de la matrícula en la DGII.',
		FSC_FormalizacionGarantiasService.ETAPA_DISPONIBLE_ENTREGA => 'Enviar a retirar el expediente.',
		FSC_FormalizacionGarantiasService.ETAPA_EN_RETIRO => 'Registrar el retiro del expediente y la fecha de formalización.',
		FSC_FormalizacionGarantiasService.ETAPA_MANTENIMIENTO => 'Registrar en el sistema la fecha de formalización de la garantía y devolver a Formalización.',
		FSC_FormalizacionGarantiasService.ETAPA_ENVIO_CUSTODIA => 'Remitir los originales a Custodia.',
		FSC_FormalizacionGarantiasService.ETAPA_CUSTODIA => 'Recibir los originales de la garantía y acusar recibo.',
		FSC_FormalizacionGarantiasService.ETAPA_CDD => 'Digitalizar los documentos en el expediente del cliente.',
		FSC_FormalizacionGarantiasService.ETAPA_COMPLETADA => 'Sin acciones: la formalización de la garantía quedó completada.'
	};

	// Una solicitud se avisa una sola vez por transacción; el aviso lee el estado final al ejecutarse.
	@TestVisible
	private static Set<Id> programadas = new Set<Id>();
	@TestVisible
	private static List<Aviso> enviadosEnPrueba = new List<Aviso>();

	private final List<Id> solicitudesIds;
	private final Map<Id, String> etapaAnteriorPorSolicitud;
	private final Id actorId;

	public FSC_FormalizacionNotificaciones(List<Id> solicitudesIds, Map<Id, String> etapaAnteriorPorSolicitud, Id actorId) {
		this.solicitudesIds = solicitudesIds;
		this.etapaAnteriorPorSolicitud = etapaAnteriorPorSolicitud;
		this.actorId = actorId;
	}

	// ===== Trigger (after update) =====

	public static void programar(List<ResidentialLoanApplication> nuevas, Map<Id, ResidentialLoanApplication> anteriores) {
		try {
			List<Id> ids = new List<Id>();
			Map<Id, String> etapasAnteriores = new Map<Id, String>();
			for (ResidentialLoanApplication rla : nuevas) {
				ResidentialLoanApplication anterior = anteriores?.get(rla.Id);
				if (anterior == null || programadas.contains(rla.Id) || !requiereAviso(rla, anterior)) {
					continue;
				}
				programadas.add(rla.Id);
				ids.add(rla.Id);
				etapasAnteriores.put(rla.Id, anterior.FSC_EtapaFormalizacion__c);
			}
			if (ids.isEmpty() || Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
				return;
			}
			System.enqueueJob(new FSC_FormalizacionNotificaciones(ids, etapasAnteriores, UserInfo.getUserId()));
		} catch (Exception e) {
			System.debug(LoggingLevel.WARN, 'No se pudo programar el aviso de formalización: ' + e.getMessage());
		}
	}

	@TestVisible
	private static Boolean requiereAviso(ResidentialLoanApplication rla, ResidentialLoanApplication anterior) {
		String etapa = rla.FSC_EtapaFormalizacion__c;
		if (String.isBlank(etapa) || etapa == FSC_FormalizacionGarantiasService.ETAPA_EN_DESEMBOLSO) {
			return false;
		}
		if (etapa != anterior.FSC_EtapaFormalizacion__c) {
			// Los avances internos de Formalización los hace el mismo usuario: no se avisa a sí mismo.
			return !(esEtapaFormalizacion(etapa) && esEtapaFormalizacion(anterior.FSC_EtapaFormalizacion__c));
		}
		// Reasignación dentro de la misma etapa.
		if (COLA_POR_ETAPA.containsKey(etapa)) {
			return rla.FSC_ResponsableAreaFormalizacion__c != anterior.FSC_ResponsableAreaFormalizacion__c &&
				rla.FSC_ResponsableAreaFormalizacion__c != null;
		}
		return esEtapaFormalizacion(etapa) &&
			rla.FSC_UsuarioFormalizacion__c != anterior.FSC_UsuarioFormalizacion__c &&
			rla.FSC_UsuarioFormalizacion__c != null;
	}

	private static Boolean esEtapaFormalizacion(String etapa) {
		return !String.isBlank(etapa) &&
			!ETAPAS_OFICIAL.contains(etapa) &&
			!COLA_POR_ETAPA.containsKey(etapa) &&
			etapa != FSC_FormalizacionGarantiasService.ETAPA_EN_DESEMBOLSO &&
			etapa != FSC_FormalizacionGarantiasService.ETAPA_COMPLETADA;
	}

	// ===== Ejecución asíncrona =====

	public void execute(QueueableContext context) {
		try {
			List<Aviso> avisos = armarAvisos();
			enviarCampanita(avisos);
			enviarCorreos(avisos);
			if (Test.isRunningTest()) {
				enviadosEnPrueba.addAll(avisos);
			}
		} catch (Exception e) {
			System.debug(LoggingLevel.WARN, 'No se pudieron enviar los avisos de formalización: ' + e.getMessage());
		}
	}

	@TestVisible
	private List<Aviso> armarAvisos() {
		List<Aviso> avisos = new List<Aviso>();
		Map<String, Set<Id>> miembrosPorCola = new Map<String, Set<Id>>();
		for (ResidentialLoanApplication rla : [
			SELECT
				Id,
				Name,
				OwnerId,
				Account.Name,
				Status,
				FSC_EtapaFormalizacion__c,
				FSC_ObservacionFormalizacion__c,
				FSC_UsuarioFormalizacion__c,
				FSC_ResponsableAreaFormalizacion__c
			FROM ResidentialLoanApplication
			WHERE Id IN :solicitudesIds
		]) {
			String etapa = rla.FSC_EtapaFormalizacion__c;
			if (String.isBlank(etapa) || etapa == FSC_FormalizacionGarantiasService.ETAPA_EN_DESEMBOLSO) {
				continue;
			}
			Set<Id> destinatarios = new Set<Id>();
			if (ETAPAS_OFICIAL.contains(etapa) || etapa == FSC_FormalizacionGarantiasService.ETAPA_COMPLETADA) {
				destinatarios.add(rla.OwnerId);
			} else if (COLA_POR_ETAPA.containsKey(etapa)) {
				destinatarios.addAll(
					rla.FSC_ResponsableAreaFormalizacion__c != null
						? new Set<Id>{ rla.FSC_ResponsableAreaFormalizacion__c }
						: miembros(COLA_POR_ETAPA.get(etapa), miembrosPorCola)
				);
			} else {
				destinatarios.addAll(
					rla.FSC_UsuarioFormalizacion__c != null
						? new Set<Id>{ rla.FSC_UsuarioFormalizacion__c }
						: miembros(COLA_FORMALIZACION, miembrosPorCola)
				);
			}
			destinatarios.remove(actorId);
			destinatarios.remove(null);
			// El propietario puede ser una cola: solo se avisa a usuarios.
			Set<Id> usuarios = new Set<Id>();
			for (Id destinatario : destinatarios) {
				if (destinatario.getSObjectType() == User.SObjectType) {
					usuarios.add(destinatario);
				}
			}
			if (!usuarios.isEmpty()) {
				avisos.add(new Aviso(rla, etapaAnteriorPorSolicitud?.get(rla.Id), usuarios));
			}
		}
		filtrarActivos(avisos);
		return avisos;
	}

	private static Set<Id> miembros(String cola, Map<String, Set<Id>> cache) {
		if (!cache.containsKey(cola)) {
			List<Group> grupos = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :cola LIMIT 1];
			cache.put(cola, grupos.isEmpty() ? new Set<Id>() : FSC_RandomQueueApproverAction.collectCandidatePrincipalIds(grupos[0].Id));
		}
		return cache.get(cola);
	}

	private static void filtrarActivos(List<Aviso> avisos) {
		Set<Id> todos = new Set<Id>();
		for (Aviso aviso : avisos) {
			todos.addAll(aviso.destinatarios);
		}
		Set<Id> activos = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :todos AND IsActive = TRUE]).keySet();
		for (Aviso aviso : avisos) {
			aviso.destinatarios.retainAll(activos);
		}
	}

	private static void enviarCampanita(List<Aviso> avisos) {
		List<CustomNotificationType> tipos = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = :TIPO_NOTIFICACION LIMIT 1];
		if (tipos.isEmpty()) {
			return;
		}
		for (Aviso aviso : avisos) {
			if (aviso.destinatarios.isEmpty()) {
				continue;
			}
			try {
				Messaging.CustomNotification notificacion = new Messaging.CustomNotification();
				notificacion.setNotificationTypeId(tipos[0].Id);
				notificacion.setTargetId(aviso.solicitudId);
				notificacion.setTitle(aviso.asunto().left(250));
				notificacion.setBody(aviso.textoCorto().left(750));
				Set<String> ids = new Set<String>();
				for (Id destinatario : aviso.destinatarios) {
					ids.add(destinatario);
				}
				notificacion.send(ids);
			} catch (Exception e) {
				System.debug(LoggingLevel.WARN, 'No se pudo enviar la notificación de formalización: ' + e.getMessage());
			}
		}
	}

	private static void enviarCorreos(List<Aviso> avisos) {
		List<Messaging.SingleEmailMessage> correos = new List<Messaging.SingleEmailMessage>();
		String baseUrl = URL.getOrgDomainUrl().toExternalForm();
		for (Aviso aviso : avisos) {
			for (Id destinatario : aviso.destinatarios) {
				Messaging.SingleEmailMessage correo = new Messaging.SingleEmailMessage();
				correo.setTargetObjectId(destinatario);
				correo.setSaveAsActivity(false);
				correo.setSubject(aviso.asunto());
				correo.setHtmlBody(aviso.cuerpoHtml(baseUrl));
				correo.setPlainTextBody(aviso.textoCorto() + '\n\n' + baseUrl + '/' + aviso.solicitudId);
				correos.add(correo);
			}
		}
		if (!correos.isEmpty()) {
			// allOrNone = false: un destinatario con problemas no impide los demás correos.
			Messaging.sendEmail(correos, false);
		}
	}

	// ===== Tipos =====

	public class Aviso {
		public Id solicitudId;
		public String solicitud;
		public String cliente;
		public String etapa;
		public String etapaAnterior;
		public String observacion;
		public Set<Id> destinatarios;

		Aviso(ResidentialLoanApplication rla, String etapaAnterior, Set<Id> destinatarios) {
			this.solicitudId = rla.Id;
			this.solicitud = rla.Name;
			this.cliente = rla.Account?.Name;
			this.etapa = rla.FSC_EtapaFormalizacion__c;
			this.etapaAnterior = etapaAnterior;
			this.observacion = rla.FSC_ObservacionFormalizacion__c;
			this.destinatarios = destinatarios;
		}

		public String pendiente() {
			return PENDIENTE_POR_ETAPA.containsKey(etapa) ? PENDIENTE_POR_ETAPA.get(etapa) : 'Revisar la solicitud.';
		}

		public String asunto() {
			return 'Formalización de garantía - ' + solicitud + ': ' + etapa;
		}

		public String textoCorto() {
			String texto = 'Etapa: ' + etapa + '. Pendiente: ' + pendiente();
			if (etapa == FSC_FormalizacionGarantiasService.ETAPA_DEVUELTA_OFICIAL && !String.isBlank(observacion)) {
				texto += ' Observación: ' + observacion;
			}
			return texto;
		}

		public String cuerpoHtml(String baseUrl) {
			String html =
				'<p>La solicitud <b>' + esc(solicitud) + '</b>' +
				(String.isBlank(cliente) ? '' : ' del cliente <b>' + esc(cliente) + '</b>') +
				' requiere su atención en el proceso de formalización de garantías.</p>' +
				'<p><b>Etapa actual:</b> ' + esc(etapa) +
				(String.isBlank(etapaAnterior) ? '' : '<br/><b>Etapa anterior:</b> ' + esc(etapaAnterior)) +
				'<br/><b>Pendiente:</b> ' + esc(pendiente()) + '</p>';
			if (!String.isBlank(observacion)) {
				html += '<p><b>Última observación:</b> ' + esc(observacion) + '</p>';
			}
			return html + '<p><a href="' + baseUrl + '/' + solicitudId + '">Abrir la solicitud en Salesforce</a></p>';
		}

		private String esc(String valor) {
			return valor == null ? '' : valor.escapeHtml4();
		}
	}
}