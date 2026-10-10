@IsTest
private class FSC_ActaComitePDFControllerTest {
	private static final String TEST_ACCOUNT_NAME = 'Test Account 1';

	@TestSetup
	static void setupData() {
		TestDataFactory_FSC.createJuridicAccounts(1);
	}

	private static Account getTestAccount() {
		return [
			SELECT Id, Name
			FROM Account
			WHERE Name = :TEST_ACCOUNT_NAME
			WITH USER_MODE
			LIMIT 1
		];
	}

	private static ResidentialLoanApplication createRLA(
		Id accountId,
		DateTime fechaAprobacion,
		Boolean aprobadaPorComite,
		Decimal montoSolicitado,
		Decimal montoAprobado,
		Decimal plazoSolicitado,
		Decimal plazoAprobado,
		Boolean aplicaGarantia
	) {
		ResidentialLoanApplication rla = buildRLA(
			accountId,
			fechaAprobacion,
			aprobadaPorComite,
			montoSolicitado,
			montoAprobado,
			plazoSolicitado,
			plazoAprobado,
			aplicaGarantia,
			'01 - CONSUMO'
		);
		insert rla;
		return rla;
	}

	private static ResidentialLoanApplication buildRLA(
		Id accountId,
		DateTime fechaAprobacion,
		Boolean aprobadaPorComite,
		Decimal montoSolicitado,
		Decimal montoAprobado,
		Decimal plazoSolicitado,
		Decimal plazoAprobado,
		Boolean aplicaGarantia,
		String creditType
	) {
		ResidentialLoanApplication rla = new ResidentialLoanApplication();
		rla.AccountId = accountId;
		// Usa el tipo de registro real para que la garantía se presente según el producto.
		String recordTypeName = creditType != null && creditType.contains('MIPYME')
			? 'FSC_Solicitud_Credito_PYME'
			: creditType != null && creditType.contains('HIPOTECARIA')
				? 'FSC_Solicitud_Credito_Hipotecario'
				: creditType != null && creditType.contains('VEHICULO')
					? 'FSC_Solicitud_Credito_Vehiculo'
					: 'FSC_Solicitud_Credito_Consumo';
		Map<String, Schema.RecordTypeInfo> recordTypes =
			ResidentialLoanApplication.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
		if (recordTypes.containsKey(recordTypeName)) {
			rla.RecordTypeId = recordTypes.get(recordTypeName).getRecordTypeId();
		}
		rla.FSC_SolicitudAprobadaPorComite__c = aprobadaPorComite;
		rla.FSC_FechaYHoraAprobacionComite__c = fechaAprobacion;
		rla.Name = 'Test RLA ' + String.valueOf(fechaAprobacion);
		rla.FSC_Monto__c = montoSolicitado;
		rla.FSC_MontoAprobado__c = montoAprobado;
		rla.FSC_PlazoMeses__c = plazoSolicitado;
		rla.FSC_PlazoMesesAprobado__c = plazoAprobado;
		rla.FSC_TasaInteres__c = 12.34;
		rla.FSC_TasaInteresAprobada__c = 10.11;
		rla.FSC_Aplica_Garantia__c = aplicaGarantia;
		rla.FSC_DecisionComite__c = 'Aprobada con condición';
		rla.FSC_CondicionComite__c = 'COND';
		rla.FSC_ObservacionesComite__c = 'OBS';
		rla.FSC_Cuotas__c = 1;
		rla.FSC_TipoCredito__c = creditType;
		rla.FSC_Tipo_de_Garantia__c = 'Garantía Real';
		return rla;
	}

	private static void createGuarantee(Id rlaId, String assetType, Decimal value, String descripcion) {
		LoanApplicationAsset laa = new LoanApplicationAsset();
		laa.LoanApplicationId = rlaId;
		laa.AssetType = assetType;
		laa.CashOrMarketValue = value;
		laa.Name = 'Name ' + assetType;
		laa.FSC_Descripcion_de_la_Garantia__c = descripcion;
		insert laa;
	}

	private static void createFscGuarantee(Id rlaId) {
		insert new FSC_Garantia__c(Name = 'Garantía hipotecaria', FSC_Residential_Loan_Application__c = rlaId, FSC_Tipo_de_Garantia__c = 'Hipoteca');
	}

	@IsTest
	static void testController_withRecordsAndAssets() {
		Account acc = getTestAccount();

		Date actaDate = Date.today();
		DateTime dtInRange = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 12, 0, 0);

		ResidentialLoanApplication rla1 = createRLA(acc.Id, dtInRange, false, 1000, 900, 10, 9, true);

