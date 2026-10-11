@IsTest
private class FSC_ContratoRedaccionCtrlTest {
	private static Id rlaRecordType(String developerName) {
		return Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName().get(developerName).getRecordTypeId();
	}

	private static String firstPicklistValue(Schema.SObjectField field) {
		for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
			if (entry.isActive()) return entry.getValue();
		}
		return null;
	}

	private static ResidentialLoanApplication newPyme(Id accountId, String guaranteeType, Map<String, Object> savedValues) {
		return new ResidentialLoanApplication(
			Name = 'RLA redacción ' + guaranteeType,
			AccountId = accountId,
			RecordTypeId = rlaRecordType('FSC_Solicitud_Credito_PYME'),
			Status = 'En proceso',
			FSC_Subestado__c = 'Generación de contrato',
			FSC_TipoSolicitud__c = 'BPR',
			FSC_Tipo_de_Garantia__c = guaranteeType,
			FSC_Moneda__c = '1',
			FSC_Monto__c = 500000,
			FSC_MontoAprobado__c = 450000,
			FSC_TasaInteres__c = 12,
			FSC_TasaInteresAprobada__c = 11,
			FSC_Plazo_meses__c = '24',
			FSC_PlazoMesesAprobado__c = 24,
			FSC_Destino_del_Prestamo__c = 'Capital de trabajo',
			FSC_Fecha_Contrato__c = Date.today(),
			FSC_Domicilio_Cliente_Contrato__c = 'Calle 4 No. 17, Santo Domingo',
			FSC_Datos_Intervinientes_Contrato__c = JSON.serialize(savedValues),
			FSC_UsuarioPagaresYContratos__c = UserInfo.getUserId()
		);
	}

	private static ResidentialLoanApplication createPersonSolaFirma(Map<String, Object> savedValues) {
		Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
		Account account = new Account(
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(),
			FirstName = 'Ana',
			LastName = 'Redacción',
			ACC_NumIdentificacion__c = '40200695563'
		);
		insert account;
		ResidentialLoanApplication rla = newPyme(account.Id, 'Sin Garantía', savedValues);
		rla.FSC_Identificacion_Cliente_Contrato__c = '40200695563';
		rla.FSC_Nacionalidad_Cliente_Contrato__c = 'Dominicana';
		rla.FSC_Estado_Civil_Cliente_Contrato__c = 'Soltera';
		rla.FSC_NumeroPolizaSeguroDeVida__c = 'VIDA-1';
		insert rla;
		return rla;
	}

	private static Map<String, Object> lifeInsurance() {
		return new Map<String, Object>{
			'clienteSexo' => FSC_ContratoParte.SEXO_FEMENINO,
			'seguroVidaAseguradora' => 'Seguros de prueba, S. A.',
			'seguroVidaDireccion' => 'Av. Winston Churchill, Santo Domingo',
			'seguroVidaPrima' => '850'
		};
	}

	private static FSC_DatosContratoController.CampoEntrada findField(FSC_DatosContratoController.ContextoGeneracion context, String key) {
		for (FSC_DatosContratoController.SeccionEntrada section : context.seccionesContrato) {
			for (FSC_DatosContratoController.CampoEntrada field : section.campos) {
				if (field.clave == key) return field;
			}
		}
		return null;
	}

	@IsTest
	static void solaFirmaPersonaFisicaLlevaSeguroDeVidaColectivo() {
		ResidentialLoanApplication rla = createPersonSolaFirma(lifeInsurance());
		Test.setCurrentPage(Page.FSC_ContratoPrestamoComercialSF);

		Test.startTest();
		FSC_DatosContratoController.ContextoGeneracion context = FSC_DatosContratoController.getContextoGeneracion(rla.Id);
		FSC_ContratoPrestamoComercialSFCtrl controller = new FSC_ContratoPrestamoComercialSFCtrl(new ApexPages.StandardController(rla));
		Test.stopTest();

		System.assertEquals('VIDA-1', findField(context, 'seguroVidaPoliza').valor, 'La póliza de vida se precarga de la solicitud.');
		System.assertEquals(FSC_ContratoParte.SEXO_FEMENINO, findField(context, 'clienteSexo').valor);
		System.assertEquals('LA PRESTATARIA', controller.deudor.nombre);
		System.assertEquals(controller.deudor, controller.sujetoGeneral);
		System.assertEquals(true, controller.seguroVida.aplica);
		System.assertEquals(false, controller.seguroVida.endosado);
		System.assertEquals('24', controller.seguroVida.cuotasNumero);
		System.assertEquals(false, controller.seguroPropiedad.aplica);
		System.assertEquals(false, controller.garantiaInmueble);
		System.assert(controller.clienteGenerales.contains('portadora de la cédula de identidad y electoral No. 402-0069556-3'));
		System.assertEquals(1, controller.firmantesCliente.size());
	}

	@IsTest
	static void validaQueCadaPolizaTraigaLosDatosDeSuVersion() {
		Map<String, Object> saved = lifeInsurance();
		saved.remove('seguroVidaPrima');
		ResidentialLoanApplication rla = createPersonSolaFirma(saved);

		FSC_DatosContratoController.ContextoGeneracion context = FSC_DatosContratoController.getContextoGeneracion(rla.Id);
		List<String> errors = FSC_DatosContratoController.validarDatosCombinados(context);
		System.assertEquals(1, errors.size());
		System.assert(errors[0].contains('prima mensual del seguro de vida'));

		findField(context, 'seguroVidaFechaEndoso').valor = String.valueOf(Date.today());
		findField(context, 'seguroVidaMonto').valor = '';
		errors = FSC_DatosContratoController.validarDatosCombinados(context);
		System.assertEquals(1, errors.size());
		System.assert(errors[0].contains('monto asegurado del seguro de vida endosado'));

		findField(context, 'seguroVidaMonto').valor = '1000000';
		System.assertEquals(0, FSC_DatosContratoController.validarDatosCombinados(context).size());
	}

	@IsTest
	static void garantiaSolidariaConEmpresaYVariosGerentes() {
		Account account = new Account(
			Name = 'COMIENDO BUENO GIL RD, S.R.L.',
			ACC_TipoIdentificacion__c = 'RNC',
			ACC_NumIdentificacion__c = '131716342',
			ACC_RNC__c = '131716342',
			VFS_RegistroMercantil__c = '145454SD',
			BillingStreet = 'Calle 4 No. 17',
			BillingCity = 'Santo Domingo'
		);
		insert account;
		Map<String, Object> saved = new Map<String, Object>{
			'representanteSexo' => FSC_ContratoParte.SEXO_FEMENINO,
			'garanteSexo' => FSC_ContratoParte.SEXO_MASCULINO,
			'representante2_nombre' => 'WILKI ONASIS GIL VILLAR',
			'representante2_cargo' => 'Gerente',
			'representante2_sexo' => FSC_ContratoParte.SEXO_MASCULINO,
			'representante2_nacionalidad' => 'Dominicano',
			'representante2_estadoCivil' => 'Soltero',
			'representante2_identificacion' => '00113130439',
			'representante2_domicilio' => 'Calle 4 No. 17, Santo Domingo'
		};
		ResidentialLoanApplication rla = newPyme(account.Id, 'Garantía Solidaria', saved);
		rla.FSC_RNC_Cliente_Contrato__c = '131716342';
		rla.FSC_Registro_Mercantil_Contrato__c = '145454SD';
		rla.FSC_Nombre_Representante_Cliente__c = 'NICOLE YENISE UREÑA ABREU';
		rla.FSC_Cargo_Representante_Cliente__c = 'Gerente';
		rla.FSC_Nacionalidad_Representante__c = 'Dominicana';
		rla.FSC_Estado_Civil_Representante__c = 'Soltera';
		rla.FSC_Identificacion_Representante__c = '40200695563';
		rla.FSC_Domicilio_Representante__c = 'Calle 4 No. 17, Santo Domingo';
		rla.FSC_Resolucion_Autorizacion__c = 'Primera Resolución';
		rla.FSC_Fecha_Acta_Autorizacion__c = Date.today();
		rla.FSC_Personas_Autorizadas__c = 'Los Gerentes';
		rla.FSC_Calidad_Autorizados__c = 'Gerentes';
		rla.FSC_Nombre_Garante_Contrato__c = 'PEDRO GARANTE';
		rla.FSC_Identificacion_Garante_Contrato__c = '00100000102';
		rla.FSC_Nacionalidad_Garante_Contrato__c = 'Dominicano';
		rla.FSC_Estado_Civil_Garante_Contrato__c = 'Casado';
		rla.FSC_Domicilio_Garante_Contrato__c = 'Santiago';
		insert rla;
		insert new LoanApplicant(
			Name = 'Garante 102',
			LoanApplicationId = rla.Id,
			FSC_TipoSolicitante__c = 'Garante',
			FSC_TipoIdentificacion__c = firstPicklistValue(LoanApplicant.FSC_TipoIdentificacion__c),
			FSC_Nombre__c = 'PEDRO',
			FSC_PrimerApellido__c = 'GARANTE',
			FSC_NumIdentificacion__c = '00100000102',
			FSC_Nacionalidad__c = firstPicklistValue(LoanApplicant.FSC_Nacionalidad__c),
			FSC_EstadoCivil__c = firstPicklistValue(LoanApplicant.FSC_EstadoCivil__c)
		);
		Test.setCurrentPage(Page.FSC_ContratoPrestamoComercialGS);

		Test.startTest();
		FSC_DatosContratoController.ContextoGeneracion context = FSC_DatosContratoController.getContextoGeneracion(rla.Id);
		FSC_ContratoPrestamoComercialGSCtrl controller = new FSC_ContratoPrestamoComercialGSCtrl(new ApexPages.StandardController(rla));
		Test.stopTest();

		System.assertEquals('WILKI ONASIS GIL VILLAR', findField(context, 'representante2_nombre').valor);
		System.assertEquals(false, findField(context, 'representante3_nombre').requerido);
		System.assertEquals(null, findField(context, 'seguroVidaPoliza'), 'Una empresa no lleva seguro de vida.');
		System.assertEquals('LA PRESTATARIA', controller.deudor.nombre);
		System.assertEquals('EL GARANTE SOLIDARIO', controller.garante.nombre);
		System.assertEquals('LA PRESTATARIA y EL GARANTE SOLIDARIO', controller.sujetoGeneral.nombre);
		System.assert(controller.clienteGenerales.contains('RNC No. 1-31-71634-2'));
		System.assert(controller.clienteGenerales.contains('debidamente representada por sus Gerentes, señores NICOLE YENISE UREÑA ABREU, dominicana'));
		System.assert(controller.garanteGenerales.startsWith('PEDRO GARANTE, dominicano'));
		System.assertEquals(2, controller.firmantesCliente.size());
		System.assert(controller.datos.nombresFirmantesNotario.contains('WILKI ONASIS GIL VILLAR'));
		System.assert(controller.datos.nombresFirmantesNotario.contains('PEDRO GARANTE'));
		System.assertEquals(false, controller.seguroVida.aplica);

		findField(context, 'representante2_cargo').valor = '';
		List<String> errors = FSC_DatosContratoController.validarDatosCombinados(context);
		System.assertEquals(1, errors.size());
		System.assert(errors[0].contains('WILKI ONASIS GIL VILLAR'));
	}

	@IsTest
	static void guardarDatosConservaSexoYSeguroDeVidaEnLaSolicitud() {
		ResidentialLoanApplication rla = createPersonSolaFirma(new Map<String, Object>{ 'otroDato' => 'se conserva' });
		Map<String, Object> values = lifeInsurance();
		values.put('clienteIdentificacion', '40200695563');

		Test.startTest();
		FSC_DatosContratoController.guardarDatosYPrepararGeneracion(rla.Id, null, null, null, false, true, JSON.serialize(values));
		Test.stopTest();

		Map<String, Object> saved = FSC_ContratoIntervinienteService.parse(
			[SELECT FSC_Datos_Intervinientes_Contrato__c FROM ResidentialLoanApplication WHERE Id = :rla.Id].FSC_Datos_Intervinientes_Contrato__c
		);
		System.assertEquals(FSC_ContratoParte.SEXO_FEMENINO, saved.get('clienteSexo'));
		System.assertEquals('850', saved.get('seguroVidaPrima'));
		System.assertEquals('se conserva', saved.get('otroDato'));
		System.assertEquals(false, saved.containsKey('clienteIdentificacion'), 'Los datos del cliente se guardan en sus campos.');
	}
}