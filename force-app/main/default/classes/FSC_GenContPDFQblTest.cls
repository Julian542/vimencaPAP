@IsTest
private class FSC_GenContPDFQblTest {
	private static Account createAccount() {
		Account acc = new Account(
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
				.get('Candidato_Persona_Juridica')
				.getRecordTypeId(),
			Name = 'Cuenta Test PDF Queueable ' + System.now().getTime(),
			ACC_RNC__c = 'QBL' + String.valueOf(System.now().getTime()).right(6),
			ACC_Condicion__c = 'PROSPECTO',
			ACC_Estado__c = 'INICIADO',
			ACC_TipoIdentificacion__c = 'RNC'
		);
		insert acc;
		return acc;
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
			SELECT Id, FSC_Subestado__c, FSC_Contrato_Generado__c, FSC_LogErrores__c
			FROM ResidentialLoanApplication
			WHERE Id = :eligibleRla.Id
			LIMIT 1
		];

		System.assertEquals('Gestionar firmas', updatedRla.FSC_Subestado__c, 'El subestado debe actualizarse luego de generar el PDF.');
		System.assertEquals(true, updatedRla.FSC_Contrato_Generado__c, 'El indicador de contrato generado debe quedar en true.');
		System.assertEquals(null, updatedRla.FSC_LogErrores__c, 'No debe guardarse log de error cuando la generación fue exitosa.');

		List<ContentDocumentLink> links = [
			SELECT ContentDocumentId, ContentDocument.Title, LinkedEntityId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :eligibleRla.Id
		];

		System.assertEquals(1, links.size(), 'Debe existir un archivo vinculado al ResidentialLoanApplication elegible.');
		System.assertEquals(
			'Contrato_RLA_' + String.valueOf(eligibleRla.Id),
			links[0].ContentDocument.Title,
			'El título del archivo debe seguir la convención esperada.'
		);
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
		System.assertEquals(true, rlaMap.get(eligibleRla.Id).FSC_Contrato_Generado__c, 'El elegible debe quedar con contrato generado.');
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

		System.assertEquals(1, eligibleLinkCount, 'Debe haber un archivo para el registro elegible.');
		System.assertEquals(0, nonEligibleLinkCount, 'No debe haber archivos para el registro no elegible.');
	}

	@IsTest
	static void testExecute_WhenGenerationFails_AccumulatesErrorLog() {
		ResidentialLoanApplication eligibleRla = createRla('En proceso', 'Generación de contrato');
		eligibleRla.FSC_LogErrores__c = 'Log anterior';
		update eligibleRla;

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
		System.assert(failedRla.FSC_LogErrores__c.contains('Error generando contrato PDF'), 'Debe guardarse un mensaje de error claro.');
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