		createGuarantee(rla1.Id, 'HIPOTECA', 5000, 'Casa');
		createGuarantee(rla1.Id, 'PRENDA', 2000, 'Auto');
		update new ResidentialLoanApplication(Id = rla1.Id, FSC_SolicitudAprobadaPorComite__c = true);

		DateTime dtOutRange = dtInRange.addDays(-1);
		createRLA(acc.Id, dtOutRange, true, 2000, 1500, 12, 10, false);

		Test.startTest();
		PageReference pr = Page.FSC_ActaComitePDF;
		Test.setCurrentPage(pr);

		ApexPages.currentPage().getParameters().put('actaDate', String.valueOf(actaDate));
		ApexPages.currentPage().getParameters().put('actaNumero', 'NUM-TEST');
		ApexPages.currentPage().getParameters().put('horaInicio', '08:00');
		ApexPages.currentPage().getParameters().put('horaFin', '09:00');

		FSC_ActaComitePDFController ctrl = new FSC_ActaComitePDFController();
		Test.stopTest();

		Assert.areEqual('NUM-TEST', ctrl.actaNumero, 'Debe tomar actaNumero de params');
		Assert.isNotNull(ctrl.actaFecha, 'Debe calcular actaFecha');
		Assert.areEqual('08:00', ctrl.horaInicio, 'Debe tomar horaInicio de params');
		Assert.areEqual('09:00', ctrl.horaFin, 'Debe tomar horaFin de params');

		Assert.isNotNull(ctrl.textoQuorum, 'Debe construir el texto de quórum');
		Assert.isNotNull(ctrl.textoObjetivo, 'Debe construir el texto del objetivo');

		Assert.areEqual(1, ctrl.actas.size(), 'Solo debe incluir el RLA del día');

		FSC_ActaComitePDFController.ActaRow row = ctrl.actas[0];
		Assert.areEqual(1, row.numero, 'Debe numerar la primera solicitud');
		Assert.areEqual('Oficina Principal', row.sucursal, 'Debe mostrar la sucursal esperada');
		Assert.areEqual(TEST_ACCOUNT_NAME, row.nombreCliente, 'Debe mostrar el nombre del cliente');
		Assert.areEqual('Crédito Consumo con garantía', row.tipoFacilidad, 'LoanApplicationAsset debe contar como garantía');
		Assert.isTrue(row.montoSolicitado != null && row.montoSolicitado.startsWith('$ '), 'Debe formatear el monto solicitado');
		Assert.isTrue(row.montoAprobado != null && row.montoAprobado.startsWith('$ '), 'Debe formatear el monto aprobado');

		Assert.areEqual('HIPOTECA', row.garantiaPrincipal, 'Debe mostrar la garantía principal');
		Assert.isTrue(row.valorGarantiaPrincipal.startsWith('$ '), 'Debe formatear el valor de la garantía principal');
		Assert.areEqual('Casa', row.descGarantiaPrincipal, 'Debe mostrar la descripción de la garantía principal');

