@isTest
public class generalUtilsTest {
	@isTest
    public static void pickListGetLabelTest(){
        /* pickListGetLabel */
        String value = generalUtils.pickListGetLabel(Account.ACC_Condicion__c.getDescribe(), 'CLIENTE');
        System.assertEquals('CLIENTE', value);
        
        value = generalUtils.pickListGetLabel(Account.ACC_Condicion__c.getDescribe(), 'NO EXISTENTE');
        System.assertEquals('NO EXISTENTE', value);
    }
    @isTest 
    public static void getDateTest(){
        /* parseStringtoDate */
        Date stringToDate = generalUtils.parseStringtoDate('12/25/2019');
        Date dateTest = Date.newinstance(2019,12,25);
        System.assertEquals(stringToDate,dateTest);
        
        /* getDate */
        System.assertEquals(generalUtils.getDate(dateTest),'25/12/2019');
        
        /* getDate */
        DateTime dateTimeTest = DateTime.newinstance(2019, 12, 25, 3, 3, 3);
        System.assertEquals(generalUtils.getDateTime(dateTimeTest),'25/12/2019 03:03:03');
        
    }
}