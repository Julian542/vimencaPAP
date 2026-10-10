@IsTest
private class FSC_CoberturaPendienteTest {
    @TestSetup
    static void asignarPermisosAdministrador() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            PermissionSet permiso = [SELECT Id FROM PermissionSet WHERE Name = 'FSC_PS_Administrador' LIMIT 1];
            // El usuario que ejecuta los tests puede tener ya el permission set asignado.
            if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permiso.Id] == 0) {
                insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permiso.Id);
            }
        }
    }

	private static Integer sequence = 0;

	private static Id rlaRecordType(String developerName) {
		return ResidentialLoanApplication.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
	}

	private static Account createCorporateAccount() {
		sequence++;
		Account account = new Account(
			Name = 'Empresa cobertura pendiente ' + sequence,
			ACC_TipoIdentificacion__c = 'RNC',
			ACC_NumIdentificacion__c = '10100000' + sequence,
			ACC_RNC__c = '10100000' + sequence,
			VFS_RegistroMercantil__c = 'RM-' + sequence,
			ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA',
			ACC_Estado_Civil__c = 'SOLTERO/A',
			BillingStreet = 'Calle cobertura',
			BillingCity = 'Santo Domingo',
			BillingState = 'Distrito Nacional',
			BillingCountry = 'República Dominicana'
		);
		insert account;
		return account;
	}

	private static ResidentialLoanApplication createPyme(String suffix) {
		Account account = createCorporateAccount();
		ResidentialLoanApplication rla = new ResidentialLoanApplication(
			Name = 'RLA pendiente ' + suffix,
			AccountId = account.Id,
			RecordTypeId = rlaRecordType('FSC_Solicitud_Credito_PYME'),
			Status = 'En proceso',
			FSC_Subestado__c = 'Generación de contrato',
			FSC_TipoSolicitud__c = 'BPR',
			FSC_Tipo_de_Garantia__c = 'Sin Garantía',
			FSC_Moneda__c = '1',
			FSC_Monto__c = 500000,
			FSC_MontoAprobado__c = 450000,
			FSC_TasaInteres__c = 12,
			FSC_TasaInteresAprobada__c = 11,
			FSC_Plazo_meses__c = '24',
			FSC_PlazoMesesAprobado__c = 24,
			FSC_Destino_del_Prestamo__c = 'Capital de trabajo',
			FSC_Fecha_Contrato__c = Date.today(),
			FSC_RNC_Cliente_Contrato__c = '101000001',
			FSC_Registro_Mercantil_Contrato__c = 'RM-TEST',
			FSC_Domicilio_Cliente_Contrato__c = 'Santo Domingo',
			FSC_Nombre_Representante_Cliente__c = 'Representante Prueba',
			FSC_Cargo_Representante_Cliente__c = 'Gerente',
			FSC_Nacionalidad_Representante__c = 'REPUBLICA DOMINICANA',
			FSC_Estado_Civil_Representante__c = 'SOLTERO/A',
			FSC_Identificacion_Representante__c = '00100000001',
			FSC_Domicilio_Representante__c = 'Santo Domingo',
			FSC_Resolucion_Autorizacion__c = 'Resolución de prueba',
			FSC_Fecha_Acta_Autorizacion__c = Date.today(),
			FSC_Personas_Autorizadas__c = 'Representante Prueba',
			FSC_Calidad_Autorizados__c = 'Gerente',
			FSC_UsuarioPagaresYContratos__c = UserInfo.getUserId()
		);
		insert rla;
		return rla;
	}

	private static ResidentialLoanApplication createConsumption(String suffix) {
		ResidentialLoanApplication rla = createPyme(suffix);
		update new ResidentialLoanApplication(Id = rla.Id, RecordTypeId = rlaRecordType('FSC_Solicitud_Credito_Consumo'));
		return rla;
	}

	private static void saveContractData(Id rlaId) {
		FSC_DatosContratoController.guardarDatosYPrepararGeneracion(
			rlaId,
			null,
			null,
			null,
			false,
			true,
			JSON.serialize(new Map<String, Object>{ 'clienteDomicilio' => 'Santo Domingo' })
		);
	}

	private static void expectDocumentEditFailure(Id rlaId, String documentType, String changesJson) {
		try {
			FSC_RlaAccionesController.guardarYRegenerarDocumentoAnalisis(rlaId, documentType, changesJson);
			System.assert(false, 'La entrada inválida debía generar un error controlado.');
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}
	}

	@IsTest
	static void approvalServiceCubreGruposDirectosYAnidados() {
		Profile nonAdminProfile = [SELECT Id FROM Profile WHERE PermissionsModifyAllData = FALSE LIMIT 1];
		User actingUser = new User(
			Alias = 'cvrapr',
			CommunityNickname = 'cvrapr' + String.valueOf(Math.mod(System.now().getTime(), 100000)),
			Email = 'cobertura.aprobacion@example.com',
			EmailEncodingKey = 'UTF-8',
			LastName = 'Cobertura Aprobación',
			LanguageLocaleKey = 'es',
			LocaleSidKey = 'es_AR',
			ProfileId = nonAdminProfile.Id,
			TimeZoneSidKey = 'America/Santo_Domingo',
			Username = 'cobertura.aprobacion.' + System.now().getTime() + '@example.com'
		);
		completarCamposObligatoriosUsuario(actingUser);
		insert actingUser;
		Group directGroup = new Group(Name = 'Aprobadores directos cobertura', Type = 'Regular');
		Group nestedGroup = new Group(Name = 'Aprobadores anidados cobertura', Type = 'Regular');
		insert new List<Group>{ directGroup, nestedGroup };
		insert new GroupMember(GroupId = directGroup.Id, UserOrGroupId = actingUser.Id);
		insert new GroupMember(GroupId = nestedGroup.Id, UserOrGroupId = directGroup.Id);

		ProcessInstanceWorkitem directItem = new ProcessInstanceWorkitem(ActorId = directGroup.Id);
		ProcessInstanceWorkitem nestedItem = new ProcessInstanceWorkitem(ActorId = nestedGroup.Id);
		System.runAs(actingUser) {
			System.assertEquals(true, FSC_ExcepcionApprovalService.canCurrentUserAct(directItem));
			System.assertEquals(true, FSC_ExcepcionApprovalService.canCurrentUserAct(nestedItem));

			Map<Id, List<ProcessInstanceWorkitem>> workItems = new Map<Id, List<ProcessInstanceWorkitem>>{
				actingUser.Id => new List<ProcessInstanceWorkitem>{ directItem, nestedItem }
			};
			System.assertEquals(1, FSC_ExcepcionApprovalService.getActionableTargetIds(workItems).size());
		}
	}

	@IsTest
	static void loanApplicantActualizaYEliminaColecciones() {
		Account account = createCorporateAccount();
		Map<String, Object> applicant = new Map<String, Object>{
			'FSC_TipoSolicitante__c' => 'Deudor',
			'FSC_Nombre__c' => 'Cliente',
			'FSC_PrimerApellido__c' => 'Cobertura',
			'FSC_SegundoApellido__c' => 'Pendiente',
			'FSC_TipoIdentificacion__c' => 'RNC',
			'FSC_NumIdentificacion__c' => '00100000999',
			'FSC_Nacionalidad__c' => 'REPUBLICA DOMINICANA',
			'FSC_EstadoCivil__c' => 'SOLTERO/A',
			'FSC_TipoVivienda__c' => '2',
			'FSC_TiempoVivienda__c' => '2020-01-01',
			'FSC_NumeroDependientes__c' => '2',
			'FSC_ClasificacionSIB__c' => 'A',
			'FSC_IngresosMensuales__c' => '25000',
			'FSC_TipoNegocio__c' => 'Servicios',
			'FSC_LugarFondeLabora__c' => 'Empresa prueba',
			'FSC_FuenteIngreso__c' => 'Empleado Privado',
			'FSC_Ocupacion__c' => 'ABOGADO',
			'FSC_TiempoLaborando__c' => '2021-02-03',
			'FSC_EmpresaAnteriorLaboro__c' => 'Empresa anterior',
			'ContactPointPhone' => new List<Object>{
				new Map<String, Object>{ 'FSC_TipoContacto__c' => 'Celular', 'TelephoneNumber' => '8095550001' }
			},
			'ContactPointAddress' => new List<Object>{
				new Map<String, Object>{
					'Name' => 'Residencia',
					'Street' => 'Calle 1',
					'City' => 'Santo Domingo',
					'State' => 'Distrito Nacional',
					'PostalCode' => '10100',
					'Country' => 'DO'
				}
			},
			'ContactPointEmail' => new List<Object>{ new Map<String, Object>{ 'EmailAddress' => 'cobertura@example.com' } }
		};

		FSC_LoanApplicantController.updateDebtorAccount(account.Id, JSON.serialize(applicant));
		System.assertEquals(1, [SELECT COUNT() FROM ContactPointPhone WHERE ParentId = :account.Id]);
		System.assertEquals(1, [SELECT COUNT() FROM ContactPointAddress WHERE ParentId = :account.Id]);
		System.assertEquals(1, [SELECT COUNT() FROM ContactPointEmail WHERE ParentId = :account.Id]);

		applicant.put('ContactPointPhone', new List<Object>());
		applicant.put('ContactPointAddress', new List<Object>());
		applicant.put('ContactPointEmail', new List<Object>());
		FSC_LoanApplicantController.updateDebtorAccount(account.Id, JSON.serialize(applicant));

		System.assertEquals(0, [SELECT COUNT() FROM ContactPointPhone WHERE ParentId = :account.Id]);
		System.assertEquals(0, [SELECT COUNT() FROM ContactPointAddress WHERE ParentId = :account.Id]);
		System.assertEquals(0, [SELECT COUNT() FROM ContactPointEmail WHERE ParentId = :account.Id]);

		try {
			FSC_LoanApplicantController.updateDebtorAccount(UserInfo.getUserId(), JSON.serialize(applicant));
			System.assert(false, 'Debió rechazar un contexto no soportado.');
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}
		applicant.put('FSC_TipoSolicitante__c', 'Garante');
		try {
			FSC_LoanApplicantController.updateDebtorAccount(account.Id, JSON.serialize(applicant));
			System.assert(false, 'Debió rechazar un solicitante que no sea deudor.');
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}
	}

	@IsTest
	static void datosContratoYControladorBaseSolaFirma() {
		ResidentialLoanApplication rla = createPyme('sola');
		ApexPages.currentPage().getParameters().put('fechaContrato', String.valueOf(Date.today()));

		FSC_DatosContratoController.OpcionEntrada option = new FSC_DatosContratoController.OpcionEntrada('Pesos', '1');
		FSC_DatosContratoController.CampoEntrada field = new FSC_DatosContratoController.CampoEntrada('clave', 'Etiqueta', 'valor', 'text');
		FSC_DatosContratoController.SeccionEntrada section = new FSC_DatosContratoController.SeccionEntrada('Sección');
		section.campos.add(field);
		System.assertEquals('1', option.value);

		FSC_DatosContratoController.ContextoGeneracion context = FSC_DatosContratoController.getContextoGeneracion(rla.Id);
		System.assertEquals(true, context.aplicaContrato);
		System.assertEquals(0, context.erroresConfiguracion.size());

		FSC_ContratoPrestamoComercialSFCtrl controller = new FSC_ContratoPrestamoComercialSFCtrl(new ApexPages.StandardController(rla));
		System.assertNotEquals(null, controller.datos);
		System.assertEquals(true, controller.getHasAnnexImage());
		System.assertNotEquals(null, controller.getPlaceholderValue('p001'));
		System.assertEquals('', controller.getPlaceholderValue('NO_EXISTE'));

		Map<String, Object> values = new Map<String, Object>{
			'clienteRnc' => '101000001',
			'clienteRegistroMercantil' => 'RM-EDITADO',
			'clienteDomicilio' => 'Domicilio editado',
			'representanteNombre' => 'Representante Editado',
			'representanteCargo' => 'Presidente',
			'representanteNacionalidad' => 'REPUBLICA DOMINICANA',
			'representanteEstadoCivil' => 'Casado(a)',
			'representanteIdentificacion' => '00100000002',
			'representanteDomicilio' => 'Domicilio representante',
			'autorizacionResolucion' => 'Nueva resolución',
			'autorizacionFecha' => String.valueOf(Date.today()),
			'autorizacionPersonas' => 'Persona autorizada',
			'autorizacionCalidad' => 'Presidente'
		};
		FSC_DatosContratoController.guardarDatosYPrepararGeneracion(rla.Id, null, null, null, false, true, JSON.serialize(values));
	}

	@IsTest
	static void queueableGeneraContratoPymeSolaFirma() {
		ResidentialLoanApplication rla = createPyme('queueable');

		Test.startTest();
		new FSC_GenerarContratoPDFQueueable(new List<Id>{ rla.Id }).execute(null);
		Test.stopTest();

		ResidentialLoanApplication updated = [
			SELECT FSC_Subestado__c, FSC_Contrato_Generado__c
			FROM ResidentialLoanApplication
			WHERE Id = :rla.Id
		];
		System.assertEquals('Gestionar firmas', updated.FSC_Subestado__c);
		System.assertEquals(true, updated.FSC_Contrato_Generado__c);
		System.assertEquals(1, [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :rla.Id]);
	}

	@IsTest
	static void datosContratoCubreGarantiasPyme() {
		ResidentialLoanApplication mortgage = createPyme('hipoteca');
		update new ResidentialLoanApplication(Id = mortgage.Id, FSC_Tipo_de_Garantia__c = 'Garantía Real');
		insert new LoanApplicationAsset(
			Name = 'Inmueble pendiente',
			LoanApplicationId = mortgage.Id,
			AssetClass = 'Bienes inmuebles',
			AssetType = 'Otro',
			FSC_Descripcion_de_la_Garantia__c = '3',
			FSC_Descripcion_Contrato__c = 'Inmueble identificado para prueba',
			FSC_Ubicacion_Contrato__c = 'Santo Domingo',
			FSC_Numero_Titulo_Contrato__c = 'TIT-001',
			FSC_Registro_Titulos_Contrato__c = 'Registro de Títulos',
			FSC_Fecha_Titulo_Contrato__c = Date.today()
		);

		ResidentialLoanApplication vehicle = createPyme('vehiculo');
		update new ResidentialLoanApplication(Id = vehicle.Id, FSC_Tipo_de_Garantia__c = 'Garantía Prendaria y/o Mobiliaria');
		insert new LoanApplicationAsset(
			Name = 'Vehículo pendiente',
			LoanApplicationId = vehicle.Id,
			AssetClass = 'Otro',
			AssetType = 'Otro',
			FSC_Descripcion_de_la_Garantia__c = '28',
			FSC_Tipo_Vehiculo_Contrato__c = 'Automóvil',
			FSC_Marca_Vehiculo_Contrato__c = 'Marca prueba',
			FSC_Modelo_Vehiculo_Contrato__c = 'Modelo prueba',
			FSC_Ano_Vehiculo_Contrato__c = 2025,
			FSC_Color_Vehiculo_Contrato__c = 'Blanco',
			FSC_Chasis_Vehiculo_Contrato__c = 'CHASIS-001',
			FSC_Motor_Vehiculo_Contrato__c = 'MOTOR-001',
			FSC_Placa_Vehiculo_Contrato__c = 'A000001',
			FSC_Matricula_Vehiculo_Contrato__c = 'MAT-001',
			CashOrMarketValue = 900000,
			FSC_Ubicacion_Contrato__c = 'Santo Domingo'
		);

		ResidentialLoanApplication certificate = createPyme('certificado');
		update new ResidentialLoanApplication(Id = certificate.Id, FSC_Tipo_de_Garantia__c = 'Garantía Prendaria y/o Mobiliaria');
		insert new LoanApplicationAsset(
			Name = 'Certificado pendiente',
			LoanApplicationId = certificate.Id,
			AssetClass = 'Financiero',
			AccountType = 'Certificado de depósito',
			FSC_Descripcion_de_la_Garantia__c = '31',
			AccountNumber = 'CD-PYME-001',
			FSC_Fecha_CD_Contrato__c = Date.today(),
			FSC_Titular_CD_Contrato__c = 'Empresa de prueba',
			CashOrMarketValue = 700000,
			FSC_Moneda_CD_Contrato__c = 'Pesos Dominicanos',
			FinancialInstitutionName = 'Banco Múltiple Vimenca, S. A.'
		);

		FSC_DatosContratoController.ContextoGeneracion mortgageContext = FSC_DatosContratoController.getContextoGeneracion(mortgage.Id);
		FSC_DatosContratoController.ContextoGeneracion vehicleContext = FSC_DatosContratoController.getContextoGeneracion(vehicle.Id);
		FSC_DatosContratoController.ContextoGeneracion certificateContext = FSC_DatosContratoController.getContextoGeneracion(certificate.Id);
		System.assertEquals('GARANTIA_HIPOTECARIA', mortgageContext.tipoContrato);
		System.assertEquals('GARANTIA_MOBILIARIA_SIN_POSESION', vehicleContext.tipoContrato);
		System.assertEquals('GARANTIA_MOBILIARIA_CON_POSESION', certificateContext.tipoContrato);

		saveContractData(mortgage.Id);
		saveContractData(vehicle.Id);
		saveContractData(certificate.Id);
	}

	@IsTest
	static void datosContratoCubreGarantiaSolidariaYActo() {
		ResidentialLoanApplication rla = createPyme('solidaria');
		update new ResidentialLoanApplication(Id = rla.Id, FSC_Tipo_de_Garantia__c = 'Garantía Solidaria', FSC_Requiere_Acto_Garantia__c = true);
		List<LoanApplicant> guarantors = new List<LoanApplicant>{
			new LoanApplicant(
				Name = 'Garante Uno',
				LoanApplicationId = rla.Id,
				FSC_TipoSolicitante__c = 'Garante',
				FSC_Nombre__c = 'Garante',
				FSC_PrimerApellido__c = 'Uno',
				FSC_TipoIdentificacion__c = 'Cédula',
				FSC_NumIdentificacion__c = '00100000111',
				FSC_Nacionalidad__c = 'REPUBLICA DOMINICANA',
				FSC_EstadoCivil__c = 'SOLTERO/A'
			),
			new LoanApplicant(
				Name = 'Garante Dos',
				LoanApplicationId = rla.Id,
				FSC_TipoSolicitante__c = 'Garante',
				FSC_Nombre__c = 'Garante',
				FSC_PrimerApellido__c = 'Dos',
				FSC_TipoIdentificacion__c = 'Cédula',
				FSC_NumIdentificacion__c = '00100000222',
				FSC_Nacionalidad__c = 'REPUBLICA DOMINICANA',
				FSC_EstadoCivil__c = 'CASADO/A'
			)
		};
		insert guarantors;

		ContactPointAddress oldestAddress = new ContactPointAddress(
			ParentId = rla.AccountId,
			FSC_Solicitante__c = guarantors[0].Id,
			Name = 'Dirección original',
			Street = 'Calle Primera',
			City = 'Santo Domingo',
			State = 'Distrito Nacional',
			Country = 'República Dominicana'
		);
		ContactPointAddress newestAddress = new ContactPointAddress(
			ParentId = rla.AccountId,
			FSC_Solicitante__c = guarantors[0].Id,
			Name = 'Dirección posterior',
			Street = 'Calle Segunda',
			City = 'Santiago',
			State = 'Santiago',
			Country = 'República Dominicana'
		);
		insert new List<ContactPointAddress>{ oldestAddress, newestAddress };
		Test.setCreatedDate(oldestAddress.Id, Datetime.now().addDays(-2));
		Test.setCreatedDate(newestAddress.Id, Datetime.now().addDays(-1));

		Test.startTest();
		FSC_DatosContratoController.ContextoGeneracion context = FSC_DatosContratoController.getContextoGeneracion(rla.Id);
		Test.stopTest();

		FSC_DatosContratoController.CampoEntrada addressField;
		for (FSC_DatosContratoController.SeccionEntrada section : context.seccionesContrato) {
			for (FSC_DatosContratoController.CampoEntrada inputField : section.campos) {
				if (inputField.clave == 'garanteDomicilio') {
					addressField = inputField;
				}
			}
		}
		Assert.areEqual('GARANTIA_SOLIDARIA', context.tipoContrato, 'Debe resolver el contrato con garantía solidaria.');
		Assert.isTrue(context.seccionesContrato.size() > 0, 'Debe construir las secciones del contrato.');
		Assert.isTrue(context.seccionesActoGarantia.size() > 0, 'Debe construir las secciones del acto de garantía.');
		Assert.isNotNull(addressField, 'Debe incluir el domicilio del garante.');
		Assert.areEqual(
			'Calle Primera, Santo Domingo, Distrito Nacional, República Dominicana',
			addressField.valor,
			'Debe usar el primer ContactPointAddress creado para el LoanApplicant.'
		);
	}

	@IsTest
	static void datosContratoYQueueableCubreGarantiasConsumo() {
		ResidentialLoanApplication mortgage = createConsumption('consumo-hipoteca');
		update new ResidentialLoanApplication(Id = mortgage.Id, FSC_Tipo_de_Garantia__c = 'Garantía Real', FSC_Excepcion_Contrato_Notarial__c = true);
		insert new FSC_Garantia__c(
			Name = 'Hipoteca consumo',
			FSC_Residential_Loan_Application__c = mortgage.Id,
			FSC_Clase_de_Garantia__c = 'BIENES INMUEBLES',
			FSC_Tipo_de_Garantia__c = 'Hipoteca',
			FSC_Descripcion_de_la_Garantia__c = 'Inmueble de prueba',
			FSC_Ubicacion__c = 'Santo Domingo',
			FSC_Numero_Titulo__c = 'TIT-C-001',
			FSC_Registro_de_Titulos__c = 'Registro de Títulos',
			FSC_Fecha_Expedicion_Titulo__c = Date.today()
		);

		ResidentialLoanApplication vehicle = createConsumption('consumo-vehiculo');
		update new ResidentialLoanApplication(
			Id = vehicle.Id,
			FSC_Tipo_de_Garantia__c = 'Garantía Prendaria y/o Mobiliaria',
			FSC_Excepcion_Contrato_Notarial__c = true
		);
		insert new FSC_Garantia__c(
			Name = 'Vehículo consumo',
			FSC_Residential_Loan_Application__c = vehicle.Id,
			FSC_Clase_de_Garantia__c = 'VEHICULOS USADOS-P2',
			FSC_Tipo_de_Garantia__c = 'Vehículo',
			FSC_Tipo_Vehiculo__c = 'Automóvil',
			FSC_Color_Vehiculo__c = 'Blanco',
			FSC_Numero_Chasis_Vehiculo__c = 'CHASIS-C-001',
			FSC_Serial_Motor_Vehiculo__c = 'MOTOR-C-001',
			FSC_Numero_Placa_Vehiculo__c = 'A000002',
			FSC_Numero_Matricula__c = 'MAT-C-001',
			FSC_Valor_Vehiculo__c = 850000,
			FSC_Ubicacion__c = 'Santo Domingo'
		);

		ResidentialLoanApplication certificate = createConsumption('consumo-certificado');
		update new ResidentialLoanApplication(
			Id = certificate.Id,
			FSC_Tipo_de_Garantia__c = 'Garantía Prendaria y/o Mobiliaria',
			FSC_Relacion_Propietario_CD__c = 'Persona distinta',
			FSC_Identificacion_Propietario_CD__c = '00100000333',
			FSC_Numero_Fisico_CD__c = 'FIS-001',
			FSC_Lugar_Pignoracion_CD__c = 'Santo Domingo',
			FSC_Nombre_Ejecutivo_Pignoracion__c = 'Ejecutivo Prueba',
			FSC_Cargo_Ejecutivo_Pignoracion__c = 'Oficial'
		);
		insert new FSC_Garantia__c(
			Name = 'Certificado consumo',
			FSC_Residential_Loan_Application__c = certificate.Id,
			FSC_Clase_de_Garantia__c = 'CERTIFICADOS DEPOSITOS BANCO VIMENCA',
			FSC_Tipo_de_Garantia__c = 'Certificado de depósito',
			FSC_Numero_Certificado_Deposito__c = 'CD-C-001',
			FSC_Fecha_Certificado_Deposito__c = Date.today(),
			FSC_Titular_Certificado_Deposito__c = 'Titular prueba',
			FSC_Monto_Certificado_Deposito__c = 700000,
			FSC_Moneda_Certificado_Deposito__c = 'Pesos Dominicanos',
			FSC_Emisor_Certificado_Deposito__c = 'Banco Múltiple Vimenca, S. A.'
		);

		System.assertEquals('CONSUMO_GARANTIA_HIPOTECARIA', FSC_DatosContratoController.getContextoGeneracion(mortgage.Id).tipoContrato);
		System.assertEquals('CONSUMO_GARANTIA_MOBILIARIA', FSC_DatosContratoController.getContextoGeneracion(vehicle.Id).tipoContrato);
		FSC_DatosContratoController.ContextoGeneracion certificateContext = FSC_DatosContratoController.getContextoGeneracion(certificate.Id);
		System.assertEquals(true, certificateContext.requierePignoracion);
		System.assert(certificateContext.seccionesPignoracion.size() > 0);

		Test.startTest();
		saveContractData(certificate.Id);
		System.enqueueJob(new FSC_GenerarContratoPDFQueueable(new List<Id>{ certificate.Id }));
		Test.stopTest();
		ResidentialLoanApplication updated = [
			SELECT FSC_Pignoracion_Generada__c, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :certificate.Id
		];
		System.assertEquals(true, updated.FSC_Pignoracion_Generada__c);
		System.assertEquals('Gestionar firmas', updated.FSC_Subestado__c);
	}

	@IsTest
	static void rlaAccionesCubreEdicionYFormatosSimples() {
		FSC_FabricaDatosDocumentosAnalisisTest.crearDatosBase();
		Account account = FSC_FabricaDatosDocumentosAnalisisTest.obtenerCuentaBase();
		ResidentialLoanApplication rla = FSC_FabricaDatosDocumentosAnalisisTest.crearSolicitud(
			account.Id,
			'FSC_Solicitud_Credito_Consumo',
			'En proceso',
			'Análisis de crédito',
			900000,
			true
		);
		update new ResidentialLoanApplication(
			Id = rla.Id,
			FSC_Resultado_Buro__c = 'Referido',
			FSC_Doc_Completa_Analisis__c = true,
			FSC_DocumentacionValidadaAnalista__c = true,
			FSC_DebeRevisarComite__c = false,
			FSC_DebeRevisarSupervisor__c = false,
			FSC_Aprobado_con_Condiciones__c = false
		);
		FSC_FabricaDatosDocumentosAnalisisTest.crearArchivo(rla.Id, 'Informe de Crédito - ' + rla.Name);
		FSC_RlaAccionesController.testPermitirEdicionDocumentosAnalisis = true;
		System.assertNotEquals(
			null,
			FSC_RlaAccionesController.getDatosDocumentoAnalisis(rla.Id, FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME)
		);
		ContentVersion versionConAjustesInvalidos = [
			SELECT Id, FSC_DatosEditadosAnalisis__c
			FROM ContentVersion
			WHERE Title LIKE 'Informe de Crédito%'
			ORDER BY CreatedDate DESC
			LIMIT 1
		];
		versionConAjustesInvalidos.FSC_DatosEditadosAnalisis__c = '{';
		update versionConAjustesInvalidos;
		System.assertNotEquals(
			null,
			FSC_RlaAccionesController.getDatosDocumentoAnalisis(rla.Id, FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME)
		);

		expectDocumentEditFailure(rla.Id, 'NO_SOPORTADO', '{}');
		expectDocumentEditFailure(null, FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME, '{}');
		expectDocumentEditFailure(rla.Id, FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME, ' ');
		expectDocumentEditFailure(rla.Id, FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME, '{');
		expectDocumentEditFailure(rla.Id, FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME, '[1]');
		expectDocumentEditFailure(rla.Id, FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME, '{}');
		expectDocumentEditFailure(
			rla.Id,
			FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME,
			JSON.serialize(new Map<String, Object>{ 'rutaInexistente' => new Map<String, Object>{ 'value' => 'x', 'format' => 'text' } })
		);
		expectDocumentEditFailure(
			rla.Id,
			FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME,
			JSON.serialize(new Map<String, Object>{ 'solicitante' => 'valor sin estructura' })
		);
		expectDocumentEditFailure(
			rla.Id,
			FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME,
			JSON.serialize(new Map<String, Object>{ 'solicitante' => new Map<String, Object>{ 'value' => 'x', 'format' => 'date' } })
		);

		String oversized = '';
		while (oversized.length() <= 20000)
			oversized += 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
		List<Map<String, Object>> invalidValues = new List<Map<String, Object>>{
			new Map<String, Object>{ 'path' => 'solicitante', 'value' => oversized, 'format' => 'text' },
			new Map<String, Object>{ 'path' => 'fechaEvaluacion', 'value' => 'fecha inválida', 'format' => 'date' },
			new Map<String, Object>{ 'path' => 'edad', 'value' => '20.5', 'format' => 'integer' },
			new Map<String, Object>{ 'path' => 'tasaInteres', 'value' => '-1', 'format' => 'percent' },
			new Map<String, Object>{ 'path' => 'plazoMeses', 'value' => '100', 'format' => 'integer' },
			new Map<String, Object>{ 'path' => 'tiempoTasaFija', 'value' => '100', 'format' => 'integer' },
			new Map<String, Object>{ 'path' => 'edad', 'value' => '151', 'format' => 'integer' },
			new Map<String, Object>{ 'path' => 'garantiaSuperficie', 'value' => 'ABC', 'format' => 'number' }
		};
		for (Map<String, Object> invalidValue : invalidValues) {
			String path = String.valueOf(invalidValue.get('path'));
			expectDocumentEditFailure(
				rla.Id,
				FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME,
				JSON.serialize(
					new Map<String, Object>{
						path => new Map<String, Object>{ 'value' => invalidValue.get('value'), 'format' => invalidValue.get('format') }
					}
				)
			);
		}

		FSC_RlaAccionesController.guardarYRegenerarDocumentoAnalisis(
			rla.Id,
			FSC_ColaGeneracionDocumentosAnalisis.DOCUMENTO_INFORME,
			JSON.serialize(
				new Map<String, Object>{
					'solicitante' => new Map<String, Object>{ 'value' => '', 'format' => 'text' },
					'fechaEvaluacion' => new Map<String, Object>{ 'value' => String.valueOf(Date.today()), 'format' => 'date' },
					'fechaAprobacion' => new Map<String, Object>{ 'value' => '', 'format' => 'date' },
					'garantiaSuperficie' => new Map<String, Object>{ 'value' => '125.5', 'format' => 'number' },
					'montoAprobado' => new Map<String, Object>{ 'value' => '1000', 'format' => 'money' }
				}
			)
		);
	}

	@IsTest
	static void rlaAccionesCubreActualizacionesYGuardasSimples() {
		ResidentialLoanApplication pagare = createPyme('acciones-pagare');
		FSC_RlaAccionesController.guardarDatosPagareComplementario(pagare.Id, ' PRESTAMO-001 ');
		FSC_RlaAccionesController.aprobarProcesoActual(pagare.Id, 'Aprobación sin proceso activo');

		ResidentialLoanApplication estados = createPyme('acciones-estados');
		try {
			FSC_RlaAccionesController.marcarCreadoEnAbanks(estados.Id);
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}
		try {
			FSC_RlaAccionesController.marcarDesembolsado(estados.Id);
		} catch (AuraHandledException expected) {
			System.assertNotEquals(null, expected);
		}

		try {
			FSC_RlaAccionesController.validarDocumentacionAnalista(null);
		} catch (AuraHandledException expected) {
		}
		try {
			FSC_RlaAccionesController.reintentarListas(null);
		} catch (AuraHandledException expected) {
		}
		try {
			FSC_RlaAccionesController.reintentarBuro(null);
		} catch (AuraHandledException expected) {
		}
		try {
			FSC_RlaAccionesController.validarCreacionEnAbanks(null);
		} catch (AuraHandledException expected) {
		}
		try {
			FSC_RlaAccionesController.reintentarCreacionPrestamo(null);
		} catch (AuraHandledException expected) {
		}
		try {
			FSC_RlaAccionesController.reintentarDesembolso(null);
		} catch (AuraHandledException expected) {
		}
		try {
			FSC_RlaAccionesController.reintentarCreacionPrestamo(pagare.Id);
		} catch (AuraHandledException expected) {
		}
		try {
			FSC_RlaAccionesController.reintentarDesembolso(pagare.Id);
		} catch (AuraHandledException expected) {
		}

		ResidentialLoanApplication refreshed = [SELECT FSC_Numero_Prestamo_Pagare__c FROM ResidentialLoanApplication WHERE Id = :pagare.Id];
		System.assertEquals('PRESTAMO-001', refreshed.FSC_Numero_Prestamo_Pagare__c);
	}

	// La org exige Oficina, Codigo y Canal de Atencion en todo usuario (regla Validar_Campos_Obligatorios_Usuario).
	private static void completarCamposObligatoriosUsuario(User usuario) {
		Map<String, Schema.SObjectField> campos = Schema.SObjectType.User.fields.getMap();
		for (String campo : new List<String>{ 'USE_Oficina__c', 'Canal_Atencion__c' }) {
			if (!campos.containsKey(campo)) {
				continue;
			}
			for (Schema.PicklistEntry valor : campos.get(campo).getDescribe().getPicklistValues()) {
				if (valor.isActive()) {
					usuario.put(campo, valor.getValue());
					break;
				}
			}
		}
		if (campos.containsKey('USE_Codigo__c')) {
			usuario.put('USE_Codigo__c', 'TEST');
		}
		if (campos.containsKey('USE_Oficina__c')) {
			asegurarOficinaEnDatosMaestros((String) usuario.get('USE_Oficina__c'));
		}
	}

	// El flow "Información usuario" busca la oficina del usuario en Datos_Maestros__c y falla si no existe.
	private static void asegurarOficinaEnDatosMaestros(String oficina) {
		if (String.isBlank(oficina) || [SELECT COUNT() FROM Datos_Maestros__c WHERE DM_Codigo_Oficina__c = :oficina AND DM_Tipo__c = 'Oficina'] > 0) {
			return;
		}
		System.runAs(new User(Id = UserInfo.getUserId())) {
			insert new Datos_Maestros__c(Name = 'Oficina test ' + oficina, DM_Codigo_Oficina__c = oficina, DM_Tipo__c = 'Oficina');
		}
	}
}