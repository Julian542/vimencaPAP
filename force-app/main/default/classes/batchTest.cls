@IsTest
public class batchTest {
    private static Id neutralAccountRecordTypeId() {
        return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Candidato_Persona_Juridica')
            .getRecordTypeId();
    }
		
    @TestSetup
    public static void makeData(){

        // Crear clientes
        Account[] cuentas = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            Account newAcc = new Account();
            newAcc.RecordTypeId = neutralAccountRecordTypeId();
            newAcc.Name = 'Mi cuenta '+i;
            newAcc.ACC_RNC__c = 'BATCHRNC' + i;
            newAcc.ACC_Condicion__c = 'PROSPECTO';
            newAcc.ACC_Estado__c = 'INICIADO';
            newAcc.ACC_TipoIdentificacion__c = 'RNC';
            cuentas.add(newAcc);
        }
        insert cuentas;

        for (Account acc : cuentas) {
            // Se crean 30 direcciones, 6 por cada cuenta 

            Direccion__c[] direccionesList = new List<Direccion__c>();
            for (Integer i = 0; i < 3; i++) {
                // solo con Ext ID backup
                Direccion__c dirA = new Direccion__c();
                dirA.DIR_Account__c = acc.Id;
                dirA.DIR_Id_Externo_Direccion_bk__c = 'A'+i;

                // solo con Ext ID
                Direccion__c dirB = new Direccion__c();
                dirB.DIR_Account__c = acc.Id;
                dirB.DIR_Id_Externo_Direccion__c = 'B'+i;
                
                direccionesList.add(dirA);
                direccionesList.add(dirB);
            }
            insert direccionesList;

            Informacion_Financiera__c[] infoFinancieraList = new List<Informacion_Financiera__c>();
            for (Integer i = 0; i < 3; i++) {
                // solo con Ext ID backup
                Informacion_Financiera__c infA = new Informacion_Financiera__c();
                infA.INF_Cuenta__c = acc.Id;
                infA.INF_Id_Externo_Inf_bk__c = 'A'+i;

                // solo con Ext ID
                Informacion_Financiera__c infB = new Informacion_Financiera__c();
                infB.INF_Cuenta__c = acc.Id;
                infB.INF_Id_Externo_Inf__c = 'B'+i;
                
                infoFinancieraList.add(infA);
                infoFinancieraList.add(infB);
            }
            insert infoFinancieraList;

            Historial_laboral__c[] hisLaboralList = new List<Historial_laboral__c>();
            for (Integer i = 0; i < 3; i++) {
                // solo con Ext ID backup
                Historial_laboral__c hisA = new Historial_laboral__c();
                hisA.HIS_Cuenta__c = acc.Id;
                hisA.HIS_Id_Externo_Historial_bk__c = 'A'+i;

                // solo con Ext ID
                Historial_laboral__c histB = new Historial_laboral__c();
                histB.HIS_Cuenta__c = acc.Id;
                histB.HIS_Id_Externo_Historial__c = 'B'+i;
                
                hisLaboralList.add(hisA);
                hisLaboralList.add(histB);
            }
            insert hisLaboralList;

            Vias_de_Contacto__c[] viaList = new List<Vias_de_Contacto__c>();
            for (Integer i = 0; i < 3; i++) {
                // solo con Ext ID backup
                Vias_de_Contacto__c viaA = new Vias_de_Contacto__c();
                viaA.VIA_Account__c = acc.Id;
                viaA.VIA_Id_Externo_Via_bk__c = 'A'+i;

                // solo con Ext ID
                Vias_de_Contacto__c viaB = new Vias_de_Contacto__c();
                viaB.VIA_Account__c = acc.Id;
                viaB.VIA_Id_Externo_Via__c = 'B'+i;
                
                viaList.add(viaA);
                viaList.add(viaB);
            }
            insert viaList;

            Referencia__c[] refList = new List<Referencia__c>();
            for (Integer i = 0; i < 3; i++) {
                // solo con Ext ID backup
                Referencia__c refA = new Referencia__c();
                refA.Account__c = acc.Id;
                refA.REF_Id_Externo_bk__c = 'A'+i;

                // solo con Ext ID
                Referencia__c refB = new Referencia__c();
                refB.Account__c = acc.Id;
                refB.REF_Id_Externo__c = 'B'+i;
                
                refList.add(refA);
                refList.add(refB);
            }
            insert refList;
        }
    }
    
    @IsTest
    static void batchDireccionesTest() {
        Test.startTest();
        batchDirecciones batch = new batchDirecciones();
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();
        // Valida que se hayan eliminado las 15 direcciones sin External ID
        System.assertEquals(15, [select count() from Direccion__c where DIR_Id_Externo_Direccion__c != null]);
        System.assertEquals(0, [select count() from Direccion__c where DIR_Id_Externo_Direccion_bk__c != null]);
    }

    @IsTest
    static void batchDatosFinancierosTest() {
        Test.startTest();
        batchDatosFinancieros batch = new batchDatosFinancieros();
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();
        // Valida que se hayan eliminado las 15 info financiera sin External ID
        System.assertEquals(15, [select count() from Informacion_Financiera__c where INF_Id_Externo_Inf__c != null]);
        System.assertEquals(0, [select count() from Informacion_Financiera__c where INF_Id_Externo_Inf_bk__c != null]);
    }

    @IsTest
    static void batchViasTest() {
        Test.startTest();
        batchVias batch = new batchVias();
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();
        // Valida que se hayan eliminado las 15 vias sin External ID
        System.assertEquals(15, [select count() from Vias_de_Contacto__c where VIA_Id_Externo_Via__c != null]);
        System.assertEquals(0, [select count() from Vias_de_Contacto__c where VIA_Id_Externo_Via_bk__c != null]);
    }
    
    @IsTest
    static void batchHistorialLaboralTest() {
        Test.startTest();
        batchHistorialLaboral batch = new batchHistorialLaboral();
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();
        // Valida que se hayan eliminado las 15 his laboral sin External ID
        System.assertEquals(15, [select count() from Historial_laboral__c where HIS_Id_Externo_Historial__c != null]);
        System.assertEquals(0, [select count() from Historial_laboral__c where HIS_Id_Externo_Historial_bk__c != null]);
    }

    @IsTest
    static void batchReferenciasTest() {
        Test.startTest();
        batchReferencias batch = new batchReferencias();
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();
        // Valida que se hayan eliminado las 15 referencias sin External ID
        System.assertEquals(15, [select count() from Referencia__c where REF_Id_Externo__c != null]);
        System.assertEquals(0, [select count() from Referencia__c where REF_Id_Externo_bk__c != null]);
    }
    
}
