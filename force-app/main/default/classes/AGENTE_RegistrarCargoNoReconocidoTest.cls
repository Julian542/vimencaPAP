@isTest
private class AGENTE_RegistrarCargoNoReconocidoTest {

    @isTest
    static void testCaminoFelizConIdYCrearCaso() {
        // 1. Setup: Tipo de Registro Individual para Persona Física
        Id recordTypeIdPF = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesIndividual').getRecordTypeId();
        
        Account acc = new Account(
            Name = 'Cliente PF Feliz',
            RecordTypeId = recordTypeIdPF,
            ACC_NumIdentificacion__c = '00108803610',
            ACC_Estado__c = 'ACTIVO',
            ACC_Condicion__c = 'CLIENTE'
        );
        insert acc;

        // 2. Armamos el Input usando los campos válidos de InvocableInput
        AGENTE_RegistrarCargoNoReconocido.InvocableInput input = new AGENTE_RegistrarCargoNoReconocido.InvocableInput();
        input.accountId = acc.Id;
        input.customerType = 'PF';
        input.identificationNumber = acc.ACC_NumIdentificacion__c;
        input.selectedTransactionJson = '{"transactionId":"TX123","amount":"150.00", "description":"Compra Amazon", "transactionDate":"2026-06-20"}';
        input.createCase = true;
        input.requiresTransfer = true;
        input.channel = 'Agentforce';

        // 3. Ejecución
        Test.startTest();
        List<AGENTE_RegistrarCargoNoReconocido.InvocableOutput> outputs = 
            AGENTE_RegistrarCargoNoReconocido.registrarCargoNoReconocido(
                new List<AGENTE_RegistrarCargoNoReconocido.InvocableInput>{input}
            );
        Test.stopTest();

        // 4. Validaciones (Asserts)
        System.assertEquals(1, outputs.size(), 'Debería retornar un solo InvocableOutput');
        System.assertEquals('OK', outputs[0].status, 'El estado debería ser OK');
        System.assertNotEquals(null, outputs[0].caseId, 'El ID del caso no debería ser nulo');
    }

    @isTest
    static void testBusquedaPorPersonaJuridicaCif_DocumentaCampoNoConsultado() {
        // 1. Setup: Tipo de Registro para Persona Jurídica
        Id recordTypeIdPJ = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Personas_Juridicas').getRecordTypeId();
        
        Account acc = new Account(
            Name = 'Empresa PJ Agentforce',
            RecordTypeId = recordTypeIdPJ,
            ACC_RNC__c = '1022328',
            ACC_CIF__c = '1022328',
            ACC_Estado__c = 'ACTIVO',
            ACC_Condicion__c = 'CLIENTE'
        );
        insert acc;

        // 2. Input: No enviamos ID, forzamos la búsqueda por CIF
        AGENTE_RegistrarCargoNoReconocido.InvocableInput input = new AGENTE_RegistrarCargoNoReconocido.InvocableInput();
        input.customerType = 'PJ';
        input.cif = '1022328';
        input.selectedTransactionJson = '{"transactionId":"TX999","amount":"5000.00", "description":"Pago Proveedor"}';
        input.createCase = true;

        Test.startTest();
        List<AGENTE_RegistrarCargoNoReconocido.InvocableOutput> outputs = 
            AGENTE_RegistrarCargoNoReconocido.registrarCargoNoReconocido(
                new List<AGENTE_RegistrarCargoNoReconocido.InvocableInput>{input}
            );
        Test.stopTest();

        System.assertEquals('ERROR', outputs[0].status);
        System.assert(outputs[0].message.contains('ACC_Correo_Electronico_Cliente__c'), outputs[0].message);
    }

