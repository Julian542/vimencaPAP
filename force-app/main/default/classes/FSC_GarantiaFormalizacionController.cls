public with sharing class FSC_GarantiaFormalizacionController {
	private static final String PERMISO_FORMALIZACION = 'FSC_CP_Formalizacion_Creditos';
	private static final String PERMISO_ADMINISTRADOR = 'FSC_CP_Administrador';
	private static final String GRUPO_HIPOTECARIO = 'real-estate';
	private static final String GRUPO_VEHICULO = 'vehicle';
	private static final Integer COMENTARIO_MAXIMO = 1000;
	private static final Set<String> SUBESTADOS_FORMALIZABLES = new Set<String>{
		FSC_GarantiaFormalizacionService.SUBESTADO_FORMALIZACION,
		FSC_GarantiaFormalizacionService.SUBESTADO_DOCUMENTACION_DESEMBOLSO,
		'Pendiente planilla de desembolso',
		'Creación de crédito',
		'Desembolso',
		'Archivo y custodia'
	};

	@TestVisible
	private static Boolean omitirValidacionPermisoEnPrueba = false;
	@TestVisible
	private static Boolean ignorarAdministradorEnPrueba = false;

	@AuraEnabled(cacheable=true)
	public static FormalizacionContext getContext(Id residentialLoanApplicationId) {
		validarEntradaYPermiso(residentialLoanApplicationId);
		ResidentialLoanApplication solicitud = consultarSolicitud(residentialLoanApplicationId);

		FormalizacionContext contexto = new FormalizacionContext();
		contexto.subestado = solicitud.FSC_Subestado__c;
		contexto.garantias = new List<GarantiaItem>();

		for (FSC_Garantia__c garantia : consultarGarantias(residentialLoanApplicationId)) {
			String grupo = FSC_GarantiaFormalizacionService.obtenerGrupo(garantia.FSC_Clase_de_Garantia__c);
			if (grupo != GRUPO_HIPOTECARIO && grupo != GRUPO_VEHICULO) {
				continue;
			}

			GarantiaItem item = new GarantiaItem();
			item.id = garantia.Id;
			item.nombre = garantia.Name;
			item.claseGarantia = garantia.FSC_Clase_de_Garantia__c;
			item.esHipotecaria = grupo == GRUPO_HIPOTECARIO;
			item.esVehiculo = grupo == GRUPO_VEHICULO;
			item.tituloRegistrado = garantia.FSC_Titulo_Registrado__c;
			item.fechaFormalizacionHipotecaria = garantia.FSC_Fecha_Formalizacion_Hipotecaria__c;
			item.garantiaConstituida = garantia.FSC_Garantia_Constituida__c;
			item.comentarioVehiculo = garantia.FSC_Comentario_Formalizacion_Vehiculo__c;
			item.fechaConstitucionGarantia = garantia.FSC_Fecha_Constitucion_Garantia__c;
			item.formalizada = FSC_GarantiaFormalizacionService.estaFormalizada(garantia);
			contexto.garantias.add(item);
		}

		contexto.tieneGarantiasAplicables = !contexto.garantias.isEmpty();
		contexto.todasFormalizadas = contexto.tieneGarantiasAplicables;
		contexto.cantidadPendientes = 0;
		for (GarantiaItem item : contexto.garantias) {
			if (!item.formalizada) {
				contexto.todasFormalizadas = false;
				contexto.cantidadPendientes++;
			}
		}

		return contexto;
	}

	@AuraEnabled
	public static FormalizacionContext desembolsarSinRegistrar(Id residentialLoanApplicationId) {
		validarEntradaYPermiso(residentialLoanApplicationId);
		FormalizacionContext contextoInicial = getContext(residentialLoanApplicationId);
		if (
			contextoInicial.subestado != FSC_GarantiaFormalizacionService.SUBESTADO_FORMALIZACION ||
			contextoInicial.tieneGarantiasAplicables != true
		) {
			throw new AuraHandledException('La solicitud no está disponible para desembolsar sin registrar garantías.');
		}
		actualizarSubestado(residentialLoanApplicationId, FSC_GarantiaFormalizacionService.SUBESTADO_DOCUMENTACION_DESEMBOLSO);
		return getContext(residentialLoanApplicationId);
	}

	@AuraEnabled
	public static FormalizacionContext guardarFormalizacion(Id residentialLoanApplicationId, List<GarantiaInput> garantias) {
		validarEntradaYPermiso(residentialLoanApplicationId);
		String subestadoInicial = consultarSolicitud(residentialLoanApplicationId).FSC_Subestado__c;
		if (!SUBESTADOS_FORMALIZABLES.contains(subestadoInicial)) {
			throw new AuraHandledException('La solicitud no está en un subestado habilitado para formalizar garantías.');
		}
		Map<Id, GarantiaInput> entradaPorId = indexarEntradas(garantias);
		List<FSC_Garantia__c> garantiasConsultadas = consultarGarantias(residentialLoanApplicationId);
		List<FSC_Garantia__c> garantiasParaActualizar = prepararActualizaciones(garantiasConsultadas, entradaPorId);
		if (garantiasParaActualizar.isEmpty()) {
			throw new AuraHandledException('La solicitud no tiene garantías hipotecarias o vehiculares para formalizar.');
		}
		if (entradaPorId.size() != garantiasParaActualizar.size()) {
			throw new AuraHandledException('La solicitud de formalización contiene garantías que no corresponden a este crédito.');
		}

		try {
			new EscrituraFormalizacion().actualizar(garantiasParaActualizar);
		} catch (DmlException exceptionDetails) {
			throw new AuraHandledException('No se pudieron guardar los datos de formalización. Verifique sus permisos y los valores ingresados.');
		}

		if (subestadoInicial == FSC_GarantiaFormalizacionService.SUBESTADO_FORMALIZACION) {
			actualizarSubestado(residentialLoanApplicationId, FSC_GarantiaFormalizacionService.SUBESTADO_DOCUMENTACION_DESEMBOLSO);
		}
		return getContext(residentialLoanApplicationId);
	}

	private static ResidentialLoanApplication consultarSolicitud(Id residentialLoanApplicationId) {
		List<ResidentialLoanApplication> solicitudes = [
			SELECT Id, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			WITH USER_MODE
			LIMIT 1
		];
		if (solicitudes.isEmpty()) {
			throw new AuraHandledException('No se encontró la solicitud o no tiene acceso a ella.');
		}
		return solicitudes[0];
	}

	private static Map<Id, GarantiaInput> indexarEntradas(List<GarantiaInput> garantias) {
		if (garantias == null || garantias.isEmpty()) {
			throw new AuraHandledException('Debe completar al menos una garantía.');
		}

		Map<Id, GarantiaInput> entradaPorId = new Map<Id, GarantiaInput>();
		for (GarantiaInput entrada : garantias) {
			if (entrada == null || entrada.id == null) {
				throw new AuraHandledException('Cada garantía debe incluir un identificador válido.');
			}
			entradaPorId.put(entrada.id, entrada);
		}
		return entradaPorId;
	}

	private static List<FSC_Garantia__c> prepararActualizaciones(List<FSC_Garantia__c> garantiasConsultadas, Map<Id, GarantiaInput> entradaPorId) {
		List<FSC_Garantia__c> garantiasParaActualizar = new List<FSC_Garantia__c>();
		for (FSC_Garantia__c garantia : garantiasConsultadas) {
			String grupo = FSC_GarantiaFormalizacionService.obtenerGrupo(garantia.FSC_Clase_de_Garantia__c);
			if (grupo != GRUPO_HIPOTECARIO && grupo != GRUPO_VEHICULO) {
				continue;
			}
			GarantiaInput entrada = entradaPorId.get(garantia.Id);
			if (entrada == null) {
				throw new AuraHandledException('Debe completar los datos de todas las garantías hipotecarias y vehiculares.');
			}

			FSC_Garantia__c actualizacion = new FSC_Garantia__c(Id = garantia.Id);
			if (grupo == GRUPO_HIPOTECARIO) {
				aplicarDatosHipotecarios(garantia, actualizacion, entrada);
			} else {
				aplicarDatosVehiculo(garantia, actualizacion, entrada);
			}
			garantiasParaActualizar.add(actualizacion);
		}
		return garantiasParaActualizar;
	}

	private static List<FSC_Garantia__c> consultarGarantias(Id residentialLoanApplicationId) {
		return [
			SELECT
				Id,
				Name,
				FSC_Clase_de_Garantia__c,
				FSC_Titulo_Registrado__c,
				FSC_Fecha_Formalizacion_Hipotecaria__c,
				FSC_Garantia_Constituida__c,
				FSC_Comentario_Formalizacion_Vehiculo__c,
				FSC_Fecha_Constitucion_Garantia__c
			FROM FSC_Garantia__c
			WHERE FSC_Residential_Loan_Application__c = :residentialLoanApplicationId
			WITH USER_MODE
			ORDER BY CreatedDate, Id
		];
	}

	private static void aplicarDatosHipotecarios(FSC_Garantia__c garantia, FSC_Garantia__c actualizacion, GarantiaInput entrada) {
		validarRespuesta(entrada.tituloRegistrado, 'Debe indicar si cada título hipotecario está registrado.');
		Boolean tituloRegistrado = entrada.tituloRegistrado == FSC_GarantiaFormalizacionService.RESPUESTA_SI;
		validarFechaNoFutura(entrada.fechaFormalizacionHipotecaria, 'La fecha de formalización no puede ser posterior a la fecha actual.');
		if (tituloRegistrado && entrada.fechaFormalizacionHipotecaria == null) {
			throw new AuraHandledException('La fecha de formalización es requerida para cada título hipotecario registrado.');
		}

		actualizacion.FSC_Titulo_Registrado__c = entrada.tituloRegistrado;
		actualizacion.FSC_Fecha_Formalizacion_Hipotecaria__c = tituloRegistrado ? entrada.fechaFormalizacionHipotecaria : null;
		garantia.FSC_Titulo_Registrado__c = actualizacion.FSC_Titulo_Registrado__c;
		garantia.FSC_Fecha_Formalizacion_Hipotecaria__c = actualizacion.FSC_Fecha_Formalizacion_Hipotecaria__c;
	}

	private static void aplicarDatosVehiculo(FSC_Garantia__c garantia, FSC_Garantia__c actualizacion, GarantiaInput entrada) {
		validarRespuesta(entrada.garantiaConstituida, 'Debe indicar si cada garantía vehicular está constituida.');
		String comentario = validarComentarioVehiculo(entrada.comentarioVehiculo);
		validarFechaConstitucionVehiculo(entrada.garantiaConstituida, entrada.fechaConstitucionGarantia);

		actualizacion.FSC_Garantia_Constituida__c = entrada.garantiaConstituida;
		actualizacion.FSC_Comentario_Formalizacion_Vehiculo__c = comentario;
		actualizacion.FSC_Fecha_Constitucion_Garantia__c = entrada.garantiaConstituida == FSC_GarantiaFormalizacionService.RESPUESTA_SI
			? entrada.fechaConstitucionGarantia
			: null;
		garantia.FSC_Garantia_Constituida__c = actualizacion.FSC_Garantia_Constituida__c;
		garantia.FSC_Comentario_Formalizacion_Vehiculo__c = actualizacion.FSC_Comentario_Formalizacion_Vehiculo__c;
		garantia.FSC_Fecha_Constitucion_Garantia__c = actualizacion.FSC_Fecha_Constitucion_Garantia__c;
	}

	private static String validarComentarioVehiculo(String comentarioRecibido) {
		String comentario = comentarioRecibido?.trim();
		if (String.isBlank(comentario)) {
			throw new AuraHandledException('El comentario es requerido para cada garantía vehicular.');
		}
		if (comentario.length() > COMENTARIO_MAXIMO) {
			throw new AuraHandledException('El comentario de la garantía vehicular no puede superar 1.000 caracteres.');
		}
		return comentario;
	}

	private static void validarFechaConstitucionVehiculo(String garantiaConstituida, Date fechaConstitucion) {
		validarFechaNoFutura(fechaConstitucion, 'La fecha de constitución de la garantía no puede ser posterior a la fecha actual.');
		if (garantiaConstituida == FSC_GarantiaFormalizacionService.RESPUESTA_SI && fechaConstitucion == null) {
			throw new AuraHandledException('La fecha de constitución es requerida cuando la garantía vehicular está constituida.');
		}
	}

	private static void validarRespuesta(String respuesta, String mensaje) {
		if (respuesta != FSC_GarantiaFormalizacionService.RESPUESTA_SI && respuesta != FSC_GarantiaFormalizacionService.RESPUESTA_NO) {
			throw new AuraHandledException(mensaje);
		}
	}

	private static void validarFechaNoFutura(Date fecha, String mensajeError) {
		if (fecha != null && fecha > Date.today()) {
			throw new AuraHandledException(mensajeError);
		}
	}

	private static void actualizarSubestado(Id residentialLoanApplicationId, String subestado) {
		try {
			new EscrituraFormalizacion().actualizar(
				new List<SObject>{ new ResidentialLoanApplication(Id = residentialLoanApplicationId, FSC_Subestado__c = subestado) }
			);
		} catch (DmlException exceptionDetails) {
			throw new AuraHandledException('No se pudo actualizar el subestado de la solicitud. Verifique sus permisos.');
		}
	}

	private static void validarEntradaYPermiso(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (
			!omitirValidacionPermisoEnPrueba &&
			!FeatureManagement.checkPermission(PERMISO_FORMALIZACION) &&
			!FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR)
		) {
			throw new AuraHandledException('No tiene permiso para formalizar garantías.');
		}
		validarUsuarioAsignado(residentialLoanApplicationId);
	}

	// El usuario de formalización solo lee la solicitud (modelo Private); las escrituras se hacen sin sharing
	// después de validar el permiso y la asignación, y solo tocan los campos que arma este controlador.
	private without sharing class EscrituraFormalizacion {
		void actualizar(List<SObject> registros) {
			Database.update(registros, true, AccessLevel.SYSTEM_MODE);
		}
	}

	// Sin usuario asignado (cola vacía o solicitudes anteriores) cualquiera con el permiso puede formalizar.
	private static void validarUsuarioAsignado(Id residentialLoanApplicationId) {
		if (!ignorarAdministradorEnPrueba && FeatureManagement.checkPermission(PERMISO_ADMINISTRADOR)) {
			return;
		}
		List<ResidentialLoanApplication> solicitudes = [
			SELECT FSC_UsuarioFormalizacion__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			WITH SYSTEM_MODE
			LIMIT 1
		];
		if (
			!solicitudes.isEmpty() &&
			solicitudes[0].FSC_UsuarioFormalizacion__c != null &&
			solicitudes[0].FSC_UsuarioFormalizacion__c != UserInfo.getUserId()
		) {
			throw new AuraHandledException('La formalización está asignada a otro usuario. Solo la persona asignada o un administrador pueden realizarla.');
		}
	}

	public class FormalizacionContext {
		@AuraEnabled
		public String subestado;
		@AuraEnabled
		public Boolean tieneGarantiasAplicables;
		@AuraEnabled
		public Boolean todasFormalizadas;
		@AuraEnabled
		public Integer cantidadPendientes;
		@AuraEnabled
		public List<GarantiaItem> garantias;
	}

	public class GarantiaItem {
		@AuraEnabled
		public Id id;
		@AuraEnabled
		public String nombre;
		@AuraEnabled
		public String claseGarantia;
		@AuraEnabled
		public Boolean esHipotecaria;
		@AuraEnabled
		public Boolean esVehiculo;
		@AuraEnabled
		public String tituloRegistrado;
		@AuraEnabled
		public Date fechaFormalizacionHipotecaria;
		@AuraEnabled
		public String garantiaConstituida;
		@AuraEnabled
		public String comentarioVehiculo;
		@AuraEnabled
		public Date fechaConstitucionGarantia;
		@AuraEnabled
		public Boolean formalizada;
	}

	public class GarantiaInput {
		@AuraEnabled
		public Id id { get; set; }
		@AuraEnabled
		public String tituloRegistrado { get; set; }
		@AuraEnabled
		public Date fechaFormalizacionHipotecaria { get; set; }
		@AuraEnabled
		public String garantiaConstituida { get; set; }
		@AuraEnabled
		public String comentarioVehiculo { get; set; }
		@AuraEnabled
		public Date fechaConstitucionGarantia { get; set; }
	}
}