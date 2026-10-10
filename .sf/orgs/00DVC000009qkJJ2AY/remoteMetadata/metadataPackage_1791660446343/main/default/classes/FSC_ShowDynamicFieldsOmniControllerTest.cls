@IsTest
private class FSC_ShowDynamicFieldsOmniControllerTest {
    @IsTest
    static void returnsPicklistLabelForKnownSucursalValue() {
        Schema.PicklistEntry firstActiveValue = getFirstActiveSucursalValue();
        System.assertNotEquals(null, firstActiveValue, 'User.FSC_Sucursal__c debe tener al menos un valor activo.');

        Test.startTest();
        String label = FSC_ShowDynamicFieldsOmniController.getUserSucursalLabel(firstActiveValue.getValue());
        Test.stopTest();

        System.assertEquals(firstActiveValue.getLabel(), label);
    }

    @IsTest
    static void callableReturnsPicklistLabelForJsonInput() {
        Schema.PicklistEntry firstActiveValue = getFirstActiveSucursalValue();
        System.assertNotEquals(null, firstActiveValue, 'User.FSC_Sucursal__c debe tener al menos un valor activo.');

        Map<String, Object> args = new Map<String, Object>{
            'input' => JSON.serialize(new Map<String, Object>{
                'sucursalValue' => firstActiveValue.getValue()
            }),
            'output' => new Map<String, Object>(),
            'options' => new Map<String, Object>()
        };

        Test.startTest();
        Map<String, Object> output = (Map<String, Object>) new FSC_ShowDynamicFieldsOmniController()
            .call('getUserSucursalLabel', args);
        Test.stopTest();

        System.assertEquals(firstActiveValue.getValue(), output.get('value'));
        System.assertEquals(firstActiveValue.getLabel(), output.get('label'));
    }

    @IsTest
    static void returnsOriginalValueWhenSucursalValueIsUnknown() {
        Test.startTest();
        String label = FSC_ShowDynamicFieldsOmniController.getUserSucursalLabel('UNKNOWN_VALUE');
        Test.stopTest();

        System.assertEquals('UNKNOWN_VALUE', label);
    }

    @IsTest
    static void returnsNullWhenSucursalValueIsBlank() {
        Test.startTest();
        String label = FSC_ShowDynamicFieldsOmniController.getUserSucursalLabel(' ');
        Test.stopTest();

        System.assertEquals(null, label);
    }

    private static Schema.PicklistEntry getFirstActiveSucursalValue() {
        for (Schema.PicklistEntry picklistEntry : User.FSC_Sucursal__c.getDescribe().getPicklistValues()) {
            if (picklistEntry.isActive()) {
                return picklistEntry;
            }
        }

        return null;
    }
}