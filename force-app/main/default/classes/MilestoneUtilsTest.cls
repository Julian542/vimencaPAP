@isTest
public class MilestoneUtilsTest {
    @isTest
    public static void MilestoneTest(){
        //List<CaseMilestone> milestone = new List<CaseMilestone>();
        //milestone.add(new CaseMilestone());
        CaseMilestone milestone = new CaseMilestone();
     //   insert milestone;
        DateTime fecha= System.now();
        Test.startTest();
        MilestoneUtils.completeMilestone(new List<Id>{milestone.id},'Prueba', fecha);
        Test.stopTest();
    }
}