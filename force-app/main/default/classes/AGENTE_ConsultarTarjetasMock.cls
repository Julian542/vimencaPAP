@IsTest
global class AGENTE_ConsultarTarjetasMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        res.setStatusCode(200);

        String reqBody = req.getBody() != null ? req.getBody() : '';
        String ns = reqBody.contains('ConsultaProdFinPJ') ? 
            'http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PJ%20Response%20IO' : 
            'http://www.siebel.com/xml/BR%20EAI%20Consulta%20Productos%20PF%20VBC%20Response%20IO';

        String xmlBody = '<?xml version="1.0" encoding="UTF-8"?>' +
            '<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">' +
                '<SOAP-ENV:Body>' +
                    '<ListOfBREAIFuncionGeneral xmlns="' + ns + '">' +
                        '<Result>' +
                            '<ErrorCode>000</ErrorCode>' +
                            '<ErrorText>TRANSACCION PROCESADA</ErrorText>' +
                            '<Producto>' +
                                '<NumCuenta>1234567890123456</NumCuenta>' +
                                '<CodigoProducto>TCR</CodigoProducto>' +
                                '<LineaProducto>TARJETA CREDITO</LineaProducto>' +
                                '<Estado>VIGENTE</Estado>' +
                            '</Producto>' +
                            '<Producto>' +
                                '<NumCuenta>1111222233334444</NumCuenta>' +
                                '<CodigoProducto>TCR</CodigoProducto>' +
                                '<LineaProducto>TARJETA CREDITO</LineaProducto>' +
                                '<Estado>INACTIVA</Estado>' +
                            '</Producto>' +
                            '<Producto>' +
                                '<NumCuenta>9876543210987654</NumCuenta>' +
                                '<CodigoProducto>TCR</CodigoProducto>' +
                                '<LineaProducto>TARJETA CREDITO</LineaProducto>' +
                                '<Estado>BLOQUEADA</Estado>' +
                            '</Producto>' +
                        '</Result>' +
                    '</ListOfBREAIFuncionGeneral>' +
                '</SOAP-ENV:Body>' +
            '</SOAP-ENV:Envelope>';

        res.setBody(xmlBody);
        return res;
    }
}