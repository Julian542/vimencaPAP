global class INT008TestMock  implements HttpCalloutMock {

    String pf_pj;
     
    global INT008TestMock(String pf_pj){
        this.pf_pj = pf_pj;
    }
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        if(this.pf_pj.equals('PF'))
        	res.setBody('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <soap:Header> <wsa:Action>http://schemas.xmlsoap.org/ws/2004/08/addressing/fault</wsa:Action> <wsa:MessageID>urn:uuid:8159c407-260f-4250-8971-342527265b4a</wsa:MessageID> <wsa:RelatesTo>urn:uuid:0ce484fc-a330-4cd1-999a-da6241b965d5</wsa:RelatesTo> <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To> <wsse:Security> <wsu:Timestamp wsu:Id="Timestamp-aa279305-308b-4fc4-aa84-ba3a393a4ff2"> <wsu:Created>2018-02-15T09:55:39Z</wsu:Created> <wsu:Expires>2018-02-15T10:00:39Z</wsu:Expires> </wsu:Timestamp> </wsse:Security> </soap:Header> <soap:Body> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Empresa%20Core%20Response%20IO"> <Result> <ErrorCode>000</ErrorCode> <ErrorText>TRANSACION PROCESADA</ErrorText> <Response> <CIF>2589005542</CIF> </Response> </Result> </ListOfBREAIFuncionGeneral> </soap:Body> </soap:Envelope>');
        else if (this.pf_pj.equals('PJ'))
        	res.setBody('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <soap:Header> <wsa:Action>http://schemas.xmlsoap.org/ws/2004/08/addressing/fault</wsa:Action> <wsa:MessageID>urn:uuid:8159c407-260f-4250-8971-342527265b4a</wsa:MessageID> <wsa:RelatesTo>urn:uuid:0ce484fc-a330-4cd1-999a-da6241b965d5</wsa:RelatesTo> <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To> <wsse:Security> <wsu:Timestamp wsu:Id="Timestamp-aa279305-308b-4fc4-aa84-ba3a393a4ff2"> <wsu:Created>2018-02-15T09:55:39Z</wsu:Created> <wsu:Expires>2018-02-15T10:00:39Z</wsu:Expires> </wsu:Timestamp> </wsse:Security> </soap:Header> <soap:Body> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Empresa%20Core%20Response%20IO"> <Result> <ErrorCode>000</ErrorCode> <ErrorText>TRANSACION PROCESADA</ErrorText> <Response> <CIF>2589005542</CIF> </Response> </Result> </ListOfBREAIFuncionGeneral> </soap:Body> </soap:Envelope>');
        return res; 
    }
    
}