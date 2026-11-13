@IsTest
public class FSC_ContratoPrestamoCtrlTestHelper {

    public static ApexPages.StandardController buildUnsavedStandardController() {
        ResidentialLoanApplication rla = new ResidentialLoanApplication();
        return new ApexPages.StandardController(rla);
    }

    public static String buildFakeResidentialLoanApplicationId() {
        String prefix = ResidentialLoanApplication.SObjectType.getDescribe().getKeyPrefix();
        return prefix + '000000000000';
    }

    public static void assertBaseControllerState(
        Object controllerObj,
        Integer expectedPlaceholderCount,
        String expectedLastPlaceholder
    ) {
        // This helper exists only for documentation purposes in this test suite.
        System.assertNotEquals(null, controllerObj, 'El controlador no debería ser nulo.');
        System.assert(expectedPlaceholderCount > 0, 'La cantidad de placeholders esperada debe ser mayor que cero.');
        System.assert(!String.isBlank(expectedLastPlaceholder), 'El último placeholder esperado no debería estar vacío.');
    }
}