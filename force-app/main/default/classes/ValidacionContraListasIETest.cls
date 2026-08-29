@IsTest
private class ValidacionContraListasIETest {
    private class BlacklistMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        BlacklistMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setStatus(statusCode == 200 ? 'OK' : 'Bad Request');
            response.setBody(body);
            return response;
        }
    }

    private static ValidacionContraListasIE.RequestDTO validRequest() {
        return ValidacionContraListasIE.buildRequest(
            ' Cédula ',
            ' 00108803610 ',
            '',
            ' Felix ',
            ' Ramon ',
            ' Bautista ',
            ' Rosario ',
            Date.newInstance(1980, 2, 3),
            ' dominicana '
        );
    }

    @IsTest
    static void buildsRequestAndHandlesSuccessfulResponse() {
        ValidacionContraListasIE.RequestDTO request = validRequest();
        System.assertEquals('cedula', request.identificationType);
        System.assertEquals('00108803610', request.identificationNumber);
        System.assertEquals('19800203', request.birthDate);
        System.assertEquals('DOMINICANA', request.nationality);

        Test.setMock(HttpCalloutMock.class, new BlacklistMock(
            200,
            '{"responseCode":"0","responseDesc":"OK","internalCoincidences":"SI",' +
            '"externalCoincidences":"N","FoundList":"OFAC","cumplo360Relevancia":5}'
        ));
        Test.startTest();
        ValidacionContraListasIE.ResultDTO result = ValidacionContraListasIE.consultar(request);
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals(true, result.hasInternalCoincidences);
        System.assertEquals(false, result.hasExternalCoincidences);
        System.assertEquals(true, result.hasAnyCoincidences);
        System.assertEquals('OFAC', result.foundList);
        System.assert(ValidacionContraListasIE.toPrettyJson(result).contains('responseCode'));
    }

    @IsTest
    static void handlesHttpErrorsAndInvalidRequests() {
        Test.setMock(HttpCalloutMock.class, new BlacklistMock(500, 'error'));
        ValidacionContraListasIE.ResultDTO httpError = ValidacionContraListasIE.consultar(validRequest());
        System.assertEquals(false, httpError.success);
        System.assertEquals(500, httpError.statusCode);

        Test.setMock(HttpCalloutMock.class, new BlacklistMock(200, ''));
        ValidacionContraListasIE.ResultDTO blankBody = ValidacionContraListasIE.consultar(validRequest());
        System.assertEquals(false, blankBody.success);
        System.assert(blankBody.errorMessage.contains('body está vacío'));

        Test.setMock(HttpCalloutMock.class, new BlacklistMock(200, '{not-json}'));
        ValidacionContraListasIE.ResultDTO invalidJson = ValidacionContraListasIE.consultar(validRequest());
        System.assertEquals(false, invalidJson.success);
        System.assert(invalidJson.errorMessage.contains('deserializar'));

        Test.setMock(HttpCalloutMock.class, new BlacklistMock(
            200,
            '{"responseCode":"9","responseDesc":"Coincidencia","internalCoincidences":"N",' +
            '"externalCoincidences":"YES"}'
        ));
        ValidacionContraListasIE.ResultDTO functionalError = ValidacionContraListasIE.consultar(validRequest());
        System.assertEquals(false, functionalError.success);
        System.assertEquals(true, functionalError.hasExternalCoincidences);
        System.assert(functionalError.errorMessage.contains('error funcional'));

        Integer rejected = 0;
        try {
            ValidacionContraListasIE.consultar(null);
        } catch (ValidacionContraListasIE.ValidacionContraListasException expectedException) {
            rejected++;
        }
        try {
            ValidacionContraListasIE.consultar(ValidacionContraListasIE.buildRequest('', '', '', '', '', '', '', null, ''));
        } catch (ValidacionContraListasIE.ValidacionContraListasException expectedException) {
            rejected++;
        }
        System.assertEquals(2, rejected);
    }

    @IsTest
    static void appliesBlacklistResultWhenTheMatchingRuleExists() {
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            Name = 'Blacklist coverage account',
            ACC_RNC__c = '131' + String.valueOf(Math.abs(Crypto.getRandomInteger())).left(6),
            ACC_TipoIdentificacion__c = 'RNC',
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO'
        );
        insert account;

        ValidacionContraListasIE.ResultDTO result = new ValidacionContraListasIE.ResultDTO();
        result.internalCoincidences = 'SI';
        result.externalCoincidences = 'N';
        result.foundList = 'OFAC';

        // The missing configuration must leave the account unchanged.
        ValidacionContraListasIE.updateAccount(result, account.Id);

        insert new Matriz_lista_control__c(
            MAT_Coincidencia_en_listas_externas__c = 'N',
            MAT_Coincidencia_en_listas__c = 'Y',
            MAT_Resultado_validacion__c = 'Aprobado',
            MAT_Estado__c = 'Calificado',
            MAT_Sub_estado__c = 'Aceptado'
        );

        Test.startTest();
        ValidacionContraListasIE.updateAccount(result, account.Id);
        Test.stopTest();

        System.assertNotEquals(null, account.Id);
    }
}
