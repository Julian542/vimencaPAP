@isTest
public class TestDataFactory {
  public static void createTestData() {
    List<Datos_Maestros__c> dmList = createDatosMaestro();

    Profile p = [SELECT Id FROM Profile WHERE id = '00e3i000001RR1rAAG']; //Id de usuario estandar
    User u = new User(
      Alias = 'standt',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'standardusertestvimenca@testorg.com',
      USE_Codigo__c = 'TESTCODE',
      USE_Oficina__c = dmList[0].DM_Codigo_Oficina__c
    );

    insert u;

    List<Account> personAccountList = createPersonAccounts(20);
    List<Direccion__c> direcciones = createDirecciones(personAccountList);
    List<Vias_de_Contacto__c> viasList = createViasDeContacto(personAccountList);
    List<Matriz_de_producto__c> matrizList = createMatrizDeProducto(10);
    List<Asset> assetList = createAssets_CuentaCorriente(personAccountList, direcciones, matrizList, u, 1);
    List<Vinculado__c> vinculadoList = createVinculados(personAccountList, assetList);
  }

  public static List<Profile> createProfile() {
    List<Profile> profiles = [SELECT Id FROM Profile WHERE id = '00e3i000001RR1rAAG'];
    return profiles;
  }

  public static List<Account> createPersonAccounts(Integer n) {
    Account acc;
    List<Account> accList = new List<Account>();

    for (Integer i = 1; i <= n; i++) {
      acc = new Account();
      //Verificar nombre del tipo de cliente en el entorno al que se vaya a pasar.
      acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Fisica').getRecordTypeId();
      acc.firstName = 'FirstName ' + i;
      acc.lastname = 'Test Person Account ' + i;
      acc.ACC_CIF__c = 'TESTCIF' + i;
      acc.ACC_TipoIdentificacion__c = 'Cédula';
      acc.ACC_NumIdentificacion__c = '12345678';
      acc.ACC_Nacionalidad__c = 'REPUBLICA DOMINICANA';
      acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
      acc.ACC_Genero__c = 'FEMENINO';
      acc.ACC_Estado_Civil__c = 'SOLTERO/A';
      acc.ACC_Posee_Resid_Otro_Pais__c = false;
      accList.add(acc);
    }

    insert accList;
    return accList;
  }
  public static List<Account> createJuridicAccounts(Integer n) {
    Account acc;
    List<Account> accList = new List<Account>();

    for (Integer i = 1; i <= n; i++) {
      acc = new Account();
      acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Candidato_Persona_Juridica').getRecordTypeId();
      acc.name = 'Test Account ' + i;
      // acc.lastname = 'Test Person Account ' + i;
      acc.ACC_RNC__c = 'RNC' + i;
      acc.ACC_CIF__c = 'TESTCIF' + i;
      acc.ACC_Condicion__c = 'PROSPECTO';
      acc.ACC_Estado__c = 'INICIADO';
      acc.ACC_TipoIdentificacion__c = 'RNC';
      accList.add(acc);
    }

    insert accList;
    return accList;
  }

  public static List<Vinculado__c> createVinculados(List<Account> accList, List<Asset> assetList) {
    Vinculado__c linked;
    List<Vinculado__c> linkedList = new List<Vinculado__c>();

    for (Account acc : accList) {
      for (Asset ast : assetList) {
        linked = new Vinculado__c();

        linked.VIN_Tipo_de_vinculo__c = 'AUTORIZADO';
        linked.VIN_Cuenta_financiera__c = ast.id;
        linked.VIN_Cliente_vinculado__c = acc.id;

        linkedList.add(linked);
      }
    }

    insert linkedList;
    return linkedList;
  }

