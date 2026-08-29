public without sharing class FSC_RlaAccionesController {
	@TestVisible
	private static Boolean testForcePrivilegedSupervisorReview = false;
	private static final String SUBESTADO_RECEPCION_ANALISIS = 'Recepción de documentos – Análisis';
	private static final String SUBESTADO_DOCS_DESEMBOLSO = 'Documentación para desembolso y firmas';
	private static final String CAT_ANALISIS = 'Documentos para análisis';
	private static final String CAT_CONTRATO = 'Documentos para confección de contrato';
	private static final String CAT_DESEMBOLSO = 'Documentos para desembolso';
	private static final String ESTADO_PENDIENTE = 'Pendiente';
	private static final String ESTADO_APROBADO = 'Aprobado';
	private static final String ESTADO_OBSERVADO = 'Observado';
	private static final String SUBESTADO_RECEPCION_ANALISIS_NORM = 'recepcion de documentos analisis';
	private static final String SUBESTADO_ANALISIS_CREDITO_NORM = 'analisis de credito';
	private static final String SUBESTADO_DOCS_DESEMBOLSO_NORM = 'documentacion para desembolso y firmas';
	private static final String CAT_ANALISIS_NORM = 'documentos para analisis';
	private static final String CAT_CONTRATO_NORM = 'documentos para confeccion de contrato';
	private static final String CAT_DESEMBOLSO_NORM = 'documentos para desembolso';
	private static final String MSG_PAGARES_SIN_AUTORIZACION = 'Usted no tiene autorización para realizar esta acción, solo la persona asignada o un administrador tienen permiso.';
	private static final String SUBESTADO_CREACION_CREDITO = 'Creación de crédito';
	private static final String FORMA_DESEMBOLSO_CUENTA_AHORRO = 'Cuenta de ahorro';
	private static final String RT_SOLICITUD_CREDITO_PYME = 'FSC_Solicitud_Credito_PYME';
	private static final String IP_VALIDAR_CLASIFICACION_MIPYMES = 'FSC_ValidarClasificacionMIPYMES';
	private static final String RESPUESTA_CLASIFICACION_MIPYMES_VALIDA = 'ClasificacionMIPYMESValida';
	private static final String PROCESO_ANALISTA = 'FSC_AnalistasDeCredito';
	@TestVisible
	private static Boolean testClasificacionMIPYMESValida;

	@AuraEnabled
	public static Boolean validarClasificacionMIPYMES(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		ResidentialLoanApplication rla = [
			SELECT RecordType.DeveloperName, FSC_Cantidad_de_empleados__c, FSC_VentasBrutasAnuales__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			WITH USER_MODE
			LIMIT 1
		];

		if (rla.RecordType == null || rla.RecordType.DeveloperName != RT_SOLICITUD_CREDITO_PYME) {
			return true;
		}

		if (Test.isRunningTest() && testClasificacionMIPYMESValida != null) {
			return testClasificacionMIPYMESValida;
		}

		Map<String, Object> inputMap = new Map<String, Object>{
			'CantidadEmpleados' => rla.FSC_Cantidad_de_empleados__c,
			'VentasBrutasAnuales' => rla.FSC_VentasBrutasAnuales__c
		};

		try {
			Object rawResponse = omnistudio.IntegrationProcedureService.runIntegrationService(
				IP_VALIDAR_CLASIFICACION_MIPYMES,
				inputMap,
				new Map<String, Object>()
			);
			if (!(rawResponse instanceof Map<String, Object>)) {
				throw new AuraHandledException('La validación MIPYMES no devolvió una respuesta válida.');
			}

			Map<String, Object> response = (Map<String, Object>) rawResponse;
			Object clasificacionValida = response.get(RESPUESTA_CLASIFICACION_MIPYMES_VALIDA);
			if (clasificacionValida == null) {
				throw new AuraHandledException('La validación MIPYMES no devolvió un resultado.');
			}

			return Boolean.valueOf(String.valueOf(clasificacionValida));
		} catch (Exception exceptionInstance) {
			throw new AuraHandledException('No se pudo validar la clasificación MIPYMES de la solicitud.');
		}
	}

	@AuraEnabled(cacheable=true)
	public static Map<String, Object> getApprovalContext(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Id requerido');
		}

		Map<String, Object> result = new Map<String, Object>{
			'hasActiveApproval' => false,
			'workItemCount' => 0,
			'currentApproverName' => '',
			'currentApproverId' => null,
			'currentApproverType' => '',
			'isCurrentUserQueueMember' => false,
			'currentProcessDefinitionDeveloperName' => ''
		};

		List<ProcessInstanceWorkitem> workItems = [
			SELECT Id, ActorId, Actor.Name, Actor.Type, ProcessInstanceId
			FROM ProcessInstanceWorkitem
			WHERE ProcessInstance.TargetObjectId = :residentialLoanApplicationId
			ORDER BY CreatedDate DESC
		];

		result.put('hasActiveApproval', !workItems.isEmpty());
		result.put('workItemCount', workItems.size());

		if (!workItems.isEmpty() && workItems[0].ActorId != null) {
			Id actorId = workItems[0].ActorId;
			String actorName = workItems[0].Actor != null ? workItems[0].Actor.Name : '';
			String actorType = workItems[0].Actor != null ? String.valueOf(workItems[0].Actor.Type) : '';
			String currentProcessDefinitionDeveloperName = getProcessDefinitionDeveloperName(workItems[0].ProcessInstanceId);

			result.put('currentApproverName', actorName);
			result.put('currentApproverId', actorId);
			result.put('currentApproverType', actorType);
			result.put('currentProcessDefinitionDeveloperName', currentProcessDefinitionDeveloperName);

			if (String.valueOf(actorId).startsWith('00G')) {
				result.put('isCurrentUserQueueMember', isUserMemberOfGroupRecursive(actorId, UserInfo.getUserId()));
			}
		}

		return result;
	}

	@AuraEnabled(cacheable=true)
	public static List<Map<String, String>> getAssignableUsers() {
		List<Map<String, String>> options = new List<Map<String, String>>();

		for (User u : [
			SELECT Id, Name
			FROM User
			WHERE IsActive = TRUE
			ORDER BY Name
		]) {
			options.add(new Map<String, String>{ 'label' => u.Name, 'value' => u.Id });
		}

		return options;
	}

	@AuraEnabled(cacheable=true)
	public static Map<String, Object> getPagaresContext(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		User currentUser = [
			SELECT Id, Profile.Name
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];

		ResidentialLoanApplication rla = [
			SELECT Id, FSC_UsuarioPagaresYContratos__c, FSC_UsuarioPagaresYContratos__r.Name
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		Boolean isAdmin = isGestionPlanillaAdminProfile(currentUser.Profile.Name);
		Boolean isAssignedUser = rla.FSC_UsuarioPagaresYContratos__c == currentUser.Id;

		return new Map<String, Object>{
			'assignedUserId' => rla.FSC_UsuarioPagaresYContratos__c,
			'assignedUserName' => rla.FSC_UsuarioPagaresYContratos__r != null ? rla.FSC_UsuarioPagaresYContratos__r.Name : '',
			'canGeneratePagare' => isAdmin || isAssignedUser
		};
	}

	@AuraEnabled(cacheable=true)
	public static List<Map<String, String>> getFormaDesembolsoOptions() {
		List<Map<String, String>> options = new List<Map<String, String>>();
		Schema.DescribeFieldResult fieldDescribe = ResidentialLoanApplication.FSC_FormaDeDesembolso__c.getDescribe();

		for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
			if (entry.isActive()) {
				options.add(new Map<String, String>{ 'label' => entry.getLabel(), 'value' => entry.getValue() });
			}
		}

		return options;
	}

	@AuraEnabled(cacheable=true)
	public static List<Map<String, String>> getCuentasDesembolsoOptions(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, AccountId
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		List<Map<String, String>> options = new List<Map<String, String>>();
		if (rla.AccountId == null) {
			return options;
		}

		for (FinServ__FinancialAccount__c financialAccount : [
			SELECT Id, Name, FinServ__FinancialAccountNumber__c
			FROM FinServ__FinancialAccount__c
			WHERE
				FinServ__PrimaryOwner__c = :rla.AccountId
				AND (RecordType.DeveloperName = 'CheckingAccount'
				OR RecordType.DeveloperName = 'SavingsAccount')
			ORDER BY Name
		]) {
			options.add(
				new Map<String, String>{ 'label' => buildCuentaDesembolsoLabel(financialAccount), 'value' => String.valueOf(financialAccount.Id) }
			);
		}

		return options;
	}

	@AuraEnabled
	public static void guardarFormaDesembolsoGestionPlanillas(Id residentialLoanApplicationId, String formaDeDesembolso, Id financialAccountId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (String.isBlank(formaDeDesembolso)) {
			throw new AuraHandledException('Forma de desembolso requerida.');
		}

		validateCurrentUserCanCompleteGestionPlanillas(residentialLoanApplicationId);
		validateFormaDeDesembolsoValue(formaDeDesembolso);
		updateFormaDeDesembolso(residentialLoanApplicationId, formaDeDesembolso, financialAccountId);
	}

	@AuraEnabled
	public static void guardarDatosPagare(Id residentialLoanApplicationId, String actoNumeroPagare, String numeroFolioPagare) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (String.isBlank(actoNumeroPagare) || String.isBlank(numeroFolioPagare)) {
			throw new AuraHandledException('Debe completar los campos del pagaré.');
		}

		validateCurrentUserCanCompletePagares(residentialLoanApplicationId);
		Decimal numeroFolioPagareValue;
		try {
			numeroFolioPagareValue = Decimal.valueOf(numeroFolioPagare.trim());
		} catch (Exception ex) {
			throw new AuraHandledException('Número de folio pagaré debe ser numérico.');
		}

		update new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_ActoNumeroPagare__c = actoNumeroPagare.trim(),
			FSC_NumeroFolioPagare__c = numeroFolioPagareValue
		);
	}

	@AuraEnabled
	public static Boolean validateChecklistApprovalReadiness(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		validateChecklistApprovalReadinessInternal(residentialLoanApplicationId);
		return true;
	}

	@AuraEnabled
	public static void validarDocumentacionAnalista(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		validateCurrentUserCanActOnApproval(residentialLoanApplicationId, PROCESO_ANALISTA);
		validateChecklistApprovalReadinessInternal(residentialLoanApplicationId);

		update new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_DocumentacionValidadaAnalista__c = true
		);
	}

	@AuraEnabled
	public static void aprobarProcesoActual(Id residentialLoanApplicationId, String comentario) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (String.isBlank(comentario)) {
			throw new AuraHandledException('Comentario requerido.');
		}
		if (comentario.length() > 255) {
			throw new AuraHandledException('Comentario máximo 255 caracteres.');
		}

		if (hasActiveApprovalForProcess(residentialLoanApplicationId, PROCESO_ANALISTA)) {
			validateAnalystDecisionReadiness(residentialLoanApplicationId);
		} else {
			validateChecklistApprovalReadinessInternal(residentialLoanApplicationId);
		}

		List<ProcessInstanceWorkitem> workItems = getActiveWorkItems(residentialLoanApplicationId);
		if (workItems.isEmpty()) {
			System.debug('No hay proceso de aprobación activo.');
		}

		for (ProcessInstanceWorkitem wi : workItems) {
			Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
			req.setWorkitemId(wi.Id);
			req.setAction('Approve');
			req.setComments(comentario.trim());

			Approval.ProcessResult result = Approval.process(req);

			if (!result.isSuccess()) {
				throw new AuraHandledException('No se pudo aprobar el proceso de aprobación actual.');
			}
		}

		ResidentialLoanApplication rla = [
			SELECT Id, FSC_Subestado__c, FSC_DebeRevisarComite__c, FSC_SolicitudAprobadaPorComite__c, FSC_FechaYHoraAprobacionComite__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (rla.FSC_Subestado__c == 'Análisis de crédito' && rla.FSC_DebeRevisarComite__c) {
			rla.FSC_SolicitudAprobadaPorComite__c = true;
			rla.FSC_FechaYHoraAprobacionComite__c = System.now();
		}
	}

	@AuraEnabled
	public static void rechazarProcesoActual(Id residentialLoanApplicationId, String motivo, String motivoDeRechazo) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (String.isBlank(motivo)) {
			throw new AuraHandledException('Motivo requerido.');
		}
		if (motivo.length() > 255) {
			throw new AuraHandledException('Motivo máximo 255 caracteres.');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, RecordType.DeveloperName
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];
		String recordTypeDeveloperName = rla.RecordType != null ? rla.RecordType.DeveloperName : null;
		Boolean isPymeRla = recordTypeDeveloperName == RT_SOLICITUD_CREDITO_PYME;

		if (isPymeRla && String.isBlank(motivoDeRechazo)) {
			throw new AuraHandledException('Motivo de rechazo requerido.');
		}

		List<ProcessInstanceWorkitem> workItems = getActiveWorkItems(residentialLoanApplicationId);
		if (workItems.isEmpty()) {
			System.debug('No hay proceso de aprobación activo.');
		}

		String profileName = '';
		try {
			Profile p = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
			profileName = p.Name;
		} catch (Exception e) {
			profileName = '';
		}

		for (ProcessInstanceWorkitem wi : workItems) {
			Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
			req.setWorkitemId(wi.Id);
			req.setAction('Reject');
			req.setComments(motivo);

			Approval.ProcessResult result = Approval.process(req);

			if (!result.isSuccess()) {
				throw new AuraHandledException('No se pudo rechazar el proceso de aprobación actual.');
			}
		}

		ResidentialLoanApplication upd = new ResidentialLoanApplication(Id = residentialLoanApplicationId);
		if (isPymeRla) {
			upd.FSC_MotivosDeRechazo__c = motivoDeRechazo.trim();
		}

		String norm = normalize(profileName);

		if (norm == normalize('Prevención de lavado y activos') || norm == normalize('Prevencion de lavado y activos')) {
			upd.FSC_ObservacionPLA__c = motivo;
		} else if (norm == normalize('Recepción y control de documentos') || norm == normalize('Recepcion y control de documentos')) {
			upd.FSC_ObservacionRecepcionYControlDeDocs__c = motivo;
		} else if (norm == normalize('Analista de crédito') || norm == normalize('Analista de credito')) {
			upd.FSC_ObservacionAnalistaDeCredito__c = motivo;
		} else if (norm == normalize('Supervisor')) {
			upd.FSC_ObservacionSupervisor__c = motivo;
		} else if (norm == normalize('Comité de crédito') || norm == normalize('Comite de credito')) {
			upd.FSC_ObservacionesComite__c = motivo;
		} else if (norm == normalize('Archivo y custodia de valores')) {
			upd.FSC_ObservacionArchyCustodiaDeValores__c = motivo;
		} else {
			upd.FSC_ObservacionAdministrador__c = motivo;
		}

		update upd;
	}

	@AuraEnabled
	public static void reasignarProcesoActual(Id residentialLoanApplicationId, Id newActorId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (newActorId == null) {
			throw new AuraHandledException('Debe seleccionar un usuario.');
		}

		List<ProcessInstanceWorkitem> workItems = getActiveWorkItems(residentialLoanApplicationId);
		if (workItems.isEmpty()) {
			System.debug('No hay proceso de aprobación activo.');
		}

		for (ProcessInstanceWorkitem wi : workItems) {
			Boolean success = false;

			try {
				Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
				req.setWorkitemId(wi.Id);
				req.setAction('Reassign');
				req.setComments('Reasignado desde acciones.');
				req.setNextApproverIds(new List<Id>{ newActorId });

				Approval.ProcessResult result = Approval.process(req);
				success = result != null && result.isSuccess();
			} catch (Exception ex) {
				success = false;
			}

			if (!success) {
				try {
					ProcessInstanceWorkitem wiUpd = new ProcessInstanceWorkitem(Id = wi.Id, ActorId = newActorId);
					update wiUpd;
					success = true;
				} catch (Exception ex2) {
					throw new AuraHandledException('No se pudo reasignar el proceso de aprobación actual. ' + ex2.getMessage());
				}
			}
		}
	}

	@AuraEnabled
	public static String reintentarListas(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Id requerido');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, AccountId
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		Map<String, Object> inputMap = new Map<String, Object>{ 'accountId' => rla.AccountId, 'solicitudDeCreditoId' => rla.Id };

		Map<String, Object> options = new Map<String, Object>();

		Object response = omnistudio.IntegrationProcedureService.runIntegrationService('FSC_ValidaListasControl', inputMap, options);

		return response != null ? String.valueOf(response) : 'OK';
	}

	@AuraEnabled
	public static String reintentarBuro(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Id requerido');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, RecordType.DeveloperName
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (rla.RecordType != null && rla.RecordType.DeveloperName == 'FSC_Solicitud_Credito_PYME') {
			Map<String, Object> inputMap = new Map<String, Object>{ 'residentialLoanApplicationId' => residentialLoanApplicationId };

			Object response = omnistudio.IntegrationProcedureService.runIntegrationService(
				'FSC_APIBuroCreditoPyme',
				inputMap,
				new Map<String, Object>()
			);

			return response != null ? String.valueOf(response) : 'OK';
		}

		FSC_LoanDecisionAPI.callAPI(new List<Id>{ residentialLoanApplicationId });
		return 'OK';
	}

	@AuraEnabled
	public static String reintentarCreacionPrestamo(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, FSC_lineaFinanciera__c, FSC_subAplicacion__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		FSC_APIPrestamoProductos.Input productoInput = new FSC_APIPrestamoProductos.Input();
		productoInput.lineaFinanciera = rla.FSC_lineaFinanciera__c;
		productoInput.subAplicacion = rla.FSC_subAplicacion__c;

		List<FSC_APIPrestamoProductos.Output> productoOutputs = FSC_APIPrestamoProductos.run(
			new List<FSC_APIPrestamoProductos.Input>{ productoInput }
		);
		FSC_APIPrestamoProductos.Output productoOutput = productoOutputs == null || productoOutputs.isEmpty() ? null : productoOutputs[0];

		if (productoOutput == null) {
			throw new AuraHandledException('No se pudo consultar el producto del prestamo.');
		}
		if (productoOutput.success != true) {
			throw new AuraHandledException(
				String.isBlank(productoOutput.message) ? 'No se pudo consultar el producto del prestamo.' : productoOutput.message
			);
		}
		if (productoOutput.found != true || String.isBlank(productoOutput.productoJson)) {
			throw new AuraHandledException(
				String.isBlank(productoOutput.message)
					? 'No se encontro producto para la linea financiera y sub aplicacion indicadas.'
					: productoOutput.message
			);
		}

		User currentUser = [
			SELECT FSC_CodigoAbanks__c
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];

		FSC_APIPrestamoPrestamos.Input prestamoInput = new FSC_APIPrestamoPrestamos.Input();
		prestamoInput.residentialLoanApplicationId = residentialLoanApplicationId;
		prestamoInput.productoJson = productoOutput.productoJson;
		prestamoInput.codigoUsuario = currentUser.FSC_CodigoAbanks__c;
		prestamoInput.codigoEjecutivo = 'ABANKS';

		List<FSC_APIPrestamoPrestamos.Output> prestamoOutputs = FSC_APIPrestamoPrestamos.run(
			new List<FSC_APIPrestamoPrestamos.Input>{ prestamoInput }
		);
		FSC_APIPrestamoPrestamos.Output prestamoOutput = prestamoOutputs == null || prestamoOutputs.isEmpty() ? null : prestamoOutputs[0];

		if (prestamoOutput == null) {
			throw new AuraHandledException('No se pudo crear el prestamo en ABANKS.');
		}
		if (prestamoOutput.success != true) {
			throw new AuraHandledException(
				String.isBlank(prestamoOutput.message) ? 'No se pudo crear el prestamo en ABANKS.' : prestamoOutput.message
			);
		}

		return String.isBlank(prestamoOutput.message) ? 'Prestamo creado en ABANKS.' : prestamoOutput.message;
	}

	@AuraEnabled
	public static String reintentarDesembolso(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, FSC_Subestado__c, FSC_FormaDeDesembolso__c, FSC_FlagErrorAPIDesembolso__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (rla.FSC_FlagErrorAPIDesembolso__c != true) {
			throw new AuraHandledException('No hay error de desembolso para reintentar.');
		}
		if (rla.FSC_Subestado__c != SUBESTADO_CREACION_CREDITO) {
			throw new AuraHandledException('La solicitud debe estar en Creación de crédito para reintentar el desembolso.');
		}
		if (rla.FSC_FormaDeDesembolso__c != FORMA_DESEMBOLSO_CUENTA_AHORRO) {
			throw new AuraHandledException('La forma de desembolso debe ser Cuenta de ahorro.');
		}

		User currentUser = [
			SELECT FSC_CodigoAbanks__c
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];

		FSC_APIPrestamoDesembolso.Input desembolsoInput = new FSC_APIPrestamoDesembolso.Input();
		desembolsoInput.residentialLoanApplicationId = residentialLoanApplicationId;
		desembolsoInput.codigoUsuario = currentUser.FSC_CodigoAbanks__c;

		List<FSC_APIPrestamoDesembolso.Output> outputs = FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{ desembolsoInput });
		FSC_APIPrestamoDesembolso.Output output = outputs == null || outputs.isEmpty() ? null : outputs[0];

		if (output == null) {
			throw new AuraHandledException('No se pudo ejecutar el desembolso en ABANKS.');
		}
		if (output.success != true) {
			throw new AuraHandledException(String.isBlank(output.message) ? 'No se pudo ejecutar el desembolso en ABANKS.' : output.message);
		}

		return String.isBlank(output.message) ? 'Desembolso creado en ABANKS.' : output.message;
	}

	@AuraEnabled
	public static void cancelarAprobacion(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Id requerido');
		}

		List<ProcessInstanceWorkitem> workItems = getActiveWorkItems(residentialLoanApplicationId);

		if (workItems.isEmpty()) {
			System.debug('No hay proceso de aprobación activo.');
		}

		for (ProcessInstanceWorkitem wi : workItems) {
			Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
			req.setWorkitemId(wi.Id);
			req.setAction('Removed');
			req.setComments('Proceso cancelado desde sistema.');

			Approval.ProcessResult result = Approval.process(req);

			if (!result.isSuccess()) {
				throw new AuraHandledException('No se pudo cancelar el proceso.');
			}
		}
	}

	@AuraEnabled
	public static void aprobarConCondicion(
		Id residentialLoanApplicationId,
		Decimal montoAprobado,
		Integer plazoMesesAprobado,
		Decimal tasaInteresAprobada,
		String otrasCondicionesComite
	) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (otrasCondicionesComite != null && otrasCondicionesComite.length() > 2000) {
			throw new AuraHandledException('Otras condiciones máximo 2000 caracteres.');
		}

		ResidentialLoanApplication upd = new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_MontoAprobado__c = montoAprobado,
			FSC_PlazoMesesAprobado__c = plazoMesesAprobado,
			FSC_TasaInteresAprobada__c = tasaInteresAprobada,
			FSC_OtrasCondicionesComite__c = otrasCondicionesComite,
			FSC_Aprobado_con_Condiciones__c = true
		);

		update upd;
	}

	@AuraEnabled
	public static void devolverAOficial(Id residentialLoanApplicationId, String motivo) {
		if (residentialLoanApplicationId == null)
			throw new AuraHandledException('Solicitud requerida.');
		if (String.isBlank(motivo))
			throw new AuraHandledException('Motivo requerido.');
		if (motivo.length() > 255)
			throw new AuraHandledException('Motivo excede 255 caracteres.');

		validateCurrentUserCanActOnApproval(residentialLoanApplicationId, null);

		String profileName = '';
		try {
			Profile p = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
			profileName = p.Name;
		} catch (Exception e) {
			profileName = '';
		}

		if (shouldUsePrivilegedSupervisorFallback(residentialLoanApplicationId)) {
			FSC_RlaApprovalAdminClient.returnToBusiness(residentialLoanApplicationId, motivo, profileName);
			return;
		}

		FSC_RlaApprovalAdminService.returnToBusiness(residentialLoanApplicationId, motivo, profileName);
	}

	@AuraEnabled
	public static void devolverAAnalista(Id residentialLoanApplicationId, String motivo) {
		if (residentialLoanApplicationId == null)
			throw new AuraHandledException('Solicitud requerida.');
		if (String.isBlank(motivo))
			throw new AuraHandledException('Motivo requerido.');
		if (motivo.length() > 255)
			throw new AuraHandledException('Motivo excede 255 caracteres.');

		if (shouldUsePrivilegedSupervisorFallback(residentialLoanApplicationId)) {
			FSC_RlaApprovalAdminClient.returnToAnalyst(residentialLoanApplicationId, motivo);
			return;
		}

		FSC_RlaApprovalAdminService.returnToAnalyst(residentialLoanApplicationId, motivo);
	}

	@AuraEnabled
	public static void enviarRevisionSupervisor(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		validateAnalystDecisionReadiness(residentialLoanApplicationId);

		if (shouldUsePrivilegedSupervisorFallback(residentialLoanApplicationId)) {
			FSC_RlaApprovalAdminClient.sendToSupervisor(residentialLoanApplicationId);
			return;
		}

		FSC_RlaApprovalAdminService.sendToSupervisor(residentialLoanApplicationId);
	}

	@TestVisible
	private static Boolean shouldUsePrivilegedSupervisorFallback(Id residentialLoanApplicationId) {
		if (testForcePrivilegedSupervisorReview) {
			return true;
		}

		User currentUser = [
			SELECT Id, Profile.PermissionsModifyAllData
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];

		if (currentUser.Profile.PermissionsModifyAllData) {
			return false;
		}

		List<ProcessInstance> activeProcesses = [
			SELECT Id, SubmittedById
			FROM ProcessInstance
			WHERE TargetObjectId = :residentialLoanApplicationId AND Status = 'Pending'
			ORDER BY CreatedDate DESC
			LIMIT 1
		];

		if (activeProcesses.isEmpty()) {
			return false;
		}

		return activeProcesses[0].SubmittedById != currentUser.Id;
	}

	@AuraEnabled
	public static void marcarFirmaCompletaYPasarADocDesembolso(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		ResidentialLoanApplication upd = new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_Firma_completada__c = true,
			FSC_Subestado__c = 'Documentación para desembolso y firmas'
		);

		update upd;
	}

	@AuraEnabled
	public static void marcarEnviadoAFirmar(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		update new ResidentialLoanApplication(Id = residentialLoanApplicationId, FSC_EnviadoAFirmar__c = true);
	}

	@AuraEnabled
	public static void marcarDocumentosFirmadosFisicamente(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		update new ResidentialLoanApplication(Id = residentialLoanApplicationId, FSC_DocumentosFirmadosFis__c = true);
		ResidentialLoanApplication rla = [
			SELECT Id, RecordType.DeveloperName
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];
		String recordTypeDeveloperName = rla.RecordType == null ? null : rla.RecordType.DeveloperName;
		if (!FSC_ConfiguracionFirmaDocumentosService.hasDocumentosFirmaDigital(recordTypeDeveloperName)) {
			update new ResidentialLoanApplication(
				Id = residentialLoanApplicationId,
				FSC_Firma_completada__c = true,
				FSC_Subestado__c = 'Documentación para desembolso y firmas'
			);
			return;
		}

		FSC_ContentVersionTriggerHandler.actualizarSiFirmasCompletas(new Set<Id>{ residentialLoanApplicationId });
	}

	@AuraEnabled(cacheable=false)
	public static FirmaValidationState getFirmaValidationState(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		FirmaValidationState state = new FirmaValidationState();

		Boolean hasPhysicalField = ResidentialLoanApplication.SObjectType.getDescribe().fields.getMap().containsKey('FSC_DocumentosFirmadosFis__c');
		String soql = 'SELECT Id, RecordType.DeveloperName';
		if (hasPhysicalField) {
			soql += ', FSC_DocumentosFirmadosFis__c';
		}
		soql += ' FROM ResidentialLoanApplication WHERE Id = :residentialLoanApplicationId LIMIT 1';

		ResidentialLoanApplication rla = (ResidentialLoanApplication) Database.query(soql);
		String recordTypeDeveloperName = rla.RecordType == null ? null : rla.RecordType.DeveloperName;
		Boolean digitalRequired = FSC_ConfiguracionFirmaDocumentosService.hasDocumentosFirmaDigital(recordTypeDeveloperName);
		state.digitalComplete = !digitalRequired || tieneFirmasDigitalesCompletas(residentialLoanApplicationId);
		state.physicalRequired = FSC_ConfiguracionFirmaDocumentosService.hasDocumentosFirmaFisica(recordTypeDeveloperName);
		state.physicalConfirmed = hasPhysicalField && Boolean.valueOf(rla.get('FSC_DocumentosFirmadosFis__c'));
		state.shouldAskPhysicalConfirmation = state.digitalComplete && state.physicalRequired && !state.physicalConfirmed;
		return state;
	}

	private static Boolean tieneFirmasDigitalesCompletas(Id residentialLoanApplicationId) {
		Set<Id> latestVersionIds = new Set<Id>();
		for (ContentDocumentLink link : [
			SELECT ContentDocument.LatestPublishedVersionId
			FROM ContentDocumentLink
			WHERE LinkedEntityId = :residentialLoanApplicationId
		]) {
			if (link.ContentDocument.LatestPublishedVersionId != null) {
				latestVersionIds.add(link.ContentDocument.LatestPublishedVersionId);
			}
		}

		if (latestVersionIds.isEmpty()) {
			return false;
		}

		Integer documentosDigitalesEnviados = 0;
		Boolean tieneArchivoFirmadoDescargado = false;

		for (ContentVersion document : [
			SELECT Id, Title, FSC_EnviarDocumento__c, FSC_FechaEnvioFirma__c, FSC_Firmado__c
			FROM ContentVersion
			WHERE Id IN :latestVersionIds
		]) {
			if (isDocumentoDigitalEnviado(document)) {
				documentosDigitalesEnviados++;
				if (document.FSC_Firmado__c != true) {
					return false;
				}
			}

			if (isArchivoFirmadoDescargado(document)) {
				tieneArchivoFirmadoDescargado = true;
			}
		}

		if (documentosDigitalesEnviados > 0) {
			return true;
		}

		return tieneArchivoFirmadoDescargado;
	}

	private static Boolean isDocumentoDigitalEnviado(ContentVersion version) {
		return version != null && version.FSC_EnviarDocumento__c == true && version.FSC_FechaEnvioFirma__c != null;
	}

	private static Boolean isArchivoFirmadoDescargado(ContentVersion version) {
		if (version == null || version.FSC_Firmado__c != true || String.isBlank(version.Title)) {
			return false;
		}

		return version.Title.trim().toLowerCase().endsWith('_firmado');
	}

	public class FirmaValidationState {
		@AuraEnabled
		public Boolean digitalComplete;
		@AuraEnabled
		public Boolean physicalRequired;
		@AuraEnabled
		public Boolean physicalConfirmed;
		@AuraEnabled
		public Boolean shouldAskPhysicalConfirmation;
	}

	@AuraEnabled
	public static void marcarDocCompletaDesembolso(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		validateChecklistUploadCompletenessInternal(residentialLoanApplicationId);

		ResidentialLoanApplication upd = new ResidentialLoanApplication(Id = residentialLoanApplicationId, FSC_Doc_Completa_Desembolso__c = true);

		update upd;
	}

	@AuraEnabled
	public static void marcarCreadoEnAbanks(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		update new ResidentialLoanApplication(Id = residentialLoanApplicationId, FSC_Subestado__c = 'Desembolso');
	}

	@AuraEnabled
	public static void marcarDesembolsado(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		update new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_Subestado__c = 'Archivo y custodia',
			FSC_Desembolso_Realizado__c = true
		);
	}

	private static void updateFormaDeDesembolso(Id residentialLoanApplicationId, String formaDeDesembolso, Id financialAccountId) {
		ResidentialLoanApplication upd = new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_FormaDeDesembolso__c = formaDeDesembolso
		);

		if (formaDeDesembolso == FORMA_DESEMBOLSO_CUENTA_AHORRO) {
			FinServ__FinancialAccount__c cuentaDesembolso = getValidCuentaDesembolso(residentialLoanApplicationId, financialAccountId);
			upd.FSC_NumeroCuentaDesembolso__c = cuentaDesembolso.FinServ__FinancialAccountNumber__c;
		} else {
			upd.FSC_NumeroCuentaDesembolso__c = null;
		}

		update upd;
	}

	@AuraEnabled
	public static void enviarAArchivoYCustodia(Id residentialLoanApplicationId, String motivo) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}
		if (String.isBlank(motivo)) {
			throw new AuraHandledException('Motivo requerido.');
		}
		if (motivo.length() > 2000) {
			throw new AuraHandledException('Motivo máximo 2000 caracteres.');
		}

		ResidentialLoanApplication upd = new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_Doc_Incompleta_Post_Desembolso__c = false,
			FSC_ObservacionesParaArchivo__c = motivo.trim()
		);

		update upd;
	}

	@AuraEnabled
	public static void solicitarExcepcionBuro(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		ResidentialLoanApplication upd = new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_SolicitaExcepcionParaRechazoDeBuro__c = true
		);

		update upd;
	}

	@AuraEnabled
	public static void marcarDocCompletaAnalisis(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		validateChecklistUploadCompletenessInternal(residentialLoanApplicationId);

		ResidentialLoanApplication upd = new ResidentialLoanApplication(Id = residentialLoanApplicationId, FSC_Doc_Completa_Analisis__c = true);

		update upd;
	}

	@AuraEnabled
	public static Id consultarEstadoFirma() {
		return Database.executeBatch(new FSC_ConsultarEstadoEnvelopeBatch(), FSC_ConsultarEstadoEnvelopeBatch.batchSize);
	}

	@AuraEnabled
	public static void actualizarSubestadoGeneracionPagares(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		cancelarAprobacion(residentialLoanApplicationId);

		ResidentialLoanApplication upd = new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			FSC_Subestado__c = 'Generación de pagarés y plantillas',
			FSC_SolicitudAprobadaPorComite__c = true,
			FSC_FechaYHoraAprobacionComite__c = System.now()
		);

		update upd;
	}

	@AuraEnabled
	public static void generarPagare(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		validateCurrentUserCanCompletePagares(residentialLoanApplicationId);

		FSC_GenerarPagarePDF_Action.Input inputItem = new FSC_GenerarPagarePDF_Action.Input();
		inputItem.residentialLoanApplicationId = residentialLoanApplicationId;

		List<FSC_GenerarPagarePDF_Action.Output> outputs = FSC_GenerarPagarePDF_Action.run(new List<FSC_GenerarPagarePDF_Action.Input>{ inputItem });

		FSC_GenerarPagarePDF_Action.Output outputItem = (outputs == null || outputs.isEmpty()) ? null : outputs[0];

		if (outputItem == null || outputItem.status != 'OK') {
			String message = (outputItem == null || String.isBlank(outputItem.message)) ? 'No se pudo generar el pagare.' : outputItem.message;
			throw new AuraHandledException(message);
		}
	}

	@AuraEnabled
	public static void rechazarPorCliente(Id residentialLoanApplicationId) {
		if (residentialLoanApplicationId == null) {
			throw new AuraHandledException('Solicitud requerida.');
		}

		cancelarAprobacion(residentialLoanApplicationId);

		ResidentialLoanApplication upd = new ResidentialLoanApplication(
			Id = residentialLoanApplicationId,
			Status = 'Cerrada Perdida',
			FSC_Subestado__c = 'Rechazada por cliente'
		);

		update upd;
	}

	private static void validateChecklistApprovalReadinessInternal(Id residentialLoanApplicationId) {
		ResidentialLoanApplication rla = [
			SELECT Id, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		Set<String> relevantCategories = getRelevantChecklistCategories(rla.FSC_Subestado__c);
		if (relevantCategories.isEmpty()) {
			return;
		}

		List<FSC_ChecklistDocsController.RowDTO> rows = FSC_ChecklistDocsController.initAndGetRows(residentialLoanApplicationId);

		List<FSC_ChecklistDocsController.RowDTO> relevantRows = new List<FSC_ChecklistDocsController.RowDTO>();
		for (FSC_ChecklistDocsController.RowDTO row : rows) {
			if (row != null && relevantCategories.contains(normalize(row.categoria))) {
				relevantRows.add(row);
			}
		}

		if (relevantRows.isEmpty()) {
			throw new AuraHandledException('Debe revisar todos los documentos de la categoría correspondiente antes de aprobar.');
		}

		for (FSC_ChecklistDocsController.RowDTO row : relevantRows) {
			if (String.isBlank(row.estadoRevision) || (row.estadoRevision != ESTADO_APROBADO && row.estadoRevision != ESTADO_OBSERVADO)) {
				throw new AuraHandledException(
					'Debe completar el estado de revisión de todos los documentos de la categoría correspondiente antes de aprobar.'
				);
			}

			if (row.estadoRevision == ESTADO_OBSERVADO && String.isBlank(row.comentario)) {
				throw new AuraHandledException('Si un documento queda con estado "Observado", debe ingresar un comentario antes de aprobar.');
			}
		}
	}

	private static void validateChecklistUploadCompletenessInternal(Id residentialLoanApplicationId) {
		ResidentialLoanApplication rla = [
			SELECT Id, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		Set<String> relevantCategories = getRelevantChecklistCategories(rla.FSC_Subestado__c);
		if (relevantCategories.isEmpty()) {
			return;
		}

		List<FSC_ChecklistDocsController.RowDTO> rows = FSC_ChecklistDocsController.initAndGetRows(residentialLoanApplicationId);

		List<FSC_ChecklistDocsController.RowDTO> relevantRows = new List<FSC_ChecklistDocsController.RowDTO>();
		for (FSC_ChecklistDocsController.RowDTO row : rows) {
			if (row != null && relevantCategories.contains(normalize(row.categoria))) {
				relevantRows.add(row);
			}
		}

		if (relevantRows.isEmpty()) {
			throw new AuraHandledException(
				'Debe cargar o marcar como "No aplica" todos los documentos de la categoria correspondiente antes de enviar a revision.'
			);
		}

		for (FSC_ChecklistDocsController.RowDTO row : relevantRows) {
			Boolean hasFile = row.files != null && !row.files.isEmpty();
			if (row.noAplica != true && !hasFile) {
				throw new AuraHandledException(
					'Debe cargar o marcar como "No aplica" todos los documentos de la categoria correspondiente antes de enviar a revision.'
				);
			}
		}
	}

	private static Set<String> getRelevantChecklistCategories(String subestado) {
		Set<String> categories = new Set<String>();

		String normalizedSubestado = normalize(subestado).replace('–', ' ').replace('-', ' ').replaceAll('\\s+', ' ').trim();

		if (
			normalizedSubestado == SUBESTADO_RECEPCION_ANALISIS_NORM ||
			normalizedSubestado == SUBESTADO_ANALISIS_CREDITO_NORM
		) {
			categories.add(CAT_ANALISIS_NORM);
		} else if (normalizedSubestado == SUBESTADO_DOCS_DESEMBOLSO_NORM) {
			categories.add(CAT_CONTRATO_NORM);
			categories.add(CAT_DESEMBOLSO_NORM);
		}

		return categories;
	}

	private static List<ProcessInstanceWorkitem> getActiveWorkItems(Id residentialLoanApplicationId) {
		return [
			SELECT Id, ActorId, OriginalActorId, ProcessInstanceId
			FROM ProcessInstanceWorkitem
			WHERE ProcessInstance.TargetObjectId = :residentialLoanApplicationId
			ORDER BY CreatedDate DESC
		];
	}

	private static void validateAnalystDecisionReadiness(Id residentialLoanApplicationId) {
		validateCurrentUserCanActOnApproval(residentialLoanApplicationId, PROCESO_ANALISTA);

		ResidentialLoanApplication rla = [
			SELECT FSC_DocumentacionValidadaAnalista__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (!rla.FSC_DocumentacionValidadaAnalista__c) {
			throw new AuraHandledException(
				'Debe validar la documentación en pestaña Checklist de Documentos antes de continuar.'
			);
		}

		validateChecklistApprovalReadinessInternal(residentialLoanApplicationId);
	}

	private static Boolean hasActiveApprovalForProcess(Id residentialLoanApplicationId, String processDeveloperName) {
		return getActiveWorkItemForProcess(residentialLoanApplicationId, processDeveloperName) != null;
	}

	private static void validateCurrentUserCanActOnApproval(
		Id residentialLoanApplicationId,
		String expectedProcessDeveloperName
	) {
		ProcessInstanceWorkitem workItem = getActiveWorkItemForProcess(
			residentialLoanApplicationId,
			expectedProcessDeveloperName
		);

		if (workItem == null) {
			throw new AuraHandledException('No hay un proceso de aprobación activo para esta acción.');
		}

		Id currentUserId = UserInfo.getUserId();
		Boolean canAct =
			isCurrentUserModifyAllData() ||
			workItem.ActorId == currentUserId ||
			(
				workItem.ActorId != null &&
				String.valueOf(workItem.ActorId).startsWith('00G') &&
				isUserMemberOfGroupRecursive(workItem.ActorId, currentUserId)
			);

		if (!canAct) {
			throw new AuraHandledException(
				'Usted no tiene autorización para realizar esta acción, solo la persona asignada o un administrador tienen permiso.'
			);
		}
	}

	private static ProcessInstanceWorkitem getActiveWorkItemForProcess(
		Id residentialLoanApplicationId,
		String expectedProcessDeveloperName
	) {
		for (ProcessInstanceWorkitem workItem : getActiveWorkItems(residentialLoanApplicationId)) {
			if (
				String.isBlank(expectedProcessDeveloperName) ||
				getProcessDefinitionDeveloperName(workItem.ProcessInstanceId) == expectedProcessDeveloperName
			) {
				return workItem;
			}
		}

		return null;
	}

	private static Boolean isCurrentUserModifyAllData() {
		User currentUser = [
			SELECT Profile.PermissionsModifyAllData
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];
		return currentUser.Profile.PermissionsModifyAllData;
	}

	private static void validateCurrentUserCanCompleteGestionPlanillas(Id residentialLoanApplicationId) {
		User currentUser = [
			SELECT Id, Profile.Name
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];

		if (isGestionPlanillaAdminProfile(currentUser.Profile.Name)) {
			return;
		}

		ResidentialLoanApplication rla = [
			SELECT Id, FSC_UsuarioGestionPlanilla__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (rla.FSC_UsuarioGestionPlanilla__c == currentUser.Id) {
			return;
		}

		throw new AuraHandledException(
			'Usted no tiene autorización para realizar esta acción, solo la persona asignada o un administrador tienen permiso.'
		);
	}

	private static void validateCurrentUserCanCompletePagares(Id residentialLoanApplicationId) {
		User currentUser = [
			SELECT Id, Profile.Name
			FROM User
			WHERE Id = :UserInfo.getUserId()
			LIMIT 1
		];

		if (isGestionPlanillaAdminProfile(currentUser.Profile.Name)) {
			return;
		}

		ResidentialLoanApplication rla = [
			SELECT Id, FSC_UsuarioPagaresYContratos__c
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (rla.FSC_UsuarioPagaresYContratos__c == currentUser.Id) {
			return;
		}

		throw new AuraHandledException(MSG_PAGARES_SIN_AUTORIZACION);
	}

	private static Boolean isGestionPlanillaAdminProfile(String profileName) {
		return profileName == 'System Administrator' || profileName == 'Administrador del sistema';
	}

	private static void validateFormaDeDesembolsoValue(String formaDeDesembolso) {
		Set<String> validValues = new Set<String>();
		for (Schema.PicklistEntry entry : ResidentialLoanApplication.FSC_FormaDeDesembolso__c.getDescribe().getPicklistValues()) {
			if (entry.isActive()) {
				validValues.add(entry.getValue());
			}
		}

		if (!validValues.contains(formaDeDesembolso)) {
			throw new AuraHandledException('Forma de desembolso no valida.');
		}
	}

	private static FinServ__FinancialAccount__c getValidCuentaDesembolso(Id residentialLoanApplicationId, Id financialAccountId) {
		if (financialAccountId == null) {
			throw new AuraHandledException('Cuenta de desembolso requerida.');
		}

		ResidentialLoanApplication rla = [
			SELECT Id, AccountId
			FROM ResidentialLoanApplication
			WHERE Id = :residentialLoanApplicationId
			LIMIT 1
		];

		if (rla.AccountId == null) {
			throw new AuraHandledException('La solicitud no tiene cliente asociado.');
		}

		List<FinServ__FinancialAccount__c> cuentas = [
			SELECT Id, Name, FinServ__FinancialAccountNumber__c
			FROM FinServ__FinancialAccount__c
			WHERE
				Id = :financialAccountId
				AND FinServ__PrimaryOwner__c = :rla.AccountId
				AND (RecordType.DeveloperName = 'CheckingAccount'
				OR RecordType.DeveloperName = 'SavingsAccount')
			LIMIT 1
		];

		if (cuentas.isEmpty()) {
			throw new AuraHandledException('Cuenta de desembolso no valida para esta solicitud.');
		}
		if (String.isBlank(cuentas[0].FinServ__FinancialAccountNumber__c)) {
			throw new AuraHandledException('La cuenta de desembolso seleccionada no tiene numero de cuenta.');
		}

		return cuentas[0];
	}

	private static String buildCuentaDesembolsoLabel(FinServ__FinancialAccount__c financialAccount) {
		if (financialAccount == null) {
			return '';
		}

		if (String.isBlank(financialAccount.FinServ__FinancialAccountNumber__c) && !String.isBlank(financialAccount.Name)) {
			return financialAccount.Name;
		}
		if (!String.isBlank(financialAccount.FinServ__FinancialAccountNumber__c) && String.isBlank(financialAccount.Name)) {
			return financialAccount.FinServ__FinancialAccountNumber__c;
		}
		if (String.isBlank(financialAccount.FinServ__FinancialAccountNumber__c) && String.isBlank(financialAccount.Name)) {
			return String.valueOf(financialAccount.Id);
		}

		return financialAccount.Name + ' - ' + financialAccount.FinServ__FinancialAccountNumber__c;
	}

	@TestVisible
	private static String getProcessDefinitionDeveloperName(Id processInstanceId) {
		if (processInstanceId == null) {
			return '';
		}

		List<ProcessInstance> processInstances = [
			SELECT Id, ProcessDefinitionId
			FROM ProcessInstance
			WHERE Id = :processInstanceId
			LIMIT 1
		];

		if (processInstances.isEmpty() || processInstances[0].ProcessDefinitionId == null) {
			return '';
		}

		List<ProcessDefinition> processDefinitions = [
			SELECT Id, DeveloperName
			FROM ProcessDefinition
			WHERE Id = :processInstances[0].ProcessDefinitionId
			LIMIT 1
		];

		return processDefinitions.isEmpty() ? '' : processDefinitions[0].DeveloperName;
	}

	@TestVisible
	private static String normalize(String s) {
		if (s == null)
			return '';
		String out = s.trim().toLowerCase();
		out = out.replace('á', 'a').replace('é', 'e').replace('í', 'i').replace('ó', 'o').replace('ú', 'u');
		out = out.replace('ü', 'u').replace('ñ', 'n');
		out = out.replace('á', 'a').replace('é', 'e').replace('í', 'i').replace('ó', 'o').replace('ú', 'u');
		out = out.replace('ü', 'u').replace('ñ', 'n');
		out = out.replace('á', 'a').replace('é', 'e').replace('í', 'i').replace('ó', 'o').replace('ú', 'u');
		out = out.replace('ü', 'u').replace('ñ', 'n');
		out = out.replace('â€“', ' ').replace('–', ' ').replace('-', ' ');
		out = out.replaceAll('\\s+', ' ').trim();
		return out;
	}

	@TestVisible
	private static Boolean isUserMemberOfGroupRecursive(Id rootGroupId, Id userId) {
		if (rootGroupId == null || userId == null) {
			return false;
		}

		User currentUser = [
			SELECT Id, UserRoleId
			FROM User
			WHERE Id = :userId
			LIMIT 1
		];

		Set<Id> targetIds = new Set<Id>{ userId };
		if (currentUser.UserRoleId != null) {
			targetIds.add(currentUser.UserRoleId);
		}

		Set<Id> visitedGroupIds = new Set<Id>();
		Set<Id> groupsToProcess = new Set<Id>{ rootGroupId };

		while (!groupsToProcess.isEmpty()) {
			Set<Id> currentBatch = new Set<Id>(groupsToProcess);
			groupsToProcess.clear();

			for (GroupMember gm : [
				SELECT GroupId, UserOrGroupId
				FROM GroupMember
				WHERE GroupId IN :currentBatch
			]) {
				if (targetIds.contains(gm.UserOrGroupId)) {
					return true;
				}

				String memberIdStr = String.valueOf(gm.UserOrGroupId);
				if (memberIdStr.startsWith('00G') && !visitedGroupIds.contains(gm.UserOrGroupId)) {
					visitedGroupIds.add(gm.UserOrGroupId);
					groupsToProcess.add(gm.UserOrGroupId);
				}
			}
		}

		return false;
	}
}