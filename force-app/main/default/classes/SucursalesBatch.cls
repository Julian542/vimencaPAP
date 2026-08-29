global class SucursalesBatch implements Database.Batchable<Object>, Database.AllowsCallouts {

    global Iterable<Object> start(Database.BatchableContext bc) {

        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint('https://staging.mapasgv.com/api/sucursales/');
        req.setMethod('GET');
        req.setTimeout(20000);

        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new CalloutException('Error en API: ' + res.getBody());
        }

        return (List<Object>) JSON.deserializeUntyped(res.getBody());
    }

    global void execute(Database.BatchableContext bc, List<Object> scope) {

        List<Sucursal__c> records = new List<Sucursal__c>();

        for (Object obj : scope) {

            Map<String, Object> s = (Map<String, Object>) obj;

            Sucursal__c suc = new Sucursal__c();

            // External ID
            suc.External_ID__c = String.valueOf(s.get('id'));

            // 🔥 NAME (seguro)
            String nombre = String.valueOf(s.get('nombre_oficina'));

            if (String.isBlank(nombre)) {
                nombre = 'Sucursal sin nombre';
            }

            nombre = nombre.trim();

            if (nombre.length() > 80) {
                nombre = nombre.substring(0, 80);
            }

            suc.Name = nombre;

            // Dirección
            suc.SUC_Address__c = String.isBlank((String) s.get('direccion')) ? 'No informado' : (String) s.get('direccion');

            // País
            suc.SUC_Country__c = 'República Dominicana';

            // Provincia (real desde API)
            suc.SUC_Province__c = String.isBlank((String) s.get('provincia')) ? 'No informado' : (String) s.get('provincia');

            // 🧠 Ciudad (MEJORADO)
            // Como la API no trae ciudad separada:
            suc.SUC_City__c = suc.SUC_Province__c;

            // Campos requeridos por validation rule
            suc.SUC_Street__c = 'No informado';
            suc.SUC_Neighborhood__c = 'No informado';
            suc.SUC_Number__c = 'S/N';

            // Teléfono
            suc.SUC_Phone__c = (String) s.get('telefono');

            // 🔥 TIPO DE SUCURSAL (CORRECTO)
            String tipoApi = String.valueOf(s.get('tipo_de_oficina'));
            String servicio = String.valueOf(s.get('servicio_principal'));

            if (tipoApi == 'Sucursal') {
                suc.SUC_BranchType__c = 'Sucursal';
            } 
            else if (tipoApi == 'Representante') {
                suc.SUC_BranchType__c = 'Representante';
            } 
            else if (tipoApi == 'N') {
                // Ahora sabemos que es ATM
                suc.SUC_BranchType__c = 'ATM Unared';
            } 
            else {
                System.debug('TIPO DESCONOCIDO: ' + tipoApi + ' - ' + servicio);
                suc.SUC_BranchType__c = 'Sucursal';
            }

            suc.SUC_Active__c = true;

            // GEOLOCATION
            if (s.get('latitud') != null && s.get('longitud') != null) {
                suc.SUC_Location__Latitude__s = Decimal.valueOf(String.valueOf(s.get('latitud')));
                suc.SUC_Location__Longitude__s = Decimal.valueOf(String.valueOf(s.get('longitud')));
            }

            // 🔥 SERVICIOS
            List<String> servicios = new List<String>();

            if ((String) s.get('banco_vimenca') == 'Y') 
                servicios.add('Banco Vimenca');

            if ((String) s.get('remesas') == 'Y') 
                servicios.add('Remesas Vimenca');

            if ((String) s.get('pagatodo') == 'Y') 
                servicios.add('Paga Todo');

            if ((String) s.get('vimenpaq') == 'Y') 
                servicios.add('Vimenpaq');

            if ((String) s.get('cajero_automaticos') == 'Y') 
                servicios.add('Cajero Automaticos');

            if (!servicios.isEmpty()) {
                suc.SUC_ServicesOffered__c = String.join(servicios, ';');
            }

            // 🔥 HORARIOS
            List<String> horarios = new List<String>();

            if (s.get('d_lunes_viernes') != null)
                horarios.add('Lunes a Viernes: ' + (String) s.get('d_lunes_viernes'));

            if (s.get('d_sabado') != null)
                horarios.add('Sábado: ' + (String) s.get('d_sabado'));

            if (s.get('d_domingo') != null)
                horarios.add('Domingo: ' + (String) s.get('d_domingo'));

            if (!horarios.isEmpty()) {
                suc.Horarios__c = String.join(horarios, '\n');
            }

            records.add(suc);
        }

        if (!records.isEmpty()) {
            upsert records External_ID__c;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de sucursales finalizado correctamente');
    }
}