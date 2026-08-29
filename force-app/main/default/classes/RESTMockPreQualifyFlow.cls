@isTest
global class RESTMockPreQualifyFlow implements HttpCalloutMock{
    
	global integer StatusCode = 200;

    public RESTMockPreQualifyFlow(){
        
    } 
    public RESTMockPreQualifyFlow(Integer StatusCode){
        this.StatusCode = StatusCode;
    }
    
    global HTTPResponse respond (HTTPRequest req) {
        HttpResponse res = new HttpResponse ();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(StatusCode);
        res.setBody(
            '{'+
                '"status": "success",'+
                '"data": {'+
                	'"id": "faf64ea3-92ae-458b-a48c-750bf7f5f5fc",'+
                	'"message": "MEDIO"'+
                '}'+
            '}'
        );
        return res;
    }
}