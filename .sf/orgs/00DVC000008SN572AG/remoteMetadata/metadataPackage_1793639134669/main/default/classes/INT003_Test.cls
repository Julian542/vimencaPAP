@IsTest
private class INT003_Test {

    private class Http200Mock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setStatus('OK');
            res.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            res.setBody(
                '<Envelope>' +
                    '<ErrorCode>000</ErrorCode>' +
                    '<ErrorText>OK</ErrorText>' +
                    '<NumDocumento>12345678</NumDocumento>' +
                    '<TipoDocumento>DNI</TipoDocumento>' +
                    '<CoincidenciaLI>N</CoincidenciaLI>' +
                    '<CoincidenciaLE>Y</CoincidenciaLE>' +
                    '<Listas>LISTA TEST</Listas>' +
                '</Envelope>'
            );
            return res;
        }
    }

    private class Http500Mock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            res.setHeader('Content-Type', 'text/plain');
            res.setBody('Error interno simulado');
            return res;
        }
    }

    private static String getFirstActivePicklistValue(Schema.SObjectField field) {
        for (Schema.PicklistEntry pe : field.getDescribe().getPicklistValues()) {
            if (pe.isActive()) {
                return pe.getValue();
            }
        }
        return null;
    }

    private static String getCommonPicklistValue(
        Schema.SObjectField sourceField,
        Schema.SObjectField targetField
    ) {
        Set<String> targetValues = new Set<String>();
        for (Schema.PicklistEntry pe : targetField.getDescribe().getPicklistValues()) {
            if (pe.isActive()) {
                targetValues.add(pe.getValue());
            }
        }

        for (Schema.PicklistEntry pe : sourceField.getDescribe().getPicklistValues()) {
            if (pe.isActive() && targetValues.contains(pe.getValue())) {
                return pe.getValue();
            }
        }
        return null;
    }

    private static String getCompatibleUppercasePicklistValue(
        Schema.SObjectField sourceField,
        Schema.SObjectField targetField
    ) {
        Set<String> targetValuesUpper = new Set<String>();
        for (Schema.PicklistEntry pe : targetField.getDescribe().getPicklistValues()) {
            if (pe.isActive() && pe.getValue() != null) {
                targetValuesUpper.add(pe.getValue().toUpperCase());
            }
        }

        for (Schema.PicklistEntry pe : sourceField.getDescribe().getPicklistValues()) {
            if (pe.isActive() && pe.getValue() != null && targetValuesUpper.contains(pe.getValue().toUpperCase())) {
                return pe.getValue();
            }
        }
        return null;
    }

    private static String getAnyActiveStageName() {
        OpportunityStage os = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true LIMIT 1];
        return os.MasterLabel;
    }

    private static Account createAccount(String condicion) {
        List<Account> accList = TestDataFactory.createPersonAccounts(1);
        Account acc = accList[0];

        Map<String, Schema.RecordTypeInfo> rtInfos =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();

        if (rtInfos.containsKey('PersonAccount')) {
            acc.RecordTypeId = rtInfos.get('PersonAccount').getRecordTypeId();
        }

        acc.ACC_Condicion__c = condicion;
        acc.ACC_NumIdentificacion__c = '12345678';
        acc.ACC_TipoIdentificacion__c = 'Cédula';
        acc.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';

        update acc;
        return acc;
    }

    private static Matriz_lista_control__c createMatriz(
        String li,
        String le,
        String estado,
        String subEstado
    ) {
        Matriz_lista_control__c matriz = new Matriz_lista_control__c();
        matriz.MAT_Coincidencia_en_listas__c = li;
        matriz.MAT_Coincidencia_en_listas_externas__c = le;

        String resultadoValido = getFirstActivePicklistValue(
            Matriz_lista_control__c.MAT_Resultado_validacion__c
        );
        if (resultadoValido != null) {
            matriz.MAT_Resultado_validacion__c = resultadoValido;
        }

        if (estado != null) {
            matriz.MAT_Estado__c = estado;
        }

        if (subEstado != null) {
            matriz.MAT_Sub_estado__c = subEstado;
        }

        insert matriz;
        return matriz;
    }

    private static INT003.Response buildResponse(String li, String le, String listas) {
        INT003.Response r = new INT003.Response();
        r.values.put('CoincidenciaLI', li);
        r.values.put('CoincidenciaLE', le);
        r.values.put('Listas', listas);
        return r;
    }

    private static ResidentialLoanApplication createLoan(Id accountId) {
        Opportunity opp = new Opportunity(
            Name = 'Opp Test INT003',
            StageName = getAnyActiveStageName(),
            CloseDate = Date.today().addDays(30),
            AccountId = accountId
        );
        insert opp;

        SObject loanSObj = Schema.getGlobalDescribe().get('ResidentialLoanApplication').newSObject();
        Map<String, Schema.SObjectField> fields =
            Schema.getGlobalDescribe().get('ResidentialLoanApplication').getDescribe().fields.getMap();

        if (fields.containsKey('AccountId')) {
            loanSObj.put('AccountId', accountId);
        }
        if (fields.containsKey('OpportunityId')) {
            loanSObj.put('OpportunityId', opp.Id);
        }
        if (fields.containsKey('Name') && fields.get('Name').getDescribe().isCreateable()) {
            loanSObj.put('Name', 'Solicitud Test INT003');
        }

        insert loanSObj;

        return [
            SELECT Id, FSC_Resultado_PEP_Listas__c, FSC_ErrorValidacionListas__c, FSC_Subestado__c
            FROM ResidentialLoanApplication
            WHERE Id = :(Id) loanSObj.get('Id')
            LIMIT 1
        ];
    }

    @IsTest
    static void testParse_ok() {
        String xml =
            '<Envelope>' +
                '<ErrorCode>000</ErrorCode>' +
                '<ErrorText>OK</ErrorText>' +
                '<NumDocumento>12345678</NumDocumento>' +
                '<TipoDocumento>DNI</TipoDocumento>' +
                '<CoincidenciaLI>Y</CoincidenciaLI>' +
                '<CoincidenciaLE>N</CoincidenciaLE>' +
                '<Listas>PEP Yamp; OFAC</Listas>' +
            '</Envelope>';

        INT003.Response resp = INT003.parse(xml);

        System.assertEquals('000', resp.errorCode);
        System.assertEquals('OK', resp.errorText);
        System.assertEquals('12345678', resp.values.get('NumDocumento'));
        System.assertEquals('DNI', resp.values.get('TipoDocumento'));
        System.assertEquals('Y', resp.values.get('CoincidenciaLI'));
        System.assertEquals('N', resp.values.get('CoincidenciaLE'));
        System.assertEquals('PEP & OFAC', resp.values.get('Listas'));
    }

    @IsTest
    static void testParse_error() {
        String xml =
            '<Envelope>' +
                '<ErrorCode>999</ErrorCode>' +
                '<ErrorText>Error</ErrorText>' +
            '</Envelope>';

        INT003.Response resp = INT003.parse(xml);

        System.assertEquals('999', resp.errorCode);
        System.assertEquals('Error', resp.errorText);
        System.assertEquals(null, resp.values.get('NumDocumento'));
        System.assertEquals(null, resp.values.get('CoincidenciaLI'));
    }

    @IsTest
    static void testUpdateAccount_cliente() {
        Account acc = createAccount('CLIENTE');
        Matriz_lista_control__c matriz = createMatriz('Y', 'N', null, null);

        INT003.Response resp = buildResponse('Y', 'N', 'LISTA INTERNA');

        Test.startTest();
        INT003.updateAccount(resp, acc.Id);
        Test.stopTest();

        Account updated = [
            SELECT
                ACC_Resultado_Validacion__c,
                ACC_Coincidencia_Listas_Externas__c,
                ACC_Coincidencia_Listas_Internas__c,
                ACC_Listas__c,
                ACC_Condicion__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals('CLIENTE', updated.ACC_Condicion__c);
        System.assertEquals(matriz.MAT_Resultado_validacion__c, updated.ACC_Resultado_Validacion__c);
        System.assertEquals(false, updated.ACC_Coincidencia_Listas_Externas__c);
        System.assertEquals(true, updated.ACC_Coincidencia_Listas_Internas__c);
        System.assertEquals('LISTA INTERNA', updated.ACC_Listas__c);
    }

    @IsTest
    static void testUpdateAccount_noCliente() {
        Account acc = createAccount('PROSPECTO');

        String estadoValido = getCommonPicklistValue(
            Matriz_lista_control__c.MAT_Estado__c,
            Account.ACC_Estado__c
        );
        String subEstadoValido = getCompatibleUppercasePicklistValue(
            Matriz_lista_control__c.MAT_Sub_estado__c,
            Account.ACC_SubEstado__c
        );

        Matriz_lista_control__c matriz = createMatriz('N', 'Y', estadoValido, subEstadoValido);

        INT003.Response resp = buildResponse('N', 'Y', 'LISTA EXTERNA');

        Test.startTest();
        INT003.updateAccount(resp, acc.Id);
        Test.stopTest();

        Account updated = [
            SELECT
                ACC_Resultado_Validacion__c,
                ACC_Coincidencia_Listas_Externas__c,
                ACC_Coincidencia_Listas_Internas__c,
                ACC_Listas__c,
                ACC_Condicion__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(false, updated.ACC_Coincidencia_Listas_Internas__c);
    }

    @IsTest
    static void testUpdateLoan_conCoincidenciaLI() {
        Account acc = createAccount('PROSPECTO');
        ResidentialLoanApplication rla = createLoan(acc.Id);

        INT003.Response resp = buildResponse('Y', 'N', 'LISTA TEST');

        Test.startTest();
        INT003.updateLoan(resp, rla.Id);
        Test.stopTest();

        ResidentialLoanApplication updated = [
            SELECT FSC_Resultado_PEP_Listas__c, FSC_ErrorValidacionListas__c, FSC_Subestado__c
            FROM ResidentialLoanApplication
            WHERE Id = :rla.Id
        ];

        System.assertEquals('Coincidencia', updated.FSC_Resultado_PEP_Listas__c);
        System.assertEquals(null, updated.FSC_ErrorValidacionListas__c);
    }

    @IsTest
    static void testUpdateLoan_conCoincidenciaLE() {
        Account acc = createAccount('PROSPECTO');
        ResidentialLoanApplication rla = createLoan(acc.Id);

        INT003.Response resp = buildResponse('N', 'Y', 'LISTA TEST');

        Test.startTest();
        INT003.updateLoan(resp, rla.Id);
        Test.stopTest();

        ResidentialLoanApplication updated = [
            SELECT FSC_Resultado_PEP_Listas__c, FSC_ErrorValidacionListas__c, FSC_Subestado__c
            FROM ResidentialLoanApplication
            WHERE Id = :rla.Id
        ];

        System.assertEquals('Coincidencia', updated.FSC_Resultado_PEP_Listas__c);
        System.assertEquals(null, updated.FSC_ErrorValidacionListas__c);
    }

    @IsTest
    static void testUpdateLoan_sinCoincidencias() {
        Account acc = createAccount('PROSPECTO');
        ResidentialLoanApplication rla = createLoan(acc.Id);

        INT003.Response resp = buildResponse('N', 'N', 'SIN LISTAS');

        Test.startTest();
        INT003.updateLoan(resp, rla.Id);
        Test.stopTest();

        ResidentialLoanApplication updated = [
            SELECT FSC_Resultado_PEP_Listas__c, FSC_ErrorValidacionListas__c, FSC_Subestado__c
            FROM ResidentialLoanApplication
            WHERE Id = :rla.Id
        ];

        System.assertEquals(null, updated.FSC_ErrorValidacionListas__c);
    }

    @IsTest
    static void testUpdateLoan_noRevienta_conIdValidoPeroObjetoIncorrecto() {
        INT003.Response resp = buildResponse('N', 'N', 'SIN LISTAS');

        Test.startTest();
        INT003.updateLoan(resp, UserInfo.getUserId());
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testUpdateLoanError_ok() {
        Account acc = createAccount('PROSPECTO');
        ResidentialLoanApplication rla = createLoan(acc.Id);

        Test.startTest();
        INT003.updateLoanError(rla.Id, 'Error simulado');
        Test.stopTest();

        ResidentialLoanApplication updated = [
            SELECT FSC_ErrorValidacionListas__c
            FROM ResidentialLoanApplication
            WHERE Id = :rla.Id
        ];

        System.assertEquals('Error simulado', updated.FSC_ErrorValidacionListas__c);
    }

    @IsTest
    static void testUpdateLoanError_noRevienta_conIdValidoPeroObjetoIncorrecto() {
        Test.startTest();
        INT003.updateLoanError(UserInfo.getUserId(), 'Error simulado');
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testFillXML() {
        Account acc = createAccount('CLIENTE');
        INT003.Response resp = new INT003.Response();

        String frame =
            '<Envelope>' +
                '<Function>' +
                    '<Documento>[function_document]</Documento>' +
                    '<TipoDocumento>[function_documentType]</TipoDocumento>' +
                '</Function>' +
            '</Envelope>';

        String result = INT003.fillXML(resp, acc, frame);

        System.assert(result.contains('12345678'));
        System.assert(result.contains('Cédula'));
        System.assertEquals(false, result.contains('[function_document]'));
        System.assertEquals(false, result.contains('[function_documentType]'));
    }

    @IsTest
    static void testFillDetailClient() {
        Account acc = createAccount('CLIENTE');

        Map<String, String> valuesClient = new Map<String, String>{
            '[function_document]' => 'ACC_NumIdentificacion__c',
            '[function_documentType]' => 'ACC_TipoIdentificacion__c'
        };

        String frame =
            '<Documento>[function_document]</Documento>' +
            '<TipoDocumento>[function_documentType]</TipoDocumento>';

        String result = INT003.fillDetailClient(valuesClient, acc, frame);

        System.assert(result.contains('12345678'));
        System.assert(result.contains('Cédula'));
        System.assertEquals(false, result.contains('[function_document]'));
        System.assertEquals(false, result.contains('[function_documentType]'));
    }

    @IsTest
    static void testResponseStatic() {
        INT003.response = buildResponse('N', 'Y', 'LISTA TEST');

        System.assertNotEquals(null, INT003.response);
        System.assertEquals('N', INT003.response.values.get('CoincidenciaLI'));
        System.assertEquals('Y', INT003.response.values.get('CoincidenciaLE'));
        System.assertEquals('LISTA TEST', INT003.response.values.get('Listas'));
    }

    @IsTest(SeeAllData=true)
    static void testValidatePF_200_conLoan() {
        Account acc = createAccount('PROSPECTO');
        ResidentialLoanApplication rla = createLoan(acc.Id);

        String estadoValido = getCommonPicklistValue(
            Matriz_lista_control__c.MAT_Estado__c,
            Account.ACC_Estado__c
        );
        String subEstadoValido = getCompatibleUppercasePicklistValue(
            Matriz_lista_control__c.MAT_Sub_estado__c,
            Account.ACC_SubEstado__c
        );

        createMatriz('N', 'Y', estadoValido, subEstadoValido);

        Test.setMock(HttpCalloutMock.class, new Http200Mock());

        Test.startTest();
        INT003.validatePF(acc.Id, rla.Id);
        Test.stopTest();

        ResidentialLoanApplication updated = [
            SELECT FSC_Resultado_PEP_Listas__c, FSC_ErrorValidacionListas__c
            FROM ResidentialLoanApplication
            WHERE Id = :rla.Id
        ];

        System.assertEquals('Coincidencia', updated.FSC_Resultado_PEP_Listas__c);
        System.assertEquals(null, updated.FSC_ErrorValidacionListas__c);
        System.assertNotEquals(null, INT003.response);
    }

    @IsTest(SeeAllData=true)
    static void testValidatePF_500_conLoan() {
        Account acc = createAccount('PROSPECTO');
        ResidentialLoanApplication rla = createLoan(acc.Id);

        Test.setMock(HttpCalloutMock.class, new Http500Mock());

        Test.startTest();
        INT003.validatePF(acc.Id, rla.Id);
        Test.stopTest();

        ResidentialLoanApplication updated = [
            SELECT FSC_ErrorValidacionListas__c
            FROM ResidentialLoanApplication
            WHERE Id = :rla.Id
        ];

        System.assertNotEquals(null, updated.FSC_ErrorValidacionListas__c);
        System.assert(updated.FSC_ErrorValidacionListas__c.contains('Error 500'));
    }
}