@IsTest
private class FSC_RoleAuthorizationServiceTest {
	@IsTest
	static void shouldAuthorizeAssignedUserWithPagaresPermission() {
		FSC_RoleAuthorizationService.testAdministratorPermission = false;
		FSC_RoleAuthorizationService.testPagaresPermission = true;

		Test.startTest();
		Boolean isAuthorized = FSC_RoleAuthorizationService.canManagePagares(UserInfo.getUserId());
		Test.stopTest();

		Assert.isTrue(isAuthorized, 'The assigned user with the pagares permission should be authorized.');
	}

	@IsTest
	static void shouldRejectAssignedUserWithoutPagaresPermission() {
		FSC_RoleAuthorizationService.testAdministratorPermission = false;
		FSC_RoleAuthorizationService.testPagaresPermission = false;

		Test.startTest();
		Boolean isAuthorized = FSC_RoleAuthorizationService.canManagePagares(UserInfo.getUserId());
		Test.stopTest();

		Assert.isFalse(isAuthorized, 'Assignment alone must not authorize pagares actions.');
	}

	@IsTest
	static void shouldRejectUnassignedUserWithDisbursementPermission() {
		FSC_RoleAuthorizationService.testAdministratorPermission = false;
		FSC_RoleAuthorizationService.testDisbursementPermission = true;

		Test.startTest();
		Boolean isAuthorized = FSC_RoleAuthorizationService.canManageDisbursement(null);
		Test.stopTest();

		Assert.isFalse(isAuthorized, 'The disbursement permission must not bypass assignment.');
	}

	@IsTest
	static void shouldAuthorizeAdministratorWithoutAssignment() {
		FSC_RoleAuthorizationService.testAdministratorPermission = true;
		FSC_RoleAuthorizationService.testPagaresPermission = false;
		FSC_RoleAuthorizationService.testDisbursementPermission = false;

		Test.startTest();
		Boolean canManagePagares = FSC_RoleAuthorizationService.canManagePagares(null);
		Boolean canManageDisbursement = FSC_RoleAuthorizationService.canManageDisbursement(null);
		Test.stopTest();

		Assert.isTrue(canManagePagares, 'An administrator should bypass pagares assignment.');
		Assert.isTrue(canManageDisbursement, 'An administrator should bypass disbursement assignment.');
	}
}