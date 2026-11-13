public virtual without sharing class FSC_ContratoPrestamoComercialBaseCtrl {
    public DatosDocumento datos { get; private set; }
    public ResidentialLoanApplication loanApplication { get; private set; }
    public Map<String, String> mergeFields { get; private set; }
    public Boolean esDolares { get; private set; }
    /** Parte deudora tal como se denomina en el contrato (EL PRESTATARIO, LA PRESTATARIA, LOS PRESTATARIOS...). */
    public FSC_ContratoParte deudor { get; protected set; }
    /** Garante solidario del contrato comercial con garantía solidaria. */
    public FSC_ContratoParte garante { get; protected set; }
    /** Sujeto de los artículos generales (deudor, o deudor y garante cuando ambos se obligan). */
    public FSC_ContratoParte sujetoGeneral { get; protected set; }
    public FSC_ContratoSeguro seguroVida { get; private set; }
    public FSC_ContratoSeguro seguroPropiedad { get; private set; }
    public Boolean garantiaInmueble { get; private set; }
    public String clienteGenerales { get; private set; }
    public String garanteGenerales { get; private set; }
    /** Quienes firman por el deudor: la persona física o los representantes de la empresa. */
    public List<String> firmantesCliente { get; private set; }

    public Boolean getHasAnnexImage() {
        return true;
    }

    public String getAnnexImageUrl() {
        return '/resource/FSC_ContratoPrestamoComercial_Anexo';
    }

    public class DatosDocumento {
        public Id rlaId { get; set; }
        public String tipoContrato { get; set; }
        public String tituloContrato { get; set; }
        public Boolean esPersonaFisica { get; set; }
        public String clienteNombre { get; set; }
        public String clienteRnc { get; set; }
        public String clienteRegistroMercantil { get; set; }
        public String clienteIdentificacion { get; set; }
        public String clienteNacionalidad { get; set; }
        public String clienteEstadoCivil { get; set; }
        public String clienteDomicilio { get; set; }
        public String clienteSexo { get; set; }
        public String representanteNombre { get; set; }
        public String representanteCargo { get; set; }
        public String representanteNacionalidad { get; set; }
        public String representanteEstadoCivil { get; set; }
        public String representanteIdentificacion { get; set; }
        public String representanteDomicilio { get; set; }
        public String autorizacionResolucion { get; set; }
        public String autorizacionFecha { get; set; }
        public String autorizacionPersonas { get; set; }
        public String autorizacionCalidad { get; set; }
        public String garanteNombre { get; set; }
        public String garanteIdentificacion { get; set; }
        public String garanteNacionalidad { get; set; }
        public String garanteEstadoCivil { get; set; }
        public String garanteDomicilio { get; set; }
        public String oficialNegocio { get; set; }
        public FSC_ContratoParticipanteService.Participante bancoRepresentante1 { get; set; }
        public FSC_ContratoParticipanteService.Participante bancoRepresentante2 { get; set; }
        public FSC_ContratoParticipanteService.Participante notario { get; set; }
        public String montoLetras { get; set; }
        public String montoNumero { get; set; }
        public String cuotaLetras { get; set; }
        public String cuotaNumero { get; set; }
        public String simboloMoneda { get; set; }
        public String nombreMoneda { get; set; }
        public String tasaLetras { get; set; }
        public String tasaNumero { get; set; }
        public String plazoLetras { get; set; }
        public String plazoNumero { get; set; }
        public String destinoPrestamo { get; set; }
        public String fechaContrato { get; set; }
        public String fechaContratoDiaLetras { get; set; }
        public String fechaContratoDiaNumero { get; set; }
        public String fechaContratoMes { get; set; }
        public String fechaContratoAnoLetras { get; set; }
        public String fechaContratoAnoNumero { get; set; }
        public String fechaVencimiento { get; set; }
        public String garantiaDescripcion { get; set; }
        public String garantiaNumeroTitulo { get; set; }
        public String garantiaRegistroTitulos { get; set; }
        public String garantiaFechaTitulo { get; set; }
        public String vehiculoDescripcion { get; set; }
        public String vehiculoValorLetras { get; set; }
        public String vehiculoValorNumero { get; set; }
        public String vehiculoUbicacion { get; set; }
        public String certificadoDescripcion { get; set; }
        public String certificadoNombreMoneda { get; set; }
        public String nombresFirmantesNotario { get; set; }
        public String lugarFirma { get; set; }
        public String referenciaLegal { get; set; }
    }

    protected FSC_ContratoPrestamoComercialBaseCtrl(
        ApexPages.StandardController standardController,
        String expectedTemplateCode,
        Integer legacyPlaceholderCount
    ) {
        initializeLegacyPlaceholders(legacyPlaceholderCount);
        Id rlaId = resolveRlaId(standardController);
        if (rlaId == null) return;
        FSC_RLAContractTemplateResolver.ContractResolution resolution =
            FSC_RLAContractTemplateResolver.resolve(rlaId);
        if (!resolution.aplicaContrato || resolution.templateCode != expectedTemplateCode) {
            throw new FSC_ContratoPrestamoComercialException('El contrato solicitado no corresponde a la solicitud.');
        }

        FSC_DatosContratoController.ContextoGeneracion context =
            FSC_DatosContratoController.getContextoGeneracion(rlaId);
        validateContext(context);
        Map<String, String> values = flattenValues(context);
        ResidentialLoanApplication rla = queryRla(rlaId);
        loanApplication = rla;
        esDolares = rla.FSC_Moneda__c == '2';
        Date contractDate = resolveContractDate(rla.FSC_Fecha_Contrato__c);

        FSC_ContratoParticipanteService.ParticipantesContrato participants =
            FSC_ContratoParticipanteService.getParticipantes(resolution.tipoContrato);
        datos = buildDocumentData(rla, resolution, participants, values, contractDate);
        initializeDrafting(rla, resolution.templateCode, values);
    }

    private void initializeDrafting(ResidentialLoanApplication rla, String templateCode, Map<String, String> values) {
        deudor = FSC_ContratoParte.crear(
            FSC_RLAContractTemplateResolver.isMortgagePurchaseTemplate(templateCode) ? 'PRESTATARIO - COMPRADOR' : 'PRESTATARIO',
            get(values, 'clienteSexo'),
            !datos.esPersonaFisica
        );
        sujetoGeneral = deudor;
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_SOLIDARIA) {
            garante = FSC_ContratoParte.crear('GARANTE SOLIDARIO', get(values, 'garanteSexo'), false);
            sujetoGeneral = FSC_ContratoParte.combinar(deudor, garante);
            garanteGenerales = FSC_ContratoRedaccionService.generalesPersona(
                datos.garanteNombre,
                get(values, 'garanteSexo'),
                datos.garanteNacionalidad,
                datos.garanteEstadoCivil,
                datos.garanteIdentificacion,
                datos.garanteDomicilio
            );
        }
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_CONSUMO_GARANTIA_HIPOTECARIA) {
            // En consumo con garantía hipotecaria el mismo cliente hipoteca su inmueble.
            garante = FSC_ContratoParte.crear('GARANTE REAL', get(values, 'clienteSexo'), !datos.esPersonaFisica);
        }
        clienteGenerales = datos.esPersonaFisica
            ? FSC_ContratoRedaccionService.generalesPersona(
                datos.clienteNombre,
                get(values, 'clienteSexo'),
                datos.clienteNacionalidad,
                datos.clienteEstadoCivil,
                datos.clienteIdentificacion,
                datos.clienteDomicilio
            )
            : FSC_ContratoRedaccionService.generalesEmpresa(
                datos.clienteNombre,
                datos.clienteRnc,
                datos.clienteRegistroMercantil,
                datos.clienteDomicilio,
                representatives(values)
            );
        garantiaInmueble = FSC_ContratoRedaccionService.esPlantillaInmueble(templateCode);
        firmantesCliente = new List<String>();
        if (datos.esPersonaFisica) {
            firmantesCliente.add(datos.clienteNombre);
        } else {
            for (FSC_ContratoRedaccionService.Representante item : representatives(values)) {
                if (!String.isBlank(item.nombre)) firmantesCliente.add(item.nombre);
            }
        }
        List<String> signerNames = new List<String>(firmantesCliente);
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_SOLIDARIA) signerNames.add(datos.garanteNombre);
        signerNames.add(datos.bancoRepresentante1.nombreCompleto);
        signerNames.add(datos.bancoRepresentante2.nombreCompleto);
        datos.nombresFirmantesNotario = joinNames(signerNames);

        Integer months = loanMonths(rla);
        String propertyType = FSC_ContratoRedaccionService.tipoSeguroPropiedad(templateCode);
        seguroPropiedad = propertyType == null
            ? FSC_ContratoSeguro.noAplica(null)
            : FSC_ContratoSeguro.crear(
                propertyType,
                get(values, 'seguroPoliza'),
                get(values, 'seguroAseguradora'),
                get(values, 'seguroDireccion'),
                dateInput(values, 'seguroFechaEndoso'),
                decimalInput(values, 'seguroMonto'),
                decimalInput(values, 'seguroPrima'),
                months,
                rla.FSC_Moneda__c
            );
        seguroVida = FSC_ContratoRedaccionService.aplicaSeguroVida(datos.esPersonaFisica, templateCode)
            ? FSC_ContratoSeguro.crear(
                FSC_ContratoSeguro.TIPO_VIDA,
                get(values, 'seguroVidaPoliza'),
                get(values, 'seguroVidaAseguradora'),
                get(values, 'seguroVidaDireccion'),
                dateInput(values, 'seguroVidaFechaEndoso'),
                decimalInput(values, 'seguroVidaMonto'),
                decimalInput(values, 'seguroVidaPrima'),
                months,
                rla.FSC_Moneda__c
            )
            : FSC_ContratoSeguro.noAplica(FSC_ContratoSeguro.TIPO_VIDA);
    }

    private static List<FSC_ContratoRedaccionService.Representante> representatives(Map<String, String> values) {
        List<FSC_ContratoRedaccionService.Representante> result = new List<FSC_ContratoRedaccionService.Representante>{
            representative(values, 'representante')
        };
        for (String prefix : new List<String>{ 'representante2_', 'representante3_' }) {
            if (!String.isBlank(get(values, prefix + 'nombre'))) result.add(representative(values, prefix));
        }
        return result;
    }

    // Representante principal: claves 'representanteNombre'...; adicionales: 'representante2_nombre'...
    private static FSC_ContratoRedaccionService.Representante representative(Map<String, String> values, String prefix) {
        Boolean principal = prefix == 'representante';
        FSC_ContratoRedaccionService.Representante item = new FSC_ContratoRedaccionService.Representante();
        item.nombre = get(values, prefix + (principal ? 'Nombre' : 'nombre'));
        item.cargo = get(values, prefix + (principal ? 'Cargo' : 'cargo'));
        item.sexo = get(values, prefix + (principal ? 'Sexo' : 'sexo'));
        item.nacionalidad = get(values, prefix + (principal ? 'Nacionalidad' : 'nacionalidad'));
        item.estadoCivil = get(values, prefix + (principal ? 'EstadoCivil' : 'estadoCivil'));
        item.identificacion = get(values, prefix + (principal ? 'Identificacion' : 'identificacion'));
        item.domicilio = get(values, prefix + (principal ? 'Domicilio' : 'domicilio'));
        return item;
    }

    private static Integer loanMonths(ResidentialLoanApplication rla) {
        Decimal monthsValue = rla.FSC_PlazoMesesAprobado__c;
        if (monthsValue == null && !String.isBlank(rla.FSC_Plazo_meses__c)) {
            monthsValue = Decimal.valueOf(rla.FSC_Plazo_meses__c);
        }
        return monthsValue == null ? null : monthsValue.intValue();
    }

    public String getPlaceholderValue(String key) {
        return mergeFields != null && mergeFields.containsKey(key) ? mergeFields.get(key) : '';
    }

    private void initializeLegacyPlaceholders(Integer placeholderCount) {
        mergeFields = new Map<String, String>();
        for (Integer index = 1; index <= placeholderCount; index++) {
            String key = 'p' + String.valueOf(index).leftPad(3, '0');
            mergeFields.put(key, '[' + key + ']');
        }
    }

    private static DatosDocumento buildDocumentData(
        ResidentialLoanApplication rla,
        FSC_RLAContractTemplateResolver.ContractResolution resolution,
        FSC_ContratoParticipanteService.ParticipantesContrato participants,
        Map<String, String> values,
        Date contractDate
    ) {
        DatosDocumento data = new DatosDocumento();
        Decimal amount = rla.FSC_MontoAprobado__c == null ? rla.FSC_Monto__c : rla.FSC_MontoAprobado__c;
        Decimal rate = rla.FSC_TasaInteresAprobada__c == null ? rla.FSC_TasaInteres__c : rla.FSC_TasaInteresAprobada__c;
        Integer months = loanMonths(rla);
        Decimal payment = FSC_ContratoFormatoService.calcularCuota(amount, rate, months);
        Date expirationDate = months == null ? contractDate : contractDate.addMonths(months);

        data.rlaId = rla.Id;
        data.tipoContrato = resolution.templateCode;
        data.tituloContrato = displayTitle(resolution.templateCode);
        data.esPersonaFisica = rla.Account.IsPersonAccount;
        data.clienteNombre = rla.Account.Name;
        data.clienteRnc = get(values, 'clienteRnc');
        data.clienteRegistroMercantil = get(values, 'clienteRegistroMercantil');
        data.clienteIdentificacion = get(values, 'clienteIdentificacion');
        data.clienteNacionalidad = get(values, 'clienteNacionalidad');
        data.clienteEstadoCivil = get(values, 'clienteEstadoCivil');
        data.clienteDomicilio = get(values, 'clienteDomicilio');
        data.clienteSexo = get(values, 'clienteSexo');
        data.representanteNombre = get(values, 'representanteNombre');
        data.representanteCargo = get(values, 'representanteCargo');
        data.representanteNacionalidad = get(values, 'representanteNacionalidad');
        data.representanteEstadoCivil = get(values, 'representanteEstadoCivil');
        data.representanteIdentificacion = get(values, 'representanteIdentificacion');
        data.representanteDomicilio = get(values, 'representanteDomicilio');
        data.autorizacionResolucion = get(values, 'autorizacionResolucion');
        data.autorizacionFecha = formatInputDate(get(values, 'autorizacionFecha'));
        data.autorizacionPersonas = get(values, 'autorizacionPersonas');
        data.autorizacionCalidad = get(values, 'autorizacionCalidad');
        data.garanteNombre = get(values, 'garanteNombre');
        data.garanteIdentificacion = get(values, 'garanteIdentificacion');
        data.garanteNacionalidad = get(values, 'garanteNacionalidad');
        data.garanteEstadoCivil = get(values, 'garanteEstadoCivil');
        data.garanteDomicilio = get(values, 'garanteDomicilio');
        data.oficialNegocio = rla.CreatedBy.Name;
        data.bancoRepresentante1 = participants.representanteBanco1;
        data.bancoRepresentante2 = participants.representanteBanco2;
        data.notario = participants.notario;

        data.simboloMoneda = FSC_ContratoFormatoService.simboloMoneda(rla.FSC_Moneda__c);
        data.nombreMoneda = FSC_ContratoFormatoService.nombreMoneda(rla.FSC_Moneda__c);
        data.montoLetras = FSC_ContratoFormatoService.montoEnLetras(amount, rla.FSC_Moneda__c);
        data.montoNumero = FSC_ContratoFormatoService.formatearMonto(amount);
        data.cuotaLetras = FSC_ContratoFormatoService.montoEnLetras(payment, rla.FSC_Moneda__c);
        data.cuotaNumero = FSC_ContratoFormatoService.formatearMonto(payment);
        data.tasaLetras = FSC_ContratoFormatoService.decimalEnLetras(rate);
        data.tasaNumero = decimalDisplay(rate);
        data.plazoLetras = FSC_ContratoFormatoService.numeroMasculinoEnLetras(months).toLowerCase();
        data.plazoNumero = String.valueOf(months);
        data.destinoPrestamo = String.isBlank(rla.FSC_Destino_del_Prestamo__c)
            ? rla.FSC_DescripcionPropositoFacilidad__c
            : rla.FSC_Destino_del_Prestamo__c;
        data.fechaContrato = FSC_ContratoFormatoService.fechaCompleta(contractDate);
        data.fechaContratoDiaLetras = FSC_ContratoFormatoService.numeroMasculinoEnLetras(contractDate.day()).toLowerCase();
        data.fechaContratoDiaNumero = String.valueOf(contractDate.day()).leftPad(2, '0');
        data.fechaContratoMes = FSC_ContratoFormatoService.mes(contractDate.month());
        data.fechaContratoAnoLetras = FSC_ContratoFormatoService.numeroEnLetras(contractDate.year()).toLowerCase();
        data.fechaContratoAnoNumero = String.valueOf(contractDate.year());
        data.fechaVencimiento = FSC_ContratoFormatoService.fechaCortaEnLetras(expirationDate);

        data.garantiaDescripcion = get(values, 'garantiaDescripcion');
        data.garantiaNumeroTitulo = get(values, 'garantiaNumeroTitulo');
        data.garantiaRegistroTitulos = get(values, 'garantiaRegistroTitulos');
        data.garantiaFechaTitulo = formatInputDate(get(values, 'garantiaFechaTitulo'));
        data.vehiculoDescripcion = buildVehicleDescription(values);
        Decimal vehicleValue = decimalInput(values, 'vehiculoValor');
        data.vehiculoValorLetras = FSC_ContratoFormatoService.montoEnLetras(vehicleValue, rla.FSC_Moneda__c);
        data.vehiculoValorNumero = FSC_ContratoFormatoService.formatearMonto(vehicleValue);
        data.vehiculoUbicacion = get(values, 'vehiculoUbicacion');
        data.certificadoDescripcion = buildCertificateDescription(values);
        data.certificadoNombreMoneda = get(values, 'certificadoMoneda').toLowerCase();
        data.lugarFirma = participants.notario.lugarFirma;
        data.referenciaLegal = legalReference(resolution.templateCode) + ' / ' + data.clienteNombre + ' / ' + rla.Id;
        return data;
    }

    private static ResidentialLoanApplication queryRla(Id rlaId) {
        return [
            SELECT Id, FSC_MontoAprobado__c, FSC_Monto__c, FSC_PlazoMesesAprobado__c,
                FSC_Plazo_meses__c, FSC_TasaInteresAprobada__c, FSC_TasaInteres__c,
                FSC_Destino_del_Prestamo__c, FSC_DescripcionPropositoFacilidad__c,
                FSC_Moneda__c, FSC_Fecha_Contrato__c,
                CreatedBy.Name, Account.Name, Account.IsPersonAccount
            FROM ResidentialLoanApplication
            WHERE Id = :rlaId
            LIMIT 1
        ];
    }

    private static void validateContext(FSC_DatosContratoController.ContextoGeneracion context) {
        List<String> errors = new List<String>();
        errors.addAll(context.erroresConfiguracion);
        errors.addAll(FSC_DatosContratoController.validarDatosCombinados(context));
        for (FSC_DatosContratoController.SeccionEntrada section : context.seccionesContrato) {
            for (FSC_DatosContratoController.CampoEntrada field : section.campos) {
                if (field.requerido && String.isBlank(field.valor)) errors.add('Falta ' + field.etiqueta + '.');
            }
        }
        if (!errors.isEmpty()) {
            throw new FSC_ContratoPrestamoComercialException(String.join(errors, ' | '));
        }
    }

    private static Map<String, String> flattenValues(FSC_DatosContratoController.ContextoGeneracion context) {
        Map<String, String> values = new Map<String, String>();
        for (FSC_DatosContratoController.SeccionEntrada section : context.seccionesContrato) {
            for (FSC_DatosContratoController.CampoEntrada field : section.campos) values.put(field.clave, field.valor);
        }
        return values;
    }

    private static Id resolveRlaId(ApexPages.StandardController standardController) {
        if (standardController != null && standardController.getId() != null) return standardController.getId();
        String idParameter = ApexPages.currentPage() == null ? null : ApexPages.currentPage().getParameters().get('id');
        if (String.isBlank(idParameter)) return null;
        try {
            return (Id) idParameter;
        } catch (Exception error) {
            return null;
        }
    }

    private static Date resolveContractDate(Date storedDate) {
        String dateParameter = ApexPages.currentPage() == null
            ? null
            : ApexPages.currentPage().getParameters().get('fechaContrato');
        if (!String.isBlank(dateParameter)) return Date.valueOf(dateParameter);
        return storedDate == null ? Date.today() : storedDate;
    }

    private static String buildVehicleDescription(Map<String, String> values) {
        return 'Tipo ' + get(values, 'vehiculoTipo') + ', marca ' + get(values, 'vehiculoMarca') +
            ', modelo ' + get(values, 'vehiculoModelo') + ', año ' + get(values, 'vehiculoAno') +
            ', color ' + get(values, 'vehiculoColor') + ', chasis No. ' + get(values, 'vehiculoChasis') +
            ', motor No. ' + get(values, 'vehiculoMotor') + ', placa No. ' + get(values, 'vehiculoPlaca') +
            ' y matrícula No. ' + get(values, 'vehiculoMatricula') + '.';
    }

    private static String buildCertificateDescription(Map<String, String> values) {
        String certificateCurrency = get(values, 'certificadoMoneda');
        String currencyCode = certificateCurrency != null && certificateCurrency.toLowerCase().contains('dólar') ? '2' : '1';
        Decimal certificateAmount = decimalInput(values, 'certificadoMonto');
        Date certificateDate = dateInput(values, 'certificadoFecha');
        return 'Certificado de depósito No. ' + get(values, 'certificadoNumero') + ', de fecha ' +
            FSC_ContratoFormatoService.fechaCortaEnLetras(certificateDate) + ', expedido por ' +
            get(values, 'certificadoEmisor') + ', a favor de ' + get(values, 'certificadoTitular') +
            ', por un monto de ' + FSC_ContratoFormatoService.montoEnLetras(certificateAmount, currencyCode) +
            ' (' + FSC_ContratoFormatoService.simboloMoneda(currencyCode) +
            FSC_ContratoFormatoService.formatearMonto(certificateAmount) + ').';
    }

    private static String displayTitle(String templateCode) {
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_PERSONA_FISICA ||
            templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_EMPRESA ||
            templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_EMPRESA_LEY_158) {
            return 'CONTRATO DE PRÉSTAMO CON GARANTÍA HIPOTECARIA Y COMPRA DE INMUEBLE';
        }
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_FIDEICOMISO_NORMAL ||
            templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_HIPOTECARIO_FIDEICOMISO_BAJO_COSTO) {
            return 'CONTRATO DE PRÉSTAMO CON GARANTÍA HIPOTECARIA Y COMPRA DE INMUEBLE CON FIDUCIARIA';
        }
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_CONSUMO_GARANTIA_HIPOTECARIA) return 'CONTRATO DE PRÉSTAMO DE CONSUMO CON GARANTÍA HIPOTECARIA';
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_CONSUMO_GARANTIA_MOBILIARIA) return 'CONTRATO DE PRÉSTAMO DE CONSUMO CON GARANTÍA MOBILIARIA';
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_SOLA_FIRMA) return 'CONTRATO DE PRÉSTAMO COMERCIAL A CUOTAS A SOLA FIRMA';
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_HIPOTECARIA) return 'CONTRATO DE PRÉSTAMO COMERCIAL A CUOTAS CON GARANTÍA HIPOTECARIA';
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_SOLIDARIA) return 'CONTRATO DE PRÉSTAMO COMERCIAL A CUOTAS CON GARANTÍA SOLIDARIA';
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION) return 'CONTRATO DE PRÉSTAMO COMERCIAL A CUOTAS CON GARANTÍA MOBILIARIA CON POSESIÓN (CERTIFICADO DE DEPÓSITO)';
        return 'CONTRATO DE PRÉSTAMO COMERCIAL A CUOTAS CON GARANTÍA MOBILIARIA SIN POSESIÓN (VEHÍCULOS, MAQUINARIAS Y EQUIPOS)';
    }

    private static String legalReference(String templateCode) {
        if (FSC_RLAContractTemplateResolver.isMortgagePurchaseTemplate(templateCode)) return 'CONT.PRE.HIP.COMP.INM';
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_CONSUMO_GARANTIA_HIPOTECARIA) return 'CONT.PRE.CONS.GAR.HIP';
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_CONSUMO_GARANTIA_MOBILIARIA) return 'CONT.PRE.CONS.GAR.MOB';
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_SOLA_FIRMA) return 'CON.PRE.COM.SOL.FIR';
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_HIPOTECARIA) return 'CON.PRE.COM.GAR.HIP';
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_SOLIDARIA) return 'PREST.COM.GTIA.SOL';
        if (templateCode == FSC_RLAContractTemplateResolver.TEMPLATE_GARANTIA_MOBILIARIA_CON_POSESION) return 'CONT.PREST.COMER.GTIA.CD';
        return 'CON.PRE.COM.GAR.MOB';
    }

    private static String formatInputDate(String rawDate) {
        return String.isBlank(rawDate) ? '' : FSC_ContratoFormatoService.fechaCortaEnLetras(Date.valueOf(rawDate));
    }

    private static Date dateInput(Map<String, String> values, String key) {
        String rawValue = get(values, key);
        return String.isBlank(rawValue) ? null : Date.valueOf(rawValue);
    }

    private static Decimal decimalInput(Map<String, String> values, String key) {
        String rawValue = get(values, key);
        return String.isBlank(rawValue) ? null : Decimal.valueOf(rawValue);
    }

    private static String decimalDisplay(Decimal value) {
        if (value == null) return '';
        String result = String.valueOf(value.setScale(2));
        while (result.endsWith('0')) result = result.left(result.length() - 1);
        return result.endsWith('.') ? result.left(result.length() - 1) : result;
    }

    private static String joinNames(List<String> names) {
        List<String> filtered = new List<String>();
        for (String name : names) if (!String.isBlank(name)) filtered.add(name);
        if (filtered.size() <= 1) return String.join(filtered, '');
        String lastName = filtered.remove(filtered.size() - 1);
        return String.join(filtered, ', ') + ' y ' + lastName;
    }

    private static String get(Map<String, String> values, String key) {
        return values.containsKey(key) ? values.get(key) : '';
    }

    public class FSC_ContratoPrestamoComercialException extends Exception {}
}