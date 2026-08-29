public with sharing class FSC_PYMESolicitudPDFController {

    public Id rlaId { get; private set; }
    private ResidentialLoanApplication rla;
    private Account acc;
    private Map<String, Schema.SObjectField> rlaFieldMap;
    private List<LoanApplicantRow> loanApplicantsCache;
    private List<FSC_LoanApplicantFirmanteService.Firmante> loanApplicantFirmantesCache;

    public FSC_PYMESolicitudPDFController() {
        rlaId = (Id)ApexPages.currentPage().getParameters().get('id');
        rlaFieldMap = Schema.SObjectType.ResidentialLoanApplication.fields.getMap();
        if (rlaId != null) {
            loadRLA();
            loadAccount();
        }
    }

    private void loadRLA() {
        List<String> fieldApis = new List<String>{
            'AccountId','FSC_Sucursal__c','OtherLoanFeature',
            'FSC_Nombre_del_negocio__c','FSC_Tiempo_del_negocio__c','FSC_Situacion_Legal__c','FSC_Cargo__c',
            'FSC_Cantidad_de_empleados__c','FSC_Emplea_familiares__c','FSC_A_os_de_operacion__c','FSC_Local_del_negocio__c',
            'FSC_Tiempo_en_el_local_actual__c','FSC_Se_encuentra_en_la_misma_residencia__c','FSC_Se_encuentra_en_zona_comercial__c',
            'FSC_Actividad_economica__c','FSC_Telefono__c','FSC_Correo_Electronico__c','FSC_Direccion_del_Negocio__c',
            'FSC_Ingresos_Mensuales__c','FSC_Monto_de_los_Ingresos__c','FSC_Origen_de_los_Ingresos__c', 'FSC_Recomendaciones__c',
            'FSC_Tipo_de_solicitud__c','FSC_Destino_del_Prestamo__c','FSC_Moneda__c','FSC_Monto__c','FSC_Plazo_meses__c',
            'FSC_TasaInteres__c','FSC_MontoAprobado__c','FSC_PlazoMesesAprobado__c','FSC_TasaInteresAprobada__c',
            'FSC_Clasificacion_de_Riesgo__c','FSC_Grupo_de_Empresa__c','FSC_Condiciones_de_la_Facilidad__c','FSC_Descripcion_del_Negocio__c',
            'FSC_Tipo_de_Garantia__c','FSC_Valor_de_la_Garantia__c','FSC_Porcentaje_de_Admisibilidad__c','FSC_Descripcion_de_la_Garantia__c',
            'FSC_Historial_del_cliente__c','FSC_Operaciones_Perspectiva__c','FSC_CreatedBy_Name__c',
            'FSC_Total_Dias_Buenos__c','FSC_Total_Dias_Regulares__c','FSC_Total_Dias_Malos__c','FSC_Total_Semanal__c',
            'FSC_Efectivo_en_caja_y_bancos__c','FSC_Cuentas_por_cobrar_clientes__c','FSC_Inventario__c','FSC_Total_activos_corrientes__c',
            'FSC_Terrenos__c','FSC_Edificaciones__c','FSC_Maquinarias_y_equipos__c','FSC_Muebles_y_enseres__c','FSC_Vehiculos__c',
            'FSC_Otros_activos__c','FSC_Otros_activos_fijos__c','FSC_Total_activos__c','FSC_Total_Activos_Fijos__c',
            'FSC_Docs_Por_pagar_Corto_Plazo__c','FSC_Otras_deudas_corto_plazo__c','FSC_Cuentas_por_pagar_suplidores__c',
            'FSC_Total_pasivos_corto_plazo__c','FSC_Otras_cuentas_por_pagar__c','FSC_Otros_pasivos__c','FSC_Capital__c',
            'FSC_Total_Pasivos__c','FSC_Total_pasivos_y_capital__c',
            'FSC_Nomina__c','FSC_Alquiler_Generales__c','FSC_Servicios_basicos_Generales__c','FSC_Combustible__c','FSC_Reparaciones__c',
            'FSC_Seguros_Generales__c','FSC_Otros_Generales__c','FSC_Total_Gastos_Grales_y_Adm__c',
            'FSC_Alquiler_Personales__c','FSC_Servicios_basicos_Personales__c','FSC_Alimentos__c','FSC_Educacion__c','FSC_Transporte__c',
            'FSC_Seguros_Personales__c','FSC_Otros_Personales__c','FSC_Total_gastos_personales__c',
            'FSC_Cuotas__c','FSC_Otros_Financieros__c','FSC_Total_gastos_financieros__c'
        };

        List<String> selectFields = new List<String>{ 'Id', 'CreatedBy.Name' };
        for (String api : fieldApis) if (rlaFieldMap.containsKey(api)) selectFields.add(api);

        String soql = 'SELECT ' + String.join(selectFields, ',') + ' FROM ResidentialLoanApplication WHERE Id = \'' +
            String.escapeSingleQuotes(String.valueOf(rlaId)) + '\' LIMIT 1';
        rla = (ResidentialLoanApplication)Database.query(soql);
    }

    private void loadAccount() {
        if (rla == null) return;
        Id accId = (Id)rla.get('AccountId');
        if (accId == null) return;

        Map<String, Schema.SObjectField> aMap = Schema.SObjectType.Account.fields.getMap();
        List<String> aFields = new List<String>{
            'Name','Phone','PersonEmail','PersonMobilePhone','PersonHomePhone','ACC_TipoIdentificacion__c','ACC_Genero__c',
            'BillingStreet','BillingCity','BillingState','BillingCountry','BillingPostalCode','ACC_Nacionalidad__c',
            'PersonMailingStreet','PersonMailingCity','PersonMailingState','PersonMailingCountry','PersonMailingPostalCode',
            'FirstName','LastName','ACC_NumIdentificacion__c','ACC_Estado_Civil__c','Tipo_de_vivienda__c','ACC_Telefono_Movil__c',
            'ACC_Nombre_Corto_Comercial__c','Actividad_Economica_Name__c','ACC_RNC__c','FinServ__BillingAddress__pc'
        };

        List<String> existing = new List<String>();
        for (String f : aFields) if (aMap.containsKey(f)) existing.add(f);

        String soql = 'SELECT Id,' + String.join(existing, ',') + ' FROM Account WHERE Id = \'' +
            String.escapeSingleQuotes(String.valueOf(accId)) + '\' LIMIT 1';
        acc = (Account)Database.query(soql);
    }

    public String sucursal { get { return safe(rla == null ? '' : String.valueOf(rla.get('FSC_Sucursal__c'))); } }
    public String fechaHoyFmt { get { return fmtDate(Date.today()); } }

    public String pfNombres {
        get {
            if (acc == null) return '';
            if (Schema.SObjectType.Account.fields.getMap().containsKey('FirstName')) {
                String v = safe(String.valueOf(acc.get('FirstName')));
                if (v != '') return v;
            }
            String name = safe(String.valueOf(acc.get('Name')));
            if (name == '') return '';
            if (name.contains(' ')) return name.substring(0, name.indexOf(' '));
            return name;
        }
    }

    public String pfApellidos {
        get {
            if (acc == null) return '';
            if (Schema.SObjectType.Account.fields.getMap().containsKey('LastName')) {
                String v = safe(String.valueOf(acc.get('LastName')));
                if (v != '') return v;
            }
            String name = safe(String.valueOf(acc.get('Name')));
            if (name == '') return '';
            if (name.contains(' ')) return name.substring(name.indexOf(' ') + 1);
            return '';
        }
    }

    public String pfTipoCedula {
        get {
            if (acc == null) return '';
            if (Schema.SObjectType.Account.fields.getMap().containsKey('ACC_TipoIdentificacion__c')) {
                String v = safe(String.valueOf(acc.get('ACC_TipoIdentificacion__c')));
                if (v != '') return v;
            }
            String name = safe(String.valueOf(acc.get('Name')));
            if (name == '') return '';
            if (name.contains(' ')) return name.substring(0, name.indexOf(' '));
            return name;
        }
    }
    public String pfNoIdentificacion { get { return safe(String.valueOf(acc.get('ACC_NumIdentificacion__c'))); } }
    public String pfNacionalidad { get { return safe(String.valueOf(acc.get('ACC_Nacionalidad__c'))); } }
    public String pfSexo {
        get {
            if (acc == null) return '';
            if (Schema.SObjectType.Account.fields.getMap().containsKey('ACC_Genero__c')) {
                String v = safe(String.valueOf(acc.get('ACC_Genero__c')));
                if (v != '') return v;
            }
            String name = safe(String.valueOf(acc.get('Name')));
            if (name == '') return '';
            if (name.contains(' ')) return name.substring(0, name.indexOf(' '));
            return name;
        }
    }
    public String pfEstadoCivil { get { return safe(String.valueOf(acc.get('ACC_Estado_Civil__c'))); } }
    public String pfTipoVivienda { get { return safe(String.valueOf(acc.get('Tipo_de_vivienda__c'))); } }

    public String pfTelefono { get { return acc == null ? '' : safe(String.valueOf(acc.get('ACC_Telefono_Movil__c'))); } }

    public String pfCelular { get { return acc == null ? '' : safe(String.valueOf(acc.get('ACC_Telefono_Movil__c'))); } }

    public String pfEmail {
        get {
            if (acc == null) return '';
            if (Schema.SObjectType.Account.fields.getMap().containsKey('PersonEmail')) {
                String v = safe(String.valueOf(acc.get('PersonEmail')));
                if (v != '') return v;
            }
            return '';
        }
    }

    public String pfDireccion {
        get {
            if (acc == null) return '';
            return safe(String.valueOf(acc.get('FinServ__BillingAddress__pc')));
        }
    }

    public String pjRazonSocial { get { return safe(String.valueOf(acc.get('Actividad_Economica_Name__c'))); } }
    public String pjNombreComercial { get { return safe(String.valueOf(acc.get('ACC_Nombre_Corto_Comercial__c'))); } }
    public String pjRnc { get { return safe(String.valueOf(acc.get('ACC_RNC__c'))); } }

    public class SocioRow {
        public String nombre { get; set; }
        public String identificacion { get; set; }
        public String numeroId { get; set; }
        public String cargo { get; set; }
        public String porcentaje { get; set; }
    }

    public List<SocioRow> socios { get { return querySocios(rlaId); } }
    public Integer sociosSize { get { return socios == null ? 0 : socios.size(); } }

    public class LoanApplicantRow {
        public String tipoSolicitante { get; set; }
        public String name { get; set; }
        public String tipoIdentificacion { get; set; }
        public String numIdentificacion { get; set; }
        public String direccion { get; set; }
        public String telefono { get; set; }
        public String correoElectronico { get; set; }
    }

    public List<LoanApplicantRow> loanApplicants {
        get {
            if (loanApplicantsCache == null) {
                loanApplicantsCache = queryLoanApplicants(rlaId);
            }
            return loanApplicantsCache;
        }
    }
    public Integer loanApplicantsSize { get { return loanApplicants == null ? 0 : loanApplicants.size(); } }
    public List<FSC_LoanApplicantFirmanteService.Firmante> loanApplicantFirmantes {
        get {
            if (loanApplicantFirmantesCache == null) {
                loanApplicantFirmantesCache = FSC_LoanApplicantFirmanteService.queryFirmantes(rlaId);
            }
            return loanApplicantFirmantesCache;
        }
    }
    public Integer loanApplicantFirmantesSize {
        get {
            return loanApplicantFirmantes == null ? 0 : loanApplicantFirmantes.size();
        }
    }

    public String negocioNombre { get { return safe(val('FSC_Nombre_del_negocio__c')); } }
    public String negocioTiempo { get { return safe(val('FSC_Tiempo_del_negocio__c')); } }
    public String negocioSituacionLegal { get { return safe(val('FSC_Situacion_Legal__c')); } }
    public String negocioCargo { get { return safe(val('FSC_Cargo__c')); } }
    public String negocioEmpleados { get { return safe(val('FSC_Cantidad_de_empleados__c')) + ' empleados'; } }

    public String negocioEmpleaFamilia { get { return String.valueOf(rla.get('FSC_Emplea_familiares__c')); } }

    public String negocioAniosOperacion { get { return safe(val('FSC_A_os_de_operacion__c')) + ' años'; } }

    public String negocioLocal { get { return safe(val('FSC_Local_del_negocio__c')); } }

    public String negocioTiempoLocal { get { return safe(val('FSC_Tiempo_en_el_local_actual__c')); } }
    public String comentarios { get { return safe(val('OtherLoanFeature')); } }

    public String negocioMismaResidencia { get { return Boolean.valueOf(rla.get('FSC_Se_encuentra_en_la_misma_residencia__c')) ? 'Si' : 'No'; } }

    public String negocioZonaComercial { get { return Boolean.valueOf(rla.get('FSC_Se_encuentra_en_zona_comercial__c')) ? 'Si' : 'No'; } }

    public String negocioActividad { get { return safe(val('FSC_Actividad_economica__c')); } }

    public Decimal negocioIngresosMensualesVal { get { return tryDec(rla == null ? null : rla.get('FSC_Ingresos_Mensuales__c')); } }
    public String negocioIngresosMensualesFmt { get { return fmtMoney(negocioIngresosMensualesVal); } }

    public String negocioOtrosIngresos { get { return tryDec(rla == null ? null : rla.get('FSC_Monto_de_los_Ingresos__c')) > 0 ? 'Si' : 'No'; } }

    public String negocioOrigenIngresos { get { return safe(val('FSC_Origen_de_los_Ingresos__c')); } }
    public Decimal negocioMontoIngresosVal { get { return tryDec(rla == null ? null : rla.get('FSC_Monto_de_los_Ingresos__c')); } }
    public String negocioMontoIngresosFmt { get { return fmtMoney(negocioMontoIngresosVal); } }

    public String negocioTelefono { get { return safe(val('FSC_Telefono__c')); } }
    public String negocioEmail { get { return safe(val('FSC_Correo_Electronico__c')); } }
    public String negocioDireccion { get { return safe(val('FSC_Direccion_del_Negocio__c')); } }
    public String recomendaciones { get { return safe(val('FSC_Recomendaciones__c')); } }
    public String oficialNegocios {
        get {
            String stored = safe(val('FSC_CreatedBy_Name__c'));
            if (stored != '') return stored;
            if (rla != null) {
                SObject createdBy = rla.getSObject('CreatedBy');
                if (createdBy != null) return safe(String.valueOf(createdBy.get('Name')));
            }
            return '';
        }
    }
    public String oficialNegociosFirma { get { return oficialNegocios.toUpperCase(); } }

    public String creditoTipoSolicitud { get { return safe(val('FSC_Tipo_de_solicitud__c')); } }
    public String creditoDestino { get { return safe(val('FSC_Destino_del_Prestamo__c')); } }
    public String creditoMoneda { get { return safe(val('FSC_Moneda__c')); } }
    public Decimal creditoMontoVal { get { return tryDec(firstPopulated('FSC_MontoAprobado__c', 'FSC_Monto__c')); } }
    public String creditoMontoFmt { get { return fmtMoney(creditoMontoVal); } }
    public String creditoPlazoMeses { get { return safe(stringValue(firstPopulated('FSC_PlazoMesesAprobado__c', 'FSC_Plazo_meses__c'))); } }
    public String tasaInteres { get { return safe(stringValue(firstPopulated('FSC_TasaInteresAprobada__c', 'FSC_TasaInteres__c'))); } }
    public String creditoClasificacionRiesgo { get { return safe(val('FSC_Clasificacion_de_Riesgo__c')); } }
    public String creditoGrupo { get { return safe(val('FSC_Grupo_de_Empresa__c')); } }
    public String creditoCondiciones { get { return safe(val('FSC_Condiciones_de_la_Facilidad__c')); } }
    public String creditoDescripcionNegocio { get { return safe(val('FSC_Descripcion_del_Negocio__c')); } }

    public String garantiaTipo { get { return safe(val('FSC_Tipo_de_Garantia__c')); } }
    public Decimal garantiaValorVal { get { return tryDec(rla == null ? null : rla.get('FSC_Valor_de_la_Garantia__c')); } }
    public String garantiaValorFmt { get { return fmtMoney(garantiaValorVal); } }
    public String garantiaPorcAdmis { get { return safe(val('FSC_Porcentaje_de_Admisibilidad__c')); } }
    public String garantiaDescripcion { get { return safe(val('FSC_Descripcion_de_la_Garantia__c')); } }

    public class FacilidadRow {
        public String numero { get; set; }
        public String fechaAperturaFmt { get; set; }
        public String tipoFacilidad { get; set; }
        public String plazoMeses { get; set; }
        public String moneda { get; set; }
        public String deudaActualFmt { get; set; }
        public String limiteAutorizadoFmt { get; set; }
        public String aumentoSolicitadoFmt { get; set; }
        public String posibleCompromisoFmt { get; set; }
        public String compromisoMensualFmt { get; set; }
        public Decimal tasa { get; set; }
    }

    public List<FacilidadRow> facilidades { get { return queryFacilidades(rlaId); } }
    public Integer facilidadesSize { get { return facilidades == null ? 0 : facilidades.size(); } }

    public class PropositoRow {
        public String numeroFacilidades { get; set; }
        public String proposito { get; set; }
    }

    public List<PropositoRow> propositos { get { return queryPropositos(rlaId); } }
    public Integer propositosSize { get { return propositos == null ? 0 : propositos.size(); } }

    public class GarantiaRow {
        public String numeroFacilidades { get; set; }
        public String descripcion { get; set; }
        public String valorFmt { get; set; }
        public Decimal porcAdmis { get; set; }
    }

    public List<GarantiaRow> garantiasLista { get { return queryGarantias(rlaId); } }
    public Integer garantiasListaSize { get { return garantiasLista == null ? 0 : garantiasLista.size(); } }

    public class RelacionRow {
        public String tipoProducto { get; set; }
        public String numero { get; set; }
        public String fechaAperturaFmt { get; set; }
        public String balancePromedioFmt { get; set; }
        public String balanceActualFmt { get; set; }
        public String flujoProm { get; set; }
        public String limiteCreditoFmt { get; set; }
        public String montoAperturaFmt { get; set; }
        public String montoMinimoFmt { get; set; }
        public String periodo { get; set; }
        public String tasaPasiva { get; set; }
    }

    public List<RelacionRow> relaciones { get { return queryRelaciones(rlaId); } }
    public Integer relacionesSize { get { return relaciones == null ? 0 : relaciones.size(); } }

    public class ReferenciaSimpleRow {
        public String nombre { get; set; }
        public String telefono { get; set; }
        public String tipoProducto { get; set; }
        public String parentesco { get; set; }
    }

    public List<ReferenciaSimpleRow> referenciasParaTabla { get { return queryReferenciasSimple(rlaId); } }
    public Integer referenciasParaTablaSize { get { return referenciasParaTabla == null ? 0 : referenciasParaTabla.size(); } }

    public class CPRow {
        public String nombre { get; set; }
        public String terminos { get; set; }
        public String telefono { get; set; }
    }

    public List<CPRow> clientesProveedores { get { return queryClientesProveedores(rlaId); } }
    public Integer clientesProveedoresSize { get { return clientesProveedores == null ? 0 : clientesProveedores.size(); } }

    public String historiaCliente { get { return safe(val('FSC_Historial_del_cliente__c')); } }
    public String operacionesPerspectiva { get { return safe(val('FSC_Operaciones_Perspectiva__c')); } }

    public List<String> listFortalezas { get { return queryFortalezasDebilidades(rlaId, 'Fortaleza'); } }
    public Integer listFortalezasSize { get { return listFortalezas == null ? 0 : listFortalezas.size(); } }
    public List<String> listDebilidades { get { return queryFortalezasDebilidades(rlaId, 'Debilidad'); } }
    public Integer listDebilidadesSize { get { return listDebilidades == null ? 0 : listDebilidades.size(); } }

    public Decimal totalDiasBuenos { get { return tryDec(rla == null ? null : rla.get('FSC_Total_Dias_Buenos__c')); } }
    public Decimal totalDiasRegulares { get { return tryDec(rla == null ? null : rla.get('FSC_Total_Dias_Regulares__c')); } }
    public Decimal totalDiasMalos { get { return tryDec(rla == null ? null : rla.get('FSC_Total_Dias_Malos__c')); } }
    public Decimal totalSemanal { get { return tryDec(rla == null ? null : rla.get('FSC_Total_Semanal__c')); } }

    public String totalDiasBuenosFmt { get { return fmtMoney(totalDiasBuenos); } }
    public String totalDiasRegularesFmt { get { return fmtMoney(totalDiasRegulares); } }
    public String totalDiasMalosFmt { get { return fmtMoney(totalDiasMalos); } }
    public String totalSemanalFmt { get { return fmtMoney(totalSemanal); } }

    public Decimal actEfectivo { get { return tryDec(rla == null ? null : rla.get('FSC_Efectivo_en_caja_y_bancos__c')); } }
    public Decimal actCxc { get { return tryDec(rla == null ? null : rla.get('FSC_Cuentas_por_cobrar_clientes__c')); } }
    public Decimal actInventario { get { return tryDec(rla == null ? null : rla.get('FSC_Inventario__c')); } }
    public Decimal actTotalCorrientes { get { return tryDec(rla == null ? null : rla.get('FSC_Total_activos_corrientes__c')); } }
    public Decimal actTerrenos { get { return tryDec(rla == null ? null : rla.get('FSC_Terrenos__c')); } }
    public Decimal actEdificaciones { get { return tryDec(rla == null ? null : rla.get('FSC_Edificaciones__c')); } }
    public Decimal actMaquinarias { get { return tryDec(rla == null ? null : rla.get('FSC_Maquinarias_y_equipos__c')); } }
    public Decimal actMuebles { get { return tryDec(rla == null ? null : rla.get('FSC_Muebles_y_enseres__c')); } }
    public Decimal actVehiculos { get { return tryDec(rla == null ? null : rla.get('FSC_Vehiculos__c')); } }
    public Decimal actOtros { get { return tryDec(rla == null ? null : rla.get('FSC_Otros_activos__c')); } }
    public Decimal actOtrosActivos { get { return tryDec(rla == null ? null : rla.get('FSC_Otros_activos_fijos__c')); } }
    public Decimal actTotal { get { return tryDec(rla == null ? null : rla.get('FSC_Total_activos__c')); } }
    public Decimal actTotalFijos { get { return tryDec(rla == null ? null : rla.get('FSC_Total_Activos_Fijos__c')); } }

    public String actEfectivoFmt { get { return fmtMoney(actEfectivo); } }
    public String actCxcFmt { get { return fmtMoney(actCxc); } }
    public String actInventarioFmt { get { return fmtMoney(actInventario); } }
    public String actTotalCorrientesFmt { get { return fmtMoney(actTotalCorrientes); } }
    public String actTerrenosFmt { get { return fmtMoney(actTerrenos); } }
    public String actEdificacionesFmt { get { return fmtMoney(actEdificaciones); } }
    public String actMaquinariasFmt { get { return fmtMoney(actMaquinarias); } }
    public String actMueblesFmt { get { return fmtMoney(actMuebles); } }
    public String actVehiculosFmt { get { return fmtMoney(actVehiculos); } }
    public String actOtrosFmt { get { return fmtMoney(actOtros); } }
    public String actOtrosActivosFmt { get { return fmtMoney(actOtrosActivos); } }
    public String actTotalFmt { get { return fmtMoney(actTotal); } }
    public String actTotalFijosFmt { get { return fmtMoney(actTotalFijos); } }

    public Decimal pasDocs { get { return tryDec(rla == null ? null : rla.get('FSC_Docs_Por_pagar_Corto_Plazo__c')); } }
    public Decimal pasOtrasDeudasCP { get { return tryDec(rla == null ? null : rla.get('FSC_Otras_deudas_corto_plazo__c')); } }
    public Decimal pasCxp { get { return tryDec(rla == null ? null : rla.get('FSC_Cuentas_por_pagar_suplidores__c')); } }
    public Decimal pasTotalCP { get { return tryDec(rla == null ? null : rla.get('FSC_Total_pasivos_corto_plazo__c')); } }
    public Decimal pasOtrasCxp { get { return tryDec(rla == null ? null : rla.get('FSC_Otras_cuentas_por_pagar__c')); } }
    public Decimal pasOtros { get { return tryDec(rla == null ? null : rla.get('FSC_Otros_pasivos__c')); } }
    public Decimal pasCapital { get { return tryDec(rla == null ? null : rla.get('FSC_Capital__c')); } }
    public Decimal pasTotal { get { return tryDec(rla == null ? null : rla.get('FSC_Total_Pasivos__c')); } }
    public Decimal pasTotalPasCap { get { return tryDec(rla == null ? null : rla.get('FSC_Total_pasivos_y_capital__c')); } }

    public String pasDocsFmt { get { return fmtMoney(pasDocs); } }
    public String pasOtrasDeudasCPFmt { get { return fmtMoney(pasOtrasDeudasCP); } }
    public String pasCxpFmt { get { return fmtMoney(pasCxp); } }
    public String pasTotalCPFmt { get { return fmtMoney(pasTotalCP); } }
    public String pasOtrasCxpFmt { get { return fmtMoney(pasOtrasCxp); } }
    public String pasOtrosFmt { get { return fmtMoney(pasOtros); } }
    public String pasCapitalFmt { get { return fmtMoney(pasCapital); } }
    public String pasTotalFmt { get { return fmtMoney(pasTotal); } }
    public String pasTotalPasCapFmt { get { return fmtMoney(pasTotalPasCap); } }

    public Decimal gpNomina { get { return tryDec(rla == null ? null : rla.get('FSC_Nomina__c')); } }
    public Decimal gpAlquilerGenerales { get { return tryDec(rla == null ? null : rla.get('FSC_Alquiler_Generales__c')); } }
    public Decimal gpServiciosBasicosGenerales { get { return tryDec(rla == null ? null : rla.get('FSC_Servicios_basicos_Generales__c')); } }
    public Decimal gpCombustible { get { return tryDec(rla == null ? null : rla.get('FSC_Combustible__c')); } }
    public Decimal gpReparaciones { get { return tryDec(rla == null ? null : rla.get('FSC_Reparaciones__c')); } }
    public Decimal gpSegurosGenerales { get { return tryDec(rla == null ? null : rla.get('FSC_Seguros_Generales__c')); } }
    public Decimal gpOtrosGenerales { get { return tryDec(rla == null ? null : rla.get('FSC_Otros_Generales__c')); } }
    public Decimal gpTotalGGA { get { return tryDec(rla == null ? null : rla.get('FSC_Total_Gastos_Grales_y_Adm__c')); } }

    public String gpNominaFmt { get { return fmtMoney(gpNomina); } }
    public String gpAlquilerGeneralesFmt { get { return fmtMoney(gpAlquilerGenerales); } }
    public String gpServiciosBasicosGeneralesFmt { get { return fmtMoney(gpServiciosBasicosGenerales); } }
    public String gpCombustibleFmt { get { return fmtMoney(gpCombustible); } }
    public String gpReparacionesFmt { get { return fmtMoney(gpReparaciones); } }
    public String gpSegurosGeneralesFmt { get { return fmtMoney(gpSegurosGenerales); } }
    public String gpOtrosGeneralesFmt { get { return fmtMoney(gpOtrosGenerales); } }
    public String gpTotalGGAFmt { get { return fmtMoney(gpTotalGGA); } }

    public Decimal gpAlquilerPersonales { get { return tryDec(rla == null ? null : rla.get('FSC_Alquiler_Personales__c')); } }
    public Decimal gpServiciosBasicosPersonales { get { return tryDec(rla == null ? null : rla.get('FSC_Servicios_basicos_Personales__c')); } }
    public Decimal gpAlimentos { get { return tryDec(rla == null ? null : rla.get('FSC_Alimentos__c')); } }
    public Decimal gpEducacion { get { return tryDec(rla == null ? null : rla.get('FSC_Educacion__c')); } }
    public Decimal gpTransporte { get { return tryDec(rla == null ? null : rla.get('FSC_Transporte__c')); } }
    public Decimal gpSegurosPersonales { get { return tryDec(rla == null ? null : rla.get('FSC_Seguros_Personales__c')); } }
    public Decimal gpOtrosPersonales { get { return tryDec(rla == null ? null : rla.get('FSC_Otros_Personales__c')); } }
    public Decimal gpTotalPersonales { get { return tryDec(rla == null ? null : rla.get('FSC_Total_gastos_personales__c')); } }

    public String gpAlquilerPersonalesFmt { get { return fmtMoney(gpAlquilerPersonales); } }
    public String gpServiciosBasicosPersonalesFmt { get { return fmtMoney(gpServiciosBasicosPersonales); } }
    public String gpAlimentosFmt { get { return fmtMoney(gpAlimentos); } }
    public String gpEducacionFmt { get { return fmtMoney(gpEducacion); } }
    public String gpTransporteFmt { get { return fmtMoney(gpTransporte); } }
    public String gpSegurosPersonalesFmt { get { return fmtMoney(gpSegurosPersonales); } }
    public String gpOtrosPersonalesFmt { get { return fmtMoney(gpOtrosPersonales); } }
    public String gpTotalPersonalesFmt { get { return fmtMoney(gpTotalPersonales); } }

    public Decimal gpCuotas { get { return tryDec(rla == null ? null : rla.get('FSC_Cuotas__c')); } }
    public Decimal gpOtrosFinancieros { get { return tryDec(rla == null ? null : rla.get('FSC_Otros_Financieros__c')); } }
    public Decimal gpTotalFinancieros { get { return tryDec(rla == null ? null : rla.get('FSC_Total_gastos_financieros__c')); } }

    public String gpCuotasFmt { get { return fmtMoney(gpCuotas); } }
    public String gpOtrosFinancierosFmt { get { return fmtMoney(gpOtrosFinancieros); } }
    public String gpTotalFinancierosFmt { get { return fmtMoney(gpTotalFinancieros); } }

    public class FieldRow {
        public String label { get; set; }
        public String value { get; set; }
    }

    private String formatByType(Schema.DescribeFieldResult d, Object v, Boolean monthYear) {
        if (v == null) return '';
        Schema.DisplayType t = d.getType();
        if (t == Schema.DisplayType.Date) return monthYear ? fmtMonthYear((Date)v) : fmtDate((Date)v);
        if (t == Schema.DisplayType.DateTime) {
            Date dd = ((DateTime)v).date();
            return monthYear ? fmtMonthYear(dd) : fmtDate(dd);
        }
        if (t == Schema.DisplayType.Currency || t == Schema.DisplayType.Double || t == Schema.DisplayType.Percent) {
            return fmtMoney(tryDec(v));
        }
        return String.valueOf(v);
    }

    private String val(String api) {
        Object v = rlaValue(api);
        return v == null ? '' : String.valueOf(v);
    }

    private Object firstPopulated(String preferredApi, String fallbackApi) {
        Object preferred = rlaValue(preferredApi);
        if (preferred != null && (!(preferred instanceof String) || String.isNotBlank((String)preferred))) return preferred;
        return rlaValue(fallbackApi);
    }

    private Object rlaValue(String api) {
        if (rla == null || rlaFieldMap == null || !rlaFieldMap.containsKey(api)) return null;
        return rla.get(api);
    }

    private String stringValue(Object value) {
        return value == null ? '' : String.valueOf(value);
    }

    private static List<SocioRow> querySocios(Id idVal) {
        List<SocioRow> out = new List<SocioRow>();
        if (idVal == null) return out;
        String objApi = 'FSC_Socios_Principales_Y_Accionistas__c';
        if (!Schema.getGlobalDescribe().containsKey(objApi)) return out;

        String soql = 'SELECT Name, FSC_Identificacion__c, FSC_Numero_Id__c, FSC_Cargo_en_la_Empresa__c, FSC_Porcentaje_Participacion_en_Acciones__c ' +
                      'FROM ' + objApi + ' WHERE FSC_Residential_Loan_Application__c = \'' + String.escapeSingleQuotes(String.valueOf(idVal)) + '\'';
        for (SObject s : Database.query(soql)) {
            SocioRow r = new SocioRow();
            r.nombre = String.valueOf(s.get('Name'));
            r.identificacion = String.valueOf(s.get('FSC_Identificacion__c'));
            r.numeroId = String.valueOf(s.get('FSC_Numero_Id__c'));
            r.cargo = String.valueOf(s.get('FSC_Cargo_en_la_Empresa__c'));
            r.porcentaje = String.valueOf(s.get('FSC_Porcentaje_Participacion_en_Acciones__c'));
            out.add(r);
        }
        return out;
    }

    private static List<LoanApplicantRow> queryLoanApplicants(Id idVal) {
        List<LoanApplicantRow> out = new List<LoanApplicantRow>();
        if (idVal == null || !Schema.getGlobalDescribe().containsKey('LoanApplicant')) return out;

        List<LoanApplicant> applicants = [
            SELECT
                Id,
                Name,
                Contact.Email,
                Contact.Phone,
                Contact.MobilePhone,
                Contact.MailingStreet,
                Contact.MailingCity,
                Contact.MailingState,
                Contact.MailingCountry,
                FSC_TipoSolicitante__c,
                FSC_TipoIdentificacion__c,
                FSC_NumIdentificacion__c,
                FSC_Nombre__c,
                FSC_PrimerApellido__c,
                FSC_SegundoApellido__c
            FROM LoanApplicant
            WHERE LoanApplicationId = :idVal AND FSC_TipoSolicitante__c != 'Deudor'
            ORDER BY CreatedDate, Id
        ];

        Map<Id, String> emailByApplicantId = queryApplicantEmails(applicants);
        for (LoanApplicant applicant : applicants) {
            if (!isCoDeudorOGarante(applicant.FSC_TipoSolicitante__c)) continue;

            LoanApplicantRow row = new LoanApplicantRow();
            row.tipoSolicitante = safe(applicant.FSC_TipoSolicitante__c);
            row.name = firstNonBlank(
                joinNonBlank(new List<String>{ applicant.FSC_Nombre__c, applicant.FSC_PrimerApellido__c, applicant.FSC_SegundoApellido__c }, ' '),
                applicant.Name
            );
            row.tipoIdentificacion = safe(applicant.FSC_TipoIdentificacion__c);
            row.numIdentificacion = safe(applicant.FSC_NumIdentificacion__c);
            row.direccion = applicant.Contact == null
                ? ''
                : joinNonBlank(new List<String>{ applicant.Contact.MailingStreet, applicant.Contact.MailingCity, applicant.Contact.MailingState, applicant.Contact.MailingCountry }, ', ');
            row.telefono = applicant.Contact == null ? '' : firstNonBlank(applicant.Contact.MobilePhone, applicant.Contact.Phone);
            row.correoElectronico = firstNonBlank(emailByApplicantId.get(applicant.Id), applicant.Contact == null ? '' : applicant.Contact.Email);
            out.add(row);
        }
        return out;
    }

    private static Map<Id, String> queryApplicantEmails(List<LoanApplicant> applicants) {
        Map<Id, String> emailByApplicantId = new Map<Id, String>();
        if (applicants == null || applicants.isEmpty() || !Schema.getGlobalDescribe().containsKey('ContactPointEmail')) {
            return emailByApplicantId;
        }

        Set<Id> applicantIds = new Set<Id>();
        for (LoanApplicant applicant : applicants) {
            applicantIds.add(applicant.Id);
        }
        for (ContactPointEmail emailRecord : [
            SELECT FSC_Solicitante__c, EmailAddress
            FROM ContactPointEmail
            WHERE FSC_Solicitante__c IN :applicantIds
            ORDER BY CreatedDate DESC, Id DESC
        ]) {
            if (!emailByApplicantId.containsKey(emailRecord.FSC_Solicitante__c)) {
                emailByApplicantId.put(emailRecord.FSC_Solicitante__c, emailRecord.EmailAddress);
            }
        }
        return emailByApplicantId;
    }

    private static List<FacilidadRow> queryFacilidades(Id idVal) {
        List<FacilidadRow> out = new List<FacilidadRow>();
        if (idVal == null) return out;
        String objApi = 'FSC_Facilidades_De_Credito__c';
        if (!Schema.getGlobalDescribe().containsKey(objApi)) return out;

        String soql = 'SELECT FSC_Numero__c, FSC_Fecha_Apertura__c, FSC_Tipo_de_Facilidad__c, FSC_Plazo_meses__c, FSC_Moneda__c, FSC_Deuda_Actual__c, FSC_Limite_Autorizado__c, FSC_Aumento_Solicitado__c, FSC_Posible_Compromiso__c, FSC_Compromiso_Mensual__c, FSC_Tasa__c ' +
                      'FROM ' + objApi + ' WHERE FSC_Residential_Loan_Application__c = \'' + String.escapeSingleQuotes(String.valueOf(idVal)) + '\'';
        for (SObject s : Database.query(soql)) {
            FacilidadRow r = new FacilidadRow();
            r.numero = String.valueOf(s.get('FSC_Numero__c'));
            r.fechaAperturaFmt = fmtDate(tryDate(s.get('FSC_Fecha_Apertura__c')));
            r.tipoFacilidad = String.valueOf(s.get('FSC_Tipo_de_Facilidad__c'));
            r.plazoMeses = String.valueOf(s.get('FSC_Plazo_meses__c'));
            r.moneda = String.valueOf(s.get('FSC_Moneda__c'));
            r.deudaActualFmt = fmtMoney(tryDec(s.get('FSC_Deuda_Actual__c')));
            r.limiteAutorizadoFmt = fmtMoney(tryDec(s.get('FSC_Limite_Autorizado__c')));
            r.aumentoSolicitadoFmt = fmtMoney(tryDec(s.get('FSC_Aumento_Solicitado__c')));
            r.posibleCompromisoFmt = fmtMoney(tryDec(s.get('FSC_Posible_Compromiso__c')));
            r.compromisoMensualFmt = fmtMoney(tryDec(s.get('FSC_Compromiso_Mensual__c')));
            r.tasa = tryDec(s.get('FSC_Tasa__c'));
            out.add(r);
        }
        return out;
    }

    private static List<PropositoRow> queryPropositos(Id idVal) {
        List<PropositoRow> out = new List<PropositoRow>();
        if (idVal == null) return out;
        String objApi = 'FSC_Proposito_Y_Uso_De_Fondos__c';
        if (!Schema.getGlobalDescribe().containsKey(objApi)) return out;

        String soql = 'SELECT FSC_Numero_Facilidades__c, FSC_Proposito__c FROM ' + objApi +
                      ' WHERE FSC_Residential_Loan_Application__c = \'' + String.escapeSingleQuotes(String.valueOf(idVal)) + '\'';
        for (SObject s : Database.query(soql)) {
            PropositoRow r = new PropositoRow();
            r.numeroFacilidades = String.valueOf(s.get('FSC_Numero_Facilidades__c'));
            r.proposito = String.valueOf(s.get('FSC_Proposito__c'));
            out.add(r);
        }
        return out;
    }

    private static List<GarantiaRow> queryGarantias(Id idVal) {
        List<GarantiaRow> out = new List<GarantiaRow>();
        if (idVal == null) return out;

        String soql = '\'' + String.escapeSingleQuotes(String.valueOf(idVal)) + '\'';
        for (SObject s : [SELECT FSC_Numero_Facilidades__c, FSC_Descripcion_de_la_Garantia__c, CashOrMarketValue, FSC_Porcentaje_Admisibilidad__c FROM LoanApplicationAsset WHERE LoanApplicationId = :idVal]) {
            GarantiaRow r = new GarantiaRow();
            r.numeroFacilidades = String.valueOf(s.get('FSC_Numero_Facilidades__c'));
            r.descripcion = String.valueOf(s.get('FSC_Descripcion_de_la_Garantia__c'));
            r.valorFmt = fmtMoney(tryDec(s.get('CashOrMarketValue')));
            r.porcAdmis = tryDec(s.get('FSC_Porcentaje_Admisibilidad__c'));
            out.add(r);
        }
        return out;
    }

    private static List<RelacionRow> queryRelaciones(Id idVal) {
        List<RelacionRow> out = new List<RelacionRow>();
        if (idVal == null) return out;
        String objApi = 'FSC_Relacion_Negocios_Colaterales__c';
        if (!Schema.getGlobalDescribe().containsKey(objApi)) return out;

        String soql = 'SELECT FSC_Tipo_de_Producto__c, FSC_Numero__c, FSC_Fecha_de_Apertura__c, FSC_Balance_Promedio__c, FSC_Balance_Actual__c, FSC_Flujo_Prom_Dep__c, FSC_Limite_de_Credito__c, FSC_Monto_Apertura__c, FSC_Monto_Minimo__c, FSC_Periodo__c, FSC_Tasa_Pasiva__c ' +
                      'FROM ' + objApi + ' WHERE FSC_Residential_Loan_Application__c = \'' + String.escapeSingleQuotes(String.valueOf(idVal)) + '\'';
        for (SObject s : Database.query(soql)) {
            RelacionRow r = new RelacionRow();
            r.tipoProducto = String.valueOf(s.get('FSC_Tipo_de_Producto__c'));
            r.numero = String.valueOf(s.get('FSC_Numero__c'));
            r.fechaAperturaFmt = fmtDate(tryDate(s.get('FSC_Fecha_de_Apertura__c')));
            r.balancePromedioFmt = fmtMoney(tryDec(s.get('FSC_Balance_Promedio__c')));
            r.balanceActualFmt = fmtMoney(tryDec(s.get('FSC_Balance_Actual__c')));
            r.flujoProm = String.valueOf(s.get('FSC_Flujo_Prom_Dep__c'));
            r.limiteCreditoFmt = fmtMoney(tryDec(s.get('FSC_Limite_de_Credito__c')));
            r.montoAperturaFmt = fmtMoney(tryDec(s.get('FSC_Monto_Apertura__c')));
            r.montoMinimoFmt = fmtMoney(tryDec(s.get('FSC_Monto_Minimo__c')));
            r.periodo = String.valueOf(s.get('FSC_Periodo__c'));
            r.tasaPasiva = String.valueOf(s.get('FSC_Tasa_Pasiva__c'));
            out.add(r);
        }
        return out;
    }

    private static List<ReferenciaSimpleRow> queryReferenciasSimple(Id idVal) {
        List<ReferenciaSimpleRow> out = new List<ReferenciaSimpleRow>();
        if (idVal == null) return out;
        String objApi = 'FSC_Referencias__c';
        if (!Schema.getGlobalDescribe().containsKey(objApi)) return out;

        String soql = 'SELECT Name, FSC_Telefono__c, FSC_Tipo_de_Producto__c, FSC_Parentesco__c FROM ' + objApi +
                      ' WHERE FSC_Residential_Loan_Application__c = \'' + String.escapeSingleQuotes(String.valueOf(idVal)) + '\'';
        for (SObject s : Database.query(soql)) {
            ReferenciaSimpleRow r = new ReferenciaSimpleRow();
            r.nombre = String.valueOf(s.get('Name'));
            r.telefono = String.valueOf(s.get('FSC_Telefono__c'));
            r.tipoProducto = String.valueOf(s.get('FSC_Tipo_de_Producto__c'));
            r.parentesco = String.valueOf(s.get('FSC_Parentesco__c'));
            out.add(r);
        }
        return out;
    }

    private static List<CPRow> queryClientesProveedores(Id idVal) {
        List<CPRow> out = new List<CPRow>();
        if (idVal == null) return out;
        String objApi = 'FSC_Clientes_Y_Proveedores_Principales__c';
        if (!Schema.getGlobalDescribe().containsKey(objApi)) return out;

        String soql = 'SELECT Name, FSC_Terminos_de_Negociacion__c, FSC_Numero_Telefonico__c FROM ' + objApi +
                      ' WHERE FSC_Residential_Loan_Application__c = \'' + String.escapeSingleQuotes(String.valueOf(idVal)) + '\'';
        for (SObject s : Database.query(soql)) {
            CPRow r = new CPRow();
            r.nombre = String.valueOf(s.get('Name'));
            r.terminos = String.valueOf(s.get('FSC_Terminos_de_Negociacion__c'));
            r.telefono = String.valueOf(s.get('FSC_Numero_Telefonico__c'));
            out.add(r);
        }
        return out;
    }

    private static List<String> queryFortalezasDebilidades(Id idVal, String tipo) {
        List<String> out = new List<String>();
        if (idVal == null) return out;
        String objApi = 'FSC_Fortalezas_Y_Debilidades__c';
        if (!Schema.getGlobalDescribe().containsKey(objApi)) return out;

        String soql = 'SELECT Name FROM ' + objApi +
                      ' WHERE FSC_Residential_Loan_Application__c = \'' + String.escapeSingleQuotes(String.valueOf(idVal)) + '\' AND FSC_Tipo__c = \'' + tipo + '\'';
        for (SObject s : Database.query(soql)) {
            out.add(String.valueOf(s.get('Name')));
        }
        return out;
    }

    public static String fmtMoney(Decimal amount) {
        if (amount == null) return '';
        Decimal a = amount.setScale(2);
        String raw = String.valueOf(a);
        List<String> parts = raw.split('\\.');
        String intPart = parts[0];
        String decPart = (parts.size() > 1 ? parts[1] : '00');
        if (decPart.length() == 1) decPart = decPart + '0';
        if (decPart.length() > 2) decPart = decPart.substring(0,2);

        String withCommas = '';
        Integer cnt = 0;
        for (Integer i = intPart.length()-1; i >= 0; i--) {
            withCommas = intPart.substring(i,i+1) + withCommas;
            cnt++;
            if (cnt == 3 && i > 0) {
                withCommas = ',' + withCommas;
                cnt = 0;
            }
        }
        return 'RD$ ' + withCommas + '.' + decPart;
    }

    private static String fmtDate(Date d) {
        if (d == null) return '';
        String dd = String.valueOf(d.day()).leftPad(2,'0');
        String mm = String.valueOf(d.month()).leftPad(2,'0');
        String yy = String.valueOf(d.year());
        return dd + '/' + mm + '/' + yy;
    }

    private static String fmtMonthYear(Date d) {
        if (d == null) return '';
        String mm = String.valueOf(d.month()).leftPad(2,'0');
        String yy = String.valueOf(d.year());
        return mm + '/' + yy;
    }

    private static Decimal tryDec(Object v) {
        if (v == null) return null;
        if (v instanceof Decimal) return (Decimal)v;
        if (v instanceof Integer) return Decimal.valueOf((Integer)v);
        if (v instanceof Long) return Decimal.valueOf((Long)v);
        if (v instanceof Double) return Decimal.valueOf(String.valueOf(v));
        return Decimal.valueOf(String.valueOf(v));
    }

    private static Date tryDate(Object v) {
        if (v == null) return null;
        if (v instanceof Date) return (Date)v;
        if (v instanceof DateTime) return ((DateTime)v).date();
        String s = String.valueOf(v);
        if (s != null && s.length() >= 10 && s.contains('-')) return Date.valueOf(s.substring(0,10));
        return null;
    }

    private static Boolean isCoDeudorOGarante(String tipoSolicitante) {
        String tipo = safe(tipoSolicitante).toLowerCase();
        return tipo.contains('co') || tipo.contains('garante');
    }

    private static String firstNonBlank(String firstValue, String secondValue) {
        if (!String.isBlank(firstValue)) return firstValue;
        return safe(secondValue);
    }

    private static String joinNonBlank(List<String> values, String separator) {
        List<String> parts = new List<String>();
        for (String value : values) {
            if (!String.isBlank(value)) parts.add(value.trim());
        }
        return String.join(parts, separator);
    }

    private static String safe(String s) { return s == null ? '' : s; }
}