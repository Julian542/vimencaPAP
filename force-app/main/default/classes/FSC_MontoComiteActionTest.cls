@IsTest
private class FSC_MontoComiteActionTest {
    private static ResidentialLoanApplication crearSolicitud(String nombre, Decimal monto) {
        // La acción solo lee el monto; los límites de política se prueban en FSC_CreditPolicyGuardTest.
        FSC_CreditPolicyGuard.bypassInTests = true;
        Account cuenta = new Account(Name = 'Cuenta Monto Comite ' + nombre);
        insert cuenta;

        ResidentialLoanApplication solicitud = new ResidentialLoanApplication(
            Name = nombre,
            AccountId = cuenta.Id,
            Status = 'Borrador',
            RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
                .get('FSC_Solicitud_Credito_Hipotecario')
                .getRecordTypeId(),
            FSC_Monto__c = monto
        );
        insert solicitud;
        return solicitud;
    }

    private static FSC_MontoComiteAction.Input entrada(Id solicitudId) {
        FSC_MontoComiteAction.Input inputItem = new FSC_MontoComiteAction.Input();
        inputItem.solicitudId = solicitudId;
        return inputItem;
    }

    @IsTest
    static void runDevuelveElMontoDeCadaSolicitudEnOrden() {
        ResidentialLoanApplication menor = crearSolicitud('Monto comite menor', 2000000);
        ResidentialLoanApplication mayor = crearSolicitud('Monto comite mayor', 30000000);

        Test.startTest();
        List<FSC_MontoComiteAction.Output> outputs = FSC_MontoComiteAction.run(
            new List<FSC_MontoComiteAction.Input>{ entrada(mayor.Id), entrada(menor.Id) }
        );
        Test.stopTest();

        Assert.areEqual(2, outputs.size(), 'Debe devolver una salida por cada entrada.');
        Assert.areEqual(30000000, outputs[0].monto, 'La primera salida corresponde a la primera solicitud enviada.');
        Assert.areEqual(2000000, outputs[1].monto, 'La segunda salida corresponde a la segunda solicitud enviada.');
    }

    @IsTest
    static void runToleraEntradasVaciasYSolicitudesInexistentes() {
        Assert.areEqual(0, FSC_MontoComiteAction.run(null).size(), 'Sin entradas no debe devolver salidas.');

        List<FSC_MontoComiteAction.Output> outputs = FSC_MontoComiteAction.run(
            new List<FSC_MontoComiteAction.Input>{ entrada(null), null }
        );

        Assert.areEqual(2, outputs.size(), 'Debe conservar una salida por entrada aunque no tenga solicitud.');
        Assert.isNull(outputs[0].monto, 'Sin solicitud no hay monto.');
        Assert.isNull(outputs[1].monto, 'Una entrada nula no debe fallar.');
    }
}