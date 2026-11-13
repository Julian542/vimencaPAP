/**
 * Fábrica de datos aislados para las pruebas de documentos de análisis de crédito.
 */
@IsTest
public with sharing class FSC_FabricaDatosDocumentosAnalisisTest {
	private static final String NOMBRE_CUENTA_BASE = 'FSC Cliente Documentos Análisis';
	private static Integer secuenciaDocumento = 100000000;

	/** Crea los datos compartidos por los métodos de prueba. */
	public static void crearDatosBase() {
		insert new Account(
			Name = NOMBRE_CUENTA_BASE,
			ACC_NumIdentificacion__c = '00112345678',
			ACC_Score_Crediticio__c = '720',
			ACC_N_Dependientes__c = 2,
			ACC_Total_Activos__c = 500000,
			VFS_TotalPasivo__c = 100000,
			BillingStreet = 'Avenida Principal 1',
			BillingCity = 'Santo Domingo',
			BillingCountry = 'República Dominicana'
		);
	}

	/**
	 * @return Cuenta común creada por TestSetup.
	 */
	public static Account obtenerCuentaBase() {
		return [
			SELECT
				Id,
				Name,
				ACC_NumIdentificacion__c,
				ACC_Score_Crediticio__c,
				ACC_Total_Activos__c,
				VFS_TotalPasivo__c,
				BillingStreet,
				BillingCity,
				BillingCountry
			FROM Account
			WHERE Name = :NOMBRE_CUENTA_BASE
			WITH USER_MODE
			LIMIT 1
		];
	}

	/**
	 * Crea una solicitud de crédito.
	 * @param cuentaId Cuenta deudora.
	 * @param tipoRegistro Nombre de desarrollador del Record Type.
	 * @param estado Estado de la solicitud.
	 * @param subestado Subestado de la solicitud.
	 * @param monto Monto solicitado.
	 * @param insertar Indica si debe insertarse.
	 * @return Solicitud creada.
	 */
	public static ResidentialLoanApplication crearSolicitud(
		Id cuentaId,
		String tipoRegistro,
		String estado,
		String subestado,
		Decimal monto,
		Boolean insertar
	) {
		return crearSolicitudes(cuentaId, 1, tipoRegistro, estado, subestado, monto, insertar)[0];
	}

	/**
	 * Crea solicitudes en una sola operación DML.
	 * @param cuentaId Cuenta deudora.
	 * @param cantidad Cantidad de solicitudes.
	 * @param tipoRegistro Nombre de desarrollador del Record Type.
	 * @param estado Estado de las solicitudes.
	 * @param subestado Subestado de las solicitudes.
	 * @param monto Monto solicitado.
	 * @param insertar Indica si deben insertarse.
	 * @return Solicitudes creadas.
	 */
	public static List<ResidentialLoanApplication> crearSolicitudes(
		Id cuentaId,
		Integer cantidad,
		String tipoRegistro,
		String estado,
		String subestado,
		Decimal monto,
		Boolean insertar
	) {
		List<ResidentialLoanApplication> solicitudes = new List<ResidentialLoanApplication>();
		if (cantidad == null || cantidad <= 0) {
			return solicitudes;
		}

		Id tipoRegistroId = obtenerTipoRegistroSolicitud(tipoRegistro);
		String clave = String.valueOf(Datetime.now().getTime());
		for (Integer indice = 0; indice < cantidad; indice++) {
			solicitudes.add(
				new ResidentialLoanApplication(
					Name = 'FSC RLA Documentos ' + clave + ' ' + indice,
					AccountId = cuentaId,
					RecordTypeId = tipoRegistroId,
					Status = estado,
					FSC_Subestado__c = subestado,
					FSC_TipoSolicitud__c = 'BPR',
					FSC_lineaFinanciera__c = '32',
					FSC_subAplicacion__c = '401',
					FSC_Destino_del_Prestamo__c = 'Consolidación de deudas',
					FSC_Monto__c = monto,
					FSC_PlazoMeses__c = 60,
					FSC_Plazo_meses__c = '60',
					FSC_TasaInteres__c = 0.18,
					FSC_TasaFijaPorMeses__c = 12,
					FSC_Monto_De_La_Cuota__c = 12000,
					FSC_Alquiler_Personales__c = 15000,
					FSC_Monto_de_los_Ingresos__c = 80000,
					FSC_Cuotas__c = 5000,
					FSC_Clasificacion_de_Riesgo__c = 'A',
					FSC_Historial_del_cliente__c = 'Historial satisfactorio',
					FSC_Recomendaciones__c = 'Recomendado',
					FSC_ObservacionAnalistaDeCredito__c = 'Capacidad validada',
					FSC_FechaAprobacion__c = Date.today(),
					FSC_Actividad_economica__c = 'Servicios profesionales',
					FSC_TipoGarantia__c = 'Hipotecaria',
					FSC_Valor_de_la_Garantia__c = 5000000,
					FSC_Sucursal__c = 'Principal',
					FSC_UsuarioAnalista__c = UserInfo.getUserId()
				)
			);
		}
		if (insertar) {
			insert solicitudes;
		}
		return solicitudes;
	}

	/**
	 * Crea un participante relacionado con la solicitud.
	 * @param solicitudId Solicitud relacionada.
	 * @param tipo Tipo de solicitante.
	 * @param nombre Nombre del participante.
	 * @param ingresoMensual Ingreso mensual.
	 * @param otrosIngresos Otros ingresos.
	 * @return Participante insertado.
	 */
	public static LoanApplicant crearParticipante(Id solicitudId, String tipo, String nombre, Decimal ingresoMensual, Decimal otrosIngresos) {
		secuenciaDocumento++;
		LoanApplicant participante = new LoanApplicant(
			Name = nombre,
			LoanApplicationId = solicitudId,
			FSC_TipoSolicitante__c = tipo,
			FSC_TipoIdentificacion__c = 'Cédula',
			FSC_NumIdentificacion__c = String.valueOf(secuenciaDocumento).leftPad(11, '0'),
			FSC_Nombre__c = nombre,
			FSC_FechaNacimiento__c = Date.today().addYears(-35),
			FSC_NumeroDependientes__c = 2,
			FSC_TiempoLaborando__c = Date.today().addYears(-3),
			FSC_IngresosMensuales__c = ingresoMensual,
			FSC_OtrosIngresos__c = otrosIngresos,
			FSC_ClasificacionSIB__c = primerValorActivo(LoanApplicant.FSC_ClasificacionSIB__c),
			FSC_Ocupacion__c = primerValorActivo(LoanApplicant.FSC_Ocupacion__c),
			FSC_FuenteIngreso__c = primerValorActivo(LoanApplicant.FSC_FuenteIngreso__c),
			FSC_EstadoCivil__c = primerValorActivo(LoanApplicant.FSC_EstadoCivil__c),
			FSC_Nacionalidad__c = primerValorActivo(LoanApplicant.FSC_Nacionalidad__c)
		);
		insert participante;
		return participante;
	}

	/**
	 * Crea una fuente estructurada de ingreso.
	 * @param solicitudId Solicitud relacionada.
	 * @param participanteId Participante relacionado.
	 * @param monto Monto mensual.
	 * @return Ingreso insertado.
	 */
	public static LoanApplicantIncome crearIngreso(Id solicitudId, Id participanteId, Decimal monto) {
		LoanApplicantIncome ingreso = new LoanApplicantIncome(
			Name = 'FSC Ingreso ' + String.valueOf(Datetime.now().getTime()),
			LoanApplicationId = solicitudId,
			LoanApplicantId = participanteId,
			IncomeSourceType = primerValorActivo(LoanApplicantIncome.IncomeSourceType),
			MonthlyIncomeAmount = monto
		);
		insert ingreso;
		return ingreso;
	}

	/**
	 * Crea el empleo principal de un participante.
	 * @param solicitudId Solicitud relacionada.
	 * @param participanteId Participante relacionado.
	 * @param anos Años en el empleo.
	 * @param meses Meses adicionales.
	 * @return Empleo insertado.
	 */
	public static LoanApplicantEmployment crearEmpleo(Id solicitudId, Id participanteId, Integer anos, Integer meses) {
		LoanApplicantEmployment empleo = new LoanApplicantEmployment(
			Name = 'FSC Empleo ' + String.valueOf(Datetime.now().getTime()),
			LoanApplicationId = solicitudId,
			LoanApplicantId = participanteId,
			EmployerName = 'Empresa FSC',
			JobTitle = 'Analista',
			CurrentJobYearCount = anos,
			CurrentJobAdditionalMonthCount = meses
		);
		insert empleo;
		return empleo;
	}

	/**
	 * Crea una obligación financiera estándar.
	 * @param solicitudId Solicitud relacionada.
	 * @param balance Balance pendiente.
	 * @param cuota Cuota mensual.
	 * @param cancelar Indica si será cancelada con el nuevo crédito.
	 * @return Obligación insertada.
	 */
	public static LoanApplicationLiability crearDeuda(Id solicitudId, Decimal balance, Decimal cuota, Boolean cancelar) {
		LoanApplicationLiability deuda = new LoanApplicationLiability(
			Name = 'FSC Deuda ' + String.valueOf(Datetime.now().getTime()),
			LoanApplicationId = solicitudId,
			UnpaidBalanceAmount = balance,
			MonthlyPaymentAmount = cuota,
			ShouldBePaidInFull = cancelar
		);
		insert deuda;
		return deuda;
	}

	/**
	 * Crea un activo declarado.
	 * @param solicitudId Solicitud relacionada.
	 * @param valor Valor de mercado.
	 * @return Activo insertado.
	 */
	public static LoanApplicationAsset crearActivo(Id solicitudId, Decimal valor) {
		LoanApplicationAsset activo = new LoanApplicationAsset(
			Name = 'FSC Activo ' + String.valueOf(Datetime.now().getTime()),
			LoanApplicationId = solicitudId,
			CashOrMarketValue = valor
		);
		insert activo;
		return activo;
	}

	/**
	 * Crea una garantía hipotecaria.
	 * @param solicitudId Solicitud relacionada.
	 * @param valorTasado Valor tasado.
	 * @param precioVenta Precio de venta.
	 * @return Garantía insertada.
	 */
	public static FSC_Garantia__c crearGarantiaHipotecaria(Id solicitudId, Decimal valorTasado, Decimal precioVenta) {
		FSC_Garantia__c garantia = new FSC_Garantia__c(
			Name = 'FSC Garantía ' + String.valueOf(Datetime.now().getTime()),
			FSC_Residential_Loan_Application__c = solicitudId,
			FSC_Tipo_de_Garantia__c = 'Hipotecaria',
			FSC_Descripcion_de_la_Garantia__c = 'Apartamento residencial',
			FSC_Ubicacion__c = 'Santo Domingo',
			FSC_Metros_Cuadrados_de_Construccion__c = 120,
			FSC_Tasado_Por__c = primerValorActivo(FSC_Garantia__c.FSC_Tasado_Por__c),
			FSC_Fecha_Tasacion__c = Date.today(),
			FSC_Valor_Tasado__c = valorTasado,
			FSC_Valor_Inmueble__c = valorTasado,
			FSC_Precio_de_Venta__c = precioVenta,
			FSC_Monto_Inicial_Avance_Pagado__c = 500000
		);
		insert garantia;
		return garantia;
	}

	/**
	 * Crea una tarjeta declarada en otra institución.
	 * @param participanteId Participante relacionado.
	 * @param balance Balance pendiente.
	 * @return Facilidad insertada.
	 */
	public static FSC_Facilidad_Otra_Institucion__c crearTarjetaExterna(Id participanteId, Decimal balance) {
		FSC_Facilidad_Otra_Institucion__c facilidad = new FSC_Facilidad_Otra_Institucion__c(
			Name = 'FSC Tarjeta Externa ' + String.valueOf(Datetime.now().getTime()),
			FSC_LoanApplicant__c = participanteId,
			FSC_TipoFacilidad__c = 'TARJETA CREDITO - BTC',
			FSC_Facilidad__c = 'VISA CLASICA LOCAL - 47',
			FSC_Balance__c = balance
		);
		insert facilidad;
		return facilidad;
	}

	/**
	 * Publica un archivo de prueba en una solicitud.
	 * @param solicitudId Solicitud destino.
	 * @param titulo Título del archivo.
	 * @return Versión insertada.
	 */
	public static ContentVersion crearArchivo(Id solicitudId, String titulo) {
		ContentVersion versionArchivo = new ContentVersion(
			Title = titulo,
			PathOnClient = titulo + '.pdf',
			VersionData = Blob.valueOf('PDF DE PRUEBA'),
			FirstPublishLocationId = solicitudId
		);
		insert versionArchivo;
		return versionArchivo;
	}

	/**
	 * @param developerName Nombre de desarrollador.
	 * @return Id del Record Type o null.
	 */
	public static Id obtenerTipoRegistroSolicitud(String developerName) {
		Schema.RecordTypeInfo informacion = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName().get(developerName);
		return informacion?.getRecordTypeId();
	}

	private static String primerValorActivo(Schema.SObjectField campo) {
		for (Schema.PicklistEntry valor : campo.getDescribe().getPicklistValues()) {
			if (valor.isActive()) {
				return valor.getValue();
			}
		}
		return null;
	}
}