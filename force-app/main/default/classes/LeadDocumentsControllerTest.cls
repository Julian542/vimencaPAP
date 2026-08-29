@IsTest
private class LeadDocumentsControllerTest {
    @IsTest
    static void exposesEmptyStatesAndModalConfiguration() {
        System.assertEquals(0, LeadDocumentsController.searchDocTypes(null, 'doc').size());
        System.assertEquals(0, LeadDocumentsController.getDocuments(null).size());
        System.assertNotEquals(null, LeadDocumentsController.getDocumentModalFields());

        LeadDocumentsController.SimplePick pick =
            new LeadDocumentsController.SimplePick('id', 'Documento');
        LeadDocumentsController.FieldInfo field =
            new LeadDocumentsController.FieldInfo('DOC_Estado__c', true);
        System.assertEquals('Documento', pick.name);
        System.assert(field.required);
    }

    @IsTest
    static void rejectsIncompleteDocumentCommands() {
        Integer rejected = 0;
        try {
            LeadDocumentsController.createDocumentFromCatalogAfterUpload(null, null, null, null);
        } catch (AuraHandledException expected) {
            rejected++;
        }
        try {
            LeadDocumentsController.updateDocumentAfterUpload(null, null, null);
        } catch (AuraHandledException expected) {
            rejected++;
        }
        try {
            LeadDocumentsController.updateDocumentFieldsOnly(null, null);
        } catch (AuraHandledException expected) {
            rejected++;
        }
        try {
            LeadDocumentsController.approveDocuments(null);
        } catch (AuraHandledException expected) {
            rejected++;
        }
        try {
            LeadDocumentsController.deleteDocumentWithFiles(null);
        } catch (AuraHandledException expected) {
            rejected++;
        }

        System.assertEquals(5, rejected);
    }

    @IsTest
    static void managesDocumentWithoutCatalogOrFile() {
        Datos_Maestros__c economicActivity = new Datos_Maestros__c(
            Name = 'Document Lifecycle Activity',
            DM_Direccion__c = 'DLC001'
        );
        insert economicActivity;
        Lead candidate = new Lead(
            FirstName = 'Documento',
            LastName = 'Lifecycle',
            Company = 'Documento Lifecycle',
            Status = 'Iniciado',
            LEA_NumIdentificacion__c = '00108803555',
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
            LEA_PersonBirthdate__c = Date.today().addYears(-30),
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Actividad_Economica__c = economicActivity.Id,
            LEA_Tipo_Sector__c = 'PRIVADO'
        );
        insert candidate;
        Documentacion_Legal__c document = new Documentacion_Legal__c(
            DOC_Candidato__c = candidate.Id,
            DOC_Codigo_Documento__c = 'TEST-COVERAGE'
        );
        insert document;

        Test.startTest();
        List<LeadDocumentsController.DocRow> rows =
            LeadDocumentsController.getDocuments(candidate.Id);
        Boolean updateRejected = false;
        try {
            LeadDocumentsController.updateDocumentFieldsOnly(
                document.Id,
                JSON.serialize(new Map<String, Object>{
                    'DOC_Fecha_Recepcion__c' => String.valueOf(Date.today()),
                    'Campo_Inexistente__c' => 'ignorado'
                })
            );
        } catch (AuraHandledException expected) {
            updateRejected = true;
        }

        Boolean approvalRejected = false;
        try {
            LeadDocumentsController.approveDocuments(new List<Id>{ document.Id });
        } catch (AuraHandledException expected) {
            approvalRejected = true;
        }

        LeadDocumentsController.deleteDocumentWithFiles(document.Id);
        Test.stopTest();

        System.assertEquals(1, rows.size());
        System.assertEquals('Documento TEST-COVERAGE', rows[0].documentName);
        System.assert(updateRejected);
        System.assert(approvalRejected);
        System.assertEquals(0, [SELECT COUNT() FROM Documentacion_Legal__c WHERE Id = :document.Id]);
    }

    @IsTest
    static void createsUpdatesAndApprovesDocumentWithFile() {
        Datos_Maestros__c economicActivity = new Datos_Maestros__c(
            Name = 'Document Upload Activity',
            DM_Direccion__c = 'DUP001'
        );
        insert economicActivity;
        Lead candidate = new Lead(
            FirstName = 'Archivo',
            LastName = 'Documento',
            Company = 'Documento Archivo',
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Natural').getRecordTypeId(),
            Status = 'Iniciado',
            LEA_NumIdentificacion__c = '00108803556',
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
            LEA_PersonBirthdate__c = Date.today().addYears(-30),
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Actividad_Economica__c = economicActivity.Id,
            LEA_Tipo_Sector__c = 'PRIVADO'
        );
        insert candidate;

        Admin_Doc_Requerida__c documentType = new Admin_Doc_Requerida__c(
            ADR_Nombre_de_documento__c = 'Comprobante de prueba',
            ADR_Entidad__c = 'Persona Física',
            ADR_Tipo__c = 'Cédula'
        );
        insert documentType;

        ContentVersion initialVersion = new ContentVersion(
            Title = 'comprobante-inicial',
            PathOnClient = 'comprobante-inicial.pdf',
            VersionData = Blob.valueOf('contenido inicial')
        );
        insert initialVersion;
        Id initialDocumentId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :initialVersion.Id
        ].ContentDocumentId;

