@IsTest
private class FSC_GenerarContratoPDFTest {
	private static Integer accountSequence = 13;

	private static Account createAccount() {
		Account acc = new Account(
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
			Name = 'Cuenta Test Enqueue ' + System.now().getTime(),
			ACC_RNC__c = '1310000' + String.valueOf(accountSequence++),
			ACC_TipoIdentificacion__c = 'RNC',
			ACC_Condicion__c = 'PROSPECTO',
			ACC_Estado__c = 'INICIADO'
		);
		insert acc;
		return acc;
	}

	private static ResidentialLoanApplication createRla(String status, String subestado) {
		Account acc = createAccount();

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Test Enqueue ' + System.now().getTime(),
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
	static void testEnqueueGeneration_WithIds_EnqueuesAndExecutesQueueable() {
		ResidentialLoanApplication eligibleRla = createRla('En proceso', 'Generación de contrato');
		ResidentialLoanApplication nonEligibleRla = createRla('En proceso', 'Pendiente planilla de desembolso');

		Test.startTest();
		FSC_GenerarContratoPDF.enqueueGeneration(new Set<Id>{ eligibleRla.Id, nonEligibleRla.Id });
		Test.stopTest();

		List<AsyncApexJob> jobs = [
			SELECT Id, Status, JobType, ApexClass.Name
			FROM AsyncApexJob
			WHERE JobType = 'Queueable' AND ApexClass.Name = 'FSC_GenerarContratoPDFQueueable'
		];

		System.assertEquals(1, jobs.size(), 'Debe encolarse exactamente un Queueable cuando se reciben IDs válidos.');
		System.assertEquals('Completed', jobs[0].Status, 'El Queueable debe completarse correctamente en el contexto del test.');

		Map<Id, ResidentialLoanApplication> rlaMap = new Map<Id, ResidentialLoanApplication>(
			[
				SELECT Id, FSC_Subestado__c, FSC_Contrato_Generado__c
				FROM ResidentialLoanApplication
				WHERE Id IN :new Set<Id>{ eligibleRla.Id, nonEligibleRla.Id }
			]
		);

		System.assertEquals(
			'Gestionar firmas',
			rlaMap.get(eligibleRla.Id).FSC_Subestado__c,
			'El registro elegible debe ser procesado por la queueable encolada.'
		);
		System.assertEquals(
			true,
			rlaMap.get(eligibleRla.Id).FSC_Contrato_Generado__c,
			'El registro elegible debe quedar marcado con contrato generado.'
		);

		System.assertEquals(
			'Pendiente planilla de desembolso',
			rlaMap.get(nonEligibleRla.Id).FSC_Subestado__c,
			'El registro no elegible no debe cambiar de subestado.'
		);
		System.assertEquals(
			false,
			rlaMap.get(nonEligibleRla.Id).FSC_Contrato_Generado__c,
			'El registro no elegible no debe marcarse como contrato generado.'
		);
	}

	@IsTest
	static void testEnqueueGeneration_NullSet_DoesNotEnqueue() {
		Test.startTest();
		FSC_GenerarContratoPDF.enqueueGeneration(null);
		Test.stopTest();

		Integer jobsCount = [
			SELECT COUNT()
			FROM AsyncApexJob
			WHERE JobType = 'Queueable' AND ApexClass.Name = 'FSC_GenerarContratoPDFQueueable'
		];

		System.assertEquals(0, jobsCount, 'No debe encolarse ningún trabajo cuando el Set es null.');
	}

	@IsTest
	static void testEnqueueGeneration_EmptySet_DoesNotEnqueue() {
		Test.startTest();
		FSC_GenerarContratoPDF.enqueueGeneration(new Set<Id>());
		Test.stopTest();

		Integer jobsCount = [
			SELECT COUNT()
			FROM AsyncApexJob
			WHERE JobType = 'Queueable' AND ApexClass.Name = 'FSC_GenerarContratoPDFQueueable'
		];

		System.assertEquals(0, jobsCount, 'No debe encolarse ningún trabajo cuando el Set está vacío.');
	}
}
