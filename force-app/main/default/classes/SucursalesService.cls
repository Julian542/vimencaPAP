public with sharing class SucursalesService {

    // DTO para mapear la API
    public class SucursalDTO {
        public Integer id;
        public String nombre_oficina;
        public String direccion;
        public String telefono;
        public Decimal latitud;
        public Decimal longitud;
        public String provincia;
        public String tipo_de_oficina;
        public String servicio_principal;

        public String banco_vimenca;
        public String remesas;
        public String pagatodo;
        public String cajero_automaticos;
        public String vimenpaq;

        public String d_lunes_viernes;
        public String d_sabado;
        public String d_domingo;
    }

    public static void syncSucursales() {

        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint('https://staging.mapasgv.com/api/sucursales/');
        req.setMethod('GET');
        req.setTimeout(20000);

        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new CalloutException('Error en API: ' + res.getBody());
        }

        List<SucursalDTO> data = 
            (List<SucursalDTO>) JSON.deserialize(res.getBody(), List<SucursalDTO>.class);

        List<Sucursal__c> records = new List<Sucursal__c>();

        for (SucursalDTO s : data) {

            // (Opcional) Filtrar solo Banco Vimenca
            // if (s.servicio_principal != 'Banco Vimenca') continue;

            Sucursal__c suc = new Sucursal__c();

            // External ID
            suc.External_ID__c = String.valueOf(s.id);

            // Básicos
            suc.Name = String.isBlank(s.nombre_oficina) ? 'Sucursal sin nombre' : s.nombre_oficina.trim();
            if (suc.Name.length() > 80) {
                suc.Name = suc.Name.substring(0, 80);
            }
            suc.SUC_Address__c = String.isBlank(s.direccion) ? 'No informado' : s.direccion;
            suc.SUC_Phone__c = s.telefono;
            suc.SUC_Province__c = String.isBlank(s.provincia) ? 'No informado' : s.provincia;
            suc.SUC_City__c = suc.SUC_Province__c;
            suc.SUC_Street__c = 'No informado';
            suc.SUC_Neighborhood__c = 'No informado';
            suc.SUC_Number__c = 'S/N';
            suc.SUC_BranchType__c = normalizeBranchType(s.tipo_de_oficina);

            // 🌎 País agregado
            suc.SUC_Country__c = 'República Dominicana';

            // Activo
            suc.SUC_Active__c = true;

            // GEOLOCATION
            if (s.latitud != null && s.longitud != null) {
                suc.SUC_Location__Latitude__s = s.latitud;
                suc.SUC_Location__Longitude__s = s.longitud;
            }

            // SERVICIOS (multi-picklist)
            List<String> servicios = new List<String>();

            if (s.banco_vimenca == 'Y') servicios.add('Banco Vimenca');
            if (s.remesas == 'Y') servicios.add('Remesas Vimenca');
            if (s.pagatodo == 'Y') servicios.add('Paga Todo');
            if (s.vimenpaq == 'Y') servicios.add('Vimenpaq');
            if (s.cajero_automaticos == 'Y') servicios.add('Cajero Automaticos');

            if (!servicios.isEmpty()) {
                suc.SUC_ServicesOffered__c = String.join(servicios, ';');
            }

            // HORARIOS
            List<String> horarios = new List<String>();

            if (s.d_lunes_viernes != null)
                horarios.add('Lunes a Viernes: ' + s.d_lunes_viernes);

            if (s.d_sabado != null)
                horarios.add('Sábado: ' + s.d_sabado);

            if (s.d_domingo != null)
                horarios.add('Domingo: ' + s.d_domingo);

            if (!horarios.isEmpty()) {
                suc.Horarios__c = String.join(horarios, '\n');
            }

            records.add(suc);
        }

        if (!records.isEmpty()) {
            upsert records External_ID__c;
        }
        System.debug('Sucursales procesadas: ' + records.size());
    }

    private static String normalizeBranchType(String tipoApi) {
        if (tipoApi == 'Representante') {
            return 'Representante';
        }
        if (tipoApi == 'N') {
            return 'ATM Unared';
        }
        return 'Sucursal';
    }
}