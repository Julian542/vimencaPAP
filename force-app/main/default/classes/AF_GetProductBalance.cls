public with sharing class AF_GetProductBalance {

    @TestVisible
    private static INT013Agente.Response testCoreResponse;

    public class Request {
        @InvocableVariable(required=true)
        public String accountNumber;

        @InvocableVariable(required=true)
        public String productLine;

        @InvocableVariable(required=true)
        public String currencyCode;
    }

public class Response {

    @InvocableVariable
    public String status;

    @InvocableVariable
    public String errorCode;

    @InvocableVariable
    public String errorText;

    @InvocableVariable
    public Decimal balance;

    @InvocableVariable
    public String currencyCode;

    @InvocableVariable
    public Boolean hasBalance;
    @InvocableVariable
    public Decimal montoAdeudado;

    // TARJETAS DE CREDITO

    @InvocableVariable
    public Decimal saldoActualRD;

    @InvocableVariable
    public Decimal saldoDisponibleRD;

    @InvocableVariable
    public Decimal ultimoCorteRD;

    @InvocableVariable
    public Decimal pagoMinimoRD;

    @InvocableVariable
    public Decimal saldoActualUSD;

    @InvocableVariable
    public Decimal saldoDisponibleUSD;

    @InvocableVariable
    public String fechaCorte;
}

    @InvocableMethod(label='Consultar Balance Producto')
    public static List<Response> getBalance(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response r = new Response();
            r.hasBalance = false;
            r.status = 'ERROR';

            try {
                INT013Agente.Response coreResponse = testCoreResponse != null
                    ? testCoreResponse
                    : INT013Agente.getBalance(
                        req.accountNumber,
                        req.productLine,
                        req.currencyCode
                    );

                // Caso 1: no hubo respuesta del core
                if (coreResponse == null) {
                    r.status = 'NO_DATA';
                    r.errorCode = 'NO_RESPONSE';
                    r.errorText = 'No fue posible obtener información del producto.';
                    responses.add(r);
                    continue;
                }

                // Mapeo base
                r.errorCode = coreResponse.errorCode;
                r.errorText = coreResponse.errorText;
                r.balance = coreResponse.balance;
                r.currencyCode = coreResponse.currencyCode;
                //PRESTAMOS
                r.montoAdeudado =
                coreResponse.montoAdeudado;
                // TARJETA DE CREDITO

r.saldoActualRD =
    coreResponse.saldoActualRD;

r.saldoDisponibleRD =
    coreResponse.saldoDisponibleRD;

r.ultimoCorteRD =
    coreResponse.ultimoCorteRD;

r.pagoMinimoRD =
    coreResponse.pagoMinimoRD;

r.saldoActualUSD =
    coreResponse.saldoActualUSD;

r.saldoDisponibleUSD =
    coreResponse.saldoDisponibleUSD;

r.fechaCorte =
    coreResponse.fechaCorte;
                

                // Caso 2: respuesta con balance
                if (coreResponse.balance != null) {
                    r.status = 'SUCCESS';
                    r.hasBalance = true;
                }
                // Caso 3: respuesta sin balance, pero sin excepción técnica
                else {
                    r.status = 'NO_DATA';

                    if (String.isBlank(r.errorCode)) {
                        r.errorCode = 'NO_BALANCE_AVAILABLE';
                    }

                    if (String.isBlank(r.errorText)) {
                        r.errorText = 'No hay balance disponible para este producto en este canal.';
                    }
                }
            }
            catch (Exception e) {
                r.status = 'ERROR';
                r.errorCode = 'UNEXPECTED_ERROR';
                r.errorText = 'Ocurrió un inconveniente al consultar el balance.';
                System.debug(LoggingLevel.ERROR,
                    'AF_GetProductBalance error. accountNumber=' + (req == null ? null : req.accountNumber) +
                    ', productLine=' + (req == null ? null : req.productLine) +
                    ', currencyCode=' + (req == null ? null : req.currencyCode) +
                    ', detail=' + e.getMessage()
                );
            }

            responses.add(r);
        }

        return responses;
    }
}