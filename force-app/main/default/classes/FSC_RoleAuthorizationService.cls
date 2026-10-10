public inherited sharing class FSC_RoleAuthorizationService {
	private static final String ADMINISTRATOR_PERMISSION = 'FSC_CP_Administrador';
	private static final String PAGARES_PERMISSION = 'FSC_CP_Generacion_Pagares_Contratos';
	private static final String DISBURSEMENT_PERMISSION = 'FSC_CP_Desembolso_Creditos';

	@TestVisible
	private static Boolean testAdministratorPermission;
	@TestVisible
	private static Boolean testPagaresPermission = Test.isRunningTest() ? true : null;
	@TestVisible
	private static Boolean testDisbursementPermission = Test.isRunningTest() ? true : null;

	public static Boolean canManagePagares(Id assignedUserId) {
		return hasPermission(ADMINISTRATOR_PERMISSION, testAdministratorPermission) ||
			(assignedUserId == UserInfo.getUserId() && hasPermission(PAGARES_PERMISSION, testPagaresPermission));
	}

	public static Boolean canManageDisbursement(Id assignedUserId) {
		return hasPermission(ADMINISTRATOR_PERMISSION, testAdministratorPermission) ||
			(assignedUserId == UserInfo.getUserId() && hasPermission(DISBURSEMENT_PERMISSION, testDisbursementPermission));
	}

	private static Boolean hasPermission(String permissionName, Boolean testPermission) {
		if (Test.isRunningTest() && testPermission != null) {
			return testPermission;
		}
		return FeatureManagement.checkPermission(permissionName);
	}
}