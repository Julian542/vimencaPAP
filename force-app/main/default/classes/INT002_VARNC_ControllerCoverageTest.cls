@IsTest
private class INT002_VARNC_ControllerCoverageTest {
    @IsTest
    static void rejectsAccountThatIsNotIniciado() {
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'RNC coverage account',
            ACC_RNC__c = '131002COVER',
            ACC_Estado__c = 'CALIFICADO'
        );
        insert account;

        INT002_VARNC_Controller.Response response =
            INT002_VARNC_Controller.updateAccountRNC(account.Id);

        System.assertEquals(false, response.updateSuccess);
        System.assertEquals('000', response.errorCode);
        System.assert(response.updateErrorMessage.contains('INICIADO'));
    }
}
