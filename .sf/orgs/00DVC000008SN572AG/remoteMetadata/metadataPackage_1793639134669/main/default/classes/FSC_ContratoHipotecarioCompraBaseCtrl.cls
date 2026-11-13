public virtual without sharing class FSC_ContratoHipotecarioCompraBaseCtrl extends FSC_ContratoPrestamoComercialBaseCtrl {
    public DatosHipotecario hipotecario { get; private set; }
    public List<FSC_LoanApplicantFirmanteService.Firmante> firmantesAdicionales { get; private set; }

    public class DatosHipotecario {
        public String tipoVendedor { get; set; }
        public Boolean esPersonaFisica { get; set; }
        public Boolean esEmpresa { get; set; }
        public Boolean esFideicomiso { get; set; }
        public Boolean esLey158 { get; set; }
        public Boolean esBajoCosto { get; set; }
        public String codeudorNombre { get; set; }
        public String codeudorIdentificacion { get; set; }
        public String codeudorNacionalidad { get; set; }
        public String codeudorEstadoCivil { get; set; }
        public String codeudorDomicilio { get; set; }
        public Boolean tieneCodeudor { get; set; }
        public String vendedorNombre { get; set; }
        public String vendedorRnc { get; set; }
        public String vendedorRegistroMercantil { get; set; }
        public String vendedorNacionalidad { get; set; }
        public String vendedorEstadoCivil { get; set; }
        public String vendedorIdentificacion { get; set; }
        public String vendedorDomicilio { get; set; }
        public String vendedorRepresentanteCargo { get; set; }
        public String vendedorRepresentanteNombre { get; set; }
        public String vendedorRepresentanteNacionalidad { get; set; }
        public String vendedorRepresentanteEstadoCivil { get; set; }
        public String vendedorRepresentanteIdentificacion { get; set; }
        public String vendedorRepresentanteDomicilio { get; set; }
        public String vendedorAutorizacion { get; set; }
        public String fideicomisoNombre { get; set; }
        public String fideicomisoRnc { get; set; }
        public String fideicomisoRegistro { get; set; }
        public String fiduciariaNombre { get; set; }
        public String fiduciariaRnc { get; set; }
        public String fiduciariaRegistro { get; set; }
        public String fiduciariaDomicilio { get; set; }
        public String fiduciariaRepresentantes { get; set; }
        public String fiduciariaFirmantes { get; set; }
        public String fiduciariaAutorizacion { get; set; }
        public String promotoresGenerales { get; set; }
        public String promotoresFirmantes { get; set; }
        public String proyectoNombre { get; set; }
        public String precioVentaLetras { get; set; }
        public String precioVentaNumero { get; set; }
        public String aporteInicialLetras { get; set; }
        public String aporteInicialNumero { get; set; }
        public String fechaPagoInicial { get; set; }
        public String medioPagoInicial { get; set; }
        public String medioPagoFinanciado { get; set; }
        public String periodoTasaFijaLetras { get; set; }
        public String periodoTasaFijaNumero { get; set; }
        public Boolean tieneGaranteReal { get; set; }
        public Boolean tieneConyugeInterviniente { get; set; }
        /** Quien hipoteca el inmueble: los garantes reales o, si no hay, el propio deudor. */
        public FSC_ContratoParte propietariosGarantia { get; set; }
        public FSC_ContratoParte conyugeParte { get; set; }
        public String prestatariosGenerales { get; set; }
        public String garantesGenerales { get; set; }
        public String conyugeGenerales { get; set; }
        public String nombresFirmantesNotario { get; set; }
        public List<FSC_ContratoIntervinienteService.Interviniente> prestatarios { get; set; }
        public List<FSC_ContratoIntervinienteService.Interviniente> garantesReales { get; set; }
        public FSC_ContratoIntervinienteService.Interviniente conyuge { get; set; }
    }

    protected FSC_ContratoHipotecarioCompraBaseCtrl(
        ApexPages.StandardController standardController,
        String expectedTemplateCode
    ) {
        super(standardController, expectedTemplateCode, 0);
        initializeMortgageData((Id) standardController.getId(), expectedTemplateCode);
    }

    private void initializeMortgageData(Id rlaId, String templateCode) {
        ResidentialLoanApplication rla = [
            SELECT Id, AccountId, FSC_Datos_Contrato_Hipotecario__c, FSC_Datos_Intervinientes_Contrato__c,
                FSC_Propietario_Garantia_Hipotecaria__c, FSC_Moneda__c
            FROM ResidentialLoanApplication
            WHERE Id = :rlaId
            LIMIT 1
        ];
        Map<String, Object> values = parseValues(rla.FSC_Datos_Contrato_Hipotecario__c);
        Map<String, Object> intervenerValues = FSC_ContratoIntervinienteService.parse(rla.FSC_Datos_Intervinientes_Contrato__c);
        DatosHipotecario item = new DatosHipotecario();
        item.tipoVendedor = value(values, 'hipotecarioTipoVendedor');
        item.esPersonaFisica = templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_PERSONA_FISICA;
        item.esEmpresa = templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_EMPRESA ||
            templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_EMPRESA_LEY_158;
        item.esFideicomiso = templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_FIDEICOMISO_NORMAL ||
            templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_FIDEICOMISO_BAJO_COSTO;
        item.esLey158 = templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_EMPRESA_LEY_158;
        item.esBajoCosto = templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_FIDEICOMISO_BAJO_COSTO;
        item.prestatarios = new List<FSC_ContratoIntervinienteService.Interviniente>{
            FSC_ContratoIntervinienteService.fromPrimaryAccount(
                datos.clienteNombre,
                datos.clienteIdentificacion,
                datos.clienteNacionalidad,
                datos.clienteEstadoCivil,
                datos.clienteDomicilio,
                datos.clienteSexo
            )
        };
        List<FSC_ContratoIntervinienteService.Interviniente> coBorrowers = FSC_ContratoIntervinienteService.getApplicants(
            rlaId,
            FSC_ContratoIntervinienteService.TIPO_CODEUDOR,
            'codeudor_',
            intervenerValues,
            false
        );
        item.prestatarios.addAll(coBorrowers);
        item.tieneCodeudor = !coBorrowers.isEmpty();
        if (item.tieneCodeudor) {
            FSC_ContratoIntervinienteService.Interviniente firstCoBorrower = coBorrowers[0];
            item.codeudorNombre = firstCoBorrower.nombre;
            item.codeudorIdentificacion = firstCoBorrower.identificacion;
            item.codeudorNacionalidad = firstCoBorrower.nacionalidad;
            item.codeudorEstadoCivil = firstCoBorrower.estadoCivil;
            item.codeudorDomicilio = firstCoBorrower.domicilio;
        }
        item.prestatariosGenerales = FSC_ContratoIntervinienteService.joinGenerales(item.prestatarios);
        item.tieneGaranteReal = rla.FSC_Propietario_Garantia_Hipotecaria__c == FSC_HipotecarioDocumentoResolver.PROPIETARIO_DISTINTO;
        item.garantesReales = item.tieneGaranteReal
            ? FSC_ContratoIntervinienteService.getApplicants(
                rlaId,
                FSC_ContratoIntervinienteService.TIPO_GARANTE,
                'garanteContrato_',
                intervenerValues,
                true
            )
            : new List<FSC_ContratoIntervinienteService.Interviniente>();
        item.garantesGenerales = FSC_ContratoIntervinienteService.joinGenerales(item.garantesReales);
        deudor = FSC_ContratoParte.crear(
            'PRESTATARIO - COMPRADOR',
            FSC_ContratoIntervinienteService.sexes(item.prestatarios),
            !datos.esPersonaFisica
        );
        sujetoGeneral = deudor;
        item.propietariosGarantia = item.tieneGaranteReal
            ? FSC_ContratoParte.crear('COMPRADOR - GARANTE REAL', FSC_ContratoIntervinienteService.sexes(item.garantesReales), false)
            : deudor;
        item.tieneConyugeInterviniente = value(intervenerValues, 'hipotecarioConyugeInterviniente') == 'Sí';
        item.conyuge = item.tieneConyugeInterviniente
            ? FSC_ContratoIntervinienteService.getConyuge(rla.AccountId, intervenerValues)
            : null;
        item.conyugeGenerales = item.conyuge == null ? '' : item.conyuge.generales;
        item.conyugeParte = FSC_ContratoParte.crear('CÓNYUGE - INTERVINIENTE', item.conyuge == null ? null : item.conyuge.sexo, false);
        item.vendedorNombre = value(values, 'hipotecarioVendedorNombre');
        item.vendedorRnc = value(values, 'hipotecarioVendedorRnc');
        item.vendedorRegistroMercantil = value(values, 'hipotecarioVendedorRegistroMercantil');
        item.vendedorNacionalidad = value(values, 'hipotecarioVendedorNacionalidad');
        item.vendedorEstadoCivil = value(values, 'hipotecarioVendedorEstadoCivil');
        item.vendedorIdentificacion = value(values, 'hipotecarioVendedorIdentificacion');
        item.vendedorDomicilio = value(values, 'hipotecarioVendedorDomicilio');
        item.vendedorRepresentanteCargo = value(values, 'hipotecarioVendedorRepresentanteCargo');
        item.vendedorRepresentanteNombre = value(values, 'hipotecarioVendedorRepresentanteNombre');
        item.vendedorRepresentanteNacionalidad = value(values, 'hipotecarioVendedorRepresentanteNacionalidad');
        item.vendedorRepresentanteEstadoCivil = value(values, 'hipotecarioVendedorRepresentanteEstadoCivil');
        item.vendedorRepresentanteIdentificacion = value(values, 'hipotecarioVendedorRepresentanteIdentificacion');
        item.vendedorRepresentanteDomicilio = value(values, 'hipotecarioVendedorRepresentanteDomicilio');
        item.vendedorAutorizacion = value(values, 'hipotecarioVendedorAutorizacion');
        item.fideicomisoNombre = value(values, 'hipotecarioFideicomisoNombre');
        item.fideicomisoRnc = value(values, 'hipotecarioFideicomisoRnc');
        item.fideicomisoRegistro = value(values, 'hipotecarioFideicomisoRegistro');
        item.fiduciariaNombre = value(values, 'hipotecarioFiduciariaNombre');
        item.fiduciariaRnc = value(values, 'hipotecarioFiduciariaRnc');
        item.fiduciariaRegistro = value(values, 'hipotecarioFiduciariaRegistro');
        item.fiduciariaDomicilio = value(values, 'hipotecarioFiduciariaDomicilio');
        item.fiduciariaRepresentantes = value(values, 'hipotecarioFiduciariaRepresentantes');
        item.fiduciariaFirmantes = value(values, 'hipotecarioFiduciariaFirmantes');
        item.fiduciariaAutorizacion = value(values, 'hipotecarioFiduciariaAutorizacion');
        item.promotoresGenerales = value(values, 'hipotecarioPromotoresGenerales');
        item.promotoresFirmantes = value(values, 'hipotecarioPromotoresFirmantes');
        item.proyectoNombre = value(values, 'hipotecarioProyectoNombre');
        Decimal salePrice = decimalValue(values, 'hipotecarioPrecioVenta');
        Decimal downPayment = decimalValue(values, 'hipotecarioAporteInicial');
        item.precioVentaLetras = FSC_ContratoFormatoService.montoEnLetras(salePrice, rla.FSC_Moneda__c);
        item.precioVentaNumero = FSC_ContratoFormatoService.formatearMonto(salePrice);
        item.aporteInicialLetras = FSC_ContratoFormatoService.montoEnLetras(downPayment, rla.FSC_Moneda__c);
        item.aporteInicialNumero = FSC_ContratoFormatoService.formatearMonto(downPayment);
        item.fechaPagoInicial = formatDate(value(values, 'hipotecarioFechaPagoInicial'));
        item.medioPagoInicial = value(values, 'hipotecarioMedioPagoInicial');
        item.medioPagoFinanciado = value(values, 'hipotecarioMedioPagoFinanciado');
        Decimal fixedRateMonths = decimalValue(values, 'hipotecarioPeriodoTasaFija');
        item.periodoTasaFijaNumero = fixedRateMonths == null ? '' : String.valueOf(fixedRateMonths.intValue());
        item.periodoTasaFijaLetras = fixedRateMonths == null
            ? ''
            : FSC_ContratoFormatoService.numeroMasculinoEnLetras(fixedRateMonths.longValue()).toLowerCase();

        List<String> signerNames = new List<String>{ FSC_ContratoIntervinienteService.joinNames(item.prestatarios) };
        if (item.tieneGaranteReal) signerNames.add(FSC_ContratoIntervinienteService.joinNames(item.garantesReales));
        if (item.tieneConyugeInterviniente) signerNames.add(item.conyuge.nombre);
        if (item.esPersonaFisica) signerNames.add(item.vendedorNombre);
        if (item.esEmpresa) signerNames.add(item.vendedorRepresentanteNombre);
        if (item.esFideicomiso) {
            signerNames.add(item.fiduciariaFirmantes);
            signerNames.add(item.promotoresFirmantes);
        }
        signerNames.add(datos.bancoRepresentante1.nombreCompleto);
        signerNames.add(datos.bancoRepresentante2.nombreCompleto);
        item.nombresFirmantesNotario = joinNames(signerNames);
        hipotecario = item;
        firmantesAdicionales = FSC_LoanApplicantFirmanteService.queryFirmantes(rlaId);
    }

    private static Map<String, Object> parseValues(String jsonValue) {
        if (String.isBlank(jsonValue)) return new Map<String, Object>();
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(jsonValue);
        } catch (Exception ignored) {
            return new Map<String, Object>();
        }
    }

    private static String value(Map<String, Object> values, String key) {
        return values.containsKey(key) && values.get(key) != null ? String.valueOf(values.get(key)).trim() : '';
    }

    private static String joinNames(List<String> names) {
        List<String> filtered = new List<String>();
        for (String name : names) if (!String.isBlank(name)) filtered.add(name);
        if (filtered.size() <= 1) return String.join(filtered, '');
        String lastName = filtered.remove(filtered.size() - 1);
        return String.join(filtered, ', ') + ' y ' + lastName;
    }

    private static Decimal decimalValue(Map<String, Object> values, String key) {
        String rawValue = value(values, key);
        if (String.isBlank(rawValue)) return null;
        try {
            return Decimal.valueOf(rawValue);
        } catch (Exception ignored) {
            return null;
        }
    }

    private static String formatDate(String rawDate) {
        if (String.isBlank(rawDate)) return '';
        try {
            return FSC_ContratoFormatoService.fechaCortaEnLetras(Date.valueOf(rawDate));
        } catch (Exception ignored) {
            return rawDate;
        }
    }
}