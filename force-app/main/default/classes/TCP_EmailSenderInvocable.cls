/**
 * Name: TCP_EmailSenderInvocable
 * Autor: Lisbeth Colomo
 * Description:
 *  Invocable reusable para Flow (OpportunityTCP__c):
 *   - CLIENT: Envía correo de rechazo al cliente resolviendo el email desde ContactPointEmail (CORREO ELECTRÓNICO).
 *             NO se guarda el correo en OpportunityTCP__c.
 *   - ANALYST: Envía correo al analista asignado (OTCP_AssignedAnalyst__r.Email) con mensaje de asignación.
 *   - DEMORA_EVIDENCIAS: Envía correo al analista asignado informando vencimiento de entrega de evidencias.
 *   - ASIGNACION_ANALISTA_INICIAL: Envía correo al analista asignado informando asignación inicial.
 *   - DEMORA_INICIAR_ANALISIS: Envía correo al analista asignado por demora en iniciar análisis.
 *   - DEMORA_TERMINAR_ANALISIS: Envía correo al analista asignado por demora sin interacción luego de iniciado.
 *   - BIENVENIDA_CLIENTE: Envía correo de bienvenida al cliente usando template HTML + Custom Metadata + URLs públicas de imágenes.
 *
 *  CAMBIO:
 *   - En cualquiera de los modos de ANALISTA, se incluye link directo al registro OpportunityTCP__c.
 *   - En BIENVENIDA_CLIENTE, se resuelve el email igual que CLIENT y se arma el HTML según tipo de tarjeta.
 *   - Las imágenes de BIENVENIDA_CLIENTE ya no se envían como adjuntos inline (cid:).
 *   - Los campos Banner_URL__c, QR_Benefits__c y QR_Tarifario__c del Custom Metadata deben guardar la URL pública completa de la imagen.
 *
 *  Inputs desde Flow:
 *   - opportunityTcpId (requerido)
 *   - subject (requerido) -> se usa tal cual lo envíe Flow/clase
 *   - recipientMode (requerido):
 *       CLIENT,
 *       ANALYST,
 *       DEMORA_EVIDENCIAS,
 *       ASIGNACION_ANALISTA_INICIAL,
 *       DEMORA_INICIAR_ANALISIS,
 *       DEMORA_TERMINAR_ANALISIS,
 *       BIENVENIDA_CLIENTE
 *   - orgWideEmailAddressId (opcional)
 *   - failOnMissingRecipient (opcional)
 *
 *  Reutilizable desde otras clases:
 *   - sendFromCode(opportunityTcpId, subject, recipientMode, orgWideEmailAddressId, failOnMissingRecipient)
 *   - sendSingleEmail(toEmail, subject, htmlBody, orgWideEmailAddressId)
 *   - sendEmails(msgs)
 *
 * Last modified: 2026-03-12
 */
