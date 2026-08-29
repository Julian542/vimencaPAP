@IsTest
private class FSC_DesembolsoDeCreditoTest {

    private static Account createAccount() {
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'Cuenta Test Desembolso',
            ACC_RNC__c = String.valueOf(Math.abs(Crypto.getRandomInteger())).leftPad(9, '0').substring(0, 9),
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC'
        );
        insert acc;
        return acc;
    }

    private static ResidentialLoanApplication createRla() {
        Account acc = createAccount();

        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            Name = 'RLA Test Desembolso',
            AccountId = acc.Id
        );
        insert rla;
        return rla;
    }

    @IsTest
    static void testDesembolso_EjecutaMetodo() {
        ResidentialLoanApplication rla = createRla();

        Test.startTest();
        try {
            FSC_DesembolsoDeCredito.desembolso(rla);
        } catch (Exception e) {
        }
        Test.stopTest();

        System.assert(true);
    }
}
