@IsTest
global class FSC_EsignHttpMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');

        String endpoint = req.getEndpoint() == null ? '' : req.getEndpoint();

	    if (endpoint.contains('/file/upload')) {
	        res.setBody('{"FileId":"mock-file-id-001"}');
	        return res;
	    }

	    if (endpoint.contains('/file/prepare')) {
	        res.setBody(
	            '{"Activities":[{"Action":{"Sign":{"Elements":{"Signatures":[{"ElementId":"FIRMASOLICITANTE","DocumentNumber":1,"FieldDefinition":{"Position":{"PageNumber":3,"X":238,"Y":160},"Size":{"Width":120,"Height":40}}}]}}}}]}'
	        );
	        return res;
	    }

	    if (endpoint.contains('/file/')) {
	        res.setHeader('Content-Type', 'application/pdf');
	        res.setBodyAsBlob(Blob.valueOf('PDF FIRMADO MOCK'));
            return res;
        }

        if (endpoint.contains('/envelope/send')) {
            res.setBody('{"EnvelopeId":"mock-envelope-id-001"}');
            return res;
        }

        if (endpoint.contains('/envelope/') && endpoint.endsWith('/files')) {
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Documents":[{"FileId":"mock-signed-file-id-001","FileName":"Documento firmado.pdf"}]}');
            return res;
        }

        if (endpoint.contains('/envelope/')) {
            res.setBody('{"EnvelopeStatus":"InProgress","Activities":[]}');
            return res;
        }

        res.setBody('{"success":true,"message":null}');
        return res;
    }
}