    @isTest
    static void testCuentaInactiva() {
        // Setup: Cuenta con estado diferente a ACTIVO
        Id recordTypeIdPF = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesIndividual').getRecordTypeId();
        
        Account acc = new Account(
            Name = 'Cliente Inactivo',
            RecordTypeId = recordTypeIdPF,
            ACC_NumIdentificacion__c = '00108803611',
            ACC_Estado__c = 'INACTIVO',
            ACC_Condicion__c = 'CLIENTE'
        );
        insert acc;

        AGENTE_RegistrarCargoNoReconocido.InvocableInput input = new AGENTE_RegistrarCargoNoReconocido.InvocableInput();
        input.accountId = acc.Id;
        input.selectedTransactionJson = '{"transactionId":"TX123"}';

        Test.startTest();
        List<AGENTE_RegistrarCargoNoReconocido.InvocableOutput> outputs = 
            AGENTE_RegistrarCargoNoReconocido.registrarCargoNoReconocido(
                new List<AGENTE_RegistrarCargoNoReconocido.InvocableInput>{input}
            );
        Test.stopTest();

        System.assertEquals('ACCOUNT_INACTIVE', outputs[0].status, 'Debería detectar que la cuenta no está activa');
    }

    @isTest
    static void testInputsInvalidosYVacios() {
        Test.startTest();
        
        // Prueba 1: Lista nula
        List<AGENTE_RegistrarCargoNoReconocido.InvocableOutput> out1 = 
            AGENTE_RegistrarCargoNoReconocido.registrarCargoNoReconocido(null);

        // Prueba 2: JSON Vacío
        AGENTE_RegistrarCargoNoReconocido.InvocableInput inputSinJson = new AGENTE_RegistrarCargoNoReconocido.InvocableInput();
        List<AGENTE_RegistrarCargoNoReconocido.InvocableOutput> out2 = 
            AGENTE_RegistrarCargoNoReconocido.registrarCargoNoReconocido(
                new List<AGENTE_RegistrarCargoNoReconocido.InvocableInput>{inputSinJson}
            );
            
        // Prueba 3: JSON Inválido (Malformado) para probar el catch
        AGENTE_RegistrarCargoNoReconocido.InvocableInput inputJsonMalo = new AGENTE_RegistrarCargoNoReconocido.InvocableInput();
        inputJsonMalo.accountId = '001000000000000AAA'; // Id Falso
        inputJsonMalo.selectedTransactionJson = 'ESTO NO ES UN JSON';
        List<AGENTE_RegistrarCargoNoReconocido.InvocableOutput> out3 = 
            AGENTE_RegistrarCargoNoReconocido.registrarCargoNoReconocido(
                new List<AGENTE_RegistrarCargoNoReconocido.InvocableInput>{inputJsonMalo}
            );

        Test.stopTest();

        System.assertEquals('INVALID_INPUT', out1[0].status, 'Debería fallar por input nulo');
        System.assertEquals('INVALID_INPUT', out2[0].status, 'Debería fallar por falta de JSON');
        System.assertEquals('ACCOUNT_NOT_FOUND', out3[0].status, 'Debe resolver primero la cuenta antes de leer el JSON');
    }
    
    @isTest
    static void testCuentaNoEncontrada() {
        AGENTE_RegistrarCargoNoReconocido.InvocableInput input = new AGENTE_RegistrarCargoNoReconocido.InvocableInput();
        input.customerType = 'PF';
        input.identificationNumber = '99999999999'; // Documento que no existe en DB
        input.selectedTransactionJson = '{"transactionId":"TX123"}';

        Test.startTest();
        List<AGENTE_RegistrarCargoNoReconocido.InvocableOutput> outputs = 
            AGENTE_RegistrarCargoNoReconocido.registrarCargoNoReconocido(
                new List<AGENTE_RegistrarCargoNoReconocido.InvocableInput>{input}
            );
        Test.stopTest();

        System.assertEquals('ACCOUNT_NOT_FOUND', outputs[0].status, 'No debería encontrar la cuenta');
    }
    @isTest
    static void testJsonInvalidoConCuentaExistente() {
        Account acc = createAccount('Json Malo', '00108803612', 'ACTIVO');

        AGENTE_RegistrarCargoNoReconocido.InvocableInput input = new AGENTE_RegistrarCargoNoReconocido.InvocableInput();
        input.accountId = acc.Id;
        input.selectedTransactionJson = 'ESTO NO ES JSON';

        List<AGENTE_RegistrarCargoNoReconocido.InvocableOutput> outputs =
            AGENTE_RegistrarCargoNoReconocido.registrarCargoNoReconocido(
                new List<AGENTE_RegistrarCargoNoReconocido.InvocableInput>{ input }
            );

        System.assertEquals('ERROR', outputs[0].status);
    }

