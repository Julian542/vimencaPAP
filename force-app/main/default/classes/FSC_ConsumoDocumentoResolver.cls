public without sharing class FSC_ConsumoDocumentoResolver {
    public static final String PAGARE_NOTARIAL = 'NOTARIAL';
    public static final String PAGARE_COMPLEMENTARIO = 'COMPLEMENTARIO';
    public static final String PAGARE_SIMPLE = 'SIMPLE';
    public static final String PAGARE_SIMPLE_FIADOR = 'SIMPLE_FIADOR';

    public static final String GARANTIA_VEHICULO = 'VEHICULO';
    public static final String GARANTIA_HIPOTECARIA = 'HIPOTECARIA';
    public static final String GARANTIA_CD = 'CERTIFICADO_DEPOSITO';
    public static final String GARANTIA_SOLIDARIA = 'SOLIDARIA';
    public static final String SIN_GARANTIA = 'SIN_GARANTIA';

    private static final String RECORD_TYPE_CONSUMO = 'FSC_Solicitud_Credito_Consumo';
    private static final Decimal MONTO_PAGARE_NOTARIAL = 2000000;

    public class ResolucionDocumento {
        public Boolean aplicaConsumo { get; set; }
        public String codigoPagare { get; set; }
        public String nombrePagare { get; set; }
        public String tipoGarantia { get; set; }
        public Id garantiaId { get; set; }
        public Boolean tieneGarante { get; set; }
    }

    public static ResolucionDocumento resolve(Id rlaId) {
        ResidentialLoanApplication rla = [
            SELECT Id, RecordType.DeveloperName, FSC_RequiereContratoPagareNotarial__c,
                FSC_Monto__c, FSC_MontoAprobado__c, FSC_Tipo_de_Garantia__c
            FROM ResidentialLoanApplication
            WHERE Id = :rlaId
            LIMIT 1
        ];

        ResolucionDocumento result = new ResolucionDocumento();
        result.aplicaConsumo = rla.RecordType.DeveloperName == RECORD_TYPE_CONSUMO;
        if (!result.aplicaConsumo) return result;

        List<FSC_Garantia__c> guarantees = [
            SELECT Id, FSC_Clase_de_Garantia__c, FSC_Tipo_de_Garantia__c, CreatedDate
            FROM FSC_Garantia__c
            WHERE FSC_Residential_Loan_Application__c = :rlaId
            ORDER BY CreatedDate ASC, Id ASC
            LIMIT 1
        ];
        Integer guarantorCount = [
            SELECT COUNT()
            FROM LoanApplicant
            WHERE LoanApplicationId = :rlaId AND FSC_TipoSolicitante__c = 'Garante'
        ];
        result.tieneGarante = guarantorCount > 0;

        if (!guarantees.isEmpty()) {
            FSC_Garantia__c firstGuarantee = guarantees[0];
            result.garantiaId = firstGuarantee.Id;
            result.tipoGarantia = classifyGuarantee(
                FSC_CatalogoGarantiaService.getTextoClasificacion(
                    firstGuarantee.FSC_Clase_de_Garantia__c,
                    firstGuarantee.FSC_Tipo_de_Garantia__c
                )
            );
        } else {
            result.tipoGarantia = classifyGuarantee(rla.FSC_Tipo_de_Garantia__c);
        }

        Boolean solidary = result.tieneGarante && normalize(rla.FSC_Tipo_de_Garantia__c).contains('SOLIDARIA');
        Decimal amount = rla.FSC_Monto__c;
        Boolean notarial = rla.FSC_RequiereContratoPagareNotarial__c == true ||
            (amount != null && amount > MONTO_PAGARE_NOTARIAL) ||
            result.tipoGarantia == GARANTIA_VEHICULO ||
            result.tipoGarantia == GARANTIA_HIPOTECARIA;

        if (notarial) {
            result.codigoPagare = PAGARE_NOTARIAL;
            result.nombrePagare = 'Pagaré notarial';
        } else if (solidary) {
            result.codigoPagare = PAGARE_SIMPLE_FIADOR;
            result.nombrePagare = 'Pagaré comercial individual con fiador';
        } else if (result.tipoGarantia == GARANTIA_VEHICULO ||
            result.tipoGarantia == GARANTIA_HIPOTECARIA ||
            result.tipoGarantia == GARANTIA_CD) {
            result.codigoPagare = PAGARE_COMPLEMENTARIO;
            result.nombrePagare = 'Pagaré complementario';
        } else if (result.tipoGarantia == SIN_GARANTIA || result.tipoGarantia == GARANTIA_SOLIDARIA) {
            result.codigoPagare = PAGARE_SIMPLE;
            result.nombrePagare = 'Pagaré comercial individual';
        } else {
            throw new FSC_ConsumoDocumentoResolverException(
                'La garantía de Consumo no corresponde a vehículo, inmueble, certificado de depósito ni garantía solidaria.'
            );
        }
        return result;
    }

    private static String classifyGuarantee(String rawValue) {
        String value = normalize(rawValue);
        if (String.isBlank(value) || value.contains('SIN GARANTIA')) return SIN_GARANTIA;
        if (value.contains('VEHICULO')) return GARANTIA_VEHICULO;
        if (value.contains('INMUEBLE') || value.contains('HIPOTEC') || value.contains('SOLAR') ||
            value.contains('TERRENO') || value.contains('VIVIENDA') || value.contains('APARTAMENTO')) {
            return GARANTIA_HIPOTECARIA;
        }
        if (value.contains('CERTIFICADO') || value.contains('DEPOSITO A PLAZO')) return GARANTIA_CD;
        if (value.contains('SOLIDARIA') || value.contains('FIRMA SOLIDARIA')) return GARANTIA_SOLIDARIA;
        return 'OTRA_GARANTIA';
    }

    private static String normalize(String value) {
        String normalized = String.isBlank(value) ? '' : value.trim().toUpperCase();
        return normalized.replace('Á', 'A').replace('É', 'E').replace('Í', 'I')
            .replace('Ó', 'O').replace('Ú', 'U').replace('Ü', 'U');
    }

    public class FSC_ConsumoDocumentoResolverException extends Exception {}
}