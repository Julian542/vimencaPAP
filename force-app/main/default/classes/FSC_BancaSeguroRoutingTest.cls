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
	static void simpleNotesSkipManualReviewInBulk() {
		List<ResidentialLoanApplication> applications = new List<ResidentialLoanApplication>();
		for (Integer index = 1; index <= 251; index++) {
			ResidentialLoanApplication application = nuevaSolicitud('FSC_Solicitud_Credito_Consumo', false);
			application.Id = Id.valueOf(Schema.SObjectType.ResidentialLoanApplication.getKeyPrefix() + String.valueOf(index).leftPad(12, '0'));
			application.FSC_Monto__c = 2000000;
			applications.add(application);
		}
		Test.startTest();
		FSC_DocumentacionContratosService.encaminarEntradas(applications, null);
		Integer queryCount = Limits.getQueries();
		Test.stopTest();
		for (ResidentialLoanApplication application : applications)
			Assert.areEqual('Generación de contrato', application.FSC_Subestado__c, 'El simple debe saltar la revisión manual.');
		Assert.areEqual(2, queryCount, 'Se deben consultar garantías y garantes una vez para todo el lote.');
	}

	@IsTest
	static void notarialAndComplementaryKeepManualReview() {
		ResidentialLoanApplication notarial = nuevaSolicitud('FSC_Solicitud_Credito_Consumo', false);
		notarial.Id = Id.valueOf(Schema.SObjectType.ResidentialLoanApplication.getKeyPrefix() + '000000000001');
		notarial.FSC_Monto__c = 2000001;
		ResidentialLoanApplication complementary = nuevaSolicitud('FSC_Solicitud_Credito_Consumo', false);
		complementary.Id = Id.valueOf(Schema.SObjectType.ResidentialLoanApplication.getKeyPrefix() + '000000000002');
		complementary.FSC_Tipo_de_Garantia__c = 'CERTIFICADO DE DEPOSITO';
		ResidentialLoanApplication explicitNotarial = nuevaSolicitud('FSC_Solicitud_Credito_Consumo', false);
		explicitNotarial.Id = Id.valueOf(Schema.SObjectType.ResidentialLoanApplication.getKeyPrefix() + '000000000003');
		explicitNotarial.FSC_RequiereContratoPagareNotarial__c = true;
		Test.startTest();
		FSC_DocumentacionContratosService.encaminarEntradas(new List<ResidentialLoanApplication>{ notarial, complementary, explicitNotarial }, null);
		Test.stopTest();
		Assert.areEqual(SUBESTADO_GENERACION, notarial.FSC_Subestado__c, 'El notarial por monto conserva la revisión.');
		Assert.areEqual(SUBESTADO_GENERACION, complementary.FSC_Subestado__c, 'El complementario conserva la revisión.');
		Assert.areEqual(SUBESTADO_GENERACION, explicitNotarial.FSC_Subestado__c, 'El notarial explícito conserva la revisión.');
	}

	@IsTest
	static void simpleNoteLeavingDocumentationSkipsManualReview() {
		ResidentialLoanApplication application = nuevaSolicitud('FSC_Solicitud_Credito_Consumo', false);
		application.Id = Id.valueOf(Schema.SObjectType.ResidentialLoanApplication.getKeyPrefix() + '000000000001');
		ResidentialLoanApplication previous = application.clone(true);
		previous.FSC_Subestado__c = FSC_DocumentacionContratosService.SUBESTADO_CARGA;
		Test.startTest();
		FSC_DocumentacionContratosService.encaminarEntradas(
			new List<ResidentialLoanApplication>{ application },
			new Map<Id, ResidentialLoanApplication>{ application.Id => previous }
		);
		Test.stopTest();
		Assert.areEqual('Generación de contrato', application.FSC_Subestado__c, 'La salida de documentación también debe automatizarse.');
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