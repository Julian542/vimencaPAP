public with sharing class FSC_PymeSolicitudPdfCtrl {
    // Entrada
    public String payload { get; private set; }
    public String contextId { get; private set; }

    // JSON root
    private Map<String, Object> root;
    private Map<String, Object> omniData;

    // Secciones (maps)
    public Map<String, Object> fisica { get; private set; }
    public Map<String, Object> juridica { get; private set; }
    public Map<String, Object> company { get; private set; }
    public Map<String, Object> loan { get; private set; }
    public Map<String, Object> warrantyDetails { get; private set; }
    public Map<String, Object> historia { get; private set; }
    public Map<String, Object> estadosFinancieros { get; private set; }
    public Map<String, Object> estadoSituacion { get; private set; }
    public Map<String, Object> gananciasPerdidas { get; private set; }

    // Person type
    public String personType { get; private set; }

    // Listas para tablas
    public List<Map<String, Object>> socios { get; private set; }
    public List<Map<String, Object>> facilidades { get; private set; }
    public List<Map<String, Object>> propositos { get; private set; }
    public List<Map<String, Object>> garantiasOfrecidas { get; private set; }
    public List<Map<String, Object>> relacion { get; private set; }
    public List<Map<String, Object>> referencias { get; private set; }
    public List<Map<String, Object>> fortalezasDebilidades { get; private set; }
    public List<Map<String, Object>> clientesProveedores { get; private set; }

    // Encabezado
    public Date today { get; private set; }

    public FSC_PymeSolicitudPdfCtrl() {
        today = Date.today();

        payload  = ApexPages.currentPage().getParameters().get('payload');
        contextId = ApexPages.currentPage().getParameters().get('ContextId');

        if (String.isBlank(payload)) {
            // Puedes decidir si aquí quieres fallback a buscar JSON desde un registro por ContextId
            payload = '{"omniData":{}}';
        }

        parse();
        bind();
    }

    private void parse() {
        Object o = JSON.deserializeUntyped(payload);
        if (o instanceof Map<String, Object>) {
            root = (Map<String, Object>) o;
        } else {
            root = new Map<String, Object>();
        }
        omniData = asMap(root.get('omniData'));
    }

    private void bind() {
        fisica = asMap(omniData.get('StepApplicantDetailsFisica'));
        juridica = asMap(omniData.get('StepApplicantDetailsJuridica'));
        company = asMap(omniData.get('StepCompanyDetails'));
        loan = asMap(omniData.get('StepLoanDetails'));
        warrantyDetails = asMap(omniData.get('StepWarrantyDetails'));
        historia = asMap(omniData.get('StepHistoria'));
        estadosFinancieros = asMap(omniData.get('StepEstadosFinancieros'));
        estadoSituacion = asMap(omniData.get('StepEstadoSituacion'));
        gananciasPerdidas = asMap(omniData.get('StepEstadoGananciasPerdidas'));

        personType = asString(asMap(omniData.get('StepPersonType')).get('PersonType'));

        socios = asListOfMap(juridica.get('FSC_Socios_Principales_Y_Accionistas__c'));
        facilidades = asListOfMap(asMap(omniData.get('StepDescripcionFacilidades')).get('FSC_Facilidades_De_Credito__c'));
        propositos = asListOfMap(asMap(omniData.get('StepProposito')).get('FSC_Proposito_Y_Uso_De_Fondos__c'));
        garantiasOfrecidas = asListOfMap(asMap(omniData.get('StepGarantias')).get('LoanApplicationAsset'));
        relacion = asListOfMap(omniData.get('StepRelacion'));
        referencias = asListOfMap(asMap(omniData.get('StepReferencias')).get('FSC_Referencias__c'));
        fortalezasDebilidades = asListOfMap(asMap(omniData.get('StepFortalezaDebilidades')).get('FSC_Fortalezas_Y_Debilidades__c'));
        clientesProveedores = asListOfMap(asMap(omniData.get('StepClientesYProveedoresPrincipales')).get('FSC_Clientes_Y_Proveedores_Principales__c'));
    }

    // Helpers
    private static Map<String, Object> asMap(Object o) {
        return (o instanceof Map<String, Object>) ? (Map<String, Object>)o : new Map<String, Object>();
    }
    private static List<Object> asList(Object o) {
        return (o instanceof List<Object>) ? (List<Object>)o : new List<Object>();
    }
    private static List<Map<String, Object>> asListOfMap(Object o) {
        List<Map<String, Object>> out = new List<Map<String, Object>>();
        for (Object x : asList(o)) out.add(asMap(x));
        return out;
    }
    public static String asString(Object o) {
        return o == null ? '' : String.valueOf(o);
    }

    // Formateos
    public String fmtDate(Object o) {
        // JSON viene "yyyy-MM-dd"
        String s = asString(o);
        if (String.isBlank(s)) return '';
        try {
            Date d = Date.valueOf(s);
            // Ajustable: dd-MM-yyyy
            return d.day() + '-' + d.month() + '-' + d.year();
        } catch (Exception e) {
            return s;
        }
    }

    public String fmtMoney(Object o) {
        if (o == null) return '';
        try {
            Decimal d = (o instanceof Decimal) ? (Decimal)o : Decimal.valueOf(String.valueOf(o));
            return d.setScale(2).format();
        } catch (Exception e) {
            return String.valueOf(o);
        }
    }

    // Checkboxes (render como ☒ / ☐)
    public String cb(Boolean checked) {
        return checked ? '☒' : '☐';
    }

    public Boolean isPersonaFisica() {
        return personType == 'Persona_Fisica';
    }
    public Boolean isPersonaJuridica() {
        return personType == 'Persona_Juridica';
    }

    // Ejemplos de checks
    public Boolean isCedula() {
        return asString(fisica.get('IdentificationType')).toLowerCase().contains('cédula')
            || asString(fisica.get('IdentificationType')).toLowerCase().contains('cedula');
    }
    public Boolean isPasaporte() {
        return asString(fisica.get('IdentificationType')).toLowerCase().contains('pasaporte');
    }
    public Boolean isMasculino() {
        return asString(fisica.get('Sex')).toUpperCase().startsWith('M');
    }
    public Boolean isFemenino() {
        return asString(fisica.get('Sex')).toUpperCase().startsWith('F');
    }
}