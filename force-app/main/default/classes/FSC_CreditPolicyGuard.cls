public with sharing class FSC_CreditPolicyGuard {
	private static Map<Id, FSC_CreditPolicyService.Request> plans = new Map<Id, FSC_CreditPolicyService.Request>();
	// Permite a los tests de documentos y contratos crear solicitudes sin armar un escenario de política completo.
	@TestVisible
	private static Boolean bypassInTests = false;
	private static final Set<String> APPLICATION_FIELDS = new Set<String>{
		'AccountId',
		'RecordTypeId',
		'FSC_Monto__c',
		'FSC_Plazo_meses__c',
		'FSC_Moneda__c',
		'FSC_MontoAprobado__c',
		'FSC_PlazoMesesAprobado__c'
	};
	private static final Set<String> GUARANTEE_FIELDS = new Set<String>{
		'FSC_Residential_Loan_Application__c',
		'FSC_Clase_de_Garantia__c',
		'FSC_Proposito_Garantia_Hipotecario__c',
		'FSC_Tipo_de_Inmueble__c',
		'FSC_Valor_Inmueble__c',
		'FSC_Precio_de_Venta__c',
		'FSC_Valor_Mejoras__c',
		'FSC_SaldoPrimeraHipoteca__c'
	};
	public static void registerPlan(FSC_CreditPolicyService.Request request) {
		FSC_CreditPolicyService.Result result = FSC_CreditPolicyService.evaluate(new List<FSC_CreditPolicyService.Request>{ request })[0];
		if (!result.valid)
			throw new FSC_CreditPolicyController.CreditPolicyException(result.message);
		plans.put(request.accountId, request);
	}
	public static void validateApplications(List<ResidentialLoanApplication> records, Map<Id, ResidentialLoanApplication> previous) {
		if (records == null || records.isEmpty() || bypassed())
			return;
		List<ResidentialLoanApplication> targets = new List<ResidentialLoanApplication>();
		Set<Id> ids = new Set<Id>();
		for (ResidentialLoanApplication record : records) {
			if (loanType(record.RecordTypeId) == '' || !changed(record, previous == null ? null : previous.get(record.Id), APPLICATION_FIELDS))
				continue;
			if (
				record.FSC_Monto__c == null &&
				String.isBlank(record.FSC_Plazo_meses__c) &&
				record.FSC_MontoAprobado__c == null &&
				record.FSC_PlazoMesesAprobado__c == null
			)
				continue;
			targets.add(record);
			if (record.Id != null)
				ids.add(record.Id);
		}
		if (targets.isEmpty())
			return;
		Map<Id, List<FSC_CreditPolicyService.Guarantee>> grouped = groupedGuarantees(ids);
		List<FSC_CreditPolicyService.Request> requests = new List<FSC_CreditPolicyService.Request>();
		for (ResidentialLoanApplication record : targets) {
			FSC_CreditPolicyService.Request request = fromApplication(record, grouped.get(record.Id));
			FSC_CreditPolicyService.Request plan = plans.get(record.AccountId);
			if (matches(plan, request))
				request.guarantees = plan.guarantees;
			requests.add(request);
		}
		applyApplicationResults(targets, requests);
	}
	private static void applyApplicationResults(List<ResidentialLoanApplication> records, List<FSC_CreditPolicyService.Request> requests) {
		List<FSC_CreditPolicyService.Result> results = FSC_CreditPolicyService.evaluate(requests);
		List<FSC_CreditPolicyService.Request> approvedRequests = new List<FSC_CreditPolicyService.Request>();
		List<Integer> indexes = new List<Integer>();
		for (Integer index = 0; index < records.size(); index++) {
			if (!results[index].valid)
				records[index].addError(results[index].message);
			if (results[index].applicable && requests[index].loanType == 'consumo')
				records[index].FSC_TipoGarantia__c = 'Garantía Real';
			if (results[index].applicable && (records[index].FSC_MontoAprobado__c != null || records[index].FSC_PlazoMesesAprobado__c != null)) {
				FSC_CreditPolicyService.Request approved = (FSC_CreditPolicyService.Request) JSON.deserialize(
					JSON.serialize(requests[index]),
					FSC_CreditPolicyService.Request.class
				);
				if (records[index].FSC_MontoAprobado__c != null)
					approved.amount = records[index].FSC_MontoAprobado__c;
				if (records[index].FSC_PlazoMesesAprobado__c != null)
					approved.months = records[index].FSC_PlazoMesesAprobado__c;
				approvedRequests.add(approved);
				indexes.add(index);
			}
		}
		List<FSC_CreditPolicyService.Result> approvedResults = FSC_CreditPolicyService.evaluate(approvedRequests);
		for (Integer index = 0; index < approvedResults.size(); index++) {
			if (!approvedResults[index].valid)
				records[indexes[index]].addError('Condiciones aprobadas: ' + approvedResults[index].message);
		}
	}
	public static void validateGuarantees(List<FSC_Garantia__c> records, Map<Id, FSC_Garantia__c> previous) {
		if (records == null || records.isEmpty() || bypassed())
			return;
		Set<Id> ids = new Set<Id>();
		for (FSC_Garantia__c record : records) {
			if (changed(record, previous == null ? null : previous.get(record.Id), GUARANTEE_FIELDS))
				ids.add(record.FSC_Residential_Loan_Application__c);
		}
		ids.remove(null);
		if (ids.isEmpty())
			return;
		Map<Id, ResidentialLoanApplication> applications = FSC_CreditPolicyService.applications(ids);
		Set<Id> policyIds = new Set<Id>();
		for (ResidentialLoanApplication application : applications.values()) {
			if (loanType(application.RecordTypeId) != '' && application.FSC_Monto__c != null) {
				policyIds.add(application.Id);
			}
		}
		if (policyIds.isEmpty()) {
			return;
		}
		Map<Id, List<FSC_CreditPolicyService.Guarantee>> grouped = groupedGuarantees(policyIds);
		List<FSC_CreditPolicyService.Request> requests = new List<FSC_CreditPolicyService.Request>();
		List<Id> order = new List<Id>();
		for (ResidentialLoanApplication application : applications.values()) {
			if (loanType(application.RecordTypeId) == '' || application.FSC_Monto__c == null)
				continue;
			FSC_CreditPolicyService.Request request = fromApplication(application, grouped.get(application.Id));
			requests.add(request);
			order.add(application.Id);
			if (application.FSC_MontoAprobado__c != null || application.FSC_PlazoMesesAprobado__c != null) {
				FSC_CreditPolicyService.Request approved = (FSC_CreditPolicyService.Request) JSON.deserialize(
					JSON.serialize(request),
					FSC_CreditPolicyService.Request.class
				);
				if (application.FSC_MontoAprobado__c != null)
					approved.amount = application.FSC_MontoAprobado__c;
				if (application.FSC_PlazoMesesAprobado__c != null)
					approved.months = application.FSC_PlazoMesesAprobado__c;
				requests.add(approved);
				order.add(application.Id);
			}
		}
		List<FSC_CreditPolicyService.Result> results = FSC_CreditPolicyService.evaluate(requests);
		Map<Id, String> errors = new Map<Id, String>();
		for (Integer index = 0; index < results.size(); index++) {
			if (!results[index].valid)
				errors.put(order[index], results[index].message);
		}
		for (FSC_Garantia__c record : records) {
			String message = errors.get(record.FSC_Residential_Loan_Application__c);
			if (message != null)
				record.addError(message);
		}
	}
	public static void validateFacilities(List<FSC_Facilidades_De_Credito__c> records, Map<Id, FSC_Facilidades_De_Credito__c> previous) {
		if (records == null || records.isEmpty() || bypassed())
			return;
		Set<Id> ids = new Set<Id>();
		List<FSC_Facilidades_De_Credito__c> targets = new List<FSC_Facilidades_De_Credito__c>();
		Set<String> fields = new Set<String>{
			'FSC_Monto_Solicitado__c',
			'FSC_Plazo_meses__c',
			'FSC_Moneda__c',
			'FSC_Residential_Loan_Application__c'
		};
		for (FSC_Facilidades_De_Credito__c record : records) {
			if (changed(record, previous == null ? null : previous.get(record.Id), fields)) {
				targets.add(record);
				ids.add(record.FSC_Residential_Loan_Application__c);
			}
		}
		ids.remove(null);
		if (ids.isEmpty())
			return;
		Map<Id, ResidentialLoanApplication> applications = FSC_CreditPolicyService.applications(ids);
		Map<Id, List<FSC_CreditPolicyService.Guarantee>> grouped = groupedGuarantees(ids);
		List<FSC_CreditPolicyService.Request> requests = new List<FSC_CreditPolicyService.Request>();
		List<FSC_Facilidades_De_Credito__c> evaluated = new List<FSC_Facilidades_De_Credito__c>();
		for (FSC_Facilidades_De_Credito__c record : targets) {
			ResidentialLoanApplication parent = applications.get(record.FSC_Residential_Loan_Application__c);
			if (parent == null || loanType(parent.RecordTypeId) == '')
				continue;
			FSC_CreditPolicyService.Request request = fromApplication(parent, grouped.get(parent.Id));
			request.amount = record.FSC_Monto_Solicitado__c;
			request.months = record.FSC_Plazo_meses__c;
			if (String.isNotBlank(record.FSC_Moneda__c))
				request.currencyCode = currencyCode(record.FSC_Moneda__c);
			requests.add(request);
			evaluated.add(record);
		}
		List<FSC_CreditPolicyService.Result> results = FSC_CreditPolicyService.evaluate(requests);
		for (Integer index = 0; index < results.size(); index++) {
			if (!results[index].valid)
				evaluated[index].addError(results[index].message);
		}
	}
	private static Boolean bypassed() {
		return Test.isRunningTest() && bypassInTests;
	}
	private static Map<Id, List<FSC_CreditPolicyService.Guarantee>> groupedGuarantees(Set<Id> ids) {
		Map<Id, List<FSC_CreditPolicyService.Guarantee>> grouped = new Map<Id, List<FSC_CreditPolicyService.Guarantee>>();
		if (ids.isEmpty())
			return grouped;
		for (FSC_Garantia__c guarantee : FSC_CreditPolicyService.guarantees(ids)) {
			Id parentId = guarantee.FSC_Residential_Loan_Application__c;
			if (!grouped.containsKey(parentId))
				grouped.put(parentId, new List<FSC_CreditPolicyService.Guarantee>());
			grouped.get(parentId).add(FSC_CreditPolicyService.storedGuarantee(guarantee));
		}
		return grouped;
	}
	private static FSC_CreditPolicyService.Request fromApplication(
		ResidentialLoanApplication application,
		List<FSC_CreditPolicyService.Guarantee> guarantees
	) {
		FSC_CreditPolicyService.Request request = new FSC_CreditPolicyService.Request();
		request.accountId = application.AccountId;
		request.loanType = loanType(application.RecordTypeId);
		request.currencyCode = String.isBlank(application.FSC_Moneda__c) && request.loanType == 'consumo'
			? 'DOP'
			: currencyCode(application.FSC_Moneda__c);
		request.amount = application.FSC_Monto__c;
		request.months = String.isBlank(application.FSC_Plazo_meses__c) ? null : Decimal.valueOf(application.FSC_Plazo_meses__c);
		request.guarantees = guarantees == null ? new List<FSC_CreditPolicyService.Guarantee>() : guarantees;
		return request;
	}
	private static String currencyCode(String value) {
		return value == '2' || value == 'USD' ? 'USD' : value == '1' || value == 'DOP' ? 'DOP' : '';
	}
	private static Boolean matches(FSC_CreditPolicyService.Request plan, FSC_CreditPolicyService.Request request) {
		return plan != null &&
			plan.loanType == request.loanType &&
			plan.amount == request.amount &&
			plan.months == request.months &&
			plan.currencyCode == request.currencyCode;
	}
	public static String loanType(Id recordTypeId) {
		Schema.RecordTypeInfo info = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosById().get(recordTypeId);
		String name = info == null ? '' : info.getDeveloperName();
		return name == 'FSC_Solicitud_Credito_Hipotecario' ? 'hipotecario' : name == 'FSC_Solicitud_Credito_Consumo' ? 'consumo' : '';
	}
	private static Boolean changed(SObject current, SObject previous, Set<String> fields) {
		if (previous == null)
			return true;
		for (String field : fields) {
			if (current.get(field) != previous.get(field))
				return true;
		}
		return false;
	}
}