public with sharing class DocumentosVencimientoNotificScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        System.debug('DocumentosVencimientoNotificationScheduler.execute | Ejecutando batch');
        Database.executeBatch(new DocumentosVencimientoNotificationBatch(), 200);
    }

    public static void scheduleDaily() {
        System.schedule(
            'Notificación diaria documentos por vencer',
            '0 0 7 * * ?',
            new DocumentosVencimientoNotificScheduler()
        );
    }
}