global with sharing class VimencaAutoRejectLeadBatch 
    implements Database.Batchable<SObject>, Schedulable {

    private static final String STATUS_RECHAZADO = 'Rechazado';

    global Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug(LoggingLevel.DEBUG, 'start()');

        Datetime limite = System.now().addDays(-7);

        return Database.getQueryLocator([
            SELECT Id, Status, IsConverted, CreatedDate, LeadSource
            FROM Lead
            WHERE IsConverted = false
              AND CreatedDate <= :limite
              AND Status != :STATUS_RECHAZADO
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Lead> scope) {
        System.debug(LoggingLevel.DEBUG, 'execute() - scope size: ' + scope.size());

        try {
            List<Lead> leadsToUpdate = new List<Lead>();

            for (Lead ld : scope) {
                Lead upd = new Lead(
                    Id = ld.Id,
                    Status = STATUS_RECHAZADO,
                    LEA_Motivo_de_rechazo__c = 'Rechazado automático - Tiempo de espera agotado'
                );
                leadsToUpdate.add(upd);
            }

            if (!leadsToUpdate.isEmpty()) {
                Database.SaveResult[] results = Database.update(leadsToUpdate, false);

                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        for (Database.Error err : results[i].getErrors()) {
                            System.debug(
                                LoggingLevel.ERROR,
                                'Error actualizando Lead ' + leadsToUpdate[i].Id + ': ' + err.getMessage()
                            );
                        }
                    }
                }
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error en execute(): ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.DEBUG, 'finish()');
    }

    global void execute(SchedulableContext sc) {
        System.debug(LoggingLevel.DEBUG, 'execute(SchedulableContext)');
        Database.executeBatch(new VimencaAutoRejectLeadBatch(), 200);
    }
}