@IsTest
private class FSC_FormalizacionNotificacionesTest {
	private static final String SOLICITUD = 'RLA Avisos Formalizacion';

	@TestSetup
	static void setupData() {
		// Estos datos no prueban la política de crédito; sus límites se prueban en FSC_CreditPolicyGuardTest.
		FSC_CreditPolicyGuard.bypassInTests = true;
		Account cuenta = FSC_ExcepcionTestDataFactory.createAccount('4901', true);
		ResidentialLoanApplication rla = FSC_ExcepcionTestDataFactory.createSolicitud(cuenta.Id, SOLICITUD, 'Gestionar firmas', 400000, true);
		insert new FSC_Garantia__c(
			Name = 'Hipoteca avisos',
			FSC_Residential_Loan_Application__c = rla.Id,
			FSC_Clase_de_Garantia__c = 'BIENES INMUEBLES',
			FSC_Tipo_de_Garantia__c = 'Hipoteca avisos'
		);
	}

	@IsTest
	static void decideCuandoAvisar() {
		Id otro = otroUsuarioActivo();
		ResidentialLoanApplication anterior = new ResidentialLoanApplication(FSC_EtapaFormalizacion__c = FSC_FormalizacionGarantiasService.ETAPA_REVISION);

		Assert.isTrue(requiere(FSC_FormalizacionGarantiasService.ETAPA_DEVUELTA_OFICIAL, anterior), 'Devolución al oficial.');
		Assert.isTrue(requiere(FSC_FormalizacionGarantiasService.ETAPA_SOLICITUD_CHEQUE, anterior), 'Pase a un área.');
		Assert.isFalse(requiere(FSC_FormalizacionGarantiasService.ETAPA_FIRMAS, anterior), 'Avance interno de Formalización.');
		Assert.isFalse(requiere(FSC_FormalizacionGarantiasService.ETAPA_EN_DESEMBOLSO, anterior), 'Desembolso sigue su propio flujo.');
		Assert.isFalse(requiere(null, anterior), 'Sin proceso por etapas.');
		Assert.isTrue(
			requiere(FSC_FormalizacionGarantiasService.ETAPA_REVISION, new ResidentialLoanApplication()),
			'Entrada a Formalización.'
		);
		Assert.isTrue(
			requiere(
				FSC_FormalizacionGarantiasService.ETAPA_DEPOSITO_TITULOS,
				new ResidentialLoanApplication(FSC_EtapaFormalizacion__c = FSC_FormalizacionGarantiasService.ETAPA_EN_DESEMBOLSO)
			),
			'Regreso del desembolso.'
		);

		ResidentialLoanApplication reasignada = new ResidentialLoanApplication(
			FSC_EtapaFormalizacion__c = FSC_FormalizacionGarantiasService.ETAPA_REVISION,
			FSC_UsuarioFormalizacion__c = otro
		);
		Assert.isTrue(FSC_FormalizacionNotificaciones.requiereAviso(reasignada, anterior), 'Reasignación en Formalización.');
		ResidentialLoanApplication areaReasignada = new ResidentialLoanApplication(
			FSC_EtapaFormalizacion__c = FSC_FormalizacionGarantiasService.ETAPA_CDD,
			FSC_ResponsableAreaFormalizacion__c = otro
		);
		Assert.isTrue(
			FSC_FormalizacionNotificaciones.requiereAviso(
				areaReasignada,
				new ResidentialLoanApplication(FSC_EtapaFormalizacion__c = FSC_FormalizacionGarantiasService.ETAPA_CDD)
			),
			'Reasignación en un área.'
		);
		Assert.isFalse(FSC_FormalizacionNotificaciones.requiereAviso(anterior, anterior), 'Sin cambios.');
	}

	@IsTest
	static void avisaAlOficialCuandoSeLeDevuelve() {
		Id solicitudId = enEtapa(FSC_FormalizacionGarantiasService.ETAPA_DEVUELTA_OFICIAL, null);
		update new ResidentialLoanApplication(Id = solicitudId, FSC_ObservacionFormalizacion__c = '[Revisión de documentos] Falta poder notarial');

		Test.startTest();
		ejecutar(solicitudId, FSC_FormalizacionGarantiasService.ETAPA_REVISION, otroUsuarioActivo());
		Test.stopTest();

		Assert.areEqual(1, FSC_FormalizacionNotificaciones.enviadosEnPrueba.size());
		FSC_FormalizacionNotificaciones.Aviso aviso = FSC_FormalizacionNotificaciones.enviadosEnPrueba[0];
		Assert.isTrue(aviso.destinatarios.contains(UserInfo.getUserId()), 'El dueño (oficial) recibe el aviso.');
		Assert.isTrue(aviso.textoCorto().contains('Falta poder notarial'), 'Incluye el motivo de la devolución.');
		Assert.isTrue(aviso.cuerpoHtml('https://test').contains(solicitudId), 'El correo enlaza la solicitud.');
		Assert.isTrue(aviso.asunto().contains(FSC_FormalizacionGarantiasService.ETAPA_DEVUELTA_OFICIAL));
	}

