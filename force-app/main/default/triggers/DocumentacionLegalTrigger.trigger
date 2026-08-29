/**
 * @description       : Trigger para recalcular documentos legales no aprobados en Lead/Candidato.
 * @author            : Jhonny Peroza
 * @last modified on  : 12-05-2026
 * @last modified by  : Jhonny Peroza
 **/
trigger DocumentacionLegalTrigger on Documentacion_Legal__c (
    after insert,
    after update,
    after delete,
    after undelete
) {
    System.debug('DocumentacionLegalTrigger iniciado.');
    System.debug('DocumentacionLegalTrigger Trigger.isInsert=' + Trigger.isInsert);
    System.debug('DocumentacionLegalTrigger Trigger.isUpdate=' + Trigger.isUpdate);
    System.debug('DocumentacionLegalTrigger Trigger.isDelete=' + Trigger.isDelete);
    System.debug('DocumentacionLegalTrigger Trigger.isUndelete=' + Trigger.isUndelete);
    System.debug('DocumentacionLegalTrigger Trigger.size=' + Trigger.size);

    try {
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                DocumentacionLegalTriggerHandler.afterInsert(Trigger.new);
            }

            if (Trigger.isUpdate) {
                DocumentacionLegalTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
            }

            if (Trigger.isDelete) {
                DocumentacionLegalTriggerHandler.afterDelete(Trigger.old);
            }

            if (Trigger.isUndelete) {
                DocumentacionLegalTriggerHandler.afterUndelete(Trigger.new);
            }
        }
    } catch (Exception e) {
        System.debug('ERROR DocumentacionLegalTrigger: ' + e.getMessage());
        System.debug(e.getStackTraceString());
        throw e;
    }
}