/**
 * @description       : Handler para recalcular en Lead/Candidato la cantidad de documentos legales no aprobados.
 * @author            : Jhonny Peroza
 * @last modified on  : 15-05-2026
 * @last modified by  : Jhonny Peroza
 **/
public with sharing class DocumentacionLegalTriggerHandler {

    private static final String ESTADO_APROBADO = 'APROBADO';

    public static void afterInsert(List<Documentacion_Legal__c> newList) {
        System.debug('DocumentacionLegalTriggerHandler.afterInsert() newList size=' + (newList == null ? 0 : newList.size()));

        try {
            Set<Id> leadIds = getLeadIdsFromNewRecords(newList);

            System.debug('DocumentacionLegalTriggerHandler.afterInsert() leadIds=' + leadIds);

            recalcularDocumentosNoAprobados(leadIds);

        } catch (Exception e) {
            System.debug('ERROR DocumentacionLegalTriggerHandler.afterInsert: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw e;
        }
    }

    public static void afterUpdate(List<Documentacion_Legal__c> newList, Map<Id, Documentacion_Legal__c> oldMap) {
        System.debug('DocumentacionLegalTriggerHandler.afterUpdate() newList size=' + (newList == null ? 0 : newList.size()));
        System.debug('DocumentacionLegalTriggerHandler.afterUpdate() oldMap size=' + (oldMap == null ? 0 : oldMap.size()));

        try {
            Set<Id> leadIds = new Set<Id>();

            if (newList != null) {
                for (Documentacion_Legal__c newDoc : newList) {
                    if (newDoc == null) {
                        continue;
                    }

                    Documentacion_Legal__c oldDoc = oldMap != null ? oldMap.get(newDoc.Id) : null;

                    Boolean candidatoCambio = oldDoc != null && newDoc.DOC_Candidato__c != oldDoc.DOC_Candidato__c;
                    Boolean estadoCambio = oldDoc != null && newDoc.DOC_Estado__c != oldDoc.DOC_Estado__c;

                    System.debug(
                        'DocumentacionLegalTriggerHandler.afterUpdate() docId=' + newDoc.Id +
                        ', candidatoCambio=' + candidatoCambio +
                        ', estadoCambio=' + estadoCambio +
                        ', oldCandidato=' + (oldDoc == null ? null : oldDoc.DOC_Candidato__c) +
                        ', newCandidato=' + newDoc.DOC_Candidato__c +
                        ', oldEstado=' + (oldDoc == null ? null : oldDoc.DOC_Estado__c) +
                        ', newEstado=' + newDoc.DOC_Estado__c
                    );

                    if (candidatoCambio || estadoCambio) {
                        if (newDoc.DOC_Candidato__c != null) {
                            leadIds.add(newDoc.DOC_Candidato__c);
                        }

                        if (oldDoc != null && oldDoc.DOC_Candidato__c != null) {
                            leadIds.add(oldDoc.DOC_Candidato__c);
                        }
                    }
                }
            }

            System.debug('DocumentacionLegalTriggerHandler.afterUpdate() leadIds=' + leadIds);

            recalcularDocumentosNoAprobados(leadIds);

        } catch (Exception e) {
            System.debug('ERROR DocumentacionLegalTriggerHandler.afterUpdate: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw e;
        }
    }

    public static void afterDelete(List<Documentacion_Legal__c> oldList) {
        System.debug('DocumentacionLegalTriggerHandler.afterDelete() oldList size=' + (oldList == null ? 0 : oldList.size()));

        try {
            Set<Id> leadIds = getLeadIdsFromOldRecords(oldList);

            System.debug('DocumentacionLegalTriggerHandler.afterDelete() leadIds=' + leadIds);

            recalcularDocumentosNoAprobados(leadIds);

        } catch (Exception e) {
            System.debug('ERROR DocumentacionLegalTriggerHandler.afterDelete: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw e;
        }
    }

    public static void afterUndelete(List<Documentacion_Legal__c> newList) {
        System.debug('DocumentacionLegalTriggerHandler.afterUndelete() newList size=' + (newList == null ? 0 : newList.size()));

        try {
            Set<Id> leadIds = getLeadIdsFromNewRecords(newList);

            System.debug('DocumentacionLegalTriggerHandler.afterUndelete() leadIds=' + leadIds);

            recalcularDocumentosNoAprobados(leadIds);

        } catch (Exception e) {
            System.debug('ERROR DocumentacionLegalTriggerHandler.afterUndelete: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw e;
        }
    }

    private static Set<Id> getLeadIdsFromNewRecords(List<Documentacion_Legal__c> records) {
        System.debug('DocumentacionLegalTriggerHandler.getLeadIdsFromNewRecords() records size=' + (records == null ? 0 : records.size()));

        Set<Id> leadIds = new Set<Id>();

        if (records == null || records.isEmpty()) {
            return leadIds;
        }

        for (Documentacion_Legal__c doc : records) {
            if (doc != null && doc.DOC_Candidato__c != null) {
                leadIds.add(doc.DOC_Candidato__c);
            }
        }

        System.debug('DocumentacionLegalTriggerHandler.getLeadIdsFromNewRecords() leadIds=' + leadIds);

        return leadIds;
    }

    private static Set<Id> getLeadIdsFromOldRecords(List<Documentacion_Legal__c> records) {
        System.debug('DocumentacionLegalTriggerHandler.getLeadIdsFromOldRecords() records size=' + (records == null ? 0 : records.size()));

        Set<Id> leadIds = new Set<Id>();

        if (records == null || records.isEmpty()) {
            return leadIds;
        }

        for (Documentacion_Legal__c doc : records) {
            if (doc != null && doc.DOC_Candidato__c != null) {
                leadIds.add(doc.DOC_Candidato__c);
            }
        }

        System.debug('DocumentacionLegalTriggerHandler.getLeadIdsFromOldRecords() leadIds=' + leadIds);

        return leadIds;
    }

    public static void recalcularDocumentosNoAprobados(Set<Id> leadIds) {
        System.debug('DocumentacionLegalTriggerHandler.recalcularDocumentosNoAprobados() leadIds=' + leadIds);

        if (leadIds == null || leadIds.isEmpty()) {
            System.debug('DocumentacionLegalTriggerHandler.recalcularDocumentosNoAprobados() no hay candidatos para recalcular.');
            return;
        }

        try {
            Map<Id, Integer> totalDocumentosPorLead = new Map<Id, Integer>();
            Map<Id, Integer> totalNoAprobadosPorLead = new Map<Id, Integer>();

            for (Id leadId : leadIds) {
                totalDocumentosPorLead.put(leadId, 0);
                totalNoAprobadosPorLead.put(leadId, 0);
            }

            System.debug('DocumentacionLegalTriggerHandler.recalcularDocumentosNoAprobados() ejecutando query AggregateResult total documentos.');

            for (AggregateResult ar : [
                SELECT DOC_Candidato__c candidatoId, COUNT(Id) total
                FROM Documentacion_Legal__c
                WHERE DOC_Candidato__c IN :leadIds
                GROUP BY DOC_Candidato__c
            ]) {
                Id candidatoId = (Id) ar.get('candidatoId');
                Integer total = (Integer) ar.get('total');

                totalDocumentosPorLead.put(candidatoId, total);

                System.debug(
                    'DocumentacionLegalTriggerHandler.recalcularDocumentosNoAprobados() candidatoId=' + candidatoId +
                    ', totalDocumentos=' + total
                );
            }

            System.debug('DocumentacionLegalTriggerHandler.recalcularDocumentosNoAprobados() ejecutando query AggregateResult documentos no aprobados.');

            for (AggregateResult ar : [
                SELECT DOC_Candidato__c candidatoId, COUNT(Id) total
                FROM Documentacion_Legal__c
                WHERE DOC_Candidato__c IN :leadIds
                AND (
                    DOC_Estado__c = null
                    OR DOC_Estado__c != :ESTADO_APROBADO
                )
                GROUP BY DOC_Candidato__c
            ]) {
                Id candidatoId = (Id) ar.get('candidatoId');
                Integer total = (Integer) ar.get('total');

                totalNoAprobadosPorLead.put(candidatoId, total);

                System.debug(
                    'DocumentacionLegalTriggerHandler.recalcularDocumentosNoAprobados() candidatoId=' + candidatoId +
                    ', totalNoAprobados=' + total
                );
            }

            List<Lead> leadsToUpdate = new List<Lead>();

            for (Id leadId : leadIds) {
                Integer totalDocumentos = totalDocumentosPorLead.containsKey(leadId)
                    ? totalDocumentosPorLead.get(leadId)
                    : 0;

                Integer totalNoAprobados = totalNoAprobadosPorLead.containsKey(leadId)
                    ? totalNoAprobadosPorLead.get(leadId)
                    : 0;

                Lead leadToUpdate = new Lead(
                    Id = leadId,
                    LEA_N_Documentos__c = totalDocumentos,
                    LEA_Doc_Legal_No_Aprobada__c = totalNoAprobados
                );

                if (totalNoAprobados > 0) {
                    leadToUpdate.Status = 'Validado';
                } else {
                    leadToUpdate.Status = 'Aprobado';
                }

                leadsToUpdate.add(leadToUpdate);

                System.debug(
                    'DocumentacionLegalTriggerHandler.recalcularDocumentosNoAprobados() Lead preparado. leadId=' + leadId +
                    ', LEA_N_Documentos__c=' + totalDocumentos +
                    ', LEA_Doc_Legal_No_Aprobada__c=' + totalNoAprobados +
                    ', Status=' + leadToUpdate.Status
                );
            }

            System.debug('DocumentacionLegalTriggerHandler.recalcularDocumentosNoAprobados() leadsToUpdate size=' + leadsToUpdate.size());

            if (!leadsToUpdate.isEmpty()) {
                update leadsToUpdate;
            }

        } catch (Exception e) {
            System.debug('ERROR DocumentacionLegalTriggerHandler.recalcularDocumentosNoAprobados: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw e;
        }
    }
}