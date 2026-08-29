@IsTest
private class OtpValidateServiceTest {

    private static String sha256Hex(String input) {
        Blob b = Crypto.generateDigest('SHA-256', Blob.valueOf(input));
        return EncodingUtil.convertToHex(b);
    }

    private static OTP_Challenge__c createChallenge(
        String email,
        String otpPlain,
        Integer expiresInMinutes,   
        Integer attempts,
        Integer maxAttempts,
        Boolean isUsed,
        String status,              
        String salt
    ) {
        String normEmail = (email == null) ? null : email.trim().toLowerCase();

        OTP_Challenge__c ch = new OTP_Challenge__c();
        ch.Email__c = normEmail;

        ch.Salt__c = salt;
        ch.CodeHash__c = sha256Hex(salt + ':' + otpPlain.trim());

        if (expiresInMinutes != null) {
            ch.ExpiresAt__c = System.now().addMinutes(expiresInMinutes);
        }

        ch.Attempts__c = attempts;
        ch.MaxAttempts__c = maxAttempts;
        ch.IsUsed__c = isUsed;

        if (!String.isBlank(status)) {
            ch.Status__c = status;
        }

        insert ch;
        return ch;
    }

    private static OtpValidateService.Request req(String email, String otp) {
        OtpValidateService.Request r = new OtpValidateService.Request();
        r.email = email;
        r.otp = otp;
        return r;
    }

    @IsTest
    static void test_invalidEmail_returns_INVALID_EMAIL() {
        Test.startTest();
        OtpValidateService.Response res = OtpValidateService.validate(req('NO_ES_EMAIL', '123456'));
        Test.stopTest();

        System.assertEquals(false, res.isValid);
        System.assertEquals('INVALID_EMAIL', res.status);
        System.assertEquals(0, res.remainingAttempts);
    }

    @IsTest
    static void test_blankOtp_returns_INVALID() {
        Test.startTest();
        OtpValidateService.Response res = OtpValidateService.validate(req('test@acme.com', '   '));
        Test.stopTest();

        System.assertEquals(false, res.isValid);
        System.assertEquals('INVALID', res.status);
        System.assertEquals(0, res.remainingAttempts);
    }

    @IsTest
    static void test_notFound_returns_NOT_FOUND() {
        Test.startTest();
        OtpValidateService.Response res = OtpValidateService.validate(req('missing@acme.com', '123456'));
        Test.stopTest();

        System.assertEquals(false, res.isValid);
        System.assertEquals('NOT_FOUND', res.status);
        System.assertEquals(0, res.remainingAttempts);
    }

    @IsTest
    static void test_used_returns_USED() {
        String email = 'used@acme.com';
        createChallenge(
            email,
            '111111',
            10,
            0,
            2,
            true,
            'USED',   
            'SALT1'
        );

        Test.startTest();
        OtpValidateService.Response res = OtpValidateService.validate(req(email, '111111'));
        Test.stopTest();

        System.assertEquals(false, res.isValid);
        System.assertEquals('USED', res.status);
        System.assertEquals(2, res.remainingAttempts); 
    }

    @IsTest
    static void test_expired_marks_record_EXPIRED_and_returns_EXPIRED() {
        String email = 'expired@acme.com';
        OTP_Challenge__c ch = createChallenge(
            email,
            '222222',
            -5,      
            0,
            2,
            false,
            null,
            'SALT2'
        );

        Test.startTest();
        OtpValidateService.Response res = OtpValidateService.validate(req(email, '222222'));
        Test.stopTest();

        System.assertEquals(false, res.isValid);
        System.assertEquals('EXPIRED', res.status);
        System.assertEquals(2, res.remainingAttempts);

        OTP_Challenge__c after = [
            SELECT Status__c, LastAttemptAt__c
            FROM OTP_Challenge__c
            WHERE Id = :ch.Id
        ];
        System.assertEquals('EXPIRED', after.Status__c);
        System.assertNotEquals(null, after.LastAttemptAt__c);
    }

