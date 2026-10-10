global without sharing class FSC_CallAPIs implements omnistudio.VlocityOpenInterface, Callable{
    private static final String INTEGRATION_CODE = '003';
    private static final String INTEGRATION_FUNCTION = 'ValidaListasControl';
    private static final String ERROR_LOG_SEPARATOR = '\n';
    private static final Integer ERROR_FIELD_MAX_LENGTH = 1000;
    private static final Integer ERROR_LOG_MAX_LENGTH = 10000;

    public static Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        try {
            if (methodName.equals('validatePF')) {
                validatePF(inputMap, outMap, options);
                return true;
            } else {
                System.debug('El nombre del método no es correcto');
                return false;
            }
        } catch (Exception e) {
            System.debug(
                'Error Invoke Method:: ' +
                    e.getMessage() +
                    ' en la linea:: ' +
                    e.getLineNumber()
            );
            return false;
        }
    }
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');
        return invokeMethod(action, input, output, options);
    }

    private static void validatePF(
        Map<String, Object> inputMap,
        Map<String, Object> outMap,
        Map<String, Object> options
    ) {
        HttpRequest request;
        HttpResponse response;
        Id solicitudDeCreditoRecordId;
        Boolean apiExecuted = false;
        Boolean responseReceived = false;
        String stage = 'PREPARATION';
        String failureMessage;

        initializeOutput(outMap);

        try {
            String accountId = getInputValue(inputMap, 'accountId');
            String solicitudDeCreditoId = getInputValue(inputMap, 'solicitudDeCreditoId');
            solicitudDeCreditoRecordId = String.isBlank(solicitudDeCreditoId) ? null : Id.valueOf(solicitudDeCreditoId);
            if (String.isBlank(accountId)) {
                throw new ListValidationException('No se recibió el accountId requerido.');
            }

            List<StaticResource> srList = [SELECT Id, Name, Body FROM StaticResource WHERE Name = 'INT003_request_frame'];
            List<AuthSession> authList = [
                SELECT Id, SourceIP
                FROM AuthSession
                WHERE UsersId = :UserInfo.getUserId()
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (srList.isEmpty()) {
                throw new ListValidationException('No existe el recurso estático INT003_request_frame.');
            }
            if (authList.isEmpty()) {
                throw new ListValidationException('No se encontró una sesión activa para obtener la terminal.');
            }

            List<String> fields = new List<String>(Account.SObjectType.getDescribe().fields.getMap().keySet());
            String soql = 'SELECT ' + String.join(fields, ',') +
                ' FROM Account WHERE Id = \'' + String.escapeSingleQuotes(accountId) + '\'';
            Account client = Database.query(soql);

            request = new HttpRequest();
            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
            request.setHeader('SoapAction', 'http://crmintegration.local/ValidaListasControl');

            String frame = srList[0].Body.toString();
            frame = frame.replace('[ws_user]', Label.Int_Username);
            frame = frame.replace('[ws_password]', Label.Int_Password);
            frame = frame.replace('[function_username]', UserInfo.getUserName());
            frame = frame.replace('[function_requestdate]', System.now().format('dd/MM/yyyy'));
            frame = frame.replace('[function_requesttime]', System.now().format('hh:mm:ss'));
            frame = frame.replace('[function_terminal]', authList[0].SourceIp);
            frame = INT003.fillXML(new INT003.Response(), client, frame);
            request.setBody(frame);

            // Solo se marca ejecutada cuando comienza el intento HTTP.
            stage = 'CALLOUT';
            apiExecuted = true;
            response = new Http().send(request);
            responseReceived = true;
            outMap.put('httpStatusCode', response.getStatusCode());
            outMap.put('httpStatus', response.getStatus());

            stage = 'HTTP_RESPONSE';
            if (response.getStatusCode() != 200) {
                throw new ListValidationException('HTTP ' + response.getStatusCode() + ' - ' + response.getStatus());
            }

            stage = 'BUSINESS_RESPONSE';
            INT003.Response responseServer = INT003.parse(response.getBody());
            outMap.put('businessErrorCode', responseServer.errorCode);
            outMap.put('businessErrorText', responseServer.errorText);
            if (responseServer.errorCode != '000') {
                throw new ListValidationException(
                    'El servicio respondió ' + responseServer.errorCode + ': ' + responseServer.errorText
                );
            }
            String coincidenciaLI = getResponseValue(responseServer, 'CoincidenciaLI');
            String coincidenciaLE = getResponseValue(responseServer, 'CoincidenciaLE');
            String listas = getResponseValue(responseServer, 'Listas');
            if (coincidenciaLI == null || coincidenciaLE == null) {
                throw new ListValidationException('La respuesta no contiene los indicadores de coincidencia esperados.');
            }

            stage = 'UPDATE_RECORDS';
            INT003.updateAccount(responseServer, accountId);
            if (solicitudDeCreditoRecordId != null) {
                INT003.updateLoan(responseServer, solicitudDeCreditoRecordId);
            }

            stage = 'COMPLETED';
            outMap.put('success', true);
            outMap.put('stage', stage);
            outMap.put('message', 'Validación de listas completada correctamente.');
            outMap.put('coincidenciaLE', coincidenciaLE == 'Y');
            outMap.put('coincidenciaLI', coincidenciaLI == 'Y');
            outMap.put('coincidenciaLista', !String.isBlank(listas));
        } catch (Exception e) {
            failureMessage = buildFailureMessage(stage, e);
            outMap.put('success', false);
            outMap.put('stage', stage);
            outMap.put('message', failureMessage);
            outMap.put('errorMessage', failureMessage);
            outMap.put('errorLine', e.getLineNumber());
        } finally {
            outMap.put('apiExecuted', apiExecuted);
            outMap.put('responseReceived', responseReceived);
            if (apiExecuted) {
                // También deja respuesta de log cuando el servicio no responde.
                INTLogger.INTLoggerResult logResult = response == null
                    ? INTLogger.logCalloutError(INTEGRATION_CODE, INTEGRATION_FUNCTION, request, failureMessage)
                    : INTLogger.logCallout(INTEGRATION_CODE, INTEGRATION_FUNCTION, request, response);
                outMap.put('integrationLogSaved', logResult.success);
                outMap.put('requestLogId', logResult.requestId);
                outMap.put('responseLogId', logResult.responseId);
                if (!logResult.success) {
                    outMap.put('warning', 'La API fue ejecutada, pero no se pudo guardar el log: ' + logResult.message);
                }
            }
        }

        if (!String.isBlank(failureMessage) && solicitudDeCreditoRecordId != null) {
            outMap.put('rlaErrorSaved', saveRlaError(solicitudDeCreditoRecordId, failureMessage));
        }
    }

    private static void initializeOutput(Map<String, Object> outMap) {
        outMap.put('success', false);
        outMap.put('apiExecuted', false);
        outMap.put('responseReceived', false);
        outMap.put('integrationLogSaved', false);
        outMap.put('rlaErrorSaved', false);
    }

    private static String getInputValue(Map<String, Object> inputMap, String key) {
        Object value = inputMap == null ? null : inputMap.get(key);
        return value == null ? null : String.valueOf(value);
    }

    private static String getResponseValue(INT003.Response response, String key) {
        Object value = response == null ? null : response.values.get(key);
        return value == null ? null : String.valueOf(value);
    }

    private static String buildFailureMessage(String stage, Exception error) {
        String state;
        switch on stage {
            when 'CALLOUT' {
                state = 'API ejecutada sin respuesta';
            }
            when 'HTTP_RESPONSE' {
                state = 'API ejecutada con respuesta HTTP fallida';
            }
            when 'BUSINESS_RESPONSE' {
                state = 'API ejecutada con respuesta funcional fallida';
            }
            when 'UPDATE_RECORDS' {
                state = 'API exitosa, pero falló la actualización de Salesforce';
            }
            when else {
                state = 'API no ejecutada';
            }
        }
        return state + ': ' + error.getMessage();
    }

    private static Boolean saveRlaError(Id rlaId, String message) {
        try {
            ResidentialLoanApplication currentRla = [
                SELECT Id, FSC_LogErrores__c
                FROM ResidentialLoanApplication
                WHERE Id = :rlaId
                LIMIT 1
            ];
            String entry = Datetime.now().format('yyyy-MM-dd HH:mm:ss') + ' | Validación listas | ' + message;
            String combinedLog = String.isBlank(currentRla.FSC_LogErrores__c)
                ? entry
                : currentRla.FSC_LogErrores__c + ERROR_LOG_SEPARATOR + entry;

            update new ResidentialLoanApplication(
                Id = rlaId,
                FSC_ErrorValidacionListas__c = truncate(message, ERROR_FIELD_MAX_LENGTH),
                FSC_LogErrores__c = truncateFromEnd(combinedLog, ERROR_LOG_MAX_LENGTH)
            );
            return true;
        } catch (Exception logError) {
            System.debug('No se pudo guardar el error de validación de listas: ' + logError.getMessage());
            return false;
        }
    }

    private static String truncate(String value, Integer maxLength) {
        return value != null && value.length() > maxLength ? value.substring(0, maxLength) : value;
    }

    private static String truncateFromEnd(String value, Integer maxLength) {
        return value != null && value.length() > maxLength
            ? value.substring(value.length() - maxLength)
            : value;
    }

    private class ListValidationException extends Exception {}
}