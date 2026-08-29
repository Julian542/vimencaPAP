@IsTest
private class FSC_LoanFacilityControllerTest {
	@IsTest
	static void testGetGuaranteeTypeOptionsReturnsUniqueMetadataLabels() {
		FSC_TiposSeguro__mdt sampleRecord = [
			SELECT FSC_Facilidad__c
			FROM FSC_TiposSeguro__mdt
			WHERE FSC_Facilidad__c = '- 401' AND FSC_Label__c != NULL AND FSC_Deshabilitado__c = FALSE
			LIMIT 1
		];

		List<FSC_TiposSeguro__mdt> metadataRecords = [
			SELECT DeveloperName, FSC_Label__c, FSC_Tasa__c
			FROM FSC_TiposSeguro__mdt
			WHERE FSC_Facilidad__c = :sampleRecord.FSC_Facilidad__c AND FSC_Deshabilitado__c = FALSE
			ORDER BY FSC_Label__c, MasterLabel
		];

		Set<String> expectedLabels = new Set<String>();
		Map<String, Decimal> expectedRatesByApiName = new Map<String, Decimal>();
		for (FSC_TiposSeguro__mdt metadataRecord : metadataRecords) {
			if (String.isNotBlank(metadataRecord.FSC_Label__c)) {
				String expectedApiName = metadataRecord.DeveloperName.endsWith('_2')
					? metadataRecord.DeveloperName.substring(0, metadataRecord.DeveloperName.length() - 2)
					: metadataRecord.DeveloperName;
				expectedLabels.add(expectedApiName);
				expectedRatesByApiName.put(expectedApiName, metadataRecord.FSC_Tasa__c);
			}
		}

		Test.startTest();
		List<FSC_LoanFacilityController.OptionDTO> result = FSC_LoanFacilityController.getGuaranteeTypeOptions(
			'TEST ' + sampleRecord.FSC_Facilidad__c,
			'consumo'
		);
		Test.stopTest();

		Set<String> actualLabels = new Set<String>();
		for (FSC_LoanFacilityController.OptionDTO option : result) {
			actualLabels.add(option.value);
			System.assertEquals(expectedRatesByApiName.get(option.value), option.rate, 'La opcion debe incluir la tasa configurada en la metadata.');
		}

		System.assertEquals(expectedLabels, actualLabels, 'Debe devolver los tipos unicos para la facilidad.');
	}

	@IsTest
	static void testGetInsuranceRateOptionsReturnsMetadataRateByType() {
		FSC_TiposSeguro__mdt sampleRecord = [
			SELECT FSC_Label__c, FSC_Tasa__c, FSC_Facilidad__c
			FROM FSC_TiposSeguro__mdt
			WHERE FSC_Facilidad__c != NULL AND FSC_Label__c != NULL AND FSC_Tasa__c != NULL AND FSC_Deshabilitado__c = FALSE
			LIMIT 1
		];

		Test.startTest();
		List<FSC_LoanFacilityController.InsuranceRateDTO> result = FSC_LoanFacilityController.getInsuranceRateOptions(
			'TEST ' + sampleRecord.FSC_Facilidad__c
		);
		Test.stopTest();

		Map<String, Decimal> ratesByLabel = new Map<String, Decimal>();
		for (FSC_LoanFacilityController.InsuranceRateDTO option : result) {
			if (!ratesByLabel.containsKey(option.label)) {
				ratesByLabel.put(option.label, option.rate);
			}
		}

		System.assert(ratesByLabel.containsKey(sampleRecord.FSC_Label__c), 'Debe incluir la tasa del tipo de seguro consultado.');
		System.assertEquals(
			sampleRecord.FSC_Tasa__c,
			ratesByLabel.get(sampleRecord.FSC_Label__c),
			'Debe devolver la tasa configurada en custom metadata.'
		);
	}

	@IsTest
	static void testGetInsuranceRateReturnsSelectedInsuranceMetadata() {
		FSC_TiposSeguro__mdt sampleRecord = [
			SELECT
				DeveloperName,
				FSC_Label__c,
				FSC_Tasa__c,
				FSC_Facilidad__c,
				FSC_Tipo_Calculo_Prima__c,
				FSC_Base_Calculo_Prima__c,
				FSC_Divisor_Tasa__c,
				FSC_Parametros_Formula__c
			FROM FSC_TiposSeguro__mdt
			WHERE
				FSC_Facilidad__c != NULL
				AND FSC_Label__c != NULL
				AND FSC_Tasa__c != NULL
				AND FSC_Tipo_Calculo_Prima__c != NULL
				AND FSC_Deshabilitado__c = FALSE
			LIMIT 1
		];

		Test.startTest();
		FSC_LoanFacilityController.InsuranceRateDTO result = FSC_LoanFacilityController.getInsuranceRate(
			'TEST ' + sampleRecord.FSC_Facilidad__c,
			sampleRecord.DeveloperName.endsWith('_2')
				? sampleRecord.DeveloperName.substring(0, sampleRecord.DeveloperName.length() - 2)
				: sampleRecord.DeveloperName
		);
		Test.stopTest();

		System.assertNotEquals(null, result, 'Debe devolver la metadata del seguro seleccionado.');
		System.assertEquals(sampleRecord.FSC_Label__c, result.label, 'Debe devolver el label del seguro consultado.');
		System.assertEquals(sampleRecord.FSC_Tasa__c, result.rate, 'Debe devolver la tasa configurada.');
		System.assertEquals(sampleRecord.FSC_Tipo_Calculo_Prima__c, result.calculationType, 'Debe devolver el tipo de calculo.');
		System.assertEquals(sampleRecord.FSC_Base_Calculo_Prima__c, result.calculationBase, 'Debe devolver la base de calculo.');
		System.assertEquals(sampleRecord.FSC_Divisor_Tasa__c, result.rateDivisor, 'Debe devolver el divisor de tasa.');
		System.assertEquals(sampleRecord.FSC_Parametros_Formula__c, result.formulaParameters, 'Debe devolver los parametros de formula.');
	}

