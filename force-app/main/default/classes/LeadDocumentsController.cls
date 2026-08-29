public with sharing class LeadDocumentsController {

    public class SimplePick {
        @AuraEnabled public String id;
        @AuraEnabled public String name;

        public SimplePick(String i, String n) {
            id = i;
            name = n;
        }
    }

    public class DocRow {
        @AuraEnabled public String id;
        @AuraEnabled public String documentName;
        @AuraEnabled public String estado;
        @AuraEnabled public String subEstado;
        @AuraEnabled public String recibidoLabel;
        @AuraEnabled public String fechaVencimiento;
        @AuraEnabled public List<FileRow> files;

        public DocRow() {}
    }

    public class FileRow {
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String title;
        @AuraEnabled public String fileType;

        public FileRow() {}
    }

    public class FieldInfo {
        @AuraEnabled public String apiName;
        @AuraEnabled public Boolean required;

        public FieldInfo(String a, Boolean r) {
            apiName = a;
            required = r;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SimplePick> searchDocTypes(Id leadId, String searchKey) {
        if (leadId == null) {
            return new List<SimplePick>();
        }

        if (String.isBlank(searchKey) || searchKey.trim().length() < 2) {
            return new List<SimplePick>();
        }

        Lead l = [
            SELECT Id, RecordType.DeveloperName, LEA_Clasificacion_Empresa__c, LEA_TipoIdentificacion__c
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];

        String rtDev = (l.RecordType == null) ? null : String.valueOf(l.RecordType.DeveloperName);
        Boolean isPF = isPFByRecordType(rtDev);
        String entidad = isPF ? 'Persona Física' : 'Persona Jurídica';
        String tipoDocumento = isPF ? l.LEA_TipoIdentificacion__c : l.LEA_Clasificacion_Empresa__c;

        if (String.isBlank(tipoDocumento)) {
            return new List<SimplePick>();
        }

        String term = String.escapeSingleQuotes(searchKey.trim()) + '*';

        String sosl =
            'FIND \'' + term + '\' IN ALL FIELDS ' +
            'RETURNING Admin_Doc_Requerida__c(' +
                'Id, Name, ADR_Nombre_de_documento__c, ADR_Tipo__c, ADR_Entidad__c ' +
                'WHERE ADR_Entidad__c = \'' + String.escapeSingleQuotes(entidad) + '\' ' +
                'AND ADR_Tipo__c = \'' + String.escapeSingleQuotes(tipoDocumento) + '\'' +
            ') ' +
            'LIMIT 25';

        List<List<SObject>> res = Search.query(sosl);

        List<SimplePick> out = new List<SimplePick>();

        if (res != null && !res.isEmpty()) {
            for (SObject s : res[0]) {
                Admin_Doc_Requerida__c r = (Admin_Doc_Requerida__c) s;

                String label = !String.isBlank(r.ADR_Nombre_de_documento__c)
                    ? r.ADR_Nombre_de_documento__c
                    : (!String.isBlank(r.ADR_Tipo__c) ? r.ADR_Tipo__c : r.Name);

                out.add(new SimplePick(r.Id, label));
            }
        }

        return out;
    }

    @AuraEnabled
    public static List<DocRow> getDocuments(Id leadId) {
        System.debug('LeadDocumentsController.getDocuments() leadId=' + leadId);

        if (leadId == null) {
            return new List<DocRow>();
        }

        Lead l = [
            SELECT Id, RecordType.DeveloperName, RecordType.Name, LEA_Clasificacion_Empresa__c, LEA_TipoIdentificacion__c
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];

        String rtDev = (l.RecordType == null) ? null : String.valueOf(l.RecordType.DeveloperName);
        String rtName = (l.RecordType == null) ? null : String.valueOf(l.RecordType.Name);
        Boolean isPF = isPFByRecordType(rtDev);
        String tipoDocumento = isPF ? l.LEA_TipoIdentificacion__c : l.LEA_Clasificacion_Empresa__c;

        createMissingRequiredDocuments(leadId, rtDev, rtName, isPF, tipoDocumento);

        List<Documentacion_Legal__c> docs = [
            SELECT Id,
                   DOC_Estado__c,
                   DOC_Sub_Estado__c,
                   DOC_Recibido__c,
                   DOC_Fecha_Vencimiento__c,
                   DOC_Documento_PF__c,
                   DOC_Documento_PJ__c,
                   DOC_Documento_PF__r.ADR_Nombre_de_documento__c,
                   DOC_Documento_PF__r.Name,
                   DOC_Documento_PJ__r.ADR_Nombre_de_documento__c,
                   DOC_Documento_PJ__r.Name,
                   DOC_Codigo_Documento__c,
                   CreatedDate
            FROM Documentacion_Legal__c
            WHERE DOC_Candidato__c = :leadId
            ORDER BY CreatedDate ASC
            LIMIT 200
        ];

        Set<Id> docIds = new Set<Id>();

        for (Documentacion_Legal__c d : docs) {
            docIds.add(d.Id);
        }

        Map<Id, List<FileRow>> filesByDocId = new Map<Id, List<FileRow>>();

        if (!docIds.isEmpty()) {
            for (ContentDocumentLink cdl : [
                SELECT LinkedEntityId,
                       ContentDocumentId,
                       ContentDocument.Title,
                       ContentDocument.FileType
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :docIds
                ORDER BY ContentDocument.CreatedDate DESC
            ]) {
                FileRow f = new FileRow();
                f.contentDocumentId = String.valueOf(cdl.ContentDocumentId);
                f.title = cdl.ContentDocument.Title;
                f.fileType = cdl.ContentDocument.FileType;

                if (!filesByDocId.containsKey(cdl.LinkedEntityId)) {
                    filesByDocId.put(cdl.LinkedEntityId, new List<FileRow>());
                }

                filesByDocId.get(cdl.LinkedEntityId).add(f);
            }
        }

        List<DocRow> out = new List<DocRow>();
        Set<String> displayedNormalDocumentNames = new Set<String>();

        for (Documentacion_Legal__c d : docs) {
            String namePF = d.DOC_Documento_PF__r != null
                ? d.DOC_Documento_PF__r.ADR_Nombre_de_documento__c
                : null;

            String namePJ = d.DOC_Documento_PJ__r != null
                ? d.DOC_Documento_PJ__r.ADR_Nombre_de_documento__c
                : null;

            String fallbackPF = d.DOC_Documento_PF__r != null
                ? d.DOC_Documento_PF__r.Name
                : null;

            String fallbackPJ = d.DOC_Documento_PJ__r != null
                ? d.DOC_Documento_PJ__r.Name
                : null;

            String dn = isPF ? namePF : namePJ;

            if (String.isBlank(dn)) {
                dn = isPF ? fallbackPF : fallbackPJ;
            }

            if (String.isBlank(dn)) {
                dn = String.isBlank(d.DOC_Codigo_Documento__c)
                    ? 'Documento Legal'
                    : ('Documento ' + d.DOC_Codigo_Documento__c);
            }

            Boolean isOtro = isOtroDocumentName(dn);
            String normalizedName = normalizeDocumentName(dn);

            if (!isOtro && displayedNormalDocumentNames.contains(normalizedName)) {
                System.debug('LeadDocumentsController.getDocuments() documento duplicado omitido visualmente=' + dn + ', documentacionLegalId=' + d.Id);
                continue;
            }

            if (!isOtro) {
                displayedNormalDocumentNames.add(normalizedName);
            }

            DocRow r = new DocRow();
            r.id = String.valueOf(d.Id);
            r.documentName = dn;
            r.estado = String.isBlank(d.DOC_Estado__c) ? 'Pendiente' : d.DOC_Estado__c;
            r.subEstado = String.isBlank(d.DOC_Sub_Estado__c) ? 'Pendiente' : d.DOC_Sub_Estado__c;
            r.recibidoLabel = (d.DOC_Recibido__c == true) ? 'Sí' : 'No';
            r.fechaVencimiento = d.DOC_Fecha_Vencimiento__c == null
                ? null
                : String.valueOf(d.DOC_Fecha_Vencimiento__c);

            r.files = filesByDocId.containsKey(d.Id)
                ? filesByDocId.get(d.Id)
                : new List<FileRow>();

            out.add(r);
        }

        return out;
    }

    /**
     * Retorna true solamente cuando cada documento requerido en el catÃ¡logo
     * tiene un registro de Documentacion_Legal__c y al menos un archivo enlazado.
     */
    public static Boolean hasAllRequiredDocumentsUploaded(Id leadId) {
        if (leadId == null) {
            return false;
        }

        Lead candidate = [
            SELECT Id, RecordType.DeveloperName, LEA_Clasificacion_Empresa__c,
                   LEA_TipoIdentificacion__c
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];

        String recordTypeDeveloperName = candidate.RecordType == null
            ? null
            : candidate.RecordType.DeveloperName;
        Boolean isPF = isPFByRecordType(recordTypeDeveloperName);
        String entityType = isPF ? 'Persona Física' : 'Persona Jurídica';
        String documentType = isPF
            ? candidate.LEA_TipoIdentificacion__c
            : candidate.LEA_Clasificacion_Empresa__c;

        if (String.isBlank(documentType)) {
            return false;
        }

        Set<String> requiredDocumentNames = new Set<String>();
        for (Admin_Doc_Requerida__c catalogDocument : [
            SELECT Id, Name, ADR_Nombre_de_documento__c
            FROM Admin_Doc_Requerida__c
            WHERE ADR_Entidad__c = :entityType
            AND ADR_Tipo__c = :documentType
            AND ADR_Requerido__c = true
        ]) {
            String documentName = !String.isBlank(catalogDocument.ADR_Nombre_de_documento__c)
                ? catalogDocument.ADR_Nombre_de_documento__c
                : catalogDocument.Name;
            requiredDocumentNames.add(normalizeDocumentName(documentName));
        }

        if (requiredDocumentNames.isEmpty()) {
            return false;
        }

        Map<Id, String> documentNameByRecordId = new Map<Id, String>();
        for (Documentacion_Legal__c documentRecord : [
            SELECT Id,
                   DOC_Documento_PF__r.ADR_Nombre_de_documento__c,
                   DOC_Documento_PF__r.Name,
                   DOC_Documento_PJ__r.ADR_Nombre_de_documento__c,
                   DOC_Documento_PJ__r.Name
            FROM Documentacion_Legal__c
            WHERE DOC_Candidato__c = :leadId
        ]) {
            String documentName = getDocumentNameFromDocumentacionLegal(documentRecord, isPF);
            if (!String.isBlank(documentName)) {
                documentNameByRecordId.put(documentRecord.Id, normalizeDocumentName(documentName));
            }
        }

        if (documentNameByRecordId.isEmpty()) {
            return false;
        }

        Set<String> uploadedDocumentNames = new Set<String>();
        Set<Id> documentRecordIds = documentNameByRecordId.keySet();
        for (ContentDocumentLink fileLink : [
            SELECT LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :documentRecordIds
        ]) {
            uploadedDocumentNames.add(documentNameByRecordId.get(fileLink.LinkedEntityId));
        }

        return uploadedDocumentNames.containsAll(requiredDocumentNames);
    }

    @AuraEnabled(cacheable=true)
    public static List<FieldInfo> getDocumentModalFields() {
        List<FieldInfo> out = new List<FieldInfo>();

        Schema.DescribeSObjectResult d = Documentacion_Legal__c.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fmap = d.fields.getMap();

        List<String> ordered = new List<String>{
            'DOC_Estado__c',
            'DOC_Sub_Estado__c',
            'DOC_Recibido__c',
            'DOC_Fecha_Recepcion__c',
            'DOC_Fecha_Recepcion_Legal__c',
            'DOC_Fecha_Aprobacion_Legal__c',
            'DOC_Fecha_Vencimiento__c',
            'DOC_Descripcion__c',
            'DOC_Aprobado_Por__c'
        };

        for (String api : ordered) {
            if (fmap.containsKey(api)) {
                Schema.DescribeFieldResult fd = fmap.get(api).getDescribe();

                Boolean required =
                    (!fd.isNillable() && !fd.isDefaultedOnCreate()) ||
                    api == 'DOC_Fecha_Recepcion__c';

                out.add(new FieldInfo(api, required));
            }
        }

        return out;
    }

    @AuraEnabled
    public static Id createDocumentFromCatalogAfterUpload(
        Id leadId,
        Id docTypeId,
        Id contentDocumentId,
        String fieldsJson
    ) {
        System.debug('LeadDocumentsController.createDocumentFromCatalogAfterUpload() leadId=' + leadId + ', docTypeId=' + docTypeId + ', contentDocumentId=' + contentDocumentId);

        if (leadId == null) {
            throw new AuraHandledException('leadId es requerido.');
        }

        if (docTypeId == null) {
            throw new AuraHandledException('docTypeId es requerido.');
        }

        if (contentDocumentId == null) {
            throw new AuraHandledException('Debe cargar un archivo.');
        }

        try {
            Lead l = [
                SELECT Id, RecordType.DeveloperName
                FROM Lead
                WHERE Id = :leadId
                LIMIT 1
            ];

            Admin_Doc_Requerida__c adminDoc = [
                SELECT Id, Name, ADR_Nombre_de_documento__c
                FROM Admin_Doc_Requerida__c
                WHERE Id = :docTypeId
                LIMIT 1
            ];

            String rtDev = (l.RecordType == null) ? null : String.valueOf(l.RecordType.DeveloperName);
            Boolean isPF = isPFByRecordType(rtDev);
            String docName = !String.isBlank(adminDoc.ADR_Nombre_de_documento__c)
                ? adminDoc.ADR_Nombre_de_documento__c
                : adminDoc.Name;

            Documentacion_Legal__c doc;
            Id existingDocumentId = isOtroDocumentName(docName)
                ? null
                : getExistingDocumentId(leadId, docTypeId, isPF);

            if (existingDocumentId != null) {
                doc = new Documentacion_Legal__c(Id = existingDocumentId);
            } else {
                doc = new Documentacion_Legal__c();
                doc.DOC_Candidato__c = leadId;

                if (isPF) {
                    doc.DOC_Documento_PF__c = docTypeId;
                } else {
                    doc.DOC_Documento_PJ__c = docTypeId;
                }
            }

            applyFieldsToDocument(doc, fieldsJson);

            setApprovalDataIfApproved(doc);

            validateRequiredDates(doc);

            Schema.DescribeSObjectResult d = Documentacion_Legal__c.SObjectType.getDescribe();
            Map<String, Schema.SObjectField> fmap = d.fields.getMap();

            if (fmap.containsKey('DOC_Recibido__c')) {
                if (existingDocumentId == null && fmap.get('DOC_Recibido__c').getDescribe().isCreateable()) {
                    doc.DOC_Recibido__c = true;
                } else if (existingDocumentId != null && fmap.get('DOC_Recibido__c').getDescribe().isUpdateable()) {
                    doc.DOC_Recibido__c = true;
                }
            }

            if (existingDocumentId == null) {
                insert doc;
            } else {
                update doc;
            }

            relinkSingleFileToDocument(doc.Id, leadId, contentDocumentId);
            AccountLookupController.submitLegalApprovalForParticipantLeadIfRequired(leadId);

            return doc.Id;

        } catch (Exception e) {
            System.debug('ERROR LeadDocumentsController.createDocumentFromCatalogAfterUpload: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateDocumentAfterUpload(
        Id documentacionLegalId,
        Id contentDocumentId,
        String fieldsJson
    ) {
        System.debug('LeadDocumentsController.updateDocumentAfterUpload() documentacionLegalId=' + documentacionLegalId + ', contentDocumentId=' + contentDocumentId);

        if (documentacionLegalId == null) {
            throw new AuraHandledException('documentacionLegalId es requerido.');
        }

        if (contentDocumentId == null) {
            throw new AuraHandledException('Debe cargar un archivo.');
        }

        try {
            Documentacion_Legal__c existingDoc = [
                SELECT Id, DOC_Candidato__c
                FROM Documentacion_Legal__c
                WHERE Id = :documentacionLegalId
                LIMIT 1
            ];

            Documentacion_Legal__c doc = new Documentacion_Legal__c(Id = documentacionLegalId);

            applyFieldsToDocument(doc, fieldsJson);

            setApprovalDataIfApproved(doc);

            validateRequiredDates(doc);

            Schema.DescribeSObjectResult d = Documentacion_Legal__c.SObjectType.getDescribe();
            Map<String, Schema.SObjectField> fmap = d.fields.getMap();

            if (fmap.containsKey('DOC_Recibido__c') && fmap.get('DOC_Recibido__c').getDescribe().isUpdateable()) {
                doc.DOC_Recibido__c = true;
            }

            update doc;

            relinkSingleFileToDocument(documentacionLegalId, existingDoc.DOC_Candidato__c, contentDocumentId);
            AccountLookupController.submitLegalApprovalForParticipantLeadIfRequired(
                existingDoc.DOC_Candidato__c
            );

        } catch (Exception e) {
            System.debug('ERROR LeadDocumentsController.updateDocumentAfterUpload: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateDocumentFieldsOnly(Id documentacionLegalId, String fieldsJson) {
        validateLegalDocumentManagementAccess();
        System.debug('LeadDocumentsController.updateDocumentFieldsOnly() documentacionLegalId=' + documentacionLegalId);

        if (documentacionLegalId == null) {
            throw new AuraHandledException('documentacionLegalId es requerido.');
        }

        try {
            Documentacion_Legal__c doc = new Documentacion_Legal__c(Id = documentacionLegalId);

            applyFieldsToDocument(doc, fieldsJson);

            setApprovalDataIfApproved(doc);

            validateRequiredDates(doc);

            update doc;

        } catch (Exception e) {
            System.debug('ERROR LeadDocumentsController.updateDocumentFieldsOnly: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void approveDocuments(List<Id> documentacionLegalIds) {
        validateLegalDocumentManagementAccess();
        System.debug('LeadDocumentsController.approveDocuments() documentacionLegalIds=' + documentacionLegalIds);

        if (documentacionLegalIds == null || documentacionLegalIds.isEmpty()) {
            throw new AuraHandledException('Debe seleccionar al menos un documento.');
        }

        try {
            Set<Id> docIds = new Set<Id>();
            docIds.addAll(documentacionLegalIds);

            List<Documentacion_Legal__c> docs = [
                SELECT Id,
                    Name,
                    DOC_Candidato__c,
                    DOC_Estado__c,
                    DOC_Recibido__c,
                    DOC_Aprobado_Por__c,
                    DOC_Fecha_Aprobacion_Legal__c,
                    DOC_Documento_PF__c,
                    DOC_Documento_PJ__c,
                    DOC_Documento_PF__r.ADR_Nombre_de_documento__c,
                    DOC_Documento_PF__r.Name,
                    DOC_Documento_PJ__r.ADR_Nombre_de_documento__c,
                    DOC_Documento_PJ__r.Name,
                    DOC_Codigo_Documento__c
                FROM Documentacion_Legal__c
                WHERE Id IN :docIds
            ];

            validateCompleteLegalSelection(docs, docIds);

            Set<Id> docIdsConArchivo = new Set<Id>();

            for (ContentDocumentLink cdl : [
                SELECT Id, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :docIds
            ]) {
                if (cdl.LinkedEntityId != null) {
                    docIdsConArchivo.add(cdl.LinkedEntityId);
                }
            }

            List<String> documentosSinArchivo = new List<String>();

            for (Documentacion_Legal__c doc : docs) {
                if (!docIdsConArchivo.contains(doc.Id)) {
                    String nombreDocumento = null;

                    if (doc.DOC_Documento_PF__r != null) {
                        nombreDocumento = !String.isBlank(doc.DOC_Documento_PF__r.ADR_Nombre_de_documento__c)
                            ? doc.DOC_Documento_PF__r.ADR_Nombre_de_documento__c
                            : doc.DOC_Documento_PF__r.Name;
                    }

                    if (String.isBlank(nombreDocumento) && doc.DOC_Documento_PJ__r != null) {
                        nombreDocumento = !String.isBlank(doc.DOC_Documento_PJ__r.ADR_Nombre_de_documento__c)
                            ? doc.DOC_Documento_PJ__r.ADR_Nombre_de_documento__c
                            : doc.DOC_Documento_PJ__r.Name;
                    }

                    if (String.isBlank(nombreDocumento)) {
                        nombreDocumento = !String.isBlank(doc.DOC_Codigo_Documento__c)
                            ? 'Documento ' + doc.DOC_Codigo_Documento__c
                            : (!String.isBlank(doc.Name) ? doc.Name : String.valueOf(doc.Id));
                    }

                    documentosSinArchivo.add(nombreDocumento);
                }
            }

            if (!documentosSinArchivo.isEmpty()) {
                throw new AuraHandledException(
                    'Algunos documentos no tienen archivo adjunto. Complete la carga de archivos e intente aprobar nuevamente.'
                );
            }

            List<Documentacion_Legal__c> docsToUpdate = new List<Documentacion_Legal__c>();

            for (Documentacion_Legal__c doc : docs) {
                doc.DOC_Estado__c = 'APROBADO';
                doc.DOC_Recibido__c = true;
                doc.DOC_Aprobado_Por__c = UserInfo.getUserId();
                doc.DOC_Fecha_Aprobacion_Legal__c = Date.today();

                docsToUpdate.add(doc);
            }

            if (!docsToUpdate.isEmpty()) {
                update docsToUpdate;
                System.debug('LeadDocumentsController.approveDocuments() documentos aprobados=' + docsToUpdate.size());
            }

        } catch (AuraHandledException e) {
            System.debug('ERROR LeadDocumentsController.approveDocuments AuraHandledException: ' + e.getMessage());
            throw e;
        } catch (Exception e) {
            System.debug('ERROR LeadDocumentsController.approveDocuments: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteDocumentWithFiles(Id documentacionLegalId) {
        validateLegalDocumentManagementAccess();
        System.debug('LeadDocumentsController.deleteDocumentWithFiles() documentacionLegalId=' + documentacionLegalId);

        if (documentacionLegalId == null) {
            throw new AuraHandledException('documentacionLegalId es requerido.');
        }

        try {
            List<ContentDocumentLink> links = [
                SELECT Id, ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :documentacionLegalId
            ];

            Set<Id> contentDocumentIds = new Set<Id>();

            for (ContentDocumentLink link : links) {
                if (link.ContentDocumentId != null) {
                    contentDocumentIds.add(link.ContentDocumentId);
                }
            }

            if (!links.isEmpty()) {
                delete links;
            }

            delete new Documentacion_Legal__c(Id = documentacionLegalId);

            if (!contentDocumentIds.isEmpty()) {
                List<ContentDocument> docsToDelete = [
                    SELECT Id
                    FROM ContentDocument
                    WHERE Id IN :contentDocumentIds
                ];

                if (!docsToDelete.isEmpty()) {
                    delete docsToDelete;
                }
            }

        } catch (Exception e) {
            System.debug('ERROR LeadDocumentsController.deleteDocumentWithFiles: ' + e.getMessage());
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static void createMissingRequiredDocuments(Id leadId, String rtDev, String rtName, Boolean isPF, String tipoDocumento) {
        System.debug('LeadDocumentsController.createMissingRequiredDocuments() leadId=' + leadId + ', rtDev=' + rtDev + ', rtName=' + rtName + ', isPF=' + isPF);

        if (leadId == null) {
            return;
        }

        String entidad = isPF ? 'Persona Física' : 'Persona Jurídica';

        System.debug('LeadDocumentsController.createMissingRequiredDocuments() entidad=' + entidad);

        if (String.isBlank(tipoDocumento)) {
            System.debug('LeadDocumentsController.createMissingRequiredDocuments() tipoDocumento vacío. No se generan documentos.');
            return;
        }

        List<Admin_Doc_Requerida__c> catalogDocs = [
            SELECT Id,
                   Name,
                   ADR_Nombre_de_documento__c,
                   ADR_Tipo__c,
                   ADR_Entidad__c,
                   ADR_Requerido__c
            FROM Admin_Doc_Requerida__c
            WHERE ADR_Entidad__c = :entidad
            AND ADR_Tipo__c = :tipoDocumento
            AND (
                ADR_Requerido__c = true
                OR ADR_Nombre_de_documento__c LIKE 'OTRO%'
                OR Name LIKE 'OTRO%'
            )
            ORDER BY ADR_Nombre_de_documento__c ASC, CreatedDate ASC
            LIMIT 200
        ];

        System.debug('LeadDocumentsController.createMissingRequiredDocuments() catalogDocs.size=' + catalogDocs.size());

        if (catalogDocs.isEmpty()) {
            System.debug('LeadDocumentsController.createMissingRequiredDocuments() no hay documentos para entidad=' + entidad);
            return;
        }

        Set<Id> catalogDocIds = new Set<Id>();

        for (Admin_Doc_Requerida__c adminDoc : catalogDocs) {
            catalogDocIds.add(adminDoc.Id);
        }

        List<Documentacion_Legal__c> existingDocs;

        if (isPF) {
            existingDocs = [
                SELECT Id,
                       DOC_Documento_PF__c,
                       DOC_Documento_PJ__c,
                       DOC_Documento_PF__r.ADR_Nombre_de_documento__c,
                       DOC_Documento_PF__r.Name,
                       DOC_Documento_PJ__r.ADR_Nombre_de_documento__c,
                       DOC_Documento_PJ__r.Name
                FROM Documentacion_Legal__c
                WHERE DOC_Candidato__c = :leadId
                AND (
                    DOC_Documento_PF__c IN :catalogDocIds
                    OR DOC_Documento_PJ__c IN :catalogDocIds
                )
            ];
        } else {
            existingDocs = [
                SELECT Id,
                       DOC_Documento_PF__c,
                       DOC_Documento_PJ__c,
                       DOC_Documento_PF__r.ADR_Nombre_de_documento__c,
                       DOC_Documento_PF__r.Name,
                       DOC_Documento_PJ__r.ADR_Nombre_de_documento__c,
                       DOC_Documento_PJ__r.Name
                FROM Documentacion_Legal__c
                WHERE DOC_Candidato__c = :leadId
                AND (
                    DOC_Documento_PF__c IN :catalogDocIds
                    OR DOC_Documento_PJ__c IN :catalogDocIds
                )
            ];
        }

        Set<Id> existingCatalogIds = new Set<Id>();
        Set<String> existingNormalDocumentNames = new Set<String>();

        for (Documentacion_Legal__c existingDoc : existingDocs) {
            Id catalogId = isPF ? existingDoc.DOC_Documento_PF__c : existingDoc.DOC_Documento_PJ__c;

            if (catalogId != null) {
                existingCatalogIds.add(catalogId);
            }

            String existingName = getDocumentNameFromDocumentacionLegal(existingDoc, isPF);
            String normalizedExistingName = normalizeDocumentName(existingName);

            if (!isOtroDocumentName(existingName) && !String.isBlank(normalizedExistingName)) {
                existingNormalDocumentNames.add(normalizedExistingName);
            }
        }

        List<Documentacion_Legal__c> docsToInsert = new List<Documentacion_Legal__c>();
        Set<String> catalogNormalNamesAlreadyProcessed = new Set<String>();

        for (Admin_Doc_Requerida__c adminDoc : catalogDocs) {
            String docName = !String.isBlank(adminDoc.ADR_Nombre_de_documento__c)
                ? adminDoc.ADR_Nombre_de_documento__c
                : adminDoc.Name;

            Boolean isOtro = isOtroDocumentName(docName);
            String normalizedDocName = normalizeDocumentName(docName);

            if (isOtro && existingCatalogIds.contains(adminDoc.Id)) {
                System.debug('LeadDocumentsController.createMissingRequiredDocuments() OTRO ya existe por catálogo, se omite. adminDocId=' + adminDoc.Id);
                continue;
            }

            if (!isOtro && existingNormalDocumentNames.contains(normalizedDocName)) {
                System.debug('LeadDocumentsController.createMissingRequiredDocuments() documento normal ya existe por nombre, se omite. nombre=' + docName);
                continue;
            }

            if (!isOtro && catalogNormalNamesAlreadyProcessed.contains(normalizedDocName)) {
                System.debug('LeadDocumentsController.createMissingRequiredDocuments() documento normal duplicado en catálogo, se omite. nombre=' + docName);
                continue;
            }

            Documentacion_Legal__c newDoc = new Documentacion_Legal__c();
            newDoc.DOC_Candidato__c = leadId;

            if (isPF) {
                newDoc.DOC_Documento_PF__c = adminDoc.Id;
            } else {
                newDoc.DOC_Documento_PJ__c = adminDoc.Id;
            }

            docsToInsert.add(newDoc);

            if (!isOtro) {
                catalogNormalNamesAlreadyProcessed.add(normalizedDocName);
                existingNormalDocumentNames.add(normalizedDocName);
            }
        }

        System.debug('LeadDocumentsController.createMissingRequiredDocuments() docsToInsert.size=' + docsToInsert.size());

        if (!docsToInsert.isEmpty()) {
            insert docsToInsert;
            System.debug('LeadDocumentsController.createMissingRequiredDocuments() documentos insertados=' + docsToInsert.size());
        }
    }

    private static Id getExistingDocumentId(Id leadId, Id docTypeId, Boolean isPF) {
        if (leadId == null || docTypeId == null) {
            return null;
        }

        List<Documentacion_Legal__c> docs;

        if (isPF) {
            docs = [
                SELECT Id
                FROM Documentacion_Legal__c
                WHERE DOC_Candidato__c = :leadId
                AND DOC_Documento_PF__c = :docTypeId
                ORDER BY CreatedDate ASC
                LIMIT 1
            ];
        } else {
            docs = [
                SELECT Id
                FROM Documentacion_Legal__c
                WHERE DOC_Candidato__c = :leadId
                AND DOC_Documento_PJ__c = :docTypeId
                ORDER BY CreatedDate ASC
                LIMIT 1
            ];
        }

        return docs.isEmpty() ? null : docs[0].Id;
    }

    @TestVisible
    private static String getDocumentNameFromDocumentacionLegal(Documentacion_Legal__c doc, Boolean isPF) {
        if (doc == null) {
            return null;
        }

        String namePF = doc.DOC_Documento_PF__r != null
            ? doc.DOC_Documento_PF__r.ADR_Nombre_de_documento__c
            : null;

        String namePJ = doc.DOC_Documento_PJ__r != null
            ? doc.DOC_Documento_PJ__r.ADR_Nombre_de_documento__c
            : null;

        String fallbackPF = doc.DOC_Documento_PF__r != null
            ? doc.DOC_Documento_PF__r.Name
            : null;

        String fallbackPJ = doc.DOC_Documento_PJ__r != null
            ? doc.DOC_Documento_PJ__r.Name
            : null;

        String docName = isPF ? namePF : namePJ;

        if (String.isBlank(docName)) {
            docName = isPF ? fallbackPF : fallbackPJ;
        }

        return docName;
    }

    @TestVisible
    private static Boolean isOtroDocumentName(String documentName) {
        if (String.isBlank(documentName)) {
            return false;
        }

        String normalizedName = normalizeDocumentName(documentName);

        return normalizedName == 'OTRO' || normalizedName.startsWith('OTRO ');
    }

    @TestVisible
    private static String normalizeDocumentName(String documentName) {
        if (String.isBlank(documentName)) {
            return null;
        }

        return documentName.trim().replaceAll('\\s+', ' ').toUpperCase();
    }

    private static void relinkSingleFileToDocument(Id documentacionLegalId, Id leadId, Id contentDocumentId) {
        System.debug('LeadDocumentsController.relinkSingleFileToDocument() documentacionLegalId=' + documentacionLegalId + ', leadId=' + leadId + ', contentDocumentId=' + contentDocumentId);

        if (documentacionLegalId == null || contentDocumentId == null) {
            return;
        }

        List<ContentDocumentLink> oldDocLinks = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :documentacionLegalId
            AND ContentDocumentId != :contentDocumentId
        ];

        if (!oldDocLinks.isEmpty()) {
            delete oldDocLinks;
        }

        List<ContentDocumentLink> currentDocLink = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :documentacionLegalId
            AND ContentDocumentId = :contentDocumentId
            LIMIT 1
        ];

        if (currentDocLink.isEmpty()) {
            insert new ContentDocumentLink(
                LinkedEntityId = documentacionLegalId,
                ContentDocumentId = contentDocumentId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
        }

        if (leadId != null) {
            List<ContentDocumentLink> leadLinks = [
                SELECT Id
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :leadId
                AND ContentDocumentId = :contentDocumentId
            ];

            if (!leadLinks.isEmpty()) {
                delete leadLinks;
            }
        }
    }

    @TestVisible
    private static void validateRequiredDates(Documentacion_Legal__c doc) {
        if (doc == null) {
            return;
        }

        if (doc.DOC_Fecha_Recepcion__c == null) {
            throw new AuraHandledException('Debes completar la Fecha de recepción.');
        }
    }

    @TestVisible
    private static void setApprovalDataIfApproved(Documentacion_Legal__c doc) {
        System.debug('LeadDocumentsController.setApprovalDataIfApproved() inicio');

        if (doc == null) {
            return;
        }

        String estadoDocumento = String.valueOf(doc.DOC_Estado__c).trim().toUpperCase();

        if (estadoDocumento != 'APROBADO') {
            System.debug('LeadDocumentsController.setApprovalDataIfApproved() estado no es APROBADO: ' + doc.DOC_Estado__c);
            return;
        }

        Schema.DescribeSObjectResult d = Documentacion_Legal__c.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fmap = d.fields.getMap();

        if (
            fmap.containsKey('DOC_Aprobado_Por__c') &&
            (
                fmap.get('DOC_Aprobado_Por__c').getDescribe().isCreateable() ||
                fmap.get('DOC_Aprobado_Por__c').getDescribe().isUpdateable()
            )
        ) {
            doc.DOC_Aprobado_Por__c = UserInfo.getUserId();
            System.debug('LeadDocumentsController.setApprovalDataIfApproved() DOC_Aprobado_Por__c=' + UserInfo.getUserId());
        }

        if (
            fmap.containsKey('DOC_Fecha_Aprobacion_Legal__c') &&
            (
                fmap.get('DOC_Fecha_Aprobacion_Legal__c').getDescribe().isCreateable() ||
                fmap.get('DOC_Fecha_Aprobacion_Legal__c').getDescribe().isUpdateable()
            )
        ) {
            doc.DOC_Fecha_Aprobacion_Legal__c = Date.today();
            System.debug('LeadDocumentsController.setApprovalDataIfApproved() DOC_Fecha_Aprobacion_Legal__c=' + Date.today());
        }
    }

    @TestVisible
    private static void applyFieldsToDocument(Documentacion_Legal__c doc, String fieldsJson) {
        if (doc == null || String.isBlank(fieldsJson)) {
            return;
        }

        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(fieldsJson);

        if (m == null || m.isEmpty()) {
            return;
        }

        Schema.DescribeSObjectResult d = Documentacion_Legal__c.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fmap = d.fields.getMap();

        for (String k : m.keySet()) {
            if (!fmap.containsKey(k)) {
                continue;
            }

            Schema.DescribeFieldResult fd = fmap.get(k).getDescribe();

            if (!fd.isCreateable() && !fd.isUpdateable()) {
                continue;
            }

            Object v = m.get(k);

            if (v == null) {
                doc.put(k, null);
                continue;
            }

            Schema.DisplayType t = fd.getType();

            if (t == Schema.DisplayType.Date) {
                String s = String.valueOf(v).trim();
                if (!String.isBlank(s)) {
                    doc.put(k, Date.valueOf(s));
                }
                continue;
            }

            if (t == Schema.DisplayType.DateTime) {
                String s = String.valueOf(v).trim();
                if (!String.isBlank(s)) {
                    doc.put(k, Datetime.valueOf(s));
                }
                continue;
            }

            if (t == Schema.DisplayType.Boolean) {
                String s = String.valueOf(v).trim().toLowerCase();
                doc.put(k, (s == 'true' || s == '1' || s == 'yes' || s == 'si' || s == 'sí'));
                continue;
            }

            if (t == Schema.DisplayType.Integer) {
                String s = String.valueOf(v).trim();
                if (!String.isBlank(s)) {
                    doc.put(k, Integer.valueOf(s));
                }
                continue;
            }

            if (
                t == Schema.DisplayType.Double ||
                t == Schema.DisplayType.Currency ||
                t == Schema.DisplayType.Percent
            ) {
                String s = String.valueOf(v).trim();
                if (!String.isBlank(s)) {
                    doc.put(k, Decimal.valueOf(s));
                }
                continue;
            }

            doc.put(k, v);
        }
    }

    @TestVisible
    private static void validateCompleteLegalSelection(
        List<Documentacion_Legal__c> selectedDocuments,
        Set<Id> selectedDocumentIds
    ) {
        Set<Id> candidateIds = new Set<Id>();
        for (Documentacion_Legal__c document : selectedDocuments) {
            if (document.DOC_Candidato__c != null) {
                candidateIds.add(document.DOC_Candidato__c);
            }
        }

        if (candidateIds.isEmpty()) {
            return;
        }

        List<Group> legalQueues = [
            SELECT Id
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'FSC_Legal'
            LIMIT 1
        ];
        if (legalQueues.isEmpty()) {
            return;
        }
        Id legalQueueId = legalQueues[0].Id;

        Integer pendingLegalWorkItems = [
            SELECT COUNT()
            FROM ProcessInstanceWorkitem
            WHERE ActorId = :legalQueueId
            AND ProcessInstance.TargetObjectId IN :candidateIds
            AND ProcessInstance.Status = 'Pending'
        ];
        if (pendingLegalWorkItems == 0) {
            return;
        }

        Set<Id> allCandidateDocumentIds = new Map<Id, Documentacion_Legal__c>([
            SELECT Id
            FROM Documentacion_Legal__c
            WHERE DOC_Candidato__c IN :candidateIds
        ]).keySet();

        if (!selectedDocumentIds.containsAll(allCandidateDocumentIds)) {
            throw new AuraHandledException(
                'Legal debe seleccionar todos los documentos del candidato antes de completar la aprobación final.'
            );
        }
    }

    @TestVisible
    private static void validateLegalDocumentManagementAccess() {
        if (FeatureManagement.checkPermission('FSC_VIMENCA_GESTION_DOCUMENTOS_LEGAL')) {
            return;
        }

        Profile currentProfile = [
            SELECT PermissionsModifyAllData
            FROM Profile
            WHERE Id = :UserInfo.getProfileId()
            LIMIT 1
        ];

        if (!currentProfile.PermissionsModifyAllData) {
            throw new AuraHandledException('No tienes permisos para editar, eliminar o aprobar documentos legales.');
        }
    }

    @TestVisible
    private static Boolean isPFByRecordType(String developerName) {
        if (String.isBlank(developerName)) {
            return false;
        }

        String dn = developerName.toLowerCase();

        if (dn.contains('persona_natural') || dn.contains('natural') || dn.contains('pf')) {
            return true;
        }

        return false;
    }
}