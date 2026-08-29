/**
 * Name: TCP_PrequalificationService
 * Description:
 *  Servicio de precalificación TC. Hoy funciona en modo MOCK (sin callout real).
 *  Cuando exista la API, se sustituye la sección "REAL CALLOUT (COMMENTED)" con Http POST.
 *
 * Output esperado:
 *  - Dictamen: "Aprobado" | "Rechazado" | "Referido"
 *
 * Last modified: 2026-02-16
 */
public with sharing class TCP_PrequalificationService {

    public class Input {
        // Account / Persona
        public String numIdentificacion;      // id
        public String tipoIdentificacion;     // type (C/R/T/PL/CH)
        public Decimal salario;               // salario
        public Decimal tiempoLaborando;       // tiempoLaborando (meses)
        public Integer tipoCliente;           // 1=Asalariado, 2=Independiente
        public Decimal tasaCambio;            // tasaCambio
        public String clasificacionSIB;       // clasificacionSIB

    }

    public class Result {
        public String dictamen;      // Aprobado | Rechazado | Referido
        public Integer statusCode;
        public String rawResponse;
        public String message;
        public String correlationId;

        public Integer xcore;
        public Decimal limiteSugeridoDop;
        public Decimal limiteSugeridoUsd;
        public String transactionId;
        public List<String> mensajes;         
    }

    public class TCPPrequalException extends Exception {}
    public class TCPGenericException extends Exception {}

    @TestVisible private static Boolean TEST_THROW_TCPPREQUAL = false;
    @TestVisible private static Boolean TEST_THROW_GENERIC = false;

    // Public API
    public static Result prequalifyTCP(Input input) {
        System.debug('>>> TCP_PrequalificationService.prequalifyTCP. input=' + JSON.serialize(input));

        Result res = new Result();
        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(Label.EndpointTCP);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(20000);
        
        // Request base para log, incluso si falla validateInput
        req.setBody(JSON.serialize(input));

        try {
            if (Test.isRunningTest()) {
                if (TEST_THROW_TCPPREQUAL == true) {
                    throw new TCPPrequalException('TEST TCPPrequalException');
                }
                if (TEST_THROW_GENERIC == true) {
                    throw new TCPGenericException('TEST Generic Exception');
                }
            }
            
            validateInput(input);

            // Request con contrato
            Map<String, Object> requestBody = buildRequestBodyV2(input);
            String requestJson = JSON.serialize(requestBody);
            System.debug('>>> TCP_PrequalificationService requestJson=' + requestJson);
            
            // Reemplaza el body simple por el request real
            req.setBody(requestJson);
            
            Http http = new Http();
            HttpResponse httpRes = http.send(req);
 
            res.statusCode = httpRes.getStatusCode();
            res.rawResponse = httpRes.getBody();
            System.debug('>>> RESPONSE = ' + JSON.serializePretty(JSON.deserializeUntyped(httpRes.getBody())));

            res = parseResponseToResult(httpRes.getBody());
            res.statusCode = httpRes.getStatusCode(); 

            // Asegura dictamen siempre y normalizado
            if (res == null) res = new Result();
            res.dictamen = normalizeDictamen(res.dictamen);
            
            if (String.isBlank(res.message)) res.message = 'Response parsed successfully';
            return res;
            
        } catch (TCPPrequalException e) {
            System.debug(LoggingLevel.WARN, '>>> Validation error (TCPPrequalException): ' + e.getMessage());
            res.dictamen = 'Referido';
            res.statusCode = 0;
            res.message = 'Validation: ' + e.getMessage();
            return res;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '>>> Error in prequalifyTCP: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());

            res.dictamen = 'Referido';
            res.statusCode = 0;
            res.message = 'Exception: ' + e.getMessage();
            return res;
        } finally {
            HttpResponse httpResToLog = new HttpResponse();
        
            Integer statusToLog = res != null && res.statusCode != null ? res.statusCode : 0;
            httpResToLog.setStatusCode(statusToLog);
        
            Boolean hasError =
                res == null ||
                statusToLog < 200 ||
                statusToLog >= 300 ||
                !String.isBlank(res.message) &&
                (
                    res.message.startsWith('Validation:') ||
                    res.message.startsWith('Exception:')
                );
        
            if (hasError) {
                httpResToLog.setBody(buildErrorLogBody(input, res));
            } else {
                httpResToLog.setBody(buildFilteredLogBody(input, res));
            }

            try {
                INTLogger.INTLoggerResult result = INTLogger.logCallout('TCP', 'prequalifyTCP', req, httpResToLog);
            } catch (Exception logEx) {
                System.debug(LoggingLevel.ERROR, '>>> Error INTLogger TCP: ' + logEx.getMessage());
                System.debug(LoggingLevel.ERROR, logEx.getStackTraceString());
            }
        }
    }

    // Helpers
    private static void validateInput(Input input) {
        System.debug('>>> on TCP_PrequalificationService.validateInput');

        if (input == null) throw new TCPPrequalException('Input is null');

        //se valida lo que exige el contrato:
        if (String.isBlank(input.numIdentificacion))
            throw new TCPPrequalException('numIdentificacion (id) is required');

        if (String.isBlank(input.tipoIdentificacion))
            throw new TCPPrequalException('tipoIdentificacion (type) is required');

        if (input.salario == null)
            throw new TCPPrequalException('salario is required');

        if (input.tiempoLaborando == null)
            throw new TCPPrequalException('tiempoLaborando is required');

        if (input.tipoCliente == null)
            throw new TCPPrequalException('tipoCliente is required');

        if (input.tasaCambio == null)
            throw new TCPPrequalException('tasaCambio is required');
    }

    // Armado de Request --> {"applicants":{"primaryConsumer":{"personalInformation":{...}}}}
    private static Map<String, Object> buildRequestBodyV2(Input input) {
        System.debug('>>> on TCP_PrequalificationService.buildRequestBodyV2');

        String tipoCode = normalizeTipoIdentificacion(input.tipoIdentificacion);
        system.debug('tipo de Identificacion del input: '+input.tipoIdentificacion + 'codigo: '+tipoCode);
        Map<String, Object> personalInformation = new Map<String, Object>{
            'id'              => input.numIdentificacion,
            'type'            => tipoCode,                         //tipo de identificación: C=Cédula, R=RNC, T=Teléfono
            'salario'         => String.valueOf(input.salario),           
            'tiempoLaborando' => String.valueOf(input.tiempoLaborando),  
            'tipoCliente'     => input.tipoCliente,
            'tasaCambio'      => input.tasaCambio,
            'clasificacionSIB'=> (input.clasificacionSIB == null) ? '' : input.clasificacionSIB
        };

       
        return new Map<String, Object>{
            'applicants' => new Map<String, Object>{
                'primaryConsumer' => new Map<String, Object>{
                    'personalInformation' => personalInformation
                }
            }
        };
        
    }

    // Parse del response: toma Filtro_BcoVimencaTcr.Generales.{dictamen,xcore,limites,mensajes}
    private static Result parseResponseToResult(String responseJson) {
        System.debug('>>> on TCP_PrequalificationService.parseResponseToResult');

        Result res = new Result();
        res.mensajes = new List<String>();

        if (String.isBlank(responseJson)) {
            res.dictamen = 'Referido';
            res.message = 'Empty responseJson';
            return res;
        }

        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(responseJson);

        Map<String, Object> applicants = (Map<String, Object>) root.get('applicants');
        Map<String, Object> primaryConsumer = (applicants != null) ? (Map<String, Object>) applicants.get('primaryConsumer') : null;
        Map<String, Object> interconnectResponse = (primaryConsumer != null) ? (Map<String, Object>) primaryConsumer.get('interconnectResponse') : null;
        Map<String, Object> filtro = (interconnectResponse != null) ? (Map<String, Object>) interconnectResponse.get('Filtro_BcoVimencaTcr') : null;
        Map<String, Object> generales = (filtro != null) ? (Map<String, Object>) filtro.get('Generales') : null;

        if (generales == null) {
            res.dictamen = 'Referido';
            res.message = 'Nodo Filtro_BcoVimencaTcr.Generales no encontrado';
            return res;
        }

        // dictamen
        String dictamen = String.valueOf(generales.get('dictamen'));
        res.dictamen = String.isBlank(dictamen) ? 'Referido' : dictamen;

        // xcore
        Object xcoreObj = generales.get('xcore');
        if (xcoreObj != null) {
            try { res.xcore = Integer.valueOf(String.valueOf(xcoreObj)); } catch (Exception ignore) {}
        }

        // limites
        Object dopObj = generales.get('limite_sugerido_dop');
        if (dopObj != null) {
            try { res.limiteSugeridoDop = Decimal.valueOf(String.valueOf(dopObj)); } catch (Exception ignore) {}
        }

        Object usdObj = generales.get('limite_sugerido_usd');
        if (usdObj != null) {
            try { res.limiteSugeridoUsd = Decimal.valueOf(String.valueOf(usdObj)); } catch (Exception ignore) {}
        }

        // mensajes.evaluacion[]
        Map<String, Object> mensajesNode = (Map<String, Object>) generales.get('mensajes');
        if (mensajesNode != null && mensajesNode.containsKey('evaluacion')) {
            List<Object> evalList = (List<Object>) mensajesNode.get('evaluacion');
            if (evalList != null) {
                for (Object o : evalList) {
                    Map<String,Object> msg = (Map<String,Object>) o;
                    if (msg != null && msg.containsKey('description')) {
                        res.mensajes.add(String.valueOf(msg.get('description')));
                    }
                }
            }
        }
        //TransactionId
        Object transactionObj = root.get('transactionId');
        if (transactionObj != null) {
            try { res.transactionId = String.valueOf(transactionObj); } catch (Exception ignore) {}
        }

        return res;
    }
    private static String normalizeDictamen(String dictamen) {
        String d = (dictamen == null) ? '' : dictamen.trim();
        if (d == 'Aprobado' || d == 'Rechazado' || d == 'Referido') {
            return d;
        }
        return 'Referido';
    }
    
    private static String buildFilteredLogBody(Input input, Result res) {
        Map<String, Object> logMap = new Map<String, Object>();
    
        logMap.put('Xcore', res != null ? res.xcore : null);
        logMap.put('Dictamen', res != null ? res.dictamen : null);
        logMap.put(
            'MensajeRespuesta',
            (res != null && res.mensajes != null && !res.mensajes.isEmpty())
                ? String.join(res.mensajes, ' | ')
                : null
        );
        logMap.put('LimiteSugeridoUSD', res != null ? res.limiteSugeridoUsd : null);
        logMap.put('LimiteSugeridoDOP', res != null ? res.limiteSugeridoDop : null);
        logMap.put('TransactionId', res != null ? res.transactionId : null);
    
        return JSON.serialize(logMap);
    }
    private static String buildErrorLogBody(Input input, Result res) {
        Map<String, Object> logMap = new Map<String, Object>();
    
        logMap.put('success', false);
        logMap.put('statusCode', res != null ? res.statusCode : null);
        logMap.put('dictamen', res != null ? res.dictamen : 'Referido');
        logMap.put('message', res != null ? res.message : null);
        logMap.put('rawResponse', res != null ? res.rawResponse : null);
        logMap.put('transactionId', res != null ? res.transactionId : null);
        logMap.put('correlationId', res != null ? res.correlationId : null);
    
        logMap.put('numIdentificacion', input != null ? input.numIdentificacion : null);
        logMap.put('tipoIdentificacion', input != null ? input.tipoIdentificacion : null);
    
        return JSON.serialize(logMap);
    }
    
    private static String normalizeTipoIdentificacion(String tipo) {
        if (String.isBlank(tipo)) return '';
    
        String t = tipo.trim().toLowerCase();
    
        // si ya viene como código
        if (t == 'C' || t == 'R' || t == 'T' || t == 'PL' || t == 'CH') return t.toUpperCase();
    
        // mapeos por label
        if (t.contains('cédula') || t.contains('cedula')) return 'C';
        if (t.contains('rnc')) return 'R';
        if (t.contains('pasaporte')) return 'P';
        if (t.contains('teléfono')) return 'T';
        if (t.contains('placa')) return 'PL';
        if (t.contains('chasis')) return 'CH';
    	system.debug('normalizeTipoIdentificacion: '+t);
        return ''; // desconocido
    }
}