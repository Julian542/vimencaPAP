public with sharing class INT013Agente {

public class Response {

    @AuraEnabled public Decimal balance;
    @AuraEnabled public String currencyCode;
    @AuraEnabled public String errorCode;
    @AuraEnabled public String errorText;
    // PRESTAMOS
    @AuraEnabled public Decimal montoAdeudado;

    // TARJETAS DE CREDITO
    @AuraEnabled public Decimal saldoActualRD;
    @AuraEnabled public Decimal saldoDisponibleRD;
    @AuraEnabled public Decimal ultimoCorteRD;
    @AuraEnabled public Decimal pagoMinimoRD;

    @AuraEnabled public Decimal saldoActualUSD;
    @AuraEnabled public Decimal saldoDisponibleUSD;

    @AuraEnabled public String fechaCorte;
}

    private static Map<String, String> functionsXML = new Map<String, String>{
        'cuentas de ahorro' => 'ConsultaCAhorro',
        'cuentas corrientes' => 'ConsultaCCorriente',
        'certificados financieros' => 'ConsultaCertFin',
        'lineas de credito' => 'ConsultaLineaCred',
        'prestamos' => 'ConsultaPrestamo',
        'tarjetas de credito' => 'ConsultaTC',
        'tarjetas prepago' => 'ConsultaPrepago'
    };

    public static Response getBalance(
        String accountNumber,
        String productLine,
        String currencyCode
    ){

        Response r = new Response();

        try {

            if(String.isBlank(accountNumber)){
                throw new IllegalArgumentException(
                    'accountNumber no puede ser vacío'
                );
            }

            if(String.isBlank(productLine)){
                throw new IllegalArgumentException(
                    'productLine no puede ser vacío'
                );
            }

            if(String.isBlank(currencyCode)){
                throw new IllegalArgumentException(
                    'currencyCode no puede ser vacío'
                );
            }

            String normalizedProductLine =
                normalizeText(productLine);

            System.debug('ACCOUNT → ' + accountNumber);
            System.debug('PRODUCT LINE → ' + normalizedProductLine);
System.debug(
    'PRODUCT LINE ORIGINAL -> [' +
    productLine + ']'
);

System.debug(
    'PRODUCT LINE NORMALIZED -> [' +
    normalizedProductLine + ']'
);
            String functionName =
                functionsXML.get(normalizedProductLine);

            if(functionName == null){
                throw new IllegalArgumentException(
                    'Tipo de producto no soportado: ' + productLine
                );
            }

            // ============================================
            // HTTP
            // ============================================

            HttpRequest request = new HttpRequest();

            request.setEndpoint(Label.EndpointWs);
            request.setMethod('POST');
            request.setTimeout(120000);

            request.setHeader(
                'Content-Type',
                'text/xml;charset=UTF-8'
            );

            request.setHeader(
                'SoapAction',
                'http://crmintegration.local/' + functionName
            );

            // ============================================
            // XML
            // ============================================

            StaticResource sr = [
                SELECT Body
                FROM StaticResource
                WHERE Name = 'INT013_request_frame'
                LIMIT 1
            ];

            String frame = sr.Body.toString();

            frame = frame.replace(
                '[ws_user]',
                Label.Int_Username
            );

            frame = frame.replace(
                '[ws_password]',
                Label.Int_Password
            );

            frame = frame.replace(
                '[function_processIntegration]',
                functionName
            );

            frame = frame.replace(
                '[function_username]',
                UserInfo.getUserName()
            );

            frame = frame.replace(
                '[function_requestdate]',
                System.now().format('dd/MM/yyyy')
            );

            frame = frame.replace(
                '[function_requesttime]',
                System.now().format('hh:mm:ss')
            );

            frame = frame.replace(
                '[function_terminal]',
                'AGENTE'
            );

            frame = frame.replace(
                '[function_accountnumber]',
                accountNumber
            );

            frame = frame.replace(
                '[function_productline]',
               productLine.trim()
            );

            frame = frame.replace(
                '[function_currency]',
                currencyCode
            );

            request.setBody(frame);

            System.debug('==============================');
            System.debug('FUNCTION NAME -> ' + functionName);
            System.debug('REQUEST XML -> ' + frame);
            System.debug('==============================');

            Http http = new Http();

            HttpResponse res = http.send(request);

if(res.getStatusCode() == 200){

    String responseBody = res.getBody();

    System.debug('XML COMPLETO -> ' + responseBody);

    Integer chunkSize = 1000;

    for(Integer i = 0; i < responseBody.length(); i += chunkSize){
        System.debug(
            'XML PART → ' +
            responseBody.substring(
                i,
                Math.min(i + chunkSize, responseBody.length())
            )
        );
    }

                for(
                    Integer i = 0;
                    i < responseBody.length();
                    i += chunkSize
                ){
                    System.debug(
                        'XML PART → ' +
                        responseBody.substring(
                            i,
                            Math.min(
                                i + chunkSize,
                                responseBody.length()
                            )
                        )
                    );
                }

                // ============================================
                // MAP UNIFICADO
                // ============================================

                Map<String,String> detalle =
                    new Map<String,String>();

                // ============================================
                // DTO SEGÚN PRODUCTO
                // ============================================

                if(normalizedProductLine == 'cuentas de ahorro'){

                    INT013CADTO dto = new INT013CADTO();

                    dto.parse(responseBody);

                    r.errorCode = dto.result.ErrorCode;
                    r.errorText = dto.result.ErrorText;

                    if(dto.Producto != null &&
                       dto.Producto.values != null){

                        detalle.putAll(dto.Producto.values);
                    }

                    if(dto.Detalle != null &&
                       dto.Detalle.values != null){

                        detalle.putAll(dto.Detalle.values);
                    }

                }
                else if(
                    normalizedProductLine ==
                    'cuentas corrientes'
                ){

                    INT013CCDTO dto = new INT013CCDTO();

                    dto.parse(responseBody);

                    r.errorCode = dto.result.ErrorCode;
                    r.errorText = dto.result.ErrorText;

                    if(dto.Producto != null &&
                       dto.Producto.values != null){

                        detalle.putAll(dto.Producto.values);
                    }

                    if(dto.Detalle != null &&
                       dto.Detalle.values != null){

                        detalle.putAll(dto.Detalle.values);
                    }

                }
                    else if(
                       normalizedProductLine == 'prestamos'
                      ){

                    INT013PRDTO dto = new INT013PRDTO();

                    dto.parse(responseBody);

                    r.errorCode = dto.result.ErrorCode;
                    r.errorText = dto.result.ErrorText;

                    if(dto.Producto != null &&
                       dto.Producto.values != null){

                        detalle.putAll(dto.Producto.values);
                    }

                    if(dto.Detalle != null &&
                       dto.Detalle.values != null){

                        detalle.putAll(dto.Detalle.values);
                    }

                }
                else if(
                    normalizedProductLine ==
                    'tarjetas de credito'
                ){

                    INT013TCDTO dto = new INT013TCDTO();

                    dto.parse(responseBody);

                    r.errorCode = dto.result.ErrorCode;
                    r.errorText = dto.result.ErrorText;

                    if(dto.Producto != null &&
                       dto.Producto.values != null){

                        detalle.putAll(dto.Producto.values);
                    }

                    if(dto.Detalle != null &&
                       dto.Detalle.values != null){

                        detalle.putAll(dto.Detalle.values);
                    }
// ============================================
// CAMPOS PRESTAMOS
// ============================================

if(normalizedProductLine == 'prestamos'){

    r.montoAdeudado =
        getDecimalValue(
            detalle,
            'MontoAdeudado'
        );

    System.debug(
        '===== CAMPOS PRESTAMO ====='
    );

    System.debug(
        'Monto adeudado -> ' +
        r.montoAdeudado
    );
}
    // 🔥 DEBUG DE TODOS LOS CAMPOS TC
    System.debug(
        '========= CAMPOS TARJETA CREDITO ========='
    );

    List<String> keys =
        new List<String>(detalle.keySet());

    keys.sort();

    for(String key : keys){

        System.debug(
            'KEY -> ' + key +
            ' | VALUE -> ' + detalle.get(key)
        );
    }

    System.debug(
        '=========================================='
    );
                }
                else if(
                    normalizedProductLine ==
                    'tarjetas prepago'
                ){

                    INT013TPDTO dto = new INT013TPDTO();

                    dto.parse(responseBody);

                    r.errorCode = dto.result.ErrorCode;
                    r.errorText = dto.result.ErrorText;

                    if(dto.Producto != null &&
                       dto.Producto.values != null){

                        detalle.putAll(dto.Producto.values);
                    }

                    if(dto.Detalle != null &&
                       dto.Detalle.values != null){

                        detalle.putAll(dto.Detalle.values);
                    }

                }
                else if(
                    normalizedProductLine ==
                    'certificados financieros'
                ){

                    INT013CFDTO dto = new INT013CFDTO();

                    dto.parse(responseBody);

                    r.errorCode = dto.result.ErrorCode;
                    r.errorText = dto.result.ErrorText;

                    if(dto.Producto != null &&
                       dto.Producto.values != null){

                        detalle.putAll(dto.Producto.values);
                    }

                    if(dto.Detalle != null &&
                       dto.Detalle.values != null){

                        detalle.putAll(dto.Detalle.values);
                    }

                }
                else if(
                    normalizedProductLine ==
                    'lineas de credito'
                ){

                    INT013LCDTO dto = new INT013LCDTO();

                    dto.parse(responseBody);

                    r.errorCode = dto.result.ErrorCode;
                    r.errorText = dto.result.ErrorText;

                    if(dto.Producto != null &&
                       dto.Producto.values != null){

                        detalle.putAll(dto.Producto.values);
                    }

                    if(dto.Detalle != null &&
                       dto.Detalle.values != null){

                        detalle.putAll(dto.Detalle.values);
                    }

                }
                else {

                    throw new IllegalArgumentException(
                        'Producto no soportado'
                    );
                }

System.debug('=========== TODOS LOS CAMPOS ===========');

for(String key : detalle.keySet()){

    String value = detalle.get(key);

    System.debug(
        'CAMPO -> ' + key +
        ' | VALOR -> ' + value
    );
}

System.debug('========================================');
// ============================================
// EXTRAER BALANCE
// ============================================

Decimal detectedBalance;
String detectedCurrency;

// ============================================
// PRESTAMOS
// ============================================

if(
    normalizedProductLine == 'prestamos' &&
    detalle.containsKey('MontoAdeudado')
){

    detectedBalance =
        Decimal.valueOf(
            detalle.get(
                'MontoAdeudado'
            )
        );

    detectedCurrency = 'DOP';
}

// ============================================
// PRIORIDAD 1
// ============================================

else if(
    detalle.containsKey(
        'BalanceDisponibleRDP'
    )
){

    detectedBalance =
        Decimal.valueOf(
            detalle.get(
                'BalanceDisponibleRDP'
            )
        );

    detectedCurrency = 'DOP';
}

// ============================================
// PRIORIDAD 2
// ============================================

else if(
    detalle.containsKey(
        'BalanceDisponibleUSD'
    )
){

    detectedBalance =
        Decimal.valueOf(
            detalle.get(
                'BalanceDisponibleUSD'
            )
        );

    detectedCurrency = 'USD';
}

// ============================================
// FALLBACK
// ============================================

else {

    for(String key : detalle.keySet()){

        String value = detalle.get(key);

        if(value == null) continue;

        String keyLower =
            key.toLowerCase();

        if(
            keyLower.contains('disponible') ||
            keyLower.contains('balance') ||
            keyLower.contains('saldo')
        ){

            try{

                detectedBalance =
                    Decimal.valueOf(
                        value.replace(',', '')
                    );

                if(
                    keyLower.contains('usd')
                ){
                    detectedCurrency = 'USD';
                }
                else{
                    detectedCurrency = 'DOP';
                }

                break;

            }catch(Exception e){}
        }
    }
}

r.balance = detectedBalance;
r.currencyCode = detectedCurrency;

// ============================================
// CAMPOS PRESTAMOS
// ============================================

if(normalizedProductLine == 'prestamos'){

    r.montoAdeudado =
        getDecimalValue(
            detalle,
            'MontoAdeudado'
        );

    System.debug(
        '===== CAMPOS PRESTAMO ====='
    );

    System.debug(
        'Monto adeudado -> ' +
        r.montoAdeudado
    );
}

// ============================================
// CAMPOS TARJETA DE CREDITO
// ============================================

if(normalizedProductLine == 'tarjetas de credito'){

    r.saldoActualRD =
        getDecimalValue(
            detalle,
            'BalanceFechaRDP'
        );

    r.saldoDisponibleRD =
        getDecimalValue(
            detalle,
            'BalanceDisponibleRDP'
        );

    r.ultimoCorteRD =
        getDecimalValue(
            detalle,
            'BalanceCorteRDP'
        );

    r.pagoMinimoRD =
        getDecimalValue(
            detalle,
            'PagoMinimoRDP'
        );

    r.saldoActualUSD =
        getDecimalValue(
            detalle,
            'BalanceFechaUSD'
        );

    r.saldoDisponibleUSD =
        getDecimalValue(
            detalle,
            'BalanceDisponibleUSD'
        );

    r.fechaCorte =
        detalle.get('FechaCorte');

    System.debug(
        '===== CAMPOS TC ====='
    );

    System.debug(
        'Saldo actual RD -> ' +
        r.saldoActualRD
    );

    System.debug(
        'Saldo disponible RD -> ' +
        r.saldoDisponibleRD
    );

    System.debug(
        'Último corte RD -> ' +
        r.ultimoCorteRD
    );

    System.debug(
        'Pago mínimo RD -> ' +
        r.pagoMinimoRD
    );

    System.debug(
        'Saldo actual USD -> ' +
        r.saldoActualUSD
    );

    System.debug(
        'Saldo disponible USD -> ' +
        r.saldoDisponibleUSD
    );

    System.debug(
        'Fecha corte -> ' +
        r.fechaCorte
    );
}
                System.debug(
                    'BALANCE FINAL -> ' + r.balance
                );

                System.debug(
                    'CURRENCY FINAL -> ' + r.currencyCode
                );

            } else {

                r.errorText =
                    'Error HTTP: ' + res.getStatusCode();
            }

        } catch(Exception e){

            r.errorText = e.getMessage();

            System.debug(
                LoggingLevel.ERROR,
                'INT013Agente ERROR -> ' + e.getMessage()
            );
        }

        return r;
    }
private static Decimal getDecimalValue(
    Map<String,String> detalle,
    String key
){
    try{

        if(
            detalle.containsKey(key) &&
            !String.isBlank(detalle.get(key))
        ){
            return Decimal.valueOf(
                detalle.get(key).replace(',', '')
            );
        }

    }catch(Exception e){}

    return null;
}
    // ============================================
    // NORMALIZAR TEXTO
    // ============================================

 private static String normalizeText(String input){

    if(input == null){
        return '';
    }

    input = input.trim().toLowerCase();

    // eliminar acentos unicode
    input = input.normalizeSpace();

    input = input.replaceAll('[áàäâã]', 'a');
    input = input.replaceAll('[éèëê]', 'e');
    input = input.replaceAll('[íìïî]', 'i');
    input = input.replaceAll('[óòöôõ]', 'o');
    input = input.replaceAll('[úùüû]', 'u');
    input = input.replaceAll('ñ', 'n');

    return input.trim();
}
}