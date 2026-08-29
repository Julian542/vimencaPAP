/**
 * Name: LeadTriggerHandler
 * Description:
 *  Handler del Trigger del objeto Lead.
 *  Valida duplicidad, limpia campos de identificación,
 *  envía aprobación PLA cuando aplica y bloquea conversión si existen
 *  participantes candidatos pendientes.
 *
 * Last modified: 2026-05-15
 * Autor: Jhonny Peroza
 */
public with sharing class LeadTriggerHandler {

    private static Boolean alreadyRan = false;

    private static final String RECORD_TYPE_CANDIDATO_PERSONA_FISICA = 'Candidato Persona Física';

    private static final Set<String> ESTADOS_VALIDOS_PARTICIPANTE_CANDIDATO = new Set<String>{
        'Validado',
        'Aprobado',
        'Convertido a cliente'
    };

    public static void beforeSave(List<Lead> newList, Map<Id, Lead> oldMap) {

        System.debug('on LeadTriggerHandler.beforeSave()');
        System.debug('LeadTriggerHandler.beforeSave() newList size=' + (newList == null ? 0 : newList.size()));
        System.debug('LeadTriggerHandler.beforeSave() oldMap disponible=' + (oldMap != null));

        setDefaultPersonLeadFields(newList);
        validateParticipantCandidatesBeforeConversion(newList, oldMap);
        cleanIdentificationFields(newList);
        validateUniqueIdentification(newList, oldMap);
        validateUniqueRNC(newList, oldMap);
    }

    public static void afterUpdate(List<Lead> newList, Map<Id, Lead> oldMap) {

        System.debug('on LeadTriggerHandler.afterUpdate()');

        if (alreadyRan) return;
        alreadyRan = true;

        submitPLAApprovalIfNeeded(newList, oldMap);

        Set<Id> convertedLeadIds = new Set<Id>();

        for (Lead l : newList) {
            Lead oldL = (oldMap != null) ? oldMap.get(l.Id) : null;

            if (l != null && l.IsConverted == true && (oldL == null || oldL.IsConverted != true)) {
                convertedLeadIds.add(l.Id);
            }
        }

        // if (!convertedLeadIds.isEmpty()) {
        //     System.debug('Enqueue LeadConversionQueue leads=' + convertedLeadIds.size());
        //     System.enqueueJob(new LeadConversionQueue(convertedLeadIds));
        // }
    }

    private static void setDefaultPersonLeadFields(List<Lead> newList) {
        System.debug('on LeadTriggerHandler.setDefaultPersonLeadFields()');

        if (newList == null || newList.isEmpty()) {
            return;
        }

        Set<Id> recordTypeIds = new Set<Id>();

        for (Lead l : newList) {
            if (l != null && l.RecordTypeId != null) {
                recordTypeIds.add(l.RecordTypeId);
            }
        }

        if (recordTypeIds.isEmpty()) {
            return;
        }

        Map<Id, RecordType> recordTypesById = new Map<Id, RecordType>([
            SELECT Id, Name, DeveloperName
            FROM RecordType
            WHERE Id IN :recordTypeIds
        ]);

        for (Lead l : newList) {
            if (l == null || l.RecordTypeId == null) {
                continue;
            }

            RecordType rt = recordTypesById.get(l.RecordTypeId);

            if (rt == null || rt.Name != RECORD_TYPE_CANDIDATO_PERSONA_FISICA) {
                continue;
            }

            System.debug('LeadTriggerHandler.setDefaultPersonLeadFields() aplicando defaults a Lead Id=' + l.Id);

            if (String.isBlank(l.LEA_Persona_PEP__c)) {
                l.LEA_Persona_PEP__c = 'NO';
            }

            if (l.LEA_Posee_Resid_Otro_Pais__c == null) {
                l.LEA_Posee_Resid_Otro_Pais__c = false;
            }

            if (l.LEA_Posee_Resid_Otro_Pais__c == false) {
                l.LEA_INT_Pais_Residencia_Legal__c = 'REPUBLICA DOMINICANA';
                l.LEA_Pais_Residencia_Legal__c = 'REPUBLICA DOMINICANA';
            }
        }
    }

    private static void validateParticipantCandidatesBeforeConversion(List<Lead> newList, Map<Id, Lead> oldMap) {
        System.debug('on LeadTriggerHandler.validateParticipantCandidatesBeforeConversion()');

        if (newList == null || newList.isEmpty() || oldMap == null || oldMap.isEmpty()) {
            return;
        }

        Set<Id> leadIdsToValidate = new Set<Id>();

        for (Lead newLead : newList) {
            if (newLead == null || newLead.Id == null) {
                continue;
            }

            Lead oldLead = oldMap.get(newLead.Id);

            Boolean isRealConversion =
                oldLead != null &&
                oldLead.IsConverted == false &&
                newLead.IsConverted == true;

            System.debug(
                'LeadTriggerHandler.validateParticipantCandidatesBeforeConversion() Lead evaluado Id=' + newLead.Id +
                ', oldIsConverted=' + (oldLead == null ? null : oldLead.IsConverted) +
                ', newIsConverted=' + newLead.IsConverted +
                ', isRealConversion=' + isRealConversion
            );

            if (isRealConversion) {
                leadIdsToValidate.add(newLead.Id);
            }
        }

        System.debug('LeadTriggerHandler.validateParticipantCandidatesBeforeConversion() leadIdsToValidate=' + leadIdsToValidate);

        if (leadIdsToValidate.isEmpty()) {
            return;
        }

        List<Participante__c> invalidParticipants = [
            SELECT Id,
                   Name,
                   PAR_Candidato__c,
                   PAR_Participante_Candidato__c,
                   PAR_Participante_Candidato__r.Name,
                   PAR_Participante_Candidato__r.Status
            FROM Participante__c
            WHERE PAR_Candidato__c IN :leadIdsToValidate
            AND PAR_Participante_Candidato__c != null
            AND (
                PAR_Participante_Candidato__r.Status = null
                OR PAR_Participante_Candidato__r.Status NOT IN :ESTADOS_VALIDOS_PARTICIPANTE_CANDIDATO
            )
        ];

        System.debug('LeadTriggerHandler.validateParticipantCandidatesBeforeConversion() invalidParticipants size=' + invalidParticipants.size());

        Map<Id, List<String>> invalidParticipantNamesByLeadId = new Map<Id, List<String>>();

        for (Participante__c participant : invalidParticipants) {
            if (participant == null || participant.PAR_Candidato__c == null) {
                continue;
            }

            if (!invalidParticipantNamesByLeadId.containsKey(participant.PAR_Candidato__c)) {
                invalidParticipantNamesByLeadId.put(participant.PAR_Candidato__c, new List<String>());
            }

            String participantName = 'Participante candidato pendiente';

            if (participant.PAR_Participante_Candidato__r != null) {
                participantName =
                    String.valueOf(participant.PAR_Participante_Candidato__r.Name) +
                    ' - Estado: ' +
                    String.valueOf(participant.PAR_Participante_Candidato__r.Status);
            }

            invalidParticipantNamesByLeadId.get(participant.PAR_Candidato__c).add(participantName);

            System.debug(
                'LeadTriggerHandler.validateParticipantCandidatesBeforeConversion() participante inválido. ' +
                'leadPrincipal=' + participant.PAR_Candidato__c +
                ', participanteId=' + participant.Id +
                ', candidatoParticipante=' + participant.PAR_Participante_Candidato__c +
                ', nombreEstado=' + participantName
            );
        }

        for (Lead newLead : newList) {
            if (newLead == null || newLead.Id == null) {
                continue;
            }

            if (invalidParticipantNamesByLeadId.containsKey(newLead.Id)) {
                String participantesPendientes = String.join(invalidParticipantNamesByLeadId.get(newLead.Id), ', ');

                newLead.addError(
                    'No puede convertir este candidato porque existen participantes candidatos pendientes de validación: ' +
                    participantesPendientes +
                    '. Todos los participantes candidatos deben estar en estado Validado, Aprobado o Convertido a cliente.'
                );

                System.debug(
                    'LeadTriggerHandler.validateParticipantCandidatesBeforeConversion() addError aplicado al Lead=' +
                    newLead.Id +
                    ', participantesPendientes=' +
                    participantesPendientes
                );
            }
        }
    }

    private static void submitPLAApprovalIfNeeded(List<Lead> newList, Map<Id, Lead> oldMap) {
        System.debug('LeadTriggerHandler.submitPLAApprovalIfNeeded() inicio');
        System.debug('LeadTriggerHandler.submitPLAApprovalIfNeeded() newList size=' + (newList == null ? 0 : newList.size()));
        System.debug('LeadTriggerHandler.submitPLAApprovalIfNeeded() oldMap disponible=' + (oldMap != null));

        if (newList == null || newList.isEmpty()) {
            System.debug('LeadTriggerHandler.submitPLAApprovalIfNeeded() no hay Leads para procesar');
            return;
        }

        try {
            Set<Id> leadIdsToSubmit = new Set<Id>();

            for (Lead newLead : newList) {
                if (newLead == null || newLead.Id == null) {
                    continue;
                }

                Lead oldLead = oldMap != null ? oldMap.get(newLead.Id) : null;

                Boolean statusChanged = oldLead == null || newLead.Status != oldLead.Status;

                Boolean statusAplica =
                    newLead.Status == 'Validado' ||
                    newLead.Status == 'Aprobado';

                Boolean tieneDocsNoAprobados =
                    newLead.LEA_Doc_Legal_No_Aprobada__c != null &&
                    newLead.LEA_Doc_Legal_No_Aprobada__c > 0;

                System.debug(
                    'LeadTriggerHandler.submitPLAApprovalIfNeeded() Lead evaluado. Id=' + newLead.Id +
                    ', oldStatus=' + (oldLead == null ? null : oldLead.Status) +
                    ', newStatus=' + newLead.Status +
                    ', statusChanged=' + statusChanged +
                    ', statusAplica=' + statusAplica +
                    ', LEA_Doc_Legal_No_Aprobada__c=' + newLead.LEA_Doc_Legal_No_Aprobada__c +
                    ', tieneDocsNoAprobados=' + tieneDocsNoAprobados
                );

                if (statusChanged && statusAplica && tieneDocsNoAprobados) {
                    leadIdsToSubmit.add(newLead.Id);
                }
            }

            System.debug('LeadTriggerHandler.submitPLAApprovalIfNeeded() leadIdsToSubmit=' + leadIdsToSubmit);

            if (leadIdsToSubmit.isEmpty()) {
                System.debug('LeadTriggerHandler.submitPLAApprovalIfNeeded() no hay Leads para enviar a aprobación');
                return;
            }

            Set<Id> leadIdsAlreadyPending = new Set<Id>();

            System.debug('LeadTriggerHandler.submitPLAApprovalIfNeeded() query ProcessInstance Pending');

            for (ProcessInstance pi : [
                SELECT Id, TargetObjectId, Status
                FROM ProcessInstance
                WHERE TargetObjectId IN :leadIdsToSubmit
                AND Status = 'Pending'
            ]) {
                leadIdsAlreadyPending.add(pi.TargetObjectId);
            }

            System.debug('LeadTriggerHandler.submitPLAApprovalIfNeeded() leadIdsAlreadyPending=' + leadIdsAlreadyPending);

            for (Id leadId : leadIdsToSubmit) {
                if (leadIdsAlreadyPending.contains(leadId)) {
                    System.debug('LeadTriggerHandler.submitPLAApprovalIfNeeded() Lead ya está en aprobación. leadId=' + leadId);
                    continue;
                }

                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(leadId);
                req.setSubmitterId(UserInfo.getUserId());
                req.setComments('Enviado automáticamente a revisión PLA porque posee documentos legales no aprobados.');

                System.debug('LeadTriggerHandler.submitPLAApprovalIfNeeded() enviando Lead a aprobación PLA. leadId=' + leadId);

                Approval.ProcessResult result = Approval.process(req);

                System.debug('LeadTriggerHandler.submitPLAApprovalIfNeeded() resultado leadId=' + leadId);
                System.debug('LeadTriggerHandler.submitPLAApprovalIfNeeded() result.isSuccess=' + result.isSuccess());
                System.debug('LeadTriggerHandler.submitPLAApprovalIfNeeded() result.instanceId=' + result.getInstanceId());
            }

        } catch (Exception e) {
            System.debug('ERROR LeadTriggerHandler.submitPLAApprovalIfNeeded: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw e;
        }
    }

    private static void cleanIdentificationFields(List<Lead> newList) {
        System.debug('on LeadTriggerHandler.cleanIdentificationFields()');

        if (newList == null || newList.isEmpty()) {
            return;
        }

        for (Lead l : newList) {
            if (l == null) {
                continue;
            }

            if (
                l.LEA_NumIdentificacion__c != null &&
                !isPassport(l.LEA_TipoIdentificacion__c)
            ) {
                l.LEA_NumIdentificacion__c = l.LEA_NumIdentificacion__c.replaceAll('[^0-9]', '');
            }

            if (l.LEA_RNC__c != null) {
                l.LEA_RNC__c = l.LEA_RNC__c.replaceAll('[^0-9]', '');
            }
        }
    }

    private static void validateUniqueIdentification(List<Lead> newList, Map<Id, Lead> oldMap) {
        System.debug('on LeadTriggerHandler.validateUniqueIdentification()');

        if (newList == null || newList.isEmpty()) {
            return;
        }

        Set<String> tiposIdentificacion = new Set<String>();
        Set<String> numerosIdentificacion = new Set<String>();
        Set<String> clavesEnTransaccion = new Set<String>();
        Set<String> clavesDuplicadasEnTransaccion = new Set<String>();
        Set<Id> leadIdsActuales = new Set<Id>();
        List<Lead> leadsAValidar = new List<Lead>();

        for (Lead l : newList) {
            if (l == null) {
                continue;
            }

            if (l.Id != null) {
                leadIdsActuales.add(l.Id);
            }

            Boolean debeValidar = oldMap == null || !oldMap.containsKey(l.Id);

            if (!debeValidar && oldMap != null && l.Id != null) {
                Lead oldLead = oldMap.get(l.Id);

                debeValidar =
                    oldLead != null &&
                    (
                        l.LEA_TipoIdentificacion__c != oldLead.LEA_TipoIdentificacion__c ||
                        l.LEA_NumIdentificacion__c != oldLead.LEA_NumIdentificacion__c
                    );
            }

            if (!debeValidar) {
                continue;
            }

            if (
                String.isBlank(l.LEA_TipoIdentificacion__c) ||
                String.isBlank(l.LEA_NumIdentificacion__c)
            ) {
                continue;
            }

            leadsAValidar.add(l);

            String clave = buildIdentificationKey(l.LEA_TipoIdentificacion__c, l.LEA_NumIdentificacion__c);

            if (clavesEnTransaccion.contains(clave)) {
                clavesDuplicadasEnTransaccion.add(clave);
            }

            clavesEnTransaccion.add(clave);
            tiposIdentificacion.add(l.LEA_TipoIdentificacion__c);
            numerosIdentificacion.add(l.LEA_NumIdentificacion__c);
        }

        if (leadsAValidar.isEmpty()) {
            return;
        }

        for (Lead l : leadsAValidar) {
            String clave = buildIdentificationKey(l.LEA_TipoIdentificacion__c, l.LEA_NumIdentificacion__c);

            if (clavesDuplicadasEnTransaccion.contains(clave)) {
                l.addError('Ya existe otro candidato en esta misma operación con el mismo tipo y número de identificación.');
            }
        }

        if (tiposIdentificacion.isEmpty() || numerosIdentificacion.isEmpty()) {
            return;
        }

        System.debug('Query Lead - Validar combinación tipo/número de identificación');

        List<Lead> leadsExistentes = [
            SELECT Id, LEA_TipoIdentificacion__c, LEA_NumIdentificacion__c
            FROM Lead
            WHERE LEA_TipoIdentificacion__c IN :tiposIdentificacion
            AND LEA_NumIdentificacion__c IN :numerosIdentificacion
        ];

        System.debug('leadsExistentes size: ' + leadsExistentes.size());

        Set<String> clavesExistentes = new Set<String>();

        for (Lead existente : leadsExistentes) {
            if (leadIdsActuales.contains(existente.Id)) {
                continue;
            }

            clavesExistentes.add(
                buildIdentificationKey(
                    existente.LEA_TipoIdentificacion__c,
                    existente.LEA_NumIdentificacion__c
                )
            );
        }

        for (Lead l : leadsAValidar) {
            String clave = buildIdentificationKey(l.LEA_TipoIdentificacion__c, l.LEA_NumIdentificacion__c);

            if (clavesExistentes.contains(clave)) {
                l.addError('Ya existe un candidato con el mismo tipo y número de identificación.');
            }
        }
    }

    private static void validateUniqueRNC(List<Lead> newList, Map<Id, Lead> oldMap) {
        System.debug('on LeadTriggerHandler.validateUniqueRNC()');

        if (newList == null || newList.isEmpty()) {
            return;
        }

        Set<String> rncs = new Set<String>();
        Set<String> rncsEnTransaccion = new Set<String>();
        Set<String> rncsDuplicadosEnTransaccion = new Set<String>();
        Set<Id> leadIdsActuales = new Set<Id>();
        List<Lead> leadsAValidar = new List<Lead>();

        for (Lead l : newList) {
            if (l == null) {
                continue;
            }

            if (l.Id != null) {
                leadIdsActuales.add(l.Id);
            }

            Boolean debeValidar = oldMap == null || !oldMap.containsKey(l.Id);

            if (!debeValidar && oldMap != null && l.Id != null) {
                Lead oldLead = oldMap.get(l.Id);

                debeValidar =
                    oldLead != null &&
                    l.LEA_RNC__c != oldLead.LEA_RNC__c;
            }

            if (!debeValidar) {
                continue;
            }

            if (String.isBlank(l.LEA_RNC__c)) {
                continue;
            }

            leadsAValidar.add(l);

            String rncNormalizado = buildRNCKey(l.LEA_RNC__c);

            if (rncsEnTransaccion.contains(rncNormalizado)) {
                rncsDuplicadosEnTransaccion.add(rncNormalizado);
            }

            rncsEnTransaccion.add(rncNormalizado);
            rncs.add(rncNormalizado);
        }

        if (leadsAValidar.isEmpty()) {
            return;
        }

        for (Lead l : leadsAValidar) {
            String rncNormalizado = buildRNCKey(l.LEA_RNC__c);

            if (rncsDuplicadosEnTransaccion.contains(rncNormalizado)) {
                l.addError('Ya existe otro candidato en esta misma operación con el mismo RNC.');
            }
        }

        if (rncs.isEmpty()) {
            return;
        }

        System.debug('Query Lead - Validar duplicidad de RNC');

        List<Lead> leadsExistentes = [
            SELECT Id, LEA_RNC__c
            FROM Lead
            WHERE LEA_RNC__c IN :rncs
        ];

        System.debug('leadsExistentes por RNC size: ' + leadsExistentes.size());

        Set<String> rncsExistentes = new Set<String>();

        for (Lead existente : leadsExistentes) {
            if (leadIdsActuales.contains(existente.Id)) {
                continue;
            }

            if (String.isBlank(existente.LEA_RNC__c)) {
                continue;
            }

            rncsExistentes.add(buildRNCKey(existente.LEA_RNC__c));
        }

        for (Lead l : leadsAValidar) {
            String rncNormalizado = buildRNCKey(l.LEA_RNC__c);

            if (rncsExistentes.contains(rncNormalizado)) {
                l.addError('Ya existe un candidato Persona Jurídica con el mismo RNC.');
            }
        }
    }

    private static String buildIdentificationKey(String tipoIdentificacion, String numeroIdentificacion) {
        System.debug('on LeadTriggerHandler.buildIdentificationKey()');

        return String.valueOf(tipoIdentificacion).trim().toUpperCase() +
            '-' +
            String.valueOf(numeroIdentificacion).trim().toUpperCase();
    }

    private static String buildRNCKey(String rnc) {
        System.debug('on LeadTriggerHandler.buildRNCKey()');

        return String.valueOf(rnc).trim().toUpperCase();
    }

    private static Boolean isPassport(String tipoIdentificacion) {
        System.debug('on LeadTriggerHandler.isPassport()');

        return String.valueOf(tipoIdentificacion).trim().toUpperCase() == 'PASAPORTE';
    }
}