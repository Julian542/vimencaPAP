@IsTest
private class VimencashSlaAssignerCoverageTest {
    @IsTest
    static void ignoresNullAndAlreadyAssignedCases() {
        VimencashSlaAssigner.applySlaIfNeeded(null);

        Case alreadyAssigned = new Case(
            EntitlementId = UserInfo.getUserId()
        );
        VimencashSlaAssigner.applySlaIfNeeded(alreadyAssigned);
        System.assertEquals(UserInfo.getUserId(), alreadyAssigned.EntitlementId);
    }

    @IsTest
    static void handlesCaseRecordTypeWithoutMatchingSla() {
        RecordType caseRecordType = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Case'
            LIMIT 1
        ];
        Case caseRecord = new Case(RecordTypeId = caseRecordType.Id);

        VimencashSlaAssigner.applySlaIfNeeded(caseRecord);
        System.assertEquals(null, caseRecord.EntitlementId);
    }
}
