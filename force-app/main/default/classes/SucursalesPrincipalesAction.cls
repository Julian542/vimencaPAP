public with sharing class SucursalesPrincipalesAction {

    public class Request {
        @InvocableVariable
        public String dummy;
    }

    public class Response {
        @InvocableVariable
        public String nombre;

        @InvocableVariable
        public String direccion;

        @InvocableVariable
        public String telefono;

        @InvocableVariable
        public String horarios;

        @InvocableVariable
        public String servicios;
    }

    @InvocableMethod(label='Obtener sucursales principales')
    public static List<List<Response>> execute(List<Request> requests) {

        List<List<Response>> result = new List<List<Response>>();

        // 🔥 LISTA DE PRINCIPALES
        List<String> principales = new List<String>{
            'Banco Múltiple Vimenca - Santiago',
            'Banco Múltiple Vimenca - San Cristóbal',
            'Banco Multiple Vimenca - El Portal',
            'Banco Múltiple Vimenca - Ágora Santiago Center',
            'Banco Múltiple Vimenca - Punta Cana',
            'Banco Múltiple Vimenca - Plaza Paseo 27',
            'Banco Múltiple Vimenca - Megacentro',
            'Banco Múltiple Vimenca - Lope de Vega',
            'Banco Múltiple Vimenca - Lincoln'
        };

        List<Sucursal__c> sucursales = [
            SELECT 
                Name, 
                SUC_Address__c, 
                SUC_Phone__c, 
                Horarios__c,
                SUC_ServicesOffered__c
            FROM Sucursal__c
            WHERE Name IN :principales
            AND SUC_Active__c = true
        ];

        for (Request req : requests) {

            List<Response> respuestas = new List<Response>();

            for (Sucursal__c s : sucursales) {

                Response r = new Response();
                r.nombre = s.Name;
                r.direccion = s.SUC_Address__c;
                r.telefono = s.SUC_Phone__c;
                r.horarios = s.Horarios__c;
                r.servicios = s.SUC_ServicesOffered__c;

                respuestas.add(r);
            }

            result.add(respuestas);
        }

        return result;
    }
}