public with sharing class TCP_EmailSenderInvocable {

    public class OTCPEmailException extends Exception {}

    // Static Resource solo para el HTML template
    private static final String STATIC_RESOURCE_TEMPLATE = 'TCP_WelcomeCardTemplate';


    public class Input {
        @InvocableVariable(required=true) public Id opportunityTcpId;
        @InvocableVariable(required=true) public String subject;
        @InvocableVariable(required=true) public String recipientMode; // ver lista en Description
        @InvocableVariable(required=false) public Id orgWideEmailAddressId;
        @InvocableVariable(required=false) public Boolean failOnMissingRecipient;
    }

    public class Output {
        @InvocableVariable public Id opportunityTcpId;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
        @InvocableVariable public String toEmailResolved;
        @InvocableVariable public String recipientModeUsed;
    }

    // -------- INVOCABLE (orquestador) --------
    @InvocableMethod(
        label='TCP - Enviar correo (según modo)'
        description='Envía correo desde OpportunityTCP__c según recipientMode: CLIENT, ANALYST, DEMORA_EVIDENCIAS, ASIGNACION_ANALISTA_INICIAL, DEMORA_INICIAR_ANALISIS, DEMORA_TERMINAR_ANALISIS, BIENVENIDA_CLIENTE.'
    )
    public static List<Output> sendEmail(List<Input> inputs) {

        System.debug('>>> TCP_EmailSenderInvocable.sendEmail inputs size=' + (inputs == null ? 0 : inputs.size()));

        List<Output> results = initOutputs(inputs);
        if (inputs == null || inputs.isEmpty()) return results;

        Context ctx = buildContext(inputs, results);
        if (ctx.otcpIds.isEmpty()) {
            setAllResults(results, false, 'No se recibieron IDs válidos de OpportunityTCP__c.');
            return results;
        }

        try {
            ctx.otcpList = queryOTCP(ctx.otcpIds);
            ctx.accountIds = extractAccountIds(ctx.otcpList);
            ctx.accById = queryAccounts(ctx.accountIds);

            // Resuelve correos de cliente para CLIENT y BIENVENIDA_CLIENTE
            if (needsClientResolution(ctx)) {
                ctx.emailByAccountId = queryClientEmailsFromVias(ctx.accountIds);
            }

            // Arma mensajes + mapea índice->OTCP para poder interpretar SendEmailResult[]
            PreparedEmails prep = prepareEmails(ctx);

            // Envía
            if (!prep.msgs.isEmpty()) {
                Messaging.SendEmailResult[] sendResults = sendEmails(prep.msgs);
                applySendResults(sendResults, prep.idxToOtcp, ctx.outByOtcpId);
            } else {
                System.debug('>>> No hay emails para enviar (todos sin destinatario o inválidos).');
            }

            return results;

        } catch (Exception e) {
            System.debug('!!! ERROR in TCP_EmailSenderInvocable.sendEmail: ' + e.getMessage() + ' | ' + e.getStackTraceString());
            for (Output o : results) {
                o.success = false;
                o.message = 'Excepción en invocable: ' + e.getMessage();
            }
            return results;
        }
    }

    // -------- MÉTODO REUTILIZABLE (desde otras clases) --------
    public static Output sendFromCode(
        Id opportunityTcpId,
        String subject,
        String recipientMode,
        Id orgWideEmailAddressId,
        Boolean failOnMissingRecipient
    ) {
        System.debug('>>> TCP_EmailSenderInvocable.sendFromCode opportunityTcpId=' + opportunityTcpId + ', subject=' + subject + ', recipientMode=' + recipientMode);

        Input i = new Input();
        i.opportunityTcpId = opportunityTcpId;
        i.subject = subject;
        i.recipientMode = recipientMode;
        i.orgWideEmailAddressId = orgWideEmailAddressId;
        i.failOnMissingRecipient = failOnMissingRecipient;

        List<Output> outs = sendEmail(new List<Input>{ i });
        return (outs != null && !outs.isEmpty()) ? outs[0] : null;
    }

    // Enviar 1 correo sin pasar por el invocable completo
    public static Messaging.SendEmailResult sendSingleEmail(
        String toEmail,
        String subject,
        String htmlBody,
        Id orgWideEmailAddressId
    ) {
        System.debug('>>> TCP_EmailSenderInvocable.sendSingleEmail toEmail=' + toEmail + ', subject=' + subject);

        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
        m.setToAddresses(new List<String>{ (toEmail == null ? null : toEmail.trim()) });
        m.setSubject(subject);
        m.setHtmlBody(htmlBody);

        if (orgWideEmailAddressId != null) {
            m.setOrgWideEmailAddressId(orgWideEmailAddressId);
        }

        Messaging.SendEmailResult[] r = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ m }, false);
        return (r != null && !r.isEmpty()) ? r[0] : null;
    }

    // Enviar una lista de correos (también reusable)
    public static Messaging.SendEmailResult[] sendEmails(List<Messaging.SingleEmailMessage> msgs) {
        System.debug('>>> TCP_EmailSenderInvocable.sendEmails count=' + (msgs == null ? 0 : msgs.size()));
        if (msgs == null || msgs.isEmpty()) return new Messaging.SendEmailResult[] {};
        return Messaging.sendEmail(msgs, false);
    }

    // -------- MODELOS INTERNOS --------
    private class Context {
        List<Input> inputs;
        List<Output> results;

        Map<Id, Output> outByOtcpId = new Map<Id, Output>();
        Map<Id, Input>  inByOtcpId  = new Map<Id, Input>();
        Set<Id> otcpIds = new Set<Id>();

        List<OpportunityTCP__c> otcpList = new List<OpportunityTCP__c>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Account> accById = new Map<Id, Account>();

        Map<Id, String> emailByAccountId = new Map<Id, String>(); // AccountId -> email (Vias)
    }

    private class PreparedEmails {
        List<Messaging.SingleEmailMessage> msgs = new List<Messaging.SingleEmailMessage>();
        Map<Integer, Id> idxToOtcp = new Map<Integer, Id>(); // idx mensaje -> OTCP Id
    }

    private class EmailContent {
        String htmlBody;
    }

    // -------- INIT / CONTEXTO --------
    private static List<Output> initOutputs(List<Input> inputs) {
        List<Output> results = new List<Output>();
        if (inputs == null) return results;

        for (Input i : inputs) {
            Output o = new Output();
            o.opportunityTcpId = (i == null ? null : i.opportunityTcpId);
            o.success = false;
            o.message = 'Inicializando...';
            o.recipientModeUsed = (i == null ? null : i.recipientMode);
            results.add(o);
        }
        return results;
    }

    private static Context buildContext(List<Input> inputs, List<Output> results) {
        Context ctx = new Context();
        ctx.inputs = inputs;
        ctx.results = results;

        for (Integer k = 0; k < inputs.size(); k++) {
            Input i = inputs[k];
            Output o = results[k];

            if (i != null && i.opportunityTcpId != null) {
                ctx.otcpIds.add(i.opportunityTcpId);
                ctx.outByOtcpId.put(i.opportunityTcpId, o);
                ctx.inByOtcpId.put(i.opportunityTcpId, i);
            }
        }
        return ctx;
    }

    private static void setAllResults(List<Output> results, Boolean success, String message) {
        for (Output o : results) {
            o.success = success;
            o.message = message;
        }
    }

    // -------- QUERIES --------
    private static List<OpportunityTCP__c> queryOTCP(Set<Id> otcpIds) {
        System.debug('>>> Query OpportunityTCP__c IDs=' + otcpIds);

        String soql =
            'SELECT Id, ' +
            '       Name, ' +
            '       OTCP_Account__c, ' +
            '       OTCP_SubState__c, ' +
            '       OTCP_AssignedAnalyst__c, ' +
            '       OTCP_AssignedAnalyst__r.Email, ' +
            '       OTCP_AssignedAnalyst__r.Name, ' +
            '       OTCP_CardType__c, ' +
            '       OTCP_limiteSugeridoDOP__c, ' +
            '       OTCP_limiteSugeridoUSD__c ' +
            'FROM OpportunityTCP__c ' +
            'WHERE Id IN :otcpIds';

        System.debug('>>> SOQL queryOTCP=' + soql);

        return Database.query(soql);
    }

    private static Set<Id> extractAccountIds(List<OpportunityTCP__c> otcpList) {
        Set<Id> accountIds = new Set<Id>();
        for (OpportunityTCP__c o : otcpList) {
            if (o.OTCP_Account__c != null) accountIds.add(o.OTCP_Account__c);
        }
        return accountIds;
    }

    private static Map<Id, Account> queryAccounts(Set<Id> accountIds) {
        Map<Id, Account> accById = new Map<Id, Account>();
        if (accountIds == null || accountIds.isEmpty()) return accById;

        System.debug('>>> Query Account IDs=' + accountIds);

        accById = new Map<Id, Account>([
            SELECT Id, Name
            FROM Account
            WHERE Id IN :accountIds
        ]);

        return accById;
    }

    private static Map<Id, String> queryClientEmailsFromVias(Set<Id> accountIds) {
        Map<Id, String> emailByAccountId = new Map<Id, String>();
        if (accountIds == null || accountIds.isEmpty()) return emailByAccountId;
    
    
        List<ContactPointEmail> emails = [
            SELECT Id,
                   ParentId,
                   EmailAddress,
                   IsPrimary
            FROM ContactPointEmail
            WHERE ParentId IN :accountIds
              AND IsPrimary = true
              AND EmailAddress != null
            ORDER BY CreatedDate ASC
        ];
        System.debug('Query ContactPointEmail=' + emails);
    
        for (ContactPointEmail cpe : emails) {
            if (cpe.ParentId == null) continue;
    
            if (!emailByAccountId.containsKey(cpe.ParentId)) {
                emailByAccountId.put(cpe.ParentId, String.valueOf(cpe.EmailAddress).trim());
            }
        }
    
        return emailByAccountId;
    }

    // -------- RESOLUCIÓN / PREPARACIÓN --------
    private static Boolean needsClientResolution(Context ctx) {
        for (OpportunityTCP__c o : ctx.otcpList) {
            Input inpt = ctx.inByOtcpId.get(o.Id);
            if (inpt == null) continue;

            String mode = String.valueOf(inpt.recipientMode).toUpperCase();
            if (mode == 'CLIENT' || mode == 'BIENVENIDA_CLIENTE') return true;
        }
        return false;
    }

    private static PreparedEmails prepareEmails(Context ctx) {
        System.debug('>>> TCP_EmailSenderInvocable.prepareEmails');

        PreparedEmails prep = new PreparedEmails();

        for (OpportunityTCP__c o : ctx.otcpList) {
            Input inpt = ctx.inByOtcpId.get(o.Id);
            Output out = ctx.outByOtcpId.get(o.Id);

            if (inpt == null || out == null) continue;

            String mode = String.valueOf(inpt.recipientMode).toUpperCase();
            out.recipientModeUsed = mode;

            String toEmail = resolveToEmail(mode, o, ctx.emailByAccountId);
            out.toEmailResolved = toEmail;

            if (String.isBlank(toEmail)) {
                handleMissingRecipient(inpt, out, mode, o, ctx.emailByAccountId);
                continue;
            }

            Account a = (o.OTCP_Account__c == null) ? null : ctx.accById.get(o.OTCP_Account__c);

            // Link al registro (se agregará en TODOS los modos de analista)
            String recordUrl = buildOtcpRecordUrl(o);

            EmailContent emailContent = buildEmailContentByMode(mode, o, a, recordUrl);

            if (emailContent == null || String.isBlank(emailContent.htmlBody)) {
                out.success = false;
                out.message =
                    'recipientMode inválido. Use: ' +
                    'CLIENT, ANALYST, DEMORA_EVIDENCIAS, ASIGNACION_ANALISTA_INICIAL, DEMORA_INICIAR_ANALISIS, DEMORA_TERMINAR_ANALISIS, BIENVENIDA_CLIENTE.';
                continue;
            }

            Messaging.SingleEmailMessage m = buildEmailMessage(
                toEmail,
                inpt.subject,
                emailContent,
                inpt.orgWideEmailAddressId
            );

            prep.msgs.add(m);
            prep.idxToOtcp.put(prep.msgs.size() - 1, o.Id);

            out.success = true;
            out.message = 'Email preparado para envío.';
        }

        return prep;
    }

    private static Boolean isAnalystMode(String mode) {
        return mode == 'ANALYST'
            || mode == 'DEMORA_EVIDENCIAS'
            || mode == 'ASIGNACION_ANALISTA_INICIAL'
            || mode == 'DEMORA_INICIAR_ANALISIS'
            || mode == 'DEMORA_TERMINAR_ANALISIS';
    }

    private static String resolveToEmail(String mode, OpportunityTCP__c o, Map<Id, String> emailByAccountId) {
        String toEmail;

        if (mode == 'CLIENT' || mode == 'BIENVENIDA_CLIENTE') {
            toEmail = (o.OTCP_Account__c == null) ? null : emailByAccountId.get(o.OTCP_Account__c);

        } else if (isAnalystMode(mode)) {
            toEmail = (o.OTCP_AssignedAnalyst__r == null) ? null : o.OTCP_AssignedAnalyst__r.Email;

        } else {
            toEmail = null;
        }

        return (toEmail == null) ? null : toEmail.trim();
    }

    private static void handleMissingRecipient(
        Input inpt,
        Output out,
        String mode,
        OpportunityTCP__c o,
        Map<Id, String> emailByAccountId
    ) {
        String viaResolved = (o.OTCP_Account__c == null) ? null : emailByAccountId.get(o.OTCP_Account__c);

        out.success = false;
        out.message =
            'No se resolvió email destino. ' +
            'recipientMode=' + mode +
            ', AccountId=' + String.valueOf(o.OTCP_Account__c) +
            ', ViaCorreoEncontrado=' + String.valueOf(viaResolved) +
            ', AssignedAnalystId=' + String.valueOf(o.OTCP_AssignedAnalyst__c);

        if (inpt.failOnMissingRecipient == true) {
            throw new OTCPEmailException(out.message);
        }
    }

    private static Messaging.SingleEmailMessage buildEmailMessage(
        String toEmail,
        String subject,
        EmailContent emailContent,
        Id orgWideEmailAddressId
    ) {
        System.debug('>>> TCP_EmailSenderInvocable.buildEmailMessage toEmail=' + toEmail + ', subject=' + subject);

        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
        m.setToAddresses(new List<String>{ toEmail });
        m.setSubject(subject);
        m.setHtmlBody(emailContent.htmlBody);

        if (orgWideEmailAddressId != null) {
            m.setOrgWideEmailAddressId(orgWideEmailAddressId);
        }

        return m;
    }

    private static void applySendResults(
        Messaging.SendEmailResult[] sendResults,
        Map<Integer, Id> idxToOtcp,
        Map<Id, Output> outByOtcpId
    ) {
        for (Integer i = 0; i < sendResults.size(); i++) {
            Id otcpId = idxToOtcp.get(i);
            Output out = outByOtcpId.get(otcpId);
            if (out == null) continue;

            if (sendResults[i] != null && sendResults[i].isSuccess()) {
                out.success = true;
                out.message = 'Email enviado (sendEmail success).';
                continue;
            }

            out.success = false;
            String errMsg = 'Error al enviar email.';
            if (sendResults[i] != null && sendResults[i].getErrors() != null && !sendResults[i].getErrors().isEmpty()) {
                errMsg += ' ' + sendResults[i].getErrors()[0].getMessage();
            }
            out.message = errMsg;
        }
    }

    // -------- LINK HELPERS --------
    private static String buildOtcpRecordUrl(OpportunityTCP__c o) {
        System.debug('>>> TCP_EmailSenderInvocable.buildOtcpRecordUrl otcpId=' + (o == null ? null : o.Id));
        if (o == null || o.Id == null) return null;

        try {
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            return baseUrl + '/lightning/r/OpportunityTCP__c/' + String.valueOf(o.Id) + '/view';
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'No se pudo construir URL del record: ' + e.getMessage());
            return null;
        }
    }

    private static String buildRecordLinkHtml(String recordUrl) {
        if (String.isBlank(recordUrl)) return '';
        return
            '<p style="margin:12px 0 0 0;">' +
                '<a href="' + escapeHtml(recordUrl) + '" target="_blank" rel="noopener noreferrer">' +
                    'Abrir solicitud en Salesforce' +
                '</a>' +
            '</p>';
    }

    // -------- BODIES --------
    private static EmailContent buildEmailContentByMode(String mode, OpportunityTCP__c o, Account a, String recordUrl) {
        System.debug('>>> TCP_EmailSenderInvocable.buildEmailContentByMode mode=' + mode + ', otcpId=' + (o == null ? null : o.Id));

        if (mode == 'CLIENT') {
            return buildSimpleEmailContent(buildRejectionHtml(o, a));
        }

        if (mode == 'BIENVENIDA_CLIENTE') {
            return buildWelcomeClientHtml(o, a);
        }

        if (mode == 'ANALYST') {
            return buildSimpleEmailContent(buildAnalystAssignmentHtml(o, a, recordUrl));
        }

        if (mode == 'DEMORA_EVIDENCIAS') {
            return buildSimpleEmailContent(buildDelayEvidencesHtml(o, recordUrl));
        }

        if (mode == 'ASIGNACION_ANALISTA_INICIAL') {
            return buildSimpleEmailContent(buildAsignacionAnalistaInicialHtml(o, a, recordUrl));
        }

        if (mode == 'DEMORA_INICIAR_ANALISIS') {
            return buildSimpleEmailContent(buildDemoraIniciarAnalisisHtml(o, recordUrl));
        }

        if (mode == 'DEMORA_TERMINAR_ANALISIS') {
            return buildSimpleEmailContent(buildDemoraTerminarAnalisisHtml(o, recordUrl));
        }

        return null;
    }

    private static EmailContent buildSimpleEmailContent(String htmlBody) {
        System.debug('>>> TCP_EmailSenderInvocable.buildSimpleEmailContent');
        EmailContent content = new EmailContent();
        content.htmlBody = htmlBody;
        return content;
    }

    // Email al cliente por rechazo
    private static String buildRejectionHtml(OpportunityTCP__c o, Account a) {
        System.debug('>>> TCP_EmailSenderInvocable.buildRejectionHtml otcpId=' + (o == null ? null : o.Id));

        String accountName = (a == null || String.isBlank(a.Name)) ? 'Cliente' : a.Name;
        String motivo      = (o == null || String.isBlank(o.OTCP_SubState__c)) ? null : o.OTCP_SubState__c;

        String motivoBlock = '';
        if (!String.isBlank(motivo)) {
            motivoBlock =
                '<p style="margin:12px 0 0 0;">Motivo / Subestado:</p>' +
                '<p style="padding:10px 12px; background:#f3f4f6; border-left:4px solid #111827; margin:8px 0 14px 0;">' +
                    '<strong>' + escapeHtml(motivo) + '</strong>' +
                '</p>';
        }

        return
            '<div style="font-family: Arial, sans-serif; font-size: 14px; color: #1f1f1f; line-height: 1.5;">' +
                '<p>Hola <strong>' + escapeHtml(accountName) + '</strong>,</p>' +
                '<p>Gracias por pensar en nuestros productos y servicios.</p>' +
                '<p>En esta oportunidad, posterior a realizar el análisis correspondiente, tu solicitud de tarjeta de crédito ' +
                'no ha sido posible aprobarla, en cumplimiento con las políticas internas del Banco.</p>' +
                '<p>Es de nuestro muy alto interés conectar contigo y reevaluar tu caso en los próximos <strong>6 meses</strong>.</p>' +
                '<p>Si deseas conocer más detalles sobre esta evaluación o explorar otras opciones disponibles, puedes escribirnos a ' +
                    '<a href="mailto:teleasistencia@bv.com.do">teleasistencia@bv.com.do</a> o comunicarte con nosotros al ' +
                    '<a href="tel:+18095331400">809.533.1400</a>.</p>' +
                '<p>Nuestro equipo está disponible para asistirte de <strong>lunes a domingo de 7AM a 12AM</strong>, ' +
                'y en <strong>días feriados de 7AM a 8PM</strong>.</p>' +
                '<p>Para nosotros, es un privilegio servirte.</p>' +
                '<p style="margin:16px 0 0 0;"><strong>Equipo Banca Personal</strong><br/>' +
                'Banco Vimenca</p>' +
                '<hr style="border:0; border-top:1px solid #e5e7eb; margin:16px 0;" />' +
                '<p style="font-size:12px; color:#6b7280; margin:0;">' +
                    'Cuéntanos tu experiencia con nosotros en ' +
                    '<a href="mailto:miexperiencia@bv.com.do">miexperiencia@bv.com.do</a>. ¡Queremos escucharte!' +
                '</p>' +
            '</div>';
    }

    // BIENVENIDA_CLIENTE
    private static EmailContent buildWelcomeClientHtml(OpportunityTCP__c o, Account a) {
        System.debug('>>> TCP_EmailSenderInvocable.buildWelcomeClientHtml otcpId=' + (o == null ? null : o.Id));

        try {
            String customerName = (a == null || String.isBlank(a.Name)) ? 'Cliente' : a.Name;
            String cardType = getCardTypeFromOTCP(o);

            System.debug('>>> cardType resuelto para BIENVENIDA_CLIENTE=' + cardType);

            if (String.isBlank(cardType)) {
                throw new OTCPEmailException(
                    'No se pudo resolver el tipo de tarjeta desde OpportunityTCP__c. Revise OTCP_CardType__c.'
                );
            }

            return buildWelcomeEmailHtml(cardType, customerName, o);

        } catch (Exception e) {
            System.debug('!!! ERROR buildWelcomeClientHtml: ' + e.getMessage());
            System.debug('!!! StackTrace: ' + e.getStackTraceString());
            throw e;
        }
    }

    // ANALYST (Revisar evidencias)
    private static String buildAnalystAssignmentHtml(OpportunityTCP__c o, Account a, String recordUrl) {
        System.debug('>>> TCP_EmailSenderInvocable.buildAnalystAssignmentHtml otcpId=' + (o == null ? null : o.Id));

        String otcpName = (o == null || String.isBlank(o.Name)) ? '(sin nombre)' : o.Name;
        String customerName = (a == null || String.isBlank(a.Name)) ? '' : (' del cliente <strong>' + escapeHtml(a.Name) + '</strong>');
        String userName = (o == null || o.OTCP_AssignedAnalyst__r == null || String.isBlank(o.OTCP_AssignedAnalyst__r.Name))
            ? ''
            : o.OTCP_AssignedAnalyst__r.Name;

        String linkHtml = buildRecordLinkHtml(recordUrl);

        return
            '<div style="font-family: Arial, sans-serif; font-size: 14px; color: #1f1f1f;">' +
                '<p>Estimado/a <strong>' + escapeHtml(userName) + '</strong>,</p>' +
                '<p>Se le ha asignado la solicitud <strong>' + escapeHtml(otcpName) + '</strong>' + customerName +
                ' para su revisión antes de enviar a aprobación.</p>' +
                linkHtml +
                '<p style="margin-top:18px; font-size:12px; color:#6b7280;">Este correo fue generado automáticamente.</p>' +
            '</div>';
    }

    // DEMORA_EVIDENCIAS
    private static String buildDelayEvidencesHtml(OpportunityTCP__c o, String recordUrl) {
        System.debug('>>> TCP_EmailSenderInvocable.buildDelayEvidencesHtml otcpId=' + (o == null ? null : o.Id));

        String otcpName = (o == null || String.isBlank(o.Name)) ? '(sin nombre)' : o.Name;
        String userName = (o == null || o.OTCP_AssignedAnalyst__r == null || String.isBlank(o.OTCP_AssignedAnalyst__r.Name))
            ? ''
            : o.OTCP_AssignedAnalyst__r.Name;

        String linkHtml = buildRecordLinkHtml(recordUrl);

        return
            '<div style="font-family: Arial, sans-serif; font-size: 14px; color: #1f1f1f;">' +
                '<p>Estimado/a <strong>' + escapeHtml(userName) + '</strong>,</p>' +
                '<p>Se ha vencido el tiempo de entrega de evidencias que solicitó de la oportunidad TCP: ' +
                '<strong>\'' + escapeHtml(otcpName) + '\'</strong>.</p>' +
                linkHtml +
                '<p style="margin-top:18px; font-size:12px; color:#6b7280;">Este correo fue generado automáticamente.</p>' +
            '</div>';
    }

    // ASIGNACION_ANALISTA_INICIAL
    private static String buildAsignacionAnalistaInicialHtml(OpportunityTCP__c o, Account a, String recordUrl) {
        System.debug('>>> TCP_EmailSenderInvocable.buildAsignacionAnalistaInicialHtml otcpId=' + (o == null ? null : o.Id));

        String otcpName = (o == null || String.isBlank(o.Name)) ? '(sin nombre)' : o.Name;
        String customerNamePlain = (a == null || String.isBlank(a.Name)) ? '' : a.Name;

        String phraseSolicitud;
        if (String.isBlank(customerNamePlain)) {
            phraseSolicitud = escapeHtml(otcpName);
        } else {
            phraseSolicitud = escapeHtml(customerNamePlain) + ' - ' + escapeHtml(otcpName);
        }

        String userName = (o == null || o.OTCP_AssignedAnalyst__r == null || String.isBlank(o.OTCP_AssignedAnalyst__r.Name))
            ? ''
            : o.OTCP_AssignedAnalyst__r.Name;

        String linkHtml = buildRecordLinkHtml(recordUrl);

        return
            '<div style="font-family: Arial, sans-serif; font-size: 14px; color: #1f1f1f;">' +
                '<p>Estimado/a <strong>' + escapeHtml(userName) + '</strong>,</p>' +
                '<p>Se le ha asignado la solicitud ' + phraseSolicitud +
                (String.isBlank(customerNamePlain) ? '' : (' del cliente <strong>' + escapeHtml(customerNamePlain) + '</strong>')) +
                ' para su revisión antes de enviar a aprobación.</p>' +
                linkHtml +
                '<p style="margin-top:18px; font-size:12px; color:#6b7280;">Este correo fue generado automáticamente.</p>' +
            '</div>';
    }

    // DEMORA_INICIAR_ANALISIS
    private static String buildDemoraIniciarAnalisisHtml(OpportunityTCP__c o, String recordUrl) {
        System.debug('>>> TCP_EmailSenderInvocable.buildDemoraIniciarAnalisisHtml otcpId=' + (o == null ? null : o.Id));

        String otcpName = (o == null || String.isBlank(o.Name)) ? '(sin nombre)' : o.Name;
        String userName = (o == null || o.OTCP_AssignedAnalyst__r == null || String.isBlank(o.OTCP_AssignedAnalyst__r.Name))
            ? ''
            : o.OTCP_AssignedAnalyst__r.Name;

        String linkHtml = buildRecordLinkHtml(recordUrl);

        return
            '<div style="font-family: Arial, sans-serif; font-size: 14px; color: #1f1f1f;">' +
                '<p>Estimado/a <strong>' + escapeHtml(userName) + '</strong>,</p>' +
                '<p>La oportunidad <strong>' + escapeHtml(otcpName) + '</strong> fue asignada hace más de 15 min y el análisis aún no ha iniciado.</p>' +
                linkHtml +
                '<p style="margin-top:18px; font-size:12px; color:#6b7280;">Este correo fue generado automáticamente.</p>' +
            '</div>';
    }

    // DEMORA_TERMINAR_ANALISIS
    private static String buildDemoraTerminarAnalisisHtml(OpportunityTCP__c o, String recordUrl) {
        System.debug('>>> TCP_EmailSenderInvocable.buildDemoraTerminarAnalisisHtml otcpId=' + (o == null ? null : o.Id));

        String otcpName = (o == null || String.isBlank(o.Name)) ? '(sin nombre)' : o.Name;
        String userName = (o == null || o.OTCP_AssignedAnalyst__r == null || String.isBlank(o.OTCP_AssignedAnalyst__r.Name))
            ? ''
            : o.OTCP_AssignedAnalyst__r.Name;

        String linkHtml = buildRecordLinkHtml(recordUrl);

        return
            '<div style="font-family: Arial, sans-serif; font-size: 14px; color: #1f1f1f;">' +
                '<p>Estimado/a <strong>' + escapeHtml(userName) + '</strong>,</p>' +
                '<p>Iniciado pero sin interacción: la oportunidad <strong>' + escapeHtml(otcpName) + '</strong> lleva más de 15 min sin interacción del analista.</p>' +
                linkHtml +
                '<p style="margin-top:18px; font-size:12px; color:#6b7280;">Este correo fue generado automáticamente.</p>' +
            '</div>';
    }

    // -------- HELPERS BIENVENIDA CLIENTE --------
    private static String getCardTypeFromOTCP(OpportunityTCP__c o) {
        System.debug('>>> TCP_EmailSenderInvocable.getCardTypeFromOTCP otcpId=' + (o == null ? null : o.Id));

        if (o == null) return null;

        try {
            Object rawValue = o.get('OTCP_CardType__c');
            String cardType = (rawValue == null) ? null : String.valueOf(rawValue).trim();

            System.debug('>>> cardType dinámico=' + cardType);
            return cardType;

        } catch (Exception e) {
            System.debug('!!! ERROR getCardTypeFromOTCP: ' + e.getMessage());
            return null;
        }
    }

    private static EmailContent buildWelcomeEmailHtml(String cardType, String customerName, OpportunityTCP__c otcp) {
        System.debug('>>> TCP_EmailSenderInvocable.buildWelcomeEmailHtml cardType=' + cardType + ', customerName=' + customerName);

        try {
            if (String.isBlank(cardType)) {
                throw new OTCPEmailException('El tipo de tarjeta no puede ser vacío para BIENVENIDA_CLIENTE.');
            }

            List<TCP_Welcome_Config__mdt> configList = [
                SELECT DeveloperName,
                       Card_Type__c,
                       Card_Name__c,
                       Banner_URL__c,
                       QR_Benefits__c,
                       QR_Tarifario__c,
                       logo_url__c
                FROM TCP_Welcome_Config__mdt
                WHERE Card_Type__c = :cardType
                LIMIT 1
            ];

            System.debug('>>> Query TCP_Welcome_Config__mdt resultado=' + configList);

            if (configList.isEmpty()) {
                throw new OTCPEmailException('No existe configuración en TCP_Welcome_Config__mdt para tipo de tarjeta: ' + cardType);
            }

            TCP_Welcome_Config__mdt cfg = configList[0];

            String bannerUrl = getRequiredPublicUrl(cfg.Banner_URL__c, 'Banner_URL__c', cardType);
            String qrBenefitsUrl = getRequiredPublicUrl(cfg.QR_Benefits__c, 'QR_Benefits__c', cardType);
            String qrTarifarioUrl = getRequiredPublicUrl(cfg.QR_Tarifario__c, 'QR_Tarifario__c', cardType);
            String logoUrl = getRequiredPublicUrl(cfg.logo_url__c, 'logo_url__c', cardType);

            String htmlTemplate = getWelcomeTemplateHtml();

            String limiteDOP = formatCurrencyValue(otcp == null ? null : otcp.OTCP_limiteSugeridoDOP__c);
            String limiteUSD = formatCurrencyValue(otcp == null ? null : otcp.OTCP_limiteSugeridoUSD__c);

            htmlTemplate = htmlTemplate.replace('{{banner}}', escapeHtml(bannerUrl));
            htmlTemplate = htmlTemplate.replace('{{nombre}}', escapeHtml(String.isBlank(customerName) ? 'Cliente' : customerName));
            htmlTemplate = htmlTemplate.replace('{{card}}', escapeHtml(String.isBlank(cfg.Card_Name__c) ? cardType : cfg.Card_Name__c));
            htmlTemplate = htmlTemplate.replace('{{qrBenefits}}', escapeHtml(qrBenefitsUrl));
            htmlTemplate = htmlTemplate.replace('{{qrTarifario}}', escapeHtml(qrTarifarioUrl));
            htmlTemplate = htmlTemplate.replace('{{logoVimenca}}', escapeHtml(logoUrl));
            htmlTemplate = htmlTemplate.replace('{{limiteDOP}}', limiteDOP);
            htmlTemplate = htmlTemplate.replace('{{limiteUSD}}', limiteUSD);

            EmailContent content = new EmailContent();
            content.htmlBody = htmlTemplate;
            return content;

        } catch (Exception e) {
            System.debug('!!! ERROR buildWelcomeEmailHtml: ' + e.getMessage() + ' | ' + e.getStackTraceString());
            throw e;
        }
    }

    private static String getWelcomeTemplateHtml() {
        System.debug('>>> TCP_EmailSenderInvocable.getWelcomeTemplateHtml');

        List<StaticResource> templateList = [
            SELECT Id, Name, Body
            FROM StaticResource
            WHERE Name = :STATIC_RESOURCE_TEMPLATE
            LIMIT 1
        ];

        if (templateList.isEmpty()) {
            throw new OTCPEmailException('No existe el Static Resource del template: ' + STATIC_RESOURCE_TEMPLATE);
        }

        return templateList[0].Body.toString();
    }

    private static String getRequiredPublicUrl(String value, String fieldApiName, String cardType) {
        System.debug('>>> TCP_EmailSenderInvocable.getRequiredPublicUrl fieldApiName=' + fieldApiName + ', value=' + value);

        String cleanedValue = (value == null) ? null : value.trim();

        if (String.isBlank(cleanedValue)) {
            throw new OTCPEmailException(
                'El campo ' + fieldApiName + ' está vacío en TCP_Welcome_Config__mdt para tipo de tarjeta: ' + cardType
            );
        }

        if (!cleanedValue.startsWith('https://')) {
            throw new OTCPEmailException(
                'El campo ' + fieldApiName + ' debe contener una URL pública válida de imagen. Valor actual: ' + cleanedValue
            );
        }

        return cleanedValue;
    }

    private static String formatCurrencyValue(Decimal value) {
        System.debug('>>> TCP_EmailSenderInvocable.formatCurrencyValue value=' + value);

        try {
            if (value == null) {
                return '0.00';
            }

            Decimal scaledValue = value.setScale(2);
            String result = String.valueOf(scaledValue);

            System.debug('>>> formatCurrencyValue result=' + result);
            return result;

        } catch (Exception e) {
            System.debug('!!! ERROR formatCurrencyValue: ' + e.getMessage());
            System.debug('!!! StackTrace: ' + e.getStackTraceString());
            throw e;
        }
    }

    private static String escapeHtml(String s) {
        System.debug('>>> TCP_EmailSenderInvocable.escapeHtml s=' + s);
        if (s == null) return '';
        String x = s;
        x = x.replace('&', '&amp;');
        x = x.replace('<', '&lt;');
        x = x.replace('>', '&gt;');
        x = x.replace('"', '&quot;');
        x = x.replace('\'', '&#39;');
        return x;
    }
}