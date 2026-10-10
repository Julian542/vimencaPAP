public with sharing class FSC_ActaComitePDFController {
	public String actaNumero { get; private set; }
	public String actaFecha { get; private set; }
	public String horaInicio { get; private set; }
	public String horaFin { get; private set; }

	public String textoQuorum { get; private set; }
	public String textoObjetivo { get; private set; }

	public List<ActaRow> actas { get; private set; }
	public List<ActaSection> seccionesActa { get; private set; }
	public List<MiembroComite> miembrosComite { get; private set; }
	public String confirmacionRemota { get; private set; }

	public class ActaDocumentData {
		@AuraEnabled public String actaNumero { get; set; }
		@AuraEnabled public String actaFecha { get; set; }
		@AuraEnabled public String textoQuorum { get; set; }
		@AuraEnabled public String textoObjetivo { get; set; }
		@AuraEnabled public String confirmacionRemota { get; set; }
		@AuraEnabled public List<ActaSection> seccionesActa { get; set; }
		@AuraEnabled public List<MiembroComite> miembrosComite { get; set; }
	}

	public class PdfDownload {
		@AuraEnabled public String fileName { get; set; }
		@AuraEnabled public String base64Data { get; set; }
	}

	private class ActaEdits {
		public String actaNumero { get; set; }
		public String confirmacionRemota { get; set; }
		public List<ActaRowEdit> rows { get; set; }
	}

	private class ActaRowEdit {
		public Integer sectionIndex { get; set; }
		public Integer rowIndex { get; set; }
		public Map<String, String> values { get; set; }
	}

	public class ActaSection {
		@AuraEnabled public String titulo { get; set; }
		@AuraEnabled public List<ActaRow> solicitudes { get; set; }

		public ActaSection(String titulo, List<ActaRow> solicitudes) {
			this.titulo = titulo;
			this.solicitudes = solicitudes;
		}
	}

	public class ActaRow {
		@AuraEnabled public Integer numero { get; set; }
		@AuraEnabled public String sucursal { get; set; }
		@AuraEnabled public String oficial { get; set; }
		@AuraEnabled public String nombreCliente { get; set; }
		@AuraEnabled public String tipoFacilidad { get; set; }

		@AuraEnabled public String montoSolicitado { get; set; }
		@AuraEnabled public String montoAprobado { get; set; }

		@AuraEnabled public String cuotaSolicitada { get; set; }
		@AuraEnabled public String plazoSolicitado { get; set; }
		@AuraEnabled public String tasaRefSolicitada { get; set; }
		@AuraEnabled public String cuotaAprobada { get; set; }
		@AuraEnabled public String plazoAprobado { get; set; }
		@AuraEnabled public String tasaRefAprobada { get; set; }

		@AuraEnabled public String garantiaPrincipal { get; set; }
		@AuraEnabled public String valorGarantiaPrincipal { get; set; }
		@AuraEnabled public String descGarantiaPrincipal { get; set; }

		@AuraEnabled public String garantiaSecundaria { get; set; }
		@AuraEnabled public String valorGarantiaSecundaria { get; set; }
		@AuraEnabled public String descGarantiaSecundaria { get; set; }

		@AuraEnabled public String decisionComite { get; set; }
		@AuraEnabled public String condicion { get; set; }
		@AuraEnabled public String observaciones { get; set; }
	}

	public class MiembroComite {
		@AuraEnabled public String nombre { get; set; }
		@AuraEnabled public String perfil { get; set; }
		@AuraEnabled public String funcion { get; set; }
		@AuraEnabled public String modalidad { get; set; }
	}

	public FSC_ActaComitePDFController() {
		Map<String, String> p = ApexPages.currentPage().getParameters();
		Date actaDate = Date.valueOf(p.get('actaDate'));
		initializeDocument(actaDate, p);
		applyEdits(p.get('editData'));
	}

	private FSC_ActaComitePDFController(Date actaDate) {
		initializeDocument(actaDate, new Map<String, String>());
	}

	private void initializeDocument(Date actaDate, Map<String, String> p) {
		DateTime actaDateInicio = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 0, 0, 0).addHours(-4);
		DateTime actaDateFin = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 23, 59, 59).addHours(-4);

		actaNumero = nvl(p.get('actaNumero'), 'BMV-AC-C1-001/2026');
		actaFecha = (actaDate != null) ? actaDate.format() : nvl(p.get('actaFecha'), '');
		horaInicio = nvl(p.get('horaInicio'), '—');
		horaFin = nvl(p.get('horaFin'), '—');

		textoQuorum = 'El Sr. Jeffrey Omar Reyes Peña, en su función de Secretario, tomó la palabra para dar la bienvenida y validar si se cuenta con la presencia del quórum reglamentario de los Miembros, ya sea en modalidad virtual o presencial, certificando el debido cumplimiento según lo establecido en el Manual de Comités del Banco, por lo que, con la anuencia y validación del Presidente, procede a dar inicio formal a la sesión del Comité de Crédito correspondiente.';
		textoObjetivo = 'Presentar ante los Miembros de los Comités de Crédito y/o Instancias de Aprobación correspondientes, según los límites en cuanto a los montos determinados, para conocer y decidir sobre las siguientes solicitudes de créditos, garantizando una correcta aplicación de las normas y políticas de riesgo de crédito de la entidad, de acuerdo con los lineamientos establecidos.';

		confirmacionRemota = '';

		Map<Id, String> committeeDecisionByRlaId = getCommitteeDecisions(actaDateInicio, actaDateFin);
		Set<Id> rlaIdsDecidedByProcess = committeeDecisionByRlaId.keySet();

		List<ResidentialLoanApplication> apps = [
			SELECT
				Id,
				Account.Name,
				RecordType.DeveloperName,
				FSC_Monto__c,
				FSC_Cuotas__c,
				CreatedBy.Name,
				FSC_PlazoMeses__c,
				FSC_TasaInteres__c,
				FSC_TipoCredito__c,
				FSC_MontoAprobado__c,
				FSC_DecisionComite__c,
				FSC_Aprobado_con_Condiciones__c,
				FSC_SolicitudAprobadaPorComite__c,
				FSC_CondicionComite__c,
				FSC_Tipo_de_Garantia__c,
				FSC_Monto_De_La_Cuota__c,
				FSC_MontoCuotaRegular__c,
				FSC_PlazoMesesAprobado__c,
				FSC_ObservacionesComite__c,
				FSC_TasaInteresAprobada__c,
				FSC_Valor_de_la_Garantia__c,
				FSC_MontoTotalCuotaMensual__c
			FROM ResidentialLoanApplication
			WHERE
				(
					(
						FSC_FechaYHoraAprobacionComite__c >= :actaDateInicio
						AND FSC_FechaYHoraAprobacionComite__c <= :actaDateFin
					)
					OR Id IN :rlaIdsDecidedByProcess
				)
			WITH USER_MODE
			ORDER BY FSC_MontoAprobado__c DESC NULLS LAST, FSC_FechaYHoraAprobacionComite__c ASC, Id ASC
		];

		Set<Id> rlaIds = new Set<Id>();
		for (ResidentialLoanApplication app : apps) {
			rlaIds.add(app.Id);
		}

		Map<Id, List<LoanApplicationAsset>> rlaIdToAssets = new Map<Id, List<LoanApplicationAsset>>();
		Set<Id> rlaIdsWithGuarantee = new Set<Id>();
		if (!rlaIds.isEmpty()) {
			List<LoanApplicationAsset> laas = [
				SELECT Id, AssetType, CashOrMarketValue, LoanApplicationId, FSC_Descripcion_de_la_Garantia__c
				FROM LoanApplicationAsset
				WHERE LoanApplicationId IN :rlaIds
				WITH USER_MODE
				ORDER BY CreatedDate ASC, Id ASC
			];

			for (LoanApplicationAsset laa : laas) {
				rlaIdsWithGuarantee.add(laa.LoanApplicationId);
				if (!rlaIdToAssets.containsKey(laa.LoanApplicationId)) {
					rlaIdToAssets.put(laa.LoanApplicationId, new List<LoanApplicationAsset>());
				}
				rlaIdToAssets.get(laa.LoanApplicationId).add(laa);
			}

			for (FSC_Garantia__c guarantee : [
				SELECT Id, FSC_Residential_Loan_Application__c
				FROM FSC_Garantia__c
				WHERE FSC_Residential_Loan_Application__c IN :rlaIds
				WITH USER_MODE
			]) {
				rlaIdsWithGuarantee.add(guarantee.FSC_Residential_Loan_Application__c);
			}
		}

		Map<String, List<ActaRow>> rowsBySection = new Map<String, List<ActaRow>>{
			'COMERCIAL' => new List<ActaRow>(),
			'CONSUMO' => new List<ActaRow>(),
			'VEHICULAR' => new List<ActaRow>(),
			'HIPOTECARIO' => new List<ActaRow>()
		};

		for (ResidentialLoanApplication a : apps) {

			ActaRow r = new ActaRow();
			Boolean isPyme = isPymeCredit(a.FSC_TipoCredito__c, a.RecordType?.DeveloperName);
			r.sucursal = 'Oficina Principal';
			r.oficial = (a.CreatedBy != null) ? a.CreatedBy.Name : '';
			r.nombreCliente = (a.Account != null) ? a.Account.Name : '';
			r.tipoFacilidad = resolveFacilityType(a.FSC_TipoCredito__c, a.RecordType?.DeveloperName, rlaIdsWithGuarantee.contains(a.Id));

			r.montoSolicitado = fmtMoney(a.FSC_Monto__c);
			r.montoAprobado = fmtMoney(a.FSC_MontoAprobado__c);

			r.cuotaAprobada = fmtInstallment(a.FSC_MontoAprobado__c, a.FSC_PlazoMesesAprobado__c);
			// Para PyME, ambas cuotas deben mostrar el valor aprobado.
			r.cuotaSolicitada = isPyme
				? r.cuotaAprobada
				: fmtMoney(a.FSC_Monto_De_La_Cuota__c);
			r.plazoSolicitado = (a.FSC_PlazoMesesAprobado__c != null) ? String.valueOf(a.FSC_PlazoMesesAprobado__c) : '';
			r.tasaRefSolicitada = fmtRate(a.FSC_TasaInteres__c);

			r.plazoAprobado = (a.FSC_PlazoMesesAprobado__c != null) ? String.valueOf(a.FSC_PlazoMesesAprobado__c) : '';
			r.tasaRefAprobada = fmtRate(a.FSC_TasaInteresAprobada__c);

			List<LoanApplicationAsset> assetsForRLA = rlaIdToAssets.get(a.Id);

			LoanApplicationAsset gar1 = (assetsForRLA != null && assetsForRLA.size() > 0) ? assetsForRLA[0] : null;
			LoanApplicationAsset gar2 = (assetsForRLA != null && assetsForRLA.size() > 1) ? assetsForRLA[1] : null;

			r.garantiaPrincipal = isPyme
				? getPicklistLabel(ResidentialLoanApplication.FSC_Tipo_de_Garantia__c, a.FSC_Tipo_de_Garantia__c)
				: ((gar1 != null && gar1.AssetType != null) ? String.valueOf(gar1.AssetType) : '');
			r.valorGarantiaPrincipal = (gar1 != null) ? fmtMoney(gar1.CashOrMarketValue) : '';
			r.descGarantiaPrincipal = (gar1 != null)
				? getPicklistLabel(LoanApplicationAsset.FSC_Descripcion_de_la_Garantia__c, gar1.FSC_Descripcion_de_la_Garantia__c)
				: '';

			r.garantiaSecundaria = (gar2 != null && gar2.AssetType != null) ? String.valueOf(gar2.AssetType) : '';
			r.valorGarantiaSecundaria = (gar2 != null) ? fmtMoney(gar2.CashOrMarketValue) : '';
			r.descGarantiaSecundaria = (gar2 != null)
				? getPicklistLabel(LoanApplicationAsset.FSC_Descripcion_de_la_Garantia__c, gar2.FSC_Descripcion_de_la_Garantia__c)
				: '';

			r.decisionComite = resolveCommitteeDecision(a, committeeDecisionByRlaId.get(a.Id));
			r.condicion = (a.FSC_CondicionComite__c != null) ? String.valueOf(a.FSC_CondicionComite__c) : '';
			r.observaciones = (a.FSC_ObservacionesComite__c != null) ? String.valueOf(a.FSC_ObservacionesComite__c) : '';

			String sectionKey = resolveSectionKey(a.FSC_TipoCredito__c, a.RecordType?.DeveloperName);
			rowsBySection.get(sectionKey).add(r);
		}

		actas = new List<ActaRow>();
		seccionesActa = new List<ActaSection>();
		Map<String, String> sectionTitles = new Map<String, String>{
			'COMERCIAL' => 'PRESTAMOS COMERCIALES',
			'CONSUMO' => 'PRESTAMOS DE CONSUMO',
			'VEHICULAR' => 'PRESTAMOS VEHICULARES',
			'HIPOTECARIO' => 'PRESTAMOS HIPOTECARIOS'
		};
		List<String> sectionOrder = new List<String>{ 'COMERCIAL', 'CONSUMO', 'VEHICULAR', 'HIPOTECARIO' };
		Integer rowNumber = 1;
		for (String sectionKey : sectionOrder) {
			List<ActaRow> sectionRows = rowsBySection.get(sectionKey);
			if (sectionRows.isEmpty()) {
				continue;
			}
			for (ActaRow row : sectionRows) {
				row.numero = rowNumber++;
			}
			actas.addAll(sectionRows);
			seccionesActa.add(new ActaSection(sectionTitles.get(sectionKey), sectionRows));
		}

		miembrosComite = new List<MiembroComite>();
		Map<String, FSC_MiembrosComiteParaActas__mdt> memberConfigByName = FSC_MiembrosComiteParaActas__mdt.getAll();
		List<String> memberConfigNames = new List<String>(memberConfigByName.keySet());
		memberConfigNames.sort();
		for (String memberConfigName : memberConfigNames) {
			FSC_MiembrosComiteParaActas__mdt variableMCPA = memberConfigByName.get(memberConfigName);
			MiembroComite mc = new MiembroComite();
			mc.nombre = variableMCPA.FSC_Nombre__c;
			mc.perfil = variableMCPA.FSC_Perfil__c;
			mc.funcion = variableMCPA.FSC_Funcion__c;
			mc.modalidad = variableMCPA.FSC_Modalidad__c;
			miembrosComite.add(mc);
		}
	}

	@AuraEnabled(cacheable=true)
	public static ActaDocumentData getActaDocumentData(Date actaDate) {
		if (actaDate == null) {
			throw new AuraHandledException('La fecha del acta es requerida.');
		}

		FSC_ActaComitePDFController controller = new FSC_ActaComitePDFController(actaDate);
		ActaDocumentData data = new ActaDocumentData();
		data.actaNumero = controller.actaNumero;
		data.actaFecha = controller.actaFecha;
		data.textoQuorum = controller.textoQuorum;
		data.textoObjetivo = controller.textoObjetivo;
		data.confirmacionRemota = controller.confirmacionRemota;
		data.seccionesActa = controller.seccionesActa;
		data.miembrosComite = controller.miembrosComite;
		return data;
	}

	@AuraEnabled
	public static PdfDownload generateEditedPdf(Date actaDate, String changesJson) {
		if (actaDate == null) {
			throw new AuraHandledException('La fecha del acta es requerida.');
		}
		if (String.isBlank(changesJson) || changesJson.length() > 100000) {
			throw new AuraHandledException('Los cambios del documento no son validos.');
		}

		try {
			// La deserializacion valida la estructura antes de enviarla a la pagina PDF.
			ActaEdits edits = (ActaEdits) JSON.deserialize(changesJson, ActaEdits.class);
			String validatedChanges = JSON.serialize(edits);

			PageReference pageReference = Page.FSC_ActaComitePDF;
			pageReference.getParameters().put('actaDate', String.valueOf(actaDate));
			pageReference.getParameters().put('editData', validatedChanges);

			PdfDownload download = new PdfDownload();
			download.fileName = buildFileName(actaDate);
			download.base64Data = EncodingUtil.base64Encode(pageReference.getContentAsPDF());
			return download;
		} catch (Exception e) {
			throw new AuraHandledException('No fue posible generar el documento editado: ' + e.getMessage());
		}
	}

	private void applyEdits(String changesJson) {
		if (String.isBlank(changesJson)) {
			return;
		}

		ActaEdits edits = (ActaEdits) JSON.deserialize(changesJson, ActaEdits.class);
		if (edits == null) {
			return;
		}
		if (edits.actaNumero != null) {
			actaNumero = edits.actaNumero;
		}
		if (edits.confirmacionRemota != null) {
			confirmacionRemota = edits.confirmacionRemota;
		}
		if (edits.rows == null) {
			return;
		}

		for (ActaRowEdit edit : edits.rows) {
			if (edit == null || edit.sectionIndex == null || edit.rowIndex == null || edit.values == null ||
				edit.sectionIndex < 0 || edit.sectionIndex >= seccionesActa.size()) {
				continue;
			}
			List<ActaRow> sectionRows = seccionesActa[edit.sectionIndex].solicitudes;
			if (edit.rowIndex < 0 || edit.rowIndex >= sectionRows.size()) {
				continue;
			}
			applyRowValues(sectionRows[edit.rowIndex], edit.values);
		}
	}

	private static void applyRowValues(ActaRow row, Map<String, String> values) {
		for (String fieldName : values.keySet()) {
			String value = values.get(fieldName);
			switch on fieldName {
				when 'numero' {
					row.numero = String.isBlank(value) ? null : Integer.valueOf(value);
				}
				when 'sucursal' { row.sucursal = value; }
				when 'oficial' { row.oficial = value; }
				when 'nombreCliente' { row.nombreCliente = value; }
				when 'tipoFacilidad' { row.tipoFacilidad = value; }
				when 'montoSolicitado' { row.montoSolicitado = value; }
				when 'montoAprobado' { row.montoAprobado = value; }
				when 'cuotaSolicitada' { row.cuotaSolicitada = value; }
				when 'plazoSolicitado' { row.plazoSolicitado = value; }
				when 'tasaRefSolicitada' { row.tasaRefSolicitada = value; }
				when 'cuotaAprobada' { row.cuotaAprobada = value; }
				when 'plazoAprobado' { row.plazoAprobado = value; }
				when 'tasaRefAprobada' { row.tasaRefAprobada = value; }
				when 'garantiaPrincipal' { row.garantiaPrincipal = value; }
				when 'valorGarantiaPrincipal' { row.valorGarantiaPrincipal = value; }
				when 'descGarantiaPrincipal' { row.descGarantiaPrincipal = value; }
				when 'garantiaSecundaria' { row.garantiaSecundaria = value; }
				when 'valorGarantiaSecundaria' { row.valorGarantiaSecundaria = value; }
				when 'descGarantiaSecundaria' { row.descGarantiaSecundaria = value; }
				when 'decisionComite' { row.decisionComite = value; }
				when 'condicion' { row.condicion = value; }
				when 'observaciones' { row.observaciones = value; }
			}
		}
	}

	private static String buildFileName(Date actaDate) {
		String isoDate = actaDate.year() + '-' + String.valueOf(actaDate.month()).leftPad(2, '0') + '-' +
			String.valueOf(actaDate.day()).leftPad(2, '0');
		return 'Acta_Comite_Credito_Editada_' + isoDate + '.pdf';
	}

	private static String nvl(String a, String b) {
		return String.isBlank(a) ? b : a;
	}

	private static String fmtMoney(Decimal d) {
		if (d == null)
			return '';
		return '$ ' + d.setScale(2).format();
	}

	private static String fmtRate(Decimal d) {
		if (d == null)
			return '';
		return d.setScale(2).format() + '%';
	}

	private static String getPicklistLabel(Schema.SObjectField field, String value) {
		if (String.isBlank(value)) {
			return '';
		}
		for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
			if (entry.getValue() == value) {
				return entry.getLabel();
			}
		}
		return value;
	}

	private static String fmtInstallment(Decimal amount, Decimal termMonths) {
		if (amount == null || termMonths == null || termMonths <= 0) {
			return '';
		}
		return fmtMoney(amount / termMonths);
	}

	private static Map<Id, String> getCommitteeDecisions(DateTime startDate, DateTime endDate) {
		Map<Id, String> decisionByRlaId = new Map<Id, String>();
		for (ProcessInstance process : [
			SELECT TargetObjectId, Status
			FROM ProcessInstance
			WHERE ProcessDefinition.DeveloperName = 'FSC_ComiteDeCredito'
				AND Status IN ('Approved', 'Rejected')
				AND CompletedDate >= :startDate
				AND CompletedDate <= :endDate
			ORDER BY CompletedDate ASC, Id ASC
		]) {
			decisionByRlaId.put(process.TargetObjectId, process.Status);
		}
		return decisionByRlaId;
	}

	private static String resolveCommitteeDecision(ResidentialLoanApplication application, String processStatus) {
		if (processStatus == 'Rejected') {
			return 'Rechazada';
		}
		if (processStatus == 'Approved') {
			return application.FSC_Aprobado_con_Condiciones__c == true ? 'Aprobada con condición' : 'Aprobada';
		}
		if (!String.isBlank(application.FSC_DecisionComite__c)) {
			return application.FSC_DecisionComite__c;
		}
		if (application.FSC_SolicitudAprobadaPorComite__c == true) {
			return application.FSC_Aprobado_con_Condiciones__c == true ? 'Aprobada con condición' : 'Aprobada';
		}
		return '';
	}

	private static String resolveSectionKey(String creditType, String recordTypeDeveloperName) {
		String source = nvl(creditType, '') + ' ' + nvl(recordTypeDeveloperName, '');
		String normalizedCreditType = source.trim().toUpperCase();

		if (normalizedCreditType.contains('HIPOTEC')) {
			return 'HIPOTECARIO';
		}
		if (normalizedCreditType.contains('VEHIC')) {
			return 'VEHICULAR';
		}
		if (normalizedCreditType.contains('CONSUMO')) {
			return 'CONSUMO';
		}
		return 'COMERCIAL';
	}

	private static Boolean isPymeCredit(String creditType, String recordTypeDeveloperName) {
		String source = nvl(creditType, '') + ' ' + nvl(recordTypeDeveloperName, '');
		String normalizedCreditType = source.trim().toUpperCase();
		return normalizedCreditType.contains('MIPYME') || normalizedCreditType.contains('PYME');
	}

	private static String resolveFacilityType(String creditType, String recordTypeDeveloperName, Boolean hasGuarantee) {
		String creditTypeSource = !String.isBlank(creditType) ? creditType : recordTypeDeveloperName;
		String normalizedCreditType = String.isBlank(creditTypeSource) ? '' : creditTypeSource.trim().toUpperCase();
		String facilityType;

		if (normalizedCreditType.contains('HIPOTEC')) {
			facilityType = 'Crédito Hipotecario';
		} else if (normalizedCreditType.contains('VEHIC')) {
			facilityType = 'Crédito Vehicular';
		} else if (normalizedCreditType.contains('MIPYME') || normalizedCreditType.contains('PYME')) {
			facilityType = 'Crédito PyMe';
		} else if (normalizedCreditType.contains('CONSUMO')) {
			facilityType = 'Crédito Consumo';
		} else {
			facilityType = String.isBlank(creditTypeSource) ? 'Crédito' : creditTypeSource.trim();
		}

		return facilityType + (hasGuarantee == true ? ' con garantía' : ' sin garantía');
	}
}