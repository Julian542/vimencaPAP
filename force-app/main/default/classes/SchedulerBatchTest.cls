@isTest
public class SchedulerBatchTest {
    // Dummy CRON expression: midnight on March 15.
    public static String CRON_EXP = '0 00 0 15 3 ? 2042';

    @isTest
    static void test(){
        Test.startTest();
        String jobId = System.schedule('SchedulerBatchTest',CRON_EXP, new SchedulerBatch());
        Test.stopTest();
    }
}