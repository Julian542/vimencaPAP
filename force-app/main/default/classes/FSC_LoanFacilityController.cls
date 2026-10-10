public with sharing class FSC_LoanFacilityController {
	private static final String FACILITY_SUFFIX_CONSUMO = '- 401';
	private static final Set<String> FACILITY_SUFFIXES_HIPOTECARIO = new Set<String>{ '- 402', '- 453' };
	public class LoanTermConfigurationDTO {
		@AuraEnabled
		public Integer consumoMaxMonths { get; set; }
		@AuraEnabled
		public Integer referenceYear { get; set; }
		@AuraEnabled
		public List<VehicleTermRangeDTO> vehicleRanges { get; set; }
	}

	public class VehicleTermRangeDTO {
		@AuraEnabled
		public Integer ageFrom { get; set; }
		@AuraEnabled
		public Integer ageTo { get; set; }
		@AuraEnabled
		public Integer maxMonths { get; set; }
	}

	@AuraEnabled(cacheable=true)
	public static LoanTermConfigurationDTO getLoanTermConfiguration() {
		return buildLoanTermConfiguration(
			new Map<String, FSC_PlazoCredito__mdt>{
				'Consumo' => FSC_PlazoCredito__mdt.getInstance('Consumo'),
				'VehiculoNuevo' => FSC_PlazoCredito__mdt.getInstance('VehiculoNuevo'),
				'VehiculoUsadoReciente' => FSC_PlazoCredito__mdt.getInstance('VehiculoUsadoReciente'),
				'VehiculoUsadoAntiguo' => FSC_PlazoCredito__mdt.getInstance('VehiculoUsadoAntiguo')
			}
		);
	}

	@TestVisible
	private static LoanTermConfigurationDTO buildLoanTermConfiguration(Map<String, FSC_PlazoCredito__mdt> settings) {
		FSC_PlazoCredito__mdt consumo = settings?.get('Consumo');
		if (consumo == null || !isValidLoanTerm(consumo.FSC_PlazoMaximo__c)) {
			throw invalidLoanTermConfiguration();
		}
		LoanTermConfigurationDTO result = new LoanTermConfigurationDTO();
		result.consumoMaxMonths = consumo.FSC_PlazoMaximo__c.intValue();
		result.referenceYear = Date.today().year();
		result.vehicleRanges = new List<VehicleTermRangeDTO>();
		Integer nextAge = 0;
		Integer previousTerm = 999;
		for (String recordName : new List<String>{ 'VehiculoNuevo', 'VehiculoUsadoReciente', 'VehiculoUsadoAntiguo' }) {
			FSC_PlazoCredito__mdt setting = settings.get(recordName);
			if (
				!isValidVehicleAgeRange(setting, nextAge) ||
				!isValidLoanTerm(setting.FSC_PlazoMaximo__c) ||
				setting.FSC_PlazoMaximo__c > previousTerm
			) {
				throw invalidLoanTermConfiguration();
			}
			VehicleTermRangeDTO range = new VehicleTermRangeDTO();
			range.ageFrom = setting.FSC_AnioDesde__c.intValue();
			range.ageTo = setting.FSC_AnioHasta__c.intValue();
			range.maxMonths = setting.FSC_PlazoMaximo__c.intValue();
			result.vehicleRanges.add(range);
			nextAge = range.ageTo + 1;
			previousTerm = range.maxMonths;
		}
		return result;
	}

	private static Boolean isValidVehicleAgeRange(FSC_PlazoCredito__mdt setting, Integer nextAge) {
		return setting != null &&
			setting.FSC_AnioDesde__c == nextAge &&
			setting.FSC_AnioHasta__c != null &&
			setting.FSC_AnioHasta__c >= nextAge &&
			setting.FSC_AnioHasta__c <= 99 &&
			setting.FSC_AnioHasta__c == setting.FSC_AnioHasta__c.intValue();
	}

	private static Boolean isValidLoanTerm(Decimal value) {
		return value != null && value >= 1 && value <= 999 && value == value.intValue();
	}

	private static AuraHandledException invalidLoanTermConfiguration() {
		String message = 'Revise los plazos configurados y las tres franjas de vehículo: deben ser consecutivas desde 0, sin solapamientos, y el plazo no debe aumentar con la antigüedad.';
		AuraHandledException error = new AuraHandledException(message);
		error.setMessage(message);
		return error;
	}
	public class GuaranteeClassDTO {
		@AuraEnabled
		public String value { get; set; }
		@AuraEnabled
		public String groupName { get; set; }
		@AuraEnabled
		public List<GuaranteeTypeDTO> types { get; set; }
		@AuraEnabled
		public Integer code { get; set; }
		// Textos historicos de la misma clase, para reconocer garantias guardadas antes del catalogo.
		@AuraEnabled
		public List<String> aliases { get; set; }
		@AuraEnabled
		public Boolean fromCatalog { get; set; }
	}

	public class GuaranteeTypeDTO implements Comparable {
		@AuraEnabled
		public String value { get; set; }
		@AuraEnabled
		public Integer code { get; set; }
		public Decimal sortOrder;

		public Integer compareTo(Object other) {
			GuaranteeTypeDTO otherType = (GuaranteeTypeDTO) other;
			if (sortOrder == otherType.sortOrder) {
				return value.compareTo(otherType.value);
			}
			return sortOrder < otherType.sortOrder ? -1 : 1;
		}
	}

	public class VehicleOptionDTO {
		@AuraEnabled
		public String label { get; set; }
		@AuraEnabled
		public String value { get; set; }
		@AuraEnabled
		public Integer code { get; set; }
		@AuraEnabled
		public List<VehicleOptionDTO> models { get; set; }
	}

	@AuraEnabled(cacheable=true)
	public static List<GuaranteeClassDTO> getGuaranteeConfiguration() {
		// Sin catalogo sincronizado se mantiene la configuracion historica del CMT.
		if (FSC_CatalogoGarantiaService.tieneCatalogo()) {
			return buildCatalogConfiguration(
				FSC_CatalogoGarantiaService.getActivos(FSC_CatalogoGarantiaService.CATALOGO_CLASE),
				FSC_CatalogoGarantiaService.getActivos(FSC_CatalogoGarantiaService.CATALOGO_TIPO),
				FSC_ClaseGarantia__mdt.getAll().values()
			);
		}
		return buildGuaranteeConfiguration(FSC_ClaseGarantia__mdt.getAll().values(), FSC_TipoGarantia__mdt.getAll().values());
	}

	@TestVisible
	private static List<GuaranteeClassDTO> buildCatalogConfiguration(
		List<FSC_CatalogoGarantia__c> classRecords,
		List<FSC_CatalogoGarantia__c> typeRecords,
		List<FSC_ClaseGarantia__mdt> classSettings
	) {
		Map<Integer, String> groupByCode = new Map<Integer, String>();
		Map<Integer, List<String>> aliasesByCode = new Map<Integer, List<String>>();
		for (FSC_ClaseGarantia__mdt setting : classSettings) {
			if (setting.FSC_Codigo__c == null) {
				continue;
			}
			Integer code = setting.FSC_Codigo__c.intValue();
			if (!String.isBlank(setting.FSC_Grupo__c)) {
				groupByCode.put(code, setting.FSC_Grupo__c);
			}
			if (!aliasesByCode.containsKey(code)) {
				aliasesByCode.put(code, new List<String>());
			}
			if (!String.isBlank(setting.FSC_Valor__c)) {
				aliasesByCode.get(code).add(setting.FSC_Valor__c);
			}
		}

		Map<Integer, GuaranteeClassDTO> classesByCode = new Map<Integer, GuaranteeClassDTO>();
		List<GuaranteeClassDTO> result = new List<GuaranteeClassDTO>();
		for (FSC_CatalogoGarantia__c classRecord : classRecords) {
			Integer code = classRecord.FSC_Codigo__c == null ? null : classRecord.FSC_Codigo__c.intValue();
			if (code == null || String.isBlank(classRecord.FSC_Descripcion__c) || classesByCode.containsKey(code)) {
				continue;
			}
			GuaranteeClassDTO configuration = new GuaranteeClassDTO();
			configuration.value = classRecord.FSC_Descripcion__c;
			configuration.code = code;
			configuration.groupName = groupByCode.containsKey(code) ? groupByCode.get(code) : FSC_CatalogoGarantiaService.GRUPO_GENERAL;
			configuration.aliases = aliasesByCode.containsKey(code) ? aliasesByCode.get(code) : new List<String>();
			configuration.types = new List<GuaranteeTypeDTO>();
			configuration.fromCatalog = true;
			classesByCode.put(code, configuration);
			result.add(configuration);
		}

		Set<String> typeKeys = new Set<String>();
		for (FSC_CatalogoGarantia__c typeRecord : typeRecords) {
			Integer classCode = typeRecord.FSC_Codigo_Padre__c == null ? null : typeRecord.FSC_Codigo_Padre__c.intValue();
			GuaranteeClassDTO configuration = classesByCode.get(classCode);
			if (
				configuration == null ||
				String.isBlank(typeRecord.FSC_Descripcion__c) ||
				!typeKeys.add(classCode + ':' + typeRecord.FSC_Descripcion__c)
			) {
				continue;
			}
			GuaranteeTypeDTO option = new GuaranteeTypeDTO();
			option.value = typeRecord.FSC_Descripcion__c;
			option.code = typeRecord.FSC_Codigo__c == null ? null : typeRecord.FSC_Codigo__c.intValue();
			option.sortOrder = 0;
			configuration.types.add(option);
		}
		for (GuaranteeClassDTO configuration : result) {
			configuration.types.sort();
		}
		return result;
	}

	@AuraEnabled(cacheable=true)
	public static List<VehicleOptionDTO> getVehicleCatalog() {
		return buildVehicleCatalog(
			FSC_CatalogoGarantiaService.getActivos(FSC_CatalogoGarantiaService.CATALOGO_MARCA),
			FSC_CatalogoGarantiaService.getActivos(FSC_CatalogoGarantiaService.CATALOGO_MODELO)
		);
	}

	@TestVisible
	private static List<VehicleOptionDTO> buildVehicleCatalog(
		List<FSC_CatalogoGarantia__c> brandRecords,
		List<FSC_CatalogoGarantia__c> modelRecords
	) {
		Map<Integer, VehicleOptionDTO> brandsByCode = new Map<Integer, VehicleOptionDTO>();
		List<VehicleOptionDTO> brands = new List<VehicleOptionDTO>();
		for (FSC_CatalogoGarantia__c brandRecord : brandRecords) {
			Integer code = brandRecord.FSC_Codigo__c == null ? null : brandRecord.FSC_Codigo__c.intValue();
			if (code == null || String.isBlank(brandRecord.FSC_Descripcion__c) || brandsByCode.containsKey(code)) {
				continue;
			}
			VehicleOptionDTO brand = createVehicleOption(brandRecord.FSC_Descripcion__c, code);
			brand.models = new List<VehicleOptionDTO>();
			brandsByCode.put(code, brand);
			brands.add(brand);
		}

		Set<String> modelKeys = new Set<String>();
		for (FSC_CatalogoGarantia__c modelRecord : modelRecords) {
			Integer brandCode = modelRecord.FSC_Codigo_Padre__c == null ? null : modelRecord.FSC_Codigo_Padre__c.intValue();
			VehicleOptionDTO brand = brandsByCode.get(brandCode);
			// Un mismo nombre de modelo puede repetirse dentro de la marca; se muestra una sola vez.
			if (
				brand == null ||
				String.isBlank(modelRecord.FSC_Descripcion__c) ||
				!modelKeys.add(brandCode + ':' + FSC_CatalogoGarantiaService.normalizarClave(modelRecord.FSC_Descripcion__c))
			) {
				continue;
			}
			brand.models.add(createVehicleOption(modelRecord.FSC_Descripcion__c, modelRecord.FSC_Codigo__c.intValue()));
		}
		return brands;
	}

	private static VehicleOptionDTO createVehicleOption(String description, Integer code) {
		VehicleOptionDTO option = new VehicleOptionDTO();
		option.label = description;
		option.value = description;
		option.code = code;
		return option;
	}

	@TestVisible
	private static List<GuaranteeClassDTO> buildGuaranteeConfiguration(
		List<FSC_ClaseGarantia__mdt> classRecords,
		List<FSC_TipoGarantia__mdt> typeRecords
	) {
		if (classRecords.isEmpty()) {
			throw new AuraHandledException('No hay clases de garantia configuradas. Contacte al administrador.');
		}
		Map<Id, GuaranteeClassDTO> classesById = new Map<Id, GuaranteeClassDTO>();
		Set<String> classValues = new Set<String>();
		Set<String> supportedGroups = new Set<String>{ 'general', 'real-estate', 'vehicle' };
		for (FSC_ClaseGarantia__mdt classRecord : classRecords) {
			if (
				String.isBlank(classRecord.FSC_Valor__c) ||
				!supportedGroups.contains(classRecord.FSC_Grupo__c) ||
				!classValues.add(classRecord.FSC_Valor__c.trim().toLowerCase())
			) {
				throw new AuraHandledException('La configuracion de clases de garantia no es valida. Contacte al administrador.');
			}
			GuaranteeClassDTO configuration = new GuaranteeClassDTO();
			configuration.value = classRecord.FSC_Valor__c;
			configuration.groupName = classRecord.FSC_Grupo__c;
			configuration.types = new List<GuaranteeTypeDTO>();
			configuration.code = classRecord.FSC_Codigo__c == null ? null : classRecord.FSC_Codigo__c.intValue();
			configuration.aliases = new List<String>();
			configuration.fromCatalog = false;
			classesById.put(classRecord.Id, configuration);
		}
		Set<String> typeValues = new Set<String>();
		for (FSC_TipoGarantia__mdt typeRecord : typeRecords) {
			GuaranteeClassDTO configuration = classesById.get(typeRecord.FSC_Clase__c);
			if (
				configuration == null ||
				String.isBlank(typeRecord.FSC_Valor__c) ||
				!typeValues.add(typeRecord.FSC_Clase__c + ':' + typeRecord.FSC_Valor__c)
			) {
				throw new AuraHandledException('La configuracion de tipos de garantia no es valida. Contacte al administrador.');
			}
			GuaranteeTypeDTO option = new GuaranteeTypeDTO();
			option.value = typeRecord.FSC_Valor__c;
			option.sortOrder = typeRecord.FSC_Orden__c == null ? 0 : typeRecord.FSC_Orden__c;
			configuration.types.add(option);
		}
		for (GuaranteeClassDTO configuration : classesById.values()) {
			configuration.types.sort();
		}
		return classesById.values();
	}

	public class OptionDTO {
		@AuraEnabled
		public String label { get; set; }
		@AuraEnabled
		public String value { get; set; }
		@AuraEnabled
		public Decimal rate { get; set; }
		@AuraEnabled
		public String calculationType { get; set; }
		@AuraEnabled
		public String calculationBase { get; set; }
		@AuraEnabled
		public Decimal rateDivisor { get; set; }
		@AuraEnabled
		public String formulaParameters { get; set; }
	}

	public class InsuranceRateDTO {
		@AuraEnabled
		public String label { get; set; }
		@AuraEnabled
		public Decimal rate { get; set; }
		@AuraEnabled
		public String calculationType { get; set; }
		@AuraEnabled
		public String calculationBase { get; set; }
		@AuraEnabled
		public Decimal rateDivisor { get; set; }
		@AuraEnabled
		public String formulaParameters { get; set; }
	}

	@AuraEnabled(cacheable=true)
	public static List<OptionDTO> getGuaranteeTypeOptions(String facilityValue, String loanType) {
		String facilitySuffix = getInsuranceFacilitySuffix(facilityValue, loanType);
		if (String.isBlank(facilitySuffix)) {
			return new List<OptionDTO>();
		}

		List<OptionDTO> options = new List<OptionDTO>();
		Set<String> addedValues = new Set<String>();

		for (FSC_TiposSeguro__mdt tipoSeguroRecord : getInsuranceMetadataByFacility(facilitySuffix)) {
			if (!appliesToLoanType(tipoSeguroRecord, loanType)) {
				continue;
			}

			String optionValue = getCanonicalInsuranceType(tipoSeguroRecord.DeveloperName);
			if (String.isBlank(tipoSeguroRecord.FSC_Label__c) || addedValues.contains(optionValue)) {
				continue;
			}

			addedValues.add(optionValue);

			OptionDTO option = new OptionDTO();
			option.label = tipoSeguroRecord.FSC_Label__c;
			option.value = optionValue;
			option.rate = tipoSeguroRecord.FSC_Tasa__c;
			option.calculationType = tipoSeguroRecord.FSC_Tipo_Calculo_Prima__c;
			option.calculationBase = tipoSeguroRecord.FSC_Base_Calculo_Prima__c;
			option.rateDivisor = tipoSeguroRecord.FSC_Divisor_Tasa__c;
			option.formulaParameters = tipoSeguroRecord.FSC_Parametros_Formula__c;
			options.add(option);
		}

		return options;
	}

	@AuraEnabled(cacheable=true)
	public static List<InsuranceRateDTO> getInsuranceRateOptions(String facilityValue) {
		String facilitySuffix = getLastFiveCharacters(facilityValue);
		if (String.isBlank(facilitySuffix)) {
			return new List<InsuranceRateDTO>();
		}

		List<InsuranceRateDTO> rates = new List<InsuranceRateDTO>();
		Set<String> addedValues = new Set<String>();

		for (FSC_TiposSeguro__mdt tipoSeguroRecord : getInsuranceMetadataByFacility(facilitySuffix)) {
			if (String.isBlank(tipoSeguroRecord.FSC_Label__c) || addedValues.contains(tipoSeguroRecord.FSC_Label__c)) {
				continue;
			}

			addedValues.add(tipoSeguroRecord.FSC_Label__c);

			InsuranceRateDTO rateOption = new InsuranceRateDTO();
			rateOption.label = tipoSeguroRecord.FSC_Label__c;
			rateOption.rate = tipoSeguroRecord.FSC_Tasa__c;
			populateCalculationConfiguration(rateOption, tipoSeguroRecord);
			rates.add(rateOption);
		}

		return rates;
	}

	@AuraEnabled(cacheable=true)
	public static InsuranceRateDTO getInsuranceRate(String facilityValue, String insuranceType) {
		String facilitySuffix = getLastFiveCharacters(facilityValue);
		if (String.isBlank(facilitySuffix) || String.isBlank(insuranceType)) {
			return null;
		}

		Set<String> insuranceTypeDeveloperNames = new Set<String>{ insuranceType, insuranceType + '_2' };

		List<FSC_TiposSeguro__mdt> insuranceMetadata = [
			SELECT
				DeveloperName,
				FSC_Label__c,
				FSC_Tasa__c,
				FSC_Tipo_Calculo_Prima__c,
				FSC_Base_Calculo_Prima__c,
				FSC_Divisor_Tasa__c,
				FSC_Parametros_Formula__c
			FROM FSC_TiposSeguro__mdt
			WHERE FSC_Facilidad__c = :facilitySuffix AND DeveloperName IN :insuranceTypeDeveloperNames AND FSC_Deshabilitado__c = FALSE
			WITH USER_MODE
			ORDER BY MasterLabel
			LIMIT 1
		];

		if (insuranceMetadata.isEmpty()) {
			return null;
		}

		InsuranceRateDTO rateOption = new InsuranceRateDTO();
		rateOption.label = insuranceMetadata[0].FSC_Label__c;
		rateOption.rate = insuranceMetadata[0].FSC_Tasa__c;
		populateCalculationConfiguration(rateOption, insuranceMetadata[0]);
		return rateOption;
	}

	private static void populateCalculationConfiguration(InsuranceRateDTO target, FSC_TiposSeguro__mdt source) {
		target.calculationType = source.FSC_Tipo_Calculo_Prima__c;
		target.calculationBase = source.FSC_Base_Calculo_Prima__c;
		target.rateDivisor = source.FSC_Divisor_Tasa__c;
		target.formulaParameters = source.FSC_Parametros_Formula__c;
	}

	private static List<FSC_TiposSeguro__mdt> getInsuranceMetadataByFacility(String facilitySuffix) {
		return [
			SELECT
				DeveloperName,
				MasterLabel,
				FSC_Label__c,
				FSC_Facilidad__c,
				FSC_Tasa__c,
				FSC_AplicaHipotecario__c,
				FSC_AplicaVehiculo__c,
				FSC_Tipo_Calculo_Prima__c,
				FSC_Base_Calculo_Prima__c,
				FSC_Divisor_Tasa__c,
				FSC_Parametros_Formula__c
			FROM FSC_TiposSeguro__mdt
			WHERE FSC_Facilidad__c = :facilitySuffix AND FSC_Deshabilitado__c = FALSE
			WITH USER_MODE
			ORDER BY FSC_Label__c, MasterLabel
		];
	}

	private static String getLastFiveCharacters(String value) {
		if (String.isBlank(value)) {
			return null;
		}

		String trimmedValue = value.trim();
		Integer startIndex = Math.max(0, trimmedValue.length() - 5);
		return trimmedValue.substring(startIndex);
	}

	private static String getInsuranceFacilitySuffix(String facilityValue, String loanType) {
		String facilitySuffix = getLastFiveCharacters(facilityValue);
		String normalizedLoanType = normalizeLoanType(loanType);
		if (String.isBlank(facilitySuffix) || String.isBlank(normalizedLoanType)) {
			return null;
		}

		if (normalizedLoanType == 'consumo' || normalizedLoanType == 'vehiculo') {
			return facilitySuffix == FACILITY_SUFFIX_CONSUMO ? facilitySuffix : null;
		}

		if (normalizedLoanType == 'hipotecario') {
			return FACILITY_SUFFIXES_HIPOTECARIO.contains(facilitySuffix) ? facilitySuffix : null;
		}

		return null;
	}

	private static String getCanonicalInsuranceType(String developerName) {
		return developerName != null && developerName.endsWith('_2') ? developerName.substring(0, developerName.length() - 2) : developerName;
	}

	private static Boolean appliesToLoanType(FSC_TiposSeguro__mdt insuranceType, String loanType) {
		String normalizedLoanType = normalizeLoanType(loanType);

		if (normalizedLoanType == 'consumo') {
			return true;
		}
		if (normalizedLoanType == 'vehiculo') {
			return insuranceType.FSC_AplicaVehiculo__c;
		}
		if (normalizedLoanType == 'hipotecario') {
			return insuranceType.FSC_AplicaHipotecario__c;
		}

		return true;
	}

	private static String normalizeLoanType(String loanType) {
		return String.isBlank(loanType) ? '' : loanType.trim().toLowerCase();
	}
}