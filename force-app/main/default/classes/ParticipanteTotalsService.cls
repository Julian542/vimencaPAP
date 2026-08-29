/**
 * @description       : Servicio para recalcular participantes no aprobados en Lead/Candidato principal.
 * @author            : Jhonny Peroza
 * @last modified on  : 26-05-2026
 * @last modified by  : Jhonny Peroza
 **/
public with sharing class ParticipanteTotalsService {

    private static final Set<String> ESTADOS_PARTICIPANTE_NO_APROBADO = new Set<String>{
        'Iniciado',
        'Calificado',
        'Validado',
        'Rechazado'
    };

    public static void recalcularPorLeadsParticipantes(Set<Id> participantLeadIds) {
        System.debug('ParticipanteTotalsService.recalcularPorLeadsParticipantes() participantLeadIds=' + participantLeadIds);

        if (participantLeadIds == null || participantLeadIds.isEmpty()) {
            System.debug('ParticipanteTotalsService.recalcularPorLeadsParticipantes() no hay Leads participantes para recalcular.');
            return;
        }

        try {
            Set<Id> leadPrincipalIds = new Set<Id>();

            System.debug('ParticipanteTotalsService.recalcularPorLeadsParticipantes() ejecutando query Participante__c por Lead participante.');

            for (Participante__c participante : [
                SELECT Id, PAR_Candidato__c, PAR_Participante_Candidato__c
                FROM Participante__c
                WHERE PAR_Participante_Candidato__c IN :participantLeadIds
                AND PAR_Candidato__c != null
            ]) {
                leadPrincipalIds.add(participante.PAR_Candidato__c);

                System.debug(
                    'ParticipanteTotalsService.recalcularPorLeadsParticipantes() participanteId=' + participante.Id +
                    ', leadPrincipal=' + participante.PAR_Candidato__c +
                    ', leadParticipante=' + participante.PAR_Participante_Candidato__c
                );
            }

            System.debug('ParticipanteTotalsService.recalcularPorLeadsParticipantes() leadPrincipalIds=' + leadPrincipalIds);

            recalcularPorCandidatosPrincipales(leadPrincipalIds);

        } catch (Exception e) {
            System.debug('ERROR ParticipanteTotalsService.recalcularPorLeadsParticipantes: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw e;
        }
    }

    public static void recalcularPorCandidatosPrincipales(Set<Id> leadPrincipalIds) {
        System.debug('ParticipanteTotalsService.recalcularPorCandidatosPrincipales() leadPrincipalIds=' + leadPrincipalIds);

        if (leadPrincipalIds == null || leadPrincipalIds.isEmpty()) {
            System.debug('ParticipanteTotalsService.recalcularPorCandidatosPrincipales() no hay candidatos principales para recalcular.');
            return;
        }

        try {
            Map<Id, Integer> totalNoAprobadosPorLead = new Map<Id, Integer>();

            for (Id leadId : leadPrincipalIds) {
                totalNoAprobadosPorLead.put(leadId, 0);
            }

            System.debug('ParticipanteTotalsService.recalcularPorCandidatosPrincipales() ejecutando query Participante__c.');

            List<Participante__c> participantes = [
                SELECT Id, PAR_Candidato__c, PAR_Participante_Candidato__c
                FROM Participante__c
                WHERE PAR_Candidato__c IN :leadPrincipalIds
                AND PAR_Participante_Candidato__c != null
            ];

            System.debug('ParticipanteTotalsService.recalcularPorCandidatosPrincipales() participantes size=' + participantes.size());

            Set<Id> participantLeadIds = new Set<Id>();

            for (Participante__c participante : participantes) {
                participantLeadIds.add(participante.PAR_Participante_Candidato__c);
            }

            System.debug('ParticipanteTotalsService.recalcularPorCandidatosPrincipales() participantLeadIds=' + participantLeadIds);

            Map<Id, Lead> participantLeadById = new Map<Id, Lead>();

            if (!participantLeadIds.isEmpty()) {
                System.debug('ParticipanteTotalsService.recalcularPorCandidatosPrincipales() ejecutando query Lead participantes.');

                participantLeadById = new Map<Id, Lead>([
                    SELECT Id, Status
                    FROM Lead
                    WHERE Id IN :participantLeadIds
                ]);
            }

            for (Participante__c participante : participantes) {
                if (participante.PAR_Candidato__c == null || participante.PAR_Participante_Candidato__c == null) {
                    continue;
                }

                Lead leadParticipante = participantLeadById.get(participante.PAR_Participante_Candidato__c);

                if (leadParticipante == null) {
                    continue;
                }

                System.debug(
                    'ParticipanteTotalsService.recalcularPorCandidatosPrincipales() participanteId=' + participante.Id +
                    ', leadPrincipal=' + participante.PAR_Candidato__c +
                    ', leadParticipante=' + participante.PAR_Participante_Candidato__c +
                    ', statusParticipante=' + leadParticipante.Status
                );

                if (ESTADOS_PARTICIPANTE_NO_APROBADO.contains(leadParticipante.Status)) {
                    Integer totalActual = totalNoAprobadosPorLead.containsKey(participante.PAR_Candidato__c)
                        ? totalNoAprobadosPorLead.get(participante.PAR_Candidato__c)
                        : 0;

                    totalNoAprobadosPorLead.put(participante.PAR_Candidato__c, totalActual + 1);
                }
            }

            List<Lead> leadsToUpdate = new List<Lead>();

            for (Id leadPrincipalId : leadPrincipalIds) {
                Integer totalNoAprobados = totalNoAprobadosPorLead.containsKey(leadPrincipalId)
                    ? totalNoAprobadosPorLead.get(leadPrincipalId)
                    : 0;

                Lead leadToUpdate = new Lead(
                    Id = leadPrincipalId,
                    LEA_N_Participantes__c = totalNoAprobados
                );

                leadsToUpdate.add(leadToUpdate);

                System.debug(
                    'ParticipanteTotalsService.recalcularPorCandidatosPrincipales() Lead preparado. leadId=' + leadPrincipalId +
                    ', LEA_N_Participantes__c=' + totalNoAprobados
                );
            }

            System.debug('ParticipanteTotalsService.recalcularPorCandidatosPrincipales() leadsToUpdate size=' + leadsToUpdate.size());

            if (!leadsToUpdate.isEmpty()) {
                update leadsToUpdate;
            }

        } catch (Exception e) {
            System.debug('ERROR ParticipanteTotalsService.recalcularPorCandidatosPrincipales: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw e;
        }
    }
}