  public static List<Asset> createAssets_CuentaCorriente(List<Account> accList, List<Direccion__c> dirsList, List<Matriz_de_producto__c> matrizList, User u, Integer assetsPerAccount) {
    Asset ast;
    List<Asset> assetList = new List<Asset>();
    Integer j = 0;
    Map<Id, Direccion__c> direccionMapByAccountId = new Map<Id, Direccion__c>();

    for (Direccion__c d : dirsList) {
      direccionMapByAccountId.put(d.DIR_Account__c, d);
    }

    for (Account acc : accList) {
      for (Integer i = 1; i <= assetsPerAccount; i++) {
        ast = new Asset();
        ast.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Certificados_financieros').getRecordTypeId();
        ast.name = 'Cuenta Corriente ' + i;
        ast.AccountId = acc.id;
        ast.ASE_Moneda__c = 'DOP';
        ast.ASE_N_de_cuenta__c = 'CC' + j + '--' + i;
        ast.ASE_Alias_de_la_cuenta__c = 'ALIAS' + acc.name + j + '--' + i;
        ast.ASE_Direccion__c = direccionMapByAccountId.get(acc.id).id;
        ast.ASE_Tipo_de_Cuenta__c = 'TEST';
        //System.debug('Matriz :: '+ matrizList[0].PRO_Nombre_de_linea_de_producto__c);
        //ast.ASE_Producto__c = matrizList[0].id;
        ast.ASE_Ejecutivo__c = u.id;
        ast.ownerId = u.id;
        ast.ASE_N_de_libreta__c = j + '' + i;
        ast.ASE_Tipo_de_vinculacion__c = 'Principal';
        ast.ASE_Linea_de_producto__c = 'Préstamos';
        assetList.add(ast);
      }
      j++;
    }

    insert assetList;
    return assetList;
  }

  public static List<Direccion__c> createDirecciones(List<Account> accList) {
    List<Direccion__c> direccionList = new List<Direccion__c>();
    Direccion__c dir;

    for (Account acc : accList) {
      dir = new Direccion__c();
      dir.DIR_Account__c = acc.id;
      dir.DIR_Tipo_Direccion__c = 'RESIDENCIA';
      dir.DIR_Calle__c = 'AVENIDA ' + acc.name;
      dir.DIR_Pais__c = 'AZ';
      direccionList.add(dir);
    }

    insert direccionList;
    return direccionList;
  }

  public static List<Vias_de_Contacto__c> createViasDeContacto(List<Account> accList) {
    List<Vias_de_Contacto__c> viasList = new List<Vias_de_Contacto__c>();
    Vias_de_Contacto__c via;

    for (Account acc : accList) {
      via = new Vias_de_Contacto__c();
      via.VIA_Account__c = acc.id;
      viasList.add(via);
    }

    insert viasList;
    return viasList;
  }

  public static List<Datos_Maestros__c> createDatosMaestro() {
    List<Datos_Maestros__c> dmList = new List<Datos_Maestros__c>();
    Datos_Maestros__c dm;
    Datos_Maestros__c dm2;

    dm = new Datos_Maestros__c(Name = 'Datos TEST', DM_Codigo_Oficina__c = '1', DM_Tipo__c = 'Oficina');
    dmList.add(dm);

    dm2 = new Datos_Maestros__c(Name = 'Datos TEST 2', DM_Codigo_Externo__c = '1-AQ-4432', DM_Tipo__c = 'Actividad Económica', DM_Direccion__c = '361033');
    dmList.add(dm2);

    insert dmList;
    return dmList;
  }

  public static List<Matriz_de_producto__c> createMatrizDeProducto(Integer n) {
    List<Matriz_de_producto__c> matrizList = new List<Matriz_de_producto__c>();
    Matriz_de_producto__c matriz;
    for (Integer i = 1; i <= n; i++) {
      matriz = new Matriz_de_producto__c();
      matriz.name = 'Matriz de producto TEST' + i;
      matriz.PRO_Codigo_de_producto__c = 'TEST' + i;
      //  matriz.PRO_Nombre_de_linea_de_producto__c = 'Certificados financieros';
      matrizList.add(matriz);
    }

    insert matrizList;
    return matrizList;
  }
}