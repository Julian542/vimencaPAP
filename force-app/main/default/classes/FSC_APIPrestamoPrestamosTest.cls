@IsTest
private class FSC_APIPrestamoPrestamosTest {
    @TestSetup
    static void asignarPermisosAdministrador() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet permiso = [SELECT Id FROM PermissionSet WHERE Name = 'FSC_PS_Administrador' LIMIT 1];
            // El usuario que despliega puede tener ya el permission set asignado.
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permiso.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permiso.Id);
            }
        }
    }

	private static Integer accountSequence = 0;

	private class PrestamosAndCatalogCalloutMock implements HttpCalloutMock {
		private Map<String, Object> catalogResponses;

		private PrestamosAndCatalogCalloutMock(Map<String, Object> catalogResponses) {
			this.catalogResponses = catalogResponses;
		}

		public HttpResponse respond(HttpRequest request) {
			Assert.areEqual(FSC_APIPrestamoConfig__mdt.getInstance('Default').FSC_ApiKey__c, request.getHeader('X-API-KEY'), 'Todas las llamadas deben enviar la API key configurada en FSC_APIPrestamoConfig__mdt.');
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json');
			if (request.getMethod() == 'GET') {
				Assert.isTrue(catalogResponses.containsKey(request.getEndpoint()), 'El catálogo solicitado debe estar configurado en el mock.');
				response.setBody(JSON.serialize(catalogResponses.get(request.getEndpoint())));
			} else {
				Assert.areEqual('POST', request.getMethod(), 'La creación del préstamo debe usar POST.');
				response.setBody(JSON.serialize(successfulResponse()));
			}
			return response;
		}
	}

	private class PrestamosTimeoutMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			throw new CalloutException('Timeout simulado');
		}
	}

	private class PrestamosBusinessRejectionMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			Assert.areEqual('POST', request.getMethod(), 'El reintento debe llamar al servicio de préstamos.');
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody(JSON.serialize(new Map<String, Object>{
				'descripcionRespuesta' => 'El codigo aprobacion de la solicitud 2 no es valido. Dato=00.',
				'descripcionTecnica' => 'Solicitud rechazada',
				'codigoRespuesta' => '99'
			}));
			return response;
		}
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
		ResidentialLoanApplication expectedRla = [
			SELECT FSC_MontoCuotaRegular__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];

		Assert.areEqual('FLOWUSR', ipInput.get('codigoUsuario'), 'Debe mapear codigoUsuario.');
		Assert.areEqual('1', prestamoItem.get('codigoTipoIdentificacion'), 'Debe mapear el tipo de identificación.');
		Assert.areEqual('001-0880361-0', prestamoItem.get('numeroIdentificacion'), 'Debe mapear la identificación formateada.');
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
	}

	@IsTest
	static void run_doesNotUpdateRlaWhenResponseIsNotSuccessful() {
		ResidentialLoanApplication rla = createRla();
		Test.setMock(HttpCalloutMock.class, new PrestamosBusinessRejectionMock());

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
		Assert.areEqual('El codigo aprobacion de la solicitud 2 no es valido. Dato=00.', outputs[0].descripcionRespuesta, 'Debe conservar el error de ABANKS.');

		List<INT_Request__c> requests = [
			SELECT Id, Trama_de_env_o__c
			FROM INT_Request__c
			WHERE Integraci_n__c = 'FSC_APIPrestamoPrestamos' AND Funci_n__c = 'callPrestamosIp'
		];
		Assert.areEqual(1, requests.size(), 'El rechazo funcional debe conservar el request.');
		Assert.isTrue(requests[0].Trama_de_env_o__c.contains('FLOWUSR'), 'Debe conservar el body enviado.');
		List<INT_Response__c> responses = [
			SELECT Http_Status_Code__c, Trama_de_respuesta__c
			FROM INT_Response__c
			WHERE INT_Request__c = :requests[0].Id
		];
		Assert.areEqual(1, responses.size(), 'El rechazo funcional debe conservar el response.');
		Assert.areEqual(Decimal.valueOf('200'), responses[0].Http_Status_Code__c, 'Debe guardar el status HTTP real.');
		Assert.isTrue(responses[0].Trama_de_respuesta__c.contains('El codigo aprobacion'), 'Debe conservar la respuesta de ABANKS.');

		ResidentialLoanApplication refreshed = [
			SELECT FSC_NumeroPrestamoAbanks__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		Assert.isNull(refreshed.FSC_NumeroPrestamoAbanks__c, 'No debe guardar un número de préstamo.');
		Assert.areNotEqual('Desembolso', refreshed.FSC_Subestado__c, 'No debe avanzar a desembolso.');
	}

	@IsTest
	static void reintentarCreacionPrestamo_preservesLogWhenAbanksRejectsRequest() {
		User actingUser = new User(Id = UserInfo.getUserId());

		System.runAs(actingUser) {
			ResidentialLoanApplication rla = createRla();
			update new ResidentialLoanApplication(Id = rla.Id, FSC_FormaDeDesembolso__c = 'Cuenta de ahorro');
			FSC_APIPrestamoProductos.mockIpResponse = new Map<String, Object>{
				'success' => true,
				'productos' => new List<Object>{
					new Map<String, Object>{
						'CODIGO_LINEA_FINANCIERA' => 32,
						'CODIGO_SUB_APLICACION' => 401,
						'CLAVE_PRODUCTO' => 17,
						'CODIGO_TIPO_AMORTIZACION' => '4',
						'CODIGO_VALOR_TASA_CARTERA' => 55,
						'CODIGO_ESTADO_CARTERA' => 'A',
						'DIAS_GRACIA_MORA' => 3
					}
				}
			};
			Test.setMock(HttpCalloutMock.class, new PrestamosBusinessRejectionMock());

			Test.startTest();
			FSC_RlaAccionesController.ReintentoPrestamoResult result = FSC_RlaAccionesController.reintentarCreacionPrestamo(rla.Id);
			Test.stopTest();

			Assert.isFalse(result.success, 'El rechazo de ABANKS debe devolverse al componente sin lanzar una excepción.');
			Assert.isTrue(result.message.contains('El codigo aprobacion'), 'Debe mostrar el motivo devuelto por ABANKS.');
			Assert.areEqual(1, [
				SELECT COUNT()
				FROM INT_Request__c
				WHERE Integraci_n__c = 'FSC_APIPrestamoPrestamos' AND Funci_n__c = 'callPrestamosIp'
			], 'El request debe sobrevivir al rechazo funcional.');
			Assert.areEqual(1, [
				SELECT COUNT()
				FROM INT_Response__c
				WHERE INT_Request__r.Integraci_n__c = 'FSC_APIPrestamoPrestamos'
			], 'El response debe sobrevivir al rechazo funcional.');
		}
	}

	@IsTest
	static void run_returnsErrorWhenRequiredDataIsMissing() {
		Account account = new Account(Name = 'Cliente sin identificacion');
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

	@IsTest
	static void run_buildsGuaranteeAndVehicleNodes() {
		ResidentialLoanApplication rla = createRla();
		update new ResidentialLoanApplication(Id = rla.Id, FSC_Moneda__c = '1', FSC_Porcentaje_de_Admisibilidad__c = 80);

		insert new List<FSC_Garantia__c>{
			new FSC_Garantia__c(
				Name = 'Vehiculo usado',
				FSC_Residential_Loan_Application__c = rla.Id,
				FSC_Clase_de_Garantia__c = 'VEHICULOS, MAQUINARIAS',
				FSC_Tipo_de_Garantia__c = 'Garantia vehicular usada',
				FSC_Descripcion_de_la_Garantia__c = 'Vehiculo Toyota Hilux',
				FSC_Tipo_Vehiculo__c = 'VEHICULO',
				FSC_Marca_Vehiculo__c = 'Toyota',
				FSC_Modelo_Vehiculo__c = 'HILUX',
				FSC_Ano_Vehiculo__c = Date.today().year() - 4,
				FSC_Color_Vehiculo__c = 'Blanco',
				FSC_Numero_Chasis_Vehiculo__c = 'CHASIS-001',
				FSC_Serial_Motor_Vehiculo__c = 'MOTOR-001',
				FSC_Numero_Placa_Vehiculo__c = 'A123456',
				FSC_Numero_Matricula__c = 'MAT-001',
				FSC_Valor_Vehiculo__c = 1500000
			),
			new FSC_Garantia__c(
				Name = 'Garantia hipotecaria',
				FSC_Residential_Loan_Application__c = rla.Id,
				FSC_Clase_de_Garantia__c = 'BIENES INMUEBLES',
				FSC_Tipo_de_Garantia__c = 'Garantia hipotecaria residencial',
				FSC_Descripcion_de_la_Garantia__c = 'Vivienda principal',
				FSC_Tipo_de_Inmueble__c = 'CASA',
				FSC_Valor_Tasado__c = 3000000
			),
			new FSC_Garantia__c(
				Name = 'Firma solidaria',
				FSC_Residential_Loan_Application__c = rla.Id,
				FSC_Clase_de_Garantia__c = 'FIRMA SOLIDARIA',
				FSC_Tipo_de_Garantia__c = 'Garantia solidaria',
				FSC_Descripcion_de_la_Garantia__c = 'Firma solidaria del garante'
			),
			new FSC_Garantia__c(
				Name = 'Certificado',
				FSC_Residential_Loan_Application__c = rla.Id,
				FSC_Clase_de_Garantia__c = 'CERTIFICADOS DEPOSITOS BANCO VIMENCA',
				FSC_Tipo_de_Garantia__c = 'Certificado de deposito Banco Vimenca',
				FSC_Descripcion_de_la_Garantia__c = 'Certificado de deposito propio',
				FSC_Monto_Certificado_Deposito__c = 500000
			)
		};

		FSC_APIPrestamoPrestamos.callCatalogHttpInTests = true;
		Test.setMock(HttpCalloutMock.class, new PrestamosAndCatalogCalloutMock(guaranteeCatalogResponses()));

		FSC_APIPrestamoPrestamos.Input inputItem = buildInput(rla.Id);
		Test.startTest();
		List<FSC_APIPrestamoPrestamos.Output> outputs = FSC_APIPrestamoPrestamos.run(new List<FSC_APIPrestamoPrestamos.Input>{ inputItem });
		Test.stopTest();

		Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(outputs[0].ipInput);
		List<Object> guarantees = (List<Object>) ((Map<String, Object>) requestBody.get('garantia')).get('gaGarantiasItem');
		List<Object> vehicles = (List<Object>) ((Map<String, Object>) requestBody.get('garantiaAutos')).get('gaAutosItem');
		Assert.isTrue(outputs[0].success, 'La solicitud con garantias debe procesarse.');
		Assert.areEqual(4, guarantees.size(), 'Debe incluir todas las garantias comunes.');
		Assert.areEqual(1, vehicles.size(), 'Debe incluir el detalle del vehiculo.');
		List<INT_Request__c> savedRequests = [
			SELECT Id, Funci_n__c, Trama_de_env_o__c
			FROM INT_Request__c
			WHERE Integraci_n__c = 'FSC_APIPrestamoPrestamos'
		];
		Assert.areEqual(8, savedRequests.size(), 'Deben registrarse siete catálogos y la creación del préstamo.');
		Integer catalogCount = 0;
		Integer loanCount = 0;
		for (INT_Request__c savedRequest : savedRequests) {
			if (savedRequest.Funci_n__c == 'callPrestamosIp') {
				loanCount++;
				Assert.isTrue(savedRequest.Trama_de_env_o__c.contains('prestamo'), 'Debe conservarse el body enviado al API de préstamos.');
			} else {
				catalogCount++;
				Assert.isTrue(savedRequest.Trama_de_env_o__c.contains('"method":"GET"'), 'Debe identificarse el GET del catálogo.');
			}
		}
		Assert.areEqual(7, catalogCount, 'Cada consulta de catálogo debe tener su request.');
		Assert.areEqual(1, loanCount, 'La creación del préstamo debe tener un request.');
		List<INT_Response__c> savedResponses = [
			SELECT INT_Request__c, Http_Status_Code__c, Trama_de_respuesta__c
			FROM INT_Response__c
			WHERE INT_Request__r.Integraci_n__c = 'FSC_APIPrestamoPrestamos'
		];
		Assert.areEqual(8, savedResponses.size(), 'Cada llamada debe conservar su respuesta vinculada.');
		for (INT_Response__c savedResponse : savedResponses) {
			Assert.areEqual(Decimal.valueOf('200'), savedResponse.Http_Status_Code__c, 'El status HTTP debe guardarse.');
			Assert.isNotNull(savedResponse.INT_Request__c, 'La respuesta debe vincularse con su request.');
			Assert.isNotNull(savedResponse.Trama_de_respuesta__c, 'Debe conservarse el body de respuesta.');
		}
	}

	@IsTest
	static void run_usesStoredCatalogCodes() {
		ResidentialLoanApplication rla = createRla();
		update new ResidentialLoanApplication(Id = rla.Id, FSC_Moneda__c = '1', FSC_Porcentaje_de_Admisibilidad__c = 80);
		FSC_Garantia__c vehicle = new FSC_Garantia__c(
			Name = 'Vehiculo usado',
			FSC_Residential_Loan_Application__c = rla.Id,
			FSC_Clase_de_Garantia__c = 'VEHICULOS, MAQUINARIAS',
			FSC_Tipo_de_Garantia__c = 'VEHICULO ELEGIDO EN CATALOGO',
			FSC_Descripcion_de_la_Garantia__c = 'Vehiculo Toyota Hilux',
			FSC_Tipo_Vehiculo__c = 'VEHICULO',
			FSC_Marca_Vehiculo__c = 'TOYOTA',
			FSC_Modelo_Vehiculo__c = 'HILUX',
			FSC_Ano_Vehiculo__c = Date.today().year() - 4,
			FSC_Numero_Chasis_Vehiculo__c = 'CHASIS-002',
			FSC_Serial_Motor_Vehiculo__c = 'MOTOR-002',
			FSC_Valor_Vehiculo__c = 1500000
		);
		insert vehicle;
		// El trigger solo recalcula codigos si cambia el texto, por lo que estos codigos se conservan.
		Database.update(
			new FSC_Garantia__c(
				Id = vehicle.Id,
				FSC_Codigo_Clase_Garantia__c = 1,
				FSC_Codigo_Tipo_Garantia__c = 60,
				FSC_Codigo_Marca_Vehiculo__c = 7,
				FSC_Codigo_Modelo_Vehiculo__c = 71
			),
			AccessLevel.SYSTEM_MODE
		);

		// Dos tipos y dos modelos con la misma descripcion: sin codigo, la descripcion no alcanza para elegir.
		Map<String, Object> catalogResponses = guaranteeCatalogResponses();
		List<Object> types = (List<Object>) catalogResponses.get('callout:FSC_APIPrestamo/api/prestamo/garantias/tipos');
		types.add(new Map<String, Object>{ 'CODIGO_TIPO_GARANTIA' => 60, 'DESCRIPCION' => 'VEHICULO ELEGIDO EN CATALOGO', 'CODIGO_MONEDA' => 1, 'PORCENTAJE_SIB' => 90 });
		types.add(new Map<String, Object>{ 'CODIGO_TIPO_GARANTIA' => 61, 'DESCRIPCION' => 'VEHICULO ELEGIDO EN CATALOGO', 'CODIGO_MONEDA' => 1, 'PORCENTAJE_SIB' => 90 });
		List<Object> relations = (List<Object>) catalogResponses.get('callout:FSC_APIPrestamo/api/prestamo/garantias/clases-por-tipo');
		relations.add(new Map<String, Object>{ 'CODIGO_TIPO_GARANTIA' => 60, 'CODIGO_CLASE_GARANTIA' => 1 });
		relations.add(new Map<String, Object>{ 'CODIGO_TIPO_GARANTIA' => 61, 'CODIGO_CLASE_GARANTIA' => 1 });
		((List<Object>) catalogResponses.get('callout:FSC_APIPrestamo/api/prestamo/garantias/modelos-auto'))
			.add(new Map<String, Object>{ 'CODIGO_MODELO' => 71, 'CODIGO_MARCA' => 7, 'DESCRIPCION' => 'HILUX', 'CAPACIDAD' => 7, 'CODIGO_TIPO' => 3 });
		FSC_APIPrestamoPrestamos.mockIpResponse = successfulResponse();
		FSC_APIPrestamoPrestamos.mockCatalogResponses = catalogResponses;

		Test.startTest();
		List<FSC_APIPrestamoPrestamos.Output> outputs = FSC_APIPrestamoPrestamos.run(new List<FSC_APIPrestamoPrestamos.Input>{ buildInput(rla.Id) });
		Test.stopTest();

		Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(outputs[0].ipInput);
		Map<String, Object> guarantee = (Map<String, Object>) ((List<Object>) ((Map<String, Object>) requestBody.get('garantia')).get('gaGarantiasItem'))[0];
		Map<String, Object> vehicleItem = (Map<String, Object>) ((List<Object>) ((Map<String, Object>) requestBody.get('garantiaAutos')).get('gaAutosItem'))[0];
		Assert.isTrue(outputs[0].success, 'La solicitud debe procesarse.');
		Assert.areEqual(60, guarantee.get('codigoTipoGarantia'), 'Ante tipos repetidos debe enviarse el tipo exacto elegido en el catalogo.');
		Assert.areEqual(1, guarantee.get('codigoClaseGarantias'), 'Debe enviarse la clase guardada.');
		Assert.areEqual(71, vehicleItem.get('codigoModelo'), 'Ante modelos repetidos debe enviarse el modelo exacto guardado.');
	}

	@IsTest
	static void run_buildsRlaAndPymeGuarantees() {
		ResidentialLoanApplication fallbackRla = createRla();
		update new ResidentialLoanApplication(
			Id = fallbackRla.Id,
			FSC_Moneda__c = '1',
			FSC_Tipo_de_Garantia__c = 'Garantía Solidaria',
			FSC_Descripcion_de_la_Garantia__c = '78',
			FSC_Valor_de_la_Garantia__c = 100000,
			FSC_Porcentaje_de_Admisibilidad__c = 100
		);

		ResidentialLoanApplication pymeRla = createRla('FSC_Solicitud_Credito_PYME');
		update new ResidentialLoanApplication(Id = pymeRla.Id, FSC_Moneda__c = '1');
		insert new LoanApplicationAsset(
			LoanApplicationId = pymeRla.Id,
			Name = 'Inventario comercial',
			CashOrMarketValue = 750000,
			FSC_Porcentaje_Admisibilidad__c = 70,
			FSC_Descripcion_de_la_Garantia__c = '16',
			FSC_Descripcion_Contrato__c = 'Inventario de mercancia'
		);

		FSC_APIPrestamoPrestamos.mockIpResponse = successfulResponse();
		FSC_APIPrestamoPrestamos.mockCatalogResponses = guaranteeCatalogResponses();
		Test.startTest();
		List<FSC_APIPrestamoPrestamos.Output> outputs = FSC_APIPrestamoPrestamos.run(
			new List<FSC_APIPrestamoPrestamos.Input>{ buildInput(fallbackRla.Id), buildInput(pymeRla.Id) }
		);
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Debe procesar ambas fuentes de garantias.');
		Assert.isTrue(outputs[0].success, 'La garantia de la solicitud debe procesarse.');
		Assert.isTrue(outputs[1].success, 'La garantia PYME debe procesarse.');
	}

	@IsTest
	static void run_persistsTwoLoanCalloutsInBulk() {
		ResidentialLoanApplication firstRla = createRla();
		ResidentialLoanApplication secondRla = createRla();
		Test.setMock(HttpCalloutMock.class, new PrestamosAndCatalogCalloutMock(new Map<String, Object>()));

		Test.startTest();
		List<FSC_APIPrestamoPrestamos.Output> outputs = FSC_APIPrestamoPrestamos.run(
			new List<FSC_APIPrestamoPrestamos.Input>{ buildInput(firstRla.Id), buildInput(secondRla.Id) }
		);
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Debe devolver una salida por cada préstamo.');
		Assert.isTrue(outputs[0].success, 'El primer préstamo debe crearse.');
		Assert.isTrue(outputs[1].success, 'El segundo préstamo debe crearse.');
		Assert.areEqual(
			2,
			[SELECT COUNT() FROM INT_Request__c WHERE Integraci_n__c = 'FSC_APIPrestamoPrestamos' AND Funci_n__c = 'callPrestamosIp'],
			'Deben persistirse ambas solicitudes tras terminar los callouts.'
		);
		Assert.areEqual(
			2,
			[SELECT COUNT() FROM INT_Response__c WHERE INT_Request__r.Integraci_n__c = 'FSC_APIPrestamoPrestamos'],
			'Cada préstamo debe tener su respuesta vinculada.'
		);
	}

	@IsTest
	static void run_persistsRequestWhenLoanCalloutTimesOut() {
		ResidentialLoanApplication rla = createRla();
		Test.setMock(HttpCalloutMock.class, new PrestamosTimeoutMock());

		Test.startTest();
		List<FSC_APIPrestamoPrestamos.Output> outputs = FSC_APIPrestamoPrestamos.run(new List<FSC_APIPrestamoPrestamos.Input>{ buildInput(rla.Id) });
		Test.stopTest();

		Assert.isFalse(outputs[0].success, 'Un timeout debe marcar error de integración.');
		List<INT_Request__c> requests = [
			SELECT Id, Trama_de_env_o__c
			FROM INT_Request__c
			WHERE Integraci_n__c = 'FSC_APIPrestamoPrestamos' AND Funci_n__c = 'callPrestamosIp'
		];
		Assert.areEqual(1, requests.size(), 'Debe registrarse el intento fallido.');
		Assert.isTrue(requests[0].Trama_de_env_o__c.contains('prestamo'), 'Debe conservarse el body enviado.');
		INT_Response__c response = [
			SELECT Http_Status_Code__c, Status__c, Trama_de_respuesta__c
			FROM INT_Response__c
			WHERE INT_Request__c = :requests[0].Id
		];
		Assert.areEqual(Decimal.valueOf('0'), response.Http_Status_Code__c, 'Sin respuesta HTTP se usa 0 por ser obligatorio el campo.');
		Assert.areEqual('SIN RESPUESTA', response.Status__c, 'Debe identificarse la falta de respuesta.');
		Assert.isTrue(response.Trama_de_respuesta__c.contains('Timeout simulado'), 'Debe conservarse la causa del timeout.');
	}

	private static FSC_APIPrestamoPrestamos.Input buildInput(Id rlaId) {
		FSC_APIPrestamoPrestamos.Input inputItem = new FSC_APIPrestamoPrestamos.Input();
		inputItem.residentialLoanApplicationId = rlaId;
		inputItem.codigoUsuario = 'FLOWUSR';
		inputItem.codigoAgencia = '7';
		inputItem.codigoEjecutivo = 'FLOWUSR';
		inputItem.productoJson = buildProductoJson();
		return inputItem;
	}

	private static Map<String, Object> successfulResponse() {
		return new Map<String, Object>{ 'descripcionRespuesta' => 'Exitoso', 'codigoRespuesta' => '00', 'numeroPrestamo' => 54291 };
	}

	private static Map<String, Object> guaranteeCatalogResponses() {
		return new Map<String, Object>{
			'callout:FSC_APIPrestamo/api/prestamo/garantias/tipos' => new List<Object>{
				catalogRow(
					new Map<String, Object>{
						'CODIGO_TIPO_GARANTIA' => 10,
						'DESCRIPCION' => 'VEHICULOS USADOS 3 5 ANOS',
						'CODIGO_MONEDA' => 1,
						'PORCENTAJE_SIB' => 80,
						'MANEJA_SEGUROS' => 'S'
					}
				),
				catalogRow(
					new Map<String, Object>{
						'CODIGO_TIPO_GARANTIA' => 20,
						'DESCRIPCION' => 'EDIFICIOS RESIDENCIALES VIVIENDAS O APTOS',
						'CODIGO_MONEDA' => 1,
						'PORCENTAJE_SIB' => 80
					}
				),
				catalogRow(
					new Map<String, Object>{
						'CODIGO_TIPO_GARANTIA' => 30,
						'DESCRIPCION' => 'SOLIDARIO',
						'CODIGO_MONEDA' => 1,
						'PORCENTAJE_SIB' => 100
					}
				),
				catalogRow(
					new Map<String, Object>{
						'CODIGO_TIPO_GARANTIA' => 40,
						'DESCRIPCION' => 'DUENO DEL DP',
						'CODIGO_MONEDA' => 1,
						'PORCENTAJE_SIB' => 100
					}
				),
				catalogRow(
					new Map<String, Object>{
						'CODIGO_TIPO_GARANTIA' => 50,
						'DESCRIPCION' => 'INVENTARIO',
						'CODIGO_MONEDA' => 1,
						'PORCENTAJE_SIB' => 70
					}
				)
			},
			'callout:FSC_APIPrestamo/api/prestamo/garantias/tipos-bien' => new List<Object>{
				catalogRow(
					new Map<String, Object>{
						'CODIGO_BIEN' => 100,
						'DESCRIPCION' => 'VEHICULO',
						'STATUS' => 'M',
						'SIGLA' => 'VEH',
						'CODIGO_GRUPO_TARIFA' => 'AUTO'
					}
				),
				catalogRow(
					new Map<String, Object>{
						'CODIGO_BIEN' => 101,
						'DESCRIPCION' => 'CASA',
						'STATUS' => 'I',
						'SIGLA' => 'INM',
						'CODIGO_GRUPO_TARIFA' => 'CASA'
					}
				),
				catalogRow(
					new Map<String, Object>{
						'CODIGO_BIEN' => 102,
						'DESCRIPCION' => 'AVALES O FIANZAS',
						'STATUS' => 'O',
						'SIGLA' => 'AVA',
						'CODIGO_GRUPO_TARIFA' => 'FIRMA'
					}
				),
				catalogRow(
					new Map<String, Object>{
						'CODIGO_BIEN' => 103,
						'DESCRIPCION' => 'CERTIFICADO DEPOSITO INVERSION',
						'STATUS' => 'T',
						'SIGLA' => 'CD',
						'CODIGO_GRUPO_TARIFA' => 'CERT'
					}
				),
				catalogRow(new Map<String, Object>{ 'CODIGO_BIEN' => 104, 'DESCRIPCION' => 'OTROS', 'STATUS' => 'O' }),
				catalogRow(new Map<String, Object>{ 'CODIGO_BIEN' => 105, 'DESCRIPCION' => 'INVENTARIO', 'STATUS' => 'N' })
			},
			'callout:FSC_APIPrestamo/api/prestamo/garantias/clases' => new List<Object>{
				catalogRow(
					new Map<String, Object>{ 'CODIGO_CLASE_GARANTIA' => 1, 'DESCRIPCION' => 'VEHICULOS, MAQUINARIAS', 'MANEJA_SEGUROS' => 'S' }
				),
				catalogRow(new Map<String, Object>{ 'CODIGO_CLASE_GARANTIA' => 2, 'DESCRIPCION' => 'BIENES INMUEBLES', 'MANEJA_SEGUROS' => 'S' }),
				catalogRow(new Map<String, Object>{ 'CODIGO_CLASE_GARANTIA' => 3, 'DESCRIPCION' => 'FIRMA SOLIDARIA' }),
				catalogRow(new Map<String, Object>{ 'CODIGO_CLASE_GARANTIA' => 4, 'DESCRIPCION' => 'CERTIFICADOS DEPOSITOS BANCO VIMENCA' }),
				catalogRow(new Map<String, Object>{ 'CODIGO_CLASE_GARANTIA' => 5, 'DESCRIPCION' => 'OTROS' })
			},
			'callout:FSC_APIPrestamo/api/prestamo/garantias/clases-por-tipo' => new List<Object>{
				catalogRow(new Map<String, Object>{ 'CODIGO_TIPO_GARANTIA' => 10, 'CODIGO_CLASE_GARANTIA' => 1 }),
				catalogRow(new Map<String, Object>{ 'CODIGO_TIPO_GARANTIA' => 20, 'CODIGO_CLASE_GARANTIA' => 2 }),
				catalogRow(new Map<String, Object>{ 'CODIGO_TIPO_GARANTIA' => 30, 'CODIGO_CLASE_GARANTIA' => 3 }),
				catalogRow(new Map<String, Object>{ 'CODIGO_TIPO_GARANTIA' => 40, 'CODIGO_CLASE_GARANTIA' => 4 }),
				catalogRow(new Map<String, Object>{ 'CODIGO_TIPO_GARANTIA' => 50, 'CODIGO_CLASE_GARANTIA' => 5 })
			},
			'callout:FSC_APIPrestamo/api/prestamo/garantias/marcas-auto' => new List<Object>{
				catalogRow(new Map<String, Object>{ 'CODIGO_MARCA' => 7, 'DESCRIPCION' => 'Toyota' })
			},
			'callout:FSC_APIPrestamo/api/prestamo/garantias/modelos-auto' => new List<Object>{
				catalogRow(
					new Map<String, Object>{
						'CODIGO_MODELO' => 70,
						'CODIGO_MARCA' => 7,
						'DESCRIPCION' => 'HILUX',
						'CAPACIDAD' => 5,
						'CILINDROS' => 4,
						'CODIGO_TIPO' => 2
					}
				)
			},
			'callout:FSC_APIPrestamo/api/prestamo/garantias/aseguradoras' => new List<Object>{
				catalogRow(new Map<String, Object>{ 'CODIGO_ASEGURADORA' => 9, 'NOMBRE' => 'Seguros Universal' })
			}
		};
	}

	private static Map<String, Object> catalogRow(Map<String, Object> row) {
		return row;
	}

	private static ResidentialLoanApplication createRla() {
		return createRla('FSC_Solicitud_Credito_Consumo');
	}

	private static ResidentialLoanApplication createRla(String recordTypeName) {
		Account account = new Account(
			LastName = 'Cliente Prestamo',
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Fisica').getRecordTypeId(),
			ACC_NumIdentificacion__c = '00108803610',
			ACC_TipoIdentificacion__c = 'Cédula'
		);
		if (accountSequence++ > 0) {
			account.ACC_NumIdentificacion__c = '00108803628';
		}
		insert account;

		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA Prestamo',
			AccountId = account.Id,
			RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId(),
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