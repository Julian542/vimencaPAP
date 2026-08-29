public without sharing class FSC_PlanillaDesembolsoSaver {
	private static final String TARGET_SUBSTATUS = 'Creación de crédito';
	private static final Set<String> ADMIN_PROFILES = new Set<String>{ 'System Administrator', 'Administrador del sistema' };

	public static void save(Id loanAppId, Map<String, Object> inputMap) {
		if (loanAppId == null || loanAppId.getSObjectType() != ResidentialLoanApplication.SObjectType) {
			throw new AuraHandledException('No se recibió una solicitud de crédito válida.');
		}

		ResidentialLoanApplication currentRla = [
			SELECT Id, FSC_UsuarioGestionPlanilla__c
			FROM ResidentialLoanApplication
			WHERE Id = :loanAppId
			LIMIT 1
		];

		if (!isAllowed(currentRla)) {
			throw new AuraHandledException(
				'Usted no tiene autorización para realizar esta acción, solo la persona asignada o el administrador tienen permiso.'
			);
		}

		Map<String, Schema.SObjectField> fields = ResidentialLoanApplication.SObjectType.getDescribe().fields.getMap();
		ResidentialLoanApplication rlaToUpdate = new ResidentialLoanApplication(Id = loanAppId);

		if (inputMap != null) {
			for (String key : inputMap.keySet()) {
				if (String.isBlank(key) || key == 'Id' || !fields.containsKey(key)) {
					continue;
				}
				if (!key.startsWith('FSC_') && key != 'Status') {
					continue;
				}

				Schema.DescribeFieldResult fieldDescribe = fields.get(key).getDescribe();
				if (fieldDescribe.isCalculated() || fieldDescribe.isAutoNumber()) {
					continue;
				}

				rlaToUpdate.put(key, convertValue(inputMap.get(key), fieldDescribe));
			}
		}

		rlaToUpdate.FSC_Subestado__c = TARGET_SUBSTATUS;
		update rlaToUpdate;
	}

	private static Boolean isAllowed(ResidentialLoanApplication rla) {
		User currentUser = [
			SELECT Profile.Name
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];

		return ADMIN_PROFILES.contains(currentUser.Profile.Name) || rla.FSC_UsuarioGestionPlanilla__c == UserInfo.getUserId();
	}

	private static Object convertValue(Object value, Schema.DescribeFieldResult fieldDescribe) {
		if (value == null || String.isBlank(String.valueOf(value))) {
			return null;
		}

		Schema.DisplayType fieldType = fieldDescribe.getType();
		String rawValue = String.valueOf(value).trim();

		if (fieldType == Schema.DisplayType.Boolean) {
			return value instanceof Boolean ? value : Boolean.valueOf(rawValue);
		}
		if (
			fieldType == Schema.DisplayType.Currency ||
			fieldType == Schema.DisplayType.Double ||
			fieldType == Schema.DisplayType.Percent
		) {
			return value instanceof Decimal ? value : Decimal.valueOf(rawValue.replace(',', ''));
		}
		if (fieldType == Schema.DisplayType.Integer) {
			return value instanceof Integer ? value : Integer.valueOf(rawValue);
		}
		if (fieldType == Schema.DisplayType.Date) {
			return value instanceof Date ? value : Date.valueOf(rawValue.contains('T') ? rawValue.substring(0, 10) : rawValue);
		}
		if (fieldType == Schema.DisplayType.DateTime) {
			return value instanceof Datetime ? value : Datetime.valueOf(rawValue.replace('T', ' ').replace('Z', ''));
		}

		return rawValue;
	}
}