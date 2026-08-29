public with sharing class FSC_LoanFacilityController {
	private static final String FACILITY_SUFFIX_CONSUMO = '- 401';
	private static final Set<String> FACILITY_SUFFIXES_HIPOTECARIO = new Set<String>{ '- 402', '- 453' };

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