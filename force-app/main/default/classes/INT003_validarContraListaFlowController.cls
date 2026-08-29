public class INT003_validarContraListaFlowController {
    
    @TestVisible private static Boolean useMock = false;
    @TestVisible private static INT003.Response mockResponse;
    @TestVisible private static Exception mockException;

    // -----------------------------
    //  Clases auxiliares para Flow
    // -----------------------------
    public class Request {
        @InvocableVariable(required=true)
        public Id accountId;
    }

    public class Result {
        @InvocableVariable public Boolean isPep;        
        @InvocableVariable public Boolean inInternalLists;
        @InvocableVariable public Boolean inExternalLists;        
        @InvocableVariable public Boolean hasError;        
        @InvocableVariable public String errorCode;        
        @InvocableVariable public String errorMessage;
        //@InvocableVariable public String tasaCambioLabel;
    }

    /**
     * Acción invocable para Flow:
     * - Hace el callout al servicio INT003 (sin @future).
     * - Reutiliza INT003.parse, INT003.fillXML y (cuando aplica) INT003.updateAccount.
     * - Devuelve flags para PEP, listas internas/externas y estado de error.
     */
    @InvocableMethod(
        label='Validar Listas de Control (INT003)'
        description='Consume INT003 para validar listas internas/externas y PEP. Actualiza la cuenta cuando la respuesta es válida y devuelve flags para Flow.'
        callout=true
    )
    public static List<Result> validarListas(List<Request> requests) {
		//final String tasaCambioLbl = System.Label.TasaCambio_CL;
        System.debug('INT003_validarContraListaFlowController.validarListas - input: ' + requests);

        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result out = new Result();
            results.add(out);

            if (req == null || req.accountId == null) {
                out.hasError     = true;
                out.errorCode    = 'FLOW-001';
                out.errorMessage = 'AccountId no informado en la invocación desde Flow.';
                continue;
            }

            try {
                INT003.Response intResp = callServiceINT003(req.accountId);
                System.debug('INT003_validarContraListaFlowController.validarListas - INT003.Response: ' + intResp);

                if (intResp == null) {
                    out.hasError     = true;
                    out.errorCode    = 'INT003-NULL';
                    out.errorMessage = 'El servicio INT003 no devolvió respuesta.';
                    continue;
                }

                out.errorCode    = intResp.errorCode;
                out.errorMessage = intResp.errorText;

                // Si el servicio respondió OK (código 000), interpretamos flags.
                if (intResp.errorCode == '000') {

                    // values puede venir null/empty dependiendo del parse
                    String coincidenciaLE = safeGetString(intResp, 'CoincidenciaLE');
                    String coincidenciaLI = safeGetString(intResp, 'CoincidenciaLI');
                    String listas         = safeGetString(intResp, 'Listas');

                    out.inExternalLists = (coincidenciaLE == 'Y');
                    out.inInternalLists = (coincidenciaLI == 'Y');

                    Boolean pepDetectado = false;
                    if (out.inExternalLists && !String.isBlank(listas)) {
                        pepDetectado = listas.toUpperCase().contains('PEPS');
                    }

                    out.isPep    = pepDetectado;
                    out.hasError = false;

                } else {
                    // El servicio respondió con error distinto de 000.
                    out.hasError = true;
                }

            } catch (Exception e) {
                out.hasError     = true;
                out.errorCode    = 'EXCEPTION';
                out.errorMessage = 'Excepción al invocar INT003: ' + e.getMessage();
            }
			//out.tasaCambioLabel = tasaCambioLbl;
            System.debug('INT003_validarContraListaFlowController.validarListas - out: ' + out);
        }
        System.debug('INT003_validarContraListaFlowController.validarListas - results: ' + results);
        return results;
    }

    /**
     * Helper: lectura segura de un value del mapa values, evitando NPE.
     */
    private static String safeGetString(INT003.Response resp, String key) {
        if (resp == null || String.isBlank(key) || resp.values == null) return null;
        if (!resp.values.containsKey(key)) return null;
        Object v = resp.values.get(key);
        return (v == null) ? null : String.valueOf(v);
    }

    /**
     * Hace el mismo callout que INT003.validatePF, pero de forma síncrona
     * (para poder usarlo desde Flow sin @future).
     * Reutiliza:
     *  - INT003.fillXML
     *  - INT003.parse
     *  - INT003.updateAccount (solo si la respuesta es OK y trae datos)
     */
    private static INT003.Response callServiceINT003(Id accountId) {

        System.debug('INT003_validarContraListaFlowController.callServiceINT003 - accountId: ' + accountId);
        if (Test.isRunningTest() && useMock) {
            if (mockException != null) {
                throw mockException;
            }
            return mockResponse;
        }

        // Recupera el Static Resource con el frame XML
        List<StaticResource> srList = [
            SELECT Id, Name, Body
            FROM StaticResource
            WHERE Name = 'INT003_request_frame'
            LIMIT 1
        ];

        if (srList.isEmpty()) {
            throw new XmlException('No se encontró el Static Resource "INT003_request_frame".');
        }

        // Última sesión de login para obtener la IP (terminal)
        List<AuthSession> authList = [
            SELECT Id, SourceIp, Users.Name, LoginType, NumSecondsValid, CreatedDate
            FROM AuthSession
            WHERE UsersId = :UserInfo.getUserId()
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        // Armamos el SOQL dinámico igual que en INT003.validatePF
        List<String> fields = new List<String>(Account.SObjectType.getDescribe().fields.getMap().keySet());
        String soql = 'SELECT ' + String.join(fields, ',') +
                      ' FROM Account' +
                      ' WHERE Id = \'' + String.escapeSingleQuotes(String.valueOf(accountId)) + '\'';
        Account client = Database.query(soql);

        HttpRequest request = new HttpRequest();
        HttpResponse res;
        Http http = new Http();

        INT003.Response responseServer = new INT003.Response();

        String frame = srList[0].Body.toString();

        // Config básica del request
        request.setEndpoint(Label.EndpointWs);
        request.setMethod('POST');
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        request.setHeader('SoapAction', 'http://crmintegration.local/ValidaListasControl');

        // Credenciales del WS
        frame = frame.replace('[ws_user]', Label.Int_Username);
        frame = frame.replace('[ws_password]', Label.Int_Password);

        // Parámetros de la llamada
        frame = frame.replace('[function_username]', UserInfo.getUserName());
        frame = frame.replace('[function_requestdate]', System.now().format('dd/MM/yyyy'));
        frame = frame.replace('[function_requesttime]', System.now().format('HH:mm:ss'));

        String sourceIp = authList.isEmpty() ? '' : authList[0].SourceIp;
        frame = frame.replace('[function_terminal]', sourceIp);

        // Detalle del cliente (usa lógica de INT003)
        frame = INT003.fillXML(responseServer, client, frame);

        request.setBody(frame);
        System.debug('INT003_validarContraListaFlowController.callServiceINT003 - request: ' + request);

        try {
            res = http.send(request);
            System.debug('INT003_validarContraListaFlowController.callServiceINT003 - response: ' + res);

            if (res == null) {
                throw new CalloutException('La respuesta HTTP de INT003 fue nula.');
            }

            responseServer.requestStatusCode = res.getStatusCode();
            responseServer.requestStatus     = res.getStatus();

            if (res.getStatusCode() == 200) {

                // Parseamos la respuesta
                responseServer = INT003.parse(res.getBody());

                // Asegurar que se preserve status HTTP en el response retornado
                responseServer.requestStatusCode = res.getStatusCode();
                responseServer.requestStatus     = res.getStatus();

                System.debug('INT003_validarContraListaFlowController.callServiceINT003 - responseServer parsed: ' + responseServer);

                // ------------------------------------------------------------
                // SOLO ACTUALIZA SI VIENE OK (000) Y HAY DATA UTIL
                // ------------------------------------------------------------
                if (responseServer != null && responseServer.errorCode == '000') {

                    // Validación defensiva: requerimos CoincidenciaLE/LI para que updateAccount no truene
                    String coincidenciaLE = safeGetString(responseServer, 'CoincidenciaLE');
                    String coincidenciaLI = safeGetString(responseServer, 'CoincidenciaLI');

                    if (!String.isBlank(coincidenciaLE) && !String.isBlank(coincidenciaLI)) {
                        System.debug('INT003.updateAccount - OK para actualizar. LE=' + coincidenciaLE + ' LI=' + coincidenciaLI);
                        INT003.updateAccount(responseServer, accountId);
                    } else {
                        System.debug('INT003.updateAccount - OMITIDO: faltan CoincidenciaLE/LI en values (evitar NPE). values=' + responseServer.values);
                    }

                } else {
                    // Error de negocio: 9999 u otro => NO actualizar
                    System.debug('INT003.updateAccount - OMITIDO: errorCode=' + (responseServer == null ? null : responseServer.errorCode) +
                                 ', errorText=' + (responseServer == null ? null : responseServer.errorText));
                }

            } else {
                // HTTP distinto de 200: construir un error controlado en Response
                if (responseServer == null) responseServer = new INT003.Response();

                responseServer.errorCode = 'HTTP-' + String.valueOf(res.getStatusCode());
                responseServer.errorText = 'INT003 devolvió HTTP ' + res.getStatusCode() + ' - ' + res.getStatus();
            }

            // Log de integración igual que en INT003
            INTLogger.INTLoggerResult resultLog =
                INTLogger.logCallout('003', 'ValidaListasControl', request, res);

        } catch (Exception e) {
            System.debug('INT003_validarContraListaFlowController.callServiceINT003 - EXCEPTION: ' + e.getMessage() + ' | ' + e.getStackTraceString());
            throw e;
        }

        System.debug('INT003_validarContraListaFlowController.callServiceINT003 - return responseServer: ' + responseServer);
        return responseServer;
    }
}