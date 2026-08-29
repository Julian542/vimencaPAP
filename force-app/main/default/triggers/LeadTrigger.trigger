/**
 * Last modified: 2026-05-12
 * Autor: Jhonny Peroza
 */
trigger LeadTrigger on Lead(before insert, before update, after insert, after update) {
    try {
        System.debug('LeadTrigger iniciado');
        System.debug('LeadTrigger contexto - isBefore: ' + Trigger.isBefore);
        System.debug('LeadTrigger contexto - isAfter: ' + Trigger.isAfter);
        System.debug('LeadTrigger contexto - isInsert: ' + Trigger.isInsert);
        System.debug('LeadTrigger contexto - isUpdate: ' + Trigger.isUpdate);
        System.debug('LeadTrigger tamaño Trigger.new: ' + (Trigger.new != null ? Trigger.new.size() : 0));
        System.debug('LeadTrigger Trigger.oldMap disponible: ' + (Trigger.oldMap != null));

        if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
            System.debug('LeadTrigger entrando a bloque before insert/before update');

            System.debug('LeadTrigger antes de llamar LeadTriggerHandler.beforeSave');
            LeadTriggerHandler.beforeSave(Trigger.new, Trigger.oldMap);
            System.debug('LeadTrigger después de llamar LeadTriggerHandler.beforeSave');

            System.debug('LeadTrigger iniciando limpieza de campos LEA_NumIdentificacion__c y LEA_RNC__c');

            for (Lead l : Trigger.new) {
                if (l == null) {
                    System.debug('LeadTrigger registro Lead nulo en Trigger.new durante limpieza');
                    continue;
                }

                System.debug('LeadTrigger Lead en limpieza - Id: ' + l.Id);
                System.debug('LeadTrigger valor original LEA_NumIdentificacion__c: ' + l.LEA_NumIdentificacion__c);
                System.debug('LeadTrigger valor original LEA_RNC__c: ' + l.LEA_RNC__c);

                if (l.LEA_NumIdentificacion__c != null) {
                    l.LEA_NumIdentificacion__c = l.LEA_NumIdentificacion__c.replaceAll('[^0-9]', '');
                    System.debug('LeadTrigger valor limpio LEA_NumIdentificacion__c: ' + l.LEA_NumIdentificacion__c);
                }

                if (l.LEA_RNC__c != null) {
                    l.LEA_RNC__c = l.LEA_RNC__c.replaceAll('[^0-9]', '');
                    System.debug('LeadTrigger valor limpio LEA_RNC__c: ' + l.LEA_RNC__c);
                }
            }

            System.debug('LeadTrigger finalizó limpieza de campos');
        }

        if (Trigger.isAfter && Trigger.isInsert) {
            LeadAutoQualificationQueue.enqueueEligibleLeads(Trigger.new);
        }

        if (Trigger.isAfter && Trigger.isUpdate) {
            System.debug('LeadTrigger entrando a bloque after update');

            System.debug('LeadTrigger antes de llamar LeadTriggerHandler.afterUpdate');
            LeadTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
            System.debug('LeadTrigger después de llamar LeadTriggerHandler.afterUpdate');

            Set<Id> convertedLeadIds = new Set<Id>();
            System.debug('LeadTrigger iniciando detección de Leads convertidos');

            for (Lead l : Trigger.new) {
                if (l == null) {
                    System.debug('LeadTrigger registro Lead nulo en Trigger.new durante detección de conversión');
                    continue;
                }

                Lead oldL = Trigger.oldMap != null ? Trigger.oldMap.get(l.Id) : null;

                System.debug('LeadTrigger evaluando Lead - Id: ' + l.Id);
                System.debug('LeadTrigger Lead actual IsConverted: ' + l.IsConverted);
                System.debug('LeadTrigger Lead anterior existe: ' + (oldL != null));
                System.debug('LeadTrigger Lead anterior IsConverted: ' + (oldL != null ? oldL.IsConverted : null));
                System.debug('LeadTrigger ConvertedAccountId actual: ' + l.ConvertedAccountId);
                System.debug('LeadTrigger ConvertedContactId actual: ' + l.ConvertedContactId);
                System.debug('LeadTrigger ConvertedOpportunityId actual: ' + l.ConvertedOpportunityId);

                if (l.IsConverted == true && (oldL == null || oldL.IsConverted != true)) {
                    System.debug('LeadTrigger conversión real detectada para Lead Id: ' + l.Id);
                    convertedLeadIds.add(l.Id);
                } else {
                    System.debug('LeadTrigger no se detectó conversión real para Lead Id: ' + l.Id);
                }
            }

            System.debug('LeadTrigger total Leads convertidos detectados: ' + convertedLeadIds.size());
            System.debug('LeadTrigger Leads convertidos detectados: ' + convertedLeadIds);

            if (!convertedLeadIds.isEmpty()) {
                System.debug('LeadTrigger antes de llamar LeadConversionQueue.processLeads');
                System.debug('LeadTrigger IDs enviados a LeadConversionQueue.processLeads: ' + convertedLeadIds);

                LeadConversionQueue.processLeads(convertedLeadIds);

                System.debug('LeadTrigger después de llamar LeadConversionQueue.processLeads');

                /*
                 * Producción:
                 * Descomentar la línea siguiente y comentar la anterior.
                 */
                // System.debug('LeadTrigger antes de encolar LeadConversionQueue');
                // System.enqueueJob(new LeadConversionQueue(convertedLeadIds));
                // System.debug('LeadTrigger después de encolar LeadConversionQueue');
            } else {
                System.debug('LeadTrigger no llama LeadConversionQueue porque no hay Leads convertidos');
            }
        }

        System.debug('LeadTrigger finalizado correctamente');

    } catch (Exception e) {
        System.debug('ERROR LeadTrigger: ' + e.getMessage());
        System.debug('ERROR LeadTrigger stacktrace: ' + e.getStackTraceString());
        throw e;
    }
}