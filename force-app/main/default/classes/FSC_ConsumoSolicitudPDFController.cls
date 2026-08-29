public with sharing class FSC_ConsumoSolicitudPDFController {
	public Id rlaId { get; private set; }

	private ResidentialLoanApplication rla;
	private Account acc;
	private Map<String, Schema.SObjectField> rlaFieldMap;
	private Map<String, Schema.SObjectField> accFieldMap;
	private Map<String, Schema.SObjectField> userFieldMap;
	private List<ReferenciaRow> referenciasCache;
	private List<FacilidadRow> facilidadesCache;
	private List<GarantiaRow> garantiasCache;
	private List<String> direccionesCache;
	private List<String> telefonosCache;
	private List<String> correosCache;
	private List<SObject> loanApplicants;
	private SObject solicitanteLoanApplicant;
	private SObject coSolicitanteLoanApplicant;
	private SObject garanteLoanApplicant;
	private SObject datosGeneralesLoanApplicant;
	private SObject solicitanteEmployment;
	private SObject solicitanteAddress;
	private List<SObject> garantiasPdfSource;
	private List<GarantiaPdfRow> garantiasPdfCache;
	private List<FSC_LoanApplicantFirmanteService.Firmante> loanApplicantFirmantesCache;
	private List<FirmantePairRow> loanApplicantFirmanteRowsCache;
	private List<SignaturePairRow> signatureRowsCache;

	public FSC_ConsumoSolicitudPDFController() {
		rlaId = (Id) ApexPages.currentPage().getParameters().get('id');
		rlaFieldMap = Schema.SObjectType.ResidentialLoanApplication.fields.getMap();
		accFieldMap = Schema.SObjectType.Account.fields.getMap();
		userFieldMap = Schema.SObjectType.User.fields.getMap();
		loanApplicants = new List<SObject>();

		if (rlaId != null) {
			loadRla();
			loadAccount();
			loadLoanApplicants();
			loadGarantiasPdfSource();
		}
	}

	private void loadRla() {
		List<String> fieldApis = new List<String>{
			'AccountId',
			'FSC_Sucursal__c',
			'FSC_CodigoAprobacion__c',
			'FSC_Clasificacion_de_Riesgo__c',
			'FSC_clasificacionSib__c',
			'FSC_TipoCredito__c',
			'FSC_Tipo_de_solicitud__c',
			'FSC_Tipo_de_solicitud_Otro__c',
			'FSC_TipoSolicitud__c',
			'FSC_Destino_del_Prestamo__c',
			'FSC_Moneda__c',
			'FSC_Monto__c',
			'FSC_MontoAprobado__c',
			'FSC_MontoDesembolso__c',
			'FSC_MontoDesembolsar__c',
			'FSC_Plazo_meses__c',
			'FSC_PlazoMeses__c',
			'FSC_TasaInteres__c',
			'FSC_MontoCuotaRegular__c',
			'FSC_MontoTotalCuotaMensual__c',
			'FSC_FormaPago__c',
			'FSC_EsRefinanciamiento__c',
			'FSC_EsConsolidacionDeudas__c',
			'FSC_TipoDeudaCancelar__c',
			'FSC_Aplica_Garantia__c',
			'FSC_TipoGarantia__c',
			'FSC_Tipo_de_Garantia__c',
			'FSC_Valor_de_la_Garantia__c',
			'FSC_Descripcion_de_la_Garantia__c',
			'FSC_Observaciones__c',
			'FSC_CreatedBy_Name__c',
			'FSC_Nombre_del_negocio__c',
			'FSC_Cargo__c',
			'FSC_Actividad_economica__c',
			'FSC_Tiempo_laborando__c',
			'FSC_Tiempo_del_negocio__c',
			'FSC_Ingresos_Mensuales__c',
			'FSC_Monto_de_los_Ingresos__c',
			'FSC_Telefono__c',
			'FSC_Correo_Electronico__c',
			'FSC_Direccion_del_Negocio__c',
			'FSC_NumeroCliente__c',
			'FSC_DescripcionPropositoFacilidad__c',
			'FSC_Numero__c',
			'FSC_Tipo_de_Facilidad__c',
			'FSC_Prestamo_Con_Garantia__c',
			'FSC_Monto_Solicitado__c',
			'FSC_Forma_De_Pago__c',
			'FSC_Tasa__c',
			'FSC_Tasa_Fija__c',
			'FSC_Monto_De_La_Cuota__c',
			'FSC_Tiempo_Tasa_Fija__c',
			'FSC_Deuda_Actual__c',
			'FSC_Descripcion_Proposito_Facilidad__c',
			'FSC_Compromiso_Mensual__c',
			'FSC_Limite_Autorizado__c',
			'FSC_Aumento_Solicitado__c'
		};

		List<String> selectFields = new List<String>{
			'Id',
			'Name',
			'Status',
			'CreatedDate',
			'CreatedBy.Name',
			'RecordType.DeveloperName',
			'RecordType.Name'
		};
		if (userFieldMap.containsKey('FSC_Sucursal__c')) {
			selectFields.add('CreatedBy.FSC_Sucursal__c');
		}
		for (String api : fieldApis) {
			if (rlaFieldMap.containsKey(api)) {
				selectFields.add(api);
			}
		}

		String soql =
			'SELECT ' +
			String.join(selectFields, ',') +
			' FROM ResidentialLoanApplication WHERE Id = \'' +
			String.escapeSingleQuotes(String.valueOf(rlaId)) +
			'\' LIMIT 1';

		rla = (ResidentialLoanApplication) Database.query(soql);
	}

	private void loadAccount() {
		if (rla == null) {
			return;
		}

		Id accountId = (Id) rla.get('AccountId');
		if (accountId == null) {
			return;
		}

		List<String> fieldApis = new List<String>{
			'FirstName',
			'MiddleName',
			'LastName',
			'PersonBirthdate',
			'PersonEmail',
			'PersonHomePhone',
			'PersonMobilePhone',
			'ACC_Telefono_Movil__c',
			'ACC_TipoIdentificacion__c',
			'ACC_NumIdentificacion__c',
			'ACC_Tipo_Identificacion_Anterior__c',
			'ACC_N_Identificacion_Anterior__c',
			'ACC_Nacionalidad__c',
			'ACC_Estado_Civil__c',
			'ACC_Genero__c',
			'Tipo_de_vivienda__c',
			'BillingStreet',
			'BillingCity',
			'BillingState',
			'BillingCountry',
			'PersonMailingStreet',
			'PersonMailingCity',
			'PersonMailingState',
			'PersonMailingCountry',
			'FinServ__BillingAddress__pc',
			'ACC_Nombre_Corto_Comercial__c',
			'ACC_N_Dependientes__c',
			'ACC_Codigo_Persona_PF__c',
			'FinServ__CustomerID__c'
		};

		List<String> selectFields = new List<String>{ 'Id', 'Name' };
		for (String api : fieldApis) {
			if (accFieldMap.containsKey(api)) {
				selectFields.add(api);
			}
		}

		String soql =
			'SELECT ' +
			String.join(selectFields, ',') +
			' FROM Account WHERE Id = \'' +
			String.escapeSingleQuotes(String.valueOf(accountId)) +
			'\' LIMIT 1';

		acc = (Account) Database.query(soql);
	}

	private void loadLoanApplicants() {
		if (rlaId == null || !Schema.getGlobalDescribe().containsKey('LoanApplicant')) {
			return;
		}

		List<SObject> applicants = Database.query(
			'SELECT Id, ContactId, LoanApplicationId, FSC_TipoSolicitante__c, FSC_TipoIdentificacion__c, ' +
				'FSC_NumIdentificacion__c, FSC_Nombre__c, FSC_PrimerApellido__c, FSC_SegundoApellido__c, ' +
				'FSC_FechaNacimiento__c, FSC_Nacionalidad__c, FSC_EstadoCivil__c, FSC_NumeroDependientes__c, ' +
				'FSC_ClasificacionSIB__c, FSC_TipoVivienda__c, FSC_Ocupacion__c, FSC_FuenteIngreso__c, ' +
				'FSC_LugarFondeLabora__c, FSC_TipoNegocio__c, FSC_TiempoLaborando__c, FSC_IngresosMensuales__c, ' +
				'FSC_OtrosIngresos__c, FSC_EmpresaAnteriorLaboro__c, FSC_TotalIngresos__c, ' +
				'FSC_MontoPrestacionesLaborales__c, FSC_DescripcionOtrosIngresos__c ' +
				'FROM LoanApplicant WHERE LoanApplicationId = :rlaId ORDER BY CreatedDate'
		);
		loanApplicants = applicants;

		for (SObject applicant : applicants) {
			String tipo = safe(String.valueOf(applicant.get('FSC_TipoSolicitante__c'))).toLowerCase();
			if (solicitanteLoanApplicant == null && tipo.contains('deudor') && !tipo.contains('co')) {
				solicitanteLoanApplicant = applicant;
			} else if (coSolicitanteLoanApplicant == null && tipo.contains('co')) {
				coSolicitanteLoanApplicant = applicant;
			} else if (garanteLoanApplicant == null && tipo.contains('garante')) {
				garanteLoanApplicant = applicant;
			}
		}

		datosGeneralesLoanApplicant = firstAvailableApplicant();

		if (datosGeneralesLoanApplicant != null) {
			Id applicantId = (Id) datosGeneralesLoanApplicant.get('Id');
			if (Schema.getGlobalDescribe().containsKey('LoanApplicantEmployment')) {
				List<SObject> employments = Database.query(
					'SELECT EmployerName, EmployerAddress, JobTitle, CurrentJobYearCount, ' +
						'CurrentJobAdditionalMonthCount, MonthlyTotalIncomeAmount ' +
						'FROM LoanApplicantEmployment WHERE LoanApplicantId = :applicantId ' +
						'ORDER BY CreatedDate LIMIT 1'
				);
				if (!employments.isEmpty()) {
					solicitanteEmployment = employments[0];
				}
			}

			if (Schema.getGlobalDescribe().containsKey('LoanApplicantAddress')) {
				List<SObject> addresses = Database.query(
					'SELECT ResidenceAddress FROM LoanApplicantAddress WHERE LoanApplicantId = :applicantId ' + 'ORDER BY CreatedDate LIMIT 1'
				);
				if (!addresses.isEmpty()) {
					solicitanteAddress = addresses[0];
				}
			}
		}
	}

	private void loadGarantiasPdfSource() {
		garantiasPdfSource = new List<SObject>();
		if (rlaId == null || !Schema.getGlobalDescribe().containsKey('FSC_Garantia__c')) {
			return;
		}

		Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('FSC_Garantia__c').getDescribe().fields.getMap();
		String whereClause;
		if (fieldMap.containsKey('FSC_Residential_Loan_Application__c')) {
			whereClause = ' WHERE FSC_Residential_Loan_Application__c = \'' + String.escapeSingleQuotes(String.valueOf(rlaId)) + '\'';
		} else if (fieldMap.containsKey('FSC_Facilidad_De_Credito__c')) {
			whereClause =
				' WHERE FSC_Facilidad_De_Credito__r.FSC_Residential_Loan_Application__c = \'' +
				String.escapeSingleQuotes(String.valueOf(rlaId)) +
				'\'';
		} else {
			return;
		}

		String soql =
			'SELECT FSC_Clase_de_Garantia__c, FSC_Tipo_de_Garantia__c, FSC_Descripcion_de_la_Garantia__c, ' +
			'FSC_Proposito_Garantia_Hipotecario__c, FSC_Tipo_de_Inmueble__c, FSC_Ubicacion__c, ' +
			'FSC_Valor_Tasado__c, FSC_Fecha_Tasacion__c, FSC_Precio_de_Venta__c, FSC_Valor_Inmueble__c, ' +
			'FSC_Monto_Inicial_Avance_Pagado__c, FSC_Tasado_Por__c ' +
			'FROM FSC_Garantia__c' +
			whereClause +
			' ORDER BY CreatedDate, Id';

		garantiasPdfSource = Database.query(soql);
	}

	public String sucursal {
		get {
			return createdByVal('FSC_Sucursal__c');
		}
	}
	public String numeroSolicitud {
		get {
			return rla == null ? '' : safe(String.valueOf(rla.get('Name')));
		}
	}
	public String fechaHoyFmt {
		get {
			return fmtDate(Date.today());
		}
	}
	public String fechaSolicitudFmt {
		get {
			return rla == null ? '' : fmtDate(((DateTime) rla.get('CreatedDate')).date());
		}
	}
	public String estadoSolicitud {
		get {
			return rla == null ? '' : safe(String.valueOf(rla.get('Status')));
		}
	}
	public String codigoAprobacion {
		get {
			return safe(val('FSC_CodigoAprobacion__c'));
		}
	}
	public String destinoPrestamo {
		get {
			return safe(val('FSC_Destino_del_Prestamo__c'));
		}
	}
	public String moneda {
		get {
			return safe(val('FSC_Moneda__c'));
		}
	}
	public String formaPago {
		get {
			return safe(val('FSC_FormaPago__c'));
		}
	}
	public String tipoIdentificacion {
		get {
			return accVal('ACC_TipoIdentificacion__c');
		}
	}
	public String numeroIdentificacion {
		get {
			return accVal('ACC_NumIdentificacion__c');
		}
	}
	public String tipoIdentificacionAnterior {
		get {
			return accVal('ACC_Tipo_Identificacion_Anterior__c');
		}
	}
	public String numeroIdentificacionAnterior {
		get {
			return accVal('ACC_N_Identificacion_Anterior__c');
		}
	}
	public String nacionalidad {
		get {
			return accVal('ACC_Nacionalidad__c');
		}
	}
	public String genero {
		get {
			return accVal('ACC_Genero__c');
		}
	}
	public String estadoCivil {
		get {
			return accVal('ACC_Estado_Civil__c');
		}
	}
	public String tipoVivienda {
		get {
			return accVal('Tipo_de_vivienda__c');
		}
	}
	public String primerNombre {
		get {
			return accVal('FirstName');
		}
	}
	public String segundoNombre {
		get {
			return accVal('MiddleName');
		}
	}
	public String apellidos {
		get {
			return accVal('LastName');
		}
	}
	public List<FSC_LoanApplicantFirmanteService.Firmante> loanApplicantFirmantes {
		get {
			if (loanApplicantFirmantesCache == null) {
				loanApplicantFirmantesCache = FSC_LoanApplicantFirmanteService.queryFirmantes(rlaId);
			}
			return loanApplicantFirmantesCache;
		}
	}
	public Integer loanApplicantFirmantesSize {
		get {
			return loanApplicantFirmantes == null ? 0 : loanApplicantFirmantes.size();
		}
	}

	public List<FirmantePairRow> loanApplicantFirmanteRows {
		get {
			if (loanApplicantFirmanteRowsCache == null) {
				loanApplicantFirmanteRowsCache = new List<FirmantePairRow>();
				for (Integer i = 0; i < loanApplicantFirmantesSize; i += 2) {
					FSC_LoanApplicantFirmanteService.Firmante left = loanApplicantFirmantes[i];
					FSC_LoanApplicantFirmanteService.Firmante right = i + 1 < loanApplicantFirmantesSize ? loanApplicantFirmantes[i + 1] : null;
					loanApplicantFirmanteRowsCache.add(new FirmantePairRow(left, right));
				}
			}
			return loanApplicantFirmanteRowsCache;
		}
	}

	public Integer loanApplicantFirmanteRowsSize {
		get {
			return loanApplicantFirmanteRows == null ? 0 : loanApplicantFirmanteRows.size();
		}
	}

	public List<SignaturePairRow> signatureRows {
		get {
			if (signatureRowsCache == null) {
				List<SignatureCell> signatures = new List<SignatureCell>{
					new SignatureCell(
						'[[!FIRMASOLICITANTE:signer1:signature:size(width=120,height=40)]]',
						upperSafe(
							firstNonBlank(
							new List<String>{ joinNonBlank(new List<String>{ solicitanteNombres, solicitantePrimerApellido, solicitanteSegundoApellido }, ' '), nombreCompleto }
							)
						),
						'FIRMA DEL SOLICITANTE'
					)
				};
				for (FSC_LoanApplicantFirmanteService.Firmante firmante : loanApplicantFirmantes) {
					signatures.add(
						new SignatureCell(
							'[[!' + firmante.firmaElementId + ':signer1:signature:size(width=120,height=40)]]',
							upperSafe(firmante.name),
							upperSafe(firmante.tipoSolicitante)
						)
					);
				}

				signatureRowsCache = new List<SignaturePairRow>();
				for (Integer i = 0; i < signatures.size(); i += 2) {
					SignatureCell left = signatures[i];
					SignatureCell right = i + 1 < signatures.size() ? signatures[i + 1] : null;
					signatureRowsCache.add(new SignaturePairRow(left, right));
				}
			}
			return signatureRowsCache;
		}
	}

	public class SignatureCell {
		public String markerToken { get; private set; }
		public String label { get; private set; }
		public String secondaryLabel { get; private set; }

		public SignatureCell(String markerToken, String label, String secondaryLabel) {
			this.markerToken = markerToken;
			this.label = label;
			this.secondaryLabel = secondaryLabel;
		}

		public Boolean hasSecondaryLabel {
			get {
				return !String.isBlank(secondaryLabel);
			}
		}
	}

	public class SignaturePairRow {
		public SignatureCell left { get; private set; }
		public SignatureCell right { get; private set; }

		public SignaturePairRow(SignatureCell left, SignatureCell right) {
			this.left = left;
			this.right = right;
		}

		public Boolean hasRight {
			get {
				return right != null;
			}
		}
	}

	public class FirmantePairRow {
		public FSC_LoanApplicantFirmanteService.Firmante left { get; private set; }
		public FSC_LoanApplicantFirmanteService.Firmante right { get; private set; }

		public FirmantePairRow(FSC_LoanApplicantFirmanteService.Firmante left, FSC_LoanApplicantFirmanteService.Firmante right) {
			this.left = left;
			this.right = right;
		}

		public Boolean hasRight {
			get {
				return right != null;
			}
		}
	}

	public String oficialNegocios {
		get {
			String stored = safe(val('FSC_CreatedBy_Name__c'));
			if (stored != '') {
				return stored;
			}
			if (rla != null) {
				SObject createdBy = rla.getSObject('CreatedBy');
				if (createdBy != null) {
					return safe(String.valueOf(createdBy.get('Name')));
				}
			}
			return '';
		}
	}

	public String oficialNegociosFirma {
		get {
			return upperSafe(oficialNegocios);
		}
	}

	public String tipoCredito {
		get {
			return firstNonBlank(new List<String>{ safe(val('FSC_TipoCredito__c')), creditoProducto });
		}
	}

	public String tipoSolicitud {
		get {
			return firstNonBlank(
				new List<String>{
					safe(val('FSC_Tipo_de_solicitud__c')),
					safe(val('FSC_TipoSolicitud__c')),
					safe(val('FSC_Tipo_de_solicitud_Otro__c'))
				}
			);
		}
	}

	public String clasificacionSib {
		get {
			return firstNonBlank(new List<String>{ safe(val('FSC_clasificacionSib__c')), safe(val('FSC_Clasificacion_de_Riesgo__c')) });
		}
	}

	public String nombreCompleto {
		get {
			return joinNonBlank(new List<String>{ accVal('FirstName'), accVal('MiddleName'), accVal('LastName') }, ' ');
		}
	}

	public String fechaNacimientoFmt {
		get {
			return fmtDate(tryDate(acc == null ? null : acc.get('PersonBirthdate')));
		}
	}

	public String correo {
		get {
			return firstNonBlank(new List<String>{ accVal('PersonEmail'), safe(val('FSC_Correo_Electronico__c')) });
		}
	}

	public String telefonoResidencia {
		get {
			return firstNonBlank(new List<String>{ accVal('PersonHomePhone'), safe(val('FSC_Telefono__c')) });
		}
	}

	public String celular {
		get {
			return firstNonBlank(new List<String>{ accVal('ACC_Telefono_Movil__c'), accVal('PersonMobilePhone') });
		}
	}

	public String direccionResidencia {
		get {
			if (acc == null) {
				return '';
			}

			String fullAddress = accVal('FinServ__BillingAddress__pc');
			if (fullAddress != '') {
				return fullAddress;
			}

			String mailingAddress = joinNonBlank(
				new List<String>{
					accVal('PersonMailingStreet'),
					accVal('PersonMailingCity'),
					accVal('PersonMailingState'),
					accVal('PersonMailingCountry')
				},
				', '
			);
			if (mailingAddress != '') {
				return mailingAddress;
			}

			return joinNonBlank(
				new List<String>{ accVal('BillingStreet'), accVal('BillingCity'), accVal('BillingState'), accVal('BillingCountry') },
				', '
			);
		}
	}

	public String empresaActual {
		get {
			return firstNonBlank(new List<String>{ safe(val('FSC_Nombre_del_negocio__c')), accVal('ACC_Nombre_Corto_Comercial__c') });
		}
	}

	public String direccionLaboral {
		get {
			return safe(val('FSC_Direccion_del_Negocio__c'));
		}
	}
	public String actividadEconomica {
		get {
			return safe(val('FSC_Actividad_economica__c'));
		}
	}

	public String ocupacion {
		get {
			return firstNonBlank(new List<String>{ safe(val('FSC_Cargo__c')), safe(val('FSC_Actividad_economica__c')) });
		}
	}

	public String tiempoLaborando {
		get {
			return firstNonBlank(new List<String>{ safe(val('FSC_Tiempo_laborando__c')), safe(val('FSC_Tiempo_del_negocio__c')) });
		}
	}

	public Decimal ingresosMensualesVal {
		get {
			Decimal monthly = tryDec(rla == null ? null : rla.get('FSC_Ingresos_Mensuales__c'));
			if (monthly != null) {
				return monthly;
			}
			return tryDec(rla == null ? null : rla.get('FSC_Monto_de_los_Ingresos__c'));
		}
	}

	public String ingresosMensualesFmt {
		get {
			return fmtMoney(ingresosMensualesVal);
		}
	}

	public Decimal montoSolicitadoVal {
		get {
			return tryDec(rla == null ? null : rla.get('FSC_Monto__c'));
		}
	}
	public String montoSolicitadoFmt {
		get {
			return fmtMoney(montoSolicitadoVal);
		}
	}

	public Decimal montoAprobadoVal {
		get {
			Decimal approved = tryDec(rla == null ? null : rla.get('FSC_MontoAprobado__c'));
			return approved == null ? montoSolicitadoVal : approved;
		}
	}

	public String montoAprobadoFmt {
		get {
			return fmtMoney(montoAprobadoVal);
		}
	}

	public Decimal montoDesembolsoVal {
		get {
			Decimal disbursement = tryDec(rla == null ? null : rla.get('FSC_MontoDesembolsar__c'));
			if (disbursement != null) {
				return disbursement;
			}
			return tryDec(rla == null ? null : rla.get('FSC_MontoDesembolso__c'));
		}
	}

	public String montoDesembolsoFmt {
		get {
			return fmtMoney(montoDesembolsoVal);
		}
	}

	public String plazoMeses {
		get {
			return firstNonBlank(new List<String>{ safe(val('FSC_Plazo_meses__c')), safe(val('FSC_PlazoMeses__c')) });
		}
	}

	public Decimal tasaInteresVal {
		get {
			return tryDec(rla == null ? null : rla.get('FSC_TasaInteres__c'));
		}
	}
	public String tasaInteresFmt {
		get {
			return tasaInteresVal == null ? '' : String.valueOf(tasaInteresVal.setScale(2)) + '%';
		}
	}

	public Decimal cuotaMensualVal {
		get {
			Decimal full = tryDec(rla == null ? null : rla.get('FSC_MontoTotalCuotaMensual__c'));
			return full == null ? tryDec(rla == null ? null : rla.get('FSC_MontoCuotaRegular__c')) : full;
		}
	}

	public String cuotaMensualFmt {
		get {
			return fmtMoney(cuotaMensualVal);
		}
	}

	public Boolean esRefinanciamientoVal {
		get {
			return asBoolean(rla == null ? null : rla.get('FSC_EsRefinanciamiento__c'));
		}
	}
	public Boolean esConsolidacionVal {
		get {
			return asBoolean(rla == null ? null : rla.get('FSC_EsConsolidacionDeudas__c'));
		}
	}
	public String refinanciamientoTexto {
		get {
			return esRefinanciamientoVal ? '[X] Si  [ ] No' : '[ ] Si  [X] No';
		}
	}
	public String consolidacionTexto {
		get {
			return esConsolidacionVal ? '[X] Si  [ ] No' : '[ ] Si  [X] No';
		}
	}
	public String deudaCancelar {
		get {
			return safe(val('FSC_TipoDeudaCancelar__c'));
		}
	}

	public Boolean aplicaGarantiaVal {
		get {
			return asBoolean(rla == null ? null : rla.get('FSC_Aplica_Garantia__c'));
		}
	}
	public String aplicaGarantiaTexto {
		get {
			return aplicaGarantiaVal ? '[X] Si  [ ] No' : '[ ] Si  [X] No';
		}
	}

	public String tipoGarantia {
		get {
			return firstNonBlank(new List<String>{ safe(val('FSC_TipoGarantia__c')), safe(val('FSC_Tipo_de_Garantia__c')) });
		}
	}

	public Decimal garantiaValorVal {
		get {
			return tryDec(rla == null ? null : rla.get('FSC_Valor_de_la_Garantia__c'));
		}
	}
	public String garantiaValorFmt {
		get {
			return fmtMoney(garantiaValorVal);
		}
	}
	public String descripcionGarantia {
		get {
			return safe(val('FSC_Descripcion_de_la_Garantia__c'));
		}
	}
	public String observaciones {
		get {
			return safe(val('FSC_Observaciones__c'));
		}
	}

	public String usuarioOficial {
		get {
			return oficialNegocios;
		}
	}
	public String fechaSolicitudDetalleFmt {
		get {
			return rla == null ? '' : fmtDateTime((DateTime) rla.get('CreatedDate'));
		}
	}
	public String estadoActualSolicitud {
		get {
			return estadoSolicitud;
		}
	}
	public String tipoSolicitudGeneral {
		get {
			return tipoSolicitud;
		}
	}
	public String esConsolidacionSimple {
		get {
			return esConsolidacionVal ? 'Si' : 'No';
		}
	}
	public String esRefinanciamientoSimple {
		get {
			return esRefinanciamientoVal ? 'Si' : 'No';
		}
	}

	public Boolean mostrarCoSolicitante {
		get {
			return hasApplicantPdfData(coSolicitanteLoanApplicant);
		}
	}

	public Boolean mostrarGarante {
		get {
			return hasApplicantPdfData(garanteLoanApplicant);
		}
	}

	public String solicitanteTipo {
		get {
			return applicantVal(solicitanteLoanApplicant, 'FSC_TipoSolicitante__c');
		}
	}

	public String solicitanteTipoIdentificacion {
		get {
			if (solicitanteLoanApplicant == null) {
				return '';
			}
			return firstNonBlank(new List<String>{ applicantVal(solicitanteLoanApplicant, 'FSC_TipoIdentificacion__c'), tipoIdentificacion });
		}
	}

	public String solicitanteNumeroIdentificacion {
		get {
			if (solicitanteLoanApplicant == null) {
				return '';
			}
			return firstNonBlank(new List<String>{ applicantVal(solicitanteLoanApplicant, 'FSC_NumIdentificacion__c'), numeroIdentificacion });
		}
	}

	public String solicitanteCodigoCliente {
		get {
			if (solicitanteLoanApplicant == null) {
				return '';
			}
			return firstNonBlank(
				new List<String>{ safe(val('FSC_NumeroCliente__c')), accVal('FinServ__CustomerID__c'), accVal('ACC_Codigo_Persona_PF__c') }
			);
		}
	}

	public String solicitanteNombres {
		get {
			if (solicitanteLoanApplicant == null) {
				return '';
			}
			return firstNonBlank(
				new List<String>{
					applicantVal(solicitanteLoanApplicant, 'FSC_Nombre__c'),
					joinNonBlank(new List<String>{ accVal('FirstName'), accVal('MiddleName') }, ' ')
				}
			);
		}
	}

	public String solicitantePrimerApellido {
		get {
			if (solicitanteLoanApplicant == null) {
				return '';
			}
			return firstNonBlank(new List<String>{ applicantVal(solicitanteLoanApplicant, 'FSC_PrimerApellido__c'), splitLastNames(apellidos)[0] });
		}
	}

	public String solicitanteSegundoApellido {
		get {
			if (solicitanteLoanApplicant == null) {
				return '';
			}
			return firstNonBlank(new List<String>{ applicantVal(solicitanteLoanApplicant, 'FSC_SegundoApellido__c'), splitLastNames(apellidos)[1] });
		}
	}

	public String solicitanteNacionalidad {
		get {
			if (solicitanteLoanApplicant == null) {
				return '';
			}
			return firstNonBlank(new List<String>{ applicantVal(solicitanteLoanApplicant, 'FSC_Nacionalidad__c'), nacionalidad });
		}
	}

	public String solicitanteFechaNacimiento {
		get {
			if (solicitanteLoanApplicant == null) {
				return '';
			}
			Date birthDate = firstNonNullDate(
				new List<Date>{
					tryDate(solicitanteLoanApplicant == null ? null : solicitanteLoanApplicant.get('FSC_FechaNacimiento__c')),
					tryDate(acc == null ? null : acc.get('PersonBirthdate'))
				}
			);
			return fmtDate(birthDate);
		}
	}

	public String solicitanteEstadoCivil {
		get {
			if (solicitanteLoanApplicant == null) {
				return '';
			}
			return firstNonBlank(new List<String>{ applicantVal(solicitanteLoanApplicant, 'FSC_EstadoCivil__c'), estadoCivil });
		}
	}

	public String solicitanteNumeroDependientes {
		get {
			if (solicitanteLoanApplicant == null) {
				return '';
			}
			return firstNonBlank(
				new List<String>{ applicantVal(solicitanteLoanApplicant, 'FSC_NumeroDependientes__c'), accVal('ACC_N_Dependientes__c') }
			);
		}
	}

	public String solicitanteClasificacionSib {
		get {
			if (solicitanteLoanApplicant == null) {
				return '';
			}
			return firstNonBlank(new List<String>{ applicantVal(solicitanteLoanApplicant, 'FSC_ClasificacionSIB__c'), clasificacionSib });
		}
	}

	public String solicitanteEstadoVivienda {
		get {
			if (solicitanteLoanApplicant == null) {
				return '';
			}
			String applicantValue = applicantVal(solicitanteLoanApplicant, 'FSC_TipoVivienda__c');
			if (applicantValue != '') {
				return picklistLabel('LoanApplicant', 'FSC_TipoVivienda__c', applicantValue);
			}
			return tipoVivienda;
		}
	}

	public String coSolicitanteTipo {
		get {
			return applicantVal(coSolicitanteLoanApplicant, 'FSC_TipoSolicitante__c');
		}
	}
	public String coSolicitanteTipoIdentificacion {
		get {
			return applicantVal(coSolicitanteLoanApplicant, 'FSC_TipoIdentificacion__c');
		}
	}
	public String coSolicitanteNumeroIdentificacion {
		get {
			return applicantVal(coSolicitanteLoanApplicant, 'FSC_NumIdentificacion__c');
		}
	}
	public String coSolicitanteCodigoCliente {
		get {
			return '';
		}
	}
	public String coSolicitanteNombres {
		get {
			return applicantVal(coSolicitanteLoanApplicant, 'FSC_Nombre__c');
		}
	}
	public String coSolicitantePrimerApellido {
		get {
			return applicantVal(coSolicitanteLoanApplicant, 'FSC_PrimerApellido__c');
		}
	}
	public String coSolicitanteSegundoApellido {
		get {
			return applicantVal(coSolicitanteLoanApplicant, 'FSC_SegundoApellido__c');
		}
	}
	public String coSolicitanteNacionalidad {
		get {
			return applicantVal(coSolicitanteLoanApplicant, 'FSC_Nacionalidad__c');
		}
	}
	public String coSolicitanteFechaNacimiento {
		get {
			return fmtDate(tryDate(coSolicitanteLoanApplicant == null ? null : coSolicitanteLoanApplicant.get('FSC_FechaNacimiento__c')));
		}
	}
	public String coSolicitanteEstadoCivil {
		get {
			return applicantVal(coSolicitanteLoanApplicant, 'FSC_EstadoCivil__c');
		}
	}
	public String coSolicitanteNumeroDependientes {
		get {
			return applicantVal(coSolicitanteLoanApplicant, 'FSC_NumeroDependientes__c');
		}
	}
	public String coSolicitanteClasificacionSib {
		get {
			return applicantVal(coSolicitanteLoanApplicant, 'FSC_ClasificacionSIB__c');
		}
	}
	public String coSolicitanteEstadoVivienda {
		get {
			String applicantValue = applicantVal(coSolicitanteLoanApplicant, 'FSC_TipoVivienda__c');
			return applicantValue == '' ? '' : picklistLabel('LoanApplicant', 'FSC_TipoVivienda__c', applicantValue);
		}
	}

	public String garanteTipo {
		get {
			return applicantVal(garanteLoanApplicant, 'FSC_TipoSolicitante__c');
		}
	}
	public String garanteTipoIdentificacion {
		get {
			return applicantVal(garanteLoanApplicant, 'FSC_TipoIdentificacion__c');
		}
	}
	public String garanteNumeroIdentificacion {
		get {
			return applicantVal(garanteLoanApplicant, 'FSC_NumIdentificacion__c');
		}
	}
	public String garanteCodigoCliente {
		get {
			return '';
		}
	}
	public String garanteNombres {
		get {
			return applicantVal(garanteLoanApplicant, 'FSC_Nombre__c');
		}
	}
	public String garantePrimerApellido {
		get {
			return applicantVal(garanteLoanApplicant, 'FSC_PrimerApellido__c');
		}
	}
	public String garanteSegundoApellido {
		get {
			return applicantVal(garanteLoanApplicant, 'FSC_SegundoApellido__c');
		}
	}
	public String garanteNacionalidad {
		get {
			return applicantVal(garanteLoanApplicant, 'FSC_Nacionalidad__c');
		}
	}
	public String garanteFechaNacimiento {
		get {
			return fmtDate(tryDate(garanteLoanApplicant == null ? null : garanteLoanApplicant.get('FSC_FechaNacimiento__c')));
		}
	}
	public String garanteEstadoCivil {
		get {
			return applicantVal(garanteLoanApplicant, 'FSC_EstadoCivil__c');
		}
	}
	public String garanteNumeroDependientes {
		get {
			return applicantVal(garanteLoanApplicant, 'FSC_NumeroDependientes__c');
		}
	}
	public String garanteClasificacionSib {
		get {
			return applicantVal(garanteLoanApplicant, 'FSC_ClasificacionSIB__c');
		}
	}
	public String garanteEstadoVivienda {
		get {
			String applicantValue = applicantVal(garanteLoanApplicant, 'FSC_TipoVivienda__c');
			return applicantValue == '' ? '' : picklistLabel('LoanApplicant', 'FSC_TipoVivienda__c', applicantValue);
		}
	}

	public List<String> direcciones {
		get {
			if (direccionesCache == null) {
				direccionesCache = queryContactPointAddresses();
				if (direccionesCache.isEmpty()) {
					addIfNotBlank(
						direccionesCache,
						firstNonBlank(
							new List<String>{
								safe(solicitanteAddress == null ? null : String.valueOf(solicitanteAddress.get('ResidenceAddress'))),
								direccionResidencia
							}
						)
					);
				}
			}
			return direccionesCache;
		}
	}

	public List<String> telefonos {
		get {
			if (telefonosCache == null) {
				telefonosCache = queryContactPointPhones();
				if (telefonosCache.isEmpty()) {
					addAllNonBlank(telefonosCache, new List<String>{ telefonoResidencia, celular });
				}
			}
			return telefonosCache;
		}
	}

	public List<String> correos {
		get {
			if (correosCache == null) {
				correosCache = queryContactPointEmails();
				if (correosCache.isEmpty()) {
					addIfNotBlank(correosCache, correo);
				}
			}
			return correosCache;
		}
	}

	public String direccionTexto {
		get {
			return joinNonBlank(direcciones, ' / ');
		}
	}
	public String telefonosTexto {
		get {
			return joinNonBlank(telefonos, ' / ');
		}
	}
	public String correosTexto {
		get {
			return joinNonBlank(correos, ' / ');
		}
	}

	public String laborOcupacion {
		get {
			return firstNonBlank(
				new List<String>{ applicantVal(datosGeneralesLoanApplicant, 'FSC_Ocupacion__c'), safe(val('FSC_Actividad_economica__c')) }
			);
		}
	}

	public String laborFuenteIngreso {
		get {
			return firstNonBlank(
				new List<String>{ applicantVal(datosGeneralesLoanApplicant, 'FSC_FuenteIngreso__c'), safe(val('FSC_Actividad_economica__c')) }
			);
		}
	}

	public String laborLugarDondeLabora {
		get {
			return firstNonBlank(
				new List<String>{
					applicantVal(datosGeneralesLoanApplicant, 'FSC_LugarFondeLabora__c'),
					safe(solicitanteEmployment == null ? null : String.valueOf(solicitanteEmployment.get('EmployerName'))),
					empresaActual
				}
			);
		}
	}

	public String laborTipoNegocio {
		get {
			return firstNonBlank(
				new List<String>{ applicantVal(datosGeneralesLoanApplicant, 'FSC_TipoNegocio__c'), safe(val('FSC_Nombre_del_negocio__c')) }
			);
		}
	}

	public String laborCargoActual {
		get {
			return firstNonBlank(
				new List<String>{
					safe(solicitanteEmployment == null ? null : String.valueOf(solicitanteEmployment.get('JobTitle'))),
					safe(val('FSC_Cargo__c'))
				}
			);
		}
	}

	public String laborTiempoLaborando {
		get {
			return firstNonBlank(
				new List<String>{ applicantVal(datosGeneralesLoanApplicant, 'FSC_TiempoLaborando__c'), formatEmploymentTenure(), tiempoLaborando }
			);
		}
	}

	public String laborIngresosMensuales {
		get {
			Decimal value = firstNonNullDecimal(
				new List<Decimal>{
					tryDec(datosGeneralesLoanApplicant == null ? null : datosGeneralesLoanApplicant.get('FSC_IngresosMensuales__c')),
					tryDec(solicitanteEmployment == null ? null : solicitanteEmployment.get('MonthlyTotalIncomeAmount')),
					ingresosMensualesVal
				}
			);
			return fmtPdfMoney(value);
		}
	}

	public String laborOtrosIngresos {
		get {
			return fmtPdfMoney(
				firstNonNullDecimal(
					new List<Decimal>{
						tryDec(datosGeneralesLoanApplicant == null ? null : datosGeneralesLoanApplicant.get('FSC_OtrosIngresos__c')),
						tryDec(rla == null ? null : rla.get('FSC_Monto_de_los_Ingresos__c'))
					}
				)
			);
		}
	}

	public String laborEmpresaAnterior {
		get {
			return applicantVal(datosGeneralesLoanApplicant, 'FSC_EmpresaAnteriorLaboro__c');
		}
	}

	public String laborTotalIngresos {
		get {
			return fmtPdfMoney(
				firstNonNullDecimal(
					new List<Decimal>{
						tryDec(datosGeneralesLoanApplicant == null ? null : datosGeneralesLoanApplicant.get('FSC_TotalIngresos__c')),
						tryDec(solicitanteEmployment == null ? null : solicitanteEmployment.get('MonthlyTotalIncomeAmount'))
					}
				)
			);
		}
	}

	public String laborPrestaciones {
		get {
			return fmtPdfMoney(
				tryDec(datosGeneralesLoanApplicant == null ? null : datosGeneralesLoanApplicant.get('FSC_MontoPrestacionesLaborales__c'))
			);
		}
	}

	public String laborDescripcionOtrosIngresos {
		get {
			return applicantVal(datosGeneralesLoanApplicant, 'FSC_DescripcionOtrosIngresos__c');
		}
	}

	public String resumenTipoFacilidad {
		get {
			return 'CONTROL DE PRESTAMOS';
		}
	}

	public String resumenFacilidad {
		get {
			return firstNonBlank(new List<String>{ safe(val('FSC_Tipo_de_Facilidad__c')), creditoProductoMayuscula });
		}
	}

	public String resumenPrestamoConGarantia {
		get {
			Object value = rlaValue('FSC_Prestamo_Con_Garantia__c');
			if (value != null) {
				return asBoolean(value) ? 'Si' : 'No';
			}
			return aplicaGarantiaVal ? 'Si' : 'No';
		}
	}

	public String resumenMontoSolicitado {
		get {
			return fmtPdfMoney(firstNonNullDecimal(new List<Decimal>{ tryDec(rlaValue('FSC_Monto_Solicitado__c')), montoSolicitadoVal }));
		}
	}

	public String resumenFormaPago {
		get {
			return firstNonBlank(new List<String>{ safe(val('FSC_Forma_De_Pago__c')), formaPago });
		}
	}

	public String resumenPlazoActual {
		get {
			return firstNonBlank(new List<String>{ safe(val('FSC_Plazo_meses__c')), plazoMeses });
		}
	}

	public String resumenTasaInteresActual {
		get {
			Decimal value = firstNonNullDecimal(new List<Decimal>{ tryDec(rlaValue('FSC_Tasa__c')), tasaInteresVal });
			return value == null ? '' : String.valueOf(value.setScale(2)) + '%';
		}
	}

	public String resumenTasaFija {
		get {
			Object value = rlaValue('FSC_Tasa_Fija__c');
			if (value == null) {
				return '';
			}
			return asBoolean(value) ? 'Si' : 'No';
		}
	}

	public String resumenMontoCuota {
		get {
			return fmtPdfMoney(firstNonNullDecimal(new List<Decimal>{ tryDec(rlaValue('FSC_Monto_De_La_Cuota__c')), cuotaMensualVal }));
		}
	}

	public String resumenTiempoTasaFija {
		get {
			return safe(val('FSC_Tiempo_Tasa_Fija__c'));
		}
	}

	public String resumenDeudaConsolidada {
		get {
			return fmtPdfMoney(firstNonNullDecimal(new List<Decimal>{ tryDec(rlaValue('FSC_Deuda_Actual__c')) }));
		}
	}

	public String propositoFacilidad {
		get {
			return firstNonBlank(
				new List<String>{
					safe(val('FSC_Descripcion_Proposito_Facilidad__c')),
					safe(val('FSC_DescripcionPropositoFacilidad__c')),
					destinoPrestamo
				}
			);
		}
	}

	public List<GarantiaPdfRow> garantiasPdf {
		get {
			if (garantiasPdfCache == null) {
				garantiasPdfCache = new List<GarantiaPdfRow>();
				if (garantiasPdfSource != null) {
					for (SObject garantiaRecord : garantiasPdfSource) {
						garantiasPdfCache.add(buildGarantiaPdfRow(garantiaRecord, garantiasPdfCache.size() + 1));
					}
				}

				if (garantiasPdfCache.isEmpty() && (tipoGarantia != '' || descripcionGarantia != '')) {
					GarantiaPdfRow row = new GarantiaPdfRow();
					row.titulo = 'Garantia 1';
					row.clase = '';
					row.tipo = tipoGarantia;
					row.descripcion = descripcionGarantia;
					row.propositoHipotecario = '';
					row.tipoInmueble = '';
					row.ubicacion = '';
					row.valorTasado = '';
					row.fechaTasacion = '';
					row.precioVenta = '';
					row.valorInmueble = '';
					row.montoInicialAvance = '';
					row.tasador = '';
					garantiasPdfCache.add(row);
				}
			}
			return garantiasPdfCache;
		}
	}

	public Integer garantiasPdfSize {
		get {
			return garantiasPdf == null ? 0 : garantiasPdf.size();
		}
	}

	public class GarantiaPdfRow {
		public String titulo { get; set; }
		public String clase { get; set; }
		public String tipo { get; set; }
		public String descripcion { get; set; }
		public String propositoHipotecario { get; set; }
		public String tipoInmueble { get; set; }
		public String ubicacion { get; set; }
		public String valorTasado { get; set; }
		public String fechaTasacion { get; set; }
		public String precioVenta { get; set; }
		public String valorInmueble { get; set; }
		public String montoInicialAvance { get; set; }
		public String tasador { get; set; }
	}

	public class ReferenciaRow {
		public String parentesco { get; set; }
		public String nombres { get; set; }
		public String apellidos { get; set; }
	}

	public class FacilidadRow {
		public String numero { get; set; }
		public String tipo { get; set; }
		public String plazo { get; set; }
		public String tasa { get; set; }
		public String cuota { get; set; }
		public String monto { get; set; }
	}

	public class GarantiaRow {
		public String descripcion { get; set; }
		public String valor { get; set; }
		public String porcentaje { get; set; }
	}

	public List<ReferenciaRow> referencias {
		get {
			if (referenciasCache == null) {
				referenciasCache = queryReferencias(rlaId);
			}
			return referenciasCache;
		}
	}
	public Integer referenciasSize {
		get {
			return referencias == null ? 0 : referencias.size();
		}
	}

	public List<FacilidadRow> facilidades {
		get {
			if (facilidadesCache == null) {
				facilidadesCache = new List<FacilidadRow>{ buildCurrentFacilidadRow() };
			}
			return facilidadesCache;
		}
	}

	public List<GarantiaRow> garantias {
		get {
			if (garantiasCache == null) {
				garantiasCache = queryGarantias(rlaId);
				if (garantiasCache.isEmpty() && (tipoGarantia != '' || descripcionGarantia != '' || garantiaValorVal != null)) {
					GarantiaRow row = new GarantiaRow();
					row.descripcion = firstNonBlank(new List<String>{ descripcionGarantia, tipoGarantia });
					row.valor = garantiaValorFmt;
					row.porcentaje = '';
					garantiasCache.add(row);
				}
			}
			return garantiasCache;
		}
	}

	public Integer garantiasSize {
		get {
			return garantias == null ? 0 : garantias.size();
		}
	}
	public List<Integer> emptyReferenciaRows {
		get {
			return referenciasSize == 0 ? new List<Integer>() : buildEmptyRows(referenciasSize, 3);
		}
	}
	public List<Integer> emptyFacilidadRows {
		get {
			return buildEmptyRows(facilidades == null ? 0 : facilidades.size(), 4);
		}
	}
	public List<Integer> emptyGarantiaRows {
		get {
			return buildEmptyRows(garantiasSize, 3);
		}
	}

	public String textoAutorizacion {
		get {
			return 'Por la presente AUTORIZO al Banco Vimenca a consultar las bases de datos de los buros de informacion crediticia, ' +
				'con la finalidad de verificar toda la informacion suministrada con respecto a esta solicitud.<br/>Asimismo, en caso de ' +
				'que la presente solicitud sea acogida por el Banco, AUTORIZO tambien al Banco a suministrar a cualquier Centro de ' +
				'Informacion Crediticia la informacion patrimonial necesaria, a los fines de evaluacion de credito por parte de ' +
				'otras instituciones suscriptoras de dichos centros de informacion, reconociendo y garantizando que la revelacion ' +
				'de dichas informaciones por parte de EL BANCO y/o por los centros de informacion crediticia y/o sus respectivos ' +
				'empleados, funcionarios y accionistas, no conllevara violacion de la Ley No. 172-13 de Proteccion de Datos de ' +
				'Caracter Personal, ni del secreto profesional, a los efectos del Articulo 337 del Codigo Penal, ni generara ' +
				'responsabilidad bajo los articulos 1382 y siguientes del Codigo Civil Dominicano, ni bajo ningun otro texto legal ' +
				'vigente, al tiempo de renunciar expresa y formalmente al ejercicio de cualquier accion o demanda por dicha causa o ' +
				'motivo, en virtud de las disposiciones del articulo 1120 del Codigo Civil.';
		}
	}

	private String val(String api) {
		if (rla == null || String.isBlank(api)) {
			return '';
		}
		Object value = rlaValue(api);
		return value == null ? '' : String.valueOf(value);
	}

	private Object rlaValue(String api) {
		if (rla == null || String.isBlank(api) || !rlaFieldMap.containsKey(api)) {
			return null;
		}
		return rla.get(api);
	}

	private String accVal(String api) {
		if (acc == null || String.isBlank(api) || !accFieldMap.containsKey(api)) {
			return '';
		}
		Object value = acc.get(api);
		return value == null ? '' : String.valueOf(value);
	}

	private String createdByVal(String api) {
		if (rla == null || String.isBlank(api) || !userFieldMap.containsKey(api)) {
			return '';
		}

		SObject createdBy = rla.getSObject('CreatedBy');
		if (createdBy == null) {
			return '';
		}

		try {
			Object value = createdBy.get(api);
			return value == null ? '' : String.valueOf(value);
		} catch (SObjectException e) {
			return '';
		}
	}

	private String creditoProducto {
		get {
			String developerName = recordTypeDeveloperName;
			if (developerName == 'FSC_Solicitud_Credito_Consumo') {
				return 'Consumo';
			}
			if (developerName == 'FSC_Solicitud_Credito_Hipotecario') {
				return 'Hipotecario';
			}
			if (developerName == 'FSC_Solicitud_Credito_Vehiculo') {
				return 'Vehiculo';
			}
			if (developerName == 'FSC_Solicitud_Credito_PYME') {
				return 'PyMe';
			}

			String recordTypeName = recordTypeLabel;
			if (recordTypeName.toLowerCase().contains('consumo')) {
				return 'Consumo';
			}
			if (recordTypeName.toLowerCase().contains('hipotecario')) {
				return 'Hipotecario';
			}
			if (
				recordTypeName.toLowerCase().contains('vehiculo') ||
				recordTypeName.toLowerCase().contains('vehículo') ||
				recordTypeName.toLowerCase().contains('vehicular')
			) {
				return 'Vehiculo';
			}
			if (recordTypeName.toLowerCase().contains('pyme')) {
				return 'PyMe';
			}

			return '';
		}
	}

	private String creditoProductoMayuscula {
		get {
			String producto = creditoProducto;
			return producto == '' ? '' : producto.toUpperCase();
		}
	}

	private String recordTypeDeveloperName {
		get {
			SObject recordType = rla == null ? null : rla.getSObject('RecordType');
			return recordType == null ? '' : safe(String.valueOf(recordType.get('DeveloperName')));
		}
	}

	private String recordTypeLabel {
		get {
			SObject recordType = rla == null ? null : rla.getSObject('RecordType');
			return recordType == null ? '' : safe(String.valueOf(recordType.get('Name')));
		}
	}

	private String applicantVal(SObject applicant, String api) {
		if (applicant == null || String.isBlank(api)) {
			return '';
		}
		Object value = applicant.get(api);
		return value == null ? '' : String.valueOf(value);
	}

	private static Boolean hasApplicantPdfData(SObject applicant) {
		if (applicant == null) {
			return false;
		}

		List<String> applicantFields = new List<String>{
			'FSC_TipoSolicitante__c',
			'FSC_TipoIdentificacion__c',
			'FSC_NumIdentificacion__c',
			'FSC_Nombre__c',
			'FSC_PrimerApellido__c',
			'FSC_SegundoApellido__c',
			'FSC_FechaNacimiento__c',
			'FSC_Nacionalidad__c',
			'FSC_EstadoCivil__c',
			'FSC_NumeroDependientes__c',
			'FSC_ClasificacionSIB__c',
			'FSC_TipoVivienda__c'
		};

		for (String api : applicantFields) {
			if (!String.isBlank(sobjectVal(applicant, api))) {
				return true;
			}
		}
		return false;
	}

	private static String sobjectVal(SObject record, String api) {
		if (record == null || String.isBlank(api)) {
			return '';
		}

		try {
			Object value = record.get(api);
			return value == null ? '' : String.valueOf(value);
		} catch (SObjectException e) {
			return '';
		}
	}

	private static GarantiaPdfRow buildGarantiaPdfRow(SObject record, Integer sequence) {
		GarantiaPdfRow item = new GarantiaPdfRow();
		item.titulo = 'Garantia ' + String.valueOf(sequence);
		item.clase = sobjectVal(record, 'FSC_Clase_de_Garantia__c');
		item.tipo = sobjectVal(record, 'FSC_Tipo_de_Garantia__c');
		item.descripcion = sobjectVal(record, 'FSC_Descripcion_de_la_Garantia__c');
		item.propositoHipotecario = sobjectVal(record, 'FSC_Proposito_Garantia_Hipotecario__c');
		item.tipoInmueble = sobjectVal(record, 'FSC_Tipo_de_Inmueble__c');
		item.ubicacion = sobjectVal(record, 'FSC_Ubicacion__c');
		item.valorTasado = fmtPdfMoney(tryDec(record == null ? null : record.get('FSC_Valor_Tasado__c')));
		item.fechaTasacion = fmtDate(tryDate(record == null ? null : record.get('FSC_Fecha_Tasacion__c')));
		item.precioVenta = fmtPdfMoney(tryDec(record == null ? null : record.get('FSC_Precio_de_Venta__c')));
		item.valorInmueble = fmtPdfMoney(tryDec(record == null ? null : record.get('FSC_Valor_Inmueble__c')));
		item.montoInicialAvance = fmtPdfMoney(tryDec(record == null ? null : record.get('FSC_Monto_Inicial_Avance_Pagado__c')));
		item.tasador = sobjectVal(record, 'FSC_Tasado_Por__c');
		return item;
	}

	private static String fmtPdfMoney(Decimal amount) {
		return fmtMoney(amount);
	}

	private static String fmtDateTime(DateTime value) {
		if (value == null) {
			return '';
		}
		return value.format('dd/MM/yyyy hh:mm a');
	}

	private static Decimal firstNonNullDecimal(List<Decimal> values) {
		for (Decimal value : values) {
			if (value != null) {
				return value;
			}
		}
		return null;
	}

	private static Date firstNonNullDate(List<Date> values) {
		for (Date value : values) {
			if (value != null) {
				return value;
			}
		}
		return null;
	}

	private static List<String> splitLastNames(String lastNames) {
		List<String> result = new List<String>{ '', '' };
		if (String.isBlank(lastNames)) {
			return result;
		}

		List<String> parts = lastNames.trim().split('\\s+');
		result[0] = parts[0];
		if (parts.size() > 1) {
			List<String> remaining = new List<String>();
			for (Integer i = 1; i < parts.size(); i++) {
				remaining.add(parts[i]);
			}
			result[1] = String.join(remaining, ' ');
		}
		return result;
	}

	private static List<String> splitFullName(String fullName) {
		List<String> result = new List<String>{ '', '' };
		if (String.isBlank(fullName)) {
			return result;
		}

		List<String> parts = fullName.trim().split('\\s+');
		if (parts.size() == 1) {
			result[0] = parts[0];
			return result;
		}

		Integer surnameCount = parts.size() >= 3 ? 2 : 1;
		List<String> names = new List<String>();
		List<String> lastNames = new List<String>();
		for (Integer i = 0; i < parts.size(); i++) {
			if (i < parts.size() - surnameCount) {
				names.add(parts[i]);
			} else {
				lastNames.add(parts[i]);
			}
		}

		result[0] = String.join(names, ' ');
		result[1] = String.join(lastNames, ' ');
		return result;
	}

	private String formatEmploymentTenure() {
		if (solicitanteEmployment == null) {
			return '';
		}

		Integer years = tryInteger(solicitanteEmployment.get('CurrentJobYearCount'));
		Integer months = tryInteger(solicitanteEmployment.get('CurrentJobAdditionalMonthCount'));
		List<String> parts = new List<String>();

		if (years != null && years > 0) {
			parts.add(String.valueOf(years) + (years == 1 ? ' ano' : ' anos'));
		}
		if (months != null && months > 0) {
			parts.add(String.valueOf(months) + (months == 1 ? ' mes' : ' meses'));
		}

		return String.join(parts, ' ');
	}

	private static String picklistLabel(String objectApiName, String fieldApiName, String value) {
		if (String.isBlank(objectApiName) || String.isBlank(fieldApiName) || String.isBlank(value)) {
			return '';
		}

		Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
		if (!globalDescribe.containsKey(objectApiName)) {
			return value;
		}

		Map<String, Schema.SObjectField> fieldMap = globalDescribe.get(objectApiName).getDescribe().fields.getMap();
		if (!fieldMap.containsKey(fieldApiName)) {
			return value;
		}

		for (Schema.PicklistEntry picklistValue : fieldMap.get(fieldApiName).getDescribe().getPicklistValues()) {
			if (picklistValue.getValue() == value) {
				return picklistValue.getLabel();
			}
		}

		return value;
	}

	private FacilidadRow buildCurrentFacilidadRow() {
		FacilidadRow current = new FacilidadRow();
		current.numero = firstNonBlank(new List<String>{ safe(val('FSC_Numero__c')), numeroSolicitud });
		current.tipo = firstNonBlank(new List<String>{ safe(val('FSC_Tipo_de_Facilidad__c')), tipoCredito });
		current.plazo = firstNonBlank(new List<String>{ safe(val('FSC_Plazo_meses__c')), plazoMeses });

		Decimal tasa = firstNonNullDecimal(new List<Decimal>{ tryDec(rlaValue('FSC_Tasa__c')), tasaInteresVal });
		current.tasa = tasa == null ? '' : String.valueOf(tasa.setScale(2)) + '%';

		current.cuota = fmtMoney(firstNonNullDecimal(new List<Decimal>{ tryDec(rlaValue('FSC_Compromiso_Mensual__c')), cuotaMensualVal }));

		current.monto = fmtMoney(
			firstNonNullDecimal(
				new List<Decimal>{ tryDec(rlaValue('FSC_Limite_Autorizado__c')), tryDec(rlaValue('FSC_Aumento_Solicitado__c')), montoSolicitadoVal }
			)
		);
		return current;
	}

	private List<String> queryContactPointAddresses() {
		List<String> out = new List<String>();
		for (SObject row : queryContactPoints('ContactPointAddress', new List<String>{ 'Street', 'City', 'State', 'PostalCode', 'Country' })) {
			addIfNotBlank(
				out,
				joinNonBlank(
					new List<String>{
						sobjectVal(row, 'Street'),
						sobjectVal(row, 'City'),
						sobjectVal(row, 'State'),
						sobjectVal(row, 'PostalCode'),
						sobjectVal(row, 'Country')
					},
					', '
				)
			);
		}
		return out;
	}

	private List<String> queryContactPointPhones() {
		List<String> out = new List<String>();
		for (
			SObject row : queryContactPoints(
				'ContactPointPhone',
				new List<String>{ 'TelephoneNumber', 'FormattedNationalPhoneNumber', 'FormattedInternationalPhoneNumber' }
			)
		) {
			addIfNotBlank(
				out,
				firstNonBlank(
					new List<String>{
						sobjectVal(row, 'TelephoneNumber'),
						sobjectVal(row, 'FormattedNationalPhoneNumber'),
						sobjectVal(row, 'FormattedInternationalPhoneNumber')
					}
				)
			);
		}
		return out;
	}

	private List<String> queryContactPointEmails() {
		List<String> out = new List<String>();
		for (SObject row : queryContactPoints('ContactPointEmail', new List<String>{ 'EmailAddress' })) {
			addIfNotBlank(out, sobjectVal(row, 'EmailAddress'));
		}
		return out;
	}

	private List<SObject> queryContactPoints(String objectApiName, List<String> valueFields) {
		Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
		if (rlaId == null || !globalDescribe.containsKey(objectApiName)) {
			return new List<SObject>();
		}

		Map<String, Schema.SObjectField> fieldMap = globalDescribe.get(objectApiName).getDescribe().fields.getMap();
		List<String> selectFields = new List<String>{ 'Id', 'CreatedDate' };
		for (String fieldName : valueFields) {
			if (fieldMap.containsKey(fieldName)) {
				selectFields.add(fieldName);
			}
		}

		Set<Id> applicantIds = contactPointLoanApplicantIds();
		if (applicantIds.isEmpty() || !fieldMap.containsKey('FSC_Solicitante__c')) {
			return new List<SObject>();
		}

		return Database.query(
			'SELECT ' +
				String.join(selectFields, ',') +
				' FROM ' +
				objectApiName +
				' WHERE FSC_Solicitante__c IN (' +
				quoteIds(applicantIds) +
				')' +
				' ORDER BY CreatedDate'
		);
	}

	private Set<Id> contactPointLoanApplicantIds() {
		Set<Id> ids = new Set<Id>();
		if (loanApplicants == null) {
			return ids;
		}

		for (SObject applicant : loanApplicants) {
			if (applicant != null && applicant.get('Id') != null && isDeudorApplicant(applicant)) {
				ids.add((Id) applicant.get('Id'));
			}
		}
		if (ids.isEmpty() && datosGeneralesLoanApplicant != null && datosGeneralesLoanApplicant.get('Id') != null) {
			ids.add((Id) datosGeneralesLoanApplicant.get('Id'));
		}
		return ids;
	}

	private SObject firstAvailableApplicant() {
		if (solicitanteLoanApplicant != null) {
			return solicitanteLoanApplicant;
		}
		if (coSolicitanteLoanApplicant != null) {
			return coSolicitanteLoanApplicant;
		}
		if (garanteLoanApplicant != null) {
			return garanteLoanApplicant;
		}
		if (loanApplicants != null && !loanApplicants.isEmpty()) {
			return loanApplicants[0];
		}
		return null;
	}

	private static Boolean isDeudorApplicant(SObject applicant) {
		if (applicant == null) {
			return false;
		}

		String tipo = safe(String.valueOf(applicant.get('FSC_TipoSolicitante__c'))).toLowerCase();
		return tipo.contains('deudor') && !tipo.contains('co');
	}

	private static String quoteIds(Set<Id> ids) {
		List<String> quoted = new List<String>();
		for (Id idValue : ids) {
			quoted.add('\'' + String.escapeSingleQuotes(String.valueOf(idValue)) + '\'');
		}
		return String.join(quoted, ',');
	}

	private static void addAllNonBlank(List<String> target, List<String> values) {
		for (String value : values) {
			addIfNotBlank(target, value);
		}
	}

	private static void addIfNotBlank(List<String> target, String value) {
		String cleanValue = safe(value);
		if (cleanValue == '' || target.contains(cleanValue)) {
			return;
		}
		target.add(cleanValue);
	}

	private static List<ReferenciaRow> queryReferencias(Id idVal) {
		List<ReferenciaRow> out = new List<ReferenciaRow>();
		if (idVal == null || !Schema.getGlobalDescribe().containsKey('FSC_Referencias__c')) {
			return out;
		}

		String soql =
			'SELECT Name, FSC_Parentesco__c ' +
			'FROM FSC_Referencias__c WHERE FSC_Residential_Loan_Application__c = \'' +
			String.escapeSingleQuotes(String.valueOf(idVal)) +
			'\'';

		for (SObject row : Database.query(soql)) {
			ReferenciaRow item = new ReferenciaRow();
			List<String> nameParts = splitFullName(safe(String.valueOf(row.get('Name'))));
			item.parentesco = safe(String.valueOf(row.get('FSC_Parentesco__c')));
			item.nombres = nameParts[0];
			item.apellidos = nameParts[1];
			out.add(item);
		}

		return out;
	}

	private static List<GarantiaRow> queryGarantias(Id idVal) {
		List<GarantiaRow> out = new List<GarantiaRow>();
		if (idVal == null) {
			return out;
		}

		for (SObject row : [
			SELECT FSC_Descripcion_de_la_Garantia__c, CashOrMarketValue, FSC_Porcentaje_Admisibilidad__c
			FROM LoanApplicationAsset
			WHERE LoanApplicationId = :idVal
		]) {
			GarantiaRow item = new GarantiaRow();
			item.descripcion = safe(String.valueOf(row.get('FSC_Descripcion_de_la_Garantia__c')));
			item.valor = fmtMoney(tryDec(row.get('CashOrMarketValue')));

			Decimal percentage = tryDec(row.get('FSC_Porcentaje_Admisibilidad__c'));
			item.porcentaje = percentage == null ? '' : String.valueOf(percentage.setScale(2)) + '%';
			out.add(item);
		}

		return out;
	}

	public static String fmtMoney(Decimal amount) {
		if (amount == null) {
			return '';
		}

		Decimal scaled = amount.setScale(2);
		String raw = String.valueOf(scaled);
		List<String> parts = raw.split('\\.');
		String intPart = parts[0];
		String decPart = parts.size() > 1 ? parts[1] : '00';

		if (decPart.length() == 1) {
			decPart += '0';
		}

		String withCommas = '';
		Integer counter = 0;
		for (Integer i = intPart.length() - 1; i >= 0; i--) {
			withCommas = intPart.substring(i, i + 1) + withCommas;
			counter++;
			if (counter == 3 && i > 0) {
				withCommas = ',' + withCommas;
				counter = 0;
			}
		}

		return 'RD$ ' + withCommas + '.' + decPart;
	}

	private static String fmtDate(Date value) {
		if (value == null) {
			return '';
		}

		return String.valueOf(value.day()).leftPad(2, '0') + '/' + String.valueOf(value.month()).leftPad(2, '0') + '/' + String.valueOf(value.year());
	}

	private static Decimal tryDec(Object value) {
		if (value == null) {
			return null;
		}
		if (value instanceof Decimal) {
			return (Decimal) value;
		}
		if (value instanceof Integer) {
			return Decimal.valueOf((Integer) value);
		}
		if (value instanceof Long) {
			return Decimal.valueOf((Long) value);
		}
		if (value instanceof Double) {
			return Decimal.valueOf(String.valueOf(value));
		}
		return Decimal.valueOf(String.valueOf(value));
	}

	private static Integer tryInteger(Object value) {
		Decimal decimalValue = tryDec(value);
		return decimalValue == null ? null : decimalValue.intValue();
	}

	private static Date tryDate(Object value) {
		if (value == null) {
			return null;
		}
		if (value instanceof Date) {
			return (Date) value;
		}
		if (value instanceof DateTime) {
			return ((DateTime) value).date();
		}

		String text = String.valueOf(value);
		if (text != null && text.length() >= 10 && text.contains('-')) {
			return Date.valueOf(text.substring(0, 10));
		}
		return null;
	}

	private static Boolean asBoolean(Object value) {
		return value != null && String.valueOf(value).toLowerCase() == 'true';
	}

	private static String firstNonBlank(List<String> values) {
		for (String value : values) {
			if (!String.isBlank(value)) {
				return value;
			}
		}
		return '';
	}

	private static String joinNonBlank(List<String> values, String separator) {
		List<String> clean = new List<String>();
		for (String value : values) {
			if (!String.isBlank(value)) {
				clean.add(value);
			}
		}
		return String.join(clean, separator);
	}

	private static String safe(String value) {
		return value == null ? '' : value;
	}

	private static String upperSafe(String value) {
		return safe(value).toUpperCase();
	}

	private static List<Integer> buildEmptyRows(Integer currentSize, Integer minimumRows) {
		List<Integer> out = new List<Integer>();
		Integer blanks = Math.max(0, minimumRows - currentSize);
		for (Integer i = 0; i < blanks; i++) {
			out.add(i);
		}
		return out;
	}
}