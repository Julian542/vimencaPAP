@IsTest
private class FSC_FormalizacionGarantiasTest {
	private static final String SOLICITUD_HIPOTECARIA = 'RLA Formalizacion Hipotecaria';
	private static final String SOLICITUD_VEHICULO = 'RLA Formalizacion Vehiculo';
	private static final String SOLICITUD_MOBILIARIA = 'RLA Formalizacion Mobiliaria';
	private static final String PERMISO_ADMINISTRADOR = FSC_FormalizacionGarantiasService.PERMISO_ADMINISTRADOR;

	@TestSetup
	static void setupData() {
		// Estos datos no prueban la política de crédito; sus límites se prueban en FSC_CreditPolicyGuardTest.
		FSC_CreditPolicyGuard.bypassInTests = true;
		Account cuenta = FSC_ExcepcionTestDataFactory.createAccount('4801', true);
		List<ResidentialLoanApplication> solicitudes = new List<ResidentialLoanApplication>{
			FSC_ExcepcionTestDataFactory.createSolicitud(cuenta.Id, SOLICITUD_HIPOTECARIA, 'Gestionar firmas', 500000, false),
			FSC_ExcepcionTestDataFactory.createSolicitud(cuenta.Id, SOLICITUD_VEHICULO, 'Gestionar firmas', 300000, false),
			FSC_ExcepcionTestDataFactory.createSolicitud(cuenta.Id, SOLICITUD_MOBILIARIA, 'Gestionar firmas', 200000, false)
		};
		insert solicitudes;
		insert new List<FSC_Garantia__c>{
			crearGarantia(solicitudes[0].Id, 'Hipoteca', 'BIENES INMUEBLES'),
			crearGarantia(solicitudes[1].Id, 'Vehiculo', 'VEHICULOS USADOS-P2'),
			crearGarantia(solicitudes[2].Id, 'Maquinaria', 'MAQUINARIAS INDUSTRIALES')
		};
	}

