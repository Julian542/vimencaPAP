public with sharing class FSC_RegenerarSolicitudCreditoService {
	private static final String STATUS_BORRADOR = 'Borrador';
	private static final String STATUS_EN_PROCESO = 'En proceso';
	private static final String SUBESTADO_COMPLETANDO_INFORMACION = 'Completando información';
	private static final String SUBESTADO_EN_VALIDACION_PEP = 'En validación PEP/Listas';
	private static final String SUBESTADO_EN_MOTOR_BURO = 'En Motor Buró';
	private static final String SUBESTADO_RECEPCION_DOCUMENTOS = 'Recepción de documentos – Análisis';
	private static final String SUBESTADO_ANALISIS_CREDITO = 'Análisis de crédito';
	private static final String RT_CREDITO_PYME = 'FSC_Solicitud_Credito_PYME';
	private static final String TITLE_PATTERN_CREDITO_PYME = 'Crédito PyMe - %';
	private static final String TITLE_PATTERN_CREDITO_PYME_NO_ACCENT = 'Credito PyMe - %';
	private static final String TITLE_PATTERN_CREDITO_CONSUMO = 'Crédito Consumo - %';
	private static final String TITLE_PATTERN_CREDITO_CONSUMO_NO_ACCENT = 'Credito Consumo - %';
	private static final String TITLE_PATTERN_LEGACY_CREDITO_PYME = '(Crédito PyMe - %';
	private static final String TITLE_PATTERN_LEGACY_CREDITO_PYME_NO_ACCENT = '(Credito PyMe - %';

	private static final Map<String, Schema.RecordTypeInfo> RECORD_TYPE_INFOS_BY_DEVELOPER_NAME = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName();

	private static final Id RT_CREDITO_PYME_ID = RECORD_TYPE_INFOS_BY_DEVELOPER_NAME.containsKey(RT_CREDITO_PYME)
		? RECORD_TYPE_INFOS_BY_DEVELOPER_NAME.get(RT_CREDITO_PYME).getRecordTypeId()
		: null;

	private static final Set<String> SUBESTADOS_VALIDOS_EN_PROCESO = new Set<String>{
		SUBESTADO_EN_VALIDACION_PEP,
		SUBESTADO_EN_MOTOR_BURO,
		SUBESTADO_RECEPCION_DOCUMENTOS,
		SUBESTADO_ANALISIS_CREDITO
	};

	private static final Set<String> PYME_TRACKED_FIELDS = new Set<String>{
		'FSC_Nombre_del_negocio__c',
		'FSC_Telefono__c',
		'FSC_Correo_Electronico__c',
		'FSC_Direccion_del_Negocio__c',
		'FSC_Cantidad_de_empleados__c',
		'FSC_A_os_de_operacion__c',
		'FSC_Local_del_negocio__c',
		'FSC_Tiempo_en_el_local_actual__c',
		'FSC_Tiempo_del_negocio__c',
		'FSC_Situacion_Legal__c',
		'FSC_Cargo__c',
		'FSC_Emplea_familiares__c',
		'FSC_Se_encuentra_en_la_misma_residencia__c',
		'FSC_Se_encuentra_en_zona_comercial__c',
		'FSC_Actividad_economica__c',
		'FSC_Ingresos_Mensuales__c',
		'FSC_Origen_de_los_Ingresos__c',
		'FSC_Monto_de_los_Ingresos__c',
		'FSC_Tipo_de_solicitud__c',
		'FSC_TipoSolicitud__c',
		'FSC_TasaInteres__c',
		'FSC_Destino_del_Prestamo__c',
		'FSC_Monto__c',
		'FSC_Plazo_meses__c',
		'FSC_Moneda__c',
		'OtherLoanFeature',
		'FSC_Tipo_de_solicitud_Otro__c',
		'FSC_Clasificacion_de_Riesgo__c',
		'FSC_Grupo_de_Empresa__c',
		'FSC_Descripcion_del_Negocio__c',
		'FSC_Condiciones_de_la_Facilidad__c',
		'FSC_FormaDeDesembolso__c',
		'FSC_Aprobado_con_Condiciones__c',
		'FSC_MontoAprobado__c',
		'FSC_PlazoMesesAprobado__c',
		'FSC_TasaInteresAprobada__c',
		'FSC_Tipo_de_Garantia__c',
		'FSC_Valor_de_la_Garantia__c',
		'FSC_Porcentaje_de_Admisibilidad__c',
		'FSC_Descripcion_de_la_Garantia__c',
		'FSC_Historial_del_cliente__c',
		'FSC_Recomendaciones__c',
		'FSC_Operaciones_Perspectiva__c',
		'FSC_Total_Dias_Buenos__c',
		'FSC_Total_Dias_Regulares__c',
		'FSC_Total_Dias_Malos__c',
		'FSC_Total_Semanal__c',
		'FSC_DiaEstadoSituacion__c',
		'FSC_MesEstadoSituacion__c',
		'FSC_AnoEstadoSituacion__c',
		'FSC_DesdeMesGananciasyPerdidas__c',
		'FSC_DesdeAnoGananciasyPerdidas__c',
		'FSC_HastaMesGananciasyPerdidas__c',
		'FSC_HastaAnoGananciasyPerdidas__c',
		'FSC_Efectivo_en_caja_y_bancos__c',
		'FSC_Cuentas_por_cobrar_clientes__c',
		'FSC_Inventario__c',
		'FSC_Total_activos_corrientes__c',
		'FSC_Terrenos__c',
		'FSC_Edificaciones__c',
		'FSC_Maquinarias_y_equipos__c',
		'FSC_Muebles_y_enseres__c',
		'FSC_Vehiculos__c',
		'FSC_Otros_activos_fijos__c',
		'FSC_Total_Activos_Fijos__c',
		'FSC_Otros_activos__c',
		'FSC_Total_activos__c',
		'FSC_Docs_Por_pagar_Corto_Plazo__c',
		'FSC_Otras_deudas_corto_plazo__c',
		'FSC_Cuentas_por_pagar_suplidores__c',
		'FSC_Total_pasivos_corto_plazo__c',
		'FSC_Otras_cuentas_por_pagar__c',
		'FSC_Otros_pasivos__c',
		'FSC_Total_Pasivos__c',
		'FSC_Capital__c',
		'FSC_Total_pasivos_y_capital__c',
		'FSC_VentasSalario__c',
		'FSC_CostoMercanciaVendida__c',
		'FSC_GananciasBrutas__c',
		'FSC_OtrosIngresos__c',
		'FSC_ResultadoGananciasPerdida__c',
		'FSC_Nomina__c',
		'FSC_Alquiler_Generales__c',
		'FSC_Servicios_basicos_Generales__c',
		'FSC_Combustible__c',
		'FSC_Reparaciones__c',
		'FSC_Seguros_Generales__c',
		'FSC_Otros_Generales__c',
		'FSC_Total_Gastos_Grales_y_Adm__c',
		'FSC_Alquiler_Personales__c',
		'FSC_Servicios_basicos_Personales__c',
		'FSC_Alimentos__c',
		'FSC_Educacion__c',
		'FSC_Transporte__c',
		'FSC_Seguros_Personales__c',
		'FSC_Otros_Personales__c',
		'FSC_Total_gastos_personales__c',
		'FSC_Cuotas__c',
		'FSC_Otros_Financieros__c',
		'FSC_Total_gastos_financieros__c'
	};

	private static final Set<String> NOT_PYME_TRACKED_FIELDS = new Set<String>{
		'Name',
		'AccountId',
		'FSC_Nombre_Cliente__c',
		'FSC_Monto_De_La_Cuota__c',
		'Status',
		'FSC_Subestado__c',
		'FSC_TipoSolicitud__c',
		'FSC_EsRefinanciamiento__c',
		'FSC_EsConsolidacionDeudas__c',
		'FSC_SolicitudMedianteReferidor__c',
		'FSC_Referidor__c',
		'FSC_RequiereContratoPagareNotarial__c',
		'FSC_DescripcionPropositoFacilidad__c',
		'FSC_TipoDeudaCancelar__c',
		'FSC_Facilidad__c',
		'FSC_Cuotas__c',
		'FSC_Monto__c',
		'FSC_TasaInteres__c',
		'FSC_Plazo_meses__c',
		'FSC_ActoNumeroPagare__c',
		'FSC_NumeroFolioPagare__c',
		'FSC_Aprobado_con_Condiciones__c',
		'FSC_MontoAprobado__c',
		'FSC_OtrasCondicionesComite__c',
		'FSC_PlazoMesesAprobado__c',
		'FSC_TasaInteresAprobada__c',
		'FSC_FechaYHoraAprobacionComite__c'
	};

	private static final String OBJ_LOAN_APPLICANT = 'LoanApplicant';
	private static final String OBJ_CONTACT_POINT_ADDRESS = 'ContactPointAddress';
	private static final String OBJ_CONTACT_POINT_PHONE = 'ContactPointPhone';
	private static final String OBJ_CONTACT_POINT_EMAIL = 'ContactPointEmail';
	private static final String OBJ_FACILIDAD_CREDITO = 'FSC_Facilidades_De_Credito__c';
	private static final String OBJ_GARANTIA = 'FSC_Garantia__c';
	private static final String OBJ_FACILIDAD_OTRA_INSTITUCION = 'FSC_Facilidad_Otra_Institucion__c';

	private static final String FIELD_LOAN_APPLICATION_ID = 'LoanApplicationId';
	private static final String FIELD_CONTACT_POINT_RLA_ID = 'FSC_ResidentialLoanApplicationId__c';
	private static final String FIELD_CONTACT_POINT_LOAN_APPLICANT_ID = 'FSC_Solicitante__c';
	private static final String FIELD_FACILIDAD_RLA_ID = 'FSC_Residential_Loan_Application__c';
	private static final String FIELD_FACILIDAD_OTRA_LOAN_APPLICANT_ID = 'FSC_LoanApplicant__c';

	private static final Map<String, String> DIRECT_RLA_FIELD_BY_OBJECT = new Map<String, String>{
		OBJ_LOAN_APPLICANT => FIELD_LOAN_APPLICATION_ID,
		OBJ_CONTACT_POINT_ADDRESS => FIELD_CONTACT_POINT_RLA_ID,
		OBJ_CONTACT_POINT_PHONE => FIELD_CONTACT_POINT_RLA_ID,
		OBJ_CONTACT_POINT_EMAIL => FIELD_CONTACT_POINT_RLA_ID,
		OBJ_FACILIDAD_CREDITO => FIELD_FACILIDAD_RLA_ID
	};

	private static final Map<String, Set<String>> RELATED_TRACKED_FIELDS_BY_OBJECT = new Map<String, Set<String>>{
		OBJ_LOAN_APPLICANT => new Set<String>{
			'Name',
			'LoanApplicationId',
			'FSC_ClasificacionSIB__c',
			'FSC_LugarFondeLabora__c',
			'FSC_EmpresaAnteriorLaboro__c',
			'FSC_FuenteIngreso__c',
			'FSC_TipoVivienda__c',
			'FSC_OtrosIngresos__c',
			'FSC_NumIdentificacion__c',
			'FSC_TipoIdentificacion__c',
			'FSC_SegundoApellido__c',
			'FSC_Nombre__c',
			'FSC_FechaNacimiento__c',
			'FSC_TiempoVivienda__c',
			'FSC_TiempoLaborando__c',
			'FSC_PrimerApellido__c',
			'FSC_EstadoCivil__c',
			'FSC_NumeroDependientes__c',
			'FSC_TipoNegocio__c',
			'FSC_Ocupacion__c',
			'FSC_TipoSolicitante__c',
			'FSC_Nacionalidad__c',
			'FSC_IngresosMensuales__c',
			'FSC_DescripcionOtrosIngresos__c',
			'FSC_MontoPrestacionesLaborales__c',
			'FSC_TipoDeudor__c',
			'FSC_TotalIngresos__c'
		},
		OBJ_CONTACT_POINT_ADDRESS => new Set<String>{
			'Name',
			'City',
			'Country',
			'State',
			'Street',
			'PostalCode',
			'FSC_Solicitante__c',
			'FSC_ResidentialLoanApplicationId__c'
		},
		OBJ_CONTACT_POINT_PHONE => new Set<String>{
			'TelephoneNumber',
			'FSC_TipoContacto__c',
			'FSC_Solicitante__c',
			'FSC_ResidentialLoanApplicationId__c'
		},
		OBJ_CONTACT_POINT_EMAIL => new Set<String>{ 'EmailAddress', 'FSC_Solicitante__c', 'FSC_ResidentialLoanApplicationId__c' },
		OBJ_FACILIDAD_CREDITO => new Set<String>{
			'FSC_Aumento_Solicitado__c',
			'FSC_Compromiso_Mensual__c',
			'FSC_Descripcion_Proposito_Facilidad__c',
			'FSC_Deuda_Actual__c',
			'FSC_Fecha_Apertura__c',
			'FSC_Forma_De_Pago__c',
			'FSC_Limite_Autorizado__c',
			'FSC_Lineas_Financieras_Empresas__c',
			'FSC_Moneda__c',
			'FSC_Monto_De_La_Cuota__c',
			'FSC_Monto_Solicitado__c',
			'FSC_Numero__c',
			'FSC_Plazo_meses__c',
			'FSC_Posible_Compromiso__c',
			'FSC_Prestamo_Con_Garantia__c',
			'FSC_Prestamo_Convenio__c',
			'FSC_Requiere_Contrato_Pagare_Notarial__c',
			'FSC_Tasa_Fija__c',
			'FSC_Tasa_Interes__c',
			'FSC_Tasa__c',
			'FSC_Tiempo_Tasa_Fija__c',
			'FSC_Tipo_Facilidad__c',
			'FSC_Tipo_Modalidad__c',
			'FSC_Tipo_de_Facilidad__c',
			'Name'
		},
		OBJ_GARANTIA => new Set<String>{
			'FSC_Clase_de_Garantia__c',
			'FSC_Descripcion_de_la_Garantia__c',
			'FSC_Fecha_Tasacion__c',
			'FSC_Metros_Cuadrados_de_Construccion__c',
			'FSC_Monto_Inicial_Avance_Pagado__c',
			'FSC_Precio_de_Venta__c',
			'FSC_Proposito_Garantia_Hipotecario__c',
			'FSC_Tasado_Por__c',
			'FSC_Tipo_de_Garantia__c',
			'FSC_Tipo_de_Inmueble__c',
			'FSC_Ubicacion__c',
			'FSC_Valor_Inmueble__c',
			'FSC_Valor_Tasado__c',
			'Name'
		},
		OBJ_FACILIDAD_OTRA_INSTITUCION => new Set<String>{
			'Name',
			'FSC_EntidadFinanciera__c',
			'FSC_DescripcionFacilidad__c',
			'FSC_TipoFacilidad__c',
			'FSC_Moneda__c',
			'FSC_Balance__c',
			'FSC_Facilidad__c',
			'FSC_LoanApplicant__c'
		}
	};

	public static Boolean shouldRegenerateSolicitudCredito(ResidentialLoanApplication newRecord, ResidentialLoanApplication oldRecord) {
		if (newRecord == null || oldRecord == null) {
			return false;
		}

		if (!isValidStatusAndSubestado(newRecord.Status, newRecord.FSC_Subestado__c)) {
			return false;
		}

		Set<String> trackedFields = getTrackedFields(newRecord.RecordTypeId, oldRecord.RecordTypeId);
		if (trackedFields.isEmpty()) {
			return false;
		}

		return hasTrackedFieldChanged(newRecord, oldRecord, trackedFields);
	}

	public static void enqueueRegenerationForRelatedRecords(List<SObject> newRecords, Map<Id, SObject> oldRecords) {
		if (newRecords == null || newRecords.isEmpty() || oldRecords == null || oldRecords.isEmpty()) {
			return;
		}

		String sObjectApiName = getSObjectApiName(newRecords);
		if (String.isBlank(sObjectApiName)) {
			return;
		}

		Set<String> trackedFields = RELATED_TRACKED_FIELDS_BY_OBJECT.get(sObjectApiName);
		if (trackedFields == null || trackedFields.isEmpty()) {
			return;
		}

		Set<Id> residentialLoanApplicationIds = getRelatedResidentialLoanApplicationIds(sObjectApiName, newRecords, oldRecords, trackedFields);

		enqueueRegeneration(filterRegeneratableResidentialLoanApplicationIds(residentialLoanApplicationIds));
	}

	public static void enqueueRegenerationForRelatedRecords(List<SObject> records) {
		if (records == null || records.isEmpty()) {
			return;
		}

		String sObjectApiName = getSObjectApiName(records);
		if (String.isBlank(sObjectApiName) || !RELATED_TRACKED_FIELDS_BY_OBJECT.containsKey(sObjectApiName)) {
			return;
		}

		Set<Id> residentialLoanApplicationIds = getRelatedResidentialLoanApplicationIds(sObjectApiName, records);

		Set<Id> regeneratableIds = filterRegeneratableResidentialLoanApplicationIds(residentialLoanApplicationIds);
		enqueueRegeneration(filterResidentialLoanApplicationsWithSolicitudCreditoPdf(regeneratableIds));
	}

	private static Boolean isValidStatusAndSubestado(String status, String subestado) {
		if (subestado == SUBESTADO_COMPLETANDO_INFORMACION) {
			return status == STATUS_BORRADOR;
		}

		return status == STATUS_EN_PROCESO && SUBESTADOS_VALIDOS_EN_PROCESO.contains(subestado);
	}

	public static void enqueueRegeneration(Set<Id> residentialLoanApplicationIds) {
		if (residentialLoanApplicationIds == null || residentialLoanApplicationIds.isEmpty()) {
			return;
		}

		System.enqueueJob(new FSC_RegenerarSolicitudCreditoQueueable(new List<Id>(residentialLoanApplicationIds)));
	}

	private static Set<String> getTrackedFields(Id newRecordTypeId, Id oldRecordTypeId) {
		Id recordTypeId = newRecordTypeId != null ? newRecordTypeId : oldRecordTypeId;

		if (recordTypeId == RT_CREDITO_PYME_ID) {
			return PYME_TRACKED_FIELDS;
		}

		if (recordTypeId != RT_CREDITO_PYME_ID) {
			return NOT_PYME_TRACKED_FIELDS;
		}

		return new Set<String>();
	}

	private static Boolean hasTrackedFieldChanged(
		ResidentialLoanApplication newRecord,
		ResidentialLoanApplication oldRecord,
		Set<String> trackedFields
	) {
		for (String fieldApiName : trackedFields) {
			if (!areEqual(newRecord.get(fieldApiName), oldRecord.get(fieldApiName))) {
				return true;
			}
		}

		return false;
	}

	private static String getSObjectApiName(List<SObject> records) {
		for (SObject record : records) {
			if (record != null) {
				return record.getSObjectType().getDescribe().getName();
			}
		}

		return null;
	}

	private static Set<Id> getRelatedResidentialLoanApplicationIds(
		String sObjectApiName,
		List<SObject> newRecords,
		Map<Id, SObject> oldRecords,
		Set<String> trackedFields
	) {
		Set<Id> residentialLoanApplicationIds = new Set<Id>();
		Set<Id> facilidadCreditoIds = new Set<Id>();
		Set<Id> loanApplicantIds = new Set<Id>();

		for (SObject newRecord : newRecords) {
			if (newRecord == null || newRecord.get('Id') == null) {
				continue;
			}

			SObject oldRecord = oldRecords.get((Id) newRecord.get('Id'));
			if (oldRecord == null || !hasRelatedTrackedFieldChanged(newRecord, oldRecord, trackedFields)) {
				continue;
			}

			if (sObjectApiName == OBJ_GARANTIA) {
				addId(residentialLoanApplicationIds, newRecord.get(FIELD_FACILIDAD_RLA_ID));
				addId(residentialLoanApplicationIds, oldRecord.get(FIELD_FACILIDAD_RLA_ID));
				continue;
			}

			if (sObjectApiName == OBJ_FACILIDAD_OTRA_INSTITUCION) {
				addId(loanApplicantIds, newRecord.get(FIELD_FACILIDAD_OTRA_LOAN_APPLICANT_ID));
				addId(loanApplicantIds, oldRecord.get(FIELD_FACILIDAD_OTRA_LOAN_APPLICANT_ID));
				continue;
			}

			if (isContactPointObject(sObjectApiName)) {
				addId(residentialLoanApplicationIds, newRecord.get(FIELD_CONTACT_POINT_RLA_ID));
				addId(residentialLoanApplicationIds, oldRecord.get(FIELD_CONTACT_POINT_RLA_ID));
				addId(loanApplicantIds, newRecord.get(FIELD_CONTACT_POINT_LOAN_APPLICANT_ID));
				addId(loanApplicantIds, oldRecord.get(FIELD_CONTACT_POINT_LOAN_APPLICANT_ID));
				continue;
			}

			String rlaFieldApiName = DIRECT_RLA_FIELD_BY_OBJECT.get(sObjectApiName);
			if (String.isBlank(rlaFieldApiName)) {
				continue;
			}

			addId(residentialLoanApplicationIds, newRecord.get(rlaFieldApiName));
			addId(residentialLoanApplicationIds, oldRecord.get(rlaFieldApiName));
		}

		residentialLoanApplicationIds.addAll(getResidentialLoanApplicationIdsByFacilidadCredito(facilidadCreditoIds));
		residentialLoanApplicationIds.addAll(getResidentialLoanApplicationIdsByLoanApplicant(loanApplicantIds));

		return residentialLoanApplicationIds;
	}

	private static Set<Id> getRelatedResidentialLoanApplicationIds(String sObjectApiName, List<SObject> records) {
		Set<Id> residentialLoanApplicationIds = new Set<Id>();
		Set<Id> facilidadCreditoIds = new Set<Id>();

		if (records == null || records.isEmpty()) {
			return residentialLoanApplicationIds;
		}

		if (sObjectApiName == OBJ_GARANTIA) {
			for (SObject record : records) {
				if (record == null) {
					continue;
				}

				addId(residentialLoanApplicationIds, record.get(FIELD_FACILIDAD_RLA_ID));
			}

			return getResidentialLoanApplicationIdsByFacilidadCredito(facilidadCreditoIds);
		}

		if (sObjectApiName == OBJ_FACILIDAD_OTRA_INSTITUCION) {
			Set<Id> loanApplicantIds = new Set<Id>();
			for (SObject record : records) {
				if (record == null) {
					continue;
				}

				addId(loanApplicantIds, record.get(FIELD_FACILIDAD_OTRA_LOAN_APPLICANT_ID));
			}

			return getResidentialLoanApplicationIdsByLoanApplicant(loanApplicantIds);
		}

		if (isContactPointObject(sObjectApiName)) {
			Set<Id> loanApplicantIds = new Set<Id>();
			for (SObject record : records) {
				if (record == null) {
					continue;
				}

				addId(residentialLoanApplicationIds, record.get(FIELD_CONTACT_POINT_RLA_ID));
				addId(loanApplicantIds, record.get(FIELD_CONTACT_POINT_LOAN_APPLICANT_ID));
			}

			residentialLoanApplicationIds.addAll(getResidentialLoanApplicationIdsByLoanApplicant(loanApplicantIds));
			return residentialLoanApplicationIds;
		}

		String rlaFieldApiName = DIRECT_RLA_FIELD_BY_OBJECT.get(sObjectApiName);
		if (String.isBlank(rlaFieldApiName)) {
			return residentialLoanApplicationIds;
		}

		for (SObject record : records) {
			if (record == null) {
				continue;
			}

			addId(residentialLoanApplicationIds, record.get(rlaFieldApiName));
		}

		return residentialLoanApplicationIds;
	}

	private static Set<Id> getResidentialLoanApplicationIdsByLoanApplicant(Set<Id> loanApplicantIds) {
		Set<Id> residentialLoanApplicationIds = new Set<Id>();
		if (loanApplicantIds == null || loanApplicantIds.isEmpty()) {
			return residentialLoanApplicationIds;
		}

		for (LoanApplicant applicant : [
			SELECT Id, LoanApplicationId
			FROM LoanApplicant
			WHERE Id IN :loanApplicantIds
		]) {
			addId(residentialLoanApplicationIds, applicant.LoanApplicationId);
		}

		return residentialLoanApplicationIds;
	}

	private static Set<Id> getResidentialLoanApplicationIdsByFacilidadCredito(Set<Id> facilidadCreditoIds) {
		Set<Id> residentialLoanApplicationIds = new Set<Id>();
		if (facilidadCreditoIds == null || facilidadCreditoIds.isEmpty()) {
			return residentialLoanApplicationIds;
		}

		for (FSC_Facilidades_De_Credito__c facilidad : [
			SELECT Id, FSC_Residential_Loan_Application__c
			FROM FSC_Facilidades_De_Credito__c
			WHERE Id IN :facilidadCreditoIds
		]) {
			addId(residentialLoanApplicationIds, facilidad.FSC_Residential_Loan_Application__c);
		}

		return residentialLoanApplicationIds;
	}

	private static Boolean isContactPointObject(String sObjectApiName) {
		return sObjectApiName == OBJ_CONTACT_POINT_ADDRESS || sObjectApiName == OBJ_CONTACT_POINT_PHONE || sObjectApiName == OBJ_CONTACT_POINT_EMAIL;
	}

	private static Set<Id> filterRegeneratableResidentialLoanApplicationIds(Set<Id> residentialLoanApplicationIds) {
		Set<Id> filteredIds = new Set<Id>();
		if (residentialLoanApplicationIds == null || residentialLoanApplicationIds.isEmpty()) {
			return filteredIds;
		}

		for (ResidentialLoanApplication rla : [
			SELECT Id, Status, FSC_Subestado__c
			FROM ResidentialLoanApplication
			WHERE Id IN :residentialLoanApplicationIds
		]) {
			if (isValidStatusAndSubestado(rla.Status, rla.FSC_Subestado__c)) {
				filteredIds.add(rla.Id);
			}
		}

		return filteredIds;
	}

	private static Set<Id> filterResidentialLoanApplicationsWithSolicitudCreditoPdf(Set<Id> residentialLoanApplicationIds) {
		Set<Id> filteredIds = new Set<Id>();
		if (residentialLoanApplicationIds == null || residentialLoanApplicationIds.isEmpty()) {
			return filteredIds;
		}

		for (ContentDocumentLink link : [
			SELECT LinkedEntityId
			FROM ContentDocumentLink
			WHERE LinkedEntityId IN :residentialLoanApplicationIds
			  AND (
				  ContentDocument.Title LIKE :TITLE_PATTERN_CREDITO_PYME
				  OR ContentDocument.Title LIKE :TITLE_PATTERN_CREDITO_PYME_NO_ACCENT
				  OR ContentDocument.Title LIKE :TITLE_PATTERN_CREDITO_CONSUMO
				  OR ContentDocument.Title LIKE :TITLE_PATTERN_CREDITO_CONSUMO_NO_ACCENT
				  OR ContentDocument.Title LIKE :TITLE_PATTERN_LEGACY_CREDITO_PYME
				  OR ContentDocument.Title LIKE :TITLE_PATTERN_LEGACY_CREDITO_PYME_NO_ACCENT
			  )
		]) {
			addId(filteredIds, link.LinkedEntityId);
		}

		return filteredIds;
	}

	private static Boolean hasRelatedTrackedFieldChanged(SObject newRecord, SObject oldRecord, Set<String> trackedFields) {
		Map<String, Schema.SObjectField> fieldMap = newRecord.getSObjectType().getDescribe().fields.getMap();

		for (String fieldApiName : trackedFields) {
			if (!fieldMap.containsKey(fieldApiName)) {
				continue;
			}

			if (!areEqual(newRecord.get(fieldApiName), oldRecord.get(fieldApiName))) {
				return true;
			}
		}

		return false;
	}

	private static void addId(Set<Id> ids, Object rawValue) {
		if (ids == null || rawValue == null) {
			return;
		}

		String idValue = String.valueOf(rawValue);
		if (String.isBlank(idValue)) {
			return;
		}

		ids.add((Id) idValue);
	}

	private static Boolean areEqual(Object newValue, Object oldValue) {
		if (newValue == oldValue) {
			return true;
		}

		if (newValue == null || oldValue == null) {
			return false;
		}

		return newValue == oldValue;
	}
}