@IsTest
private class FSC_ExcepcionesCreditoControllerTest {
	private static final String RLA_ELEGIBLE = 'RLA Excepción Elegible';
	private static final String RLA_NO_ELEGIBLE = 'RLA Excepción No Elegible';
	private static final String RLA_CONDICIONADA = 'RLA Excepción Condicionada';
	private static final String TIPO_NEGOCIOS = 'Excepciones de Negocios';

	@TestSetup
	static void setupTestData() {
		Account account = FSC_ExcepcionTestDataFactory.createAccount('1001', true);
		FSC_ExcepcionTestDataFactory.createSolicitud(account.Id, RLA_ELEGIBLE, 'En Motor Buró', 1000, true);
		FSC_ExcepcionTestDataFactory.createSolicitud(account.Id, RLA_NO_ELEGIBLE, 'Análisis de crédito', 1000, true);
		ResidentialLoanApplication condicionada = FSC_ExcepcionTestDataFactory.createSolicitud(
			account.Id,
			RLA_CONDICIONADA,
			'En Motor Buró',
			1000,
			true
		);
		insert FSC_ExcepcionTestDataFactory.buildExcepcion(condicionada.Id, 1, 'Pendiente', 'Presentar garantía adicional');
	}

	@IsTest
	static void shouldReturnConfiguredCatalogWhenOptionsAreRequested() {
		Integer expected = 0;
		for (FSC_ExcepcionesDeCredito__mdt config : FSC_ExcepcionesDeCredito__mdt.getAll().values()) {
			if (String.isNotBlank(config.FSC_Tipo__c) && String.isNotBlank(config.FSC_Detalle__c)) {
				expected++;
			}
		}

		Test.startTest();
		List<FSC_ExcepcionesCreditoController.FSC_OpcionExcepcion> options = FSC_ExcepcionesCreditoController.getOpcionesExcepcion();
		Test.stopTest();

		Assert.areEqual(expected, options.size(), 'Debe devolver cada configuración válida del Custom Metadata.');
	}

	@IsTest
	static void shouldExposeConfiguredCapacityWhenRequestHasNoExceptions() {
		ResidentialLoanApplication solicitud = getSolicitud(RLA_ELEGIBLE);
		forceAuthorization();
		FSC_ExcepcionConfig.testMaximoExcepciones = 5;

		Test.startTest();
		Map<String, Object> context = FSC_ExcepcionesCreditoController.getContextoExcepcion(solicitud.Id);
		Test.stopTest();

		Assert.areEqual(0, context.get('cantidad'), 'Una solicitud nueva debe iniciar con cero excepciones.');
		Assert.areEqual(5, context.get('maximo'), 'Debe exponer el máximo configurado al LWC.');
		Assert.areEqual(5, context.get('disponibles'), 'La capacidad inicial debe adaptarse a la configuración.');
		Assert.areEqual(true, context.get('puedeSolicitar'), 'Un oficial autorizado debe poder solicitar la primera.');
	}

	@IsTest
	static void shouldCreateChildAndSubmitChildApprovalWhenRequestIsValid() {
		ResidentialLoanApplication solicitud = getSolicitud(RLA_ELEGIBLE);
		FSC_ExcepcionesCreditoController.FSC_OpcionExcepcion option = getOption(TIPO_NEGOCIOS);
		forceAuthorization();

		Test.startTest();
		Id excepcionId = FSC_ExcepcionesCreditoController.solicitarExcepcion(
			solicitud.Id,
			option.tipo,
			option.detalle,
			'  Justificación de prueba  '
		);
		Test.stopTest();

		FSC_Excepcion__c created = [
			SELECT FSC_Solicitud_Prestamo__c, FSC_Tipo__c, FSC_Detalle__c, FSC_Motivo__c, FSC_Estado__c
			FROM FSC_Excepcion__c
			WHERE Id = :excepcionId
		];
		Assert.areEqual(solicitud.Id, created.FSC_Solicitud_Prestamo__c, 'El hijo debe relacionarse con la solicitud.');
		Assert.areEqual(option.tipo, created.FSC_Tipo__c, 'Debe almacenar el tipo configurado.');
		Assert.areEqual(option.detalle, created.FSC_Detalle__c, 'Debe almacenar el detalle configurado.');
		Assert.areEqual('Justificación de prueba', created.FSC_Motivo__c, 'Debe normalizar el motivo.');
		Assert.areEqual('Pendiente', created.FSC_Estado__c, 'Debe iniciar pendiente.');
		Assert.areEqual(
			1,
			[SELECT COUNT() FROM ProcessInstance WHERE TargetObjectId = :excepcionId],
			'La aprobación debe tener como objetivo el hijo, no ResidentialLoanApplication.'
		);
	}

