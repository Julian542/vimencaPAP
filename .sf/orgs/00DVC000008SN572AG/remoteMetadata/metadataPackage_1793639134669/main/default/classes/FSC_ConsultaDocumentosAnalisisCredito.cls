/**
 * Centraliza las consultas necesarias para construir los documentos de análisis de crédito.
 */
public inherited sharing class FSC_ConsultaDocumentosAnalisisCredito {
	/**
	 * Obtiene una solicitud de crédito con los campos usados por ambos documentos.
	 * @param solicitudId Id de ResidentialLoanApplication.
	 * @return Solicitud encontrada o null.
	 */
	public static ResidentialLoanApplication seleccionarSolicitud(Id solicitudId) {
		if (solicitudId == null) {
			return null;
		}

		List<ResidentialLoanApplication> solicitudes = [
			SELECT
				Id,
				Name,
				AccountId,
				CreatedDate,
				CreatedBy.Name,
				CreatedBy.FSC_Sucursal__c,
				FSC_CreatedBy_Name__c,
				RecordType.DeveloperName,
				Status,
				FSC_Subestado__c,
				FSC_Sucursal__c,
				FSC_UsuarioAnalista__c,
				FSC_UsuarioAnalista__r.Name,
				FSC_Destino_del_Prestamo__c,
				FSC_DescripcionPropositoFacilidad__c,
				FSC_Monto__c,
				FSC_Plazo_meses__c,
				FSC_PlazoMeses__c,
				FSC_Moneda__c,
				FSC_TasaInteres__c,
				FSC_Monto_De_La_Cuota__c,
				FSC_TasaFijaPorMeses__c,
				FSC_Alquiler_Personales__c,
				FSC_Monto_de_los_Ingresos__c,
				FSC_Clasificacion_de_Riesgo__c,
				FSC_XCore_Buro__c,
				FSC_MoraTC30Dias__c,
				FSC_MoraTC60Dias__c,
				FSC_MoraTC90Dias__c,
				FSC_MoraPrestamo30Dias__c,
				FSC_MoraPrestamo60Dias__c,
				FSC_MoraPrestamo90Dias__c,
				FSC_ProbabilidadIncumplimientoBuro__c,
				FSC_CategoriaRiesgoBuro__c,
				FSC_DeudaTCBuroDOP__c,
				FSC_DeudaTCBuroUSD__c,
				FSC_DeudaPrestamoBuroDOP__c,
				FSC_DeudaPrestamoBuroUSD__c,
				FSC_CuotaTCBuroDOP__c,
				FSC_CuotaTCBuroUSD__c,
				FSC_CuotaPrestamoBuroDOP__c,
				FSC_CuotaPrestamoBuroUSD__c,
				FSC_Recomendaciones__c,
				FSC_ObservacionAnalistaDeCredito__c,
				FSC_FechaAprobacion__c,
				FSC_FechaYHoraAprobacionComite__c,
				FSC_MontoAprobado__c,
				FSC_Total_activos__c,
				FSC_Total_Pasivos__c,
				FSC_Actividad_economica__c,
				FSC_Ingresos_Mensuales__c,
				FSC_Origen_de_los_Ingresos__c,
				FSC_PrestamoGarantia__c,
				FSC_RequiereContratoPagareNotarial__c,
				FSC_TipoGarantia__c,
				FSC_Valor_de_la_Garantia__c,
				FSC_Descripcion_de_la_Garantia__c
			FROM ResidentialLoanApplication
			WHERE Id = :solicitudId
			WITH USER_MODE
			LIMIT 1
		];
		return solicitudes.isEmpty() ? null : solicitudes[0];
	}

	/**
	 * Obtiene la cuenta deudora relacionada con la solicitud.
	 * @param cuentaId Id de Account.
	 * @return Cuenta encontrada o null.
	 */
	public static Account seleccionarCuenta(Id cuentaId) {
		if (cuentaId == null) {
			return null;
		}

		List<Account> cuentas = [
			SELECT
				Id,
				Name,
				PersonBirthdate,
				BillingStreet,
				BillingCity,
				BillingState,
				BillingCountry,
				ACC_NumIdentificacion__c,
				ACC_Estado_Civil__c,
				ACC_N_Dependientes__c,
				ACC_Nacionalidad__c,
				ACC_Score_Crediticio__c,
				FinServ__CreditScore__c,
				ACC_Total_Activos__c,
				VFS_TotalPasivo__c,
				Actividad_Economica_Name__c
			FROM Account
			WHERE Id = :cuentaId
			WITH USER_MODE
			LIMIT 1
		];
		return cuentas.isEmpty() ? null : cuentas[0];
	}

	/**
	 * Obtiene los participantes de la solicitud.
	 * @param solicitudId Id de ResidentialLoanApplication.
	 * @return Participantes ordenados por fecha de creación.
	 */
	public static List<LoanApplicant> seleccionarParticipantes(Id solicitudId) {
		if (solicitudId == null) {
			return new List<LoanApplicant>();
		}

		return [
			SELECT
				Id,
				LoanApplicationId,
				FSC_TipoSolicitante__c,
				FSC_TipoIdentificacion__c,
				FSC_NumIdentificacion__c,
				FSC_Nombre__c,
				FSC_PrimerApellido__c,
				FSC_SegundoApellido__c,
				FSC_FechaNacimiento__c,
				FSC_Nacionalidad__c,
				FSC_EstadoCivil__c,
				FSC_NumeroDependientes__c,
				FSC_ClasificacionSIB__c,
				FSC_Ocupacion__c,
				FSC_FuenteIngreso__c,
				FSC_LugarFondeLabora__c,
				FSC_TiempoLaborando__c,
				FSC_IngresosMensuales__c,
				FSC_OtrosIngresos__c,
				FSC_TotalIngresos__c,
				FSC_DescripcionOtrosIngresos__c
			FROM LoanApplicant
			WHERE LoanApplicationId = :solicitudId
			WITH USER_MODE
			ORDER BY CreatedDate
		];
	}

	/**
	 * Obtiene el empleo principal del deudor.
	 * @param participanteId Id de LoanApplicant.
	 * @return Empleo encontrado o null.
	 */
	public static LoanApplicantEmployment seleccionarEmpleo(Id participanteId) {
		if (participanteId == null) {
			return null;
		}

		List<LoanApplicantEmployment> empleos = [
			SELECT Id, EmployerName, JobTitle, CurrentJobYearCount, CurrentJobAdditionalMonthCount, MonthlyTotalIncomeAmount
			FROM LoanApplicantEmployment
			WHERE LoanApplicantId = :participanteId
			WITH USER_MODE
			ORDER BY CreatedDate
			LIMIT 1
		];
		return empleos.isEmpty() ? null : empleos[0];
	}

	/**
	 * Obtiene las fuentes de ingreso registradas para la solicitud.
	 * @param solicitudId Id de ResidentialLoanApplication.
	 * @return Fuentes de ingreso.
	 */
	public static List<LoanApplicantIncome> seleccionarIngresos(Id solicitudId) {
		if (solicitudId == null) {
			return new List<LoanApplicantIncome>();
		}

		return [
			SELECT Id, LoanApplicantId, IncomeSourceType, MonthlyIncomeAmount
			FROM LoanApplicantIncome
			WHERE LoanApplicationId = :solicitudId
			WITH USER_MODE
			ORDER BY CreatedDate
		];
	}

	/**
	 * Obtiene las obligaciones financieras registradas para la solicitud.
	 * @param solicitudId Id de ResidentialLoanApplication.
	 * @return Obligaciones financieras.
	 */
	public static List<LoanApplicationLiability> seleccionarDeudas(Id solicitudId) {
		if (solicitudId == null) {
			return new List<LoanApplicationLiability>();
		}

		return [
			SELECT Id, AccountType, LiabilityClass, LoanType, MonthlyPaymentAmount, UnpaidBalanceAmount, ShouldBePaidInFull
			FROM LoanApplicationLiability
			WHERE LoanApplicationId = :solicitudId
			WITH USER_MODE
			ORDER BY CreatedDate
		];
	}

	/**
	 * Obtiene facilidades declaradas en otras instituciones para los participantes.
	 * @param participantesIds Ids de LoanApplicant.
	 * @return Facilidades externas encontradas.
	 */
	public static List<FSC_Facilidad_Otra_Institucion__c> seleccionarFacilidadesExternas(Set<Id> participantesIds) {
		if (participantesIds == null || participantesIds.isEmpty()) {
			return new List<FSC_Facilidad_Otra_Institucion__c>();
		}

		return [
			SELECT Id, FSC_LoanApplicant__c, FSC_TipoFacilidad__c, FSC_Facilidad__c, FSC_Balance__c
			FROM FSC_Facilidad_Otra_Institucion__c
			WHERE FSC_LoanApplicant__c IN :participantesIds
			WITH USER_MODE
			ORDER BY CreatedDate
		];
	}

	/**
	 * Obtiene los activos declarados para la solicitud.
	 * @param solicitudId Id de ResidentialLoanApplication.
	 * @return Activos declarados.
	 */
	public static List<LoanApplicationAsset> seleccionarActivos(Id solicitudId) {
		if (solicitudId == null) {
			return new List<LoanApplicationAsset>();
		}

		return [
			SELECT Id, AssetClass, AssetType, CashOrMarketValue, PresentMarketValue
			FROM LoanApplicationAsset
			WHERE LoanApplicationId = :solicitudId
			WITH USER_MODE
			ORDER BY CreatedDate
		];
	}

	/**
	 * Obtiene las garantías específicas vinculadas al RLA.
	 * @param solicitudId Id de ResidentialLoanApplication.
	 * @return Garantías encontradas.
	 */
	public static List<FSC_Garantia__c> seleccionarGarantias(Id solicitudId) {
		if (solicitudId == null) {
			return new List<FSC_Garantia__c>();
		}

		return [
			SELECT
				Id,
				FSC_Clase_de_Garantia__c,
				FSC_Tipo_de_Garantia__c,
				FSC_Descripcion_de_la_Garantia__c,
				FSC_Ubicacion__c,
				FSC_Metros_Cuadrados_de_Construccion__c,
				FSC_EsTasadorExterno__c,
				FSC_NombreTasadorExterno__c,
				FSC_Tasado_Por__c,
				FSC_Fecha_Tasacion__c,
				FSC_Valor_Tasado__c,
				FSC_Precio_de_Venta__c,
				FSC_Monto_Inicial_Avance_Pagado__c,
				FSC_Marca_Vehiculo__c,
				FSC_Modelo_Vehiculo__c,
				FSC_Ano_Vehiculo__c,
				FSC_Valor_Vehiculo__c,
				FSC_Valor_Inmueble__c
			FROM FSC_Garantia__c
			WHERE FSC_Residential_Loan_Application__c = :solicitudId
			WITH USER_MODE
			ORDER BY CreatedDate
		];
	}

	/**
	 * Obtiene las facilidades de crédito incluidas en la solicitud.
	 * @param solicitudId Id de ResidentialLoanApplication.
	 * @return Facilidades relacionadas con la solicitud.
	 */
	public static List<FSC_Facilidades_De_Credito__c> seleccionarFacilidadesCredito(Id solicitudId) {
		if (solicitudId == null) {
			return new List<FSC_Facilidades_De_Credito__c>();
		}

		return [
			SELECT Id, FSC_Monto_Solicitado__c, FSC_Requiere_Contrato_Pagare_Notarial__c, FSC_Tiempo_Tasa_Fija__c
			FROM FSC_Facilidades_De_Credito__c
			WHERE FSC_Residential_Loan_Application__c = :solicitudId
			WITH USER_MODE
			ORDER BY CreatedDate
		];
	}

	/** Obtiene el historial de pago registrado al recomendar la solicitud. */
	public static String seleccionarHistorialPago(Id solicitudId) {
		if (solicitudId == null) {
			return '';
		}

		List<ResidentialLoanApplication> solicitudes = [
			SELECT FSC_HistorialPago__c
			FROM ResidentialLoanApplication
			WHERE Id = :solicitudId
			LIMIT 1
		];
		return solicitudes.isEmpty() ? '' : solicitudes[0].FSC_HistorialPago__c;
	}

	/** Obtiene los documentos cargados que sirven como evidencia de ingresos. */
	public static List<String> seleccionarEvidenciasIngresos(Id solicitudId) {
		if (solicitudId == null) {
			return new List<String>();
		}

		List<FSC_SolicitudDeCreditoYChecklistDeDocs__c> documentos = [
			SELECT Id, FSC_Documento__r.Name, FSC_Documento__r.FSC_NombreDelDocumento__c
			FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
			WHERE FSC_SolicitudDeCredito__c = :solicitudId AND FSC_NoAplica__c = FALSE
			WITH USER_MODE
			ORDER BY FSC_Documento__r.FSC_NroDeDocumento__c
		];
		if (documentos.isEmpty()) {
			return new List<String>();
		}

		Set<Id> documentosIds = new Map<Id, FSC_SolicitudDeCreditoYChecklistDeDocs__c>(documentos).keySet();
		Map<Id, List<String>> archivosPorDocumento = new Map<Id, List<String>>();
		for (ContentDocumentLink enlace : [
			SELECT LinkedEntityId, ContentDocument.Title
			FROM ContentDocumentLink
			WHERE LinkedEntityId IN :documentosIds
			WITH USER_MODE
		]) {
			if (!archivosPorDocumento.containsKey(enlace.LinkedEntityId)) {
				archivosPorDocumento.put(enlace.LinkedEntityId, new List<String>());
			}
			archivosPorDocumento.get(enlace.LinkedEntityId).add(enlace.ContentDocument.Title);
		}

		List<String> resultado = new List<String>();
		Set<String> nombresAgregados = new Set<String>();
		for (FSC_SolicitudDeCreditoYChecklistDeDocs__c documento : documentos) {
			String descripcion = documento.FSC_Documento__r?.FSC_NombreDelDocumento__c;
			String nombre = String.isBlank(descripcion) ? documento.FSC_Documento__r?.Name : descripcion;
			List<String> titulosArchivos = archivosPorDocumento.get(documento.Id);
			if (titulosArchivos == null) {
				continue;
			}
			for (String tituloArchivo : titulosArchivos) {
				if ((esEvidenciaIngresos(nombre) || esEvidenciaIngresos(tituloArchivo)) && nombresAgregados.add(tituloArchivo)) {
					resultado.add(tituloArchivo.trim());
				}
			}
		}
		return resultado;
	}

	/** Devuelve la tasa vigente USD a DOP configurada en Salesforce. */
	public static Decimal seleccionarTasaCambioActual() {
		try {
			List<SObject> monedas = Database.query(
				'SELECT IsoCode, ConversionRate FROM CurrencyType WHERE IsActive = true AND IsoCode IN (\'DOP\', \'USD\')'
			);
			Map<String, Decimal> tasas = new Map<String, Decimal>();
			for (SObject moneda : monedas) {
				tasas.put(String.valueOf(moneda.get('IsoCode')), (Decimal) moneda.get('ConversionRate'));
			}
			Decimal tasaDop = tasas.get('DOP');
			Decimal tasaUsd = tasas.get('USD');
			return tasaDop == null || tasaDop == 0 || tasaUsd == null ? null : tasaUsd / tasaDop;
		} catch (Exception error) {
			return null;
		}
	}

	private static Boolean esEvidenciaIngresos(String nombreOriginal) {
		String nombre = normalizar(nombreOriginal);
		return nombre.contains('ingreso') ||
			nombre.contains('estado de cuenta') ||
			nombre.contains('estados de cuenta') ||
			nombre.contains('estado financiero') ||
			nombre.contains('estados financieros') ||
			nombre.contains('carta laboral') ||
			nombre.contains('certificacion laboral') ||
			(nombre.contains('contrato') && nombre.contains('alquiler')) ||
			nombre.contains('registro mercantil') ||
			nombre.contains('declaracion de renta') ||
			nombre.contains('volante de pago') ||
			nombre.contains('volantes de pago') ||
			nombre.contains('nomina');
	}

	private static String normalizar(String valor) {
		return String.isBlank(valor)
			? ''
			: valor.toLowerCase().replace('á', 'a').replace('é', 'e').replace('í', 'i').replace('ó', 'o').replace('ú', 'u').replace('ü', 'u');
	}

	public static List<FSC_Excepcion__c> seleccionarExcepciones(Id solicitudId) {
		if (solicitudId == null) {
			return new List<FSC_Excepcion__c>();
		}

		return [
			SELECT Name, FSC_Tipo__c, FSC_Detalle__c, FSC_Motivo__c, FSC_Estado__c, FSC_Condicion__c, CreatedDate
			FROM FSC_Excepcion__c
			WHERE FSC_Solicitud_Prestamo__c = :solicitudId
			WITH USER_MODE
			ORDER BY CreatedDate, Id
		];
	}
}