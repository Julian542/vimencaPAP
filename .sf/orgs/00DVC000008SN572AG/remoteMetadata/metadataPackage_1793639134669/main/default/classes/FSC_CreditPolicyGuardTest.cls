@IsTest
private class FSC_CreditPolicyGuardTest {
	@TestSetup
	static void createPolicyRecords() {
		Account borrower = FSC_ExcepcionTestDataFactory.createAccount('8571', false);
		borrower.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
		borrower.ACC_Posee_Otra_Nacionalidad__c = false;
		insert borrower;
		List<ResidentialLoanApplication> applications = new List<ResidentialLoanApplication>();
		for (String product : new List<String>{ 'Hipotecario', 'Consumo', 'PYME' }) {
			ResidentialLoanApplication draft = FSC_ExcepcionTestDataFactory.createSolicitud(borrower.Id, 'Policy ' + product, null, null, false);
			draft.RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
				.get('FSC_Solicitud_Credito_' + product)
				.getRecordTypeId();
			draft.Status = 'Borrador';
			draft.FSC_Plazo_meses__c = null;
			draft.FSC_Moneda__c = '1';
			applications.add(draft);
		}
		insert applications;
		List<FSC_Garantia__c> guarantees = new List<FSC_Garantia__c>();
		for (Integer index = 0; index < 2; index++) {
			guarantees.add(
				new FSC_Garantia__c(
					Name = 'Policy collateral ' + index,
					FSC_Residential_Loan_Application__c = applications[index].Id,
					FSC_Clase_de_Garantia__c = 'BIENES INMUEBLES',
					FSC_Proposito_Garantia_Hipotecario__c = FSC_ReglaCredito__mdt.getInstance(index == 0 ? 'HipCompraDOP' : 'ConsConsolidacion')
						.FSC_Proposito__c,
					FSC_Valor_Inmueble__c = 2000000,
					FSC_Precio_de_Venta__c = 1500000,
					FSC_Tipo_de_Inmueble__c = 'Vivienda'
				)
			);
		}
		insert guarantees;
		List<ResidentialLoanApplication> completed = new List<ResidentialLoanApplication>();
		for (Integer index = 0; index < 2; index++) {
			completed.add(
				new ResidentialLoanApplication(
					Id = applications[index].Id,
					FSC_Monto__c = 600000,
					FSC_Plazo_meses__c = '24',
					FSC_MontoAprobado__c = 600000,
					FSC_PlazoMesesAprobado__c = 24
				)
			);
		}
		update completed;
	}

	@IsTest
	static void acceptsPersistedMortgageAndApprovedConditions() {
		ResidentialLoanApplication record = storedApplication('Hipotecario');
		Test.startTest();
		FSC_CreditPolicyGuard.validateApplications(new List<ResidentialLoanApplication>{ record }, null);
		Test.stopTest();
		Assert.isFalse(record.hasErrors(), 'Las condiciones solicitadas y aprobadas están respaldadas por la garantía persistida.');
	}

	@IsTest
	static void rejectsApprovedAmountAboveCollateralCapacity() {
		ResidentialLoanApplication record = storedApplication('Hipotecario');
		record.FSC_MontoAprobado__c = 1200000.01;
		Test.startTest();
		FSC_CreditPolicyGuard.validateApplications(new List<ResidentialLoanApplication>{ record }, null);
		Test.stopTest();
		Assert.isTrue(record.hasErrors(), 'La aprobación no puede superar el 80% del menor valor de la garantía.');
		Assert.isTrue(record.getErrors()[0].getMessage().startsWith('Condiciones aprobadas:'), 'Debe identificar las condiciones aprobadas.');
	}

	@IsTest
	static void rejectsApprovedTermAboveDestinationLimit() {
		ResidentialLoanApplication record = storedApplication('Consumo');
		record.FSC_PlazoMesesAprobado__c = 85;
		Test.startTest();
		FSC_CreditPolicyGuard.validateApplications(new List<ResidentialLoanApplication>{ record }, null);
		Test.stopTest();
		Assert.isTrue(record.hasErrors(), 'La consolidación admite como máximo 84 meses, también al aprobar.');
	}