	@IsTest
	static void testMethodsReturnEmptyWhenFacilityIsBlank() {
		System.assertEquals(
			0,
			FSC_LoanFacilityController.getGuaranteeTypeOptions(null, 'consumo').size(),
			'Sin facilidad no deben devolverse tipos de garantia.'
		);
		System.assertEquals(0, FSC_LoanFacilityController.getInsuranceRateOptions('').size(), 'Sin facilidad no deben devolverse tasas de seguro.');
		System.assertEquals(
			null,
			FSC_LoanFacilityController.getInsuranceRate('', 'Seguro de Vida'),
			'Sin facilidad no debe devolverse una tasa puntual.'
		);
	}

	@IsTest
	static void testInsuranceOptionsReturnEmptyWhenLoanTypeIsBlank() {
		Test.startTest();
		List<FSC_LoanFacilityController.OptionDTO> result = FSC_LoanFacilityController.getGuaranteeTypeOptions('TEST - 401', null);
		Test.stopTest();

		Assert.areEqual(0, result.size(), 'Sin tipo de prestamo no deben devolverse tipos de seguro.');
	}

	@IsTest
	static void testConsumoInsuranceOptionsUseAllActive401Metadata() {
		assertInsuranceOptions('- 401', 'consumo');
	}

	@IsTest
	static void testVehicleInsuranceOptionsUseActiveApplicable401Metadata() {
		assertInsuranceOptions('- 401', 'vehiculo');
	}

	@IsTest
	static void testMortgagePesosInsuranceOptionsUseActiveApplicable402Metadata() {
		assertInsuranceOptions('- 402', 'hipotecario');
	}

	@IsTest
	static void testMortgageDollarsInsuranceOptionsUseActiveApplicable453Metadata() {
		assertInsuranceOptions('- 453', 'hipotecario');
	}

	@IsTest
	static void testConsumoInsuranceOptionsRejectNon401Metadata() {
		assertNoInsuranceOptions('- 404', 'consumo');
	}

	@IsTest
	static void testVehicleInsuranceOptionsRejectNon401Metadata() {
		assertNoInsuranceOptions('- 402', 'vehiculo');
	}

	@IsTest
	static void testMortgageInsuranceOptionsRejectNonMortgageMetadata() {
		assertNoInsuranceOptions('- 401', 'hipotecario');
	}

	private static void assertInsuranceOptions(String facilitySuffix, String loanType) {
		Set<String> expectedApiNames = new Set<String>();
		for (FSC_TiposSeguro__mdt metadataRecord : [
			SELECT DeveloperName, FSC_AplicaHipotecario__c, FSC_AplicaVehiculo__c
			FROM FSC_TiposSeguro__mdt
			WHERE FSC_Facilidad__c = :facilitySuffix AND FSC_Deshabilitado__c = FALSE
		]) {
			Boolean appliesToLoan =
				loanType == 'consumo' ||
				(loanType == 'vehiculo' && metadataRecord.FSC_AplicaVehiculo__c) ||
				(loanType == 'hipotecario' && metadataRecord.FSC_AplicaHipotecario__c);
			if (!appliesToLoan) {
				continue;
			}

			String apiName = metadataRecord.DeveloperName.endsWith('_2')
				? metadataRecord.DeveloperName.substring(0, metadataRecord.DeveloperName.length() - 2)
				: metadataRecord.DeveloperName;
			expectedApiNames.add(apiName);
		}

		Test.startTest();
		List<FSC_LoanFacilityController.OptionDTO> result = FSC_LoanFacilityController.getGuaranteeTypeOptions('TEST ' + facilitySuffix, loanType);
		Test.stopTest();

		Set<String> actualApiNames = new Set<String>();
		for (FSC_LoanFacilityController.OptionDTO option : result) {
			actualApiNames.add(option.value);
		}

		Assert.areEqual(expectedApiNames, actualApiNames, 'Debe filtrar los seguros para ' + loanType + ' y la facilidad ' + facilitySuffix + '.');
	}

	private static void assertNoInsuranceOptions(String facilitySuffix, String loanType) {
		Test.startTest();
		List<FSC_LoanFacilityController.OptionDTO> result = FSC_LoanFacilityController.getGuaranteeTypeOptions('TEST ' + facilitySuffix, loanType);
		Test.stopTest();

		Assert.areEqual(0, result.size(), 'No debe devolver seguros para una facilidad incompatible con ' + loanType + '.');
	}
}