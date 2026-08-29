@IsTest
	private class FSC_ConsumoSolicitudPDFController_Test {
		private static void setupPersonAccountMock() {
			Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
		}

		@IsTest
		static void testControllerLoadsPdfSections() {
			Account account = new Account();
		Id personRtId = getPersonAccountRecordTypeId();

		if (personRtId != null) {
			account.RecordTypeId = personRtId;
		}
		account.FirstName = 'Ana';
		account.LastName = 'Garcia Perez';

		Map<String, Schema.SObjectField> accountFieldMap = Schema.SObjectType.Account.fields.getMap();
		setIfFieldExists(account, accountFieldMap, 'MiddleName', 'Maria');
		setIfFieldExists(account, accountFieldMap, 'PersonBirthdate', Date.newInstance(1990, 5, 20));
		setIfFieldExists(account, accountFieldMap, 'PersonEmail', 'ana.garcia@vimenca.com');
		setIfFieldExists(account, accountFieldMap, 'PersonHomePhone', '8095551000');
		setIfFieldExists(account, accountFieldMap, 'PersonMobilePhone', '8295552000');
		setIfFieldExists(account, accountFieldMap, 'ACC_Telefono_Movil__c', '8295552000');
		setIfFieldExists(account, accountFieldMap, 'ACC_TipoIdentificacion__c', 'Cédula');
		setIfFieldExists(account, accountFieldMap, 'ACC_NumIdentificacion__c', '00100000000');
		setIfFieldExists(account, accountFieldMap, 'ACC_Nacionalidad__c', 'REPUBLICA DOMINICANA');
		setIfFieldExists(account, accountFieldMap, 'ACC_Estado_Civil__c', 'SOLTERO/A');
		setIfFieldExists(account, accountFieldMap, 'Tipo_de_vivienda__c', '3');
		setIfFieldExists(account, accountFieldMap, 'ACC_N_Dependientes__c', 2);
		setIfFieldExists(account, accountFieldMap, 'BillingStreet', 'C/ Primera #10');
			setIfFieldExists(account, accountFieldMap, 'BillingCity', 'Santo Domingo');
			setIfFieldExists(account, accountFieldMap, 'BillingCountry', 'Republica Dominicana');

			setupPersonAccountMock();
			insert account;

		SObject rla = Schema.getGlobalDescribe().get('ResidentialLoanApplication').newSObject();
		rla.put('AccountId', account.Id);
		rla.put('Name', 'SC-0001');
		Id consumoRtId = getRlaRecordTypeId('FSC_Solicitud_Credito_Consumo');
		if (consumoRtId != null) {
			rla.put('RecordTypeId', consumoRtId);
		}

		Map<String, Schema.SObjectField> rlaFieldMap = Schema.SObjectType.ResidentialLoanApplication.fields.getMap();
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Sucursal__c', 'Sucursal Central');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_TipoCredito__c', 'Consumo');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Tipo_de_solicitud__c', 'Disminución de Garantía');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Destino_del_Prestamo__c', 'Consolidacion de deudas');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Moneda__c', '1');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Monto__c', 250000);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_MontoAprobado__c', 200000);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_MontoDesembolsar__c', 190000);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Plazo_meses__c', '24');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_TasaInteres__c', 16.5);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_FormaPago__c', 'Debito automatico');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_EsRefinanciamiento__c', true);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_EsConsolidacionDeudas__c', false);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_TipoDeudaCancelar__c', 'Préstamos y Tarjetas');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Aplica_Garantia__c', true);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_TipoGarantia__c', 'Solidaria');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Valor_de_la_Garantia__c', 300000);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Descripcion_de_la_Garantia__c', 'Fiador solidario');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Observaciones__c', 'Cliente con buen historial.');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Nombre_del_negocio__c', 'Negocio Ana');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Cargo__c', 'Administradora');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Actividad_economica__c', 'Servicios');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Tiempo_laborando__c', 5);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Ingresos_Mensuales__c', 80000);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Monto_de_los_Ingresos__c', 5000);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Telefono__c', '8095551000');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Correo_Electronico__c', 'ana.garcia@vimenca.com');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Direccion_del_Negocio__c', 'Av. 27 de Febrero #5');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_NumeroCliente__c', 'CLI-0001');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_DescripcionPropositoFacilidad__c', 'Compra de muebles');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Numero__c', 1);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Tipo_de_Facilidad__c', 'CONSUMO');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Prestamo_Con_Garantia__c', true);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Monto_Solicitado__c', 250000);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Forma_De_Pago__c', 'Debito automatico');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Tasa__c', 16.5);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Tasa_Fija__c', true);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Monto_De_La_Cuota__c', 13000);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Tiempo_Tasa_Fija__c', 12);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Deuda_Actual__c', 50000);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Descripcion_Proposito_Facilidad__c', 'Compra de muebles');
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Compromiso_Mensual__c', 13000);
		setIfFieldExists(rla, rlaFieldMap, 'FSC_Limite_Autorizado__c', 250000);

		insert rla;

		Id rlaId = (Id) rla.get('Id');

		Id applicantId = insertIfPossible(
			'LoanApplicant',
			new Map<String, Object>{
				'Name' => 'Ana Maria Garcia Perez',
				'LoanApplicationId' => rlaId,
				'FSC_TipoSolicitante__c' => 'Deudor',
				'FSC_TipoIdentificacion__c' => 'Cédula',
				'FSC_NumIdentificacion__c' => '00100000000',
				'FSC_Nombre__c' => 'Ana Maria',
				'FSC_PrimerApellido__c' => 'Garcia',
				'FSC_SegundoApellido__c' => 'Perez',
				'FSC_FechaNacimiento__c' => Date.newInstance(1990, 5, 20),
				'FSC_Nacionalidad__c' => 'REPUBLICA DOMINICANA',
				'FSC_EstadoCivil__c' => 'SOLTERO/A',
				'FSC_NumeroDependientes__c' => 2,
				'FSC_ClasificacionSIB__c' => 'A',
				'FSC_Ocupacion__c' => 'OFICIAL',
				'FSC_FuenteIngreso__c' => 'Empleado Privado',
				'FSC_LugarFondeLabora__c' => 'Banco Vimenca',
				'FSC_TipoNegocio__c' => 'Servicios',
				'FSC_IngresosMensuales__c' => 85000,
				'FSC_OtrosIngresos__c' => 5000,
				'FSC_EmpresaAnteriorLaboro__c' => 'Empresa XYZ',
				'FSC_MontoPrestacionesLaborales__c' => '15000',
				'FSC_DescripcionOtrosIngresos__c' => 'Comisiones'
			}
		);

		if (applicantId != null) {
			insertIfPossible(
				'LoanApplicantEmployment',
				new Map<String, Object>{
					'Name' => 'Empleo Ana Garcia',
					'LoanApplicantId' => applicantId,
					'EmployerName' => 'Banco Vimenca',
					'EmployerAddress' => 'Av. Sarasota #20',
					'JobTitle' => 'Analista Senior',
					'CurrentJobYearCount' => 3,
					'CurrentJobAdditionalMonthCount' => 6,
					'MonthlyTotalIncomeAmount' => 85000
				}
			);

			insertIfPossible(
				'LoanApplicantAddress',
				new Map<String, Object>{ 'LoanApplicantId' => applicantId, 'ResidenceAddress' => 'C/ Primera #10, Santo Domingo' }
			);
		}

		Id coApplicantId = insertIfPossible(
			'LoanApplicant',
			new Map<String, Object>{
				'Name' => 'Luis Alberto Diaz Lopez',
				'LoanApplicationId' => rlaId,
				'FSC_TipoSolicitante__c' => 'Co-Deudor',
				'FSC_TipoIdentificacion__c' => 'Cédula',
				'FSC_NumIdentificacion__c' => '00200000000',
				'FSC_Nombre__c' => 'Luis Alberto',
				'FSC_PrimerApellido__c' => 'Diaz',
				'FSC_SegundoApellido__c' => 'Lopez',
				'FSC_FechaNacimiento__c' => Date.newInstance(1988, 10, 15),
				'FSC_Nacionalidad__c' => 'REPUBLICA DOMINICANA',
				'FSC_EstadoCivil__c' => 'CASADO/A',
				'FSC_NumeroDependientes__c' => 1,
				'FSC_ClasificacionSIB__c' => 'A'
			}
		);

		Id garanteApplicantId = insertIfPossible(
			'LoanApplicant',
			new Map<String, Object>{
				'Name' => 'Marta Santos Rojas',
				'LoanApplicationId' => rlaId,
				'FSC_TipoSolicitante__c' => 'Garante',
				'FSC_TipoIdentificacion__c' => 'Cédula',
				'FSC_NumIdentificacion__c' => '00300000000',
				'FSC_Nombre__c' => 'Marta',
				'FSC_PrimerApellido__c' => 'Santos',
				'FSC_SegundoApellido__c' => 'Rojas',
				'FSC_FechaNacimiento__c' => Date.newInstance(1979, 3, 8),
				'FSC_Nacionalidad__c' => 'REPUBLICA DOMINICANA',
				'FSC_EstadoCivil__c' => 'CASADO/A',
				'FSC_NumeroDependientes__c' => 3,
				'FSC_ClasificacionSIB__c' => 'A'
			}
		);

		Id referenciaId = insertIfPossible(
			'FSC_Referencias__c',
			new Map<String, Object>{ 'Name' => 'Laura Perez Gomez', 'FSC_Residential_Loan_Application__c' => rlaId, 'FSC_Parentesco__c' => 'Hermana' }
		);

		Id garantiaId = insertIfPossible(
			'FSC_Garantia__c',
			new Map<String, Object>{
				'FSC_Residential_Loan_Application__c' => rlaId,
				'FSC_Clase_de_Garantia__c' => 'BIENES INMUEBLES',
				'FSC_Tipo_de_Garantia__c' => 'Inmueble',
				'FSC_Descripcion_de_la_Garantia__c' => 'Apartamento residencial',
				'FSC_Proposito_Garantia_Hipotecario__c' => 'Compra de Solar para fines residenciales',
				'FSC_Tipo_de_Inmueble__c' => 'Apartamento',
				'FSC_Ubicacion__c' => 'Villa Juana, Santo Domingo',
				'FSC_Valor_Tasado__c' => 3000000,
				'FSC_Fecha_Tasacion__c' => Date.newInstance(2026, 1, 10),
				'FSC_Precio_de_Venta__c' => 3200000,
				'FSC_Valor_Inmueble__c' => 3000000,
				'FSC_Monto_Inicial_Avance_Pagado__c' => 500000,
				'FSC_Tasado_Por__c' => 'Carlos Joaquin Garcia'
			}
		);

		Id segundaGarantiaId = insertIfPossible(
			'FSC_Garantia__c',
			new Map<String, Object>{
				'FSC_Residential_Loan_Application__c' => rlaId,
				'FSC_Clase_de_Garantia__c' => 'VEHICULOS, MAQUINARIAS',
				'FSC_Tipo_de_Garantia__c' => 'Vehiculo',
				'FSC_Descripcion_de_la_Garantia__c' => 'Vehiculo familiar',
				'FSC_Proposito_Garantia_Hipotecario__c' => 'Compra de Solar para fines residenciales',
				'FSC_Tipo_de_Inmueble__c' => 'Vehiculo',
				'FSC_Ubicacion__c' => 'Ensanche Naco, Santo Domingo',
				'FSC_Valor_Tasado__c' => 950000,
				'FSC_Fecha_Tasacion__c' => Date.newInstance(2026, 2, 15),
				'FSC_Precio_de_Venta__c' => 975000,
				'FSC_Valor_Inmueble__c' => 950000,
				'FSC_Monto_Inicial_Avance_Pagado__c' => 150000,
				'FSC_Tasado_Por__c' => 'Ing. Juan Jorge Jerez'
			}
		);

		Id assetId = insertIfPossible(
			'LoanApplicationAsset',
			new Map<String, Object>{
				'LoanApplicationId' => rlaId,
				'Name' => 'Garantia Consumo',
				'CashOrMarketValue' => 300000,
				'FSC_Descripcion_de_la_Garantia__c' => 'Fiador solidario',
				'FSC_Porcentaje_Admisibilidad__c' => 80
			}
		);

		Test.startTest();
		Test.setCurrentPage(new PageReference('/apex/FSC_ConsumoSolicitudPDF'));
		ApexPages.currentPage().getParameters().put('id', String.valueOf(rlaId));
		FSC_ConsumoSolicitudPDFController controller = new FSC_ConsumoSolicitudPDFController();
		String sink;

		sink = controller.numeroSolicitud;
		sink = controller.usuarioOficial;
		sink = controller.fechaSolicitudDetalleFmt;
		sink = controller.estadoActualSolicitud;
		sink = controller.tipoSolicitudGeneral;
		sink = controller.esConsolidacionSimple;
		sink = controller.esRefinanciamientoSimple;
		sink = controller.deudaCancelar;
		sink = controller.solicitanteTipo;
		sink = controller.solicitanteTipoIdentificacion;
		sink = controller.solicitanteNumeroIdentificacion;
		sink = controller.solicitanteCodigoCliente;
		sink = controller.solicitanteNombres;
		sink = controller.solicitantePrimerApellido;
		sink = controller.solicitanteSegundoApellido;
		sink = controller.solicitanteNacionalidad;
		sink = controller.solicitanteFechaNacimiento;
		sink = controller.solicitanteEstadoCivil;
		sink = controller.solicitanteNumeroDependientes;
		sink = controller.solicitanteClasificacionSib;
		sink = controller.solicitanteEstadoVivienda;
		sink = controller.coSolicitanteTipo;
		sink = controller.coSolicitanteTipoIdentificacion;
		sink = controller.coSolicitanteNumeroIdentificacion;
		sink = controller.coSolicitanteNombres;
		sink = controller.coSolicitantePrimerApellido;
		sink = controller.coSolicitanteSegundoApellido;
		sink = controller.coSolicitanteNacionalidad;
		sink = controller.coSolicitanteFechaNacimiento;
		sink = controller.coSolicitanteEstadoCivil;
		sink = controller.coSolicitanteNumeroDependientes;
		sink = controller.coSolicitanteClasificacionSib;
		sink = controller.garanteTipo;
		sink = controller.garanteTipoIdentificacion;
		sink = controller.garanteNumeroIdentificacion;
		sink = controller.garanteCodigoCliente;
		sink = controller.garanteNombres;
		sink = controller.garantePrimerApellido;
		sink = controller.garanteSegundoApellido;
		sink = controller.garanteNacionalidad;
		sink = controller.garanteFechaNacimiento;
		sink = controller.garanteEstadoCivil;
		sink = controller.garanteNumeroDependientes;
		sink = controller.garanteClasificacionSib;
		sink = controller.garanteEstadoVivienda;
		sink = controller.direccionTexto;
		sink = controller.telefonosTexto;
		sink = controller.correosTexto;
		sink = controller.laborOcupacion;
		sink = controller.laborFuenteIngreso;
		sink = controller.laborLugarDondeLabora;
		sink = controller.laborTipoNegocio;
		sink = controller.laborCargoActual;
		sink = controller.laborTiempoLaborando;
		sink = controller.laborIngresosMensuales;
		sink = controller.laborOtrosIngresos;
		sink = controller.laborEmpresaAnterior;
		sink = controller.laborTotalIngresos;
		sink = controller.laborPrestaciones;
		sink = controller.laborDescripcionOtrosIngresos;
		sink = controller.resumenTipoFacilidad;
		sink = controller.resumenFacilidad;
		sink = controller.resumenPrestamoConGarantia;
		sink = controller.resumenMontoSolicitado;
		sink = controller.resumenFormaPago;
		sink = controller.resumenPlazoActual;
		sink = controller.resumenTasaInteresActual;
		sink = controller.resumenTasaFija;
		sink = controller.resumenMontoCuota;
		sink = controller.resumenTiempoTasaFija;
		sink = controller.resumenDeudaConsolidada;
		sink = controller.propositoFacilidad;
		Integer garantiaPdfSize = controller.garantiasPdfSize;
		for (FSC_ConsumoSolicitudPDFController.GarantiaPdfRow garantiaPdf : controller.garantiasPdf) {
			sink = garantiaPdf.titulo;
			sink = garantiaPdf.clase;
			sink = garantiaPdf.tipo;
			sink = garantiaPdf.descripcion;
			sink = garantiaPdf.ubicacion;
			sink = garantiaPdf.tasador;
		}
		Integer loanApplicantFirmantesSize = controller.loanApplicantFirmantesSize;
		for (FSC_LoanApplicantFirmanteService.Firmante firmante : controller.loanApplicantFirmantes) {
			sink = firmante.firmaElementId;
			sink = firmante.tipoSolicitante;
			sink = firmante.name;
		}
		Integer loanApplicantFirmanteRowsSize = controller.loanApplicantFirmanteRowsSize;
		sink = controller.textoAutorizacion;
		Test.stopTest();

			System.assertNotEquals(null, controller.sucursal);
		System.assertEquals('CONTROL DE PRESTAMOS', controller.resumenTipoFacilidad);
		System.assertEquals('CONSUMO', controller.resumenFacilidad);
		System.assertEquals('CLI-0001', controller.solicitanteCodigoCliente);
		System.assertEquals('Compra de muebles', controller.propositoFacilidad);
		System.assertEquals('Si', controller.esRefinanciamientoSimple);
		System.assertEquals('No', controller.esConsolidacionSimple);
		System.assertEquals(coApplicantId != null, controller.mostrarCoSolicitante);
		System.assertEquals(garanteApplicantId != null, controller.mostrarGarante);
		System.assert(controller.textoAutorizacion.contains('AUTORIZO'));
		System.assertEquals(referenciaId == null ? 0 : 1, controller.referenciasSize);
		System.assertEquals(assetId == null ? 0 : 1, controller.garantiasSize);

		if (referenciaId != null) {
			System.assertEquals('Hermana', controller.referencias[0].parentesco);
			System.assertEquals('Laura', controller.referencias[0].nombres);
			System.assertEquals('Perez Gomez', controller.referencias[0].apellidos);
		}

		if (applicantId != null) {
			System.assertEquals('Ana Maria', controller.solicitanteNombres);
			System.assertEquals('Banco Vimenca', controller.laborLugarDondeLabora);
			System.assertEquals('Comisiones', controller.laborDescripcionOtrosIngresos);
		}
		if (applicantId != null && coApplicantId != null && garanteApplicantId != null) {
			System.assertEquals(2, loanApplicantFirmantesSize);
			System.assertEquals(1, loanApplicantFirmanteRowsSize);
			System.assertEquals('Co-Deudor', controller.loanApplicantFirmantes[0].tipoSolicitante);
			System.assertEquals('FIRMALOANAPPLICANT1', controller.loanApplicantFirmantes[0].firmaElementId);
			System.assertEquals('Garante', controller.loanApplicantFirmantes[1].tipoSolicitante);
			System.assertEquals('FIRMALOANAPPLICANT2', controller.loanApplicantFirmantes[1].firmaElementId);
			System.assertEquals('Co-Deudor', controller.loanApplicantFirmanteRows[0].left.tipoSolicitante);
			System.assertEquals('Garante', controller.loanApplicantFirmanteRows[0].right.tipoSolicitante);
		}

		System.assertEquals('RD$ 250,000.00', controller.resumenMontoSolicitado);
		System.assertEquals('Debito automatico', controller.resumenFormaPago);

		if (garantiaId != null && segundaGarantiaId != null) {
			System.assertEquals(2, garantiaPdfSize);
			System.assertEquals('Garantia 1', controller.garantiasPdf[0].titulo);
			System.assertEquals('BIENES INMUEBLES', controller.garantiasPdf[0].clase);
			System.assertEquals('Garantia 2', controller.garantiasPdf[1].titulo);
			System.assertEquals('VEHICULOS, MAQUINARIAS', controller.garantiasPdf[1].clase);
			System.assertEquals('Vehiculo familiar', controller.garantiasPdf[1].descripcion);
			System.assertEquals('Ensanche Naco, Santo Domingo', controller.garantiasPdf[1].ubicacion);
			System.assertEquals('Ing. Juan Jorge Jerez', controller.garantiasPdf[1].tasador);
		}
	}

	@IsTest
	static void testControllerWithoutIdDoesNotFail() {
		Test.setCurrentPage(new PageReference('/apex/FSC_ConsumoSolicitudPDF'));
		FSC_ConsumoSolicitudPDFController controller = new FSC_ConsumoSolicitudPDFController();

		System.assertEquals('', controller.sucursal);
		System.assertNotEquals('', controller.fechaHoyFmt);
		System.assertEquals('', controller.fechaSolicitudFmt);
		System.assertEquals('', controller.cuotaMensualFmt);
		System.assertEquals('[ ] Si  [X] No', controller.refinanciamientoTexto);
		System.assertEquals('[ ] Si  [X] No', controller.consolidacionTexto);
		System.assertEquals('[ ] Si  [X] No', controller.aplicaGarantiaTexto);
		System.assertEquals(0, controller.referenciasSize);
		System.assertEquals(1, controller.facilidades.size());
		System.assertEquals(0, controller.emptyReferenciaRows.size());
		System.assertEquals(3, controller.emptyFacilidadRows.size());
		System.assertEquals(0, controller.garantiasSize);
		System.assertEquals(0, controller.garantiasPdfSize);
		System.assertEquals(3, controller.emptyGarantiaRows.size());
		System.assertEquals('', FSC_ConsumoSolicitudPDFController.fmtMoney(null));
	}

	@IsTest
	static void testControllerUsesFallbackValuesAndSyntheticRows() {
		Account account = createAccountRecord(
			new Map<String, Object>{
				'FirstName' => 'Pedro',
				'MiddleName' => 'Luis',
				'LastName' => 'Morales Diaz',
				'PersonBirthdate' => Date.newInstance(1985, 1, 2),
				'PersonMobilePhone' => '8095559999',
				'ACC_TipoIdentificacion__c' => 'Pasaporte',
				'ACC_NumIdentificacion__c' => 'P003000000',
				'ACC_Tipo_Identificacion_Anterior__c' => 'Pasaporte',
				'ACC_N_Identificacion_Anterior__c' => 'OLD-123',
				'ACC_Nacionalidad__c' => 'REPUBLICA DOMINICANA',
				'ACC_Estado_Civil__c' => 'CASADO/A',
				'Tipo_de_vivienda__c' => '3',
				'ACC_N_Dependientes__c' => 4,
				'PersonMailingStreet' => 'C/ Secundaria #12',
				'PersonMailingCity' => 'Santiago',
				'PersonMailingState' => 'Santiago',
				'PersonMailingCountry' => 'Republica Dominicana',
				'ACC_Nombre_Corto_Comercial__c' => 'Comercial Pedro',
				'FinServ__CustomerID__c' => 'CUS-123'
			}
		);

		Id rlaId = createRlaRecord(
			account.Id,
			new Map<String, Object>{
				'FSC_CodigoAprobacion__c' => 'APR-001',
				'FSC_Destino_del_Prestamo__c' => 'Capital de trabajo',
				'FSC_Moneda__c' => '1',
				'FSC_FormaPago__c' => 'Debito automatico',
				'FSC_TipoSolicitud__c' => 'BPR',
				'FSC_Clasificacion_de_Riesgo__c' => 'A',
				'FSC_Correo_Electronico__c' => 'fallback@vimenca.com',
				'FSC_Telefono__c' => '8095557777',
				'FSC_Actividad_economica__c' => 'Comercio',
				'FSC_Tiempo_del_negocio__c' => '8 anos',
				'FSC_Monto_de_los_Ingresos__c' => 1500,
				'FSC_Monto__c' => 90000,
				'FSC_MontoDesembolso__c' => 85000,
				'FSC_PlazoMeses__c' => 18,
				'FSC_TasaInteres__c' => 12.5,
				'FSC_EsRefinanciamiento__c' => false,
				'FSC_EsConsolidacionDeudas__c' => true,
				'FSC_Aplica_Garantia__c' => false,
				'FSC_TipoGarantia__c' => 'Solidaria',
				'FSC_Valor_de_la_Garantia__c' => 100000,
				'FSC_Descripcion_de_la_Garantia__c' => 'Fiador solidario'
			}
		);

		Test.startTest();
		FSC_ConsumoSolicitudPDFController controller = createController(rlaId);
		Test.stopTest();

		System.assertEquals('APR-001', controller.codigoAprobacion);
		System.assertNotEquals('', controller.numeroSolicitud);
		System.assertNotEquals('', controller.fechaSolicitudFmt);
		System.assertEquals('BPR', controller.tipoSolicitud);
		System.assertEquals('Capital de trabajo', controller.destinoPrestamo);
		System.assertEquals('1', controller.moneda);
		System.assertEquals('Debito automatico', controller.formaPago);
		System.assertEquals('A', controller.clasificacionSib);
		System.assertEquals('Pasaporte', controller.tipoIdentificacion);
		System.assertEquals('P003000000', controller.numeroIdentificacion);
		System.assertEquals('Pasaporte', controller.tipoIdentificacionAnterior);
		System.assertEquals('OLD-123', controller.numeroIdentificacionAnterior);
		System.assertEquals('REPUBLICA DOMINICANA', controller.nacionalidad);
		System.assertEquals('', controller.genero);
		System.assertEquals('CASADO/A', controller.estadoCivil);
		System.assertEquals('Pedro', controller.primerNombre);
		System.assertEquals('Luis', controller.segundoNombre);
		System.assertEquals(false, controller.mostrarCoSolicitante);
		System.assertEquals(false, controller.mostrarGarante);
		System.assertEquals('Morales Diaz', controller.apellidos);
		System.assertEquals('Pedro Luis Morales Diaz', controller.nombreCompleto);
		System.assertEquals('02/01/1985', controller.fechaNacimientoFmt);
		System.assertEquals('fallback@vimenca.com', controller.correo);
		System.assertEquals('8095557777', controller.telefonoResidencia);
		System.assertEquals('8095559999', controller.celular);
		System.assertEquals('C/ Secundaria #12, Santiago, Santiago, Republica Dominicana', controller.direccionResidencia);
		System.assertEquals('Comercial Pedro', controller.empresaActual);
		System.assertEquals('', controller.direccionLaboral);
		System.assertEquals('Comercio', controller.actividadEconomica);
		System.assertEquals('Comercio', controller.ocupacion);
		System.assertEquals('8 anos', controller.tiempoLaborando);
		System.assertEquals('RD$ 1,500.00', controller.ingresosMensualesFmt);
		System.assertEquals('RD$ 90,000.00', controller.montoSolicitadoFmt);
		System.assertEquals('RD$ 90,000.00', controller.montoAprobadoFmt);
		System.assertEquals('RD$ 85,000.00', controller.montoDesembolsoFmt);
		System.assertEquals('18', controller.plazoMeses);
		System.assertEquals('12.50%', controller.tasaInteresFmt);
		System.assertEquals('[ ] Si  [X] No', controller.refinanciamientoTexto);
		System.assertEquals('[X] Si  [ ] No', controller.consolidacionTexto);
		System.assertEquals('[ ] Si  [X] No', controller.aplicaGarantiaTexto);
		System.assertEquals(UserInfo.getName(), controller.usuarioOficial);
		System.assertEquals('', controller.solicitanteTipo);
		System.assertEquals('', controller.solicitanteTipoIdentificacion);
		System.assertEquals('', controller.solicitanteNumeroIdentificacion);
		System.assertEquals('', controller.solicitanteCodigoCliente);
		System.assertEquals('', controller.solicitanteNombres);
		System.assertEquals('', controller.solicitantePrimerApellido);
		System.assertEquals('', controller.solicitanteSegundoApellido);
		System.assertEquals('', controller.solicitanteNacionalidad);
		System.assertEquals('', controller.solicitanteFechaNacimiento);
		System.assertEquals('', controller.solicitanteEstadoCivil);
		System.assertEquals('', controller.solicitanteNumeroDependientes);
		System.assertEquals('', controller.solicitanteClasificacionSib);
		System.assertEquals('', controller.solicitanteEstadoVivienda);
		System.assertEquals('', controller.coSolicitanteTipo);
		System.assertEquals('', controller.coSolicitanteCodigoCliente);
		System.assertEquals('C/ Secundaria #12, Santiago, Santiago, Republica Dominicana', controller.direccionTexto);
		System.assertEquals('8095557777 / 8095559999', controller.telefonosTexto);
		System.assertEquals('fallback@vimenca.com', controller.correosTexto);
		System.assertEquals('Comercio', controller.laborOcupacion);
		System.assertEquals('Comercio', controller.laborFuenteIngreso);
		System.assertEquals('Comercial Pedro', controller.laborLugarDondeLabora);
		System.assertEquals('', controller.laborTipoNegocio);
		System.assertEquals('', controller.laborCargoActual);
		System.assertEquals('8 anos', controller.laborTiempoLaborando);
		System.assertEquals('RD$ 1,500.00', controller.laborIngresosMensuales);
		System.assertEquals('RD$ 1,500.00', controller.laborOtrosIngresos);
		System.assertEquals('', controller.laborTotalIngresos);
		System.assertEquals('', controller.laborPrestaciones);
		System.assertEquals('', controller.laborDescripcionOtrosIngresos);
		System.assertEquals('No', controller.resumenPrestamoConGarantia);
		System.assertEquals('RD$ 90,000.00', controller.resumenMontoSolicitado);
		System.assertEquals('Debito automatico', controller.resumenFormaPago);
		System.assertEquals('18', controller.resumenPlazoActual);
		System.assertEquals('12.50%', controller.resumenTasaInteresActual);
		System.assertEquals('No', controller.resumenTasaFija);
		System.assertEquals('Capital de trabajo', controller.propositoFacilidad);
		System.assertEquals('RD$ 100,000.00', controller.garantiaValorFmt);
		System.assertEquals('Fiador solidario', controller.descripcionGarantia);
		System.assertEquals('', controller.observaciones);
		System.assertEquals(0, controller.referenciasSize);
		System.assertEquals(1, controller.facilidades.size());
		System.assertEquals('Consumo', controller.facilidades[0].tipo);
		System.assertEquals(1, controller.garantiasSize);
		System.assertEquals('Fiador solidario', controller.garantias[0].descripcion);
		System.assertEquals(1, controller.garantiasPdfSize);
		System.assertEquals('Solidaria', controller.garantiasPdf[0].tipo);
		System.assertEquals('Fiador solidario', controller.garantiasPdf[0].descripcion);
		System.assertEquals(0, controller.emptyReferenciaRows.size());
		System.assertEquals(3, controller.emptyFacilidadRows.size());
		System.assertEquals(2, controller.emptyGarantiaRows.size());
	}

	@IsTest
	static void testControllerUsesApplicantFallbacksForCoSolicitanteAndLaborData() {
		Account account = createAccountRecord(
			new Map<String, Object>{
				'FirstName' => 'Maria',
				'MiddleName' => 'Elena',
				'LastName' => 'Lopez Ruiz',
				'ACC_TipoIdentificacion__c' => 'Pasaporte',
				'ACC_NumIdentificacion__c' => 'AA11',
				'ACC_Nacionalidad__c' => 'REPUBLICA DOMINICANA',
				'ACC_Estado_Civil__c' => 'SOLTERO/A',
				'Tipo_de_vivienda__c' => '1'
			}
		);

		Id rlaId = createRlaRecord(
			account.Id,
			new Map<String, Object>{
				'FSC_Actividad_economica__c' => 'Servicios',
				'FSC_Nombre_del_negocio__c' => 'Negocio Dos',
				'FSC_Monto_de_los_Ingresos__c' => 4000
			}
		);

		Id applicantId = insertIfPossible(
			'LoanApplicant',
			new Map<String, Object>{
				'Name' => 'Maria Elena Lopez Ruiz',
				'LoanApplicationId' => rlaId,
				'FSC_TipoSolicitante__c' => 'Deudor',
				'FSC_TipoIdentificacion__c' => 'Pasaporte',
				'FSC_NumIdentificacion__c' => 'AA11',
				'FSC_Nombre__c' => 'Maria Elena',
				'FSC_FechaNacimiento__c' => Date.newInstance(1992, 6, 15),
				'FSC_Nacionalidad__c' => 'REPUBLICA DOMINICANA',
				'FSC_EstadoCivil__c' => 'SOLTERO/A',
				'FSC_NumeroDependientes__c' => 1,
				'FSC_ClasificacionSIB__c' => 'A',
				'FSC_TipoVivienda__c' => '1',
				'FSC_IngresosMensuales__c' => 12345.67,
				'FSC_TotalIngresos__c' => 12345.67
			}
		);

		if (applicantId != null) {
			insertIfPossible(
				'LoanApplicantEmployment',
				new Map<String, Object>{
					'Name' => 'Empleo Maria Lopez',
					'LoanApplicantId' => applicantId,
					'EmployerName' => 'Empresa Uno',
					'JobTitle' => 'Consultora',
					'CurrentJobYearCount' => 1,
					'CurrentJobAdditionalMonthCount' => 1,
					'MonthlyTotalIncomeAmount' => 12345.67
				}
			);
		}

		Id coApplicantId = insertIfPossible(
			'LoanApplicant',
			new Map<String, Object>{
				'Name' => 'Carlos Perez Diaz',
				'LoanApplicationId' => rlaId,
				'FSC_TipoSolicitante__c' => 'Co-Deudor',
				'FSC_TipoIdentificacion__c' => 'Pasaporte',
				'FSC_NumIdentificacion__c' => 'BB22',
				'FSC_Nombre__c' => 'Carlos',
				'FSC_PrimerApellido__c' => 'Perez',
				'FSC_SegundoApellido__c' => 'Diaz',
				'FSC_FechaNacimiento__c' => Date.newInstance(1990, 2, 10),
				'FSC_Nacionalidad__c' => 'REPUBLICA DOMINICANA',
				'FSC_EstadoCivil__c' => 'CASADO/A',
				'FSC_NumeroDependientes__c' => 2,
				'FSC_ClasificacionSIB__c' => 'A',
				'FSC_TipoVivienda__c' => '2'
			}
		);

		Test.startTest();
		FSC_ConsumoSolicitudPDFController controller = createController(rlaId);
		Test.stopTest();

		System.assertEquals(coApplicantId != null, controller.mostrarCoSolicitante);
		System.assertEquals(false, controller.mostrarGarante);

		if (applicantId != null) {
			System.assertEquals('Maria Elena', controller.solicitanteNombres);
			System.assertEquals('Lopez', controller.solicitantePrimerApellido);
			System.assertEquals('Ruiz', controller.solicitanteSegundoApellido);
			System.assertEquals('Propia', controller.solicitanteEstadoVivienda);
			System.assertEquals('Servicios', controller.laborOcupacion);
			System.assertEquals('Servicios', controller.laborFuenteIngreso);
			System.assertEquals('Empresa Uno', controller.laborLugarDondeLabora);
			System.assertEquals('Negocio Dos', controller.laborTipoNegocio);
			System.assertEquals('Consultora', controller.laborCargoActual);
			System.assertEquals('1 ano 1 mes', controller.laborTiempoLaborando);
			System.assertEquals('RD$ 12,345.67', controller.laborIngresosMensuales);
			System.assertEquals('RD$ 12,345.67', controller.laborTotalIngresos);
		}

		if (coApplicantId != null) {
			System.assertEquals('Co-Deudor', controller.coSolicitanteTipo);
			System.assertEquals('Pasaporte', controller.coSolicitanteTipoIdentificacion);
			System.assertEquals('BB22', controller.coSolicitanteNumeroIdentificacion);
			System.assertEquals('Carlos', controller.coSolicitanteNombres);
			System.assertEquals('Perez', controller.coSolicitantePrimerApellido);
			System.assertEquals('Diaz', controller.coSolicitanteSegundoApellido);
			System.assertEquals('REPUBLICA DOMINICANA', controller.coSolicitanteNacionalidad);
			System.assertEquals('10/02/1990', controller.coSolicitanteFechaNacimiento);
			System.assertEquals('CASADO/A', controller.coSolicitanteEstadoCivil);
			System.assertEquals('2', controller.coSolicitanteNumeroDependientes);
			System.assertEquals('A', controller.coSolicitanteClasificacionSib);
			System.assertEquals('Alquilada', controller.coSolicitanteEstadoVivienda);
		}

		System.assertEquals('', controller.coSolicitanteCodigoCliente);
	}

	@IsTest
	static void testControllerKeepsSolicitanteEmptyWhenOnlyGuaranteeApplicantExists() {
		Account account = createAccountRecord(new Map<String, Object>{ 'FirstName' => 'Roberto', 'LastName' => 'Santos' });

		Id rlaId = createRlaRecord(account.Id, new Map<String, Object>());
		Id garanteId = insertIfPossible(
			'LoanApplicant',
			new Map<String, Object>{
				'Name' => 'Roberto Garante',
				'LoanApplicationId' => rlaId,
				'FSC_TipoSolicitante__c' => 'Garante',
				'FSC_TipoIdentificacion__c' => 'Pasaporte',
				'FSC_NumIdentificacion__c' => 'GG77',
				'FSC_Nombre__c' => 'Roberto',
				'FSC_TipoVivienda__c' => '4',
				'FSC_Ocupacion__c' => 'Comerciante',
				'FSC_FuenteIngreso__c' => 'Negocio propio',
				'FSC_LugarFondeLabora__c' => 'Ferreteria Santos',
				'FSC_IngresosMensuales__c' => 55000,
				'FSC_TotalIngresos__c' => 55000,
				'FSC_DescripcionOtrosIngresos__c' => 'Ventas'
			}
		);
		Id direccionId;
		Id telefonoId;
		Id correoId;
		if (garanteId != null) {
			direccionId = insertIfPossible(
				'ContactPointAddress',
				new Map<String, Object>{
					'Name' => 'Direccion Garante',
					'IsPrimary' => true,
					'IsDefault' => true,
					'IsThirdPartyAddress' => false,
					'Street' => 'C/ Garante #12',
					'City' => 'Santo Domingo',
					'Country' => 'Republica Dominicana',
					'FSC_Solicitante__c' => garanteId
				}
			);
			telefonoId = insertIfPossible(
				'ContactPointPhone',
				new Map<String, Object>{
					'IsPrimary' => true,
					'IsSmsCapable' => true,
					'IsFaxCapable' => false,
					'IsPersonalPhone' => true,
					'IsBusinessPhone' => false,
					'TelephoneNumber' => '8095551212',
					'FSC_Solicitante__c' => garanteId
				}
			);
			correoId = insertIfPossible(
				'ContactPointEmail',
				new Map<String, Object>{ 'IsPrimary' => true, 'EmailAddress' => 'garante@vimenca.com', 'FSC_Solicitante__c' => garanteId }
			);
		}

		Test.startTest();
		FSC_ConsumoSolicitudPDFController controller = createController(rlaId);
		Test.stopTest();

		System.assertEquals('', controller.solicitanteTipo);
		System.assertEquals('', controller.solicitanteNombres);
		System.assertEquals('', controller.coSolicitanteTipo);
		System.assertEquals('', controller.coSolicitanteEstadoVivienda);
		System.assertEquals(false, controller.mostrarCoSolicitante);
		System.assertEquals(garanteId != null, controller.mostrarGarante);
		if (garanteId != null) {
			System.assertEquals('Garante', controller.garanteTipo);
			System.assertEquals('Roberto', controller.garanteNombres);
			System.assertEquals('Comerciante', controller.laborOcupacion);
			System.assertEquals('Negocio propio', controller.laborFuenteIngreso);
			System.assertEquals('Ferreteria Santos', controller.laborLugarDondeLabora);
			System.assertEquals('RD$ 55,000.00', controller.laborIngresosMensuales);
			System.assertEquals('Ventas', controller.laborDescripcionOtrosIngresos);
		}
		if (direccionId != null) {
			System.assertEquals('C/ Garante #12, Santo Domingo, Republica Dominicana', controller.direccionTexto);
		}
		if (telefonoId != null) {
			System.assertEquals('8095551212', controller.telefonosTexto);
		}
		if (correoId != null) {
			System.assertEquals('garante@vimenca.com', controller.correosTexto);
		}
	}

	private static Id getPersonAccountRecordTypeId() {
		List<RecordType> recordTypes = [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'PersonAccount' AND SobjectType = 'Account'
			LIMIT 1
		];
		return recordTypes.isEmpty() ? null : recordTypes[0].Id;
	}

	private static Account createAccountRecord(Map<String, Object> fieldValues) {
		Account account = new Account();
		Id personRtId = getPersonAccountRecordTypeId();
		Map<String, Schema.SObjectField> accountFieldMap = Schema.SObjectType.Account.fields.getMap();

		if (personRtId != null) {
			account.RecordTypeId = personRtId;
		} else {
			setIfFieldExists(account, accountFieldMap, 'Name', 'Cuenta de prueba');
		}

		setIfFieldExists(account, accountFieldMap, 'FirstName', 'Ana');
		setIfFieldExists(account, accountFieldMap, 'LastName', 'Garcia Perez');

			if (fieldValues != null) {
				for (String apiName : fieldValues.keySet()) {
					setIfFieldExists(account, accountFieldMap, apiName, fieldValues.get(apiName));
				}
			}

			setupPersonAccountMock();
			insert account;
			return account;
		}

	private static Id createRlaRecord(Id accountId, Map<String, Object> fieldValues) {
		SObject rla = Schema.getGlobalDescribe().get('ResidentialLoanApplication').newSObject();
		Map<String, Schema.SObjectField> rlaFieldMap = Schema.SObjectType.ResidentialLoanApplication.fields.getMap();

		rla.put('AccountId', accountId);
		rla.put('Name', 'SC-' + String.valueOf(DateTime.now().getTime()));
		Id consumoRtId = getRlaRecordTypeId('FSC_Solicitud_Credito_Consumo');
		if (consumoRtId != null) {
			rla.put('RecordTypeId', consumoRtId);
		}

		if (fieldValues != null) {
			for (String apiName : fieldValues.keySet()) {
				setIfFieldExists(rla, rlaFieldMap, apiName, fieldValues.get(apiName));
			}
		}

		insert rla;
		return (Id) rla.get('Id');
	}

	private static FSC_ConsumoSolicitudPDFController createController(Id rlaId) {
		Test.setCurrentPage(new PageReference('/apex/FSC_ConsumoSolicitudPDF'));
		ApexPages.currentPage().getParameters().put('id', String.valueOf(rlaId));
		return new FSC_ConsumoSolicitudPDFController();
	}

	private static Id getRlaRecordTypeId(String developerName) {
		Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName();
		return recordTypes.containsKey(developerName) ? recordTypes.get(developerName).getRecordTypeId() : null;
	}

	private static void setIfFieldExists(SObject record, Map<String, Schema.SObjectField> fieldMap, String apiName, Object value) {
		if (fieldMap.containsKey(apiName)) {
			Schema.DescribeFieldResult fieldDescribe = fieldMap.get(apiName).getDescribe();
			if (!fieldDescribe.isCreateable()) {
				return;
			}

			Object coercedValue = coerceFieldValue(fieldDescribe, value);
			if (value != null && coercedValue == null) {
				return;
			}

			try {
				record.put(apiName, coercedValue);
			} catch (SObjectException e) {
			}
		}
	}

	private static Id insertIfPossible(String objectApiName, Map<String, Object> fieldValues) {
		Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
		if (!globalDescribe.containsKey(objectApiName)) {
			return null;
		}

		SObject record = globalDescribe.get(objectApiName).newSObject();
		Map<String, Schema.SObjectField> fieldMap = record.getSObjectType().getDescribe().fields.getMap();

		for (String apiName : fieldValues.keySet()) {
			if (fieldMap.containsKey(apiName)) {
				Schema.DescribeFieldResult fieldDescribe = fieldMap.get(apiName).getDescribe();
				if (!fieldDescribe.isCreateable()) {
					continue;
				}

				Object originalValue = fieldValues.get(apiName);
				Object coercedValue = coerceFieldValue(fieldDescribe, originalValue);
				if (originalValue != null && coercedValue == null) {
					continue;
				}

				try {
					record.put(apiName, coercedValue);
				} catch (SObjectException e) {
				}
			}
		}

		try {
			insert record;
			return (Id) record.get('Id');
		} catch (DmlException e) {
			return null;
		}
	}

	private static Object coerceFieldValue(Schema.DescribeFieldResult fieldDescribe, Object value) {
		if (value == null) {
			return null;
		}

		Schema.DisplayType fieldType = fieldDescribe.getType();
		if (fieldType == Schema.DisplayType.Date) {
			return tryDateValue(value);
		}
		if (fieldType == Schema.DisplayType.DateTime) {
			return tryDateTimeValue(value);
		}
		if (fieldType == Schema.DisplayType.Currency || fieldType == Schema.DisplayType.Double || fieldType == Schema.DisplayType.Percent) {
			return tryDecimalValue(value);
		}
		if (fieldType == Schema.DisplayType.Integer) {
			return tryIntegerValue(value);
		}
		if (fieldType == Schema.DisplayType.Boolean) {
			return tryBooleanValue(value);
		}
		String fieldTypeName = String.valueOf(fieldType).toLowerCase();
		if (
			new Set<String>{ 'string', 'textarea', 'phone', 'email', 'url', 'picklist', 'multipicklist', 'combobox', 'encryptedstring' }
				.contains(fieldTypeName)
		) {
			return String.valueOf(value);
		}

		return value;
	}

	private static Date tryDateValue(Object value) {
		if (value instanceof Date) {
			return (Date) value;
		}
		if (value instanceof DateTime) {
			return ((DateTime) value).date();
		}

		String text = String.valueOf(value);
		if (String.isBlank(text)) {
			return null;
		}
		if (text.length() >= 10) {
			text = text.substring(0, 10);
		}

		try {
			return Date.valueOf(text);
		} catch (Exception e) {
			return null;
		}
	}

	private static DateTime tryDateTimeValue(Object value) {
		if (value instanceof DateTime) {
			return (DateTime) value;
		}
		if (value instanceof Date) {
			return DateTime.newInstance((Date) value, Time.newInstance(0, 0, 0, 0));
		}

		String text = String.valueOf(value);
		if (String.isBlank(text)) {
			return null;
		}

		try {
			return DateTime.valueOf(text.replace('T', ' ').replace('Z', ''));
		} catch (Exception e) {
			Date parsedDate = tryDateValue(text);
			return parsedDate == null ? null : DateTime.newInstance(parsedDate, Time.newInstance(0, 0, 0, 0));
		}
	}

	private static Decimal tryDecimalValue(Object value) {
		try {
			if (value instanceof Decimal) {
				return (Decimal) value;
			}
			return Decimal.valueOf(String.valueOf(value));
		} catch (Exception e) {
			return null;
		}
	}

	private static Integer tryIntegerValue(Object value) {
		Decimal parsedValue = tryDecimalValue(value);
		return parsedValue == null ? null : parsedValue.intValue();
	}

	private static Boolean tryBooleanValue(Object value) {
		if (value instanceof Boolean) {
			return (Boolean) value;
		}

		String text = String.valueOf(value);
		if (String.isBlank(text)) {
			return null;
		}

		text = text.trim().toLowerCase();
		if (text == 'true') {
			return true;
		}
		if (text == 'false') {
			return false;
		}
		return null;
	}
}