public without sharing class FSC_VehiculoDocumentoResolver {
    public static final String GARANTIA_VEHICULO = 'VEHICULO';
    public static final String OTRA_GARANTIA = 'OTRA_GARANTIA';
    public static final String SIN_GARANTIA = 'SIN_GARANTIA';
    public static final String PROPIETARIO_DEUDOR = 'Deudor';
    public static final String PROPIETARIO_DISTINTO = 'Otra persona (Garante mobiliario)';

    private static final String RECORD_TYPE_VEHICULO = 'FSC_Solicitud_Credito_Vehiculo';

    public class ResolucionDocumento {
        public Boolean aplicaVehiculo { get; set; }
        public String codigoPagare { get; set; }
        public String nombrePagare { get; set; }
        public String tipoGarantia { get; set; }
        public Id garantiaId { get; set; }
        public String propietarioGarantia { get; set; }
        public Boolean tieneContratoVehicular { get; set; }
        public Boolean generaContrato { get; set; }
    }

    public static ResolucionDocumento resolve(Id rlaId) {
        ResidentialLoanApplication rla = [
            SELECT Id, RecordType.DeveloperName, FSC_Excepcion_Contrato_Notarial__c,
                FSC_Propietario_Garantia_Vehiculo__c
            FROM ResidentialLoanApplication
            WHERE Id = :rlaId
            LIMIT 1
        ];

        ResolucionDocumento result = new ResolucionDocumento();
        result.aplicaVehiculo = rla.RecordType.DeveloperName == RECORD_TYPE_VEHICULO;
        result.tieneContratoVehicular = false;
        result.generaContrato = false;
        if (!result.aplicaVehiculo) return result;

        result.codigoPagare = rla.FSC_Excepcion_Contrato_Notarial__c == true
            ? FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL
            : FSC_ConsumoDocumentoResolver.PAGARE_COMPLEMENTARIO;
        result.nombrePagare = result.codigoPagare == FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL
            ? 'Pagaré notarial'
            : 'Pagaré complementario';
        result.propietarioGarantia = String.isBlank(rla.FSC_Propietario_Garantia_Vehiculo__c)
            ? PROPIETARIO_DEUDOR
            : rla.FSC_Propietario_Garantia_Vehiculo__c;

        List<FSC_Garantia__c> guarantees = [
            SELECT Id, FSC_Clase_de_Garantia__c, FSC_Tipo_de_Garantia__c, CreatedDate
            FROM FSC_Garantia__c
            WHERE FSC_Residential_Loan_Application__c = :rlaId
            ORDER BY CreatedDate ASC, Id ASC
            LIMIT 1
        ];
        if (guarantees.isEmpty()) {
            result.tipoGarantia = SIN_GARANTIA;
            return result;
        }

        FSC_Garantia__c firstGuarantee = guarantees[0];
        result.garantiaId = firstGuarantee.Id;
        result.tipoGarantia = classifyGuarantee(
            FSC_CatalogoGarantiaService.getTextoClasificacion(
                firstGuarantee.FSC_Clase_de_Garantia__c,
                firstGuarantee.FSC_Tipo_de_Garantia__c
            )
        );
        result.tieneContratoVehicular = result.tipoGarantia == GARANTIA_VEHICULO;
        // El mismo contrato admite al propietario deudor o a garantes mobiliarios distintos.
        result.generaContrato = result.tieneContratoVehicular;
        return result;
    }

    private static String classifyGuarantee(String rawValue) {
        String value = normalize(rawValue);
        if (String.isBlank(value) || value.contains('SIN GARANTIA')) return SIN_GARANTIA;
        if (value.contains('VEHICULO')) return GARANTIA_VEHICULO;
        return OTRA_GARANTIA;
    }

    private static String normalize(String value) {
        String normalized = String.isBlank(value) ? '' : value.trim().toUpperCase();
        return normalized.replace('Á', 'A').replace('É', 'E').replace('Í', 'I')
            .replace('Ó', 'O').replace('Ú', 'U').replace('Ü', 'U');
    }
}