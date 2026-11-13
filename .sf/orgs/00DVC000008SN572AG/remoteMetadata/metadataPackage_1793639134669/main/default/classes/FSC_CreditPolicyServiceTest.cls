@IsTest
private class FSC_CreditPolicyServiceTest {
	@IsTest
	static void rejectsNullCaptureContext() {
		Test.startTest();
		try {
			FSC_CreditPolicyService.parse(null);
			Assert.fail('Un contexto ausente debe rechazarse con un error controlado.');
		} catch (FSC_CreditPolicyService.PolicyInputException expected) {
			Assert.isTrue(expected.getMessage().contains('No se recibieron'), 'Debe explicar la ausencia del contexto.');
		}
		Test.stopTest();
	}

	@IsTest
	static void rejectsSeveralFacilitiesInPersonalCapture() {
		Map<String, Object> context = new Map<String, Object>{
			'loanType' => 'consumo',
			'facility' => new List<Object>{ new Map<String, Object>(), new Map<String, Object>() }
		};
		Test.startTest();
		try {
			FSC_CreditPolicyService.parse(context);
			Assert.fail('La captura personal debe rechazar más de una facilidad.');
		} catch (FSC_CreditPolicyService.PolicyInputException expected) {
			Assert.isTrue(expected.getMessage().contains('una sola facilidad'), 'Debe identificar la ambigüedad de las facilidades.');
		}
		Test.stopTest();
	}

	@IsTest
	static void rejectsSeveralPrimaryBorrowers() {
		Map<String, Object> debtor = new Map<String, Object>{ 'FSC_TipoSolicitante__c' => 'Deudor', 'FSC_Nacionalidad__c' => 'ARGENTINA' };
		Map<String, Object> context = new Map<String, Object>{
			'loanType' => 'hipotecario',
			'applicants' => new Map<String, Object>{ 'LoanApplicant' => new List<Object>{ debtor, debtor } }
		};
		Test.startTest();
		try {
			FSC_CreditPolicyService.parse(context);
			Assert.fail('No se puede clasificar un crédito con dos deudores principales.');
		} catch (FSC_CreditPolicyService.PolicyInputException expected) {
			Assert.isTrue(expected.getMessage().contains('único deudor'), 'Debe explicar que el deudor principal es ambiguo.');
		}
		Test.stopTest();
	}

	@IsTest
	static void parsesSingleBorrowerAndDefaultsConsumptionCurrency() {
		Map<String, Object> context = new Map<String, Object>{
			'recordTypeName' => 'FSC_Solicitud_Credito_Consumo',
			'DatosSolicitante' => new Map<String, Object>{
				'LoanApplicant' => new Map<String, Object>{ 'FSC_TipoSolicitante__c' => 'Deudor', 'FSC_Nacionalidad__c' => 'ARGENTINA' }
			},
			'facility' => new Map<String, Object>{ 'FSC_Monto_Solicitado__c' => 500000, 'FSC_Plazo_meses__c' => 24 }
		};
		Test.startTest();
		FSC_CreditPolicyService.Request result = FSC_CreditPolicyService.parse(context);
		Test.stopTest();
		Assert.areEqual('ARGENTINA', result.nationality, 'Debe interpretar el deudor representado como objeto individual.');
		Assert.areEqual('DOP', result.currencyCode, 'El consumo sin moneda explícita se captura en pesos.');
	}

