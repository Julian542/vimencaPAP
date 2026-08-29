public with sharing class SucursalesPorServicio {

    public class Request {
        @InvocableVariable(required=true)
        public String ciudad;

        @InvocableVariable(required=true)
        public String servicio;
    }

    public class Response {
        @InvocableVariable
        public String nombre;

        @InvocableVariable
        public String direccion;

        @InvocableVariable
        public String horarios;

        @InvocableVariable
        public String servicios;
    }

    @InvocableMethod(label='Buscar sucursales por servicio')
    public static List<List<Response>> execute(List<Request> requests) {

        List<List<Response>> result = new List<List<Response>>();

        for (Request req : requests) {

            List<Response> respuestas = new List<Response>();

            //  NORMALIZAR servicio (clave)
            String servicio = normalizarServicio(req.servicio);

            List<Sucursal__c> sucursales = [
                SELECT Name, SUC_Address__c, Horarios__c, SUC_ServicesOffered__c
                FROM Sucursal__c
                WHERE SUC_Province__c LIKE :('%' + req.ciudad + '%')
                AND SUC_ServicesOffered__c INCLUDES (:servicio)
                AND SUC_Active__c = true
                LIMIT 10
            ];

            for (Sucursal__c s : sucursales) {

                Response r = new Response();
                r.nombre = s.Name;
                r.direccion = s.SUC_Address__c;
                r.horarios = s.Horarios__c;
                r.servicios = s.SUC_ServicesOffered__c;

                respuestas.add(r);
            }

            result.add(respuestas);
        }

        return result;
    }

    // MAPEO INTELIGENTE (CLAVE)
    private static String normalizarServicio(String input) {

        if (input == null) return null;

        input = input.toLowerCase();

        if (input.contains('paga')) return 'Paga Todo';
        if (input.contains('vimenpaq')) return 'Vimenpaq';
        if (input.contains('remesa')) return 'Remesas Vimenca';
        if (input.contains('cajero') || input.contains('atm')) return 'Cajero Automaticos';
        if (input.contains('banco')) return 'Banco Vimenca';

        return input;
    }
}