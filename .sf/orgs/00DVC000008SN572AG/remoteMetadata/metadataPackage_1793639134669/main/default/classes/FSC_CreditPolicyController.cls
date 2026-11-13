global with sharing class FSC_CreditPolicyController implements System.Callable {
	@AuraEnabled(cacheable=true)
	public static List<FSC_ReglaCredito__mdt> getRules() {
		List<FSC_ReglaCredito__mdt> rules = new List<FSC_ReglaCredito__mdt>();
		for (FSC_ReglaCredito__mdt rule : FSC_CreditPolicyService.rules()) {
			if (rule.FSC_Activa__c)
				rules.add(rule);
		}
		return rules;
	}
	@AuraEnabled
	public static FSC_CreditPolicyService.Result evaluate(String contextJson) {
		try {
			FSC_CreditPolicyService.Request request = FSC_CreditPolicyService.parse((Map<String, Object>) JSON.deserializeUntyped(contextJson));
			return FSC_CreditPolicyService.evaluate(new List<FSC_CreditPolicyService.Request>{ request })[0];
		} catch (Exception exceptionValue) {
			throw new AuraHandledException('No se pudieron validar los límites. Revise los datos y los permisos de acceso.');
		}
	}
	public class CreditPolicyException extends Exception {
	}
	global Object call(String action, Map<String, Object> args) {
		if (action != 'validate')
			throw new CreditPolicyException('Acción de política no soportada.');
		Map<String, Object> input = FSC_CreditPolicyService.mapValue(args == null ? null : args.get('input'));
		Map<String, Object> output = FSC_CreditPolicyService.mapValue(args == null ? null : args.get('output'));
		FSC_CreditPolicyService.Request request = FSC_CreditPolicyService.parse(input);
		// El primer paso de captura crea un borrador sin monto ni garantías.
		if (request.amount == null && request.months == null && request.guarantees.isEmpty()) {
			output.put('success', true);
			return true;
		}
		FSC_CreditPolicyService.Result result = FSC_CreditPolicyService.evaluate(new List<FSC_CreditPolicyService.Request>{ request })[0];
		output.put('success', result.valid);
		output.put('message', result.message);
		if (!result.valid)
			throw new CreditPolicyException(result.message);
		if (result.applicable && request.accountId != null)
			FSC_CreditPolicyGuard.registerPlan(request);
		return true;
	}
}