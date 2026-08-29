global class INT002TestMock  implements HttpCalloutMock {

    String pf_pj;
     
    global INT002TestMock(String pf_pj){
        this.pf_pj = pf_pj;
    }
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        if(this.pf_pj.equals('PF'))
        	res.setBody('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <soap:Header> <wsa:Action>http://crmintegration.local/ValidacionRNCResponse</wsa:Action> <wsa:MessageID>urn:uuid:37bd8270-561e-4e3e-8e60-d56c109ad3d0</wsa:MessageID> <wsa:RelatesTo>urn:uuid:c35f3ed4-5bfc-436f-9b3d-1830bce37820</wsa:RelatesTo> <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To> <wsse:Security> <wsu:Timestamp wsu:Id="Timestamp-5f39612f-a031-4716-9dc6-ea8bf7c1a392"> <wsu:Created>2018-02-14T17:50:29Z</wsu:Created> <wsu:Expires>2018-02-14T17:55:29Z</wsu:Expires> </wsu:Timestamp> </wsse:Security> </soap:Header> <soap:Body> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Validacion%20RNC%20Response%20IO"> <Result> <ErrorCode>000</ErrorCode> <ErrorText>TRANSACCION PROCESADA</ErrorText> <Response> <RNC>502598856</RNC> <NombreCorto>GARCIA BRETON PEDRO JOSE</NombreCorto> <RazonSocial/> </Response> </Result> </ListOfBREAIFuncionGeneral> </soap:Body> </soap:Envelope>');
        else if (this.pf_pj.equals('PJ'))
            res.setBody('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <soap:Header> <wsa:Action>http://crmintegration.local/ValidacionRNCResponse</wsa:Action> <wsa:MessageID>urn:uuid:37bd8270-561e-4e3e-8e60-d56c109ad3d0</wsa:MessageID> <wsa:RelatesTo>urn:uuid:c35f3ed4-5bfc-436f-9b3d-1830bce37820</wsa:RelatesTo> <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To> <wsse:Security> <wsu:Timestamp wsu:Id="Timestamp-5f39612f-a031-4716-9dc6-ea8bf7c1a392"> <wsu:Created>2018-02-14T17:50:29Z</wsu:Created> <wsu:Expires>2018-02-14T17:55:29Z</wsu:Expires> </wsu:Timestamp> </wsse:Security> </soap:Header> <soap:Body> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Validacion%20RNC%20Response%20IO"> <Result> <ErrorCode>000</ErrorCode> <ErrorText>TRANSACCION PROCESADA</ErrorText> <Response> <RNC>502598856</RNC> <NombreCorto>GARCIA BRETON PEDRO JOSE</NombreCorto> <RazonSocial/> </Response> </Result> </ListOfBREAIFuncionGeneral> </soap:Body> </soap:Envelope>');
        return res; 
    }
    
}