public with sharing class FSC_CaseWrapUpController {

    public class WrapUpResult {
        @AuraEnabled public Integer fileCount;
        @AuraEnabled public String emailTo;
        @AuraEnabled public String emailSubject;
        @AuraEnabled public String emailBody;
    }

    @AuraEnabled
    public static WrapUpResult getWrapUpData(Id caseId)  {
        if (caseId == null) {
            throw new AuraHandledException('El Id del Caso es requerido.');
        }

        WrapUpResult res = new WrapUpResult();

        res.fileCount = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :caseId
        ];

        Case c = [
            SELECT Id, CaseNumber, Subject, Contact.Email, SuppliedEmail
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        res.emailTo = (c.Contact != null && String.isNotBlank(c.Contact.Email))
            ? c.Contact.Email
            : c.SuppliedEmail;

        res.emailSubject = 'Cierre de Caso #' + c.CaseNumber;
        res.emailBody =
            'Hola,\n\n' +
            'Tu caso ' + c.CaseNumber + ' ha sido cerrado.\n\n' +
            'Saludos.';

        return res;
    
    }

    private static String getCloseStatus(Case c) {
        String rtDevName = c.RecordType.DeveloperName;

        if (rtDevName == 'Solicitudes' || rtDevName == 'Solicitud_Activacion_Tarjeta' || rtDevName == 'Solicitud_Analisis_5_Etapas' || rtDevName == 'Solicitud_Evaluacion_5_Etapas' || rtDevName == 'Solicitud_Procesamiento_Directo' || rtDevName == 'Solicitud_Seis_Etapas' || rtDevName == 'Solicitud_Validacion_Doble') {
            return 'Resolución y Cierre';
        }

        if (rtDevName == 'Reclamaciones' || rtDevName == 'Reclamo_Estandar' || rtDevName == 'Reclamo_Investigacion_Contracargo'|| 
        rtDevName == 'Reclamo_Contracargo'|| rtDevName == 'Reclamo_Contracargo_Investigacion'|| rtDevName == 'Reclamo_Data_Credito') {
            return 'Resolucion del caso';
        }

        throw new AuraHandledException('No hay estado de cierre configurado para el Record Type: ' + rtDevName);
    }

    @AuraEnabled
    public static void closeCase(Id caseId,
                                String outcome,
                                String closeReason,
                                String resolutionSummary,
                                Boolean sendEmail,
                                String emailTo,
                                String emailSubject,
                                String emailBody,
                                Integer minFilesRequired) {

        if (String.isBlank(outcome) || String.isBlank(closeReason) || String.isBlank(resolutionSummary)) {
            throw new AuraHandledException('Completa Resultado, Motivo de cierre y Resolución.');
        }

        Integer fileCount = [
            SELECT count()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :caseId
        ];

        Case currentCase = [
            SELECT Id,
                RecordTypeId,
                RecordType.DeveloperName,
                Type,
                CAS_Tipo_Caso__c,
                Status
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        
        if (minFilesRequired != null && fileCount < minFilesRequired) {
            throw new AuraHandledException('Faltan evidencias. Debes adjuntar al menos ' + minFilesRequired + ' archivo(s).');
        }


        String statusToClose = getCloseStatus(currentCase);

        Case c = new Case(
            Id = caseId,
            CAS_Motivo_de_Rechazo__c = outcome,
            FSC_CAS_Motivo_de_cierre__c = closeReason,
            FSC_CAS_Resumen_de_solucion__c = resolutionSummary,
            ClosedDate = system.now(),
            Status = statusToClose
        );

        try {
            update c;
        } catch (DmlException e) {
            // throw new AuraHandledException(
                // 'No se pudo cerrar el caso. El estado "' + statusToClose + '" puede no estar disponible para este Record Type.'
            // );
            throw new AuraHandledException('No se pudo cerrar el caso. Estado intentado: "' + statusToClose + '". Error real: ' + e.getDmlMessage(0));


        }
    }
    
    public class Request {
        @InvocableVariable(required=true)
        public Id caseId;
    }

    @InvocableMethod(label='Enviar recordatorio de caso')
    public static void sendReminderEmail(List<Request> requests) {

        if (requests.isEmpty()) return;

        Id caseId = requests[0].caseId;

        Case c = [
            SELECT Id, IsClosed, ContactId, CAS_Correo_Electronico_Cliente__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        if (c.IsClosed) return;

        if (String.isBlank(c.CAS_Correo_Electronico_Cliente__c)) return;

        EmailTemplate template = [
            SELECT Id
            FROM EmailTemplate
            WHERE DeveloperName = 'FSC_Notificacion_Cliente_15_dias'
            LIMIT 1
        ];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(new String[] { c.CAS_Correo_Electronico_Cliente__c });

        mail.setTargetObjectId(c.ContactId);
        mail.setTreatTargetObjectAsRecipient(false);

        mail.setWhatId(c.Id);
        mail.setTemplateId(template.Id);
        mail.setSaveAsActivity(true);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    @AuraEnabled
    public static void sendAditionalInformationEmail(String aditionalInformation, Id recordId) {

        Case rec = new Case(Id = recordId, CAS_Informacion_Adicional__c = aditionalInformation);
        update rec;

        Case c = [
            SELECT Id, IsClosed, ContactId, CAS_Correo_Electronico_Cliente__c
            FROM Case
            WHERE Id = :recordId
            LIMIT 1
        ];

        if (String.isBlank(c.CAS_Correo_Electronico_Cliente__c)){
            // return;
            throw new AuraHandledException(
                'Es necesario contar con el correo electronico del cliente.'
            );
        }

        if (c.Id == null) {
            throw new AuraHandledException('El Id del caso es requerido.');
        }

        Map<String, Object> inputs = new Map<String, Object>();
        inputs.put('recordId', c.Id);

        Flow.Interview.FL_CAS_Send_Case_Email_Alert flowInterview =
            new Flow.Interview.FL_CAS_Send_Case_Email_Alert(inputs);

        flowInterview.start();

        // Invocable.Action action = Invocable.Action.createCustomAction(
        //     'emailAlert',
        //     'Case.FSC_CAS_Solicitar_Informacion_Adicional'
        // );

        // action.setInvocationParameter('SObjectRowId', c.Id);

        // List<Invocable.Action.Result> results = action.invoke();

        // for (Invocable.Action.Result result : results) {
        //     if (!result.isSuccess()) {
        //         System.debug('Error Email Alert: ' + result.getErrors());
        //         throw new AuraHandledException(
        //             'No se pudo enviar el correo del caso.'
        //         );
        //     }
        // }

        // EmailTemplate template = [
        //     SELECT Id
        //     FROM EmailTemplate
        //     WHERE DeveloperName = 'FSC_CAS_Solicitar_Informacion_Adicional'
        //     LIMIT 1
        // ];

        /*Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(new String[] { c.CAS_Correo_Electronico_Cliente__c });

        mail.setTargetObjectId(c.ContactId);
        mail.setTreatTargetObjectAsRecipient(false);

        mail.setWhatId(c.Id);
        mail.setTemplateId(template.Id);
        mail.setSaveAsActivity(true);

        Messaging.SendEmailResult[] results = Messaging.sendEmail(
            new Messaging.SingleEmailMessage[] { mail },
            false
        );

        for (Messaging.SendEmailResult result : results) {
            System.debug('=== Email success: ' + result.isSuccess());

            if (!result.isSuccess()) {
                for (Messaging.SendEmailError err : result.getErrors()) {
                    System.debug('=== Email error status: ' + err.getStatusCode());
                    System.debug('=== Email error message: ' + err.getMessage());
                }
            }
        }*/
    }
}