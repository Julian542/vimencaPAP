// Proceso de formalización de garantías por etapas (hipotecaria, vehículo y mobiliaria SEGM), con un expediente por solicitud.
// Las áreas solo leen la solicitud (modelo Private): las escrituras se hacen sin sharing después de validar
// que el usuario es el actor de la etapa actual, y solo tocan los campos que arma esta clase.
public without sharing class FSC_FormalizacionGarantiasService {
	public static final String RUTA_HIPOTECARIA = 'hipotecaria';
	public static final String RUTA_VEHICULO = 'vehiculo';
	public static final String RUTA_MOBILIARIA = 'mobiliaria';

	public static final String ETAPA_REVISION = 'Revisión de documentos';
	public static final String ETAPA_DEVUELTA_OFICIAL = 'Devuelta al oficial';
	public static final String ETAPA_FIRMAS = 'Recolección de firmas y notarización';
	public static final String ETAPA_AUTORIZACION_DGII = 'Pendiente de autorización DGII';
	public static final String ETAPA_SOLICITUD_CHEQUE = 'Solicitud de cheque';
	public static final String ETAPA_PAGO_DGII = 'En proceso de pago en DGII';
	public static final String ETAPA_DEPOSITO_TITULOS = 'Depósito en Registro de Títulos';
	public static final String ETAPA_SEGM = 'Registro de aviso en SEGM';
	public static final String ETAPA_EN_DESEMBOLSO = 'En desembolso';
	public static final String ETAPA_PENDIENTE_MATRICULA = 'Pendiente de matrícula original';
	public static final String ETAPA_OPOSICION_MATRICULA = 'Oposición de matrícula';
	public static final String ETAPA_MATRICULA_DGII = 'Matrícula depositada en DGII';
	public static final String ETAPA_DISPONIBLE_ENTREGA = 'Disponible para entrega';
	public static final String ETAPA_EN_RETIRO = 'En retiro';
	public static final String ETAPA_MANTENIMIENTO = 'Mantenimiento de Operaciones';
	public static final String ETAPA_ENVIO_CUSTODIA = 'Pendiente envío a Custodia';
	public static final String ETAPA_CUSTODIA = 'En Custodia';
	public static final String ETAPA_CDD = 'Digitalización CDD';
	public static final String ETAPA_COMPLETADA = 'Completada';

	public static final String MODALIDAD_ANTES = 'Registro antes del desembolso';
	public static final String MODALIDAD_SOLO_IMPUESTO = 'Solo liquidar impuesto';
	public static final String MODALIDAD_DESPUES = 'Registro después del desembolso';

	public static final String ACCION_CONTINUAR = 'CONTINUAR';
	public static final String ACCION_DEVOLVER_OFICIAL = 'DEVOLVER_OFICIAL';
	public static final String ACCION_REENVIAR_FORMALIZACION = 'REENVIAR_FORMALIZACION';
	public static final String ACCION_FIRMAS_COMPLETADAS = 'FIRMAS_COMPLETADAS';
	public static final String ACCION_ENVIAR_EJECUCION = 'ENVIAR_EJECUCION';
	public static final String ACCION_CHEQUE_ANEXADO = 'CHEQUE_ANEXADO';
	public static final String ACCION_IMPUESTOS_LIQUIDADOS = 'IMPUESTOS_LIQUIDADOS';
	public static final String ACCION_REGISTRAR_DEPOSITO = 'REGISTRAR_DEPOSITO';
	public static final String ACCION_REGISTRAR_SEGM = 'REGISTRAR_SEGM';
	public static final String ACCION_ENVIAR_MATRICULA = 'ENVIAR_MATRICULA';
	public static final String ACCION_DEPOSITAR_MATRICULA = 'DEPOSITAR_MATRICULA';
	public static final String ACCION_DISPONIBLE_ENTREGA = 'DISPONIBLE_ENTREGA';
	public static final String ACCION_ENVIAR_RETIRO = 'ENVIAR_RETIRO';
	public static final String ACCION_REGISTRAR_RETIRO = 'REGISTRAR_RETIRO';
	public static final String ACCION_FECHA_REGISTRADA = 'FECHA_REGISTRADA';
	public static final String ACCION_ENVIAR_CUSTODIA = 'ENVIAR_CUSTODIA';
	public static final String ACCION_ACUSAR_RECIBO = 'ACUSAR_RECIBO';
	public static final String ACCION_DIGITALIZACION_COMPLETADA = 'DIGITALIZACION_COMPLETADA';

	public static final String PERMISO_ADMINISTRADOR = 'FSC_CP_Administrador';
	public static final String PERMISO_FORMALIZACION = 'FSC_CP_Formalizacion_Creditos';
	public static final String RESPUESTA_SI = 'Sí';
	public static final String RESPUESTA_NO = 'No';

	private static final String SUBESTADO_FORMALIZACION = 'Formalización';
	private static final String SUBESTADO_DOC_DESEMBOLSO = 'Documentación para desembolso y firmas';
	private static final String SUBESTADO_ARCHIVO_CUSTODIA = 'Archivo y custodia';
	private static final String STATUS_EN_PROCESO = 'En proceso';
	private static final Integer TEXTO_MAXIMO = 1000;
	private static final Set<String> EXTENSIONES = new Set<String>{ 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png' };

	private static final String URL_REGISTRO_INMOBILIARIO = 'https://servicios.ri.gob.do/ConsultaDeExpedientes';
	private static final String URL_SEGM = 'https://app.segm.gob.do/#/login';
	private static final String URL_DGII = 'https://dgii.gov.do/herramientas/consultas/Paginas/default.aspx';

	private static final Set<String> ETAPAS_OFICIAL = new Set<String>{ ETAPA_DEVUELTA_OFICIAL, ETAPA_PENDIENTE_MATRICULA };
	private static final Set<String> ETAPAS_SIN_ACTOR = new Set<String>{ ETAPA_EN_DESEMBOLSO, ETAPA_COMPLETADA };

	private static final Map<String, Area> AREAS_POR_ETAPA = new Map<String, Area>{
		ETAPA_SOLICITUD_CHEQUE => new Area(
			'Ejecución de Operaciones',
			'FSC_ColaOperaciones',
			'FSC_PS_EjecucionOperaciones',
			'FSC_CP_EjecucionOperaciones'
		),
		ETAPA_MANTENIMIENTO => new Area(
			'Mantenimiento de Operaciones',
			'FSC_ColaMantenimientoOperaciones',
			'FSC_PS_MantenimientoOperaciones',
			'FSC_CP_MantenimientoOperaciones'
		),
		ETAPA_CUSTODIA => new Area('Custodia', 'FSC_Cola_Archivo_y_custodia_de_valores', 'FSC_PS_Archivo_Custodia_Valores', 'FSC_CP_Archivo_Custodia_Valores'),
		ETAPA_CDD => new Area('CDD', 'FSC_ColaCDD', 'FSC_PS_CDD', 'FSC_CP_CDD')
	};

	// En pruebas reemplaza FeatureManagement: los usuarios de prueba no pueden recibir permission sets en todos los ambientes.
	@TestVisible
	private static Set<String> permisosEnPrueba;

	// ===== Trigger =====

	// Inicia el proceso al entrar a Formalización y retoma la etapa pendiente cuando el desembolso termina.
	public static void encaminar(List<ResidentialLoanApplication> nuevas, Map<Id, ResidentialLoanApplication> anteriores) {
		if (nuevas == null || anteriores == null) {
			return;
		}
		for (ResidentialLoanApplication rla : nuevas) {
			ResidentialLoanApplication anterior = anteriores.get(rla.Id);
			if (anterior == null || rla.FSC_Subestado__c == anterior.FSC_Subestado__c) {
				continue;
			}
			if (rla.FSC_Subestado__c == SUBESTADO_FORMALIZACION && String.isBlank(rla.FSC_EtapaFormalizacion__c)) {
				rla.FSC_EtapaFormalizacion__c = ETAPA_REVISION;
			} else if (rla.FSC_Subestado__c == SUBESTADO_ARCHIVO_CUSTODIA && rla.FSC_EtapaFormalizacion__c == ETAPA_EN_DESEMBOLSO) {
				rla.FSC_DesembolsoFormalizacion__c = true;
				rla.FSC_Subestado__c = SUBESTADO_FORMALIZACION;
				rla.FSC_EtapaFormalizacion__c = String.isBlank(rla.FSC_EtapaFormalizacionRetorno__c)
					? ETAPA_REVISION
					: rla.FSC_EtapaFormalizacionRetorno__c;
				rla.FSC_EtapaFormalizacionRetorno__c = null;
			}
		}
	}

	// Los responsables del proceso solo leen la solicitud; el lookup no la comparte por sí mismo.
	public static void compartir(List<ResidentialLoanApplication> nuevas, Map<Id, ResidentialLoanApplication> anteriores) {
		if (nuevas == null) {
			return;
		}
		List<ResidentialLoanApplicationShare> accesos = new List<ResidentialLoanApplicationShare>();
		Set<Id> usuarios = new Set<Id>();
		Map<Id, Set<Id>> destinatariosPorSolicitud = new Map<Id, Set<Id>>();
		for (ResidentialLoanApplication rla : nuevas) {
			ResidentialLoanApplication anterior = anteriores?.get(rla.Id);
			Set<Id> destinatarios = new Set<Id>();
			if (anterior == null || anterior.FSC_ResponsableAreaFormalizacion__c != rla.FSC_ResponsableAreaFormalizacion__c) {
				destinatarios.add(rla.FSC_ResponsableAreaFormalizacion__c);
			}
			if (anterior == null || anterior.FSC_UsuarioFormalizacion__c != rla.FSC_UsuarioFormalizacion__c) {
				destinatarios.add(rla.FSC_UsuarioFormalizacion__c);
			}
			destinatarios.remove(null);
			destinatarios.remove(rla.OwnerId);
			if (!destinatarios.isEmpty()) {
				destinatariosPorSolicitud.put(rla.Id, destinatarios);
				usuarios.addAll(destinatarios);
			}
		}
		if (destinatariosPorSolicitud.isEmpty()) {
			return;
		}

		Set<Id> solicitudesIds = destinatariosPorSolicitud.keySet();
		Set<String> existentes = new Set<String>();
		for (ResidentialLoanApplicationShare acceso : [
			SELECT ParentId, UserOrGroupId
			FROM ResidentialLoanApplicationShare
			WHERE ParentId IN :solicitudesIds AND UserOrGroupId IN :usuarios
		]) {
			existentes.add(acceso.ParentId + ':' + acceso.UserOrGroupId);
		}
		Map<Id, User> activos = new Map<Id, User>([SELECT Id FROM User WHERE Id IN :usuarios AND IsActive = TRUE]);
		for (Id solicitudId : solicitudesIds) {
			for (Id usuarioId : destinatariosPorSolicitud.get(solicitudId)) {
				if (existentes.contains(solicitudId + ':' + usuarioId) || !activos.containsKey(usuarioId)) {
					continue;
				}
				accesos.add(new ResidentialLoanApplicationShare(ParentId = solicitudId, UserOrGroupId = usuarioId, AccessLevel = 'Read', RowCause = 'Manual'));
			}
		}
		if (!accesos.isEmpty()) {
			Database.insert(accesos, false);
		}
	}

	// ===== Contexto =====

	public static Contexto obtenerContexto(Id solicitudId) {
		ResidentialLoanApplication rla = consultarSolicitud(solicitudId);
		Contexto contexto = new Contexto();
		contexto.etapa = rla.FSC_EtapaFormalizacion__c;
		contexto.visible = !String.isBlank(rla.FSC_EtapaFormalizacion__c);
		if (!contexto.visible) {
			return contexto;
		}

		FSC_Garantia__c garantia = consultarGarantiaPrincipal(solicitudId);
		String ruta = garantia == null ? null : FSC_CatalogoGarantiaService.getRutaFormalizacion(garantia.FSC_Clase_de_Garantia__c);
		Boolean desembolsado = estaDesembolsado(rla);

		contexto.subestado = rla.FSC_Subestado__c;
		contexto.ruta = ruta;
		contexto.rutaEtiqueta = etiquetaRuta(ruta);
		contexto.desembolsado = desembolsado;
		contexto.etapaRetorno = rla.FSC_EtapaFormalizacionRetorno__c;
		contexto.observacion = rla.FSC_ObservacionFormalizacion__c;
		contexto.garantia = garantia == null ? null : new GarantiaInfo(garantia);
		contexto.datosGarantia = datosGarantia(rla, garantia, ruta);
		contexto.responsable = nombreResponsable(rla);
		contexto.esActor = esActor(rla);
		contexto.mensaje = mensajeEtapa(rla, ruta, desembolsado);
		contexto.enlaces = enlacesEtapa(rla.FSC_EtapaFormalizacion__c, ruta);
		contexto.acciones = contexto.esActor && rla.Status == STATUS_EN_PROCESO
			? accionesDisponibles(rla, garantia, ruta, desembolsado)
			: new List<Accion>();
		Boolean actorFormalizacion = contexto.esActor && !ETAPAS_OFICIAL.contains(rla.FSC_EtapaFormalizacion__c) &&
			!AREAS_POR_ETAPA.containsKey(rla.FSC_EtapaFormalizacion__c);
		contexto.puedeGenerarInventario = actorFormalizacion && ruta == RUTA_HIPOTECARIA &&
			(rla.FSC_EtapaFormalizacion__c == ETAPA_PAGO_DGII || rla.FSC_EtapaFormalizacion__c == ETAPA_DEPOSITO_TITULOS);
		contexto.puedeGenerarAutorizacion = actorFormalizacion && ruta == RUTA_VEHICULO &&
			(rla.FSC_EtapaFormalizacion__c == ETAPA_OPOSICION_MATRICULA || rla.FSC_EtapaFormalizacion__c == ETAPA_MATRICULA_DGII);
		return contexto;
	}

	// ===== Acciones =====

	public static void ejecutar(Id solicitudId, String codigo, Map<String, Object> datos) {
		ResidentialLoanApplication rla = consultarSolicitud(solicitudId);
		if (rla.Status != STATUS_EN_PROCESO || String.isBlank(rla.FSC_EtapaFormalizacion__c)) {
			throw new AuraHandledException('La solicitud no tiene un proceso de formalización activo.');
		}
		if (!esActor(rla)) {
			throw new AuraHandledException('No tiene permiso para actuar en la etapa ' + rla.FSC_EtapaFormalizacion__c + '.');
		}
		FSC_Garantia__c garantia = consultarGarantiaPrincipal(solicitudId);
		String ruta = garantia == null ? null : FSC_CatalogoGarantiaService.getRutaFormalizacion(garantia.FSC_Clase_de_Garantia__c);
		Boolean desembolsado = estaDesembolsado(rla);
		Boolean permitida = false;
		for (Accion accion : accionesDisponibles(rla, garantia, ruta, desembolsado)) {
			permitida = permitida || accion.codigo == codigo;
		}
		if (!permitida) {
			throw new AuraHandledException('La acción no está disponible en la etapa ' + rla.FSC_EtapaFormalizacion__c + '. Actualice la página.');
		}

		Map<String, Object> entrada = datos == null ? new Map<String, Object>() : datos;
		ResidentialLoanApplication cambio = new ResidentialLoanApplication(Id = rla.Id);
		FSC_Garantia__c cambioGarantia = new FSC_Garantia__c(Id = garantia.Id);
		Boolean actualizaGarantia = false;
		String etapaActual = rla.FSC_EtapaFormalizacion__c;
		String comentario = texto(entrada, 'comentario', false, 'El comentario');

		switch on codigo {
			when 'CONTINUAR' {
				String modalidad = garantia.FSC_ModalidadFormalizacion__c;
				if (!desembolsado) {
					modalidad = texto(entrada, 'modalidad', true, 'La modalidad de formalización');
					if (!opcionesModalidad(ruta).contains(modalidad)) {
						throw new AuraHandledException('Seleccione una modalidad de formalización válida.');
					}
					cambioGarantia.FSC_ModalidadFormalizacion__c = modalidad;
					actualizaGarantia = true;
				}
				String siguiente = ruta == RUTA_HIPOTECARIA ? ETAPA_FIRMAS : ETAPA_SEGM;
				if (!desembolsado && modalidad == MODALIDAD_DESPUES) {
					enviarADesembolso(cambio, ETAPA_REVISION);
				} else {
					moverA(cambio, siguiente);
				}
			}
			when 'DEVOLVER_OFICIAL' {
				comentario = texto(entrada, 'comentario', true, 'El motivo de la devolución');
				moverA(cambio, ETAPA_DEVUELTA_OFICIAL);
				cambio.FSC_EtapaFormalizacionRetorno__c = etapaActual == ETAPA_MATRICULA_DGII ? ETAPA_OPOSICION_MATRICULA : etapaActual;
			}
			when 'REENVIAR_FORMALIZACION' {
				moverA(cambio, String.isBlank(rla.FSC_EtapaFormalizacionRetorno__c) ? ETAPA_REVISION : rla.FSC_EtapaFormalizacionRetorno__c);
				cambio.FSC_EtapaFormalizacionRetorno__c = null;
			}
			when 'FIRMAS_COMPLETADAS' {
				moverA(cambio, ETAPA_AUTORIZACION_DGII);
			}
			when 'ENVIAR_EJECUCION' {
				vincularArchivos(rla.Id, ids(entrada, 'archivos'), false);
				moverAArea(cambio, ETAPA_SOLICITUD_CHEQUE);
			}
			when 'CHEQUE_ANEXADO' {
				vincularArchivos(rla.Id, ids(entrada, 'archivos'), true);
				moverA(cambio, ETAPA_PAGO_DGII);
			}
			when 'IMPUESTOS_LIQUIDADOS' {
				Boolean continuarRegistro = desembolsado || texto(entrada, 'continuarRegistro', true, 'La respuesta') == RESPUESTA_SI;
				if (continuarRegistro) {
					moverA(cambio, ETAPA_DEPOSITO_TITULOS);
				} else {
					enviarADesembolso(cambio, ETAPA_DEPOSITO_TITULOS);
				}
			}
			when 'REGISTRAR_DEPOSITO' {
				cambioGarantia.FSC_NumeroExpedienteRegistroTitulos__c = texto(entrada, 'numeroExpedienteRegistroTitulos', true, 'El número de expediente');
				cambioGarantia.FSC_Fecha_Constitucion_Garantia__c = fecha(entrada, 'fechaConstitucion', true, 'La fecha de constitución');
				cambioGarantia.FSC_Garantia_Constituida__c = RESPUESTA_SI;
				actualizaGarantia = true;
				if (!desembolsado) {
					enviarADesembolso(cambio, ETAPA_DEPOSITO_TITULOS);
				} else {
					cambio.FSC_EtapaFormalizacion__c = ETAPA_DEPOSITO_TITULOS;
				}
			}
			when 'REGISTRAR_SEGM' {
				vincularArchivos(rla.Id, ids(entrada, 'archivos'), false);
				cambioGarantia.FSC_Fecha_Constitucion_Garantia__c = fecha(entrada, 'fechaConstitucion', true, 'La fecha de constitución');
				cambioGarantia.FSC_Garantia_Constituida__c = RESPUESTA_SI;
				actualizaGarantia = true;
				if (ruta == RUTA_MOBILIARIA) {
					cambioGarantia.FSC_Fecha_Formalizacion_Hipotecaria__c = fecha(entrada, 'fechaFormalizacion', true, 'La fecha de formalización');
					if (desembolsado) {
						completar(cambio, true);
					} else {
						// La formalización concluye y la solicitud sigue su desembolso sin volver a esta etapa.
						completar(cambio, false);
						cambio.FSC_Subestado__c = SUBESTADO_DOC_DESEMBOLSO;
					}
				} else if (!desembolsado) {
					enviarADesembolso(cambio, ETAPA_PENDIENTE_MATRICULA);
				} else {
					moverA(cambio, ETAPA_PENDIENTE_MATRICULA);
				}
			}
			when 'ENVIAR_MATRICULA' {
				moverA(cambio, ETAPA_OPOSICION_MATRICULA);
			}
			when 'DEPOSITAR_MATRICULA' {
				cambioGarantia.FSC_NumeroExpedienteDGII__c = texto(entrada, 'numeroExpedienteDgii', true, 'El número de expediente de la DGII');
				actualizaGarantia = true;
				moverA(cambio, ETAPA_MATRICULA_DGII);
			}
			when 'DISPONIBLE_ENTREGA' {
				moverA(cambio, ETAPA_DISPONIBLE_ENTREGA);
			}
			when 'ENVIAR_RETIRO' {
				moverA(cambio, ETAPA_EN_RETIRO);
			}
			when 'REGISTRAR_RETIRO' {
				vincularArchivos(rla.Id, ids(entrada, 'archivos'), false);
				cambioGarantia.FSC_Fecha_Formalizacion_Hipotecaria__c = fecha(entrada, 'fechaFormalizacion', true, 'La fecha de formalización');
				if (ruta == RUTA_HIPOTECARIA) {
					cambioGarantia.FSC_Titulo_Registrado__c = RESPUESTA_SI;
				}
				actualizaGarantia = true;
				moverAArea(cambio, ETAPA_MANTENIMIENTO);
			}
			when 'FECHA_REGISTRADA' {
				moverA(cambio, ETAPA_ENVIO_CUSTODIA);
			}
			when 'ENVIAR_CUSTODIA' {
				moverAArea(cambio, ETAPA_CUSTODIA);
			}
			when 'ACUSAR_RECIBO' {
				moverAArea(cambio, ETAPA_CDD);
			}
			when 'DIGITALIZACION_COMPLETADA' {
				completar(cambio, desembolsado);
			}
		}

		if (!String.isBlank(comentario)) {
			cambio.FSC_ObservacionFormalizacion__c = '[' + etapaActual + '] ' + UserInfo.getName() + ': ' + comentario;
		}
		if (actualizaGarantia) {
			update cambioGarantia;
		}
		update cambio;
	}

	@TestVisible
	private static List<Accion> accionesDisponibles(ResidentialLoanApplication rla, FSC_Garantia__c garantia, String ruta, Boolean desembolsado) {
		List<Accion> acciones = new List<Accion>();
		if (garantia == null || ruta == null) {
			return acciones;
		}
		Accion devolver = new Accion(ACCION_DEVOLVER_OFICIAL, 'Devolver al oficial de negocio', 'neutral')
			.agregar(new Campo('comentario', 'Motivo de la devolución', 'textarea', true));

		switch on rla.FSC_EtapaFormalizacion__c {
			when 'Revisión de documentos' {
				Accion continuar = new Accion(ACCION_CONTINUAR, 'Documentación completa, continuar', 'brand');
				if (!desembolsado) {
					continuar.agregar(
						new Campo('modalidad', 'Modalidad de formalización', 'combobox', true)
							.conOpciones(opcionesModalidad(ruta))
							.conValor(garantia.FSC_ModalidadFormalizacion__c)
					);
				}
				acciones.add(continuar);
				acciones.add(devolver);
			}
			when 'Devuelta al oficial' {
				acciones.add(
					new Accion(ACCION_REENVIAR_FORMALIZACION, 'Documentación completada, reenviar a Formalización', 'brand')
						.agregar(new Campo('comentario', 'Comentario', 'textarea', false))
				);
			}
			when 'Recolección de firmas y notarización' {
				acciones.add(new Accion(ACCION_FIRMAS_COMPLETADAS, 'Expediente firmado y notarizado', 'brand'));
				acciones.add(devolver);
			}
			when 'Pendiente de autorización DGII' {
				acciones.add(
					new Accion(ACCION_ENVIAR_EJECUCION, 'Autorización DGII recibida, enviar a Ejecución de Operaciones', 'brand')
						.agregar(new Campo('archivos', 'Autorización de pago de la DGII (opcional si ya está en Archivos)', 'archivos', false))
						.agregar(new Campo('comentario', 'Comentario', 'textarea', false))
				);
				acciones.add(devolver);
			}
			when 'Solicitud de cheque' {
				acciones.add(
					new Accion(ACCION_CHEQUE_ANEXADO, 'Cheque anexado, devolver a Formalización', 'brand')
						.agregar(new Campo('archivos', 'Cheque de pago de impuestos', 'archivos', true))
						.agregar(new Campo('comentario', 'Comentario', 'textarea', false))
				);
			}
			when 'En proceso de pago en DGII' {
				Accion liquidados = new Accion(ACCION_IMPUESTOS_LIQUIDADOS, 'Impuestos liquidados', 'brand');
				if (!desembolsado) {
					liquidados.agregar(
						new Campo('continuarRegistro', '¿Continuar con el proceso de registro de la garantía?', 'combobox', true)
							.conOpciones(new List<String>{ RESPUESTA_SI, RESPUESTA_NO })
							.conValor(garantia.FSC_ModalidadFormalizacion__c == MODALIDAD_SOLO_IMPUESTO ? RESPUESTA_NO : RESPUESTA_SI)
							.conAyuda('Si responde No, la solicitud pasa a desembolso y vuelve a esta etapa luego de desembolsada.')
					);
				}
				acciones.add(liquidados);
				acciones.add(devolver);
			}
			when 'Depósito en Registro de Títulos' {
				Boolean depositoRegistrado = !String.isBlank(garantia.FSC_NumeroExpedienteRegistroTitulos__c);
				acciones.add(
					new Accion(
							ACCION_REGISTRAR_DEPOSITO,
							desembolsado ? (depositoRegistrado ? 'Actualizar datos del depósito' : 'Registrar depósito') : 'Registrar depósito y pasar a desembolso',
							depositoRegistrado ? 'neutral' : 'brand'
						)
						.agregar(
							new Campo('numeroExpedienteRegistroTitulos', 'N.º de expediente', 'text', true)
								.conValor(garantia.FSC_NumeroExpedienteRegistroTitulos__c)
						)
						.agregar(
							new Campo('fechaConstitucion', 'Fecha de constitución', 'date', true)
								.conValor(fechaTexto(garantia.FSC_Fecha_Constitucion_Garantia__c))
						)
				);
				if (desembolsado && depositoRegistrado) {
					acciones.add(new Accion(ACCION_DISPONIBLE_ENTREGA, 'Disponible para entrega', 'brand'));
				}
			}
			when 'Registro de aviso en SEGM' {
				Accion segm = new Accion(ACCION_REGISTRAR_SEGM, 'Aviso registrado en SEGM', 'brand')
					.agregar(new Campo('archivos', 'Aviso publicado en el SEGM', 'archivos', false))
					.agregar(
						new Campo('fechaConstitucion', 'Fecha de constitución', 'date', true).conValor(fechaTexto(garantia.FSC_Fecha_Constitucion_Garantia__c))
					);
				if (ruta == RUTA_MOBILIARIA) {
					segm.agregar(
						new Campo('fechaFormalizacion', 'Fecha de formalización', 'date', true)
							.conValor(fechaTexto(garantia.FSC_Fecha_Formalizacion_Hipotecaria__c))
					);
				}
				acciones.add(segm);
				acciones.add(devolver);
			}
			when 'Pendiente de matrícula original' {
				acciones.add(new Accion(ACCION_ENVIAR_MATRICULA, 'Matrícula original recibida, enviar a Formalización', 'brand'));
			}
			when 'Oposición de matrícula' {
				acciones.add(
					new Accion(ACCION_DEPOSITAR_MATRICULA, 'Matrícula depositada en DGII', 'brand')
						.agregar(new Campo('numeroExpedienteDgii', 'N.º de expediente DGII', 'text', true).conValor(garantia.FSC_NumeroExpedienteDGII__c))
				);
			}
			when 'Matrícula depositada en DGII' {
				acciones.add(new Accion(ACCION_DISPONIBLE_ENTREGA, 'Oposición lista para retiro', 'brand'));
				acciones.add(devolver);
			}
			when 'Disponible para entrega' {
				acciones.add(new Accion(ACCION_ENVIAR_RETIRO, 'Enviar a retirar', 'brand'));
			}
			when 'En retiro' {
				acciones.add(
					new Accion(ACCION_REGISTRAR_RETIRO, 'Documentos retirados, enviar a Mantenimiento de Operaciones', 'brand')
						.agregar(new Campo('archivos', 'Documentos escaneados (opcional si ya están en Archivos)', 'archivos', false))
						.agregar(
							new Campo('fechaFormalizacion', 'Fecha de formalización de la garantía', 'date', true)
								.conValor(fechaTexto(garantia.FSC_Fecha_Formalizacion_Hipotecaria__c))
						)
				);
			}
			when 'Mantenimiento de Operaciones' {
				acciones.add(new Accion(ACCION_FECHA_REGISTRADA, 'Fecha registrada en el sistema, devolver a Formalización', 'brand'));
			}
			when 'Pendiente envío a Custodia' {
				acciones.add(new Accion(ACCION_ENVIAR_CUSTODIA, 'Remitir originales a Custodia', 'brand'));
			}
			when 'En Custodia' {
				acciones.add(new Accion(ACCION_ACUSAR_RECIBO, 'Acusar recibo de originales', 'brand'));
			}
			when 'Digitalización CDD' {
				acciones.add(new Accion(ACCION_DIGITALIZACION_COMPLETADA, 'Digitalización completada', 'brand'));
			}
		}
		return acciones;
	}

	// ===== Actor de la etapa =====

	public static Boolean esActor(ResidentialLoanApplication rla) {
		String etapa = rla.FSC_EtapaFormalizacion__c;
		if (String.isBlank(etapa) || ETAPAS_SIN_ACTOR.contains(etapa)) {
			return false;
		}
		if (tienePermiso(PERMISO_ADMINISTRADOR)) {
			return true;
		}
		Id usuarioActual = UserInfo.getUserId();
		if (ETAPAS_OFICIAL.contains(etapa)) {
			return rla.OwnerId == usuarioActual;
		}
		Area area = AREAS_POR_ETAPA.get(etapa);
		if (area != null) {
			return tienePermiso(area.permiso) &&
				(rla.FSC_ResponsableAreaFormalizacion__c == null || rla.FSC_ResponsableAreaFormalizacion__c == usuarioActual);
		}
		// Sin usuario asignado cualquiera con el permiso puede formalizar.
		return tienePermiso(PERMISO_FORMALIZACION) && (rla.FSC_UsuarioFormalizacion__c == null || rla.FSC_UsuarioFormalizacion__c == usuarioActual);
	}

	public static void validarActorFormalizacion(Id solicitudId) {
		ResidentialLoanApplication rla = consultarSolicitud(solicitudId);
		if (
			rla.Status != STATUS_EN_PROCESO ||
			!esActor(rla) ||
			ETAPAS_OFICIAL.contains(rla.FSC_EtapaFormalizacion__c) ||
			AREAS_POR_ETAPA.containsKey(rla.FSC_EtapaFormalizacion__c)
		) {
			throw new AuraHandledException('Solo el usuario de Formalización asignado o un administrador pueden generar este documento.');
		}
	}

	public static Boolean tienePermiso(String permiso) {
		return permisosEnPrueba != null ? permisosEnPrueba.contains(permiso) : FeatureManagement.checkPermission(permiso);
	}

	// ===== Archivos =====

	// Los archivos se cargan primero en la biblioteca privada del usuario porque las áreas solo leen la solicitud.
	public static void vincularArchivos(Id solicitudId, List<Id> documentosIds, Boolean requeridos) {
		if (documentosIds == null || documentosIds.isEmpty()) {
			if (requeridos) {
				throw new AuraHandledException('Debe cargar al menos un archivo.');
			}
			return;
		}
		List<ContentDocumentLink> enlaces = new List<ContentDocumentLink>();
		for (ContentDocument documento : archivosPrivados(new Set<Id>(documentosIds))) {
			if (String.isBlank(documento.FileExtension) || !EXTENSIONES.contains(documento.FileExtension.toLowerCase())) {
				throw new AuraHandledException('Solo se permiten archivos Word, PDF, Excel, JPG y PNG.');
			}
			enlaces.add(new ContentDocumentLink(ContentDocumentId = documento.Id, LinkedEntityId = solicitudId, ShareType = 'V', Visibility = 'InternalUsers'));
		}
		insert enlaces;
	}

	// El PDF se crea en la biblioteca del usuario y se vincula sin sharing, igual que los archivos cargados.
	public static Id adjuntarDocumento(Id solicitudId, String titulo, Blob contenido) {
		String tituloSeguro = titulo.left(250);
		ContentVersion version = new ContentVersion(Title = tituloSeguro, PathOnClient = tituloSeguro + '.pdf', VersionData = contenido);
		insert version;
		Id documentoId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id].ContentDocumentId;
		insert new ContentDocumentLink(ContentDocumentId = documentoId, LinkedEntityId = solicitudId, ShareType = 'V', Visibility = 'InternalUsers');
		return documentoId;
	}

	public static void descartarArchivos(List<Id> documentosIds) {
		if (documentosIds == null || documentosIds.isEmpty()) {
			return;
		}
		delete archivosPrivados(new Set<Id>(documentosIds));
	}

	private static List<ContentDocument> archivosPrivados(Set<Id> documentosIds) {
		Id usuarioActual = UserInfo.getUserId();
		List<ContentDocument> documentos = [
			SELECT Id, FileExtension
			FROM ContentDocument
			WHERE Id IN :documentosIds AND OwnerId = :usuarioActual AND CreatedById = :usuarioActual
		];
		if (documentos.size() != documentosIds.size()) {
			throw new AuraHandledException('No se pudieron validar los archivos cargados.');
		}
		for (ContentDocumentLink enlace : [SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :documentosIds]) {
			if (enlace.LinkedEntityId != usuarioActual) {
				throw new AuraHandledException('Uno de los archivos ya está vinculado. Actualice la solicitud.');
			}
		}
		return documentos;
	}

	// ===== Transiciones =====

	private static void moverA(ResidentialLoanApplication cambio, String etapa) {
		cambio.FSC_EtapaFormalizacion__c = etapa;
		cambio.FSC_ResponsableAreaFormalizacion__c = null;
	}

	private static void moverAArea(ResidentialLoanApplication cambio, String etapa) {
		cambio.FSC_EtapaFormalizacion__c = etapa;
		cambio.FSC_ResponsableAreaFormalizacion__c = seleccionarResponsable(AREAS_POR_ETAPA.get(etapa));
	}

	private static void enviarADesembolso(ResidentialLoanApplication cambio, String etapaRetorno) {
		moverA(cambio, ETAPA_EN_DESEMBOLSO);
		cambio.FSC_EtapaFormalizacionRetorno__c = etapaRetorno;
		cambio.FSC_Subestado__c = SUBESTADO_DOC_DESEMBOLSO;
	}

	private static void completar(ResidentialLoanApplication cambio, Boolean desembolsado) {
		moverA(cambio, ETAPA_COMPLETADA);
		cambio.FSC_EtapaFormalizacionRetorno__c = null;
		if (desembolsado) {
			cambio.FSC_Subestado__c = SUBESTADO_ARCHIVO_CUSTODIA;
		}
	}

	// Usuario activo al azar de la cola del área que además tenga el permission set del área.
	@TestVisible
	private static Id seleccionarResponsable(Area area) {
		List<Group> colas = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :area.cola LIMIT 1];
		if (colas.isEmpty()) {
			return null;
		}
		Set<Id> miembros = FSC_RandomQueueApproverAction.collectCandidatePrincipalIds(colas[0].Id);
		Set<Id> habilitados = new Set<Id>();
		for (PermissionSetAssignment asignacion : [
			SELECT AssigneeId
			FROM PermissionSetAssignment
			WHERE
				PermissionSet.Name = :area.permissionSet
				AND AssigneeId IN :miembros
				AND Assignee.IsActive = TRUE
				AND (ExpirationDate = NULL
				OR ExpirationDate > :System.now())
		]) {
			habilitados.add(asignacion.AssigneeId);
		}
		if (habilitados.isEmpty()) {
			return null;
		}
		List<Id> candidatos = new List<Id>(habilitados);
		return candidatos[Math.abs(Math.mod(Crypto.getRandomInteger(), candidatos.size()))];
	}

	// ===== Consultas y utilidades =====

	private static ResidentialLoanApplication consultarSolicitud(Id solicitudId) {
		if (solicitudId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		List<ResidentialLoanApplication> solicitudes = [
			SELECT
				Id,
				Name,
				OwnerId,
				Owner.Name,
				Status,
				FSC_Subestado__c,
				FSC_EtapaFormalizacion__c,
				FSC_EtapaFormalizacionRetorno__c,
				FSC_ObservacionFormalizacion__c,
				FSC_ResponsableAreaFormalizacion__c,
				FSC_ResponsableAreaFormalizacion__r.Name,
				FSC_UsuarioFormalizacion__c,
				FSC_UsuarioFormalizacion__r.Name,
				FSC_DesembolsoFormalizacion__c,
				FSC_Desembolso_Realizado__c,
				Account.Name
			FROM ResidentialLoanApplication
			WHERE Id = :solicitudId
			LIMIT 1
		];
		if (solicitudes.isEmpty()) {
			throw new AuraHandledException('No se encontró la solicitud.');
		}
		return solicitudes[0];
	}

	// Un expediente por solicitud: se formaliza la primera garantía que tenga ruta de formalización.
	public static FSC_Garantia__c consultarGarantiaPrincipal(Id solicitudId) {
		for (FSC_Garantia__c garantia : [
			SELECT
				Id,
				Name,
				FSC_Clase_de_Garantia__c,
				FSC_Tipo_de_Garantia__c,
				FSC_Descripcion_de_la_Garantia__c,
				FSC_ModalidadFormalizacion__c,
				FSC_NumeroExpedienteRegistroTitulos__c,
				FSC_NumeroExpedienteDGII__c,
				FSC_Fecha_Constitucion_Garantia__c,
				FSC_Fecha_Formalizacion_Hipotecaria__c,
				FSC_Garantia_Constituida__c,
				FSC_Titulo_Registrado__c,
				FSC_Numero_Titulo__c,
				FSC_Ubicacion__c,
				FSC_Tipo_Vehiculo__c,
				FSC_Marca_Vehiculo__c,
				FSC_Modelo_Vehiculo__c,
				FSC_Ano_Vehiculo__c,
				FSC_Color_Vehiculo__c,
				FSC_Numero_Chasis_Vehiculo__c,
				FSC_Numero_Placa_Vehiculo__c,
				FSC_Serial_Motor_Vehiculo__c,
				FSC_Numero_Matricula__c,
				FSC_Numero_Certificado_Deposito__c,
				FSC_Emisor_Certificado_Deposito__c,
				FSC_Monto_Certificado_Deposito__c,
				FSC_Valor_Tasado__c
			FROM FSC_Garantia__c
			WHERE FSC_Residential_Loan_Application__c = :solicitudId
			ORDER BY CreatedDate, Id
		]) {
			if (FSC_CatalogoGarantiaService.getRutaFormalizacion(garantia.FSC_Clase_de_Garantia__c) != null) {
				return garantia;
			}
		}
		return null;
	}

	private static Boolean estaDesembolsado(ResidentialLoanApplication rla) {
		return rla.FSC_DesembolsoFormalizacion__c == true || rla.FSC_Desembolso_Realizado__c == true;
	}

	public static List<String> opcionesModalidad(String ruta) {
		return ruta == RUTA_HIPOTECARIA
			? new List<String>{ MODALIDAD_ANTES, MODALIDAD_SOLO_IMPUESTO, MODALIDAD_DESPUES }
			: new List<String>{ MODALIDAD_ANTES, MODALIDAD_DESPUES };
	}

	private static String etiquetaRuta(String ruta) {
		if (ruta == RUTA_HIPOTECARIA) {
			return 'Garantía hipotecaria';
		}
		if (ruta == RUTA_VEHICULO) {
			return 'Garantía de vehículo';
		}
		if (ruta == RUTA_MOBILIARIA) {
			return 'Garantía mobiliaria (SEGM)';
		}
		return null;
	}

	private static String nombreResponsable(ResidentialLoanApplication rla) {
		String etapa = rla.FSC_EtapaFormalizacion__c;
		if (ETAPAS_SIN_ACTOR.contains(etapa)) {
			return null;
		}
		if (ETAPAS_OFICIAL.contains(etapa)) {
			return 'Oficial de negocio: ' + rla.Owner?.Name;
		}
		Area area = AREAS_POR_ETAPA.get(etapa);
		if (area != null) {
			return area.nombre + ': ' + (rla.FSC_ResponsableAreaFormalizacion__c == null ? 'sin asignar' : rla.FSC_ResponsableAreaFormalizacion__r?.Name);
		}
		return 'Formalización: ' + (rla.FSC_UsuarioFormalizacion__c == null ? 'sin asignar' : rla.FSC_UsuarioFormalizacion__r?.Name);
	}

	@TestVisible
	private static String mensajeEtapa(ResidentialLoanApplication rla, String ruta, Boolean desembolsado) {
		switch on rla.FSC_EtapaFormalizacion__c {
			when 'Revisión de documentos' {
				return desembolsado
					? 'El crédito ya fue desembolsado. Revise la documentación y continúe con la formalización de la garantía.'
					: 'Revise el expediente. Si la documentación está incompleta devuélvalo al oficial; si está completa defina la modalidad de formalización.';
			}
			when 'Devuelta al oficial' {
				return 'Formalización devolvió la solicitud por documentación incompleta. Complete lo indicado en la observación y reenvíela.';
			}
			when 'Recolección de firmas y notarización' {
				return 'El expediente se encuentra en recolección de firmas y notarización.';
			}
			when 'Pendiente de autorización DGII' {
				return 'Digitalice el expediente, cárguelo en Archivos y solicite por correo la autorización de pago a la DGII. Al recibirla, envíe la solicitud a Ejecución de Operaciones.';
			}
			when 'Solicitud de cheque' {
				return 'Solicite el cheque para el pago de impuestos, cárguelo y entregue el original a Formalización.';
			}
			when 'En proceso de pago en DGII' {
				return 'El expediente se encuentra en proceso de pago en la DGII. Si la DGII no recibe el pago por un tema del cliente, devuelva la solicitud al oficial con el detalle.';
			}
			when 'Depósito en Registro de Títulos' {
				return desembolsado
					? 'Genere el inventario, deposite el expediente en el Registro de Títulos y registre el número de expediente y la fecha de constitución. Cuando esté disponible para entrega, indíquelo.'
					: 'Genere el inventario, deposite el expediente en el Registro de Títulos y registre el número de expediente y la fecha de constitución; luego la solicitud pasa a desembolso.';
			}
			when 'Registro de aviso en SEGM' {
				return 'Registre el aviso en el portal del SEGM con los datos de la garantía, descargue la publicación y regístrela aquí.';
			}
			when 'En desembolso' {
				return 'La solicitud está en desembolso. Al desembolsarse vuelve a Formalización en la etapa: ' + rla.FSC_EtapaFormalizacionRetorno__c + '.';
			}
			when 'Pendiente de matrícula original' {
				return 'Gestione con el cliente la matrícula original del vehículo y, al recibirla, envíela a Formalización.';
			}
			when 'Oposición de matrícula' {
				return 'Genere la autorización de oposición y entrega de matrícula, imprímala, fírmela y deposítela en la DGII.';
			}
			when 'Matrícula depositada en DGII' {
				return 'Matrícula depositada en la DGII. Consulte el estado en el portal; si la DGII no realiza la oposición por un tema del cliente, devuelva la solicitud al oficial.';
			}
			when 'Disponible para entrega' {
				return 'El expediente está disponible para entrega. Indique cuando se envíe a retirar.';
			}
			when 'En retiro' {
				return 'Expediente en retiro. Al retirarlo, escanee los documentos y registre la fecha de formalización.';
			}
			when 'Mantenimiento de Operaciones' {
				return 'Registre en el sistema la fecha de formalización de la garantía y devuelva la solicitud a Formalización.';
			}
			when 'Pendiente envío a Custodia' {
				return 'Remita los originales a Custodia.';
			}
			when 'En Custodia' {
				return 'Confirme la recepción de los originales de la garantía.';
			}
			when 'Digitalización CDD' {
				return 'Digitalice los documentos en el expediente del cliente.';
			}
			when 'Completada' {
				return 'La formalización de la garantía está completada.';
			}
		}
		return null;
	}

	@TestVisible
	private static List<Enlace> enlacesEtapa(String etapa, String ruta) {
		List<Enlace> enlaces = new List<Enlace>();
		if (etapa == ETAPA_SEGM) {
			enlaces.add(new Enlace('Abrir portal del SEGM', URL_SEGM));
		}
		if (ruta == RUTA_HIPOTECARIA && (etapa == ETAPA_DEPOSITO_TITULOS || etapa == ETAPA_DISPONIBLE_ENTREGA)) {
			enlaces.add(new Enlace('Consultar expediente en el Registro Inmobiliario', URL_REGISTRO_INMOBILIARIO));
		}
		if (ruta == RUTA_VEHICULO && (etapa == ETAPA_MATRICULA_DGII || etapa == ETAPA_DISPONIBLE_ENTREGA)) {
			enlaces.add(new Enlace('Consultar en el portal de la DGII', URL_DGII));
		}
		return enlaces;
	}

	// Datos de apoyo para completar formularios externos (aviso SEGM, oposición).
	private static List<Dato> datosGarantia(ResidentialLoanApplication rla, FSC_Garantia__c garantia, String ruta) {
		List<Dato> datos = new List<Dato>();
		if (garantia == null) {
			return datos;
		}
		agregarDato(datos, 'Deudor', rla.Account?.Name);
		agregarDato(datos, 'Clase de garantía', garantia.FSC_Clase_de_Garantia__c);
		agregarDato(datos, 'Tipo de garantía', garantia.FSC_Tipo_de_Garantia__c);
		if (ruta == RUTA_HIPOTECARIA) {
			agregarDato(datos, 'N.º de título', garantia.FSC_Numero_Titulo__c);
			agregarDato(datos, 'Ubicación', garantia.FSC_Ubicacion__c);
			agregarDato(datos, 'N.º expediente Registro de Títulos', garantia.FSC_NumeroExpedienteRegistroTitulos__c);
		} else if (ruta == RUTA_VEHICULO) {
			agregarDato(datos, 'Tipo de vehículo', garantia.FSC_Tipo_Vehiculo__c);
			agregarDato(datos, 'Marca', garantia.FSC_Marca_Vehiculo__c);
			agregarDato(datos, 'Modelo', garantia.FSC_Modelo_Vehiculo__c);
			agregarDato(datos, 'Año', garantia.FSC_Ano_Vehiculo__c == null ? null : String.valueOf(garantia.FSC_Ano_Vehiculo__c.intValue()));
			agregarDato(datos, 'Color', garantia.FSC_Color_Vehiculo__c);
			agregarDato(datos, 'Chasis', garantia.FSC_Numero_Chasis_Vehiculo__c);
			agregarDato(datos, 'Placa', garantia.FSC_Numero_Placa_Vehiculo__c);
			agregarDato(datos, 'Motor o serie', garantia.FSC_Serial_Motor_Vehiculo__c);
			agregarDato(datos, 'Matrícula', garantia.FSC_Numero_Matricula__c);
			agregarDato(datos, 'N.º expediente DGII', garantia.FSC_NumeroExpedienteDGII__c);
		} else {
			agregarDato(datos, 'N.º de certificado', garantia.FSC_Numero_Certificado_Deposito__c);
			agregarDato(datos, 'Emisor', garantia.FSC_Emisor_Certificado_Deposito__c);
			agregarDato(
				datos,
				'Monto del certificado',
				garantia.FSC_Monto_Certificado_Deposito__c == null ? null : FSC_ContratoFormatoService.formatearMonto(garantia.FSC_Monto_Certificado_Deposito__c)
			);
			agregarDato(datos, 'Valor tasado', garantia.FSC_Valor_Tasado__c == null ? null : FSC_ContratoFormatoService.formatearMonto(garantia.FSC_Valor_Tasado__c));
		}
		agregarDato(datos, 'Descripción', garantia.FSC_Descripcion_de_la_Garantia__c);
		return datos;
	}

	private static void agregarDato(List<Dato> datos, String etiqueta, String valor) {
		if (!String.isBlank(valor)) {
			datos.add(new Dato(etiqueta, valor));
		}
	}

	private static String texto(Map<String, Object> datos, String clave, Boolean requerido, String nombre) {
		Object valor = datos.get(clave);
		String resultado = valor == null ? null : String.valueOf(valor).trim();
		if (String.isBlank(resultado)) {
			if (requerido) {
				throw new AuraHandledException(nombre + ' es requerido.');
			}
			return null;
		}
		if (resultado.length() > TEXTO_MAXIMO) {
			throw new AuraHandledException(nombre + ' no puede superar 1.000 caracteres.');
		}
		return resultado;
	}

	private static Date fecha(Map<String, Object> datos, String clave, Boolean requerido, String nombre) {
		String valor = texto(datos, clave, requerido, nombre);
		if (valor == null) {
			return null;
		}
		Date resultado;
		try {
			resultado = Date.valueOf(valor.left(10));
		} catch (Exception e) {
			throw new AuraHandledException(nombre + ' no es válida.');
		}
		if (resultado > Date.today()) {
			throw new AuraHandledException(nombre + ' no puede ser posterior a la fecha actual.');
		}
		return resultado;
	}

	private static String fechaTexto(Date valor) {
		return valor == null ? null : String.valueOf(valor);
	}

	private static List<Id> ids(Map<String, Object> datos, String clave) {
		List<Id> resultado = new List<Id>();
		Object valor = datos.get(clave);
		if (valor instanceof List<Object>) {
			for (Object item : (List<Object>) valor) {
				if (item != null) {
					resultado.add(Id.valueOf(String.valueOf(item)));
				}
			}
		}
		return resultado;
	}

	// ===== Tipos =====

	private class Area {
		String nombre;
		String cola;
		String permissionSet;
		String permiso;

		Area(String nombre, String cola, String permissionSet, String permiso) {
			this.nombre = nombre;
			this.cola = cola;
			this.permissionSet = permissionSet;
			this.permiso = permiso;
		}
	}

	public class Contexto {
		@AuraEnabled
		public Boolean visible = false;
		@AuraEnabled
		public String etapa;
		@AuraEnabled
		public String etapaRetorno;
		@AuraEnabled
		public String subestado;
		@AuraEnabled
		public String ruta;
		@AuraEnabled
		public String rutaEtiqueta;
		@AuraEnabled
		public Boolean desembolsado = false;
		@AuraEnabled
		public String observacion;
		@AuraEnabled
		public String responsable;
		@AuraEnabled
		public String mensaje;
		@AuraEnabled
		public Boolean esActor = false;
		@AuraEnabled
		public Boolean puedeGenerarInventario = false;
		@AuraEnabled
		public Boolean puedeGenerarAutorizacion = false;
		@AuraEnabled
		public GarantiaInfo garantia;
		@AuraEnabled
		public List<Dato> datosGarantia = new List<Dato>();
		@AuraEnabled
		public List<Enlace> enlaces = new List<Enlace>();
		@AuraEnabled
		public List<Accion> acciones = new List<Accion>();
	}

	public class GarantiaInfo {
		@AuraEnabled
		public Id id;
		@AuraEnabled
		public String nombre;
		@AuraEnabled
		public String clase;
		@AuraEnabled
		public String modalidad;
		@AuraEnabled
		public String numeroExpedienteRegistroTitulos;
		@AuraEnabled
		public String numeroExpedienteDgii;
		@AuraEnabled
		public Date fechaConstitucion;
		@AuraEnabled
		public Date fechaFormalizacion;

		GarantiaInfo(FSC_Garantia__c garantia) {
			this.id = garantia.Id;
			this.nombre = garantia.Name;
			this.clase = garantia.FSC_Clase_de_Garantia__c;
			this.modalidad = garantia.FSC_ModalidadFormalizacion__c;
			this.numeroExpedienteRegistroTitulos = garantia.FSC_NumeroExpedienteRegistroTitulos__c;
			this.numeroExpedienteDgii = garantia.FSC_NumeroExpedienteDGII__c;
			this.fechaConstitucion = garantia.FSC_Fecha_Constitucion_Garantia__c;
			this.fechaFormalizacion = garantia.FSC_Fecha_Formalizacion_Hipotecaria__c;
		}
	}

	public class Accion {
		@AuraEnabled
		public String codigo;
		@AuraEnabled
		public String etiqueta;
		@AuraEnabled
		public String variante;
		@AuraEnabled
		public List<Campo> campos = new List<Campo>();

		Accion(String codigo, String etiqueta, String variante) {
			this.codigo = codigo;
			this.etiqueta = etiqueta;
			this.variante = variante;
		}

		Accion agregar(Campo campo) {
			this.campos.add(campo);
			return this;
		}
	}

	public class Campo {
		@AuraEnabled
		public String nombre;
		@AuraEnabled
		public String etiqueta;
		@AuraEnabled
		public String tipo;
		@AuraEnabled
		public Boolean requerido;
		@AuraEnabled
		public String valor;
		@AuraEnabled
		public String ayuda;
		@AuraEnabled
		public List<Map<String, String>> opciones = new List<Map<String, String>>();

		Campo(String nombre, String etiqueta, String tipo, Boolean requerido) {
			this.nombre = nombre;
			this.etiqueta = etiqueta;
			this.tipo = tipo;
			this.requerido = requerido;
		}

		Campo conOpciones(List<String> valores) {
			for (String valor : valores) {
				this.opciones.add(new Map<String, String>{ 'label' => valor, 'value' => valor });
			}
			return this;
		}

		Campo conValor(String valor) {
			this.valor = valor;
			return this;
		}

		Campo conAyuda(String ayuda) {
			this.ayuda = ayuda;
			return this;
		}
	}

	public class Enlace {
		@AuraEnabled
		public String etiqueta;
		@AuraEnabled
		public String url;

		Enlace(String etiqueta, String url) {
			this.etiqueta = etiqueta;
			this.url = url;
		}
	}

	public class Dato {
		@AuraEnabled
		public String etiqueta;
		@AuraEnabled
		public String valor;

		Dato(String etiqueta, String valor) {
			this.etiqueta = etiqueta;
			this.valor = valor;
		}
	}
}