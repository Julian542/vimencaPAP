@IsTest
private class IntegrationServicesTest {
    private class ResponseMock implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        ResponseMock(Integer statusCode, String body) {
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

    private static TCP_PrequalificationService.Input validTcpInput() {
        TCP_PrequalificationService.Input input = new TCP_PrequalificationService.Input();
        input.numIdentificacion = '00108803610';
        input.tipoIdentificacion = 'Cédula';
        input.salario = 80000;
        input.tiempoLaborando = 36;
        input.tipoCliente = 1;
        input.tasaCambio = 60;
        input.clasificacionSIB = 'A';
        return input;
    }

    @IsTest
    static void parsesSuccessfulBlacklistResponse() {
        ValidacionContraListasIE.RequestDTO request = ValidacionContraListasIE.buildRequest(
            'Cédula',
            '00108803610',
            null,
            'Ana',
            null,
            'Perez',
            null,
            Date.newInstance(1990, 2, 3),
            'do'
        );
        System.assertEquals('19900203', request.birthDate);
        System.assertEquals('DO', request.nationality);
        System.assertEquals('POST', ValidacionContraListasIE.buildHttpRequest(request).getMethod());
        System.assert(ValidacionContraListasIE.toPrettyJson(request).contains('00108803610'));

        Test.setMock(
            HttpCalloutMock.class,
            new ResponseMock(
                200,
                '{"responseCode":"0","responseDesc":"OK","internalCoincidences":"N",' +
                '"externalCoincidences":"SÍ","FoundList":"PEPS","cumplo360Relevancia":8}'
            )
        );

        Test.startTest();
        ValidacionContraListasIE.ResultDTO result = ValidacionContraListasIE.consultar(request);
        Test.stopTest();

        System.assert(result.success);
        System.assertEquals(false, result.hasInternalCoincidences);
        System.assertEquals(true, result.hasExternalCoincidences);
        System.assertEquals(true, result.hasAnyCoincidences);
    }

    @IsTest
    static void handlesBlacklistValidationAndHttpErrors() {
        Boolean invalidRejected = false;
        try {
            ValidacionContraListasIE.consultar(null);
        } catch (ValidacionContraListasIE.ValidacionContraListasException expected) {
            invalidRejected = true;
        }

        ValidacionContraListasIE.RequestDTO request = ValidacionContraListasIE.buildRequest(
            'RNC', '131000001', 'Empresa Test', null, null, null, null, null, null
        );
        Test.setMock(HttpCalloutMock.class, new ResponseMock(400, '{"error":"invalid"}'));
        ValidacionContraListasIE.ResultDTO result = ValidacionContraListasIE.consultar(request);

        System.assert(invalidRejected);
        System.assertEquals(false, result.success);
        System.assert(result.errorMessage.contains('Error HTTP 400'));
    }

    @IsTest
    static void parsesSuccessfulTcpPrequalificationResponse() {
        String responseBody =
            '{"transactionId":"TX-001","applicants":{"primaryConsumer":{"interconnectResponse":' +
            '{"Filtro_BcoVimencaTcr":{"Generales":{"dictamen":"Aprobado","xcore":750,' +
            '"limite_sugerido_dop":250000,"limite_sugerido_usd":4000,' +
            '"mensajes":{"evaluacion":[{"description":"Aprobado por score"}]}}}}}}}';
        Test.setMock(HttpCalloutMock.class, new ResponseMock(200, responseBody));

        Test.startTest();
        TCP_PrequalificationService.Result result =
            TCP_PrequalificationService.prequalifyTCP(validTcpInput());
        Test.stopTest();

        System.assertEquals('Aprobado', result.dictamen);
        System.assertEquals(750, result.xcore);
        System.assertEquals('TX-001', result.transactionId);
        System.assertEquals(1, result.mensajes.size());
    }

    @IsTest
    static void handlesTcpValidationAndControlledExceptions() {
        TCP_PrequalificationService.Result validationResult =
            TCP_PrequalificationService.prequalifyTCP(null);

        TCP_PrequalificationService.TEST_THROW_GENERIC = true;
        TCP_PrequalificationService.Result genericResult =
            TCP_PrequalificationService.prequalifyTCP(validTcpInput());
        TCP_PrequalificationService.TEST_THROW_GENERIC = false;

        TCP_PrequalificationService.TEST_THROW_TCPPREQUAL = true;
        TCP_PrequalificationService.Result controlledResult =
            TCP_PrequalificationService.prequalifyTCP(validTcpInput());
        TCP_PrequalificationService.TEST_THROW_TCPPREQUAL = false;

        System.assertEquals('Referido', validationResult.dictamen);
        System.assert(validationResult.message.startsWith('Validation:'));
        System.assert(genericResult.message.startsWith('Exception:'));
        System.assert(controlledResult.message.startsWith('Validation:'));
    }

    @IsTest
    static void mapsMockedInt003ResponsesForFlow() {
        INT003_validarContraListaFlowController.useMock = true;

        List<INT003_validarContraListaFlowController.Result> invalidResults =
            INT003_validarContraListaFlowController.validarListas(
                new List<INT003_validarContraListaFlowController.Request>{ null }
            );

        INT003_validarContraListaFlowController.Request request =
            new INT003_validarContraListaFlowController.Request();
        request.accountId = UserInfo.getUserId();

        INT003_validarContraListaFlowController.mockResponse = null;
        List<INT003_validarContraListaFlowController.Result> nullResults =
            INT003_validarContraListaFlowController.validarListas(
                new List<INT003_validarContraListaFlowController.Request>{ request }
            );

        INT003.Response serviceResponse = new INT003.Response();
        serviceResponse.errorCode = '000';
        serviceResponse.values.put('CoincidenciaLE', 'Y');
        serviceResponse.values.put('CoincidenciaLI', 'N');
        serviceResponse.values.put('Listas', 'PEPS INTERNACIONALES');
        INT003_validarContraListaFlowController.mockResponse = serviceResponse;
        List<INT003_validarContraListaFlowController.Result> successResults =
            INT003_validarContraListaFlowController.validarListas(
                new List<INT003_validarContraListaFlowController.Request>{ request }
            );

        INT003_validarContraListaFlowController.mockException =
            new CalloutException('Fallo simulado');
        List<INT003_validarContraListaFlowController.Result> exceptionResults =
            INT003_validarContraListaFlowController.validarListas(
                new List<INT003_validarContraListaFlowController.Request>{ request }
            );

        System.assertEquals('FLOW-001', invalidResults[0].errorCode);
        System.assertEquals('INT003-NULL', nullResults[0].errorCode);
        System.assertEquals(true, successResults[0].isPep);
        System.assertEquals(false, successResults[0].inInternalLists);
        System.assertEquals('EXCEPTION', exceptionResults[0].errorCode);
    }
}
