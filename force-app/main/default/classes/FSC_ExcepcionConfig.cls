public inherited sharing class FSC_ExcepcionConfig {
	private static final Integer DEFAULT_MAXIMO_EXCEPCIONES = 3;
	private static final String CONFIGURACION_GLOBAL = 'FSC_Limite_Global';

	@TestVisible
	private static Decimal testMaximoExcepciones;

	public static Integer getMaximoExcepciones() {
		Decimal valorConfigurado = Test.isRunningTest() && testMaximoExcepciones != null
			? testMaximoExcepciones
			: FSC_Configuracion_Excepciones__mdt.getInstance(CONFIGURACION_GLOBAL)?.FSC_Maximo_Excepciones__c;
		return valorConfigurado == null || valorConfigurado < 1 ? DEFAULT_MAXIMO_EXCEPCIONES : valorConfigurado.intValue();
	}

	public static String getMensajeLimite() {
		return 'Se ha alcanzado el límite máximo de ' + getMaximoExcepciones() + ' excepciones para esta solicitud.';
	}
}