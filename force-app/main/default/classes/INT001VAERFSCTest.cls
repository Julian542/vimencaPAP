@IsTest
private class INT001VAERFSCTest {
    private class PepMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setHeader('Content-Type', 'application/xml');
            response.setBody(
                '<root><ErrorCode>000</ErrorCode><ErrorText>Success</ErrorText>' +
                '<PersonaPEP>SI</PersonaPEP><Documento>00100058007</Documento>' +
                '<TipoDocumento>Cédula</TipoDocumento><PrimerNombre>Juan Carlos</PrimerNombre>' +
                '<SegundoApellido>Lopez</SegundoApellido><PrimerApellido>Perez</PrimerApellido>' +
                '<TipoParentesco>AMIGO</TipoParentesco><Ocupacion>MEDICO</Ocupacion>' +
                '<InstitucionTrabajo>EMPRESA TEST</InstitucionTrabajo>' +
                '<Nacionalidad>REPUBLICA DOMINICANA</Nacionalidad>' +
                '<CargoPolitico>SENADOR</CargoPolitico></root>'
            );
            return response;
        }
    }

    private static Account createCandidate(String identificationType, String state) {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        Account account = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount').getRecordTypeId(),
            FirstName = 'Int001',
            LastName = 'Coverage ' + identificationType,
            ACC_TipoIdentificacion__c = identificationType,
            ACC_NumIdentificacion__c = '00100058007',
            ACC_Estado__c = state
        );
        insert account;
        return account;
    }

    @IsTest
    static void updatesACreatedCedulaCandidateFromTheElectoralRegister() {
        Account candidate = createCandidate('Cédula', 'CREADO');
        Test.setMock(HttpCalloutMock.class, new INT001TestMock('PF'));

        Test.startTest();
        INT001_VAER_Controller_FSC.Response response =
            INT001_VAER_Controller_FSC.updateAccount(candidate.Id);
        Test.stopTest();

        System.assertEquals('000', response.errorCode);
        System.assertEquals(200, response.httpRequestStatusCode);
    }

    @IsTest
    static void rejectsCandidatesWithANonCedulaIdentificationType() {
        Account candidate = createCandidate('Pasaporte', 'CREADO');

        Test.startTest();
        INT001_VAER_Controller_FSC.Response response =
            INT001_VAER_Controller_FSC.updateAccount(candidate.Id);
        Test.stopTest();

        System.assertEquals(false, response.updateSuccess);
        System.assert(response.updateErrorMessage.contains('CÉDULA'));
    }

    @IsTest
    static void rejectsCedulaOutsideCreatedState() {
        Account candidate = createCandidate('Cédula', null);

        INT001_VAER_Controller_FSC.Response response =
            INT001_VAER_Controller_FSC.updateAccount(candidate.Id);

        System.assertEquals(false, response.updateSuccess);
        System.assert(response.updateErrorMessage.contains('CREADO'));
    }

    @IsTest
    static void coversPepCandidateAndMissingIdentificationBranches() {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        Account missingIdentification = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('PersonAccount').getRecordTypeId(),
            FirstName = 'Missing',
            LastName = 'Identification',
            ACC_Estado__c = 'CREADO'
        );
        insert missingIdentification;

        Account pepCandidate = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Fisica').getRecordTypeId(),
            FirstName = 'Pep',
            LastName = 'Candidate',
            ACC_TipoIdentificacion__c = 'Cédula',
            ACC_NumIdentificacion__c = '00100058007',
            ACC_Estado__c = 'INICIADO'
        );
        insert pepCandidate;
        insert new FinServ__Employment__c(Name = 'EMPRESA TEST');

        Test.setMock(HttpCalloutMock.class, new PepMock());
        Test.startTest();
        INT001_VAER_Controller_FSC.Response missingResponse =
            INT001_VAER_Controller_FSC.updateAccountPEP(missingIdentification.Id);
        INT001_VAER_Controller_FSC.Response pepResponse =
            INT001_VAER_Controller_FSC.updateAccountPEP(pepCandidate.Id);
        INT001_VAER_Controller_FSC.updateAccountPEPFlow(
            new List<Id>{ missingIdentification.Id }
        );
        Test.stopTest();

        System.assertNotEquals(null, missingResponse);
        System.assertNotEquals(null, pepResponse);
    }

    @IsTest
    static void returnsNotRegisteredWhenTheElectoralServiceFails() {
        Account candidate = createCandidate('Cédula', 'CREADO');
        Test.setMock(HttpCalloutMock.class, new INT001TestMock('FAIL'));

        Test.startTest();
        INT001_VAER_Controller_FSC.Response response =
            INT001_VAER_Controller_FSC.updateAccount(candidate.Id);
        Test.stopTest();

        System.assertEquals(false, response.updateSuccess);
        System.assertEquals('El numero de documento no esta registrado', response.updateErrorMessage);
    }
}
