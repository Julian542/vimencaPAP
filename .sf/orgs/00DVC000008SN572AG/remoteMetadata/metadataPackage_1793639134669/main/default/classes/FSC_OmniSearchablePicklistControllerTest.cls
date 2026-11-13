@IsTest
private class FSC_OmniSearchablePicklistControllerTest {
	@IsTest
	static void getReferidorOptionsReturnsMetadataOptions() {
		Test.startTest();
		List<FSC_OmniSearchablePicklistController.OptionDTO> options = FSC_OmniSearchablePicklistController.getReferidorOptions();
		Test.stopTest();

		System.assertNotEquals(null, options, 'Debe devolver una lista, aunque no existan registros.');
		for (FSC_OmniSearchablePicklistController.OptionDTO option : options) {
			System.assert(!String.isBlank(option.label), 'El label no debe estar vacio.');
			System.assertEquals(option.label, option.value, 'El valor guardado debe ser el nombre del referidor.');
		}
	}
}