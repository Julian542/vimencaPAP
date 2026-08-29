global class INT014TestMock  implements HttpCalloutMock {
    
    String pf_pj;
    
    global INT014TestMock(String pf_pj){
        this.pf_pj = pf_pj;
    }
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        if(this.pf_pj.equals('PF'))
            res.setBody('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"> <soap:Header> <wsa:Action>http://crmintegration.local/ConsultaTransCtasResponse</wsa:Action> <wsa:MessageID>urn:uuid:2a24bebd-1328-4305-afa1-6ed5d50ac377</wsa:MessageID> <wsa:RelatesTo>urn:uuid:98708c2f-ff52-40fb-9062-81f851c6bfb2</wsa:RelatesTo> <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To> <wsse:Security> <wsu:Timestamp wsu:Id="Timestamp-51d861ba-5186-463a-b531-d4e5bc081668"> <wsu:Created>2018-02-20T10:36:57Z</wsu:Created> <wsu:Expires>2018-02-20T10:41:57Z</wsu:Expires> </wsu:Timestamp> </wsse:Security> </soap:Header> <soap:Body> <ListOfBREAIFuncionGeneral xmlns="http://www.siebel.com/xml/BR%20EAI%20Transacciones%20Cuentas%20Response%20IO"> <Result> <ErrorCode>000</ErrorCode> <ErrorText>TRANSACCION PROCESADA</ErrorText> <Response> <CO>Credito</CO> <CodCausal>00120 0002120021N</CodCausal> <CodTransaccion>13</CodTransaccion> <CreditoDebito>Crédito</CreditoDebito> <DescTransaccion>Dep de ahorros sin libreta</DescTransaccion> <Documento>647657289</Documento> <Estado>Procesada</Estado> <FechaFinal>02/28/2018</FechaFinal> <FechaInicial>02/01/2018</FechaInicial> <FechaProceso>09/04/2017</FechaProceso> <FechaTransaccion>09/04/2017</FechaTransaccion> <Hora>00:00:00</Hora> <IdPagAnt>201709040000000024000044300000000001000000000000066064990</IdPagAnt> <IdPagProx>201709040000000024000044300000000001000000000000066064990</IdPagProx> <MontoMaximo>12.85</MontoMaximo> <MontoMinimo>96.58</MontoMinimo> <NumDocumento>021N</NumDocumento> <Oficina>OFIC PRINCIPAL</Oficina> <Referencia>8227506776</Referencia> <Terminal>T273674656</Terminal> <TipoDeposito>Efectivo</TipoDeposito> <Valor>20.00</Valor> <UltimaPagina>Y</UltimaPagina> </Response> </Result> </ListOfBREAIFuncionGeneral> </soap:Body> </soap:Envelope>');
        else if (this.pf_pj.equals('PJ'))
            res.setBody('');
        return res; 
    }
    
}