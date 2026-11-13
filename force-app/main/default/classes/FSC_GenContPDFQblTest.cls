@IsTest
private class FSC_GenContPDFQblTest {
	@TestSetup
	static void setupData() {
		FSC_ExcepcionTestDataFactory.createAccount('Simple PDF 1027', true);
	}

	private static Account createAccount() {
		return [SELECT Id FROM Account LIMIT 1];
	}

	private static ResidentialLoanApplication createRla(String status, String subestado) {
		Account acc = createAccount();

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Queueable Test ' + System.now().getTime(),
			AccountId = acc.Id,
			RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
				.get('FSC_Solicitud_Credito_Consumo')
				.getRecordTypeId(),
			Status = status,
			FSC_Subestado__c = subestado,
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401'
		);

		insert rla;
		return rla;
	}

	@IsTest
	static void testExecute_GeneratesPdfAndUpdatesEligibleLoan() {
		ResidentialLoanApplication eligibleRla = createRla('En proceso', 'Generación de contrato');

		Test.startTest();
		System.enqueueJob(new FSC_GenerarContratoPDFQueueable(new List<Id>{ eligibleRla.Id }));
		Test.stopTest();

		ResidentialLoanApplication updatedRla = [
			SELECT Id, FSC_Subestado__c, FSC_Contrato_Generado__c, FSC_Pagares_y_Plantillas_Generados__c, FSC_LogErrores__c
			FROM ResidentialLoanApplication
			WHERE Id = :eligibleRla.Id
			LIMIT 1
		];

		System.assertEquals('Gestionar firmas', updatedRla.FSC_Subestado__c, 'El subestado debe actualizarse luego de generar el PDF.');
		System.assertEquals(false, updatedRla.FSC_Contrato_Generado__c, 'Un consumo sin contrato aplicable sólo debe avanzar de etapa.');
		System.assertEquals(null, updatedRla.FSC_LogErrores__c, 'No debe guardarse log de error cuando la generación fue exitosa.');

		List<ContentDocumentLink> links = [
			SELECT ContentDocumentId, ContentDocument.Title, LinkedEntityId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :eligibleRla.Id
		];

		Assert.areEqual(1, links.size(), 'Debe generar el pagaré simple sin crear contrato.');
		Assert.isTrue(links[0].ContentDocument.Title.startsWith('Pagare Individual '), 'Debe usar la plantilla simple.');
		Assert.isTrue(updatedRla.FSC_Pagares_y_Plantillas_Generados__c, 'El pagaré debe quedar marcado como generado.');
	}

	@IsTest
	static void testExecute_SkipsNonEligibleLoan() {
		ResidentialLoanApplication nonEligibleRla = createRla('En proceso', 'Pendiente planilla de desembolso');

		Test.startTest();
		System.enqueueJob(new FSC_GenerarContratoPDFQueueable(new List<Id>{ nonEligibleRla.Id }));
		Test.stopTest();

		ResidentialLoanApplication unchangedRla = [
			SELECT Id, FSC_Subestado__c, FSC_Contrato_Generado__c, FSC_LogErrores__c
			FROM ResidentialLoanApplication
			WHERE Id = :nonEligibleRla.Id
			LIMIT 1
		];

		System.assertEquals(
			'Pendiente planilla de desembolso',
			unchangedRla.FSC_Subestado__c,
			'No debe cambiar el subestado si el registro no era elegible.'
		);
		System.assertEquals(false, unchangedRla.FSC_Contrato_Generado__c, 'No debe marcarse contrato generado para registros no elegibles.');
		System.assertEquals(null, unchangedRla.FSC_LogErrores__c, 'No debe registrarse error para registros omitidos.');

		List<ContentDocumentLink> links = [
			SELECT Id
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :nonEligibleRla.Id
		];

		System.assertEquals(0, links.size(), 'No debe generarse archivo para registros no elegibles.');
	}

	@IsTest
	static void testExecute_MixedList_ProcessesOnlyEligible() {
		ResidentialLoanApplication eligibleRla = createRla('En proceso', 'Generación de contrato');
		ResidentialLoanApplication nonEligibleRla = createRla('En proceso', 'Pendiente planilla de desembolso');

		Test.startTest();
		System.enqueueJob(new FSC_GenerarContratoPDFQueueable(new List<Id>{ eligibleRla.Id, nonEligibleRla.Id }));
		Test.stopTest();

		Map<Id, ResidentialLoanApplication> rlaMap = new Map<Id, ResidentialLoanApplication>(
			[
				SELECT Id, FSC_Subestado__c, FSC_Contrato_Generado__c, FSC_LogErrores__c
				FROM ResidentialLoanApplication
				WHERE Id IN :new Set<Id>{ eligibleRla.Id, nonEligibleRla.Id }
			]
		);

		System.assertEquals('Gestionar firmas', rlaMap.get(eligibleRla.Id).FSC_Subestado__c, 'El elegible debe avanzar de subestado.');
		System.assertEquals(
			false,
			rlaMap.get(eligibleRla.Id).FSC_Contrato_Generado__c,
			'El consumo sin contrato aplicable no debe marcarse como generado.'
		);
		System.assertEquals(null, rlaMap.get(eligibleRla.Id).FSC_LogErrores__c, 'El elegible no debe registrar error si todo sale bien.');

		System.assertEquals(
			'Pendiente planilla de desembolso',
			rlaMap.get(nonEligibleRla.Id).FSC_Subestado__c,
			'El no elegible debe permanecer igual.'
		);
		System.assertEquals(false, rlaMap.get(nonEligibleRla.Id).FSC_Contrato_Generado__c, 'El no elegible no debe marcarse como generado.');
		System.assertEquals(null, rlaMap.get(nonEligibleRla.Id).FSC_LogErrores__c, 'El no elegible no debe registrar errores.');

		Integer eligibleLinkCount = [
			SELECT COUNT()
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :eligibleRla.Id
		];
		Integer nonEligibleLinkCount = [
			SELECT COUNT()
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :nonEligibleRla.Id
		];

		Assert.areEqual(1, eligibleLinkCount, 'Debe adjuntar el pagaré simple de la solicitud elegible.');
		System.assertEquals(0, nonEligibleLinkCount, 'No debe haber archivos para el registro no elegible.');
	}

	@IsTest
	static void testExecute_WhenGenerationFails_AccumulatesErrorLog() {
		ResidentialLoanApplication eligibleRla = createRla('En proceso', 'Generación de contrato');
		update new ResidentialLoanApplication(Id = eligibleRla.Id, FSC_LogErrores__c = 'Log anterior');

		FSC_GenerarContratoPDFQueueable.forcedGenerationErrorLoanApplicationIds = new Set<Id>{ eligibleRla.Id };

		Test.startTest();
		new FSC_GenerarContratoPDFQueueable(new List<Id>{ eligibleRla.Id }).execute(null);
		Test.stopTest();

		FSC_GenerarContratoPDFQueueable.forcedGenerationErrorLoanApplicationIds.clear();

		ResidentialLoanApplication failedRla = [
			SELECT Id, FSC_Subestado__c, FSC_Contrato_Generado__c, FSC_LogErrores__c
			FROM ResidentialLoanApplication
			WHERE Id = :eligibleRla.Id
			LIMIT 1
		];

		System.assertEquals('Generación de contrato', failedRla.FSC_Subestado__c, 'El subestado no debe avanzar cuando falla la generación.');
		System.assertEquals(false, failedRla.FSC_Contrato_Generado__c, 'No debe marcarse contrato generado cuando ocurre un error.');
		System.assertNotEquals(null, failedRla.FSC_LogErrores__c, 'Debe guardarse el error de generación en el log.');
		System.assert(failedRla.FSC_LogErrores__c.contains('Log anterior'), 'Debe preservarse el contenido previo del log.');
		System.assert(failedRla.FSC_LogErrores__c.contains('--------------------'), 'Debe agregarse el separador entre errores.');
		System.assert(failedRla.FSC_LogErrores__c.contains('Error generando documento PDF'), 'Debe guardarse un mensaje de error claro.');
		System.assert(
			failedRla.FSC_LogErrores__c.contains('Error de generación forzado para prueba.'),
			'Debe guardar el detalle del error ocurrido.'
		);

		Integer linkCount = [
			SELECT COUNT()
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :eligibleRla.Id
		];

		System.assertEquals(0, linkCount, 'No debe generarse archivo cuando falla la generación.');
	}

	@IsTest
	static void triggerGeneratesSimpleWithoutApprovalAssignment() {
		ResidentialLoanApplication application = createRla('En proceso', 'Documentación para contratos');
		Test.startTest();
		update new ResidentialLoanApplication(Id = application.Id, FSC_Subestado__c = 'Generación de pagarés y plantillas');
		ResidentialLoanApplication queued = [
			SELECT FSC_Subestado__c, FSC_UsuarioPagaresYContratos__c
			FROM ResidentialLoanApplication
			WHERE Id = :application.Id
		];
		Assert.areEqual('Generación de contrato', queued.FSC_Subestado__c, 'Debe iniciar la generación automática.');
		Assert.isNull(queued.FSC_UsuarioPagaresYContratos__c, 'No debe asignar un responsable de aprobación.');
		Test.stopTest();
		ResidentialLoanApplication generated = [
			SELECT FSC_Subestado__c, FSC_Pagares_y_Plantillas_Generados__c
			FROM ResidentialLoanApplication
			WHERE Id = :application.Id
		];
		Assert.areEqual('Gestionar firmas', generated.FSC_Subestado__c, 'Debe avanzar después de guardar el pagaré.');
		Assert.isTrue(generated.FSC_Pagares_y_Plantillas_Generados__c, 'Debe marcar el documento generado.');
		Assert.areEqual(0, [SELECT COUNT() FROM ProcessInstance WHERE TargetObjectId = :application.Id], 'No debe crear una aprobación.');
	}

	@IsTest
	static void simpleNotesContinueInBoundedJobs() {
		List<ResidentialLoanApplication> applications = FSC_ExcepcionTestDataFactory.createSolicitudes(createAccount().Id, 11, false);
		for (ResidentialLoanApplication application : applications)
			application.FSC_Subestado__c = 'Generación de contrato';
		insert applications;
		Set<Id> ids = new Map<Id, ResidentialLoanApplication>(applications).keySet();
		Test.startTest();
		new FSC_GenerarContratoPDFQueueable(new List<Id>(ids)).execute(null);
		Assert.areEqual(
			10,
			[SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId IN :ids],
			'El primer trabajo debe limitar la generación a diez PDFs.'
		);
		Test.stopTest();
		Assert.areEqual(11, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId IN :ids], 'El trabajo siguiente debe completar el lote.');
		Assert.areEqual(
			11,
			[SELECT COUNT() FROM ResidentialLoanApplication WHERE Id IN :ids AND FSC_Subestado__c = 'Gestionar firmas'],
			'Todas las solicitudes deben avanzar al guardar su documento.'
		);
	}

	@IsTest
	static void repeatedExecutionDoesNotDuplicateSimpleNote() {
		ResidentialLoanApplication application = createRla('En proceso', 'Generación de contrato');
		Test.startTest();
		new FSC_GenerarContratoPDFQueueable(new List<Id>{ application.Id }).execute(null);
		new FSC_GenerarContratoPDFQueueable(new List<Id>{ application.Id }).execute(null);
		Test.stopTest();
		Assert.areEqual(
			1,
			[SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :application.Id],
			'Reejecutar el trabajo no debe duplicar el pagaré.'
		);
	}

	@IsTest
	static void noteWithGuarantorIsGeneratedAutomatically() {
		ResidentialLoanApplication application = createRla('En proceso', 'Generación de contrato');
		update new ResidentialLoanApplication(Id = application.Id, FSC_Tipo_de_Garantia__c = 'Garantía Solidaria');
		insert new LoanApplicant(
			Name = 'Fiador simple',
			LoanApplicationId = application.Id,
			FSC_TipoSolicitante__c = 'Garante',
			FSC_TipoIdentificacion__c = 'Cédula',
			FSC_NumIdentificacion__c = '00100000501',
			FSC_Nombre__c = 'Ana',
			FSC_PrimerApellido__c = 'Prueba'
		);
		Test.startTest();
		System.enqueueJob(new FSC_GenerarContratoPDFQueueable(new List<Id>{ application.Id }));
		Test.stopTest();
		ContentDocumentLink link = [SELECT ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId = :application.Id LIMIT 1];
		Assert.isTrue(link.ContentDocument.Title.startsWith('Pagare Individual con Fiador '), 'Debe usar la variante simple con fiador.');
		Assert.areEqual(
			'Gestionar firmas',
			[SELECT FSC_Subestado__c FROM ResidentialLoanApplication WHERE Id = :application.Id].FSC_Subestado__c,
			'Debe avanzar al guardar el pagaré.'
		);
	}

	@IsTest
	static void approvalConditionsArePreserved() {
		ResidentialLoanApplication application = createRla('En proceso', 'Generación de contrato');
		update new ResidentialLoanApplication(
			Id = application.Id,
			FSC_Aprobado_con_Condiciones__c = true,
			FSC_MontoAprobado__c = 120000,
			FSC_PlazoMesesAprobado__c = 18,
			FSC_TasaInteresAprobada__c = 12
		);
		Test.startTest();
		System.enqueueJob(new FSC_GenerarContratoPDFQueueable(new List<Id>{ application.Id }));
		Test.stopTest();
		ResidentialLoanApplication generated = [
			SELECT FSC_MontoAprobado__c, FSC_PlazoMesesAprobado__c, FSC_TasaInteresAprobada__c
			FROM ResidentialLoanApplication
			WHERE Id = :application.Id
		];
		Assert.areEqual(120000, generated.FSC_MontoAprobado__c, 'Debe conservar el monto del comité.');
		Assert.areEqual(18, generated.FSC_PlazoMesesAprobado__c, 'Debe conservar el plazo del comité.');
		Assert.areEqual(12, generated.FSC_TasaInteresAprobada__c, 'Debe conservar la tasa del comité.');
	}

	@IsTest
	static void testExecute_NullAndEmptyInput_DoNothing() {
		ResidentialLoanApplication untouchedRla = createRla('En proceso', 'Pendiente planilla de desembolso');

		Test.startTest();
		new FSC_GenerarContratoPDFQueueable(null).execute(null);
		new FSC_GenerarContratoPDFQueueable(new List<Id>()).execute(null);
		Test.stopTest();

		ResidentialLoanApplication unchangedRla = [
			SELECT Id, FSC_Subestado__c, FSC_Contrato_Generado__c, FSC_LogErrores__c
			FROM ResidentialLoanApplication
			WHERE Id = :untouchedRla.Id
			LIMIT 1
		];

		System.assertEquals(
			'Pendiente planilla de desembolso',
			unchangedRla.FSC_Subestado__c,
			'No debe haber cambios cuando la Queueable se ejecuta sin IDs.'
		);
		System.assertEquals(
			false,
			unchangedRla.FSC_Contrato_Generado__c,
			'No debe marcarse contrato generado cuando la Queueable se ejecuta sin IDs.'
		);
		System.assertEquals(null, unchangedRla.FSC_LogErrores__c, 'No debe registrarse ningún error cuando no hay IDs para procesar.');

		Integer linkCount = [
			SELECT COUNT()
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :untouchedRla.Id
		];

		System.assertEquals(0, linkCount, 'No debe existir ningún archivo para el registro de control.');
	}
}