	@IsTest
	static void acceptsEveryConfiguredScenario() {
		Test.startTest();
		for (FSC_ReglaCredito__mdt rule : rules()) {
			FSC_CreditPolicyService.Result result = evaluate(request(rule));
			Assert.isTrue(result.valid, rule.DeveloperName + ': ' + result.message);
			Assert.areEqual(rule.FSC_PlazoMinimo__c.intValue(), result.minMonths, 'Mínimo de meses del escenario.');
			Assert.areEqual(rule.FSC_PlazoMaximo__c.intValue(), result.maxMonths, 'Máximo de meses del escenario.');
		}
		Test.stopTest();
	}
	@IsTest
	static void acceptsInclusiveAmountAndTermBoundaries() {
		FSC_CreditPolicyService.Request request = localPurchase();
		Test.startTest();
		request.amount = 500000;
		request.months = 6;
		Assert.isTrue(evaluate(request).valid, 'Los mínimos inclusivos deben admitirse.');
		request.amount = 1200000;
		request.months = 360;
		Assert.isTrue(evaluate(request).valid, 'El máximo usa el menor valor, 1.500.000 por 80%.');
		Test.stopTest();
	}
	@IsTest
	static void rejectsAmountOutsideBoundaries() {
		FSC_CreditPolicyService.Request request = localPurchase();
		Test.startTest();
		request.amount = 499999.99;
		Assert.isNotNull(evaluate(request).amountMessage, 'Debe rechazar un centavo bajo el mínimo.');
		request.amount = 1200000.01;
		Assert.isNotNull(evaluate(request).amountMessage, 'Debe rechazar un centavo sobre el máximo.');
		Test.stopTest();
	}
	@IsTest
	static void rejectsNonIntegerAndOutOfRangeTerms() {
		FSC_CreditPolicyService.Request request = localPurchase();
		Test.startTest();
		for (Decimal months : new List<Decimal>{ 5, 361, 6.5 }) {
			request.months = months;
			Assert.isNotNull(evaluate(request).termMessage, 'Debe rechazar el plazo ' + months);
		}
		Test.stopTest();
	}
	@IsTest
	static void foreignPurchaseRequiresSixtyMonthsAndTenThousandUsd() {
		FSC_CreditPolicyService.Request request = request(FSC_ReglaCredito__mdt.getInstance('ExtCompraUSD'));
		Test.startTest();
		request.months = 59;
		Assert.isFalse(evaluate(request).valid, 'Extranjeros requieren al menos 60 meses.');
		request.months = 60;
		request.amount = 9999.99;
		Assert.isFalse(evaluate(request).valid, 'No se convierte ni reduce el mínimo extranjero.');
		request.amount = 10000;
		Assert.isTrue(evaluate(request).valid, 'Debe admitir ambos mínimos exactos.');
		Test.stopTest();
	}
	@IsTest
	static void convertsLocalUsdMinimumUpward() {
		FSC_CreditPolicyService.Request request = request(FSC_ReglaCredito__mdt.getInstance('HipCompraUSD'));
		Test.startTest();
		request.amount = 8127.43;
		FSC_CreditPolicyService.Result invalid = evaluate(request);
		Assert.areEqual(8127.44, invalid.minAmount, 'El mínimo convertido se redondea hacia arriba.');
		Assert.isFalse(invalid.valid, 'El centavo inferior debe rechazarse.');
		request.amount = 8127.44;
		Assert.isTrue(evaluate(request).valid, 'El mínimo convertido debe admitirse.');
		Test.stopTest();
	}
	@IsTest
	static void keepsMostRecentRateOnLaterDates() {
		FSC_CreditPolicyService.Request request = request(FSC_ReglaCredito__mdt.getInstance('HipCompraUSD'));
		request.amount = 8127.44;
		Test.startTest();
		FSC_CreditPolicyService.Result result = evaluateWithRates(request, new List<FSC_TasaCambioCredito__mdt>{ rate(61.52, POLICY_DATE) }, POLICY_DATE.addDays(30));
		Test.stopTest();
		Assert.isTrue(result.valid, 'La última tasa sigue vigente hasta que se cargue otra: ' + result.message);
		Assert.areEqual(8127.44, result.minAmount, 'Debe convertir con la tasa más reciente.');
	}
	@IsTest
	static void prefersMostRecentRateOverOlderOnes() {
		FSC_CreditPolicyService.Request request = request(FSC_ReglaCredito__mdt.getInstance('HipCompraUSD'));
		List<FSC_TasaCambioCredito__mdt> rates = new List<FSC_TasaCambioCredito__mdt>{
			rate(61.52, POLICY_DATE),
			rate(50, POLICY_DATE.addDays(-10)),
			rate(70, POLICY_DATE.addDays(5))
		};
		Test.startTest();
		FSC_CreditPolicyService.Result result = evaluateWithRates(request, rates, POLICY_DATE.addDays(2));
		Test.stopTest();
		Assert.areEqual(8127.44, result.minAmount, 'Se ignoran las tasas anteriores y las de vigencia futura.');
	}
	@IsTest
	static void rejectsMissingOrAmbiguousRate() {
		FSC_CreditPolicyService.Request request = request(FSC_ReglaCredito__mdt.getInstance('HipCompraUSD'));
		Test.startTest();
		FSC_CreditPolicyService.Result future = evaluateWithRates(request, new List<FSC_TasaCambioCredito__mdt>{ rate(61.52, POLICY_DATE) }, POLICY_DATE.addDays(-1));
		FSC_CreditPolicyService.Result tied = evaluateWithRates(
			request,
			new List<FSC_TasaCambioCredito__mdt>{ rate(61.52, POLICY_DATE), rate(60, POLICY_DATE) },
			POLICY_DATE
		);
		Test.stopTest();
		Assert.isFalse(future.valid, 'Una tasa de vigencia futura no aplica hoy.');
		Assert.isTrue(future.message.contains('tasa de cambio'), 'Debe identificar la configuración de tasa.');
		Assert.isFalse(tied.valid, 'No se escoge silenciosamente entre dos tasas de la misma fecha.');
	}
	private static FSC_TasaCambioCredito__mdt rate(Decimal value, Date effectiveFrom) {
		return new FSC_TasaCambioCredito__mdt(
			FSC_MonedaOrigen__c = 'USD',
			FSC_MonedaDestino__c = 'DOP',
			FSC_Tasa__c = value,
			FSC_FechaVigencia__c = effectiveFrom,
			FSC_FechaReferencia__c = effectiveFrom.addDays(-1),
			FSC_TipoCotizacion__c = 'VENTA',
			FSC_Fuente__c = 'https://www.aduanas.gob.do/tasa-de-cambio/'
		);
	}
	private static FSC_CreditPolicyService.Result evaluateWithRates(
		FSC_CreditPolicyService.Request request,
		List<FSC_TasaCambioCredito__mdt> rates,
		Date effectiveDate
	) {
		return evaluate(new List<FSC_CreditPolicyService.Request>{ request }, rules(), rates, effectiveDate)[0];
	}
	@IsTest
	static void reconstructsUsingOnlyImprovements() {
		FSC_CreditPolicyService.Request request = request(FSC_ReglaCredito__mdt.getInstance('HipReconstruccion'));
		request.guarantees[0].propertyValue = 10000000;
		Test.startTest();
		FSC_CreditPolicyService.Result result = evaluate(request);
		Test.stopTest();
		Assert.areEqual(600000, result.maxAmount, 'El máximo es 60% de las mejoras, no del inmueble.');
	}
	@IsTest
	static void subtractsPriorLienFromTotalExposure() {
		FSC_CreditPolicyService.Request request = request(FSC_ReglaCredito__mdt.getInstance('ConsSegundaHipoteca'));
		request.guarantees[0].priorBalance = 700000;
		Test.startTest();
		FSC_CreditPolicyService.Result result = evaluate(request);
		Test.stopTest();
		Assert.areEqual(900000, result.maxAmount, '80% de 2.000.000 menos 700.000 de primer rango.');
	}
	@IsTest
	static void requiresExplicitPriorBalance() {
		FSC_CreditPolicyService.Request request = request(FSC_ReglaCredito__mdt.getInstance('HipRemodelacion'));
		request.guarantees[0].priorBalance = null;
		Test.startTest();
		FSC_CreditPolicyService.Result result = evaluate(request);
		Test.stopTest();
		Assert.isFalse(result.valid, 'No se presume saldo cero.');
	}
	@IsTest
	static void rejectsMissingNationality() {
		FSC_CreditPolicyService.Request request = localPurchase();
		request.nationality = '';
		Test.startTest();
		FSC_CreditPolicyService.Result result = evaluate(request);
		Test.stopTest();
		Assert.isFalse(result.valid, 'Nacionalidad vacía no implica perfil local.');
	}
	@IsTest
	static void rejectsDualNationalityPendingReview() {
		FSC_CreditPolicyService.Request request = localPurchase();
		request.dualNationality = true;
		Test.startTest();
		FSC_CreditPolicyService.Result result = evaluate(request);
		Test.stopTest();
		Assert.isFalse(result.valid, 'La doble nacionalidad requiere revisión.');
	}
	@IsTest
	static void rejectsAmbiguousDestinationAndDuplicateRules() {
		FSC_CreditPolicyService.Request request = localPurchase();
		List<FSC_ReglaCredito__mdt> rules = rules();
		rules.add(FSC_ReglaCredito__mdt.getInstance('HipCompraDOP'));
		Test.startTest();
		List<FSC_CreditPolicyService.Result> results = evaluate(
			new List<FSC_CreditPolicyService.Request>{ request },
			rules,
			new List<FSC_TasaCambioCredito__mdt>(),
			POLICY_DATE
		);
		Test.stopTest();
		Assert.isFalse(results[0].valid, 'No se escoge silenciosamente entre dos reglas.');
	}
	@IsTest
	static void requiresUnencumberedLotForConstruction() {
		FSC_CreditPolicyService.Request request = request(FSC_ReglaCredito__mdt.getInstance('HipConstruccion'));
		request.guarantees[0].propertyType = 'Solar';
		Test.startTest();
		FSC_CreditPolicyService.Result result = evaluate(request);
		Test.stopTest();
		Assert.isFalse(result.valid, 'No se presume que un solar esté libre de gravamen.');
	}
	@IsTest
	static void neverAddsSeveralGuaranteeCapacities() {
		FSC_CreditPolicyService.Request request = localPurchase();
		FSC_CreditPolicyService.Guarantee second = request(FSC_ReglaCredito__mdt.getInstance('HipCompraDOP')).guarantees[0];
		second.propertyValue = 1000000;
		request.guarantees.add(second);
		Test.startTest();
		FSC_CreditPolicyService.Result result = evaluate(request);
		Test.stopTest();
		Assert.areEqual(800000, result.maxAmount, 'Se conserva el límite más restrictivo sin sumar garantías.');
	}
	@IsTest
	static void processesTwoHundredFiftyOneWithoutQueriesOrDml() {
		List<FSC_CreditPolicyService.Request> requests = new List<FSC_CreditPolicyService.Request>();
		for (Integer index = 0; index < 251; index++)
			requests.add(localPurchase());
		Test.startTest();
		Integer queryCount = Limits.getQueries();
		Integer dmlCount = Limits.getDmlStatements();
		List<FSC_CreditPolicyService.Result> results = evaluate(requests, rules(), new List<FSC_TasaCambioCredito__mdt>(), POLICY_DATE);
		Assert.areEqual(queryCount, Limits.getQueries(), 'El dominio no consulta registros.');
		Assert.areEqual(dmlCount, Limits.getDmlStatements(), 'El dominio no ejecuta DML.');
		Test.stopTest();
		Assert.areEqual(251, results.size(), 'Debe devolver un resultado por entrada.');
		for (FSC_CreditPolicyService.Result result : results)
			Assert.isTrue(result.valid, 'Cada elemento debe ser válido.');
	}
	private static FSC_CreditPolicyService.Request localPurchase() {
		return request(FSC_ReglaCredito__mdt.getInstance('HipCompraDOP'));
	}
	@IsTest
	static void keepsGeneralConsumptionLimitOutsideRealEstatePolicy() {
		FSC_CreditPolicyService.Request request = new FSC_CreditPolicyService.Request();
		request.loanType = 'consumo';
		request.months = 999;
		Test.startTest();
		FSC_CreditPolicyService.Result result = FSC_CreditPolicyService.evaluate(new List<FSC_CreditPolicyService.Request>{ request })[0];
		Test.stopTest();
		Assert.isFalse(result.applicable, 'No hay garantía inmobiliaria.');
		Assert.isFalse(result.valid, 'La ausencia de garantía no permite saltarse el plazo general.');
	}
	@IsTest
	static void leavesOtherProductsOutsidePolicy() {
		FSC_CreditPolicyService.Request request = new FSC_CreditPolicyService.Request();
		request.loanType = 'vehiculo';
		Test.startTest();
		FSC_CreditPolicyService.Result result = FSC_CreditPolicyService.evaluate(new List<FSC_CreditPolicyService.Request>{ request })[0];
		Test.stopTest();
		Assert.isTrue(result.valid, 'Se conserva la validación específica de vehículos existente.');
		Assert.isFalse(result.applicable, 'No corresponde a la política inmobiliaria.');
	}
	@IsTest
	static void parsesActualOmniPayload() {
		Map<String, Object> facility = new Map<String, Object>{
			'FSC_Monto_Solicitado__c' => '500000',
			'FSC_Plazo_meses__c' => '120',
			'FSC_Moneda__c' => '1',
			'FSC_Garantias__r' => new List<Object>{
				new Map<String, Object>{
					'FSC_Clase_de_Garantia__c' => 'Inmueble',
					'FSC_Valor_Mejoras__c' => 1000000,
					'FSC_SaldoPrimeraHipoteca__c' => 0,
					'FSC_Valor_Inmueble__c' => 2000000
				}
			}
		};
		Map<String, Object> payload = new Map<String, Object>{
			'recordTypeName' => 'FSC_Solicitud_Credito_Hipotecario',
			'omniData' => new Map<String, Object>{
				'StepDatosGeneralesSolicitud' => new Map<String, Object>{ 'FSC_Facilidades_De_Credito__c' => new List<Object>{ facility } }
			}
		};
		Test.startTest();
		FSC_CreditPolicyService.Request result = FSC_CreditPolicyService.parse(payload);
		Test.stopTest();
		Assert.areEqual('hipotecario', result.loanType, 'Debe identificar el producto del OmniScript.');
		Assert.areEqual(500000, result.amount, 'Debe convertir la representación numérica.');
		Assert.areEqual(1000000, result.guarantees[0].improvements, 'Debe conservar mejoras.');
		Assert.areEqual(0, result.guarantees[0].priorBalance, 'Cero es un saldo explícito válido.');
	}
	private static final Date POLICY_DATE = Date.newInstance(2026, 10, 21);
	private static List<FSC_ReglaCredito__mdt> rules() {
		return FSC_ReglaCredito__mdt.getAll().values();
	}
	private static FSC_CreditPolicyService.Request request(FSC_ReglaCredito__mdt rule) {
		FSC_CreditPolicyService.Request request = new FSC_CreditPolicyService.Request();
		request.loanType = rule.FSC_Producto__c == 'HIPOTECARIO' ? 'hipotecario' : 'consumo';
		request.currencyCode = rule.FSC_Moneda__c == 'TODAS' ? 'DOP' : rule.FSC_Moneda__c;
		request.nationality = rule.FSC_Perfil__c == 'EXTRANJERO' ? 'ARGENTINA' : 'REPUBLICA DOMINICANA';
		request.dualNationality = false;
		request.amount = request.currencyCode == 'USD' ? 10000 : 500000;
		request.months = rule.FSC_PlazoMinimo__c;
		FSC_CreditPolicyService.Guarantee guarantee = new FSC_CreditPolicyService.Guarantee();
		guarantee.classValue = 'Inmueble';
		guarantee.purpose = rule.FSC_Proposito__c;
		guarantee.propertyType = 'Solar sin gravamen';
		guarantee.propertyValue = 2000000;
		guarantee.salePrice = 1500000;
		guarantee.improvements = 1000000;
		guarantee.priorBalance = 0;
		request.guarantees.add(guarantee);
		return request;
	}
	private static FSC_CreditPolicyService.Result evaluate(FSC_CreditPolicyService.Request request) {
		return evaluate(new List<FSC_CreditPolicyService.Request>{ request }, rules(), FSC_TasaCambioCredito__mdt.getAll().values(), POLICY_DATE)[0];
	}
	private static List<FSC_CreditPolicyService.Result> evaluate(
		List<FSC_CreditPolicyService.Request> requests,
		List<FSC_ReglaCredito__mdt> rules,
		List<FSC_TasaCambioCredito__mdt> rates,
		Date effectiveDate
	) {
		return FSC_CreditPolicyService.evaluate(
			requests,
			rules,
			rates,
			new Set<String>{ 'INMUEBLE' },
			new Set<String>{ 'REPUBLICA DOMINICANA', 'ARGENTINA' },
			effectiveDate
		);
	}
}