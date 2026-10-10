@IsTest
private class FSC_GarantiaFormalizacionTest {
    static void asignarPermisosAdministrador() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet permiso = [SELECT Id FROM PermissionSet WHERE Name = 'FSC_PS_Administrador' LIMIT 1];
            // El usuario que ejecuta los tests puede tener ya el permission set asignado.
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permiso.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permiso.Id);
            }
        }
    }

	private static final String SOLICITUD_MIXTA = 'RLA Formalizacion Mixta';
	private static final String SOLICITUD_SIN_GARANTIA = 'RLA Sin Garantia Aplicable';
	private static final String SOLICITUD_PENDIENTE = 'RLA Garantia Pendiente';

	@TestSetup
	static void setupData() {
		asignarPermisosAdministrador();
		Account account = FSC_ExcepcionTestDataFactory.createAccount('4701', true);
		ResidentialLoanApplication solicitudMixta = FSC_ExcepcionTestDataFactory.createSolicitud(
			account.Id,
			SOLICITUD_MIXTA,
			FSC_GarantiaFormalizacionService.SUBESTADO_FORMALIZACION,
			500000,
			true
		);
		FSC_ExcepcionTestDataFactory.createSolicitud(account.Id, SOLICITUD_SIN_GARANTIA, 'Gestionar firmas', 200000, true);
		ResidentialLoanApplication solicitudPendiente = FSC_ExcepcionTestDataFactory.createSolicitud(
			account.Id,
			SOLICITUD_PENDIENTE,
			FSC_GarantiaFormalizacionService.SUBESTADO_FORMALIZACION,
			300000,
			true
		);

		insert new List<FSC_Garantia__c>{
			crearGarantia(solicitudMixta.Id, 'Hipoteca principal', 'BIENES INMUEBLES'),
			crearGarantia(solicitudMixta.Id, 'Vehiculo principal', 'VEHICULOS USADOS-P2'),
			crearGarantia(solicitudMixta.Id, 'Certificado excluido', 'CERTIFICADOS DEPOSITOS BANCO VIMENCA'),
			crearGarantia(solicitudPendiente.Id, 'Vehiculo pendiente', 'VEHICULOS, MAQUINARIAS')
		};
	}

	@IsTest
	static void resolverSubestadoPosteriorAFirmasClasificaSolicitudes() {
		Map<String, ResidentialLoanApplication> solicitudes = obtenerSolicitudesPorNombre();
		Set<Id> ids = new Set<Id>{ solicitudes.get(SOLICITUD_MIXTA).Id, solicitudes.get(SOLICITUD_SIN_GARANTIA).Id };

		Test.startTest();
		Map<Id, String> resultado = FSC_GarantiaFormalizacionService.resolverSubestadoPosteriorAFirmas(ids);
		Test.stopTest();

		Assert.areEqual(
			FSC_GarantiaFormalizacionService.SUBESTADO_FORMALIZACION,
			resultado.get(solicitudes.get(SOLICITUD_MIXTA).Id),
			'Una garantia hipotecaria o vehicular debe enviar la solicitud a Formalizacion.'
		);
		Assert.areEqual(
			FSC_GarantiaFormalizacionService.SUBESTADO_DOCUMENTACION_DESEMBOLSO,
			resultado.get(solicitudes.get(SOLICITUD_SIN_GARANTIA).Id),
			'Una solicitud sin garantias aplicables debe continuar a documentacion.'
		);
	}

	@IsTest
	static void getContextDevuelveSoloGarantiasAplicables() {
		FSC_GarantiaFormalizacionController.omitirValidacionPermisoEnPrueba = true;
		Id solicitudId = obtenerSolicitudesPorNombre().get(SOLICITUD_MIXTA).Id;

		Test.startTest();
		FSC_GarantiaFormalizacionController.FormalizacionContext contexto = FSC_GarantiaFormalizacionController.getContext(solicitudId);
		Test.stopTest();

		Assert.isTrue(contexto.tieneGarantiasAplicables, 'Debe identificar las garantias aplicables.');
		Assert.isFalse(contexto.todasFormalizadas, 'Las garantias nuevas deben estar pendientes.');
		Assert.areEqual(2, contexto.cantidadPendientes, 'Solo hipoteca y vehiculo deben contarse como pendientes.');
		Assert.areEqual(2, contexto.garantias.size(), 'El certificado de deposito no debe incluirse.');
	}

	@IsTest
	static void guardarFormalizacionCompletaTodasYAvanzaSolicitud() {
		FSC_GarantiaFormalizacionController.omitirValidacionPermisoEnPrueba = true;
		ResidentialLoanApplication solicitud = obtenerSolicitudesPorNombre().get(SOLICITUD_MIXTA);
		Map<String, FSC_Garantia__c> garantias = obtenerGarantiasPorNombre(solicitud.Id);
		List<FSC_GarantiaFormalizacionController.GarantiaInput> entradas = new List<FSC_GarantiaFormalizacionController.GarantiaInput>{
			crearEntradaHipotecaria(garantias.get('Hipoteca principal').Id, true, Date.today()),
			crearEntradaVehiculo(garantias.get('Vehiculo principal').Id, true, 'Inscripcion confirmada')
		};

		Test.startTest();
		FSC_GarantiaFormalizacionController.FormalizacionContext contexto = FSC_GarantiaFormalizacionController.guardarFormalizacion(
			solicitud.Id,
			entradas
		);
		Test.stopTest();

		Assert.isTrue(contexto.todasFormalizadas, 'Ambas garantias deben quedar formalizadas.');
		Assert.areEqual(0, contexto.cantidadPendientes, 'No deben quedar garantias pendientes.');
		ResidentialLoanApplication solicitudActualizada = [
			SELECT FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :solicitud.Id
		];
		Assert.areEqual(
			FSC_GarantiaFormalizacionService.SUBESTADO_DOCUMENTACION_DESEMBOLSO,
			solicitudActualizada.FSC_Subestado__c,
			'La solicitud debe avanzar cuando todas sus garantias estan formalizadas.'
		);
		Map<String, FSC_Garantia__c> garantiasActualizadas = obtenerGarantiasPorNombre(solicitud.Id);
		Assert.areEqual(
			FSC_GarantiaFormalizacionService.RESPUESTA_SI,
			garantiasActualizadas.get('Hipoteca principal').FSC_Titulo_Registrado__c,
			'El titulo debe quedar registrado con una respuesta explicita.'
		);
		Assert.areEqual(
			Date.today(),
			garantiasActualizadas.get('Hipoteca principal').FSC_Fecha_Formalizacion_Hipotecaria__c,
			'La fecha hipotecaria debe conservar el valor formalizado.'
		);
		Assert.areEqual(
			FSC_GarantiaFormalizacionService.RESPUESTA_SI,
			garantiasActualizadas.get('Vehiculo principal').FSC_Garantia_Constituida__c,
			'La garantia vehicular debe quedar constituida con una respuesta explicita.'
		);
		Assert.areEqual(
			'Inscripcion confirmada',
			garantiasActualizadas.get('Vehiculo principal').FSC_Comentario_Formalizacion_Vehiculo__c,
			'El comentario vehicular debe persistirse.'
		);
		Assert.areEqual(
			Date.today(),
			garantiasActualizadas.get('Vehiculo principal').FSC_Fecha_Constitucion_Garantia__c,
			'La fecha de constitucion de la garantia debe persistirse.'
		);
	}

	@IsTest
	static void guardarVehiculoNoConstituidoAvanzaConGarantiaPendiente() {
		FSC_GarantiaFormalizacionController.omitirValidacionPermisoEnPrueba = true;
		ResidentialLoanApplication solicitud = obtenerSolicitudesPorNombre().get(SOLICITUD_PENDIENTE);
		FSC_Garantia__c garantia = obtenerGarantiasPorNombre(solicitud.Id).get('Vehiculo pendiente');

		Test.startTest();
		FSC_GarantiaFormalizacionController.FormalizacionContext contexto = FSC_GarantiaFormalizacionController.guardarFormalizacion(
			solicitud.Id,
			new List<FSC_GarantiaFormalizacionController.GarantiaInput>{ crearEntradaVehiculo(garantia.Id, false, 'Pendiente de inscripcion') }
		);
		Test.stopTest();

		Assert.isFalse(contexto.todasFormalizadas, 'Un vehiculo no constituido debe continuar pendiente.');
		Assert.areEqual(1, contexto.cantidadPendientes, 'Debe conservar una garantia pendiente.');
		ResidentialLoanApplication solicitudActualizada = [
			SELECT FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :solicitud.Id
		];
		Assert.areEqual(
			FSC_GarantiaFormalizacionService.SUBESTADO_DOCUMENTACION_DESEMBOLSO,
			solicitudActualizada.FSC_Subestado__c,
			'Una respuesta No debe permitir continuar al desembolso y conservar la garantia pendiente.'
		);
		Assert.areEqual(
			FSC_GarantiaFormalizacionService.RESPUESTA_NO,
			[
				SELECT FSC_Garantia_Constituida__c
				FROM FSC_Garantia__c
				WHERE Id = :garantia.Id
			]
			.FSC_Garantia_Constituida__c,
			'La respuesta No debe persistirse para la segunda gestion de formalizacion.'
		);
	}

	@IsTest
	static void guardarTituloNoRegistradoAvanzaConGarantiaPendiente() {
		FSC_GarantiaFormalizacionController.omitirValidacionPermisoEnPrueba = true;
		ResidentialLoanApplication solicitud = obtenerSolicitudesPorNombre().get(SOLICITUD_MIXTA);
		Map<String, FSC_Garantia__c> garantias = obtenerGarantiasPorNombre(solicitud.Id);
		Id garantiaHipotecariaId = garantias.get('Hipoteca principal').Id;

		Test.startTest();
		FSC_GarantiaFormalizacionController.FormalizacionContext contexto = FSC_GarantiaFormalizacionController.guardarFormalizacion(
			solicitud.Id,
			new List<FSC_GarantiaFormalizacionController.GarantiaInput>{
				crearEntradaHipotecaria(garantiaHipotecariaId, false, null),
				crearEntradaVehiculo(garantias.get('Vehiculo principal').Id, true, 'Inscripcion confirmada')
			}
		);
		Test.stopTest();

		Assert.isFalse(contexto.todasFormalizadas, 'Un titulo no registrado debe continuar pendiente.');
		Assert.areEqual(
			FSC_GarantiaFormalizacionService.SUBESTADO_DOCUMENTACION_DESEMBOLSO,
			contexto.subestado,
			'El titulo pendiente no debe impedir que la solicitud continue al desembolso.'
		);
		Assert.areEqual(
			FSC_GarantiaFormalizacionService.RESPUESTA_NO,
			[
				SELECT FSC_Titulo_Registrado__c
				FROM FSC_Garantia__c
				WHERE Id = :garantiaHipotecariaId
			]
			.FSC_Titulo_Registrado__c,
			'La respuesta No del titulo debe persistirse para completar el registro despues del desembolso.'
		);
	}

	@IsTest
	static void formalizarDespuesDeDesembolsoCompletaGarantiaPendiente() {
		FSC_GarantiaFormalizacionController.omitirValidacionPermisoEnPrueba = true;
		ResidentialLoanApplication solicitud = obtenerSolicitudesPorNombre().get(SOLICITUD_PENDIENTE);
		FSC_Garantia__c garantia = obtenerGarantiasPorNombre(solicitud.Id).get('Vehiculo pendiente');

		FSC_GarantiaFormalizacionController.guardarFormalizacion(
			solicitud.Id,
			new List<FSC_GarantiaFormalizacionController.GarantiaInput>{ crearEntradaVehiculo(garantia.Id, false, 'Pendiente de inscripcion') }
		);

		Test.startTest();
		FSC_GarantiaFormalizacionController.FormalizacionContext contexto = FSC_GarantiaFormalizacionController.guardarFormalizacion(
			solicitud.Id,
			new List<FSC_GarantiaFormalizacionController.GarantiaInput>{ crearEntradaVehiculo(garantia.Id, true, 'Inscripcion completada') }
		);
		Test.stopTest();

		Assert.isTrue(contexto.todasFormalizadas, 'La segunda gestion debe completar la garantia pendiente.');
		Assert.areEqual(0, contexto.cantidadPendientes, 'No deben quedar garantias pendientes despues de la segunda gestion.');
		Assert.areEqual(
			FSC_GarantiaFormalizacionService.SUBESTADO_DOCUMENTACION_DESEMBOLSO,
			contexto.subestado,
			'La formalizacion tardia no debe retroceder el flujo de desembolso.'
		);
	}

	@IsTest
	static void desembolsarSinRegistrarAvanzaPeroCierreQuedaBloqueado() {
		FSC_GarantiaFormalizacionController.omitirValidacionPermisoEnPrueba = true;
		ResidentialLoanApplication solicitud = obtenerSolicitudesPorNombre().get(SOLICITUD_PENDIENTE);

		Test.startTest();
		FSC_GarantiaFormalizacionController.desembolsarSinRegistrar(solicitud.Id);
		ResidentialLoanApplication solicitudAnterior = new ResidentialLoanApplication(
			Id = solicitud.Id,
			Status = 'En proceso',
			FSC_Subestado__c = FSC_GarantiaFormalizacionService.SUBESTADO_DOCUMENTACION_DESEMBOLSO
		);
		ResidentialLoanApplication solicitudCerrada = new ResidentialLoanApplication(
			Id = solicitud.Id,
			Status = 'Cerrada Ganada',
			FSC_Subestado__c = 'Completado'
		);
		FSC_GarantiaFormalizacionService.validarCierre(
			new List<ResidentialLoanApplication>{ solicitudCerrada },
			new Map<Id, ResidentialLoanApplication>{ solicitud.Id => solicitudAnterior }
		);
		Test.stopTest();

		Assert.areEqual(
			FSC_GarantiaFormalizacionService.SUBESTADO_DOCUMENTACION_DESEMBOLSO,
			[
				SELECT FSC_Subestado__c
				FROM ResidentialLoanApplication
				WHERE Id = :solicitud.Id
			]
			.FSC_Subestado__c,
			'La opcion Si debe permitir continuar a documentacion.'
		);
		Assert.isTrue(solicitudCerrada.hasErrors(), 'El cierre debe bloquearse mientras exista una garantia pendiente.');
	}

	@IsTest
	static void desembolsarSinRegistrarRechazaSubestadoNoPermitido() {
		FSC_GarantiaFormalizacionController.omitirValidacionPermisoEnPrueba = true;
		ResidentialLoanApplication solicitud = obtenerSolicitudesPorNombre().get(SOLICITUD_SIN_GARANTIA);
		Boolean solicitudRechazada = false;

		Test.startTest();
		try {
			FSC_GarantiaFormalizacionController.desembolsarSinRegistrar(solicitud.Id);
			Assert.fail('La accion debio rechazarse fuera del subestado Formalizacion.');
		} catch (AuraHandledException exceptionDetails) {
			solicitudRechazada = true;
		}
		Test.stopTest();

		Assert.isTrue(solicitudRechazada, 'El API no debe permitir avanzar solicitudes fuera de Formalizacion.');
	}

	@IsTest
	static void triggerImpideCerrarSolicitudConGarantiaPendiente() {
		ResidentialLoanApplication solicitud = obtenerSolicitudesPorNombre().get(SOLICITUD_PENDIENTE);
		Boolean cierreBloqueado = false;

		Test.startTest();
		try {
			update new ResidentialLoanApplication(Id = solicitud.Id, Status = 'Cerrada Ganada', FSC_Subestado__c = 'Completado');
		} catch (DmlException exceptionDetails) {
			cierreBloqueado = exceptionDetails.getDmlMessage(0).contains('garant');
		}
		Test.stopTest();

		Assert.isTrue(cierreBloqueado, 'El trigger debe impedir la aprobacion final mientras exista una garantia pendiente.');
	}

	@IsTest
	static void validarAprobacionArchivoCustodiaRechazaGarantiaPendiente() {
		ResidentialLoanApplication solicitud = obtenerSolicitudesPorNombre().get(SOLICITUD_PENDIENTE);
		Boolean aprobacionBloqueada = false;

		Test.startTest();
		try {
			FSC_GarantiaFormalizacionService.validarAprobacionArchivoCustodia(solicitud.Id, 'Archivo y custodia');
			Assert.fail('La aprobacion debio bloquearse por la garantia pendiente.');
		} catch (AuraHandledException exceptionDetails) {
			aprobacionBloqueada = true;
		}
		Test.stopTest();

		Assert.isTrue(aprobacionBloqueada, 'Archivo y custodia no debe aprobarse con garantias pendientes.');
	}

	@IsTest
	static void validarAprobacionArchivoCustodiaPermiteSolicitudSinGarantiaAplicable() {
		ResidentialLoanApplication solicitud = obtenerSolicitudesPorNombre().get(SOLICITUD_SIN_GARANTIA);

		Test.startTest();
		FSC_GarantiaFormalizacionService.validarAprobacionArchivoCustodia(solicitud.Id, 'Archivo y custodia');
		Test.stopTest();

		Assert.areEqual(
			'Gestionar firmas',
			[SELECT FSC_Subestado__c FROM ResidentialLoanApplication WHERE Id = :solicitud.Id].FSC_Subestado__c,
			'La validacion no debe modificar una solicitud sin garantias aplicables.'
		);
	}

	@IsTest
	static void rechazaFechaFutura() {
		FSC_GarantiaFormalizacionController.omitirValidacionPermisoEnPrueba = true;
		ResidentialLoanApplication solicitud = obtenerSolicitudesPorNombre().get(SOLICITUD_PENDIENTE);
		FSC_Garantia__c garantia = obtenerGarantiasPorNombre(solicitud.Id).get('Vehiculo pendiente');
		Boolean errorEsperado = false;

		Test.startTest();
		try {
			FSC_GarantiaFormalizacionController.GarantiaInput entrada = crearEntradaVehiculo(garantia.Id, true, 'Fecha invalida');
			entrada.fechaConstitucionGarantia = Date.today().addDays(1);
			FSC_GarantiaFormalizacionController.guardarFormalizacion(
				solicitud.Id,
				new List<FSC_GarantiaFormalizacionController.GarantiaInput>{ entrada }
			);
		} catch (AuraHandledException exceptionDetails) {
			errorEsperado = true;
		}
		Test.stopTest();

		Assert.isTrue(errorEsperado, 'Debe rechazar fechas de formalizacion futuras.');
	}

	@IsTest
	static void resolverSubestadoEsBulkificado() {
		Account account = [SELECT Id FROM Account WHERE Name LIKE 'Cuenta prueba excepciones%' LIMIT 1];
		List<ResidentialLoanApplication> solicitudes = FSC_ExcepcionTestDataFactory.createSolicitudes(account.Id, 251, true);
		Set<Id> ids = new Map<Id, ResidentialLoanApplication>(solicitudes).keySet();

		Test.startTest();
		Map<Id, String> resultado = FSC_GarantiaFormalizacionService.resolverSubestadoPosteriorAFirmas(ids);
		Test.stopTest();

		Assert.areEqual(251, resultado.size(), 'Debe resolver todas las solicitudes de una transaccion masiva.');
		for (String subestado : resultado.values()) {
			Assert.areEqual(
				FSC_GarantiaFormalizacionService.SUBESTADO_DOCUMENTACION_DESEMBOLSO,
				subestado,
				'Las solicitudes sin garantias aplicables deben avanzar a documentacion.'
			);
		}
	}

	private static FSC_Garantia__c crearGarantia(Id solicitudId, String nombre, String claseGarantia) {
		return new FSC_Garantia__c(
			Name = nombre,
			FSC_Residential_Loan_Application__c = solicitudId,
			FSC_Clase_de_Garantia__c = claseGarantia,
			FSC_Tipo_de_Garantia__c = nombre,
			FSC_Descripcion_de_la_Garantia__c = 'Garantia para pruebas de formalizacion'
		);
	}

	private static Map<String, ResidentialLoanApplication> obtenerSolicitudesPorNombre() {
		Map<String, ResidentialLoanApplication> resultado = new Map<String, ResidentialLoanApplication>();
		for (ResidentialLoanApplication solicitud : [
			SELECT Id, Name, Status, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Name IN :new Set<String>{ SOLICITUD_MIXTA, SOLICITUD_SIN_GARANTIA, SOLICITUD_PENDIENTE }
		]) {
			resultado.put(solicitud.Name, solicitud);
		}
		return resultado;
	}

	private static Map<String, FSC_Garantia__c> obtenerGarantiasPorNombre(Id solicitudId) {
		Map<String, FSC_Garantia__c> resultado = new Map<String, FSC_Garantia__c>();
		for (FSC_Garantia__c garantia : [
			SELECT
				Id,
				Name,
				FSC_Titulo_Registrado__c,
				FSC_Fecha_Formalizacion_Hipotecaria__c,
				FSC_Garantia_Constituida__c,
				FSC_Comentario_Formalizacion_Vehiculo__c,
				FSC_Fecha_Constitucion_Garantia__c
			FROM FSC_Garantia__c
			WHERE FSC_Residential_Loan_Application__c = :solicitudId
		]) {
			resultado.put(garantia.Name, garantia);
		}
		return resultado;
	}

	private static FSC_GarantiaFormalizacionController.GarantiaInput crearEntradaHipotecaria(
		Id garantiaId,
		Boolean tituloRegistrado,
		Date fechaFormalizacion
	) {
		FSC_GarantiaFormalizacionController.GarantiaInput entrada = new FSC_GarantiaFormalizacionController.GarantiaInput();
		entrada.id = garantiaId;
		entrada.tituloRegistrado = tituloRegistrado ? FSC_GarantiaFormalizacionService.RESPUESTA_SI : FSC_GarantiaFormalizacionService.RESPUESTA_NO;
		entrada.fechaFormalizacionHipotecaria = fechaFormalizacion;
		return entrada;
	}

	private static FSC_GarantiaFormalizacionController.GarantiaInput crearEntradaVehiculo(
		Id garantiaId,
		Boolean garantiaConstituida,
		String comentario
	) {
		FSC_GarantiaFormalizacionController.GarantiaInput entrada = new FSC_GarantiaFormalizacionController.GarantiaInput();
		entrada.id = garantiaId;
		entrada.garantiaConstituida = garantiaConstituida
			? FSC_GarantiaFormalizacionService.RESPUESTA_SI
			: FSC_GarantiaFormalizacionService.RESPUESTA_NO;
		entrada.comentarioVehiculo = comentario;
		entrada.fechaConstitucionGarantia = garantiaConstituida ? Date.today() : null;
		return entrada;
	}
}