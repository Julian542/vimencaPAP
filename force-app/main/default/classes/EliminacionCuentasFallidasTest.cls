@isTest
public class EliminacionCuentasFallidasTest 
{
    public static String CRON_EXP = '0 0 0 15 3 ? 2099';

    @TestSetup
    static void prepareData(){
        
        TestDataFactory.createTestData();

        List<Asset> assetToUpdate = new List<Asset>();
        List<Case> lstCase = new List<Case>();
        
        List<Asset> cuentasFinancieras = [SELECT Id, CreatedDate, Accountid FROM Asset LIMIT 10];
        
        for(Asset cFinciera : cuentasFinancieras ){
            cFinciera.ASE_Fecha_de_apertura__c = null;
            cFinciera.ASE_Estado__c = 'PTE. APERTURA';
            Test.setCreatedDate(cFinciera.Id, System.today()-1);
            assetToUpdate.add(cFinciera);            
        	Case c = new Case();
            c.AssetId = cFinciera.Id;
            c.AccountId = cFinciera.AccountId;
            lstCase.add(c);
        }

        update assetToUpdate;
        insert lstCase;
    }

    @isTest
    static void testBatch()
    {
        Test.startTest();
        EliminacionCuentasFallidas testsche = new EliminacionCuentasFallidas();
        String jobID = System.schedule('Test status Check', CRON_EXP, testsche );
        List<CronTrigger > jobs= [SELECT Id FROM CronTrigger WHERE Id = :jobId]; 
        system.assert(jobs.size()>0);
        Test.stopTest();
        
    }
}
