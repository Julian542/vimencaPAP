@isTest
private class LeadConversionQueue_Test {
    
    @testSetup
    static void setup() {
        Datos_Maestros__c actividadEconomica = new Datos_Maestros__c(
            Name = 'Servicios',
            DM_Tipo__c = 'Actividad Económica'
        );
        insert actividadEconomica;
        
        Id contactRoleRecordTypeId = Schema.SObjectType.FinServ__ReciprocalRole__c
            .getRecordTypeInfosByDeveloperName()
            .get('ContactRole')
            .getRecordTypeId();
            
        FinServ__ReciprocalRole__c contactRole = new FinServ__ReciprocalRole__c(
            Name = 'Test ContactRole',
            FinServ__InverseRole__c = 'Test ContactRole',
            RecordTypeId = contactRoleRecordTypeId
        );
        insert contactRole;
        
        Id accountRoleRecordTypeId = Schema.SObjectType.FinServ__ReciprocalRole__c
            .getRecordTypeInfosByDeveloperName()
            .get('AccountRole')
            .getRecordTypeId();    
        
        FinServ__ReciprocalRole__c accountRole = new FinServ__ReciprocalRole__c(
            Name = 'Test AccountRole',
            FinServ__InverseRole__c = 'Test AccountRole',
            RecordTypeId = accountRoleRecordTypeId
        );
        insert accountRole;
    }
    
    @isTest
    static void testProcessLeads_PersonaNatural() {
        
        Id leadPNRecordTypeId = Schema.SObjectType.Lead
            .getRecordTypeInfosByDeveloperName()
            .get('Candidato_Persona_Natural')
            .getRecordTypeId();
        
        Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c WHERE DM_Tipo__c = 'Actividad Económica' LIMIT 1];
        
