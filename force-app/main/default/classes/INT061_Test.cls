@isTest
public class INT061_Test {
    @isTest
    static void createOrModifyPFTest()
    {
        List<Account> accList= TestDataFactory.createPersonAccounts(2);
		Test.setMock(HttpCalloutMock.class, new INT061TestMock('PJ'));
        Test.startTest();
        INT061.UpdateListOfBanks();
        Test.stopTest();
    }
    
     @isTest
    static void ClientINT061TriggerPersonAccTest()
    {
        Test.setMock(HttpCalloutMock.class, new INT061TestMock('PJ'));
        Account acc = new Account();
        Integer n=5;
        
        Datos_Maestros__c sector = new Datos_Maestros__c();
        sector.Name = 'Sector Test';
        sector.DM_Tipo__c = 'Sector';
        sector.DM_Distrito__c = '010101';
        insert sector;
        
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Fisica').getRecordTypeId();
        acc.lastname = 'Test Person Account ';
        
        acc.ACC_RNC__c = 'RNC';
        acc.ACC_CIF__c = 'TESTCIF';
        acc.ACC_Condicion__c='PROSPECTO';
        acc.ACC_Estado__c='INICIADO';
        acc.ACC_TipoIdentificacion__c='Cédula';
        acc.ACC_NumEmpleados__c=150;
        acc.ACC_Volumen_Ventas_Anual__c=1500000000;
        acc.ACC_Total_Activos__c=1500000000;
        acc.PersonBirthdate = date.today();
        
        insert acc;
                     
        Informacion_Financiera__c infoFinanciera = new Informacion_Financiera__c();
        infoFinanciera.INF_Cuenta__c = acc.Id;
        insert infoFinanciera;
        
        Direccion__c dir = new Direccion__c();
        dir.DIR_Principal__c = true;
        dir.DIR_Tipo_Direccion__c = 'Residencia';
        dir.DIR_Account__c = acc.Id;
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
        historial.HIS_Cuenta__c = acc.Id;
        insert historial;
        
        Referencia__c ref1 = new Referencia__c();
        Referencia__c ref2 = new Referencia__c();
        
        ref1.Account__c = acc.Id;
        ref2.Account__c = acc.Id;
        
        insert ref1;
        insert ref2;
        
        Vias_de_Contacto__c viaCont = new Vias_de_Contacto__c();
        viaCont.VIA_Principal__c = true;
        viaCont.VIA_Account__c = acc.Id;
        viaCont.VIA_de_Contacto__c = 'TELÉFONO FIJO';
        viaCont.VIA_Telefonica__c = 'Claro';
        viaCont.VIA_Numero_Correo__c = '8090000000';
        
        insert viaCont;
        
        Datos_Maestros__c actividad = new Datos_Maestros__c();
        actividad.DM_Tipo__c = 'Actividad Económica';
        insert actividad;
        
        /* convertimos */
        acc.ACC_Actividad_Economica__c = actividad.id;
        acc.PersonBirthdate = date.today();
        acc.ACC_Total_Activos__c=1500000000;
        acc.ACC_Persona_PEP__c = 'NO';
        acc.ACC_Resultado_Validacion__c = 'Test';
        acc.ACC_Tipo_Cliente_PF__c = '1';
        acc.ACC_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO';
        acc.ACC_Tipo_Actividad__c = 'AGUA';
        acc.ACC_Tipo_Sector__c = 'PUBLICO';
        acc.ACC_Fecha_Informacion__c = Datetime.now();
        acc.ACC_Total_activos__c = 1;
        acc.ACC_Moneda__c = 'DOP';
        acc.ACC_Ventas_Ingresos_Anuales__c = 1;
        acc.ACC_Patrimonio_Num__c = 1;
        acc.ACC_Calificacion_de_cliente__c = 'ALTO';
        acc.ACC_Fecha_de_calificacion__c = Date.today();
        acc.ACC_Estado__c='CONVERTIR';
        acc.ACC_Genero_Identificaci_n__c = 'Cédula Femenino	';
        acc.ACC_Genero__c = 'FEMENINO';
        acc.ACC_Estado_Civil__c = 'SOLTERO/A';
        acc.ACC_Tipo_Persona_PF__c = 'P5';
        acc.Tipo_de_vivienda__c = '1';
        
        update acc;
        
        Account aUp=[SELECT id , ACC_Apellido_FATCA__c FROM Account LIMIT 1];
        aUp.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        aUp.ACC_Estado__c ='new';
        aUp.ACC_Condicion__c='CLIENTE';
        aUp.ACC_Estado__c='CREADO';
        
        Test.startTest();
        update aUp;
        Test.stopTest();
    }   
}
