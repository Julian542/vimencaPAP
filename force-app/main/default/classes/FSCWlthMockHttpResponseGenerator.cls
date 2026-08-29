/*************************
* @Class Name:- FSCWlthMockHttpResponseGenerator
* @Description:- mocked Service provider for unit test
*                no remote callouts from this provider
**************************/
@IsTest
global with sharing class FSCWlthMockHttpResponseGenerator implements HttpCalloutMock {
    Integer code;
    String status;
    String body;
    Map<string, String> responseHeaders;

    //Mock Response Generator
    public FSCWlthMockHttpResponseGenerator(Integer code, String status, String body, Map<String, String> responseHeaders) {
        this.code = code;
        this.status = status;
        this.body = body;
        this.responseHeaders = responseHeaders;
    }

    //Get response
    public HTTPResponse respond(HTTPRequest req) {
        //create fake response
        HttpResponse res = new HttpResponse();
        for (String key : this.responseHeaders.keySet()) {
            res.setHeader(key, this.responseHeaders.get(key));
        }
        res.setBody(this.body);
        res.setStatusCode(this.code);
        res.setStatus(this.status);
        return res;
    }
}