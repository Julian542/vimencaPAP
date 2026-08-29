global class INT061TestMock  implements HttpCalloutMock {
    
    String pf_pj;
    
    global INT061TestMock(String pf_pj){
        this.pf_pj = pf_pj;
    }
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        if(this.pf_pj.equals('PF'))
            res.setBody('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <soap:Header> <wsa:Action>http://crmintegration.local/ConsultaListaBancosResponse</wsa:Action> <wsa:MessageID>urn:uuid:45a88e3d-7594-4281-bc6d-8a58dac0af4c</wsa:MessageID> <wsa:RelatesTo>urn:uuid:487eb161-ab39-44aa-ba18-3978ba70d971</wsa:RelatesTo> <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To> <wsse:Security> <wsu:Timestamp wsu:Id="Timestamp-305b3800-445d-420f-9b34-f4ccfeaffdcb"> <wsu:Created>2018-02-24T17:18:32Z</wsu:Created> <wsu:Expires>2018-02-24T17:23:32Z</wsu:Expires> </wsu:Timestamp> </wsse:Security> </soap:Header> <soap:Body> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Bancos%20IO%20Response"> <Result> <ErrorCode>000</ErrorCode> <ErrorText>TRANSACCION PROCESADA</ErrorText> <Response> <CodBanco>70016</CodBanco> <NombreBanco>ALMUZAINI EXCHANGE COMPANY KSC (CLO</NombreBanco> </Response> <Response> <CodBanco>70017</CodBanco> <NombreBanco>ASSET ALLOCATION ADVISORS SA</NombreBanco> </Response> <Response> <CodBanco>70018</CodBanco> <NombreBanco>ASSOCIATION ADMINISTRATIVE AGRR</NombreBanco> </Response> <Response> <CodBanco>70019</CodBanco> <NombreBanco>ALLIANZ ALTERNATIVE ASSET MANAGEMEN</NombreBanco> </Response> </Result> </ListOfBREAIFuncionGeneral> </soap:Body> </soap:Envelope>');
        else if (this.pf_pj.equals('PJ'))
            res.setBody('');
        return res; 
    }
}