@IsTest
private class FSC_CreditPolicyControllerTest {
	@IsTest
	static void initialDraftDoesNotRequireLimits() {
		Map<String, Object> output = new Map<String, Object>();
		Test.startTest();
		Object result = new FSC_CreditPolicyController()
			.call(
				'validate',
				new Map<String, Object>{
					'input' => new Map<String, Object>{ 'recordTypeName' => 'FSC_Solicitud_Credito_Hipotecario' },
					'output' => output
				}
			);
		Test.stopTest();
		Assert.areEqual(true, result, 'La primera captura puede crear un borrador vacío.');
		Assert.areEqual(true, output.get('success'), 'Debe informar éxito del borrador.');
	}
	@IsTest
	static void callableValidatesCompleteConsumptionInput() {
		Map<String, Object> output = new Map<String, Object>();
		Test.startTest();
		Object result = new FSC_CreditPolicyController()
			.call(
				'validate',
				new Map<String, Object>{
					'input' => new Map<String, Object>{
						'loanType' => 'consumo',
						'facility' => new Map<String, Object>{
							'FSC_Monto_Solicitado__c' => 500000,
							'FSC_Plazo_meses__c' => 24,
							'FSC_Moneda__c' => '1'
						}
					},
					'output' => output
				}
			);
		Test.stopTest();
		Assert.areEqual(true, result, 'La validación debe procesar las condiciones completas.');
		Assert.areEqual(true, output.get('success'), 'El consumo dentro del plazo general debe validarse.');
	}
	@IsTest
	static void callableRejectsCompleteMortgageWithoutBorrowerNationality() {
		Test.startTest();
		try {
			new FSC_CreditPolicyController()
				.call(
					'validate',
					new Map<String, Object>{
						'input' => new Map<String, Object>{
							'loanType' => 'hipotecario',
							'facility' => new Map<String, Object>{
								'FSC_Monto_Solicitado__c' => 500000,
								'FSC_Plazo_meses__c' => 120,
								'FSC_Moneda__c' => '1'
							}
						},
						'output' => new Map<String, Object>()
					}
				);
			Assert.fail('La captura completa no puede omitir la nacionalidad del deudor.');
		} catch (FSC_CreditPolicyController.CreditPolicyException expected) {
			Assert.isTrue(expected.getMessage().contains('nacionalidad'), 'Debe devolver el rechazo de la política a OmniStudio.');
		}
		Test.stopTest();
	}
	@IsTest
	static void rejectsUnsupportedCallableAction() {
		Test.startTest();
		try {
			new FSC_CreditPolicyController().call('unknown', new Map<String, Object>());
			Assert.fail('Debe rechazar una acción desconocida.');
		} catch (FSC_CreditPolicyController.CreditPolicyException expected) {
			Assert.isTrue(expected.getMessage().contains('no soportada'), 'Debe informar la acción inválida.');
		}
		Test.stopTest();
	}
	@IsTest
	static void controllerSanitizesMalformedInput() {
		Test.startTest();
		try {
			FSC_CreditPolicyController.evaluate('{');
			Assert.fail('El JSON incompleto debe rechazarse.');
		} catch (AuraHandledException expected) {
			Assert.isNotNull(expected, 'El controlador debe devolver un error controlado.');
		}
		Test.stopTest();
	}

	@IsTest
	static void exportsOnlyActiveRules() {
		Test.startTest();
		List<FSC_ReglaCredito__mdt> rules = FSC_CreditPolicyController.getRules();
		Test.stopTest();
		Assert.isFalse(rules.isEmpty(), 'Debe entregar las reglas configuradas para la interfaz.');
		for (FSC_ReglaCredito__mdt rule : rules)
			Assert.isTrue(rule.FSC_Activa__c, 'No debe exponer reglas inactivas.');
	}
}