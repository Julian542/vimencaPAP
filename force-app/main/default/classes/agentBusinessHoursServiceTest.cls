@IsTest(SeeAllData=true)
private class agentBusinessHoursServiceTest {

    @IsTest
    static void testValidateAvailability_NullRequests() {
        Test.startTest();
        List<agentBusinessHoursService.Result> results =
            agentBusinessHoursService.validateAvailability(null);
        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assertEquals(0, results.size());
    }

    @IsTest
    static void testValidateAvailability_EmptyRequests() {
        Test.startTest();
        List<agentBusinessHoursService.Result> results =
            agentBusinessHoursService.validateAvailability(
                new List<agentBusinessHoursService.Request>()
            );
        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assertEquals(0, results.size());
    }

    @IsTest
    static void testValidateAvailability_BusinessHoursNotFound_WithCustomMessage() {
        agentBusinessHoursService.Request req = new agentBusinessHoursService.Request();
        req.businessHoursName = 'BH_INEXISTENTE_TEST';
        req.unavailableMessage = 'Mensaje personalizado de no disponibilidad.';

        Test.startTest();
        List<agentBusinessHoursService.Result> results =
            agentBusinessHoursService.validateAvailability(
                new List<agentBusinessHoursService.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());

        agentBusinessHoursService.Result res = results[0];
        System.assertEquals(false, res.isAvailable);
        System.assertEquals('Mensaje personalizado de no disponibilidad.', res.messageToUser);
        System.assertEquals(null, res.nextOpenAt);
        System.assertEquals('BH_INEXISTENTE_TEST', res.resolvedBusinessHoursName);
        System.assertEquals(null, res.timeZoneSidKey);
    }

    @IsTest
    static void testValidateAvailability_DefaultName_NotFound_UsesDefaultMessage() {
        agentBusinessHoursService.Request req = new agentBusinessHoursService.Request();
        req.businessHoursName = null;
        req.unavailableMessage = null;

        Test.startTest();
        List<agentBusinessHoursService.Result> results =
            agentBusinessHoursService.validateAvailability(
                new List<agentBusinessHoursService.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());

        agentBusinessHoursService.Result res = results[0];
        System.assertEquals('AGENTE - Teleasistencia', res.resolvedBusinessHoursName);
        System.assertNotEquals(null, res.timeZoneSidKey);
        if (res.isAvailable) {
            System.assertEquals(null, res.messageToUser);
            System.assertNotEquals(null, res.nextOpenAt);
        } else {
            System.assertEquals(
                'En este momento no tenemos agentes disponibles. Nuestro horario de atención es de lunes a viernes, de 7:00 AM a 12:00 AM, hora de República Dominicana.',
                res.messageToUser
            );
        }
    }

    @IsTest
    static void testValidateAvailability_FoundBusinessHours() {
        BusinessHours bh = [
            SELECT Id, Name, TimeZoneSidKey
            FROM BusinessHours
            LIMIT 1
        ];

        agentBusinessHoursService.Request req = new agentBusinessHoursService.Request();
        req.businessHoursName = bh.Name;
        req.unavailableMessage = 'Mensaje custom fuera de horario.';

        Test.startTest();
        List<agentBusinessHoursService.Result> results =
            agentBusinessHoursService.validateAvailability(
                new List<agentBusinessHoursService.Request>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());

        agentBusinessHoursService.Result res = results[0];
        System.assertEquals(bh.Name, res.resolvedBusinessHoursName);
        System.assertEquals(bh.TimeZoneSidKey, res.timeZoneSidKey);

        if (res.isAvailable) {
            System.assertEquals(null, res.messageToUser);
            System.assertNotEquals(null, res.nextOpenAt);
        } else {
            System.assertEquals('Mensaje custom fuera de horario.', res.messageToUser);
        }
    }

    @IsTest
    static void testValidateAvailability_MultipleRequests() {
        BusinessHours bh = [
            SELECT Id, Name, TimeZoneSidKey
            FROM BusinessHours
            LIMIT 1
        ];

        agentBusinessHoursService.Request req1 = new agentBusinessHoursService.Request();
        req1.businessHoursName = bh.Name;
        req1.unavailableMessage = 'Fuera de horario BH existente.';

        agentBusinessHoursService.Request req2 = new agentBusinessHoursService.Request();
        req2.businessHoursName = 'BH_QUE_NO_EXISTE';
        req2.unavailableMessage = 'Fuera de horario BH inexistente.';

        Test.startTest();
        List<agentBusinessHoursService.Result> results =
            agentBusinessHoursService.validateAvailability(
                new List<agentBusinessHoursService.Request>{ req1, req2 }
            );
        Test.stopTest();

        System.assertEquals(2, results.size());

        System.assertEquals(bh.Name, results[0].resolvedBusinessHoursName);
        System.assertEquals(bh.TimeZoneSidKey, results[0].timeZoneSidKey);

        System.assertEquals(false, results[1].isAvailable);
        System.assertEquals('Fuera de horario BH inexistente.', results[1].messageToUser);
        System.assertEquals('BH_QUE_NO_EXISTE', results[1].resolvedBusinessHoursName);
        System.assertEquals(null, results[1].timeZoneSidKey);
        System.assertEquals(null, results[1].nextOpenAt);
    }
}