		Assert.areEqual('PRENDA', row.garantiaSecundaria, 'Debe mostrar la garantía secundaria');
		Assert.isTrue(row.valorGarantiaSecundaria.startsWith('$ '), 'Debe formatear el valor de la garantía secundaria');
		Assert.areEqual('Auto', row.descGarantiaSecundaria, 'Debe mostrar la descripción de la garantía secundaria');
	}

	@IsTest
	static void testController_noAssets_noCrash() {
		Account acc = getTestAccount();

		Date actaDate = Date.today();
		DateTime dtInRange = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 10, 0, 0);

		createRLA(acc.Id, dtInRange, true, 3000, 2500, 6, 6, false);

		Test.startTest();
		Test.setCurrentPage(Page.FSC_ActaComitePDF);
		ApexPages.currentPage().getParameters().put('actaDate', String.valueOf(actaDate));

		FSC_ActaComitePDFController ctrl = new FSC_ActaComitePDFController();
		Test.stopTest();

		Assert.areEqual(1, ctrl.actas.size(), 'Debe incluir la solicitud sin activos');
		FSC_ActaComitePDFController.ActaRow row = ctrl.actas[0];

		Assert.areEqual('Crédito Consumo sin garantía', row.tipoFacilidad, 'Sin registros hijos debe indicar sin garantía');
		Assert.areEqual('', row.garantiaPrincipal, 'No debe mostrar garantía principal');
		Assert.areEqual('', row.valorGarantiaPrincipal, 'No debe mostrar valor de garantía principal');
		Assert.areEqual('', row.descGarantiaPrincipal, 'No debe mostrar descripción de garantía principal');
		Assert.areEqual('', row.garantiaSecundaria, 'No debe mostrar garantía secundaria');
		Assert.areEqual('', row.valorGarantiaSecundaria, 'No debe mostrar valor de garantía secundaria');
		Assert.areEqual('', row.descGarantiaSecundaria, 'No debe mostrar descripción de garantía secundaria');
	}

	@IsTest
	static void testController_detectsFscGuaranteeForMortgage() {
		Account acc = getTestAccount();
		Date actaDate = Date.today();
		DateTime approvedAt = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 11, 0, 0);
		ResidentialLoanApplication mortgage = buildRLA(
			acc.Id,
			approvedAt,
			false,
			5000000,
			4500000,
			99,
			99,
			false,
			'04 - CONSUMO CON GARANTIA HIPOTECARIA'
		);
		insert mortgage;
		createFscGuarantee(mortgage.Id);
		update new ResidentialLoanApplication(Id = mortgage.Id, FSC_SolicitudAprobadaPorComite__c = true);

		Test.startTest();
		Test.setCurrentPage(Page.FSC_ActaComitePDF);
		ApexPages.currentPage().getParameters().put('actaDate', String.valueOf(actaDate));
		FSC_ActaComitePDFController ctrl = new FSC_ActaComitePDFController();
		Test.stopTest();

		Assert.areEqual(1, ctrl.actas.size(), 'Debe incluir la solicitud hipotecaria');
		Assert.areEqual(
			'Crédito Hipotecario con garantía',
			ctrl.actas[0].tipoFacilidad,
			'FSC_Garantia__c debe contar como garantía aunque FSC_Aplica_Garantia__c sea falso'
		);
	}

	@IsTest
	static void testController_missingApprovedValues_noCrash() {
		Account acc = getTestAccount();
		Date actaDate = Date.today();
		DateTime approvedAt = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 11, 30, 0);
		ResidentialLoanApplication application = buildRLA(
			acc.Id,
			approvedAt,
			true,
			1000001,
			null,
			null,
			null,
			false,
			'01 - CONSUMO'
		);
		insert application;

		Test.startTest();
		Test.setCurrentPage(Page.FSC_ActaComitePDF);
		ApexPages.currentPage().getParameters().put('actaDate', String.valueOf(actaDate));
		FSC_ActaComitePDFController ctrl = new FSC_ActaComitePDFController();
		Test.stopTest();

		Assert.areEqual(1, ctrl.actas.size(), 'Debe procesar la solicitud con datos de aprobación incompletos');
		FSC_ActaComitePDFController.ActaRow row = ctrl.actas[0];
		Assert.areEqual('', row.cuotaSolicitada, 'Sin plazo solicitado no debe calcular una cuota ficticia');
		Assert.areEqual('', row.montoAprobado, 'Sin monto aprobado debe dejar el valor vacío');
		Assert.areEqual('', row.cuotaAprobada, 'Sin monto ni plazo aprobados debe dejar la cuota vacía');
		Assert.areEqual('', row.plazoAprobado, 'Sin plazo aprobado debe dejar el valor vacío');
	}

	@IsTest
	static void testController_includesAndLabelsAllCreditTypes() {
		Account acc = getTestAccount();

		Date actaDate = Date.today();
		DateTime approvedAt = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 12, 0, 0);
		List<String> creditTypes = new List<String>{
			'01 - CONSUMO',
			'04 - CONSUMO CON GARANTIA HIPOTECARIA',
			'05 - CONSUMO CON GARANTIA DE VEHICULO',
			'06 - MIPYMES'
		};
		List<ResidentialLoanApplication> applications = new List<ResidentialLoanApplication>();
		for (Integer i = 0; i < creditTypes.size(); i++) {
			// Un crédito vehicular sin garantías no admite plazo aprobado (regla FSC_ValidarPlazoMaximoVehiculo).
			Decimal plazoAprobado = creditTypes[i].contains('VEHICULO') ? null : 12;
			applications.add(buildRLA(acc.Id, approvedAt.addSeconds(i), true, 1000, 900, 12, plazoAprobado, i > 0, creditTypes[i]));
		}
		insert applications;

		Test.startTest();
		Test.setCurrentPage(Page.FSC_ActaComitePDF);
		ApexPages.currentPage().getParameters().put('actaDate', String.valueOf(actaDate));
		FSC_ActaComitePDFController ctrl = new FSC_ActaComitePDFController();
		Test.stopTest();

		Assert.areEqual(creditTypes.size(), ctrl.actas.size(), 'El acta debe incluir todos los tipos de crédito');
		Set<String> renderedTypes = new Set<String>();
		for (FSC_ActaComitePDFController.ActaRow row : ctrl.actas) {
			renderedTypes.add(row.tipoFacilidad);
		}
		Assert.areEqual(
			new Set<String>{
				'Crédito Consumo sin garantía',
				'Crédito Hipotecario sin garantía',
				'Crédito Vehicular sin garantía',
				'Crédito PyMe sin garantía'
			},
			renderedTypes,
			'El tipo debe mapearse y la garantía debe depender de registros hijos, no de FSC_Aplica_Garantia__c'
		);
	}

	@IsTest
	static void testAuraInputsAndSimpleEdits() {
		Account acc = getTestAccount();
		Date actaDate = Date.today();
		DateTime approvedAt = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 13, 0, 0);
		createRLA(acc.Id, approvedAt, true, 1000, 900, 12, 12, false);

		FSC_ActaComitePDFController.ActaDocumentData data =
			FSC_ActaComitePDFController.getActaDocumentData(actaDate);
		Assert.isNotNull(data.seccionesActa, 'Debe devolver la estructura editable.');

		String changesJson = JSON.serialize(new Map<String, Object>{
			'actaNumero' => 'ACTA-EDITADA',
			'confirmacionRemota' => 'Confirmación simple',
			'rows' => new List<Object>{
				new Map<String, Object>{
					'sectionIndex' => 99,
					'rowIndex' => 0,
					'values' => new Map<String, String>{ 'sucursal' => 'Ignorada' }
				},
				new Map<String, Object>{
					'sectionIndex' => 0,
					'rowIndex' => 99,
					'values' => new Map<String, String>{ 'sucursal' => 'Ignorada' }
				},
				new Map<String, Object>{
					'sectionIndex' => 0,
					'rowIndex' => 0,
					'values' => new Map<String, String>{
						'numero' => '7',
						'sucursal' => 'Sucursal editada',
						'oficial' => 'Oficial editado',
						'nombreCliente' => 'Cliente editado',
						'tipoFacilidad' => 'Facilidad editada',
						'montoSolicitado' => '$ 1',
						'montoAprobado' => '$ 2',
						'cuotaSolicitada' => '$ 3',
						'plazoSolicitado' => '4',
						'tasaRefSolicitada' => '5%',
						'cuotaAprobada' => '$ 6',
						'plazoAprobado' => '7',
						'tasaRefAprobada' => '8%',
						'garantiaPrincipal' => 'Principal',
						'valorGarantiaPrincipal' => '$ 9',
						'descGarantiaPrincipal' => 'Descripción principal',
						'garantiaSecundaria' => 'Secundaria',
						'valorGarantiaSecundaria' => '$ 10',
						'descGarantiaSecundaria' => 'Descripción secundaria',
						'decisionComite' => 'Aprobada',
						'condicion' => 'Condición editada',
						'observaciones' => 'Observación editada'
					}
				}
			}
		});

		Test.setCurrentPage(Page.FSC_ActaComitePDF);
		ApexPages.currentPage().getParameters().put('actaDate', String.valueOf(actaDate));
		ApexPages.currentPage().getParameters().put('editData', changesJson);
		FSC_ActaComitePDFController controller = new FSC_ActaComitePDFController();
		Assert.areEqual('ACTA-EDITADA', controller.actaNumero, 'Debe aplicar la edición del encabezado.');
		Assert.areEqual(7, controller.seccionesActa[0].solicitudes[0].numero, 'Debe aplicar la edición de fila.');
		Assert.areEqual('Sucursal editada', controller.seccionesActa[0].solicitudes[0].sucursal);

		try {
			FSC_ActaComitePDFController.getActaDocumentData(null);
			Assert.fail('La fecha nula debe rechazarse.');
		} catch (AuraHandledException expected) {
			Assert.isNotNull(expected);
		}
		try {
			FSC_ActaComitePDFController.generateEditedPdf(actaDate, ' ');
			Assert.fail('Los cambios vacíos deben rechazarse.');
		} catch (AuraHandledException expected) {
			Assert.isNotNull(expected);
		}
		try {
			FSC_ActaComitePDFController.generateEditedPdf(actaDate, changesJson);
		} catch (AuraHandledException expectedInTestContext) {
			Assert.isNotNull(expectedInTestContext);
		}
	}
}