public without sharing class agentBusinessHoursService {

    public class Request {
        @InvocableVariable(label='Business Hours Name' required=false)
        public String businessHoursName;

        @InvocableVariable(label='Unavailable Message' required=false)
        public String unavailableMessage;
    }

    public class Result {
        @InvocableVariable(label='Is Available')
        public Boolean isAvailable;

        @InvocableVariable(label='Message To User')
        public String messageToUser;

        @InvocableVariable(label='Next Open At')
        public String nextOpenAt;

        @InvocableVariable(label='Business Hours Name')
        public String resolvedBusinessHoursName;

        @InvocableVariable(label='Time Zone')
        public String timeZoneSidKey;
    }

    @InvocableMethod(
        label='Validar horario de atención'
        description='Valida si la atención humana está disponible según Business Hours'
    )
    public static List<Result> validateAvailability(List<Request> requests) {
        List<Result> results = new List<Result>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }

        Set<String> names = new Set<String>();
        for (Request req : requests) {
            String bhName = String.isBlank(req.businessHoursName)
                ? 'AGENTE - Teleasistencia'
                : req.businessHoursName.trim();
            names.add(bhName);
        }

        Map<String, BusinessHours> bhByName = new Map<String, BusinessHours>();
        for (BusinessHours bh : [
            SELECT Id, Name, TimeZoneSidKey
            FROM BusinessHours
            WHERE Name IN :names
        ]) {
            bhByName.put(bh.Name, bh);
        }

        for (Request req : requests) {
            Result res = new Result();

            String bhName = String.isBlank(req.businessHoursName)
                ? 'AGENTE - Teleasistencia'
                : req.businessHoursName.trim();

            String fallbackMessage = String.isBlank(req.unavailableMessage)
                ? 'En este momento no tenemos agentes disponibles. Nuestro horario de atención es de lunes a viernes, de 7:00 AM a 12:00 AM, hora de República Dominicana.'
                : req.unavailableMessage;

            if (!bhByName.containsKey(bhName)) {
                res.isAvailable = false;
                res.messageToUser = fallbackMessage;
                res.nextOpenAt = null;
                res.resolvedBusinessHoursName = bhName;
                res.timeZoneSidKey = null;
                results.add(res);
                continue;
            }

            BusinessHours bh = bhByName.get(bhName);

            Datetime nowDt = System.now();
            Boolean available = System.BusinessHours.isWithin(bh.Id, nowDt);

            res.isAvailable = available;
            res.resolvedBusinessHoursName = bh.Name;
            res.timeZoneSidKey = bh.TimeZoneSidKey;

            if (available) {
                res.messageToUser = null;
                res.nextOpenAt = nowDt.format('dd/MM/yyyy hh:mm a', bh.TimeZoneSidKey);
            } else {
                Datetime nextOpen = System.BusinessHours.nextStartDate(bh.Id, nowDt);
                res.nextOpenAt = nextOpen == null
                    ? null
                    : nextOpen.format('dd/MM/yyyy hh:mm a', bh.TimeZoneSidKey);

                res.messageToUser = fallbackMessage;
            }

            results.add(res);
        }

        return results;
    }
}