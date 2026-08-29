@IsTest
private class OtpGenerateServiceTest {

    private static String uniqueEmail() {
        return 'test.otp.' + System.now().getTime() + '@example.com';
    }

    private static OTP_Challenge__c getLastChallengeByEmail(String email) {
        List<OTP_Challenge__c> rows = [
            SELECT Id, Email__c, Salt__c, CodeHash__c, ExpiresAt__c,
                   Attempts__c, MaxAttempts__c, IsUsed__c, Status__c, LastError__c, CreatedDate
            FROM OTP_Challenge__c
            WHERE Email__c = :email
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0];
    }

    @IsTest
    static void test_generate_null_request_invalid_email() {
        Test.startTest();
        OtpGenerateService.Response res = OtpGenerateService.generate(null);
        Test.stopTest();

        System.assertEquals('INVALID_EMAIL', res.status);
        System.assertEquals(false, res.sent);
        System.assertEquals(null, res.otp);
        System.assertEquals(null, res.challengeId);
    }

    @IsTest
    static void test_generate_blank_email_invalid() {
        OtpGenerateService.Request req = new OtpGenerateService.Request();
        req.email = '   ';

        OtpGenerateService.Response res = OtpGenerateService.generate(req);

        System.assertEquals('INVALID_EMAIL', res.status);
        System.assertEquals(false, res.sent);
        System.assertEquals(null, res.otp);
        System.assertEquals(null, res.challengeId);
    }

    @IsTest
    static void test_generate_invalid_email_variants() {
        List<String> bads = new List<String>{
            '',
            '   ',
            'a@',
            'a@b',
            'a@b.',
            '@domain.com',
            'a domain@x.com',
            'a@domain,com'
        };

        for (String b : bads) {
            OtpGenerateService.Request req = new OtpGenerateService.Request();
            req.email = b;

            OtpGenerateService.Response res = OtpGenerateService.generate(req);

            System.assertEquals('INVALID_EMAIL', res.status, 'Debe ser INVALID_EMAIL para: ' + b);
            System.assertEquals(false, res.sent);
            System.assertEquals(null, res.otp);
            System.assertEquals(null, res.challengeId);
        }
    }

    @IsTest
    static void test_generate_normalizes_email_trim_and_lowercase() {
        String raw = '   FlorHarmath+OTP@GMAIL.COM   ';
        String normalized = 'florharmath+otp@gmail.com';

        OtpGenerateService.Request req = new OtpGenerateService.Request();
        req.email = raw;

        Test.startTest();
        OtpGenerateService.Response res = OtpGenerateService.generate(req);
        Test.stopTest();

        System.assertEquals('OK', res.status);
        System.assertNotEquals(null, res.challengeId);

        OTP_Challenge__c ch = [
            SELECT Email__c
            FROM OTP_Challenge__c
            WHERE Id = :res.challengeId
            LIMIT 1
        ];
        System.assertEquals(normalized, ch.Email__c);
    }

    @IsTest
    static void test_generate_creates_challenge_and_updates_status() {
        String email = uniqueEmail();

        OtpGenerateService.Request req = new OtpGenerateService.Request();
        req.email = email;

        Datetime beforeCall = System.now();

        Test.startTest();
        OtpGenerateService.Response res = OtpGenerateService.generate(req);
        Test.stopTest();

        System.assertEquals('OK', res.status);
        System.assertNotEquals(null, res.challengeId);
        System.assertNotEquals(null, res.expiresAt);
        System.assertNotEquals(null, res.otp);

        // OTP de 6 y numérico
        System.assertEquals(6, res.otp.length());
        System.assertEquals('', res.otp.replaceAll('\\d', ''), 'OTP debe ser numérico');

        // ExpiresAt ~ 10 min (tolerancia 9-11)
        Long diffSeconds = (res.expiresAt.getTime() - beforeCall.getTime()) / 1000;
        System.assert(
            diffSeconds >= 9 * 60 && diffSeconds <= 11 * 60,
            'ExpiresAt aprox +10 min. Diff=' + diffSeconds
        );

        OTP_Challenge__c ch = getLastChallengeByEmail(email.toLowerCase());
        System.assertNotEquals(null, ch);

        System.assertEquals(email.toLowerCase(), ch.Email__c);
        System.assertNotEquals(null, ch.Salt__c);
        System.assertNotEquals(null, ch.CodeHash__c);
        System.assertEquals(false, ch.IsUsed__c);
        System.assertEquals(0, Integer.valueOf(ch.Attempts__c));
        System.assertEquals(2, Integer.valueOf(ch.MaxAttempts__c));

        // status final debe ser SENT o SEND_FAILED
        System.assert(
            ch.Status__c == 'SENT' || ch.Status__c == 'SEND_FAILED',
            'Status__c debe ser SENT o SEND_FAILED. Actual=' + ch.Status__c
        );

        if (res.sent == true) {
            System.assertEquals('SENT', ch.Status__c);
        } else {
            System.assertEquals('SEND_FAILED', ch.Status__c);
            System.assertNotEquals(null, ch.LastError__c);
        }
    }

