@IsTest
private class FSC_LoanApplicantFirmanteService_Test {
	private static Integer documentSequence = 1;

	private static ResidentialLoanApplication createRla() {
		Account account = new Account(
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
			Name = 'Cliente Firmantes',
			ACC_RNC__c = String.valueOf(Math.abs(Crypto.getRandomInteger())).leftPad(9, '0').substring(0, 9),
			ACC_Condicion__c = 'PROSPECTO',
			ACC_Estado__c = 'INICIADO',
			ACC_TipoIdentificacion__c = 'RNC'
		);
		insert account;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(Name = 'RLA Firmantes', AccountId = account.Id, FSC_TipoSolicitud__c = 'BPR');
		insert rla;
		return rla;
	}

	private static LoanApplicant createApplicant(Id rlaId, String tipoSolicitante, String nombre, String primerApellido) {
		LoanApplicant applicant = new LoanApplicant(
			Name = nombre + ' ' + primerApellido,
			LoanApplicationId = rlaId,
			FSC_TipoIdentificacion__c = 'Cédula',
			FSC_NumIdentificacion__c = String.valueOf(documentSequence++).leftPad(11, '0'),
			FSC_Nombre__c = nombre,
			FSC_PrimerApellido__c = primerApellido,
			FSC_TipoSolicitante__c = tipoSolicitante
		);
		insert applicant;
		return applicant;
	}

	@IsTest
	static void queryFirmantesFiltersAndIndexesCoDebtorsAndGuarantors() {
		ResidentialLoanApplication rla = createRla();
		createApplicant(rla.Id, 'Deudor', 'Deudor', 'Principal');
		createApplicant(rla.Id, 'Co-Deudor', 'Co', 'Deudor');
		createApplicant(rla.Id, 'Garante', 'Gar', 'Ante');

		Test.startTest();
		List<FSC_LoanApplicantFirmanteService.Firmante> firmantes = FSC_LoanApplicantFirmanteService.queryFirmantes(rla.Id);
		Test.stopTest();

		System.assertEquals(2, firmantes.size());
		System.assertEquals(1, firmantes[0].index);
		System.assertEquals('FIRMALOANAPPLICANT1', firmantes[0].firmaElementId);
		System.assertEquals('Co-Deudor', firmantes[0].tipoSolicitante);
		System.assertEquals('Co', firmantes[0].firstName);
		System.assertEquals('Deudor', firmantes[0].lastName);
		System.assertEquals(2, firmantes[1].index);
		System.assertEquals('FIRMALOANAPPLICANT2', firmantes[1].firmaElementId);
		System.assertEquals('Garante', firmantes[1].tipoSolicitante);
	}

	@IsTest
	static void queryFirmantesConEmailHandlesMissingEmailsAndNullRla() {
		ResidentialLoanApplication rla = createRla();
		createApplicant(rla.Id, 'Co-Deudor', 'Sin', 'Correo');

		Test.startTest();
		List<FSC_LoanApplicantFirmanteService.Firmante> emptyFirmantes = FSC_LoanApplicantFirmanteService.queryFirmantes(null);
		List<FSC_LoanApplicantFirmanteService.Firmante> firmantes = FSC_LoanApplicantFirmanteService.queryFirmantesConEmail(rla.Id);
		Test.stopTest();

		System.assertEquals(0, emptyFirmantes.size());
		System.assertEquals(1, firmantes.size());
		System.assertEquals(null, firmantes[0].email);
	}
}
