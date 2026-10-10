/**
 * Verifica la selección, composición y generación asíncrona de documentos de análisis de crédito.
 */
@IsTest
private with sharing class FSC_DocumentosAnalisisCreditoTest {
    static void asignarPermisosAdministrador() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet permiso = [SELECT Id FROM PermissionSet WHERE Name = 'FSC_PS_Administrador' LIMIT 1];
            // El usuario que ejecuta los tests puede tener ya el permission set asignado.
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permiso.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permiso.Id);
            }
        }
    }

	private static final String TIPO_CONSUMO = 'FSC_Solicitud_Credito_Consumo';
	private static final String TIPO_VEHICULO = 'FSC_Solicitud_Credito_Vehiculo';
	private static final String TIPO_HIPOTECARIO = 'FSC_Solicitud_Credito_Hipotecario';
	private static final String TIPO_PYME = 'FSC_Solicitud_Credito_PYME';
	private static final String ESTADO_EN_PROCESO = 'En proceso';
	private static final String SUBESTADO_ANTERIOR = 'En Motor Buró';
	private static final String SUBESTADO_ANALISIS = 'Análisis de crédito';
	private static final Integer CANTIDAD_SOLICITUDES_MASIVAS = 251;
	private static final Integer CANTIDAD_SOLICITUDES_ELEGIBLES = 5;

	@TestSetup
	static void prepararDatos() {
		asignarPermisosAdministrador();
		FSC_FabricaDatosDocumentosAnalisisTest.crearDatosBase();
	}

	@IsTest
	static void shouldGenerateTwoFiles_WhenConsumptionEntersAnalysis() {
		Account cuenta = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		ResidentialLoanApplication solicitud = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			cuenta.Id,
			TIPO_CONSUMO,
			ESTADO_EN_PROCESO,
			SUBESTADO_ANTERIOR,
			1000001,
			true
		);

		Test.startTest();
		solicitud.Status = ESTADO_EN_PROCESO;
		solicitud.FSC_Subestado__c = SUBESTADO_ANALISIS;
		update solicitud;
		Test.stopTest();

		Assert.areEqual(
			new Set<String>{ 'Capacidad de Pago - ' + solicitud.Name, 'Informe de Crédito de Consumo - ' + solicitud.Name },
			obtenerTitulos(solicitud.Id),
			'La transición real del trigger debe generar exactamente los dos documentos de consumo.'
		);
	}

	@IsTest
	static void shouldChooseExpectedReport_WhenEligibleCreditTypesAreProcessed() {
		Account cuenta = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		ResidentialLoanApplication consumoLimite = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			cuenta.Id,
			TIPO_CONSUMO,
			ESTADO_EN_PROCESO,
			SUBESTADO_ANALISIS,
			1000000,
			true
		);
		ResidentialLoanApplication vehiculo = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			cuenta.Id,
			TIPO_VEHICULO,
			ESTADO_EN_PROCESO,
			SUBESTADO_ANALISIS,
			1500000,
			true
		);
		ResidentialLoanApplication hipotecario = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			cuenta.Id,
			TIPO_HIPOTECARIO,
			ESTADO_EN_PROCESO,
			SUBESTADO_ANALISIS,
			3000000,
			true
		);

		Test.startTest();
		System.enqueueJob(new FSC_ColaGeneracionDocumentosAnalisis(new List<Id>{ consumoLimite.Id, vehiculo.Id, hipotecario.Id }));
		Test.stopTest();

		Assert.areEqual(
			new Set<String>{ 'Capacidad de Pago - ' + consumoLimite.Name, 'Informe de Crédito de Consumo - ' + consumoLimite.Name },
			obtenerTitulos(consumoLimite.Id),
			'El consumo sin garantía debe usar el informe de consumo sin importar el monto.'
		);
		Assert.areEqual(
			new Set<String>{ 'Capacidad de Pago - ' + vehiculo.Name, 'Informe de Crédito de Consumo - Vehículo - ' + vehiculo.Name },
			obtenerTitulos(vehiculo.Id),
			'El crédito vehicular debe usar el informe Consumo - Vehículo.'
		);
		Assert.areEqual(
			new Set<String>{ 'Capacidad de Pago - ' + hipotecario.Name, 'Informe de Crédito Hipotecario - ' + hipotecario.Name },
			obtenerTitulos(hipotecario.Id),
			'El crédito hipotecario debe usar el informe hipotecario.'
		);
	}

	@IsTest
	static void shouldAvoidDuplicatesAndSkipPyme_WhenQueueRunsAgain() {
		Account cuenta = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		ResidentialLoanApplication consumo = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			cuenta.Id,
			TIPO_CONSUMO,
			ESTADO_EN_PROCESO,
			SUBESTADO_ANALISIS,
			1200000,
			true
		);
		ResidentialLoanApplication pyme = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			cuenta.Id,
			TIPO_PYME,
			ESTADO_EN_PROCESO,
			SUBESTADO_ANALISIS,
			1200000,
			true
		);
		FSC_FabricaDatosDocumentosAnalisisTest.crearArchivo(consumo.Id, 'Capacidad de Pago - ' + consumo.Name);
		FSC_FabricaDatosDocumentosAnalisisTest.crearArchivo(consumo.Id, 'Informe de Crédito de Consumo - ' + consumo.Name);

		Test.startTest();
		System.enqueueJob(new FSC_ColaGeneracionDocumentosAnalisis(new List<Id>{ consumo.Id, pyme.Id }));
		Test.stopTest();

		Assert.areEqual(2, obtenerTitulos(consumo.Id).size(), 'La reejecución no debe duplicar archivos que ya existen por título.');
		Assert.areEqual(1, obtenerTitulos(pyme.Id).size(), 'El Queueable debe generar el informe PYME una sola vez.');
	}

	@IsTest
	static void shouldNotEnqueue_WhenServiceInputsAreNull() {
		Test.startTest();
		FSC_ServicioDocumentosAnalisisCredito.programarAlEntrarAnalisis(null, null);
		Assert.areEqual(0, Limits.getQueueableJobs(), 'Las entradas nulas no deben crear trabajos asíncronos.');
		Test.stopTest();
	}

	@IsTest
	static void shouldNotEnqueue_WhenRecordWasAlreadyInAnalysis() {
		Account cuenta = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		ResidentialLoanApplication solicitud = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			cuenta.Id,
			TIPO_CONSUMO,
			ESTADO_EN_PROCESO,
			SUBESTADO_ANALISIS,
			1200000,
			true
		);
		ResidentialLoanApplication anterior = solicitud.clone(true, true, false, false);
		ResidentialLoanApplication nueva = solicitud.clone(true, true, false, false);

		Test.startTest();
		FSC_ServicioDocumentosAnalisisCredito.programarAlEntrarAnalisis(
			new List<ResidentialLoanApplication>{ nueva },
			new Map<Id, ResidentialLoanApplication>{ anterior.Id => anterior }
		);
		Assert.areEqual(0, Limits.getQueueableJobs(), 'Permanecer en la etapa no debe volver a programar documentos.');
		Test.stopTest();
	}

	@IsTest
	static void shouldNotEnqueue_WhenPymeEntersAnalysis() {
		Account cuenta = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		ResidentialLoanApplication solicitud = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			cuenta.Id,
			TIPO_PYME,
			ESTADO_EN_PROCESO,
			SUBESTADO_ANTERIOR,
			1200000,
			true
		);
		ResidentialLoanApplication anterior = solicitud.clone(true, true, false, false);
		ResidentialLoanApplication nueva = solicitud.clone(true, true, false, false);
		nueva.Status = ESTADO_EN_PROCESO;
		nueva.FSC_Subestado__c = SUBESTADO_ANALISIS;

		Test.startTest();
		FSC_ServicioDocumentosAnalisisCredito.programarAlEntrarAnalisis(
			new List<ResidentialLoanApplication>{ nueva },
			new Map<Id, ResidentialLoanApplication>{ anterior.Id => anterior }
		);
		Assert.areEqual(1, Limits.getQueueableJobs(), 'La entrada de un crédito PYME debe iniciar la generación del informe.');
		Test.stopTest();
	}

	@IsTest
	static void shouldEnqueueSingleInitialJob_WhenProcessing251Records() {
		Account cuenta = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		List<ResidentialLoanApplication> solicitudes = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitudes(
			cuenta.Id,
			CANTIDAD_SOLICITUDES_MASIVAS,
			TIPO_CONSUMO,
			ESTADO_EN_PROCESO,
			SUBESTADO_ANTERIOR,
			1200000,
			true
		);
		List<ResidentialLoanApplication> nuevas = new List<ResidentialLoanApplication>();
		Map<Id, ResidentialLoanApplication> anterioresPorId = new Map<Id, ResidentialLoanApplication>();
		Integer indice = 0;
		for (ResidentialLoanApplication solicitud : solicitudes) {
			ResidentialLoanApplication anterior = solicitud.clone(true, true, false, false);
			ResidentialLoanApplication nueva = solicitud.clone(true, true, false, false);
			if (indice < CANTIDAD_SOLICITUDES_ELEGIBLES) {
				nueva.FSC_Subestado__c = SUBESTADO_ANALISIS;
			}
			anterioresPorId.put(anterior.Id, anterior);
			nuevas.add(nueva);
			indice++;
		}

		Test.startTest();
		FSC_ServicioDocumentosAnalisisCredito.programarAlEntrarAnalisis(nuevas, anterioresPorId);
		Assert.areEqual(1, Limits.getQueueableJobs(), 'Una entrada masiva debe consolidarse en un único Queueable inicial.');
		Test.stopTest();
	}

	@IsTest
	static void shouldMapStructuredData_WhenMortgageHasRelatedRecords() {
		Account cuenta = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		ResidentialLoanApplication solicitud = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			cuenta.Id,
			TIPO_HIPOTECARIO,
			ESTADO_EN_PROCESO,
			SUBESTADO_ANALISIS,
			2000000,
			true
		);
		LoanApplicant deudor = FSC_FabricaDatosDocumentosAnalisisTest.crearParticipante(solicitud.Id, 'Deudor', 'Ana Deudora', 100000, 0);
		LoanApplicant codeudor = FSC_FabricaDatosDocumentosAnalisisTest.crearParticipante(solicitud.Id, 'Co-Deudor', 'Carlos Codeudor', 50000, 0);
		LoanApplicant garante = FSC_FabricaDatosDocumentosAnalisisTest.crearParticipante(solicitud.Id, 'Garante', 'Gloria Garante', 900000, 0);
		FSC_FabricaDatosDocumentosAnalisisTest.crearIngreso(solicitud.Id, deudor.Id, 100000);
		FSC_FabricaDatosDocumentosAnalisisTest.crearIngreso(solicitud.Id, codeudor.Id, 50000);
		FSC_FabricaDatosDocumentosAnalisisTest.crearIngreso(solicitud.Id, garante.Id, 900000);
		FSC_FabricaDatosDocumentosAnalisisTest.crearEmpleo(solicitud.Id, deudor.Id, 3, 4);
		FSC_FabricaDatosDocumentosAnalisisTest.crearDeuda(solicitud.Id, 100000, 10000, false);
		FSC_FabricaDatosDocumentosAnalisisTest.crearDeuda(solicitud.Id, 20000, 2000, true);
		FSC_FabricaDatosDocumentosAnalisisTest.crearActivo(solicitud.Id, 700000);
		FSC_FabricaDatosDocumentosAnalisisTest.crearGarantiaHipotecaria(solicitud.Id, 5000000, 4700000);
		insert new List<FSC_Excepcion__c>{
			FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 1, 'Aprobada', null),
			FSC_ExcepcionTestDataFactory.buildExcepcion(solicitud.Id, 2, 'Pendiente', 'Presentar avalúo actualizado')
		};
		Test.setCurrentPage(Page.FSC_InformeCreditoAnalisisPDF);
		ApexPages.currentPage().getParameters().put('id', solicitud.Id);

		Test.startTest();
		FSC_ControladorDocumentosAnalisisCredito controlador = new FSC_ControladorDocumentosAnalisisCredito();
		Test.stopTest();

		FSC_DatosDocumentosAnalisisCredito datos = controlador.datos;
		Assert.areEqual('Hipotecario', datos.tipoPrestamo, 'Debe reconocer el Record Type hipotecario.');
		Assert.isTrue(datos.esHipotecario, 'Debe activar la plantilla hipotecaria.');
		Assert.isFalse(datos.esVehiculo, 'Una hipoteca no debe activar la plantilla vehicular.');
		Assert.areEqual('Ana Deudora', datos.solicitante, 'El deudor principal debe ser el solicitante mostrado.');
		Assert.areEqual(formatearDinero(150000), datos.totalIngresos, 'Debe sumar deudor y co-deudor, excluyendo al garante.');
		Assert.areEqual('3 años, 4 meses', datos.antiguedadLaboral, 'Debe formatear la antigüedad del empleo principal.');
		Assert.areEqual('', datos.evidenciaIngresos, 'No debe inferir evidencia documental desde el tipo de ingreso.');
		Assert.areEqual(formatearDinero(120000), datos.totalAdeudado, 'Debe sumar los balances de obligaciones estándar.');
		Assert.areEqual(formatearDinero(22000), datos.totalPagosCreditos, 'Debe descontar la cuota de la deuda marcada para cancelar.');
		Assert.areEqual(formatearDinero(37000), datos.totalPagos, 'Debe incluir el alquiler registrado en los pagos totales.');
		Assert.areEqual('Hipotecaria', datos.garantiaTipo, 'Debe usar el tipo de la garantía relacionada.');
		Assert.areEqual('Santo Domingo', datos.garantiaUbicacion, 'Debe mapear la ubicación de la garantía hipotecaria.');
		Assert.areEqual(formatearDinero(5000000), datos.garantiaValorTasacion, 'Debe mostrar el valor tasado estructurado.');
		Assert.areEqual(formatearPorcentaje(0.40), datos.prestamoSobreTasacion, 'Debe calcular préstamo sobre tasación.');
		Assert.areEqual('A', datos.clasificacionRiesgo, 'Debe priorizar la clasificación almacenada en el RLA.');
		Assert.isTrue(datos.excepciones.contains('Detalle de prueba 1'), 'Debe incluir la primera excepción hija en el documento.');
		Assert.isTrue(datos.excepciones.contains('Detalle de prueba 2'), 'Debe incluir la segunda excepción hija en el documento.');
		Assert.isTrue(datos.excepciones.contains('Presentar avalúo actualizado'), 'Debe incluir condiciones del nuevo modelo.');
	}

	@IsTest
	static void shouldUseApplicantAndExternalFacilityFallbacks_WhenStandardRowsAreMissing() {
		Account cuenta = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		ResidentialLoanApplication solicitud = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			cuenta.Id,
			TIPO_CONSUMO,
			ESTADO_EN_PROCESO,
			SUBESTADO_ANALISIS,
			900000,
			true
		);
		LoanApplicant deudor = FSC_FabricaDatosDocumentosAnalisisTest.crearParticipante(solicitud.Id, 'Deudor', 'Daniel Deudor', 100000, 5000);
		FSC_FabricaDatosDocumentosAnalisisTest.crearTarjetaExterna(deudor.Id, 100000);
		Test.setCurrentPage(Page.FSC_CapacidadPagoPDF);
		ApexPages.currentPage().getParameters().put('id', solicitud.Id);

		Test.startTest();
		FSC_ControladorDocumentosAnalisisCredito controlador = new FSC_ControladorDocumentosAnalisisCredito();
		Test.stopTest();

		FSC_DatosDocumentosAnalisisCredito datos = controlador.datos;
		Assert.isFalse(datos.esVehiculo, 'Un consumo sin garantía no debe usar la variante Consumo - Vehículo.');
		Assert.areEqual(formatearDinero(105000), datos.totalIngresos, 'Sin filas de ingreso debe usar los campos del deudor.');
		Assert.areEqual(formatearDinero(100000), datos.deudaTarjetas, 'Debe usar la facilidad externa cuando no existen obligaciones estándar.');
		Assert.areEqual(formatearDinero(8000), datos.cuotaTarjetas, 'Debe calcular el 8% del balance de la tarjeta externa.');
		Assert.areEqual(formatearDinero(20000), datos.totalPagosCreditos, 'Debe sumar pago mínimo de tarjeta y cuota nueva.');
	}

	@IsTest
	static void shouldKeepDefaultData_WhenPageIdIsInvalid() {
		Test.setCurrentPage(Page.FSC_InformeCreditoAnalisisPDF);
		ApexPages.currentPage().getParameters().put('id', 'identificador-invalido');

		Test.startTest();
		FSC_ControladorDocumentosAnalisisCredito controlador = new FSC_ControladorDocumentosAnalisisCredito();
		Test.stopTest();

		Assert.isNull(controlador.datos.numeroSolicitud, 'Un Id inválido no debe intentar cargar una solicitud.');
		Assert.isFalse(controlador.datos.esVehiculo, 'El DTO debe conservar la bandera vehicular apagada.');
		Assert.isFalse(controlador.datos.esHipotecario, 'El DTO debe conservar la bandera hipotecaria apagada.');
	}

	@IsTest
	static void shouldReturnEmptyResults_WhenSelectorInputsAreNull() {
		Test.startTest();
		ResidentialLoanApplication solicitud = FSC_ConsultaDocumentosAnalisisCredito.seleccionarSolicitud(null);
		Account cuenta = FSC_ConsultaDocumentosAnalisisCredito.seleccionarCuenta(null);
		List<LoanApplicant> participantes = FSC_ConsultaDocumentosAnalisisCredito.seleccionarParticipantes(null);
		LoanApplicantEmployment empleo = FSC_ConsultaDocumentosAnalisisCredito.seleccionarEmpleo(null);
		List<LoanApplicantIncome> ingresos = FSC_ConsultaDocumentosAnalisisCredito.seleccionarIngresos(null);
		List<LoanApplicationLiability> deudas = FSC_ConsultaDocumentosAnalisisCredito.seleccionarDeudas(null);
		List<FSC_Facilidad_Otra_Institucion__c> facilidades = FSC_ConsultaDocumentosAnalisisCredito.seleccionarFacilidadesExternas(null);
		List<LoanApplicationAsset> activos = FSC_ConsultaDocumentosAnalisisCredito.seleccionarActivos(null);
		List<FSC_Garantia__c> garantias = FSC_ConsultaDocumentosAnalisisCredito.seleccionarGarantias(null);
		List<FSC_Excepcion__c> excepciones = FSC_ConsultaDocumentosAnalisisCredito.seleccionarExcepciones(null);
		Test.stopTest();

		Assert.isNull(solicitud, 'Una solicitud nula debe devolver null.');
		Assert.isNull(cuenta, 'Una cuenta nula debe devolver null.');
		Assert.isTrue(participantes.isEmpty(), 'No debe devolver participantes para una solicitud nula.');
		Assert.isNull(empleo, 'Un participante nulo no debe devolver empleo.');
		Assert.isTrue(ingresos.isEmpty(), 'No debe devolver ingresos para una solicitud nula.');
		Assert.isTrue(deudas.isEmpty(), 'No debe devolver deudas para una solicitud nula.');
		Assert.isTrue(facilidades.isEmpty(), 'No debe devolver facilidades para participantes nulos.');
		Assert.isTrue(activos.isEmpty(), 'No debe devolver activos para una solicitud nula.');
		Assert.isTrue(garantias.isEmpty(), 'No debe devolver garantías para una solicitud nula.');
		Assert.isTrue(excepciones.isEmpty(), 'No debe devolver excepciones para una solicitud nula.');
	}

	@IsTest
	static void shouldDoNothing_WhenQueueReceivesNullIds() {
		Integer archivosAntes = [SELECT COUNT() FROM ContentVersion];

		Test.startTest();
		new FSC_ColaGeneracionDocumentosAnalisis(null).execute(null);
		Test.stopTest();

		Assert.areEqual(archivosAntes, [SELECT COUNT() FROM ContentVersion], 'Una cola sin solicitudes no debe publicar archivos.');
	}

	@IsTest
	static void shouldSaveEditedValuesAndVersionOnlySelectedDocument() {
		Account cuenta = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		ResidentialLoanApplication solicitud = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			cuenta.Id,
			TIPO_CONSUMO,
			ESTADO_EN_PROCESO,
			SUBESTADO_ANALISIS,
			900000,
			true
		);
		solicitud.FSC_Resultado_Buro__c = 'Referido';
		solicitud.FSC_Doc_Completa_Analisis__c = true;
		solicitud.FSC_DocumentacionValidadaAnalista__c = true;
		solicitud.FSC_DebeRevisarComite__c = false;
		solicitud.FSC_DebeRevisarSupervisor__c = false;
		solicitud.FSC_Aprobado_con_Condiciones__c = false;
		update solicitud;

		ContentVersion informe = FSC_FabricaDatosDocumentosAnalisisTest.crearArchivo(
			solicitud.Id,
			'Informe de Crédito de Consumo - Vehículo - ' + solicitud.Name
		);
		ContentVersion capacidad = FSC_FabricaDatosDocumentosAnalisisTest.crearArchivo(solicitud.Id, 'Capacidad de Pago - ' + solicitud.Name);
		informe = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :informe.Id];
		capacidad = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :capacidad.Id];
		FSC_RlaAccionesController.testPermitirEdicionDocumentosAnalisis = true;
		Map<String, Object> cambios = new Map<String, Object>{
			'historialPago' => new Map<String, Object>{ 'value' => 'Historial corregido por el analista', 'format' => 'text' }
		};

		Test.startTest();
		FSC_RlaAccionesController.guardarYRegenerarDocumentoAnalisis(
			solicitud.Id,
			FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME,
			JSON.serialize(cambios)
		);
		Test.stopTest();

		ResidentialLoanApplication actualizada = [SELECT FSC_PlazoMeses__c FROM ResidentialLoanApplication WHERE Id = :solicitud.Id];
		Assert.areEqual(60, actualizada.FSC_PlazoMeses__c, 'Editar el PDF no debe modificar el plazo ni ningún campo del RLA.');
		ContentVersion informeActual = [
			SELECT FSC_DatosEditadosAnalisis__c
			FROM ContentVersion
			WHERE ContentDocumentId = :informe.ContentDocumentId AND IsLatest = true
			LIMIT 1
		];
		Assert.isTrue(
			!String.isBlank(informeActual.FSC_DatosEditadosAnalisis__c) &&
				informeActual.FSC_DatosEditadosAnalisis__c.contains('Historial corregido por el analista'),
			'Los ajustes deben conservarse únicamente en la versión del PDF.'
		);

		Map<String, Object> datos = FSC_ControladorDocumentosAnalisisCredito.construirDatos(
			solicitud.Id,
			FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME
		);
		Assert.areEqual('Historial corregido por el analista', datos.get('historialPago'), 'El texto editado debe llegar a Visualforce.');
		Assert.areEqual(
			2,
			[SELECT COUNT() FROM ContentVersion WHERE ContentDocumentId = :informe.ContentDocumentId],
			'El informe debe reemplazarse mediante una nueva versión del mismo archivo.'
		);
		Assert.areEqual(
			1,
			[SELECT COUNT() FROM ContentVersion WHERE ContentDocumentId = :capacidad.ContentDocumentId],
			'Editar el informe no debe modificar capacidad de pago.'
		);
	}

	@IsTest
	static void shouldRejectDocumentEditingOutsideEligibleStageAndInvalidNumbers() {
		Account cuenta = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		ResidentialLoanApplication solicitud = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			cuenta.Id,
			TIPO_CONSUMO,
			ESTADO_EN_PROCESO,
			SUBESTADO_ANTERIOR,
			900000,
			true
		);
		FSC_RlaAccionesController.testPermitirEdicionDocumentosAnalisis = true;
		Boolean rechazoEtapa = false;
		try {
			FSC_RlaAccionesController.getDatosDocumentoAnalisis(solicitud.Id, FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME);
		} catch (AuraHandledException error) {
			rechazoEtapa = true;
		}
		Assert.isTrue(rechazoEtapa, 'No debe permitir edición antes de la etapa de decisión del analista.');

		solicitud.FSC_Subestado__c = SUBESTADO_ANALISIS;
		solicitud.FSC_Resultado_Buro__c = 'Referido';
		solicitud.FSC_Doc_Completa_Analisis__c = true;
		solicitud.FSC_DocumentacionValidadaAnalista__c = true;
		solicitud.FSC_DebeRevisarComite__c = false;
		solicitud.FSC_DebeRevisarSupervisor__c = false;
		solicitud.FSC_Aprobado_con_Condiciones__c = false;
		update solicitud;
		Boolean rechazoNumero = false;
		try {
			FSC_RlaAccionesController.guardarYRegenerarDocumentoAnalisis(
				solicitud.Id,
				FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME,
				JSON.serialize(
					new Map<String, Object>{
						'plazoMeses' => new Map<String, Object>{ 'value' => 'ABC', 'format' => 'integer' }
					}
				)
			);
		} catch (AuraHandledException error) {
			rechazoNumero = true;
		}
		Assert.isTrue(rechazoNumero, 'El servidor debe rechazar un plazo no numérico aunque se evada la validación del modal.');
	}

	@IsTest
	static void shouldCalculateCapacityTotalsFromEditableCurrencies() {
		Account cuenta = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		ResidentialLoanApplication solicitud = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			cuenta.Id,
			TIPO_CONSUMO,
			ESTADO_EN_PROCESO,
			SUBESTADO_ANALISIS,
			900000,
			true
		);
		solicitud.FSC_Resultado_Buro__c = 'Referido';
		solicitud.FSC_Doc_Completa_Analisis__c = true;
		solicitud.FSC_DocumentacionValidadaAnalista__c = true;
		solicitud.FSC_DebeRevisarComite__c = false;
		solicitud.FSC_DebeRevisarSupervisor__c = false;
		solicitud.FSC_Aprobado_con_Condiciones__c = false;
		update solicitud;

		ContentVersion capacidad = FSC_FabricaDatosDocumentosAnalisisTest.crearArchivo(
			solicitud.Id,
			'Capacidad de Pago - ' + solicitud.Name
		);
		capacidad = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :capacidad.Id];
		FSC_RlaAccionesController.testPermitirEdicionDocumentosAnalisis = true;
		Map<String, Object> cambios = new Map<String, Object>{
			'montosPesos.ingresoCartaTrabajo' => new Map<String, Object>{ 'value' => '1000', 'format' => 'moneyDop' },
			'montosDolares.ingresoDepositos' => new Map<String, Object>{ 'value' => '10', 'format' => 'moneyUsd' },
			'montosPesos.ingresoAlquiler' => new Map<String, Object>{ 'value' => '500', 'format' => 'moneyDop' },
			'montosPesos.cuotaPrestamos' => new Map<String, Object>{ 'value' => '200', 'format' => 'moneyDop' },
			'montosPesos.cuotaNuevoPrestamo' => new Map<String, Object>{ 'value' => '300', 'format' => 'moneyDop' },
			'montosPesos.cuotasCancelar' => new Map<String, Object>{ 'value' => '50', 'format' => 'moneyDop' },
			'montosPesos.pagoVivienda' => new Map<String, Object>{ 'value' => '400', 'format' => 'moneyDop' }
		};

		Test.startTest();
		FSC_RlaAccionesController.guardarYRegenerarDocumentoAnalisis(
			solicitud.Id,
			FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_CAPACIDAD,
			JSON.serialize(cambios)
		);
		Test.stopTest();

		ContentVersion versionActual = [
			SELECT FSC_DatosEditadosAnalisis__c
			FROM ContentVersion
			WHERE ContentDocumentId = :capacidad.ContentDocumentId AND IsLatest = true
			LIMIT 1
		];
		Map<String, Object> ajustes = (Map<String, Object>) JSON.deserializeUntyped(
			versionActual.FSC_DatosEditadosAnalisis__c
		);
		Map<String, Object> montosPesos = (Map<String, Object>) ajustes.get('montosPesos');
		Map<String, Object> montosDolares = (Map<String, Object>) ajustes.get('montosDolares');
		Map<String, Object> totalesPesos = (Map<String, Object>) ajustes.get('totalesPesos');

		Assert.isNotNull(montosPesos.get('totalIngresos'), 'Debe recalcular el total de ingresos en pesos.');
		Assert.isNotNull(montosDolares.get('totalIngresos'), 'Debe recalcular el total de ingresos en dólares.');
		Assert.isNotNull(totalesPesos.get('totalIngresos'), 'Debe recalcular el total consolidado en pesos.');
		Assert.isNotNull(montosPesos.get('totalPagos'), 'Debe recalcular el total de pagos.');
	}

	@IsTest
	static void shouldReplaceOnlyCapacity_WhenTargetDocumentIsCapacity() {
		Account cuenta = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		ResidentialLoanApplication solicitud = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			cuenta.Id,
			TIPO_VEHICULO,
			ESTADO_EN_PROCESO,
			SUBESTADO_ANALISIS,
			1200000,
			true
		);
		ContentVersion informe = FSC_FabricaDatosDocumentosAnalisisTest.crearArchivo(
			solicitud.Id,
			'Informe de Crédito de Consumo - Vehículo - ' + solicitud.Name
		);
		ContentVersion capacidad = FSC_FabricaDatosDocumentosAnalisisTest.crearArchivo(solicitud.Id, 'Capacidad de Pago - ' + solicitud.Name);
		informe = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :informe.Id];
		capacidad = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :capacidad.Id];

		Test.startTest();
		new FSC_ColaGeneracionDocumentosAnalisis(
			new List<Id>{ solicitud.Id },
			FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_CAPACIDAD
		).execute(null);
		Test.stopTest();

		Assert.areEqual(
			2,
			[SELECT COUNT() FROM ContentVersion WHERE ContentDocumentId = :capacidad.ContentDocumentId],
			'Capacidad de pago debe recibir una nueva versión.'
		);
		Assert.areEqual(
			1,
			[SELECT COUNT() FROM ContentVersion WHERE ContentDocumentId = :informe.ContentDocumentId],
			'El informe debe conservarse sin cambios.'
		);
	}

	@IsTest
	static void shouldValidateQueueDocumentTargetAndBooleanCompatibilityConstructor() {
		Boolean rechazoTipo = false;
		try {
			new FSC_ColaGeneracionDocumentosAnalisis(new List<Id>(), 'DOCUMENTO_DESCONOCIDO');
		} catch (FSC_ColaGeneracionDocumentosAnalisis.FSC_ErrorGeneracionDocumentoException error) {
			rechazoTipo = true;
		}
		Assert.isTrue(rechazoTipo, 'La cola debe rechazar un tipo de documento desconocido.');

		Test.startTest();
		new FSC_ColaGeneracionDocumentosAnalisis(null, false).execute(null);
		new FSC_ColaGeneracionDocumentosAnalisis(new List<Id>(), 0).execute(null);
		Test.stopTest();
	}

	@IsTest
	static void shouldAppendAndLimitQueueErrors() {
		Id solicitudId = UserInfo.getUserId();
		Map<Id, String> logActual = new Map<Id, String>{ solicitudId => 'Anterior' };
		Map<Id, String> logPendiente = new Map<Id, String>();

		FSC_ColaGeneracionDocumentosAnalisis.registrarError(logActual, logPendiente, solicitudId, 'Primero');
		FSC_ColaGeneracionDocumentosAnalisis.registrarError(logActual, logPendiente, solicitudId, 'Segundo');

		System.assert(logPendiente.get(solicitudId).contains('Anterior'));
		System.assertEquals('', FSC_ColaGeneracionDocumentosAnalisis.limitar('', 10));
		System.assertEquals('123...', FSC_ColaGeneracionDocumentosAnalisis.limitar('12345', 3));
	}

	private static Set<String> obtenerTitulos(Id solicitudId) {
		Set<String> titulos = new Set<String>();
		for (ContentDocumentLink enlace : [
			SELECT ContentDocument.Title
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :solicitudId
			WITH USER_MODE
		]) {
			// La planilla "Crédito <tipo> - ..." la regenera otro proceso; aquí solo cuentan los documentos de análisis.
			if (enlace.ContentDocument.Title.startsWith('Crédito ')) {
				continue;
			}
			titulos.add(enlace.ContentDocument.Title);
		}
		return titulos;
	}

	private static String formatearDinero(Decimal valor) {
		return 'RD$ ' + valor.setScale(2).format();
	}

	private static String formatearDolares(Decimal valor) {
		return 'US$ ' + valor.setScale(2).format();
	}

	private static String formatearPorcentaje(Decimal valor) {
		return (valor * 100).setScale(2).format() + '%';
	}
}