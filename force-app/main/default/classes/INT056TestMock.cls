global class INT056TestMock  implements HttpCalloutMock {
    
    String pf_pj;
    
    global INT056TestMock(String pf_pj){
        this.pf_pj = pf_pj;
    }
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        if(this.pf_pj.equals('PF'))
            res.setBody('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <soap:Header> <wsa:Action>http://schemas.xmlsoap.org/ws/2004/08/addressing/fault</wsa:Action> <wsa:MessageID>urn:uuid:db9e60f2-7cc2-4d17-8ef6-36c389c0129c</wsa:MessageID> <wsa:RelatesTo>urn:uuid:10342f8d-915b-4eb1-926e-af728c5c0909</wsa:RelatesTo> <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To> <wsse:Security> <wsu:Timestamp wsu:Id="Timestamp-f62a1c2f-e92c-414c-a8e1-5cc1dabdfc9d"> <wsu:Created>2018-02-23T22:45:45Z</wsu:Created> <wsu:Expires>2018-02-23T22:50:45Z</wsu:Expires> </wsu:Timestamp> </wsse:Security> </soap:Header> <soap:Body> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Funcion%20General%20IO"> <Result> <ErrorCode>000</ErrorCode> <ErrorText>TRANSACCION PORCESADA</ErrorText> </Result> </ListOfBREAIFuncionGeneral> </soap:Body> </soap:Envelope>');
        else if (this.pf_pj.equals('PJ'))
            res.setBody('');
        return res; 
    }
}