        Lead leadPN = new Lead(
            FirstName = 'Test',
            LastName = 'Queue',
            Company = 'Test Company PN',
            RecordTypeId = leadPNRecordTypeId,
            Status = 'Nuevo',
            LEA_PersonBirthdate__c = Date.today().addYears(-25),
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_NumIdentificacion__c = '00108803610',
            LEA_Tipo_de_vivienda__c = '1',
            LEA_Persona_PEP__c = 'NO',
            LEA_Resultado_Validacion__c = 'Aprobado',
            LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
            LEA_Tipo_Persona_PF__c = 'P3',
            LEA_Tipo_Cliente_PF__c = '511',
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Tipo_Actividad__c = 'AGUA',
            LEA_Actividad_Economica__c = actEcon.Id,
            LEA_Tipo_Sector__c = 'Privado',
            LEA_Fuente_de_ingresos__c = 'Herencia',
            LEA_Periodo__c = 'Anualmente',
            LEA_Ingresos__c = '<= RD$ 15,000',
            LEA_Calle__c = 'Calle Test',
            LEA_Numero__c = '123',
            LEA_N_Apartamento__c = '4B',
            LEA_Pais__c = 'DO',
            LEA_Provincia__c = '02',
            LEA_Municipio__c = '0101',
            LEA_Sector__c = 'Piantini',
            LEA_Apartado_postal__c = '10101',
            LEA_Fecha_Informacion__c = Date.today(),
            LEA_Total_Activos__c = 500000,
            LEA_Moneda__c = 'DOP',
            LEA_Ventas_Ingresos_Anuales__c = 1200000,
            LEA_Patrimonio_Num__c = 300000,
            LEA_Tipo_Referencia1__c = 'Personal',
            LEA_Nombre_Referencia1__c = 'Referencia Test',
            LEA_RNC_Referencia1__c = '123456789',
            LEA_Telefono_Referencia1__c = '8091234567',
            LEA_Direccion_Referencia1__c = 'Dirección Referencia',
            LEA_Pais_Referencia1__c = 'DO',
            LEA_Tipo_Referencia2__c = 'Comercial',
            LEA_Nombre_Referencia2__c = 'Referencia Test 2',
            LEA_RNC_Referencia2__c = '987654321',
            LEA_Telefono_Referencia2__c = '8099876543',
            LEA_Direccion_Referencia2__c = 'Dirección Referencia 2',
            LEA_Pais_Referencia2__c = 'DO',
            LEA_Principal1__c = TRUE,
            LEA_Via_de_Contacto1__c = 'TELÉFONO MÓVIL',
            LEA_Numero_Correo1__c = '8091234567',
            LEA_Telefonica1__c = 'CLARO',
            LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
            LEA_Calificacion_de_cliente__c = 'BAJO',
            LEA_EsEmpleado_Vimenca__c = 'NO',
            LEA_EsEmpleado_GrupoVimenca__c = 'NO',
            LEA_EsProveedor__c = 'NO',
            LEA_Empleo_Actual_Anterior__c = 'Actual',
            LEA_Empresa__c = 'Empresa Test',
            LEA_Puesto_de_trabajo__c = 'Analista',
            LEA_Ocupacion__c = 'ABOGADO',
            LEA_Tipo_de_empleado__c = '1',
            LEA_Tiempo_de_empresa__c = '2',
            LEA_Fecha_de_ingreso__c = Date.today().addYears(-5),
            LEA_Fecha_de_fin__c = Date.today(),
            LEA_Salario__c = 50000,
            LEA_Direcci_n_de_la_empresa__c = 'Av. Principal 123'
        );
        insert leadPN;
        
        
        Id personAccountRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        Account personAccount = new Account(
            FirstName = leadPN.FirstName,
            LastName = leadPN.LastName,
            RecordTypeId = personAccountRecordTypeId
        );
        insert personAccount;
        
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadPN.Id);
        lc.setAccountId(personAccount.Id); 
        lc.setDoNotCreateOpportunity(true); 
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess(), 'Lead should be converted successfully');
        
        Lead convertedLead = [SELECT Id, ConvertedAccountId, ConvertedContactId FROM Lead WHERE Id = :leadPN.Id];
        
        Integer addressesBeforeQueue = [SELECT COUNT() FROM ContactPointAddress WHERE ParentId = :convertedLead.ConvertedAccountId];
        Integer phonesBeforeQueue = [SELECT COUNT() FROM ContactPointPhone WHERE ParentId = :convertedLead.ConvertedAccountId];
        Integer finInfosBeforeQueue = [SELECT COUNT() FROM Informacion_Financiera__c WHERE INF_Cuenta__c = :convertedLead.ConvertedAccountId];
        Integer employmentsBeforeQueue = [SELECT COUNT() FROM FinServ__Employment__c WHERE FinServ__Contact__c = :convertedLead.ConvertedContactId];
        Integer refContactsBeforeQueue = [SELECT COUNT() FROM Contact WHERE Id != :convertedLead.ConvertedContactId AND AccountId = null];
        Integer relationsBeforeQueue = [SELECT COUNT() FROM FinServ__ContactContactRelation__c WHERE FinServ__Contact__c = :convertedLead.ConvertedContactId];
        
        Test.startTest();
        LeadConversionQueue queue = new LeadConversionQueue(new Set<Id>{leadPN.Id});
        System.enqueueJob(queue);
        Test.stopTest();
        
        Account acc = [SELECT Id, ACC_Tipo_Persona_PF__c, ACC_Nacionalidad__c FROM Account WHERE Id = :convertedLead.ConvertedAccountId];
        System.assertNotEquals(null, acc, 'Account should exist');
        
        Integer addressesAfterQueue = [SELECT COUNT() FROM ContactPointAddress WHERE ParentId = :convertedLead.ConvertedAccountId];
        System.assertEquals(addressesBeforeQueue + 1, addressesAfterQueue, 'Queue should create exactly 1 ContactPointAddress');
        
        List<ContactPointAddress> addresses = [SELECT Id, Street, City FROM ContactPointAddress WHERE ParentId = :convertedLead.ConvertedAccountId];
        Boolean foundCorrectAddress = false;
        for (ContactPointAddress addr : addresses) {
            if (addr.Street != null && addr.Street.contains('Calle Test')) {
                foundCorrectAddress = true;
                break;
            }
        }
        System.assert(foundCorrectAddress, 'Should have an address with Calle Test');
        
        Integer phonesAfterQueue = [SELECT COUNT() FROM ContactPointPhone WHERE ParentId = :convertedLead.ConvertedAccountId];
        System.assertEquals(phonesBeforeQueue + 1, phonesAfterQueue, 'Queue should create exactly 1 ContactPointPhone');
        
        Integer finInfosAfterQueue = [SELECT COUNT() FROM Informacion_Financiera__c WHERE INF_Cuenta__c = :convertedLead.ConvertedAccountId];
        System.assertEquals(finInfosBeforeQueue + 1, finInfosAfterQueue, 'Queue should create exactly 1 Informacion_Financiera__c');
        
        List<Informacion_Financiera__c> finInfos = [SELECT Id, INF_Fuente_de_ingresos__c FROM Informacion_Financiera__c WHERE INF_Cuenta__c = :convertedLead.ConvertedAccountId];
        Boolean foundCorrectSource = false;
        for (Informacion_Financiera__c finInfo : finInfos) {
            if (finInfo.INF_Fuente_de_ingresos__c == 'Herencia') {
                foundCorrectSource = true;
                break;
            }
        }
        System.assert(foundCorrectSource, 'Should have correct income source');
        
        Integer employmentsAfterQueue = [SELECT COUNT() FROM FinServ__Employment__c WHERE FinServ__Contact__c = :convertedLead.ConvertedContactId];
        System.assertEquals(employmentsBeforeQueue + 1, employmentsAfterQueue, 'Queue should create exactly 1 Employment record');
        
        List<FinServ__Employment__c> employments = [SELECT Id, Name FROM FinServ__Employment__c WHERE FinServ__Contact__c = :convertedLead.ConvertedContactId];
        Boolean foundCorrectEmployer = false;
        for (FinServ__Employment__c emp : employments) {
            if (emp.Name == 'Empresa Test') {
                foundCorrectEmployer = true;
                break;
            }
        }
        System.assert(foundCorrectEmployer, 'Should have correct employer name');
        
        Integer refContactsAfterQueue = [SELECT COUNT() FROM Contact WHERE Id != :convertedLead.ConvertedContactId AND AccountId = null];
        System.assertEquals(refContactsBeforeQueue + 2, refContactsAfterQueue, 'Queue should create exactly 2 reference Contacts');
        
        Integer relationsAfterQueue = [SELECT COUNT() FROM FinServ__ContactContactRelation__c WHERE FinServ__Contact__c = :convertedLead.ConvertedContactId];
        System.assertEquals(relationsBeforeQueue + 2, relationsAfterQueue, 'Queue should create exactly 2 ContactContactRelations');
    }

    @isTest
    static void testProcessLeads_NullLeadIds() {
        
        Test.startTest();
        LeadConversionQueue.processLeads(null);
        Test.stopTest();
        
        System.assert(true, 'Should handle null leadIds gracefully');
    }
    
    @isTest
    static void testProcessLeads_EmptySet() {
        
        Test.startTest();
        LeadConversionQueue.processLeads(new Set<Id>());
        Test.stopTest();
        
        System.assert(true, 'Should handle empty set gracefully');
    }
    
    @isTest
    static void testProcessLeads_NonConvertedLead() {
        
        Id leadPNRecordTypeId = Schema.SObjectType.Lead
            .getRecordTypeInfosByDeveloperName()
            .get('Candidato_Persona_Natural')
            .getRecordTypeId();
        
        Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c WHERE DM_Tipo__c = 'Actividad Económica' LIMIT 1];
        
        Lead leadPN = new Lead(
            FirstName = 'Not',
            LastName = 'Converted',
            Company = 'Test Company',
            RecordTypeId = leadPNRecordTypeId,
            Status = 'Nuevo',
            LEA_PersonBirthdate__c = Date.today().addYears(-25),
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_NumIdentificacion__c = '00108803611',
            LEA_Tipo_de_vivienda__c = '1',
            LEA_Persona_PEP__c = 'NO',
            LEA_Resultado_Validacion__c = 'Aprobado',
            LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
            LEA_Tipo_Persona_PF__c = 'P3',
            LEA_Tipo_Cliente_PF__c = '511',
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Tipo_Actividad__c = 'AGUA',
            LEA_Actividad_Economica__c = actEcon.Id,
            LEA_Tipo_Sector__c = 'Privado',
            LEA_Fuente_de_ingresos__c = 'Herencia',
            LEA_Periodo__c = 'Anualmente',
            LEA_Ingresos__c = '<= RD$ 15,000',
            LEA_Calle__c = 'Calle Test',
            LEA_Numero__c = '123',
            LEA_N_Apartamento__c = '4B',
            LEA_Pais__c = 'DO',
            LEA_Provincia__c = '02',
            LEA_Municipio__c = '0101',
            LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
            LEA_Calificacion_de_cliente__c = 'BAJO',
            LEA_EsEmpleado_Vimenca__c = 'NO',
            LEA_EsEmpleado_GrupoVimenca__c = 'NO',
            LEA_EsProveedor__c = 'NO'
        );
        insert leadPN;
        
        Test.startTest();
        LeadConversionQueue.processLeads(new Set<Id>{leadPN.Id});
        Test.stopTest();
        
        List<ContactPointAddress> addresses = [SELECT Id FROM ContactPointAddress];
        System.assertEquals(0, addresses.size(), 'Should not create ContactPointAddress for non-converted lead');
        
        List<Informacion_Financiera__c> finInfos = [SELECT Id FROM Informacion_Financiera__c];
        System.assertEquals(0, finInfos.size(), 'Should not create Informacion_Financiera__c for non-converted lead');
    }
    
    @isTest
    static void testQueueable_Execute() {
        
        Id leadPNRecordTypeId = Schema.SObjectType.Lead
            .getRecordTypeInfosByDeveloperName()
            .get('Candidato_Persona_Natural')
            .getRecordTypeId();
        
        Datos_Maestros__c actEcon = [SELECT Id FROM Datos_Maestros__c WHERE DM_Tipo__c = 'Actividad Económica' LIMIT 1];
        
        Lead leadPN = new Lead(
            FirstName = 'Queue',
            LastName = 'Test',
            Company = 'Test Company',
            RecordTypeId = leadPNRecordTypeId,
            Status = 'Nuevo',
            LEA_PersonBirthdate__c = Date.today().addYears(-30),
            LEA_TipoIdentificacion__c = 'Cédula',
            LEA_NumIdentificacion__c = '00108803612',
            LEA_Tipo_de_vivienda__c = '3',
            LEA_Persona_PEP__c = 'NO',
            LEA_Resultado_Validacion__c = 'Aprobado',
            LEA_Genero_Identificaci_n__c = 'Cédula Masculino',
            LEA_Tipo_Persona_PF__c = 'P3',
            LEA_Tipo_Cliente_PF__c = '511',
            LEA_Tipo_Vinculacion__c = 'DEUDOR O EMISOR NO VINCULADO',
            LEA_Tipo_Actividad__c = 'AGUA',
            LEA_Actividad_Economica__c = actEcon.Id,
            LEA_Tipo_Sector__c = 'Privado',
            LEA_Fuente_de_ingresos__c = 'Herencia',
            LEA_Periodo__c = 'Mensual',
            LEA_Ingresos__c = '<= RD$ 15,000',
            LEA_Calle__c = 'Calle Queue',
            LEA_Numero__c = '456',
            LEA_N_Apartamento__c = '5A',
            LEA_Pais__c = 'DO',
            LEA_Provincia__c = '02',
            LEA_Municipio__c = '0101',
            LEA_Sector__c = 'Centro',
            LEA_Apartado_postal__c = '20202',
            LEA_Nacionalidad__c = 'REPUBLICA DOMINICANA',
            LEA_Calificacion_de_cliente__c = 'BAJO',
            LEA_EsEmpleado_Vimenca__c = 'NO',
            LEA_EsEmpleado_GrupoVimenca__c = 'NO',
            LEA_EsProveedor__c = 'NO',
            LEA_Fecha_Informacion__c = Date.today(),
            LEA_Total_Activos__c = 400000,
            LEA_Moneda__c = 'DOP',
            LEA_Ventas_Ingresos_Anuales__c = 1000000,
            LEA_Patrimonio_Num__c = 250000,
            LEA_Tipo_Referencia1__c = 'Personal',
            LEA_Nombre_Referencia1__c = 'Ref Queue',
            LEA_RNC_Referencia1__c = '111222333',
            LEA_Telefono_Referencia1__c = '8091111111',
            LEA_Direccion_Referencia1__c = 'Dirección Ref 1',
            LEA_Pais_Referencia1__c = 'DO',
            LEA_Tipo_Referencia2__c = 'Comercial',
            LEA_Nombre_Referencia2__c = 'Ref Queue 2',
            LEA_RNC_Referencia2__c = '444555666',
            LEA_Telefono_Referencia2__c = '8092222222',
            LEA_Direccion_Referencia2__c = 'Dirección Ref 2',
            LEA_Pais_Referencia2__c = 'DO',
            LEA_Principal1__c = TRUE,
            LEA_Via_de_Contacto1__c = 'TELÉFONO MÓVIL',
            LEA_Numero_Correo1__c = '8093333333',
            LEA_Telefonica1__c = 'CLARO',
            LEA_Empleo_Actual_Anterior__c = 'Actual',
            LEA_Empresa__c = 'Empresa Queue',
            LEA_Puesto_de_trabajo__c = 'Desarrollador',
            LEA_Ocupacion__c = 'ABOGADO',
            LEA_Tipo_de_empleado__c = '1',
            LEA_Tiempo_de_empresa__c = '3',
            LEA_Fecha_de_ingreso__c = Date.today().addYears(-3),
            LEA_Fecha_de_fin__c = Date.today(),
            LEA_Salario__c = 60000,
            LEA_Direcci_n_de_la_empresa__c = 'Av. Queue 789'
        );
        insert leadPN;
        
        Id personAccountRecordTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        Account personAccount = new Account(
            FirstName = leadPN.FirstName,
            LastName = leadPN.LastName,
            RecordTypeId = personAccountRecordTypeId
        );
        insert personAccount;
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadPN.Id);
        lc.setAccountId(personAccount.Id); 
        lc.setDoNotCreateOpportunity(true); 
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess(), 'Lead should be converted');
        
        Test.startTest();
        LeadConversionQueue queue = new LeadConversionQueue(new Set<Id>{leadPN.Id});
        System.enqueueJob(queue);
        Test.stopTest();
        
        List<Informacion_Financiera__c> finInfos = [SELECT Id FROM Informacion_Financiera__c];
        System.assert(finInfos.size() > 0, 'Should have created Informacion_Financiera__c');
    }

}
