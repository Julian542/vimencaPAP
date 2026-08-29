@isTest
public class INT007_Test {
    @isTest
    static void createOrModifyPFTest()
    {
        List<Account> accList = TestDataFactory.createPersonAccounts(10);
        List<Direccion__c> direcciones = TestDataFactory.createDirecciones(accList);
        List<Vias_de_Contacto__c> viasList = TestDataFactory.createViasDeContacto(accList);
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
       
        Test.startTest();
        INT007.createOrModifyPF(accList[0].Id, 'action');
        Test.stopTest();
    }
    /*
    @isTest
    static void ClientINT007TriggerPersonAccTest()
    {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
        List<Account> accList = TestDataFactory.createPersonAccounts(2);
        List<Datos_Maestros__c> maestro = TestDataFactory.createDatosMaestro();
        
        Informacion_Financiera__c infoFinanciera = new Informacion_Financiera__c();
        infoFinanciera.INF_Cuenta__c = accList[0].Id;
        insert infoFinanciera;
        
        Datos_Maestros__c sector = new Datos_Maestros__c();
        sector.Name = 'Sector Test';
        sector.DM_Tipo__c = 'Sector';
        sector.DM_Distrito__c = '010101';
        insert sector;
        
        Direccion__c dir = new Direccion__c();
        dir.DIR_Principal__c = true;
        dir.DIR_Tipo_Direccion__c = 'Residencia';
        dir.DIR_Account__c = accList[0].Id;
        dir.DIR_Pais__c = 'DO';
        dir.DIR_Provincia__c = '01';
        dir.DIR_Municipio__c = '0101';
        dir.DIR_Distrito__c = '010101';
        dir.DIR_Distrito_texto__c = 'Distrito Test';
        dir.DIR_Numero__c = '1';
        dir.DIR_Sector__c = sector.id;
        dir.DIR_Calle__c = 'Calle Test';
        insert dir;
        
        Historial_laboral__c historial = new Historial_laboral__c();
        historial.HIS_Principal__c = true;
        historial.HIS_Cuenta__c = accList[0].Id;
        insert historial;
        
        Referencia__c ref1 = new Referencia__c();
        Referencia__c ref2 = new Referencia__c();
        
        ref1.Account__c = accList[0].Id;
        ref2.Account__c = accList[0].Id;
        
        insert ref1;
        insert ref2;
        
        Vias_de_Contacto__c viaCont = new Vias_de_Contacto__c();
        viaCont.VIA_Principal__c = true;
        viaCont.VIA_Account__c = accList[0].Id;
        viaCont.VIA_de_Contacto__c = 'TELÉFONO FIJO';
        viaCont.VIA_Telefonica__c = 'Claro';
        viaCont.VIA_Numero_Correo__c = '8090000000';
        
        insert viaCont;
        
        Datos_Maestros__c actividad = new Datos_Maestros__c();
        actividad.DM_Tipo__c = 'Actividad Económica';
        insert actividad;
        
        accList[0].lastname = 'Test Person Account ';
        
        accList[0].ACC_RNC__c = 'RNC';
        accList[0].ACC_CIF__c = 'TESTCIF';
        accList[0].ACC_Condicion__c='PROSPECTO';
        accList[0].ACC_Estado__c='CONVERTIR';
        accList[0].ACC_TipoIdentificacion__c='Cédula';
        accList[0].ACC_NumEmpleados__c=150;
        accList[0].ACC_Volumen_Ventas_Anual__c=1500000000;
        accList[0].ACC_Actividad_Economica__c = actividad.id;
        accList[0].PersonBirthdate = date.today();
        accList[0].ACC_Total_Activos__c=1500000000;
        accList[0].ACC_Persona_PEP__c = 'NO';
        accList[0].ACC_Resultado_Validacion__c = 'Test';
        accList[0].ACC_Tipo_Persona_PF__c = 'P5';
        accList[0].ACC_Tipo_Cliente_PF__c = '1';
        accList[0].ACC_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO';
        accList[0].ACC_Tipo_Actividad__c = 'AGUA';
        accList[0].ACC_Tipo_Sector__c = 'PUBLICO';
        accList[0].ACC_Fecha_Informacion__c = Datetime.now();
        accList[0].ACC_Total_activos__c = 1;
        accList[0].ACC_Moneda__c = 'DOP';
        accList[0].ACC_Ventas_Ingresos_Anuales__c = 1;
        
        update accList;
        
        Account aUp=[SELECT id , ACC_Apellido_FATCA__c FROM Account LIMIT 1];
        
        aUp.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId(); 
        update aUp;
        aUp.ACC_Estado__c ='new';
        aUp.ACC_Condicion__c='CLIENTE';
        aUp.ACC_Estado__c='CREADO';
        
        Test.startTest();
        update aUp; 
        //  update accList;
        Test.stopTest();
    }
    */

    /* -- NO TIENE SENTIDO ESTE TEST, LA INTEGRACION 007 ES PARA PERSONAS FISICAS Y NO JURIDICAS
    @isTest
    static void ClientINT007TriggerPersonJurdTest()
    {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PJ'));
        List<Account> accList =TestDataFactory.createPersonAccounts(2);
        accList[0].lastname = 'Test Person Account ';
        accList[0].ACC_Persona_Fisica__c=false;
        accList[0].ACC_RNC__c = 'RNC';
        accList[0].ACC_CIF__c = 'TESTCIF';
        accList[0].ACC_Condicion__c='PROSPECTO';
        accList[0].ACC_Estado__c='CONVERTIR';
        accList[0].ACC_TipoIdentificacion__c='Cédula';
        accList[0].ACC_NumEmpleados__c=150;
        accList[0].ACC_Volumen_Ventas_Anual__c=1500000000;
        accList[0].ACC_Total_Activos__c=1500000000;

        // update accList;
        /* Account aUp=[SELECT id , ACC_Apellido_FATCA__c FROM Account LIMIT 1];

aUp.ACC_Estado__c ='new';
aUp.ACC_Condicion__c='CLIENTE';
aUp.ACC_Estado__c='CREADO';*/
  
        /*Test.startTest();
        //update aUp;
        update accList;
        Test.stopTest();
    }*/
}