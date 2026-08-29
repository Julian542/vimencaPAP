@isTest
public class INT061BatchProcessTest {
    
    public static String CRON_EXP = '0 0 0 15 3 ? 2099';
    @isTest
    static void testBatch()
    {
        Test.setMock(HttpCalloutMock.class, new INT061TestMock('PJ'));
        Test.startTest();
        INT061BatchProcess testsche = new INT061BatchProcess();
        system.schedule('Test status Check', CRON_EXP, testsche );
        Test.stopTest();
    }
}
