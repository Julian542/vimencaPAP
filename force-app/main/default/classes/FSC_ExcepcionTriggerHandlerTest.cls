@IsTest
private class FSC_ExcepcionTriggerHandlerTest {
	private static final String BASE_RLA = 'RLA Trigger Base';

	@TestSetup
	static void setupTestData() {
		Account account = FSC_ExcepcionTestDataFactory.createAccount('2001', true);
		FSC_ExcepcionTestDataFactory.createSolicitud(account.Id, BASE_RLA, 'En Motor Buró', 1000, true);
	}

	@IsTest
	static void shouldInsert251RecordsWhenEachParentRemainsWithinLimit() {
		Account account = [SELECT Id FROM Account LIMIT 1];
		List<ResidentialLoanApplication> solicitudes = FSC_ExcepcionTestDataFactory.createSolicitudes(account.Id, 84, true);
		List<FSC_Excepcion__c> excepciones = new List<FSC_Excepcion__c>();
		for (Integer index = 0; index < 251; index++) {
			Integer parentIndex = index / 3;
			excepciones.add(FSC_ExcepcionTestDataFactory.buildExcepcion(solicitudes[parentIndex].Id, index, 'Aprobada', null));
		}

		Test.startTest();
		insert excepciones;
		Test.stopTest();

		Assert.areEqual(251, [SELECT COUNT() FROM FSC_Excepcion__c WHERE Id IN :excepciones], 'Debe procesar 251 hijos sin SOQL o DML en bucles.');
	}

