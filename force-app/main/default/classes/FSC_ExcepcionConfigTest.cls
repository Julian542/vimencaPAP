@IsTest
private class FSC_ExcepcionConfigTest {
	@IsTest
	static void shouldReadGlobalMetadataWhenConfigurationExists() {
		FSC_Configuracion_Excepciones__mdt configuracion = FSC_Configuracion_Excepciones__mdt.getInstance('FSC_Limite_Global');

		Assert.isNotNull(configuracion, 'El registro global debe viajar con la solución.');
		Assert.areEqual(3, FSC_ExcepcionConfig.getMaximoExcepciones(), 'Debe leer el valor inicial desde Custom Metadata.');
		Assert.areEqual(
			'Se ha alcanzado el límite máximo de 3 excepciones para esta solicitud.',
			FSC_ExcepcionConfig.getMensajeLimite(),
			'El mensaje Apex debe incluir el valor vigente.'
		);
	}

	@IsTest
	static void shouldUseSafeDefaultWhenConfiguredValueIsInvalid() {
		FSC_ExcepcionConfig.testMaximoExcepciones = 0;

		Assert.areEqual(3, FSC_ExcepcionConfig.getMaximoExcepciones(), 'Un valor no positivo no debe desactivar el límite.');
	}

	@IsTest
	static void shouldExposeConfiguredValueWhenMetadataChanges() {
		FSC_ExcepcionConfig.testMaximoExcepciones = 7;

		Assert.areEqual(7, FSC_ExcepcionConfig.getMaximoExcepciones(), 'Los consumidores deben recibir el valor configurable.');
		Assert.isTrue(FSC_ExcepcionConfig.getMensajeLimite().contains('7 excepciones'), 'El mensaje debe adaptarse al valor.');
	}
}