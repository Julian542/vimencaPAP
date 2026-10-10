@IsTest
private class FSC_APIPrestamoDesembolsoTest {
	private class RespuestaHttp implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			Assert.areEqual(FSC_APIPrestamoConfig__mdt.getInstance('Default').FSC_ApiKey__c, request.getHeader('X-API-KEY'), 'El desembolso debe enviar la API key configurada en FSC_APIPrestamoConfig__mdt.');
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"StatusCode":200}');
			return response;
		}
	}

	@IsTest
	static void run_ejecutaRutaHttpRealConMock() {
		ResidentialLoanApplication rla = createRla();
		createDebtor(rla.Id);
		Test.setMock(HttpCalloutMock.class, new RespuestaHttp());
		Test.startTest();
		FSC_APIPrestamoDesembolso.Input entrada = new FSC_APIPrestamoDesembolso.Input();
		entrada.residentialLoanApplicationId = rla.Id;
		entrada.codigoUsuario = 'FLOWUSR';
		List<FSC_APIPrestamoDesembolso.Output> salidas = FSC_APIPrestamoDesembolso.run(
			new List<FSC_APIPrestamoDesembolso.Input>{ entrada });
		Test.stopTest();
		System.assertEquals(1, salidas.size());
		System.assertEquals(true, salidas[0].success);
	}

	@IsTest
	static void run_updatesRlaWhenStatusCodeIs200() {
		ResidentialLoanApplication rla = createRla();
		createDebtor(rla.Id);
		update new ResidentialLoanApplication(Id = rla.Id, FSC_FlagErrorAPIDesembolso__c = true);

		FSC_APIPrestamoDesembolso.mockIpResponse = new Map<String, Object>{ 'HTTPDesembolso' => new Map<String, Object>{ 'StatusCode' => 200 } };

		FSC_APIPrestamoDesembolso.Input inputItem = new FSC_APIPrestamoDesembolso.Input();
		inputItem.residentialLoanApplicationId = rla.Id;
		inputItem.codigoUsuario = 'FLOWUSR';

		Test.startTest();
		List<FSC_APIPrestamoDesembolso.Output> outputs = FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{ inputItem });
		Test.stopTest();

		System.assertEquals(1, outputs.size());
		System.assertEquals(true, outputs[0].success);
		System.assertEquals(200, outputs[0].statusCode);
		System.assert(outputs[0].ipInput.contains('"bodyRequest"'));

		ResidentialLoanApplication refreshed = [
			SELECT FSC_Subestado__c, FSC_FlagErrorAPIDesembolso__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertEquals('Archivo y custodia', refreshed.FSC_Subestado__c);
		System.assertEquals(false, refreshed.FSC_FlagErrorAPIDesembolso__c);

		Map<String, Object> ipInput = FSC_APIPrestamoDesembolso.lastIpInput;
		Map<String, Object> bodyRequest = (Map<String, Object>) ipInput.get('bodyRequest');
		Map<String, Object> desembolso = (Map<String, Object>) bodyRequest.get('desembolso');

		System.assertEquals('FLOWUSR', bodyRequest.get('codigoUsuario'));
		System.assertEquals(Decimal.valueOf('54252'), desembolso.get('numeroPrestamo'));
		System.assertEquals(Decimal.valueOf('1'), desembolso.get('codigoTipoIdentificacion'));
		System.assertEquals('001-0880361-0', desembolso.get('numeroIdentificacion'));
		System.assertEquals('BCA', desembolso.get('codigoAplicacion'));
		System.assertEquals(Decimal.valueOf('1'), desembolso.get('codigoAgencia'));
		System.assertEquals(Decimal.valueOf('204'), desembolso.get('codigoSubAplicacion'));
		System.assertEquals(Decimal.valueOf('102083476'), desembolso.get('numeroCuenta'));
	}

	@IsTest
	static void run_setsErrorFlagWhenStatusCodeIsNot200() {
		ResidentialLoanApplication rla = createRla();
		createDebtor(rla.Id);

		FSC_APIPrestamoDesembolso.mockIpResponse = new Map<String, Object>{ 'StatusCode' => 500 };

		FSC_APIPrestamoDesembolso.Input inputItem = new FSC_APIPrestamoDesembolso.Input();
		inputItem.residentialLoanApplicationId = rla.Id;
		inputItem.codigoUsuario = 'FLOWUSR';

		Test.startTest();
		List<FSC_APIPrestamoDesembolso.Output> outputs = FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{ inputItem });
		Test.stopTest();

		System.assertEquals(1, outputs.size());
		System.assertEquals(false, outputs[0].success);
		System.assertEquals(500, outputs[0].statusCode);

		ResidentialLoanApplication refreshed = [
			SELECT FSC_Subestado__c, FSC_FlagErrorAPIDesembolso__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertNotEquals('Archivo y custodia', refreshed.FSC_Subestado__c);
		System.assertEquals(true, refreshed.FSC_FlagErrorAPIDesembolso__c);
	}

	@IsTest
	static void run_returnsErrorWhenRequiredDataIsMissing() {
		ResidentialLoanApplication rla = createRla();

		FSC_APIPrestamoDesembolso.Input inputItem = new FSC_APIPrestamoDesembolso.Input();
		inputItem.residentialLoanApplicationId = rla.Id;
		inputItem.codigoUsuario = 'FLOWUSR';

		Test.startTest();
		List<FSC_APIPrestamoDesembolso.Output> outputs = FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{ inputItem });
		Test.stopTest();

		System.assertEquals(1, outputs.size());
		System.assertEquals(false, outputs[0].success);
		System.assert(outputs[0].message.contains('LoanApplicant Deudor'));

		ResidentialLoanApplication refreshed = [
			SELECT FSC_FlagErrorAPIDesembolso__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertEquals(true, refreshed.FSC_FlagErrorAPIDesembolso__c);
	}

	private static ResidentialLoanApplication createRla() {
		Account account = new Account(Name = 'Cliente Desembolso');
		insert account;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Desembolso',
			AccountId = account.Id,
			RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
				.get('FSC_Solicitud_Credito_Consumo')
				.getRecordTypeId(),
			Status = 'En proceso',
			FSC_Subestado__c = 'Desembolso',
				FSC_TipoSolicitud__c = 'BPR',
			FSC_NumeroPrestamoAbanks__c = '54252',
			FSC_CodigoAprobacion__c = 'BCA',
			FSC_Grupo_de_Empresa__c = '1',
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '204',
			FSC_NumeroCuentaDesembolso__c = '102083476'
		);
		insert rla;
		return rla;
	}

	private static void createDebtor(Id rlaId) {
		LoanApplicant debtor = new LoanApplicant(
			Name = 'Cliente Deudor',
			LoanApplicationId = rlaId,
			FSC_TipoSolicitante__c = 'Deudor',
			FSC_TipoIdentificacion__c = 'Cédula',
			FSC_NumIdentificacion__c = '001-0880361-0',
			FSC_Nombre__c = 'Cliente Deudor'
		);
		insert debtor;
	}
}