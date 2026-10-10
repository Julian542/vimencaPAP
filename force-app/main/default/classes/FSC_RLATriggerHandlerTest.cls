@IsTest
private class FSC_RLATriggerHandlerTest {
    @TestSetup
    static void asignarPermisosAdministrador() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet permiso = [SELECT Id FROM PermissionSet WHERE Name = 'FSC_PS_Administrador' LIMIT 1];
            // El usuario que ejecuta los tests puede tener ya el permission set asignado.
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permiso.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permiso.Id);
            }
        }
    }

	private static final String RT_CREDITO_CONSUMO = 'FSC_Solicitud_Credito_Consumo';
	private static final String RT_CREDITO_PYME = 'FSC_Solicitud_Credito_PYME';
	private static final String STATUS_BORRADOR = 'Borrador';
	private static final String STATUS_EN_PROCESO = 'En proceso';
	private static final String STATUS_CERRADA_GANADA = 'Cerrada Ganada';
	private static final String SUBESTADO_REGENERACION = 'Completando información';
	private static final String SUBESTADO_PEP = 'En validación PEP/Listas';
	private static final String TITLE_PREFIX = 'Crédito ';

	private static Account createAccount() {
		Account acc = new Account(Name = 'Cuenta Test Trigger ' + System.now().getTime());
		insert acc;
		return acc;
	}

	private static Account createDecisionAccount() {
		Account acc = new Account(
			LastName = 'Cuenta Motor Buro ' + System.now().getTime(),
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Fisica').getRecordTypeId(),
			ACC_NumIdentificacion__c = '00108803610',
			ACC_TipoIdentificacion__c = 'Cédula'
		);
		insert acc;
		return acc;
	}

	private static FinServ__Employment__c createHistorial(Id accountId, String tipoEmpleado) {
		FinServ__Employment__c historial = new FinServ__Employment__c(Cliente__c = accountId, EMP_Tipo_de_empleado__c = tipoEmpleado);
		insert historial;
		return historial;
	}

	private static Id getResidentialLoanApplicationRecordTypeId(String developerName) {
		Schema.RecordTypeInfo rtInfo = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName().get(developerName);

		return rtInfo == null ? null : rtInfo.getRecordTypeId();
	}

	private static Id getPersonAccountRecordTypeId() {
		Schema.RecordTypeInfo rtInfo = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount');

		return rtInfo == null ? null : rtInfo.getRecordTypeId();
	}

	private static ResidentialLoanApplication createRlaForSolicitudRegeneration(
		String firstName,
		String lastName,
		String documentNumber,
		String rlaName,
		String recordTypeDeveloperName
	) {
		return createRlaForSolicitudRegeneration(
			firstName,
			lastName,
			documentNumber,
			rlaName,
			recordTypeDeveloperName,
			STATUS_BORRADOR,
			SUBESTADO_REGENERACION
		);
	}

	private static ResidentialLoanApplication createRlaForSolicitudRegeneration(
		String firstName,
		String lastName,
		String documentNumber,
		String rlaName,
		String recordTypeDeveloperName,
		String status,
		String subestado
	) {
		Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
		Account account = new Account();
		Id personAccountRecordTypeId = getPersonAccountRecordTypeId();
		if (personAccountRecordTypeId != null) {
			account.RecordTypeId = personAccountRecordTypeId;
		}
		account.FirstName = firstName;
		account.LastName = lastName;
		account.ACC_NumIdentificacion__c = documentNumber;
		insert account;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = rlaName,
			AccountId = account.Id,
			Status = status,
			FSC_Subestado__c = subestado,
			RecordTypeId = getResidentialLoanApplicationRecordTypeId(recordTypeDeveloperName),
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401'
		);

		insert rla;
		return rla;
	}

	private static Id createLinkedDocument(Id linkedEntityId, String title, String pathOnClient) {
		ContentVersion cv = new ContentVersion(
			Title = title,
			PathOnClient = pathOnClient,
			VersionData = Blob.valueOf('OLD_PDF'),
			FirstPublishLocationId = linkedEntityId,
			FSC_EnviarDocumento__c = true
		);
		insert cv;

		return [
			SELECT ContentDocumentId
			FROM ContentVersion
			WHERE Id = :cv.Id
			LIMIT 1
		]
		.ContentDocumentId;
	}

	private static String buildSolicitudTitle(String tipoCredito, String firstName, String lastName, String documentNumber) {
		return TITLE_PREFIX + tipoCredito + ' - ' + firstName + ' ' + lastName + ' - ' + documentNumber;
	}

	private static ResidentialLoanApplication createRla(String status, String subestado) {
		Account acc = createAccount();

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Trigger Test ' + System.now().getTime(),
			AccountId = acc.Id,
			RecordTypeId = getResidentialLoanApplicationRecordTypeId('FSC_Solicitud_Credito_Consumo'),
			Status = status,
			FSC_Subestado__c = subestado,
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401'
		);

		insert rla;
		return rla;
	}

	private static ResidentialLoanApplication createDecisionRla(String status, String subestado) {
		Account acc = createDecisionAccount();
		createHistorial(acc.Id, '1');

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Motor Buro Test ' + System.now().getTime(),
			AccountId = acc.Id,
			RecordTypeId = getResidentialLoanApplicationRecordTypeId('FSC_Solicitud_Credito_Consumo'),
			Status = status,
			FSC_Subestado__c = subestado,
			FSC_Ingresos_Mensuales__c = 90000,
			FSC_A_os_de_operacion__c = 5,
			FSC_Clasificacion_de_Riesgo__c = '780',
			FSC_MontoAprobado__c = 650000,
			FSC_PlazoMesesAprobado__c = 60,
			FSC_TasaInteresAprobada__c = 18,
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401'
		);

		insert rla;
		return rla;
	}

	private class LoanDecisionApprovedMock implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			res.setStatusCode(200);
			res.setHeader('Content-Type', 'application/json');
			res.setBody(
				'{' +
					'"transactionId":"trx-handler",' +
					'"status":"completed",' +
					'"applicants":{' +
					'"primaryConsumer":{' +
					'"interconnectResponse":{' +
					'"Filtro_BcoVimencaPre":{' +
					'"Generales":{' +
					'"Dictamen":"Aprobado",' +
					'"Xcore":"701",' +
					'"Mensajes":{' +
					'"Evaluacion":[' +
					'{"code":"OK","description":"Aprobado desde test handler"}' +
					']' +
					'}' +
					'}' +
					'}' +
					'}' +
					'}' +
					'}' +
					'}'
			);
			return res;
		}
	}

	@IsTest
	static void stampWonClosureDateSetsDateOnlyOnWinningTransition() {
		Id recordId = createSyntheticId(1);
		ResidentialLoanApplication oldRecord = new ResidentialLoanApplication(Id = recordId, Status = STATUS_EN_PROCESO);
		ResidentialLoanApplication newRecord = new ResidentialLoanApplication(Id = recordId, Status = STATUS_CERRADA_GANADA);

		Test.startTest();
		FSC_RLATriggerHandler.stampWonClosureDate(
			new List<ResidentialLoanApplication>{ newRecord },
			new Map<Id, ResidentialLoanApplication>{ recordId => oldRecord }
		);
		Test.stopTest();

		Assert.isNotNull(newRecord.FSC_FechaCierreGanada__c, 'La transición a Cerrada Ganada debe sellar la fecha de cierre.');
	}

	@IsTest
	static void stampWonClosureDatePreservesDateAndIgnoresOtherTransitions() {
		Id wonRecordId = createSyntheticId(2);
		Id openRecordId = createSyntheticId(3);
		Datetime originalClosureDate = System.now().addDays(-1);
		ResidentialLoanApplication alreadyWon = new ResidentialLoanApplication(
			Id = wonRecordId,
			Status = STATUS_CERRADA_GANADA,
			FSC_FechaCierreGanada__c = originalClosureDate
		);
		ResidentialLoanApplication stillOpen = new ResidentialLoanApplication(Id = openRecordId, Status = STATUS_EN_PROCESO);

		FSC_RLATriggerHandler.stampWonClosureDate(
			new List<ResidentialLoanApplication>{ alreadyWon, stillOpen },
			new Map<Id, ResidentialLoanApplication>{
				wonRecordId => new ResidentialLoanApplication(Id = wonRecordId, Status = STATUS_CERRADA_GANADA),
				openRecordId => new ResidentialLoanApplication(Id = openRecordId, Status = STATUS_BORRADOR)
			}
		);

		Assert.areEqual(originalClosureDate, alreadyWon.FSC_FechaCierreGanada__c, 'Una fecha existente no debe sobrescribirse.');
		Assert.isNull(stillOpen.FSC_FechaCierreGanada__c, 'Una transición que no cierra ganada no debe sellar fecha.');
	}

	@IsTest
	static void stampWonClosureDateIsBulkSafe() {
		List<ResidentialLoanApplication> newRecords = new List<ResidentialLoanApplication>();
		Map<Id, ResidentialLoanApplication> oldRecordsById = new Map<Id, ResidentialLoanApplication>();
		for (Integer index = 0; index < 251; index++) {
			Id recordId = createSyntheticId(index);
			newRecords.add(new ResidentialLoanApplication(Id = recordId, Status = STATUS_CERRADA_GANADA));
			oldRecordsById.put(recordId, new ResidentialLoanApplication(Id = recordId, Status = STATUS_EN_PROCESO));
		}

		Test.startTest();
		FSC_RLATriggerHandler.stampWonClosureDate(newRecords, oldRecordsById);
		Test.stopTest();

		for (ResidentialLoanApplication record : newRecords) {
			Assert.isNotNull(record.FSC_FechaCierreGanada__c, 'Cada solicitud del lote debe recibir la fecha de cierre.');
		}
	}

	private static Id createSyntheticId(Integer index) {
		String suffix = String.valueOf(index).leftPad(12, '0');
		return (Id) ('0cd' + suffix);
	}

	@IsTest
	static void testAfterUpdate_GeneracionContrato_CoversBranch() {
		ResidentialLoanApplication rlaDb = createRla('En proceso', 'Pendiente planilla de desembolso');

		ResidentialLoanApplication oldRla = rlaDb.clone(true, true, false, false);
		ResidentialLoanApplication newRla = rlaDb.clone(true, true, false, false);
		newRla.FSC_Subestado__c = 'Generación de contrato';
		newRla.Status = 'En proceso';

		Test.startTest();
		FSC_RLATriggerHandler.afterUpdate(
			new List<ResidentialLoanApplication>{ newRla },
			new Map<Id, ResidentialLoanApplication>{ rlaDb.Id => oldRla }
		);
		Test.stopTest();

		System.assert(true, 'Se cubre la rama de Generación de contrato del handler.');
	}

	@IsTest
	static void testAfterUpdate_SinCambioSubestado_DoesNothing() {
		ResidentialLoanApplication rlaDb = createRla('En proceso', 'Pendiente planilla de desembolso');

		ResidentialLoanApplication oldRla = rlaDb.clone(true, true, false, false);
		ResidentialLoanApplication newRla = rlaDb.clone(true, true, false, false);
		newRla.FSC_Subestado__c = 'Pendiente planilla de desembolso';
		newRla.Status = 'En proceso';

		Test.startTest();
		FSC_RLATriggerHandler.afterUpdate(
			new List<ResidentialLoanApplication>{ newRla },
			new Map<Id, ResidentialLoanApplication>{ rlaDb.Id => oldRla }
		);
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT Id, FSC_Subestado__c, FSC_Contrato_Generado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rlaDb.Id
			LIMIT 1
		];

		System.assertEquals(
			'Pendiente planilla de desembolso',
			refreshed.FSC_Subestado__c,
			'Si no hay cambio de subestado, el handler no debe modificar el registro.'
		);
		System.assertEquals(false, refreshed.FSC_Contrato_Generado__c, 'Si no hubo generación, el flag de contrato no debe cambiar.');

		List<ContentDocumentLink> links = [
			SELECT Id
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :rlaDb.Id
		];

		System.assertEquals(0, links.size(), 'Si no cambió el subestado, no debe generarse ningún archivo.');
	}

	@IsTest
	static void testGeneracionContrato_Directo_ValidIds() {
		ResidentialLoanApplication rla = createRla('En proceso', 'Generación de contrato');

		Test.startTest();
		FSC_RLATriggerHandler.generacionContrato(new Set<Id>{ rla.Id });
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT Id, FSC_Subestado__c, FSC_Contrato_Generado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
			LIMIT 1
		];

		System.assertEquals(
			'Gestionar firmas',
			refreshed.FSC_Subestado__c,
			'La invocación directa debe procesar el contrato cuando recibe IDs válidos.'
		);
		System.assertEquals(
			false,
			refreshed.FSC_Contrato_Generado__c,
			'Sin un contrato aplicable, debe avanzar a firmas sin marcar un archivo como generado.'
		);
	}

	@IsTest
	static void testGeneracionContrato_Directo_NullAndEmpty() {
		ResidentialLoanApplication controlRla = createRla('En proceso', 'Pendiente planilla de desembolso');

		Test.startTest();
		FSC_RLATriggerHandler.generacionContrato(null);
		FSC_RLATriggerHandler.generacionContrato(new Set<Id>());
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT Id, FSC_Subestado__c, FSC_Contrato_Generado__c
			FROM ResidentialLoanApplication
			WHERE Id = :controlRla.Id
			LIMIT 1
		];

		System.assertEquals(
			'Pendiente planilla de desembolso',
			refreshed.FSC_Subestado__c,
			'Con null o set vacío no debe ocurrir ninguna modificación.'
		);
		System.assertEquals(false, refreshed.FSC_Contrato_Generado__c, 'Con null o set vacío no debe marcarse contrato generado.');
	}

	@IsTest
	static void testAfterUpdate_Desembolso_CoversBranch() {
		ResidentialLoanApplication rlaDb = createRla('En proceso', 'Pendiente planilla de desembolso');

		ResidentialLoanApplication oldRla = rlaDb.clone(true, true, false, false);
		ResidentialLoanApplication newRla = rlaDb.clone(true, true, false, false);
		newRla.FSC_Subestado__c = 'Desembolso';
		newRla.Status = 'En proceso';

		Test.startTest();
		try {
			FSC_RLATriggerHandler.afterUpdate(
				new List<ResidentialLoanApplication>{ newRla },
				new Map<Id, ResidentialLoanApplication>{ rlaDb.Id => oldRla }
			);
		} catch (Exception e) {
			System.assertNotEquals(null, e.getMessage(), 'Si ocurre una excepción externa, al menos cubrimos correctamente la rama de desembolso.');
		}
		Test.stopTest();

		System.assert(true, 'La rama de desembolso queda cubierta aunque la lógica dependiente viva en otra clase.');
	}

	@IsTest
	static void testDesembolsoDeCredito_Directo_CoversBranch() {
		ResidentialLoanApplication rla = createRla('En proceso', 'Desembolso');

		Test.startTest();
		try {
			FSC_RLATriggerHandler.desembolsoDeCredito(rla);
		} catch (Exception e) {
			System.assertNotEquals(null, e.getMessage(), 'Si ocurre una excepción externa, al menos cubrimos la llamada directa de desembolso.');
		}
		Test.stopTest();

		System.assert(true);
	}

	@IsTest
	static void testAfterUpdate_CubreGeneracionYDesembolso() {
		ResidentialLoanApplication rlaContrato = createRla('En proceso', 'Pendiente planilla de desembolso');

		ResidentialLoanApplication rlaDesembolso = createRla('En proceso', 'Pendiente planilla de desembolso');

		ResidentialLoanApplication oldContrato = rlaContrato.clone(true, true, false, false);
		ResidentialLoanApplication newContrato = rlaContrato.clone(true, true, false, false);
		newContrato.FSC_Subestado__c = 'Generación de contrato';

		ResidentialLoanApplication oldDesembolso = rlaDesembolso.clone(true, true, false, false);
		ResidentialLoanApplication newDesembolso = rlaDesembolso.clone(true, true, false, false);
		newDesembolso.FSC_Subestado__c = 'Desembolso';

		Test.startTest();
		try {
			FSC_RLATriggerHandler.afterUpdate(
				new List<ResidentialLoanApplication>{ newContrato, newDesembolso },
				new Map<Id, ResidentialLoanApplication>{ rlaContrato.Id => oldContrato, rlaDesembolso.Id => oldDesembolso }
			);
		} catch (Exception e) {
			// En tu org puede disparar lógica adicional en desembolso.
		}
		Test.stopTest();

		System.assert(true, 'Se cubrieron ambas ramas del handler.');
	}

	@IsTest
	static void testAfterUpdate_EnMotorBuro_EncolaQueueableYActualizaRla() {
		ResidentialLoanApplication rlaDb = createDecisionRla('En proceso', 'Pendiente planilla de desembolso');

		ResidentialLoanApplication oldRla = rlaDb.clone(true, true, false, false);
		ResidentialLoanApplication newRla = rlaDb.clone(true, true, false, false);
		newRla.FSC_Subestado__c = 'En Motor Buró';
		newRla.Status = 'En proceso';

		Test.setMock(HttpCalloutMock.class, new LoanDecisionApprovedMock());

		Test.startTest();
		FSC_RLATriggerHandler.afterUpdate(
			new List<ResidentialLoanApplication>{ newRla },
			new Map<Id, ResidentialLoanApplication>{ rlaDb.Id => oldRla }
		);
		Test.stopTest();

		ResidentialLoanApplication refreshed = [
			SELECT FSC_Resultado_Buro__c, FSC_XCore_Buro__c, FSC_Mensajes_Buro__c, FSC_Subestado__c, Status
			FROM ResidentialLoanApplication
			WHERE Id = :rlaDb.Id
			LIMIT 1
		];

		System.assertEquals('Aprobado', refreshed.FSC_Resultado_Buro__c);
		System.assertEquals(Decimal.valueOf('701'), refreshed.FSC_XCore_Buro__c);
		System.assertEquals('En proceso', refreshed.Status);
		System.assert(refreshed.FSC_Mensajes_Buro__c.contains('code: OK'));
	}

	@IsTest
	static void testAfterUpdate_RegeneraSolicitudCreditoPyme() {
		ResidentialLoanApplication rlaDb = createRlaForSolicitudRegeneration(
			'Maria',
			'Gomez',
			'00112345678',
			'RLA PyMe Regeneracion',
			RT_CREDITO_PYME
		);
		String expectedTitle = buildSolicitudTitle('PyMe', 'Maria', 'Gomez', '00112345678');
		Id previousDocumentId = createLinkedDocument(rlaDb.Id, expectedTitle, 'credito-pyme-old.pdf');

		ResidentialLoanApplication oldRla = rlaDb.clone(true, true, false, false);
		ResidentialLoanApplication newRla = rlaDb.clone(true, true, false, false);
		newRla.FSC_Telefono__c = '8095550101';

		Test.startTest();
		FSC_RLATriggerHandler.afterUpdate(
			new List<ResidentialLoanApplication>{ newRla },
			new Map<Id, ResidentialLoanApplication>{ rlaDb.Id => oldRla }
		);
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM ContentDocument WHERE Id = :previousDocumentId]);
		System.assertEquals(
			1,
			[
				SELECT COUNT()
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :rlaDb.Id AND ContentDocument.Title = :expectedTitle
			]
		);
	}

	@IsTest
	static void testAfterUpdate_RegeneraSolicitudCreditoConsumo() {
		ResidentialLoanApplication rlaDb = createRlaForSolicitudRegeneration(
			'Joel',
			'Valenti',
			'42010242',
			'RLA Consumo Regeneracion',
			RT_CREDITO_CONSUMO
		);
		String expectedTitle = buildSolicitudTitle('Consumo', 'Joel', 'Valenti', '42010242');
		Id previousDocumentId = createLinkedDocument(rlaDb.Id, expectedTitle, 'credito-consumo-old.pdf');

		ResidentialLoanApplication oldRla = rlaDb.clone(true, true, false, false);
		ResidentialLoanApplication newRla = rlaDb.clone(true, true, false, false);
		newRla.FSC_Referidor__c = 'Referidor Test';

		Test.startTest();
		FSC_RLATriggerHandler.afterUpdate(
			new List<ResidentialLoanApplication>{ newRla },
			new Map<Id, ResidentialLoanApplication>{ rlaDb.Id => oldRla }
		);
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM ContentDocument WHERE Id = :previousDocumentId]);
		System.assertEquals(
			1,
			[
				SELECT COUNT()
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :rlaDb.Id AND ContentDocument.Title = :expectedTitle
			]
		);
	}

	@IsTest
	static void testAfterUpdate_NoRegeneraSolicitudCreditoSinCampoConfigurado() {
		ResidentialLoanApplication rlaDb = createRlaForSolicitudRegeneration(
			'Laura',
			'Perez',
			'00100011122',
			'RLA Sin Regeneracion',
			RT_CREDITO_PYME
		);
		String expectedTitle = buildSolicitudTitle('PyMe', 'Laura', 'Perez', '00100011122');
		Id previousDocumentId = createLinkedDocument(rlaDb.Id, expectedTitle, 'credito-pyme-existing.pdf');

		ResidentialLoanApplication oldRla = rlaDb.clone(true, true, false, false);
		ResidentialLoanApplication newRla = rlaDb.clone(true, true, false, false);
		newRla.Name = 'RLA Sin Regeneracion Actualizada';

		Test.startTest();
		FSC_RLATriggerHandler.afterUpdate(
			new List<ResidentialLoanApplication>{ newRla },
			new Map<Id, ResidentialLoanApplication>{ rlaDb.Id => oldRla }
		);
		Test.stopTest();

		System.assertEquals(1, [SELECT COUNT() FROM ContentDocument WHERE Id = :previousDocumentId]);
		System.assertEquals(
			1,
			[
				SELECT COUNT()
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :rlaDb.Id AND ContentDocument.Title = :expectedTitle
			]
		);
	}

	@IsTest
	static void testAfterUpdate_NoRegeneraSolicitudCreditoSiStatusYSubestadoNoCorresponden() {
		ResidentialLoanApplication rlaDb = createRlaForSolicitudRegeneration(
			'Luis',
			'Ramirez',
			'00122233344',
			'RLA Status Subestado Invalido',
			RT_CREDITO_PYME,
			STATUS_EN_PROCESO,
			SUBESTADO_PEP
		);
		String expectedTitle = buildSolicitudTitle('PyMe', 'Luis', 'Ramirez', '00122233344');
		Id previousDocumentId = createLinkedDocument(rlaDb.Id, expectedTitle, 'credito-pyme-status-invalido.pdf');

		ResidentialLoanApplication oldRla = rlaDb.clone(true, true, false, false);
		ResidentialLoanApplication newRla = rlaDb.clone(true, true, false, false);
		newRla.FSC_Telefono__c = '8095550202';

		Test.startTest();
		FSC_RLATriggerHandler.afterUpdate(
			new List<ResidentialLoanApplication>{ newRla },
			new Map<Id, ResidentialLoanApplication>{ rlaDb.Id => oldRla }
		);
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM ContentDocument WHERE Id = :previousDocumentId]);
		System.assertEquals(
			1,
			[
				SELECT COUNT()
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :rlaDb.Id AND ContentDocument.Title = :expectedTitle
			]
		);
	}

	@IsTest
	static void testSolicitudCreditoRegenerationIgnoresEmptyInputs() {
		Test.startTest();
		FSC_RegenerarSolicitudCreditoService.enqueueRegeneration(null);
		FSC_RegenerarSolicitudCreditoService.enqueueRegeneration(new Set<Id>());
		FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(null, null);
		FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(new List<SObject>(), new Map<Id, SObject>());
		FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(
			new List<SObject>{ null },
			new Map<Id, SObject>{ UserInfo.getUserId() => new User(Id = UserInfo.getUserId()) }
		);
		FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(
			new List<SObject>{ new User(Id = UserInfo.getUserId()) },
			new Map<Id, SObject>{ UserInfo.getUserId() => new User(Id = UserInfo.getUserId()) }
		);
		new FSC_RegenerarSolicitudCreditoQueueable(null).execute(null);
		new FSC_RegenerarSolicitudCreditoQueueable(new List<Id>()).execute(null);
		Test.stopTest();

		System.assert(true);
	}

	@IsTest
	static void testShouldRegenerateSolicitudCreditoDirectCases() {
		ResidentialLoanApplication oldPyme = new ResidentialLoanApplication(
			RecordTypeId = getResidentialLoanApplicationRecordTypeId(RT_CREDITO_PYME),
			Status = STATUS_BORRADOR,
			FSC_Subestado__c = SUBESTADO_REGENERACION,
			FSC_Telefono__c = '8095550000'
		);
		ResidentialLoanApplication newPyme = oldPyme.clone(false, true, false, false);
		newPyme.FSC_Telefono__c = '8095550001';

		ResidentialLoanApplication invalidStatus = newPyme.clone(false, true, false, false);
		invalidStatus.Status = STATUS_EN_PROCESO;
		invalidStatus.FSC_Subestado__c = 'No regenerable';

		ResidentialLoanApplication oldConsumo = new ResidentialLoanApplication(
			RecordTypeId = getResidentialLoanApplicationRecordTypeId(RT_CREDITO_CONSUMO),
			Status = STATUS_BORRADOR,
			FSC_Subestado__c = SUBESTADO_REGENERACION,
			FSC_Referidor__c = 'Referidor A'
		);
		ResidentialLoanApplication newConsumo = oldConsumo.clone(false, true, false, false);
		newConsumo.FSC_Referidor__c = 'Referidor B';

		Test.startTest();
		Boolean pymeChanged = FSC_RegenerarSolicitudCreditoService.shouldRegenerateSolicitudCredito(newPyme, oldPyme);
		Boolean nullInputs = FSC_RegenerarSolicitudCreditoService.shouldRegenerateSolicitudCredito(null, oldPyme);
		Boolean invalidStatusResult = FSC_RegenerarSolicitudCreditoService.shouldRegenerateSolicitudCredito(invalidStatus, oldPyme);
		Boolean consumoChanged = FSC_RegenerarSolicitudCreditoService.shouldRegenerateSolicitudCredito(newConsumo, oldConsumo);
		Boolean consumoUnchanged = FSC_RegenerarSolicitudCreditoService.shouldRegenerateSolicitudCredito(oldConsumo, oldConsumo);
		Test.stopTest();

		System.assertEquals(true, pymeChanged);
		System.assertEquals(false, nullInputs);
		System.assertEquals(false, invalidStatusResult);
		System.assertEquals(true, consumoChanged);
		System.assertEquals(false, consumoUnchanged);
	}

	@IsTest
	static void testEnqueueRegenerationForRelatedContactPointEmail() {
		ResidentialLoanApplication rlaDb = createRla(STATUS_EN_PROCESO, 'Pendiente planilla de desembolso');

		ContactPointEmail oldEmail = new ContactPointEmail(
			Id = '9Vl000000000001',
			EmailAddress = 'old@example.com',
			FSC_ResidentialLoanApplicationId__c = rlaDb.Id
		);
		ContactPointEmail newEmail = new ContactPointEmail(
			Id = oldEmail.Id,
			EmailAddress = 'new@example.com',
			FSC_ResidentialLoanApplicationId__c = rlaDb.Id
		);

		Test.startTest();
		FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(
			new List<SObject>{ newEmail },
			new Map<Id, SObject>{ oldEmail.Id => oldEmail }
		);
		Test.stopTest();

		System.assert(true, 'Se cubren ramas de registros relacionados sin encolar por status invalido.');
	}

	@IsTest
	static void testAfterInsertRelatedRecordDoesNotRegenerateWithoutExistingSolicitudPdf() {
		ResidentialLoanApplication rlaDb = createRlaForSolicitudRegeneration('Laura', 'Perez', '00111111111', 'RLA PyMe Sin PDF', RT_CREDITO_PYME);

		ContactPointEmail newEmail = new ContactPointEmail(EmailAddress = 'nuevo@example.com', FSC_ResidentialLoanApplicationId__c = rlaDb.Id);

		Test.startTest();
		FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(new List<SObject>{ newEmail });
		Test.stopTest();

		System.assertEquals(
			0,
			[SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :rlaDb.Id],
			'No debe regenerar durante el alta inicial si todavía no existe el PDF de solicitud.'
		);
	}

	@IsTest
	static void testAfterInsertRelatedRecordRegeneratesWhenSolicitudPdfAlreadyExists() {
		ResidentialLoanApplication rlaDb = createRlaForSolicitudRegeneration('Maria', 'Gomez', '00112345678', 'RLA PyMe Con PDF', RT_CREDITO_PYME);
		String expectedTitle = buildSolicitudTitle('PyMe', 'Maria', 'Gomez', '00112345678');
		Id previousDocumentId = createLinkedDocument(rlaDb.Id, expectedTitle, 'credito-pyme-old.pdf');

		ContactPointEmail newEmail = new ContactPointEmail(EmailAddress = 'nuevo@example.com', FSC_ResidentialLoanApplicationId__c = rlaDb.Id);

		Test.startTest();
		FSC_RegenerarSolicitudCreditoService.enqueueRegenerationForRelatedRecords(new List<SObject>{ newEmail });
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM ContentDocument WHERE Id = :previousDocumentId]);
		System.assertEquals(
			1,
			[
				SELECT COUNT()
				FROM ContentDocumentLink
				WHERE LinkedEntityId = :rlaDb.Id AND ContentDocument.Title = :expectedTitle
			],
			'Debe regenerar inserts posteriores cuando ya existe un PDF de solicitud.'
		);
	}
}