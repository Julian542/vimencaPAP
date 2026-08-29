global class  wsCreacionProdMock implements HttpCalloutMock {
    String pf_pj;
     
    global wsCreacionProdMock(String pf_pj){
        this.pf_pj = pf_pj;
    }
    
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        if(this.pf_pj.equals('SUCCESS'))
        	res.setBody('<?xml version="1.0" encoding="UTF-8"?> <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> <soap:Header> <wsa:Action>http://crmintegration.local/CrearCtaCorrienteResponse</wsa:Action> <wsa:MessageID>urn:uuid:74a1e5ff-1b2d-42e8-b3a3-ecdbb794a9b7</wsa:MessageID> <wsa:RelatesTo>urn:uuid:2e1b37a7-0a02-4f42-92ee-51876f5b661a</wsa:RelatesTo> <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To> <wsse:Security> <wsu:Timestamp wsu:Id="Timestamp-a3bcaef7-6875-4267-91e6-3144f300bdca"> <wsu:Created>2020-01-30T17:36:07Z</wsu:Created> <wsu:Expires>2020-01-30T17:41:07Z</wsu:Expires> </wsu:Timestamp> </wsse:Security> </soap:Header> <soap:Body> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Crear%20Cuenta%20Response%20IO"> <Result> <ErrorCode>000</ErrorCode> <ErrorText>TRANSACCION PROCESADA</ErrorText> <Producto> <NumCuenta>45015935</NumCuenta> </Producto> </Result> </ListOfBREAIFuncionGeneral> </soap:Body> </soap:Envelope>');
        else if(this.pf_pj.equals('FAIL'))
        	res.setBody('<?xml version="1.0" encoding="UTF-8"?> <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> <soap:Header> <wsa:Action>http://crmintegration.local/CrearCtaCorrienteResponse</wsa:Action> <wsa:MessageID>urn:uuid:74a1e5ff-1b2d-42e8-b3a3-ecdbb794a9b7</wsa:MessageID> <wsa:RelatesTo>urn:uuid:2e1b37a7-0a02-4f42-92ee-51876f5b661a</wsa:RelatesTo> <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To> <wsse:Security> <wsu:Timestamp wsu:Id="Timestamp-a3bcaef7-6875-4267-91e6-3144f300bdca"> <wsu:Created>2020-01-30T17:36:07Z</wsu:Created> <wsu:Expires>2020-01-30T17:41:07Z</wsu:Expires> </wsu:Timestamp> </wsse:Security> </soap:Header> <soap:Body> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Crear%20Cuenta%20Response%20IO"> <Result> <ErrorCode>9903</ErrorCode> <ErrorText>ERROR TRANSACCION</ErrorText> </Result> </ListOfBREAIFuncionGeneral> </soap:Body> </soap:Envelope>');
        return res; 
    }   
}