        ContentVersion replacementVersion = new ContentVersion(
            Title = 'comprobante-reemplazo',
            PathOnClient = 'comprobante-reemplazo.pdf',
            VersionData = Blob.valueOf('contenido reemplazo')
        );
        insert replacementVersion;
        Id replacementDocumentId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :replacementVersion.Id
        ].ContentDocumentId;

        String receivedFields = JSON.serialize(new Map<String, Object>{
            'DOC_Fecha_Recepcion__c' => String.valueOf(Date.today()),
            'DOC_Estado__c' => 'PENDIENTE',
            'DOC_Descripcion__c' => 'Documento cargado desde test'
        });

        Test.startTest();
        Test.setFixedSearchResults(new List<Id>{ documentType.Id });
        List<LeadDocumentsController.SimplePick> documentTypes =
            LeadDocumentsController.searchDocTypes(candidate.Id, 'Co');
        Id legalDocumentId = LeadDocumentsController.createDocumentFromCatalogAfterUpload(
            candidate.Id,
            documentType.Id,
            initialDocumentId,
            receivedFields
        );
        LeadDocumentsController.updateDocumentAfterUpload(
            legalDocumentId,
            replacementDocumentId,
            JSON.serialize(new Map<String, Object>{
                'DOC_Fecha_Recepcion__c' => String.valueOf(Date.today()),
                'DOC_Estado__c' => 'PENDIENTE',
                'DOC_Descripcion__c' => 'Documento reemplazado desde test'
            })
        );
        LeadDocumentsController.updateDocumentFieldsOnly(
            legalDocumentId,
            JSON.serialize(new Map<String, Object>{
                'DOC_Fecha_Recepcion__c' => String.valueOf(Date.today()),
                'DOC_Estado__c' => 'PENDIENTE',
                'DOC_Descripcion__c' => 'Documento actualizado desde test'
            })
        );
        LeadDocumentsController.approveDocuments(new List<Id>{ legalDocumentId });
        Test.stopTest();

        Documentacion_Legal__c legalDocument = [
            SELECT DOC_Estado__c, DOC_Recibido__c, DOC_Aprobado_Por__c
            FROM Documentacion_Legal__c
            WHERE Id = :legalDocumentId
        ];
        System.assertEquals('APROBADO', legalDocument.DOC_Estado__c);
        System.assertEquals(true, legalDocument.DOC_Recibido__c);
        System.assertEquals(UserInfo.getUserId(), legalDocument.DOC_Aprobado_Por__c);
        System.assertEquals(1, documentTypes.size());
        System.assertEquals('Comprobante de prueba', documentTypes[0].name);
        System.assertEquals(
            1,
            [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :legalDocumentId]
        );
    }

    @IsTest
    static void generatesRequiredDocumentsAndAvoidsNormalDuplicates() {
        Datos_Maestros__c economicActivity = new Datos_Maestros__c(
            Name = 'Required Documents Activity',
            DM_Direccion__c = 'RDA001'
        );
        insert economicActivity;

        Lead candidate = new Lead(
            FirstName = 'Required',
            LastName = 'Documents',
            Company = 'Required Documents',
            RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName()
                .get('Candidato_Persona_Natural').getRecordTypeId(),
            Status = 'Iniciado',
            LEA_NumIdentificacion__c = '00108803557',
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
            LEA_PersonBirthdate__c = Date.today().addYears(-30),
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Actividad_Economica__c = economicActivity.Id,
            LEA_Tipo_Sector__c = 'PRIVADO'
        );
        insert candidate;

        insert new List<Admin_Doc_Requerida__c>{
            new Admin_Doc_Requerida__c(
                ADR_Nombre_de_documento__c = 'Documento obligatorio',
                ADR_Entidad__c = 'Persona Física',
                ADR_Tipo__c = 'Cédula',
                ADR_Requerido__c = true
            ),
            new Admin_Doc_Requerida__c(
                ADR_Nombre_de_documento__c = '  documento   obligatorio  ',
                ADR_Entidad__c = 'Persona Física',
                ADR_Tipo__c = 'Cédula',
                ADR_Requerido__c = true
            ),
            new Admin_Doc_Requerida__c(
                ADR_Nombre_de_documento__c = 'OTRO soporte',
                ADR_Entidad__c = 'Persona Física',
                ADR_Tipo__c = 'Cédula',
                ADR_Requerido__c = true
            )
        };

        Test.startTest();
        List<LeadDocumentsController.DocRow> firstLoad =
            LeadDocumentsController.getDocuments(candidate.Id);
        List<LeadDocumentsController.DocRow> secondLoad =
            LeadDocumentsController.getDocuments(candidate.Id);
        Test.stopTest();

        System.assertEquals(2, firstLoad.size());
        System.assertEquals(2, secondLoad.size());
        System.assertEquals(
            2,
            [SELECT COUNT() FROM Documentacion_Legal__c WHERE DOC_Candidato__c = :candidate.Id]
        );
    }
}
