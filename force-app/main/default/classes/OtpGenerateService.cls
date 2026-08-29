public with sharing class OtpGenerateService {

    private static final Integer OTP_LENGTH = 6;
    private static final Integer TTL_MINUTES = 10;
    private static final Integer MAX_ATTEMPTS = 2;

    private class OtpGenerateServiceException extends Exception {}

    @TestVisible private static Boolean forceEmailSendFailure = false;
    @TestVisible private static Boolean forceEmailException = false;
    @TestVisible private static Boolean forceGenerateExceptionAfterInsert = false;

    public class Request {
        @AuraEnabled public String email;
    }

    public class Response {
        @AuraEnabled public String otp;
        @AuraEnabled public Boolean sent;
        @AuraEnabled public Datetime expiresAt;
        @AuraEnabled public Id challengeId;
        @AuraEnabled public String status;
    }

    public static Response generate(Request req) {
        Response res = new Response();
        OTP_Challenge__c ch;

        try {
            String email = normalizeEmail(req == null ? null : req.email);
            if (!isValidEmail(email)) {
                res.status = 'INVALID_EMAIL';
                res.sent = false;
                res.otp = null;
                return res;
            }

            String otp = generateNumericOtp(OTP_LENGTH);

            String salt = randomHex(16);

            String hashHex = sha256Hex(salt + ':' + otp);
            Datetime exp = System.now().addMinutes(TTL_MINUTES);

            ch = new OTP_Challenge__c();
            ch.Email__c = email;
            ch.Salt__c = salt;
            ch.CodeHash__c = hashHex;
            ch.ExpiresAt__c = exp;
            ch.Attempts__c = 0;
            ch.MaxAttempts__c = MAX_ATTEMPTS;
            ch.IsUsed__c = false;
            ch.Status__c = 'CREATED';
            ch.LastError__c = null;
            ch.Otp_BORRAR_EN_PRODUCCION__c = otp;

            insert ch;

            if (forceGenerateExceptionAfterInsert) {
                throw new OtpGenerateServiceException('Forced generate exception');
            }

            Boolean sent = sendOtpEmail(email, ch.Id);

            ch.Status__c = sent ? 'SENT' : 'SEND_FAILED';
            if (!sent) {
                ch.LastError__c = 'Email delivery failed or blocked by org deliverability/settings.';
            }
            update ch;

            res.otp = otp;
            res.sent = sent;
            res.expiresAt = exp;
            res.challengeId = ch.Id;
            res.status = 'OK';
            return res;

        } catch (Exception e) {
            try {
                if (ch != null && ch.Id != null) {
                    ch.Status__c = 'SEND_FAILED';
                    ch.LastError__c = safeErrorMessage(e);
                    update ch;
                }
            } catch (Exception ignore) {
            }

            res.status = 'ERROR';
            res.sent = false;
            res.otp = null;
            return res;
        }
    }

    public class InvocableInput {
        @InvocableVariable(required=true)
        public String email;
    }

    public class InvocableOutput {
        @InvocableVariable public String otp;
        @InvocableVariable public Boolean sent;
        @InvocableVariable public Datetime expiresAt;
        @InvocableVariable public String challengeId;
        @InvocableVariable public String status;
    }

    @InvocableMethod(
        label='Generate OTP'
        description='Genera un OTP, crea el desafío y envía el código por correo. Devuelve estado, expiración e id del desafío.'
    )
    public static List<InvocableOutput> sendOtp(List<InvocableInput> inputs) {
        List<InvocableOutput> results = new List<InvocableOutput>();

        for (InvocableInput i : inputs) {
            Request r = new Request();
            r.email = i.email;

            Response resp = generate(r);

            InvocableOutput out = new InvocableOutput();
            out.otp = resp.otp;
            out.sent = resp.sent;
            out.expiresAt = resp.expiresAt;
            out.challengeId = (resp.challengeId == null) ? null : String.valueOf(resp.challengeId);
            out.status = resp.status;

            results.add(out);
        }

        return results;
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

    private static String generateNumericOtp(Integer len) {
        Integer L = (len == null || len <= 0) ? 6 : len;
        Integer max = (Integer) Math.pow(10, L);
        Integer n = Math.mod(Crypto.getRandomInteger(), max);
        if (n < 0) n = -n;
        return String.valueOf(n).leftPad(L, '0');
    }

    private static String sha256Hex(String input) {
        Blob b = Crypto.generateDigest('SHA-256', Blob.valueOf(input));
        return EncodingUtil.convertToHex(b);
    }

    @TestVisible
    private static String randomHex(Integer bytesLen) {
        Integer lenBytes = (bytesLen == null || bytesLen <= 0) ? 16 : bytesLen;

        Integer keyBits = pickAesKeyBits(lenBytes);

        Blob b = Crypto.generateAesKey(keyBits);
        String hex = EncodingUtil.convertToHex(b);

        Integer hexLen = lenBytes * 2;
        if (hex.length() > hexLen) {
            hex = hex.substring(0, hexLen);
        }
        return hex;
    }

    @TestVisible
    private static Integer pickAesKeyBits(Integer bytesNeeded) {
        if (bytesNeeded <= 16) return 128;
        if (bytesNeeded <= 24) return 192;
        return 256;
    }

    private static Boolean sendOtpEmail(String toEmail, Id challengeId) {
        try {
            if (forceEmailException) {
                throw new OtpGenerateServiceException('Forced email exception');
            }
            if (forceEmailSendFailure) {
                return false;
            }

            EmailTemplate tpl = [
                SELECT Id
                FROM EmailTemplate
                WHERE DeveloperName = 'OTP_Banco_Vimenca'
                LIMIT 1
            ];

            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setTemplateId(tpl.Id);
            msg.setTargetObjectId(UserInfo.getUserId());
            msg.setTreatTargetObjectAsRecipient(false);
            msg.setToAddresses(new List<String>{ toEmail });
            msg.setWhatId(challengeId);
            msg.setSaveAsActivity(false);

            Messaging.SendEmailResult[] r =
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { msg });

            return (r != null && !r.isEmpty() && r[0].isSuccess());
        } catch (Exception e) {
            return false;
        }
    }

    @TestVisible
    private static String safeErrorMessage(Exception e) {
        String msg = (e == null) ? 'Unknown error' : e.getMessage();
        if (String.isBlank(msg)) msg = 'Unknown error';
        if (msg.length() > 1000) msg = msg.substring(0, 1000);
        return msg;
    }
}