    @isTest
    static void testTipoClienteInvalido() {
        Account acc = createAccount('Cliente Tipo Invalido', '00108803613', 'ACTIVO');

        AGENTE_RegistrarCargoNoReconocido.InvocableInput input = new AGENTE_RegistrarCargoNoReconocido.InvocableInput();
        input.accountId = acc.Id;
        input.customerType = 'XX';
        input.selectedTransactionJson = '{"transactionId":"TX123"}';

        List<AGENTE_RegistrarCargoNoReconocido.InvocableOutput> outputs =
            AGENTE_RegistrarCargoNoReconocido.registrarCargoNoReconocido(
                new List<AGENTE_RegistrarCargoNoReconocido.InvocableInput>{ input }
            );

        System.assertEquals('INVALID_INPUT', outputs[0].status);
    }

    @isTest
    static void testSinCrearCasoYConCola() {
        Account acc = createAccount('Cliente Sin Caso', '00108803614', 'ACTIVO');

        AGENTE_RegistrarCargoNoReconocido.InvocableInput input = new AGENTE_RegistrarCargoNoReconocido.InvocableInput();
        input.accountId = acc.Id;
        input.targetQueueName = 'Servicio a Cliente';
        input.selectedTransactionJson = '{"transactionId":"TX123","amount":"10.00"}';
        input.createCase = false;
        input.requiresTransfer = true;

        List<AGENTE_RegistrarCargoNoReconocido.InvocableOutput> outputs =
            AGENTE_RegistrarCargoNoReconocido.registrarCargoNoReconocido(
                new List<AGENTE_RegistrarCargoNoReconocido.InvocableInput>{ input }
            );

        System.assertEquals('OK', outputs[0].status);
    }

    @isTest
    static void testValidacionesAdicionales() {
        AGENTE_RegistrarCargoNoReconocido.InvocableInput sinCuenta = new AGENTE_RegistrarCargoNoReconocido.InvocableInput();
        sinCuenta.selectedTransactionJson = '{"transactionId":"TX123"}';

        AGENTE_RegistrarCargoNoReconocido.InvocableInput pjSinCif = new AGENTE_RegistrarCargoNoReconocido.InvocableInput();
        pjSinCif.customerType = 'PJ';
        pjSinCif.identificationNumber = '12345';
        pjSinCif.selectedTransactionJson = '{"transactionId":"TX124"}';

        List<AGENTE_RegistrarCargoNoReconocido.InvocableOutput> outputs =
            AGENTE_RegistrarCargoNoReconocido.registrarCargoNoReconocido(
                new List<AGENTE_RegistrarCargoNoReconocido.InvocableInput>{ null, sinCuenta, pjSinCif }
            );

        System.assertEquals('INVALID_INPUT', outputs[0].status);
        System.assertEquals('INVALID_INPUT', outputs[1].status);
        System.assertEquals('ACCOUNT_NOT_FOUND', outputs[2].status);
    }

    private static Account createAccount(String name, String documentNumber, String status) {
        Account acc = new Account(
            Name = name,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesIndividual').getRecordTypeId(),
            ACC_NumIdentificacion__c = documentNumber,
            ACC_Estado__c = status,
            ACC_Condicion__c = 'CLIENTE'
        );
        insert acc;
        return acc;
    }
}
