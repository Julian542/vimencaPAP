/**
 * @description       : 
 * @author            : Luisina Platino (lplatino@keystoneadvisors.cl)
 * @group             : 
 * @last modified on  : 04-12-2025
 * @last modified by  : Luisina Platino (lplatino@keystoneadvisors.cl)
**/
@isTest
private with sharing class UtilVariablesTest {

    @IsTest
    static void generalTest(){

        Boolean expected = true;
        Boolean actual;

        System.runAs(new User(Id = UserInfo.getUserId())){

            UtilVariables instance;

            Test.startTest();
                System.debug(LoggingLevel.DEBUG, UtilVariables.DEV_RT_BANCARIA);
                System.debug(LoggingLevel.DEBUG, UtilVariables.DEV_RT_COMERCIAL);
                System.debug(LoggingLevel.DEBUG, UtilVariables.DEV_RT_PERSONA_FISICA);
                System.debug(LoggingLevel.DEBUG, UtilVariables.DEV_RT_PERSONA_JURIDICA);
                System.debug(LoggingLevel.DEBUG, UtilVariables.DEV_RT_PERSONAL);
                System.debug(LoggingLevel.DEBUG, UtilVariables.RES_STATUS);

                instance = new UtilVariables();
            Test.stopTest();

            actual = instance != null;

            System.assertEquals(expected, actual, '[!] instance is null');
        }
    }
}