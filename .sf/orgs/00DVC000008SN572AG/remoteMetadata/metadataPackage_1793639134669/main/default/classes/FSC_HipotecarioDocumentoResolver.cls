public without sharing class FSC_HipotecarioDocumentoResolver {
    public static final String PROPIETARIO_DEUDOR = 'Deudor';
    public static final String PROPIETARIO_DISTINTO = 'Otra persona (Garante real)';
    public static final String VENDEDOR_PERSONA_FISICA = 'Persona física';
    public static final String VENDEDOR_EMPRESA = 'Empresa';
    public static final String VENDEDOR_FIDEICOMISO = 'Fideicomiso';

    private static final String RECORD_TYPE_HIPOTECARIO = 'FSC_Solicitud_Credito_Hipotecario';

    public class ResolucionDocumento {
        public Boolean aplicaHipotecario { get; set; }
        public String codigoPagare { get; set; }
        public String nombrePagare { get; set; }
        public Boolean tieneGarantiaHipotecaria { get; set; }
        public Boolean contratoDisponible { get; set; }
        public Boolean generaContrato { get; set; }
        public Id garantiaId { get; set; }
        public String propietarioGarantia { get; set; }
        public String tipoVendedor { get; set; }
        public Boolean tieneCertificadoConfotur { get; set; }
        public Boolean tieneCertificadoBajoCosto { get; set; }
        public String templateCode { get; set; }
    }

    public static ResolucionDocumento resolve(Id rlaId) {
        ResidentialLoanApplication rla = [
            SELECT Id, RecordType.DeveloperName, FSC_Excepcion_Contrato_Notarial__c,
                FSC_Propietario_Garantia_Hipotecaria__c, FSC_Tipo_Vendedor_Hipotecario__c
            FROM ResidentialLoanApplication
            WHERE Id = :rlaId
            LIMIT 1
        ];

        ResolucionDocumento result = new ResolucionDocumento();
        result.aplicaHipotecario = rla.RecordType.DeveloperName == RECORD_TYPE_HIPOTECARIO;
        result.tieneGarantiaHipotecaria = false;
        result.contratoDisponible = false;
        result.generaContrato = false;
        if (!result.aplicaHipotecario) return result;

        result.codigoPagare = rla.FSC_Excepcion_Contrato_Notarial__c == true
            ? FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL
            : FSC_ConsumoDocumentoResolver.PAGARE_COMPLEMENTARIO;
        result.nombrePagare = result.codigoPagare == FSC_ConsumoDocumentoResolver.PAGARE_NOTARIAL
            ? 'Pagaré notarial'
            : 'Pagaré complementario';
        result.propietarioGarantia = String.isBlank(rla.FSC_Propietario_Garantia_Hipotecaria__c)
            ? PROPIETARIO_DEUDOR
            : rla.FSC_Propietario_Garantia_Hipotecaria__c;
        result.tipoVendedor = String.isBlank(rla.FSC_Tipo_Vendedor_Hipotecario__c)
            ? VENDEDOR_EMPRESA
            : rla.FSC_Tipo_Vendedor_Hipotecario__c;

        List<FSC_Garantia__c> guarantees = [
            SELECT Id, FSC_Clase_de_Garantia__c, FSC_Tipo_de_Garantia__c
            FROM FSC_Garantia__c
            WHERE FSC_Residential_Loan_Application__c = :rlaId
            ORDER BY CreatedDate ASC, Id ASC
            LIMIT 1
        ];
        if (guarantees.isEmpty()) return result;

        FSC_Garantia__c firstGuarantee = guarantees[0];
        result.garantiaId = firstGuarantee.Id;
        result.tieneGarantiaHipotecaria = isMortgage(
            FSC_CatalogoGarantiaService.getTextoClasificacion(
                firstGuarantee.FSC_Clase_de_Garantia__c,
                firstGuarantee.FSC_Tipo_de_Garantia__c
            )
        );
        if (!result.tieneGarantiaHipotecaria) return result;

        Map<String, Boolean> certificates = findUploadedCertificates(rlaId);
        result.tieneCertificadoConfotur = certificates.get('confotur') == true;
        result.tieneCertificadoBajoCosto = certificates.get('bajoCosto') == true;
        if (result.tieneCertificadoConfotur) result.tipoVendedor = VENDEDOR_EMPRESA;
        result.templateCode = selectTemplate(result);
        result.contratoDisponible = true;
        // Las cinco versiones hipotecarias admiten propietario deudor o garantes reales.
        result.generaContrato = true;
        return result;
    }

    private static String selectTemplate(ResolucionDocumento result) {
        if (result.tieneCertificadoConfotur) {
            return FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_EMPRESA_LEY_158;
        }
        if (result.tipoVendedor == VENDEDOR_PERSONA_FISICA) {
            return FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_PERSONA_FISICA;
        }
        if (result.tipoVendedor == VENDEDOR_FIDEICOMISO) {
            return result.tieneCertificadoBajoCosto
                ? FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_FIDEICOMISO_BAJO_COSTO
                : FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_FIDEICOMISO_NORMAL;
        }
        return FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_EMPRESA;
    }

    private static Map<String, Boolean> findUploadedCertificates(Id rlaId) {
        Map<String, Boolean> result = new Map<String, Boolean>{
            'confotur' => false,
            'bajoCosto' => false
        };
        List<FSC_SolicitudDeCreditoYChecklistDeDocs__c> rows = [
            SELECT Id, FSC_NoAplica__c, FSC_Documento__r.FSC_NombreDelDocumento__c
            FROM FSC_SolicitudDeCreditoYChecklistDeDocs__c
            WHERE FSC_SolicitudDeCredito__c = :rlaId AND FSC_NoAplica__c = false
        ];
        if (rows.isEmpty()) return result;

        Set<Id> rowIds = new Set<Id>();
        for (FSC_SolicitudDeCreditoYChecklistDeDocs__c row : rows) rowIds.add(row.Id);
        Set<Id> rowsWithFile = new Set<Id>();
        for (ContentDocumentLink link : [
            SELECT LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :rowIds
        ]) {
            rowsWithFile.add(link.LinkedEntityId);
        }

        for (FSC_SolicitudDeCreditoYChecklistDeDocs__c row : rows) {
            if (!rowsWithFile.contains(row.Id) || row.FSC_Documento__r == null) continue;
            String name = normalize(row.FSC_Documento__r.FSC_NombreDelDocumento__c);
            if (name.contains('CONFOTUR') || name.contains('CONFORTUR')) result.put('confotur', true);
            if (name.contains('BAJO COSTO')) result.put('bajoCosto', true);
        }
        return result;
    }

    private static Boolean isMortgage(String rawValue) {
        String value = normalize(rawValue);
        return value.contains('INMUEBLE') || value.contains('SOLAR') || value.contains('TERRENO') ||
            value.contains('HIPOTEC') || value.contains('EDIFICIO') || value.contains('VIVIENDA') ||
            value.contains('APTO') || value.contains('HOTEL') || value.contains('ZONA FRANCA') ||
            value.contains('NAVE INDUSTRIAL');
    }

    private static String normalize(String value) {
        String normalized = String.isBlank(value) ? '' : value.trim().toUpperCase();
        return normalized.replace('Á', 'A').replace('É', 'E').replace('Í', 'I')
            .replace('Ó', 'O').replace('Ú', 'U').replace('Ü', 'U');
    }
}