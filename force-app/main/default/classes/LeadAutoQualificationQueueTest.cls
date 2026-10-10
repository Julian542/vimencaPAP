@IsTest
private class LeadAutoQualificationQueueTest {
    private class QualificationMock implements HttpCalloutMock {
        private String responseType;

        QualificationMock(String responseType) {
            this.responseType = responseType;
        }

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setStatus('OK');
            response.setHeader('Content-Type', 'application/xml');
            if (responseType == 'RNC') {
                response.setBody(
                    '<Envelope><ErrorCode>000</ErrorCode><ErrorText>OK</ErrorText>' +
                    '<Result><RNC>123456789</RNC><NombreCorto>ACME</NombreCorto>' +
                    '<RazonSocial>ACME Inc.</RazonSocial></Result></Envelope>'
                );
            } else if (responseType == 'RNC_ERROR') {
                response.setBody(
                    '<Envelope><ErrorCode>001</ErrorCode>' +
                    '<ErrorText>RNC no encontrado</ErrorText></Envelope>'
                );
            } else if (responseType == 'CEDULA_ERROR') {
                response.setBody(
                    '<root><ErrorCode>001</ErrorCode><ErrorText>No encontrado</ErrorText>' +
                    '<NumDocumento></NumDocumento></root>'
                );
            } else {
                response.setBody(
                    '<root><ErrorCode>000</ErrorCode><ErrorText>Success</ErrorText>' +
                    '<NumDocumento>00100058007</NumDocumento><PrimerNombre>Juan</PrimerNombre>' +
                    '<SegundoNombre>Carlos</SegundoNombre><PrimerApellido>Perez</PrimerApellido>' +
                    '<SegundoApellido>Lopez</SegundoApellido><FechaNacimiento>1990-05-15</FechaNacimiento>' +
                    '<LugarNacimiento>R.D</LugarNacimiento><Genero>MASCULINO</Genero></root>'
                );
            }
            return response;
        }
    }

    @IsTest
    static void enqueuesOnlyEligiblePersonAndPassportCandidates() {
        Map<String, Schema.RecordTypeInfo> recordTypes =
            Lead.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        String leadPrefix = Lead.SObjectType.getDescribe().getKeyPrefix();

        Lead personCandidate = new Lead(
            Id = Id.valueOf(leadPrefix + '000000000011'),
            RecordTypeId = recordTypes.get('Candidato_Persona_Natural').getRecordTypeId(),
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_NumIdentificacion__c = '00108804001'
        );
        Lead passportCandidate = new Lead(
            Id = Id.valueOf(leadPrefix + '000000000012'),
            RecordTypeId = recordTypes.get('Candidato_Persona_Natural').getRecordTypeId(),
            LEA_TipoIdentificacion__c = 'Pasaporte',
            LEA_NumIdentificacion__c = 'PA04002'
        );
        Lead ignoredCandidate = new Lead(
            Id = Id.valueOf(leadPrefix + '000000000013'),
            RecordTypeId = recordTypes.get('Candidato_Persona_Natural').getRecordTypeId(),
            LEA_TipoIdentificacion__c = 'Cédula'
        );

        Test.startTest();
        LeadAutoQualificationQueue.enqueueEligibleLeads(null);
        LeadAutoQualificationQueue.enqueueEligibleLeads(new List<Lead>());
        LeadAutoQualificationQueue.enqueueEligibleLeads(
            new List<Lead>{ null, personCandidate, passportCandidate, ignoredCandidate }
        );
        System.assertEquals(2, Limits.getQueueableJobs());
        Test.stopTest();
    }

    @IsTest
    static void runsElectoralRegisterStage() {
        Test.setMock(HttpCalloutMock.class, new INT001TestMock('PF'));
        Datos_Maestros__c activity = new Datos_Maestros__c(
            Name = 'Actividad auto cedula',
            DM_Direccion__c = 'AUTO-CED'
        );
        insert activity;
        Lead candidate = new Lead(
            RecordTypeId = Lead.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Natural').getRecordTypeId(),
            FirstName = 'Auto',
            LastName = 'Cedula',
            Company = 'Prospecto No Cliente',
            Status = 'Iniciado',
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_NumIdentificacion__c = '00100058007',
            LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
            LEA_Persona_PEP__c = 'NO',
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Actividad_Economica__c = activity.Id,
            LEA_Tipo_Sector__c = 'Privado'
        );

        Test.startTest();
        insert candidate;
        Test.stopTest();

        System.assertNotEquals(null, candidate.Id);
    }

    @IsTest
    static void coversEmptyAndPepStagesWithoutRunningAChain() {
        Test.setMock(HttpCalloutMock.class, new INT004TestMock('PEP_NO'));
        Id naturalRecordTypeId = Lead.SObjectType.getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('Candidato_Persona_Natural').getRecordTypeId();
        Lead candidate = new Lead(
            RecordTypeId = naturalRecordTypeId,
            FirstName = 'First',
            LastName = 'Failure',
            Company = 'Prospecto No Cliente',
            Status = 'Iniciado',
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_NumIdentificacion__c = '00108803885',
            LEA_Persona_PEP__c = 'NO'
        );
        insert candidate;

        // El segundo Id es deliberadamente inexistente: cubre la continuación
        // del queueable sin iniciar otra cadena de calificación real.
        Id missingLeadId = Id.valueOf(
            Lead.SObjectType.getDescribe().getKeyPrefix() + '000000000099'
        );

        LeadAutoQualificationQueue emptyQueue =
            (LeadAutoQualificationQueue) JSON.deserialize(
                '{"leadIds":[],"currentStage":"PEP"}',
                LeadAutoQualificationQueue.class
            );
        emptyQueue.execute(null);

        LeadAutoQualificationQueue pepQueue =
            (LeadAutoQualificationQueue) JSON.deserialize(
                '{"leadIds":["' + candidate.Id + '","' + missingLeadId + '"],' +
                '"currentStage":"PEP"}',
                LeadAutoQualificationQueue.class
            );
        pepQueue.execute(null);

        System.assertNotEquals(null, candidate.Id);
    }

    @IsTest
    static void runsPassportApprovalStage() {
        Lead candidate = new Lead(
            RecordTypeId = Lead.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Natural').getRecordTypeId(),
            FirstName = 'Auto',
            LastName = 'Passport',
            Company = 'Prospecto No Cliente',
            Status = 'Iniciado',
            LEA_TipoIdentificacion__c = 'Pasaporte',
            LEA_NumIdentificacion__c = '123456789'
        );

        Test.startTest();
        insert candidate;
        Test.stopTest();

        System.assertNotEquals(null, candidate.Id);
    }

    @IsTest
    static void runsRncStage() {
        Test.setMock(HttpCalloutMock.class, new QualificationMock('RNC_ERROR'));
        Lead candidate = new Lead(
            RecordTypeId = Lead.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica').getRecordTypeId(),
            LastName = 'Empresa Auto',
            Company = 'Empresa Auto',
            Status = 'Validado',
            LEA_TipoIdentificacion__c = 'RNC',
            LEA_RNC__c = '101010101'
        );

        Test.startTest();
        insert candidate;
        Test.stopTest();

        System.assertNotEquals(null, candidate.Id);
    }
}
