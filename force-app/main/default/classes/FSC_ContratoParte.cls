/**
 * Denominación de una parte del contrato (EL PRESTATARIO, LA PRESTATARIA, LOS PRESTATARIOS...) con las
 * terminaciones que las plantillas usan para concordar verbos y adjetivos, ej. "autoriza{!p.n}", "obligad{!p.o}".
 */
public without sharing class FSC_ContratoParte {
    public static final String SEXO_MASCULINO = 'Masculino';
    public static final String SEXO_FEMENINO = 'Femenino';

    private static final Set<String> CONECTORES = new Set<String>{ '-', 'Y', 'DE', 'DEL' };

    public String nombre { get; private set; }
    public Boolean plural { get; private set; }
    public Boolean femenino { get; private set; }

    public String n {
        get { return plural ? 'n' : ''; }
    }
    public String o {
        get { return (femenino ? 'a' : 'o') + (plural ? 's' : ''); }
    }
    public String es {
        get { return plural ? 'son' : 'es'; }
    }
    public String lo {
        get { return (femenino ? 'la' : 'lo') + (plural ? 's' : ''); }
    }
    public String le {
        get { return plural ? 'les' : 'le'; }
    }
    public String s {
        get { return plural ? 's' : ''; }
    }
    public String este {
        get { return plural ? (femenino ? 'estas' : 'estos') : (femenino ? 'esta' : 'este'); }
    }
    public String deudor {
        get { return 'deudor' + (femenino ? 'a' : '') + (plural ? (femenino ? 's' : 'es') : ''); }
    }

    private FSC_ContratoParte(String nombre, Boolean plural, Boolean femenino) {
        this.nombre = nombre;
        this.plural = plural;
        this.femenino = femenino;
    }

    /**
     * @param sustantivos denominación en masculino singular, ej. 'PRESTATARIO - GARANTE MOBILIARIO'.
     * @param sexos sexo de cada persona que integra la parte; una empresa se trata como femenino singular
     *              ("LA PRESTATARIA", por "la sociedad").
     */
    public static FSC_ContratoParte crear(String sustantivos, List<String> sexos, Boolean esEmpresa) {
        Integer personas = sexos == null || sexos.isEmpty() ? 1 : sexos.size();
        Boolean esPlural = personas > 1;
        // En plural basta un integrante masculino (o una empresa) para usar el masculino.
        Boolean esFemenino = (!esPlural && esEmpresa == true) || todasFemeninas(sexos);
        String articulo = esPlural ? (esFemenino ? 'LAS' : 'LOS') : (esFemenino ? 'LA' : 'EL');
        return new FSC_ContratoParte(articulo + ' ' + flexionar(sustantivos, esFemenino, esPlural), esPlural, esFemenino);
    }

    public static FSC_ContratoParte crear(String sustantivos, String sexo, Boolean esEmpresa) {
        return crear(sustantivos, new List<String>{ sexo }, esEmpresa);
    }

    /** Une dos partes como sujeto compuesto, ej. "EL PRESTATARIO y EL GARANTE SOLIDARIO autorizan". */
    public static FSC_ContratoParte combinar(FSC_ContratoParte primera, FSC_ContratoParte segunda) {
        if (segunda == null) return primera;
        return new FSC_ContratoParte(primera.nombre + ' y ' + segunda.nombre, true, primera.femenino && segunda.femenino);
    }

    private static Boolean todasFemeninas(List<String> sexos) {
        if (sexos == null || sexos.isEmpty()) return false;
        for (String sexo : sexos) {
            if (sexo != SEXO_FEMENINO) return false;
        }
        return true;
    }

    @TestVisible
    private static String flexionar(String sustantivos, Boolean esFemenino, Boolean esPlural) {
        List<String> resultado = new List<String>();
        for (String palabra : sustantivos.trim().split(' ')) {
            resultado.add(CONECTORES.contains(palabra) ? palabra : flexionarPalabra(palabra, esFemenino, esPlural));
        }
        return String.join(resultado, ' ');
    }

    private static String flexionarPalabra(String palabra, Boolean esFemenino, Boolean esPlural) {
        String resultado = palabra;
        if (palabra.endsWith('O')) {
            resultado = esFemenino ? palabra.left(palabra.length() - 1) + 'A' : palabra;
            return esPlural ? resultado + 'S' : resultado;
        }
        if (palabra.endsWith('OR')) {
            resultado = esFemenino ? palabra + 'A' : palabra;
            return esPlural ? resultado + (esFemenino ? 'S' : 'ES') : resultado;
        }
        if (palabra.endsWith('E')) {
            return esPlural ? palabra + 'S' : palabra;
        }
        return esPlural ? palabra + 'ES' : palabra;
    }
}