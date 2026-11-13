public without sharing class FSC_ActoGarantiaSolidariaCtrl {
    public ResidentialLoanApplication rla { get; private set; }
    public FSC_ContratoParticipanteService.Participante representanteBanco1 { get; private set; }
    public FSC_ContratoParticipanteService.Participante representanteBanco2 { get; private set; }
    public FSC_ContratoParticipanteService.Participante notario { get; private set; }
    public List<Fiador> fiadores { get; private set; }
    public String documentoBase { get; private set; }
    public String generalesDeudor { get; private set; }
    public String generalesFiadores { get; private set; }
    public String formaPago { get; private set; }
    public String montoLetras { get; private set; }
    public String montoNumero { get; private set; }
    public String simboloMoneda { get; private set; }
    public String tasaLetras { get; private set; }
    public String tasaNumero { get; private set; }
    public String fechaContrato { get; private set; }
    public String fechaActoDiaLetras { get; private set; }
    public String fechaActoDiaNumero { get; private set; }
    public String fechaActoMes { get; private set; }
    public String fechaActoAnoLetras { get; private set; }
    public String fechaActoAnoNumero { get; private set; }
    public String nombresComparecientes { get; private set; }
    public String lugarFirma { get; private set; }
    public String referenciaLegal { get; private set; }

    public class Fiador {
        public String nombre { get; private set; }

        public Fiador(String nombre) {
            this.nombre = nombre;
        }
    }

    public FSC_ActoGarantiaSolidariaCtrl(ApexPages.StandardController standardController) {
        Id rlaId = standardController == null
            ? (Id) ApexPages.currentPage().getParameters().get('id')
            : standardController.getId();
        if (rlaId == null) {
            throw new ActoGarantiaException('Se requiere la solicitud de crédito.');
        }

        rla = [
            SELECT Id, AccountId, Account.Name, Account.IsPersonAccount, Account.ACC_RNC__c,
                Account.VFS_RegistroMercantil__c, Account.ACC_NumIdentificacion__c,
                Account.ACC_Nacionalidad__c, Account.ACC_Estado_Civil__c,
                Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingCountry,
                FSC_MontoAprobado__c, FSC_Monto__c, FSC_TasaInteresAprobada__c, FSC_TasaInteres__c,
                FSC_Moneda__c, FSC_Fecha_Contrato__c,
                FSC_RNC_Cliente_Contrato__c, FSC_Registro_Mercantil_Contrato__c,
                FSC_Identificacion_Cliente_Contrato__c, FSC_Nacionalidad_Cliente_Contrato__c,
                FSC_Estado_Civil_Cliente_Contrato__c, FSC_Domicilio_Cliente_Contrato__c,
                FSC_Nombre_Representante_Cliente__c, FSC_Cargo_Representante_Cliente__c,
                FSC_Nacionalidad_Representante__c, FSC_Estado_Civil_Representante__c,
                FSC_Identificacion_Representante__c, FSC_Domicilio_Representante__c,
                FSC_Documento_Base_Acto_Garantia__c, FSC_Forma_Pago_Acto_Garantia__c,
                FSC_Generales_Fiadores_Acto__c, FSC_Nombre_del_negocio__c
            FROM ResidentialLoanApplication
            WHERE Id = :rlaId
            LIMIT 1
        ];

        FSC_ContratoParticipanteService.ParticipantesContrato participantes =
            FSC_ContratoParticipanteService.getParticipantes('SOLIDARIO');
        if (!participantes.errores.isEmpty()) {
            throw new ActoGarantiaException(String.join(participantes.errores, ' | '));
        }
        representanteBanco1 = participantes.representanteBanco1;
        representanteBanco2 = participantes.representanteBanco2;
        notario = participantes.notario;

        List<LoanApplicant> garantes = [
            SELECT Id, Name, FSC_Nombre__c, FSC_PrimerApellido__c, FSC_SegundoApellido__c
            FROM LoanApplicant
            WHERE LoanApplicationId = :rlaId AND FSC_TipoSolicitante__c = 'Garante'
            ORDER BY CreatedDate, Id
        ];
        if (garantes.isEmpty()) {
            throw new ActoGarantiaException('El acto de garantía solidaria requiere al menos un Loan Applicant de tipo Garante.');
        }

        fiadores = new List<Fiador>();
        List<String> nombresFiadores = new List<String>();
        for (LoanApplicant garante : garantes) {
            String nombre = applicantName(garante);
            fiadores.add(new Fiador(nombre));
            nombresFiadores.add(nombre);
        }

        documentoBase = rla.FSC_Documento_Base_Acto_Garantia__c;
        formaPago = rla.FSC_Forma_Pago_Acto_Garantia__c;
        generalesFiadores = rla.FSC_Generales_Fiadores_Acto__c;
        generalesDeudor = buildDebtorDescription(rla);

        Decimal monto = rla.FSC_MontoAprobado__c == null ? rla.FSC_Monto__c : rla.FSC_MontoAprobado__c;
        Decimal tasa = rla.FSC_TasaInteresAprobada__c == null ? rla.FSC_TasaInteres__c : rla.FSC_TasaInteresAprobada__c;
        montoLetras = FSC_ContratoFormatoService.montoEnLetras(monto, rla.FSC_Moneda__c);
        montoNumero = FSC_ContratoFormatoService.formatearMonto(monto);
        simboloMoneda = FSC_ContratoFormatoService.simboloMoneda(rla.FSC_Moneda__c);
        tasaLetras = FSC_ContratoFormatoService.decimalEnLetras(tasa).toLowerCase();
        tasaNumero = tasa == null ? '' : String.valueOf(tasa);

        Date contractDate = rla.FSC_Fecha_Contrato__c == null ? Date.today() : rla.FSC_Fecha_Contrato__c;
        Date actDate = resolveActDate();
        fechaContrato = FSC_ContratoFormatoService.fechaCortaEnLetras(contractDate);
        fechaActoDiaLetras = FSC_ContratoFormatoService.numeroMasculinoEnLetras(actDate.day()).toLowerCase();
        fechaActoDiaNumero = String.valueOf(actDate.day());
        fechaActoMes = FSC_ContratoFormatoService.mes(actDate.month());
        fechaActoAnoLetras = FSC_ContratoFormatoService.numeroEnLetras(actDate.year()).toLowerCase();
        fechaActoAnoNumero = String.valueOf(actDate.year());

        List<String> comparecientes = new List<String>{
            representanteBanco1.nombreCompleto,
            representanteBanco2.nombreCompleto
        };
        comparecientes.addAll(nombresFiadores);
        nombresComparecientes = joinNames(comparecientes);
        lugarFirma = notario.lugarFirma;
        referenciaLegal = 'DP/LEGAL/' + (String.isBlank(rla.FSC_Nombre_del_negocio__c)
            ? ''
            : rla.FSC_Nombre_del_negocio__c);
    }

    private static Date resolveActDate() {
        String rawDate = ApexPages.currentPage().getParameters().get('fechaActo');
        return String.isBlank(rawDate) ? Date.today() : Date.valueOf(rawDate);
    }

    private static String buildDebtorDescription(ResidentialLoanApplication source) {
        Account account = source.Account;
        String address = first(source.FSC_Domicilio_Cliente_Contrato__c, buildAddress(account));
        if (account.IsPersonAccount) {
            return account.Name + ', ' + first(source.FSC_Nacionalidad_Cliente_Contrato__c, account.ACC_Nacionalidad__c) +
                ', mayor de edad, ' + first(source.FSC_Estado_Civil_Cliente_Contrato__c, account.ACC_Estado_Civil__c) +
                ', portador(a) del documento de identidad No. ' +
                first(source.FSC_Identificacion_Cliente_Contrato__c, account.ACC_NumIdentificacion__c) +
                ', domiciliado(a) y residente en ' + address;
        }

        return account.Name + ', sociedad comercial organizada y existente de acuerdo con las leyes de la República Dominicana, RNC No. ' +
            first(source.FSC_RNC_Cliente_Contrato__c, account.ACC_RNC__c) + ', Registro Mercantil No. ' +
            first(source.FSC_Registro_Mercantil_Contrato__c, account.VFS_RegistroMercantil__c) +
            ', con domicilio social en ' + address + ', debidamente representada por ' +
            source.FSC_Nombre_Representante_Cliente__c + ', en calidad de ' + source.FSC_Cargo_Representante_Cliente__c +
            ', ' + source.FSC_Nacionalidad_Representante__c + ', mayor de edad, ' +
            source.FSC_Estado_Civil_Representante__c + ', portador(a) del documento de identidad No. ' +
            source.FSC_Identificacion_Representante__c + ', domiciliado(a) y residente en ' +
            source.FSC_Domicilio_Representante__c;
    }

    private static String applicantName(LoanApplicant applicant) {
        List<String> parts = new List<String>();
        add(parts, applicant.FSC_Nombre__c);
        add(parts, applicant.FSC_PrimerApellido__c);
        add(parts, applicant.FSC_SegundoApellido__c);
        return parts.isEmpty() ? applicant.Name : String.join(parts, ' ');
    }

    private static String buildAddress(Account account) {
        List<String> parts = new List<String>();
        add(parts, account.BillingStreet);
        add(parts, account.BillingCity);
        add(parts, account.BillingState);
        add(parts, account.BillingCountry);
        return String.join(parts, ', ');
    }

    private static String joinNames(List<String> names) {
        if (names.size() == 1) return names[0];
        if (names.size() == 2) return names[0] + ' y ' + names[1];
        String lastName = names.remove(names.size() - 1);
        return String.join(names, ', ') + ' y ' + lastName;
    }

    private static String first(String firstValue, String secondValue) {
        return String.isBlank(firstValue) ? secondValue : firstValue;
    }

    private static void add(List<String> values, String value) {
        if (!String.isBlank(value)) values.add(value.trim());
    }

    public class ActoGarantiaException extends Exception {}
}