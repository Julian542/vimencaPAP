@IsTest
private class QueueResolverCoverageTest {
    @IsTest
    static void handlesEmptyAndUnknownQueueNames() {
        QueueResolver.clearCache();

        System.assertEquals(null, QueueResolver.getQueueIdByDeveloperName(null));
        System.assertEquals(null, QueueResolver.getQueueIdByDeveloperName(''));
        System.assertEquals(
            1,
            QueueResolver.getQueueIdsByDeveloperNames(new Set<String>{ null, '', 'QUEUE_DOES_NOT_EXIST' }).size()
        );
    }

    @IsTest
    static void resolvesExistingQueueAndUsesCache() {
        Group queue = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            LIMIT 1
        ];

        QueueResolver.clearCache();
        Test.startTest();
        Id firstResult = QueueResolver.getQueueIdByDeveloperName(queue.DeveloperName);
        Id cachedResult = QueueResolver.getQueueIdByDeveloperName(queue.DeveloperName.toLowerCase());
        Map<String, Id> bulkResult = QueueResolver.getQueueIdsByDeveloperNames(
            new Set<String>{ queue.DeveloperName, 'QUEUE_DOES_NOT_EXIST' }
        );
        Test.stopTest();

        System.assertEquals(queue.Id, firstResult);
        System.assertEquals(queue.Id, cachedResult);
        System.assertEquals(queue.Id, bulkResult.get(queue.DeveloperName.toUpperCase()));
    }
}
