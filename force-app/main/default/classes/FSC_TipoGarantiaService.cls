public without sharing class FSC_TipoGarantiaService {
	public static final String GARANTIA_PRENDARIA = 'Garantía Prendaria y/o Mobiliaria';
	public static final String GARANTIA_SOLIDARIA = 'Garantía Solidaria';
	public static final String GARANTIA_REAL = 'Garantía Real';
	public static final String SIN_GARANTIA = 'Sin Garantía';

	private static final Set<String> SUPPORTED_RECORD_TYPES = new Set<String>{
		'FSC_Solicitud_Credito_Consumo',
		'FSC_Solicitud_Credito_Hipotecario',
		'FSC_Solicitud_Credito_PYME',
		'FSC_Solicitud_Credito_Vehiculo'
	};

	private static final Set<String> REAL_ASSET_CODES = new Set<String>{
		'3', '6', '9', '10', '12', '27', '29', '36', '37', '38',
		'69', '76', '81', '82', '83', '84'
	};

	private static final Set<String> MOVABLE_ASSET_CODES = new Set<String>{
		'7', '8', '15', '16', '28', '31', '33', '34', '39',
		'49', '50', '51', '52', '53', '54', '55', '56', '57', '58',
		'59', '60', '61', '62', '63', '64', '65', '66', '68', '71',
		'72', '73', '74', '75', '77', '80'
	};

	private static final Set<String> REAL_KEYWORDS = new Set<String>{
		'HIPOTEC',
		'INMUEBL',
		'TERRENO',
		'SOLAR',
		'EDIFICIO',
		'VIVIENDA',
		'APARTAMENTO',
		'LOCAL COMERCIAL',
		'NAVE INDUSTRIAL',
		'HOTEL',
		'ZONA FRANCA'
	};

	private static final Set<String> MOVABLE_KEYWORDS = new Set<String>{
		'VEHICUL',
		'AUTOMOVIL',
		'CAMION',
		'MOTOCICL',
		'MAQUINARIA',
		'EQUIPO',
		'PRENDARIA',
		'MOBILIARIA',
		'AERONAVE',
		'INVENTARIO'
	};

	private static final Set<String> DEPOSIT_KEYWORDS = new Set<String>{
		'CERTIFICADO DE DEPOSITO',
		'CERTIFICADOS DEPOSITO',
		'CERTIFICADO FINANCIER',
		'DEPOSITO A PLAZO',
		'DEPOSITO FIJO',
		'DEPOSITO EN GARANTIA'
	};

	private static final Set<Id> SUPPORTED_RECORD_TYPE_IDS = loadSupportedRecordTypeIds();
	private static final Map<String, String> ASSET_DESCRIPTION_LABELS = loadAssetDescriptionLabels();

	public static void setDefaultOnInsert(List<ResidentialLoanApplication> records) {
		if (records == null || records.isEmpty()) {
			return;
		}

		for (ResidentialLoanApplication record : records) {
			if (
				record != null &&
				String.isBlank(record.FSC_Tipo_de_Garantia__c) &&
				(record.RecordTypeId == null || SUPPORTED_RECORD_TYPE_IDS.contains(record.RecordTypeId))
			) {
				record.FSC_Tipo_de_Garantia__c = SIN_GARANTIA;
			}
		}
	}

	public static void publishForRelatedRecords(List<SObject> records, String relationshipField) {
		publishForRelatedRecords(records, null, relationshipField);
	}

	public static void publishForRelatedRecords(
		List<SObject> newRecords,
		List<SObject> oldRecords,
		String relationshipField
	) {
		Set<Id> residentialLoanApplicationIds = new Set<Id>();
		collectRelatedIds(residentialLoanApplicationIds, newRecords, relationshipField);
		collectRelatedIds(residentialLoanApplicationIds, oldRecords, relationshipField);
		publish(residentialLoanApplicationIds);
	}

	public static void publish(Set<Id> residentialLoanApplicationIds) {
		if (residentialLoanApplicationIds == null || residentialLoanApplicationIds.isEmpty()) {
			return;
		}

		List<FSC_Actualizar_Tipo_Garantia__e> events = new List<FSC_Actualizar_Tipo_Garantia__e>();
		for (Id residentialLoanApplicationId : residentialLoanApplicationIds) {
			events.add(new FSC_Actualizar_Tipo_Garantia__e(
				FSC_ResidentialLoanApplicationId__c = String.valueOf(residentialLoanApplicationId)
			));
		}

		// El evento se procesa después del commit de la transacción original.
		List<Database.SaveResult> results = EventBus.publish(events);
		for (Database.SaveResult result : results) {
			if (!result.isSuccess()) {
				System.debug(LoggingLevel.ERROR, 'No fue posible programar la actualización del tipo de garantía: ' + result.getErrors());
			}
		}
	}

	public static void recalculate(Set<Id> residentialLoanApplicationIds) {
		if (residentialLoanApplicationIds == null || residentialLoanApplicationIds.isEmpty()) {
			return;
		}

		Map<Id, GuaranteeState> stateByRlaId = new Map<Id, GuaranteeState>();
		Map<Id, ResidentialLoanApplication> rlaById = new Map<Id, ResidentialLoanApplication>();
		for (ResidentialLoanApplication rla : [
			SELECT Id, FSC_Tipo_de_Garantia__c, RecordType.DeveloperName
			FROM ResidentialLoanApplication
			WHERE Id IN :residentialLoanApplicationIds
		]) {
			if (!SUPPORTED_RECORD_TYPES.contains(rla.RecordType.DeveloperName)) {
				continue;
			}

			rlaById.put(rla.Id, rla);
			stateByRlaId.put(rla.Id, new GuaranteeState());
		}

		if (stateByRlaId.isEmpty()) {
			return;
		}

		Set<Id> supportedRlaIds = stateByRlaId.keySet();
		for (LoanApplicant applicant : [
			SELECT LoanApplicationId, FSC_TipoSolicitante__c
			FROM LoanApplicant
			WHERE LoanApplicationId IN :supportedRlaIds
		]) {
			if (normalize(applicant.FSC_TipoSolicitante__c) == 'GARANTE') {
				stateByRlaId.get(applicant.LoanApplicationId).hasGuarantor = true;
			}
		}

		for (LoanApplicationAsset asset : [
			SELECT Name, LoanApplicationId, AssetClass, AssetType, AccountType,
				FSC_Descripcion_de_la_Garantia__c, FSC_Descripcion_Contrato__c,
				FSC_Tipo_Vehiculo_Contrato__c
			FROM LoanApplicationAsset
			WHERE LoanApplicationId IN :supportedRlaIds
		]) {
			GuaranteeState state = stateByRlaId.get(asset.LoanApplicationId);
			String descriptionCode = asset.FSC_Descripcion_de_la_Garantia__c;
			String descriptionLabel = ASSET_DESCRIPTION_LABELS.get(descriptionCode);
			classify(
				state,
				descriptionCode,
				combine(new List<Object>{
					asset.Name,
					asset.AssetClass,
					asset.AssetType,
					asset.AccountType,
					descriptionLabel,
					asset.FSC_Descripcion_Contrato__c,
					asset.FSC_Tipo_Vehiculo_Contrato__c
				})
			);
		}

		for (FSC_Garantia__c guarantee : [
			SELECT Name, FSC_Residential_Loan_Application__c, FSC_Clase_de_Garantia__c,
				FSC_Tipo_de_Garantia__c, FSC_Descripcion_de_la_Garantia__c,
				FSC_Tipo_de_Inmueble__c, FSC_Tipo_Vehiculo__c
			FROM FSC_Garantia__c
			WHERE FSC_Residential_Loan_Application__c IN :supportedRlaIds
		]) {
			// Con clase, el tipo del core (y el Name que lo repite) no participa: puede traer palabras de otra categoria.
			Boolean tieneClase = !String.isBlank(guarantee.FSC_Clase_de_Garantia__c);
			classify(
				stateByRlaId.get(guarantee.FSC_Residential_Loan_Application__c),
				null,
				combine(new List<Object>{
					tieneClase && guarantee.Name == guarantee.FSC_Tipo_de_Garantia__c ? null : guarantee.Name,
					guarantee.FSC_Clase_de_Garantia__c,
					tieneClase ? null : guarantee.FSC_Tipo_de_Garantia__c,
					guarantee.FSC_Descripcion_de_la_Garantia__c,
					guarantee.FSC_Tipo_de_Inmueble__c,
					guarantee.FSC_Tipo_Vehiculo__c
				})
			);
		}

		List<ResidentialLoanApplication> recordsToUpdate = new List<ResidentialLoanApplication>();
		for (Id rlaId : stateByRlaId.keySet()) {
			String expectedValue = resolveValue(stateByRlaId.get(rlaId));
			if (rlaById.get(rlaId).FSC_Tipo_de_Garantia__c != expectedValue) {
				recordsToUpdate.add(new ResidentialLoanApplication(
					Id = rlaId,
					FSC_Tipo_de_Garantia__c = expectedValue
				));
			}
		}

		if (!recordsToUpdate.isEmpty()) {
			List<Database.SaveResult> updateResults = Database.update(recordsToUpdate, false);
			for (Database.SaveResult result : updateResults) {
				if (!result.isSuccess()) {
					System.debug(LoggingLevel.ERROR, 'No fue posible actualizar el tipo de garantía: ' + result.getErrors());
				}
			}
		}
	}

	private static void collectRelatedIds(Set<Id> ids, List<SObject> records, String relationshipField) {
		if (records == null || String.isBlank(relationshipField)) {
			return;
		}

		for (SObject record : records) {
			if (record != null && record.get(relationshipField) != null) {
				ids.add((Id) record.get(relationshipField));
			}
		}
	}

	private static void classify(GuaranteeState state, String descriptionCode, String sourceText) {
		if (state == null) {
			return;
		}

		if (REAL_ASSET_CODES.contains(descriptionCode)) {
			state.hasRealGuarantee = true;
			return;
		}

		if (MOVABLE_ASSET_CODES.contains(descriptionCode)) {
			state.hasMovableGuarantee = true;
			return;
		}

		String normalizedText = normalize(sourceText);
		if (containsAny(normalizedText, REAL_KEYWORDS)) {
			state.hasRealGuarantee = true;
		}
		if (
			containsAny(normalizedText, MOVABLE_KEYWORDS) ||
			containsAny(normalizedText, DEPOSIT_KEYWORDS) ||
			containsToken(normalizedText, 'CD')
		) {
			state.hasMovableGuarantee = true;
		}
	}

	private static String resolveValue(GuaranteeState state) {
		// La prioridad respeta el orden funcional definido para una solicitud con varias garantías.
		if (state.hasGuarantor) {
			return GARANTIA_SOLIDARIA;
		}
		if (state.hasMovableGuarantee) {
			return GARANTIA_PRENDARIA;
		}
		if (state.hasRealGuarantee) {
			return GARANTIA_REAL;
		}
		return SIN_GARANTIA;
	}

	private static Boolean containsAny(String sourceText, Set<String> keywords) {
		if (String.isBlank(sourceText)) {
			return false;
		}

		for (String keyword : keywords) {
			if (sourceText.contains(keyword)) {
				return true;
			}
		}
		return false;
	}

	private static Boolean containsToken(String sourceText, String expectedToken) {
		if (String.isBlank(sourceText)) {
			return false;
		}

		for (String token : sourceText.split('[^A-Z0-9]+')) {
			if (token == expectedToken) {
				return true;
			}
		}
		return false;
	}

	private static String combine(List<Object> values) {
		List<String> textValues = new List<String>();
		for (Object value : values) {
			if (value != null && !String.isBlank(String.valueOf(value))) {
				textValues.add(String.valueOf(value));
			}
		}
		return String.join(textValues, ' ');
	}

	private static String normalize(String value) {
		if (String.isBlank(value)) {
			return '';
		}

		return value.trim().toUpperCase()
			.replace('Á', 'A')
			.replace('É', 'E')
			.replace('Í', 'I')
			.replace('Ó', 'O')
			.replace('Ú', 'U')
			.replace('Ü', 'U')
			.replace('Ñ', 'N');
	}

	private static Set<Id> loadSupportedRecordTypeIds() {
		Set<Id> recordTypeIds = new Set<Id>();
		Map<String, Schema.RecordTypeInfo> recordTypesByDeveloperName =
			Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName();

		for (String developerName : SUPPORTED_RECORD_TYPES) {
			if (recordTypesByDeveloperName.containsKey(developerName)) {
				recordTypeIds.add(recordTypesByDeveloperName.get(developerName).getRecordTypeId());
			}
		}
		return recordTypeIds;
	}

	private static Map<String, String> loadAssetDescriptionLabels() {
		Map<String, String> labelsByValue = new Map<String, String>();
		for (Schema.PicklistEntry entry : LoanApplicationAsset.FSC_Descripcion_de_la_Garantia__c.getDescribe().getPicklistValues()) {
			if (entry.isActive()) {
				labelsByValue.put(entry.getValue(), entry.getLabel());
			}
		}
		return labelsByValue;
	}

	private class GuaranteeState {
		private Boolean hasGuarantor = false;
		private Boolean hasMovableGuarantee = false;
		private Boolean hasRealGuarantee = false;
	}
}