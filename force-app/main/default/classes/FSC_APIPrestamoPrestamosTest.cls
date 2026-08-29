@IsTest
private class FSC_APIPrestamoPrestamosTest {
	private static Account buildNeutralAccount(String name, String documentNumber) {
		Account account = new Account();
		account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
		account.Name = name;
		account.ACC_RNC__c = 'RNCPREST' + String.valueOf(Math.abs(Crypto.getRandomInteger())).left(6);
		account.ACC_NumIdentificacion__c = documentNumber;
		account.ACC_Condicion__c = 'PROSPECTO';
		account.ACC_Estado__c = 'INICIADO';
		account.ACC_TipoIdentificacion__c = 'RNC';
		return account;
	}

	@IsTest
	static void run_updatesRlaWhenIpResponseIsSuccessful() {
		ResidentialLoanApplication rla = createRla();
		update new ResidentialLoanApplication(Id = rla.Id, FSC_FlagErrorAPIPrestamos__c = true);

		FSC_APIPrestamoPrestamos.mockIpResponse = new Map<String, Object>{
			'descripcionRespuesta' => 'Exitoso',
			'descripcionTecnica' => null,
			'codigoRespuesta' => '00',
			'numeroPrestamo' => 54290
		};

		FSC_APIPrestamoPrestamos.Input inputItem = new FSC_APIPrestamoPrestamos.Input();
		inputItem.residentialLoanApplicationId = rla.Id;
		inputItem.codigoUsuario = 'FLOWUSR';
		inputItem.codigoAgencia = '7';
		inputItem.codigoEjecutivo = 'FLOWUSR';
		inputItem.productoJson = buildProductoJson();

		Test.startTest();
		List<FSC_APIPrestamoPrestamos.Output> outputs = FSC_APIPrestamoPrestamos.run(new List<FSC_APIPrestamoPrestamos.Input>{ inputItem });
		Test.stopTest();

		Assert.areEqual(1, outputs.size(), 'Debe devolver una salida por solicitud.');
		Assert.isTrue(outputs[0].success, 'La creación del préstamo debe resultar exitosa.');
		Assert.areEqual('Exitoso', outputs[0].descripcionRespuesta, 'Debe conservar la descripción de ABANKS.');
		Assert.areEqual('54290', outputs[0].numeroPrestamo, 'Debe devolver el número de préstamo creado.');
		Assert.isTrue(outputs[0].ipInput.contains('"codigoUsuario":"FLOWUSR"'), 'Debe enviar el usuario indicado.');

		ResidentialLoanApplication refreshed = [
			SELECT FSC_NumeroPrestamoAbanks__c, FSC_Subestado__c, FSC_FlagErrorAPIPrestamos__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		Assert.areEqual('54290', refreshed.FSC_NumeroPrestamoAbanks__c, 'Debe guardar el número de préstamo.');
		Assert.areEqual('Desembolso', refreshed.FSC_Subestado__c, 'Debe avanzar al subestado de desembolso.');
		Assert.isFalse(refreshed.FSC_FlagErrorAPIPrestamos__c, 'Debe limpiar el indicador de error.');

		Map<String, Object> ipInput = FSC_APIPrestamoPrestamos.lastIpInput;
		Assert.isFalse(ipInput.containsKey('bodyRequest'), 'El IP debe recibir la estructura directa, sin bodyRequest.');

		Map<String, Object> prestamo = (Map<String, Object>) ipInput.get('prestamo');
		List<Object> prestamosItems = (List<Object>) prestamo.get('prPrestamosItem');
		Map<String, Object> prestamoItem = (Map<String, Object>) prestamosItems[0];
		Map<String, Object> deducciones = (Map<String, Object>) ipInput.get('deducciones');
		List<Object> deduccionesUpperItems = (List<Object>) deducciones.get('prDeduccionesItem');
		List<Object> deduccionesLowerItems = (List<Object>) deducciones.get('prdeduccionesItem');
		ResidentialLoanApplication expectedRla = [
			SELECT FSC_MontoCuotaRegular__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		Assert.areEqual('FLOWUSR', ipInput.get('codigoUsuario'), 'Debe mapear codigoUsuario.');
		Assert.areEqual('1', prestamoItem.get('codigoTipoIdentificacion'), 'Debe mapear el tipo de identificación.');
		Assert.areEqual('00108803610', prestamoItem.get('numeroIdentificacion'), 'Debe mapear la identificación.');
		Assert.areEqual('1', prestamoItem.get('codigoEmpresa'), 'Debe mapear la empresa.');
		Assert.areEqual('7', prestamoItem.get('codigoAgencia'), 'Debe mapear la agencia.');
		Assert.areEqual('401', prestamoItem.get('codigoSubAplicacion'), 'Debe mapear la subaplicación.');
		Assert.areEqual('17', prestamoItem.get('claveProducto'), 'Debe mapear la clave del producto.');
		Assert.areEqual('4', prestamoItem.get('codigoTipoAmortizacion'), 'Debe mapear el tipo de amortización.');
		Assert.areEqual('A', prestamoItem.get('codigoEstadoCartera'), 'Debe mapear el estado de cartera.');
		Assert.areEqual('55', prestamoItem.get('codigoValorTasaCartera'), 'Debe mapear el código de tasa.');
		Assert.areEqual(Decimal.valueOf('55'), prestamoItem.get('tasaBaseIntCorriente'), 'Debe mapear la tasa base.');
		Assert.areEqual(Decimal.valueOf('20000'), prestamoItem.get('montoInicial'), 'Debe mapear el monto inicial.');
		Assert.areEqual(expectedRla.FSC_MontoCuotaRegular__c, prestamoItem.get('valorCuota'), 'Debe mapear la cuota.');
		Assert.areEqual(Decimal.valueOf('29.7'), prestamoItem.get('tasaTotal'), 'Debe mapear la tasa aprobada.');
		Assert.areEqual('5', prestamoItem.get('tipoTasa'), 'Tipo de tasa debe ser periódica.');
		Assert.areEqual('2', prestamoItem.get('tipoFrecuenciaRevision'), 'La frecuencia debe expresarse en meses.');
		Assert.areEqual('12', prestamoItem.get('periodoTasa'), 'Debe mapear el período de tasa.');
		Assert.areEqual('23', prestamoItem.get('diaRevisionTasa'), 'Debe usar el día de creación de la solicitud.');
		Assert.areEqual(formatAbanksDate(Date.today().addMonths(12)), prestamoItem.get('fechaRevisionInt'), 'Debe calcular la revisión desde hoy.');
		Assert.areEqual('3', prestamoItem.get('diasGraciaMora'), 'Debe usar los días de gracia del producto.');
		Assert.areEqual('24', prestamoItem.get('numeroCuotas'), 'Debe mapear el plazo.');
		Assert.areEqual('23-sep-2025', prestamoItem.get('fechaAprobacion'), 'Debe mapear la fecha de aprobación.');
		Assert.areEqual('23-sep-2025', prestamoItem.get('fechaApertura'), 'Debe mapear la fecha de creación.');
		Assert.areEqual('23-oct-2025', prestamoItem.get('fechaPrimerPagoInteres'), 'Debe mapear el primer pago de interés.');
		Assert.areEqual('23-oct-2025', prestamoItem.get('fechaPrimerPagoCapital'), 'Debe mapear el primer pago de capital.');
		Assert.areEqual('FLOWUSR', prestamoItem.get('codigoEjecutivo'), 'Debe mapear el ejecutivo.');
		Assert.areEqual('23-sep-2026', prestamoItem.get('fechaVencimiento'), 'Debe mapear el vencimiento.');
		Assert.areEqual(0, deduccionesUpperItems.size(), 'No debe crear deducciones en la colección superior.');
		Assert.areEqual(0, deduccionesLowerItems.size(), 'No debe crear deducciones en la colección inferior.');
	}

	@IsTest
	static void run_doesNotUpdateRlaWhenResponseIsNotSuccessful() {
		ResidentialLoanApplication rla = createRla();
		FSC_APIPrestamoPrestamos.mockIpResponse = new Map<String, Object>{
			'descripcionRespuesta' => 'Error',
			'descripcionTecnica' => 'Bad Request',
			'codigoRespuesta' => '99'
		};

		FSC_APIPrestamoPrestamos.Input inputItem = new FSC_APIPrestamoPrestamos.Input();
		inputItem.residentialLoanApplicationId = rla.Id;
		inputItem.codigoUsuario = 'FLOWUSR';
		inputItem.codigoAgencia = '7';
		inputItem.codigoEjecutivo = 'FLOWUSR';
		inputItem.productoJson = buildProductoJson();

		Test.startTest();
		List<FSC_APIPrestamoPrestamos.Output> outputs = FSC_APIPrestamoPrestamos.run(new List<FSC_APIPrestamoPrestamos.Input>{ inputItem });
		Test.stopTest();

		Assert.areEqual(1, outputs.size(), 'Debe devolver una salida.');
		Assert.isFalse(outputs[0].success, 'La respuesta no exitosa debe marcar error.');
		Assert.areEqual('Error', outputs[0].descripcionRespuesta, 'Debe conservar el error de ABANKS.');

		ResidentialLoanApplication refreshed = [
			SELECT FSC_NumeroPrestamoAbanks__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		Assert.isNull(refreshed.FSC_NumeroPrestamoAbanks__c, 'No debe guardar un número de préstamo.');
		Assert.areNotEqual('Desembolso', refreshed.FSC_Subestado__c, 'No debe avanzar a desembolso.');
	}

	@IsTest
	static void run_returnsErrorWhenRequiredDataIsMissing() {
		Account account = buildNeutralAccount('Cliente sin identificacion', null);
		insert account;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Prestamo Error',
			AccountId = account.Id,
			RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
				.get('FSC_Solicitud_Credito_Consumo')
				.getRecordTypeId(),
			Status = 'En proceso',
			FSC_Subestado__c = 'Creación de crédito',
			FSC_Grupo_de_Empresa__c = '1',
			FSC_MontoAprobado__c = 20000,
			FSC_PlazoMesesAprobado__c = 24,
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401'
		);
		insert rla;

		FSC_APIPrestamoPrestamos.Input inputItem = new FSC_APIPrestamoPrestamos.Input();
		inputItem.residentialLoanApplicationId = rla.Id;

		Test.startTest();
		List<FSC_APIPrestamoPrestamos.Output> outputs = FSC_APIPrestamoPrestamos.run(new List<FSC_APIPrestamoPrestamos.Input>{ inputItem });
		Test.stopTest();

		Assert.areEqual(1, outputs.size(), 'Debe devolver una salida.');
		Assert.isFalse(outputs[0].success, 'Debe rechazar datos incompletos.');
		Assert.isTrue(outputs[0].message.contains('Account.ACC_NumIdentificacion__c'), 'Debe identificar el campo requerido faltante.');
	}

	private static ResidentialLoanApplication createRla() {
		Account account = new Account(
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
			FirstName = 'Cliente',
			LastName = 'Prestamo',
			ACC_NumIdentificacion__c = '00108803610',
			ACC_TipoIdentificacion__c = 'Cédula'
		);
		Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
		insert account;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Prestamo',
			AccountId = account.Id,
			RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
				.get('FSC_Solicitud_Credito_Consumo')
				.getRecordTypeId(),
			Status = 'En proceso',
			FSC_Subestado__c = 'Creación de crédito',
			FSC_Grupo_de_Empresa__c = '1',
			FSC_MontoAprobado__c = 20000,
			FSC_MontoDesembolsar__c = 20000,
			FSC_PlazoMeses__c = 24,
			FSC_PlazoMesesAprobado__c = 24,
			FSC_TasaInteres__c = 29.7,
			FSC_TasaInteresAprobada__c = 29.7,
			FSC_FechaYHoraAprobacionComite__c = Datetime.newInstance(2025, 9, 23, 10, 0, 0),
			FSC_FechaVencimiento__c = Date.newInstance(2026, 9, 23),
			FSC_CodigoAprobacion__c = '14',
			FSC_lineaFinanciera__c = '32',
			FSC_subAplicacion__c = '401',
			FSC_PeriodoTasa__c = 12,
			FSC_FechaPrimerPagoInteres__c = Date.newInstance(2025, 10, 23),
			FSC_FechaPrimerPagoCapital__c = Date.newInstance(2025, 10, 23)
		);
		insert rla;
		Test.setCreatedDate(rla.Id, Datetime.newInstance(2025, 9, 23, 9, 0, 0));
		return rla;
	}

	private static String buildProductoJson() {
		return JSON.serialize(
			new Map<String, Object>{
				'CLAVE_PRODUCTO' => 17,
				'CODIGO_SUB_APLICACION' => 401,
				'CODIGO_TIPO_AMORTIZACION' => '4',
				'CODIGO_VALOR_TASA_CARTERA' => 55,
				'CODIGO_ESTADO_CARTERA' => 'A',
				'CODIGO_VALOR_TASA_CARTERA_MORA' => 40,
				'DIAS_GRACIA_MORA' => 3
			}
		);
	}

	private static String formatAbanksDate(Date value) {
		List<String> months = new List<String>{ 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic' };
		String dayText = value.day() < 10 ? '0' + value.day() : String.valueOf(value.day());
		return dayText + '-' + months[value.month() - 1] + '-' + value.year();
	}
}