    @IsTest
    static void test_invocable_sendOtp_single_input() {
        String email = uniqueEmail();

        OtpGenerateService.InvocableInput input = new OtpGenerateService.InvocableInput();
        input.email = email;

        Test.startTest();
        List<OtpGenerateService.InvocableOutput> outs =
            OtpGenerateService.sendOtp(new List<OtpGenerateService.InvocableInput>{ input });
        Test.stopTest();

        System.assertEquals(1, outs.size());
        System.assertEquals('OK', outs[0].status);
        System.assertNotEquals(null, outs[0].challengeId);
        System.assertNotEquals(null, outs[0].expiresAt);
        System.assertNotEquals(null, outs[0].otp);
        System.assertEquals(6, outs[0].otp.length());

        OTP_Challenge__c ch = getLastChallengeByEmail(email.toLowerCase());
        System.assertNotEquals(null, ch);
    }

    @IsTest
    static void test_invocable_sendOtp_multiple_inputs() {
        String e1 = 'multi1.' + System.now().getTime() + '@example.com';
        String e2 = 'multi2.' + System.now().getTime() + '@example.com';

        OtpGenerateService.InvocableInput i1 = new OtpGenerateService.InvocableInput();
        i1.email = e1;

        OtpGenerateService.InvocableInput i2 = new OtpGenerateService.InvocableInput();
        i2.email = e2;

        Test.startTest();
        List<OtpGenerateService.InvocableOutput> outs =
            OtpGenerateService.sendOtp(new List<OtpGenerateService.InvocableInput>{ i1, i2 });
        Test.stopTest();

        System.assertEquals(2, outs.size());
        System.assertEquals('OK', outs[0].status);
        System.assertEquals('OK', outs[1].status);

        Integer countChallenges = [
            SELECT COUNT()
            FROM OTP_Challenge__c
            WHERE Email__c IN :new List<String>{ e1.toLowerCase(), e2.toLowerCase() }
        ];
        System.assertEquals(2, countChallenges);
    }

    @IsTest
    static void test_invocable_sendOtp_null_email_in_input() {
        OtpGenerateService.InvocableInput i = new OtpGenerateService.InvocableInput();
        i.email = null;

        Test.startTest();
        List<OtpGenerateService.InvocableOutput> outs =
            OtpGenerateService.sendOtp(new List<OtpGenerateService.InvocableInput>{ i });
        Test.stopTest();

        System.assertEquals(1, outs.size());
        System.assertEquals('INVALID_EMAIL', outs[0].status);
        System.assertEquals(false, outs[0].sent);
        System.assertEquals(null, outs[0].otp);
        System.assertEquals(null, outs[0].challengeId);
    }

    @IsTest
    static void test_generate_email_send_failure() {
        OtpGenerateService.forceEmailSendFailure = true;

        OtpGenerateService.Request req = new OtpGenerateService.Request();
        req.email = uniqueEmail();

        OtpGenerateService.Response res = OtpGenerateService.generate(req);

        System.assertEquals('OK', res.status);
        System.assertEquals(false, res.sent);

        OtpGenerateService.forceEmailSendFailure = false;
    }

    @IsTest
    static void test_generate_forced_exception_after_insert() {
        String email = uniqueEmail();
        OtpGenerateService.forceGenerateExceptionAfterInsert = true;

        OtpGenerateService.Request req = new OtpGenerateService.Request();
        req.email = email;

        OtpGenerateService.Response res = OtpGenerateService.generate(req);
        OTP_Challenge__c ch = getLastChallengeByEmail(email.toLowerCase());

        System.assertEquals('ERROR', res.status);
        System.assertEquals(false, res.sent);
        System.assertEquals('SEND_FAILED', ch.Status__c);

        OtpGenerateService.forceGenerateExceptionAfterInsert = false;
    }

    @IsTest
    static void test_email_exception_and_helper_edges() {
        OtpGenerateService.forceEmailException = true;

        OtpGenerateService.Request req = new OtpGenerateService.Request();
        req.email = uniqueEmail();

        OtpGenerateService.Response res = OtpGenerateService.generate(req);

        System.assertEquals('OK', res.status);
        System.assertEquals(false, res.sent);
        System.assertEquals(50, OtpGenerateService.randomHex(25).length());

        OtpGenerateService.forceEmailException = false;
        OtpGenerateService.safeErrorMessage(null);
    }
}