	@IsTest
	static void identifiesConsumptionWithRealEstateCollateral() {
		ResidentialLoanApplication record = storedApplication('Consumo');
		Test.startTest();
		FSC_CreditPolicyGuard.validateApplications(new List<ResidentialLoanApplication>{ record }, null);
		Test.stopTest();
		Assert.isFalse(record.hasErrors(), 'El consumo cumple su política inmobiliaria.');
		Assert.areEqual('Garantía Real', record.FSC_TipoGarantia__c, 'Debe conservar la clasificación inmobiliaria.');
	}

	@IsTest
	static void registeredPlanAllowsCollateralBeforeChildInsert() {
		ResidentialLoanApplication record = storedApplication('Hipotecario');
		FSC_CreditPolicyService.Request plan = planFor(record);
		ResidentialLoanApplication draft = application('FSC_Solicitud_Credito_Hipotecario', '24');
		draft.AccountId = record.AccountId;
		draft.FSC_Monto__c = 600000;
		Test.startTest();
		FSC_CreditPolicyGuard.registerPlan(plan);
		FSC_CreditPolicyGuard.validateApplications(new List<ResidentialLoanApplication>{ draft }, null);
		Test.stopTest();
		Assert.isFalse(draft.hasErrors(), 'El plan de la misma cuenta y condiciones respalda el padre antes de crear los hijos.');
	}

	@IsTest
	static void registeredPlanCannotValidateDifferentFinancialConditions() {
		ResidentialLoanApplication record = storedApplication('Hipotecario');
		FSC_CreditPolicyService.Request plan = planFor(record);
		ResidentialLoanApplication draft = application('FSC_Solicitud_Credito_Hipotecario', '24');
		draft.AccountId = record.AccountId;
		draft.FSC_Monto__c = 700000;
		Test.startTest();
		FSC_CreditPolicyGuard.registerPlan(plan);
		FSC_CreditPolicyGuard.validateApplications(new List<ResidentialLoanApplication>{ draft }, null);
		Test.stopTest();
		Assert.isTrue(draft.hasErrors(), 'Un plan previo no puede reutilizarse después de cambiar el monto.');
	}

	@IsTest
	static void rejectsInvalidPlanRegistration() {
		FSC_CreditPolicyService.Request plan = planFor(storedApplication('Hipotecario'));
		plan.amount = 499999.99;
		Test.startTest();
		try {
			FSC_CreditPolicyGuard.registerPlan(plan);
			Assert.fail('No se puede registrar un monto inferior al mínimo.');
		} catch (FSC_CreditPolicyController.CreditPolicyException expected) {
			Assert.isTrue(expected.getMessage().contains('monto'), 'Debe informar el incumplimiento del monto.');
		}
		Test.stopTest();
	}

	@IsTest
	static void collateralReductionRejectsAndRollsBackTheUpdate() {
		FSC_Garantia__c guarantee = storedGuarantee('Hipotecario');
		Test.startTest();
		Database.SaveResult result = Database.update(new FSC_Garantia__c(Id = guarantee.Id, FSC_Valor_Inmueble__c = 700000), false);
		Test.stopTest();
		Assert.isFalse(result.isSuccess(), 'El nuevo máximo de 560.000 no respalda los 600.000 solicitados y aprobados.');
		Assert.isTrue(
			result.getErrors()[0].getMessage().contains('monto'),
			'El rechazo debe provenir del límite de monto: ' + result.getErrors()[0].getMessage()
		);
		Assert.areEqual(2000000, storedGuarantee('Hipotecario').FSC_Valor_Inmueble__c, 'El valor anterior debe conservarse al rechazar el cambio.');
	}

	@IsTest
	static void cannotDeleteTheOnlyMortgageCollateral() {
		FSC_Garantia__c guarantee = storedGuarantee('Hipotecario');
		Test.startTest();
		Database.DeleteResult result = Database.delete(guarantee, false);
		Test.stopTest();
		Assert.isFalse(result.isSuccess(), 'La solicitud completa debe conservar su respaldo inmobiliario.');
		Assert.isTrue(result.getErrors()[0].getMessage().contains('garantía'), 'Debe indicar la falta de respaldo.');
		Assert.areEqual(guarantee.Id, storedGuarantee('Hipotecario').Id, 'La eliminación rechazada debe revertirse.');
	}

	@IsTest
	static void validCollateralUpdateKeepsTheApprovedLoan() {
		FSC_Garantia__c guarantee = storedGuarantee('Hipotecario');
		Test.startTest();
		update new FSC_Garantia__c(Id = guarantee.Id, FSC_Precio_de_Venta__c = 1400000);
		Test.stopTest();
		Assert.areEqual(1400000, storedGuarantee('Hipotecario').FSC_Precio_de_Venta__c, 'La garantía actualizada sigue respaldando el crédito.');
	}

