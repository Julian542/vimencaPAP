/**
 * @description       : Asigna aleatoriamente casos a usuarios activos pertenecientes
 *                      a la cola que ya fue determinada previamente en el trigger/handler.
 *                      Mantiene OwnerId como cola y guarda el usuario seleccionado
 *                      en el campo Asignado_a__c.
 * @author            : Jhonny Peroza
 * @last modified on  : 04-06-2026
 * @last modified by  : Jhonny Peroza
 **/
public with sharing class CaseRoundRobin {

    public static void assignRandomOwnerFromQueue(List<Case> newCases) {
        System.debug(LoggingLevel.DEBUG,
            'CaseRoundRobin.assignRandomOwnerFromQueue() newCases.size()=' +
            (newCases != null ? newCases.size() : 0)
        );

        try {
            if (newCases == null || newCases.isEmpty()) {
                return;
            }

            Set<Id> queueIds = new Set<Id>();

            for (Case c : newCases) {
                if (c.OwnerId != null && c.OwnerId.getSObjectType() == Group.SObjectType) {
                    queueIds.add(c.OwnerId);
                }
            }

            System.debug(LoggingLevel.DEBUG,
                'CaseRoundRobin.assignRandomOwnerFromQueue() queueIds=' + queueIds
            );

            if (queueIds.isEmpty()) {
                return;
            }

            Map<Id, List<User>> usersByQueue = getActiveUsersByQueue(queueIds);

            System.debug(LoggingLevel.DEBUG,
                'CaseRoundRobin.assignRandomOwnerFromQueue() usersByQueue=' + usersByQueue
            );

            for (Case c : newCases) {
                if (c.OwnerId == null || c.OwnerId.getSObjectType() != Group.SObjectType) {
                    continue;
                }

                List<User> queueUsers = usersByQueue.get(c.OwnerId);

                if (queueUsers == null || queueUsers.isEmpty()) {
                    System.debug(LoggingLevel.DEBUG,
                        'CaseRoundRobin.assignRandomOwnerFromQueue() cola sin usuarios activos. CaseId=' + c.Id +
                        ', QueueId=' + c.OwnerId
                    );
                    continue;
                }

                Integer randomValue = Crypto.getRandomInteger();

                if (randomValue < 0) {
                    randomValue = randomValue * -1;
                }

                if (randomValue < 0) {
                    randomValue = 0;
                }

                Integer indexSelected = Math.mod(randomValue, queueUsers.size());
                User selectedUser = queueUsers[indexSelected];

                System.debug(LoggingLevel.DEBUG,
                    'CaseRoundRobin.assignRandomOwnerFromQueue() CaseId=' + c.Id +
                    ', QueueId=' + c.OwnerId +
                    ', queueUsers.size()=' + queueUsers.size() +
                    ', indexSelected=' + indexSelected +
                    ', selectedUserId=' + selectedUser.Id
                );

                /*
                 * Se mantiene OwnerId como cola resolutora.
                 * El usuario elegido por Round Robin se guarda en el campo Asignado a.
                 */
                c.Asignado_a__c = selectedUser.Id;
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en CaseRoundRobin.assignRandomOwnerFromQueue(): ' + e.getMessage()
            );
        }
    }

    private static Map<Id, List<User>> getActiveUsersByQueue(Set<Id> queueIds) {
        System.debug(LoggingLevel.DEBUG,
            'CaseRoundRobin.getActiveUsersByQueue() queueIds=' + queueIds
        );

        Map<Id, List<User>> result = new Map<Id, List<User>>();

        try {
            if (queueIds == null || queueIds.isEmpty()) {
                return result;
            }

            System.debug(LoggingLevel.DEBUG,
                'Query GroupMember inicial en CaseRoundRobin.getActiveUsersByQueue(). queueIds=' + queueIds
            );

            List<GroupMember> initialMembers = [
                SELECT GroupId, UserOrGroupId
                FROM GroupMember
                WHERE GroupId IN :queueIds
            ];

            Set<Id> allUserIds = new Set<Id>();
            Map<Id, Set<Id>> userIdsByQueue = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> queuesByNestedGroup = new Map<Id, Set<Id>>();
            Set<Id> pendingGroupIds = new Set<Id>();

            for (Id queueId : queueIds) {
                userIdsByQueue.put(queueId, new Set<Id>());
            }

            for (GroupMember gm : initialMembers) {
                if (gm.UserOrGroupId == null) {
                    continue;
                }

                if (gm.UserOrGroupId.getSObjectType() == User.SObjectType) {
                    allUserIds.add(gm.UserOrGroupId);

                    if (!userIdsByQueue.containsKey(gm.GroupId)) {
                        userIdsByQueue.put(gm.GroupId, new Set<Id>());
                    }

                    userIdsByQueue.get(gm.GroupId).add(gm.UserOrGroupId);
                }

                if (gm.UserOrGroupId.getSObjectType() == Group.SObjectType) {
                    pendingGroupIds.add(gm.UserOrGroupId);

                    if (!queuesByNestedGroup.containsKey(gm.UserOrGroupId)) {
                        queuesByNestedGroup.put(gm.UserOrGroupId, new Set<Id>());
                    }

                    queuesByNestedGroup.get(gm.UserOrGroupId).add(gm.GroupId);
                }
            }

            /*
             * Soporte para grupos anidados dentro de la cola.
             * Ejemplo:
             * Cola -> Grupo Público -> Usuario
             * Cola -> Grupo Público -> Grupo Público -> Usuario
             */
            Set<Id> processedGroupIds = new Set<Id>();

            while (!pendingGroupIds.isEmpty()) {
                Set<Id> groupsToQuery = new Set<Id>();

                for (Id groupId : pendingGroupIds) {
                    if (!processedGroupIds.contains(groupId)) {
                        groupsToQuery.add(groupId);
                    }
                }

                pendingGroupIds.clear();

                if (groupsToQuery.isEmpty()) {
                    break;
                }

                processedGroupIds.addAll(groupsToQuery);

                System.debug(LoggingLevel.DEBUG,
                    'Query GroupMember anidado en CaseRoundRobin.getActiveUsersByQueue(). groupsToQuery=' + groupsToQuery
                );

                List<GroupMember> nestedMembers = [
                    SELECT GroupId, UserOrGroupId
                    FROM GroupMember
                    WHERE GroupId IN :groupsToQuery
                ];

                for (GroupMember gm : nestedMembers) {
                    if (gm.UserOrGroupId == null) {
                        continue;
                    }

                    Set<Id> relatedQueueIds = queuesByNestedGroup.get(gm.GroupId);

                    if (relatedQueueIds == null || relatedQueueIds.isEmpty()) {
                        continue;
                    }

                    if (gm.UserOrGroupId.getSObjectType() == User.SObjectType) {
                        allUserIds.add(gm.UserOrGroupId);

                        for (Id queueId : relatedQueueIds) {
                            if (!userIdsByQueue.containsKey(queueId)) {
                                userIdsByQueue.put(queueId, new Set<Id>());
                            }

                            userIdsByQueue.get(queueId).add(gm.UserOrGroupId);
                        }
                    }

                    if (gm.UserOrGroupId.getSObjectType() == Group.SObjectType) {
                        if (!processedGroupIds.contains(gm.UserOrGroupId)) {
                            pendingGroupIds.add(gm.UserOrGroupId);
                        }

                        if (!queuesByNestedGroup.containsKey(gm.UserOrGroupId)) {
                            queuesByNestedGroup.put(gm.UserOrGroupId, new Set<Id>());
                        }

                        queuesByNestedGroup.get(gm.UserOrGroupId).addAll(relatedQueueIds);
                    }
                }
            }

            if (allUserIds.isEmpty()) {
                System.debug(LoggingLevel.DEBUG,
                    'CaseRoundRobin.getActiveUsersByQueue() no se encontraron usuarios en la cola ni en grupos anidados.'
                );
                return result;
            }

            System.debug(LoggingLevel.DEBUG,
                'Query User en CaseRoundRobin.getActiveUsersByQueue(). allUserIds=' + allUserIds
            );

            Map<Id, User> activeUsersMap = new Map<Id, User>([
                SELECT Id, Name, IsActive
                FROM User
                WHERE Id IN :allUserIds
                AND IsActive = true
            ]);

            for (Id queueId : userIdsByQueue.keySet()) {
                List<User> queueUsers = new List<User>();

                for (Id userId : userIdsByQueue.get(queueId)) {
                    if (activeUsersMap.containsKey(userId)) {
                        queueUsers.add(activeUsersMap.get(userId));
                    }
                }

                if (!queueUsers.isEmpty()) {
                    result.put(queueId, queueUsers);
                }
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Error en CaseRoundRobin.getActiveUsersByQueue(): ' + e.getMessage()
            );
        }

        return result;
    }
}