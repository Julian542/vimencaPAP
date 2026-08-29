public without sharing class FSC_RandomQueueApproverAction {
    private static final Set<String> SUPPORTED_ASSIGNED_USER_FIELDS = new Set<String>{
        'FSC_UsuarioAnalista__c',
        'FSC_UsuarioComite__c',
        'FSC_UsuarioControlDocumentos__c',
        'FSC_UsuarioSupervisor__c'
    };

    public class Input {
        @InvocableVariable(required=true)
        public Id groupId;

        @InvocableVariable
        public String assignedUserFieldApiName;
    }

    public class Output {
        @InvocableVariable
        public Id userId;
    }

    @InvocableMethod(
        label='FSC - Obtener aprobador con menor carga de cola'
        description='Devuelve un usuario activo desde una cola o grupo, con menor carga si se indica un campo soportado de asignación.'
    )
    public static List<Output> run(List<Input> inputs) {
        List<Output> outputs = new List<Output>();

        if (inputs == null) {
            return outputs;
        }

        for (Input inputItem : inputs) {
            Output outputItem = new Output();
            outputItem.userId = selectApproverId(
                inputItem != null ? inputItem.groupId : null,
                inputItem != null ? inputItem.assignedUserFieldApiName : null
            );
            outputs.add(outputItem);
        }

        return outputs;
    }

    @TestVisible
    private static Id selectApproverId(Id rootGroupId, String assignedUserFieldApiName) {
        if (rootGroupId == null) {
            return null;
        }

        Set<Id> candidatePrincipalIds = collectCandidatePrincipalIds(rootGroupId);
        if (candidatePrincipalIds.isEmpty()) {
            return null;
        }

        List<User> activeUsers = [
            SELECT Id
            FROM User
            WHERE Id IN :candidatePrincipalIds
            AND IsActive = true
        ];

        if (activeUsers.isEmpty()) {
            return null;
        }

        if (!SUPPORTED_ASSIGNED_USER_FIELDS.contains(assignedUserFieldApiName)) {
            return selectRandomUserId(extractUserIds(activeUsers));
        }

        Map<Id, Integer> assignedCountsByUserId = new Map<Id, Integer>();
        for (User activeUser : activeUsers) {
            assignedCountsByUserId.put(activeUser.Id, 0);
        }

        Set<Id> assignedUserIds = assignedCountsByUserId.keySet();
        String loadQuery =
            'SELECT ' + assignedUserFieldApiName + ' assigneeId, COUNT(Id) total ' +
            'FROM ResidentialLoanApplication ' +
            'WHERE ' + assignedUserFieldApiName + ' IN :assignedUserIds ' +
            'AND Status = \'En proceso\' ' +
            'GROUP BY ' + assignedUserFieldApiName;

        for (AggregateResult result : Database.query(loadQuery)) {
            assignedCountsByUserId.put(
                (Id) result.get('assigneeId'),
                (Integer) result.get('total')
            );
        }

        Integer minimumAssignedCount;
        List<Id> leastLoadedUserIds = new List<Id>();

        for (User activeUser : activeUsers) {
            Integer assignedCount = assignedCountsByUserId.get(activeUser.Id);

            if (minimumAssignedCount == null || assignedCount < minimumAssignedCount) {
                minimumAssignedCount = assignedCount;
                leastLoadedUserIds.clear();
                leastLoadedUserIds.add(activeUser.Id);
            } else if (assignedCount == minimumAssignedCount) {
                leastLoadedUserIds.add(activeUser.Id);
            }
        }

        return selectRandomUserId(leastLoadedUserIds);
    }

    @TestVisible
    private static Set<Id> collectCandidatePrincipalIds(Id rootGroupId) {
        Set<Id> candidatePrincipalIds = new Set<Id>();
        Set<Id> visitedGroupIds = new Set<Id>{ rootGroupId };
        Set<Id> groupsToProcess = new Set<Id>{ rootGroupId };

        while (!groupsToProcess.isEmpty()) {
            Set<Id> currentBatch = new Set<Id>(groupsToProcess);
            groupsToProcess.clear();

            for (GroupMember member : [
                SELECT GroupId, UserOrGroupId
                FROM GroupMember
                WHERE GroupId IN :currentBatch
            ]) {
                String memberId = String.valueOf(member.UserOrGroupId);
                if (memberId.startsWith('00G')) {
                    if (!visitedGroupIds.contains(member.UserOrGroupId)) {
                        visitedGroupIds.add(member.UserOrGroupId);
                        groupsToProcess.add(member.UserOrGroupId);
                    }
                } else {
                    candidatePrincipalIds.add(member.UserOrGroupId);
                }
            }
        }

        return candidatePrincipalIds;
    }

    @TestVisible
    private static List<Id> extractUserIds(List<User> users) {
        List<Id> userIds = new List<Id>();
        for (User userRecord : users) {
            userIds.add(userRecord.Id);
        }
        return userIds;
    }

    @TestVisible
    private static Id selectRandomUserId(List<Id> candidateUserIds) {
        if (candidateUserIds == null || candidateUserIds.isEmpty()) {
            return null;
        }

        Long positiveRandomValue = Crypto.getRandomInteger();
        if (positiveRandomValue < 0) {
            positiveRandomValue = -positiveRandomValue;
        }

        Integer randomIndex = (Integer) Math.mod(positiveRandomValue, candidateUserIds.size());
        return candidateUserIds[randomIndex];
    }
}