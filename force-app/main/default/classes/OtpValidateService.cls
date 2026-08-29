public with sharing class OtpValidateService {

    private static final Integer DEFAULT_MAX_ATTEMPTS = 2;

    public class Request {
        @AuraEnabled public String email;
        @AuraEnabled public String otp;
    }

    public class Response {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public String status;
        @AuraEnabled public Integer remainingAttempts;
    }

    public static Response validate(Request req) {
        Response res = new Response();
        res.isValid = false;

        OTP_Challenge__c ch;

        try {
            String email = normalizeEmail(req == null ? null : req.email);
            String otp = (req == null ? null : req.otp);

            if (!isValidEmail(email) || String.isBlank(otp)) {
                res.status = !isValidEmail(email) ? 'INVALID_EMAIL' : 'INVALID';
                res.remainingAttempts = 0;
                return res;
            }

            List<OTP_Challenge__c> rows = [
                SELECT Id, Email__c, Salt__c, CodeHash__c, ExpiresAt__c,
                       Attempts__c, MaxAttempts__c, IsUsed__c, LastAttemptAt__c,
                       Status__c, LastError__c
                FROM OTP_Challenge__c
                WHERE Email__c = :email
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (rows.isEmpty()) {
                res.status = 'NOT_FOUND';
                res.remainingAttempts = 0;
                return res;
            }

            ch = rows[0];

            Integer maxAtt = (ch.MaxAttempts__c == null)
                ? DEFAULT_MAX_ATTEMPTS
                : Integer.valueOf(ch.MaxAttempts__c);

            Integer att = (ch.Attempts__c == null)
                ? 0
                : Integer.valueOf(ch.Attempts__c);

            if (ch.IsUsed__c == true) {
                res.status = 'USED';
                res.remainingAttempts = remaining(att, maxAtt);
                return res;
            }

            if (ch.ExpiresAt__c != null && System.now() > ch.ExpiresAt__c) {
                if (ch.Status__c != 'EXPIRED') {
                    ch.Status__c = 'EXPIRED';
                    ch.LastAttemptAt__c = System.now();
                    update ch;
                }

                res.status = 'EXPIRED';
                res.remainingAttempts = remaining(att, maxAtt);
                return res;
            }

            if (att >= maxAtt) {
                if (ch.Status__c != 'LOCKED') {
                    ch.Status__c = 'LOCKED';
                    ch.LastAttemptAt__c = System.now();
                    update ch;
                }

                res.status = 'MAX_ATTEMPTS';
                res.remainingAttempts = 0;
                return res;
            }

            String expectedHash = sha256Hex(ch.Salt__c + ':' + otp.trim());
            Boolean ok = (expectedHash == ch.CodeHash__c);

            if (!ok) {
                Integer newAtt = att + 1;

                ch.Attempts__c = newAtt;
                ch.LastAttemptAt__c = System.now();

                if (newAtt >= maxAtt) {
                    ch.Status__c = 'LOCKED';
                }

                update ch;

                Integer rem = remaining(newAtt, maxAtt);
                res.remainingAttempts = rem;

                res.status = (newAtt >= maxAtt) ? 'MAX_ATTEMPTS' : 'INVALID';
                return res;
            }

            ch.IsUsed__c = true;
            ch.LastAttemptAt__c = System.now();
            ch.Status__c = 'USED';
            ch.LastError__c = null;
            update ch;

            res.isValid = true;
            res.status = 'OK';
            res.remainingAttempts = 0;
            return res;

        } catch (Exception e) {
            try {
                if (ch != null && ch.Id != null) {
                    ch.LastError__c = safeErrorMessage(e);
                    update ch;
                }
            } catch (Exception ignore) {
            }

            res.status = 'ERROR';
            res.remainingAttempts = 0;
            return res;
        }
    }

    public class InvocableInput {
        @InvocableVariable(required=true)
        public String email;

        @InvocableVariable(required=true)
        public String otp;
    }

    public class InvocableOutput {
        @InvocableVariable public Boolean isValid;
        @InvocableVariable public String status;
        @InvocableVariable public Integer remainingAttempts;
    }

    @InvocableMethod
    public static List<InvocableOutput> validateOtp(List<InvocableInput> inputs) {
        List<InvocableOutput> results = new List<InvocableOutput>();

        for (InvocableInput i : inputs) {
            Request r = new Request();
            r.email = i.email;
            r.otp = i.otp;

            Response resp = validate(r);

            InvocableOutput out = new InvocableOutput();
            out.isValid = resp.isValid;
            out.status = resp.status;
            out.remainingAttempts = resp.remainingAttempts;

            results.add(out);
        }

        return results;
    }

    private static Integer remaining(Integer att, Integer maxAtt) {
        Integer a = (att == null) ? 0 : att;
        Integer m = (maxAtt == null || maxAtt <= 0) ? DEFAULT_MAX_ATTEMPTS : maxAtt;
        Integer rem = m - a;
        return rem < 0 ? 0 : rem;
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

    private static String sha256Hex(String input) {
        Blob b = Crypto.generateDigest('SHA-256', Blob.valueOf(input));
        return EncodingUtil.convertToHex(b);
    }

    private static String safeErrorMessage(Exception e) {
        String msg = (e == null) ? 'Unknown error' : e.getMessage();
        if (String.isBlank(msg)) msg = 'Unknown error';
        if (msg.length() > 1000) msg = msg.substring(0, 1000);
        return msg;
    }
}