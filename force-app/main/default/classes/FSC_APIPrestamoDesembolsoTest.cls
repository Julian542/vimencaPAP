@IsTest
private class FSC_APIPrestamoDesembolsoTest {
	private static final String NUMERO_CUENTA = '102083476';
	private static Integer llamadasDesembolso = 0;

	private class RespuestaHttp implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			llamadasDesembolso++;
			Assert.areEqual(FSC_APIPrestamoConfig__mdt.getInstance('Default').FSC_ApiKey__c, request.getHeader('X-API-KEY'), 'El desembolso debe enviar la API key configurada en FSC_APIPrestamoConfig__mdt.');
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"codigoRespuesta":"00","descripcionRespuesta":"Exitoso","descripcionTecnica":null,"numeroSecuencia":1}');
			return response;
		}
	}

	@IsTest
	static void run_ejecutaRutaHttpRealConMock() {
		ResidentialLoanApplication rla = createRla();
		createDebtor(rla.Id);
		Test.setMock(HttpCalloutMock.class, new RespuestaHttp());
		Test.startTest();
		List<FSC_APIPrestamoDesembolso.Output> salidas = FSC_APIPrestamoDesembolso.run(
			new List<FSC_APIPrestamoDesembolso.Input>{ buildInput(rla.Id) });
		Test.stopTest();
		System.assertEquals(1, salidas.size());
		System.assertEquals(true, salidas[0].success, salidas[0].message);
	}

	@IsTest
	static void run_updatesRlaWhenDescripcionIsExitoso() {
		ResidentialLoanApplication rla = createRla();
		createDebtor(rla.Id);
		update new ResidentialLoanApplication(Id = rla.Id, FSC_FlagErrorAPIDesembolso__c = true);
		FSC_APIPrestamoDesembolso.mockIpResponse = new Map<String, Object>{
			'HTTPDesembolso' => new Map<String, Object>{ 'StatusCode' => 200, 'descripcionRespuesta' => 'Exitoso' }
		};
		Test.startTest();
		List<FSC_APIPrestamoDesembolso.Output> outputs = FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{ buildInput(rla.Id) });
		Test.stopTest();
		ResidentialLoanApplication resultado = [
			SELECT FSC_Subestado__c, FSC_DesembolsoAPIExitoso__c, FSC_EvidenciasDesembolsoCargadas__c, FSC_FlagErrorAPIDesembolso__c
			FROM ResidentialLoanApplication WHERE Id = :rla.Id WITH SYSTEM_MODE
		];
		System.assertEquals(true, outputs[0].success, outputs[0].message);
		System.assertEquals('Desembolso', resultado.FSC_Subestado__c);
		System.assert(resultado.FSC_DesembolsoAPIExitoso__c && !resultado.FSC_EvidenciasDesembolsoCargadas__c && !resultado.FSC_FlagErrorAPIDesembolso__c);
	}

	@IsTest
	static void run_usesCheckingAccountProduct() {
		ResidentialLoanApplication rla = createRla('CheckingAccount', 'BCC', '118');
		createDebtor(rla.Id);
		FSC_APIPrestamoDesembolso.mockIpResponse = new Map<String, Object>{ 'StatusCode' => 200, 'descripcionRespuesta' => 'Exitoso' };

		Test.startTest();
		List<FSC_APIPrestamoDesembolso.Output> outputs = FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{ buildInput(rla.Id) });
		Test.stopTest();

		System.assertEquals(true, outputs[0].success, outputs[0].message);
		Map<String, Object> desembolso = (Map<String, Object>) ((Map<String, Object>) FSC_APIPrestamoDesembolso.lastIpInput.get('bodyRequest')).get('desembolso');
		System.assertEquals('BCC', desembolso.get('codigoAplicacion'), 'Una cuenta corriente debe enviarse como BCC.');
		System.assertEquals(Decimal.valueOf('118'), desembolso.get('codigoSubAplicacion'));
	}

	@IsTest
	static void run_setsErrorFlagWhenApiReturns200WithBusinessError() {
		ResidentialLoanApplication rla = createRla();
		createDebtor(rla.Id);

		// Respuesta real del API: HTTP 200 aunque el desembolso no se haya hecho.
		FSC_APIPrestamoDesembolso.mockIpResponse = new Map<String, Object>{
			'StatusCode' => 200,
			'body' => '{"codigoRespuesta":"99","descripcionRespuesta":"Cuenta de  Ahorros No existe.","descripcionTecnica":null,"numeroSecuencia":null}'
		};

		Test.startTest();
		List<FSC_APIPrestamoDesembolso.Output> outputs = FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{ buildInput(rla.Id) });
		Test.stopTest();

		System.assertEquals(false, outputs[0].success);
		System.assert(outputs[0].message.contains('Cuenta de  Ahorros No existe.'), outputs[0].message);

		ResidentialLoanApplication refreshed = [
			SELECT FSC_Subestado__c, FSC_FlagErrorAPIDesembolso__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertEquals('Desembolso', refreshed.FSC_Subestado__c, 'No debe pasar a Archivo y custodia.');
		System.assertEquals(true, refreshed.FSC_FlagErrorAPIDesembolso__c);
	}

	@IsTest
	static void run_setsErrorFlagWhenStatusCodeIsNot200() {
		ResidentialLoanApplication rla = createRla();
		createDebtor(rla.Id);

		FSC_APIPrestamoDesembolso.mockIpResponse = new Map<String, Object>{ 'StatusCode' => 500 };

		Test.startTest();
		List<FSC_APIPrestamoDesembolso.Output> outputs = FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{ buildInput(rla.Id) });
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

		Test.startTest();
		List<FSC_APIPrestamoDesembolso.Output> outputs = FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{ buildInput(rla.Id) });
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

	@IsTest
	static void run_failsWhenAccountDoesNotBelongToClient() {
		ResidentialLoanApplication rla = createRla();
		createDebtor(rla.Id);
		Account otroCliente = new Account(Name = 'Otro cliente');
		insert otroCliente;
		// La cuenta elegida existe, pero pertenece a otro cliente.
		insert new FinServ__FinancialAccount__c(
			Name = 'Cuenta ajena',
			FinServ__FinancialAccountNumber__c = '555000111',
			FinServ__PrimaryOwner__c = otroCliente.Id,
			RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName()
				.get('SavingsAccount')
				.getRecordTypeId()
		);
		update new ResidentialLoanApplication(Id = rla.Id, FSC_NumeroCuentaDesembolso__c = '555000111');
		FSC_APIPrestamoDesembolso.mockIpResponse = new Map<String, Object>{ 'StatusCode' => 200, 'descripcionRespuesta' => 'Exitoso' };

		Test.startTest();
		List<FSC_APIPrestamoDesembolso.Output> outputs = FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{ buildInput(rla.Id) });
		Test.stopTest();

		System.assertEquals(false, outputs[0].success);
		System.assert(outputs[0].message.contains('no se encontro entre las cuentas'), outputs[0].message);
		System.assertEquals(null, FSC_APIPrestamoDesembolso.lastIpInput, 'No debe llamar al API.');
	}

	@IsTest
	static void run_doesNotDisburseOutsideDesembolsoOrTwice() {
		ResidentialLoanApplication rla = createRla();
		createDebtor(rla.Id);
		Test.setMock(HttpCalloutMock.class, new RespuestaHttp());
		Test.startTest();
		List<FSC_APIPrestamoDesembolso.Output> outputs = FSC_APIPrestamoDesembolso.run(
			new List<FSC_APIPrestamoDesembolso.Input>{ buildInput(rla.Id), buildInput(rla.Id) }
		);
		List<FSC_APIPrestamoDesembolso.Output> secondRun = FSC_APIPrestamoDesembolso.run(
			new List<FSC_APIPrestamoDesembolso.Input>{ buildInput(rla.Id) }
		);
		Test.stopTest();
		System.assertEquals(true, outputs[0].success, outputs[0].message);
		System.assert(!outputs[1].success && !secondRun[0].success && secondRun[0].message.contains('ya se realizó'));
		System.assertEquals(1, llamadasDesembolso);
	}

	@IsTest
	static void run_usesCurrentUserAbanksCodeOrAlias() {
		ResidentialLoanApplication rla = createRla();
		createDebtor(rla.Id);
		FSC_APIPrestamoDesembolso.mockIpResponse = new Map<String, Object>{ 'StatusCode' => 200, 'descripcionRespuesta' => 'Exitoso' };
		FSC_APIPrestamoDesembolso.Input inputItem = buildInput(rla.Id);
		inputItem.codigoUsuario = null;
		User currentUser = [SELECT FSC_CodigoAbanks__c, Alias FROM User WHERE Id = :UserInfo.getUserId()];
		String expectedCode = String.isBlank(currentUser.FSC_CodigoAbanks__c) ? currentUser.Alias : currentUser.FSC_CodigoAbanks__c.trim();

		Test.startTest();
		List<FSC_APIPrestamoDesembolso.Output> outputs = FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{ inputItem });
		Test.stopTest();

		System.assertEquals(true, outputs[0].success, outputs[0].message);
		Map<String, Object> bodyRequest = (Map<String, Object>) FSC_APIPrestamoDesembolso.lastIpInput.get('bodyRequest');
		System.assertEquals(expectedCode, bodyRequest.get('codigoUsuario'), 'Usuario: codigo ABANKS o, si falta, alias.');
	}

	@IsTest
	static void isDescripcionExitosa_recognizesSuccessText() {
		System.assertEquals(true, FSC_APIPrestamoDesembolso.isDescripcionExitosa('Exitoso'));
		System.assertEquals(true, FSC_APIPrestamoDesembolso.isDescripcionExitosa('Desembolso realizado con éxito'));
		System.assertEquals(false, FSC_APIPrestamoDesembolso.isDescripcionExitosa('Proceso no exitoso'));
		System.assertEquals(false, FSC_APIPrestamoDesembolso.isDescripcionExitosa('Numero de Prestamo no encontrado 58265'));
		System.assertEquals(false, FSC_APIPrestamoDesembolso.isDescripcionExitosa(null));
	}

	private static void desembolsar(ResidentialLoanApplication rla) {
		createDebtor(rla.Id);
		FSC_APIPrestamoDesembolso.mockIpResponse = new Map<String, Object>{ 'StatusCode' => 200, 'descripcionRespuesta' => 'Exitoso' };
		FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{buildInput(rla.Id)});
	}

	private static List<Id> crearEvidencias() {
		List<ContentVersion> versiones = new List<ContentVersion>{
			new ContentVersion(Title = 'Hoja de amortización', PathOnClient = 'amortizacion.pdf', VersionData = Blob.valueOf('tabla'), FirstPublishLocationId = UserInfo.getUserId()),
			new ContentVersion(Title = 'Recibo de desembolso', PathOnClient = 'recibo.pdf', VersionData = Blob.valueOf('recibo'), FirstPublishLocationId = UserInfo.getUserId())
		};
		insert versiones;
		Map<Id, ContentVersion> archivos = new Map<Id, ContentVersion>([SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :versiones]);
		return new List<Id>{archivos.get(versiones[0].Id).ContentDocumentId, archivos.get(versiones[1].Id).ContentDocumentId};
	}

	@IsTest
	static void evidenciasExigenAmbosArchivosAntesDeAvanzar() {
		FSC_CapturaOperacionesService.testBypassPermissions = true;
		ResidentialLoanApplication rla = createRla();
		List<Id> documentos = crearEvidencias();
		Test.startTest();
		desembolsar(rla);
		String etapa = [SELECT FSC_Subestado__c FROM ResidentialLoanApplication WHERE Id = :rla.Id].FSC_Subestado__c;
		Integer bloqueados = 0;
		try { FSC_RlaAccionesController.confirmarDesembolsoManual(rla.Id, new List<Id>{documentos[0]}, null); }
		catch (AuraHandledException esperado) { bloqueados++; }
		try { FSC_RlaAccionesController.confirmarDesembolsoManual(rla.Id, null, new List<Id>{documentos[1]}); }
		catch (AuraHandledException esperado) { bloqueados++; }
		FSC_RlaAccionesController.confirmarDesembolsoManual(rla.Id, new List<Id>{documentos[0]}, new List<Id>{documentos[1]});
		Test.stopTest();
		ResidentialLoanApplication resultado = [SELECT FSC_Subestado__c, FSC_EvidenciasDesembolsoCargadas__c FROM ResidentialLoanApplication WHERE Id = :rla.Id WITH SYSTEM_MODE];
		System.assertEquals('Desembolso', etapa);
		System.assertEquals(2, bloqueados);
		System.assertEquals(true, resultado.FSC_EvidenciasDesembolsoCargadas__c && resultado.FSC_Subestado__c == 'Archivo y custodia');
	}

	@IsTest
	static void noSePuedeSaltarLaCargaDesdeElRegistro() {
		ResidentialLoanApplication rla = createRla();
		Test.startTest();
		desembolsar(rla);
		Database.SaveResult avance = Database.update(new ResidentialLoanApplication(Id = rla.Id,
			FSC_Subestado__c = 'Archivo y custodia', FSC_Desembolso_Realizado__c = true), false);
		Test.stopTest();
		System.assertEquals(false, avance.isSuccess());
		System.assert(avance.getErrors()[0].getMessage().contains('hoja de amortización'));
	}

	@IsTest
	static void conservaEvidenciasPendientesAlApagarElInterruptor() {
		FSC_CapturaOperacionesService.testBypassPermissions = true;
		ResidentialLoanApplication rla = createRla();
		Test.startTest();
		desembolsar(rla);
		FSC_ProcesamientoAbanks.automatizacionTest = false;
		update new ResidentialLoanApplication(Id = rla.Id, FSC_FlagErrorAPIDesembolso__c = true);
		Map<String, Object> contexto = FSC_RlaAccionesController.getCapturaOperacionesContext(rla.Id);
		FSC_APIPrestamoDesembolso.lastIpInput = null;
		FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{buildInput(rla.Id)});
		Test.stopTest();
		System.assertEquals(true, contexto.get('puedeCargarArchivosDesembolso'));
		System.assertEquals(false, [SELECT FSC_ProcesamientoAbanksManual__c FROM ResidentialLoanApplication WHERE Id = :rla.Id].FSC_ProcesamientoAbanksManual__c);
		System.assertEquals(null, FSC_APIPrestamoDesembolso.lastIpInput);
	}

	@IsTest
	static void rechazaUsarElMismoArchivoEnAmbasSecciones() {
		FSC_CapturaOperacionesService.testBypassPermissions = true;
		ResidentialLoanApplication rla = createRla();
		List<Id> documentos = crearEvidencias();
		Test.startTest();
		desembolsar(rla);
		Boolean rechazado = false;
		try { FSC_RlaAccionesController.confirmarDesembolsoManual(rla.Id, new List<Id>{documentos[0]}, new List<Id>{documentos[0]}); }
		catch (AuraHandledException esperado) { rechazado = true; }
		Test.stopTest();
		System.assertEquals(true, rechazado);
		System.assertEquals(0, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :rla.Id]);
	}

	@IsTest
	static void rechazaConfirmarSinExitoDeLaApi() {
		FSC_CapturaOperacionesService.testBypassPermissions = true;
		ResidentialLoanApplication rla = createRla();
		Test.startTest();
		Boolean rechazado = false;
		try { FSC_RlaAccionesController.confirmarDesembolsoManual(rla.Id, null, null); }
		catch (AuraHandledException esperado) { rechazado = true; }
		Test.stopTest();
		System.assertEquals(true, rechazado);
		System.assertEquals('Desembolso', [SELECT FSC_Subestado__c FROM ResidentialLoanApplication WHERE Id = :rla.Id].FSC_Subestado__c);
	}

	@IsTest
	static void run_noEnviaFueraDeLaEtapaDeDesembolso() {
		ResidentialLoanApplication rla = createRla();
		update new ResidentialLoanApplication(Id = rla.Id, FSC_Subestado__c = 'Archivo y custodia');
		Test.startTest();
		List<FSC_APIPrestamoDesembolso.Output> resultado = FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{buildInput(rla.Id)});
		Test.stopTest();
		System.assertEquals(false, resultado[0].success);
		System.assertEquals(null, FSC_APIPrestamoDesembolso.lastIpInput);
	}

	private static FSC_APIPrestamoDesembolso.Input buildInput(Id rlaId) {
		FSC_APIPrestamoDesembolso.Input inputItem = new FSC_APIPrestamoDesembolso.Input();
		inputItem.residentialLoanApplicationId = rlaId;
		inputItem.codigoUsuario = 'FLOWUSR';
		inputItem.codigoAgencia = '1';
		return inputItem;
	}

	private static ResidentialLoanApplication createRla() {
		return createRla('SavingsAccount', 'BCA', '209');
	}

	private static ResidentialLoanApplication createRla(String cuentaRecordType, String codigoLinea, String codigoProducto) {
		Account account = new Account(Name = 'Cliente Desembolso');
		insert account;

		Matriz_de_producto__c producto = new Matriz_de_producto__c(
			Name = 'Producto ' + codigoLinea + ' ' + codigoProducto,
			PRO_Codigo_de_linea_de_producto__c = codigoLinea,
			PRO_Codigo_de_producto__c = codigoProducto
		);
		insert producto;
		insert new FinServ__FinancialAccount__c(
			Name = 'Cuenta ' + NUMERO_CUENTA,
			FinServ__FinancialAccountNumber__c = NUMERO_CUENTA,
			FinServ__PrimaryOwner__c = account.Id,
			FIN_Producto__c = producto.Id,
			RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName()
				.get(cuentaRecordType)
				.getRecordTypeId()
		);

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Desembolso',
			AccountId = account.Id,
			RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
				.get('FSC_Solicitud_Credito_Consumo')
				.getRecordTypeId(),
			Status = 'En proceso',
			FSC_Subestado__c = 'Desembolso',
			FSC_FormaDeDesembolso__c = 'Cuenta de ahorro',
			FSC_TipoSolicitud__c = 'BPR',
			FSC_NumeroPrestamoAbanks__c = '54252',
			FSC_CodigoAprobacion__c = 'BCA',
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '204',
			FSC_NumeroCuentaDesembolso__c = NUMERO_CUENTA
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