	@IsTest
	static void shouldAllowThirdAndThenHideRequestActionWhenTwoChildrenExist() {
		ResidentialLoanApplication solicitud = getSolicitud(RLA_ELEGIBLE);
		insert new List<FSC_Excepcion__c>{
			FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 1, 'Aprobada', null),
			FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 2, 'Rechazada', null)
		};
		forceAuthorization();
		FSC_ExcepcionesCreditoController.FSC_OpcionExcepcion option = getOption(TIPO_NEGOCIOS);

		Test.startTest();
		Id thirdId = FSC_ExcepcionesCreditoController.solicitarExcepcion(solicitud.Id, option.tipo, option.detalle, 'Tercera excepción');
		Map<String, Object> context = FSC_ExcepcionesCreditoController.getContextoExcepcion(solicitud.Id);
		Test.stopTest();

		Assert.isNotNull(thirdId, 'La tercera excepción debe poder crearse.');
		Assert.areEqual(3, context.get('cantidad'), 'El contador debe incluir estados aprobados, rechazados y pendientes.');
		Assert.areEqual(true, context.get('limiteAlcanzado'), 'El contexto debe indicar que se alcanzó el límite.');
		Assert.areEqual(true, context.get('canActOnApproval'), 'Debe seleccionar la excepción cuyo Work Item puede atender el usuario.');
		Assert.areEqual(false, context.get('puedeSolicitar'), 'La acción de solicitud debe ocultarse después de la tercera.');
	}

	@IsTest
	static void shouldRejectRequestWhenThreeChildrenAlreadyExist() {
		ResidentialLoanApplication solicitud = getSolicitud(RLA_ELEGIBLE);
		insert new List<FSC_Excepcion__c>{
			FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 1, 'Aprobada', null),
			FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 2, 'Rechazada', null),
			FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 3, 'Pendiente', null)
		};
		forceAuthorization();
		FSC_ExcepcionesCreditoController.FSC_OpcionExcepcion option = getOption(TIPO_NEGOCIOS);

		Test.startTest();
		try {
			FSC_ExcepcionesCreditoController.solicitarExcepcion(solicitud.Id, option.tipo, option.detalle, 'Cuarta excepción');
			Assert.fail('Se esperaba el bloqueo de la cuarta excepción.');
		} catch (AuraHandledException exceptionInstance) {
			Assert.isNotNull(exceptionInstance, 'Debe devolver un error controlado al LWC.');
		}
		Test.stopTest();
		Assert.areEqual(3, [SELECT COUNT() FROM FSC_Excepcion__c WHERE FSC_Solicitud_Prestamo__c = :solicitud.Id], 'No debe crear un cuarto hijo.');
	}

	@IsTest
	static void shouldApproveConditionWhenClientAccepts() {
		FSC_Excepcion__c excepcion = getExcepcion(RLA_CONDICIONADA);
		forceAuthorization();

		Test.startTest();
		FSC_ExcepcionesCreditoController.responderCondicionCliente(excepcion.Id, true);
		Test.stopTest();

		Assert.areEqual('Aprobada', [SELECT FSC_Estado__c FROM FSC_Excepcion__c WHERE Id = :excepcion.Id].FSC_Estado__c, 'Debe aprobar el hijo.');
	}

	@IsTest
	static void shouldCloseLoanWhenClientRejectsCondition() {
		FSC_Excepcion__c excepcion = getExcepcion(RLA_CONDICIONADA);
		forceAuthorization();

		Test.startTest();
		FSC_ExcepcionesCreditoController.responderCondicionCliente(excepcion.Id, false);
		Test.stopTest();

		ResidentialLoanApplication solicitud = getSolicitud(RLA_CONDICIONADA);
		Assert.areEqual('Rechazada', [SELECT FSC_Estado__c FROM FSC_Excepcion__c WHERE Id = :excepcion.Id].FSC_Estado__c, 'Debe rechazar el hijo.');
		Assert.areEqual('Cerrada Perdida', solicitud.Status, 'Debe cerrar la solicitud.');
		Assert.areEqual('Rechazada por cliente', solicitud.FSC_Subestado__c, 'Debe distinguir el rechazo del cliente.');
	}

	@IsTest
	static void shouldApproveChildWhenAssignedApprovalIsCompleted() {
		ResidentialLoanApplication solicitud = getSolicitud(RLA_ELEGIBLE);
		FSC_ExcepcionesCreditoController.FSC_OpcionExcepcion option = getOption(TIPO_NEGOCIOS);
		forceAuthorization();
		Id excepcionId = FSC_ExcepcionesCreditoController.solicitarExcepcion(solicitud.Id, option.tipo, option.detalle, 'Justificación para aprobar');

		Test.startTest();
		FSC_ExcepcionesCreditoController.aprobarExcepcion(excepcionId);
		Test.stopTest();

		Assert.areEqual(
			'Aprobada',
			[SELECT FSC_Estado__c FROM FSC_Excepcion__c WHERE Id = :excepcionId].FSC_Estado__c,
			'La decisión debe actualizar el hijo.'
		);
	}

	@IsTest
	static void shouldRejectChildAndCloseParentWithSingleAuthorizedUpdate() {
		ResidentialLoanApplication solicitud = getSolicitud(RLA_ELEGIBLE);
		FSC_ExcepcionesCreditoController.FSC_OpcionExcepcion option = getOption(TIPO_NEGOCIOS);
		forceAuthorization();
		Id excepcionId = FSC_ExcepcionesCreditoController.solicitarExcepcion(
			solicitud.Id,
			option.tipo,
			option.detalle,
			'Justificación para rechazar'
		);

		Test.startTest();
		FSC_ExcepcionesCreditoController.rechazarExcepcion(excepcionId, 'Riesgo no aceptado');
		Test.stopTest();

		FSC_Excepcion__c excepcion = [SELECT FSC_Estado__c FROM FSC_Excepcion__c WHERE Id = :excepcionId];
		ResidentialLoanApplication updated = [
			SELECT Status, FSC_Subestado__c, FSC_Motivo_Rechazo__c
			FROM ResidentialLoanApplication
			WHERE Id = :solicitud.Id
		];
		Assert.areEqual('Rechazada', excepcion.FSC_Estado__c, 'La acción final debe rechazar la excepción hija.');
		Assert.areEqual('Cerrada Perdida', updated.Status, 'El rechazo debe cerrar la solicitud una sola vez.');
		Assert.areEqual('Rechazado por análisis', updated.FSC_Subestado__c, 'Debe conservar el origen del rechazo.');
		Assert.areEqual('Riesgo no aceptado', updated.FSC_Motivo_Rechazo__c, 'Debe conservar el motivo informado por el aprobador.');
	}

	@IsTest
	static void shouldRejectInvalidSubstatusWhenRequestIsAttempted() {
		ResidentialLoanApplication solicitud = getSolicitud(RLA_NO_ELEGIBLE);
		FSC_ExcepcionesCreditoController.FSC_OpcionExcepcion option = getOption(TIPO_NEGOCIOS);
		forceAuthorization();

		Test.startTest();
		try {
			FSC_ExcepcionesCreditoController.solicitarExcepcion(solicitud.Id, option.tipo, option.detalle, 'Motivo');
			Assert.fail('Se esperaba un error por subestado no elegible.');
		} catch (AuraHandledException exceptionInstance) {
			Assert.isNotNull(exceptionInstance, 'Debe devolver un error controlado.');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldRejectUnknownConfigurationWhenRequestIsAttempted() {
		ResidentialLoanApplication solicitud = getSolicitud(RLA_ELEGIBLE);
		forceAuthorization();

		Test.startTest();
		try {
			FSC_ExcepcionesCreditoController.solicitarExcepcion(solicitud.Id, 'Tipo inexistente', 'Detalle inexistente', 'Motivo');
			Assert.fail('Se esperaba un error por configuración inexistente.');
		} catch (AuraHandledException exceptionInstance) {
			Assert.isNotNull(exceptionInstance, 'Debe devolver un error controlado.');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldRejectNullSolicitudWhenContextIsRequested() {
		forceAuthorization();
		Test.startTest();
		try {
			FSC_ExcepcionesCreditoController.getContextoExcepcion(null);
			Assert.fail('Se esperaba un error por solicitud nula.');
		} catch (AuraHandledException exceptionInstance) {
			Assert.isNotNull(exceptionInstance, 'Debe controlar el Id nulo.');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldRejectLoanIdWhenChildExceptionIsRequired() {
		ResidentialLoanApplication solicitud = getSolicitud(RLA_ELEGIBLE);
		forceAuthorization();

		Test.startTest();
		try {
			FSC_ExcepcionesCreditoController.responderCondicionCliente(solicitud.Id, true);
			Assert.fail('El registro padre ya no debe aceptarse como excepción.');
		} catch (AuraHandledException exceptionInstance) {
			Assert.isNotNull(exceptionInstance, 'Debe rechazar explícitamente el identificador del modelo eliminado.');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldRejectBlankConditionWhenConditionalApprovalIsAttempted() {
		forceAuthorization();
		Test.startTest();
		try {
			FSC_ExcepcionesCreditoController.aprobarExcepcionConCondicion(null, ' ');
			Assert.fail('Se esperaba un error por condición vacía.');
		} catch (AuraHandledException exceptionInstance) {
			Assert.isNotNull(exceptionInstance, 'Debe controlar la condición vacía.');
		}
		Test.stopTest();
	}

	private static void forceAuthorization() {
		FSC_ExcepcionesCreditoController.testForceAuthorized = true;
		FSC_ExcepcionApprovalService.testForceAuthorized = true;
	}

	private static ResidentialLoanApplication getSolicitud(String name) {
		return [
			SELECT Id, Status, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Name = :name
			LIMIT 1
		];
	}

	private static FSC_Excepcion__c getExcepcion(String solicitudName) {
		return [
			SELECT Id, FSC_Estado__c, FSC_Condicion__c
			FROM FSC_Excepcion__c
			WHERE FSC_Solicitud_Prestamo__r.Name = :solicitudName
			LIMIT 1
		];
	}

	private static FSC_ExcepcionesCreditoController.FSC_OpcionExcepcion getOption(String tipo) {
		for (FSC_ExcepcionesCreditoController.FSC_OpcionExcepcion option : FSC_ExcepcionesCreditoController.getOpcionesExcepcion()) {
			if (option.tipo == tipo) {
				return option;
			}
		}
		Assert.fail('No se encontró una opción configurada para: ' + tipo);
		return null;
	}
}