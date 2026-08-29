@IsTest
private class FSC_RegSolicitudTrigTest {
	private static Integer accountSequence = 0;

	private static String firstActivePicklistValue(Schema.SObjectField fieldToken) {
		for (Schema.PicklistEntry entry : fieldToken.getDescribe().getPicklistValues()) {
			if (entry.isActive()) {
				return entry.getValue();
			}
		}
		return null;
	}

	private static ResidentialLoanApplication createRla() {
		Test.setMock(HttpCalloutMock.class, new FSC_EsignHttpMock());
		Account account = new Account(
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
			FirstName = 'Cuenta',
			LastName = 'Trigger Coverage ' + System.now().getTime(),
			ACC_TipoIdentificacion__c = 'Cédula',
			ACC_NumIdentificacion__c = nextTestIdentification()
		);
		insert account;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Trigger Coverage ' + System.now().getTime(),
			AccountId = account.Id,
			Status = 'En proceso',
			FSC_Subestado__c = 'Gestionar firmas',
			FSC_TipoSolicitud__c = firstActivePicklistValue(ResidentialLoanApplication.FSC_TipoSolicitud__c)
		);
		insert rla;
		return rla;
	}

	private static String nextTestIdentification() {
		accountSequence++;
		return '00108803' + String.valueOf(accountSequence).leftPad(3, '0');
	}

	private static LoanApplicant createLoanApplicant(ResidentialLoanApplication rla) {
		LoanApplicant applicant = new LoanApplicant(
			Name = 'Solicitante Trigger Coverage',
			LoanApplicationId = rla.Id,
			FSC_NumIdentificacion__c = '00112345678',
			FSC_TipoIdentificacion__c = firstActivePicklistValue(LoanApplicant.FSC_TipoIdentificacion__c),
			FSC_Nombre__c = 'Solicitante',
			FSC_TipoSolicitante__c = firstActivePicklistValue(LoanApplicant.FSC_TipoSolicitante__c)
		);
		insert applicant;
		return applicant;
	}

	@IsTest
	static void coversContactPointAddressTriggerInsertUpdateDelete() {
		ResidentialLoanApplication rla = createRla();
		ContactPointAddress address = new ContactPointAddress(Name = 'Direccion inicial');
		address.put('FSC_ResidentialLoanApplicationId__c', rla.Id);

		Test.startTest();
		insert address;
		address.Name = 'Direccion actualizada';
		update address;
		delete address;
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM ContactPointAddress WHERE Id = :address.Id]);
	}

	@IsTest
	static void coversContactPointEmailTriggerInsertUpdateDelete() {
		ResidentialLoanApplication rla = createRla();
		ContactPointEmail email = new ContactPointEmail(EmailAddress = 'inicial@example.com');
		email.put('FSC_ResidentialLoanApplicationId__c', rla.Id);

		Test.startTest();
		insert email;
		email.EmailAddress = 'actualizado@example.com';
		update email;
		delete email;
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM ContactPointEmail WHERE Id = :email.Id]);
	}

	@IsTest
	static void coversContactPointPhoneTriggerInsertUpdateDelete() {
		ResidentialLoanApplication rla = createRla();
		ContactPointPhone phone = new ContactPointPhone(TelephoneNumber = '8095550001');
		phone.put('FSC_ResidentialLoanApplicationId__c', rla.Id);

		Test.startTest();
		insert phone;
		phone.TelephoneNumber = '8095550002';
		update phone;
		delete phone;
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM ContactPointPhone WHERE Id = :phone.Id]);
	}

	@IsTest
	static void coversFacilidadesDeCreditoTriggerInsertUpdateDelete() {
		ResidentialLoanApplication rla = createRla();
		FSC_Facilidades_De_Credito__c facility = new FSC_Facilidades_De_Credito__c(
			Name = 'Facilidad inicial',
			FSC_Residential_Loan_Application__c = rla.Id
		);

		Test.startTest();
		insert facility;
		facility.Name = 'Facilidad actualizada';
		update facility;
		delete facility;
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM FSC_Facilidades_De_Credito__c WHERE Id = :facility.Id]);
	}

	@IsTest
	static void coversFacilidadOtraInstitucionTriggerInsertUpdateDelete() {
		ResidentialLoanApplication rla = createRla();
		LoanApplicant applicant = createLoanApplicant(rla);
		FSC_Facilidad_Otra_Institucion__c otherFacility = new FSC_Facilidad_Otra_Institucion__c(
			Name = 'Otra facilidad inicial',
			FSC_LoanApplicant__c = applicant.Id
		);

		Test.startTest();
		insert otherFacility;
		otherFacility.Name = 'Otra facilidad actualizada';
		update otherFacility;
		delete otherFacility;
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM FSC_Facilidad_Otra_Institucion__c WHERE Id = :otherFacility.Id]);
	}

	@IsTest
	static void coversGarantiaTriggerInsertUpdateDelete() {
		ResidentialLoanApplication rla = createRla();
		FSC_Garantia__c guarantee = new FSC_Garantia__c(
			Name = 'Garantia inicial',
			FSC_Residential_Loan_Application__c = rla.Id
		);

		Test.startTest();
		insert guarantee;
		guarantee.Name = 'Garantia actualizada';
		update guarantee;
		delete guarantee;
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM FSC_Garantia__c WHERE Id = :guarantee.Id]);
	}

	@IsTest
	static void coversLoanApplicantTriggerInsertUpdateDelete() {
		ResidentialLoanApplication rla = createRla();
		LoanApplicant applicant = new LoanApplicant(
			Name = 'Solicitante inicial',
			LoanApplicationId = rla.Id,
			FSC_NumIdentificacion__c = '00187654321',
			FSC_TipoIdentificacion__c = firstActivePicklistValue(LoanApplicant.FSC_TipoIdentificacion__c),
			FSC_Nombre__c = 'Solicitante',
			FSC_TipoSolicitante__c = firstActivePicklistValue(LoanApplicant.FSC_TipoSolicitante__c)
		);

		Test.startTest();
		insert applicant;
		applicant.FSC_Nombre__c = 'Solicitante actualizado';
		update applicant;
		delete applicant;
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM LoanApplicant WHERE Id = :applicant.Id]);
	}
}
