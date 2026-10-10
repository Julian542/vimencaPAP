@IsTest
private class FSC_CatalogoGarantiaServiceTest {
	private static final String CLASE_AGRO_API = 'SOLARES O TERRENOS PARA FINES AGROPECUARIOS-I2';
	private static final String CLASE_AGRO_HISTORICA = 'SOLARES O TERRENOS PARA FINES AGROPECUARIOS I2';
	private static final String TIPO_AGRO_API = 'SOLARES O TERRENOS PARA FINES AGROPECUARIOS-RD$-I2';

	private static FSC_CatalogoGarantia__c registro(String catalogo, Integer codigo, Integer padre, String descripcion) {
		return new FSC_CatalogoGarantia__c(
			Name = descripcion.left(80),
			FSC_Clave__c = FSC_CatalogoGarantiaSyncJob.construirClave(catalogo, padre, codigo),
			FSC_Tipo_Catalogo__c = catalogo,
			FSC_Codigo__c = codigo,
			FSC_Codigo_Padre__c = padre,
			FSC_Descripcion__c = descripcion,
			FSC_Activo__c = true
		);
	}

	private static void crearCatalogo() {
		Database.insert(new List<FSC_CatalogoGarantia__c>{
			registro('Clase', 24, null, CLASE_AGRO_API),
			registro('Clase', 15, null, 'MAQUINARIAS INDUSTRIALES'),
			registro('Clase', 1, null, 'BIENES INMUEBLES'),
			registro('Tipo', 37, 24, TIPO_AGRO_API),
			registro('Tipo', 52, 15, 'CALENTADORES SOLARES PARA AGUA Y/O ACEITE TÉRMICO-J4'),
			registro('Tipo', 6, 1, 'MAQUINARIAS Y EQUIPOS DE USO MULTIPLE (RD$)- H2'),
			registro('Marca', 5, null, 'TOYOTA'),
			registro('Modelo', 7, 5, 'COROLLA'),
			registro('Modelo', 9, 5, 'COROLLA'),
			registro('Modelo', 8, 5, 'HILUX')
		}, AccessLevel.SYSTEM_MODE);
		FSC_CatalogoGarantiaService.limpiarCache();
	}