	@IsTest
	static void shouldPartiallyRejectBatchWhenTwoIncomingRecordsExceedRemainingCapacity() {
		ResidentialLoanApplication solicitud = getBaseSolicitud();
		insert new List<FSC_Excepcion__c>{
			FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 1, 'Aprobada', null),
			FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 2, 'Rechazada', null)
		};
		List<FSC_Excepcion__c> incoming = new List<FSC_Excepcion__c>{
			FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 3, 'Pendiente', null),
			FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 4, 'Pendiente', null)
		};

		Test.startTest();
		Database.SaveResult[] results = Database.insert(incoming, false);
		Test.stopTest();

		Assert.isTrue(results[0].isSuccess(), 'El último cupo disponible debe aceptarse.');
		Assert.isFalse(results[1].isSuccess(), 'El registro que excede el tercer cupo debe rechazarse.');
		Assert.isTrue(
			results[1].getErrors()[0].getMessage().contains('límite máximo de 3 excepciones'),
			'El error bulk debe mantener el mensaje de negocio.'
		);
		Assert.areEqual(
			3,
			[SELECT COUNT() FROM FSC_Excepcion__c WHERE FSC_Solicitud_Prestamo__c = :solicitud.Id],
			'Solo deben persistir tres hijos.'
		);
	}

	@IsTest
	static void shouldUseValidationRuleMessageWhenSingleFourthRecordIsInserted() {
		ResidentialLoanApplication solicitud = getBaseSolicitud();
		insert new List<FSC_Excepcion__c>{
			FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 1, 'Aprobada', null),
			FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 2, 'Rechazada', null),
			FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 3, 'Pendiente', null)
		};

		Test.startTest();
		Database.SaveResult result = Database.insert(FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 4, 'Pendiente', null), false);
		Test.stopTest();

		Assert.isFalse(result.isSuccess(), 'La cuarta excepción individual debe bloquearse.');
		Assert.areEqual(
			'Se ha alcanzado el límite máximo de excepciones configurado para esta solicitud.',
			result.getErrors()[0].getMessage(),
			'La regla de validación debe identificar el límite configurable.'
		);
	}

	@IsTest
	static void shouldBlockDeleteWhenUserAttemptsToResetHistoricalCount() {
		ResidentialLoanApplication solicitud = getBaseSolicitud();
		FSC_Excepcion__c excepcion = FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 1, 'Aprobada', null);
		insert excepcion;

		Test.startTest();
		Database.DeleteResult result = Database.delete(excepcion, false);
		Test.stopTest();

		Assert.isFalse(result.isSuccess(), 'No debe permitir eliminar una excepción histórica.');
		Assert.isTrue(
			result.getErrors()[0].getMessage().contains('límite configurado es histórico'),
			'Debe explicar por qué se bloquea la eliminación.'
		);
	}

	@IsTest
	static void shouldCloseParentWhenChildTransitionsToRejected() {
		ResidentialLoanApplication solicitud = getBaseSolicitud();
		FSC_Excepcion__c excepcion = FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 1, 'Pendiente', null);
		insert excepcion;

		Test.startTest();
		FSC_ExcepcionTriggerHandler.afterUpdate(
			new Map<Id, FSC_Excepcion__c>{
				excepcion.Id => new FSC_Excepcion__c(
					Id = excepcion.Id,
					FSC_Estado__c = 'Rechazada',
					FSC_Solicitud_Prestamo__c = solicitud.Id
				)
			},
			new Map<Id, FSC_Excepcion__c>{
				excepcion.Id => new FSC_Excepcion__c(
					Id = excepcion.Id,
					FSC_Estado__c = 'Pendiente',
					FSC_Solicitud_Prestamo__c = solicitud.Id
				)
			}
		);
		Test.stopTest();

		ResidentialLoanApplication updated = [SELECT Status, FSC_Subestado__c FROM ResidentialLoanApplication WHERE Id = :solicitud.Id];
		Assert.areEqual('Cerrada Perdida', updated.Status, 'Un rechazo estándar debe cerrar el crédito.');
		Assert.areEqual('Rechazado por análisis', updated.FSC_Subestado__c, 'Debe registrar la causa operativa.');
	}

	@IsTest
	static void shouldPreserveAuthorizedRejectionContextWhenChildIsRejected() {
		ResidentialLoanApplication solicitud = getBaseSolicitud();
		FSC_Excepcion__c excepcion = FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 1, 'Pendiente', null);
		insert excepcion;

		Test.startTest();
		FSC_ExcepcionTriggerHandler.setRejectionContext(excepcion.Id, 'Rechazada por cliente', 'Cliente no acepta condición');
		try {
			FSC_ExcepcionTriggerHandler.afterUpdate(
				new Map<Id, FSC_Excepcion__c>{
					excepcion.Id => new FSC_Excepcion__c(
						Id = excepcion.Id,
						FSC_Estado__c = 'Rechazada',
						FSC_Solicitud_Prestamo__c = solicitud.Id
					)
				},
				new Map<Id, FSC_Excepcion__c>{
					excepcion.Id => new FSC_Excepcion__c(
						Id = excepcion.Id,
						FSC_Estado__c = 'Pendiente',
						FSC_Solicitud_Prestamo__c = solicitud.Id
					)
				}
			);
		} finally {
			FSC_ExcepcionTriggerHandler.clearRejectionContext(excepcion.Id);
		}
		Test.stopTest();

		ResidentialLoanApplication updated = [
			SELECT Status, FSC_Subestado__c, FSC_Motivo_Rechazo__c
			FROM ResidentialLoanApplication
			WHERE Id = :solicitud.Id
		];
		Assert.areEqual('Cerrada Perdida', updated.Status, 'El contexto no debe impedir el cierre del crédito.');
		Assert.areEqual('Rechazada por cliente', updated.FSC_Subestado__c, 'Debe conservar el origen autorizado del rechazo.');
		Assert.areEqual('Cliente no acepta condición', updated.FSC_Motivo_Rechazo__c, 'Debe conservar el motivo en una única actualización del padre.');
	}

	private static ResidentialLoanApplication getBaseSolicitud() {
		return [SELECT Id FROM ResidentialLoanApplication WHERE Name = :BASE_RLA LIMIT 1];
	}
}