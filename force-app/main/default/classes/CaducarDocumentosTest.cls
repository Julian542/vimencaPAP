@isTest
public class CaducarDocumentosTest 
{
    public static String CRON_EXP = '0 0 0 15 3 ? 2099';
    @isTest
    static void testBatch()
    {
        Test.startTest();
        CaducarDocumentos testsche = new CaducarDocumentos();
        system.schedule('Test status Check', CRON_EXP, testsche );
        Test.stopTest();
    }
}