    @IsTest
    static void test_alreadyMaxAttempts_marks_LOCKED_and_returns_MAX_ATTEMPTS() {
        String email = 'locked@acme.com';
        OTP_Challenge__c ch = createChallenge(
            email,
            '333333',
            10,
            2,       
            2,
            false,
            null,
            'SALT3'
        );

        Test.startTest();
        OtpValidateService.Response res = OtpValidateService.validate(req(email, '333333'));
        Test.stopTest();

        System.assertEquals(false, res.isValid);
        System.assertEquals('MAX_ATTEMPTS', res.status);
        System.assertEquals(0, res.remainingAttempts);

        OTP_Challenge__c after = [
            SELECT Status__c, LastAttemptAt__c
            FROM OTP_Challenge__c
            WHERE Id = :ch.Id
        ];
        System.assertEquals('LOCKED', after.Status__c);
        System.assertNotEquals(null, after.LastAttemptAt__c);
    }

    @IsTest
    static void test_wrongOtp_incrementsAttempts_and_eventually_locks() {
        String email = 'wrong@acme.com';
        OTP_Challenge__c ch = createChallenge(
            email,
            '444444',
            10,
            0,
            2,
            false,
            null,
            'SALT4'
        );

        Test.startTest();

        OtpValidateService.Response r1 = OtpValidateService.validate(req(email, '999999'));
        OtpValidateService.Response r2 = OtpValidateService.validate(req(email, '888888'));

        Test.stopTest();

        System.assertEquals(false, r1.isValid);
        System.assertEquals('INVALID', r1.status);
        System.assertEquals(1, r1.remainingAttempts);

        System.assertEquals(false, r2.isValid);
        System.assertEquals('MAX_ATTEMPTS', r2.status);
        System.assertEquals(0, r2.remainingAttempts);

        OTP_Challenge__c after = [
            SELECT Attempts__c, Status__c
            FROM OTP_Challenge__c
            WHERE Id = :ch.Id
        ];
        System.assertEquals(2, Integer.valueOf(after.Attempts__c));
        System.assertEquals('LOCKED', after.Status__c);
    }

    @IsTest
    static void test_correctOtp_marks_used_and_returns_OK() {
        String email = 'ok@acme.com';
        OTP_Challenge__c ch = createChallenge(
            email,
            '555555',
            10,
            0,
            2,
            false,
            null,
            'SALT5'
        );

        Test.startTest();
        OtpValidateService.Response res = OtpValidateService.validate(req(email, '555555'));
        Test.stopTest();

        System.assertEquals(true, res.isValid);
        System.assertEquals('OK', res.status);
        System.assertEquals(0, res.remainingAttempts);

        OTP_Challenge__c after = [
            SELECT IsUsed__c, Status__c, LastAttemptAt__c, LastError__c
            FROM OTP_Challenge__c
            WHERE Id = :ch.Id
        ];
        System.assertEquals(true, after.IsUsed__c);
        System.assertEquals('USED', after.Status__c);
        System.assertNotEquals(null, after.LastAttemptAt__c);
        System.assertEquals(null, after.LastError__c);
    }

    @IsTest
    static void test_latestChallenge_is_used_due_to_orderByCreatedDateDesc() {
        String email = 'multi@acme.com';

        OTP_Challenge__c oldCh = createChallenge(
            email,
            '111111',
            10,
            0,
            2,
            false,
            null,
            'SALT_OLD'
        );
        Test.setCreatedDate(oldCh.Id, System.now().addMinutes(-30));

        OTP_Challenge__c newCh = createChallenge(
            email,
            '222222',
            10,
            0,
            2,
            false,
            null,
            'SALT_NEW'
        );

        Test.startTest();
        OtpValidateService.Response ok = OtpValidateService.validate(req(email, '222222'));
        Test.stopTest();

        System.assertEquals(true, ok.isValid);
        System.assertEquals('OK', ok.status);
        OtpValidateService.Response second = OtpValidateService.validate(req(email, '111111'));
        System.assertEquals(false, second.isValid);
        System.assertEquals('USED', second.status);
    }

    @IsTest
    static void test_invocable_validateOtp_returns_list() {
        String email = 'inv@acme.com';
        createChallenge(
            email,
            '666666',
            10,
            0,
            2,
            false,
            null,
            'SALT6'
        );

        OtpValidateService.InvocableInput input = new OtpValidateService.InvocableInput();
        input.email = email;
        input.otp = '666666';

        Test.startTest();
        List<OtpValidateService.InvocableOutput> out = OtpValidateService.validateOtp(
            new List<OtpValidateService.InvocableInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, out.size());
        System.assertEquals(true, out[0].isValid);
        System.assertEquals('OK', out[0].status);
        System.assertEquals(0, out[0].remainingAttempts);
    }
}