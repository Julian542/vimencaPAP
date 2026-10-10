@IsTest
private class FSC_GuaranteeConfigurationTest {
	private static FSC_ClaseGarantia__mdt createClass(Integer sequence, String value, String groupName) {
		String recordId =
			FSC_ClaseGarantia__mdt.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getKeyPrefix() +
			String.valueOf(sequence).leftPad(12, '0');
		return new FSC_ClaseGarantia__mdt(Id = recordId, FSC_Valor__c = value, FSC_Grupo__c = groupName);
	}

	private static FSC_TipoGarantia__mdt createType(Id classId, String value, Decimal position) {
		return new FSC_TipoGarantia__mdt(FSC_Clase__c = classId, FSC_Valor__c = value, FSC_Orden__c = position);
	}

	@IsTest
	static void shouldPreserveValuesAndSortTypes() {
		FSC_ClaseGarantia__mdt classRecord = createClass(1, 'INMUEBLE PARAMETRICO', 'real-estate');
		Test.startTest();
		List<FSC_LoanFacilityController.GuaranteeClassDTO> result = FSC_LoanFacilityController.buildGuaranteeConfiguration(
			new List<FSC_ClaseGarantia__mdt>{ classRecord },
			new List<FSC_TipoGarantia__mdt>{ createType(classRecord.Id, 'Tipo B', 2), createType(classRecord.Id, 'Tipo Á', 1) }
		);
		Test.stopTest();
		Assert.areEqual(1, result.size(), 'Must return the configured class.');
		Assert.areEqual(classRecord.FSC_Valor__c, result[0].value, 'Must preserve the stored class value.');
		Assert.areEqual('real-estate', result[0].groupName, 'Must preserve the configured behavior.');
		Assert.areEqual('Tipo Á', result[0].types[0].value, 'Must preserve accents and apply configured order.');
		Assert.areEqual('Tipo B', result[0].types[1].value, 'Must return the second type.');
	}

	@IsTest
	static void shouldReturnClassWithoutTypes() {
		Test.startTest();
		List<FSC_LoanFacilityController.GuaranteeClassDTO> result = FSC_LoanFacilityController.buildGuaranteeConfiguration(
			new List<FSC_ClaseGarantia__mdt>{ createClass(1, 'VEHICULO PARAMETRICO', 'vehicle') },
			new List<FSC_TipoGarantia__mdt>()
		);
		Test.stopTest();
		Assert.areEqual('vehicle', result[0].groupName, 'Classes without types must retain their behavior.');
		Assert.areEqual(0, result[0].types.size(), 'Must not invent type options.');
	}

	@IsTest
	static void shouldSortTiesAndDefaultMissingOrder() {
		FSC_ClaseGarantia__mdt classRecord = createClass(1, 'GENERAL', 'general');
		Test.startTest();
		List<FSC_LoanFacilityController.GuaranteeClassDTO> result = FSC_LoanFacilityController.buildGuaranteeConfiguration(
			new List<FSC_ClaseGarantia__mdt>{ classRecord },
			new List<FSC_TipoGarantia__mdt>{ createType(classRecord.Id, 'B', null), createType(classRecord.Id, 'A', 0) }
		);
		Test.stopTest();
		Assert.areEqual('A', result[0].types[0].value, 'Equal orders must have a deterministic value tie-breaker.');
		Assert.areEqual('B', result[0].types[1].value, 'Missing order must default to zero.');
	}

