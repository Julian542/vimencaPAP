@IsTest
private class FSC_RlaApprovalAdminRestTest {
    private static final String SUBESTADO_ANALISIS = 'An\u00E1lisis de cr\u00E9dito';

    private static ResidentialLoanApplication createRla() {
        Account acc = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Juridica')
                .getRecordTypeId(),
            Name = 'Cuenta Rest ' + System.now().getTime(),
            ACC_NumIdentificacion__c = '00108803610',
            ACC_RNC__c = 'RLAREST' + String.valueOf(System.now().getTime()).right(6),
            ACC_Condicion__c = 'PROSPECTO',
            ACC_Estado__c = 'INICIADO',
            ACC_TipoIdentificacion__c = 'RNC'
        );
        insert acc;

        ResidentialLoanApplication rla = new ResidentialLoanApplication(
            Name = 'RLA Rest ' + System.now().getTime(),
            AccountId = acc.Id,
            RecordTypeId = Schema.SObjectType.ResidentialLoanApplication.getRecordTypeInfosByDeveloperName()
                .get('FSC_Solicitud_Credito_Consumo')
                .getRecordTypeId(),
            Status = 'En proceso',
            FSC_Subestado__c = SUBESTADO_ANALISIS,
            FSC_ActoNumeroPagare__c = 'ACTREST',
            FSC_Pagares_y_Plantillas_Generados__c = false,
            FSC_Monto__c = 5000,
            FSC_Plazo_meses__c = '24',
            FSC_TasaInteres__c = 14,
            FSC_Aprobado_con_Condiciones__c = false,
            FSC_lineaFinanciera__c = '32',
            FSC_subAplicacion__c = '401'
        );
        insert rla;
        return rla;
    }

    @IsTest
    static void sendToSupervisor_marksFlag() {
        ResidentialLoanApplication rla = createRla();

        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/fsc/rla-approval-admin/supervisor-review';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(
            '{"residentialLoanApplicationId":"' + rla.Id + '"}'
        );
        RestContext.response = new RestResponse();

        Test.startTest();
        FSC_RlaApprovalAdminRest.sendToSupervisor();
        Test.stopTest();

        ResidentialLoanApplication refreshed = [
            SELECT FSC_DebeRevisarSupervisor__c
            FROM ResidentialLoanApplication
            WHERE Id = :rla.Id
        ];

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(true, refreshed.FSC_DebeRevisarSupervisor__c);
    }

    @IsTest
    static void sendToSupervisor_returnsBadRequestWhenMissingId() {
        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/fsc/rla-approval-admin/supervisor-review';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf('{}');
        RestContext.response = new RestResponse();

        Test.startTest();
        FSC_RlaApprovalAdminRest.sendToSupervisor();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Solicitud requerida'));
    }

    @IsTest
    static void returnToAnalyst_updatesFields() {
        ResidentialLoanApplication rla = createRla();
        update new ResidentialLoanApplication(
            Id = rla.Id,
            FSC_DebeRevisarSupervisor__c = true
        );

        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/fsc/rla-approval-admin/return-to-analyst';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(
            '{"residentialLoanApplicationId":"' + rla.Id + '","motivo":"volver a analista"}'
        );
        RestContext.response = new RestResponse();

        Test.startTest();
        FSC_RlaApprovalAdminReturnToAnalystRest.returnToAnalyst();
        Test.stopTest();

        ResidentialLoanApplication refreshed = [
            SELECT FSC_DebeRevisarSupervisor__c, FSC_ObservacionSupervisor__c
            FROM ResidentialLoanApplication
            WHERE Id = :rla.Id
        ];

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(false, refreshed.FSC_DebeRevisarSupervisor__c);
        System.assertEquals('volver a analista', refreshed.FSC_ObservacionSupervisor__c);
    }

    @IsTest
    static void returnToAnalyst_returnsBadRequestWhenMissingMotivo() {
        ResidentialLoanApplication rla = createRla();

        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/fsc/rla-approval-admin/return-to-analyst';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(
            '{"residentialLoanApplicationId":"' + rla.Id + '"}'
        );
        RestContext.response = new RestResponse();

        Test.startTest();
        FSC_RlaApprovalAdminReturnToAnalystRest.returnToAnalyst();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Motivo requerido'));
    }

    @IsTest
    static void returnToAnalyst_returnsBadRequestWhenMissingId() {
        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/fsc/rla-approval-admin/return-to-analyst';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf('{"motivo":"sin solicitud"}');
        RestContext.response = new RestResponse();

        Test.startTest();
        FSC_RlaApprovalAdminReturnToAnalystRest.returnToAnalyst();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Solicitud requerida'));
    }

    @IsTest
    static void returnToAnalyst_returnsServerErrorForInvalidJson() {
        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/fsc/rla-approval-admin/return-to-analyst';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf('{');
        RestContext.response = new RestResponse();

        Test.startTest();
        FSC_RlaApprovalAdminReturnToAnalystRest.returnToAnalyst();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('"success":false'));
    }

    @IsTest
    static void returnToBusiness_updatesFields() {
        ResidentialLoanApplication rla = createRla();
        update new ResidentialLoanApplication(
            Id = rla.Id,
            FSC_DebeRevisarSupervisor__c = true,
            FSC_DebeRevisarComite__c = true,
            FSC_Doc_Completa_Analisis__c = true
        );

        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/fsc/rla-approval-admin/return-to-business';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(
            '{"residentialLoanApplicationId":"' + rla.Id + '","motivo":"volver a oficial","profileName":"Supervisor"}'
        );
        RestContext.response = new RestResponse();

        Test.startTest();
        FSC_RlaApprovalAdminReturnToBusinessRest.returnToBusiness();
        Test.stopTest();

        ResidentialLoanApplication refreshed = [
            SELECT FSC_DebeRevisarSupervisor__c,
                   FSC_DebeRevisarComite__c,
                   FSC_Doc_Completa_Analisis__c,
                   FSC_Subestado__c,
                   FSC_ObservacionSupervisor__c
            FROM ResidentialLoanApplication
            WHERE Id = :rla.Id
        ];

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(false, refreshed.FSC_DebeRevisarSupervisor__c);
        System.assertEquals(false, refreshed.FSC_DebeRevisarComite__c);
        System.assertEquals(false, refreshed.FSC_Doc_Completa_Analisis__c);
        System.assertEquals('Recepción de documentos – Análisis', refreshed.FSC_Subestado__c);
        System.assertEquals('volver a oficial', refreshed.FSC_ObservacionSupervisor__c);
    }

    @IsTest
    static void returnToBusiness_returnsBadRequestWhenMissingMotivo() {
        ResidentialLoanApplication rla = createRla();

        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/fsc/rla-approval-admin/return-to-business';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(
            '{"residentialLoanApplicationId":"' + rla.Id + '"}'
        );
        RestContext.response = new RestResponse();

        Test.startTest();
        FSC_RlaApprovalAdminReturnToBusinessRest.returnToBusiness();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Motivo requerido'));
    }

    @IsTest
    static void returnToBusiness_returnsBadRequestWhenMissingId() {
        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/fsc/rla-approval-admin/return-to-business';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf('{"motivo":"sin solicitud","profileName":"Supervisor"}');
        RestContext.response = new RestResponse();

        Test.startTest();
        FSC_RlaApprovalAdminReturnToBusinessRest.returnToBusiness();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Solicitud requerida'));
    }

    @IsTest
    static void returnToBusiness_returnsServerErrorForInvalidJson() {
        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/fsc/rla-approval-admin/return-to-business';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf('{');
        RestContext.response = new RestResponse();

        Test.startTest();
        FSC_RlaApprovalAdminReturnToBusinessRest.returnToBusiness();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('"success":false'));
    }
}
