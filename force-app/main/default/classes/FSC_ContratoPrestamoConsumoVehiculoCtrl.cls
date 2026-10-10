public without sharing class FSC_ContratoPrestamoConsumoVehiculoCtrl extends FSC_ContratoPrestamoComercialBaseCtrl {
    public DatosVehiculo vehiculo { get; private set; }

    public class DatosVehiculo {
        public Boolean tieneGaranteMobiliario { get; set; }
        public String denominacionPrestatarios { get; set; }
        public String denominacionGarantes { get; set; }
        public String prestatariosGenerales { get; set; }
        public String garantesGenerales { get; set; }
        public String nombresFirmantesNotario { get; set; }
        public List<FSC_ContratoIntervinienteService.Interviniente> prestatarios { get; set; }
        public List<FSC_ContratoIntervinienteService.Interviniente> garantes { get; set; }
    }

    public FSC_ContratoPrestamoConsumoVehiculoCtrl(ApexPages.StandardController standardController) {
        super(standardController, FSC_RLAContractTemplateResolver.TEMPLATE_CONSUMO_GARANTIA_MOBILIARIA, 0);
        initializeInterveners((Id) standardController.getId());
    }

    private void initializeInterveners(Id rlaId) {
        ResidentialLoanApplication rla = [
            SELECT FSC_Propietario_Garantia_Vehiculo__c, FSC_Datos_Intervinientes_Contrato__c
            FROM ResidentialLoanApplication
            WHERE Id = :rlaId
            LIMIT 1
        ];
        Map<String, Object> saved = FSC_ContratoIntervinienteService.parse(rla.FSC_Datos_Intervinientes_Contrato__c);
        DatosVehiculo item = new DatosVehiculo();
        item.prestatarios = new List<FSC_ContratoIntervinienteService.Interviniente>{
            FSC_ContratoIntervinienteService.fromPrimaryAccount(
                datos.clienteNombre,
                datos.clienteIdentificacion,
                datos.clienteNacionalidad,
                datos.clienteEstadoCivil,
                datos.clienteDomicilio
            )
        };
        item.prestatarios.addAll(
            FSC_ContratoIntervinienteService.getApplicants(
                rlaId,
                FSC_ContratoIntervinienteService.TIPO_CODEUDOR,
                'codeudor_',
                saved,
                false
            )
        );
        item.tieneGaranteMobiliario = rla.FSC_Propietario_Garantia_Vehiculo__c == FSC_VehiculoDocumentoResolver.PROPIETARIO_DISTINTO;
        item.garantes = item.tieneGaranteMobiliario
            ? FSC_ContratoIntervinienteService.getApplicants(
                rlaId,
                FSC_ContratoIntervinienteService.TIPO_GARANTE,
                'garanteContrato_',
                saved,
                true
            )
            : new List<FSC_ContratoIntervinienteService.Interviniente>();
        item.denominacionPrestatarios = item.tieneGaranteMobiliario
            ? (item.prestatarios.size() > 1 ? 'LOS PRESTATARIOS' : 'EL PRESTATARIO')
            : (item.prestatarios.size() > 1 ? 'LOS PRESTATARIOS - GARANTES MOBILIARIOS' : 'EL PRESTATARIO - GARANTE MOBILIARIO');
        item.denominacionGarantes = item.garantes.size() > 1 ? 'LOS GARANTES MOBILIARIOS' : 'EL GARANTE MOBILIARIO';
        item.prestatariosGenerales = FSC_ContratoIntervinienteService.joinGenerales(item.prestatarios);
        item.garantesGenerales = FSC_ContratoIntervinienteService.joinGenerales(item.garantes);

        List<String> signerNames = new List<String>{ FSC_ContratoIntervinienteService.joinNames(item.prestatarios) };
        if (item.tieneGaranteMobiliario) signerNames.add(FSC_ContratoIntervinienteService.joinNames(item.garantes));
        signerNames.add(datos.bancoRepresentante1.nombreCompleto);
        signerNames.add(datos.bancoRepresentante2.nombreCompleto);
        item.nombresFirmantesNotario = joinNames(signerNames);
        vehiculo = item;
    }

    private static String joinNames(List<String> names) {
        List<String> filtered = new List<String>();
        for (String name : names) if (!String.isBlank(name)) filtered.add(name);
        if (filtered.size() <= 1) return String.join(filtered, '');
        String lastName = filtered.remove(filtered.size() - 1);
        return String.join(filtered, ', ') + ' y ' + lastName;
    }
}