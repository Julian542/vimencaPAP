public without sharing class FSC_RLAContractTemplateResolver {

    public static final String TEMPLATE_SOLA_FIRMA = 'SOLA_FIRMA';
    public static final String TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION = 'GARANTIA_MOBILIARIA_CON_POSESION';
    public static final String TEMPLATE_GARANTIA_HIPOTECARIA = 'GARANTIA_HIPOTECARIA';
    public static final String TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION = 'GARANTIA_MOBILIARIA_SIN_POSESION';
    public static final String TEMPLATE_GARANTIA_SOLIDARIA = 'GARANTIA_SOLIDARIA';
    public static final String TEMPLATE_CONSUMO_GARANTIA_HIPOTECARIA = 'CONSUMO_GARANTIA_HIPOTECARIA';
    public static final String TEMPLATE_CONSUMO_GARANTIA_MOBILIARIA = 'CONSUMO_GARANTIA_MOBILIARIA';
    public static final String TEMPLATE_HIPOTECARIO_PERSONA_FISICA = 'HIPOTECARIO_PERSONA_FISICA';
    public static final String TEMPLATE_HIPOTECARIO_EMPRESA = 'HIPOTECARIO_EMPRESA';
    public static final String TEMPLATE_HIPOTECARIO_EMPRESA_LEY_158 = 'HIPOTECARIO_EMPRESA_LEY_158';
    public static final String TEMPLATE_HIPOTECARIO_FIDEICOMISO_NORMAL = 'HIPOTECARIO_FIDEICOMISO_NORMAL';
    public static final String TEMPLATE_HIPOTECARIO_FIDEICOMISO_BAJO_COSTO = 'HIPOTECARIO_FIDEICOMISO_BAJO_COSTO';

    private static final String RECORD_TYPE_PYME = 'FSC_Solicitud_Credito_PYME';
    private static final String RECORD_TYPE_CONSUMO = 'FSC_Solicitud_Credito_Consumo';
    private static final String RECORD_TYPE_VEHICULO = 'FSC_Solicitud_Credito_Vehiculo';
    private static final String RECORD_TYPE_HIPOTECARIO = 'FSC_Solicitud_Credito_Hipotecario';
    private static final String SIN_GARANTIA = 'SIN GARANTIA';

    public class ContractResolution {
        @AuraEnabled public Boolean aplicaContrato { get; set; }
        @AuraEnabled public Boolean contratoDisponible { get; set; }
        @AuraEnabled public String templateCode { get; set; }
        @AuraEnabled public String tipoContrato { get; set; }
        @AuraEnabled public String nombreContrato { get; set; }
        @AuraEnabled public String tituloArchivo { get; set; }
        @AuraEnabled public Id garantiaId { get; set; }
        @AuraEnabled public Id loanApplicationAssetId { get; set; }

        public ContractResolution(Boolean aplicaContrato) {
            this.aplicaContrato = aplicaContrato;
            this.contratoDisponible = aplicaContrato;
        }
    }

    public static ContractResolution resolve(Id residentialLoanApplicationId) {
        if (residentialLoanApplicationId == null) {
            throw new FSC_RLAContractTemplateResolverException('Se requiere el Id de la solicitud.');
        }

        ResidentialLoanApplication rla = [
            SELECT Id, RecordType.DeveloperName, FSC_Tipo_de_Garantia__c, FSC_Moneda__c
            FROM ResidentialLoanApplication
            WHERE Id = :residentialLoanApplicationId
            LIMIT 1
        ];

        if (rla.RecordType.DeveloperName == RECORD_TYPE_CONSUMO) {
            return resolveConsumption(residentialLoanApplicationId, rla.FSC_Moneda__c);
        }

        if (rla.RecordType.DeveloperName == RECORD_TYPE_VEHICULO) {
            return resolveVehicle(residentialLoanApplicationId, rla.FSC_Moneda__c);
        }

        if (rla.RecordType.DeveloperName == RECORD_TYPE_HIPOTECARIO) {
            return resolveMortgage(residentialLoanApplicationId, rla.FSC_Moneda__c);
        }

        if (rla.RecordType.DeveloperName != RECORD_TYPE_PYME) {
            return new ContractResolution(false);
        }

        List<LoanApplicationAsset> guarantees = [
            SELECT Id, AssetClass, AssetType, AccountType, FSC_Descripcion_de_la_Garantia__c, CreatedDate
            FROM LoanApplicationAsset
            WHERE LoanApplicationId = :residentialLoanApplicationId
            ORDER BY CreatedDate ASC, Id ASC
        ];

        Boolean declaredWithoutGuarantee = normalize(rla.FSC_Tipo_de_Garantia__c) == SIN_GARANTIA;
        if (declaredWithoutGuarantee && guarantees.isEmpty()) {
            validateCurrency(rla.FSC_Moneda__c);
            return buildResolution(TEMPLATE_SOLA_FIRMA, rla.FSC_Moneda__c, null);
        }

        validateCurrency(rla.FSC_Moneda__c);

        Integer guarantorCount = [
            SELECT COUNT()
            FROM LoanApplicant
            WHERE LoanApplicationId = :residentialLoanApplicationId
                AND FSC_TipoSolicitante__c = 'Garante'
        ];

        if (guarantorCount > 0) {
            return buildResolution(TEMPLATE_GARANTIA_SOLIDARIA, rla.FSC_Moneda__c, null);
        }

        if (guarantees.isEmpty()) {
            if (String.isBlank(rla.FSC_Tipo_de_Garantia__c)) {
                return buildResolution(TEMPLATE_SOLA_FIRMA, rla.FSC_Moneda__c, null);
            }
            throw new FSC_RLAContractTemplateResolverException(
                'El crédito PYME indica que tiene garantía, pero no posee un LoanApplicationAsset relacionado.'
            );
        }

        LoanApplicationAsset firstGuarantee = guarantees[0];
        String guaranteeType = normalize(
            picklistLabel(
                LoanApplicationAsset.FSC_Descripcion_de_la_Garantia__c.getDescribe(),
                firstGuarantee.FSC_Descripcion_de_la_Garantia__c
            ) + ' ' + firstGuarantee.AssetClass + ' ' + firstGuarantee.AssetType + ' ' + firstGuarantee.AccountType
        );
        String templateCode;

        if (isMortgage(guaranteeType)) {
            templateCode = TEMPLATE_GARANTIA_HIPOTECARIA;
        } else if (isDepositCertificate(guaranteeType)) {
            templateCode = TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION;
        } else if (isVehicle(guaranteeType)) {
            templateCode = TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION;
        } else {
            throw new FSC_RLAContractTemplateResolverException(
                'La primera garantía creada no corresponde a inmueble, vehículo ni certificado de depósito.'
            );
        }

        ContractResolution resolution = buildResolution(templateCode, rla.FSC_Moneda__c, null);
        resolution.loanApplicationAssetId = firstGuarantee.Id;
        return resolution;
    }

    public static PageReference resolvePageReference(Id residentialLoanApplicationId) {
        ContractResolution resolution = resolve(residentialLoanApplicationId);
        if (!resolution.aplicaContrato) {
            throw new FSC_RLAContractTemplateResolverException('La solicitud no requiere contrato.');
        }
        return buildPageReference(resolution.templateCode, residentialLoanApplicationId);
    }

    public static PageReference resolvePageReference(Id residentialLoanApplicationId, String templateCode) {
        if (residentialLoanApplicationId == null || String.isBlank(templateCode)) {
            throw new FSC_RLAContractTemplateResolverException('Se requiere la solicitud y el tipo de contrato.');
        }
        return buildPageReference(templateCode, residentialLoanApplicationId);
    }

    public static String getMetadataContractType(String templateCode) {
        if (templateCode == TEMPLATE_SOLA_FIRMA) return 'SOLA_FIRMA';
        if (templateCode == TEMPLATE_GARANTIA_HIPOTECARIA) return 'HIPOTECARIO';
        if (templateCode == TEMPLATE_GARANTIA_SOLIDARIA) return 'SOLIDARIO';
        if (templateCode == TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION) return 'MOBILIARIO_CON_POSESION';
        if (templateCode == TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION) return 'MOBILIARIO_SIN_POSESION';
        if (templateCode == TEMPLATE_CONSUMO_GARANTIA_HIPOTECARIA) return 'HIPOTECARIO';
        if (templateCode == TEMPLATE_CONSUMO_GARANTIA_MOBILIARIA) return 'MOBILIARIO_SIN_POSESION';
        if (isMortgagePurchaseTemplate(templateCode)) return 'HIPOTECARIO';
        return null;
    }

    private static ContractResolution resolveConsumption(Id rlaId, String currencyCode) {
        FSC_ConsumoDocumentoResolver.ResolucionDocumento document = FSC_ConsumoDocumentoResolver.resolve(rlaId);
        if (document.codigoPagare == FSC_ConsumoDocumentoResolver.PAGARE_SIMPLE ||
            document.codigoPagare == FSC_ConsumoDocumentoResolver.PAGARE_SIMPLE_FIADOR ||
            document.tipoGarantia == FSC_ConsumoDocumentoResolver.GARANTIA_CD) {
            return new ContractResolution(false);
        }
        if (document.tipoGarantia == FSC_ConsumoDocumentoResolver.GARANTIA_HIPOTECARIA) {
            return buildResolution(TEMPLATE_CONSUMO_GARANTIA_HIPOTECARIA, currencyCode, document.garantiaId);
        }
        if (document.tipoGarantia == FSC_ConsumoDocumentoResolver.GARANTIA_VEHICULO) {
            return buildResolution(TEMPLATE_CONSUMO_GARANTIA_MOBILIARIA, currencyCode, document.garantiaId);
        }
        return new ContractResolution(false);
    }

    private static ContractResolution resolveVehicle(Id rlaId, String currencyCode) {
        FSC_VehiculoDocumentoResolver.ResolucionDocumento document =
            FSC_VehiculoDocumentoResolver.resolve(rlaId);
        if (!document.tieneContratoVehicular || document.garantiaId == null) {
            return new ContractResolution(false);
        }

        ContractResolution result = buildResolution(
            TEMPLATE_CONSUMO_GARANTIA_MOBILIARIA,
            currencyCode,
            document.garantiaId
        );
        result.aplicaContrato = document.generaContrato;
        return result;
    }

    private static ContractResolution resolveMortgage(Id rlaId, String currencyCode) {
        FSC_HipotecarioDocumentoResolver.ResolucionDocumento document =
            FSC_HipotecarioDocumentoResolver.resolve(rlaId);
        if (!document.tieneGarantiaHipotecaria || String.isBlank(document.templateCode)) {
            return new ContractResolution(false);
        }

        ContractResolution result = buildResolution(document.templateCode, currencyCode, document.garantiaId);
        result.contratoDisponible = document.contratoDisponible;
        result.aplicaContrato = document.generaContrato;
        return result;
    }

    private static ContractResolution buildResolution(String templateCode, String currencyCode, Id guaranteeId) {
        ContractResolution result = new ContractResolution(true);
        result.contratoDisponible = true;
        result.templateCode = templateCode;
        result.tipoContrato = getMetadataContractType(templateCode);
        result.nombreContrato = getContractName(templateCode);
        result.tituloArchivo = getFileTitle(templateCode, currencyCode);
        result.garantiaId = guaranteeId;
        return result;
    }

    private static String getFileTitle(String templateCode, String currencyCode) {
        return getContractName(templateCode) + (currencyCode == '2' ? ' EN DOLARES' : ' EN PESOS');
    }

    private static String getContractName(String templateCode) {
        if (templateCode == TEMPLATE_SOLA_FIRMA) {
            return 'CONTRATO DE PRESTAMO COMERCIAL A CUOTAS A SOLA FIRMA';
        }
        if (templateCode == TEMPLATE_GARANTIA_HIPOTECARIA) {
            return 'CONTRATO DE PRESTAMO COMERCIAL A CUOTAS CON GARANTIA HIPOTECARIA';
        }
        if (templateCode == TEMPLATE_GARANTIA_SOLIDARIA) {
            return 'CONTRATO DE PRESTAMO COMERCIAL A CUOTAS CON GARANTIA SOLIDARIA';
        }
        if (templateCode == TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION) {
            return 'CONTRATO DE PRESTAMO COMERCIAL A CUOTAS CON GARANTIA MOBILIARIA CON POSESION';
        }
        if (templateCode == TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION) {
            return 'CONTRATO DE PRESTAMO COMERCIAL A CUOTAS CON GARANTIA MOBILIARIA SIN POSESION (ADQUISICION O CESION)';
        }
        if (templateCode == TEMPLATE_CONSUMO_GARANTIA_HIPOTECARIA) {
            return 'CONTRATO DE PRESTAMO DE CONSUMO CON GARANTIA HIPOTECARIA';
        }
        if (templateCode == TEMPLATE_CONSUMO_GARANTIA_MOBILIARIA) {
            return 'CONTRATO DE PRESTAMO DE CONSUMO CON GARANTIA MOBILIARIA';
        }
        if (templateCode == TEMPLATE_HIPOTECARIO_PERSONA_FISICA) {
            return 'CONTRATO DE PRESTAMO CON GARANTIA HIPOTECARIA Y COMPRA DE INMUEBLE VENDEDOR PERSONA FISICA';
        }
        if (templateCode == TEMPLATE_HIPOTECARIO_EMPRESA) {
            return 'CONTRATO DE PRESTAMO CON GARANTIA HIPOTECARIA Y COMPRA DE INMUEBLE VENDEDORA EMPRESA';
        }
        if (templateCode == TEMPLATE_HIPOTECARIO_EMPRESA_LEY_158) {
            return 'CONTRATO DE PRESTAMO CON GARANTIA HIPOTECARIA Y COMPRA DE INMUEBLE VENDEDORA EMPRESA LEY 158-01';
        }
        if (templateCode == TEMPLATE_HIPOTECARIO_FIDEICOMISO_NORMAL) {
            return 'CONTRATO DE PRESTAMO CON GARANTIA HIPOTECARIA Y COMPRA DE INMUEBLE CON FIDEICOMISO DE VIVIENDA NORMAL';
        }
        if (templateCode == TEMPLATE_HIPOTECARIO_FIDEICOMISO_BAJO_COSTO) {
            return 'CONTRATO DE PRESTAMO CON GARANTIA HIPOTECARIA Y COMPRA DE INMUEBLE CON FIDEICOMISO DE VIVIENDA DE BAJO COSTO';
        }
        throw new FSC_RLAContractTemplateResolverException('Tipo de contrato no configurado: ' + templateCode);
    }

    private static PageReference buildPageReference(String templateCode, Id residentialLoanApplicationId) {
        PageReference contractPage;
        if (templateCode == TEMPLATE_SOLA_FIRMA) {
            contractPage = Page.FSC_ContratoPrestamoComercialSF;
        } else if (templateCode == TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION) {
            contractPage = Page.FSC_ContratoPrestamoComercialGarantiaCD;
        } else if (templateCode == TEMPLATE_GARANTIA_HIPOTECARIA) {
            contractPage = Page.FSC_ContratoPrestamoComercialCH;
        } else if (templateCode == TEMPLATE_GARANTIA_MOBILIARIA_SIN_POSESION) {
            contractPage = Page.FSC_ContratoPrestamoComercialGMSP;
        } else if (templateCode == TEMPLATE_GARANTIA_SOLIDARIA) {
            contractPage = Page.FSC_ContratoPrestamoComercialGS;
        } else if (templateCode == TEMPLATE_CONSUMO_GARANTIA_HIPOTECARIA) {
            contractPage = Page.FSC_ContratoConsumoHipotecario;
        } else if (templateCode == TEMPLATE_CONSUMO_GARANTIA_MOBILIARIA) {
            contractPage = Page.FSC_ContratoPrestamoConsumoVehiculo;
        } else if (templateCode == TEMPLATE_HIPOTECARIO_PERSONA_FISICA) {
            contractPage = Page.FSC_ContratoHipotecarioPersonaFisica;
        } else if (templateCode == TEMPLATE_HIPOTECARIO_EMPRESA) {
            contractPage = Page.FSC_ContratoHipotecarioEmpresa;
        } else if (templateCode == TEMPLATE_HIPOTECARIO_EMPRESA_LEY_158) {
            contractPage = Page.FSC_ContratoHipotecarioEmpresaLey158;
        } else if (templateCode == TEMPLATE_HIPOTECARIO_FIDEICOMISO_NORMAL) {
            contractPage = Page.FSC_ContratoHipFideicomisoNormal;
        } else if (templateCode == TEMPLATE_HIPOTECARIO_FIDEICOMISO_BAJO_COSTO) {
            contractPage = Page.FSC_ContratoHipFideicomisoBajoCosto;
        } else {
            throw new FSC_RLAContractTemplateResolverException('No existe una página para el tipo de contrato: ' + templateCode);
        }

        contractPage.getParameters().put('id', String.valueOf(residentialLoanApplicationId));
        return contractPage;
    }

    private static void validateCurrency(String currencyCode) {
        if (currencyCode != '1' && currencyCode != '2') {
            throw new FSC_RLAContractTemplateResolverException('Los contratos PYME solo pueden generarse en pesos o dólares.');
        }
    }

    private static Boolean isMortgage(String value) {
        return value.contains('INMUEBLE') || value.contains('SOLAR') || value.contains('TERRENO') ||
            value.contains('HIPOTEC') || value.contains('EDIFICIO') || value.contains('VIVIENDA') ||
            value.contains('APTO') || value.contains('HOTEL') || value.contains('ZONA FRANCA') ||
            value.contains('NAVE INDUSTRIAL');
    }

    private static Boolean isDepositCertificate(String value) {
        return value.contains('CERTIFICADOS DEPOSITOS') ||
            value.contains('CERTIFICADOS FINANCIEROS') ||
            value.contains('CERTIFICADO DE DEPOSITO') ||
            value.contains('DEPOSITOS A PLAZO') ||
            value.contains('DEPOSITO A PLAZO');
    }

    private static Boolean isVehicle(String value) {
        return value.contains('VEHICULO');
    }

    public static Boolean isMortgagePurchaseTemplate(String templateCode) {
        return templateCode == TEMPLATE_HIPOTECARIO_PERSONA_FISICA ||
            templateCode == TEMPLATE_HIPOTECARIO_EMPRESA ||
            templateCode == TEMPLATE_HIPOTECARIO_EMPRESA_LEY_158 ||
            templateCode == TEMPLATE_HIPOTECARIO_FIDEICOMISO_NORMAL ||
            templateCode == TEMPLATE_HIPOTECARIO_FIDEICOMISO_BAJO_COSTO;
    }

    private static String normalize(String value) {
        String normalized = String.isBlank(value) ? '' : value.trim().toUpperCase();
        return normalized
            .replace('Á', 'A').replace('É', 'E').replace('Í', 'I')
            .replace('Ó', 'O').replace('Ú', 'U').replace('Ü', 'U');
    }

    private static String picklistLabel(Schema.DescribeFieldResult description, String selectedValue) {
        if (String.isBlank(selectedValue)) return '';
        for (Schema.PicklistEntry entry : description.getPicklistValues()) {
            if (entry.getValue() == selectedValue) return entry.getLabel();
        }
        return selectedValue;
    }

    public class FSC_RLAContractTemplateResolverException extends Exception {}
}