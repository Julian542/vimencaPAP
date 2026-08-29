global class INT057TestMock  implements HttpCalloutMock {
    
    String pf_pj;
    
    global INT057TestMock(String pf_pj){
        this.pf_pj = pf_pj;
    }
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        if(this.pf_pj.equals('PF'))
            res.setBody('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <soap:Header> <wsa:Action>http://crmintegration.local/ConsultaProdFinPJResponse</wsa:Action> <wsa:MessageID>urn:uuid:cdd8dbc0-56b9-4d68-b1ab-8e1f3893b8ec</wsa:MessageID> <wsa:RelatesTo>urn:uuid:8d181717-397b-4abc-b30f-532927595ab5</wsa:RelatesTo> <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To> <wsse:Security> <wsu:Timestamp wsu:Id="Timestamp-1c4e6de1-c0bb-4df9-b1c6-f9013e75dde5"> <wsu:Created>2018-02-19T10:08:03Z</wsu:Created> <wsu:Expires>2018-02-19T10:13:03Z</wsu:Expires> </wsu:Timestamp> </wsse:Security> </soap:Header> <soap:Body> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Funcion%20General%20IO"> <Result> <ErrorCode>000</ErrorCode> <ErrorText>TRANSACCION PROCESADA</ErrorText> </Result> </ListOfBREAIFuncionGeneral> </soap:Body> </soap:Envelope>');
        else if (this.pf_pj.equals('PJ'))
            res.setBody('');
        return res; 
    }
}