	@IsTest
	static void facilityInsertEnforcesMortgageLimits() {
		ResidentialLoanApplication parent = storedApplication('Hipotecario');
		FSC_Facilidades_De_Credito__c facility = new FSC_Facilidades_De_Credito__c(
			Name = 'Policy invalid term',
			FSC_Residential_Loan_Application__c = parent.Id,
			FSC_Monto_Solicitado__c = 600000,
			FSC_Plazo_meses__c = 361,
			FSC_Moneda__c = '1'
		);
		Test.startTest();
		Database.SaveResult result = Database.insert(facility, false);
		Test.stopTest();
		Assert.isFalse(result.isSuccess(), 'Una facilidad no puede superar 360 meses aunque el padre sea válido.');
		Assert.isTrue(result.getErrors()[0].getMessage().contains('plazo'), 'Debe devolver la causa financiera del rechazo.');
	}

	@IsTest
	static void validFacilityLifecyclePreservesTheMortgageConditions() {
		ResidentialLoanApplication parent = storedApplication('Hipotecario');
		FSC_Facilidades_De_Credito__c facility = new FSC_Facilidades_De_Credito__c(
			Name = 'Policy valid lifecycle',
			FSC_Residential_Loan_Application__c = parent.Id,
			FSC_Monto_Solicitado__c = 600000,
			FSC_Plazo_meses__c = 24,
			FSC_Moneda__c = '1'
		);
		Test.startTest();
		insert facility;
		Assert.isNotNull(facility.Id, 'Una facilidad dentro de los límites debe persistirse.');
		update new FSC_Facilidades_De_Credito__c(Id = facility.Id, FSC_Plazo_meses__c = 25);
		FSC_Facilidades_De_Credito__c saved = [SELECT FSC_Plazo_meses__c FROM FSC_Facilidades_De_Credito__c WHERE Id = :facility.Id WITH USER_MODE];
		Assert.areEqual(25, saved.FSC_Plazo_meses__c, 'El cambio válido de plazo debe guardarse.');
		delete facility;
		Assert.areEqual(
			0,
			[SELECT COUNT() FROM FSC_Facilidades_De_Credito__c WHERE Id = :facility.Id WITH USER_MODE],
			'Se puede retirar la facilidad sin eliminar la solicitud ni su respaldo.'
		);
		Test.stopTest();
		Assert.areEqual(
			600000,
			storedApplication('Hipotecario').FSC_Monto__c,
			'El ciclo de la facilidad debe conservar las condiciones de la solicitud.'
		);
	}

	@IsTest
	static void validatesTwoHundredFiftyOneFacilitiesWithConstantQueries() {
		ResidentialLoanApplication parent = storedApplication('Hipotecario');
		List<FSC_Facilidades_De_Credito__c> facilities = new List<FSC_Facilidades_De_Credito__c>();
		for (Integer index = 0; index < 251; index++) {
			facilities.add(
				new FSC_Facilidades_De_Credito__c(
					FSC_Residential_Loan_Application__c = parent.Id,
					FSC_Monto_Solicitado__c = Math.mod(index, 2) == 0 ? 600000 : 1200000.01,
					FSC_Plazo_meses__c = 24,
					FSC_Moneda__c = '1'
				)
			);
		}
		Test.startTest();
		Integer queries = Limits.getQueries();
		FSC_CreditPolicyGuard.validateFacilities(facilities, null);
		Assert.areEqual(3, Limits.getQueries() - queries, 'Padres, garantías y deudores se consultan una vez para todo el lote.');
		Test.stopTest();
		for (Integer index = 0; index < facilities.size(); index++) {
			Assert.areEqual(Math.mod(index, 2) != 0, facilities[index].hasErrors(), 'El rechazo debe corresponder al monto de cada facilidad.');
		}
	}

