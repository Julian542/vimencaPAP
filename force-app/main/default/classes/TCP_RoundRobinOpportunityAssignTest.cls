@IsTest
private class TCP_RoundRobinOpportunityAssignTest {
    @TestSetup
    static void createsCoverageQueue() {
        Group queue = new Group(
            Name = 'TCP round robin coverage queue',
            DeveloperName = 'TcpRoundRobinCoverage',
            Type = 'Queue'
        );
        insert queue;
        insert new GroupMember(GroupId = queue.Id, UserOrGroupId = UserInfo.getUserId());
    }

    @IsTest
    static void handlesEmptyAndInvalidRequests() {
        Test.startTest();
        List<TCP_RoundRobinOpportunityAssign.Response> emptyResult =
            TCP_RoundRobinOpportunityAssign.assignFromFlow(null);
        List<TCP_RoundRobinOpportunityAssign.Response> invalidResult =
            TCP_RoundRobinOpportunityAssign.assignFromFlow(
                new List<TCP_RoundRobinOpportunityAssign.Request>{
                    null,
                    new TCP_RoundRobinOpportunityAssign.Request(),
                    buildRequest(null, UserInfo.getUserId(), 'ANALISIS_CREDITO'),
                    buildRequest(null, null, 'ANALISIS_CREDITO'),
                    buildRequest(null, UserInfo.getUserId(), null)
                }
            );
        List<User> noQueueUsers = TCP_RoundRobinOpportunityAssign.getActiveUsersFromQueue(null);
        Test.stopTest();

        System.assertEquals(0, emptyResult.size());
        System.assertEquals(5, invalidResult.size());
        for (TCP_RoundRobinOpportunityAssign.Response response : invalidResult) {
            System.assertEquals(false, response.success);
            System.assert(response.message.contains('Request inválido'));
        }
        System.assertEquals(0, noQueueUsers.size());
    }

    @IsTest
    static void handlesUnknownOpportunityAndScenery() {
        String keyPrefix = OpportunityTCP__c.SObjectType.getDescribe().getKeyPrefix();
        Id missingOpportunityId = Id.valueOf(keyPrefix + '000000000001');

        TCP_RoundRobinOpportunityAssign.Request missingRequest =
            buildRequest(missingOpportunityId, UserInfo.getUserId(), 'ANALISIS_CREDITO');
        TCP_RoundRobinOpportunityAssign.Request unknownSceneryRequest =
            buildRequest(missingOpportunityId, UserInfo.getUserId(), 'ESCENARIO_INEXISTENTE');

        Test.startTest();
        List<TCP_RoundRobinOpportunityAssign.Response> responses =
            TCP_RoundRobinOpportunityAssign.assignFromFlow(
                new List<TCP_RoundRobinOpportunityAssign.Request>{
                    missingRequest,
                    unknownSceneryRequest
                }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(false, responses[0].success);
        System.assertEquals('No se encontró OpportunityTCP__c con ese Id.', responses[0].message);
    }

    @IsTest
    static void returnsExistingAssignmentWithoutReassigning() {
        OpportunityTCP__c opportunity = new OpportunityTCP__c(
            Name = 'OTCP existing assignment',
            OTCP_AssignedAnalyst__c = UserInfo.getUserId()
        );
        insert opportunity;

        TCP_RoundRobinOpportunityAssign.Request request =
            buildRequest(opportunity.Id, UserInfo.getUserId(), 'ANALISIS_CREDITO');

        Test.startTest();
        List<TCP_RoundRobinOpportunityAssign.Response> responses =
            TCP_RoundRobinOpportunityAssign.assignFromFlow(
                new List<TCP_RoundRobinOpportunityAssign.Request>{ request }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].success);
        System.assertEquals(UserInfo.getUserId(), responses[0].assignedUserId);
        System.assertEquals('OTCP_AssignedAnalyst__c', responses[0].assignedField);
    }

    @IsTest
    static void selectsTheLeastLoadedActiveQueueMember() {
        Group queue = [
            SELECT Id
            FROM Group
            WHERE DeveloperName = 'TcpRoundRobinCoverage'
            LIMIT 1
        ];

        OpportunityTCP__c opportunity = new OpportunityTCP__c(Name = 'OTCP round robin coverage');
        insert opportunity;

        Test.startTest();
        List<TCP_RoundRobinOpportunityAssign.Response> responses =
            TCP_RoundRobinOpportunityAssign.assignFromFlow(
                new List<TCP_RoundRobinOpportunityAssign.Request>{
                    buildRequest(opportunity.Id, queue.Id, 'PERSONA_PEP')
                }
            );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].success, responses[0].message);
        System.assertEquals(UserInfo.getUserId(), responses[0].assignedUserId);
        System.assertEquals('OTCP_PLAUser__c', responses[0].assignedField);
    }

    private static TCP_RoundRobinOpportunityAssign.Request buildRequest(
        Id opportunityId,
        Id queueId,
        String scenery
    ) {
        TCP_RoundRobinOpportunityAssign.Request request =
            new TCP_RoundRobinOpportunityAssign.Request();
        request.opportunityId = opportunityId;
        request.queueId = queueId;
        request.scenery = scenery;
        return request;
    }
}
