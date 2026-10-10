public with sharing class FSC_RlaGarantiasTablaController {
    private static final String RT_PYME = 'FSC_Solicitud_Credito_PYME';
    private static final Set<String> RT_GARANTIAS = new Set<String>{
        'FSC_Solicitud_Credito_Consumo', 'FSC_Solicitud_Credito_Hipotecario', 'FSC_Solicitud_Credito_Vehiculo'
    };
    private static Map<String, Map<String, String>> etiquetas = new Map<String, Map<String, String>>();

    // La pantalla y la hoja de desembolso usan las mismas filas.
    public class GarantiaRow {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String nombre { get; set; }
        @AuraEnabled public Boolean esPyme { get; set; }
        @AuraEnabled public String numeroFacilidad { get; set; }
        @AuraEnabled public String descripcionGarantia { get; set; }
        @AuraEnabled public Decimal valor { get; set; }
        @AuraEnabled public Decimal porcentajeAdmisibilidad { get; set; }
        @AuraEnabled public List<String> detalles { get; set; }
        @AuraEnabled public List<ImporteGarantia> importes { get; set; }

        public GarantiaRow() {
            detalles = new List<String>();
            importes = new List<ImporteGarantia>();
        }
    }

    public class ImporteGarantia {
        @AuraEnabled public String etiqueta { get; set; }
        @AuraEnabled public Decimal valor { get; set; }
        @AuraEnabled public String moneda { get; set; }

        public String monedaTexto {
            get { return String.isBlank(moneda) ? 'Moneda no informada' : moneda; }
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<GarantiaRow> getGarantias(Id residentialLoanApplicationId) {
        if (residentialLoanApplicationId == null) {
            return new List<GarantiaRow>();
        }
        List<ResidentialLoanApplication> solicitudes = [
            SELECT Id, RecordType.DeveloperName, FSC_Moneda__c
            FROM ResidentialLoanApplication
            WHERE Id = :residentialLoanApplicationId
        ];
        if (solicitudes.isEmpty()) {
            throw new AuraHandledException('No se encontró la solicitud de crédito o no tiene acceso a ella.');
        }
        ResidentialLoanApplication solicitud = solicitudes[0];
        if (solicitud.RecordType.DeveloperName == RT_PYME) {
            return getGarantiasPyme(solicitud);
        }
        if (RT_GARANTIAS.contains(solicitud.RecordType.DeveloperName)) {
            return getOtrasGarantias(solicitud);
        }
        throw new AuraHandledException('El tipo de crédito no está configurado para consultar garantías.');
    }

    private static List<GarantiaRow> getGarantiasPyme(ResidentialLoanApplication solicitud) {
        Id solicitudId = solicitud.Id;
        String query = 'SELECT Id, Name, FSC_Numero_Facilidades__c, FSC_Descripcion_de_la_Garantia__c, ' +
            'CashOrMarketValue, FSC_Porcentaje_Admisibilidad__c, FSC_Descripcion_Contrato__c, ' +
            'AccountNumber, FinancialInstitutionName, FSC_Titular_CD_Contrato__c, FSC_Moneda_CD_Contrato__c, ' +
            'FSC_Marca_Vehiculo_Contrato__c, FSC_Modelo_Vehiculo_Contrato__c, FSC_Ano_Vehiculo_Contrato__c, ' +
            'FSC_Chasis_Vehiculo_Contrato__c, FSC_Placa_Vehiculo_Contrato__c, FSC_Matricula_Vehiculo_Contrato__c, ' +
            'FSC_Numero_Titulo_Contrato__c, FSC_Ubicacion_Contrato__c' + campoMoneda(LoanApplicationAsset.SObjectType) +
            ' FROM LoanApplicationAsset WHERE LoanApplicationId = :solicitudId ' +
            'ORDER BY FSC_Numero_Facilidades__c ASC NULLS LAST, CreatedDate ASC, Id ASC';
        List<GarantiaRow> rows = new List<GarantiaRow>();
        for (LoanApplicationAsset asset : (List<LoanApplicationAsset>) Database.query(query)) {
            GarantiaRow row = new GarantiaRow();
            row.id = asset.Id;
            row.nombre = asset.Name;
            row.esPyme = true;
            row.numeroFacilidad = asset.FSC_Numero_Facilidades__c == null ? '' : String.valueOf(asset.FSC_Numero_Facilidades__c);
            row.descripcionGarantia = etiqueta(LoanApplicationAsset.FSC_Descripcion_de_la_Garantia__c, asset.FSC_Descripcion_de_la_Garantia__c);
            row.valor = asset.CashOrMarketValue;
            row.porcentajeAdmisibilidad = asset.FSC_Porcentaje_Admisibilidad__c;
            agregarDetalle(row, 'Descripción', asset.FSC_Descripcion_Contrato__c);
            agregarDetalle(row, 'Cuenta / certificado', asset.AccountNumber);
            agregarDetalle(row, 'Entidad financiera', asset.FinancialInstitutionName);
            agregarDetalle(row, 'Titular', asset.FSC_Titular_CD_Contrato__c);
            agregarDetalle(row, 'Marca', asset.FSC_Marca_Vehiculo_Contrato__c);
            agregarDetalle(row, 'Modelo', asset.FSC_Modelo_Vehiculo_Contrato__c);
            agregarDetalle(row, 'Año', asset.FSC_Ano_Vehiculo_Contrato__c);
            agregarDetalle(row, 'Chasis', asset.FSC_Chasis_Vehiculo_Contrato__c);
            agregarDetalle(row, 'Placa', asset.FSC_Placa_Vehiculo_Contrato__c);
            agregarDetalle(row, 'Matrícula', asset.FSC_Matricula_Vehiculo_Contrato__c);
            agregarDetalle(row, 'Título', asset.FSC_Numero_Titulo_Contrato__c);
            agregarDetalle(row, 'Ubicación', asset.FSC_Ubicacion_Contrato__c);
            agregarImporte(row, 'Valor', asset.CashOrMarketValue,
                resolverMoneda(asset, asset.FSC_Moneda_CD_Contrato__c, solicitud.FSC_Moneda__c));
            rows.add(row);
        }
        return rows;
    }

    private static List<GarantiaRow> getOtrasGarantias(ResidentialLoanApplication solicitud) {
        Id solicitudId = solicitud.Id;
        String query = 'SELECT Id, Name, FSC_Tipo_de_Garantia__c, FSC_Clase_de_Garantia__c, FSC_Descripcion_de_la_Garantia__c, ' +
            'FSC_Tipo_de_Inmueble__c, FSC_Ubicacion__c, FSC_Numero_Titulo__c, FSC_Registro_de_Titulos__c, ' +
            'FSC_Valor_Inmueble__c, FSC_Valor_Tasado__c, FSC_Precio_de_Venta__c, FSC_Fecha_Tasacion__c, ' +
            'FSC_Marca_Vehiculo__c, FSC_Modelo_Vehiculo__c, FSC_Ano_Vehiculo__c, FSC_Numero_Chasis_Vehiculo__c, ' +
            'FSC_Numero_Placa_Vehiculo__c, FSC_Numero_Matricula__c, FSC_Valor_Vehiculo__c, ' +
            'FSC_Numero_Certificado_Deposito__c, FSC_Titular_Certificado_Deposito__c, FSC_Emisor_Certificado_Deposito__c, ' +
            'FSC_Monto_Certificado_Deposito__c, FSC_Moneda_Certificado_Deposito__c' + campoMoneda(FSC_Garantia__c.SObjectType) +
            ' FROM FSC_Garantia__c WHERE FSC_Residential_Loan_Application__c = :solicitudId ORDER BY CreatedDate ASC, Id ASC';
        List<GarantiaRow> rows = new List<GarantiaRow>();
        for (FSC_Garantia__c garantia : (List<FSC_Garantia__c>) Database.query(query)) {
            GarantiaRow row = new GarantiaRow();
            row.id = garantia.Id;
            row.nombre = garantia.Name;
            row.esPyme = false;
            row.descripcionGarantia = garantia.FSC_Tipo_de_Garantia__c;
            agregarDetalle(row, 'Clase', etiqueta(FSC_Garantia__c.FSC_Clase_de_Garantia__c, garantia.FSC_Clase_de_Garantia__c));
            agregarDetalle(row, 'Descripción', garantia.FSC_Descripcion_de_la_Garantia__c);
            agregarDetalle(row, 'Inmueble', garantia.FSC_Tipo_de_Inmueble__c);
            agregarDetalle(row, 'Ubicación', garantia.FSC_Ubicacion__c);
            agregarDetalle(row, 'Título', garantia.FSC_Numero_Titulo__c);
            agregarDetalle(row, 'Registro de títulos', garantia.FSC_Registro_de_Titulos__c);
            agregarDetalle(row, 'Fecha de tasación', garantia.FSC_Fecha_Tasacion__c);
            agregarDetalle(row, 'Marca', etiqueta(FSC_Garantia__c.FSC_Marca_Vehiculo__c, garantia.FSC_Marca_Vehiculo__c));
            agregarDetalle(row, 'Modelo', etiqueta(FSC_Garantia__c.FSC_Modelo_Vehiculo__c, garantia.FSC_Modelo_Vehiculo__c));
            agregarDetalle(row, 'Año', garantia.FSC_Ano_Vehiculo__c);
            agregarDetalle(row, 'Chasis', garantia.FSC_Numero_Chasis_Vehiculo__c);
            agregarDetalle(row, 'Placa', garantia.FSC_Numero_Placa_Vehiculo__c);
            agregarDetalle(row, 'Matrícula', garantia.FSC_Numero_Matricula__c);
            agregarDetalle(row, 'Certificado', garantia.FSC_Numero_Certificado_Deposito__c);
            agregarDetalle(row, 'Titular', garantia.FSC_Titular_Certificado_Deposito__c);
            agregarDetalle(row, 'Emisor', garantia.FSC_Emisor_Certificado_Deposito__c);
            String moneda = resolverMoneda(garantia, null, solicitud.FSC_Moneda__c);
            agregarImporte(row, 'Valor del inmueble', garantia.FSC_Valor_Inmueble__c, moneda);
            agregarImporte(row, 'Valor tasado', garantia.FSC_Valor_Tasado__c, moneda);
            agregarImporte(row, 'Precio de venta', garantia.FSC_Precio_de_Venta__c, moneda);
            agregarImporte(row, 'Valor del vehículo', garantia.FSC_Valor_Vehiculo__c, moneda);
            agregarImporte(row, 'Monto del certificado', garantia.FSC_Monto_Certificado_Deposito__c,
                resolverMoneda(garantia, garantia.FSC_Moneda_Certificado_Deposito__c, solicitud.FSC_Moneda__c));
            rows.add(row);
        }
        return rows;
    }

    private static void agregarDetalle(GarantiaRow row, String nombre, Object valor) {
        if (valor != null && !String.isBlank(String.valueOf(valor))) {
            String texto = String.valueOf(valor);
            // Las fechas de tasación se muestran sin hora.
            if (valor instanceof Date) {
                Date fecha = (Date) valor;
                texto = String.valueOf(fecha.day()).leftPad(2, '0') + '/' +
                    String.valueOf(fecha.month()).leftPad(2, '0') + '/' + String.valueOf(fecha.year());
            }
            row.detalles.add(nombre + ': ' + texto);
        }
    }

    private static void agregarImporte(GarantiaRow row, String nombre, Decimal valor, String moneda) {
        if (valor == null) {
            return;
        }
        ImporteGarantia importe = new ImporteGarantia();
        importe.etiqueta = nombre;
        importe.valor = valor;
        importe.moneda = moneda;
        row.importes.add(importe);
    }

    private static String etiqueta(Schema.SObjectField campo, String valor) {
        if (String.isBlank(valor)) {
            return '';
        }
        String clave = String.valueOf(campo);
        if (!etiquetas.containsKey(clave)) {
            Map<String, String> opciones = new Map<String, String>();
            for (Schema.PicklistEntry opcion : campo.getDescribe().getPicklistValues()) {
                opciones.put(opcion.getValue(), opcion.getLabel());
            }
            etiquetas.put(clave, opciones);
        }
        return etiquetas.get(clave).containsKey(valor) ? etiquetas.get(clave).get(valor) : valor;
    }

    // CurrencyIsoCode solo existe cuando el objeto admite varias monedas.
    private static String campoMoneda(Schema.SObjectType tipo) {
        return tipo.getDescribe().fields.getMap().containsKey('CurrencyIsoCode') ? ', CurrencyIsoCode' : '';
    }

    private static String resolverMoneda(SObject registro, String monedaCertificado, String monedaSolicitud) {
        if (!String.isBlank(monedaCertificado)) {
            return codigoMoneda(monedaCertificado);
        }
        if (campoMoneda(registro.getSObjectType()) != '') {
            String monedaRegistro = (String) registro.get('CurrencyIsoCode');
            if (!String.isBlank(monedaRegistro)) {
                return codigoMoneda(monedaRegistro);
            }
        }
        return codigoMoneda(monedaSolicitud);
    }

    private static String codigoMoneda(String valor) {
        if (String.isBlank(valor)) {
            return null;
        }
        String moneda = valor.trim().toUpperCase();
        if (moneda == '1' || moneda == 'DOP' || moneda.contains('PESO') || moneda == 'RD$') {
            return 'DOP';
        }
        if (moneda == '2' || moneda == 'USD' || moneda.contains('DOLAR') || moneda.contains('DÓLAR') || moneda == 'US$') {
            return 'USD';
        }
        if (moneda == '3' || moneda == 'EUR' || moneda.contains('EURO')) {
            return 'EUR';
        }
        return moneda;
    }
}