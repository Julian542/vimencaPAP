public with sharing class IdentityIdValidationService {

    private static final String ACTIVE_STATUS = 'ACTIVO';
    private static final Integer MAX_QUERY_ROWS = 10;

    public class Request {
        @AuraEnabled public String identificationNumber;
        @AuraEnabled public String messagingSessionId;
    }

    public class Response {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public String status;

        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountType;
        @AuraEnabled public String accountStatus;

        @AuraEnabled public String email;
        @AuraEnabled public String maskedEmail;

        @AuraEnabled public Integer matches;

        @AuraEnabled public Boolean sessionLinked;
        @AuraEnabled public String sessionLinkMessage;
    }

    public static Response validate(Request req) {
        Response res = new Response();
        res.isValid = false;
        res.matches = 0;
        res.sessionLinked = false;

        Account found;

        try {
            String raw = (req == null) ? null : req.identificationNumber;

            if (String.isBlank(raw) || !isValidIdentificationInput(raw)) {
                res.status = 'INVALID_INPUT';
                return res;
            }

            String normalized = normalizeId(raw);

            if (String.isBlank(normalized) || normalized.length() < 5) {
                res.status = 'INVALID_INPUT';
                return res;
            }

            Set<String> lookupValues = buildLookupValues(raw, normalized);

            List<Account> personActiveCandidates = [
                SELECT Id, Name, ACC_Estado__c, ACC_Correo_Electronico_Cliente__c, ACC_NumIdentificacion__c
                FROM Account
                WHERE ACC_NumIdentificacion__c IN :lookupValues
                  AND ACC_Estado__c = :ACTIVE_STATUS
                LIMIT :MAX_QUERY_ROWS
            ];

            List<Account> personActive = filterPersonAccounts(personActiveCandidates, normalized);

            if (!personActive.isEmpty()) {
                res.matches = personActive.size();
                if (personActive.size() > 1) {
                    res.status = 'MULTIPLE_ACTIVE';
                    return res;
                }
                found = personActive[0];
                res.accountType = 'PERSON';
            } else {
                List<Account> businessActiveCandidates = [
                    SELECT Id, Name, ACC_Estado__c, ACC_Correo_Electronico_Cliente__c, ACC_RNC__c
                    FROM Account
                    WHERE ACC_RNC__c IN :lookupValues
                      AND ACC_Estado__c = :ACTIVE_STATUS
                    LIMIT :MAX_QUERY_ROWS
                ];

                List<Account> businessActive = filterBusinessAccounts(businessActiveCandidates, normalized);

                if (!businessActive.isEmpty()) {
                    res.matches = businessActive.size();
                    if (businessActive.size() > 1) {
                        res.status = 'MULTIPLE_ACTIVE';
                        return res;
                    }
                    found = businessActive[0];
                    res.accountType = 'BUSINESS';
                }
            }

            if (found == null) {
                Account anyPerson = findAnyById(normalized, lookupValues);
                if (anyPerson != null) {
                    res.status = 'NOT_ACTIVE';
                    res.accountId = anyPerson.Id;
                    res.accountName = anyPerson.Name;
                    res.accountStatus = anyPerson.ACC_Estado__c;
                    res.accountType = 'PERSON';
                    return res;
                }

                Account anyBiz = findAnyByRnc(normalized, lookupValues);
                if (anyBiz != null) {
                    res.status = 'NOT_ACTIVE';
                    res.accountId = anyBiz.Id;
                    res.accountName = anyBiz.Name;
                    res.accountStatus = anyBiz.ACC_Estado__c;
                    res.accountType = 'BUSINESS';
                    return res;
                }

                res.status = 'NOT_FOUND';
                return res;
            }

            res.accountId = found.Id;
            res.accountName = found.Name;
            res.accountStatus = found.ACC_Estado__c;

            String email = normalizeEmail(found.ACC_Correo_Electronico_Cliente__c);

            if (String.isBlank(email)) {
                res.status = 'NO_EMAIL';
                return res;
            }

            if (!isValidEmail(email)) {
                res.status = 'INVALID_EMAIL';
                return res;
            }

            res.email = email;
            res.maskedEmail = maskEmail(email);

            linkMessagingSessionToAccount(req == null ? null : req.messagingSessionId, found.Id, res);

            res.isValid = true;
            res.status = 'OK';
            return res;

        } catch (Exception e) {
            res.status = 'ERROR';
            res.sessionLinkMessage = e.getMessage();
            return res;
        }
    }

    public class InvocableInput {
        @InvocableVariable(required=true)
        public String identificationNumber;

        @InvocableVariable(required=false)
        public String messagingSessionId;
    }

    public class InvocableOutput {
        @InvocableVariable public Boolean isValid;
        @InvocableVariable public String status;

        @InvocableVariable public String accountId;
        @InvocableVariable public String accountName;
        @InvocableVariable public String accountType;
        @InvocableVariable public String accountStatus;

        @InvocableVariable public String email;
        @InvocableVariable public String maskedEmail;

        @InvocableVariable public Integer matches;

        @InvocableVariable public Boolean sessionLinked;
        @InvocableVariable public String sessionLinkMessage;
    }

    @InvocableMethod
    public static List<InvocableOutput> validateInvocable(List<InvocableInput> inputs) {
        List<InvocableOutput> results = new List<InvocableOutput>();

        if (inputs == null) {
            return results;
        }

        for (InvocableInput i : inputs) {
            Request r = new Request();
            r.identificationNumber = i.identificationNumber;
            r.messagingSessionId = i.messagingSessionId;

            Response resp = validate(r);

            InvocableOutput out = new InvocableOutput();
            out.isValid = resp.isValid;
            out.status = resp.status;

            out.accountId = (resp.accountId == null) ? null : String.valueOf(resp.accountId);
            out.accountName = resp.accountName;
            out.accountType = resp.accountType;
            out.accountStatus = resp.accountStatus;

            out.email = resp.email;
            out.maskedEmail = resp.maskedEmail;

            out.matches = resp.matches;

            out.sessionLinked = resp.sessionLinked;
            out.sessionLinkMessage = resp.sessionLinkMessage;

            results.add(out);
        }

        return results;
    }

    private static void linkMessagingSessionToAccount(String messagingSessionId, Id accountId, Response res) {
        if (String.isBlank(messagingSessionId) || accountId == null) {
            res.sessionLinked = false;
            res.sessionLinkMessage = 'No se recibió messagingSessionId o accountId.';
            return;
        }

        List<MessagingSession> sessions = [
            SELECT Id, Cliente__c
            FROM MessagingSession
            WHERE Id = :messagingSessionId
            LIMIT 1
        ];

        if (sessions.isEmpty()) {
            res.sessionLinked = false;
            res.sessionLinkMessage = 'No se encontró la MessagingSession.';
            return;
        }

        MessagingSession ms = sessions[0];
        ms.Cliente__c = accountId;
        update ms;

        res.sessionLinked = true;
        res.sessionLinkMessage = 'Sesión vinculada correctamente.';
    }

    private static Account findAnyById(String normalized, Set<String> lookupValues) {
        List<Account> rows = [
            SELECT Id, Name, ACC_Estado__c, ACC_NumIdentificacion__c
            FROM Account
            WHERE ACC_NumIdentificacion__c IN :lookupValues
            ORDER BY CreatedDate DESC
            LIMIT :MAX_QUERY_ROWS
        ];

        List<Account> filtered = filterPersonAccounts(rows, normalized);
        return filtered.isEmpty() ? null : filtered[0];
    }

    private static Account findAnyByRnc(String normalized, Set<String> lookupValues) {
        List<Account> rows = [
            SELECT Id, Name, ACC_Estado__c, ACC_RNC__c
            FROM Account
            WHERE ACC_RNC__c IN :lookupValues
            ORDER BY CreatedDate DESC
            LIMIT :MAX_QUERY_ROWS
        ];

        List<Account> filtered = filterBusinessAccounts(rows, normalized);
        return filtered.isEmpty() ? null : filtered[0];
    }

    private static List<Account> filterPersonAccounts(List<Account> candidates, String normalizedInput) {
        List<Account> matches = new List<Account>();

        if (candidates == null || String.isBlank(normalizedInput)) {
            return matches;
        }

        for (Account acc : candidates) {
            if (idsMatch(acc.ACC_NumIdentificacion__c, normalizedInput)) {
                matches.add(acc);
            }
        }

        return matches;
    }

    private static List<Account> filterBusinessAccounts(List<Account> candidates, String normalizedInput) {
        List<Account> matches = new List<Account>();

        if (candidates == null || String.isBlank(normalizedInput)) {
            return matches;
        }

        for (Account acc : candidates) {
            if (idsMatch(acc.ACC_RNC__c, normalizedInput)) {
                matches.add(acc);
            }
        }

        return matches;
    }

    private static Boolean idsMatch(String storedValue, String normalizedInput) {
        if (String.isBlank(storedValue) || String.isBlank(normalizedInput)) {
            return false;
        }

        return normalizeId(storedValue) == normalizedInput;
    }

    private static Boolean isValidIdentificationInput(String input) {
        if (String.isBlank(input)) {
            return false;
        }

        String s = input.trim();
        s = s.replaceAll('\\s+', '');

        if (String.isBlank(s)) {
            return false;
        }

        Pattern p = Pattern.compile('^[0-9-]+$');
        return p.matcher(s).matches();
    }

    private static String normalizeId(String input) {
        if (input == null) {
            return null;
        }

        String s = input.trim();

        if (String.isBlank(s)) {
            return null;
        }

        s = s.replaceAll('\\s+', '');
        s = s.replace('-', '');

        return s;
    }

    private static Set<String> buildLookupValues(String raw, String normalized) {
        Set<String> values = new Set<String>();

        if (!String.isBlank(raw)) {
            String trimmed = raw.trim();
            addIfNotBlank(values, trimmed);
            addIfNotBlank(values, trimmed.replaceAll('\\s+', ''));
        }

        addIfNotBlank(values, normalized);

        // Formato estándar de cédula: 001-0880361-0
        addIfNotBlank(values, formatCedulaStandard(normalized));

        // Formato que tiene Vimenca en el campo: 00-1088036-10
        addIfNotBlank(values, formatCedulaVimenca(normalized));

        // Formato RNC: 1-01-99999-9
        addIfNotBlank(values, formatRnc(normalized));

        return values;
    }

    private static void addIfNotBlank(Set<String> values, String valueToAdd) {
        if (values == null || String.isBlank(valueToAdd)) {
            return;
        }

        values.add(valueToAdd);
    }

    private static String formatCedulaStandard(String normalized) {
        if (String.isBlank(normalized) || normalized.length() != 11 || !isDigitsOnly(normalized)) {
            return null;
        }

        return normalized.substring(0, 3) + '-' +
               normalized.substring(3, 10) + '-' +
               normalized.substring(10, 11);
    }

    private static String formatCedulaVimenca(String normalized) {
        if (String.isBlank(normalized) || normalized.length() != 11 || !isDigitsOnly(normalized)) {
            return null;
        }

        return normalized.substring(0, 2) + '-' +
               normalized.substring(2, 9) + '-' +
               normalized.substring(9, 11);
    }

    private static String formatRnc(String normalized) {
        if (String.isBlank(normalized) || normalized.length() != 9 || !isDigitsOnly(normalized)) {
            return null;
        }

        return normalized.substring(0, 1) + '-' +
               normalized.substring(1, 3) + '-' +
               normalized.substring(3, 8) + '-' +
               normalized.substring(8, 9);
    }

    private static Boolean isDigitsOnly(String value) {
        if (String.isBlank(value)) {
            return false;
        }

        Pattern p = Pattern.compile('^[0-9]+$');
        return p.matcher(value).matches();
    }

    private static String normalizeEmail(String email) {
        if (email == null) return null;
        return email.trim().toLowerCase();
    }

    private static Boolean isValidEmail(String email) {
        if (String.isBlank(email)) return false;
        Pattern p = Pattern.compile('^[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}$');
        return p.matcher(email).matches();
    }

    private static String maskEmail(String email) {
        if (String.isBlank(email) || !email.contains('@')) return null;

        List<String> parts = email.split('@');
        String user = parts[0];
        String domain = parts[1];

        String userMasked = (user.length() <= 2)
            ? user.substring(0, 1) + '***'
            : user.substring(0, 2) + '***';

        String domainMasked;
        Integer dot = domain.lastIndexOf('.');
        if (dot > 0) {
            String base = domain.substring(0, dot);
            String tld = domain.substring(dot);
            String baseMasked = (base.length() <= 2)
                ? base.substring(0, 1) + '***'
                : base.substring(0, 2) + '***';
            domainMasked = baseMasked + tld;
        } else {
            domainMasked = (domain.length() <= 2)
                ? domain.substring(0, 1) + '***'
                : domain.substring(0, 2) + '***';
        }

        return userMasked + '@' + domainMasked;
    }
}