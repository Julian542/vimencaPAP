public with sharing class FSC_CreditPolicyService {
	public static List<FSC_CreditPolicyService.Result> evaluate(List<FSC_CreditPolicyService.Request> requests) {
		if (requests == null)
			return new List<FSC_CreditPolicyService.Result>();
		Set<Id> ids = new Set<Id>();
		for (FSC_CreditPolicyService.Request request : requests) {
			if (request != null && request.accountId != null && request.loanType == 'hipotecario')
				ids.add(request.accountId);
		}
		Map<Id, Account> accounts = ids.isEmpty() ? new Map<Id, Account>() : FSC_CreditPolicyService.accounts(ids);
		for (FSC_CreditPolicyService.Request request : requests) {
			Account account = request == null ? null : accounts.get(request.accountId);
			if (account != null) {
				request.nationality = account.ACC_Nacionalidad__c;
				request.dualNationality = account.ACC_Posee_Otra_Nacionalidad__c;
			} else if (request != null && request.accountId != null && request.loanType == 'hipotecario') {
				request.nationality = null;
			}
		}
		List<FSC_CreditPolicyService.Result> results = FSC_CreditPolicyService.evaluate(
			requests,
			FSC_CreditPolicyService.rules(),
			FSC_CreditPolicyService.rates(),
			FSC_CreditPolicyService.realEstateClasses(),
			FSC_CreditPolicyService.nationalities(),
			Date.today()
		);
		Decimal consumptionMax = FSC_PlazoCredito__mdt.getInstance('Consumo')?.FSC_PlazoMaximo__c;
		for (Integer index = 0; index < results.size(); index++) {
			if (
				!results[index].applicable &&
				requests[index]?.loanType == 'consumo' &&
				(consumptionMax == null ||
				requests[index].months > consumptionMax)
			) {
				results[index].valid = false;
				results[index].message = 'El consumo sin garantía inmobiliaria supera el plazo máximo general.';
			}
		}
		return results;
	}
	public class Request {
		public Id accountId;
		public String loanType;
		public String currencyCode;
		public String nationality;
		public Boolean dualNationality;
		public Decimal amount;
		public Decimal months;
		public List<Guarantee> guarantees = new List<Guarantee>();
	}
	public class Guarantee {
		public String purpose;
		public String classValue;
		public String propertyType;
		public Decimal propertyValue;
		public Decimal salePrice;
		public Decimal improvements;
		public Decimal priorBalance;
	}
	public class Result {
		@AuraEnabled
		public Boolean applicable { get; set; }
		@AuraEnabled
		public Boolean valid { get; set; }
		@AuraEnabled
		public String message { get; set; }
		@AuraEnabled
		public String amountMessage { get; set; }
		@AuraEnabled
		public String termMessage { get; set; }
		@AuraEnabled
		public Decimal minAmount { get; set; }
		@AuraEnabled
		public Decimal maxAmount { get; set; }
		@AuraEnabled
		public Integer minMonths { get; set; }
		@AuraEnabled
		public Integer maxMonths { get; set; }
		@AuraEnabled
		public String currencyCode { get; set; }
		@AuraEnabled
		public String profile { get; set; }
	}
	public static List<Result> evaluate(
		List<Request> requests,
		List<FSC_ReglaCredito__mdt> rules,
		List<FSC_TasaCambioCredito__mdt> rates,
		Set<String> realEstateClasses,
		Set<String> nationalities,
		Date effectiveDate
	) {
		List<Result> results = new List<Result>();
		if (requests == null)
			return results;
		for (Request request : requests) {
			results.add(evaluateOne(request, rules, rates, realEstateClasses, nationalities, effectiveDate));
		}
		return results;
	}
	private static Result evaluateOne(
		Request request,
		List<FSC_ReglaCredito__mdt> rules,
		List<FSC_TasaCambioCredito__mdt> rates,
		Set<String> realEstateClasses,
		Set<String> nationalities,
		Date effectiveDate
	) {
		Result result = new Result();
		result.valid = true;
		result.applicable = false;
		if (request == null)
			return fail(result, 'No se recibieron los datos del crédito.');
		if (request.loanType != 'hipotecario' && request.loanType != 'consumo')
			return result;
		List<Guarantee> guarantees = new List<Guarantee>();
		if (request.guarantees == null)
			request.guarantees = new List<Guarantee>();
		Set<String> purposesConfigured = new Set<String>();
		for (FSC_ReglaCredito__mdt rule : rules)
			purposesConfigured.add(rule.FSC_Proposito__c);
		for (Guarantee guarantee : request.guarantees) {
			if (
				realEstateClasses.contains(key(guarantee.classValue)) ||
				purposesConfigured.contains(guarantee.purpose) ||
				(String.isNotBlank(guarantee.purpose) && guarantee.propertyValue != null)
			)
				guarantees.add(guarantee);
		}
		result.applicable = request.loanType == 'hipotecario' || !guarantees.isEmpty();
		if (!result.applicable)
			return result;
		result.currencyCode = request.currencyCode;
		if (request.currencyCode != 'DOP' && request.currencyCode != 'USD') {
			return fail(result, 'Seleccione la moneda del crédito.');
		}
		result.profile = 'LOCAL';
		if (request.loanType == 'hipotecario') {
			if (String.isBlank(request.nationality) || !nationalities.contains(request.nationality)) {
				return fail(result, 'Complete una nacionalidad válida del deudor principal.');
			}
			if (request.dualNationality == true) {
				return fail(result, 'La doble nacionalidad requiere revisión de la política antes de continuar.');
			}
			result.profile = key(request.nationality) == 'REPUBLICADOMINICANA' ? 'LOCAL' : 'EXTRANJERO';
		}
		if (guarantees.isEmpty())
			return fail(result, 'Agregue una garantía inmobiliaria para determinar los límites.');
		String product = request.loanType == 'hipotecario' ? 'HIPOTECARIO' : 'CONSUMO_GARANTIA_INMOBILIARIA';
		Set<String> purposes = new Set<String>();
		for (Guarantee guarantee : guarantees) {
			FSC_ReglaCredito__mdt rule;
			Integer matches = 0;
			for (FSC_ReglaCredito__mdt candidate : rules) {
				if (
					candidate.FSC_Activa__c &&
					candidate.FSC_Producto__c == product &&
					candidate.FSC_Perfil__c == result.profile &&
					candidate.FSC_Proposito__c == guarantee.purpose &&
					(candidate.FSC_Moneda__c == request.currencyCode ||
					candidate.FSC_Moneda__c == 'TODAS')
				) {
					rule = candidate;
					matches++;
				}
			}
			if (matches != 1)
				return fail(result, 'El destino no tiene una regla única para este producto, perfil y moneda. Seleccione un destino vigente.');
			if (!validRule(rule))
				return fail(result, 'La configuración de límites es inválida. Contacte al administrador.');
			purposes.add(rule.FSC_Destino__c);
			Decimal minimum = convertMinimum(rule, request.currencyCode, rates, effectiveDate);
			if (minimum == null)
				return fail(result, 'No existe una tasa de cambio única y vigente. Actualice la configuración de tasas.');
			Decimal capacity = capacity(guarantee, rule, result);
			if (!result.valid)
				return result;
			result.minAmount = result.minAmount == null ? minimum : Math.max(result.minAmount, minimum);
			result.maxAmount = result.maxAmount == null ? capacity : Math.min(result.maxAmount, capacity);
			Integer lower = rule.FSC_PlazoMinimo__c.intValue();
			Integer upper = rule.FSC_PlazoMaximo__c.intValue();
			result.minMonths = result.minMonths == null ? lower : Math.max(result.minMonths, lower);
			result.maxMonths = result.maxMonths == null ? upper : Math.min(result.maxMonths, upper);
		}
		if (purposes.size() != 1)
			return fail(result, 'Las garantías de una misma facilidad deben tener el mismo destino de crédito.');
		if (result.maxAmount < result.minAmount || result.maxMonths < result.minMonths) {
			return fail(result, 'La garantía no permite financiar el mínimo de la política.');
		}
		if (request.amount == null || request.amount < result.minAmount || request.amount > result.maxAmount) {
			result.amountMessage = 'El monto debe estar entre ' + result.minAmount + ' y ' + result.maxAmount + ' ' + result.currencyCode + '.';
		}
		if (
			request.months == null ||
			request.months != request.months.setScale(0) ||
			request.months < result.minMonths ||
			request.months > result.maxMonths
		) {
			result.termMessage = 'El plazo debe ser un entero entre ' + result.minMonths + ' y ' + result.maxMonths + ' meses.';
		}
		result.valid = result.amountMessage == null && result.termMessage == null;
		result.message = result.amountMessage != null ? result.amountMessage : result.termMessage;
		return result;
	}
	private static Boolean validRule(FSC_ReglaCredito__mdt rule) {
		return rule.FSC_MontoMinimo__c > 0 &&
			rule.FSC_PorcentajeMaximo__c > 0 &&
			rule.FSC_PorcentajeMaximo__c <= 100 &&
			rule.FSC_PlazoMinimo__c > 0 &&
			rule.FSC_PlazoMaximo__c <= 999 &&
			rule.FSC_PlazoMaximo__c >= rule.FSC_PlazoMinimo__c &&
			rule.FSC_PlazoMinimo__c == rule.FSC_PlazoMinimo__c.setScale(0) &&
			rule.FSC_PlazoMaximo__c == rule.FSC_PlazoMaximo__c.setScale(0);
	}
	private static Decimal convertMinimum(
		FSC_ReglaCredito__mdt rule,
		String currencyCode,
		List<FSC_TasaCambioCredito__mdt> rates,
		Date effectiveDate
	) {
		if (rule.FSC_MonedaMinimo__c == currencyCode)
			return rule.FSC_MontoMinimo__c;
		// Se usa la tasa con la vigencia más reciente que no sea futura; dos tasas con esa misma fecha son ambiguas.
		FSC_TasaCambioCredito__mdt selected;
		Integer count = 0;
		for (FSC_TasaCambioCredito__mdt rate : rates) {
			if (
				rate.FSC_MonedaOrigen__c == currencyCode &&
				rate.FSC_MonedaDestino__c == rule.FSC_MonedaMinimo__c &&
				rate.FSC_FechaVigencia__c != null &&
				rate.FSC_FechaVigencia__c <= effectiveDate &&
				rate.FSC_Tasa__c > 0 &&
				rate.FSC_FechaReferencia__c != null &&
				rate.FSC_FechaReferencia__c <= effectiveDate &&
				rate.FSC_TipoCotizacion__c == 'VENTA' &&
				String.isNotBlank(rate.FSC_Fuente__c)
			) {
				if (selected == null || rate.FSC_FechaVigencia__c > selected.FSC_FechaVigencia__c) {
					selected = rate;
					count = 1;
				} else if (rate.FSC_FechaVigencia__c == selected.FSC_FechaVigencia__c) {
					count++;
				}
			}
		}
		return count == 1 ? (rule.FSC_MontoMinimo__c / selected.FSC_Tasa__c).setScale(2, RoundingMode.CEILING) : null;
	}
	private static Decimal capacity(Guarantee guarantee, FSC_ReglaCredito__mdt rule, Result result) {
		Decimal basis;
		switch on rule.FSC_BaseCalculo__c {
			when 'MENOR_INMUEBLE_VENTA' {
				if (guarantee.propertyValue > 0 && guarantee.salePrice > 0)
					basis = Math.min(guarantee.propertyValue, guarantee.salePrice);
			}
			when 'MEJORAS' {
				basis = guarantee.improvements;
			}
			when 'SOLAR_SIN_GRAVAMEN' {
				if (key(guarantee.propertyType) != 'SOLARSINGRAVAMEN') {
					fail(result, 'Para construcción, identifique el tipo de inmueble como Solar sin gravamen.');
					return null;
				}
				basis = guarantee.propertyValue;
			}
			when 'SOLAR' {
				if (!key(guarantee.propertyType).startsWith('SOLAR')) {
					fail(result, 'La garantía debe identificar un solar para este destino.');
					return null;
				}
				basis = guarantee.propertyValue;
			}
			when 'INMUEBLE', 'INMUEBLE_CON_PRIMER_RANGO' {
				basis = guarantee.propertyValue;
			}
			when else {
				fail(result, 'La base de cálculo de la regla no es válida.');
				return null;
			}
		}
		if (basis == null || basis <= 0) {
			fail(result, 'Complete el valor positivo de la base de cálculo: ' + rule.FSC_BaseCalculo__c + '.');
			return null;
		}
		Decimal capacity = (basis * rule.FSC_PorcentajeMaximo__c / 100).setScale(2, RoundingMode.FLOOR);
		if (rule.FSC_BaseCalculo__c == 'INMUEBLE_CON_PRIMER_RANGO') {
			if (guarantee.priorBalance == null || guarantee.priorBalance < 0) {
				fail(result, 'Informe el saldo de primera hipoteca de esta garantía; use cero si no existe deuda previa.');
				return null;
			}
			capacity -= guarantee.priorBalance;
		}
		return capacity;
	}
	private static Result fail(Result result, String message) {
		result.valid = false;
		result.message = message;
		return result;
	}
	public static String key(String value) {
		if (value == null)
			return '';
		return value.toUpperCase()
			.replace('Á', 'A')
			.replace('É', 'E')
			.replace('Í', 'I')
			.replace('Ó', 'O')
			.replace('Ú', 'U')
			.replace('Ü', 'U')
			.replaceAll('[^A-Z0-9]', '');
	}
	public class PolicyInputException extends Exception {
	}
	public static FSC_CreditPolicyService.Request parse(Map<String, Object> context) {
		if (context == null)
			throw new PolicyInputException('No se recibieron datos de la solicitud.');
		FSC_CreditPolicyService.Request request = new FSC_CreditPolicyService.Request();
		String recordType = stringValue(context.get('recordTypeName'));
		request.loanType = recordType.contains('Hipotecario')
			? 'hipotecario'
			: recordType.contains('Consumo') ? 'consumo' : stringValue(context.get('loanType'));
		Map<String, Object> omni = mapValue(context.get('omniData'));
		if (omni.isEmpty())
			omni = context;
		Map<String, Object> general = mapValue(omni.get('StepDatosGeneralesSolicitud'));
		Object facilities = general.get('FSC_Facilidades_De_Credito__c');
		if (facilities == null)
			facilities = context.get('facility');
		Map<String, Object> facility = firstMap(facilities);
		request.amount = numberValue(facility.get('FSC_Monto_Solicitado__c'));
		request.months = numberValue(facility.get('FSC_Plazo_meses__c'));
		String currencyCode = stringValue(facility.get('FSC_Moneda__c'));
		request.currencyCode = currencyCode == '2' || currencyCode == 'USD' ? 'USD' : currencyCode == '1' || currencyCode == 'DOP' ? 'DOP' : '';
		if (String.isBlank(request.currencyCode) && request.loanType == 'consumo')
			request.currencyCode = 'DOP';
		Map<String, Object> applicants = mapValue(omni.get('StepDatosSolicitante'));
		if (applicants.isEmpty())
			applicants = mapValue(omni.get('DatosSolicitante'));
		if (applicants.isEmpty())
			applicants = mapValue(context.get('applicants'));
		Object account = context.get('accountId');
		if (account == null)
			account = applicants.get('AccountId');
		if (account == null)
			account = omni.get('ContextId');
		if (account != null && stringValue(account).startsWith('001'))
			request.accountId = Id.valueOf(stringValue(account));
		List<Object> debtors = listValue(applicants.get('LoanApplicant'));
		Integer count = 0;
		for (Object raw : debtors) {
			Map<String, Object> debtor = mapValue(raw);
			if (stringValue(debtor.get('FSC_TipoSolicitante__c')) == 'Deudor') {
				request.nationality = stringValue(debtor.get('FSC_Nacionalidad__c'));
				count++;
			}
		}
		if (count > 1)
			throw new PolicyInputException('Debe existir un único deudor principal.');
		for (Object raw : listValue(facility.get('FSC_Garantias__r'))) {
			request.guarantees.add(guarantee(mapValue(raw)));
		}
		return request;
	}
	public static FSC_CreditPolicyService.Guarantee guarantee(Map<String, Object> value) {
		FSC_CreditPolicyService.Guarantee result = new FSC_CreditPolicyService.Guarantee();
		result.classValue = stringValue(value.get('FSC_Clase_de_Garantia__c'));
		result.purpose = stringValue(value.get('FSC_Proposito_Garantia_Hipotecario__c'));
		result.propertyType = stringValue(value.get('FSC_Tipo_de_Inmueble__c'));
		result.propertyValue = numberValue(value.get('FSC_Valor_Inmueble__c'));
		result.salePrice = numberValue(value.get('FSC_Precio_de_Venta__c'));
		result.improvements = numberValue(value.get('FSC_Valor_Mejoras__c'));
		result.priorBalance = numberValue(value.get('FSC_SaldoPrimeraHipoteca__c'));
		return result;
	}
	public static FSC_CreditPolicyService.Guarantee storedGuarantee(FSC_Garantia__c value) {
		Map<String, Object> populatedFields = value.getPopulatedFieldsAsMap();
		return guarantee(
			new Map<String, Object>{
				'FSC_Clase_de_Garantia__c' => value.FSC_Clase_de_Garantia__c,
				'FSC_Proposito_Garantia_Hipotecario__c' => value.FSC_Proposito_Garantia_Hipotecario__c,
				'FSC_Tipo_de_Inmueble__c' => value.FSC_Tipo_de_Inmueble__c,
				'FSC_Valor_Inmueble__c' => value.FSC_Valor_Inmueble__c,
				'FSC_Precio_de_Venta__c' => value.FSC_Precio_de_Venta__c,
				'FSC_Valor_Mejoras__c' => populatedFields.get('FSC_Valor_Mejoras__c'),
				'FSC_SaldoPrimeraHipoteca__c' => populatedFields.get('FSC_SaldoPrimeraHipoteca__c')
			}
		);
	}
	public static Map<String, Object> mapValue(Object value) {
		return value instanceof Map<String, Object> ? (Map<String, Object>) value : new Map<String, Object>();
	}
	public static List<Object> listValue(Object value) {
		if (value == null)
			return new List<Object>();
		return value instanceof List<Object> ? (List<Object>) value : new List<Object>{ value };
	}
	private static Map<String, Object> firstMap(Object value) {
		if (value instanceof List<Object>) {
			List<Object> values = (List<Object>) value;
			if (values.size() > 1)
				throw new PolicyInputException('La captura de crédito personal admite una sola facilidad.');
			return values.isEmpty() ? new Map<String, Object>() : mapValue(values[0]);
		}
		return mapValue(value);
	}
	private static String stringValue(Object value) {
		return value == null ? '' : String.valueOf(value);
	}
	private static Decimal numberValue(Object value) {
		return value == null || String.isBlank(String.valueOf(value)) ? null : Decimal.valueOf(String.valueOf(value));
	}
	public static List<FSC_ReglaCredito__mdt> rules() {
		return FSC_ReglaCredito__mdt.getAll().values();
	}
	public static List<FSC_TasaCambioCredito__mdt> rates() {
		return FSC_TasaCambioCredito__mdt.getAll().values();
	}
	public static Set<String> realEstateClasses() {
		Set<String> values = new Set<String>();
		for (FSC_ClaseGarantia__mdt config : FSC_ClaseGarantia__mdt.getAll().values()) {
			if (config.FSC_Grupo__c == 'real-estate')
				values.add(FSC_CreditPolicyService.key(config.FSC_Valor__c));
		}
		return values;
	}
	public static Set<String> nationalities() {
		Set<String> values = new Set<String>();
		for (Schema.PicklistEntry entry : LoanApplicant.FSC_Nacionalidad__c.getDescribe().getPicklistValues()) {
			if (entry.isActive())
				values.add(entry.getValue());
		}
		return values;
	}
	public static Map<Id, Account> accounts(Set<Id> accountIds) {
		return new Map<Id, Account>(
			[
				SELECT Id, ACC_Nacionalidad__c, ACC_Posee_Otra_Nacionalidad__c
				FROM Account
				WHERE Id IN :accountIds
				WITH USER_MODE
			]
		);
	}
	public static Map<Id, ResidentialLoanApplication> applications(Set<Id> ids) {
		return new Map<Id, ResidentialLoanApplication>(
			[
				SELECT
					Id,
					RecordTypeId,
					AccountId,
					RecordType.DeveloperName,
					FSC_Monto__c,
					FSC_Plazo_meses__c,
					FSC_PlazoMesesAprobado__c,
					FSC_MontoAprobado__c,
					FSC_Moneda__c
				FROM ResidentialLoanApplication
				WHERE Id IN :ids
				WITH USER_MODE
			]
		);
	}
	public static List<FSC_Garantia__c> guarantees(Set<Id> ids) {
		List<String> fields = new List<String>{
			'Id',
			'FSC_Residential_Loan_Application__c',
			'FSC_Clase_de_Garantia__c',
			'FSC_Proposito_Garantia_Hipotecario__c',
			'FSC_Tipo_de_Inmueble__c',
			'FSC_Valor_Inmueble__c',
			'FSC_Precio_de_Venta__c'
		};
		if (FSC_Garantia__c.FSC_Valor_Mejoras__c.getDescribe().isAccessible()) {
			fields.add('FSC_Valor_Mejoras__c');
		}
		if (FSC_Garantia__c.FSC_SaldoPrimeraHipoteca__c.getDescribe().isAccessible()) {
			fields.add('FSC_SaldoPrimeraHipoteca__c');
		}
		return Database.queryWithBinds(
			'SELECT ' + String.join(fields, ',') + ' FROM FSC_Garantia__c WHERE FSC_Residential_Loan_Application__c IN :applicationIds',
			new Map<String, Object>{ 'applicationIds' => ids },
			AccessLevel.USER_MODE
		);
	}
}