/**
 * Reglas de redacción compartidas por las plantillas de contrato: qué seguros aplican y cómo se escriben las
 * generales de personas físicas y jurídicas.
 */
public without sharing class FSC_ContratoRedaccionService {
    public class Representante {
        public String nombre { get; set; }
        public String cargo { get; set; }
        public String sexo { get; set; }
        public String nacionalidad { get; set; }
        public String estadoCivil { get; set; }
        public String identificacion { get; set; }
        public String domicilio { get; set; }
    }

    /**
     * Toda persona física lleva seguro de vida, salvo garantía de vehículo o de certificado financiero.
     * Las personas jurídicas no llevan seguro de vida.
     */
    public static Boolean aplicaSeguroVida(Boolean esPersonaFisica, String templateCode) {
        return esPersonaFisica == true &&
            !esPlantillaVehiculo(templateCode) &&
            templateCode != FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION;
    }

    /** Vehículo: seguro full 100% comprensivo. Inmueble: seguro de incendio. Otras garantías: ninguno. */
    public static String tipoSeguroPropiedad(String templateCode) {
        if (esPlantillaVehiculo(templateCode)) return FSC_ContratoSeguro.TIPO_VEHICULO;
        if (esPlantillaInmueble(templateCode)) return FSC_ContratoSeguro.TIPO_INCENDIO;
        return null;
    }

    public static Boolean esPlantillaInmueble(String templateCode) {
        return templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_HIPOTECARIA ||
            templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_CONSUMO_GARANTIA_HIPOTECARIA ||
            FSC_RLAContractTemplateResolver.isMortgagePurchaseTemplate(templateCode);
    }

    public static Boolean esPlantillaVehiculo(String templateCode) {
        return templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION ||
            templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_CONSUMO_GARANTIA_MOBILIARIA;
    }

    /** Ej.: "JUAN PÉREZ, dominicano, mayor de edad, soltero, portador de la cédula de identidad y electoral No. ...". */
    public static String generalesPersona(
        String nombre,
        String sexo,
        String nacionalidad,
        String estadoCivil,
        String identificacion,
        String domicilio
    ) {
        return nombre + ', ' + descripcionPersona(sexo, nacionalidad, estadoCivil, identificacion, domicilio);
    }

    /** Generales de una sociedad con uno o varios representantes, según el modelo indicado por EL BANCO. */
    public static String generalesEmpresa(
        String nombre,
        String rnc,
        String registroMercantil,
        String domicilio,
        List<Representante> representantes
    ) {
        return nombre + ', sociedad comercial organizada y existente de conformidad con las leyes de la República Dominicana, RNC No. ' +
            formatearRnc(rnc) + ', Registro Mercantil No. ' + texto(registroMercantil) + ', con su domicilio social en ' +
            texto(domicilio) + ', debidamente representada por ' + representacion(representantes);
    }

    public static String formatearRnc(String rnc) {
        String digitos = soloDigitos(rnc);
        if (digitos.length() != 9) return texto(rnc);
        return digitos.left(1) + '-' + digitos.mid(1, 2) + '-' + digitos.mid(3, 5) + '-' + digitos.right(1);
    }

    public static String formatearCedula(String identificacion) {
        String digitos = soloDigitos(identificacion);
        if (!esCedula(identificacion)) return texto(identificacion);
        return digitos.left(3) + '-' + digitos.mid(3, 7) + '-' + digitos.right(1);
    }

    /** Agrega la "a" de concordancia cuando se conoce el sexo, ej. "portador(a)" → "portadora". */
    public static String concordar(String masculino, String sexo) {
        if (sexo == FSC_ContratoParte.SEXO_FEMENINO) return masculino.endsWith('o') ? masculino.left(masculino.length() - 1) + 'a' : masculino + 'a';
        if (sexo == FSC_ContratoParte.SEXO_MASCULINO) return masculino;
        return masculino + '(a)';
    }

    private static String representacion(List<Representante> representantes) {
        List<Representante> firmantes = new List<Representante>();
        for (Representante item : representantes == null ? new List<Representante>() : representantes) {
            if (item != null && !String.isBlank(item.nombre)) firmantes.add(item);
        }
        if (firmantes.isEmpty()) return '';
        if (firmantes.size() == 1) return 'su ' + texto(firmantes[0].cargo) + ', ' + presentar(firmantes[0]);

        Boolean mismoCargo = true;
        Boolean todasMujeres = true;
        for (Representante item : firmantes) {
            mismoCargo = mismoCargo && texto(item.cargo).equalsIgnoreCase(texto(firmantes[0].cargo));
            todasMujeres = todasMujeres && item.sexo == FSC_ContratoParte.SEXO_FEMENINO;
        }
        List<String> partes = new List<String>();
        for (Representante item : firmantes) {
            partes.add(
                mismoCargo
                    ? item.nombre + ', ' + descripcionPersona(item.sexo, item.nacionalidad, item.estadoCivil, item.identificacion, item.domicilio)
                    : 'su ' + texto(item.cargo) + ', ' + presentar(item)
            );
        }
        String lista = unir(partes, mismoCargo ? ', ' : '; ');
        return mismoCargo ? 'sus ' + pluralizar(texto(firmantes[0].cargo)) + ', ' + (todasMujeres ? 'señoras ' : 'señores ') + lista : lista;
    }

    private static String presentar(Representante item) {
        String tratamiento = item.sexo == FSC_ContratoParte.SEXO_FEMENINO ? 'señora ' : (item.sexo == FSC_ContratoParte.SEXO_MASCULINO ? 'señor ' : '');
        return tratamiento + generalesPersona(item.nombre, item.sexo, item.nacionalidad, item.estadoCivil, item.identificacion, item.domicilio);
    }

    private static String descripcionPersona(String sexo, String nacionalidad, String estadoCivil, String identificacion, String domicilio) {
        String documento = esCedula(identificacion)
            ? ' de la cédula de identidad y electoral No. '
            : ' del documento de identidad No. ';
        return minusculas(nacionalidad) + ', mayor de edad, ' + minusculas(estadoCivil) + ', ' + concordar('portador', sexo) + documento +
            formatearCedula(identificacion) + ', ' + concordar('domiciliado', sexo) + ' y residente en ' + texto(domicilio);
    }

    @TestVisible
    private static String pluralizar(String cargo) {
        // Solo se pluraliza el cargo, no su complemento: "Director General de Ventas" -> "Directores Generales de Ventas".
        List<String> palabras = new List<String>();
        Boolean complemento = false;
        for (String palabra : cargo.split(' ')) {
            String minuscula = palabra.toLowerCase();
            complemento = complemento || minuscula == 'de' || minuscula == 'del';
            if (complemento || minuscula == 'y' || String.isBlank(palabra) || minuscula.endsWith('s')) {
                palabras.add(palabra);
            } else {
                palabras.add('aeiouáéó'.contains(minuscula.right(1)) ? palabra + 's' : palabra + 'es');
            }
        }
        return String.join(palabras, ' ');
    }

    private static String unir(List<String> valores, String separador) {
        if (valores.size() == 1) return valores[0];
        List<String> copia = new List<String>(valores);
        String ultimo = copia.remove(copia.size() - 1);
        return String.join(copia, separador) + (separador == ', ' ? ', y ' : '; y ') + ultimo;
    }

    private static Boolean esCedula(String identificacion) {
        String digitos = soloDigitos(identificacion);
        return digitos.length() == 11 && texto(identificacion).replaceAll('[0-9\\-\\s]', '') == '';
    }

    private static String soloDigitos(String value) {
        return value == null ? '' : value.replaceAll('[^0-9]', '');
    }

    private static String minusculas(String value) {
        return texto(value).toLowerCase();
    }

    private static String texto(String value) {
        return value == null ? '' : value.trim();
    }
}