	@IsTest
	static void shouldHandleBulkConfigurationWithoutQueriesOrDml() {
		List<FSC_ClaseGarantia__mdt> classes = new List<FSC_ClaseGarantia__mdt>();
		List<FSC_TipoGarantia__mdt> types = new List<FSC_TipoGarantia__mdt>();
		for (Integer index = 1; index <= 251; index++) {
			FSC_ClaseGarantia__mdt classRecord = createClass(index, 'Class ' + index, 'general');
			classes.add(classRecord);
			types.add(createType(classRecord.Id, 'Type ' + index, 1));
		}
		Test.startTest();
		List<FSC_LoanFacilityController.GuaranteeClassDTO> result = FSC_LoanFacilityController.buildGuaranteeConfiguration(classes, types);
		Integer queries = Limits.getQueries();
		Integer statements = Limits.getDmlStatements();
		Test.stopTest();
		Assert.areEqual(classes.size(), result.size(), 'Must process all classes.');
		Assert.areEqual(0, queries, 'Mapping must not query records.');
		Assert.areEqual(0, statements, 'Mapping must not perform DML.');
		for (FSC_LoanFacilityController.GuaranteeClassDTO configuration : result) {
			Assert.areEqual(1, configuration.types.size(), 'Every type must belong to its configured class.');
			Assert.areEqual(configuration.value.replace('Class ', 'Type '), configuration.types[0].value, 'Must not mix types between classes.');
		}
	}

	@IsTest
	static void shouldRejectMissingClasses() {
		assertInvalid(new List<FSC_ClaseGarantia__mdt>(), new List<FSC_TipoGarantia__mdt>());
	}

	@IsTest
	static void shouldRejectUnsupportedGroup() {
		assertInvalid(new List<FSC_ClaseGarantia__mdt>{ createClass(1, 'Class', 'unsupported') }, new List<FSC_TipoGarantia__mdt>());
	}

	@IsTest
	static void shouldRejectBlankClassValue() {
		assertInvalid(new List<FSC_ClaseGarantia__mdt>{ createClass(1, ' ', 'general') }, new List<FSC_TipoGarantia__mdt>());
	}

	@IsTest
	static void shouldRejectDuplicateClasses() {
		assertInvalid(
			new List<FSC_ClaseGarantia__mdt>{ createClass(1, 'Class', 'general'), createClass(2, 'CLASS', 'vehicle') },
			new List<FSC_TipoGarantia__mdt>()
		);
	}

	@IsTest
	static void shouldRejectOrphanType() {
		assertInvalid(
			new List<FSC_ClaseGarantia__mdt>{ createClass(1, 'Class', 'general') },
			new List<FSC_TipoGarantia__mdt>{ createType(null, 'Type', 1) }
		);
	}

	@IsTest
	static void shouldRejectBlankTypeValue() {
		FSC_ClaseGarantia__mdt classRecord = createClass(1, 'Class', 'general');
		assertInvalid(new List<FSC_ClaseGarantia__mdt>{ classRecord }, new List<FSC_TipoGarantia__mdt>{ createType(classRecord.Id, ' ', 1) });
	}

	@IsTest
	static void shouldRejectDuplicateTypes() {
		FSC_ClaseGarantia__mdt classRecord = createClass(1, 'Class', 'general');
		assertInvalid(
			new List<FSC_ClaseGarantia__mdt>{ classRecord },
			new List<FSC_TipoGarantia__mdt>{ createType(classRecord.Id, 'Type', 1), createType(classRecord.Id, 'Type', 2) }
		);
	}

	@IsTest
	static void shouldReadDeployedMetadata() {
		Test.startTest();
		List<FSC_LoanFacilityController.GuaranteeClassDTO> result = FSC_LoanFacilityController.getGuaranteeConfiguration();
		Test.stopTest();
		Assert.areEqual(FSC_ClaseGarantia__mdt.getAll().size(), result.size(), 'The endpoint must read all configured classes.');
	}

	private static void assertInvalid(List<FSC_ClaseGarantia__mdt> classes, List<FSC_TipoGarantia__mdt> types) {
		Test.startTest();
		try {
			FSC_LoanFacilityController.buildGuaranteeConfiguration(classes, types);
			Assert.fail('Expected invalid configuration to be rejected.');
		} catch (AuraHandledException expected) {
			Assert.isNotNull(expected, 'Must report a handled configuration error.');
		}
		Test.stopTest();
	}
}