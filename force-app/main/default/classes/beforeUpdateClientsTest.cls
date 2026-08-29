@isTest
public class beforeUpdateClientsTest 
{
    @isTest
    static void updateAccountMicro()
    {
         List<Account> accList =TestDataFactory.createJuridicAccounts(2);
        //acc.lastname = 'Test Person Account ';
        accList[0].Name='Some';
        accList[0].ACC_RNC__c = 'RNC';
        accList[0].ACC_CIF__c = 'TESTCIF';
       // accList[0].ACC_TipoIdentificacion__c='Cédula';
        accList[0].ACC_Persona_Fisica__c=false;
        accList[0].ACC_Cliente_Conocido__c=false;
        accList[0].ACC_Coincidencia_Listas_Internas__c=false;
        //accList[0].ACC_Condicion__c='CLIENTE';
        accList[0].ACC_Tipo_Organizacion__c='FIDEICOMISOS';
        accList[0].ACC_NumEmpleados__c=1;
        accList[0].ACC_Volumen_Ventas_Anual__c=1;
        accList[0].ACC_Total_Activos__c=1;
        
        update accList;
        Account aUp=[SELECT id , ACC_Apellido_FATCA__c FROM Account LIMIT 1];
        
        aUp.Description ='new';
        aUp.ACC_Tipo_Organizacion__c='FIDEICOMISOS';
        Test.startTest();
        update aUp;
        Test.stopTest();
    }
    
        @isTest
    static void updateAccountPeq()
    {
        List<Account> accList =TestDataFactory.createJuridicAccounts(1);	       
        //acc.lastname = 'Test Person Account ';
        accList[0].Name='Some';
        accList[0].ACC_RNC__c = 'RNC';
        accList[0].ACC_CIF__c = 'TESTCIF';
       // accList[0].ACC_TipoIdentificacion__c='Cédula';
        accList[0].ACC_Persona_Fisica__c=false;
        accList[0].ACC_Cliente_Conocido__c=false;
        accList[0].ACC_Coincidencia_Listas_Internas__c=false;
       // accList[0].ACC_Condicion__c='CLIENTE';
        accList[0].ACC_Tipo_Organizacion__c='CONSORCIOS';
        accList[0].ACC_NumEmpleados__c=150;
        accList[0].ACC_Volumen_Ventas_Anual__c=5000000;
        accList[0].ACC_Total_Activos__c=5000000;
        
        update accList;
        Account aUp=[SELECT id , ACC_Apellido_FATCA__c FROM Account LIMIT 1];
        
        aUp.Description ='new';
        aUp.ACC_Tipo_Organizacion__c='FIDEICOMISOS';
        
        Test.startTest();
        update aUp;
        Test.stopTest();
    }
    
            @isTest
    static void updateAccountMed()
    {
        Account acc = new Account();
        Integer n=5;
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Personas_Juridicas').getRecordTypeId();
        //acc.lastname = 'Test Person Account ';
        acc.Name='Some';
        acc.ACC_RNC__c = 'RNC';
        acc.ACC_CIF__c = 'TESTCIF';
       // acc.ACC_TipoIdentificacion__c='Cédula';
        acc.ACC_Persona_Fisica__c=false;
        acc.ACC_Cliente_Conocido__c=false;
        acc.ACC_Coincidencia_Listas_Internas__c=false;
      //  acc.ACC_Condicion__c='CLIENTE';
        acc.ACC_Tipo_Organizacion__c='CONSORCIOS';
        acc.ACC_NumEmpleados__c=150;
        acc.ACC_Volumen_Ventas_Anual__c=15000000;
        acc.ACC_Total_Activos__c=15000000;
        
        insert acc;
        Account aUp=[SELECT id , ACC_Apellido_FATCA__c FROM Account LIMIT 1];
        
        aUp.Description ='new';
        
        Test.startTest();
        update aUp;
        Test.stopTest();
    }
    
              @isTest
    static void updateAccountCorp()
    {
        Account acc = new Account();
        Integer n=5;
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Personas_Juridicas').getRecordTypeId();
        //acc.lastname = 'Test Person Account ';
        acc.Name='Some';
        acc.ACC_RNC__c = 'RNC';
        acc.ACC_CIF__c = 'TESTCIF';
        //acc.ACC_TipoIdentificacion__c='Cédula';
        acc.ACC_Persona_Fisica__c=false;
        acc.ACC_Cliente_Conocido__c=false;
        acc.ACC_Coincidencia_Listas_Internas__c=false;
      //  acc.ACC_Condicion__c='CLIENTE';
        acc.ACC_NumEmpleados__c=150;
        acc.ACC_Volumen_Ventas_Anual__c=150000000;
        acc.ACC_Total_Activos__c=150000000;
        
        insert acc;
        Account aUp=[SELECT id , ACC_Apellido_FATCA__c FROM Account LIMIT 1];
        
        aUp.Description ='new';
        aUp.ACC_Tipo_Organizacion__c='FIDEICOMISOS';
        Test.startTest();
        update aUp;
        Test.stopTest();
    }
}