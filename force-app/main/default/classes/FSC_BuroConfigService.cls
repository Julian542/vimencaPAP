public with sharing class FSC_BuroConfigService {
	public static final String RESULTADO_REFERIDO = 'Referido';
	public static final String SUBESTADO_REFERIDO = 'Recepción de documentos – Análisis';
	public static final String MENSAJE_MOTOR_APAGADO =
		'El motor de buró se encuentra apagado para este tipo de crédito, por lo tanto devuelve Referido automáticamente y avanza al siguiente subestado.';

	private static final Map<String, String> CONFIG_BY_RECORD_TYPE = new Map<String, String>{
		'FSC_Solicitud_Credito_Consumo' => 'URL',
		'FSC_Solicitud_Credito_Vehiculo' => 'URLVehicular',
		'FSC_Solicitud_Credito_Hipotecario' => 'URLHipotecario',
		'FSC_Solicitud_Credito_PYME' => 'PYME'
	};
	@TestVisible private static Set<String> motoresApagadosEnPrueba = new Set<String>();

	public static Boolean isMotorEncendido(String recordTypeDeveloperName) {
		if (Test.isRunningTest() && motoresApagadosEnPrueba.contains(recordTypeDeveloperName)) return false;
		String configDeveloperName = CONFIG_BY_RECORD_TYPE.get(recordTypeDeveloperName);
		if (String.isBlank(configDeveloperName)) {
			return true;
		}

		ConfigLoanDecisionAPI__mdt config = ConfigLoanDecisionAPI__mdt.getInstance(configDeveloperName);
		return config == null || config.Encendido__c != false;
	}

	public static void aplicarMotorApagado(ResidentialLoanApplication solicitud) {
		if (solicitud == null) {
			return;
		}

		solicitud.FSC_Resultado_Buro__c = RESULTADO_REFERIDO;
		solicitud.FSC_Subestado__c = SUBESTADO_REFERIDO;
		solicitud.FSC_Mensajes_Buro__c = MENSAJE_MOTOR_APAGADO;
	}
}