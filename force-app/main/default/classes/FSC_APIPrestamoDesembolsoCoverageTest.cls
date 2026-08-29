@IsTest
private class FSC_APIPrestamoDesembolsoCoverageTest {
    @IsTest
    static void handlesEmptyAndIncompleteInputs() {
        System.assertEquals(0, FSC_APIPrestamoDesembolso.run(null).size());
        System.assertEquals(0, FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>()).size());

        FSC_APIPrestamoDesembolso.Input missingId = new FSC_APIPrestamoDesembolso.Input();
        List<FSC_APIPrestamoDesembolso.Output> missingIdOutput =
            FSC_APIPrestamoDesembolso.run(new List<FSC_APIPrestamoDesembolso.Input>{ missingId });
        System.assertEquals(1, missingIdOutput.size());
        System.assertEquals('residentialLoanApplicationId requerido.', missingIdOutput[0].message);
    }
}