	@IsTest
	static void unchangedCollateralDoesNotRevalidateFinancialConditions() {
		FSC_Garantia__c guarantee = storedGuarantee('Hipotecario');
		guarantee.FSC_Valor_Mejoras__c = null;
		guarantee.FSC_SaldoPrimeraHipoteca__c = null;
		Test.startTest();
		Integer queries = Limits.getQueries();
		FSC_CreditPolicyGuard.validateGuarantees(
			new List<FSC_Garantia__c>{ guarantee },
			new Map<Id, FSC_Garantia__c>{ guarantee.Id => guarantee.clone(true) }
		);
		Assert.areEqual(queries, Limits.getQueries(), 'Sin cambios en los campos financieros no se consulta ni revalúa el crédito.');
		Test.stopTest();
		Assert.isFalse(guarantee.hasErrors(), 'Una garantía sin cambios debe conservar su validez.');
	}

	private static ResidentialLoanApplication storedApplication(String product) {
		String name = 'Policy ' + product;
		return [
			SELECT
				Id,
				AccountId,
				RecordTypeId,
				FSC_Monto__c,
				FSC_Plazo_meses__c,
				FSC_Moneda__c,
				FSC_MontoAprobado__c,
				FSC_PlazoMesesAprobado__c,
				FSC_TipoGarantia__c
			FROM ResidentialLoanApplication
			WHERE Name = :name
			WITH USER_MODE
			LIMIT 1
		];
	}
	private static FSC_Garantia__c storedGuarantee(String product) {
		Id parentId = storedApplication(product).Id;
		return FSC_CreditPolicyService.guarantees(new Set<Id>{ parentId })[0];
	}
	private static FSC_CreditPolicyService.Request planFor(ResidentialLoanApplication record) {
		FSC_CreditPolicyService.Request plan = new FSC_CreditPolicyService.Request();
		plan.accountId = record.AccountId;
		plan.loanType = 'hipotecario';
		plan.currencyCode = 'DOP';
		plan.amount = record.FSC_Monto__c;
		plan.months = Decimal.valueOf(record.FSC_Plazo_meses__c);
		plan.guarantees.add(FSC_CreditPolicyService.storedGuarantee(storedGuarantee('Hipotecario')));
		return plan;
	}
	@IsTest
	static void rejectsCompleteMortgageWithoutItsGuarantee() {
		ResidentialLoanApplication application = application('FSC_Solicitud_Credito_Hipotecario', '120');
		Test.startTest();
		FSC_CreditPolicyGuard.validateApplications(new List<ResidentialLoanApplication>{ application }, null);
		Test.stopTest();
		Assert.isTrue(application.hasErrors(), 'Una solicitud completa por API no puede omitir los datos de la política.');
	}
	@IsTest
	static void permitsInitialEmptyDraft() {
		ResidentialLoanApplication application = application('FSC_Solicitud_Credito_Hipotecario', null);
		application.FSC_Monto__c = null;
		Test.startTest();
		FSC_CreditPolicyGuard.validateApplications(new List<ResidentialLoanApplication>{ application }, null);
		Test.stopTest();
		Assert.isFalse(application.hasErrors(), 'OmniStudio captura el deudor antes de las condiciones financieras.');
	}
	@IsTest
	static void rejectsConsumptionAboveGeneralTermWithoutCollateral() {
		ResidentialLoanApplication application = application('FSC_Solicitud_Credito_Consumo', '180');
		Test.startTest();
		FSC_CreditPolicyGuard.validateApplications(new List<ResidentialLoanApplication>{ application }, null);
		Test.stopTest();
		Assert.isTrue(application.hasErrors(), 'No se admite ampliar el plazo omitiendo la garantía.');
	}
	@IsTest
	static void validatesTwoHundredFiftyOneDraftsWithoutDml() {
		List<ResidentialLoanApplication> applications = new List<ResidentialLoanApplication>();
		for (Integer index = 0; index < 251; index++)
			applications.add(application('FSC_Solicitud_Credito_Consumo', '12'));
		Test.startTest();
		Integer dml = Limits.getDmlStatements();
		FSC_CreditPolicyGuard.validateApplications(applications, null);
		Assert.areEqual(dml, Limits.getDmlStatements(), 'La validación no debe guardar registros.');
		Test.stopTest();
		for (ResidentialLoanApplication record : applications)
			Assert.isFalse(record.hasErrors(), 'El plazo general válido debe admitirse.');
	}
	private static ResidentialLoanApplication application(String typeName, String months) {
		return new ResidentialLoanApplication(
			RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName().get(typeName).getRecordTypeId(),
			FSC_Monto__c = 500000,
			FSC_Plazo_meses__c = months,
			FSC_Moneda__c = '1'
		);
	}
}