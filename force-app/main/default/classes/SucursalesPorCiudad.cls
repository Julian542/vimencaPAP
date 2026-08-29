public with sharing class SucursalesPorCiudad {

    public class Request {
        @InvocableVariable(required=true)
        public String ciudad;
    }

    public class Response {
        @InvocableVariable
        public String nombre;

        @InvocableVariable
        public String direccion;

        @InvocableVariable
        public String horarios;
    }

    @InvocableMethod(label='Buscar sucursales por ciudad')
    public static List<List<Response>> execute(List<Request> requests) {

        List<List<Response>> result = new List<List<Response>>();

        for (Request req : requests) {

            List<Response> respuestas = new List<Response>();

            // 🔍 Buscar por provincia (o ciudad)
            List<Sucursal__c> sucursales = [
                SELECT Name, SUC_Address__c, Horarios__c
                FROM Sucursal__c
                WHERE SUC_Province__c LIKE :('%' + req.ciudad + '%')
                AND SUC_Active__c = true
                LIMIT 50
            ];

            // 🔥 Priorizar las que tienen horarios
            sucursales.sort(new HorarioComparator());

            for (Sucursal__c s : sucursales) {

                Response r = new Response();
                r.nombre = s.Name;
                r.direccion = s.SUC_Address__c;
                r.horarios = s.Horarios__c;

                respuestas.add(r);
            }

            result.add(respuestas);
        }

        return result;
    }

    // 🔥 Comparator para priorizar con horarios
    public class HorarioComparator implements System.Comparator<Sucursal__c> {
        public Integer compare(Sucursal__c a, Sucursal__c b) {

            Boolean aTiene = a.Horarios__c != null;
            Boolean bTiene = b.Horarios__c != null;

            if (aTiene == bTiene) return 0;
            if (aTiene) return -1;
            return 1;
        }
    }
}