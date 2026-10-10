@IsTest
private class FSC_BancaSeguroRoutingTest {
	private static final String SUBESTADO_GENERACION = 'Generación de pagarés y plantillas';

	@IsTest
	static void vehiculoPendienteSeEnrutaABancaSeguro() {
		ResidentialLoanApplication solicitud = nuevaSolicitud('FSC_Solicitud_Credito_Vehiculo', false);

		FSC_DocumentacionContratosService.encaminarEntradas(
			new List<ResidentialLoanApplication>{ solicitud },
			new Map<Id, ResidentialLoanApplication>()
		);

		System.assertEquals('Banca Seguro', solicitud.FSC_Subestado__c);
	}

	@IsTest
	static void hipotecarioPendienteSeEnrutaABancaSeguro() {
		ResidentialLoanApplication solicitud = nuevaSolicitud('FSC_Solicitud_Credito_Hipotecario', false);

		FSC_DocumentacionContratosService.encaminarEntradas(
			new List<ResidentialLoanApplication>{ solicitud },
			new Map<Id, ResidentialLoanApplication>()
		);

		System.assertEquals('Banca Seguro', solicitud.FSC_Subestado__c);
	}

	@IsTest
	static void consumoNoIngresaABancaSeguro() {
		ResidentialLoanApplication solicitud = nuevaSolicitud('FSC_Solicitud_Credito_Consumo', false);

		FSC_DocumentacionContratosService.encaminarEntradas(
			new List<ResidentialLoanApplication>{ solicitud },
			new Map<Id, ResidentialLoanApplication>()
		);

		System.assertNotEquals('Banca Seguro', solicitud.FSC_Subestado__c);
	}

	@IsTest
	static void vehiculoYaAprobadoNoReingresaABancaSeguro() {
		ResidentialLoanApplication solicitud = nuevaSolicitud('FSC_Solicitud_Credito_Vehiculo', true);

		FSC_DocumentacionContratosService.encaminarEntradas(
			new List<ResidentialLoanApplication>{ solicitud },
			new Map<Id, ResidentialLoanApplication>()
		);

		System.assertNotEquals('Banca Seguro', solicitud.FSC_Subestado__c);
	}

	@IsTest
	static void salidaDeBancaSeguroNoReingresaAunqueElIndicadorSeActualiceDespues() {
		ResidentialLoanApplication solicitud = nuevaSolicitud('FSC_Solicitud_Credito_Vehiculo', false);
		ResidentialLoanApplication anterior = nuevaSolicitud('FSC_Solicitud_Credito_Vehiculo', false);
		Id solicitudId = Id.valueOf(Schema.SObjectType.ResidentialLoanApplication.getKeyPrefix() + '000000000001');
		solicitud.Id = solicitudId;
		anterior.Id = solicitudId;
		anterior.FSC_Subestado__c = 'Banca Seguro';

		FSC_DocumentacionContratosService.encaminarEntradas(
			new List<ResidentialLoanApplication>{ solicitud },
			new Map<Id, ResidentialLoanApplication>{ solicitudId => anterior }
		);

		System.assertNotEquals('Banca Seguro', solicitud.FSC_Subestado__c);
	}

	@IsTest
	static void enrutaSolicitudesEnLote() {
		List<ResidentialLoanApplication> solicitudes = new List<ResidentialLoanApplication>();
		for (Integer index = 0; index < 251; index++) {
			solicitudes.add(nuevaSolicitud(Math.mod(index, 2) == 0 ? 'FSC_Solicitud_Credito_Vehiculo' : 'FSC_Solicitud_Credito_Hipotecario', false));
		}

		FSC_DocumentacionContratosService.encaminarEntradas(solicitudes, new Map<Id, ResidentialLoanApplication>());

		for (ResidentialLoanApplication solicitud : solicitudes) {
			System.assertEquals('Banca Seguro', solicitud.FSC_Subestado__c);
		}
	}

	@IsTest
	static void rechazoBancaSeguroValidaEntradasObligatorias() {
		Id solicitudId = Id.valueOf(Schema.SObjectType.ResidentialLoanApplication.getKeyPrefix() + '000000000001');

		assertAuraHandledException(null, 'Motivo', 'Comentario');
		assertAuraHandledException(solicitudId, '', 'Comentario');
		assertAuraHandledException(solicitudId, 'Motivo', '');
		assertAuraHandledException(solicitudId, repeatedString(256), 'Comentario');
		assertAuraHandledException(solicitudId, 'Motivo', repeatedString(2001));
	}

	private static void assertAuraHandledException(Id solicitudId, String motivo, String comentario) {
		try {
			FSC_RlaAccionesController.rechazarBancaSeguro(solicitudId, motivo, comentario);
			Assert.fail('Se esperaba AuraHandledException por entrada inválida.');
		} catch (AuraHandledException expected) {
			Assert.isNotNull(expected);
		}
	}

	private static String repeatedString(Integer length) {
		String result = '';
		for (Integer index = 0; index < length; index++) {
			result += 'x';
		}
		return result;
	}

	private static ResidentialLoanApplication nuevaSolicitud(String recordTypeDeveloperName, Boolean aprobadaBancaSeguro) {
		return new ResidentialLoanApplication(
			Status = 'En proceso',
			FSC_Subestado__c = SUBESTADO_GENERACION,
			FSC_BancaSeguroAprobada__c = aprobadaBancaSeguro,
			RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
				.get(recordTypeDeveloperName)
				.getRecordTypeId()
		);
	}
}