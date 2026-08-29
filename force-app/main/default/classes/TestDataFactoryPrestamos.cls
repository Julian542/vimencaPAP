@isTest
public class TestDataFactoryPrestamos {
    
    public static void createTestData() {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        List<Account> clientes = crearClientePF(1, true);
        List<Matriz_de_producto__c> facilidades = createMatrizDeProducto(1);
        Opportunity opp = crearOportunidadWithProduct(clientes[0]?.Id, facilidades[0]?.Id, true);
    }

    public static void createTestDataConsultaDatacredito() {
        Test.setMock(HttpCalloutMock.class, new INT007TestMock('PF'));
        List<Account> clientes = crearClientePF(1, true);
        createHistorial(clientes);
        createInfoFinan(clientes);        
        List<Matriz_de_producto__c> facilidades = createMatrizDeProducto(1);
        Opportunity opp = crearOportunidadWithProduct(clientes[0]?.Id, facilidades[0]?.Id, true);
    }

    public static List<Account> crearClientePF(Integer n, boolean inserts) {

        Account acc;
        List<Account> accList = new List<Account>();

        try {
            for(Integer i = 1; i <= n; i++) {
                acc = new Account();
                acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
                acc.ACC_NumIdentificacion__c = String.valueOf(111111+i);
                acc.ACC_TipoIdentificacion__c = 'Cédula';
                acc.Lastname = 'LastName '+i;
                acc.FirstName = 'FirstName '+i;
                acc.MiddleName = 'MiddleName '+i;
                accList.add(acc);
            }
            if (inserts) {
                insert accList;
            }
        } catch (Exception e) {
            System.debug(e);            
        }
        return accList;
    }

    public static Opportunity crearOportunidadWithProduct(String accId, String productId, boolean inserts) {

        Opportunity opp = new Opportunity();
        try {
            opp.AccountId = accId;
            opp.Producto__c = productId;
            opp.Plazo__c =  32;
            opp.Tasa__c = 19;
            opp.Monto__c = 400000;
            opp.Tipo_Solicitud__c = 'BPR';
            opp.Forma_de_pago__c = '1';
            opp.opp_xcore__c = 555;
            opp.Razon_Decision__c = 'Test';
            opp.Dictamen__c = 'Referido';
            opp.OPP_Nombre_linea_de_producto__c = 'Préstamos';

            opp.Name = 'Opp Test';
            opp.StageName = 'Created';
            opp.CloseDate = Date.today().addDays(20);
            opp.Fecha_Solictud__c = Date.today();
            opp.Opp_Requiere_garantia__c = 'NO';
            
            if (inserts) {
                insert opp;
            }
        } catch (Exception e) {
            System.debug(e);
        }
        return opp;
    }

    public static List<Matriz_de_producto__c> createMatrizDeProducto(Integer n) {
        List<Matriz_de_producto__c> matrizList = new List<Matriz_de_producto__c>();
        Matriz_de_producto__c matriz;
        for(Integer i = 1; i <= n; i++) {
            matriz = new Matriz_de_producto__c();
            matriz.name = 'Producto ' + i;
            matriz.PRO_Codigo_de_producto__c =  String.valueOf(400+i);
            matriz.PRO_Tipo__c = 'Activo';
            matriz.PRO_Nombre_de_linea_de_producto__c = 'Préstamos';
            matrizList.add(matriz);
        }
        insert matrizList;
        return matrizList;
    }
    
    public static List<Informacion_Financiera__c> createInfoFinan(List<Account> accList){
        List<Informacion_Financiera__c> infoFinanLIst = new List<Informacion_Financiera__c>();
        for(Account acc: accList){
            Informacion_Financiera__c info = new Informacion_Financiera__c();
            info.INF_Cuenta__c = acc.Id;
            info.INF_Fuente_de_ingresos__c = 'Herencia'; 
            infoFinanLIst.add(info);
        }
        insert infoFinanLIst;
        return infoFinanLIst;
    }
    
    public static List<Historial_laboral__c> createHistorial(List<Account> accList){
        List<Historial_laboral__c> histList = new List<Historial_laboral__c>();
        Historial_laboral__c histL;        
        for(Account acc: accList){
            histL = new Historial_laboral__c();
            histL.HIS_Cuenta__c = acc.Id;
            histL.HIS_Fecha_de_ingreso__c = date.today().addDays(365);
            histL.Tipo_de_empleado__c = '1';
            histL.Salario__c = 60000;
            histL.Tiempo_de_empresa__c = '24 meses';
            histList.add(histL);
        }
        insert histList;
        return histList;
    }
}
