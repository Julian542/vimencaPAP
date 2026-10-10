@IsTest
private class CaseRequiredDocumentsValidatorTest {

    private static Case createCase() {
        Case testCase = new Case(
            Subject = 'Validación de documentos requeridos',
            Status = 'New',
            Origin = 'Phone'
        );
        insert testCase;
        return [SELECT Id, RecordTypeId, Status FROM Case WHERE Id = :testCase.Id];
    }

    private static void attachFile(Id caseId, String title) {
        insert new ContentVersion(
            Title = title,
            PathOnClient = title + '.pdf',
            VersionData = Blob.valueOf('contenido de prueba'),
            FirstPublishLocationId = caseId
        );
    }

    private static Case caseLeavingInitialStatus(Case storedCase) {
        return new Case(
            Id = storedCase.Id,
            RecordTypeId = storedCase.RecordTypeId,
            Status = 'En proceso'
        );
    }

    private static Map<Id, Case> initialStatusMap(Case storedCase) {
        return new Map<Id, Case>{
            storedCase.Id => new Case(
                Id = storedCase.Id,
                RecordTypeId = storedCase.RecordTypeId,
                Status = CaseRequiredDocumentsValidator.INITIAL_STATUS
            )
        };
    }

    private static void validate(Case currentCase, Case storedCase) {
        CaseRequiredDocumentsValidator.validateStatusAdvance(
            new List<Case>{ currentCase },
            initialStatusMap(storedCase),
            new Set<Id>(),
            new Set<Id>{ storedCase.RecordTypeId }
        );
    }

    @IsTest
    static void blocksAdvanceWhenBothDocumentsAreMissing() {
        Case storedCase = createCase();
        Case currentCase = caseLeavingInitialStatus(storedCase);

        Test.startTest();
        validate(currentCase, storedCase);
        Test.stopTest();

        System.assert(currentCase.hasErrors(), 'Debe bloquear el cambio sin documentos.');
        System.assertEquals(
            CaseRequiredDocumentsValidator.ERROR_MESSAGE,
            currentCase.getErrors()[0].getMessage()
        );
    }

    @IsTest
    static void blocksAdvanceWhenOnlyOneDocumentExists() {
        Case storedCase = createCase();
        attachFile(storedCase.Id, 'Documento cualquiera');
        Case currentCase = caseLeavingInitialStatus(storedCase);

        Test.startTest();
        validate(currentCase, storedCase);
        Test.stopTest();

        System.assert(currentCase.hasErrors(), 'Debe exigir al menos dos documentos adjuntos.');
    }

    @IsTest
    static void allowsAdvanceWhenBothDocumentsExist() {
        Case storedCase = createCase();
        attachFile(storedCase.Id, 'Archivo uno');
        attachFile(storedCase.Id, 'Archivo dos');
        Case currentCase = caseLeavingInitialStatus(storedCase);

        Test.startTest();
        validate(currentCase, storedCase);
        Test.stopTest();

        System.assert(!currentCase.hasErrors(), 'Debe permitir avanzar con ambos documentos.');
    }

    @IsTest
    static void ignoresUpdatesThatDoNotLeaveInitialStatus() {
        Case storedCase = createCase();
        Case currentCase = new Case(
            Id = storedCase.Id,
            RecordTypeId = storedCase.RecordTypeId,
            Status = CaseRequiredDocumentsValidator.INITIAL_STATUS
        );

        Test.startTest();
        validate(currentCase, storedCase);
        Test.stopTest();

        System.assert(!currentCase.hasErrors(), 'No debe validar mientras permanezca en el estado inicial.');
    }
}