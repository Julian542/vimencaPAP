Set<Id> staleJobs = new Set<Id>{
    '707VC00001xK40NYAS',
    '707VC00001xJRiRYAW',
    '707VC00001xIxeHYAS',
    '707VC00001xGlHOYA0'
};

List<ApexTestQueueItem> items = [
    SELECT Id, Status
    FROM ApexTestQueueItem
    WHERE ParentJobId IN :staleJobs
    AND Status IN ('Queued', 'Processing')
];

for (ApexTestQueueItem item : items) {
    item.Status = 'Aborted';
}

if (!items.isEmpty()) {
    update items;
}

System.debug('Aborted stale test queue items: ' + items.size());
