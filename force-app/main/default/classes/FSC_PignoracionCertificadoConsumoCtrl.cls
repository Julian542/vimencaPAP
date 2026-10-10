public without sharing class FSC_PignoracionCertificadoConsumoCtrl {
    public ResidentialLoanApplication rla { get; private set; }
    public Boolean propietarioDistinto { get; private set; }
    public String nombreTitularPrestamo { get; private set; }
    public String identificacionTitularPrestamo { get; private set; }
    public String nombreTitularCertificado { get; private set; }
    public String identificacionTitularCertificado { get; private set; }
    public String numeroCertificado { get; private set; }
    public String numeroFisico { get; private set; }
    public String montoCertificadoLetras { get; private set; }
    public String montoCertificadoNumero { get; private set; }
    public String simboloCertificado { get; private set; }
    public String montoPrestamoLetras { get; private set; }
    public String montoPrestamoNumero { get; private set; }
    public String simboloPrestamo { get; private set; }
    public String diaLetras { get; private set; }
    public String diaNumero { get; private set; }
    public String mes { get; private set; }
    public String anoLetras { get; private set; }
    public String anoNumero { get; private set; }
    public String fechaNumero { get; private set; }
    public String lugarOtorgamiento { get; private set; }
    public String nombreEjecutivo { get; private set; }
    public String cargoEjecutivo { get; private set; }

    public FSC_PignoracionCertificadoConsumoCtrl(ApexPages.StandardController standardController) {
        Id rlaId = standardController == null
            ? (Id) ApexPages.currentPage().getParameters().get('id')
            : standardController.getId();
        if (rlaId == null) {
            throw new PignoracionException('Se requiere la solicitud de crédito.');
        }

        rla = [
            SELECT Id, Account.Name, Account.ACC_NumIdentificacion__c,
                FSC_Identificacion_Cliente_Contrato__c, FSC_MontoAprobado__c, FSC_Monto__c,
                FSC_Moneda__c, FSC_Relacion_Propietario_CD__c, FSC_Numero_Fisico_CD__c,
                FSC_Identificacion_Propietario_CD__c, FSC_Lugar_Pignoracion_CD__c,
                FSC_Nombre_Ejecutivo_Pignoracion__c, FSC_Cargo_Ejecutivo_Pignoracion__c,
                CreatedBy.Name, CreatedBy.Title
            FROM ResidentialLoanApplication
            WHERE Id = :rlaId
            LIMIT 1
        ];

        FSC_ConsumoDocumentoResolver.ResolucionDocumento resolution =
            FSC_ConsumoDocumentoResolver.resolve(rlaId);
        if (resolution.tipoGarantia != FSC_ConsumoDocumentoResolver.GARANTIA_CD || resolution.garantiaId == null) {
            throw new PignoracionException('La solicitud no tiene un certificado de depósito relacionado.');
        }

        FSC_Garantia__c guarantee = [
            SELECT FSC_Numero_Certificado_Deposito__c, FSC_Titular_Certificado_Deposito__c,
                FSC_Monto_Certificado_Deposito__c, FSC_Moneda_Certificado_Deposito__c
            FROM FSC_Garantia__c
            WHERE Id = :resolution.garantiaId
            LIMIT 1
        ];

        propietarioDistinto = rla.FSC_Relacion_Propietario_CD__c == 'Persona distinta';
        nombreTitularPrestamo = rla.Account.Name;
        identificacionTitularPrestamo = first(
            rla.FSC_Identificacion_Cliente_Contrato__c,
            rla.Account.ACC_NumIdentificacion__c
        );
        nombreTitularCertificado = first(guarantee.FSC_Titular_Certificado_Deposito__c, nombreTitularPrestamo);
        identificacionTitularCertificado = propietarioDistinto
            ? rla.FSC_Identificacion_Propietario_CD__c
            : identificacionTitularPrestamo;
        numeroCertificado = guarantee.FSC_Numero_Certificado_Deposito__c;
        numeroFisico = rla.FSC_Numero_Fisico_CD__c;

        String certificateCurrencyCode = currencyCode(guarantee.FSC_Moneda_Certificado_Deposito__c, rla.FSC_Moneda__c);
        montoCertificadoLetras = FSC_ContratoFormatoService.montoEnLetras(
            guarantee.FSC_Monto_Certificado_Deposito__c,
            certificateCurrencyCode
        );
        montoCertificadoNumero = FSC_ContratoFormatoService.formatearMonto(guarantee.FSC_Monto_Certificado_Deposito__c);
        simboloCertificado = FSC_ContratoFormatoService.simboloMoneda(certificateCurrencyCode);

        Decimal loanAmount = rla.FSC_MontoAprobado__c == null ? rla.FSC_Monto__c : rla.FSC_MontoAprobado__c;
        montoPrestamoLetras = FSC_ContratoFormatoService.montoEnLetras(loanAmount, rla.FSC_Moneda__c);
        montoPrestamoNumero = FSC_ContratoFormatoService.formatearMonto(loanAmount);
        simboloPrestamo = FSC_ContratoFormatoService.simboloMoneda(rla.FSC_Moneda__c);

        Date generationDate = resolveGenerationDate();
        diaLetras = FSC_ContratoFormatoService.numeroMasculinoEnLetras(generationDate.day()).toLowerCase();
        diaNumero = String.valueOf(generationDate.day());
        mes = FSC_ContratoFormatoService.mes(generationDate.month());
        anoLetras = FSC_ContratoFormatoService.numeroEnLetras(generationDate.year()).toLowerCase();
        anoNumero = String.valueOf(generationDate.year());
        fechaNumero = generationDate.format();
        lugarOtorgamiento = rla.FSC_Lugar_Pignoracion_CD__c;
        nombreEjecutivo = first(rla.FSC_Nombre_Ejecutivo_Pignoracion__c, rla.CreatedBy.Name);
        cargoEjecutivo = first(rla.FSC_Cargo_Ejecutivo_Pignoracion__c, rla.CreatedBy.Title);

    }

    private static Date resolveGenerationDate() {
        String rawValue = ApexPages.currentPage().getParameters().get('fechaDocumento');
        return String.isBlank(rawValue) ? Date.today() : Date.valueOf(rawValue);
    }

    private static String currencyCode(String certificateCurrency, String fallbackCode) {
        String normalized = String.isBlank(certificateCurrency) ? '' : certificateCurrency.toUpperCase();
        if (normalized.contains('DOLAR') || normalized.contains('DÓLAR') || normalized.contains('USD') || normalized.contains('US$')) {
            return '2';
        }
        if (normalized.contains('PESO') || normalized.contains('RD$')) {
            return '1';
        }
        return fallbackCode;
    }

    private static String first(String firstValue, String secondValue) {
        return String.isBlank(firstValue) ? secondValue : firstValue;
    }

    public class PignoracionException extends Exception {}
}