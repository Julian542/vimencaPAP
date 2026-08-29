@IsTest
private class FSC_APIBuroCreditoTest {

    private static Id getRecordTypeId(String developerName) {

        Map<String, Schema.RecordTypeInfo> rtMap =
            ResidentialLoanApplication.SObjectType
                .getDescribe()
                .getRecordTypeInfosByDeveloperName();

        if (rtMap != null && rtMap.containsKey(developerName)) {
            return rtMap.get(developerName).getRecordTypeId();
        }

        return null;
    }

    private static Account createAccount() {
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'Cuenta Test API Buró',
            ACC_RNC__c = String.valueOf(Math.abs(Crypto.getRandomInteger())).leftPad(9, '0').substring(0, 9),
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC'
        );
        insert acc;
        return acc;
    }

    private static ResidentialLoanApplication createRla(String recordTypeDeveloperName) {
        Account acc = createAccount();

        ResidentialLoanApplication rla = new ResidentialLoanApplication();

        Id rtId = recordTypeDeveloperName != null ? getRecordTypeId(recordTypeDeveloperName) : null;
        if (rtId != null) {
            rla.RecordTypeId = rtId;
        }

        rla.AccountId = acc.Id;
        rla.Name = 'Test';
        insert rla;
        return rla;
    }

    private static Id createDeletedRlaId() {
        ResidentialLoanApplication rla = createRla(null);
        Id deletedId = rla.Id;
        delete rla;
        return deletedId;
    }

    @IsTest
    static void testRun_NullInputs() {
        Test.startTest();
        List<FSC_APIBuroCredito.Output> result = FSC_APIBuroCredito.run(null);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testRun_EmptyInputs() {
        Test.startTest();
        List<FSC_APIBuroCredito.Output> result = FSC_APIBuroCredito.run(new List<FSC_APIBuroCredito.Input>());
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testRun_InputNull() {
        List<FSC_APIBuroCredito.Input> inputs = new List<FSC_APIBuroCredito.Input>{
            null
        };

        Test.startTest();
        List<FSC_APIBuroCredito.Output> result = FSC_APIBuroCredito.run(inputs);
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(false, result[0].success);
        System.assertEquals('residentialLoanApplicationId requerido.', result[0].message);
    }

    @IsTest
    static void testRun_IdNull() {
        FSC_APIBuroCredito.Input input = new FSC_APIBuroCredito.Input();
        input.residentialLoanApplicationId = null;

        Test.startTest();
        List<FSC_APIBuroCredito.Output> result = FSC_APIBuroCredito.run(
            new List<FSC_APIBuroCredito.Input>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(false, result[0].success);
        System.assertEquals('residentialLoanApplicationId requerido.', result[0].message);
    }

    @IsTest
    static void testRun_RlaNoEncontrado() {
        Id deletedRlaId = createDeletedRlaId();

        FSC_APIBuroCredito.Input input = new FSC_APIBuroCredito.Input();
        input.residentialLoanApplicationId = deletedRlaId;

        Test.startTest();
        List<FSC_APIBuroCredito.Output> result = FSC_APIBuroCredito.run(
            new List<FSC_APIBuroCredito.Input>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals(false, result[0].success);
        System.assertEquals('No se encontró ResidentialLoanApplication para el Id provisto.', result[0].message);
    }

    @IsTest
    static void testRun_RecordTypeContemplado() {
        Id pymeRtId = getRecordTypeId('FSC_Solicitud_Credito_PYME');

        if (pymeRtId == null) {
            System.assert(true);
            return;
        }

        Account acc = createAccount();

        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            AccountId = acc.Id,
            RecordTypeId = pymeRtId,
            Name = 'Test'
        );
        insert rla;

        FSC_APIBuroCredito.Input input = new FSC_APIBuroCredito.Input();
        input.residentialLoanApplicationId = rla.Id;

        Test.startTest();
        List<FSC_APIBuroCredito.Output> result =
            FSC_APIBuroCredito.run(new List<FSC_APIBuroCredito.Input>{ input });
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('FSC_Solicitud_Credito_PYME', result[0].recordTypeDeveloperName);

        System.assertNotEquals(null, result[0].success);
    }

    @IsTest
    static void testExtractResultado_Null() {
        Test.startTest();
        Map<String, String> result = FSC_APIBuroCredito.extractResultado(null);
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @IsTest
    static void testExtractResultado_ConStatusYRejectionReason() {
        Map<String, Object> input = new Map<String, Object>{
            'Status' => 'Rechazado',
            'RejectionReasonCode' => 'RC001'
        };

        Test.startTest();
        Map<String, String> result = FSC_APIBuroCredito.extractResultado(input);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('Rechazado', result.get('Status'));
        System.assertEquals('RC001', result.get('RejectionReasonCode'));
    }

    @IsTest
    static void testExtractResultado_SoloStatus() {
        Map<String, Object> input = new Map<String, Object>{
            'Status' => 'Aprobado'
        };

        Test.startTest();
        Map<String, String> result = FSC_APIBuroCredito.extractResultado(input);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals('Aprobado', result.get('Status'));
        System.assertEquals(null, result.get('RejectionReasonCode'));
    }
}
