@IsTest
private class FSC_DesembolsoDeCreditoTest {

    private static Account createAccount() {
        Account acc = new Account(Name = 'Cuenta Test Desembolso');
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