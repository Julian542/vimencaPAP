global with sharing class FSC_ShowDynamicFieldsOmniController implements System.Callable {
    global Object call(String action, Map<String, Object> args) {
        Map<String, Object> inputMap = normalizeInput(args == null ? null : args.get('input'));
        Map<String, Object> outputMap = args == null ? null : (Map<String, Object>) args.get('output');

        if (outputMap == null) {
            outputMap = new Map<String, Object>();
        }

        if (action == 'getUserSucursalLabel') {
            String sucursalValue = firstNonBlankValue(new List<Object>{
                inputMap.get('sucursalValue'),
                inputMap.get('sucursalUsuario'),
                inputMap.get('FSC_Sucursal__c')
            });

            outputMap.put('value', String.isBlank(sucursalValue) ? null : sucursalValue.trim());
            outputMap.put('label', getUserSucursalLabel(sucursalValue));
            return outputMap;
        }

        outputMap.put('success', false);
        outputMap.put('message', 'Unknown method: ' + action);
        return outputMap;
    }

    public static String getUserSucursalLabel(String sucursalValue) {
        if (String.isBlank(sucursalValue)) {
            return null;
        }

        String normalizedValue = sucursalValue.trim();
        Schema.DescribeFieldResult fieldDescribe = User.FSC_Sucursal__c.getDescribe();

        for (Schema.PicklistEntry picklistEntry : fieldDescribe.getPicklistValues()) {
            if (picklistEntry.getValue() == normalizedValue) {
                return picklistEntry.getLabel();
            }
        }

        return normalizedValue;
    }

    private static Map<String, Object> normalizeInput(Object input) {
        if (input == null) {
            return new Map<String, Object>();
        }

        if (input instanceof Map<String, Object>) {
            return (Map<String, Object>) input;
        }

        if (input instanceof String && String.isNotBlank((String) input)) {
            Object deserializedInput = JSON.deserializeUntyped((String) input);
            if (deserializedInput instanceof Map<String, Object>) {
                return (Map<String, Object>) deserializedInput;
            }
        }

        return new Map<String, Object>();
    }

    private static String firstNonBlankValue(List<Object> values) {
        for (Object value : values) {
            if (value != null && String.isNotBlank(String.valueOf(value))) {
                return String.valueOf(value);
            }
        }

        return null;
    }
}