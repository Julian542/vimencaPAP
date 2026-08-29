/**
 * @description       : Controlador para la grilla de documentos legales
 *                      pendientes de aprobación.
 *
 *                      Muestra documentos de candidatos cuya aprobación
 *                      está asignada actualmente a una cola a la que
 *                      pertenece el usuario conectado.
 *
 * @author            : Jhonny Peroza
 **/
public with sharing class LegalDocumentsAssignedGridController {

    /**
     * Fila enviada al LWC.
     */
    public class LegalDocumentRow {

        @AuraEnabled
        public Id documentId;

        @AuraEnabled
        public Id candidateId;

        @AuraEnabled
        public String documentName;

        @AuraEnabled
        public String status;

        @AuraEnabled
        public String candidateName;

        @AuraEnabled
        public Date receivedDate;

        @AuraEnabled
        public Date expirationDate;

        @AuraEnabled
        public String description;

        @AuraEnabled
        public String queueName;

        @AuraEnabled
        public Datetime approvalReceivedDate;
    }

    /**
     * Devuelve los documentos pendientes de aprobación pertenecientes
     * a candidatos cuya aprobación está asignada a una cola del usuario.
     */
    @AuraEnabled(cacheable=true)
    public static List<LegalDocumentRow> getPendingLegalDocuments() {

        System.debug(
            LoggingLevel.DEBUG,
            'LegalDocumentsAssignedGridController.getPendingLegalDocuments()'
        );

        try {

            Id currentUserId = UserInfo.getUserId();

            /*
             * 1. Obtener todas las colas a las que pertenece el usuario,
             *    directa o indirectamente.
             */
            Set<Id> queueIds = getUserQueueIds(currentUserId);

            System.debug(
                LoggingLevel.DEBUG,
                'Colas encontradas para el usuario: ' + queueIds
            );

            if (queueIds.isEmpty()) {
                return new List<LegalDocumentRow>();
            }

            /*
             * 2. Obtener las solicitudes de aprobación pendientes
             *    asignadas actualmente a esas colas.
             *
             * ProcessInstanceWorkitem representa el paso de aprobación
             * que todavía está pendiente.
             */
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id,
                       ActorId,
                       Actor.Name,
                       CreatedDate,
                       ProcessInstanceId,
                       ProcessInstance.TargetObjectId,
                       ProcessInstance.Status
                FROM ProcessInstanceWorkitem
                WHERE ActorId IN :queueIds
                AND ProcessInstance.Status = 'Pending'
                ORDER BY CreatedDate ASC
                LIMIT 2000
            ];

            System.debug(
                LoggingLevel.DEBUG,
                'Workitems encontrados: ' + workItems.size()
            );

            if (workItems.isEmpty()) {
                return new List<LegalDocumentRow>();
            }

            /*
             * Candidatos actualmente pendientes en las colas.
             */
            Set<Id> candidateIds = new Set<Id>();

            /*
             * Cola actual por candidato.
             */
            Map<Id, String> queueNameByCandidateId = new Map<Id, String>();

            /*
             * Fecha en que el paso llegó a la cola.
             */
            Map<Id, Datetime> workItemDateByCandidateId =
                new Map<Id, Datetime>();

            for (ProcessInstanceWorkitem workItem : workItems) {

                Id targetObjectId =
                    workItem.ProcessInstance != null
                    ? workItem.ProcessInstance.TargetObjectId
                    : null;

                if (targetObjectId == null) {
                    continue;
                }

                /*
                 * Los candidatos son registros Lead.
                 */
                if (targetObjectId.getSObjectType() != Lead.SObjectType) {
                    continue;
                }

                candidateIds.add(targetObjectId);

                if (!queueNameByCandidateId.containsKey(targetObjectId)) {
                    queueNameByCandidateId.put(
                        targetObjectId,
                        workItem.Actor != null
                            ? workItem.Actor.Name
                            : null
                    );
                }

                if (!workItemDateByCandidateId.containsKey(targetObjectId)) {
                    workItemDateByCandidateId.put(
                        targetObjectId,
                        workItem.CreatedDate
                    );
                }
            }

            System.debug(
                LoggingLevel.DEBUG,
                'Candidatos encontrados en aprobación: ' + candidateIds
            );

            if (candidateIds.isEmpty()) {
                return new List<LegalDocumentRow>();
            }

            /*
             * 3. Obtener los candidatos.
             */
            Map<Id, Lead> candidatesById = new Map<Id, Lead>([
                SELECT Id,
                       Name,
                       RecordType.DeveloperName
                FROM Lead
                WHERE Id IN :candidateIds
            ]);

            if (candidatesById.isEmpty()) {
                return new List<LegalDocumentRow>();
            }

            /*
             * 4. Consultar los documentos:
             *
             * - El documento fue recibido.
             * - Todavía no está aprobado.
             * - Pertenece a un candidato cuya aprobación está
             *   actualmente en una cola del usuario.
             */
            List<Documentacion_Legal__c> documents = [
                SELECT Id,
                       Name,
                       DOC_Candidato__c,
                       DOC_Estado__c,
                       DOC_Sub_Estado__c,
                       DOC_Recibido__c,
                       DOC_Fecha_Recepcion__c,
                       DOC_Fecha_Vencimiento__c,
                       DOC_Descripcion__c,
                       DOC_Codigo_Documento__c,
                       DOC_Documento_PF__c,
                       DOC_Documento_PJ__c,
                       DOC_Documento_PF__r.Name,
                       DOC_Documento_PF__r.ADR_Nombre_de_documento__c,
                       DOC_Documento_PJ__r.Name,
                       DOC_Documento_PJ__r.ADR_Nombre_de_documento__c,
                       CreatedDate
                FROM Documentacion_Legal__c
                WHERE DOC_Candidato__c IN :candidateIds
                AND (
                    DOC_Estado__c = null
                    OR DOC_Estado__c != 'APROBADO'
                )
                ORDER BY DOC_Fecha_Recepcion__c ASC NULLS LAST,
                         CreatedDate ASC
                LIMIT 2000
            ];

            System.debug(
                LoggingLevel.DEBUG,
                'Documentos pendientes encontrados: ' + documents.size()
            );

            List<LegalDocumentRow> rows =
                new List<LegalDocumentRow>();

            for (Documentacion_Legal__c document : documents) {

                Lead candidate =
                    candidatesById.get(document.DOC_Candidato__c);

                if (candidate == null) {
                    continue;
                }

                LegalDocumentRow row = new LegalDocumentRow();

                row.documentId = document.Id;
                row.candidateId = candidate.Id;
                row.documentName = getDocumentName(document);
                row.status = String.isBlank(document.DOC_Estado__c)
                    ? 'PENDIENTE'
                    : document.DOC_Estado__c;
                row.candidateName = candidate.Name;
                row.receivedDate = document.DOC_Fecha_Recepcion__c;
                row.expirationDate = document.DOC_Fecha_Vencimiento__c;
                row.description = document.DOC_Descripcion__c;
                row.queueName =
                    queueNameByCandidateId.get(candidate.Id);
                row.approvalReceivedDate =
                    workItemDateByCandidateId.get(candidate.Id);

                rows.add(row);
            }

            System.debug(
                LoggingLevel.DEBUG,
                'Filas devueltas a la grilla: ' + rows.size()
            );

            return rows;

        } catch (Exception e) {

            System.debug(
                LoggingLevel.ERROR,
                'Error en getPendingLegalDocuments(): ' +
                e.getMessage()
            );

            System.debug(
                LoggingLevel.ERROR,
                e.getStackTraceString()
            );

            throw new AuraHandledException(
                'Ocurrió un error al consultar los documentos ' +
                'pendientes de aprobación: ' +
                e.getMessage()
            );
        }
    }

    /**
     * Obtiene las colas a las que pertenece el usuario.
     *
     * Soporta:
     * - Usuario agregado directamente a la cola.
     * - Usuario agregado a un grupo público.
     * - Grupo público agregado a una cola.
     * - Grupos anidados.
     * - Membresía por función.
     * - Membresía por función y subordinados.
     */
    @TestVisible
    private static Set<Id> getUserQueueIds(Id userId) {

        Set<Id> queueIds = new Set<Id>();

        if (userId == null) {
            return queueIds;
        }

        User currentUser = [
            SELECT Id,
                   UserRoleId
            FROM User
            WHERE Id = :userId
            LIMIT 1
        ];

        /*
         * Identidades que pueden estar incluidas en GroupMember:
         *
         * - El propio usuario.
         * - Grupo correspondiente a su función.
         * - Grupos RoleAndSubordinates de su función
         *   y de funciones superiores.
         */
        Set<Id> startingPrincipalIds = new Set<Id>{ userId };

        if (currentUser.UserRoleId != null) {

            Set<Id> roleIds = getRoleAndAncestorIds(
                currentUser.UserRoleId
            );

            for (Group roleGroup : [
                SELECT Id,
                       Type,
                       RelatedId
                FROM Group
                WHERE RelatedId IN :roleIds
                AND Type IN (
                    'Role',
                    'RoleAndSubordinates'
                )
            ]) {

                if (
                    roleGroup.Type == 'Role' &&
                    roleGroup.RelatedId != currentUser.UserRoleId
                ) {
                    continue;
                }

                startingPrincipalIds.add(roleGroup.Id);
            }
        }

        /*
         * Resolver grupos anidados.
         */
        Set<Id> allDiscoveredGroupIds = new Set<Id>();
        Set<Id> frontier = new Set<Id>();
        frontier.addAll(startingPrincipalIds);

        Integer iteration = 0;
        Integer maximumIterations = 20;

        while (
            !frontier.isEmpty() &&
            iteration < maximumIterations
        ) {

            iteration++;

            List<GroupMember> memberships = [
                SELECT GroupId,
                       UserOrGroupId
                FROM GroupMember
                WHERE UserOrGroupId IN :frontier
            ];

            Set<Id> nextFrontier = new Set<Id>();

            for (GroupMember membership : memberships) {

                if (
                    membership.GroupId == null ||
                    allDiscoveredGroupIds.contains(
                        membership.GroupId
                    )
                ) {
                    continue;
                }

                allDiscoveredGroupIds.add(
                    membership.GroupId
                );

                nextFrontier.add(
                    membership.GroupId
                );
            }

            frontier = nextFrontier;
        }

        if (allDiscoveredGroupIds.isEmpty()) {
            return queueIds;
        }

        /*
         * De todos los grupos encontrados, conservar únicamente
         * los grupos de tipo Queue.
         */
        for (Group queueGroup : [
            SELECT Id,
                   Name,
                   DeveloperName,
                   Type
            FROM Group
            WHERE Id IN :allDiscoveredGroupIds
            AND Type = 'Queue'
        ]) {
            queueIds.add(queueGroup.Id);
        }

        return queueIds;
    }

    /**
     * Obtiene la función actual del usuario y todas las funciones
     * superiores en la jerarquía.
     */
    @TestVisible
    private static Set<Id> getRoleAndAncestorIds(Id userRoleId) {

        Set<Id> roleIds = new Set<Id>();

        if (userRoleId == null) {
            return roleIds;
        }

        Id currentRoleId = userRoleId;
        Integer iteration = 0;
        Integer maximumIterations = 20;

        while (
            currentRoleId != null &&
            iteration < maximumIterations &&
            !roleIds.contains(currentRoleId)
        ) {

            iteration++;

            UserRole currentRole = [
                SELECT Id,
                       ParentRoleId
                FROM UserRole
                WHERE Id = :currentRoleId
                LIMIT 1
            ];

            roleIds.add(currentRole.Id);
            currentRoleId = currentRole.ParentRoleId;
        }

        return roleIds;
    }

    /**
     * Obtiene el nombre visible del documento.
     */
    @TestVisible
    private static String getDocumentName(
        Documentacion_Legal__c document
    ) {

        if (document == null) {
            return 'Documento Legal';
        }

        String documentName;

        if (document.DOC_Documento_PF__r != null) {

            documentName =
                !String.isBlank(
                    document
                        .DOC_Documento_PF__r
                        .ADR_Nombre_de_documento__c
                )
                ? document
                    .DOC_Documento_PF__r
                    .ADR_Nombre_de_documento__c
                : document.DOC_Documento_PF__r.Name;
        }

        if (
            String.isBlank(documentName) &&
            document.DOC_Documento_PJ__r != null
        ) {

            documentName =
                !String.isBlank(
                    document
                        .DOC_Documento_PJ__r
                        .ADR_Nombre_de_documento__c
                )
                ? document
                    .DOC_Documento_PJ__r
                    .ADR_Nombre_de_documento__c
                : document.DOC_Documento_PJ__r.Name;
        }

        if (
            String.isBlank(documentName) &&
            !String.isBlank(document.DOC_Codigo_Documento__c)
        ) {
            documentName =
                'Documento ' +
                document.DOC_Codigo_Documento__c;
        }

        if (
            String.isBlank(documentName) &&
            !String.isBlank(document.Name)
        ) {
            documentName = document.Name;
        }

        return String.isBlank(documentName)
            ? 'Documento Legal'
            : documentName;
    }
}