	private static void asignarPermisosAdministrador() {
		System.runAs(new User(Id = UserInfo.getUserId())) {
			PermissionSet permiso = [SELECT Id FROM PermissionSet WHERE Name = 'FSC_PS_Administrador' LIMIT 1];
			// El usuario que ejecuta los tests puede tener ya el permission set asignado.
			if ([SELECT COUNT() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :permiso.Id] == 0) {
				insert new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(), PermissionSetId = permiso.Id);
			}
		}
	}

	@IsTest
	static void normalizarClave_ignoraAcentosEspaciosYSignos() {
		Assert.areEqual(
			FSC_CatalogoGarantiaService.normalizarClave(CLASE_AGRO_HISTORICA),
			FSC_CatalogoGarantiaService.normalizarClave(CLASE_AGRO_API),
			'El texto historico y el del API deben ser la misma clase.'
		);
		Assert.areEqual('GARANTIATERMICO', FSC_CatalogoGarantiaService.normalizarClave('Garantía - Térmico'), 'Debe quitar acentos y signos.');
		Assert.areEqual('', FSC_CatalogoGarantiaService.normalizarClave(null), 'Un valor vacio no debe fallar.');
	}

	@IsTest
	static void getTextoClasificacion_usaLaClaseCuandoExiste() {
		Assert.areEqual(
			'MAQUINARIAS INDUSTRIALES',
			FSC_CatalogoGarantiaService.getTextoClasificacion('MAQUINARIAS INDUSTRIALES', 'CALENTADORES SOLARES'),
			'Con clase, el tipo no debe influir en la categoria.'
		);
		Assert.areEqual(
			'null PRENDARIA VEHICULOS',
			FSC_CatalogoGarantiaService.getTextoClasificacion(null, 'PRENDARIA VEHICULOS'),
			'Sin clase se conserva el texto historico de clasificacion.'
		);
	}

	@IsTest
	static void resolverCodigos_completaCodigosDesdeElCatalogo() {
		crearCatalogo();
		FSC_Garantia__c nueva = new FSC_Garantia__c(
			FSC_Clase_de_Garantia__c = CLASE_AGRO_HISTORICA,
			FSC_Tipo_de_Garantia__c = TIPO_AGRO_API,
			FSC_Marca_Vehiculo__c = 'Toyota',
			FSC_Modelo_Vehiculo__c = 'Corolla'
		);

		Test.startTest();
		FSC_CatalogoGarantiaService.resolverCodigos(new List<FSC_Garantia__c>{ nueva }, null);
		Test.stopTest();

		Assert.areEqual(24, nueva.FSC_Codigo_Clase_Garantia__c, 'El texto historico debe resolver el codigo de la clase.');
		Assert.areEqual(37, nueva.FSC_Codigo_Tipo_Garantia__c, 'El tipo se resuelve dentro de su clase.');
		Assert.areEqual(5, nueva.FSC_Codigo_Marca_Vehiculo__c, 'La marca se resuelve sin importar mayusculas.');
		Assert.areEqual(7, nueva.FSC_Codigo_Modelo_Vehiculo__c, 'Ante un modelo repetido gana el menor codigo.');
	}

	@IsTest
	static void resolverCodigos_soloRecalculaLoQueCambio() {
		crearCatalogo();
		Id garantiaId = FSC_Garantia__c.SObjectType.getDescribe().getKeyPrefix() + '000000000001';
		FSC_Garantia__c anterior = new FSC_Garantia__c(
			Id = garantiaId,
			FSC_Clase_de_Garantia__c = 'BIENES INMUEBLES',
			FSC_Tipo_de_Garantia__c = 'TIPO HISTORICO',
			FSC_Codigo_Clase_Garantia__c = 1
		);
		FSC_Garantia__c sinCambios = anterior.clone(true, true);
		sinCambios.FSC_Codigo_Clase_Garantia__c = 999;
		FSC_Garantia__c conCambioDeTipo = anterior.clone(true, true);
		conCambioDeTipo.FSC_Tipo_de_Garantia__c = 'MAQUINARIAS Y EQUIPOS DE USO MULTIPLE (RD$)- H2';

		Test.startTest();
		FSC_CatalogoGarantiaService.resolverCodigos(new List<FSC_Garantia__c>{ sinCambios }, new Map<Id, FSC_Garantia__c>{ garantiaId => anterior });
		FSC_CatalogoGarantiaService.resolverCodigos(
			new List<FSC_Garantia__c>{ conCambioDeTipo },
			new Map<Id, FSC_Garantia__c>{ garantiaId => anterior }
		);
		Test.stopTest();

		Assert.areEqual(999, sinCambios.FSC_Codigo_Clase_Garantia__c, 'Sin cambio de textos no se toca ningun codigo.');
		Assert.areEqual(1, conCambioDeTipo.FSC_Codigo_Clase_Garantia__c, 'Si solo cambia el tipo, la clase conserva su codigo.');
		Assert.areEqual(6, conCambioDeTipo.FSC_Codigo_Tipo_Garantia__c, 'El tipo nuevo debe resolver su codigo.');
	}

	@IsTest
	static void grupos_reconocenTextoHistoricoYDescripcionDelApi() {
		crearCatalogo();
		Database.update(
			new FSC_CatalogoGarantia__c(
				Id = [SELECT Id FROM FSC_CatalogoGarantia__c WHERE FSC_Clave__c = 'CLASE-24' WITH SYSTEM_MODE].Id,
				FSC_Descripcion__c = 'TERRENOS AGROPECUARIOS RENOMBRADOS EN EL CORE'
			),
			AccessLevel.SYSTEM_MODE
		);
		FSC_CatalogoGarantiaService.limpiarCache();

		Test.startTest();
		String grupoHistorico = FSC_GarantiaFormalizacionService.obtenerGrupo(CLASE_AGRO_HISTORICA);
		String grupoApi = FSC_GarantiaFormalizacionService.obtenerGrupo(CLASE_AGRO_API);
		String grupoRenombrado = FSC_CatalogoGarantiaService.getGrupo('TERRENOS AGROPECUARIOS RENOMBRADOS EN EL CORE');
		String checklistHistorico = FSC_ChecklistDocsController.resolveTipoSolicitudByClaseGarantia(CLASE_AGRO_HISTORICA);
		String checklistApi = FSC_ChecklistDocsController.resolveTipoSolicitudByClaseGarantia(CLASE_AGRO_API);
		Test.stopTest();

		Assert.areEqual('real-estate', grupoHistorico, 'El texto historico sigue siendo hipotecario.');
		Assert.areEqual('real-estate', grupoApi, 'La descripcion del API debe exigir formalizacion hipotecaria.');
		Assert.areEqual('real-estate', grupoRenombrado, 'Una clase renombrada en el core conserva su grupo por codigo.');
		Assert.isNotNull(checklistApi, 'El checklist debe reconocer la clase del API.');
		Assert.areEqual(checklistHistorico, checklistApi, 'El checklist debe ser el mismo para ambos textos.');
	}

	@IsTest
	static void clasificacion_noCambiaPorPalabrasDelTipoDelCore() {
		asignarPermisosAdministrador();
		Account cuenta = FSC_ExcepcionTestDataFactory.createAccount('9911', true);
		ResidentialLoanApplication maquinaria = FSC_ExcepcionTestDataFactory.createSolicitud(cuenta.Id, 'RLA Calentador', 'Gestionar firmas', 3000000, true);
		ResidentialLoanApplication inmueble = FSC_ExcepcionTestDataFactory.createSolicitud(cuenta.Id, 'RLA Inmueble', 'Gestionar firmas', 3000000, true);
		insert new List<FSC_Garantia__c>{
			new FSC_Garantia__c(
				Name = 'CALENTADORES SOLARES PARA AGUA Y/O ACEITE TÉRMICO-J4',
				FSC_Residential_Loan_Application__c = maquinaria.Id,
				FSC_Clase_de_Garantia__c = 'MAQUINARIAS INDUSTRIALES',
				FSC_Tipo_de_Garantia__c = 'CALENTADORES SOLARES PARA AGUA Y/O ACEITE TÉRMICO-J4'
			),
			new FSC_Garantia__c(
				Name = 'MAQUINARIAS Y EQUIPOS DE USO MULTIPLE (RD$)- H2',
				FSC_Residential_Loan_Application__c = inmueble.Id,
				FSC_Clase_de_Garantia__c = 'BIENES INMUEBLES',
				FSC_Tipo_de_Garantia__c = 'MAQUINARIAS Y EQUIPOS DE USO MULTIPLE (RD$)- H2'
			)
		};

		Test.startTest();
		FSC_ConsumoDocumentoResolver.ResolucionDocumento resolucion = FSC_ConsumoDocumentoResolver.resolve(maquinaria.Id);
		FSC_TipoGarantiaService.recalculate(new Set<Id>{ maquinaria.Id, inmueble.Id });
		Test.stopTest();

		Assert.areNotEqual(
			FSC_ConsumoDocumentoResolver.GARANTIA_HIPOTECARIA,
			resolucion.tipoGarantia,
			'Un calentador solar es maquinaria: no debe generar documentos hipotecarios.'
		);
		Map<Id, ResidentialLoanApplication> solicitudes = new Map<Id, ResidentialLoanApplication>(
			[SELECT FSC_Tipo_de_Garantia__c FROM ResidentialLoanApplication WHERE Id IN :new Set<Id>{ maquinaria.Id, inmueble.Id }]
		);
		Assert.areEqual(
			FSC_TipoGarantiaService.GARANTIA_REAL,
			solicitudes.get(inmueble.Id).FSC_Tipo_de_Garantia__c,
			'Un inmueble sigue siendo garantia real aunque el tipo mencione maquinarias.'
		);
		Assert.areEqual(
			FSC_TipoGarantiaService.GARANTIA_PRENDARIA,
			solicitudes.get(maquinaria.Id).FSC_Tipo_de_Garantia__c,
			'La maquinaria sigue siendo prendaria.'
		);
	}

	@IsTest
	static void controlador_entregaClasesTiposMarcasYModelosDelCatalogo() {
		crearCatalogo();

		Test.startTest();
		List<FSC_LoanFacilityController.GuaranteeClassDTO> clases = FSC_LoanFacilityController.getGuaranteeConfiguration();
		List<FSC_LoanFacilityController.VehicleOptionDTO> marcas = FSC_LoanFacilityController.getVehicleCatalog();
		Test.stopTest();

		Map<Integer, FSC_LoanFacilityController.GuaranteeClassDTO> clasesPorCodigo = new Map<Integer, FSC_LoanFacilityController.GuaranteeClassDTO>();
		for (FSC_LoanFacilityController.GuaranteeClassDTO clase : clases) {
			clasesPorCodigo.put(clase.code, clase);
		}
		Assert.areEqual(3, clases.size(), 'Debe mostrar solo las clases del catalogo.');
		Assert.isTrue(clasesPorCodigo.get(24).fromCatalog, 'La configuracion debe venir del catalogo.');
		Assert.areEqual('real-estate', clasesPorCodigo.get(24).groupName, 'El grupo se toma del CMT por codigo.');
		Assert.isTrue(clasesPorCodigo.get(24).aliases.contains(CLASE_AGRO_HISTORICA), 'Debe incluir el texto historico como alias.');
		Assert.areEqual(TIPO_AGRO_API, clasesPorCodigo.get(24).types[0].value, 'Solo los tipos de la clase.');
		Assert.areEqual('general', clasesPorCodigo.get(15).groupName, 'Maquinarias es grupo general.');
		Assert.areEqual(1, marcas.size(), 'Debe devolver la marca.');
		Assert.areEqual(2, marcas[0].models.size(), 'Un modelo repetido dentro de la marca se muestra una vez.');
	}

	@IsTest
	static void datosContrato_usaCatalogoYConservaValorHistorico() {
		crearCatalogo();

		Test.startTest();
		FSC_DatosContratoController.CampoEntrada marca = FSC_DatosContratoController.vehicleBrandField('Toyota');
		FSC_DatosContratoController.CampoEntrada modelo = FSC_DatosContratoController.vehicleModelField('Toyota', 'Corolla');
		FSC_DatosContratoController.CampoEntrada modeloApi = FSC_DatosContratoController.vehicleModelField('TOYOTA', 'HILUX');
		Test.stopTest();

		Assert.areEqual('Toyota', marca.opciones[0].value, 'La marca historica se conserva como primera opcion.');
		Assert.areEqual(2, marca.opciones.size(), 'Debe incluir la marca del catalogo.');
		Boolean historicoIncluido = false;
		for (FSC_DatosContratoController.OpcionEntrada opcion : modelo.opciones) {
			historicoIncluido = historicoIncluido || (opcion.value == 'Corolla' && opcion.controlador == 'Toyota');
		}
		Assert.isTrue(historicoIncluido, 'El modelo historico se conserva asociado a su marca.');
		Assert.areEqual(2, modeloApi.opciones.size(), 'Con un valor del catalogo no se agregan opciones extra.');
		Assert.areEqual('TOYOTA', modeloApi.opciones[0].controlador, 'Cada modelo indica su marca.');
	}
}