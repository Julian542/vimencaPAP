public with sharing class DocumentosVencimientoNotificationBatch
    implements Database.Batchable<DocumentosVencimientoNotificationBatch.WorkItem>, Database.Stateful {

    private static final String QUEUE_DEVELOPER_NAME = 'FSC_Legal';

    public class WorkItem {
        public Id recordId;
        public String objectApiName;
        public String documentName;
        public String parentName;
        public Date expirationDate;
        public Boolean isNearExpiration;
        public Boolean isExpired;

        public WorkItem(
            Id recordId,
            String objectApiName,
            String documentName,
            String parentName,
            Date expirationDate,
            Boolean isNearExpiration,
            Boolean isExpired
        ) {
            this.recordId = recordId;
            this.objectApiName = objectApiName;
            this.documentName = documentName;
            this.parentName = parentName;
            this.expirationDate = expirationDate;
            this.isNearExpiration = isNearExpiration;
            this.isExpired = isExpired;
        }
    }

    public Iterable<WorkItem> start(Database.BatchableContext bc) {
        System.debug('DocumentosVencimientoNotificationBatch.start | Inicio');

        Date todayDate = Date.today();
        Date limitDate = todayDate.addDays(15);

        List<WorkItem> items = new List<WorkItem>();

        for (Documentacion_Legal__c doc : [
            SELECT Id,
                   Name,
                   DOC_Candidato__c,
                   DOC_Candidato__r.Name,
                   DOC_Candidato__r.IsConverted,
                   DOC_Fecha_Vencimiento__c,
                   DOC_Notificacion_15_Dias_Enviada__c,
                   DOC_Notificacion_Vencido_Enviada__c,
                   DOC_Documento_PF__r.ADR_Nombre_de_documento__c,
                   DOC_Documento_PJ__r.ADR_Nombre_de_documento__c,
                   DOC_Codigo_Documento__c
            FROM Documentacion_Legal__c
            WHERE DOC_Candidato__c != null
            AND DOC_Candidato__r.IsConverted = false
            AND DOC_Fecha_Vencimiento__c != null
            AND (
                (
                    DOC_Fecha_Vencimiento__c >= :todayDate
                    AND DOC_Fecha_Vencimiento__c <= :limitDate
                    AND DOC_Notificacion_15_Dias_Enviada__c = false
                )
                OR
                (
                    DOC_Fecha_Vencimiento__c < :todayDate
                    AND DOC_Notificacion_Vencido_Enviada__c = false
                )
            )
        ]) {
            Boolean isNearExpiration =
                doc.DOC_Fecha_Vencimiento__c >= todayDate &&
                doc.DOC_Fecha_Vencimiento__c <= limitDate &&
                doc.DOC_Notificacion_15_Dias_Enviada__c == false;

            Boolean isExpired =
                doc.DOC_Fecha_Vencimiento__c < todayDate &&
                doc.DOC_Notificacion_Vencido_Enviada__c == false;

            items.add(new WorkItem(
                doc.Id,
                'Documentacion_Legal__c',
                getDocumentacionLegalName(doc),
                doc.DOC_Candidato__r != null ? doc.DOC_Candidato__r.Name : '',
                doc.DOC_Fecha_Vencimiento__c,
                isNearExpiration,
                isExpired
            ));
        }

        for (DocumentChecklistItem dci : [
            SELECT Id,
                   Name,
                   ParentRecordId,
                   DCI_Fecha_Vencimiento__c,
                   DCI_Notificacion_15_Dias_Enviada__c,
                   DCI_Notificacion_Vencido_Enviada__c
            FROM DocumentChecklistItem
            WHERE DCI_Fecha_Vencimiento__c != null
            AND (
                (
                    DCI_Fecha_Vencimiento__c >= :todayDate
                    AND DCI_Fecha_Vencimiento__c <= :limitDate
                    AND DCI_Notificacion_15_Dias_Enviada__c = false
                )
                OR
                (
                    DCI_Fecha_Vencimiento__c < :todayDate
                    AND DCI_Notificacion_Vencido_Enviada__c = false
                )
            )
        ]) {
            Boolean isNearExpiration =
                dci.DCI_Fecha_Vencimiento__c >= todayDate &&
                dci.DCI_Fecha_Vencimiento__c <= limitDate &&
                dci.DCI_Notificacion_15_Dias_Enviada__c == false;

            Boolean isExpired =
                dci.DCI_Fecha_Vencimiento__c < todayDate &&
                dci.DCI_Notificacion_Vencido_Enviada__c == false;

            items.add(new WorkItem(
                dci.Id,
                'DocumentChecklistItem',
                dci.Name,
                String.valueOf(dci.ParentRecordId),
                dci.DCI_Fecha_Vencimiento__c,
                isNearExpiration,
                isExpired
            ));
        }

        System.debug('DocumentosVencimientoNotificationBatch.start | items.size=' + items.size());

        return items;
    }

    public void execute(Database.BatchableContext bc, List<WorkItem> scope) {
        System.debug('DocumentosVencimientoNotificationBatch.execute | scope.size=' + (scope == null ? 0 : scope.size()));

        if (scope == null || scope.isEmpty()) {
            return;
        }

        List<String> queueEmails = getQueueMemberEmails();

        if (queueEmails.isEmpty()) {
            System.debug('DocumentosVencimientoNotificationBatch.execute | No hay correos de usuarios activos en la cola');
            return;
        }

        List<WorkItem> nearExpirationItems = new List<WorkItem>();
        List<WorkItem> expiredItems = new List<WorkItem>();

        for (WorkItem item : scope) {
            if (item.isNearExpiration == true) {
                nearExpirationItems.add(item);
            }

            if (item.isExpired == true) {
                expiredItems.add(item);
            }
        }

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        if (!nearExpirationItems.isEmpty()) {
            emailsToSend.add(buildEmail(
                queueEmails,
                'Documentos próximos a vencer',
                buildEmailBody('Documentos próximos a vencer en los próximos 15 días', nearExpirationItems)
            ));
        }

        if (!expiredItems.isEmpty()) {
            emailsToSend.add(buildEmail(
                queueEmails,
                'Documentos vencidos',
                buildEmailBody('Documentos vencidos', expiredItems)
            ));
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend, false);
            Boolean hasSuccess = false;

            for (Messaging.SendEmailResult result : results) {
                if (result != null && result.isSuccess()) {
                    hasSuccess = true;
                } else if (result != null && result.getErrors() != null) {
                    for (Messaging.SendEmailError err : result.getErrors()) {
                        System.debug('DocumentosVencimientoNotificationBatch.execute | Error enviando correo=' + err.getMessage());
                    }
                }
            }

            if (hasSuccess) {
                updateNotificationFlags(scope);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('DocumentosVencimientoNotificationBatch.finish | Proceso finalizado');
    }

    private static void updateNotificationFlags(List<WorkItem> scope) {
        System.debug('DocumentosVencimientoNotificationBatch.updateNotificationFlags | Inicio');

        List<Documentacion_Legal__c> docsToUpdate = new List<Documentacion_Legal__c>();
        List<DocumentChecklistItem> dciToUpdate = new List<DocumentChecklistItem>();

        for (WorkItem item : scope) {
            if (item == null || item.recordId == null) {
                continue;
            }

            if (item.objectApiName == 'Documentacion_Legal__c') {
                Documentacion_Legal__c doc = new Documentacion_Legal__c(Id = item.recordId);

                if (item.isNearExpiration == true) {
                    doc.DOC_Notificacion_15_Dias_Enviada__c = true;
                }

                if (item.isExpired == true) {
                    doc.DOC_Notificacion_Vencido_Enviada__c = true;
                }

                docsToUpdate.add(doc);
            }

            if (item.objectApiName == 'DocumentChecklistItem') {
                DocumentChecklistItem dci = new DocumentChecklistItem(Id = item.recordId);

                if (item.isNearExpiration == true) {
                    dci.DCI_Notificacion_15_Dias_Enviada__c = true;
                }

                if (item.isExpired == true) {
                    dci.DCI_Notificacion_Vencido_Enviada__c = true;
                }

                dciToUpdate.add(dci);
            }
        }

        if (!docsToUpdate.isEmpty()) {
            update docsToUpdate;
            System.debug('DocumentosVencimientoNotificationBatch.updateNotificationFlags | Documentacion_Legal__c actualizados=' + docsToUpdate.size());
        }

        if (!dciToUpdate.isEmpty()) {
            update dciToUpdate;
            System.debug('DocumentosVencimientoNotificationBatch.updateNotificationFlags | DocumentChecklistItem actualizados=' + dciToUpdate.size());
        }
    }

    private static List<String> getQueueMemberEmails() {
        List<String> emails = new List<String>();

        List<Group> queues = [
            SELECT Id,
                   Name,
                   DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = :QUEUE_DEVELOPER_NAME
            LIMIT 1
        ];

        if (queues.isEmpty()) {
            System.debug('DocumentosVencimientoNotificationBatch.getQueueMemberEmails | No existe la cola=' + QUEUE_DEVELOPER_NAME);
            return emails;
        }

        Set<Id> userIds = new Set<Id>();

        for (GroupMember gm : [
            SELECT UserOrGroupId
            FROM GroupMember
            WHERE GroupId = :queues[0].Id
        ]) {
            if (String.valueOf(gm.UserOrGroupId).startsWith('005')) {
                userIds.add(gm.UserOrGroupId);
            }
        }

        if (userIds.isEmpty()) {
            System.debug('DocumentosVencimientoNotificationBatch.getQueueMemberEmails | La cola no tiene usuarios directos');
            return emails;
        }

        for (User u : [
            SELECT Id,
                   Email,
                   IsActive
            FROM User
            WHERE Id IN :userIds
            AND IsActive = true
            AND Email != null
        ]) {
            emails.add(u.Email);
        }

        System.debug('DocumentosVencimientoNotificationBatch.getQueueMemberEmails | emails.size=' + emails.size());

        return emails;
    }

    private static Messaging.SingleEmailMessage buildEmail(
        List<String> toAddresses,
        String subject,
        String body
    ) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        mail.setSaveAsActivity(false);
        return mail;
    }

    private static String buildEmailBody(String title, List<WorkItem> items) {
        String body = title + '\n\n';

        for (WorkItem item : items) {
            body += 'Objeto: ' + item.objectApiName + '\n';
            body += 'Documento: ' + item.documentName + '\n';
            body += 'Relacionado: ' + item.parentName + '\n';
            body += 'Fecha de vencimiento: ' + String.valueOf(item.expirationDate) + '\n';
            body += 'Registro: ' + URL.getOrgDomainUrl().toExternalForm() + '/' + item.recordId + '\n';
            body += '-----------------------------\n';
        }

        return body;
    }

    private static String getDocumentacionLegalName(Documentacion_Legal__c doc) {
        if (doc == null) {
            return 'Documento Legal';
        }

        if (
            doc.DOC_Documento_PF__r != null &&
            String.isNotBlank(doc.DOC_Documento_PF__r.ADR_Nombre_de_documento__c)
        ) {
            return doc.DOC_Documento_PF__r.ADR_Nombre_de_documento__c;
        }

        if (
            doc.DOC_Documento_PJ__r != null &&
            String.isNotBlank(doc.DOC_Documento_PJ__r.ADR_Nombre_de_documento__c)
        ) {
            return doc.DOC_Documento_PJ__r.ADR_Nombre_de_documento__c;
        }

        if (String.isNotBlank(doc.DOC_Codigo_Documento__c)) {
            return 'Documento ' + doc.DOC_Codigo_Documento__c;
        }

        return 'Documento Legal';
    }
}