global class INT055TestMock  implements HttpCalloutMock {
    
    String pf_pj;
    
    global INT055TestMock(String pf_pj){
        this.pf_pj = pf_pj;
    }
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        if(this.pf_pj.equals('PF'))
            res.setBody('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <soap:Header> <wsa:Action>http://crmintegration.local/CtaComunVincResponse</wsa:Action> <wsa:MessageID>urn:uuid:4c033b71-3060-441d-9e8e-439d5ffad083</wsa:MessageID> <wsa:RelatesTo>urn:uuid:31283f73-6f2e-4b0c-ade2-0edd3edb4820</wsa:RelatesTo> <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To> <wsse:Security> <wsu:Timestamp wsu:Id="Timestamp-de1407d0-f065-48eb-aa55-7861788faff5"> <wsu:Created>2018-02-24T15:50:54Z</wsu:Created> <wsu:Expires>2018-02-24T15:55:54Z</wsu:Expires> </wsu:Timestamp> </wsse:Security> </soap:Header> <soap:Body> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20Cuenta%20Comun%20Vinculados%20Response%20IO"> <Result> <ErrorCode>000</ErrorCode> <ErrorText>TRANSACCION PROCESADA</ErrorText> <Response> <NumeroCuenta>10005891</NumeroCuenta> <NombreProducto>C/AHORRO PERSONAL SIN LIBRETA</NombreProducto> <Balance>1447.89</Balance> <TieneRestriccion>N</TieneRestriccion> </Response> </Result> </ListOfBREAIFuncionGeneral> </soap:Body> </soap:Envelope>');
        else if (this.pf_pj.equals('PJ'))
            res.setBody('');
        return res; 
    }
}