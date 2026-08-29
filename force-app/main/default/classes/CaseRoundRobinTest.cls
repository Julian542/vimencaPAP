@IsTest
private class CaseRoundRobinTest {
    private static Group createCaseQueue(String suffix) {
        Group queue = new Group(
            Name = 'Case coverage queue ' + suffix,
            DeveloperName = 'Case_Coverage_Queue_' + suffix,
            Type = 'Queue'
        );
        insert queue;
        insert new QueueSobject(QueueId = queue.Id, SobjectType = 'Case');
        return queue;
    }

    @IsTest
    static void assignsDirectActiveQueueMember() {
        Group queue = createCaseQueue('Direct');
        insert new GroupMember(GroupId = queue.Id, UserOrGroupId = UserInfo.getUserId());
        Case queuedCase = new Case(OwnerId = queue.Id);

        Test.startTest();
        CaseRoundRobin.assignRandomOwnerFromQueue(null);
        CaseRoundRobin.assignRandomOwnerFromQueue(new List<Case>());
        CaseRoundRobin.assignRandomOwnerFromQueue(
            new List<Case>{ new Case(OwnerId = UserInfo.getUserId()), queuedCase }
        );
        Test.stopTest();

        System.assertEquals(UserInfo.getUserId(), queuedCase.Asignado_a__c);
        System.assertEquals(queue.Id, queuedCase.OwnerId);
    }

    @IsTest
    static void assignsMemberFromNestedPublicGroups() {
        Group queue = createCaseQueue('Nested');
        Group firstLevel = new Group(
            Name = 'Coverage first level',
            DeveloperName = 'Coverage_First_Level',
            Type = 'Regular'
        );
        Group secondLevel = new Group(
            Name = 'Coverage second level',
            DeveloperName = 'Coverage_Second_Level',
            Type = 'Regular'
        );
        insert new List<Group>{ firstLevel, secondLevel };
        insert new List<GroupMember>{
            new GroupMember(GroupId = queue.Id, UserOrGroupId = firstLevel.Id),
            new GroupMember(GroupId = firstLevel.Id, UserOrGroupId = secondLevel.Id),
            new GroupMember(GroupId = secondLevel.Id, UserOrGroupId = UserInfo.getUserId())
        };
        Case queuedCase = new Case(OwnerId = queue.Id);

        Test.startTest();
        CaseRoundRobin.assignRandomOwnerFromQueue(new List<Case>{ queuedCase });
        Test.stopTest();

        System.assertEquals(UserInfo.getUserId(), queuedCase.Asignado_a__c);
    }

    @IsTest
    static void leavesCaseUnassignedWhenQueueHasNoMembers() {
        Group queue = createCaseQueue('Empty');
        Case queuedCase = new Case(OwnerId = queue.Id);

        CaseRoundRobin.assignRandomOwnerFromQueue(new List<Case>{ queuedCase });

        System.assertEquals(null, queuedCase.Asignado_a__c);
    }
}
