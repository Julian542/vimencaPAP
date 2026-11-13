global without sharing class FSC_ConsultaProdFinRemoteAction implements Callable {

    global Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');

        try {
            if (action == 'startAsync' || action == 'iniciarConsultaProdFinAsync') {
                Id accountId = extractAccountId(input);

                if (accountId == null) {
                    output.put('success', false);
                    output.put('message', 'No se recibió un Account Id válido.');
                    return output;
                }

                wsConsultaProdFinPFPJ_FSC.futureConsultaProdFin_PF_PJ(accountId);

                output.put('success', true);
                output.put('message', 'Proceso encolado correctamente.');
                output.put('accountId', accountId);
                return output;
            }

            output.put('success', false);
            output.put('message', 'Método no soportado: ' + action);
            return output;

        } catch (Exception e) {
            output.put('success', false);
            output.put('message', e.getMessage());
            return output;
        }
    }

    global static Id extractAccountId(Map<String, Object> input) {
        if (input == null) return null;

        for (String key : new List<String>{'accountId','ContextId','contextId','Id','id'}) {
            if (input.containsKey(key) && input.get(key) != null) {
                String rawValue = String.valueOf(input.get(key)).trim();
                if (!String.isBlank(rawValue)) {
                    try {
                        return (Id) rawValue;
                    } catch (Exception ex) {}
                }
            }
        }
        return null;
    }
}