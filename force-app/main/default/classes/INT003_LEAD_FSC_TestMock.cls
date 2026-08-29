@isTest
global class INT003_LEAD_FSC_TestMock implements HttpCalloutMock {
  String scenario;

  global INT003_LEAD_FSC_TestMock(String scenario) {
    this.scenario = scenario;
  }

  global HttpResponse respond(HttpRequest req) {
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', 'text/xml');

    if (this.scenario == 'SUCCESS') {
      res.setStatusCode(200);
      res.setBody(
        '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<ListOfBREAIFuncionGeneral>' +
          '<Result>' +
          '<ErrorCode>000</ErrorCode>' +
          '<ErrorText>TRANSACCION PROCESADA</ErrorText>' +
          '<Response>' +
          '<NumDocumento>00112345678</NumDocumento>' +
          '<TipoDocumento>Cedula</TipoDocumento>' +
          '<CoincidenciaLI>N</CoincidenciaLI>' +
          '<CoincidenciaLE>N</CoincidenciaLE>' +
          '<Listas></Listas>' +
          '</Response>' +
          '</Result>' +
          '</ListOfBREAIFuncionGeneral>' +
          '</soap:Body>' +
          '</soap:Envelope>'
      );
    } else if (this.scenario == 'ERROR') {
      res.setStatusCode(200);
      res.setBody(
        '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
          '<soap:Body>' +
          '<ListOfBREAIFuncionGeneral>' +
          '<Result>' +
          '<ErrorCode>999</ErrorCode>' +
          '<ErrorText>ERROR</ErrorText>' +
          '</Result>' +
          '</ListOfBREAIFuncionGeneral>' +
          '</soap:Body>' +
          '</soap:Envelope>'
      );
    } else if (this.scenario == 'HTTP_ERROR') {
      res.setStatusCode(500);
      res.setBody('Internal Server Error');
    }
    return res;
  }
}