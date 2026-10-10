public with sharing class FSC_LoanApplicantController {
	static final String NOMBRE_CONFIGURACION_FACILIDADES_OTRAS_INSTITUCIONES = 'FSC_LimiteFacilidadesOtrasInstituciones';

	@AuraEnabled
	public static void updateDebtorAccount(Id contextId, String applicantJson) {
		Savepoint savepoint = Database.setSavepoint();
		try {
			Id accountId = getAccountIdFromContext(contextId);
			if (accountId == null) {
				throw new AuraHandledException('No se pudo identificar el Account asociado a la solicitud.');
			}

			Map<String, Object> applicant = (Map<String, Object>) JSON.deserializeUntyped(applicantJson);
			if (applicant == null || normalizeText(stringValue(applicant.get('FSC_TipoSolicitante__c'))) != 'deudor') {
				throw new AuraHandledException('Solo se permite actualizar el Account desde el Deudor.');
			}

			Account account = [SELECT Id, IsPersonAccount, PersonContactId FROM Account WHERE Id = :accountId FOR UPDATE];
			// Actualiza todos los datos del Deudor en una sola transaccion.
			updateAccountData(account, applicant);
			updateEmploymentData(account, applicant);
			syncPhones(account.Id, collectionRows(applicant, 'ContactPointPhone'));
			syncAddresses(account.Id, collectionRows(applicant, 'ContactPointAddress'));
			syncEmails(account.Id, collectionRows(applicant, 'ContactPointEmail'));
		} catch (AuraHandledException e) {
			Database.rollback(savepoint);
			throw e;
		} catch (Exception e) {
			Database.rollback(savepoint);
			throw new AuraHandledException('No se pudo actualizar la informacion del Deudor: ' + e.getMessage());
		}
	}

	private static void updateAccountData(Account account, Map<String, Object> applicant) {
		String firstName = stringValue(applicant.get('FSC_Nombre__c'));
		String lastName = joinNonBlank(
			new List<String>{ stringValue(applicant.get('FSC_PrimerApellido__c')), stringValue(applicant.get('FSC_SegundoApellido__c')) }
		);

		Account accountUpdate = new Account(
			Id = account.Id,
			ACC_TipoIdentificacion__c = stringValue(applicant.get('FSC_TipoIdentificacion__c')),
			ACC_NumIdentificacion__c = stringValue(applicant.get('FSC_NumIdentificacion__c')),
			ACC_Nacionalidad__c = stringValue(applicant.get('FSC_Nacionalidad__c')),
			ACC_Estado_Civil__c = stringValue(applicant.get('FSC_EstadoCivil__c')),
			Tipo_de_vivienda__c = mapApplicantTipoVivienda(stringValue(applicant.get('FSC_TipoVivienda__c'))),
			Tiempo_en_Vivienda__c = stringValue(applicant.get('FSC_TiempoVivienda__c')),
			ACC_N_Dependientes__c = decimalValue(applicant.get('FSC_NumeroDependientes__c')),
			ACC_Categoria_Riesgo_Cliente__c = stringValue(applicant.get('FSC_ClasificacionSIB__c')),
			ACC_Ventas_Ingresos_Anuales__c = annualIncome(decimalValue(applicant.get('FSC_IngresosMensuales__c'))),
			Industry = stringValue(applicant.get('FSC_TipoNegocio__c'))
		);

		if (account.IsPersonAccount) {
			accountUpdate.FirstName = firstName;
			accountUpdate.LastName = lastName;
			accountUpdate.PersonBirthdate = dateValue(applicant.get('FSC_FechaNacimiento__c'));
		} else {
			accountUpdate.Name = joinNonBlank(new List<String>{ firstName, lastName });
		}

		update accountUpdate;
	}

	private static void updateEmploymentData(Account account, Map<String, Object> applicant) {
		// Reutiliza los empleos actual y anterior para conservar sus relaciones.
		List<FinServ__Employment__c> employments = [
			SELECT Id, EMP_Empleo__c, EMP_Principal__c
			FROM FinServ__Employment__c
			WHERE Cliente__c = :account.Id
			ORDER BY EMP_Principal__c DESC, CreatedDate DESC
		];

		FinServ__Employment__c currentEmployment;
		FinServ__Employment__c previousEmployment;
		for (FinServ__Employment__c employment : employments) {
			if (currentEmployment == null && (employment.EMP_Principal__c || employment.EMP_Empleo__c == 'Actual')) {
				currentEmployment = employment;
			}
			if (previousEmployment == null && employment.EMP_Empleo__c == 'Anterior') {
				previousEmployment = employment;
			}
		}

		if (currentEmployment == null) {
			currentEmployment = new FinServ__Employment__c(Cliente__c = account.Id, FinServ__Contact__c = account.PersonContactId);
		}
		currentEmployment.EMP_Empleo__c = 'Actual';
		currentEmployment.EMP_Principal__c = true;
		currentEmployment.EMP_Empresa__c = stringValue(applicant.get('FSC_LugarFondeLabora__c'));
		currentEmployment.EMP_Tipo_de_empleado__c = mapEmployeeType(stringValue(applicant.get('FSC_FuenteIngreso__c')));
		currentEmployment.FinServ__AnnualIncome__c = annualIncome(decimalValue(applicant.get('FSC_IngresosMensuales__c')));
		// Se comenta hasta que se haga el merge de campos de la Account y el LoanApplicant BV-1023
		// currentEmployment.FinServ__Occupation__c = stringValue(applicant.get('FSC_Ocupacion__c'));
		currentEmployment.FinServ__StartDate__c = dateValue(applicant.get('FSC_TiempoLaborando__c'));
		FSC_LoanApplicantEmploymentWriter.save(account.Id, currentEmployment);

		String previousCompany = stringValue(applicant.get('FSC_EmpresaAnteriorLaboro__c'));
		if (previousEmployment != null || String.isNotBlank(previousCompany)) {
			if (previousEmployment == null) {
				previousEmployment = new FinServ__Employment__c(Cliente__c = account.Id, FinServ__Contact__c = account.PersonContactId);
			}
			previousEmployment.EMP_Empleo__c = 'Anterior';
			previousEmployment.EMP_Principal__c = false;
			previousEmployment.EMP_Empresa__c = previousCompany;
			FSC_LoanApplicantEmploymentWriter.save(account.Id, previousEmployment);
		}
	}

	private static void syncPhones(Id accountId, List<Map<String, Object>> rows) {
		List<ContactPointPhone> existingRows = [
			SELECT Id, FSC_TipoContacto__c, TelephoneNumber
			FROM ContactPointPhone
			WHERE ParentId = :accountId
			ORDER BY CreatedDate
		];
		List<ContactPointPhone> rowsToSave = new List<ContactPointPhone>();
		for (Integer index = 0; index < rows.size(); index++) {
			ContactPointPhone phone = index < existingRows.size() ? existingRows[index] : new ContactPointPhone(ParentId = accountId);
			phone.FSC_TipoContacto__c = stringValue(rows[index].get('FSC_TipoContacto__c'));
			phone.TelephoneNumber = stringValue(rows[index].get('TelephoneNumber'));
			rowsToSave.add(phone);
		}
		if (!rowsToSave.isEmpty()) {
			upsert rowsToSave;
		}
		List<ContactPointPhone> rowsToDelete = new List<ContactPointPhone>();
		for (Integer index = rows.size(); index < existingRows.size(); index++) {
			rowsToDelete.add(existingRows[index]);
		}
		if (!rowsToDelete.isEmpty()) {
			delete rowsToDelete;
		}
	}

	private static void syncAddresses(Id accountId, List<Map<String, Object>> rows) {
		List<ContactPointAddress> existingRows = [
			SELECT Id, Name, Street, City, State, PostalCode, Country
			FROM ContactPointAddress
			WHERE ParentId = :accountId
			ORDER BY CreatedDate
		];
		List<ContactPointAddress> rowsToSave = new List<ContactPointAddress>();
		for (Integer index = 0; index < rows.size(); index++) {
			ContactPointAddress address = index < existingRows.size() ? existingRows[index] : new ContactPointAddress(ParentId = accountId);
			address.Name = stringValue(rows[index].get('Name'));
			address.Street = stringValue(rows[index].get('Street'));
			address.City = stringValue(rows[index].get('City'));
			address.State = stringValue(rows[index].get('State'));
			address.PostalCode = stringValue(rows[index].get('PostalCode'));
			address.Country = stringValue(rows[index].get('Country'));
			rowsToSave.add(address);
		}
		if (!rowsToSave.isEmpty()) {
			upsert rowsToSave;
		}
		List<ContactPointAddress> rowsToDelete = new List<ContactPointAddress>();
		for (Integer index = rows.size(); index < existingRows.size(); index++) {
			rowsToDelete.add(existingRows[index]);
		}
		if (!rowsToDelete.isEmpty()) {
			delete rowsToDelete;
		}
	}

	private static void syncEmails(Id accountId, List<Map<String, Object>> rows) {
		List<ContactPointEmail> existingRows = [
			SELECT Id, EmailAddress
			FROM ContactPointEmail
			WHERE ParentId = :accountId
			ORDER BY CreatedDate
		];
		List<ContactPointEmail> rowsToSave = new List<ContactPointEmail>();
		for (Integer index = 0; index < rows.size(); index++) {
			ContactPointEmail email = index < existingRows.size() ? existingRows[index] : new ContactPointEmail(ParentId = accountId);
			email.EmailAddress = stringValue(rows[index].get('EmailAddress'));
			rowsToSave.add(email);
		}
		if (!rowsToSave.isEmpty()) {
			upsert rowsToSave;
		}
		List<ContactPointEmail> rowsToDelete = new List<ContactPointEmail>();
		for (Integer index = rows.size(); index < existingRows.size(); index++) {
			rowsToDelete.add(existingRows[index]);
		}
		if (!rowsToDelete.isEmpty()) {
			delete rowsToDelete;
		}
	}

	private static List<Map<String, Object>> collectionRows(Map<String, Object> applicant, String fieldName) {
		List<Map<String, Object>> rows = new List<Map<String, Object>>();
		Object value = applicant.get(fieldName);
		if (!(value instanceof List<Object>)) {
			return rows;
		}

		for (Object row : (List<Object>) value) {
			if (row instanceof Map<String, Object>) {
				rows.add((Map<String, Object>) row);
			}
		}
		return rows;
	}

	private static String stringValue(Object value) {
		return value == null || String.isBlank(String.valueOf(value)) ? null : String.valueOf(value).trim();
	}

	private static Decimal decimalValue(Object value) {
		String text = stringValue(value);
		if (text == null) {
			return null;
		}
		try {
			return Decimal.valueOf(text);
		} catch (Exception e) {
			return null;
		}
	}

	private static Date dateValue(Object value) {
		String text = stringValue(value);
		if (text == null) {
			return null;
		}
		try {
			return Date.valueOf(text);
		} catch (Exception e) {
			return null;
		}
	}

	private static Decimal annualIncome(Decimal monthlyIncomeValue) {
		return monthlyIncomeValue == null ? null : monthlyIncomeValue * 12;
	}

	private static String mapEmployeeType(String source) {
		Map<String, String> sourceToEmployment = new Map<String, String>{
			'independiente' => '0',
			'empleado privado' => '1',
			'empleado publico' => '2'
		};
		return sourceToEmployment.get(normalizeText(source));
	}

	private static String mapApplicantTipoVivienda(String applicantTipoVivienda) {
		Map<String, String> applicantToAccount = new Map<String, String>{ '2' => '1', '4' => '2', '1' => '3' };
		return applicantToAccount.containsKey(applicantTipoVivienda) ? applicantToAccount.get(applicantTipoVivienda) : applicantTipoVivienda;
	}

	private static String normalizeText(String value) {
		return String.isBlank(value)
			? ''
			: value.toLowerCase().replace('á', 'a').replace('é', 'e').replace('í', 'i').replace('ó', 'o').replace('ú', 'u').trim();
	}

	private static String joinNonBlank(List<String> values) {
		List<String> parts = new List<String>();
		for (String value : values) {
			if (String.isNotBlank(value)) {
				parts.add(value.trim());
			}
		}
		return parts.isEmpty() ? null : String.join(parts, ' ');
	}

	@AuraEnabled(cacheable=true)
	public static Integer obtenerLimiteFacilidadesOtrasInstituciones() {
		Decimal limiteConfigurado = FSC_LimiteSolicitudCredito__mdt.getInstance(NOMBRE_CONFIGURACION_FACILIDADES_OTRAS_INSTITUCIONES)?.FSC_Limite__c;
		Integer limiteNormalizado = limiteConfigurado?.intValue();
		return limiteNormalizado;
	}

	@AuraEnabled
	public static Map<String, Object> getLoanApplicant(String tipoId, String numId) {
		Map<String, Object> accountApplicant = getLoanApplicantFromAccount(tipoId, numId);
		if (accountApplicant != null) {
			mergeMissingLaborData(accountApplicant, getExistingLoanApplicant(tipoId, numId));
			return accountApplicant;
		}

		return getExistingLoanApplicant(tipoId, numId);
	}

	@AuraEnabled
	public static Map<String, Object> getAccountLoanApplicant(Id contextId) {
		Id accountId = getAccountIdFromContext(contextId);
		if (accountId == null) {
			return null;
		}

		List<Account> accounts = [
			SELECT
				Name,
				FirstName,
				LastName,
				PersonBirthdate,
				PersonEmail,
				PersonMobilePhone,
				PersonHomePhone,
				Phone,
				BillingStreet,
				BillingCity,
				BillingState,
				BillingPostalCode,
				BillingCountry,
				PersonMailingStreet,
				PersonMailingCity,
				PersonMailingState,
				PersonMailingPostalCode,
				PersonMailingCountry,
				ACC_TipoIdentificacion__c,
				ACC_NumIdentificacion__c,
				ACC_Nacionalidad__c,
				ACC_Estado_Civil__c,
				Tipo_de_vivienda__c,
				Tiempo_en_Vivienda__c,
				ACC_N_Dependientes__c,
				ACC_Categoria_Riesgo_Cliente__c,
				ACC_Ventas_Ingresos_Anuales__c,
				ACC_Correo_Electronico_Cliente__c,
				ACC_Tipo_Actividad__c,
				Industry
			FROM Account
			WHERE Id = :accountId
			LIMIT 1
		];
		return accounts.isEmpty() ? null : accountToApplicantMap(accounts[0]);
	}

	private static Map<String, Object> getLoanApplicantFromAccount(String tipoId, String numId) {
		List<Account> accounts = [
			SELECT
				Name,
				FirstName,
				LastName,
				PersonBirthdate,
				PersonEmail,
				PersonMobilePhone,
				PersonHomePhone,
				Phone,
				BillingStreet,
				BillingCity,
				BillingState,
				BillingPostalCode,
				BillingCountry,
				PersonMailingStreet,
				PersonMailingCity,
				PersonMailingState,
				PersonMailingPostalCode,
				PersonMailingCountry,
				ACC_TipoIdentificacion__c,
				ACC_NumIdentificacion__c,
				ACC_Nacionalidad__c,
				ACC_Estado_Civil__c,
				Tipo_de_vivienda__c,
				Tiempo_en_Vivienda__c,
				ACC_N_Dependientes__c,
				ACC_Categoria_Riesgo_Cliente__c,
				ACC_Ventas_Ingresos_Anuales__c,
				ACC_Correo_Electronico_Cliente__c,
				ACC_Tipo_Actividad__c,
				Industry
			FROM Account
			WHERE ACC_TipoIdentificacion__c = :tipoId AND ACC_NumIdentificacion__c = :numId
			ORDER BY LastModifiedDate DESC
			LIMIT 1
		];

		if (accounts.isEmpty()) {
			return null;
		}

		return accountToApplicantMap(accounts[0]);
	}

	private static Map<String, Object> accountToApplicantMap(Account account) {
		List<String> lastNames = splitLastNames(account.LastName);
		Map<String, Object> applicant = new Map<String, Object>{
			'Name' => account.Name,
			'FSC_TipoSolicitante__c' => 'Deudor',
			'FSC_TipoIdentificacion__c' => account.ACC_TipoIdentificacion__c,
			'FSC_NumIdentificacion__c' => account.ACC_NumIdentificacion__c,
			'FSC_Nombre__c' => firstNonBlank(new List<String>{ account.FirstName, account.Name }),
			'FSC_PrimerApellido__c' => lastNames[0],
			'FSC_SegundoApellido__c' => lastNames[1],
			'FSC_FechaNacimiento__c' => account.PersonBirthdate,
			'FSC_Nacionalidad__c' => account.ACC_Nacionalidad__c,
			'FSC_EstadoCivil__c' => account.ACC_Estado_Civil__c,
			'FSC_TipoVivienda__c' => mapTipoVivienda(account.Tipo_de_vivienda__c),
			'FSC_TiempoVivienda__c' => parseDate(account.Tiempo_en_Vivienda__c),
			'FSC_IngresosMensuales__c' => monthlyIncome(account.ACC_Ventas_Ingresos_Anuales__c),
			'FSC_NumeroDependientes__c' => account.ACC_N_Dependientes__c,
			'FSC_Ocupacion__c' => account.ACC_Tipo_Actividad__c,
			'FSC_TipoNegocio__c' => account.Industry,
			'FSC_ClasificacionSIB__c' => account.ACC_Categoria_Riesgo_Cliente__c,
			'Contact_Point_Phones__r' => phoneRowsToMaps(accountPhones(account)),
			'Contact_Point_Addresses__r' => addressRowsToMaps(accountAddresses(account)),
			'Contact_Point_Emails__r' => emailRowsToMaps(accountEmails(account))
		};

		addEmploymentData(applicant, account.Id);
		return applicant;
	}

	private static void addEmploymentData(Map<String, Object> applicant, Id accountId) {
		List<FinServ__Employment__c> employments = [
			SELECT
				EMP_Empleo__c,
				EMP_Empresa__c,
				EMP_Principal__c,
				EMP_Tipo_de_empleado__c,
				FinServ__AnnualIncome__c,
				FinServ__Occupation__c,
				FinServ__StartDate__c
			FROM FinServ__Employment__c
			WHERE Cliente__c = :accountId
			ORDER BY EMP_Principal__c DESC, CreatedDate DESC
		];

		FinServ__Employment__c currentEmployment;
		FinServ__Employment__c previousEmployment;
		for (FinServ__Employment__c employment : employments) {
			if (currentEmployment == null && (employment.EMP_Principal__c || employment.EMP_Empleo__c == 'Actual')) {
				currentEmployment = employment;
			}
			if (previousEmployment == null && employment.EMP_Empleo__c == 'Anterior') {
				previousEmployment = employment;
			}
		}

		if (currentEmployment == null && !employments.isEmpty()) {
			currentEmployment = employments[0];
		}
		if (currentEmployment == null) {
			return;
		}

		putWhenNotNull(applicant, 'FSC_Ocupacion__c', currentEmployment.FinServ__Occupation__c);
		putWhenNotNull(applicant, 'FSC_LugarFondeLabora__c', currentEmployment.EMP_Empresa__c);
		putWhenNotNull(applicant, 'FSC_TiempoLaborando__c', currentEmployment.FinServ__StartDate__c);
		putWhenNotNull(applicant, 'FSC_FuenteIngreso__c', mapFuenteIngreso(currentEmployment.EMP_Tipo_de_empleado__c));
		putWhenNotNull(applicant, 'FSC_IngresosMensuales__c', monthlyIncome(currentEmployment.FinServ__AnnualIncome__c));

		if (previousEmployment != null) {
			putWhenNotNull(applicant, 'FSC_EmpresaAnteriorLaboro__c', previousEmployment.EMP_Empresa__c);
		}
	}

	private static void mergeMissingLaborData(Map<String, Object> accountApplicant, Map<String, Object> existingApplicant) {
		if (existingApplicant == null) {
			return;
		}

		List<String> laborFields = new List<String>{
			'FSC_Ocupacion__c',
			'FSC_EmpresaAnteriorLaboro__c',
			'FSC_LugarFondeLabora__c',
			'FSC_TiempoLaborando__c',
			'FSC_FuenteIngreso__c',
			'FSC_IngresosMensuales__c',
			'FSC_OtrosIngresos__c',
			'FSC_DescripcionOtrosIngresos__c',
			'FSC_TotalIngresos__c',
			'FSC_MontoPrestacionesLaborales__c',
			'FSC_TipoNegocio__c'
		};

		for (String fieldName : laborFields) {
			if (isBlankValue(accountApplicant.get(fieldName)) && !isBlankValue(existingApplicant.get(fieldName))) {
				accountApplicant.put(fieldName, existingApplicant.get(fieldName));
			}
		}
	}

	private static Boolean isBlankValue(Object value) {
		return value == null || (value instanceof String && String.isBlank((String) value));
	}

	private static void putWhenNotNull(Map<String, Object> target, String fieldName, Object value) {
		if (value != null) {
			target.put(fieldName, value);
		}
	}

	private static String mapFuenteIngreso(String employeeType) {
		Map<String, String> sourceToApplicant = new Map<String, String>{
			'0' => 'Independiente',
			'1' => 'Empleado Privado',
			'2' => 'Empleado Publico'
		};
		return sourceToApplicant.get(employeeType);
	}

	private static Id getAccountIdFromContext(Id contextId) {
		if (contextId == null) {
			return null;
		}

		Schema.SObjectType contextType = contextId.getSObjectType();
		if (contextType == Account.SObjectType) {
			return contextId;
		}

		if (contextType == ResidentialLoanApplication.SObjectType) {
			List<ResidentialLoanApplication> rlas = [
				SELECT AccountId
				FROM ResidentialLoanApplication
				WHERE Id = :contextId
				LIMIT 1
			];
			return rlas.isEmpty() ? null : rlas[0].AccountId;
		}

		return null;
	}

	private static Map<String, Object> getExistingLoanApplicant(String tipoId, String numId) {
		List<LoanApplicant> applicants = [
			SELECT
				Name,
				FSC_TipoIdentificacion__c,
				FSC_NumIdentificacion__c,
				FSC_Nombre__c,
				FSC_PrimerApellido__c,
				FSC_SegundoApellido__c,
				FSC_FechaNacimiento__c,
				FSC_Nacionalidad__c,
				FSC_EstadoCivil__c,
				FSC_TipoVivienda__c,
				FSC_TiempoVivienda__c,
				FSC_Ocupacion__c,
				FSC_EmpresaAnteriorLaboro__c,
				FSC_LugarFondeLabora__c,
				FSC_TiempoLaborando__c,
				FSC_FuenteIngreso__c,
				FSC_IngresosMensuales__c,
				FSC_OtrosIngresos__c,
				FSC_DescripcionOtrosIngresos__c,
				FSC_TotalIngresos__c,
				FSC_MontoPrestacionesLaborales__c,
				FSC_NumeroDependientes__c,
				FSC_TipoNegocio__c,
				FSC_ClasificacionSIB__c,
				(SELECT FSC_TipoContacto__c, TelephoneNumber FROM Contact_Point_Phones__r ORDER BY CreatedDate),
				(SELECT Name, Street, City, State, PostalCode, Country FROM Contact_Point_Addresses__r ORDER BY CreatedDate),
				(SELECT EmailAddress FROM Contact_Point_Emails__r ORDER BY CreatedDate),
				(
					SELECT
						Name,
						FSC_FirstName__c,
						FSC_LastName__c,
						FSC_TipoIdentificacion__c,
						FSC_Identificacion__c,
						FSC_Direccion__c,
						FSC_Email__c,
						FSC_Telefono__c,
						FSC_Parentesco__c,
						FSC_LugarTrabajo__c
					FROM Referencias__r
					ORDER BY CreatedDate
				)
			FROM LoanApplicant
			WHERE FSC_TipoIdentificacion__c = :tipoId AND FSC_NumIdentificacion__c = :numId
			ORDER BY CreatedDate DESC
			LIMIT 1
		];
		if (applicants.isEmpty()) {
			return null;
		}

		LoanApplicant applicant = applicants[0];
		Map<String, Object> result = rowToMap(
			applicant,
			new List<String>{
				'Name',
				'FSC_TipoIdentificacion__c',
				'FSC_NumIdentificacion__c',
				'FSC_Nombre__c',
				'FSC_PrimerApellido__c',
				'FSC_SegundoApellido__c',
				'FSC_FechaNacimiento__c',
				'FSC_Nacionalidad__c',
				'FSC_EstadoCivil__c',
				'FSC_TipoVivienda__c',
				'FSC_TiempoVivienda__c',
				'FSC_Ocupacion__c',
				'FSC_EmpresaAnteriorLaboro__c',
				'FSC_LugarFondeLabora__c',
				'FSC_TiempoLaborando__c',
				'FSC_FuenteIngreso__c',
				'FSC_IngresosMensuales__c',
				'FSC_OtrosIngresos__c',
				'FSC_DescripcionOtrosIngresos__c',
				'FSC_TotalIngresos__c',
				'FSC_MontoPrestacionesLaborales__c',
				'FSC_NumeroDependientes__c',
				'FSC_TipoNegocio__c',
				'FSC_ClasificacionSIB__c'
			}
		);
		result.put('Contact_Point_Phones__r', sobjectRowsToMaps(applicant.getSObjects('Contact_Point_Phones__r'), phoneFields()));
		result.put('Contact_Point_Addresses__r', sobjectRowsToMaps(applicant.getSObjects('Contact_Point_Addresses__r'), addressFields()));
		result.put('Contact_Point_Emails__r', sobjectRowsToMaps(applicant.getSObjects('Contact_Point_Emails__r'), emailFields()));
		result.put(
			'Referencias__r',
			sobjectRowsToMaps(
				applicant.getSObjects('Referencias__r'),
				new List<String>{
					'Name',
					'FSC_FirstName__c',
					'FSC_LastName__c',
					'FSC_TipoIdentificacion__c',
					'FSC_Identificacion__c',
					'FSC_Direccion__c',
					'FSC_Email__c',
					'FSC_Telefono__c',
					'FSC_Parentesco__c',
					'FSC_LugarTrabajo__c'
				}
			)
		);
		return result;
	}

	private static List<ContactPointPhone> accountPhones(Account account) {
		List<ContactPointPhone> phones = [
			SELECT FSC_TipoContacto__c, TelephoneNumber
			FROM ContactPointPhone
			WHERE ParentId = :account.Id
			ORDER BY CreatedDate
		];

		if (!phones.isEmpty()) {
			return phones;
		}

		List<ContactPointPhone> fallbackPhones = new List<ContactPointPhone>();
		addPhone(fallbackPhones, account.PersonMobilePhone);
		addPhone(fallbackPhones, account.Phone);
		addPhone(fallbackPhones, account.PersonHomePhone);
		return fallbackPhones;
	}

	private static List<ContactPointAddress> accountAddresses(Account account) {
		List<ContactPointAddress> addresses = [
			SELECT Name, Street, City, State, PostalCode, Country
			FROM ContactPointAddress
			WHERE ParentId = :account.Id
			ORDER BY CreatedDate
		];

		if (!addresses.isEmpty()) {
			return addresses;
		}

		List<ContactPointAddress> fallbackAddresses = new List<ContactPointAddress>();
		ContactPointAddress mailingAddress = addressFromFields(
			'Dirección principal',
			account.PersonMailingStreet,
			account.PersonMailingCity,
			account.PersonMailingState,
			account.PersonMailingPostalCode,
			account.PersonMailingCountry
		);
		if (mailingAddress != null) {
			fallbackAddresses.add(mailingAddress);
			return fallbackAddresses;
		}

		ContactPointAddress billingAddress = addressFromFields(
			'Dirección principal',
			account.BillingStreet,
			account.BillingCity,
			account.BillingState,
			account.BillingPostalCode,
			account.BillingCountry
		);
		if (billingAddress != null) {
			fallbackAddresses.add(billingAddress);
		}

		return fallbackAddresses;
	}

	private static List<ContactPointEmail> accountEmails(Account account) {
		List<ContactPointEmail> emails = [
			SELECT EmailAddress
			FROM ContactPointEmail
			WHERE ParentId = :account.Id
			ORDER BY CreatedDate
		];

		if (!emails.isEmpty()) {
			return emails;
		}

		String emailAddress = firstNonBlank(new List<String>{ account.PersonEmail, account.ACC_Correo_Electronico_Cliente__c });
		return String.isBlank(emailAddress)
			? new List<ContactPointEmail>()
			: new List<ContactPointEmail>{ new ContactPointEmail(EmailAddress = emailAddress) };
	}

	private static List<Map<String, Object>> phoneRowsToMaps(List<ContactPointPhone> rows) {
		List<Map<String, Object>> out = new List<Map<String, Object>>();
		for (ContactPointPhone row : rows) {
			out.add(rowToMap(row, phoneFields()));
		}
		return out;
	}

	private static List<Map<String, Object>> addressRowsToMaps(List<ContactPointAddress> rows) {
		List<Map<String, Object>> out = new List<Map<String, Object>>();
		for (ContactPointAddress row : rows) {
			out.add(rowToMap(row, addressFields()));
		}
		return out;
	}

	private static List<Map<String, Object>> emailRowsToMaps(List<ContactPointEmail> rows) {
		List<Map<String, Object>> out = new List<Map<String, Object>>();
		for (ContactPointEmail row : rows) {
			out.add(rowToMap(row, emailFields()));
		}
		return out;
	}

	private static List<Map<String, Object>> sobjectRowsToMaps(List<SObject> rows, List<String> fields) {
		List<Map<String, Object>> out = new List<Map<String, Object>>();
		if (rows == null) {
			return out;
		}

		for (SObject row : rows) {
			out.add(rowToMap(row, fields));
		}
		return out;
	}

	private static Map<String, Object> rowToMap(SObject row, List<String> fields) {
		Map<String, Object> out = new Map<String, Object>();
		for (String fieldName : fields) {
			out.put(fieldName, row.get(fieldName));
		}
		return out;
	}

	private static List<String> phoneFields() {
		return new List<String>{ 'FSC_TipoContacto__c', 'TelephoneNumber' };
	}

	private static List<String> addressFields() {
		return new List<String>{ 'Name', 'Street', 'City', 'State', 'PostalCode', 'Country' };
	}

	private static List<String> emailFields() {
		return new List<String>{ 'EmailAddress' };
	}

	private static void addPhone(List<ContactPointPhone> phones, String phoneNumber) {
		if (String.isBlank(phoneNumber) || hasPhone(phones, phoneNumber)) {
			return;
		}

		phones.add(new ContactPointPhone(TelephoneNumber = phoneNumber));
	}

	private static Boolean hasPhone(List<ContactPointPhone> phones, String phoneNumber) {
		for (ContactPointPhone phone : phones) {
			if (phone.TelephoneNumber == phoneNumber) {
				return true;
			}
		}
		return false;
	}

	private static ContactPointAddress addressFromFields(String name, String street, String city, String state, String postalCode, String country) {
		if (String.isBlank(street) && String.isBlank(city) && String.isBlank(state) && String.isBlank(postalCode) && String.isBlank(country)) {
			return null;
		}

		return new ContactPointAddress(Name = name, Street = street, City = city, State = state, PostalCode = postalCode, Country = country);
	}

	private static Decimal monthlyIncome(Decimal annualIncome) {
		return annualIncome == null ? null : annualIncome / 12;
	}

	private static Date parseDate(String value) {
		if (String.isBlank(value)) {
			return null;
		}

		try {
			return Date.valueOf(value);
		} catch (Exception e) {
			return null;
		}
	}

	private static String mapTipoVivienda(String accountTipoVivienda) {
		Map<String, String> accountToApplicant = new Map<String, String>{ '1' => '2', '2' => '4', '3' => '1' };
		return accountToApplicant.containsKey(accountTipoVivienda) ? accountToApplicant.get(accountTipoVivienda) : accountTipoVivienda;
	}

	private static String firstNonBlank(List<String> values) {
		for (String value : values) {
			if (String.isNotBlank(value)) {
				return value;
			}
		}
		return null;
	}

	private static List<String> splitLastNames(String lastNames) {
		String value = String.isBlank(lastNames) ? '' : lastNames.trim();
		Integer separatorIndex = value.indexOf(' ');
		if (separatorIndex < 0) {
			return new List<String>{ value, null };
		}
		return new List<String>{ value.substring(0, separatorIndex), value.substring(separatorIndex + 1).trim() };
	}
}