global class INT001TestMock  implements HttpCalloutMock {
    String pf_pj;
     
    global INT001TestMock(String pf_pj){
        this.pf_pj = pf_pj;
    }
    
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        if(this.pf_pj.equals('PF'))
        	res.setBody('<?xml version="1.0" encoding="UTF-8"?> <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> <soap:Header> <wsa:Action>http://crmintegration.local/ConsultaPadronResponse</wsa:Action> <wsa:MessageID>urn:uuid:a56b15bd-d55f-4849-b315-0a4ba0607465</wsa:MessageID> <wsa:RelatesTo>urn:uuid:f7cfba7c-14bf-41fe-a901-1d54d54f3fc0</wsa:RelatesTo> <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To> <wsse:Security> <wsu:Timestamp wsu:Id="Timestamp-f21bdc19-4ca9-4e42-bf26-8d4c34a87d95"> <wsu:Created>2020-02-04T16:12:06Z</wsu:Created> <wsu:Expires>2020-02-04T16:17:06Z</wsu:Expires> </wsu:Timestamp> </wsse:Security> </soap:Header> <soap:Body> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Contacto%20Padron%20Response%20IO"> <Result> <ErrorCode>000</ErrorCode> <ErrorText>TRANSACCION PROCESADA</ErrorText> <Response> <NumDocumento>00100058007</NumDocumento> <TipoDocumento>CEDULA</TipoDocumento> <PrimerNombre>ANA</PrimerNombre> <SegundoNombre>JACQUELINE</SegundoNombre> <PrimerApellido>DE MARCHENA</PrimerApellido> <SegundoApellido>SEPULVEDA</SegundoApellido> <FechaNacimiento>04/03/1961</FechaNacimiento> <LugarNacimiento>SANTO DOMINGO, R.D.</LugarNacimiento> <Genero>Femenino</Genero> </Response> </Result> </ListOfBREAIFuncionGeneral> </soap:Body> </soap:Envelope>');
        else if(this.pf_pj.equals('FAIL'))
        	res.setBody('<?xml version="1.0" encoding="UTF-8"?> <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> <soap:Header> <wsa:Action>http://crmintegration.local/ConsultaPadronResponse</wsa:Action> <wsa:MessageID>urn:uuid:a56b15bd-d55f-4849-b315-0a4ba0607465</wsa:MessageID> <wsa:RelatesTo>urn:uuid:f7cfba7c-14bf-41fe-a901-1d54d54f3fc0</wsa:RelatesTo> <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To> <wsse:Security> <wsu:Timestamp wsu:Id="Timestamp-f21bdc19-4ca9-4e42-bf26-8d4c34a87d95"> <wsu:Created>2020-02-04T16:12:06Z</wsu:Created> <wsu:Expires>2020-02-04T16:17:06Z</wsu:Expires> </wsu:Timestamp> </wsse:Security> </soap:Header> <soap:Body> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Contacto%20Padron%20Response%20IO"> <Result> <ErrorCode>500</ErrorCode> <ErrorText>ERROR TRANSACCION</ErrorText> <Response> </Response> </Result> </ListOfBREAIFuncionGeneral> </soap:Body> </soap:Envelope>');
        return res; 
    }
    
    
}