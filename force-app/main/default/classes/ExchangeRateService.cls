/**
 * Name: c
 * Description:
 *
 * Reglas:
 *  - Lee endpoint desde Custom Label (EndpointExchangeRate)
 *  - Retorna SOLO TasaCambio (Decimal)
 *  - Si TasaCambio viene null/blank, o hay error -> retorna 0
 *
 * Last modified: 2026-03-02
 */
public with sharing class ExchangeRateService {
    public static HttpRequest lastRequestToLog;
	public static HttpResponse lastResponseToLog;

    public class ExchangeRateResponse {
        public String TasaCambio;
    }
    public static Decimal getTasaCambio(Integer currencyCode) {
        Decimal tasa = 0;
		HttpRequest req = new HttpRequest();
        HttpRequest reqToLog = new HttpRequest();
        HttpResponse res = new HttpResponse();
        HttpResponse resToLog = new HttpResponse();
        
        try {
            if (currencyCode == null) {
                return 0;
            }

            String baseEndpoint = Label.EndpointExchangeRate;
            if (String.isBlank(baseEndpoint)) {
                System.debug(LoggingLevel.WARN, 'Label.EndpointExchangeRate está en blanco. Devuelve 0.');
                return 0;
            }

            String endpoint = baseEndpoint;
            // Asegura que el endpoint no venga con espacios
            endpoint = endpoint.trim();

            // Arma querystring
            endpoint += (endpoint.contains('?') ? '&' : '?') + 'currencyCode=' + String.valueOf(currencyCode);

            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(20000);

            System.debug('ExchangeRateService REQUEST-endpoint=' + endpoint);

            Http http = new Http();
            res = http.send(req);
            
            // Request artificial solo para INTLogger
            reqToLog.setEndpoint(endpoint);
            reqToLog.setMethod('GET');
            reqToLog.setHeader('Content-Type', 'application/json');
            reqToLog.setBody(JSON.serialize(new Map<String, Object>{
                'currencyCode' => currencyCode,
                'endpoint' => endpoint,
                'method' => 'GET'
            }));
            
            // Response artificial enriquecido para INTLogger
            resToLog.setStatusCode(res.getStatusCode());
            resToLog.setBody(JSON.serialize(new Map<String, Object>{
                'statusCode' => res.getStatusCode(),
                'status' => res.getStatus(),
                'body' => res.getBody()
            }));
            
            lastRequestToLog = reqToLog;
            lastResponseToLog = resToLog;
             //FIN Response artificial enriquecido para INTLogger

            Integer sc = res != null ? res.getStatusCode() : null;
            String body = res != null ? res.getBody() : null;

            System.debug('ExchangeRateService RESPONSE statusCode=' + sc);
            System.debug('ExchangeRateService RESPONSE respuesta =' + res);

            if (sc == null || sc < 200 || sc >= 300 || String.isBlank(body)) {
                System.debug(LoggingLevel.WARN, 'Non-2xx or empty body. Returning 0.');
                return 0;
            }

            // Parse mínimo
            ExchangeRateResponse parsed = (ExchangeRateResponse) JSON.deserialize(body, ExchangeRateResponse.class);

            String tasaStr = (parsed != null) ? parsed.TasaCambio : null;
            if (String.isBlank(tasaStr)) {
                System.debug(LoggingLevel.WARN, 'TasaCambio es nulo/en blanco. Devolviendo 0.');
                return 0;
            }
            

            try {
                tasa = Decimal.valueOf(tasaStr);
            } catch (Exception parseEx) {
                System.debug(LoggingLevel.WARN, 'Could not parse TasaCambio=' + tasaStr + '. Devolviendo 0. error=' + parseEx.getMessage());
                return 0;
            }

            System.debug('>>> ExchangeRateService tasaCambio parsed=' + tasa);
            return tasa;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '>>> ExchangeRateService.getTasaCambio ERROR: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, e.getStackTraceString());
            return 0;
        }
    }
}