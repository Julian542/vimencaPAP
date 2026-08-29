public class FSC_NewCaseComponent_Controller {

    private static final String LEAD_TIPO_IDENTIFICACION_NATURAL_FIELD = 'LEA_TipoIdentificacion__c';
    private static final String LEAD_NUMERO_IDENTIFICACION_NATURAL_FIELD = 'LEA_NumIdentificacion__c';

    private static final String LEAD_TIPO_IDENTIFICACION_JURIDICA_FIELD = 'LEA_TipoIdentificacion__c';
    private static final String LEAD_RNC_FIELD = 'LEA_RNC__c';

    private static final String LEAD_TIPO_VINCULACION_FIELD = 'LEA_Tipo_Vinculacion__c';
    private static final String LEAD_TIPO_SECTOR_FIELD = 'LEA_Tipo_Sector__c';

    private static final String DEFAULT_TIPO_VINCULACION = 'SIN DEFINIR';
    private static final String DEFAULT_TIPO_SECTOR = 'NO DISPONIBLE';
    private static final String DEFAULT_LEAD_STATUS = 'Iniciado';

    private static final String RT_CANDIDATO_PERSONA_NATURAL = 'Candidato_Persona_Natural';
    private static final String RT_CANDIDATO_PERSONA_JURIDICA = 'Candidato_Persona_Juridica';

    @AuraEnabled(cacheable=true)
    public static String getPrimaryEmail(Id accountId) {

        List<ContactPointEmail> emails = [
            SELECT EmailAddress
            FROM ContactPointEmail
            WHERE ParentId = :accountId
            AND IsPrimary = true
            LIMIT 1
        ];

        if (!emails.isEmpty()) {
            return emails[0].EmailAddress;
        }

        return null;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean hasFinancialAccountTransactions(Id financialAccountId) {
        if (financialAccountId == null) {
            return false;
        }

        return [
            SELECT COUNT()
            FROM FinServ__FinancialAccountTransaction__c
            WHERE FinServ__FinancialAccount__c = :financialAccountId
        ] > 0;
    }

    @AuraEnabled
    public static Account getAccountInfo(Id accountId) {

        Account accounts = [
            SELECT Id, ACC_TipoIdentificacion__c, ACC_Branch__r.Name, OwnerId, Owner.Name
            FROM Account
            WHERE Id = :accountId
        ];
        
        return accounts;
    }

    @AuraEnabled
    public static Id getOrCreateCandidate(
        String tipoCandidato,
        String tipoIdentificacion,
        String numeroIdentificacion,
        String rnc,
        String firstName,
        String lastName,
        String company,
        String email,
        String phone
    ) {
        System.debug('========== INICIO getOrCreateCandidate ==========');
        System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | tipoCandidato: ' + tipoCandidato);
        System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | tipoIdentificacion: ' + tipoIdentificacion);
        System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | numeroIdentificacion: ' + numeroIdentificacion);
        System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | rnc: ' + rnc);
        System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | firstName: ' + firstName);
        System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | lastName: ' + lastName);
        System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | company: ' + company);
        System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | email: ' + email);
        System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | phone: ' + phone);

        if (String.isBlank(tipoCandidato)) {
            System.debug('ERROR getOrCreateCandidate | tipoCandidato viene vacío');
            throw new AuraHandledException('Debe indicar el tipo de candidato.');
        }

        if (String.isBlank(tipoIdentificacion)) {
            System.debug('ERROR getOrCreateCandidate | tipoIdentificacion viene vacío');
            throw new AuraHandledException('Debe indicar el tipo de identificación.');
        }

        tipoCandidato = tipoCandidato.trim();
        tipoIdentificacion = tipoIdentificacion.trim();

        Boolean isPersonaJuridica = tipoCandidato == 'Persona Jurídica';
        Boolean isPersonaNatural = tipoCandidato == 'Persona Natural';

        System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | isPersonaJuridica: ' + isPersonaJuridica);
        System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | isPersonaNatural: ' + isPersonaNatural);

        if (!isPersonaJuridica && !isPersonaNatural) {
            System.debug('ERROR getOrCreateCandidate | Tipo de candidato inválido: ' + tipoCandidato);
            throw new AuraHandledException('Tipo de candidato inválido. Use Persona Natural o Persona Jurídica.');
        }

        System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | Validando campo: ' + LEAD_TIPO_VINCULACION_FIELD);
        validateLeadField(LEAD_TIPO_VINCULACION_FIELD);

        System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | Validando campo: ' + LEAD_TIPO_SECTOR_FIELD);
        validateLeadField(LEAD_TIPO_SECTOR_FIELD);

        Id recordTypeId;
        String searchField;
        String searchValue;
        String tipoIdentificacionField;

        if (isPersonaJuridica) {
            System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | Rama Persona Jurídica');

            System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | Validando campo: ' + LEAD_TIPO_IDENTIFICACION_JURIDICA_FIELD);
            validateLeadField(LEAD_TIPO_IDENTIFICACION_JURIDICA_FIELD);

            System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | Validando campo: ' + LEAD_RNC_FIELD);
            validateLeadField(LEAD_RNC_FIELD);

            recordTypeId = getLeadRecordTypeId(RT_CANDIDATO_PERSONA_JURIDICA);
            searchField = LEAD_RNC_FIELD;
            searchValue = rnc;
            tipoIdentificacionField = LEAD_TIPO_IDENTIFICACION_JURIDICA_FIELD;

            if (String.isBlank(searchValue)) {
                System.debug('ERROR getOrCreateCandidate | RNC vacío para candidato jurídico');
                throw new AuraHandledException('Debe indicar el RNC del candidato jurídico.');
            }

            if (String.isBlank(company)) {
                System.debug('ERROR getOrCreateCandidate | company vacío para candidato jurídico');
                throw new AuraHandledException('Debe indicar la razón social del candidato jurídico.');
            }

        } else {
            System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | Rama Persona Natural');

            System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | Validando campo: ' + LEAD_TIPO_IDENTIFICACION_NATURAL_FIELD);
            validateLeadField(LEAD_TIPO_IDENTIFICACION_NATURAL_FIELD);

            System.debug('FSC_NewCaseComponent_Controller.getOrCreateCandidate | Validando campo: ' + LEAD_NUMERO_IDENTIFICACION_NATURAL_FIELD);
            validateLeadField(LEAD_NUMERO_IDENTIFICACION_NATURAL_FIELD);

            recordTypeId = getLeadRecordTypeId(RT_CANDIDATO_PERSONA_NATURAL);
            searchField = LEAD_NUMERO_IDENTIFICACION_NATURAL_FIELD;
            searchValue = numeroIdentificacion;
            tipoIdentificacionField = LEAD_TIPO_IDENTIFICACION_NATURAL_FIELD;

            if (String.isBlank(searchValue)) {
                System.debug('ERROR getOrCreateCandidate | Número de identificación vacío para candidato persona');
                throw new AuraHandledException('Debe indicar el número de identificación del candidato persona.');
            }

            if (String.isBlank(lastName)) {
                System.debug('ERROR getOrCreateCandidate | lastName vacío para candidato persona');
                throw new AuraHandledException('Debe indicar el apellido del candidato.');
            }
        }

        searchValue = searchValue.trim();

        String query =
            'SELECT Id, FirstName, LastName, Company, Email, Phone, RecordTypeId, ' +
            tipoIdentificacionField + ', ' +
            searchField + ' ' +
            'FROM Lead ' +
            'WHERE RecordTypeId = :recordTypeId ' +
            'AND ' + searchField + ' = :searchValue ' +
            'AND ' + tipoIdentificacionField + ' = :tipoIdentificacion ' +
            'LIMIT 1';

        List<Lead> existingLeads = Database.query(query);

        if (!existingLeads.isEmpty()) {
            return existingLeads[0].Id;
        }

        Lead nuevoLead = new Lead();
        nuevoLead.RecordTypeId = recordTypeId;

        if (!String.isBlank(email)) {
            nuevoLead.Email = email.trim();
        }

        if (!String.isBlank(phone)) {
            nuevoLead.Phone = phone.trim();
        }

        if (isPersonaJuridica) {
            nuevoLead.Company = company.trim();
            nuevoLead.LastName = company.trim();

            nuevoLead.put(LEAD_TIPO_IDENTIFICACION_JURIDICA_FIELD, tipoIdentificacion);
            nuevoLead.put(LEAD_RNC_FIELD, searchValue);

        } else {
            if (!String.isBlank(firstName)) {
                nuevoLead.FirstName = firstName.trim();
            }

            nuevoLead.LastName = lastName.trim();
            nuevoLead.Company = 'Prospecto No Cliente';

            nuevoLead.put(LEAD_TIPO_IDENTIFICACION_NATURAL_FIELD, tipoIdentificacion);
            nuevoLead.put(LEAD_NUMERO_IDENTIFICACION_NATURAL_FIELD, searchValue);
        }

        nuevoLead.put(LEAD_TIPO_VINCULACION_FIELD, DEFAULT_TIPO_VINCULACION);
        nuevoLead.put(LEAD_TIPO_SECTOR_FIELD, DEFAULT_TIPO_SECTOR);
        nuevoLead.Status = DEFAULT_LEAD_STATUS;

        insert nuevoLead;

        return nuevoLead.Id;
    }

    @TestVisible
    private static void validateLeadField(String fieldApiName) {

        Map<String, Schema.SObjectField> leadFields =
            Schema.SObjectType.Lead.fields.getMap();

        if (!leadFields.containsKey(fieldApiName)) {
            throw new AuraHandledException(
                'El campo ' + fieldApiName + ' no existe en Lead. Ajuste el API name en FSC_NewCaseComponent_Controller.'
            );
        }
    }

    @TestVisible
    private static Id getLeadRecordTypeId(String developerName) {

        Map<String, Schema.RecordTypeInfo> recordTypesByDeveloperName =
            Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName();

        if (!recordTypesByDeveloperName.containsKey(developerName)) {
            throw new AuraHandledException(
                'No existe el Record Type de Lead con DeveloperName: ' + developerName
            );
        }

        return recordTypesByDeveloperName.get(developerName).getRecordTypeId();
    }

    @TestVisible
    private static String getDefaultLeadStatus() {

        List<LeadStatus> statuses = [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsDefault = true
            LIMIT 1
        ];

        if (!statuses.isEmpty()) {
            return statuses[0].MasterLabel;
        }

        return null;
    }

    @AuraEnabled
    public static String getOficinaLabel() {

        String oficina = UserInfo.getUserId() != null
            ? [SELECT USE_Oficina__c FROM User WHERE Id = :UserInfo.getUserId()].USE_Oficina__c
            : null;

        return formatOficinaLabel(oficina);
    }

    @TestVisible
    private static String formatOficinaLabel(String oficina) {

        if (String.isBlank(oficina)) {
            return '';
        }

        Map<String, String> oficinasMap = new Map<String, String>{
            '1'  => System.Label.Oficina_1,
            '2'  => System.Label.Oficina_2,
            '3'  => System.Label.Oficina_3,
            '4'  => System.Label.Oficina_4,
            '5'  => System.Label.Oficina_5,
            '6'  => System.Label.Oficina_6,
            '7'  => System.Label.Oficina_7,
            '8'  => System.Label.Oficina_8,
            '9'  => System.Label.Oficina_9,
            '10' => System.Label.Oficina_10,
            '11' => System.Label.Oficina_11,
            '12' => System.Label.Oficina_12
        };

        if (oficinasMap.containsKey(oficina)) {
            return oficina + ' - ' + oficinasMap.get(oficina);
        }

        return '';
    }

    @AuraEnabled
    public static FinServ__FinancialAccount__c getAccountNumber(Id accountId) {

        FinServ__FinancialAccount__c accounts = [
            SELECT Id, FinServ__FinancialAccountNumber__c, FIN_Linea_de_producto__c
            FROM FinServ__FinancialAccount__c
            WHERE FinServ__PrimaryOwner__c = :accountId
        ];
 
        return accounts;
    }

    @AuraEnabled
    public static FinServ__FinancialAccount__c getOneFinnAccountNumber(Id accountId) {

        System.debug(accountId);

        FinServ__FinancialAccount__c accounts = [
            SELECT Id,
                FinServ__FinancialAccountNumber__c,
                FIN_Linea_de_producto__c,
                FIN_Monto_disponible__c,
                FIN_Moneda__c,
                FIN_Producto__c,
                FIN_Producto__r.Name,
                RecordType.DeveloperName,
                FinServ__CloseDate__c,
                FinServ__PaymentDueDate__c,
                FinServ__TotalCreditLimit__c,
                FIN_Limite_Credito_USD__c,
                FinServ__PrincipalBalance__c
            FROM FinServ__FinancialAccount__c
            WHERE Id = :accountId
            LIMIT 1
        ];

        System.debug('acc ' + accounts);
        return accounts;
    }

    @AuraEnabled
    public static FinServ__FinancialAccount__c getFinnAccountNumber(Id accountId, Id notInclude) {

        FinServ__FinancialAccount__c accounts = [
            SELECT Id, FinServ__FinancialAccountNumber__c, FIN_Linea_de_producto__c
            FROM FinServ__FinancialAccount__c
            WHERE Id = :accountId
            AND Id != :notInclude
        ];
 
        return accounts;
    }

    @AuraEnabled
    public static void uploadFile(Id recordId, String fileName, String base64Data) {

        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        insert cv;

        Id contentDocumentId = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'V';

        insert cdl;
    }

    @AuraEnabled(cacheable=true)
    public static Id getSupportQueueId() {
        System.debug('FSC_NewCaseComponent_Controller.getSupportQueueId | Inicio');

        try {
            List<Group> queues = [
                SELECT Id, DeveloperName, Name
                FROM Group
                WHERE Type = 'Queue'
                AND DeveloperName = 'Soporte_TI_Produccion'
                LIMIT 1
            ];

            if (!queues.isEmpty()) {
                return queues[0].Id;
            }

            return null;

        } catch (Exception e) {
            System.debug('FSC_NewCaseComponent_Controller.getSupportQueueId | Error: ' + e.getMessage());
            return null;
        }
    }

    public static void sendEmail(String emailTo, String emailSubject, String emailBody) {

        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setToAddresses(new List<String>{ emailTo });
        msg.setSubject(emailSubject);
        msg.setPlainTextBody(emailBody);
        msg.setReplyTo('bv_reclamos@bv.com.do');
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ msg });
    }

    public class Input {

        @InvocableVariable
        public String emailTo;

        @InvocableVariable
        public String emailSubject;

        @InvocableVariable
        public String emaiemailBodylTo;
    }

    @InvocableMethod(label='Enviar email creacion de caso')
    public static void procesar(List<Input> inputs) {

        sendEmail(inputs[0].emailTo, inputs[0].emailSubject, inputs[0].emaiemailBodylTo);
    }

    public class FamiliarAdicionalOption {
        @AuraEnabled public Id contactId;
        @AuraEnabled public String nombre;
        @AuraEnabled public String parentesco;

        public FamiliarAdicionalOption(Id contactId, String nombre, String parentesco) {
            this.contactId = contactId;
            this.nombre = nombre;
            this.parentesco = parentesco;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<FamiliarAdicionalOption> getFamiliaresAdicionales(Id accountId) {
        List<FamiliarAdicionalOption> result = new List<FamiliarAdicionalOption>();

        if (accountId == null) {
            return result;
        }

        Account acc = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        if (acc.PersonContactId == null) {
            return result;
        }

        List<FinServ__ContactContactRelation__c> relaciones = [
            SELECT Id,
                RecordType.DeveloperName,
                FinServ__Contact__c,
                FinServ__Contact__r.Name,
                FinServ__RelatedContact__c,
                FinServ__RelatedContact__r.Name,
                FinServ__Role__c,
                FinServ__Role__r.Name
            FROM FinServ__ContactContactRelation__c
            WHERE RecordType.DeveloperName = 'Familiar'
            AND (
                FinServ__Contact__c = :acc.PersonContactId
                OR FinServ__RelatedContact__c = :acc.PersonContactId
            )
            ORDER BY CreatedDate DESC
        ];

        for (FinServ__ContactContactRelation__c rel : relaciones) {
            Id familiarContactId;
            String familiarNombre;

            if (rel.FinServ__Contact__c == acc.PersonContactId) {
                familiarContactId = rel.FinServ__RelatedContact__c;
                familiarNombre = rel.FinServ__RelatedContact__r != null
                    ? rel.FinServ__RelatedContact__r.Name
                    : null;
            } else {
                familiarContactId = rel.FinServ__Contact__c;
                familiarNombre = rel.FinServ__Contact__r != null
                    ? rel.FinServ__Contact__r.Name
                    : null;
            }

            if (familiarContactId != null) {
                result.add(
                    new FamiliarAdicionalOption(
                        familiarContactId,
                        familiarNombre,
                        rel.FinServ__Role__r != null
                            ? rel.FinServ__Role__r.Name
                            : ''
                    )
                );
            }
        }

        return result;
    }

}