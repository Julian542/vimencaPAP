/** 
 * Nombre: TCP_RoundRobinOpportunityAssign
 * Autor: Lisbeth Colomo
 * Descripción: Asignación por carga (round-robin) para OpportunityTCP__c desde Flow.
 *
 * IMPORTANTE:
 *  - NO realiza UPDATE sobre OpportunityTCP__c.
 *  - Solo determina el usuario a asignar (por menor carga) y lo devuelve en la respuesta.
 *  - Mantiene el envío de notificaciones (Custom Notification).
 *  - EL ENVÍO DE CORREO YA NO SE HACE AQUÍ.
 *
 * Entradas desde Flow (por cada request):
 *  1) opportunityId : Id de OpportunityTCP__c
 *  2) queueId       : Id de la cola (GroupId - Queue)
 *  3) scenery       : indicador (String) que define el campo destino
 *
 * Mapeo scenery -> campo destino:
 *  - ANALISIS_CREDITO      -> OTCP_AssignedAnalyst__c
 *  - PENDIENTE_ENLACE      -> OTCP_LinkUser__c
 *  - PENDIENTE_ACTIVACION  -> OTCP_ActivationUser__c
 *  - PLASTICO_ENLAZADO     -> OTCP_ActivationUser__c
 *  - PERSONA_PEP           -> OTCP_PLAUser__c
 *  - PERSONA_LISTA         -> OTCP_PLAUser__c
 *
 * Notas:
 *  - No depende de Sub-Estado ni de OTCP_LinkedPlastic__c en la oportunidad.
 *  - Elige el usuario con menor cantidad de oportunidades asignadas en el campo destino.
 *
 * @last modified on  : 19-01-2026
**/
public with sharing class TCP_RoundRobinOpportunityAssign {

    // Wrappers para Flow
    public class Request {
        @InvocableVariable(required=true) public Id opportunityId; // OpportunityTCP__c
        @InvocableVariable(required=true) public Id queueId;       // GroupId (Queue)
        @InvocableVariable(required=true) public String scenery;   // indicador
    }

    public class Response {
        @InvocableVariable public Id opportunityId;
        @InvocableVariable public Id assignedUserId;
        @InvocableVariable public String assignedUserName;
        @InvocableVariable public String assignedField;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }

    // Constantes (escenarios)
    private static final String SC_ANALISIS      = 'ANALISIS_CREDITO';
    private static final String SC_ENLACE        = 'PENDIENTE_ENLACE';
    private static final String SC_ACTIVACION    = 'PENDIENTE_ACTIVACION';
    private static final String SC_PEP           = 'PERSONA_PEP';
    private static final String SC_LISTA         = 'PERSONA_LISTA';

    // Campos destino
    private static final String FIELD_ANALYST    = 'OTCP_AssignedAnalyst__c';
    private static final String FIELD_LINK_USER  = 'OTCP_LinkUser__c';
    private static final String FIELD_ACTIVATION = 'OTCP_ActivationUser__c';
    private static final String FIELD_PLA_USER   = 'OTCP_PLAUser__c';

    // Whitelist para SOQL dinámico
    private static final Set<String> ALLOWED_TARGET_FIELDS = new Set<String>{
        FIELD_ANALYST, FIELD_LINK_USER, FIELD_ACTIVATION, FIELD_PLA_USER
    };

    // Invocable
    @InvocableMethod(
        label='Asignar usuario (Round-Robin TCP por carga)'
        description='Determina usuario desde la cola indicada (sin DML) y devuelve el usuario a asignar según scenery.'
    )
    public static List<Response> assignFromFlow(List<Request> requests) {
        System.debug('TCP_RoundRobinOpportunityAssign.assignFromFlow() requests=' + requests);

        List<Response> results = new List<Response>();
        if (requests == null || requests.isEmpty()) return results;

        // Map OppId -> Request (1 request por oportunidad en la ejecución)
        Map<Id, Request> reqByOppId = new Map<Id, Request>();
        Set<Id> oppIds = new Set<Id>();

        for (Request r : requests) {
            if (r == null || r.opportunityId == null || r.queueId == null || String.isBlank(r.scenery)) {
                Response rr = new Response();
                rr.success = false;
                rr.message = 'Request inválido: opportunityId/queueId/scenery es requerido.';
                results.add(rr);
                continue;
            }
            oppIds.add(r.opportunityId);
            reqByOppId.put(r.opportunityId, r);
        }

        if (oppIds.isEmpty()) return results;

        // Query Opportunities (solo lo necesario)
        System.debug('QUERY OpportunityTCP__c WHERE Id IN :oppIds');
        List<OpportunityTCP__c> opps = [
            SELECT Id, Name,
                   OTCP_AssignedAnalyst__c,
                   OTCP_LinkUser__c,
                   OTCP_ActivationUser__c,
                   OTCP_PLAUser__c
            FROM OpportunityTCP__c
            WHERE Id IN :oppIds
        ];

        if (opps.isEmpty()) {
            for (Id oid : oppIds) {
                Response rr = new Response();
                rr.opportunityId = oid;
                rr.success = false;
                rr.message = 'No se encontró OpportunityTCP__c con ese Id.';
                results.add(rr);
            }
            return results;
        }

        // Cache de usuarios por cola y cache de cargas por (campo+cola)
        Map<Id, List<User>> queueUsersCache = new Map<Id, List<User>>();
        Map<String, Map<Id, Integer>> loadCache = new Map<String, Map<Id, Integer>>();

        // NotificationType
        CustomNotificationType notificationType = getNotificationTypeSafe('TCP_Notificacion');

        // Para resolver nombres de users ya asignados
        Set<Id> existingAssignedUserIds = new Set<Id>();

        for (OpportunityTCP__c opp : opps) {
            System.debug('Procesando OpportunityTCP__c Id=' + opp.Id + ' Name=' + opp.Name);

            Response res = new Response();
            res.opportunityId = opp.Id;

            Request req = reqByOppId.get(opp.Id);
            if (req == null) {
                res.success = false;
                res.message = 'No existe Request asociado a la oportunidad en esta ejecución.';
                results.add(res);
                continue;
            }

            String targetField = determineTargetFieldFromScenery(req.scenery);
            res.assignedField = targetField;

            if (String.isBlank(targetField)) {
                res.success = false;
                res.message = 'Scenery no reconocido: ' + req.scenery;
                results.add(res);
                continue;
            }

            // Si ya está asignado en el campo destino, solo devolver el usuario ya asignado (sin notificaciones/correo)
            Id currentAssigned = (Id) opp.get(targetField);
            if (currentAssigned != null) {
                existingAssignedUserIds.add(currentAssigned);
                res.success = true;
                res.assignedUserId = currentAssigned;
                res.message = 'Ya existe asignación en ' + targetField + '. No se modifica.';
                results.add(res);
                continue;
            }

            // Obtener usuarios de la cola (cacheado)
            List<User> usersList;
            if (queueUsersCache.containsKey(req.queueId)) {
                usersList = queueUsersCache.get(req.queueId);
            } else {
                usersList = getActiveUsersFromQueue(req.queueId);
                queueUsersCache.put(req.queueId, usersList);
            }

            if (usersList == null || usersList.isEmpty()) {
                res.success = false;
                res.message = 'La cola indicada (' + String.valueOf(req.queueId) + ') no tiene usuarios activos.';
                results.add(res);
                continue;
            }

            Map<Id, User> userById = new Map<Id, User>(usersList);
            Set<Id> userIds = userById.keySet();

            // Carga por campo destino (campo+cola)
            String loadKey = targetField + ':' + String.valueOf(req.queueId);
            Map<Id, Integer> userLoad;

            if (loadCache.containsKey(loadKey)) {
                userLoad = loadCache.get(loadKey);
            } else {
                userLoad = getUserLoadByTargetField(targetField, userIds);
                // asegurar 0 para todos
                for (Id uid : userIds) if (!userLoad.containsKey(uid)) userLoad.put(uid, 0);
                loadCache.put(loadKey, userLoad);
            }

            // Elegir usuario con menor carga (tie-break por Id)
            Id selectedUserId = null;
            Integer minLoad = null;

            for (Id uid : userIds) {
                Integer load = userLoad.get(uid);
                if (load == null) load = 0;

                if (selectedUserId == null ||
                    load < minLoad ||
                    (load == minLoad && String.valueOf(uid) < String.valueOf(selectedUserId))) {
                    selectedUserId = uid;
                    minLoad = load;
                }
            }

            if (selectedUserId == null) {
                res.success = false;
                res.message = 'No se pudo determinar usuario para asignar.';
                results.add(res);
                continue;
            }

            User sel = userById.get(selectedUserId);

            // SOLO DEVOLVER asignación (sin DML)
            res.success = true;
            res.assignedUserId = selectedUserId;
            res.assignedUserName = (sel != null) ? sel.Name : null;
            res.message = 'Usuario asignado correctamente por menor carga en ' + targetField + '.';
            results.add(res);

            // Notificación (opcional)
            if (notificationType != null && sel != null) {
                generateNotification(sel, opp, notificationType, targetField);
            }
        }

        // Resolver nombres de usuario para casos ya asignados (solo para llenar assignedUserName)
        if (!existingAssignedUserIds.isEmpty()) {
            try {
                System.debug('QUERY User (existing assigned) WHERE Id IN :existingAssignedUserIds');
                Map<Id, User> existingUsers = new Map<Id, User>([
                    SELECT Id, Name
                    FROM User
                    WHERE Id IN :existingAssignedUserIds
                ]);

                for (Response r : results) {
                    if (r != null && r.assignedUserId != null && String.isBlank(r.assignedUserName)) {
                        User u = existingUsers.get(r.assignedUserId);
                        if (u != null) r.assignedUserName = u.Name;
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'No se pudo resolver nombre de usuarios ya asignados: ' + e.getMessage());
            }
        }

        return results;
    }

    // Scenery -> campo destino
    private static String determineTargetFieldFromScenery(String scenery) {
        System.debug('TCP_RoundRobinOpportunityAssign.determineTargetFieldFromScenery() scenery=' + scenery);

        if (String.isBlank(scenery)) return null;
        String sc = scenery.trim().toUpperCase();

        if (sc == SC_ANALISIS)   return FIELD_ANALYST;
        if (sc == SC_ENLACE)     return FIELD_LINK_USER;
        if (sc == SC_ACTIVACION) return FIELD_ACTIVATION;
        if (sc == SC_PEP)        return FIELD_PLA_USER;
        if (sc == SC_LISTA)      return FIELD_PLA_USER;

        return null;
    }

    // Usuarios activos de cola (expande grupos anidados)
    public static List<User> getActiveUsersFromQueue(Id queueId) {
        System.debug('TCP_RoundRobinOpportunityAssign.getActiveUsersFromQueue() queueId=' + queueId);

        List<User> result = new List<User>();
        if (queueId == null) return result;

        try {
            System.debug('QUERY Group WHERE Id=:queueId');
            Group g = [
                SELECT Id, Name, Type
                FROM Group
                WHERE Id = :queueId
                LIMIT 1
            ];

            if (g == null || g.Type != 'Queue') {
                System.debug(LoggingLevel.WARN, 'El GroupId no es de tipo Queue. Type=' + (g != null ? g.Type : null));
                return result;
            }

            Set<Id> visitedGroups = new Set<Id>();
            Set<Id> pendingGroups = new Set<Id>();
            Set<Id> userIds = new Set<Id>();

            pendingGroups.add(queueId);

            while (!pendingGroups.isEmpty()) {
                Id currentGroupId = pendingGroups.iterator().next();
                pendingGroups.remove(currentGroupId);

                if (visitedGroups.contains(currentGroupId)) continue;
                visitedGroups.add(currentGroupId);

                System.debug('QUERY GroupMember WHERE GroupId=' + currentGroupId);
                List<GroupMember> members = [
                    SELECT UserOrGroupId
                    FROM GroupMember
                    WHERE GroupId = :currentGroupId
                ];

                for (GroupMember gm : members) {
                    if (gm.UserOrGroupId == null) continue;

                    String idStr = String.valueOf(gm.UserOrGroupId);

                    // User
                    if (idStr.startsWith('005')) {
                        userIds.add(gm.UserOrGroupId);
                    }
                    // Group
                    else if (idStr.startsWith('00G')) {
                        pendingGroups.add(gm.UserOrGroupId);
                    }
                }
            }

            if (!userIds.isEmpty()) {
                System.debug('QUERY User WHERE Id IN :userIds AND IsActive=true');
                result = [
                    SELECT Id, Name, Email
                    FROM User
                    WHERE Id IN :userIds
                      AND IsActive = true
                    ORDER BY Name ASC
                ];
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'getActiveUsersFromQueue Error: ' + e.getMessage());
        }

        return result;
    }

    // Carga por campo destino
    private static Map<Id, Integer> getUserLoadByTargetField(String targetField, Set<Id> userIds) {
        System.debug('TCP_RoundRobinOpportunityAssign.getUserLoadByTargetField() targetField=' + targetField + ' userIds=' + userIds);

        Map<Id, Integer> userLoad = new Map<Id, Integer>();
        if (String.isBlank(targetField) || userIds == null || userIds.isEmpty()) return userLoad;

        // Whitelist para evitar inyección
        if (!ALLOWED_TARGET_FIELDS.contains(targetField)) return userLoad;

        try {
            String soql =
                'SELECT ' + targetField + ' userId, COUNT(Id) total ' +
                'FROM OpportunityTCP__c ' +
                'WHERE ' + targetField + ' IN :userIds ' +
                'GROUP BY ' + targetField;

            System.debug('DYNAMIC SOQL (load): ' + soql);

            for (AggregateResult ar : (List<AggregateResult>) Database.query(soql)) {
                Id uid = (Id) ar.get('userId');
                Integer total = (Integer) ar.get('total');
                if (uid != null) userLoad.put(uid, total);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'getUserLoadByTargetField Error: ' + e.getMessage());
        }

        return userLoad;
    }

    // Notificaciones (opcional)
    private static CustomNotificationType getNotificationTypeSafe(String developerName) {
        System.debug('TCP_RoundRobinOpportunityAssign.getNotificationTypeSafe() developerName=' + developerName);

        if (String.isBlank(developerName)) return null;

        try {
            System.debug('QUERY CustomNotificationType DeveloperName=' + developerName);
            return [
                SELECT Id, DeveloperName
                FROM CustomNotificationType
                WHERE DeveloperName = :developerName
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,
                'No se encontró CustomNotificationType "' + developerName + '". Se continúa sin notificaciones. Detalle: ' + e.getMessage());
            return null;
        }
    }

    public static void generateNotification(
        User assignedUser,
        OpportunityTCP__c opp,
        CustomNotificationType notificationType,
        String targetField
    ) {
        System.debug('TCP_RoundRobinOpportunityAssign.generateNotification() user='
            + (assignedUser != null ? assignedUser.Id : null)
            + ' opp=' + (opp != null ? opp.Id : null)
            + ' targetField=' + targetField);

        if (assignedUser == null || opp == null || notificationType == null) return;

        String title = 'Asignación Oportunidad TCP';
        String body  = 'Estimado(a) ' + assignedUser.Name + ', se le ha asignado la ' + opp.Name + '.';

        try {
            Messaging.CustomNotification n = new Messaging.CustomNotification();
            n.setTitle(title);
            n.setBody(body);
            n.setNotificationTypeId(notificationType.Id);
            n.setTargetId(opp.Id);

            n.send(new Set<String>{ assignedUser.Id });
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'generateNotification Error: ' + e.getMessage());
        }
    }
}