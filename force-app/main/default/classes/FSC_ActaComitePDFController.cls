public with sharing class FSC_ActaComitePDFController {

    public String actaNumero { get; private set; }
    public String actaFecha { get; private set; }
    public String horaInicio { get; private set; }
    public String horaFin { get; private set; }

    public String textoQuorum { get; private set; }
    public String textoObjetivo { get; private set; }

    public List<ActaRow> actas { get; private set; }
    public List<MiembroComite> miembrosComite { get; private set; }

    public class ActaRow {
        public Integer numero { get; set; }
        public String sucursal { get; set; }
        public String oficial { get; set; }
        public String nombreCliente { get; set; }
        public String tipoFacilidad { get; set; }

        public String montoSolicitado { get; set; }
        public String montoAprobado { get; set; }

        public String cuotaSolicitada { get; set; }
        public String plazoSolicitado { get; set; }
        public String tasaRefSolicitada { get; set; }
        public String cuotaAprobada { get; set; }
        public String plazoAprobado { get; set; }
        public String tasaRefAprobada { get; set; }

        public String garantiaPrincipal { get; set; }
        public String valorGarantiaPrincipal { get; set; }
        public String descGarantiaPrincipal { get; set; }

        public String garantiaSecundaria { get; set; }
        public String valorGarantiaSecundaria { get; set; }
        public String descGarantiaSecundaria { get; set; }

        public String decisionComite { get; set; }
        public String condicion { get; set; }
        public String observaciones { get; set; }
    }

    public class MiembroComite {
        public String nombre { get; set; }
        public String perfil { get; set; }
        public String funcion { get; set; }
        public String modalidad { get; set; }
    }

    public FSC_ActaComitePDFController() {
        Map<String, String> p = ApexPages.currentPage().getParameters();

        Date actaDate = Date.valueOf(p.get('actaDate'));
        DateTime actaDateInicio = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 0, 0, 0).addHours(-4);
        DateTime actaDateFin = DateTime.newInstance(actaDate.year(), actaDate.month(), actaDate.day(), 23, 59, 59).addHours(-4);

        actaNumero = nvl(p.get('actaNumero'), 'BMV-AC-C1-001/2026');
        actaFecha  = (actaDate != null) ? actaDate.format() : nvl(p.get('actaFecha'), '');
        horaInicio = nvl(p.get('horaInicio'), '—');
        horaFin    = nvl(p.get('horaFin'), '—');

        textoQuorum =
            'El Sr. Jeffrey Omar Reyes Peña, en su función de Secretario, tomó la palabra para dar la bienvenida y validar si se cuenta con la presencia del quórum reglamentario de los Miembros, ya sea en modalidad virtual o presencial, certificando el debido cumplimiento según lo establecido en el Manual de Comités del Banco, por lo que, con la anuencia y validación del Presidente, procede a dar inicio formal a la sesión del Comité de Crédito correspondiente.';
        textoObjetivo =
            'Presentar ante los Miembros de los Comités de Crédito y/o Instancias de Aprobación correspondientes, según los límites en cuanto a los montos determinados, para conocer y decidir sobre las siguientes solicitudes de créditos, garantizando una correcta aplicación de las normas y políticas de riesgo de crédito de la entidad, de acuerdo con los lineamientos establecidos.';

        List<ResidentialLoanApplication> apps = [
            SELECT
                Id,
                Account.Name,
                FSC_Monto__c,
                FSC_Cuotas__c,
                CreatedBy.Name,
                FSC_PlazoMeses__c,
                FSC_TasaInteres__c,
                FSC_TipoCredito__c,
                FSC_MontoAprobado__c,
                FSC_DecisionComite__c,
                FSC_Aplica_Garantia__c,
                FSC_CondicionComite__c,
                FSC_Tipo_de_Garantia__c,
                FSC_MontoCuotaRegular__c,
                FSC_PlazoMesesAprobado__c,
                FSC_ObservacionesComite__c,
                FSC_TasaInteresAprobada__c,
                FSC_Valor_de_la_Garantia__c,
                FSC_MontoTotalCuotaMensual__c
            FROM ResidentialLoanApplication
            WHERE
                FSC_SolicitudAprobadaPorComite__c = true
                AND FSC_FechaYHoraAprobacionComite__c >= :actaDateInicio
                AND FSC_FechaYHoraAprobacionComite__c <= :actaDateFin
            ORDER BY FSC_FechaYHoraAprobacionComite__c ASC
        ];

        List<Id> listRLAIds = new List<Id>();
        for (ResidentialLoanApplication app : apps) {
            listRLAIds.add(app.Id);
        }

        Map<Id, List<LoanApplicationAsset>> rlaIdToAssets = new Map<Id, List<LoanApplicationAsset>>();
        if (!listRLAIds.isEmpty()) {
            List<LoanApplicationAsset> laas = [
                SELECT
                    Id,
                    AssetType,
                    CashOrMarketValue,
                    LoanApplicationId,
                    FSC_Descripcion_de_la_Garantia__c
                FROM LoanApplicationAsset
                WHERE LoanApplicationId IN :listRLAIds
            ];

            for (LoanApplicationAsset laa : laas) {
                if (!rlaIdToAssets.containsKey(laa.LoanApplicationId)) {
                    rlaIdToAssets.put(laa.LoanApplicationId, new List<LoanApplicationAsset>());
                }
                rlaIdToAssets.get(laa.LoanApplicationId).add(laa);
            }
        }

        actas = new List<ActaRow>();
        for (Integer i = 0; i < apps.size(); i++) {
            ResidentialLoanApplication a = apps[i];

            ActaRow r = new ActaRow();
            r.numero = i + 1;
            r.sucursal = 'Oficina Principal';
            r.oficial = (a.CreatedBy != null) ? a.CreatedBy.Name : '';
            r.nombreCliente = (a.Account != null) ? a.Account.Name : '';
            r.tipoFacilidad = (a.FSC_Aplica_Garantia__c)
                ? 'Crédito pyme con contrato de garantía'
                : 'Crédito pyme sin garantía';

            r.montoSolicitado = fmtMoney(a.FSC_Monto__c);
            r.montoAprobado   = fmtMoney(a.FSC_MontoAprobado__c);

            r.cuotaSolicitada = fmtMoney(a.FSC_Monto__c / (a.FSC_PlazoMeses__c != null ? a.FSC_PlazoMeses__c : 1));
            r.plazoSolicitado = (a.FSC_PlazoMeses__c != null) ? String.valueOf(a.FSC_PlazoMeses__c) : '';
            r.tasaRefSolicitada = fmtRate(a.FSC_TasaInteres__c);

            r.cuotaAprobada = fmtMoney(a.FSC_MontoAprobado__c / (a.FSC_PlazoMesesAprobado__c != null ? a.FSC_PlazoMesesAprobado__c : 1));
            r.plazoAprobado = (a.FSC_PlazoMesesAprobado__c != null) ? String.valueOf(a.FSC_PlazoMesesAprobado__c) : '';
            r.tasaRefAprobada = fmtRate(a.FSC_TasaInteresAprobada__c);

            List<LoanApplicationAsset> assetsForRLA = rlaIdToAssets.get(a.Id);

            LoanApplicationAsset gar1 = (assetsForRLA != null && assetsForRLA.size() > 0) ? assetsForRLA[0] : null;
            LoanApplicationAsset gar2 = (assetsForRLA != null && assetsForRLA.size() > 1) ? assetsForRLA[1] : null;

            r.garantiaPrincipal = (gar1 != null && gar1.AssetType != null) ? String.valueOf(gar1.AssetType) : '';
            r.valorGarantiaPrincipal = (gar1 != null) ? fmtMoney(gar1.CashOrMarketValue) : '';
            r.descGarantiaPrincipal = (gar1 != null) ? nvl(gar1.FSC_Descripcion_de_la_Garantia__c, '') : '';

            r.garantiaSecundaria = (gar2 != null && gar2.AssetType != null) ? String.valueOf(gar2.AssetType) : '';
            r.valorGarantiaSecundaria = (gar2 != null) ? fmtMoney(gar2.CashOrMarketValue) : '';
            r.descGarantiaSecundaria = (gar2 != null) ? nvl(gar2.FSC_Descripcion_de_la_Garantia__c, '') : '';

            r.decisionComite = (a.FSC_DecisionComite__c != null) ? String.valueOf(a.FSC_DecisionComite__c) : '';
            r.condicion = (a.FSC_CondicionComite__c != null) ? String.valueOf(a.FSC_CondicionComite__c) : '';
            r.observaciones = (a.FSC_ObservacionesComite__c != null) ? String.valueOf(a.FSC_ObservacionesComite__c) : '';

            actas.add(r);
        }

        miembrosComite = new List<MiembroComite>();
        for (FSC_MiembrosComiteParaActas__mdt variableMCPA : [
            SELECT
                Id,
                FSC_Nombre__c,
                FSC_Perfil__c,
                FSC_Funcion__c,
                FSC_Modalidad__c
            FROM FSC_MiembrosComiteParaActas__mdt
            ORDER BY Label
        ]) {
            MiembroComite mc = new MiembroComite();
            mc.nombre = variableMCPA.FSC_Nombre__c;
            mc.perfil = variableMCPA.FSC_Perfil__c;
            mc.funcion = variableMCPA.FSC_Funcion__c;
            mc.modalidad = variableMCPA.FSC_Modalidad__c;
            miembrosComite.add(mc);
        }
    }

    private static String nvl(String a, String b) {
        return String.isBlank(a) ? b : a;
    }

    private static String fmtMoney(Decimal d) {
        if (d == null) return '';
        return '$ ' + d.setScale(2).format();
    }

    private static String fmtRate(Decimal d) {
        if (d == null) return '';
        return d.setScale(2).format() + '%';
    }
}