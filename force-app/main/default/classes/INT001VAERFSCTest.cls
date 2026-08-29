@IsTest
private class INT001VAERFSCTest {
    private static Account createCandidate(String identificationType, String state) {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount').getRecordTypeId(),
            FirstName = 'Int001',
            LastName = 'Coverage ' + identificationType,
            ACC_TipoIdentificacion__c = identificationType,
            ACC_NumIdentificacion__c = '00100058007',
            ACC_Estado__c = state
        );
        insert account;
        return account;
    }

    @IsTest
    static void updatesACreatedCedulaCandidateFromTheElectoralRegister() {
        Account candidate = createCandidate('Cédula', 'CREADO');
        Test.setMock(HttpCalloutMock.class, new INT001TestMock('PF'));

        Test.startTest();
        INT001_VAER_Controller_FSC.Response response =
            INT001_VAER_Controller_FSC.updateAccount(candidate.Id);
        Test.stopTest();

        System.assertEquals('000', response.errorCode);
        System.assertEquals(200, response.httpRequestStatusCode);
    }

    @IsTest
    static void rejectsCandidatesWithANonCedulaIdentificationType() {
        Account candidate = createCandidate('Pasaporte', 'CREADO');

        Test.startTest();
        INT001_VAER_Controller_FSC.Response response =
            INT001_VAER_Controller_FSC.updateAccount(candidate.Id);
        Test.stopTest();

        System.assertEquals(false, response.updateSuccess);
        System.assert(response.updateErrorMessage.contains('CÉDULA'));
    }
}
