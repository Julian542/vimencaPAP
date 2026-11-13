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

	@IsTest
	static void shouldReturnConfiguredTerms() {
		Test.startTest();
		FSC_LoanFacilityController.LoanTermConfigurationDTO result = FSC_LoanFacilityController.buildLoanTermConfiguration(loanTermSettings());
		Test.stopTest();
		Assert.areEqual(60, result.consumoMaxMonths, 'Consumo debe usar el plazo configurado.');
		Assert.areEqual(Date.today().year(), result.referenceYear, 'La antigüedad debe usar el año de Salesforce.');
		Assert.areEqual(3, result.vehicleRanges.size(), 'Deben existir tres franjas.');
		Assert.areEqual(84, result.vehicleRanges[0].maxMonths, 'Nuevo debe permitir 84 meses.');
		Assert.areEqual(72, result.vehicleRanges[1].maxMonths, 'Usado reciente debe permitir 72 meses.');
		Assert.areEqual(60, result.vehicleRanges[2].maxMonths, 'Usado antiguo debe permitir 60 meses.');
		Assert.areEqual(7, result.vehicleRanges[2].ageTo, 'La antigüedad máxima debe venir de la configuración.');
	}

	@IsTest
	static void shouldReadCustomMetadataWithoutQueries() {
		Test.startTest();
		Integer initialQueries = Limits.getQueries();
		FSC_LoanFacilityController.LoanTermConfigurationDTO result = FSC_LoanFacilityController.getLoanTermConfiguration();
		Integer queriesUsed = Limits.getQueries() - initialQueries;
		Test.stopTest();
		Assert.areEqual(
			FSC_PlazoCredito__mdt.getInstance('Consumo').FSC_PlazoMaximo__c.intValue(),
			result.consumoMaxMonths,
			'Debe leer Custom Metadata.'
		);
		Assert.areEqual(0, queriesUsed, 'La lectura de configuración no debe consumir consultas.');
	}

	@IsTest
	static void shouldUseChangedConfiguration() {
		Map<String, FSC_PlazoCredito__mdt> records = loanTermSettings();
		records.get('Consumo').FSC_PlazoMaximo__c = 48;
		records.get('VehiculoUsadoReciente').FSC_AnioHasta__c = 3;
		records.get('VehiculoUsadoReciente').FSC_PlazoMaximo__c = 66;
		records.get('VehiculoUsadoAntiguo').FSC_AnioDesde__c = 4;
		records.get('VehiculoUsadoAntiguo').FSC_AnioHasta__c = 8;
		records.get('VehiculoUsadoAntiguo').FSC_PlazoMaximo__c = 54;
		Test.startTest();
		FSC_LoanFacilityController.LoanTermConfigurationDTO result = FSC_LoanFacilityController.buildLoanTermConfiguration(records);
		Test.stopTest();
		Assert.areEqual(48, result.consumoMaxMonths, 'Consumo no debe estar hardcodeado.');
		Assert.areEqual(3, result.vehicleRanges[1].ageTo, 'El límite de la franja debe ser parametrico.');
		Assert.areEqual(54, result.vehicleRanges[2].maxMonths, 'El plazo de vehículo debe ser parametrico.');
		Assert.areEqual(8, result.vehicleRanges[2].ageTo, 'La antigüedad máxima debe ser parametrica.');
	}

	@IsTest
	static void shouldRejectNullConfiguration() {
		assertInvalidLoanTermConfiguration(null);
	}

	@IsTest
	static void shouldRejectMissingConsumption() {
		Map<String, FSC_PlazoCredito__mdt> records = loanTermSettings();
		records.remove('Consumo');
		assertInvalidLoanTermConfiguration(records);
	}

	@IsTest
	static void shouldRejectMissingVehicleRange() {
		Map<String, FSC_PlazoCredito__mdt> records = loanTermSettings();
		records.remove('VehiculoUsadoReciente');
		assertInvalidLoanTermConfiguration(records);
	}

	@IsTest
	static void shouldRejectOverlappingRanges() {
		Map<String, FSC_PlazoCredito__mdt> records = loanTermSettings();
		records.get('VehiculoUsadoAntiguo').FSC_AnioDesde__c = 2;
		assertInvalidLoanTermConfiguration(records);
	}

	@IsTest
	static void shouldRejectGapBetweenRanges() {
		Map<String, FSC_PlazoCredito__mdt> records = loanTermSettings();
		records.get('VehiculoUsadoAntiguo').FSC_AnioDesde__c = 4;
		assertInvalidLoanTermConfiguration(records);
	}

	@IsTest
	static void shouldRejectIncreasingTerms() {
		Map<String, FSC_PlazoCredito__mdt> records = loanTermSettings();
		records.get('VehiculoUsadoAntiguo').FSC_PlazoMaximo__c = 80;
		assertInvalidLoanTermConfiguration(records);
	}

	@IsTest
	static void shouldRejectZeroConsumptionTerm() {
		Map<String, FSC_PlazoCredito__mdt> records = loanTermSettings();
		records.get('Consumo').FSC_PlazoMaximo__c = 0;
		assertInvalidLoanTermConfiguration(records);
	}

	@IsTest
	static void shouldRejectFractionalAge() {
		Map<String, FSC_PlazoCredito__mdt> records = loanTermSettings();
		records.get('VehiculoUsadoAntiguo').FSC_AnioHasta__c = 7.5;
		assertInvalidLoanTermConfiguration(records);
	}

	@IsTest
	static void shouldHandle251ReadsWithoutQueriesOrDml() {
		Map<String, FSC_PlazoCredito__mdt> records = loanTermSettings();
		Test.startTest();
		Integer queriesBefore = Limits.getQueries();
		Integer dmlBefore = Limits.getDmlStatements();
		for (Integer index = 0; index < 251; index++) {
			FSC_LoanFacilityController.LoanTermConfigurationDTO result = FSC_LoanFacilityController.buildLoanTermConfiguration(records);
			Assert.areEqual(60, result.vehicleRanges[2].maxMonths, 'Cada lectura debe mantener el límite configurado.');
		}
		Assert.areEqual(queriesBefore, Limits.getQueries(), 'No debe haber SOQL en el procesamiento masivo.');
		Assert.areEqual(dmlBefore, Limits.getDmlStatements(), 'No debe haber DML en el procesamiento masivo.');
		Test.stopTest();
	}

	private static void assertInvalidLoanTermConfiguration(Map<String, FSC_PlazoCredito__mdt> records) {
		Test.startTest();
		try {
			FSC_LoanFacilityController.buildLoanTermConfiguration(records);
			Assert.fail('Debe rechazar la configuración inválida.');
		} catch (AuraHandledException error) {
			Assert.isTrue(error.getMessage().contains('Revise los plazos configurados'), 'Debe explicar el error de configuración.');
		}
		Test.stopTest();
	}

	private static Map<String, FSC_PlazoCredito__mdt> loanTermSettings() {
		// Custom Metadata se simula en memoria; no requiere datos persistidos ni @testSetup.
		return new Map<String, FSC_PlazoCredito__mdt>{
			'Consumo' => new FSC_PlazoCredito__mdt(FSC_PlazoMaximo__c = 60),
			'VehiculoNuevo' => new FSC_PlazoCredito__mdt(FSC_AnioDesde__c = 0, FSC_AnioHasta__c = 0, FSC_PlazoMaximo__c = 84),
			'VehiculoUsadoReciente' => new FSC_PlazoCredito__mdt(FSC_AnioDesde__c = 1, FSC_AnioHasta__c = 2, FSC_PlazoMaximo__c = 72),
			'VehiculoUsadoAntiguo' => new FSC_PlazoCredito__mdt(FSC_AnioDesde__c = 3, FSC_AnioHasta__c = 7, FSC_PlazoMaximo__c = 60)
		};
	}

	@IsTest
	static void shouldBuildCatalogWithAliasesAndUniqueTypes() {
		List<FSC_CatalogoGarantia__c> classes = new List<FSC_CatalogoGarantia__c>{
			new FSC_CatalogoGarantia__c(FSC_Codigo__c = 22, FSC_Descripcion__c = 'Vehículos del catálogo'),
			new FSC_CatalogoGarantia__c(FSC_Codigo__c = 22, FSC_Descripcion__c = 'Clase duplicada'),
			new FSC_CatalogoGarantia__c(FSC_Descripcion__c = 'Clase sin código'),
			new FSC_CatalogoGarantia__c(FSC_Codigo__c = 23, FSC_Descripcion__c = ''),
			new FSC_CatalogoGarantia__c(FSC_Codigo__c = 24, FSC_Descripcion__c = 'Garantía general')
		};
		List<FSC_ClaseGarantia__mdt> settings = new List<FSC_ClaseGarantia__mdt>{
			new FSC_ClaseGarantia__mdt(FSC_Codigo__c = 22, FSC_Grupo__c = 'vehicle', FSC_Valor__c = 'Vehículos históricos'),
			new FSC_ClaseGarantia__mdt(FSC_Codigo__c = 22, FSC_Valor__c = 'Otra descripción histórica'),
			new FSC_ClaseGarantia__mdt(FSC_Valor__c = 'Sin código')
		};
		List<FSC_CatalogoGarantia__c> types = new List<FSC_CatalogoGarantia__c>{
			new FSC_CatalogoGarantia__c(FSC_Codigo__c = 6, FSC_Codigo_Padre__c = 22, FSC_Descripcion__c = 'Zeta'),
			new FSC_CatalogoGarantia__c(FSC_Codigo__c = 7, FSC_Codigo_Padre__c = 22, FSC_Descripcion__c = 'Alfa'),
			new FSC_CatalogoGarantia__c(FSC_Codigo_Padre__c = 22, FSC_Descripcion__c = 'Zeta'),
			new FSC_CatalogoGarantia__c(FSC_Codigo_Padre__c = 99, FSC_Descripcion__c = 'Tipo sin clase'),
			new FSC_CatalogoGarantia__c(FSC_Codigo_Padre__c = 22, FSC_Descripcion__c = '')
		};
		Test.startTest();
		List<FSC_LoanFacilityController.GuaranteeClassDTO> result = FSC_LoanFacilityController.buildCatalogConfiguration(classes, types, settings);
		Test.stopTest();
		Assert.areEqual(2, result.size(), 'Debe excluir clases inválidas y duplicadas.');
		Assert.areEqual('vehicle', result[0].groupName, 'El grupo debe provenir de la configuración.');
		Assert.areEqual(2, result[0].aliases.size(), 'Debe conservar las dos descripciones históricas.');
		Assert.areEqual(true, result[0].fromCatalog, 'Debe identificar el origen del catálogo.');
		Assert.areEqual(22, result[0].code, 'Debe conservar el código de clase.');
		Assert.areEqual(2, result[0].types.size(), 'Debe excluir tipos inválidos y duplicados.');
		Assert.areEqual('Alfa', result[0].types[0].value, 'Debe ordenar los tipos alfabéticamente.');
		Assert.areEqual(7, result[0].types[0].code, 'Debe conservar el código del tipo.');
		Assert.areEqual('general', result[1].groupName, 'Sin configuración debe usar el grupo general.');
	}

	@IsTest
	static void shouldBuildVehicleCatalogWithoutDuplicateModels() {
		List<FSC_CatalogoGarantia__c> brands = new List<FSC_CatalogoGarantia__c>{
			new FSC_CatalogoGarantia__c(FSC_Codigo__c = 10, FSC_Descripcion__c = 'Marca A'),
			new FSC_CatalogoGarantia__c(FSC_Codigo__c = 20, FSC_Descripcion__c = 'Marca B'),
			new FSC_CatalogoGarantia__c(FSC_Codigo__c = 10, FSC_Descripcion__c = 'Marca duplicada'),
			new FSC_CatalogoGarantia__c(FSC_Descripcion__c = 'Sin código'),
			new FSC_CatalogoGarantia__c(FSC_Codigo__c = 30, FSC_Descripcion__c = '')
		};
		List<FSC_CatalogoGarantia__c> models = new List<FSC_CatalogoGarantia__c>{
			new FSC_CatalogoGarantia__c(FSC_Codigo__c = 100, FSC_Codigo_Padre__c = 10, FSC_Descripcion__c = 'Modelo A'),
			new FSC_CatalogoGarantia__c(FSC_Codigo__c = 101, FSC_Codigo_Padre__c = 10, FSC_Descripcion__c = 'MODELO A'),
			new FSC_CatalogoGarantia__c(FSC_Codigo__c = 102, FSC_Codigo_Padre__c = 10, FSC_Descripcion__c = 'Modelo B'),
			new FSC_CatalogoGarantia__c(FSC_Codigo__c = 103, FSC_Codigo_Padre__c = 20, FSC_Descripcion__c = 'Modelo C'),
			new FSC_CatalogoGarantia__c(FSC_Codigo_Padre__c = 99, FSC_Descripcion__c = 'Sin marca'),
			new FSC_CatalogoGarantia__c(FSC_Codigo_Padre__c = 10, FSC_Descripcion__c = '')
		};
		Test.startTest();
		List<FSC_LoanFacilityController.VehicleOptionDTO> result = FSC_LoanFacilityController.buildVehicleCatalog(brands, models);
		Test.stopTest();
		Assert.areEqual(2, result.size(), 'Debe excluir marcas inválidas y duplicadas.');
		Assert.areEqual('Marca A', result[0].label, 'Debe conservar la marca.');
		Assert.areEqual(10, result[0].code, 'Debe conservar su código.');
		Assert.areEqual(2, result[0].models.size(), 'Debe normalizar y excluir modelos duplicados.');
		Assert.areEqual('Modelo B', result[0].models[1].value, 'Debe asociar el modelo a su marca.');
		Assert.areEqual(102, result[0].models[1].code, 'Debe conservar el código del modelo.');
		Assert.areEqual(1, result[1].models.size(), 'La otra marca debe contener solo su modelo.');
	}

	@IsTest
	static void shouldReturnEmptyVehicleCatalogWithoutRecords() {
		Test.startTest();
		List<FSC_LoanFacilityController.VehicleOptionDTO> result = FSC_LoanFacilityController.getVehicleCatalog();
		Test.stopTest();
		Assert.areEqual(0, result.size(), 'Sin registros debe devolver un catálogo vacío.');
	}

	@IsTest
	static void shouldBuildMetadataGuaranteesWithOrderedTypes() {
		Id classId = Id.valueOf(FSC_ClaseGarantia__mdt.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getKeyPrefix() + '000000000001');
		List<FSC_ClaseGarantia__mdt> classes = new List<FSC_ClaseGarantia__mdt>{
			new FSC_ClaseGarantia__mdt(Id = classId, FSC_Valor__c = 'Vehículos', FSC_Grupo__c = 'vehicle', FSC_Codigo__c = 22)
		};
		List<FSC_TipoGarantia__mdt> types = new List<FSC_TipoGarantia__mdt>{
			new FSC_TipoGarantia__mdt(FSC_Clase__c = classId, FSC_Valor__c = 'Zeta', FSC_Orden__c = 2),
			new FSC_TipoGarantia__mdt(FSC_Clase__c = classId, FSC_Valor__c = 'Alfa', FSC_Orden__c = 2),
			new FSC_TipoGarantia__mdt(FSC_Clase__c = classId, FSC_Valor__c = 'Prioritario', FSC_Orden__c = 1)
		};
		Test.startTest();
		List<FSC_LoanFacilityController.GuaranteeClassDTO> result = FSC_LoanFacilityController.buildGuaranteeConfiguration(classes, types);
		Test.stopTest();
		Assert.areEqual(1, result.size(), 'Debe devolver la clase configurada.');
		Assert.areEqual(false, result[0].fromCatalog, 'Debe indicar que usa metadata histórica.');
		Assert.areEqual('Vehículos', result[0].value, 'Debe conservar el valor de la clase.');
		Assert.areEqual(3, result[0].types.size(), 'Debe incluir todos los tipos configurados.');
		Assert.areEqual('Prioritario', result[0].types[0].value, 'Debe ordenar primero por prioridad.');
		Assert.areEqual('Alfa', result[0].types[1].value, 'A igual prioridad debe ordenar por nombre.');
		Assert.areEqual('Zeta', result[0].types[2].value, 'Debe preservar el orden completo.');
	}

	@IsTest
	static void shouldRejectEmptyGuaranteeMetadata() {
		Test.startTest();
		try {
			FSC_LoanFacilityController.buildGuaranteeConfiguration(new List<FSC_ClaseGarantia__mdt>(), new List<FSC_TipoGarantia__mdt>());
			Assert.fail('Debe rechazar una configuración sin clases.');
		} catch (AuraHandledException error) {
			Assert.isNotNull(error, 'Debe informar el error de configuración.');
		}
		Test.stopTest();
	}
}