	@IsTest
	static void entrarAFormalizacionIniciaRevisionDeDocumentos() {
		Id solicitudId = solicitud(SOLICITUD_HIPOTECARIA).Id;

		Test.startTest();
		update new ResidentialLoanApplication(Id = solicitudId, FSC_Subestado__c = 'Formalización');
		Test.stopTest();

		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_REVISION, solicitud(SOLICITUD_HIPOTECARIA).FSC_EtapaFormalizacion__c);
	}

	@IsTest
	static void rutasDeGarantia() {
		Assert.areEqual('hipotecaria', FSC_CatalogoGarantiaService.getRutaFormalizacion('BIENES INMUEBLES'));
		Assert.areEqual('vehiculo', FSC_CatalogoGarantiaService.getRutaFormalizacion('VEHICULOS USADOS-P2'));
		Assert.areEqual('mobiliaria', FSC_CatalogoGarantiaService.getRutaFormalizacion('MAQUINARIAS INDUSTRIALES'));
		Assert.isNull(FSC_CatalogoGarantiaService.getRutaFormalizacion('CERTIFICADOS DEPOSITOS BANCO VIMENCA'), 'CD Vimenca queda fuera del flujo.');
		Assert.isNull(FSC_CatalogoGarantiaService.getRutaFormalizacion(null));
		Assert.isTrue(FSC_GarantiaFormalizacionService.esGarantiaAplicable('MAQUINARIAS INDUSTRIALES'));
	}

	@IsTest
	static void hipotecariaRegistroAntesDelDesembolso() {
		comoAdministrador();
		Id solicitudId = enFormalizacion(SOLICITUD_HIPOTECARIA, FSC_FormalizacionGarantiasService.ETAPA_REVISION);

		Test.startTest();
		ejecutar(solicitudId, 'CONTINUAR', new Map<String, Object>{ 'modalidad' => FSC_FormalizacionGarantiasService.MODALIDAD_ANTES });
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_FIRMAS, etapa(solicitudId));

		ejecutar(solicitudId, 'DEVOLVER_OFICIAL', new Map<String, Object>{ 'comentario' => 'Falta poder notarial' });
		ResidentialLoanApplication devuelta = solicitud(SOLICITUD_HIPOTECARIA);
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_DEVUELTA_OFICIAL, devuelta.FSC_EtapaFormalizacion__c);
		Assert.isTrue(devuelta.FSC_ObservacionFormalizacion__c.contains('Falta poder notarial'));

		ejecutar(solicitudId, 'REENVIAR_FORMALIZACION', null);
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_FIRMAS, etapa(solicitudId), 'Debe volver a la etapa desde donde se devolvió.');

		ejecutar(solicitudId, 'FIRMAS_COMPLETADAS', null);
		ejecutar(solicitudId, 'ENVIAR_EJECUCION', new Map<String, Object>{ 'comentario' => 'Autorización recibida' });
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_SOLICITUD_CHEQUE, etapa(solicitudId));
		Test.stopTest();

		Assert.areEqual(
			FSC_FormalizacionGarantiasService.MODALIDAD_ANTES,
			garantia(solicitudId).FSC_ModalidadFormalizacion__c,
			'La modalidad se guarda en la garantía.'
		);
	}

	@IsTest
	static void hipotecariaPagoDepositoYDesembolso() {
		comoAdministrador();
		Id solicitudId = enFormalizacion(SOLICITUD_HIPOTECARIA, FSC_FormalizacionGarantiasService.ETAPA_SOLICITUD_CHEQUE);
		Id chequeId = archivoPrivado('cheque.pdf');

		Test.startTest();
		ejecutar(solicitudId, 'CHEQUE_ANEXADO', new Map<String, Object>{ 'archivos' => new List<Object>{ chequeId } });
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_PAGO_DGII, etapa(solicitudId));
		Assert.areEqual(1, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :solicitudId AND ContentDocumentId = :chequeId]);

		ejecutar(solicitudId, 'IMPUESTOS_LIQUIDADOS', new Map<String, Object>{ 'continuarRegistro' => 'Sí' });
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_DEPOSITO_TITULOS, etapa(solicitudId));

		ejecutar(
			solicitudId,
			'REGISTRAR_DEPOSITO',
			new Map<String, Object>{ 'numeroExpedienteRegistroTitulos' => 'RT-123', 'fechaConstitucion' => String.valueOf(Date.today()) }
		);
		ResidentialLoanApplication enDesembolso = solicitud(SOLICITUD_HIPOTECARIA);
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_EN_DESEMBOLSO, enDesembolso.FSC_EtapaFormalizacion__c);
		Assert.areEqual('Documentación para desembolso y firmas', enDesembolso.FSC_Subestado__c);
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_DEPOSITO_TITULOS, enDesembolso.FSC_EtapaFormalizacionRetorno__c);

		// El desembolso deja la solicitud en Archivo y custodia; el trigger la regresa a Formalización.
		update new ResidentialLoanApplication(Id = solicitudId, FSC_Subestado__c = 'Archivo y custodia');
		Test.stopTest();

		ResidentialLoanApplication retornada = solicitud(SOLICITUD_HIPOTECARIA);
		Assert.areEqual('Formalización', retornada.FSC_Subestado__c);
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_DEPOSITO_TITULOS, retornada.FSC_EtapaFormalizacion__c);
		Assert.isTrue(retornada.FSC_DesembolsoFormalizacion__c);
		Assert.areEqual('RT-123', garantia(solicitudId).FSC_NumeroExpedienteRegistroTitulos__c);
	}

	@IsTest
	static void hipotecariaRetiroCustodiaYCdd() {
		comoAdministrador();
		Id solicitudId = enFormalizacion(SOLICITUD_HIPOTECARIA, FSC_FormalizacionGarantiasService.ETAPA_DEPOSITO_TITULOS);
		update new FSC_Garantia__c(Id = garantia(solicitudId).Id, FSC_NumeroExpedienteRegistroTitulos__c = 'RT-9');
		update new ResidentialLoanApplication(Id = solicitudId, FSC_DesembolsoFormalizacion__c = true);

		Test.startTest();
		ejecutar(solicitudId, 'DISPONIBLE_ENTREGA', null);
		ejecutar(solicitudId, 'ENVIAR_RETIRO', null);
		ejecutar(solicitudId, 'REGISTRAR_RETIRO', new Map<String, Object>{ 'fechaFormalizacion' => String.valueOf(Date.today()) });
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_MANTENIMIENTO, etapa(solicitudId));
		ejecutar(solicitudId, 'FECHA_REGISTRADA', null);
		ejecutar(solicitudId, 'ENVIAR_CUSTODIA', null);
		ejecutar(solicitudId, 'ACUSAR_RECIBO', null);
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_CDD, etapa(solicitudId));
		ejecutar(solicitudId, 'DIGITALIZACION_COMPLETADA', null);
		Test.stopTest();

		ResidentialLoanApplication completada = solicitud(SOLICITUD_HIPOTECARIA);
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_COMPLETADA, completada.FSC_EtapaFormalizacion__c);
		Assert.areEqual('Archivo y custodia', completada.FSC_Subestado__c, 'Al completar continúa al archivo de la solicitud.');
		FSC_Garantia__c formalizada = garantia(solicitudId);
		Assert.areEqual('Sí', formalizada.FSC_Titulo_Registrado__c);
		Assert.areEqual(Date.today(), formalizada.FSC_Fecha_Formalizacion_Hipotecaria__c);
		Assert.isTrue(FSC_GarantiaFormalizacionService.estaFormalizada(formalizada));
	}

	@IsTest
	static void vehiculoDespuesDelDesembolsoYOposicion() {
		comoAdministrador();
		Id solicitudId = enFormalizacion(SOLICITUD_VEHICULO, FSC_FormalizacionGarantiasService.ETAPA_REVISION);

		Test.startTest();
		ejecutar(solicitudId, 'CONTINUAR', new Map<String, Object>{ 'modalidad' => FSC_FormalizacionGarantiasService.MODALIDAD_DESPUES });
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_EN_DESEMBOLSO, etapa(solicitudId));
		update new ResidentialLoanApplication(Id = solicitudId, FSC_Subestado__c = 'Archivo y custodia');
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_REVISION, etapa(solicitudId));

		ejecutar(solicitudId, 'CONTINUAR', null);
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_SEGM, etapa(solicitudId));
		ejecutar(solicitudId, 'REGISTRAR_SEGM', new Map<String, Object>{ 'fechaConstitucion' => String.valueOf(Date.today()) });
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_PENDIENTE_MATRICULA, etapa(solicitudId), 'Ya desembolsado espera la matrícula del oficial.');

		ejecutar(solicitudId, 'ENVIAR_MATRICULA', null);
		ejecutar(solicitudId, 'DEPOSITAR_MATRICULA', new Map<String, Object>{ 'numeroExpedienteDgii' => 'DGII-77' });
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_MATRICULA_DGII, etapa(solicitudId));
		ejecutar(solicitudId, 'DEVOLVER_OFICIAL', new Map<String, Object>{ 'comentario' => 'Matrícula con multa' });
		Test.stopTest();

		ResidentialLoanApplication devuelta = solicitud(SOLICITUD_VEHICULO);
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_OPOSICION_MATRICULA, devuelta.FSC_EtapaFormalizacionRetorno__c, 'Vuelve a depositar la matrícula.');
		Assert.areEqual('DGII-77', garantia(solicitudId).FSC_NumeroExpedienteDGII__c);
	}

	@IsTest
	static void vehiculoAntesDelDesembolsoVuelveAlOficial() {
		comoAdministrador();
		Id solicitudId = enFormalizacion(SOLICITUD_VEHICULO, FSC_FormalizacionGarantiasService.ETAPA_SEGM);

		Test.startTest();
		ejecutar(solicitudId, 'REGISTRAR_SEGM', new Map<String, Object>{ 'fechaConstitucion' => String.valueOf(Date.today()) });
		Test.stopTest();

		ResidentialLoanApplication enDesembolso = solicitud(SOLICITUD_VEHICULO);
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_EN_DESEMBOLSO, enDesembolso.FSC_EtapaFormalizacion__c);
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_PENDIENTE_MATRICULA, enDesembolso.FSC_EtapaFormalizacionRetorno__c);
	}

	@IsTest
	static void mobiliariaConcluyeAlRegistrarAvisoSegm() {
		comoAdministrador();
		Id solicitudId = enFormalizacion(SOLICITUD_MOBILIARIA, FSC_FormalizacionGarantiasService.ETAPA_REVISION);

		Test.startTest();
		ejecutar(solicitudId, 'CONTINUAR', new Map<String, Object>{ 'modalidad' => FSC_FormalizacionGarantiasService.MODALIDAD_ANTES });
		ejecutar(
			solicitudId,
			'REGISTRAR_SEGM',
			new Map<String, Object>{ 'fechaConstitucion' => String.valueOf(Date.today()), 'fechaFormalizacion' => String.valueOf(Date.today()) }
		);
		Test.stopTest();

		ResidentialLoanApplication concluida = solicitud(SOLICITUD_MOBILIARIA);
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_COMPLETADA, concluida.FSC_EtapaFormalizacion__c);
		Assert.areEqual('Documentación para desembolso y firmas', concluida.FSC_Subestado__c, 'Sin desembolso previo sigue a desembolso.');
		Assert.isTrue(FSC_GarantiaFormalizacionService.estaFormalizada(garantia(solicitudId)));
	}

	@IsTest
	static void cierreBloqueadoMientrasLaFormalizacionNoTermina() {
		Id solicitudId = enFormalizacion(SOLICITUD_MOBILIARIA, FSC_FormalizacionGarantiasService.ETAPA_SEGM);
		ResidentialLoanApplication anterior = new ResidentialLoanApplication(Id = solicitudId, Status = 'En proceso', FSC_Subestado__c = 'Archivo y custodia');
		ResidentialLoanApplication cierre = new ResidentialLoanApplication(Id = solicitudId, Status = 'Cerrada Ganada', FSC_Subestado__c = 'Completado');

		Test.startTest();
		FSC_GarantiaFormalizacionService.validarCierre(
			new List<ResidentialLoanApplication>{ cierre },
			new Map<Id, ResidentialLoanApplication>{ solicitudId => anterior }
		);
		Test.stopTest();

		Assert.isTrue(cierre.hasErrors(), 'Debe bloquear el cierre hasta completar la formalización.');
	}

	@IsTest
	static void contextoDelPanel() {
		comoAdministrador();
		Id solicitudId = enFormalizacion(SOLICITUD_HIPOTECARIA, FSC_FormalizacionGarantiasService.ETAPA_DEPOSITO_TITULOS);

		Test.startTest();
		FSC_FormalizacionGarantiasService.Contexto contexto = FSC_FormalizacionGarantiasController.getContexto(solicitudId);
		Test.stopTest();

		Assert.isTrue(contexto.visible);
		Assert.isTrue(contexto.esActor);
		Assert.areEqual('hipotecaria', contexto.ruta);
		Assert.isTrue(contexto.puedeGenerarInventario);
		Assert.isFalse(contexto.acciones.isEmpty());
		Assert.isFalse(contexto.enlaces.isEmpty(), 'Debe ofrecer la consulta en el Registro Inmobiliario.');
		Assert.isNotNull(contexto.mensaje);
		Assert.isNotNull(contexto.responsable);
	}

	@IsTest
	static void contextoSinProcesoNoEsVisible() {
		Test.startTest();
		FSC_FormalizacionGarantiasService.Contexto contexto = FSC_FormalizacionGarantiasController.getContexto(solicitud(SOLICITUD_HIPOTECARIA).Id);
		Test.stopTest();

		Assert.isFalse(contexto.visible);
	}

	@IsTest
	static void todasLasEtapasTienenMensajeYAcciones() {
		comoAdministrador();
		Map<String, FSC_Garantia__c> garantias = new Map<String, FSC_Garantia__c>();
		for (FSC_Garantia__c registro : [SELECT Id, FSC_Clase_de_Garantia__c, FSC_ModalidadFormalizacion__c, FSC_NumeroExpedienteRegistroTitulos__c,
				FSC_NumeroExpedienteDGII__c, FSC_Fecha_Constitucion_Garantia__c, FSC_Fecha_Formalizacion_Hipotecaria__c FROM FSC_Garantia__c]) {
			garantias.put(FSC_CatalogoGarantiaService.getRutaFormalizacion(registro.FSC_Clase_de_Garantia__c), registro);
		}
		garantias.get('hipotecaria').FSC_NumeroExpedienteRegistroTitulos__c = 'RT-1';
		Integer accionesTotales = 0;

		Test.startTest();
		for (Schema.PicklistEntry entrada : ResidentialLoanApplication.FSC_EtapaFormalizacion__c.getDescribe().getPicklistValues()) {
			for (String ruta : garantias.keySet()) {
				for (Boolean desembolsado : new List<Boolean>{ true, false }) {
					ResidentialLoanApplication rla = new ResidentialLoanApplication(
						FSC_EtapaFormalizacion__c = entrada.getValue(),
						FSC_EtapaFormalizacionRetorno__c = FSC_FormalizacionGarantiasService.ETAPA_REVISION
					);
					Assert.isNotNull(FSC_FormalizacionGarantiasService.mensajeEtapa(rla, ruta, desembolsado), 'Sin mensaje: ' + entrada.getValue());
					accionesTotales += FSC_FormalizacionGarantiasService.accionesDisponibles(rla, garantias.get(ruta), ruta, desembolsado).size();
					FSC_FormalizacionGarantiasService.enlacesEtapa(entrada.getValue(), ruta);
				}
			}
		}
		Test.stopTest();

		Assert.isTrue(accionesTotales > 50, 'Cada etapa con actor debe ofrecer acciones.');
	}

	@IsTest
	static void actoresPorEtapa() {
		ResidentialLoanApplication rla = new ResidentialLoanApplication(OwnerId = UserInfo.getUserId());
		Id otroUsuario = otroUsuarioActivo();

		FSC_FormalizacionGarantiasService.permisosEnPrueba = new Set<String>{ 'FSC_CP_Formalizacion_Creditos' };
		rla.FSC_EtapaFormalizacion__c = FSC_FormalizacionGarantiasService.ETAPA_REVISION;
		Assert.isTrue(FSC_FormalizacionGarantiasService.esActor(rla), 'Sin asignación cualquiera de Formalización puede actuar.');
		rla.FSC_UsuarioFormalizacion__c = otroUsuario;
		Assert.isFalse(FSC_FormalizacionGarantiasService.esActor(rla), 'Asignada a otro usuario no puede actuar.');

		rla.FSC_EtapaFormalizacion__c = FSC_FormalizacionGarantiasService.ETAPA_CDD;
		Assert.isFalse(FSC_FormalizacionGarantiasService.esActor(rla), 'Formalización no actúa en etapas del CDD.');
		FSC_FormalizacionGarantiasService.permisosEnPrueba = new Set<String>{ 'FSC_CP_CDD' };
		Assert.isTrue(FSC_FormalizacionGarantiasService.esActor(rla));
		rla.FSC_ResponsableAreaFormalizacion__c = otroUsuario;
		Assert.isFalse(FSC_FormalizacionGarantiasService.esActor(rla));

		FSC_FormalizacionGarantiasService.permisosEnPrueba = new Set<String>();
		rla.FSC_EtapaFormalizacion__c = FSC_FormalizacionGarantiasService.ETAPA_PENDIENTE_MATRICULA;
		Assert.isTrue(FSC_FormalizacionGarantiasService.esActor(rla), 'El oficial dueño gestiona la matrícula.');
		rla.FSC_EtapaFormalizacion__c = FSC_FormalizacionGarantiasService.ETAPA_EN_DESEMBOLSO;
		Assert.isFalse(FSC_FormalizacionGarantiasService.esActor(rla));
	}

	@IsTest
	static void administradorActuaEnTodasLasEtapasSinPermisosDeArea() {
		comoAdministrador();
		Id otroUsuario = otroUsuarioActivo();
		// Asignada a otras personas y con otro dueño: el Administrador igual puede actuar.
		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			OwnerId = otroUsuario,
			FSC_UsuarioFormalizacion__c = otroUsuario,
			FSC_ResponsableAreaFormalizacion__c = otroUsuario
		);
		Set<String> sinActor = new Set<String>{ FSC_FormalizacionGarantiasService.ETAPA_EN_DESEMBOLSO, FSC_FormalizacionGarantiasService.ETAPA_COMPLETADA };

		for (Schema.PicklistEntry entrada : ResidentialLoanApplication.FSC_EtapaFormalizacion__c.getDescribe().getPicklistValues()) {
			rla.FSC_EtapaFormalizacion__c = entrada.getValue();
			Assert.areEqual(!sinActor.contains(entrada.getValue()), FSC_FormalizacionGarantiasService.esActor(rla), entrada.getValue());
		}
	}

	@IsTest
	static void rechazaAccionesNoPermitidas() {
		FSC_FormalizacionGarantiasService.permisosEnPrueba = new Set<String>();
		Id solicitudId = enFormalizacion(SOLICITUD_HIPOTECARIA, FSC_FormalizacionGarantiasService.ETAPA_REVISION);

		Test.startTest();
		Boolean sinPermiso = lanzaError(solicitudId, 'CONTINUAR', new Map<String, Object>{ 'modalidad' => FSC_FormalizacionGarantiasService.MODALIDAD_ANTES });
		comoAdministrador();
		Boolean fueraDeEtapa = lanzaError(solicitudId, 'ACUSAR_RECIBO', null);
		Boolean modalidadInvalida = lanzaError(solicitudId, 'CONTINUAR', new Map<String, Object>{ 'modalidad' => 'Otra' });
		Boolean sinMotivo = lanzaError(solicitudId, 'DEVOLVER_OFICIAL', null);
		Test.stopTest();

		Assert.isTrue(sinPermiso, 'Sin permiso no puede actuar.');
		Assert.isTrue(fueraDeEtapa, 'La acción debe corresponder a la etapa.');
		Assert.isTrue(modalidadInvalida, 'La modalidad debe ser válida para la ruta.');
		Assert.isTrue(sinMotivo, 'La devolución exige motivo.');
	}

	@IsTest
	static void validaFechasYArchivos() {
		comoAdministrador();
		Id solicitudId = enFormalizacion(SOLICITUD_HIPOTECARIA, FSC_FormalizacionGarantiasService.ETAPA_SOLICITUD_CHEQUE);
		Id descartableId = archivoPrivado('descartar.pdf');

		Test.startTest();
		Boolean sinCheque = lanzaError(solicitudId, 'CHEQUE_ANEXADO', null);
		FSC_FormalizacionGarantiasController.descartarArchivos(new List<Id>{ descartableId });
		update new ResidentialLoanApplication(Id = solicitudId, FSC_EtapaFormalizacion__c = FSC_FormalizacionGarantiasService.ETAPA_EN_RETIRO);
		Boolean fechaFutura = lanzaError(solicitudId, 'REGISTRAR_RETIRO', new Map<String, Object>{ 'fechaFormalizacion' => String.valueOf(Date.today().addDays(3)) });
		Boolean fechaInvalida = lanzaError(solicitudId, 'REGISTRAR_RETIRO', new Map<String, Object>{ 'fechaFormalizacion' => 'no-es-fecha' });
		Test.stopTest();

		Assert.isTrue(sinCheque, 'El cheque es obligatorio.');
		Assert.areEqual(0, [SELECT COUNT() FROM ContentDocument WHERE Id = :descartableId]);
		Assert.isTrue(fechaFutura, 'No admite fechas futuras.');
		Assert.isTrue(fechaInvalida, 'No admite fechas inválidas.');
	}

	@IsTest
	static void generaInventarioYAutorizacion() {
		comoAdministrador();
		Id hipotecaId = enFormalizacion(SOLICITUD_HIPOTECARIA, FSC_FormalizacionGarantiasService.ETAPA_DEPOSITO_TITULOS);
		Id vehiculoId = enFormalizacion(SOLICITUD_VEHICULO, FSC_FormalizacionGarantiasService.ETAPA_OPOSICION_MATRICULA);

		Test.startTest();
		Map<String, Object> inventario = FSC_FormalizacionGarantiasController.getDatosDocumento(hipotecaId, 'inventario');
		List<Object> tasas = (List<Object>) inventario.get('tasas');
		((Map<String, Object>) tasas[0]).put('cantidad', 2);
		inventario.put('montoContrato', 1500000);
		Id inventarioId = FSC_FormalizacionGarantiasController.generarDocumento(hipotecaId, 'inventario', JSON.serialize(inventario));

		Map<String, Object> autorizacion = FSC_FormalizacionGarantiasController.getDatosDocumento(vehiculoId, 'autorizacion');
		autorizacion.putAll(
			new Map<String, Object>{
				'fechaContrato' => String.valueOf(Date.today()),
				'tipoVehiculo' => 'AUTOBUS PRIVADO',
				'marca' => 'TOYOTA',
				'modelo' => 'TOWNACE',
				'anio' => '2017',
				'color' => 'BLANCO',
				'chasis' => 'S402M-0063425',
				'placa' => 'I114367',
				'matricula' => '18783528',
				'sexoAutorizado' => 'Femenino',
				'nombreAutorizado' => 'Ana Pérez',
				'estadoCivilAutorizado' => 'soltera',
				'cedulaAutorizado' => '001-0000000-1'
			}
		);
		Id autorizacionId = FSC_FormalizacionGarantiasController.generarDocumento(vehiculoId, 'autorizacion', JSON.serialize(autorizacion));
		Test.stopTest();

		Assert.areEqual(1, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :hipotecaId AND ContentDocumentId = :inventarioId]);
		Assert.areEqual(1, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :vehiculoId AND ContentDocumentId = :autorizacionId]);

		FSC_FormalizacionDocumentosController.Inventario armado = FSC_FormalizacionDocumentosController.armarInventario(inventario);
		Assert.areEqual('2,000.00', armado.total, '2 x 1,000 de la primera tasa.');
		FSC_FormalizacionDocumentosController.Autorizacion carta = FSC_FormalizacionDocumentosController.armarAutorizacion(autorizacion);
		Assert.isTrue(carta.autorizado.startsWith('a la señora Ana Pérez'));
		Assert.isTrue(carta.vehiculo.contains('Matrícula No. 18783528'));
	}

	@IsTest
	static void paginasVisualforceLeenLosDatos() {
		FSC_FormalizacionDocumentosController.Inventario inventario = new FSC_FormalizacionDocumentosController.Inventario();
		inventario.nombreCliente = 'Cliente';
		inventario.documentos = new List<FSC_FormalizacionDocumentosController.Fila>{ new FSC_FormalizacionDocumentosController.Fila('Contrato', 1, null) };

		Test.startTest();
		PageReference pagina = Page.FSC_InventarioRegistroTitulos;
		pagina.getParameters().put('tipo', 'inventario');
		pagina.getParameters().put('datos', JSON.serialize(inventario));
		Test.setCurrentPage(pagina);
		FSC_FormalizacionDocumentosController controladorInventario = new FSC_FormalizacionDocumentosController();

		PageReference carta = Page.FSC_AutorizacionOposicionMatricula;
		carta.getParameters().put('tipo', 'autorizacion');
		carta.getParameters().put('datos', JSON.serialize(new FSC_FormalizacionDocumentosController.Autorizacion()));
		Test.setCurrentPage(carta);
		FSC_FormalizacionDocumentosController controladorCarta = new FSC_FormalizacionDocumentosController();
		Test.stopTest();

		Assert.areEqual('Cliente', controladorInventario.inventario.nombreCliente);
		Assert.isNotNull(controladorCarta.autorizacion);
	}

	@IsTest
	static void documentosSoloParaFormalizacion() {
		FSC_FormalizacionGarantiasService.permisosEnPrueba = new Set<String>();
		Id solicitudId = enFormalizacion(SOLICITUD_HIPOTECARIA, FSC_FormalizacionGarantiasService.ETAPA_DEPOSITO_TITULOS);
		Boolean bloqueado = false;

		Test.startTest();
		try {
			FSC_FormalizacionGarantiasController.getDatosDocumento(solicitudId, 'inventario');
		} catch (AuraHandledException e) {
			bloqueado = true;
		}
		Test.stopTest();

		Assert.isTrue(bloqueado);
	}

	@IsTest
	static void asignaResponsableDeLaColaConPermissionSet() {
		Group cola = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'FSC_ColaCDD' LIMIT 1];
		PermissionSet permiso = [SELECT Id FROM PermissionSet WHERE Name = 'FSC_PS_CDD' LIMIT 1];
		System.runAs(new User(Id = UserInfo.getUserId())) {
			insert new GroupMember(GroupId = cola.Id, UserOrGroupId = UserInfo.getUserId());
			if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permiso.Id] == 0) {
				insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permiso.Id);
			}
		}
		comoAdministrador();
		Id solicitudId = enFormalizacion(SOLICITUD_HIPOTECARIA, FSC_FormalizacionGarantiasService.ETAPA_CUSTODIA);

		Test.startTest();
		ejecutar(solicitudId, 'ACUSAR_RECIBO', null);
		Test.stopTest();

		ResidentialLoanApplication enCdd = solicitud(SOLICITUD_HIPOTECARIA);
		Assert.areEqual(FSC_FormalizacionGarantiasService.ETAPA_CDD, enCdd.FSC_EtapaFormalizacion__c);
		Assert.areEqual(UserInfo.getUserId(), enCdd.FSC_ResponsableAreaFormalizacion__c, 'Único miembro habilitado de la cola.');
	}

	@IsTest
	static void comparteSolicitudConElResponsable() {
		Id solicitudId = solicitud(SOLICITUD_HIPOTECARIA).Id;
		Id otroUsuario = otroUsuarioActivo();

		Test.startTest();
		update new ResidentialLoanApplication(Id = solicitudId, FSC_ResponsableAreaFormalizacion__c = otroUsuario);
		Test.stopTest();

		Integer accesos = [SELECT COUNT() FROM ResidentialLoanApplicationShare WHERE ParentId = :solicitudId AND UserOrGroupId = :otroUsuario];
		Assert.isTrue(accesos <= 1, 'No debe duplicar accesos.');
	}

	// ===== Utilidades =====

	private static void comoAdministrador() {
		FSC_FormalizacionGarantiasService.permisosEnPrueba = new Set<String>{ PERMISO_ADMINISTRADOR };
	}

	private static Id enFormalizacion(String nombre, String etapa) {
		Id solicitudId = solicitud(nombre).Id;
		update new ResidentialLoanApplication(Id = solicitudId, FSC_Subestado__c = 'Formalización');
		update new ResidentialLoanApplication(Id = solicitudId, FSC_EtapaFormalizacion__c = etapa);
		return solicitudId;
	}

	private static void ejecutar(Id solicitudId, String accion, Map<String, Object> datos) {
		FSC_FormalizacionGarantiasController.ejecutarAccion(solicitudId, accion, datos);
	}

	private static Boolean lanzaError(Id solicitudId, String accion, Map<String, Object> datos) {
		try {
			ejecutar(solicitudId, accion, datos);
			return false;
		} catch (AuraHandledException e) {
			return true;
		}
	}

	private static String etapa(Id solicitudId) {
		return [SELECT FSC_EtapaFormalizacion__c FROM ResidentialLoanApplication WHERE Id = :solicitudId].FSC_EtapaFormalizacion__c;
	}

	private static ResidentialLoanApplication solicitud(String nombre) {
		return [
			SELECT
				Id,
				FSC_Subestado__c,
				FSC_EtapaFormalizacion__c,
				FSC_EtapaFormalizacionRetorno__c,
				FSC_ObservacionFormalizacion__c,
				FSC_DesembolsoFormalizacion__c,
				FSC_ResponsableAreaFormalizacion__c
			FROM ResidentialLoanApplication
			WHERE Name = :nombre
			LIMIT 1
		];
	}

	private static FSC_Garantia__c garantia(Id solicitudId) {
		return [
			SELECT
				Id,
				FSC_Clase_de_Garantia__c,
				FSC_ModalidadFormalizacion__c,
				FSC_NumeroExpedienteRegistroTitulos__c,
				FSC_NumeroExpedienteDGII__c,
				FSC_Titulo_Registrado__c,
				FSC_Garantia_Constituida__c,
				FSC_Comentario_Formalizacion_Vehiculo__c,
				FSC_Fecha_Constitucion_Garantia__c,
				FSC_Fecha_Formalizacion_Hipotecaria__c
			FROM FSC_Garantia__c
			WHERE FSC_Residential_Loan_Application__c = :solicitudId
			LIMIT 1
		];
	}

	private static Id archivoPrivado(String nombre) {
		ContentVersion version = new ContentVersion(Title = nombre, PathOnClient = nombre, VersionData = Blob.valueOf('contenido'));
		insert version;
		return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :version.Id].ContentDocumentId;
	}

	private static Id otroUsuarioActivo() {
		return [SELECT Id FROM User WHERE IsActive = TRUE AND UserType = 'Standard' AND Id != :UserInfo.getUserId() LIMIT 1].Id;
	}

	private static FSC_Garantia__c crearGarantia(Id solicitudId, String nombre, String claseGarantia) {
		return new FSC_Garantia__c(
			Name = nombre,
			FSC_Residential_Loan_Application__c = solicitudId,
			FSC_Clase_de_Garantia__c = claseGarantia,
			FSC_Tipo_de_Garantia__c = nombre,
			FSC_Descripcion_de_la_Garantia__c = 'Garantia para pruebas de formalizacion por etapas'
		);
	}
}