	@IsTest
	static void avisaAlResponsableDelArea() {
		Id solicitudId = enEtapa(FSC_FormalizacionGarantiasService.ETAPA_MANTENIMIENTO, UserInfo.getUserId());

		Test.startTest();
		ejecutar(solicitudId, FSC_FormalizacionGarantiasService.ETAPA_EN_RETIRO, otroUsuarioActivo());
		Test.stopTest();

		Assert.areEqual(1, FSC_FormalizacionNotificaciones.enviadosEnPrueba.size());
		Assert.areEqual(new Set<Id>{ UserInfo.getUserId() }, FSC_FormalizacionNotificaciones.enviadosEnPrueba[0].destinatarios);
		Assert.isTrue(FSC_FormalizacionNotificaciones.enviadosEnPrueba[0].pendiente().contains('fecha de formalización'));
	}

	@IsTest
	static void noSeAvisaAQuienHizoLaAccion() {
		Id solicitudId = enEtapa(FSC_FormalizacionGarantiasService.ETAPA_COMPLETADA, null);

		Test.startTest();
		ejecutar(solicitudId, FSC_FormalizacionGarantiasService.ETAPA_CDD, UserInfo.getUserId());
		Test.stopTest();

		Assert.isTrue(FSC_FormalizacionNotificaciones.enviadosEnPrueba.isEmpty(), 'El oficial que completó no se avisa a sí mismo.');
	}

	@IsTest
	static void sinResponsableAvisaALaCola() {
		Id solicitudId = enEtapa(FSC_FormalizacionGarantiasService.ETAPA_CDD, null);
		Group cola = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'FSC_ColaCDD' LIMIT 1];
		System.runAs(new User(Id = UserInfo.getUserId())) {
			if ([SELECT COUNT() FROM GroupMember WHERE GroupId = :cola.Id AND UserOrGroupId = :UserInfo.getUserId()] == 0) {
				insert new GroupMember(GroupId = cola.Id, UserOrGroupId = UserInfo.getUserId());
			}
		}

		Test.startTest();
		ejecutar(solicitudId, FSC_FormalizacionGarantiasService.ETAPA_CUSTODIA, otroUsuarioActivo());
		Test.stopTest();

		Assert.areEqual(1, FSC_FormalizacionNotificaciones.enviadosEnPrueba.size());
		Assert.isTrue(FSC_FormalizacionNotificaciones.enviadosEnPrueba[0].destinatarios.contains(UserInfo.getUserId()), 'Miembros de la cola del área.');
	}

	@IsTest
	static void elTriggerProgramaElAvisoUnaVezPorTransaccion() {
		Id solicitudId = enEtapa(FSC_FormalizacionGarantiasService.ETAPA_REVISION, null);
		FSC_FormalizacionNotificaciones.programadas.clear();

		Test.startTest();
		update new ResidentialLoanApplication(Id = solicitudId, FSC_EtapaFormalizacion__c = FSC_FormalizacionGarantiasService.ETAPA_DEVUELTA_OFICIAL);
		update new ResidentialLoanApplication(Id = solicitudId, FSC_EtapaFormalizacion__c = FSC_FormalizacionGarantiasService.ETAPA_REVISION);
		Test.stopTest();

		Assert.isTrue(FSC_FormalizacionNotificaciones.programadas.contains(solicitudId), 'El cambio de etapa programa el aviso.');
		Assert.areEqual(1, FSC_FormalizacionNotificaciones.programadas.size(), 'Un solo aviso por solicitud en la transacción.');
	}

	@IsTest
	static void erroresNoInterrumpenLaTransaccion() {
		Test.startTest();
		FSC_FormalizacionNotificaciones.programar(null, null);
		new FSC_FormalizacionNotificaciones(null, null, null).execute(null);
		Test.stopTest();

		Assert.isTrue(FSC_FormalizacionNotificaciones.enviadosEnPrueba.isEmpty());
	}

	// ===== Utilidades =====

	private static Boolean requiere(String etapa, ResidentialLoanApplication anterior) {
		return FSC_FormalizacionNotificaciones.requiereAviso(new ResidentialLoanApplication(FSC_EtapaFormalizacion__c = etapa), anterior);
	}

	private static Id enEtapa(String etapa, Id responsableArea) {
		Id solicitudId = [SELECT Id FROM ResidentialLoanApplication WHERE Name = :SOLICITUD LIMIT 1].Id;
		// La preparación no debe generar avisos propios.
		FSC_FormalizacionNotificaciones.programadas.add(solicitudId);
		update new ResidentialLoanApplication(Id = solicitudId, FSC_Subestado__c = 'Formalización');
		update new ResidentialLoanApplication(Id = solicitudId, FSC_EtapaFormalizacion__c = etapa, FSC_ResponsableAreaFormalizacion__c = responsableArea);
		FSC_FormalizacionNotificaciones.programadas.clear();
		return solicitudId;
	}

	private static void ejecutar(Id solicitudId, String etapaAnterior, Id actorId) {
		new FSC_FormalizacionNotificaciones(new List<Id>{ solicitudId }, new Map<Id, String>{ solicitudId => etapaAnterior }, actorId).execute(null);
	}

	private static Id otroUsuarioActivo() {
		return [SELECT Id FROM User WHERE IsActive = TRUE AND UserType = 'Standard' AND Id != :UserInfo.getUserId() LIMIT 1].Id;
	}
}